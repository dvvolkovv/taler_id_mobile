import 'dart:async';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../voice_enrollment/domain/repositories/voice_enrollment_repository.dart';
import '../../data/interpreter_lang_store.dart';
import '../../domain/interpreter_error.dart';
import '../../domain/interpreter_models.dart';
import '../../domain/interpreter_repository.dart';
import '../../room/caption_lines.dart';
import '../../room/interpreter_device.dart';
import '../../room/interpreter_room_controller.dart';
import '../../room/interpreter_room_port.dart';
import '../../room/interpreter_signal.dart';
import 'interpreter_event.dart';
import 'interpreter_state.dart';

/// State machine for "Разговор с переводом" (two phones, side by side, each
/// hearing only the translation of the other).
///
/// Every repository failure funnels through [_emitRepoFailure], which also
/// handles the one cross-cutting rule the spec calls for: a bare
/// `voice_print_required` from the server reopens the voice-print gate
/// instead of surfacing as a generic [InterpreterFailure] — `
/// host_voice_print_required` and every other code do not, since there is
/// nothing the current user can do about someone else's missing print.
class InterpreterBloc extends Bloc<InterpreterEvent, InterpreterState> {
  final InterpreterRepository repo;
  final InterpreterLangStore langStore;
  final VoiceEnrollmentRepository voice;
  final InterpreterRoomPort Function() roomFactory;
  final InterpreterDevice device;
  final String Function() appLocale;

  /// Where the room is, from the client's own media endpoint (the CIS edge
  /// when the app runs on it), as calls do — not the server's LIVEKIT_WS_URL,
  /// which a CIS network cannot reach.
  final String Function() livekitUrl;
  final DateTime Function() now;
  final Duration pollEvery;

  InterpreterRoomController? _controller;
  StreamSubscription<RoomUpdate>? _roomSub;
  Timer? _pollTimer;
  bool _pollInFlight = false;

  /// `true` once the current room attempt's teardown (device + controller)
  /// has run, so [_teardownRoom] — called from more than one place a call
  /// can end — performs it exactly once. Starts `true`: there is nothing to
  /// tear down before the first room is ever attached.
  bool _tornDown = true;

  String? _initialJoinCode;
  InterpreterChoosing? _lastChoosing;
  String? _sessionId;
  bool _isHost = false;
  DateTime? _startedAt;
  String? _partnerUserId;
  bool _agentPresentNow = false;

  /// Set when a [PartnerJoined] update is processed before the bloc has
  /// had a chance to emit [InterpreterHosting] itself — see [_onRoomUpdate].
  bool _partnerJoinedBeforeHosting = false;

  InterpreterBloc({
    required this.repo,
    required this.langStore,
    required this.voice,
    required this.roomFactory,
    required this.device,
    required this.appLocale,
    required this.livekitUrl,
    this.now = DateTime.now,
    this.pollEvery = const Duration(seconds: 15),
  }) : super(const InterpreterLoading()) {
    on<Started>(_onStarted);
    on<LanguageChosen>(_onLanguageChosen);
    on<HostPressed>(_onHostPressed);
    on<JoinPressed>(_onJoinPressed);
    on<VoicePrintResult>(_onVoicePrintResult);
    on<NewCodePressed>(_onNewCodePressed);
    on<EndPressed>(_onEndPressed);
    on<MicToggled>(_onMicToggled);
    on<RetryPressed>(_onRetryPressed);
    on<BackToStart>(_onBackToStart);
    on<RoomUpdateArrived>(_onRoomUpdate);
    on<PollTicked>(_onPollTicked);
  }

  String? get _myUserId => _controller?.myBaseIdentity;

  InterpreterErrorKind _kindOf(Object error) =>
      InterpreterException.from(error).kind;

  Future<void> _onStarted(Started event, Emitter<InterpreterState> emit) async {
    _initialJoinCode = event.joinCode;
    emit(const InterpreterLoading());

    InterpreterCatalog catalog;
    try {
      catalog = await repo.catalog();
    } catch (e) {
      // No Choosing has ever been reached yet — there is nothing to fall
      // back to except retrying this same load.
      emit(InterpreterFailure(kind: _kindOf(e)));
      return;
    }

    if (!catalog.enabled) {
      emit(const InterpreterUnavailable());
      return;
    }

    final myLang = await langStore.initial(catalog, appLocale());
    _emitChoosing(
      InterpreterChoosing(
        catalog: catalog,
        myLang: myLang,
        joinCode: event.joinCode,
      ),
      emit,
    );
  }

  Future<void> _onLanguageChosen(
    LanguageChosen event,
    Emitter<InterpreterState> emit,
  ) async {
    final current = state;
    if (current is! InterpreterChoosing) return;
    await langStore.remember(event.code);
    _emitChoosing(current.copyWith(myLang: event.code), emit);
  }

  Future<void> _onHostPressed(
    HostPressed event,
    Emitter<InterpreterState> emit,
  ) async {
    final current = state;
    if (current is! InterpreterChoosing) return;
    await _gateOnVoicePrint(
      back: current,
      then: InterpreterPendingAction.host,
      code: null,
      emit: emit,
    );
  }

  Future<void> _onJoinPressed(
    JoinPressed event,
    Emitter<InterpreterState> emit,
  ) async {
    final current = state;
    if (current is! InterpreterChoosing) return;
    await _gateOnVoicePrint(
      back: current,
      then: InterpreterPendingAction.join,
      code: event.code,
      emit: emit,
    );
  }

  Future<void> _gateOnVoicePrint({
    required InterpreterChoosing back,
    required InterpreterPendingAction then,
    required String? code,
    required Emitter<InterpreterState> emit,
  }) async {
    bool enrolled;
    try {
      enrolled = (await voice.getStatus()).enrolled;
    } catch (e) {
      _emitRepoFailure(e, emit: emit, back: back);
      return;
    }

    if (!enrolled) {
      emit(InterpreterNeedVoicePrint(then: then, code: code));
      return;
    }

    if (then == InterpreterPendingAction.host) {
      await _hostSession(lang: back.myLang, emit: emit, back: back);
    } else {
      await _joinSession(
          code: code!, lang: back.myLang, emit: emit, back: back);
    }
  }

  Future<void> _onVoicePrintResult(
    VoicePrintResult event,
    Emitter<InterpreterState> emit,
  ) async {
    final current = state;
    if (current is! InterpreterNeedVoicePrint) return;
    final back = _lastChoosing;
    // Defensive: NeedVoicePrint always follows a Choosing.
    if (back == null) return;

    if (!event.ok) {
      _emitChoosing(back, emit);
      return;
    }

    if (current.then == InterpreterPendingAction.host) {
      await _hostSession(lang: back.myLang, emit: emit, back: back);
    } else {
      await _joinSession(
        code: current.code!,
        lang: back.myLang,
        emit: emit,
        back: back,
      );
    }
  }

  Future<void> _hostSession({
    required String lang,
    required Emitter<InterpreterState> emit,
    required InterpreterChoosing back,
  }) async {
    emit(const InterpreterWorking(InterpreterWorkKind.creating));

    HostedSession hosted;
    try {
      hosted = await repo.create(lang);
    } catch (e) {
      if (emit.isDone) return;
      _emitRepoFailure(
        e,
        emit: emit,
        back: back,
        pendingThen: InterpreterPendingAction.host,
      );
      return;
    }

    // The bloc closed while create() was resolving: the session is real on
    // the server, but there is no one left to use it or to show a failure
    // to — release the QR slot and stop here, never touching the room.
    if (emit.isDone) {
      _abandonSession(hosted.sessionId);
      return;
    }

    _isHost = true;
    _sessionId = hosted.sessionId;
    try {
      await _enterRoom(url: livekitUrl(), token: hosted.token, emit: emit);
    } catch (e) {
      await _teardownRoom();
      if (emit.isDone) {
        _abandonSession(hosted.sessionId);
      } else {
        emit(InterpreterFailure(kind: _kindOf(e), back: back));
      }
      return;
    }

    if (emit.isDone) {
      await _teardownRoom();
      _abandonSession(hosted.sessionId);
      return;
    }

    final hosting = InterpreterHosting(
      session: hosted,
      code: hosted.code,
      expiresAt: hosted.expiresAt,
      myLang: lang,
    );
    emit(hosting);

    if (_partnerJoinedBeforeHosting) {
      _partnerJoinedBeforeHosting = false;
      await _hostSeesPartnerJoin(hosting, emit);
    }
  }

  Future<void> _joinSession({
    required String code,
    required String lang,
    required Emitter<InterpreterState> emit,
    required InterpreterChoosing back,
  }) async {
    emit(const InterpreterWorking(InterpreterWorkKind.joining));

    JoinedSession joined;
    try {
      joined = await repo.join(code, lang);
    } catch (e) {
      if (emit.isDone) return;
      _emitRepoFailure(
        e,
        emit: emit,
        back: back,
        pendingThen: InterpreterPendingAction.join,
        pendingCode: code,
      );
      return;
    }

    // The bloc closed while join() was resolving: the single-use code was
    // already consumed and the host's billing session opened, but nobody is
    // left to talk to — ending it now, rather than leaving it to expire on
    // its own, is what stops the host being billed for an empty room.
    if (emit.isDone) {
      _abandonSession(joined.sessionId);
      return;
    }

    _isHost = false;
    _sessionId = joined.sessionId;
    try {
      await _enterRoom(url: livekitUrl(), token: joined.token, emit: emit);
    } catch (e) {
      await _teardownRoom();
      if (emit.isDone) {
        _abandonSession(joined.sessionId);
      } else {
        emit(InterpreterFailure(kind: _kindOf(e), back: back));
      }
      return;
    }

    if (emit.isDone) {
      await _teardownRoom();
      _abandonSession(joined.sessionId);
      return;
    }

    // The join answer carries no `startedAt` (unlike the host's later
    // `GET /interpreter/sessions/:id`) — the guest's own clock is the only
    // option.
    _startedAt = now();
    // The guest only reaches here once already connected to the host, so
    // unlike the host's QR screen there is no code on screen left to blank.
    await device.setNearEarScreenOff(true);
    emit(InterpreterActive(
      isHost: false,
      myLang: lang,
      partner: joined.partner,
      directions: joined.directions,
      captions: CaptionLines(),
      partnerSpeaking: false,
      meSpeaking: false,
      agentPresent: _agentPresentNow,
      connection: InterpreterLinkState.ok,
      micOn: true,
      startedAt: _startedAt!,
      spentPlanck: null,
    ));
    _startPolling();
  }

  Future<void> _hostSeesPartnerJoin(
    InterpreterHosting hosting,
    Emitter<InterpreterState> emit,
  ) async {
    SessionView view;
    try {
      view = await repo.get(hosting.session.sessionId);
    } catch (e) {
      // The room is already connected at this point — leaving it live would
      // strand the host on a mic-open, proximity-locked device with nowhere
      // to go but a second room stacked over this one.
      await _teardownRoom();
      _emitRepoFailure(e, emit: emit);
      return;
    }

    final partner = view.partner;
    final directions = view.directions;
    if (partner == null || directions == null) {
      // Defensive: the backend contract guarantees both once a partner has
      // joined, but a null here must not crash the call via a force-unwrap
      // — fall back to exactly what a failed repo.get() above would have
      // done.
      await _teardownRoom();
      _emitRepoFailure(
        const InterpreterException(InterpreterErrorKind.unknown),
        emit: emit,
      );
      return;
    }

    _startedAt = view.startedAt ?? now();
    // Only now, with a partner actually on the call, is it safe to let the
    // proximity sensor blank the screen — turning it on any earlier would
    // blank the QR the host is still showing.
    await device.setNearEarScreenOff(true);
    emit(InterpreterActive(
      isHost: true,
      myLang: hosting.myLang,
      partner: partner,
      directions: directions,
      captions: CaptionLines(),
      partnerSpeaking: false,
      meSpeaking: false,
      agentPresent: _agentPresentNow,
      connection: InterpreterLinkState.ok,
      micOn: true,
      startedAt: _startedAt!,
      spentPlanck: view.spentPlanck,
    ));
    _startPolling();
  }

  Future<void> _onNewCodePressed(
    NewCodePressed event,
    Emitter<InterpreterState> emit,
  ) async {
    final current = state;
    if (current is! InterpreterHosting) return;
    try {
      final fresh = await repo.newCode(current.session.sessionId);
      emit(current.copyWith(code: fresh.code, expiresAt: fresh.expiresAt));
    } catch (e) {
      _emitRepoFailure(e, emit: emit);
    }
  }

  Future<void> _onEndPressed(
    EndPressed event,
    Emitter<InterpreterState> emit,
  ) async {
    final sessionId = _sessionId;
    if (sessionId != null) {
      try {
        await repo.end(sessionId);
      } catch (e) {
        // Spec: errors here are logged, not surfaced — the call is being
        // torn down regardless of whether the server confirmed cleanup.
        debugPrint('[InterpreterBloc] repo.end($sessionId) failed: $e');
      }
    }
    await _finish(emit: emit, reason: InterpreterEndReason.hangup);
  }

  Future<void> _onMicToggled(
    MicToggled event,
    Emitter<InterpreterState> emit,
  ) async {
    final current = state;
    if (current is! InterpreterActive) return;
    await _controller?.setMic(event.on);
    emit(current.copyWith(micOn: event.on));
  }

  Future<void> _onRetryPressed(
    RetryPressed event,
    Emitter<InterpreterState> emit,
  ) =>
      _returnToChoosing(emit);

  Future<void> _onBackToStart(
    BackToStart event,
    Emitter<InterpreterState> emit,
  ) =>
      _returnToChoosing(emit);

  Future<void> _returnToChoosing(Emitter<InterpreterState> emit) async {
    // Idempotent — a no-op whenever the room was already torn down (the
    // common case), but the one thing standing between every path back to
    // the start screen and a room left live behind it.
    await _teardownRoom();
    final current = state;
    final back = current is InterpreterFailure ? current.back : _lastChoosing;
    if (back != null) {
      _emitChoosing(back, emit);
      return;
    }
    // Only reachable when the very first catalog load failed: nothing to go
    // back to except retrying that same load.
    await _onStarted(Started(joinCode: _initialJoinCode), emit);
  }

  Future<void> _onRoomUpdate(
    RoomUpdateArrived event,
    Emitter<InterpreterState> emit,
  ) async {
    switch (event.update) {
      case PartnerJoined(identity: final id):
        _partnerUserId = InterpreterRoomController.baseOf(id);
        final current = state;
        if (current is InterpreterHosting) {
          await _hostSeesPartnerJoin(current, emit);
        } else {
          // Events process concurrently with the create()+room-connect
          // round trip, so this can arrive while the host is still
          // `InterpreterWorking(creating)` (or earlier) — the room's own
          // `ParticipantJoined` replay for an already-present partner can
          // easily win that race. Remembered here and picked back up the
          // moment Hosting itself is emitted, instead of being dropped with
          // the host left waiting on the QR forever.
          _partnerJoinedBeforeHosting = true;
        }
      case PartnerLeft():
        // The backend gives a reconnecting partner 60s before closing the
        // session as `partner_left`; nothing for the UI to do here beyond
        // what the next poll or a room `Closed` will already handle.
        break;
      case AgentJoined():
        _agentPresentNow = true;
        _updateActive(emit, (a) => a.copyWith(agentPresent: true));
      case AgentLeft():
        _agentPresentNow = false;
        _updateActive(emit, (a) => a.copyWith(agentPresent: false));
      case Signal(signal: final signal):
        _applySignal(signal, emit);
      case Connection(state: final connectionState):
        _updateActive(
          emit,
          (a) => a.copyWith(
            connection: connectionState == InterpreterConnectionState.ok
                ? InterpreterLinkState.ok
                : InterpreterLinkState.reconnecting,
          ),
        );
      case Closed():
        await _finishFromClosed(emit);
    }
  }

  void _updateActive(
    Emitter<InterpreterState> emit,
    InterpreterActive Function(InterpreterActive current) update,
  ) {
    final current = state;
    if (current is InterpreterActive) emit(update(current));
  }

  void _applySignal(InterpreterSignal signal, Emitter<InterpreterState> emit) {
    final current = state;
    if (current is! InterpreterActive) return;

    switch (signal) {
      case CaptionSignal():
        // Mutated in place; copyWith() alone bumps the revision so this is
        // still a distinct, deliverable state.
        current.captions.add(signal, now());
        emit(current.copyWith());
      case SpeakingSignal(speaker: final speaker, on: final on):
        final myId = _myUserId;
        emit(current.copyWith(
          meSpeaking: myId != null && speaker == myId ? on : current.meSpeaking,
          partnerSpeaking:
              speaker == _partnerUserId ? on : current.partnerSpeaking,
        ));
      case StatusSignal(state: final s):
        emit(current.copyWith(
            connection: switch (s) {
          StatusState.reconnecting => InterpreterLinkState.reconnecting,
          StatusState.ok => InterpreterLinkState.ok,
          StatusState.failed => InterpreterLinkState.failed,
        }));
    }
  }

  Future<void> _finishFromClosed(Emitter<InterpreterState> emit) async {
    if (state is InterpreterEnded || _controller == null) return;

    SessionView? view;
    final sessionId = _sessionId;
    if (sessionId != null) {
      try {
        view = await repo.get(sessionId);
      } catch (_) {
        view = null;
      }
    }

    await _finish(
      emit: emit,
      reason: view?.endReason,
      spentPlanckOverride: view?.spentPlanck,
    );
  }

  Future<void> _onPollTicked(
    PollTicked event,
    Emitter<InterpreterState> emit,
  ) async {
    final current = state;
    if (current is! InterpreterActive || _pollInFlight) return;
    final sessionId = _sessionId;
    if (sessionId == null) return;

    _pollInFlight = true;
    try {
      final view = await repo.get(sessionId);
      if (view.status == InterpreterStatus.ended) {
        await _finish(
          emit: emit,
          reason: view.endReason,
          spentPlanckOverride: view.spentPlanck,
        );
        return;
      }
      if (current.isHost && view.spentPlanck != null) {
        final latest = state;
        if (latest is InterpreterActive) {
          emit(latest.copyWith(spentPlanck: view.spentPlanck));
        }
      }
    } catch (_) {
      // A transient poll failure just waits for the next tick rather than
      // tearing down an otherwise-healthy call.
    } finally {
      _pollInFlight = false;
    }
  }

  Future<void> _finish({
    required Emitter<InterpreterState> emit,
    InterpreterEndReason? reason,
    String? spentPlanckOverride,
  }) async {
    if (state is InterpreterEnded) return;
    final current = state;
    final spentPlanck = spentPlanckOverride ??
        (current is InterpreterActive ? current.spentPlanck : null);
    final duration = _startedAt == null ? null : now().difference(_startedAt!);
    final isHost = _isHost;

    await _teardownRoom();

    emit(InterpreterEnded(
      reason: reason,
      duration: duration,
      spentPlanck: spentPlanck,
      isHost: isHost,
    ));
  }

  void _emitChoosing(
    InterpreterChoosing choosing,
    Emitter<InterpreterState> emit,
  ) {
    _lastChoosing = choosing;
    emit(choosing);
  }

  /// Centralises what happens to a thrown repo/voice error: a bare
  /// `voice_print_required` reopens the gate when there is a pending
  /// action to resume; everything else — including `network`/`unknown` and
  /// every other backend code — becomes an [InterpreterFailure] pointing
  /// back at the last known [InterpreterChoosing] ([back], or the bloc's own
  /// memory of it when the caller has none at hand).
  void _emitRepoFailure(
    Object error, {
    required Emitter<InterpreterState> emit,
    InterpreterChoosing? back,
    InterpreterPendingAction? pendingThen,
    String? pendingCode,
  }) {
    final kind = _kindOf(error);
    if (kind == InterpreterErrorKind.voicePrintRequired &&
        pendingThen != null) {
      emit(InterpreterNeedVoicePrint(then: pendingThen, code: pendingCode));
      return;
    }
    emit(InterpreterFailure(kind: kind, back: back ?? _lastChoosing));
  }

  Future<void> _enterRoom({
    required String url,
    required String token,
    required Emitter<InterpreterState> emit,
  }) async {
    _tornDown = false;
    await device.enterConversation();
    if (emit.isDone) return;
    await _attachRoom();
    if (emit.isDone) return;
    await _controller!.start(url: url, token: token, micOn: true);
  }

  /// The bloc closed mid-flight after a create/join had already gone
  /// through on the server (whether just the REST call, or the room that
  /// followed it too — [_enterRoom] bails out early on its own checks either
  /// way). Nobody is left to see a failure, but the session is real on the
  /// server, so it still has to be released. Best-effort: there is no one
  /// left to retry for.
  void _abandonSession(String sessionId) {
    repo.end(sessionId).catchError((_) {});
  }

  /// Defensive: under the intended flow nothing is ever attached twice —
  /// [_teardownRoom] always clears [_controller] first — but a stray leftover
  /// controller must not simply be overwritten and leaked (a live mic +
  /// subscription under a reference nothing holds any more).
  Future<void> _attachRoom() async {
    final stale = _controller;
    final staleSub = _roomSub;
    _controller = null;
    _roomSub = null;
    await staleSub?.cancel();
    if (stale != null) {
      try {
        await stale.dispose();
      } catch (_) {
        // Best-effort: already being replaced regardless.
      }
    }

    _controller = InterpreterRoomController(roomFactory());
    _roomSub = _controller!.updates.listen((u) => add(RoomUpdateArrived(u)));
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(pollEvery, (_) => add(const PollTicked()));
  }

  /// Always runs device + controller teardown exactly once per room
  /// attempt, however the call ended (`EndPressed`, the room closing on its
  /// own, a poll detecting `ended`, or the bloc itself closing).
  Future<void> _teardownRoom() async {
    if (_tornDown) return;
    _tornDown = true;

    _pollTimer?.cancel();
    _pollTimer = null;
    await _roomSub?.cancel();
    _roomSub = null;

    final controller = _controller;
    _controller = null;
    await controller?.dispose();
    await device.leaveConversation();

    _sessionId = null;
    _startedAt = null;
    _partnerUserId = null;
    _agentPresentNow = false;
    _partnerJoinedBeforeHosting = false;
    _isHost = false;
  }

  @override
  Future<void> close() async {
    await _teardownRoom();
    return super.close();
  }
}

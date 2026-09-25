// lib/core/platform/system_call_registry.dart
import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import 'call_kit.dart';
import 'callkit_support.dart';
import 'system_call_bridge.dart';

/// Something the OS call system did to one of our conversations.
sealed class SystemCallEvent {
  const SystemCallEvent(this.uuid, this.roomName);

  /// CallKit uuid, lowercase.
  final String uuid;

  /// LiveKit room of the conversation; null until the server created it.
  final String? roomName;
}

/// The conversation went on hold. [bySystem]: call waiting (WhatsApp, a
/// cellular call, a second Taler ID call answered with "Hold & Accept"), as
/// opposed to our own line switch, which is never resumed automatically.
final class SystemCallHeld extends SystemCallEvent {
  const SystemCallHeld(super.uuid, super.roomName, {required this.bySystem});
  final bool bySystem;
}

final class SystemCallResumed extends SystemCallEvent {
  const SystemCallResumed(super.uuid, super.roomName, {required this.swapped});

  /// The system resumed a line the app had put on hold — e.g. the Swap
  /// button — so the app should switch to it.
  final bool swapped;
}

/// The mute button of the system call UI (lock screen, Dynamic Island).
final class SystemCallMuteChanged extends SystemCallEvent {
  const SystemCallMuteChanged(super.uuid, super.roomName, {required this.muted});
  final bool muted;
}

/// Ended outside the app: the system End button, "End & Accept".
final class SystemCallEndedBySystem extends SystemCallEvent {
  const SystemCallEndedBySystem(super.uuid, super.roomName, {this.conversationId});

  /// The conversation this call belonged to, when the registry knew it (see
  /// [_Entry.conversationId]) — null for an outgoing call, or an incoming
  /// one the registry never learned it for. The listener needs this to send
  /// `call_ended` for a room CallStateService has no line for yet (the join
  /// is still in flight), where there is nowhere else left to read it from.
  final String? conversationId;
}

enum _State { starting, active, heldBySystem, heldByApp }

class _Entry {
  _Entry({
    required this.uuid,
    required this.outgoing,
    required this.state,
    this.roomName,
    this.conversationId,
  });

  final String uuid;
  final bool outgoing;
  String? roomName;
  /// Carried through to [SystemCallEndedBySystem] — see its doc.
  final String? conversationId;
  _State state;
  bool connectedReported = false;
  final started = Completer<bool>();
}

/// Used off a real iPhone, where [SystemCallRegistry] is disabled and every
/// method on it a no-op: avoids [MethodChannelSystemCallBridge]'s
/// constructor, which installs a platform-channel handler that throws
/// without an initialized Flutter binding — as in a plain unit test, which
/// is where later tasks reach [SystemCallRegistry.instance] from main.dart,
/// the dashboard and notification_service.
class _NoBridge implements SystemCallBridge {
  @override
  Future<void> setManagedCalls(List<String> uuids) async {}

  @override
  Future<void> prepareCallAudio() async {}

  @override
  Stream<void> get otherCallsEnded => const Stream<void>.empty();
}

/// iOS: every conversation on the call screen lives in CallKit for as long as
/// it lasts, so WhatsApp and cellular calls arrive as call waiting instead of
/// taking our audio session. This is the Dart side of it: which CallKit call
/// is which conversation, and what the system did to it. See
/// docs/superpowers/specs/2026-09-24-ios-calls-through-callkit-design.md.
///
/// Disabled everywhere but a real iPhone. Every method is then a no-op, and
/// the ones that replace a blanket `endAllCalls()` fall back to exactly that,
/// so Android, desktop and the simulator behave as before.
class SystemCallRegistry {
  SystemCallRegistry({
    required CallKitPlatform callKit,
    required SystemCallBridge bridge,
    required this.enabled,
    this.startTimeout = const Duration(seconds: 3),
    this.answerTimeout = const Duration(seconds: 2),
    String Function()? newUuid,
  })  : _callKit = callKit,
        _bridge = bridge,
        _newUuid = newUuid ?? (() => const Uuid().v4());

  static SystemCallRegistry? _instance;

  static SystemCallRegistry get instance {
    final onIPhone = !kIsWeb && Platform.isIOS && !isIosSimulator;
    return _instance ??= SystemCallRegistry(
      callKit: CallKitPlatform.instance,
      bridge: onIPhone ? MethodChannelSystemCallBridge() : _NoBridge(),
      enabled: onIPhone,
    );
  }

  @visibleForTesting
  static set debugInstance(SystemCallRegistry? registry) => _instance = registry;

  final CallKitPlatform _callKit;
  final SystemCallBridge _bridge;
  final bool enabled;
  final Duration startTimeout;
  final Duration answerTimeout;
  final String Function() _newUuid;

  /// Our conversations, by lowercase CallKit uuid.
  final Map<String, _Entry> _entries = {};

  /// Outgoing starts [startOutgoing] gave up on: ended if iOS starts them late.
  final Set<String> _abandonedStarts = {};

  /// Holds we asked for ourselves (line switch) — not call waiting.
  final Set<String> _appHolds = {};

  /// Uuid -> completer for a pending [answerRinging]: completed by
  /// [_onAccepted] when the ACCEPT it is waiting for arrives.
  final Map<String, Completer<bool>> _pendingAnswers = {};

  final _events = StreamController<SystemCallEvent>.broadcast();
  StreamSubscription<CallKitEvent>? _callKitSub;
  StreamSubscription<void>? _bridgeSub;

  Stream<SystemCallEvent> get events => _events.stream;

  /// At least one conversation is in CallKit — CallKit owns the audio
  /// session. Also true for an outgoing call still waiting for iOS to
  /// confirm the start: native already treats it as managed from
  /// [startOutgoing]'s first sync, before CallKit itself agrees.
  bool get hasConversations => _entries.isNotEmpty;

  /// Starts listening. Call once, before runApp, so an accept that launched a
  /// killed app is not missed.
  void attach() {
    if (!enabled || _callKitSub != null) return;
    _callKitSub = _callKit.events.listen(_onCallKitEvent);
    _bridgeSub = _bridge.otherCallsEnded.listen((_) => _onOtherCallsEnded());
    // Pushes the current set once — empty on a fresh start, since _entries is
    // still empty here. Safe for a killed-app answer: native only ever
    // subtracts registeredByDart from answeredHere, so an empty push cannot
    // touch a call native already marked answered on its own. And it clears
    // stale native state left over from a Dart hot restart — without this,
    // native can keep believing a uuid from before the restart is still
    // registeredByDart, with no Dart-side entry left to ever clear it, so
    // manual audio would stay on for good.
    unawaited(_syncManaged());
  }

  @visibleForTesting
  Future<void> detach() async {
    await _callKitSub?.cancel();
    await _bridgeSub?.cancel();
    _callKitSub = null;
    _bridgeSub = null;
  }

  bool isConversation(String roomName) => _entryForRoom(roomName) != null;

  String? uuidForRoom(String roomName) => _entryForRoom(roomName)?.uuid;

  bool isHeldBySystem(String roomName) =>
      _entryForRoom(roomName)?.state == _State.heldBySystem;

  /// Puts a conversation that did not ring through CallKit into it — an
  /// outgoing call, a meeting joined by link, a call picked up outside
  /// CallKit — and waits for iOS to confirm. Returns the CallKit uuid, or
  /// null: the call then runs the old way, without CallKit.
  Future<String?> startOutgoing({
    required String displayName,
    required String handle,
    String? roomName,
  }) async {
    if (!enabled) return null;
    if (_callKitSub == null) {
      // Not attached: the START event this method waits for is never heard,
      // so without this guard the call would just time out — and a late
      // start would never be ended, leaving an orphan CallKit call.
      debugPrint('[SystemCall] startOutgoing before attach() — call runs without CallKit');
      return null;
    }
    final uuid = _newUuid().toLowerCase();
    final entry = _Entry(uuid: uuid, outgoing: true, state: _State.starting, roomName: roomName);
    _entries[uuid] = entry;
    // Registered and synced before startCall: CallKit activates the audio
    // session right after the start, before the START event could reach
    // Dart and come back — native must already treat the call as managed
    // by then, or CallKit and the old WebRTC audio path would fight over it.
    if (!await _syncManaged()) {
      _entries.remove(uuid);
      if (!entry.started.isCompleted) entry.started.complete(false);
      return null;
    }
    try {
      await _bridge.prepareCallAudio();
      await _callKit.startCall(
        uuid: uuid,
        callerName: displayName,
        handle: handle,
        extra: {if (roomName != null) 'roomName': roomName},
      );
    } catch (e) {
      debugPrint('[SystemCall] could not start $uuid in CallKit: $e');
      if (!entry.started.isCompleted) entry.started.complete(false);
    }
    final ok = await entry.started.future.timeout(startTimeout, onTimeout: () {
      // Complete the completer itself, not just this wrapped future: other
      // callers (markConnected) await entry.started.future directly and
      // must not hang forever if iOS never confirms.
      if (!entry.started.isCompleted) entry.started.complete(false);
      return false;
    });
    if (ok) return uuid;
    // Ended while starting — _end already hung it up; nothing to abandon.
    if (!identical(_entries[uuid], entry)) return null;
    _entries.remove(uuid);
    _abandonedStarts.add(uuid);
    await _syncManaged();
    debugPrint('[SystemCall] CallKit did not confirm $uuid — call runs without it');
    return null;
  }

  /// Attaches the room name once the server has created the room. Returns
  /// false when [uuid] is no longer a conversation — e.g. the system End
  /// button was pressed while an outgoing call was still connecting, before
  /// the room existed — so the caller (the call screen) knows to hang up
  /// instead of proceeding.
  bool bindRoom(String uuid, String roomName) {
    final entry = _entries[uuid.toLowerCase()];
    if (entry == null) return false;
    entry.roomName = roomName;
    return true;
  }

  /// A conversation whose CallKit call was answered while the app was not
  /// listening (cold start after an answer on the lock screen).
  Future<void> adoptAnswered({
    required String uuid,
    required String roomName,
    String? conversationId,
  }) async {
    if (!enabled) return;
    if (!_isCallScreenConversation(roomName)) return;
    final key = uuid.toLowerCase();
    if (_entries.containsKey(key)) return;
    _entries[key] = _Entry(
      uuid: key,
      outgoing: false,
      state: _State.active,
      roomName: roomName,
      conversationId: conversationId,
    );
    await _syncManaged();
  }

  /// The callee (or the AI twin) answered, or a meeting was joined: iOS shows
  /// the outgoing call connected from here on. Incoming calls are connected by
  /// the answer itself.
  Future<void> markConnected(String roomName) async {
    final entry = _entryForRoom(roomName);
    if (entry == null || !entry.outgoing || entry.connectedReported) return;
    if (entry.state == _State.starting) {
      // Reporting "connected" before CallKit even knows the call exists
      // makes the plugin request an answer action that fails, and would
      // latch connectedReported so the real report is never sent. Wait for
      // startOutgoing's own confirmation (or give-up) instead — that future
      // always completes, including on timeout (see startOutgoing).
      final started = await entry.started.future;
      if (!started || _entries[entry.uuid] != entry || entry.connectedReported) return;
    }
    entry.connectedReported = true;
    try {
      await _callKit.setCallConnected(entry.uuid);
    } catch (e) {
      debugPrint('[SystemCall] setCallConnected failed for ${entry.uuid}: $e');
    }
  }

  /// Hangs up our side of [roomName]'s conversation in CallKit.
  Future<void> endConversation(String roomName) async {
    final entry = _entryForRoom(roomName);
    if (entry != null) await _end(entry.uuid);
  }

  /// Hangs up our side of a conversation in CallKit, keyed by its uuid —
  /// same as [endConversation], for a caller that already has the uuid to
  /// hand instead of the room name.
  Future<void> endConversationByUuid(String uuid) async {
    final key = uuid.toLowerCase();
    if (_entries.containsKey(key)) await _end(key);
  }

  /// Hangs up every one of our conversations in CallKit — the call screen's
  /// "hang up all". (Sign-out still uses the raw `endAllCalls()`, not this.)
  Future<void> endAllConversations() async {
    for (final uuid in List.of(_entries.keys)) {
      // A CallKit ENDED processed while a previous iteration's _end was
      // awaiting may already have removed this uuid — don't hang it up
      // (and call endCall on it) a second time.
      if (!_entries.containsKey(uuid)) continue;
      await _end(uuid);
    }
  }

  /// Ends every ringing CallKit call that is ours but not (yet) a
  /// conversation — what the blanket endAllCalls() was used for: dismissing
  /// ringing calls. Leaves alone: other apps' calls (no `extra` payload),
  /// calls already registered as conversations, and an answered call-screen
  /// conversation Dart has not turned into an entry yet (the same race
  /// [endRingingForRoom] guards against). An answered group/mesh call is
  /// none of those — it never becomes an entry — so it stays dismissable
  /// here: the dashboard ends an accepted group call by calling this once
  /// the group call itself ends.
  /// A plugin failure is swallowed and logged, leaving any remaining
  /// ringing calls alone rather than throwing. Disabled registry: exactly
  /// the old endAllCalls().
  Future<void> dismissRinging() async {
    if (!enabled) return _callKit.endAllCalls();
    List<dynamic> calls;
    try {
      calls = await _callKit.activeCalls();
    } catch (e) {
      debugPrint('[SystemCall] dismissRinging: activeCalls failed: $e');
      return;
    }
    for (final raw in calls) {
      if (raw is! Map) continue;
      final id = (raw['id'] ?? '').toString().toLowerCase();
      // Other apps' calls come without our payload — never ours to end.
      if (id.isEmpty || !raw.containsKey('extra') || _entries.containsKey(id)) continue;
      final extra = raw['extra'];
      final roomName = extra is Map ? extra['roomName'] : null;
      final answered = raw['isAccepted'] == true || raw['accepted'] == true;
      if (answered && roomName is String && _isCallScreenConversation(roomName, kind: extra['kind'])) {
        continue; // answered — Dart just has not registered it as a conversation yet
      }
      try {
        await _callKit.endCall(id);
      } catch (e) {
        debugPrint('[SystemCall] dismissRinging: endCall failed for $id: $e');
      }
    }
  }

  /// Ends [roomName]'s ringing call (cancelled by the caller, answered on
  /// another device, declined in our dialog). Returns true — and ends nothing —
  /// when that call is a conversation: an entry, or a call CallKit reports as
  /// accepted/connected. The second check covers the moment before Dart has
  /// turned an accept into an entry: on iOS the FCM handler that calls this
  /// runs on the main isolate, sharing this same singleton, so a concurrent
  /// accept not yet registered is still caught here; on Android the
  /// registry is disabled and this method falls back to the old
  /// `endAllCalls()` instead — not a no-op. Matches the ringing call
  /// either by the uuid [roomName] derives ([toCallkitId]) or by its own
  /// `extra.roomName` — a VoIP-push call whose room isn't
  /// `call-<uuid>`/uuid-shaped keeps the push's own id, which doesn't equal
  /// the derived uuid. Never throws: a plugin failure is treated as "nothing
  /// ended, not known as a conversation" (false). Disabled registry: the old
  /// endAllCalls(), returns false.
  Future<bool> endRingingForRoom(String roomName) async {
    if (!enabled) {
      await _callKit.endAllCalls();
      return false;
    }
    if (_entryForRoom(roomName) != null) return true;
    final uuid = toCallkitId(roomName).toLowerCase();
    List<dynamic> calls;
    try {
      calls = await _callKit.activeCalls();
    } catch (e) {
      debugPrint('[SystemCall] endRingingForRoom: activeCalls failed: $e');
      return false;
    }
    for (final raw in calls) {
      if (raw is! Map) continue;
      final id = (raw['id'] ?? '').toString().toLowerCase();
      final extra = raw['extra'];
      final matchesRoom = extra is Map && extra['roomName'] == roomName;
      if (id != uuid && !matchesRoom) continue;
      if (raw['isAccepted'] == true || raw['accepted'] == true) return true;
      try {
        await _callKit.endCall(id);
      } catch (e) {
        debugPrint('[SystemCall] endRingingForRoom: endCall failed for $id: $e');
      }
      return false;
    }
    return false;
  }

  /// In-app line switch (call held from our own UI, e.g. switching to
  /// another conversation) mirrored into CallKit. Not call waiting, so
  /// never auto-resumed by [_onOtherCallsEnded].
  Future<void> holdForLineSwitch(String roomName, bool onHold) async {
    final entry = _entryForRoom(roomName);
    if (entry == null) return;
    if (onHold) {
      _appHolds.add(entry.uuid);
    } else {
      _appHolds.remove(entry.uuid);
    }
    try {
      await _callKit.setHeld(entry.uuid, onHold);
    } catch (e) {
      debugPrint('[SystemCall] setHeld failed for ${entry.uuid}: $e');
      // A failed hold request never actually happened: undo the mark. A
      // failed UNhold leaves the mark cleared on purpose — _onOtherCallsEnded's
      // retry (M2(b)) covers it, and putting the mark back would make a
      // later iOS unhold misread as the system's own Swap.
      if (onHold) _appHolds.remove(entry.uuid);
    }
  }

  /// The "Resume" button of the hold overlay.
  Future<void> resume(String roomName) async {
    final entry = _entryForRoom(roomName);
    if (entry == null) return;
    try {
      await _callKit.setHeld(entry.uuid, false);
    } catch (e) {
      debugPrint('[SystemCall] setHeld failed for ${entry.uuid}: $e');
    }
  }

  /// Mirrors our mute state into the system call UI.
  Future<void> setMuted(String roomName, bool muted) async {
    final entry = _entryForRoom(roomName);
    if (entry == null) return;
    try {
      await _callKit.setMuted(entry.uuid, muted);
    } catch (e) {
      debugPrint('[SystemCall] setMuted failed for ${entry.uuid}: $e');
    }
  }

  /// Our dialog's "Answer": answers the ringing CallKit call, so the call
  /// takes the same path as an answer on the CallKit UI (main.dart's accept
  /// handler connects and navigates). True at once if [roomName] is already
  /// one of our conversations — checked before consulting CallKit at all,
  /// since a call already ours might not currently be listed there.
  /// Otherwise resolves the call via [CallKitPlatform.activeCalls],
  /// matching either the uuid [roomName] derives ([toCallkitId]) or the
  /// call's own `extra.roomName` — same as [endRingingForRoom] — rather
  /// than answering blind: iOS may have rejected the incoming report
  /// (Focus/DND, a blocked number) while our dialog still shows it, and
  /// answering a uuid CallKit never heard of would otherwise just wait out
  /// [answerTimeout] for nothing. False at once when no matching call is
  /// found there either; true at once when CallKit already reports it
  /// accepted/connected; otherwise answers that call's own id — which may
  /// differ from the derived uuid, e.g. a VoIP-push fallback id — and waits
  /// for the ACCEPT up to [answerTimeout], false on timeout. If
  /// [CallKitPlatform.activeCalls] itself fails, falls back to answering
  /// the derived uuid blind. A concurrent call for the same resolved uuid
  /// shares the one pending answer instead of issuing a second CallKit
  /// request — completed false on timeout too, so the second caller is not
  /// left hanging on a completer nothing else would ever complete. False at
  /// once when disabled or not attached — the ACCEPT this waits for would
  /// never be heard.
  Future<bool> answerRinging(String roomName) async {
    if (!enabled) return false;
    if (_callKitSub == null) {
      // Not attached: the ACCEPT event this method waits for is never
      // heard, so without this guard it would just time out.
      debugPrint('[SystemCall] answerRinging before attach() — dialog takes its old path');
      return false;
    }
    if (_entryForRoom(roomName) != null) return true;
    final derivedUuid = toCallkitId(roomName).toLowerCase();
    String uuid;
    try {
      final calls = await _callKit.activeCalls();
      Map? found;
      for (final raw in calls) {
        if (raw is! Map) continue;
        final id = (raw['id'] ?? '').toString().toLowerCase();
        final extra = raw['extra'];
        final matchesRoom = extra is Map && extra['roomName'] == roomName;
        if (id == derivedUuid || matchesRoom) {
          found = raw;
          break;
        }
      }
      if (found == null) return false;
      if (found['isAccepted'] == true || found['accepted'] == true) return true;
      uuid = (found['id'] ?? '').toString().toLowerCase();
    } catch (e) {
      debugPrint('[SystemCall] answerRinging: activeCalls failed, answering blind: $e');
      uuid = derivedUuid;
    }

    final existing = _pendingAnswers[uuid];
    if (existing != null) return existing.future;

    final pending = Completer<bool>();
    _pendingAnswers[uuid] = pending;
    try {
      await _callKit.setCallConnected(uuid);
    } catch (e) {
      debugPrint('[SystemCall] answer via CallKit failed: $e');
      if (!pending.isCompleted) pending.complete(false);
    }
    final ok = await pending.future.timeout(answerTimeout, onTimeout: () {
      // Complete the completer itself, not just this wrapped future: a
      // concurrent caller sharing it awaits pending.future directly and
      // must not hang forever if CallKit never confirms.
      if (!pending.isCompleted) pending.complete(false);
      return false;
    });
    if (identical(_pendingAnswers[uuid], pending)) _pendingAnswers.remove(uuid);
    return ok;
  }

  Future<void> _end(String uuid) async {
    // Removed first: the ENDED event CallKit sends back is then not "ours",
    // and nobody hangs up a second time.
    final entry = _entries.remove(uuid);
    _appHolds.remove(uuid);
    // Hung up before CallKit confirmed the start: startOutgoing stops waiting
    // now instead of timing out.
    if (entry != null && !entry.started.isCompleted) entry.started.complete(false);
    // A native side still holding this call keeps WebRTC in manual audio —
    // the next call would be silent. Retry once, and say so loudly if not.
    if (!await _syncManaged() && !await _syncManaged()) {
      debugPrint('[SystemCall] WARNING: native still manages $uuid — audio may stay manual until the next sync');
    }
    try {
      await _callKit.endCall(uuid);
    } catch (e) {
      debugPrint('[SystemCall] endCall failed for $uuid: $e');
    }
  }

  void _onCallKitEvent(CallKitEvent event) {
    final uuid = event.uuid.toLowerCase();
    switch (event.type) {
      case CallKitEvent.typeStart:
        final entry = _entries[uuid];
        if (entry == null) {
          if (_abandonedStarts.remove(uuid)) {
            unawaited(_callKit.endCall(uuid).catchError((Object e) {
              debugPrint('[SystemCall] could not end late-started $uuid: $e');
            }));
          }
          return;
        }
        if (entry.state == _State.starting) entry.state = _State.active;
        if (!entry.started.isCompleted) entry.started.complete(true);
      case CallKitEvent.typeAccept:
        _onAccepted(uuid, event.data);
      case CallKitEvent.typeToggleHold:
        final entry = _entries[uuid];
        if (entry == null) return;
        if (event.data?['isOnHold'] == true) {
          final byApp = _appHolds.contains(uuid);
          final held = byApp ? _State.heldByApp : _State.heldBySystem;
          if (entry.state == held) return; // echo
          entry.state = held;
          _events.add(SystemCallHeld(uuid, entry.roomName, bySystem: !byApp));
        } else {
          // Computed before the mark is cleared: an entry the app itself
          // put on hold, whose mark is STILL set, means the app never
          // asked for it back (holdForLineSwitch(room, false) clears the
          // mark before requesting) — so this unhold is the system's own
          // doing, e.g. the "Swap" button.
          final swapped = entry.state == _State.heldByApp && _appHolds.contains(uuid);
          _appHolds.remove(uuid);
          if (entry.state == _State.active) return; // echo
          entry.state = _State.active;
          _events.add(SystemCallResumed(uuid, entry.roomName, swapped: swapped));
        }
      case CallKitEvent.typeToggleMute:
        final entry = _entries[uuid];
        if (entry == null) return;
        _events.add(SystemCallMuteChanged(uuid, entry.roomName,
            muted: event.data?['isMuted'] == true));
      case CallKitEvent.typeEnded || CallKitEvent.typeDecline || CallKitEvent.typeTimeout:
        // For a conversation DECLINE and ENDED mean the same: the system ended it.
        final entry = _entries.remove(uuid);
        _appHolds.remove(uuid);
        if (entry == null) return;
        unawaited(_syncManaged());
        if (!entry.started.isCompleted) entry.started.complete(false);
        _events.add(SystemCallEndedBySystem(uuid, entry.roomName, conversationId: entry.conversationId));
    }
  }

  void _onAccepted(String uuid, Map<String, dynamic>? data) {
    final pending = _pendingAnswers.remove(uuid);
    if (pending != null && !pending.isCompleted) pending.complete(true);
    if (_entries.containsKey(uuid)) return;
    final extra = data?['extra'];
    if (extra is! Map) return;
    final roomName = extra['roomName'];
    if (roomName is! String) return;
    if (!_isCallScreenConversation(roomName, kind: extra['kind'])) return;
    final conversationId = extra['conversationId'];
    _entries[uuid] = _Entry(
      uuid: uuid,
      outgoing: false,
      state: _State.active,
      roomName: roomName,
      conversationId: conversationId is String ? conversationId : null,
    );
    unawaited(_syncManaged());
  }

  /// Mesh group calls run their own audio stack, LiveKit group calls
  /// (`group-<id>`) their own screen — neither is a call-screen conversation.
  /// Must match `CallKitAudioBridge.isCallScreenConversation` (Swift).
  static bool _isCallScreenConversation(String roomName, {Object? kind}) =>
      roomName.isNotEmpty && !roomName.startsWith('group-') && kind != 'mesh_gc';

  /// The call that put us on hold is over and nothing else is going on:
  /// take the conversation back (agreed with the user 2026-09-24 — resume by
  /// itself, not by a button). If iOS resumes it first, the hold event makes
  /// this a no-op. Also retries a resume the app itself asked for
  /// ([holdForLineSwitch]) that CallKit refused while another call was up:
  /// that call's mark is already cleared (the request clears it before
  /// asking), so it reads as [_State.heldByApp] with no mark — distinct
  /// from a fresh app hold, which still has one.
  void _onOtherCallsEnded() {
    // A start CallKit hasn't confirmed yet counts as active: the user is
    // opening a new line, and resuming the held one now would fight it.
    if (_entries.values.any((e) => e.state == _State.active || e.state == _State.starting)) return;
    for (final entry in _entries.values) {
      final isCallWaitingHold = entry.state == _State.heldBySystem;
      final isRefusedAppResume = entry.state == _State.heldByApp && !_appHolds.contains(entry.uuid);
      if (isCallWaitingHold || isRefusedAppResume) {
        unawaited(_callKit.setHeld(entry.uuid, false).catchError((Object e) {
          debugPrint('[SystemCall] auto-resume setHeld failed for ${entry.uuid}: $e');
        }));
        return;
      }
    }
  }

  _Entry? _entryForRoom(String roomName) {
    for (final entry in _entries.values) {
      if (entry.roomName == roomName) return entry;
    }
    return null;
  }

  /// Pushes the current managed set to the bridge. Returns false if the
  /// bridge call failed, so a caller that must not proceed without native
  /// already treating the call as managed can bail out.
  Future<bool> _syncManaged() async {
    try {
      await _bridge.setManagedCalls(_entries.keys.toList());
      return true;
    } catch (e) {
      debugPrint('[SystemCall] setManagedCalls failed: $e');
      return false;
    }
  }
}

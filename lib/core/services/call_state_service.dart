import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:livekit_client/livekit_client.dart' as lk;
import '../api/dio_client.dart';
import '../api/endpoint_service.dart';
import '../di/service_locator.dart';

/// Represents a single call line.
class CallLine {
  final lk.Room room;
  final String roomName;
  final String? conversationId;
  final String? e2eeKey;
  /// Room-scoped LiveKit token from the join response (`POST /voice/rooms`
  /// or `.../join`) — NOT the Taler ID access token. Needed by the room-chat
  /// REST endpoints (`POST`/`GET /voice/rooms/:roomName/chat`): their
  /// `RoomAccessGuard` only admits a Taler ID token for the call's own
  /// participant, the personal room's owner, or the ad-hoc room's creator,
  /// so a logged-in guest let into someone else's temporary room would get a
  /// 403 with it. This token is what LiveKit itself issued to authorize the
  /// bearer for this exact room, valid for guest and account holder alike.
  /// Replaced (new `CallLine`, see [CallStateService.setRoom]) on every
  /// reconnect, since a fresh join issues a fresh token.
  final String? lkToken;
  String? calleeName;
  String? calleeAvatar;
  bool isOnHold;
  /// Mic state before the line was put on hold.
  bool wasMuted = false;
  /// When the call was connected (for duration display).
  DateTime? connectedAt;
  /// iOS put this line on hold for another call (call waiting).
  bool heldBySystem = false;
  /// Mic state when that hold began — restored on resume.
  bool micOnBeforeSystemHold = false;

  CallLine({
    required this.room,
    required this.roomName,
    this.conversationId,
    this.e2eeKey,
    this.lkToken,
    this.calleeName,
    this.calleeAvatar,
    this.isOnHold = false,
  });
}

class CallStateService {
  static final instance = CallStateService._();
  CallStateService._();

  static const maxLines = 3;

  /// All active call lines, keyed by roomName.
  final Map<String, CallLine> _lines = {};
  /// Currently active (foreground) line.
  String? _activeRoomName;

  /// Active group-call id (Phase 1) — null if user is not in a group call.
  /// Independent from [_activeRoomName] (which tracks 1-on-1 voice rooms).
  String? _activeGroupCallId;
  final _activeGroupCallCtrl = StreamController<String?>.broadcast();

  bool _bgConnecting = false;
  Completer<bool>? _bgCompleter;

  /// Room + conversation id of the join [_bgCompleter] belongs to. Set at the
  /// top of [connectInBackground]; read by [abandonBackgroundConnect] to
  /// decide whether a given room is the join currently in flight, and to
  /// hand back its conversation id (there is no line yet to read it from).
  /// Cleared in `settleOwn`, under the same identity guard as `_bgCompleter`
  /// itself — only the attempt that still owns it may clear it.
  String? _bgRoomName;
  String? _bgConvId;

  /// Bumped by [endCall], [notifyEnded] and [abandonBackgroundConnect], and
  /// once per [connectInBackground].
  ///
  /// connectInBackground awaits an HTTP join and a LiveKit connect, either of
  /// which can outlive the call: the user hangs up, or `call_ended` arrives,
  /// while we are still dialling. Checking `_bgConnecting` alone is not enough
  /// — a *new* background connect sets it back to true, and the stale attempt
  /// would take that as "still mine". Comparing generations tells the two apart.
  int _bgGeneration = 0;

  /// Outgoing-call glare tracking.
  ///
  /// When the user opens an outgoing voice call screen, this is set to the
  /// callee's userId (+roomName). If a call_invite arrives from that same
  /// userId while it's set, both sides dialed each other simultaneously
  /// (glare). The dashboard incoming-call handler uses [outgoingPeerId] to
  /// suppress the regular ringing UI and show a choice dialog instead.
  String? _outgoingPeerId;
  String? _outgoingRoomName;
  String? get outgoingPeerId => _outgoingPeerId;
  String? get outgoingRoomName => _outgoingRoomName;

  void markOutgoing(String peerId, String? roomName) {
    _outgoingPeerId = peerId;
    _outgoingRoomName = roomName;
  }

  /// Clears the outgoing marker iff it matches the given peer. Pass null to
  /// force-clear. Matching prevents a stale dispose from a previous outgoing
  /// screen wiping a newer one.
  void clearOutgoing({String? peerId}) {
    if (peerId == null || peerId == _outgoingPeerId) {
      _outgoingPeerId = null;
      _outgoingRoomName = null;
    }
  }

  /// Rooms where the AI voice twin has taken over. These calls must survive
  /// a stale `call_ended` broadcast from the original human callee (their
  /// CallKit/push banner expired, they dismissed it, etc.) — we don't want
  /// Dashboard/CallKit cleanup to deactivate the iOS audio session while the
  /// caller is still talking to the AI twin.
  final Set<String> _aiTwinActiveRooms = {};
  void markAiTwinActive(String roomName) => _aiTwinActiveRooms.add(roomName);
  void unmarkAiTwinActive(String roomName) => _aiTwinActiveRooms.remove(roomName);
  bool isAiTwinRoom(String roomName) => _aiTwinActiveRooms.contains(roomName);

  /// Rooms where a sibling device (same account) has already answered the
  /// incoming call. Used to bail out early from LiveKit join so both devices
  /// don't end up in the same room (which turns a 1-on-1 into a 3-way).
  final Set<String> _answeredElsewhereRooms = {};
  void markAnsweredElsewhere(String roomName) => _answeredElsewhereRooms.add(roomName);
  bool isAnsweredElsewhere(String roomName) => _answeredElsewhereRooms.contains(roomName);

  /// Rooms where THIS device sent `call_answered`. The server echoes the
  /// event back to us; without this we'd incorrectly mark our own accepted
  /// call as "answered elsewhere". Set right before emitting call_answered.
  final Set<String> _selfAnsweredRooms = {};
  void markSelfAnswered(String roomName) => _selfAnsweredRooms.add(roomName);
  bool didSelfAnswer(String roomName) => _selfAnsweredRooms.contains(roomName);

  /// Clear both answered flags for a room. Call when a room ends so a
  /// subsequent call with the same id (rare, but possible) isn't blocked.
  void clearAnsweredState(String roomName) {
    _answeredElsewhereRooms.remove(roomName);
    _selfAnsweredRooms.remove(roomName);
  }

  /// Rooms the system ended before CallStateService ever got a line for
  /// them — e.g. a system End while [connectInBackground]'s join was still
  /// in flight. A pending call route (NotificationService, main.dart) can
  /// outlive that cancellation; [consumeSystemEnded] lets whoever is about
  /// to act on a stale copy of it check first. True once, then forgotten —
  /// [setRoom] also forgets a stale mark the moment this room name is
  /// legitimately reused, and [endCall] clears the lot.
  final Set<String> _systemEndedRooms = {};
  void markSystemEnded(String roomName) => _systemEndedRooms.add(roomName);
  bool consumeSystemEnded(String roomName) => _systemEndedRooms.remove(roomName);

  final _stateCtrl = StreamController<bool>.broadcast();
  // Re-emit the current state to every new subscriber so the dashboard's
  // "active call" banner reappears correctly after the voice screen is
  // closed and the dashboard is rebuilt.
  Stream<bool> get stateStream async* {
    yield isInCall;
    yield* _stateCtrl.stream;
  }

  /// Emits the active roomName whenever the active line changes externally
  /// (e.g. CallKit accept of a second call). VoiceCallScreen subscribes to
  /// this to detect switches it didn't initiate.
  final _activeRoomCtrl = StreamController<String?>.broadcast();
  Stream<String?> get activeRoomStream => _activeRoomCtrl.stream;

  // ── Legacy single-room API (backward compatible) ─────────────────

  lk.Room? get room => activeLine?.room;
  String? get roomName => _activeRoomName;
  String? get conversationId => activeLine?.conversationId;
  String? get e2eeKey => activeLine?.e2eeKey;
  /// Room-scoped LiveKit token for the active line — see [CallLine.lkToken].
  String? get lkToken => activeLine?.lkToken;

  bool get isInCall => _lines.isNotEmpty;
  bool get isBackgroundConnecting => _bgConnecting;

  // ── Group-call API (Phase 1) ─────────────────────────────────────

  /// Active group-call id (Phase 1) — null if user is not in a group call.
  /// Independent from [roomName] (1-on-1 voice rooms).
  String? get activeGroupCallId => _activeGroupCallId;

  /// Broadcast stream of group-call id changes (null/id transitions).
  Stream<String?> get activeGroupCallStream => _activeGroupCallCtrl.stream;

  /// True if user is in any kind of call — 1-on-1 voice OR group voice.
  bool get isInAnyCall => _lines.isNotEmpty || _activeGroupCallId != null;

  void setActiveGroupCall(String? id) {
    if (_activeGroupCallId == id) return;
    _activeGroupCallId = id;
    if (!_activeGroupCallCtrl.isClosed) {
      _activeGroupCallCtrl.add(id);
    }
  }

  // ── Multi-line API ───────────────────────────────────────────────

  CallLine? get activeLine => _activeRoomName != null ? _lines[_activeRoomName] : null;
  List<CallLine> get allLines => _lines.values.toList();
  int get lineCount => _lines.length;
  bool get hasHeldLines => _lines.values.any((l) => l.isOnHold);
  bool get canAddLine => _lines.length < maxLines;

  // ── System calls (iOS CallKit) ───────────────────────────────────────────

  /// Ends the CallKit call of every line that goes away, whichever path
  /// removes it. Set in main.dart; null on platforms without CallKit calls.
  Future<void> Function(String roomName)? onLineEnded;

  /// Mirrors in-app line switching into CallKit holds.
  Future<void> Function(String roomName, bool onHold)? onLineHoldChanged;

  /// Rooms the system already held before their `CallLine` existed —
  /// "Hold & Accept" can land while the LiveKit join for that room is still
  /// in flight. Consumed by [setRoom] once the line finally shows up.
  final Set<String> _pendingSystemHolds = {};

  void _reportLineEnded(String roomName) {
    final hook = onLineEnded;
    if (hook == null) return;
    // Future.sync catches a synchronous throw from the hook too — without
    // it, a hook that throws before returning its Future would propagate
    // straight out of here and abort whatever call site (e.g. endCall,
    // mid-way through disconnecting rooms) invoked us.
    unawaited(Future.sync(() => hook(roomName)).catchError((Object e) {
      debugPrint('[CallState] onLineEnded hook failed: $e');
    }));
  }

  void _reportLineHold(String roomName, bool onHold) {
    final hook = onLineHoldChanged;
    if (hook == null) return;
    unawaited(Future.sync(() => hook(roomName, onHold)).catchError((Object e) {
      debugPrint('[CallState] onLineHoldChanged hook failed: $e');
    }));
  }

  /// What the user wants this line's mic to be right now, independent of
  /// whichever hold — system or in-app — currently forces it off. Reads
  /// whichever *other* hold's recorded intent applies, or the live hardware
  /// state if the line isn't held at all.
  bool _micWanted(CallLine l) {
    if (l.heldBySystem) return l.micOnBeforeSystemHold;
    if (l.isOnHold) return !l.wasMuted;
    return l.room.localParticipant?.isMicrophoneEnabled() ?? false;
  }

  /// Un-holds a line the app itself put on hold, without touching the
  /// active-line pointer — the caller decides whether this line stays (or
  /// becomes) active. Shared by connectInBackground's failure path and
  /// holdAndSwitch's target-vanished-mid-flight path: both need to roll
  /// back an in-app hold the same way.
  Future<void> _undoAppHold(CallLine line) async {
    line.isOnHold = false;
    _reportLineHold(line.roomName, false);
    if (!line.heldBySystem) {
      try {
        await line.room.localParticipant?.setMicrophoneEnabled(!line.wasMuted);
      } catch (_) {}
    }
  }

  /// Call waiting took the audio: the peer gets a muted mic, and whatever the
  /// mic was is remembered for the resume. A room with no line yet (join
  /// still in flight) is remembered as pending — see [_pendingSystemHolds].
  Future<void> applySystemHold(String roomName) async {
    final line = _lines[roomName];
    if (line == null) {
      _pendingSystemHolds.add(roomName);
      return;
    }
    if (line.heldBySystem) return;
    line.micOnBeforeSystemHold = _micWanted(line);
    line.heldBySystem = true;
    try {
      await line.room.localParticipant?.setMicrophoneEnabled(false);
    } catch (_) {}
  }

  /// Only this method may turn a `heldBySystem` line's mic on — and even
  /// then, not if the line is also app-held (`isOnHold`): the in-app switch
  /// back to it owns the mic in that case.
  Future<void> applySystemResume(String roomName) async {
    _pendingSystemHolds.remove(roomName);
    final line = _lines[roomName];
    if (line == null || !line.heldBySystem) return;
    line.heldBySystem = false;
    if (line.isOnHold) {
      // Both holds were active and the system let go first. Fold its
      // recorded intent into wasMuted — the in-app switch back reads
      // wasMuted, not micOnBeforeSystemHold, and would otherwise apply
      // whatever wasMuted was left at from before this hold even started.
      line.wasMuted = !line.micOnBeforeSystemHold;
      return;
    }
    if (!line.micOnBeforeSystemHold) return;
    try {
      await line.room.localParticipant?.setMicrophoneEnabled(true);
    } catch (_) {}
  }

  /// The mute button of the system call UI. A held line (either way) never
  /// touches the mic directly — it records what the user wants for whichever
  /// hold ends first (system resume, or the in-app line switch) to apply.
  Future<void> applySystemMute(String roomName, bool muted) => setLineMuted(roomName, muted);

  /// The app's own mute button — same held-line rule as [applySystemMute].
  Future<void> setLineMuted(String roomName, bool muted) async {
    final line = _lines[roomName];
    if (line == null) return;
    if (line.heldBySystem) {
      line.micOnBeforeSystemHold = !muted;
      return;
    }
    if (line.isOnHold) {
      line.wasMuted = muted;
      return;
    }
    try {
      await line.room.localParticipant?.setMicrophoneEnabled(!muted);
    } catch (_) {}
  }

  Future<bool> waitForBackgroundConnect() async {
    if (!_bgConnecting || _bgCompleter == null) return isInCall;
    return _bgCompleter!.future;
  }

  void setRoom(lk.Room r, String name, String? convId, {String? e2eeKeyValue, String? lkToken, String? calleeName, String? calleeAvatar}) {
    // A stale "system ended" mark must not survive this room name getting a
    // real line — meeting/personal rooms are reused, and consumeSystemEnded
    // reading true for a call that never had anything to do with the old
    // mark would be as wrong as the leak it exists to catch.
    _systemEndedRooms.remove(name);
    final previous = _lines[name];
    final line = CallLine(
      room: r,
      roomName: name,
      conversationId: convId,
      e2eeKey: e2eeKeyValue,
      lkToken: lkToken,
      calleeName: calleeName,
      calleeAvatar: calleeAvatar,
    );
    line.connectedAt = DateTime.now();
    if (previous != null) {
      // Reconnect (_startManualReconnect): a system hold in effect on the
      // old line must carry over, or applySystemResume later has nothing
      // left to resume and the mic never comes back.
      line.heldBySystem = previous.heldBySystem;
      line.micOnBeforeSystemHold = previous.micOnBeforeSystemHold;
    } else if (_pendingSystemHolds.remove(name)) {
      // The system already held this call before we'd even joined it — the
      // line starts held so nothing turns the mic on until resume says so.
      line.heldBySystem = true;
      line.micOnBeforeSystemHold = true;
    }
    _lines[name] = line;
    _activeRoomName = name;
    _stateCtrl.add(true);
    _activeRoomCtrl.add(name);
  }

  /// Put the active call on hold and switch to another line.
  Future<void> holdAndSwitch(String targetRoomName) async {
    final target = _lines[targetRoomName];
    // Already the active, non-held line: nothing to do. _initCall calls this
    // for an already-connected conversation, and without this guard it would
    // report an unhold — asking CallKit to resume our call in the middle of
    // call waiting, taking the audio back from WhatsApp, for a switch that
    // never actually happened. A *stuck* isOnHold on the active line (e.g.
    // from an interrupted switch — see the target-vanished undo below)
    // still falls through: the dashboard shows the swap icon for any
    // isOnHold line and calls holdAndSwitch on it, which is how it clears.
    if (target != null && _activeRoomName == targetRoomName && !target.isOnHold) {
      return;
    }

    final current = activeLine;
    if (current != null && current.roomName != targetRoomName) {
      // Save mic state before hold so it can be restored later.
      current.wasMuted = !_micWanted(current);
      current.isOnHold = true;
      _reportLineHold(current.roomName, true);
      try {
        await current.room.localParticipant?.setMicrophoneEnabled(false);
        await current.room.localParticipant?.setCameraEnabled(false);
      } catch (_) {}
    }

    // The awaits above can outlive `target` (its line ends — screen
    // hang-up, system end — while we were still muting `current`):
    // re-resolve by identity rather than trusting the lookup from before
    // them, or this would switch the UI onto a room that's already gone.
    if (!identical(_lines[targetRoomName], target)) {
      if (current != null &&
          current.roomName != targetRoomName &&
          identical(_lines[current.roomName], current) &&
          _activeRoomName == current.roomName &&
          current.isOnHold) {
        await _undoAppHold(current);
      }
      return;
    }

    if (target != null) {
      target.isOnHold = false;
      _reportLineHold(targetRoomName, false);
      _activeRoomName = targetRoomName;
      // heldBySystem still owns the mic — only applySystemResume may turn it
      // on for this line.
      if (!target.heldBySystem) {
        try {
          // Restore the mic state the user had before this line was held.
          await target.room.localParticipant?.setMicrophoneEnabled(!target.wasMuted);
        } catch (_) {}
      }
      _stateCtrl.add(true);
      _activeRoomCtrl.add(targetRoomName);
    }
  }

  /// Disconnects a room with a bounded wait — a hung disconnect (dead room,
  /// unresponsive LiveKit) must not stall whoever is waiting on it forever.
  /// Timeout and any error are swallowed, same as
  /// VoiceCallScreen._hangUpInner's own guard around room.disconnect().
  Future<void> _disconnectRoom(lk.Room room) async {
    try {
      await room.disconnect().timeout(const Duration(seconds: 2), onTimeout: () {});
    } catch (_) {}
  }

  /// End a specific call line.
  Future<void> endLine(String name) async {
    final line = _lines.remove(name);
    clearAnsweredState(name);
    // Unconditional, whether or not `name` was ever a line: a system hold
    // can land for a room that's still joining (see applySystemHold), and
    // if that join then ends here — screen hang-up, a system end, a failed
    // join's own cleanup — the pending hold must not survive it. Meeting
    // and personal rooms are reused, so leaving it would make the *next*
    // line for this room start heldBySystem with no CallKit hold behind
    // it: the lock-screen mute gets recorded but never applied, and a real
    // later hold hits applySystemHold's already-held early return.
    _pendingSystemHolds.remove(name);
    if (line != null) {
      // Disconnect BEFORE reporting the line ended: onLineEnded ends this
      // conversation's CallKit call, which releases our manual WebRTC audio
      // ownership. A still-connected room would then have WebRTC grab the
      // audio unit and activate the session on its own — mid a
      // WhatsApp/cellular call, if this line had been on hold for one.
      await _disconnectRoom(line.room);
      _reportLineEnded(name);
      // A hold can land for `name` while the disconnect above was in
      // flight: the line was already removed at the top of this method, so
      // applySystemHold reads it as unknown and re-adds it to
      // _pendingSystemHolds. Remove it again, or it leaks into whatever
      // this reused room name's next line turns out to be.
      _pendingSystemHolds.remove(name);
    }
    if (_activeRoomName == name) {
      // Switch to another held line if available
      if (_lines.isNotEmpty) {
        final next = _lines.values.first;
        _activeRoomName = next.roomName;
        next.isOnHold = false;
        _reportLineHold(next.roomName, false);
        if (!next.heldBySystem) {
          try {
            await next.room.localParticipant?.setMicrophoneEnabled(!next.wasMuted);
          } catch (_) {}
        }
        _activeRoomCtrl.add(next.roomName);
      } else {
        _activeRoomName = null;
        _activeRoomCtrl.add(null);
      }
    }
    _stateCtrl.add(_lines.isNotEmpty);
  }

  Future<void> endCall() async {
    final lines = List<CallLine>.from(_lines.values);
    _lines.clear();
    _activeRoomName = null;
    _bgConnecting = false;
    _bgGeneration++;
    _answeredElsewhereRooms.clear();
    _selfAnsweredRooms.clear();
    _pendingSystemHolds.clear();
    _systemEndedRooms.clear();
    // Cleared and emitted before the disconnects below are awaited — "the
    // call ended" reaches subscribers right away, not only once every room
    // has (possibly slowly) hung up.
    _stateCtrl.add(false);
    _activeRoomCtrl.add(null);
    // Disconnect every room BEFORE reporting any line ended — same reason
    // as endLine: a room still connected when onLineEnded releases manual
    // WebRTC audio ownership would have WebRTC grab it right back. Parallel,
    // so N held lines cost one 2 s timeout, not N of them in a row.
    await Future.wait(lines.map((line) => _disconnectRoom(line.room)));
    for (final line in lines) {
      _reportLineEnded(line.roomName);
      // Same race as endLine: a hold can land for this room while its
      // disconnect was in flight above, re-adding it to _pendingSystemHolds.
      // Remove it again, or it leaks into whatever this room name's next
      // line turns out to be.
      _pendingSystemHolds.remove(line.roomName);
    }
  }

  /// Contract: callers disconnect the room first — this never does it itself.
  void notifyEnded() {
    // Remove the active line (or all if unknown)
    if (_activeRoomName != null) {
      final ended = _activeRoomName!;
      if (_lines.remove(ended) != null) _reportLineEnded(ended);
      if (_lines.isNotEmpty) {
        final next = _lines.values.first;
        _activeRoomName = next.roomName;
        next.isOnHold = false;
        _reportLineHold(next.roomName, false);
        // notifyEnded is sync (called straight from the socket/CallKit
        // handler), so the restore can't be awaited here — fire it the same
        // way the hooks above do. heldBySystem still owns the mic in that
        // case, same rule as everywhere else.
        final mic = next.room.localParticipant;
        if (mic != null && !next.heldBySystem) {
          unawaited(() async {
            try {
              await mic.setMicrophoneEnabled(!next.wasMuted);
            } catch (e) {
              debugPrint('[CallState] notifyEnded mic restore failed: $e');
            }
          }());
        }
      } else {
        _activeRoomName = null;
      }
    } else {
      // Copy the keys: _reportLineEnded's hook can re-enter (e.g. a hook
      // that itself starts a new call via setRoom) and mutate _lines while
      // this loop is still walking its live key view.
      for (final name in _lines.keys.toList()) {
        _reportLineEnded(name);
      }
      _lines.clear();
    }
    _bgConnecting = false;
    _bgGeneration++;
    _stateCtrl.add(_lines.isNotEmpty);
  }

  /// Cancels the background join in flight for [roomName], if that is what
  /// is currently in flight — e.g. a system End arrived for a call CallKit
  /// already marked answered, but whose LiveKit join hasn't produced a line
  /// yet (see [_endBackgroundLine] in main.dart). Bumps the generation so
  /// connectInBackground's own cancellation checks (after the HTTP join,
  /// after the LiveKit connect) take it from here — same path a stale
  /// attempt already takes when a newer one supersedes it — so the mic never
  /// gets turned on for a call the user just ended, and whichever line it
  /// held for the switch gets its hold undone there.
  ///
  /// Returns the abandoned join's conversation id — the caller needs it to
  /// send `call_ended`, since without a line there is nowhere else in
  /// CallStateService to read it from — or null when [roomName] is not the
  /// join currently in flight (nothing to abandon).
  String? abandonBackgroundConnect(String roomName) {
    if (!_bgConnecting || _bgRoomName != roomName) return null;
    final convId = _bgConvId;
    _bgGeneration++;
    _bgConnecting = false;
    final completer = _bgCompleter;
    if (completer != null && !completer.isCompleted) completer.complete(false);
    _bgCompleter = null;
    _bgRoomName = null;
    _bgConvId = null;
    return convId;
  }

  /// Connect to a LiveKit room in the background after CallKit accept.
  Future<bool> connectInBackground(String rName, String? convId, {String? e2eeKey}) async {
    if (_lines.containsKey(rName)) return true;
    if (_lines.length >= maxLines) return false;
    if (_bgConnecting) return _bgCompleter?.future ?? Future.value(false);
    _bgConnecting = true;
    final completer = Completer<bool>();
    _bgCompleter = completer;
    final gen = ++_bgGeneration;
    _bgRoomName = rName;
    _bgConvId = convId;

    // Only settle our own completer: by the time a cancelled attempt unwinds,
    // a newer connect may already own _bgCompleter. Never clears _bgConnecting
    // either — whoever cancelled us has set it, or a newer attempt owns it now.
    void settleOwn(bool value) {
      if (!completer.isCompleted) completer.complete(value);
      if (identical(_bgCompleter, completer)) {
        _bgCompleter = null;
        _bgRoomName = null;
        _bgConvId = null;
      }
    }

    // Declared outside the try so the catch block below can undo the hold
    // on failure — a failed join (caller hung up, network blip) must not
    // strand line A app-held with nothing left to ever resume it.
    CallLine? current;
    try {
      // Hold current active line, preserving mic state
      current = activeLine;
      if (current != null) {
        current.wasMuted = !_micWanted(current);
        current.isOnHold = true;
        _reportLineHold(current.roomName, true);
        try {
          await current.room.localParticipant?.setMicrophoneEnabled(false);
          await current.room.localParticipant?.setCameraEnabled(false);
        } catch (_) {}
      }

      final client = sl<DioClient>();
      final res = await client.post<Map<String, dynamic>>(
        '/voice/rooms/$rName/join',
        data: {},
        fromJson: (d) => Map<String, dynamic>.from(d as Map),
      );
      // The call may have ended while the join request was in flight.
      if (gen != _bgGeneration) {
        debugPrint('[CallState] connectInBackground cancelled after join, room=$rName');
        // Same undo as the catch block below, minus its `gen == _bgGeneration`
        // guard — we are already inside the branch where that would be
        // false. After endCall/notifyEnded, `current`'s line is gone too, so
        // the identical() check is false and this is a no-op; after
        // abandonBackgroundConnect it is not — line A comes back off hold.
        if (current != null &&
            identical(_lines[current.roomName], current) &&
            _activeRoomName == current.roomName &&
            current.isOnHold) {
          await _undoAppHold(current);
        }
        settleOwn(false);
        return false;
      }

      final token = res['token'] as String;
      final r = lk.Room();

      lk.E2EEOptions? e2eeOptions;
      if (e2eeKey != null) {
        final keyProvider = await lk.BaseKeyProvider.create(sharedKey: true);
        await keyProvider.setSharedKey(e2eeKey);
        e2eeOptions = lk.E2EEOptions(keyProvider: keyProvider);
      }

      await r.connect(
        // mediaBaseUrl, not baseUrl: an edge may relay the API while its
        // /livekit/ reaches no SFU, and calls 502 there.
        '${sl<EndpointService>().mediaBaseUrl.replaceFirst('https://', 'wss://')}/livekit/',
        token,
        roomOptions: lk.RoomOptions(
          e2eeOptions: e2eeOptions,
          defaultAudioPublishOptions: const lk.AudioPublishOptions(audioBitrate: 32000),
        ),
      );
      // Same check after the LiveKit connect: without it setRoom() would put
      // the line back into _lines and emit "in call" for a call the user has
      // already hung up, leaving a live room and a hot mic behind.
      if (gen != _bgGeneration) {
        debugPrint('[CallState] connectInBackground cancelled after connect, room=$rName');
        try {
          await r.disconnect();
        } catch (_) {}
        // Same undo, same reasoning as the cancel-after-join branch above.
        if (current != null &&
            identical(_lines[current.roomName], current) &&
            _activeRoomName == current.roomName &&
            current.isOnHold) {
          await _undoAppHold(current);
        }
        settleOwn(false);
        return false;
      }

      // lkToken: token — the SAME `token` this method already used for
      // r.connect() above, the room-scoped LiveKit join token from the
      // /join response at line 337. Not the Taler ID access token, not
      // anything from SecureStorageService — those authenticate the
      // *account*, and RoomChatApi needs a token that authenticates the
      // *room* (see CallLine.lkToken's doc for why the two aren't
      // interchangeable: a guest in someone else's temporary room has no
      // Taler ID standing to write to it at all).
      //
      // Omitting this parameter here was exactly the gap this feature branch
      // shipped with until this line was added: a call answered from the
      // background (CallKit accept / dashboard in-app accept while on
      // another screen) reaches this line, but
      // VoiceCallScreen never runs its own `_connect()` for it — the room
      // is already up by the time the screen appears, so it takes the
      // "already connected" resume branch in `_initCall()`, which only
      // copies `CallLine.lkToken` into `_lkToken`. If this line doesn't put
      // a token on the CallLine, that branch has nothing to copy, `_lkToken`
      // stays null, and the room chat panel fails every send/history fetch
      // for the rest of the call — silently, since a null token just makes
      // RoomChatApi's caller bail out early rather than throw. There's no
      // stack trace pointing back here; it looks like the chat feature
      // itself is broken, not this one missing argument.
      setRoom(r, rName, convId, e2eeKeyValue: e2eeKey, lkToken: token);
      // A pending system hold (see setRoom/_pendingSystemHolds) means this
      // very line started heldBySystem — only applySystemResume may turn
      // its mic on then, same rule as everywhere else.
      if (!(_lines[rName]?.heldBySystem ?? false)) {
        try {
          await r.localParticipant?.setMicrophoneEnabled(true);
        } catch (_) {}
      }
      try {
        await Future.delayed(const Duration(milliseconds: 500));
        const audioChannel = MethodChannel('taler_id/audio');
        await audioChannel.invokeMethod('setAudioOutput', 'earpiece');
        await lk.Hardware.instance.setSpeakerphoneOn(false);
      } catch (_) {}
      debugPrint('[CallState] connectInBackground OK, room=$rName, e2ee=${e2eeKey != null}, lines=${_lines.length}');
      _bgConnecting = false;
      settleOwn(true);
      return true;
    } catch (e) {
      debugPrint('[CallState] connectInBackground failed: $e');
      if (gen == _bgGeneration) _bgConnecting = false;
      // Undo the hold placed on the previous line above, but only if it's
      // still exactly what we left it as: a newer connect/switch may have
      // already moved it on, and clobbering that would be worse than the
      // original bug.
      if (gen == _bgGeneration &&
          current != null &&
          identical(_lines[current.roomName], current) &&
          _activeRoomName == current.roomName &&
          current.isOnHold) {
        await _undoAppHold(current);
      }
      settleOwn(false);
      return false;
    }
  }
}

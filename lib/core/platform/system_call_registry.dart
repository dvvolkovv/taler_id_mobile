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
  const SystemCallResumed(super.uuid, super.roomName);
}

/// The mute button of the system call UI (lock screen, Dynamic Island).
final class SystemCallMuteChanged extends SystemCallEvent {
  const SystemCallMuteChanged(super.uuid, super.roomName, {required this.muted});
  final bool muted;
}

/// Ended outside the app: the system End button, "End & Accept".
final class SystemCallEndedBySystem extends SystemCallEvent {
  const SystemCallEndedBySystem(super.uuid, super.roomName);
}

enum _State { starting, active, heldBySystem, heldByApp }

class _Entry {
  _Entry({required this.uuid, required this.outgoing, required this.state, this.roomName});

  final String uuid;
  final bool outgoing;
  String? roomName;
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
    _entries.remove(uuid);
    _abandonedStarts.add(uuid);
    await _syncManaged();
    debugPrint('[SystemCall] CallKit did not confirm $uuid — call runs without it');
    return null;
  }

  /// Attaches the room name once the server has created the room.
  void bindRoom(String uuid, String roomName) {
    _entries[uuid.toLowerCase()]?.roomName = roomName;
  }

  /// A conversation whose CallKit call was answered while the app was not
  /// listening (cold start after an answer on the lock screen).
  Future<void> adoptAnswered({required String uuid, required String roomName}) async {
    if (!enabled) return;
    if (!_isCallScreenConversation(roomName)) return;
    final key = uuid.toLowerCase();
    if (_entries.containsKey(key)) return;
    _entries[key] = _Entry(uuid: key, outgoing: false, state: _State.active, roomName: roomName);
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
    }
  }

  void _onAccepted(String uuid, Map<String, dynamic>? data) {
    if (_entries.containsKey(uuid)) return;
    final extra = data?['extra'];
    if (extra is! Map) return;
    final roomName = extra['roomName'];
    if (roomName is! String) return;
    if (!_isCallScreenConversation(roomName, kind: extra['kind'])) return;
    _entries[uuid] = _Entry(uuid: uuid, outgoing: false, state: _State.active, roomName: roomName);
    unawaited(_syncManaged());
  }

  /// Mesh group calls run their own audio stack, LiveKit group calls
  /// (`group-<id>`) their own screen — neither is a call-screen conversation.
  /// Must match `CallKitAudioBridge.isCallScreenConversation` (Swift).
  static bool _isCallScreenConversation(String roomName, {Object? kind}) =>
      roomName.isNotEmpty && !roomName.startsWith('group-') && kind != 'mesh_gc';

  void _onOtherCallsEnded() {}

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

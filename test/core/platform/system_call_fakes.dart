// test/core/platform/system_call_fakes.dart
import 'dart:async';

import 'package:taler_id_mobile/core/platform/call_kit.dart';
import 'package:taler_id_mobile/core/platform/system_call_bridge.dart';

class FakeCallKit implements CallKitPlatform {
  final _events = StreamController<CallKitEvent>.broadcast();

  /// Everything the registry asked for, e.g. `endCall:<uuid>`.
  final log = <String>[];
  List<dynamic> active = [];
  bool confirmStarts = true;

  /// Set by a test that needs [activeCalls] to fail, e.g. to exercise
  /// dismissRinging's/endRingingForRoom's error handling.
  Object? activeCallsError;

  /// Set by a test that needs [endCall] to fail after logging the attempt,
  /// e.g. to exercise dismissRinging's/endRingingForRoom's/_end's error
  /// handling.
  Object? endCallError;

  /// Set by a test that needs [setHeld] to fail after logging the attempt,
  /// e.g. to exercise _onOtherCallsEnded's/holdForLineSwitch's/resume's
  /// error handling.
  Object? setHeldError;

  /// Set by a test that needs to observe call order across both fakes,
  /// without changing what [log] records.
  void Function(String tag)? onCall;

  /// iOS echoes hold/mute toggles with the upper-case `uuidString` Swift
  /// keeps (see [CallKitEvent.typeToggleHold]/[typeToggleMute]); START and
  /// ACCEPT are passed through as given so a test can pick either case.
  void emit(String type, String uuid, [Map<String, dynamic> data = const {}]) {
    final id = (type == CallKitEvent.typeToggleHold || type == CallKitEvent.typeToggleMute)
        ? uuid.toUpperCase()
        : uuid;
    _events.add(CallKitEvent(type: type, uuid: id, data: {'id': id, ...data}));
  }

  @override
  Stream<CallKitEvent> get events => _events.stream;

  @override
  Future<void> startCall({
    required String uuid,
    required String callerName,
    required String handle,
    Map<String, dynamic>? extra,
  }) async {
    onCall?.call('startCall');
    log.add('startCall:$uuid:$callerName:$handle');
    if (confirmStarts) emit(CallKitEvent.typeStart, uuid);
  }

  @override
  Future<void> setCallConnected(String uuid) async => log.add('setCallConnected:$uuid');

  @override
  Future<void> setHeld(String uuid, bool onHold) async {
    log.add('setHeld:$uuid:$onHold');
    if (setHeldError != null) throw setHeldError!;
  }

  @override
  Future<void> setMuted(String uuid, bool muted) async => log.add('setMuted:$uuid:$muted');

  @override
  Future<void> endCall(String uuid) async {
    log.add('endCall:$uuid');
    if (endCallError != null) throw endCallError!;
  }

  @override
  Future<void> endAllCalls() async => log.add('endAllCalls');

  @override
  Future<List<dynamic>> activeCalls() async {
    if (activeCallsError != null) throw activeCallsError!;
    return active;
  }

  @override
  Future<String?> getDevicePushTokenVoIP() async => null;

  @override
  Future<void> showIncomingCall({
    required String uuid,
    required String callerName,
    required String roomName,
    String? handle,
    String? avatar,
    bool isVideo = false,
    Map<String, dynamic>? extra,
    String? textAccept,
    String? textDecline,
    int? durationMs,
    String? androidIncomingChannelName,
    String? androidMissedChannelName,
  }) async {}
}

class FakeBridge implements SystemCallBridge {
  final managed = <List<String>>[];
  int prepared = 0;
  final _otherCallsEnded = StreamController<void>.broadcast();

  /// Set by a test to make [prepareCallAudio] throw, e.g. to exercise
  /// startOutgoing's early-abort path.
  Object? prepareCallAudioError;

  /// Set by a test to make [setManagedCalls] throw, e.g. to exercise
  /// startOutgoing's initial-sync early-abort path.
  Object? setManagedCallsError;

  /// Set by a test that needs to observe call order across both fakes,
  /// without changing what [managed] / [prepared] record.
  void Function(String tag)? onCall;

  List<String> get lastManaged => managed.isEmpty ? const [] : managed.last;
  void otherCallsGone() => _otherCallsEnded.add(null);

  @override
  Future<void> setManagedCalls(List<String> uuids) async {
    onCall?.call('setManagedCalls');
    if (setManagedCallsError != null) throw setManagedCallsError!;
    managed.add(List.of(uuids));
  }

  @override
  Future<void> prepareCallAudio() async {
    onCall?.call('prepareCallAudio');
    if (prepareCallAudioError != null) throw prepareCallAudioError!;
    prepared++;
  }

  @override
  Stream<void> get otherCallsEnded => _otherCallsEnded.stream;
}

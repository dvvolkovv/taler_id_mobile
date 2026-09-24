import 'dart:async';

import 'package:taler_id_mobile/core/platform/call_kit.dart';
import 'package:taler_id_mobile/core/platform/system_call_bridge.dart';

class FakeCallKit implements CallKitPlatform {
  final _events = StreamController<CallKitEvent>.broadcast();

  /// Everything the registry asked for, e.g. `endCall:<uuid>`.
  final log = <String>[];
  List<dynamic> active = [];
  bool confirmStarts = true;

  void emit(String type, String uuid, [Map<String, dynamic> data = const {}]) =>
      _events.add(CallKitEvent(type: type, uuid: uuid, data: {'id': uuid, ...data}));

  @override
  Stream<CallKitEvent> get events => _events.stream;

  @override
  Future<void> startCall({
    required String uuid,
    required String callerName,
    required String handle,
    Map<String, dynamic>? extra,
  }) async {
    log.add('startCall:$uuid:$callerName:$handle');
    if (confirmStarts) emit(CallKitEvent.typeStart, uuid);
  }

  @override
  Future<void> setCallConnected(String uuid) async => log.add('setCallConnected:$uuid');

  @override
  Future<void> setHeld(String uuid, bool onHold) async => log.add('setHeld:$uuid:$onHold');

  @override
  Future<void> setMuted(String uuid, bool muted) async => log.add('setMuted:$uuid:$muted');

  @override
  Future<void> endCall(String uuid) async => log.add('endCall:$uuid');

  @override
  Future<void> endAllCalls() async => log.add('endAllCalls');

  @override
  Future<List<dynamic>> activeCalls() async => active;

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

  List<String> get lastManaged => managed.isEmpty ? const [] : managed.last;
  void otherCallsGone() => _otherCallsEnded.add(null);

  @override
  Future<void> setManagedCalls(List<String> uuids) async => managed.add(List.of(uuids));

  @override
  Future<void> prepareCallAudio() async => prepared++;

  @override
  Stream<void> get otherCallsEnded => _otherCallsEnded.stream;
}

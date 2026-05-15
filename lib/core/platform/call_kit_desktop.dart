// lib/core/platform/call_kit_desktop.dart
import 'dart:async';

import 'call_kit.dart';

/// [CallKitPlatform] no-op implementation for macOS, Windows, and Linux.
///
/// Desktop platforms do not have CallKit or a native incoming-call UI.
/// All methods are silent no-ops; [events] is an empty stream; [activeCalls]
/// returns an empty list; [getDevicePushTokenVoIP] returns `null`.
class CallKitDesktop implements CallKitPlatform {
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

  @override
  Future<void> endCall(String uuid) async {}

  @override
  Future<void> endAllCalls() async {}

  @override
  Future<List<dynamic>> activeCalls() async => [];

  @override
  Future<String?> getDevicePushTokenVoIP() async => null;

  @override
  Stream<CallKitEvent> get events => const Stream.empty();
}

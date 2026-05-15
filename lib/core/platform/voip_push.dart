// lib/core/platform/voip_push.dart
import 'package:flutter/foundation.dart';
import 'platform_utils.dart';
import 'voip_push_mobile.dart';
import 'voip_push_desktop.dart';

/// Platform-agnostic interface for VoIP push notifications (PushKit on iOS,
/// FCM-VoIP workaround on Android, no-op on desktop).
///
/// On mobile, [getToken] retrieves the OS-level VoIP token that should be
/// registered with the backend so the server can wake the app via a high-
/// priority push when an incoming call arrives.  On desktop the method returns
/// `null`; callers MUST handle null gracefully (fall back to Socket.IO-only
/// call_invite delivery).
///
/// [incomingPayloads] is a stream of raw push payloads that arrive while the
/// app is foregrounded.  On desktop the stream is always empty.
abstract class VoipPushPlatform {
  static VoipPushPlatform? _instance;

  static VoipPushPlatform get instance =>
      _instance ??= PlatformUtils.instance.isMobile
          ? VoipPushMobile()
          : VoipPushDesktop();

  /// VoIP token to register with the backend, or null on platforms without
  /// VoIP push (desktop). When null, callers fall back to Socket.IO-only
  /// call_invite delivery.
  Future<String?> getToken();

  /// Stream of inbound VoIP push payloads. Empty on desktop.
  Stream<Map<String, dynamic>> get incomingPayloads;

  @visibleForTesting
  static void debugResetForTest() => _instance = null;

  @visibleForTesting
  static set debugInstance(VoipPushPlatform i) => _instance = i;
}

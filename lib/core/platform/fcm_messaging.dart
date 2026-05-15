// lib/core/platform/fcm_messaging.dart
import 'package:flutter/foundation.dart';
import 'platform_utils.dart';
import 'fcm_messaging_mobile.dart';
import 'fcm_messaging_desktop.dart';

/// Platform-agnostic interface for FCM (Firebase Cloud Messaging).
///
/// On mobile, [FcmMessagingMobile] delegates to `firebase_messaging`.
/// On desktop, [FcmMessagingDesktop] is a silent stub — Phase 2 will replace
/// it with `flutter_local_notifications` for macOS.
///
/// Use [debugResetForTest] / [debugInstance] in unit tests to override dispatch.
abstract class FcmMessagingPlatform {
  static FcmMessagingPlatform? _instance;

  static FcmMessagingPlatform get instance =>
      _instance ??= PlatformUtils.instance.isMobile
          ? FcmMessagingMobile()
          : FcmMessagingDesktop();

  /// Initialises FCM: requests permissions, registers background handlers, etc.
  /// No-op on desktop in Phase 1.
  Future<void> initialize();

  /// FCM registration token, or null if not supported on this platform.
  Future<String?> getToken();

  /// Asks the OS for notification display permission.
  /// No-op on desktop in Phase 1.
  Future<void> requestPermissions();

  /// Returns whether the user has granted notification permission.
  /// Always returns false on desktop in Phase 1.
  Future<bool> hasPermission();

  /// Subscribe to an FCM topic (e.g. for mesh-key fan-out).
  /// No-op on desktop in Phase 1.
  Future<void> subscribeToTopic(String topic);

  /// Unsubscribe from an FCM topic.
  /// No-op on desktop in Phase 1.
  Future<void> unsubscribeFromTopic(String topic);

  /// Stream of token refresh events.  Emits the new token string.
  /// Empty stream on desktop in Phase 1.
  Stream<String> get onTokenRefresh;

  /// Foreground message stream — emits when a message arrives while the app is
  /// in the foreground.  Empty stream on desktop in Phase 1.
  Stream<Map<String, dynamic>> get onMessage;

  /// Emits when the user taps a notification while the app is in the background
  /// (not terminated).  Empty stream on desktop in Phase 1.
  Stream<Map<String, dynamic>> get onMessageOpenedApp;

  /// Returns the [RemoteMessage]-equivalent map for a notification that
  /// launched the app from a terminated state, or null if there was none.
  Future<Map<String, dynamic>?> getInitialMessage();

  @visibleForTesting
  static void debugResetForTest() => _instance = null;

  @visibleForTesting
  static set debugInstance(FcmMessagingPlatform i) => _instance = i;
}

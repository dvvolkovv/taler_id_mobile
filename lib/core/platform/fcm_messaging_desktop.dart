// lib/core/platform/fcm_messaging_desktop.dart
import 'fcm_messaging.dart';

/// Desktop stub implementation of [FcmMessagingPlatform].
///
/// All methods are silent no-ops or return empty/null values.
/// Phase 2 will replace this with a [flutter_local_notifications] bridge
/// for macOS so desktop users receive chat/call notifications via the
/// macOS Notification Center.
class FcmMessagingDesktop implements FcmMessagingPlatform {
  @override
  Future<void> initialize() async {}

  @override
  Future<String?> getToken() async => null;

  @override
  Future<void> deleteToken() async {}

  @override
  Future<void> requestPermissions() async {}

  @override
  Future<bool> hasPermission() async => false;

  @override
  Future<void> subscribeToTopic(String topic) async {}

  @override
  Future<void> unsubscribeFromTopic(String topic) async {}

  @override
  Stream<String> get onTokenRefresh => const Stream.empty();

  @override
  Stream<Map<String, dynamic>> get onMessage => const Stream.empty();

  @override
  Stream<Map<String, dynamic>> get onMessageOpenedApp => const Stream.empty();

  @override
  Future<Map<String, dynamic>?> getInitialMessage() async => null;
}

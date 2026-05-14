// lib/core/platform/fcm_messaging_mobile.dart
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'fcm_messaging.dart';

/// Mobile implementation of [FcmMessagingPlatform] — wraps
/// [FirebaseMessaging] from `firebase_messaging`.
///
/// All behavior is identical to the pre-abstraction direct usage.  The class
/// is kept thin — its only job is to adapt [FirebaseMessaging]'s API surface
/// to the platform-agnostic [FcmMessagingPlatform] contract so desktop builds
/// never import `firebase_messaging`.
class FcmMessagingMobile implements FcmMessagingPlatform {
  final FirebaseMessaging _fcm;

  FcmMessagingMobile({FirebaseMessaging? fcm})
      : _fcm = fcm ?? FirebaseMessaging.instance;

  @override
  Future<void> initialize() async {
    // Background handler registration must be done at call-site (top-level
    // function required by FCM isolate) before calling initialize().
    // Nothing to do here that can't be done inline in the call-site.
  }

  @override
  Future<String?> getToken() async {
    try {
      return await _fcm.getToken();
    } catch (e) {
      debugPrint('[FcmMessagingMobile] getToken failed: $e');
      return null;
    }
  }

  @override
  Future<void> requestPermissions() async {
    try {
      await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
    } catch (e) {
      debugPrint('[FcmMessagingMobile] requestPermissions failed: $e');
    }
  }

  @override
  Future<bool> hasPermission() async {
    try {
      final settings = await _fcm.getNotificationSettings();
      return settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> subscribeToTopic(String topic) async {
    await _fcm.subscribeToTopic(topic);
  }

  @override
  Future<void> unsubscribeFromTopic(String topic) async {
    await _fcm.unsubscribeFromTopic(topic);
  }

  @override
  Stream<String> get onTokenRefresh => _fcm.onTokenRefresh;

  @override
  Stream<Map<String, dynamic>> get onMessage =>
      FirebaseMessaging.onMessage.map((msg) => _toMap(msg));

  @override
  Stream<Map<String, dynamic>> get onMessageOpenedApp =>
      FirebaseMessaging.onMessageOpenedApp.map((msg) => _toMap(msg));

  @override
  Future<Map<String, dynamic>?> getInitialMessage() async {
    try {
      final msg = await _fcm.getInitialMessage();
      return msg != null ? _toMap(msg) : null;
    } catch (_) {
      return null;
    }
  }

  /// Convert a [RemoteMessage] to a plain map that the platform-agnostic
  /// interface exposes.  Callers that need the full [RemoteMessage] structure
  /// should go through [FcmMessagingMobile] directly, but in practice all
  /// existing callers only need [data] and [notification.title/body].
  static Map<String, dynamic> _toMap(RemoteMessage msg) => {
        'data': msg.data,
        'notification': msg.notification == null
            ? null
            : {
                'title': msg.notification!.title,
                'body': msg.notification!.body,
              },
        'messageId': msg.messageId,
        'from': msg.from,
        'collapseKey': msg.collapseKey,
        'sentTime': msg.sentTime?.millisecondsSinceEpoch,
      };
}

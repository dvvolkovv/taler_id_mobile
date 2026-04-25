import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/mesh/services/device_key_sync_service.dart';

/// Subscribes the device to `mesh-keys/<userId>` topics for each contact so
/// the server's `FcmService.sendKeyUpdate` fan-out reaches all interested
/// clients.
///
/// On an incoming data-only push with `type == 'mesh_key_update'`, triggers a
/// re-fetch of the affected user's keys via [DeviceKeySyncService].
class MeshFcmListener {
  final DeviceKeySyncService syncService;
  final FirebaseMessaging _fcm;

  MeshFcmListener({
    required this.syncService,
    FirebaseMessaging? fcm,
  }) : _fcm = fcm ?? FirebaseMessaging.instance;

  /// Subscribe to mesh-key topics for a set of contacts. Idempotent per topic.
  Future<void> subscribeContactTopics(List<String> contactUserIds) async {
    for (final id in contactUserIds) {
      await _fcm.subscribeToTopic('mesh-keys/$id');
    }
  }

  Future<void> unsubscribeContactTopic(String contactUserId) async {
    await _fcm.unsubscribeFromTopic('mesh-keys/$contactUserId');
  }

  /// Attach a foreground message handler. Call once at app startup after
  /// Firebase.initializeApp + any other FCM setup in the project.
  void attachHandlers() {
    FirebaseMessaging.onMessage.listen((msg) async {
      if (msg.data['type'] != 'mesh_key_update') return;
      final userId = msg.data['userId'] as String?;
      if (userId == null) return;
      debugPrint('[mesh-fcm] key update for $userId — refetching');
      try {
        await syncService.fetchContactKeys(userId);
      } catch (e) {
        debugPrint('[mesh-fcm] refetch failed: $e');
      }
    });
  }
}

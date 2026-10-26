// test/core/notifications/notification_to_route_test.dart
//
// Regression (PROD, 2026-10-26): tapping the "Входящий звонок" notification
// opened the call screen as an incoming call, and that screen answers — it
// joins the room and tells the caller. Android shows this notification next
// to the one with Answer/Decline (the FCM payload carries a notification
// block), and nothing removes it when the call ends, so a tap could also
// "answer" a call that was long over.
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taler_id_mobile/core/notifications/notification_service.dart';

void main() {
  test('a call notification opens the app, not the call', () {
    const message = RemoteMessage(data: {
      'type': 'call_invite',
      'roomName': 'call-550e8400-e29b-41d4-a716-446655440000',
      'conversationId': 'conv-1',
      'fromName': 'Alice',
    });

    expect(notificationToRoute(message), isNull);
  });

  test('other notifications still lead to their screens', () {
    const message = RemoteMessage(data: {'type': 'new_session'});

    expect(notificationToRoute(message), '/dashboard/sessions');
  });
}

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

  test('an approval notification carries its deadline to the screen', () {
    const expiresAt = '2026-11-16T19:48:25.096Z';
    const message = RemoteMessage(data: {
      'type': 'device_approval',
      'approvalId': 'appr-1',
      'deviceInfo': 'Pixel',
      'ip': '1.2.3.4',
      'expiresAt': expiresAt,
    });

    final uri = Uri.parse(notificationToRoute(message)!);
    expect(uri.path, '/auth/device-approval-request');
    expect(uri.queryParameters['approvalId'], 'appr-1');
    expect(uri.queryParameters['expiresAt'], expiresAt);
  });

  test('other notifications still lead to their screens', () {
    const message = RemoteMessage(data: {'type': 'new_session'});

    expect(notificationToRoute(message), '/dashboard/sessions');
  });
}

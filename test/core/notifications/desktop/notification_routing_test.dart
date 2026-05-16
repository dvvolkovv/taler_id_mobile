import 'package:flutter_test/flutter_test.dart';
import 'package:taler_id_mobile/core/notifications/desktop/notification_routing.dart';

void main() {
  test('chat payload maps to messenger chat route', () {
    expect(
      NotificationRouting.routeFor('chat:abc123'),
      '/dashboard/messenger/chat/abc123',
    );
  });

  test('call payload maps to call history', () {
    expect(
      NotificationRouting.routeFor('call:room-7'),
      '/dashboard/call-history',
    );
  });

  test('profile payload maps to profile route', () {
    expect(
      NotificationRouting.routeFor('profile:u-7'),
      '/dashboard/profile/u-7',
    );
  });

  test('unknown type returns null', () {
    expect(NotificationRouting.routeFor('unknown:foo'), isNull);
  });

  test('malformed payload returns null', () {
    expect(NotificationRouting.routeFor('no_colon_here'), isNull);
  });
}

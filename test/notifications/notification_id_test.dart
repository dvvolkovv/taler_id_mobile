import 'package:flutter_test/flutter_test.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:taler_id_mobile/core/notifications/notification_service.dart';
void main() {
  test('notifKeyFor matches the server sha1 scheme + is per-conversation', () {
    final s = NotificationService();
    String expected(String c) => 'conv-' + sha1.convert(utf8.encode(c)).toString().substring(0, 16);
    expect(s.notifKeyFor('conv-123'), expected('conv-123'));
    expect(s.notifKeyFor('conv-123'), s.notifKeyFor('conv-123'));
    expect(s.notifKeyFor('conv-123'), isNot(s.notifKeyFor('conv-456')));
    expect(s.notifIntIdFor('conv-123') >= 0, true);
  });
}

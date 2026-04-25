import 'package:flutter_test/flutter_test.dart';
import 'package:taler_id_mobile/features/messenger/domain/entities/message_entity.dart';

void main() {
  group('MessageEntity.transport', () {
    test('defaults to null when missing from JSON', () {
      final m = MessageEntity.fromJson({
        'id': 'srv-1',
        'conversationId': 'c-1',
        'senderId': 'u-1',
        'content': 'hi',
        'sentAt': DateTime(2026, 4, 24, 12, 0).toIso8601String(),
      });
      expect(m.transport, isNull);
    });

    test('round-trips transport: "mesh"', () {
      final m = MessageEntity(
        id: 'mesh-1',
        conversationId: 'c-1',
        senderId: 'u-1',
        content: 'hi',
        sentAt: DateTime(2026, 4, 24, 12, 0),
        transport: 'mesh',
      );
      final json = m.toJson();
      expect(json['transport'], 'mesh');
      final decoded = MessageEntity.fromJson(json);
      expect(decoded.transport, 'mesh');
    });

    test('copyWith updates transport', () {
      final m = MessageEntity(
        id: 's-1',
        conversationId: 'c-1',
        senderId: 'u-1',
        content: 'hi',
        sentAt: DateTime(2026, 4, 24, 12, 0),
      );
      final updated = m.copyWith(transport: 'mesh');
      expect(updated.transport, 'mesh');
      expect(m.transport, isNull);
    });
  });
}

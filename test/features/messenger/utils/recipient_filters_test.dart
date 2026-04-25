import 'package:flutter_test/flutter_test.dart';
import 'package:taler_id_mobile/features/messenger/domain/entities/conversation_entity.dart';
import 'package:taler_id_mobile/features/messenger/utils/recipient_filters.dart';

ConversationEntity _conv(String id, String type, {String? myRole}) =>
    ConversationEntity(
      id: id,
      participantIds: const [],
      type: type,
      myRole: myRole,
    );

void main() {
  group('filterRecipients', () {
    test('includes DIRECT and GROUP', () {
      final result = filterRecipients([
        _conv('c1', 'DIRECT'),
        _conv('c2', 'GROUP'),
      ]);
      expect(result.map((c) => c.id), ['c1', 'c2']);
    });

    test('includes SAVED, AI_ANALYST, AI_OUTBOUND', () {
      final result = filterRecipients([
        _conv('s', 'SAVED'),
        _conv('a', 'AI_ANALYST'),
        _conv('o', 'AI_OUTBOUND'),
      ]);
      expect(result.map((c) => c.id), ['s', 'a', 'o']);
    });

    test('CHANNEL: includes OWNER and ADMIN, excludes SUBSCRIBER and null role', () {
      final result = filterRecipients([
        _conv('owner', 'CHANNEL', myRole: 'OWNER'),
        _conv('admin', 'CHANNEL', myRole: 'ADMIN'),
        _conv('sub', 'CHANNEL', myRole: 'SUBSCRIBER'),
        _conv('null', 'CHANNEL'),
      ]);
      expect(result.map((c) => c.id), ['owner', 'admin']);
    });

    test('excludes unknown types', () {
      final result = filterRecipients([
        _conv('x', 'SYSTEM'),
        _conv('y', 'WEIRD'),
      ]);
      expect(result, isEmpty);
    });

    test('preserves order of input', () {
      final result = filterRecipients([
        _conv('c1', 'DIRECT'),
        _conv('c2', 'AI_ANALYST'),
        _conv('c3', 'GROUP'),
      ]);
      expect(result.map((c) => c.id), ['c1', 'c2', 'c3']);
    });
  });
}

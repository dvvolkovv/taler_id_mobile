import 'package:flutter_test/flutter_test.dart';
import 'package:taler_id_mobile/features/messenger/domain/entities/conversation_entity.dart';
import 'package:taler_id_mobile/features/messenger/domain/entities/message_entity.dart';
import 'package:taler_id_mobile/features/messenger/domain/entities/pinned_preview_entity.dart';

void main() {
  test('MessageEntity parses pin fields from server JSON', () {
    final m = MessageEntity.fromJson({
      'id': 'm1',
      'conversationId': 'c1',
      'senderId': 's1',
      'content': 'hi',
      'sentAt': '2026-08-08T10:00:00.000Z',
      'pinnedAt': '2026-08-08T11:00:00.000Z',
      'pinnedById': 'u1',
    });

    expect(m.pinnedAt, DateTime.parse('2026-08-08T11:00:00.000Z'));
    expect(m.pinnedById, 'u1');
  });

  test('MessageEntity defaults pin fields to null when absent', () {
    final m = MessageEntity.fromJson({
      'id': 'm1',
      'conversationId': 'c1',
      'senderId': 's1',
      'content': 'hi',
      'sentAt': '2026-08-08T10:00:00.000Z',
    });

    expect(m.pinnedAt, isNull);
    expect(m.pinnedById, isNull);
  });

  test('ConversationEntity parses pinnedCount, topPinned and pinsDismissedAt', () {
    final c = ConversationEntity.fromJson({
      'id': 'c1',
      'participantIds': <String>[],
      'type': 'CHANNEL',
      'pinnedCount': 2,
      'topPinned': {
        'id': 'm9',
        'content': 'announcement',
        'senderName': 'Taler ID',
        'sentAt': '2026-08-08T10:00:00.000Z',
        'pinnedAt': '2026-08-08T11:00:00.000Z',
      },
      'pinsDismissedAt': '2026-08-07T00:00:00.000Z',
    });

    expect(c.pinnedCount, 2);
    expect(c.topPinned!.id, 'm9');
    expect(c.topPinned!.content, 'announcement');
    expect(c.topPinned!.senderName, 'Taler ID');
    expect(c.topPinned!.sentAt, DateTime.parse('2026-08-08T10:00:00.000Z'));
    expect(c.topPinned!.pinnedAt, DateTime.parse('2026-08-08T11:00:00.000Z'));
    expect(c.pinsDismissedAt, DateTime.parse('2026-08-07T00:00:00.000Z'));
  });

  test('ConversationEntity has no pins when the server omits the fields', () {
    final c = ConversationEntity.fromJson({
      'id': 'c1',
      'participantIds': <String>[],
      'type': 'DIRECT',
    });

    expect(c.pinnedCount, 0);
    expect(c.topPinned, isNull);
    expect(c.pinsDismissedAt, isNull);
  });

  test('ConversationEntity survives a direct toJson → fromJson round-trip', () {
    final original = ConversationEntity(
      id: 'c1',
      type: 'CHANNEL',
      participantIds: const [],
      pinnedCount: 2,
      topPinned: PinnedPreviewEntity(
        id: 'm9',
        content: 'announcement',
        senderName: 'Taler ID',
        sentAt: DateTime.parse('2026-08-08T10:00:00.000Z'),
        pinnedAt: DateTime.parse('2026-08-08T11:00:00.000Z'),
      ),
      pinsDismissedAt: DateTime.parse('2026-08-07T00:00:00.000Z'),
    );

    final restored = ConversationEntity.fromJson(original.toJson());

    expect(restored.pinnedCount, 2);
    expect(restored.topPinned, original.topPinned);
    expect(restored.pinsDismissedAt, original.pinsDismissedAt);
  });
}

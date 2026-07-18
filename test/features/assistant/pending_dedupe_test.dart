import 'package:flutter_test/flutter_test.dart';
import 'package:taler_id_mobile/features/assistant/domain/pending_dedupe.dart';
import 'package:taler_id_mobile/features/messenger/domain/entities/message_entity.dart';

MessageEntity _msg(String content, {Map<String, dynamic>? metadata}) =>
    MessageEntity(
      id: 'id-$content',
      conversationId: 'conv',
      senderId: 'sender',
      content: content,
      sentAt: DateTime(2026, 1, 1),
      metadata: metadata,
    );

void main() {
  group('replicaAlreadyPersisted', () {
    test('matches a voice-sourced message with identical content', () {
      final messages = [
        _msg('привет', metadata: {'source': 'voice'}),
      ];
      expect(replicaAlreadyPersisted('привет', messages), isTrue);
    });

    test('no match when content differs', () {
      final messages = [
        _msg('привет', metadata: {'source': 'voice'}),
      ];
      expect(replicaAlreadyPersisted('пока', messages), isFalse);
    });

    test('non-voice source does not match even with same content', () {
      final messages = [
        _msg('привет', metadata: {'source': 'text'}),
        _msg('привет'), // no metadata at all
      ];
      expect(replicaAlreadyPersisted('привет', messages), isFalse);
    });
  });
}

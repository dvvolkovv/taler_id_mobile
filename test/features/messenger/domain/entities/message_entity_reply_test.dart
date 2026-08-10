import 'package:flutter_test/flutter_test.dart';
import 'package:taler_id_mobile/features/messenger/domain/entities/message_entity.dart';

void main() {
  Map<String, dynamic> base() => {
        'id': 'm1',
        'conversationId': 'c1',
        'senderId': 'u1',
        'content': 'ответ',
        'sentAt': '2026-08-10T10:00:00.000Z',
      };

  group('MessageEntity reply/forward', () {
    test('parses the quote that comes with the message', () {
      final m = MessageEntity.fromJson({
        ...base(),
        'replyToId': 'orig-1',
        'replyTo': {
          'id': 'orig-1',
          'senderId': 'u2',
          'senderName': 'Аня Автор',
          'content': 'оригинал',
          'fileType': null,
          'fileName': null,
          'isDeleted': false,
        },
      });

      expect(m.replyToId, 'orig-1');
      expect(m.replyTo!.senderName, 'Аня Автор');
      expect(m.replyTo!.content, 'оригинал');
      expect(m.replyTo!.isDeleted, isFalse);
    });

    test('survives a round trip through json', () {
      // Кэш сообщений гоняет сущности через toJson/fromJson. Без
      // explicitToJson на фабрике вложенные replyTo/forwardedFrom уезжают в
      // карту живыми объектами, и обратный разбор падает — на этом уже
      // спотыкались с другой вложенной сущностью.
      final original = MessageEntity.fromJson({
        ...base(),
        'replyToId': 'orig-1',
        'replyTo': {'id': 'orig-1', 'senderName': 'Аня', 'content': 'привет'},
        'forwardedFrom': {'userId': 'u9', 'name': 'Боря', 'messageId': 'src-1'},
      });

      final restored = MessageEntity.fromJson(original.toJson());

      expect(restored, original);
      expect(restored.replyTo!.content, 'привет');
      expect(restored.forwardedFrom!.name, 'Боря');
    });

    test('reads forward attribution', () {
      final m = MessageEntity.fromJson({
        ...base(),
        'forwardedFrom': {'userId': 'u9', 'name': 'Боря', 'messageId': 'src-1'},
      });

      expect(m.forwardedFrom!.name, 'Боря');
      expect(m.forwardedFrom!.messageId, 'src-1');
    });

    test('marks a quote whose original was deleted', () {
      final m = MessageEntity.fromJson({
        ...base(),
        'replyToId': 'orig-1',
        'replyTo': {'id': 'orig-1', 'content': '', 'isDeleted': true},
      });

      expect(m.replyTo!.isDeleted, isTrue);
      expect(m.replyTo!.content, isEmpty);
    });

    test('an ordinary message carries neither', () {
      final m = MessageEntity.fromJson(base());

      expect(m.replyToId, isNull);
      expect(m.replyTo, isNull);
      expect(m.forwardedFrom, isNull);
    });

    test('tolerates a server that sends replyToId without the preview', () {
      // Путь, который превью не собирает, не должен ронять разбор.
      final m = MessageEntity.fromJson({...base(), 'replyToId': 'orig-1'});

      expect(m.replyToId, 'orig-1');
      expect(m.replyTo, isNull);
    });
  });
}

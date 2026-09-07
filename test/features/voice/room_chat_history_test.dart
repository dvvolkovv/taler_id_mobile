import 'package:flutter_test/flutter_test.dart';
import 'package:taler_id_mobile/features/voice/domain/room_chat_history.dart';

/// Разбор ответа `GET /voice/rooms/:roomName/chat`.
///
/// Тот же дух устойчивости к типам, что и у `parseRoomChatText`
/// (`room_chat_text_test.dart`) и `RoomChatController.handlePacket`: данные
/// приходят из `jsonDecode` по сети, поле может оказаться не той природы, и
/// одна кривая запись не должна ронять всю страницу истории.
void main() {
  group('parseRoomChatHistory — порядок и own', () {
    test('порядок сообщений сохраняется', () {
      final page = parseRoomChatHistory({
        'messages': [
          {'msgId': 'm1', 'text': 'первое', 'name': 'A', 'ts': 1000, 'seq': 1, 'own': false},
          {'msgId': 'm2', 'text': 'второе', 'name': 'B', 'ts': 2000, 'seq': 2, 'own': false},
          {'msgId': 'm3', 'text': 'третье', 'name': 'A', 'ts': 3000, 'seq': 3, 'own': true},
        ],
        'seq': 3,
        'truncated': false,
      });

      expect(page.messages.map((m) => m.text).toList(), ['первое', 'второе', 'третье']);
      expect(page.messages.map((m) => m.msgId).toList(), ['m1', 'm2', 'm3']);
    });

    test('own читается из ответа — не хардкод в одну сторону', () {
      final page = parseRoomChatHistory({
        'messages': [
          {'msgId': 'm1', 'text': 'моё', 'name': 'A', 'ts': 1000, 'seq': 1, 'own': true},
          {'msgId': 'm2', 'text': 'чужое', 'name': 'B', 'ts': 2000, 'seq': 2, 'own': false},
        ],
        'seq': 2,
        'truncated': false,
      });

      expect(page.messages[0].own, isTrue);
      expect(page.messages[1].own, isFalse);
    });
  });

  group('parseRoomChatHistory — пустая лента', () {
    test('пустой messages, seq и truncated передаются как есть, а не как дефолт', () {
      final page = parseRoomChatHistory({
        'messages': <dynamic>[],
        'seq': 42,
        'truncated': true,
      });

      expect(page.messages, isEmpty);
      // 42 и true — не дефолтные значения (0/false), поэтому совпадение
      // доказывает, что поля реально читаются, а не всегда возвращают дефолт.
      expect(page.seq, 42);
      expect(page.truncated, isTrue);
    });
  });

  group('parseRoomChatHistory — устойчивость к мусору', () {
    test('сообщение без текста пропущено, соседи остаются по порядку', () {
      final page = parseRoomChatHistory({
        'messages': [
          {'msgId': 'ok1', 'text': 'первое', 'name': 'A', 'ts': 1000, 'seq': 1, 'own': false},
          {'msgId': 'no-text-key', 'name': 'A', 'ts': 1500, 'seq': 2, 'own': false},
          {'msgId': 'empty', 'text': '', 'name': 'A', 'ts': 1600, 'seq': 3, 'own': false},
          {'msgId': 'whitespace', 'text': '   ', 'name': 'A', 'ts': 1700, 'seq': 4, 'own': false},
          {'msgId': 'wrong-type', 'text': 123, 'name': 'A', 'ts': 1800, 'seq': 5, 'own': false},
          {'msgId': 'ok2', 'text': 'второе', 'name': 'B', 'ts': 2000, 'seq': 6, 'own': false},
        ],
        'seq': 6,
        'truncated': false,
      });

      expect(page.messages.map((m) => m.msgId).toList(), ['ok1', 'ok2']);
      expect(page.messages.map((m) => m.text).toList(), ['первое', 'второе']);
    });

    test('поля не той природы не роняют разбор остальных полей сообщения', () {
      final page = parseRoomChatHistory({
        'messages': [
          {
            'msgId': 42, // не строка
            'text': 'единственно валидное поле',
            'name': 123, // не строка
            'ts': 'не число', // не int
            'seq': 'тоже не число', // не int
            'own': 'true', // не bool
            'clientMsgId': 999, // не строка
          },
        ],
        'seq': 'мусор', // не int
        'truncated': 'мусор', // не bool
      });

      expect(page.messages, hasLength(1));
      final m = page.messages.single;
      expect(m.text, 'единственно валидное поле');
      expect(m.msgId, ''); // безопасный дефолт, не TypeError
      expect(m.name, '');
      expect(m.sentAt, isA<DateTime>());
      expect(m.seq, 0);
      expect(m.own, isFalse);
      expect(m.clientMsgId, isNull);
      expect(page.seq, 0);
      expect(page.truncated, isFalse);
    });

    test('мусор вместо тела ответа даёт пустую страницу, а не исключение', () {
      expect(parseRoomChatHistory(const {}).messages, isEmpty);
      expect(parseRoomChatHistory(const {'messages': 'не список'}).messages, isEmpty);
      expect(parseRoomChatHistory(const {'messages': null}).messages, isEmpty);
      expect(parseRoomChatHistory(const {'unexpected': 'shape'}).seq, 0);
      expect(parseRoomChatHistory(const {'unexpected': 'shape'}).truncated, isFalse);
    });
  });

  group('parseRoomChatHistory — clientMsgId: нет ключа ≠ пустая строка', () {
    test('ключа нет вовсе → null', () {
      final page = parseRoomChatHistory({
        'messages': [
          {'msgId': 'm1', 'text': 'hi', 'name': 'A', 'ts': 1000, 'seq': 1, 'own': false},
        ],
        'seq': 1,
        'truncated': false,
      });

      expect(page.messages.single.clientMsgId, isNull);
    });

    test('ключ прислан → значение, а не null и не потеряно', () {
      final page = parseRoomChatHistory({
        'messages': [
          {
            'msgId': 'm2',
            'text': 'hi',
            'name': 'A',
            'ts': 1000,
            'seq': 2,
            'own': true,
            'clientMsgId': 'local-42',
          },
        ],
        'seq': 2,
        'truncated': false,
      });

      expect(page.messages.single.clientMsgId, 'local-42');
    });
  });
}

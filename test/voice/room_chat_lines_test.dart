import 'package:flutter_test/flutter_test.dart';
import 'package:taler_id_mobile/features/voice/presentation/controllers/room_chat_lines.dart';

void main() {
  late RoomChatLines lines;

  setUp(() => lines = RoomChatLines());

  group('select', () {
    test('первый выбор линии создаёт пустой контроллер', () {
      final a = lines.select('room-a');

      expect(a.messages, isEmpty);
    });

    test('повторный выбор той же линии возвращает тот же контроллер', () {
      final first = lines.select('room-a');
      final second = lines.select('room-a');

      expect(identical(first, second), isTrue);
    });

    test('разные линии получают разные контроллеры', () {
      final a = lines.select('room-a');
      final b = lines.select('room-b');

      expect(identical(a, b), isFalse);
    });

    test('переключение линии не показывает чужую ленту', () {
      final a = lines.select('room-a');
      a.addOwn('Я', 'привет с первой линии', 'cid-a1');

      final b = lines.select('room-b');

      expect(b.messages, isEmpty);
      // и не пропадает у себя, когда мы вернёмся
      expect(a.messages, hasLength(1));
      expect(a.messages.single.text, 'привет с первой линии');
    });
  });

  group('shouldFetchHistory', () {
    test('true в первый раз для линии, false при повторе', () {
      expect(lines.shouldFetchHistory('room-a'), isTrue);
      expect(lines.shouldFetchHistory('room-a'), isFalse);
      expect(lines.shouldFetchHistory('room-a'), isFalse);
    });

    test('независимо для разных линий', () {
      expect(lines.shouldFetchHistory('room-a'), isTrue);
      expect(lines.shouldFetchHistory('room-b'), isTrue);
    });
  });

  group('isActive', () {
    test('ничего не выбрано — ни одна линия не активна', () {
      expect(lines.isActive('room-a'), isFalse);
    });

    test('последняя выбранная линия активна, остальные — нет', () {
      lines.select('room-a');
      lines.select('room-b');

      expect(lines.isActive('room-b'), isTrue);
      expect(lines.isActive('room-a'), isFalse);
    });

    // Именно этот сценарий из описания фичи: ответ на фетч истории линии A
    // прилетает уже после того, как человек переключился на B.
    test('ответ истории «не той» линии отбрасывается: isActive false для линии, с которой уже переключились', () {
      lines.select('room-a'); // фетч для A стартовал бы здесь
      lines.select('room-b'); // переключились на B раньше, чем A ответила

      expect(lines.isActive('room-a'), isFalse,
          reason: 'ответ фетча A не должен вызывать перерисовку — на экране B');
    });

    test('переключились туда и обратно — своя линия снова активна', () {
      lines.select('room-a');
      lines.select('room-b');
      lines.select('room-a');

      expect(lines.isActive('room-a'), isTrue);
      expect(lines.isActive('room-b'), isFalse);
    });
  });

  group('эхо/сверка одной линии не задевают другую', () {
    test('reconcile на B не находит clientMsgId, отправленный на A, и не трогает запись на A', () {
      final a = lines.select('room-a');
      a.addOwn('Я', 'привет', 'cid-shared-looking-id');

      final b = lines.select('room-b');
      final result = b.reconcile('cid-shared-looking-id', 'srv-1');

      expect(result, isFalse);
      expect(b.messages, isEmpty);
      // Если бы сверка B ошибочно нашла запись A, у неё сейчас стоял бы
      // msgId со стороны B — этого быть не должно.
      expect(a.messages.single.msgId, isNull);
      expect(a.messages.single.failed, isFalse);
    });

    test('markFailed на B не помечает сообщение, отправленное на A', () {
      final a = lines.select('room-a');
      a.addOwn('Я', 'привет', 'cid-x');

      final b = lines.select('room-b');
      final result = b.markFailed('cid-x');

      expect(result, isFalse);
      expect(a.messages.single.failed, isFalse);
    });

    test('handleIncomingPacket на B не реконсилирует эхо, чей clientMsgId — с A', () {
      final a = lines.select('room-a');
      a.addOwn('Я', 'привет', 'cid-echo');

      final b = lines.select('room-b');
      final handled = b.handleIncomingPacket(
        {
          'type': 'chat_message',
          'text': 'привет',
          'name': 'Я',
          'msgId': 'srv-echo',
          'clientMsgId': 'cid-echo',
        },
        fallbackName: 'Гость',
        isDuplicate: (_) => false,
      );

      // Не находит совпадения на B → это чужой пакет для B → рисуется как
      // обычное (не своё) сообщение на B, а запись на A остаётся нетронутой.
      expect(handled, isTrue);
      expect(b.messages.single.own, isFalse);
      expect(a.messages.single.msgId, isNull);
      expect(a.messages, hasLength(1));
    });
  });

  group('disposeAll', () {
    test('дальнейшая мутация любого созданного контроллера бросает — dispose реально вызван', () {
      final a = lines.select('room-a');
      final b = lines.select('room-b');

      lines.disposeAll();

      expect(() => a.setOpen(true), throwsFlutterError);
      expect(() => b.setOpen(true), throwsFlutterError);
    });

    test('контроллер, ни разу не выбранный, не создаётся и не мешает disposeAll', () {
      lines.select('room-a');

      expect(() => lines.disposeAll(), returnsNormally);
    });
  });
}

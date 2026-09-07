import 'package:flutter_test/flutter_test.dart';
import 'package:taler_id_mobile/features/voice/domain/room_chat_history.dart';
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

  group('fetchCursor / recordSeq — первый показ линии полный, возврат — догоняющий', () {
    test('первый показ линии: курсора ещё нет — фетч должен быть полным', () {
      expect(lines.fetchCursor('room-a'), isNull);
    });

    test('после recordSeq курсор — этот seq, а не null: возврат на линию делает догоняющий запрос', () {
      lines.recordSeq('room-a', 5);

      expect(lines.fetchCursor('room-a'), 5);
    });

    test('независимо для разных линий', () {
      lines.recordSeq('room-a', 5);

      expect(lines.fetchCursor('room-a'), 5);
      expect(lines.fetchCursor('room-b'), isNull);
    });

    test('курсор движется вперёд от повторных recordSeq — так его двигают и живые пакеты, не только страница истории', () {
      lines.recordSeq('room-a', 3);
      lines.recordSeq('room-a', 3); // например, страница истории с тем же seq
      lines.recordSeq('room-a', 7); // например, seq живого пакета чата

      expect(lines.fetchCursor('room-a'), 7);
    });

    test('recordSeq монотонен: более старый seq не откатывает курсор назад', () {
      lines.recordSeq('room-a', 10);
      lines.recordSeq('room-a', 4); // переупорядоченный/повторно доставленный старый пакет

      expect(lines.fetchCursor('room-a'), 10,
          reason: 'иначе следующий догоняющий запрос перезапросит уже виденное');
    });

    test('линия, для которой ничего не фетчилось, но recordSeq вызывался напрямую от живого пакета — тоже даёт курсор', () {
      // Сценарий: живой пакет обновил курсор ДО первого фетча истории этой
      // линии (в теории возможно, если порядок вызовов на экране другой) —
      // fetchCursor всё равно должен отразить его, а не null.
      lines.recordSeq('room-b', 42);

      expect(lines.fetchCursor('room-b'), 42);
    });
  });

  group('needsFullRefetch — truncated приводит к полному перечитыванию только для догоняющего', () {
    test('truncated + был курсор (догоняющий) → нужен полный рефетч', () {
      expect(
        RoomChatLines.needsFullRefetch(truncated: true, since: 5),
        isTrue,
      );
    });

    test('truncated + курсора не было (полный запрос) → не рефетчим повторно', () {
      expect(
        RoomChatLines.needsFullRefetch(truncated: true, since: null),
        isFalse,
        reason: 'это принятое ограничение — сервер и так не отдал бы больше',
      );
    });

    test('не truncated + был курсор → рефетч не нужен', () {
      expect(
        RoomChatLines.needsFullRefetch(truncated: false, since: 5),
        isFalse,
      );
    });

    test('не truncated + курсора не было → рефетч не нужен', () {
      expect(
        RoomChatLines.needsFullRefetch(truncated: false, since: null),
        isFalse,
      );
    });
  });

  group('пропущенные сообщения появляются при возврате на линию (сквозной сценарий)', () {
    test('догоняющий запрос дополняет ленту, а не переписывает её', () {
      // Первый показ линии: полная история, seq страницы = 2.
      final a = lines.select('room-a');
      a.setHistory([
        RoomChatHistoryMessage(
          msgId: 's1',
          text: 'до отъезда',
          name: 'Аня',
          sentAt: DateTime.now(),
          seq: 2,
          own: false,
        ),
      ]);
      lines.recordSeq('room-a', 2);

      // Переключились на другую линию — на A слушателя нет, но кто-то там
      // написал. Мы об этом узнаём только при возврате.
      lines.select('room-b');
      expect(lines.fetchCursor('room-a'), 2,
          reason: 'при возврате на A должен уйти догоняющий запрос since=2');

      // Возврат на A: догоняющий фетч приносит то, что пропустили.
      lines.select('room-a');
      a.setHistory(
        [
          RoomChatHistoryMessage(
            msgId: 's2',
            text: 'пока меня не было',
            name: 'Боб',
            sentAt: DateTime.now(),
            seq: 3,
            own: false,
          ),
        ],
        append: true,
      );
      lines.recordSeq('room-a', 3);

      expect(a.messages.map((m) => m.text).toList(),
          ['до отъезда', 'пока меня не было']);
      expect(lines.fetchCursor('room-a'), 3);
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

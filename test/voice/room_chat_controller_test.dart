import 'package:flutter_test/flutter_test.dart';
import 'package:taler_id_mobile/features/voice/domain/room_chat_history.dart';
import 'package:taler_id_mobile/features/voice/presentation/controllers/room_chat_controller.dart';

void main() {
  late RoomChatController c;

  setUp(() => c = RoomChatController());

  test('принимает пакет chat_message и кладёт его в ленту', () {
    final handled = c.handlePacket(
      {'type': 'chat_message', 'text': 'Привет', 'name': 'Аня', 'ts': 1000},
      fallbackName: 'Гость',
    );

    expect(handled, isTrue);
    expect(c.messages, hasLength(1));
    expect(c.messages.single.text, 'Привет');
    expect(c.messages.single.name, 'Аня');
    expect(c.messages.single.own, isFalse);
    expect(c.messages.single.sentAt.millisecondsSinceEpoch, 1000);
  });

  test('пакет чужого типа не трогает ленту', () {
    final handled = c.handlePacket(
      {'type': 'recording_approved'},
      fallbackName: 'Гость',
    );

    expect(handled, isFalse);
    expect(c.messages, isEmpty);
  });

  test('пустой текст игнорируется', () {
    final handled = c.handlePacket(
      {'type': 'chat_message', 'text': '   ', 'name': 'Аня'},
      fallbackName: 'Гость',
    );

    expect(handled, isFalse);
    expect(c.messages, isEmpty);
  });

  test('без имени берётся запасное', () {
    c.handlePacket(
      {'type': 'chat_message', 'text': 'Привет'},
      fallbackName: 'Гость',
    );

    expect(c.messages.single.name, 'Гость');
  });

  test('чужие сообщения при закрытой панели считаются непрочитанными', () {
    c.handlePacket({'type': 'chat_message', 'text': 'раз'}, fallbackName: 'Г');
    c.handlePacket({'type': 'chat_message', 'text': 'два'}, fallbackName: 'Г');

    expect(c.unread, 2);
  });

  test('открытие панели обнуляет счётчик', () {
    c.handlePacket({'type': 'chat_message', 'text': 'раз'}, fallbackName: 'Г');
    c.setOpen(true);

    expect(c.unread, 0);
    expect(c.isOpen, isTrue);
  });

  test('закрытие панели возвращает подсчёт непрочитанных', () {
    c.setOpen(true);
    c.setOpen(false);
    c.handlePacket({'type': 'chat_message', 'text': 'раз'}, fallbackName: 'Г');

    expect(c.isOpen, isFalse);
    expect(c.unread, 1);
  });

  test('setOpen уведомляет слушателей', () {
    var notified = 0;
    c.addListener(() => notified++);

    c.setOpen(true);

    expect(notified, 1);
  });

  test('повторный setOpen с тем же значением не уведомляет вхолостую', () {
    c.setOpen(true);
    var notified = 0;
    c.addListener(() => notified++);

    c.setOpen(true);

    expect(notified, 0);
  });

  test('при открытой панели непрочитанные не копятся', () {
    c.setOpen(true);
    c.handlePacket({'type': 'chat_message', 'text': 'раз'}, fallbackName: 'Г');

    expect(c.unread, 0);
  });

  test('своё сообщение не считается непрочитанным', () {
    c.addOwn('Я', 'привет', 'cid-own-1');

    expect(c.messages.single.own, isTrue);
    expect(c.unread, 0);
  });

  test('своё пустое сообщение не добавляется', () {
    final added = c.addOwn('Я', '   ', 'cid-empty');

    expect(added, isNull);
    expect(c.messages, isEmpty);
  });

  test('своё сообщение обрезается по краям', () {
    c.addOwn('Я', '  привет  ', 'cid-trim');

    expect(c.messages.single.text, 'привет');
  });

  test('уведомляет слушателей о новом сообщении', () {
    var notified = 0;
    c.addListener(() => notified++);

    c.handlePacket({'type': 'chat_message', 'text': 'раз'}, fallbackName: 'Г');

    expect(notified, 1);
  });

  // --- устойчивость к типам из jsonDecode ---------------------------------

  test('не-строковый text не роняет разбор и не попадает в ленту', () {
    final handled = c.handlePacket(
      {'type': 'chat_message', 'text': 42, 'name': 'Аня'},
      fallbackName: 'Гость',
    );

    expect(handled, isFalse);
    expect(c.messages, isEmpty);
  });

  test('не-строковое name заменяется запасным', () {
    final handled = c.handlePacket(
      {'type': 'chat_message', 'text': 'Привет', 'name': 7},
      fallbackName: 'Гость',
    );

    expect(handled, isTrue);
    expect(c.messages.single.name, 'Гость');
  });

  test('не-целочисленный ts заменяется текущим временем', () {
    final before = DateTime.now();
    final handled = c.handlePacket(
      {'type': 'chat_message', 'text': 'Привет', 'ts': '1000'},
      fallbackName: 'Гость',
    );
    final after = DateTime.now();

    expect(handled, isTrue);
    final sentAt = c.messages.single.sentAt;
    expect(sentAt.isBefore(before), isFalse);
    expect(sentAt.isAfter(after), isFalse);
  });

  test('не-строковый type не роняет разбор', () {
    final handled = c.handlePacket({'type': 5}, fallbackName: 'Гость');

    expect(handled, isFalse);
    expect(c.messages, isEmpty);
  });

  test('лента снаружи неизменяема', () {
    c.addOwn('Я', 'привет', 'cid-immutable');

    expect(
      () => c.messages.add(
        RoomChatMessage(
          name: 'X',
          text: 'y',
          sentAt: DateTime.now(),
          own: false,
        ),
      ),
      throwsUnsupportedError,
    );
  });

  // --- msgId/clientMsgId на пакетах и своих сообщениях --------------------

  group('msgId и clientMsgId', () {
    test('handlePacket сохраняет msgId и clientMsgId из чужого пакета', () {
      c.handlePacket(
        {
          'type': 'chat_message',
          'text': 'привет',
          'name': 'Боб',
          'msgId': 'srv-1',
          'clientMsgId': 'their-cid',
        },
        fallbackName: 'Гость',
      );

      expect(c.messages.single.msgId, 'srv-1');
      expect(c.messages.single.clientMsgId, 'their-cid');
      expect(c.messages.single.own, isFalse);
    });

    test('handlePacket без msgId/clientMsgId оставляет их null', () {
      c.handlePacket({'type': 'chat_message', 'text': 'привет'}, fallbackName: 'Г');

      expect(c.messages.single.msgId, isNull);
      expect(c.messages.single.clientMsgId, isNull);
    });

    test('addOwn проставляет clientMsgId и не отправлено=false по умолчанию', () {
      final added = c.addOwn('Я', 'привет', 'cid-new');

      expect(added, isNotNull);
      expect(added!.clientMsgId, 'cid-new');
      expect(added.msgId, isNull);
      expect(added.failed, isFalse);
      expect(added.own, isTrue);
    });
  });

  // --- reconcile / markFailed — примитивы сверки ---------------------------

  group('reconcile', () {
    test('находит своё сообщение по clientMsgId и проставляет msgId', () {
      c.addOwn('Я', 'привет', 'cid-r1');

      final result = c.reconcile('cid-r1', 'srv-r1');

      expect(result, isTrue);
      expect(c.messages.single.msgId, 'srv-r1');
      expect(c.messages.single.failed, isFalse);
    });

    test('снимает пометку «не отправлено» при сверке', () {
      c.addOwn('Я', 'привет', 'cid-r2');
      c.markFailed('cid-r2');
      expect(c.messages.single.failed, isTrue);

      c.reconcile('cid-r2', 'srv-r2');

      expect(c.messages.single.failed, isFalse);
    });

    test('неизвестный clientMsgId — возвращает false, ленту не трогает', () {
      final result = c.reconcile('нет-такого', 'srv-x');

      expect(result, isFalse);
      expect(c.messages, isEmpty);
    });

    test('источник правды — сама лента: сверка работает и после setHistory-вставки', () {
      // Проверяем, что reconcile не зависит от какого-то отдельного набора
      // «ожидаемых» id, а действительно сканирует текущую ленту: запись,
      // добавленная не через addOwn (а через историю), тоже находится.
      c.setHistory([
        RoomChatHistoryMessage(
          msgId: 'srv-hist',
          text: 'из истории',
          name: 'Я',
          sentAt: DateTime.now(),
          seq: 1,
          own: true,
          clientMsgId: 'cid-hist',
        ),
      ]);

      final result = c.reconcile('cid-hist', 'srv-hist-2');

      expect(result, isTrue);
      expect(c.messages.single.msgId, 'srv-hist-2');
    });
  });

  group('markFailed', () {
    test('помечает своё сообщение как не отправленное, не удаляя его', () {
      c.addOwn('Я', 'привет', 'cid-f1');

      final result = c.markFailed('cid-f1');

      expect(result, isTrue);
      expect(c.messages, hasLength(1));
      expect(c.messages.single.failed, isTrue);
    });

    test('неизвестный clientMsgId — возвращает false', () {
      final result = c.markFailed('нет-такого');

      expect(result, isFalse);
    });
  });

  // --- повтор с тем же clientMsgId -----------------------------------------

  group('повтор отправки', () {
    test('addOwn дважды с одним clientMsgId не создаёт второго сообщения', () {
      c.addOwn('Я', 'привет', 'cid-dup');
      c.addOwn('Я', 'привет', 'cid-dup');

      expect(c.messages, hasLength(1));
    });

    test('повтор после отказа снимает пометку «не отправлено» и не плодит записей', () {
      c.addOwn('Я', 'привет', 'cid-retry');
      c.markFailed('cid-retry');
      expect(c.messages.single.failed, isTrue);

      final retried = c.addOwn('Я', 'привет', 'cid-retry');

      expect(c.messages, hasLength(1));
      expect(retried, isNotNull);
      expect(retried!.failed, isFalse);
      expect(c.messages.single.failed, isFalse);
    });
  });

  // --- setHistory ------------------------------------------------------------

  group('setHistory', () {
    test('новые записи вставляются в начало, перед уже пришедшими вживую', () {
      c.handlePacket({'type': 'chat_message', 'text': 'живое'}, fallbackName: 'Боб');

      c.setHistory([
        RoomChatHistoryMessage(
          msgId: 's1',
          text: 'старое 1',
          name: 'Аня',
          sentAt: DateTime.now(),
          seq: 1,
          own: false,
        ),
        RoomChatHistoryMessage(
          msgId: 's2',
          text: 'старое 2',
          name: 'Боб',
          sentAt: DateTime.now(),
          seq: 2,
          own: false,
        ),
      ]);

      expect(c.messages.map((m) => m.text).toList(), ['старое 1', 'старое 2', 'живое']);
    });

    test('mode:append кладёт новые записи в конец — догоняющий запрос, а не начальный', () {
      c.handlePacket({'type': 'chat_message', 'text': 'до отъезда'}, fallbackName: 'Боб');

      c.setHistory(
        [
          RoomChatHistoryMessage(
            msgId: 's1',
            text: 'пропущенное 1',
            name: 'Аня',
            sentAt: DateTime.now(),
            seq: 2,
            own: false,
          ),
          RoomChatHistoryMessage(
            msgId: 's2',
            text: 'пропущенное 2',
            name: 'Боб',
            sentAt: DateTime.now(),
            seq: 3,
            own: false,
          ),
        ],
        mode: RoomChatMergeMode.append,
      );

      expect(c.messages.map((m) => m.text).toList(),
          ['до отъезда', 'пропущенное 1', 'пропущенное 2']);
    });

    test('mode:append считает непрочитанными свежие чужие записи (панель закрыта)', () {
      expect(c.unread, 0);

      c.setHistory(
        [
          RoomChatHistoryMessage(
            msgId: 's1',
            text: 'пропущенное 1',
            name: 'Аня',
            sentAt: DateTime.now(),
            seq: 1,
            own: false,
          ),
          RoomChatHistoryMessage(
            msgId: 's2',
            text: 'пропущенное 2',
            name: 'Боб',
            sentAt: DateTime.now(),
            seq: 2,
            own: false,
          ),
        ],
        mode: RoomChatMergeMode.append,
      );

      expect(c.unread, 2,
          reason: 'догоняющий запрос после возврата — это для человека новые сообщения');
    });

    test('mode:append не считает непрочитанной свою же запись из истории', () {
      c.setHistory(
        [
          RoomChatHistoryMessage(
            msgId: 's1',
            text: 'моё',
            name: 'Я',
            sentAt: DateTime.now(),
            seq: 1,
            own: true,
          ),
        ],
        mode: RoomChatMergeMode.append,
      );

      expect(c.unread, 0);
    });

    test('mode:append не копит непрочитанные при открытой панели', () {
      c.setOpen(true);

      c.setHistory(
        [
          RoomChatHistoryMessage(
            msgId: 's1',
            text: 'пропущенное',
            name: 'Аня',
            sentAt: DateTime.now(),
            seq: 1,
            own: false,
          ),
        ],
        mode: RoomChatMergeMode.append,
      );

      expect(c.unread, 0);
    });

    test('mode:replace не увеличивает непрочитанные — это аварийный ресинк, не догонка', () {
      c.setHistory(
        [
          RoomChatHistoryMessage(
            msgId: 's1',
            text: 'после truncated',
            name: 'Аня',
            sentAt: DateTime.now(),
            seq: 5,
            own: false,
          ),
        ],
        mode: RoomChatMergeMode.replace,
      );

      expect(c.unread, 0);
    });

    test('mode:replace заменяет ленту целиком — старые записи не выживают', () {
      c.handlePacket({'type': 'chat_message', 'text': 'старое до truncated'}, fallbackName: 'Боб');
      c.addOwn('Я', 'моё до truncated', 'cid-before-replace');

      c.setHistory(
        [
          RoomChatHistoryMessage(
            msgId: 's1',
            text: 'полная свежая страница',
            name: 'Аня',
            sentAt: DateTime.now(),
            seq: 10,
            own: false,
          ),
        ],
        mode: RoomChatMergeMode.replace,
      );

      expect(c.messages.map((m) => m.text).toList(), ['полная свежая страница']);
    });

    test('mode:replace не сверяет — совпадающий clientMsgId не подхватывает старую запись (другой текст это доказывает)', () {
      // Сверка (_applyReconcile) меняет только msgId/failed и НИКОГДА не
      // трогает text — поэтому разный текст у старой и новой записи с
      // ОДНИМ И ТЕМ ЖЕ clientMsgId различает "сверилась" от "заменилась
      // целиком": одинаковый текст (как было раньше) давал бы одинаковый
      // результат в обоих случаях и ничего не проверял бы на самом деле.
      c.addOwn('Я', 'старый текст до truncated', 'cid-r1');

      c.setHistory(
        [
          RoomChatHistoryMessage(
            msgId: 'srv-r1',
            text: 'новый текст со свежей страницы',
            name: 'Я',
            sentAt: DateTime.now(),
            seq: 7,
            own: true,
            clientMsgId: 'cid-r1',
          ),
        ],
        mode: RoomChatMergeMode.replace,
      );

      // Ровно одна запись — не два экземпляра — и с текстом СО СТРАНИЦЫ,
      // а не унаследованным от старой (что случилось бы при сверке).
      expect(c.messages, hasLength(1));
      expect(c.messages.single.text, 'новый текст со свежей страницы',
          reason: 'если бы сработала сверка вместо замены, остался бы старый текст');
    });

    test('own из истории определяет сторону пузыря', () {
      c.setHistory([
        RoomChatHistoryMessage(
          msgId: 's1',
          text: 'моё старое',
          name: 'Я',
          sentAt: DateTime.now(),
          seq: 1,
          own: true,
        ),
      ]);

      expect(c.messages.single.own, isTrue);
    });

    test('запись, чей clientMsgId уже есть в ленте, не дублируется — только сверяется', () {
      c.addOwn('Я', 'привет', 'cid-h1');

      c.setHistory([
        RoomChatHistoryMessage(
          msgId: 'srv-h1',
          text: 'привет',
          name: 'Я',
          sentAt: DateTime.now(),
          seq: 1,
          own: true,
          clientMsgId: 'cid-h1',
        ),
      ]);

      expect(c.messages, hasLength(1));
      expect(c.messages.single.msgId, 'srv-h1');
      expect(c.messages.single.failed, isFalse);
    });

    test('не увеличивает счётчик непрочитанных', () {
      c.setHistory([
        RoomChatHistoryMessage(
          msgId: 's1',
          text: 'старое',
          name: 'Аня',
          sentAt: DateTime.now(),
          seq: 1,
          own: false,
        ),
      ]);

      expect(c.unread, 0);
    });

    test('пустой список не уведомляет слушателей', () {
      var notified = 0;
      c.addListener(() => notified++);

      c.setHistory(const []);

      expect(notified, 0);
    });
  });

  // --- четыре порядка сверки (см. описание фичи) ---------------------------

  group('четыре порядка сверки собственного сообщения', () {
    test('эхо раньше ответа: реконсилиация по эху, затем идемпотентный ответ', () {
      c.addOwn('Я', 'привет', 'cid-o1');

      final echoHandled = c.handleIncomingPacket(
        {
          'type': 'chat_message',
          'text': 'привет',
          'name': 'Я',
          'msgId': 'srv-o1',
          'clientMsgId': 'cid-o1',
        },
        fallbackName: 'Гость',
        isDuplicate: (_) => false,
      );
      expect(echoHandled, isTrue);
      expect(c.messages, hasLength(1));
      expect(c.messages.single.msgId, 'srv-o1');
      expect(c.messages.single.failed, isFalse);

      // Ответ на POST прилетает позже с тем же msgId — не должен ничего
      // сломать и не должен создать вторую запись.
      final responseReconciled = c.reconcile('cid-o1', 'srv-o1');
      expect(responseReconciled, isTrue);
      expect(c.messages, hasLength(1));
      expect(c.messages.single.msgId, 'srv-o1');
    });

    test('ответ раньше эха: реконсилиация по ответу, затем идемпотентное эхо', () {
      c.addOwn('Я', 'привет', 'cid-o2');

      final responseReconciled = c.reconcile('cid-o2', 'srv-o2');
      expect(responseReconciled, isTrue);
      expect(c.messages.single.msgId, 'srv-o2');

      final echoHandled = c.handleIncomingPacket(
        {
          'type': 'chat_message',
          'text': 'привет',
          'name': 'Я',
          'msgId': 'srv-o2',
          'clientMsgId': 'cid-o2',
        },
        fallbackName: 'Гость',
        isDuplicate: (_) => false,
      );
      expect(echoHandled, isTrue);
      expect(c.messages, hasLength(1));
      expect(c.messages.single.msgId, 'srv-o2');
    });

    test('история раньше эха: setHistory реконсилиирует, повторное эхо не дублирует', () {
      c.addOwn('Я', 'привет', 'cid-o3');

      c.setHistory([
        RoomChatHistoryMessage(
          msgId: 'srv-o3',
          text: 'привет',
          name: 'Я',
          sentAt: DateTime.now(),
          seq: 1,
          own: true,
          clientMsgId: 'cid-o3',
        ),
      ]);
      expect(c.messages, hasLength(1));
      expect(c.messages.single.msgId, 'srv-o3');

      final echoHandled = c.handleIncomingPacket(
        {
          'type': 'chat_message',
          'text': 'привет',
          'name': 'Я',
          'msgId': 'srv-o3',
          'clientMsgId': 'cid-o3',
        },
        fallbackName: 'Гость',
        isDuplicate: (_) => false,
      );
      expect(echoHandled, isTrue);
      expect(c.messages, hasLength(1));
      expect(c.messages.single.failed, isFalse);
    });

    test('отказ, а потом позднее эхо: запись не удаляется и реконсилируется задним числом', () {
      c.addOwn('Я', 'привет', 'cid-o4');

      final failedMarked = c.markFailed('cid-o4');
      expect(failedMarked, isTrue);
      expect(c.messages.single.failed, isTrue);
      expect(c.messages, hasLength(1), reason: 'запись об ожидании не удаляется при отказе');

      final echoHandled = c.handleIncomingPacket(
        {
          'type': 'chat_message',
          'text': 'привет',
          'name': 'Я',
          'msgId': 'srv-o4',
          'clientMsgId': 'cid-o4',
        },
        fallbackName: 'Гость',
        isDuplicate: (_) => false,
      );

      expect(echoHandled, isTrue);
      expect(c.messages, hasLength(1), reason: 'позднее эхо не должно нарисовать второе, чужое на вид сообщение');
      expect(c.messages.single.failed, isFalse);
      expect(c.messages.single.msgId, 'srv-o4');
      expect(c.messages.single.own, isTrue);
    });
  });

  // --- handleIncomingPacket: сверка выше гейта дедупликации ------------------

  group('handleIncomingPacket — порядок сверки и гейта', () {
    test('чужое сообщение с чужим clientMsgId рисуется обычным образом', () {
      final handled = c.handleIncomingPacket(
        {
          'type': 'chat_message',
          'text': 'привет всем',
          'name': 'Боб',
          'msgId': 'srv-x',
          'clientMsgId': 'their-cid',
        },
        fallbackName: 'Гость',
        isDuplicate: (_) => false,
      );

      expect(handled, isTrue);
      expect(c.messages, hasLength(1));
      expect(c.messages.single.own, isFalse);
      expect(c.messages.single.name, 'Боб');
      expect(c.messages.single.msgId, 'srv-x');
      expect(c.messages.single.clientMsgId, 'their-cid');
    });

    test(
      'своё эхо реконсилируется, даже если внешний гейт счёл бы msgId дублем — '
      'гейт для реконсилированного эха вообще не спрашивается',
      () {
        c.addOwn('Я', 'привет', 'cid-gate1');
        var gateCalls = 0;
        bool alwaysDuplicate(String _) {
          gateCalls++;
          return true;
        }

        final handled = c.handleIncomingPacket(
          {
            'type': 'chat_message',
            'text': 'привет',
            'name': 'Я',
            'msgId': 'srv-gate1',
            'clientMsgId': 'cid-gate1',
          },
          fallbackName: 'Гость',
          isDuplicate: alwaysDuplicate,
        );

        expect(handled, isTrue,
            reason: 'сверка не должна зависеть от вердикта гейта дедупликации');
        expect(gateCalls, 0,
            reason: 'реконсилированное собственное эхо не должно доходить до гейта');
        expect(c.messages.single.msgId, 'srv-gate1');
        expect(c.messages.single.failed, isFalse);
      },
    );

    test('чужой пакет без clientMsgId всё же проходит через гейт дедупликации', () {
      var gateCalls = 0;
      bool neverSeenBefore(String _) {
        gateCalls++;
        return false;
      }

      final handled = c.handleIncomingPacket(
        {'type': 'chat_message', 'text': 'привет', 'name': 'Боб', 'msgId': 'srv-gate2'},
        fallbackName: 'Гость',
        isDuplicate: neverSeenBefore,
      );

      expect(handled, isTrue);
      expect(gateCalls, 1);
    });

    test('гейт дедупликации всё же отсеивает настоящий повтор чужого пакета', () {
      final handled = c.handleIncomingPacket(
        {'type': 'chat_message', 'text': 'привет', 'name': 'Боб', 'msgId': 'srv-gate3'},
        fallbackName: 'Гость',
        isDuplicate: (_) => true,
      );

      expect(handled, isFalse);
      expect(c.messages, isEmpty);
    });

    test('пакет не-чата не обрабатывается и гейт не вызывается', () {
      var gateCalls = 0;
      final handled = c.handleIncomingPacket(
        {'type': 'recording_approved', 'msgId': 'srv-gate4'},
        fallbackName: 'Гость',
        isDuplicate: (_) {
          gateCalls++;
          return false;
        },
      );

      expect(handled, isFalse);
      expect(gateCalls, 0);
      expect(c.messages, isEmpty);
    });
  });
}

import 'dart:collection';

import 'package:flutter/foundation.dart';

import '../../domain/room_chat_history.dart';

/// Как страница истории (`GET /voice/rooms/:roomName/chat`) встраивается в
/// ленту — см. [RoomChatController.setHistory].
enum RoomChatMergeMode {
  /// Самый первый показ линии: страница старше всего, что уже могло прийти
  /// вживую пока запрос летел — встаёт в НАЧАЛО. Не считается непрочитанным:
  /// пачка исторических сообщений в момент присоединения — это фон, а не
  /// сигнал «вам написали, пока вас не было».
  prepend,

  /// Догоняющий запрос (`since=<курсор>`, см. `RoomChatLines.planFetch`)
  /// после возврата на линию, которую держали без слушателя data-канала:
  /// записи — продолжение того, что уже в ленте, а не более раннее, и
  /// встают в КОНЕЦ. Считается непрочитанным (при закрытой панели, как и
  /// живой пакет) — это ровно то, что человек пропустил, пока был на другой
  /// линии, а не история до его прихода.
  append,

  /// Полное перечитывание вместо доклейки — когда догоняющий запрос вернулся
  /// `truncated` и склеивать его с тем, что уже в ленте, нечестно (могла
  /// остаться дыра). Лента ЗАМЕНЯЕТСЯ целиком: сверка по `clientMsgId` с
  /// уже имеющимися записями не производится — раз в них нельзя быть
  /// уверенным, подмешивать их нельзя, только выбросить. Не считается
  /// непрочитанным: это аварийный ресинк, а не обычная догонка, и раздувать
  /// бейдж на весь объём перечитанной страницы было бы шумом.
  replace,
}

/// Одно сообщение в чате комнаты.
@immutable
class RoomChatMessage {
  final String name;
  final String text;
  final DateTime sentAt;
  final bool own;
  /// Реальный id сообщения, каким его знает сервер (ответ на `POST` или
  /// эхо-пакет с data-канала — оба несут одно и то же значение). `null` до
  /// подтверждения: для своих сообщений — пока не сверились ни по одному из
  /// трёх путей ([RoomChatController.reconcile]), для чужих — если пакет
  /// пришёл без этого поля (старый клиент, ещё не переведённый на серверный
  /// транспорт).
  final String? msgId;
  /// Id, которым клиент-автор пометил сообщение перед отправкой. Для чужих
  /// сообщений — то, что прислал их автор (может быть `null`). Для своих —
  /// то, что сгенерировал `_sendChatMessage`; это единственный устойчивый
  /// ключ, по которому [RoomChatController.reconcile] находит запись в
  /// ленте, поэтому он не меняется в течение жизни сообщения.
  final String? clientMsgId;
  /// «Не отправлено»: `POST /voice/rooms/:roomName/chat` завершился отказом
  /// (сеть, 400/429/503/...). Запись НЕ удаляется — сервер мог всё же
  /// принять сообщение до того, как ответ потерялся, и эхо с data-канала
  /// придёт позже отказа; см. [RoomChatController.markFailed].
  final bool failed;

  const RoomChatMessage({
    required this.name,
    required this.text,
    required this.sentAt,
    required this.own,
    this.msgId,
    this.clientMsgId,
    this.failed = false,
  });

  RoomChatMessage copyWith({String? msgId, bool? failed}) => RoomChatMessage(
        name: name,
        text: text,
        sentAt: sentAt,
        own: own,
        clientMsgId: clientMsgId,
        msgId: msgId ?? this.msgId,
        failed: failed ?? this.failed,
      );
}

/// Состояние чата комнаты: лента, счётчик непрочитанных, открыта ли панель.
///
/// Живёт ровно столько, сколько идёт звонок — но, в отличие от чисто
/// P2P-версии, история существует и на сервере: `VoiceCallScreen` один раз
/// подгружает её через `RoomChatApi.fetchHistory` и кладёт в ленту через
/// [setHistory], поэтому вошедший позже видит написанное до него.
///
/// Разбор пакета намеренно устойчив к типам: данные приходят из `jsonDecode`
/// по сети, и любое поле может оказаться не той природы, которую мы ждём.
/// Приведение вида `msg['text'] as String?` бросило бы `TypeError` на числе,
/// внешний `try/catch` в `_handleDataReceived` его проглотил бы — и сообщение
/// исчезло бы молча вместе со всем остальным разбором пакета.
///
/// ## Сверка своих сообщений (три независимых пути)
///
/// Отправка чата — `POST /voice/rooms/:roomName/chat` — асинхронна, а своё
/// сообщение рисуется сразу, до ответа ([addOwn]). Подтверждение, что оно
/// реально дошло, может прийти тремя независимыми путями, и ни один не
/// обязателен — потому что ни один не гарантирован:
///  - эхо с data-канала (сервер рассылает `chat_message` всем, включая
///    автора, ДО ответа на POST — эхо может обогнать ответ);
///  - ответ на сам POST (`{msgId, seq, ts}`);
///  - историческая запись из [setHistory] (если панель успела перезапросить
///    ленту, пока POST ещё летел).
/// Все три ведут в [reconcile]. Источник правды — сама лента (`_messages`),
/// а не отдельный набор «ожидаемых» id: так сверка остаётся идемпотентной
/// при любом порядке и повторах, и не может «протухнуть» отдельно от
/// сообщения, которое описывает.
///
/// При отказе POST запись НЕ удаляется ([markFailed]) — именно чтобы эхо,
/// пришедшее позже отказа (сервер успел принять сообщение до того, как
/// ответ потерялся), всё ещё могло её найти и снять пометку.
class RoomChatController extends ChangeNotifier {
  final List<RoomChatMessage> _messages = [];
  int _unread = 0;
  bool _open = false;

  /// Живое представление ленты, а не копия: панель дёргает геттер по
  /// несколько раз за перерисовку, а перерисовка идёт на каждое сообщение —
  /// `List.unmodifiable` копировал бы весь список каждый раз.
  late final List<RoomChatMessage> messages = UnmodifiableListView(_messages);
  int get unread => _unread;
  bool get isOpen => _open;

  void setOpen(bool open) {
    // Повторный вызов с тем же значением не должен дёргать перерисовку.
    // Второе слагаемое — на случай, если счётчик когда-нибудь сможет
    // накопиться при открытой панели: сейчас `_append` этого не допускает,
    // поэтому состояние недостижимо и тестом не покрыто, но обнуление без
    // уведомления оставило бы бейдж висеть.
    final changed = _open != open || (open && _unread != 0);
    _open = open;
    if (open) _unread = 0;
    if (changed) notifyListeners();
  }

  /// Разбирает пакет из data-канала. Возвращает false, если это не сообщение
  /// чата или оно пустое — вызывающая сторона тогда ничего не делает.
  ///
  /// Всегда добавляет НОВУЮ запись с `own: false` — не пытается опознать,
  /// не наше ли это собственное эхо. Эта проверка (по `clientMsgId`) стоит
  /// выше по стеку, в [handleIncomingPacket]: звонок из `handlePacket`
  /// напрямую (как раньше, и как всё ещё делают многие тесты) остаётся
  /// «это точно чужое сообщение, просто нарисуй его».
  bool handlePacket(
    Map<String, dynamic> msg, {
    required String fallbackName,
  }) {
    if (msg['type'] != 'chat_message') return false;

    final rawText = msg['text'];
    final text = rawText is String ? rawText.trim() : '';
    if (text.isEmpty) return false;

    final rawName = msg['name'];
    final name = rawName is String ? rawName.trim() : '';
    final ts = msg['ts'];
    final rawMsgId = msg['msgId'];
    final rawClientMsgId = msg['clientMsgId'];

    _append(RoomChatMessage(
      name: name.isEmpty ? fallbackName : name,
      text: text,
      sentAt: ts is int
          ? DateTime.fromMillisecondsSinceEpoch(ts)
          : DateTime.now(),
      own: false,
      msgId: rawMsgId is String ? rawMsgId : null,
      clientMsgId: rawClientMsgId is String ? rawClientMsgId : null,
    ));
    return true;
  }

  /// Полное решение для одного входящего `chat_message`-пакета с
  /// data-канала: сначала сверка по своему `clientMsgId` — и ТОЛЬКО если она
  /// не нашла совпадения, пакет идёт в общий гейт дедупликации вызывающей
  /// стороны и затем в [handlePacket] как обычное чужое сообщение.
  ///
  /// Порядок принципиален и намеренно захардкожен именно в эту сторону.
  /// Гейт (`isDuplicate`, на практике — `RoomDataPacketIds.isDuplicate` с
  /// экрана звонка) ключуется по `msgId` — а для пакета, который разослал
  /// сервер, `msgId` это настоящий id сообщения в БД, а не что-то, что
  /// гарантированно попадёт в тот же набор «уже виденных» id вовремя. Если
  /// проверить гейт РАНЬШЕ сверки, а не после — своё же эхо рискует быть
  /// отброшено гейтом ДО того, как сверка вообще запустится, и пометка «не
  /// отправлено» останется висеть навсегда, хотя сообщение реально дошло.
  /// Именно это поймали на веб-версии за шесть кругов ревью. Поэтому
  /// реконсилированное собственное эхо вообще не обращается к [isDuplicate]
  /// — см. тест «гейт для реконсилированного эха вообще не спрашивается».
  ///
  /// [isDuplicate] внедряется параметром, а не хранится в контроллере,
  /// потому что набор «виденных» id на экране общий для ВСЕХ типов пакетов
  /// data-канала (recording-consent и т.д.), не только чата — им владеет
  /// экран, а не эта модель чата.
  bool handleIncomingPacket(
    Map<String, dynamic> msg, {
    required String fallbackName,
    required bool Function(String msgId) isDuplicate,
  }) {
    if (msg['type'] != 'chat_message') return false;

    final rawClientMsgId = msg['clientMsgId'];
    final clientMsgId = rawClientMsgId is String ? rawClientMsgId : null;
    final rawMsgId = msg['msgId'];
    final msgId = rawMsgId is String ? rawMsgId : null;

    if (clientMsgId != null && msgId != null && reconcile(clientMsgId, msgId)) {
      return true;
    }

    if (msgId != null && isDuplicate(msgId)) return false;

    return handlePacket(msg, fallbackName: fallbackName);
  }

  /// Своё отправленное сообщение — показываем сразу, не дожидаясь ответа
  /// сервера. [clientMsgId] — идентификатор, придуманный вызывающей стороной
  /// перед отправкой ('[A-Za-z0-9_-]', 1-64 по контракту сервера); именно по
  /// нему [reconcile] потом найдёт эту запись.
  ///
  /// Идемпотентен по [clientMsgId]: повторный вызов с тем же id (повтор
  /// отправки после отказа) не добавляет вторую запись, а возвращает
  /// существующую, снимая пометку «не отправлено», если она была —
  /// см. класс-док про то, зачем отказавшая запись не удаляется.
  ///
  /// Возвращает `null`, если после обрезки текст пуст — тогда вызывающая
  /// сторона ничего не делает (defensive: панель уже не пускает сюда пустой
  /// текст, но сохраняем ту же гарантию, что была у старого `addOwn`).
  RoomChatMessage? addOwn(String name, String text, String clientMsgId) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return null;

    final existingIndex =
        _messages.indexWhere((m) => m.clientMsgId == clientMsgId);
    if (existingIndex != -1) {
      final existing = _messages[existingIndex];
      if (!existing.failed) return existing;
      final retried = existing.copyWith(failed: false);
      _messages[existingIndex] = retried;
      notifyListeners();
      return retried;
    }

    final message = RoomChatMessage(
      name: name,
      text: trimmed,
      sentAt: DateTime.now(),
      own: true,
      clientMsgId: clientMsgId,
    );
    _append(message);
    return message;
  }

  /// Сверяет своё сообщение по [clientMsgId]: находит его в ленте (сканирует
  /// `_messages` — источник правды сама лента, не отдельный набор
  /// «ожидаемых» id), проставляет настоящий [msgId] и снимает пометку «не
  /// отправлено», если она была. Идемпотентен: повторный вызов с теми же
  /// значениями (например, и эхо, и ответ на POST принесли один и тот же
  /// `msgId`) не плодит лишних уведомлений слушателей.
  ///
  /// Возвращает `false`, если сообщения с таким `clientMsgId` в ленте нет —
  /// вызывающая сторона тогда не должна считать пакет «своим».
  bool reconcile(String clientMsgId, String msgId) {
    final index = _messages.indexWhere((m) => m.clientMsgId == clientMsgId);
    if (index == -1) return false;
    if (_applyReconcile(index, msgId)) notifyListeners();
    return true;
  }

  /// Помечает своё сообщение как не отправленное — БЕЗ удаления записи: эхо
  /// может прийти позже отказа и доказать, что сообщение на самом деле
  /// дошло (см. класс-док и [reconcile]). Идемпотентен.
  ///
  /// Возвращает `false`, если сообщения с таким `clientMsgId` в ленте нет.
  bool markFailed(String clientMsgId) {
    final index = _messages.indexWhere((m) => m.clientMsgId == clientMsgId);
    if (index == -1) return false;
    final existing = _messages[index];
    if (existing.failed) return true;
    _messages[index] = existing.copyWith(failed: true);
    notifyListeners();
    return true;
  }

  /// Кладёт страницу истории (`GET /voice/rooms/:roomName/chat`) в ленту —
  /// см. [RoomChatMergeMode] по поводу того, что означает каждый режим и
  /// почему перепутать их — значит либо показать пропущенную переписку
  /// задом наперёд, либо подмешать данные, которые сервер уже пометил как
  /// потенциально дырявые.
  ///
  /// Для [RoomChatMergeMode.prepend] и [RoomChatMergeMode.append]: запись,
  /// чей `clientMsgId` уже есть в ленте — своё сообщение, которое эхо/ответ
  /// ещё не сверили, либо чужое, что уже пришло вживую — не добавляется
  /// второй раз, а сверяется на месте через тот же путь, что и [reconcile]
  /// (без второго уведомления слушателей на каждую запись).
  ///
  /// Для [RoomChatMergeMode.replace] сверка не производится вовсе — лента
  /// ОЧИЩАЕТСЯ перед вставкой страницы: источник, вернувший `truncated`,
  /// уже дал понять, что старому состоянию верить нельзя, а «сверить
  /// частично и подмешать» и есть тот самый недобросовестный сплав, ради
  /// которого прочитали лишний раз.
  void setHistory(
    List<RoomChatHistoryMessage> history, {
    RoomChatMergeMode mode = RoomChatMergeMode.prepend,
  }) {
    if (mode == RoomChatMergeMode.replace) {
      // Сознательно без сверки: очистка ленты делает `indexWhere` ниже
      // всегда -1, и каждая запись страницы становится "новой" — ровно то
      // поведение, которое и нужно для полной замены.
      _messages.clear();
    } else if (history.isEmpty) {
      return;
    }

    final newEntries = <RoomChatMessage>[];
    var changed = mode == RoomChatMergeMode.replace;
    for (final h in history) {
      final clientMsgId = h.clientMsgId;
      final index = clientMsgId == null
          ? -1
          : _messages.indexWhere((m) => m.clientMsgId == clientMsgId);
      if (index != -1) {
        if (_applyReconcile(index, h.msgId)) changed = true;
        continue;
      }
      newEntries.add(RoomChatMessage(
        name: h.name,
        text: h.text,
        sentAt: h.sentAt,
        own: h.own,
        msgId: h.msgId,
        clientMsgId: h.clientMsgId,
      ));
    }

    if (newEntries.isNotEmpty) {
      if (mode == RoomChatMergeMode.prepend) {
        _messages.insertAll(0, newEntries);
      } else {
        // append и replace: обе кладут в конец — разница между ними уже
        // отыграна выше (replace очистил ленту перед циклом, append — нет).
        _messages.addAll(newEntries);
      }
      changed = true;
      // См. RoomChatMergeMode: только "append" считается непрочитанным —
      // это единственный режим, в котором новые записи для человека
      // действительно новость, а не фон присоединения или аварийный ресинк.
      if (mode == RoomChatMergeMode.append && !_open) {
        _unread += newEntries.where((m) => !m.own).length;
      }
    }
    if (changed) notifyListeners();
  }

  /// Общая мутация для [reconcile] и [setHistory]: проставляет [msgId] и
  /// снимает `failed` у записи `_messages[index]`, если что-то реально
  /// меняется. Не вызывает `notifyListeners()` сама — вызывающая сторона
  /// решает, когда уведомить (при обходе истории это одно уведомление на
  /// всю страницу, а не на каждую совпавшую запись).
  bool _applyReconcile(int index, String msgId) {
    final existing = _messages[index];
    if (existing.msgId == msgId && !existing.failed) return false;
    _messages[index] = existing.copyWith(msgId: msgId, failed: false);
    return true;
  }

  void _append(RoomChatMessage m) {
    _messages.add(m);
    if (!m.own && !_open) _unread++;
    notifyListeners();
  }
}

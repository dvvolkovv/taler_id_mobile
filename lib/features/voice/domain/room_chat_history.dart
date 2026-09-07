import 'package:flutter/foundation.dart';

/// Одно сообщение в странице истории чата комнаты, как их отдаёт
/// `GET /voice/rooms/:roomName/chat`.
@immutable
class RoomChatHistoryMessage {
  final String msgId;
  final String text;
  final String name;
  final DateTime sentAt;
  /// Серверный порядковый номер этого сообщения (не путать с
  /// [RoomChatHistoryPage.seq] — курсором страницы).
  final int seq;
  /// От чьего лица показывать пузырь — решает сервер, не клиент.
  final bool own;
  /// `null` — сервер не получил `clientMsgId` для этого сообщения (обычный
  /// случай для истории, отправленной кем-то другим или до этой фичи).
  /// Пустая строка сюда никогда не должна попасть: сервер сам не пришлёт
  /// ключ с пустым значением, а разбор ниже намеренно не подменяет
  /// «ключа нет» на `''`, чтобы одно не превратилось в другое.
  final String? clientMsgId;

  const RoomChatHistoryMessage({
    required this.msgId,
    required this.text,
    required this.name,
    required this.sentAt,
    required this.seq,
    required this.own,
    this.clientMsgId,
  });
}

/// Страница истории чата комнаты, как её отдаёт
/// `GET /voice/rooms/:roomName/chat?since=<seq>`.
@immutable
class RoomChatHistoryPage {
  final List<RoomChatHistoryMessage> messages;
  /// Курсор: значение для следующего запроса `?since=`.
  final int seq;
  /// true — сервер обрезал историю, часть более старых сообщений не прислана.
  final bool truncated;

  const RoomChatHistoryPage({
    required this.messages,
    required this.seq,
    required this.truncated,
  });
}

/// Разбирает ответ `GET /voice/rooms/:roomName/chat`.
///
/// [json] приходит из `jsonDecode` сетевого ответа: сервер свой, но поле
/// всё равно может оказаться не той природы, которую мы ждём (регрессия на
/// бэкенде, урезанный ответ прокси и т.п.). Приведение вида
/// `m['text'] as String` бросило бы `TypeError` на числе и унесло бы всю
/// страницу истории целиком, а не одну кривую запись — тот же принцип, что
/// в `parseRoomChatText` и `RoomChatController.handlePacket`: каждое поле
/// проверяется через `is`, а не приводится напрямую, и одна плохая запись
/// пропускается, не трогая соседей.
RoomChatHistoryPage parseRoomChatHistory(Map<String, dynamic> json) {
  final rawMessages = json['messages'];
  final messages = <RoomChatHistoryMessage>[];
  if (rawMessages is List) {
    for (final raw in rawMessages) {
      if (raw is! Map) continue;
      final parsed = _parseMessage(raw);
      if (parsed != null) messages.add(parsed);
    }
  }

  final rawSeq = json['seq'];
  final rawTruncated = json['truncated'];
  return RoomChatHistoryPage(
    messages: messages,
    seq: rawSeq is int ? rawSeq : 0,
    truncated: rawTruncated == true,
  );
}

RoomChatHistoryMessage? _parseMessage(Map raw) {
  final rawText = raw['text'];
  final text = rawText is String ? rawText.trim() : '';
  // Сообщение без текста бессмысленно рисовать — пропускаем его, а не всю
  // страницу.
  if (text.isEmpty) return null;

  final rawMsgId = raw['msgId'];
  final rawName = raw['name'];
  final rawTs = raw['ts'];
  final rawSeq = raw['seq'];
  final rawOwn = raw['own'];

  // «Ключа нет» отличаем от «ключ есть» через containsKey — приведение вида
  // `raw['clientMsgId'] as String? ?? ''` слило бы оба случая в одну пустую
  // строку и лишило бы отправителя единственного способа опознать своё же
  // сообщение в истории (см. четыре урока в описании фичи).
  String? clientMsgId;
  if (raw.containsKey('clientMsgId')) {
    final rawClientMsgId = raw['clientMsgId'];
    clientMsgId = rawClientMsgId is String ? rawClientMsgId : null;
  }

  return RoomChatHistoryMessage(
    msgId: rawMsgId is String ? rawMsgId : '',
    text: text,
    name: rawName is String ? rawName.trim() : '',
    sentAt: rawTs is int ? DateTime.fromMillisecondsSinceEpoch(rawTs) : DateTime.now(),
    seq: rawSeq is int ? rawSeq : 0,
    own: rawOwn == true,
    clientMsgId: clientMsgId,
  );
}

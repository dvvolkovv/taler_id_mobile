import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../core/api/dio_client.dart';
import '../domain/room_chat_history.dart';

/// Результат `POST /voice/rooms/:roomName/chat`.
@immutable
class RoomChatSendResult {
  final String msgId;
  final int seq;
  final DateTime sentAt;

  const RoomChatSendResult({
    required this.msgId,
    required this.seq,
    required this.sentAt,
  });
}

/// Разбирает `{ts, seq, msgId}` так же устойчиво к типам, как
/// [parseRoomChatHistory]: ответ свой, серверный, но всё равно проходит
/// через `jsonDecode`, и приведение вида `json['msgId'] as String` бросило
/// бы `TypeError` на регрессии бэкенда вместо понятной деградации.
RoomChatSendResult _parseSendResult(Map<String, dynamic> json) {
  final rawMsgId = json['msgId'];
  final rawSeq = json['seq'];
  final rawTs = json['ts'];
  return RoomChatSendResult(
    msgId: rawMsgId is String ? rawMsgId : '',
    seq: rawSeq is int ? rawSeq : 0,
    sentAt: rawTs is int ? DateTime.fromMillisecondsSinceEpoch(rawTs) : DateTime.now(),
  );
}

/// Клиент REST-ручек чата комнаты (LiveKit-звонка).
///
/// Обе ручки авторизуются room-scoped LiveKit-токеном — тем самым, что
/// приложение получает при входе в комнату (`VoiceCallScreen._lkToken`,
/// см. `CallStateService.lkToken`), а НЕ токеном Taler ID: `RoomAccessGuard`
/// по токену Taler ID пускает только участника звонка, владельца
/// персональной комнаты или создателя временной, поэтому залогиненный гость
/// в чужой временной комнате получит с ним 403.
///
/// Поэтому запросы идут не через `DioClient.get/post` (они не принимают
/// `Options`), а напрямую через `dio` с ручным заголовком `Authorization` и
/// `extra: {'skipAuth': true}` — без него `AuthInterceptor.onRequest`
/// перепишет заголовок токеном Taler ID поверх нашего (см.
/// `core/api/auth_interceptor.dart`).
class RoomChatApi {
  final DioClient _dioClient;

  RoomChatApi(this._dioClient);

  Options _authOptions(String lkToken) => Options(
        headers: {'Authorization': 'Bearer $lkToken'},
        extra: {'skipAuth': true},
      );

  /// `POST /voice/rooms/:roomName/chat` — отправляет сообщение в чат
  /// комнаты. [clientMsgId] опознаёт своё же сообщение по возвращении эхом
  /// через data-канал или в истории — сервер кладёт его в оба места, если
  /// он был передан здесь.
  Future<RoomChatSendResult> sendMessage({
    required String roomName,
    required String lkToken,
    required String text,
    String? name,
    String? clientMsgId,
  }) async {
    final response = await _dioClient.dio.post(
      '/voice/rooms/$roomName/chat',
      data: {
        'text': text,
        if (name != null) 'name': name,
        if (clientMsgId != null) 'clientMsgId': clientMsgId,
      },
      options: _authOptions(lkToken),
    );
    return _parseSendResult(Map<String, dynamic>.from(response.data as Map));
  }

  /// `GET /voice/rooms/:roomName/chat?since=<seq>` — постранично забирает
  /// ленту. [since] опущен для первой страницы (с начала истории).
  Future<RoomChatHistoryPage> fetchHistory({
    required String roomName,
    required String lkToken,
    int? since,
  }) async {
    final response = await _dioClient.dio.get(
      '/voice/rooms/$roomName/chat',
      queryParameters: since != null ? {'since': since} : null,
      options: _authOptions(lkToken),
    );
    return parseRoomChatHistory(Map<String, dynamic>.from(response.data as Map));
  }
}

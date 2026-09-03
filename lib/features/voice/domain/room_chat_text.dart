import 'package:flutter/foundation.dart';

/// Потолок длины сообщения в чате комнаты — зеркалит `maxLength` у поля ввода
/// в `room_chat_panel.dart`. Человеку его навязывает виджет, ассистентам —
/// [parseRoomChatText].
const int kRoomChatMaxLength = 500;

/// Результат разбора аргумента `text` инструмента `send_room_chat`.
///
/// Ровно одно из полей заполнено: либо [text] — обрезанный текст, готовый к
/// отправке, либо [refusal] — причина отказа готовой фразой, которую модель
/// может произнести вслух.
@immutable
class RoomChatTextParse {
  final String? text;
  final String? refusal;

  const RoomChatTextParse._({this.text, this.refusal});

  bool get isValid => text != null;
}

/// Разбирает и проверяет текст сообщения для чата комнаты.
///
/// Один и тот же разбор нужен обоим ассистентам: тому, что живёт на экране
/// звонка (`VoiceCallScreen._handleAssistantFunctionCall`), и отдельному
/// (`AssistantToolsExecutor`). Списки инструментов у них независимые, а вот
/// правила — те же, что и у человека за полем ввода, поэтому они здесь, в
/// одном месте.
///
/// [raw] намеренно `Object?`, а не `String?`: модель регулярно присылает
/// число там, где объявлена строка, и приведение `args['text'] as String?`
/// бросило бы `TypeError`. Оба вызывающих ловят исключения снаружи и
/// показали бы пользователю невнятную поломку вместо понятного отказа. Та же
/// логика, что в `RoomChatController.handlePacket`.
///
/// Отказы на английском: их читает модель, а пользователю она перескажет их
/// на его языке сама.
RoomChatTextParse parseRoomChatText(Object? raw) {
  final text = raw is String ? raw.trim() : '';
  if (text.isEmpty) {
    return const RoomChatTextParse._(
      refusal: 'The message is empty, nothing to send.',
    );
  }
  if (text.length > kRoomChatMaxLength) {
    // Отказ, а не обрезка: молча укороченное сообщение выглядит для всех в
    // комнате законченным.
    return const RoomChatTextParse._(
      refusal: 'The message is too long ($kRoomChatMaxLength characters max). '
          'Shorten it and send again.',
    );
  }
  return RoomChatTextParse._(text: text);
}

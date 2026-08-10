import 'package:freezed_annotation/freezed_annotation.dart';

part 'reply_preview_entity.freezed.dart';
part 'reply_preview_entity.g.dart';

/// Цитата: кусок сообщения, на которое отвечают.
///
/// Приходит вместе с самим ответом, чтобы пузырь рисовался сразу — без дозагрузки
/// оригинала, которого в загруженном окне истории может и не быть.
///
/// [content] обрезан сервером до 200 символов: цитата — подпись, а не копия.
/// [isDeleted] означает, что оригинал удалили уже после ответа; тело в этом
/// случае приходит пустым, и рисовать надо «Сообщение удалено».
@freezed
class ReplyPreviewEntity with _$ReplyPreviewEntity {
  const factory ReplyPreviewEntity({
    required String id,
    String? senderId,
    String? senderName,
    @Default('') String content,
    String? fileType,
    String? fileName,
    @Default(false) bool isDeleted,
  }) = _ReplyPreviewEntity;

  factory ReplyPreviewEntity.fromJson(Map<String, dynamic> json) =>
      _$ReplyPreviewEntityFromJson(json);
}

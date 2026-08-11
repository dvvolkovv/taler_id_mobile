import 'package:freezed_annotation/freezed_annotation.dart';

import 'forwarded_from_entity.dart';
import 'reply_preview_entity.dart';

part 'message_entity.freezed.dart';
part 'message_entity.g.dart';

@freezed
class MessageEntity with _$MessageEntity {
  /// explicitToJson нужен из-за вложенных replyTo/forwardedFrom: без него
  /// toJson кладёт в карту живые объекты вместо их Map, и обратный fromJson
  /// падает. Ставится именно на фабрику, а не на класс.
  @JsonSerializable(explicitToJson: true)
  const factory MessageEntity({
    required String id,
    required String conversationId,
    required String senderId,
    String? senderName,
    required String content,
    required DateTime sentAt,
    String? fileUrl,
    String? fileName,
    int? fileSize,
    String? fileType,
    String? s3Key,
    String? thumbnailSmallUrl,
    String? thumbnailMediumUrl,
    String? thumbnailLargeUrl,
    String? fileRecordId,
    @Default(false) bool isDelivered,
    @Default(false) bool isRead,
    @Default(false) bool isSystem,
    @Default(false) bool isEdited,
    @Default([]) List<Map<String, dynamic>> reactions,
    String? threadParentId,
    @Default(0) int threadReplyCount,
    List<String>? threadLastReplierAvatars,
    String? topicId,
    Map<String, dynamic>? metadata,
    /// Phase 1f — "mesh" for messages delivered via MeshMessagingService.
    /// Null (or absent in server JSON) means the normal socket/REST path.
    String? transport,
    /// Pin state: null means the message is not pinned.
    DateTime? pinnedAt,
    String? pinnedById,

    /// Ответ. [replyToId] есть всегда, когда сообщение — ответ; [replyTo]
    /// может быть null у старых клиентов и на путях, которые превью не
    /// собирают, поэтому UI опирается на наличие самого превью.
    String? replyToId,
    ReplyPreviewEntity? replyTo,

    /// Атрибуция пересылки; null у обычного сообщения.
    ForwardedFromEntity? forwardedFrom,

    /// Кого упомянули. Считает сервер по участникам беседы — клиенту эти id
    /// нужны только чтобы подсветить своё упоминание.
    @Default([]) List<String> mentionedUserIds,

    /// Просмотры поста канала. null у остальных бесед: там то же число
    /// показывается галочками.
    int? viewCount,
  }) = _MessageEntity;

  factory MessageEntity.fromJson(Map<String, dynamic> json) =>
      _$MessageEntityFromJson(json);
}

import 'package:freezed_annotation/freezed_annotation.dart';

part 'message_entity.freezed.dart';
part 'message_entity.g.dart';

@freezed
class MessageEntity with _$MessageEntity {
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
  }) = _MessageEntity;

  factory MessageEntity.fromJson(Map<String, dynamic> json) =>
      _$MessageEntityFromJson(json);
}

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'message_entity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$MessageEntityImpl _$$MessageEntityImplFromJson(Map<String, dynamic> json) =>
    _$MessageEntityImpl(
      id: json['id'] as String,
      conversationId: json['conversationId'] as String,
      senderId: json['senderId'] as String,
      senderName: json['senderName'] as String?,
      content: json['content'] as String,
      sentAt: DateTime.parse(json['sentAt'] as String),
      fileUrl: json['fileUrl'] as String?,
      fileName: json['fileName'] as String?,
      fileSize: (json['fileSize'] as num?)?.toInt(),
      fileType: json['fileType'] as String?,
      s3Key: json['s3Key'] as String?,
      thumbnailSmallUrl: json['thumbnailSmallUrl'] as String?,
      thumbnailMediumUrl: json['thumbnailMediumUrl'] as String?,
      thumbnailLargeUrl: json['thumbnailLargeUrl'] as String?,
      fileRecordId: json['fileRecordId'] as String?,
      isDelivered: json['isDelivered'] as bool? ?? false,
      isRead: json['isRead'] as bool? ?? false,
      isSystem: json['isSystem'] as bool? ?? false,
      isEdited: json['isEdited'] as bool? ?? false,
      reactions: (json['reactions'] as List<dynamic>?)
              ?.map((e) => e as Map<String, dynamic>)
              .toList() ??
          const [],
      threadParentId: json['threadParentId'] as String?,
      threadReplyCount: (json['threadReplyCount'] as num?)?.toInt() ?? 0,
      threadLastReplierAvatars:
          (json['threadLastReplierAvatars'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList(),
      topicId: json['topicId'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
      transport: json['transport'] as String?,
      pinnedAt: json['pinnedAt'] == null
          ? null
          : DateTime.parse(json['pinnedAt'] as String),
      pinnedById: json['pinnedById'] as String?,
      replyToId: json['replyToId'] as String?,
      replyTo: json['replyTo'] == null
          ? null
          : ReplyPreviewEntity.fromJson(
              json['replyTo'] as Map<String, dynamic>),
      forwardedFrom: json['forwardedFrom'] == null
          ? null
          : ForwardedFromEntity.fromJson(
              json['forwardedFrom'] as Map<String, dynamic>),
      mentionedUserIds: (json['mentionedUserIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      viewCount: (json['viewCount'] as num?)?.toInt(),
    );

Map<String, dynamic> _$$MessageEntityImplToJson(_$MessageEntityImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'conversationId': instance.conversationId,
      'senderId': instance.senderId,
      'senderName': instance.senderName,
      'content': instance.content,
      'sentAt': instance.sentAt.toIso8601String(),
      'fileUrl': instance.fileUrl,
      'fileName': instance.fileName,
      'fileSize': instance.fileSize,
      'fileType': instance.fileType,
      's3Key': instance.s3Key,
      'thumbnailSmallUrl': instance.thumbnailSmallUrl,
      'thumbnailMediumUrl': instance.thumbnailMediumUrl,
      'thumbnailLargeUrl': instance.thumbnailLargeUrl,
      'fileRecordId': instance.fileRecordId,
      'isDelivered': instance.isDelivered,
      'isRead': instance.isRead,
      'isSystem': instance.isSystem,
      'isEdited': instance.isEdited,
      'reactions': instance.reactions,
      'threadParentId': instance.threadParentId,
      'threadReplyCount': instance.threadReplyCount,
      'threadLastReplierAvatars': instance.threadLastReplierAvatars,
      'topicId': instance.topicId,
      'metadata': instance.metadata,
      'transport': instance.transport,
      'pinnedAt': instance.pinnedAt?.toIso8601String(),
      'pinnedById': instance.pinnedById,
      'replyToId': instance.replyToId,
      'replyTo': instance.replyTo?.toJson(),
      'forwardedFrom': instance.forwardedFrom?.toJson(),
      'mentionedUserIds': instance.mentionedUserIds,
      'viewCount': instance.viewCount,
    };

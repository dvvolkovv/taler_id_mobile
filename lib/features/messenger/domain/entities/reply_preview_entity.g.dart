// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reply_preview_entity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ReplyPreviewEntityImpl _$$ReplyPreviewEntityImplFromJson(
        Map<String, dynamic> json) =>
    _$ReplyPreviewEntityImpl(
      id: json['id'] as String,
      senderId: json['senderId'] as String?,
      senderName: json['senderName'] as String?,
      content: json['content'] as String? ?? '',
      fileType: json['fileType'] as String?,
      fileName: json['fileName'] as String?,
      isDeleted: json['isDeleted'] as bool? ?? false,
    );

Map<String, dynamic> _$$ReplyPreviewEntityImplToJson(
        _$ReplyPreviewEntityImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'senderId': instance.senderId,
      'senderName': instance.senderName,
      'content': instance.content,
      'fileType': instance.fileType,
      'fileName': instance.fileName,
      'isDeleted': instance.isDeleted,
    };

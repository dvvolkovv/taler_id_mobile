// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pinned_preview_entity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PinnedPreviewEntityImpl _$$PinnedPreviewEntityImplFromJson(
        Map<String, dynamic> json) =>
    _$PinnedPreviewEntityImpl(
      id: json['id'] as String,
      content: json['content'] as String? ?? '',
      senderName: json['senderName'] as String?,
      sentAt: json['sentAt'] == null
          ? null
          : DateTime.parse(json['sentAt'] as String),
      pinnedAt: json['pinnedAt'] == null
          ? null
          : DateTime.parse(json['pinnedAt'] as String),
    );

Map<String, dynamic> _$$PinnedPreviewEntityImplToJson(
        _$PinnedPreviewEntityImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'content': instance.content,
      'senderName': instance.senderName,
      'sentAt': instance.sentAt?.toIso8601String(),
      'pinnedAt': instance.pinnedAt?.toIso8601String(),
    };

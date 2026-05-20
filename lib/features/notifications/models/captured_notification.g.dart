// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'captured_notification.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$CapturedNotificationImpl _$$CapturedNotificationImplFromJson(
        Map<String, dynamic> json) =>
    _$CapturedNotificationImpl(
      packageName: json['packageName'] as String,
      key: json['key'] as String,
      postedAt: DateTime.parse(json['postedAt'] as String),
      title: json['title'] as String,
      body: json['body'] as String,
      conversationTitle: json['conversationTitle'] as String?,
      canReply: json['canReply'] as bool? ?? false,
    );

Map<String, dynamic> _$$CapturedNotificationImplToJson(
        _$CapturedNotificationImpl instance) =>
    <String, dynamic>{
      'packageName': instance.packageName,
      'key': instance.key,
      'postedAt': instance.postedAt.toIso8601String(),
      'title': instance.title,
      'body': instance.body,
      'conversationTitle': instance.conversationTitle,
      'canReply': instance.canReply,
    };

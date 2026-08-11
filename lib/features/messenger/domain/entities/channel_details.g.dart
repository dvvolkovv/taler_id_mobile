// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'channel_details.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ChannelDetailsImpl _$$ChannelDetailsImplFromJson(Map<String, dynamic> json) =>
    _$ChannelDetailsImpl(
      id: json['id'] as String,
      name: json['name'] as String?,
      description: json['description'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      subscribersCount: (json['subscribersCount'] as num?)?.toInt() ?? 0,
      isSubscribed: json['isSubscribed'] as bool? ?? false,
      myRole: json['myRole'] as String?,
      publicUsername: json['publicUsername'] as String?,
    );

Map<String, dynamic> _$$ChannelDetailsImplToJson(
        _$ChannelDetailsImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'avatarUrl': instance.avatarUrl,
      'subscribersCount': instance.subscribersCount,
      'isSubscribed': instance.isSubscribed,
      'myRole': instance.myRole,
      'publicUsername': instance.publicUsername,
    };

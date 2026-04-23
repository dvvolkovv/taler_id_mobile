// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'channel_summary.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ChannelSummaryImpl _$$ChannelSummaryImplFromJson(Map<String, dynamic> json) =>
    _$ChannelSummaryImpl(
      id: json['id'] as String,
      name: json['name'] as String?,
      description: json['description'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      subscribersCount: (json['subscribersCount'] as num?)?.toInt() ?? 0,
      isSubscribed: json['isSubscribed'] as bool? ?? false,
    );

Map<String, dynamic> _$$ChannelSummaryImplToJson(
        _$ChannelSummaryImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'avatarUrl': instance.avatarUrl,
      'subscribersCount': instance.subscribersCount,
      'isSubscribed': instance.isSubscribed,
    };

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'contact_item_entity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ContactItemEntityImpl _$$ContactItemEntityImplFromJson(
        Map<String, dynamic> json) =>
    _$ContactItemEntityImpl(
      userId: json['userId'] as String,
      name: json['name'] as String,
      username: json['username'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      status: $enumDecode(_$ContactStatusEnumMap, json['status']),
      conversationId: json['conversationId'] as String?,
      requestId: json['requestId'] as String?,
      requestSentAt: json['requestSentAt'] == null
          ? null
          : DateTime.parse(json['requestSentAt'] as String),
      localPending: json['localPending'] as bool? ?? false,
    );

Map<String, dynamic> _$$ContactItemEntityImplToJson(
        _$ContactItemEntityImpl instance) =>
    <String, dynamic>{
      'userId': instance.userId,
      'name': instance.name,
      'username': instance.username,
      'avatarUrl': instance.avatarUrl,
      'status': _$ContactStatusEnumMap[instance.status]!,
      'conversationId': instance.conversationId,
      'requestId': instance.requestId,
      'requestSentAt': instance.requestSentAt?.toIso8601String(),
      'localPending': instance.localPending,
    };

const _$ContactStatusEnumMap = {
  ContactStatus.incoming: 'incoming',
  ContactStatus.accepted: 'accepted',
  ContactStatus.pending: 'pending',
};

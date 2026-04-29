// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'group_call_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ProfileSummaryDtoImpl _$$ProfileSummaryDtoImplFromJson(
        Map<String, dynamic> json) =>
    _$ProfileSummaryDtoImpl(
      firstName: json['firstName'] as String?,
      lastName: json['lastName'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
    );

Map<String, dynamic> _$$ProfileSummaryDtoImplToJson(
        _$ProfileSummaryDtoImpl instance) =>
    <String, dynamic>{
      'firstName': instance.firstName,
      'lastName': instance.lastName,
      'avatarUrl': instance.avatarUrl,
    };

_$UserSummaryDtoImpl _$$UserSummaryDtoImplFromJson(Map<String, dynamic> json) =>
    _$UserSummaryDtoImpl(
      id: json['id'] as String,
      profile: json['profile'] == null
          ? null
          : ProfileSummaryDto.fromJson(json['profile'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$UserSummaryDtoImplToJson(
        _$UserSummaryDtoImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'profile': instance.profile,
    };

_$GroupCallInviteDtoImpl _$$GroupCallInviteDtoImplFromJson(
        Map<String, dynamic> json) =>
    _$GroupCallInviteDtoImpl(
      id: json['id'] as String,
      groupCallId: json['groupCallId'] as String,
      userId: json['userId'] as String,
      status: $enumDecode(_$GroupCallInviteStatusDtoEnumMap, json['status']),
      invitedAt: DateTime.parse(json['invitedAt'] as String),
      respondedAt: json['respondedAt'] == null
          ? null
          : DateTime.parse(json['respondedAt'] as String),
      joinedAt: json['joinedAt'] == null
          ? null
          : DateTime.parse(json['joinedAt'] as String),
      leftAt: json['leftAt'] == null
          ? null
          : DateTime.parse(json['leftAt'] as String),
      user: json['user'] == null
          ? null
          : UserSummaryDto.fromJson(json['user'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$GroupCallInviteDtoImplToJson(
        _$GroupCallInviteDtoImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'groupCallId': instance.groupCallId,
      'userId': instance.userId,
      'status': _$GroupCallInviteStatusDtoEnumMap[instance.status]!,
      'invitedAt': instance.invitedAt.toIso8601String(),
      'respondedAt': instance.respondedAt?.toIso8601String(),
      'joinedAt': instance.joinedAt?.toIso8601String(),
      'leftAt': instance.leftAt?.toIso8601String(),
      'user': instance.user,
    };

const _$GroupCallInviteStatusDtoEnumMap = {
  GroupCallInviteStatusDto.calling: 'CALLING',
  GroupCallInviteStatusDto.joined: 'JOINED',
  GroupCallInviteStatusDto.declined: 'DECLINED',
  GroupCallInviteStatusDto.timeout: 'TIMEOUT',
  GroupCallInviteStatusDto.left: 'LEFT',
};

_$GroupCallDtoImpl _$$GroupCallDtoImplFromJson(Map<String, dynamic> json) =>
    _$GroupCallDtoImpl(
      id: json['id'] as String,
      livekitRoomName: json['livekitRoomName'] as String,
      hostUserId: json['hostUserId'] as String,
      status: $enumDecode(_$GroupCallStatusDtoEnumMap, json['status']),
      startedAt: DateTime.parse(json['startedAt'] as String),
      endedAt: json['endedAt'] == null
          ? null
          : DateTime.parse(json['endedAt'] as String),
      endedReason: json['endedReason'] as String?,
      host: json['host'] == null
          ? null
          : UserSummaryDto.fromJson(json['host'] as Map<String, dynamic>),
      invites: (json['invites'] as List<dynamic>?)
              ?.map(
                  (e) => GroupCallInviteDto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$$GroupCallDtoImplToJson(_$GroupCallDtoImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'livekitRoomName': instance.livekitRoomName,
      'hostUserId': instance.hostUserId,
      'status': _$GroupCallStatusDtoEnumMap[instance.status]!,
      'startedAt': instance.startedAt.toIso8601String(),
      'endedAt': instance.endedAt?.toIso8601String(),
      'endedReason': instance.endedReason,
      'host': instance.host,
      'invites': instance.invites,
    };

const _$GroupCallStatusDtoEnumMap = {
  GroupCallStatusDto.lobby: 'LOBBY',
  GroupCallStatusDto.active: 'ACTIVE',
  GroupCallStatusDto.ended: 'ENDED',
};

_$CreateGroupCallResponseDtoImpl _$$CreateGroupCallResponseDtoImplFromJson(
        Map<String, dynamic> json) =>
    _$CreateGroupCallResponseDtoImpl(
      groupCall:
          GroupCallDto.fromJson(json['groupCall'] as Map<String, dynamic>),
      livekitToken: json['livekitToken'] as String,
      livekitWsUrl: json['livekitWsUrl'] as String,
    );

Map<String, dynamic> _$$CreateGroupCallResponseDtoImplToJson(
        _$CreateGroupCallResponseDtoImpl instance) =>
    <String, dynamic>{
      'groupCall': instance.groupCall,
      'livekitToken': instance.livekitToken,
      'livekitWsUrl': instance.livekitWsUrl,
    };

_$JoinGroupCallResponseDtoImpl _$$JoinGroupCallResponseDtoImplFromJson(
        Map<String, dynamic> json) =>
    _$JoinGroupCallResponseDtoImpl(
      livekitToken: json['livekitToken'] as String,
      livekitWsUrl: json['livekitWsUrl'] as String,
    );

Map<String, dynamic> _$$JoinGroupCallResponseDtoImplToJson(
        _$JoinGroupCallResponseDtoImpl instance) =>
    <String, dynamic>{
      'livekitToken': instance.livekitToken,
      'livekitWsUrl': instance.livekitWsUrl,
    };

_$ActiveGroupCallsResponseDtoImpl _$$ActiveGroupCallsResponseDtoImplFromJson(
        Map<String, dynamic> json) =>
    _$ActiveGroupCallsResponseDtoImpl(
      calls: (json['calls'] as List<dynamic>?)
              ?.map((e) => GroupCallDto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$$ActiveGroupCallsResponseDtoImplToJson(
        _$ActiveGroupCallsResponseDtoImpl instance) =>
    <String, dynamic>{
      'calls': instance.calls,
    };

_$GetGroupCallResponseDtoImpl _$$GetGroupCallResponseDtoImplFromJson(
        Map<String, dynamic> json) =>
    _$GetGroupCallResponseDtoImpl(
      groupCall:
          GroupCallDto.fromJson(json['groupCall'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$GetGroupCallResponseDtoImplToJson(
        _$GetGroupCallResponseDtoImpl instance) =>
    <String, dynamic>{
      'groupCall': instance.groupCall,
    };

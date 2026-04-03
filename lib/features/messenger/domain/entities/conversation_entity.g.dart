// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'conversation_entity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ConversationEntityImpl _$$ConversationEntityImplFromJson(
        Map<String, dynamic> json) =>
    _$ConversationEntityImpl(
      id: json['id'] as String,
      participantIds: (json['participantIds'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      type: json['type'] as String? ?? 'DIRECT',
      name: json['name'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      description: json['description'] as String?,
      participantCount: (json['participantCount'] as num?)?.toInt() ?? 0,
      myRole: json['myRole'] as String?,
      lastMessageContent: json['lastMessageContent'] as String?,
      lastMessageAt: json['lastMessageAt'] == null
          ? null
          : DateTime.parse(json['lastMessageAt'] as String),
      lastMessageSenderId: json['lastMessageSenderId'] as String?,
      lastMessageSenderName: json['lastMessageSenderName'] as String?,
      lastMessageIsSystem: json['lastMessageIsSystem'] as bool? ?? false,
      otherUserName: json['otherUserName'] as String?,
      otherUserId: json['otherUserId'] as String?,
      otherUserAvatar: json['otherUserAvatar'] as String?,
      otherUserStatus: json['otherUserStatus'] as String?,
      otherUserLastSeen: json['otherUserLastSeen'] == null
          ? null
          : DateTime.parse(json['otherUserLastSeen'] as String),
      unreadCount: (json['unreadCount'] as num?)?.toInt() ?? 0,
      isMuted: json['isMuted'] as bool? ?? false,
      mutedUntil: json['mutedUntil'] == null
          ? null
          : DateTime.parse(json['mutedUntil'] as String),
      activeCallRoomName: json['activeCallRoomName'] as String?,
      slowMode: json['slowMode'] as bool? ?? false,
      topicsEnabled: json['topicsEnabled'] as bool? ?? false,
      autoDeleteDays: (json['autoDeleteDays'] as num?)?.toInt(),
    );

Map<String, dynamic> _$$ConversationEntityImplToJson(
        _$ConversationEntityImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'participantIds': instance.participantIds,
      'type': instance.type,
      'name': instance.name,
      'avatarUrl': instance.avatarUrl,
      'description': instance.description,
      'participantCount': instance.participantCount,
      'myRole': instance.myRole,
      'lastMessageContent': instance.lastMessageContent,
      'lastMessageAt': instance.lastMessageAt?.toIso8601String(),
      'lastMessageSenderId': instance.lastMessageSenderId,
      'lastMessageSenderName': instance.lastMessageSenderName,
      'lastMessageIsSystem': instance.lastMessageIsSystem,
      'otherUserName': instance.otherUserName,
      'otherUserId': instance.otherUserId,
      'otherUserAvatar': instance.otherUserAvatar,
      'otherUserStatus': instance.otherUserStatus,
      'otherUserLastSeen': instance.otherUserLastSeen?.toIso8601String(),
      'unreadCount': instance.unreadCount,
      'isMuted': instance.isMuted,
      'mutedUntil': instance.mutedUntil?.toIso8601String(),
      'activeCallRoomName': instance.activeCallRoomName,
      'slowMode': instance.slowMode,
      'topicsEnabled': instance.topicsEnabled,
      'autoDeleteDays': instance.autoDeleteDays,
    };

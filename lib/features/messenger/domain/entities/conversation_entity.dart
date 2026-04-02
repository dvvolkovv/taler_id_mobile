import 'package:freezed_annotation/freezed_annotation.dart';

part 'conversation_entity.freezed.dart';
part 'conversation_entity.g.dart';

@freezed
class ConversationEntity with _$ConversationEntity {
  const factory ConversationEntity({
    required String id,
    required List<String> participantIds,
    @Default('DIRECT') String type,
    String? name,
    String? avatarUrl,
    String? description,
    @Default(0) int participantCount,
    String? myRole,
    String? lastMessageContent,
    DateTime? lastMessageAt,
    String? lastMessageSenderId,
    String? lastMessageSenderName,
    @Default(false) bool lastMessageIsSystem,
    String? otherUserName,
    String? otherUserId,
    String? otherUserAvatar,
    String? otherUserStatus,
    DateTime? otherUserLastSeen,
    @Default(0) int unreadCount,
    @Default(false) bool isMuted,
    DateTime? mutedUntil,
    String? activeCallRoomName,
    @Default(false) bool slowMode,
    @Default(false) bool topicsEnabled,
    int? autoDeleteDays,
  }) = _ConversationEntity;

  factory ConversationEntity.fromJson(Map<String, dynamic> json) =>
      _$ConversationEntityFromJson(json);
}

import 'package:equatable/equatable.dart';
import '../../domain/entities/message_entity.dart';

abstract class MessengerEvent extends Equatable {
  const MessengerEvent();
  @override
  List<Object?> get props => [];
}

class ConnectMessenger extends MessengerEvent {
  final String accessToken;
  final String? userId;
  const ConnectMessenger(this.accessToken, {this.userId});
  @override
  List<Object?> get props => [accessToken, userId];
}

class ClearNewConversation extends MessengerEvent {}

class LoadConversations extends MessengerEvent {}

class OpenConversation extends MessengerEvent {
  final String conversationId;
  const OpenConversation(this.conversationId);
  @override
  List<Object?> get props => [conversationId];
}

class SendMessage extends MessengerEvent {
  final String conversationId;
  final String content;
  final String? fileUrl;
  final String? fileName;
  final int? fileSize;
  final String? fileType;
  final String? s3Key;
  final String? thumbnailSmallUrl;
  final String? thumbnailMediumUrl;
  final String? thumbnailLargeUrl;
  final String? fileRecordId;
  final String? topicId;
  const SendMessage(
    this.conversationId,
    this.content, {
    this.fileUrl,
    this.fileName,
    this.fileSize,
    this.fileType,
    this.s3Key,
    this.thumbnailSmallUrl,
    this.thumbnailMediumUrl,
    this.thumbnailLargeUrl,
    this.fileRecordId,
    this.topicId,
  });
  @override
  List<Object?> get props => [conversationId, content, fileUrl, fileName];
}

class MessageReceived extends MessengerEvent {
  final MessageEntity message;
  const MessageReceived(this.message);
  @override
  List<Object?> get props => [message];
}

class LoadMoreMessages extends MessengerEvent {
  final String conversationId;
  const LoadMoreMessages(this.conversationId);
  @override
  List<Object?> get props => [conversationId];
}

class SearchUsers extends MessengerEvent {
  final String query;
  const SearchUsers(this.query);
  @override
  List<Object?> get props => [query];
}

class StartConversationWith extends MessengerEvent {
  final String userId;
  const StartConversationWith(this.userId);
  @override
  List<Object?> get props => [userId];
}

class CallInviteReceived extends MessengerEvent {
  final Map<String, dynamic> data;
  const CallInviteReceived(this.data);
  @override
  List<Object?> get props => [data];
}

class DismissCallInvite extends MessengerEvent {}

class MessageUpdated extends MessengerEvent {
  final String messageId;
  final bool? isDelivered;
  final bool? isRead;
  final String? content;
  final bool? isEdited;
  const MessageUpdated(this.messageId, {this.isDelivered, this.isRead, this.content, this.isEdited});
  @override
  List<Object?> get props => [messageId, isDelivered, isRead, content, isEdited];
}

class EditMessage extends MessengerEvent {
  final String conversationId;
  final String messageId;
  final String newContent;
  const EditMessage({required this.conversationId, required this.messageId, required this.newContent});
  @override
  List<Object?> get props => [conversationId, messageId, newContent];
}

class DeleteMessage extends MessengerEvent {
  final String conversationId;
  final String messageId;
  final bool forEveryone;
  const DeleteMessage({required this.conversationId, required this.messageId, required this.forEveryone});
  @override
  List<Object?> get props => [conversationId, messageId, forEveryone];
}

class MessageDeleted extends MessengerEvent {
  final String messageId;
  final String conversationId;
  const MessageDeleted({required this.messageId, required this.conversationId});
  @override
  List<Object?> get props => [messageId, conversationId];
}

class MessagesRead extends MessengerEvent {
  final String conversationId;
  final List<String> messageIds;
  const MessagesRead(this.conversationId, this.messageIds);
  @override
  List<Object?> get props => [conversationId, messageIds];
}

class MarkConversationRead extends MessengerEvent {
  final String conversationId;
  const MarkConversationRead(this.conversationId);
  @override
  List<Object?> get props => [conversationId];
}

// ─── Group events ───

class CreateGroup extends MessengerEvent {
  final String name;
  final List<String> participantIds;
  const CreateGroup({required this.name, required this.participantIds});
  @override
  List<Object?> get props => [name, participantIds];
}

class LoadGroupMembers extends MessengerEvent {
  final String conversationId;
  const LoadGroupMembers(this.conversationId);
  @override
  List<Object?> get props => [conversationId];
}

class AddGroupMembers extends MessengerEvent {
  final String conversationId;
  final List<String> userIds;
  const AddGroupMembers({required this.conversationId, required this.userIds});
  @override
  List<Object?> get props => [conversationId, userIds];
}

class RemoveGroupMember extends MessengerEvent {
  final String conversationId;
  final String userId;
  const RemoveGroupMember({required this.conversationId, required this.userId});
  @override
  List<Object?> get props => [conversationId, userId];
}

class ChangeGroupRole extends MessengerEvent {
  final String conversationId;
  final String userId;
  final String role;
  const ChangeGroupRole({required this.conversationId, required this.userId, required this.role});
  @override
  List<Object?> get props => [conversationId, userId, role];
}

class UpdateGroupInfo extends MessengerEvent {
  final String conversationId;
  final String? name;
  final String? avatarUrl;
  final String? description;
  const UpdateGroupInfo({required this.conversationId, this.name, this.avatarUrl, this.description});
  @override
  List<Object?> get props => [conversationId, name, avatarUrl, description];
}

class LeaveGroup extends MessengerEvent {
  final String conversationId;
  const LeaveGroup(this.conversationId);
  @override
  List<Object?> get props => [conversationId];
}

class DeleteGroup extends MessengerEvent {
  final String conversationId;
  const DeleteGroup(this.conversationId);
  @override
  List<Object?> get props => [conversationId];
}

class UpdateGroupSettings extends MessengerEvent {
  final String conversationId;
  final bool? slowMode;
  final bool? topicsEnabled;
  final int? autoDeleteDays;
  const UpdateGroupSettings({
    required this.conversationId,
    this.slowMode,
    this.topicsEnabled,
    this.autoDeleteDays,
  });
  @override
  List<Object?> get props => [conversationId, slowMode, topicsEnabled, autoDeleteDays];
}

class ForwardMessage extends MessengerEvent {
  final MessageEntity message;
  final String targetConversationId;
  const ForwardMessage({required this.message, required this.targetConversationId});
  @override
  List<Object?> get props => [message.id, targetConversationId];
}

// ─── Mute events ───

class MuteConversation extends MessengerEvent {
  final String conversationId;
  final int? durationMinutes;
  const MuteConversation({required this.conversationId, this.durationMinutes});
  @override
  List<Object?> get props => [conversationId, durationMinutes];
}

class UnmuteConversation extends MessengerEvent {
  final String conversationId;
  const UnmuteConversation(this.conversationId);
  @override
  List<Object?> get props => [conversationId];
}

// ─── Group call events ───

class GroupCallStarted extends MessengerEvent {
  final String conversationId;
  final String roomName;
  const GroupCallStarted({required this.conversationId, required this.roomName});
  @override
  List<Object?> get props => [conversationId, roomName];
}

class GroupCallEnded extends MessengerEvent {
  final String conversationId;
  const GroupCallEnded(this.conversationId);
  @override
  List<Object?> get props => [conversationId];
}

class GroupEventReceived extends MessengerEvent {
  final String eventType;
  final Map<String, dynamic> data;
  const GroupEventReceived(this.eventType, this.data);
  @override
  List<Object?> get props => [eventType, data];
}

// ─── Typing events ───

class TypingReceived extends MessengerEvent {
  final String conversationId;
  final String userId;
  final String? userName;
  final bool isTyping;
  const TypingReceived({
    required this.conversationId,
    required this.userId,
    this.userName,
    required this.isTyping,
  });
  @override
  List<Object?> get props => [conversationId, userId, isTyping];
}

class SendTyping extends MessengerEvent {
  final String conversationId;
  final bool isTyping;
  const SendTyping({required this.conversationId, required this.isTyping});
  @override
  List<Object?> get props => [conversationId, isTyping];
}

// ─── Contact request events ───

class SendContactRequest extends MessengerEvent {
  final String receiverId;
  const SendContactRequest(this.receiverId);
  @override
  List<Object?> get props => [receiverId];
}

class LoadContactRequests extends MessengerEvent {}

class AcceptContactRequest extends MessengerEvent {
  final String requestId;
  const AcceptContactRequest(this.requestId);
  @override
  List<Object?> get props => [requestId];
}

class RejectContactRequest extends MessengerEvent {
  final String requestId;
  const RejectContactRequest(this.requestId);
  @override
  List<Object?> get props => [requestId];
}

class ContactRequestReceived extends MessengerEvent {
  final Map<String, dynamic> data;
  const ContactRequestReceived(this.data);
  @override
  List<Object?> get props => [data];
}

// ─── Reaction events ───

class ReactToMessage extends MessengerEvent {
  final String conversationId;
  final String messageId;
  final String emoji;
  const ReactToMessage({required this.conversationId, required this.messageId, required this.emoji});
  @override
  List<Object?> get props => [conversationId, messageId, emoji];
}

class ReactionUpdated extends MessengerEvent {
  final String messageId;
  final String conversationId;
  final List<Map<String, dynamic>> reactions;
  const ReactionUpdated({required this.messageId, required this.conversationId, required this.reactions});
  @override
  List<Object?> get props => [messageId, conversationId, reactions];
}

class ContactRequestAccepted extends MessengerEvent {
  final Map<String, dynamic> data;
  const ContactRequestAccepted(this.data);
  @override
  List<Object?> get props => [data];
}

class LoadSentContactRequests extends MessengerEvent {}

class LoadBadgeCounts extends MessengerEvent {}

class UpdateBadgeCounts extends MessengerEvent {
  final int? missedCallsCount;
  final int? pendingCalendarInvites;
  final int? pendingContactRequests;
  const UpdateBadgeCounts({this.missedCallsCount, this.pendingCalendarInvites, this.pendingContactRequests});
  @override
  List<Object?> get props => [missedCallsCount, pendingCalendarInvites, pendingContactRequests];
}

class SocketErrorReceived extends MessengerEvent {
  final String message;
  const SocketErrorReceived(this.message);
  @override
  List<Object?> get props => [message];
}

class ClearSocketError extends MessengerEvent {
  const ClearSocketError();
  @override
  List<Object?> get props => [];
}

import '../entities/conversation_entity.dart';
import '../entities/message_entity.dart';
import '../entities/sync_result.dart';
import '../entities/user_search_entity.dart';
import '../entities/group_member_entity.dart';
import '../entities/analyst_events.dart';

abstract class IMessengerRepository {
  Future<void> connect(String accessToken);
  Future<List<ConversationEntity>> getConversations();
  Future<ConversationEntity> createConversation(String participantId);
  Future<Map<String, dynamic>> getMessages(String conversationId, {String? cursor, String? topicId});
  Future<SyncResult> sync({String? cursor, int limit});
  Future<List<UserSearchEntity>> searchUsers(String query);
  void joinConversation(String id);
  void sendMessage(String conversationId, String content, {String? fileUrl, String? fileName, int? fileSize, String? fileType, String? s3Key, String? thumbnailSmallUrl, String? thumbnailMediumUrl, String? thumbnailLargeUrl, String? fileRecordId, String? topicId, String? clientTempId});
  void editMessage(String conversationId, String messageId, String newContent);
  void deleteMessage(String conversationId, String messageId, String scope);
  void sendTyping(String conversationId, bool isTyping);
  void sendCallInvite(String conversationId, String roomName);
  Stream<MessageEntity> get messageStream;
  Stream<Map<String, dynamic>> get callInviteStream;
  Stream<String> get callAnsweredStream;
  Stream<String> get callEndedStream;
  Stream<Map<String, dynamic>> get messageUpdatedStream;
  Stream<Map<String, dynamic>> get messageDeletedStream;
  Stream<Map<String, dynamic>> get messageAckedStream;
  Stream<Map<String, dynamic>> get messagesReadStream;
  void markRead(String conversationId);
  // Group methods
  Future<ConversationEntity> createGroupConversation(String name, List<String> participantIds);
  Future<List<GroupMemberEntity>> getGroupMembers(String conversationId);
  Future<void> addGroupMembers(String conversationId, List<String> userIds);
  Future<void> removeGroupMember(String conversationId, String userId);
  Future<void> changeGroupMemberRole(String conversationId, String userId, String role);
  Future<void> updateGroupInfo(String conversationId, {String? name, String? avatarUrl, String? description, bool? slowMode, bool? topicsEnabled, int? autoDeleteDays});
  Future<void> leaveGroup(String conversationId);
  Future<void> deleteGroup(String conversationId);
  // Group streams
  Stream<Map<String, dynamic>> get groupUpdatedStream;
  Stream<Map<String, dynamic>> get groupMemberAddedStream;
  Stream<Map<String, dynamic>> get groupMemberRemovedStream;
  Stream<Map<String, dynamic>> get groupRoleChangedStream;
  Stream<Map<String, dynamic>> get groupCreatedStream;
  Stream<Map<String, dynamic>> get groupDeletedStream;
  // Group call streams
  Stream<Map<String, dynamic>> get groupCallStartedStream;
  Stream<Map<String, dynamic>> get groupCallEndedStream;
  // Typing stream
  Stream<Map<String, dynamic>> get typingStream;
  // Contact request methods
  Future<Map<String, dynamic>> sendContactRequest(String receiverId);
  Future<List<Map<String, dynamic>>> getContactRequests();
  Future<Map<String, dynamic>> acceptContactRequest(String requestId);
  Future<void> rejectContactRequest(String requestId);
  Future<List<Map<String, dynamic>>> getSentContactRequests();
  Stream<Map<String, dynamic>> get contactRequestStream;
  Stream<Map<String, dynamic>> get contactAcceptedStream;
  // Reaction methods
  void reactToMessage(String conversationId, String messageId, String emoji);
  Stream<Map<String, dynamic>> get reactionUpdatedStream;
  Stream<String> get socketErrorStream;
  // Mute methods
  Future<Map<String, dynamic>> muteConversation(String conversationId, {int? durationMinutes});
  Future<void> unmuteConversation(String conversationId);
  // Pin methods
  Future<Map<String, dynamic>> pinMessage(String conversationId, String messageId);
  Future<Map<String, dynamic>> unpinMessage(String conversationId, String messageId);
  Future<List<MessageEntity>> getPinnedMessages(String conversationId);
  Future<Map<String, dynamic>> unpinAll(String conversationId);
  Future<Map<String, dynamic>> dismissPins(String conversationId, {DateTime? upTo});
  Stream<Map<String, dynamic>> get messagePinnedStream;
  Stream<Map<String, dynamic>> get messageUnpinnedStream;
  Stream<Map<String, dynamic>> get pinsClearedStream;
  // Analyst streams
  Stream<AnalystChunk> get analystChunkStream;
  Stream<AnalystSeam>  get analystSeamStream;
  /// Returns the per-user SAVED conversation id, creating it on the server if needed.
  Future<String> getOrCreateSavedConversation();
  void dispose();

  /// Stream of mesh-delivered text messages (Phase 1e). Emits after the
  /// mesh adapter resolves the sender's devicePk to a known contact.
  Stream<MeshInboundMessage> get meshMessageStream;

  /// Stream of mesh-delivered OUTBOUND messages — emitted after the
  /// local transport ack so the bloc can replace the optimistic `temp_*`
  /// bubble with a mesh-out entry carrying `transport: 'mesh'`.
  Stream<MeshOutboundMessage> get meshOutboundStream;
}

class MeshOutboundMessage {
  final String id;
  final String conversationId;
  final String contactUserId;
  final String? clientTempId;
  final String text;
  final DateTime sentAt;
  const MeshOutboundMessage({
    required this.id,
    required this.conversationId,
    required this.contactUserId,
    required this.clientTempId,
    required this.text,
    required this.sentAt,
  });
}

/// A mesh-delivered inbound message surfaced to the messenger layer.
class MeshInboundMessage {
  final String contactUserId;
  final String conversationId;
  final String text;
  final DateTime receivedAt;
  const MeshInboundMessage({
    required this.contactUserId,
    required this.conversationId,
    required this.text,
    required this.receivedAt,
  });
}

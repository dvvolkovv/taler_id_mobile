import '../entities/conversation_entity.dart';
import '../entities/message_entity.dart';
import '../entities/user_search_entity.dart';
import '../entities/group_member_entity.dart';

abstract class IMessengerRepository {
  Future<void> connect(String accessToken);
  Future<List<ConversationEntity>> getConversations();
  Future<ConversationEntity> createConversation(String participantId);
  Future<Map<String, dynamic>> getMessages(String conversationId, {String? cursor});
  Future<List<UserSearchEntity>> searchUsers(String query);
  void joinConversation(String id);
  void sendMessage(String conversationId, String content, {String? fileUrl, String? fileName, int? fileSize, String? fileType, String? s3Key, String? thumbnailSmallUrl, String? thumbnailMediumUrl, String? thumbnailLargeUrl, String? fileRecordId, String? topicId, String? clientTempId});
  void editMessage(String conversationId, String messageId, String newContent);
  void deleteMessage(String conversationId, String messageId, String scope);
  void sendTyping(String conversationId, bool isTyping);
  void sendCallInvite(String conversationId, String roomName);
  Stream<MessageEntity> get messageStream;
  Stream<Map<String, dynamic>> get callInviteStream;
  Stream<Map<String, dynamic>> get messageUpdatedStream;
  Stream<Map<String, dynamic>> get messageDeletedStream;
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
  void dispose();
}

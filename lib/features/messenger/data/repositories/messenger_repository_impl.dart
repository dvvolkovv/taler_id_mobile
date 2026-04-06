import '../../domain/entities/conversation_entity.dart';
import '../../domain/entities/message_entity.dart';
import '../../domain/entities/user_search_entity.dart';
import '../../domain/entities/group_member_entity.dart';
import '../../domain/repositories/i_messenger_repository.dart';
import '../datasources/messenger_remote_datasource.dart';

class MessengerRepositoryImpl implements IMessengerRepository {
  final MessengerRemoteDataSource _remote;

  MessengerRepositoryImpl(this._remote);

  @override
  Future<void> connect(String accessToken) => _remote.connect(accessToken);

  @override
  Future<List<ConversationEntity>> getConversations() => _remote.getConversations();

  @override
  Future<ConversationEntity> createConversation(String participantId) =>
      _remote.createConversation(participantId);

  @override
  Future<Map<String, dynamic>> getMessages(String conversationId, {String? cursor}) =>
      _remote.getMessages(conversationId, cursor: cursor);

  @override
  Future<List<UserSearchEntity>> searchUsers(String query) => _remote.searchUsers(query);

  @override
  void joinConversation(String id) => _remote.joinConversation(id);

  @override
  void sendMessage(String conversationId, String content, {String? fileUrl, String? fileName, int? fileSize, String? fileType, String? s3Key, String? thumbnailSmallUrl, String? thumbnailMediumUrl, String? thumbnailLargeUrl, String? fileRecordId, String? topicId, String? clientTempId}) =>
      _remote.sendMessage(conversationId, content, fileUrl: fileUrl, fileName: fileName, fileSize: fileSize, fileType: fileType, s3Key: s3Key, thumbnailSmallUrl: thumbnailSmallUrl, thumbnailMediumUrl: thumbnailMediumUrl, thumbnailLargeUrl: thumbnailLargeUrl, fileRecordId: fileRecordId, topicId: topicId, clientTempId: clientTempId);

  @override
  void editMessage(String conversationId, String messageId, String newContent) =>
      _remote.editMessage(conversationId, messageId, newContent);

  @override
  void deleteMessage(String conversationId, String messageId, String scope) =>
      _remote.deleteMessage(conversationId, messageId, scope);

  @override
  void sendTyping(String conversationId, bool isTyping) =>
      _remote.sendTyping(conversationId, isTyping);

  @override
  void sendCallInvite(String conversationId, String roomName) =>
      _remote.sendCallInvite(conversationId, roomName);

  @override
  Stream<MessageEntity> get messageStream => _remote.messageStream;

  @override
  Stream<Map<String, dynamic>> get callInviteStream => _remote.callInviteStream;

  @override
  Stream<Map<String, dynamic>> get messageUpdatedStream => _remote.messageUpdatedStream;

  @override
  Stream<Map<String, dynamic>> get messageDeletedStream => _remote.messageDeletedStream;

  @override
  Stream<Map<String, dynamic>> get messagesReadStream => _remote.messagesReadStream;

  @override
  void markRead(String conversationId) => _remote.markRead(conversationId);

  // Group methods
  @override
  Future<ConversationEntity> createGroupConversation(String name, List<String> participantIds) =>
      _remote.createGroupConversation(name, participantIds);

  @override
  Future<List<GroupMemberEntity>> getGroupMembers(String conversationId) =>
      _remote.getGroupMembers(conversationId);

  @override
  Future<void> addGroupMembers(String conversationId, List<String> userIds) =>
      _remote.addGroupMembers(conversationId, userIds);

  @override
  Future<void> removeGroupMember(String conversationId, String userId) =>
      _remote.removeGroupMember(conversationId, userId);

  @override
  Future<void> changeGroupMemberRole(String conversationId, String userId, String role) =>
      _remote.changeGroupMemberRole(conversationId, userId, role);

  @override
  Future<void> updateGroupInfo(String conversationId, {String? name, String? avatarUrl, String? description, bool? slowMode, bool? topicsEnabled, int? autoDeleteDays}) =>
      _remote.updateGroupInfo(conversationId, name: name, avatarUrl: avatarUrl, description: description, slowMode: slowMode, topicsEnabled: topicsEnabled, autoDeleteDays: autoDeleteDays);

  @override
  Future<void> leaveGroup(String conversationId) => _remote.leaveGroup(conversationId);

  @override
  Future<void> deleteGroup(String conversationId) => _remote.deleteGroup(conversationId);

  // Group streams
  @override
  Stream<Map<String, dynamic>> get groupUpdatedStream => _remote.groupUpdatedStream;
  @override
  Stream<Map<String, dynamic>> get groupMemberAddedStream => _remote.groupMemberAddedStream;
  @override
  Stream<Map<String, dynamic>> get groupMemberRemovedStream => _remote.groupMemberRemovedStream;
  @override
  Stream<Map<String, dynamic>> get groupRoleChangedStream => _remote.groupRoleChangedStream;
  @override
  Stream<Map<String, dynamic>> get groupCreatedStream => _remote.groupCreatedStream;
  @override
  Stream<Map<String, dynamic>> get groupDeletedStream => _remote.groupDeletedStream;

  // Group call streams
  @override
  Stream<Map<String, dynamic>> get groupCallStartedStream => _remote.groupCallStartedStream;
  @override
  Stream<Map<String, dynamic>> get groupCallEndedStream => _remote.groupCallEndedStream;

  // Typing stream
  @override
  Stream<Map<String, dynamic>> get typingStream => _remote.typingStream;

  // Contact requests
  @override
  Future<Map<String, dynamic>> sendContactRequest(String receiverId) => _remote.sendContactRequest(receiverId);
  @override
  Future<List<Map<String, dynamic>>> getContactRequests() => _remote.getContactRequests();
  @override
  Future<Map<String, dynamic>> acceptContactRequest(String requestId) => _remote.acceptContactRequest(requestId);
  @override
  Future<void> rejectContactRequest(String requestId) => _remote.rejectContactRequest(requestId);
  @override
  Future<List<Map<String, dynamic>>> getSentContactRequests() => _remote.getSentContactRequests();
  @override
  Stream<Map<String, dynamic>> get contactRequestStream => _remote.contactRequestStream;
  @override
  Stream<Map<String, dynamic>> get contactAcceptedStream => _remote.contactAcceptedStream;

  // Reaction methods
  @override
  void reactToMessage(String conversationId, String messageId, String emoji) =>
      _remote.reactToMessage(conversationId, messageId, emoji);
  @override
  Stream<Map<String, dynamic>> get reactionUpdatedStream => _remote.reactionUpdatedStream;
  @override
  Stream<String> get socketErrorStream => _remote.socketErrorStream;

  // Mute methods
  @override
  Future<Map<String, dynamic>> muteConversation(String conversationId, {int? durationMinutes}) =>
      _remote.muteConversation(conversationId, durationMinutes: durationMinutes);

  @override
  Future<void> unmuteConversation(String conversationId) =>
      _remote.unmuteConversation(conversationId);

  @override
  void dispose() => _remote.dispose();
}

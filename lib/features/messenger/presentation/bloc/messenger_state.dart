import 'package:equatable/equatable.dart';
import '../../domain/entities/conversation_entity.dart';
import '../../domain/entities/message_entity.dart';
import '../../domain/entities/user_search_entity.dart';
import '../../domain/entities/group_member_entity.dart';

class MessengerState extends Equatable {
  final List<ConversationEntity> conversations;
  final Map<String, List<MessageEntity>> messages;
  final Map<String, String?> nextCursors;
  final List<UserSearchEntity> searchResults;
  final bool isLoading;
  final bool isConnected;
  final String? error;
  final String? newConversationId;
  final String? currentUserId;
  final Map<String, dynamic>? pendingCallInvite;
  final Map<String, List<GroupMemberEntity>> groupMembers;
  final Map<String, String> activeGroupCalls; // conversationId → roomName
  final Map<String, Map<String, String>> typingUsers; // conversationId → {userId: userName}
  final List<Map<String, dynamic>> contactRequests;
  final List<Map<String, dynamic>> sentContactRequests;
  final String? contactRequestSent; // receiverId if request just sent
  final int missedCallsCount;
  final int pendingCalendarInvites;
  final int pendingContactRequests;
  final String? socketError;

  const MessengerState({
    this.conversations = const [],
    this.messages = const {},
    this.nextCursors = const {},
    this.searchResults = const [],
    this.isLoading = false,
    this.isConnected = false,
    this.error,
    this.newConversationId,
    this.currentUserId,
    this.pendingCallInvite,
    this.groupMembers = const {},
    this.activeGroupCalls = const {},
    this.typingUsers = const {},
    this.contactRequests = const [],
    this.sentContactRequests = const [],
    this.contactRequestSent,
    this.missedCallsCount = 0,
    this.pendingCalendarInvites = 0,
    this.pendingContactRequests = 0,
    this.socketError,
  });

  MessengerState copyWith({
    List<ConversationEntity>? conversations,
    Map<String, List<MessageEntity>>? messages,
    Map<String, String?>? nextCursors,
    List<UserSearchEntity>? searchResults,
    bool? isLoading,
    bool? isConnected,
    String? error,
    String? newConversationId,
    String? currentUserId,
    Map<String, dynamic>? pendingCallInvite,
    Map<String, List<GroupMemberEntity>>? groupMembers,
    Map<String, String>? activeGroupCalls,
    Map<String, Map<String, String>>? typingUsers,
    List<Map<String, dynamic>>? contactRequests,
    List<Map<String, dynamic>>? sentContactRequests,
    String? contactRequestSent,
    int? missedCallsCount,
    int? pendingCalendarInvites,
    int? pendingContactRequests,
    String? socketError,
    bool clearError = false,
    bool clearNewConversation = false,
    bool clearCallInvite = false,
    bool clearContactRequestSent = false,
    bool clearSocketError = false,
  }) {
    return MessengerState(
      conversations: conversations ?? this.conversations,
      messages: messages ?? this.messages,
      nextCursors: nextCursors ?? this.nextCursors,
      searchResults: searchResults ?? this.searchResults,
      isLoading: isLoading ?? this.isLoading,
      isConnected: isConnected ?? this.isConnected,
      error: clearError ? null : (error ?? this.error),
      newConversationId: clearNewConversation
          ? null
          : (newConversationId ?? this.newConversationId),
      currentUserId: currentUserId ?? this.currentUserId,
      pendingCallInvite:
          clearCallInvite ? null : (pendingCallInvite ?? this.pendingCallInvite),
      groupMembers: groupMembers ?? this.groupMembers,
      activeGroupCalls: activeGroupCalls ?? this.activeGroupCalls,
      typingUsers: typingUsers ?? this.typingUsers,
      contactRequests: contactRequests ?? this.contactRequests,
      sentContactRequests: sentContactRequests ?? this.sentContactRequests,
      contactRequestSent: clearContactRequestSent ? null : (contactRequestSent ?? this.contactRequestSent),
      missedCallsCount: missedCallsCount ?? this.missedCallsCount,
      pendingCalendarInvites: pendingCalendarInvites ?? this.pendingCalendarInvites,
      pendingContactRequests: pendingContactRequests ?? this.pendingContactRequests,
      socketError: clearSocketError ? null : (socketError ?? this.socketError),
    );
  }

  @override
  List<Object?> get props => [
        conversations,
        messages,
        nextCursors,
        searchResults,
        isLoading,
        isConnected,
        error,
        newConversationId,
        currentUserId,
        pendingCallInvite,
        groupMembers,
        activeGroupCalls,
        typingUsers,
        contactRequests,
        sentContactRequests,
        contactRequestSent,
        missedCallsCount,
        pendingCalendarInvites,
        pendingContactRequests,
        socketError,
      ];
}

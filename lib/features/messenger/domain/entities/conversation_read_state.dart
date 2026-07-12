class ConversationReadState {
  final String conversationId;
  final DateTime? myLastReadAt;
  final int unread;
  ConversationReadState({required this.conversationId, this.myLastReadAt, required this.unread});
  factory ConversationReadState.fromJson(Map<String, dynamic> j) => ConversationReadState(
    conversationId: j['conversationId'] as String,
    myLastReadAt: j['myLastReadAt'] != null ? DateTime.parse(j['myLastReadAt'] as String) : null,
    unread: (j['unread'] as num?)?.toInt() ?? 0,
  );
}

/// A single participant's read cursor within one conversation — how far
/// (in time) that participant has read. Used to render read receipts
/// (1:1 ticks + group "Seen by N") on the current user's own messages.
class ParticipantCursor {
  final String userId;
  final DateTime? lastReadAt;
  ParticipantCursor({required this.userId, this.lastReadAt});
  factory ParticipantCursor.fromJson(Map<String, dynamic> j) => ParticipantCursor(
    userId: j['userId'] as String,
    lastReadAt: j['lastReadAt'] != null ? DateTime.parse(j['lastReadAt'] as String) : null,
  );
}

/// Parses the raw `[{userId, lastReadAt, lastReadMessageId}]` list returned
/// by `MessengerRemoteDataSource.fetchConversationReadState` into cursors.
List<ParticipantCursor> parseParticipantCursors(List<Map<String, dynamic>> raw) =>
    raw.map((e) => ParticipantCursor.fromJson(e)).toList();

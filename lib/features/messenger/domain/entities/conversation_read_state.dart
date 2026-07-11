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

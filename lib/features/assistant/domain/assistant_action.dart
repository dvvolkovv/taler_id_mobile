enum AssistantActionType {
  messageSent('message_sent'),
  eventCreated('event_created'),
  analystReply('analyst_reply'),
  callMade('call_made'),
  contactAdded('contact_added'),
  channelPost('channel_post');

  const AssistantActionType(this.wire);
  final String wire;

  static AssistantActionType? fromWire(String? v) {
    for (final t in values) {
      if (t.wire == v) return t;
    }
    return null;
  }
}

class AssistantAction {
  const AssistantAction({
    required this.type,
    required this.entityId,
    required this.title,
    this.conversationId,
  });

  final AssistantActionType type;
  final String entityId;
  final String title;
  final String? conversationId;

  static AssistantAction? fromMetadata(Map<String, dynamic>? metadata) {
    final raw = metadata?['action'];
    if (raw is! Map) return null;
    final type = AssistantActionType.fromWire(raw['type'] as String?);
    final entityId = raw['entityId'] as String?;
    final title = raw['title'] as String?;
    if (type == null || entityId == null || title == null) return null;
    return AssistantAction(
      type: type,
      entityId: entityId,
      title: title,
      conversationId: raw['conversationId'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'type': type.wire,
        'entityId': entityId,
        'title': title,
        if (conversationId != null) 'conversationId': conversationId,
      };

  @override
  bool operator ==(Object other) =>
      other is AssistantAction &&
      other.type == type &&
      other.entityId == entityId &&
      other.title == title &&
      other.conversationId == conversationId;

  @override
  int get hashCode => Object.hash(type, entityId, title, conversationId);
}

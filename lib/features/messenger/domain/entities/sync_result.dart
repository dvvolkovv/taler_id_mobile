import 'message_entity.dart';

class SyncResult {
  final List<MessageEntity> messages;
  final String? nextCursor;
  final bool hasMore;

  const SyncResult({
    required this.messages,
    required this.nextCursor,
    required this.hasMore,
  });

  factory SyncResult.fromJson(Map<String, dynamic> json) {
    final raw = (json['messages'] as List?) ?? const [];
    return SyncResult(
      messages: raw
          .map((e) => MessageEntity.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      nextCursor: json['nextCursor'] as String?,
      hasMore: (json['hasMore'] as bool?) ?? false,
    );
  }
}

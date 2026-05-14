// lib/features/contacts/domain/entities/contact_item_entity.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'contact_item_entity.freezed.dart';
part 'contact_item_entity.g.dart';

enum ContactStatus {
  @JsonValue('incoming') incoming,
  @JsonValue('accepted') accepted,
  @JsonValue('pending') pending,
}

@freezed
class ContactItemEntity with _$ContactItemEntity {
  const factory ContactItemEntity({
    required String userId,
    required String name,
    String? username,
    String? avatarUrl,
    required ContactStatus status,
    String? conversationId,
    String? requestId,
    DateTime? requestSentAt,
    @Default(false) bool localPending,
  }) = _ContactItemEntity;

  factory ContactItemEntity.fromJson(Map<String, dynamic> json) =>
      _$ContactItemEntityFromJson(json);
}

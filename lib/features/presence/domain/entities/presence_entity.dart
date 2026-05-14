import 'package:freezed_annotation/freezed_annotation.dart';

part 'presence_entity.freezed.dart';

/// One target user's presence as returned by `GET /presence/:userId`.
///
/// [isOnline] is three-valued: `true` (active heartbeat within ~90 s),
/// `false` (offline), or `null` (hidden by privacy — paired with [hidden]).
///
/// [lastSeenAt] is `null` either when the target has never been seen, or
/// when [hidden] is true and the server is intentionally not disclosing it.
@freezed
class PresenceEntity with _$PresenceEntity {
  const factory PresenceEntity({
    required bool? isOnline,
    required DateTime? lastSeenAt,
    required bool hidden,
  }) = _PresenceEntity;

  factory PresenceEntity.fromJson(Map<String, dynamic> json) {
    return PresenceEntity(
      isOnline: json['isOnline'] as bool?,
      lastSeenAt: json['lastSeenAt'] != null
          ? DateTime.parse(json['lastSeenAt'] as String).toUtc()
          : null,
      hidden: (json['hidden'] as bool?) ?? false,
    );
  }
}

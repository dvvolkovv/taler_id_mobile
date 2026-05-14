import 'package:freezed_annotation/freezed_annotation.dart';

part 'presence_entity.freezed.dart';

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

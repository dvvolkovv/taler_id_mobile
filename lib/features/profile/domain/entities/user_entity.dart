import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_entity.freezed.dart';
part 'user_entity.g.dart';

enum KycStatus {
  @JsonValue('UNVERIFIED') unverified,
  @JsonValue('PENDING') pending,
  @JsonValue('VERIFIED') verified,
  @JsonValue('REJECTED') rejected,
}

@freezed
class AvailableBots with _$AvailableBots {
  const factory AvailableBots({
    @Default(true) bool analyst,
    @Default(true) bool outbound,
    @Default(false) bool informer,
  }) = _AvailableBots;

  factory AvailableBots.fromJson(Map<String, dynamic> json) =>
      _$AvailableBotsFromJson(json);
}

@freezed
class UserEntity with _$UserEntity {
  const factory UserEntity({
    required String id,
    required String email,
    String? phone,
    String? firstName,
    String? lastName,
    String? middleName,
    String? country,
    String? avatarUrl,
    String? postalCode,
    String? dateOfBirth,
    @Default(KycStatus.unverified) KycStatus kycStatus,
    @Default(false) bool emailVerified,
    String? fcmToken,
    String? username,
    String? status,
    @Default(false) bool aiTwinEnabled,
    @Default(30) int aiTwinTimeoutSeconds,
    String? aiTwinPrompt,
    String? aiTwinVoiceId,
    @Default('EVERYONE') String lastSeenPrivacy,
    @Default(AvailableBots()) AvailableBots availableBots,
  }) = _UserEntity;

  factory UserEntity.fromJson(Map<String, dynamic> json) =>
      _$UserEntityFromJson(json);
}

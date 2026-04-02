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
    String? fcmToken,
    String? username,
    String? status,
  }) = _UserEntity;

  factory UserEntity.fromJson(Map<String, dynamic> json) =>
      _$UserEntityFromJson(json);
}

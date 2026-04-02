// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_entity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$UserEntityImpl _$$UserEntityImplFromJson(Map<String, dynamic> json) =>
    _$UserEntityImpl(
      id: json['id'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String?,
      firstName: json['firstName'] as String?,
      lastName: json['lastName'] as String?,
      middleName: json['middleName'] as String?,
      country: json['country'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      postalCode: json['postalCode'] as String?,
      dateOfBirth: json['dateOfBirth'] as String?,
      kycStatus: $enumDecodeNullable(_$KycStatusEnumMap, json['kycStatus']) ??
          KycStatus.unverified,
      fcmToken: json['fcmToken'] as String?,
      username: json['username'] as String?,
      status: json['status'] as String?,
    );

Map<String, dynamic> _$$UserEntityImplToJson(_$UserEntityImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'email': instance.email,
      'phone': instance.phone,
      'firstName': instance.firstName,
      'lastName': instance.lastName,
      'middleName': instance.middleName,
      'country': instance.country,
      'avatarUrl': instance.avatarUrl,
      'postalCode': instance.postalCode,
      'dateOfBirth': instance.dateOfBirth,
      'kycStatus': _$KycStatusEnumMap[instance.kycStatus]!,
      'fcmToken': instance.fcmToken,
      'username': instance.username,
      'status': instance.status,
    };

const _$KycStatusEnumMap = {
  KycStatus.unverified: 'UNVERIFIED',
  KycStatus.pending: 'PENDING',
  KycStatus.verified: 'VERIFIED',
  KycStatus.rejected: 'REJECTED',
};

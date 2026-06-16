// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_entity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$AvailableBotsImpl _$$AvailableBotsImplFromJson(Map<String, dynamic> json) =>
    _$AvailableBotsImpl(
      analyst: json['analyst'] as bool? ?? true,
      outbound: json['outbound'] as bool? ?? true,
      informer: json['informer'] as bool? ?? false,
    );

Map<String, dynamic> _$$AvailableBotsImplToJson(_$AvailableBotsImpl instance) =>
    <String, dynamic>{
      'analyst': instance.analyst,
      'outbound': instance.outbound,
      'informer': instance.informer,
    };

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
      emailVerified: json['emailVerified'] as bool? ?? false,
      fcmToken: json['fcmToken'] as String?,
      username: json['username'] as String?,
      status: json['status'] as String?,
      aiTwinEnabled: json['aiTwinEnabled'] as bool? ?? false,
      aiTwinTimeoutSeconds:
          (json['aiTwinTimeoutSeconds'] as num?)?.toInt() ?? 30,
      aiTwinPrompt: json['aiTwinPrompt'] as String?,
      aiTwinVoiceId: json['aiTwinVoiceId'] as String?,
      lastSeenPrivacy: json['lastSeenPrivacy'] as String? ?? 'EVERYONE',
      availableBots: json['availableBots'] == null
          ? const AvailableBots()
          : AvailableBots.fromJson(
              json['availableBots'] as Map<String, dynamic>),
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
      'emailVerified': instance.emailVerified,
      'fcmToken': instance.fcmToken,
      'username': instance.username,
      'status': instance.status,
      'aiTwinEnabled': instance.aiTwinEnabled,
      'aiTwinTimeoutSeconds': instance.aiTwinTimeoutSeconds,
      'aiTwinPrompt': instance.aiTwinPrompt,
      'aiTwinVoiceId': instance.aiTwinVoiceId,
      'lastSeenPrivacy': instance.lastSeenPrivacy,
      'availableBots': instance.availableBots,
    };

const _$KycStatusEnumMap = {
  KycStatus.unverified: 'UNVERIFIED',
  KycStatus.pending: 'PENDING',
  KycStatus.verified: 'VERIFIED',
  KycStatus.rejected: 'REJECTED',
};

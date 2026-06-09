// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'owner_voice_status.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$OwnerVoiceStatusImpl _$$OwnerVoiceStatusImplFromJson(
        Map<String, dynamic> json) =>
    _$OwnerVoiceStatusImpl(
      enrolled: json['enrolled'] as bool,
      speakerId: json['speakerId'] as String?,
      enrolledAt: json['enrolledAt'] == null
          ? null
          : DateTime.parse(json['enrolledAt'] as String),
    );

Map<String, dynamic> _$$OwnerVoiceStatusImplToJson(
        _$OwnerVoiceStatusImpl instance) =>
    <String, dynamic>{
      'enrolled': instance.enrolled,
      'speakerId': instance.speakerId,
      'enrolledAt': instance.enrolledAt?.toIso8601String(),
    };

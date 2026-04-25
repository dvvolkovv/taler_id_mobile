// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'feature_toggle_entity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$FeatureToggleEntityImpl _$$FeatureToggleEntityImplFromJson(
        Map<String, dynamic> json) =>
    _$FeatureToggleEntityImpl(
      featureKey: json['featureKey'] as String,
      enabled: json['enabled'] as bool,
    );

Map<String, dynamic> _$$FeatureToggleEntityImplToJson(
        _$FeatureToggleEntityImpl instance) =>
    <String, dynamic>{
      'featureKey': instance.featureKey,
      'enabled': instance.enabled,
    };

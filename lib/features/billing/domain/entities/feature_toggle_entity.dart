import 'package:freezed_annotation/freezed_annotation.dart';

part 'feature_toggle_entity.freezed.dart';
part 'feature_toggle_entity.g.dart';

@freezed
class FeatureToggleEntity with _$FeatureToggleEntity {
  const factory FeatureToggleEntity({
    required String featureKey,
    required bool enabled,
  }) = _FeatureToggleEntity;

  factory FeatureToggleEntity.fromJson(Map<String, dynamic> json) =>
      _$FeatureToggleEntityFromJson(json);
}

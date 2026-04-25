// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'feature_toggle_entity.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

FeatureToggleEntity _$FeatureToggleEntityFromJson(Map<String, dynamic> json) {
  return _FeatureToggleEntity.fromJson(json);
}

/// @nodoc
mixin _$FeatureToggleEntity {
  String get featureKey => throw _privateConstructorUsedError;
  bool get enabled => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $FeatureToggleEntityCopyWith<FeatureToggleEntity> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $FeatureToggleEntityCopyWith<$Res> {
  factory $FeatureToggleEntityCopyWith(
          FeatureToggleEntity value, $Res Function(FeatureToggleEntity) then) =
      _$FeatureToggleEntityCopyWithImpl<$Res, FeatureToggleEntity>;
  @useResult
  $Res call({String featureKey, bool enabled});
}

/// @nodoc
class _$FeatureToggleEntityCopyWithImpl<$Res, $Val extends FeatureToggleEntity>
    implements $FeatureToggleEntityCopyWith<$Res> {
  _$FeatureToggleEntityCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? featureKey = null,
    Object? enabled = null,
  }) {
    return _then(_value.copyWith(
      featureKey: null == featureKey
          ? _value.featureKey
          : featureKey // ignore: cast_nullable_to_non_nullable
              as String,
      enabled: null == enabled
          ? _value.enabled
          : enabled // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$FeatureToggleEntityImplCopyWith<$Res>
    implements $FeatureToggleEntityCopyWith<$Res> {
  factory _$$FeatureToggleEntityImplCopyWith(_$FeatureToggleEntityImpl value,
          $Res Function(_$FeatureToggleEntityImpl) then) =
      __$$FeatureToggleEntityImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String featureKey, bool enabled});
}

/// @nodoc
class __$$FeatureToggleEntityImplCopyWithImpl<$Res>
    extends _$FeatureToggleEntityCopyWithImpl<$Res, _$FeatureToggleEntityImpl>
    implements _$$FeatureToggleEntityImplCopyWith<$Res> {
  __$$FeatureToggleEntityImplCopyWithImpl(_$FeatureToggleEntityImpl _value,
      $Res Function(_$FeatureToggleEntityImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? featureKey = null,
    Object? enabled = null,
  }) {
    return _then(_$FeatureToggleEntityImpl(
      featureKey: null == featureKey
          ? _value.featureKey
          : featureKey // ignore: cast_nullable_to_non_nullable
              as String,
      enabled: null == enabled
          ? _value.enabled
          : enabled // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$FeatureToggleEntityImpl implements _FeatureToggleEntity {
  const _$FeatureToggleEntityImpl(
      {required this.featureKey, required this.enabled});

  factory _$FeatureToggleEntityImpl.fromJson(Map<String, dynamic> json) =>
      _$$FeatureToggleEntityImplFromJson(json);

  @override
  final String featureKey;
  @override
  final bool enabled;

  @override
  String toString() {
    return 'FeatureToggleEntity(featureKey: $featureKey, enabled: $enabled)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$FeatureToggleEntityImpl &&
            (identical(other.featureKey, featureKey) ||
                other.featureKey == featureKey) &&
            (identical(other.enabled, enabled) || other.enabled == enabled));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, featureKey, enabled);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$FeatureToggleEntityImplCopyWith<_$FeatureToggleEntityImpl> get copyWith =>
      __$$FeatureToggleEntityImplCopyWithImpl<_$FeatureToggleEntityImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$FeatureToggleEntityImplToJson(
      this,
    );
  }
}

abstract class _FeatureToggleEntity implements FeatureToggleEntity {
  const factory _FeatureToggleEntity(
      {required final String featureKey,
      required final bool enabled}) = _$FeatureToggleEntityImpl;

  factory _FeatureToggleEntity.fromJson(Map<String, dynamic> json) =
      _$FeatureToggleEntityImpl.fromJson;

  @override
  String get featureKey;
  @override
  bool get enabled;
  @override
  @JsonKey(ignore: true)
  _$$FeatureToggleEntityImplCopyWith<_$FeatureToggleEntityImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

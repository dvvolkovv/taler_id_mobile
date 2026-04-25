// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'pricebook_item_entity.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

PricebookItemEntity _$PricebookItemEntityFromJson(Map<String, dynamic> json) {
  return _PricebookItemEntity.fromJson(json);
}

/// @nodoc
mixin _$PricebookItemEntity {
  String get featureKey => throw _privateConstructorUsedError;
  String get unit => throw _privateConstructorUsedError;
  String get costUsdPerUnit => throw _privateConstructorUsedError;
  String get markupMultiplier => throw _privateConstructorUsedError;
  String get minReservePlanck => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $PricebookItemEntityCopyWith<PricebookItemEntity> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PricebookItemEntityCopyWith<$Res> {
  factory $PricebookItemEntityCopyWith(
          PricebookItemEntity value, $Res Function(PricebookItemEntity) then) =
      _$PricebookItemEntityCopyWithImpl<$Res, PricebookItemEntity>;
  @useResult
  $Res call(
      {String featureKey,
      String unit,
      String costUsdPerUnit,
      String markupMultiplier,
      String minReservePlanck});
}

/// @nodoc
class _$PricebookItemEntityCopyWithImpl<$Res, $Val extends PricebookItemEntity>
    implements $PricebookItemEntityCopyWith<$Res> {
  _$PricebookItemEntityCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? featureKey = null,
    Object? unit = null,
    Object? costUsdPerUnit = null,
    Object? markupMultiplier = null,
    Object? minReservePlanck = null,
  }) {
    return _then(_value.copyWith(
      featureKey: null == featureKey
          ? _value.featureKey
          : featureKey // ignore: cast_nullable_to_non_nullable
              as String,
      unit: null == unit
          ? _value.unit
          : unit // ignore: cast_nullable_to_non_nullable
              as String,
      costUsdPerUnit: null == costUsdPerUnit
          ? _value.costUsdPerUnit
          : costUsdPerUnit // ignore: cast_nullable_to_non_nullable
              as String,
      markupMultiplier: null == markupMultiplier
          ? _value.markupMultiplier
          : markupMultiplier // ignore: cast_nullable_to_non_nullable
              as String,
      minReservePlanck: null == minReservePlanck
          ? _value.minReservePlanck
          : minReservePlanck // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$PricebookItemEntityImplCopyWith<$Res>
    implements $PricebookItemEntityCopyWith<$Res> {
  factory _$$PricebookItemEntityImplCopyWith(_$PricebookItemEntityImpl value,
          $Res Function(_$PricebookItemEntityImpl) then) =
      __$$PricebookItemEntityImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String featureKey,
      String unit,
      String costUsdPerUnit,
      String markupMultiplier,
      String minReservePlanck});
}

/// @nodoc
class __$$PricebookItemEntityImplCopyWithImpl<$Res>
    extends _$PricebookItemEntityCopyWithImpl<$Res, _$PricebookItemEntityImpl>
    implements _$$PricebookItemEntityImplCopyWith<$Res> {
  __$$PricebookItemEntityImplCopyWithImpl(_$PricebookItemEntityImpl _value,
      $Res Function(_$PricebookItemEntityImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? featureKey = null,
    Object? unit = null,
    Object? costUsdPerUnit = null,
    Object? markupMultiplier = null,
    Object? minReservePlanck = null,
  }) {
    return _then(_$PricebookItemEntityImpl(
      featureKey: null == featureKey
          ? _value.featureKey
          : featureKey // ignore: cast_nullable_to_non_nullable
              as String,
      unit: null == unit
          ? _value.unit
          : unit // ignore: cast_nullable_to_non_nullable
              as String,
      costUsdPerUnit: null == costUsdPerUnit
          ? _value.costUsdPerUnit
          : costUsdPerUnit // ignore: cast_nullable_to_non_nullable
              as String,
      markupMultiplier: null == markupMultiplier
          ? _value.markupMultiplier
          : markupMultiplier // ignore: cast_nullable_to_non_nullable
              as String,
      minReservePlanck: null == minReservePlanck
          ? _value.minReservePlanck
          : minReservePlanck // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$PricebookItemEntityImpl implements _PricebookItemEntity {
  const _$PricebookItemEntityImpl(
      {required this.featureKey,
      required this.unit,
      required this.costUsdPerUnit,
      required this.markupMultiplier,
      required this.minReservePlanck});

  factory _$PricebookItemEntityImpl.fromJson(Map<String, dynamic> json) =>
      _$$PricebookItemEntityImplFromJson(json);

  @override
  final String featureKey;
  @override
  final String unit;
  @override
  final String costUsdPerUnit;
  @override
  final String markupMultiplier;
  @override
  final String minReservePlanck;

  @override
  String toString() {
    return 'PricebookItemEntity(featureKey: $featureKey, unit: $unit, costUsdPerUnit: $costUsdPerUnit, markupMultiplier: $markupMultiplier, minReservePlanck: $minReservePlanck)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PricebookItemEntityImpl &&
            (identical(other.featureKey, featureKey) ||
                other.featureKey == featureKey) &&
            (identical(other.unit, unit) || other.unit == unit) &&
            (identical(other.costUsdPerUnit, costUsdPerUnit) ||
                other.costUsdPerUnit == costUsdPerUnit) &&
            (identical(other.markupMultiplier, markupMultiplier) ||
                other.markupMultiplier == markupMultiplier) &&
            (identical(other.minReservePlanck, minReservePlanck) ||
                other.minReservePlanck == minReservePlanck));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, featureKey, unit, costUsdPerUnit,
      markupMultiplier, minReservePlanck);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$PricebookItemEntityImplCopyWith<_$PricebookItemEntityImpl> get copyWith =>
      __$$PricebookItemEntityImplCopyWithImpl<_$PricebookItemEntityImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PricebookItemEntityImplToJson(
      this,
    );
  }
}

abstract class _PricebookItemEntity implements PricebookItemEntity {
  const factory _PricebookItemEntity(
      {required final String featureKey,
      required final String unit,
      required final String costUsdPerUnit,
      required final String markupMultiplier,
      required final String minReservePlanck}) = _$PricebookItemEntityImpl;

  factory _PricebookItemEntity.fromJson(Map<String, dynamic> json) =
      _$PricebookItemEntityImpl.fromJson;

  @override
  String get featureKey;
  @override
  String get unit;
  @override
  String get costUsdPerUnit;
  @override
  String get markupMultiplier;
  @override
  String get minReservePlanck;
  @override
  @JsonKey(ignore: true)
  _$$PricebookItemEntityImplCopyWith<_$PricebookItemEntityImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

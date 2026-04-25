// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'billing_package_entity.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

BillingPackageEntity _$BillingPackageEntityFromJson(Map<String, dynamic> json) {
  return _BillingPackageEntity.fromJson(json);
}

/// @nodoc
mixin _$BillingPackageEntity {
  String get id => throw _privateConstructorUsedError;
  String get amountPlanck => throw _privateConstructorUsedError;
  int get priceEurCents => throw _privateConstructorUsedError;
  Map<String, String> get label => throw _privateConstructorUsedError;
  Map<String, List<String>> get highlights =>
      throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $BillingPackageEntityCopyWith<BillingPackageEntity> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $BillingPackageEntityCopyWith<$Res> {
  factory $BillingPackageEntityCopyWith(BillingPackageEntity value,
          $Res Function(BillingPackageEntity) then) =
      _$BillingPackageEntityCopyWithImpl<$Res, BillingPackageEntity>;
  @useResult
  $Res call(
      {String id,
      String amountPlanck,
      int priceEurCents,
      Map<String, String> label,
      Map<String, List<String>> highlights});
}

/// @nodoc
class _$BillingPackageEntityCopyWithImpl<$Res,
        $Val extends BillingPackageEntity>
    implements $BillingPackageEntityCopyWith<$Res> {
  _$BillingPackageEntityCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? amountPlanck = null,
    Object? priceEurCents = null,
    Object? label = null,
    Object? highlights = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      amountPlanck: null == amountPlanck
          ? _value.amountPlanck
          : amountPlanck // ignore: cast_nullable_to_non_nullable
              as String,
      priceEurCents: null == priceEurCents
          ? _value.priceEurCents
          : priceEurCents // ignore: cast_nullable_to_non_nullable
              as int,
      label: null == label
          ? _value.label
          : label // ignore: cast_nullable_to_non_nullable
              as Map<String, String>,
      highlights: null == highlights
          ? _value.highlights
          : highlights // ignore: cast_nullable_to_non_nullable
              as Map<String, List<String>>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$BillingPackageEntityImplCopyWith<$Res>
    implements $BillingPackageEntityCopyWith<$Res> {
  factory _$$BillingPackageEntityImplCopyWith(_$BillingPackageEntityImpl value,
          $Res Function(_$BillingPackageEntityImpl) then) =
      __$$BillingPackageEntityImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String amountPlanck,
      int priceEurCents,
      Map<String, String> label,
      Map<String, List<String>> highlights});
}

/// @nodoc
class __$$BillingPackageEntityImplCopyWithImpl<$Res>
    extends _$BillingPackageEntityCopyWithImpl<$Res, _$BillingPackageEntityImpl>
    implements _$$BillingPackageEntityImplCopyWith<$Res> {
  __$$BillingPackageEntityImplCopyWithImpl(_$BillingPackageEntityImpl _value,
      $Res Function(_$BillingPackageEntityImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? amountPlanck = null,
    Object? priceEurCents = null,
    Object? label = null,
    Object? highlights = null,
  }) {
    return _then(_$BillingPackageEntityImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      amountPlanck: null == amountPlanck
          ? _value.amountPlanck
          : amountPlanck // ignore: cast_nullable_to_non_nullable
              as String,
      priceEurCents: null == priceEurCents
          ? _value.priceEurCents
          : priceEurCents // ignore: cast_nullable_to_non_nullable
              as int,
      label: null == label
          ? _value._label
          : label // ignore: cast_nullable_to_non_nullable
              as Map<String, String>,
      highlights: null == highlights
          ? _value._highlights
          : highlights // ignore: cast_nullable_to_non_nullable
              as Map<String, List<String>>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$BillingPackageEntityImpl implements _BillingPackageEntity {
  const _$BillingPackageEntityImpl(
      {required this.id,
      required this.amountPlanck,
      required this.priceEurCents,
      required final Map<String, String> label,
      required final Map<String, List<String>> highlights})
      : _label = label,
        _highlights = highlights;

  factory _$BillingPackageEntityImpl.fromJson(Map<String, dynamic> json) =>
      _$$BillingPackageEntityImplFromJson(json);

  @override
  final String id;
  @override
  final String amountPlanck;
  @override
  final int priceEurCents;
  final Map<String, String> _label;
  @override
  Map<String, String> get label {
    if (_label is EqualUnmodifiableMapView) return _label;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_label);
  }

  final Map<String, List<String>> _highlights;
  @override
  Map<String, List<String>> get highlights {
    if (_highlights is EqualUnmodifiableMapView) return _highlights;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_highlights);
  }

  @override
  String toString() {
    return 'BillingPackageEntity(id: $id, amountPlanck: $amountPlanck, priceEurCents: $priceEurCents, label: $label, highlights: $highlights)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$BillingPackageEntityImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.amountPlanck, amountPlanck) ||
                other.amountPlanck == amountPlanck) &&
            (identical(other.priceEurCents, priceEurCents) ||
                other.priceEurCents == priceEurCents) &&
            const DeepCollectionEquality().equals(other._label, _label) &&
            const DeepCollectionEquality()
                .equals(other._highlights, _highlights));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      amountPlanck,
      priceEurCents,
      const DeepCollectionEquality().hash(_label),
      const DeepCollectionEquality().hash(_highlights));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$BillingPackageEntityImplCopyWith<_$BillingPackageEntityImpl>
      get copyWith =>
          __$$BillingPackageEntityImplCopyWithImpl<_$BillingPackageEntityImpl>(
              this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$BillingPackageEntityImplToJson(
      this,
    );
  }
}

abstract class _BillingPackageEntity implements BillingPackageEntity {
  const factory _BillingPackageEntity(
          {required final String id,
          required final String amountPlanck,
          required final int priceEurCents,
          required final Map<String, String> label,
          required final Map<String, List<String>> highlights}) =
      _$BillingPackageEntityImpl;

  factory _BillingPackageEntity.fromJson(Map<String, dynamic> json) =
      _$BillingPackageEntityImpl.fromJson;

  @override
  String get id;
  @override
  String get amountPlanck;
  @override
  int get priceEurCents;
  @override
  Map<String, String> get label;
  @override
  Map<String, List<String>> get highlights;
  @override
  @JsonKey(ignore: true)
  _$$BillingPackageEntityImplCopyWith<_$BillingPackageEntityImpl>
      get copyWith => throw _privateConstructorUsedError;
}

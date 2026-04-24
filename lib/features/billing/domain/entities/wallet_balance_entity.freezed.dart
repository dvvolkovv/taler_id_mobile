// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'wallet_balance_entity.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

WalletBalanceEntity _$WalletBalanceEntityFromJson(Map<String, dynamic> json) {
  return _WalletBalanceEntity.fromJson(json);
}

/// @nodoc
mixin _$WalletBalanceEntity {
  String get balancePlanck => throw _privateConstructorUsedError;
  String get balanceMicroTal => throw _privateConstructorUsedError;
  String? get custodialAddress => throw _privateConstructorUsedError;
  List<BillingTransactionEntity> get recentTx =>
      throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $WalletBalanceEntityCopyWith<WalletBalanceEntity> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $WalletBalanceEntityCopyWith<$Res> {
  factory $WalletBalanceEntityCopyWith(
          WalletBalanceEntity value, $Res Function(WalletBalanceEntity) then) =
      _$WalletBalanceEntityCopyWithImpl<$Res, WalletBalanceEntity>;
  @useResult
  $Res call(
      {String balancePlanck,
      String balanceMicroTal,
      String? custodialAddress,
      List<BillingTransactionEntity> recentTx});
}

/// @nodoc
class _$WalletBalanceEntityCopyWithImpl<$Res, $Val extends WalletBalanceEntity>
    implements $WalletBalanceEntityCopyWith<$Res> {
  _$WalletBalanceEntityCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? balancePlanck = null,
    Object? balanceMicroTal = null,
    Object? custodialAddress = freezed,
    Object? recentTx = null,
  }) {
    return _then(_value.copyWith(
      balancePlanck: null == balancePlanck
          ? _value.balancePlanck
          : balancePlanck // ignore: cast_nullable_to_non_nullable
              as String,
      balanceMicroTal: null == balanceMicroTal
          ? _value.balanceMicroTal
          : balanceMicroTal // ignore: cast_nullable_to_non_nullable
              as String,
      custodialAddress: freezed == custodialAddress
          ? _value.custodialAddress
          : custodialAddress // ignore: cast_nullable_to_non_nullable
              as String?,
      recentTx: null == recentTx
          ? _value.recentTx
          : recentTx // ignore: cast_nullable_to_non_nullable
              as List<BillingTransactionEntity>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$WalletBalanceEntityImplCopyWith<$Res>
    implements $WalletBalanceEntityCopyWith<$Res> {
  factory _$$WalletBalanceEntityImplCopyWith(_$WalletBalanceEntityImpl value,
          $Res Function(_$WalletBalanceEntityImpl) then) =
      __$$WalletBalanceEntityImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String balancePlanck,
      String balanceMicroTal,
      String? custodialAddress,
      List<BillingTransactionEntity> recentTx});
}

/// @nodoc
class __$$WalletBalanceEntityImplCopyWithImpl<$Res>
    extends _$WalletBalanceEntityCopyWithImpl<$Res, _$WalletBalanceEntityImpl>
    implements _$$WalletBalanceEntityImplCopyWith<$Res> {
  __$$WalletBalanceEntityImplCopyWithImpl(_$WalletBalanceEntityImpl _value,
      $Res Function(_$WalletBalanceEntityImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? balancePlanck = null,
    Object? balanceMicroTal = null,
    Object? custodialAddress = freezed,
    Object? recentTx = null,
  }) {
    return _then(_$WalletBalanceEntityImpl(
      balancePlanck: null == balancePlanck
          ? _value.balancePlanck
          : balancePlanck // ignore: cast_nullable_to_non_nullable
              as String,
      balanceMicroTal: null == balanceMicroTal
          ? _value.balanceMicroTal
          : balanceMicroTal // ignore: cast_nullable_to_non_nullable
              as String,
      custodialAddress: freezed == custodialAddress
          ? _value.custodialAddress
          : custodialAddress // ignore: cast_nullable_to_non_nullable
              as String?,
      recentTx: null == recentTx
          ? _value._recentTx
          : recentTx // ignore: cast_nullable_to_non_nullable
              as List<BillingTransactionEntity>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$WalletBalanceEntityImpl implements _WalletBalanceEntity {
  const _$WalletBalanceEntityImpl(
      {required this.balancePlanck,
      required this.balanceMicroTal,
      this.custodialAddress,
      final List<BillingTransactionEntity> recentTx =
          const <BillingTransactionEntity>[]})
      : _recentTx = recentTx;

  factory _$WalletBalanceEntityImpl.fromJson(Map<String, dynamic> json) =>
      _$$WalletBalanceEntityImplFromJson(json);

  @override
  final String balancePlanck;
  @override
  final String balanceMicroTal;
  @override
  final String? custodialAddress;
  final List<BillingTransactionEntity> _recentTx;
  @override
  @JsonKey()
  List<BillingTransactionEntity> get recentTx {
    if (_recentTx is EqualUnmodifiableListView) return _recentTx;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_recentTx);
  }

  @override
  String toString() {
    return 'WalletBalanceEntity(balancePlanck: $balancePlanck, balanceMicroTal: $balanceMicroTal, custodialAddress: $custodialAddress, recentTx: $recentTx)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$WalletBalanceEntityImpl &&
            (identical(other.balancePlanck, balancePlanck) ||
                other.balancePlanck == balancePlanck) &&
            (identical(other.balanceMicroTal, balanceMicroTal) ||
                other.balanceMicroTal == balanceMicroTal) &&
            (identical(other.custodialAddress, custodialAddress) ||
                other.custodialAddress == custodialAddress) &&
            const DeepCollectionEquality().equals(other._recentTx, _recentTx));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, balancePlanck, balanceMicroTal,
      custodialAddress, const DeepCollectionEquality().hash(_recentTx));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$WalletBalanceEntityImplCopyWith<_$WalletBalanceEntityImpl> get copyWith =>
      __$$WalletBalanceEntityImplCopyWithImpl<_$WalletBalanceEntityImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$WalletBalanceEntityImplToJson(
      this,
    );
  }
}

abstract class _WalletBalanceEntity implements WalletBalanceEntity {
  const factory _WalletBalanceEntity(
          {required final String balancePlanck,
          required final String balanceMicroTal,
          final String? custodialAddress,
          final List<BillingTransactionEntity> recentTx}) =
      _$WalletBalanceEntityImpl;

  factory _WalletBalanceEntity.fromJson(Map<String, dynamic> json) =
      _$WalletBalanceEntityImpl.fromJson;

  @override
  String get balancePlanck;
  @override
  String get balanceMicroTal;
  @override
  String? get custodialAddress;
  @override
  List<BillingTransactionEntity> get recentTx;
  @override
  @JsonKey(ignore: true)
  _$$WalletBalanceEntityImplCopyWith<_$WalletBalanceEntityImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'billing_transaction_entity.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

BillingTransactionEntity _$BillingTransactionEntityFromJson(
    Map<String, dynamic> json) {
  return _BillingTransactionEntity.fromJson(json);
}

/// @nodoc
mixin _$BillingTransactionEntity {
  String get id => throw _privateConstructorUsedError;
  String get type => throw _privateConstructorUsedError;
  String get amountPlanck => throw _privateConstructorUsedError;
  String? get featureKey => throw _privateConstructorUsedError;
  String? get sessionId => throw _privateConstructorUsedError;
  String get createdAt => throw _privateConstructorUsedError;
  String get status => throw _privateConstructorUsedError;
  Map<String, dynamic>? get metadata => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $BillingTransactionEntityCopyWith<BillingTransactionEntity> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $BillingTransactionEntityCopyWith<$Res> {
  factory $BillingTransactionEntityCopyWith(BillingTransactionEntity value,
          $Res Function(BillingTransactionEntity) then) =
      _$BillingTransactionEntityCopyWithImpl<$Res, BillingTransactionEntity>;
  @useResult
  $Res call(
      {String id,
      String type,
      String amountPlanck,
      String? featureKey,
      String? sessionId,
      String createdAt,
      String status,
      Map<String, dynamic>? metadata});
}

/// @nodoc
class _$BillingTransactionEntityCopyWithImpl<$Res,
        $Val extends BillingTransactionEntity>
    implements $BillingTransactionEntityCopyWith<$Res> {
  _$BillingTransactionEntityCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? type = null,
    Object? amountPlanck = null,
    Object? featureKey = freezed,
    Object? sessionId = freezed,
    Object? createdAt = null,
    Object? status = null,
    Object? metadata = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as String,
      amountPlanck: null == amountPlanck
          ? _value.amountPlanck
          : amountPlanck // ignore: cast_nullable_to_non_nullable
              as String,
      featureKey: freezed == featureKey
          ? _value.featureKey
          : featureKey // ignore: cast_nullable_to_non_nullable
              as String?,
      sessionId: freezed == sessionId
          ? _value.sessionId
          : sessionId // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as String,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      metadata: freezed == metadata
          ? _value.metadata
          : metadata // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$BillingTransactionEntityImplCopyWith<$Res>
    implements $BillingTransactionEntityCopyWith<$Res> {
  factory _$$BillingTransactionEntityImplCopyWith(
          _$BillingTransactionEntityImpl value,
          $Res Function(_$BillingTransactionEntityImpl) then) =
      __$$BillingTransactionEntityImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String type,
      String amountPlanck,
      String? featureKey,
      String? sessionId,
      String createdAt,
      String status,
      Map<String, dynamic>? metadata});
}

/// @nodoc
class __$$BillingTransactionEntityImplCopyWithImpl<$Res>
    extends _$BillingTransactionEntityCopyWithImpl<$Res,
        _$BillingTransactionEntityImpl>
    implements _$$BillingTransactionEntityImplCopyWith<$Res> {
  __$$BillingTransactionEntityImplCopyWithImpl(
      _$BillingTransactionEntityImpl _value,
      $Res Function(_$BillingTransactionEntityImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? type = null,
    Object? amountPlanck = null,
    Object? featureKey = freezed,
    Object? sessionId = freezed,
    Object? createdAt = null,
    Object? status = null,
    Object? metadata = freezed,
  }) {
    return _then(_$BillingTransactionEntityImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as String,
      amountPlanck: null == amountPlanck
          ? _value.amountPlanck
          : amountPlanck // ignore: cast_nullable_to_non_nullable
              as String,
      featureKey: freezed == featureKey
          ? _value.featureKey
          : featureKey // ignore: cast_nullable_to_non_nullable
              as String?,
      sessionId: freezed == sessionId
          ? _value.sessionId
          : sessionId // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as String,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      metadata: freezed == metadata
          ? _value._metadata
          : metadata // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$BillingTransactionEntityImpl implements _BillingTransactionEntity {
  const _$BillingTransactionEntityImpl(
      {required this.id,
      required this.type,
      required this.amountPlanck,
      this.featureKey,
      this.sessionId,
      required this.createdAt,
      this.status = 'COMPLETED',
      final Map<String, dynamic>? metadata})
      : _metadata = metadata;

  factory _$BillingTransactionEntityImpl.fromJson(Map<String, dynamic> json) =>
      _$$BillingTransactionEntityImplFromJson(json);

  @override
  final String id;
  @override
  final String type;
  @override
  final String amountPlanck;
  @override
  final String? featureKey;
  @override
  final String? sessionId;
  @override
  final String createdAt;
  @override
  @JsonKey()
  final String status;
  final Map<String, dynamic>? _metadata;
  @override
  Map<String, dynamic>? get metadata {
    final value = _metadata;
    if (value == null) return null;
    if (_metadata is EqualUnmodifiableMapView) return _metadata;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  @override
  String toString() {
    return 'BillingTransactionEntity(id: $id, type: $type, amountPlanck: $amountPlanck, featureKey: $featureKey, sessionId: $sessionId, createdAt: $createdAt, status: $status, metadata: $metadata)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$BillingTransactionEntityImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.amountPlanck, amountPlanck) ||
                other.amountPlanck == amountPlanck) &&
            (identical(other.featureKey, featureKey) ||
                other.featureKey == featureKey) &&
            (identical(other.sessionId, sessionId) ||
                other.sessionId == sessionId) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.status, status) || other.status == status) &&
            const DeepCollectionEquality().equals(other._metadata, _metadata));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      type,
      amountPlanck,
      featureKey,
      sessionId,
      createdAt,
      status,
      const DeepCollectionEquality().hash(_metadata));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$BillingTransactionEntityImplCopyWith<_$BillingTransactionEntityImpl>
      get copyWith => __$$BillingTransactionEntityImplCopyWithImpl<
          _$BillingTransactionEntityImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$BillingTransactionEntityImplToJson(
      this,
    );
  }
}

abstract class _BillingTransactionEntity implements BillingTransactionEntity {
  const factory _BillingTransactionEntity(
      {required final String id,
      required final String type,
      required final String amountPlanck,
      final String? featureKey,
      final String? sessionId,
      required final String createdAt,
      final String status,
      final Map<String, dynamic>? metadata}) = _$BillingTransactionEntityImpl;

  factory _BillingTransactionEntity.fromJson(Map<String, dynamic> json) =
      _$BillingTransactionEntityImpl.fromJson;

  @override
  String get id;
  @override
  String get type;
  @override
  String get amountPlanck;
  @override
  String? get featureKey;
  @override
  String? get sessionId;
  @override
  String get createdAt;
  @override
  String get status;
  @override
  Map<String, dynamic>? get metadata;
  @override
  @JsonKey(ignore: true)
  _$$BillingTransactionEntityImplCopyWith<_$BillingTransactionEntityImpl>
      get copyWith => throw _privateConstructorUsedError;
}

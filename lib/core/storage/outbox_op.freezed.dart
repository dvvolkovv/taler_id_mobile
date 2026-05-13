// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'outbox_op.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

OutboxOp _$OutboxOpFromJson(Map<String, dynamic> json) {
  return _OutboxOp.fromJson(json);
}

/// @nodoc
mixin _$OutboxOp {
  String get opId => throw _privateConstructorUsedError;
  String get feature => throw _privateConstructorUsedError;
  OutboxOpKind get op => throw _privateConstructorUsedError;
  String get entityId => throw _privateConstructorUsedError;
  Map<String, dynamic>? get payload => throw _privateConstructorUsedError;
  DateTime? get expectedUpdatedAt => throw _privateConstructorUsedError;
  int get attempts => throw _privateConstructorUsedError;
  OutboxOpStatus get status => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;
  DateTime? get lastAttemptAt => throw _privateConstructorUsedError;
  String? get lastError => throw _privateConstructorUsedError;
  Map<String, dynamic>? get serverData => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $OutboxOpCopyWith<OutboxOp> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $OutboxOpCopyWith<$Res> {
  factory $OutboxOpCopyWith(OutboxOp value, $Res Function(OutboxOp) then) =
      _$OutboxOpCopyWithImpl<$Res, OutboxOp>;
  @useResult
  $Res call(
      {String opId,
      String feature,
      OutboxOpKind op,
      String entityId,
      Map<String, dynamic>? payload,
      DateTime? expectedUpdatedAt,
      int attempts,
      OutboxOpStatus status,
      DateTime createdAt,
      DateTime? lastAttemptAt,
      String? lastError,
      Map<String, dynamic>? serverData});
}

/// @nodoc
class _$OutboxOpCopyWithImpl<$Res, $Val extends OutboxOp>
    implements $OutboxOpCopyWith<$Res> {
  _$OutboxOpCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? opId = null,
    Object? feature = null,
    Object? op = null,
    Object? entityId = null,
    Object? payload = freezed,
    Object? expectedUpdatedAt = freezed,
    Object? attempts = null,
    Object? status = null,
    Object? createdAt = null,
    Object? lastAttemptAt = freezed,
    Object? lastError = freezed,
    Object? serverData = freezed,
  }) {
    return _then(_value.copyWith(
      opId: null == opId
          ? _value.opId
          : opId // ignore: cast_nullable_to_non_nullable
              as String,
      feature: null == feature
          ? _value.feature
          : feature // ignore: cast_nullable_to_non_nullable
              as String,
      op: null == op
          ? _value.op
          : op // ignore: cast_nullable_to_non_nullable
              as OutboxOpKind,
      entityId: null == entityId
          ? _value.entityId
          : entityId // ignore: cast_nullable_to_non_nullable
              as String,
      payload: freezed == payload
          ? _value.payload
          : payload // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
      expectedUpdatedAt: freezed == expectedUpdatedAt
          ? _value.expectedUpdatedAt
          : expectedUpdatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      attempts: null == attempts
          ? _value.attempts
          : attempts // ignore: cast_nullable_to_non_nullable
              as int,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as OutboxOpStatus,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      lastAttemptAt: freezed == lastAttemptAt
          ? _value.lastAttemptAt
          : lastAttemptAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      lastError: freezed == lastError
          ? _value.lastError
          : lastError // ignore: cast_nullable_to_non_nullable
              as String?,
      serverData: freezed == serverData
          ? _value.serverData
          : serverData // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$OutboxOpImplCopyWith<$Res>
    implements $OutboxOpCopyWith<$Res> {
  factory _$$OutboxOpImplCopyWith(
          _$OutboxOpImpl value, $Res Function(_$OutboxOpImpl) then) =
      __$$OutboxOpImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String opId,
      String feature,
      OutboxOpKind op,
      String entityId,
      Map<String, dynamic>? payload,
      DateTime? expectedUpdatedAt,
      int attempts,
      OutboxOpStatus status,
      DateTime createdAt,
      DateTime? lastAttemptAt,
      String? lastError,
      Map<String, dynamic>? serverData});
}

/// @nodoc
class __$$OutboxOpImplCopyWithImpl<$Res>
    extends _$OutboxOpCopyWithImpl<$Res, _$OutboxOpImpl>
    implements _$$OutboxOpImplCopyWith<$Res> {
  __$$OutboxOpImplCopyWithImpl(
      _$OutboxOpImpl _value, $Res Function(_$OutboxOpImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? opId = null,
    Object? feature = null,
    Object? op = null,
    Object? entityId = null,
    Object? payload = freezed,
    Object? expectedUpdatedAt = freezed,
    Object? attempts = null,
    Object? status = null,
    Object? createdAt = null,
    Object? lastAttemptAt = freezed,
    Object? lastError = freezed,
    Object? serverData = freezed,
  }) {
    return _then(_$OutboxOpImpl(
      opId: null == opId
          ? _value.opId
          : opId // ignore: cast_nullable_to_non_nullable
              as String,
      feature: null == feature
          ? _value.feature
          : feature // ignore: cast_nullable_to_non_nullable
              as String,
      op: null == op
          ? _value.op
          : op // ignore: cast_nullable_to_non_nullable
              as OutboxOpKind,
      entityId: null == entityId
          ? _value.entityId
          : entityId // ignore: cast_nullable_to_non_nullable
              as String,
      payload: freezed == payload
          ? _value._payload
          : payload // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
      expectedUpdatedAt: freezed == expectedUpdatedAt
          ? _value.expectedUpdatedAt
          : expectedUpdatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      attempts: null == attempts
          ? _value.attempts
          : attempts // ignore: cast_nullable_to_non_nullable
              as int,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as OutboxOpStatus,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      lastAttemptAt: freezed == lastAttemptAt
          ? _value.lastAttemptAt
          : lastAttemptAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      lastError: freezed == lastError
          ? _value.lastError
          : lastError // ignore: cast_nullable_to_non_nullable
              as String?,
      serverData: freezed == serverData
          ? _value._serverData
          : serverData // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$OutboxOpImpl implements _OutboxOp {
  const _$OutboxOpImpl(
      {required this.opId,
      required this.feature,
      required this.op,
      required this.entityId,
      final Map<String, dynamic>? payload,
      this.expectedUpdatedAt,
      this.attempts = 0,
      this.status = OutboxOpStatus.pending,
      required this.createdAt,
      this.lastAttemptAt,
      this.lastError,
      final Map<String, dynamic>? serverData})
      : _payload = payload,
        _serverData = serverData;

  factory _$OutboxOpImpl.fromJson(Map<String, dynamic> json) =>
      _$$OutboxOpImplFromJson(json);

  @override
  final String opId;
  @override
  final String feature;
  @override
  final OutboxOpKind op;
  @override
  final String entityId;
  final Map<String, dynamic>? _payload;
  @override
  Map<String, dynamic>? get payload {
    final value = _payload;
    if (value == null) return null;
    if (_payload is EqualUnmodifiableMapView) return _payload;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  @override
  final DateTime? expectedUpdatedAt;
  @override
  @JsonKey()
  final int attempts;
  @override
  @JsonKey()
  final OutboxOpStatus status;
  @override
  final DateTime createdAt;
  @override
  final DateTime? lastAttemptAt;
  @override
  final String? lastError;
  final Map<String, dynamic>? _serverData;
  @override
  Map<String, dynamic>? get serverData {
    final value = _serverData;
    if (value == null) return null;
    if (_serverData is EqualUnmodifiableMapView) return _serverData;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  @override
  String toString() {
    return 'OutboxOp(opId: $opId, feature: $feature, op: $op, entityId: $entityId, payload: $payload, expectedUpdatedAt: $expectedUpdatedAt, attempts: $attempts, status: $status, createdAt: $createdAt, lastAttemptAt: $lastAttemptAt, lastError: $lastError, serverData: $serverData)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$OutboxOpImpl &&
            (identical(other.opId, opId) || other.opId == opId) &&
            (identical(other.feature, feature) || other.feature == feature) &&
            (identical(other.op, op) || other.op == op) &&
            (identical(other.entityId, entityId) ||
                other.entityId == entityId) &&
            const DeepCollectionEquality().equals(other._payload, _payload) &&
            (identical(other.expectedUpdatedAt, expectedUpdatedAt) ||
                other.expectedUpdatedAt == expectedUpdatedAt) &&
            (identical(other.attempts, attempts) ||
                other.attempts == attempts) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.lastAttemptAt, lastAttemptAt) ||
                other.lastAttemptAt == lastAttemptAt) &&
            (identical(other.lastError, lastError) ||
                other.lastError == lastError) &&
            const DeepCollectionEquality()
                .equals(other._serverData, _serverData));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      opId,
      feature,
      op,
      entityId,
      const DeepCollectionEquality().hash(_payload),
      expectedUpdatedAt,
      attempts,
      status,
      createdAt,
      lastAttemptAt,
      lastError,
      const DeepCollectionEquality().hash(_serverData));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$OutboxOpImplCopyWith<_$OutboxOpImpl> get copyWith =>
      __$$OutboxOpImplCopyWithImpl<_$OutboxOpImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$OutboxOpImplToJson(
      this,
    );
  }
}

abstract class _OutboxOp implements OutboxOp {
  const factory _OutboxOp(
      {required final String opId,
      required final String feature,
      required final OutboxOpKind op,
      required final String entityId,
      final Map<String, dynamic>? payload,
      final DateTime? expectedUpdatedAt,
      final int attempts,
      final OutboxOpStatus status,
      required final DateTime createdAt,
      final DateTime? lastAttemptAt,
      final String? lastError,
      final Map<String, dynamic>? serverData}) = _$OutboxOpImpl;

  factory _OutboxOp.fromJson(Map<String, dynamic> json) =
      _$OutboxOpImpl.fromJson;

  @override
  String get opId;
  @override
  String get feature;
  @override
  OutboxOpKind get op;
  @override
  String get entityId;
  @override
  Map<String, dynamic>? get payload;
  @override
  DateTime? get expectedUpdatedAt;
  @override
  int get attempts;
  @override
  OutboxOpStatus get status;
  @override
  DateTime get createdAt;
  @override
  DateTime? get lastAttemptAt;
  @override
  String? get lastError;
  @override
  Map<String, dynamic>? get serverData;
  @override
  @JsonKey(ignore: true)
  _$$OutboxOpImplCopyWith<_$OutboxOpImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

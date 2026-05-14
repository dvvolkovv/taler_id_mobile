// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'contact_item_entity.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

ContactItemEntity _$ContactItemEntityFromJson(Map<String, dynamic> json) {
  return _ContactItemEntity.fromJson(json);
}

/// @nodoc
mixin _$ContactItemEntity {
  String get userId => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String? get username => throw _privateConstructorUsedError;
  String? get avatarUrl => throw _privateConstructorUsedError;
  ContactStatus get status => throw _privateConstructorUsedError;
  String? get conversationId => throw _privateConstructorUsedError;
  String? get requestId => throw _privateConstructorUsedError;
  DateTime? get requestSentAt => throw _privateConstructorUsedError;
  bool get localPending => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $ContactItemEntityCopyWith<ContactItemEntity> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ContactItemEntityCopyWith<$Res> {
  factory $ContactItemEntityCopyWith(
          ContactItemEntity value, $Res Function(ContactItemEntity) then) =
      _$ContactItemEntityCopyWithImpl<$Res, ContactItemEntity>;
  @useResult
  $Res call(
      {String userId,
      String name,
      String? username,
      String? avatarUrl,
      ContactStatus status,
      String? conversationId,
      String? requestId,
      DateTime? requestSentAt,
      bool localPending});
}

/// @nodoc
class _$ContactItemEntityCopyWithImpl<$Res, $Val extends ContactItemEntity>
    implements $ContactItemEntityCopyWith<$Res> {
  _$ContactItemEntityCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? userId = null,
    Object? name = null,
    Object? username = freezed,
    Object? avatarUrl = freezed,
    Object? status = null,
    Object? conversationId = freezed,
    Object? requestId = freezed,
    Object? requestSentAt = freezed,
    Object? localPending = null,
  }) {
    return _then(_value.copyWith(
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      username: freezed == username
          ? _value.username
          : username // ignore: cast_nullable_to_non_nullable
              as String?,
      avatarUrl: freezed == avatarUrl
          ? _value.avatarUrl
          : avatarUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as ContactStatus,
      conversationId: freezed == conversationId
          ? _value.conversationId
          : conversationId // ignore: cast_nullable_to_non_nullable
              as String?,
      requestId: freezed == requestId
          ? _value.requestId
          : requestId // ignore: cast_nullable_to_non_nullable
              as String?,
      requestSentAt: freezed == requestSentAt
          ? _value.requestSentAt
          : requestSentAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      localPending: null == localPending
          ? _value.localPending
          : localPending // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ContactItemEntityImplCopyWith<$Res>
    implements $ContactItemEntityCopyWith<$Res> {
  factory _$$ContactItemEntityImplCopyWith(_$ContactItemEntityImpl value,
          $Res Function(_$ContactItemEntityImpl) then) =
      __$$ContactItemEntityImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String userId,
      String name,
      String? username,
      String? avatarUrl,
      ContactStatus status,
      String? conversationId,
      String? requestId,
      DateTime? requestSentAt,
      bool localPending});
}

/// @nodoc
class __$$ContactItemEntityImplCopyWithImpl<$Res>
    extends _$ContactItemEntityCopyWithImpl<$Res, _$ContactItemEntityImpl>
    implements _$$ContactItemEntityImplCopyWith<$Res> {
  __$$ContactItemEntityImplCopyWithImpl(_$ContactItemEntityImpl _value,
      $Res Function(_$ContactItemEntityImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? userId = null,
    Object? name = null,
    Object? username = freezed,
    Object? avatarUrl = freezed,
    Object? status = null,
    Object? conversationId = freezed,
    Object? requestId = freezed,
    Object? requestSentAt = freezed,
    Object? localPending = null,
  }) {
    return _then(_$ContactItemEntityImpl(
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      username: freezed == username
          ? _value.username
          : username // ignore: cast_nullable_to_non_nullable
              as String?,
      avatarUrl: freezed == avatarUrl
          ? _value.avatarUrl
          : avatarUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as ContactStatus,
      conversationId: freezed == conversationId
          ? _value.conversationId
          : conversationId // ignore: cast_nullable_to_non_nullable
              as String?,
      requestId: freezed == requestId
          ? _value.requestId
          : requestId // ignore: cast_nullable_to_non_nullable
              as String?,
      requestSentAt: freezed == requestSentAt
          ? _value.requestSentAt
          : requestSentAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      localPending: null == localPending
          ? _value.localPending
          : localPending // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ContactItemEntityImpl implements _ContactItemEntity {
  const _$ContactItemEntityImpl(
      {required this.userId,
      required this.name,
      this.username,
      this.avatarUrl,
      required this.status,
      this.conversationId,
      this.requestId,
      this.requestSentAt,
      this.localPending = false});

  factory _$ContactItemEntityImpl.fromJson(Map<String, dynamic> json) =>
      _$$ContactItemEntityImplFromJson(json);

  @override
  final String userId;
  @override
  final String name;
  @override
  final String? username;
  @override
  final String? avatarUrl;
  @override
  final ContactStatus status;
  @override
  final String? conversationId;
  @override
  final String? requestId;
  @override
  final DateTime? requestSentAt;
  @override
  @JsonKey()
  final bool localPending;

  @override
  String toString() {
    return 'ContactItemEntity(userId: $userId, name: $name, username: $username, avatarUrl: $avatarUrl, status: $status, conversationId: $conversationId, requestId: $requestId, requestSentAt: $requestSentAt, localPending: $localPending)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ContactItemEntityImpl &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.username, username) ||
                other.username == username) &&
            (identical(other.avatarUrl, avatarUrl) ||
                other.avatarUrl == avatarUrl) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.conversationId, conversationId) ||
                other.conversationId == conversationId) &&
            (identical(other.requestId, requestId) ||
                other.requestId == requestId) &&
            (identical(other.requestSentAt, requestSentAt) ||
                other.requestSentAt == requestSentAt) &&
            (identical(other.localPending, localPending) ||
                other.localPending == localPending));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      userId,
      name,
      username,
      avatarUrl,
      status,
      conversationId,
      requestId,
      requestSentAt,
      localPending);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ContactItemEntityImplCopyWith<_$ContactItemEntityImpl> get copyWith =>
      __$$ContactItemEntityImplCopyWithImpl<_$ContactItemEntityImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ContactItemEntityImplToJson(
      this,
    );
  }
}

abstract class _ContactItemEntity implements ContactItemEntity {
  const factory _ContactItemEntity(
      {required final String userId,
      required final String name,
      final String? username,
      final String? avatarUrl,
      required final ContactStatus status,
      final String? conversationId,
      final String? requestId,
      final DateTime? requestSentAt,
      final bool localPending}) = _$ContactItemEntityImpl;

  factory _ContactItemEntity.fromJson(Map<String, dynamic> json) =
      _$ContactItemEntityImpl.fromJson;

  @override
  String get userId;
  @override
  String get name;
  @override
  String? get username;
  @override
  String? get avatarUrl;
  @override
  ContactStatus get status;
  @override
  String? get conversationId;
  @override
  String? get requestId;
  @override
  DateTime? get requestSentAt;
  @override
  bool get localPending;
  @override
  @JsonKey(ignore: true)
  _$$ContactItemEntityImplCopyWith<_$ContactItemEntityImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

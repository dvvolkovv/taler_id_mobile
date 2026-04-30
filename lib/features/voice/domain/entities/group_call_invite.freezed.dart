// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'group_call_invite.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$GroupCallInvite {
  String get id => throw _privateConstructorUsedError;
  String get userId => throw _privateConstructorUsedError;
  String get displayName => throw _privateConstructorUsedError;
  String? get avatarUrl => throw _privateConstructorUsedError;
  GroupCallInviteStatus get status => throw _privateConstructorUsedError;
  DateTime? get joinedAt => throw _privateConstructorUsedError;
  DateTime? get leftAt => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $GroupCallInviteCopyWith<GroupCallInvite> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $GroupCallInviteCopyWith<$Res> {
  factory $GroupCallInviteCopyWith(
          GroupCallInvite value, $Res Function(GroupCallInvite) then) =
      _$GroupCallInviteCopyWithImpl<$Res, GroupCallInvite>;
  @useResult
  $Res call(
      {String id,
      String userId,
      String displayName,
      String? avatarUrl,
      GroupCallInviteStatus status,
      DateTime? joinedAt,
      DateTime? leftAt});
}

/// @nodoc
class _$GroupCallInviteCopyWithImpl<$Res, $Val extends GroupCallInvite>
    implements $GroupCallInviteCopyWith<$Res> {
  _$GroupCallInviteCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? displayName = null,
    Object? avatarUrl = freezed,
    Object? status = null,
    Object? joinedAt = freezed,
    Object? leftAt = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      displayName: null == displayName
          ? _value.displayName
          : displayName // ignore: cast_nullable_to_non_nullable
              as String,
      avatarUrl: freezed == avatarUrl
          ? _value.avatarUrl
          : avatarUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as GroupCallInviteStatus,
      joinedAt: freezed == joinedAt
          ? _value.joinedAt
          : joinedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      leftAt: freezed == leftAt
          ? _value.leftAt
          : leftAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$GroupCallInviteImplCopyWith<$Res>
    implements $GroupCallInviteCopyWith<$Res> {
  factory _$$GroupCallInviteImplCopyWith(_$GroupCallInviteImpl value,
          $Res Function(_$GroupCallInviteImpl) then) =
      __$$GroupCallInviteImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String userId,
      String displayName,
      String? avatarUrl,
      GroupCallInviteStatus status,
      DateTime? joinedAt,
      DateTime? leftAt});
}

/// @nodoc
class __$$GroupCallInviteImplCopyWithImpl<$Res>
    extends _$GroupCallInviteCopyWithImpl<$Res, _$GroupCallInviteImpl>
    implements _$$GroupCallInviteImplCopyWith<$Res> {
  __$$GroupCallInviteImplCopyWithImpl(
      _$GroupCallInviteImpl _value, $Res Function(_$GroupCallInviteImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? displayName = null,
    Object? avatarUrl = freezed,
    Object? status = null,
    Object? joinedAt = freezed,
    Object? leftAt = freezed,
  }) {
    return _then(_$GroupCallInviteImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      displayName: null == displayName
          ? _value.displayName
          : displayName // ignore: cast_nullable_to_non_nullable
              as String,
      avatarUrl: freezed == avatarUrl
          ? _value.avatarUrl
          : avatarUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as GroupCallInviteStatus,
      joinedAt: freezed == joinedAt
          ? _value.joinedAt
          : joinedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      leftAt: freezed == leftAt
          ? _value.leftAt
          : leftAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc

class _$GroupCallInviteImpl implements _GroupCallInvite {
  const _$GroupCallInviteImpl(
      {required this.id,
      required this.userId,
      required this.displayName,
      this.avatarUrl,
      required this.status,
      this.joinedAt,
      this.leftAt});

  @override
  final String id;
  @override
  final String userId;
  @override
  final String displayName;
  @override
  final String? avatarUrl;
  @override
  final GroupCallInviteStatus status;
  @override
  final DateTime? joinedAt;
  @override
  final DateTime? leftAt;

  @override
  String toString() {
    return 'GroupCallInvite(id: $id, userId: $userId, displayName: $displayName, avatarUrl: $avatarUrl, status: $status, joinedAt: $joinedAt, leftAt: $leftAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$GroupCallInviteImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.displayName, displayName) ||
                other.displayName == displayName) &&
            (identical(other.avatarUrl, avatarUrl) ||
                other.avatarUrl == avatarUrl) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.joinedAt, joinedAt) ||
                other.joinedAt == joinedAt) &&
            (identical(other.leftAt, leftAt) || other.leftAt == leftAt));
  }

  @override
  int get hashCode => Object.hash(runtimeType, id, userId, displayName,
      avatarUrl, status, joinedAt, leftAt);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$GroupCallInviteImplCopyWith<_$GroupCallInviteImpl> get copyWith =>
      __$$GroupCallInviteImplCopyWithImpl<_$GroupCallInviteImpl>(
          this, _$identity);
}

abstract class _GroupCallInvite implements GroupCallInvite {
  const factory _GroupCallInvite(
      {required final String id,
      required final String userId,
      required final String displayName,
      final String? avatarUrl,
      required final GroupCallInviteStatus status,
      final DateTime? joinedAt,
      final DateTime? leftAt}) = _$GroupCallInviteImpl;

  @override
  String get id;
  @override
  String get userId;
  @override
  String get displayName;
  @override
  String? get avatarUrl;
  @override
  GroupCallInviteStatus get status;
  @override
  DateTime? get joinedAt;
  @override
  DateTime? get leftAt;
  @override
  @JsonKey(ignore: true)
  _$$GroupCallInviteImplCopyWith<_$GroupCallInviteImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

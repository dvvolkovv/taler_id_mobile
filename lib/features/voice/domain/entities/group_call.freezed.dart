// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'group_call.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$GroupCall {
  String get id => throw _privateConstructorUsedError;
  String get livekitRoomName => throw _privateConstructorUsedError;
  String get hostUserId => throw _privateConstructorUsedError;
  String get hostDisplayName => throw _privateConstructorUsedError;
  String? get hostAvatarUrl => throw _privateConstructorUsedError;
  GroupCallStatus get status => throw _privateConstructorUsedError;
  DateTime get startedAt => throw _privateConstructorUsedError;
  List<GroupCallInvite> get invites => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $GroupCallCopyWith<GroupCall> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $GroupCallCopyWith<$Res> {
  factory $GroupCallCopyWith(GroupCall value, $Res Function(GroupCall) then) =
      _$GroupCallCopyWithImpl<$Res, GroupCall>;
  @useResult
  $Res call(
      {String id,
      String livekitRoomName,
      String hostUserId,
      String hostDisplayName,
      String? hostAvatarUrl,
      GroupCallStatus status,
      DateTime startedAt,
      List<GroupCallInvite> invites});
}

/// @nodoc
class _$GroupCallCopyWithImpl<$Res, $Val extends GroupCall>
    implements $GroupCallCopyWith<$Res> {
  _$GroupCallCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? livekitRoomName = null,
    Object? hostUserId = null,
    Object? hostDisplayName = null,
    Object? hostAvatarUrl = freezed,
    Object? status = null,
    Object? startedAt = null,
    Object? invites = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      livekitRoomName: null == livekitRoomName
          ? _value.livekitRoomName
          : livekitRoomName // ignore: cast_nullable_to_non_nullable
              as String,
      hostUserId: null == hostUserId
          ? _value.hostUserId
          : hostUserId // ignore: cast_nullable_to_non_nullable
              as String,
      hostDisplayName: null == hostDisplayName
          ? _value.hostDisplayName
          : hostDisplayName // ignore: cast_nullable_to_non_nullable
              as String,
      hostAvatarUrl: freezed == hostAvatarUrl
          ? _value.hostAvatarUrl
          : hostAvatarUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as GroupCallStatus,
      startedAt: null == startedAt
          ? _value.startedAt
          : startedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      invites: null == invites
          ? _value.invites
          : invites // ignore: cast_nullable_to_non_nullable
              as List<GroupCallInvite>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$GroupCallImplCopyWith<$Res>
    implements $GroupCallCopyWith<$Res> {
  factory _$$GroupCallImplCopyWith(
          _$GroupCallImpl value, $Res Function(_$GroupCallImpl) then) =
      __$$GroupCallImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String livekitRoomName,
      String hostUserId,
      String hostDisplayName,
      String? hostAvatarUrl,
      GroupCallStatus status,
      DateTime startedAt,
      List<GroupCallInvite> invites});
}

/// @nodoc
class __$$GroupCallImplCopyWithImpl<$Res>
    extends _$GroupCallCopyWithImpl<$Res, _$GroupCallImpl>
    implements _$$GroupCallImplCopyWith<$Res> {
  __$$GroupCallImplCopyWithImpl(
      _$GroupCallImpl _value, $Res Function(_$GroupCallImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? livekitRoomName = null,
    Object? hostUserId = null,
    Object? hostDisplayName = null,
    Object? hostAvatarUrl = freezed,
    Object? status = null,
    Object? startedAt = null,
    Object? invites = null,
  }) {
    return _then(_$GroupCallImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      livekitRoomName: null == livekitRoomName
          ? _value.livekitRoomName
          : livekitRoomName // ignore: cast_nullable_to_non_nullable
              as String,
      hostUserId: null == hostUserId
          ? _value.hostUserId
          : hostUserId // ignore: cast_nullable_to_non_nullable
              as String,
      hostDisplayName: null == hostDisplayName
          ? _value.hostDisplayName
          : hostDisplayName // ignore: cast_nullable_to_non_nullable
              as String,
      hostAvatarUrl: freezed == hostAvatarUrl
          ? _value.hostAvatarUrl
          : hostAvatarUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as GroupCallStatus,
      startedAt: null == startedAt
          ? _value.startedAt
          : startedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      invites: null == invites
          ? _value._invites
          : invites // ignore: cast_nullable_to_non_nullable
              as List<GroupCallInvite>,
    ));
  }
}

/// @nodoc

class _$GroupCallImpl implements _GroupCall {
  const _$GroupCallImpl(
      {required this.id,
      required this.livekitRoomName,
      required this.hostUserId,
      required this.hostDisplayName,
      this.hostAvatarUrl,
      required this.status,
      required this.startedAt,
      final List<GroupCallInvite> invites = const []})
      : _invites = invites;

  @override
  final String id;
  @override
  final String livekitRoomName;
  @override
  final String hostUserId;
  @override
  final String hostDisplayName;
  @override
  final String? hostAvatarUrl;
  @override
  final GroupCallStatus status;
  @override
  final DateTime startedAt;
  final List<GroupCallInvite> _invites;
  @override
  @JsonKey()
  List<GroupCallInvite> get invites {
    if (_invites is EqualUnmodifiableListView) return _invites;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_invites);
  }

  @override
  String toString() {
    return 'GroupCall(id: $id, livekitRoomName: $livekitRoomName, hostUserId: $hostUserId, hostDisplayName: $hostDisplayName, hostAvatarUrl: $hostAvatarUrl, status: $status, startedAt: $startedAt, invites: $invites)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$GroupCallImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.livekitRoomName, livekitRoomName) ||
                other.livekitRoomName == livekitRoomName) &&
            (identical(other.hostUserId, hostUserId) ||
                other.hostUserId == hostUserId) &&
            (identical(other.hostDisplayName, hostDisplayName) ||
                other.hostDisplayName == hostDisplayName) &&
            (identical(other.hostAvatarUrl, hostAvatarUrl) ||
                other.hostAvatarUrl == hostAvatarUrl) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.startedAt, startedAt) ||
                other.startedAt == startedAt) &&
            const DeepCollectionEquality().equals(other._invites, _invites));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      livekitRoomName,
      hostUserId,
      hostDisplayName,
      hostAvatarUrl,
      status,
      startedAt,
      const DeepCollectionEquality().hash(_invites));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$GroupCallImplCopyWith<_$GroupCallImpl> get copyWith =>
      __$$GroupCallImplCopyWithImpl<_$GroupCallImpl>(this, _$identity);
}

abstract class _GroupCall implements GroupCall {
  const factory _GroupCall(
      {required final String id,
      required final String livekitRoomName,
      required final String hostUserId,
      required final String hostDisplayName,
      final String? hostAvatarUrl,
      required final GroupCallStatus status,
      required final DateTime startedAt,
      final List<GroupCallInvite> invites}) = _$GroupCallImpl;

  @override
  String get id;
  @override
  String get livekitRoomName;
  @override
  String get hostUserId;
  @override
  String get hostDisplayName;
  @override
  String? get hostAvatarUrl;
  @override
  GroupCallStatus get status;
  @override
  DateTime get startedAt;
  @override
  List<GroupCallInvite> get invites;
  @override
  @JsonKey(ignore: true)
  _$$GroupCallImplCopyWith<_$GroupCallImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

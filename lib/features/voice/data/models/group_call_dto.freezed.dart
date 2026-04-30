// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'group_call_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

ProfileSummaryDto _$ProfileSummaryDtoFromJson(Map<String, dynamic> json) {
  return _ProfileSummaryDto.fromJson(json);
}

/// @nodoc
mixin _$ProfileSummaryDto {
  String? get firstName => throw _privateConstructorUsedError;
  String? get lastName => throw _privateConstructorUsedError;
  String? get avatarUrl => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $ProfileSummaryDtoCopyWith<ProfileSummaryDto> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ProfileSummaryDtoCopyWith<$Res> {
  factory $ProfileSummaryDtoCopyWith(
          ProfileSummaryDto value, $Res Function(ProfileSummaryDto) then) =
      _$ProfileSummaryDtoCopyWithImpl<$Res, ProfileSummaryDto>;
  @useResult
  $Res call({String? firstName, String? lastName, String? avatarUrl});
}

/// @nodoc
class _$ProfileSummaryDtoCopyWithImpl<$Res, $Val extends ProfileSummaryDto>
    implements $ProfileSummaryDtoCopyWith<$Res> {
  _$ProfileSummaryDtoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? firstName = freezed,
    Object? lastName = freezed,
    Object? avatarUrl = freezed,
  }) {
    return _then(_value.copyWith(
      firstName: freezed == firstName
          ? _value.firstName
          : firstName // ignore: cast_nullable_to_non_nullable
              as String?,
      lastName: freezed == lastName
          ? _value.lastName
          : lastName // ignore: cast_nullable_to_non_nullable
              as String?,
      avatarUrl: freezed == avatarUrl
          ? _value.avatarUrl
          : avatarUrl // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ProfileSummaryDtoImplCopyWith<$Res>
    implements $ProfileSummaryDtoCopyWith<$Res> {
  factory _$$ProfileSummaryDtoImplCopyWith(_$ProfileSummaryDtoImpl value,
          $Res Function(_$ProfileSummaryDtoImpl) then) =
      __$$ProfileSummaryDtoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String? firstName, String? lastName, String? avatarUrl});
}

/// @nodoc
class __$$ProfileSummaryDtoImplCopyWithImpl<$Res>
    extends _$ProfileSummaryDtoCopyWithImpl<$Res, _$ProfileSummaryDtoImpl>
    implements _$$ProfileSummaryDtoImplCopyWith<$Res> {
  __$$ProfileSummaryDtoImplCopyWithImpl(_$ProfileSummaryDtoImpl _value,
      $Res Function(_$ProfileSummaryDtoImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? firstName = freezed,
    Object? lastName = freezed,
    Object? avatarUrl = freezed,
  }) {
    return _then(_$ProfileSummaryDtoImpl(
      firstName: freezed == firstName
          ? _value.firstName
          : firstName // ignore: cast_nullable_to_non_nullable
              as String?,
      lastName: freezed == lastName
          ? _value.lastName
          : lastName // ignore: cast_nullable_to_non_nullable
              as String?,
      avatarUrl: freezed == avatarUrl
          ? _value.avatarUrl
          : avatarUrl // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ProfileSummaryDtoImpl implements _ProfileSummaryDto {
  const _$ProfileSummaryDtoImpl(
      {this.firstName, this.lastName, this.avatarUrl});

  factory _$ProfileSummaryDtoImpl.fromJson(Map<String, dynamic> json) =>
      _$$ProfileSummaryDtoImplFromJson(json);

  @override
  final String? firstName;
  @override
  final String? lastName;
  @override
  final String? avatarUrl;

  @override
  String toString() {
    return 'ProfileSummaryDto(firstName: $firstName, lastName: $lastName, avatarUrl: $avatarUrl)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ProfileSummaryDtoImpl &&
            (identical(other.firstName, firstName) ||
                other.firstName == firstName) &&
            (identical(other.lastName, lastName) ||
                other.lastName == lastName) &&
            (identical(other.avatarUrl, avatarUrl) ||
                other.avatarUrl == avatarUrl));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, firstName, lastName, avatarUrl);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ProfileSummaryDtoImplCopyWith<_$ProfileSummaryDtoImpl> get copyWith =>
      __$$ProfileSummaryDtoImplCopyWithImpl<_$ProfileSummaryDtoImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ProfileSummaryDtoImplToJson(
      this,
    );
  }
}

abstract class _ProfileSummaryDto implements ProfileSummaryDto {
  const factory _ProfileSummaryDto(
      {final String? firstName,
      final String? lastName,
      final String? avatarUrl}) = _$ProfileSummaryDtoImpl;

  factory _ProfileSummaryDto.fromJson(Map<String, dynamic> json) =
      _$ProfileSummaryDtoImpl.fromJson;

  @override
  String? get firstName;
  @override
  String? get lastName;
  @override
  String? get avatarUrl;
  @override
  @JsonKey(ignore: true)
  _$$ProfileSummaryDtoImplCopyWith<_$ProfileSummaryDtoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

UserSummaryDto _$UserSummaryDtoFromJson(Map<String, dynamic> json) {
  return _UserSummaryDto.fromJson(json);
}

/// @nodoc
mixin _$UserSummaryDto {
  String get id => throw _privateConstructorUsedError;
  ProfileSummaryDto? get profile => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $UserSummaryDtoCopyWith<UserSummaryDto> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UserSummaryDtoCopyWith<$Res> {
  factory $UserSummaryDtoCopyWith(
          UserSummaryDto value, $Res Function(UserSummaryDto) then) =
      _$UserSummaryDtoCopyWithImpl<$Res, UserSummaryDto>;
  @useResult
  $Res call({String id, ProfileSummaryDto? profile});

  $ProfileSummaryDtoCopyWith<$Res>? get profile;
}

/// @nodoc
class _$UserSummaryDtoCopyWithImpl<$Res, $Val extends UserSummaryDto>
    implements $UserSummaryDtoCopyWith<$Res> {
  _$UserSummaryDtoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? profile = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      profile: freezed == profile
          ? _value.profile
          : profile // ignore: cast_nullable_to_non_nullable
              as ProfileSummaryDto?,
    ) as $Val);
  }

  @override
  @pragma('vm:prefer-inline')
  $ProfileSummaryDtoCopyWith<$Res>? get profile {
    if (_value.profile == null) {
      return null;
    }

    return $ProfileSummaryDtoCopyWith<$Res>(_value.profile!, (value) {
      return _then(_value.copyWith(profile: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$UserSummaryDtoImplCopyWith<$Res>
    implements $UserSummaryDtoCopyWith<$Res> {
  factory _$$UserSummaryDtoImplCopyWith(_$UserSummaryDtoImpl value,
          $Res Function(_$UserSummaryDtoImpl) then) =
      __$$UserSummaryDtoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String id, ProfileSummaryDto? profile});

  @override
  $ProfileSummaryDtoCopyWith<$Res>? get profile;
}

/// @nodoc
class __$$UserSummaryDtoImplCopyWithImpl<$Res>
    extends _$UserSummaryDtoCopyWithImpl<$Res, _$UserSummaryDtoImpl>
    implements _$$UserSummaryDtoImplCopyWith<$Res> {
  __$$UserSummaryDtoImplCopyWithImpl(
      _$UserSummaryDtoImpl _value, $Res Function(_$UserSummaryDtoImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? profile = freezed,
  }) {
    return _then(_$UserSummaryDtoImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      profile: freezed == profile
          ? _value.profile
          : profile // ignore: cast_nullable_to_non_nullable
              as ProfileSummaryDto?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$UserSummaryDtoImpl implements _UserSummaryDto {
  const _$UserSummaryDtoImpl({required this.id, this.profile});

  factory _$UserSummaryDtoImpl.fromJson(Map<String, dynamic> json) =>
      _$$UserSummaryDtoImplFromJson(json);

  @override
  final String id;
  @override
  final ProfileSummaryDto? profile;

  @override
  String toString() {
    return 'UserSummaryDto(id: $id, profile: $profile)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UserSummaryDtoImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.profile, profile) || other.profile == profile));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, id, profile);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$UserSummaryDtoImplCopyWith<_$UserSummaryDtoImpl> get copyWith =>
      __$$UserSummaryDtoImplCopyWithImpl<_$UserSummaryDtoImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$UserSummaryDtoImplToJson(
      this,
    );
  }
}

abstract class _UserSummaryDto implements UserSummaryDto {
  const factory _UserSummaryDto(
      {required final String id,
      final ProfileSummaryDto? profile}) = _$UserSummaryDtoImpl;

  factory _UserSummaryDto.fromJson(Map<String, dynamic> json) =
      _$UserSummaryDtoImpl.fromJson;

  @override
  String get id;
  @override
  ProfileSummaryDto? get profile;
  @override
  @JsonKey(ignore: true)
  _$$UserSummaryDtoImplCopyWith<_$UserSummaryDtoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

GroupCallInviteDto _$GroupCallInviteDtoFromJson(Map<String, dynamic> json) {
  return _GroupCallInviteDto.fromJson(json);
}

/// @nodoc
mixin _$GroupCallInviteDto {
  String get id => throw _privateConstructorUsedError;
  String get groupCallId => throw _privateConstructorUsedError;
  String get userId => throw _privateConstructorUsedError;
  GroupCallInviteStatusDto get status => throw _privateConstructorUsedError;
  DateTime get invitedAt => throw _privateConstructorUsedError;
  DateTime? get respondedAt => throw _privateConstructorUsedError;
  DateTime? get joinedAt => throw _privateConstructorUsedError;
  DateTime? get leftAt => throw _privateConstructorUsedError;
  UserSummaryDto? get user => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $GroupCallInviteDtoCopyWith<GroupCallInviteDto> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $GroupCallInviteDtoCopyWith<$Res> {
  factory $GroupCallInviteDtoCopyWith(
          GroupCallInviteDto value, $Res Function(GroupCallInviteDto) then) =
      _$GroupCallInviteDtoCopyWithImpl<$Res, GroupCallInviteDto>;
  @useResult
  $Res call(
      {String id,
      String groupCallId,
      String userId,
      GroupCallInviteStatusDto status,
      DateTime invitedAt,
      DateTime? respondedAt,
      DateTime? joinedAt,
      DateTime? leftAt,
      UserSummaryDto? user});

  $UserSummaryDtoCopyWith<$Res>? get user;
}

/// @nodoc
class _$GroupCallInviteDtoCopyWithImpl<$Res, $Val extends GroupCallInviteDto>
    implements $GroupCallInviteDtoCopyWith<$Res> {
  _$GroupCallInviteDtoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? groupCallId = null,
    Object? userId = null,
    Object? status = null,
    Object? invitedAt = null,
    Object? respondedAt = freezed,
    Object? joinedAt = freezed,
    Object? leftAt = freezed,
    Object? user = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      groupCallId: null == groupCallId
          ? _value.groupCallId
          : groupCallId // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as GroupCallInviteStatusDto,
      invitedAt: null == invitedAt
          ? _value.invitedAt
          : invitedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      respondedAt: freezed == respondedAt
          ? _value.respondedAt
          : respondedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      joinedAt: freezed == joinedAt
          ? _value.joinedAt
          : joinedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      leftAt: freezed == leftAt
          ? _value.leftAt
          : leftAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      user: freezed == user
          ? _value.user
          : user // ignore: cast_nullable_to_non_nullable
              as UserSummaryDto?,
    ) as $Val);
  }

  @override
  @pragma('vm:prefer-inline')
  $UserSummaryDtoCopyWith<$Res>? get user {
    if (_value.user == null) {
      return null;
    }

    return $UserSummaryDtoCopyWith<$Res>(_value.user!, (value) {
      return _then(_value.copyWith(user: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$GroupCallInviteDtoImplCopyWith<$Res>
    implements $GroupCallInviteDtoCopyWith<$Res> {
  factory _$$GroupCallInviteDtoImplCopyWith(_$GroupCallInviteDtoImpl value,
          $Res Function(_$GroupCallInviteDtoImpl) then) =
      __$$GroupCallInviteDtoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String groupCallId,
      String userId,
      GroupCallInviteStatusDto status,
      DateTime invitedAt,
      DateTime? respondedAt,
      DateTime? joinedAt,
      DateTime? leftAt,
      UserSummaryDto? user});

  @override
  $UserSummaryDtoCopyWith<$Res>? get user;
}

/// @nodoc
class __$$GroupCallInviteDtoImplCopyWithImpl<$Res>
    extends _$GroupCallInviteDtoCopyWithImpl<$Res, _$GroupCallInviteDtoImpl>
    implements _$$GroupCallInviteDtoImplCopyWith<$Res> {
  __$$GroupCallInviteDtoImplCopyWithImpl(_$GroupCallInviteDtoImpl _value,
      $Res Function(_$GroupCallInviteDtoImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? groupCallId = null,
    Object? userId = null,
    Object? status = null,
    Object? invitedAt = null,
    Object? respondedAt = freezed,
    Object? joinedAt = freezed,
    Object? leftAt = freezed,
    Object? user = freezed,
  }) {
    return _then(_$GroupCallInviteDtoImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      groupCallId: null == groupCallId
          ? _value.groupCallId
          : groupCallId // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as GroupCallInviteStatusDto,
      invitedAt: null == invitedAt
          ? _value.invitedAt
          : invitedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      respondedAt: freezed == respondedAt
          ? _value.respondedAt
          : respondedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      joinedAt: freezed == joinedAt
          ? _value.joinedAt
          : joinedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      leftAt: freezed == leftAt
          ? _value.leftAt
          : leftAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      user: freezed == user
          ? _value.user
          : user // ignore: cast_nullable_to_non_nullable
              as UserSummaryDto?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$GroupCallInviteDtoImpl implements _GroupCallInviteDto {
  const _$GroupCallInviteDtoImpl(
      {required this.id,
      required this.groupCallId,
      required this.userId,
      required this.status,
      required this.invitedAt,
      this.respondedAt,
      this.joinedAt,
      this.leftAt,
      this.user});

  factory _$GroupCallInviteDtoImpl.fromJson(Map<String, dynamic> json) =>
      _$$GroupCallInviteDtoImplFromJson(json);

  @override
  final String id;
  @override
  final String groupCallId;
  @override
  final String userId;
  @override
  final GroupCallInviteStatusDto status;
  @override
  final DateTime invitedAt;
  @override
  final DateTime? respondedAt;
  @override
  final DateTime? joinedAt;
  @override
  final DateTime? leftAt;
  @override
  final UserSummaryDto? user;

  @override
  String toString() {
    return 'GroupCallInviteDto(id: $id, groupCallId: $groupCallId, userId: $userId, status: $status, invitedAt: $invitedAt, respondedAt: $respondedAt, joinedAt: $joinedAt, leftAt: $leftAt, user: $user)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$GroupCallInviteDtoImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.groupCallId, groupCallId) ||
                other.groupCallId == groupCallId) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.invitedAt, invitedAt) ||
                other.invitedAt == invitedAt) &&
            (identical(other.respondedAt, respondedAt) ||
                other.respondedAt == respondedAt) &&
            (identical(other.joinedAt, joinedAt) ||
                other.joinedAt == joinedAt) &&
            (identical(other.leftAt, leftAt) || other.leftAt == leftAt) &&
            (identical(other.user, user) || other.user == user));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, id, groupCallId, userId, status,
      invitedAt, respondedAt, joinedAt, leftAt, user);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$GroupCallInviteDtoImplCopyWith<_$GroupCallInviteDtoImpl> get copyWith =>
      __$$GroupCallInviteDtoImplCopyWithImpl<_$GroupCallInviteDtoImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$GroupCallInviteDtoImplToJson(
      this,
    );
  }
}

abstract class _GroupCallInviteDto implements GroupCallInviteDto {
  const factory _GroupCallInviteDto(
      {required final String id,
      required final String groupCallId,
      required final String userId,
      required final GroupCallInviteStatusDto status,
      required final DateTime invitedAt,
      final DateTime? respondedAt,
      final DateTime? joinedAt,
      final DateTime? leftAt,
      final UserSummaryDto? user}) = _$GroupCallInviteDtoImpl;

  factory _GroupCallInviteDto.fromJson(Map<String, dynamic> json) =
      _$GroupCallInviteDtoImpl.fromJson;

  @override
  String get id;
  @override
  String get groupCallId;
  @override
  String get userId;
  @override
  GroupCallInviteStatusDto get status;
  @override
  DateTime get invitedAt;
  @override
  DateTime? get respondedAt;
  @override
  DateTime? get joinedAt;
  @override
  DateTime? get leftAt;
  @override
  UserSummaryDto? get user;
  @override
  @JsonKey(ignore: true)
  _$$GroupCallInviteDtoImplCopyWith<_$GroupCallInviteDtoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

GroupCallDto _$GroupCallDtoFromJson(Map<String, dynamic> json) {
  return _GroupCallDto.fromJson(json);
}

/// @nodoc
mixin _$GroupCallDto {
  String get id => throw _privateConstructorUsedError;
  String get livekitRoomName => throw _privateConstructorUsedError;
  String get hostUserId => throw _privateConstructorUsedError;
  GroupCallStatusDto get status => throw _privateConstructorUsedError;
  DateTime get startedAt => throw _privateConstructorUsedError;
  DateTime? get endedAt => throw _privateConstructorUsedError;
  String? get endedReason => throw _privateConstructorUsedError;
  UserSummaryDto? get host => throw _privateConstructorUsedError;
  List<GroupCallInviteDto> get invites => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $GroupCallDtoCopyWith<GroupCallDto> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $GroupCallDtoCopyWith<$Res> {
  factory $GroupCallDtoCopyWith(
          GroupCallDto value, $Res Function(GroupCallDto) then) =
      _$GroupCallDtoCopyWithImpl<$Res, GroupCallDto>;
  @useResult
  $Res call(
      {String id,
      String livekitRoomName,
      String hostUserId,
      GroupCallStatusDto status,
      DateTime startedAt,
      DateTime? endedAt,
      String? endedReason,
      UserSummaryDto? host,
      List<GroupCallInviteDto> invites});

  $UserSummaryDtoCopyWith<$Res>? get host;
}

/// @nodoc
class _$GroupCallDtoCopyWithImpl<$Res, $Val extends GroupCallDto>
    implements $GroupCallDtoCopyWith<$Res> {
  _$GroupCallDtoCopyWithImpl(this._value, this._then);

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
    Object? status = null,
    Object? startedAt = null,
    Object? endedAt = freezed,
    Object? endedReason = freezed,
    Object? host = freezed,
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
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as GroupCallStatusDto,
      startedAt: null == startedAt
          ? _value.startedAt
          : startedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      endedAt: freezed == endedAt
          ? _value.endedAt
          : endedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      endedReason: freezed == endedReason
          ? _value.endedReason
          : endedReason // ignore: cast_nullable_to_non_nullable
              as String?,
      host: freezed == host
          ? _value.host
          : host // ignore: cast_nullable_to_non_nullable
              as UserSummaryDto?,
      invites: null == invites
          ? _value.invites
          : invites // ignore: cast_nullable_to_non_nullable
              as List<GroupCallInviteDto>,
    ) as $Val);
  }

  @override
  @pragma('vm:prefer-inline')
  $UserSummaryDtoCopyWith<$Res>? get host {
    if (_value.host == null) {
      return null;
    }

    return $UserSummaryDtoCopyWith<$Res>(_value.host!, (value) {
      return _then(_value.copyWith(host: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$GroupCallDtoImplCopyWith<$Res>
    implements $GroupCallDtoCopyWith<$Res> {
  factory _$$GroupCallDtoImplCopyWith(
          _$GroupCallDtoImpl value, $Res Function(_$GroupCallDtoImpl) then) =
      __$$GroupCallDtoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String livekitRoomName,
      String hostUserId,
      GroupCallStatusDto status,
      DateTime startedAt,
      DateTime? endedAt,
      String? endedReason,
      UserSummaryDto? host,
      List<GroupCallInviteDto> invites});

  @override
  $UserSummaryDtoCopyWith<$Res>? get host;
}

/// @nodoc
class __$$GroupCallDtoImplCopyWithImpl<$Res>
    extends _$GroupCallDtoCopyWithImpl<$Res, _$GroupCallDtoImpl>
    implements _$$GroupCallDtoImplCopyWith<$Res> {
  __$$GroupCallDtoImplCopyWithImpl(
      _$GroupCallDtoImpl _value, $Res Function(_$GroupCallDtoImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? livekitRoomName = null,
    Object? hostUserId = null,
    Object? status = null,
    Object? startedAt = null,
    Object? endedAt = freezed,
    Object? endedReason = freezed,
    Object? host = freezed,
    Object? invites = null,
  }) {
    return _then(_$GroupCallDtoImpl(
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
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as GroupCallStatusDto,
      startedAt: null == startedAt
          ? _value.startedAt
          : startedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      endedAt: freezed == endedAt
          ? _value.endedAt
          : endedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      endedReason: freezed == endedReason
          ? _value.endedReason
          : endedReason // ignore: cast_nullable_to_non_nullable
              as String?,
      host: freezed == host
          ? _value.host
          : host // ignore: cast_nullable_to_non_nullable
              as UserSummaryDto?,
      invites: null == invites
          ? _value._invites
          : invites // ignore: cast_nullable_to_non_nullable
              as List<GroupCallInviteDto>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$GroupCallDtoImpl implements _GroupCallDto {
  const _$GroupCallDtoImpl(
      {required this.id,
      required this.livekitRoomName,
      required this.hostUserId,
      required this.status,
      required this.startedAt,
      this.endedAt,
      this.endedReason,
      this.host,
      final List<GroupCallInviteDto> invites = const []})
      : _invites = invites;

  factory _$GroupCallDtoImpl.fromJson(Map<String, dynamic> json) =>
      _$$GroupCallDtoImplFromJson(json);

  @override
  final String id;
  @override
  final String livekitRoomName;
  @override
  final String hostUserId;
  @override
  final GroupCallStatusDto status;
  @override
  final DateTime startedAt;
  @override
  final DateTime? endedAt;
  @override
  final String? endedReason;
  @override
  final UserSummaryDto? host;
  final List<GroupCallInviteDto> _invites;
  @override
  @JsonKey()
  List<GroupCallInviteDto> get invites {
    if (_invites is EqualUnmodifiableListView) return _invites;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_invites);
  }

  @override
  String toString() {
    return 'GroupCallDto(id: $id, livekitRoomName: $livekitRoomName, hostUserId: $hostUserId, status: $status, startedAt: $startedAt, endedAt: $endedAt, endedReason: $endedReason, host: $host, invites: $invites)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$GroupCallDtoImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.livekitRoomName, livekitRoomName) ||
                other.livekitRoomName == livekitRoomName) &&
            (identical(other.hostUserId, hostUserId) ||
                other.hostUserId == hostUserId) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.startedAt, startedAt) ||
                other.startedAt == startedAt) &&
            (identical(other.endedAt, endedAt) || other.endedAt == endedAt) &&
            (identical(other.endedReason, endedReason) ||
                other.endedReason == endedReason) &&
            (identical(other.host, host) || other.host == host) &&
            const DeepCollectionEquality().equals(other._invites, _invites));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      livekitRoomName,
      hostUserId,
      status,
      startedAt,
      endedAt,
      endedReason,
      host,
      const DeepCollectionEquality().hash(_invites));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$GroupCallDtoImplCopyWith<_$GroupCallDtoImpl> get copyWith =>
      __$$GroupCallDtoImplCopyWithImpl<_$GroupCallDtoImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$GroupCallDtoImplToJson(
      this,
    );
  }
}

abstract class _GroupCallDto implements GroupCallDto {
  const factory _GroupCallDto(
      {required final String id,
      required final String livekitRoomName,
      required final String hostUserId,
      required final GroupCallStatusDto status,
      required final DateTime startedAt,
      final DateTime? endedAt,
      final String? endedReason,
      final UserSummaryDto? host,
      final List<GroupCallInviteDto> invites}) = _$GroupCallDtoImpl;

  factory _GroupCallDto.fromJson(Map<String, dynamic> json) =
      _$GroupCallDtoImpl.fromJson;

  @override
  String get id;
  @override
  String get livekitRoomName;
  @override
  String get hostUserId;
  @override
  GroupCallStatusDto get status;
  @override
  DateTime get startedAt;
  @override
  DateTime? get endedAt;
  @override
  String? get endedReason;
  @override
  UserSummaryDto? get host;
  @override
  List<GroupCallInviteDto> get invites;
  @override
  @JsonKey(ignore: true)
  _$$GroupCallDtoImplCopyWith<_$GroupCallDtoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

CreateGroupCallResponseDto _$CreateGroupCallResponseDtoFromJson(
    Map<String, dynamic> json) {
  return _CreateGroupCallResponseDto.fromJson(json);
}

/// @nodoc
mixin _$CreateGroupCallResponseDto {
  GroupCallDto get groupCall => throw _privateConstructorUsedError;
  String get livekitToken => throw _privateConstructorUsedError;
  String get livekitWsUrl => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $CreateGroupCallResponseDtoCopyWith<CreateGroupCallResponseDto>
      get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CreateGroupCallResponseDtoCopyWith<$Res> {
  factory $CreateGroupCallResponseDtoCopyWith(CreateGroupCallResponseDto value,
          $Res Function(CreateGroupCallResponseDto) then) =
      _$CreateGroupCallResponseDtoCopyWithImpl<$Res,
          CreateGroupCallResponseDto>;
  @useResult
  $Res call({GroupCallDto groupCall, String livekitToken, String livekitWsUrl});

  $GroupCallDtoCopyWith<$Res> get groupCall;
}

/// @nodoc
class _$CreateGroupCallResponseDtoCopyWithImpl<$Res,
        $Val extends CreateGroupCallResponseDto>
    implements $CreateGroupCallResponseDtoCopyWith<$Res> {
  _$CreateGroupCallResponseDtoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? groupCall = null,
    Object? livekitToken = null,
    Object? livekitWsUrl = null,
  }) {
    return _then(_value.copyWith(
      groupCall: null == groupCall
          ? _value.groupCall
          : groupCall // ignore: cast_nullable_to_non_nullable
              as GroupCallDto,
      livekitToken: null == livekitToken
          ? _value.livekitToken
          : livekitToken // ignore: cast_nullable_to_non_nullable
              as String,
      livekitWsUrl: null == livekitWsUrl
          ? _value.livekitWsUrl
          : livekitWsUrl // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }

  @override
  @pragma('vm:prefer-inline')
  $GroupCallDtoCopyWith<$Res> get groupCall {
    return $GroupCallDtoCopyWith<$Res>(_value.groupCall, (value) {
      return _then(_value.copyWith(groupCall: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$CreateGroupCallResponseDtoImplCopyWith<$Res>
    implements $CreateGroupCallResponseDtoCopyWith<$Res> {
  factory _$$CreateGroupCallResponseDtoImplCopyWith(
          _$CreateGroupCallResponseDtoImpl value,
          $Res Function(_$CreateGroupCallResponseDtoImpl) then) =
      __$$CreateGroupCallResponseDtoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({GroupCallDto groupCall, String livekitToken, String livekitWsUrl});

  @override
  $GroupCallDtoCopyWith<$Res> get groupCall;
}

/// @nodoc
class __$$CreateGroupCallResponseDtoImplCopyWithImpl<$Res>
    extends _$CreateGroupCallResponseDtoCopyWithImpl<$Res,
        _$CreateGroupCallResponseDtoImpl>
    implements _$$CreateGroupCallResponseDtoImplCopyWith<$Res> {
  __$$CreateGroupCallResponseDtoImplCopyWithImpl(
      _$CreateGroupCallResponseDtoImpl _value,
      $Res Function(_$CreateGroupCallResponseDtoImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? groupCall = null,
    Object? livekitToken = null,
    Object? livekitWsUrl = null,
  }) {
    return _then(_$CreateGroupCallResponseDtoImpl(
      groupCall: null == groupCall
          ? _value.groupCall
          : groupCall // ignore: cast_nullable_to_non_nullable
              as GroupCallDto,
      livekitToken: null == livekitToken
          ? _value.livekitToken
          : livekitToken // ignore: cast_nullable_to_non_nullable
              as String,
      livekitWsUrl: null == livekitWsUrl
          ? _value.livekitWsUrl
          : livekitWsUrl // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$CreateGroupCallResponseDtoImpl implements _CreateGroupCallResponseDto {
  const _$CreateGroupCallResponseDtoImpl(
      {required this.groupCall,
      required this.livekitToken,
      required this.livekitWsUrl});

  factory _$CreateGroupCallResponseDtoImpl.fromJson(
          Map<String, dynamic> json) =>
      _$$CreateGroupCallResponseDtoImplFromJson(json);

  @override
  final GroupCallDto groupCall;
  @override
  final String livekitToken;
  @override
  final String livekitWsUrl;

  @override
  String toString() {
    return 'CreateGroupCallResponseDto(groupCall: $groupCall, livekitToken: $livekitToken, livekitWsUrl: $livekitWsUrl)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CreateGroupCallResponseDtoImpl &&
            (identical(other.groupCall, groupCall) ||
                other.groupCall == groupCall) &&
            (identical(other.livekitToken, livekitToken) ||
                other.livekitToken == livekitToken) &&
            (identical(other.livekitWsUrl, livekitWsUrl) ||
                other.livekitWsUrl == livekitWsUrl));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode =>
      Object.hash(runtimeType, groupCall, livekitToken, livekitWsUrl);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$CreateGroupCallResponseDtoImplCopyWith<_$CreateGroupCallResponseDtoImpl>
      get copyWith => __$$CreateGroupCallResponseDtoImplCopyWithImpl<
          _$CreateGroupCallResponseDtoImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$CreateGroupCallResponseDtoImplToJson(
      this,
    );
  }
}

abstract class _CreateGroupCallResponseDto
    implements CreateGroupCallResponseDto {
  const factory _CreateGroupCallResponseDto(
      {required final GroupCallDto groupCall,
      required final String livekitToken,
      required final String livekitWsUrl}) = _$CreateGroupCallResponseDtoImpl;

  factory _CreateGroupCallResponseDto.fromJson(Map<String, dynamic> json) =
      _$CreateGroupCallResponseDtoImpl.fromJson;

  @override
  GroupCallDto get groupCall;
  @override
  String get livekitToken;
  @override
  String get livekitWsUrl;
  @override
  @JsonKey(ignore: true)
  _$$CreateGroupCallResponseDtoImplCopyWith<_$CreateGroupCallResponseDtoImpl>
      get copyWith => throw _privateConstructorUsedError;
}

JoinGroupCallResponseDto _$JoinGroupCallResponseDtoFromJson(
    Map<String, dynamic> json) {
  return _JoinGroupCallResponseDto.fromJson(json);
}

/// @nodoc
mixin _$JoinGroupCallResponseDto {
  String get livekitToken => throw _privateConstructorUsedError;
  String get livekitWsUrl => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $JoinGroupCallResponseDtoCopyWith<JoinGroupCallResponseDto> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $JoinGroupCallResponseDtoCopyWith<$Res> {
  factory $JoinGroupCallResponseDtoCopyWith(JoinGroupCallResponseDto value,
          $Res Function(JoinGroupCallResponseDto) then) =
      _$JoinGroupCallResponseDtoCopyWithImpl<$Res, JoinGroupCallResponseDto>;
  @useResult
  $Res call({String livekitToken, String livekitWsUrl});
}

/// @nodoc
class _$JoinGroupCallResponseDtoCopyWithImpl<$Res,
        $Val extends JoinGroupCallResponseDto>
    implements $JoinGroupCallResponseDtoCopyWith<$Res> {
  _$JoinGroupCallResponseDtoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? livekitToken = null,
    Object? livekitWsUrl = null,
  }) {
    return _then(_value.copyWith(
      livekitToken: null == livekitToken
          ? _value.livekitToken
          : livekitToken // ignore: cast_nullable_to_non_nullable
              as String,
      livekitWsUrl: null == livekitWsUrl
          ? _value.livekitWsUrl
          : livekitWsUrl // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$JoinGroupCallResponseDtoImplCopyWith<$Res>
    implements $JoinGroupCallResponseDtoCopyWith<$Res> {
  factory _$$JoinGroupCallResponseDtoImplCopyWith(
          _$JoinGroupCallResponseDtoImpl value,
          $Res Function(_$JoinGroupCallResponseDtoImpl) then) =
      __$$JoinGroupCallResponseDtoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String livekitToken, String livekitWsUrl});
}

/// @nodoc
class __$$JoinGroupCallResponseDtoImplCopyWithImpl<$Res>
    extends _$JoinGroupCallResponseDtoCopyWithImpl<$Res,
        _$JoinGroupCallResponseDtoImpl>
    implements _$$JoinGroupCallResponseDtoImplCopyWith<$Res> {
  __$$JoinGroupCallResponseDtoImplCopyWithImpl(
      _$JoinGroupCallResponseDtoImpl _value,
      $Res Function(_$JoinGroupCallResponseDtoImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? livekitToken = null,
    Object? livekitWsUrl = null,
  }) {
    return _then(_$JoinGroupCallResponseDtoImpl(
      livekitToken: null == livekitToken
          ? _value.livekitToken
          : livekitToken // ignore: cast_nullable_to_non_nullable
              as String,
      livekitWsUrl: null == livekitWsUrl
          ? _value.livekitWsUrl
          : livekitWsUrl // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$JoinGroupCallResponseDtoImpl implements _JoinGroupCallResponseDto {
  const _$JoinGroupCallResponseDtoImpl(
      {required this.livekitToken, required this.livekitWsUrl});

  factory _$JoinGroupCallResponseDtoImpl.fromJson(Map<String, dynamic> json) =>
      _$$JoinGroupCallResponseDtoImplFromJson(json);

  @override
  final String livekitToken;
  @override
  final String livekitWsUrl;

  @override
  String toString() {
    return 'JoinGroupCallResponseDto(livekitToken: $livekitToken, livekitWsUrl: $livekitWsUrl)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$JoinGroupCallResponseDtoImpl &&
            (identical(other.livekitToken, livekitToken) ||
                other.livekitToken == livekitToken) &&
            (identical(other.livekitWsUrl, livekitWsUrl) ||
                other.livekitWsUrl == livekitWsUrl));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, livekitToken, livekitWsUrl);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$JoinGroupCallResponseDtoImplCopyWith<_$JoinGroupCallResponseDtoImpl>
      get copyWith => __$$JoinGroupCallResponseDtoImplCopyWithImpl<
          _$JoinGroupCallResponseDtoImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$JoinGroupCallResponseDtoImplToJson(
      this,
    );
  }
}

abstract class _JoinGroupCallResponseDto implements JoinGroupCallResponseDto {
  const factory _JoinGroupCallResponseDto(
      {required final String livekitToken,
      required final String livekitWsUrl}) = _$JoinGroupCallResponseDtoImpl;

  factory _JoinGroupCallResponseDto.fromJson(Map<String, dynamic> json) =
      _$JoinGroupCallResponseDtoImpl.fromJson;

  @override
  String get livekitToken;
  @override
  String get livekitWsUrl;
  @override
  @JsonKey(ignore: true)
  _$$JoinGroupCallResponseDtoImplCopyWith<_$JoinGroupCallResponseDtoImpl>
      get copyWith => throw _privateConstructorUsedError;
}

ActiveGroupCallsResponseDto _$ActiveGroupCallsResponseDtoFromJson(
    Map<String, dynamic> json) {
  return _ActiveGroupCallsResponseDto.fromJson(json);
}

/// @nodoc
mixin _$ActiveGroupCallsResponseDto {
  List<GroupCallDto> get calls => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $ActiveGroupCallsResponseDtoCopyWith<ActiveGroupCallsResponseDto>
      get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ActiveGroupCallsResponseDtoCopyWith<$Res> {
  factory $ActiveGroupCallsResponseDtoCopyWith(
          ActiveGroupCallsResponseDto value,
          $Res Function(ActiveGroupCallsResponseDto) then) =
      _$ActiveGroupCallsResponseDtoCopyWithImpl<$Res,
          ActiveGroupCallsResponseDto>;
  @useResult
  $Res call({List<GroupCallDto> calls});
}

/// @nodoc
class _$ActiveGroupCallsResponseDtoCopyWithImpl<$Res,
        $Val extends ActiveGroupCallsResponseDto>
    implements $ActiveGroupCallsResponseDtoCopyWith<$Res> {
  _$ActiveGroupCallsResponseDtoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? calls = null,
  }) {
    return _then(_value.copyWith(
      calls: null == calls
          ? _value.calls
          : calls // ignore: cast_nullable_to_non_nullable
              as List<GroupCallDto>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ActiveGroupCallsResponseDtoImplCopyWith<$Res>
    implements $ActiveGroupCallsResponseDtoCopyWith<$Res> {
  factory _$$ActiveGroupCallsResponseDtoImplCopyWith(
          _$ActiveGroupCallsResponseDtoImpl value,
          $Res Function(_$ActiveGroupCallsResponseDtoImpl) then) =
      __$$ActiveGroupCallsResponseDtoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({List<GroupCallDto> calls});
}

/// @nodoc
class __$$ActiveGroupCallsResponseDtoImplCopyWithImpl<$Res>
    extends _$ActiveGroupCallsResponseDtoCopyWithImpl<$Res,
        _$ActiveGroupCallsResponseDtoImpl>
    implements _$$ActiveGroupCallsResponseDtoImplCopyWith<$Res> {
  __$$ActiveGroupCallsResponseDtoImplCopyWithImpl(
      _$ActiveGroupCallsResponseDtoImpl _value,
      $Res Function(_$ActiveGroupCallsResponseDtoImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? calls = null,
  }) {
    return _then(_$ActiveGroupCallsResponseDtoImpl(
      calls: null == calls
          ? _value._calls
          : calls // ignore: cast_nullable_to_non_nullable
              as List<GroupCallDto>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ActiveGroupCallsResponseDtoImpl
    implements _ActiveGroupCallsResponseDto {
  const _$ActiveGroupCallsResponseDtoImpl(
      {final List<GroupCallDto> calls = const []})
      : _calls = calls;

  factory _$ActiveGroupCallsResponseDtoImpl.fromJson(
          Map<String, dynamic> json) =>
      _$$ActiveGroupCallsResponseDtoImplFromJson(json);

  final List<GroupCallDto> _calls;
  @override
  @JsonKey()
  List<GroupCallDto> get calls {
    if (_calls is EqualUnmodifiableListView) return _calls;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_calls);
  }

  @override
  String toString() {
    return 'ActiveGroupCallsResponseDto(calls: $calls)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ActiveGroupCallsResponseDtoImpl &&
            const DeepCollectionEquality().equals(other._calls, _calls));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode =>
      Object.hash(runtimeType, const DeepCollectionEquality().hash(_calls));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ActiveGroupCallsResponseDtoImplCopyWith<_$ActiveGroupCallsResponseDtoImpl>
      get copyWith => __$$ActiveGroupCallsResponseDtoImplCopyWithImpl<
          _$ActiveGroupCallsResponseDtoImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ActiveGroupCallsResponseDtoImplToJson(
      this,
    );
  }
}

abstract class _ActiveGroupCallsResponseDto
    implements ActiveGroupCallsResponseDto {
  const factory _ActiveGroupCallsResponseDto({final List<GroupCallDto> calls}) =
      _$ActiveGroupCallsResponseDtoImpl;

  factory _ActiveGroupCallsResponseDto.fromJson(Map<String, dynamic> json) =
      _$ActiveGroupCallsResponseDtoImpl.fromJson;

  @override
  List<GroupCallDto> get calls;
  @override
  @JsonKey(ignore: true)
  _$$ActiveGroupCallsResponseDtoImplCopyWith<_$ActiveGroupCallsResponseDtoImpl>
      get copyWith => throw _privateConstructorUsedError;
}

GetGroupCallResponseDto _$GetGroupCallResponseDtoFromJson(
    Map<String, dynamic> json) {
  return _GetGroupCallResponseDto.fromJson(json);
}

/// @nodoc
mixin _$GetGroupCallResponseDto {
  GroupCallDto get groupCall => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $GetGroupCallResponseDtoCopyWith<GetGroupCallResponseDto> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $GetGroupCallResponseDtoCopyWith<$Res> {
  factory $GetGroupCallResponseDtoCopyWith(GetGroupCallResponseDto value,
          $Res Function(GetGroupCallResponseDto) then) =
      _$GetGroupCallResponseDtoCopyWithImpl<$Res, GetGroupCallResponseDto>;
  @useResult
  $Res call({GroupCallDto groupCall});

  $GroupCallDtoCopyWith<$Res> get groupCall;
}

/// @nodoc
class _$GetGroupCallResponseDtoCopyWithImpl<$Res,
        $Val extends GetGroupCallResponseDto>
    implements $GetGroupCallResponseDtoCopyWith<$Res> {
  _$GetGroupCallResponseDtoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? groupCall = null,
  }) {
    return _then(_value.copyWith(
      groupCall: null == groupCall
          ? _value.groupCall
          : groupCall // ignore: cast_nullable_to_non_nullable
              as GroupCallDto,
    ) as $Val);
  }

  @override
  @pragma('vm:prefer-inline')
  $GroupCallDtoCopyWith<$Res> get groupCall {
    return $GroupCallDtoCopyWith<$Res>(_value.groupCall, (value) {
      return _then(_value.copyWith(groupCall: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$GetGroupCallResponseDtoImplCopyWith<$Res>
    implements $GetGroupCallResponseDtoCopyWith<$Res> {
  factory _$$GetGroupCallResponseDtoImplCopyWith(
          _$GetGroupCallResponseDtoImpl value,
          $Res Function(_$GetGroupCallResponseDtoImpl) then) =
      __$$GetGroupCallResponseDtoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({GroupCallDto groupCall});

  @override
  $GroupCallDtoCopyWith<$Res> get groupCall;
}

/// @nodoc
class __$$GetGroupCallResponseDtoImplCopyWithImpl<$Res>
    extends _$GetGroupCallResponseDtoCopyWithImpl<$Res,
        _$GetGroupCallResponseDtoImpl>
    implements _$$GetGroupCallResponseDtoImplCopyWith<$Res> {
  __$$GetGroupCallResponseDtoImplCopyWithImpl(
      _$GetGroupCallResponseDtoImpl _value,
      $Res Function(_$GetGroupCallResponseDtoImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? groupCall = null,
  }) {
    return _then(_$GetGroupCallResponseDtoImpl(
      groupCall: null == groupCall
          ? _value.groupCall
          : groupCall // ignore: cast_nullable_to_non_nullable
              as GroupCallDto,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$GetGroupCallResponseDtoImpl implements _GetGroupCallResponseDto {
  const _$GetGroupCallResponseDtoImpl({required this.groupCall});

  factory _$GetGroupCallResponseDtoImpl.fromJson(Map<String, dynamic> json) =>
      _$$GetGroupCallResponseDtoImplFromJson(json);

  @override
  final GroupCallDto groupCall;

  @override
  String toString() {
    return 'GetGroupCallResponseDto(groupCall: $groupCall)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$GetGroupCallResponseDtoImpl &&
            (identical(other.groupCall, groupCall) ||
                other.groupCall == groupCall));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, groupCall);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$GetGroupCallResponseDtoImplCopyWith<_$GetGroupCallResponseDtoImpl>
      get copyWith => __$$GetGroupCallResponseDtoImplCopyWithImpl<
          _$GetGroupCallResponseDtoImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$GetGroupCallResponseDtoImplToJson(
      this,
    );
  }
}

abstract class _GetGroupCallResponseDto implements GetGroupCallResponseDto {
  const factory _GetGroupCallResponseDto(
      {required final GroupCallDto groupCall}) = _$GetGroupCallResponseDtoImpl;

  factory _GetGroupCallResponseDto.fromJson(Map<String, dynamic> json) =
      _$GetGroupCallResponseDtoImpl.fromJson;

  @override
  GroupCallDto get groupCall;
  @override
  @JsonKey(ignore: true)
  _$$GetGroupCallResponseDtoImplCopyWith<_$GetGroupCallResponseDtoImpl>
      get copyWith => throw _privateConstructorUsedError;
}

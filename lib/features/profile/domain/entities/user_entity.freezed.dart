// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'user_entity.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

AvailableBots _$AvailableBotsFromJson(Map<String, dynamic> json) {
  return _AvailableBots.fromJson(json);
}

/// @nodoc
mixin _$AvailableBots {
  bool get analyst => throw _privateConstructorUsedError;
  bool get outbound => throw _privateConstructorUsedError;
  bool get informer => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $AvailableBotsCopyWith<AvailableBots> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AvailableBotsCopyWith<$Res> {
  factory $AvailableBotsCopyWith(
          AvailableBots value, $Res Function(AvailableBots) then) =
      _$AvailableBotsCopyWithImpl<$Res, AvailableBots>;
  @useResult
  $Res call({bool analyst, bool outbound, bool informer});
}

/// @nodoc
class _$AvailableBotsCopyWithImpl<$Res, $Val extends AvailableBots>
    implements $AvailableBotsCopyWith<$Res> {
  _$AvailableBotsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? analyst = null,
    Object? outbound = null,
    Object? informer = null,
  }) {
    return _then(_value.copyWith(
      analyst: null == analyst
          ? _value.analyst
          : analyst // ignore: cast_nullable_to_non_nullable
              as bool,
      outbound: null == outbound
          ? _value.outbound
          : outbound // ignore: cast_nullable_to_non_nullable
              as bool,
      informer: null == informer
          ? _value.informer
          : informer // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$AvailableBotsImplCopyWith<$Res>
    implements $AvailableBotsCopyWith<$Res> {
  factory _$$AvailableBotsImplCopyWith(
          _$AvailableBotsImpl value, $Res Function(_$AvailableBotsImpl) then) =
      __$$AvailableBotsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({bool analyst, bool outbound, bool informer});
}

/// @nodoc
class __$$AvailableBotsImplCopyWithImpl<$Res>
    extends _$AvailableBotsCopyWithImpl<$Res, _$AvailableBotsImpl>
    implements _$$AvailableBotsImplCopyWith<$Res> {
  __$$AvailableBotsImplCopyWithImpl(
      _$AvailableBotsImpl _value, $Res Function(_$AvailableBotsImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? analyst = null,
    Object? outbound = null,
    Object? informer = null,
  }) {
    return _then(_$AvailableBotsImpl(
      analyst: null == analyst
          ? _value.analyst
          : analyst // ignore: cast_nullable_to_non_nullable
              as bool,
      outbound: null == outbound
          ? _value.outbound
          : outbound // ignore: cast_nullable_to_non_nullable
              as bool,
      informer: null == informer
          ? _value.informer
          : informer // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$AvailableBotsImpl implements _AvailableBots {
  const _$AvailableBotsImpl(
      {this.analyst = true, this.outbound = true, this.informer = false});

  factory _$AvailableBotsImpl.fromJson(Map<String, dynamic> json) =>
      _$$AvailableBotsImplFromJson(json);

  @override
  @JsonKey()
  final bool analyst;
  @override
  @JsonKey()
  final bool outbound;
  @override
  @JsonKey()
  final bool informer;

  @override
  String toString() {
    return 'AvailableBots(analyst: $analyst, outbound: $outbound, informer: $informer)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AvailableBotsImpl &&
            (identical(other.analyst, analyst) || other.analyst == analyst) &&
            (identical(other.outbound, outbound) ||
                other.outbound == outbound) &&
            (identical(other.informer, informer) ||
                other.informer == informer));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, analyst, outbound, informer);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$AvailableBotsImplCopyWith<_$AvailableBotsImpl> get copyWith =>
      __$$AvailableBotsImplCopyWithImpl<_$AvailableBotsImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$AvailableBotsImplToJson(
      this,
    );
  }
}

abstract class _AvailableBots implements AvailableBots {
  const factory _AvailableBots(
      {final bool analyst,
      final bool outbound,
      final bool informer}) = _$AvailableBotsImpl;

  factory _AvailableBots.fromJson(Map<String, dynamic> json) =
      _$AvailableBotsImpl.fromJson;

  @override
  bool get analyst;
  @override
  bool get outbound;
  @override
  bool get informer;
  @override
  @JsonKey(ignore: true)
  _$$AvailableBotsImplCopyWith<_$AvailableBotsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

UserEntity _$UserEntityFromJson(Map<String, dynamic> json) {
  return _UserEntity.fromJson(json);
}

/// @nodoc
mixin _$UserEntity {
  String get id => throw _privateConstructorUsedError;
  String get email => throw _privateConstructorUsedError;
  String? get phone => throw _privateConstructorUsedError;
  String? get firstName => throw _privateConstructorUsedError;
  String? get lastName => throw _privateConstructorUsedError;
  String? get middleName => throw _privateConstructorUsedError;
  String? get country => throw _privateConstructorUsedError;
  String? get avatarUrl => throw _privateConstructorUsedError;
  String? get postalCode => throw _privateConstructorUsedError;
  String? get dateOfBirth => throw _privateConstructorUsedError;
  KycStatus get kycStatus => throw _privateConstructorUsedError;
  bool get emailVerified => throw _privateConstructorUsedError;
  String? get fcmToken => throw _privateConstructorUsedError;
  String? get username => throw _privateConstructorUsedError;
  String? get status => throw _privateConstructorUsedError;
  bool get aiTwinEnabled => throw _privateConstructorUsedError;
  int get aiTwinTimeoutSeconds => throw _privateConstructorUsedError;
  String? get aiTwinPrompt => throw _privateConstructorUsedError;
  String? get aiTwinVoiceId => throw _privateConstructorUsedError;
  String get lastSeenPrivacy => throw _privateConstructorUsedError;
  AvailableBots get availableBots => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $UserEntityCopyWith<UserEntity> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UserEntityCopyWith<$Res> {
  factory $UserEntityCopyWith(
          UserEntity value, $Res Function(UserEntity) then) =
      _$UserEntityCopyWithImpl<$Res, UserEntity>;
  @useResult
  $Res call(
      {String id,
      String email,
      String? phone,
      String? firstName,
      String? lastName,
      String? middleName,
      String? country,
      String? avatarUrl,
      String? postalCode,
      String? dateOfBirth,
      KycStatus kycStatus,
      bool emailVerified,
      String? fcmToken,
      String? username,
      String? status,
      bool aiTwinEnabled,
      int aiTwinTimeoutSeconds,
      String? aiTwinPrompt,
      String? aiTwinVoiceId,
      String lastSeenPrivacy,
      AvailableBots availableBots});

  $AvailableBotsCopyWith<$Res> get availableBots;
}

/// @nodoc
class _$UserEntityCopyWithImpl<$Res, $Val extends UserEntity>
    implements $UserEntityCopyWith<$Res> {
  _$UserEntityCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? email = null,
    Object? phone = freezed,
    Object? firstName = freezed,
    Object? lastName = freezed,
    Object? middleName = freezed,
    Object? country = freezed,
    Object? avatarUrl = freezed,
    Object? postalCode = freezed,
    Object? dateOfBirth = freezed,
    Object? kycStatus = null,
    Object? emailVerified = null,
    Object? fcmToken = freezed,
    Object? username = freezed,
    Object? status = freezed,
    Object? aiTwinEnabled = null,
    Object? aiTwinTimeoutSeconds = null,
    Object? aiTwinPrompt = freezed,
    Object? aiTwinVoiceId = freezed,
    Object? lastSeenPrivacy = null,
    Object? availableBots = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      email: null == email
          ? _value.email
          : email // ignore: cast_nullable_to_non_nullable
              as String,
      phone: freezed == phone
          ? _value.phone
          : phone // ignore: cast_nullable_to_non_nullable
              as String?,
      firstName: freezed == firstName
          ? _value.firstName
          : firstName // ignore: cast_nullable_to_non_nullable
              as String?,
      lastName: freezed == lastName
          ? _value.lastName
          : lastName // ignore: cast_nullable_to_non_nullable
              as String?,
      middleName: freezed == middleName
          ? _value.middleName
          : middleName // ignore: cast_nullable_to_non_nullable
              as String?,
      country: freezed == country
          ? _value.country
          : country // ignore: cast_nullable_to_non_nullable
              as String?,
      avatarUrl: freezed == avatarUrl
          ? _value.avatarUrl
          : avatarUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      postalCode: freezed == postalCode
          ? _value.postalCode
          : postalCode // ignore: cast_nullable_to_non_nullable
              as String?,
      dateOfBirth: freezed == dateOfBirth
          ? _value.dateOfBirth
          : dateOfBirth // ignore: cast_nullable_to_non_nullable
              as String?,
      kycStatus: null == kycStatus
          ? _value.kycStatus
          : kycStatus // ignore: cast_nullable_to_non_nullable
              as KycStatus,
      emailVerified: null == emailVerified
          ? _value.emailVerified
          : emailVerified // ignore: cast_nullable_to_non_nullable
              as bool,
      fcmToken: freezed == fcmToken
          ? _value.fcmToken
          : fcmToken // ignore: cast_nullable_to_non_nullable
              as String?,
      username: freezed == username
          ? _value.username
          : username // ignore: cast_nullable_to_non_nullable
              as String?,
      status: freezed == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String?,
      aiTwinEnabled: null == aiTwinEnabled
          ? _value.aiTwinEnabled
          : aiTwinEnabled // ignore: cast_nullable_to_non_nullable
              as bool,
      aiTwinTimeoutSeconds: null == aiTwinTimeoutSeconds
          ? _value.aiTwinTimeoutSeconds
          : aiTwinTimeoutSeconds // ignore: cast_nullable_to_non_nullable
              as int,
      aiTwinPrompt: freezed == aiTwinPrompt
          ? _value.aiTwinPrompt
          : aiTwinPrompt // ignore: cast_nullable_to_non_nullable
              as String?,
      aiTwinVoiceId: freezed == aiTwinVoiceId
          ? _value.aiTwinVoiceId
          : aiTwinVoiceId // ignore: cast_nullable_to_non_nullable
              as String?,
      lastSeenPrivacy: null == lastSeenPrivacy
          ? _value.lastSeenPrivacy
          : lastSeenPrivacy // ignore: cast_nullable_to_non_nullable
              as String,
      availableBots: null == availableBots
          ? _value.availableBots
          : availableBots // ignore: cast_nullable_to_non_nullable
              as AvailableBots,
    ) as $Val);
  }

  @override
  @pragma('vm:prefer-inline')
  $AvailableBotsCopyWith<$Res> get availableBots {
    return $AvailableBotsCopyWith<$Res>(_value.availableBots, (value) {
      return _then(_value.copyWith(availableBots: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$UserEntityImplCopyWith<$Res>
    implements $UserEntityCopyWith<$Res> {
  factory _$$UserEntityImplCopyWith(
          _$UserEntityImpl value, $Res Function(_$UserEntityImpl) then) =
      __$$UserEntityImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String email,
      String? phone,
      String? firstName,
      String? lastName,
      String? middleName,
      String? country,
      String? avatarUrl,
      String? postalCode,
      String? dateOfBirth,
      KycStatus kycStatus,
      bool emailVerified,
      String? fcmToken,
      String? username,
      String? status,
      bool aiTwinEnabled,
      int aiTwinTimeoutSeconds,
      String? aiTwinPrompt,
      String? aiTwinVoiceId,
      String lastSeenPrivacy,
      AvailableBots availableBots});

  @override
  $AvailableBotsCopyWith<$Res> get availableBots;
}

/// @nodoc
class __$$UserEntityImplCopyWithImpl<$Res>
    extends _$UserEntityCopyWithImpl<$Res, _$UserEntityImpl>
    implements _$$UserEntityImplCopyWith<$Res> {
  __$$UserEntityImplCopyWithImpl(
      _$UserEntityImpl _value, $Res Function(_$UserEntityImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? email = null,
    Object? phone = freezed,
    Object? firstName = freezed,
    Object? lastName = freezed,
    Object? middleName = freezed,
    Object? country = freezed,
    Object? avatarUrl = freezed,
    Object? postalCode = freezed,
    Object? dateOfBirth = freezed,
    Object? kycStatus = null,
    Object? emailVerified = null,
    Object? fcmToken = freezed,
    Object? username = freezed,
    Object? status = freezed,
    Object? aiTwinEnabled = null,
    Object? aiTwinTimeoutSeconds = null,
    Object? aiTwinPrompt = freezed,
    Object? aiTwinVoiceId = freezed,
    Object? lastSeenPrivacy = null,
    Object? availableBots = null,
  }) {
    return _then(_$UserEntityImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      email: null == email
          ? _value.email
          : email // ignore: cast_nullable_to_non_nullable
              as String,
      phone: freezed == phone
          ? _value.phone
          : phone // ignore: cast_nullable_to_non_nullable
              as String?,
      firstName: freezed == firstName
          ? _value.firstName
          : firstName // ignore: cast_nullable_to_non_nullable
              as String?,
      lastName: freezed == lastName
          ? _value.lastName
          : lastName // ignore: cast_nullable_to_non_nullable
              as String?,
      middleName: freezed == middleName
          ? _value.middleName
          : middleName // ignore: cast_nullable_to_non_nullable
              as String?,
      country: freezed == country
          ? _value.country
          : country // ignore: cast_nullable_to_non_nullable
              as String?,
      avatarUrl: freezed == avatarUrl
          ? _value.avatarUrl
          : avatarUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      postalCode: freezed == postalCode
          ? _value.postalCode
          : postalCode // ignore: cast_nullable_to_non_nullable
              as String?,
      dateOfBirth: freezed == dateOfBirth
          ? _value.dateOfBirth
          : dateOfBirth // ignore: cast_nullable_to_non_nullable
              as String?,
      kycStatus: null == kycStatus
          ? _value.kycStatus
          : kycStatus // ignore: cast_nullable_to_non_nullable
              as KycStatus,
      emailVerified: null == emailVerified
          ? _value.emailVerified
          : emailVerified // ignore: cast_nullable_to_non_nullable
              as bool,
      fcmToken: freezed == fcmToken
          ? _value.fcmToken
          : fcmToken // ignore: cast_nullable_to_non_nullable
              as String?,
      username: freezed == username
          ? _value.username
          : username // ignore: cast_nullable_to_non_nullable
              as String?,
      status: freezed == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String?,
      aiTwinEnabled: null == aiTwinEnabled
          ? _value.aiTwinEnabled
          : aiTwinEnabled // ignore: cast_nullable_to_non_nullable
              as bool,
      aiTwinTimeoutSeconds: null == aiTwinTimeoutSeconds
          ? _value.aiTwinTimeoutSeconds
          : aiTwinTimeoutSeconds // ignore: cast_nullable_to_non_nullable
              as int,
      aiTwinPrompt: freezed == aiTwinPrompt
          ? _value.aiTwinPrompt
          : aiTwinPrompt // ignore: cast_nullable_to_non_nullable
              as String?,
      aiTwinVoiceId: freezed == aiTwinVoiceId
          ? _value.aiTwinVoiceId
          : aiTwinVoiceId // ignore: cast_nullable_to_non_nullable
              as String?,
      lastSeenPrivacy: null == lastSeenPrivacy
          ? _value.lastSeenPrivacy
          : lastSeenPrivacy // ignore: cast_nullable_to_non_nullable
              as String,
      availableBots: null == availableBots
          ? _value.availableBots
          : availableBots // ignore: cast_nullable_to_non_nullable
              as AvailableBots,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$UserEntityImpl implements _UserEntity {
  const _$UserEntityImpl(
      {required this.id,
      required this.email,
      this.phone,
      this.firstName,
      this.lastName,
      this.middleName,
      this.country,
      this.avatarUrl,
      this.postalCode,
      this.dateOfBirth,
      this.kycStatus = KycStatus.unverified,
      this.emailVerified = false,
      this.fcmToken,
      this.username,
      this.status,
      this.aiTwinEnabled = false,
      this.aiTwinTimeoutSeconds = 30,
      this.aiTwinPrompt,
      this.aiTwinVoiceId,
      this.lastSeenPrivacy = 'EVERYONE',
      this.availableBots = const AvailableBots()});

  factory _$UserEntityImpl.fromJson(Map<String, dynamic> json) =>
      _$$UserEntityImplFromJson(json);

  @override
  final String id;
  @override
  final String email;
  @override
  final String? phone;
  @override
  final String? firstName;
  @override
  final String? lastName;
  @override
  final String? middleName;
  @override
  final String? country;
  @override
  final String? avatarUrl;
  @override
  final String? postalCode;
  @override
  final String? dateOfBirth;
  @override
  @JsonKey()
  final KycStatus kycStatus;
  @override
  @JsonKey()
  final bool emailVerified;
  @override
  final String? fcmToken;
  @override
  final String? username;
  @override
  final String? status;
  @override
  @JsonKey()
  final bool aiTwinEnabled;
  @override
  @JsonKey()
  final int aiTwinTimeoutSeconds;
  @override
  final String? aiTwinPrompt;
  @override
  final String? aiTwinVoiceId;
  @override
  @JsonKey()
  final String lastSeenPrivacy;
  @override
  @JsonKey()
  final AvailableBots availableBots;

  @override
  String toString() {
    return 'UserEntity(id: $id, email: $email, phone: $phone, firstName: $firstName, lastName: $lastName, middleName: $middleName, country: $country, avatarUrl: $avatarUrl, postalCode: $postalCode, dateOfBirth: $dateOfBirth, kycStatus: $kycStatus, emailVerified: $emailVerified, fcmToken: $fcmToken, username: $username, status: $status, aiTwinEnabled: $aiTwinEnabled, aiTwinTimeoutSeconds: $aiTwinTimeoutSeconds, aiTwinPrompt: $aiTwinPrompt, aiTwinVoiceId: $aiTwinVoiceId, lastSeenPrivacy: $lastSeenPrivacy, availableBots: $availableBots)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UserEntityImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.email, email) || other.email == email) &&
            (identical(other.phone, phone) || other.phone == phone) &&
            (identical(other.firstName, firstName) ||
                other.firstName == firstName) &&
            (identical(other.lastName, lastName) ||
                other.lastName == lastName) &&
            (identical(other.middleName, middleName) ||
                other.middleName == middleName) &&
            (identical(other.country, country) || other.country == country) &&
            (identical(other.avatarUrl, avatarUrl) ||
                other.avatarUrl == avatarUrl) &&
            (identical(other.postalCode, postalCode) ||
                other.postalCode == postalCode) &&
            (identical(other.dateOfBirth, dateOfBirth) ||
                other.dateOfBirth == dateOfBirth) &&
            (identical(other.kycStatus, kycStatus) ||
                other.kycStatus == kycStatus) &&
            (identical(other.emailVerified, emailVerified) ||
                other.emailVerified == emailVerified) &&
            (identical(other.fcmToken, fcmToken) ||
                other.fcmToken == fcmToken) &&
            (identical(other.username, username) ||
                other.username == username) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.aiTwinEnabled, aiTwinEnabled) ||
                other.aiTwinEnabled == aiTwinEnabled) &&
            (identical(other.aiTwinTimeoutSeconds, aiTwinTimeoutSeconds) ||
                other.aiTwinTimeoutSeconds == aiTwinTimeoutSeconds) &&
            (identical(other.aiTwinPrompt, aiTwinPrompt) ||
                other.aiTwinPrompt == aiTwinPrompt) &&
            (identical(other.aiTwinVoiceId, aiTwinVoiceId) ||
                other.aiTwinVoiceId == aiTwinVoiceId) &&
            (identical(other.lastSeenPrivacy, lastSeenPrivacy) ||
                other.lastSeenPrivacy == lastSeenPrivacy) &&
            (identical(other.availableBots, availableBots) ||
                other.availableBots == availableBots));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hashAll([
        runtimeType,
        id,
        email,
        phone,
        firstName,
        lastName,
        middleName,
        country,
        avatarUrl,
        postalCode,
        dateOfBirth,
        kycStatus,
        emailVerified,
        fcmToken,
        username,
        status,
        aiTwinEnabled,
        aiTwinTimeoutSeconds,
        aiTwinPrompt,
        aiTwinVoiceId,
        lastSeenPrivacy,
        availableBots
      ]);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$UserEntityImplCopyWith<_$UserEntityImpl> get copyWith =>
      __$$UserEntityImplCopyWithImpl<_$UserEntityImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$UserEntityImplToJson(
      this,
    );
  }
}

abstract class _UserEntity implements UserEntity {
  const factory _UserEntity(
      {required final String id,
      required final String email,
      final String? phone,
      final String? firstName,
      final String? lastName,
      final String? middleName,
      final String? country,
      final String? avatarUrl,
      final String? postalCode,
      final String? dateOfBirth,
      final KycStatus kycStatus,
      final bool emailVerified,
      final String? fcmToken,
      final String? username,
      final String? status,
      final bool aiTwinEnabled,
      final int aiTwinTimeoutSeconds,
      final String? aiTwinPrompt,
      final String? aiTwinVoiceId,
      final String lastSeenPrivacy,
      final AvailableBots availableBots}) = _$UserEntityImpl;

  factory _UserEntity.fromJson(Map<String, dynamic> json) =
      _$UserEntityImpl.fromJson;

  @override
  String get id;
  @override
  String get email;
  @override
  String? get phone;
  @override
  String? get firstName;
  @override
  String? get lastName;
  @override
  String? get middleName;
  @override
  String? get country;
  @override
  String? get avatarUrl;
  @override
  String? get postalCode;
  @override
  String? get dateOfBirth;
  @override
  KycStatus get kycStatus;
  @override
  bool get emailVerified;
  @override
  String? get fcmToken;
  @override
  String? get username;
  @override
  String? get status;
  @override
  bool get aiTwinEnabled;
  @override
  int get aiTwinTimeoutSeconds;
  @override
  String? get aiTwinPrompt;
  @override
  String? get aiTwinVoiceId;
  @override
  String get lastSeenPrivacy;
  @override
  AvailableBots get availableBots;
  @override
  @JsonKey(ignore: true)
  _$$UserEntityImplCopyWith<_$UserEntityImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

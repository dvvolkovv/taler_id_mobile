// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'channel_details.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

ChannelDetails _$ChannelDetailsFromJson(Map<String, dynamic> json) {
  return _ChannelDetails.fromJson(json);
}

/// @nodoc
mixin _$ChannelDetails {
  String get id => throw _privateConstructorUsedError;
  String? get name => throw _privateConstructorUsedError;
  String? get description => throw _privateConstructorUsedError;
  String? get avatarUrl => throw _privateConstructorUsedError;
  int get subscribersCount => throw _privateConstructorUsedError;
  bool get isSubscribed => throw _privateConstructorUsedError;
  String? get myRole => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $ChannelDetailsCopyWith<ChannelDetails> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ChannelDetailsCopyWith<$Res> {
  factory $ChannelDetailsCopyWith(
          ChannelDetails value, $Res Function(ChannelDetails) then) =
      _$ChannelDetailsCopyWithImpl<$Res, ChannelDetails>;
  @useResult
  $Res call(
      {String id,
      String? name,
      String? description,
      String? avatarUrl,
      int subscribersCount,
      bool isSubscribed,
      String? myRole});
}

/// @nodoc
class _$ChannelDetailsCopyWithImpl<$Res, $Val extends ChannelDetails>
    implements $ChannelDetailsCopyWith<$Res> {
  _$ChannelDetailsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = freezed,
    Object? description = freezed,
    Object? avatarUrl = freezed,
    Object? subscribersCount = null,
    Object? isSubscribed = null,
    Object? myRole = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: freezed == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String?,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      avatarUrl: freezed == avatarUrl
          ? _value.avatarUrl
          : avatarUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      subscribersCount: null == subscribersCount
          ? _value.subscribersCount
          : subscribersCount // ignore: cast_nullable_to_non_nullable
              as int,
      isSubscribed: null == isSubscribed
          ? _value.isSubscribed
          : isSubscribed // ignore: cast_nullable_to_non_nullable
              as bool,
      myRole: freezed == myRole
          ? _value.myRole
          : myRole // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ChannelDetailsImplCopyWith<$Res>
    implements $ChannelDetailsCopyWith<$Res> {
  factory _$$ChannelDetailsImplCopyWith(_$ChannelDetailsImpl value,
          $Res Function(_$ChannelDetailsImpl) then) =
      __$$ChannelDetailsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String? name,
      String? description,
      String? avatarUrl,
      int subscribersCount,
      bool isSubscribed,
      String? myRole});
}

/// @nodoc
class __$$ChannelDetailsImplCopyWithImpl<$Res>
    extends _$ChannelDetailsCopyWithImpl<$Res, _$ChannelDetailsImpl>
    implements _$$ChannelDetailsImplCopyWith<$Res> {
  __$$ChannelDetailsImplCopyWithImpl(
      _$ChannelDetailsImpl _value, $Res Function(_$ChannelDetailsImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = freezed,
    Object? description = freezed,
    Object? avatarUrl = freezed,
    Object? subscribersCount = null,
    Object? isSubscribed = null,
    Object? myRole = freezed,
  }) {
    return _then(_$ChannelDetailsImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: freezed == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String?,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      avatarUrl: freezed == avatarUrl
          ? _value.avatarUrl
          : avatarUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      subscribersCount: null == subscribersCount
          ? _value.subscribersCount
          : subscribersCount // ignore: cast_nullable_to_non_nullable
              as int,
      isSubscribed: null == isSubscribed
          ? _value.isSubscribed
          : isSubscribed // ignore: cast_nullable_to_non_nullable
              as bool,
      myRole: freezed == myRole
          ? _value.myRole
          : myRole // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ChannelDetailsImpl implements _ChannelDetails {
  const _$ChannelDetailsImpl(
      {required this.id,
      this.name,
      this.description,
      this.avatarUrl,
      this.subscribersCount = 0,
      this.isSubscribed = false,
      this.myRole});

  factory _$ChannelDetailsImpl.fromJson(Map<String, dynamic> json) =>
      _$$ChannelDetailsImplFromJson(json);

  @override
  final String id;
  @override
  final String? name;
  @override
  final String? description;
  @override
  final String? avatarUrl;
  @override
  @JsonKey()
  final int subscribersCount;
  @override
  @JsonKey()
  final bool isSubscribed;
  @override
  final String? myRole;

  @override
  String toString() {
    return 'ChannelDetails(id: $id, name: $name, description: $description, avatarUrl: $avatarUrl, subscribersCount: $subscribersCount, isSubscribed: $isSubscribed, myRole: $myRole)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ChannelDetailsImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.avatarUrl, avatarUrl) ||
                other.avatarUrl == avatarUrl) &&
            (identical(other.subscribersCount, subscribersCount) ||
                other.subscribersCount == subscribersCount) &&
            (identical(other.isSubscribed, isSubscribed) ||
                other.isSubscribed == isSubscribed) &&
            (identical(other.myRole, myRole) || other.myRole == myRole));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, id, name, description, avatarUrl,
      subscribersCount, isSubscribed, myRole);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ChannelDetailsImplCopyWith<_$ChannelDetailsImpl> get copyWith =>
      __$$ChannelDetailsImplCopyWithImpl<_$ChannelDetailsImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ChannelDetailsImplToJson(
      this,
    );
  }
}

abstract class _ChannelDetails implements ChannelDetails {
  const factory _ChannelDetails(
      {required final String id,
      final String? name,
      final String? description,
      final String? avatarUrl,
      final int subscribersCount,
      final bool isSubscribed,
      final String? myRole}) = _$ChannelDetailsImpl;

  factory _ChannelDetails.fromJson(Map<String, dynamic> json) =
      _$ChannelDetailsImpl.fromJson;

  @override
  String get id;
  @override
  String? get name;
  @override
  String? get description;
  @override
  String? get avatarUrl;
  @override
  int get subscribersCount;
  @override
  bool get isSubscribed;
  @override
  String? get myRole;
  @override
  @JsonKey(ignore: true)
  _$$ChannelDetailsImplCopyWith<_$ChannelDetailsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

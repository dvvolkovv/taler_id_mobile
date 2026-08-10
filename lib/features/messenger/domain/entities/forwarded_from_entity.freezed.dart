// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'forwarded_from_entity.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

ForwardedFromEntity _$ForwardedFromEntityFromJson(Map<String, dynamic> json) {
  return _ForwardedFromEntity.fromJson(json);
}

/// @nodoc
mixin _$ForwardedFromEntity {
  String? get userId => throw _privateConstructorUsedError;
  String? get name => throw _privateConstructorUsedError;
  String? get messageId => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $ForwardedFromEntityCopyWith<ForwardedFromEntity> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ForwardedFromEntityCopyWith<$Res> {
  factory $ForwardedFromEntityCopyWith(
          ForwardedFromEntity value, $Res Function(ForwardedFromEntity) then) =
      _$ForwardedFromEntityCopyWithImpl<$Res, ForwardedFromEntity>;
  @useResult
  $Res call({String? userId, String? name, String? messageId});
}

/// @nodoc
class _$ForwardedFromEntityCopyWithImpl<$Res, $Val extends ForwardedFromEntity>
    implements $ForwardedFromEntityCopyWith<$Res> {
  _$ForwardedFromEntityCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? userId = freezed,
    Object? name = freezed,
    Object? messageId = freezed,
  }) {
    return _then(_value.copyWith(
      userId: freezed == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String?,
      name: freezed == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String?,
      messageId: freezed == messageId
          ? _value.messageId
          : messageId // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ForwardedFromEntityImplCopyWith<$Res>
    implements $ForwardedFromEntityCopyWith<$Res> {
  factory _$$ForwardedFromEntityImplCopyWith(_$ForwardedFromEntityImpl value,
          $Res Function(_$ForwardedFromEntityImpl) then) =
      __$$ForwardedFromEntityImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String? userId, String? name, String? messageId});
}

/// @nodoc
class __$$ForwardedFromEntityImplCopyWithImpl<$Res>
    extends _$ForwardedFromEntityCopyWithImpl<$Res, _$ForwardedFromEntityImpl>
    implements _$$ForwardedFromEntityImplCopyWith<$Res> {
  __$$ForwardedFromEntityImplCopyWithImpl(_$ForwardedFromEntityImpl _value,
      $Res Function(_$ForwardedFromEntityImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? userId = freezed,
    Object? name = freezed,
    Object? messageId = freezed,
  }) {
    return _then(_$ForwardedFromEntityImpl(
      userId: freezed == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String?,
      name: freezed == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String?,
      messageId: freezed == messageId
          ? _value.messageId
          : messageId // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ForwardedFromEntityImpl implements _ForwardedFromEntity {
  const _$ForwardedFromEntityImpl({this.userId, this.name, this.messageId});

  factory _$ForwardedFromEntityImpl.fromJson(Map<String, dynamic> json) =>
      _$$ForwardedFromEntityImplFromJson(json);

  @override
  final String? userId;
  @override
  final String? name;
  @override
  final String? messageId;

  @override
  String toString() {
    return 'ForwardedFromEntity(userId: $userId, name: $name, messageId: $messageId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ForwardedFromEntityImpl &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.messageId, messageId) ||
                other.messageId == messageId));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, userId, name, messageId);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ForwardedFromEntityImplCopyWith<_$ForwardedFromEntityImpl> get copyWith =>
      __$$ForwardedFromEntityImplCopyWithImpl<_$ForwardedFromEntityImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ForwardedFromEntityImplToJson(
      this,
    );
  }
}

abstract class _ForwardedFromEntity implements ForwardedFromEntity {
  const factory _ForwardedFromEntity(
      {final String? userId,
      final String? name,
      final String? messageId}) = _$ForwardedFromEntityImpl;

  factory _ForwardedFromEntity.fromJson(Map<String, dynamic> json) =
      _$ForwardedFromEntityImpl.fromJson;

  @override
  String? get userId;
  @override
  String? get name;
  @override
  String? get messageId;
  @override
  @JsonKey(ignore: true)
  _$$ForwardedFromEntityImplCopyWith<_$ForwardedFromEntityImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

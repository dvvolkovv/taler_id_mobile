// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'presence_entity.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$PresenceEntity {
  bool? get isOnline => throw _privateConstructorUsedError;
  DateTime? get lastSeenAt => throw _privateConstructorUsedError;
  bool get hidden => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $PresenceEntityCopyWith<PresenceEntity> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PresenceEntityCopyWith<$Res> {
  factory $PresenceEntityCopyWith(
          PresenceEntity value, $Res Function(PresenceEntity) then) =
      _$PresenceEntityCopyWithImpl<$Res, PresenceEntity>;
  @useResult
  $Res call({bool? isOnline, DateTime? lastSeenAt, bool hidden});
}

/// @nodoc
class _$PresenceEntityCopyWithImpl<$Res, $Val extends PresenceEntity>
    implements $PresenceEntityCopyWith<$Res> {
  _$PresenceEntityCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? isOnline = freezed,
    Object? lastSeenAt = freezed,
    Object? hidden = null,
  }) {
    return _then(_value.copyWith(
      isOnline: freezed == isOnline
          ? _value.isOnline
          : isOnline // ignore: cast_nullable_to_non_nullable
              as bool?,
      lastSeenAt: freezed == lastSeenAt
          ? _value.lastSeenAt
          : lastSeenAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      hidden: null == hidden
          ? _value.hidden
          : hidden // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$PresenceEntityImplCopyWith<$Res>
    implements $PresenceEntityCopyWith<$Res> {
  factory _$$PresenceEntityImplCopyWith(_$PresenceEntityImpl value,
          $Res Function(_$PresenceEntityImpl) then) =
      __$$PresenceEntityImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({bool? isOnline, DateTime? lastSeenAt, bool hidden});
}

/// @nodoc
class __$$PresenceEntityImplCopyWithImpl<$Res>
    extends _$PresenceEntityCopyWithImpl<$Res, _$PresenceEntityImpl>
    implements _$$PresenceEntityImplCopyWith<$Res> {
  __$$PresenceEntityImplCopyWithImpl(
      _$PresenceEntityImpl _value, $Res Function(_$PresenceEntityImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? isOnline = freezed,
    Object? lastSeenAt = freezed,
    Object? hidden = null,
  }) {
    return _then(_$PresenceEntityImpl(
      isOnline: freezed == isOnline
          ? _value.isOnline
          : isOnline // ignore: cast_nullable_to_non_nullable
              as bool?,
      lastSeenAt: freezed == lastSeenAt
          ? _value.lastSeenAt
          : lastSeenAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      hidden: null == hidden
          ? _value.hidden
          : hidden // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc

class _$PresenceEntityImpl implements _PresenceEntity {
  const _$PresenceEntityImpl(
      {required this.isOnline, required this.lastSeenAt, required this.hidden});

  @override
  final bool? isOnline;
  @override
  final DateTime? lastSeenAt;
  @override
  final bool hidden;

  @override
  String toString() {
    return 'PresenceEntity(isOnline: $isOnline, lastSeenAt: $lastSeenAt, hidden: $hidden)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PresenceEntityImpl &&
            (identical(other.isOnline, isOnline) ||
                other.isOnline == isOnline) &&
            (identical(other.lastSeenAt, lastSeenAt) ||
                other.lastSeenAt == lastSeenAt) &&
            (identical(other.hidden, hidden) || other.hidden == hidden));
  }

  @override
  int get hashCode => Object.hash(runtimeType, isOnline, lastSeenAt, hidden);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$PresenceEntityImplCopyWith<_$PresenceEntityImpl> get copyWith =>
      __$$PresenceEntityImplCopyWithImpl<_$PresenceEntityImpl>(
          this, _$identity);
}

abstract class _PresenceEntity implements PresenceEntity {
  const factory _PresenceEntity(
      {required final bool? isOnline,
      required final DateTime? lastSeenAt,
      required final bool hidden}) = _$PresenceEntityImpl;

  @override
  bool? get isOnline;
  @override
  DateTime? get lastSeenAt;
  @override
  bool get hidden;
  @override
  @JsonKey(ignore: true)
  _$$PresenceEntityImplCopyWith<_$PresenceEntityImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

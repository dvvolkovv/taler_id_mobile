// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'owner_voice_status.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

OwnerVoiceStatus _$OwnerVoiceStatusFromJson(Map<String, dynamic> json) {
  return _OwnerVoiceStatus.fromJson(json);
}

/// @nodoc
mixin _$OwnerVoiceStatus {
  bool get enrolled => throw _privateConstructorUsedError;
  String? get speakerId => throw _privateConstructorUsedError;
  DateTime? get enrolledAt => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $OwnerVoiceStatusCopyWith<OwnerVoiceStatus> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $OwnerVoiceStatusCopyWith<$Res> {
  factory $OwnerVoiceStatusCopyWith(
          OwnerVoiceStatus value, $Res Function(OwnerVoiceStatus) then) =
      _$OwnerVoiceStatusCopyWithImpl<$Res, OwnerVoiceStatus>;
  @useResult
  $Res call({bool enrolled, String? speakerId, DateTime? enrolledAt});
}

/// @nodoc
class _$OwnerVoiceStatusCopyWithImpl<$Res, $Val extends OwnerVoiceStatus>
    implements $OwnerVoiceStatusCopyWith<$Res> {
  _$OwnerVoiceStatusCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? enrolled = null,
    Object? speakerId = freezed,
    Object? enrolledAt = freezed,
  }) {
    return _then(_value.copyWith(
      enrolled: null == enrolled
          ? _value.enrolled
          : enrolled // ignore: cast_nullable_to_non_nullable
              as bool,
      speakerId: freezed == speakerId
          ? _value.speakerId
          : speakerId // ignore: cast_nullable_to_non_nullable
              as String?,
      enrolledAt: freezed == enrolledAt
          ? _value.enrolledAt
          : enrolledAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$OwnerVoiceStatusImplCopyWith<$Res>
    implements $OwnerVoiceStatusCopyWith<$Res> {
  factory _$$OwnerVoiceStatusImplCopyWith(_$OwnerVoiceStatusImpl value,
          $Res Function(_$OwnerVoiceStatusImpl) then) =
      __$$OwnerVoiceStatusImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({bool enrolled, String? speakerId, DateTime? enrolledAt});
}

/// @nodoc
class __$$OwnerVoiceStatusImplCopyWithImpl<$Res>
    extends _$OwnerVoiceStatusCopyWithImpl<$Res, _$OwnerVoiceStatusImpl>
    implements _$$OwnerVoiceStatusImplCopyWith<$Res> {
  __$$OwnerVoiceStatusImplCopyWithImpl(_$OwnerVoiceStatusImpl _value,
      $Res Function(_$OwnerVoiceStatusImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? enrolled = null,
    Object? speakerId = freezed,
    Object? enrolledAt = freezed,
  }) {
    return _then(_$OwnerVoiceStatusImpl(
      enrolled: null == enrolled
          ? _value.enrolled
          : enrolled // ignore: cast_nullable_to_non_nullable
              as bool,
      speakerId: freezed == speakerId
          ? _value.speakerId
          : speakerId // ignore: cast_nullable_to_non_nullable
              as String?,
      enrolledAt: freezed == enrolledAt
          ? _value.enrolledAt
          : enrolledAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$OwnerVoiceStatusImpl implements _OwnerVoiceStatus {
  const _$OwnerVoiceStatusImpl(
      {required this.enrolled, this.speakerId, this.enrolledAt});

  factory _$OwnerVoiceStatusImpl.fromJson(Map<String, dynamic> json) =>
      _$$OwnerVoiceStatusImplFromJson(json);

  @override
  final bool enrolled;
  @override
  final String? speakerId;
  @override
  final DateTime? enrolledAt;

  @override
  String toString() {
    return 'OwnerVoiceStatus(enrolled: $enrolled, speakerId: $speakerId, enrolledAt: $enrolledAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$OwnerVoiceStatusImpl &&
            (identical(other.enrolled, enrolled) ||
                other.enrolled == enrolled) &&
            (identical(other.speakerId, speakerId) ||
                other.speakerId == speakerId) &&
            (identical(other.enrolledAt, enrolledAt) ||
                other.enrolledAt == enrolledAt));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, enrolled, speakerId, enrolledAt);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$OwnerVoiceStatusImplCopyWith<_$OwnerVoiceStatusImpl> get copyWith =>
      __$$OwnerVoiceStatusImplCopyWithImpl<_$OwnerVoiceStatusImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$OwnerVoiceStatusImplToJson(
      this,
    );
  }
}

abstract class _OwnerVoiceStatus implements OwnerVoiceStatus {
  const factory _OwnerVoiceStatus(
      {required final bool enrolled,
      final String? speakerId,
      final DateTime? enrolledAt}) = _$OwnerVoiceStatusImpl;

  factory _OwnerVoiceStatus.fromJson(Map<String, dynamic> json) =
      _$OwnerVoiceStatusImpl.fromJson;

  @override
  bool get enrolled;
  @override
  String? get speakerId;
  @override
  DateTime? get enrolledAt;
  @override
  @JsonKey(ignore: true)
  _$$OwnerVoiceStatusImplCopyWith<_$OwnerVoiceStatusImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

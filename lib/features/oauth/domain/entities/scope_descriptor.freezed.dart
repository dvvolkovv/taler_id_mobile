// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'scope_descriptor.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

ScopeDescriptor _$ScopeDescriptorFromJson(Map<String, dynamic> json) {
  return _ScopeDescriptor.fromJson(json);
}

/// @nodoc
mixin _$ScopeDescriptor {
  String get key => throw _privateConstructorUsedError;
  String get label => throw _privateConstructorUsedError;
  String get description => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $ScopeDescriptorCopyWith<ScopeDescriptor> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ScopeDescriptorCopyWith<$Res> {
  factory $ScopeDescriptorCopyWith(
          ScopeDescriptor value, $Res Function(ScopeDescriptor) then) =
      _$ScopeDescriptorCopyWithImpl<$Res, ScopeDescriptor>;
  @useResult
  $Res call({String key, String label, String description});
}

/// @nodoc
class _$ScopeDescriptorCopyWithImpl<$Res, $Val extends ScopeDescriptor>
    implements $ScopeDescriptorCopyWith<$Res> {
  _$ScopeDescriptorCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? key = null,
    Object? label = null,
    Object? description = null,
  }) {
    return _then(_value.copyWith(
      key: null == key
          ? _value.key
          : key // ignore: cast_nullable_to_non_nullable
              as String,
      label: null == label
          ? _value.label
          : label // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ScopeDescriptorImplCopyWith<$Res>
    implements $ScopeDescriptorCopyWith<$Res> {
  factory _$$ScopeDescriptorImplCopyWith(_$ScopeDescriptorImpl value,
          $Res Function(_$ScopeDescriptorImpl) then) =
      __$$ScopeDescriptorImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String key, String label, String description});
}

/// @nodoc
class __$$ScopeDescriptorImplCopyWithImpl<$Res>
    extends _$ScopeDescriptorCopyWithImpl<$Res, _$ScopeDescriptorImpl>
    implements _$$ScopeDescriptorImplCopyWith<$Res> {
  __$$ScopeDescriptorImplCopyWithImpl(
      _$ScopeDescriptorImpl _value, $Res Function(_$ScopeDescriptorImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? key = null,
    Object? label = null,
    Object? description = null,
  }) {
    return _then(_$ScopeDescriptorImpl(
      key: null == key
          ? _value.key
          : key // ignore: cast_nullable_to_non_nullable
              as String,
      label: null == label
          ? _value.label
          : label // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ScopeDescriptorImpl implements _ScopeDescriptor {
  const _$ScopeDescriptorImpl(
      {required this.key, required this.label, required this.description});

  factory _$ScopeDescriptorImpl.fromJson(Map<String, dynamic> json) =>
      _$$ScopeDescriptorImplFromJson(json);

  @override
  final String key;
  @override
  final String label;
  @override
  final String description;

  @override
  String toString() {
    return 'ScopeDescriptor(key: $key, label: $label, description: $description)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ScopeDescriptorImpl &&
            (identical(other.key, key) || other.key == key) &&
            (identical(other.label, label) || other.label == label) &&
            (identical(other.description, description) ||
                other.description == description));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, key, label, description);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ScopeDescriptorImplCopyWith<_$ScopeDescriptorImpl> get copyWith =>
      __$$ScopeDescriptorImplCopyWithImpl<_$ScopeDescriptorImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ScopeDescriptorImplToJson(
      this,
    );
  }
}

abstract class _ScopeDescriptor implements ScopeDescriptor {
  const factory _ScopeDescriptor(
      {required final String key,
      required final String label,
      required final String description}) = _$ScopeDescriptorImpl;

  factory _ScopeDescriptor.fromJson(Map<String, dynamic> json) =
      _$ScopeDescriptorImpl.fromJson;

  @override
  String get key;
  @override
  String get label;
  @override
  String get description;
  @override
  @JsonKey(ignore: true)
  _$$ScopeDescriptorImplCopyWith<_$ScopeDescriptorImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

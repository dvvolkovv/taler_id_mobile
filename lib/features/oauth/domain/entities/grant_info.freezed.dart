// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'grant_info.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

GrantInfo _$GrantInfoFromJson(Map<String, dynamic> json) {
  return _GrantInfo.fromJson(json);
}

/// @nodoc
mixin _$GrantInfo {
  @JsonKey(name: 'client_name')
  String get clientName => throw _privateConstructorUsedError;
  @JsonKey(name: 'client_logo')
  String? get clientLogo => throw _privateConstructorUsedError;
  List<ScopeDescriptor> get scopes => throw _privateConstructorUsedError;
  bool get remembered => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $GrantInfoCopyWith<GrantInfo> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $GrantInfoCopyWith<$Res> {
  factory $GrantInfoCopyWith(GrantInfo value, $Res Function(GrantInfo) then) =
      _$GrantInfoCopyWithImpl<$Res, GrantInfo>;
  @useResult
  $Res call(
      {@JsonKey(name: 'client_name') String clientName,
      @JsonKey(name: 'client_logo') String? clientLogo,
      List<ScopeDescriptor> scopes,
      bool remembered});
}

/// @nodoc
class _$GrantInfoCopyWithImpl<$Res, $Val extends GrantInfo>
    implements $GrantInfoCopyWith<$Res> {
  _$GrantInfoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? clientName = null,
    Object? clientLogo = freezed,
    Object? scopes = null,
    Object? remembered = null,
  }) {
    return _then(_value.copyWith(
      clientName: null == clientName
          ? _value.clientName
          : clientName // ignore: cast_nullable_to_non_nullable
              as String,
      clientLogo: freezed == clientLogo
          ? _value.clientLogo
          : clientLogo // ignore: cast_nullable_to_non_nullable
              as String?,
      scopes: null == scopes
          ? _value.scopes
          : scopes // ignore: cast_nullable_to_non_nullable
              as List<ScopeDescriptor>,
      remembered: null == remembered
          ? _value.remembered
          : remembered // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$GrantInfoImplCopyWith<$Res>
    implements $GrantInfoCopyWith<$Res> {
  factory _$$GrantInfoImplCopyWith(
          _$GrantInfoImpl value, $Res Function(_$GrantInfoImpl) then) =
      __$$GrantInfoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'client_name') String clientName,
      @JsonKey(name: 'client_logo') String? clientLogo,
      List<ScopeDescriptor> scopes,
      bool remembered});
}

/// @nodoc
class __$$GrantInfoImplCopyWithImpl<$Res>
    extends _$GrantInfoCopyWithImpl<$Res, _$GrantInfoImpl>
    implements _$$GrantInfoImplCopyWith<$Res> {
  __$$GrantInfoImplCopyWithImpl(
      _$GrantInfoImpl _value, $Res Function(_$GrantInfoImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? clientName = null,
    Object? clientLogo = freezed,
    Object? scopes = null,
    Object? remembered = null,
  }) {
    return _then(_$GrantInfoImpl(
      clientName: null == clientName
          ? _value.clientName
          : clientName // ignore: cast_nullable_to_non_nullable
              as String,
      clientLogo: freezed == clientLogo
          ? _value.clientLogo
          : clientLogo // ignore: cast_nullable_to_non_nullable
              as String?,
      scopes: null == scopes
          ? _value._scopes
          : scopes // ignore: cast_nullable_to_non_nullable
              as List<ScopeDescriptor>,
      remembered: null == remembered
          ? _value.remembered
          : remembered // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$GrantInfoImpl implements _GrantInfo {
  const _$GrantInfoImpl(
      {@JsonKey(name: 'client_name') required this.clientName,
      @JsonKey(name: 'client_logo') this.clientLogo,
      required final List<ScopeDescriptor> scopes,
      required this.remembered})
      : _scopes = scopes;

  factory _$GrantInfoImpl.fromJson(Map<String, dynamic> json) =>
      _$$GrantInfoImplFromJson(json);

  @override
  @JsonKey(name: 'client_name')
  final String clientName;
  @override
  @JsonKey(name: 'client_logo')
  final String? clientLogo;
  final List<ScopeDescriptor> _scopes;
  @override
  List<ScopeDescriptor> get scopes {
    if (_scopes is EqualUnmodifiableListView) return _scopes;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_scopes);
  }

  @override
  final bool remembered;

  @override
  String toString() {
    return 'GrantInfo(clientName: $clientName, clientLogo: $clientLogo, scopes: $scopes, remembered: $remembered)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$GrantInfoImpl &&
            (identical(other.clientName, clientName) ||
                other.clientName == clientName) &&
            (identical(other.clientLogo, clientLogo) ||
                other.clientLogo == clientLogo) &&
            const DeepCollectionEquality().equals(other._scopes, _scopes) &&
            (identical(other.remembered, remembered) ||
                other.remembered == remembered));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, clientName, clientLogo,
      const DeepCollectionEquality().hash(_scopes), remembered);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$GrantInfoImplCopyWith<_$GrantInfoImpl> get copyWith =>
      __$$GrantInfoImplCopyWithImpl<_$GrantInfoImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$GrantInfoImplToJson(
      this,
    );
  }
}

abstract class _GrantInfo implements GrantInfo {
  const factory _GrantInfo(
      {@JsonKey(name: 'client_name') required final String clientName,
      @JsonKey(name: 'client_logo') final String? clientLogo,
      required final List<ScopeDescriptor> scopes,
      required final bool remembered}) = _$GrantInfoImpl;

  factory _GrantInfo.fromJson(Map<String, dynamic> json) =
      _$GrantInfoImpl.fromJson;

  @override
  @JsonKey(name: 'client_name')
  String get clientName;
  @override
  @JsonKey(name: 'client_logo')
  String? get clientLogo;
  @override
  List<ScopeDescriptor> get scopes;
  @override
  bool get remembered;
  @override
  @JsonKey(ignore: true)
  _$$GrantInfoImplCopyWith<_$GrantInfoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

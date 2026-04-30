// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'group_call_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$GroupCallState {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() idle,
    required TResult Function() creating,
    required TResult Function(
            GroupCall groupCall, String livekitToken, String livekitWsUrl)
        inLobby,
    required TResult Function(GroupCall groupCall, String livekitToken,
            String livekitWsUrl, bool muteRequestedByHost)
        inActive,
    required TResult Function(String reason) ended,
    required TResult Function(String message) error,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? idle,
    TResult? Function()? creating,
    TResult? Function(
            GroupCall groupCall, String livekitToken, String livekitWsUrl)?
        inLobby,
    TResult? Function(GroupCall groupCall, String livekitToken,
            String livekitWsUrl, bool muteRequestedByHost)?
        inActive,
    TResult? Function(String reason)? ended,
    TResult? Function(String message)? error,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? idle,
    TResult Function()? creating,
    TResult Function(
            GroupCall groupCall, String livekitToken, String livekitWsUrl)?
        inLobby,
    TResult Function(GroupCall groupCall, String livekitToken,
            String livekitWsUrl, bool muteRequestedByHost)?
        inActive,
    TResult Function(String reason)? ended,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(Idle value) idle,
    required TResult Function(Creating value) creating,
    required TResult Function(InLobby value) inLobby,
    required TResult Function(InActive value) inActive,
    required TResult Function(Ended value) ended,
    required TResult Function(ErrorState value) error,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(Idle value)? idle,
    TResult? Function(Creating value)? creating,
    TResult? Function(InLobby value)? inLobby,
    TResult? Function(InActive value)? inActive,
    TResult? Function(Ended value)? ended,
    TResult? Function(ErrorState value)? error,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(Idle value)? idle,
    TResult Function(Creating value)? creating,
    TResult Function(InLobby value)? inLobby,
    TResult Function(InActive value)? inActive,
    TResult Function(Ended value)? ended,
    TResult Function(ErrorState value)? error,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $GroupCallStateCopyWith<$Res> {
  factory $GroupCallStateCopyWith(
          GroupCallState value, $Res Function(GroupCallState) then) =
      _$GroupCallStateCopyWithImpl<$Res, GroupCallState>;
}

/// @nodoc
class _$GroupCallStateCopyWithImpl<$Res, $Val extends GroupCallState>
    implements $GroupCallStateCopyWith<$Res> {
  _$GroupCallStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;
}

/// @nodoc
abstract class _$$IdleImplCopyWith<$Res> {
  factory _$$IdleImplCopyWith(
          _$IdleImpl value, $Res Function(_$IdleImpl) then) =
      __$$IdleImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$IdleImplCopyWithImpl<$Res>
    extends _$GroupCallStateCopyWithImpl<$Res, _$IdleImpl>
    implements _$$IdleImplCopyWith<$Res> {
  __$$IdleImplCopyWithImpl(_$IdleImpl _value, $Res Function(_$IdleImpl) _then)
      : super(_value, _then);
}

/// @nodoc

class _$IdleImpl implements Idle {
  const _$IdleImpl();

  @override
  String toString() {
    return 'GroupCallState.idle()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$IdleImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() idle,
    required TResult Function() creating,
    required TResult Function(
            GroupCall groupCall, String livekitToken, String livekitWsUrl)
        inLobby,
    required TResult Function(GroupCall groupCall, String livekitToken,
            String livekitWsUrl, bool muteRequestedByHost)
        inActive,
    required TResult Function(String reason) ended,
    required TResult Function(String message) error,
  }) {
    return idle();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? idle,
    TResult? Function()? creating,
    TResult? Function(
            GroupCall groupCall, String livekitToken, String livekitWsUrl)?
        inLobby,
    TResult? Function(GroupCall groupCall, String livekitToken,
            String livekitWsUrl, bool muteRequestedByHost)?
        inActive,
    TResult? Function(String reason)? ended,
    TResult? Function(String message)? error,
  }) {
    return idle?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? idle,
    TResult Function()? creating,
    TResult Function(
            GroupCall groupCall, String livekitToken, String livekitWsUrl)?
        inLobby,
    TResult Function(GroupCall groupCall, String livekitToken,
            String livekitWsUrl, bool muteRequestedByHost)?
        inActive,
    TResult Function(String reason)? ended,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) {
    if (idle != null) {
      return idle();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(Idle value) idle,
    required TResult Function(Creating value) creating,
    required TResult Function(InLobby value) inLobby,
    required TResult Function(InActive value) inActive,
    required TResult Function(Ended value) ended,
    required TResult Function(ErrorState value) error,
  }) {
    return idle(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(Idle value)? idle,
    TResult? Function(Creating value)? creating,
    TResult? Function(InLobby value)? inLobby,
    TResult? Function(InActive value)? inActive,
    TResult? Function(Ended value)? ended,
    TResult? Function(ErrorState value)? error,
  }) {
    return idle?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(Idle value)? idle,
    TResult Function(Creating value)? creating,
    TResult Function(InLobby value)? inLobby,
    TResult Function(InActive value)? inActive,
    TResult Function(Ended value)? ended,
    TResult Function(ErrorState value)? error,
    required TResult orElse(),
  }) {
    if (idle != null) {
      return idle(this);
    }
    return orElse();
  }
}

abstract class Idle implements GroupCallState {
  const factory Idle() = _$IdleImpl;
}

/// @nodoc
abstract class _$$CreatingImplCopyWith<$Res> {
  factory _$$CreatingImplCopyWith(
          _$CreatingImpl value, $Res Function(_$CreatingImpl) then) =
      __$$CreatingImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$CreatingImplCopyWithImpl<$Res>
    extends _$GroupCallStateCopyWithImpl<$Res, _$CreatingImpl>
    implements _$$CreatingImplCopyWith<$Res> {
  __$$CreatingImplCopyWithImpl(
      _$CreatingImpl _value, $Res Function(_$CreatingImpl) _then)
      : super(_value, _then);
}

/// @nodoc

class _$CreatingImpl implements Creating {
  const _$CreatingImpl();

  @override
  String toString() {
    return 'GroupCallState.creating()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$CreatingImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() idle,
    required TResult Function() creating,
    required TResult Function(
            GroupCall groupCall, String livekitToken, String livekitWsUrl)
        inLobby,
    required TResult Function(GroupCall groupCall, String livekitToken,
            String livekitWsUrl, bool muteRequestedByHost)
        inActive,
    required TResult Function(String reason) ended,
    required TResult Function(String message) error,
  }) {
    return creating();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? idle,
    TResult? Function()? creating,
    TResult? Function(
            GroupCall groupCall, String livekitToken, String livekitWsUrl)?
        inLobby,
    TResult? Function(GroupCall groupCall, String livekitToken,
            String livekitWsUrl, bool muteRequestedByHost)?
        inActive,
    TResult? Function(String reason)? ended,
    TResult? Function(String message)? error,
  }) {
    return creating?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? idle,
    TResult Function()? creating,
    TResult Function(
            GroupCall groupCall, String livekitToken, String livekitWsUrl)?
        inLobby,
    TResult Function(GroupCall groupCall, String livekitToken,
            String livekitWsUrl, bool muteRequestedByHost)?
        inActive,
    TResult Function(String reason)? ended,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) {
    if (creating != null) {
      return creating();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(Idle value) idle,
    required TResult Function(Creating value) creating,
    required TResult Function(InLobby value) inLobby,
    required TResult Function(InActive value) inActive,
    required TResult Function(Ended value) ended,
    required TResult Function(ErrorState value) error,
  }) {
    return creating(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(Idle value)? idle,
    TResult? Function(Creating value)? creating,
    TResult? Function(InLobby value)? inLobby,
    TResult? Function(InActive value)? inActive,
    TResult? Function(Ended value)? ended,
    TResult? Function(ErrorState value)? error,
  }) {
    return creating?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(Idle value)? idle,
    TResult Function(Creating value)? creating,
    TResult Function(InLobby value)? inLobby,
    TResult Function(InActive value)? inActive,
    TResult Function(Ended value)? ended,
    TResult Function(ErrorState value)? error,
    required TResult orElse(),
  }) {
    if (creating != null) {
      return creating(this);
    }
    return orElse();
  }
}

abstract class Creating implements GroupCallState {
  const factory Creating() = _$CreatingImpl;
}

/// @nodoc
abstract class _$$InLobbyImplCopyWith<$Res> {
  factory _$$InLobbyImplCopyWith(
          _$InLobbyImpl value, $Res Function(_$InLobbyImpl) then) =
      __$$InLobbyImplCopyWithImpl<$Res>;
  @useResult
  $Res call({GroupCall groupCall, String livekitToken, String livekitWsUrl});

  $GroupCallCopyWith<$Res> get groupCall;
}

/// @nodoc
class __$$InLobbyImplCopyWithImpl<$Res>
    extends _$GroupCallStateCopyWithImpl<$Res, _$InLobbyImpl>
    implements _$$InLobbyImplCopyWith<$Res> {
  __$$InLobbyImplCopyWithImpl(
      _$InLobbyImpl _value, $Res Function(_$InLobbyImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? groupCall = null,
    Object? livekitToken = null,
    Object? livekitWsUrl = null,
  }) {
    return _then(_$InLobbyImpl(
      groupCall: null == groupCall
          ? _value.groupCall
          : groupCall // ignore: cast_nullable_to_non_nullable
              as GroupCall,
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

  @override
  @pragma('vm:prefer-inline')
  $GroupCallCopyWith<$Res> get groupCall {
    return $GroupCallCopyWith<$Res>(_value.groupCall, (value) {
      return _then(_value.copyWith(groupCall: value));
    });
  }
}

/// @nodoc

class _$InLobbyImpl implements InLobby {
  const _$InLobbyImpl(
      {required this.groupCall,
      required this.livekitToken,
      required this.livekitWsUrl});

  @override
  final GroupCall groupCall;
  @override
  final String livekitToken;
  @override
  final String livekitWsUrl;

  @override
  String toString() {
    return 'GroupCallState.inLobby(groupCall: $groupCall, livekitToken: $livekitToken, livekitWsUrl: $livekitWsUrl)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$InLobbyImpl &&
            (identical(other.groupCall, groupCall) ||
                other.groupCall == groupCall) &&
            (identical(other.livekitToken, livekitToken) ||
                other.livekitToken == livekitToken) &&
            (identical(other.livekitWsUrl, livekitWsUrl) ||
                other.livekitWsUrl == livekitWsUrl));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, groupCall, livekitToken, livekitWsUrl);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$InLobbyImplCopyWith<_$InLobbyImpl> get copyWith =>
      __$$InLobbyImplCopyWithImpl<_$InLobbyImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() idle,
    required TResult Function() creating,
    required TResult Function(
            GroupCall groupCall, String livekitToken, String livekitWsUrl)
        inLobby,
    required TResult Function(GroupCall groupCall, String livekitToken,
            String livekitWsUrl, bool muteRequestedByHost)
        inActive,
    required TResult Function(String reason) ended,
    required TResult Function(String message) error,
  }) {
    return inLobby(groupCall, livekitToken, livekitWsUrl);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? idle,
    TResult? Function()? creating,
    TResult? Function(
            GroupCall groupCall, String livekitToken, String livekitWsUrl)?
        inLobby,
    TResult? Function(GroupCall groupCall, String livekitToken,
            String livekitWsUrl, bool muteRequestedByHost)?
        inActive,
    TResult? Function(String reason)? ended,
    TResult? Function(String message)? error,
  }) {
    return inLobby?.call(groupCall, livekitToken, livekitWsUrl);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? idle,
    TResult Function()? creating,
    TResult Function(
            GroupCall groupCall, String livekitToken, String livekitWsUrl)?
        inLobby,
    TResult Function(GroupCall groupCall, String livekitToken,
            String livekitWsUrl, bool muteRequestedByHost)?
        inActive,
    TResult Function(String reason)? ended,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) {
    if (inLobby != null) {
      return inLobby(groupCall, livekitToken, livekitWsUrl);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(Idle value) idle,
    required TResult Function(Creating value) creating,
    required TResult Function(InLobby value) inLobby,
    required TResult Function(InActive value) inActive,
    required TResult Function(Ended value) ended,
    required TResult Function(ErrorState value) error,
  }) {
    return inLobby(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(Idle value)? idle,
    TResult? Function(Creating value)? creating,
    TResult? Function(InLobby value)? inLobby,
    TResult? Function(InActive value)? inActive,
    TResult? Function(Ended value)? ended,
    TResult? Function(ErrorState value)? error,
  }) {
    return inLobby?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(Idle value)? idle,
    TResult Function(Creating value)? creating,
    TResult Function(InLobby value)? inLobby,
    TResult Function(InActive value)? inActive,
    TResult Function(Ended value)? ended,
    TResult Function(ErrorState value)? error,
    required TResult orElse(),
  }) {
    if (inLobby != null) {
      return inLobby(this);
    }
    return orElse();
  }
}

abstract class InLobby implements GroupCallState {
  const factory InLobby(
      {required final GroupCall groupCall,
      required final String livekitToken,
      required final String livekitWsUrl}) = _$InLobbyImpl;

  GroupCall get groupCall;
  String get livekitToken;
  String get livekitWsUrl;
  @JsonKey(ignore: true)
  _$$InLobbyImplCopyWith<_$InLobbyImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$InActiveImplCopyWith<$Res> {
  factory _$$InActiveImplCopyWith(
          _$InActiveImpl value, $Res Function(_$InActiveImpl) then) =
      __$$InActiveImplCopyWithImpl<$Res>;
  @useResult
  $Res call(
      {GroupCall groupCall,
      String livekitToken,
      String livekitWsUrl,
      bool muteRequestedByHost});

  $GroupCallCopyWith<$Res> get groupCall;
}

/// @nodoc
class __$$InActiveImplCopyWithImpl<$Res>
    extends _$GroupCallStateCopyWithImpl<$Res, _$InActiveImpl>
    implements _$$InActiveImplCopyWith<$Res> {
  __$$InActiveImplCopyWithImpl(
      _$InActiveImpl _value, $Res Function(_$InActiveImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? groupCall = null,
    Object? livekitToken = null,
    Object? livekitWsUrl = null,
    Object? muteRequestedByHost = null,
  }) {
    return _then(_$InActiveImpl(
      groupCall: null == groupCall
          ? _value.groupCall
          : groupCall // ignore: cast_nullable_to_non_nullable
              as GroupCall,
      livekitToken: null == livekitToken
          ? _value.livekitToken
          : livekitToken // ignore: cast_nullable_to_non_nullable
              as String,
      livekitWsUrl: null == livekitWsUrl
          ? _value.livekitWsUrl
          : livekitWsUrl // ignore: cast_nullable_to_non_nullable
              as String,
      muteRequestedByHost: null == muteRequestedByHost
          ? _value.muteRequestedByHost
          : muteRequestedByHost // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }

  @override
  @pragma('vm:prefer-inline')
  $GroupCallCopyWith<$Res> get groupCall {
    return $GroupCallCopyWith<$Res>(_value.groupCall, (value) {
      return _then(_value.copyWith(groupCall: value));
    });
  }
}

/// @nodoc

class _$InActiveImpl implements InActive {
  const _$InActiveImpl(
      {required this.groupCall,
      required this.livekitToken,
      required this.livekitWsUrl,
      this.muteRequestedByHost = false});

  @override
  final GroupCall groupCall;
  @override
  final String livekitToken;
  @override
  final String livekitWsUrl;
  @override
  @JsonKey()
  final bool muteRequestedByHost;

  @override
  String toString() {
    return 'GroupCallState.inActive(groupCall: $groupCall, livekitToken: $livekitToken, livekitWsUrl: $livekitWsUrl, muteRequestedByHost: $muteRequestedByHost)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$InActiveImpl &&
            (identical(other.groupCall, groupCall) ||
                other.groupCall == groupCall) &&
            (identical(other.livekitToken, livekitToken) ||
                other.livekitToken == livekitToken) &&
            (identical(other.livekitWsUrl, livekitWsUrl) ||
                other.livekitWsUrl == livekitWsUrl) &&
            (identical(other.muteRequestedByHost, muteRequestedByHost) ||
                other.muteRequestedByHost == muteRequestedByHost));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType, groupCall, livekitToken, livekitWsUrl, muteRequestedByHost);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$InActiveImplCopyWith<_$InActiveImpl> get copyWith =>
      __$$InActiveImplCopyWithImpl<_$InActiveImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() idle,
    required TResult Function() creating,
    required TResult Function(
            GroupCall groupCall, String livekitToken, String livekitWsUrl)
        inLobby,
    required TResult Function(GroupCall groupCall, String livekitToken,
            String livekitWsUrl, bool muteRequestedByHost)
        inActive,
    required TResult Function(String reason) ended,
    required TResult Function(String message) error,
  }) {
    return inActive(groupCall, livekitToken, livekitWsUrl, muteRequestedByHost);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? idle,
    TResult? Function()? creating,
    TResult? Function(
            GroupCall groupCall, String livekitToken, String livekitWsUrl)?
        inLobby,
    TResult? Function(GroupCall groupCall, String livekitToken,
            String livekitWsUrl, bool muteRequestedByHost)?
        inActive,
    TResult? Function(String reason)? ended,
    TResult? Function(String message)? error,
  }) {
    return inActive?.call(
        groupCall, livekitToken, livekitWsUrl, muteRequestedByHost);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? idle,
    TResult Function()? creating,
    TResult Function(
            GroupCall groupCall, String livekitToken, String livekitWsUrl)?
        inLobby,
    TResult Function(GroupCall groupCall, String livekitToken,
            String livekitWsUrl, bool muteRequestedByHost)?
        inActive,
    TResult Function(String reason)? ended,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) {
    if (inActive != null) {
      return inActive(
          groupCall, livekitToken, livekitWsUrl, muteRequestedByHost);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(Idle value) idle,
    required TResult Function(Creating value) creating,
    required TResult Function(InLobby value) inLobby,
    required TResult Function(InActive value) inActive,
    required TResult Function(Ended value) ended,
    required TResult Function(ErrorState value) error,
  }) {
    return inActive(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(Idle value)? idle,
    TResult? Function(Creating value)? creating,
    TResult? Function(InLobby value)? inLobby,
    TResult? Function(InActive value)? inActive,
    TResult? Function(Ended value)? ended,
    TResult? Function(ErrorState value)? error,
  }) {
    return inActive?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(Idle value)? idle,
    TResult Function(Creating value)? creating,
    TResult Function(InLobby value)? inLobby,
    TResult Function(InActive value)? inActive,
    TResult Function(Ended value)? ended,
    TResult Function(ErrorState value)? error,
    required TResult orElse(),
  }) {
    if (inActive != null) {
      return inActive(this);
    }
    return orElse();
  }
}

abstract class InActive implements GroupCallState {
  const factory InActive(
      {required final GroupCall groupCall,
      required final String livekitToken,
      required final String livekitWsUrl,
      final bool muteRequestedByHost}) = _$InActiveImpl;

  GroupCall get groupCall;
  String get livekitToken;
  String get livekitWsUrl;
  bool get muteRequestedByHost;
  @JsonKey(ignore: true)
  _$$InActiveImplCopyWith<_$InActiveImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$EndedImplCopyWith<$Res> {
  factory _$$EndedImplCopyWith(
          _$EndedImpl value, $Res Function(_$EndedImpl) then) =
      __$$EndedImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String reason});
}

/// @nodoc
class __$$EndedImplCopyWithImpl<$Res>
    extends _$GroupCallStateCopyWithImpl<$Res, _$EndedImpl>
    implements _$$EndedImplCopyWith<$Res> {
  __$$EndedImplCopyWithImpl(
      _$EndedImpl _value, $Res Function(_$EndedImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? reason = null,
  }) {
    return _then(_$EndedImpl(
      null == reason
          ? _value.reason
          : reason // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class _$EndedImpl implements Ended {
  const _$EndedImpl(this.reason);

  @override
  final String reason;

  @override
  String toString() {
    return 'GroupCallState.ended(reason: $reason)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$EndedImpl &&
            (identical(other.reason, reason) || other.reason == reason));
  }

  @override
  int get hashCode => Object.hash(runtimeType, reason);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$EndedImplCopyWith<_$EndedImpl> get copyWith =>
      __$$EndedImplCopyWithImpl<_$EndedImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() idle,
    required TResult Function() creating,
    required TResult Function(
            GroupCall groupCall, String livekitToken, String livekitWsUrl)
        inLobby,
    required TResult Function(GroupCall groupCall, String livekitToken,
            String livekitWsUrl, bool muteRequestedByHost)
        inActive,
    required TResult Function(String reason) ended,
    required TResult Function(String message) error,
  }) {
    return ended(reason);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? idle,
    TResult? Function()? creating,
    TResult? Function(
            GroupCall groupCall, String livekitToken, String livekitWsUrl)?
        inLobby,
    TResult? Function(GroupCall groupCall, String livekitToken,
            String livekitWsUrl, bool muteRequestedByHost)?
        inActive,
    TResult? Function(String reason)? ended,
    TResult? Function(String message)? error,
  }) {
    return ended?.call(reason);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? idle,
    TResult Function()? creating,
    TResult Function(
            GroupCall groupCall, String livekitToken, String livekitWsUrl)?
        inLobby,
    TResult Function(GroupCall groupCall, String livekitToken,
            String livekitWsUrl, bool muteRequestedByHost)?
        inActive,
    TResult Function(String reason)? ended,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) {
    if (ended != null) {
      return ended(reason);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(Idle value) idle,
    required TResult Function(Creating value) creating,
    required TResult Function(InLobby value) inLobby,
    required TResult Function(InActive value) inActive,
    required TResult Function(Ended value) ended,
    required TResult Function(ErrorState value) error,
  }) {
    return ended(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(Idle value)? idle,
    TResult? Function(Creating value)? creating,
    TResult? Function(InLobby value)? inLobby,
    TResult? Function(InActive value)? inActive,
    TResult? Function(Ended value)? ended,
    TResult? Function(ErrorState value)? error,
  }) {
    return ended?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(Idle value)? idle,
    TResult Function(Creating value)? creating,
    TResult Function(InLobby value)? inLobby,
    TResult Function(InActive value)? inActive,
    TResult Function(Ended value)? ended,
    TResult Function(ErrorState value)? error,
    required TResult orElse(),
  }) {
    if (ended != null) {
      return ended(this);
    }
    return orElse();
  }
}

abstract class Ended implements GroupCallState {
  const factory Ended(final String reason) = _$EndedImpl;

  String get reason;
  @JsonKey(ignore: true)
  _$$EndedImplCopyWith<_$EndedImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$ErrorStateImplCopyWith<$Res> {
  factory _$$ErrorStateImplCopyWith(
          _$ErrorStateImpl value, $Res Function(_$ErrorStateImpl) then) =
      __$$ErrorStateImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String message});
}

/// @nodoc
class __$$ErrorStateImplCopyWithImpl<$Res>
    extends _$GroupCallStateCopyWithImpl<$Res, _$ErrorStateImpl>
    implements _$$ErrorStateImplCopyWith<$Res> {
  __$$ErrorStateImplCopyWithImpl(
      _$ErrorStateImpl _value, $Res Function(_$ErrorStateImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? message = null,
  }) {
    return _then(_$ErrorStateImpl(
      null == message
          ? _value.message
          : message // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class _$ErrorStateImpl implements ErrorState {
  const _$ErrorStateImpl(this.message);

  @override
  final String message;

  @override
  String toString() {
    return 'GroupCallState.error(message: $message)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ErrorStateImpl &&
            (identical(other.message, message) || other.message == message));
  }

  @override
  int get hashCode => Object.hash(runtimeType, message);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ErrorStateImplCopyWith<_$ErrorStateImpl> get copyWith =>
      __$$ErrorStateImplCopyWithImpl<_$ErrorStateImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() idle,
    required TResult Function() creating,
    required TResult Function(
            GroupCall groupCall, String livekitToken, String livekitWsUrl)
        inLobby,
    required TResult Function(GroupCall groupCall, String livekitToken,
            String livekitWsUrl, bool muteRequestedByHost)
        inActive,
    required TResult Function(String reason) ended,
    required TResult Function(String message) error,
  }) {
    return error(message);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? idle,
    TResult? Function()? creating,
    TResult? Function(
            GroupCall groupCall, String livekitToken, String livekitWsUrl)?
        inLobby,
    TResult? Function(GroupCall groupCall, String livekitToken,
            String livekitWsUrl, bool muteRequestedByHost)?
        inActive,
    TResult? Function(String reason)? ended,
    TResult? Function(String message)? error,
  }) {
    return error?.call(message);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? idle,
    TResult Function()? creating,
    TResult Function(
            GroupCall groupCall, String livekitToken, String livekitWsUrl)?
        inLobby,
    TResult Function(GroupCall groupCall, String livekitToken,
            String livekitWsUrl, bool muteRequestedByHost)?
        inActive,
    TResult Function(String reason)? ended,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) {
    if (error != null) {
      return error(message);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(Idle value) idle,
    required TResult Function(Creating value) creating,
    required TResult Function(InLobby value) inLobby,
    required TResult Function(InActive value) inActive,
    required TResult Function(Ended value) ended,
    required TResult Function(ErrorState value) error,
  }) {
    return error(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(Idle value)? idle,
    TResult? Function(Creating value)? creating,
    TResult? Function(InLobby value)? inLobby,
    TResult? Function(InActive value)? inActive,
    TResult? Function(Ended value)? ended,
    TResult? Function(ErrorState value)? error,
  }) {
    return error?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(Idle value)? idle,
    TResult Function(Creating value)? creating,
    TResult Function(InLobby value)? inLobby,
    TResult Function(InActive value)? inActive,
    TResult Function(Ended value)? ended,
    TResult Function(ErrorState value)? error,
    required TResult orElse(),
  }) {
    if (error != null) {
      return error(this);
    }
    return orElse();
  }
}

abstract class ErrorState implements GroupCallState {
  const factory ErrorState(final String message) = _$ErrorStateImpl;

  String get message;
  @JsonKey(ignore: true)
  _$$ErrorStateImplCopyWith<_$ErrorStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

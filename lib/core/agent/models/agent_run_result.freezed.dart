// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'agent_run_result.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

AgentToolCall _$AgentToolCallFromJson(Map<String, dynamic> json) {
  return _AgentToolCall.fromJson(json);
}

/// @nodoc
mixin _$AgentToolCall {
  String get name => throw _privateConstructorUsedError;
  Map<String, dynamic> get input => throw _privateConstructorUsedError;
  String get output => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $AgentToolCallCopyWith<AgentToolCall> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AgentToolCallCopyWith<$Res> {
  factory $AgentToolCallCopyWith(
          AgentToolCall value, $Res Function(AgentToolCall) then) =
      _$AgentToolCallCopyWithImpl<$Res, AgentToolCall>;
  @useResult
  $Res call({String name, Map<String, dynamic> input, String output});
}

/// @nodoc
class _$AgentToolCallCopyWithImpl<$Res, $Val extends AgentToolCall>
    implements $AgentToolCallCopyWith<$Res> {
  _$AgentToolCallCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? input = null,
    Object? output = null,
  }) {
    return _then(_value.copyWith(
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      input: null == input
          ? _value.input
          : input // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      output: null == output
          ? _value.output
          : output // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$AgentToolCallImplCopyWith<$Res>
    implements $AgentToolCallCopyWith<$Res> {
  factory _$$AgentToolCallImplCopyWith(
          _$AgentToolCallImpl value, $Res Function(_$AgentToolCallImpl) then) =
      __$$AgentToolCallImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String name, Map<String, dynamic> input, String output});
}

/// @nodoc
class __$$AgentToolCallImplCopyWithImpl<$Res>
    extends _$AgentToolCallCopyWithImpl<$Res, _$AgentToolCallImpl>
    implements _$$AgentToolCallImplCopyWith<$Res> {
  __$$AgentToolCallImplCopyWithImpl(
      _$AgentToolCallImpl _value, $Res Function(_$AgentToolCallImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? input = null,
    Object? output = null,
  }) {
    return _then(_$AgentToolCallImpl(
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      input: null == input
          ? _value._input
          : input // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      output: null == output
          ? _value.output
          : output // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$AgentToolCallImpl implements _AgentToolCall {
  const _$AgentToolCallImpl(
      {required this.name,
      required final Map<String, dynamic> input,
      required this.output})
      : _input = input;

  factory _$AgentToolCallImpl.fromJson(Map<String, dynamic> json) =>
      _$$AgentToolCallImplFromJson(json);

  @override
  final String name;
  final Map<String, dynamic> _input;
  @override
  Map<String, dynamic> get input {
    if (_input is EqualUnmodifiableMapView) return _input;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_input);
  }

  @override
  final String output;

  @override
  String toString() {
    return 'AgentToolCall(name: $name, input: $input, output: $output)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AgentToolCallImpl &&
            (identical(other.name, name) || other.name == name) &&
            const DeepCollectionEquality().equals(other._input, _input) &&
            (identical(other.output, output) || other.output == output));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType, name, const DeepCollectionEquality().hash(_input), output);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$AgentToolCallImplCopyWith<_$AgentToolCallImpl> get copyWith =>
      __$$AgentToolCallImplCopyWithImpl<_$AgentToolCallImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$AgentToolCallImplToJson(
      this,
    );
  }
}

abstract class _AgentToolCall implements AgentToolCall {
  const factory _AgentToolCall(
      {required final String name,
      required final Map<String, dynamic> input,
      required final String output}) = _$AgentToolCallImpl;

  factory _AgentToolCall.fromJson(Map<String, dynamic> json) =
      _$AgentToolCallImpl.fromJson;

  @override
  String get name;
  @override
  Map<String, dynamic> get input;
  @override
  String get output;
  @override
  @JsonKey(ignore: true)
  _$$AgentToolCallImplCopyWith<_$AgentToolCallImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

AgentRunResult _$AgentRunResultFromJson(Map<String, dynamic> json) {
  return _AgentRunResult.fromJson(json);
}

/// @nodoc
mixin _$AgentRunResult {
  String get finalText => throw _privateConstructorUsedError;
  List<AgentToolCall> get toolCalls => throw _privateConstructorUsedError;
  bool get aborted => throw _privateConstructorUsedError;
  String? get conversationId => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $AgentRunResultCopyWith<AgentRunResult> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AgentRunResultCopyWith<$Res> {
  factory $AgentRunResultCopyWith(
          AgentRunResult value, $Res Function(AgentRunResult) then) =
      _$AgentRunResultCopyWithImpl<$Res, AgentRunResult>;
  @useResult
  $Res call(
      {String finalText,
      List<AgentToolCall> toolCalls,
      bool aborted,
      String? conversationId});
}

/// @nodoc
class _$AgentRunResultCopyWithImpl<$Res, $Val extends AgentRunResult>
    implements $AgentRunResultCopyWith<$Res> {
  _$AgentRunResultCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? finalText = null,
    Object? toolCalls = null,
    Object? aborted = null,
    Object? conversationId = freezed,
  }) {
    return _then(_value.copyWith(
      finalText: null == finalText
          ? _value.finalText
          : finalText // ignore: cast_nullable_to_non_nullable
              as String,
      toolCalls: null == toolCalls
          ? _value.toolCalls
          : toolCalls // ignore: cast_nullable_to_non_nullable
              as List<AgentToolCall>,
      aborted: null == aborted
          ? _value.aborted
          : aborted // ignore: cast_nullable_to_non_nullable
              as bool,
      conversationId: freezed == conversationId
          ? _value.conversationId
          : conversationId // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$AgentRunResultImplCopyWith<$Res>
    implements $AgentRunResultCopyWith<$Res> {
  factory _$$AgentRunResultImplCopyWith(_$AgentRunResultImpl value,
          $Res Function(_$AgentRunResultImpl) then) =
      __$$AgentRunResultImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String finalText,
      List<AgentToolCall> toolCalls,
      bool aborted,
      String? conversationId});
}

/// @nodoc
class __$$AgentRunResultImplCopyWithImpl<$Res>
    extends _$AgentRunResultCopyWithImpl<$Res, _$AgentRunResultImpl>
    implements _$$AgentRunResultImplCopyWith<$Res> {
  __$$AgentRunResultImplCopyWithImpl(
      _$AgentRunResultImpl _value, $Res Function(_$AgentRunResultImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? finalText = null,
    Object? toolCalls = null,
    Object? aborted = null,
    Object? conversationId = freezed,
  }) {
    return _then(_$AgentRunResultImpl(
      finalText: null == finalText
          ? _value.finalText
          : finalText // ignore: cast_nullable_to_non_nullable
              as String,
      toolCalls: null == toolCalls
          ? _value._toolCalls
          : toolCalls // ignore: cast_nullable_to_non_nullable
              as List<AgentToolCall>,
      aborted: null == aborted
          ? _value.aborted
          : aborted // ignore: cast_nullable_to_non_nullable
              as bool,
      conversationId: freezed == conversationId
          ? _value.conversationId
          : conversationId // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$AgentRunResultImpl implements _AgentRunResult {
  const _$AgentRunResultImpl(
      {required this.finalText,
      required final List<AgentToolCall> toolCalls,
      required this.aborted,
      this.conversationId})
      : _toolCalls = toolCalls;

  factory _$AgentRunResultImpl.fromJson(Map<String, dynamic> json) =>
      _$$AgentRunResultImplFromJson(json);

  @override
  final String finalText;
  final List<AgentToolCall> _toolCalls;
  @override
  List<AgentToolCall> get toolCalls {
    if (_toolCalls is EqualUnmodifiableListView) return _toolCalls;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_toolCalls);
  }

  @override
  final bool aborted;
  @override
  final String? conversationId;

  @override
  String toString() {
    return 'AgentRunResult(finalText: $finalText, toolCalls: $toolCalls, aborted: $aborted, conversationId: $conversationId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AgentRunResultImpl &&
            (identical(other.finalText, finalText) ||
                other.finalText == finalText) &&
            const DeepCollectionEquality()
                .equals(other._toolCalls, _toolCalls) &&
            (identical(other.aborted, aborted) || other.aborted == aborted) &&
            (identical(other.conversationId, conversationId) ||
                other.conversationId == conversationId));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, finalText,
      const DeepCollectionEquality().hash(_toolCalls), aborted, conversationId);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$AgentRunResultImplCopyWith<_$AgentRunResultImpl> get copyWith =>
      __$$AgentRunResultImplCopyWithImpl<_$AgentRunResultImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$AgentRunResultImplToJson(
      this,
    );
  }
}

abstract class _AgentRunResult implements AgentRunResult {
  const factory _AgentRunResult(
      {required final String finalText,
      required final List<AgentToolCall> toolCalls,
      required final bool aborted,
      final String? conversationId}) = _$AgentRunResultImpl;

  factory _AgentRunResult.fromJson(Map<String, dynamic> json) =
      _$AgentRunResultImpl.fromJson;

  @override
  String get finalText;
  @override
  List<AgentToolCall> get toolCalls;
  @override
  bool get aborted;
  @override
  String? get conversationId;
  @override
  @JsonKey(ignore: true)
  _$$AgentRunResultImplCopyWith<_$AgentRunResultImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'channel_summary.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

ChannelSummary _$ChannelSummaryFromJson(Map<String, dynamic> json) {
  return _ChannelSummary.fromJson(json);
}

/// @nodoc
mixin _$ChannelSummary {
  String get id => throw _privateConstructorUsedError;
  String? get name => throw _privateConstructorUsedError;
  String? get description => throw _privateConstructorUsedError;
  String? get avatarUrl => throw _privateConstructorUsedError;
  int get subscribersCount => throw _privateConstructorUsedError;
  bool get isSubscribed => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $ChannelSummaryCopyWith<ChannelSummary> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ChannelSummaryCopyWith<$Res> {
  factory $ChannelSummaryCopyWith(
          ChannelSummary value, $Res Function(ChannelSummary) then) =
      _$ChannelSummaryCopyWithImpl<$Res, ChannelSummary>;
  @useResult
  $Res call(
      {String id,
      String? name,
      String? description,
      String? avatarUrl,
      int subscribersCount,
      bool isSubscribed});
}

/// @nodoc
class _$ChannelSummaryCopyWithImpl<$Res, $Val extends ChannelSummary>
    implements $ChannelSummaryCopyWith<$Res> {
  _$ChannelSummaryCopyWithImpl(this._value, this._then);

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
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ChannelSummaryImplCopyWith<$Res>
    implements $ChannelSummaryCopyWith<$Res> {
  factory _$$ChannelSummaryImplCopyWith(_$ChannelSummaryImpl value,
          $Res Function(_$ChannelSummaryImpl) then) =
      __$$ChannelSummaryImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String? name,
      String? description,
      String? avatarUrl,
      int subscribersCount,
      bool isSubscribed});
}

/// @nodoc
class __$$ChannelSummaryImplCopyWithImpl<$Res>
    extends _$ChannelSummaryCopyWithImpl<$Res, _$ChannelSummaryImpl>
    implements _$$ChannelSummaryImplCopyWith<$Res> {
  __$$ChannelSummaryImplCopyWithImpl(
      _$ChannelSummaryImpl _value, $Res Function(_$ChannelSummaryImpl) _then)
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
  }) {
    return _then(_$ChannelSummaryImpl(
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
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ChannelSummaryImpl implements _ChannelSummary {
  const _$ChannelSummaryImpl(
      {required this.id,
      this.name,
      this.description,
      this.avatarUrl,
      this.subscribersCount = 0,
      this.isSubscribed = false});

  factory _$ChannelSummaryImpl.fromJson(Map<String, dynamic> json) =>
      _$$ChannelSummaryImplFromJson(json);

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
  String toString() {
    return 'ChannelSummary(id: $id, name: $name, description: $description, avatarUrl: $avatarUrl, subscribersCount: $subscribersCount, isSubscribed: $isSubscribed)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ChannelSummaryImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.avatarUrl, avatarUrl) ||
                other.avatarUrl == avatarUrl) &&
            (identical(other.subscribersCount, subscribersCount) ||
                other.subscribersCount == subscribersCount) &&
            (identical(other.isSubscribed, isSubscribed) ||
                other.isSubscribed == isSubscribed));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, id, name, description, avatarUrl,
      subscribersCount, isSubscribed);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ChannelSummaryImplCopyWith<_$ChannelSummaryImpl> get copyWith =>
      __$$ChannelSummaryImplCopyWithImpl<_$ChannelSummaryImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ChannelSummaryImplToJson(
      this,
    );
  }
}

abstract class _ChannelSummary implements ChannelSummary {
  const factory _ChannelSummary(
      {required final String id,
      final String? name,
      final String? description,
      final String? avatarUrl,
      final int subscribersCount,
      final bool isSubscribed}) = _$ChannelSummaryImpl;

  factory _ChannelSummary.fromJson(Map<String, dynamic> json) =
      _$ChannelSummaryImpl.fromJson;

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
  @JsonKey(ignore: true)
  _$$ChannelSummaryImplCopyWith<_$ChannelSummaryImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

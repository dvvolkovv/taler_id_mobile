// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'captured_notification.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

CapturedNotification _$CapturedNotificationFromJson(Map<String, dynamic> json) {
  return _CapturedNotification.fromJson(json);
}

/// @nodoc
mixin _$CapturedNotification {
  String get packageName => throw _privateConstructorUsedError;
  String get key => throw _privateConstructorUsedError;
  DateTime get postedAt => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String get body => throw _privateConstructorUsedError;
  String? get conversationTitle => throw _privateConstructorUsedError;
  bool get canReply => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $CapturedNotificationCopyWith<CapturedNotification> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CapturedNotificationCopyWith<$Res> {
  factory $CapturedNotificationCopyWith(CapturedNotification value,
          $Res Function(CapturedNotification) then) =
      _$CapturedNotificationCopyWithImpl<$Res, CapturedNotification>;
  @useResult
  $Res call(
      {String packageName,
      String key,
      DateTime postedAt,
      String title,
      String body,
      String? conversationTitle,
      bool canReply});
}

/// @nodoc
class _$CapturedNotificationCopyWithImpl<$Res,
        $Val extends CapturedNotification>
    implements $CapturedNotificationCopyWith<$Res> {
  _$CapturedNotificationCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? packageName = null,
    Object? key = null,
    Object? postedAt = null,
    Object? title = null,
    Object? body = null,
    Object? conversationTitle = freezed,
    Object? canReply = null,
  }) {
    return _then(_value.copyWith(
      packageName: null == packageName
          ? _value.packageName
          : packageName // ignore: cast_nullable_to_non_nullable
              as String,
      key: null == key
          ? _value.key
          : key // ignore: cast_nullable_to_non_nullable
              as String,
      postedAt: null == postedAt
          ? _value.postedAt
          : postedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      body: null == body
          ? _value.body
          : body // ignore: cast_nullable_to_non_nullable
              as String,
      conversationTitle: freezed == conversationTitle
          ? _value.conversationTitle
          : conversationTitle // ignore: cast_nullable_to_non_nullable
              as String?,
      canReply: null == canReply
          ? _value.canReply
          : canReply // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$CapturedNotificationImplCopyWith<$Res>
    implements $CapturedNotificationCopyWith<$Res> {
  factory _$$CapturedNotificationImplCopyWith(_$CapturedNotificationImpl value,
          $Res Function(_$CapturedNotificationImpl) then) =
      __$$CapturedNotificationImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String packageName,
      String key,
      DateTime postedAt,
      String title,
      String body,
      String? conversationTitle,
      bool canReply});
}

/// @nodoc
class __$$CapturedNotificationImplCopyWithImpl<$Res>
    extends _$CapturedNotificationCopyWithImpl<$Res, _$CapturedNotificationImpl>
    implements _$$CapturedNotificationImplCopyWith<$Res> {
  __$$CapturedNotificationImplCopyWithImpl(_$CapturedNotificationImpl _value,
      $Res Function(_$CapturedNotificationImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? packageName = null,
    Object? key = null,
    Object? postedAt = null,
    Object? title = null,
    Object? body = null,
    Object? conversationTitle = freezed,
    Object? canReply = null,
  }) {
    return _then(_$CapturedNotificationImpl(
      packageName: null == packageName
          ? _value.packageName
          : packageName // ignore: cast_nullable_to_non_nullable
              as String,
      key: null == key
          ? _value.key
          : key // ignore: cast_nullable_to_non_nullable
              as String,
      postedAt: null == postedAt
          ? _value.postedAt
          : postedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      body: null == body
          ? _value.body
          : body // ignore: cast_nullable_to_non_nullable
              as String,
      conversationTitle: freezed == conversationTitle
          ? _value.conversationTitle
          : conversationTitle // ignore: cast_nullable_to_non_nullable
              as String?,
      canReply: null == canReply
          ? _value.canReply
          : canReply // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$CapturedNotificationImpl extends _CapturedNotification {
  const _$CapturedNotificationImpl(
      {required this.packageName,
      required this.key,
      required this.postedAt,
      required this.title,
      required this.body,
      this.conversationTitle,
      this.canReply = false})
      : super._();

  factory _$CapturedNotificationImpl.fromJson(Map<String, dynamic> json) =>
      _$$CapturedNotificationImplFromJson(json);

  @override
  final String packageName;
  @override
  final String key;
  @override
  final DateTime postedAt;
  @override
  final String title;
  @override
  final String body;
  @override
  final String? conversationTitle;
  @override
  @JsonKey()
  final bool canReply;

  @override
  String toString() {
    return 'CapturedNotification(packageName: $packageName, key: $key, postedAt: $postedAt, title: $title, body: $body, conversationTitle: $conversationTitle, canReply: $canReply)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CapturedNotificationImpl &&
            (identical(other.packageName, packageName) ||
                other.packageName == packageName) &&
            (identical(other.key, key) || other.key == key) &&
            (identical(other.postedAt, postedAt) ||
                other.postedAt == postedAt) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.body, body) || other.body == body) &&
            (identical(other.conversationTitle, conversationTitle) ||
                other.conversationTitle == conversationTitle) &&
            (identical(other.canReply, canReply) ||
                other.canReply == canReply));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, packageName, key, postedAt,
      title, body, conversationTitle, canReply);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$CapturedNotificationImplCopyWith<_$CapturedNotificationImpl>
      get copyWith =>
          __$$CapturedNotificationImplCopyWithImpl<_$CapturedNotificationImpl>(
              this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$CapturedNotificationImplToJson(
      this,
    );
  }
}

abstract class _CapturedNotification extends CapturedNotification {
  const factory _CapturedNotification(
      {required final String packageName,
      required final String key,
      required final DateTime postedAt,
      required final String title,
      required final String body,
      final String? conversationTitle,
      final bool canReply}) = _$CapturedNotificationImpl;
  const _CapturedNotification._() : super._();

  factory _CapturedNotification.fromJson(Map<String, dynamic> json) =
      _$CapturedNotificationImpl.fromJson;

  @override
  String get packageName;
  @override
  String get key;
  @override
  DateTime get postedAt;
  @override
  String get title;
  @override
  String get body;
  @override
  String? get conversationTitle;
  @override
  bool get canReply;
  @override
  @JsonKey(ignore: true)
  _$$CapturedNotificationImplCopyWith<_$CapturedNotificationImpl>
      get copyWith => throw _privateConstructorUsedError;
}

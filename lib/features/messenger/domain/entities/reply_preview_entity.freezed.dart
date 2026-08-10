// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'reply_preview_entity.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

ReplyPreviewEntity _$ReplyPreviewEntityFromJson(Map<String, dynamic> json) {
  return _ReplyPreviewEntity.fromJson(json);
}

/// @nodoc
mixin _$ReplyPreviewEntity {
  String get id => throw _privateConstructorUsedError;
  String? get senderId => throw _privateConstructorUsedError;
  String? get senderName => throw _privateConstructorUsedError;
  String get content => throw _privateConstructorUsedError;
  String? get fileType => throw _privateConstructorUsedError;
  String? get fileName => throw _privateConstructorUsedError;
  bool get isDeleted => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $ReplyPreviewEntityCopyWith<ReplyPreviewEntity> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ReplyPreviewEntityCopyWith<$Res> {
  factory $ReplyPreviewEntityCopyWith(
          ReplyPreviewEntity value, $Res Function(ReplyPreviewEntity) then) =
      _$ReplyPreviewEntityCopyWithImpl<$Res, ReplyPreviewEntity>;
  @useResult
  $Res call(
      {String id,
      String? senderId,
      String? senderName,
      String content,
      String? fileType,
      String? fileName,
      bool isDeleted});
}

/// @nodoc
class _$ReplyPreviewEntityCopyWithImpl<$Res, $Val extends ReplyPreviewEntity>
    implements $ReplyPreviewEntityCopyWith<$Res> {
  _$ReplyPreviewEntityCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? senderId = freezed,
    Object? senderName = freezed,
    Object? content = null,
    Object? fileType = freezed,
    Object? fileName = freezed,
    Object? isDeleted = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      senderId: freezed == senderId
          ? _value.senderId
          : senderId // ignore: cast_nullable_to_non_nullable
              as String?,
      senderName: freezed == senderName
          ? _value.senderName
          : senderName // ignore: cast_nullable_to_non_nullable
              as String?,
      content: null == content
          ? _value.content
          : content // ignore: cast_nullable_to_non_nullable
              as String,
      fileType: freezed == fileType
          ? _value.fileType
          : fileType // ignore: cast_nullable_to_non_nullable
              as String?,
      fileName: freezed == fileName
          ? _value.fileName
          : fileName // ignore: cast_nullable_to_non_nullable
              as String?,
      isDeleted: null == isDeleted
          ? _value.isDeleted
          : isDeleted // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ReplyPreviewEntityImplCopyWith<$Res>
    implements $ReplyPreviewEntityCopyWith<$Res> {
  factory _$$ReplyPreviewEntityImplCopyWith(_$ReplyPreviewEntityImpl value,
          $Res Function(_$ReplyPreviewEntityImpl) then) =
      __$$ReplyPreviewEntityImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String? senderId,
      String? senderName,
      String content,
      String? fileType,
      String? fileName,
      bool isDeleted});
}

/// @nodoc
class __$$ReplyPreviewEntityImplCopyWithImpl<$Res>
    extends _$ReplyPreviewEntityCopyWithImpl<$Res, _$ReplyPreviewEntityImpl>
    implements _$$ReplyPreviewEntityImplCopyWith<$Res> {
  __$$ReplyPreviewEntityImplCopyWithImpl(_$ReplyPreviewEntityImpl _value,
      $Res Function(_$ReplyPreviewEntityImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? senderId = freezed,
    Object? senderName = freezed,
    Object? content = null,
    Object? fileType = freezed,
    Object? fileName = freezed,
    Object? isDeleted = null,
  }) {
    return _then(_$ReplyPreviewEntityImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      senderId: freezed == senderId
          ? _value.senderId
          : senderId // ignore: cast_nullable_to_non_nullable
              as String?,
      senderName: freezed == senderName
          ? _value.senderName
          : senderName // ignore: cast_nullable_to_non_nullable
              as String?,
      content: null == content
          ? _value.content
          : content // ignore: cast_nullable_to_non_nullable
              as String,
      fileType: freezed == fileType
          ? _value.fileType
          : fileType // ignore: cast_nullable_to_non_nullable
              as String?,
      fileName: freezed == fileName
          ? _value.fileName
          : fileName // ignore: cast_nullable_to_non_nullable
              as String?,
      isDeleted: null == isDeleted
          ? _value.isDeleted
          : isDeleted // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ReplyPreviewEntityImpl implements _ReplyPreviewEntity {
  const _$ReplyPreviewEntityImpl(
      {required this.id,
      this.senderId,
      this.senderName,
      this.content = '',
      this.fileType,
      this.fileName,
      this.isDeleted = false});

  factory _$ReplyPreviewEntityImpl.fromJson(Map<String, dynamic> json) =>
      _$$ReplyPreviewEntityImplFromJson(json);

  @override
  final String id;
  @override
  final String? senderId;
  @override
  final String? senderName;
  @override
  @JsonKey()
  final String content;
  @override
  final String? fileType;
  @override
  final String? fileName;
  @override
  @JsonKey()
  final bool isDeleted;

  @override
  String toString() {
    return 'ReplyPreviewEntity(id: $id, senderId: $senderId, senderName: $senderName, content: $content, fileType: $fileType, fileName: $fileName, isDeleted: $isDeleted)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ReplyPreviewEntityImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.senderId, senderId) ||
                other.senderId == senderId) &&
            (identical(other.senderName, senderName) ||
                other.senderName == senderName) &&
            (identical(other.content, content) || other.content == content) &&
            (identical(other.fileType, fileType) ||
                other.fileType == fileType) &&
            (identical(other.fileName, fileName) ||
                other.fileName == fileName) &&
            (identical(other.isDeleted, isDeleted) ||
                other.isDeleted == isDeleted));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, id, senderId, senderName,
      content, fileType, fileName, isDeleted);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ReplyPreviewEntityImplCopyWith<_$ReplyPreviewEntityImpl> get copyWith =>
      __$$ReplyPreviewEntityImplCopyWithImpl<_$ReplyPreviewEntityImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ReplyPreviewEntityImplToJson(
      this,
    );
  }
}

abstract class _ReplyPreviewEntity implements ReplyPreviewEntity {
  const factory _ReplyPreviewEntity(
      {required final String id,
      final String? senderId,
      final String? senderName,
      final String content,
      final String? fileType,
      final String? fileName,
      final bool isDeleted}) = _$ReplyPreviewEntityImpl;

  factory _ReplyPreviewEntity.fromJson(Map<String, dynamic> json) =
      _$ReplyPreviewEntityImpl.fromJson;

  @override
  String get id;
  @override
  String? get senderId;
  @override
  String? get senderName;
  @override
  String get content;
  @override
  String? get fileType;
  @override
  String? get fileName;
  @override
  bool get isDeleted;
  @override
  @JsonKey(ignore: true)
  _$$ReplyPreviewEntityImplCopyWith<_$ReplyPreviewEntityImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

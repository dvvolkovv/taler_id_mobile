// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'message_entity.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

MessageEntity _$MessageEntityFromJson(Map<String, dynamic> json) {
  return _MessageEntity.fromJson(json);
}

/// @nodoc
mixin _$MessageEntity {
  String get id => throw _privateConstructorUsedError;
  String get conversationId => throw _privateConstructorUsedError;
  String get senderId => throw _privateConstructorUsedError;
  String? get senderName => throw _privateConstructorUsedError;
  String get content => throw _privateConstructorUsedError;
  DateTime get sentAt => throw _privateConstructorUsedError;
  String? get fileUrl => throw _privateConstructorUsedError;
  String? get fileName => throw _privateConstructorUsedError;
  int? get fileSize => throw _privateConstructorUsedError;
  String? get fileType => throw _privateConstructorUsedError;
  String? get s3Key => throw _privateConstructorUsedError;
  String? get thumbnailSmallUrl => throw _privateConstructorUsedError;
  String? get thumbnailMediumUrl => throw _privateConstructorUsedError;
  String? get thumbnailLargeUrl => throw _privateConstructorUsedError;
  String? get fileRecordId => throw _privateConstructorUsedError;
  bool get isDelivered => throw _privateConstructorUsedError;
  bool get isRead => throw _privateConstructorUsedError;
  bool get isSystem => throw _privateConstructorUsedError;
  bool get isEdited => throw _privateConstructorUsedError;
  List<Map<String, dynamic>> get reactions =>
      throw _privateConstructorUsedError;
  String? get threadParentId => throw _privateConstructorUsedError;
  int get threadReplyCount => throw _privateConstructorUsedError;
  List<String>? get threadLastReplierAvatars =>
      throw _privateConstructorUsedError;
  String? get topicId => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $MessageEntityCopyWith<MessageEntity> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MessageEntityCopyWith<$Res> {
  factory $MessageEntityCopyWith(
          MessageEntity value, $Res Function(MessageEntity) then) =
      _$MessageEntityCopyWithImpl<$Res, MessageEntity>;
  @useResult
  $Res call(
      {String id,
      String conversationId,
      String senderId,
      String? senderName,
      String content,
      DateTime sentAt,
      String? fileUrl,
      String? fileName,
      int? fileSize,
      String? fileType,
      String? s3Key,
      String? thumbnailSmallUrl,
      String? thumbnailMediumUrl,
      String? thumbnailLargeUrl,
      String? fileRecordId,
      bool isDelivered,
      bool isRead,
      bool isSystem,
      bool isEdited,
      List<Map<String, dynamic>> reactions,
      String? threadParentId,
      int threadReplyCount,
      List<String>? threadLastReplierAvatars,
      String? topicId});
}

/// @nodoc
class _$MessageEntityCopyWithImpl<$Res, $Val extends MessageEntity>
    implements $MessageEntityCopyWith<$Res> {
  _$MessageEntityCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? conversationId = null,
    Object? senderId = null,
    Object? senderName = freezed,
    Object? content = null,
    Object? sentAt = null,
    Object? fileUrl = freezed,
    Object? fileName = freezed,
    Object? fileSize = freezed,
    Object? fileType = freezed,
    Object? s3Key = freezed,
    Object? thumbnailSmallUrl = freezed,
    Object? thumbnailMediumUrl = freezed,
    Object? thumbnailLargeUrl = freezed,
    Object? fileRecordId = freezed,
    Object? isDelivered = null,
    Object? isRead = null,
    Object? isSystem = null,
    Object? isEdited = null,
    Object? reactions = null,
    Object? threadParentId = freezed,
    Object? threadReplyCount = null,
    Object? threadLastReplierAvatars = freezed,
    Object? topicId = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      conversationId: null == conversationId
          ? _value.conversationId
          : conversationId // ignore: cast_nullable_to_non_nullable
              as String,
      senderId: null == senderId
          ? _value.senderId
          : senderId // ignore: cast_nullable_to_non_nullable
              as String,
      senderName: freezed == senderName
          ? _value.senderName
          : senderName // ignore: cast_nullable_to_non_nullable
              as String?,
      content: null == content
          ? _value.content
          : content // ignore: cast_nullable_to_non_nullable
              as String,
      sentAt: null == sentAt
          ? _value.sentAt
          : sentAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      fileUrl: freezed == fileUrl
          ? _value.fileUrl
          : fileUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      fileName: freezed == fileName
          ? _value.fileName
          : fileName // ignore: cast_nullable_to_non_nullable
              as String?,
      fileSize: freezed == fileSize
          ? _value.fileSize
          : fileSize // ignore: cast_nullable_to_non_nullable
              as int?,
      fileType: freezed == fileType
          ? _value.fileType
          : fileType // ignore: cast_nullable_to_non_nullable
              as String?,
      s3Key: freezed == s3Key
          ? _value.s3Key
          : s3Key // ignore: cast_nullable_to_non_nullable
              as String?,
      thumbnailSmallUrl: freezed == thumbnailSmallUrl
          ? _value.thumbnailSmallUrl
          : thumbnailSmallUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      thumbnailMediumUrl: freezed == thumbnailMediumUrl
          ? _value.thumbnailMediumUrl
          : thumbnailMediumUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      thumbnailLargeUrl: freezed == thumbnailLargeUrl
          ? _value.thumbnailLargeUrl
          : thumbnailLargeUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      fileRecordId: freezed == fileRecordId
          ? _value.fileRecordId
          : fileRecordId // ignore: cast_nullable_to_non_nullable
              as String?,
      isDelivered: null == isDelivered
          ? _value.isDelivered
          : isDelivered // ignore: cast_nullable_to_non_nullable
              as bool,
      isRead: null == isRead
          ? _value.isRead
          : isRead // ignore: cast_nullable_to_non_nullable
              as bool,
      isSystem: null == isSystem
          ? _value.isSystem
          : isSystem // ignore: cast_nullable_to_non_nullable
              as bool,
      isEdited: null == isEdited
          ? _value.isEdited
          : isEdited // ignore: cast_nullable_to_non_nullable
              as bool,
      reactions: null == reactions
          ? _value.reactions
          : reactions // ignore: cast_nullable_to_non_nullable
              as List<Map<String, dynamic>>,
      threadParentId: freezed == threadParentId
          ? _value.threadParentId
          : threadParentId // ignore: cast_nullable_to_non_nullable
              as String?,
      threadReplyCount: null == threadReplyCount
          ? _value.threadReplyCount
          : threadReplyCount // ignore: cast_nullable_to_non_nullable
              as int,
      threadLastReplierAvatars: freezed == threadLastReplierAvatars
          ? _value.threadLastReplierAvatars
          : threadLastReplierAvatars // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      topicId: freezed == topicId
          ? _value.topicId
          : topicId // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$MessageEntityImplCopyWith<$Res>
    implements $MessageEntityCopyWith<$Res> {
  factory _$$MessageEntityImplCopyWith(
          _$MessageEntityImpl value, $Res Function(_$MessageEntityImpl) then) =
      __$$MessageEntityImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String conversationId,
      String senderId,
      String? senderName,
      String content,
      DateTime sentAt,
      String? fileUrl,
      String? fileName,
      int? fileSize,
      String? fileType,
      String? s3Key,
      String? thumbnailSmallUrl,
      String? thumbnailMediumUrl,
      String? thumbnailLargeUrl,
      String? fileRecordId,
      bool isDelivered,
      bool isRead,
      bool isSystem,
      bool isEdited,
      List<Map<String, dynamic>> reactions,
      String? threadParentId,
      int threadReplyCount,
      List<String>? threadLastReplierAvatars,
      String? topicId});
}

/// @nodoc
class __$$MessageEntityImplCopyWithImpl<$Res>
    extends _$MessageEntityCopyWithImpl<$Res, _$MessageEntityImpl>
    implements _$$MessageEntityImplCopyWith<$Res> {
  __$$MessageEntityImplCopyWithImpl(
      _$MessageEntityImpl _value, $Res Function(_$MessageEntityImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? conversationId = null,
    Object? senderId = null,
    Object? senderName = freezed,
    Object? content = null,
    Object? sentAt = null,
    Object? fileUrl = freezed,
    Object? fileName = freezed,
    Object? fileSize = freezed,
    Object? fileType = freezed,
    Object? s3Key = freezed,
    Object? thumbnailSmallUrl = freezed,
    Object? thumbnailMediumUrl = freezed,
    Object? thumbnailLargeUrl = freezed,
    Object? fileRecordId = freezed,
    Object? isDelivered = null,
    Object? isRead = null,
    Object? isSystem = null,
    Object? isEdited = null,
    Object? reactions = null,
    Object? threadParentId = freezed,
    Object? threadReplyCount = null,
    Object? threadLastReplierAvatars = freezed,
    Object? topicId = freezed,
  }) {
    return _then(_$MessageEntityImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      conversationId: null == conversationId
          ? _value.conversationId
          : conversationId // ignore: cast_nullable_to_non_nullable
              as String,
      senderId: null == senderId
          ? _value.senderId
          : senderId // ignore: cast_nullable_to_non_nullable
              as String,
      senderName: freezed == senderName
          ? _value.senderName
          : senderName // ignore: cast_nullable_to_non_nullable
              as String?,
      content: null == content
          ? _value.content
          : content // ignore: cast_nullable_to_non_nullable
              as String,
      sentAt: null == sentAt
          ? _value.sentAt
          : sentAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      fileUrl: freezed == fileUrl
          ? _value.fileUrl
          : fileUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      fileName: freezed == fileName
          ? _value.fileName
          : fileName // ignore: cast_nullable_to_non_nullable
              as String?,
      fileSize: freezed == fileSize
          ? _value.fileSize
          : fileSize // ignore: cast_nullable_to_non_nullable
              as int?,
      fileType: freezed == fileType
          ? _value.fileType
          : fileType // ignore: cast_nullable_to_non_nullable
              as String?,
      s3Key: freezed == s3Key
          ? _value.s3Key
          : s3Key // ignore: cast_nullable_to_non_nullable
              as String?,
      thumbnailSmallUrl: freezed == thumbnailSmallUrl
          ? _value.thumbnailSmallUrl
          : thumbnailSmallUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      thumbnailMediumUrl: freezed == thumbnailMediumUrl
          ? _value.thumbnailMediumUrl
          : thumbnailMediumUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      thumbnailLargeUrl: freezed == thumbnailLargeUrl
          ? _value.thumbnailLargeUrl
          : thumbnailLargeUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      fileRecordId: freezed == fileRecordId
          ? _value.fileRecordId
          : fileRecordId // ignore: cast_nullable_to_non_nullable
              as String?,
      isDelivered: null == isDelivered
          ? _value.isDelivered
          : isDelivered // ignore: cast_nullable_to_non_nullable
              as bool,
      isRead: null == isRead
          ? _value.isRead
          : isRead // ignore: cast_nullable_to_non_nullable
              as bool,
      isSystem: null == isSystem
          ? _value.isSystem
          : isSystem // ignore: cast_nullable_to_non_nullable
              as bool,
      isEdited: null == isEdited
          ? _value.isEdited
          : isEdited // ignore: cast_nullable_to_non_nullable
              as bool,
      reactions: null == reactions
          ? _value._reactions
          : reactions // ignore: cast_nullable_to_non_nullable
              as List<Map<String, dynamic>>,
      threadParentId: freezed == threadParentId
          ? _value.threadParentId
          : threadParentId // ignore: cast_nullable_to_non_nullable
              as String?,
      threadReplyCount: null == threadReplyCount
          ? _value.threadReplyCount
          : threadReplyCount // ignore: cast_nullable_to_non_nullable
              as int,
      threadLastReplierAvatars: freezed == threadLastReplierAvatars
          ? _value._threadLastReplierAvatars
          : threadLastReplierAvatars // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      topicId: freezed == topicId
          ? _value.topicId
          : topicId // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$MessageEntityImpl implements _MessageEntity {
  const _$MessageEntityImpl(
      {required this.id,
      required this.conversationId,
      required this.senderId,
      this.senderName,
      required this.content,
      required this.sentAt,
      this.fileUrl,
      this.fileName,
      this.fileSize,
      this.fileType,
      this.s3Key,
      this.thumbnailSmallUrl,
      this.thumbnailMediumUrl,
      this.thumbnailLargeUrl,
      this.fileRecordId,
      this.isDelivered = false,
      this.isRead = false,
      this.isSystem = false,
      this.isEdited = false,
      final List<Map<String, dynamic>> reactions = const [],
      this.threadParentId,
      this.threadReplyCount = 0,
      final List<String>? threadLastReplierAvatars,
      this.topicId})
      : _reactions = reactions,
        _threadLastReplierAvatars = threadLastReplierAvatars;

  factory _$MessageEntityImpl.fromJson(Map<String, dynamic> json) =>
      _$$MessageEntityImplFromJson(json);

  @override
  final String id;
  @override
  final String conversationId;
  @override
  final String senderId;
  @override
  final String? senderName;
  @override
  final String content;
  @override
  final DateTime sentAt;
  @override
  final String? fileUrl;
  @override
  final String? fileName;
  @override
  final int? fileSize;
  @override
  final String? fileType;
  @override
  final String? s3Key;
  @override
  final String? thumbnailSmallUrl;
  @override
  final String? thumbnailMediumUrl;
  @override
  final String? thumbnailLargeUrl;
  @override
  final String? fileRecordId;
  @override
  @JsonKey()
  final bool isDelivered;
  @override
  @JsonKey()
  final bool isRead;
  @override
  @JsonKey()
  final bool isSystem;
  @override
  @JsonKey()
  final bool isEdited;
  final List<Map<String, dynamic>> _reactions;
  @override
  @JsonKey()
  List<Map<String, dynamic>> get reactions {
    if (_reactions is EqualUnmodifiableListView) return _reactions;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_reactions);
  }

  @override
  final String? threadParentId;
  @override
  @JsonKey()
  final int threadReplyCount;
  final List<String>? _threadLastReplierAvatars;
  @override
  List<String>? get threadLastReplierAvatars {
    final value = _threadLastReplierAvatars;
    if (value == null) return null;
    if (_threadLastReplierAvatars is EqualUnmodifiableListView)
      return _threadLastReplierAvatars;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  final String? topicId;

  @override
  String toString() {
    return 'MessageEntity(id: $id, conversationId: $conversationId, senderId: $senderId, senderName: $senderName, content: $content, sentAt: $sentAt, fileUrl: $fileUrl, fileName: $fileName, fileSize: $fileSize, fileType: $fileType, s3Key: $s3Key, thumbnailSmallUrl: $thumbnailSmallUrl, thumbnailMediumUrl: $thumbnailMediumUrl, thumbnailLargeUrl: $thumbnailLargeUrl, fileRecordId: $fileRecordId, isDelivered: $isDelivered, isRead: $isRead, isSystem: $isSystem, isEdited: $isEdited, reactions: $reactions, threadParentId: $threadParentId, threadReplyCount: $threadReplyCount, threadLastReplierAvatars: $threadLastReplierAvatars, topicId: $topicId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MessageEntityImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.conversationId, conversationId) ||
                other.conversationId == conversationId) &&
            (identical(other.senderId, senderId) ||
                other.senderId == senderId) &&
            (identical(other.senderName, senderName) ||
                other.senderName == senderName) &&
            (identical(other.content, content) || other.content == content) &&
            (identical(other.sentAt, sentAt) || other.sentAt == sentAt) &&
            (identical(other.fileUrl, fileUrl) || other.fileUrl == fileUrl) &&
            (identical(other.fileName, fileName) ||
                other.fileName == fileName) &&
            (identical(other.fileSize, fileSize) ||
                other.fileSize == fileSize) &&
            (identical(other.fileType, fileType) ||
                other.fileType == fileType) &&
            (identical(other.s3Key, s3Key) || other.s3Key == s3Key) &&
            (identical(other.thumbnailSmallUrl, thumbnailSmallUrl) ||
                other.thumbnailSmallUrl == thumbnailSmallUrl) &&
            (identical(other.thumbnailMediumUrl, thumbnailMediumUrl) ||
                other.thumbnailMediumUrl == thumbnailMediumUrl) &&
            (identical(other.thumbnailLargeUrl, thumbnailLargeUrl) ||
                other.thumbnailLargeUrl == thumbnailLargeUrl) &&
            (identical(other.fileRecordId, fileRecordId) ||
                other.fileRecordId == fileRecordId) &&
            (identical(other.isDelivered, isDelivered) ||
                other.isDelivered == isDelivered) &&
            (identical(other.isRead, isRead) || other.isRead == isRead) &&
            (identical(other.isSystem, isSystem) ||
                other.isSystem == isSystem) &&
            (identical(other.isEdited, isEdited) ||
                other.isEdited == isEdited) &&
            const DeepCollectionEquality()
                .equals(other._reactions, _reactions) &&
            (identical(other.threadParentId, threadParentId) ||
                other.threadParentId == threadParentId) &&
            (identical(other.threadReplyCount, threadReplyCount) ||
                other.threadReplyCount == threadReplyCount) &&
            const DeepCollectionEquality().equals(
                other._threadLastReplierAvatars, _threadLastReplierAvatars) &&
            (identical(other.topicId, topicId) || other.topicId == topicId));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hashAll([
        runtimeType,
        id,
        conversationId,
        senderId,
        senderName,
        content,
        sentAt,
        fileUrl,
        fileName,
        fileSize,
        fileType,
        s3Key,
        thumbnailSmallUrl,
        thumbnailMediumUrl,
        thumbnailLargeUrl,
        fileRecordId,
        isDelivered,
        isRead,
        isSystem,
        isEdited,
        const DeepCollectionEquality().hash(_reactions),
        threadParentId,
        threadReplyCount,
        const DeepCollectionEquality().hash(_threadLastReplierAvatars),
        topicId
      ]);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$MessageEntityImplCopyWith<_$MessageEntityImpl> get copyWith =>
      __$$MessageEntityImplCopyWithImpl<_$MessageEntityImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$MessageEntityImplToJson(
      this,
    );
  }
}

abstract class _MessageEntity implements MessageEntity {
  const factory _MessageEntity(
      {required final String id,
      required final String conversationId,
      required final String senderId,
      final String? senderName,
      required final String content,
      required final DateTime sentAt,
      final String? fileUrl,
      final String? fileName,
      final int? fileSize,
      final String? fileType,
      final String? s3Key,
      final String? thumbnailSmallUrl,
      final String? thumbnailMediumUrl,
      final String? thumbnailLargeUrl,
      final String? fileRecordId,
      final bool isDelivered,
      final bool isRead,
      final bool isSystem,
      final bool isEdited,
      final List<Map<String, dynamic>> reactions,
      final String? threadParentId,
      final int threadReplyCount,
      final List<String>? threadLastReplierAvatars,
      final String? topicId}) = _$MessageEntityImpl;

  factory _MessageEntity.fromJson(Map<String, dynamic> json) =
      _$MessageEntityImpl.fromJson;

  @override
  String get id;
  @override
  String get conversationId;
  @override
  String get senderId;
  @override
  String? get senderName;
  @override
  String get content;
  @override
  DateTime get sentAt;
  @override
  String? get fileUrl;
  @override
  String? get fileName;
  @override
  int? get fileSize;
  @override
  String? get fileType;
  @override
  String? get s3Key;
  @override
  String? get thumbnailSmallUrl;
  @override
  String? get thumbnailMediumUrl;
  @override
  String? get thumbnailLargeUrl;
  @override
  String? get fileRecordId;
  @override
  bool get isDelivered;
  @override
  bool get isRead;
  @override
  bool get isSystem;
  @override
  bool get isEdited;
  @override
  List<Map<String, dynamic>> get reactions;
  @override
  String? get threadParentId;
  @override
  int get threadReplyCount;
  @override
  List<String>? get threadLastReplierAvatars;
  @override
  String? get topicId;
  @override
  @JsonKey(ignore: true)
  _$$MessageEntityImplCopyWith<_$MessageEntityImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

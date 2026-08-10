// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'conversation_entity.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

ConversationEntity _$ConversationEntityFromJson(Map<String, dynamic> json) {
  return _ConversationEntity.fromJson(json);
}

/// @nodoc
mixin _$ConversationEntity {
  String get id => throw _privateConstructorUsedError;
  List<String> get participantIds => throw _privateConstructorUsedError;
  String get type => throw _privateConstructorUsedError;
  String? get name => throw _privateConstructorUsedError;
  String? get avatarUrl => throw _privateConstructorUsedError;
  String? get description => throw _privateConstructorUsedError;
  int get participantCount => throw _privateConstructorUsedError;
  String? get myRole => throw _privateConstructorUsedError;
  int? get subscribersCount => throw _privateConstructorUsedError;
  bool? get isSubscribed => throw _privateConstructorUsedError;
  String? get lastMessageContent => throw _privateConstructorUsedError;
  DateTime? get lastMessageAt => throw _privateConstructorUsedError;
  String? get lastMessageSenderId => throw _privateConstructorUsedError;
  String? get lastMessageSenderName => throw _privateConstructorUsedError;
  bool get lastMessageIsSystem => throw _privateConstructorUsedError;
  String? get otherUserName => throw _privateConstructorUsedError;
  String? get otherUserId => throw _privateConstructorUsedError;
  String? get otherUserAvatar => throw _privateConstructorUsedError;
  String? get otherUserStatus => throw _privateConstructorUsedError;
  DateTime? get otherUserLastSeen => throw _privateConstructorUsedError;
  int get unreadCount => throw _privateConstructorUsedError;

  /// Непрочитанные упоминания. Отдельно от [unreadCount]: в шумной группе
  /// «есть непрочитанное» не значит ничего, а «тебя позвали» значит.
  int get mentionCount => throw _privateConstructorUsedError;
  bool get isMuted => throw _privateConstructorUsedError;
  DateTime? get mutedUntil => throw _privateConstructorUsedError;
  String? get activeCallRoomName => throw _privateConstructorUsedError;
  bool get slowMode => throw _privateConstructorUsedError;
  bool get topicsEnabled => throw _privateConstructorUsedError;
  int? get autoDeleteDays => throw _privateConstructorUsedError;
  int get pinnedCount => throw _privateConstructorUsedError;
  PinnedPreviewEntity? get topPinned => throw _privateConstructorUsedError;
  DateTime? get pinsDismissedAt => throw _privateConstructorUsedError;

  /// Персональное состояние беседы в списке чатов. Раньше жило в локальном
  /// Hive и на втором устройстве не существовало.
  ///
  /// [chatPinnedAt] — закрепление беседы в списке; не путать с [pinnedCount]
  /// и [topPinned], это закреплённые сообщения ВНУТРИ беседы.
  String? get draft => throw _privateConstructorUsedError;
  DateTime? get draftAt => throw _privateConstructorUsedError;
  DateTime? get archivedAt => throw _privateConstructorUsedError;
  DateTime? get chatPinnedAt => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $ConversationEntityCopyWith<ConversationEntity> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ConversationEntityCopyWith<$Res> {
  factory $ConversationEntityCopyWith(
          ConversationEntity value, $Res Function(ConversationEntity) then) =
      _$ConversationEntityCopyWithImpl<$Res, ConversationEntity>;
  @useResult
  $Res call(
      {String id,
      List<String> participantIds,
      String type,
      String? name,
      String? avatarUrl,
      String? description,
      int participantCount,
      String? myRole,
      int? subscribersCount,
      bool? isSubscribed,
      String? lastMessageContent,
      DateTime? lastMessageAt,
      String? lastMessageSenderId,
      String? lastMessageSenderName,
      bool lastMessageIsSystem,
      String? otherUserName,
      String? otherUserId,
      String? otherUserAvatar,
      String? otherUserStatus,
      DateTime? otherUserLastSeen,
      int unreadCount,
      int mentionCount,
      bool isMuted,
      DateTime? mutedUntil,
      String? activeCallRoomName,
      bool slowMode,
      bool topicsEnabled,
      int? autoDeleteDays,
      int pinnedCount,
      PinnedPreviewEntity? topPinned,
      DateTime? pinsDismissedAt,
      String? draft,
      DateTime? draftAt,
      DateTime? archivedAt,
      DateTime? chatPinnedAt});

  $PinnedPreviewEntityCopyWith<$Res>? get topPinned;
}

/// @nodoc
class _$ConversationEntityCopyWithImpl<$Res, $Val extends ConversationEntity>
    implements $ConversationEntityCopyWith<$Res> {
  _$ConversationEntityCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? participantIds = null,
    Object? type = null,
    Object? name = freezed,
    Object? avatarUrl = freezed,
    Object? description = freezed,
    Object? participantCount = null,
    Object? myRole = freezed,
    Object? subscribersCount = freezed,
    Object? isSubscribed = freezed,
    Object? lastMessageContent = freezed,
    Object? lastMessageAt = freezed,
    Object? lastMessageSenderId = freezed,
    Object? lastMessageSenderName = freezed,
    Object? lastMessageIsSystem = null,
    Object? otherUserName = freezed,
    Object? otherUserId = freezed,
    Object? otherUserAvatar = freezed,
    Object? otherUserStatus = freezed,
    Object? otherUserLastSeen = freezed,
    Object? unreadCount = null,
    Object? mentionCount = null,
    Object? isMuted = null,
    Object? mutedUntil = freezed,
    Object? activeCallRoomName = freezed,
    Object? slowMode = null,
    Object? topicsEnabled = null,
    Object? autoDeleteDays = freezed,
    Object? pinnedCount = null,
    Object? topPinned = freezed,
    Object? pinsDismissedAt = freezed,
    Object? draft = freezed,
    Object? draftAt = freezed,
    Object? archivedAt = freezed,
    Object? chatPinnedAt = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      participantIds: null == participantIds
          ? _value.participantIds
          : participantIds // ignore: cast_nullable_to_non_nullable
              as List<String>,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as String,
      name: freezed == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String?,
      avatarUrl: freezed == avatarUrl
          ? _value.avatarUrl
          : avatarUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      participantCount: null == participantCount
          ? _value.participantCount
          : participantCount // ignore: cast_nullable_to_non_nullable
              as int,
      myRole: freezed == myRole
          ? _value.myRole
          : myRole // ignore: cast_nullable_to_non_nullable
              as String?,
      subscribersCount: freezed == subscribersCount
          ? _value.subscribersCount
          : subscribersCount // ignore: cast_nullable_to_non_nullable
              as int?,
      isSubscribed: freezed == isSubscribed
          ? _value.isSubscribed
          : isSubscribed // ignore: cast_nullable_to_non_nullable
              as bool?,
      lastMessageContent: freezed == lastMessageContent
          ? _value.lastMessageContent
          : lastMessageContent // ignore: cast_nullable_to_non_nullable
              as String?,
      lastMessageAt: freezed == lastMessageAt
          ? _value.lastMessageAt
          : lastMessageAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      lastMessageSenderId: freezed == lastMessageSenderId
          ? _value.lastMessageSenderId
          : lastMessageSenderId // ignore: cast_nullable_to_non_nullable
              as String?,
      lastMessageSenderName: freezed == lastMessageSenderName
          ? _value.lastMessageSenderName
          : lastMessageSenderName // ignore: cast_nullable_to_non_nullable
              as String?,
      lastMessageIsSystem: null == lastMessageIsSystem
          ? _value.lastMessageIsSystem
          : lastMessageIsSystem // ignore: cast_nullable_to_non_nullable
              as bool,
      otherUserName: freezed == otherUserName
          ? _value.otherUserName
          : otherUserName // ignore: cast_nullable_to_non_nullable
              as String?,
      otherUserId: freezed == otherUserId
          ? _value.otherUserId
          : otherUserId // ignore: cast_nullable_to_non_nullable
              as String?,
      otherUserAvatar: freezed == otherUserAvatar
          ? _value.otherUserAvatar
          : otherUserAvatar // ignore: cast_nullable_to_non_nullable
              as String?,
      otherUserStatus: freezed == otherUserStatus
          ? _value.otherUserStatus
          : otherUserStatus // ignore: cast_nullable_to_non_nullable
              as String?,
      otherUserLastSeen: freezed == otherUserLastSeen
          ? _value.otherUserLastSeen
          : otherUserLastSeen // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      unreadCount: null == unreadCount
          ? _value.unreadCount
          : unreadCount // ignore: cast_nullable_to_non_nullable
              as int,
      mentionCount: null == mentionCount
          ? _value.mentionCount
          : mentionCount // ignore: cast_nullable_to_non_nullable
              as int,
      isMuted: null == isMuted
          ? _value.isMuted
          : isMuted // ignore: cast_nullable_to_non_nullable
              as bool,
      mutedUntil: freezed == mutedUntil
          ? _value.mutedUntil
          : mutedUntil // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      activeCallRoomName: freezed == activeCallRoomName
          ? _value.activeCallRoomName
          : activeCallRoomName // ignore: cast_nullable_to_non_nullable
              as String?,
      slowMode: null == slowMode
          ? _value.slowMode
          : slowMode // ignore: cast_nullable_to_non_nullable
              as bool,
      topicsEnabled: null == topicsEnabled
          ? _value.topicsEnabled
          : topicsEnabled // ignore: cast_nullable_to_non_nullable
              as bool,
      autoDeleteDays: freezed == autoDeleteDays
          ? _value.autoDeleteDays
          : autoDeleteDays // ignore: cast_nullable_to_non_nullable
              as int?,
      pinnedCount: null == pinnedCount
          ? _value.pinnedCount
          : pinnedCount // ignore: cast_nullable_to_non_nullable
              as int,
      topPinned: freezed == topPinned
          ? _value.topPinned
          : topPinned // ignore: cast_nullable_to_non_nullable
              as PinnedPreviewEntity?,
      pinsDismissedAt: freezed == pinsDismissedAt
          ? _value.pinsDismissedAt
          : pinsDismissedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      draft: freezed == draft
          ? _value.draft
          : draft // ignore: cast_nullable_to_non_nullable
              as String?,
      draftAt: freezed == draftAt
          ? _value.draftAt
          : draftAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      archivedAt: freezed == archivedAt
          ? _value.archivedAt
          : archivedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      chatPinnedAt: freezed == chatPinnedAt
          ? _value.chatPinnedAt
          : chatPinnedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }

  @override
  @pragma('vm:prefer-inline')
  $PinnedPreviewEntityCopyWith<$Res>? get topPinned {
    if (_value.topPinned == null) {
      return null;
    }

    return $PinnedPreviewEntityCopyWith<$Res>(_value.topPinned!, (value) {
      return _then(_value.copyWith(topPinned: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$ConversationEntityImplCopyWith<$Res>
    implements $ConversationEntityCopyWith<$Res> {
  factory _$$ConversationEntityImplCopyWith(_$ConversationEntityImpl value,
          $Res Function(_$ConversationEntityImpl) then) =
      __$$ConversationEntityImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      List<String> participantIds,
      String type,
      String? name,
      String? avatarUrl,
      String? description,
      int participantCount,
      String? myRole,
      int? subscribersCount,
      bool? isSubscribed,
      String? lastMessageContent,
      DateTime? lastMessageAt,
      String? lastMessageSenderId,
      String? lastMessageSenderName,
      bool lastMessageIsSystem,
      String? otherUserName,
      String? otherUserId,
      String? otherUserAvatar,
      String? otherUserStatus,
      DateTime? otherUserLastSeen,
      int unreadCount,
      int mentionCount,
      bool isMuted,
      DateTime? mutedUntil,
      String? activeCallRoomName,
      bool slowMode,
      bool topicsEnabled,
      int? autoDeleteDays,
      int pinnedCount,
      PinnedPreviewEntity? topPinned,
      DateTime? pinsDismissedAt,
      String? draft,
      DateTime? draftAt,
      DateTime? archivedAt,
      DateTime? chatPinnedAt});

  @override
  $PinnedPreviewEntityCopyWith<$Res>? get topPinned;
}

/// @nodoc
class __$$ConversationEntityImplCopyWithImpl<$Res>
    extends _$ConversationEntityCopyWithImpl<$Res, _$ConversationEntityImpl>
    implements _$$ConversationEntityImplCopyWith<$Res> {
  __$$ConversationEntityImplCopyWithImpl(_$ConversationEntityImpl _value,
      $Res Function(_$ConversationEntityImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? participantIds = null,
    Object? type = null,
    Object? name = freezed,
    Object? avatarUrl = freezed,
    Object? description = freezed,
    Object? participantCount = null,
    Object? myRole = freezed,
    Object? subscribersCount = freezed,
    Object? isSubscribed = freezed,
    Object? lastMessageContent = freezed,
    Object? lastMessageAt = freezed,
    Object? lastMessageSenderId = freezed,
    Object? lastMessageSenderName = freezed,
    Object? lastMessageIsSystem = null,
    Object? otherUserName = freezed,
    Object? otherUserId = freezed,
    Object? otherUserAvatar = freezed,
    Object? otherUserStatus = freezed,
    Object? otherUserLastSeen = freezed,
    Object? unreadCount = null,
    Object? mentionCount = null,
    Object? isMuted = null,
    Object? mutedUntil = freezed,
    Object? activeCallRoomName = freezed,
    Object? slowMode = null,
    Object? topicsEnabled = null,
    Object? autoDeleteDays = freezed,
    Object? pinnedCount = null,
    Object? topPinned = freezed,
    Object? pinsDismissedAt = freezed,
    Object? draft = freezed,
    Object? draftAt = freezed,
    Object? archivedAt = freezed,
    Object? chatPinnedAt = freezed,
  }) {
    return _then(_$ConversationEntityImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      participantIds: null == participantIds
          ? _value._participantIds
          : participantIds // ignore: cast_nullable_to_non_nullable
              as List<String>,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as String,
      name: freezed == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String?,
      avatarUrl: freezed == avatarUrl
          ? _value.avatarUrl
          : avatarUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      participantCount: null == participantCount
          ? _value.participantCount
          : participantCount // ignore: cast_nullable_to_non_nullable
              as int,
      myRole: freezed == myRole
          ? _value.myRole
          : myRole // ignore: cast_nullable_to_non_nullable
              as String?,
      subscribersCount: freezed == subscribersCount
          ? _value.subscribersCount
          : subscribersCount // ignore: cast_nullable_to_non_nullable
              as int?,
      isSubscribed: freezed == isSubscribed
          ? _value.isSubscribed
          : isSubscribed // ignore: cast_nullable_to_non_nullable
              as bool?,
      lastMessageContent: freezed == lastMessageContent
          ? _value.lastMessageContent
          : lastMessageContent // ignore: cast_nullable_to_non_nullable
              as String?,
      lastMessageAt: freezed == lastMessageAt
          ? _value.lastMessageAt
          : lastMessageAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      lastMessageSenderId: freezed == lastMessageSenderId
          ? _value.lastMessageSenderId
          : lastMessageSenderId // ignore: cast_nullable_to_non_nullable
              as String?,
      lastMessageSenderName: freezed == lastMessageSenderName
          ? _value.lastMessageSenderName
          : lastMessageSenderName // ignore: cast_nullable_to_non_nullable
              as String?,
      lastMessageIsSystem: null == lastMessageIsSystem
          ? _value.lastMessageIsSystem
          : lastMessageIsSystem // ignore: cast_nullable_to_non_nullable
              as bool,
      otherUserName: freezed == otherUserName
          ? _value.otherUserName
          : otherUserName // ignore: cast_nullable_to_non_nullable
              as String?,
      otherUserId: freezed == otherUserId
          ? _value.otherUserId
          : otherUserId // ignore: cast_nullable_to_non_nullable
              as String?,
      otherUserAvatar: freezed == otherUserAvatar
          ? _value.otherUserAvatar
          : otherUserAvatar // ignore: cast_nullable_to_non_nullable
              as String?,
      otherUserStatus: freezed == otherUserStatus
          ? _value.otherUserStatus
          : otherUserStatus // ignore: cast_nullable_to_non_nullable
              as String?,
      otherUserLastSeen: freezed == otherUserLastSeen
          ? _value.otherUserLastSeen
          : otherUserLastSeen // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      unreadCount: null == unreadCount
          ? _value.unreadCount
          : unreadCount // ignore: cast_nullable_to_non_nullable
              as int,
      mentionCount: null == mentionCount
          ? _value.mentionCount
          : mentionCount // ignore: cast_nullable_to_non_nullable
              as int,
      isMuted: null == isMuted
          ? _value.isMuted
          : isMuted // ignore: cast_nullable_to_non_nullable
              as bool,
      mutedUntil: freezed == mutedUntil
          ? _value.mutedUntil
          : mutedUntil // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      activeCallRoomName: freezed == activeCallRoomName
          ? _value.activeCallRoomName
          : activeCallRoomName // ignore: cast_nullable_to_non_nullable
              as String?,
      slowMode: null == slowMode
          ? _value.slowMode
          : slowMode // ignore: cast_nullable_to_non_nullable
              as bool,
      topicsEnabled: null == topicsEnabled
          ? _value.topicsEnabled
          : topicsEnabled // ignore: cast_nullable_to_non_nullable
              as bool,
      autoDeleteDays: freezed == autoDeleteDays
          ? _value.autoDeleteDays
          : autoDeleteDays // ignore: cast_nullable_to_non_nullable
              as int?,
      pinnedCount: null == pinnedCount
          ? _value.pinnedCount
          : pinnedCount // ignore: cast_nullable_to_non_nullable
              as int,
      topPinned: freezed == topPinned
          ? _value.topPinned
          : topPinned // ignore: cast_nullable_to_non_nullable
              as PinnedPreviewEntity?,
      pinsDismissedAt: freezed == pinsDismissedAt
          ? _value.pinsDismissedAt
          : pinsDismissedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      draft: freezed == draft
          ? _value.draft
          : draft // ignore: cast_nullable_to_non_nullable
              as String?,
      draftAt: freezed == draftAt
          ? _value.draftAt
          : draftAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      archivedAt: freezed == archivedAt
          ? _value.archivedAt
          : archivedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      chatPinnedAt: freezed == chatPinnedAt
          ? _value.chatPinnedAt
          : chatPinnedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _$ConversationEntityImpl implements _ConversationEntity {
  const _$ConversationEntityImpl(
      {required this.id,
      required final List<String> participantIds,
      this.type = 'DIRECT',
      this.name,
      this.avatarUrl,
      this.description,
      this.participantCount = 0,
      this.myRole,
      this.subscribersCount,
      this.isSubscribed,
      this.lastMessageContent,
      this.lastMessageAt,
      this.lastMessageSenderId,
      this.lastMessageSenderName,
      this.lastMessageIsSystem = false,
      this.otherUserName,
      this.otherUserId,
      this.otherUserAvatar,
      this.otherUserStatus,
      this.otherUserLastSeen,
      this.unreadCount = 0,
      this.mentionCount = 0,
      this.isMuted = false,
      this.mutedUntil,
      this.activeCallRoomName,
      this.slowMode = false,
      this.topicsEnabled = false,
      this.autoDeleteDays,
      this.pinnedCount = 0,
      this.topPinned,
      this.pinsDismissedAt,
      this.draft,
      this.draftAt,
      this.archivedAt,
      this.chatPinnedAt})
      : _participantIds = participantIds;

  factory _$ConversationEntityImpl.fromJson(Map<String, dynamic> json) =>
      _$$ConversationEntityImplFromJson(json);

  @override
  final String id;
  final List<String> _participantIds;
  @override
  List<String> get participantIds {
    if (_participantIds is EqualUnmodifiableListView) return _participantIds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_participantIds);
  }

  @override
  @JsonKey()
  final String type;
  @override
  final String? name;
  @override
  final String? avatarUrl;
  @override
  final String? description;
  @override
  @JsonKey()
  final int participantCount;
  @override
  final String? myRole;
  @override
  final int? subscribersCount;
  @override
  final bool? isSubscribed;
  @override
  final String? lastMessageContent;
  @override
  final DateTime? lastMessageAt;
  @override
  final String? lastMessageSenderId;
  @override
  final String? lastMessageSenderName;
  @override
  @JsonKey()
  final bool lastMessageIsSystem;
  @override
  final String? otherUserName;
  @override
  final String? otherUserId;
  @override
  final String? otherUserAvatar;
  @override
  final String? otherUserStatus;
  @override
  final DateTime? otherUserLastSeen;
  @override
  @JsonKey()
  final int unreadCount;

  /// Непрочитанные упоминания. Отдельно от [unreadCount]: в шумной группе
  /// «есть непрочитанное» не значит ничего, а «тебя позвали» значит.
  @override
  @JsonKey()
  final int mentionCount;
  @override
  @JsonKey()
  final bool isMuted;
  @override
  final DateTime? mutedUntil;
  @override
  final String? activeCallRoomName;
  @override
  @JsonKey()
  final bool slowMode;
  @override
  @JsonKey()
  final bool topicsEnabled;
  @override
  final int? autoDeleteDays;
  @override
  @JsonKey()
  final int pinnedCount;
  @override
  final PinnedPreviewEntity? topPinned;
  @override
  final DateTime? pinsDismissedAt;

  /// Персональное состояние беседы в списке чатов. Раньше жило в локальном
  /// Hive и на втором устройстве не существовало.
  ///
  /// [chatPinnedAt] — закрепление беседы в списке; не путать с [pinnedCount]
  /// и [topPinned], это закреплённые сообщения ВНУТРИ беседы.
  @override
  final String? draft;
  @override
  final DateTime? draftAt;
  @override
  final DateTime? archivedAt;
  @override
  final DateTime? chatPinnedAt;

  @override
  String toString() {
    return 'ConversationEntity(id: $id, participantIds: $participantIds, type: $type, name: $name, avatarUrl: $avatarUrl, description: $description, participantCount: $participantCount, myRole: $myRole, subscribersCount: $subscribersCount, isSubscribed: $isSubscribed, lastMessageContent: $lastMessageContent, lastMessageAt: $lastMessageAt, lastMessageSenderId: $lastMessageSenderId, lastMessageSenderName: $lastMessageSenderName, lastMessageIsSystem: $lastMessageIsSystem, otherUserName: $otherUserName, otherUserId: $otherUserId, otherUserAvatar: $otherUserAvatar, otherUserStatus: $otherUserStatus, otherUserLastSeen: $otherUserLastSeen, unreadCount: $unreadCount, mentionCount: $mentionCount, isMuted: $isMuted, mutedUntil: $mutedUntil, activeCallRoomName: $activeCallRoomName, slowMode: $slowMode, topicsEnabled: $topicsEnabled, autoDeleteDays: $autoDeleteDays, pinnedCount: $pinnedCount, topPinned: $topPinned, pinsDismissedAt: $pinsDismissedAt, draft: $draft, draftAt: $draftAt, archivedAt: $archivedAt, chatPinnedAt: $chatPinnedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ConversationEntityImpl &&
            (identical(other.id, id) || other.id == id) &&
            const DeepCollectionEquality()
                .equals(other._participantIds, _participantIds) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.avatarUrl, avatarUrl) ||
                other.avatarUrl == avatarUrl) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.participantCount, participantCount) ||
                other.participantCount == participantCount) &&
            (identical(other.myRole, myRole) || other.myRole == myRole) &&
            (identical(other.subscribersCount, subscribersCount) ||
                other.subscribersCount == subscribersCount) &&
            (identical(other.isSubscribed, isSubscribed) ||
                other.isSubscribed == isSubscribed) &&
            (identical(other.lastMessageContent, lastMessageContent) ||
                other.lastMessageContent == lastMessageContent) &&
            (identical(other.lastMessageAt, lastMessageAt) ||
                other.lastMessageAt == lastMessageAt) &&
            (identical(other.lastMessageSenderId, lastMessageSenderId) ||
                other.lastMessageSenderId == lastMessageSenderId) &&
            (identical(other.lastMessageSenderName, lastMessageSenderName) ||
                other.lastMessageSenderName == lastMessageSenderName) &&
            (identical(other.lastMessageIsSystem, lastMessageIsSystem) ||
                other.lastMessageIsSystem == lastMessageIsSystem) &&
            (identical(other.otherUserName, otherUserName) ||
                other.otherUserName == otherUserName) &&
            (identical(other.otherUserId, otherUserId) ||
                other.otherUserId == otherUserId) &&
            (identical(other.otherUserAvatar, otherUserAvatar) ||
                other.otherUserAvatar == otherUserAvatar) &&
            (identical(other.otherUserStatus, otherUserStatus) ||
                other.otherUserStatus == otherUserStatus) &&
            (identical(other.otherUserLastSeen, otherUserLastSeen) ||
                other.otherUserLastSeen == otherUserLastSeen) &&
            (identical(other.unreadCount, unreadCount) ||
                other.unreadCount == unreadCount) &&
            (identical(other.mentionCount, mentionCount) ||
                other.mentionCount == mentionCount) &&
            (identical(other.isMuted, isMuted) || other.isMuted == isMuted) &&
            (identical(other.mutedUntil, mutedUntil) ||
                other.mutedUntil == mutedUntil) &&
            (identical(other.activeCallRoomName, activeCallRoomName) ||
                other.activeCallRoomName == activeCallRoomName) &&
            (identical(other.slowMode, slowMode) ||
                other.slowMode == slowMode) &&
            (identical(other.topicsEnabled, topicsEnabled) ||
                other.topicsEnabled == topicsEnabled) &&
            (identical(other.autoDeleteDays, autoDeleteDays) ||
                other.autoDeleteDays == autoDeleteDays) &&
            (identical(other.pinnedCount, pinnedCount) ||
                other.pinnedCount == pinnedCount) &&
            (identical(other.topPinned, topPinned) ||
                other.topPinned == topPinned) &&
            (identical(other.pinsDismissedAt, pinsDismissedAt) ||
                other.pinsDismissedAt == pinsDismissedAt) &&
            (identical(other.draft, draft) || other.draft == draft) &&
            (identical(other.draftAt, draftAt) || other.draftAt == draftAt) &&
            (identical(other.archivedAt, archivedAt) ||
                other.archivedAt == archivedAt) &&
            (identical(other.chatPinnedAt, chatPinnedAt) ||
                other.chatPinnedAt == chatPinnedAt));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hashAll([
        runtimeType,
        id,
        const DeepCollectionEquality().hash(_participantIds),
        type,
        name,
        avatarUrl,
        description,
        participantCount,
        myRole,
        subscribersCount,
        isSubscribed,
        lastMessageContent,
        lastMessageAt,
        lastMessageSenderId,
        lastMessageSenderName,
        lastMessageIsSystem,
        otherUserName,
        otherUserId,
        otherUserAvatar,
        otherUserStatus,
        otherUserLastSeen,
        unreadCount,
        mentionCount,
        isMuted,
        mutedUntil,
        activeCallRoomName,
        slowMode,
        topicsEnabled,
        autoDeleteDays,
        pinnedCount,
        topPinned,
        pinsDismissedAt,
        draft,
        draftAt,
        archivedAt,
        chatPinnedAt
      ]);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ConversationEntityImplCopyWith<_$ConversationEntityImpl> get copyWith =>
      __$$ConversationEntityImplCopyWithImpl<_$ConversationEntityImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ConversationEntityImplToJson(
      this,
    );
  }
}

abstract class _ConversationEntity implements ConversationEntity {
  const factory _ConversationEntity(
      {required final String id,
      required final List<String> participantIds,
      final String type,
      final String? name,
      final String? avatarUrl,
      final String? description,
      final int participantCount,
      final String? myRole,
      final int? subscribersCount,
      final bool? isSubscribed,
      final String? lastMessageContent,
      final DateTime? lastMessageAt,
      final String? lastMessageSenderId,
      final String? lastMessageSenderName,
      final bool lastMessageIsSystem,
      final String? otherUserName,
      final String? otherUserId,
      final String? otherUserAvatar,
      final String? otherUserStatus,
      final DateTime? otherUserLastSeen,
      final int unreadCount,
      final int mentionCount,
      final bool isMuted,
      final DateTime? mutedUntil,
      final String? activeCallRoomName,
      final bool slowMode,
      final bool topicsEnabled,
      final int? autoDeleteDays,
      final int pinnedCount,
      final PinnedPreviewEntity? topPinned,
      final DateTime? pinsDismissedAt,
      final String? draft,
      final DateTime? draftAt,
      final DateTime? archivedAt,
      final DateTime? chatPinnedAt}) = _$ConversationEntityImpl;

  factory _ConversationEntity.fromJson(Map<String, dynamic> json) =
      _$ConversationEntityImpl.fromJson;

  @override
  String get id;
  @override
  List<String> get participantIds;
  @override
  String get type;
  @override
  String? get name;
  @override
  String? get avatarUrl;
  @override
  String? get description;
  @override
  int get participantCount;
  @override
  String? get myRole;
  @override
  int? get subscribersCount;
  @override
  bool? get isSubscribed;
  @override
  String? get lastMessageContent;
  @override
  DateTime? get lastMessageAt;
  @override
  String? get lastMessageSenderId;
  @override
  String? get lastMessageSenderName;
  @override
  bool get lastMessageIsSystem;
  @override
  String? get otherUserName;
  @override
  String? get otherUserId;
  @override
  String? get otherUserAvatar;
  @override
  String? get otherUserStatus;
  @override
  DateTime? get otherUserLastSeen;
  @override
  int get unreadCount;
  @override

  /// Непрочитанные упоминания. Отдельно от [unreadCount]: в шумной группе
  /// «есть непрочитанное» не значит ничего, а «тебя позвали» значит.
  int get mentionCount;
  @override
  bool get isMuted;
  @override
  DateTime? get mutedUntil;
  @override
  String? get activeCallRoomName;
  @override
  bool get slowMode;
  @override
  bool get topicsEnabled;
  @override
  int? get autoDeleteDays;
  @override
  int get pinnedCount;
  @override
  PinnedPreviewEntity? get topPinned;
  @override
  DateTime? get pinsDismissedAt;
  @override

  /// Персональное состояние беседы в списке чатов. Раньше жило в локальном
  /// Hive и на втором устройстве не существовало.
  ///
  /// [chatPinnedAt] — закрепление беседы в списке; не путать с [pinnedCount]
  /// и [topPinned], это закреплённые сообщения ВНУТРИ беседы.
  String? get draft;
  @override
  DateTime? get draftAt;
  @override
  DateTime? get archivedAt;
  @override
  DateTime? get chatPinnedAt;
  @override
  @JsonKey(ignore: true)
  _$$ConversationEntityImplCopyWith<_$ConversationEntityImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

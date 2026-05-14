// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'calendar_event_entity.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

CalendarEventEntity _$CalendarEventEntityFromJson(Map<String, dynamic> json) {
  return _CalendarEventEntity.fromJson(json);
}

/// @nodoc
mixin _$CalendarEventEntity {
  String get id => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String? get description => throw _privateConstructorUsedError;
  CalendarEventType get type => throw _privateConstructorUsedError;
  DateTime get startAt => throw _privateConstructorUsedError;
  DateTime? get endAt => throw _privateConstructorUsedError;
  bool get allDay => throw _privateConstructorUsedError;
  DateTime? get reminderAt => throw _privateConstructorUsedError;
  bool get reminderSent => throw _privateConstructorUsedError;
  String? get displayTime => throw _privateConstructorUsedError;
  Map<String, dynamic>? get recurrence => throw _privateConstructorUsedError;
  List<String> get contactIds => throw _privateConstructorUsedError;
  String get createdBy => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;
  DateTime get updatedAt => throw _privateConstructorUsedError;
  bool get localPending => throw _privateConstructorUsedError;
  Map<String, dynamic>? get conflictedWith =>
      throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $CalendarEventEntityCopyWith<CalendarEventEntity> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CalendarEventEntityCopyWith<$Res> {
  factory $CalendarEventEntityCopyWith(
          CalendarEventEntity value, $Res Function(CalendarEventEntity) then) =
      _$CalendarEventEntityCopyWithImpl<$Res, CalendarEventEntity>;
  @useResult
  $Res call(
      {String id,
      String title,
      String? description,
      CalendarEventType type,
      DateTime startAt,
      DateTime? endAt,
      bool allDay,
      DateTime? reminderAt,
      bool reminderSent,
      String? displayTime,
      Map<String, dynamic>? recurrence,
      List<String> contactIds,
      String createdBy,
      DateTime createdAt,
      DateTime updatedAt,
      bool localPending,
      Map<String, dynamic>? conflictedWith});
}

/// @nodoc
class _$CalendarEventEntityCopyWithImpl<$Res, $Val extends CalendarEventEntity>
    implements $CalendarEventEntityCopyWith<$Res> {
  _$CalendarEventEntityCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? description = freezed,
    Object? type = null,
    Object? startAt = null,
    Object? endAt = freezed,
    Object? allDay = null,
    Object? reminderAt = freezed,
    Object? reminderSent = null,
    Object? displayTime = freezed,
    Object? recurrence = freezed,
    Object? contactIds = null,
    Object? createdBy = null,
    Object? createdAt = null,
    Object? updatedAt = null,
    Object? localPending = null,
    Object? conflictedWith = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as CalendarEventType,
      startAt: null == startAt
          ? _value.startAt
          : startAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      endAt: freezed == endAt
          ? _value.endAt
          : endAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      allDay: null == allDay
          ? _value.allDay
          : allDay // ignore: cast_nullable_to_non_nullable
              as bool,
      reminderAt: freezed == reminderAt
          ? _value.reminderAt
          : reminderAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      reminderSent: null == reminderSent
          ? _value.reminderSent
          : reminderSent // ignore: cast_nullable_to_non_nullable
              as bool,
      displayTime: freezed == displayTime
          ? _value.displayTime
          : displayTime // ignore: cast_nullable_to_non_nullable
              as String?,
      recurrence: freezed == recurrence
          ? _value.recurrence
          : recurrence // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
      contactIds: null == contactIds
          ? _value.contactIds
          : contactIds // ignore: cast_nullable_to_non_nullable
              as List<String>,
      createdBy: null == createdBy
          ? _value.createdBy
          : createdBy // ignore: cast_nullable_to_non_nullable
              as String,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: null == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      localPending: null == localPending
          ? _value.localPending
          : localPending // ignore: cast_nullable_to_non_nullable
              as bool,
      conflictedWith: freezed == conflictedWith
          ? _value.conflictedWith
          : conflictedWith // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$CalendarEventEntityImplCopyWith<$Res>
    implements $CalendarEventEntityCopyWith<$Res> {
  factory _$$CalendarEventEntityImplCopyWith(_$CalendarEventEntityImpl value,
          $Res Function(_$CalendarEventEntityImpl) then) =
      __$$CalendarEventEntityImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String title,
      String? description,
      CalendarEventType type,
      DateTime startAt,
      DateTime? endAt,
      bool allDay,
      DateTime? reminderAt,
      bool reminderSent,
      String? displayTime,
      Map<String, dynamic>? recurrence,
      List<String> contactIds,
      String createdBy,
      DateTime createdAt,
      DateTime updatedAt,
      bool localPending,
      Map<String, dynamic>? conflictedWith});
}

/// @nodoc
class __$$CalendarEventEntityImplCopyWithImpl<$Res>
    extends _$CalendarEventEntityCopyWithImpl<$Res, _$CalendarEventEntityImpl>
    implements _$$CalendarEventEntityImplCopyWith<$Res> {
  __$$CalendarEventEntityImplCopyWithImpl(_$CalendarEventEntityImpl _value,
      $Res Function(_$CalendarEventEntityImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? description = freezed,
    Object? type = null,
    Object? startAt = null,
    Object? endAt = freezed,
    Object? allDay = null,
    Object? reminderAt = freezed,
    Object? reminderSent = null,
    Object? displayTime = freezed,
    Object? recurrence = freezed,
    Object? contactIds = null,
    Object? createdBy = null,
    Object? createdAt = null,
    Object? updatedAt = null,
    Object? localPending = null,
    Object? conflictedWith = freezed,
  }) {
    return _then(_$CalendarEventEntityImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as CalendarEventType,
      startAt: null == startAt
          ? _value.startAt
          : startAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      endAt: freezed == endAt
          ? _value.endAt
          : endAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      allDay: null == allDay
          ? _value.allDay
          : allDay // ignore: cast_nullable_to_non_nullable
              as bool,
      reminderAt: freezed == reminderAt
          ? _value.reminderAt
          : reminderAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      reminderSent: null == reminderSent
          ? _value.reminderSent
          : reminderSent // ignore: cast_nullable_to_non_nullable
              as bool,
      displayTime: freezed == displayTime
          ? _value.displayTime
          : displayTime // ignore: cast_nullable_to_non_nullable
              as String?,
      recurrence: freezed == recurrence
          ? _value._recurrence
          : recurrence // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
      contactIds: null == contactIds
          ? _value._contactIds
          : contactIds // ignore: cast_nullable_to_non_nullable
              as List<String>,
      createdBy: null == createdBy
          ? _value.createdBy
          : createdBy // ignore: cast_nullable_to_non_nullable
              as String,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: null == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      localPending: null == localPending
          ? _value.localPending
          : localPending // ignore: cast_nullable_to_non_nullable
              as bool,
      conflictedWith: freezed == conflictedWith
          ? _value._conflictedWith
          : conflictedWith // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$CalendarEventEntityImpl implements _CalendarEventEntity {
  const _$CalendarEventEntityImpl(
      {required this.id,
      required this.title,
      this.description,
      this.type = CalendarEventType.event,
      required this.startAt,
      this.endAt,
      this.allDay = false,
      this.reminderAt,
      this.reminderSent = false,
      this.displayTime,
      final Map<String, dynamic>? recurrence,
      final List<String> contactIds = const <String>[],
      this.createdBy = 'MANUAL',
      required this.createdAt,
      required this.updatedAt,
      this.localPending = false,
      final Map<String, dynamic>? conflictedWith})
      : _recurrence = recurrence,
        _contactIds = contactIds,
        _conflictedWith = conflictedWith;

  factory _$CalendarEventEntityImpl.fromJson(Map<String, dynamic> json) =>
      _$$CalendarEventEntityImplFromJson(json);

  @override
  final String id;
  @override
  final String title;
  @override
  final String? description;
  @override
  @JsonKey()
  final CalendarEventType type;
  @override
  final DateTime startAt;
  @override
  final DateTime? endAt;
  @override
  @JsonKey()
  final bool allDay;
  @override
  final DateTime? reminderAt;
  @override
  @JsonKey()
  final bool reminderSent;
  @override
  final String? displayTime;
  final Map<String, dynamic>? _recurrence;
  @override
  Map<String, dynamic>? get recurrence {
    final value = _recurrence;
    if (value == null) return null;
    if (_recurrence is EqualUnmodifiableMapView) return _recurrence;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  final List<String> _contactIds;
  @override
  @JsonKey()
  List<String> get contactIds {
    if (_contactIds is EqualUnmodifiableListView) return _contactIds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_contactIds);
  }

  @override
  @JsonKey()
  final String createdBy;
  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;
  @override
  @JsonKey()
  final bool localPending;
  final Map<String, dynamic>? _conflictedWith;
  @override
  Map<String, dynamic>? get conflictedWith {
    final value = _conflictedWith;
    if (value == null) return null;
    if (_conflictedWith is EqualUnmodifiableMapView) return _conflictedWith;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  @override
  String toString() {
    return 'CalendarEventEntity(id: $id, title: $title, description: $description, type: $type, startAt: $startAt, endAt: $endAt, allDay: $allDay, reminderAt: $reminderAt, reminderSent: $reminderSent, displayTime: $displayTime, recurrence: $recurrence, contactIds: $contactIds, createdBy: $createdBy, createdAt: $createdAt, updatedAt: $updatedAt, localPending: $localPending, conflictedWith: $conflictedWith)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CalendarEventEntityImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.startAt, startAt) || other.startAt == startAt) &&
            (identical(other.endAt, endAt) || other.endAt == endAt) &&
            (identical(other.allDay, allDay) || other.allDay == allDay) &&
            (identical(other.reminderAt, reminderAt) ||
                other.reminderAt == reminderAt) &&
            (identical(other.reminderSent, reminderSent) ||
                other.reminderSent == reminderSent) &&
            (identical(other.displayTime, displayTime) ||
                other.displayTime == displayTime) &&
            const DeepCollectionEquality()
                .equals(other._recurrence, _recurrence) &&
            const DeepCollectionEquality()
                .equals(other._contactIds, _contactIds) &&
            (identical(other.createdBy, createdBy) ||
                other.createdBy == createdBy) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            (identical(other.localPending, localPending) ||
                other.localPending == localPending) &&
            const DeepCollectionEquality()
                .equals(other._conflictedWith, _conflictedWith));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      title,
      description,
      type,
      startAt,
      endAt,
      allDay,
      reminderAt,
      reminderSent,
      displayTime,
      const DeepCollectionEquality().hash(_recurrence),
      const DeepCollectionEquality().hash(_contactIds),
      createdBy,
      createdAt,
      updatedAt,
      localPending,
      const DeepCollectionEquality().hash(_conflictedWith));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$CalendarEventEntityImplCopyWith<_$CalendarEventEntityImpl> get copyWith =>
      __$$CalendarEventEntityImplCopyWithImpl<_$CalendarEventEntityImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$CalendarEventEntityImplToJson(
      this,
    );
  }
}

abstract class _CalendarEventEntity implements CalendarEventEntity {
  const factory _CalendarEventEntity(
      {required final String id,
      required final String title,
      final String? description,
      final CalendarEventType type,
      required final DateTime startAt,
      final DateTime? endAt,
      final bool allDay,
      final DateTime? reminderAt,
      final bool reminderSent,
      final String? displayTime,
      final Map<String, dynamic>? recurrence,
      final List<String> contactIds,
      final String createdBy,
      required final DateTime createdAt,
      required final DateTime updatedAt,
      final bool localPending,
      final Map<String, dynamic>? conflictedWith}) = _$CalendarEventEntityImpl;

  factory _CalendarEventEntity.fromJson(Map<String, dynamic> json) =
      _$CalendarEventEntityImpl.fromJson;

  @override
  String get id;
  @override
  String get title;
  @override
  String? get description;
  @override
  CalendarEventType get type;
  @override
  DateTime get startAt;
  @override
  DateTime? get endAt;
  @override
  bool get allDay;
  @override
  DateTime? get reminderAt;
  @override
  bool get reminderSent;
  @override
  String? get displayTime;
  @override
  Map<String, dynamic>? get recurrence;
  @override
  List<String> get contactIds;
  @override
  String get createdBy;
  @override
  DateTime get createdAt;
  @override
  DateTime get updatedAt;
  @override
  bool get localPending;
  @override
  Map<String, dynamic>? get conflictedWith;
  @override
  @JsonKey(ignore: true)
  _$$CalendarEventEntityImplCopyWith<_$CalendarEventEntityImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

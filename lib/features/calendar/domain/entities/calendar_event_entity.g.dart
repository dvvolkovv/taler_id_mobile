// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'calendar_event_entity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$CalendarEventEntityImpl _$$CalendarEventEntityImplFromJson(
        Map<String, dynamic> json) =>
    _$CalendarEventEntityImpl(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      type: $enumDecodeNullable(_$CalendarEventTypeEnumMap, json['type']) ??
          CalendarEventType.event,
      startAt: DateTime.parse(json['startAt'] as String),
      endAt: json['endAt'] == null
          ? null
          : DateTime.parse(json['endAt'] as String),
      allDay: json['allDay'] as bool? ?? false,
      reminderAt: json['reminderAt'] == null
          ? null
          : DateTime.parse(json['reminderAt'] as String),
      reminderSent: json['reminderSent'] as bool? ?? false,
      displayTime: json['displayTime'] as String?,
      recurrence: json['recurrence'] as Map<String, dynamic>?,
      contactIds: (json['contactIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const <String>[],
      createdBy: json['createdBy'] as String? ?? 'MANUAL',
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      localPending: json['localPending'] as bool? ?? false,
      conflictedWith: json['conflictedWith'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$$CalendarEventEntityImplToJson(
        _$CalendarEventEntityImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'description': instance.description,
      'type': _$CalendarEventTypeEnumMap[instance.type]!,
      'startAt': instance.startAt.toIso8601String(),
      'endAt': instance.endAt?.toIso8601String(),
      'allDay': instance.allDay,
      'reminderAt': instance.reminderAt?.toIso8601String(),
      'reminderSent': instance.reminderSent,
      'displayTime': instance.displayTime,
      'recurrence': instance.recurrence,
      'contactIds': instance.contactIds,
      'createdBy': instance.createdBy,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
      'localPending': instance.localPending,
      'conflictedWith': instance.conflictedWith,
    };

const _$CalendarEventTypeEnumMap = {
  CalendarEventType.call: 'CALL',
  CalendarEventType.event: 'EVENT',
  CalendarEventType.task: 'TASK',
  CalendarEventType.reminder: 'REMINDER',
};

import 'package:freezed_annotation/freezed_annotation.dart';

part 'calendar_event_entity.freezed.dart';
part 'calendar_event_entity.g.dart';

enum CalendarEventType {
  @JsonValue('CALL') call,
  @JsonValue('EVENT') event,
  @JsonValue('TASK') task,
  @JsonValue('REMINDER') reminder,
}

@freezed
class CalendarEventEntity with _$CalendarEventEntity {
  const factory CalendarEventEntity({
    required String id,
    required String title,
    String? description,
    @Default(CalendarEventType.event) CalendarEventType type,
    required DateTime startAt,
    DateTime? endAt,
    @Default(false) bool allDay,
    DateTime? reminderAt,
    @Default(false) bool reminderSent,
    String? displayTime,
    Map<String, dynamic>? recurrence,
    @Default(<String>[]) List<String> contactIds,
    @Default('MANUAL') String createdBy,
    required DateTime createdAt,
    required DateTime updatedAt,
    @Default(false) bool localPending,
    Map<String, dynamic>? conflictedWith,
  }) = _CalendarEventEntity;

  factory CalendarEventEntity.fromJson(Map<String, dynamic> json) =>
      _$CalendarEventEntityFromJson(json);
}

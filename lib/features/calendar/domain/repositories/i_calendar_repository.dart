import '../entities/calendar_event_entity.dart';
import '../../../notes/domain/entities/note_entity.dart' show ConflictResolution;

abstract class ICalendarRepository {
  Stream<List<CalendarEventEntity>> watchAll();
  Future<void> refresh({DateTime? from, DateTime? to});
  Future<CalendarEventEntity> create(CalendarEventEntity draft);
  Future<CalendarEventEntity> update(
    String id, {
    String? title,
    String? description,
    CalendarEventType? type,
    DateTime? startAt,
    DateTime? endAt,
    bool? allDay,
    DateTime? reminderAt,
    String? displayTime,
    Map<String, dynamic>? recurrence,
    List<String>? contactIds,
  });
  Future<void> delete(String id);

  /// Durably delete a real Task (feature `task`) via the outbox: [taskId] is the
  /// backend task id, [viewId] the synthetic calendar entity id ("task:{id}:{date}")
  /// removed optimistically. Retried until the server confirms, so a lost/offline
  /// delete no longer leaves a ghost the app hid but never removed server-side.
  Future<void> deleteTask({required String taskId, required String viewId});

  /// Durably set a real Task's status ('done'|'dropped'|'pending') via the outbox.
  /// [occurrenceDate] (YYYY-MM-DD) marks one routine day; omit for a one-off task.
  /// The affected calendar entity ([viewId]) is removed optimistically.
  Future<void> setTaskStatus({
    required String taskId,
    required String status,
    String? occurrenceDate,
    required String viewId,
  });

  Future<void> resolveConflict(String id, ConflictResolution choice);
  Stream<int> watchPendingCount();
  Stream<int> watchConflictCount();
}

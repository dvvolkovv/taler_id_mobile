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
  Future<void> resolveConflict(String id, ConflictResolution choice);
  Stream<int> watchPendingCount();
  Stream<int> watchConflictCount();
}

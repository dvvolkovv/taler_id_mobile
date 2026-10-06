import 'entities/calendar_event_entity.dart';

/// Whether a (possibly recurring) calendar event occurs on [day] (compared in
/// local time).
///
/// The backend expands a recurring EVENT into one record per occurrence, all
/// sharing the base event id. The local store keys by event id, so those
/// occurrences collapse to a single stored row (whichever upserted last —
/// typically the furthest-future occurrence in the fetch window). Matching a day
/// only against that single stored `startAt` then hides the event on every other
/// occurrence (the "weekly meeting shows on just one date" bug). This re-expands
/// from the recurrence rule so the event shows on all of its occurrence days.
///
/// Task items are surfaced as synthetic per-occurrence rows ("task:{id}:{date}")
/// — already one row per date — so they are matched on their exact date only and
/// never re-expanded here, or a daily routine would show on every day at once.
bool eventOccursOnDay(CalendarEventEntity e, DateTime day) {
  final start = e.startAt.toLocal();
  final s = DateTime(start.year, start.month, start.day);
  final d = DateTime(day.year, day.month, day.day);

  if (s == d) return true; // exact start — covers non-recurring events too
  if (e.id.startsWith('task:')) return false; // tasks are already per-date

  final rec = e.recurrence;
  if (rec == null) return false;

  final freq = (rec['frequency'] as String?)?.toLowerCase();
  final rawInterval = (rec['interval'] as num?)?.toInt() ?? 1;
  final step = rawInterval <= 0 ? 1 : rawInterval;

  switch (freq) {
    case 'daily':
      return d.difference(s).inDays % step == 0;
    case 'weekly':
      if (d.weekday != s.weekday) return false;
      return (d.difference(s).inDays ~/ 7) % step == 0;
    case 'monthly':
      if (d.day != s.day) return false;
      return ((d.year - s.year) * 12 + (d.month - s.month)) % step == 0;
    case 'yearly':
      if (d.month != s.month || d.day != s.day) return false;
      return (d.year - s.year) % step == 0;
    default:
      return false;
  }
}

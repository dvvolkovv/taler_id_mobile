import 'package:flutter_test/flutter_test.dart';
import 'package:taler_id_mobile/features/calendar/domain/entities/calendar_event_entity.dart';
import 'package:taler_id_mobile/features/calendar/domain/recurrence_match.dart';

CalendarEventEntity ev(
  String id,
  String startUtc, {
  Map<String, dynamic>? recurrence,
}) =>
    CalendarEventEntity(
      id: id,
      title: 'T',
      startAt: DateTime.parse(startUtc),
      createdAt: DateTime.parse('2026-01-01T00:00:00Z'),
      updatedAt: DateTime.parse('2026-01-01T00:00:00Z'),
      recurrence: recurrence,
    );

DateTime day(String ymd) => DateTime.parse('${ymd}T12:00:00');

void main() {
  group('eventOccursOnDay', () {
    test('non-recurring matches only its own day', () {
      final e = ev('e1', '2026-10-06T05:00:00.000Z');
      expect(eventOccursOnDay(e, day('2026-10-06')), isTrue);
      expect(eventOccursOnDay(e, day('2026-10-07')), isFalse);
      expect(eventOccursOnDay(e, day('2026-10-13')), isFalse);
    });

    // The 2Димы bug: weekly event whose stored row collapsed to the furthest
    // occurrence (Dec 29) must still show on an earlier occurrence (today).
    test('weekly shows on every same-weekday occurrence, incl. before stored row',
        () {
      final e = ev('be116d3e', '2026-12-29T05:00:00.000Z',
          recurrence: {'frequency': 'weekly', 'interval': 1}); // Tuesdays
      expect(eventOccursOnDay(e, day('2026-10-06')), isTrue); // Tue, today
      expect(eventOccursOnDay(e, day('2026-10-13')), isTrue); // Tue
      expect(eventOccursOnDay(e, day('2026-12-29')), isTrue); // Tue, stored
      expect(eventOccursOnDay(e, day('2026-10-07')), isFalse); // Wed
    });

    test('weekly interval 2 skips the off weeks', () {
      final e = ev('e1', '2026-10-06T05:00:00.000Z',
          recurrence: {'frequency': 'weekly', 'interval': 2});
      expect(eventOccursOnDay(e, day('2026-10-06')), isTrue);
      expect(eventOccursOnDay(e, day('2026-10-20')), isTrue); // +2w
      expect(eventOccursOnDay(e, day('2026-10-13')), isFalse); // +1w (off)
    });

    test('daily matches every day', () {
      final e = ev('e1', '2026-10-06T05:00:00.000Z',
          recurrence: {'frequency': 'daily', 'interval': 1});
      expect(eventOccursOnDay(e, day('2026-10-07')), isTrue);
      expect(eventOccursOnDay(e, day('2026-11-01')), isTrue);
    });

    test('monthly matches same day-of-month', () {
      final e = ev('e1', '2026-10-06T05:00:00.000Z',
          recurrence: {'frequency': 'monthly', 'interval': 1});
      expect(eventOccursOnDay(e, day('2026-11-06')), isTrue);
      expect(eventOccursOnDay(e, day('2026-11-07')), isFalse);
    });

    test('yearly matches same month+day', () {
      final e = ev('e1', '2026-10-06T05:00:00.000Z',
          recurrence: {'frequency': 'yearly', 'interval': 1});
      expect(eventOccursOnDay(e, day('2027-10-06')), isTrue);
      expect(eventOccursOnDay(e, day('2027-10-07')), isFalse);
    });

    // Task items are already per-date synthetic rows — must NOT be re-expanded,
    // or a daily routine would appear on every day at once.
    test('task items are matched on exact date only, never re-expanded', () {
      final t = ev('task:abc:2026-10-06', '2026-10-06T05:00:00.000Z',
          recurrence: {'frequency': 'daily', 'interval': 1});
      expect(eventOccursOnDay(t, day('2026-10-06')), isTrue);
      expect(eventOccursOnDay(t, day('2026-10-07')), isFalse);
    });
  });
}

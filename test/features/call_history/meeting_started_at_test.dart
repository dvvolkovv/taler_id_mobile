import 'package:flutter_test/flutter_test.dart';
import 'package:taler_id_mobile/features/call_history/presentation/screens/call_history_screen.dart';

/// Строка встречи заводится в момент остановки записи, поэтому `createdAt` —
/// это её конец. Карточка показывала его как время встречи: запись с 9:01 до
/// 9:33 значилась «в 9:33», и выглядело так, будто её включили на полчаса
/// позже.
void main() {
  group('meetingStartedAt', () {
    test('steps back from the stop moment by the recorded duration', () {
      final started = meetingStartedAt({
        'createdAt': '2026-11-17T06:33:16.034Z',
        'durationSec': 1910,
      });
      expect(started, DateTime.utc(2026, 11, 17, 6, 1, 26, 34));
    });

    test('without a duration falls back to the row time', () {
      final created = DateTime.utc(2026, 11, 17, 6, 33, 16);
      expect(
        meetingStartedAt({'createdAt': created.toIso8601String()}),
        created,
      );
      expect(
        meetingStartedAt({'createdAt': created.toIso8601String(), 'durationSec': 0}),
        created,
      );
    });

    test('a duration of the wrong type is ignored, not thrown on', () {
      final created = DateTime.utc(2026, 11, 17, 6, 33, 16);
      expect(
        meetingStartedAt({'createdAt': created.toIso8601String(), 'durationSec': '1910'}),
        created,
      );
    });

    test('an unreadable row time gives null', () {
      expect(meetingStartedAt({'createdAt': 'not a date', 'durationSec': 60}), isNull);
      expect(meetingStartedAt({}), isNull);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:taler_id_mobile/features/interpreter/data/pending_interpreter_join.dart';

void main() {
  group('PendingInterpreterJoin', () {
    late PendingInterpreterJoin pending;
    late DateTime fakeNow;

    setUp(() {
      fakeNow = DateTime.utc(2026, 11, 1, 12, 0, 0);
      pending = PendingInterpreterJoin(now: () => fakeNow);
    });

    test('consume returns null when nothing was saved', () {
      expect(pending.consume(), isNull);
    });

    test('consume returns the saved code', () {
      pending.save('ABCD1234');
      expect(pending.consume(), 'ABCD1234');
    });

    test('consume is one-shot — a second call returns null', () {
      pending.save('ABCD1234');
      pending.consume();
      expect(pending.consume(), isNull);
    });

    test('consume within the 5-minute TTL returns the code', () {
      pending.save('ABCD1234');
      fakeNow = fakeNow.add(const Duration(minutes: 4));
      expect(pending.consume(), 'ABCD1234');
    });

    test('consume past the TTL returns null and clears the slot', () {
      pending.save('ABCD1234');
      fakeNow = fakeNow.add(const Duration(minutes: 6));
      expect(pending.consume(), isNull);
      // Clearing even on expiry matters — otherwise a later, correctly-timed
      // consume would wrongly resurrect the stale code.
      fakeNow = fakeNow.subtract(const Duration(minutes: 6));
      expect(pending.consume(), isNull);
    });

    test('consume on the exact TTL boundary returns null', () {
      pending.save('ABCD1234');
      fakeNow = fakeNow.add(const Duration(minutes: 5));
      expect(pending.consume(), isNull);
    });

    test(
        'consume returns null when the device clock was corrected backwards '
        'between save and consume', () {
      pending.save('ABCD1234');
      fakeNow = fakeNow.subtract(const Duration(minutes: 1));
      expect(pending.consume(), isNull);
    });

    test('save overwrites a previous, not yet consumed code', () {
      pending.save('FIRST111');
      pending.save('SECOND22');
      expect(pending.consume(), 'SECOND22');
    });
  });
}

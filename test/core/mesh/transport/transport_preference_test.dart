import 'package:flutter_test/flutter_test.dart';

import 'package:taler_id_mobile/core/mesh/transport/transport_preference.dart';

void main() {
  group('TransportPreference', () {
    test('bonjour beats ble when both available', () {
      final pref = TransportPreference();
      final choice = pref.chooseAmong({TransportId.ble, TransportId.bonjour});
      expect(choice, equals(TransportId.bonjour));
    });

    test('ble only when bonjour absent', () {
      final pref = TransportPreference();
      expect(
        pref.chooseAmong({TransportId.ble}),
        equals(TransportId.ble),
      );
    });

    test('bonjour only when ble absent', () {
      final pref = TransportPreference();
      expect(
        pref.chooseAmong({TransportId.bonjour}),
        equals(TransportId.bonjour),
      );
    });

    test('throws on empty set', () {
      final pref = TransportPreference();
      expect(() => pref.chooseAmong({}), throwsStateError);
    });

    test('orderedAmong returns bonjour first, then ble', () {
      final pref = TransportPreference();
      expect(
        pref.orderedAmong({TransportId.ble, TransportId.bonjour}),
        equals([TransportId.bonjour, TransportId.ble]),
      );
    });
  });
}

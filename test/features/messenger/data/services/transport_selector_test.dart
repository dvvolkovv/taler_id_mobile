import 'package:flutter_test/flutter_test.dart';

import 'package:taler_id_mobile/features/messenger/data/services/transport_selector.dart';

void main() {
  group('TransportSelector', () {
    TransportSelector build({
      required bool socket,
      required bool peer,
      required bool fallback,
    }) =>
        TransportSelector(
          isSocketConnected: () => socket,
          isPeerVisibleFor: (_) => peer,
          offlineFallbackEnabled: () => fallback,
        );

    test('socket connected → server', () {
      expect(
        build(socket: true, peer: true, fallback: true).chooseFor('u-1'),
        equals(TransportChoice.server),
      );
      expect(
        build(socket: true, peer: false, fallback: false).chooseFor('u-1'),
        equals(TransportChoice.server),
      );
    });

    test('socket off, peer visible, fallback on → mesh', () {
      expect(
        build(socket: false, peer: true, fallback: true).chooseFor('u-1'),
        equals(TransportChoice.mesh),
      );
    });

    test('socket off, peer visible, fallback OFF → offline', () {
      expect(
        build(socket: false, peer: true, fallback: false).chooseFor('u-1'),
        equals(TransportChoice.offline),
      );
    });

    test('socket off, peer not visible → offline', () {
      expect(
        build(socket: false, peer: false, fallback: true).chooseFor('u-1'),
        equals(TransportChoice.offline),
      );
    });
  });
}

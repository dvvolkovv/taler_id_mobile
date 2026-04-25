import 'package:flutter_test/flutter_test.dart';

import 'package:taler_id_mobile/core/mesh/transport/ble/ble_peer_registry.dart';
import 'package:taler_id_mobile/core/mesh/transport/peer_id.dart';

void main() {
  group('BlePeerRegistry', () {
    test('shouldInitiate returns true when our pk < theirs', () {
      final mine = PeerId.fromHex('a' * 64);
      final theirs = PeerId.fromHex('b' * 64);
      final reg = BlePeerRegistry(selfPk: mine);

      expect(reg.shouldInitiate(theirs), isTrue);
    });

    test('shouldInitiate returns false when our pk > theirs', () {
      final mine = PeerId.fromHex('c' * 64);
      final theirs = PeerId.fromHex('b' * 64);
      final reg = BlePeerRegistry(selfPk: mine);

      expect(reg.shouldInitiate(theirs), isFalse);
    });

    test('shouldInitiate returns false when equal (reject self-connect)',
        () {
      final mine = PeerId.fromHex('a' * 64);
      final reg = BlePeerRegistry(selfPk: mine);

      expect(reg.shouldInitiate(mine), isFalse);
    });

    test('mark/get roundtrip preserves BleLinkState', () {
      final mine = PeerId.fromHex('a' * 64);
      final theirs = PeerId.fromHex('b' * 64);
      final reg = BlePeerRegistry(selfPk: mine);

      expect(reg.stateOf(theirs), equals(BleLinkState.idle));
      reg.mark(theirs, BleLinkState.connecting);
      expect(reg.stateOf(theirs), equals(BleLinkState.connecting));
      reg.mark(theirs, BleLinkState.connected);
      expect(reg.stateOf(theirs), equals(BleLinkState.connected));
    });

    test('forget resets state to idle', () {
      final mine = PeerId.fromHex('a' * 64);
      final theirs = PeerId.fromHex('b' * 64);
      final reg = BlePeerRegistry(selfPk: mine);

      reg.mark(theirs, BleLinkState.connected);
      reg.forget(theirs);
      expect(reg.stateOf(theirs), equals(BleLinkState.idle));
    });

    test('allConnected returns currently-connected peers', () {
      final mine = PeerId.fromHex('a' * 64);
      final p1 = PeerId.fromHex('b' * 64);
      final p2 = PeerId.fromHex('c' * 64);
      final p3 = PeerId.fromHex('d' * 64);
      final reg = BlePeerRegistry(selfPk: mine);

      reg.mark(p1, BleLinkState.connected);
      reg.mark(p2, BleLinkState.connecting);
      reg.mark(p3, BleLinkState.connected);

      final connected = reg.allConnected().toSet();
      expect(connected, equals({p1, p3}));
    });
  });
}

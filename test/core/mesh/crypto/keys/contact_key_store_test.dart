import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:taler_id_mobile/core/mesh/crypto/keys/contact_key_store.dart';
import 'package:taler_id_mobile/core/mesh/transport/peer_id.dart';

void main() {
  group('ContactKeyStore', () {
    late ContactKeyStore store;

    setUp(() {
      store = ContactKeyStore();
    });

    test('empty by default', () {
      final pk = PeerId(Uint8List.fromList(List.filled(32, 1)));
      expect(store.isKnownDevice(pk), isFalse);
      expect(store.lookupUserByDevice(pk), isNull);
    });

    test('addContact registers user and their devices', () {
      final userPk = PeerId(Uint8List.fromList(List.filled(32, 0xAA)));
      final device1 = PeerId(Uint8List.fromList(List.filled(32, 0xBB)));
      final device2 = PeerId(Uint8List.fromList(List.filled(32, 0xCC)));
      store.addContact(userPk: userPk, devicePks: [device1, device2]);

      expect(store.isKnownDevice(device1), isTrue);
      expect(store.isKnownDevice(device2), isTrue);
      expect(store.lookupUserByDevice(device1), equals(userPk));
      expect(store.lookupUserByDevice(device2), equals(userPk));
    });

    test('devicesFor returns all devices of user', () {
      final userPk = PeerId(Uint8List.fromList(List.filled(32, 0xAA)));
      final d1 = PeerId(Uint8List.fromList(List.filled(32, 0xBB)));
      final d2 = PeerId(Uint8List.fromList(List.filled(32, 0xCC)));
      store.addContact(userPk: userPk, devicePks: [d1, d2]);
      final devices = store.devicesFor(userPk);
      expect(devices, containsAll([d1, d2]));
      expect(devices.length, 2);
    });

    test('removeDevice unbinds single device', () {
      final userPk = PeerId(Uint8List.fromList(List.filled(32, 0xAA)));
      final d1 = PeerId(Uint8List.fromList(List.filled(32, 0xBB)));
      final d2 = PeerId(Uint8List.fromList(List.filled(32, 0xCC)));
      store.addContact(userPk: userPk, devicePks: [d1, d2]);
      store.removeDevice(d1);
      expect(store.isKnownDevice(d1), isFalse);
      expect(store.isKnownDevice(d2), isTrue);
      expect(store.devicesFor(userPk), equals([d2]));
    });
  });
}

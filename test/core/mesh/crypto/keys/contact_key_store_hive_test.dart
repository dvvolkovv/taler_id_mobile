import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:taler_id_mobile/core/mesh/crypto/keys/contact_key_store.dart';
import 'package:taler_id_mobile/core/mesh/crypto/keys/contact_key_store_hive.dart';
import 'package:taler_id_mobile/core/mesh/crypto/keys/device_cert.dart';
import 'package:taler_id_mobile/core/mesh/transport/peer_id.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_test_');
    Hive.init(tempDir.path);
  });

  tearDown(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('HiveContactKeyStore', () {
    test('addContact persists across instances', () async {
      final store1 = await HiveContactKeyStore.open(boxName: 'test-contacts-1');
      final userPk = PeerId(Uint8List.fromList(List.filled(32, 0xAA)));
      final cert = DeviceCert(
        devicePk: 'ab' * 32,
        userId: 'user-1',
        userPk: null,
        algorithm: 'X25519',
        validUntilEpochMs: DateTime.now()
            .add(const Duration(days: 30))
            .millisecondsSinceEpoch,
        signature: 'ff' * 64,
      );
      await store1.addContactCerts(userPk: userPk, certs: [cert]);
      expect(store1.isKnownDevice(PeerId.fromHex(cert.devicePk)), isTrue);
      await store1.close();

      final store2 = await HiveContactKeyStore.open(boxName: 'test-contacts-1');
      expect(store2.isKnownDevice(PeerId.fromHex(cert.devicePk)), isTrue);
      expect(store2.lookupUserByDevice(PeerId.fromHex(cert.devicePk)),
          equals(userPk));
      await store2.close();
    });

    test('removeDevice removes persisted entry', () async {
      final store = await HiveContactKeyStore.open(boxName: 'test-contacts-2');
      final userPk = PeerId(Uint8List.fromList(List.filled(32, 0xBB)));
      final cert = DeviceCert(
        devicePk: 'cd' * 32,
        userId: 'user-2',
        userPk: null,
        algorithm: 'X25519',
        validUntilEpochMs: DateTime.now()
            .add(const Duration(days: 30))
            .millisecondsSinceEpoch,
        signature: '00' * 64,
      );
      await store.addContactCerts(userPk: userPk, certs: [cert]);
      await store.removeDevice(PeerId.fromHex(cert.devicePk));
      expect(store.isKnownDevice(PeerId.fromHex(cert.devicePk)), isFalse);
      await store.close();

      final reopened = await HiveContactKeyStore.open(boxName: 'test-contacts-2');
      expect(reopened.isKnownDevice(PeerId.fromHex(cert.devicePk)), isFalse);
      await reopened.close();
    });

    test('userId ↔ userPk mapping round-trips', () async {
      final store = await HiveContactKeyStore.open(boxName: 'userid-map-test');
      await store.putContactUserIdMapping(
        contactUserId: 'contact-uuid-1',
        userPk: PeerId.fromHex('a' * 64),
      );
      expect(
        store.userPkForContactUserId('contact-uuid-1')?.toHex(),
        equals('a' * 64),
      );
      expect(store.userPkForContactUserId('unknown'), isNull);
      await store.close();
    });

    test('allUserIdMappings returns all stored userId mappings', () async {
      final store = await HiveContactKeyStore.open(boxName: 'userid-map-all-test');
      await store.putContactUserIdMapping(
        contactUserId: 'user-a',
        userPk: PeerId.fromHex('a' * 64),
      );
      await store.putContactUserIdMapping(
        contactUserId: 'user-b',
        userPk: PeerId.fromHex('b' * 64),
      );
      final mappings = store.allUserIdMappings().toList();
      expect(mappings.length, 2);
      final ids = mappings.map((e) => e.$1).toSet();
      expect(ids, containsAll(['user-a', 'user-b']));
      await store.close();
    });

    test('userId mappings do not appear in devicesFor results', () async {
      final store = await HiveContactKeyStore.open(boxName: 'userid-no-device-test');
      final userPk = PeerId(Uint8List.fromList(List.filled(32, 0xAA)));
      // Add a userId mapping with the same hex as userPk.
      await store.putContactUserIdMapping(
        contactUserId: 'some-user',
        userPk: userPk,
      );
      // devicesFor should return an empty list because no cert entries exist.
      final devices = store.devicesFor(userPk);
      expect(devices, isEmpty);
      await store.close();
    });

    test('devicesFor returns all devices of user', () async {
      final store = await HiveContactKeyStore.open(boxName: 'test-contacts-3');
      final userPk = PeerId(Uint8List.fromList(List.filled(32, 0xCC)));
      final cert1 = DeviceCert(
        devicePk: '11' * 32,
        userId: 'user-3',
        userPk: null,
        algorithm: 'X25519',
        validUntilEpochMs: DateTime.now()
            .add(const Duration(days: 30))
            .millisecondsSinceEpoch,
        signature: 'aa' * 64,
      );
      final cert2 = DeviceCert(
        devicePk: '22' * 32,
        userId: 'user-3',
        userPk: null,
        algorithm: 'X25519',
        validUntilEpochMs: DateTime.now()
            .add(const Duration(days: 30))
            .millisecondsSinceEpoch,
        signature: 'bb' * 64,
      );
      await store.addContactCerts(userPk: userPk, certs: [cert1, cert2]);
      final devices = store.devicesFor(userPk);
      expect(devices.length, 2);
      expect(devices.map((d) => d.toHex()), containsAll(['11' * 32, '22' * 32]));
      await store.close();
    });
  });

  group('HiveContactKeyStore bridgeIntoInMemory (Phase 1g)', () {
    test('populates the in-memory store with all stored certs', () async {
      final hiveStore = await HiveContactKeyStore.open(boxName: 'bridge-1');

      final userPk = PeerId(Uint8List.fromList(List.filled(32, 0x11)));
      final cert = DeviceCert(
        devicePk: 'ee' * 32,
        userId: 'user-2',
        userPk: null,
        algorithm: 'X25519',
        validUntilEpochMs: DateTime.now()
            .add(const Duration(days: 30))
            .millisecondsSinceEpoch,
        signature: 'aa' * 64,
      );
      await hiveStore.addContactCerts(userPk: userPk, certs: [cert]);
      await hiveStore.putContactUserIdMapping(
        contactUserId: 'user-2',
        userPk: userPk,
      );

      final inMemory = ContactKeyStore();
      final devicePk = PeerId.fromHex(cert.devicePk);
      expect(inMemory.isKnownDevice(devicePk), isFalse,
          reason: 'empty before bridge');

      hiveStore.bridgeIntoInMemory(inMemory);

      expect(inMemory.isKnownDevice(devicePk), isTrue);
      expect(inMemory.lookupUserByDevice(devicePk), equals(userPk));
      expect(inMemory.devicesFor(userPk).length, 1);

      await hiveStore.close();
    });

    test('is a no-op when Hive is empty', () async {
      final hiveStore = await HiveContactKeyStore.open(boxName: 'bridge-2');
      final inMemory = ContactKeyStore();
      // Should not throw.
      hiveStore.bridgeIntoInMemory(inMemory);
      expect(inMemory.isKnownDevice(PeerId.fromHex('a' * 64)), isFalse);
      await hiveStore.close();
    });

    test('dedupes by userPk across multiple userId mappings (same userPk)',
        () async {
      final hiveStore = await HiveContactKeyStore.open(boxName: 'bridge-3');

      final userPk = PeerId(Uint8List.fromList(List.filled(32, 0x22)));
      final cert = DeviceCert(
        devicePk: 'ff' * 32,
        userId: 'user-2',
        userPk: null,
        algorithm: 'X25519',
        validUntilEpochMs: DateTime.now()
            .add(const Duration(days: 30))
            .millisecondsSinceEpoch,
        signature: 'bb' * 64,
      );
      await hiveStore.addContactCerts(userPk: userPk, certs: [cert]);
      // Two userId → same userPk mappings (shouldn't happen in practice but
      // tests the dedup guard).
      await hiveStore.putContactUserIdMapping(
        contactUserId: 'user-2',
        userPk: userPk,
      );
      await hiveStore.putContactUserIdMapping(
        contactUserId: 'user-2-alias',
        userPk: userPk,
      );

      final inMemory = ContactKeyStore();
      hiveStore.bridgeIntoInMemory(inMemory);

      expect(inMemory.devicesFor(userPk).length, 1);

      await hiveStore.close();
    });
  });
}

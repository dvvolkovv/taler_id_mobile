import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:taler_id_mobile/core/mesh/crypto/keys/mesh_key_persistence.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('mesh_keys_test_');
    Hive.init(tempDir.path);
  });

  tearDown(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('MeshKeyPersistence', () {
    test('loadOrRotateDeviceKey generates on empty box and reports didRotate=true',
        () async {
      final p = await MeshKeyPersistence.open(boxName: 'mkp-1');
      final (key, didRotate) = await p.loadOrRotateDeviceKey();
      expect(didRotate, isTrue);
      expect(key.publicKey.length, 32);
      await p.close();
    });

    test('second call returns same DeviceKey and didRotate=false', () async {
      final p1 = await MeshKeyPersistence.open(boxName: 'mkp-2');
      final (k1, r1) = await p1.loadOrRotateDeviceKey();
      expect(r1, isTrue);
      await p1.close();

      final p2 = await MeshKeyPersistence.open(boxName: 'mkp-2');
      final (k2, r2) = await p2.loadOrRotateDeviceKey();
      expect(r2, isFalse);
      expect(k2.publicKey, equals(k1.publicKey));
      await p2.close();
    });

    test('DeviceKey rotates when stored createdAt is older than 30 days',
        () async {
      final p = await MeshKeyPersistence.open(boxName: 'mkp-3');
      final (k1, _) = await p.loadOrRotateDeviceKey(
        now: DateTime(2026, 1, 1),
      );

      // 31 days later → rotation required
      final (k2, didRotate) = await p.loadOrRotateDeviceKey(
        now: DateTime(2026, 2, 1),
      );
      expect(didRotate, isTrue);
      expect(k2.publicKey, isNot(equals(k1.publicKey)));
      await p.close();
    });

    test('loadOrRotateMeshStaticKey mirrors DeviceKey behavior', () async {
      final p = await MeshKeyPersistence.open(boxName: 'mkp-4');
      final (k1, r1) = await p.loadOrRotateMeshStaticKey();
      expect(r1, isTrue);
      expect(k1.publicKey.length, 32);

      final (k2, r2) = await p.loadOrRotateMeshStaticKey();
      expect(r2, isFalse);
      expect(k2.publicKey, equals(k1.publicKey));

      final (k3, r3) = await p.loadOrRotateMeshStaticKey(
        now: DateTime.now().add(const Duration(days: 31)),
      );
      expect(r3, isTrue);
      expect(k3.publicKey, isNot(equals(k1.publicKey)));
      await p.close();
    });
  });
}

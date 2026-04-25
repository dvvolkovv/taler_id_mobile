import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:taler_id_mobile/core/mesh/crypto/keys/device_key.dart';

void main() {
  group('DeviceKey', () {
    test('generate creates 32-byte keys', () async {
      final key = await DeviceKey.generate();
      expect(key.publicKey.length, 32);
      expect(key.privateKeyBytes.length, 32);
    });

    test('signs and verifies message', () async {
      final key = await DeviceKey.generate();
      final msg = Uint8List.fromList([1, 2, 3, 4, 5]);
      final sig = await key.sign(msg);
      expect(sig.length, 64);
      final ok = await DeviceKey.verify(
        publicKey: key.publicKey,
        message: msg,
        signature: sig,
      );
      expect(ok, isTrue);
    });

    test('rejects signature with wrong public key', () async {
      final key = await DeviceKey.generate();
      final other = await DeviceKey.generate();
      final msg = Uint8List.fromList([1, 2, 3]);
      final sig = await key.sign(msg);
      final ok = await DeviceKey.verify(
        publicKey: other.publicKey,
        message: msg,
        signature: sig,
      );
      expect(ok, isFalse);
    });

    test('rejects tampered message', () async {
      final key = await DeviceKey.generate();
      final msg = Uint8List.fromList([1, 2, 3]);
      final sig = await key.sign(msg);
      final tampered = Uint8List.fromList([1, 2, 4]);
      final ok = await DeviceKey.verify(
        publicKey: key.publicKey,
        message: tampered,
        signature: sig,
      );
      expect(ok, isFalse);
    });

    test('fromPrivateKeyBytes reproduces keypair', () async {
      final key = await DeviceKey.generate();
      final reloaded = await DeviceKey.fromPrivateKeyBytes(key.privateKeyBytes);
      expect(reloaded.publicKey, equals(key.publicKey));
    });
  });
}

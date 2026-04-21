import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:taler_id_mobile/core/mesh/crypto/keys/mesh_static_key.dart';

void main() {
  group('MeshStaticKey', () {
    test('generate produces 32-byte X25519 keys', () async {
      final key = await MeshStaticKey.generate();
      expect(key.publicKey.length, 32);
      expect(key.privateKeyBytes.length, 32);
    });

    test('fromPrivateKeyBytes reproduces public key', () async {
      final a = await MeshStaticKey.generate();
      final b = await MeshStaticKey.fromPrivateKeyBytes(a.privateKeyBytes);
      expect(b.publicKey, equals(a.publicKey));
    });

    test('fromPrivateKeyBytes rejects wrong length', () async {
      expect(
        () => MeshStaticKey.fromPrivateKeyBytes(Uint8List(31)),
        throwsArgumentError,
      );
    });
  });
}

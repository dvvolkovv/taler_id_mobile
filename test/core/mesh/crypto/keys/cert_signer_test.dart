import 'package:flutter_test/flutter_test.dart';
import 'package:taler_id_mobile/core/mesh/crypto/keys/cert_signer.dart';
import 'package:taler_id_mobile/core/mesh/crypto/keys/device_cert.dart';
import 'package:taler_id_mobile/core/mesh/crypto/keys/device_key.dart';
import 'package:taler_id_mobile/core/mesh/crypto/keys/mesh_static_key.dart';

void main() {
  group('CertSigner', () {
    test('sign + verify round-trip succeeds', () async {
      final signing = await DeviceKey.generate();       // Ed25519
      final mesh = await MeshStaticKey.generate();       // X25519
      final signer = CertSigner(signingKey: signing);

      final cert = await signer.sign(
        meshPublicKey: mesh.publicKey,
        userId: 'user-1',
        validUntilEpochMs: DateTime.now()
            .add(const Duration(days: 30))
            .millisecondsSinceEpoch,
      );

      expect(cert.devicePk.length, 64);
      expect(cert.signature.length, 128);
      expect(cert.algorithm, 'X25519');

      final ok = await CertSigner.verify(
        cert: cert,
        signingPublicKey: signing.publicKey,
      );
      expect(ok, isTrue);
    });

    test('verify rejects tampered cert', () async {
      final signing = await DeviceKey.generate();
      final mesh = await MeshStaticKey.generate();
      final signer = CertSigner(signingKey: signing);
      final cert = await signer.sign(
        meshPublicKey: mesh.publicKey,
        userId: 'user-1',
        validUntilEpochMs: DateTime.now()
            .add(const Duration(days: 30))
            .millisecondsSinceEpoch,
      );

      final tampered = DeviceCert(
        devicePk: cert.devicePk,
        userId: 'user-2', // CHANGED
        algorithm: cert.algorithm,
        validUntilEpochMs: cert.validUntilEpochMs,
        signature: cert.signature,
      );

      final ok = await CertSigner.verify(
        cert: tampered,
        signingPublicKey: signing.publicKey,
      );
      expect(ok, isFalse);
    });

    test('verify rejects different signing key', () async {
      final signing = await DeviceKey.generate();
      final other = await DeviceKey.generate();
      final mesh = await MeshStaticKey.generate();
      final signer = CertSigner(signingKey: signing);
      final cert = await signer.sign(
        meshPublicKey: mesh.publicKey,
        userId: 'user-1',
        validUntilEpochMs: DateTime.now()
            .add(const Duration(days: 30))
            .millisecondsSinceEpoch,
      );

      final ok = await CertSigner.verify(
        cert: cert,
        signingPublicKey: other.publicKey,
      );
      expect(ok, isFalse);
    });
  });
}

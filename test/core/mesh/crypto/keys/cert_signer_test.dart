import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:taler_id_mobile/core/mesh/crypto/keys/cert_signer.dart';
import 'package:taler_id_mobile/core/mesh/crypto/keys/device_cert.dart';
import 'package:taler_id_mobile/core/mesh/crypto/keys/mesh_static_key.dart';
import 'package:taler_id_mobile/core/mesh/crypto/keys/user_identity_key.dart';

void main() {
  group('CertSigner Phase 1c', () {
    test('sign produces a cert with userPk and Ed25519 signature over userPk inclusive',
        () async {
      final identity = await UserIdentityKey.generate();
      final mesh = await MeshStaticKey.generate();
      final signer = CertSigner(userIdentityKey: identity);

      final cert = await signer.sign(
        meshPublicKey: mesh.publicKey,
        userId: 'user-1',
        validUntilEpochMs: DateTime.now()
            .add(const Duration(days: 30))
            .millisecondsSinceEpoch,
      );

      expect(cert.devicePk.length, 64);
      expect(cert.userPk, isNotNull);
      expect(cert.userPk!.length, 64);
      expect(cert.signature.length, 128);
    });

    test('verify round-trip succeeds using userPk from the cert itself',
        () async {
      final identity = await UserIdentityKey.generate();
      final mesh = await MeshStaticKey.generate();
      final signer = CertSigner(userIdentityKey: identity);
      final cert = await signer.sign(
        meshPublicKey: mesh.publicKey,
        userId: 'user-1',
        validUntilEpochMs: DateTime.now()
            .add(const Duration(days: 30))
            .millisecondsSinceEpoch,
      );

      final ok = await CertSigner.verifyWithEmbeddedUserPk(cert: cert);
      expect(ok, isTrue);
    });

    test('verify rejects tampered userId', () async {
      final identity = await UserIdentityKey.generate();
      final mesh = await MeshStaticKey.generate();
      final signer = CertSigner(userIdentityKey: identity);
      final cert = await signer.sign(
        meshPublicKey: mesh.publicKey,
        userId: 'user-1',
        validUntilEpochMs: DateTime.now()
            .add(const Duration(days: 30))
            .millisecondsSinceEpoch,
      );

      final tampered = DeviceCert(
        devicePk: cert.devicePk,
        userId: 'user-2', // changed
        userPk: cert.userPk,
        algorithm: cert.algorithm,
        validUntilEpochMs: cert.validUntilEpochMs,
        signature: cert.signature,
      );

      final ok = await CertSigner.verifyWithEmbeddedUserPk(cert: tampered);
      expect(ok, isFalse);
    });

    test('verify rejects tampered userPk (attacker swapping identities)',
        () async {
      final identity = await UserIdentityKey.generate();
      final mesh = await MeshStaticKey.generate();
      final signer = CertSigner(userIdentityKey: identity);
      final cert = await signer.sign(
        meshPublicKey: mesh.publicKey,
        userId: 'user-1',
        validUntilEpochMs: DateTime.now()
            .add(const Duration(days: 30))
            .millisecondsSinceEpoch,
      );

      final tampered = DeviceCert(
        devicePk: cert.devicePk,
        userId: cert.userId,
        userPk: 'ab' * 32, // attacker's pk — but signature was by real pk
        algorithm: cert.algorithm,
        validUntilEpochMs: cert.validUntilEpochMs,
        signature: cert.signature,
      );

      final ok = await CertSigner.verifyWithEmbeddedUserPk(cert: tampered);
      expect(ok, isFalse);
    });

    test('verifyWithEmbeddedUserPk returns false when cert.userPk is null',
        () async {
      final cert = DeviceCert(
        devicePk: 'ab' * 32,
        userId: 'user-1',
        userPk: null,
        algorithm: 'X25519',
        validUntilEpochMs: 1800000000000,
        signature: 'ff' * 64,
      );
      final ok = await CertSigner.verifyWithEmbeddedUserPk(cert: cert);
      expect(ok, isFalse);
    });
  });
}

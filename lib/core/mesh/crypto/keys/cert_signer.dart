import 'dart:convert';
import 'dart:typed_data';

import 'device_cert.dart';
import 'user_identity_key.dart';

/// Issues and verifies self-signed [DeviceCert]s.
///
/// Signing is performed by a permanent [UserIdentityKey] (Ed25519). The cert
/// binds an X25519 `devicePk` ([MeshStaticKey] public key) to a Taler ID user
/// and to the signing [UserIdentityKey]'s public key (`userPk`). Verifiers
/// read `userPk` out of the cert itself and use it to check the signature —
/// the cert is self-consistent.
class CertSigner {
  final UserIdentityKey userIdentityKey;

  CertSigner({required this.userIdentityKey});

  /// Produce a signed [DeviceCert] committing [meshPublicKey] as the device's
  /// X25519 static pk for [userId], valid until [validUntilEpochMs]. The
  /// returned cert's `userPk` is the hex of [userIdentityKey]'s public key.
  Future<DeviceCert> sign({
    required Uint8List meshPublicKey,
    required String userId,
    required int validUntilEpochMs,
  }) async {
    final devicePkHex = _hex(meshPublicKey);
    final userPkHex = _hex(userIdentityKey.publicKey);
    final draft = DeviceCert(
      devicePk: devicePkHex,
      userId: userId,
      userPk: userPkHex,
      algorithm: 'X25519',
      validUntilEpochMs: validUntilEpochMs,
      signature: '',
    );
    final canonical = draft.toCanonicalJsonWithoutSignature();
    final sigBytes =
        await userIdentityKey.sign(Uint8List.fromList(utf8.encode(canonical)));
    return DeviceCert(
      devicePk: devicePkHex,
      userId: userId,
      userPk: userPkHex,
      algorithm: 'X25519',
      validUntilEpochMs: validUntilEpochMs,
      signature: _hex(sigBytes),
    );
  }

  /// Verify [cert]'s signature using the `userPk` embedded inside the cert.
  ///
  /// Returns false when [cert]'s `userPk` is null (Phase 1b cert — caller
  /// must decide whether to trust it via out-of-band mechanism).
  static Future<bool> verifyWithEmbeddedUserPk({
    required DeviceCert cert,
  }) async {
    final userPkHex = cert.userPk;
    if (userPkHex == null) return false;
    return _verify(cert: cert, userIdentityPublicKey: _unhex(userPkHex));
  }

  /// Low-level verify against an externally-provided [userIdentityPublicKey].
  /// Exposed for testing and future PKI extensions.
  static Future<bool> verify({
    required DeviceCert cert,
    required Uint8List userIdentityPublicKey,
  }) =>
      _verify(cert: cert, userIdentityPublicKey: userIdentityPublicKey);

  static Future<bool> _verify({
    required DeviceCert cert,
    required Uint8List userIdentityPublicKey,
  }) async {
    final canonical = cert.toCanonicalJsonWithoutSignature();
    final msg = Uint8List.fromList(utf8.encode(canonical));
    final sig = _unhex(cert.signature);
    return UserIdentityKey.verify(
      publicKey: userIdentityPublicKey,
      message: msg,
      signature: sig,
    );
  }

  static String _hex(Uint8List bytes) {
    final buf = StringBuffer();
    for (final b in bytes) {
      buf.write(b.toRadixString(16).padLeft(2, '0'));
    }
    return buf.toString();
  }

  static Uint8List _unhex(String hex) {
    final n = hex.length ~/ 2;
    final out = Uint8List(n);
    for (var i = 0; i < n; i++) {
      out[i] = int.parse(hex.substring(i * 2, i * 2 + 2), radix: 16);
    }
    return out;
  }
}

import 'dart:convert';
import 'dart:typed_data';

import 'device_cert.dart';
import 'device_key.dart';

/// Signs and verifies self-signed device certificates.
///
/// The signing algorithm is Ed25519 (via [DeviceKey]). The cert binds an
/// X25519 static pk ([MeshStaticKey]) to a user id + validity window.
class CertSigner {
  final DeviceKey signingKey;

  CertSigner({required this.signingKey});

  /// Produce a signed [DeviceCert] that commits to [meshPublicKey] as this
  /// device's X25519 static pk for [userId] until [validUntilEpochMs].
  Future<DeviceCert> sign({
    required Uint8List meshPublicKey,
    required String userId,
    required int validUntilEpochMs,
  }) async {
    final devicePkHex = _hex(meshPublicKey);
    final draft = DeviceCert(
      devicePk: devicePkHex,
      userId: userId,
      algorithm: 'X25519',
      validUntilEpochMs: validUntilEpochMs,
      signature: '', // filled in after
    );
    final canonical = draft.toCanonicalJsonWithoutSignature();
    final sigBytes = await signingKey.sign(Uint8List.fromList(utf8.encode(canonical)));
    return DeviceCert(
      devicePk: devicePkHex,
      userId: userId,
      algorithm: 'X25519',
      validUntilEpochMs: validUntilEpochMs,
      signature: _hex(sigBytes),
    );
  }

  /// Verify [cert]'s signature using [signingPublicKey].
  static Future<bool> verify({
    required DeviceCert cert,
    required Uint8List signingPublicKey,
  }) async {
    final canonical = cert.toCanonicalJsonWithoutSignature();
    final msg = Uint8List.fromList(utf8.encode(canonical));
    final sig = _unhex(cert.signature);
    return await DeviceKey.verify(
      publicKey: signingPublicKey,
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

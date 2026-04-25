import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';

/// X25519 static keypair used as this device's long-term Noise IK identity.
///
/// Note: this is distinct from [DeviceKey] (Ed25519) which is used for
/// signing device certificates. The Noise IK handshake requires X25519
/// Diffie-Hellman, so a separate keypair is needed.
///
/// Phase 1a: generated ephemerally per test. Phase 1c: persisted via Hive
/// (see [MeshKeyPersistence]), rotated every 30 days per spec.
class MeshStaticKey {
  static final _x25519 = X25519();

  final Uint8List publicKey;
  final Uint8List privateKeyBytes;

  MeshStaticKey._({
    required this.publicKey,
    required this.privateKeyBytes,
  });

  static Future<MeshStaticKey> generate() async {
    final kp = await _x25519.newKeyPair();
    final priv = await kp.extractPrivateKeyBytes();
    final pub = await kp.extractPublicKey();
    return MeshStaticKey._(
      publicKey: Uint8List.fromList(pub.bytes),
      privateKeyBytes: Uint8List.fromList(priv),
    );
  }

  static Future<MeshStaticKey> fromPrivateKeyBytes(Uint8List privateKeyBytes) async {
    if (privateKeyBytes.length != 32) {
      throw ArgumentError('X25519 private key must be 32 bytes');
    }
    final kp = await _x25519.newKeyPairFromSeed(privateKeyBytes);
    final pub = await kp.extractPublicKey();
    return MeshStaticKey._(
      publicKey: Uint8List.fromList(pub.bytes),
      privateKeyBytes: Uint8List.fromList(privateKeyBytes),
    );
  }
}

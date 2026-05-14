import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

import '../../../../core/platform/secure_storage.dart';

/// Permanent per-device Ed25519 identity keypair for the mesh PKI.
///
/// Stored in [SecureStorage] under [storageKey] as base64-encoded
/// 32-byte private seed. Public key is derived on load. Generated once on
/// first app launch and never rotated — this is the stable `userPk` that
/// contacts use to verify this device's self-issued DeviceCerts.
class UserIdentityKey {
  /// Secure-storage key used by [loadOrCreate]. Exposed for debug/test.
  static const String storageKey = 'mesh_user_identity_priv';

  static final _ed25519 = Ed25519();

  final SimpleKeyPairData _keyPair;
  final Uint8List publicKey;
  final Uint8List privateKeyBytes;

  UserIdentityKey._({
    required SimpleKeyPairData keyPair,
    required this.publicKey,
    required this.privateKeyBytes,
  }) : _keyPair = keyPair;

  static Future<UserIdentityKey> generate() async {
    final kp = await _ed25519.newKeyPair();
    final kpData = await kp.extract();
    final pub = await kp.extractPublicKey();
    return UserIdentityKey._(
      keyPair: kpData,
      publicKey: Uint8List.fromList(pub.bytes),
      privateKeyBytes: Uint8List.fromList(kpData.bytes),
    );
  }

  static Future<UserIdentityKey> _fromPrivateKeyBytes(Uint8List privBytes) async {
    final kp = await _ed25519.newKeyPairFromSeed(privBytes);
    final kpData = await kp.extract();
    final pub = await kp.extractPublicKey();
    return UserIdentityKey._(
      keyPair: kpData,
      publicKey: Uint8List.fromList(pub.bytes),
      privateKeyBytes: Uint8List.fromList(kpData.bytes),
    );
  }

  /// Read the identity key from [storage] under [storageKey]. If absent,
  /// generate a new keypair, persist it, and return it. This call is
  /// idempotent across app launches.
  static Future<UserIdentityKey> loadOrCreate(
    SecureStorage storage,
  ) async {
    final encoded = await storage.read(storageKey);
    if (encoded != null && encoded.isNotEmpty) {
      final bytes = Uint8List.fromList(base64Decode(encoded));
      if (bytes.length == 32) {
        return _fromPrivateKeyBytes(bytes);
      }
      // Length mismatch — treat as corrupted, regenerate.
    }
    final fresh = await generate();
    await storage.write(storageKey, base64Encode(fresh.privateKeyBytes));
    return fresh;
  }

  Future<Uint8List> sign(Uint8List message) async {
    final sig = await _ed25519.sign(message, keyPair: _keyPair);
    return Uint8List.fromList(sig.bytes);
  }

  static Future<bool> verify({
    required Uint8List publicKey,
    required Uint8List message,
    required Uint8List signature,
  }) async {
    final pub = SimplePublicKey(publicKey, type: KeyPairType.ed25519);
    return _ed25519.verify(
      message,
      signature: Signature(signature, publicKey: pub),
    );
  }
}

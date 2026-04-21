import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';

class DeviceKey {
  static final _ed25519 = Ed25519();

  final SimpleKeyPairData _keyPair;
  final Uint8List publicKey;
  final Uint8List privateKeyBytes;

  DeviceKey._({
    required SimpleKeyPairData keyPair,
    required this.publicKey,
    required this.privateKeyBytes,
  }) : _keyPair = keyPair;

  static Future<DeviceKey> generate() async {
    final kp = await _ed25519.newKeyPair();
    final kpData = await kp.extract();
    final pub = await kp.extractPublicKey();
    return DeviceKey._(
      keyPair: kpData,
      publicKey: Uint8List.fromList(pub.bytes),
      privateKeyBytes: Uint8List.fromList(kpData.bytes),
    );
  }

  static Future<DeviceKey> fromPrivateKeyBytes(Uint8List privateKeyBytes) async {
    final kpData = await _ed25519.newKeyPairFromSeed(privateKeyBytes);
    final kpExtracted = await kpData.extract();
    final pub = await kpData.extractPublicKey();
    return DeviceKey._(
      keyPair: kpExtracted,
      publicKey: Uint8List.fromList(pub.bytes),
      privateKeyBytes: Uint8List.fromList(kpExtracted.bytes),
    );
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
    return await _ed25519.verify(
      message,
      signature: Signature(signature, publicKey: pub),
    );
  }
}

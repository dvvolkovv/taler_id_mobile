import 'dart:convert';

/// Self-signed device certificate for Phase 1b mesh identity.
///
/// A device owns an Ed25519 keypair (DeviceKey, signing) and an X25519 keypair
/// (MeshStaticKey, ECDH). The cert binds the X25519 public key to a Taler ID
/// user, signed by the device's Ed25519 private key.
///
/// Phase 1b simplification: self-signed (device signs its own cert).
/// Phase 1c promotes this to a user-identity-key-signed cert chain.
class DeviceCert {
  final String devicePk;             // hex 64 chars, X25519 static pk
  final String userId;               // Taler ID user UUID
  final String algorithm;            // "X25519"
  final int validUntilEpochMs;
  final String signature;            // hex 128 chars Ed25519 over canonical JSON

  const DeviceCert({
    required this.devicePk,
    required this.userId,
    required this.algorithm,
    required this.validUntilEpochMs,
    required this.signature,
  });

  /// Canonical JSON of the signed fields (excluding `signature`), alphabetical
  /// keys, no whitespace. This is what the Ed25519 signature covers.
  String toCanonicalJsonWithoutSignature() {
    // Keys alphabetically: algorithm, devicePk, userId, validUntilEpochMs.
    final map = <String, dynamic>{
      'algorithm': algorithm,
      'devicePk': devicePk,
      'userId': userId,
      'validUntilEpochMs': validUntilEpochMs,
    };
    return jsonEncode(map);
  }

  Map<String, dynamic> toJson() => {
        'devicePk': devicePk,
        'userId': userId,
        'algorithm': algorithm,
        'validUntilEpochMs': validUntilEpochMs,
        'signature': signature,
      };

  factory DeviceCert.fromJson(Map<String, dynamic> json) => DeviceCert(
        devicePk: json['devicePk'] as String,
        userId: json['userId'] as String,
        algorithm: json['algorithm'] as String,
        validUntilEpochMs: json['validUntilEpochMs'] as int,
        signature: json['signature'] as String,
      );

  bool isValid({DateTime? now}) {
    final t = now ?? DateTime.now();
    return t.millisecondsSinceEpoch < validUntilEpochMs;
  }
}

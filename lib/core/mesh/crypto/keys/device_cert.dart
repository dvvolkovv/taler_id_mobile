import 'dart:convert';

/// Self-signed device certificate for mesh identity.
///
/// A device owns:
/// - an Ed25519 keypair ([UserIdentityKey]) that is permanent per device and
///   signs this cert — its public key is the [userPk] field;
/// - an X25519 keypair ([MeshStaticKey]) whose public key is [devicePk], used
///   for Noise IK ECDH.
///
/// Phase 1b compat: certs issued under Phase 1b have no [userPk] (it is null
/// on the wire). When loading such certs, consumers that want to verify the
/// signature will skip verification and fall back to trusting the server that
/// served the cert.
class DeviceCert {
  /// X25519 static public key (hex, 64 chars).
  final String devicePk;

  /// Taler ID user UUID.
  final String userId;

  /// Ed25519 [UserIdentityKey] public key (hex, 64 chars).
  ///
  /// Null for Phase 1b certs that did not carry a user identity key.
  final String? userPk;

  /// Algorithm of [devicePk]; must be `"X25519"`.
  final String algorithm;

  final int validUntilEpochMs;

  /// Ed25519 signature over [toCanonicalJsonWithoutSignature] (hex, 128 chars).
  final String signature;

  const DeviceCert({
    required this.devicePk,
    required this.userId,
    required this.userPk,
    required this.algorithm,
    required this.validUntilEpochMs,
    required this.signature,
  });

  /// Canonical JSON of the signed fields (excluding `signature`), keys in
  /// alphabetical order, no whitespace. This is what the Ed25519 signature
  /// covers. When [userPk] is null, the field is **omitted** — required for
  /// Phase 1b backward compatibility where signatures were computed without
  /// the field.
  String toCanonicalJsonWithoutSignature() {
    // Alphabetical: algorithm, devicePk, userId, userPk, validUntilEpochMs.
    final map = <String, dynamic>{
      'algorithm': algorithm,
      'devicePk': devicePk,
      'userId': userId,
      if (userPk != null) 'userPk': userPk,
      'validUntilEpochMs': validUntilEpochMs,
    };
    return jsonEncode(map);
  }

  Map<String, dynamic> toJson() => {
        'devicePk': devicePk,
        'userId': userId,
        if (userPk != null) 'userPk': userPk,
        'algorithm': algorithm,
        'validUntilEpochMs': validUntilEpochMs,
        'signature': signature,
      };

  factory DeviceCert.fromJson(Map<String, dynamic> json) => DeviceCert(
        devicePk: json['devicePk'] as String,
        userId: json['userId'] as String,
        userPk: json['userPk'] as String?,
        algorithm: json['algorithm'] as String,
        validUntilEpochMs: json['validUntilEpochMs'] as int,
        signature: json['signature'] as String,
      );

  bool isValid({DateTime? now}) {
    final t = now ?? DateTime.now();
    return t.millisecondsSinceEpoch < validUntilEpochMs;
  }
}

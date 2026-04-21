import 'package:flutter_test/flutter_test.dart';
import 'package:taler_id_mobile/core/mesh/crypto/keys/device_cert.dart';

void main() {
  group('DeviceCert', () {
    test('canonical JSON has keys alphabetically ordered without whitespace', () {
      final cert = DeviceCert(
        devicePk: 'ab' * 32,
        userId: 'user-1',
        algorithm: 'X25519',
        validUntilEpochMs: 1800000000000,
        signature: 'ff' * 64,
      );
      final json = cert.toCanonicalJsonWithoutSignature();
      expect(json.contains('"algorithm":"X25519"'), isTrue);
      expect(json.contains('"devicePk":"${'ab' * 32}"'), isTrue);
      expect(json.contains('"userId":"user-1"'), isTrue);
      expect(json.contains('"validUntilEpochMs":1800000000000'), isTrue);
      expect(json.indexOf('"algorithm"'), lessThan(json.indexOf('"devicePk"')));
      expect(json.indexOf('"devicePk"'), lessThan(json.indexOf('"userId"')));
      expect(json.indexOf('"userId"'), lessThan(json.indexOf('"validUntilEpochMs"')));
      // No signature in canonical form
      expect(json.contains('signature'), isFalse);
      // No whitespace
      expect(json.contains(' '), isFalse);
    });

    test('toJson / fromJson round-trip preserves fields', () {
      final cert = DeviceCert(
        devicePk: 'ab' * 32,
        userId: 'user-1',
        algorithm: 'X25519',
        validUntilEpochMs: 1800000000000,
        signature: 'ff' * 64,
      );
      final map = cert.toJson();
      expect(map['devicePk'], 'ab' * 32);
      expect(map['signature'], 'ff' * 64);
      final revived = DeviceCert.fromJson(map);
      expect(revived.devicePk, cert.devicePk);
      expect(revived.userId, cert.userId);
      expect(revived.algorithm, cert.algorithm);
      expect(revived.validUntilEpochMs, cert.validUntilEpochMs);
      expect(revived.signature, cert.signature);
    });

    test('isValid returns false when expired', () {
      final past = DateTime.now().subtract(const Duration(days: 1)).millisecondsSinceEpoch;
      final cert = DeviceCert(
        devicePk: 'ab' * 32,
        userId: 'u',
        algorithm: 'X25519',
        validUntilEpochMs: past,
        signature: 'ff' * 64,
      );
      expect(cert.isValid(), isFalse);
    });

    test('isValid returns true when not expired', () {
      final future = DateTime.now().add(const Duration(days: 1)).millisecondsSinceEpoch;
      final cert = DeviceCert(
        devicePk: 'ab' * 32,
        userId: 'u',
        algorithm: 'X25519',
        validUntilEpochMs: future,
        signature: 'ff' * 64,
      );
      expect(cert.isValid(), isTrue);
    });
  });
}

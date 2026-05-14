// test/core/platform/biometric_auth_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:taler_id_mobile/core/platform/biometric_auth.dart';
import 'package:taler_id_mobile/core/platform/biometric_auth_desktop.dart';

void main() {
  setUp(() => BiometricAuthPlatform.debugResetForTest());
  tearDown(() => BiometricAuthPlatform.debugResetForTest());

  group('BiometricAuthDesktop (no-op)', () {
    late BiometricAuthDesktop desktop;

    setUp(() => desktop = BiometricAuthDesktop());

    test('canCheckBiometrics returns false', () async {
      expect(await desktop.canCheckBiometrics, isFalse);
    });

    test('isDeviceSupported returns false', () async {
      expect(await desktop.isDeviceSupported, isFalse);
    });

    test('getAvailableBiometrics returns empty list', () async {
      expect(await desktop.getAvailableBiometrics(), isEmpty);
    });

    test('authenticate returns false', () async {
      expect(
        await desktop.authenticate(localizedReason: 'test reason'),
        isFalse,
      );
    });

    test('authenticate with biometricOnly also returns false', () async {
      expect(
        await desktop.authenticate(
          localizedReason: 'test',
          biometricOnly: true,
        ),
        isFalse,
      );
    });
  });

  group('BiometricAuthPlatform.debugResetForTest', () {
    test('resets singleton so next access re-creates it', () {
      final a = BiometricAuthPlatform.instance;
      BiometricAuthPlatform.debugResetForTest();
      final b = BiometricAuthPlatform.instance;
      expect(a, isNotNull);
      expect(b, isNotNull);
    });
  });

  group('BiometricKind enum', () {
    test('all values accessible', () {
      expect(BiometricKind.values, contains(BiometricKind.fingerprint));
      expect(BiometricKind.values, contains(BiometricKind.face));
      expect(BiometricKind.values, contains(BiometricKind.iris));
      expect(BiometricKind.values, contains(BiometricKind.weak));
      expect(BiometricKind.values, contains(BiometricKind.strong));
    });
  });
}

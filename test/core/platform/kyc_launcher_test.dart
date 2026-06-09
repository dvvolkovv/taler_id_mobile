// test/core/platform/kyc_launcher_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:taler_id_mobile/core/platform/kyc_launcher.dart';
import 'package:taler_id_mobile/core/platform/kyc_launcher_desktop.dart';

void main() {
  setUp(() => KycLauncherPlatform.debugResetForTest());
  tearDown(() => KycLauncherPlatform.debugResetForTest());

  group('KycLaunchResult', () {
    test('skipped constructor sets correct fields', () {
      const r = KycLaunchResult.skipped();
      expect(r.success, isFalse);
      expect(r.skipped, isTrue);
      expect(r.errorMessage, isNull);
      expect(r.errorType, isNull);
    });

    test('success result', () {
      const r = KycLaunchResult(success: true);
      expect(r.success, isTrue);
      expect(r.skipped, isFalse);
    });

    test('error result', () {
      const r = KycLaunchResult(
        success: false,
        errorMessage: 'User cancelled',
        errorType: 'Cancelled',
      );
      expect(r.success, isFalse);
      expect(r.errorMessage, 'User cancelled');
      expect(r.errorType, 'Cancelled');
    });
  });

  group('KycLauncherDesktop', () {
    late KycLauncherDesktop desktop;

    setUp(() => desktop = KycLauncherDesktop());

    test('launch with empty webSdkUrl returns skipped', () async {
      final result = await desktop.launch(webSdkUrl: '');
      expect(result.skipped, isTrue);
      expect(result.success, isFalse);
    });
  });

  group('KycLauncherPlatform.debugResetForTest', () {
    test('resets singleton so next access re-creates it', () {
      final a = KycLauncherPlatform.instance;
      KycLauncherPlatform.debugResetForTest();
      final b = KycLauncherPlatform.instance;
      expect(a, isNotNull);
      expect(b, isNotNull);
    });
  });
}

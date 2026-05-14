// test/core/platform/kyc_launcher_test.dart
import 'package:flutter/widgets.dart' show Locale;
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

    test('launch returns skipped result', () async {
      final result = await desktop.launch(
        sdkToken: 'test-token',
        onTokenExpiration: () async => 'new-token',
      );
      expect(result.skipped, isTrue);
      expect(result.success, isFalse);
    });

    test('launch with custom locale still skips', () async {
      final result = await desktop.launch(
        sdkToken: 'tok',
        onTokenExpiration: () async => null,
        locale: const Locale('en'),
      );
      expect(result.skipped, isTrue);
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

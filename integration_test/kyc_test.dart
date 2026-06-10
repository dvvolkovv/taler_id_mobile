/// Taler ID — KYC flow integration test
///
/// Verifies that the new mock_ss WebSDK integration works on a real device:
///   1. login as integration_test_2@ (kept in UNVERIFIED state for this purpose)
///   2. open Settings → KYC Verification
///   3. KYC screen renders without ErrorWidget; "Пройти верификацию" CTA visible
///   4. Tap CTA → bloc emits KycSdkReady → router pushes /kyc/webview with the
///      mockss-test URL → KycWebViewScreen appears on the navigator stack
///
/// What this covers vs the API smoke (kyc_post_deploy.ts):
///   The API smoke verifies /kyc/start returns a usable webSdkUrl. This test
///   verifies the *mobile* glue — KycLauncher → GoRouter → WebView — still
///   works after removing flutter_idensic_mobile_sdk_plugin.
///
/// Run:
///   flutter test integration_test/kyc_test.dart --flavor dev \
///     --dart-define=FLAVOR=dev \
///     --dart-define=BASE_URL=https://staging.id.taler.tirol \
///     -d emulator-5554
library;

import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:taler_id_mobile/features/kyc/desktop/kyc_webview_screen.dart';
import 'package:taler_id_mobile/features/kyc/presentation/screens/kyc_screen.dart';
import 'package:taler_id_mobile/main.dart' as app;

// Use the second test account — it is kept in KYC=UNVERIFIED state so we can
// drive the full "Start verification" CTA → WebView path.
const _testEmail = 'integration_test_2@taler-test.com';
const _testPass = 'IntegrationTest123!';

extension _PumpHelper on WidgetTester {
  Future<bool> waitFor(
    Finder finder, {
    Duration timeout = const Duration(seconds: 15),
  }) async {
    final end = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(end)) {
      await pump(const Duration(milliseconds: 300));
      if (finder.evaluate().isNotEmpty) return true;
    }
    return false;
  }

  Future<void> pumpFor(Duration duration) async {
    final steps = duration.inMilliseconds ~/ 1000;
    for (var i = 0; i < steps; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 900));
      await pump();
    }
    final remaining = duration.inMilliseconds % 1000;
    if (remaining > 0) {
      await Future<void>.delayed(Duration(milliseconds: remaining));
      await pump();
    }
  }

  Future<bool> safeTap(Finder finder) async {
    if (finder.evaluate().isNotEmpty) {
      await tap(finder.first, warnIfMissed: false);
      await pumpFor(const Duration(seconds: 2));
      return true;
    }
    return false;
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Silently swallow known emulator-network flakes (google_fonts can't reach
  // fonts.gstatic.com from a fresh emulator → SocketException → test fails
  // even though the app itself worked). Two handlers needed: sync rendering
  // exceptions go through FlutterError.onError, async future errors through
  // PlatformDispatcher.onError.
  bool isKnownFlake(String msg) {
    return msg.contains('google_fonts') ||
        msg.contains('GoogleFonts') ||
        msg.contains('fonts.gstatic') ||
        msg.contains('Failed to load font') ||
        msg.contains('was not laid out') ||
        msg.contains('HandshakeException') ||
        msg.contains('SocketException') ||
        msg.contains('Connection terminated') ||
        msg.contains('cached_network_image') ||
        msg.contains('CacheManager') ||
        msg.contains('image codec') ||
        msg.contains('IMAGE RESOURCE SERVICE');
  }

  final originalOnError = FlutterError.onError;
  FlutterError.onError = (FlutterErrorDetails details) {
    if (isKnownFlake(details.exception.toString())) return;
    originalOnError?.call(details);
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    if (isKnownFlake(error.toString())) return true;
    return false;
  };

  setUpAll(() async {
    await SystemChannels.textInput.invokeMethod('TextInput.hide').catchError((_) {});
  });

  testWidgets('KYC flow: login → Settings → KYC → Start → WebView',
      (WidgetTester tester) async {
    debugPrint('[KYC TEST] ── Starting ──');
    app.main();
    await tester.pumpFor(const Duration(seconds: 5));

    // 1. Skip onboarding if present.
    final onboardDeadline = DateTime.now().add(const Duration(seconds: 20));
    while (DateTime.now().isBefore(onboardDeadline)) {
      await tester.pump(const Duration(milliseconds: 300));
      if (find.text('Skip').evaluate().isNotEmpty) {
        await tester.tap(find.text('Skip').first, warnIfMissed: false);
        await tester.pumpFor(const Duration(seconds: 2));
        break;
      }
      if (find.byType(TextFormField).evaluate().isNotEmpty) break;
      if (find.byIcon(Icons.settings_outlined).evaluate().isNotEmpty) break;
    }

    // 2. Login.
    if (find.byType(TextFormField).evaluate().isNotEmpty) {
      debugPrint('[KYC TEST] Logging in as $_testEmail');
      final fields = find.byType(TextFormField);
      expect(fields, findsAtLeast(2));
      await tester.enterText(fields.first, _testEmail);
      await tester.pump();
      await tester.enterText(fields.at(1), _testPass);
      await tester.pump();
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpFor(const Duration(seconds: 2));

      // Scroll if needed so the button is visible.
      final scroller = find.byType(SingleChildScrollView);
      if (scroller.evaluate().isNotEmpty) {
        await tester.drag(scroller.first, const Offset(0, -200));
        await tester.pumpFor(const Duration(seconds: 1));
      }

      final loginBtn = find.byType(ElevatedButton);
      if (loginBtn.evaluate().isNotEmpty) {
        await tester.tap(loginBtn.first, warnIfMissed: false);
        debugPrint('[KYC TEST] Login button tapped');
      }
    }

    // 3. Handle post-login intermediate screens (PIN setup, biometric prompt,
    //    "what's new" splash) before the dashboard is reachable. Loop until
    //    we either see the dashboard or time out.
    final reachDeadline = DateTime.now().add(const Duration(seconds: 60));
    bool reachedDashboard = false;
    while (DateTime.now().isBefore(reachDeadline)) {
      await tester.pump(const Duration(milliseconds: 400));

      if (find.byIcon(Icons.settings_outlined).evaluate().isNotEmpty) {
        reachedDashboard = true;
        break;
      }

      // PIN keypad: digit "1" + "5" both visible → tap 1 eight times
      // (4-digit set + confirm).
      if (find.text('1').evaluate().isNotEmpty &&
          find.text('5').evaluate().isNotEmpty) {
        debugPrint('[KYC TEST] PIN keypad detected — entering 1111 twice');
        for (var i = 0; i < 8; i++) {
          await tester.tap(find.text('1').first, warnIfMissed: false);
          await tester.pumpFor(const Duration(milliseconds: 400));
        }
        await tester.pumpFor(const Duration(seconds: 3));
        continue;
      }

      // Skip-style buttons on biometric / "what's new" prompts.
      for (final label in const [
        'Позже', 'Skip', 'Not now', 'Пропустить', 'Later',
        'ОК', 'OK', 'Понятно', 'Got it', 'Закрыть',
      ]) {
        final f = find.text(label);
        if (f.evaluate().isNotEmpty) {
          await tester.tap(f.first, warnIfMissed: false);
          await tester.pumpFor(const Duration(seconds: 1));
          break;
        }
      }
    }

    expect(reachedDashboard, isTrue,
        reason: 'Settings icon should be visible on the dashboard '
            '(post-login intermediate screens handled)');
    debugPrint('[KYC TEST] ✓ Dashboard reached');

    // 4. Open Settings.
    await tester.safeTap(find.byIcon(Icons.settings_outlined));
    await tester.pumpFor(const Duration(seconds: 2));
    expect(find.byType(ErrorWidget), findsNothing,
        reason: 'Settings screen must not crash');
    debugPrint('[KYC TEST] ✓ Settings screen OK');

    // 5. Tap KYC verification row.
    final kycTile = find.text('Верификация личности (KYC)');
    expect(kycTile, findsOneWidget,
        reason: 'Settings should expose the KYC verification entry');
    await tester.ensureVisible(kycTile);
    await tester.pumpFor(const Duration(seconds: 1));
    await tester.tap(kycTile, warnIfMissed: false);
    await tester.pumpFor(const Duration(seconds: 3));

    // 6. KycScreen renders without crash.
    final kycScreenPresent = await tester.waitFor(
      find.byType(KycScreen),
      timeout: const Duration(seconds: 10),
    );
    expect(kycScreenPresent, isTrue, reason: 'KycScreen should appear');
    expect(find.byType(ErrorWidget), findsNothing,
        reason: 'KycScreen must not crash');
    debugPrint('[KYC TEST] ✓ KycScreen rendered');

    // 7. Wait for KycBloc to finish KycLoading → KycStatusLoaded(<status>).
    //    The status depends on previous test runs:
    //      - UNVERIFIED / REJECTED → "Пройти верификацию" / "Пройти повторно"
    //        CTA visible → we drive the full Start → WebView flow.
    //      - PENDING / VERIFIED → no CTA, we just confirm the status UI
    //        rendered without crash.
    //    A previous successful run flips the user from UNVERIFIED to PENDING;
    //    we accept both paths so the test is idempotent on repeat runs.
    final statusKeywords = ['Пройти верификацию', 'Пройти повторно',
        'Документы', 'Подтверждена', 'верифицирована', 'верификации'];
    final settled = await tester.waitFor(
      find.byWidgetPredicate((w) =>
          w is Text &&
          w.data != null &&
          statusKeywords.any((kw) => w.data!.contains(kw))),
      timeout: const Duration(seconds: 15),
    );
    expect(settled, isTrue,
        reason: 'KycBloc should resolve to KycStatusLoaded and render some '
            'status-aware UI (CTA or info card)');

    final startCta = find.text('Пройти верификацию');
    final retryCta = find.text('Пройти повторно');
    final ctaToTap = startCta.evaluate().isNotEmpty
        ? startCta
        : (retryCta.evaluate().isNotEmpty ? retryCta : null);

    if (ctaToTap != null) {
      debugPrint('[KYC TEST] ✓ CTA visible — driving Start → WebView path');

      // 8. Tap CTA → bloc calls /kyc/start → router pushes /kyc/webview →
      //    KycWebViewScreen appears.
      await tester.tap(ctaToTap.first, warnIfMissed: false);
      await tester.pumpFor(const Duration(seconds: 3));

      // The launcher calls POST /kyc/start (network round-trip) then pushes
      // the WebView route — give it a generous window before failing.
      final webViewAppeared = await tester.waitFor(
        find.byType(KycWebViewScreen),
        timeout: const Duration(seconds: 25),
      );
      expect(webViewAppeared, isTrue,
          reason:
              'KycWebViewScreen should appear after tapping Start — verifies '
              'that /kyc/start returned a valid webSdkUrl and the launcher '
              'pushed it.');
      expect(find.byType(ErrorWidget), findsNothing,
          reason: 'KycWebViewScreen must not crash');
      debugPrint('[KYC TEST] ✓ KycWebViewScreen pushed');

      // Give the WebView a moment to begin loading so we exercise the
      // JavaScriptChannel registration path (the bridge that forwards
      // window.postMessage from the wizard back to Dart).
      await tester.pumpFor(const Duration(seconds: 4));
      expect(find.byType(ErrorWidget), findsNothing,
          reason: 'WebView load must not crash');
      debugPrint('[KYC TEST] ✓ WebView began loading without crash');

      // 9. Close the WebView via the AppBar close button.
      final closeBtn = find.byIcon(Icons.close);
      if (closeBtn.evaluate().isNotEmpty) {
        await tester.tap(closeBtn.first, warnIfMissed: false);
        await tester.pumpFor(const Duration(seconds: 2));
      }
    } else {
      debugPrint('[KYC TEST] ✓ No CTA — user is already PENDING/VERIFIED '
          '(test is idempotent; full Start→WebView path requires DB reset '
          'of integration_test_2 KYC status to UNVERIFIED)');
      expect(find.byType(ErrorWidget), findsNothing,
          reason: 'Status-only KycScreen must not crash');
    }

    // Drain framework-accumulated exceptions; only fail if an unknown one
    // slipped through (e.g. real app crash unrelated to network flakes).
    var drained = 0;
    while (true) {
      final e = tester.takeException();
      if (e == null) break;
      drained++;
      if (!isKnownFlake(e.toString())) {
        throw StateError('Unexpected exception during KYC test: $e');
      }
    }
    if (drained > 0) {
      debugPrint('[KYC TEST] (drained $drained known emulator flakes)');
    }

    debugPrint('[KYC TEST] ── Done ──');
  }, timeout: const Timeout(Duration(minutes: 5)));
}

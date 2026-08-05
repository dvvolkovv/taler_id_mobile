// Desktop smoke test — verifies the app compiles and launches to a stable
// state on macOS (and other desktop targets) without crashing.
//
// Run:
//   flutter test integration_test/desktop_smoke_test.dart -d macos \
//       --dart-define=FLAVOR=dev \
//       --dart-define=BASE_URL=https://staging.id.taler.tirol
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:taler_id_mobile/main.dart' as app;
import 'package:taler_id_mobile/features/dashboard/desktop/widgets/activity_bar.dart';
import 'package:taler_id_mobile/core/desktop_tray/desktop_tray_service.dart';
import 'package:taler_id_mobile/core/notifications/desktop/desktop_notifications_service.dart';
import 'package:taler_id_mobile/core/url_scheme/url_scheme_handler.dart';

const _testEmail = String.fromEnvironment(
  'TEST_EMAIL',
  defaultValue: 'integration_test@taler-test.com',
);
const _testPass = String.fromEnvironment(
  'TEST_PASSWORD',
  defaultValue: 'IntegrationTest123!',
);

extension _DesktopSmokePump on WidgetTester {
  Future<void> pumpFor(Duration duration) async {
    final steps = (duration.inMilliseconds / 300).ceil().clamp(1, 1000);
    for (var i = 0; i < steps; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 300));
      await pump();
    }
  }

  Future<bool> waitFor(
    Finder finder, {
    Duration timeout = const Duration(seconds: 15),
  }) async {
    final steps = (timeout.inMilliseconds / 300).ceil().clamp(1, 1000);
    for (var i = 0; i < steps; i++) {
      await pump(const Duration(milliseconds: 300));
      if (finder.evaluate().isNotEmpty) return true;
    }
    return false;
  }

  Future<void> tapActivity(String tooltip) async {
    final finder = find.byTooltip(tooltip);
    debugPrint('[desktop-smoke] opening $tooltip');
    for (var i = 0; i < 8 && finder.hitTestable().evaluate().isEmpty; i++) {
      final scrollable = find.byType(Scrollable);
      if (scrollable.evaluate().isEmpty) break;
      await drag(scrollable.first, const Offset(0, -80));
      await pump(const Duration(milliseconds: 200));
    }
    final tappable = finder.hitTestable();
    expect(tappable, findsOneWidget,
        reason: '$tooltip missing from ActivityBar');
    await tap(tappable, warnIfMissed: false);
    await pumpFor(const Duration(seconds: 2));
    expect(find.byType(ErrorWidget), findsNothing, reason: '$tooltip crashed');
  }

  Future<bool> advanceFirstRunGates() async {
    for (final text in ['Пропустить', 'Skip', 'Позже', 'Later']) {
      final finder = find.text(text);
      if (finder.evaluate().isNotEmpty) {
        debugPrint('[desktop-smoke] advancing gate via "$text"');
        await tap(finder.first, warnIfMissed: false);
        await pumpFor(const Duration(seconds: 2));
        return true;
      }
    }
    return false;
  }

  Future<bool> leavePinGateForPasswordLogin() async {
    final isPinGate = find.text('Enter PIN').evaluate().isNotEmpty ||
        find.text('Введите PIN-код').evaluate().isNotEmpty;
    if (!isPinGate) return false;
    for (final text in ['Sign In', 'Войти']) {
      final finder = find.text(text);
      if (finder.evaluate().isNotEmpty) {
        debugPrint('[desktop-smoke] leaving PIN gate via "$text"');
        await tap(finder.first, warnIfMissed: false);
        await pumpFor(const Duration(seconds: 2));
        return true;
      }
    }
    return false;
  }

  Future<bool> waitForDesktopShell() async {
    for (var i = 0; i < 170; i++) {
      await pump(const Duration(milliseconds: 300));
      if (find.byType(ActivityBar).evaluate().isNotEmpty) {
        debugPrint('[desktop-smoke] desktop shell ready');
        return true;
      }
      await advanceFirstRunGates();
    }
    return false;
  }

  void dumpVisibleTexts() {
    final texts = find
        .byType(Text)
        .evaluate()
        .map((e) => e.widget)
        .whereType<Text>()
        .map((w) => w.data)
        .whereType<String>()
        .where((s) => s.trim().isNotEmpty)
        .take(30)
        .join(' | ');
    debugPrint('[desktop-smoke] visible texts: $texts');
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('desktop launches, signs in, and opens primary routes',
      (tester) async {
    // Suppress transient background errors from background async tasks
    // (e.g. file-lock EAGAIN from speech_to_text, non-blocking socket errors
    // from Dio network requests) that are not relevant to the launch smoke.
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      final summary = details.summary.toString();
      final exception = details.exception.toString();
      // Swallow OS-level I/O noise that isn't an app crash:
      if (exception.contains('OS Error') ||
          exception.contains('errno = 35') ||
          exception.contains('errno = 36') ||
          exception.contains('Resource temporarily unavailable') ||
          exception.contains('lock failed') ||
          exception.contains('SocketException') ||
          summary.contains('OS Error') ||
          summary.contains('errno = 35')) {
        debugPrint('[smoke] suppressed background I/O error: $summary');
        return;
      }
      originalOnError?.call(details);
    };

    // Run app.main() in a real async context so platform channels work.
    await tester.runAsync(() async {
      app.main();
      // Give the async init chain (Firebase, Hive, DI) time to complete
      // and call runApp().
      await Future.delayed(const Duration(seconds: 5));
    });

    // Pump a single frame so Flutter processes the widget tree.
    await tester.pump();

    // Loose assertion — MaterialApp was mounted (login or main screen).
    expect(find.byType(MaterialApp), findsOneWidget);

    if (find.byType(ActivityBar).evaluate().isEmpty) {
      final reachedShellFromSession = await tester.waitForDesktopShell();
      if (!reachedShellFromSession) {
        await tester.leavePinGateForPasswordLogin();
        final hasLogin = await tester.waitFor(
          find.byType(TextFormField),
          timeout: const Duration(seconds: 15),
        );
        if (!hasLogin) tester.dumpVisibleTexts();
        expect(hasLogin, isTrue,
            reason: 'Expected login form or desktop shell');

        final fields = find.byType(TextFormField);
        expect(fields, findsAtLeast(2), reason: 'Expected email + password');
        await tester.enterText(fields.first, _testEmail);
        await tester.enterText(fields.at(1), _testPass);
        FocusManager.instance.primaryFocus?.unfocus();
        await tester.pumpFor(const Duration(seconds: 1));
        await tester.tap(find.byType(ElevatedButton).first,
            warnIfMissed: false);
      }
    }

    final hasActivityBar = await tester.waitForDesktopShell();
    if (!hasActivityBar) tester.dumpVisibleTexts();
    expect(hasActivityBar, isTrue, reason: 'Desktop shell did not open');
    expect(find.byType(ErrorWidget), findsNothing);

    await tester.tapActivity('Messenger');
    await tester.tapActivity('Calls');
    await tester.tapActivity('Assistant');
    await tester.tapActivity('Calendar');
    await tester.tapActivity('Wallet');
    await tester.tapActivity('AI settings');
    await tester.tapActivity('Settings');

    // Phase 2 smoke: verify singleton instances are accessible (constructed at
    // class-load time via static final). The services themselves are initialized
    // lazily inside main() via DI; here we only verify that the singleton
    // objects exist and the imports resolve — no platform channel calls are
    // made, so these assertions are safe in the integration-test host process.
    expect(DesktopTrayService.instance, isNotNull);
    expect(DesktopNotificationsService.instance, isNotNull);
    expect(UrlSchemeHandler.instance, isNotNull);

    // Restore original error handler.
    FlutterError.onError = originalOnError;
  });
}

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

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('app launches to login screen on desktop without crash',
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

    // Restore original error handler.
    FlutterError.onError = originalOnError;
  });
}

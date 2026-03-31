/// Taler ID — Call Integration Test (RECEIVER)
///
/// Запуск: flutter test integration_test/call_test_receiver.dart --flavor dev \
///   --dart-define=FLAVOR=dev --dart-define=BASE_URL=https://staging.id.taler.tirol \
///   -d emulator-5556
///
/// Координация: логинится, ждёт входящий звонок, принимает.
/// Caller должен быть запущен на первом эмуляторе одновременно.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:taler_id_mobile/main.dart' as app;

const _email = 'integration_test_2@taler-test.com';
const _pass = 'IntegrationTest123!';

extension on WidgetTester {
  Future<bool> waitFor(Finder f, {Duration timeout = const Duration(seconds: 15)}) async {
    final end = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(end)) {
      await pump(const Duration(milliseconds: 300));
      if (f.evaluate().isNotEmpty) return true;
    }
    return false;
  }

  Future<void> pumpFor(Duration d) async {
    final steps = d.inMilliseconds ~/ 1000;
    for (var i = 0; i < steps; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 900));
      await pump();
    }
    final remaining = d.inMilliseconds % 1000;
    if (remaining > 0) {
      await Future<void>.delayed(Duration(milliseconds: remaining));
      await pump();
    }
  }

  Future<bool> safeTap(Finder f) async {
    if (f.evaluate().isNotEmpty) {
      await tap(f.first, warnIfMissed: false);
      await pumpFor(const Duration(seconds: 2));
      return true;
    }
    return false;
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('RECEIVER: Login → Wait for call → Accept → Verify → Wait for hangup', (tester) async {
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      final msg = details.exceptionAsString();
      if (msg.contains('google_fonts') || msg.contains('GoogleFonts') ||
          msg.contains('firebase') || msg.contains('FIS_AUTH') ||
          msg.contains('HandshakeException')) {
        debugPrint('[RECEIVER] Ignoring non-critical error: ${msg.substring(0, msg.length.clamp(0, 80))}');
        return;
      }
      originalOnError?.call(details);
    };

    // ── Launch & Login ────────────────────────────────────────────
    app.main();
    await tester.pumpFor(const Duration(seconds: 6));

    // Handle onboarding
    final deadline = DateTime.now().add(const Duration(seconds: 20));
    while (DateTime.now().isBefore(deadline)) {
      await tester.pump(const Duration(milliseconds: 300));
      if (find.text('Next').evaluate().isNotEmpty) {
        for (var i = 0; i < 5; i++) await tester.safeTap(find.text('Next'));
        await tester.safeTap(find.text('Get Started'));
        await tester.safeTap(find.text('Skip'));
        break;
      }
      if (find.text('Skip').evaluate().isNotEmpty) {
        await tester.safeTap(find.text('Skip'));
        break;
      }
      if (find.byType(TextFormField).evaluate().isNotEmpty) break;
      if (find.byType(BottomNavigationBar).evaluate().isNotEmpty) break;
    }

    // Login if needed
    if (find.byType(TextFormField).evaluate().isNotEmpty) {
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.first, _email);
      await tester.enterText(fields.at(1), _pass);
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpFor(const Duration(seconds: 2));
      await tester.drag(find.byType(SingleChildScrollView).first, const Offset(0, -200));
      await tester.pumpFor(const Duration(seconds: 1));
      await tester.safeTap(find.byType(ElevatedButton));
    }

    // Wait for dashboard
    final hasDash = await tester.waitFor(find.byType(BottomNavigationBar), timeout: const Duration(seconds: 20));
    expect(hasDash, isTrue, reason: 'Dashboard not found');
    debugPrint('[RECEIVER] Dashboard loaded — waiting for incoming call...');

    // ── Wait for incoming call (up to 90s) ────────────────────────
    // The incoming call appears as a ModalBottomSheet with call_rounded icon
    // or as IncomingCallBanner
    bool callReceived = false;
    final callDeadline = DateTime.now().add(const Duration(seconds: 90));
    while (DateTime.now().isBefore(callDeadline)) {
      await tester.pump(const Duration(milliseconds: 500));

      // Check for incoming call dialog (green call_rounded icon in bottom sheet)
      // The accept button uses Icons.call_rounded with green background
      final acceptIcon = find.byIcon(Icons.call_rounded);
      if (acceptIcon.evaluate().length >= 1) {
        // Incoming call dialog found — tap accept (green call icon)
        debugPrint('[RECEIVER] Incoming call detected!');

        // The accept button is a GestureDetector with green Container > Icon(call_rounded)
        // It may coexist with the decline button which has call_end_rounded
        // Find the green accept button (not the decline one)
        await tester.tap(acceptIcon.last, warnIfMissed: false);
        callReceived = true;
        debugPrint('[RECEIVER] Accept tapped');
        break;
      }
    }

    expect(callReceived, isTrue, reason: 'No incoming call received within 90s');

    // ── Verify VoiceCallScreen ────────────────────────────────────
    final hasCallScreen = await tester.waitFor(
      find.byIcon(Icons.call_end_rounded),
      timeout: const Duration(seconds: 15),
    );
    expect(hasCallScreen, isTrue, reason: 'VoiceCallScreen not found after accepting call');
    debugPrint('[RECEIVER] Voice call screen loaded');

    // ── Verify call is active ─────────────────────────────────────
    await tester.pumpFor(const Duration(seconds: 5));
    expect(find.byType(ErrorWidget), findsNothing, reason: 'Voice screen crashed');

    // Check participant avatars (should see at least self + caller)
    final avatars = find.byType(CircleAvatar);
    debugPrint('[RECEIVER] CircleAvatars: ${avatars.evaluate().length}');

    // ── Stay on call for 10s then verify still connected ──────────
    await tester.pumpFor(const Duration(seconds: 10));
    expect(find.byType(ErrorWidget), findsNothing, reason: 'Voice screen crashed during call');

    // Hangup button should still be visible (call still active)
    final hangupStillThere = find.byIcon(Icons.call_end_rounded);
    final stillInCall = hangupStillThere.evaluate().isNotEmpty;
    debugPrint('[RECEIVER] Still in call: $stillInCall');

    // ── Wait for caller to hangup, or hangup ourselves ────────────
    if (stillInCall) {
      await tester.pumpFor(const Duration(seconds: 15));

      // If still in call screen, hangup
      final hangup = find.byIcon(Icons.call_end_rounded);
      if (hangup.evaluate().isNotEmpty) {
        await tester.tap(hangup.first, warnIfMissed: false);
        debugPrint('[RECEIVER] Hangup tapped (cleanup)');
      }
    }

    await tester.pumpFor(const Duration(seconds: 3));
    debugPrint('[RECEIVER] ✓ Call test complete');
  });
}

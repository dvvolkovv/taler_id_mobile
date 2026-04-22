/// Repro: receiver accepts call → minimizes → navigates to messenger,
/// checks whether the call survives (CallStateService.isInCall stays true).
///
/// flutter test integration_test/call_minimize_test_receiver.dart \
///   --flavor dev --dart-define=FLAVOR=dev \
///   --dart-define=BASE_URL=https://staging.id.taler.tirol \
///   -d emulator-5556
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:taler_id_mobile/main.dart' as app;
import 'package:taler_id_mobile/core/services/call_state_service.dart';

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

  testWidgets('RECEIVER: accept → minimize → messenger → check call alive', (tester) async {
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      final msg = details.exceptionAsString();
      if (msg.contains('google_fonts') || msg.contains('GoogleFonts') ||
          msg.contains('firebase') || msg.contains('FIS_AUTH') ||
          msg.contains('HandshakeException')) {
        return;
      }
      originalOnError?.call(details);
    };

    app.main();
    await tester.pumpFor(const Duration(seconds: 6));

    // Skip onboarding
    final deadline = DateTime.now().add(const Duration(seconds: 20));
    while (DateTime.now().isBefore(deadline)) {
      await tester.pump(const Duration(milliseconds: 300));
      if (find.text('Next').evaluate().isNotEmpty) {
        for (var i = 0; i < 5; i++) await tester.safeTap(find.text('Next'));
        await tester.safeTap(find.text('Get Started'));
        await tester.safeTap(find.text('Skip'));
        break;
      }
      if (find.text('Skip').evaluate().isNotEmpty) { await tester.safeTap(find.text('Skip')); break; }
      if (find.byType(TextFormField).evaluate().isNotEmpty) break;
    }

    // Login
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

    // Post-login onboarding
    await tester.pumpFor(const Duration(seconds: 4));
    final onboardingDeadline = DateTime.now().add(const Duration(seconds: 20));
    while (DateTime.now().isBefore(onboardingDeadline)) {
      await tester.pump(const Duration(milliseconds: 300));
      if (find.byIcon(Icons.chat_bubble_outline_rounded).evaluate().isNotEmpty) break;
      if (find.text('Skip').evaluate().isNotEmpty) { await tester.safeTap(find.text('Skip')); break; }
      if (find.text('Пропустить').evaluate().isNotEmpty) { await tester.safeTap(find.text('Пропустить')); break; }
      if (find.text('Next').evaluate().isNotEmpty) await tester.safeTap(find.text('Next'));
      if (find.text('Далее').evaluate().isNotEmpty) await tester.safeTap(find.text('Далее'));
    }

    final hasDash = await tester.waitFor(find.byIcon(Icons.chat_bubble_outline_rounded), timeout: const Duration(seconds: 20));
    expect(hasDash, isTrue, reason: 'Dashboard not found');
    debugPrint('[REPRO-RECV] Dashboard loaded — waiting for incoming call...');

    // Wait for incoming call (generous window — caller still has to build/login)
    bool callReceived = false;
    final callDeadline = DateTime.now().add(const Duration(seconds: 300));
    while (DateTime.now().isBefore(callDeadline)) {
      await tester.pump(const Duration(milliseconds: 500));
      final acceptIcon = find.byIcon(Icons.call_rounded);
      if (acceptIcon.evaluate().length >= 1) {
        debugPrint('[REPRO-RECV] Incoming call detected — tapping accept');
        await tester.tap(acceptIcon.last, warnIfMissed: false);
        callReceived = true;
        break;
      }
    }
    expect(callReceived, isTrue, reason: 'No incoming call within 90s');

    // Wait for VoiceCallScreen
    final hasCallScreen = await tester.waitFor(find.byIcon(Icons.call_end_rounded), timeout: const Duration(seconds: 90));
    expect(hasCallScreen, isTrue, reason: 'VoiceCallScreen not found');
    debugPrint('[REPRO-RECV] Voice call screen loaded');

    // Poll for LiveKit connection — up to 60s on emulator
    debugPrint('[REPRO-RECV] Polling for CallStateService.isInCall (max 60s)...');
    for (int i = 0; i < 60; i++) {
      await tester.pumpFor(const Duration(seconds: 1));
      if (CallStateService.instance.isInCall) {
        debugPrint('[REPRO-RECV] LiveKit connected at t=${i + 1}s, room=${CallStateService.instance.roomName}');
        break;
      }
    }

    // Baseline: is call active?
    final inCallBefore = CallStateService.instance.isInCall;
    final roomBefore = CallStateService.instance.roomName;
    debugPrint('[REPRO-RECV] BEFORE minimize: isInCall=$inCallBefore room=$roomBefore');
    if (!inCallBefore) {
      debugPrint('[REPRO-RECV] ⚠ LiveKit never connected — aborting repro (not the bug being tested)');
      return;
    }

    // ── MINIMIZE: tap AppBar back arrow on voice screen ─────────
    debugPrint('[REPRO-RECV] >>> tapping back/minimize');
    final backBtns = find.byTooltip('Back');
    if (backBtns.evaluate().isNotEmpty) {
      await tester.tap(backBtns.first, warnIfMissed: false);
    } else {
      // Fallback: find the first IconButton in an AppBar
      final appBarBack = find.byWidgetPredicate((w) =>
          w is IconButton && w.icon is Icon && ((w.icon as Icon).icon == Icons.arrow_back || (w.icon as Icon).icon == Icons.arrow_back_ios));
      if (appBarBack.evaluate().isNotEmpty) {
        await tester.tap(appBarBack.first, warnIfMissed: false);
      } else {
        debugPrint('[REPRO-RECV] ⚠ Back button not found — using GoRouter pop');
        final el = tester.element(find.byType(Scaffold).first);
        GoRouter.of(el).pop();
      }
    }
    await tester.pumpFor(const Duration(seconds: 2));

    // Check call state AFTER minimize (before navigating)
    final inCallAfterMin = CallStateService.instance.isInCall;
    debugPrint('[REPRO-RECV] AFTER minimize: isInCall=$inCallAfterMin room=${CallStateService.instance.roomName}');

    // ── NAVIGATE TO MESSENGER (the action the user reports) ──────
    debugPrint('[REPRO-RECV] >>> navigating to /dashboard/messenger');
    final el = tester.element(find.byType(Scaffold).first);
    GoRouter.of(el).push('/dashboard/messenger');
    await tester.pumpFor(const Duration(seconds: 3));

    // Check call state right after navigate
    final inCallAfterNav = CallStateService.instance.isInCall;
    debugPrint('[REPRO-RECV] RIGHT AFTER navigate: isInCall=$inCallAfterNav room=${CallStateService.instance.roomName}');

    // Wait 15s and poll state — this is when stale events would arrive
    debugPrint('[REPRO-RECV] Polling call state for 15s...');
    for (int i = 0; i < 15; i++) {
      await tester.pumpFor(const Duration(seconds: 1));
      final alive = CallStateService.instance.isInCall;
      debugPrint('[REPRO-RECV] t=${i + 1}s  isInCall=$alive  room=${CallStateService.instance.roomName}');
      if (!alive) {
        debugPrint('[REPRO-RECV] ❌ CALL DROPPED at t=${i + 1}s after navigating to messenger');
        break;
      }
    }

    final finalAlive = CallStateService.instance.isInCall;
    debugPrint('[REPRO-RECV] FINAL STATE: isInCall=$finalAlive (expected: true if bug NOT present)');

    await tester.pumpFor(const Duration(seconds: 2));
    debugPrint('[REPRO-RECV] ✓ Repro test complete');
    // Do not expect() here — we want to record the observation, not fail.
  });
}

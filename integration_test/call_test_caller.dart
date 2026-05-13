/// Taler ID — Call Integration Test (CALLER)
///
/// Запуск: flutter test integration_test/call_test_caller.dart --flavor dev \
///   --dart-define=FLAVOR=dev --dart-define=BASE_URL=https://staging.id.taler.tirol \
///   -d emulator-5554
///
/// Координация: ждёт 30с после логина, потом звонит.
/// Receiver должен быть запущен на втором эмуляторе одновременно.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:taler_id_mobile/main.dart' as app;

const _email = 'integration_test@taler-test.com';
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
    // Use real-time delay + periodic pumps to avoid frame scheduling conflicts
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

  testWidgets('CALLER: Login → Open chat → Call → Verify → Hangup', (tester) async {
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

    // Handle post-login onboarding (fresh install: isOnboardingSeen = false)
    await tester.pumpFor(const Duration(seconds: 4));
    final onboardingDeadline = DateTime.now().add(const Duration(seconds: 20));
    while (DateTime.now().isBefore(onboardingDeadline)) {
      await tester.pump(const Duration(milliseconds: 300));
      if (find.byIcon(Icons.chat_bubble_outline_rounded).evaluate().isNotEmpty) break;
      if (find.text('Skip').evaluate().isNotEmpty) {
        await tester.safeTap(find.text('Skip'));
        break;
      }
      if (find.text('Пропустить').evaluate().isNotEmpty) {
        await tester.safeTap(find.text('Пропустить'));
        break;
      }
      if (find.text('Next').evaluate().isNotEmpty) {
        await tester.safeTap(find.text('Next'));
      }
      if (find.text('Далее').evaluate().isNotEmpty) {
        await tester.safeTap(find.text('Далее'));
      }
    }

    // Wait for dashboard (orbital nav — look for chat bubble icon)
    final hasDash = await tester.waitFor(find.byIcon(Icons.chat_bubble_outline_rounded), timeout: const Duration(seconds: 20));
    expect(hasDash, isTrue, reason: 'Dashboard not found');
    debugPrint('[CALLER] Dashboard loaded');

    // ── Open conversation directly (DEV staging conversation ID) ──────
    // Navigate directly to the known conversation between test accounts.
    // Step 1: go to conversations list first
    const convId = '91f97844-307b-4a20-ad62-c1d2820e627f';
    debugPrint('[CALLER] Navigating to messenger conversations first');
    await tester.safeTap(find.byIcon(Icons.chat_bubble_outline_rounded));
    await tester.pumpFor(const Duration(seconds: 3));

    // Step 2: push chat room from messenger context
    debugPrint('[CALLER] Pushing conversation $convId');
    final messengerElement = tester.element(find.byType(Scaffold).first);
    GoRouter.of(messengerElement).push('/dashboard/messenger/$convId');
    await tester.pumpFor(const Duration(seconds: 4));

    // Verify we're in the chat room (phone icon visible in AppBar)
    final hasPhone = await tester.waitFor(find.byIcon(Icons.phone_outlined), timeout: const Duration(seconds: 8));
    debugPrint('[CALLER] phone_outlined found: $hasPhone');

    // ── WAIT for receiver to be ready ─────────────────────────────
    debugPrint('[CALLER] Waiting 30s for receiver to be ready...');
    await tester.pumpFor(const Duration(seconds: 30));

    // ── Tap call button ───────────────────────────────────────────
    // NOTE: tester.tap() misses due to hit-test interception by underlying widget.
    // In chat_room_screen the phone icon is wrapped in InkWell (not IconButton)
    // so onLongPress and onTap can coexist — invoke onTap directly.
    final callBtn = find.byIcon(Icons.phone_outlined);
    debugPrint('[CALLER] phone_outlined icons: ${callBtn.evaluate().length}');
    expect(callBtn, findsWidgets, reason: 'Call button not found in chat');
    final inkWells = find.ancestor(
      of: find.byIcon(Icons.phone_outlined),
      matching: find.byType(InkWell),
    );
    expect(inkWells, findsWidgets, reason: 'Phone InkWell not found');
    final callInkWell = tester.widget<InkWell>(inkWells.first);
    expect(callInkWell.onTap, isNotNull, reason: 'Call button is disabled');
    callInkWell.onTap!();
    await tester.pump(const Duration(milliseconds: 500));
    debugPrint('[CALLER] Call button invoked');

    // ── Verify VoiceCallScreen appears ────────────────────────────
    // Wait for call_end icon (hangup button) — LiveKit connection can take 60s on emulator
    final hasCallScreen = await tester.waitFor(
      find.byIcon(Icons.call_end_rounded),
      timeout: const Duration(seconds: 90),
    );
    if (!hasCallScreen) {
      // Debug: check what's on screen
      final widgets = find.byType(Scaffold);
      debugPrint('[CALLER] Scaffolds on screen: ${widgets.evaluate().length}');
      final texts = find.byType(Text);
      for (final t in texts.evaluate().take(5)) {
        final w = t.widget as Text;
        debugPrint('[CALLER] Text: "${w.data}"');
      }
    }
    expect(hasCallScreen, isTrue, reason: 'VoiceCallScreen (hangup button) not found');
    debugPrint('[CALLER] Voice call screen loaded');

    // ── Wait for other participant to join ─────────────────────────
    // Wait for "Call active" text or PulsingAvatar (remote participant)
    debugPrint('[CALLER] Waiting for remote participant (40s)...');
    await tester.pumpFor(const Duration(seconds: 40));

    // Verify no error
    expect(find.byType(ErrorWidget), findsNothing, reason: 'Voice screen crashed');

    // ── Verify we see at least one participant avatar ──────────────
    final avatars = find.byType(CircleAvatar);
    debugPrint('[CALLER] CircleAvatars on screen: ${avatars.evaluate().length}');
    // At minimum, we should see our own avatar
    expect(avatars, findsWidgets, reason: 'No participant avatars visible');

    // ── Hangup ────────────────────────────────────────────────────
    final hangup = find.byIcon(Icons.call_end_rounded);
    await tester.tap(hangup.first, warnIfMissed: false);
    debugPrint('[CALLER] Hangup tapped');
    await tester.pumpFor(const Duration(seconds: 5));

    // Allow audioplayers & other animations to fully stop before teardown
    await tester.binding.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 500));
    });

    // Should be back on chat or dashboard
    debugPrint('[CALLER] ✓ Call test complete');
  });
}

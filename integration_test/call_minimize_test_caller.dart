/// Caller for the minimize-repro: makes the call, holds for 60s so
/// receiver has time to minimize + navigate to messenger + observe.
///
/// flutter test integration_test/call_minimize_test_caller.dart \
///   --flavor dev --dart-define=FLAVOR=dev \
///   --dart-define=BASE_URL=https://staging.id.taler.tirol \
///   -d emulator-5554
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:taler_id_mobile/main.dart' as app;
import 'package:taler_id_mobile/core/services/call_state_service.dart';

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

  testWidgets('CALLER (minimize-repro): login → call → hold for 60s → report remote drop', (tester) async {
    app.main();
    await tester.pumpFor(const Duration(seconds: 6));

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
    debugPrint('[REPRO-CALL] Dashboard loaded');

    const convId = '91f97844-307b-4a20-ad62-c1d2820e627f';
    await tester.safeTap(find.byIcon(Icons.chat_bubble_outline_rounded));
    await tester.pumpFor(const Duration(seconds: 3));

    final messengerElement = tester.element(find.byType(Scaffold).first);
    GoRouter.of(messengerElement).push('/dashboard/messenger/$convId');
    await tester.pumpFor(const Duration(seconds: 4));

    await tester.waitFor(find.byIcon(Icons.phone_outlined), timeout: const Duration(seconds: 8));

    debugPrint('[REPRO-CALL] Receiver already ready (orchestrator confirmed dashboard), calling now');
    await tester.pumpFor(const Duration(seconds: 3));

    final callBtn = find.byIcon(Icons.phone_outlined);
    expect(callBtn, findsWidgets);
    final iconBtns = find.ancestor(of: find.byIcon(Icons.phone_outlined), matching: find.byType(IconButton));
    final callIconBtn = tester.widget<IconButton>(iconBtns.first);
    callIconBtn.onPressed!();
    await tester.pump(const Duration(milliseconds: 500));
    debugPrint('[REPRO-CALL] Call button invoked');

    final hasCallScreen = await tester.waitFor(find.byIcon(Icons.call_end_rounded), timeout: const Duration(seconds: 90));
    expect(hasCallScreen, isTrue);
    debugPrint('[REPRO-CALL] Voice call screen loaded');

    // Hold the call for 120s; poll our own state + remote participant count
    debugPrint('[REPRO-CALL] Holding call for 120s — polling state each sec...');
    bool reportedDrop = false;
    for (int i = 0; i < 120; i++) {
      await tester.pumpFor(const Duration(seconds: 1));
      final cs = CallStateService.instance;
      final alive = cs.isInCall;
      final participants = cs.activeLine?.room.remoteParticipants.length ?? 0;
      if (i % 2 == 0 || !alive) {
        debugPrint('[REPRO-CALL] t=${i + 1}s  isInCall=$alive  remoteParticipants=$participants');
      }
      if (!alive && !reportedDrop) {
        debugPrint('[REPRO-CALL] ❌ CALL DROPPED AT CALLER t=${i + 1}s');
        reportedDrop = true;
        break;
      }
    }

    debugPrint('[REPRO-CALL] ✓ Caller test complete');
    final hangup = find.byIcon(Icons.call_end_rounded);
    if (hangup.evaluate().isNotEmpty) {
      await tester.tap(hangup.first, warnIfMissed: false);
    }
    await tester.pumpFor(const Duration(seconds: 3));
  });
}

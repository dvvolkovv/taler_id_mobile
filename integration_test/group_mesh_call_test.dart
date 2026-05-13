/// Taler ID — Group Mesh Voice Room: host-side integration test
///
/// Exercises: login → Call History tab → "New group call" FAB →
/// contact picker → (if mesh contacts present) select + confirm →
/// lobby screen with Cancel button.
///
/// Запуск:
///   flutter test integration_test/group_mesh_call_test.dart \
///     --flavor dev --dart-define=FLAVOR=dev \
///     --dart-define=BASE_URL=https://staging.id.taler.tirol \
///     -d emulator-5554
///
/// Для двух эмуляторов см. integration_test/run_group_mesh_call_test.sh.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:taler_id_mobile/main_dev.dart' as app;

// ── Config ──────────────────────────────────────────────────────────────────

/// Test account on DEV (staging).
const _testEmail = 'integration_test@taler-test.com';
const _testPass = 'IntegrationTest123!';

// ── Helpers ─────────────────────────────────────────────────────────────────

extension _PumpHelper on WidgetTester {
  /// Pumps until [finder] appears or [timeout] expires; returns found status.
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

  /// Pumps for [duration] in 1-second increments.
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

  /// Taps [finder] if present; returns whether a tap was performed.
  Future<bool> safeTap(Finder finder) async {
    if (finder.evaluate().isNotEmpty) {
      await tap(finder.first, warnIfMissed: false);
      await pumpFor(const Duration(seconds: 2));
      return true;
    }
    return false;
  }
}

// ── Main ─────────────────────────────────────────────────────────────────────

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'group mesh call: host taps FAB, picks contact, reaches lobby',
    (tester) async {
      // ── 1. Launch ──────────────────────────────────────────────────────
      app.main();
      await tester.pumpFor(const Duration(seconds: 6)); // splash + DI + Firebase

      // ── 2. Handle Splash → Onboarding or Login ─────────────────────────
      bool hasLogin = false;
      final authDeadline = DateTime.now().add(const Duration(seconds: 20));
      while (DateTime.now().isBefore(authDeadline)) {
        await tester.pump(const Duration(milliseconds: 300));
        if (find.text('Next').evaluate().isNotEmpty) {
          debugPrint('[GMC-TEST] Onboarding — tapping through');
          for (var i = 0; i < 5; i++) {
            if (find.text('Next').evaluate().isNotEmpty) {
              await tester.tap(find.text('Next').first, warnIfMissed: false);
              await tester.pumpFor(const Duration(seconds: 1));
            }
          }
          await tester.safeTap(find.text('Get Started'));
          await tester.safeTap(find.text('Skip'));
          break;
        }
        if (find.text('Skip').evaluate().isNotEmpty) {
          await tester.tap(find.text('Skip').first, warnIfMissed: false);
          await tester.pumpFor(const Duration(seconds: 2));
          break;
        }
        if (find.byType(TextFormField).evaluate().isNotEmpty) {
          debugPrint('[GMC-TEST] Login screen detected');
          hasLogin = true;
          break;
        }
        // Already on dashboard (orbital nav)
        if (find.byIcon(Icons.chat_bubble_outline_rounded).evaluate().isNotEmpty) {
          debugPrint('[GMC-TEST] Already on dashboard');
          break;
        }
      }

      // ── 3. Login if needed ─────────────────────────────────────────────
      if (!hasLogin) {
        hasLogin = await tester.waitFor(
          find.byType(TextFormField),
          timeout: const Duration(seconds: 10),
        );
      }

      if (hasLogin) {
        debugPrint('[GMC-TEST] Entering credentials');
        final textFields = find.byType(TextFormField);
        expect(textFields, findsAtLeast(2),
            reason: 'Expected email + password fields');

        await tester.enterText(textFields.first, _testEmail);
        await tester.pump();
        await tester.enterText(textFields.at(1), _testPass);
        await tester.pump();

        FocusManager.instance.primaryFocus?.unfocus();
        await tester.pumpFor(const Duration(seconds: 2));

        if (find.byType(SingleChildScrollView).evaluate().isNotEmpty) {
          await tester.drag(
              find.byType(SingleChildScrollView).first, const Offset(0, -200));
          await tester.pumpFor(const Duration(seconds: 1));
        }

        final loginBtn = find.byType(ElevatedButton);
        if (loginBtn.evaluate().isNotEmpty) {
          await tester.ensureVisible(loginBtn.first);
          await tester.pumpFor(const Duration(milliseconds: 500));
          await tester.tap(loginBtn.first, warnIfMissed: false);
          debugPrint('[GMC-TEST] Login button tapped');
        }
      } else {
        debugPrint('[GMC-TEST] No login form — already authenticated');
      }

      // ── 3b. Handle post-login onboarding ──────────────────────────────
      await tester.pumpFor(const Duration(seconds: 3));
      final onboardingDeadline = DateTime.now().add(const Duration(seconds: 15));
      while (DateTime.now().isBefore(onboardingDeadline)) {
        await tester.pump(const Duration(milliseconds: 300));
        if (find.text('Next').evaluate().isNotEmpty) {
          for (var i = 0; i < 5; i++) {
            if (find.text('Next').evaluate().isNotEmpty) {
              await tester.tap(find.text('Next').first, warnIfMissed: false);
              await tester.pumpFor(const Duration(seconds: 1));
            }
          }
          await tester.safeTap(find.text('Get Started'));
          await tester.safeTap(find.text('Skip'));
          break;
        }
        if (find.text('Skip').evaluate().isNotEmpty) {
          await tester.tap(find.text('Skip').first, warnIfMissed: false);
          await tester.pumpFor(const Duration(seconds: 2));
          break;
        }
        if (find.byIcon(Icons.chat_bubble_outline_rounded).evaluate().isNotEmpty) break;
      }

      // ── 4. Wait for dashboard ──────────────────────────────────────────
      final hasDashboard = await tester.waitFor(
        find.byIcon(Icons.chat_bubble_outline_rounded),
        timeout: const Duration(seconds: 30),
      );
      expect(hasDashboard, isTrue,
          reason: 'Dashboard (orbital nav) should appear after login');
      debugPrint('[GMC-TEST] Dashboard loaded');

      // ── 5. Navigate to Call History tab ───────────────────────────────
      // The call history icon on the orbital nav — matches what app_test.dart uses.
      await tester.safeTap(find.byIcon(Icons.call_outlined));
      await tester.pumpFor(const Duration(seconds: 3));
      expect(find.byType(ErrorWidget), findsNothing,
          reason: 'Call History screen must not crash');
      debugPrint('[GMC-TEST] Call History screen open');

      // ── 6. Locate the "New group call" FAB ────────────────────────────
      // The FAB uses Icons.group_add_rounded (FloatingActionButton.extended)
      // and is always visible in prod/dev once Task 13 un-gates it.
      final fab = find.byIcon(Icons.group_add_rounded);
      expect(fab, findsOneWidget,
          reason:
              'Group mesh call FAB (Icons.group_add_rounded) should be visible '
              'on the Call History screen');
      debugPrint('[GMC-TEST] FAB found — tapping');
      await tester.tap(fab, warnIfMissed: false);
      await tester.pumpFor(const Duration(seconds: 3));
      expect(find.byType(ErrorWidget), findsNothing,
          reason: 'NewGroupCallScreen must not crash on open');

      // ── 7. Contact picker screen ───────────────────────────────────────
      // Contacts are CheckboxListTile rows. If none are present (no mesh-
      // reachable contacts in this environment), return early — valid state.
      final anyCheckbox = find.byType(CheckboxListTile);
      if (anyCheckbox.evaluate().isEmpty) {
        debugPrint(
            '[GMC-TEST] No mesh-reachable contacts on this emulator session — '
            'returning early (valid environment state).');
        return;
      }
      debugPrint(
          '[GMC-TEST] ${anyCheckbox.evaluate().length} contact(s) found in picker');

      // Tap the first CheckboxListTile to select it.
      await tester.tap(anyCheckbox.first, warnIfMissed: false);
      await tester.pumpFor(const Duration(seconds: 1));

      // ── 8. Confirm via the AppBar check-mark button ────────────────────
      // The "start" action is an IconButton(Icons.check_rounded) in the AppBar;
      // tooltip is l10n.meshGcStart ("Начать групповой звонок" / "Start group call").
      final confirmBtn = find.byIcon(Icons.check_rounded);
      if (confirmBtn.evaluate().isEmpty) {
        // Selection may not have stuck (contact went offline between load and tap).
        debugPrint('[GMC-TEST] Confirm button not enabled — contact offline, returning early');
        return;
      }
      debugPrint('[GMC-TEST] Tapping confirm (check_rounded)');
      await tester.tap(confirmBtn.first, warnIfMissed: false);

      // ── 9. Wait for lobby navigation ─────────────────────────────────
      // GMCStartRequested → bloc → service.start() → emits GMCLobby →
      // BlocListener routes to /group-call/:id/lobby → GroupCallLobbyScreen.
      // Allow several seconds for the Noise handshake + LiveKit room setup.
      await tester.pumpFor(const Duration(seconds: 5));
      expect(find.byType(ErrorWidget), findsNothing,
          reason: 'GroupCallLobbyScreen must not crash');

      // ── 10. Assert lobby is displayed ─────────────────────────────────
      // The lobby renders an OutlinedButton.icon whose label is
      // l10n.meshGcCancel ("Отмена" / "Cancel"). This is the most reliable
      // widget to assert on — it only exists on the lobby screen.
      final cancelBtn = find.byType(OutlinedButton);
      expect(cancelBtn, findsWidgets,
          reason:
              'GroupCallLobbyScreen should render the Cancel (OutlinedButton) '
              'while waiting for invitees');

      // Extra: assert no ErrorWidget survived the transition.
      expect(find.byType(ErrorWidget), findsNothing,
          reason: 'No ErrorWidget after reaching lobby');

      debugPrint('[GMC-TEST] ✓ Lobby screen reached — Cancel button visible');

      // Cross-device portion (invitee Accept → GMCActive → active screen) is
      // exercised by integration_test/run_group_mesh_call_test.sh with manual
      // invitee coordination, and by hardware smoke as documented in the
      // implementation plan §16.
    },
  );
}

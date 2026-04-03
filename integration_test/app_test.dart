/// Taler ID — Full Integration Test
///
/// Запуск на Android эмуляторе:
///   flutter test integration_test/app_test.dart --flavor dev \
///     --dart-define=FLAVOR=dev \
///     --dart-define=BASE_URL=https://staging.id.taler.tirol \
///     -d emulator-5554
///
/// Запуск на Android устройстве:
///   flutter test integration_test/app_test.dart --flavor dev \
///     --dart-define=FLAVOR=dev \
///     --dart-define=BASE_URL=https://staging.id.taler.tirol \
///     -d 78c0742f
///
/// Запуск на iPhone:
///   flutter test integration_test/app_test.dart --flavor dev \
///     --dart-define=FLAVOR=dev \
///     --dart-define=BASE_URL=https://staging.id.taler.tirol \
///     -d 00008101-000E21100202001E
///
/// Тест проходит: логин → все экраны через орбитальную навигацию → подэкраны → проверка данных.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:taler_id_mobile/main.dart' as app;

// ── Config ─────────────────────────────────────────────────────────────────

/// Тестовый аккаунт на DEV (staging). Создаётся один раз, не удаляется.
const _testEmail = 'integration_test@taler-test.com';
const _testPass = 'IntegrationTest123!';

// ── Helpers ────────────────────────────────────────────────────────────────

extension PumpHelper on WidgetTester {
  /// Ждёт пока виджет появится (макс [timeout]).
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

  /// Ждёт [duration], периодически пампая фреймы.
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

  /// Безопасный тап — если найден, тапнуть; если нет — пропустить.
  Future<bool> safeTap(Finder finder) async {
    if (finder.evaluate().isNotEmpty) {
      await tap(finder.first, warnIfMissed: false);
      await pumpFor(const Duration(seconds: 2));
      return true;
    }
    return false;
  }

  /// Возвращает на ассистента через home FAB или back arrow.
  Future<void> goHome() async {
    // Try home FAB first (visible on all non-assistant routes)
    if (find.byIcon(Icons.home_rounded).evaluate().isNotEmpty) {
      await tap(find.byIcon(Icons.home_rounded).first, warnIfMissed: false);
      await pumpFor(const Duration(seconds: 2));
      return;
    }
    // Fallback: back arrow
    if (find.byIcon(Icons.arrow_back_ios_new_rounded).evaluate().isNotEmpty) {
      await tap(find.byIcon(Icons.arrow_back_ios_new_rounded).first, warnIfMissed: false);
      await pumpFor(const Duration(seconds: 2));
      return;
    }
    if (find.byIcon(Icons.arrow_back).evaluate().isNotEmpty) {
      await tap(find.byIcon(Icons.arrow_back).first, warnIfMissed: false);
      await pumpFor(const Duration(seconds: 2));
    }
  }
}

// ── Main ───────────────────────────────────────────────────────────────────

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Full App Smoke Test', () {
    testWidgets('Login → Dashboard → All screens → Sub-screens', (tester) async {
      // ── 1. Launch app ──────────────────────────────────────────────
      app.main();
      await tester.pumpFor(const Duration(seconds: 6)); // splash + DI + Firebase

      // ── 2. Handle Splash → Onboarding or Login ─────────────────────
      bool hasLogin = false;
      final deadline = DateTime.now().add(const Duration(seconds: 20));
      while (DateTime.now().isBefore(deadline)) {
        await tester.pump(const Duration(milliseconds: 300));
        // Check onboarding
        if (find.text('Next').evaluate().isNotEmpty) {
          debugPrint('[TEST] Onboarding detected — tapping through');
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
          debugPrint('[TEST] Onboarding Skip detected');
          await tester.tap(find.text('Skip').first, warnIfMissed: false);
          await tester.pumpFor(const Duration(seconds: 2));
          break;
        }
        // Check login form
        if (find.byType(TextFormField).evaluate().isNotEmpty) {
          debugPrint('[TEST] Login screen detected');
          hasLogin = true;
          break;
        }
        // Check if already on assistant screen (orbital nav)
        if (find.byIcon(Icons.chat_bubble_outline_rounded).evaluate().isNotEmpty) {
          debugPrint('[TEST] Already on dashboard (orbital nav)');
          break;
        }
      }

      // ── 3. Login screen ────────────────────────────────────────────
      if (!hasLogin) {
        hasLogin = await tester.waitFor(
          find.byType(TextFormField),
          timeout: const Duration(seconds: 10),
        );
      }

      if (hasLogin) {
        debugPrint('[TEST] Login screen found — entering credentials');

        final textFields = find.byType(TextFormField);
        expect(textFields, findsAtLeast(2), reason: 'Expected email + password fields');

        // Enter email
        await tester.enterText(textFields.first, _testEmail);
        await tester.pump();

        // Enter password
        await tester.enterText(textFields.at(1), _testPass);
        await tester.pump();

        // Close keyboard
        FocusManager.instance.primaryFocus?.unfocus();
        await tester.pumpFor(const Duration(seconds: 2));

        // Scroll down to make login button visible (keyboard may have pushed it off)
        await tester.drag(find.byType(SingleChildScrollView).first, const Offset(0, -200));
        await tester.pumpFor(const Duration(seconds: 1));

        // Tap login button
        final loginBtn = find.byType(ElevatedButton);
        if (loginBtn.evaluate().isNotEmpty) {
          await tester.ensureVisible(loginBtn.first);
          await tester.pumpFor(const Duration(milliseconds: 500));
          await tester.tap(loginBtn.first, warnIfMissed: false);
          debugPrint('[TEST] Login button tapped');
        }
      } else {
        debugPrint('[TEST] Login screen not found — maybe already authenticated');
      }

      // ── 4. Wait for dashboard (orbital nav assistant screen) ────────
      // The new design has orbital circles — detect Messages circle icon
      final hasDashboard = await tester.waitFor(
        find.byIcon(Icons.chat_bubble_outline_rounded),
        timeout: const Duration(seconds: 20),
      );
      expect(hasDashboard, isTrue, reason: 'Dashboard (orbital nav) should appear after login');
      debugPrint('[TEST] Dashboard loaded with orbital navigation');

      // ── 5. Screen: Messages ────────────────────────────────────────
      await tester.safeTap(find.byIcon(Icons.chat_bubble_outline_rounded));
      await tester.pumpFor(const Duration(seconds: 2));
      expect(find.byType(ErrorWidget), findsNothing, reason: 'Messenger screen crashed');
      debugPrint('[TEST] ✓ Messenger screen OK');
      await tester.goHome();

      // ── 6. Screen: Calls ───────────────────────────────────────────
      await tester.safeTap(find.byIcon(Icons.call_outlined));
      await tester.pumpFor(const Duration(seconds: 2));
      expect(find.byType(ErrorWidget), findsNothing, reason: 'Calls screen crashed');
      debugPrint('[TEST] ✓ Calls screen OK');
      await tester.goHome();

      // ── 7. Screen: Calendar ────────────────────────────────────────
      await tester.safeTap(find.byIcon(Icons.calendar_month_outlined));
      await tester.pumpFor(const Duration(seconds: 2));
      expect(find.byType(ErrorWidget), findsNothing, reason: 'Calendar screen crashed');
      debugPrint('[TEST] ✓ Calendar screen OK');
      await tester.goHome();

      // ── 8. Screen: Profile ─────────────────────────────────────────
      await tester.safeTap(find.byIcon(Icons.person_outline));
      await tester.pumpFor(const Duration(seconds: 2));
      expect(find.byType(ErrorWidget), findsNothing, reason: 'Profile screen crashed');
      debugPrint('[TEST] ✓ Profile screen OK');

      // ── 8a. Edit Profile → change firstName → save ─────────────────
      if (await tester.safeTap(find.byIcon(Icons.edit_outlined))) {
        await tester.pumpFor(const Duration(seconds: 2));
        expect(find.byType(ErrorWidget), findsNothing, reason: 'Edit profile screen crashed');
        debugPrint('[TEST] Edit profile screen opened');

        // Find firstName field and update it
        final fields = find.byType(TextFormField);
        if (fields.evaluate().isNotEmpty) {
          // Clear and re-enter firstName
          await tester.tap(fields.first, warnIfMissed: false);
          await tester.pump();
          await tester.enterText(fields.first, 'Integration');
          await tester.pump();
          FocusManager.instance.primaryFocus?.unfocus();
          await tester.pumpFor(const Duration(seconds: 1));
          debugPrint('[TEST] firstName set to "Integration"');

          // Scroll down to find save button
          if (find.byType(SingleChildScrollView).evaluate().isNotEmpty) {
            await tester.drag(find.byType(SingleChildScrollView).first, const Offset(0, -300));
            await tester.pumpFor(const Duration(seconds: 1));
          }

          // Tap save (ElevatedButton or the save text button in AppBar)
          final saveBtn = find.byType(ElevatedButton);
          final saveText = find.text('Сохранить').or(find.text('Save'));
          if (saveBtn.evaluate().isNotEmpty) {
            await tester.tap(saveBtn.first, warnIfMissed: false);
          } else if (saveText.evaluate().isNotEmpty) {
            await tester.tap(saveText.first, warnIfMissed: false);
          }
          await tester.pumpFor(const Duration(seconds: 4));
          expect(find.byType(ErrorWidget), findsNothing, reason: 'Profile save crashed');
          debugPrint('[TEST] ✓ Profile saved');
        }

        // Navigate back if still on edit screen
        await tester.goHome();
        await tester.pumpFor(const Duration(seconds: 1));
      }

      await tester.goHome();

      // ── 9. Screen: Settings ────────────────────────────────────────
      await tester.safeTap(find.byIcon(Icons.settings_outlined));
      await tester.pumpFor(const Duration(seconds: 2));
      expect(find.byType(ErrorWidget), findsNothing, reason: 'Settings screen crashed');
      debugPrint('[TEST] ✓ Settings screen OK');

      // ── 10. Settings → Sessions sub-screen ─────────────────────────
      if (await tester.safeTap(find.text('Sessions'))) {
        await tester.pumpFor(const Duration(seconds: 2));
        expect(find.byType(ErrorWidget), findsNothing, reason: 'Sessions screen crashed');
        debugPrint('[TEST] ✓ Sessions screen OK');
        await tester.safeTap(find.byIcon(Icons.arrow_back));
        await tester.pumpFor(const Duration(seconds: 1));
      }
      await tester.goHome();

      // ── 11. Messages → open conversation ───────────────────────────
      await tester.safeTap(find.byIcon(Icons.chat_bubble_outline_rounded));
      await tester.pumpFor(const Duration(seconds: 3));

      final listTiles = find.byType(ListTile);
      if (listTiles.evaluate().length > 1) {
        await tester.tap(listTiles.at(0), warnIfMissed: false);
        await tester.pumpFor(const Duration(seconds: 3));
        expect(find.byType(ErrorWidget), findsNothing, reason: 'Chat room crashed');
        debugPrint('[TEST] ✓ Chat room OK');
        await tester.safeTap(find.byIcon(Icons.arrow_back));
      }
      await tester.goHome();

      // ── 12. Calendar → Create event ────────────────────────────────
      await tester.safeTap(find.byIcon(Icons.calendar_month_outlined));
      await tester.pumpFor(const Duration(seconds: 2));

      if (await tester.safeTap(find.byType(FloatingActionButton))) {
        await tester.pumpFor(const Duration(seconds: 2));
        expect(find.byType(ErrorWidget), findsNothing, reason: 'New event screen crashed');
        debugPrint('[TEST] ✓ New event screen OK');
        await tester.safeTap(find.byIcon(Icons.arrow_back));
      }
      await tester.goHome();

      // ── 13. Final check ────────────────────────────────────────────
      expect(find.byType(ErrorWidget), findsNothing, reason: 'App has ErrorWidget at the end');
      debugPrint('[TEST] ✓ All screens passed — no crashes detected');
    });
  });
}

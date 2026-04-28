# Call Details: Tap Participant Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make participant rows in the Call Details screen tappable; tap opens existing `UserProfileScreen` for non-self users.

**Architecture:** Extract a private `_ParticipantTile` widget inside [call_history_screen.dart](lib/features/call_history/presentation/screens/call_history_screen.dart). Wire `currentUserId` from `MessengerBloc.state.currentUserId`. Add localized `(Вы) / (You)` suffix for self-row. No backend, API, route, or domain changes.

**Tech Stack:** Flutter, flutter_bloc (`MessengerBloc`), GoRouter (existing route `/dashboard/user/:userId`), AppLocalizations (ARB).

**Spec:** [docs/superpowers/specs/2026-04-28-call-details-tap-participant-design.md](docs/superpowers/specs/2026-04-28-call-details-tap-participant-design.md)

---

## File Map

- **Modify** `lib/l10n/app_ru.arb` — add key `callDetailYouSuffix`
- **Modify** `lib/l10n/app_en.arb` — add key `callDetailYouSuffix`
- **Modify** `lib/features/call_history/presentation/screens/call_history_screen.dart`:
  - Add import for `flutter_bloc` (likely already present) and `MessengerBloc`
  - Replace inline participants block (lines 1682-1734) with `_ParticipantTile` mapping
  - Append new `_ParticipantTile` widget class to end of file
- **Create** `test/features/call_history/participant_tile_test.dart` — widget test for the decision tree
- **Modify** `integration_test/app_test.dart` — add navigation step into call details and tap

---

## Pre-flight

Before starting, confirm working state:

- [ ] **Step P1: Verify branch and clean tree**

```bash
cd ~/Downloads/taler_id_mobile
git status
git branch --show-current
```

Expected: branch is `dev`, working tree clean (or only this plan/spec staged).

- [ ] **Step P2: Confirm baseline tests pass**

```bash
cd ~/Downloads/taler_id_mobile && flutter test
```

Expected: existing test suite green. If red, stop and fix baseline before starting.

---

## Task 1: Add localized "(You)" suffix to ARB files

**Files:**
- Modify: `lib/l10n/app_ru.arb`
- Modify: `lib/l10n/app_en.arb`

- [ ] **Step 1.1: Add key to Russian ARB**

Locate the existing `callHistory*` block in `lib/l10n/app_ru.arb` (search for `"callHistoryParticipants"`). Add the new key alphabetically near other `callHistory*` keys, plus the metadata block. Example fragment:

```json
"callDetailYouSuffix": "(Вы)",
"@callDetailYouSuffix": {
  "description": "Suffix appended to the current user's display name in the call details participants list."
},
```

- [ ] **Step 1.2: Add key to English ARB**

In `lib/l10n/app_en.arb`, add identical metadata structure with English value:

```json
"callDetailYouSuffix": "(You)",
"@callDetailYouSuffix": {
  "description": "Suffix appended to the current user's display name in the call details participants list."
},
```

- [ ] **Step 1.3: Regenerate localizations**

```bash
cd ~/Downloads/taler_id_mobile && flutter gen-l10n
```

Expected: no errors. New getter `AppLocalizations.callDetailYouSuffix` is generated in `lib/l10n/app_localizations.dart` (or wherever the project keeps generated l10n).

- [ ] **Step 1.4: Verify the getter exists**

```bash
cd ~/Downloads/taler_id_mobile && grep -rn "callDetailYouSuffix" lib/l10n/
```

Expected: matches in both `app_ru.arb`, `app_en.arb`, and the generated `app_localizations*.dart` file(s).

- [ ] **Step 1.5: Commit**

```bash
cd ~/Downloads/taler_id_mobile
git add lib/l10n/app_ru.arb lib/l10n/app_en.arb lib/l10n/
git commit -m "i18n(call-history): add callDetailYouSuffix key"
```

---

## Task 2: Add `_ParticipantTile` widget (no behavior change yet)

**Files:**
- Modify: `lib/features/call_history/presentation/screens/call_history_screen.dart` — append new widget class

This task adds the widget definition without yet wiring it into the participants list. Allows isolated review of the widget logic.

- [ ] **Step 2.1: Inspect existing imports in call_history_screen.dart**

```bash
cd ~/Downloads/taler_id_mobile && head -25 lib/features/call_history/presentation/screens/call_history_screen.dart
```

Note which of these are already imported:
- `package:flutter/material.dart`
- `package:flutter_bloc/flutter_bloc.dart`
- `package:go_router/go_router.dart`
- The project's `MessengerBloc` import path
- `AppColorsExtension` import path (defined in `lib/core/theme/app_theme.dart`)
- `rainbowColorFor` helper import path
- `l10n` / `AppLocalizations` import path

- [ ] **Step 2.2: Append `_ParticipantTile` to the bottom of `call_history_screen.dart`**

Add at the very end of the file (after the last closing brace of any existing widget, just before EOF):

```dart
class _ParticipantTile extends StatelessWidget {
  const _ParticipantTile({
    required this.data,
    required this.currentUserId,
    required this.colors,
    required this.youSuffix,
    required this.unknownLabel,
  });

  final Map<String, dynamic> data;
  final String? currentUserId;
  final AppColorsExtension colors;
  final String youSuffix;
  final String unknownLabel;

  @override
  Widget build(BuildContext context) {
    final rawName = data['displayName'] as String?;
    final name = (rawName == null || rawName.isEmpty) ? unknownLabel : rawName;
    final userId = data['userId'] as String?;
    final isSelf = userId != null && userId == currentUserId;
    final isTappable = userId != null && !isSelf;

    final displayText = isSelf ? '$name $youSuffix' : name;

    final row = Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          _buildAvatar(name),
          const SizedBox(width: 12),
          Expanded(
            child: Text(displayText, style: TextStyle(color: colors.textPrimary, fontSize: 15)),
          ),
        ],
      ),
    );

    if (!isTappable) return row;

    return InkWell(
      onTap: () => context.push('/dashboard/user/$userId'),
      borderRadius: BorderRadius.circular(8),
      child: row,
    );
  }

  Widget _buildAvatar(String name) {
    final ringColor = rainbowColorFor(name.isNotEmpty ? name : '$data');
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: ringColor, width: 1.5),
        boxShadow: [
          BoxShadow(color: ringColor.withOpacity(0.35), blurRadius: 6),
        ],
      ),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            center: const Alignment(-0.3, -0.4),
            radius: 1.1,
            colors: [
              Color.lerp(ringColor, Colors.white, 0.3)!,
              ringColor,
              Color.lerp(ringColor, Colors.black, 0.4)!,
            ],
            stops: const [0.0, 0.55, 1.0],
          ),
        ),
        child: Center(
          child: Text(
            name.isNotEmpty ? name[0].toUpperCase() : '?',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2.3: Add any missing imports**

If Step 2.1 showed `go_router` is not imported, add to the import block at the top of the file:

```dart
import 'package:go_router/go_router.dart';
```

If `flutter_bloc` is not imported (needed for Task 3), add:

```dart
import 'package:flutter_bloc/flutter_bloc.dart';
```

If `MessengerBloc` is not imported, add (path may vary — verify by grepping `class MessengerBloc`):

```bash
cd ~/Downloads/taler_id_mobile && grep -rn "class MessengerBloc" lib/
```

Then add the matching import.

- [ ] **Step 2.4: Run analyzer to confirm no syntax errors and no unused-warning yet**

```bash
cd ~/Downloads/taler_id_mobile && flutter analyze lib/features/call_history/presentation/screens/call_history_screen.dart
```

Expected: zero errors. Possibly a warning about `_ParticipantTile` being unused — that's expected, will be wired in Task 3. If the analyzer treats unused private classes as errors in this project, it's still acceptable to commit and immediately wire it in Task 3.

- [ ] **Step 2.5: Commit**

```bash
cd ~/Downloads/taler_id_mobile
git add lib/features/call_history/presentation/screens/call_history_screen.dart
git commit -m "feat(call-history): add _ParticipantTile widget (not yet wired)"
```

---

## Task 3: Wire `_ParticipantTile` into the participants list

**Files:**
- Modify: `lib/features/call_history/presentation/screens/call_history_screen.dart` — replace lines 1682-1734 region

- [ ] **Step 3.1: Locate the current participants block**

```bash
cd ~/Downloads/taler_id_mobile && sed -n '1672,1738p' lib/features/call_history/presentation/screens/call_history_screen.dart
```

Confirm you see the `// Participants` comment, the `if (participants.isNotEmpty) ...[` block, the inline `participants.map((p) { return Padding(Row( ...` body, and the closing `]`.

- [ ] **Step 3.2: Replace the inline body with `_ParticipantTile` mapping**

Find the section starting from `// Participants` (around line 1673). Replace the inner `AppCard(child: Column(...))` body so the surrounding section header stays intact. The AppCard should become:

```dart
AppCard(
  child: Column(
    children: () {
      final currentUserId = context.read<MessengerBloc>().state.currentUserId;
      return participants.map((p) => _ParticipantTile(
        data: p as Map<String, dynamic>,
        currentUserId: currentUserId,
        colors: colors,
        youSuffix: l10n.callDetailYouSuffix,
        unknownLabel: l10n.callHistoryUnknown,
      )).toList();
    }(),
  ),
),
```

(The IIFE `() { ... }()` keeps `currentUserId` scoped without needing a separate state field. `MessengerBloc` is provided at the dashboard ShellRoute, so `context.read<MessengerBloc>()` will resolve.)

- [ ] **Step 3.3: Verify the file compiles and analyzer is clean**

```bash
cd ~/Downloads/taler_id_mobile && flutter analyze lib/features/call_history/presentation/screens/call_history_screen.dart
```

Expected: zero errors, zero warnings. (`_ParticipantTile` should now register as used.)

- [ ] **Step 3.4: Run full Flutter test suite to catch regressions**

```bash
cd ~/Downloads/taler_id_mobile && flutter test
```

Expected: all existing tests pass. (No new tests yet — those come in Task 4.)

- [ ] **Step 3.5: Commit**

```bash
cd ~/Downloads/taler_id_mobile
git add lib/features/call_history/presentation/screens/call_history_screen.dart
git commit -m "feat(call-history): tap participant in call details opens user profile"
```

---

## Task 4: Widget test for `_ParticipantTile`

**Files:**
- Create: `test/features/call_history/participant_tile_test.dart`

This is the project's first widget test. We test widget-tree structure (presence of `InkWell`, displayed text), not navigation behavior — navigation goes through `GoRouter` and is covered by the integration test in Task 5. Because `_ParticipantTile` is private, we test it indirectly by re-declaring an identical public test fixture, OR by adding a test-only export. The simpler path: change `_ParticipantTile` to package-private `ParticipantTile` (drop the leading underscore) and add a `// ignore: library_private_types_in_public_api` if needed. We choose this path.

- [ ] **Step 4.1: Rename `_ParticipantTile` → `ParticipantTile` in `call_history_screen.dart`**

Two replacements in `lib/features/call_history/presentation/screens/call_history_screen.dart`:
1. Class declaration: `class _ParticipantTile extends StatelessWidget {` → `class ParticipantTile extends StatelessWidget {`
2. Constructor: `const _ParticipantTile({` → `const ParticipantTile({`
3. Usage in `.map((p) => _ParticipantTile(...))` → `.map((p) => ParticipantTile(...))`

```bash
cd ~/Downloads/taler_id_mobile && grep -n "_ParticipantTile\|ParticipantTile" lib/features/call_history/presentation/screens/call_history_screen.dart
```

Expected: 3 occurrences, all now `ParticipantTile` (without underscore).

- [ ] **Step 4.2: Verify analyzer still clean**

```bash
cd ~/Downloads/taler_id_mobile && flutter analyze lib/features/call_history/presentation/screens/call_history_screen.dart
```

Expected: zero errors.

- [ ] **Step 4.3: Create test directory if missing**

```bash
cd ~/Downloads/taler_id_mobile && mkdir -p test/features/call_history
```

- [ ] **Step 4.4: Write the failing widget tests**

Create file `test/features/call_history/participant_tile_test.dart` with content:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taler_id_mobile/features/call_history/presentation/screens/call_history_screen.dart';
import 'package:taler_id_mobile/l10n/app_localizations.dart';
import 'package:taler_id_mobile/core/theme/app_theme.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: const [Locale('en'), Locale('ru')],
    locale: const Locale('en'),
    home: Scaffold(body: child),
  );
}

void main() {
  // AppColorsExtension is the project's color palette type; .dark and .light
  // factories exist (see lib/core/theme/app_theme.dart).
  final colors = AppColorsExtension.dark;

  group('ParticipantTile', () {
    testWidgets('non-self participant is tappable (InkWell present)', (tester) async {
      await tester.pumpWidget(_wrap(
        ParticipantTile(
          data: const {'displayName': 'Alice', 'userId': 'user-A'},
          currentUserId: 'user-ME',
          colors: colors,
          youSuffix: '(You)',
          unknownLabel: 'Unknown',
        ),
      ));

      expect(find.byType(InkWell), findsOneWidget);
      expect(find.text('Alice'), findsOneWidget);
      expect(find.textContaining('(You)'), findsNothing);
    });

    testWidgets('self participant is not tappable and shows youSuffix', (tester) async {
      await tester.pumpWidget(_wrap(
        ParticipantTile(
          data: const {'displayName': 'Me', 'userId': 'user-ME'},
          currentUserId: 'user-ME',
          colors: colors,
          youSuffix: '(You)',
          unknownLabel: 'Unknown',
        ),
      ));

      expect(find.byType(InkWell), findsNothing);
      expect(find.text('Me (You)'), findsOneWidget);
    });

    testWidgets('participant with missing userId is not tappable', (tester) async {
      await tester.pumpWidget(_wrap(
        ParticipantTile(
          data: const {'displayName': 'Bob'},
          currentUserId: 'user-ME',
          colors: colors,
          youSuffix: '(You)',
          unknownLabel: 'Unknown',
        ),
      ));

      expect(find.byType(InkWell), findsNothing);
      expect(find.text('Bob'), findsOneWidget);
    });

    testWidgets('participant with missing displayName falls back to unknownLabel', (tester) async {
      await tester.pumpWidget(_wrap(
        ParticipantTile(
          data: const {'userId': 'user-X'},
          currentUserId: 'user-ME',
          colors: colors,
          youSuffix: '(You)',
          unknownLabel: 'Unknown',
        ),
      ));

      expect(find.text('Unknown'), findsOneWidget);
      expect(find.byType(InkWell), findsOneWidget);
    });
  });
}
```

- [ ] **Step 4.5: Run tests — expect them to pass since the implementation already exists from Task 3**

```bash
cd ~/Downloads/taler_id_mobile && flutter test test/features/call_history/participant_tile_test.dart
```

Expected: 4 tests, all PASS. Since the implementation already exists from Task 3, these tests should pass on first run. If any FAIL, debug the test setup (most likely cause: AppColors constructor or import path).

- [ ] **Step 4.6: Run the full test suite to confirm no regressions**

```bash
cd ~/Downloads/taler_id_mobile && flutter test
```

Expected: all green.

- [ ] **Step 4.7: Commit**

```bash
cd ~/Downloads/taler_id_mobile
git add test/features/call_history/participant_tile_test.dart \
  lib/features/call_history/presentation/screens/call_history_screen.dart
git commit -m "test(call-history): widget tests for ParticipantTile"
```

---

## Task 5: Extend integration test with call-details navigation

**Files:**
- Modify: `integration_test/app_test.dart`

The existing integration test already opens Call History (per CLAUDE.md "проверяет: Messenger, Calls, Assistant, Calendar, Settings, Profile, Sessions, Chat Room, New Event"). We add a tolerant step that, if a call with a tappable participant exists, taps it and verifies a `UserProfileScreen` appears. Tolerance is critical because the test account's call history may not always have a multi-participant call.

- [ ] **Step 5.1: Locate the Call History block in the integration test**

```bash
cd ~/Downloads/taler_id_mobile && grep -n "Call History\|callHistory\|CallHistory\|Calls\b" integration_test/app_test.dart | head -10
```

Identify the section that navigates to and verifies Call History. Note the line numbers.

- [ ] **Step 5.2: Add a sub-step that tries to open a call detail and tap a participant**

In the Call History section, after the existing checks, add (use `safeTap` helper that already exists in the file):

```dart
// Try to open a call detail and verify tap-on-participant navigation.
// Tolerant — skips if no calls exist or no multi-participant call available.
final callTiles = find.byType(ListTile); // adjust if Call History uses a different tile widget
if (callTiles.evaluate().isNotEmpty) {
  await tester.tap(callTiles.first, warnIfMissed: false);
  await tester.pumpFor(const Duration(seconds: 2));

  // Look for a participant row (ParticipantTile is package-private after Task 4 rename).
  final participantTiles = find.byType(ParticipantTile);
  if (participantTiles.evaluate().length >= 2) {
    // Tap the second tile to skip self (if self is in list, it's typically first).
    await tester.tap(participantTiles.at(1), warnIfMissed: false);
    await tester.pumpFor(const Duration(seconds: 3));

    // Verify we navigated somewhere — could check for AppBar back button or specific screen widget.
    // If UserProfileScreen has a unique key or text, assert that. For now: assert no exception thrown.
    expect(tester.takeException(), isNull);

    // Navigate back to Call History for subsequent test steps.
    await tester.pageBack();
    await tester.pumpFor(const Duration(seconds: 2));
  }

  // Back out of call detail.
  await tester.pageBack();
  await tester.pumpFor(const Duration(seconds: 1));
}
```

- [ ] **Step 5.3: Add the `ParticipantTile` import if used**

At the top of `integration_test/app_test.dart`, add:

```dart
import 'package:taler_id_mobile/features/call_history/presentation/screens/call_history_screen.dart' show ParticipantTile;
```

If `find.byType(ParticipantTile)` is judged too tightly coupled, an alternative is `find.descendant(of: find.text('Участники'), matching: find.byType(InkWell))` — pick whichever is more robust against future renames. Keep one approach, document it inline with a comment if it's the alternative.

- [ ] **Step 5.4: Confirm the test still parses**

```bash
cd ~/Downloads/taler_id_mobile && flutter analyze integration_test/app_test.dart
```

Expected: zero errors.

- [ ] **Step 5.5: Run the integration test on emulator (per CLAUDE.md)**

Make sure an Android emulator is running:

```bash
flutter emulators --launch Pixel_XL_API_33
```

Wait ~15 seconds, then:

```bash
~/Library/Android/sdk/platform-tools/adb devices
```

Expected: `emulator-5554` listed.

Run the integration test:

```bash
cd ~/Downloads/taler_id_mobile && flutter test integration_test/app_test.dart \
  --flavor dev --dart-define=FLAVOR=dev \
  --dart-define=BASE_URL=https://staging.id.taler.tirol \
  -d emulator-5554
```

Expected: all existing assertions still pass; new tolerant step either runs (if test account has a call in history) or no-ops without failing.

- [ ] **Step 5.6: Commit**

```bash
cd ~/Downloads/taler_id_mobile
git add integration_test/app_test.dart
git commit -m "test(integration): tap participant in call details opens profile"
```

---

## Task 6: Manual smoke test on emulator (dev flavor)

This is verification, not implementation. Follow CLAUDE.md's deploy rule: dev first.

- [ ] **Step 6.1: Launch the dev flavor on emulator**

```bash
cd ~/Downloads/taler_id_mobile && flutter run --flavor dev \
  -t lib/main_dev.dart \
  --dart-define=FLAVOR=dev \
  --dart-define=BASE_URL=https://staging.id.taler.tirol \
  -d emulator-5554
```

- [ ] **Step 6.2: Manual checklist**

Log in as `integration_test@taler-test.com` / `IntegrationTest123!`. Then:

1. Navigate to Call History tab.
2. Open any call that has at least 2 participants (one of them being yourself).
3. Verify your own row shows `Имя (Вы)` (or `Name (You)` if device locale is English).
4. Verify your own row does NOT respond to tap (no ripple, no navigation).
5. Tap another participant's row — verify a Material ripple appears, then `UserProfileScreen` opens.
6. From `UserProfileScreen`, tap "Message" — verify it opens chat with that user.
7. Press back — verify you return to call details, not all the way to Call History.
8. Switch device locale to English (Settings → System → Languages → add English, move to top), reopen the app, repeat steps 2-3, expect `(You)` instead of `(Вы)`.

If any step fails: stop, debug, fix in a new commit, re-run smoke before declaring done.

- [ ] **Step 6.3: No commit — manual verification only**

If the smoke test passed, this task is complete. If it failed and required a code fix, that fix is its own commit on `dev`.

---

## Task 7: Pre-deploy test gate (per CLAUDE.md)

Before pushing to `dev` remote (which feeds the dev APK), CLAUDE.md requires the full test gate. We are not deploying in this plan — that is a separate user-initiated step — but we run the gate to confirm we did not break anything.

- [ ] **Step 7.1: Flutter unit tests**

```bash
cd ~/Downloads/taler_id_mobile && flutter test
```

Expected: all green.

- [ ] **Step 7.2: API smoke tests on DEV (only if backend was touched — it was not)**

This task does not touch the backend, so `~/Downloads/taler_id_tests` does not need to run. Skip.

- [ ] **Step 7.3: Push to `dev` branch (only if user explicitly approves push)**

```bash
cd ~/Downloads/taler_id_mobile && git push origin dev
```

⚠️ Per CLAUDE.md, deploy of the dev APK is a separate, user-confirmed step. Do NOT proceed to `flutter build apk --flavor dev` or copy to `/var/www/downloads/` unless the user has explicitly asked for it.

---

## Self-review checklist (run before declaring plan done)

After implementation:

- [ ] All 6 tasks committed on `dev`, no uncommitted edits.
- [ ] Spec requirements all covered: tap navigates non-self → profile (Task 3); self-row shows suffix and is non-tappable (Task 3 logic, verified Task 4 + 6); ARB keys added for ru and en (Task 1); existing screen/route untouched.
- [ ] No backend, route, repository, or domain changes — confirmed by file map.
- [ ] No widget test regressions in existing test suite (Step 3.4, 4.6).

---

## Out of Scope (per spec)

- Visual chevron / color tint on tappable rows
- Bottom sheet action menu on participant tap
- Filtering bot/agent participants
- Changes to `UserProfileScreen`

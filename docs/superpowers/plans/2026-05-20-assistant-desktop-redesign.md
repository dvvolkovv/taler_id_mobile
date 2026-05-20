# Assistant Desktop Redesign — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the macOS Assistant screen auto-start a voice session on entry, replace the orbital "wheel" idle with a minimal restart screen, and expand the desktop Activity bar to absorb the wheel's nav role.

**Architecture:** Pure UI-layer change. No data model or service changes. The existing `_connect()` / `_endCall()` / `_buildIdle()` paths stay — we add a `PlatformUtils.instance.isDesktop` branch in three places.

**Tech Stack:** Flutter, `package:flutter/material.dart`, existing `PlatformUtils.instance.isDesktop` helper, existing `AssistantScreen.connectNotifier` / `autoConnect` static flags.

**Spec:** `docs/superpowers/specs/2026-05-20-assistant-desktop-redesign-design.md`

**No automated tests for this work.** The assistant screen is a 3 200-line stateful widget without unit-test coverage of its UI; adding tests is out of scope. Validation is via `dart analyze` + manual smoke on the running macOS app.

---

## Task 1: Expand Activity Bar with Notes / Contacts / Profile

**Files:**
- Modify: `lib/features/dashboard/desktop/widgets/activity_bar.dart`

- [ ] **Step 1: Open the file and add three items between Calendar and Settings**

Replace the `items` list (around line 14):

```dart
    final items = <_ActivityBarItem>[
      _ActivityBarItem(icon: Icons.chat_bubble_outline, route: RouteConstants.messenger, tooltip: 'Messenger'),
      _ActivityBarItem(icon: Icons.call_outlined, route: RouteConstants.callHistory, tooltip: 'Calls'),
      _ActivityBarItem(icon: Icons.smart_toy_outlined, route: RouteConstants.assistant, tooltip: 'Assistant'),
      _ActivityBarItem(icon: Icons.calendar_today_outlined, route: RouteConstants.calendar, tooltip: 'Calendar'),
      _ActivityBarItem(icon: Icons.sticky_note_2_outlined, route: RouteConstants.notes, tooltip: 'Notes'),
      _ActivityBarItem(icon: Icons.people_outline, route: RouteConstants.contacts, tooltip: 'Contacts'),
      _ActivityBarItem(icon: Icons.person_outline, route: RouteConstants.profile, tooltip: 'Profile'),
      _ActivityBarItem(icon: Icons.settings_outlined, route: RouteConstants.settings, tooltip: 'Settings'),
    ];
```

- [ ] **Step 2: Run analyzer**

```bash
cd ~/Downloads/taler_id_mobile && dart analyze lib/features/dashboard/desktop/widgets/activity_bar.dart
```

Expected: `No issues found!`

- [ ] **Step 3: Commit**

```bash
cd ~/Downloads/taler_id_mobile && git add lib/features/dashboard/desktop/widgets/activity_bar.dart && git commit -m "$(cat <<'EOF'
feat(desktop): add Notes / Contacts / Profile to Activity bar

These three destinations previously lived only inside the Assistant screen's
orbital wheel and were unreachable from the left rail. Adding them in the
slot before Settings makes the activity bar the single source of nav truth
and unblocks the wheel removal in the next commit.

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>
EOF
)"
```

---

## Task 2: Auto-connect voice session on desktop entry

**Files:**
- Modify: `lib/features/assistant/presentation/screens/assistant_screen.dart`

- [ ] **Step 1: Add PlatformUtils import**

At the top of the file, after the existing `import 'package:flutter/services.dart';` (around line 8), add:

```dart
import '../../../../core/platform/platform_utils.dart';
```

(Verify the relative path — `assistant_screen.dart` lives at `lib/features/assistant/presentation/screens/`, so four `..` levels reach `lib/`.)

- [ ] **Step 2: Add the desktop auto-connect branch in `initState`**

Find the existing wake-word block in `initState` (around lines 142-153):

```dart
    // Listen for wake word trigger while already on this screen
    AssistantScreen.connectNotifier.addListener(_onWakeWordTrigger);
    // Auto-connect if triggered by wake word
    if (AssistantScreen.autoConnect) {
      AssistantScreen.autoConnect = false;
      debugPrint('[WakeWord] Auto-connecting assistant...');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _state == _CallState.idle) {
          debugPrint('[WakeWord] Calling _connect()');
          _connect();
        }
      });
    }
  }
```

Insert a desktop branch right after the wake-word block, still inside `initState`:

```dart
    // Listen for wake word trigger while already on this screen
    AssistantScreen.connectNotifier.addListener(_onWakeWordTrigger);
    // Auto-connect if triggered by wake word
    if (AssistantScreen.autoConnect) {
      AssistantScreen.autoConnect = false;
      debugPrint('[WakeWord] Auto-connecting assistant...');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _state == _CallState.idle) {
          debugPrint('[WakeWord] Calling _connect()');
          _connect();
        }
      });
    } else if (PlatformUtils.instance.isDesktop) {
      // Desktop: skip the idle "restart" screen on first entry — start the
      // voice session immediately. Mobile keeps the manual tap-to-start gesture.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _state == _CallState.idle) _connect();
      });
    }
  }
```

- [ ] **Step 3: Run analyzer**

```bash
cd ~/Downloads/taler_id_mobile && dart analyze lib/features/assistant/presentation/screens/assistant_screen.dart
```

Expected: no new errors (pre-existing `info` warnings about deprecated `withOpacity` are unrelated and stay).

- [ ] **Step 4: Commit**

```bash
cd ~/Downloads/taler_id_mobile && git add lib/features/assistant/presentation/screens/assistant_screen.dart && git commit -m "$(cat <<'EOF'
feat(assistant): auto-connect voice session on desktop entry

Tapping Assistant in the desktop Activity bar now starts the voice session
without an intermediate "tap to start" gesture. Mobile retains the manual
gesture because the wheel is still the assistant home screen there.

The wake-word branch is preserved and takes precedence — it's checked first
so the autoConnect static flag still consumes itself before the desktop
branch falls through.

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>
EOF
)"
```

---

## Task 3: Desktop idle = minimal restart screen (no wheel)

**Files:**
- Modify: `lib/features/assistant/presentation/screens/assistant_screen.dart`

- [ ] **Step 1: Add an early-return desktop branch at the top of `_buildIdle`**

Find `_buildIdle` (around line 2488). The first lines compute `colors`, `screenSize`, `shortSide`, `orbitRadius`. Insert the desktop branch right after `final colors = AppColors.of(context);` and before the screen-size math:

```dart
  Widget _buildIdle(AppLocalizations l10n) {
    final colors = AppColors.of(context);
    if (PlatformUtils.instance.isDesktop) {
      return _buildIdleDesktop(l10n, colors);
    }
    final screenSize = MediaQuery.of(context).size;
    final shortSide = screenSize.width < screenSize.height ? screenSize.width : screenSize.height;
    final orbitRadius = (shortSide * 0.30).clamp(100.0, 220.0);
    ...
```

(The `...` is the existing rest of the method — do not delete it.)

- [ ] **Step 2: Add the `_buildIdleDesktop` method**

Add it immediately after `_buildIdle` closes (before `_buildNavCircle`). Reuses the same pulsing avatar pattern as the connected-state center widget:

```dart
  Widget _buildIdleDesktop(AppLocalizations l10n, AppColorsExtension colors) {
    return Center(
      child: GestureDetector(
        onTap: _connect,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ScaleTransition(
              scale: _pulseAnim,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colors.card,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.25),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: colors.primary.withValues(alpha: 0.4),
                      blurRadius: 40,
                      spreadRadius: 4,
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.4),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: _logoVideoReady && _logoVideo != null
                      ? FittedBox(
                          fit: BoxFit.cover,
                          child: SizedBox(
                            width: _logoVideo!.value.size.width,
                            height: _logoVideo!.value.size.height,
                            child: VideoPlayer(_logoVideo!),
                          ),
                        )
                      : Container(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.black
                              : Colors.white,
                          padding: const EdgeInsets.all(12),
                          child: Image.asset(
                            Theme.of(context).brightness == Brightness.dark
                                ? 'assets/app_icon_dark.png'
                                : 'assets/app_icon_light.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              l10n.assistantTapToStart,
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
```

The avatar uses `_pulseAnim` (declared at the top of `_AssistantScreenState` and animated continuously in `initState`). No new controllers needed.

- [ ] **Step 3: Run analyzer**

```bash
cd ~/Downloads/taler_id_mobile && dart analyze lib/features/assistant/presentation/screens/assistant_screen.dart
```

Expected: no new errors. The pre-existing pulse animation controller and video logo state are already in scope.

- [ ] **Step 4: Commit**

```bash
cd ~/Downloads/taler_id_mobile && git add lib/features/assistant/presentation/screens/assistant_screen.dart && git commit -m "$(cat <<'EOF'
feat(assistant): desktop idle is a minimal restart screen instead of the wheel

Replaces the 7-circle orbital wheel with a single centred pulsing avatar +
"Tap to start" label on desktop. The wheel still renders on mobile (gated
by PlatformUtils.instance.isDesktop). Nav circles' destinations now live in
the Activity bar; the wheel's drag/fling code stays for the connected-state
wave painter that shares the orbit animation controller.

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>
EOF
)"
```

---

## Task 4: Manual smoke test on macOS

- [ ] **Step 1: Stop any running flutter run**

```bash
pkill -f "flutter_tools.snapshot run" 2>/dev/null; pkill -f "taler_id_mobile.app" 2>/dev/null
```

- [ ] **Step 2: Launch the app**

```bash
cd ~/Downloads/taler_id_mobile && flutter run -d macos --dart-define=FLAVOR=dev --dart-define=BASE_URL=https://staging.id.taler.tirol
```

- [ ] **Step 3: Verify each scenario**

| Scenario | Expected |
|---|---|
| Cold start → log in → click `Assistant` in Activity bar | Voice session begins immediately, no wheel visible |
| Click `End Call` button | Returns to idle: centered avatar + "Tap to start", no orbital ring |
| Tap the centered avatar | New voice session starts |
| Click each of Notes / Contacts / Profile in the Activity bar | Correct route opens, icons highlight when active |
| Click `Assistant` again | Voice session starts again |
| Hot restart (press `R`) | Same behaviour, no console errors |

- [ ] **Step 4: Sanity-check mobile flow is untouched (skip if no iOS available)**

If an iPhone is plugged in, run the dev flavor on iOS and confirm the idle wheel still appears:

```bash
flutter run --flavor dev -t lib/main_dev.dart --dart-define=FLAVOR=dev --dart-define=BASE_URL=https://staging.id.taler.tirol -d 00008101-000E21100202001E
```

Otherwise skip this step and note it in the final report.

- [ ] **Step 5: Stop flutter and report**

Press `q` in the flutter terminal. Summarise the manual results to the user.

---

## Self-Review Summary

- **Spec coverage:**
  - Auto-connect on desktop entry → Task 2 ✅
  - Minimal restart screen replacing the wheel → Task 3 ✅
  - Activity bar expanded with 3 new icons → Task 1 ✅
  - Mobile flow preserved (isDesktop gate) → Task 2 & Task 3 ✅
  - L10n string `assistantTapToStart` → already exists in en + ru ARB (verified before plan-writing); no l10n changes required
  - Connected state controls untouched → not modified by any task ✅
- **Placeholders:** none — every code block is concrete.
- **Type consistency:** `_pulseAnim`, `_logoVideo`, `_logoVideoReady`, `colors`, `_connect`, `PlatformUtils.instance.isDesktop`, `RouteConstants.notes/contacts/profile` are all real existing identifiers verified in code or in `lib/core/utils/constants.dart`.

# Assistant Screen Redesign — macOS Desktop

**Status:** design approved 2026-05-20
**Branch:** `feature/agent-shell-phase-0`
**Scope:** desktop-only (mobile flow untouched)

## Problem

On macOS desktop the `/assistant` route opens to an "orbital wheel" idle state — a central pulsing avatar with 7 `_NavCircle` widgets arranged on a draggable circular arc (Messenger, Calls, Calendar, Notes, Contacts, Profile, Settings). The wheel was ported verbatim from the mobile screen.

Two things are wrong with this on desktop:

1. **Redundant navigation.** The desktop already has an Activity bar on the left side of the window that already exposes 5 of those 7 destinations (Messenger, Calls, Assistant, Calendar, Settings). The wheel duplicates them and adds 3 more (Notes, Contacts, Profile) that exist nowhere else in the left rail.
2. **Friction to start a session.** On mobile the wheel is the home screen — you tap the central avatar to begin voice mode. On desktop the user has already chosen the assistant tab; making them tap an avatar inside the screen is one click too many.

## Goals

- Tapping the `Assistant` icon in the Activity bar begins a voice session immediately.
- Notes / Contacts / Profile become first-class destinations in the Activity bar, so the wheel's nav role is fully absorbed.
- Mobile behaviour is preserved unchanged.

## Non-goals

- No change to the connected-state controls (Speaker · End Call · Mute) — they stay as the bottom row.
- No change to the orbit drag/fling code itself — `_orbitCtrl`, `_orbitAngle`, `_orbitVelocity` continue to drive the wave painter in connected state. We only stop rendering the `_NavCircle` ring around the avatar.
- No change to the mobile assistant screen, the wake-word flow, or the translator mode.

## Design

### Behaviour

**Enter `/assistant` route on desktop:**
- `AssistantScreen.initState` checks `PlatformUtils.instance.isDesktop`.
- If true, schedule `_connect()` on the next frame (after `super.initState()`), bypassing idle.
- The existing `autoConnect` static flag (used by wake-word triggers) keeps working as-is for both platforms.

**End Call on desktop:**
- `_endCall()` returns to idle state (same as today).
- Idle state on desktop renders the **minimal restart screen** described below — not the wheel.

**Switching tabs (Activity bar) while a session is active:**
- Out of scope for this redesign. Current behaviour preserved: navigating away cleans up the session via existing `dispose` paths.

### Minimal restart screen (desktop idle)

When `_buildIdle()` runs on desktop, render:

```
                ┌─────────────┐
                │             │
                │   pulsing   │   ← same _AssistantWavePainter + video logo
                │   avatar    │     as the connected-state center widget
                │             │
                └─────────────┘
                  Tap to start
```

- Centered in the assistant pane.
- Tap on the avatar → `_connect()`.
- No nav circles, no orbit arc, no drag handler bound here.
- Label uses an existing l10n string if one fits, otherwise add `assistantTapToStart` (ru: «Нажмите чтобы начать», en: «Tap to start»).

On mobile, `_buildIdle()` keeps rendering the current wheel — gated by the same `isDesktop` branch.

### Activity bar expansion

Today's `ActivityBar` builds 5 items. New list (insertion points shown):

```
Messenger
Calls
Assistant
Calendar
Notes      ← new
Contacts   ← new
Profile    ← new
Settings
```

Icons reused from the existing `_NavCircle` constants in `assistant_screen.dart`:
- Notes → `Icons.sticky_note_2_outlined`, route `RouteConstants.notes`
- Contacts → `Icons.people_outline`, route `RouteConstants.contacts`
- Profile → `Icons.person_outline`, route `RouteConstants.profile`

Tooltips: `Notes`, `Contacts`, `Profile` (English — matches the existing tooltip style; localization can come later if needed).

Vertical fit: at `DesktopDensity.activityBarWidth` (~52 px) each icon takes ~52 px tall. 8 × 52 = 416 px, comfortably inside any reasonable window height. No scroll behaviour needed.

### Dead code removed

The `_NavCircle` widget class and the `navCircles` list inside `_buildIdle` are referenced from:
- Desktop idle (this redesign removes their use here)
- Mobile idle (still uses them)

Therefore the class stays. We delete only the desktop branch's circle list construction and the orbital `Stack` / `IgnorePointer` that draws them.

## Files touched

| File | Change |
|---|---|
| `lib/features/assistant/presentation/screens/assistant_screen.dart` | `initState` auto-connect branch for desktop; `_buildIdle` desktop variant |
| `lib/features/dashboard/desktop/widgets/activity_bar.dart` | Add 3 items between Calendar and Settings |
| `lib/l10n/app_localizations_ru.arb`, `lib/l10n/app_localizations_en.arb` | Add `assistantTapToStart` if no suitable string exists |

## Risks / open points

- **Auto-connect billing:** `_connect()` opens a billing session immediately. A user who clicks `Assistant` accidentally pays for one micro-charge of "session started". The existing `_billing.start()` already 402s if insufficient funds, so no runaway risk. Acceptable.
- **Microphone TCC popup on first launch:** unchanged behaviour. Already covered by the onboarding screen.
- **Wake-word re-entry:** `WakeWordService.instance.pause()` is called inside `_connect()`, so the wake-word flow still works.

## Test strategy

Manual on macOS:
1. Tap `Assistant` from cold start → voice session begins, no wheel visible.
2. End call → minimal restart screen, tap avatar → session restarts.
3. Tap each new Activity bar item (Notes, Contacts, Profile) → correct route loads.
4. Switch to mobile (iOS simulator or device) → idle still shows the wheel, no regressions.

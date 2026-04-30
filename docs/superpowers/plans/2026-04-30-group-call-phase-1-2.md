# Group Call Phase 1.2 — Reliability Hotfix

**Status:** planned
**Created:** 2026-04-30
**Successor of:** [Phase 1 plan](2026-04-29-group-voice-room.md), [Phase 1.1 hotfixes (already merged)](#)

## Why this exists

Phase 1 shipped the foundation; Phase 1.1 (merged 2026-04-30) closed three
critical defects that surfaced during the first real-device smoke (host couldn't
reach LiveKit, foreground app didn't ring, ErrorState left the screen on a
spinner). Five more defects surfaced in the same smoke session that we did not
have time to fix in-line. They all manifest only after the happy-path is
already working, so they were invisible until the basic flow itself was fixed.

This plan documents what they are, why they happen, and the ordered work to
close them. Each task is independently mergeable.

## Current shape of the system after Phase 1.1

- Host: picker → POST /voice/group-calls → InLobby → invitee JOIN → InActive →
  /group-call/:id → `room.connect` ✅ (verified in iPhone logs).
- Foregrounded invitee: `gcInviteStream` → `showCallkitIncoming` ✅ (verified).
- Backgrounded invitee on iPhone (VoIP push) + on Android with fresh FCM token:
  works.
- Active screen `_stateSub` listener re-runs `_connectIfNeeded` on every BLoC
  emission, so the invitee path no longer races itself.
- ErrorState in active screen → snackbar + back to `/dashboard/call-history`.

## Defects targeted by Phase 1.2

### 1. Stale FCM token blocks Android invitee notification

**Symptom:** Inviting a user whose Android device hasn't logged in recently
silently drops the invite. Backend logs:
`FCM sendGroupCallInvite error for {userId}: NotRegistered`. Socket.io is the
only fallback, but it only delivers if the invitee's app is open.

**Root cause:** Stale FCM tokens are not pruned. On the next login, the device
should re-register, but if the user never logs in again the row stays poisoned
and every subsequent invite fails.

**Fix:**
- `FcmService.sendGroupCallInvite` already returns the SDK error. When it sees
  `NotRegistered` or `InvalidRegistration`, **delete the FcmToken row** so the
  next login's `PUT /profile` re-registration writes a clean token.
- Mirror the same pattern in 1-on-1 `sendCallInvite` for parity.
- Mobile-side: on every successful login + on `onTokenRefresh`, force a
  `PUT /profile` even when the cached token matches — server-side delete of a
  stale row would otherwise leave the device thinking it's already registered.

**Files:**
- `src/messenger/fcm.service.ts` — error-branch token cleanup.
- `lib/core/notifications/notification_service.dart` — drop the
  "skip if token unchanged" optimisation in the login path.

**Acceptance:** Invite a previously-stale user; backend log shows clean
`FCM sendGroupCallInvite OK` after the user opens the app once and re-logs.

---

### 2. CallKit accept on Android emulator never auto-navigates

**Symptom:** Invitee accepts CallKit on an emulator → app stays on whatever
screen it was on (or the home wheel). User has to tap the active-call banner
in Calls history to enter the room.

**Root cause:** `_navigateWhenResumed` (lib/main.dart) polls
`WidgetsBinding.instance.lifecycleState` every 300 ms and only pushes the
route once `lifecycle == AppLifecycleState.resumed`. On Android emulators
the lifecycle sometimes oscillates `paused ↔ inactive` after CallKit's UI
overlays the app, never reaching `resumed`. The poll exhausts its 100-attempt
budget silently.

**Fix:**
- After 30 attempts (10 s) of polling without a resumed signal, fall through
  and push the route anyway. Worst case, we push while the app is paused; the
  router will queue the navigation for the next frame, which is what the user
  wants.
- Add a debug log on every 10th attempt so future flake is easier to diagnose.

**Files:**
- `lib/main.dart` — `_navigateWhenResumed` deadline + log.

**Acceptance:** Accept CallKit on Pixel emulator → active screen appears
within 11 s without manual navigation.

---

### 3. Cold start lands on a stale `/group-call/:id` route

**Symptom:** Killing and reopening the app sometimes drops the user straight
onto the active screen for a call that already TIMEOUT'd. JoinCall returns
410, BLoC emits ErrorState, the active screen now (Phase 1.1) navigates back
to call history — so the bug is masked but the user sees a flicker
(spinner → back to home).

**Root cause:** GoRouter restores the last URL on cold start. There's no guard
against entering the active screen for a call that the local cache cannot
verify still exists.

**Fix:** In `GroupCallActiveScreen.initState`, before dispatching `JoinCall`,
issue a lightweight `GET /voice/group-calls/active` and check whether
`widget.callId` appears in the active list. If not, immediately navigate to
`/dashboard/call-history` without ever showing the spinner.

This duplicates a small amount of logic that JoinCall would do, but it avoids
the spinner→snackbar→back round-trip on cold start, which is the worst UX
moment.

**Files:**
- `lib/features/voice/presentation/screens/group_call_active_screen.dart`
  — pre-flight active check before JoinCall.

**Acceptance:** Cold-start the app while the only group call has already
timed out → land on `/dashboard/call-history` directly, no spinner flicker.

---

### 4. Empty active screen when manually navigating from Calls history

**Symptom:** User taps an in-progress call from Calls history while it is
still active for the host but not yet joined for them. Active screen shows
the bottom action row (mic / leave) but the participant grid is empty.

**Root cause:** `_ActiveView` reads `state.groupCall.invites` directly. For
an invitee whose JoinCall has not yet returned, the BLoC is still in `Idle`
and the builder falls through to the spinner. After JoinCall returns,
`getCall` is fetched server-side — but the response goes through the BLoC
emit, which is throttled by the build cycle. There's a one-frame window
where the screen is `_$InActiveImpl` with `invites: []`, because the BLoC's
`_onJoin` first emits with the freshly-joined invite, before the second
`_onStatusUpdated` arrives with the host + other invitees populated.

**Fix:** When `getCall` returns in `_onJoin`, the invite list is already
correct — no second emit needed. The race is in `_onStatusUpdated` happening
to fire between JoinCall's two awaits and clobbering the InActive payload.
Make `_onStatusUpdated` a no-op while a JoinCall is in flight (track via a
private `_joinInProgress` flag).

**Files:**
- `lib/features/voice/presentation/bloc/group_call_bloc.dart` — guard
  `_onStatusUpdated` while `_joinInProgress`.

**Acceptance:** From Calls history, tap an active group call I'm invited to
→ active screen renders with at least the host's tile within 1 s.

---

### 5. Defensive: Active-screen action Row may hit the same infinite-width
   layout bug we fixed in Lobby

**Symptom:** Not yet observed, but the same `Row(mainAxisAlignment: ..., children: [..., ElevatedButton.icon])`
pattern from the Lobby (which crashed with `BoxConstraints forces an infinite
width`) is present in `_ActiveView` at `group_call_active_screen.dart:337-367`.
With three children (IconButton, IconButton, ElevatedButton.icon) and
`spaceEvenly` it would normally distribute width via flex slots — but
`spaceEvenly` does not impose a `Flexible` wrapper; sufficiently narrow
screens or non-text labels could still trigger the same crash.

**Fix:** Wrap the `ElevatedButton.icon` in `Flexible` and add `mainAxisSize:
MainAxisSize.min` to the surrounding Row. This is purely defensive — costs a
two-line change and removes a class of risk we already paid for once.

**Files:**
- `lib/features/voice/presentation/screens/group_call_active_screen.dart`
  — Flexible wrap + MainAxisSize.min.

**Acceptance:** Hot-reload in narrow simulator (e.g. iPhone SE) — no layout
assertion in the active screen.

---

## Out of scope

- New CallKit native features (decline, mute on lock screen).
- Push notification dedup across iOS APNs + FCM (Phase 1 already handles this
  on the receiver via `roomName.startsWith('group-')`).
- Phase 2 breakouts (separate plan).

## Order of work

1. Defect 5 (defensive layout fix) — 5 min, can ship in any commit.
2. Defect 3 (cold-start guard) — 30 min, isolated to one screen.
3. Defect 4 (BLoC race) — 45 min, requires careful event ordering analysis.
4. Defect 2 (CallKit auto-nav fallback) — 15 min.
5. Defect 1 (stale FCM cleanup) — 1 h, touches backend + mobile.

## Verification plan

After all five defects:

- Real-device smoke from CLAUDE.md group-call section.
- Re-run `npm run test` from `~/Downloads/taler_id_tests` (existing 20-check
  smoke for group calls — should still pass).
- Manual: invite a user whose token is known stale. After they re-login,
  invite them again. Backend log should show `FCM ... OK` on the second
  attempt.
- Manual: cold-start the app while no call is active → land on home, not
  on a stale group-call route.

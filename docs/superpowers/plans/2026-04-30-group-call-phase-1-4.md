# Group Call Phase 1.4 — End-User Polish Backlog

**Status:** planned (not started)
**Created:** 2026-04-30, end of an 8-hour live-debug session.
**Predecessors:** Phase 1.0 (foundation), 1.1 (host LK connect, foreground
CallKit, ErrorState handler), 1.2 (FCM cleanup, cold-start guard, BLoC race,
CallKit nav fallback, defensive Flexible), 1.3 (UUID-in-room fix backend +
orphaned CallKit group route + host tile in active grid).

## What's been shipped to DEV

The system handles the happy path (host creates → invitee joins → both speak)
when both devices are foregrounded with fresh sessions and the call is
accepted within ~30 s. Names render. Host enters LiveKit. Foreground app
rings.

## Defects observed in 2026-04-30 smoke that remain

These need a methodical reproduction harness rather than live whack-a-mole.

### 1. Host's tile / avatar disappears mid-call

**Observation:** Host's UI element (likely the host star badge on a participant
tile, or the host count in the appbar) flickers off after ~5 s. Unclear
whether it's the host's own self-tile, the invitee's tile from host's view,
or a header element.

**Hypothesis:** A `_onStatusUpdated` event arrives with a partial invite list
(e.g. only `{userId, status}`, no `user.profile`), and `_parseInvite` falls
back to userId — so the displayName shifts. With the joined invitee leaving
the grid filter on a status transition, the tile literally vanishes.

**Diagnosis steps:**
- Add a debug print to `_parseInvite` showing every parsed invite's
  `userId`, `status`, and whether `user.profile` is present.
- Reproduce on host with a single invitee and watch which `StatusUpdated`
  payload triggers the tile change.

### 2. Host's own tile not shown anywhere on active screen

The current grid omits the host when viewer == host. This was intentional
("don't show me my own face") but in a 1-on-1 group call (host + 1 invitee)
the host sees only the invitee tile, with no self-indicator. Consider adding
a small self badge or a "you" tile so the host knows their own state
(muted/unmuted, active speaker).

### 3. Stale active route → spinner trap

**Observation:** When the iPhone app is killed mid-call and reopened,
GoRouter restores the last `/group-call/:id` route. Cold-start guard from
Phase 1.2 #3 *should* navigate back if the call isn't active — but in
practice the user lands on a perpetual spinner with no escape except
swipe-to-kill.

**Hypothesis:** The pre-flight `getActiveCallsForMe()` is failing silently
(network blip, 401 on stale token), the `try/catch` swallows the error,
and the JoinCall path runs anyway → 410 → ErrorState → my Phase 1.1
ErrorState handler navigates back, but only if the screen is mounted in
a way that runs the listener. If the BlocConsumer is being torn down or
the listener fires before the navigator is ready, the navigation no-ops.

**Diagnosis steps:**
- Add a debug print at every branch in the cold-start guard.
- Add a fallback timer: if the active screen has been mounted for 20 s
  with `_room == null` and BLoC state isn't InActive, force-navigate to
  call-history.

### 4. iPhone Xcode debug session times out

**Observation:** `flutter run -d <iPhone>` hits `Error: Did not find a Dart
VM Service advertised for tirol.taler.talerIdMobile.dev.` after 60+ s.
Build itself succeeds; install runs; debugger never attaches.

**Likely cause:** Xcode 26 / iOS 26.4 flake. Not our code. Workaround:
re-run `flutter run`, sometimes opening Xcode and pressing Run helps,
sometimes a full Xcode restart is needed.

**Action:** No code change. Document the workaround in CLAUDE.md.

### 5. Call to Android device sometimes doesn't ring

**Observation:** Inviting a user whose Android device should ring → no
ring on device, even though the device is unlocked and the app is in the
background.

**Hypothesis:**
- (a) FCM token *is* registered but FCM delivery is throttled or filtered
  by device OEM (Xiaomi has aggressive battery management).
- (b) FCM token is stale and the cleanup-then-re-register cycle from
  Phase 1.2 #1 hasn't kicked in yet (one round of "send fails → token
  cleared → user opens app → re-register" is needed before the next
  invite works).

**Diagnosis steps:**
- Check backend logs for `FCM sendGroupCallInvite OK` vs cleanup errors
  for the target user during the failed invite.
- If FCM succeeded but the device didn't ring, the issue is OEM background
  filtering — need to instruct user to whitelist the app, or fall back to
  a high-priority data-only push that won't be filtered.

### 6. Audio doesn't transmit after iPhone joins

**Observation:** iPhone joins the active screen, sees host tile, but no
audio passes between participants.

**Hypothesis:** `setMicrophoneEnabled(true)` is called immediately after
`room.connect`. On iOS, this may race with CallKit's audio session: CallKit
deactivates the session on accept, LiveKit re-activates it, mic enable
fires before the session is fully active → silently no-op.

**Diagnosis steps:**
- Add a 200-500 ms delay between `room.connect` and
  `setMicrophoneEnabled`.
- Or hook into `RoomEventConnected` and enable the mic from there.
- Capture LiveKit's verbose logs (`lk.setLogLevel(lk.LogLevel.verbose)`)
  during a failing reproduction.

### 7. CallKit accept after >30 s lands in stuck 1-on-1 voice screen

**Observation:** Phase 1.3 already discriminates `group-` prefix in
`_checkActiveCallKitCalls`. But the case where CallKit was accepted *after*
the server-side ringing timeout fired still ends up confusing the UI: the
group call is ENDED, the orphan handler tries to route to the group active
screen, ActiveScreen mounts in Idle, JoinCall returns 410, ErrorState
handler navigates back. So the user sees the brief flicker.

**Polish:** The orphan handler could pre-flight check `getActiveCallsForMe`
the same way the active-screen cold-start guard does, and silently dismiss
the CallKit + skip navigation when the call is gone.

## Plan for Phase 1.4

Don't reactive-fix in a live device session. Instead:

1. **Build a reproduction harness** (~2 h):
   - Two-emulator script that creates a call via REST, has device A accept
     CallKit, expects audio + video tile within N seconds, asserts.
   - Run it in CI eventually, but for now run locally to hit defects
     deterministically.

2. **Methodically trace** each defect (1, 2, 3, 5, 6, 7) with the harness.
   Add the diagnostic prints listed above. Capture exact failing payload /
   timing.

3. **Fix in priority order**:
   - 6 (audio not passing) → blocks all real use.
   - 1, 3 (UI flicker / spinner trap) → frequently hit.
   - 5 (FCM delivery) → real users will hit on first invite.
   - 7 (post-timeout CallKit polish) → lower frequency.
   - 2 (no self-tile) → ergonomic, ship later.
   - 4 (Xcode flake) → not code, document only.

4. **Verify** with the harness before claiming done. No reactive smoke.

5. **Then PROD deploy** (only after harness is green).

## Things NOT to do

- Don't keep adding instrumentation prints during live debugging — they
  pile up and obscure new logs. Remove the Phase 1.1 / 1.2 debug prints
  before PROD.
- Don't deploy to PROD with any defect 1, 3, 5, or 6 unresolved.
- Don't expand Phase 2 (breakouts) until Phase 1.4 is green.

## Out of scope

- Phase 2 breakouts.
- Video.
- Screenshare.
- Desktop client parity.

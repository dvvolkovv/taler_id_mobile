# Phase 3d.1 — Mesh Voice Call: Core UI Integration

**Status:** Brainstormed 2026-04-29; ready for writing-plans.

**Parent design:** [`2026-04-29-mesh-voice-call-phase3-design.md`](2026-04-29-mesh-voice-call-phase3-design.md) — covers Phase 3 in full (audio engine, datagram channel, signaling, UI integration). Phase 3d in that doc decomposes into 3d.1 (this spec) + 3d.2 (chat integration + polish).

## Goal

Make mesh voice calls work end-to-end through the app UI: a user can start a call (via a debug-only entry point in this phase), the callee sees an incoming modal sheet, both sides see an active call screen with timer / mute / hangup, and a history entry is written to a local Hive box on call end. After this phase, the mesh-call audio path can be hardware-tested in a real UI flow without any chat-screen or call-history-screen integration.

## Non-Goals (Phase 3d.1)

Out of scope, deferred to Phase 3d.2:
- Chat-header mesh-call button (auto-pick on tap, popup on long-press)
- Chat-header eligibility dot
- Existing `CallHistoryScreen` merging server entries with local mesh entries
- Android background full-screen Notification (foreground-only in 3d.1)
- iOS onboarding tooltip about background-suspend limit
- Toast on attempting mesh call while a LiveKit call is active

Out of scope for all of Phase 3 (per parent design):
- CallKit / Telecom integration (lock-screen UI, OS recents)
- Group mesh calls
- Speakerphone / Bluetooth route switching in `MeshVoiceCallScreen`

## Architecture

```
┌──────────────────────────────────────────────────┐
│  MeshVoiceCallScreen      MeshIncomingCallSheet  │   UI
└──────────┬─────────────────────────┬─────────────┘
           │                         │
           ▼                         ▼
┌──────────────────────────────────────────────────┐
│       MeshVoiceUiCoordinator (singleton)         │   navigation +
│  listens to MeshVoiceService.stateStream          │   sheet control +
│  routes via NavigationService.navigatorKey        │   history write
└──────────┬───────────────────────────┬───────────┘
           │                           │
           ▼                           ▼
┌─────────────────────┐  ┌──────────────────────────┐
│  MeshVoiceService   │  │ MeshCallHistoryRepository │
│  (Phase 3c, ready)  │  │ Hive: mesh_call_history   │
└─────────────────────┘  └──────────────────────────┘
```

**Key principle:** the Coordinator owns all UI control flow. `MeshVoiceCallScreen` and `MeshIncomingCallSheet` are stateless with respect to the call state machine — they read `CallState` from a stream and render. This keeps the screens testable as pure widgets and concentrates Flutter coupling in one file.

`MeshVoiceService` (built in Phase 3c) stays Flutter-free and is reused as-is.

## Components

### 1. `MeshCallHistoryEntry` + `MeshCallHistoryRepository`

**Files:**
- `lib/features/call_history/data/mesh_call_history_entry.dart` (~80 lines)
- `lib/features/call_history/data/mesh_call_history_repository.dart` (~140 lines)

**Hive box:** `mesh_call_history`, opened in `setupDependencies()` next to existing `mesh_messages`.

**Model fields:**
```dart
class MeshCallHistoryEntry {
  final int callId;
  final String peerDevicePkBase64;   // 32-byte X25519 pk → base64 (Hive key)
  final String? peerUserId;          // null if peer is not in contacts
  final String? peerName;            // snapshot of name at call time
  final bool isOutgoing;
  final DateTime startedAt;          // moment of invite (caller) / receive (callee)
  final DateTime? activatedAt;       // moment of ACTIVE; null if call never connected
  final DateTime endedAt;
  final int? durationSec;            // null if never ACTIVE
  final String endReason;            // EndReason.name from CallState
  final String? transport;           // 'bonjour' | 'ble' snapshot from transport.peerStatus
}
```

**Repository API:**
```dart
abstract class MeshCallHistoryRepository {
  Future<void> add(MeshCallHistoryEntry entry);
  Future<List<MeshCallHistoryEntry>> getAll();    // sorted by startedAt desc
  Future<void> deleteById(int callId);
  Stream<List<MeshCallHistoryEntry>> watch();      // for 3d.2 CallHistoryScreen merge
}

class HiveMeshCallHistoryRepository implements MeshCallHistoryRepository { ... }
```

The Hive type adapter is hand-written (subclass of `TypeAdapter<MeshCallHistoryEntry>`) rather than generated to avoid `build_runner` conflicts with existing generators in this repo.

### 2. `MeshVoiceUiCoordinator`

**File:** `lib/core/voice/mesh_voice_ui_coordinator.dart` (~250 lines)

**Dependencies (constructor-injected):**
- `MeshVoiceService` (Phase 3c)
- `MeshCallHistoryRepository`
- `NavigationService` (existing, used by `notification_service.dart`)
- `ContactKeyStore` (existing mesh repo for `devicePk → userId` lookup)
- `MessengerBloc` (read-only state access for `userId → name/avatar` lookup)

**Public API:**
```dart
class MeshVoiceUiCoordinator {
  void start();                              // subscribe to stateStream; called from main.dart after runApp
  Future<void> placeCall(PeerId peer);       // helper for UI buttons; performs self-loopback guard, then service.invite
  Future<void> dispose();
}
```

**Internal state:** a single `_pending` record holding `(callId, peer, peerName, peerAvatarUrl, peerUserId, isOutgoing, startedAt, activatedAt, transport)`. Reset to null after history write on `EndedState`.

**Side-effects per state transition:**

| `CallState`        | UI side-effect                                                                                                      | Hive write                              |
| ------------------ | ------------------------------------------------------------------------------------------------------------------- | --------------------------------------- |
| `IdleState`        | (no-op — initial state)                                                                                             | —                                       |
| `InvitingState`    | Lookup peer info; `_pending = (callId, ..., isOutgoing: true, startedAt: now)`. `Navigator.push(MeshVoiceCallScreen)`. | —                                       |
| `IncomingState`    | Lookup peer info; `_pending = (..., isOutgoing: false, startedAt: now)`. `showModalBottomSheet(MeshIncomingCallSheet, isDismissible: false)`. | —                                       |
| `ConnectingState`  | (no-op in 3d.1 — reserved by Phase 3c.1)                                                                            | —                                       |
| `ActiveState`      | If sheet is open: `Navigator.pop(sheet)`, then `Navigator.push(MeshVoiceCallScreen)`. If screen already pushed (caller path): no nav action — screen handles UI transition via its own stream subscription. `_pending.activatedAt = now`. | —                                       |
| `EndedState`       | Pop sheet (if open). Screen displays an "ended" overlay for ~1.5 s and pops itself.                                  | Write `MeshCallHistoryEntry` from `_pending` (`endedAt: now`, `endReason: state.reason.name`, `durationSec` computed if `activatedAt != null`). Then `_pending = null`. |

**Peer info lookup** (synchronous, in-memory only):
1. `ContactKeyStore.userIdForDevicePk(peer)` → `String? userId`.
2. If `userId != null`: scan `MessengerBloc.state.conversations` for a `DIRECT` conv with `otherUserId == userId`; pull `name` and `avatarUrl`.
3. If lookup fails at either step, store `peerName = null` — UI falls back to `Mesh-устройство ${devicePkHex.substring(0, 8)}`.

**Navigator handling:** uses `NavigationService.navigatorKey.currentContext`. If null on first event (rare — boot before first frame), the first event is deferred via `WidgetsBinding.instance.addPostFrameCallback` until a context is available. Subsequent events run immediately.

### 3. `MeshVoiceCallScreen`

**File:** `lib/features/voice/presentation/screens/mesh_voice_call_screen.dart` (~600 lines)

This screen is **separate from** `voice_call_screen.dart` (5280 lines, LiveKit-coupled). No LiveKit, CallKit, recording, E2EE, or AI-twin code paths. Reuses `lib/features/voice/presentation/widgets/pulsing_avatar.dart`.

**Constructor:**
```dart
MeshVoiceCallScreen({
  required Stream<CallState> stateStream,
  required PeerId peer,
  required String? peerName,
  required String? peerAvatarUrl,
  required String? transportName,    // 'Bonjour' | 'BLE' | null — Coordinator passes
                                     // snapshot of transport.peerStatus(peer) at push time
  required Future<void> Function() onMuteToggle,
  required Future<void> Function() onHangup,
});
```

**UI sections:**
- Pulsing avatar (top-center)
- Name line: `peerName` or fallback `Mesh-устройство ${peer hex prefix}`
- Status line: switches based on `CallState`:
  - `InvitingState` → "Вызов…"
  - `IncomingState` → not rendered (sheet handles this)
  - `ActiveState` → live timer `m:ss` updating every second
  - `EndedState` → reason-specific text:
    - `userHangup` → "Звонок завершён"
    - `remoteHangup` → "Завершён собеседником"
    - `rejectedByCallee` → "Отклонён"
    - `inviteTimeout` → "Не отвечает"
    - `noKeepalive` / `peerLost` → "Соединение потеряно"
    - `error` → "Ошибка соединения"
- Transport badge: `📡 Mesh · Bonjour` / `📡 Mesh · BLE` / `📡 Mesh` (when `transportName == null`) — passed in by Coordinator via constructor
- Mute toggle button (microphone icon, local `isMuted` state, calls `onMuteToggle`)
- Hangup button (red, calls `onHangup`)

**Transitions out:** on `EndedState`, screen waits 1.5 s then `Navigator.pop()`. If user taps hangup before `EndedState` arrives, hangup callback fires; the resulting `EndedState` from the service drives the same pop logic.

### 4. `MeshIncomingCallSheet`

**File:** `lib/features/voice/presentation/widgets/mesh_incoming_call_sheet.dart` (~180 lines)

**Constructor:**
```dart
MeshIncomingCallSheet({
  required PeerId peer,
  required String? peerName,
  required String? peerAvatarUrl,
  required VoidCallback onAccept,
  required VoidCallback onDecline,
});
```

**UI:** centered avatar; name (or fallback); subtitle "📡 Входящий mesh-звонок"; two action buttons (green Accept, red Decline). A 30 s self-timer renders as a thin progress arc around the Decline button; on expiry calls `onDecline`.

**Isolation:** the sheet does not import `MeshVoiceService` — it only invokes the supplied callbacks. Coordinator wires the callbacks to `service.accept()` and `service.reject()`.

## Boot sequence

```dart
// in lib/main.dart, after runApp:
await sl<MeshMessagingService>().start();   // already wired
sl<MeshVoiceService>().start();              // already wired in DI per Phase 3c contract
sl<MeshVoiceUiCoordinator>().start();        // NEW
```

`MeshVoiceService.start()` is owned by the DI bootstrap (per Phase 3c contract — service must be started exactly once before Coordinator subscribes). Coordinator only subscribes to `service.stateStream`; it does not call `service.start()`. The Hive box `mesh_call_history` opens in `setupDependencies()` alongside other Hive boxes.

The Hive type adapter for `MeshCallHistoryEntry` is hand-written and registered with a fresh `typeId` (next free value, currently `42` — verify against existing `Hive.registerAdapter` calls in `setupDependencies`).

## Debug placeCall trigger (this phase only)

`MeshDebugScreen` (existing since Phase 2.1) gains one extra button per discovered peer: **"Place mesh call"**, which calls `coordinator.placeCall(peer.devicePk)`. This is the **sole** entry point for placing a call in 3d.1 — Phase 3d.2 replaces it with a chat-header button and removes the debug button from production builds (or hides it behind `kDebugMode`).

## Edge cases

- **App killed during InvitingState (caller side):** `_pending` is lost; no history entry. Phase 3.1 may add persisted-pending if needed; for 3d.1 this is accepted.
- **App killed during ActiveState (either side):** same as above on the killed side. The remote side observes `noKeepalive` after 3 s and writes its own history entry with `endReason: noKeepalive`.
- **Foreground → background during ActiveState (Android):** existing mesh foreground-service (Phase 2.1) keeps datagram sockets alive; call continues. UI in 3d.1 is foreground-only (no notification), so the user sees timer resume on app return. 3d.2 adds a background notification with active-call status.
- **Foreground → background (iOS):** iOS suspends after ~30 s of background; datagrams stop flowing; service detects `noKeepalive` and emits `EndedState`. Coordinator writes history; on app return, the `MeshVoiceCallScreen` (still in the navigation stack) shows "Соединение потеряно" then pops. Documented limitation; 3d.2 surfaces this in an onboarding tooltip.
- **Double invite (race):** `MeshVoiceService.invite()` already throws `StateError` when not in `IdleState`. Coordinator's `placeCall` catches and shows a snackbar "Звонок уже идёт".
- **Loopback (peer == self):** Coordinator's `placeCall` checks `peer != messagingService.selfDevicePk` (already exposed by `MeshMessagingService`) before invoking the service. Loopback is silently ignored (no-op).

## Testing

**Unit — `MeshVoiceUiCoordinator`:** ~10 scenarios using a fake `MeshVoiceService` (a `StreamController<CallState>`), an in-memory fake `MeshCallHistoryRepository`, and a spy on `NavigationService`. Cover: caller happy path, callee accept happy path, callee decline, invite timeout, remote hangup mid-call, kill during invite (no history written), kill during active (history written with `noKeepalive`), loopback guard, double-invite snackbar, peer info lookup with name vs without name.

**Unit — `HiveMeshCallHistoryRepository`:** add / getAll (sorted desc) / deleteById / watch emits on add. Uses a temp Hive directory.

**Widget — `MeshVoiceCallScreen`:** render for each `CallState` (Inviting / Active / Ended-userHangup / Ended-noKeepalive / Ended-remoteHangup); mute tap fires callback; hangup tap fires callback; auto-pop 1.5 s after `EndedState`.

**Widget — `MeshIncomingCallSheet`:** render with name + avatar / without name / without avatar; Accept tap → onAccept; Decline tap → onDecline; 30 s auto-decline via `fakeAsync`.

**Integration — full flow:** two `MeshVoiceService` instances over an in-memory fake-transport pair (existing harness from Phase 3c tests) + two real Coordinators + two in-memory repositories. Drive: `coordinatorA.placeCall(bobPk)` → coordinatorB shows sheet → simulate accept → both reach `ActiveState` → audio frames flow for 100 ms simulated time → `coordinatorA.hangup()` → both write history entries (`userHangup` for A, `remoteHangup` for B) with matching `callId` and `durationSec` within 50 ms.

**Hardware smoke (manual, after merging):** Android (Redmi 78c0742f) + iPhone (00008150) on same WiFi. From Android `MeshDebugScreen` press "Place call" on the iPhone peer → iPhone shows incoming sheet → tap Accept → both see active screen with timer → talk for ≥ 10 s → hangup from either side → both `mesh_call_history` boxes have one matching entry. Repeat with reversed roles. iOS background-drop test: start call, lock iPhone for 35 s, expect Android to show "Соединение потеряно".

## Risks

**High:**
1. **`navigatorKey.currentContext` null on first event during boot.** Mitigation: defer first event via `addPostFrameCallback` until a context exists.
2. **iOS 30 s suspend drops calls mid-conversation.** Documented limitation; UI must show reason "Соединение потеряно" rather than silently disappear. Mitigation: reason-specific status text in `MeshVoiceCallScreen`.

**Medium:**
3. **Hive type adapter generation conflicts with existing build_runner output.** Mitigation: hand-write the adapter (`TypeAdapter<MeshCallHistoryEntry>` subclass) — Hive supports this fully.
4. **Synchronous lookup of `peerName` may return null** if `MessengerBloc.state.conversations` is not yet loaded when an inbound call arrives. Mitigation: best-effort lookup; UI fallback to `Mesh-устройство ${hex}`. History entry stores the snapshot — this is a feature, not a bug.

**Low:**
5. **Hive box corruption** from unclean shutdown during write. Mitigation: `box.put` is awaited before completing history write; on init, if open fails, delete the box and continue (history is non-critical data).

## Files to create

```
lib/core/voice/mesh_voice_ui_coordinator.dart                              ~250 lines
lib/features/call_history/data/mesh_call_history_entry.dart                ~80 lines
lib/features/call_history/data/mesh_call_history_repository.dart           ~140 lines
lib/features/voice/presentation/screens/mesh_voice_call_screen.dart        ~600 lines
lib/features/voice/presentation/widgets/mesh_incoming_call_sheet.dart      ~180 lines

test/core/voice/mesh_voice_ui_coordinator_test.dart                        ~250 lines
test/features/call_history/data/mesh_call_history_repository_test.dart     ~120 lines
test/features/voice/presentation/screens/mesh_voice_call_screen_test.dart  ~150 lines
test/features/voice/presentation/widgets/mesh_incoming_call_sheet_test.dart  ~100 lines
test/core/voice/mesh_voice_integration_test.dart                           ~200 lines
```

## Files to modify

```
lib/core/di/service_locator.dart                  +30 lines  (Coordinator + Repository registration; Hive box open)
lib/main.dart                                     +5 lines   (coordinator.start() after runApp)
lib/features/mesh/debug/mesh_debug_screen.dart    +40 lines  (per-peer "Place mesh call" button — debug-only)
```

**Files explicitly NOT touched:** `voice_call_screen.dart`, `chat_room_screen.dart`, `notification_service.dart`, `app_router.dart`, `messenger_bloc.dart`. The Coordinator pattern keeps mesh-call concerns out of these files.

## Success criteria

3d.1 is done when:

1. From two devices (Android + iPhone, same WiFi) on `feature/mesh-voice-call-phase3d.1`: I can tap "Place call" in `MeshDebugScreen` on one device, see the incoming sheet on the other, tap Accept, see `MeshVoiceCallScreen` with running timer, talk for ≥ 10 seconds, tap hangup on either side; both devices show "Звонок завершён" briefly, then return to the previous screen; both `mesh_call_history` Hive boxes contain a matching entry with non-null `durationSec ≥ 10`.
2. All Phase 3d.1 unit / widget / integration tests pass (~25 across the five test files listed).
3. No regressions in existing 486 tests on `dev`.
4. `flutter analyze` reports 0 errors.
5. iOS background drop produces "Соединение потеряно" text in the call screen, not silent failure.

## Vertical slice for Phase 3d.2

After 3d.1, `MeshVoiceCallScreen` and `MeshIncomingCallSheet` are stable. Phase 3d.2 then:

- Replaces the debug "Place call" button with a chat-header icon button + auto-pick / long-press popup.
- Adds the chat-header eligibility dot.
- Merges `mesh_call_history` Hive entries into existing `CallHistoryScreen`.
- Adds Android background full-screen Notification (the existing mesh foreground-service already has the channel; only payload + intent wiring is new).
- Adds iOS onboarding tooltip on first chat-header view.
- Adds toast "Завершите текущий звонок" when starting a mesh call while a LiveKit call is active.

## Rollout

1. Branch `feature/mesh-voice-call-phase3d.1` from `dev`.
2. Implement via subagent-driven-development: ~12-14 tasks across the 5 new files + 3 modifications.
3. Hardware smoke per Success criteria.
4. PR into `dev`. After merge, branch `feature/mesh-voice-call-phase3d.2` from `dev` for Phase 3d.2.

# Phase 3d.2 — Mesh Voice Call: Chat-Header Integration + History Merge + Polish

**Status:** Brainstormed 2026-04-30; ready for writing-plans.

**Parent design:** [`2026-04-29-mesh-voice-call-phase3-design.md`](2026-04-29-mesh-voice-call-phase3-design.md). Phase 3d.1 (already merged) shipped the core call flow — coordinator, active-call screen, incoming sheet, and local Hive history — gated behind a debug-only entry point. 3d.2 makes the feature usable end-to-end through normal chat UX.

## Goal

Make a mesh voice call placeable from a regular DIRECT chat header instead of MeshDebugScreen. Show users when a contact is reachable via mesh. Merge mesh-call history with the existing CallHistoryScreen. Surface iOS background-suspend limitation once. Prevent confusion when LiveKit is already active.

After 3d.2, mesh voice calls are production-quality for the foreground use case on both platforms.

## Non-Goals (Phase 3d.2)

Out of scope, deferred to Phase 3d.3:

- **Android background foreground service** with full-screen incoming Notification. The original Phase 3 design assumed an existing mesh foreground service in the codebase, but no such service exists. Building it requires `Service` class, `MANAGE_EXTERNAL_STORAGE`/`FOREGROUND_SERVICE_MICROPHONE` permissions on Android 13+, BroadcastReceiver for accept-from-notification, and integration with Doze mode. ~1-2 weeks of work, deserves its own phase.

- **CallKit integration** (lock-screen UI). Out of scope for all of Phase 3 per parent design.

- **Persisting "recent LiveKit call with peer X" across restarts.** In-memory `Map<String, int>` is enough for the 30-minute sticky-transport heuristic. SharedPreferences-backed persistence can land later if real users hit the cold-start case.

- **Server-side caller-name resolution for `peerUserId == null` mesh entries.** Phase 3d.2 falls back to `Mesh-устройство <hex>` rendering — same as `MeshIncomingCallSheet` and `MeshVoiceCallScreen`.

- **CallKit-style dial pad / number pad for mesh.** Mesh peers are discovered, not dialed by ID.

## Architecture

```
┌────────────────────────────────────────────────────────────┐
│ chat_room_screen.dart                                       │
│   ├─ phone IconButton  → onPressed: _autoPickCall()         │
│   │                    → onLongPress: _showTransportPopup()│
│   ├─ MeshEligibilityDot (overlay on phone icon)            │
│   └─ static _recentLkCallMs map (30-min sticky transport)  │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌────────────────────────────────────────────────────────────┐
│ MeshPeerEligibilityWatcher (singleton, NEW)                 │
│  - subscribes once to MeshTransport.discoveries / losses   │
│  - aggregates onlineDevices per userId                     │
│  - exposes: bool isUserOnline(userId)                      │
│             Stream<({userId, isOnline})> userChanges       │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌────────────────────────────────────────────────────────────┐
│ MeshTransport (existing) + HiveContactKeyStore (existing)   │
│  - discoveries / losses streams: PeerDiscovered/PeerLost   │
│  - allUserIdMappings(): Iterable<(userId, userPk)>         │
│  - devicesFor(userPk): List<PeerId>                        │
└────────────────────────────────────────────────────────────┘

┌────────────────────────────────────────────────────────────┐
│ call_history_screen.dart (modified)                         │
│  - parallel: server fetch + MeshCallHistoryRepository.watch│
│  - converts MeshCallHistoryEntry → _CallEntry              │
│  - sorts globally by startedAt desc                        │
│  - renders 📡 Mesh badge for entries with isMesh==true     │
└────────────────────────────────────────────────────────────┘
```

## Components

### 1. `MeshPeerEligibilityWatcher`

**File:** `lib/core/voice/mesh_peer_eligibility_watcher.dart` (~120 lines)

**Constructor:**
```dart
MeshPeerEligibilityWatcher({
  required MeshTransport transport,
  required HiveContactKeyStore contactKeyStore,
});
```

**State:** `Map<String userId, Set<PeerId> onlineDevices>` — populated as discovery events arrive. A userId is "online" iff any of its known devicePks appears in the discovery set.

**Public API:**
```dart
void start();                     // subscribes to transport streams
Future<void> dispose();           // cancels subscriptions, closes broadcast controller
bool isUserOnline(String userId);
Stream<({String userId, bool isOnline})> get userChanges;  // broadcast
```

**Behavior:**
- On `PeerDiscovered(devicePk)`:
  1. Look up `devicePk → userPk` via `contactKeyStore.lookupUserByDevice(devicePk)`. If no mapping (unknown contact), ignore.
  2. Look up `userPk → userId` via scan over `contactKeyStore.allUserIdMappings()`. If no mapping (mesh device of unauthenticated peer), ignore.
  3. Add `devicePk` to `_onlineDevices[userId]`. If the set was empty, emit `(userId, isOnline: true)` on `userChanges`.
- On `PeerLost(devicePk)`:
  1. Find the userId whose set contains this devicePk (linear scan O(N) where N = contacts known to be online).
  2. Remove devicePk. If the set is now empty, remove the userId entry and emit `(userId, isOnline: false)`.
- `isUserOnline(userId)` → `_onlineDevices[userId]?.isNotEmpty == true`.

### 2. `MeshEligibilityDot`

**File:** `lib/features/voice/presentation/widgets/mesh_eligibility_dot.dart` (~80 lines)

**Constructor:**
```dart
MeshEligibilityDot({
  required String userId,
  Color color = const Color(0xFF4CAF50),  // material green
  double size = 6.0,
});
```

**Implementation:** `StatefulWidget`. In `initState`:
1. Read initial state via `sl<MeshPeerEligibilityWatcher>().isUserOnline(userId)` → `_isOnline`.
2. Subscribe to `watcher.userChanges.where((e) => e.userId == userId)` → update `_isOnline` + `setState`.

In `build`: returns either `Container(width: size, height: size, decoration: BoxDecoration(shape: circle, color: color))` or `SizedBox.shrink()` based on `_isOnline`.

**Placement in chat_room_screen:** wrapped over the phone IconButton via `Stack` with `Positioned(top: 4, right: 4, child: MeshEligibilityDot(userId: otherUserId))`. Render only when `conv?.type == 'DIRECT' && otherUserId != null`.

### 3. Auto-pick logic

**File:** `lib/features/messenger/presentation/screens/chat_room_screen.dart` (~120 lines added/changed)

The existing `_startCall()` is renamed to `_startLkCall()` (no behavior change). New entry point:

```dart
static final Map<String, int> _recentLkCallMs = {}; // userId → epoch ms

Future<void> _autoPickCall() async {
  if (CallStateService.instance.isInCall && !CallStateService.instance.canAddLine) {
    _showSnack(AppLocalizations.of(context)!.callConflictAlreadyInCall);
    return;
  }
  final conv = _resolveConv(...);
  if (conv?.type != 'DIRECT') return _startLkCall();
  final userId = conv?.otherUserId;
  if (userId == null) return _startLkCall();

  final recentMs = _recentLkCallMs[userId];
  if (recentMs != null && DateTime.now().millisecondsSinceEpoch - recentMs < 30 * 60 * 1000) {
    return _startLkCall();
  }

  if (!sl<MeshPeerEligibilityWatcher>().isUserOnline(userId)) {
    return _startLkCall();
  }

  await _maybeShowIosOnboardingTooltip();
  await _startMeshCall(userId);
}

Future<void> _showTransportPopup() async {
  // showModalBottomSheet with two ElevatedButton.icon: mesh / livekit.
  // Mesh button is disabled (greyed out) when watcher.isUserOnline == false.
}

Future<void> _startMeshCall(String userId) async {
  // Resolve userId → first devicePk via contact key store.
  final userPk = sl<HiveContactKeyStore>().userPkForContactUserId(userId);
  if (userPk == null) return _startLkCall();
  final devices = sl<HiveContactKeyStore>().devicesFor(userPk);
  if (devices.isEmpty) return _startLkCall();
  final devicePk = (devices.toList()..sort((a, b) => a.toHex().compareTo(b.toHex()))).first;
  await sl<MeshVoiceUiCoordinator>().placeCall(devicePk);
}

Future<void> _startLkCall() async {
  final conv = _resolveConv(...);
  if (conv?.type == 'DIRECT' && conv?.otherUserId != null) {
    _recentLkCallMs[conv!.otherUserId!] = DateTime.now().millisecondsSinceEpoch;
  }
  // ... existing _startCall body unchanged.
}
```

The phone IconButton becomes:
```dart
GestureDetector(
  onLongPress: _showTransportPopup,
  child: IconButton(
    icon: Stack(...phone icon + Positioned MeshEligibilityDot),
    onPressed: _autoPickCall,
  ),
)
```

### 4. iOS onboarding tooltip

**File:** `lib/features/voice/presentation/widgets/ios_mesh_onboarding_tooltip.dart` (~100 lines)

Public API:
```dart
class IosMeshOnboardingTooltip {
  static const _prefsKey = 'mesh_onboarding_shown_v1';

  /// Returns true if the dialog was shown (and dismissed) just now.
  /// Returns false on non-iOS or if already-shown flag is set.
  static Future<bool> showIfNeeded(BuildContext context) async { ... }
}
```

Implementation:
1. If `!Platform.isIOS` → return false.
2. Read `SharedPreferences.getInstance().getBool(_prefsKey)` — if `true`, return false.
3. Show `AlertDialog`:
   - Title: 📡 `meshOnboardingTitle` ("Mesh-звонки требуют активного приложения")
   - Content: `meshOnboardingBody` ("Когда телефон заблокирован, mesh-звонки могут прерываться через ~30 секунд (iOS ограничение).")
   - Actions: `[ElevatedButton onPressed: pop with 'ok' label: meshOnboardingAck]`
4. After dismiss: write `prefs.setBool(_prefsKey, true)`. Return true.

`_autoPickCall` calls `await IosMeshOnboardingTooltip.showIfNeeded(context)` before `_startMeshCall`.

### 5. CallHistoryScreen merge

**File:** `lib/features/call_history/presentation/screens/call_history_screen.dart` (~150 lines added/changed)

Modifications:

1. **Extend `_CallEntry`** with two optional mesh fields:
```dart
final String? meshTransport;   // 'bonjour' | 'ble' | null. non-null ⇒ this is a mesh entry
final String? meshEndReason;   // EndReason.name from MeshCallHistoryEntry.endReason
bool get isMesh => meshTransport != null || (id.startsWith('mesh-') && meshEndReason != null);
```

2. **Add converter helper** at file scope:
```dart
_CallEntry _entryFromMesh(MeshCallHistoryEntry m) => _CallEntry(
  id: 'mesh-${m.callId.toRadixString(16)}',
  otherPartyName: m.peerName ?? 'Mesh-устройство ${_hexShort(m.peerDevicePkBase64)}',
  otherPartyAvatar: null,
  otherPartyId: m.peerUserId,
  startedAt: m.startedAt,
  durationSec: m.durationSec,
  isOutgoing: m.isOutgoing,
  isMissed: m.activatedAt == null && (m.endReason == 'inviteTimeout' || m.endReason == 'rejectedByCallee'),
  withAi: false,
  conversationId: null,
  meshTransport: m.transport,
  meshEndReason: m.endReason,
);

String _hexShort(String base64Pk) {
  // Decode base64 → first 4 bytes → hex (matches incoming-sheet fallback format).
  try {
    final bytes = base64Decode(base64Pk);
    return bytes.take(4).map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  } catch (_) {
    return base64Pk.substring(0, math.min(8, base64Pk.length));
  }
}
```

3. **In `_loadHistory()`** (existing method):
   - After server fetch produces `serverEntries`, also call `final meshEntries = (await sl<MeshCallHistoryRepository>().getAll()).map(_entryFromMesh).toList()`.
   - Combine: `final all = [...serverEntries, ...meshEntries]`. Sort by `startedAt desc`. Set `_history = all`.

4. **Subscribe to `MeshCallHistoryRepository.watch()`** in `initState` — on each emit, re-merge with current server cache + setState. Cancel subscription in `dispose`.

5. **Render mesh badge**: in the entry widget builder (existing `_CallTile` or similar), if `entry.isMesh`, append a small `Container(padding: 4, child: Text('📡 Mesh', style: small)) ` next to the timestamp row.

6. **Tap behavior on mesh entry:** if `entry.otherPartyId != null` — open DIRECT chat (existing `_openConversation` reuse). If null — `ScaffoldMessenger.showSnackBar(meshHistoryNoChatAvailable)`.

### 6. `_screenPushed` refactor (carry-over from 3d.1)

**File:** `lib/core/voice/mesh_voice_ui_coordinator.dart` (~10 lines net change)

Move `bool _screenPushed` from `MeshVoiceUiCoordinator` field into `_PendingCall.screenPushed` (mutable, default false). Set true at push time, automatically discarded when `_pending = null` in `_handleEnded`. The Boolean no longer relies on `Navigator.push.future` blocking until the route pops.

All 3d.1 tests continue to pass — the flag's observable semantics are unchanged.

## Boot sequence (DI changes)

In `setupDependencies()` in `lib/core/di/service_locator.dart`, after the `MeshVoiceUiCoordinator` registration, add:

```dart
sl.registerLazySingleton<MeshPeerEligibilityWatcher>(
  () => MeshPeerEligibilityWatcher(
    transport: sl<MeshTransport>(),
    contactKeyStore: sl<HiveContactKeyStore>(),
  ),
);
```

In `lib/core/mesh/mesh_bootstrap.dart`, in `runMeshBootstrap()` after `sl<MeshVoiceUiCoordinator>().start()`:

```dart
if (sl.isRegistered<MeshPeerEligibilityWatcher>()) {
  try {
    sl<MeshPeerEligibilityWatcher>().start();
    debugPrint('[mesh-boot] MeshPeerEligibilityWatcher.start() ok');
  } catch (e) {
    debugPrint('[mesh-boot] MeshPeerEligibilityWatcher.start() failed: $e');
  }
}
```

## l10n keys

To `lib/l10n/app_ru.arb` and `app_en.arb`, add:

| Key | RU | EN |
|---|---|---|
| `callConflictAlreadyInCall` | Завершите текущий звонок | Finish the current call first |
| `callPopupTransportTitle` | Способ звонка | Call via |
| `callPopupTransportMesh` | 📡 По сети (mesh) | 📡 Mesh (peer-to-peer) |
| `callPopupTransportLk` | 📞 Через сервер | 📞 Server |
| `callPopupTransportMeshUnavailable` | Контакт не доступен через mesh | Contact not reachable via mesh |
| `meshOnboardingTitle` | 📡 Mesh-звонки требуют активного приложения | 📡 Mesh calls need the app open |
| `meshOnboardingBody` | Когда телефон заблокирован, mesh-звонки могут прерываться через ~30 секунд (iOS ограничение). | When the phone is locked, mesh calls may drop after ~30 seconds (iOS limitation). |
| `meshOnboardingAck` | Понятно | Got it |
| `meshHistoryBadge` | 📡 Mesh | 📡 Mesh |
| `meshHistoryNoChatAvailable` | Контакт не в списке | Contact is not in your list |

## Edge cases

- **Watcher started before DeviceKeySync completes:** `isUserOnline(userId)` returns false until the key sync writes mappings to `HiveContactKeyStore`. Mesh dot appears a few seconds after login (acceptable).
- **One userId, multiple online devices:** dot true while at least one device is online. `_startMeshCall` picks the lexicographically smallest devicePk hex (deterministic, predictable).
- **iOS-tooltip race:** if user double-taps the phone icon, second tap may fire while the dialog is still up. Guard via `bool _tooltipShowing = false` static — if true, second tap does no-op until dialog dismisses.
- **CallHistoryScreen tap on mesh entry without `peerUserId`:** SnackBar `meshHistoryNoChatAvailable`, no navigation.
- **`_recentLkCallMs` pollution:** Map grows unboundedly per session. Bounded in practice (≤ contact count). No persistent eviction needed for v1.
- **Conflict with active mesh call (not LK):** `MeshVoiceService.invite()` already throws StateError → coordinator shows existing "Звонок уже идёт" SnackBar. Auto-pick path doesn't add new logic.
- **Group/AI/channel chat:** `_autoPickCall` short-circuits to `_startLkCall()`. Long-press popup not shown for non-DIRECT (skipped via `if (conv?.type != 'DIRECT') return null` early in popup handler).

## Testing

**Unit (`MeshPeerEligibilityWatcher`):**
- `start()` subscribes to transport.discoveries + losses; `dispose()` cancels.
- `isUserOnline(userId)` returns true after PeerDiscovered for an owned device of that userId.
- `userChanges` emits only on first-add and last-remove (not on every device add when set non-empty).
- Returns false when ContactKeyStore has no userPk-for-userId mapping yet.
- Returns false when transport reports unknown device (no userPk mapping).

**Widget (`MeshEligibilityDot`):**
- Renders `SizedBox.shrink` initially when `isUserOnline == false`.
- Renders dot Container after watcher emits `(userId, true)`.
- Disappears after watcher emits `(userId, false)`.

**Widget (`chat_room_screen` auto-pick):**
- DIRECT + watcher.isUserOnline=true + iOS first-time → tooltip shown then placeCall fires.
- DIRECT + watcher.isUserOnline=false → _startLkCall fires (not placeCall).
- DIRECT + recent LK call within 30 min → _startLkCall fires regardless of mesh eligibility.
- group chat → _startLkCall fires (mesh path skipped).
- isInCall=true → SnackBar shown, neither path fires.
- Long-press → showModalBottomSheet shown with both transport options.
- Mesh option in popup is disabled when isUserOnline=false.

**Integration (`call_history_mesh_merge_test`):**
- Server-list and mesh-list combined → sorted by startedAt desc with mesh entries interleaved correctly.
- Tap on mesh entry with peerUserId → calls `_openConversation` with userId.
- Tap on mesh entry with peerUserId=null → SnackBar shown, no navigation.
- Repository `watch()` emits → CallHistoryScreen re-renders with new entry visible.

**Hardware smoke (after merge):**
- Two devices on same WiFi, both authenticated as mutual contacts.
- Open DIRECT chat with the other user → 📡 dot visible next to phone icon.
- Toggle WiFi off on receiver → dot disappears within ~10 sec on caller side (mDNS ServiceLost).
- Toggle WiFi on → dot reappears within ~10 sec.
- Short-tap phone → mesh call rings on receiver (incoming sheet appears via existing 3d.1 flow).
- iOS-side first call: tooltip dialog shows first time only.
- Long-press → popup with two options. Tap `[Через сервер]` → LiveKit call starts.
- During an active LiveKit call: tap phone icon → SnackBar "Завершите текущий звонок". LK call unaffected.
- Open CallHistoryScreen → mesh call from earlier appears with 📡 Mesh badge in correct chronological order.
- Tap that mesh history entry → opens DIRECT chat with the peer.

## Files to create

```
lib/core/voice/mesh_peer_eligibility_watcher.dart                              ~120 lines
lib/features/voice/presentation/widgets/mesh_eligibility_dot.dart              ~80 lines
lib/features/voice/presentation/widgets/ios_mesh_onboarding_tooltip.dart       ~100 lines

test/core/voice/mesh_peer_eligibility_watcher_test.dart                        ~150 lines
test/features/voice/presentation/widgets/mesh_eligibility_dot_test.dart        ~80 lines
test/features/messenger/presentation/screens/chat_room_auto_pick_test.dart     ~200 lines
test/features/call_history/call_history_mesh_merge_test.dart                   ~120 lines
```

## Files to modify

```
lib/core/di/service_locator.dart                                       +10 lines
lib/core/mesh/mesh_bootstrap.dart                                      +5 lines
lib/core/voice/mesh_voice_ui_coordinator.dart                          +5 -5 (_screenPushed → _PendingCall.screenPushed)
lib/features/messenger/presentation/screens/chat_room_screen.dart      +120 lines
lib/features/call_history/presentation/screens/call_history_screen.dart  +150 lines
lib/features/mesh_debug/presentation/screens/mesh_debug_screen.dart    -40 lines  (remove debug Place-call button — chat-header is now primary)
lib/l10n/app_ru.arb                                                    +10 keys
lib/l10n/app_en.arb                                                    +10 keys
```

**Files explicitly NOT touched:**

- `voice_call_screen.dart` (LiveKit, 5280 lines)
- `mesh_voice_service.dart` (Phase 3c)
- `bonjour_transport.dart` (Phase 3a/3b/3d.1)
- `mesh_voice_call_screen.dart` (Phase 3d.1 — only carry-over flag refactor in coordinator)
- `mesh_incoming_call_sheet.dart` (Phase 3d.1)
- `mesh_call_history_repository.dart` (Phase 3d.1)

## Risks

**High:**

1. **Tap-to-open-chat from mesh-history entry without `peerUserId`** — UX trade-off (SnackBar). Acceptable for v1; revisit if user feedback complains.

**Medium:**

2. **Watcher requires ContactKeyStore mappings to be populated.** After fresh login, mesh dot may take ~30 sec to appear because DeviceKeySync runs in background. Documented; acceptable.
3. **Recent-LK 30-min memory is process-local.** Cold-restart forgets sticky transport. Documented; SharedPreferences-backed persistence is a 3d.x improvement.

**Low:**

4. **iOS gesture conflicts with `onLongPress`** — using bare `GestureDetector` (not `InkWell`) to avoid Material ripple eating the long-press.
5. **CallHistoryScreen modifications in a 2830-line file.** Localized to `_loadHistory`, `_CallEntry`, and the entry render method. Risk low.
6. **Cache key collision in `CallHistoryCacheService`** — mesh entry IDs are prefixed `'mesh-'`, server IDs are UUIDs. No collision.

## Success criteria

3d.2 is done when:

1. On two devices (Android + iPhone, same WiFi), both authenticated to mutual-contact accounts: open DIRECT chat → 📡 green dot appears next to phone icon within ~10 sec of mesh discovery.
2. WiFi toggle on either device → dot disappears within ~10 sec on the other side; toggle back → dot reappears.
3. Short-tap phone in DIRECT chat → mesh call (sheet → screen → audio both ways → hangup → history entry written).
4. First-ever short-tap on iOS → onboarding dialog shown; subsequent taps → no dialog.
5. Long-press phone → popup with `[По сети] [Через сервер]`. Tap server option → LiveKit call.
6. While LiveKit active, tap phone icon → SnackBar "Завершите текущий звонок". LK call uninterrupted.
7. Open CallHistoryScreen → mesh entries appear with 📡 Mesh badge, in global chronological order. Tap → opens DIRECT chat (when peerUserId resolved).
8. All ~24 new tests pass; 540+ total suite green.
9. `flutter analyze` clean for new and modified files.
10. No regressions in 3d.1 functionality (verified by replaying 3d.1 hardware smoke flow at end of 3d.2 smoke).

## Vertical slice for Phase 3d.3

After 3d.2, mesh voice calls are end-to-end production-quality for the foreground use case. Phase 3d.3 adds:

- Android foreground service (new Service class) keeping the mesh stack alive in background.
- BroadcastReceiver for "Accept" / "Decline" actions in incoming notification.
- Full-screen incoming Notification on Android using existing `flutter_local_notifications` channel.
- Documentation/screenshot guide for users to enable battery-optimization exception.

iOS background limitation will remain documented (Phase 3 design accepts it). CallKit support is a possible Phase 3.x.

## Rollout

1. Branch `feature/mesh-voice-call-phase3d.2` from `dev` (3d.1 is already merged into dev).
2. Implement via subagent-driven-development: ~10 tasks (watcher, dot widget, auto-pick, tooltip, history merge, conflict toast, _screenPushed refactor, l10n, hardware smoke, PR).
3. Hardware smoke per success criteria.
4. PR into `dev`. After merge, branch `feature/mesh-voice-call-phase3d.3` (Android foreground service) — separate phase, separate spec.

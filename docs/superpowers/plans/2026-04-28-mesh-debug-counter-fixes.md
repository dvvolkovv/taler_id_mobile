# Mesh Debug Counter Fixes Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix two follow-ups identified during PR #9 hardware smoke — make the Mesh Debug status card auto-refresh once per second, and drain `PendingMeshSendQueue` entries when the server echo confirms delivery.

**Architecture:** A 1 Hz `Timer.periodic` in `_MeshDebugScreenState` keeps all three counters honest without per-counter stream plumbing. In `MessengerBloc._onMessageReceived`, mirror the existing `_pending.remove(tempId)` cleanup loop with `_pendingMeshQueue.remove(tempId)` so server-relay delivery clears mesh-pending state. Single-device assumption documented inline.

**Tech Stack:** Dart/Flutter, `flutter_bloc`, `get_it` (DI), `flutter_test`, `bloc_test`, `mocktail`. Mobile-only.

**Spec:** `docs/superpowers/specs/2026-04-28-mesh-debug-counter-fixes-design.md`

**Branch:** `fix/mesh-debug-counter-fixes` (already created from `dev`, spec already committed).

**File map:**

| File | Role | New / Modified |
|---|---|---|
| `lib/features/messenger/presentation/bloc/messenger_bloc.dart` | Add `_pendingMeshQueue` field + `remove(tempId)` call alongside existing pending cleanup loop in `_onMessageReceived` | Modified |
| `lib/features/mesh_debug/presentation/screens/mesh_debug_screen.dart` | Add `Timer? _refreshTicker`; arm 1 Hz `Timer.periodic` in `initState`; cancel in `dispose` | Modified |
| `test/messenger/messenger_bloc_test.dart` | Register `PendingMeshSendQueue` in `setUp`; new test asserting echo drains a previously-enqueued entry | Modified |

---

## Task 1: `MessengerBloc` drains mesh-pending on echo (TDD)

**Files:**
- Modify: `lib/features/messenger/presentation/bloc/messenger_bloc.dart`
- Modify: `test/messenger/messenger_bloc_test.dart`

- [ ] **Step 1: Register `PendingMeshSendQueue` in the bloc test scaffold**

The bloc field initializer reads `PendingMeshSendQueue` via `sl`, so the test must register a real instance in `setUp` (it's a small in-memory class with no Hive dependency, no fake needed).

In `test/messenger/messenger_bloc_test.dart`, find the `setUp(() {` block (around line 227). After the `MessengerRemoteDataSource` registration (around line 251), add:

```dart

    if (sl.isRegistered<PendingMeshSendQueue>()) {
      sl.unregister<PendingMeshSendQueue>();
    }
    sl.registerSingleton<PendingMeshSendQueue>(PendingMeshSendQueue());
```

Add the import at the top of the file (next to the other relative imports under `package:taler_id_mobile/...`):

```dart
import 'package:taler_id_mobile/features/messenger/data/services/pending_mesh_send_queue.dart';
```

- [ ] **Step 2: Write the failing test**

Append a new test at the end of the existing `group('MessageReceived', () {` block (the closing `});` of that group is around line 746). Use `seed:` (clean, public API) — not `bloc.emit` (private):

```dart

    blocTest<MessengerBloc, MessengerState>(
      'echo drains matching mesh-pending entry',
      setUp: () {
        sl<PendingMeshSendQueue>().enqueue(
          clientId: 'temp_mesh-1',
          conversationId: 'conv-1',
          content: 'mesh hi',
          sentAt: DateTime(2024, 1, 15, 10, 0),
        );
      },
      build: buildBloc,
      seed: () => MessengerState(messages: {
        'conv-1': [
          MessageEntity(
            id: 'temp_mesh-1',
            conversationId: 'conv-1',
            senderId: 'user-1',
            senderName: 'Me',
            content: 'mesh hi',
            sentAt: DateTime(2024, 1, 15, 10, 0),
          ),
        ],
      }),
      act: (b) => b.add(MessageReceived(MessageEntity(
        id: 'srv-mesh-1',
        conversationId: 'conv-1',
        senderId: 'user-1',
        senderName: 'Me',
        content: 'mesh hi',
        sentAt: DateTime(2024, 1, 15, 10, 0),
        clientTempId: 'temp_mesh-1',
      ))),
      verify: (_) {
        expect(sl<PendingMeshSendQueue>().pendingCount, 0,
            reason: 'echo with matching senderId+content should drain mesh-pending entry');
      },
    );
```

- [ ] **Step 3: Run the test, expect FAIL**

Run: `cd /Users/dmitry/Downloads/taler_id_mesh && flutter test test/messenger/messenger_bloc_test.dart --plain-name 'echo drains matching mesh-pending'`

Expected: 1 test fails with `Expected: <0> Actual: <1>` — the queue entry is still present because the bloc currently never calls `_pendingMeshQueue.remove`.

If it instead fails with a compilation or DI error (`Object/factory with type PendingMeshSendQueue is not registered`), the `setUp` registration in Step 1 is missing or the import is wrong — fix that first.

- [ ] **Step 4: Add the field + the cleanup call**

In `lib/features/messenger/presentation/bloc/messenger_bloc.dart`, find the existing field declaration block at the top of the class (line 25 area):

```dart
  final PendingMessageService _pending = sl<PendingMessageService>();
```

Add right below it:

```dart
  final PendingMeshSendQueue _pendingMeshQueue = sl<PendingMeshSendQueue>();
```

Add the import at the top of the file alongside the other `../../data/...` imports (line 9 area):

```dart
import '../../data/services/pending_mesh_send_queue.dart';
```

Find the existing pending cleanup loop in `_onMessageReceived` (lines 760-766):

```dart
    // Clear these from the persistent pending queue — server has acknowledged.
    // Also clear from in-flight set so a future _resendPending() can emit them
    // if they're ever re-queued.
    for (final tempId in removed) {
      _pending.remove(tempId);
      _inFlightTempIds.remove(tempId);
    }
```

Replace it with:

```dart
    // Clear these from the persistent pending queue — server has acknowledged.
    // Also clear from in-flight set so a future _resendPending() can emit them
    // if they're ever re-queued. Mesh-pending drain: server echo ⇒ message
    // reached the broker and was routed to all online recipients; mesh
    // fanout retry is no longer required for this clientId. (Edge case:
    // multi-device user with one device offline — server only delivered to
    // online devices; the mesh-only path to the offline device is bypassed.
    // Acceptable today since most users have one device per account.)
    for (final tempId in removed) {
      _pending.remove(tempId);
      _inFlightTempIds.remove(tempId);
      _pendingMeshQueue.remove(tempId);
    }
```

- [ ] **Step 5: Run the test, expect PASS**

Run: `cd /Users/dmitry/Downloads/taler_id_mesh && flutter test test/messenger/messenger_bloc_test.dart --plain-name 'echo drains matching mesh-pending'`

Expected: 1 test passed.

- [ ] **Step 6: Run the full bloc test file for regressions**

Run: `cd /Users/dmitry/Downloads/taler_id_mesh && flutter test test/messenger/messenger_bloc_test.dart`

Expected: all tests pass. Other tests already construct `MessengerBloc`; if any of them now fail with `PendingMeshSendQueue is not registered`, the `setUp` registration from Step 1 isn't running — verify the registration is inside the outer `setUp(() {` block, not nested in a sub-group.

- [ ] **Step 7: Commit**

```bash
cd /Users/dmitry/Downloads/taler_id_mesh && git add lib/features/messenger/presentation/bloc/messenger_bloc.dart test/messenger/messenger_bloc_test.dart && git commit -m "fix(mesh): drain PendingMeshSendQueue on server echo"
```

If a pre-commit hook fails, investigate (do NOT use `--no-verify`).

---

## Task 2: `MeshDebugScreen` 1 Hz refresh ticker

**Files:**
- Modify: `lib/features/mesh_debug/presentation/screens/mesh_debug_screen.dart`

This task has no isolated unit test — verification is `dart analyze` clean + Task 3 hardware smoke (re-run PR #9 4b on devices).

- [ ] **Step 1: Add the ticker field**

In `lib/features/mesh_debug/presentation/screens/mesh_debug_screen.dart`, find the existing fields block in `_MeshDebugScreenState` (around line 24-37):

```dart
class _MeshDebugScreenState extends State<MeshDebugScreen> {
  late final MeshTransport _transport;
  late final MeshStaticKey _meshKey;

  MeshMessagingService? _messaging;

  bool _running = false;
  String? _lastError;

  final Map<PeerId, _PeerEntry> _peers = {};
  final List<_LogEntry> _messages = [];
  StreamSubscription<PeerDiscovered>? _discoverySub;
  StreamSubscription<PeerLost>? _lossSub;
  StreamSubscription<InboundEnvelope>? _inboundSub;
```

Add this field at the bottom of that block (right after `_inboundSub`):

```dart
  Timer? _refreshTicker;
```

The `Timer` import is already present via `import 'dart:async';` at line 1.

- [ ] **Step 2: Arm the ticker in `initState`**

Find the existing `initState` (around line 40-44):

```dart
  @override
  void initState() {
    super.initState();
    _transport = sl<MeshTransport>();
    _meshKey = sl<MeshStaticKey>();
  }
```

Replace it with:

```dart
  @override
  void initState() {
    super.initState();
    _transport = sl<MeshTransport>();
    _meshKey = sl<MeshStaticKey>();
    // Mesh Debug counters (Pending / Resets / Reinits) read fresh from DI on
    // each rebuild. Outbound mesh-fanout, supervisor reinits, and peer
    // resets on the receive side don't always coincide with a discovery /
    // inbound event, so we drive a 1 Hz tick to keep the status card honest.
    _refreshTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {});
    });
  }
```

- [ ] **Step 3: Cancel the ticker in `dispose`**

Find the existing `dispose` (around line 47-52):

```dart
  @override
  void dispose() {
    _discoverySub?.cancel();
    _lossSub?.cancel();
    _inboundSub?.cancel();
    super.dispose();
  }
```

Replace it with:

```dart
  @override
  void dispose() {
    _refreshTicker?.cancel();
    _discoverySub?.cancel();
    _lossSub?.cancel();
    _inboundSub?.cancel();
    super.dispose();
  }
```

- [ ] **Step 4: Verify analyze + tests still green**

Run: `cd /Users/dmitry/Downloads/taler_id_mesh && dart analyze lib/features/mesh_debug/presentation/screens/mesh_debug_screen.dart 2>&1 | tail -5`
Expected: no errors.

Run: `cd /Users/dmitry/Downloads/taler_id_mesh && flutter test 2>&1 | tail -3`
Expected: `All tests passed!`

- [ ] **Step 5: Commit**

```bash
cd /Users/dmitry/Downloads/taler_id_mesh && git add lib/features/mesh_debug/presentation/screens/mesh_debug_screen.dart && git commit -m "fix(mesh-debug): 1 Hz ticker so counters auto-refresh while screen is open"
```

---

## Task 3: Final analyze + push + hardware smoke + PR

**Files:** none modified — verification only.

- [ ] **Step 1: Static analysis**

Run: `cd /Users/dmitry/Downloads/taler_id_mesh && flutter analyze 2>&1 | tail -10`
Expected: no NEW errors or warnings introduced. Existing baseline is acceptable.

- [ ] **Step 2: Full test suite**

Run: `cd /Users/dmitry/Downloads/taler_id_mesh && flutter test 2>&1 | tail -3`
Expected: `All tests passed!` Count is current baseline + 1 new test = ~438.

- [ ] **Step 3: Push to origin**

```bash
cd /Users/dmitry/Downloads/taler_id_mesh && git push -u origin fix/mesh-debug-counter-fixes
```

- [ ] **Step 4: Hardware smoke (manual)**

Two devices (Android Redmi 78c0742f + iPhone wired 00008150-...), both running a fresh dev build of this branch.

Build & install:

```bash
cd /Users/dmitry/Downloads/taler_id_mesh
flutter build apk --flavor dev --release -t lib/main_dev.dart --dart-define=FLAVOR=dev --dart-define=BASE_URL=https://staging.id.taler.tirol
~/Library/Android/sdk/platform-tools/adb -s 78c0742f install -r build/app/outputs/flutter-apk/app-dev-release.apk
flutter run --release --flavor dev -t lib/main_dev.dart --dart-define=FLAVOR=dev --dart-define=BASE_URL=https://staging.id.taler.tirol -d 00008150-00060C5A21E9401C
```

(Hit `q` once iOS install completes; the app stays installed and running on the device.)

**Smoke 1 — re-run PR #9 4b with the fix:**

1. Open Mesh Debug on Android. Force-quit Taler ID Dev on iPhone.
2. Send 2 text messages from Android to iPhone in a 1:1 chat.
3. Switch to Mesh Debug on Android. Counter shows `Pending: 2`.
4. Relaunch iPhone, wait ~5 s for Socket.IO to deliver.
5. **Expected (different from PR #9 result):** without leaving the Mesh Debug screen, counter ticks down to `Pending: 0` within 1-2 seconds of the iPhone receiving the messages — Task 1's drain-on-echo fires when Android's bloc gets the server echo, and Task 2's 1 Hz ticker re-renders the card.
6. Force-quit Android app, reopen — `Pending: 0` (queue is in-memory; restart proves queue was actually drained, not just hidden).

**Smoke 2 — `Reinits` live update:**

1. With Mesh Debug open on Android, toggle WiFi off and back on.
2. **Expected:** within a couple of seconds, `Reinits` ticks up by ≥ 1 without re-entering the screen.

- [ ] **Step 5: Open the PR**

```bash
cd /Users/dmitry/Downloads/taler_id_mesh && gh pr create --base dev --head fix/mesh-debug-counter-fixes --title "fix(mesh-debug): drain pending queue on echo + 1 Hz UI refresh" --body "$(cat <<'EOF'
## Summary
- `MessengerBloc._onMessageReceived` now calls `_pendingMeshQueue.remove(tempId)` alongside the existing `_pending.remove(tempId)` cleanup. Once the server echoes a message back to the sender, mesh fanout retry is no longer needed for that clientId — the recipients have it via Socket.IO already. (Edge case: multi-device user with one device offline; documented inline as acceptable today.)
- `MeshDebugScreen._MeshDebugScreenState` arms a 1 Hz `Timer.periodic` in `initState` (cancelled in `dispose`) that re-runs `setState` while the screen is mounted. All three counters now refresh live without needing inbound/discovery/loss events on the host side.

## Test plan
- [x] Unit: bloc test seeds a pending bubble + a matching `PendingMeshSendQueue` entry, then fires `MessageReceived` echo; asserts `pendingCount` drops 1 → 0.
- [x] `flutter test` — full suite green.
- [x] `dart analyze` on touched files — clean.
- [x] Hardware smoke on Redmi + iPhone wired: re-running PR #9 4b shows `Pending: 2 → 0` live without screen re-entry; WiFi toggle ticks `Reinits` live.

## Notes
- Implements design `docs/superpowers/specs/2026-04-28-mesh-debug-counter-fixes-design.md`.
- Follow-up to PR #9 (mesh-debug screen polish). Picks up in v1.0.65.
- Mobile-only, no backend / DB / wire-format change.

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"
```

---

## Self-review (run by author)

**Spec coverage:**
- Fix 1 — UI 1 Hz refresh → Task 2 Steps 1-3. ✓
- Fix 2 — drain on echo (Option A semantic) → Task 1 Step 4. ✓
- Bloc unit test (Fix 2) → Task 1 Step 2. ✓
- DI injection of `PendingMeshSendQueue` as a field mirroring `_pending` pattern → Task 1 Step 4. ✓
- Hardware smoke re-running PR #9 4b → Task 3 Step 4. ✓
- Multi-device caveat documented inline in code → Task 1 Step 4 inline comment. ✓

**Placeholder scan:** none.

**Type consistency:**
- `_pendingMeshQueue` field name consistent across Task 1 Step 4 (declaration, usage in cleanup loop) and the test (`sl<PendingMeshSendQueue>()` in setUp + verify). ✓
- `clientTempId` ↔ queue key: in `_onSendMessage` the bloc sets `tempId = 'temp_<uuid>'` (line 646), uses it as both the optimistic bubble's `MessageEntity.id` AND the `clientTempId` passed to `_repo.sendMessage(...)` (line 713). The repo's `_meshFanoutOrEnqueue` enqueues with `clientId: clientTempId` — so the queue's key is the full `temp_<uuid>` string. In `_onMessageReceived`, the `removed` list collects `m.id` for matching `temp_*` bubbles, which is the same `temp_<uuid>` string. Therefore `_pendingMeshQueue.remove(tempId)` matches the queue's keying without any prefix manipulation. The test fixtures use the same `'temp_mesh-1'` string for queue key, bubble `id`, and the echo's `clientTempId` so the test exercises the exact runtime path. ✓

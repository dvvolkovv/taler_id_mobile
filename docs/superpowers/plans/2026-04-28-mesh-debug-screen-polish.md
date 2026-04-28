# Mesh Debug Screen Polish — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Surface three Phase 2.x recovery counters (pending mesh sends, peer resets, discovery reinits) on the existing Mesh Debug screen so the developer can see at a glance whether the recovery paths are firing.

**Architecture:** Add an `_reinitCount` field + getter to `MeshDiscoverySupervisor`, a `peerResetCountTotal` getter to `MeshMessagingService` (sliding window over `_peerResetTimes`), register `BonjourTransport` separately in DI so the debug screen can reach `_supervisor.reinitCount`, and extend `_StatusCard` in the debug screen with three new key/value rows.

**Tech Stack:** Dart/Flutter, `flutter_bloc`, `get_it` (DI), `bonsoir` (transport-level), `flutter_test` (with `fake_async` for the supervisor counter test). Mobile-only.

**Spec:** `docs/superpowers/specs/2026-04-28-mesh-debug-screen-polish-design.md`

**Branch:** `feature/mesh-debug-screen-polish` (already created from `dev`).

**File map:**

| File | Role | New / Modified |
|---|---|---|
| `lib/core/mesh/transport/mesh_discovery_supervisor.dart` | Add `_reinitCount` field + getter; increment in `_gatedReinit` after rate-limit check passes | Modified |
| `lib/core/mesh/transport/bonjour_transport.dart` | Add `int get discoveryReinitCount => _supervisor?.reinitCount ?? 0;` proxy | Modified |
| `lib/core/mesh/services/mesh_messaging_service.dart` | Add `int get peerResetCountTotal` | Modified |
| `lib/core/di/service_locator.dart` | Register `BonjourTransport` as a separate singleton (the same instance that goes into `MultiTransport`) | Modified |
| `lib/features/mesh_debug/presentation/screens/mesh_debug_screen.dart` | Read counters via DI; pass to `_StatusCard`; render three new `_kv` rows | Modified |
| `test/core/mesh/transport/mesh_discovery_supervisor_test.dart` | Test `reinitCount` increments only on accepted reinits | Modified |
| `test/core/mesh/services/mesh_messaging_service_test.dart` | Test `peerResetCountTotal` sliding-window count | Modified |

---

## Task 1: `MeshDiscoverySupervisor.reinitCount` (TDD)

**Files:**
- Modify: `lib/core/mesh/transport/mesh_discovery_supervisor.dart`
- Modify: `test/core/mesh/transport/mesh_discovery_supervisor_test.dart`

- [ ] **Step 1: Write the failing test**

Append a new test at the end of the existing `MeshDiscoverySupervisor` test groups (just before the closing `}` of `main()`):

```dart

  group('MeshDiscoverySupervisor reinitCount', () {
    test('increments on accepted reinit, not on rate-limited skip', () {
      fakeAsync((async) {
        final reinitCalls = <String>[];
        final lifecycleCtrl = StreamController<AppLifecycleState>.broadcast();

        final supervisor = MeshDiscoverySupervisor(
          reinit: (reason) async => reinitCalls.add(reason),
          coldStartDelay: const Duration(seconds: 5),
          maxColdStartAttempts: 3,
          lifecycleStream: lifecycleCtrl.stream,
          rateLimit: const Duration(seconds: 3),
        );
        supervisor.onDiscoveryStarted();

        expect(supervisor.reinitCount, 0);

        // First lifecycle resume — accepted.
        lifecycleCtrl
          ..add(AppLifecycleState.paused)
          ..add(AppLifecycleState.resumed);
        async.flushMicrotasks();
        expect(reinitCalls.length, 1);
        expect(supervisor.reinitCount, 1);

        // Second resume within rate-limit — skipped, counter unchanged.
        lifecycleCtrl
          ..add(AppLifecycleState.paused)
          ..add(AppLifecycleState.resumed);
        async.flushMicrotasks();
        expect(reinitCalls.length, 1);
        expect(supervisor.reinitCount, 1);

        // After rate-limit window — accepted again.
        async.elapse(const Duration(seconds: 4));
        lifecycleCtrl
          ..add(AppLifecycleState.paused)
          ..add(AppLifecycleState.resumed);
        async.flushMicrotasks();
        expect(reinitCalls.length, 2);
        expect(supervisor.reinitCount, 2);
      });
    });
  });
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `cd /Users/dmitry/Downloads/taler_id_mesh && flutter test test/core/mesh/transport/mesh_discovery_supervisor_test.dart --plain-name 'increments on accepted reinit'`
Expected: compilation error — `reinitCount` getter does not exist on `MeshDiscoverySupervisor`.

- [ ] **Step 3: Add the field, getter, and increment**

In `lib/core/mesh/transport/mesh_discovery_supervisor.dart`, find the existing private state block (around the `_lastReinitAt` field). Add a counter field next to it:

```dart
  DateTime? _lastReinitAt;
  int _reinitCount = 0;
```

Below the existing constructor body, expose the getter (place it next to other public methods like `onDiscoveryStarted`):

```dart
  int get reinitCount => _reinitCount;
```

In `_gatedReinit`, increment the counter immediately after the rate-limit check accepts and we record `_lastReinitAt`. The full updated method:

```dart
  Future<void> _gatedReinit(String reason) async {
    final now = clock.now();
    final last = _lastReinitAt;
    if (last != null && now.difference(last) < rateLimit) {
      debugPrint(
        '[mesh-discovery-supervisor] reinit skipped — within ${rateLimit.inSeconds}s rate-limit (reason=$reason)',
      );
      return;
    }
    _lastReinitAt = now;
    _reinitCount++;
    await reinit(reason);
  }
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `cd /Users/dmitry/Downloads/taler_id_mesh && flutter test test/core/mesh/transport/mesh_discovery_supervisor_test.dart --plain-name 'increments on accepted reinit'`
Expected: 1 test passed.

- [ ] **Step 5: Run the full supervisor test suite for regressions**

Run: `cd /Users/dmitry/Downloads/taler_id_mesh && flutter test test/core/mesh/transport/mesh_discovery_supervisor_test.dart`
Expected: all supervisor tests pass.

- [ ] **Step 6: Commit**

```bash
git add lib/core/mesh/transport/mesh_discovery_supervisor.dart \
        test/core/mesh/transport/mesh_discovery_supervisor_test.dart
git commit -m "mesh(debug): MeshDiscoverySupervisor.reinitCount counter"
```

---

## Task 2: `MeshMessagingService.peerResetCountTotal` (TDD)

**Files:**
- Modify: `lib/core/mesh/services/mesh_messaging_service.dart`
- Modify: `test/core/mesh/services/mesh_messaging_service_test.dart`

- [ ] **Step 1: Write the failing test**

Append a new test inside the existing `Phase 2.3 stale-session recovery` group (after the rate-limit test, before the closing `});`):

```dart

    test('peerResetCountTotal counts resets within the window', () async {
      final (alicePriv, alicePub) = await _x25519Keys();
      final (bobPriv, bobPub) = await _x25519Keys();
      final alicePeer = PeerId(alicePub);
      final bobPeer = PeerId(bobPub);

      final aliceStore = ContactKeyStore()
        ..addContact(userPk: bobPeer, devicePks: [bobPeer]);
      final bobStore = ContactKeyStore()
        ..addContact(userPk: alicePeer, devicePks: [alicePeer]);

      final aliceT = _FakeTransport();
      final bobT = _FakeTransport();
      aliceT.partner = bobT;
      bobT.partner = aliceT;

      final alice = MeshMessagingService(
        transport: aliceT,
        contactKeyStore: aliceStore,
        myDevicePrivateKey: alicePriv,
        myDevicePublicKey: alicePub,
      );
      final bob = MeshMessagingService(
        transport: bobT,
        contactKeyStore: bobStore,
        myDevicePrivateKey: bobPriv,
        myDevicePublicKey: bobPub,
        peerResetThreshold: 5,
        peerResetWindow: const Duration(seconds: 60),
      );
      await alice.start(serviceName: 'Alice');
      await bob.start(serviceName: 'Bob');

      aliceT.emitDiscovery(PeerDiscovered(
        peerId: bobPeer,
        host: '127.0.0.1',
        port: 0,
      ));
      bobT.emitDiscovery(PeerDiscovered(
        peerId: alicePeer,
        host: '127.0.0.1',
        port: 0,
      ));

      // Establish Bob's session so MAC-fail path triggers (not session==null).
      final firstAtBob = bob.inbound.first;
      await alice.sendEnvelope(
        toUserPk: bobPeer,
        envelope: Envelope(
          version: 1,
          type: 'text',
          convId: 'conv-counter',
          clientId: 'msg-warmup',
          text: 'warm up',
          sentAt: DateTime.parse('2026-04-28T10:00:00Z'),
        ),
      );
      await firstAtBob;

      expect(bob.peerResetCountTotal, 0,
          reason: 'no resets before garbage frames arrive');

      // Inject 4 garbage data frames into Bob (within threshold=5).
      for (var i = 0; i < 4; i++) {
        bobT.injectInboundFrame(InboundFrame(
          srcPeer: alicePeer,
          type: FrameType.data,
          bytes: Uint8List.fromList(List<int>.generate(80, (j) => i * 11 + j)),
        ));
      }
      await Future<void>.delayed(const Duration(milliseconds: 300));

      expect(bob.peerResetCountTotal, 4,
          reason: 'all 4 garbage frames triggered resets within window');

      await alice.dispose();
      await bob.dispose();
    });
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `cd /Users/dmitry/Downloads/taler_id_mesh && flutter test test/core/mesh/services/mesh_messaging_service_test.dart --plain-name 'peerResetCountTotal counts resets'`
Expected: compilation error — `peerResetCountTotal` getter does not exist.

- [ ] **Step 3: Add the getter**

In `lib/core/mesh/services/mesh_messaging_service.dart`, find the existing `_allowReset` method (around line 278-298). Insert the new getter immediately after the `_allowReset` method, before `_resetPeerState`:

```dart
  /// Mesh Debug — total reset count across all peers in the current
  /// `peerResetWindow`. Sliding window via DateTime comparison; matches
  /// the budget that `_allowReset` enforces. Cheap: `_peerResetTimes`
  /// is bounded by `peerResetThreshold` entries per peer plus the peer
  /// count.
  int get peerResetCountTotal {
    final now = DateTime.now();
    var total = 0;
    for (final times in _peerResetTimes.values) {
      for (final t in times) {
        if (now.difference(t) <= peerResetWindow) total++;
      }
    }
    return total;
  }
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `cd /Users/dmitry/Downloads/taler_id_mesh && flutter test test/core/mesh/services/mesh_messaging_service_test.dart --plain-name 'peerResetCountTotal counts resets'`
Expected: 1 test passed.

- [ ] **Step 5: Run the full mesh service test suite for regressions**

Run: `cd /Users/dmitry/Downloads/taler_id_mesh && flutter test test/core/mesh/services/mesh_messaging_service_test.dart`
Expected: all tests in the file pass.

- [ ] **Step 6: Commit**

```bash
git add lib/core/mesh/services/mesh_messaging_service.dart \
        test/core/mesh/services/mesh_messaging_service_test.dart
git commit -m "mesh(debug): MeshMessagingService.peerResetCountTotal getter"
```

---

## Task 3: `BonjourTransport.discoveryReinitCount` proxy + DI registration

**Files:**
- Modify: `lib/core/mesh/transport/bonjour_transport.dart`
- Modify: `lib/core/di/service_locator.dart`

This task has no isolated unit test — it's mechanical wiring. Verification is via `dart analyze` (no errors) and the integration use in Task 4 (debug screen reads it).

- [ ] **Step 1: Add the proxy getter on `BonjourTransport`**

In `lib/core/mesh/transport/bonjour_transport.dart`, find the public methods area near the existing `listenPort` getter (around line 51). Insert next to it:

```dart
  /// Mesh Debug — total Bonsoir discovery reinits the supervisor has
  /// fired since this transport was started. Returns 0 when the
  /// supervisor is not yet attached (e.g., transport stopped).
  int get discoveryReinitCount => _supervisor?.reinitCount ?? 0;
```

- [ ] **Step 2: Register `BonjourTransport` separately in DI**

In `lib/core/di/service_locator.dart`, find the existing transport registration block (around line 248):

```dart
  final bonjourTransport = BonjourTransport();
  final transports = <TransportId, MeshTransport>{
    TransportId.bonjour: bonjourTransport,
  };
  if (MeshConfig.bleEnabled) {
    transports[TransportId.ble] = BleTransport();
  }
  sl.registerSingleton<MeshTransport>(
    MultiTransport(children: transports),
  );
```

Replace it with:

```dart
  final bonjourTransport = BonjourTransport();
  // Register the concrete BonjourTransport separately so debug/diagnostic
  // tooling (Mesh Debug screen) can reach `discoveryReinitCount`. This is
  // the SAME instance that lives inside MultiTransport — registering it
  // twice via different types is fine for get_it.
  sl.registerSingleton<BonjourTransport>(bonjourTransport);

  final transports = <TransportId, MeshTransport>{
    TransportId.bonjour: bonjourTransport,
  };
  if (MeshConfig.bleEnabled) {
    transports[TransportId.ble] = BleTransport();
  }
  sl.registerSingleton<MeshTransport>(
    MultiTransport(children: transports),
  );
```

- [ ] **Step 3: Verify analyze + existing tests still green**

Run: `cd /Users/dmitry/Downloads/taler_id_mesh && dart analyze lib/core/mesh/transport/bonjour_transport.dart lib/core/di/service_locator.dart 2>&1 | tail -3`
Expected: no errors on either file.

Run: `cd /Users/dmitry/Downloads/taler_id_mesh && flutter test test/core/mesh/`
Expected: all mesh tests pass.

- [ ] **Step 4: Commit**

```bash
git add lib/core/mesh/transport/bonjour_transport.dart \
        lib/core/di/service_locator.dart
git commit -m "mesh(debug): expose BonjourTransport in DI + discoveryReinitCount proxy"
```

---

## Task 4: Mesh Debug screen — render three counters

**Files:**
- Modify: `lib/features/mesh_debug/presentation/screens/mesh_debug_screen.dart`

This task has no isolated unit test — small visual change, verification is hardware smoke (Task 5).

- [ ] **Step 1: Add imports for the new DI lookups**

In `lib/features/mesh_debug/presentation/screens/mesh_debug_screen.dart`, after the existing imports (around line 12), add:

```dart
import '../../../messenger/data/services/pending_mesh_send_queue.dart';
```

`MeshMessagingService`, `BonjourTransport`, and `sl` are already imported.

- [ ] **Step 2: Pass the three counters to `_StatusCard`**

Find the `_StatusCard(...)` invocation in `_MeshDebugScreenState.build()` (around line 183). Replace it with:

```dart
            _StatusCard(
              running: _running,
              bleEnabled: MeshConfig.bleEnabled,
              myPrefix: myPrefix,
              peerCount: _peers.length,
              pendingCount: sl.isRegistered<PendingMeshSendQueue>()
                  ? sl<PendingMeshSendQueue>().pendingCount
                  : 0,
              resetCountTotal: sl.isRegistered<MeshMessagingService>()
                  ? sl<MeshMessagingService>().peerResetCountTotal
                  : 0,
              discoveryReinitCount: sl.isRegistered<BonjourTransport>()
                  ? sl<BonjourTransport>().discoveryReinitCount
                  : 0,
            ),
```

The `isRegistered` guards keep the screen safe in test contexts that don't wire up DI fully.

- [ ] **Step 3: Extend `_StatusCard` to accept and render the three counters**

Find the `_StatusCard` class (around line 286). Replace its full definition with:

```dart
class _StatusCard extends StatelessWidget {
  final bool running;
  final bool bleEnabled;
  final String myPrefix;
  final int peerCount;
  final int pendingCount;
  final int resetCountTotal;
  final int discoveryReinitCount;

  const _StatusCard({
    required this.running,
    required this.bleEnabled,
    required this.myPrefix,
    required this.peerCount,
    required this.pendingCount,
    required this.resetCountTotal,
    required this.discoveryReinitCount,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  running ? Icons.radio_button_checked : Icons.radio_button_off,
                  color: running ? Colors.green : Colors.grey,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  running ? 'Running' : 'Stopped',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 8),
            _kv('BLE', bleEnabled ? 'ON' : 'off'),
            _kv('Me', myPrefix),
            _kv('Peers', '$peerCount'),
            _kv('Pending', '$pendingCount'),
            _kv('Resets', '$resetCountTotal (60s)'),
            _kv('Reinits', '$discoveryReinitCount'),
          ],
        ),
      ),
    );
  }

  Widget _kv(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 1),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 80,
              child: Text(
                k,
                style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
              ),
            ),
            Expanded(
              child: Text(
                v,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
              ),
            ),
          ],
        ),
      );
}
```

The structure is unchanged from the current `_StatusCard` — the only additions are the three new constructor parameters and three new `_kv` rows at the bottom of the body.

- [ ] **Step 4: Verify analyze + full test suite**

Run: `cd /Users/dmitry/Downloads/taler_id_mesh && dart analyze lib/features/mesh_debug/presentation/screens/mesh_debug_screen.dart 2>&1 | tail -3`
Expected: no errors.

Run: `cd /Users/dmitry/Downloads/taler_id_mesh && flutter test 2>&1 | tail -3`
Expected: `All tests passed!`

- [ ] **Step 5: Commit**

```bash
git add lib/features/mesh_debug/presentation/screens/mesh_debug_screen.dart
git commit -m "mesh(debug): render Pending / Resets / Reinits counters on status card"
```

---

## Task 5: Final analyze + push + manual hardware smoke + PR

**Files:** none modified — verification only.

- [ ] **Step 1: Static analysis**

Run: `cd /Users/dmitry/Downloads/taler_id_mesh && flutter analyze 2>&1 | tail -10`
Expected: no NEW errors or warnings introduced. Existing baseline (info-level lints) is acceptable.

- [ ] **Step 2: Full test suite**

Run: `cd /Users/dmitry/Downloads/taler_id_mesh && flutter test 2>&1 | tail -3`
Expected: `All tests passed!` Count is current baseline + 2 new tests = ~437.

- [ ] **Step 3: Push to origin**

```bash
git push origin feature/mesh-debug-screen-polish
```

- [ ] **Step 4: Hardware smoke (manual)**

Two devices required (Android Redmi + iPhone wired). Open Mesh Debug from settings on each.

**Step 4a — baseline:**
Initial state shows `Pending: 0 / Resets: 0 (60s) / Reinits: 0`.

**Step 4b — `Pending` counter:**
1. Force-quit the iPhone app (swipe).
2. From Android, send 2 text messages in a 1:1 chat with iPhone.
3. Open Mesh Debug on Android. Status card shows `Pending: 2`.
4. Relaunch iPhone, give it ~5 s.
5. Reopen Mesh Debug on Android. `Pending: 0` (Phase 2.2 retry delivered).

**Step 4c — `Resets` counter:**
After step 4b, `Resets` should be ≥ 1 on iPhone (Phase 2.3 receiver-side stale recovery fired when iPhone got Android's stale-encrypted retried message). Open Mesh Debug on iPhone to verify.

**Step 4d — `Reinits` counter:**
Toggle WiFi off/on on either device. Reopen Mesh Debug. `Reinits` should be ≥ 1 (supervisor's connectivity hook fired).

- [ ] **Step 5: Open the PR**

Visit https://github.com/dvvolkovv/taler_id_mobile/compare/dev...feature/mesh-debug-screen-polish and open a PR with:

- **Title:** `mesh(debug): surface recovery counters (Pending / Resets / Reinits) on debug screen`
- **Body:**

```markdown
## Summary
- New `MeshDiscoverySupervisor.reinitCount` field — increments only on accepted reinits (rate-limited skips do not count).
- New `MeshMessagingService.peerResetCountTotal` getter — sliding-window sum across `_peerResetTimes` matching the existing `peerResetWindow` budget.
- `BonjourTransport` now exposes `discoveryReinitCount` proxy and is registered separately in DI alongside `MeshTransport` so the Mesh Debug screen can read it.
- Mesh Debug screen `_StatusCard` adds three rows: `Pending`, `Resets (60s)`, `Reinits`. Reads counters via DI on each rebuild — refreshes whenever a peer is discovered/lost, a message arrives, or start/stop is pressed.

## Test plan
- [x] Unit: `reinitCount` increments on accepted reinit but not on rate-limited skip; resumes incrementing after window slides.
- [x] Unit: `peerResetCountTotal` returns 4 after 4 garbage frames trigger 4 stale-recoveries within the window.
- [x] Hardware: counters update visibly during Phase 2.x recovery scenarios — `Pending` rises with offline peer, drops after reconnect; `Resets` rises after receiver-side recovery; `Reinits` rises on WiFi toggle.

## Notes
- Implements polish per spec `docs/superpowers/specs/2026-04-28-mesh-debug-screen-polish-design.md`.
- Mobile-only, no backend, DB or wire-format change.
- Picks up in v1.0.65.
```

---

## Self-review (run by author)

**Spec coverage:**
- `reinitCount` field + getter + increment placement → Task 1 Step 3. ✓
- `peerResetCountTotal` getter → Task 2 Step 3. ✓
- `BonjourTransport.discoveryReinitCount` proxy → Task 3 Step 1. ✓
- DI registration of `BonjourTransport` separately → Task 3 Step 2. ✓
- `_StatusCard` extended with three rows → Task 4 Steps 2–3. ✓
- Sliding-window semantics, increment-only-on-accepted, fallback-to-0 in DI guards → all preserved verbatim from spec. ✓
- Hardware smoke A/B/C/D → Task 5 Step 4. ✓

**Placeholder scan:** none.

**Type consistency:**
- Field names (`_reinitCount`, `peerResetCountTotal`, `discoveryReinitCount`, `pendingCount`, `resetCountTotal`) consistent across producer (service / supervisor / transport) and consumer (screen). ✓
- Constructor parameter names in `_StatusCard` match the call site exactly. ✓

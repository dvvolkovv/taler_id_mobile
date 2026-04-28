# Mesh Debug Screen Polish — Surface Recovery Counters

**Status:** Draft
**Date:** 2026-04-28
**Owner:** Dmitry Volkov
**Builds on:** Phase 2.1 (peer reset budget), Phase 2.2 (pending mesh queue), Phase 2.3 (receiver-side stale recovery), supervisor (discovery reinits).

## Goal

Surface three diagnostic counters on the existing **Mesh Debug** screen so the developer can see Phase 2.x recovery activity at a glance without grepping `flutter run` output.

After this change, the status card on the Mesh Debug screen shows:
- `Pending` — current size of `PendingMeshSendQueue`.
- `Resets (60s)` — total Noise-session resets across all peers within the current `peerResetWindow`.
- `Reinits` — total Bonsoir discovery reinits since service start (cold-start kicks + connectivity / lifecycle hooks).

## Non-Goals

- Per-peer breakdown of resets — aggregate only. Per-peer drill-down can be added later if needed.
- Reason breakdown for reinits (cold-start vs. connectivity vs. resumed) — total only. Reasons remain in logs.
- Live push streams from each service — UI refreshes on existing events (peer discover/lose, message in/out, start/stop).
- Persistence of counters across app restart — process-local only.
- Telemetry / remote reporting.

## Architecture Overview

| File | Role | New / Modified |
|---|---|---|
| `lib/core/mesh/transport/mesh_discovery_supervisor.dart` | Add `int _reinitCount` field + getter; increment in `_gatedReinit` after the rate-limit check passes | Modified |
| `lib/core/mesh/transport/bonjour_transport.dart` | Add `int get discoveryReinitCount => _supervisor?.reinitCount ?? 0;` proxy | Modified |
| `lib/core/mesh/services/mesh_messaging_service.dart` | Add `int get peerResetCountTotal` (sliding-window sum across `_peerResetTimes`) | Modified |
| `lib/features/mesh_debug/presentation/screens/mesh_debug_screen.dart` | Wire DI lookups + extend `_StatusCard` with three new `_kv` rows | Modified |
| `test/core/mesh/transport/mesh_discovery_supervisor_test.dart` | New test for counter increment semantics | Modified |
| `test/core/mesh/services/mesh_messaging_service_test.dart` | New test for `peerResetCountTotal` | Modified |

**Backwards compatibility:** purely additive. New getters; no signature changes; no DI rewiring beyond reading existing singletons.

## Counter semantics

### `MeshDiscoverySupervisor.reinitCount`

```dart
int _reinitCount = 0;
int get reinitCount => _reinitCount;

Future<void> _gatedReinit(String reason) async {
  final now = clock.now();
  final last = _lastReinitAt;
  if (last != null && now.difference(last) < rateLimit) {
    debugPrint('[mesh-discovery-supervisor] reinit skipped — within ${rateLimit.inSeconds}s rate-limit (reason=$reason)');
    return;
  }
  _lastReinitAt = now;
  _reinitCount++;  // count only successful (non-rate-limited) reinits
  await reinit(reason);
}
```

Increments **only** when the reinit actually fires (rate-limited skips do not count). Total since service construction; not bounded by any window.

### `BonjourTransport.discoveryReinitCount`

```dart
int get discoveryReinitCount => _supervisor?.reinitCount ?? 0;
```

Proxy. Returns `0` when supervisor is not yet attached (transport stopped).

### `MeshMessagingService.peerResetCountTotal`

```dart
/// Mesh Debug — total reset count across all peers in the current
/// `peerResetWindow`. Sliding window via DateTime comparison; matches
/// the budget that `_allowReset` enforces.
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

Sliding window, matches the `peerResetWindow` constructor parameter (default 60 s). Cheap: `_peerResetTimes` is bounded by `peerResetThreshold` entries per peer (default 5) plus the peer count.

The getter does **not** prune `_peerResetTimes` — pruning happens lazily in `_allowReset`. The getter only counts entries inside the window, so stale entries past the window are simply ignored.

### `PendingMeshSendQueue.pendingCount`

Already exposed (Phase 2.2). No change.

## UI integration

`_MeshDebugScreenState.build()` reads the three counters synchronously via DI on each rebuild:

```dart
final pendingQueue = sl<PendingMeshSendQueue>();
final messaging = sl<MeshMessagingService>();
final transport = sl<MeshTransport>();
// transport may not always be a BonjourTransport (BLE, MultiTransport in
// future). Use a safe cast that returns 0 when not the expected type.
final reinitCount = transport is BonjourTransport
    ? transport.discoveryReinitCount
    : 0;

// pass to _StatusCard:
_StatusCard(
  running: _running,
  bleEnabled: MeshConfig.bleEnabled,
  myPrefix: myPrefix,
  peerCount: _peers.length,
  pendingCount: pendingQueue.pendingCount,
  resetCountTotal: messaging.peerResetCountTotal,
  discoveryReinitCount: reinitCount,
)
```

`_StatusCard` adds three rows after the existing `Peers`:

```dart
_kv('Pending', '$pendingCount'),
_kv('Resets', '$resetCountTotal (60s)'),
_kv('Reinits', '$discoveryReinitCount'),
```

The screen rebuilds via `setState` whenever a peer is discovered/lost, a message arrives, or start/stop is pressed. That cadence is sufficient — counters update on every meaningful mesh event without a separate timer.

## Testing

### Unit — `mesh_discovery_supervisor_test.dart`

```dart
test('reinitCount increments on accepted reinit, not on rate-limited skip', () {
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

    // After window slides — accepted again.
    async.elapse(const Duration(seconds: 4));
    lifecycleCtrl
      ..add(AppLifecycleState.paused)
      ..add(AppLifecycleState.resumed);
    async.flushMicrotasks();
    expect(reinitCalls.length, 2);
    expect(supervisor.reinitCount, 2);
  });
});
```

### Unit — `mesh_messaging_service_test.dart`

Builds Alice & Bob, establishes a session, then injects N garbage data frames into Bob (each MAC-fails and triggers `_triggerStaleRecovery` which records a reset). After N frames within the same `peerResetWindow`, `peerResetCountTotal` returns `min(N, peerResetThreshold)`.

```dart
test('peerResetCountTotal counts resets within the window', () async {
  // setup Alice/Bob with established session, peerResetThreshold: 5
  // ... (see Phase 2.3 test for the warm-up dance)

  // Inject 4 garbage data frames into Bob.
  for (var i = 0; i < 4; i++) {
    bobT.injectInboundFrame(InboundFrame(
      srcPeer: alicePeer,
      type: FrameType.data,
      bytes: Uint8List.fromList(List<int>.generate(80, (j) => i * 11 + j)),
    ));
  }
  await Future<void>.delayed(const Duration(milliseconds: 300));

  // 4 within threshold=5 → all accepted → peerResetCountTotal == 4.
  expect(bob.peerResetCountTotal, 4);
});
```

### UI — not tested

Small visual addition. UI tests for the debug screen are out of scope.

## Hardware smoke (manual, after impl)

1. Open Mesh Debug on one device. Status card shows `Pending: 0 / Resets: 0 (60s) / Reinits: 0`.
2. Force-quit the peer device. Send a message in chat → reopen Mesh Debug. `Pending: 1` (or more).
3. Relaunch the peer. After mesh discovery + recovery → `Pending: 0`, `Resets: 1 (60s)`.
4. Toggle WiFi briefly to trigger supervisor connectivity reinit → `Reinits: ≥1`.

## Risks

1. **`MeshTransport` may not be a `BonjourTransport`** — the runtime DI registration could change to `MultiTransport` or `BleTransport`. *Mitigation:* type check + fallback to 0 in the screen.
2. **`peerResetCountTotal` reads `_peerResetTimes` without locking** — Dart is single-threaded; the map is mutated only from the same isolate. Safe.
3. **Counter semantics drift over time** — if `_allowReset` logic changes (e.g., per-peer thresholds), this getter may no longer match the underlying behavior. *Mitigation:* doc comment on getter pins the semantic to the existing window.

## Rollout

1. Branch `feature/mesh-debug-screen-polish` (already created).
2. TDD impl — 3 commits: supervisor counter, messaging service getter, UI extension.
3. Hardware smoke — see above.
4. PR → `dev`. Merge after spec & code reviews.
5. Picks up in v1.0.65.

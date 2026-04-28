# Mesh Debug Counter Fixes — UI Refresh & Pending Drain on Echo

**Status:** Draft
**Date:** 2026-04-28
**Owner:** Dmitry Volkov
**Builds on:** PR #9 (mesh-debug screen polish — Pending / Resets / Reinits counters)

## Goal

Fix two follow-ups identified during PR #9 hardware smoke (Redmi + iPhone wired, 2026-04-28):

1. **UI auto-refresh.** `MeshDebugScreen._StatusCard` rebuilds via `setState` only on inbound message / discovery / loss events. Outbound mesh-fanout success, peer resets on the receiver, and supervisor reinits don't trigger a rebuild — re-entering the screen also doesn't help (bottom-nav caches widget state). Counters update only on full app restart.
2. **`PendingMeshSendQueue` not drained when server-relay delivers.** Phase 2.2 enqueues an entry when no eligible mesh peers exist at first send, expecting `peerDiscovered` to flush via mesh fanout. If Socket.IO delivery beats mesh-rediscovery (typical when both devices regain internet faster than they re-Bonjour-discover each other), the entry stays in the in-memory queue until process restart. The `Pending` counter on the debug screen stays artificially elevated.

## Non-Goals

- Multi-device fanout correctness. The chosen drain semantic (Option A — drop on server echo) prematurely clears a queue entry if the same userId has another device that's mesh-only-reachable. Acceptable today (single-device default per CLAUDE.md memory); revisit when multi-device becomes common.
- Reset/reinit counter persistence across app restart. Process-local only, same as PR #9.
- Per-counter granular streams (`PendingMeshSendQueue.changes`, `MeshMessagingService.resetCountChanged`, etc.). Overkill for a debug screen.
- Removing the existing Phase 2.2 `markFannedOut`-based fanout tracking. Drop-on-echo runs alongside it: whichever fires first wins.

## Architecture overview

| File | Role | Change |
|---|---|---|
| `lib/features/mesh_debug/presentation/screens/mesh_debug_screen.dart` | Add a 1 Hz `Timer.periodic` in `initState`, cancel in `dispose`. While mounted, calls `setState((){})` so all three counters re-read from DI. | Modified |
| `lib/features/messenger/presentation/bloc/messenger_bloc.dart` | Inject `PendingMeshSendQueue` via `sl`. Inside `_onMessageReceived`, where the existing pending cleanup loop runs (`_pending.remove(tempId); _inFlightTempIds.remove(tempId);`), also call `_pendingMeshQueue.remove(tempId)`. | Modified |
| `test/messenger/messenger_bloc_test.dart` | New test — feed an echo `new_message` event matching a previously-enqueued mesh-pending clientTempId, assert `pendingMeshQueue.pendingCount` drops from 1 → 0. | Modified |

No new public APIs. No DI changes (`PendingMeshSendQueue` already registered as a singleton via PR #9 wiring path). No backend, DB, or wire-format change.

## Counter refresh semantics (Fix 1)

```dart
// _MeshDebugScreenState
Timer? _refreshTicker;

@override
void initState() {
  super.initState();
  _transport = sl<MeshTransport>();
  _meshKey = sl<MeshStaticKey>();
  // Mesh Debug — counters (Pending / Resets / Reinits) read fresh from DI on
  // each rebuild. Outbound mesh-fanout, supervisor reinits, and peer resets
  // on the receive side don't always coincide with a discovery / inbound
  // event, so we drive a 1 Hz tick to keep the status card honest.
  _refreshTicker = Timer.periodic(const Duration(seconds: 1), (_) {
    if (!mounted) return;
    setState(() {});
  });
}

@override
void dispose() {
  _refreshTicker?.cancel();
  // ... existing cancellations
  super.dispose();
}
```

1 Hz is plenty — the counters change at human-event cadence (toggle WiFi, app cold-start, etc.) and the rebuild cost is a single Card with six text rows.

## Pending drain on echo (Fix 2)

In `_onMessageReceived`, after the existing block that finds matching pending entries by `senderId + content` and calls `_pending.remove(tempId)`:

```dart
for (final tempId in removed) {
  _pending.remove(tempId);
  _inFlightTempIds.remove(tempId);
  // Mesh-pending drain — server echo ⇒ message reached the broker, which
  // routes to all online recipients. Mesh fanout retry is no longer
  // required for this clientId. (Edge case: multi-device user with one
  // device offline — server only delivered to online devices, but the
  // mesh-only path to the offline device is bypassed. Acceptable today
  // since most users have one device per account.)
  _pendingMeshQueue.remove(tempId);
}
```

DI injection as a field, mirroring the existing `_pending` pattern at the top of the bloc:

```dart
final PendingMeshSendQueue _pendingMeshQueue = sl<PendingMeshSendQueue>();
```

## Testing

### Bloc unit test (Fix 2)

Append to `test/messenger/messenger_bloc_test.dart` in the existing `MessengerBloc` group:

```dart
test('echo new_message drains matching mesh-pending entry', () async {
  final pendingMeshQueue = sl<PendingMeshSendQueue>();
  pendingMeshQueue.enqueue(
    clientId: 'temp-1',
    conversationId: 'conv-1',
    content: 'hi',
    sentAt: DateTime.utc(2026, 4, 28, 10),
  );
  expect(pendingMeshQueue.pendingCount, 1);

  // Inject echo via mocked repo's messages stream.
  bloc.add(MessageReceived(
    message: MessageEntity(
      id: 'srv-1',
      conversationId: 'conv-1',
      senderId: bloc.currentUserId,
      content: 'hi',
      sentAt: DateTime.utc(2026, 4, 28, 10),
      clientTempId: 'temp-1',
      // ... other required fields per project conventions
    ),
  ));
  await bloc.stream.firstWhere((s) => s.messages['conv-1']?.isNotEmpty == true);

  expect(pendingMeshQueue.pendingCount, 0);
});
```

Test setup must register `PendingMeshSendQueue` in the bloc test's DI scaffold — examples already exist in the file (search for `sl.registerSingleton`).

### UI — not unit-tested

`Timer.periodic` + setState is trivial; widget tests for `MeshDebugScreen` would need to stub `MeshTransport`, `MeshMessagingService`, `BonjourTransport`, `MeshStaticKey`, and `PendingMeshSendQueue`. Out of scope. Hardware smoke (4b re-run) covers it.

## Hardware smoke (manual)

Re-run PR #9 smoke 4b:

1. Force-quit iPhone app, send 2 msgs from Android, open Mesh Debug → `Pending: 2`.
2. Relaunch iPhone, wait ~5 s.
3. **Expected:** Android Mesh Debug shows `Pending: 0` *without* re-opening the screen — 1 Hz timer ticks, counter re-reads from DI, queue is now empty because echo arrived for both messages.
4. Toggle WiFi off/on while staying on the screen → `Reinits` increments live.

## Risks

1. **`Timer.periodic` while screen is in background.** `mounted` guard handles widget unmount; navigation push/pop pauses Flutter rendering anyway. No leak.
2. **Multi-device false-positive drain.** Documented in non-goals; revisit when multi-device usage grows.
3. **Race: echo arrives between `enqueue` and `markFannedOut`.** Both end up calling `remove` — first one wins, second is a no-op (`Map.remove` on missing key returns null). Safe.

## Rollout

1. Branch `fix/mesh-debug-counter-fixes` from `dev`.
2. TDD impl — 2 commits: bloc echo-drain (with test), debug screen 1 Hz refresh.
3. Hardware smoke — re-run PR #9 4b on Redmi + iPhone wired, expect `Pending: 0` without screen re-entry.
4. PR → `dev`. Merge after review.
5. Picks up in v1.0.65 (same release as PR #9).

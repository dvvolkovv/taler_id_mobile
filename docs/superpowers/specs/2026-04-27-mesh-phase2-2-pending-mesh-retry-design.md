# Mesh Phase 2.2 — Pending Mesh Send Retry on `PeerDiscovered`

**Status:** Draft
**Date:** 2026-04-27
**Owner:** Dmitry Volkov
**Builds on:** Phase 2 group chats (commit `61e23a4`), Phase 2.1 discovery & handshake resilience (commit `d82ad17`).

## Goal

Stop losing mesh-sendable text messages that were submitted while no peer was visible. After Phase 2.1 the bonsoir cold-start window is bounded (~5–35 s with the watchdog), but messages sent inside that window are still dropped from the mesh path because `_meshFanout` exits early on `eligible.isEmpty`. This phase adds a small in-memory retry queue: such messages are re-attempted as soon as the relevant peer surfaces via `PeerDiscovered`.

After this phase, the user-visible result for the smoke-test scenario "send 2 messages while peer is offline, then bring peer back within 30 s" is: both messages arrive over mesh, no chat reload required, no server fanback needed.

## Non-Goals

- Persistence across app restarts. Queue is in-memory only.
- Retry of attachments / file messages. Phase 2 keeps those on the server path; we keep the same boundary.
- Retry of server-failed messages (the `MessengerBloc._resendPending` path already handles socket reconnect).
- Per-message UI indication of "queued for mesh retry" — the existing pending-clock icon is sufficient.
- Auto-cleanup on message edit / delete. The TTL handles the orphan; explicit `remove()` exists for hygiene but isn't wired into edit/delete in this phase.
- Increasing or unifying the cross-transport dedup window beyond the existing 10 s — Phase 2 dedup remains as-is.

## Architecture Overview

One new file plus minor wiring:

| File | Role | New / Modified |
|---|---|---|
| `lib/features/messenger/data/services/pending_mesh_send_queue.dart` | In-memory retry queue with TTL + per-peer fan-out tracking | New |
| `lib/features/messenger/data/services/mesh_messenger_adapter.dart` | Expose a `Stream<AdaptedPeerDiscovered>` so the repo can react to peer arrivals | Modified |
| `lib/features/messenger/data/repositories/messenger_repository_impl.dart` | Enqueue on `eligible.isEmpty`; subscribe to `peerDiscovered` and re-fanout matching pending entries | Modified |
| `lib/core/di/service_locator.dart` | Register `PendingMeshSendQueue`, wire dependency into `MessengerRepositoryImpl` | Modified |
| `test/features/messenger/data/services/pending_mesh_send_queue_test.dart` | Unit tests for queue API | New |
| `test/features/messenger/data/repositories/messenger_repository_impl_pending_mesh_test.dart` | Integration tests for enqueue + retry hooks | New |

**Backwards compatibility:** purely runtime, mobile-only, no wire-format change. A peer running v1.0.62 (no Phase 2.2) still works — they emit `PeerDiscovered` for us as before, and we fan out as before; we just have a queue locally now.

## Eligibility — what enters the queue

Only messages that satisfy **all** of:

1. Text message (no `fileUrl` / `s3Key`) — same as Phase 2 mesh fanout scope.
2. `clientTempId != null` — we need a stable identifier to track per-peer fanout.
3. At first send, `_meshFanout` saw `eligible.isEmpty` (no visible peers in the conversation participant set). This is the trigger condition; messages that fanned out to at least one peer at first send do **not** enter the queue.

This matches user intent: the queue is the recovery path for the cold-start window, not a generic mesh retransmission layer.

## TTL — how long an entry stays live

30 seconds from `sentAt`. Rationale:

- Phase 2.1 cold-start watchdog: 5 / 10 / 15 s = up to ~30 s of recovery attempts before discovery is declared dead.
- Server fanback typically delivers in seconds when up; if both server and mesh fail for 30 s, the user has already moved on and a late mesh delivery would surprise more than help.
- The cross-transport dedup window is 10 s; running the retry queue past 30 s would risk re-displaying messages on the receiver if mesh delivery races with a slow server delivery. Keeping the queue window inside one window-stretch of dedup-tolerance is intentional.

Cleanup is **lazy**: every `enqueue` and `dueFor` call purges expired entries first. No background timer.

## Per-peer fan-out tracking

Each entry holds a `Set<String> fannedOutTo` of `contactUserId`s that already received this message via mesh. When a `PeerDiscovered` arrives:

- For each entry where `expiresAt > now` AND the peer is in the entry's conversation participants AND the peer is not in `fannedOutTo` — fan out.
- On a successful send, call `markFannedOut(clientId, peerUserId)`. The method returns `bool isFirstFanout` — `true` if the set was empty before this call. The repo uses that signal to call `_meshAdapter.emitOutbound` exactly once per `clientId` (mirroring Phase 2's "one outbound per logical send" rule).
- On a send failure: log, leave `fannedOutTo` unchanged. Next `PeerDiscovered` for the same peer triggers another attempt — until TTL expires.

## `PendingMeshSendQueue` public API

```dart
class PendingMeshSendQueue {
  PendingMeshSendQueue({Duration ttl = const Duration(seconds: 30)});

  void enqueue({
    required String clientId,
    required String conversationId,
    required String content,
    required DateTime sentAt,
  });

  Iterable<PendingMeshSendEntry> dueFor({
    required String peerUserId,
    required Iterable<String> Function(String conversationId) participantsOf,
  });

  /// Returns true if this peer is the first to be marked for [clientId]
  /// (i.e. the entry's fanout-set was empty before this call). The repo
  /// uses that signal to emit a single AdaptedOutboundMessage that
  /// converts the sender's `temp_<uuid>` placeholder into `mesh-out-<uuid>`.
  bool markFannedOut({required String clientId, required String peerUserId});

  void remove(String clientId);

  int get pendingCount;
}

class PendingMeshSendEntry {
  final String clientId;
  final String conversationId;
  final String content;
  final DateTime sentAt;
}
```

Behaviour notes:

- `enqueue` overwrites any existing entry with the same `clientId`. Defensive, prevents queue bloat from duplicate enqueue calls.
- `dueFor` is the only read path and applies all filters in one pass: TTL purge, participant check, `fannedOutTo` exclusion. The caller does not need to coordinate.
- `markFannedOut` on a `clientId` that no longer exists (already TTL'd or removed) is a no-op and returns `false`.
- `remove` is provided for explicit cleanup (e.g. message edit/delete in a future phase) but is not wired in 2.2.

## Trigger flow

### Enqueue (in `MessengerRepositoryImpl._meshFanout`)

```dart
if (eligible.isEmpty) {
  if (clientTempId != null) {
    _pendingMeshQueue.enqueue(
      clientId: clientTempId,
      conversationId: conversationId,
      content: content,
      sentAt: now,
    );
    debugPrint('[mesh-fanout] no eligible peers — enqueued for retry (clientId=$clientTempId)');
  }
  return;
}
```

### Re-fanout (in `MessengerRepositoryImpl._onMeshPeerDiscovered`)

```dart
Future<void> _onMeshPeerDiscovered(AdaptedPeerDiscovered ev) async {
  final due = _pendingMeshQueue.dueFor(
    peerUserId: ev.contactUserId,
    participantsOf: (convId) =>
        _cache.getConversationById(convId)?.participantIds ?? const [],
  );
  for (final entry in due) {
    final envelope = Envelope(
      version: 1,
      type: 'text',
      convId: entry.conversationId,
      clientId: entry.clientId,
      text: entry.content,
      sentAt: entry.sentAt,
    );
    try {
      await _meshAdapter.sendEnvelopeToPeer(
        peerDevicePk: ev.devicePk,
        contactUserId: ev.contactUserId,
        envelope: envelope,
      );
      final isFirst = _pendingMeshQueue.markFannedOut(
        clientId: entry.clientId,
        peerUserId: ev.contactUserId,
      );
      if (isFirst) {
        // Sender-side UI: temp_<uuid> → mesh-out-<uuid>, exactly once.
        final outboundId = entry.clientId.startsWith('temp_')
            ? 'mesh-out-${entry.clientId.substring(5)}'
            : 'mesh-out-${entry.clientId}';
        _meshAdapter.emitOutbound(AdaptedOutboundMessage(
          id: outboundId,
          conversationId: entry.conversationId,
          contactUserId: ev.contactUserId,
          clientTempId: entry.clientId,
          text: entry.content,
          sentAt: entry.sentAt,
        ));
      }
      debugPrint('[mesh-retry] delivered ${entry.clientId} to ${ev.contactUserId}');
    } catch (e) {
      debugPrint(
          '[mesh-retry] send to ${ev.contactUserId} failed: $e (will retry on next discover)');
    }
  }
}
```

### `MeshMessengerAdapter` change

Expose a new broadcast stream:

```dart
Stream<AdaptedPeerDiscovered> get peerDiscovered;

class AdaptedPeerDiscovered {
  final PeerId devicePk;
  final String contactUserId; // resolved via ContactKeyStore
  AdaptedPeerDiscovered({required this.devicePk, required this.contactUserId});
}
```

The adapter subscribes to the underlying transport's `discoveries` stream, filters to peers it can resolve to a `contactUserId`, and re-broadcasts. Already-emitted Phase 2 logic remains intact.

## Testing

### Unit — `pending_mesh_send_queue_test.dart`

- `enqueue` + `dueFor` returns the entry for a visible participant.
- `dueFor` filters by participation: peer not in conversation → not returned.
- `enqueue` with the same `clientId` overwrites, does not duplicate.
- TTL: an entry with `sentAt + ttl < now` is not returned and is purged.
- `markFannedOut` excludes the peer from subsequent `dueFor`.
- `markFannedOut` returns `true` on first call, `false` thereafter.
- `markFannedOut` on a missing/expired `clientId` returns `false` and is a no-op.
- `remove` drops the entry; `pendingCount` reflects state.

### Integration — `messenger_repository_impl_pending_mesh_test.dart`

- `sendMessage` text-only, no eligible peers → `pendingMeshQueue.enqueue` called with the correct args.
- `sendMessage` with attachment → not enqueued (text-only filter).
- `sendMessage` with `clientTempId == null` → not enqueued.
- `sendMessage` with eligible peers (Phase 2 path still active) → not enqueued.
- Repo subscribes to `_meshAdapter.peerDiscovered` on construction.
- Discovery event for a peer that is in a queued conversation → `sendEnvelopeToPeer` called.
- First successful retry → `emitOutbound` called once (with `mesh-out-` id).
- Second discovery event for a different peer in the same `clientId`'s conversation → `sendEnvelopeToPeer` called for the new peer, `emitOutbound` not called again.
- Discovery event for a peer not in any pending entry's participants → no `sendEnvelopeToPeer` call.
- Send failure during retry → `markFannedOut` not called (entry stays for next attempt).

### Hardware smoke (manual, before merge)

**Scenario A — happy path (mesh-only):**
1. dev backend stopped (`pm2 stop taler-id-dev`).
2. Android Redmi has the app open in a 1:1 chat with iPhone wired. iPhone app is force-quit.
3. Send 2 text messages from Android.
4. Android log: `[mesh-fanout] no eligible peers — enqueued for retry` for both `clientId`s.
5. Launch iPhone app. Within ~30 s, Android log shows `[mesh-retry] delivered <clientId> to <userId>` for both messages.
6. iPhone displays both messages. No bilateral restart, no chat reload.

**Scenario B — server-up (regression):**
1. dev backend running.
2. Same setup, send 2 messages from Android while iPhone is force-quit.
3. iPhone gets the messages via server when it comes back.
4. Even if Android also retries via mesh (TTL not expired), iPhone's existing dedup (clientId-based bloc filter + cross-transport heuristic) drops the duplicates.
5. No double messages on iPhone.

### Acceptance

- All existing 413+ unit tests still green.
- New unit + integration tests green.
- Both hardware scenarios pass.

## Risks

1. **Double delivery via two transports.** Server fanback delivers, mesh retry also delivers within 10 s. Existing dedup heuristic catches it. *Risk reduction:* keep TTL ≤ 30 s, verify hardware Scenario B.
2. **Memory growth.** Lazy cleanup runs only when `enqueue` or `dueFor` is called. If discovery is silent for hours, expired entries linger. *Risk reduction:* enqueue path runs on every send and is the realistic ingress; idle queue with stale entries holds maybe a few KB. Acceptable for v0; revisit if telemetry says otherwise.
3. **Race between concurrent `PeerDiscovered` for the same peer.** Two simultaneous handlers race on `markFannedOut`. *Risk reduction:* `Set`-based bookkeeping is naturally idempotent on insertion. The first call returns `true`, the second `false` — `emitOutbound` is invoked exactly once.
4. **Message editing during retry window.** User edits a queued message; the retry uses the original content. *Risk reduction:* not addressed in this phase. Server eventually delivers the edit; the small mesh-vs-edit divergence is short-lived and rare. `remove(clientId)` is provided for a future wiring.
5. **`PeerDiscovered` for an unknown peer (not in `ContactKeyStore`).** Adapter filters those out before re-broadcasting; the repo never sees them.

## Rollout

1. Branch `feature/mesh-phase2-2-pending-mesh-retry` (already created from current `dev`).
2. TDD implementation per writing-plans, unit + integration tests green.
3. Hardware smoke Scenarios A and B on Android Redmi + iPhone wired.
4. PR → `dev`. Merge after spec & code reviews.
5. The feature lands on `dev` for the next mobile release (the in-flight v1.0.63 may or may not pick it up — release manager's call). Mobile-only, no backend or DB change.

## Post-Merge Observability

- `PendingMeshSendQueue.pendingCount` exposed via existing Mesh Debug screen.
- `[mesh-retry]` log lines for delivered / failed retries — visible in flutter run output and via the Mesh Debug screen if it grows a log panel later.

These are diagnosis-only hooks; no telemetry leaves the device.

# Mesh Phase 2.3 — Receiver-side Stale-Session Recovery

**Status:** Draft
**Date:** 2026-04-28
**Owner:** Dmitry Volkov
**Builds on:** Phase 2.1 accept-latest-init (commit `d82ad17`), Phase 2.2 retry queue + serialised inbound (commit `d664d38`).

## Goal

Make the mesh receiver self-heal when the sender's cached Noise session no longer matches the receiver's state. Today such frames silently drop or log `decrypt failed: SecretBoxAuthenticationError (MAC)` and the message never arrives. Phase 2.1's "accept-latest-init" only fires when the *peer* sends a fresh `handshake_init` — receivers that just listen never trigger that path. Phase 2.3 closes the loop: when a receiver sees a `data` frame it cannot decrypt, it initiates a fresh handshake to the sender, which the sender then accepts via Phase 2.1, restoring delivery without bilateral restart.

After this phase, a force-quit + relaunch on either device is sufficient to keep mesh delivery working — the user no longer has to restart the other side.

## Non-Goals

- Wire-format or Noise-protocol changes.
- Phase 2.2 retry queue changes (it is independent and continues to work; the new handshake restores the path the queue uses).
- UI indication of "re-handshaking in progress" — implicit in the existing pending-clock → checkmark transition.
- Persistence of recovery state across app restart — recovery is reactive on the next bad frame.
- Generic protection against arbitrary garbage frames from non-contacts — `_onInboundFrame` already filters unknown `srcDevice` upstream.

## Architecture Overview

One file changes:

| File | Role | New / Modified |
|---|---|---|
| `lib/core/mesh/services/mesh_messaging_service.dart` | New `_triggerStaleRecovery` helper; two call sites in the `data` branch of `_onInboundFrame` | Modified |
| `test/core/mesh/services/mesh_messaging_service_test.dart` | New unit tests | Modified |

No new types, no DI changes, no spec changes elsewhere.

**Backwards compatibility:** purely runtime, mobile-only. A peer running v1.0.64 (no Phase 2.3 receiver) talks to a v1.0.65 sender (Phase 2.3 receiver) without any incompatibility — Phase 2.3 only changes what the *receiver* does on its own bad-frame path; the sender wire is identical.

## Trigger conditions

The recovery triggers on the `FrameType.data` branch in `_onInboundFrame`, in **two** places:

1. **`state.session == null`** — the receiver has no Noise session for the sender at all. Most common cause: receiver restarted; sender still holds a cached session and is encrypting with old keys.
2. **`decrypt` throws** (catch-all `catch (e)`) — sender's encrypted frame fails MAC check on the receiver. Most common cause: sender's session is stale relative to receiver's fresh session, or vice versa.

The `on FormatException catch (e)` branch (envelope JSON decode failed *after* successful decrypt) does **not** trigger recovery. A successful decrypt with a malformed payload is not a session-mismatch signal — it's a sender bug or attack, and re-handshaking would not help.

## `_triggerStaleRecovery` helper

```dart
/// Phase 2.3 — peer's data frame can't be decrypted (no session OR MAC
/// failure). The most likely cause is that one side restarted while the
/// other kept a cached Noise session, so keys no longer match. Reset
/// our own state and initiate a fresh handshake; Phase 2.1's
/// accept-latest-init on the peer side handles the rest.
///
/// Rate-limited via _allowReset (5 in 60s per peer) — same backoff
/// budget Phase 2.1 uses for peer-initiated resets, so a flapping or
/// adversarial peer can't drive a handshake storm.
void _triggerStaleRecovery(
  PeerId devicePk,
  _PeerState state, {
  required String reason,
}) {
  if (!_allowReset(devicePk)) return;
  debugPrint(
    '[mesh-handshake] receiver-side stale recovery '
    '(reason=$reason) pk=${devicePk.toHex().substring(0, 12)}...',
  );
  _resetPeerState(devicePk);
  // Fire-and-forget; if init fails (transport issue) the next bad frame
  // will retry.
  // ignore: unawaited_futures
  _initiateHandshake(devicePk, state).catchError((Object e) {
    debugPrint('[mesh-handshake] stale recovery init failed: $e');
  });
}
```

## `_onInboundFrame` data branch — final shape

```dart
if (frame.type == FrameType.data) {
  if (state.session == null) {
    debugPrint('[mesh-frame] data frame but no session — triggering recovery');
    _triggerStaleRecovery(srcDevice, state, reason: 'no-session');
    return;
  }
  try {
    final pt = await state.session!.decrypt(frame.bytes);
    final envelopeJson = jsonDecode(utf8.decode(pt)) as Map<String, dynamic>;
    final envelope = Envelope.fromJson(envelopeJson);
    debugPrint('[mesh-frame] decrypted envelope, emitting InboundEnvelope convId=${envelope.convId}');
    _inboundCtrl.add(InboundEnvelope(fromUserPk: srcDevice, envelope: envelope));
  } on FormatException catch (e) {
    // Decrypt succeeded, but JSON envelope decode failed. Not a stale-
    // session signal — sender produced malformed payload. Drop only.
    debugPrint('[mesh-frame] envelope decode failed: $e');
  } catch (e) {
    debugPrint('[mesh-frame] decrypt failed: $e — triggering recovery');
    _triggerStaleRecovery(srcDevice, state, reason: 'mac-error');
  }
  return;
}
```

## Interaction with existing logic

**Phase 2.1 accept-latest-init (sender side).** When the receiver's `_initiateHandshake` writes a fresh msg1 to the sender, the sender's `_onInboundFrame` handshake branch detects `hasCachedSession || hasCachedResponderHandshake` → calls `_resetPeerState(srcDevice)` → enters the responder path → finalises with fresh keys → sends msg2. Receiver completes its initiator handshake on msg2 → fresh session both sides.

**Phase 2.1 anti-thrash jitter.** Receiver's `_initiateHandshake` is called with the existing `state` object. Inside, the jitter delays the outbound msg1 by `random(0..recoveryInitJitter)` if `state.hadPriorSession` is true. We must verify `_resetPeerState` does **not** clear `hadPriorSession` — if it does, the jitter won't apply on the very first recovery and a simultaneous bilateral restart could thrash. (Verification step is in the implementation plan; if cleared, fix is one line.)

**Phase 2.1 backoff (`_allowReset`).** Shared between peer-initiated resets and our receiver-side recovery. The 5-in-60-s budget covers both. In the worst case (peer keeps restarting *and* receiver keeps seeing bad frames), some recoveries are dropped for up to ~60 s. Pending text messages remain in Phase 2.2's queue and retry on the next `peerDiscovered` event after the budget slides — no data loss, only short delay.

**Phase 2.2 inbound serialisation.** `_frameTail` ensures `_onInboundFrame` invocations execute sequentially. Multiple bad frames in a burst will each call `_triggerStaleRecovery` in order, but `_allowReset` will accept only the first 5 within the window. Subsequent calls are silent no-ops until the budget slides.

**Phase 2.2 retry queue.** Independent of the handshake. After a successful recovery, the next time the sender's `peerDiscovered` fires (or the next `sendEnvelope` to this peer), pending entries fan out and decrypt cleanly on the new session.

## Testing

### Unit tests (`test/core/mesh/services/mesh_messaging_service_test.dart`)

**Test A — `session==null` triggers recovery and re-establishes session.**

1. Build Alice and Bob, both with `_FakeTransport`. Establish a session by sending one envelope Alice→Bob.
2. Simulate Bob restart: `bob.dispose()`; build a new `bob2` with the same keys, on a fresh `_FakeTransport` whose `partner` is Alice's transport (and Alice's transport's partner is updated to Bob2's).
3. From Bob2 emit a `PeerDiscovered` for Alice via the fake transport.
4. From Alice (still holding the old session for Bob) call `sendEnvelope` — Alice encrypts with old keys.
5. Bob2 receives the data frame, sees `state.session == null`, calls `_triggerStaleRecovery`.
6. Bob2 sends msg1 to Alice. Alice's Phase 2.1 logic resets and processes msg1 as responder; sends msg2 back.
7. Bob2 finalises as initiator → fresh session.
8. Assert: Alice next `sendEnvelope` to Bob2 → Bob2's `inbound` stream emits an `InboundEnvelope` with the new payload.

**Test B — rate-limit caps recovery storm.**

1. Build Alice, Bob with overridden `peerResetThreshold: 3, peerResetWindow: 1.second` to make the test fast and deterministic.
2. Establish a session.
3. Manually corrupt Bob's session ciphertext expectations: simplest path is to construct an `InboundFrame` with `FrameType.data` and random bytes (decryption guaranteed to MAC-fail) and push it into Bob's transport `_inbound` controller 5 times.
4. Assert: only the first 3 trigger an outbound msg1 from Bob to Alice (via `_FakeTransport.partner._inbound` count of `FrameType.handshake` frames sent by Bob), the rest are dropped.

**Test C — `FormatException` does NOT trigger recovery.**

1. Set up Alice and Bob with an established session.
2. Construct a payload that will encrypt cleanly but decode as malformed JSON: send Alice → Bob with `Envelope` whose `text` is a valid string but, on the wire, replace the encrypted payload bytes such that `decrypt` succeeds (impossible to forge from outside without keys). **Alternative:** call Alice's transport `_inbound` directly with a hand-crafted `InboundFrame` whose `bytes` is the result of Alice's session encrypting `Uint8List.fromList(utf8.encode("not-json"))`. Bob's decrypt will succeed, JSON decode will throw `FormatException`.
3. Assert: no outbound `FrameType.handshake` from Bob (i.e., partner's `_inbound` count of handshake frames stays at the pre-test value).

If Test C proves too fiddly to set up reliably (constructing a one-shot Alice→Bob encrypt requires reaching into private session state), it may be downgraded to a `// TODO regression test` comment in the implementation file with a manual hardware verification.

### Hardware smoke (manual, before merge)

**Scenario A — receiver restart, sender stale session.**
1. dev backend up. Android Redmi + iPhone wired both online in a 1:1 chat. Exchange one message each direction so both have a session.
2. Force-quit iPhone app (swipe).
3. From Android, send a text message. Android log expected: `[mesh-frame]` no errors on send (Android still has cached session, encrypts and sends).
4. Relaunch iPhone app (via `flutter run` or home-icon for a previously-installed dev build).
5. iPhone's bonjour discovers Android. Android's Phase 2.2 retry kicks (no eligible peer at send time, queue holds the message). Android delivers via mesh. iPhone receives, but `state.session == null` → `_triggerStaleRecovery` → iPhone sends msg1 to Android.
6. Android (Phase 2.1) accepts the fresh init, becomes responder, sends msg2.
7. iPhone finalises. Next data frames from Android decrypt cleanly.
8. Assert (visual): the message lands in the iPhone chat without bilateral restart.

**Scenario B — both online, no regression.**
1. Both Android and iPhone running, mesh sessions live.
2. Send text both directions. No `[mesh-handshake] receiver-side stale recovery` log lines should appear on either side. Expected: normal Phase 2 fanout + decrypt.

### Acceptance

- Unit Tests A and B green; Test C green or downgraded to manual.
- Hardware Scenario A: message delivered without bilateral restart, with `[mesh-handshake] receiver-side stale recovery` log on iPhone.
- Hardware Scenario B: no spurious recovery triggers.
- Existing 432 unit tests stay green.

## Risks

1. **`_resetPeerState` clears `hadPriorSession`.** If true, Phase 2.1 anti-thrash jitter doesn't apply on the first recovery init. Two simultaneous recoveries (both sides restarted) could thrash. *Mitigation:* the implementation plan includes a verification step on `_resetPeerState`'s implementation; if `hadPriorSession` is cleared, preserve it across reset (one-line fix). The 5-in-60-s backoff also caps thrash regardless.

2. **`_allowReset` budget shared with Phase 2.1.** Peer keeps restarting AND we keep getting bad frames → budget exhausts in ~60 s window. *Mitigation:* pending Phase 2.2 entries remain queued; recovery resumes when window slides.

3. **Recovery against an attacker.** Attacker on local network could send garbage encrypted-looking frames to make us initiate handshakes. *Mitigation:* `_initiateHandshake` uses Noise IK which requires knowing the responder's static public key (we know peer's pk because peer is in `ContactKeyStore` — only known peers reach `_onInboundFrame` past the upstream filter). Garbage-from-stranger doesn't reach us.

4. **Spurious recovery from a freshly-decrypt-failed frame caused by something other than stale session** — e.g., a Noise library bug producing wrong ciphertext. Recovery would attempt re-handshake unnecessarily. *Mitigation:* `_allowReset` caps the cost; if the bug is genuine, we'd see it in logs and investigate.

## Rollout

1. Branch `feature/mesh-phase2-3-stale-session-recovery` (already created from `dev` after merge of PR #6 vanish-on-ack fix).
2. TDD implementation per writing-plans, unit tests A + B green, C if feasible.
3. Hardware smoke Scenarios A and B on Android Redmi + iPhone wired.
4. PR → `dev`. Merge after spec & code reviews.
5. Picks up in the next release (1.0.65).

## Post-merge observability

- `[mesh-handshake] receiver-side stale recovery` log lines — frequency tells us if Phase 2.1 stability degrades. High counts indicate a primary cause to investigate (peer flapping, corrupted keys, etc.).
- No telemetry leaves the device.

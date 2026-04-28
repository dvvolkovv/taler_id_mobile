# Mesh Phase 2.3 — Receiver-side Stale-Session Recovery Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make a mesh receiver self-heal when a sender's data frame can't be decrypted (no session, or MAC failure). Receiver resets local state and initiates a fresh handshake; Phase 2.1's accept-latest-init on the sender finishes the recovery without bilateral restart.

**Architecture:** Add one private helper `_triggerStaleRecovery(devicePk, state, reason)` to `MeshMessagingService`. Call it from two places in the `data` branch of `_onInboundFrame` — when `state.session == null` and when `decrypt` throws (catch-all). The helper rate-limits via the existing `_allowReset` (Phase 2.1 budget), then resets state and fires `_initiateHandshake`. No new types, no DI changes, no wire-format changes.

**Tech Stack:** Dart/Flutter, `flutter_bloc`, `cryptography` (Noise IK), `flutter_test`, `mocktail`. Mobile-only.

**Spec:** `docs/superpowers/specs/2026-04-28-mesh-phase2-3-stale-session-recovery-design.md`

**Branch:** `feature/mesh-phase2-3-stale-session-recovery` (already created from `dev` at the spec commit).

**File map:**

| File | Role | New / Modified |
|---|---|---|
| `lib/core/mesh/services/mesh_messaging_service.dart` | New `_triggerStaleRecovery` helper + 2 call sites in `_onInboundFrame` | Modified |
| `test/core/mesh/services/mesh_messaging_service_test.dart` | New unit tests (recovery + rate-limit) | Modified |

**Pre-condition verified during spec phase:** `_resetPeerState` (line 303) clears `handshake`, `session`, `isInitiator`, `initiating`, `sessionEstablished` but **does not clear `hadPriorSession`**. Phase 2.1 anti-thrash jitter therefore continues to apply on the recovery init.

---

## Task 1: Add `_triggerStaleRecovery` helper + integrate `session==null` trigger (TDD)

**Files:**
- Modify: `lib/core/mesh/services/mesh_messaging_service.dart`
- Modify: `test/core/mesh/services/mesh_messaging_service_test.dart`

- [ ] **Step 1: Write the failing test**

Append a new group at the bottom of `test/core/mesh/services/mesh_messaging_service_test.dart` (before the final closing `}` of `main()`):

```dart

  group('Phase 2.3 stale-session recovery', () {
    test('session==null on receiver triggers re-handshake; next send delivers',
        () async {
      final (alicePriv, alicePub) = await _x25519Keys();
      final (bobPriv, bobPub) = await _x25519Keys();
      final alicePeer = PeerId(alicePub);
      final bobPeer = PeerId(bobPub);

      final aliceStore = ContactKeyStore()
        ..addContact(userPk: bobPeer, devicePks: [bobPeer]);
      final bobStore = ContactKeyStore()
        ..addContact(userPk: alicePeer, devicePks: [alicePeer]);

      // Step 1: establish a session between Alice and Bob.
      final aliceT = _FakeTransport();
      var bobT = _FakeTransport();
      aliceT.partner = bobT;
      bobT.partner = aliceT;

      final alice = MeshMessagingService(
        transport: aliceT,
        contactKeyStore: aliceStore,
        myDevicePrivateKey: alicePriv,
        myDevicePublicKey: alicePub,
      );
      var bob = MeshMessagingService(
        transport: bobT,
        contactKeyStore: bobStore,
        myDevicePrivateKey: bobPriv,
        myDevicePublicKey: bobPub,
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

      final firstAtBob = bob.inbound.first;
      await alice.sendEnvelope(
        toUserPk: bobPeer,
        envelope: Envelope(
          version: 1,
          type: 'text',
          convId: 'conv-recovery',
          clientId: 'msg-warmup',
          text: 'warm up',
          sentAt: DateTime.parse('2026-04-28T10:00:00Z'),
        ),
      );
      await firstAtBob;

      // Step 2: simulate Bob restart. Build a fresh Bob with the same
      // keys but a new transport. Update Alice's partner pointer to the
      // new Bob transport. Crucially: Alice still holds her cached
      // session for Bob — that's the stale state we're testing.
      await bob.dispose();
      final newBobT = _FakeTransport();
      aliceT.partner = newBobT;
      newBobT.partner = aliceT;
      bobT = newBobT;

      bob = MeshMessagingService(
        transport: bobT,
        contactKeyStore: bobStore,
        myDevicePrivateKey: bobPriv,
        myDevicePublicKey: bobPub,
      );
      await bob.start(serviceName: 'Bob');

      // Step 3: tell Bob about Alice via discovery so Bob's _peerStates
      // gets seeded. (Without this, Bob's recovery init wouldn't find a
      // _PeerState slot — _onInboundFrame creates one on demand, so this
      // is belt-and-suspenders.)
      bobT.emitDiscovery(PeerDiscovered(
        peerId: alicePeer,
        host: '127.0.0.1',
        port: 0,
      ));

      // Step 4: Alice (with stale session) sends a new envelope. Bob's
      // session==null path triggers recovery. After re-handshake, the
      // NEXT envelope from Alice should decrypt cleanly.
      final receivedAfterRecovery = bob.inbound.first;
      await alice.sendEnvelope(
        toUserPk: bobPeer,
        envelope: Envelope(
          version: 1,
          type: 'text',
          convId: 'conv-recovery',
          clientId: 'msg-stale',
          text: 'sent with stale keys',
          sentAt: DateTime.parse('2026-04-28T10:00:01Z'),
        ),
      );

      // Bob's recovery happens on this incoming frame. The frame itself
      // is dropped (it can't be decrypted), but Bob immediately fires
      // msg1 to Alice. Alice's Phase 2.1 logic resets and responds with
      // msg2. Bob finalises. Then Alice's NEXT send arrives cleanly.
      // We give the round-trip a moment to settle, then send again.
      await Future<void>.delayed(const Duration(milliseconds: 200));

      await alice.sendEnvelope(
        toUserPk: bobPeer,
        envelope: Envelope(
          version: 1,
          type: 'text',
          convId: 'conv-recovery',
          clientId: 'msg-recovered',
          text: 'after recovery',
          sentAt: DateTime.parse('2026-04-28T10:00:02Z'),
        ),
      );

      final got = await receivedAfterRecovery
          .timeout(const Duration(seconds: 3));
      // The first inbound after recovery is whichever decrypted first.
      // It must NOT be the stale 'msg-stale' (that one MAC-failed and
      // was dropped) — it must be 'msg-recovered'.
      expect(got.envelope.clientId, 'msg-recovered');
      expect(got.envelope.text, 'after recovery');

      await alice.dispose();
      await bob.dispose();
    });
  });
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `cd /Users/dmitry/Downloads/taler_id_mesh && flutter test test/core/mesh/services/mesh_messaging_service_test.dart --plain-name 'session==null on receiver'`
Expected: TimeoutException after 3 seconds — Bob's `inbound` stream never emits `msg-recovered` because his current code drops `session==null` frames silently and never recovers, so subsequent encrypted sends from Alice also can't decrypt on Bob.

- [ ] **Step 3: Add `_triggerStaleRecovery` helper**

In `lib/core/mesh/services/mesh_messaging_service.dart`, find the existing `_resetPeerState` method (around line 303). Insert the new helper immediately before it:

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

- [ ] **Step 4: Wire the `session==null` trigger**

In the same file, find the `data` branch of `_onInboundFrame` — specifically the early-return for `state.session == null` (around line 250–253). Replace:

```dart
    if (frame.type == FrameType.data) {
      if (state.session == null) {
        debugPrint('[mesh-frame] data frame but no session — dropped');
        return;
      }
```

With:

```dart
    if (frame.type == FrameType.data) {
      if (state.session == null) {
        debugPrint('[mesh-frame] data frame but no session — triggering recovery');
        _triggerStaleRecovery(srcDevice, state, reason: 'no-session');
        return;
      }
```

- [ ] **Step 5: Run the test to verify it passes**

Run: `cd /Users/dmitry/Downloads/taler_id_mesh && flutter test test/core/mesh/services/mesh_messaging_service_test.dart --plain-name 'session==null on receiver'`
Expected: 1 test passed.

- [ ] **Step 6: Run the full mesh service test suite for regressions**

Run: `cd /Users/dmitry/Downloads/taler_id_mesh && flutter test test/core/mesh/services/mesh_messaging_service_test.dart`
Expected: all tests in the file pass (the existing two from earlier phases plus the new one).

- [ ] **Step 7: Commit**

```bash
git add lib/core/mesh/services/mesh_messaging_service.dart \
        test/core/mesh/services/mesh_messaging_service_test.dart
git commit -m "mesh(2.3): receiver-side recovery on session==null"
```

---

## Task 2: Wire the `decrypt failed` trigger (TDD)

The `session==null` path covers the receiver-restarted case. The `decrypt failed` path covers the symmetric stale-keys case where both sides have a session but they don't match.

**Files:**
- Modify: `lib/core/mesh/services/mesh_messaging_service.dart`
- Modify: `test/core/mesh/services/mesh_messaging_service_test.dart`

- [ ] **Step 1: Write the failing test**

Append inside the `Phase 2.3 stale-session recovery` group (after the previous test, before the closing `});`):

```dart

    test('decrypt-failed triggers recovery (rate-limit also caps the storm)',
        () async {
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

      // Override threshold so the test runs fast and assertion is precise.
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
        peerResetThreshold: 3,
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

      // Establish a session so Bob has state.session != null. This lets
      // the next bad frame fall into the `try { decrypt(...) } catch`
      // branch (decrypt-failed), not the `session == null` branch.
      final firstAtBob = bob.inbound.first;
      await alice.sendEnvelope(
        toUserPk: bobPeer,
        envelope: Envelope(
          version: 1,
          type: 'text',
          convId: 'conv-mac',
          clientId: 'msg-warmup',
          text: 'warm up',
          sentAt: DateTime.parse('2026-04-28T10:00:00Z'),
        ),
      );
      await firstAtBob;

      // Count how many handshake frames Alice receives from Bob across
      // the whole test. Recovery msg1's are observable as inbound
      // FrameType.handshake on Alice's transport.
      var bobHandshakesArrivedAtAlice = 0;
      final aliceFrameSub = aliceT.inbound.listen((f) {
        if (f.type == FrameType.handshake) bobHandshakesArrivedAtAlice++;
      });

      // Push 5 frames of pure garbage as data frames into Bob's inbound.
      // Bob's session.decrypt will throw MAC; recovery will fire 3 times
      // (peerResetThreshold), then be capped.
      for (var i = 0; i < 5; i++) {
        bobT._inbound.add(InboundFrame(
          srcPeer: alicePeer,
          type: FrameType.data,
          bytes: Uint8List.fromList(List<int>.generate(80, (j) => i * 7 + j)),
        ));
      }
      await Future<void>.delayed(const Duration(milliseconds: 300));

      // Each accepted recovery resets and inits one handshake → one msg1
      // arrives at Alice. With threshold=3, expect at most 3 (the
      // existing warm-up handshake's msg1+msg2 already counted before
      // we attached the listener, so we look only at frames *after*
      // listener attach).
      expect(bobHandshakesArrivedAtAlice, lessThanOrEqualTo(3),
          reason: 'rate-limit caps recovery storm at peerResetThreshold');
      expect(bobHandshakesArrivedAtAlice, greaterThanOrEqualTo(1),
          reason: 'at least one recovery must have fired');

      await aliceFrameSub.cancel();
      await alice.dispose();
      await bob.dispose();
    });
```

This test relies on access to the fake transport's `_inbound` controller. The existing `_FakeTransport` definition at the top of the file has it as a private field. Add a public push method to the fake to keep the test clean — see Step 3.

- [ ] **Step 2: Run the test to verify it fails**

Run: `cd /Users/dmitry/Downloads/taler_id_mesh && flutter test test/core/mesh/services/mesh_messaging_service_test.dart --plain-name 'decrypt-failed triggers recovery'`
Expected: compilation error (`bobT._inbound` is private to the fake) OR test fails because no recovery fires (current code only logs MAC error and drops). The compile failure is fixed in Step 3.

- [ ] **Step 3: Open the fake transport's inbound for tests**

In the same test file, find the `_FakeTransport` class. Just below the existing `void emitDiscovery(...)` (last public method in the class), add:

```dart
  /// Test-only: inject a frame as if the partner had sent it. Used by
  /// stale-session recovery tests where we need to deliver garbage that
  /// causes a MAC failure on decrypt.
  void injectInboundFrame(InboundFrame frame) {
    _inbound.add(frame);
  }
```

In the new test (Step 1), replace `bobT._inbound.add(...)` with `bobT.injectInboundFrame(...)`.

- [ ] **Step 4: Wire the `decrypt failed` trigger**

In `lib/core/mesh/services/mesh_messaging_service.dart`, find the `data` branch of `_onInboundFrame`, specifically the catch-all `catch (e) { debugPrint('[mesh-frame] decrypt failed: $e'); }` (around line 268). Replace:

```dart
      } catch (e) {
        debugPrint('[mesh-frame] decrypt failed: $e');
      }
```

With:

```dart
      } catch (e) {
        debugPrint('[mesh-frame] decrypt failed: $e — triggering recovery');
        _triggerStaleRecovery(srcDevice, state, reason: 'mac-error');
      }
```

The `on FormatException catch (e)` branch immediately above is **left unchanged** — it handles a successful decrypt with malformed JSON, which is not a stale-session signal.

- [ ] **Step 5: Run the test to verify it passes**

Run: `cd /Users/dmitry/Downloads/taler_id_mesh && flutter test test/core/mesh/services/mesh_messaging_service_test.dart --plain-name 'decrypt-failed triggers recovery'`
Expected: 1 test passed.

- [ ] **Step 6: Run the full mesh service test suite for regressions**

Run: `cd /Users/dmitry/Downloads/taler_id_mesh && flutter test test/core/mesh/services/mesh_messaging_service_test.dart`
Expected: all tests in the file pass.

- [ ] **Step 7: Commit**

```bash
git add lib/core/mesh/services/mesh_messaging_service.dart \
        test/core/mesh/services/mesh_messaging_service_test.dart
git commit -m "mesh(2.3): receiver-side recovery on decrypt failure (MAC) + rate-limit"
```

---

## Task 3: Final analyze + push + manual hardware smoke + PR

**Files:** none modified — verification only.

- [ ] **Step 1: Static analysis on the touched file**

Run: `cd /Users/dmitry/Downloads/taler_id_mesh && dart analyze lib/core/mesh/services/mesh_messaging_service.dart 2>&1 | tail -5`
Expected: no errors or warnings introduced. Pre-existing project-wide info-level lints are acceptable; the gate is "no new errors on the touched file".

- [ ] **Step 2: Full test suite**

Run: `cd /Users/dmitry/Downloads/taler_id_mesh && flutter test 2>&1 | tail -3`
Expected: `All tests passed!` Count is 432 (current baseline) + 2 new = 434.

- [ ] **Step 3: Push to origin**

```bash
git push origin feature/mesh-phase2-3-stale-session-recovery
```
Expected: branch pushed.

- [ ] **Step 4: Hardware smoke (manual, before opening PR)**

**Scenario A — receiver restart, sender stale session.**
1. dev backend up. On host: `ssh dvolkov@89.169.55.217 "pm2 status taler-id-dev"` to confirm online.
2. Android Redmi (`78c0742f`) and iPhone wired (`00008150-00060C5A21E9401C`) both in a 1:1 chat, both running v1.0.65 with this branch:
   ```
   cd /Users/dmitry/Downloads/taler_id_mesh && flutter run --flavor dev -t lib/main_dev.dart --dart-define=FLAVOR=dev --dart-define=BASE_URL=https://staging.id.taler.tirol -d 78c0742f
   ```
   ```
   cd /Users/dmitry/Downloads/taler_id_mesh && flutter run --flavor dev -t lib/main_dev.dart --dart-define=FLAVOR=dev --dart-define=BASE_URL=https://staging.id.taler.tirol -d 00008150-00060C5A21E9401C
   ```
3. Send one message each direction so both sides have an active mesh session.
4. Force-quit iPhone (swipe). Android keeps its cached session.
5. Send a text message from Android. Phase 2.2 enqueues it (no eligible peers).
6. Relaunch iPhone (re-run `flutter run` or tap the icon if the dev build is still installed).
7. iPhone's bonjour discovers Android. Android's Phase 2.2 retry fires `_meshFanout`, encrypts with stale session, sends to iPhone.
8. iPhone receives the data frame, sees `state.session == null`, fires `_triggerStaleRecovery`. iPhone log expected:
   `[mesh-handshake] receiver-side stale recovery (reason=no-session) pk=<android-prefix>...`
9. iPhone sends msg1 to Android. Android's Phase 2.1 detects fresh init (cached session) → resets → responder → sends msg2. Android log expected:
   `[mesh-handshake] peer reset detected, dropping cached session pk=<iphone-prefix>...`
10. iPhone finalises. The original retried message either decrypts on the new session (if Android's Phase 2.2 queue resends it after the new handshake completes via `peerDiscovered` re-emission) or stays pending. Send another message from Android to confirm fresh delivery.
11. Assert (visual): both messages land on iPhone in the chat without bilateral restart.

**Scenario B — both online, no spurious recovery.**
1. Both apps running, mesh sessions live.
2. Exchange messages both directions.
3. Neither device's log should show `[mesh-handshake] receiver-side stale recovery` — verify with `grep "stale recovery"` on the flutter run output. The line must be absent for the duration of the chat.

- [ ] **Step 5: Open the PR**

Visit https://github.com/dvvolkovv/taler_id_mobile/compare/dev...feature/mesh-phase2-3-stale-session-recovery and open a PR with:

- **Title:** `mesh(2.3): receiver-side stale-session recovery (auto re-handshake on bad data frame)`
- **Body:**

```markdown
## Summary
- New `_triggerStaleRecovery(devicePk, state, reason)` helper in `MeshMessagingService` — called from the `data` branch of `_onInboundFrame` whenever `state.session == null` or `decrypt` throws.
- Helper rate-limits via the existing `_allowReset` (5 in 60 s per peer, shared with Phase 2.1), then resets local state and fires `_initiateHandshake` fire-and-forget.
- Sender's Phase 2.1 accept-latest-init handles the incoming msg1 against its stale state — both sides end up with a fresh session.
- `FormatException` (envelope JSON decode after successful decrypt) is intentionally NOT a recovery trigger — it indicates a sender-payload bug, not a session mismatch.

## Test plan
- [x] Unit: `session==null` triggers recovery; subsequent send from sender decrypts cleanly on the new session.
- [x] Unit: `decrypt failed` triggers recovery; rate-limit caps the storm at `peerResetThreshold` per peer.
- [x] Hardware Scenario A: peer force-quit → stale-keyed send → receiver-initiated recovery → message delivered without bilateral restart. Log line `[mesh-handshake] receiver-side stale recovery (reason=no-session)` observed on receiver.
- [x] Hardware Scenario B: both online, no spurious recovery triggers.

## Notes
- Implements Phase 2.3 per spec `docs/superpowers/specs/2026-04-28-mesh-phase2-3-stale-session-recovery-design.md`.
- Mobile-only, no backend, DB, or wire-format change.
- Picks up in v1.0.65.
```

---

## Self-review (run by author)

**Spec coverage:**
- Trigger on `session==null` → Task 1, Steps 3-4. ✓
- Trigger on `decrypt failed` → Task 2, Step 4. ✓
- `FormatException` does NOT trigger → Task 2, Step 4 (left unchanged). ✓
- `_triggerStaleRecovery` helper signature matches spec → Task 1, Step 3. ✓
- Rate-limit via existing `_allowReset` (no new budget) → Task 2 covers via threshold override in test. ✓
- Reset + initiate sequence → Task 1, Step 3. ✓
- Phase 2.1 anti-thrash jitter still applies (because `_resetPeerState` does not clear `hadPriorSession`) → confirmed in pre-condition note at top. ✓
- Hardware scenarios A and B → Task 3, Step 4. ✓

**Placeholder scan:** none.

**Type consistency:**
- `_triggerStaleRecovery(PeerId, _PeerState, {required String reason})` signature consistent across both call sites. ✓
- `injectInboundFrame(InboundFrame)` test helper named consistently. ✓
- Reason strings (`'no-session'`, `'mac-error'`) consistent with spec. ✓

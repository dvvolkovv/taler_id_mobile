# Mesh Phase 2.1 — Discovery & Handshake Resilience

**Status:** Draft
**Date:** 2026-04-26
**Owner:** Dmitry Volkov
**Builds on:** Phase 2 group chats (merged into `dev` as commit `61e23a4`)

## Goal

Eliminate two pre-existing Phase 1i bugs that surfaced during Phase 2 hardware smoke testing:

1. **iOS bonsoir cold-start race** — iPhone subscribes to discovery `eventStream` but `discoveryServiceFound` events never fire until *another* peer triggers an mDNS event (e.g., Android restart). Workaround today: restart peer side.
2. **Noise re-handshake after one-side restart** — when one side restarts the app, peer's cached session/handshake state persists; new `handshake_init` is rejected with `unexpected handshake frame — state.isInitiator=false handshake!=null`. Workaround today: bilateral restart.

After this phase, both workarounds become unnecessary.

## Non-Goals

- Group key derivation (deferred to Phase 2.5+).
- Peer authentication beyond Noise IK (Phase 3+).
- Wire format / protocol changes (we stay on Phase 2 v2 envelope).
- UI indicators for "re-handshaking…" or "discovery cold-start kicked" (out of scope; can land separately).
- Patching `bonsoir_darwin` upstream — we work around in our wrapper layer instead.
- macOS / Linux desktop polish — same code paths run, but desktop hardware testing is not part of acceptance.

## Architecture Overview

Two independent fixes, packaged into one PR because they share the "what happens when one side restarts" mental model.

**Affected files (mobile only):**

- `lib/core/mesh/transport/bonjour_transport.dart` (or its current equivalent — the file that wraps `BonsoirDiscovery` / `BonsoirBroadcast`).
- `lib/core/mesh/services/mesh_messaging_service.dart` — handshake state machine in `_handleInboundFrame`.
- `pubspec.yaml` — verify `connectivity_plus` is reusable from mesh layer (already a project dependency).

**Backwards compatibility:** purely runtime changes. Phase 2 wire format, dedup, and UI stay as-is. Mixed-version cohorts (one side with the fix, one without) keep working — this is strictly an additive resilience layer.

## Bug 1 — iOS bonsoir cold-start (hybrid fix)

### Root cause

In `bonsoir_darwin`, when the Dart side calls `subscribe(eventStream)` immediately after `startDiscovery()`, there is a race: `NSNetServiceBrowser` has not actually begun searching by the time the stream is subscribed, and existing `_talermesh._tcp` services on the network are missed. Future events (a fresh advertise from a peer) wake the resolver up, which is why peer-side restart unblocks discovery.

### Fix

Wrap discovery in a `MeshDiscoverySupervisor` with three triggers, all funneled through one rate-limited `_reinit()` (max 1 per 3 seconds, idempotent).

**Trigger 1 — cold-start watchdog.**
After `subscribe(eventStream)`, arm a 5-second timer. If neither `discoveryStarted` nor any `discoveryServiceFound` event has fired by then, call `dispose()` + `startDiscovery()` again. Up to 3 attempts with backoff (5 / 10 / 20 seconds). After exhausting attempts, stop kicking and rely on runtime triggers.

**Trigger 2 — connectivity changes.**
Subscribe to `Connectivity().onConnectivityChanged`. On any transition into `wifi` (including `none → wifi` and apparent IP/SSID changes within `wifi`), call `_reinit()`.

**Trigger 3 — app lifecycle.**
Implement `WidgetsBindingObserver`. On `paused → resumed`, call `_reinit()`. iOS sometimes kills mDNS background work without restoring it; resume is the cleanest hook.

### Logging

```
[mesh-discovery-supervisor] kick reason=cold-start attempt=2
[mesh-discovery-supervisor] kick reason=connectivity prev=none now=wifi
[mesh-discovery-supervisor] kick reason=resumed
[mesh-discovery-supervisor] reinit skipped — within 3s rate-limit
```

### Platform behavior

The supervisor runs on all platforms identically. On Android, where the cold-start race is not observed, the cosmetic kicks are harmless (rate-limited, no functional change). On iOS, this is the actual fix.

## Bug 2 — Noise re-handshake (accept latest init + jitter)

### Root cause

`MeshMessagingService._handleInboundFrame` rejects an incoming `handshake_init` when local state is `isInitiator=false && handshake!=null`. Today this means: "I already accepted a handshake from this peer once and I'm in some intermediate state." But after one peer restarts, that intermediate state is stale; rejecting forces the user to bilaterally restart.

### Fix

**A — Accept latest init.**
When `handshake_init` arrives from a peer for whom we already have `state.handshake != null` or `state.session != null`:

1. Log `[mesh-handshake] peer reset detected, dropping cached session pk=<peerPk>`.
2. Call `_resetPeerState(peerPk)` — clear handshake, session, ushortcut buffer, pending outbound queue for this peer.
3. Build a fresh `responder` Noise handshake.
4. Process the incoming init frame against the fresh responder.

**B — Anti-thrash jitter.**
When *we* call `_initiateHandshake(peerPk)` along the recovery path (i.e., we previously had a session with this peer and are now re-creating one — not a brand-new contact), delay the outbound `handshake_init` by `random(50..200)` ms. If during the delay we receive a `handshake_init` from the peer, cancel our pending init and become responder.

**C — Backoff.**
Maintain `peerResetCount[peerPk]` over a 60-second sliding window. If count exceeds 5, pause re-handshake attempts for that peer for 30 seconds (defends against a buggy or malicious peer that resets every message).

### Out of scope (intentional)

- **In-flight messages encrypted with the dropped session** are dropped and not retransmitted at the mesh layer. Phase 2's `(senderId, content, ±10s)` dedup window handles legitimate retries; server fanback covers persistence.
- **No session persistence to Hive** — sessions stay ephemeral by design. App restart always means full re-handshake.

### Metric

Expose `peerResetCount` in `MeshStatusBloc.peerStats` so the Mesh Debug screen and integration tests can observe reset frequency.

## Wire & Protocol

No changes. Frame v2 envelope, Noise IK, JSON payloads — all unchanged.

## Testing

### Unit (TDD)

**`mesh_discovery_supervisor_test.dart`** (new):
- Cold-start kick fires after 5 s of silence and retries up to 3 times with 5/10/20 s backoff.
- Connectivity event triggers `_reinit()`.
- Lifecycle resume triggers `_reinit()`.
- Rate-limit suppresses second `_reinit()` within 3 s.
- After 3 failed cold-start attempts, watchdog stops; runtime triggers still work.

**`mesh_messaging_service_handshake_reset_test.dart`** (new):
- Receiving `handshake_init` after established session resets state and accepts new handshake.
- Receiving `handshake_init` while local pending-initiator timer running → cancels timer, becomes responder.
- 6th reset for same peer within 60 s triggers 30-second backoff; 7th reset before backoff expires is rejected.
- Anti-thrash jitter delays outbound init within 50..200 ms range.

**Existing 402 tests** must remain green.

### Hardware smoke (required before merge to `dev`)

**Scenario 1 — cold-start fix:**
1. Both iPhone and Android already running and advertising; iPhone is the target under test.
2. Force-quit and relaunch iPhone app.
3. Within 15 seconds, iPhone log shows `[mesh-discovery-supervisor] kick reason=cold-start` followed by `discoveryServiceFound` for the Android peer.
4. No Android-side intervention required.

**Scenario 2 — re-handshake fix:**
1. iPhone and Android in an active mesh session (each has sent at least one message).
2. Force-quit and relaunch Android app only.
3. From Android, send a message to iPhone in the group chat.
4. iPhone log shows `peer reset detected, dropping cached session`. Message arrives via mesh on iPhone within the normal latency window. No restart of iPhone required.

**Scenario 3 — Phase 2 regression:**
1. Re-run Phase 2 hardware smoke (group + server, mesh-only, sender clock fix).
2. All three should pass identically.

### Acceptance criteria

- All unit tests pass (existing + new).
- All three hardware scenarios pass on Android Redmi + iPhone wired (emulator optional — its NAT means cold-start fix is hard to observe meaningfully).
- No more than one spurious `discoveryServiceLost` per 5 minutes of idle. Above that signals regression.

## Risks

1. **Cascading reinits** — three triggers firing within seconds (e.g., resume on a fresh Wi-Fi). Mitigated by rate-limit (1 reinit / 3 s).
2. **Log noise** — each kick logs. Mitigated by `reason=` tag and `debugPrint` (release-mode strips them).
3. **Backoff bites a flaky-but-legitimate peer** — counter resets after 60 s of silence, so transient turbulence won't lock the peer out permanently.
4. **`connectivity_plus` desktop quirks** — out of scope for this phase, but the supervisor must not crash on desktop platforms; verify in code review.
5. **iOS Local Network permission denied** — no fix in this phase; should be a separate Mesh Debug enhancement to surface the deny state to the user.

## Rollout

1. Implementation on `feature/mesh-phase2-1-discovery-handshake-resilience`.
2. Unit tests + hardware smoke on Android Redmi + iPhone wired.
3. PR → `dev`. Merge after spec & code reviews.
4. Deploy: mobile-only, no backend touched. Run dev APK / iOS dev flavor on test devices and reproduce both scenarios.
5. Soak on `dev` for 1–2 days. Monitor logs for unexpected kick frequency or backoff hits.
6. Promote to `main` for PROD release. **Do not bundle with other feature releases** — keep the surgical-rollback option open if discovery turbulence appears in the wild.

## Post-Merge Metrics

- `peerResetCount` per peer (already on `MeshStatusBloc.peerStats`).
- `discoveryReinitCount` per session, broken down by `reason` (cold-start / connectivity / resumed). Surface in Mesh Debug screen for manual observation.

These are observability hooks for diagnosis only — no telemetry shipped to backend.

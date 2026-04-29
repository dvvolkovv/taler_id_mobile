# Mesh Voice Call — Phase 3 (1-on-1, 1-hop, full mesh-only)

**Status:** Draft
**Date:** 2026-04-29
**Owner:** Dmitry Volkov
**Builds on:** Phase 1a-1k (mesh messaging), Phase 2 (group chats), Phase 2.1-2.3 (resilience), root mesh-design `2026-04-21-mesh-network-design.md`

## Goal

Enable serverless 1-on-1 voice calls between two devices that see each other in direct mesh discovery (Bonjour LAN or BLE direct). All audio bytes — capture, encoding, transport, decoding, playback — go through the mesh stack. No LiveKit, no SFU, no STUN/TURN, no APNs/FCM for this call path.

After this phase ships, a user in a chat with a contact whose device is currently mesh-discovered can press a "voice call" button, and the call rings the peer through mesh signaling and streams audio over a new mesh datagram channel encrypted with Noise IK.

## Non-Goals (Phase 3)

- Multi-hop relay for voice — RTP frames flow only between directly-discovered peers. Multi-hop is Phase 4 (separate plan).
- Group calls (3+ participants) — Phase 4+.
- Video.
- BLE-multi-hop / mesh-flood for audio.
- iOS background incoming. iOS cannot be woken from background by a mesh frame (no VoIP push without server). Documented limitation; missed-call entry on app return.
- CallKit / Telecom integration for mesh calls. Out-of-app call screens, lock-screen call control — deferred to Phase 3.1 if the feature ships and demands it.
- Server-mediated fallback when mesh is unreachable. Existing LiveKit path remains for non-mesh contacts; mesh button simply disabled when callee not mesh-discovered.
- AI Voice Twin in mesh calls (twin agent runs server-side, unreachable on pure-mesh path).
- Replacement of existing LiveKit call stack. The two coexist; call entry decides which path on a per-call basis.

## Architecture overview

```
┌──────────────────────────────────────────────────┐
│ VoiceCallScreen (existing) + MeshCallBadge       │  UI
├──────────────────────────────────────────────────┤
│ MeshVoiceService (new)                           │  Orchestration
│   call lifecycle, state machine, RTT, mute       │
├──────────────────────────────────────────────────┤
│ MeshVoiceAudioEngine (new — Dart + native + FFI) │  Audio
│   mic capture → Opus encode → ... → playback     │
├──────────────────────────────────────────────────┤
│ MeshMessagingService.sendEnvelope(call_*)        │  Signaling
│   (existing, extended with new envelope types)   │
├──────────────────────────────────────────────────┤
│ MeshTransport.sendDatagram() / inboundDatagrams  │  Transport
│ Bonjour: parallel UDP socket (port via TXT)      │     (extended)
│ BLE: notify-without-ARQ characteristic           │
├──────────────────────────────────────────────────┤
│ MeshDatagramCipher (new)                         │  Crypto
│   Noise IK session reuse, per-frame nonce = seq  │
└──────────────────────────────────────────────────┘
```

**Reused:** Noise IK sessions from `MeshMessagingService` (signaling lives on the existing reliable channel; datagram cipher reuses the same handshake-derived keys). Discovery streams from `MeshTransport`. `ContactKeyStore` for `userId → devicePks` resolution. Existing `VoiceCallScreen` and `call_history` Hive box.

**New:** `MeshVoiceService`, `MeshVoiceAudioEngine`, `MeshDatagramCipher`, datagram channel inside `MeshTransport` (Bonjour + BLE implementations + MultiTransport fan-out).

**Estimated effort:** 3-4 focused weeks for working 1-hop prototype on Android+iPhone-foreground. Substantially heavier than text-mesh phases due to native audio + FFI + new transport channel.

## Audio engine

`MeshVoiceAudioEngine` is a Dart facade over a native audio session and a libopus codec via `dart:ffi`. One instance per active call; lifecycle bound to call lifecycle.

### Capture path (sender)

```
platform mic (voice-chat audio session)
  → 16 kHz mono PCM frames (20 ms = 320 samples)
  → libopus encode (Opus 16-32 kbps adaptive)
  → encoded bytes (~20-80 bytes typical)
```

Native:
- **iOS** — `AVAudioSession.modeVoiceChat`, `kAudioUnitSubType_VoiceProcessingIO` AudioUnit. Built-in hardware AEC/AGC/NS.
- **Android** — `AudioRecord` with `MediaRecorder.AudioSource.VOICE_COMMUNICATION` + `NoiseSuppressor.create()` + `AcousticEchoCanceler.create()` enabled.

Frames emit through a Dart `Stream<Uint8List>` consumed by `MeshVoiceService`.

### Playback path (receiver)

```
inbound datagram → MeshDatagramCipher.decrypt
  → JitterBuffer.push(seq, opus_bytes)
  → JitterBuffer.pull() (called at 50 Hz from playback callback)
  → libopus decode → 16 kHz mono PCM
  → native audio output (voice-chat mode)
```

`JitterBuffer`:
- Ring-FIFO indexed by sequence number.
- Adaptive depth 60-120 ms based on EMA of inter-arrival jitter.
- On gap ≤ 2 frames → Opus PLC (`opus_decode` with null input). On gap > 2 → silent frame.
- Late-arriving frames (seq below current playout) → drop.

### libopus FFI

- `dart:ffi` bindings to libopus C API: `opus_encoder_create`, `opus_encode`, `opus_decoder_create`, `opus_decode`, `opus_*_destroy`.
- Vendored prebuilt libraries:
  - iOS: universal static lib (arm64 + x86_64 simulator) inside a CocoaPods spec.
  - Android: `.so` per ABI (`armeabi-v7a`, `arm64-v8a`, `x86_64`) under `android/app/src/main/jniLibs/`.
- Pure-Dart wrapper exposes `OpusEncoder.encode(Uint8List pcm) → Uint8List` and `OpusDecoder.decode(Uint8List opus) → Uint8List`.

### Codec parameters (defaults)

| Param | Value |
|---|---|
| Sample rate | 16 kHz mono |
| Frame size | 20 ms |
| Bitrate | 24 kbps adaptive |
| Application | `OPUS_APPLICATION_VOIP` |
| FEC | off (Phase 3); revisit in Phase 4 if loss budget exceeded |

### Mute / unmute

`AudioEngine.setMicEnabled(bool)` toggles native capture. Encoded frames stop emitting; battery/CPU savings (vs. encoding silence).

### Failure modes

- libopus FFI fails to load → fall back to uncompressed PCM frames (640 bytes / 20 ms = ~256 kbps). Works on LAN, infeasible on BLE — `MeshVoiceService` then refuses BLE-only calls. UI shows "low-quality mode" warning.
- Mic permission denied → call setup fails before audio engine starts; UI surfaces permission prompt + retry.
- Audio session interrupted (incoming phone call, Siri) → call held, resumed when session restored. Same handling as existing LiveKit call code in `voice_call_screen.dart`.

## Datagram channel inside `MeshTransport`

Parallel low-latency channel alongside the existing reliable `send()`. Voice frames go through datagram; signaling stays on reliable.

### Interface extension

```dart
abstract class MeshTransport {
  // existing
  Stream<PeerDiscovered> get discoveries;
  Stream<PeerLost> get losses;
  Stream<InboundFrame> get inbound;
  Future<void> send(PeerId peer, Uint8List data);

  // new
  Stream<InboundDatagram> get inboundDatagrams;
  Future<void> sendDatagram(PeerId peer, Uint8List data);
  // throws TransportUnavailable if no datagram path to peer
}

class InboundDatagram {
  final PeerId src;
  final Uint8List bytes;
  final TransportId via;
}
```

### Bonjour implementation

- On `startAdvertising`, bind a parallel `RawDatagramSocket.bind(InternetAddress.anyIPv4, 0)` to an ephemeral UDP port.
- Advertise the UDP port through the Bonjour TXT record: new key `udp_port=<port>` alongside the existing `pk=...`.
- On `PeerDiscovered`, parse `udp_port` from TXT; cache in `_peerUdpEndpoints[devicePk] = (host, port)`.
- `sendDatagram(peer, bytes)` — `_socket.send(bytes, host, port)` to the cached endpoint.
- `inboundDatagrams` listens to the local UDP socket, emits `InboundDatagram` keyed by source IP→PeerId reverse lookup (built from active discoveries).
- Frame size cap: 1200 bytes (avoid IPv4 fragmentation under typical 1500 MTU with UDP+IP headers).

### BLE implementation

- New GATT characteristic UUID `0x6D65-7368-6461-7461-6772616D` ("meshdatagram") on the existing mesh service.
- Properties: `WriteWithoutResponse | Notify`. No link-layer ARQ.
- Frame size cap: 244 bytes (BLE 5 ATT MTU after exchange; falls back to 20 if MTU exchange not yet completed — `MeshVoiceService` warns and refuses call until MTU upgraded).
- Larger frames (typical when MTU not upgraded) — fragmented at the cipher layer; reassembled on receive. 2-byte fragment header `[1 bit final][15 bit fragment_id]`.

### MultiTransport routing

- `sendDatagram(peer, data)` iterates children; picks first child whose `_peers[peer]` contains the peer.
- If peer is visible on both Bonjour and BLE → prefer Bonjour (higher bandwidth, lower latency).
- Mid-call transport switching (e.g., WiFi drops mid-call, BLE still up) — **not in Phase 3**. The existing transport is used for the call's lifetime; if the chosen transport drops, the call ends with `peer_lost`. Smart switching → Phase 4.

### Encryption (`MeshDatagramCipher`)

Reuses Noise IK transport keys derived during the existing handshake (the same `MeshMessagingService._sessions[devicePk]` that encrypts text messages provides the keys; we add a separate cipher object that draws from the same shared secret to avoid mixing nonces between text and voice).

- AEAD: ChaCha20-Poly1305.
- Per-frame nonce: 12 bytes constructed as `direction (1 byte) || zero (3 bytes) || sequence (8 bytes BE)`. `direction = 0x00` for caller→callee, `0x01` for callee→caller. Sequence is a 64-bit counter that increments per-frame and starts from a random `datagram_seq_init` exchanged in signaling.
- Replay protection: sliding window of 64 frames per direction. Frames with seq ≤ `max_seen − 64` dropped.
- Frame layout (cleartext): `[1 byte type][4 bytes call_id][8 bytes seq][N bytes Opus payload]`. After AEAD, the seq+call_id+type stay in a per-frame AAD (associated data) so they're authenticated but readable; the Opus payload is encrypted+authenticated.

## Signaling (call setup and teardown)

Uses the existing `MeshMessagingService.sendEnvelope` reliable Noise-IK-encrypted channel. New `Envelope.type` values:

| `type` | direction | payload |
|---|---|---|
| `call_invite` | caller → callee | `{call_id, codec_params, datagram_seq_init}` |
| `call_accept` | callee → caller | `{call_id, codec_params, datagram_seq_init}` |
| `call_reject` | callee → caller | `{call_id, reason}` (busy / declined / unsupported / timeout) |
| `call_setup` | both | `{call_id}` (final ack after parameter negotiation) |
| `call_end` | both | `{call_id, reason}` (hangup / timeout / error / peer_lost) |
| `call_keepalive` | both, mid-call | `{call_id}` (1 Hz; detects silent transport failure) |

`call_id` is a random 64-bit value generated by the caller, included in every signaling envelope and every datagram for this call.

`codec_params` (CBOR-encoded for compactness):

```
{
  "audio": "opus",
  "rate": 16000,
  "channels": 1,
  "frame_ms": 20,
  "bitrate": 24000,
  "fec": false
}
```

The caller offers; the callee responds with the matching set or rejects with `unsupported`. Phase 3 only supports the single profile above; `unsupported` covers future-version mismatches.

`datagram_seq_init` — initial 64-bit sequence number chosen randomly by each side, exchanged in invite/accept. Prevents nonce collisions if a contact pair is in a session-reuse situation across calls.

### Caller state machine

```
IDLE
  ↓ user taps "call via mesh", MeshVoiceService.invite(devicePk)
  ↓ send call_invite envelope
INVITING (timeout 30s)
  on call_accept     → CONNECTING
  on call_reject     → ENDED
  on timeout         → send call_end{reason:timeout} → ENDED
CONNECTING
  ↓ send call_setup, await callee call_setup (5s timeout)
  ↓ start audio engine + datagram capture/playback
ACTIVE
  → audio frames flow both ways
  → keepalive every 1 s
  on user hangup           → send call_end → ENDED
  on remote call_end       → ENDED
  on no inbound datagram >3s → send call_end{reason:timeout} → ENDED
ENDED
  ↓ stop audio engine, drop datagram session, write call_history entry
```

Callee mirror: `IDLE → INCOMING (showing UI) → CONNECTING → ACTIVE → ENDED`.

### Eligibility check

When the user is on a chat screen and considers placing a voice call:

1. Resolve `userId → devicePks[]` via `ContactKeyStore`.
2. For each `devicePk`, check `MeshTransport.peerStatus(devicePk)` (new synchronous getter, computed from active discovery state). Returns `online | offline | unknown`.
3. If any device is `online` → "Mesh available", show the mesh-call button.
4. If none → fall back to existing LiveKit-based call (or "not mesh-reachable, call via server?" — UI choice via long-press; see Section: UI).

Live updates of the eligibility dot in chat header come through the existing `_peers` discovery / loss streams.

## Persistence

Mesh call entries write to the existing `call_history` Hive box. Schema additions (additive, backwards-compatible):

```
{
  ... existing fields,
  "transport": "mesh" | "livekit",
  "via": "bonjour" | "ble" | null,
  "callId": "<64-bit hex>"
}
```

Existing rendering: `_CallHistoryItem` widget gets a tiny mesh icon when `transport == 'mesh'` (different from the existing LiveKit indicator).

## UI integration and platform behavior

`VoiceCallScreen` is reused. New constructor parameter `transport: 'mesh' | 'livekit'`. When `mesh`, mute / hangup / RTT / quality-meter wire to `MeshVoiceService` instead of `lk.Room`.

### Visual differences for mesh calls

- Header badge: small mesh-network icon and the label "Mesh".
- Quality indicator: shows current transport (`bonjour` / `ble`) and one of three states — Good / OK / Poor — derived from jitter EMA + packet-loss rate over the last 5 s.
- No AI-twin UI.

### Place-call button in chat

- Single tap: auto-pick. If callee is mesh-discovered → mesh, else LiveKit.
- Long-press: popup `[По сети] [Через сервер]` for explicit choice.
- Mesh-availability indicator: small dot beside the contact's avatar in the chat header. Live-updates on discovery / loss events from the streams the chat already subscribes to.

### Incoming UI

- iOS / Android **foreground**: modal sheet with avatar, name, "Mesh call" badge, accept / decline buttons. Auto-dismiss after 30 s → `call_reject{reason:timeout}` to the caller.
- iOS **background**: call does not arrive (mesh frame cannot wake the app). Caller times out at 30 s. Callee, on next foreground, sees a missed-call entry in `call_history` (written when `MeshVoiceService` later receives any orphan `call_end`).
- Android background: existing mesh foreground service receives the signaling envelope (it already subscribes for messaging). On `call_invite`, posts a full-screen incoming Notification (matches the existing LiveKit incoming UI). User taps accept → app foregrounds → `MeshVoiceService.accept()` → audio session + RTP flow.

### iOS background-limit messaging

A one-time onboarding tooltip when the user first opens a chat with a mesh-eligible contact: "📡 Mesh-звонки требуют активного приложения". Not repeated per-chat.

### Conflict with existing LiveKit calls

- If a LiveKit call is active and a mesh `call_invite` arrives → `MeshVoiceService` auto-replies `call_reject{reason:busy}` (mirrors LiveKit's own busy behavior).
- If the user attempts to start a mesh call while a LiveKit call is active → UI blocks with a toast "Завершите текущий звонок".

### CallKit / Telecom

Out of scope for Phase 3. Mesh calls do not appear in the OS native call UI / lock screen / iOS recents. If the feature gains traction, Phase 3.1 can wire CallKit's `CXProvider` into the foreground-only state.

## Testing

### Unit

- `OpusEncoder.encode` / `OpusDecoder.decode` round-trip with a synthetic 1 kHz sine PCM input — decoded RMS energy ≥ 90 % of input.
- `JitterBuffer` fill/drain: feed frames out-of-order and with gaps; assert `pull()` returns frames in seq order, gaps trigger PLC, late frames dropped.
- `MeshDatagramCipher`: encrypt → decrypt round-trip; replay window correctly drops stale seq; nonce uniqueness across 10 000 frames.
- `MeshVoiceService` state machine: drive transitions through mocked signaling/audio/transport callbacks; use `fakeAsync` for timeouts (30 s invite, 5 s setup, 3 s keepalive).
- Bonjour datagram: `RawDatagramSocket` mock — send/receive across two ephemeral UDP ports, fragment cap honored.

### Integration

- Two `MeshMessagingService` + `MeshTransport` instances over an in-memory `_FakeTransport` extended with a datagram channel that simulates jitter (10-30 ms variance) and 5 % packet loss.
- Full-flow happy path: alice.invite(bob) → bob accepts → 5 s of audio frames → alice.hangup → both ENDED.
- Edge: bob declines → ENDED, no audio engine started.
- Edge: peer disappears mid-call (synthetic `PeerLost` event during ACTIVE) → cleanup + `call_history` written with `reason:peer_lost`.
- Edge: 50 % packet loss for 2 s — call survives via PLC; quality indicator drops to Poor; recovers when loss subsides.

### Hardware smoke (manual, after implementation)

- Redmi 78c0742f + iPhone wired (00008150) on the same WiFi: 1-on-1 mesh call, 30 s, subjective MOS rating.
- Same setup with WiFi off (BLE direct): mesh call works; latency and quality assessed.
- Two Android devices: cross-Android verification.
- iOS background test: Android initiates, iPhone in background. Expect: caller times out, iPhone shows missed-call entry on next foreground.

### Performance benchmarks (ad-hoc)

- End-to-end mouth-to-ear latency: target < 200 ms on LAN, < 400 ms on BLE.
- CPU usage: target < 15 % single-core typical (Opus encode + decode + AEC dominate).
- Battery: continuous-call duration roughly comparable to LiveKit call (within 20 %).

## Risks

### High

1. **libopus FFI bindings.** Prebuilt libs needed for iOS (universal arm64 + x86_64) and Android (`.so` per ABI). Pure-Dart Opus exists but is too slow for real-time encode/decode. **Mitigation:** spike in week 1; if FFI integration blocks, pivot to uncompressed PCM (640 bytes / 20 ms = ~256 kbps), accepting that BLE-only calls become infeasible.
2. **iOS `AVAudioSession.modeVoiceChat` conflicts with active LiveKit calls.** **Mitigation:** signaling-level busy reject (Section: UI).
3. **BLE bandwidth realism.** BLE 5 PHY 2M practical ≈ 500 kbps; Opus 24 kbps fits, but mesh discovery + signaling traffic shares the air time. **Mitigation:** hardware smoke in week 1 confirms feasibility; if BLE is too constrained we drop to BLE-disabled in Phase 3 (LAN-only) and document.
4. **Echo cancellation quality vs LiveKit baseline.** Platform AEC is weaker than WebRTC's AEC3, especially on low-end Android with weak DSP. **Mitigation:** document that speakerphone mode is less stable; recommend headphones; if smoke shows unacceptable echo, integrate a software AEC (e.g., `webrtc-audio-processing` standalone) as a pre-encode stage.

### Medium

5. **Bonjour TXT record changes** for the new `udp_port` key. **Mitigation:** TXT records are forward-compatible by spec — older clients ignore unknown keys; backward compatibility preserved.
6. **Replay window 64 frames vs 50 fps emission.** 64 / 50 = 1.28 s tolerance for reordering. Tight under high jitter. **Mitigation:** widen to 256 frames if smoke shows dropping legitimate late frames.

## Open questions for the plan phase

- Where to host libopus FFI bindings: separate pub package `opus_ffi` (vendored via `dependency_overrides`) or under `lib/core/audio/opus/`? Both work; the writing-plans phase picks based on whether opus is reused outside the mesh-call feature.
- Native class names for the `AVAudioSession` / `AudioRecord` Flutter platform-channel wrappers — pattern follows existing `flutter_callkit_incoming` integration in the repo.
- Bonjour TXT advertising for the UDP port — version it (`v=1, udp_port=...`) for forward-compat? Recommendation: yes, prefix with a `v=` tag now to leave room for future protocol bumps.

## Rollout

1. Branch `feature/mesh-voice-call-phase3` from `dev`.
2. Implementation in 4 sub-phases (the writing-plans skill produces concrete task breakdown):
   - 3a. libopus FFI + audio engine prototype (mic→encode→decode→playback in a self-test scenario, no mesh yet).
   - 3b. Datagram channel in `MeshTransport` (Bonjour + BLE + MultiTransport) + `MeshDatagramCipher`.
   - 3c. Signaling envelopes + `MeshVoiceService` state machine.
   - 3d. UI integration (chat eligibility dot, mesh-call button, incoming Notification on Android, `VoiceCallScreen` adapter).
3. Hardware smoke after each sub-phase before moving on.
4. Final hardware smoke on real devices (Section: Testing).
5. PR to `dev`. Picks up in v1.0.66 or later, depending on smoke outcomes.

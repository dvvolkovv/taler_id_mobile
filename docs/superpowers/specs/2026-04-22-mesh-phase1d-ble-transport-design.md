# Mesh Phase 1d — BLE Transport & MultiTransport Integration

**Date:** 2026-04-22
**Status:** Design approved, ready for implementation planning

**Working dir:** `~/Downloads/taler_id_mesh/` — branch `feature/mesh-network` (off `dev`). No backend changes.

---

## 1. Executive Summary

Phase 1d adds a BLE-based peer-to-peer transport that does both **discovery** (BLE advertising + scanning) and **data transport** (GATT write/notify). Combined with a new `MultiTransport` composer, it enables fully offline text messaging without any WiFi access point, while keeping the fast-path `BonjourTransport` available when both peers share an AP.

**What changes:**
- New `BleTransport` implements the existing `MeshTransport` abstract class from Phase 1a.
- New `MultiTransport` fans-in discoveries and routes `send()` across multiple transports with a preference policy (Bonjour > BLE on bandwidth).
- No changes to `MeshMessagingService`, Noise crypto, or any upper-layer code — the whole Phase 1c PKI works over BLE identically.

**Scope boundary:** BLE-only for this phase. Wi-Fi Direct / Multipeer / Android hotspot are deferred to Phase 1f. File transfer and voice over BLE are explicitly out (bandwidth insufficient).

---

## 2. Decision Log

| # | Question | Decision | Rationale |
|---|----------|----------|-----------|
| 1 | BLE role | B: BLE discovery + BLE data transport | Closes the "full offline" goal; ~100-200 Kbps is sufficient for text/voice-messages |
| 2 | Flutter libraries | A: `flutter_reactive_ble` (central) + `flutter_ble_peripheral` (peripheral) | Both mature on pub.dev; no custom native code; ~2 weeks saved vs bespoke plugin |
| 3 | Coexistence with Bonjour | A: both transports run in parallel under `MultiTransport` | Clean abstraction now, also unblocks Phase 1f Wi-Fi Direct addition |
| 4 | GATT protocol shape | Single service + single characteristic with `WRITE_WITHOUT_RESPONSE + NOTIFY` | Full-duplex byte channel; minimal surface for Noise to run over |
| 5 | Connection tiebreak | Lexicographic: smaller `devicePk` hex initiates | Prevents double-connect races without extra handshake |
| 6 | Scan duty cycle | 100% active | Adaptive 5s/30s idle deferred to Phase 1e lifecycle work |
| 7 | Advertising prefix rotation | Use full static MeshStaticKey public key prefix, no extra rotation | Phase 1c already rotates MeshStaticKey every 30 days; daily prefix rotation is privacy hardening for Phase 1e |
| 8 | iOS background | Foreground only | CoreBluetooth background APIs too limited; spec already documents this |
| 9 | Feature flag | `mesh.ble.enabled` default OFF | Ship BLE code dormant; enable after real-hardware testing |

---

## 3. Goals & Non-Goals

### Goals

1. Two devices advertising the mesh service UUID find each other via BLE.
2. Either device can initiate a Noise IK handshake over a BLE-backed byte channel using the existing Phase 1c `UserIdentityKey` / `MeshStaticKey`.
3. After handshake, arbitrary `NoiseSession` data frames flow in both directions via GATT write/notify.
4. `MultiTransport` surfaces a unified discovery + inbound stream; `send()` picks the best available transport per peer.
5. Android permissions requested at runtime; missing permission disables BLE transport cleanly.
6. Works cross-platform: iPhone ↔ Android text message roundtrip.

### Non-Goals (Phase 1d)

- Wi-Fi Direct, Multipeer Connectivity, Android hotspot — Phase 1f
- iOS background BLE
- Adaptive duty-cycled scanning
- Daily rotation of the advertised prefix (separate from key rotation)
- UI — Settings screen, mesh status badges, transport indicators — Phase 1e
- File transfer / voice over BLE (bandwidth insufficient)
- Routing / multi-hop — Phase 2
- Onion packet framing — Phase 2
- Feature flag UI (the flag itself is wired; UI toggle comes later)

---

## 4. Architecture

```
lib/core/mesh/transport/
├── mesh_transport.dart          # (unchanged) abstract MeshTransport
├── bonjour_transport.dart       # (unchanged) Phase 1a mDNS + TCP
├── ble_transport.dart           # NEW — implements MeshTransport over BLE
├── ble/
│   ├── ble_gatt_protocol.dart   # Service/characteristic UUIDs + length-prefixed framing
│   ├── ble_peer_registry.dart   # Active BLE connections keyed by PeerId
│   └── ble_connection.dart      # Wraps a single central↔peripheral link
├── multi_transport.dart         # NEW — fan-in over N transports
└── transport_preference.dart    # NEW — per-peer transport choice policy
```

### BleTransport

Composes two Flutter libraries:
- **Peripheral role** (`flutter_ble_peripheral`): advertises the mesh service UUID, exposes a GATT server with one characteristic for bidirectional data.
- **Central role** (`flutter_reactive_ble`): scans filtered by service UUID, connects to discovered peers, subscribes to notifications, writes inbound frames.

Exposes the standard `MeshTransport` surface: `discoveries`, `losses`, `inbound`, `startAdvertising`, `connectTo`, `send`, `dispose`.

### MultiTransport

```dart
class MultiTransport implements MeshTransport {
  MultiTransport(List<MeshTransport> transports);
  // Streams merged from all children, PeerDiscovered deduped by PeerId.
  // send(peer, data) picks best transport per peer, falls back on error.
}
```

`MeshMessagingService` receives this via DI and does not need to know which transport carries a given message.

### TransportPreference

```dart
class TransportPreference {
  TransportChoice chooseFor(PeerId peer, Set<TransportId> available);
}
```

Phase 1d policy: **Bonjour > BLE** (higher bandwidth). Extracted into a separate testable unit so Phase 1f can add Wi-Fi Direct cleanly.

---

## 5. BLE Protocol

### Service & characteristic UUIDs

Deterministic 128-bit UUIDs under a stable base, chosen once and never reused.

| Role | UUID | Purpose |
|------|------|---------|
| Service | `00005459-4c52-4944-4d45-534853470100` | Discovery filter |
| Characteristic | `00005459-4c52-4944-4d45-534853470101` | Bidirectional data |

### Advertising payload

20 bytes (fits in standard BLE advertising):

```
┌──────────────┬──────────┬──────┬──────────┐
│ svcUUID (16B)│ devicePk │ flags│ version  │
│              │ prefix(8)│ (1B) │ (1B)     │
└──────────────┴──────────┴──────┴──────────┘
```

- `devicePk prefix` = first 8 bytes of `MeshStaticKey.publicKey`
- `flags` = 0 in Phase 1d (reserved for future: has-gateway, is-SFU, etc.)
- `version` = 1

iOS advertisements are constrained — we use the manufacturer-data pathway via `flutter_ble_peripheral`.

### GATT characteristic

Single characteristic with properties `WRITE_WITHOUT_RESPONSE | NOTIFY`. This gives us a full-duplex byte channel:

- Central → peripheral: writes chunks
- Peripheral → central: sends notify chunks

### Framing

BLE MTU is typically 20–512 bytes depending on negotiation. Noise frames can reach ~2 KB. `BleGattProtocol` adds a minimal length-prefixed framing on top of the raw byte stream:

```
[2B length big-endian][payload bytes]
```

Sender splits into MTU-sized chunks. Receiver buffers bytes and reassembles whole frames once `length` bytes arrived. Invalid lengths (0 or > max) drop the buffer and log.

This framing is below the Noise layer — `NoiseIKHandshake` and `NoiseSession` receive whole frames exactly as over Bonjour's TCP.

### Connection initiation policy

When both peers discover each other simultaneously, both would try to `connect`. We break the tie deterministically:

- Let `mine = myDevicePk.hex`, `theirs = peerDevicePk.hex`
- If `mine < theirs` lexicographically → this device initiates as central
- If `mine > theirs` → wait as peripheral; ignore this peer in the scan-results path

`BlePeerRegistry` tracks per-peer state (`advertised`, `connecting`, `connected`) and enforces the above rule.

### Advertising interval

500 ms. Balances discovery latency (~1-2 seconds to see a new peer) and power draw. User-tunable only via feature flag in Phase 1e.

### Scan duty cycle

100% active in Phase 1d. Phase 1e introduces adaptive duty-cycle tied to app lifecycle (foreground/background) and recent-activity heuristics.

---

## 6. MultiTransport Integration

### Unified streams

- `multi.discoveries` — emits `PeerDiscovered` once per peer (first transport wins; attributes from later transports merged in). When a peer is re-discovered on a second transport, no event is emitted but internal state updates.
- `multi.losses` — emits `PeerLost` only when the peer is lost on **all** transports simultaneously. A BLE drop while Bonjour still has the peer does not propagate.
- `multi.inbound` — merged from all children.

### Sending

```
send(peer, data):
  transports = registry.transportsKnowing(peer)
  ordered = preference.order(peer, transports)
  for t in ordered:
    try: t.send(peer, data); return
    catch: log; continue
  throw NoTransportAvailable
```

### DI wiring

`service_locator.dart` after Phase 1d:

```dart
final bonjour = BonjourTransport(...);      // unchanged
final ble = BleTransport(...);              // new
sl.registerSingleton<MeshTransport>(
  MultiTransport([bonjour, ble]),
);
```

`MeshMessagingService` and everything above it sees only the `MeshTransport` interface — no awareness of BLE vs Bonjour.

---

## 7. Permissions & Lifecycle

### Android

Added to `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.BLUETOOTH_ADVERTISE" />
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />
<uses-permission android:name="android.permission.BLUETOOTH_SCAN"
    android:usesPermissionFlags="neverForLocation" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />  <!-- API 30 and below -->
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_CONNECTED_DEVICE" />
```

Runtime request via existing `permission_handler` package at `BleTransport.startAdvertising()` invocation. Denial → BLE transport logs warning and enters disabled state; `MultiTransport` continues with Bonjour-only.

### iOS

Added to `ios/Runner/Info.plist`:

```xml
<key>NSBluetoothAlwaysUsageDescription</key>
<string>Taler ID mesh uses Bluetooth to find nearby contacts when you're offline.</string>
```

No additional runtime request — iOS prompts automatically on first use.

### Lifecycle

- `BleTransport.startAdvertising()` → starts advertising + scanning immediately, no throttling
- `BleTransport.dispose()` → stops advertising, tears down GATT server, disconnects all centrals
- App backgrounded on iOS: BLE stops working within seconds (CoreBluetooth limitation); documented as expected

---

## 8. Feature Flag

`mesh.ble.enabled` — boolean read from a new `MeshConfig` holder in `lib/core/config/`. Default: `false`.

Effect:
- If `false`: `MultiTransport` is constructed with only `[bonjour]`. No BLE code loads or runs.
- If `true`: `MultiTransport` gets `[bonjour, ble]`, full behaviour.

Phase 1e adds a Settings UI toggle that flips this. Phase 1d ships the flag as a compile-time-read constant or `--dart-define` so QA can enable it for hardware testing without shipping it to users.

---

## 9. Testing Strategy

### Unit (no hardware)

- `ble_gatt_protocol_test.dart` — length-prefix frame encode/decode; chunk/reassemble with variable MTU; malformed length handling
- `ble_peer_registry_test.dart` — lexicographic tiebreak resolves initiator; duplicate discovery is idempotent
- `transport_preference_test.dart` — Bonjour preferred over BLE; single-transport choice; unknown peer throws
- `multi_transport_test.dart` — fan-in dedup, send-with-fallback, loss-only-when-all-lost. Uses two `_FakeTransport` doubles.

### Hardware integration (manual)

- `integration_test/ble_peer_discovery_test.dart` — run on two physical Android devices with BT enabled. Assertions:
  1. Both discover each other within 5 seconds.
  2. Noise handshake completes successfully.
  3. One text message roundtrips in < 2 seconds.
- Cross-platform manual run: iPhone + Android device — same assertions.

### Regression

`flutter test test/core/mesh/` must stay green (Phase 1a+1b+1c+1d). No flaky or skipped cases.

---

## 10. Risks & Mitigations

| Risk | Impact | Mitigation |
|------|--------|-----------|
| `flutter_ble_peripheral` regresses on a new Android/iOS release | BLE peripheral role breaks; users see no offline mesh | Feature flag OFF by default; smoke test on latest Android/iOS before enabling |
| BLE MTU negotiation inconsistent on some vendors | Throughput drops; large Noise frames slow | Framing code handles any MTU ≥ 20 bytes; worst-case just slower |
| iOS background kills advertising within seconds | Users don't receive messages when screen off | Documented; foreground-only is the accepted Phase 1 posture |
| Permission denial on Android 12+ | BLE transport never starts | Graceful degradation — `MultiTransport` continues Bonjour-only; log to analytics |
| Connection initiation race between two peers | Both sides fail to handshake | Lexicographic tiebreak in `BlePeerRegistry` |
| `flutter_reactive_ble` silent failures on connection drop | Stale `PeerId` in registry | Heartbeat over GATT characteristic (optional, Phase 1e); for Phase 1d, rely on library's `.connectionState` stream |

---

## 11. Rollout

1. Merge to `feature/mesh-network` with feature flag OFF. Dormant in the shipping app.
2. QA team enables `--dart-define=MESH_BLE_ENABLED=true` on test builds.
3. Run hardware integration tests on 2 Android + 1 iOS device combinations.
4. If stable for one week, Phase 1e adds the Settings UI to flip the flag per-user.

No backend changes. No migration. No user-visible change until Phase 1e.

---

## 12. Next Steps

1. User review of this spec (current step)
2. Feedback addressed if any
3. Invoke `writing-plans` skill → detailed Phase 1d implementation plan
4. Execute plan via `subagent-driven-development`

---

## Appendix A — UUID derivation

Base pattern: `00005459-4c52-4944-4d45-5348534707XX` where `5459 4c52 4944 4d45 5348 5347` spells `TYLR IDME SHSG` (Taler ID Mesh Service Group) — arbitrary but stable. Last byte is an allocation number:

- `00` — reserved
- `01`–`7F` — Phase 1 service + characteristics
- `80`–`FF` — future phases

Phase 1d uses `0100` (service) and `0101` (data characteristic).

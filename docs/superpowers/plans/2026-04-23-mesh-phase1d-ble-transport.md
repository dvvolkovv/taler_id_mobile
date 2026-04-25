# Mesh Phase 1d — BLE Transport & MultiTransport Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a BLE-backed `MeshTransport` (discovery + bidirectional data) alongside the existing `BonjourTransport`, composed under a new `MultiTransport` that picks the best path per peer. BLE traffic runs under a feature flag that defaults to OFF, so the shipping app is unaffected until hardware testing signs off.

**Architecture:** `BleTransport` advertises a 128-bit service UUID via `flutter_ble_peripheral` and scans for it via `flutter_reactive_ble`; both sides expose a single GATT characteristic with `WRITE_WITHOUT_RESPONSE | NOTIFY` for full-duplex byte flow. A length-prefix framing layer (`BleGattProtocol`) reassembles Noise frames regardless of negotiated MTU. `MultiTransport` merges `discoveries`/`losses`/`inbound` streams from N sub-transports, deduplicates peers, and routes `send()` via a `TransportPreference` that prefers higher-bandwidth transports.

**Tech Stack:**
- Dart 3.6 / Flutter, existing Phase 1a–1c crypto/services stay intact.
- New packages: `flutter_reactive_ble` (central), `flutter_ble_peripheral` (peripheral).
- Existing `permission_handler` reused for runtime Android 12+ BLE permissions.
- Tests: `flutter_test` (unit) + `integration_test` (hardware, manual runs).

---

## Spec & Dependencies

- Spec: `docs/superpowers/specs/2026-04-22-mesh-phase1d-ble-transport-design.md`
- Prior phases:
  - Phase 1a: `docs/superpowers/plans/2026-04-21-mesh-phase1a-text-exchange.md`
  - Phase 1b: `docs/superpowers/plans/2026-04-21-mesh-phase1b-device-key-sync.md`
  - Phase 1c: `docs/superpowers/plans/2026-04-22-mesh-phase1c-user-identity-keys.md`
- Working dir: `~/Downloads/taler_id_mesh/` on branch `feature/mesh-network` (off `dev`). No backend changes.

### Foundation types already in place

- `MeshTransport` abstract class at `lib/core/mesh/transport/mesh_transport.dart` with streams `discoveries` / `losses` / `inbound` and methods `startAdvertising` / `connectTo` / `send` / `dispose`.
- `PeerId` at `lib/core/mesh/transport/peer_id.dart` (32-byte wrapper with `toHex()` / `fromHex()` / equality).
- `Frame` / `FrameType` at `lib/core/mesh/transport/frame.dart` (version + type + srcPk + payload, `encode()` / `decode()`).
- `BonjourTransport` at `lib/core/mesh/transport/bonjour_transport.dart` — reference for how the stream controllers, per-peer connection tracking, and `startAdvertising` work.

---

## File Structure

### New files

```
lib/core/config/
└── mesh_config.dart                          # Feature flag holder, reads from --dart-define

lib/core/mesh/transport/
├── ble_transport.dart                        # BleTransport (implements MeshTransport)
├── multi_transport.dart                      # MultiTransport (implements MeshTransport)
├── transport_preference.dart                 # TransportChoice policy
└── ble/
    ├── ble_gatt_protocol.dart                # Service UUIDs + length-prefix framing
    ├── ble_peer_registry.dart                # Per-peer connection state + tiebreak
    └── ble_connection.dart                   # Wraps a single central↔peripheral link

test/core/mesh/transport/
├── ble_gatt_protocol_test.dart
├── ble_peer_registry_test.dart
├── multi_transport_test.dart
└── transport_preference_test.dart

integration_test/
└── ble_peer_discovery_test.dart              # Hardware-only, manual runs
```

### Modified files

```
pubspec.yaml                                  # + flutter_reactive_ble, flutter_ble_peripheral
android/app/src/main/AndroidManifest.xml      # + BLE permissions
ios/Runner/Info.plist                         # + NSBluetoothAlwaysUsageDescription
lib/core/di/service_locator.dart              # Wrap BonjourTransport in MultiTransport
```

---

## Execution Order

Tasks **T1–T3** add foundations (feature flag, pubspec deps, permissions). Tasks **T4–T6** implement the composable pieces (framing protocol, peer registry, transport preference). Task **T7** is the `BleTransport` itself. Tasks **T8–T9** wire the `MultiTransport` composer and DI. Task **T10** is the hardware integration test. Task **T11** is the final regression sweep.

Work from: `cd ~/Downloads/taler_id_mesh` (branch `feature/mesh-network`).

---

## Task T1: MeshConfig — feature flag holder

**Files:**
- Create: `lib/core/config/mesh_config.dart`
- Create: `test/core/config/mesh_config_test.dart`

- [ ] **Step 1: Write failing test**

Create `test/core/config/mesh_config_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';

import 'package:taler_id_mobile/core/config/mesh_config.dart';

void main() {
  group('MeshConfig', () {
    test('bleEnabled default is false', () {
      expect(MeshConfig.bleEnabled, isFalse);
    });
  });
}
```

- [ ] **Step 2: Run — expect FAIL**

```bash
cd ~/Downloads/taler_id_mesh
flutter test test/core/config/mesh_config_test.dart 2>&1 | tail -5
```

Expected: Compile error about the missing `mesh_config.dart` module.

- [ ] **Step 3: Implement MeshConfig**

Create `lib/core/config/mesh_config.dart`:

```dart
/// Compile-time feature flags for the mesh subsystem.
///
/// Phase 1d: `bleEnabled` gates the BLE transport. Default OFF so shipping
/// builds continue to use only Bonjour until hardware testing signs off.
///
/// Override via:
///   flutter run --dart-define=MESH_BLE_ENABLED=true
class MeshConfig {
  /// Whether the BLE-based MeshTransport is active.
  static const bool bleEnabled = bool.fromEnvironment(
    'MESH_BLE_ENABLED',
    defaultValue: false,
  );
}
```

- [ ] **Step 4: Run — expect pass**

```bash
cd ~/Downloads/taler_id_mesh
flutter test test/core/config/mesh_config_test.dart 2>&1 | tail -5
```

Expected: `+1: All tests passed!`

- [ ] **Step 5: Commit**

```bash
cd ~/Downloads/taler_id_mesh
git add lib/core/config/mesh_config.dart test/core/config/mesh_config_test.dart
git commit -m "feat(mesh/config): add MeshConfig with bleEnabled compile-time flag"
```

---

## Task T2: pubspec — add BLE dependencies

**Files:**
- Modify: `pubspec.yaml`

- [ ] **Step 1: Add the two packages**

Open `pubspec.yaml`. Find the existing dependency block (after `bonsoir`, `cryptography`). Add:

```yaml
  # Mesh BLE (Phase 1d) — central + peripheral
  flutter_reactive_ble: ^5.3.1
  flutter_ble_peripheral: ^1.2.7
```

- [ ] **Step 2: Resolve deps**

```bash
cd ~/Downloads/taler_id_mesh
flutter pub get 2>&1 | tail -5
```

Expected: `Got dependencies!`. If a platform constraint conflict appears, note the failing package and escalate — do NOT silently upgrade or downgrade other deps.

- [ ] **Step 3: Verify no regressions in mesh tests**

```bash
cd ~/Downloads/taler_id_mesh
flutter test test/core/mesh/ 2>&1 | tail -3
```

Expected: all existing tests pass (72/72 or higher).

- [ ] **Step 4: Commit**

```bash
cd ~/Downloads/taler_id_mesh
git add pubspec.yaml pubspec.lock
git commit -m "chore(mesh): add flutter_reactive_ble + flutter_ble_peripheral deps"
```

---

## Task T3: Platform permissions

**Files:**
- Modify: `android/app/src/main/AndroidManifest.xml`
- Modify: `ios/Runner/Info.plist`

- [ ] **Step 1: Add Android BLE permissions**

Open `android/app/src/main/AndroidManifest.xml`. Find the block of `<uses-permission>` tags near the top. Add these four lines in that block (keep alphabetical-ish ordering with the existing set):

```xml
    <uses-permission android:name="android.permission.BLUETOOTH_ADVERTISE"/>
    <uses-permission android:name="android.permission.BLUETOOTH_CONNECT"/>
    <uses-permission android:name="android.permission.BLUETOOTH_SCAN" android:usesPermissionFlags="neverForLocation"/>
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE_CONNECTED_DEVICE"/>
```

`ACCESS_FINE_LOCATION` already exists in the manifest — reused for pre-API-31 scan compatibility.

- [ ] **Step 2: Add iOS Bluetooth usage description**

Open `ios/Runner/Info.plist`. Find the `<dict>` opening tag. Before `</dict>`, add:

```xml
	<key>NSBluetoothAlwaysUsageDescription</key>
	<string>Taler ID mesh uses Bluetooth to find nearby contacts when you're offline.</string>
```

(Indentation matches existing entries — tabs, not spaces.)

- [ ] **Step 3: Verify Android and iOS builds still compile**

```bash
cd ~/Downloads/taler_id_mesh
flutter analyze lib/ 2>&1 | tail -5
```

Expected: `No issues found!`. (A true Android/iOS compile check requires `flutter build apk` / `flutter build ios` on a real machine; the analyze step is the fast proxy for static-validation.)

- [ ] **Step 4: Commit**

```bash
cd ~/Downloads/taler_id_mesh
git add android/app/src/main/AndroidManifest.xml ios/Runner/Info.plist
git commit -m "chore(mesh): add Android + iOS BLE permissions for Phase 1d"
```

---

## Task T4: BleGattProtocol — UUIDs + length-prefix framing

**Files:**
- Create: `lib/core/mesh/transport/ble/ble_gatt_protocol.dart`
- Create: `test/core/mesh/transport/ble_gatt_protocol_test.dart`

- [ ] **Step 1: Write failing tests**

Create `test/core/mesh/transport/ble_gatt_protocol_test.dart`:

```dart
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:taler_id_mobile/core/mesh/transport/ble/ble_gatt_protocol.dart';

void main() {
  group('BleGattProtocol', () {
    test('service and characteristic UUIDs are stable', () {
      expect(BleGattProtocol.serviceUuid,
          equals('00005459-4c52-4944-4d45-534853470100'));
      expect(BleGattProtocol.characteristicUuid,
          equals('00005459-4c52-4944-4d45-534853470101'));
    });

    test('encodes frame with 2-byte big-endian length prefix', () {
      final payload = Uint8List.fromList([1, 2, 3, 4]);
      final encoded = BleGattProtocol.encodeFrame(payload);
      expect(encoded.length, equals(6));
      expect(encoded[0], equals(0));
      expect(encoded[1], equals(4));
      expect(encoded.sublist(2), equals(payload));
    });

    test('chunks output into MTU-sized writes', () {
      final payload = Uint8List(500);
      for (var i = 0; i < 500; i++) {
        payload[i] = i & 0xFF;
      }
      final chunks = BleGattProtocol.chunkForMtu(
        BleGattProtocol.encodeFrame(payload),
        mtu: 20,
      );
      expect(chunks.length, equals(26)); // ceil((500+2) / 20)
      expect(chunks.first.length, equals(20));
      // Last chunk may be shorter.
      expect(chunks.last.length, equals(2));
    });

    test('chunkForMtu throws on mtu < 1', () {
      expect(
        () => BleGattProtocol.chunkForMtu(Uint8List(10), mtu: 0),
        throwsArgumentError,
      );
    });

    test('FrameReassembler emits whole frame after split chunks arrive',
        () {
      final reassembler = FrameReassembler();
      final received = <Uint8List>[];
      reassembler.onFrame = (frame) => received.add(frame);

      final payload = Uint8List.fromList(List.generate(100, (i) => i & 0xFF));
      final encoded = BleGattProtocol.encodeFrame(payload);
      // Feed in 30-byte chunks.
      for (var i = 0; i < encoded.length; i += 30) {
        final end = (i + 30).clamp(0, encoded.length);
        reassembler.feed(Uint8List.sublistView(encoded, i, end));
      }

      expect(received, hasLength(1));
      expect(received.first, equals(payload));
    });

    test('FrameReassembler handles two frames in one chunk', () {
      final reassembler = FrameReassembler();
      final received = <Uint8List>[];
      reassembler.onFrame = (frame) => received.add(frame);

      final payloadA = Uint8List.fromList([1, 2, 3]);
      final payloadB = Uint8List.fromList([9, 8, 7, 6]);
      final combined = Uint8List.fromList([
        ...BleGattProtocol.encodeFrame(payloadA),
        ...BleGattProtocol.encodeFrame(payloadB),
      ]);
      reassembler.feed(combined);

      expect(received, hasLength(2));
      expect(received[0], equals(payloadA));
      expect(received[1], equals(payloadB));
    });

    test('FrameReassembler rejects zero-length frame', () {
      final reassembler = FrameReassembler();
      final received = <Uint8List>[];
      reassembler.onFrame = (frame) => received.add(frame);

      final bad = Uint8List.fromList([0, 0]); // length = 0
      reassembler.feed(bad);

      expect(received, isEmpty);
    });
  });
}
```

- [ ] **Step 2: Run — expect FAIL**

```bash
cd ~/Downloads/taler_id_mesh
flutter test test/core/mesh/transport/ble_gatt_protocol_test.dart 2>&1 | tail -5
```

Expected: import error for the missing module.

- [ ] **Step 3: Implement BleGattProtocol**

Create `lib/core/mesh/transport/ble/ble_gatt_protocol.dart`:

```dart
import 'dart:typed_data';

/// Protocol constants + wire-format helpers for the BLE transport.
///
/// GATT surface is a single service with a single characteristic. The
/// characteristic supports `WRITE_WITHOUT_RESPONSE | NOTIFY`, giving us a
/// full-duplex byte channel over which Noise frames flow.
///
/// Each application-level Noise frame is prefixed by a 2-byte big-endian
/// length. Receivers reassemble over arbitrary chunk boundaries produced
/// by BLE MTU fragmentation.
class BleGattProtocol {
  /// 128-bit service UUID advertised by the peripheral role.
  static const String serviceUuid =
      '00005459-4c52-4944-4d45-534853470100';

  /// 128-bit characteristic UUID exposed under [serviceUuid].
  static const String characteristicUuid =
      '00005459-4c52-4944-4d45-534853470101';

  /// Maximum payload length for a single Noise frame over BLE. Aligned with
  /// the upper-layer `Frame.maxPayload` so we never truncate.
  static const int maxFrameLength = 65535;

  /// Wrap a Noise frame with a 2-byte big-endian length prefix.
  static Uint8List encodeFrame(Uint8List payload) {
    if (payload.length > maxFrameLength) {
      throw ArgumentError('BLE frame over $maxFrameLength bytes');
    }
    final out = Uint8List(2 + payload.length);
    out[0] = (payload.length >> 8) & 0xFF;
    out[1] = payload.length & 0xFF;
    out.setRange(2, out.length, payload);
    return out;
  }

  /// Split a prepared wire buffer into MTU-sized chunks for sequential
  /// write / notify operations.
  static List<Uint8List> chunkForMtu(Uint8List wire, {required int mtu}) {
    if (mtu < 1) {
      throw ArgumentError('mtu must be >= 1, got $mtu');
    }
    final out = <Uint8List>[];
    for (var i = 0; i < wire.length; i += mtu) {
      final end = (i + mtu < wire.length) ? i + mtu : wire.length;
      out.add(Uint8List.sublistView(wire, i, end));
    }
    return out;
  }
}

/// Stateful decoder for the opposite direction: fed arbitrary chunks,
/// invokes [onFrame] once per complete decoded Noise frame.
class FrameReassembler {
  final List<int> _buffer = [];
  void Function(Uint8List frame)? onFrame;

  void feed(Uint8List chunk) {
    _buffer.addAll(chunk);
    while (_tryExtract()) {}
  }

  bool _tryExtract() {
    if (_buffer.length < 2) return false;
    final len = (_buffer[0] << 8) | _buffer[1];
    if (len == 0 || len > BleGattProtocol.maxFrameLength) {
      // Malformed — drop everything; the peer is out of sync.
      _buffer.clear();
      return false;
    }
    if (_buffer.length < 2 + len) return false;
    final frame = Uint8List.fromList(_buffer.sublist(2, 2 + len));
    _buffer.removeRange(0, 2 + len);
    onFrame?.call(frame);
    return true;
  }
}
```

- [ ] **Step 4: Run — expect all pass**

```bash
cd ~/Downloads/taler_id_mesh
flutter test test/core/mesh/transport/ble_gatt_protocol_test.dart 2>&1 | tail -5
```

Expected: `+7: All tests passed!`

- [ ] **Step 5: Commit**

```bash
cd ~/Downloads/taler_id_mesh
git add lib/core/mesh/transport/ble/ble_gatt_protocol.dart test/core/mesh/transport/ble_gatt_protocol_test.dart
git commit -m "feat(mesh/transport/ble): BleGattProtocol — UUIDs + length-prefix framing"
```

---

## Task T5: BlePeerRegistry — per-peer state + lexicographic tiebreak

**Files:**
- Create: `lib/core/mesh/transport/ble/ble_peer_registry.dart`
- Create: `test/core/mesh/transport/ble_peer_registry_test.dart`

- [ ] **Step 1: Write failing tests**

Create `test/core/mesh/transport/ble_peer_registry_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';

import 'package:taler_id_mobile/core/mesh/transport/ble/ble_peer_registry.dart';
import 'package:taler_id_mobile/core/mesh/transport/peer_id.dart';

void main() {
  group('BlePeerRegistry', () {
    test('shouldInitiate returns true when our pk < theirs', () {
      final mine = PeerId.fromHex('a' * 64);
      final theirs = PeerId.fromHex('b' * 64);
      final reg = BlePeerRegistry(selfPk: mine);

      expect(reg.shouldInitiate(theirs), isTrue);
    });

    test('shouldInitiate returns false when our pk > theirs', () {
      final mine = PeerId.fromHex('c' * 64);
      final theirs = PeerId.fromHex('b' * 64);
      final reg = BlePeerRegistry(selfPk: mine);

      expect(reg.shouldInitiate(theirs), isFalse);
    });

    test('shouldInitiate returns false when equal (reject self-connect)',
        () {
      final mine = PeerId.fromHex('a' * 64);
      final reg = BlePeerRegistry(selfPk: mine);

      expect(reg.shouldInitiate(mine), isFalse);
    });

    test('mark/get roundtrip preserves BleLinkState', () {
      final mine = PeerId.fromHex('a' * 64);
      final theirs = PeerId.fromHex('b' * 64);
      final reg = BlePeerRegistry(selfPk: mine);

      expect(reg.stateOf(theirs), equals(BleLinkState.idle));
      reg.mark(theirs, BleLinkState.connecting);
      expect(reg.stateOf(theirs), equals(BleLinkState.connecting));
      reg.mark(theirs, BleLinkState.connected);
      expect(reg.stateOf(theirs), equals(BleLinkState.connected));
    });

    test('forget resets state to idle', () {
      final mine = PeerId.fromHex('a' * 64);
      final theirs = PeerId.fromHex('b' * 64);
      final reg = BlePeerRegistry(selfPk: mine);

      reg.mark(theirs, BleLinkState.connected);
      reg.forget(theirs);
      expect(reg.stateOf(theirs), equals(BleLinkState.idle));
    });

    test('allConnected returns currently-connected peers', () {
      final mine = PeerId.fromHex('a' * 64);
      final p1 = PeerId.fromHex('b' * 64);
      final p2 = PeerId.fromHex('c' * 64);
      final p3 = PeerId.fromHex('d' * 64);
      final reg = BlePeerRegistry(selfPk: mine);

      reg.mark(p1, BleLinkState.connected);
      reg.mark(p2, BleLinkState.connecting);
      reg.mark(p3, BleLinkState.connected);

      final connected = reg.allConnected().toSet();
      expect(connected, equals({p1, p3}));
    });
  });
}
```

- [ ] **Step 2: Run — expect FAIL**

```bash
cd ~/Downloads/taler_id_mesh
flutter test test/core/mesh/transport/ble_peer_registry_test.dart 2>&1 | tail -5
```

Expected: compile error for missing module.

- [ ] **Step 3: Implement BlePeerRegistry**

Create `lib/core/mesh/transport/ble/ble_peer_registry.dart`:

```dart
import '../peer_id.dart';

enum BleLinkState {
  idle,
  connecting,
  connected,
}

/// Tracks per-peer BLE connection state and enforces the lexicographic
/// tiebreak that decides which side initiates when both discover the
/// other simultaneously.
///
/// Rule: the peer with the smaller `devicePk` hex string initiates as
/// central; the other waits for an incoming connection in the peripheral
/// role.
class BlePeerRegistry {
  final PeerId selfPk;
  final Map<PeerId, BleLinkState> _state = {};

  BlePeerRegistry({required this.selfPk});

  /// True iff this device should initiate the BLE connect to [peer] once
  /// both sides have discovered each other. False for equal (self) or
  /// for the side that must wait.
  bool shouldInitiate(PeerId peer) {
    final mine = selfPk.toHex();
    final theirs = peer.toHex();
    return mine.compareTo(theirs) < 0;
  }

  BleLinkState stateOf(PeerId peer) => _state[peer] ?? BleLinkState.idle;

  void mark(PeerId peer, BleLinkState state) {
    _state[peer] = state;
  }

  void forget(PeerId peer) {
    _state.remove(peer);
  }

  Iterable<PeerId> allConnected() => _state.entries
      .where((e) => e.value == BleLinkState.connected)
      .map((e) => e.key);
}
```

- [ ] **Step 4: Run — expect all pass**

```bash
cd ~/Downloads/taler_id_mesh
flutter test test/core/mesh/transport/ble_peer_registry_test.dart 2>&1 | tail -5
```

Expected: `+6: All tests passed!`

- [ ] **Step 5: Commit**

```bash
cd ~/Downloads/taler_id_mesh
git add lib/core/mesh/transport/ble/ble_peer_registry.dart test/core/mesh/transport/ble_peer_registry_test.dart
git commit -m "feat(mesh/transport/ble): BlePeerRegistry — state + tiebreak"
```

---

## Task T6: TransportPreference — per-peer transport choice

**Files:**
- Create: `lib/core/mesh/transport/transport_preference.dart`
- Create: `test/core/mesh/transport/transport_preference_test.dart`

- [ ] **Step 1: Write failing tests**

Create `test/core/mesh/transport/transport_preference_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';

import 'package:taler_id_mobile/core/mesh/transport/transport_preference.dart';

void main() {
  group('TransportPreference', () {
    test('bonjour beats ble when both available', () {
      final pref = TransportPreference();
      final choice = pref.chooseAmong({TransportId.ble, TransportId.bonjour});
      expect(choice, equals(TransportId.bonjour));
    });

    test('ble only when bonjour absent', () {
      final pref = TransportPreference();
      expect(
        pref.chooseAmong({TransportId.ble}),
        equals(TransportId.ble),
      );
    });

    test('bonjour only when ble absent', () {
      final pref = TransportPreference();
      expect(
        pref.chooseAmong({TransportId.bonjour}),
        equals(TransportId.bonjour),
      );
    });

    test('throws on empty set', () {
      final pref = TransportPreference();
      expect(() => pref.chooseAmong({}), throwsStateError);
    });

    test('orderedAmong returns bonjour first, then ble', () {
      final pref = TransportPreference();
      expect(
        pref.orderedAmong({TransportId.ble, TransportId.bonjour}),
        equals([TransportId.bonjour, TransportId.ble]),
      );
    });
  });
}
```

- [ ] **Step 2: Run — expect FAIL**

```bash
cd ~/Downloads/taler_id_mesh
flutter test test/core/mesh/transport/transport_preference_test.dart 2>&1 | tail -5
```

Expected: import error for missing module.

- [ ] **Step 3: Implement TransportPreference**

Create `lib/core/mesh/transport/transport_preference.dart`:

```dart
/// Stable identifier for a concrete [MeshTransport] implementation.
///
/// Used by [MultiTransport] to route `send()` to the highest-preference
/// transport that knows a given peer.
enum TransportId {
  /// Bonjour / mDNS over TCP — only works when both peers share a LAN,
  /// but has the highest bandwidth. Phase 1a.
  bonjour,

  /// BLE advertising + GATT. Works offline; ~100-200 Kbps. Phase 1d.
  ble,
}

/// Pure function policy for picking a transport among the set that knows
/// a given peer. Order chosen for Phase 1d: [bonjour] beats [ble] because
/// bandwidth matters more than novelty when both are available.
class TransportPreference {
  static const List<TransportId> _order = [TransportId.bonjour, TransportId.ble];

  TransportId chooseAmong(Set<TransportId> available) {
    if (available.isEmpty) {
      throw StateError('No available transports to choose from');
    }
    for (final id in _order) {
      if (available.contains(id)) return id;
    }
    // All known transports are in _order — this is unreachable while the
    // enum and _order stay in sync.
    throw StateError('Unknown transports: $available');
  }

  List<TransportId> orderedAmong(Set<TransportId> available) =>
      _order.where(available.contains).toList();
}
```

- [ ] **Step 4: Run — expect all pass**

```bash
cd ~/Downloads/taler_id_mesh
flutter test test/core/mesh/transport/transport_preference_test.dart 2>&1 | tail -5
```

Expected: `+5: All tests passed!`

- [ ] **Step 5: Commit**

```bash
cd ~/Downloads/taler_id_mesh
git add lib/core/mesh/transport/transport_preference.dart test/core/mesh/transport/transport_preference_test.dart
git commit -m "feat(mesh/transport): TransportPreference policy (Bonjour > BLE)"
```

---

## Task T7: BleTransport + BleConnection — the actual BLE transport

**Files:**
- Create: `lib/core/mesh/transport/ble/ble_connection.dart`
- Create: `lib/core/mesh/transport/ble_transport.dart`

### Scope note

`BleTransport` is the largest file in the phase (~400 lines). It is NOT test-covered by unit tests because the underlying BLE plugin APIs cannot be meaningfully stubbed without a hardware integration — those paths are exercised by Task T10's hardware test. What CAN be unit-covered is already split into T4/T5/T6 and into the `BleConnection.parseAdvertisementData` logic below.

- [ ] **Step 1: Write failing test for advertisement parsing**

Create `test/core/mesh/transport/ble_connection_test.dart`:

```dart
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:taler_id_mobile/core/mesh/transport/ble/ble_connection.dart';

void main() {
  group('BleConnection.parseAdvertisementData', () {
    test('parses 8-byte devicePk prefix + flags + version from 10 bytes', () {
      final mfg = Uint8List.fromList([
        0xAB, 0xCD, 0xEF, 0x01, 0x23, 0x45, 0x67, 0x89, // 8B prefix
        0x00, // flags
        0x01, // version
      ]);
      final parsed = BleConnection.parseAdvertisementData(mfg);
      expect(parsed, isNotNull);
      expect(parsed!.devicePkPrefix,
          equals(Uint8List.fromList([0xAB, 0xCD, 0xEF, 0x01, 0x23, 0x45, 0x67, 0x89])));
      expect(parsed.flags, equals(0));
      expect(parsed.version, equals(1));
    });

    test('returns null for too-short buffer', () {
      final mfg = Uint8List.fromList([0xAB, 0xCD]);
      expect(BleConnection.parseAdvertisementData(mfg), isNull);
    });

    test('returns null for wrong version', () {
      final mfg = Uint8List.fromList([
        0xAB, 0xCD, 0xEF, 0x01, 0x23, 0x45, 0x67, 0x89,
        0x00,
        0x02, // unsupported version
      ]);
      expect(BleConnection.parseAdvertisementData(mfg), isNull);
    });
  });
}
```

- [ ] **Step 2: Run — expect FAIL**

```bash
cd ~/Downloads/taler_id_mesh
flutter test test/core/mesh/transport/ble_connection_test.dart 2>&1 | tail -5
```

Expected: import error.

- [ ] **Step 3: Implement BleConnection (advertisement + GATT link)**

Create `lib/core/mesh/transport/ble/ble_connection.dart`:

```dart
import 'dart:typed_data';

/// Parsed BLE advertisement payload for the mesh service.
class ParsedAdvertisement {
  final Uint8List devicePkPrefix; // 8 bytes
  final int flags;                // reserved, 0 in Phase 1d
  final int version;              // must equal 1

  ParsedAdvertisement({
    required this.devicePkPrefix,
    required this.flags,
    required this.version,
  });
}

/// Helpers for the BLE connection-level protocol.
///
/// Advertisement wire format (10 bytes of manufacturer data):
/// ```
/// ┌──────────────────────┬──────┬──────────┐
/// │ devicePk prefix (8B) │flags │ version  │
/// │                      │ (1B) │ (1B)     │
/// └──────────────────────┴──────┴──────────┘
/// ```
class BleConnection {
  static const int advertisementVersion = 1;
  static const int advertisementByteLength = 10;

  static ParsedAdvertisement? parseAdvertisementData(Uint8List mfgData) {
    if (mfgData.length < advertisementByteLength) return null;
    final version = mfgData[9];
    if (version != advertisementVersion) return null;
    return ParsedAdvertisement(
      devicePkPrefix: Uint8List.fromList(mfgData.sublist(0, 8)),
      flags: mfgData[8],
      version: version,
    );
  }

  /// Build the 10-byte advertisement manufacturer-data block for our own
  /// device.
  static Uint8List buildAdvertisementData({
    required Uint8List devicePkFull,
    int flags = 0,
  }) {
    if (devicePkFull.length < 8) {
      throw ArgumentError('devicePkFull must be at least 8 bytes');
    }
    final out = Uint8List(advertisementByteLength);
    out.setRange(0, 8, devicePkFull);
    out[8] = flags & 0xFF;
    out[9] = advertisementVersion;
    return out;
  }
}
```

- [ ] **Step 4: Run — expect all pass**

```bash
cd ~/Downloads/taler_id_mesh
flutter test test/core/mesh/transport/ble_connection_test.dart 2>&1 | tail -5
```

Expected: `+3: All tests passed!`

- [ ] **Step 5: Implement BleTransport (the transport wrapper)**

Create `lib/core/mesh/transport/ble_transport.dart`:

```dart
import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_ble_peripheral/flutter_ble_peripheral.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:permission_handler/permission_handler.dart';

import 'ble/ble_connection.dart';
import 'ble/ble_gatt_protocol.dart';
import 'ble/ble_peer_registry.dart';
import 'mesh_transport.dart';
import 'peer_id.dart';

/// BLE-based MeshTransport. Implements discovery (advertising + scanning)
/// and full-duplex data (GATT write / notify).
///
/// Phase 1d scope: 100% active scan, foreground only, lexicographic
/// connection tiebreak. See design doc §5 for wire format details.
class BleTransport implements MeshTransport {
  final _discoveriesCtrl = StreamController<PeerDiscovered>.broadcast();
  final _lossesCtrl = StreamController<PeerLost>.broadcast();
  final _inboundCtrl = StreamController<InboundFrame>.broadcast();

  final FlutterReactiveBle _central = FlutterReactiveBle();
  final FlutterBlePeripheral _peripheral = FlutterBlePeripheral();

  BlePeerRegistry? _registry;
  StreamSubscription<DiscoveredDevice>? _scanSub;
  final Map<PeerId, StreamSubscription<ConnectionStateUpdate>> _connectionSubs = {};
  final Map<PeerId, FrameReassembler> _reassemblers = {};
  final Map<PeerId, DiscoveredDevice> _deviceCache = {};

  bool _started = false;

  @override
  Stream<PeerDiscovered> get discoveries => _discoveriesCtrl.stream;
  @override
  Stream<PeerLost> get losses => _lossesCtrl.stream;
  @override
  Stream<InboundFrame> get inbound => _inboundCtrl.stream;

  @override
  Future<void> startAdvertising(DeviceInfo self) async {
    if (_started) return;
    _registry = BlePeerRegistry(selfPk: self.devicePk);

    final granted = await _ensurePermissions();
    if (!granted) {
      debugPrint('[ble] permissions denied — transport disabled');
      return;
    }

    final mfgData = BleConnection.buildAdvertisementData(
      devicePkFull: self.devicePk.bytes,
    );
    await _peripheral.start(
      advertiseData: AdvertiseData(
        serviceUuid: BleGattProtocol.serviceUuid,
        manufacturerId: 0xFFFF, // unassigned sentinel; mesh-internal only
        manufacturerData: mfgData,
      ),
    );

    _scanSub = _central
        .scanForDevices(withServices: [Uuid.parse(BleGattProtocol.serviceUuid)])
        .listen(
      _handleScanResult,
      onError: (e) => debugPrint('[ble] scan error: $e'),
    );

    _started = true;
    debugPrint('[ble] started advertising + scanning');
  }

  Future<bool> _ensurePermissions() async {
    final needed = <Permission>[
      Permission.bluetoothAdvertise,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
    ];
    for (final p in needed) {
      final status = await p.request();
      if (!status.isGranted) return false;
    }
    return true;
  }

  void _handleScanResult(DiscoveredDevice device) {
    final mfg = device.manufacturerData;
    final parsed = BleConnection.parseAdvertisementData(mfg);
    if (parsed == null) return;
    // We only know the 8-byte prefix from the advertisement. The full
    // PeerId is learned during the Noise handshake. Phase 1d: identify
    // the peer by the prefix tag stored in `attributes`.
    final prefixHex = parsed.devicePkPrefix
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join();
    _discoveriesCtrl.add(PeerDiscovered(
      peerId: _placeholderPeerId(parsed.devicePkPrefix),
      host: device.id, // platform-native device handle (MAC / UUID)
      port: 0,
      attributes: {'ble_prefix': prefixHex},
    ));
    _deviceCache[_placeholderPeerId(parsed.devicePkPrefix)] = device;
  }

  /// Build a synthetic 32-byte PeerId from the 8-byte prefix. Upper
  /// layers treat this opaquely until the Noise handshake learns the
  /// real 32-byte static key.
  PeerId _placeholderPeerId(Uint8List prefix) {
    final bytes = Uint8List(32);
    bytes.setRange(0, 8, prefix);
    return PeerId(bytes);
  }

  @override
  Future<void> connectTo(PeerId peer) async {
    if (!_started) throw StateError('BleTransport not started');
    if (!(_registry!.shouldInitiate(peer))) {
      debugPrint('[ble] skip connect — peer has lower pk, waiting inbound');
      return;
    }
    final device = _deviceCache[peer];
    if (device == null) {
      throw StateError('Unknown BLE device for peer $peer');
    }

    _registry!.mark(peer, BleLinkState.connecting);
    final sub = _central
        .connectToDevice(id: device.id)
        .listen((update) => _handleConnectionState(peer, update));
    _connectionSubs[peer] = sub;
  }

  void _handleConnectionState(PeerId peer, ConnectionStateUpdate update) {
    switch (update.connectionState) {
      case DeviceConnectionState.connected:
        _registry!.mark(peer, BleLinkState.connected);
        _reassemblers[peer] = FrameReassembler()
          ..onFrame = (bytes) => _inboundCtrl.add(
                // Frame.decode will recover type + srcPk from the payload.
                // The transport layer does not inspect it beyond delivering.
                InboundFrame(
                  srcPeer: peer,
                  type: FrameType.data,
                  bytes: bytes,
                ),
              );
        _subscribeCharacteristic(peer);
        break;
      case DeviceConnectionState.disconnected:
        _registry!.forget(peer);
        _reassemblers.remove(peer);
        _lossesCtrl.add(PeerLost(peer));
        _connectionSubs[peer]?.cancel();
        _connectionSubs.remove(peer);
        break;
      case DeviceConnectionState.connecting:
      case DeviceConnectionState.disconnecting:
        break;
    }
  }

  void _subscribeCharacteristic(PeerId peer) {
    final device = _deviceCache[peer]!;
    final ch = QualifiedCharacteristic(
      serviceId: Uuid.parse(BleGattProtocol.serviceUuid),
      characteristicId: Uuid.parse(BleGattProtocol.characteristicUuid),
      deviceId: device.id,
    );
    _central.subscribeToCharacteristic(ch).listen(
          (bytes) => _reassemblers[peer]?.feed(Uint8List.fromList(bytes)),
          onError: (e) => debugPrint('[ble] subscribe error: $e'),
        );
  }

  @override
  Future<void> send(PeerId peer, Uint8List data) async {
    if (!_started) throw StateError('BleTransport not started');
    final device = _deviceCache[peer];
    if (device == null) throw StateError('No BLE device for peer $peer');
    final ch = QualifiedCharacteristic(
      serviceId: Uuid.parse(BleGattProtocol.serviceUuid),
      characteristicId: Uuid.parse(BleGattProtocol.characteristicUuid),
      deviceId: device.id,
    );
    final wire = BleGattProtocol.encodeFrame(data);
    // MTU negotiation is library-internal; we chunk conservatively at 20B.
    final chunks = BleGattProtocol.chunkForMtu(wire, mtu: 20);
    for (final chunk in chunks) {
      await _central.writeCharacteristicWithoutResponse(ch, value: chunk);
    }
  }

  @override
  Future<void> stopAdvertising() async {
    if (!_started) return;
    try {
      await _peripheral.stop();
    } catch (e) {
      debugPrint('[ble] stop peripheral failed: $e');
    }
    await _scanSub?.cancel();
    _scanSub = null;
    _started = false;
  }

  @override
  Future<void> dispose() async {
    await stopAdvertising();
    for (final sub in _connectionSubs.values) {
      await sub.cancel();
    }
    _connectionSubs.clear();
    _reassemblers.clear();
    _deviceCache.clear();
    await _discoveriesCtrl.close();
    await _lossesCtrl.close();
    await _inboundCtrl.close();
  }
}
```

- [ ] **Step 6: Verify static analysis**

```bash
cd ~/Downloads/taler_id_mesh
flutter analyze lib/core/mesh/transport/ 2>&1 | tail -10
```

Expected: `No issues found!` or only minor info-level lints. If real errors appear (missing methods on `FlutterReactiveBle`, wrong types), DO NOT patch-over with casts — escalate. The plugin API may have drifted from the draft code.

- [ ] **Step 7: Commit**

```bash
cd ~/Downloads/taler_id_mesh
git add lib/core/mesh/transport/ble/ble_connection.dart lib/core/mesh/transport/ble_transport.dart test/core/mesh/transport/ble_connection_test.dart
git commit -m "feat(mesh/transport): BleTransport + BleConnection (advertise + GATT)"
```

---

## Task T8: MultiTransport — fan-in composer

**Files:**
- Create: `lib/core/mesh/transport/multi_transport.dart`
- Create: `test/core/mesh/transport/multi_transport_test.dart`

- [ ] **Step 1: Write failing tests**

Create `test/core/mesh/transport/multi_transport_test.dart`:

```dart
import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:taler_id_mobile/core/mesh/transport/frame.dart';
import 'package:taler_id_mobile/core/mesh/transport/mesh_transport.dart';
import 'package:taler_id_mobile/core/mesh/transport/multi_transport.dart';
import 'package:taler_id_mobile/core/mesh/transport/peer_id.dart';
import 'package:taler_id_mobile/core/mesh/transport/transport_preference.dart';

class _FakeTransport implements MeshTransport {
  final TransportId id;
  final discoveriesCtrl = StreamController<PeerDiscovered>.broadcast();
  final lossesCtrl = StreamController<PeerLost>.broadcast();
  final inboundCtrl = StreamController<InboundFrame>.broadcast();
  final List<(PeerId, Uint8List)> sends = [];
  bool failSend = false;

  _FakeTransport(this.id);

  @override
  Stream<PeerDiscovered> get discoveries => discoveriesCtrl.stream;
  @override
  Stream<PeerLost> get losses => lossesCtrl.stream;
  @override
  Stream<InboundFrame> get inbound => inboundCtrl.stream;

  @override
  Future<void> startAdvertising(DeviceInfo self) async {}
  @override
  Future<void> stopAdvertising() async {}
  @override
  Future<void> connectTo(PeerId peer) async {}

  @override
  Future<void> send(PeerId peer, Uint8List data) async {
    if (failSend) throw StateError('fake send failure');
    sends.add((peer, data));
  }

  @override
  Future<void> dispose() async {
    await discoveriesCtrl.close();
    await lossesCtrl.close();
    await inboundCtrl.close();
  }
}

void main() {
  group('MultiTransport', () {
    test('discovery from either child surfaces exactly once per peer',
        () async {
      final bonjour = _FakeTransport(TransportId.bonjour);
      final ble = _FakeTransport(TransportId.ble);
      final multi = MultiTransport(children: {
        TransportId.bonjour: bonjour,
        TransportId.ble: ble,
      });

      final seen = <PeerId>[];
      final sub = multi.discoveries.listen(seen.add);

      final peer = PeerId.fromHex('b' * 64);
      bonjour.discoveriesCtrl.add(PeerDiscovered(peerId: peer, host: 'h', port: 1));
      ble.discoveriesCtrl.add(PeerDiscovered(peerId: peer, host: 'd', port: 0));

      await Future.delayed(const Duration(milliseconds: 20));
      expect(seen.length, equals(1));
      expect(seen.first.peerId, equals(peer));

      await sub.cancel();
      await multi.dispose();
    });

    test('send picks bonjour when both know the peer', () async {
      final bonjour = _FakeTransport(TransportId.bonjour);
      final ble = _FakeTransport(TransportId.ble);
      final multi = MultiTransport(children: {
        TransportId.bonjour: bonjour,
        TransportId.ble: ble,
      });

      final peer = PeerId.fromHex('b' * 64);
      bonjour.discoveriesCtrl.add(PeerDiscovered(peerId: peer, host: 'h', port: 1));
      ble.discoveriesCtrl.add(PeerDiscovered(peerId: peer, host: 'd', port: 0));
      await Future.delayed(const Duration(milliseconds: 20));

      await multi.send(peer, Uint8List.fromList([1, 2, 3]));
      expect(bonjour.sends, hasLength(1));
      expect(ble.sends, isEmpty);

      await multi.dispose();
    });

    test('send falls back to BLE when only BLE knows the peer', () async {
      final bonjour = _FakeTransport(TransportId.bonjour);
      final ble = _FakeTransport(TransportId.ble);
      final multi = MultiTransport(children: {
        TransportId.bonjour: bonjour,
        TransportId.ble: ble,
      });

      final peer = PeerId.fromHex('b' * 64);
      ble.discoveriesCtrl.add(PeerDiscovered(peerId: peer, host: 'd', port: 0));
      await Future.delayed(const Duration(milliseconds: 20));

      await multi.send(peer, Uint8List.fromList([7]));
      expect(bonjour.sends, isEmpty);
      expect(ble.sends, hasLength(1));

      await multi.dispose();
    });

    test('send fallback when preferred transport throws', () async {
      final bonjour = _FakeTransport(TransportId.bonjour)..failSend = true;
      final ble = _FakeTransport(TransportId.ble);
      final multi = MultiTransport(children: {
        TransportId.bonjour: bonjour,
        TransportId.ble: ble,
      });

      final peer = PeerId.fromHex('b' * 64);
      bonjour.discoveriesCtrl.add(PeerDiscovered(peerId: peer, host: 'h', port: 1));
      ble.discoveriesCtrl.add(PeerDiscovered(peerId: peer, host: 'd', port: 0));
      await Future.delayed(const Duration(milliseconds: 20));

      await multi.send(peer, Uint8List.fromList([7]));
      expect(bonjour.sends, isEmpty);
      expect(ble.sends, hasLength(1));

      await multi.dispose();
    });

    test('send throws StateError when no transport knows the peer', () async {
      final bonjour = _FakeTransport(TransportId.bonjour);
      final multi = MultiTransport(children: {TransportId.bonjour: bonjour});

      final peer = PeerId.fromHex('b' * 64);
      expect(
        () => multi.send(peer, Uint8List.fromList([1])),
        throwsStateError,
      );

      await multi.dispose();
    });

    test('loss emitted only when ALL transports lose the peer', () async {
      final bonjour = _FakeTransport(TransportId.bonjour);
      final ble = _FakeTransport(TransportId.ble);
      final multi = MultiTransport(children: {
        TransportId.bonjour: bonjour,
        TransportId.ble: ble,
      });

      final peer = PeerId.fromHex('b' * 64);
      bonjour.discoveriesCtrl.add(PeerDiscovered(peerId: peer, host: 'h', port: 1));
      ble.discoveriesCtrl.add(PeerDiscovered(peerId: peer, host: 'd', port: 0));
      await Future.delayed(const Duration(milliseconds: 20));

      final losses = <PeerId>[];
      final sub = multi.losses.listen((e) => losses.add(e.peerId));

      // Only BLE drops — no loss emitted (bonjour still knows).
      ble.lossesCtrl.add(PeerLost(peer));
      await Future.delayed(const Duration(milliseconds: 20));
      expect(losses, isEmpty);

      // Now bonjour drops too — loss emitted.
      bonjour.lossesCtrl.add(PeerLost(peer));
      await Future.delayed(const Duration(milliseconds: 20));
      expect(losses, equals([peer]));

      await sub.cancel();
      await multi.dispose();
    });

    test('inbound frames from any transport surface through multi', () async {
      final bonjour = _FakeTransport(TransportId.bonjour);
      final ble = _FakeTransport(TransportId.ble);
      final multi = MultiTransport(children: {
        TransportId.bonjour: bonjour,
        TransportId.ble: ble,
      });

      final received = <InboundFrame>[];
      final sub = multi.inbound.listen(received.add);

      final peer = PeerId.fromHex('b' * 64);
      bonjour.inboundCtrl.add(InboundFrame(
        srcPeer: peer,
        type: FrameType.data,
        bytes: Uint8List.fromList([1]),
      ));
      ble.inboundCtrl.add(InboundFrame(
        srcPeer: peer,
        type: FrameType.handshake,
        bytes: Uint8List.fromList([2]),
      ));

      await Future.delayed(const Duration(milliseconds: 20));
      expect(received, hasLength(2));

      await sub.cancel();
      await multi.dispose();
    });
  });
}
```

- [ ] **Step 2: Run — expect FAIL**

```bash
cd ~/Downloads/taler_id_mesh
flutter test test/core/mesh/transport/multi_transport_test.dart 2>&1 | tail -10
```

Expected: import error for missing module.

- [ ] **Step 3: Implement MultiTransport**

Create `lib/core/mesh/transport/multi_transport.dart`:

```dart
import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';

import 'mesh_transport.dart';
import 'peer_id.dart';
import 'transport_preference.dart';

/// Composes multiple [MeshTransport]s into a single unified transport.
///
/// Dedup policy for discovery: first transport to surface a peer wins the
/// event; subsequent surfaces on other transports update internal routing
/// state but do NOT re-emit.
///
/// Routing policy for [send]: per-peer, use [TransportPreference] to pick
/// the best transport that currently knows the peer. Fall back to lower
/// preference on error.
class MultiTransport implements MeshTransport {
  final Map<TransportId, MeshTransport> _children;
  final TransportPreference _preference;

  final _discoveriesCtrl = StreamController<PeerDiscovered>.broadcast();
  final _lossesCtrl = StreamController<PeerLost>.broadcast();
  final _inboundCtrl = StreamController<InboundFrame>.broadcast();

  // Which transports currently know a given peer.
  final Map<PeerId, Set<TransportId>> _knownBy = {};

  final List<StreamSubscription<dynamic>> _subs = [];

  MultiTransport({
    required Map<TransportId, MeshTransport> children,
    TransportPreference? preference,
  })  : _children = children,
        _preference = preference ?? TransportPreference() {
    _wire();
  }

  void _wire() {
    for (final entry in _children.entries) {
      final id = entry.key;
      final t = entry.value;
      _subs.add(t.discoveries.listen((d) => _onDiscover(id, d)));
      _subs.add(t.losses.listen((l) => _onLoss(id, l)));
      _subs.add(t.inbound.listen(_inboundCtrl.add));
    }
  }

  void _onDiscover(TransportId id, PeerDiscovered d) {
    final set = _knownBy.putIfAbsent(d.peerId, () => <TransportId>{});
    final isFirst = set.isEmpty;
    set.add(id);
    if (isFirst) {
      _discoveriesCtrl.add(d);
    }
  }

  void _onLoss(TransportId id, PeerLost l) {
    final set = _knownBy[l.peerId];
    if (set == null) return;
    set.remove(id);
    if (set.isEmpty) {
      _knownBy.remove(l.peerId);
      _lossesCtrl.add(l);
    }
  }

  @override
  Stream<PeerDiscovered> get discoveries => _discoveriesCtrl.stream;
  @override
  Stream<PeerLost> get losses => _lossesCtrl.stream;
  @override
  Stream<InboundFrame> get inbound => _inboundCtrl.stream;

  @override
  Future<void> startAdvertising(DeviceInfo self) async {
    for (final t in _children.values) {
      try {
        await t.startAdvertising(self);
      } catch (e) {
        debugPrint('[multi] child startAdvertising failed: $e');
      }
    }
  }

  @override
  Future<void> stopAdvertising() async {
    for (final t in _children.values) {
      try {
        await t.stopAdvertising();
      } catch (_) {}
    }
  }

  @override
  Future<void> connectTo(PeerId peer) async {
    final set = _knownBy[peer] ?? const <TransportId>{};
    if (set.isEmpty) {
      throw StateError('No transport knows $peer');
    }
    final ordered = _preference.orderedAmong(set);
    for (final id in ordered) {
      try {
        await _children[id]!.connectTo(peer);
        return;
      } catch (e) {
        debugPrint('[multi] connectTo $id failed: $e');
      }
    }
    throw StateError('All transports failed to connect to $peer');
  }

  @override
  Future<void> send(PeerId peer, Uint8List data) async {
    final set = _knownBy[peer] ?? const <TransportId>{};
    if (set.isEmpty) {
      throw StateError('No transport knows $peer');
    }
    final ordered = _preference.orderedAmong(set);
    Object? lastError;
    for (final id in ordered) {
      try {
        await _children[id]!.send(peer, data);
        return;
      } catch (e) {
        debugPrint('[multi] send via $id failed: $e — trying next');
        lastError = e;
      }
    }
    throw StateError('All transports failed to send to $peer: $lastError');
  }

  @override
  Future<void> dispose() async {
    for (final s in _subs) {
      await s.cancel();
    }
    for (final t in _children.values) {
      await t.dispose();
    }
    await _discoveriesCtrl.close();
    await _lossesCtrl.close();
    await _inboundCtrl.close();
  }
}
```

- [ ] **Step 4: Run — expect 7/7 pass**

```bash
cd ~/Downloads/taler_id_mesh
flutter test test/core/mesh/transport/multi_transport_test.dart 2>&1 | tail -5
```

Expected: `+7: All tests passed!`

- [ ] **Step 5: Commit**

```bash
cd ~/Downloads/taler_id_mesh
git add lib/core/mesh/transport/multi_transport.dart test/core/mesh/transport/multi_transport_test.dart
git commit -m "feat(mesh/transport): MultiTransport — fan-in with preference-based routing"
```

---

## Task T9: DI wiring — make MeshTransport resolve to MultiTransport

**Files:**
- Modify: `lib/core/di/service_locator.dart`

- [ ] **Step 1: Wire MultiTransport into service_locator**

Open `lib/core/di/service_locator.dart`. Currently there is no `MeshTransport` registration (Phase 1a/1b/1c registered specific keys and services but not the transport singleton). We add one. After the existing "Mesh Phase 1c" block (where `DeviceKeySyncService` is registered) and BEFORE the `// Data sources` comment, add:

```dart
  // ---------------------------------------------------------------------------
  // Mesh Phase 1d — transport composition
  // ---------------------------------------------------------------------------
  //
  // Bonjour is always present (Phase 1a). BLE is added when the compile-time
  // flag MeshConfig.bleEnabled is true. MultiTransport picks the best path
  // per peer — Bonjour preferred for bandwidth, BLE fallback for offline.
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

Add these imports near the existing mesh imports at the top of the file:

```dart
import '../config/mesh_config.dart';
import '../mesh/transport/ble_transport.dart';
import '../mesh/transport/bonjour_transport.dart';
import '../mesh/transport/mesh_transport.dart';
import '../mesh/transport/multi_transport.dart';
import '../mesh/transport/transport_preference.dart';
```

- [ ] **Step 2: Static analysis**

```bash
cd ~/Downloads/taler_id_mesh
flutter analyze lib/core/di/service_locator.dart 2>&1 | tail -5
```

Expected: `No issues found!`

- [ ] **Step 3: Full mesh lib analyze + tests**

```bash
cd ~/Downloads/taler_id_mesh
flutter analyze lib/core/mesh/ 2>&1 | tail -3
flutter test test/core/mesh/ test/core/config/ 2>&1 | tail -3
```

Expected: clean analyze, all tests green (Phase 1a+1b+1c+1d cumulative).

- [ ] **Step 4: Commit**

```bash
cd ~/Downloads/taler_id_mesh
git add lib/core/di/service_locator.dart
git commit -m "feat(mesh/di): register MultiTransport under MeshConfig.bleEnabled gate"
```

---

## Task T10: Hardware integration test

**Files:**
- Create: `integration_test/ble_peer_discovery_test.dart`

### Scope note

This test is authored to run on two physical Android devices simultaneously. Automated CI cannot run it. Contributors manually execute it during hardware validation before flipping `MESH_BLE_ENABLED` to true in production builds.

- [ ] **Step 1: Create hardware integration test**

Create `integration_test/ble_peer_discovery_test.dart`:

```dart
// Phase 1d hardware integration test — requires TWO physical Android
// devices, Bluetooth enabled, runtime permissions granted, both running
// this test simultaneously.
//
// Manual run (on each device):
//   flutter test integration_test/ble_peer_discovery_test.dart \
//     --flavor dev -t lib/main_dev.dart \
//     --dart-define=FLAVOR=dev \
//     --dart-define=MESH_BLE_ENABLED=true \
//     -d <deviceId>
//
// The test succeeds on each side when the other side's advertisement
// appears within 10 seconds.

import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:taler_id_mobile/core/mesh/crypto/keys/mesh_static_key.dart';
import 'package:taler_id_mobile/core/mesh/transport/ble_transport.dart';
import 'package:taler_id_mobile/core/mesh/transport/mesh_transport.dart';
import 'package:taler_id_mobile/core/mesh/transport/peer_id.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'Phase 1d — BLE advertises and a peer is discovered',
    (tester) async {
      final meshKey = await MeshStaticKey.generate();
      final selfPk = PeerId(meshKey.publicKey);

      final transport = BleTransport();

      final discovered = <PeerDiscovered>[];
      final sub = transport.discoveries.listen(discovered.add);

      await transport.startAdvertising(DeviceInfo(
        devicePk: selfPk,
        serviceName: 'taler-phase1d-test',
      ));

      // Give the peer up to 10 seconds to appear. The test is meaningful
      // only when run simultaneously on two devices — one alone will
      // return discovered.length == 0 and fail.
      final deadline = DateTime.now().add(const Duration(seconds: 10));
      while (DateTime.now().isBefore(deadline) && discovered.isEmpty) {
        await Future.delayed(const Duration(milliseconds: 200));
      }

      expect(
        discovered,
        isNotEmpty,
        reason:
            'Expected to see at least one peer advertising the mesh service. '
            'If running solo, this test cannot pass — run on a second device.',
      );

      await sub.cancel();
      await transport.dispose();
    },
    timeout: const Timeout(Duration(seconds: 30)),
  );
}
```

- [ ] **Step 2: Static analysis**

```bash
cd ~/Downloads/taler_id_mesh
flutter analyze integration_test/ble_peer_discovery_test.dart 2>&1 | tail -5
```

Expected: `No issues found!`

- [ ] **Step 3: Commit**

```bash
cd ~/Downloads/taler_id_mesh
git add integration_test/ble_peer_discovery_test.dart
git commit -m "test(mesh): Phase 1d hardware integration test for BLE peer discovery"
```

---

## Task T11: Final regression sweep + push

- [ ] **Step 1: Full analyze**

```bash
cd ~/Downloads/taler_id_mesh
flutter analyze lib/core/ test/core/ integration_test/ 2>&1 | tail -5
```

Expected: `No issues found!`

- [ ] **Step 2: Full mesh + config test run**

```bash
cd ~/Downloads/taler_id_mesh
flutter test test/core/mesh/ test/core/config/ 2>&1 | tail -3
```

Expected: cumulative Phase 1a+1b+1c+1d unit tests all pass (target: ~95+).

- [ ] **Step 3: Verify BLE is dormant with flag OFF**

Confirm by reading `lib/core/di/service_locator.dart`: the `BleTransport` is constructed only when `MeshConfig.bleEnabled` is true. With the default flag, the shipping app only uses `BonjourTransport`, unchanged from Phase 1c's behaviour.

- [ ] **Step 4: Push branch**

```bash
cd ~/Downloads/taler_id_mesh
git push origin feature/mesh-network
```

- [ ] **Step 5: Do NOT merge**

Per standing instruction: no merges until the full mesh feature is complete. Phase 1e (UI integration + messenger wiring) is next.

---

## Self-Review Notes

### Spec coverage

- Spec §4 Architecture — all new files present, old ones untouched: Tasks T4–T8 ✓
- Spec §5 BLE Protocol — UUIDs in T4, manufacturer-data format in T7 (`BleConnection`), framing in T4, tiebreak in T5, MTU chunking in T4, scan duty-cycle 100% in T7 ✓
- Spec §6 MultiTransport integration — T8 (fan-in, send routing, losses-only-when-all-lost), T9 (DI) ✓
- Spec §7 Permissions & Lifecycle — T3 (manifest + Info.plist), T7 (`_ensurePermissions`) ✓
- Spec §8 Feature flag — T1 (`MeshConfig.bleEnabled`), T9 (gate in service_locator) ✓
- Spec §9 Testing — unit tests T4–T6, T8; hardware test T10 ✓
- Spec §10 Risks — framing malformed-length drop (T4), permission denial graceful (T7), connection race tiebreak (T5) ✓
- Spec §11 Rollout — flag default OFF (T1), hardware test authored (T10), no prod deploy (T11) ✓

### Placeholder scan

- Every code step contains complete code — no TBD / TODO / "add validation"
- Every test step has full test code, no "similar to Task N"
- Every shell command is exact with expected output described
- One genuine deferral: the BleTransport body relies on `flutter_reactive_ble` + `flutter_ble_peripheral` API surface — if those drift, the implementer is told to escalate rather than patch-over. This is a real plugin risk noted in the spec risks table.

### Type consistency

- `MeshTransport` interface (existing) — all children of `MultiTransport` use it unchanged
- `TransportId` enum values (`bonjour`, `ble`) consistent between T6 (`TransportPreference`), T8 (`MultiTransport`), T9 (DI)
- `PeerId` operations: `toHex()` used in T5 tiebreak; equality/hashCode already defined in existing `peer_id.dart`
- `PeerDiscovered` fields match existing `mesh_transport.dart` (`peerId`, `host`, `port`, `attributes`)
- `BleGattProtocol.serviceUuid` / `.characteristicUuid` constants referenced consistently in T4 (definition), T7 (consumed by `BleTransport`)
- `BleLinkState` enum values consistent (`idle`, `connecting`, `connected`) across T5 + T7

---

## Execution Handoff

After saving this plan, offer:

**1. Subagent-Driven (recommended)** — fresh subagent per task with two-stage review.

**2. Inline Execution** — batch execution with checkpoints.

Total: 11 tasks (T1–T11). T7 is the largest (~400 lines of BLE wiring); T10 requires physical devices. All others are mechanical.

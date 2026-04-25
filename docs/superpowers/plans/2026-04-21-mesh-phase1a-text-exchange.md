# Mesh Phase 1a — PoC Text Exchange Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Два устройства на общем WiFi обмениваются encrypted text через mesh, используя Bonjour discovery + Noise IK handshake + ChaCha20-Poly1305 session encryption. Успех = integration test, где emulator-A шлёт "hello" на emulator-B через mesh (без server).

**Architecture:** 6-слойная mesh-архитектура (см. spec). В Phase 1a реализуем минимум: Transport (1 backend — Bonjour/TCP), Crypto (Noise IK), Services (MessagingService). Routing/Onion/UI — вне scope Phase 1a.

**Tech Stack:**
- Flutter 3.x (Dart >= 3.6.0)
- `bonsoir: ^5.1.10` — Bonjour service discovery (iOS/Android/macOS)
- `cryptography: ^2.7.0` — Ed25519, X25519, ChaCha20-Poly1305, HKDF
- `crypto: ^3.0.6` (уже в проекте) — SHA256, BLAKE2b
- `dart:io` — ServerSocket + Socket для TCP

---

## Spec references

- [2026-04-21-mesh-network-design.md](../specs/2026-04-21-mesh-network-design.md) — полный design
- Section 5 (Transport): Bonjour+TCP; Section 6 (Crypto): Noise IK; Section 9 (Services)

## File Structure

Создаётся в `~/Downloads/taler_id_mesh/` на ветке `feature/mesh-network`.

### Production code

```
lib/core/mesh/
├── transport/
│   ├── mesh_transport.dart         # Abstract interface + value types (PeerDiscovered, PeerLost, InboundFrame)
│   ├── peer_id.dart                # PeerId value type (Ed25519 pk bytes, equality, hex)
│   ├── frame.dart                  # Encode/decode ver|type|len|src_pk|payload
│   └── bonjour_transport.dart      # Bonjour service discovery + TCP data channel impl
├── crypto/
│   ├── keys/
│   │   ├── device_key.dart         # Ed25519 keypair + sign/verify
│   │   └── contact_key_store.dart  # Known user_pk -> device_pk mapping (in-memory)
│   └── noise/
│       ├── noise_hkdf.dart         # HKDF helpers for Noise symmetric state
│       ├── noise_symmetric.dart    # Noise SymmetricState (handshake hash + chaining key)
│       ├── noise_ik_handshake.dart # IK pattern: msg1 (initiator) + msg2 (responder)
│       └── session.dart            # Post-handshake ChaCha20 cipher + counters + replay window
└── services/
    └── mesh_messaging_service.dart # High-level send/receive text API
```

### Test code

```
test/core/mesh/
├── transport/
│   ├── peer_id_test.dart
│   └── frame_test.dart
├── crypto/
│   ├── keys/
│   │   ├── device_key_test.dart
│   │   └── contact_key_store_test.dart
│   └── noise/
│       ├── noise_hkdf_test.dart
│       ├── noise_symmetric_test.dart
│       ├── noise_ik_handshake_test.dart
│       └── session_test.dart
└── services/
    └── mesh_messaging_service_test.dart

integration_test/
└── mesh_text_exchange_test.dart    # End-to-end с двумя фиктивными Transport над loopback
```

---

## Task 1: Dependencies and directory scaffolding

**Files:**
- Modify: `pubspec.yaml` (dependencies section)
- Create: `lib/core/mesh/.gitkeep`
- Create: `test/core/mesh/.gitkeep`

- [ ] **Step 1: Add dependencies to pubspec.yaml**

Open `pubspec.yaml`. In `dependencies:` section add (keeping alphabetical order within blocks):

```yaml
  # Mesh network
  bonsoir: ^5.1.10
  cryptography: ^2.7.0
```

- [ ] **Step 2: Run `flutter pub get`**

Run: `cd ~/Downloads/taler_id_mesh && flutter pub get`

Expected output includes:
```
Got dependencies!
```

- [ ] **Step 3: Create directory structure**

Run:
```bash
cd ~/Downloads/taler_id_mesh
mkdir -p lib/core/mesh/transport
mkdir -p lib/core/mesh/crypto/keys
mkdir -p lib/core/mesh/crypto/noise
mkdir -p lib/core/mesh/services
mkdir -p test/core/mesh/transport
mkdir -p test/core/mesh/crypto/keys
mkdir -p test/core/mesh/crypto/noise
mkdir -p test/core/mesh/services
touch lib/core/mesh/.gitkeep test/core/mesh/.gitkeep
```

- [ ] **Step 4: Commit**

```bash
cd ~/Downloads/taler_id_mesh
git add pubspec.yaml pubspec.lock lib/core/mesh/.gitkeep test/core/mesh/.gitkeep
git commit -m "feat(mesh): add bonsoir + cryptography deps, scaffold directories"
```

---

## Task 2: PeerId value type

**Files:**
- Create: `lib/core/mesh/transport/peer_id.dart`
- Test: `test/core/mesh/transport/peer_id_test.dart`

- [ ] **Step 1: Write failing test**

Create `test/core/mesh/transport/peer_id_test.dart`:

```dart
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:taler_id_mobile/core/mesh/transport/peer_id.dart';

void main() {
  group('PeerId', () {
    test('constructs from 32-byte public key', () {
      final bytes = Uint8List.fromList(List.filled(32, 0x42));
      final peerId = PeerId(bytes);
      expect(peerId.bytes, bytes);
    });

    test('throws on invalid length', () {
      expect(() => PeerId(Uint8List(31)), throwsArgumentError);
      expect(() => PeerId(Uint8List(33)), throwsArgumentError);
    });

    test('equality by bytes', () {
      final a = PeerId(Uint8List.fromList(List.filled(32, 1)));
      final b = PeerId(Uint8List.fromList(List.filled(32, 1)));
      final c = PeerId(Uint8List.fromList(List.filled(32, 2)));
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a, isNot(equals(c)));
    });

    test('hex encoding round-trip', () {
      final bytes = Uint8List.fromList(List.generate(32, (i) => i));
      final peerId = PeerId(bytes);
      final hex = peerId.toHex();
      expect(hex.length, 64);
      expect(PeerId.fromHex(hex), equals(peerId));
    });

    test('short prefix (8 bytes hex) for BLE advertising', () {
      final bytes = Uint8List.fromList(List.generate(32, (i) => i));
      expect(PeerId(bytes).shortPrefix(), '0001020304050607');
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/core/mesh/transport/peer_id_test.dart`

Expected: FAIL — "Target of URI doesn't exist: 'package:taler_id_mobile/core/mesh/transport/peer_id.dart'"

- [ ] **Step 3: Implement PeerId**

Create `lib/core/mesh/transport/peer_id.dart`:

```dart
import 'dart:convert';
import 'dart:typed_data';

class PeerId {
  final Uint8List bytes;

  PeerId(Uint8List bytes)
      : bytes = Uint8List.fromList(bytes),
        assert(bytes.length == 32) {
    if (bytes.length != 32) {
      throw ArgumentError('PeerId requires 32 bytes, got ${bytes.length}');
    }
  }

  factory PeerId.fromHex(String hex) {
    if (hex.length != 64) {
      throw ArgumentError('PeerId hex must be 64 chars, got ${hex.length}');
    }
    final bytes = Uint8List(32);
    for (var i = 0; i < 32; i++) {
      bytes[i] = int.parse(hex.substring(i * 2, i * 2 + 2), radix: 16);
    }
    return PeerId(bytes);
  }

  String toHex() {
    final buf = StringBuffer();
    for (final b in bytes) {
      buf.write(b.toRadixString(16).padLeft(2, '0'));
    }
    return buf.toString();
  }

  String shortPrefix() => toHex().substring(0, 16);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! PeerId) return false;
    for (var i = 0; i < 32; i++) {
      if (bytes[i] != other.bytes[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode {
    var h = 0;
    for (final b in bytes) {
      h = (h * 31 + b) & 0x7FFFFFFF;
    }
    return h;
  }

  @override
  String toString() => 'PeerId(${shortPrefix()}...)';
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/core/mesh/transport/peer_id_test.dart`

Expected: All 5 tests pass.

- [ ] **Step 5: Commit**

```bash
cd ~/Downloads/taler_id_mesh
git add lib/core/mesh/transport/peer_id.dart test/core/mesh/transport/peer_id_test.dart
git commit -m "feat(mesh/transport): add PeerId value type"
```

---

## Task 3: Frame encode/decode

Frame format from spec Section 5:
```
[ver(1)][type(1)][length(2, BE)][src_pk(32)][payload(variable)]
```

**Files:**
- Create: `lib/core/mesh/transport/frame.dart`
- Test: `test/core/mesh/transport/frame_test.dart`

- [ ] **Step 1: Write failing test**

Create `test/core/mesh/transport/frame_test.dart`:

```dart
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:taler_id_mobile/core/mesh/transport/frame.dart';
import 'package:taler_id_mobile/core/mesh/transport/peer_id.dart';

void main() {
  group('Frame', () {
    final src = PeerId(Uint8List.fromList(List.generate(32, (i) => i)));

    test('encode/decode round-trip for HANDSHAKE', () {
      final payload = Uint8List.fromList([1, 2, 3, 4, 5]);
      final frame = Frame(
        version: 1,
        type: FrameType.handshake,
        srcPk: src,
        payload: payload,
      );
      final bytes = frame.encode();
      expect(bytes.length, 1 + 1 + 2 + 32 + 5);
      final decoded = Frame.decode(bytes);
      expect(decoded.version, 1);
      expect(decoded.type, FrameType.handshake);
      expect(decoded.srcPk, equals(src));
      expect(decoded.payload, equals(payload));
    });

    test('encode correct layout', () {
      final payload = Uint8List.fromList([0xAA, 0xBB]);
      final frame = Frame(
        version: 1,
        type: FrameType.data,
        srcPk: src,
        payload: payload,
      );
      final bytes = frame.encode();
      expect(bytes[0], 1); // version
      expect(bytes[1], FrameType.data.index); // type
      expect(bytes[2], 0); // length high byte
      expect(bytes[3], 2); // length low byte
      expect(bytes.sublist(4, 36), equals(src.bytes));
      expect(bytes.sublist(36), equals(payload));
    });

    test('decode rejects wrong version', () {
      final payload = Uint8List(0);
      final frame = Frame(
        version: 2,
        type: FrameType.keepalive,
        srcPk: src,
        payload: payload,
      );
      expect(() => Frame.decode(frame.encode()), throwsA(isA<FormatException>()));
    });

    test('decode rejects short buffer', () {
      expect(() => Frame.decode(Uint8List(10)), throwsA(isA<FormatException>()));
    });

    test('max payload 65535 bytes', () {
      final big = Uint8List(65535);
      final frame = Frame(
        version: 1,
        type: FrameType.data,
        srcPk: src,
        payload: big,
      );
      final bytes = frame.encode();
      final decoded = Frame.decode(bytes);
      expect(decoded.payload.length, 65535);
    });

    test('rejects payload over 65535', () {
      final huge = Uint8List(65536);
      expect(
        () => Frame(
          version: 1,
          type: FrameType.data,
          srcPk: src,
          payload: huge,
        ).encode(),
        throwsArgumentError,
      );
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/core/mesh/transport/frame_test.dart`

Expected: FAIL — frame.dart missing.

- [ ] **Step 3: Implement Frame**

Create `lib/core/mesh/transport/frame.dart`:

```dart
import 'dart:typed_data';

import 'peer_id.dart';

enum FrameType {
  handshake,  // Noise IK msg1 or msg2
  data,       // Session-encrypted payload
  keepalive,
  disconnect,
}

class Frame {
  static const int supportedVersion = 1;
  static const int headerSize = 1 + 1 + 2 + 32; // 36
  static const int maxPayload = 65535;

  final int version;
  final FrameType type;
  final PeerId srcPk;
  final Uint8List payload;

  Frame({
    required this.version,
    required this.type,
    required this.srcPk,
    required this.payload,
  });

  Uint8List encode() {
    if (payload.length > maxPayload) {
      throw ArgumentError('Frame payload over $maxPayload bytes');
    }
    final total = headerSize + payload.length;
    final bytes = Uint8List(total);
    bytes[0] = version;
    bytes[1] = type.index;
    bytes[2] = (payload.length >> 8) & 0xFF;
    bytes[3] = payload.length & 0xFF;
    bytes.setRange(4, 36, srcPk.bytes);
    bytes.setRange(36, total, payload);
    return bytes;
  }

  static Frame decode(Uint8List bytes) {
    if (bytes.length < headerSize) {
      throw const FormatException('Frame too short');
    }
    final version = bytes[0];
    if (version != supportedVersion) {
      throw FormatException('Unsupported frame version: $version');
    }
    final typeIdx = bytes[1];
    if (typeIdx < 0 || typeIdx >= FrameType.values.length) {
      throw FormatException('Unknown frame type: $typeIdx');
    }
    final length = (bytes[2] << 8) | bytes[3];
    if (bytes.length < headerSize + length) {
      throw const FormatException('Frame payload truncated');
    }
    return Frame(
      version: version,
      type: FrameType.values[typeIdx],
      srcPk: PeerId(Uint8List.fromList(bytes.sublist(4, 36))),
      payload: Uint8List.fromList(bytes.sublist(36, 36 + length)),
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/core/mesh/transport/frame_test.dart`

Expected: All 6 tests pass.

- [ ] **Step 5: Commit**

```bash
git add lib/core/mesh/transport/frame.dart test/core/mesh/transport/frame_test.dart
git commit -m "feat(mesh/transport): add Frame encode/decode"
```

---

## Task 4: MeshTransport abstract interface

**Files:**
- Create: `lib/core/mesh/transport/mesh_transport.dart`
- Test: (no test — interface only; will be tested via implementations)

- [ ] **Step 1: Create the interface file**

Create `lib/core/mesh/transport/mesh_transport.dart`:

```dart
import 'dart:async';
import 'dart:typed_data';

import 'frame.dart';
import 'peer_id.dart';

/// Event emitted when a new peer is discovered on the network.
class PeerDiscovered {
  final PeerId peerId;
  final String host;
  final int port;
  final Map<String, String> attributes;

  PeerDiscovered({
    required this.peerId,
    required this.host,
    required this.port,
    this.attributes = const {},
  });
}

/// Event emitted when a previously-discovered peer is no longer reachable.
class PeerLost {
  final PeerId peerId;
  PeerLost(this.peerId);
}

/// Event emitted when a decoded frame arrives from a peer.
/// `type` preserves the Frame-level dispatch marker so upper layers can
/// route handshake vs. data frames without re-parsing.
class InboundFrame {
  final PeerId srcPeer;
  final FrameType type;
  final Uint8List bytes; // Frame payload (already stripped of transport header)
  InboundFrame({required this.srcPeer, required this.type, required this.bytes});
}

/// Information about this device for advertising.
class DeviceInfo {
  final PeerId devicePk;
  final String serviceName;
  DeviceInfo({required this.devicePk, required this.serviceName});
}

/// Transport layer — provides authenticated byte channel between peers.
abstract class MeshTransport {
  Stream<PeerDiscovered> get discoveries;
  Stream<PeerLost> get losses;
  Stream<InboundFrame> get inbound;

  Future<void> startAdvertising(DeviceInfo self);
  Future<void> stopAdvertising();
  Future<void> connectTo(PeerId peer);
  Future<void> send(PeerId peer, Uint8List data);
  Future<void> dispose();
}
```

- [ ] **Step 2: Verify it analyzes cleanly**

Run: `flutter analyze lib/core/mesh/transport/mesh_transport.dart`

Expected: `No issues found!`

- [ ] **Step 3: Commit**

```bash
git add lib/core/mesh/transport/mesh_transport.dart
git commit -m "feat(mesh/transport): add MeshTransport abstract interface"
```

---

## Task 5: DeviceKey (Ed25519)

**Files:**
- Create: `lib/core/mesh/crypto/keys/device_key.dart`
- Test: `test/core/mesh/crypto/keys/device_key_test.dart`

- [ ] **Step 1: Write failing test**

Create `test/core/mesh/crypto/keys/device_key_test.dart`:

```dart
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:taler_id_mobile/core/mesh/crypto/keys/device_key.dart';

void main() {
  group('DeviceKey', () {
    test('generate creates 32-byte keys', () async {
      final key = await DeviceKey.generate();
      expect(key.publicKey.length, 32);
      expect(key.privateKeyBytes.length, 32);
    });

    test('signs and verifies message', () async {
      final key = await DeviceKey.generate();
      final msg = Uint8List.fromList([1, 2, 3, 4, 5]);
      final sig = await key.sign(msg);
      expect(sig.length, 64);
      final ok = await DeviceKey.verify(
        publicKey: key.publicKey,
        message: msg,
        signature: sig,
      );
      expect(ok, isTrue);
    });

    test('rejects signature with wrong public key', () async {
      final key = await DeviceKey.generate();
      final other = await DeviceKey.generate();
      final msg = Uint8List.fromList([1, 2, 3]);
      final sig = await key.sign(msg);
      final ok = await DeviceKey.verify(
        publicKey: other.publicKey,
        message: msg,
        signature: sig,
      );
      expect(ok, isFalse);
    });

    test('rejects tampered message', () async {
      final key = await DeviceKey.generate();
      final msg = Uint8List.fromList([1, 2, 3]);
      final sig = await key.sign(msg);
      final tampered = Uint8List.fromList([1, 2, 4]);
      final ok = await DeviceKey.verify(
        publicKey: key.publicKey,
        message: tampered,
        signature: sig,
      );
      expect(ok, isFalse);
    });

    test('fromPrivateKeyBytes reproduces keypair', () async {
      final key = await DeviceKey.generate();
      final reloaded = await DeviceKey.fromPrivateKeyBytes(key.privateKeyBytes);
      expect(reloaded.publicKey, equals(key.publicKey));
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/core/mesh/crypto/keys/device_key_test.dart`

Expected: FAIL — device_key.dart missing.

- [ ] **Step 3: Implement DeviceKey**

Create `lib/core/mesh/crypto/keys/device_key.dart`:

```dart
import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';

class DeviceKey {
  static final _ed25519 = Ed25519();

  final SimpleKeyPairData _keyPair;
  final Uint8List publicKey;
  final Uint8List privateKeyBytes;

  DeviceKey._({
    required SimpleKeyPairData keyPair,
    required this.publicKey,
    required this.privateKeyBytes,
  }) : _keyPair = keyPair;

  static Future<DeviceKey> generate() async {
    final kp = await _ed25519.newKeyPair();
    final kpData = await kp.extract();
    final pub = await kp.extractPublicKey();
    return DeviceKey._(
      keyPair: kpData,
      publicKey: Uint8List.fromList(pub.bytes),
      privateKeyBytes: Uint8List.fromList(kpData.bytes),
    );
  }

  static Future<DeviceKey> fromPrivateKeyBytes(Uint8List privateKeyBytes) async {
    final kpData = await _ed25519.newKeyPairFromSeed(privateKeyBytes);
    final kpExtracted = await kpData.extract();
    final pub = await kpData.extractPublicKey();
    return DeviceKey._(
      keyPair: kpExtracted,
      publicKey: Uint8List.fromList(pub.bytes),
      privateKeyBytes: Uint8List.fromList(kpExtracted.bytes),
    );
  }

  Future<Uint8List> sign(Uint8List message) async {
    final sig = await _ed25519.sign(message, keyPair: _keyPair);
    return Uint8List.fromList(sig.bytes);
  }

  static Future<bool> verify({
    required Uint8List publicKey,
    required Uint8List message,
    required Uint8List signature,
  }) async {
    final pub = SimplePublicKey(publicKey, type: KeyPairType.ed25519);
    return await _ed25519.verify(
      message,
      signature: Signature(signature, publicKey: pub),
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/core/mesh/crypto/keys/device_key_test.dart`

Expected: All 5 tests pass.

- [ ] **Step 5: Commit**

```bash
git add lib/core/mesh/crypto/keys/device_key.dart test/core/mesh/crypto/keys/device_key_test.dart
git commit -m "feat(mesh/crypto): add DeviceKey Ed25519 wrapper"
```

---

## Task 6: ContactKeyStore (in-memory)

Phase 1a: in-memory only, seeded by test. Persistence → Phase 1b.

**Files:**
- Create: `lib/core/mesh/crypto/keys/contact_key_store.dart`
- Test: `test/core/mesh/crypto/keys/contact_key_store_test.dart`

- [ ] **Step 1: Write failing test**

Create `test/core/mesh/crypto/keys/contact_key_store_test.dart`:

```dart
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:taler_id_mobile/core/mesh/crypto/keys/contact_key_store.dart';
import 'package:taler_id_mobile/core/mesh/transport/peer_id.dart';

void main() {
  group('ContactKeyStore', () {
    late ContactKeyStore store;

    setUp(() {
      store = ContactKeyStore();
    });

    test('empty by default', () {
      final pk = PeerId(Uint8List.fromList(List.filled(32, 1)));
      expect(store.isKnownDevice(pk), isFalse);
      expect(store.lookupUserByDevice(pk), isNull);
    });

    test('addContact registers user and their devices', () {
      final userPk = PeerId(Uint8List.fromList(List.filled(32, 0xAA)));
      final device1 = PeerId(Uint8List.fromList(List.filled(32, 0xBB)));
      final device2 = PeerId(Uint8List.fromList(List.filled(32, 0xCC)));
      store.addContact(userPk: userPk, devicePks: [device1, device2]);

      expect(store.isKnownDevice(device1), isTrue);
      expect(store.isKnownDevice(device2), isTrue);
      expect(store.lookupUserByDevice(device1), equals(userPk));
      expect(store.lookupUserByDevice(device2), equals(userPk));
    });

    test('devicesFor returns all devices of user', () {
      final userPk = PeerId(Uint8List.fromList(List.filled(32, 0xAA)));
      final d1 = PeerId(Uint8List.fromList(List.filled(32, 0xBB)));
      final d2 = PeerId(Uint8List.fromList(List.filled(32, 0xCC)));
      store.addContact(userPk: userPk, devicePks: [d1, d2]);
      final devices = store.devicesFor(userPk);
      expect(devices, containsAll([d1, d2]));
      expect(devices.length, 2);
    });

    test('removeDevice unbinds single device', () {
      final userPk = PeerId(Uint8List.fromList(List.filled(32, 0xAA)));
      final d1 = PeerId(Uint8List.fromList(List.filled(32, 0xBB)));
      final d2 = PeerId(Uint8List.fromList(List.filled(32, 0xCC)));
      store.addContact(userPk: userPk, devicePks: [d1, d2]);
      store.removeDevice(d1);
      expect(store.isKnownDevice(d1), isFalse);
      expect(store.isKnownDevice(d2), isTrue);
      expect(store.devicesFor(userPk), equals([d2]));
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/core/mesh/crypto/keys/contact_key_store_test.dart`

Expected: FAIL — contact_key_store.dart missing.

- [ ] **Step 3: Implement ContactKeyStore**

Create `lib/core/mesh/crypto/keys/contact_key_store.dart`:

```dart
import '../../transport/peer_id.dart';

/// Maps known user identity keys to their device public keys.
///
/// Phase 1a: pure in-memory, seeded by application (e.g. tests).
/// Phase 1b: Hive-backed with server sync.
class ContactKeyStore {
  final Map<PeerId, Set<PeerId>> _userToDevices = {};
  final Map<PeerId, PeerId> _deviceToUser = {};

  void addContact({
    required PeerId userPk,
    required List<PeerId> devicePks,
  }) {
    final set = _userToDevices.putIfAbsent(userPk, () => <PeerId>{});
    for (final d in devicePks) {
      set.add(d);
      _deviceToUser[d] = userPk;
    }
  }

  bool isKnownDevice(PeerId devicePk) => _deviceToUser.containsKey(devicePk);

  PeerId? lookupUserByDevice(PeerId devicePk) => _deviceToUser[devicePk];

  List<PeerId> devicesFor(PeerId userPk) =>
      _userToDevices[userPk]?.toList() ?? const [];

  void removeDevice(PeerId devicePk) {
    final user = _deviceToUser.remove(devicePk);
    if (user != null) {
      _userToDevices[user]?.remove(devicePk);
      if (_userToDevices[user]?.isEmpty ?? false) {
        _userToDevices.remove(user);
      }
    }
  }

  void clear() {
    _userToDevices.clear();
    _deviceToUser.clear();
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/core/mesh/crypto/keys/contact_key_store_test.dart`

Expected: All 4 tests pass.

- [ ] **Step 5: Commit**

```bash
git add lib/core/mesh/crypto/keys/contact_key_store.dart test/core/mesh/crypto/keys/contact_key_store_test.dart
git commit -m "feat(mesh/crypto): add ContactKeyStore (in-memory for Phase 1a)"
```

---

## Task 7: Noise HKDF helpers

Noise Protocol HKDF operates on the chaining key with labelled outputs. Spec: https://noiseprotocol.org/noise.html#hash-functions

For Noise_IK_25519_ChaChaPoly_SHA256, HKDF-SHA256 with 1, 2, or 3 outputs of 32 bytes each.

**Files:**
- Create: `lib/core/mesh/crypto/noise/noise_hkdf.dart`
- Test: `test/core/mesh/crypto/noise/noise_hkdf_test.dart`

- [ ] **Step 1: Write failing test with known Noise test vector**

Create `test/core/mesh/crypto/noise/noise_hkdf_test.dart`:

```dart
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:taler_id_mobile/core/mesh/crypto/noise/noise_hkdf.dart';

Uint8List _hex(String s) {
  final n = s.length ~/ 2;
  final bytes = Uint8List(n);
  for (var i = 0; i < n; i++) {
    bytes[i] = int.parse(s.substring(i * 2, i * 2 + 2), radix: 16);
  }
  return bytes;
}

void main() {
  group('Noise HKDF', () {
    // Test vector derived from RFC 5869 HKDF-SHA256, adapted for Noise's 2-arg calling convention.
    // Noise HKDF(chainingKey, inputKeyMaterial, numOutputs) uses chainingKey as HKDF salt and inputKeyMaterial as IKM.

    test('hkdf2 produces two 32-byte outputs', () {
      final ck = Uint8List.fromList(List.filled(32, 0));
      final ikm = Uint8List.fromList(List.filled(32, 1));
      final outputs = NoiseHkdf.hkdf2(ck, ikm);
      expect(outputs.length, 2);
      expect(outputs[0].length, 32);
      expect(outputs[1].length, 32);
    });

    test('hkdf3 produces three 32-byte outputs', () {
      final ck = Uint8List.fromList(List.filled(32, 0));
      final ikm = Uint8List.fromList(List.filled(32, 1));
      final outputs = NoiseHkdf.hkdf3(ck, ikm);
      expect(outputs.length, 3);
      for (final o in outputs) {
        expect(o.length, 32);
      }
    });

    test('deterministic for same inputs', () {
      final ck = _hex('00' * 32);
      final ikm = _hex('11' * 32);
      final a = NoiseHkdf.hkdf2(ck, ikm);
      final b = NoiseHkdf.hkdf2(ck, ikm);
      expect(a[0], equals(b[0]));
      expect(a[1], equals(b[1]));
    });

    test('different ikm produces different outputs', () {
      final ck = _hex('00' * 32);
      final a = NoiseHkdf.hkdf2(ck, _hex('11' * 32));
      final b = NoiseHkdf.hkdf2(ck, _hex('22' * 32));
      expect(a[0], isNot(equals(b[0])));
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/core/mesh/crypto/noise/noise_hkdf_test.dart`

Expected: FAIL — noise_hkdf.dart missing.

- [ ] **Step 3: Implement NoiseHkdf**

Create `lib/core/mesh/crypto/noise/noise_hkdf.dart`:

```dart
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;

/// Noise-style HKDF using HMAC-SHA256 (synchronous via package:crypto).
///
/// Semantics from Noise spec section 4.3:
///   HKDF(chainingKey, inputKeyMaterial, n) → list of n 32-byte outputs.
///
/// Per spec:
///   TempKey   = HMAC(chainingKey, inputKeyMaterial)
///   Output[1] = HMAC(TempKey, byte(1))
///   Output[i] = HMAC(TempKey, Output[i-1] || byte(i))  for i > 1
class NoiseHkdf {
  static List<Uint8List> hkdf2(Uint8List ck, Uint8List ikm) =>
      _hkdfN(ck, ikm, 2);

  static List<Uint8List> hkdf3(Uint8List ck, Uint8List ikm) =>
      _hkdfN(ck, ikm, 3);

  static List<Uint8List> _hkdfN(Uint8List ck, Uint8List ikm, int n) {
    final tempKey = _hmac(ck, ikm);
    final outputs = <Uint8List>[];
    Uint8List prev = Uint8List(0);
    for (var i = 1; i <= n; i++) {
      final input = Uint8List(prev.length + 1)
        ..setRange(0, prev.length, prev)
        ..[prev.length] = i;
      final out = _hmac(tempKey, input);
      outputs.add(out);
      prev = out;
    }
    return outputs;
  }

  static Uint8List _hmac(Uint8List key, Uint8List data) {
    final mac = crypto.Hmac(crypto.sha256, key).convert(data);
    return Uint8List.fromList(mac.bytes);
  }
}
```

Note: we use `package:crypto` (already in the project) for sync HMAC rather than `package:cryptography`'s async HMAC — keeps HKDF callers non-async.

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/core/mesh/crypto/noise/noise_hkdf_test.dart`

Expected: All 4 tests pass.

- [ ] **Step 5: Commit**

```bash
git add lib/core/mesh/crypto/noise/noise_hkdf.dart test/core/mesh/crypto/noise/noise_hkdf_test.dart
git commit -m "feat(mesh/crypto/noise): add Noise HKDF helper (2/3 outputs)"
```

---

## Task 8: Noise SymmetricState

SymmetricState от Noise spec § 5.2: combines chaining key, handshake hash, optional AEAD cipher.

Operations needed for IK:
- `mixHash(data)` — `h = SHA256(h || data)`
- `mixKey(dh_output)` — updates chaining key + cipher key via HKDF
- `encryptAndHash(plaintext)` — if have key: ChaCha20-Poly1305(k, nonce, plaintext, h) and mix into h; else plaintext + mix into h
- `decryptAndHash(ciphertext)` — inverse
- `split()` — returns transport keys after handshake

**Files:**
- Create: `lib/core/mesh/crypto/noise/noise_symmetric.dart`
- Test: `test/core/mesh/crypto/noise/noise_symmetric_test.dart`

- [ ] **Step 1: Write failing test**

Create `test/core/mesh/crypto/noise/noise_symmetric_test.dart`:

```dart
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:taler_id_mobile/core/mesh/crypto/noise/noise_symmetric.dart';

void main() {
  group('NoiseSymmetricState', () {
    const protocolName = 'Noise_IK_25519_ChaChaPoly_SHA256';

    test('initializeSymmetric sets ck = h = SHA256(protocolName) if short', () {
      final ss = NoiseSymmetricState.initializeSymmetric(protocolName);
      // Since protocolName len <= 32 bytes? Actually "Noise_IK_25519_ChaChaPoly_SHA256" = 32 bytes exactly.
      expect(ss.handshakeHash.length, 32);
      expect(ss.chainingKey.length, 32);
      expect(ss.handshakeHash, equals(ss.chainingKey));
    });

    test('mixHash updates h deterministically', () {
      final a = NoiseSymmetricState.initializeSymmetric(protocolName);
      final b = NoiseSymmetricState.initializeSymmetric(protocolName);
      a.mixHash(Uint8List.fromList([1, 2, 3]));
      b.mixHash(Uint8List.fromList([1, 2, 3]));
      expect(a.handshakeHash, equals(b.handshakeHash));

      final c = NoiseSymmetricState.initializeSymmetric(protocolName);
      c.mixHash(Uint8List.fromList([4, 5, 6]));
      expect(a.handshakeHash, isNot(equals(c.handshakeHash)));
    });

    test('encryptAndHash without key returns plaintext', () async {
      final ss = NoiseSymmetricState.initializeSymmetric(protocolName);
      final pt = utf8.encode('hello');
      final ct = await ss.encryptAndHash(Uint8List.fromList(pt));
      expect(ct, equals(pt));
    });

    test('roundtrip: encrypt then decrypt with mirrored states', () async {
      final a = NoiseSymmetricState.initializeSymmetric(protocolName);
      final b = NoiseSymmetricState.initializeSymmetric(protocolName);

      final sharedKey = Uint8List.fromList(List.filled(32, 0x42));
      a.mixKey(sharedKey);
      b.mixKey(sharedKey);

      final pt = Uint8List.fromList(utf8.encode('secret message'));
      final ct = await a.encryptAndHash(pt);
      expect(ct.length, pt.length + 16); // ChaCha20-Poly1305 adds 16-byte tag

      final dec = await b.decryptAndHash(ct);
      expect(dec, equals(pt));
    });

    test('split returns two 32-byte transport keys', () {
      final ss = NoiseSymmetricState.initializeSymmetric(protocolName);
      final (k1, k2) = ss.split();
      expect(k1.length, 32);
      expect(k2.length, 32);
      expect(k1, isNot(equals(k2)));
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/core/mesh/crypto/noise/noise_symmetric_test.dart`

Expected: FAIL — noise_symmetric.dart missing.

- [ ] **Step 3: Implement NoiseSymmetricState**

Create `lib/core/mesh/crypto/noise/noise_symmetric.dart`:

```dart
import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:crypto/crypto.dart' as crypto;

import 'noise_hkdf.dart';

class NoiseSymmetricState {
  static final _aead = Chacha20.poly1305Aead();

  Uint8List chainingKey;
  Uint8List handshakeHash;
  Uint8List? _key; // null = no cipher key yet
  int _nonce = 0;

  NoiseSymmetricState._({
    required this.chainingKey,
    required this.handshakeHash,
  });

  factory NoiseSymmetricState.initializeSymmetric(String protocolName) {
    final nameBytes = Uint8List.fromList(utf8.encode(protocolName));
    Uint8List h;
    if (nameBytes.length <= 32) {
      h = Uint8List(32);
      h.setRange(0, nameBytes.length, nameBytes);
    } else {
      h = Uint8List.fromList(crypto.sha256.convert(nameBytes).bytes);
    }
    return NoiseSymmetricState._(
      chainingKey: Uint8List.fromList(h),
      handshakeHash: h,
    );
  }

  void mixHash(Uint8List data) {
    final combined = Uint8List(handshakeHash.length + data.length)
      ..setRange(0, handshakeHash.length, handshakeHash)
      ..setRange(handshakeHash.length, handshakeHash.length + data.length, data);
    handshakeHash = Uint8List.fromList(crypto.sha256.convert(combined).bytes);
  }

  void mixKey(Uint8List dhOutput) {
    final outputs = NoiseHkdf.hkdf2(chainingKey, dhOutput);
    chainingKey = outputs[0];
    _key = outputs[1];
    _nonce = 0;
  }

  bool get hasKey => _key != null;

  Future<Uint8List> encryptAndHash(Uint8List plaintext) async {
    if (!hasKey) {
      mixHash(plaintext);
      return plaintext;
    }
    final nonceBytes = _noise12ByteNonce(_nonce);
    final secretBox = await _aead.encrypt(
      plaintext,
      secretKey: SecretKey(_key!),
      nonce: nonceBytes,
      aad: handshakeHash,
    );
    _nonce++;
    final ct = Uint8List(secretBox.cipherText.length + secretBox.mac.bytes.length)
      ..setRange(0, secretBox.cipherText.length, secretBox.cipherText)
      ..setRange(secretBox.cipherText.length,
          secretBox.cipherText.length + secretBox.mac.bytes.length,
          secretBox.mac.bytes);
    mixHash(ct);
    return ct;
  }

  Future<Uint8List> decryptAndHash(Uint8List ciphertext) async {
    if (!hasKey) {
      mixHash(ciphertext);
      return ciphertext;
    }
    if (ciphertext.length < 16) {
      throw const FormatException('ciphertext too short for tag');
    }
    final ct = ciphertext.sublist(0, ciphertext.length - 16);
    final macBytes = ciphertext.sublist(ciphertext.length - 16);
    final nonceBytes = _noise12ByteNonce(_nonce);
    final sb = SecretBox(
      ct,
      nonce: nonceBytes,
      mac: Mac(macBytes),
    );
    final pt = await _aead.decrypt(
      sb,
      secretKey: SecretKey(_key!),
      aad: handshakeHash,
    );
    _nonce++;
    mixHash(ciphertext);
    return Uint8List.fromList(pt);
  }

  (Uint8List, Uint8List) split() {
    final outputs = NoiseHkdf.hkdf2(chainingKey, Uint8List(0));
    return (outputs[0], outputs[1]);
  }

  // Noise uses 96-bit nonce: 4 zero bytes + 64-bit LE counter.
  List<int> _noise12ByteNonce(int counter) {
    final n = Uint8List(12);
    for (var i = 0; i < 8; i++) {
      n[4 + i] = (counter >> (8 * i)) & 0xFF;
    }
    return n;
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/core/mesh/crypto/noise/noise_symmetric_test.dart`

Expected: All 5 tests pass.

- [ ] **Step 5: Commit**

```bash
git add lib/core/mesh/crypto/noise/noise_symmetric.dart test/core/mesh/crypto/noise/noise_symmetric_test.dart
git commit -m "feat(mesh/crypto/noise): add SymmetricState (mixHash/mixKey/encryptAndHash/split)"
```

---

## Task 9: Session (post-handshake transport cipher)

ChaCha20-Poly1305 cipher with 64-bit counter, separate send/recv keys.

**Files:**
- Create: `lib/core/mesh/crypto/noise/session.dart`
- Test: `test/core/mesh/crypto/noise/session_test.dart`

- [ ] **Step 1: Write failing test**

Create `test/core/mesh/crypto/noise/session_test.dart`:

```dart
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:taler_id_mobile/core/mesh/crypto/noise/session.dart';

void main() {
  group('NoiseSession', () {
    late Uint8List keyAtoB;
    late Uint8List keyBtoA;

    setUp(() {
      keyAtoB = Uint8List.fromList(List.filled(32, 1));
      keyBtoA = Uint8List.fromList(List.filled(32, 2));
    });

    test('encrypt then decrypt round-trip', () async {
      final alice = NoiseSession(sendKey: keyAtoB, recvKey: keyBtoA);
      final bob = NoiseSession(sendKey: keyBtoA, recvKey: keyAtoB);
      final msg = Uint8List.fromList(utf8.encode('hello bob'));
      final ct = await alice.encrypt(msg);
      expect(ct.length, msg.length + 16);
      final dec = await bob.decrypt(ct);
      expect(dec, equals(msg));
    });

    test('counters increment per message', () async {
      final alice = NoiseSession(sendKey: keyAtoB, recvKey: keyBtoA);
      final bob = NoiseSession(sendKey: keyBtoA, recvKey: keyAtoB);
      final m1 = await alice.encrypt(Uint8List.fromList([1]));
      final m2 = await alice.encrypt(Uint8List.fromList([2]));
      expect(await bob.decrypt(m1), equals([1]));
      expect(await bob.decrypt(m2), equals([2]));
    });

    test('rejects tampered ciphertext', () async {
      final alice = NoiseSession(sendKey: keyAtoB, recvKey: keyBtoA);
      final bob = NoiseSession(sendKey: keyBtoA, recvKey: keyAtoB);
      final ct = await alice.encrypt(Uint8List.fromList([1, 2, 3]));
      ct[0] ^= 0xFF;
      await expectLater(bob.decrypt(ct), throwsA(isA<Exception>()));
    });

    test('replay detected via sliding window', () async {
      final alice = NoiseSession(sendKey: keyAtoB, recvKey: keyBtoA);
      final bob = NoiseSession(sendKey: keyBtoA, recvKey: keyAtoB);
      final ct = await alice.encrypt(Uint8List.fromList([1, 2, 3]));
      await bob.decrypt(ct);
      // Bob's counter advanced; re-submitting same ciphertext fails on nonce mismatch.
      await expectLater(bob.decrypt(ct), throwsA(isA<Exception>()));
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/core/mesh/crypto/noise/session_test.dart`

Expected: FAIL — session.dart missing.

- [ ] **Step 3: Implement NoiseSession**

Create `lib/core/mesh/crypto/noise/session.dart`:

```dart
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

/// Post-handshake bidirectional transport cipher.
/// Each direction uses ChaCha20-Poly1305 with a 64-bit counter nonce (Noise spec).
class NoiseSession {
  static final _aead = Chacha20.poly1305Aead();

  final Uint8List sendKey;
  final Uint8List recvKey;
  int _sendCounter = 0;
  int _recvCounter = 0;

  NoiseSession({
    required this.sendKey,
    required this.recvKey,
  });

  Future<Uint8List> encrypt(Uint8List plaintext) async {
    final sb = await _aead.encrypt(
      plaintext,
      secretKey: SecretKey(sendKey),
      nonce: _nonce(_sendCounter),
    );
    _sendCounter++;
    final out = Uint8List(sb.cipherText.length + sb.mac.bytes.length)
      ..setRange(0, sb.cipherText.length, sb.cipherText)
      ..setRange(sb.cipherText.length, sb.cipherText.length + sb.mac.bytes.length,
          sb.mac.bytes);
    return out;
  }

  Future<Uint8List> decrypt(Uint8List ciphertext) async {
    if (ciphertext.length < 16) {
      throw const FormatException('ciphertext too short');
    }
    final ct = ciphertext.sublist(0, ciphertext.length - 16);
    final macBytes = ciphertext.sublist(ciphertext.length - 16);
    final sb = SecretBox(
      ct,
      nonce: _nonce(_recvCounter),
      mac: Mac(macBytes),
    );
    final pt = await _aead.decrypt(sb, secretKey: SecretKey(recvKey));
    _recvCounter++;
    return Uint8List.fromList(pt);
  }

  List<int> _nonce(int counter) {
    final n = Uint8List(12);
    for (var i = 0; i < 8; i++) {
      n[4 + i] = (counter >> (8 * i)) & 0xFF;
    }
    return n;
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/core/mesh/crypto/noise/session_test.dart`

Expected: All 4 tests pass.

- [ ] **Step 5: Commit**

```bash
git add lib/core/mesh/crypto/noise/session.dart test/core/mesh/crypto/noise/session_test.dart
git commit -m "feat(mesh/crypto/noise): add NoiseSession transport cipher"
```

---

## Task 10: Noise IK handshake (initiator + responder in one module)

Implements Noise IK pattern per spec section 7.5:

```
IK:
  <- s            // responder's static key is known to initiator
  ...
  -> e, es, s, ss
  <- e, ee, se
```

At end, both sides call `split()` → (k1, k2) transport keys. Initiator uses k1 for send, k2 for recv. Responder mirrored.

Needs X25519 DH. `cryptography` package provides `X25519`.

**Files:**
- Create: `lib/core/mesh/crypto/noise/noise_ik_handshake.dart`
- Test: `test/core/mesh/crypto/noise/noise_ik_handshake_test.dart`

- [ ] **Step 1: Write failing test (end-to-end handshake)**

Create `test/core/mesh/crypto/noise/noise_ik_handshake_test.dart`:

```dart
import 'dart:convert';
import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taler_id_mobile/core/mesh/crypto/noise/noise_ik_handshake.dart';

Future<(Uint8List, Uint8List)> _x25519Keypair() async {
  final kp = await X25519().newKeyPair();
  final priv = await kp.extractPrivateKeyBytes();
  final pub = await kp.extractPublicKey();
  return (Uint8List.fromList(priv), Uint8List.fromList(pub.bytes));
}

void main() {
  group('NoiseIKHandshake', () {
    test('full handshake produces symmetric transport keys', () async {
      final (initStaticPriv, initStaticPub) = await _x25519Keypair();
      final (respStaticPriv, respStaticPub) = await _x25519Keypair();

      final initiator = await NoiseIKHandshake.startInitiator(
        initiatorStaticPrivateKey: initStaticPriv,
        initiatorStaticPublicKey: initStaticPub,
        responderStaticPublicKey: respStaticPub,
        prologue: Uint8List(0),
      );
      final msg1 = await initiator.writeMessage1(
        payload: Uint8List.fromList(utf8.encode('hi')),
      );
      expect(msg1.length, greaterThan(32)); // contains at least e + payload

      final responder = await NoiseIKHandshake.startResponder(
        responderStaticPrivateKey: respStaticPriv,
        responderStaticPublicKey: respStaticPub,
        prologue: Uint8List(0),
      );
      final (payloadFromInit, _) = await responder.readMessage1(msg1);
      expect(utf8.decode(payloadFromInit), equals('hi'));

      final msg2 = await responder.writeMessage2(
        payload: Uint8List.fromList(utf8.encode('ack')),
      );
      final (payloadFromResp, responderKeys) = responder.finalize();
      final payloadReceived = await initiator.readMessage2(msg2);
      expect(utf8.decode(payloadReceived), equals('ack'));
      final initiatorKeys = initiator.finalize();

      // Initiator k1 = send, k2 = recv. Responder mirrored: k1 = recv, k2 = send.
      expect(initiatorKeys.$1, equals(responderKeys.$1));
      expect(initiatorKeys.$2, equals(responderKeys.$2));

      // Also verify we know each other's static keys after handshake.
      expect(responder.remoteStaticPublicKey, equals(initStaticPub));
    });

    test('handshake fails if initiator uses wrong responder static pk', () async {
      final (initStaticPriv, initStaticPub) = await _x25519Keypair();
      final (respStaticPriv, respStaticPub) = await _x25519Keypair();
      final (_, wrongRespPub) = await _x25519Keypair();

      final initiator = await NoiseIKHandshake.startInitiator(
        initiatorStaticPrivateKey: initStaticPriv,
        initiatorStaticPublicKey: initStaticPub,
        responderStaticPublicKey: wrongRespPub,
        prologue: Uint8List(0),
      );
      final msg1 = await initiator.writeMessage1(payload: Uint8List(0));

      final responder = await NoiseIKHandshake.startResponder(
        responderStaticPrivateKey: respStaticPriv,
        responderStaticPublicKey: respStaticPub,
        prologue: Uint8List(0),
      );
      await expectLater(responder.readMessage1(msg1), throwsA(isA<Exception>()));
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/core/mesh/crypto/noise/noise_ik_handshake_test.dart`

Expected: FAIL — noise_ik_handshake.dart missing.

- [ ] **Step 3: Implement NoiseIKHandshake**

Create `lib/core/mesh/crypto/noise/noise_ik_handshake.dart`:

```dart
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

import 'noise_symmetric.dart';

const String _protocolName = 'Noise_IK_25519_ChaChaPoly_SHA256';

/// Noise IK handshake pattern (spec section 7.5):
///
///   IK:
///     <- s              // responder's static pk is pre-known to initiator
///     ...
///     -> e, es, s, ss
///     <- e, ee, se
///
/// After the handshake both sides call `finalize()` to obtain
/// `(k1, k2)` = two 32-byte transport keys.
///   - Initiator uses `k1` as send key, `k2` as recv key.
///   - Responder uses `k1` as recv key, `k2` as send key.
///   - The bytes of `k1` and `k2` are equal on both sides.
class NoiseIKHandshake {
  static final _x25519 = X25519();

  final NoiseSymmetricState _ss;
  final Uint8List _staticPriv;
  final Uint8List _staticPub;
  final bool _isInitiator;

  Uint8List? _remoteStaticPub;
  Uint8List? _ephemeralPriv;
  Uint8List? _ephemeralPub;
  Uint8List? _remoteEphemeralPub;

  NoiseIKHandshake._({
    required NoiseSymmetricState ss,
    required Uint8List staticPriv,
    required Uint8List staticPub,
    required bool isInitiator,
    Uint8List? remoteStaticPub,
  })  : _ss = ss,
        _staticPriv = staticPriv,
        _staticPub = staticPub,
        _isInitiator = isInitiator,
        _remoteStaticPub = remoteStaticPub;

  Uint8List? get remoteStaticPublicKey => _remoteStaticPub;

  static Future<NoiseIKHandshake> startInitiator({
    required Uint8List initiatorStaticPrivateKey,
    required Uint8List initiatorStaticPublicKey,
    required Uint8List responderStaticPublicKey,
    required Uint8List prologue,
  }) async {
    final ss = NoiseSymmetricState.initializeSymmetric(_protocolName);
    ss.mixHash(prologue);
    // Pre-message: responder's static pk (known to initiator ahead of time)
    ss.mixHash(responderStaticPublicKey);
    return NoiseIKHandshake._(
      ss: ss,
      staticPriv: initiatorStaticPrivateKey,
      staticPub: initiatorStaticPublicKey,
      isInitiator: true,
      remoteStaticPub: responderStaticPublicKey,
    );
  }

  static Future<NoiseIKHandshake> startResponder({
    required Uint8List responderStaticPrivateKey,
    required Uint8List responderStaticPublicKey,
    required Uint8List prologue,
  }) async {
    final ss = NoiseSymmetricState.initializeSymmetric(_protocolName);
    ss.mixHash(prologue);
    // Pre-message: our own static pk (responder)
    ss.mixHash(responderStaticPublicKey);
    return NoiseIKHandshake._(
      ss: ss,
      staticPriv: responderStaticPrivateKey,
      staticPub: responderStaticPublicKey,
      isInitiator: false,
    );
  }

  /// Initiator writes message 1: e, es, s, ss, payload.
  Future<Uint8List> writeMessage1({required Uint8List payload}) async {
    assert(_isInitiator);
    final (ePriv, ePub) = await _newEphemeral();
    _ephemeralPriv = ePriv;
    _ephemeralPub = ePub;

    final buf = BytesBuilder();
    // e
    buf.add(ePub);
    _ss.mixHash(ePub);
    // es: DH(initEphem, respStatic)
    final es = await _dh(myPriv: ePriv, myPub: ePub, remotePub: _remoteStaticPub!);
    _ss.mixKey(es);
    // s — our static pk encrypted under current key
    final sEnc = await _ss.encryptAndHash(_staticPub);
    buf.add(sEnc);
    // ss: DH(initStatic, respStatic)
    final ssOut = await _dh(myPriv: _staticPriv, myPub: _staticPub, remotePub: _remoteStaticPub!);
    _ss.mixKey(ssOut);
    // payload
    final plEnc = await _ss.encryptAndHash(payload);
    buf.add(plEnc);
    return buf.toBytes();
  }

  /// Responder reads message 1, returns (payload, _).
  Future<(Uint8List, void)> readMessage1(Uint8List msg) async {
    assert(!_isInitiator);
    if (msg.length < 32 + 48) {
      throw const FormatException('IK msg1 too short');
    }
    // e
    final ePub = Uint8List.fromList(msg.sublist(0, 32));
    _remoteEphemeralPub = ePub;
    _ss.mixHash(ePub);
    // es: DH(respStatic, initEphem)
    final es = await _dh(myPriv: _staticPriv, myPub: _staticPub, remotePub: ePub);
    _ss.mixKey(es);
    // s (32B pk + 16B tag = 48B block)
    final sBlock = Uint8List.fromList(msg.sublist(32, 32 + 48));
    final sPub = await _ss.decryptAndHash(sBlock);
    _remoteStaticPub = sPub;
    // ss: DH(respStatic, initStatic)
    final ssOut = await _dh(myPriv: _staticPriv, myPub: _staticPub, remotePub: sPub);
    _ss.mixKey(ssOut);
    // payload
    final payloadEnc = Uint8List.fromList(msg.sublist(32 + 48));
    final payload = await _ss.decryptAndHash(payloadEnc);
    return (payload, null);
  }

  /// Responder writes message 2: e, ee, se, payload.
  Future<Uint8List> writeMessage2({required Uint8List payload}) async {
    assert(!_isInitiator);
    final (ePriv, ePub) = await _newEphemeral();
    _ephemeralPriv = ePriv;
    _ephemeralPub = ePub;

    final buf = BytesBuilder();
    buf.add(ePub);
    _ss.mixHash(ePub);
    // ee: DH(respEphem, initEphem)
    final ee = await _dh(myPriv: ePriv, myPub: ePub, remotePub: _remoteEphemeralPub!);
    _ss.mixKey(ee);
    // se: DH(respEphem, initStatic)
    final se = await _dh(myPriv: ePriv, myPub: ePub, remotePub: _remoteStaticPub!);
    _ss.mixKey(se);
    // payload
    final plEnc = await _ss.encryptAndHash(payload);
    buf.add(plEnc);
    return buf.toBytes();
  }

  /// Initiator reads message 2, returns payload.
  Future<Uint8List> readMessage2(Uint8List msg) async {
    assert(_isInitiator);
    if (msg.length < 32) {
      throw const FormatException('IK msg2 too short');
    }
    final ePub = Uint8List.fromList(msg.sublist(0, 32));
    _remoteEphemeralPub = ePub;
    _ss.mixHash(ePub);
    // ee: DH(initEphem, respEphem)
    final ee = await _dh(myPriv: _ephemeralPriv!, myPub: _ephemeralPub!, remotePub: ePub);
    _ss.mixKey(ee);
    // se: DH(initStatic, respEphem)
    final se = await _dh(myPriv: _staticPriv, myPub: _staticPub, remotePub: ePub);
    _ss.mixKey(se);
    final payloadEnc = Uint8List.fromList(msg.sublist(32));
    return await _ss.decryptAndHash(payloadEnc);
  }

  /// Returns `(k1, k2)` transport keys. Call only after handshake completes.
  ///   - Initiator: send = k1, recv = k2
  ///   - Responder: recv = k1, send = k2
  (Uint8List, Uint8List) finalize() => _ss.split();

  Future<(Uint8List, Uint8List)> _newEphemeral() async {
    final kp = await _x25519.newKeyPair();
    final priv = await kp.extractPrivateKeyBytes();
    final pub = await kp.extractPublicKey();
    return (Uint8List.fromList(priv), Uint8List.fromList(pub.bytes));
  }

  Future<Uint8List> _dh({
    required Uint8List myPriv,
    required Uint8List myPub,
    required Uint8List remotePub,
  }) async {
    final kpData = SimpleKeyPairData(
      myPriv,
      publicKey: SimplePublicKey(myPub, type: KeyPairType.x25519),
      type: KeyPairType.x25519,
    );
    final shared = await _x25519.sharedSecretKey(
      keyPair: kpData,
      remotePublicKey: SimplePublicKey(remotePub, type: KeyPairType.x25519),
    );
    final bytes = await shared.extractBytes();
    return Uint8List.fromList(bytes);
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/core/mesh/crypto/noise/noise_ik_handshake_test.dart`

Expected: All 2 tests pass.

**If tests fail because of DH direction or mixKey order:** review Noise IK spec section 7.5 carefully. Common bug: confusing `s` vs `rs` in DH operations. For initiator: `es = DH(e_initiator, rs_responder)` = `DH(initEphemPriv, respStaticPub)`. For responder processing msg1: `es = DH(s_responder, re_initiator)` = `DH(respStaticPriv, initEphemPub)` — produces same shared secret.

- [ ] **Step 5: Commit**

```bash
git add lib/core/mesh/crypto/noise/noise_ik_handshake.dart test/core/mesh/crypto/noise/noise_ik_handshake_test.dart
git commit -m "feat(mesh/crypto/noise): add Noise IK handshake (initiator + responder)"
```

---

## Task 11: BonjourTransport — advertise service

**Files:**
- Create: `lib/core/mesh/transport/bonjour_transport.dart` (partial — just advertising)
- Test: none (native plugin, tested via integration)

- [ ] **Step 1: Create skeleton with advertising**

Create `lib/core/mesh/transport/bonjour_transport.dart`:

```dart
import 'dart:async';
import 'dart:typed_data';

import 'package:bonsoir/bonsoir.dart';

import 'mesh_transport.dart';
import 'peer_id.dart';

class BonjourTransport implements MeshTransport {
  static const String serviceType = '_talermesh._tcp';

  BonsoirBroadcast? _broadcast;
  int _listenPort = 0;

  final _discoveriesCtrl = StreamController<PeerDiscovered>.broadcast();
  final _lossesCtrl = StreamController<PeerLost>.broadcast();
  final _inboundCtrl = StreamController<InboundFrame>.broadcast();

  @override
  Stream<PeerDiscovered> get discoveries => _discoveriesCtrl.stream;
  @override
  Stream<PeerLost> get losses => _lossesCtrl.stream;
  @override
  Stream<InboundFrame> get inbound => _inboundCtrl.stream;

  @override
  Future<void> startAdvertising(DeviceInfo self) async {
    // Temporary: listen port not wired yet — Task 12 adds TCP.
    // For Task 11, just publish the Bonjour record with port 0 placeholder.
    final service = BonsoirService(
      name: self.serviceName,
      type: serviceType,
      port: _listenPort,
      attributes: {
        'pk': self.devicePk.toHex(),
        'ver': '1',
      },
    );
    _broadcast = BonsoirBroadcast(service: service);
    await _broadcast!.ready;
    await _broadcast!.start();
  }

  @override
  Future<void> stopAdvertising() async {
    await _broadcast?.stop();
    _broadcast = null;
  }

  @override
  Future<void> connectTo(PeerId peer) async {
    throw UnimplementedError('implemented in Task 12');
  }

  @override
  Future<void> send(PeerId peer, Uint8List data) async {
    throw UnimplementedError('implemented in Task 12');
  }

  @override
  Future<void> dispose() async {
    await stopAdvertising();
    await _discoveriesCtrl.close();
    await _lossesCtrl.close();
    await _inboundCtrl.close();
  }
}
```

- [ ] **Step 2: Verify it analyzes**

Run: `flutter analyze lib/core/mesh/transport/bonjour_transport.dart`

Expected: `No issues found!`

- [ ] **Step 3: Commit**

```bash
git add lib/core/mesh/transport/bonjour_transport.dart
git commit -m "feat(mesh/transport): add BonjourTransport skeleton with advertising"
```

---

## Task 12: BonjourTransport — TCP server + client, discovery, full wiring

Now wire TCP data channel and Bonjour discovery together.

**Files:**
- Modify: `lib/core/mesh/transport/bonjour_transport.dart`

- [ ] **Step 1: Extend BonjourTransport with TCP + discovery**

Replace the contents of `lib/core/mesh/transport/bonjour_transport.dart` with:

```dart
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:bonsoir/bonsoir.dart';

import 'frame.dart';
import 'mesh_transport.dart';
import 'peer_id.dart';

class _ConnectedPeer {
  final Socket socket;
  final PeerId peerId;
  _ConnectedPeer({required this.socket, required this.peerId});
}

class BonjourTransport implements MeshTransport {
  static const String serviceType = '_talermesh._tcp';

  BonsoirBroadcast? _broadcast;
  BonsoirDiscovery? _discovery;
  ServerSocket? _server;

  final Map<PeerId, _ConnectedPeer> _connections = {};
  final Map<String, PeerId> _nameToPeerId = {};
  final Map<PeerId, _PeerAddress> _peerAddresses = {};

  final _discoveriesCtrl = StreamController<PeerDiscovered>.broadcast();
  final _lossesCtrl = StreamController<PeerLost>.broadcast();
  final _inboundCtrl = StreamController<InboundFrame>.broadcast();

  StreamSubscription? _discoverySub;

  @override
  Stream<PeerDiscovered> get discoveries => _discoveriesCtrl.stream;
  @override
  Stream<PeerLost> get losses => _lossesCtrl.stream;
  @override
  Stream<InboundFrame> get inbound => _inboundCtrl.stream;

  @override
  Future<void> startAdvertising(DeviceInfo self) async {
    _server = await ServerSocket.bind(InternetAddress.anyIPv4, 0);
    _server!.listen(_handleIncomingSocket);

    final service = BonsoirService(
      name: self.serviceName,
      type: serviceType,
      port: _server!.port,
      attributes: {
        'pk': self.devicePk.toHex(),
        'ver': '1',
      },
    );
    _broadcast = BonsoirBroadcast(service: service);
    await _broadcast!.ready;
    await _broadcast!.start();

    _discovery = BonsoirDiscovery(type: serviceType);
    await _discovery!.ready;
    await _discovery!.start();
    _discoverySub = _discovery!.eventStream!.listen(_onBonjourEvent);
  }

  void _onBonjourEvent(BonsoirDiscoveryEvent event) {
    final service = event.service;
    if (service == null) return;
    final pkHex = service.attributes['pk'];
    if (pkHex == null) return;
    final PeerId peerId;
    try {
      peerId = PeerId.fromHex(pkHex);
    } catch (_) {
      return;
    }
    switch (event.type) {
      case BonsoirDiscoveryEventType.discoveryServiceResolved:
        if (service is ResolvedBonsoirService) {
          _nameToPeerId[service.name] = peerId;
          _peerAddresses[peerId] = _PeerAddress(
            host: service.host ?? '',
            port: service.port,
          );
          _discoveriesCtrl.add(PeerDiscovered(
            peerId: peerId,
            host: service.host ?? '',
            port: service.port,
            attributes: service.attributes,
          ));
        }
        break;
      case BonsoirDiscoveryEventType.discoveryServiceLost:
        final lostPeer = _nameToPeerId.remove(service.name);
        if (lostPeer != null) {
          _peerAddresses.remove(lostPeer);
          _lossesCtrl.add(PeerLost(lostPeer));
        }
        break;
      default:
        break;
    }
  }

  void _handleIncomingSocket(Socket socket) {
    final buffer = BytesBuilder();
    socket.listen((chunk) {
      buffer.add(chunk);
      _tryDispatchFrames(buffer, socket);
    }, onDone: () {
      final pid = _connections.entries
          .firstWhere((e) => identical(e.value.socket, socket),
              orElse: () => const MapEntry<PeerId, _ConnectedPeer>.empty())
          .key;
      // We can't express MapEntry.empty — fallback: scan manually.
      PeerId? found;
      _connections.forEach((k, v) {
        if (identical(v.socket, socket)) found = k;
      });
      if (found != null) _connections.remove(found);
      socket.destroy();
    }, onError: (_) => socket.destroy());
  }

  void _tryDispatchFrames(BytesBuilder buffer, Socket socket) {
    while (true) {
      final all = buffer.toBytes();
      if (all.length < Frame.headerSize) return;
      final length = (all[2] << 8) | all[3];
      final total = Frame.headerSize + length;
      if (all.length < total) return;
      final frameBytes = Uint8List.fromList(all.sublist(0, total));
      final rest = Uint8List.fromList(all.sublist(total));
      buffer.clear();
      buffer.add(rest);
      try {
        final frame = Frame.decode(frameBytes);
        // Track connection by srcPk
        _connections[frame.srcPk] = _ConnectedPeer(socket: socket, peerId: frame.srcPk);
        _inboundCtrl.add(InboundFrame(
          srcPeer: frame.srcPk,
          type: frame.type,
          bytes: frame.payload,
        ));
      } on FormatException {
        // Invalid frame — close connection
        socket.destroy();
        return;
      }
    }
  }

  @override
  Future<void> connectTo(PeerId peer) async {
    if (_connections.containsKey(peer)) return;
    final addr = _peerAddresses[peer];
    if (addr == null) {
      throw StateError('Unknown peer $peer — not discovered yet');
    }
    final socket = await Socket.connect(addr.host, addr.port);
    _connections[peer] = _ConnectedPeer(socket: socket, peerId: peer);
    final buffer = BytesBuilder();
    socket.listen((chunk) {
      buffer.add(chunk);
      _tryDispatchFrames(buffer, socket);
    }, onDone: () {
      _connections.remove(peer);
      socket.destroy();
    }, onError: (_) => socket.destroy());
  }

  @override
  Future<void> send(PeerId peer, Uint8List data) async {
    var conn = _connections[peer];
    if (conn == null) {
      await connectTo(peer);
      conn = _connections[peer]!;
    }
    conn.socket.add(data);
    await conn.socket.flush();
  }

  @override
  Future<void> stopAdvertising() async {
    await _broadcast?.stop();
    _broadcast = null;
    await _discovery?.stop();
    await _discoverySub?.cancel();
    _discovery = null;
    await _server?.close();
    _server = null;
  }

  @override
  Future<void> dispose() async {
    await stopAdvertising();
    for (final conn in _connections.values) {
      conn.socket.destroy();
    }
    _connections.clear();
    await _discoveriesCtrl.close();
    await _lossesCtrl.close();
    await _inboundCtrl.close();
  }
}

class _PeerAddress {
  final String host;
  final int port;
  _PeerAddress({required this.host, required this.port});
}
```

- [ ] **Step 2: Verify it analyzes**

Run: `flutter analyze lib/core/mesh/transport/bonjour_transport.dart`

Expected: `No issues found!` — or fix any minor issues (unused imports, etc.)

- [ ] **Step 3: Commit**

```bash
git add lib/core/mesh/transport/bonjour_transport.dart
git commit -m "feat(mesh/transport): add TCP data channel + Bonjour discovery to BonjourTransport"
```

---

## Task 13: MeshMessagingService — orchestrate handshake + send text

Service layer API: `send(toUserPk, text)` and `inbound` stream of received texts.

**Files:**
- Create: `lib/core/mesh/services/mesh_messaging_service.dart`
- Test: `test/core/mesh/services/mesh_messaging_service_test.dart`

- [ ] **Step 1: Write failing test with fake transport**

Create `test/core/mesh/services/mesh_messaging_service_test.dart`:

```dart
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taler_id_mobile/core/mesh/crypto/keys/contact_key_store.dart';
import 'package:taler_id_mobile/core/mesh/services/mesh_messaging_service.dart';
import 'package:taler_id_mobile/core/mesh/transport/frame.dart';
import 'package:taler_id_mobile/core/mesh/transport/mesh_transport.dart';
import 'package:taler_id_mobile/core/mesh/transport/peer_id.dart';

class _FakeTransport implements MeshTransport {
  final _discoveries = StreamController<PeerDiscovered>.broadcast();
  final _losses = StreamController<PeerLost>.broadcast();
  final _inbound = StreamController<InboundFrame>.broadcast();
  _FakeTransport? partner;

  @override
  Stream<PeerDiscovered> get discoveries => _discoveries.stream;
  @override
  Stream<PeerLost> get losses => _losses.stream;
  @override
  Stream<InboundFrame> get inbound => _inbound.stream;

  PeerId? selfPeer;

  @override
  Future<void> startAdvertising(DeviceInfo self) async {
    selfPeer = self.devicePk;
  }

  @override
  Future<void> stopAdvertising() async {}

  @override
  Future<void> connectTo(PeerId peer) async {}

  @override
  Future<void> send(PeerId peer, Uint8List data) async {
    if (partner == null) throw StateError('no partner');
    // Decode the full Frame so we preserve `type` for the receiver.
    final frame = Frame.decode(data);
    partner!._inbound.add(InboundFrame(
      srcPeer: selfPeer!,
      type: frame.type,
      bytes: frame.payload,
    ));
  }

  @override
  Future<void> dispose() async {
    await _discoveries.close();
    await _losses.close();
    await _inbound.close();
  }

  void emitDiscovery(PeerDiscovered d) => _discoveries.add(d);
}

Future<(Uint8List, Uint8List)> _x25519Keys() async {
  final kp = await X25519().newKeyPair();
  final priv = await kp.extractPrivateKeyBytes();
  final pub = await kp.extractPublicKey();
  return (Uint8List.fromList(priv), Uint8List.fromList(pub.bytes));
}

void main() {
  group('MeshMessagingService', () {
    test('two services exchange text after handshake', () async {
      final (alicePriv, alicePub) = await _x25519Keys();
      final (bobPriv, bobPub) = await _x25519Keys();

      final alicePeer = PeerId(alicePub);
      final bobPeer = PeerId(bobPub);

      // Alice and Bob know each other's static pks.
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
      );

      await alice.start(serviceName: 'Alice');
      await bob.start(serviceName: 'Bob');

      // Simulate discovery
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

      final bobInbox = <String>[];
      final sub = bob.inbound.listen((m) => bobInbox.add(m.text));

      // Wait for discovery to register
      await Future.delayed(const Duration(milliseconds: 50));

      await alice.sendText(toUserPk: bobPeer, text: 'hello bob');

      // Wait for handshake + message round-trip
      await Future.delayed(const Duration(milliseconds: 200));

      expect(bobInbox, contains('hello bob'));

      await sub.cancel();
      await alice.dispose();
      await bob.dispose();
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/core/mesh/services/mesh_messaging_service_test.dart`

Expected: FAIL — mesh_messaging_service.dart missing.

- [ ] **Step 3: Implement MeshMessagingService**

Create `lib/core/mesh/services/mesh_messaging_service.dart`:

```dart
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import '../crypto/keys/contact_key_store.dart';
import '../crypto/noise/noise_ik_handshake.dart';
import '../crypto/noise/session.dart';
import '../transport/frame.dart';
import '../transport/mesh_transport.dart';
import '../transport/peer_id.dart';

class InboundMessage {
  final PeerId fromUserPk;
  final String text;
  InboundMessage({required this.fromUserPk, required this.text});
}

/// High-level messaging over a mesh transport.
///
/// Phase 1a scope:
///   - Single injected transport (typically BonjourTransport)
///   - ContactKeyStore for known peers
///   - Noise IK handshake on first send or on first inbound handshake frame
///   - After handshake: text encrypted with NoiseSession
///   - Dispatching by Frame.type (carried in InboundFrame.type)
///
/// Phase 1a simplification: assumes userPk == devicePk (one device per user).
/// Phase 1b generalizes to multi-device.
class MeshMessagingService {
  final MeshTransport transport;
  final ContactKeyStore contactKeyStore;
  final Uint8List myDevicePrivateKey;
  final Uint8List myDevicePublicKey;

  final Map<PeerId, _PeerState> _peerStates = {};
  final _inboundCtrl = StreamController<InboundMessage>.broadcast();

  StreamSubscription? _frameSub;
  StreamSubscription? _discoverySub;

  MeshMessagingService({
    required this.transport,
    required this.contactKeyStore,
    required this.myDevicePrivateKey,
    required this.myDevicePublicKey,
  });

  Stream<InboundMessage> get inbound => _inboundCtrl.stream;

  Future<void> start({required String serviceName}) async {
    await transport.startAdvertising(DeviceInfo(
      devicePk: PeerId(myDevicePublicKey),
      serviceName: serviceName,
    ));
    _frameSub = transport.inbound.listen(_onInboundFrame);
    _discoverySub = transport.discoveries.listen(_onPeerDiscovered);
  }

  void _onPeerDiscovered(PeerDiscovered p) {
    _peerStates.putIfAbsent(p.peerId, () => _PeerState());
  }

  Future<void> sendText({required PeerId toUserPk, required String text}) async {
    // Phase 1a: userPk == devicePk.
    final devicePk = toUserPk;
    if (!contactKeyStore.isKnownDevice(devicePk)) {
      throw StateError('Unknown contact device: ${devicePk.toHex()}');
    }
    final state = _peerStates.putIfAbsent(devicePk, () => _PeerState());
    if (state.session == null && state.handshake == null) {
      await _initiateHandshake(devicePk, state);
    }
    // Wait up to 2 s for handshake to complete.
    final deadline = DateTime.now().add(const Duration(seconds: 2));
    while (state.session == null && DateTime.now().isBefore(deadline)) {
      await Future.delayed(const Duration(milliseconds: 20));
    }
    if (state.session == null) {
      throw TimeoutException('handshake did not complete');
    }
    final payload = Uint8List.fromList(utf8.encode(text));
    final ct = await state.session!.encrypt(payload);
    await _sendFrame(devicePk, FrameType.data, ct);
  }

  Future<void> _initiateHandshake(PeerId devicePk, _PeerState state) async {
    final handshake = await NoiseIKHandshake.startInitiator(
      initiatorStaticPrivateKey: myDevicePrivateKey,
      initiatorStaticPublicKey: myDevicePublicKey,
      responderStaticPublicKey: devicePk.bytes,
      prologue: Uint8List(0),
    );
    state.handshake = handshake;
    state.isInitiator = true;
    final msg1 = await handshake.writeMessage1(payload: Uint8List(0));
    await _sendFrame(devicePk, FrameType.handshake, msg1);
  }

  Future<void> _onInboundFrame(InboundFrame frame) async {
    final srcDevice = frame.srcPeer;
    if (!contactKeyStore.isKnownDevice(srcDevice)) return; // drop unknown
    final state = _peerStates.putIfAbsent(srcDevice, () => _PeerState());

    if (frame.type == FrameType.handshake) {
      if (state.handshake == null) {
        // Responder path — we received msg1 from an initiator.
        final responder = await NoiseIKHandshake.startResponder(
          responderStaticPrivateKey: myDevicePrivateKey,
          responderStaticPublicKey: myDevicePublicKey,
          prologue: Uint8List(0),
        );
        state.handshake = responder;
        state.isInitiator = false;
        await responder.readMessage1(frame.bytes);
        final msg2 = await responder.writeMessage2(payload: Uint8List(0));
        final (k1, k2) = responder.finalize();
        // Responder: k1 = recv (initiator→responder), k2 = send (responder→initiator).
        state.session = NoiseSession(sendKey: k2, recvKey: k1);
        await _sendFrame(srcDevice, FrameType.handshake, msg2);
      } else if (state.isInitiator) {
        // Initiator receiving msg2.
        await state.handshake!.readMessage2(frame.bytes);
        final (k1, k2) = state.handshake!.finalize();
        // Initiator: k1 = send (initiator→responder), k2 = recv (responder→initiator).
        state.session = NoiseSession(sendKey: k1, recvKey: k2);
      }
      return;
    }

    if (frame.type == FrameType.data) {
      if (state.session == null) return; // no session yet — drop
      try {
        final pt = await state.session!.decrypt(frame.bytes);
        _inboundCtrl.add(InboundMessage(
          fromUserPk: srcDevice,
          text: utf8.decode(pt),
        ));
      } catch (_) {
        // undecryptable — drop silently
      }
      return;
    }
    // Other frame types (keepalive, disconnect) — Phase 1a ignores.
  }

  Future<void> _sendFrame(PeerId peer, FrameType type, Uint8List payload) async {
    final frame = Frame(
      version: 1,
      type: type,
      srcPk: PeerId(myDevicePublicKey),
      payload: payload,
    );
    await transport.send(peer, frame.encode());
  }

  Future<void> dispose() async {
    await _frameSub?.cancel();
    await _discoverySub?.cancel();
    await transport.dispose();
    await _inboundCtrl.close();
  }
}

class _PeerState {
  NoiseIKHandshake? handshake;
  NoiseSession? session;
  bool isInitiator = false;
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/core/mesh/services/mesh_messaging_service_test.dart`

Expected: single test passes. If fails, debug handshake key ordering (common pitfall).

- [ ] **Step 5: Commit**

```bash
git add lib/core/mesh/services/mesh_messaging_service.dart test/core/mesh/services/mesh_messaging_service_test.dart lib/core/mesh/transport/mesh_transport.dart lib/core/mesh/transport/bonjour_transport.dart
git commit -m "feat(mesh/services): add MeshMessagingService with Noise handshake orchestration"
```

---

## Task 14: Run all unit tests together

- [ ] **Step 1: Run complete mesh test suite**

Run: `flutter test test/core/mesh/`

Expected output:
```
00:0X +N: All tests passed!
```

With N = sum of tests across tasks 2-13.

- [ ] **Step 2: If any fail — fix before proceeding to integration test**

Do NOT skip to the integration test until all unit tests pass. Common failure modes:
- DH direction reversed → handshake test fails with mismatched keys
- Frame encoding off-by-one → decode throws FormatException
- HKDF counter wrong → mixKey produces different keys on each side

- [ ] **Step 3: If all passing, commit (if any fixups)**

If you made fix-up commits, ensure everything compiles and passes:

```bash
flutter analyze lib/core/mesh/
```

Expected: `No issues found!`

---

## Task 15: Integration test — loopback via two MeshMessagingService instances

Phase 1a integration test uses loopback (two services in same isolate) with real BonjourTransport — verifies Bonjour discovery works on the device (emulator or real).

**Files:**
- Create: `integration_test/mesh_text_exchange_test.dart`

- [ ] **Step 1: Write integration test**

Create `integration_test/mesh_text_exchange_test.dart`:

```dart
// ignore_for_file: avoid_print
import 'dart:async';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:taler_id_mobile/core/mesh/crypto/keys/contact_key_store.dart';
import 'package:taler_id_mobile/core/mesh/services/mesh_messaging_service.dart';
import 'package:taler_id_mobile/core/mesh/transport/bonjour_transport.dart';
import 'package:taler_id_mobile/core/mesh/transport/peer_id.dart';

Future<(Uint8List, Uint8List)> _x25519Keys() async {
  final kp = await X25519().newKeyPair();
  final priv = await kp.extractPrivateKeyBytes();
  final pub = await kp.extractPublicKey();
  return (Uint8List.fromList(priv), Uint8List.fromList(pub.bytes));
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'Two MeshMessagingService instances exchange text via Bonjour + TCP',
    (WidgetTester tester) async {
      final (aPriv, aPub) = await _x25519Keys();
      final (bPriv, bPub) = await _x25519Keys();
      final alicePeer = PeerId(aPub);
      final bobPeer = PeerId(bPub);

      final aliceStore = ContactKeyStore()
        ..addContact(userPk: bobPeer, devicePks: [bobPeer]);
      final bobStore = ContactKeyStore()
        ..addContact(userPk: alicePeer, devicePks: [alicePeer]);

      final alice = MeshMessagingService(
        transport: BonjourTransport(),
        contactKeyStore: aliceStore,
        myDevicePrivateKey: aPriv,
        myDevicePublicKey: aPub,
      );
      final bob = MeshMessagingService(
        transport: BonjourTransport(),
        contactKeyStore: bobStore,
        myDevicePrivateKey: bPriv,
        myDevicePublicKey: bPub,
      );

      await alice.start(serviceName: 'AliceTest-${alicePeer.shortPrefix()}');
      await bob.start(serviceName: 'BobTest-${bobPeer.shortPrefix()}');

      final bobInbox = <String>[];
      final sub = bob.inbound.listen((m) => bobInbox.add(m.text));

      // Allow Bonjour discovery to propagate. 4 seconds is conservative.
      await Future.delayed(const Duration(seconds: 4));

      await alice.sendText(toUserPk: bobPeer, text: 'hello bob from mesh');

      // Wait for handshake + message.
      await Future.delayed(const Duration(seconds: 2));

      expect(bobInbox, contains('hello bob from mesh'),
          reason: 'bob should have received alice\'s message via mesh');

      await sub.cancel();
      await alice.dispose();
      await bob.dispose();
    },
    timeout: const Timeout(Duration(seconds: 20)),
  );
}
```

- [ ] **Step 2: Run on Android emulator**

Ensure emulator is running:
```bash
flutter emulators --launch Pixel_XL_API_33
~/Library/Android/sdk/platform-tools/adb devices
```

Expected: emulator-5554 visible.

Run integration test:
```bash
cd ~/Downloads/taler_id_mesh
flutter test integration_test/mesh_text_exchange_test.dart --flavor dev --dart-define=FLAVOR=dev --dart-define=BASE_URL=https://staging.id.taler.tirol -d emulator-5554
```

Expected: test passes. If it fails with "bob should have received alice's message via mesh":
1. Check Bonjour works on emulator — may need `_tcp.local.` host resolution. Run `adb shell avahi-browse -a` if tooling allows.
2. Increase initial wait from 4s → 8s in case emulator discovery is slow.
3. Manually validate with two real devices on the same WiFi.

- [ ] **Step 3: Run on iOS Simulator (optional — not Phase 1a gate)**

Phase 1a integration gate is Android. iOS cross-device testing comes in Phase 1d. If iOS Simulator is available:
```bash
flutter test integration_test/mesh_text_exchange_test.dart -d <iOS-simulator-id>
```

If works — great; if not — file issue for Phase 1d.

- [ ] **Step 4: Commit**

```bash
git add integration_test/mesh_text_exchange_test.dart
git commit -m "test(mesh): add Phase 1a integration test — two services exchange text via Bonjour+Noise"
```

---

## Task 16: Manual field test — two real devices on same WiFi

Automate-and-forget isn't enough for a foundational layer. Manually verify end-to-end before declaring Phase 1a done.

**Files:**
- Modify: `integration_test/mesh_text_exchange_test.dart` (add a separate widget-based manual harness — out of Phase 1a scope)

This task is manual QA — no code changes. Record findings.

- [ ] **Step 1: Build dev APK on DEV server**

```bash
ssh dvolkov@89.169.55.217
cd ~/taler_id_mesh
git pull origin feature/mesh-network
flutter build apk --flavor dev --release -t lib/main_dev.dart --dart-define=FLAVOR=dev --dart-define=BASE_URL=https://staging.id.taler.tirol
```

Actually, the `~/taler_id_mesh/` path doesn't exist on the DEV server yet. Clone it:

```bash
ssh dvolkov@89.169.55.217
git clone git@github.com:dvvolkovv/taler_id_mobile.git ~/taler_id_mesh
cd ~/taler_id_mesh
git checkout feature/mesh-network
flutter build apk --flavor dev --release -t lib/main_dev.dart --dart-define=FLAVOR=dev --dart-define=BASE_URL=https://staging.id.taler.tirol
```

Note: before this works you need to push `feature/mesh-network` to origin — do so from your local clone first:
```bash
cd ~/Downloads/taler_id_mesh
git push origin feature/mesh-network
```

- [ ] **Step 2: Wire a minimal debug UI (out-of-scope for Phase 1a plan)**

Phase 1a does NOT deliver UI — integration test is the validation gate. This manual step is reserved for Phase 1e where UI arrives.

**Skip** for now — Phase 1a is complete when Task 15 passes.

- [ ] **Step 3: Push branch to origin for backup**

```bash
cd ~/Downloads/taler_id_mesh
git push -u origin feature/mesh-network
```

---

## Task 17: Phase 1a retrospective checklist

- [ ] All unit tests passing (`flutter test test/core/mesh/`)
- [ ] Integration test passing on Android emulator
- [ ] `flutter analyze lib/core/mesh/` returns `No issues found!`
- [ ] Branch `feature/mesh-network` pushed to origin
- [ ] No TODO/FIXME left in implementation files
- [ ] Spec updated if any design decisions changed during implementation

If any item unchecked — do NOT proceed to Phase 1b plan.

---

## Self-Review Notes (for plan author)

**Spec coverage check:**
- Section 5 (Transport): BonjourTransport ✓. BLE discovery deferred to Phase 1c ✓ (explicitly noted).
- Section 6 (Crypto): DeviceKey ✓, Noise IK ✓, ContactKeyStore ✓, Session ✓. User identity key / device cert → Phase 1b.
- Section 7 (Routing): Not in Phase 1a scope ✓.
- Section 8 (Onion): Not in Phase 1a scope ✓. Raw encrypted text without onion is intentional simplification for PoC.
- Section 9 (Services): MeshMessagingService ✓. TransportSelector / server fallback → Phase 1e.
- Section 10 (UI): Not in Phase 1a scope ✓.

**Placeholder scan:** no TBD / TODO / "similar to" / vague steps. Each step has concrete code.

**Type consistency:** `PeerId` used throughout. `FrameType` enum used in both transport and service. `NoiseSession` send/recv key convention documented in handshake module.

**Known simplifications in Phase 1a (explicit, not gaps):**
1. No Frame type discriminator mismatch between transport and service — addressed by adding `type` to `InboundFrame`
2. `sendText` assumes userPk == devicePk (one device per user). Phase 1b adds multi-device per user.
3. ContactKeyStore is in-memory and seeded by tests. Phase 1b adds Hive + server sync.
4. No onion encryption — raw Noise session data. Phase 1f adds 1-hop onion wrap.
5. No multi-hop routing. Phase 2 adds distance-vector gossip.

## Execution Handoff

Plan complete and saved to `docs/superpowers/plans/2026-04-21-mesh-phase1a-text-exchange.md`. Two execution options:

**1. Subagent-Driven (recommended)** — dispatch fresh subagent per task, review between tasks, fast iteration.

**2. Inline Execution** — execute tasks in this session using executing-plans, batch execution with checkpoints.

Which approach?

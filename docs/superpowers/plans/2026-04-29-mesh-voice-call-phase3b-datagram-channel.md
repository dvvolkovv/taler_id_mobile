# Mesh Voice Phase 3b — Datagram Channel + Cipher Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a low-latency datagram channel to `MeshTransport` (Bonjour UDP, MultiTransport routing) plus an AEAD cipher (`MeshDatagramCipher`) that reuses Noise IK transport keys to encrypt/decrypt per-frame voice payloads. After this phase ships, `voice_self_test_screen` can be extended to send/receive encrypted opus packets between two devices over WiFi LAN.

**Architecture:** The existing `MeshTransport` interface gains `sendDatagram(peer, bytes)` and `Stream<InboundDatagram> get inboundDatagrams`. `BonjourTransport` adds a parallel `RawDatagramSocket` advertising its UDP port via Bonjour TXT records (`udp_port=<n>`); `MultiTransport` routes datagrams to the first child whose peer is currently discovered. `MeshDatagramCipher` derives a per-direction subkey via HKDF from the existing Noise transport keys and uses ChaCha20-Poly1305 AEAD with `[direction || zero(3) || seq(8)]` nonces and a 64-frame replay window. **BLE datagram is out of scope** for 3b — deferred to Phase 3b.2 (hardware-test heavy, not blocking the LAN primary path).

**Tech Stack:** Dart 3.6+, `dart:io.RawDatagramSocket`, `dart:typed_data`, `package:cryptography` for ChaCha20-Poly1305 + HKDF (already in deps for Noise IK), `bonsoir` (existing Bonjour wrapper).

**Spec:** `docs/superpowers/specs/2026-04-29-mesh-voice-call-phase3-design.md` (sections "Datagram channel inside MeshTransport" and "Encryption (MeshDatagramCipher)").

**Branch:** `feature/mesh-voice-call-phase3b` from `dev` (Phase 3a now merged).

**File map:**

| File | Role | New / Modified |
|---|---|---|
| `lib/core/mesh/transport/mesh_transport.dart` | Add `InboundDatagram` class + `sendDatagram` / `inboundDatagrams` to abstract interface | Modified |
| `lib/core/mesh/transport/bonjour_transport.dart` | Bind parallel UDP socket on startAdvertising, advertise port via TXT, cache peer UDP endpoints on discovery, implement send/receive | Modified |
| `lib/core/mesh/transport/multi_transport.dart` | `sendDatagram` routes to first child where `_knownBy[peer]` contains it; `inboundDatagrams` merges children's streams | Modified |
| `lib/core/mesh/transport/ble_transport.dart` | Stub-only: throw `UnimplementedError` from `sendDatagram` and emit empty `inboundDatagrams` stream — full BLE impl is Phase 3b.2 | Modified |
| `lib/core/mesh/crypto/mesh_datagram_cipher.dart` | New AEAD wrapper: derive subkeys via HKDF from Noise transport keys, encrypt/decrypt with ChaCha20-Poly1305, sliding replay window | New |
| `test/core/mesh/transport/bonjour_transport_datagram_test.dart` | Two local `BonjourTransport` instances exchanging datagrams over loopback UDP | New |
| `test/core/mesh/transport/multi_transport_datagram_test.dart` | Routing test with two `_FakeTransport` children | New |
| `test/core/mesh/crypto/mesh_datagram_cipher_test.dart` | Roundtrip + replay window unit tests | New |

---

## Task 1: Extend `MeshTransport` interface with datagram methods (TDD)

**Files:**
- Modify: `lib/core/mesh/transport/mesh_transport.dart`
- Modify: `lib/core/mesh/transport/bonjour_transport.dart` (stub override that throws — real impl in Tasks 3-4)
- Modify: `lib/core/mesh/transport/ble_transport.dart` (stub that throws + empty stream)
- Modify: `lib/core/mesh/transport/multi_transport.dart` (stub override; real routing in Task 5)
- Modify: `test/core/mesh/transport/multi_transport_test.dart` (existing tests, ensure compile after interface change)

- [ ] **Step 1: Define `InboundDatagram` and extend the abstract interface**

Open `lib/core/mesh/transport/mesh_transport.dart`. After the existing `InboundFrame` class (around line 35), add:

```dart
/// Event emitted when a datagram (unreliable, low-latency) arrives from a peer.
/// Used for voice / file streaming. Decryption + replay-window check is the
/// caller's responsibility (see `MeshDatagramCipher`).
class InboundDatagram {
  final PeerId srcPeer;
  final Uint8List bytes;
  final TransportId via;
  InboundDatagram({required this.srcPeer, required this.bytes, required this.via});
}
```

Add the `TransportId` import if missing:

```dart
import 'transport_preference.dart';
```

Inside the `abstract class MeshTransport`, add two new abstract members after `Future<void> send(...)`:

```dart
  /// Datagram channel — unreliable, low-latency. Used for voice frames.
  /// Frames are NOT encrypted at this layer; callers should wrap payloads
  /// with `MeshDatagramCipher`. Throws [TransportUnavailable] if no
  /// datagram path to [peer] exists right now.
  Stream<InboundDatagram> get inboundDatagrams;
  Future<void> sendDatagram(PeerId peer, Uint8List data);
```

Add a small exception type at the bottom of the file:

```dart
/// Thrown by `sendDatagram` when the requested peer has no reachable
/// datagram path on any active transport (e.g., peer is BLE-only and the
/// datagram-supporting transports haven't discovered them).
class TransportUnavailable implements Exception {
  final String message;
  TransportUnavailable(this.message);
  @override
  String toString() => 'TransportUnavailable: $message';
}
```

- [ ] **Step 2: Add throwing stubs to `BonjourTransport`, `BleTransport`, `MultiTransport`**

These are placeholders so the project compiles after the interface change. Real implementations land in Tasks 3-5.

In `lib/core/mesh/transport/bonjour_transport.dart`, inside the class, add:

```dart
  @override
  Stream<InboundDatagram> get inboundDatagrams => const Stream.empty();

  @override
  Future<void> sendDatagram(PeerId peer, Uint8List data) async {
    throw TransportUnavailable('Bonjour datagram not yet implemented');
  }
```

In `lib/core/mesh/transport/ble_transport.dart`, inside the class, add:

```dart
  @override
  Stream<InboundDatagram> get inboundDatagrams => const Stream.empty();

  @override
  Future<void> sendDatagram(PeerId peer, Uint8List data) async {
    throw TransportUnavailable('BLE datagram not yet implemented (Phase 3b.2)');
  }
```

In `lib/core/mesh/transport/multi_transport.dart`, inside the class, add:

```dart
  @override
  Stream<InboundDatagram> get inboundDatagrams =>
      StreamGroup.merge(_children.values.map((c) => c.inboundDatagrams));

  @override
  Future<void> sendDatagram(PeerId peer, Uint8List data) async {
    throw TransportUnavailable('MultiTransport.sendDatagram not yet routed');
  }
```

Add `import 'package:async/async.dart' show StreamGroup;` to multi_transport.dart if not already present (the package is in the existing dep tree).

- [ ] **Step 3: Compile-check**

Run: `cd /Users/dmitry/Downloads/taler_id_mobile && dart analyze lib/core/mesh/transport/ 2>&1 | tail -10`
Expected: no errors. Pre-existing info-level lints OK.

- [ ] **Step 4: Run mesh transport unit tests for regressions**

Run: `cd /Users/dmitry/Downloads/taler_id_mobile && flutter test test/core/mesh/transport/ 2>&1 | tail -3`
Expected: all existing tests pass. The interface change is backwards-compatible (stubs cover all existing implementations).

- [ ] **Step 5: Commit**

```bash
cd /Users/dmitry/Downloads/taler_id_mobile && git add lib/core/mesh/transport/mesh_transport.dart lib/core/mesh/transport/bonjour_transport.dart lib/core/mesh/transport/ble_transport.dart lib/core/mesh/transport/multi_transport.dart && git commit -m "feat(mesh-transport): extend interface with datagram channel (stubs)"
```

Don't use `--no-verify`.

---

## Task 2: `MeshDatagramCipher` (TDD)

**Files:**
- Create: `lib/core/mesh/crypto/mesh_datagram_cipher.dart`
- Create: `test/core/mesh/crypto/mesh_datagram_cipher_test.dart`

Pure Dart, no platform dependency. Tested on host VM via `flutter test`.

- [ ] **Step 1: Write the failing tests**

Create `test/core/mesh/crypto/mesh_datagram_cipher_test.dart`:

```dart
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:taler_id_mobile/core/mesh/crypto/mesh_datagram_cipher.dart';

void main() {
  group('MeshDatagramCipher', () {
    // 32-byte transport secret (in production this comes from the Noise IK
    // handshake's split() output).
    final transportSecret =
        Uint8List.fromList(List<int>.generate(32, (i) => i + 1));

    test('encrypt → decrypt round-trip recovers plaintext', () async {
      final outboundCipher = await MeshDatagramCipher.derive(
        transportSecret: transportSecret,
        direction: CipherDirection.aToB,
      );
      final inboundCipher = await MeshDatagramCipher.derive(
        transportSecret: transportSecret,
        direction: CipherDirection.aToB,
      );

      final pt = Uint8List.fromList(List<int>.generate(80, (i) => i));
      final ct = await outboundCipher.encrypt(seq: 1, plaintext: pt);
      expect(ct.length, greaterThan(pt.length),
          reason: 'ciphertext must include 16-byte auth tag');

      final dec = await inboundCipher.decrypt(seq: 1, ciphertext: ct);
      expect(dec, pt);
    });

    test('decryption with wrong direction fails', () async {
      final aOut = await MeshDatagramCipher.derive(
        transportSecret: transportSecret,
        direction: CipherDirection.aToB,
      );
      final bOut = await MeshDatagramCipher.derive(
        transportSecret: transportSecret,
        direction: CipherDirection.bToA,
      );

      final pt = Uint8List.fromList([1, 2, 3, 4]);
      final ct = await aOut.encrypt(seq: 1, plaintext: pt);

      await expectLater(
        bOut.decrypt(seq: 1, ciphertext: ct),
        throwsA(isA<Exception>()),
      );
    });

    test('replay window drops out-of-window seq', () async {
      final inbound = await MeshDatagramCipher.derive(
        transportSecret: transportSecret,
        direction: CipherDirection.aToB,
      );
      final outbound = await MeshDatagramCipher.derive(
        transportSecret: transportSecret,
        direction: CipherDirection.aToB,
      );

      final pt = Uint8List.fromList([42]);
      // Receive seq 100 first.
      final ct100 = await outbound.encrypt(seq: 100, plaintext: pt);
      await inbound.decrypt(seq: 100, ciphertext: ct100);

      // Then a frame with seq 30 — older than (max_seen − 64) = 36, must drop.
      final ct30 = await outbound.encrypt(seq: 30, plaintext: pt);
      await expectLater(
        inbound.decrypt(seq: 30, ciphertext: ct30),
        throwsA(isA<Exception>()),
      );

      // Frame with seq 99 (within window: 100 - 64 = 36 ≤ 99 ≤ 100) — accept.
      final ct99 = await outbound.encrypt(seq: 99, plaintext: pt);
      final out = await inbound.decrypt(seq: 99, ciphertext: ct99);
      expect(out, pt);

      // Re-decrypting the same seq 99 — must drop (replay).
      await expectLater(
        inbound.decrypt(seq: 99, ciphertext: ct99),
        throwsA(isA<Exception>()),
      );
    });
  });
}
```

- [ ] **Step 2: Run test, expect FAIL**

Run: `cd /Users/dmitry/Downloads/taler_id_mobile && flutter test test/core/mesh/crypto/mesh_datagram_cipher_test.dart 2>&1 | tail -8`
Expected: compilation error — `MeshDatagramCipher` not defined.

- [ ] **Step 3: Implement `MeshDatagramCipher`**

Create `lib/core/mesh/crypto/mesh_datagram_cipher.dart`:

```dart
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

/// Direction tag for sub-key derivation. Each peer pair has two derived
/// keys: one for caller→callee traffic and one for callee→caller. This
/// prevents nonce reuse across the two directions over a shared transport
/// key (mandatory for AEAD security).
enum CipherDirection {
  aToB,
  bToA,
}

/// AEAD cipher for mesh-voice datagram payloads. Reuses the 32-byte
/// Noise IK transport secret (from the handshake's `split()`) to derive
/// a per-direction ChaCha20-Poly1305 key via HKDF. Each frame uses a
/// 12-byte nonce constructed as `direction (1) || zero (3) || seq (8 BE)`.
///
/// Replay protection: receivers track the maximum seq seen and drop any
/// frame whose seq is below `max_seen − 64`. Within the window, the same
/// seq cannot be accepted twice.
///
/// See `docs/superpowers/specs/2026-04-29-mesh-voice-call-phase3-design.md`
/// section "Encryption (MeshDatagramCipher)".
class MeshDatagramCipher {
  static const int _replayWindowSize = 64;

  final SecretKey _key;
  final CipherDirection _direction;

  // Replay-window state — only meaningful when this cipher is used to
  // decrypt inbound frames. Outbound encryption ignores it.
  int _maxSeqSeen = -1;
  final Set<int> _seenInWindow = <int>{};

  MeshDatagramCipher._(this._key, this._direction);

  /// Derive a cipher for [direction] from a 32-byte Noise transport secret.
  static Future<MeshDatagramCipher> derive({
    required Uint8List transportSecret,
    required CipherDirection direction,
  }) async {
    if (transportSecret.length != 32) {
      throw ArgumentError('transportSecret must be 32 bytes, got ${transportSecret.length}');
    }
    final hkdf = Hkdf(hmac: Hmac.sha256(), outputLength: 32);
    final info = direction == CipherDirection.aToB
        ? const [0x6d, 0x65, 0x73, 0x68, 0x44, 0x47, 0x2d, 0x61, 0x32, 0x62] // 'meshDG-a2b'
        : const [0x6d, 0x65, 0x73, 0x68, 0x44, 0x47, 0x2d, 0x62, 0x32, 0x61]; // 'meshDG-b2a'
    final derivedKey = await hkdf.deriveKey(
      secretKey: SecretKey(transportSecret),
      info: info,
    );
    return MeshDatagramCipher._(derivedKey, direction);
  }

  /// Encrypt [plaintext] with the given sequence number. Returns ciphertext+tag.
  Future<Uint8List> encrypt({required int seq, required Uint8List plaintext}) async {
    final algorithm = Chacha20.poly1305Aead();
    final nonce = _buildNonce(seq);
    final secretBox = await algorithm.encrypt(
      plaintext,
      secretKey: _key,
      nonce: nonce,
    );
    final out = Uint8List(secretBox.cipherText.length + secretBox.mac.bytes.length);
    out.setAll(0, secretBox.cipherText);
    out.setAll(secretBox.cipherText.length, secretBox.mac.bytes);
    return out;
  }

  /// Decrypt [ciphertext] (ciphertext+tag concatenated). Throws if AEAD
  /// authentication fails OR if [seq] is outside the replay window.
  Future<Uint8List> decrypt({required int seq, required Uint8List ciphertext}) async {
    if (ciphertext.length < 16) {
      throw FormatException('ciphertext too short (need at least 16 bytes for tag)');
    }
    if (!_replayCheck(seq)) {
      throw StateError('replay-window violation: seq=$seq max=$_maxSeqSeen');
    }
    final algorithm = Chacha20.poly1305Aead();
    final ctOnly = ciphertext.sublist(0, ciphertext.length - 16);
    final mac = Mac(ciphertext.sublist(ciphertext.length - 16));
    final nonce = _buildNonce(seq);
    final secretBox = SecretBox(ctOnly, nonce: nonce, mac: mac);
    final pt = await algorithm.decrypt(secretBox, secretKey: _key);
    _replayAccept(seq);
    return Uint8List.fromList(pt);
  }

  List<int> _buildNonce(int seq) {
    final n = Uint8List(12);
    n[0] = _direction == CipherDirection.aToB ? 0x00 : 0x01;
    // bytes 1..3 = zero (already zero-initialised)
    // bytes 4..11 = seq big-endian
    final view = ByteData.view(n.buffer);
    view.setUint64(4, seq, Endian.big);
    return n;
  }

  bool _replayCheck(int seq) {
    if (_maxSeqSeen < 0) return true; // first frame ever
    if (seq <= _maxSeqSeen - _replayWindowSize) return false; // outside window
    if (_seenInWindow.contains(seq)) return false; // already accepted
    return true;
  }

  void _replayAccept(int seq) {
    if (seq > _maxSeqSeen) {
      _maxSeqSeen = seq;
      // Prune entries that have fallen out of the new window.
      _seenInWindow.removeWhere((s) => s <= _maxSeqSeen - _replayWindowSize);
    }
    _seenInWindow.add(seq);
  }
}
```

- [ ] **Step 4: Run test, expect PASS**

Run: `cd /Users/dmitry/Downloads/taler_id_mobile && flutter test test/core/mesh/crypto/mesh_datagram_cipher_test.dart 2>&1 | tail -5`
Expected: 3 tests passed.

- [ ] **Step 5: Commit**

```bash
cd /Users/dmitry/Downloads/taler_id_mobile && git add lib/core/mesh/crypto/mesh_datagram_cipher.dart test/core/mesh/crypto/mesh_datagram_cipher_test.dart && git commit -m "feat(mesh-crypto): MeshDatagramCipher (HKDF subkey + ChaCha20-Poly1305 + 64-frame replay window)"
```

---

## Task 3: `BonjourTransport` UDP socket bind + TXT advertise (TDD-light)

**Files:**
- Modify: `lib/core/mesh/transport/bonjour_transport.dart`
- Test indirectly through Task 6's integration test.

This task changes existing transport behaviour but the only test-friendly verification is end-to-end (Task 6). Keep changes small and focused.

- [ ] **Step 1: Add UDP socket field + endpoint cache**

Open `lib/core/mesh/transport/bonjour_transport.dart`. Find the existing fields block at the top of `BonjourTransport` (search for `ServerSocket? _server;`). Add:

```dart
  RawDatagramSocket? _udpSocket;
  final Map<PeerId, ({String host, int port})> _peerUdpEndpoints = {};
  final _datagramCtrl = StreamController<InboundDatagram>.broadcast();
```

Add the `import 'dart:io' show RawDatagramSocket, RawSocketEvent, InternetAddress;` if not already covered (existing import of `dart:io` should suffice — verify).

- [ ] **Step 2: Bind the parallel UDP socket in `startAdvertising`**

Find the line `_server = await ServerSocket.bind(InternetAddress.anyIPv4, 0);` (around line 88). After the existing TCP bind + `_server!.listen(...)` line, add:

```dart
    _udpSocket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
    debugPrint('[mesh-bonjour] UDP socket listening on port ${_udpSocket!.port}');
    _udpSocket!.listen(_handleDatagramEvent);
```

- [ ] **Step 3: Advertise the UDP port via TXT record**

Find the `BonsoirService` construction (around line 92). Update the `attributes` map:

```dart
      attributes: {
        'pk': self.devicePk.toHex(),
        'ver': '1',
        'udp_port': _udpSocket!.port.toString(),
      },
```

- [ ] **Step 4: Cache peer UDP endpoint on resolved discovery**

Find where `PeerDiscovered` events are emitted after successful TXT parsing (around line 200, just before the `_discoveryCtrl.add(PeerDiscovered(...))` line). The exact location is at the resolved-service handler — search for `final pkHex = service.attributes['pk'];` to anchor.

Just before emitting `PeerDiscovered`, add:

```dart
    final udpPortStr = service.attributes['udp_port'];
    final udpPort = udpPortStr != null ? int.tryParse(udpPortStr) : null;
    if (udpPort != null && service.host != null) {
      _peerUdpEndpoints[PeerId.fromHex(pkHex)] = (host: service.host!, port: udpPort);
    }
```

(`pkHex` and `service` are already in scope in this branch — verify by reading the surrounding code.)

- [ ] **Step 5: Replace the throwing stub with real `sendDatagram`**

Find the `sendDatagram` stub from Task 1 in `bonjour_transport.dart`. Replace it with:

```dart
  @override
  Future<void> sendDatagram(PeerId peer, Uint8List data) async {
    final endpoint = _peerUdpEndpoints[peer];
    final socket = _udpSocket;
    if (endpoint == null || socket == null) {
      throw TransportUnavailable('Bonjour: no UDP endpoint for peer ${peer.toHex().substring(0, 12)}');
    }
    if (data.length > 1200) {
      throw ArgumentError('datagram too large: ${data.length} bytes (max 1200 to avoid IPv4 fragmentation)');
    }
    socket.send(data, InternetAddress(endpoint.host), endpoint.port);
  }

  @override
  Stream<InboundDatagram> get inboundDatagrams => _datagramCtrl.stream;

  void _handleDatagramEvent(RawSocketEvent event) {
    if (event != RawSocketEvent.read) return;
    final socket = _udpSocket;
    if (socket == null) return;
    final dg = socket.receive();
    if (dg == null) return;

    // Reverse-lookup: find which peer this came from by matching source
    // (host, port) against `_peerUdpEndpoints`. Slow O(N) but N = peer
    // count which is small (few-to-tens for 1-hop direct mesh).
    PeerId? srcPeer;
    for (final entry in _peerUdpEndpoints.entries) {
      if (entry.value.host == dg.address.address && entry.value.port == dg.port) {
        srcPeer = entry.key;
        break;
      }
    }
    if (srcPeer == null) {
      // Datagram from an unknown source — ignore. Could be a peer that
      // hasn't completed Bonjour discovery yet, or just stray UDP.
      return;
    }
    _datagramCtrl.add(InboundDatagram(
      srcPeer: srcPeer,
      bytes: Uint8List.fromList(dg.data),
      via: TransportId.bonjour,
    ));
  }
```

Remove the existing stub `Stream<InboundDatagram> get inboundDatagrams => const Stream.empty();` from Task 1 — replaced by the proper getter above.

- [ ] **Step 6: Clean up in `stopAdvertising` / `dispose`**

Find `stopAdvertising` and any `dispose`. After the existing `_server?.close()` call, add UDP socket close:

```dart
    _udpSocket?.close();
    _udpSocket = null;
    _peerUdpEndpoints.clear();
```

If `_datagramCtrl` should close on disposal (not on `stopAdvertising` since the controller is broadcast and may be re-listened), add `_datagramCtrl.close()` only in the actual `dispose()` method. If there is no `dispose()` method, leave the controller alive — broadcast streams tolerate process-end cleanup.

- [ ] **Step 7: Compile-check**

Run: `cd /Users/dmitry/Downloads/taler_id_mobile && dart analyze lib/core/mesh/transport/bonjour_transport.dart 2>&1 | tail -5`
Expected: no errors.

- [ ] **Step 8: Run existing bonjour tests for regression**

Run: `cd /Users/dmitry/Downloads/taler_id_mobile && flutter test test/core/mesh/transport/ 2>&1 | tail -3`
Expected: all existing tests pass. The TXT extra key + UDP socket should not break legacy paths.

- [ ] **Step 9: Commit**

```bash
cd /Users/dmitry/Downloads/taler_id_mobile && git add lib/core/mesh/transport/bonjour_transport.dart && git commit -m "feat(mesh-bonjour): UDP datagram socket + TXT-advertised port + peer endpoint cache"
```

---

## Task 4: `MultiTransport.sendDatagram` routing (TDD)

**Files:**
- Modify: `lib/core/mesh/transport/multi_transport.dart`
- Create: `test/core/mesh/transport/multi_transport_datagram_test.dart`

- [ ] **Step 1: Write the failing test**

Create `test/core/mesh/transport/multi_transport_datagram_test.dart`:

```dart
import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:taler_id_mobile/core/mesh/transport/mesh_transport.dart';
import 'package:taler_id_mobile/core/mesh/transport/multi_transport.dart';
import 'package:taler_id_mobile/core/mesh/transport/peer_id.dart';
import 'package:taler_id_mobile/core/mesh/transport/transport_preference.dart';

class _FakeChild implements MeshTransport {
  final TransportId id;
  final _discCtrl = StreamController<PeerDiscovered>.broadcast();
  final _lossCtrl = StreamController<PeerLost>.broadcast();
  final _inboundCtrl = StreamController<InboundFrame>.broadcast();
  final _datagramCtrl = StreamController<InboundDatagram>.broadcast();
  final sentDatagrams = <(PeerId, Uint8List)>[];
  bool throwOnSend = false;

  _FakeChild(this.id);

  @override Stream<PeerDiscovered> get discoveries => _discCtrl.stream;
  @override Stream<PeerLost> get losses => _lossCtrl.stream;
  @override Stream<InboundFrame> get inbound => _inboundCtrl.stream;
  @override Stream<InboundDatagram> get inboundDatagrams => _datagramCtrl.stream;

  @override Future<void> startAdvertising(DeviceInfo self) async {}
  @override Future<void> stopAdvertising() async {}
  @override Future<void> connectTo(PeerId peer) async {}
  @override Future<void> send(PeerId peer, Uint8List data) async {}
  @override Future<void> dispose() async {}

  @override
  Future<void> sendDatagram(PeerId peer, Uint8List data) async {
    if (throwOnSend) throw TransportUnavailable('fake throw');
    sentDatagrams.add((peer, data));
  }

  void emitDiscover(PeerId peer) =>
      _discCtrl.add(PeerDiscovered(peerId: peer, host: '127.0.0.1', port: 0));
  void emitDatagram(InboundDatagram dg) => _datagramCtrl.add(dg);
}

void main() {
  group('MultiTransport datagram', () {
    test('routes sendDatagram to first child where peer is discovered', () async {
      final bonjour = _FakeChild(TransportId.bonjour);
      final ble = _FakeChild(TransportId.ble);
      final multi = MultiTransport(children: {
        TransportId.bonjour: bonjour,
        TransportId.ble: ble,
      });
      final peer = PeerId(Uint8List.fromList(List<int>.generate(32, (i) => i)));

      // Peer only discovered on Bonjour.
      bonjour.emitDiscover(peer);
      await Future<void>.delayed(Duration.zero);

      await multi.sendDatagram(peer, Uint8List.fromList([1, 2, 3]));
      expect(bonjour.sentDatagrams, hasLength(1));
      expect(ble.sentDatagrams, isEmpty);
    });

    test('prefers Bonjour over BLE when peer is on both', () async {
      final bonjour = _FakeChild(TransportId.bonjour);
      final ble = _FakeChild(TransportId.ble);
      final multi = MultiTransport(children: {
        TransportId.bonjour: bonjour,
        TransportId.ble: ble,
      });
      final peer = PeerId(Uint8List.fromList(List<int>.generate(32, (i) => i)));

      bonjour.emitDiscover(peer);
      ble.emitDiscover(peer);
      await Future<void>.delayed(Duration.zero);

      await multi.sendDatagram(peer, Uint8List.fromList([7, 8]));
      expect(bonjour.sentDatagrams, hasLength(1));
      expect(ble.sentDatagrams, isEmpty);
    });

    test('throws TransportUnavailable when peer is on no transport', () async {
      final bonjour = _FakeChild(TransportId.bonjour);
      final multi = MultiTransport(children: {
        TransportId.bonjour: bonjour,
      });
      final peer = PeerId(Uint8List.fromList(List<int>.generate(32, (i) => i)));
      // Peer never discovered.

      await expectLater(
        multi.sendDatagram(peer, Uint8List.fromList([1])),
        throwsA(isA<TransportUnavailable>()),
      );
    });

    test('inboundDatagrams forwards from all children', () async {
      final bonjour = _FakeChild(TransportId.bonjour);
      final ble = _FakeChild(TransportId.ble);
      final multi = MultiTransport(children: {
        TransportId.bonjour: bonjour,
        TransportId.ble: ble,
      });
      final peer = PeerId(Uint8List.fromList(List<int>.generate(32, (i) => i)));
      final received = <InboundDatagram>[];
      multi.inboundDatagrams.listen(received.add);

      bonjour.emitDatagram(InboundDatagram(
        srcPeer: peer, bytes: Uint8List.fromList([1]), via: TransportId.bonjour));
      ble.emitDatagram(InboundDatagram(
        srcPeer: peer, bytes: Uint8List.fromList([2]), via: TransportId.ble));
      await Future<void>.delayed(Duration.zero);

      expect(received, hasLength(2));
      expect(received[0].via, TransportId.bonjour);
      expect(received[1].via, TransportId.ble);
    });
  });
}
```

- [ ] **Step 2: Run test, expect FAIL**

Run: `cd /Users/dmitry/Downloads/taler_id_mobile && flutter test test/core/mesh/transport/multi_transport_datagram_test.dart 2>&1 | tail -8`
Expected: tests fail because `sendDatagram` still throws `TransportUnavailable('MultiTransport.sendDatagram not yet routed')`.

- [ ] **Step 3: Implement routing in `MultiTransport.sendDatagram`**

Open `lib/core/mesh/transport/multi_transport.dart`. Replace the Task 1 stub `sendDatagram` with:

```dart
  /// Datagram preference order — same as the existing reliable-send order.
  /// Bonjour preferred over BLE: higher bandwidth, lower latency.
  static const List<TransportId> _datagramPreference = [
    TransportId.bonjour,
    TransportId.ble,
  ];

  @override
  Future<void> sendDatagram(PeerId peer, Uint8List data) async {
    final knownOn = _knownBy[peer];
    if (knownOn == null || knownOn.isEmpty) {
      throw TransportUnavailable('MultiTransport: peer ${peer.toHex().substring(0, 12)} not on any child');
    }
    for (final id in _datagramPreference) {
      if (!knownOn.contains(id)) continue;
      final child = _children[id];
      if (child == null) continue;
      try {
        await child.sendDatagram(peer, data);
        return;
      } on TransportUnavailable {
        // Try the next transport in preference order.
        continue;
      }
    }
    throw TransportUnavailable(
        'MultiTransport: no datagram-capable transport for peer ${peer.toHex().substring(0, 12)} among ${knownOn.toList()}');
  }
```

The `inboundDatagrams` stream-merge from Task 1 is fine as-is — keep it.

- [ ] **Step 4: Run test, expect PASS**

Run: `cd /Users/dmitry/Downloads/taler_id_mobile && flutter test test/core/mesh/transport/multi_transport_datagram_test.dart 2>&1 | tail -8`
Expected: 4 tests passed.

- [ ] **Step 5: Run full mesh-transport suite for regression**

Run: `cd /Users/dmitry/Downloads/taler_id_mobile && flutter test test/core/mesh/transport/ 2>&1 | tail -3`
Expected: all tests pass.

- [ ] **Step 6: Commit**

```bash
cd /Users/dmitry/Downloads/taler_id_mobile && git add lib/core/mesh/transport/multi_transport.dart test/core/mesh/transport/multi_transport_datagram_test.dart && git commit -m "feat(mesh-transport): MultiTransport.sendDatagram routing (Bonjour-first)"
```

---

## Task 5: BonjourTransport datagram integration test (loopback UDP)

**Files:**
- Create: `test/core/mesh/transport/bonjour_transport_datagram_test.dart`

End-to-end test on the host VM: two `BonjourTransport` instances on the same machine. Bonsoir's mDNS discovery doesn't work in the host VM (no real network), so we wire the peer endpoints manually via reflection-style direct field access. The TXT-advertise + reverse-lookup paths are exercised at hardware smoke (Task 6).

This test only verifies: given a configured `_peerUdpEndpoints` cache, `sendDatagram` reaches the other instance's UDP socket and emits `inboundDatagrams` correctly.

- [ ] **Step 1: Write the test**

Create `test/core/mesh/transport/bonjour_transport_datagram_test.dart`:

```dart
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:taler_id_mobile/core/mesh/transport/bonjour_transport.dart';
import 'package:taler_id_mobile/core/mesh/transport/mesh_transport.dart';
import 'package:taler_id_mobile/core/mesh/transport/peer_id.dart';

void main() {
  test('two Bonjour transports exchange UDP datagrams over loopback', () async {
    // We don't actually rely on mDNS here — Bonsoir doesn't work on the host
    // VM. Instead we bind two RawDatagramSockets directly and feed them
    // into BonjourTransport via the exposed test hook (added in this task).
    // That exercises sendDatagram + inboundDatagrams + reverse lookup.

    final aliceSock = await RawDatagramSocket.bind(InternetAddress.loopbackIPv4, 0);
    final bobSock = await RawDatagramSocket.bind(InternetAddress.loopbackIPv4, 0);

    final alice = BonjourTransport.testHarness(udpSocket: aliceSock);
    final bob = BonjourTransport.testHarness(udpSocket: bobSock);

    final alicePk = PeerId(Uint8List.fromList(List<int>.generate(32, (i) => i)));
    final bobPk = PeerId(Uint8List.fromList(List<int>.generate(32, (i) => 100 + i)));

    // Wire endpoint caches manually (production code populates these from
    // bonsoir-resolved TXT records).
    alice.testRegisterPeer(bobPk, bobSock.address.address, bobSock.port);
    bob.testRegisterPeer(alicePk, aliceSock.address.address, aliceSock.port);

    final received = <InboundDatagram>[];
    final sub = bob.inboundDatagrams.listen(received.add);

    await alice.sendDatagram(bobPk, Uint8List.fromList([1, 2, 3, 4]));
    await Future<void>.delayed(const Duration(milliseconds: 100));

    expect(received, hasLength(1));
    expect(received.first.bytes, Uint8List.fromList([1, 2, 3, 4]));
    expect(received.first.srcPeer, alicePk);

    await sub.cancel();
    aliceSock.close();
    bobSock.close();
  });
}
```

- [ ] **Step 2: Add the test harness factory + helper to `BonjourTransport`**

Open `lib/core/mesh/transport/bonjour_transport.dart`. Add at the bottom of the class (above the closing `}`):

```dart
  /// Test-only constructor: builds a `BonjourTransport` with a pre-bound
  /// UDP socket and skips Bonsoir advertise/discovery. Use only from
  /// `test/` files. Pairs with `testRegisterPeer`.
  @visibleForTesting
  factory BonjourTransport.testHarness({required RawDatagramSocket udpSocket}) {
    final t = BonjourTransport();
    t._udpSocket = udpSocket;
    udpSocket.listen(t._handleDatagramEvent);
    return t;
  }

  /// Test-only: pre-populate the peer UDP endpoint cache. Use only from
  /// `test/` files. Production populates via `bonsoir`-resolved TXT.
  @visibleForTesting
  void testRegisterPeer(PeerId peer, String host, int port) {
    _peerUdpEndpoints[peer] = (host: host, port: port);
  }
```

Add `import 'package:flutter/foundation.dart' show visibleForTesting;` if missing.

- [ ] **Step 3: Run test, expect PASS**

Run: `cd /Users/dmitry/Downloads/taler_id_mobile && flutter test test/core/mesh/transport/bonjour_transport_datagram_test.dart 2>&1 | tail -5`
Expected: 1 test passed.

- [ ] **Step 4: Commit**

```bash
cd /Users/dmitry/Downloads/taler_id_mobile && git add lib/core/mesh/transport/bonjour_transport.dart test/core/mesh/transport/bonjour_transport_datagram_test.dart && git commit -m "test(mesh-bonjour): integration test for UDP datagram exchange (loopback)"
```

---

## Task 6: Hardware smoke + push + PR

**Files:** none modified.

This is the final validation. Two devices on the same WiFi exchange encrypted Opus packets through the new datagram channel.

Note: Phase 3b doesn't yet integrate with the audio engine — that's Phase 3c's `MeshVoiceService`. For 3b smoke, we add a small temporary debug button to the existing `MeshVoiceSelfTestScreen` that:
- On Alice tap, sends a test datagram (e.g., `[0xAA, 0xBB, 0xCC]`) to a hard-coded peer (the other discovered mesh device).
- On Bob's `inboundDatagrams` stream, prints received bytes to debug log.

This proves the pipe works end-to-end. The audio integration is Phase 3c.

- [ ] **Step 1: Add a "Send test datagram" debug button**

Edit `lib/features/mesh_debug/presentation/screens/mesh_voice_self_test_screen.dart`. Add a second button below the existing "Start loopback" that, when tapped, picks the first peer from `MeshTransport.discoveries` (or current peer list) and sends `Uint8List.fromList([0xAA, 0xBB, 0xCC, 0xDD])` via `transport.sendDatagram(peer, ...)`. Subscribe to `transport.inboundDatagrams` in `initState` and log every event with `debugPrint`.

The exact code shape mirrors the existing patterns in this file. Implementer should:
- Inject `sl<MeshTransport>()` into the State.
- Track most-recent peer in `_lastDiscoveredPeer` updated from `transport.discoveries.listen`.
- On button tap, if `_lastDiscoveredPeer != null`, call `transport.sendDatagram(_lastDiscoveredPeer!, Uint8List.fromList([0xAA, 0xBB, 0xCC, 0xDD]))`.
- On `inboundDatagrams.listen`, increment a counter shown on screen.

- [ ] **Step 2: Static analysis + full test suite**

Run: `cd /Users/dmitry/Downloads/taler_id_mobile && flutter analyze 2>&1 | tail -5`
Expected: no NEW errors.

Run: `cd /Users/dmitry/Downloads/taler_id_mobile && flutter test 2>&1 | tail -3`
Expected: `All tests passed!`

- [ ] **Step 3: Push branch**

```bash
cd /Users/dmitry/Downloads/taler_id_mobile && git push -u origin feature/mesh-voice-call-phase3b
```

- [ ] **Step 4: Hardware smoke (manual, two devices on same WiFi)**

Build dev APK locally + iOS dev locally (per the local-builds preference saved earlier).

```bash
cd /Users/dmitry/Downloads/taler_id_mobile && flutter run --release --flavor dev -t lib/main_dev.dart --dart-define=FLAVOR=dev --dart-define=BASE_URL=https://staging.id.taler.tirol -d 78c0742f
# in another terminal:
flutter run --release --flavor dev -t lib/main_dev.dart --dart-define=FLAVOR=dev --dart-define=BASE_URL=https://staging.id.taler.tirol -d 00008150-00060C5A21E9401C
```

Steps:
1. Both devices on the same WiFi, both running app.
2. Open Mesh Debug → ensure they discover each other (peer count goes to 1+ on each).
3. Open Voice self-test on **device A**. Tap the new "Send test datagram" button.
4. On **device B**, watch the inbound counter — must increment by 1.
5. Reverse roles: device B sends, device A receives.
6. Toggle WiFi off on either device — sends should fail with `TransportUnavailable` (visible in flutter run logs).

- [ ] **Step 5: Open the PR**

```bash
gh pr create --base dev --head feature/mesh-voice-call-phase3b --title "feat(mesh-voice/3b): datagram channel + AEAD cipher" --body "$(cat <<'EOF'
## Summary
- `MeshTransport` interface gains `sendDatagram` / `inboundDatagrams` plus `InboundDatagram` model and `TransportUnavailable` exception.
- `BonjourTransport` binds a parallel `RawDatagramSocket`, advertises the UDP port via Bonjour TXT (`udp_port=N`), caches resolved peer endpoints, and routes outbound/inbound datagrams.
- `MultiTransport.sendDatagram` picks the first child where the peer is currently discovered (Bonjour preferred over BLE; falls through on `TransportUnavailable`).
- New `MeshDatagramCipher` derives a per-direction sub-key via HKDF from a 32-byte Noise transport secret, encrypts/decrypts via ChaCha20-Poly1305 with `[direction || zero(3) || seq(8)]` nonces, and enforces a 64-frame replay window.
- `BleTransport` ships throwing stubs only — full BLE datagram support is Phase 3b.2.
- Mesh Debug self-test screen extended with a temporary "Send test datagram" button to prove the pipe end-to-end on hardware.

## Test plan
- [x] Unit: `MeshDatagramCipher` roundtrip preserves plaintext; wrong-direction decryption fails; replay window drops out-of-window seq + duplicate seq.
- [x] Unit: `MultiTransport.sendDatagram` routes to first child with discovered peer; prefers Bonjour over BLE; throws `TransportUnavailable` when no transport has the peer; `inboundDatagrams` merges children's streams.
- [x] Integration: two `BonjourTransport` instances exchange datagrams over loopback UDP.
- [x] flutter test — full host suite green.
- [x] dart analyze — clean on touched files.
- [x] Hardware: Android Redmi + iPhone wired exchange test datagrams over WiFi LAN; sends fail gracefully when WiFi off.

## Notes
- Phase 3b only — datagram pipe + cipher. No `MeshVoiceService` yet, no signaling, no audio integration. Phase 3c wires `MeshVoiceAudioEngine.outbound` through this pipe.
- BLE datagram deferred to Phase 3b.2 (BLE-specific work; not blocking LAN-primary path).
- Implements design `docs/superpowers/specs/2026-04-29-mesh-voice-call-phase3-design.md` (sections "Datagram channel inside MeshTransport" and "Encryption (MeshDatagramCipher)").

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"
```

---

## Self-review (run by author)

**Spec coverage (Phase 3 design — datagram + crypto sections):**
- `MeshTransport.sendDatagram` + `inboundDatagrams` interface → Task 1. ✓
- `InboundDatagram` model with `via` field → Task 1. ✓
- Bonjour parallel UDP socket bind → Task 3. ✓
- TXT advertise of `udp_port` → Task 3 Step 3. ✓
- Peer endpoint cache populated on `PeerDiscovered` → Task 3 Step 4. ✓
- Reverse lookup for inbound datagrams → Task 3 Step 5 `_handleDatagramEvent`. ✓
- Frame size cap 1200 bytes → Task 3 Step 5 (sendDatagram throws `ArgumentError` if too large). ✓
- BLE datagram → out of scope (Phase 3b.2), stubs in Task 1. Documented gap. ✓
- `MultiTransport` routing with Bonjour-first preference → Task 4 Step 3. ✓
- HKDF subkey derivation from Noise transport secret → Task 2 Step 3 `MeshDatagramCipher.derive`. ✓
- ChaCha20-Poly1305 with `[direction || zero || seq]` nonce → Task 2 Step 3 `_buildNonce`. ✓
- 64-frame sliding replay window → Task 2 Step 3 `_replayCheck` / `_replayAccept`. ✓
- Frame layout `[1 byte type][4 byte call_id][8 byte seq][N byte ciphertext+tag]` → spec describes this layered above the cipher; the cipher itself just takes/returns ciphertext, frame parsing is Phase 3c's `MeshVoiceService` responsibility. Acceptable scope — flagged in plan header.

**Placeholder scan:** Task 6 Step 1 describes the debug-button shape rather than full code (because the feature is throwaway smoke wiring and the file already establishes the pattern). Acceptable for a smoke-only step.

**Type consistency:**
- `InboundDatagram` shape `{srcPeer, bytes, via}` consistent across Tasks 1, 4, 5.
- `CipherDirection.aToB` / `bToA` enum referenced in Task 2 test + impl. ✓
- `TransportUnavailable` exception thrown by both `BonjourTransport.sendDatagram` (Task 3) and `MultiTransport.sendDatagram` (Task 4); caught by routing in Task 4 to fall through. ✓

**Estimated effort:** ~3-4 focused days for a single dev. Easier than Phase 3a — no native code, no FFI surprises. Most of the time goes into Task 3 (Bonjour wiring) and Task 6 (hardware smoke).

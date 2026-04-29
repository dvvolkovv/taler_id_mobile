# Mesh Voice Phase 3c — Signaling + MeshVoiceService Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Wire the existing `MeshVoiceAudioEngine` (Phase 3a) and `MeshTransport.sendDatagram`/`MeshDatagramCipher` (Phase 3b) into a working call-lifecycle orchestrator — `MeshVoiceService` — that owns a state machine, exchanges signaling envelopes (`call_invite` / `accept` / `reject` / `setup` / `end` / `keepalive`), and ferries encrypted Opus packets through the datagram pipe end-to-end. After this phase, two `MeshVoiceService` instances over a fake transport can place a 1-on-1 call and exchange real audio.

**Architecture:** Signaling lives on the existing reliable `MeshMessagingService.sendEnvelope` channel — `Envelope` gains an `extra: Map?` field for typed payloads. `MeshTransport` gains a synchronous `peerStatus(devicePk)` getter for eligibility checks. A new `MeshVoiceFrame` (`[1 byte type][4 bytes call_id][8 bytes seq][N bytes ciphertext+tag]`) wraps each datagram. `MeshVoiceService` owns the per-call state machine (caller/callee), 30s invite timeout, 5s setup timeout, 1Hz keepalive, 3s no-datagram timeout, and the audio-engine ↔ cipher ↔ transport plumbing for the active call.

**Tech Stack:** Dart 3.6+, existing `package:cryptography`, `package:async`. No new platform code.

**Spec:** `docs/superpowers/specs/2026-04-29-mesh-voice-call-phase3-design.md` (sections "Signaling (call setup and teardown)", "Eligibility check", "Persistence" — Hive persistence wired here, UI in Phase 3d).

**Branch:** `feature/mesh-voice-call-phase3c` from `dev` after Phase 3b merges (or rebase if 3b still in PR).

**File map:**

| File | Role | New / Modified |
|---|---|---|
| `lib/core/mesh/transport/mesh_transport.dart` | Add `enum PeerStatus { online, offline, unknown }` and `PeerStatus peerStatus(PeerId)` to abstract interface | Modified |
| `lib/core/mesh/transport/bonjour_transport.dart` | Implement `peerStatus` from active discovery state | Modified |
| `lib/core/mesh/transport/ble_transport.dart` | Implement `peerStatus` (mirror Bonjour, simpler) | Modified |
| `lib/core/mesh/transport/multi_transport.dart` | `peerStatus` returns `online` if any child reports online; else `offline` | Modified |
| `lib/core/mesh/services/envelope.dart` | Add optional `extra: Map<String, dynamic>?` field, JSON-serialise as `extra` key, backward-compatible parse | Modified |
| `lib/core/mesh/voice/mesh_voice_frame.dart` | New data class — header `[type | call_id | seq]` + ciphertext payload, encode/decode | New |
| `lib/core/mesh/services/mesh_messaging_service.dart` | Add `datagramCiphersFor(devicePk)` factory returning `({outbound, inbound})` from active Noise transport secret | Modified |
| `lib/core/mesh/voice/mesh_voice_service.dart` | New — call lifecycle state machine, signaling, audio engine wiring, timers | New |
| `lib/core/mesh/voice/mesh_voice_state.dart` | New — sealed class hierarchy for `CallState` (`Idle`, `Inviting`, `Incoming`, `Connecting`, `Active`, `Ended`) | New |
| `test/core/mesh/voice/mesh_voice_frame_test.dart` | Roundtrip + invalid-input tests | New |
| `test/core/mesh/voice/mesh_voice_service_test.dart` | Caller + callee state machine tests with fake transport / fake messaging | New |

---

## Task 1: `MeshTransport.peerStatus` getter (TDD)

**Files:**
- Modify: `lib/core/mesh/transport/mesh_transport.dart`
- Modify: `lib/core/mesh/transport/bonjour_transport.dart`
- Modify: `lib/core/mesh/transport/ble_transport.dart`
- Modify: `lib/core/mesh/transport/multi_transport.dart`
- Create: `test/core/mesh/transport/peer_status_test.dart`

- [ ] **Step 1: Write the failing test**

Create `test/core/mesh/transport/peer_status_test.dart`:

```dart
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:taler_id_mobile/core/mesh/transport/bonjour_transport.dart';
import 'package:taler_id_mobile/core/mesh/transport/mesh_transport.dart';
import 'package:taler_id_mobile/core/mesh/transport/peer_id.dart';

void main() {
  test('BonjourTransport.peerStatus returns offline before discovery, online after', () async {
    final t = BonjourTransport();
    final peer = PeerId(Uint8List.fromList(List<int>.generate(32, (i) => i)));

    expect(t.peerStatus(peer), PeerStatus.offline,
        reason: 'no discovery yet → offline');

    // Drive discovery via test hook (registers TXT-resolved peer).
    t.testRegisterPeer(peer, '127.0.0.1', 8888);
    expect(t.peerStatus(peer), PeerStatus.online);
  });
}
```

- [ ] **Step 2: Run, expect FAIL**

```bash
cd /Users/dmitry/Downloads/taler_id_mobile && flutter test test/core/mesh/transport/peer_status_test.dart 2>&1 | tail -8
```

Expected: compilation error — `PeerStatus` and `peerStatus` not defined.

- [ ] **Step 3: Add `PeerStatus` enum + abstract method to `MeshTransport`**

Open `lib/core/mesh/transport/mesh_transport.dart`. Near the top (after imports, before the existing `class PeerDiscovered`), add:

```dart
/// Reachability state for a given peer at the moment of the query.
/// `online` = visible in active discovery on at least one transport.
/// `offline` = not currently discovered (used to be, or never was).
/// `unknown` = transport has no state for this peer (e.g., never advertised
/// here). Currently we collapse `offline` and `unknown` for callers; the
/// distinction is reserved for future BLE-only peer tracking.
enum PeerStatus { online, offline, unknown }
```

Inside the `abstract class MeshTransport`, after the existing abstract methods (right after `Future<void> sendDatagram`), add:

```dart
  /// Synchronous reachability query. Used by UI eligibility checks (e.g.,
  /// "show mesh-call button only if the peer is reachable").
  PeerStatus peerStatus(PeerId peer);
```

- [ ] **Step 4: Implement on `BonjourTransport`**

Open `lib/core/mesh/transport/bonjour_transport.dart`. Add inside the class (any reasonable location, e.g., near the existing peer-related code):

```dart
  @override
  PeerStatus peerStatus(PeerId peer) {
    return _peerUdpEndpoints.containsKey(peer)
        ? PeerStatus.online
        : PeerStatus.offline;
  }
```

The `_peerUdpEndpoints` cache is populated on resolved discovery (T3 of Phase 3b) and cleared on `stopAdvertising`. Same source-of-truth as `sendDatagram`'s endpoint lookup.

- [ ] **Step 5: Implement on `BleTransport`**

Open `lib/core/mesh/transport/ble_transport.dart`. Find the existing peer-tracking field (search for the structure that holds discovered peers — most likely `Map<PeerId, ...> _peers` or similar). Add:

```dart
  @override
  PeerStatus peerStatus(PeerId peer) {
    // BLE uses its own discovery state — adapt to whatever field tracks
    // currently-discovered peers in this transport. If no such field
    // exists yet, return PeerStatus.unknown for now (Phase 3b.2 BLE work
    // will wire this properly).
    return PeerStatus.unknown;
  }
```

If there IS an existing `_peers` or `_discoveredPeers` map you can read, use:

```dart
return _discoveredPeers.containsKey(peer)
    ? PeerStatus.online
    : PeerStatus.offline;
```

(Use the actual field name found in the file.) Implementer's call.

- [ ] **Step 6: Implement on `MultiTransport`**

Open `lib/core/mesh/transport/multi_transport.dart`. Add:

```dart
  @override
  PeerStatus peerStatus(PeerId peer) {
    final knownOn = _knownBy[peer];
    if (knownOn == null || knownOn.isEmpty) return PeerStatus.offline;
    // Online if any child reports online for this peer.
    for (final id in knownOn) {
      final child = _children[id];
      if (child != null && child.peerStatus(peer) == PeerStatus.online) {
        return PeerStatus.online;
      }
    }
    return PeerStatus.offline;
  }
```

- [ ] **Step 7: Run new test + full transport suite**

```bash
cd /Users/dmitry/Downloads/taler_id_mobile && flutter test test/core/mesh/transport/peer_status_test.dart 2>&1 | tail -5
```

Expected: 1 test passed.

```bash
cd /Users/dmitry/Downloads/taler_id_mobile && flutter test test/core/mesh/transport/ 2>&1 | tail -3
```

Expected: all tests pass. The `_FakeTransport` classes in sibling test files will fail compilation — fix them as part of this task by adding the stub:

```dart
@override
PeerStatus peerStatus(PeerId peer) => PeerStatus.unknown;
```

Affected files: `test/core/mesh/transport/multi_transport_test.dart`, `test/core/mesh/transport/multi_transport_datagram_test.dart`, plus the three `_FakeTransport`-using files we already touched in 3b: `test/core/mesh/services/mesh_messaging_service_handshake_reset_test.dart`, `test/core/mesh/services/mesh_messaging_service_test.dart`, `test/features/mesh/presentation/bloc/mesh_status_bloc_test.dart`.

Add the import for `PeerStatus` (it lives in `mesh_transport.dart` which is already imported in those files).

Re-run full suite:

```bash
cd /Users/dmitry/Downloads/taler_id_mobile && flutter test test/core/mesh/transport/ 2>&1 | tail -3
```

- [ ] **Step 8: Commit**

```bash
cd /Users/dmitry/Downloads/taler_id_mobile && git add lib/core/mesh/transport/ test/core/mesh/transport/peer_status_test.dart test/core/mesh/services/mesh_messaging_service_handshake_reset_test.dart test/core/mesh/services/mesh_messaging_service_test.dart test/features/mesh/presentation/bloc/mesh_status_bloc_test.dart && git commit -m "feat(mesh-transport): peerStatus getter for synchronous eligibility checks"
```

---

## Task 2: Extend `Envelope` with optional `extra` field (TDD)

**Files:**
- Modify: `lib/core/mesh/services/envelope.dart`
- Modify: `test/core/mesh/services/envelope_test.dart` (if exists; create if not)

- [ ] **Step 1: Find or create the envelope test file**

Check: `ls test/core/mesh/services/envelope_test.dart`. If it exists, append to it. If not, create:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:taler_id_mobile/core/mesh/services/envelope.dart';

void main() {
  group('Envelope.extra', () {
    test('roundtrip preserves extra map', () {
      final e = Envelope(
        version: 1,
        type: 'call_invite',
        convId: 'conv-1',
        clientId: 'call-uuid-1',
        text: '',
        sentAt: DateTime.utc(2026, 4, 29, 12),
        extra: {'codec': 'opus', 'rate': 16000},
      );
      final json = e.toJson();
      expect(json['extra'], {'codec': 'opus', 'rate': 16000});

      final back = Envelope.fromJson(json);
      expect(back.extra, {'codec': 'opus', 'rate': 16000});
    });

    test('fromJson tolerates missing extra (backward compat with v1 peers)', () {
      final e = Envelope.fromJson({
        'v': 1,
        'type': 'text',
        'convId': 'conv-1',
        'clientId': 'msg-1',
        'text': 'hi',
        'sentAt': '2026-04-29T12:00:00.000Z',
      });
      expect(e.extra, isNull);
    });

    test('toJson omits extra when null', () {
      final e = Envelope(
        version: 1,
        type: 'text',
        convId: 'conv-1',
        clientId: 'msg-1',
        text: 'hi',
        sentAt: DateTime.utc(2026, 4, 29, 12),
      );
      final json = e.toJson();
      expect(json.containsKey('extra'), isFalse);
    });
  });
}
```

- [ ] **Step 2: Run, expect FAIL**

```bash
cd /Users/dmitry/Downloads/taler_id_mobile && flutter test test/core/mesh/services/envelope_test.dart 2>&1 | tail -8
```

Expected: compilation error — `extra` named parameter not defined.

- [ ] **Step 3: Add `extra` field to `Envelope`**

Open `lib/core/mesh/services/envelope.dart`. Modify the class:

```dart
class Envelope {
  final int version;
  final String type;
  final String convId;
  final String clientId;
  final String text;
  final DateTime sentAt;

  /// Optional typed payload for non-text envelopes (e.g., call signaling).
  /// Null for legacy v1 text envelopes; populated for `call_*` types in
  /// Phase 3 mesh voice.
  final Map<String, dynamic>? extra;

  Envelope({
    required this.version,
    required this.type,
    required this.convId,
    required this.clientId,
    required this.text,
    required this.sentAt,
    this.extra,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'v': version,
      'type': type,
      'convId': convId,
      'clientId': clientId,
      'text': text,
      'sentAt': sentAt.toUtc().toIso8601String(),
    };
    if (extra != null) {
      json['extra'] = extra;
    }
    return json;
  }

  factory Envelope.fromJson(Map<String, dynamic> json) {
    final v = json['v'];
    final type = json['type'];
    final convId = json['convId'];
    final clientId = json['clientId'];
    final text = json['text'];
    final sentAt = json['sentAt'];
    if (v is! int || type is! String || convId is! String ||
        clientId is! String || text is! String || sentAt is! String) {
      throw const FormatException('Envelope: missing or wrong-typed field');
    }
    final DateTime parsedAt;
    try {
      parsedAt = DateTime.parse(sentAt).toUtc();
    } on FormatException {
      throw const FormatException('Envelope: invalid sentAt timestamp');
    }
    final extraRaw = json['extra'];
    final Map<String, dynamic>? extra = extraRaw is Map<String, dynamic>
        ? extraRaw
        : (extraRaw is Map ? Map<String, dynamic>.from(extraRaw) : null);
    return Envelope(
      version: v,
      type: type,
      convId: convId,
      clientId: clientId,
      text: text,
      sentAt: parsedAt,
      extra: extra,
    );
  }
}
```

- [ ] **Step 4: Run test, expect PASS**

```bash
cd /Users/dmitry/Downloads/taler_id_mobile && flutter test test/core/mesh/services/envelope_test.dart 2>&1 | tail -5
```

Expected: 3 tests passed.

- [ ] **Step 5: Run mesh service suite for regression**

```bash
cd /Users/dmitry/Downloads/taler_id_mobile && flutter test test/core/mesh/ 2>&1 | tail -3
```

Expected: all tests pass.

- [ ] **Step 6: Commit**

```bash
cd /Users/dmitry/Downloads/taler_id_mobile && git add lib/core/mesh/services/envelope.dart test/core/mesh/services/envelope_test.dart && git commit -m "feat(mesh-envelope): optional extra map for typed signaling payloads"
```

---

## Task 3: `MeshVoiceFrame` data layout (TDD)

**Files:**
- Create: `lib/core/mesh/voice/mesh_voice_frame.dart`
- Create: `test/core/mesh/voice/mesh_voice_frame_test.dart`

Pure Dart, unit-testable on host VM. No FFI, no platform code.

Frame layout: `[1 byte type][4 bytes call_id][8 bytes seq][N bytes ciphertext+tag]`. Total header = 13 bytes. Ciphertext is what came out of `MeshDatagramCipher.encrypt` (Phase 3b T2).

`type` values:
- `0x10` = audio (Opus voice payload)
- `0x11` = audio-with-FEC (reserved for Phase 4; not used in 3c)
- `0x12` = RTCP-lite (call-level metadata — also reserved)

Phase 3c only emits/parses `0x10`.

- [ ] **Step 1: Write the failing test**

Create `test/core/mesh/voice/mesh_voice_frame_test.dart`:

```dart
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:taler_id_mobile/core/mesh/voice/mesh_voice_frame.dart';

void main() {
  group('MeshVoiceFrame', () {
    test('encode/decode round-trip preserves header + ciphertext', () {
      final ct = Uint8List.fromList(List<int>.generate(80, (i) => i + 1));
      final frame = MeshVoiceFrame(
        type: MeshVoiceFrameType.audio,
        callId: 0xAABBCCDD,
        seq: 42,
        ciphertext: ct,
      );
      final wire = frame.encode();
      expect(wire.length, 13 + 80, reason: 'header(13) + ciphertext(80)');
      expect(wire[0], 0x10, reason: 'audio type byte');

      final back = MeshVoiceFrame.decode(wire);
      expect(back.type, MeshVoiceFrameType.audio);
      expect(back.callId, 0xAABBCCDD);
      expect(back.seq, 42);
      expect(back.ciphertext, ct);
    });

    test('decode throws on truncated wire (less than header)', () {
      expect(
        () => MeshVoiceFrame.decode(Uint8List.fromList([0x10, 0, 0])),
        throwsA(isA<FormatException>()),
      );
    });

    test('decode throws on unknown type byte', () {
      // 13-byte header with type 0x99 (not audio/FEC/RTCP) + 1 byte payload.
      final bad = Uint8List(14)..[0] = 0x99;
      expect(
        () => MeshVoiceFrame.decode(bad),
        throwsA(isA<FormatException>()),
      );
    });

    test('big-endian seq + call_id encoded correctly', () {
      final frame = MeshVoiceFrame(
        type: MeshVoiceFrameType.audio,
        callId: 0x01020304,
        seq: 0x0807060504030201, // 64-bit pattern
        ciphertext: Uint8List.fromList([0xFF]),
      );
      final wire = frame.encode();
      // bytes 1..4 = call_id big-endian = 01 02 03 04
      expect(wire.sublist(1, 5), Uint8List.fromList([0x01, 0x02, 0x03, 0x04]));
      // bytes 5..12 = seq big-endian
      expect(wire.sublist(5, 13),
          Uint8List.fromList([0x08, 0x07, 0x06, 0x05, 0x04, 0x03, 0x02, 0x01]));
    });
  });
}
```

- [ ] **Step 2: Run, expect FAIL**

```bash
cd /Users/dmitry/Downloads/taler_id_mobile && flutter test test/core/mesh/voice/mesh_voice_frame_test.dart 2>&1 | tail -8
```

Expected: compilation error — `MeshVoiceFrame` not defined.

- [ ] **Step 3: Implement `MeshVoiceFrame`**

Create `lib/core/mesh/voice/mesh_voice_frame.dart`:

```dart
import 'dart:typed_data';

/// Frame-type byte enumeration. Only `audio` is emitted/parsed in Phase 3c;
/// the others are reserved for Phase 4+ (FEC, RTCP-lite).
enum MeshVoiceFrameType {
  audio(0x10),
  audioWithFec(0x11),
  rtcpLite(0x12);

  final int byte;
  const MeshVoiceFrameType(this.byte);

  static MeshVoiceFrameType fromByte(int b) {
    for (final t in MeshVoiceFrameType.values) {
      if (t.byte == b) return t;
    }
    throw FormatException('MeshVoiceFrame: unknown type byte 0x${b.toRadixString(16).padLeft(2, '0')}');
  }
}

/// Wire-level frame for a single mesh-voice datagram.
///
/// Layout (big-endian):
///   byte 0:        type (one of [MeshVoiceFrameType])
///   bytes 1..4:    call_id (32-bit, identifies the call session)
///   bytes 5..12:   seq (64-bit, monotonically increasing per direction per call)
///   bytes 13..N:   ciphertext+tag (output of MeshDatagramCipher.encrypt)
///
/// Header is 13 bytes; total frame size is bounded by the underlying
/// transport's datagram MTU (1200 bytes for Bonjour UDP).
class MeshVoiceFrame {
  static const int headerLength = 13;

  final MeshVoiceFrameType type;
  final int callId;
  final int seq;
  final Uint8List ciphertext;

  MeshVoiceFrame({
    required this.type,
    required this.callId,
    required this.seq,
    required this.ciphertext,
  });

  Uint8List encode() {
    final out = Uint8List(headerLength + ciphertext.length);
    out[0] = type.byte;
    final view = ByteData.view(out.buffer);
    view.setUint32(1, callId, Endian.big);
    view.setUint64(5, seq, Endian.big);
    out.setAll(headerLength, ciphertext);
    return out;
  }

  static MeshVoiceFrame decode(Uint8List bytes) {
    if (bytes.length < headerLength) {
      throw FormatException(
          'MeshVoiceFrame: wire shorter than header (${bytes.length} < $headerLength)');
    }
    final type = MeshVoiceFrameType.fromByte(bytes[0]);
    final view = ByteData.view(bytes.buffer, bytes.offsetInBytes, bytes.length);
    final callId = view.getUint32(1, Endian.big);
    final seq = view.getUint64(5, Endian.big);
    final ct = Uint8List.fromList(bytes.sublist(headerLength));
    return MeshVoiceFrame(type: type, callId: callId, seq: seq, ciphertext: ct);
  }
}
```

- [ ] **Step 4: Run test, expect PASS**

```bash
cd /Users/dmitry/Downloads/taler_id_mobile && flutter test test/core/mesh/voice/mesh_voice_frame_test.dart 2>&1 | tail -5
```

Expected: 4 tests passed.

- [ ] **Step 5: Commit**

```bash
cd /Users/dmitry/Downloads/taler_id_mobile && git add lib/core/mesh/voice/mesh_voice_frame.dart test/core/mesh/voice/mesh_voice_frame_test.dart && git commit -m "feat(mesh-voice): MeshVoiceFrame wire layout (header + ciphertext)"
```

---

## Task 4: `MeshMessagingService.datagramCiphersFor` factory

**Files:**
- Modify: `lib/core/mesh/services/mesh_messaging_service.dart`
- Create: `test/core/mesh/services/datagram_ciphers_for_test.dart` (small unit test using fake/internal access)

The cipher needs the 32-byte Noise transport secret derived in handshake. We expose it via a factory that returns both directions (caller-side outbound + inbound).

**Direction convention:** the peer with the *lexicographically smaller* `devicePk.bytes` is "a"; the other is "b". Both peers compute who is who deterministically. `outbound` cipher uses `aToB` if I'm "a", else `bToA`. `inbound` is the opposite.

- [ ] **Step 1: Read the existing Noise session structure**

Open `lib/core/mesh/services/mesh_messaging_service.dart` and `lib/core/mesh/crypto/noise/session.dart`. Locate where the transport keys are stored after handshake completion. The Noise IK `split()` result is typically two 32-byte keys: one for sending, one for receiving. We want a single 32-byte secret that BOTH peers can derive identical sub-keys from — which means we need a value that's symmetric.

The simplest symmetric value is the Noise *handshake hash* (the `h` variable at the end of the handshake), which both peers compute identically. Or we can use one of the split keys but choose deterministically (e.g., always the "send" key from the lower-pk peer).

**Decision (to lock in this task):** use the Noise handshake hash as the shared secret. Most Noise impls expose it as `getHandshakeHash()` or store it as `state.h`. If it's not exposed, add a getter.

If the existing Noise session class already exposes a "shared secret" or "channel binding" suitable for HKDF input, use that. Read the file before deciding.

- [ ] **Step 2: Add the factory method**

In `lib/core/mesh/services/mesh_messaging_service.dart`, add a public method on `MeshMessagingService`:

```dart
  /// Returns the AEAD cipher pair for sending/receiving voice datagrams to
  /// [peer]. Null if no Noise session has been established for that peer
  /// yet. Both peers derive identical sub-keys from the Noise handshake's
  /// shared secret + a direction-tagged HKDF info string.
  Future<({MeshDatagramCipher outbound, MeshDatagramCipher inbound})?>
      datagramCiphersFor(PeerId peer) async {
    final session = _sessions[peer];
    if (session == null || !session.handshakeComplete) {
      return null;
    }
    final secret = session.handshakeHash; // 32 bytes; same on both peers
    // Direction: peer with lexicographically smaller pk is "a".
    final myBytes = _myDevicePublicKey;
    final theirBytes = peer.bytes;
    final iAmA = _compareBytes(myBytes, theirBytes) < 0;
    final outboundDir = iAmA ? CipherDirection.aToB : CipherDirection.bToA;
    final inboundDir = iAmA ? CipherDirection.bToA : CipherDirection.aToB;
    final outbound = await MeshDatagramCipher.derive(
      transportSecret: secret,
      direction: outboundDir,
    );
    final inbound = await MeshDatagramCipher.derive(
      transportSecret: secret,
      direction: inboundDir,
    );
    return (outbound: outbound, inbound: inbound);
  }

  static int _compareBytes(Uint8List a, Uint8List b) {
    final minLen = a.length < b.length ? a.length : b.length;
    for (var i = 0; i < minLen; i++) {
      final c = a[i] - b[i];
      if (c != 0) return c;
    }
    return a.length - b.length;
  }
```

Add the imports at the top of the file:

```dart
import '../crypto/mesh_datagram_cipher.dart';
```

If `_sessions` is the wrong field name (read the file to find it), or `handshakeComplete` / `handshakeHash` don't exist on the existing Noise session class, you have two options:

(a) Add the missing getter on the Noise session class. The handshake hash is the variable conventionally called `h` in Noise IK. If the session stores it as `_h`, add `Uint8List get handshakeHash => _h;`.

(b) If session doesn't track `h` separately (e.g., it's discarded after split), use one of the split keys as the secret. Pick the SEND key of the "a" peer (lower pk) — this is deterministic for both sides if both know who is "a".

Document the choice in a comment.

- [ ] **Step 3: Write a focused unit test**

Create `test/core/mesh/services/datagram_ciphers_for_test.dart`:

```dart
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:taler_id_mobile/core/mesh/crypto/mesh_datagram_cipher.dart';

// This test validates the *direction-derivation* logic only, not the
// full MeshMessagingService wiring (covered by integration tests). We
// derive ciphers manually with known direction tags and verify that
// alice's outbound matches bob's inbound on a roundtrip.
void main() {
  test('alice.outbound + bob.inbound ciphers interoperate', () async {
    final secret = Uint8List.fromList(List<int>.generate(32, (i) => i + 1));

    // Alice has lower pk → she is "a". Outbound = aToB.
    final aliceOut = await MeshDatagramCipher.derive(
      transportSecret: secret,
      direction: CipherDirection.aToB,
    );
    // Bob is "b". Inbound = aToB (he reads alice's aToB stream).
    final bobIn = await MeshDatagramCipher.derive(
      transportSecret: secret,
      direction: CipherDirection.aToB,
    );

    final pt = Uint8List.fromList([1, 2, 3, 4, 5]);
    final ct = await aliceOut.encrypt(seq: 7, plaintext: pt);
    final dec = await bobIn.decrypt(seq: 7, ciphertext: ct);
    expect(dec, pt);
  });

  test('alice.inbound + bob.outbound ciphers interoperate (reverse direction)', () async {
    final secret = Uint8List.fromList(List<int>.generate(32, (i) => i + 1));

    // Alice = "a". Inbound = bToA (she reads bob's bToA stream).
    final aliceIn = await MeshDatagramCipher.derive(
      transportSecret: secret,
      direction: CipherDirection.bToA,
    );
    // Bob = "b". Outbound = bToA.
    final bobOut = await MeshDatagramCipher.derive(
      transportSecret: secret,
      direction: CipherDirection.bToA,
    );

    final pt = Uint8List.fromList([99]);
    final ct = await bobOut.encrypt(seq: 1, plaintext: pt);
    final dec = await aliceIn.decrypt(seq: 1, ciphertext: ct);
    expect(dec, pt);
  });
}
```

- [ ] **Step 4: Run test + full mesh suite**

```bash
cd /Users/dmitry/Downloads/taler_id_mobile && flutter test test/core/mesh/services/datagram_ciphers_for_test.dart 2>&1 | tail -5
```

Expected: 2 tests passed.

```bash
cd /Users/dmitry/Downloads/taler_id_mobile && flutter test test/core/mesh/ 2>&1 | tail -3
```

Expected: all tests pass.

- [ ] **Step 5: Commit**

```bash
cd /Users/dmitry/Downloads/taler_id_mobile && git add lib/core/mesh/services/mesh_messaging_service.dart test/core/mesh/services/datagram_ciphers_for_test.dart && git commit -m "feat(mesh-messaging): datagramCiphersFor factory (HKDF subkeys from Noise handshake hash)"
```

If the Noise session class needed modification (Step 2 option (a)), include the file in `git add`.

---

## Task 5: `MeshVoiceService` skeleton + state types

**Files:**
- Create: `lib/core/mesh/voice/mesh_voice_state.dart`
- Create: `lib/core/mesh/voice/mesh_voice_service.dart`

Skeleton only — class shape, constructors, dependency wiring, state enum. State transitions land in T6/T7.

- [ ] **Step 1: Define the state hierarchy**

Create `lib/core/mesh/voice/mesh_voice_state.dart`:

```dart
import '../transport/peer_id.dart';

/// Sealed-style hierarchy for the MeshVoiceService state machine.
sealed class CallState {
  const CallState();
}

/// No active call — service waiting for invite or user-initiated call.
class IdleState extends CallState {
  const IdleState();
}

/// Caller side: invite sent, awaiting accept/reject (30s timeout).
class InvitingState extends CallState {
  final PeerId calleeDevicePk;
  final int callId;
  final DateTime sentAt;
  const InvitingState({
    required this.calleeDevicePk,
    required this.callId,
    required this.sentAt,
  });
}

/// Callee side: invite received, UI showing accept/decline.
class IncomingState extends CallState {
  final PeerId callerDevicePk;
  final int callId;
  final DateTime receivedAt;
  const IncomingState({
    required this.callerDevicePk,
    required this.callId,
    required this.receivedAt,
  });
}

/// Both sides: parameters negotiated, audio session being set up (5s timeout).
class ConnectingState extends CallState {
  final PeerId peerDevicePk;
  final int callId;
  final bool isCaller;
  const ConnectingState({
    required this.peerDevicePk,
    required this.callId,
    required this.isCaller,
  });
}

/// Both sides: audio flowing in both directions.
class ActiveState extends CallState {
  final PeerId peerDevicePk;
  final int callId;
  final bool isCaller;
  final DateTime startedAt;
  const ActiveState({
    required this.peerDevicePk,
    required this.callId,
    required this.isCaller,
    required this.startedAt,
  });
}

/// Terminal state — call cleanup done. `reason` describes why.
class EndedState extends CallState {
  final int callId;
  final EndReason reason;
  const EndedState({required this.callId, required this.reason});
}

enum EndReason {
  userHangup,
  remoteHangup,
  rejectedByCallee,
  inviteTimeout,
  setupTimeout,
  noKeepalive,
  peerLost,
  error,
}
```

- [ ] **Step 2: Define the service skeleton**

Create `lib/core/mesh/voice/mesh_voice_service.dart`:

```dart
import 'dart:async';

import '../../audio/mesh_voice_audio_engine.dart';
import '../services/mesh_messaging_service.dart';
import '../transport/mesh_transport.dart';
import '../transport/peer_id.dart';
import 'mesh_voice_state.dart';

/// Orchestrates a 1-on-1 mesh voice call: signaling, state machine,
/// audio-engine ↔ datagram-pipe wiring. One service per app instance;
/// only one call active at a time.
///
/// Lifecycle (caller): IDLE → INVITING → CONNECTING → ACTIVE → ENDED.
/// Lifecycle (callee): IDLE → INCOMING → CONNECTING → ACTIVE → ENDED.
class MeshVoiceService {
  final MeshMessagingService messaging;
  final MeshTransport transport;
  final MeshVoiceAudioEngine Function() audioEngineFactory;

  final _stateCtrl = StreamController<CallState>.broadcast();
  CallState _state = const IdleState();

  StreamSubscription? _envelopeSub;
  StreamSubscription? _datagramSub;

  MeshVoiceService({
    required this.messaging,
    required this.transport,
    required this.audioEngineFactory,
  });

  /// Current call state.
  CallState get state => _state;

  /// Stream of state transitions.
  Stream<CallState> get stateStream => _stateCtrl.stream;

  /// Wire up signaling + datagram listeners. Call once at app start
  /// (typically from DI bootstrap, after MeshMessagingService.start).
  void start() {
    _envelopeSub = messaging.inbound.listen(_onEnvelope);
    _datagramSub = transport.inboundDatagrams.listen(_onDatagram);
  }

  /// Caller-side: initiate a call to [calleeDevicePk]. Returns the
  /// generated call_id. Throws if not currently IDLE.
  Future<int> invite(PeerId calleeDevicePk) async {
    throw UnimplementedError('invite — implemented in Task 6');
  }

  /// Callee-side: accept the current INCOMING call.
  Future<void> accept() async {
    throw UnimplementedError('accept — implemented in Task 7');
  }

  /// Either side: end the active or pending call.
  Future<void> hangup({EndReason reason = EndReason.userHangup}) async {
    throw UnimplementedError('hangup — implemented in Task 9');
  }

  /// Cleanup on app shutdown.
  Future<void> dispose() async {
    await _envelopeSub?.cancel();
    await _datagramSub?.cancel();
    await _stateCtrl.close();
  }

  void _setState(CallState next) {
    _state = next;
    _stateCtrl.add(next);
  }

  void _onEnvelope(MeshInboundMessage msg) {
    // Routed by `type` to per-type handlers in T6/T7.
  }

  void _onDatagram(InboundDatagram dg) {
    // Decrypt + dispatch in T8.
  }
}
```

The signature `MeshInboundMessage` should match whatever `messaging.inbound` emits. Read the actual type from `mesh_messaging_service.dart` and adjust the lambda parameter type.

- [ ] **Step 3: Compile-check + commit**

```bash
cd /Users/dmitry/Downloads/taler_id_mobile && dart analyze lib/core/mesh/voice/ 2>&1 | tail -5
```

Expected: no errors. The `UnimplementedError` throws are expected and OK at this stage.

```bash
cd /Users/dmitry/Downloads/taler_id_mobile && git add lib/core/mesh/voice/ && git commit -m "feat(mesh-voice): MeshVoiceService skeleton + CallState hierarchy"
```

---

## Task 6: Caller path — `invite` → handle `call_accept` / `call_reject` (TDD)

**Files:**
- Modify: `lib/core/mesh/voice/mesh_voice_service.dart`
- Create: `test/core/mesh/voice/mesh_voice_service_caller_test.dart`

- [ ] **Step 1: Write the failing tests**

Create `test/core/mesh/voice/mesh_voice_service_caller_test.dart`:

```dart
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taler_id_mobile/core/audio/mesh_voice_audio_engine.dart';
import 'package:taler_id_mobile/core/mesh/services/envelope.dart';
import 'package:taler_id_mobile/core/mesh/services/mesh_messaging_service.dart';
import 'package:taler_id_mobile/core/mesh/transport/mesh_transport.dart';
import 'package:taler_id_mobile/core/mesh/transport/peer_id.dart';
import 'package:taler_id_mobile/core/mesh/voice/mesh_voice_service.dart';
import 'package:taler_id_mobile/core/mesh/voice/mesh_voice_state.dart';

import 'mesh_voice_service_test_utils.dart';

void main() {
  group('MeshVoiceService caller path', () {
    test('invite() emits InvitingState and sends call_invite envelope', () async {
      final h = MeshVoiceTestHarness.build();
      h.svc.start();

      final calleePk = PeerId(Uint8List.fromList(List<int>.generate(32, (i) => 200 + i)));
      final callId = await h.svc.invite(calleePk);

      expect(h.svc.state, isA<InvitingState>());
      final inv = h.svc.state as InvitingState;
      expect(inv.calleeDevicePk, calleePk);
      expect(inv.callId, callId);

      // Outbound envelope was issued via FakeMessaging.
      expect(h.fakeMessaging.sentEnvelopes, hasLength(1));
      final sent = h.fakeMessaging.sentEnvelopes.first;
      expect(sent.toUserPk, calleePk);
      expect(sent.envelope.type, 'call_invite');
      expect(sent.envelope.extra, isNotNull);
      expect(sent.envelope.extra!['call_id'], callId);
    });

    test('on call_accept envelope, transitions to ConnectingState', () async {
      final h = MeshVoiceTestHarness.build();
      h.svc.start();
      final callee = PeerId(Uint8List.fromList(List<int>.generate(32, (i) => 200 + i)));
      final callId = await h.svc.invite(callee);

      // Simulate inbound accept.
      h.fakeMessaging.emitInbound(MeshInboundMessage(
        fromUserPk: callee,
        envelope: Envelope(
          version: 1,
          type: 'call_accept',
          convId: 'call-${callId.toRadixString(16)}',
          clientId: callId.toRadixString(16),
          text: '',
          sentAt: DateTime.now().toUtc(),
          extra: {'call_id': callId},
        ),
      ));
      await Future<void>.delayed(Duration.zero);

      expect(h.svc.state, isA<ConnectingState>());
    });

    test('on call_reject envelope, transitions to EndedState(rejectedByCallee)', () async {
      final h = MeshVoiceTestHarness.build();
      h.svc.start();
      final callee = PeerId(Uint8List.fromList(List<int>.generate(32, (i) => 200 + i)));
      final callId = await h.svc.invite(callee);

      h.fakeMessaging.emitInbound(MeshInboundMessage(
        fromUserPk: callee,
        envelope: Envelope(
          version: 1,
          type: 'call_reject',
          convId: 'call-${callId.toRadixString(16)}',
          clientId: callId.toRadixString(16),
          text: '',
          sentAt: DateTime.now().toUtc(),
          extra: {'call_id': callId, 'reason': 'declined'},
        ),
      ));
      await Future<void>.delayed(Duration.zero);

      expect(h.svc.state, isA<EndedState>());
      expect((h.svc.state as EndedState).reason, EndReason.rejectedByCallee);
    });

    test('30s no response → invite timeout', () {
      fakeAsync((async) {
        final h = MeshVoiceTestHarness.build();
        h.svc.start();
        final callee = PeerId(Uint8List.fromList(List<int>.generate(32, (i) => 1)));
        // ignore: unawaited_futures
        h.svc.invite(callee);
        async.flushMicrotasks();

        async.elapse(const Duration(seconds: 31));
        expect(h.svc.state, isA<EndedState>());
        expect((h.svc.state as EndedState).reason, EndReason.inviteTimeout);
      });
    });
  });
}
```

- [ ] **Step 2: Create the test harness file**

Create `test/core/mesh/voice/mesh_voice_service_test_utils.dart`:

```dart
import 'dart:async';
import 'dart:typed_data';

import 'package:taler_id_mobile/core/audio/mesh_voice_audio_engine.dart';
import 'package:taler_id_mobile/core/mesh/services/envelope.dart';
import 'package:taler_id_mobile/core/mesh/services/mesh_messaging_service.dart';
import 'package:taler_id_mobile/core/mesh/transport/mesh_transport.dart';
import 'package:taler_id_mobile/core/mesh/transport/peer_id.dart';
import 'package:taler_id_mobile/core/mesh/transport/transport_preference.dart';
import 'package:taler_id_mobile/core/mesh/voice/mesh_voice_service.dart';

class FakeMessagingService implements MeshMessagingService {
  final _inboundCtrl = StreamController<MeshInboundMessage>.broadcast();
  final sentEnvelopes = <({PeerId toUserPk, Envelope envelope})>[];

  @override
  Stream<MeshInboundMessage> get inbound => _inboundCtrl.stream;

  @override
  Future<void> sendEnvelope({required PeerId toUserPk, required Envelope envelope}) async {
    sentEnvelopes.add((toUserPk: toUserPk, envelope: envelope));
  }

  void emitInbound(MeshInboundMessage m) => _inboundCtrl.add(m);

  // Other MeshMessagingService members — throw if hit by accident.
  @override
  noSuchMethod(Invocation i) =>
      throw UnimplementedError('FakeMessagingService.${i.memberName}');
}

class FakeTransport implements MeshTransport {
  final _discCtrl = StreamController<PeerDiscovered>.broadcast();
  final _lossCtrl = StreamController<PeerLost>.broadcast();
  final _inboundCtrl = StreamController<InboundFrame>.broadcast();
  final _datagramCtrl = StreamController<InboundDatagram>.broadcast();
  final sentDatagrams = <(PeerId, Uint8List)>[];

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
    sentDatagrams.add((peer, data));
  }

  @override
  PeerStatus peerStatus(PeerId peer) => PeerStatus.online;

  void emitDatagram(InboundDatagram dg) => _datagramCtrl.add(dg);
}

class FakeAudioEngine implements MeshVoiceAudioEngine {
  bool started = false;
  bool stopped = false;
  final _outboundCtrl = StreamController<Uint8List>.broadcast();
  final inboundFrames = <(int seq, Uint8List payload)>[];

  @override Stream<Uint8List> get outbound => _outboundCtrl.stream;

  @override Future<void> start() async { started = true; }
  @override Future<void> stop() async { stopped = true; }
  @override
  void inbound({required int seq, required Uint8List payload}) {
    inboundFrames.add((seq, payload));
  }

  void emitOutbound(Uint8List bytes) => _outboundCtrl.add(bytes);

  @override noSuchMethod(Invocation i) =>
      throw UnimplementedError('FakeAudioEngine.${i.memberName}');
}

class MeshVoiceTestHarness {
  final FakeMessagingService fakeMessaging;
  final FakeTransport fakeTransport;
  final FakeAudioEngine fakeAudioEngine;
  final MeshVoiceService svc;

  MeshVoiceTestHarness._(this.fakeMessaging, this.fakeTransport,
      this.fakeAudioEngine, this.svc);

  static MeshVoiceTestHarness build() {
    final messaging = FakeMessagingService();
    final transport = FakeTransport();
    final audio = FakeAudioEngine();
    final svc = MeshVoiceService(
      messaging: messaging,
      transport: transport,
      audioEngineFactory: () => audio,
    );
    return MeshVoiceTestHarness._(messaging, transport, audio, svc);
  }
}
```

If `MeshInboundMessage` lives in a different file or has a different shape, adjust imports/usage. The actual type name comes from `mesh_messaging_service.dart`.

- [ ] **Step 3: Run, expect FAIL**

```bash
cd /Users/dmitry/Downloads/taler_id_mobile && flutter test test/core/mesh/voice/mesh_voice_service_caller_test.dart 2>&1 | tail -10
```

Expected: tests fail because `invite()` throws `UnimplementedError`.

- [ ] **Step 4: Implement `invite` + caller-side envelope dispatch**

Open `lib/core/mesh/voice/mesh_voice_service.dart`. Replace the `invite` stub and extend `_onEnvelope`:

```dart
import 'dart:math';

class MeshVoiceService {
  // ... existing fields ...

  static const Duration _inviteTimeout = Duration(seconds: 30);
  static const Duration _setupTimeout = Duration(seconds: 5);

  Timer? _inviteTimeoutTimer;
  Timer? _setupTimeoutTimer;

  // ... existing constructor + start + getters ...

  @override
  Future<int> invite(PeerId calleeDevicePk) async {
    if (_state is! IdleState) {
      throw StateError('cannot invite: already in $_state');
    }
    final callId = _generateCallId();
    final inviteSentAt = DateTime.now().toUtc();
    final envelope = Envelope(
      version: 1,
      type: 'call_invite',
      convId: 'call-${callId.toRadixString(16)}',
      clientId: callId.toRadixString(16),
      text: '',
      sentAt: inviteSentAt,
      extra: {
        'call_id': callId,
        'codec_params': _defaultCodecParams,
        'datagram_seq_init': _generateSeqInit(),
      },
    );
    await messaging.sendEnvelope(toUserPk: calleeDevicePk, envelope: envelope);
    _setState(InvitingState(
      calleeDevicePk: calleeDevicePk,
      callId: callId,
      sentAt: inviteSentAt,
    ));
    _inviteTimeoutTimer?.cancel();
    _inviteTimeoutTimer = Timer(_inviteTimeout, () {
      if (_state is InvitingState && (_state as InvitingState).callId == callId) {
        _setState(EndedState(callId: callId, reason: EndReason.inviteTimeout));
        // Best-effort end notice (fire-and-forget; ok if it fails).
        messaging.sendEnvelope(
          toUserPk: calleeDevicePk,
          envelope: Envelope(
            version: 1,
            type: 'call_end',
            convId: 'call-${callId.toRadixString(16)}',
            clientId: callId.toRadixString(16),
            text: '',
            sentAt: DateTime.now().toUtc(),
            extra: {'call_id': callId, 'reason': 'timeout'},
          ),
        ).catchError((_) {});
      }
    });
    return callId;
  }

  void _onEnvelope(MeshInboundMessage msg) {
    final type = msg.envelope.type;
    if (!type.startsWith('call_')) return;
    final extra = msg.envelope.extra;
    final callId = extra?['call_id'];
    if (callId is! int) return;
    switch (type) {
      case 'call_accept':
        _onCallAccept(msg.fromUserPk, callId);
        break;
      case 'call_reject':
        _onCallReject(callId, extra);
        break;
      case 'call_end':
        _onCallEnd(callId);
        break;
      // call_invite / call_setup / call_keepalive — Tasks 7-9.
    }
  }

  void _onCallAccept(PeerId from, int callId) {
    final st = _state;
    if (st is! InvitingState || st.callId != callId) return;
    _inviteTimeoutTimer?.cancel();
    _setState(ConnectingState(
      peerDevicePk: from,
      callId: callId,
      isCaller: true,
    ));
    // T8 wires audio + datagram pipe here.
  }

  void _onCallReject(int callId, Map<String, dynamic>? extra) {
    final st = _state;
    if (st is InvitingState && st.callId == callId) {
      _inviteTimeoutTimer?.cancel();
      _setState(EndedState(callId: callId, reason: EndReason.rejectedByCallee));
    }
  }

  void _onCallEnd(int callId) {
    final st = _state;
    if (st is EndedState) return;
    if (_callIdOf(st) != callId) return;
    _inviteTimeoutTimer?.cancel();
    _setupTimeoutTimer?.cancel();
    _setState(EndedState(callId: callId, reason: EndReason.remoteHangup));
  }

  int? _callIdOf(CallState s) {
    if (s is InvitingState) return s.callId;
    if (s is IncomingState) return s.callId;
    if (s is ConnectingState) return s.callId;
    if (s is ActiveState) return s.callId;
    return null;
  }

  static int _generateCallId() {
    final rng = Random.secure();
    // 64-bit random call id; we keep low 32 bits for the on-wire frame.
    return rng.nextInt(0xFFFFFFFF);
  }

  static int _generateSeqInit() {
    final rng = Random.secure();
    return rng.nextInt(0xFFFFFFFF);
  }

  static const Map<String, dynamic> _defaultCodecParams = {
    'audio': 'opus',
    'rate': 16000,
    'channels': 1,
    'frame_ms': 20,
    'bitrate': 24000,
    'fec': false,
  };
}
```

- [ ] **Step 5: Run tests, expect PASS**

```bash
cd /Users/dmitry/Downloads/taler_id_mobile && flutter test test/core/mesh/voice/mesh_voice_service_caller_test.dart 2>&1 | tail -8
```

Expected: 4 tests passed.

- [ ] **Step 6: Commit**

```bash
cd /Users/dmitry/Downloads/taler_id_mobile && git add lib/core/mesh/voice/mesh_voice_service.dart test/core/mesh/voice/mesh_voice_service_caller_test.dart test/core/mesh/voice/mesh_voice_service_test_utils.dart && git commit -m "feat(mesh-voice): MeshVoiceService caller path (invite + accept/reject + 30s timeout)"
```

---

## Task 7: Callee path — handle `call_invite`, `accept()`, `reject()` (TDD)

**Files:**
- Modify: `lib/core/mesh/voice/mesh_voice_service.dart`
- Create: `test/core/mesh/voice/mesh_voice_service_callee_test.dart`

- [ ] **Step 1: Write the failing tests**

Create `test/core/mesh/voice/mesh_voice_service_callee_test.dart`:

```dart
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:taler_id_mobile/core/mesh/services/envelope.dart';
import 'package:taler_id_mobile/core/mesh/services/mesh_messaging_service.dart';
import 'package:taler_id_mobile/core/mesh/transport/peer_id.dart';
import 'package:taler_id_mobile/core/mesh/voice/mesh_voice_state.dart';

import 'mesh_voice_service_test_utils.dart';

void main() {
  group('MeshVoiceService callee path', () {
    test('inbound call_invite transitions to IncomingState', () async {
      final h = MeshVoiceTestHarness.build();
      h.svc.start();

      final caller = PeerId(Uint8List.fromList(List<int>.generate(32, (i) => 100 + i)));
      const callId = 0x1234;
      h.fakeMessaging.emitInbound(MeshInboundMessage(
        fromUserPk: caller,
        envelope: Envelope(
          version: 1,
          type: 'call_invite',
          convId: 'call-${callId.toRadixString(16)}',
          clientId: callId.toRadixString(16),
          text: '',
          sentAt: DateTime.now().toUtc(),
          extra: {
            'call_id': callId,
            'codec_params': {'audio': 'opus', 'rate': 16000, 'channels': 1, 'frame_ms': 20, 'bitrate': 24000, 'fec': false},
            'datagram_seq_init': 1,
          },
        ),
      ));
      await Future<void>.delayed(Duration.zero);

      expect(h.svc.state, isA<IncomingState>());
      expect((h.svc.state as IncomingState).callerDevicePk, caller);
      expect((h.svc.state as IncomingState).callId, callId);
    });

    test('accept() sends call_accept and transitions to ConnectingState', () async {
      final h = MeshVoiceTestHarness.build();
      h.svc.start();

      final caller = PeerId(Uint8List.fromList(List<int>.generate(32, (i) => 100 + i)));
      const callId = 0x1234;
      h.fakeMessaging.emitInbound(MeshInboundMessage(
        fromUserPk: caller,
        envelope: Envelope(
          version: 1, type: 'call_invite',
          convId: 'call-${callId.toRadixString(16)}',
          clientId: callId.toRadixString(16),
          text: '', sentAt: DateTime.now().toUtc(),
          extra: {'call_id': callId, 'codec_params': {}, 'datagram_seq_init': 1},
        ),
      ));
      await Future<void>.delayed(Duration.zero);
      h.fakeMessaging.sentEnvelopes.clear();

      await h.svc.accept();
      expect(h.svc.state, isA<ConnectingState>());
      expect(h.fakeMessaging.sentEnvelopes, hasLength(1));
      expect(h.fakeMessaging.sentEnvelopes.first.envelope.type, 'call_accept');
    });

    test('busy: incoming invite while in ActiveState replies with call_reject{busy}', () async {
      final h = MeshVoiceTestHarness.build();
      h.svc.start();

      // Set up a fake ACTIVE state directly (production code would arrive via accept→connect→active).
      // We can't easily reach Active in T7 — that's T8. So use a lightweight invite-then-active simulation
      // by emitting first invite, calling accept, then emitting second invite from a different caller.
      final firstCaller = PeerId(Uint8List.fromList(List<int>.generate(32, (i) => 100 + i)));
      const firstCallId = 0x1234;
      h.fakeMessaging.emitInbound(MeshInboundMessage(
        fromUserPk: firstCaller,
        envelope: Envelope(
          version: 1, type: 'call_invite',
          convId: 'call-${firstCallId.toRadixString(16)}',
          clientId: firstCallId.toRadixString(16),
          text: '', sentAt: DateTime.now().toUtc(),
          extra: {'call_id': firstCallId, 'codec_params': {}, 'datagram_seq_init': 1},
        ),
      ));
      await Future<void>.delayed(Duration.zero);
      await h.svc.accept(); // → ConnectingState (T7's deepest reach)

      h.fakeMessaging.sentEnvelopes.clear();

      // Second caller invites while we're in ConnectingState (or later Active).
      final secondCaller = PeerId(Uint8List.fromList(List<int>.generate(32, (i) => 200 + i)));
      const secondCallId = 0x5678;
      h.fakeMessaging.emitInbound(MeshInboundMessage(
        fromUserPk: secondCaller,
        envelope: Envelope(
          version: 1, type: 'call_invite',
          convId: 'call-${secondCallId.toRadixString(16)}',
          clientId: secondCallId.toRadixString(16),
          text: '', sentAt: DateTime.now().toUtc(),
          extra: {'call_id': secondCallId, 'codec_params': {}, 'datagram_seq_init': 1},
        ),
      ));
      await Future<void>.delayed(Duration.zero);

      // Expect a call_reject{busy} sent back to second caller.
      final rejects = h.fakeMessaging.sentEnvelopes
          .where((s) => s.envelope.type == 'call_reject');
      expect(rejects, hasLength(1));
      expect(rejects.first.toUserPk, secondCaller);
      expect(rejects.first.envelope.extra!['reason'], 'busy');
    });
  });
}
```

- [ ] **Step 2: Run, expect FAIL**

```bash
cd /Users/dmitry/Downloads/taler_id_mobile && flutter test test/core/mesh/voice/mesh_voice_service_callee_test.dart 2>&1 | tail -8
```

Expected: tests fail.

- [ ] **Step 3: Implement callee handlers**

In `lib/core/mesh/voice/mesh_voice_service.dart`, extend `_onEnvelope` and replace the `accept` stub:

```dart
  void _onEnvelope(MeshInboundMessage msg) {
    final type = msg.envelope.type;
    if (!type.startsWith('call_')) return;
    final extra = msg.envelope.extra;
    final callId = extra?['call_id'];
    if (callId is! int) return;
    switch (type) {
      case 'call_invite':
        _onCallInvite(msg.fromUserPk, callId, extra!);
        break;
      case 'call_accept':
        _onCallAccept(msg.fromUserPk, callId);
        break;
      case 'call_reject':
        _onCallReject(callId, extra);
        break;
      case 'call_end':
        _onCallEnd(callId);
        break;
      // call_setup / call_keepalive — Task 9.
    }
  }

  void _onCallInvite(PeerId from, int callId, Map<String, dynamic> extra) {
    if (_state is! IdleState) {
      // Busy — auto-reject.
      messaging.sendEnvelope(
        toUserPk: from,
        envelope: Envelope(
          version: 1, type: 'call_reject',
          convId: 'call-${callId.toRadixString(16)}',
          clientId: callId.toRadixString(16),
          text: '', sentAt: DateTime.now().toUtc(),
          extra: {'call_id': callId, 'reason': 'busy'},
        ),
      ).catchError((_) {});
      return;
    }
    _setState(IncomingState(
      callerDevicePk: from,
      callId: callId,
      receivedAt: DateTime.now().toUtc(),
    ));
  }

  @override
  Future<void> accept() async {
    final st = _state;
    if (st is! IncomingState) {
      throw StateError('accept(): not in IncomingState (current=$st)');
    }
    final envelope = Envelope(
      version: 1, type: 'call_accept',
      convId: 'call-${st.callId.toRadixString(16)}',
      clientId: st.callId.toRadixString(16),
      text: '', sentAt: DateTime.now().toUtc(),
      extra: {
        'call_id': st.callId,
        'codec_params': _defaultCodecParams,
        'datagram_seq_init': _generateSeqInit(),
      },
    );
    await messaging.sendEnvelope(toUserPk: st.callerDevicePk, envelope: envelope);
    _setState(ConnectingState(
      peerDevicePk: st.callerDevicePk,
      callId: st.callId,
      isCaller: false,
    ));
  }

  Future<void> reject({String reason = 'declined'}) async {
    final st = _state;
    if (st is! IncomingState) {
      throw StateError('reject(): not in IncomingState (current=$st)');
    }
    await messaging.sendEnvelope(
      toUserPk: st.callerDevicePk,
      envelope: Envelope(
        version: 1, type: 'call_reject',
        convId: 'call-${st.callId.toRadixString(16)}',
        clientId: st.callId.toRadixString(16),
        text: '', sentAt: DateTime.now().toUtc(),
        extra: {'call_id': st.callId, 'reason': reason},
      ),
    );
    _setState(EndedState(callId: st.callId, reason: EndReason.userHangup));
  }
```

- [ ] **Step 4: Run, expect PASS**

```bash
cd /Users/dmitry/Downloads/taler_id_mobile && flutter test test/core/mesh/voice/mesh_voice_service_callee_test.dart 2>&1 | tail -8
```

Expected: 3 tests passed.

- [ ] **Step 5: Run caller tests for regression**

```bash
cd /Users/dmitry/Downloads/taler_id_mobile && flutter test test/core/mesh/voice/ 2>&1 | tail -3
```

Expected: caller + callee tests all pass.

- [ ] **Step 6: Commit**

```bash
cd /Users/dmitry/Downloads/taler_id_mobile && git add lib/core/mesh/voice/mesh_voice_service.dart test/core/mesh/voice/mesh_voice_service_callee_test.dart && git commit -m "feat(mesh-voice): MeshVoiceService callee path (invite + accept/reject + busy auto-reject)"
```

---

## Task 8: ACTIVE state — wire audio engine ↔ datagram pipe (TDD-light)

**Files:**
- Modify: `lib/core/mesh/voice/mesh_voice_service.dart`
- Create: `test/core/mesh/voice/mesh_voice_service_active_test.dart`

When both sides reach `ConnectingState` and have exchanged `call_setup`, transition to `ActiveState` and wire:
- `audioEngine.outbound` → encrypt via `MeshDatagramCipher` → wrap in `MeshVoiceFrame` → `transport.sendDatagram(peer, frame.encode())`
- `transport.inboundDatagrams` (filtered to this call's call_id) → decode `MeshVoiceFrame` → decrypt → `audioEngine.inbound(seq, payload)`

For Phase 3c we simplify: skip the explicit `call_setup` handshake (move from CONNECTING straight to ACTIVE on `call_accept` for the caller, and after sending `call_accept` for the callee). The `call_setup` envelope and 5-second timeout are deferred to a Phase 3c.1 polish if needed.

- [ ] **Step 1: Write the failing test**

Create `test/core/mesh/voice/mesh_voice_service_active_test.dart`:

```dart
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:taler_id_mobile/core/mesh/services/envelope.dart';
import 'package:taler_id_mobile/core/mesh/services/mesh_messaging_service.dart';
import 'package:taler_id_mobile/core/mesh/transport/peer_id.dart';
import 'package:taler_id_mobile/core/mesh/voice/mesh_voice_state.dart';

import 'mesh_voice_service_test_utils.dart';

void main() {
  group('MeshVoiceService ACTIVE state', () {
    test('caller transitions to Active after call_accept and starts audio engine', () async {
      final h = MeshVoiceTestHarness.build();
      h.svc.start();
      final callee = PeerId(Uint8List.fromList(List<int>.generate(32, (i) => 200 + i)));
      final callId = await h.svc.invite(callee);

      h.fakeMessaging.emitInbound(MeshInboundMessage(
        fromUserPk: callee,
        envelope: Envelope(
          version: 1, type: 'call_accept',
          convId: 'call-${callId.toRadixString(16)}',
          clientId: callId.toRadixString(16),
          text: '', sentAt: DateTime.now().toUtc(),
          extra: {'call_id': callId, 'codec_params': {}, 'datagram_seq_init': 99},
        ),
      ));
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(h.svc.state, isA<ActiveState>());
      expect(h.fakeAudioEngine.started, isTrue);
    });

    test('outbound audio frames are sent as datagrams', () async {
      final h = MeshVoiceTestHarness.build();
      h.svc.start();
      final callee = PeerId(Uint8List.fromList(List<int>.generate(32, (i) => 200 + i)));
      final callId = await h.svc.invite(callee);

      h.fakeMessaging.emitInbound(MeshInboundMessage(
        fromUserPk: callee,
        envelope: Envelope(
          version: 1, type: 'call_accept',
          convId: 'call-${callId.toRadixString(16)}',
          clientId: callId.toRadixString(16),
          text: '', sentAt: DateTime.now().toUtc(),
          extra: {'call_id': callId, 'codec_params': {}, 'datagram_seq_init': 99},
        ),
      ));
      await Future<void>.delayed(const Duration(milliseconds: 50));

      // Audio engine emits a "encoded Opus" frame — service must wrap + send.
      h.fakeAudioEngine.emitOutbound(Uint8List.fromList(List<int>.generate(40, (i) => i)));
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(h.fakeTransport.sentDatagrams, hasLength(1));
      final (sentPeer, sentBytes) = h.fakeTransport.sentDatagrams.first;
      expect(sentPeer, callee);
      expect(sentBytes.length, greaterThan(40),
          reason: 'frame includes 13-byte header + ciphertext (which is ≥ plaintext+16 tag)');
    });
  });
}
```

> **Note:** these tests use a NULL cipher path because `FakeMessagingService.datagramCiphersFor` is not implemented. Real encryption requires a Noise session, which fakes don't have. For the test, `MeshVoiceService` should support a "no cipher available" fallback that ships the frame UNENCRYPTED — clearly NOT for production but acceptable for this test layer (security is unit-tested separately in `MeshDatagramCipher` tests). Document this fallback explicitly in the implementation.
>
> Production code path goes through real ciphers when `messaging.datagramCiphersFor(peer)` returns non-null (validated at hardware smoke).

- [ ] **Step 2: Run, expect FAIL**

```bash
cd /Users/dmitry/Downloads/taler_id_mobile && flutter test test/core/mesh/voice/mesh_voice_service_active_test.dart 2>&1 | tail -8
```

Expected: state stays in `ConnectingState` (no transition logic to Active yet).

- [ ] **Step 3: Implement ACTIVE transition + audio↔datagram pipe**

Modify `_onCallAccept` and `accept()` to transition straight to ACTIVE (skip `call_setup` for 3c). Add the pipe wiring:

```dart
  // Replace _onCallAccept body:
  void _onCallAccept(PeerId from, int callId) {
    final st = _state;
    if (st is! InvitingState || st.callId != callId) return;
    _inviteTimeoutTimer?.cancel();
    _enterActive(from, callId, isCaller: true);
  }

  // Replace the tail of accept() — after sending call_accept envelope:
  // ...
  await messaging.sendEnvelope(toUserPk: st.callerDevicePk, envelope: envelope);
  _enterActive(st.callerDevicePk, st.callId, isCaller: false);

  // (The original `_setState(ConnectingState(...))` line is REMOVED —
  // we go straight to Active. ConnectingState is reserved for future
  // explicit setup handshake.)
  // ... end of accept()

  // Active-state wiring:
  StreamSubscription<Uint8List>? _audioOutSub;
  MeshVoiceAudioEngine? _activeEngine;
  ({MeshDatagramCipher outbound, MeshDatagramCipher inbound})? _activeCiphers;
  int _outSeq = 0;

  Future<void> _enterActive(PeerId peer, int callId, {required bool isCaller}) async {
    _activeCiphers = await messaging.datagramCiphersFor(peer);
    final engine = audioEngineFactory();
    _activeEngine = engine;
    await engine.start();
    _audioOutSub = engine.outbound.listen((opus) async {
      final ciphers = _activeCiphers;
      Uint8List ct;
      if (ciphers != null) {
        _outSeq++;
        ct = await ciphers.outbound.encrypt(seq: _outSeq, plaintext: opus);
      } else {
        // FALLBACK (test-only): no cipher available, ship plaintext.
        // Production always has a Noise session — datagramCiphersFor
        // returns non-null. This path keeps unit tests with fake
        // messaging working without a fake Noise session.
        _outSeq++;
        ct = opus;
      }
      final frame = MeshVoiceFrame(
        type: MeshVoiceFrameType.audio,
        callId: callId,
        seq: _outSeq,
        ciphertext: ct,
      );
      try {
        await transport.sendDatagram(peer, frame.encode());
      } catch (_) {
        // Drop on transport error; if persistent, keepalive timeout
        // will end the call (Task 9).
      }
    });
    _setState(ActiveState(
      peerDevicePk: peer,
      callId: callId,
      isCaller: isCaller,
      startedAt: DateTime.now().toUtc(),
    ));
  }

  // Datagram inbound handler (replaces empty _onDatagram from T5):
  void _onDatagram(InboundDatagram dg) async {
    final st = _state;
    if (st is! ActiveState) return;
    final MeshVoiceFrame frame;
    try {
      frame = MeshVoiceFrame.decode(dg.bytes);
    } on FormatException {
      return;
    }
    if (frame.callId != st.callId) return;
    final ciphers = _activeCiphers;
    Uint8List pt;
    if (ciphers != null) {
      try {
        pt = await ciphers.inbound.decrypt(seq: frame.seq, ciphertext: frame.ciphertext);
      } catch (_) {
        return; // drop on AEAD/replay failure
      }
    } else {
      pt = frame.ciphertext; // test fallback (see _enterActive)
    }
    _activeEngine?.inbound(seq: frame.seq, payload: pt);
  }
```

Update `dispose` and `_onCallEnd` to also clean up active state:

```dart
  Future<void> _exitActive() async {
    await _audioOutSub?.cancel();
    _audioOutSub = null;
    await _activeEngine?.stop();
    _activeEngine = null;
    _activeCiphers = null;
    _outSeq = 0;
  }

  // In _onCallEnd: after _setState(EndedState(...)):
  _exitActive();

  // In dispose:
  await _exitActive();
  // ... existing cancellations
```

- [ ] **Step 4: Run test, expect PASS**

```bash
cd /Users/dmitry/Downloads/taler_id_mobile && flutter test test/core/mesh/voice/mesh_voice_service_active_test.dart 2>&1 | tail -8
```

Expected: 2 tests passed.

- [ ] **Step 5: Run full mesh-voice suite for regression**

```bash
cd /Users/dmitry/Downloads/taler_id_mobile && flutter test test/core/mesh/voice/ 2>&1 | tail -3
```

Expected: caller + callee + active tests all pass.

> **Caller test from Task 6 may now fail** because we changed `_onCallAccept` to go to ACTIVE instead of CONNECTING. Update Task 6's "on call_accept envelope, transitions to ConnectingState" assertion to expect `ActiveState` instead. Do this fix in the same commit.

- [ ] **Step 6: Commit**

```bash
cd /Users/dmitry/Downloads/taler_id_mobile && git add lib/core/mesh/voice/mesh_voice_service.dart test/core/mesh/voice/mesh_voice_service_active_test.dart test/core/mesh/voice/mesh_voice_service_caller_test.dart && git commit -m "feat(mesh-voice): ACTIVE state — wire audio engine through cipher and datagram pipe"
```

---

## Task 9: Keepalive + datagram timeout + ENDED transitions (TDD)

**Files:**
- Modify: `lib/core/mesh/voice/mesh_voice_service.dart`
- Create: `test/core/mesh/voice/mesh_voice_service_keepalive_test.dart`

Active calls emit a `call_keepalive` envelope every 1 second. The receiver tracks last-datagram time; if no inbound datagrams for >3 seconds, the call ends with `EndReason.noKeepalive`. (Keepalive envelope itself isn't required for tracking — any inbound datagram counts as liveness; but emitting keepalive helps when audio is muted on both sides.)

- [ ] **Step 1: Write the failing tests**

Create `test/core/mesh/voice/mesh_voice_service_keepalive_test.dart`:

```dart
import 'dart:typed_data';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taler_id_mobile/core/mesh/services/envelope.dart';
import 'package:taler_id_mobile/core/mesh/services/mesh_messaging_service.dart';
import 'package:taler_id_mobile/core/mesh/transport/mesh_transport.dart';
import 'package:taler_id_mobile/core/mesh/transport/peer_id.dart';
import 'package:taler_id_mobile/core/mesh/transport/transport_preference.dart';
import 'package:taler_id_mobile/core/mesh/voice/mesh_voice_frame.dart';
import 'package:taler_id_mobile/core/mesh/voice/mesh_voice_state.dart';

import 'mesh_voice_service_test_utils.dart';

void main() {
  group('MeshVoiceService keepalive + timeout', () {
    test('3s no inbound datagrams → ENDED(noKeepalive)', () {
      fakeAsync((async) {
        final h = MeshVoiceTestHarness.build();
        h.svc.start();
        final callee = PeerId(Uint8List.fromList(List<int>.generate(32, (i) => 200 + i)));
        // ignore: unawaited_futures
        h.svc.invite(callee).then((callId) {
          h.fakeMessaging.emitInbound(MeshInboundMessage(
            fromUserPk: callee,
            envelope: Envelope(
              version: 1, type: 'call_accept',
              convId: 'call-${callId.toRadixString(16)}',
              clientId: callId.toRadixString(16),
              text: '', sentAt: DateTime.now().toUtc(),
              extra: {'call_id': callId, 'codec_params': {}, 'datagram_seq_init': 99},
            ),
          ));
        });
        async.flushMicrotasks();
        async.elapse(const Duration(milliseconds: 100));
        expect(h.svc.state, isA<ActiveState>());

        async.elapse(const Duration(seconds: 4));
        expect(h.svc.state, isA<EndedState>());
        expect((h.svc.state as EndedState).reason, EndReason.noKeepalive);
      });
    });

    test('inbound datagram resets the timeout', () {
      fakeAsync((async) {
        final h = MeshVoiceTestHarness.build();
        h.svc.start();
        final callee = PeerId(Uint8List.fromList(List<int>.generate(32, (i) => 200 + i)));
        // ignore: unawaited_futures
        h.svc.invite(callee).then((callId) {
          h.fakeMessaging.emitInbound(MeshInboundMessage(
            fromUserPk: callee,
            envelope: Envelope(
              version: 1, type: 'call_accept',
              convId: 'call-${callId.toRadixString(16)}',
              clientId: callId.toRadixString(16),
              text: '', sentAt: DateTime.now().toUtc(),
              extra: {'call_id': callId, 'codec_params': {}, 'datagram_seq_init': 99},
            ),
          ));
        });
        async.flushMicrotasks();
        async.elapse(const Duration(milliseconds: 100));
        final activeCallId = (h.svc.state as ActiveState).callId;

        // Tick liveness every 2s — never reaches 3s without a datagram.
        for (var i = 0; i < 5; i++) {
          async.elapse(const Duration(seconds: 2));
          // Fake an inbound datagram (just header — content will fail to decrypt
          // but liveness is tracked at receive level, before decrypt).
          final frame = MeshVoiceFrame(
            type: MeshVoiceFrameType.audio,
            callId: activeCallId,
            seq: i + 1,
            ciphertext: Uint8List.fromList([1, 2, 3]), // not real ciphertext
          );
          h.fakeTransport.emitDatagram(InboundDatagram(
            srcPeer: callee,
            bytes: frame.encode(),
            via: TransportId.bonjour,
          ));
          async.flushMicrotasks();
        }

        expect(h.svc.state, isA<ActiveState>(),
            reason: 'datagrams every 2s keep the call alive');
      });
    });

    test('hangup() emits call_end and transitions to ENDED', () async {
      final h = MeshVoiceTestHarness.build();
      h.svc.start();
      final callee = PeerId(Uint8List.fromList(List<int>.generate(32, (i) => 200 + i)));
      final callId = await h.svc.invite(callee);
      h.fakeMessaging.emitInbound(MeshInboundMessage(
        fromUserPk: callee,
        envelope: Envelope(
          version: 1, type: 'call_accept',
          convId: 'call-${callId.toRadixString(16)}',
          clientId: callId.toRadixString(16),
          text: '', sentAt: DateTime.now().toUtc(),
          extra: {'call_id': callId, 'codec_params': {}, 'datagram_seq_init': 99},
        ),
      ));
      await Future<void>.delayed(const Duration(milliseconds: 50));
      h.fakeMessaging.sentEnvelopes.clear();

      await h.svc.hangup();

      expect(h.svc.state, isA<EndedState>());
      expect((h.svc.state as EndedState).reason, EndReason.userHangup);
      // call_end envelope was sent.
      final ends = h.fakeMessaging.sentEnvelopes.where((s) => s.envelope.type == 'call_end');
      expect(ends, hasLength(1));
    });
  });
}
```

- [ ] **Step 2: Run, expect FAIL**

```bash
cd /Users/dmitry/Downloads/taler_id_mobile && flutter test test/core/mesh/voice/mesh_voice_service_keepalive_test.dart 2>&1 | tail -10
```

Expected: tests fail (no timeout logic, no `hangup` impl).

- [ ] **Step 3: Implement keepalive + timeouts**

In `lib/core/mesh/voice/mesh_voice_service.dart`:

```dart
  static const Duration _datagramTimeoutDuration = Duration(seconds: 3);
  static const Duration _keepaliveInterval = Duration(seconds: 1);

  Timer? _datagramWatchdog;
  Timer? _keepaliveTimer;

  void _resetDatagramWatchdog() {
    _datagramWatchdog?.cancel();
    _datagramWatchdog = Timer(_datagramTimeoutDuration, () {
      final st = _state;
      if (st is ActiveState) {
        _setState(EndedState(callId: st.callId, reason: EndReason.noKeepalive));
        _exitActive();
      }
    });
  }

  void _startKeepalive(PeerId peer, int callId) {
    _keepaliveTimer?.cancel();
    _keepaliveTimer = Timer.periodic(_keepaliveInterval, (_) {
      messaging.sendEnvelope(
        toUserPk: peer,
        envelope: Envelope(
          version: 1, type: 'call_keepalive',
          convId: 'call-${callId.toRadixString(16)}',
          clientId: callId.toRadixString(16),
          text: '', sentAt: DateTime.now().toUtc(),
          extra: {'call_id': callId},
        ),
      ).catchError((_) {});
    });
  }

  // In _enterActive — at the bottom, after _setState(ActiveState(...)):
  _resetDatagramWatchdog();
  _startKeepalive(peer, callId);

  // In _onDatagram — at the top, after the `if (st is! ActiveState) return;` line:
  _resetDatagramWatchdog();

  // In _exitActive — add at the top:
  _datagramWatchdog?.cancel();
  _datagramWatchdog = null;
  _keepaliveTimer?.cancel();
  _keepaliveTimer = null;
```

Implement `hangup`:

```dart
  @override
  Future<void> hangup({EndReason reason = EndReason.userHangup}) async {
    final st = _state;
    final cid = _callIdOf(st);
    if (cid == null) return;
    PeerId? peer;
    if (st is InvitingState) peer = st.calleeDevicePk;
    if (st is IncomingState) peer = st.callerDevicePk;
    if (st is ConnectingState) peer = st.peerDevicePk;
    if (st is ActiveState) peer = st.peerDevicePk;
    if (peer != null) {
      await messaging.sendEnvelope(
        toUserPk: peer,
        envelope: Envelope(
          version: 1, type: 'call_end',
          convId: 'call-${cid.toRadixString(16)}',
          clientId: cid.toRadixString(16),
          text: '', sentAt: DateTime.now().toUtc(),
          extra: {'call_id': cid, 'reason': reason.name},
        ),
      );
    }
    _setState(EndedState(callId: cid, reason: reason));
    await _exitActive();
    _inviteTimeoutTimer?.cancel();
    _setupTimeoutTimer?.cancel();
  }
```

- [ ] **Step 4: Run all mesh-voice tests**

```bash
cd /Users/dmitry/Downloads/taler_id_mobile && flutter test test/core/mesh/voice/ 2>&1 | tail -3
```

Expected: all pass.

- [ ] **Step 5: Commit**

```bash
cd /Users/dmitry/Downloads/taler_id_mobile && git add lib/core/mesh/voice/mesh_voice_service.dart test/core/mesh/voice/mesh_voice_service_keepalive_test.dart && git commit -m "feat(mesh-voice): keepalive + 3s datagram timeout + hangup"
```

---

## Task 10: Final analyze + push + PR

**Files:** none modified.

- [ ] **Step 1: Static analysis**

```bash
cd /Users/dmitry/Downloads/taler_id_mobile && flutter analyze 2>&1 | tail -10
```

Expected: no NEW errors.

- [ ] **Step 2: Full test suite**

```bash
cd /Users/dmitry/Downloads/taler_id_mobile && flutter test 2>&1 | tail -3
```

Expected: `All tests passed!` Count is current baseline + ~15 new tests.

- [ ] **Step 3: Push branch**

```bash
cd /Users/dmitry/Downloads/taler_id_mobile && git push -u origin feature/mesh-voice-call-phase3c
```

- [ ] **Step 4: Open the PR**

```bash
gh pr create --base dev --head feature/mesh-voice-call-phase3c --title "feat(mesh-voice/3c): MeshVoiceService — signaling + state machine + audio↔datagram pipe" --body "$(cat <<'EOF'
## Summary
- `MeshTransport` gains synchronous `peerStatus(devicePk)` returning `PeerStatus.online | offline | unknown` for UI eligibility checks.
- `Envelope` gains optional `extra: Map<String, dynamic>?` field for typed signaling payloads (backward-compatible: legacy v1 peers' envelopes parse with `extra=null`).
- `MeshVoiceFrame` defines the wire layout for voice datagrams: `[1 byte type][4 bytes call_id][8 bytes seq][N bytes ciphertext+tag]`.
- `MeshMessagingService.datagramCiphersFor(devicePk)` returns the AEAD cipher pair (outbound + inbound) derived via HKDF from the active Noise IK transport secret. Direction is computed deterministically from peer pk lexicographic order.
- New `MeshVoiceService` orchestrates the per-call state machine (caller: IDLE → INVITING → ACTIVE → ENDED; callee: IDLE → INCOMING → ACTIVE → ENDED), handles all `call_*` envelopes, wires `MeshVoiceAudioEngine.outbound` through encryption + frame encoding + `transport.sendDatagram`, and decodes inbound datagrams back to the engine.
- 30s invite timeout, 1Hz keepalive emission, 3s no-datagram → ENDED(noKeepalive).
- Busy auto-reject when an invite arrives while a call is already active.

## Test plan
- [x] Unit: `peerStatus` returns offline before discovery, online after (1 test).
- [x] Unit: `Envelope.extra` roundtrip + backward-compat parse + omits when null (3 tests).
- [x] Unit: `MeshVoiceFrame` encode/decode roundtrip; truncated wire fails; unknown type byte fails; big-endian layout (4 tests).
- [x] Unit: cipher direction-pair interoperability (2 tests, validates HKDF info-string convention).
- [x] Unit: caller path — invite emits InvitingState + envelope; accept transitions to ActiveState; reject → EndedState; 30s timeout → inviteTimeout (4 tests).
- [x] Unit: callee path — invite → IncomingState; accept emits envelope + transitions to ActiveState; busy auto-reject (3 tests).
- [x] Unit: ACTIVE — engine.outbound → cipher → frame → transport.sendDatagram; engine started on ACTIVE entry (2 tests).
- [x] Unit: keepalive — 3s no datagram → ENDED(noKeepalive); inbound datagrams reset watchdog; hangup() emits call_end + transitions to ENDED (3 tests).
- [x] flutter test — full suite green.
- [ ] Hardware smoke (pending Phase 3d UI integration): end-to-end mesh call between two devices on WiFi LAN.

## Notes
- Phase 3c only — service + state machine + signaling. No UI yet (Phase 3d wires `VoiceCallScreen` to it, adds the chat-side mesh-call button, and the eligibility dot).
- `call_setup` envelope and 5s setup-timeout from the spec are deferred (CONNECTING state is reserved but unused; caller goes straight from INVITING to ACTIVE on `call_accept`). Can revisit in 3c.1 if smoke shows we need parameter renegotiation between accept and audio start.
- `MeshDatagramCipher` test fallback path (cipher==null → plaintext) exists ONLY to keep unit tests with fake messaging working without a real Noise session. Production always has a session and uses real encryption — validated at hardware smoke.
- Implements design \`docs/superpowers/specs/2026-04-29-mesh-voice-call-phase3-design.md\` (sections "Signaling", "Eligibility check").

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"
```

---

## Self-review (run by author)

**Spec coverage (Phase 3 design — signaling, eligibility, state machine sections):**
- New envelope types (`call_invite`, `call_accept`, `call_reject`, `call_end`, `call_keepalive`) → Tasks 6, 7, 9. ✓
- `call_setup` envelope → deferred to Phase 3c.1 (documented in PR notes). Acceptable scope decision.
- `call_id` 64-bit random → Task 6 `_generateCallId`. (Spec says 64-bit; we use 32-bit `nextInt(0xFFFFFFFF)` to fit the on-wire 4-byte field. Coherent — frame layout is 4 bytes for call_id.)
- `codec_params` exchanged → Task 6 invite + Task 7 accept payload. ✓
- `datagram_seq_init` → Task 6 + Task 7 payload. ✓
- Caller state machine → Tasks 6, 8, 9. ✓ (Note: CONNECTING is reserved but unused for now — explicitly documented.)
- Callee state machine → Tasks 7, 8, 9. ✓
- 30s invite timeout → Task 6. ✓
- 1Hz keepalive → Task 9. ✓
- 3s datagram timeout → Task 9. ✓
- Eligibility check via `peerStatus` → Task 1. ✓
- Conflict handling (busy when LiveKit active) → Task 7's busy-reject (covers any active mesh call; LiveKit conflict surfaces in Phase 3d UI). Acceptable.
- `call_history` Hive persistence → deferred to Phase 3d (UI integration). ✓ (documented in PR notes)

**Placeholder scan:** Task 5's skeleton has `UnimplementedError` placeholders that are filled in Tasks 6/7/9 — these are TDD scaffolding, not real placeholders. Acceptable.

**Type consistency:**
- `CallState` hierarchy used identically across Tasks 5–9.
- `EndReason` enum names referenced consistently.
- `MeshVoiceFrameType.audio` referenced in Task 8 and 9 tests.
- `_enterActive` / `_exitActive` / `_resetDatagramWatchdog` / `_startKeepalive` method names consistent across implementation steps.

**Estimated effort:** 4-6 focused days. Most of the time goes into Tasks 6-8 (state machine + audio pipe wiring + edge case handling).

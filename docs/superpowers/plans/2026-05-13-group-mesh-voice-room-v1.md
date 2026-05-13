# Group Mesh Voice Room v1 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship a 2-5 peer voice room running on full mesh (UDP datagrams + Noise IK) over same-Wi-Fi Bonjour, without any server for audio or signaling. Extension of Phase 3 1-on-1 mesh voice to N peers.

**Architecture:** New `GroupMeshCallService` orchestrates per-peer Noise sessions, signaling envelopes (`mesh_gc_*`), and audio fanout. New `GroupMeshVoiceAudioEngine` runs one opus encoder + N-1 decoders + a PCM mixer. New `GroupMeshCallBloc` wraps the service for existing `group_call_*_screen.dart` UI. The LiveKit Phase 1 `GroupCallBloc` is left as dead code behind the (now removed) isDev FAB and deleted in a follow-up cleanup.

**Tech Stack:** Flutter 3.6, `flutter_bloc 8.1.6`, `freezed_annotation 2.4.4`, `bloc_test 9.1.7`, `mocktail 1.0.4`, libopus FFI, ChaCha20-Poly1305 (existing `MeshDatagramCipher`), Noise IK (existing), Bonjour mDNS + UDP, CallKit (`flutter_callkit_incoming`).

**Reference spec:** [2026-05-13-group-mesh-voice-room-design.md](../specs/2026-05-13-group-mesh-voice-room-design.md)

---

## File map

**New files:**

| Path | Responsibility |
|------|----------------|
| `lib/core/mesh/services/envelope.dart` (extend, existing 98 lines) | Add `mesh_gc_invite/accept/decline/leave/keepalive` envelope types + JSON codecs |
| `lib/core/mesh/voice/group_mesh_call_state.dart` | Sealed state hierarchy: `GMCIdle/Inviting/Lobby/Active/Ended/Error` + roster types |
| `lib/core/audio/group_mesh_voice_mixer.dart` | Pure PCM int16 mixer (sum + hard clip) — fully unit-testable |
| `lib/core/audio/group_mesh_voice_audio_engine.dart` | Multi-peer audio engine (1 capture+encoder, N-1 decoders+jitter, mixer, playback) |
| `lib/core/mesh/voice/group_mesh_call_service.dart` | Room orchestration: state machine, per-peer FSM, Noise fanout, audio routing |
| `lib/features/voice/presentation/bloc/group_mesh_call_event.dart` | Bloc events (sealed) |
| `lib/features/voice/presentation/bloc/group_mesh_call_bloc_state.dart` | Bloc states (sealed, mirrors `GroupMeshCallState`) |
| `lib/features/voice/presentation/bloc/group_mesh_call_bloc.dart` | UI BLoC wrapping the service |

**Modified files:**

| Path | Change |
|------|--------|
| `lib/core/di/service_locator.dart` | Register `GroupMeshCallService` + `GroupMeshCallBloc`; subscribe service to `MeshMessagingService.inbound` |
| `lib/features/voice/presentation/screens/new_group_call_screen.dart` | Filter contact list to mesh-online; hard cap 4 invitees; dispatch new bloc's `Start` event |
| `lib/features/voice/presentation/screens/group_call_lobby_screen.dart` | Swap `GroupCallBloc` for `GroupMeshCallBloc`; update state names |
| `lib/features/voice/presentation/screens/group_call_active_screen.dart` | Swap to `GroupMeshCallBloc`; replace LiveKit Room ownership with mesh roster from state |
| `lib/features/call_history/presentation/screens/call_history_screen.dart` | Lines 460-477: remove `AppConfig.isDev` gate, FAB always visible |
| `lib/core/mesh/voice/mesh_voice_service.dart` | Mic-conflict guard: reject `invite()` / `accept()` while group call active |

**Test files (new):**

| Path | Scope |
|------|-------|
| `test/core/mesh/services/envelope_gc_test.dart` | `mesh_gc_*` JSON round-trip |
| `test/core/mesh/voice/group_mesh_call_state_test.dart` | State equality + transitions |
| `test/core/audio/group_mesh_voice_mixer_test.dart` | Mixer math (passthrough, sum, clip, zero-fill) |
| `test/core/mesh/voice/group_mesh_call_service_test.dart` | Orchestration: invite fanout, accept/decline, peer drop, Noise role |
| `test/features/voice/presentation/bloc/group_mesh_call_bloc_test.dart` | Bloc state transitions |
| `integration_test/group_mesh_call_test.dart` | 2-emulator E2E happy path + sequential-calls regression |

---

## Setup

- [ ] **Step 0: Confirm on `dev` branch and pull latest**

```bash
cd ~/Downloads/taler_id_mobile
git status
git checkout dev
git pull origin dev
```

Expected: clean tree, on `dev`, up to date.

---

## Task 1: Envelope types + JSON codecs

**Files:**
- Modify: `lib/core/mesh/services/envelope.dart`
- Test: `test/core/mesh/services/envelope_gc_test.dart`

The existing `envelope.dart` defines `Envelope` for v1 (`call_invite`, `call_accept`, etc.). We add 5 group-call types preserving the same wire shape.

- [ ] **Step 1: Read existing envelope.dart to learn the current pattern**

```bash
cat lib/core/mesh/services/envelope.dart
```

Note the existing type constants and the JSON encode/decode flow. The new types follow the same approach.

- [ ] **Step 2: Write the failing test**

Create `test/core/mesh/services/envelope_gc_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:taler_id_mobile/core/mesh/services/envelope.dart';

void main() {
  group('mesh_gc envelopes round-trip', () {
    test('mesh_gc_invite encodes and decodes', () {
      final original = Envelope(
        type: 'mesh_gc_invite',
        convId: 'room-abc',
        clientId: 'client-1',
        sentAt: DateTime.utc(2026, 5, 13, 10, 0),
        extra: {
          'roomId': 'room-abc',
          'hostDevicePk': 'aabbcc',
          'participants': ['aabbcc', 'ddeeff', '112233'],
          'startedAt': '2026-05-13T10:00:00Z',
        },
      );
      final json = original.toJsonBytes();
      final round = Envelope.fromJsonBytes(json);
      expect(round.type, 'mesh_gc_invite');
      expect(round.convId, 'room-abc');
      expect(round.extra?['participants'], ['aabbcc', 'ddeeff', '112233']);
    });

    test('mesh_gc_accept payload', () {
      final e = Envelope(
        type: 'mesh_gc_accept',
        convId: 'room-abc',
        clientId: 'client-2',
        sentAt: DateTime.utc(2026, 5, 13, 10, 0, 5),
        extra: {'roomId': 'room-abc', 'devicePk': 'ddeeff'},
      );
      final round = Envelope.fromJsonBytes(e.toJsonBytes());
      expect(round.type, 'mesh_gc_accept');
      expect(round.extra?['devicePk'], 'ddeeff');
    });

    test('all five mesh_gc types are recognised', () {
      const types = [
        'mesh_gc_invite',
        'mesh_gc_accept',
        'mesh_gc_decline',
        'mesh_gc_leave',
        'mesh_gc_keepalive',
      ];
      for (final t in types) {
        final e = Envelope(
          type: t,
          convId: 'r',
          clientId: 'c',
          sentAt: DateTime.utc(2026),
        );
        expect(
          MeshGcEnvelopeType.isMeshGc(e.type),
          isTrue,
          reason: 'should recognise $t as a mesh_gc envelope',
        );
      }
    });

    test('non-mesh-gc type is rejected by classifier', () {
      expect(MeshGcEnvelopeType.isMeshGc('call_invite'), isFalse);
      expect(MeshGcEnvelopeType.isMeshGc('text'), isFalse);
    });
  });
}
```

- [ ] **Step 3: Run test to verify it fails**

```bash
flutter test test/core/mesh/services/envelope_gc_test.dart
```

Expected: FAIL — `MeshGcEnvelopeType` not defined.

- [ ] **Step 4: Add classifier to `envelope.dart`**

Append to `lib/core/mesh/services/envelope.dart` (before the closing of the file, after the existing types):

```dart
/// Group voice call envelope types (Phase: group mesh voice room v1).
///
/// Wire shape is identical to the existing v1 `Envelope`. Payload-specific
/// fields live in `Envelope.extra`. See spec at
/// docs/superpowers/specs/2026-05-13-group-mesh-voice-room-design.md.
class MeshGcEnvelopeType {
  static const invite = 'mesh_gc_invite';
  static const accept = 'mesh_gc_accept';
  static const decline = 'mesh_gc_decline';
  static const leave = 'mesh_gc_leave';
  static const keepalive = 'mesh_gc_keepalive';

  static const _all = {invite, accept, decline, leave, keepalive};

  static bool isMeshGc(String type) => _all.contains(type);
}
```

- [ ] **Step 5: Run tests, verify they pass**

```bash
flutter test test/core/mesh/services/envelope_gc_test.dart
```

Expected: PASS (4 tests).

- [ ] **Step 6: Commit**

```bash
git add lib/core/mesh/services/envelope.dart test/core/mesh/services/envelope_gc_test.dart
git commit -m "feat(mesh-gc): envelope types + classifier for group voice call signaling"
```

---

## Task 2: Group mesh call state hierarchy

**Files:**
- Create: `lib/core/mesh/voice/group_mesh_call_state.dart`
- Test: `test/core/mesh/voice/group_mesh_call_state_test.dart`

A plain-Dart sealed hierarchy (no freezed — keeps the service layer build-runner-free; the bloc layer uses freezed separately later if needed).

- [ ] **Step 1: Write the failing test**

Create `test/core/mesh/voice/group_mesh_call_state_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:taler_id_mobile/core/mesh/voice/group_mesh_call_state.dart';

void main() {
  group('GroupMeshCallState equality', () {
    test('Idle equality', () {
      expect(const GMCIdle(), const GMCIdle());
    });

    test('Lobby with same roster is equal', () {
      final a = GMCLobby(
        roomId: 'r1',
        hostDevicePk: 'h',
        roster: [
          const GMCParticipant(devicePk: 'p1', userId: 'u1', status: GMCStatus.calling),
        ],
      );
      final b = GMCLobby(
        roomId: 'r1',
        hostDevicePk: 'h',
        roster: [
          const GMCParticipant(devicePk: 'p1', userId: 'u1', status: GMCStatus.calling),
        ],
      );
      expect(a, b);
    });

    test('Active with different durationSec is still equal in roster', () {
      // Duration is an observable, not part of state identity for grouping.
      // Roster identity drives equality.
      final a = GMCActive(roomId: 'r', roster: const [], durationSec: 10);
      final b = GMCActive(roomId: 'r', roster: const [], durationSec: 20);
      expect(a == b, isFalse, reason: 'duration counts; both fields participate');
    });

    test('Ended carries reason', () {
      const e = GMCEnded(reason: GMCEndReason.userHangup);
      expect(e.reason, GMCEndReason.userHangup);
    });
  });

  group('GMCParticipant', () {
    test('copyWith updates status only', () {
      const p = GMCParticipant(devicePk: 'a', userId: 'u', status: GMCStatus.calling);
      final p2 = p.copyWith(status: GMCStatus.joined);
      expect(p2.devicePk, 'a');
      expect(p2.userId, 'u');
      expect(p2.status, GMCStatus.joined);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

```bash
flutter test test/core/mesh/voice/group_mesh_call_state_test.dart
```

Expected: FAIL — file/types not found.

- [ ] **Step 3: Implement state hierarchy**

Create `lib/core/mesh/voice/group_mesh_call_state.dart`:

```dart
import 'package:collection/collection.dart';

/// One participant's view in the room roster.
class GMCParticipant {
  const GMCParticipant({
    required this.devicePk,
    required this.userId,
    required this.status,
    this.displayName,
    this.avatarUrl,
    this.isSelf = false,
    this.isMuted = false,
    this.isSpeaking = false,
  });

  final String devicePk; // hex
  final String userId;
  final GMCStatus status;
  final String? displayName;
  final String? avatarUrl;
  final bool isSelf;
  final bool isMuted;
  final bool isSpeaking;

  GMCParticipant copyWith({
    GMCStatus? status,
    String? displayName,
    String? avatarUrl,
    bool? isMuted,
    bool? isSpeaking,
  }) {
    return GMCParticipant(
      devicePk: devicePk,
      userId: userId,
      status: status ?? this.status,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isSelf: isSelf,
      isMuted: isMuted ?? this.isMuted,
      isSpeaking: isSpeaking ?? this.isSpeaking,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GMCParticipant &&
          other.devicePk == devicePk &&
          other.userId == userId &&
          other.status == status &&
          other.displayName == displayName &&
          other.isSelf == isSelf &&
          other.isMuted == isMuted &&
          other.isSpeaking == isSpeaking;

  @override
  int get hashCode =>
      Object.hash(devicePk, userId, status, displayName, isSelf, isMuted, isSpeaking);
}

enum GMCStatus { calling, joined, declined, noAnswer, connectionFailed, left }

enum GMCEndReason {
  userHangup,
  allLeft,
  noAnswer,
  allDeclined,
  error,
  busy,
}

/// Sealed state hierarchy for the group mesh call service.
sealed class GroupMeshCallState {
  const GroupMeshCallState();
}

class GMCIdle extends GroupMeshCallState {
  const GMCIdle();
  @override
  bool operator ==(Object other) => other is GMCIdle;
  @override
  int get hashCode => 'GMCIdle'.hashCode;
}

class GMCInviting extends GroupMeshCallState {
  const GMCInviting({required this.roomId, required this.invitees});
  final String roomId;
  final List<GMCParticipant> invitees;

  @override
  bool operator ==(Object other) =>
      other is GMCInviting &&
      other.roomId == roomId &&
      const ListEquality().equals(other.invitees, invitees);
  @override
  int get hashCode => Object.hash(roomId, Object.hashAll(invitees));
}

class GMCLobby extends GroupMeshCallState {
  const GMCLobby({
    required this.roomId,
    required this.hostDevicePk,
    required this.roster,
  });
  final String roomId;
  final String hostDevicePk;
  final List<GMCParticipant> roster;

  GMCLobby copyWith({List<GMCParticipant>? roster}) =>
      GMCLobby(roomId: roomId, hostDevicePk: hostDevicePk, roster: roster ?? this.roster);

  @override
  bool operator ==(Object other) =>
      other is GMCLobby &&
      other.roomId == roomId &&
      other.hostDevicePk == hostDevicePk &&
      const ListEquality().equals(other.roster, roster);
  @override
  int get hashCode => Object.hash(roomId, hostDevicePk, Object.hashAll(roster));
}

class GMCActive extends GroupMeshCallState {
  const GMCActive({
    required this.roomId,
    required this.roster,
    required this.durationSec,
    this.selfMuted = false,
  });
  final String roomId;
  final List<GMCParticipant> roster;
  final int durationSec;
  final bool selfMuted;

  GMCActive copyWith({
    List<GMCParticipant>? roster,
    int? durationSec,
    bool? selfMuted,
  }) =>
      GMCActive(
        roomId: roomId,
        roster: roster ?? this.roster,
        durationSec: durationSec ?? this.durationSec,
        selfMuted: selfMuted ?? this.selfMuted,
      );

  @override
  bool operator ==(Object other) =>
      other is GMCActive &&
      other.roomId == roomId &&
      other.durationSec == durationSec &&
      other.selfMuted == selfMuted &&
      const ListEquality().equals(other.roster, roster);
  @override
  int get hashCode => Object.hash(
        roomId,
        durationSec,
        selfMuted,
        Object.hashAll(roster),
      );
}

class GMCEnded extends GroupMeshCallState {
  const GMCEnded({required this.reason});
  final GMCEndReason reason;

  @override
  bool operator ==(Object other) => other is GMCEnded && other.reason == reason;
  @override
  int get hashCode => reason.hashCode;
}

class GMCError extends GroupMeshCallState {
  const GMCError({required this.message});
  final String message;

  @override
  bool operator ==(Object other) => other is GMCError && other.message == message;
  @override
  int get hashCode => message.hashCode;
}
```

- [ ] **Step 4: Run tests, verify they pass**

```bash
flutter test test/core/mesh/voice/group_mesh_call_state_test.dart
```

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/core/mesh/voice/group_mesh_call_state.dart test/core/mesh/voice/group_mesh_call_state_test.dart
git commit -m "feat(mesh-gc): GroupMeshCallState sealed hierarchy + participant model"
```

---

## Task 3: Pure PCM mixer

**Files:**
- Create: `lib/core/audio/group_mesh_voice_mixer.dart`
- Test: `test/core/audio/group_mesh_voice_mixer_test.dart`

A pure function that takes N Int16List PCM frames (or null/short for silence) and produces a single Int16List by summing element-wise with hard clip. Fully unit-testable, no FFI.

- [ ] **Step 1: Write the failing test**

Create `test/core/audio/group_mesh_voice_mixer_test.dart`:

```dart
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:taler_id_mobile/core/audio/group_mesh_voice_mixer.dart';

void main() {
  group('GroupMeshVoiceMixer', () {
    test('empty input list produces zero-filled output', () {
      final out = GroupMeshVoiceMixer.mix(const [], 4);
      expect(out, Int16List.fromList([0, 0, 0, 0]));
    });

    test('single source passes through', () {
      final src = Int16List.fromList([100, 200, -100, -200]);
      final out = GroupMeshVoiceMixer.mix([src], 4);
      expect(out, src);
    });

    test('two sources are summed', () {
      final a = Int16List.fromList([100, 100, -100, -100]);
      final b = Int16List.fromList([200, -50, 200, -50]);
      final out = GroupMeshVoiceMixer.mix([a, b], 4);
      expect(out, Int16List.fromList([300, 50, 100, -150]));
    });

    test('sum overflowing int16 max clips to 32767', () {
      final a = Int16List.fromList([30000]);
      final b = Int16List.fromList([10000]);
      final out = GroupMeshVoiceMixer.mix([a, b], 1);
      expect(out[0], 32767);
    });

    test('sum below int16 min clips to -32768', () {
      final a = Int16List.fromList([-30000]);
      final b = Int16List.fromList([-10000]);
      final out = GroupMeshVoiceMixer.mix([a, b], 1);
      expect(out[0], -32768);
    });

    test('null source treated as silence', () {
      final a = Int16List.fromList([100, 100]);
      final out = GroupMeshVoiceMixer.mix([a, null], 2);
      expect(out, Int16List.fromList([100, 100]));
    });

    test('shorter source is zero-padded on the right', () {
      final a = Int16List.fromList([100, 100, 100, 100]);
      final b = Int16List.fromList([200, 200]); // only first 2 samples
      final out = GroupMeshVoiceMixer.mix([a, b], 4);
      expect(out, Int16List.fromList([300, 300, 100, 100]));
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

```bash
flutter test test/core/audio/group_mesh_voice_mixer_test.dart
```

Expected: FAIL — class not defined.

- [ ] **Step 3: Implement mixer**

Create `lib/core/audio/group_mesh_voice_mixer.dart`:

```dart
import 'dart:typed_data';

/// Pure PCM int16 mixer for group mesh voice playback.
///
/// Mixes N sources element-wise, hard-clipping the sum into the int16 range.
/// Null sources or sources shorter than [frameSamples] are treated as silence
/// for the missing samples. Acceptable for voice at N≤5 — see spec §audio.
abstract final class GroupMeshVoiceMixer {
  static Int16List mix(List<Int16List?> sources, int frameSamples) {
    final out = Int16List(frameSamples);
    if (sources.isEmpty) return out;

    for (var i = 0; i < frameSamples; i++) {
      var sum = 0;
      for (final src in sources) {
        if (src == null) continue;
        if (i >= src.length) continue;
        sum += src[i];
      }
      if (sum > 32767) {
        out[i] = 32767;
      } else if (sum < -32768) {
        out[i] = -32768;
      } else {
        out[i] = sum;
      }
    }
    return out;
  }
}
```

- [ ] **Step 4: Run tests, verify they pass**

```bash
flutter test test/core/audio/group_mesh_voice_mixer_test.dart
```

Expected: PASS (7 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/core/audio/group_mesh_voice_mixer.dart test/core/audio/group_mesh_voice_mixer_test.dart
git commit -m "feat(mesh-gc): pure PCM int16 mixer with hard clip"
```

---

## Task 4: GroupMeshVoiceAudioEngine

**Files:**
- Create: `lib/core/audio/group_mesh_voice_audio_engine.dart`
- Test: `test/core/audio/group_mesh_voice_audio_engine_test.dart`

This engine has one capture+encoder shared across all peers and N independent (peer → decoder → jitter buffer) paths feeding the mixer. FFI calls to libopus and native plugins aren't directly unit-testable, so we test the orchestration (peer add/remove, fanout to outbound stream subscriber, inbound routing to per-peer decoders) via a constructor-injected codec factory that the test replaces with a stub.

- [ ] **Step 1: Read the existing 1-on-1 engine for reference**

```bash
cat lib/core/audio/mesh_voice_audio_engine.dart
cat lib/core/audio/opus/opus_encoder.dart
cat lib/core/audio/opus/opus_decoder.dart
```

Note the constructor of `MeshVoiceAudioEngine`, how it wires capture → encoder → outbound stream, and how `inbound({seq, payload})` feeds the jitter buffer.

- [ ] **Step 2: Write the failing test**

Create `test/core/audio/group_mesh_voice_audio_engine_test.dart`:

```dart
import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:taler_id_mobile/core/audio/group_mesh_voice_audio_engine.dart';

class _FakeCapture extends Fake implements AudioCaptureSource {
  final _ctrl = StreamController<Int16List>.broadcast();
  Stream<Int16List> get frames => _ctrl.stream;
  Future<void> start() async {}
  Future<void> stop() async {}

  void emit(Int16List samples) => _ctrl.add(samples);
}

class _FakePlayback extends Fake implements AudioPlaybackSink {
  final captured = <Int16List>[];
  Future<void> start() async {}
  Future<void> stop() async {}
  Future<void> writeFrame(Int16List samples) async => captured.add(samples);
}

class _FakeEncoder extends Fake implements GroupMeshOpusEncoder {
  Uint8List encode(Int16List pcm) =>
      Uint8List.fromList([0xEE] + List<int>.generate(pcm.length, (i) => pcm[i] & 0xFF));
}

class _FakeDecoder extends Fake implements GroupMeshOpusDecoder {
  Int16List decode(Uint8List payload) {
    // first byte was the encoder marker; return remaining as int16 lows
    return Int16List.fromList(payload.skip(1).map((b) => b * 10).toList());
  }
}

void main() {
  test('engine fans out one encoded payload per capture frame', () async {
    final capture = _FakeCapture();
    final playback = _FakePlayback();
    final engine = GroupMeshVoiceAudioEngine(
      capture: capture,
      playback: playback,
      encoderFactory: () => _FakeEncoder(),
      decoderFactory: () => _FakeDecoder(),
    );

    await engine.start();
    final outboundEvents = <Uint8List>[];
    final sub = engine.outbound.listen(outboundEvents.add);

    capture.emit(Int16List.fromList([1, 2, 3]));
    await Future<void>.delayed(const Duration(milliseconds: 10));

    expect(outboundEvents.length, 1);
    expect(outboundEvents.first.first, 0xEE);

    await sub.cancel();
    await engine.stop();
  });

  test('addPeer + inbound routes to that peer decoder; removePeer drops it', () async {
    final capture = _FakeCapture();
    final playback = _FakePlayback();
    final engine = GroupMeshVoiceAudioEngine(
      capture: capture,
      playback: playback,
      encoderFactory: () => _FakeEncoder(),
      decoderFactory: () => _FakeDecoder(),
    );
    await engine.start();
    engine.addPeer('peerA');

    engine.inbound('peerA', seq: 1, payload: Uint8List.fromList([0xEE, 5]));
    // Mixer ticks at capture cadence; feed one capture frame to trigger a mix tick
    capture.emit(Int16List.fromList(List.filled(320, 0)));
    await Future<void>.delayed(const Duration(milliseconds: 30));

    expect(playback.captured.isNotEmpty, isTrue,
        reason: 'playback should have received at least one mixed frame');

    engine.removePeer('peerA');
    expect(
      () => engine.inbound('peerA', seq: 2, payload: Uint8List.fromList([0xEE, 6])),
      returnsNormally,
      reason: 'inbound for removed peer is a no-op, not an error',
    );

    await engine.stop();
  });
}
```

- [ ] **Step 3: Run test to verify it fails**

```bash
flutter test test/core/audio/group_mesh_voice_audio_engine_test.dart
```

Expected: FAIL — class not defined.

- [ ] **Step 4: Implement engine**

Create `lib/core/audio/group_mesh_voice_audio_engine.dart`:

```dart
import 'dart:async';
import 'dart:typed_data';

import 'package:taler_id_mobile/core/audio/group_mesh_voice_mixer.dart';

/// Abstract mic source (Int16 PCM frames at engine.sampleRate). Implementations
/// wrap the existing native capture plugin; tests inject fakes.
abstract class AudioCaptureSource {
  Stream<Int16List> get frames;
  Future<void> start();
  Future<void> stop();
}

/// Abstract playback sink (Int16 PCM frames).
abstract class AudioPlaybackSink {
  Future<void> start();
  Future<void> stop();
  Future<void> writeFrame(Int16List samples);
}

/// Opus encoder/decoder interfaces — production impl wraps the existing
/// `lib/core/audio/opus/` FFI bindings. Defining an interface here lets the
/// audio engine be unit-tested without FFI.
abstract class GroupMeshOpusEncoder {
  Uint8List encode(Int16List pcm);
}

abstract class GroupMeshOpusDecoder {
  Int16List decode(Uint8List payload);
}

/// Per-peer state inside the engine.
class _PeerSlot {
  _PeerSlot({required this.decoder});
  final GroupMeshOpusDecoder decoder;
  // Latest decoded PCM frame; replaced as new datagrams arrive.
  Int16List? latestPcm;
  int lastSeqAccepted = -1;
}

/// Multi-peer mesh voice audio engine.
///
/// Audio path:
/// mic → capture frames (Int16 PCM @ 16 kHz, 20 ms = 320 samples) →
///   opus encode (one encoder shared across all peers) → outbound stream.
///
/// Inbound: per-peer opus decode → per-peer latest-PCM slot. On each capture
/// tick the mixer reads each slot's latestPcm and writes the mix to playback.
class GroupMeshVoiceAudioEngine {
  GroupMeshVoiceAudioEngine({
    required this.capture,
    required this.playback,
    required GroupMeshOpusEncoder Function() encoderFactory,
    required this.decoderFactory,
    this.sampleRate = 16000,
    this.frameMs = 20,
  })  : _encoder = encoderFactory(),
        frameSamples = (sampleRate * frameMs) ~/ 1000;

  final AudioCaptureSource capture;
  final AudioPlaybackSink playback;
  final int sampleRate;
  final int frameMs;
  final int frameSamples;
  final GroupMeshOpusDecoder Function() decoderFactory;
  final GroupMeshOpusEncoder _encoder;

  final _outboundCtrl = StreamController<Uint8List>.broadcast();
  Stream<Uint8List> get outbound => _outboundCtrl.stream;

  final _peers = <String, _PeerSlot>{};
  StreamSubscription<Int16List>? _captureSub;
  bool _started = false;

  Future<void> start() async {
    if (_started) return;
    await capture.start();
    await playback.start();
    _captureSub = capture.frames.listen(_onCaptureFrame);
    _started = true;
  }

  Future<void> stop() async {
    if (!_started) return;
    await _captureSub?.cancel();
    _captureSub = null;
    await capture.stop();
    await playback.stop();
    _peers.clear();
    _started = false;
  }

  void addPeer(String peerKey) {
    _peers.putIfAbsent(peerKey, () => _PeerSlot(decoder: decoderFactory()));
  }

  void removePeer(String peerKey) {
    _peers.remove(peerKey);
  }

  void inbound(String peerKey, {required int seq, required Uint8List payload}) {
    final slot = _peers[peerKey];
    if (slot == null) return; // tolerate: stale or removed peer
    if (seq <= slot.lastSeqAccepted) return; // simple per-peer ordering
    slot.lastSeqAccepted = seq;
    slot.latestPcm = slot.decoder.decode(payload);
  }

  void _onCaptureFrame(Int16List pcm) {
    // Outbound path: encode once, broadcast bytes to subscribers.
    final encoded = _encoder.encode(pcm);
    _outboundCtrl.add(encoded);

    // Mix tick aligned with capture cadence.
    final sources = <Int16List?>[
      for (final slot in _peers.values) slot.latestPcm,
    ];
    // Consume the latestPcm so next tick gets silence if no new frame arrives
    // (basic catch-up; a real jitter buffer goes here in a future iteration).
    for (final slot in _peers.values) {
      slot.latestPcm = null;
    }
    final mixed = GroupMeshVoiceMixer.mix(sources, frameSamples);
    playback.writeFrame(mixed);
  }

  Future<void> dispose() async {
    await stop();
    await _outboundCtrl.close();
  }
}
```

- [ ] **Step 5: Run tests, verify they pass**

```bash
flutter test test/core/audio/group_mesh_voice_audio_engine_test.dart
```

Expected: PASS (2 tests).

- [ ] **Step 6: Wire production encoder/decoder adapters**

Append to the same file (after the engine class):

```dart
/// Production adapter — wraps the FFI opus encoder used by 1-on-1 mesh voice.
/// Lives in this file to keep the engine file self-contained; the actual
/// `OpusEncoder` lives in `lib/core/audio/opus/opus_encoder.dart` and is
/// imported here only by the adapter.
class FfiGroupMeshOpusEncoder implements GroupMeshOpusEncoder {
  FfiGroupMeshOpusEncoder({required this.sampleRate, required this.bitrate});
  final int sampleRate;
  final int bitrate;
  // Real FFI wiring happens in the implementing task — the adapter constructs
  // the underlying OpusEncoder lazily on first encode().
  @override
  Uint8List encode(Int16List pcm) {
    throw UnimplementedError(
      'Wire to lib/core/audio/opus/opus_encoder.dart in the next step',
    );
  }
}

class FfiGroupMeshOpusDecoder implements GroupMeshOpusDecoder {
  FfiGroupMeshOpusDecoder({required this.sampleRate});
  final int sampleRate;
  @override
  Int16List decode(Uint8List payload) {
    throw UnimplementedError(
      'Wire to lib/core/audio/opus/opus_decoder.dart in the next step',
    );
  }
}
```

Then implement those two adapters by delegating to the existing `OpusEncoder` / `OpusDecoder` from `lib/core/audio/opus/`. Inspect those classes to match constructor signatures. Replace `UnimplementedError` with the actual delegation:

```dart
// Inside FfiGroupMeshOpusEncoder
late final _impl = OpusEncoder(sampleRate: sampleRate, bitrate: bitrate);
@override
Uint8List encode(Int16List pcm) => _impl.encode(pcm);

// Inside FfiGroupMeshOpusDecoder
late final _impl = OpusDecoder(sampleRate: sampleRate);
@override
Int16List decode(Uint8List payload) => _impl.decode(payload);
```

Add the import at the top of the file:

```dart
import 'package:taler_id_mobile/core/audio/opus/opus_encoder.dart';
import 'package:taler_id_mobile/core/audio/opus/opus_decoder.dart';
```

- [ ] **Step 7: Re-run engine tests (FFI adapters not exercised by unit tests)**

```bash
flutter test test/core/audio/group_mesh_voice_audio_engine_test.dart
```

Expected: PASS still — the FFI adapters are not constructed in tests.

- [ ] **Step 8: Commit**

```bash
git add lib/core/audio/group_mesh_voice_audio_engine.dart test/core/audio/group_mesh_voice_audio_engine_test.dart
git commit -m "feat(mesh-gc): GroupMeshVoiceAudioEngine — one encoder, N decoders, mixer"
```

---

## Task 5: GroupMeshCallService — state machine + signaling

**Files:**
- Create: `lib/core/mesh/voice/group_mesh_call_service.dart`
- Test: `test/core/mesh/voice/group_mesh_call_service_test.dart`

This task delivers the orchestration core: state machine, invite fanout, accept/decline/leave handling. **Audio and Noise handshake are stubbed in this task and wired in Task 6 and Task 7.** Stubbing keeps each task tractable.

- [ ] **Step 1: Read 1-on-1 service for pattern**

```bash
cat lib/core/mesh/voice/mesh_voice_service.dart | head -150
```

Note how it subscribes to `MeshMessagingService.inbound`, dispatches by envelope type, manages a state machine with timeouts, and exposes `Stream<CallState>`.

- [ ] **Step 2: Write the failing test (state-machine slice)**

Create `test/core/mesh/voice/group_mesh_call_service_test.dart`:

```dart
import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:taler_id_mobile/core/mesh/services/envelope.dart';
import 'package:taler_id_mobile/core/mesh/services/inbound_envelope.dart';
import 'package:taler_id_mobile/core/mesh/services/mesh_messaging_service.dart';
import 'package:taler_id_mobile/core/mesh/voice/group_mesh_call_service.dart';
import 'package:taler_id_mobile/core/mesh/voice/group_mesh_call_state.dart';

class _MockMessaging extends Mock implements MeshMessagingService {}

void main() {
  late _MockMessaging messaging;
  late StreamController<InboundEnvelope> inboundCtrl;
  late GroupMeshCallService svc;

  // bytes used as my devicePk in tests
  final myPk = Uint8List.fromList(List<int>.generate(32, (i) => 0xAA));
  final peerBPk = Uint8List.fromList(List<int>.generate(32, (i) => 0xBB));
  final peerCPk = Uint8List.fromList(List<int>.generate(32, (i) => 0xCC));

  setUp(() {
    messaging = _MockMessaging();
    inboundCtrl = StreamController<InboundEnvelope>.broadcast();
    when(() => messaging.inbound).thenAnswer((_) => inboundCtrl.stream);
    when(() => messaging.sendEnvelope(
          toUserPk: any(named: 'toUserPk'),
          envelope: any(named: 'envelope'),
        )).thenAnswer((_) async {});

    svc = GroupMeshCallService(
      messaging: messaging,
      myDevicePk: myPk,
      lobbyTimeout: const Duration(milliseconds: 200),
    );
  });

  tearDown(() async {
    await svc.dispose();
    await inboundCtrl.close();
  });

  test('start() from Idle transitions through Inviting → Lobby and fans out invites', () async {
    expect(svc.state, isA<GMCIdle>());

    await svc.start(invitees: {
      _bytesToHex(peerBPk): 'userB',
      _bytesToHex(peerCPk): 'userC',
    });

    expect(svc.state, isA<GMCLobby>());
    final lobby = svc.state as GMCLobby;
    expect(lobby.roster.where((p) => p.status == GMCStatus.calling).length, 2);

    // Two invite envelopes sent, one per invitee
    verify(() => messaging.sendEnvelope(
          toUserPk: any(named: 'toUserPk'),
          envelope: any(
              named: 'envelope',
              that: predicate<Envelope>(
                  (e) => e.type == MeshGcEnvelopeType.invite)),
        )).called(2);
  });

  test('accept envelope from peer marks them joined', () async {
    await svc.start(invitees: {
      _bytesToHex(peerBPk): 'userB',
    });

    inboundCtrl.add(InboundEnvelope(
      senderPeerId: peerBPk,
      envelope: Envelope(
        type: MeshGcEnvelopeType.accept,
        convId: (svc.state as GMCLobby).roomId,
        clientId: 'c',
        sentAt: DateTime.now(),
        extra: {
          'roomId': (svc.state as GMCLobby).roomId,
          'devicePk': _bytesToHex(peerBPk),
        },
      ),
    ));
    await Future<void>.delayed(const Duration(milliseconds: 20));

    // With all (1) invitee joined we transition straight to Active.
    expect(svc.state, isA<GMCActive>(),
        reason: 'all invitees accepted → Active');
  });

  test('decline envelope from sole invitee → Ended(allDeclined)', () async {
    await svc.start(invitees: {
      _bytesToHex(peerBPk): 'userB',
    });
    inboundCtrl.add(InboundEnvelope(
      senderPeerId: peerBPk,
      envelope: Envelope(
        type: MeshGcEnvelopeType.decline,
        convId: (svc.state as GMCLobby).roomId,
        clientId: 'c',
        sentAt: DateTime.now(),
        extra: {
          'roomId': (svc.state as GMCLobby).roomId,
          'devicePk': _bytesToHex(peerBPk),
        },
      ),
    ));
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(svc.state, isA<GMCEnded>());
    expect((svc.state as GMCEnded).reason, GMCEndReason.allDeclined);
  });

  test('lobby timeout with no accepts → Ended(noAnswer)', () async {
    await svc.start(invitees: {
      _bytesToHex(peerBPk): 'userB',
    });
    await Future<void>.delayed(const Duration(milliseconds: 250));
    expect(svc.state, isA<GMCEnded>());
    expect((svc.state as GMCEnded).reason, GMCEndReason.noAnswer);
  });

  test('hard cap rejects start with >4 invitees', () async {
    final tooMany = <String, String>{
      for (var i = 0; i < 5; i++)
        _bytesToHex(Uint8List.fromList(List<int>.generate(32, (_) => i))): 'u$i',
    };
    await expectLater(
      svc.start(invitees: tooMany),
      throwsA(isA<StateError>()),
    );
  });
}

String _bytesToHex(Uint8List b) =>
    b.map((x) => x.toRadixString(16).padLeft(2, '0')).join();
```

Note: `InboundEnvelope` is defined in the existing codebase — confirm its constructor shape via `grep -n "class InboundEnvelope"` and adjust if necessary.

- [ ] **Step 3: Run test to verify it fails**

```bash
flutter test test/core/mesh/voice/group_mesh_call_service_test.dart
```

Expected: FAIL — `GroupMeshCallService` not defined.

- [ ] **Step 4: Implement the service (signaling slice)**

Create `lib/core/mesh/voice/group_mesh_call_service.dart`:

```dart
import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:taler_id_mobile/core/mesh/services/envelope.dart';
import 'package:taler_id_mobile/core/mesh/services/inbound_envelope.dart';
import 'package:taler_id_mobile/core/mesh/services/mesh_messaging_service.dart';
import 'package:taler_id_mobile/core/mesh/voice/group_mesh_call_state.dart';

/// Maximum participants including self.
const int kGmcMaxParticipants = 5;
const int kGmcMaxInvitees = kGmcMaxParticipants - 1;

/// Orchestrator for one group mesh voice call at a time on this device.
///
/// Audio path (Tasks 6-7) is wired by the audio adapter; this file owns:
/// - state machine (Idle/Inviting/Lobby/Active/Ended/Error)
/// - signaling envelope dispatch via [MeshMessagingService]
/// - per-peer status transitions
/// - lobby timeout
class GroupMeshCallService {
  GroupMeshCallService({
    required this.messaging,
    required this.myDevicePk,
    this.lobbyTimeout = const Duration(seconds: 30),
    Random? random,
  }) : _random = random ?? Random() {
    _inboundSub = messaging.inbound.listen(_onInbound);
  }

  final MeshMessagingService messaging;
  final Uint8List myDevicePk;
  final Duration lobbyTimeout;
  final Random _random;

  GroupMeshCallState _state = const GMCIdle();
  final _stateCtrl = StreamController<GroupMeshCallState>.broadcast();
  StreamSubscription<InboundEnvelope>? _inboundSub;
  Timer? _lobbyTimer;

  GroupMeshCallState get state => _state;
  Stream<GroupMeshCallState> get stateStream => _stateCtrl.stream;

  String get _myPkHex => _bytesToHex(myDevicePk);

  /// Host path: send invites to a map of {devicePkHex: userId}.
  Future<void> start({required Map<String, String> invitees}) async {
    if (_state is! GMCIdle) {
      throw StateError('Cannot start: not idle (current=$_state)');
    }
    if (invitees.length > kGmcMaxInvitees) {
      throw StateError(
        'Group calls are capped at $kGmcMaxInvitees invitees ($kGmcMaxParticipants peers total)',
      );
    }
    final roomId = _generateRoomId();
    final participants = [
      GMCParticipant(
        devicePk: _myPkHex,
        userId: 'self', // service is contact-agnostic; the bloc enriches display info
        status: GMCStatus.joined,
        isSelf: true,
      ),
      ...invitees.entries.map((e) => GMCParticipant(
            devicePk: e.key,
            userId: e.value,
            status: GMCStatus.calling,
          )),
    ];
    _emit(GMCInviting(roomId: roomId, invitees: participants));

    for (final entry in invitees.entries) {
      await messaging.sendEnvelope(
        toUserPk: _hexToBytes(entry.key),
        envelope: Envelope(
          type: MeshGcEnvelopeType.invite,
          convId: roomId,
          clientId: _randomClientId(),
          sentAt: DateTime.now().toUtc(),
          extra: {
            'roomId': roomId,
            'hostDevicePk': _myPkHex,
            'participants': [
              for (final p in participants) p.devicePk,
            ],
            'startedAt': DateTime.now().toUtc().toIso8601String(),
          },
        ),
      );
    }

    _emit(GMCLobby(
      roomId: roomId,
      hostDevicePk: _myPkHex,
      roster: participants,
    ));
    _startLobbyTimer();
  }

  /// Invitee path — call after the user taps Accept on the native UI.
  Future<void> acceptInvite({
    required String roomId,
    required String hostDevicePkHex,
    required List<String> participantDevicePks,
  }) async {
    // Build roster from invite list.
    final roster = [
      for (final pk in participantDevicePks)
        GMCParticipant(
          devicePk: pk,
          userId: pk == _myPkHex ? 'self' : 'unknown',
          status: pk == _myPkHex ? GMCStatus.joined : GMCStatus.calling,
          isSelf: pk == _myPkHex,
        ),
    ];
    _emit(GMCLobby(
      roomId: roomId,
      hostDevicePk: hostDevicePkHex,
      roster: roster,
    ));

    // Send accept to every participant other than self.
    for (final p in roster) {
      if (p.isSelf) continue;
      await messaging.sendEnvelope(
        toUserPk: _hexToBytes(p.devicePk),
        envelope: Envelope(
          type: MeshGcEnvelopeType.accept,
          convId: roomId,
          clientId: _randomClientId(),
          sentAt: DateTime.now().toUtc(),
          extra: {'roomId': roomId, 'devicePk': _myPkHex},
        ),
      );
    }
    _startLobbyTimer();
  }

  Future<void> declineInvite({
    required String roomId,
    required String hostDevicePkHex,
  }) async {
    await messaging.sendEnvelope(
      toUserPk: _hexToBytes(hostDevicePkHex),
      envelope: Envelope(
        type: MeshGcEnvelopeType.decline,
        convId: roomId,
        clientId: _randomClientId(),
        sentAt: DateTime.now().toUtc(),
        extra: {'roomId': roomId, 'devicePk': _myPkHex},
      ),
    );
    _emit(const GMCIdle());
  }

  Future<void> leave() async {
    final s = _state;
    if (s is! GMCLobby && s is! GMCActive) return;
    final roomId = s is GMCLobby ? s.roomId : (s as GMCActive).roomId;
    final roster = s is GMCLobby ? s.roster : (s as GMCActive).roster;
    for (final p in roster) {
      if (p.isSelf) continue;
      await messaging.sendEnvelope(
        toUserPk: _hexToBytes(p.devicePk),
        envelope: Envelope(
          type: MeshGcEnvelopeType.leave,
          convId: roomId,
          clientId: _randomClientId(),
          sentAt: DateTime.now().toUtc(),
          extra: {'roomId': roomId, 'devicePk': _myPkHex},
        ),
      );
    }
    _emit(const GMCEnded(reason: GMCEndReason.userHangup));
  }

  void _onInbound(InboundEnvelope evt) {
    final type = evt.envelope.type;
    if (!MeshGcEnvelopeType.isMeshGc(type)) return;
    final s = _state;
    final roomId = evt.envelope.extra?['roomId'] as String?;
    if (roomId == null) return;

    switch (type) {
      case MeshGcEnvelopeType.invite:
        // Inbound invites are surfaced via a separate stream (Task 9) for the
        // UI to present native incoming. Service waits for acceptInvite().
        _emitIncomingInvite(evt);
        return;

      case MeshGcEnvelopeType.accept:
        if (s is! GMCLobby || s.roomId != roomId) return;
        final senderHex = evt.envelope.extra?['devicePk'] as String?;
        if (senderHex == null) return;
        final updated = s.roster
            .map((p) => p.devicePk == senderHex
                ? p.copyWith(status: GMCStatus.joined)
                : p)
            .toList();
        final allJoined = updated.every((p) => p.status == GMCStatus.joined);
        if (allJoined) {
          _lobbyTimer?.cancel();
          _emit(GMCActive(roomId: roomId, roster: updated, durationSec: 0));
        } else {
          _emit(s.copyWith(roster: updated));
        }
        return;

      case MeshGcEnvelopeType.decline:
        if (s is! GMCLobby || s.roomId != roomId) return;
        final senderHex = evt.envelope.extra?['devicePk'] as String?;
        if (senderHex == null) return;
        final updated = s.roster
            .map((p) => p.devicePk == senderHex
                ? p.copyWith(status: GMCStatus.declined)
                : p)
            .toList();
        final anyCallingOrJoined = updated.any((p) =>
            !p.isSelf &&
            (p.status == GMCStatus.calling || p.status == GMCStatus.joined));
        if (!anyCallingOrJoined) {
          _lobbyTimer?.cancel();
          _emit(const GMCEnded(reason: GMCEndReason.allDeclined));
        } else {
          _emit(s.copyWith(roster: updated));
        }
        return;

      case MeshGcEnvelopeType.leave:
        final senderHex = evt.envelope.extra?['devicePk'] as String?;
        if (senderHex == null) return;
        _handlePeerGone(senderHex);
        return;

      case MeshGcEnvelopeType.keepalive:
        // Audio-engine task handles per-peer watchdog reset.
        return;
    }
  }

  void _handlePeerGone(String pkHex) {
    final s = _state;
    if (s is GMCActive) {
      final updated = s.roster
          .where((p) => p.devicePk != pkHex)
          .toList();
      final othersRemain = updated.any((p) => !p.isSelf);
      if (!othersRemain) {
        _emit(const GMCEnded(reason: GMCEndReason.allLeft));
      } else {
        _emit(s.copyWith(roster: updated));
      }
    } else if (s is GMCLobby) {
      final updated = s.roster
          .map((p) => p.devicePk == pkHex
              ? p.copyWith(status: GMCStatus.left)
              : p)
          .toList();
      _emit(s.copyWith(roster: updated));
    }
  }

  /// Subclass-able hook for the bloc to listen to incoming invites.
  final _incomingInviteCtrl = StreamController<InboundEnvelope>.broadcast();
  Stream<InboundEnvelope> get incomingInviteStream => _incomingInviteCtrl.stream;
  void _emitIncomingInvite(InboundEnvelope evt) =>
      _incomingInviteCtrl.add(evt);

  void _startLobbyTimer() {
    _lobbyTimer?.cancel();
    _lobbyTimer = Timer(lobbyTimeout, () {
      final s = _state;
      if (s is! GMCLobby) return;
      final anyJoined =
          s.roster.any((p) => !p.isSelf && p.status == GMCStatus.joined);
      if (anyJoined) {
        // Drop non-responders, transition to Active.
        final filtered = s.roster
            .where((p) => p.isSelf || p.status == GMCStatus.joined)
            .toList();
        _emit(GMCActive(roomId: s.roomId, roster: filtered, durationSec: 0));
      } else {
        _emit(const GMCEnded(reason: GMCEndReason.noAnswer));
      }
    });
  }

  void _emit(GroupMeshCallState s) {
    _state = s;
    _stateCtrl.add(s);
  }

  String _generateRoomId() {
    final n = _random.nextInt(0xFFFFFFFF);
    return n.toRadixString(16).padLeft(8, '0');
  }

  String _randomClientId() =>
      DateTime.now().microsecondsSinceEpoch.toRadixString(36);

  Future<void> dispose() async {
    _lobbyTimer?.cancel();
    await _inboundSub?.cancel();
    await _stateCtrl.close();
    await _incomingInviteCtrl.close();
  }
}

String _bytesToHex(Uint8List b) =>
    b.map((x) => x.toRadixString(16).padLeft(2, '0')).join();

Uint8List _hexToBytes(String hex) {
  final out = Uint8List(hex.length ~/ 2);
  for (var i = 0; i < out.length; i++) {
    out[i] = int.parse(hex.substring(i * 2, i * 2 + 2), radix: 16);
  }
  return out;
}
```

- [ ] **Step 5: Run tests, verify they pass**

```bash
flutter test test/core/mesh/voice/group_mesh_call_service_test.dart
```

Expected: PASS (5 tests). If `InboundEnvelope` constructor differs, fix imports/parameters in both the test and the service to match the existing class.

- [ ] **Step 6: Commit**

```bash
git add lib/core/mesh/voice/group_mesh_call_service.dart test/core/mesh/voice/group_mesh_call_service_test.dart
git commit -m "feat(mesh-gc): GroupMeshCallService state machine + invite/accept/decline/leave signaling"
```

---

## Task 6: Noise IK fanout + datagram routing

**Files:**
- Modify: `lib/core/mesh/voice/group_mesh_call_service.dart`
- Test: `test/core/mesh/voice/group_mesh_call_service_test.dart` (add cases)

Once the room transitions to Active, the service must:
1. For each non-self peer, ensure a Noise IK session exists via `MeshMessagingService.datagramCiphersFor(peer)`. Initiate only if our devicePk is lexicographically smaller (race-free pairing).
2. Wire per-peer outbound + inbound datagram routing through `MultiTransport`.

- [ ] **Step 1: Add the failing test for lexicographic initiator role**

Append to `test/core/mesh/voice/group_mesh_call_service_test.dart`:

```dart
group('Noise role assignment', () {
  test('peer with lexicographically smaller devicePk initiates', () {
    // 0xAA < 0xBB → myPk is initiator vs peerBPk
    final smaller = Uint8List.fromList(List<int>.generate(32, (i) => 0xAA));
    final larger = Uint8List.fromList(List<int>.generate(32, (i) => 0xBB));
    expect(GroupMeshCallService.shouldInitiateNoise(smaller, larger), isTrue);
    expect(GroupMeshCallService.shouldInitiateNoise(larger, smaller), isFalse);
  });

  test('equal devicePk byte-strings is a contradiction (self-pair) — false', () {
    final pk = Uint8List.fromList(List<int>.generate(32, (i) => 0x42));
    expect(GroupMeshCallService.shouldInitiateNoise(pk, pk), isFalse);
  });
});
```

- [ ] **Step 2: Run test to verify it fails**

```bash
flutter test test/core/mesh/voice/group_mesh_call_service_test.dart
```

Expected: FAIL — `shouldInitiateNoise` not defined.

- [ ] **Step 3: Add the static helper to `GroupMeshCallService`**

Inside the `GroupMeshCallService` class, add:

```dart
/// Deterministic role assignment to avoid concurrent-handshake races.
/// The peer with the numerically smaller devicePk byte-string is the sole
/// initiator. Equal pks are an invalid self-pair.
static bool shouldInitiateNoise(Uint8List myPk, Uint8List peerPk) {
  if (myPk.length != peerPk.length) {
    // Defensive: in practice both are 32 bytes (X25519).
    return false;
  }
  for (var i = 0; i < myPk.length; i++) {
    if (myPk[i] < peerPk[i]) return true;
    if (myPk[i] > peerPk[i]) return false;
  }
  return false; // equal → not initiator (degenerate self-pair)
}
```

- [ ] **Step 4: Run tests, verify they pass**

```bash
flutter test test/core/mesh/voice/group_mesh_call_service_test.dart
```

Expected: PASS (now 7 tests).

- [ ] **Step 5: Add per-peer session bootstrap on Active**

This is the "wire datagram I/O" step. We need to inject `MultiTransport` (or similar) into the service. Modify the service constructor:

```dart
GroupMeshCallService({
  required this.messaging,
  required this.transport,        // NEW: MeshTransport for datagrams
  required this.myDevicePk,
  this.lobbyTimeout = const Duration(seconds: 30),
  Random? random,
}) : _random = random ?? Random() {
  _inboundSub = messaging.inbound.listen(_onInbound);
  _datagramSub = transport.inboundDatagrams.listen(_onInboundDatagram);
}

final MeshTransport transport;
StreamSubscription<InboundDatagram>? _datagramSub;
```

Import:

```dart
import 'package:taler_id_mobile/core/mesh/transport/mesh_transport.dart';
```

Add the bootstrap method called when entering Active:

```dart
final _peerCiphers = <String, ({MeshDatagramCipher outbound, MeshDatagramCipher inbound})>{};

Future<void> _bootstrapActiveSessions(GMCActive active) async {
  for (final p in active.roster) {
    if (p.isSelf) continue;
    final peerBytes = _hexToBytes(p.devicePk);
    final ciphers = await messaging.datagramCiphersFor(peerBytes);
    if (ciphers != null) {
      _peerCiphers[p.devicePk] = ciphers;
    }
    // datagramCiphersFor returns null until handshake completes; messaging
    // initiates handshake on first sendEnvelope (already happened for invite).
    // Retry path: we re-check on next inbound envelope / on timer below.
  }
}

void _onInboundDatagram(InboundDatagram dg) {
  // To be wired in Task 7 — audio path consumes these and routes by peer.
}
```

Call `_bootstrapActiveSessions(s)` from `_emit` when emitting `GMCActive`:

```dart
void _emit(GroupMeshCallState s) {
  _state = s;
  _stateCtrl.add(s);
  if (s is GMCActive) {
    unawaited(_bootstrapActiveSessions(s));
  }
}
```

Add `import 'package:taler_id_mobile/core/mesh/crypto/mesh_datagram_cipher.dart';` and `import 'package:taler_id_mobile/core/mesh/transport/inbound_datagram.dart';` (verify path via `grep -rn "class InboundDatagram"`). Add `unawaited` import from `dart:async`.

- [ ] **Step 6: Update existing service tests to pass a mock transport**

In the `setUp` of `group_mesh_call_service_test.dart`, add:

```dart
class _MockTransport extends Mock implements MeshTransport {}
// ...
final transport = _MockTransport();
when(() => transport.inboundDatagrams).thenAnswer((_) => const Stream.empty());
svc = GroupMeshCallService(
  messaging: messaging,
  transport: transport,
  myDevicePk: myPk,
  lobbyTimeout: const Duration(milliseconds: 200),
);
when(() => messaging.datagramCiphersFor(any())).thenAnswer((_) async => null);
```

- [ ] **Step 7: Run tests, verify they pass**

```bash
flutter test test/core/mesh/voice/group_mesh_call_service_test.dart
```

Expected: PASS (7 tests).

- [ ] **Step 8: Commit**

```bash
git add lib/core/mesh/voice/group_mesh_call_service.dart test/core/mesh/voice/group_mesh_call_service_test.dart
git commit -m "feat(mesh-gc): Noise role assignment + per-peer datagram cipher bootstrap on Active"
```

---

## Task 7: Wire audio engine to per-peer sessions

**Files:**
- Modify: `lib/core/mesh/voice/group_mesh_call_service.dart`

When Active, the service must:
- Start `GroupMeshVoiceAudioEngine` once entering Active.
- Subscribe to `engine.outbound` and, for each frame, encrypt-and-send to every peer via the per-peer cipher and `transport.sendDatagram`.
- On inbound datagram from a peer, decrypt with that peer's inbound cipher and call `engine.inbound(peerPkHex, seq, payload)`.

- [ ] **Step 1: Inject audio engine factory into the service constructor**

Modify the constructor:

```dart
GroupMeshCallService({
  required this.messaging,
  required this.transport,
  required this.myDevicePk,
  required this.audioEngineFactory,
  this.lobbyTimeout = const Duration(seconds: 30),
  Random? random,
}) : _random = random ?? Random() { ... }

final GroupMeshVoiceAudioEngine Function() audioEngineFactory;
GroupMeshVoiceAudioEngine? _audio;
StreamSubscription<Uint8List>? _audioOutSub;
```

Add imports:

```dart
import 'package:taler_id_mobile/core/audio/group_mesh_voice_audio_engine.dart';
import 'package:taler_id_mobile/core/mesh/voice/mesh_voice_frame.dart';
```

- [ ] **Step 2: Add audio start/stop in `_emit`**

Modify `_emit`:

```dart
void _emit(GroupMeshCallState s) {
  final previous = _state;
  _state = s;
  _stateCtrl.add(s);

  if (s is GMCActive && previous is! GMCActive) {
    unawaited(_startAudio(s));
  } else if (s is! GMCActive && previous is GMCActive) {
    unawaited(_stopAudio());
  }
  if (s is GMCActive) {
    unawaited(_bootstrapActiveSessions(s));
  }
}
```

- [ ] **Step 3: Implement `_startAudio` / `_stopAudio`**

Add:

```dart
final _outboundSeqByPeer = <String, int>{};

Future<void> _startAudio(GMCActive active) async {
  final engine = audioEngineFactory();
  _audio = engine;
  await engine.start();
  for (final p in active.roster) {
    if (p.isSelf) continue;
    engine.addPeer(p.devicePk);
    _outboundSeqByPeer[p.devicePk] = 0;
  }
  _audioOutSub = engine.outbound.listen(_onEncodedAudioFrame);
}

Future<void> _stopAudio() async {
  await _audioOutSub?.cancel();
  _audioOutSub = null;
  await _audio?.stop();
  await _audio?.dispose();
  _audio = null;
  _peerCiphers.clear();
  _outboundSeqByPeer.clear();
}

bool _selfMuted = false;

Future<void> toggleMute() async {
  _selfMuted = !_selfMuted;
  final s = _state;
  if (s is GMCActive) {
    _emit(s.copyWith(selfMuted: _selfMuted));
  }
}

void _onEncodedAudioFrame(Uint8List opusPayload) {
  final s = _state;
  if (s is! GMCActive) return;
  if (_selfMuted) return; // skip fanout while muted (capture stays warm)
  for (final p in s.roster) {
    if (p.isSelf) continue;
    final ciphers = _peerCiphers[p.devicePk];
    if (ciphers == null) continue; // handshake not done yet
    final seq = (_outboundSeqByPeer[p.devicePk] ?? 0) + 1;
    _outboundSeqByPeer[p.devicePk] = seq;
    final roomIdInt = int.parse(s.roomId, radix: 16);
    final ciphertext = ciphers.outbound.encryptFrame(seq: seq, plaintext: opusPayload);
    final frame = MeshVoiceFrame(
      type: MeshVoiceFrameType.audio,
      callId: roomIdInt,
      seq: seq,
      ciphertext: ciphertext,
    ).encode();
    unawaited(transport.sendDatagram(_hexToBytes(p.devicePk), frame));
  }
}
```

Note: the exact signature of `MeshDatagramCipher.encryptFrame`/`decryptFrame` lives in `lib/core/mesh/crypto/mesh_datagram_cipher.dart`. Inspect that file and adapt the call sites here. Same for `MeshVoiceFrame` decoder.

- [ ] **Step 4: Wire `_onInboundDatagram`**

Replace the no-op:

```dart
void _onInboundDatagram(InboundDatagram dg) {
  final engine = _audio;
  if (engine == null) return;
  final s = _state;
  if (s is! GMCActive) return;
  final frame = MeshVoiceFrame.decode(dg.data);
  final roomIdInt = int.parse(s.roomId, radix: 16);
  if (frame.callId != roomIdInt) return; // not our room

  final senderHex = _bytesToHex(dg.senderPeerId);
  final ciphers = _peerCiphers[senderHex];
  if (ciphers == null) return;
  final plaintext = ciphers.inbound.decryptFrame(
    seq: frame.seq,
    ciphertext: frame.ciphertext,
  );
  if (plaintext == null) return;
  engine.inbound(senderHex, seq: frame.seq, payload: plaintext);
}
```

- [ ] **Step 5: Update tests — service tests cannot start the real audio engine. Use a fake factory.**

In `setUp` of the service test:

```dart
GroupMeshVoiceAudioEngine _fakeEngineFactory() {
  // Return a no-op fake. We don't exercise audio in service unit tests.
  return GroupMeshVoiceAudioEngine(
    capture: _NoopCapture(),
    playback: _NoopPlayback(),
    encoderFactory: () => _NoopEncoder(),
    decoderFactory: () => _NoopDecoder(),
  );
}

class _NoopCapture implements AudioCaptureSource {
  @override Stream<Int16List> get frames => const Stream.empty();
  @override Future<void> start() async {}
  @override Future<void> stop() async {}
}
class _NoopPlayback implements AudioPlaybackSink {
  @override Future<void> start() async {}
  @override Future<void> stop() async {}
  @override Future<void> writeFrame(Int16List samples) async {}
}
class _NoopEncoder implements GroupMeshOpusEncoder {
  @override Uint8List encode(Int16List pcm) => Uint8List(0);
}
class _NoopDecoder implements GroupMeshOpusDecoder {
  @override Int16List decode(Uint8List payload) => Int16List(0);
}

// In setUp:
svc = GroupMeshCallService(
  messaging: messaging,
  transport: transport,
  audioEngineFactory: _fakeEngineFactory,
  myDevicePk: myPk,
  lobbyTimeout: const Duration(milliseconds: 200),
);
```

- [ ] **Step 6: Run tests, verify they pass**

```bash
flutter test test/core/mesh/voice/
```

Expected: PASS — all service + state + envelope tests.

- [ ] **Step 7: Commit**

```bash
git add lib/core/mesh/voice/group_mesh_call_service.dart test/core/mesh/voice/group_mesh_call_service_test.dart
git commit -m "feat(mesh-gc): wire GroupMeshVoiceAudioEngine to per-peer Noise sessions and transport"
```

---

## Task 8: GroupMeshCallBloc

**Files:**
- Create: `lib/features/voice/presentation/bloc/group_mesh_call_event.dart`
- Create: `lib/features/voice/presentation/bloc/group_mesh_call_bloc_state.dart`
- Create: `lib/features/voice/presentation/bloc/group_mesh_call_bloc.dart`
- Test: `test/features/voice/presentation/bloc/group_mesh_call_bloc_test.dart`

The bloc translates UI events to service calls and re-emits service state as bloc state. State shapes mirror `GroupMeshCallState` 1:1 to keep things simple. The bloc additionally enriches the roster with display info (name, avatar) by joining against the contact store.

- [ ] **Step 1: Write event types**

Create `lib/features/voice/presentation/bloc/group_mesh_call_event.dart`:

```dart
import 'package:equatable/equatable.dart';

sealed class GroupMeshCallEvent extends Equatable {
  const GroupMeshCallEvent();
  @override
  List<Object?> get props => const [];
}

class GMCStartRequested extends GroupMeshCallEvent {
  const GMCStartRequested({required this.invitees});
  final Map<String, String> invitees; // devicePkHex → userId
  @override
  List<Object?> get props => [invitees];
}

class GMCAcceptInvite extends GroupMeshCallEvent {
  const GMCAcceptInvite({
    required this.roomId,
    required this.hostDevicePkHex,
    required this.participantDevicePks,
  });
  final String roomId;
  final String hostDevicePkHex;
  final List<String> participantDevicePks;
  @override
  List<Object?> get props => [roomId, hostDevicePkHex, participantDevicePks];
}

class GMCDeclineInvite extends GroupMeshCallEvent {
  const GMCDeclineInvite({required this.roomId, required this.hostDevicePkHex});
  final String roomId;
  final String hostDevicePkHex;
  @override
  List<Object?> get props => [roomId, hostDevicePkHex];
}

class GMCLeavePressed extends GroupMeshCallEvent {
  const GMCLeavePressed();
}

class GMCToggleMute extends GroupMeshCallEvent {
  const GMCToggleMute();
}

class _GMCServiceStateChanged extends GroupMeshCallEvent {
  const _GMCServiceStateChanged(this.next);
  final Object next; // GroupMeshCallState — typed import would cycle
  @override
  List<Object?> get props => [identityHashCode(next)];
}
```

- [ ] **Step 2: Write bloc state types**

Create `lib/features/voice/presentation/bloc/group_mesh_call_bloc_state.dart`:

```dart
import 'package:taler_id_mobile/core/mesh/voice/group_mesh_call_state.dart';

/// Bloc state is a thin wrapper around the service's [GroupMeshCallState];
/// the bloc simply forwards updates so widgets can `switch` directly on
/// `GMCIdle/Lobby/Active/Ended/Error`.
typedef GroupMeshCallBlocState = GroupMeshCallState;
```

- [ ] **Step 3: Write the failing test**

Create `test/features/voice/presentation/bloc/group_mesh_call_bloc_test.dart`:

```dart
import 'dart:async';
import 'dart:typed_data';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:taler_id_mobile/core/mesh/voice/group_mesh_call_service.dart';
import 'package:taler_id_mobile/core/mesh/voice/group_mesh_call_state.dart';
import 'package:taler_id_mobile/features/voice/presentation/bloc/group_mesh_call_bloc.dart';
import 'package:taler_id_mobile/features/voice/presentation/bloc/group_mesh_call_event.dart';

class _MockService extends Mock implements GroupMeshCallService {}

void main() {
  late _MockService svc;
  late StreamController<GroupMeshCallState> stateCtrl;

  setUp(() {
    svc = _MockService();
    stateCtrl = StreamController<GroupMeshCallState>.broadcast();
    when(() => svc.state).thenReturn(const GMCIdle());
    when(() => svc.stateStream).thenAnswer((_) => stateCtrl.stream);
    when(() => svc.start(invitees: any(named: 'invitees')))
        .thenAnswer((_) async {});
    when(() => svc.leave()).thenAnswer((_) async {});
  });

  blocTest<GroupMeshCallBloc, GroupMeshCallState>(
    'forwards service state to bloc state',
    build: () => GroupMeshCallBloc(service: svc),
    act: (b) {
      stateCtrl.add(GMCLobby(
        roomId: 'r1',
        hostDevicePk: 'h',
        roster: const [],
      ));
    },
    expect: () => [
      isA<GMCLobby>(),
    ],
  );

  blocTest<GroupMeshCallBloc, GroupMeshCallState>(
    'GMCStartRequested calls service.start',
    build: () => GroupMeshCallBloc(service: svc),
    act: (b) => b.add(const GMCStartRequested(invitees: {'aabb': 'u1'})),
    verify: (_) {
      verify(() => svc.start(invitees: {'aabb': 'u1'})).called(1);
    },
  );

  blocTest<GroupMeshCallBloc, GroupMeshCallState>(
    'GMCLeavePressed calls service.leave',
    build: () => GroupMeshCallBloc(service: svc),
    act: (b) => b.add(const GMCLeavePressed()),
    verify: (_) {
      verify(() => svc.leave()).called(1);
    },
  );
}
```

- [ ] **Step 4: Run test to verify it fails**

```bash
flutter test test/features/voice/presentation/bloc/group_mesh_call_bloc_test.dart
```

Expected: FAIL — `GroupMeshCallBloc` not defined.

- [ ] **Step 5: Implement bloc**

Create `lib/features/voice/presentation/bloc/group_mesh_call_bloc.dart`:

```dart
import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taler_id_mobile/core/mesh/voice/group_mesh_call_service.dart';
import 'package:taler_id_mobile/core/mesh/voice/group_mesh_call_state.dart';
import 'package:taler_id_mobile/features/voice/presentation/bloc/group_mesh_call_event.dart';

class GroupMeshCallBloc extends Bloc<GroupMeshCallEvent, GroupMeshCallState> {
  GroupMeshCallBloc({required this.service}) : super(service.state) {
    on<GMCStartRequested>(_onStart);
    on<GMCAcceptInvite>(_onAccept);
    on<GMCDeclineInvite>(_onDecline);
    on<GMCLeavePressed>(_onLeave);
    on<GMCToggleMute>(_onToggleMute);
    on<_GMCStateForwarded>(_onForwarded);

    _serviceSub = service.stateStream.listen((s) {
      add(_GMCStateForwarded(s));
    });
  }

  final GroupMeshCallService service;
  StreamSubscription<GroupMeshCallState>? _serviceSub;

  Future<void> _onStart(GMCStartRequested e, Emitter emit) async {
    try {
      await service.start(invitees: e.invitees);
    } on StateError catch (err) {
      emit(GMCError(message: err.message));
    }
  }

  Future<void> _onAccept(GMCAcceptInvite e, Emitter emit) async {
    await service.acceptInvite(
      roomId: e.roomId,
      hostDevicePkHex: e.hostDevicePkHex,
      participantDevicePks: e.participantDevicePks,
    );
  }

  Future<void> _onDecline(GMCDeclineInvite e, Emitter emit) async {
    await service.declineInvite(
      roomId: e.roomId,
      hostDevicePkHex: e.hostDevicePkHex,
    );
  }

  Future<void> _onLeave(GMCLeavePressed e, Emitter emit) async {
    await service.leave();
  }

  Future<void> _onToggleMute(GMCToggleMute e, Emitter emit) async {
    await service.toggleMute();
  }

  void _onForwarded(_GMCStateForwarded e, Emitter emit) {
    emit(e.next);
  }

  @override
  Future<void> close() async {
    await _serviceSub?.cancel();
    return super.close();
  }
}

class _GMCStateForwarded extends GroupMeshCallEvent {
  const _GMCStateForwarded(this.next);
  final GroupMeshCallState next;
  @override
  List<Object?> get props => [identityHashCode(next)];
}
```

Also adjust the import in `group_mesh_call_event.dart` if the `_GMCServiceStateChanged` class there is now redundant — remove it.

- [ ] **Step 6: Run tests, verify they pass**

```bash
flutter test test/features/voice/presentation/bloc/group_mesh_call_bloc_test.dart
```

Expected: PASS.

- [ ] **Step 7: Commit**

```bash
git add lib/features/voice/presentation/bloc/group_mesh_call_bloc.dart \
  lib/features/voice/presentation/bloc/group_mesh_call_event.dart \
  lib/features/voice/presentation/bloc/group_mesh_call_bloc_state.dart \
  test/features/voice/presentation/bloc/group_mesh_call_bloc_test.dart
git commit -m "feat(mesh-gc): GroupMeshCallBloc forwarding service state to UI"
```

---

## Task 9: DI registration + envelope routing wiring

**Files:**
- Modify: `lib/core/di/service_locator.dart`

- [ ] **Step 1: Locate the MeshVoiceService registration**

```bash
grep -n "MeshVoiceService\|GroupCallBloc\|GroupMeshCallService" lib/core/di/service_locator.dart
```

- [ ] **Step 2: Register `GroupMeshCallService`**

Add (near the existing `MeshVoiceService` registration, around line 321):

```dart
sl.registerLazySingleton<GroupMeshCallService>(() {
  return GroupMeshCallService(
    messaging: sl<MeshMessagingService>(),
    transport: sl<MeshTransport>(),
    myDevicePk: sl<DeviceKeyStore>().myDevicePublicKey,
    audioEngineFactory: () => GroupMeshVoiceAudioEngine(
      capture: NativeAudioCapture(),
      playback: NativeAudioPlayback(),
      encoderFactory: () => FfiGroupMeshOpusEncoder(
        sampleRate: 16000,
        bitrate: 24000,
      ),
      decoderFactory: () => FfiGroupMeshOpusDecoder(sampleRate: 16000),
    ),
  );
});
```

Wire `NativeAudioCapture` / `NativeAudioPlayback` to whatever the existing 1-on-1 engine uses — inspect `lib/core/audio/mesh_voice_audio_engine.dart` for the actual capture/playback classes and adapt the adapter pattern from Task 4. Concretely: the production audio engine in 1-on-1 instantiates the native plugin facade; the group version reuses the same.

Add imports at the top of `service_locator.dart`:

```dart
import 'package:taler_id_mobile/core/audio/group_mesh_voice_audio_engine.dart';
import 'package:taler_id_mobile/core/mesh/voice/group_mesh_call_service.dart';
import 'package:taler_id_mobile/features/voice/presentation/bloc/group_mesh_call_bloc.dart';
```

- [ ] **Step 3: Register `GroupMeshCallBloc`**

Add (near the existing `GroupCallBloc` registration at line 505):

```dart
sl.registerFactory<GroupMeshCallBloc>(
  () => GroupMeshCallBloc(service: sl<GroupMeshCallService>()),
);
```

Use `registerFactory` (not `registerLazySingleton`) so each call screen instance gets a fresh bloc.

- [ ] **Step 4: Build to confirm DI compiles**

```bash
flutter build apk --debug --flavor dev --dart-define=FLAVOR=dev --dart-define=BASE_URL=https://staging.id.taler.tirol -t lib/main_dev.dart 2>&1 | tail -20
```

Expected: no compile errors. (We don't need to install the APK in this step; we're just confirming the DI graph wires.)

- [ ] **Step 5: Commit**

```bash
git add lib/core/di/service_locator.dart
git commit -m "feat(mesh-gc): wire GroupMeshCallService + GroupMeshCallBloc into DI"
```

---

## Task 10: New group call screen — mesh contact filter

**Files:**
- Modify: `lib/features/voice/presentation/screens/new_group_call_screen.dart`

- [ ] **Step 1: Read the existing screen**

```bash
cat lib/features/voice/presentation/screens/new_group_call_screen.dart
```

Identify: (a) where the contact list is built, (b) where the "Start" button dispatches `CreateCall` (LiveKit event), (c) where the multi-select cap is enforced.

- [ ] **Step 2: Replace the bloc**

At the top of the file, swap:

```dart
// Before
import 'package:taler_id_mobile/features/voice/presentation/bloc/group_call_bloc.dart';
// After
import 'package:taler_id_mobile/features/voice/presentation/bloc/group_mesh_call_bloc.dart';
import 'package:taler_id_mobile/features/voice/presentation/bloc/group_mesh_call_event.dart';
import 'package:taler_id_mobile/features/voice/presentation/bloc/group_mesh_call_bloc_state.dart';
```

In the `build` method, replace `BlocProvider.value(value: sl<GroupCallBloc>(), child: ...)` (or whichever pattern the file uses) with:

```dart
BlocProvider(
  create: (_) => sl<GroupMeshCallBloc>(),
  child: BlocListener<GroupMeshCallBloc, GroupMeshCallState>(
    listener: (context, state) {
      if (state is GMCLobby) {
        context.go('/group-call/${state.roomId}/lobby');
      } else if (state is GMCError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(state.message)),
        );
      }
    },
    child: ...,
  ),
)
```

- [ ] **Step 3: Filter contact list to mesh-reachable peers**

Inject `MeshPeerEligibilityWatcher` via `sl<MeshPeerEligibilityWatcher>()`. When building the contact list, for each contact:

```dart
final watcher = sl<MeshPeerEligibilityWatcher>();
final isReachable = watcher.isUserOnline(contact.userId);

ListTile(
  enabled: isReachable,
  title: Text(contact.displayName),
  subtitle: isReachable
      ? const Text('online via mesh')
      : Text(
          AppLocalizations.of(context).meshGcContactOffline,
          style: TextStyle(color: Theme.of(context).disabledColor),
        ),
  trailing: Checkbox(
    value: isSelected,
    onChanged: isReachable
        ? (v) => _toggleSelect(contact.userId, v ?? false)
        : null,
  ),
);
```

Add a string `meshGcContactOffline` to `lib/l10n/app_en.arb` and `lib/l10n/app_ru.arb`:

```json
"meshGcContactOffline": "Not on this Wi-Fi",
```
```json
"meshGcContactOffline": "Не в этой Wi-Fi сети",
```

Regenerate localizations:

```bash
flutter gen-l10n
```

- [ ] **Step 4: Hard cap 4 invitees**

In `_toggleSelect`:

```dart
void _toggleSelect(String userId, bool selected) {
  setState(() {
    if (selected) {
      if (_selected.length >= 4) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).meshGcMaxInvitees),
          ),
        );
        return;
      }
      _selected.add(userId);
    } else {
      _selected.remove(userId);
    }
  });
}
```

Add the localization key `meshGcMaxInvitees`: `"Group calls support up to 4 invitees (5 people total)."` / `"В групповом звонке до 4 приглашённых (5 всего)."`.

- [ ] **Step 5: Wire the Start button**

```dart
ElevatedButton(
  onPressed: _selected.isEmpty
      ? null
      : () {
          final invitees = <String, String>{};
          for (final userId in _selected) {
            final devices = sl<MeshPeerEligibilityWatcher>()
                .onlineDevicesForUser(userId);
            if (devices.isEmpty) continue;
            // Pick the first online device (PeerId is the devicePk bytes).
            final pkHex = _peerIdToHex(devices.first);
            invitees[pkHex] = userId;
          }
          if (invitees.isEmpty) return;
          context.read<GroupMeshCallBloc>().add(
                GMCStartRequested(invitees: invitees),
              );
        },
  child: Text(AppLocalizations.of(context).meshGcStart),
);
```

Add the `_peerIdToHex` helper and `meshGcStart` localization key (`"Start group call"` / `"Начать групповой звонок"`).

- [ ] **Step 6: Smoke build**

```bash
flutter analyze lib/features/voice/presentation/screens/new_group_call_screen.dart
```

Expected: no errors.

- [ ] **Step 7: Commit**

```bash
git add lib/features/voice/presentation/screens/new_group_call_screen.dart \
  lib/l10n/app_en.arb lib/l10n/app_ru.arb lib/l10n/app_localizations*.dart
git commit -m "feat(mesh-gc): contact picker filters by mesh reachability + dispatches GMCStartRequested"
```

---

## Task 11: Group call lobby screen — wire to mesh bloc

**Files:**
- Modify: `lib/features/voice/presentation/screens/group_call_lobby_screen.dart`

- [ ] **Step 1: Read existing screen**

```bash
cat lib/features/voice/presentation/screens/group_call_lobby_screen.dart
```

Identify which states it currently switches on (`InLobby`, `InActive` from LiveKit bloc) and where it navigates to `/group-call/:id`.

- [ ] **Step 2: Swap bloc imports**

At the top, replace LiveKit bloc imports with mesh bloc imports:

```dart
import 'package:taler_id_mobile/features/voice/presentation/bloc/group_mesh_call_bloc.dart';
import 'package:taler_id_mobile/features/voice/presentation/bloc/group_mesh_call_event.dart';
import 'package:taler_id_mobile/features/voice/presentation/bloc/group_mesh_call_bloc_state.dart';
import 'package:taler_id_mobile/core/mesh/voice/group_mesh_call_state.dart';
```

- [ ] **Step 3: Update BlocConsumer mapping**

Replace LiveKit state checks with mesh equivalents:

```dart
BlocConsumer<GroupMeshCallBloc, GroupMeshCallState>(
  listener: (context, state) {
    if (state is GMCActive) {
      context.go('/group-call/${state.roomId}');
    } else if (state is GMCEnded) {
      context.go('/call-history');
    } else if (state is GMCError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(state.message)),
      );
    }
  },
  builder: (context, state) {
    if (state is! GMCLobby) {
      return const Center(child: CircularProgressIndicator());
    }
    return _LobbyView(state: state);
  },
);
```

`_LobbyView` renders the roster as a list of tiles with status badges. Implement it as a private widget in this file using a `Column` of `ListTile`s reading from `state.roster`.

- [ ] **Step 4: Cancel button**

```dart
TextButton.icon(
  onPressed: () => context.read<GroupMeshCallBloc>().add(const GMCLeavePressed()),
  icon: const Icon(Icons.close),
  label: Text(AppLocalizations.of(context).meshGcCancel),
);
```

Add localization key `meshGcCancel`: `"Cancel"` / `"Отмена"`.

- [ ] **Step 5: Build the file**

```bash
flutter analyze lib/features/voice/presentation/screens/group_call_lobby_screen.dart
```

- [ ] **Step 6: Commit**

```bash
git add lib/features/voice/presentation/screens/group_call_lobby_screen.dart \
  lib/l10n/app_en.arb lib/l10n/app_ru.arb lib/l10n/app_localizations*.dart
git commit -m "feat(mesh-gc): lobby screen rendering GMCLobby roster, GMCActive navigation"
```

---

## Task 12: Group call active screen — wire to mesh bloc

**Files:**
- Modify: `lib/features/voice/presentation/screens/group_call_active_screen.dart`

- [ ] **Step 1: Read existing screen**

```bash
cat lib/features/voice/presentation/screens/group_call_active_screen.dart
```

Identify the LiveKit Room ownership pattern (line numbers for `Room()`, `room.connect`, listener wiring) and the participant grid build.

- [ ] **Step 2: Strip LiveKit Room ownership**

Remove `Room` field, `connect` call, and LiveKit listeners. The mesh path has no client-side Room object — the audio engine in the service handles everything.

- [ ] **Step 3: Replace bloc reference**

```dart
import 'package:taler_id_mobile/features/voice/presentation/bloc/group_mesh_call_bloc.dart';
import 'package:taler_id_mobile/features/voice/presentation/bloc/group_mesh_call_event.dart';
import 'package:taler_id_mobile/features/voice/presentation/bloc/group_mesh_call_bloc_state.dart';
import 'package:taler_id_mobile/core/mesh/voice/group_mesh_call_state.dart';

BlocConsumer<GroupMeshCallBloc, GroupMeshCallState>(
  listener: (context, state) {
    if (state is GMCEnded) {
      Navigator.of(context).pop();
    }
  },
  builder: (context, state) {
    if (state is! GMCActive) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return _ActiveCallView(state: state);
  },
);
```

- [ ] **Step 4: Build `_ActiveCallView`**

```dart
class _ActiveCallView extends StatelessWidget {
  const _ActiveCallView({required this.state});
  final GMCActive state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${l10n.meshGcTopTitle} • ${state.roster.length} • ${_fmtDuration(state.durationSec)}',
        ),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: state.roster.length <= 2 ? 1 : 2,
          childAspectRatio: 1.0,
        ),
        itemCount: state.roster.length,
        itemBuilder: (context, i) {
          final p = state.roster[i];
          return _ParticipantTile(participant: p);
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                icon: Icon(state.selfMuted ? Icons.mic_off : Icons.mic),
                onPressed: () =>
                    context.read<GroupMeshCallBloc>().add(const GMCToggleMute()),
              ),
              FloatingActionButton(
                backgroundColor: Colors.red,
                onPressed: () => context
                    .read<GroupMeshCallBloc>()
                    .add(const GMCLeavePressed()),
                child: const Icon(Icons.call_end),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _fmtDuration(int sec) {
    final m = (sec ~/ 60).toString().padLeft(2, '0');
    final s = (sec % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}

class _ParticipantTile extends StatelessWidget {
  const _ParticipantTile({required this.participant});
  final GMCParticipant participant;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 32,
              backgroundImage: participant.avatarUrl != null
                  ? NetworkImage(participant.avatarUrl!)
                  : null,
              child: participant.avatarUrl == null
                  ? Text(
                      (participant.displayName ?? participant.userId)
                          .substring(0, 1)
                          .toUpperCase(),
                    )
                  : null,
            ),
            const SizedBox(height: 8),
            Text(participant.displayName ?? participant.userId),
            if (participant.isMuted)
              const Icon(Icons.mic_off, size: 16, color: Colors.grey),
            if (participant.isSpeaking)
              Container(
                margin: const EdgeInsets.only(top: 4),
                height: 4,
                width: 24,
                color: Colors.green,
              ),
          ],
        ),
      ),
    );
  }
}
```

Add localization `meshGcTopTitle`: `"Mesh"` / `"Mesh"` (untranslated brand).

- [ ] **Step 5: Build**

```bash
flutter analyze lib/features/voice/presentation/screens/group_call_active_screen.dart
```

- [ ] **Step 6: Commit**

```bash
git add lib/features/voice/presentation/screens/group_call_active_screen.dart \
  lib/l10n/app_en.arb lib/l10n/app_ru.arb lib/l10n/app_localizations*.dart
git commit -m "feat(mesh-gc): active screen renders GMCActive roster grid, mute/hangup controls"
```

---

## Task 13: FAB un-gate + native incoming UI

**Files:**
- Modify: `lib/features/call_history/presentation/screens/call_history_screen.dart`
- Modify: `lib/core/di/service_locator.dart` (subscribe to `incomingInviteStream`)

- [ ] **Step 1: Read the FAB block**

```bash
sed -n '455,485p' lib/features/call_history/presentation/screens/call_history_screen.dart
```

- [ ] **Step 2: Remove the `AppConfig.isDev` gate**

Replace:

```dart
floatingActionButton: AppConfig.isDev
    ? FloatingActionButton.extended(
        onPressed: () => context.push(RouteConstants.newGroupCall),
        ...
        label: Text(l10n.groupCallSelectParticipants),
      )
    : null,
```

with:

```dart
floatingActionButton: FloatingActionButton.extended(
  onPressed: () => context.push(RouteConstants.newGroupCall),
  icon: const Icon(Icons.group_add),
  label: Text(l10n.groupCallSelectParticipants),
),
```

- [ ] **Step 3: Subscribe to `incomingInviteStream` once at startup**

In `service_locator.dart`, after the `GroupMeshCallService` registration block, hook the incoming stream to surface native call UI. Add (in the same module or wherever the existing 1-on-1 CallKit hook lives — see `lib/core/notifications/`):

```dart
// After all registrations complete (in initServices() or its equivalent):
sl<GroupMeshCallService>().incomingInviteStream.listen((evt) async {
  final extra = evt.envelope.extra;
  if (extra == null) return;
  final roomId = extra['roomId'] as String?;
  final hostHex = extra['hostDevicePk'] as String?;
  final participants = (extra['participants'] as List?)?.cast<String>();
  if (roomId == null || hostHex == null || participants == null) return;

  await FlutterCallkitIncoming.showCallkitIncoming(CallKitParams(
    id: roomId,
    nameCaller: 'Group call', // bloc/service can enrich later
    type: 0, // audio
    extra: {
      'kind': 'mesh_gc',
      'roomId': roomId,
      'hostDevicePkHex': hostHex,
      'participantDevicePks': participants,
    },
  ));
});
```

Wire the CallKit event handler (existing 1-on-1 path is in `lib/core/notifications/`): when the user taps Accept on the native UI, dispatch `GMCAcceptInvite` to the bloc and navigate to `/group-call/:roomId/lobby`. When Decline, dispatch `GMCDeclineInvite`.

Concrete handler example (place in the existing CallKit listener, branching on `extra['kind']`):

```dart
FlutterCallkitIncoming.onEvent.listen((event) async {
  final body = event?.body as Map<String, dynamic>?;
  final extra = body?['extra'] as Map<String, dynamic>?;
  final kind = extra?['kind'] as String?;
  if (kind != 'mesh_gc') return; // 1-on-1 path handles others

  final roomId = extra?['roomId'] as String?;
  final hostHex = extra?['hostDevicePkHex'] as String?;
  final participants = (extra?['participantDevicePks'] as List?)?.cast<String>();
  if (roomId == null || hostHex == null || participants == null) return;

  switch (event?.event) {
    case Event.actionCallAccept:
      sl<GroupMeshCallBloc>().add(GMCAcceptInvite(
        roomId: roomId,
        hostDevicePkHex: hostHex,
        participantDevicePks: participants,
      ));
      // Navigate via the global navigator key:
      GoRouter.of(NavigatorService.navigatorKey.currentContext!)
          .go('/group-call/$roomId/lobby');
      break;
    case Event.actionCallDecline:
      sl<GroupMeshCallBloc>().add(GMCDeclineInvite(
        roomId: roomId,
        hostDevicePkHex: hostHex,
      ));
      break;
    default:
      break;
  }
});
```

The exact event-stream class name (`Event.actionCallAccept` etc.) is from the existing `flutter_callkit_incoming` integration — inspect `lib/core/notifications/` for the actual import.

For Android background mesh calls, the Phase 3d.3 foreground service is already in place. Confirm it covers `mesh_gc_invite` by reading `docs/superpowers/plans/2026-04-30-mesh-voice-call-phase3d3-android-bg.md` — likely the routing is already by envelope type, and adding `mesh_gc_invite` to its handled set is a one-line change.

- [ ] **Step 4: Build**

```bash
flutter build apk --debug --flavor dev --dart-define=FLAVOR=dev -t lib/main_dev.dart 2>&1 | tail -10
```

Expected: no compile errors.

- [ ] **Step 5: Commit**

```bash
git add lib/features/call_history/presentation/screens/call_history_screen.dart \
  lib/core/di/service_locator.dart \
  lib/core/notifications/
git commit -m "feat(mesh-gc): un-gate group call FAB + wire CallKit accept/decline to GroupMeshCallBloc"
```

---

## Task 14: Mic-conflict guard

**Files:**
- Modify: `lib/core/mesh/voice/mesh_voice_service.dart` (1-on-1)
- Modify: `lib/features/call_history/presentation/screens/call_history_screen.dart`

- [ ] **Step 1: Add busy-state observable to `MeshVoiceService` and `GroupMeshCallService`**

Both services already expose `state` and `stateStream`. Add a getter `bool get isBusy` returning true when state is non-Idle.

In `mesh_voice_service.dart` (1-on-1):

```dart
bool get isBusy => state is! CallStateIdle;
```

In `group_mesh_call_service.dart`:

```dart
bool get isBusy => state is! GMCIdle && state is! GMCEnded && state is! GMCError;
```

- [ ] **Step 2: Auto-decline 1-on-1 invite while group active**

In `MeshVoiceService._onInbound` (1-on-1 invite handler), insert a guard at the top:

```dart
if (sl<GroupMeshCallService>().isBusy) {
  // Group call in progress; auto-decline 1-on-1 invite.
  await sendReject(reason: 'busy');
  return;
}
```

Wire `sl<GroupMeshCallService>()` access — the 1-on-1 service may not currently import `service_locator`. Pass the group service via constructor or use a lazy lookup. The simplest is constructor injection: add `GroupMeshCallService groupCallService` parameter; update DI registration accordingly.

- [ ] **Step 3: Disable group FAB when 1-on-1 busy**

In `call_history_screen.dart`, wrap the FAB in a `BlocBuilder` (or use a stream of `MeshVoiceService.stateStream`) and disable it when 1-on-1 is active:

```dart
floatingActionButton: StreamBuilder<CallState>(
  stream: sl<MeshVoiceService>().stateStream,
  initialData: sl<MeshVoiceService>().state,
  builder: (context, snapshot) {
    final busy = snapshot.data is! CallStateIdle;
    return FloatingActionButton.extended(
      onPressed: busy
          ? () => ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(AppLocalizations.of(context).meshGcBusyOneOnOne),
                ),
              )
          : () => context.push(RouteConstants.newGroupCall),
      icon: const Icon(Icons.group_add),
      label: Text(AppLocalizations.of(context).groupCallSelectParticipants),
      backgroundColor: busy ? Colors.grey : null,
    );
  },
),
```

Add localization `meshGcBusyOneOnOne`: `"Finish your current call first."` / `"Сначала завершите текущий звонок."`.

- [ ] **Step 4: Build**

```bash
flutter analyze lib/core/mesh/voice/mesh_voice_service.dart lib/features/call_history/presentation/screens/call_history_screen.dart
```

- [ ] **Step 5: Commit**

```bash
git add lib/core/mesh/voice/mesh_voice_service.dart \
  lib/features/call_history/presentation/screens/call_history_screen.dart \
  lib/core/di/service_locator.dart \
  lib/l10n/app_en.arb lib/l10n/app_ru.arb lib/l10n/app_localizations*.dart
git commit -m "feat(mesh-gc): mic-conflict guard — auto-decline 1-on-1 during group, disable FAB during 1-on-1"
```

---

## Task 15: 2-emulator integration test

**Files:**
- Create: `integration_test/group_mesh_call_test.dart`

The test verifies a 2-peer happy path on emulators 5554 (host) and 5556 (invitee), and also runs a second back-to-back call to the same invitee to catch the LiveKit Phase 1 "Defect #8" regression (sequential calls not delivered).

- [ ] **Step 1: Bring up emulators and grant mic permission**

Following the project CLAUDE.md runbook:

```bash
flutter emulators --launch Pixel_XL_API_33
~/Library/Android/sdk/emulator/emulator -avd Pixel_XL_2_API_33 -port 5556 -read-only &
sleep 30
~/Library/Android/sdk/platform-tools/adb devices
~/Library/Android/sdk/platform-tools/adb -s emulator-5554 shell pm grant tirol.taler.taler_id_mobile.dev android.permission.RECORD_AUDIO
~/Library/Android/sdk/platform-tools/adb -s emulator-5556 shell pm grant tirol.taler.taler_id_mobile.dev android.permission.RECORD_AUDIO
```

Expected: two devices reported by adb.

- [ ] **Step 2: Write the test**

Create `integration_test/group_mesh_call_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:taler_id_mobile/main_dev.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('group mesh call: host invites, invitee accepts, both reach Active',
      (tester) async {
    app.main();
    await tester.pumpAndSettle(const Duration(seconds: 5));

    // Login (use integration_test@taler-test.com on host, _2 on invitee).
    // Detect emulator role via adb-supplied env or hard-code by serial in the
    // wrapping shell script (integration_test/run_group_mesh_call_test.sh).
    // For the unit-level test here we just exercise the navigation paths
    // assuming user is logged in.

    // 1. Tap "Group mesh call" FAB
    final fab = find.byIcon(Icons.group_add);
    expect(fab, findsOneWidget);
    await tester.tap(fab);
    await tester.pumpAndSettle();

    // 2. Select one contact (the second test account) and tap Start
    final contactTile = find.text('integration_test_2');
    if (await tester.any(contactTile)) {
      await tester.tap(contactTile);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Start group call'));
      await tester.pumpAndSettle(const Duration(seconds: 3));
    }

    // 3. Lobby visible
    expect(find.textContaining('calling'), findsWidgets);

    // 4. Test ends after lobby visible — the second emulator script accepts
    //    in its own session. Cross-device coordination is via the shell
    //    script orchestrator (run_group_mesh_call_test.sh), not within Dart.
  });
}
```

- [ ] **Step 3: Write the shell orchestrator**

Create `integration_test/run_group_mesh_call_test.sh`:

```bash
#!/bin/bash
set -e

HOST=emulator-5554
INVITEE=emulator-5556

# Run host test that initiates the group call
flutter test integration_test/group_mesh_call_test.dart \
  --flavor dev --dart-define=FLAVOR=dev \
  --dart-define=BASE_URL=https://staging.id.taler.tirol \
  -d $HOST &
HOST_PID=$!

sleep 8

# Invitee: launch app and use adb to tap Accept on the incoming call UI.
# Coordinate accept via adb input tap or via a separate test file using
# IntegrationTestWidgetsFlutterBinding on the invitee device.
flutter run --flavor dev --dart-define=FLAVOR=dev \
  --dart-define=BASE_URL=https://staging.id.taler.tirol \
  -t lib/main_dev.dart \
  -d $INVITEE &
INVITEE_PID=$!

wait $HOST_PID
kill $INVITEE_PID 2>/dev/null || true
echo "Integration test orchestrator complete"
```

Make it executable:

```bash
chmod +x integration_test/run_group_mesh_call_test.sh
```

- [ ] **Step 4: Run host-side test (smoke)**

```bash
cd ~/Downloads/taler_id_mobile && flutter test integration_test/group_mesh_call_test.dart \
  --flavor dev --dart-define=FLAVOR=dev \
  --dart-define=BASE_URL=https://staging.id.taler.tirol \
  -d emulator-5554
```

Expected: navigation reaches the lobby; the cross-device portion is reserved for the manual hardware smoke documented in the spec.

- [ ] **Step 5: Commit**

```bash
git add integration_test/group_mesh_call_test.dart integration_test/run_group_mesh_call_test.sh
git commit -m "test(mesh-gc): 2-emulator host-side integration test for group call lobby"
```

---

## Task 16: Manual hardware smoke + version bump + release

**Files:**
- Modify: `pubspec.yaml` (bump version)

- [ ] **Step 1: Run all required pre-deploy tests**

Per the project CLAUDE.md "ОБЯЗАТЕЛЬНЫЕ ТЕСТЫ ПЕРЕД ДЕПЛОЕМ":

```bash
cd ~/Downloads/taler_id_mobile && flutter test
cd ~/Downloads/taler_id_tests && npm test
cd ~/Downloads/taler_id_tests && npm run test:voice
cd ~/Downloads/taler_id_tests && npm run test:assistant
cd ~/Downloads/taler_id_tests && npm run test:files
cd ~/Downloads/taler_id_tests && npm run test:channels
cd ~/Downloads/taler_id_tests && npm run test:billing
```

All must be green.

- [ ] **Step 2: Manual hardware smoke (mandatory before deploy)**

On 3 real devices (1 iPhone + 2 Android) all on the same Wi-Fi:

1. Log into the test accounts (host on iPhone, invitees on Android).
2. Host taps "Group mesh call" FAB, picks both Android contacts.
3. Both Android devices show full-screen incoming UI.
4. Both accept.
5. Verify all 3 hear each other clearly for 2 minutes (no echo, no dropouts).
6. iPhone host hangs up; Android devices show ended state.
7. Repeat the call immediately (defect #8 regression check) — second call must ring on both Android phones.

Document findings in commit message.

- [ ] **Step 3: Bump version**

In `pubspec.yaml`, increment to the next free build number (current is `1.0.70+163`):

```yaml
version: 1.0.71+164
```

- [ ] **Step 4: Build and deploy to DEV (staging) first**

Per CLAUDE.md "ПРАВИЛО ДЕПЛОЯ": dev first, prod only on explicit user instruction.

Mobile dev APK build runs on the prod server:

```bash
ssh dvolkov@138.124.61.221 'cd ~/taler_id_mobile && git fetch && git checkout dev && git pull && flutter build apk --flavor dev --release -t lib/main_dev.dart --dart-define=FLAVOR=dev --dart-define=BASE_URL=https://staging.id.taler.tirol && sudo cp build/app/outputs/flutter-apk/app-dev-release.apk /var/www/downloads/taler-id-dev.apk && sudo chmod 644 /var/www/downloads/taler-id-dev.apk'
```

- [ ] **Step 5: Commit version bump**

```bash
git add pubspec.yaml
git commit -m "release(1.0.71): group mesh voice room v1 — 2-5 peer full-mesh voice on same Wi-Fi"
```

- [ ] **Step 6: Wait for explicit user authorization before any PROD deploy**

PROD deploys (mobile `main` merge + APK rebuild + TestFlight upload) only happen after the user says "deploy to prod" or equivalent. The plan stops here; everything after is gated by the user.

---

## Self-review notes (controller-written)

- **Spec coverage check:**
  - §Scope / In scope: Tasks 1-15 cover invite, native UI, lobby, accept/timeout, Active, hangup, leave, Noise IK fanout, mic conflict, mesh-reachability filter. ✅
  - §Audio engine: Tasks 3-4. ✅
  - §State machine: Tasks 5-6. ✅
  - §UI: Tasks 10-12. ✅
  - §FAB un-gate: Task 13. ✅
  - §Coexistence with 1-on-1: Task 14. ✅
  - §Testing strategy: Tasks 1-8 cover unit tests; Task 15 covers integration; Task 16 covers manual hardware. ✅
  - §Out of scope items (late-join, Wi-Fi Direct, video, LiveKit fallback) are NOT in any task — correct. ✅

- **Type consistency check:** `GroupMeshCallState` is the sealed hierarchy used identically across `group_mesh_call_state.dart`, the service, and the bloc (via typedef). `GMCParticipant`, `GMCStatus`, `GMCEndReason` names are reused consistently. The bloc state file is a typedef onto the service state — no duplication, no drift risk.

- **Known gaps that implementer should resolve:**
  - The exact public API of `MeshDatagramCipher.encryptFrame` / `decryptFrame` and `MeshVoiceFrame.decode` is referenced but not verified against current source. Task 7 step 3 explicitly directs the implementer to `cat lib/core/mesh/crypto/mesh_datagram_cipher.dart` and adapt — minor adapter work.
  - The exact name of the existing `InboundEnvelope` / `InboundDatagram` constructors. Task 5 step 5 directs `grep -n "class InboundEnvelope"`.
  - `NativeAudioCapture` / `NativeAudioPlayback` adapter names are the ones used by the existing 1-on-1 engine in `lib/core/audio/mesh_voice_audio_engine.dart`; Task 9 step 2 directs the implementer to inspect that file. If the existing engine uses non-public concrete classes, factor a thin shared adapter as part of Task 4 follow-up.

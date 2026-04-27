# Mesh Phase 2 — Group Chats Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add group-chat support to mesh networking — pairwise Noise IK fanout to visible+known peers in addition to the always-on server send, with envelope-based wire format and heuristic dedup on receivers.

**Architecture:** Bump mesh frame version 1 → 2. Replace raw-text data payload with encrypted JSON envelope `{convId, clientId, type, text, sentAt}`. `MessengerRepositoryImpl.sendMessage` runs server-send + per-eligible-peer mesh-send simultaneously. Receivers dedup by `(senderId, content, sentAt-window)` heuristic — same as Phase 1g's `_onMessageReceived` temp_* removal.

**Tech Stack:** Flutter/Dart 3.6+, `bonsoir` 5.x, Noise IK (existing), `uuid` package (new dep), `flutter_bloc`, Hive (existing).

---

## File Structure

```
lib/core/mesh/
├── transport/
│   └── frame.dart                            # MODIFY: bump version 1 → 2
└── services/
    ├── envelope.dart                         # NEW: Envelope class with toJson/fromJson
    └── mesh_messaging_service.dart           # MODIFY: send/recv envelope JSON; rename sendText → sendEnvelope

lib/features/messenger/
├── data/
│   ├── services/
│   │   └── mesh_messenger_adapter.dart       # MODIFY: sendEnvelopeToPeer; inbound reads convId from envelope
│   └── repositories/
│       └── messenger_repository_impl.dart    # MODIFY: group fanout in sendMessage; remove TransportSelector usage
├── presentation/
│   └── bloc/
│       └── messenger_bloc.dart               # MODIFY: dedup extension; UUID-based temp ids
└── (DELETE: data/services/transport_selector.dart)

lib/features/mesh/
└── presentation/bloc/
    └── mesh_status_bloc.dart                 # MODIFY: add visibleParticipantsOf helper

lib/features/messenger/presentation/widgets/
└── chat_transport_badge.dart                 # MODIFY: support group "N/M in mesh" display

lib/core/di/
└── service_locator.dart                      # MODIFY: drop TransportSelector registration

pubspec.yaml                                  # MODIFY: add uuid dependency

test/core/mesh/
├── services/
│   └── envelope_test.dart                    # NEW
└── transport/
    └── frame_test.dart                       # MODIFY: v2 round-trip; v1 reject

test/features/messenger/
├── data/
│   ├── repositories/
│   │   └── messenger_repository_impl_group_test.dart  # NEW: group fanout tests
│   └── services/
│       └── mesh_messenger_adapter_test.dart  # MODIFY: envelope-aware
└── presentation/
    └── bloc/
        └── messenger_bloc_dedup_test.dart    # NEW: mesh-vs-server dedup heuristic
```

---

## Task 1: Add `uuid` dependency + UUID-based temp ids

**Files:**
- Modify: `pubspec.yaml`
- Modify: `lib/features/messenger/presentation/bloc/messenger_bloc.dart` (in `_onSendMessage`, change temp id format)
- Test: `test/messenger/messenger_bloc_test.dart` (verify pending temp_<uuid> removal still works)

- [ ] **Step 1: Add uuid to pubspec**

Edit `pubspec.yaml`. Find the `dependencies:` section and add (after existing deps, alphabetically):

```yaml
  uuid: ^4.5.2
```

- [ ] **Step 2: Run flutter pub get**

```
cd /Users/dmitry/Downloads/taler_id_mesh
flutter pub get
```
Expected: `Got dependencies!` and `uuid` resolved.

- [ ] **Step 3: Use UUID for temp ids in `_onSendMessage`**

Open `lib/features/messenger/presentation/bloc/messenger_bloc.dart`. Find `_onSendMessage` handler — search for `temp_` (`grep -n "temp_" lib/features/messenger/presentation/bloc/messenger_bloc.dart`). Replace the temp-id assignment:

Before:
```dart
final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
```

After:
```dart
import 'package:uuid/uuid.dart';   // add at top of file if not already present
// ...
final tempId = 'temp_${const Uuid().v4()}';
```

The `temp_` prefix is preserved so Phase 1g `_onMessageReceived` `m.id.startsWith('temp_')` dedup still works. Only the suffix changes from millisecond timestamp to UUID v4.

- [ ] **Step 4: Run existing bloc tests**

```
flutter test test/messenger/messenger_bloc_test.dart
```
Expected: all tests still pass — temp_* matching is by prefix, not exact format.

- [ ] **Step 5: Commit**

```bash
git add pubspec.yaml pubspec.lock lib/features/messenger/presentation/bloc/messenger_bloc.dart
git commit -m "mesh(2): switch temp_ ids to UUID v4 suffix; add uuid dep

Phase 2 group fanout requires unique clientTempIds: two senders in the
same group emitting in the same millisecond would collide under the
old temp_<millis> scheme. UUID v4 collision probability is negligible.
Temp_* prefix preserved so Phase 1g pending-removal heuristic still
matches. No behavior change for non-mesh sends."
```

---

## Task 2: Create `Envelope` class

**Files:**
- Create: `lib/core/mesh/services/envelope.dart`
- Test: `test/core/mesh/services/envelope_test.dart`

- [ ] **Step 1: Write failing test**

Create `test/core/mesh/services/envelope_test.dart`:

```dart
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:taler_id_mobile/core/mesh/services/envelope.dart';

void main() {
  group('Envelope', () {
    test('round-trips toJson/fromJson with all fields', () {
      final env = Envelope(
        version: 1,
        type: 'text',
        convId: 'conv-uuid-123',
        clientId: 'client-uuid-456',
        text: 'Привет 👋',
        sentAt: DateTime.parse('2026-04-26T12:34:56.789Z'),
      );
      final json = env.toJson();
      expect(json['v'], 1);
      expect(json['type'], 'text');
      expect(json['convId'], 'conv-uuid-123');
      expect(json['clientId'], 'client-uuid-456');
      expect(json['text'], 'Привет 👋');
      expect(json['sentAt'], '2026-04-26T12:34:56.789Z');
      final decoded = Envelope.fromJson(json);
      expect(decoded.version, 1);
      expect(decoded.type, 'text');
      expect(decoded.convId, 'conv-uuid-123');
      expect(decoded.clientId, 'client-uuid-456');
      expect(decoded.text, 'Привет 👋');
      expect(decoded.sentAt, env.sentAt);
    });

    test('round-trips through JSON string with multibyte characters', () {
      final env = Envelope(
        version: 1,
        type: 'text',
        convId: 'c-1',
        clientId: 'cl-1',
        text: 'эмодзи 🎉 китайский 你好 emoji 🚀',
        sentAt: DateTime.parse('2026-04-26T00:00:00.000Z'),
      );
      final encoded = jsonEncode(env.toJson());
      final decoded = Envelope.fromJson(
          jsonDecode(encoded) as Map<String, dynamic>);
      expect(decoded.text, env.text);
    });

    test('fromJson tolerates unknown extra fields (forward-compat)', () {
      final json = {
        'v': 1,
        'type': 'text',
        'convId': 'c-1',
        'clientId': 'cl-1',
        'text': 'hi',
        'sentAt': '2026-04-26T00:00:00.000Z',
        'futureField': 'ignored',  // simulating a Phase 2.5 extension
      };
      final env = Envelope.fromJson(json);
      expect(env.text, 'hi');
    });

    test('fromJson throws FormatException on missing required field', () {
      expect(
        () => Envelope.fromJson({'v': 1, 'type': 'text'}),
        throwsFormatException,
      );
    });
  });
}
```

- [ ] **Step 2: Run test (must fail with "envelope.dart not found")**

```
flutter test test/core/mesh/services/envelope_test.dart
```
Expected: compile error about missing `envelope.dart`.

- [ ] **Step 3: Implement Envelope**

Create `lib/core/mesh/services/envelope.dart`:

```dart
/// Phase 2 — wire-level envelope wrapping mesh-delivered messages.
///
/// Sent as JSON-encoded plaintext inside a Noise-encrypted data frame.
/// All fields are mandatory in v1; unknown fields are ignored on read for
/// forward compatibility with future envelope versions.
class Envelope {
  /// Envelope-format version (separate from the transport [Frame.version]).
  /// Bump when the field set changes incompatibly.
  final int version;

  /// Logical message type. Phase 2.0 supports only `'text'`. Future:
  /// `'system'` for membership change notices.
  final String type;

  /// Conversation id the message belongs to (server-side conversation UUID).
  /// On receive, used directly to route the message to the correct
  /// chat — bypasses Phase 1f's contact-userId resolveConversationId
  /// fallback (which is 1:1-only).
  final String convId;

  /// Sender-generated UUID v4. Same value passed to the server as
  /// `clientTempId` so receivers can dedup mesh-vs-server-echo (Phase 2.0
  /// uses heuristic dedup, not strict id-match — see spec §7).
  final String clientId;

  /// Message body (UTF-8).
  final String text;

  /// Send timestamp (UTC). Used for receiver-side ordering and the
  /// 10-second dedup window heuristic.
  final DateTime sentAt;

  Envelope({
    required this.version,
    required this.type,
    required this.convId,
    required this.clientId,
    required this.text,
    required this.sentAt,
  });

  Map<String, dynamic> toJson() => {
        'v': version,
        'type': type,
        'convId': convId,
        'clientId': clientId,
        'text': text,
        'sentAt': sentAt.toUtc().toIso8601String(),
      };

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
    return Envelope(
      version: v,
      type: type,
      convId: convId,
      clientId: clientId,
      text: text,
      sentAt: DateTime.parse(sentAt),
    );
  }
}
```

- [ ] **Step 4: Run test (must pass)**

```
flutter test test/core/mesh/services/envelope_test.dart
```
Expected: 4 tests pass.

- [ ] **Step 5: Run full suite**

```
flutter test
```
Expected: all green; 4 new tests added.

- [ ] **Step 6: Commit**

```bash
git add lib/core/mesh/services/envelope.dart \
        test/core/mesh/services/envelope_test.dart
git commit -m "mesh(2): add Envelope wire-level wrapper class

Phase 2 wraps every mesh-delivered message in an encrypted JSON
envelope { v, type, convId, clientId, text, sentAt } so receivers
can route by conversation id (group case) and dedup against the
server echo by (senderId, content, sentAt-window) heuristic."
```

---

## Task 3: Bump `Frame` version 1 → 2

**Files:**
- Modify: `lib/core/mesh/transport/frame.dart`
- Test: `test/core/mesh/transport/frame_test.dart`

- [ ] **Step 1: Update existing frame test (v1 reject + v2 round-trip)**

Open `test/core/mesh/transport/frame_test.dart`. Find any test that constructs a Frame with `version: 1` — these should now expect `FormatException` on decode. Adjust or add new tests:

```dart
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:taler_id_mobile/core/mesh/transport/frame.dart';
import 'package:taler_id_mobile/core/mesh/transport/peer_id.dart';

void main() {
  group('Frame v2', () {
    final srcPk = PeerId.fromHex('a' * 64);

    test('round-trips a v2 data frame with empty payload', () {
      final frame = Frame(
        version: 2,
        type: FrameType.data,
        srcPk: srcPk,
        payload: Uint8List(0),
      );
      final encoded = frame.encode();
      final decoded = Frame.decode(encoded);
      expect(decoded.version, 2);
      expect(decoded.type, FrameType.data);
      expect(decoded.srcPk, srcPk);
      expect(decoded.payload, Uint8List(0));
    });

    test('round-trips a v2 frame with binary payload', () {
      final payload = Uint8List.fromList(List.generate(100, (i) => i & 0xFF));
      final frame = Frame(
        version: 2,
        type: FrameType.handshake,
        srcPk: srcPk,
        payload: payload,
      );
      final decoded = Frame.decode(frame.encode());
      expect(decoded.payload, payload);
    });

    test('decode rejects a v1 frame (legacy mesh peer)', () {
      // Build a v1 data frame manually (bypassing Frame.encode which now writes v2).
      final payload = Uint8List.fromList([1, 2, 3]);
      final bytes = Uint8List(Frame.headerSize + payload.length);
      bytes[0] = 1;  // legacy v1
      bytes[1] = FrameType.data.index;
      bytes[2] = 0;
      bytes[3] = payload.length;
      bytes.setRange(4, 36, srcPk.bytes);
      bytes.setRange(36, bytes.length, payload);

      expect(() => Frame.decode(bytes), throwsFormatException);
    });

    test('encode writes version byte = 2', () {
      final frame = Frame(
        version: 2,
        type: FrameType.data,
        srcPk: srcPk,
        payload: Uint8List(0),
      );
      final encoded = frame.encode();
      expect(encoded[0], 2);
    });
  });
}
```

- [ ] **Step 2: Run test (must fail — Frame.supportedVersion still 1)**

```
flutter test test/core/mesh/transport/frame_test.dart
```
Expected: failures — `decoded.version, 2` expects 2 but decode throws.

- [ ] **Step 3: Bump Frame.supportedVersion**

Edit `lib/core/mesh/transport/frame.dart`. Change:

```dart
  static const int supportedVersion = 1;
```

to:

```dart
  static const int supportedVersion = 2;
```

The `decode` method's existing `if (version != supportedVersion) throw FormatException('Unsupported frame version: $version');` will now correctly reject v1 frames.

- [ ] **Step 4: Run test (must pass)**

```
flutter test test/core/mesh/transport/frame_test.dart
```
Expected: 4 tests pass.

- [ ] **Step 5: Run full suite**

```
flutter test
```
Expected: most tests still green. Some mesh integration tests may break if they hardcode `version: 1` — fix any to use `version: 2` per the new contract.

- [ ] **Step 6: Commit**

```bash
git add lib/core/mesh/transport/frame.dart \
        test/core/mesh/transport/frame_test.dart
git commit -m "mesh(2): bump Frame.supportedVersion 1 → 2

Phase 2 wire format change. Mixed-version cohort during rollout will
not interoperate via mesh; server fanout fully covers (no functional
regression, only mesh latency benefit lost for ~2-3 weeks until
everyone is on v2)."
```

---

## Task 4: `MeshMessagingService` — sendEnvelope + parse envelope on inbound

**Files:**
- Modify: `lib/core/mesh/services/mesh_messaging_service.dart`
- Test: `test/core/mesh/services/mesh_messaging_service_test.dart`

- [ ] **Step 1: Update existing test for envelope-aware send/receive**

Open `test/core/mesh/services/mesh_messaging_service_test.dart`. The current "two services exchange text after handshake" test sends raw text and expects raw text out. Replace it with an envelope round-trip:

```dart
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:taler_id_mobile/core/mesh/crypto/keys/contact_key_store.dart';
import 'package:taler_id_mobile/core/mesh/crypto/keys/mesh_static_key.dart';
import 'package:taler_id_mobile/core/mesh/services/envelope.dart';
import 'package:taler_id_mobile/core/mesh/services/mesh_messaging_service.dart';
import 'package:taler_id_mobile/core/mesh/transport/peer_id.dart';

import '../transport/in_memory_transport.dart';   // existing test helper

void main() {
  group('MeshMessagingService Phase 2 envelope', () {
    test('two services exchange envelope after handshake', () async {
      final aliceKey = await MeshStaticKey.generate();
      final bobKey = await MeshStaticKey.generate();
      final aliceStore = ContactKeyStore()
        ..addContact(
          userPk: PeerId(bobKey.publicKey),
          devicePks: [PeerId(bobKey.publicKey)],
        );
      final bobStore = ContactKeyStore()
        ..addContact(
          userPk: PeerId(aliceKey.publicKey),
          devicePks: [PeerId(aliceKey.publicKey)],
        );
      final pair = InMemoryTransportPair();
      final alice = MeshMessagingService(
        transport: pair.left,
        contactKeyStore: aliceStore,
        myDevicePrivateKey: aliceKey.privateKeyBytes,
        myDevicePublicKey: aliceKey.publicKey,
      );
      final bob = MeshMessagingService(
        transport: pair.right,
        contactKeyStore: bobStore,
        myDevicePrivateKey: bobKey.privateKeyBytes,
        myDevicePublicKey: bobKey.publicKey,
      );
      await alice.start(serviceName: 'alice');
      await bob.start(serviceName: 'bob');

      final received = <InboundEnvelope>[];
      bob.inbound.listen(received.add);

      final envelope = Envelope(
        version: 1,
        type: 'text',
        convId: 'conv-test',
        clientId: 'client-abc',
        text: 'Привет from Alice 👋',
        sentAt: DateTime.parse('2026-04-26T12:00:00.000Z'),
      );
      await alice.sendEnvelope(
        toUserPk: PeerId(bobKey.publicKey),
        envelope: envelope,
      );
      await Future<void>.delayed(const Duration(milliseconds: 100));

      expect(received, hasLength(1));
      final got = received.first;
      expect(got.fromUserPk, PeerId(aliceKey.publicKey));
      expect(got.envelope.text, envelope.text);
      expect(got.envelope.convId, envelope.convId);
      expect(got.envelope.clientId, envelope.clientId);
      expect(got.envelope.sentAt, envelope.sentAt);
    });
  });
}
```

If `InMemoryTransportPair` helper does not exist at `test/core/mesh/transport/in_memory_transport.dart`, check the existing test for the previous helper class name (likely `_TestTransport` or similar) and adapt the import.

- [ ] **Step 2: Run test (must fail — sendEnvelope and InboundEnvelope don't exist)**

```
flutter test test/core/mesh/services/mesh_messaging_service_test.dart
```
Expected: compile errors about `sendEnvelope` and `InboundEnvelope`.

- [ ] **Step 3: Modify MeshMessagingService**

Edit `lib/core/mesh/services/mesh_messaging_service.dart`:

3a. Replace the `InboundMessage` class declaration with:

```dart
/// Phase 2 — replaces InboundMessage; carries the full envelope payload
/// so the messenger layer routes by `envelope.convId` (group support).
class InboundEnvelope {
  final PeerId fromUserPk;
  final Envelope envelope;
  InboundEnvelope({required this.fromUserPk, required this.envelope});
}
```

Add the import at the top:
```dart
import 'envelope.dart';
```

3b. Change the stream controller declaration:

Before:
```dart
final _inboundCtrl = StreamController<InboundMessage>.broadcast();
```

After:
```dart
final _inboundCtrl = StreamController<InboundEnvelope>.broadcast();
```

Change the public getter to expose `Stream<InboundEnvelope>`.

3c. Replace `sendText` method body. Old signature:

```dart
Future<void> sendText({required PeerId toUserPk, required String text}) async {
  ...
  final payload = Uint8List.fromList(utf8.encode(text));
  ...
}
```

Replace with:

```dart
/// Phase 2 — envelope-aware send. Wraps the message contents in a JSON
/// envelope before encryption so receivers can route by conversationId.
Future<void> sendEnvelope({
  required PeerId toUserPk,
  required Envelope envelope,
}) async {
  final devicePk = toUserPk;
  debugPrint('[mesh-send] sendEnvelope to=${devicePk.toHex().substring(0, 12)}... convId=${envelope.convId} clientId=${envelope.clientId} known=${contactKeyStore.isKnownDevice(devicePk)}');
  if (!contactKeyStore.isKnownDevice(devicePk)) {
    throw StateError('Unknown contact device: ${devicePk.toHex()}');
  }
  final state = _peerStates.putIfAbsent(devicePk, () => _PeerState());
  if (state.session == null && state.handshake == null && !state.initiating) {
    state.initiating = true;
    state.sessionEstablished = Completer<void>();
    debugPrint('[mesh-send] initiating new handshake');
    try {
      await _initiateHandshake(devicePk, state);
    } catch (e) {
      state.initiating = false;
      rethrow;
    }
  }
  if (state.session == null) {
    debugPrint('[mesh-send] awaiting handshake completion (10s timeout)');
    try {
      await state.sessionEstablished!.future
          .timeout(const Duration(seconds: 10));
    } on TimeoutException {
      debugPrint('[mesh-send] handshake TIMEOUT');
      throw TimeoutException('handshake did not complete');
    }
  }
  debugPrint('[mesh-send] session established, encrypting envelope');
  final plaintext = Uint8List.fromList(utf8.encode(jsonEncode(envelope.toJson())));
  final ct = await state.session!.encrypt(plaintext);
  await _sendFrame(devicePk, FrameType.data, ct);
  debugPrint('[mesh-send] data frame sent');
}
```

The `dart:convert` import (`jsonEncode`) is likely already present. If not, add `import 'dart:convert';` at the top.

3d. Replace the `_onInboundFrame` `data` branch. Find:

```dart
if (frame.type == FrameType.data) {
  if (state.session == null) { ... }
  try {
    final pt = await state.session!.decrypt(frame.bytes);
    _inboundCtrl.add(InboundMessage(
      fromUserPk: srcDevice,
      text: utf8.decode(pt),
    ));
  } catch (e) { ... }
  return;
}
```

Replace with:

```dart
if (frame.type == FrameType.data) {
  if (state.session == null) {
    debugPrint('[mesh-frame] data frame but no session — dropped');
    return;
  }
  try {
    final pt = await state.session!.decrypt(frame.bytes);
    final envelopeJson = jsonDecode(utf8.decode(pt)) as Map<String, dynamic>;
    final envelope = Envelope.fromJson(envelopeJson);
    debugPrint('[mesh-frame] decrypted envelope, emitting InboundEnvelope convId=${envelope.convId}');
    _inboundCtrl.add(InboundEnvelope(
      fromUserPk: srcDevice,
      envelope: envelope,
    ));
  } on FormatException catch (e) {
    debugPrint('[mesh-frame] envelope decode failed: $e');
  } catch (e) {
    debugPrint('[mesh-frame] decrypt failed: $e');
  }
  return;
}
```

- [ ] **Step 4: Run test (must pass)**

```
flutter test test/core/mesh/services/mesh_messaging_service_test.dart
```
Expected: envelope round-trip test passes.

- [ ] **Step 5: Run full suite**

```
flutter test
```
Expected: failures appear in `mesh_messenger_adapter_test.dart` (still expects InboundMessage). Those fix in Task 5.

- [ ] **Step 6: Commit**

```bash
git add lib/core/mesh/services/mesh_messaging_service.dart \
        test/core/mesh/services/mesh_messaging_service_test.dart
git commit -m "mesh(2): MeshMessagingService sends/receives Envelope JSON

sendText replaced by sendEnvelope; data frame plaintext is now
jsonEncode(envelope.toJson()). InboundMessage replaced by
InboundEnvelope carrying the full envelope so adapter can route by
envelope.convId for group chats. Phase 1 1:1 still works — same
Noise IK stack, just wraps the text in JSON before encrypting."
```

---

## Task 5: `MeshMessengerAdapter` — envelope-aware

**Files:**
- Modify: `lib/features/messenger/data/services/mesh_messenger_adapter.dart`
- Test: `test/features/messenger/data/services/mesh_messenger_adapter_test.dart`

- [ ] **Step 1: Update tests to use envelope**

Open `test/features/messenger/data/services/mesh_messenger_adapter_test.dart`. The existing tests instantiate the adapter with a fake `meshSendText` callback and a fake `meshInbound` stream of `InboundMessage`. Update them to use `InboundEnvelope` and `meshSendEnvelope`. Replace whole test body:

```dart
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:taler_id_mobile/core/mesh/services/envelope.dart';
import 'package:taler_id_mobile/core/mesh/services/mesh_messaging_service.dart';
import 'package:taler_id_mobile/core/mesh/transport/peer_id.dart';
import 'package:taler_id_mobile/features/messenger/data/services/mesh_messenger_adapter.dart';

void main() {
  group('MeshMessengerAdapter Phase 2', () {
    late StreamController<InboundEnvelope> meshInboundCtrl;
    final List<({PeerId toUserPk, Envelope envelope})> sentCalls = [];
    final List<Map<String, dynamic>> persisted = [];
    final List<AdaptedInboundMessage> emitted = [];
    late MeshMessengerAdapter adapter;
    late StreamSubscription sub;

    setUp(() {
      meshInboundCtrl = StreamController<InboundEnvelope>.broadcast();
      sentCalls.clear();
      persisted.clear();
      emitted.clear();
      adapter = MeshMessengerAdapter(
        meshSendEnvelope: ({required toUserPk, required envelope}) async {
          sentCalls.add((toUserPk: toUserPk, envelope: envelope));
        },
        meshInbound: meshInboundCtrl.stream,
        lookupUserByDevice: (devicePk) =>
            devicePk == PeerId.fromHex('b' * 64) ? PeerId.fromHex('b' * 64) : null,
        contactUserIdForUserPk: (userPk) =>
            userPk == PeerId.fromHex('b' * 64) ? 'contact-1' : null,
        currentUserIdProvider: () => 'me-user-id',
        persistLocal: persisted.add,
      );
      sub = adapter.inbound.listen(emitted.add);
      adapter.start();
    });

    tearDown(() async {
      await sub.cancel();
      await adapter.dispose();
      await meshInboundCtrl.close();
    });

    test('inbound envelope routes via envelope.convId (group case)', () async {
      meshInboundCtrl.add(InboundEnvelope(
        fromUserPk: PeerId.fromHex('b' * 64),
        envelope: Envelope(
          version: 1,
          type: 'text',
          convId: 'group-conv-42',
          clientId: 'cl-1',
          text: 'hi group',
          sentAt: DateTime.parse('2026-04-26T12:00:00.000Z'),
        ),
      ));
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(emitted, hasLength(1));
      expect(emitted.first.contactUserId, 'contact-1');
      expect(emitted.first.conversationId, 'group-conv-42');
      expect(emitted.first.text, 'hi group');
      expect(persisted, hasLength(1));
      expect(persisted.first['id'], 'cl-1');
      expect(persisted.first['transport'], 'mesh');
      expect(persisted.first['conversationId'], 'group-conv-42');
      expect(persisted.first['senderId'], 'contact-1');
    });

    test('inbound from unknown device drops silently', () async {
      meshInboundCtrl.add(InboundEnvelope(
        fromUserPk: PeerId.fromHex('c' * 64),
        envelope: Envelope(
          version: 1,
          type: 'text',
          convId: 'whatever',
          clientId: 'cl-x',
          text: 'should be dropped',
          sentAt: DateTime.parse('2026-04-26T12:00:00.000Z'),
        ),
      ));
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(emitted, isEmpty);
      expect(persisted, isEmpty);
    });

    test('sendEnvelopeToPeer wraps params and dispatches to messaging', () async {
      final envelope = Envelope(
        version: 1,
        type: 'text',
        convId: 'group-conv-42',
        clientId: 'cl-out',
        text: 'group send',
        sentAt: DateTime.parse('2026-04-26T12:00:00.000Z'),
      );
      await adapter.sendEnvelopeToPeer(
        peerDevicePk: PeerId.fromHex('a' * 64),
        contactUserId: 'contact-X',
        envelope: envelope,
      );
      expect(sentCalls, hasLength(1));
      expect(sentCalls.first.toUserPk, PeerId.fromHex('a' * 64));
      expect(sentCalls.first.envelope.clientId, 'cl-out');
      expect(persisted, hasLength(1));
      expect(persisted.first['id'], 'cl-out');
      expect(persisted.first['conversationId'], 'group-conv-42');
      expect(persisted.first['senderId'], 'me-user-id');
      expect(persisted.first['transport'], 'mesh');
      expect(persisted.first['direction'], 'outbound');
    });
  });
}
```

- [ ] **Step 2: Run test (must fail — adapter API mismatch)**

```
flutter test test/features/messenger/data/services/mesh_messenger_adapter_test.dart
```
Expected: compile errors about `meshSendEnvelope`, `sendEnvelopeToPeer`, `InboundEnvelope`.

- [ ] **Step 3: Rewrite MeshMessengerAdapter**

Edit `lib/features/messenger/data/services/mesh_messenger_adapter.dart`. Replace the entire file:

```dart
import 'dart:async';

import 'package:flutter/foundation.dart' show debugPrint;

import '../../../../core/mesh/services/envelope.dart';
import '../../../../core/mesh/services/mesh_messaging_service.dart';
import '../../../../core/mesh/transport/peer_id.dart';

class AdaptedInboundMessage {
  final String contactUserId;
  final String conversationId;
  final String text;
  final DateTime receivedAt;
  final String clientId;
  AdaptedInboundMessage({
    required this.contactUserId,
    required this.conversationId,
    required this.text,
    required this.receivedAt,
    required this.clientId,
  });
}

class AdaptedOutboundMessage {
  final String id;
  final String conversationId;
  final String contactUserId;
  final String? clientTempId;
  final String text;
  final DateTime sentAt;
  AdaptedOutboundMessage({
    required this.id,
    required this.conversationId,
    required this.contactUserId,
    required this.clientTempId,
    required this.text,
    required this.sentAt,
  });
}

/// Phase 2 — envelope-aware bridge between MeshMessagingService and the
/// messenger layer. Inbound: routes by envelope.convId (works for both
/// 1:1 and group). Outbound: per-peer fanout, single AdaptedOutboundMessage
/// emitted per logical send (NOT per peer) so MessengerBloc replaces the
/// optimistic temp_clientId entry with one mesh-out entry.
class MeshMessengerAdapter {
  final Future<void> Function({required PeerId toUserPk, required Envelope envelope})
      meshSendEnvelope;
  final Stream<InboundEnvelope> meshInbound;
  final PeerId? Function(PeerId devicePk) lookupUserByDevice;
  final String? Function(PeerId userPk) contactUserIdForUserPk;
  final String? Function() currentUserIdProvider;
  final void Function(Map<String, dynamic> entry) persistLocal;

  static const String _kTransport = 'mesh';

  final _ctrl = StreamController<AdaptedInboundMessage>.broadcast();
  final _outCtrl = StreamController<AdaptedOutboundMessage>.broadcast();
  StreamSubscription<InboundEnvelope>? _sub;

  MeshMessengerAdapter({
    required this.meshSendEnvelope,
    required this.meshInbound,
    required this.lookupUserByDevice,
    required this.contactUserIdForUserPk,
    required this.currentUserIdProvider,
    required this.persistLocal,
  });

  Stream<AdaptedInboundMessage> get inbound => _ctrl.stream;
  Stream<AdaptedOutboundMessage> get outbound => _outCtrl.stream;

  void start() {
    _sub ??= meshInbound.listen(_onInbound);
  }

  Future<void> stop() async {
    await _sub?.cancel();
    _sub = null;
  }

  void _onInbound(InboundEnvelope inbound) {
    final userPk = lookupUserByDevice(inbound.fromUserPk);
    if (userPk == null) {
      debugPrint('[mesh-adapter] inbound from unknown devicePk, dropped');
      return;
    }
    final contactUserId = contactUserIdForUserPk(userPk);
    if (contactUserId == null) {
      debugPrint('[mesh-adapter] inbound from unknown userPk, dropped');
      return;
    }
    final convId = inbound.envelope.convId;
    final clientId = inbound.envelope.clientId;
    persistLocal({
      'id': clientId,
      'conversationId': convId,
      'contactUserId': contactUserId,
      'senderId': contactUserId,
      'content': inbound.envelope.text,
      'transport': _kTransport,
      'direction': 'inbound',
      'sentAt': inbound.envelope.sentAt.toUtc().toIso8601String(),
    });
    _ctrl.add(AdaptedInboundMessage(
      contactUserId: contactUserId,
      conversationId: convId,
      text: inbound.envelope.text,
      receivedAt: inbound.envelope.sentAt,
      clientId: clientId,
    ));
  }

  /// Phase 2 — single-peer mesh send. Caller (MessengerRepositoryImpl)
  /// invokes this once per visible+known peer in the group.
  Future<void> sendEnvelopeToPeer({
    required PeerId peerDevicePk,
    required String contactUserId,
    required Envelope envelope,
  }) async {
    await meshSendEnvelope(toUserPk: peerDevicePk, envelope: envelope);
    final myUserId = currentUserIdProvider();
    if (myUserId == null || myUserId.isEmpty) return;
    persistLocal({
      'id': envelope.clientId,
      'conversationId': envelope.convId,
      'contactUserId': contactUserId,
      'senderId': myUserId,
      'content': envelope.text,
      'transport': _kTransport,
      'direction': 'outbound',
      'sentAt': envelope.sentAt.toUtc().toIso8601String(),
    });
  }

  /// Phase 2 — emit a single AdaptedOutboundMessage for a logical send
  /// regardless of how many peers received it via mesh. Caller invokes this
  /// once per logical send AFTER all per-peer sendEnvelopeToPeer calls
  /// complete (or in fire-and-forget mode, after at least one succeeded).
  void emitOutbound(AdaptedOutboundMessage event) {
    _outCtrl.add(event);
  }

  Future<void> dispose() async {
    await stop();
    await _ctrl.close();
    await _outCtrl.close();
  }
}
```

The key changes vs Phase 1:
- `meshSendText` → `meshSendEnvelope` (takes Envelope, not raw text).
- `sendMessage` (per-peer with implicit envelope construction) → `sendEnvelopeToPeer` (caller constructs envelope; adapter just dispatches + persists).
- New explicit `emitOutbound` method — caller (repo) invokes once per logical send to drive Phase 1h's `MeshMessageSent` event.
- Inbound branch reads `envelope.convId` directly (no resolveConversationId callback needed for routing — Phase 1f's `meshOnly:*` fallback was 1:1-only).

Note: `resolveConversationId` parameter is gone. Phase 1f's logic was specific to the 1:1 case where the receiver had no convId in the wire payload. Phase 2 envelopes always carry the convId, so the fallback is unnecessary.

- [ ] **Step 4: Run test (must pass)**

```
flutter test test/features/messenger/data/services/mesh_messenger_adapter_test.dart
```
Expected: 3 tests pass.

- [ ] **Step 5: Run full suite**

```
flutter test
```
Expected: failures shift to `messenger_repository_*` tests and DI wiring. Those fix in Task 6/7.

- [ ] **Step 6: Commit**

```bash
git add lib/features/messenger/data/services/mesh_messenger_adapter.dart \
        test/features/messenger/data/services/mesh_messenger_adapter_test.dart
git commit -m "mesh(2): adapter routes by envelope.convId; sendEnvelopeToPeer

Phase 2 InboundEnvelope replaces InboundMessage: routing happens via
envelope.convId, which works uniformly for 1:1 and group. Phase 1f's
resolveConversationId callback (1:1-only fallback) is removed.

sendEnvelopeToPeer per-peer signature replaces sendMessage; outbound
event emission is now an explicit emitOutbound call so the repository
can fire ONE AdaptedOutboundMessage per logical send (not per peer)."
```

---

## Task 6: `MessengerRepositoryImpl` — group fanout

**Files:**
- Modify: `lib/features/messenger/data/repositories/messenger_repository_impl.dart`
- Modify: `lib/core/di/service_locator.dart` (constructor signature update; TransportSelector still removed in Task 7)
- Test: `test/features/messenger/data/repositories/messenger_repository_impl_group_test.dart` (NEW)

- [ ] **Step 1: Write the new group fanout test**

Create `test/features/messenger/data/repositories/messenger_repository_impl_group_test.dart`:

```dart
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:taler_id_mobile/core/mesh/crypto/keys/contact_key_store_hive.dart';
import 'package:taler_id_mobile/core/mesh/services/envelope.dart';
import 'package:taler_id_mobile/core/mesh/transport/peer_id.dart';
import 'package:taler_id_mobile/core/services/messenger_cache_service.dart';
import 'package:taler_id_mobile/core/services/pending_message_service.dart';
import 'package:taler_id_mobile/features/messenger/data/datasources/messenger_remote_datasource.dart';
import 'package:taler_id_mobile/features/messenger/data/repositories/messenger_repository_impl.dart';
import 'package:taler_id_mobile/features/messenger/data/services/mesh_messenger_adapter.dart';
import 'package:taler_id_mobile/features/messenger/domain/entities/conversation_entity.dart';

class _FakeRemote implements MessengerRemoteDataSource {
  final List<({String convId, String content, String? clientTempId})>
      sentCalls = [];
  bool isConnectedValue = true;

  @override
  bool get isSocketConnected => isConnectedValue;

  @override
  void sendMessage(String convId, String content,
      {String? fileUrl, String? fileName, int? fileSize, String? fileType,
      String? s3Key, String? thumbnailSmallUrl, String? thumbnailMediumUrl,
      String? thumbnailLargeUrl, String? fileRecordId, String? topicId,
      String? clientTempId}) {
    sentCalls.add((convId: convId, content: content, clientTempId: clientTempId));
  }

  @override
  dynamic noSuchMethod(Invocation i) => null;
}

class _FakeAdapter implements MeshMessengerAdapter {
  final List<({PeerId peerDevicePk, String contactUserId, Envelope envelope})>
      perPeerCalls = [];
  final List<AdaptedOutboundMessage> outboundEvents = [];

  @override
  Future<void> sendEnvelopeToPeer({
    required PeerId peerDevicePk,
    required String contactUserId,
    required Envelope envelope,
  }) async {
    perPeerCalls.add((
      peerDevicePk: peerDevicePk,
      contactUserId: contactUserId,
      envelope: envelope,
    ));
  }

  @override
  void emitOutbound(AdaptedOutboundMessage event) =>
      outboundEvents.add(event);

  @override
  dynamic noSuchMethod(Invocation i) =>
      throw UnimplementedError('not used: ${i.memberName}');
}

class _FakePending implements PendingMessageService {
  final List<String> removed = [];
  @override
  Future<void> remove(String tempId) async => removed.add(tempId);
  @override
  dynamic noSuchMethod(Invocation i) => null;
}

class _FakeCache implements MessengerCacheService {
  final Map<String, ConversationEntity> _conversations = {};
  void seedConversation(ConversationEntity c) => _conversations[c.id] = c;
  @override
  ConversationEntity? getConversationById(String id) => _conversations[id];
  @override
  dynamic noSuchMethod(Invocation i) => null;
}

class _FakeContactKeyStore implements HiveContactKeyStore {
  final Map<String, PeerId> _userIdToUserPk = {};
  final Map<PeerId, List<PeerId>> _userPkToDevices = {};
  void seedContact(String userId, PeerId userPk, List<PeerId> devices) {
    _userIdToUserPk[userId] = userPk;
    _userPkToDevices[userPk] = devices;
  }
  @override
  PeerId? userPkForContactUserId(String userId) => _userIdToUserPk[userId];
  @override
  List<PeerId> devicesFor(PeerId userPk) =>
      _userPkToDevices[userPk] ?? const [];
  @override
  dynamic noSuchMethod(Invocation i) => null;
}

void main() {
  late _FakeRemote remote;
  late _FakeAdapter adapter;
  late _FakePending pending;
  late _FakeCache cache;
  late _FakeContactKeyStore store;

  setUp(() {
    remote = _FakeRemote();
    adapter = _FakeAdapter();
    pending = _FakePending();
    cache = _FakeCache();
    store = _FakeContactKeyStore();
  });

  MessengerRepositoryImpl buildRepo({
    required Set<String> visibleUserIds,
    String? myUserId = 'me-id',
  }) {
    return MessengerRepositoryImpl(
      remote,
      meshAdapter: adapter,
      pending: pending,
      cache: cache,
      hiveContactStore: store,
      isPeerVisibleForContactUserId: visibleUserIds.contains,
      currentUserIdProvider: () => myUserId,
    );
  }

  group('Phase 2 group fanout in sendMessage', () {
    test('group with all visible+known peers — server send + N pairwise mesh',
        () async {
      cache.seedConversation(ConversationEntity(
        id: 'group-conv',
        type: 'GROUP',
        participantIds: ['me-id', 'p1', 'p2', 'p3'],
      ));
      final p1Pk = PeerId.fromHex('1' * 64);
      final p2Pk = PeerId.fromHex('2' * 64);
      final p3Pk = PeerId.fromHex('3' * 64);
      store.seedContact('p1', p1Pk, [p1Pk]);
      store.seedContact('p2', p2Pk, [p2Pk]);
      store.seedContact('p3', p3Pk, [p3Pk]);

      final repo = buildRepo(visibleUserIds: {'p1', 'p2', 'p3'});
      repo.sendMessage('group-conv', 'hi group', clientTempId: 'temp_X');
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(remote.sentCalls, hasLength(1));
      expect(remote.sentCalls.first.clientTempId, 'temp_X');
      expect(adapter.perPeerCalls, hasLength(3));
      final calledUsers =
          adapter.perPeerCalls.map((c) => c.contactUserId).toSet();
      expect(calledUsers, {'p1', 'p2', 'p3'});
      expect(adapter.outboundEvents, hasLength(1),
          reason: 'one logical send → one AdaptedOutboundMessage');
      expect(adapter.outboundEvents.first.id, 'temp_X');
    });

    test('group with mixed visibility — visible get mesh, server still hit',
        () async {
      cache.seedConversation(ConversationEntity(
        id: 'group-conv',
        type: 'GROUP',
        participantIds: ['me-id', 'p1', 'p2', 'p3'],
      ));
      final p1Pk = PeerId.fromHex('1' * 64);
      final p2Pk = PeerId.fromHex('2' * 64);
      final p3Pk = PeerId.fromHex('3' * 64);
      store.seedContact('p1', p1Pk, [p1Pk]);
      store.seedContact('p2', p2Pk, [p2Pk]);
      store.seedContact('p3', p3Pk, [p3Pk]);

      final repo = buildRepo(visibleUserIds: {'p1'});  // only p1 visible
      repo.sendMessage('group-conv', 'hi mixed', clientTempId: 'temp_Y');
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(remote.sentCalls, hasLength(1));
      expect(adapter.perPeerCalls, hasLength(1));
      expect(adapter.perPeerCalls.first.contactUserId, 'p1');
    });

    test('group, no visible peers — server-only', () async {
      cache.seedConversation(ConversationEntity(
        id: 'group-conv',
        type: 'GROUP',
        participantIds: ['me-id', 'p1', 'p2'],
      ));
      final repo = buildRepo(visibleUserIds: const {});

      repo.sendMessage('group-conv', 'no mesh', clientTempId: 'temp_Z');
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(remote.sentCalls, hasLength(1));
      expect(adapter.perPeerCalls, isEmpty);
    });

    test('socket offline + visible peers — mesh-only, no server send',
        () async {
      cache.seedConversation(ConversationEntity(
        id: 'group-conv',
        type: 'GROUP',
        participantIds: ['me-id', 'p1'],
      ));
      final p1Pk = PeerId.fromHex('1' * 64);
      store.seedContact('p1', p1Pk, [p1Pk]);
      remote.isConnectedValue = false;

      final repo = buildRepo(visibleUserIds: {'p1'});
      repo.sendMessage('group-conv', 'mesh only', clientTempId: 'temp_W');
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(remote.sentCalls, isEmpty,
          reason: 'socket offline → server send skipped');
      expect(adapter.perPeerCalls, hasLength(1));
    });

    test('1:1 with visible peer + connected — both server and mesh', () async {
      cache.seedConversation(ConversationEntity(
        id: 'direct-conv',
        type: 'DIRECT',
        participantIds: ['me-id', 'p1'],
        otherUserId: 'p1',
      ));
      final p1Pk = PeerId.fromHex('1' * 64);
      store.seedContact('p1', p1Pk, [p1Pk]);

      final repo = buildRepo(visibleUserIds: {'p1'});
      repo.sendMessage('direct-conv', 'hi 1:1', clientTempId: 'temp_D');
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(remote.sentCalls, hasLength(1));
      expect(adapter.perPeerCalls, hasLength(1));
    });

    test('group > 50 visible peers — mesh skipped, server-only', () async {
      final participants =
          List.generate(60, (i) => 'p$i')..insert(0, 'me-id');
      cache.seedConversation(ConversationEntity(
        id: 'huge-conv',
        type: 'GROUP',
        participantIds: participants,
      ));
      final visible = <String>{};
      for (var i = 0; i < 60; i++) {
        final pk = PeerId.fromHex(i.toString().padLeft(64, '0').substring(0, 64));
        store.seedContact('p$i', pk, [pk]);
        visible.add('p$i');
      }
      final repo = buildRepo(visibleUserIds: visible);

      repo.sendMessage('huge-conv', 'big group', clientTempId: 'temp_BIG');
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(remote.sentCalls, hasLength(1));
      expect(adapter.perPeerCalls, isEmpty,
          reason: 'over 50 mesh-eligible peers → mesh skipped');
    });
  });
}
```

- [ ] **Step 2: Run test (must fail — repo signature mismatch)**

```
flutter test test/features/messenger/data/repositories/messenger_repository_impl_group_test.dart
```
Expected: compile errors about constructor params (`meshAdapter`, `pending`, `cache`, `hiveContactStore`, `isPeerVisibleForContactUserId`, `currentUserIdProvider`).

- [ ] **Step 3: Rewrite MessengerRepositoryImpl.sendMessage**

Edit `lib/features/messenger/data/repositories/messenger_repository_impl.dart`. The current constructor takes `selector: TransportSelector` and `resolveContact: ConversationContactResolver`. Replace with the Phase 2 signature:

3a. Constructor:

```dart
class MessengerRepositoryImpl implements IMessengerRepository {
  final MessengerRemoteDataSource _remote;
  final MeshMessengerAdapter _meshAdapter;
  final PendingMessageService _pending;
  final MessengerCacheService _cache;
  final HiveContactKeyStore _hiveContactStore;
  final bool Function(String contactUserId) _isPeerVisibleForContactUserId;
  final String? Function() _currentUserIdProvider;

  static const int _meshGroupSizeCap = 50;

  MessengerRepositoryImpl(
    this._remote, {
    required MeshMessengerAdapter meshAdapter,
    required PendingMessageService pending,
    required MessengerCacheService cache,
    required HiveContactKeyStore hiveContactStore,
    required bool Function(String) isPeerVisibleForContactUserId,
    required String? Function() currentUserIdProvider,
  })  : _meshAdapter = meshAdapter,
        _pending = pending,
        _cache = cache,
        _hiveContactStore = hiveContactStore,
        _isPeerVisibleForContactUserId = isPeerVisibleForContactUserId,
        _currentUserIdProvider = currentUserIdProvider;
```

3b. Replace `sendMessage` body. The old implementation switched on `TransportChoice` (server/offline/mesh). The new flow runs server + mesh in parallel:

```dart
@override
void sendMessage(
  String conversationId,
  String content, {
  String? fileUrl,
  String? fileName,
  int? fileSize,
  String? fileType,
  String? s3Key,
  String? thumbnailSmallUrl,
  String? thumbnailMediumUrl,
  String? thumbnailLargeUrl,
  String? fileRecordId,
  String? topicId,
  String? clientTempId,
}) {
  // Always-on server path when socket is connected. Server fans out to all
  // members of the conversation (1:1 echo or group fanout).
  if (_remote.isSocketConnected) {
    _remote.sendMessage(
      conversationId,
      content,
      fileUrl: fileUrl,
      fileName: fileName,
      fileSize: fileSize,
      fileType: fileType,
      s3Key: s3Key,
      thumbnailSmallUrl: thumbnailSmallUrl,
      thumbnailMediumUrl: thumbnailMediumUrl,
      thumbnailLargeUrl: thumbnailLargeUrl,
      fileRecordId: fileRecordId,
      topicId: topicId,
      clientTempId: clientTempId,
    );
  }
  // (When socket is offline, MessengerBloc's _resendPending will retry on
  //  reconnect — Phase 1g behaviour preserved.)

  // Phase 2 mesh fanout — text-only (attachments stay server-side).
  if (fileUrl != null || s3Key != null) return;
  // ignore: unawaited_futures
  _meshFanout(
    conversationId: conversationId,
    content: content,
    clientTempId: clientTempId,
  );
}

Future<void> _meshFanout({
  required String conversationId,
  required String content,
  required String? clientTempId,
}) async {
  final conv = _cache.getConversationById(conversationId);
  if (conv == null) {
    debugPrint('[mesh-fanout] no cached conversation for $conversationId, skipping mesh');
    return;
  }
  final myUserId = _currentUserIdProvider();
  final eligible = _meshEligibleParticipants(conv, myUserId);
  if (eligible.isEmpty) {
    debugPrint('[mesh-fanout] no eligible peers for $conversationId, server-only');
    return;
  }
  if (eligible.length > _meshGroupSizeCap) {
    debugPrint('[mesh-fanout] group size ${eligible.length} > $_meshGroupSizeCap, mesh skipped (server-only)');
    return;
  }

  final clientId = clientTempId ?? const Uuid().v4();
  final now = DateTime.now().toUtc();
  final envelope = Envelope(
    version: 1,
    type: 'text',
    convId: conversationId,
    clientId: clientId,
    text: content,
    sentAt: now,
  );

  // Per-peer fire-and-forget; one peer failure does not block others.
  for (final peer in eligible) {
    // ignore: unawaited_futures
    _meshAdapter.sendEnvelopeToPeer(
      peerDevicePk: peer.devicePk,
      contactUserId: peer.userId,
      envelope: envelope,
    ).catchError((Object e) {
      debugPrint('[mesh-fanout] send to ${peer.userId} failed: $e');
    });
  }

  // ONE outbound event per logical send (not per peer). Phase 1h's
  // MeshMessageSent handler in MessengerBloc replaces temp_clientId with
  // a mesh-out MessageEntity exactly once.
  if (clientTempId != null) {
    _meshAdapter.emitOutbound(AdaptedOutboundMessage(
      id: clientId,
      conversationId: conversationId,
      contactUserId: eligible.first.userId,  // representative; not used by bloc handler
      clientTempId: clientTempId,
      text: content,
      sentAt: now,
    ));
    // Clear pending since the message is now persisted as mesh-out.
    await _pending.remove(clientTempId);
  }
}

List<_EligiblePeer> _meshEligibleParticipants(
    ConversationEntity conv, String? myUserId) {
  final out = <_EligiblePeer>[];
  for (final p in conv.participantIds) {
    if (p == myUserId) continue;
    if (!_isPeerVisibleForContactUserId(p)) continue;
    final userPk = _hiveContactStore.userPkForContactUserId(p);
    if (userPk == null) continue;
    final devices = _hiveContactStore.devicesFor(userPk);
    if (devices.isEmpty) continue;
    out.add(_EligiblePeer(userId: p, devicePk: devices.first));
  }
  return out;
}
```

Add at the bottom of the file:

```dart
class _EligiblePeer {
  final String userId;
  final PeerId devicePk;
  _EligiblePeer({required this.userId, required this.devicePk});
}
```

Add imports at top:
```dart
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:uuid/uuid.dart';

import '../../../../core/mesh/crypto/keys/contact_key_store_hive.dart';
import '../../../../core/mesh/services/envelope.dart';
import '../../../../core/mesh/transport/peer_id.dart';
import '../../../../core/services/messenger_cache_service.dart';
import '../../../../core/services/pending_message_service.dart';
import '../../domain/entities/conversation_entity.dart';
```

Remove the now-obsolete `import` for `transport_selector.dart` and the `ConversationContactResolver` typedef (Task 7 deletes it).

3c. Update `meshOutboundStream` getter (it now reads from the adapter's outbound stream, same as Phase 1h, just with the renamed method types):

```dart
@override
Stream<MeshOutboundMessage> get meshOutboundStream =>
    _meshAdapter.outbound.map(
      (o) => MeshOutboundMessage(
        id: o.id,
        conversationId: o.conversationId,
        contactUserId: o.contactUserId,
        clientTempId: o.clientTempId,
        text: o.text,
        sentAt: o.sentAt,
      ),
    );
```

(No change to this getter from Phase 1h, but verify it compiles after the adapter rewrite.)

- [ ] **Step 4: Update DI in service_locator.dart (constructor signature only — TransportSelector removal in Task 7)**

Edit `lib/core/di/service_locator.dart`. Find the `MessengerRepositoryImpl` registration:

Before:
```dart
sl.registerLazySingleton<IMessengerRepository>(
  () => MessengerRepositoryImpl(
    sl<MessengerRemoteDataSource>(),
    selector: sl<TransportSelector>(),
    meshAdapter: sl<MeshMessengerAdapter>()..start(),
    resolveContact: _resolveConversationContact,
    pending: sl<PendingMessageService>(),
  ),
);
```

After:
```dart
sl.registerLazySingleton<IMessengerRepository>(
  () => MessengerRepositoryImpl(
    sl<MessengerRemoteDataSource>(),
    meshAdapter: sl<MeshMessengerAdapter>()..start(),
    pending: sl<PendingMessageService>(),
    cache: sl<MessengerCacheService>(),
    hiveContactStore: sl<HiveContactKeyStore>(),
    isPeerVisibleForContactUserId: (uid) {
      try {
        return sl<MeshStatusBloc>().state.visibilityByContactUserId[uid] ?? false;
      } catch (_) {
        return false;
      }
    },
    currentUserIdProvider: () {
      try {
        return sl<MessengerBloc>().state.currentUserId;
      } catch (_) {
        return null;
      }
    },
  ),
);
```

Also update the `MeshMessengerAdapter` factory in the same file. Phase 1h registered the adapter with `meshSendText` callback; switch to `meshSendEnvelope`:

Before:
```dart
sl.registerLazySingleton<MeshMessengerAdapter>(() {
  final messaging = sl<MeshMessagingService>();
  return MeshMessengerAdapter(
    meshSendText: ({required toUserPk, required text}) =>
        messaging.sendText(toUserPk: toUserPk, text: text),
    ...
    resolveConversationId: (contactUserId) { ... },
    ...
  );
});
```

After:
```dart
sl.registerLazySingleton<MeshMessengerAdapter>(() {
  final messaging = sl<MeshMessagingService>();
  return MeshMessengerAdapter(
    meshSendEnvelope: ({required toUserPk, required envelope}) =>
        messaging.sendEnvelope(toUserPk: toUserPk, envelope: envelope),
    meshInbound: messaging.inbound,
    lookupUserByDevice: (devicePk) =>
        sl<HiveContactKeyStore>().lookupUserByDevice(devicePk),
    contactUserIdForUserPk: _contactUserIdByUserPk,
    currentUserIdProvider: () {
      try {
        return sl<MessengerBloc>().state.currentUserId;
      } catch (_) {
        return null;
      }
    },
    persistLocal: (entry) =>
        sl<MessengerCacheService>().appendMeshMessage(entry),
  );
});
```

`resolveConversationId` and `persistLocal` are unchanged from Phase 1h's wiring conceptually; the resolveConversationId callback is removed (no longer in adapter signature).

- [ ] **Step 5: Run repo group test (must pass)**

```
flutter test test/features/messenger/data/repositories/messenger_repository_impl_group_test.dart
```
Expected: 6 tests pass.

- [ ] **Step 6: Run full suite**

```
flutter test
```
Expected: only `transport_selector_test.dart` should fail (Task 7 deletes it). All others should pass.

- [ ] **Step 7: Commit**

```bash
git add lib/features/messenger/data/repositories/messenger_repository_impl.dart \
        lib/core/di/service_locator.dart \
        test/features/messenger/data/repositories/messenger_repository_impl_group_test.dart
git commit -m "mesh(2): MessengerRepositoryImpl runs server + mesh fanout in parallel

Replaces TransportSelector binary choice with always-server (when
connected) + per-eligible-peer mesh fanout. Group conversations now
get mesh delivery to visible+known members; non-visible members
covered by server fanout. 50-peer cap as a sanity guard.

Constructor takes the contact store, cache, mesh-status visibility
predicate, and current-user provider explicitly so tests can inject
fakes. ConversationContactResolver typedef gone."
```

---

## Task 7: Delete `TransportSelector`

**Files:**
- Delete: `lib/features/messenger/data/services/transport_selector.dart`
- Delete: `test/features/messenger/data/services/transport_selector_test.dart`
- Modify: `lib/core/di/service_locator.dart` (drop TransportSelector registration)

- [ ] **Step 1: Verify no callers remain**

```
grep -rn "TransportSelector\|TransportChoice" lib/ test/
```
Expected: no remaining references after Task 6's repo rewrite. (If there are, fix the call site to use the new flow.)

- [ ] **Step 2: Delete the files**

```
rm lib/features/messenger/data/services/transport_selector.dart
rm test/features/messenger/data/services/transport_selector_test.dart
```

- [ ] **Step 3: Remove DI registration**

Edit `lib/core/di/service_locator.dart`. Find and delete the entire block:

```dart
sl.registerLazySingleton<TransportSelector>(
  () => TransportSelector(
    isSocketConnected: () =>
        sl<MessengerRemoteDataSource>().isSocketConnected,
    isPeerVisibleFor: (userId) =>
        sl<MeshStatusBloc>().state.visibilityByContactUserId[userId] ?? false,
    offlineFallbackEnabled: () { ... },
  ),
);
```

Also remove the `import` for `transport_selector.dart` at the top of the file.

- [ ] **Step 4: Run full suite**

```
flutter test
```
Expected: all green; transport_selector_test.dart no longer present.

- [ ] **Step 5: Commit**

```bash
git add -A   # captures both deletions and service_locator.dart edit
git commit -m "mesh(2): delete TransportSelector — superseded by repo flow

Phase 2 runs server and mesh in parallel for the same logical send
(see Task 6); the binary TransportChoice (server/mesh/offline) of
Phase 1 is no longer applicable. Repo internal flow replaces it
without a separate selector class."
```

---

## Task 8: `MessengerBloc` dedup extension

**Files:**
- Modify: `lib/features/messenger/presentation/bloc/messenger_bloc.dart` (extend `_onMessageReceived` and `_onMeshMessageReceived`)
- Test: `test/features/messenger/presentation/bloc/messenger_bloc_dedup_test.dart` (NEW)

- [ ] **Step 1: Write the failing dedup tests**

Create `test/features/messenger/presentation/bloc/messenger_bloc_dedup_test.dart`:

```dart
import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:taler_id_mobile/core/services/messenger_cache_service.dart';
import 'package:taler_id_mobile/core/services/pending_message_service.dart';
import 'package:taler_id_mobile/core/di/service_locator.dart';
import 'package:taler_id_mobile/features/messenger/domain/entities/message_entity.dart';
import 'package:taler_id_mobile/features/messenger/domain/repositories/i_messenger_repository.dart';
import 'package:taler_id_mobile/features/messenger/presentation/bloc/messenger_bloc.dart';
import 'package:taler_id_mobile/features/messenger/presentation/bloc/messenger_event.dart';
import 'package:taler_id_mobile/features/messenger/presentation/bloc/messenger_state.dart';

class _StubRepo extends Mock implements IMessengerRepository {}
class _StubCache extends Mock implements MessengerCacheService {}
class _StubPending extends Mock implements PendingMessageService {}

Stream<T> _empty<T>() => const Stream.empty();

void main() {
  setUpAll(() {
    if (!sl.isRegistered<MessengerCacheService>()) {
      sl.registerSingleton<MessengerCacheService>(_StubCache());
    }
    if (!sl.isRegistered<PendingMessageService>()) {
      sl.registerSingleton<PendingMessageService>(_StubPending());
    }
  });

  late _StubRepo repo;
  setUp(() {
    repo = _StubRepo();
    when(() => repo.messageStream).thenAnswer((_) => _empty());
    when(() => repo.callInviteStream).thenAnswer((_) => _empty());
    when(() => repo.messageUpdatedStream).thenAnswer((_) => _empty());
    when(() => repo.messageDeletedStream).thenAnswer((_) => _empty());
    when(() => repo.messagesReadStream).thenAnswer((_) => _empty());
    when(() => repo.groupUpdatedStream).thenAnswer((_) => _empty());
    when(() => repo.groupMemberAddedStream).thenAnswer((_) => _empty());
    when(() => repo.groupMemberRemovedStream).thenAnswer((_) => _empty());
    when(() => repo.groupRoleChangedStream).thenAnswer((_) => _empty());
    when(() => repo.groupCreatedStream).thenAnswer((_) => _empty());
    when(() => repo.groupDeletedStream).thenAnswer((_) => _empty());
    when(() => repo.groupCallStartedStream).thenAnswer((_) => _empty());
    when(() => repo.groupCallEndedStream).thenAnswer((_) => _empty());
    when(() => repo.typingStream).thenAnswer((_) => _empty());
    when(() => repo.contactRequestStream).thenAnswer((_) => _empty());
    when(() => repo.contactAcceptedStream).thenAnswer((_) => _empty());
    when(() => repo.reactionUpdatedStream).thenAnswer((_) => _empty());
    when(() => repo.socketErrorStream).thenAnswer((_) => _empty());
    when(() => repo.analystChunkStream).thenAnswer((_) => _empty());
    when(() => repo.analystSeamStream).thenAnswer((_) => _empty());
    when(() => repo.meshMessageStream).thenAnswer((_) => _empty());
    when(() => repo.meshOutboundStream).thenAnswer((_) => _empty());
  });

  group('Phase 2 mesh-vs-server dedup heuristic', () {
    blocTest<MessengerBloc, MessengerState>(
      'server MessageReceived dropped when mesh entry with same senderId+content exists in 10s window',
      build: () => MessengerBloc(repo: repo),
      seed: () => MessengerState(messages: {
        'conv-1': [
          MessageEntity(
            id: 'mesh-id-1',
            conversationId: 'conv-1',
            senderId: 'alice',
            content: 'hello',
            sentAt: DateTime.parse('2026-04-26T12:00:00.000Z'),
            transport: 'mesh',
          ),
        ],
      }),
      act: (bloc) => bloc.add(MessageReceived(MessageEntity(
        id: 'server-id-1',
        conversationId: 'conv-1',
        senderId: 'alice',
        content: 'hello',
        sentAt: DateTime.parse('2026-04-26T12:00:02.000Z'),  // 2s later
      ))),
      verify: (bloc) {
        final list = bloc.state.messages['conv-1']!;
        expect(list, hasLength(1));
        expect(list.first.id, 'mesh-id-1');
        expect(list.first.transport, 'mesh');
      },
    );

    blocTest<MessengerBloc, MessengerState>(
      'mesh MeshMessageReceived dropped when server entry with same senderId+content exists in 10s window',
      build: () => MessengerBloc(repo: repo),
      seed: () => MessengerState(messages: {
        'conv-1': [
          MessageEntity(
            id: 'server-id-1',
            conversationId: 'conv-1',
            senderId: 'alice',
            content: 'hi via server first',
            sentAt: DateTime.parse('2026-04-26T12:00:00.000Z'),
            transport: null,  // server-delivered
          ),
        ],
      }),
      act: (bloc) => bloc.add(MeshMessageReceived(
        conversationId: 'conv-1',
        contactUserId: 'alice',
        text: 'hi via server first',
        receivedAt: DateTime.parse('2026-04-26T12:00:01.000Z'),
      )),
      verify: (bloc) {
        final list = bloc.state.messages['conv-1']!;
        expect(list, hasLength(1));
        expect(list.first.id, 'server-id-1');
        expect(list.first.transport, isNull);
      },
    );

    blocTest<MessengerBloc, MessengerState>(
      '10s window respected — newer message outside window is NOT deduped',
      build: () => MessengerBloc(repo: repo),
      seed: () => MessengerState(messages: {
        'conv-1': [
          MessageEntity(
            id: 'mesh-old',
            conversationId: 'conv-1',
            senderId: 'alice',
            content: 'hello',
            sentAt: DateTime.parse('2026-04-26T12:00:00.000Z'),
            transport: 'mesh',
          ),
        ],
      }),
      act: (bloc) => bloc.add(MessageReceived(MessageEntity(
        id: 'server-late',
        conversationId: 'conv-1',
        senderId: 'alice',
        content: 'hello',
        sentAt: DateTime.parse('2026-04-26T12:00:30.000Z'),  // 30s later
      ))),
      verify: (bloc) {
        final list = bloc.state.messages['conv-1']!;
        expect(list, hasLength(2),
            reason: 'outside 10s window — treated as a separate message');
      },
    );
  });
}
```

- [ ] **Step 2: Run test (must fail — current handlers don't dedup mesh-vs-server)**

```
flutter test test/features/messenger/presentation/bloc/messenger_bloc_dedup_test.dart
```
Expected: 3 tests fail with the dedup checks.

- [ ] **Step 3: Add dedup heuristic to `_onMessageReceived`**

Open `lib/features/messenger/presentation/bloc/messenger_bloc.dart`. Find `_onMessageReceived` (around the line we identified earlier):

```dart
void _onMessageReceived(
    MessageReceived event, Emitter<MessengerState> emit) {
  final msg = event.message;
  debugPrint('[MessengerBloc] MessageReceived: ...');
  final existing =
      List<MessageEntity>.from(state.messages[msg.conversationId] ?? []);
  if (existing.any((m) => m.id == msg.id)) {
    debugPrint('[MessengerBloc] Duplicate message, skipping');
    return;
  }
  // ... existing temp_* removal ...
}
```

Insert the new mesh-dedup guard immediately AFTER the existing duplicate-by-id guard:

```dart
  if (existing.any((m) => m.id == msg.id)) {
    debugPrint('[MessengerBloc] Duplicate message, skipping');
    return;
  }
  // Phase 2: drop server echo when a mesh entry with matching senderId +
  // content exists within a 10-second window.
  final meshDup = existing.any((m) =>
      m.transport == 'mesh' &&
      m.senderId == msg.senderId &&
      m.content == msg.content &&
      m.sentAt.difference(msg.sentAt).abs() < const Duration(seconds: 10));
  if (meshDup) {
    debugPrint('[MessengerBloc] Server echo deduped against mesh entry, skipping');
    return;
  }
```

- [ ] **Step 4: Add dedup heuristic to `_onMeshMessageReceived`**

Find `_onMeshMessageReceived` in the same file. Add a server-dedup guard at the top:

```dart
void _onMeshMessageReceived(
    MeshMessageReceived event, Emitter<MessengerState> emit) {
  final list = state.messages[event.conversationId] ?? const [];
  // Phase 2: drop mesh inbound when a server-delivered entry with matching
  // senderId + content exists within a 10-second window.
  final serverDup = list.any((m) =>
      m.transport != 'mesh' &&
      !m.id.startsWith('temp_') &&
      m.senderId == event.contactUserId &&
      m.content == event.text &&
      m.sentAt.difference(event.receivedAt).abs() < const Duration(seconds: 10));
  if (serverDup) {
    debugPrint('[MessengerBloc] Mesh inbound deduped against server entry, skipping');
    return;
  }
  // ... existing logic continues ...
}
```

- [ ] **Step 5: Run test (must pass)**

```
flutter test test/features/messenger/presentation/bloc/messenger_bloc_dedup_test.dart
```
Expected: 3 tests pass.

- [ ] **Step 6: Run full suite**

```
flutter test
```
Expected: all green.

- [ ] **Step 7: Commit**

```bash
git add lib/features/messenger/presentation/bloc/messenger_bloc.dart \
        test/features/messenger/presentation/bloc/messenger_bloc_dedup_test.dart
git commit -m "mesh(2): bloc dedup heuristic — drop duplicate mesh-vs-server

10-second window match on (senderId, content) covers the case where
the same logical message arrives once via mesh and once via server
fanout. Mesh entry wins (preserves the 'via mesh' caption); the
server copy is dropped. Same heuristic Phase 1g uses for temp_*
removal in _onMessageReceived, just extended to the cross-transport
case."
```

---

## Task 9: `MeshStatusBloc.visibleParticipantsOf` helper

**Files:**
- Modify: `lib/features/mesh/presentation/bloc/mesh_status_bloc.dart`
- Test: `test/features/mesh/presentation/bloc/mesh_status_bloc_test.dart`

- [ ] **Step 1: Write the failing test**

Append to existing `test/features/mesh/presentation/bloc/mesh_status_bloc_test.dart` inside the existing top-level test group (or create a new one):

```dart
  group('visibleParticipantsOf helper (Phase 2)', () {
    test('returns only userIds whose visibility flag is true', () {
      final bloc = MeshStatusBloc(/* construct with usual deps */);
      // Manually set state — adjust to whatever cubit/bloc API the existing
      // tests use. If the bloc has a markVisible(userId, bool) method, use it.
      bloc.markVisible('alice', true);
      bloc.markVisible('bob', false);
      bloc.markVisible('carol', true);
      final visible = bloc.visibleParticipantsOf(['alice', 'bob', 'carol', 'dave']);
      expect(visible.toSet(), {'alice', 'carol'});
      // dave is unknown — neither true nor false — counts as not visible.
    });

    test('returns empty when no participants are visible', () {
      final bloc = MeshStatusBloc(/* deps */);
      final visible = bloc.visibleParticipantsOf(['alice', 'bob']);
      expect(visible, isEmpty);
    });
  });
```

If the existing test file doesn't construct MeshStatusBloc directly (uses dependency injection / fakes), match that pattern. The helper signature is the only thing that's new.

- [ ] **Step 2: Run test (must fail — visibleParticipantsOf doesn't exist)**

```
flutter test test/features/mesh/presentation/bloc/mesh_status_bloc_test.dart
```
Expected: compile error.

- [ ] **Step 3: Add helper method to MeshStatusBloc**

Open `lib/features/mesh/presentation/bloc/mesh_status_bloc.dart`. Add a public method on the bloc class (next to existing methods like `markRunning`):

```dart
  /// Phase 2 — return the subset of [participantIds] that are currently
  /// visible via mesh. Used by ChatRoomScreen to display "<N>/<M> in mesh"
  /// for group chats.
  Iterable<String> visibleParticipantsOf(Iterable<String> participantIds) =>
      participantIds.where(
        (p) => state.visibilityByContactUserId[p] ?? false,
      );
```

- [ ] **Step 4: Run test (must pass)**

```
flutter test test/features/mesh/presentation/bloc/mesh_status_bloc_test.dart
```
Expected: tests pass.

- [ ] **Step 5: Commit**

```bash
git add lib/features/mesh/presentation/bloc/mesh_status_bloc.dart \
        test/features/mesh/presentation/bloc/mesh_status_bloc_test.dart
git commit -m "mesh(2): MeshStatusBloc.visibleParticipantsOf helper

Used by ChatRoomScreen group badge (Task 10) to display 'N/M in mesh'.
Pure derivation from existing visibilityByContactUserId map; no state
change."
```

---

## Task 10: `ChatTransportBadge` group display

**Files:**
- Modify: `lib/features/messenger/presentation/widgets/chat_transport_badge.dart`
- Modify: `lib/features/messenger/presentation/screens/chat_room_screen.dart` (where the badge is rendered)
- Test: `test/features/messenger/presentation/widgets/chat_transport_badge_test.dart`

- [ ] **Step 1: Write the failing widget test**

Append to existing `test/features/messenger/presentation/widgets/chat_transport_badge_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:taler_id_mobile/features/messenger/presentation/widgets/chat_transport_badge.dart';

void main() {
  group('ChatTransportBadge group state (Phase 2)', () {
    testWidgets('renders "3/5 in mesh" when state is meshGroup with counts',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ChatTransportBadge(
            state: TransportBadgeState.meshGroup,
            visibleCount: 3,
            totalCount: 5,
          ),
        ),
      ));
      expect(find.text('3/5'), findsOneWidget);
    });

    testWidgets('1:1 mesh state does not show counts',
        (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: ChatTransportBadge(state: TransportBadgeState.mesh),
        ),
      ));
      expect(find.textContaining('/'), findsNothing);
    });
  });
}
```

- [ ] **Step 2: Run test (must fail — meshGroup state doesn't exist, params not accepted)**

```
flutter test test/features/messenger/presentation/widgets/chat_transport_badge_test.dart
```
Expected: compile errors.

- [ ] **Step 3: Extend ChatTransportBadge**

Edit `lib/features/messenger/presentation/widgets/chat_transport_badge.dart`. Replace the file:

```dart
import 'package:flutter/material.dart';

enum TransportBadgeState {
  /// Socket.io connected; messages go to server.
  server,

  /// 1:1: server unreachable, peer visible via mesh.
  mesh,

  /// Group: at least one participant visible via mesh.
  /// Use [visibleCount] / [totalCount] to render "N/M".
  meshGroup,

  /// Server unreachable and no mesh peer; messages queued.
  queued,
}

/// Small icon shown in ChatRoomScreen header so the user can tell whether
/// their outbound messages are going over the server, mesh, or are queued.
/// Phase 2: in group chats, also displays "<visibleCount>/<totalCount>"
/// when state is [TransportBadgeState.meshGroup].
class ChatTransportBadge extends StatelessWidget {
  final TransportBadgeState state;
  final int? visibleCount;
  final int? totalCount;

  const ChatTransportBadge({
    super.key,
    required this.state,
    this.visibleCount,
    this.totalCount,
  });

  @override
  Widget build(BuildContext context) {
    final (icon, color, tooltip) = switch (state) {
      TransportBadgeState.server =>
          (Icons.language, Colors.green, 'Server'),
      TransportBadgeState.mesh =>
          (Icons.wifi_tethering, Colors.lightBlue, 'Mesh (offline fallback)'),
      TransportBadgeState.meshGroup => (
            Icons.wifi_tethering,
            Colors.lightBlue,
            'Group mesh ($visibleCount/$totalCount visible)'
          ),
      TransportBadgeState.queued => (
            Icons.cloud_off,
            Colors.orange,
            'Queued — no server, no mesh peer'
          ),
    };
    final iconWidget = Icon(icon, size: 18, color: color);
    final body = state == TransportBadgeState.meshGroup
        ? Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              iconWidget,
              const SizedBox(width: 4),
              Text(
                '$visibleCount/$totalCount',
                style: TextStyle(fontSize: 12, color: color),
              ),
            ],
          )
        : iconWidget;
    return Tooltip(message: tooltip, child: body);
  }
}
```

- [ ] **Step 4: Update ChatRoomScreen to pass group counts**

Edit `lib/features/messenger/presentation/screens/chat_room_screen.dart`. Find where `ChatTransportBadge` is constructed (search `ChatTransportBadge(`). The current code instantiates it with just `state:`. Update to also pass `visibleCount` and `totalCount` for group conversations.

The exact location depends on how the badge state is currently computed. Pseudocode:

```dart
// In the appBar build (or wherever badge state is selected):
final isGroup = conversation.type == 'GROUP';
final TransportBadgeState badgeState;
int? visibleCount;
int? totalCount;
if (isGroup) {
  final myUserId = state.currentUserId;
  final others = conversation.participantIds.where((p) => p != myUserId).toList();
  final visible = sl<MeshStatusBloc>().visibleParticipantsOf(others).toList();
  totalCount = others.length;
  visibleCount = visible.length;
  badgeState = visibleCount > 0
      ? TransportBadgeState.meshGroup
      : (socketConnected ? TransportBadgeState.server : TransportBadgeState.queued);
} else {
  // existing 1:1 logic ...
}

ChatTransportBadge(
  state: badgeState,
  visibleCount: visibleCount,
  totalCount: totalCount,
)
```

If the existing 1:1 selection logic is non-trivial, wrap it in a helper to keep the build method readable.

- [ ] **Step 5: Run badge widget tests**

```
flutter test test/features/messenger/presentation/widgets/chat_transport_badge_test.dart
```
Expected: tests pass.

- [ ] **Step 6: Run full suite**

```
flutter test
```
Expected: all green.

- [ ] **Step 7: Commit**

```bash
git add lib/features/messenger/presentation/widgets/chat_transport_badge.dart \
        lib/features/messenger/presentation/screens/chat_room_screen.dart \
        test/features/messenger/presentation/widgets/chat_transport_badge_test.dart
git commit -m "mesh(2): ChatTransportBadge shows N/M visible in group chats

Adds TransportBadgeState.meshGroup and visibleCount/totalCount params.
ChatRoomScreen consumes MeshStatusBloc.visibleParticipantsOf to drive
the count for group conversations. 1:1 chats unchanged."
```

---

## Task 11: Regression sweep + push

**Files:** none (verification only)

- [ ] **Step 1: flutter analyze**

```
cd /Users/dmitry/Downloads/taler_id_mesh
flutter analyze
```
Expected: no new errors. Warnings acceptable only if pre-existing (compare against `git stash show` of the merge commit).

- [ ] **Step 2: Full test suite**

```
flutter test
```
Expected: every test green. Note pass count — should be ≥ baseline (~390 from merge) plus the new tests added in Tasks 1, 2, 3, 4, 5, 6, 8, 9, 10 (approximately 25–30 new cases).

- [ ] **Step 3: Hardware smoke (manual checklist)**

Run on three real devices on the same WiFi (Android + iPhone-A + iPhone-B). Server up.

1. Create a group with all three. Send text from iPhone-A. Confirm Android and iPhone-B both render the message with `via mesh` caption. No duplicates.

2. Disconnect Android from WiFi. Send from iPhone-A. iPhone-B receives via mesh; Android does not. Reconnect Android — Android receives via server fanout; no duplicate on iPhone-B.

3. Stop the dev backend. Send from iPhone-A in the group. Other devices receive via mesh. Restart the backend; sender's pending re-emits via server. Other devices dedup the second copy. Sender sees one entry.

4. Verify 1:1 mesh still works (regression). Open a 1:1 chat between iPhone-A and Android, send a few messages, confirm "via mesh" caption + no clock-icon stuck.

5. Mixed-version sanity: install the previous (Phase 1k) APK on one device and the new (Phase 2) APK on another. Send from each side. Mesh should NOT work (frame v2 rejects v1 and vice versa); server fanout still delivers.

If any check fails, fix the regression in a new task and re-run before pushing.

- [ ] **Step 4: Push the branch**

```bash
git log --oneline   # sanity-check Phase 2 commits
git push origin feature/mesh-phase2-group-chats
```

- [ ] **Step 5: Open PR for merge into dev**

```bash
gh pr create --title "Mesh Phase 2: group chats" \
  --body "$(cat <<'EOF'
## Summary
- Group chats now use mesh fanout for visible+known peers in addition to the always-on server send
- Receivers dedup mesh-vs-server-echo via 10s (senderId, content) window heuristic — no backend change
- Frame v1 → v2; data payload becomes encrypted JSON envelope `{convId, clientId, type, text, sentAt}`
- TransportSelector retired; logic moves to MessengerRepositoryImpl
- 1:1 mesh continues to work after the wire format upgrade

## Test plan
- [ ] flutter test passes (390+ + new envelope/dedup/group-fanout cases)
- [ ] flutter analyze clean
- [ ] Hardware: 3-device group, all visible, server up — mesh delivers, no dupes
- [ ] Hardware: 3-device group, one off-WiFi — mixed mesh + server delivery
- [ ] Hardware: 3-device group, server stopped — mesh-only fanout to visible peers
- [ ] Hardware: 1:1 regression — Phase 1f/g/h/i/j/k flows preserved
- [ ] Hardware: mixed v1/v2 sanity — server fanout covers; mesh inactive between mixed devices

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"
```

The PR review window is the natural moment to fix anything reviewers flag. Once approved, merge into `dev`.

---

## Self-Review

Spec coverage check (against `2026-04-26-mesh-phase2-group-chats-design.md`):

- §1 Executive Summary: covered by Tasks 6 (always-server + per-peer mesh fanout).
- §2 Decision Log #1 (pairwise Noise): inherited from Phase 1; no new code, no task needed.
- §2 #2 (hybrid fanout): Task 6.
- §2 #3 (text + system scope): the envelope `type: 'text'` field is wired (Task 2); system messages share the same wire path when added later — out of scope here.
- §2 #4 (wire format bump): Tasks 2, 3, 4.
- §2 #5 (UUID v4 clientTempId): Task 1.
- §2 #6 (50-peer cap): Task 6 (`_meshGroupSizeCap = 50`).
- §3 Goals: 1 → Tasks 4+6; 2 → Task 8; 3 → manual smoke (Task 11); 4 → Task 4; 5 → all task tests + Task 11 sweep.
- §3 Non-Goals: scope explicitly excludes them; no tasks created for them.
- §5 Wire format: Tasks 2, 3, 4.
- §6 Send path: Task 6.
- §7 Receive path & dedup: Tasks 5 (adapter envelope routing) + 8 (bloc dedup).
- §8 State management: Tasks 1 (UUID), 9 (MeshStatusBloc helper), 10 (badge UI).
- §9 Testing: covered task by task; Task 11 manual smoke list mirrors §9.
- §10 Risks & rollout: rollout plan stated; Task 11 push + PR matches the plan.

Placeholder scan: no "TBD" / "implement later" / "similar to Task N" patterns. Every code step contains the actual code.

Type consistency check:
- `Envelope` class fields used identically across Tasks 2, 4, 5, 6.
- `meshSendEnvelope` callback signature: `({required PeerId toUserPk, required Envelope envelope})` matches between Task 4 (MeshMessagingService.sendEnvelope), Task 5 (adapter parameter), Task 6 (DI lambda).
- `sendEnvelopeToPeer` signature: `({required PeerId peerDevicePk, required String contactUserId, required Envelope envelope})` matches between Task 5 (adapter) and Task 6 (repo call).
- `AdaptedInboundMessage` field set: contactUserId, conversationId, text, receivedAt, clientId — consistent between Tasks 5 (definition) and 8 (bloc dedup uses receivedAt).
- `_meshGroupSizeCap`, `_isPeerVisibleForContactUserId`, `_currentUserIdProvider` — defined in Task 6 constructor, used only inside that file.
- `TransportBadgeState.meshGroup` + `visibleCount` / `totalCount` parameters — match between Tasks 9, 10.

No issues found — plan is internally consistent.

---

## Execution Handoff

**Plan complete and saved to `docs/superpowers/plans/2026-04-26-mesh-phase2-group-chats.md`. Two execution options:**

**1. Subagent-Driven (recommended)** - I dispatch a fresh subagent per task, review between tasks, fast iteration

**2. Inline Execution** - Execute tasks in this session using executing-plans, batch execution with checkpoints

**Which approach?**

# Mesh Phase 2.2 — Pending Mesh Send Retry Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Recover text messages that hit `_meshFanout` while no peer was visible: queue them in memory for 30 seconds and re-fan out per peer when `PeerDiscovered` brings the recipient online.

**Architecture:** New `PendingMeshSendQueue` (in-memory, 30 s TTL, per-peer fanout tracking) is enqueued from `MessengerRepositoryImpl._meshFanout` whenever the eligible-peer set is empty. `MeshMessengerAdapter` grows a `peerDiscovered` stream (resolved to `contactUserId` via `ContactKeyStore`) that the repo subscribes to; on each event, due entries are re-fanned out via the existing `sendEnvelopeToPeer` path. The first successful per-`clientId` retry emits a single `AdaptedOutboundMessage` so the sender's UI flips `temp_<uuid>` → `mesh-out-<uuid>` exactly once, mirroring Phase 2's "one outbound per logical send" rule.

**Tech Stack:** Dart/Flutter, `flutter_bloc`, `bonsoir` (transport-level), Hive (read-only here), `mocktail` (tests), `flutter_test`.

**Spec:** `docs/superpowers/specs/2026-04-27-mesh-phase2-2-pending-mesh-retry-design.md`

**Branch:** `feature/mesh-phase2-2-pending-mesh-retry` (already created from `dev` at the spec-commit).

**File map:**

| File | Role | New / Modified |
|---|---|---|
| `lib/features/messenger/data/services/pending_mesh_send_queue.dart` | In-memory retry queue with TTL + per-peer fanout tracking | New |
| `lib/features/messenger/data/services/mesh_messenger_adapter.dart` | Expose `peerDiscovered: Stream<AdaptedPeerDiscovered>`; new `AdaptedPeerDiscovered` event | Modified |
| `lib/features/messenger/data/repositories/messenger_repository_impl.dart` | Inject queue; enqueue on `eligible.isEmpty`; subscribe to `peerDiscovered` and retry due entries | Modified |
| `lib/core/di/service_locator.dart` | Register `PendingMeshSendQueue`; wire `transport.discoveries` into adapter; pass queue into repo | Modified |
| `test/features/messenger/data/services/pending_mesh_send_queue_test.dart` | Unit tests for queue API | New |
| `test/features/messenger/data/services/mesh_messenger_adapter_peer_discovered_test.dart` | Adapter `peerDiscovered` stream test | New |
| `test/features/messenger/data/repositories/messenger_repository_impl_pending_mesh_test.dart` | Integration test for enqueue + retry hooks | New |

---

## Task 1: `PendingMeshSendQueue` skeleton — `enqueue` + `dueFor` (TDD)

**Files:**
- Create: `lib/features/messenger/data/services/pending_mesh_send_queue.dart`
- Create: `test/features/messenger/data/services/pending_mesh_send_queue_test.dart`

- [ ] **Step 1: Write the failing test**

Create `test/features/messenger/data/services/pending_mesh_send_queue_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:taler_id_mobile/features/messenger/data/services/pending_mesh_send_queue.dart';

void main() {
  group('PendingMeshSendQueue enqueue + dueFor', () {
    test('enqueue then dueFor returns the entry for a participant peer', () {
      final queue = PendingMeshSendQueue();
      queue.enqueue(
        clientId: 'temp_abc',
        conversationId: 'conv-1',
        content: 'hello',
        sentAt: DateTime.parse('2026-04-27T10:00:00Z'),
      );

      final due = queue.dueFor(
        peerUserId: 'user-bob',
        participantsOf: (_) => ['user-bob', 'user-me'],
      ).toList();

      expect(due, hasLength(1));
      expect(due.single.clientId, 'temp_abc');
      expect(due.single.conversationId, 'conv-1');
      expect(due.single.content, 'hello');
    });

    test('dueFor filters out peers not in conversation participants', () {
      final queue = PendingMeshSendQueue();
      queue.enqueue(
        clientId: 'temp_abc',
        conversationId: 'conv-1',
        content: 'hello',
        sentAt: DateTime.now().toUtc(),
      );

      final due = queue.dueFor(
        peerUserId: 'user-charlie', // not in participants
        participantsOf: (_) => ['user-bob', 'user-me'],
      ).toList();

      expect(due, isEmpty);
    });

    test('enqueue with same clientId overwrites, no duplicates', () {
      final queue = PendingMeshSendQueue();
      queue.enqueue(
        clientId: 'temp_abc',
        conversationId: 'conv-1',
        content: 'first',
        sentAt: DateTime.now().toUtc(),
      );
      queue.enqueue(
        clientId: 'temp_abc',
        conversationId: 'conv-1',
        content: 'second',
        sentAt: DateTime.now().toUtc(),
      );

      final due = queue.dueFor(
        peerUserId: 'user-bob',
        participantsOf: (_) => ['user-bob'],
      ).toList();

      expect(due, hasLength(1));
      expect(due.single.content, 'second');
    });
  });
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `cd /Users/dmitry/Downloads/taler_id_mesh && flutter test test/features/messenger/data/services/pending_mesh_send_queue_test.dart`
Expected: compilation error — `pending_mesh_send_queue.dart` does not exist.

- [ ] **Step 3: Create the queue with enqueue + dueFor**

Create `lib/features/messenger/data/services/pending_mesh_send_queue.dart`:

```dart
import 'package:clock/clock.dart';

/// Retry queue for text messages that had no eligible mesh peers at first
/// send. Lives only in memory; entries expire 30 s after `sentAt`.
///
/// See `docs/superpowers/specs/2026-04-27-mesh-phase2-2-pending-mesh-retry-design.md`.
class PendingMeshSendQueue {
  final Duration ttl;
  final Map<String, _Entry> _entries = {};

  PendingMeshSendQueue({this.ttl = const Duration(seconds: 30)});

  /// Add or overwrite an entry for [clientId].
  void enqueue({
    required String clientId,
    required String conversationId,
    required String content,
    required DateTime sentAt,
  }) {
    _entries[clientId] = _Entry(
      clientId: clientId,
      conversationId: conversationId,
      content: content,
      sentAt: sentAt,
      expiresAt: sentAt.add(ttl),
    );
  }

  /// Entries currently within TTL whose conversation participants include
  /// [peerUserId] and that have not yet been fanned out to that peer.
  Iterable<PendingMeshSendEntry> dueFor({
    required String peerUserId,
    required Iterable<String> Function(String conversationId) participantsOf,
  }) sync* {
    for (final entry in _entries.values) {
      final participants = participantsOf(entry.conversationId);
      if (!participants.contains(peerUserId)) continue;
      if (entry.fannedOutTo.contains(peerUserId)) continue;
      yield PendingMeshSendEntry(
        clientId: entry.clientId,
        conversationId: entry.conversationId,
        content: entry.content,
        sentAt: entry.sentAt,
      );
    }
  }
}

class PendingMeshSendEntry {
  final String clientId;
  final String conversationId;
  final String content;
  final DateTime sentAt;
  PendingMeshSendEntry({
    required this.clientId,
    required this.conversationId,
    required this.content,
    required this.sentAt,
  });
}

class _Entry {
  final String clientId;
  final String conversationId;
  final String content;
  final DateTime sentAt;
  final DateTime expiresAt;
  final Set<String> fannedOutTo = <String>{};

  _Entry({
    required this.clientId,
    required this.conversationId,
    required this.content,
    required this.sentAt,
    required this.expiresAt,
  });
}
```

The `clock` import is unused now but Tasks 3+ depend on `clock.now()` for testable time; importing here keeps the file structure stable.

- [ ] **Step 4: Run the test to verify it passes**

Run: `cd /Users/dmitry/Downloads/taler_id_mesh && flutter test test/features/messenger/data/services/pending_mesh_send_queue_test.dart`
Expected: 3 tests passed.

- [ ] **Step 5: Commit**

```bash
git add lib/features/messenger/data/services/pending_mesh_send_queue.dart \
        test/features/messenger/data/services/pending_mesh_send_queue_test.dart
git commit -m "mesh(2.2): PendingMeshSendQueue enqueue + dueFor"
```

---

## Task 2: `markFannedOut` returns `isFirstFanout` (TDD)

**Files:**
- Modify: `lib/features/messenger/data/services/pending_mesh_send_queue.dart`
- Modify: `test/features/messenger/data/services/pending_mesh_send_queue_test.dart`

- [ ] **Step 1: Write the failing test**

Append a new group to the test file (after the existing `dueFor` group):

```dart

  group('PendingMeshSendQueue markFannedOut', () {
    test('first call returns true, subsequent calls return false', () {
      final queue = PendingMeshSendQueue();
      queue.enqueue(
        clientId: 'temp_abc',
        conversationId: 'conv-1',
        content: 'hello',
        sentAt: DateTime.now().toUtc(),
      );

      final first = queue.markFannedOut(clientId: 'temp_abc', peerUserId: 'user-bob');
      final second = queue.markFannedOut(clientId: 'temp_abc', peerUserId: 'user-bob');
      expect(first, isTrue);
      expect(second, isFalse);
    });

    test('first call for second peer also returns false (clientId already had a fanout)', () {
      final queue = PendingMeshSendQueue();
      queue.enqueue(
        clientId: 'temp_abc',
        conversationId: 'conv-1',
        content: 'hello',
        sentAt: DateTime.now().toUtc(),
      );

      queue.markFannedOut(clientId: 'temp_abc', peerUserId: 'user-bob');
      final second = queue.markFannedOut(clientId: 'temp_abc', peerUserId: 'user-charlie');
      expect(second, isFalse);
    });

    test('marked peer is excluded from subsequent dueFor', () {
      final queue = PendingMeshSendQueue();
      queue.enqueue(
        clientId: 'temp_abc',
        conversationId: 'conv-1',
        content: 'hello',
        sentAt: DateTime.now().toUtc(),
      );
      queue.markFannedOut(clientId: 'temp_abc', peerUserId: 'user-bob');

      final due = queue.dueFor(
        peerUserId: 'user-bob',
        participantsOf: (_) => ['user-bob', 'user-me'],
      ).toList();

      expect(due, isEmpty);
    });

    test('markFannedOut on missing clientId is a no-op and returns false', () {
      final queue = PendingMeshSendQueue();
      final r = queue.markFannedOut(clientId: 'no-such-id', peerUserId: 'user-bob');
      expect(r, isFalse);
    });
  });
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `cd /Users/dmitry/Downloads/taler_id_mesh && flutter test test/features/messenger/data/services/pending_mesh_send_queue_test.dart`
Expected: compilation error — `markFannedOut` does not exist.

- [ ] **Step 3: Implement `markFannedOut`**

In `lib/features/messenger/data/services/pending_mesh_send_queue.dart`, inside class `PendingMeshSendQueue`, after `dueFor`, add:

```dart
  /// Mark [peerUserId] as having received the message identified by
  /// [clientId]. Returns `true` if this is the first peer to be marked
  /// for that clientId (the entry's fanout-set was empty before this
  /// call). Returns `false` if the entry no longer exists or the
  /// fanout-set was non-empty.
  bool markFannedOut({required String clientId, required String peerUserId}) {
    final entry = _entries[clientId];
    if (entry == null) return false;
    final wasEmpty = entry.fannedOutTo.isEmpty;
    entry.fannedOutTo.add(peerUserId);
    return wasEmpty;
  }
```

- [ ] **Step 4: Run the tests**

Run: `cd /Users/dmitry/Downloads/taler_id_mesh && flutter test test/features/messenger/data/services/pending_mesh_send_queue_test.dart`
Expected: 7 tests passed (3 from Task 1 + 4 new).

- [ ] **Step 5: Commit**

```bash
git add lib/features/messenger/data/services/pending_mesh_send_queue.dart \
        test/features/messenger/data/services/pending_mesh_send_queue_test.dart
git commit -m "mesh(2.2): PendingMeshSendQueue markFannedOut isFirstFanout signal"
```

---

## Task 3: TTL expiry + `remove` + `pendingCount` (TDD)

**Files:**
- Modify: `lib/features/messenger/data/services/pending_mesh_send_queue.dart`
- Modify: `test/features/messenger/data/services/pending_mesh_send_queue_test.dart`

- [ ] **Step 1: Write the failing test**

Append to the test file:

```dart

  group('PendingMeshSendQueue TTL + remove + pendingCount', () {
    test('expired entries are not returned by dueFor and are purged lazily', () {
      withClock(Clock.fixed(DateTime.parse('2026-04-27T10:00:00Z')), () {
        final queue = PendingMeshSendQueue(ttl: const Duration(seconds: 30));
        queue.enqueue(
          clientId: 'temp_abc',
          conversationId: 'conv-1',
          content: 'hello',
          sentAt: DateTime.parse('2026-04-27T10:00:00Z'),
        );
        expect(queue.pendingCount, 1);

        // Advance fake time past TTL.
        withClock(Clock.fixed(DateTime.parse('2026-04-27T10:00:31Z')), () {
          final due = queue.dueFor(
            peerUserId: 'user-bob',
            participantsOf: (_) => ['user-bob'],
          ).toList();
          expect(due, isEmpty);
          expect(queue.pendingCount, 0,
              reason: 'lazy purge during dueFor must drop expired entries');
        });
      });
    });

    test('non-expired entries survive a dueFor call', () {
      withClock(Clock.fixed(DateTime.parse('2026-04-27T10:00:00Z')), () {
        final queue = PendingMeshSendQueue(ttl: const Duration(seconds: 30));
        queue.enqueue(
          clientId: 'temp_abc',
          conversationId: 'conv-1',
          content: 'hello',
          sentAt: DateTime.parse('2026-04-27T10:00:00Z'),
        );

        withClock(Clock.fixed(DateTime.parse('2026-04-27T10:00:10Z')), () {
          queue.dueFor(
            peerUserId: 'user-charlie', // not a participant; just trigger purge
            participantsOf: (_) => ['user-bob'],
          ).toList();
          expect(queue.pendingCount, 1);
        });
      });
    });

    test('remove drops the entry explicitly', () {
      final queue = PendingMeshSendQueue();
      queue.enqueue(
        clientId: 'temp_abc',
        conversationId: 'conv-1',
        content: 'hello',
        sentAt: DateTime.now().toUtc(),
      );
      expect(queue.pendingCount, 1);
      queue.remove('temp_abc');
      expect(queue.pendingCount, 0);
      queue.remove('temp_abc'); // second remove is a no-op
      expect(queue.pendingCount, 0);
    });
  });
```

Add to the imports at the top of the test file:

```dart
import 'package:clock/clock.dart';
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `cd /Users/dmitry/Downloads/taler_id_mesh && flutter test test/features/messenger/data/services/pending_mesh_send_queue_test.dart`
Expected: failures — `pendingCount` does not exist; expired entries are still returned; `remove` does not exist.

- [ ] **Step 3: Add TTL purge, `remove`, and `pendingCount`**

In `lib/features/messenger/data/services/pending_mesh_send_queue.dart`, replace the class body of `PendingMeshSendQueue` with:

```dart
class PendingMeshSendQueue {
  final Duration ttl;
  final Map<String, _Entry> _entries = {};

  PendingMeshSendQueue({this.ttl = const Duration(seconds: 30)});

  void enqueue({
    required String clientId,
    required String conversationId,
    required String content,
    required DateTime sentAt,
  }) {
    _purgeExpired();
    _entries[clientId] = _Entry(
      clientId: clientId,
      conversationId: conversationId,
      content: content,
      sentAt: sentAt,
      expiresAt: sentAt.add(ttl),
    );
  }

  Iterable<PendingMeshSendEntry> dueFor({
    required String peerUserId,
    required Iterable<String> Function(String conversationId) participantsOf,
  }) sync* {
    _purgeExpired();
    for (final entry in _entries.values) {
      final participants = participantsOf(entry.conversationId);
      if (!participants.contains(peerUserId)) continue;
      if (entry.fannedOutTo.contains(peerUserId)) continue;
      yield PendingMeshSendEntry(
        clientId: entry.clientId,
        conversationId: entry.conversationId,
        content: entry.content,
        sentAt: entry.sentAt,
      );
    }
  }

  bool markFannedOut({required String clientId, required String peerUserId}) {
    final entry = _entries[clientId];
    if (entry == null) return false;
    final wasEmpty = entry.fannedOutTo.isEmpty;
    entry.fannedOutTo.add(peerUserId);
    return wasEmpty;
  }

  void remove(String clientId) {
    _entries.remove(clientId);
  }

  int get pendingCount => _entries.length;

  void _purgeExpired() {
    final now = clock.now();
    _entries.removeWhere((_, entry) => entry.expiresAt.isBefore(now));
  }
}
```

- [ ] **Step 4: Run the tests**

Run: `cd /Users/dmitry/Downloads/taler_id_mesh && flutter test test/features/messenger/data/services/pending_mesh_send_queue_test.dart`
Expected: 10 tests passed.

- [ ] **Step 5: Commit**

```bash
git add lib/features/messenger/data/services/pending_mesh_send_queue.dart \
        test/features/messenger/data/services/pending_mesh_send_queue_test.dart
git commit -m "mesh(2.2): TTL expiry + remove + pendingCount"
```

---

## Task 4: `MeshMessengerAdapter.peerDiscovered` stream + `AdaptedPeerDiscovered` (TDD)

**Files:**
- Modify: `lib/features/messenger/data/services/mesh_messenger_adapter.dart`
- Create: `test/features/messenger/data/services/mesh_messenger_adapter_peer_discovered_test.dart`

- [ ] **Step 1: Write the failing test**

Create `test/features/messenger/data/services/mesh_messenger_adapter_peer_discovered_test.dart`:

```dart
import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:taler_id_mobile/core/mesh/services/envelope.dart';
import 'package:taler_id_mobile/core/mesh/services/mesh_messaging_service.dart';
import 'package:taler_id_mobile/core/mesh/transport/mesh_transport.dart';
import 'package:taler_id_mobile/core/mesh/transport/peer_id.dart';
import 'package:taler_id_mobile/features/messenger/data/services/mesh_messenger_adapter.dart';

void main() {
  group('MeshMessengerAdapter peerDiscovered', () {
    late StreamController<PeerDiscovered> discoveriesCtrl;
    late MeshMessengerAdapter adapter;
    late Map<PeerId, PeerId> deviceToUser;
    late Map<PeerId, String> userPkToContactId;

    setUp(() {
      discoveriesCtrl = StreamController<PeerDiscovered>.broadcast();
      deviceToUser = {};
      userPkToContactId = {};

      adapter = MeshMessengerAdapter(
        meshSendEnvelope: ({required toUserPk, required envelope}) async {},
        meshInbound: const Stream<InboundEnvelope>.empty(),
        meshDiscoveries: discoveriesCtrl.stream,
        lookupUserByDevice: (devicePk) => deviceToUser[devicePk],
        contactUserIdForUserPk: (userPk) => userPkToContactId[userPk],
        currentUserIdProvider: () => 'me',
        persistLocal: (_) {},
      );
      adapter.start();
    });

    tearDown(() async {
      await adapter.dispose();
      await discoveriesCtrl.close();
    });

    test('emits AdaptedPeerDiscovered for resolvable peer', () async {
      final devicePk = PeerId(Uint8List.fromList(List.generate(32, (i) => i)));
      final userPk = PeerId(Uint8List.fromList(List.generate(32, (i) => 100 + i)));
      deviceToUser[devicePk] = userPk;
      userPkToContactId[userPk] = 'user-bob';

      final received = <AdaptedPeerDiscovered>[];
      adapter.peerDiscovered.listen(received.add);

      discoveriesCtrl.add(PeerDiscovered(
        peerId: devicePk,
        host: '192.168.0.42',
        port: 12345,
      ));
      await Future<void>.delayed(Duration.zero);

      expect(received, hasLength(1));
      expect(received.single.contactUserId, 'user-bob');
      expect(received.single.devicePk, devicePk);
    });

    test('drops PeerDiscovered for unknown devicePk', () async {
      final unknownDevicePk =
          PeerId(Uint8List.fromList(List.generate(32, (i) => 200 + i)));

      final received = <AdaptedPeerDiscovered>[];
      adapter.peerDiscovered.listen(received.add);

      discoveriesCtrl.add(PeerDiscovered(
        peerId: unknownDevicePk,
        host: '192.168.0.42',
        port: 12345,
      ));
      await Future<void>.delayed(Duration.zero);

      expect(received, isEmpty);
    });
  });
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `cd /Users/dmitry/Downloads/taler_id_mesh && flutter test test/features/messenger/data/services/mesh_messenger_adapter_peer_discovered_test.dart`
Expected: compilation error — `meshDiscoveries` parameter does not exist; `peerDiscovered` getter does not exist; `AdaptedPeerDiscovered` does not exist.

- [ ] **Step 3: Add the new event class + adapter wiring**

Open `lib/features/messenger/data/services/mesh_messenger_adapter.dart`. Add an import at the top:

```dart
import '../../../../core/mesh/transport/mesh_transport.dart';
```

After `class AdaptedOutboundMessage { ... }`, add:

```dart
class AdaptedPeerDiscovered {
  final PeerId devicePk;
  final String contactUserId;
  AdaptedPeerDiscovered({required this.devicePk, required this.contactUserId});
}
```

Inside `class MeshMessengerAdapter`, add the new constructor field, controller, and subscription:

Replace the existing fields block (down to `_sub`) with:

```dart
  final Future<void> Function({required PeerId toUserPk, required Envelope envelope})
      meshSendEnvelope;
  final Stream<InboundEnvelope> meshInbound;
  final Stream<PeerDiscovered> meshDiscoveries;
  final PeerId? Function(PeerId devicePk) lookupUserByDevice;
  final String? Function(PeerId userPk) contactUserIdForUserPk;
  final String? Function() currentUserIdProvider;
  final void Function(Map<String, dynamic> entry) persistLocal;

  static const String _kTransport = 'mesh';

  final _ctrl = StreamController<AdaptedInboundMessage>.broadcast();
  final _outCtrl = StreamController<AdaptedOutboundMessage>.broadcast();
  final _peerCtrl = StreamController<AdaptedPeerDiscovered>.broadcast();
  StreamSubscription<InboundEnvelope>? _sub;
  StreamSubscription<PeerDiscovered>? _peerSub;
```

Update the constructor:

```dart
  MeshMessengerAdapter({
    required this.meshSendEnvelope,
    required this.meshInbound,
    required this.meshDiscoveries,
    required this.lookupUserByDevice,
    required this.contactUserIdForUserPk,
    required this.currentUserIdProvider,
    required this.persistLocal,
  });
```

Add the new getter next to the existing `outbound` getter:

```dart
  Stream<AdaptedPeerDiscovered> get peerDiscovered => _peerCtrl.stream;
```

Replace `start` and `stop` with:

```dart
  void start() {
    _sub ??= meshInbound.listen(_onInbound);
    _peerSub ??= meshDiscoveries.listen(_onDiscovery);
  }

  Future<void> stop() async {
    await _sub?.cancel();
    _sub = null;
    await _peerSub?.cancel();
    _peerSub = null;
  }
```

Add the `_onDiscovery` handler near `_onInbound`:

```dart
  void _onDiscovery(PeerDiscovered ev) {
    final userPk = lookupUserByDevice(ev.peerId);
    if (userPk == null) return;
    final contactUserId = contactUserIdForUserPk(userPk);
    if (contactUserId == null) return;
    _peerCtrl.add(AdaptedPeerDiscovered(
      devicePk: ev.peerId,
      contactUserId: contactUserId,
    ));
  }
```

Update `dispose`:

```dart
  Future<void> dispose() async {
    await stop();
    await _ctrl.close();
    await _outCtrl.close();
    await _peerCtrl.close();
  }
```

- [ ] **Step 4: Run the test**

Run: `cd /Users/dmitry/Downloads/taler_id_mesh && flutter test test/features/messenger/data/services/mesh_messenger_adapter_peer_discovered_test.dart`
Expected: 2 tests passed.

- [ ] **Step 5: Run the full mesh test suite to confirm no regression in adapter**

Run: `cd /Users/dmitry/Downloads/taler_id_mesh && flutter test test/features/messenger/data/services/`
Expected: all adapter and queue tests green. The existing `mesh_messenger_adapter_test.dart` will fail to compile because the constructor now requires `meshDiscoveries`. Fix it in the next sub-step.

- [ ] **Step 6: Update existing adapter tests that build the adapter**

In `test/features/messenger/data/services/mesh_messenger_adapter_test.dart`, every direct construction of `MeshMessengerAdapter(...)` must add `meshDiscoveries: const Stream<PeerDiscovered>.empty(),` to the named parameters. The import block at the top of the file must include:

```dart
import 'package:taler_id_mobile/core/mesh/transport/mesh_transport.dart';
```

(Add the import only if it isn't already present.) After applying these edits, re-run the full adapter suite:

Run: `cd /Users/dmitry/Downloads/taler_id_mesh && flutter test test/features/messenger/data/services/`
Expected: all green.

- [ ] **Step 7: Commit**

```bash
git add lib/features/messenger/data/services/mesh_messenger_adapter.dart \
        test/features/messenger/data/services/mesh_messenger_adapter_peer_discovered_test.dart \
        test/features/messenger/data/services/mesh_messenger_adapter_test.dart
git commit -m "mesh(2.2): MeshMessengerAdapter exposes peerDiscovered stream"
```

---

## Task 5: `MessengerRepositoryImpl` enqueues on no-eligible-peers (TDD)

**Files:**
- Modify: `lib/features/messenger/data/repositories/messenger_repository_impl.dart`
- Create: `test/features/messenger/data/repositories/messenger_repository_impl_pending_mesh_test.dart`

- [ ] **Step 1: Write the failing test**

Create `test/features/messenger/data/repositories/messenger_repository_impl_pending_mesh_test.dart`:

```dart
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:taler_id_mobile/core/mesh/crypto/keys/contact_key_store_hive.dart';
import 'package:taler_id_mobile/core/mesh/transport/peer_id.dart';
import 'package:taler_id_mobile/core/services/messenger_cache_service.dart';
import 'package:taler_id_mobile/core/services/pending_message_service.dart';
import 'package:taler_id_mobile/features/messenger/data/datasources/messenger_remote_datasource.dart';
import 'package:taler_id_mobile/features/messenger/data/repositories/messenger_repository_impl.dart';
import 'package:taler_id_mobile/features/messenger/data/services/mesh_messenger_adapter.dart';
import 'package:taler_id_mobile/features/messenger/data/services/pending_mesh_send_queue.dart';
import 'package:taler_id_mobile/features/messenger/domain/entities/conversation_entity.dart';

class _MockRemote extends Mock implements MessengerRemoteDataSource {}

class _MockAdapter extends Mock implements MeshMessengerAdapter {}

class _MockPending extends Mock implements PendingMessageService {}

class _MockCache extends Mock implements MessengerCacheService {}

class _MockHiveStore extends Mock implements HiveContactKeyStore {}

ConversationEntity _conv({
  required String id,
  required List<String> participantIds,
}) {
  return ConversationEntity(
    id: id,
    participantIds: participantIds,
    lastMessage: null,
    unreadCount: 0,
    isGroup: participantIds.length > 2,
    title: null,
    avatarUrl: null,
    type: ConvType.direct,
  );
}

void main() {
  setUpAll(() {
    registerFallbackValue(<String, dynamic>{});
  });

  group('MessengerRepositoryImpl pending mesh enqueue', () {
    late _MockRemote remote;
    late _MockAdapter adapter;
    late _MockPending pending;
    late _MockCache cache;
    late _MockHiveStore hive;
    late PendingMeshSendQueue queue;
    late MessengerRepositoryImpl repo;
    late StreamController<AdaptedPeerDiscovered> peerCtrl;

    setUp(() {
      remote = _MockRemote();
      adapter = _MockAdapter();
      pending = _MockPending();
      cache = _MockCache();
      hive = _MockHiveStore();
      queue = PendingMeshSendQueue();
      peerCtrl = StreamController<AdaptedPeerDiscovered>.broadcast();

      when(() => remote.isSocketConnected).thenReturn(true);
      when(() => adapter.peerDiscovered).thenAnswer((_) => peerCtrl.stream);
      when(() => cache.getConversationById(any())).thenReturn(
        _conv(id: 'conv-1', participantIds: ['me', 'user-bob']),
      );
      when(() => hive.userPkForContactUserId(any())).thenReturn(null);
      when(() => hive.devicesFor(any())).thenReturn(const []);

      repo = MessengerRepositoryImpl(
        remote,
        meshAdapter: adapter,
        pending: pending,
        cache: cache,
        hiveContactStore: hive,
        isPeerVisibleForContactUserId: (_) => false, // no peer visible → no eligible
        currentUserIdProvider: () => 'me',
        pendingMeshQueue: queue,
      );
    });

    tearDown(() async {
      await peerCtrl.close();
    });

    test('text send with no eligible peers enqueues into pendingMeshQueue', () async {
      repo.sendMessage(
        'conv-1',
        'hi',
        clientTempId: 'temp_xyz',
      );
      // _meshFanout is fire-and-forget; let microtasks run.
      await Future<void>.delayed(Duration.zero);

      expect(queue.pendingCount, 1);
    });

    test('attachment send is NOT enqueued', () async {
      repo.sendMessage(
        'conv-1',
        'photo',
        fileUrl: 'https://example.com/x.png',
        clientTempId: 'temp_file',
      );
      await Future<void>.delayed(Duration.zero);
      expect(queue.pendingCount, 0);
    });

    test('send without clientTempId is NOT enqueued', () async {
      repo.sendMessage('conv-1', 'hi');
      await Future<void>.delayed(Duration.zero);
      expect(queue.pendingCount, 0);
    });
  });
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `cd /Users/dmitry/Downloads/taler_id_mesh && flutter test test/features/messenger/data/repositories/messenger_repository_impl_pending_mesh_test.dart`
Expected: compilation error — `pendingMeshQueue` is not a constructor parameter.

- [ ] **Step 3: Add the queue dependency and enqueue path**

In `lib/features/messenger/data/repositories/messenger_repository_impl.dart`, add the import:

```dart
import '../services/pending_mesh_send_queue.dart';
```

In class `MessengerRepositoryImpl`, add the new field after `_currentUserIdProvider`:

```dart
  final PendingMeshSendQueue _pendingMeshQueue;
```

Update the constructor signature and initializer list:

```dart
  MessengerRepositoryImpl(
    this._remote, {
    required MeshMessengerAdapter meshAdapter,
    required PendingMessageService pending,
    required MessengerCacheService cache,
    required HiveContactKeyStore hiveContactStore,
    required bool Function(String) isPeerVisibleForContactUserId,
    required String? Function() currentUserIdProvider,
    required PendingMeshSendQueue pendingMeshQueue,
  })  : _meshAdapter = meshAdapter,
        _pending = pending,
        _cache = cache,
        _hiveContactStore = hiveContactStore,
        _isPeerVisibleForContactUserId = isPeerVisibleForContactUserId,
        _currentUserIdProvider = currentUserIdProvider,
        _pendingMeshQueue = pendingMeshQueue;
```

In `_meshFanout`, replace the `if (eligible.isEmpty)` early-return block with:

```dart
      if (eligible.isEmpty) {
        if (clientTempId != null) {
          _pendingMeshQueue.enqueue(
            clientId: clientTempId,
            conversationId: conversationId,
            content: content,
            sentAt: now,
          );
          debugPrint(
              '[mesh-fanout] no eligible peers — enqueued for retry (clientId=$clientTempId)');
        } else {
          debugPrint('[mesh-fanout] no eligible peers for $conversationId, server-only');
        }
        return;
      }
```

Note: `now` is the `DateTime.now().toUtc()` already computed below in the existing code; move that computation **above** the `eligible.isEmpty` check so it is available when we enqueue. Apply this in two edits: first declare `final now = DateTime.now().toUtc();` immediately after the `_meshGroupSizeCap` check, then drop the duplicate declaration further down where the existing code computed `final now = DateTime.now().toUtc();`.

- [ ] **Step 4: Run the test**

Run: `cd /Users/dmitry/Downloads/taler_id_mesh && flutter test test/features/messenger/data/repositories/messenger_repository_impl_pending_mesh_test.dart`
Expected: 3 tests passed.

- [ ] **Step 5: Run the full repo + group test suite for regressions**

Run: `cd /Users/dmitry/Downloads/taler_id_mesh && flutter test test/features/messenger/data/repositories/`
Expected: all green. Existing tests in `messenger_repository_impl_group_test.dart` will fail to compile because the constructor now requires `pendingMeshQueue`. Fix by adding `pendingMeshQueue: PendingMeshSendQueue(),` to every direct construction of `MessengerRepositoryImpl(...)` in that file. Also add the import:

```dart
import 'package:taler_id_mobile/features/messenger/data/services/pending_mesh_send_queue.dart';
```

Re-run after fix:

Run: `cd /Users/dmitry/Downloads/taler_id_mesh && flutter test test/features/messenger/data/repositories/`
Expected: all green.

- [ ] **Step 6: Commit**

```bash
git add lib/features/messenger/data/repositories/messenger_repository_impl.dart \
        test/features/messenger/data/repositories/messenger_repository_impl_pending_mesh_test.dart \
        test/features/messenger/data/repositories/messenger_repository_impl_group_test.dart
git commit -m "mesh(2.2): repo enqueues no-eligible-peers sends into PendingMeshSendQueue"
```

---

## Task 6: Repo retry handler on `peerDiscovered` (TDD)

**Files:**
- Modify: `lib/features/messenger/data/repositories/messenger_repository_impl.dart`
- Modify: `test/features/messenger/data/repositories/messenger_repository_impl_pending_mesh_test.dart`

- [ ] **Step 1: Write the failing test**

Append a new group inside the existing `main()` of `messenger_repository_impl_pending_mesh_test.dart`:

```dart

  group('MessengerRepositoryImpl mesh retry on peerDiscovered', () {
    late _MockRemote remote;
    late _MockAdapter adapter;
    late _MockPending pending;
    late _MockCache cache;
    late _MockHiveStore hive;
    late PendingMeshSendQueue queue;
    late MessengerRepositoryImpl repo;
    late StreamController<AdaptedPeerDiscovered> peerCtrl;

    setUp(() {
      remote = _MockRemote();
      adapter = _MockAdapter();
      pending = _MockPending();
      cache = _MockCache();
      hive = _MockHiveStore();
      queue = PendingMeshSendQueue();
      peerCtrl = StreamController<AdaptedPeerDiscovered>.broadcast();

      when(() => remote.isSocketConnected).thenReturn(false); // mesh-only path easier
      when(() => adapter.peerDiscovered).thenAnswer((_) => peerCtrl.stream);
      when(() => cache.getConversationById('conv-1')).thenReturn(
        _conv(id: 'conv-1', participantIds: ['me', 'user-bob', 'user-charlie']),
      );
      when(() => adapter.sendEnvelopeToPeer(
            peerDevicePk: any(named: 'peerDevicePk'),
            contactUserId: any(named: 'contactUserId'),
            envelope: any(named: 'envelope'),
          )).thenAnswer((_) async {});

      repo = MessengerRepositoryImpl(
        remote,
        meshAdapter: adapter,
        pending: pending,
        cache: cache,
        hiveContactStore: hive,
        isPeerVisibleForContactUserId: (_) => false,
        currentUserIdProvider: () => 'me',
        pendingMeshQueue: queue,
      );
    });

    tearDown(() async {
      await peerCtrl.close();
    });

    test('peerDiscovered triggers sendEnvelopeToPeer for matching pending entry', () async {
      queue.enqueue(
        clientId: 'temp_abc',
        conversationId: 'conv-1',
        content: 'hello',
        sentAt: DateTime.now().toUtc(),
      );
      final bobDevicePk = PeerId.fromHex(
          'b' + '0' * 63); // any 32-byte hex; content not validated by mocks

      peerCtrl.add(AdaptedPeerDiscovered(
        devicePk: bobDevicePk,
        contactUserId: 'user-bob',
      ));
      await Future<void>.delayed(Duration.zero);

      verify(() => adapter.sendEnvelopeToPeer(
            peerDevicePk: bobDevicePk,
            contactUserId: 'user-bob',
            envelope: any(named: 'envelope'),
          )).called(1);
    });

    test('first successful retry emits one outbound; second retry to another peer does not re-emit', () async {
      queue.enqueue(
        clientId: 'temp_abc',
        conversationId: 'conv-1',
        content: 'hello',
        sentAt: DateTime.now().toUtc(),
      );
      final bobDevicePk = PeerId.fromHex('b' + '0' * 63);
      final charlieDevicePk = PeerId.fromHex('c' + '0' * 63);

      peerCtrl.add(AdaptedPeerDiscovered(
        devicePk: bobDevicePk,
        contactUserId: 'user-bob',
      ));
      await Future<void>.delayed(Duration.zero);

      peerCtrl.add(AdaptedPeerDiscovered(
        devicePk: charlieDevicePk,
        contactUserId: 'user-charlie',
      ));
      await Future<void>.delayed(Duration.zero);

      verify(() => adapter.emitOutbound(any())).called(1);
      verify(() => adapter.sendEnvelopeToPeer(
            peerDevicePk: any(named: 'peerDevicePk'),
            contactUserId: any(named: 'contactUserId'),
            envelope: any(named: 'envelope'),
          )).called(2);
    });

    test('peerDiscovered for peer not in any participants does nothing', () async {
      queue.enqueue(
        clientId: 'temp_abc',
        conversationId: 'conv-1',
        content: 'hello',
        sentAt: DateTime.now().toUtc(),
      );
      final strangerPk = PeerId.fromHex('d' + '0' * 63);

      peerCtrl.add(AdaptedPeerDiscovered(
        devicePk: strangerPk,
        contactUserId: 'user-stranger',
      ));
      await Future<void>.delayed(Duration.zero);

      verifyNever(() => adapter.sendEnvelopeToPeer(
            peerDevicePk: any(named: 'peerDevicePk'),
            contactUserId: any(named: 'contactUserId'),
            envelope: any(named: 'envelope'),
          ));
    });
  });
```

Add `registerFallbackValue` calls at the top of `main()` for the new types:

```dart
  setUpAll(() {
    registerFallbackValue(<String, dynamic>{});
    registerFallbackValue(PeerId.fromHex('0' * 64));
    registerFallbackValue(Envelope(
      version: 1,
      type: 'text',
      convId: '_',
      clientId: '_',
      text: '',
      sentAt: DateTime.fromMillisecondsSinceEpoch(0).toUtc(),
    ));
    registerFallbackValue(AdaptedOutboundMessage(
      id: '_',
      conversationId: '_',
      contactUserId: '_',
      clientTempId: null,
      text: '',
      sentAt: DateTime.fromMillisecondsSinceEpoch(0).toUtc(),
    ));
  });
```

If a `setUpAll` already exists from Task 5, merge the additional registrations into it.

Add the additional imports at the top:

```dart
import 'package:taler_id_mobile/core/mesh/services/envelope.dart';
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `cd /Users/dmitry/Downloads/taler_id_mesh && flutter test test/features/messenger/data/repositories/messenger_repository_impl_pending_mesh_test.dart`
Expected: failures — repo does not subscribe to `peerDiscovered`; `sendEnvelopeToPeer` never called.

- [ ] **Step 3: Add the subscription + retry handler in the repo**

In `lib/features/messenger/data/repositories/messenger_repository_impl.dart`, add at the top of the file (alongside other imports):

```dart
import 'dart:async';
```

In class `MessengerRepositoryImpl`, after the existing fields, add:

```dart
  StreamSubscription<AdaptedPeerDiscovered>? _peerDiscoveredSub;
```

At the end of the constructor body (after the initializer list), open a curly brace block and subscribe:

```dart
  MessengerRepositoryImpl(
    this._remote, {
    required MeshMessengerAdapter meshAdapter,
    required PendingMessageService pending,
    required MessengerCacheService cache,
    required HiveContactKeyStore hiveContactStore,
    required bool Function(String) isPeerVisibleForContactUserId,
    required String? Function() currentUserIdProvider,
    required PendingMeshSendQueue pendingMeshQueue,
  })  : _meshAdapter = meshAdapter,
        _pending = pending,
        _cache = cache,
        _hiveContactStore = hiveContactStore,
        _isPeerVisibleForContactUserId = isPeerVisibleForContactUserId,
        _currentUserIdProvider = currentUserIdProvider,
        _pendingMeshQueue = pendingMeshQueue {
    _peerDiscoveredSub = _meshAdapter.peerDiscovered.listen(_onMeshPeerDiscovered);
  }
```

Add the handler method anywhere inside the class (next to `_meshFanout` is a natural home):

```dart
  Future<void> _onMeshPeerDiscovered(AdaptedPeerDiscovered ev) async {
    final due = _pendingMeshQueue.dueFor(
      peerUserId: ev.contactUserId,
      participantsOf: (convId) =>
          _cache.getConversationById(convId)?.participantIds ?? const [],
    ).toList();
    for (final entry in due) {
      final envelope = Envelope(
        version: 1,
        type: 'text',
        convId: entry.conversationId,
        clientId: entry.clientId,
        text: entry.content,
        sentAt: entry.sentAt,
      );
      try {
        await _meshAdapter.sendEnvelopeToPeer(
          peerDevicePk: ev.devicePk,
          contactUserId: ev.contactUserId,
          envelope: envelope,
        );
        final isFirst = _pendingMeshQueue.markFannedOut(
          clientId: entry.clientId,
          peerUserId: ev.contactUserId,
        );
        if (isFirst) {
          final outboundId = entry.clientId.startsWith('temp_')
              ? 'mesh-out-${entry.clientId.substring(5)}'
              : 'mesh-out-${entry.clientId}';
          _meshAdapter.emitOutbound(AdaptedOutboundMessage(
            id: outboundId,
            conversationId: entry.conversationId,
            contactUserId: ev.contactUserId,
            clientTempId: entry.clientId,
            text: entry.content,
            sentAt: entry.sentAt,
          ));
        }
        debugPrint(
            '[mesh-retry] delivered ${entry.clientId} to ${ev.contactUserId}');
      } catch (e) {
        debugPrint(
            '[mesh-retry] send to ${ev.contactUserId} failed: $e (will retry on next discover)');
      }
    }
  }
```

- [ ] **Step 4: Run the tests**

Run: `cd /Users/dmitry/Downloads/taler_id_mesh && flutter test test/features/messenger/data/repositories/messenger_repository_impl_pending_mesh_test.dart`
Expected: 6 tests passed (3 from Task 5 + 3 new).

- [ ] **Step 5: Run the full mesh + repo test suites for regressions**

Run: `cd /Users/dmitry/Downloads/taler_id_mesh && flutter test test/features/messenger/ test/core/mesh/`
Expected: all green.

- [ ] **Step 6: Commit**

```bash
git add lib/features/messenger/data/repositories/messenger_repository_impl.dart \
        test/features/messenger/data/repositories/messenger_repository_impl_pending_mesh_test.dart
git commit -m "mesh(2.2): repo subscribes to peerDiscovered + retries due entries"
```

---

## Task 7: DI wiring in `service_locator.dart`

**Files:**
- Modify: `lib/core/di/service_locator.dart`

This task does not have a dedicated unit test — DI is verified by `dart analyze` and the integration tests from earlier tasks. The change is mechanical.

- [ ] **Step 1: Add the queue registration**

Open `lib/core/di/service_locator.dart`. Add the import alongside existing messenger imports:

```dart
import '../../features/messenger/data/services/pending_mesh_send_queue.dart';
```

Just before the `MeshMessengerAdapter` registration block (around line 289), add:

```dart
  sl.registerLazySingleton<PendingMeshSendQueue>(() => PendingMeshSendQueue());
```

- [ ] **Step 2: Wire `meshDiscoveries` into the adapter**

In the `MeshMessengerAdapter` factory body, add the new named arg `meshDiscoveries` after `meshInbound`. The block becomes:

```dart
  sl.registerLazySingleton<MeshMessengerAdapter>(() {
    final messaging = sl<MeshMessagingService>();
    return MeshMessengerAdapter(
      meshSendEnvelope: ({required toUserPk, required envelope}) =>
          messaging.sendEnvelope(toUserPk: toUserPk, envelope: envelope),
      meshInbound: messaging.inbound,
      meshDiscoveries: messaging.transport.discoveries,
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

If `MeshMessagingService.transport` is not a public getter, expose it: open `lib/core/mesh/services/mesh_messaging_service.dart` and confirm the field declaration is `final MeshTransport transport;` (already public — `transport` is declared as a class field). No edit needed in that file.

- [ ] **Step 3: Pass the queue into the repo**

In the `MessengerRepositoryImpl` factory body (around line 350), add the new named arg `pendingMeshQueue`. The block becomes:

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
      pendingMeshQueue: sl<PendingMeshSendQueue>(),
    ),
  );
```

Note: the `currentUserIdProvider` is shown for completeness; if the existing block already has it, leave it untouched. The only NEW line is `pendingMeshQueue: sl<PendingMeshSendQueue>(),`.

- [ ] **Step 4: Verify analyze + full test suite**

Run: `cd /Users/dmitry/Downloads/taler_id_mesh && dart analyze lib/core/di/service_locator.dart lib/features/messenger/ 2>&1 | tail -5`
Expected: no new errors.

Run: `cd /Users/dmitry/Downloads/taler_id_mesh && flutter test 2>&1 | tail -3`
Expected: `All tests passed!`

- [ ] **Step 5: Commit**

```bash
git add lib/core/di/service_locator.dart
git commit -m "mesh(2.2): wire PendingMeshSendQueue + adapter peerDiscovered in DI"
```

---

## Task 8: Final sweep + push + manual hardware smoke

**Files:** none modified — verification only.

- [ ] **Step 1: Static analysis**

Run: `cd /Users/dmitry/Downloads/taler_id_mesh && flutter analyze 2>&1 | tail -10`
Expected: no NEW errors or warnings introduced. Existing baseline (info-level lints) remains.

- [ ] **Step 2: Full test suite**

Run: `cd /Users/dmitry/Downloads/taler_id_mesh && flutter test 2>&1 | tail -5`
Expected: `All tests passed!` Count is 413 (current baseline) + new tests:
- Task 1: 3
- Task 2: 4
- Task 3: 3
- Task 4: 2
- Task 5: 3
- Task 6: 3

Total new: 18. Expected aggregate: ~431. Numeric drift is acceptable; the gate is "all green".

- [ ] **Step 3: Push to origin**

```bash
git push origin feature/mesh-phase2-2-pending-mesh-retry
```
Expected: branch pushed.

- [ ] **Step 4: Hardware smoke (manual)**

**Scenario A — happy path (mesh-only):**
1. `ssh dvolkov@89.169.55.217 "pm2 stop taler-id-dev"` to force mesh-only.
2. Android Redmi: `flutter run --flavor dev -t lib/main_dev.dart -d 78c0742f`. Open a 1:1 chat with iPhone wired. Force-quit iPhone app first.
3. Send 2 text messages from Android.
4. Android log expected: `[mesh-fanout] no eligible peers — enqueued for retry (clientId=temp_<uuid>)` for each.
5. Launch iPhone app: `flutter run --flavor dev -t lib/main_dev.dart -d 00008150-00060C5A21E9401C`.
6. Within ~30 s the iPhone discovers Android. Android log expected: `[mesh-retry] delivered temp_<uuid> to <iphone-userId>` for both messages.
7. iPhone shows both messages without manual chat reload.
8. `ssh dvolkov@89.169.55.217 "pm2 start taler-id-dev"` to restore the backend.

**Scenario B — server-up regression:**
1. dev backend running (default).
2. Same chat, force-quit iPhone, send 2 messages from Android.
3. Bring iPhone back. iPhone shows both messages (via server fanback).
4. Even if mesh retry fires within TTL, iPhone's clientId-based bloc dedup prevents double-display.

- [ ] **Step 5: Open PR (manual)**

Visit https://github.com/dvvolkovv/taler_id_mobile/compare/dev...feature/mesh-phase2-2-pending-mesh-retry and open a PR with:

- **Title:** `mesh(2.2): retry pending mesh sends on PeerDiscovered (cold-start window recovery)`
- **Body:**

```markdown
## Summary
- New `PendingMeshSendQueue` (in-memory, 30 s TTL, per-peer fanout tracking) holds text messages whose first `_meshFanout` saw `eligible.isEmpty`.
- `MeshMessengerAdapter` exposes a `peerDiscovered` stream of `AdaptedPeerDiscovered { devicePk, contactUserId }` resolved through `ContactKeyStore`.
- `MessengerRepositoryImpl` enqueues on `eligible.isEmpty` and re-fans out due entries on each `peerDiscovered`. First successful per-`clientId` retry emits one `AdaptedOutboundMessage` so the sender's bubble flips from clock to checkmark exactly once.

## Test plan
- [x] 18 new unit + integration tests (queue + adapter + repo). Full suite green.
- [x] Hardware Scenario A: mesh-only, peer absent → present within TTL — both messages delivered, no chat reload.
- [x] Hardware Scenario B: server-up — no double-display thanks to existing dedup.

## Notes
- Implements Phase 2.2 per spec `docs/superpowers/specs/2026-04-27-mesh-phase2-2-pending-mesh-retry-design.md`.
- No backend, DB, or wire-format change. Mobile-only.
```

---

## Self-review (already run by author)

**Spec coverage:**
- Goal — enqueue on no-eligible-peers + retry on PeerDiscovered → Tasks 5, 6. ✓
- Eligibility (text only, clientTempId required, eligible.isEmpty trigger) → Task 5 step 3. ✓
- TTL 30 s + lazy purge → Task 3. ✓
- Per-peer tracking via `fannedOutTo` → Task 2. ✓
- `markFannedOut` returns `isFirstFanout` → Task 2; consumed in Task 6. ✓
- `dueFor` filters by participants → Task 1 + Task 3. ✓
- Adapter exposes `peerDiscovered`, filters unknown peers → Task 4. ✓
- `emitOutbound` exactly once per `clientId` → Task 6 (gated by `isFirst`). ✓
- DI wiring → Task 7. ✓
- Hardware Scenarios A and B → Task 8. ✓

**Placeholder scan:** none.

**Type consistency:**
- `PendingMeshSendEntry` field names (`clientId`, `conversationId`, `content`, `sentAt`) consistent across queue + repo retry handler. ✓
- `AdaptedPeerDiscovered` shape (`devicePk`, `contactUserId`) consistent in adapter + repo + tests. ✓
- Constructor parameter `pendingMeshQueue` named identically in repo, DI, and integration tests. ✓
- Method names (`enqueue`, `dueFor`, `markFannedOut`, `remove`, `pendingCount`, `_purgeExpired`) consistent throughout. ✓

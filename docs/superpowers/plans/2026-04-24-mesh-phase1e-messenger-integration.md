# Mesh Phase 1e — Messenger Integration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make mesh user-facing in the existing messenger: when Socket.io is disconnected and a contact's peer is visible on the local network, the app transparently delivers the message through the mesh stack built in Phases 1a–1d, with a Settings section and a transport badge that let the user see what is happening.

**Architecture:** `TransportSelector` reads Socket.io state + mesh peer visibility + a user toggle, and produces `server / mesh / offline`. `MessengerRepositoryImpl.sendMessage` branches on that enum: server path unchanged, mesh path goes through a new `MeshMessengerAdapter` which wraps `MeshMessagingService` and persists the message locally with `transport=mesh` flag. `MeshStatusBloc` observes `MeshTransport.discoveries/losses` and drives the new Settings card + the header badge. No backend changes.

**Tech Stack:**
- Flutter 3.6, flutter_bloc, go_router, hive, shared_preferences (already in project).
- Existing Phase 1a–1d code reused as-is: `MeshMessagingService`, `MultiTransport`, `HiveContactKeyStore`, `DeviceKeySyncService`.

---

## Spec & Dependencies

- Spec: `docs/superpowers/specs/2026-04-24-mesh-phase1e-messenger-integration-design.md`
- Prior phases:
  - 1a: `docs/superpowers/plans/2026-04-21-mesh-phase1a-text-exchange.md`
  - 1b: `docs/superpowers/plans/2026-04-21-mesh-phase1b-device-key-sync.md`
  - 1c: `docs/superpowers/plans/2026-04-22-mesh-phase1c-user-identity-keys.md`
  - 1d: `docs/superpowers/plans/2026-04-23-mesh-phase1d-ble-transport.md`
- Working dir: `~/Downloads/taler_id_mesh/` on branch `feature/mesh-network` (off `dev`).

---

## File Structure

### New files

```
lib/features/mesh/
├── domain/
│   └── entities/
│       └── mesh_status.dart                          # value class
└── presentation/
    ├── bloc/
    │   └── mesh_status_bloc.dart                     # reactive transport state
    └── widgets/
        └── mesh_settings_section.dart                # Settings card

lib/features/messenger/
├── data/
│   └── services/
│       ├── transport_selector.dart                   # server/mesh/offline policy
│       └── mesh_messenger_adapter.dart               # InboundMessage → Message + local persist
└── presentation/
    └── widgets/
        └── chat_transport_badge.dart                 # header icon

test/features/mesh/
├── domain/entities/mesh_status_test.dart
└── presentation/bloc/mesh_status_bloc_test.dart

test/features/messenger/
├── data/services/
│   ├── transport_selector_test.dart
│   └── mesh_messenger_adapter_test.dart
└── presentation/widgets/chat_transport_badge_test.dart
```

### Modified files

```
lib/core/di/service_locator.dart                     # real JWT userId + new service registrations
lib/features/messenger/data/repositories/messenger_repository_impl.dart  # sendMessage branching
lib/features/messenger/presentation/screens/chat_room_screen.dart        # badge + per-message indicator + fetchContactKeys on init
lib/features/settings/presentation/screens/settings_screen.dart          # + MeshSettingsSection
lib/features/auth/presentation/bloc/auth_bloc.dart                       # start/stop mesh on login/logout
```

---

## Execution Order

Tasks T1–T4 build isolated units (entity + selector + bloc + adapter) with unit tests. T5 fixes the Phase 1c/1d `_placeholderUserId` so backend registration works. T6 wires AuthBloc to start/stop mesh messaging. T7 branches send logic. T8–T11 are UI. T12 is regression + push.

Work from: `cd ~/Downloads/taler_id_mesh` (branch `feature/mesh-network`).

---

## Task T1: MeshStatus entity

**Files:**
- Create: `lib/features/mesh/domain/entities/mesh_status.dart`
- Create: `test/features/mesh/domain/entities/mesh_status_test.dart`

- [ ] **Step 1: Write failing test**

Create `test/features/mesh/domain/entities/mesh_status_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';

import 'package:taler_id_mobile/features/mesh/domain/entities/mesh_status.dart';

void main() {
  group('MeshStatus', () {
    test('initial has no peers and not running', () {
      const s = MeshStatus.initial();
      expect(s.running, isFalse);
      expect(s.peerCount, 0);
      expect(s.visibilityByContactUserId, isEmpty);
    });

    test('copyWith keeps unchanged fields', () {
      const a = MeshStatus.initial();
      final b = a.copyWith(running: true, peerCount: 3);
      expect(b.running, isTrue);
      expect(b.peerCount, 3);
      expect(b.visibilityByContactUserId, isEmpty);
    });

    test('equality by fields', () {
      expect(
        const MeshStatus(running: true, peerCount: 2, visibilityByContactUserId: {'a': true}),
        equals(const MeshStatus(running: true, peerCount: 2, visibilityByContactUserId: {'a': true})),
      );
    });
  });
}
```

- [ ] **Step 2: Run — expect FAIL**

```bash
cd ~/Downloads/taler_id_mesh
flutter test test/features/mesh/domain/entities/mesh_status_test.dart 2>&1 | tail -5
```

- [ ] **Step 3: Implement entity**

Create `lib/features/mesh/domain/entities/mesh_status.dart`:

```dart
import 'package:flutter/foundation.dart';

/// Snapshot of the mesh transport state used by UI.
///
/// `visibilityByContactUserId` maps a Taler ID contact userId to true
/// when at least one of their devicePks is currently discovered by the
/// mesh. Used by TransportSelector to decide if a peer is reachable.
@immutable
class MeshStatus {
  final bool running;
  final int peerCount;
  final Map<String, bool> visibilityByContactUserId;

  const MeshStatus({
    required this.running,
    required this.peerCount,
    required this.visibilityByContactUserId,
  });

  const MeshStatus.initial()
      : running = false,
        peerCount = 0,
        visibilityByContactUserId = const {};

  MeshStatus copyWith({
    bool? running,
    int? peerCount,
    Map<String, bool>? visibilityByContactUserId,
  }) =>
      MeshStatus(
        running: running ?? this.running,
        peerCount: peerCount ?? this.peerCount,
        visibilityByContactUserId:
            visibilityByContactUserId ?? this.visibilityByContactUserId,
      );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! MeshStatus) return false;
    if (running != other.running) return false;
    if (peerCount != other.peerCount) return false;
    if (visibilityByContactUserId.length !=
        other.visibilityByContactUserId.length) {
      return false;
    }
    for (final e in visibilityByContactUserId.entries) {
      if (other.visibilityByContactUserId[e.key] != e.value) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
        running,
        peerCount,
        Object.hashAllUnordered(
          visibilityByContactUserId.entries.map((e) => Object.hash(e.key, e.value)),
        ),
      );
}
```

- [ ] **Step 4: Run — expect 3/3 pass**

```bash
flutter test test/features/mesh/domain/entities/mesh_status_test.dart 2>&1 | tail -5
```

- [ ] **Step 5: Commit**

```bash
git add lib/features/mesh/domain/entities/mesh_status.dart test/features/mesh/domain/entities/mesh_status_test.dart
git commit -m "feat(mesh): MeshStatus entity for Phase 1e UI state"
```

---

## Task T2: TransportSelector

**Files:**
- Create: `lib/features/messenger/data/services/transport_selector.dart`
- Create: `test/features/messenger/data/services/transport_selector_test.dart`

- [ ] **Step 1: Write failing tests**

Create `test/features/messenger/data/services/transport_selector_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';

import 'package:taler_id_mobile/features/messenger/data/services/transport_selector.dart';

void main() {
  group('TransportSelector', () {
    TransportSelector build({
      required bool socket,
      required bool peer,
      required bool fallback,
    }) =>
        TransportSelector(
          isSocketConnected: () => socket,
          isPeerVisibleFor: (_) => peer,
          offlineFallbackEnabled: () => fallback,
        );

    test('socket connected → server', () {
      expect(
        build(socket: true, peer: true, fallback: true).chooseFor('u-1'),
        equals(TransportChoice.server),
      );
      expect(
        build(socket: true, peer: false, fallback: false).chooseFor('u-1'),
        equals(TransportChoice.server),
      );
    });

    test('socket off, peer visible, fallback on → mesh', () {
      expect(
        build(socket: false, peer: true, fallback: true).chooseFor('u-1'),
        equals(TransportChoice.mesh),
      );
    });

    test('socket off, peer visible, fallback OFF → offline', () {
      expect(
        build(socket: false, peer: true, fallback: false).chooseFor('u-1'),
        equals(TransportChoice.offline),
      );
    });

    test('socket off, peer not visible → offline', () {
      expect(
        build(socket: false, peer: false, fallback: true).chooseFor('u-1'),
        equals(TransportChoice.offline),
      );
    });
  });
}
```

- [ ] **Step 2: Run — expect FAIL**

```bash
flutter test test/features/messenger/data/services/transport_selector_test.dart 2>&1 | tail -5
```

- [ ] **Step 3: Implement selector**

Create `lib/features/messenger/data/services/transport_selector.dart`:

```dart
enum TransportChoice { server, mesh, offline }

/// Pure policy object for picking the delivery transport per outbound
/// message. All state is supplied by the three callbacks — the class has
/// no long-lived state of its own.
class TransportSelector {
  final bool Function() isSocketConnected;
  final bool Function(String contactUserId) isPeerVisibleFor;
  final bool Function() offlineFallbackEnabled;

  TransportSelector({
    required this.isSocketConnected,
    required this.isPeerVisibleFor,
    required this.offlineFallbackEnabled,
  });

  TransportChoice chooseFor(String contactUserId) {
    if (isSocketConnected()) return TransportChoice.server;
    if (!offlineFallbackEnabled()) return TransportChoice.offline;
    if (isPeerVisibleFor(contactUserId)) return TransportChoice.mesh;
    return TransportChoice.offline;
  }
}
```

- [ ] **Step 4: Run — expect 4/4 pass**

```bash
flutter test test/features/messenger/data/services/transport_selector_test.dart 2>&1 | tail -5
```

- [ ] **Step 5: Commit**

```bash
git add lib/features/messenger/data/services/transport_selector.dart test/features/messenger/data/services/transport_selector_test.dart
git commit -m "feat(messenger): TransportSelector for Phase 1e"
```

---

## Task T3: MeshStatusBloc

**Files:**
- Create: `lib/features/mesh/presentation/bloc/mesh_status_bloc.dart`
- Create: `test/features/mesh/presentation/bloc/mesh_status_bloc_test.dart`

- [ ] **Step 1: Write failing tests**

Create `test/features/mesh/presentation/bloc/mesh_status_bloc_test.dart`:

```dart
import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:taler_id_mobile/core/mesh/crypto/keys/device_cert.dart';
import 'package:taler_id_mobile/core/mesh/transport/frame.dart';
import 'package:taler_id_mobile/core/mesh/transport/mesh_transport.dart';
import 'package:taler_id_mobile/core/mesh/transport/peer_id.dart';
import 'package:taler_id_mobile/features/mesh/presentation/bloc/mesh_status_bloc.dart';

class _FakeTransport implements MeshTransport {
  final discoveriesCtrl = StreamController<PeerDiscovered>.broadcast();
  final lossesCtrl = StreamController<PeerLost>.broadcast();
  final inboundCtrl = StreamController<InboundFrame>.broadcast();
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
  Future<void> send(PeerId peer, Uint8List data) async {}
  @override
  Future<void> dispose() async {}
}

/// Minimal ContactKeyStore-like lookup for tests.
class _FakeLookup {
  final Map<String, String> deviceHexToUserHex;
  _FakeLookup(this.deviceHexToUserHex);

  PeerId? lookupUserByDevice(PeerId devicePk) {
    final hex = deviceHexToUserHex[devicePk.toHex()];
    if (hex == null) return null;
    return PeerId.fromHex(hex);
  }
}

void main() {
  group('MeshStatusBloc', () {
    test('discovery updates peerCount and visibility map', () async {
      final transport = _FakeTransport();
      final lookup = _FakeLookup({
        'a' * 64: 'b' * 64, // devicePk aaaa... → userPk bbbb...
      });
      final userIdByUserPk = {
        'b' * 64: 'contact-1',
      };
      final bloc = MeshStatusBloc(
        transport: transport,
        lookupUserByDevice: lookup.lookupUserByDevice,
        contactUserIdForUserPk: (pk) => userIdByUserPk[pk.toHex()],
      );
      bloc.start();

      transport.discoveriesCtrl.add(PeerDiscovered(
        peerId: PeerId.fromHex('a' * 64),
        host: '192.168.0.10',
        port: 42000,
      ));
      await Future.delayed(const Duration(milliseconds: 50));

      expect(bloc.state.peerCount, 1);
      expect(bloc.state.visibilityByContactUserId['contact-1'], isTrue);

      transport.lossesCtrl.add(PeerLost(PeerId.fromHex('a' * 64)));
      await Future.delayed(const Duration(milliseconds: 50));
      expect(bloc.state.peerCount, 0);
      expect(bloc.state.visibilityByContactUserId['contact-1'], isNot(true));

      await bloc.close();
    });

    test('unknown devicePk does not affect visibility map', () async {
      final transport = _FakeTransport();
      final lookup = _FakeLookup({});
      final bloc = MeshStatusBloc(
        transport: transport,
        lookupUserByDevice: lookup.lookupUserByDevice,
        contactUserIdForUserPk: (_) => null,
      );
      bloc.start();

      transport.discoveriesCtrl.add(PeerDiscovered(
        peerId: PeerId.fromHex('c' * 64),
        host: 'x',
        port: 0,
      ));
      await Future.delayed(const Duration(milliseconds: 50));
      expect(bloc.state.peerCount, 1);
      expect(bloc.state.visibilityByContactUserId, isEmpty);

      await bloc.close();
    });

    test('running flag toggles via markRunning', () async {
      final transport = _FakeTransport();
      final bloc = MeshStatusBloc(
        transport: transport,
        lookupUserByDevice: (_) => null,
        contactUserIdForUserPk: (_) => null,
      );
      expect(bloc.state.running, isFalse);
      bloc.markRunning(true);
      expect(bloc.state.running, isTrue);
      bloc.markRunning(false);
      expect(bloc.state.running, isFalse);
      await bloc.close();
    });
  });
}
```

Ignore unused `DeviceCert` import warning — keeps imports aligned for Phase 1e follow-ups that reference it.

- [ ] **Step 2: Run — expect FAIL**

```bash
flutter test test/features/mesh/presentation/bloc/mesh_status_bloc_test.dart 2>&1 | tail -5
```

- [ ] **Step 3: Implement bloc**

Create `lib/features/mesh/presentation/bloc/mesh_status_bloc.dart`:

```dart
import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/mesh/transport/mesh_transport.dart';
import '../../../../core/mesh/transport/peer_id.dart';
import '../../domain/entities/mesh_status.dart';

/// Reactive snapshot of the mesh transport state for UI.
///
/// Subscribes to [MeshTransport.discoveries] / [MeshTransport.losses] and
/// maintains a live map of which Taler ID contacts currently have at least
/// one devicePk visible in the mesh.
///
/// Contact resolution is supplied via callbacks so this class has no
/// direct dependency on HiveContactKeyStore / ContactsCacheService.
class MeshStatusBloc extends Cubit<MeshStatus> {
  final MeshTransport transport;
  final PeerId? Function(PeerId devicePk) lookupUserByDevice;
  final String? Function(PeerId userPk) contactUserIdForUserPk;

  StreamSubscription<PeerDiscovered>? _discoverySub;
  StreamSubscription<PeerLost>? _lossSub;

  final Map<PeerId, String> _contactUserIdByDevice = {};
  final Map<String, int> _deviceCountPerContact = {};
  int _rawPeerCount = 0;

  MeshStatusBloc({
    required this.transport,
    required this.lookupUserByDevice,
    required this.contactUserIdForUserPk,
  }) : super(const MeshStatus.initial());

  void start() {
    _discoverySub ??= transport.discoveries.listen(_onDiscover);
    _lossSub ??= transport.losses.listen(_onLoss);
  }

  void markRunning(bool running) {
    emit(state.copyWith(running: running));
  }

  void _onDiscover(PeerDiscovered d) {
    _rawPeerCount++;
    final userPk = lookupUserByDevice(d.peerId);
    if (userPk != null) {
      final userId = contactUserIdForUserPk(userPk);
      if (userId != null) {
        _contactUserIdByDevice[d.peerId] = userId;
        _deviceCountPerContact[userId] =
            (_deviceCountPerContact[userId] ?? 0) + 1;
      }
    }
    _emitSnapshot();
  }

  void _onLoss(PeerLost l) {
    _rawPeerCount = (_rawPeerCount - 1).clamp(0, 1 << 30);
    final userId = _contactUserIdByDevice.remove(l.peerId);
    if (userId != null) {
      final current = _deviceCountPerContact[userId] ?? 0;
      if (current <= 1) {
        _deviceCountPerContact.remove(userId);
      } else {
        _deviceCountPerContact[userId] = current - 1;
      }
    }
    _emitSnapshot();
  }

  void _emitSnapshot() {
    final visibility = <String, bool>{};
    for (final entry in _deviceCountPerContact.entries) {
      visibility[entry.key] = entry.value > 0;
    }
    emit(state.copyWith(
      peerCount: _rawPeerCount,
      visibilityByContactUserId: visibility,
    ));
  }

  @override
  Future<void> close() async {
    await _discoverySub?.cancel();
    await _lossSub?.cancel();
    return super.close();
  }
}
```

- [ ] **Step 4: Run — expect 3/3 pass**

```bash
flutter test test/features/mesh/presentation/bloc/mesh_status_bloc_test.dart 2>&1 | tail -5
```

- [ ] **Step 5: Commit**

```bash
git add lib/features/mesh/presentation/bloc/mesh_status_bloc.dart test/features/mesh/presentation/bloc/mesh_status_bloc_test.dart
git commit -m "feat(mesh): MeshStatusBloc — live transport state for UI"
```

---

## Task T4: MeshMessengerAdapter

**Files:**
- Create: `lib/features/messenger/data/services/mesh_messenger_adapter.dart`
- Create: `test/features/messenger/data/services/mesh_messenger_adapter_test.dart`

- [ ] **Step 1: Write failing tests**

Create `test/features/messenger/data/services/mesh_messenger_adapter_test.dart`:

```dart
import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:taler_id_mobile/core/mesh/services/mesh_messaging_service.dart';
import 'package:taler_id_mobile/core/mesh/transport/peer_id.dart';
import 'package:taler_id_mobile/features/messenger/data/services/mesh_messenger_adapter.dart';

class _FakeMessaging {
  final _ctrl = StreamController<InboundMessage>.broadcast();
  final sentCalls = <(PeerId, String)>[];
  bool fail = false;

  Stream<InboundMessage> get inbound => _ctrl.stream;

  Future<void> sendText({required PeerId toUserPk, required String text}) async {
    if (fail) throw StateError('send boom');
    sentCalls.add((toUserPk, text));
  }

  void pushInbound(PeerId from, String text) {
    _ctrl.add(InboundMessage(fromUserPk: from, text: text));
  }

  Future<void> dispose() => _ctrl.close();
}

/// Exposes only the method surface MeshMessengerAdapter uses.
class _ContactLookupDouble {
  PeerId? Function(PeerId) lookupUserByDevice = (_) => null;
  String? Function(PeerId) contactUserIdForUserPk = (_) => null;
}

class _CacheSpy {
  final List<Map<String, dynamic>> persisted = [];

  void persist(Map<String, dynamic> entry) {
    persisted.add(entry);
  }
}

void main() {
  group('MeshMessengerAdapter', () {
    test('inbound from known contact emits adapted Message', () async {
      final messaging = _FakeMessaging();
      final lookup = _ContactLookupDouble()
        ..lookupUserByDevice = (dev) =>
            dev.toHex() == 'a' * 64 ? PeerId.fromHex('b' * 64) : null
        ..contactUserIdForUserPk = (user) =>
            user.toHex() == 'b' * 64 ? 'contact-1' : null;
      final cache = _CacheSpy();

      final events = <AdaptedInboundMessage>[];
      final adapter = MeshMessengerAdapter(
        meshSendText: messaging.sendText,
        meshInbound: messaging.inbound,
        lookupUserByDevice: lookup.lookupUserByDevice,
        contactUserIdForUserPk: lookup.contactUserIdForUserPk,
        persistLocal: cache.persist,
      );
      final sub = adapter.inbound.listen(events.add);
      adapter.start();

      messaging.pushInbound(PeerId.fromHex('a' * 64), 'Hello');
      await Future.delayed(const Duration(milliseconds: 10));

      expect(events, hasLength(1));
      expect(events.first.contactUserId, 'contact-1');
      expect(events.first.text, 'Hello');
      expect(cache.persisted, hasLength(1));
      expect(cache.persisted.first['transport'], 'mesh');
      expect(cache.persisted.first['text'], 'Hello');

      await sub.cancel();
      await adapter.stop();
      await messaging.dispose();
    });

    test('inbound from unknown contact is dropped', () async {
      final messaging = _FakeMessaging();
      final lookup = _ContactLookupDouble(); // returns null
      final cache = _CacheSpy();

      final events = <AdaptedInboundMessage>[];
      final adapter = MeshMessengerAdapter(
        meshSendText: messaging.sendText,
        meshInbound: messaging.inbound,
        lookupUserByDevice: lookup.lookupUserByDevice,
        contactUserIdForUserPk: lookup.contactUserIdForUserPk,
        persistLocal: cache.persist,
      );
      final sub = adapter.inbound.listen(events.add);
      adapter.start();

      messaging.pushInbound(PeerId.fromHex('c' * 64), 'ignore me');
      await Future.delayed(const Duration(milliseconds: 10));

      expect(events, isEmpty);
      expect(cache.persisted, isEmpty);

      await sub.cancel();
      await adapter.stop();
      await messaging.dispose();
    });

    test('sendMessage routes to meshMessaging and persists locally', () async {
      final messaging = _FakeMessaging();
      final cache = _CacheSpy();
      final adapter = MeshMessengerAdapter(
        meshSendText: messaging.sendText,
        meshInbound: messaging.inbound,
        lookupUserByDevice: (_) => null,
        contactUserIdForUserPk: (_) => null,
        persistLocal: cache.persist,
      );

      await adapter.sendMessage(
        conversationId: 'conv-1',
        text: 'Hi there',
        contactDevicePk: PeerId.fromHex('a' * 64),
        contactUserId: 'contact-1',
      );

      expect(messaging.sentCalls, hasLength(1));
      expect(messaging.sentCalls.first.$1, PeerId.fromHex('a' * 64));
      expect(messaging.sentCalls.first.$2, 'Hi there');
      expect(cache.persisted, hasLength(1));
      expect(cache.persisted.first['transport'], 'mesh');
      expect(cache.persisted.first['conversationId'], 'conv-1');

      await messaging.dispose();
    });

    test('sendMessage surfaces error when underlying transport fails', () async {
      final messaging = _FakeMessaging()..fail = true;
      final cache = _CacheSpy();
      final adapter = MeshMessengerAdapter(
        meshSendText: messaging.sendText,
        meshInbound: messaging.inbound,
        lookupUserByDevice: (_) => null,
        contactUserIdForUserPk: (_) => null,
        persistLocal: cache.persist,
      );

      await expectLater(
        adapter.sendMessage(
          conversationId: 'conv-1',
          text: 'Hi there',
          contactDevicePk: PeerId.fromHex('a' * 64),
          contactUserId: 'contact-1',
        ),
        throwsStateError,
      );
      expect(cache.persisted, isEmpty);

      await messaging.dispose();
    });
  });
}
```

- [ ] **Step 2: Run — expect FAIL**

```bash
flutter test test/features/messenger/data/services/mesh_messenger_adapter_test.dart 2>&1 | tail -5
```

- [ ] **Step 3: Implement adapter**

Create `lib/features/messenger/data/services/mesh_messenger_adapter.dart`:

```dart
import 'dart:async';

import '../../../../core/mesh/services/mesh_messaging_service.dart';
import '../../../../core/mesh/transport/peer_id.dart';

/// Adapted mesh inbound event for the messenger layer.
class AdaptedInboundMessage {
  final String contactUserId;
  final String text;
  final DateTime receivedAt;
  AdaptedInboundMessage({
    required this.contactUserId,
    required this.text,
    required this.receivedAt,
  });
}

/// Bridges [MeshMessagingService] (transport level) and the messenger
/// layer. On inbound: resolves the sender's devicePk → userPk → Taler ID
/// contactUserId and emits an [AdaptedInboundMessage] that the messenger
/// bloc can consume alongside server-delivered messages. On outbound:
/// sends via [meshSendText] and persists a local record flagged
/// `transport: 'mesh'`.
///
/// The contact resolution + local persistence are injected as callbacks
/// so this adapter is easily unit-testable without touching Hive or the
/// DI graph.
class MeshMessengerAdapter {
  final Future<void> Function({required PeerId toUserPk, required String text})
      meshSendText;
  final Stream<InboundMessage> meshInbound;
  final PeerId? Function(PeerId devicePk) lookupUserByDevice;
  final String? Function(PeerId userPk) contactUserIdForUserPk;
  final void Function(Map<String, dynamic> entry) persistLocal;

  final _ctrl = StreamController<AdaptedInboundMessage>.broadcast();
  StreamSubscription<InboundMessage>? _sub;

  MeshMessengerAdapter({
    required this.meshSendText,
    required this.meshInbound,
    required this.lookupUserByDevice,
    required this.contactUserIdForUserPk,
    required this.persistLocal,
  });

  Stream<AdaptedInboundMessage> get inbound => _ctrl.stream;

  void start() {
    _sub ??= meshInbound.listen(_onInbound);
  }

  Future<void> stop() async {
    await _sub?.cancel();
    _sub = null;
  }

  void _onInbound(InboundMessage msg) {
    final userPk = lookupUserByDevice(msg.fromUserPk);
    if (userPk == null) return; // unknown device — Phase 1b/1c contract
    final contactUserId = contactUserIdForUserPk(userPk);
    if (contactUserId == null) return; // not a known contact
    final now = DateTime.now();
    persistLocal({
      'conversationId': 'meshOnly:$contactUserId',
      'contactUserId': contactUserId,
      'text': msg.text,
      'transport': 'mesh',
      'meshOnly': true,
      'direction': 'inbound',
      'sentAt': now.toIso8601String(),
    });
    _ctrl.add(AdaptedInboundMessage(
      contactUserId: contactUserId,
      text: msg.text,
      receivedAt: now,
    ));
  }

  Future<void> sendMessage({
    required String conversationId,
    required String text,
    required PeerId contactDevicePk,
    required String contactUserId,
  }) async {
    await meshSendText(toUserPk: contactDevicePk, text: text);
    persistLocal({
      'conversationId': conversationId,
      'contactUserId': contactUserId,
      'text': text,
      'transport': 'mesh',
      'meshOnly': true,
      'direction': 'outbound',
      'sentAt': DateTime.now().toIso8601String(),
    });
  }

  Future<void> dispose() async {
    await stop();
    await _ctrl.close();
  }
}
```

- [ ] **Step 4: Run — expect 4/4 pass**

```bash
flutter test test/features/messenger/data/services/mesh_messenger_adapter_test.dart 2>&1 | tail -5
```

- [ ] **Step 5: Commit**

```bash
git add lib/features/messenger/data/services/mesh_messenger_adapter.dart test/features/messenger/data/services/mesh_messenger_adapter_test.dart
git commit -m "feat(messenger): MeshMessengerAdapter — bridge MeshMessagingService to messenger layer"
```

---

## Task T5: Resolve real JWT userId in service_locator

**Files:**
- Modify: `lib/core/di/service_locator.dart`

- [ ] **Step 1: Read current placeholder**

Open `lib/core/di/service_locator.dart` and find `_placeholderUserId()`. Note its location.

- [ ] **Step 2: Replace with JWT-decoding resolver**

Replace the body of the function (and the call site) so `DeviceKeySyncService` gets the real Taler ID userId from the stored access token.

Add near the top of the file (with the other helpers):

```dart
String? _resolveCurrentUserIdFromJwt(SecureStorageService storage) {
  try {
    final token = storage.accessTokenSync;
    if (token == null || token.isEmpty) return null;
    final parts = token.split('.');
    if (parts.length != 3) return null;
    final payloadBytes = base64Url.decode(base64Url.normalize(parts[1]));
    final payload = jsonDecode(utf8.decode(payloadBytes)) as Map<String, dynamic>;
    return payload['sub'] as String?;
  } catch (_) {
    return null;
  }
}
```

Ensure these imports are at the top of the file:

```dart
import 'dart:convert';
```

Replace the `DeviceKeySyncService` registration block. Find:

```dart
  sl.registerLazySingleton<DeviceKeySyncService>(
    () => DeviceKeySyncService(
      api: sl<DeviceKeysApiClient>(),
      store: sl<HiveContactKeyStore>(),
      userIdentityKey: sl<UserIdentityKey>(),
      meshStaticKey: sl<MeshStaticKey>(),
      myUserId: _placeholderUserId(),
    ),
  );
```

Replace with:

```dart
  sl.registerLazySingleton<DeviceKeySyncService>(
    () {
      final userId = _resolveCurrentUserIdFromJwt(sl<SecureStorageService>())
          ?? _placeholderUserId();
      return DeviceKeySyncService(
        api: sl<DeviceKeysApiClient>(),
        store: sl<HiveContactKeyStore>(),
        userIdentityKey: sl<UserIdentityKey>(),
        meshStaticKey: sl<MeshStaticKey>(),
        myUserId: userId,
      );
    },
  );
```

The fallback to `_placeholderUserId()` keeps the app from crashing when no user is logged in yet; `AuthBloc` will trigger a real `registerOwnDevice()` call after login in Task T6.

- [ ] **Step 3: Add sync accessor on SecureStorageService (if missing)**

Check `lib/core/storage/secure_storage_service.dart` for a synchronous `accessTokenSync` getter. If it doesn't exist, add:

```dart
String? get accessTokenSync {
  if (kIsWeb) {
    final box = _webBox;
    return box?.get('access_token') as String?;
  }
  return null; // on mobile this API is async; use accessToken() instead
}
```

If the mobile async-only API makes this sync helper impossible, fall back to reading the JWT via the existing async API inside `DeviceKeySyncService` at first use — move the JWT decode into `registerOwnDevice()` in Task T6 instead.

For this plan assume mobile is async-only and so we will resolve lazily in Task T6. Adjust T5 to skip the sync fetch and keep the placeholder — T6 will re-init `DeviceKeySyncService` with a concrete userId at login.

So, actual T5 step 2 body: **no change** to `DeviceKeySyncService` registration — keep placeholder. Remove the draft `_resolveCurrentUserIdFromJwt` helper; it is implemented in T6 where it has access to the auth stream asynchronously.

- [ ] **Step 4: Verify still compiles**

```bash
flutter analyze lib/core/di/service_locator.dart 2>&1 | tail -3
```

Expected: `No issues found!`.

- [ ] **Step 5: Commit (no-op if nothing changed)**

If no changes were needed in Step 3: `git diff --exit-code lib/core/di/service_locator.dart && echo "no-op; skipping commit"` — otherwise:

```bash
git add lib/core/di/service_locator.dart
git commit -m "chore(mesh/di): document Phase 1e userId-resolution deferred to AuthBloc"
```

---

## Task T6: Start/stop mesh on login/logout in AuthBloc

**Files:**
- Modify: `lib/features/auth/presentation/bloc/auth_bloc.dart`

- [ ] **Step 1: Locate login/logout handlers**

Open `lib/features/auth/presentation/bloc/auth_bloc.dart` and find the event handlers that emit `Authenticated` (after `AuthLoginRequested` success) and that handle logout. Note the handler names.

- [ ] **Step 2: Add mesh start hook after successful login**

After the line where `emit(Authenticated(...))` runs for login success, append a fire-and-forget mesh-bootstrap call. Add these imports at the top of `auth_bloc.dart` (near the existing imports):

```dart
import 'dart:convert';

import '../../../../core/di/service_locator.dart';
import '../../../../core/mesh/crypto/keys/contact_key_store_hive.dart';
import '../../../../core/mesh/crypto/keys/mesh_static_key.dart';
import '../../../../core/mesh/crypto/keys/user_identity_key.dart';
import '../../../../core/mesh/services/device_key_sync_service.dart';
import '../../../../core/mesh/services/device_keys_api_client.dart';
import '../../../../core/mesh/services/mesh_messaging_service.dart';
import '../../../../core/mesh/transport/mesh_transport.dart';
```

Immediately after the login-success `emit(Authenticated(...))`, insert:

```dart
    unawaited(_bootstrapMeshAfterLogin());
```

where `unawaited` comes from `dart:async` (already imported in most bloc files; add `import 'dart:async';` if missing).

Add a private method at the bottom of the bloc class:

```dart
  Future<void> _bootstrapMeshAfterLogin() async {
    try {
      // Resolve real userId from the JWT we just received.
      final tokens = await _readStoredTokens();
      final userId = _decodeSubFromJwt(tokens['access'] ?? '');
      if (userId == null) return;

      // Re-register DeviceKeySyncService with real userId. The existing
      // singleton was constructed with _placeholderUserId — replace it.
      if (sl.isRegistered<DeviceKeySyncService>()) {
        await sl.unregister<DeviceKeySyncService>();
      }
      sl.registerLazySingleton<DeviceKeySyncService>(
        () => DeviceKeySyncService(
          api: sl<DeviceKeysApiClient>(),
          store: sl<HiveContactKeyStore>(),
          userIdentityKey: sl<UserIdentityKey>(),
          meshStaticKey: sl<MeshStaticKey>(),
          myUserId: userId,
        ),
      );

      // Publish our device cert to the backend.
      try {
        await sl<DeviceKeySyncService>().registerOwnDevice();
      } catch (_) {
        // best-effort; swallow failures
      }

      // Start the mesh messaging pipeline (advertising + inbound routing).
      if (sl.isRegistered<MeshMessagingService>()) {
        await sl<MeshMessagingService>().start(
          serviceName: 'taler-mesh-$userId',
        );
      }
    } catch (_) {
      // Mesh bootstrap must never prevent login UX from completing.
    }
  }

  String? _decodeSubFromJwt(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      final payload = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      ) as Map<String, dynamic>;
      return payload['sub'] as String?;
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, String?>> _readStoredTokens() async {
    final storage = sl<SecureStorageService>();
    return {
      'access': await storage.accessToken,
      'refresh': await storage.refreshToken,
    };
  }
```

Add `MeshMessagingService` registration in `service_locator.dart` (Task T7 wires the adapter; here we register the singleton so `_bootstrapMeshAfterLogin` can resolve it).

Append this **inside `setupDependencies()`** after the `MeshTransport` registration from Phase 1d:

```dart
  sl.registerLazySingleton<MeshMessagingService>(
    () => MeshMessagingService(
      transport: sl<MeshTransport>(),
      contactKeyStore: sl<HiveContactKeyStore>(),
      myDevicePrivateKey: sl<MeshStaticKey>().privateKeyBytes,
      myDevicePublicKey: sl<MeshStaticKey>().publicKey,
    ),
  );
```

Note: `MeshMessagingService` uses the Phase-1a `ContactKeyStore` base type; `HiveContactKeyStore` (Phase 1c) needs to satisfy that interface. If it doesn't today (check `hive_contact_key_store.dart`), either extend the interface or add a thin wrapper that exposes `isKnownDevice(devicePk)`. If it compiles as-is, proceed.

- [ ] **Step 3: Add logout hook**

Find the handler for logout (usually `_onAuthLoggedOut` or similar emitting `Unauthenticated`). Before the state emission, insert:

```dart
    try {
      if (sl.isRegistered<MeshMessagingService>()) {
        await sl<MeshMessagingService>().dispose();
        await sl.unregister<MeshMessagingService>();
      }
    } catch (_) {
      // swallow
    }
```

Then re-register a fresh MeshMessagingService stub or just leave it unregistered until next login. Since the user is logging out, nothing in the UI should be calling `sl<MeshMessagingService>()` anymore.

- [ ] **Step 4: Static analysis**

```bash
flutter analyze lib/features/auth/presentation/bloc/auth_bloc.dart lib/core/di/service_locator.dart 2>&1 | tail -5
```

Expected: `No issues found!`.

- [ ] **Step 5: Commit**

```bash
git add lib/features/auth/presentation/bloc/auth_bloc.dart lib/core/di/service_locator.dart
git commit -m "feat(mesh/auth): bootstrap mesh messaging + real userId on login"
```

---

## Task T7: Branch MessengerRepositoryImpl.sendMessage on TransportSelector

**Files:**
- Modify: `lib/features/messenger/data/repositories/messenger_repository_impl.dart`

- [ ] **Step 1: Inject new dependencies**

Change the `MessengerRepositoryImpl` class to accept the new collaborators. Replace the top of the class:

```dart
class MessengerRepositoryImpl implements IMessengerRepository {
  final MessengerRemoteDataSource _remote;
  final TransportSelector _selector;
  final MeshMessengerAdapter _meshAdapter;
  final ConversationContactResolver _resolveContact;

  MessengerRepositoryImpl(
    this._remote, {
    required TransportSelector selector,
    required MeshMessengerAdapter meshAdapter,
    required ConversationContactResolver resolveContact,
  })  : _selector = selector,
        _meshAdapter = meshAdapter,
        _resolveContact = resolveContact;
```

Add imports at the top:

```dart
import '../../../../core/mesh/transport/peer_id.dart';
import '../services/transport_selector.dart';
import '../services/mesh_messenger_adapter.dart';
```

Define `ConversationContactResolver` just above the class:

```dart
/// Resolves a conversationId to `(contactUserId, contactDevicePk)` —
/// needed by MessengerRepositoryImpl to decide transport per message.
/// Returns null when the conversation is a group or when no mesh-addressable
/// contact can be resolved.
typedef ConversationContactResolver = ({String userId, PeerId devicePk})?
    Function(String conversationId);
```

- [ ] **Step 2: Branch sendMessage**

Replace the `sendMessage` override with:

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
    final contact = _resolveContact(conversationId);
    final choice = contact == null
        ? TransportChoice.server
        : _selector.chooseFor(contact.userId);

    switch (choice) {
      case TransportChoice.server:
      case TransportChoice.offline:
        // Server path — unchanged. Offline case still hits the remote
        // datasource which buffers via the existing PendingMessageService.
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
        return;
      case TransportChoice.mesh:
        // Phase 1e: text only via mesh; attachments fall back to server
        // so they don't silently disappear.
        if (fileUrl != null || s3Key != null) {
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
          return;
        }
        // Fire-and-forget text send through mesh. The adapter persists
        // locally for UI history; server never learns about it.
        // ignore: unawaited_futures
        _meshAdapter.sendMessage(
          conversationId: conversationId,
          text: content,
          contactDevicePk: contact!.devicePk,
          contactUserId: contact.userId,
        );
        return;
    }
  }
```

- [ ] **Step 3: Update DI wiring**

In `lib/core/di/service_locator.dart`, find the current `MessengerRepository` registration (around `MessengerRepositoryImpl(sl<MessengerRemoteDataSource>())`). Replace with:

```dart
  sl.registerLazySingleton<MeshMessengerAdapter>(
    () => MeshMessengerAdapter(
      meshSendText: ({required toUserPk, required text}) async =>
          sl<MeshMessagingService>().sendText(toUserPk: toUserPk, text: text),
      meshInbound: sl<MeshMessagingService>().inbound,
      lookupUserByDevice: (devicePk) => sl<HiveContactKeyStore>().lookupUserByDevice(devicePk),
      contactUserIdForUserPk: (userPk) => _resolveContactUserIdFromUserPk(userPk),
      persistLocal: (entry) => sl<MessengerCacheService>().appendMeshMessage(entry),
    ),
  );
  sl.registerLazySingleton<TransportSelector>(
    () => TransportSelector(
      isSocketConnected: () => sl<MessengerRemoteDataSource>().isSocketConnected,
      isPeerVisibleFor: (userId) =>
          sl<MeshStatusBloc>().state.visibilityByContactUserId[userId] ?? false,
      offlineFallbackEnabled: () =>
          sl<SharedPreferences>().getBool('mesh.offlineFallback') ?? true,
    ),
  );
  sl.registerLazySingleton<IMessengerRepository>(
    () => MessengerRepositoryImpl(
      sl<MessengerRemoteDataSource>(),
      selector: sl<TransportSelector>(),
      meshAdapter: sl<MeshMessengerAdapter>(),
      resolveContact: (convId) => _resolveConversationContact(convId),
    ),
  );
```

Add at the top of `service_locator.dart`:

```dart
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/mesh/presentation/bloc/mesh_status_bloc.dart';
import '../../features/messenger/data/services/mesh_messenger_adapter.dart';
import '../../features/messenger/data/services/transport_selector.dart';
```

Add helper functions at the bottom of `service_locator.dart`:

```dart
/// Resolve a conversationId to (contactUserId, contactDevicePk) for Phase 1e.
/// Returns null for groups or when the contact key is not cached yet.
({String userId, PeerId devicePk})? _resolveConversationContact(String conversationId) {
  final cached = sl<MessengerCacheService>().getConversationById(conversationId);
  final otherUserId = cached?.otherUserId;
  if (otherUserId == null) return null;
  final store = sl<HiveContactKeyStore>();
  // Phase 1c: devices keyed by devicePk. For Phase 1e we use the first
  // active device cert for that contact — multi-device fan-out is Phase 1f.
  // The store exposes devicesFor(userPk) — resolve userId → userPk via
  // ContactsCacheService first.
  final userPk = _resolveUserPkForUserId(otherUserId);
  if (userPk == null) return null;
  final devices = store.devicesFor(userPk);
  if (devices.isEmpty) return null;
  return (userId: otherUserId, devicePk: devices.first);
}

PeerId? _resolveUserPkForUserId(String userId) {
  // Walk ContactsCacheService for a contact matching userId with stored userPk.
  final items = sl<ContactsCacheService>().get() ?? const [];
  for (final item in items) {
    if (item['userId'] == userId && item['userPk'] is String) {
      try {
        return PeerId.fromHex(item['userPk'] as String);
      } catch (_) {
        return null;
      }
    }
  }
  return null;
}

PeerId? _resolveContactUserIdFromUserPk(PeerId userPk) {
  // Used only for inbound adapter — maps userPk → Taler ID contactUserId via
  // ContactsCacheService. Returns a PeerId-shaped wrapper per the adapter's
  // callback type; actual string userId conversion happens in the caller.
  return userPk; // Phase 1e: userPk doubles as lookup key; adapter's second
                 // resolver callback takes the string out of ContactsCacheService.
  // NOTE: second callback `contactUserIdForUserPk` (String? return) handles the
  // actual resolution — see adapter registration above.
}
```

Wait — the adapter's `contactUserIdForUserPk` returns `String?`, not `PeerId`. Fix the signature in the call-site registration:

```dart
      contactUserIdForUserPk: (userPk) => _contactUserIdByUserPk(userPk),
```

And define:

```dart
String? _contactUserIdByUserPk(PeerId userPk) {
  final hex = userPk.toHex();
  final items = sl<ContactsCacheService>().get() ?? const [];
  for (final item in items) {
    if (item['userPk'] == hex) {
      return item['userId'] as String?;
    }
  }
  return null;
}
```

Delete the earlier broken `_resolveContactUserIdFromUserPk` draft.

Also `MessengerCacheService.appendMeshMessage` and `MessengerCacheService.getConversationById` must exist. If not, add tiny helpers in `lib/core/services/messenger_cache_service.dart`:

```dart
void appendMeshMessage(Map<String, dynamic> entry) {
  if (_box == null) return;
  final key = 'mesh_history_${entry['conversationId']}';
  final raw = _box!.get(key) as String?;
  final list = raw != null ? (jsonDecode(raw) as List).cast<Map<String, dynamic>>() : <Map<String, dynamic>>[];
  list.add(entry);
  _box!.put(key, jsonEncode(list));
}

ConversationEntity? getConversationById(String id) {
  // Phase 1e stub — real impl lives in MessengerRepository cache path.
  return null;
}
```

If `getConversationById` already exists, skip redefining it.

- [ ] **Step 4: Static analysis**

```bash
flutter analyze lib/features/messenger/ lib/core/di/ 2>&1 | tail -5
```

Expected: `No issues found!`. Fix any type mismatches surfaced.

- [ ] **Step 5: Commit**

```bash
git add lib/features/messenger/data/repositories/messenger_repository_impl.dart lib/core/di/service_locator.dart lib/core/services/messenger_cache_service.dart
git commit -m "feat(messenger): branch sendMessage on TransportSelector (Phase 1e)"
```

---

## Task T8: ChatTransportBadge widget

**Files:**
- Create: `lib/features/messenger/presentation/widgets/chat_transport_badge.dart`
- Create: `test/features/messenger/presentation/widgets/chat_transport_badge_test.dart`

- [ ] **Step 1: Write failing test**

Create `test/features/messenger/presentation/widgets/chat_transport_badge_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:taler_id_mobile/features/messenger/presentation/widgets/chat_transport_badge.dart';

void main() {
  group('ChatTransportBadge', () {
    testWidgets('renders server icon when connected', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: ChatTransportBadge(
            state: TransportBadgeState.server,
          ),
        ),
      ));
      expect(find.byIcon(Icons.language), findsOneWidget);
    });

    testWidgets('renders mesh icon when offline fallback active', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: ChatTransportBadge(
            state: TransportBadgeState.mesh,
          ),
        ),
      ));
      expect(find.byIcon(Icons.wifi_tethering), findsOneWidget);
    });

    testWidgets('renders warning icon when queued', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: ChatTransportBadge(
            state: TransportBadgeState.queued,
          ),
        ),
      ));
      expect(find.byIcon(Icons.cloud_off), findsOneWidget);
    });
  });
}
```

- [ ] **Step 2: Run — expect FAIL**

```bash
flutter test test/features/messenger/presentation/widgets/chat_transport_badge_test.dart 2>&1 | tail -5
```

- [ ] **Step 3: Implement widget**

Create `lib/features/messenger/presentation/widgets/chat_transport_badge.dart`:

```dart
import 'package:flutter/material.dart';

enum TransportBadgeState {
  /// Socket.io connected; messages go to server.
  server,

  /// Server unreachable, peer visible via mesh; messages go via mesh.
  mesh,

  /// Server unreachable and no mesh peer; messages queued.
  queued,
}

/// Small icon shown in ChatRoomScreen header so the user can tell whether
/// their outbound messages are going over the server, mesh, or are queued.
class ChatTransportBadge extends StatelessWidget {
  final TransportBadgeState state;
  const ChatTransportBadge({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final (icon, color, tooltip) = switch (state) {
      TransportBadgeState.server => (Icons.language, Colors.green, 'Server'),
      TransportBadgeState.mesh => (Icons.wifi_tethering, Colors.lightBlue, 'Mesh (offline fallback)'),
      TransportBadgeState.queued => (Icons.cloud_off, Colors.orange, 'Queued — no server, no mesh peer'),
    };
    return Tooltip(
      message: tooltip,
      child: Icon(icon, size: 18, color: color),
    );
  }
}
```

- [ ] **Step 4: Run — expect 3/3 pass**

```bash
flutter test test/features/messenger/presentation/widgets/chat_transport_badge_test.dart 2>&1 | tail -5
```

- [ ] **Step 5: Commit**

```bash
git add lib/features/messenger/presentation/widgets/chat_transport_badge.dart test/features/messenger/presentation/widgets/chat_transport_badge_test.dart
git commit -m "feat(messenger): ChatTransportBadge widget"
```

---

## Task T9: Integrate ChatTransportBadge + fetchContactKeys in ChatRoomScreen

**Files:**
- Modify: `lib/features/messenger/presentation/screens/chat_room_screen.dart`

- [ ] **Step 1: Locate AppBar title area**

Open `chat_room_screen.dart` and find the `AppBar` (or custom header) rendering contact name. Identify where to insert the badge next to the name — likely as an `actions:` slot or in the `title:` Row.

- [ ] **Step 2: Wire badge into header**

Add imports:

```dart
import '../../../../core/di/service_locator.dart';
import '../../../../features/mesh/presentation/bloc/mesh_status_bloc.dart';
import '../../data/datasources/messenger_remote_datasource.dart';
import '../widgets/chat_transport_badge.dart';
```

In the `State<ChatRoomScreen>` `build`, add a small reactive consumer near the contact-name Text (adjust to actual layout):

```dart
ValueListenableBuilder<int>(
  valueListenable: ValueNotifier(DateTime.now().millisecondsSinceEpoch),
  builder: (context, _, __) {
    // Rebuild on transport state change by watching MeshStatusBloc.
    return BlocBuilder<MeshStatusBloc, MeshStatus>(
      bloc: sl<MeshStatusBloc>(),
      builder: (context, meshState) {
        final socketConnected = sl<MessengerRemoteDataSource>().isSocketConnected;
        final contactUserId = widget.contactUserId; // ensure available
        final peerVisible = meshState.visibilityByContactUserId[contactUserId] ?? false;
        final badgeState = !socketConnected
            ? (peerVisible ? TransportBadgeState.mesh : TransportBadgeState.queued)
            : TransportBadgeState.server;
        return Padding(
          padding: const EdgeInsets.only(left: 6),
          child: ChatTransportBadge(state: badgeState),
        );
      },
    );
  },
),
```

Adjust `widget.contactUserId` to whatever field ChatRoomScreen already carries for the other user; grep the file for `participantId` or `otherUserId` if unsure.

- [ ] **Step 3: Fire fetchContactKeys on init**

In `initState()`:

```dart
WidgetsBinding.instance.addPostFrameCallback((_) {
  final userId = widget.contactUserId;
  try {
    sl<DeviceKeySyncService>().fetchContactKeys(userId);
  } catch (_) {
    // best-effort
  }
});
```

Add import:

```dart
import '../../../../core/mesh/services/device_key_sync_service.dart';
```

- [ ] **Step 4: Per-message mesh indicator**

Find the message bubble builder. For each rendered `Message`, check if the entry's `transport` field is `'mesh'`. If so, render a small grey caption under the bubble:

```dart
if (message.transport == 'mesh')
  Padding(
    padding: const EdgeInsets.only(top: 2),
    child: Text(
      'via mesh',
      style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
    ),
  ),
```

If `Message` doesn't already have `transport` field, add it as a nullable field to the domain entity and pass through from cache. Use a defensive default: absent `transport` → treat as server.

- [ ] **Step 5: Static analysis**

```bash
flutter analyze lib/features/messenger/presentation/screens/chat_room_screen.dart 2>&1 | tail -5
```

Expected: `No issues found!`. Fix any type mismatches from the `transport` field addition.

- [ ] **Step 6: Commit**

```bash
git add lib/features/messenger/presentation/screens/chat_room_screen.dart lib/features/messenger/domain/entities/message_entity.dart
git commit -m "feat(messenger): transport badge + via-mesh indicator + fetchContactKeys"
```

---

## Task T10: MeshSettingsSection + wire into SettingsScreen

**Files:**
- Create: `lib/features/mesh/presentation/widgets/mesh_settings_section.dart`
- Modify: `lib/features/settings/presentation/screens/settings_screen.dart`

- [ ] **Step 1: Create the section widget**

Create `lib/features/mesh/presentation/widgets/mesh_settings_section.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/utils/constants.dart';
import '../../domain/entities/mesh_status.dart';
import '../bloc/mesh_status_bloc.dart';

class MeshSettingsSection extends StatefulWidget {
  const MeshSettingsSection({super.key});

  @override
  State<MeshSettingsSection> createState() => _MeshSettingsSectionState();
}

class _MeshSettingsSectionState extends State<MeshSettingsSection> {
  bool _offlineFallback = true;

  @override
  void initState() {
    super.initState();
    _loadPref();
  }

  Future<void> _loadPref() async {
    final prefs = sl<SharedPreferences>();
    setState(() {
      _offlineFallback = prefs.getBool('mesh.offlineFallback') ?? true;
    });
  }

  Future<void> _toggle(bool v) async {
    final prefs = sl<SharedPreferences>();
    await prefs.setBool('mesh.offlineFallback', v);
    setState(() => _offlineFallback = v);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: BlocBuilder<MeshStatusBloc, MeshStatus>(
          bloc: sl<MeshStatusBloc>(),
          builder: (context, meshState) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      meshState.running
                          ? Icons.radio_button_checked
                          : Icons.radio_button_off,
                      color: meshState.running ? Colors.green : Colors.grey,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      meshState.running ? 'Active' : 'Inactive',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${meshState.peerCount} peers visible nearby',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
                const Divider(height: 24),
                SwitchListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Use mesh offline'),
                  subtitle: const Text(
                    'When the server is unreachable, send messages via nearby peers.',
                    style: TextStyle(fontSize: 12),
                  ),
                  value: _offlineFallback,
                  onChanged: _toggle,
                ),
                const Divider(height: 8),
                TextButton(
                  onPressed: () =>
                      context.push('${RouteConstants.settings}/mesh-debug'),
                  child: const Text('View debug'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Insert section into SettingsScreen**

Open `lib/features/settings/presentation/screens/settings_screen.dart`. Find a stable insertion point — after the "Application" section, before the existing "View debug" entry for mesh-debug (which we can now remove since `MeshSettingsSection` replaces it). Add:

```dart
import '../../../mesh/presentation/widgets/mesh_settings_section.dart';
```

Where the old `_navTile(... 'Mesh Debug (dev)' ...)` lived, replace with:

```dart
_sectionHeader('Mesh Network'),
const MeshSettingsSection(),
```

Delete the orphaned old nav-tile + divider — MeshSettingsSection already carries the "View debug" link.

- [ ] **Step 3: Static analysis**

```bash
flutter analyze lib/features/mesh/presentation/widgets/mesh_settings_section.dart lib/features/settings/presentation/screens/settings_screen.dart 2>&1 | tail -5
```

Expected: `No issues found!`.

- [ ] **Step 4: Commit**

```bash
git add lib/features/mesh/presentation/widgets/mesh_settings_section.dart lib/features/settings/presentation/screens/settings_screen.dart
git commit -m "feat(mesh): MeshSettingsSection in Settings (Phase 1e)"
```

---

## Task T11: Final regression sweep + push

- [ ] **Step 1: Full analyze**

```bash
cd ~/Downloads/taler_id_mesh
flutter analyze lib/core/ lib/features/mesh/ lib/features/messenger/ lib/features/auth/ 2>&1 | tail -5
```

Expected: `No issues found!` for the mesh-touched paths (pre-existing lint info lines elsewhere are acceptable).

- [ ] **Step 2: Full test pass**

```bash
flutter test test/core/ test/features/mesh/ test/features/messenger/ 2>&1 | tail -5
```

Expected: all tests green (Phase 1a+1b+1c+1d+1e cumulative).

- [ ] **Step 3: Hardware manual smoke (optional, dev machine)**

Build and run on both iPhone and Redmi with `--dart-define=MESH_BLE_ENABLED=true`. Verify:
- Open app on both, login to a test account
- Open chat with a test contact
- Transport badge in header shows 🌐 (server)
- Toggle WiFi off on server (or kill socket from dev tools): badge switches to 📡 when mesh peer visible, or 🌐⚠ when not
- Send message on one device, appears on the other with "via mesh" subtitle

- [ ] **Step 4: Push branch**

```bash
git push origin feature/mesh-network
```

- [ ] **Step 5: Do NOT merge**

Standing instruction: no merges until the full mesh feature is complete. Phase 1f (Events QR) or Phase 1d.5 (peripheral GATT) comes next.

---

## Self-Review Notes

### Spec coverage

- §3 Goal 1 (transparent mesh fallback) — Tasks T2 (TransportSelector), T7 (repo branching)
- §3 Goal 2 (Settings section) — Task T10
- §3 Goal 3 (transport badge) — Tasks T8, T9
- §3 Goal 4 (per-message indicator) — Task T9 Step 4
- §3 Goal 5 (auto-fetch contact keys on chat open) — Task T9 Step 3
- §3 Goal 6 (replace `_placeholderUserId`) — Task T6 (resolution happens at login; service_locator stays on placeholder pre-login)
- §4 Architecture (file layout) — matches Tasks T1–T4 new-file list
- §5 Data Flow — Task T7 (outbound), Task T4 (inbound)
- §6 UI Details (Settings card + badge states + per-message) — Tasks T8, T9, T10
- §7 Persistence — Task T4 (adapter persists with `transport=mesh`, `meshOnly=true`)
- §8 DI Wiring (real userId, new registrations) — Tasks T5 (deferred to T6), T6 (AuthBloc hook), T7 (MeshMessengerAdapter/TransportSelector registration)
- §9 Testing — unit tests in T1–T4, T8; hardware manual in T11
- §10 Risks — mitigations implemented in code as designed (defensive catches around bootstrap, fallback to placeholder, persistence flags)

### Placeholder scan

Every task has concrete code. No TBD / TODO / "fill in details" inside steps. Some Step commentary directs the implementer to adapt to the actual codebase shape (e.g. "adjust `widget.contactUserId` to whatever field the screen already carries") — those are explicit navigation instructions, not placeholder code.

### Type consistency

- `TransportChoice` values (`server`, `mesh`, `offline`) are consistent across T2, T7.
- `TransportBadgeState` (`server`, `mesh`, `queued`) consistent across T8, T9.
- `AdaptedInboundMessage` fields `contactUserId`, `text`, `receivedAt` consistent across T4.
- `MeshStatus` fields (`running`, `peerCount`, `visibilityByContactUserId`) consistent across T1, T3, T10.
- Callbacks injected into the adapter (`lookupUserByDevice`, `contactUserIdForUserPk`, `persistLocal`) have matching signatures in T4 tests and T7 DI wiring.
- `MeshMessagingService` constructor / method signatures match the existing Phase 1a code (`sendText({toUserPk, text})`, `start({serviceName})`, `inbound` stream, `dispose()`).

---

## Execution Handoff

After saving this plan, offer:

**1. Subagent-Driven (recommended)** — fresh subagent per task with two-stage review.
**2. Inline Execution** — batch mode with checkpoints.

Total: 11 tasks (T1–T11). T7 is the largest integration point (repository branching + DI wiring). T9 needs the implementer to work with the existing chat screen layout.

import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:taler_id_mobile/core/mesh/transport/mesh_transport.dart';
import 'package:taler_id_mobile/core/mesh/transport/peer_id.dart';
import 'package:taler_id_mobile/core/voice/mesh_peer_eligibility_watcher.dart';

class _FakeTransport implements MeshTransport {
  final disc = StreamController<PeerDiscovered>.broadcast();
  final loss = StreamController<PeerLost>.broadcast();
  @override
  Stream<PeerDiscovered> get discoveries => disc.stream;
  @override
  Stream<PeerLost> get losses => loss.stream;
  @override
  Stream<InboundFrame> get inbound => const Stream.empty();
  @override
  Stream<InboundDatagram> get inboundDatagrams => const Stream.empty();
  @override
  Future<void> startAdvertising(DeviceInfo self) async {}
  @override
  Future<void> stopAdvertising() async {}
  @override
  Future<void> connectTo(PeerId peer) async {}
  @override
  Future<void> send(PeerId peer, Uint8List data) async {}
  @override
  Future<void> sendDatagram(PeerId peer, Uint8List data) async {}
  @override
  PeerStatus peerStatus(PeerId peer) => PeerStatus.unknown;
  @override
  Future<void> dispose() async {}
}

class _FakeContactStore implements ContactKeyStoreLookup {
  final Map<PeerId, PeerId> deviceToUser;
  final Map<String, PeerId> userIdToUserPk;
  _FakeContactStore({required this.deviceToUser, required this.userIdToUserPk});

  @override
  PeerId? lookupUserByDevice(PeerId devicePk) => deviceToUser[devicePk];

  @override
  Iterable<(String, PeerId)> allUserIdMappings() sync* {
    for (final e in userIdToUserPk.entries) yield (e.key, e.value);
  }
}

PeerId _device(int seed) =>
    PeerId(Uint8List.fromList(List<int>.generate(32, (i) => seed + i)));

void main() {
  late _FakeTransport transport;
  late _FakeContactStore store;
  late MeshPeerEligibilityWatcher watcher;

  final aliceUserPk = _device(10);
  final aliceDevice1 = _device(20);
  final aliceDevice2 = _device(30);

  setUp(() {
    transport = _FakeTransport();
    store = _FakeContactStore(
      deviceToUser: {
        aliceDevice1: aliceUserPk,
        aliceDevice2: aliceUserPk,
      },
      userIdToUserPk: {'alice-user-id': aliceUserPk},
    );
    watcher = MeshPeerEligibilityWatcher(
        transport: transport, contactKeyStore: store);
  });

  tearDown(() async => watcher.dispose());

  group('MeshPeerEligibilityWatcher', () {
    test('isUserOnline returns false before any discovery', () {
      watcher.start();
      expect(watcher.isUserOnline('alice-user-id'), isFalse);
    });

    test('isUserOnline returns true after PeerDiscovered for owned device',
        () async {
      watcher.start();
      transport.disc.add(PeerDiscovered(
          peerId: aliceDevice1, host: 'h', port: 1, attributes: {}));
      await Future<void>.delayed(Duration.zero);
      expect(watcher.isUserOnline('alice-user-id'), isTrue);
    });

    test(
        'isUserOnline returns false after all owned devices are PeerLost',
        () async {
      watcher.start();
      transport.disc.add(PeerDiscovered(
          peerId: aliceDevice1, host: 'h', port: 1, attributes: {}));
      await Future<void>.delayed(Duration.zero);
      transport.loss.add(PeerLost(aliceDevice1));
      await Future<void>.delayed(Duration.zero);
      expect(watcher.isUserOnline('alice-user-id'), isFalse);
    });

    test('isUserOnline stays true when one of two devices is lost', () async {
      watcher.start();
      transport.disc.add(PeerDiscovered(
          peerId: aliceDevice1, host: 'h', port: 1, attributes: {}));
      transport.disc.add(PeerDiscovered(
          peerId: aliceDevice2, host: 'h', port: 1, attributes: {}));
      await Future<void>.delayed(Duration.zero);
      transport.loss.add(PeerLost(aliceDevice1));
      await Future<void>.delayed(Duration.zero);
      expect(watcher.isUserOnline('alice-user-id'), isTrue);
    });

    test('userChanges emits only on first-add and last-remove', () async {
      watcher.start();
      final emissions = <(String, bool)>[];
      final sub =
          watcher.userChanges.listen((e) => emissions.add((e.userId, e.isOnline)));
      transport.disc.add(PeerDiscovered(
          peerId: aliceDevice1, host: 'h', port: 1, attributes: {}));
      await Future<void>.delayed(Duration.zero);
      transport.disc.add(PeerDiscovered(
          peerId: aliceDevice2, host: 'h', port: 1, attributes: {}));
      await Future<void>.delayed(Duration.zero);
      transport.loss.add(PeerLost(aliceDevice1));
      await Future<void>.delayed(Duration.zero);
      transport.loss.add(PeerLost(aliceDevice2));
      await Future<void>.delayed(Duration.zero);
      await sub.cancel();
      expect(emissions, [
        ('alice-user-id', true),
        ('alice-user-id', false),
      ]);
    });

    test('PeerDiscovered with unknown device is ignored', () async {
      watcher.start();
      final unknownDevice = _device(99);
      transport.disc.add(PeerDiscovered(
          peerId: unknownDevice, host: 'h', port: 1, attributes: {}));
      await Future<void>.delayed(Duration.zero);
      expect(watcher.isUserOnline('alice-user-id'), isFalse);
    });

    test('isUserOnline returns false when ContactKeyStore has no userId mapping',
        () async {
      watcher.start();
      store.userIdToUserPk.clear();
      transport.disc.add(PeerDiscovered(
          peerId: aliceDevice1, host: 'h', port: 1, attributes: {}));
      await Future<void>.delayed(Duration.zero);
      expect(watcher.isUserOnline('alice-user-id'), isFalse);
    });

    test('dispose() cancels subscriptions', () async {
      watcher.start();
      await watcher.dispose();
      expect(transport.disc.hasListener, isFalse);
      expect(transport.loss.hasListener, isFalse);
    });
  });

  group('MeshPeerEligibilityWatcher.hasAnyOnlinePeer', () {
    test('false when no peer online', () {
      watcher.start();
      expect(watcher.hasAnyOnlinePeer, isFalse);
      expect(watcher.onlinePeerCount, 0);
    });

    test('true after first PeerDiscovered', () async {
      watcher.start();
      transport.disc.add(PeerDiscovered(peerId: aliceDevice1, host: 'h', port: 1, attributes: {}));
      await Future<void>.delayed(Duration.zero);
      expect(watcher.hasAnyOnlinePeer, isTrue);
      expect(watcher.onlinePeerCount, 1);
    });

    test('counts distinct userIds, not devices', () async {
      watcher.start();
      transport.disc.add(PeerDiscovered(peerId: aliceDevice1, host: 'h', port: 1, attributes: {}));
      transport.disc.add(PeerDiscovered(peerId: aliceDevice2, host: 'h', port: 1, attributes: {}));
      await Future<void>.delayed(Duration.zero);
      expect(watcher.onlinePeerCount, 1, reason: 'two devices, one userId');
    });
  });
}

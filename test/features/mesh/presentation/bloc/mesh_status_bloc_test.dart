import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

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
  Stream<InboundDatagram> get inboundDatagrams => const Stream<InboundDatagram>.empty();
  @override
  Future<void> sendDatagram(PeerId peer, Uint8List data) async {
    throw UnimplementedError('test stub');
  }

  @override
  void registerKnownPeer(PeerId peer) {}
  @override
  PeerStatus peerStatus(PeerId peer) => PeerStatus.unknown;
  @override
  Future<void> dispose() async {}
}

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
        'a' * 64: 'b' * 64,
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

  group('visibleParticipantsOf helper (Phase 2)', () {
    test('returns only userIds whose visibility flag is true', () async {
      // Device hex → user hex mapping for alice and carol (visible),
      // bob gets a discovery that is then lost (not visible).
      final transport = _FakeTransport();
      final deviceToUser = {
        'a' * 64: '1' * 64, // alice's device
        'b' * 64: '2' * 64, // bob's device
        'c' * 64: '3' * 64, // carol's device
      };
      final userPkToUserId = {
        '1' * 64: 'alice',
        '2' * 64: 'bob',
        '3' * 64: 'carol',
      };
      final lookup = _FakeLookup(deviceToUser);
      final bloc = MeshStatusBloc(
        transport: transport,
        lookupUserByDevice: lookup.lookupUserByDevice,
        contactUserIdForUserPk: (pk) => userPkToUserId[pk.toHex()],
      );
      bloc.start();

      // alice visible
      transport.discoveriesCtrl.add(PeerDiscovered(
        peerId: PeerId.fromHex('a' * 64),
        host: '192.168.0.1',
        port: 42000,
      ));
      await Future.delayed(const Duration(milliseconds: 10));
      // bob discovered then lost → not visible
      transport.discoveriesCtrl.add(PeerDiscovered(
        peerId: PeerId.fromHex('b' * 64),
        host: '192.168.0.2',
        port: 42001,
      ));
      await Future.delayed(const Duration(milliseconds: 10));
      transport.lossesCtrl.add(PeerLost(PeerId.fromHex('b' * 64)));
      await Future.delayed(const Duration(milliseconds: 10));
      // carol visible
      transport.discoveriesCtrl.add(PeerDiscovered(
        peerId: PeerId.fromHex('c' * 64),
        host: '192.168.0.3',
        port: 42002,
      ));
      await Future.delayed(const Duration(milliseconds: 50));

      // 'dave' is unknown — neither true nor false — counts as not visible.
      final visible = bloc.visibleParticipantsOf(
          ['alice', 'bob', 'carol', 'dave']);
      expect(visible.toSet(), {'alice', 'carol'});

      await bloc.close();
    });

    test('returns empty when no participants are visible', () async {
      final transport = _FakeTransport();
      final bloc = MeshStatusBloc(
        transport: transport,
        lookupUserByDevice: (_) => null,
        contactUserIdForUserPk: (_) => null,
      );
      bloc.start();
      // No discovery events fired — visibility map is empty.
      final visible = bloc.visibleParticipantsOf(['alice', 'bob']);
      expect(visible, isEmpty);
      await bloc.close();
    });
  });
}

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
}

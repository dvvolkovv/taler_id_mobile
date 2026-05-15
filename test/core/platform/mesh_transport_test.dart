import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:taler_id_mobile/core/platform/mesh_transport_desktop_stub.dart';
import 'package:taler_id_mobile/core/mesh/transport/peer_id.dart';
import 'package:taler_id_mobile/core/mesh/transport/mesh_transport.dart';

void main() {
  group('MeshTransportDesktopStub', () {
    late MeshTransportDesktopStub stub;

    setUp(() {
      stub = const MeshTransportDesktopStub();
    });

    test('discoveries stream is empty', () async {
      final events = await stub.discoveries.toList();
      expect(events, isEmpty);
    });

    test('losses stream is empty', () async {
      final events = await stub.losses.toList();
      expect(events, isEmpty);
    });

    test('inbound stream is empty', () async {
      final events = await stub.inbound.toList();
      expect(events, isEmpty);
    });

    test('inboundDatagrams stream is empty', () async {
      final events = await stub.inboundDatagrams.toList();
      expect(events, isEmpty);
    });

    test('peerStatus always returns unknown', () {
      final peer = PeerId(Uint8List(32));
      expect(stub.peerStatus(peer), equals(PeerStatus.unknown));
    });

    test('startAdvertising is a no-op', () async {
      final peer = PeerId(Uint8List(32));
      await expectLater(
        stub.startAdvertising(DeviceInfo(devicePk: peer, serviceName: 'test')),
        completes,
      );
    });

    test('stopAdvertising is a no-op', () async {
      await expectLater(stub.stopAdvertising(), completes);
    });

    test('connectTo is a no-op', () async {
      final peer = PeerId(Uint8List(32));
      await expectLater(stub.connectTo(peer), completes);
    });

    test('send is a no-op', () async {
      final peer = PeerId(Uint8List(32));
      await expectLater(stub.send(peer, Uint8List(4)), completes);
    });

    test('sendDatagram is a no-op', () async {
      final peer = PeerId(Uint8List(32));
      await expectLater(stub.sendDatagram(peer, Uint8List(4)), completes);
    });

    test('registerKnownPeer is a no-op', () {
      final peer = PeerId(Uint8List(32));
      expect(() => stub.registerKnownPeer(peer), returnsNormally);
    });

    test('dispose is a no-op', () async {
      await expectLater(stub.dispose(), completes);
    });
  });
}

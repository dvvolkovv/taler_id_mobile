import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:taler_id_mobile/core/mesh/transport/frame.dart';
import 'package:taler_id_mobile/core/mesh/transport/mesh_transport.dart';
import 'package:taler_id_mobile/core/mesh/transport/multi_transport.dart';
import 'package:taler_id_mobile/core/mesh/transport/peer_id.dart';
import 'package:taler_id_mobile/core/mesh/transport/transport_preference.dart';

class _FakeTransport implements MeshTransport {
  final TransportId id;
  final discoveriesCtrl = StreamController<PeerDiscovered>.broadcast();
  final lossesCtrl = StreamController<PeerLost>.broadcast();
  final inboundCtrl = StreamController<InboundFrame>.broadcast();
  final List<(PeerId, Uint8List)> sends = [];
  bool failSend = false;

  _FakeTransport(this.id);

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
  Future<void> send(PeerId peer, Uint8List data) async {
    if (failSend) throw StateError('fake send failure');
    sends.add((peer, data));
  }

  @override
  Stream<InboundDatagram> get inboundDatagrams => const Stream.empty();

  @override
  Future<void> sendDatagram(PeerId peer, Uint8List data) async {
    throw TransportUnavailable('_FakeTransport.sendDatagram not implemented');
  }

  @override
  void registerKnownPeer(PeerId peer) {}

  @override
  PeerStatus peerStatus(PeerId peer) => PeerStatus.unknown;

  @override
  Future<void> dispose() async {
    await discoveriesCtrl.close();
    await lossesCtrl.close();
    await inboundCtrl.close();
  }
}

void main() {
  group('MultiTransport', () {
    test('discovery from either child surfaces exactly once per peer',
        () async {
      final bonjour = _FakeTransport(TransportId.bonjour);
      final ble = _FakeTransport(TransportId.ble);
      final multi = MultiTransport(children: {
        TransportId.bonjour: bonjour,
        TransportId.ble: ble,
      });

      final seen = <PeerDiscovered>[];
      final sub = multi.discoveries.listen(seen.add);

      final peer = PeerId.fromHex('b' * 64);
      bonjour.discoveriesCtrl.add(PeerDiscovered(peerId: peer, host: 'h', port: 1));
      ble.discoveriesCtrl.add(PeerDiscovered(peerId: peer, host: 'd', port: 0));

      await Future.delayed(const Duration(milliseconds: 20));
      expect(seen.length, equals(1));
      expect(seen.first.peerId, equals(peer));

      await sub.cancel();
      await multi.dispose();
    });

    test('send picks bonjour when both know the peer', () async {
      final bonjour = _FakeTransport(TransportId.bonjour);
      final ble = _FakeTransport(TransportId.ble);
      final multi = MultiTransport(children: {
        TransportId.bonjour: bonjour,
        TransportId.ble: ble,
      });

      final peer = PeerId.fromHex('b' * 64);
      bonjour.discoveriesCtrl.add(PeerDiscovered(peerId: peer, host: 'h', port: 1));
      ble.discoveriesCtrl.add(PeerDiscovered(peerId: peer, host: 'd', port: 0));
      await Future.delayed(const Duration(milliseconds: 20));

      await multi.send(peer, Uint8List.fromList([1, 2, 3]));
      expect(bonjour.sends, hasLength(1));
      expect(ble.sends, isEmpty);

      await multi.dispose();
    });

    test('send falls back to BLE when only BLE knows the peer', () async {
      final bonjour = _FakeTransport(TransportId.bonjour);
      final ble = _FakeTransport(TransportId.ble);
      final multi = MultiTransport(children: {
        TransportId.bonjour: bonjour,
        TransportId.ble: ble,
      });

      final peer = PeerId.fromHex('b' * 64);
      ble.discoveriesCtrl.add(PeerDiscovered(peerId: peer, host: 'd', port: 0));
      await Future.delayed(const Duration(milliseconds: 20));

      await multi.send(peer, Uint8List.fromList([7]));
      expect(bonjour.sends, isEmpty);
      expect(ble.sends, hasLength(1));

      await multi.dispose();
    });

    test('send fallback when preferred transport throws', () async {
      final bonjour = _FakeTransport(TransportId.bonjour)..failSend = true;
      final ble = _FakeTransport(TransportId.ble);
      final multi = MultiTransport(children: {
        TransportId.bonjour: bonjour,
        TransportId.ble: ble,
      });

      final peer = PeerId.fromHex('b' * 64);
      bonjour.discoveriesCtrl.add(PeerDiscovered(peerId: peer, host: 'h', port: 1));
      ble.discoveriesCtrl.add(PeerDiscovered(peerId: peer, host: 'd', port: 0));
      await Future.delayed(const Duration(milliseconds: 20));

      await multi.send(peer, Uint8List.fromList([7]));
      expect(bonjour.sends, isEmpty);
      expect(ble.sends, hasLength(1));

      await multi.dispose();
    });

    test('send throws StateError when no transport knows the peer', () async {
      final bonjour = _FakeTransport(TransportId.bonjour);
      final multi = MultiTransport(children: {TransportId.bonjour: bonjour});

      final peer = PeerId.fromHex('b' * 64);
      expect(
        () => multi.send(peer, Uint8List.fromList([1])),
        throwsStateError,
      );

      await multi.dispose();
    });

    test('loss emitted only when ALL transports lose the peer', () async {
      final bonjour = _FakeTransport(TransportId.bonjour);
      final ble = _FakeTransport(TransportId.ble);
      final multi = MultiTransport(children: {
        TransportId.bonjour: bonjour,
        TransportId.ble: ble,
      });

      final peer = PeerId.fromHex('b' * 64);
      bonjour.discoveriesCtrl.add(PeerDiscovered(peerId: peer, host: 'h', port: 1));
      ble.discoveriesCtrl.add(PeerDiscovered(peerId: peer, host: 'd', port: 0));
      await Future.delayed(const Duration(milliseconds: 20));

      final losses = <PeerId>[];
      final sub = multi.losses.listen((e) => losses.add(e.peerId));

      // Only BLE drops — no loss emitted (bonjour still knows).
      ble.lossesCtrl.add(PeerLost(peer));
      await Future.delayed(const Duration(milliseconds: 20));
      expect(losses, isEmpty);

      // Now bonjour drops too — loss emitted.
      bonjour.lossesCtrl.add(PeerLost(peer));
      await Future.delayed(const Duration(milliseconds: 20));
      expect(losses, equals([peer]));

      await sub.cancel();
      await multi.dispose();
    });

    test('inbound frames from any transport surface through multi', () async {
      final bonjour = _FakeTransport(TransportId.bonjour);
      final ble = _FakeTransport(TransportId.ble);
      final multi = MultiTransport(children: {
        TransportId.bonjour: bonjour,
        TransportId.ble: ble,
      });

      final received = <InboundFrame>[];
      final sub = multi.inbound.listen(received.add);

      final peer = PeerId.fromHex('b' * 64);
      bonjour.inboundCtrl.add(InboundFrame(
        srcPeer: peer,
        type: FrameType.data,
        bytes: Uint8List.fromList([1]),
      ));
      ble.inboundCtrl.add(InboundFrame(
        srcPeer: peer,
        type: FrameType.handshake,
        bytes: Uint8List.fromList([2]),
      ));

      await Future.delayed(const Duration(milliseconds: 20));
      expect(received, hasLength(2));

      await sub.cancel();
      await multi.dispose();
    });
  });
}

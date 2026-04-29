import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:taler_id_mobile/core/mesh/transport/mesh_transport.dart';
import 'package:taler_id_mobile/core/mesh/transport/multi_transport.dart';
import 'package:taler_id_mobile/core/mesh/transport/peer_id.dart';
import 'package:taler_id_mobile/core/mesh/transport/transport_preference.dart';

class _FakeChild implements MeshTransport {
  final TransportId id;
  final _discCtrl = StreamController<PeerDiscovered>.broadcast();
  final _lossCtrl = StreamController<PeerLost>.broadcast();
  final _inboundCtrl = StreamController<InboundFrame>.broadcast();
  final _datagramCtrl = StreamController<InboundDatagram>.broadcast();
  final sentDatagrams = <(PeerId, Uint8List)>[];
  bool throwOnSend = false;

  _FakeChild(this.id);

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
    if (throwOnSend) throw TransportUnavailable('fake throw');
    sentDatagrams.add((peer, data));
  }

  @override
  PeerStatus peerStatus(PeerId peer) => PeerStatus.unknown;

  void emitDiscover(PeerId peer) =>
      _discCtrl.add(PeerDiscovered(peerId: peer, host: '127.0.0.1', port: 0));
  void emitDatagram(InboundDatagram dg) => _datagramCtrl.add(dg);
}

void main() {
  group('MultiTransport datagram', () {
    test('routes sendDatagram to first child where peer is discovered', () async {
      final bonjour = _FakeChild(TransportId.bonjour);
      final ble = _FakeChild(TransportId.ble);
      final multi = MultiTransport(children: {
        TransportId.bonjour: bonjour,
        TransportId.ble: ble,
      });
      final peer = PeerId(Uint8List.fromList(List<int>.generate(32, (i) => i)));

      // Peer only discovered on Bonjour.
      bonjour.emitDiscover(peer);
      await Future<void>.delayed(Duration.zero);

      await multi.sendDatagram(peer, Uint8List.fromList([1, 2, 3]));
      expect(bonjour.sentDatagrams, hasLength(1));
      expect(ble.sentDatagrams, isEmpty);
    });

    test('prefers Bonjour over BLE when peer is on both', () async {
      final bonjour = _FakeChild(TransportId.bonjour);
      final ble = _FakeChild(TransportId.ble);
      final multi = MultiTransport(children: {
        TransportId.bonjour: bonjour,
        TransportId.ble: ble,
      });
      final peer = PeerId(Uint8List.fromList(List<int>.generate(32, (i) => i)));

      bonjour.emitDiscover(peer);
      ble.emitDiscover(peer);
      await Future<void>.delayed(Duration.zero);

      await multi.sendDatagram(peer, Uint8List.fromList([7, 8]));
      expect(bonjour.sentDatagrams, hasLength(1));
      expect(ble.sentDatagrams, isEmpty);
    });

    test('throws TransportUnavailable when peer is on no transport', () async {
      final bonjour = _FakeChild(TransportId.bonjour);
      final multi = MultiTransport(children: {
        TransportId.bonjour: bonjour,
      });
      final peer = PeerId(Uint8List.fromList(List<int>.generate(32, (i) => i)));
      // Peer never discovered.

      await expectLater(
        multi.sendDatagram(peer, Uint8List.fromList([1])),
        throwsA(isA<TransportUnavailable>()),
      );
    });

    test('inboundDatagrams forwards from all children', () async {
      final bonjour = _FakeChild(TransportId.bonjour);
      final ble = _FakeChild(TransportId.ble);
      final multi = MultiTransport(children: {
        TransportId.bonjour: bonjour,
        TransportId.ble: ble,
      });
      final peer = PeerId(Uint8List.fromList(List<int>.generate(32, (i) => i)));
      final received = <InboundDatagram>[];
      multi.inboundDatagrams.listen(received.add);

      bonjour.emitDatagram(InboundDatagram(
        srcPeer: peer, bytes: Uint8List.fromList([1]), via: TransportId.bonjour));
      ble.emitDatagram(InboundDatagram(
        srcPeer: peer, bytes: Uint8List.fromList([2]), via: TransportId.ble));
      await Future<void>.delayed(Duration.zero);

      expect(received, hasLength(2));
      expect(received[0].via, TransportId.bonjour);
      expect(received[1].via, TransportId.ble);
    });
  });
}

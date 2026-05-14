import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:taler_id_mobile/core/mesh/transport/bonjour_transport.dart';
import 'package:taler_id_mobile/core/mesh/transport/mesh_transport.dart';
import 'package:taler_id_mobile/core/mesh/transport/peer_id.dart';

void main() {
  test('two Bonjour transports exchange UDP datagrams over loopback', () async {
    // We don't actually rely on mDNS here — Bonsoir doesn't work on the host
    // VM. Instead we bind two RawDatagramSockets directly and feed them
    // into BonjourTransport via the exposed test hook (added in this task).
    // That exercises sendDatagram + inboundDatagrams + reverse lookup.

    final aliceSock = await RawDatagramSocket.bind(InternetAddress.loopbackIPv4, 0);
    final bobSock = await RawDatagramSocket.bind(InternetAddress.loopbackIPv4, 0);

    final alicePk = PeerId(Uint8List.fromList(List<int>.generate(32, (i) => i)));
    final bobPk = PeerId(Uint8List.fromList(List<int>.generate(32, (i) => 100 + i)));

    final alice = BonjourTransport.testHarness(udpSocket: aliceSock, selfPk: alicePk);
    final bob = BonjourTransport.testHarness(udpSocket: bobSock, selfPk: bobPk);

    // Wire endpoint caches manually (production code populates these from
    // bonsoir-resolved TXT records).
    alice.testRegisterPeer(bobPk, bobSock.address.address, bobSock.port);
    bob.testRegisterPeer(alicePk, aliceSock.address.address, aliceSock.port);

    final received = <InboundDatagram>[];
    final sub = bob.inboundDatagrams.listen(received.add);

    await alice.sendDatagram(bobPk, Uint8List.fromList([1, 2, 3, 4]));
    await Future<void>.delayed(const Duration(milliseconds: 100));

    expect(received, hasLength(1));
    expect(received.first.bytes, Uint8List.fromList([1, 2, 3, 4]));
    expect(received.first.srcPeer, alicePk);

    await sub.cancel();
    aliceSock.close();
    bobSock.close();
  });
}

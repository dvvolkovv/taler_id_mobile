import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:taler_id_mobile/core/mesh/transport/bonjour_transport.dart';
import 'package:taler_id_mobile/core/mesh/transport/mesh_transport.dart';
import 'package:taler_id_mobile/core/mesh/transport/peer_id.dart';

void main() {
  test('BonjourTransport.peerStatus returns offline before discovery, online after', () async {
    final t = BonjourTransport();
    final peer = PeerId(Uint8List.fromList(List<int>.generate(32, (i) => i)));

    expect(t.peerStatus(peer), PeerStatus.offline,
        reason: 'no discovery yet → offline');

    // Drive discovery via test hook (registers TXT-resolved peer; same hook used in 3b loopback test).
    t.testRegisterPeer(peer, '127.0.0.1', 8888);
    expect(t.peerStatus(peer), PeerStatus.online);
  });
}

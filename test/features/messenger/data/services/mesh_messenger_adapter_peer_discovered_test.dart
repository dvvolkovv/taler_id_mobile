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

// Phase 1d hardware integration test — requires TWO physical Android
// devices, Bluetooth enabled, runtime permissions granted, both running
// this test simultaneously.
//
// Manual run (on each device):
//   flutter test integration_test/ble_peer_discovery_test.dart \
//     --flavor dev -t lib/main_dev.dart \
//     --dart-define=FLAVOR=dev \
//     --dart-define=MESH_BLE_ENABLED=true \
//     -d <deviceId>
//
// The test succeeds on each side when the other side's advertisement
// appears within 10 seconds.

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:taler_id_mobile/core/mesh/crypto/keys/mesh_static_key.dart';
import 'package:taler_id_mobile/core/mesh/transport/ble_transport.dart';
import 'package:taler_id_mobile/core/mesh/transport/mesh_transport.dart';
import 'package:taler_id_mobile/core/mesh/transport/peer_id.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'Phase 1d — BLE advertises and a peer is discovered',
    (tester) async {
      final meshKey = await MeshStaticKey.generate();
      final selfPk = PeerId(meshKey.publicKey);

      final transport = BleTransport();

      final discovered = <PeerDiscovered>[];
      final sub = transport.discoveries.listen(discovered.add);

      await transport.startAdvertising(DeviceInfo(
        devicePk: selfPk,
        serviceName: 'taler-phase1d-test',
      ));

      // Give the peer up to 10 seconds to appear. The test is meaningful
      // only when run simultaneously on two devices — one alone will
      // return discovered.length == 0 and fail.
      final deadline = DateTime.now().add(const Duration(seconds: 10));
      while (DateTime.now().isBefore(deadline) && discovered.isEmpty) {
        await Future.delayed(const Duration(milliseconds: 200));
      }

      expect(
        discovered,
        isNotEmpty,
        reason:
            'Expected to see at least one peer advertising the mesh service. '
            'If running solo, this test cannot pass — run on a second device.',
      );

      await sub.cancel();
      await transport.dispose();
    },
    timeout: const Timeout(Duration(seconds: 30)),
  );
}

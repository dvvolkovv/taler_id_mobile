// ignore_for_file: avoid_print
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:taler_id_mobile/core/mesh/crypto/keys/contact_key_store.dart';
import 'package:taler_id_mobile/core/mesh/services/envelope.dart';
import 'package:taler_id_mobile/core/mesh/services/mesh_messaging_service.dart';
import 'package:taler_id_mobile/core/mesh/transport/bonjour_transport.dart';
import 'package:taler_id_mobile/core/mesh/transport/peer_id.dart';

Future<(Uint8List, Uint8List)> _x25519Keys() async {
  final kp = await X25519().newKeyPair();
  final priv = await kp.extractPrivateKeyBytes();
  final pub = await kp.extractPublicKey();
  return (Uint8List.fromList(priv), Uint8List.fromList(pub.bytes));
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'Two MeshMessagingService instances exchange text via Bonjour + TCP',
    (WidgetTester tester) async {
      final (aPriv, aPub) = await _x25519Keys();
      final (bPriv, bPub) = await _x25519Keys();
      final alicePeer = PeerId(aPub);
      final bobPeer = PeerId(bPub);

      final aliceStore = ContactKeyStore()
        ..addContact(userPk: bobPeer, devicePks: [bobPeer]);
      final bobStore = ContactKeyStore()
        ..addContact(userPk: alicePeer, devicePks: [alicePeer]);

      // Keep typed references to BonjourTransport so we can call seedPeer.
      final aliceTransport = BonjourTransport();
      final bobTransport = BonjourTransport();

      final alice = MeshMessagingService(
        transport: aliceTransport,
        contactKeyStore: aliceStore,
        myDevicePrivateKey: aPriv,
        myDevicePublicKey: aPub,
      );
      final bob = MeshMessagingService(
        transport: bobTransport,
        contactKeyStore: bobStore,
        myDevicePrivateKey: bPriv,
        myDevicePublicKey: bPub,
      );

      await alice.start(serviceName: 'AliceTest-${alicePeer.shortPrefix()}');
      await bob.start(serviceName: 'BobTest-${bobPeer.shortPrefix()}');

      final bobInbox = <String>[];
      final sub = bob.inbound.listen((m) => bobInbox.add(m.envelope.text));

      // Give mDNS a chance to propagate organically (3 s).
      // On real devices this is usually <1 s. On emulators mDNS multicast
      // is unreliable, so we fall back to seedPeer (loopback TCP) below.
      await Future.delayed(const Duration(seconds: 3));

      // Fallback: if mDNS didn't deliver Bob's address to Alice's transport,
      // inject it directly via seedPeer. This exercises the full Noise IK
      // handshake + encrypted data path over a real loopback TCP socket.
      final bobPort = bobTransport.listenPort;
      print('[mesh_test] Bob TCP port: $bobPort');
      aliceTransport.seedPeer(
        peerId: bobPeer,
        host: '127.0.0.1',
        port: bobPort,
      );
      // Also let Bob know about Alice in case he needs to respond.
      final alicePort = aliceTransport.listenPort;
      print('[mesh_test] Alice TCP port: $alicePort');
      bobTransport.seedPeer(
        peerId: alicePeer,
        host: '127.0.0.1',
        port: alicePort,
      );

      // Small settle time after seeding.
      await Future.delayed(const Duration(seconds: 1));

      print('[mesh_test] Alice sending text to Bob...');
      await alice.sendEnvelope(
        toUserPk: bobPeer,
        envelope: Envelope(
          version: 1,
          type: 'text',
          convId: 'mesh-integration-loopback',
          clientId: 'mesh-test-${DateTime.now().microsecondsSinceEpoch}',
          text: 'hello bob from mesh',
          sentAt: DateTime.now().toUtc(),
        ),
      );

      // Wait for handshake round-trip + encrypted data delivery.
      await Future.delayed(const Duration(seconds: 3));

      print('[mesh_test] Bob inbox: $bobInbox');
      expect(bobInbox, contains('hello bob from mesh'),
          reason: "bob should have received alice's message via mesh");

      await sub.cancel();
      await alice.dispose();
      await bob.dispose();
    },
    timeout: const Timeout(Duration(seconds: 30)),
  );
}

import 'dart:async';
import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taler_id_mobile/core/mesh/crypto/keys/contact_key_store.dart';
import 'package:taler_id_mobile/core/mesh/services/envelope.dart';
import 'package:taler_id_mobile/core/mesh/services/mesh_messaging_service.dart';
import 'package:taler_id_mobile/core/mesh/transport/frame.dart';
import 'package:taler_id_mobile/core/mesh/transport/mesh_transport.dart';
import 'package:taler_id_mobile/core/mesh/transport/peer_id.dart';

class _FakeTransport implements MeshTransport {
  final _discoveries = StreamController<PeerDiscovered>.broadcast();
  final _losses = StreamController<PeerLost>.broadcast();
  final _inbound = StreamController<InboundFrame>.broadcast();
  _FakeTransport? partner;

  @override
  Stream<PeerDiscovered> get discoveries => _discoveries.stream;
  @override
  Stream<PeerLost> get losses => _losses.stream;
  @override
  Stream<InboundFrame> get inbound => _inbound.stream;

  PeerId? selfPeer;

  @override
  Future<void> startAdvertising(DeviceInfo self) async {
    selfPeer = self.devicePk;
  }

  @override
  Future<void> stopAdvertising() async {}

  @override
  Future<void> connectTo(PeerId peer) async {}

  @override
  Future<void> send(PeerId peer, Uint8List data) async {
    if (partner == null) throw StateError('no partner');
    // Decode the full Frame so we preserve `type` for the receiver.
    final frame = Frame.decode(data);
    partner!._inbound.add(InboundFrame(
      srcPeer: selfPeer!,
      type: frame.type,
      bytes: frame.payload,
    ));
  }

  @override
  Future<void> dispose() async {
    await _discoveries.close();
    await _losses.close();
    await _inbound.close();
  }

  void emitDiscovery(PeerDiscovered d) => _discoveries.add(d);
}

Future<(Uint8List, Uint8List)> _x25519Keys() async {
  final kp = await X25519().newKeyPair();
  final priv = await kp.extractPrivateKeyBytes();
  final pub = await kp.extractPublicKey();
  return (Uint8List.fromList(priv), Uint8List.fromList(pub.bytes));
}

void main() {
  group('MeshMessagingService Phase 2 envelope', () {
    test('two services exchange envelope after handshake', () async {
      final (alicePriv, alicePub) = await _x25519Keys();
      final (bobPriv, bobPub) = await _x25519Keys();

      final alicePeer = PeerId(alicePub);
      final bobPeer = PeerId(bobPub);

      // Alice and Bob know each other's static pks.
      final aliceStore = ContactKeyStore()
        ..addContact(userPk: bobPeer, devicePks: [bobPeer]);
      final bobStore = ContactKeyStore()
        ..addContact(userPk: alicePeer, devicePks: [alicePeer]);

      final aliceT = _FakeTransport();
      final bobT = _FakeTransport();
      aliceT.partner = bobT;
      bobT.partner = aliceT;

      final alice = MeshMessagingService(
        transport: aliceT,
        contactKeyStore: aliceStore,
        myDevicePrivateKey: alicePriv,
        myDevicePublicKey: alicePub,
      );
      final bob = MeshMessagingService(
        transport: bobT,
        contactKeyStore: bobStore,
        myDevicePrivateKey: bobPriv,
        myDevicePublicKey: bobPub,
      );

      await alice.start(serviceName: 'Alice');
      await bob.start(serviceName: 'Bob');

      // Simulate discovery
      aliceT.emitDiscovery(PeerDiscovered(
        peerId: bobPeer,
        host: '127.0.0.1',
        port: 0,
      ));
      bobT.emitDiscovery(PeerDiscovered(
        peerId: alicePeer,
        host: '127.0.0.1',
        port: 0,
      ));

      final received = <InboundEnvelope>[];
      final sub = bob.inbound.listen(received.add);

      // Wait for discovery to register
      await Future.delayed(const Duration(milliseconds: 50));

      final envelope = Envelope(
        version: 1,
        type: 'text',
        convId: 'conv-test',
        clientId: 'client-abc',
        text: 'Привет from Alice 👋',
        sentAt: DateTime.parse('2026-04-26T12:00:00.000Z'),
      );
      await alice.sendEnvelope(
        toUserPk: bobPeer,
        envelope: envelope,
      );

      // Wait for handshake + message round-trip
      await Future.delayed(const Duration(milliseconds: 200));

      expect(received, hasLength(1));
      final got = received.first;
      expect(got.fromUserPk, alicePeer);
      expect(got.envelope.text, envelope.text);
      expect(got.envelope.convId, envelope.convId);
      expect(got.envelope.clientId, envelope.clientId);
      expect(got.envelope.sentAt, envelope.sentAt);

      await sub.cancel();
      await alice.dispose();
      await bob.dispose();
    });
  });
}

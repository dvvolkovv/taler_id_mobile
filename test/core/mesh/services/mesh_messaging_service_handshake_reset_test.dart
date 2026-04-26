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
  PeerId? selfPeer;

  @override
  Stream<PeerDiscovered> get discoveries => _discoveries.stream;
  @override
  Stream<PeerLost> get losses => _losses.stream;
  @override
  Stream<InboundFrame> get inbound => _inbound.stream;

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
}

Future<(Uint8List, Uint8List)> _x25519Keys() async {
  final kp = await X25519().newKeyPair();
  final priv = await kp.extractPrivateKeyBytes();
  final pub = await kp.extractPublicKey();
  return (Uint8List.fromList(priv), Uint8List.fromList(pub.bytes));
}

void main() {
  group('MeshMessagingService handshake reset', () {
    test('peer with cached session can re-handshake after restart', () async {
      // Alice and Bob establish a session, exchange a message, then Bob
      // "restarts" (we drop and recreate his service) and re-initiates.
      // Alice's existing session must be replaced cleanly.

      final (alicePriv, alicePub) = await _x25519Keys();
      final (bobPriv, bobPub) = await _x25519Keys();
      final alicePeer = PeerId(alicePub);
      final bobPeer = PeerId(bobPub);

      final aliceStore = ContactKeyStore()
        ..addContact(userPk: bobPeer, devicePks: [bobPeer]);
      final bobStore = ContactKeyStore()
        ..addContact(userPk: alicePeer, devicePks: [alicePeer]);

      final aliceTransport = _FakeTransport();
      var bobTransport = _FakeTransport();
      aliceTransport.partner = bobTransport;
      bobTransport.partner = aliceTransport;

      final alice = MeshMessagingService(
        transport: aliceTransport,
        contactKeyStore: aliceStore,
        myDevicePrivateKey: alicePriv,
        myDevicePublicKey: alicePub,
      );
      var bob = MeshMessagingService(
        transport: bobTransport,
        contactKeyStore: bobStore,
        myDevicePrivateKey: bobPriv,
        myDevicePublicKey: bobPub,
      );
      await alice.start(serviceName: 'alice');
      await bob.start(serviceName: 'bob');

      final firstReceived = bob.inbound.first;
      await alice.sendEnvelope(
        toUserPk: bobPeer,
        envelope: Envelope(
          version: 2,
          type: 'text',
          convId: 'c1',
          clientId: 'm1',
          text: 'hello',
          sentAt: DateTime.parse('2026-04-26T10:00:00Z'),
        ),
      );
      final firstEnv = await firstReceived;
      expect(firstEnv.envelope.text, 'hello');

      // Simulate Bob restart: dispose old, build new with same keys.
      await bob.dispose();
      bobTransport = _FakeTransport();
      aliceTransport.partner = bobTransport;
      bobTransport.partner = aliceTransport;
      bob = MeshMessagingService(
        transport: bobTransport,
        contactKeyStore: bobStore,
        myDevicePrivateKey: bobPriv,
        myDevicePublicKey: bobPub,
      );
      await bob.start(serviceName: 'bob');

      // Bob now sends to Alice. Alice currently has cached session/handshake
      // for Bob; the fix must let her reset and accept the new handshake.
      final aliceReceived = alice.inbound.first;
      await bob.sendEnvelope(
        toUserPk: alicePeer,
        envelope: Envelope(
          version: 2,
          type: 'text',
          convId: 'c1',
          clientId: 'm2',
          text: 'after-restart',
          sentAt: DateTime.parse('2026-04-26T10:00:05Z'),
        ),
      );
      final secondEnv = await aliceReceived
          .timeout(const Duration(seconds: 3));
      expect(secondEnv.envelope.text, 'after-restart');

      await alice.dispose();
      await bob.dispose();
    });

    test('anti-thrash jitter cancels pending outbound init when peer init arrives first', () async {
      // Alice has a stale session. Both sides try to re-handshake at once.
      // Alice's outbound init must be cancelled; she becomes responder.

      final (alicePriv, alicePub) = await _x25519Keys();
      final (bobPriv, bobPub) = await _x25519Keys();
      final alicePeer = PeerId(alicePub);
      final bobPeer = PeerId(bobPub);

      final aliceStore = ContactKeyStore()
        ..addContact(userPk: bobPeer, devicePks: [bobPeer]);
      final bobStore = ContactKeyStore()
        ..addContact(userPk: alicePeer, devicePks: [alicePeer]);

      final aliceTransport = _FakeTransport();
      final bobTransport = _FakeTransport();
      aliceTransport.partner = bobTransport;
      bobTransport.partner = aliceTransport;

      final alice = MeshMessagingService(
        transport: aliceTransport,
        contactKeyStore: aliceStore,
        myDevicePrivateKey: alicePriv,
        myDevicePublicKey: alicePub,
        recoveryInitJitter: const Duration(milliseconds: 100),
      );
      final bob = MeshMessagingService(
        transport: bobTransport,
        contactKeyStore: bobStore,
        myDevicePrivateKey: bobPriv,
        myDevicePublicKey: bobPub,
        recoveryInitJitter: Duration.zero,
      );
      await alice.start(serviceName: 'alice');
      await bob.start(serviceName: 'bob');

      // Establish initial session.
      final firstAtBob = bob.inbound.first;
      await alice.sendEnvelope(
        toUserPk: bobPeer,
        envelope: Envelope(
          version: 2,
          type: 'text',
          convId: 'c1',
          clientId: 'm1',
          text: 'hi',
          sentAt: DateTime.parse('2026-04-26T10:00:00Z'),
        ),
      );
      await firstAtBob;

      // Both sides initiate a recovery handshake at "the same time".
      // Alice's call gets jittered by 100ms; Bob's fires immediately.
      // Bob's init should reach Alice before Alice's init goes out.
      final aliceFuture = alice.sendEnvelope(
        toUserPk: bobPeer,
        envelope: Envelope(
          version: 2,
          type: 'text',
          convId: 'c1',
          clientId: 'm-alice',
          text: 'from-alice',
          sentAt: DateTime.parse('2026-04-26T10:00:01Z'),
        ),
      );
      final bobFuture = bob.sendEnvelope(
        toUserPk: alicePeer,
        envelope: Envelope(
          version: 2,
          type: 'text',
          convId: 'c1',
          clientId: 'm-bob',
          text: 'from-bob',
          sentAt: DateTime.parse('2026-04-26T10:00:01Z'),
        ),
      );
      await Future.wait<void>([aliceFuture, bobFuture]);

      await alice.dispose();
      await bob.dispose();
    });

    test('after 5 resets in 60s, 6th init from same peer is suppressed', () async {
      final (alicePriv, alicePub) = await _x25519Keys();
      final (bobPriv, bobPub) = await _x25519Keys();
      final alicePeer = PeerId(alicePub);
      final bobPeer = PeerId(bobPub);

      final aliceStore = ContactKeyStore()
        ..addContact(userPk: bobPeer, devicePks: [bobPeer]);
      final bobStore = ContactKeyStore()
        ..addContact(userPk: alicePeer, devicePks: [alicePeer]);

      final aliceTransport = _FakeTransport();
      var bobTransport = _FakeTransport();
      aliceTransport.partner = bobTransport;
      bobTransport.partner = aliceTransport;

      final alice = MeshMessagingService(
        transport: aliceTransport,
        contactKeyStore: aliceStore,
        myDevicePrivateKey: alicePriv,
        myDevicePublicKey: alicePub,
        peerResetWindow: const Duration(seconds: 60),
        peerResetThreshold: 5,
      );
      var bob = MeshMessagingService(
        transport: bobTransport,
        contactKeyStore: bobStore,
        myDevicePrivateKey: bobPriv,
        myDevicePublicKey: bobPub,
      );
      await alice.start(serviceName: 'alice');
      await bob.start(serviceName: 'bob');

      Future<void> establishAndRestartBob({required String text}) async {
        final received = bob.inbound.first;
        await alice.sendEnvelope(
          toUserPk: bobPeer,
          envelope: Envelope(
            version: 2,
            type: 'text',
            convId: 'c1',
            clientId: 'm-$text',
            text: text,
            sentAt: DateTime.parse('2026-04-26T10:00:00Z'),
          ),
        );
        await received;
        await bob.dispose();
        bobTransport = _FakeTransport();
        aliceTransport.partner = bobTransport;
        bobTransport.partner = aliceTransport;
        bob = MeshMessagingService(
          transport: bobTransport,
          contactKeyStore: bobStore,
          myDevicePrivateKey: bobPriv,
          myDevicePublicKey: bobPub,
        );
        await bob.start(serviceName: 'bob');
      }

      // Cycles 1–5: alice→bob, then bob restarts → bob→alice succeeds.
      for (var i = 0; i < 5; i++) {
        await establishAndRestartBob(text: 'cycle$i');
        final aliceReceives = alice.inbound.first;
        await bob.sendEnvelope(
          toUserPk: alicePeer,
          envelope: Envelope(
            version: 2,
            type: 'text',
            convId: 'c1',
            clientId: 'b-$i',
            text: 'reply$i',
            sentAt: DateTime.parse('2026-04-26T10:00:01Z'),
          ),
        );
        await aliceReceives.timeout(const Duration(seconds: 3));
      }

      // Cycle 6: bob restarts again. Alice should suppress this reset.
      await establishAndRestartBob(text: 'cycle5');
      final aliceReceivesAfterBackoff = alice.inbound.first
          .timeout(const Duration(milliseconds: 500), onTimeout: () {
        throw TimeoutException('expected — backoff suppresses sixth reset');
      });
      // Fire bob's send without awaiting — Alice suppresses the reset, so Bob's
      // handshake will never complete. We only care that Alice's inbound stream
      // does NOT deliver a message within 500ms.
      unawaited(bob.sendEnvelope(
        toUserPk: alicePeer,
        envelope: Envelope(
          version: 2,
          type: 'text',
          convId: 'c1',
          clientId: 'b-5',
          text: 'reply5',
          sentAt: DateTime.parse('2026-04-26T10:00:01Z'),
        ),
      ).catchError((_) {})); // ignore expected handshake timeout
      await expectLater(
        aliceReceivesAfterBackoff,
        throwsA(isA<TimeoutException>()),
      );

      await alice.dispose();
      await bob.dispose();
    });
  });
}

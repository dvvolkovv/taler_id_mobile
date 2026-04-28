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

  /// Test-only: inject a frame as if the partner had sent it. Used by
  /// stale-session recovery tests where we need to deliver garbage that
  /// causes a MAC failure on decrypt.
  void injectInboundFrame(InboundFrame frame) {
    _inbound.add(frame);
  }
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

    test(
        'burst of N data frames to one peer all decrypt correctly (Phase 2.2 retry safety)',
        () async {
      // Regression: Phase 2.2 retry sends N frames to one peer rapidly.
      // Without serialised _onInboundFrame, concurrent decrypt calls would
      // race on Noise session state and produce MAC failures on all but the
      // first frame.
      final (alicePriv, alicePub) = await _x25519Keys();
      final (bobPriv, bobPub) = await _x25519Keys();
      final alicePeer = PeerId(alicePub);
      final bobPeer = PeerId(bobPub);

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
      await Future<void>.delayed(const Duration(milliseconds: 50));

      // Establish session with a first message.
      await alice.sendEnvelope(
        toUserPk: bobPeer,
        envelope: Envelope(
          version: 1,
          type: 'text',
          convId: 'conv-burst',
          clientId: 'msg-0',
          text: 'warm up',
          sentAt: DateTime.parse('2026-04-27T10:00:00Z'),
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 200));

      // Sequential send (matches Phase 2.2 retry handler:
      // `for (final entry in due) { await sendEnvelopeToPeer(...) }`).
      // Receiver sees the frames arriving in rapid succession via the
      // stream — that is where the concurrency would have raced.
      for (var i = 1; i <= 10; i++) {
        await alice.sendEnvelope(
          toUserPk: bobPeer,
          envelope: Envelope(
            version: 1,
            type: 'text',
            convId: 'conv-burst',
            clientId: 'msg-$i',
            text: 'burst $i',
            sentAt: DateTime.parse('2026-04-27T10:00:00Z'),
          ),
        );
      }
      await Future<void>.delayed(const Duration(milliseconds: 300));

      expect(received, hasLength(11),
          reason: 'all warm-up + 10 burst frames must decrypt');
      final clientIds = received.map((e) => e.envelope.clientId).toList();
      expect(clientIds, ['msg-0', for (var i = 1; i <= 10; i++) 'msg-$i']);

      await sub.cancel();
      await alice.dispose();
      await bob.dispose();
    });
  });

  group('Phase 2.3 stale-session recovery', () {
    test('session==null on receiver triggers re-handshake; next send delivers',
        () async {
      final (alicePriv, alicePub) = await _x25519Keys();
      final (bobPriv, bobPub) = await _x25519Keys();
      final alicePeer = PeerId(alicePub);
      final bobPeer = PeerId(bobPub);

      final aliceStore = ContactKeyStore()
        ..addContact(userPk: bobPeer, devicePks: [bobPeer]);
      final bobStore = ContactKeyStore()
        ..addContact(userPk: alicePeer, devicePks: [alicePeer]);

      // Step 1: establish a session between Alice and Bob.
      final aliceT = _FakeTransport();
      var bobT = _FakeTransport();
      aliceT.partner = bobT;
      bobT.partner = aliceT;

      final alice = MeshMessagingService(
        transport: aliceT,
        contactKeyStore: aliceStore,
        myDevicePrivateKey: alicePriv,
        myDevicePublicKey: alicePub,
      );
      var bob = MeshMessagingService(
        transport: bobT,
        contactKeyStore: bobStore,
        myDevicePrivateKey: bobPriv,
        myDevicePublicKey: bobPub,
      );
      await alice.start(serviceName: 'Alice');
      await bob.start(serviceName: 'Bob');

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

      final firstAtBob = bob.inbound.first;
      await alice.sendEnvelope(
        toUserPk: bobPeer,
        envelope: Envelope(
          version: 1,
          type: 'text',
          convId: 'conv-recovery',
          clientId: 'msg-warmup',
          text: 'warm up',
          sentAt: DateTime.parse('2026-04-28T10:00:00Z'),
        ),
      );
      await firstAtBob;

      // Step 2: simulate Bob restart. Build a fresh Bob with the same
      // keys but a new transport. Update Alice's partner pointer to the
      // new Bob transport. Crucially: Alice still holds her cached
      // session for Bob — that's the stale state we're testing.
      await bob.dispose();
      final newBobT = _FakeTransport();
      aliceT.partner = newBobT;
      newBobT.partner = aliceT;
      bobT = newBobT;

      bob = MeshMessagingService(
        transport: bobT,
        contactKeyStore: bobStore,
        myDevicePrivateKey: bobPriv,
        myDevicePublicKey: bobPub,
      );
      await bob.start(serviceName: 'Bob');

      // Step 3: tell Bob about Alice via discovery so Bob's _peerStates
      // gets seeded. (Without this, Bob's recovery init wouldn't find a
      // _PeerState slot — _onInboundFrame creates one on demand, so this
      // is belt-and-suspenders.)
      bobT.emitDiscovery(PeerDiscovered(
        peerId: alicePeer,
        host: '127.0.0.1',
        port: 0,
      ));

      // Step 4: Alice (with stale session) sends a new envelope. Bob's
      // session==null path triggers recovery. After re-handshake, the
      // NEXT envelope from Alice should decrypt cleanly.
      final receivedAfterRecovery = bob.inbound.first;
      await alice.sendEnvelope(
        toUserPk: bobPeer,
        envelope: Envelope(
          version: 1,
          type: 'text',
          convId: 'conv-recovery',
          clientId: 'msg-stale',
          text: 'sent with stale keys',
          sentAt: DateTime.parse('2026-04-28T10:00:01Z'),
        ),
      );

      // Bob's recovery happens on this incoming frame. The frame itself
      // is dropped (it can't be decrypted), but Bob immediately fires
      // msg1 to Alice. Alice's Phase 2.1 logic resets and responds with
      // msg2. Bob finalises. Then Alice's NEXT send arrives cleanly.
      // We give the round-trip a moment to settle, then send again.
      await Future<void>.delayed(const Duration(milliseconds: 200));

      await alice.sendEnvelope(
        toUserPk: bobPeer,
        envelope: Envelope(
          version: 1,
          type: 'text',
          convId: 'conv-recovery',
          clientId: 'msg-recovered',
          text: 'after recovery',
          sentAt: DateTime.parse('2026-04-28T10:00:02Z'),
        ),
      );

      final got = await receivedAfterRecovery
          .timeout(const Duration(seconds: 3));
      // The first inbound after recovery is whichever decrypted first.
      // It must NOT be the stale 'msg-stale' (that one MAC-failed and
      // was dropped) — it must be 'msg-recovered'.
      expect(got.envelope.clientId, 'msg-recovered');
      expect(got.envelope.text, 'after recovery');

      await alice.dispose();
      await bob.dispose();
    });

    test('decrypt-failed triggers recovery (rate-limit also caps the storm)',
        () async {
      final (alicePriv, alicePub) = await _x25519Keys();
      final (bobPriv, bobPub) = await _x25519Keys();
      final alicePeer = PeerId(alicePub);
      final bobPeer = PeerId(bobPub);

      final aliceStore = ContactKeyStore()
        ..addContact(userPk: bobPeer, devicePks: [bobPeer]);
      final bobStore = ContactKeyStore()
        ..addContact(userPk: alicePeer, devicePks: [alicePeer]);

      final aliceT = _FakeTransport();
      final bobT = _FakeTransport();
      aliceT.partner = bobT;
      bobT.partner = aliceT;

      // Override threshold so the test runs fast and assertion is precise.
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
        peerResetThreshold: 3,
        peerResetWindow: const Duration(seconds: 60),
      );
      await alice.start(serviceName: 'Alice');
      await bob.start(serviceName: 'Bob');

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

      // Establish a session so Bob has state.session != null. This lets
      // the next bad frame fall into the `try { decrypt(...) } catch`
      // branch (decrypt-failed), not the `session == null` branch.
      final firstAtBob = bob.inbound.first;
      await alice.sendEnvelope(
        toUserPk: bobPeer,
        envelope: Envelope(
          version: 1,
          type: 'text',
          convId: 'conv-mac',
          clientId: 'msg-warmup',
          text: 'warm up',
          sentAt: DateTime.parse('2026-04-28T10:00:00Z'),
        ),
      );
      await firstAtBob;

      // Count how many handshake frames Alice receives from Bob across
      // the whole test. Recovery msg1's are observable as inbound
      // FrameType.handshake on Alice's transport.
      var bobHandshakesArrivedAtAlice = 0;
      final aliceFrameSub = aliceT.inbound.listen((f) {
        if (f.type == FrameType.handshake) bobHandshakesArrivedAtAlice++;
      });

      // Push 5 frames of pure garbage as data frames into Bob's inbound.
      // Bob's session.decrypt will throw MAC; recovery will fire 3 times
      // (peerResetThreshold), then be capped.
      for (var i = 0; i < 5; i++) {
        bobT.injectInboundFrame(InboundFrame(
          srcPeer: alicePeer,
          type: FrameType.data,
          bytes: Uint8List.fromList(List<int>.generate(80, (j) => i * 7 + j)),
        ));
      }
      await Future<void>.delayed(const Duration(milliseconds: 300));

      // Each accepted recovery resets and inits one handshake → one msg1
      // arrives at Alice. With threshold=3, expect at most 3 (the
      // existing warm-up handshake's msg1+msg2 already counted before
      // we attached the listener, so we look only at frames *after*
      // listener attach).
      expect(bobHandshakesArrivedAtAlice, lessThanOrEqualTo(3),
          reason: 'rate-limit caps recovery storm at peerResetThreshold');
      expect(bobHandshakesArrivedAtAlice, greaterThanOrEqualTo(1),
          reason: 'at least one recovery must have fired');

      await aliceFrameSub.cancel();
      await alice.dispose();
      await bob.dispose();
    });

    test('peerResetCountTotal counts resets within the window', () async {
      final (alicePriv, alicePub) = await _x25519Keys();
      final (bobPriv, bobPub) = await _x25519Keys();
      final alicePeer = PeerId(alicePub);
      final bobPeer = PeerId(bobPub);

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
        peerResetThreshold: 5,
        peerResetWindow: const Duration(seconds: 60),
      );
      await alice.start(serviceName: 'Alice');
      await bob.start(serviceName: 'Bob');

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

      // Establish Bob's session so MAC-fail path triggers (not session==null).
      final firstAtBob = bob.inbound.first;
      await alice.sendEnvelope(
        toUserPk: bobPeer,
        envelope: Envelope(
          version: 1,
          type: 'text',
          convId: 'conv-counter',
          clientId: 'msg-warmup',
          text: 'warm up',
          sentAt: DateTime.parse('2026-04-28T10:00:00Z'),
        ),
      );
      await firstAtBob;

      expect(bob.peerResetCountTotal, 0,
          reason: 'no resets before garbage frames arrive');

      // Sever Alice→Bob link so Bob's recovery handshakes never get a
      // response from Alice. This prevents Alice from re-establishing
      // Bob's session mid-injection and thus avoids an extra _allowReset
      // hit on Bob when it processes Alice's msg2 while already holding
      // a fresh session.
      bobT.partner = null;

      // Inject 4 garbage data frames into Bob (within threshold=5).
      for (var i = 0; i < 4; i++) {
        bobT.injectInboundFrame(InboundFrame(
          srcPeer: alicePeer,
          type: FrameType.data,
          bytes: Uint8List.fromList(List<int>.generate(80, (j) => i * 11 + j)),
        ));
      }
      await Future<void>.delayed(const Duration(milliseconds: 300));

      expect(bob.peerResetCountTotal, 4,
          reason: 'all 4 garbage frames triggered resets within window');

      await alice.dispose();
      await bob.dispose();
    });
  });
}

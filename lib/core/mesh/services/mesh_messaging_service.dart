import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import '../crypto/keys/contact_key_store.dart';
import '../crypto/noise/noise_ik_handshake.dart';
import '../crypto/noise/session.dart';
import '../transport/frame.dart';
import '../transport/mesh_transport.dart';
import '../transport/peer_id.dart';

class InboundMessage {
  final PeerId fromUserPk;
  final String text;
  InboundMessage({required this.fromUserPk, required this.text});
}

/// High-level messaging over a mesh transport.
///
/// Phase 1a scope:
///   - Single injected transport (typically BonjourTransport)
///   - ContactKeyStore for known peers
///   - Noise IK handshake on first send or on first inbound handshake frame
///   - After handshake: text encrypted with NoiseSession
///   - Dispatching by Frame.type (carried in InboundFrame.type)
///
/// Phase 1a simplification: assumes userPk == devicePk (one device per user).
/// Phase 1b generalizes to multi-device.
class MeshMessagingService {
  final MeshTransport transport;
  final ContactKeyStore contactKeyStore;
  final Uint8List myDevicePrivateKey;
  final Uint8List myDevicePublicKey;

  final Map<PeerId, _PeerState> _peerStates = {};
  final _inboundCtrl = StreamController<InboundMessage>.broadcast();

  StreamSubscription? _frameSub;
  StreamSubscription? _discoverySub;

  MeshMessagingService({
    required this.transport,
    required this.contactKeyStore,
    required this.myDevicePrivateKey,
    required this.myDevicePublicKey,
  });

  Stream<InboundMessage> get inbound => _inboundCtrl.stream;

  Future<void> start({required String serviceName}) async {
    await transport.startAdvertising(DeviceInfo(
      devicePk: PeerId(myDevicePublicKey),
      serviceName: serviceName,
    ));
    _frameSub = transport.inbound.listen(_onInboundFrame);
    _discoverySub = transport.discoveries.listen(_onPeerDiscovered);
  }

  void _onPeerDiscovered(PeerDiscovered p) {
    _peerStates.putIfAbsent(p.peerId, () => _PeerState());
  }

  Future<void> sendText({required PeerId toUserPk, required String text}) async {
    // Phase 1a: userPk == devicePk.
    final devicePk = toUserPk;
    if (!contactKeyStore.isKnownDevice(devicePk)) {
      throw StateError('Unknown contact device: ${devicePk.toHex()}');
    }
    final state = _peerStates.putIfAbsent(devicePk, () => _PeerState());
    if (state.session == null && state.handshake == null) {
      await _initiateHandshake(devicePk, state);
    }
    // Wait up to 2 s for handshake to complete.
    final deadline = DateTime.now().add(const Duration(seconds: 2));
    while (state.session == null && DateTime.now().isBefore(deadline)) {
      await Future.delayed(const Duration(milliseconds: 20));
    }
    if (state.session == null) {
      throw TimeoutException('handshake did not complete');
    }
    final payload = Uint8List.fromList(utf8.encode(text));
    final ct = await state.session!.encrypt(payload);
    await _sendFrame(devicePk, FrameType.data, ct);
  }

  Future<void> _initiateHandshake(PeerId devicePk, _PeerState state) async {
    final handshake = await NoiseIKHandshake.startInitiator(
      initiatorStaticPrivateKey: myDevicePrivateKey,
      initiatorStaticPublicKey: myDevicePublicKey,
      responderStaticPublicKey: devicePk.bytes,
      prologue: Uint8List(0),
    );
    state.handshake = handshake;
    state.isInitiator = true;
    final msg1 = await handshake.writeMessage1(payload: Uint8List(0));
    await _sendFrame(devicePk, FrameType.handshake, msg1);
  }

  Future<void> _onInboundFrame(InboundFrame frame) async {
    final srcDevice = frame.srcPeer;
    if (!contactKeyStore.isKnownDevice(srcDevice)) return; // drop unknown
    final state = _peerStates.putIfAbsent(srcDevice, () => _PeerState());

    if (frame.type == FrameType.handshake) {
      if (state.handshake == null) {
        // Responder path — we received msg1 from an initiator.
        final responder = await NoiseIKHandshake.startResponder(
          responderStaticPrivateKey: myDevicePrivateKey,
          responderStaticPublicKey: myDevicePublicKey,
          prologue: Uint8List(0),
        );
        state.handshake = responder;
        state.isInitiator = false;
        await responder.readMessage1(frame.bytes);
        final msg2 = await responder.writeMessage2(payload: Uint8List(0));
        final (k1, k2) = responder.finalize();
        // Responder: k1 = recv (initiator→responder), k2 = send (responder→initiator).
        state.session = NoiseSession(sendKey: k2, recvKey: k1);
        await _sendFrame(srcDevice, FrameType.handshake, msg2);
      } else if (state.isInitiator) {
        // Initiator receiving msg2.
        await state.handshake!.readMessage2(frame.bytes);
        final (k1, k2) = state.handshake!.finalize();
        // Initiator: k1 = send (initiator→responder), k2 = recv (responder→initiator).
        state.session = NoiseSession(sendKey: k1, recvKey: k2);
      }
      return;
    }

    if (frame.type == FrameType.data) {
      if (state.session == null) return; // no session yet — drop
      try {
        final pt = await state.session!.decrypt(frame.bytes);
        _inboundCtrl.add(InboundMessage(
          fromUserPk: srcDevice,
          text: utf8.decode(pt),
        ));
      } catch (_) {
        // undecryptable — drop silently
      }
      return;
    }
    // Other frame types (keepalive, disconnect) — Phase 1a ignores.
  }

  Future<void> _sendFrame(PeerId peer, FrameType type, Uint8List payload) async {
    final frame = Frame(
      version: 1,
      type: type,
      srcPk: PeerId(myDevicePublicKey),
      payload: payload,
    );
    await transport.send(peer, frame.encode());
  }

  Future<void> dispose() async {
    await _frameSub?.cancel();
    await _discoverySub?.cancel();
    await transport.dispose();
    await _inboundCtrl.close();
  }
}

class _PeerState {
  NoiseIKHandshake? handshake;
  NoiseSession? session;
  bool isInitiator = false;
}

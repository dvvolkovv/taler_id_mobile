import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show debugPrint;

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
/// **IMPORTANT:** [myDevicePrivateKey] and [myDevicePublicKey] must be
/// X25519 keys (from [MeshStaticKey]), NOT Ed25519 ([DeviceKey]).
/// Noise IK requires X25519 Diffie-Hellman. Passing Ed25519 bytes will
/// produce a silent key mismatch — the Noise handshake will fail
/// mysteriously rather than with a clear error.
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
    debugPrint('[mesh-send] sendText to=${devicePk.toHex().substring(0, 12)}... known=${contactKeyStore.isKnownDevice(devicePk)}');
    if (!contactKeyStore.isKnownDevice(devicePk)) {
      throw StateError('Unknown contact device: ${devicePk.toHex()}');
    }
    final state = _peerStates.putIfAbsent(devicePk, () => _PeerState());
    if (state.session == null && state.handshake == null && !state.initiating) {
      state.initiating = true;
      state.sessionEstablished = Completer<void>();
      debugPrint('[mesh-send] initiating new handshake');
      try {
        await _initiateHandshake(devicePk, state);
      } catch (e) {
        state.initiating = false;
        rethrow;
      }
    }
    if (state.session == null) {
      // Phase 1j — 10s timeout (was 2s). On mobile Bonjour + Noise IK, the
      // first TCP connect + handshake can exceed 2s on low-end Android or
      // cold-start iOS. Prior 1i reset-on-timeout caused MAC errors when a
      // late msg2 arrived against a fresh handshake state — that path was
      // reverted here. A stuck handshake now blocks future sends to the
      // same peer until logout; proper retry with state machine is Phase 2.
      debugPrint('[mesh-send] awaiting handshake completion (10s timeout)');
      try {
        await state.sessionEstablished!.future
            .timeout(const Duration(seconds: 10));
      } on TimeoutException {
        debugPrint('[mesh-send] handshake TIMEOUT');
        throw TimeoutException('handshake did not complete');
      }
    }
    debugPrint('[mesh-send] session established, encrypting payload');
    final payload = Uint8List.fromList(utf8.encode(text));
    final ct = await state.session!.encrypt(payload);
    await _sendFrame(devicePk, FrameType.data, ct);
    debugPrint('[mesh-send] data frame sent');
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
    debugPrint(
      '[mesh-frame] ← type=${frame.type} from=${srcDevice.toHex().substring(0, 12)}... known=${contactKeyStore.isKnownDevice(srcDevice)}',
    );
    if (!contactKeyStore.isKnownDevice(srcDevice)) {
      debugPrint('[mesh-frame] DROPPED — unknown devicePk');
      return;
    }
    final state = _peerStates.putIfAbsent(srcDevice, () => _PeerState());

    if (frame.type == FrameType.handshake) {
      if (state.handshake == null) {
        debugPrint('[mesh-frame] starting RESPONDER handshake');
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
        state.sessionEstablished?.complete();
        await _sendFrame(srcDevice, FrameType.handshake, msg2);
        debugPrint('[mesh-frame] responder handshake complete, session established');
      } else if (state.isInitiator) {
        debugPrint('[mesh-frame] initiator receiving msg2');
        // Initiator receiving msg2.
        await state.handshake!.readMessage2(frame.bytes);
        final (k1, k2) = state.handshake!.finalize();
        // Initiator: k1 = send (initiator→responder), k2 = recv (responder→initiator).
        state.session = NoiseSession(sendKey: k1, recvKey: k2);
        state.sessionEstablished?.complete();
        debugPrint('[mesh-frame] initiator handshake complete, session established');
      } else {
        debugPrint('[mesh-frame] unexpected handshake frame — state.isInitiator=${state.isInitiator} handshake!=null');
      }
      return;
    }

    if (frame.type == FrameType.data) {
      if (state.session == null) {
        debugPrint('[mesh-frame] data frame but no session — dropped');
        return;
      }
      try {
        final pt = await state.session!.decrypt(frame.bytes);
        debugPrint('[mesh-frame] decrypted data frame, emitting InboundMessage');
        _inboundCtrl.add(InboundMessage(
          fromUserPk: srcDevice,
          text: utf8.decode(pt),
        ));
      } catch (e) {
        debugPrint('[mesh-frame] decrypt failed: $e');
      }
      return;
    }
    debugPrint('[mesh-frame] ignored frame type: ${frame.type}');
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
  Completer<void>? sessionEstablished;
  /// Phase 1j — guard against parallel handshake init by two rapid
  /// sendText calls. `putIfAbsent` + null-check on `handshake` is not
  /// enough because `_initiateHandshake` has several awaits before
  /// `state.handshake = ...` lands, leaving a window where a second
  /// sendText observes `handshake == null` and starts its own.
  bool initiating = false;
}

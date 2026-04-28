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
import 'envelope.dart';

/// Phase 2 — replaces InboundMessage; carries the full envelope payload
/// so the messenger layer routes by `envelope.convId` (group support).
class InboundEnvelope {
  final PeerId fromUserPk;
  final Envelope envelope;
  InboundEnvelope({required this.fromUserPk, required this.envelope});
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
///
/// Phase 2: data frame plaintext is now JSON-encoded [Envelope.toJson()].
/// [sendText] replaced by [sendEnvelope]; [InboundMessage] replaced by
/// [InboundEnvelope]. Phase 1 1:1 still works — same Noise IK stack,
/// just JSON-wrapped plaintext.
class MeshMessagingService {
  final MeshTransport transport;
  final ContactKeyStore contactKeyStore;
  final Uint8List myDevicePrivateKey;
  final Uint8List myDevicePublicKey;

  /// Phase 2.1 — when initiating a handshake along the recovery path
  /// (i.e., we had a session/handshake with this peer that is now stale),
  /// delay the outbound `handshake_init` by `random(0..jitter)` so that
  /// if the peer initiates concurrently, their init has time to arrive
  /// and we become responder instead of racing.
  final Duration recoveryInitJitter;

  /// Phase 2.1 — after this many resets within `peerResetWindow`, further
  /// resets from the same peer are dropped until the window slides past.
  final int peerResetThreshold;
  final Duration peerResetWindow;

  final Map<PeerId, _PeerState> _peerStates = {};
  final Map<PeerId, List<DateTime>> _peerResetTimes = {};
  final _inboundCtrl = StreamController<InboundEnvelope>.broadcast();

  StreamSubscription? _frameSub;
  StreamSubscription? _discoverySub;

  /// Serializes inbound frame processing. Without this, async `_onInboundFrame`
  /// invocations run concurrently when frames arrive in burst (e.g. Phase 2.2
  /// retry sends N data frames to one peer rapidly), corrupting the per-peer
  /// Noise session state and causing MAC failures on all but the first frame.
  Future<void> _frameTail = Future.value();

  MeshMessagingService({
    required this.transport,
    required this.contactKeyStore,
    required this.myDevicePrivateKey,
    required this.myDevicePublicKey,
    this.recoveryInitJitter = const Duration(milliseconds: 200),
    this.peerResetThreshold = 5,
    this.peerResetWindow = const Duration(seconds: 60),
  });

  Stream<InboundEnvelope> get inbound => _inboundCtrl.stream;

  Future<void> start({required String serviceName}) async {
    await transport.startAdvertising(DeviceInfo(
      devicePk: PeerId(myDevicePublicKey),
      serviceName: serviceName,
    ));
    _frameSub = transport.inbound.listen((frame) {
      _frameTail = _frameTail.then((_) => _onInboundFrame(frame));
    });
    _discoverySub = transport.discoveries.listen(_onPeerDiscovered);
  }

  void _onPeerDiscovered(PeerDiscovered p) {
    _peerStates.putIfAbsent(p.peerId, () => _PeerState());
  }

  /// Phase 2 — envelope-aware send. Wraps the message in a JSON envelope
  /// before encryption so receivers can route by conversationId.
  Future<void> sendEnvelope({
    required PeerId toUserPk,
    required Envelope envelope,
  }) async {
    // Phase 1a: userPk == devicePk.
    final devicePk = toUserPk;
    debugPrint('[mesh-send] sendEnvelope to=${devicePk.toHex().substring(0, 12)}... convId=${envelope.convId} clientId=${envelope.clientId} known=${contactKeyStore.isKnownDevice(devicePk)}');
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
    debugPrint('[mesh-send] session established, encrypting envelope');
    final plaintext = Uint8List.fromList(utf8.encode(jsonEncode(envelope.toJson())));
    final ct = await state.session!.encrypt(plaintext);
    await _sendFrame(devicePk, FrameType.data, ct);
    debugPrint('[mesh-send] data frame sent');
  }

  Future<void> _initiateHandshake(PeerId devicePk, _PeerState state) async {
    final isRecovery = state.hadPriorSession;
    if (isRecovery && recoveryInitJitter > Duration.zero) {
      final ms = (recoveryInitJitter.inMilliseconds *
              (0.25 + 0.75 * (DateTime.now().microsecondsSinceEpoch % 1000) /
                  1000.0))
          .round();
      debugPrint('[mesh-handshake] recovery init — jittering ${ms}ms');
      await Future<void>.delayed(Duration(milliseconds: ms));
      // If the peer initiated during the jitter window, our state will now
      // contain their handshake. Bail out — we became responder.
      if (state.handshake != null && !state.isInitiator) {
        debugPrint('[mesh-handshake] recovery init cancelled — peer beat us');
        state.initiating = false;
        return;
      }
    }
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
      // Phase 2.1 — accept-latest-init: if we have any cached handshake or
      // session for this peer and another `handshake_init` arrives, the peer
      // has restarted. Drop our cached state and process the new init from
      // scratch. Detection: a fresh init carries a Noise IK message1, which
      // is always 48 bytes ephemeral_pk + payload (>= 48); responder-side
      // msg2 we'd expect (from line 169 path) only arrives after we've
      // become initiator. So: if state.session != null OR (state.handshake
      // != null AND !state.isInitiator), this is a fresh init.
      final hasCachedSession = state.session != null;
      final hasCachedResponderHandshake =
          state.handshake != null && !state.isInitiator;
      final isFreshInitFromPeer =
          hasCachedSession || hasCachedResponderHandshake;
      if (isFreshInitFromPeer) {
        if (!_allowReset(srcDevice)) {
          // Drop the frame entirely — peer is in backoff.
          return;
        }
        debugPrint(
          '[mesh-handshake] peer reset detected, dropping cached session pk=${srcDevice.toHex().substring(0, 12)}...',
        );
        _resetPeerState(srcDevice);
      }

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
        state.hadPriorSession = true;
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
        state.hadPriorSession = true;
        state.sessionEstablished?.complete();
        debugPrint('[mesh-frame] initiator handshake complete, session established');
      } else {
        debugPrint('[mesh-frame] unexpected handshake frame — state.isInitiator=${state.isInitiator} handshake!=null');
      }
      return;
    }

    if (frame.type == FrameType.data) {
      if (state.session == null) {
        debugPrint('[mesh-frame] data frame but no session — triggering recovery');
        _triggerStaleRecovery(srcDevice, state, reason: 'no-session');
        return;
      }
      try {
        final pt = await state.session!.decrypt(frame.bytes);
        final envelopeJson = jsonDecode(utf8.decode(pt)) as Map<String, dynamic>;
        final envelope = Envelope.fromJson(envelopeJson);
        debugPrint('[mesh-frame] decrypted envelope, emitting InboundEnvelope convId=${envelope.convId}');
        _inboundCtrl.add(InboundEnvelope(
          fromUserPk: srcDevice,
          envelope: envelope,
        ));
      } on FormatException catch (e) {
        debugPrint('[mesh-frame] envelope decode failed: $e');
      } catch (e) {
        debugPrint('[mesh-frame] decrypt failed: $e — triggering recovery');
        _triggerStaleRecovery(srcDevice, state, reason: 'mac-error');
      }
      return;
    }
    debugPrint('[mesh-frame] ignored frame type: ${frame.type}');
  }

  Future<void> _sendFrame(PeerId peer, FrameType type, Uint8List payload) async {
    final frame = Frame(
      version: Frame.supportedVersion,
      type: type,
      srcPk: PeerId(myDevicePublicKey),
      payload: payload,
    );
    await transport.send(peer, frame.encode());
  }

  /// Returns true if a reset for [devicePk] is allowed; false if the peer
  /// has hit the rate threshold within the current window.
  bool _allowReset(PeerId devicePk) {
    final now = DateTime.now();
    final times = _peerResetTimes.putIfAbsent(devicePk, () => <DateTime>[]);
    times.removeWhere((t) => now.difference(t) > peerResetWindow);
    if (times.length >= peerResetThreshold) {
      debugPrint(
        '[mesh-handshake] reset suppressed — peer pk=${devicePk.toHex().substring(0, 12)}... hit threshold ($peerResetThreshold in ${peerResetWindow.inSeconds}s)',
      );
      return false;
    }
    times.add(now);
    return true;
  }

  /// Phase 2.3 — peer's data frame can't be decrypted (no session OR MAC
  /// failure). The most likely cause is that one side restarted while the
  /// other kept a cached Noise session, so keys no longer match. Reset
  /// our own state and initiate a fresh handshake; Phase 2.1's
  /// accept-latest-init on the peer side handles the rest.
  ///
  /// Rate-limited via _allowReset (5 in 60s per peer) — same backoff
  /// budget Phase 2.1 uses for peer-initiated resets, so a flapping or
  /// adversarial peer can't drive a handshake storm.
  void _triggerStaleRecovery(
    PeerId devicePk,
    _PeerState state, {
    required String reason,
  }) {
    if (!_allowReset(devicePk)) return;
    debugPrint(
      '[mesh-handshake] receiver-side stale recovery '
      '(reason=$reason) pk=${devicePk.toHex().substring(0, 12)}...',
    );
    _resetPeerState(devicePk);
    // Fire-and-forget; if init fails (transport issue) the next bad frame
    // will retry.
    // ignore: unawaited_futures
    _initiateHandshake(devicePk, state).catchError((Object e) {
      debugPrint('[mesh-handshake] stale recovery init failed: $e');
    });
  }

  /// Phase 2.1 — fully clear cached handshake/session for a peer so the
  /// next inbound `handshake_init` from that peer can be processed cleanly.
  /// Called when peer-side restart is detected.
  void _resetPeerState(PeerId devicePk) {
    final state = _peerStates[devicePk];
    if (state == null) return;
    debugPrint('[mesh-handshake] reset peer state pk=${devicePk.toHex().substring(0, 12)}...');
    state.handshake = null;
    state.session = null;
    state.isInitiator = false;
    state.initiating = false;
    state.sessionEstablished = null;
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
  /// sendEnvelope calls. `putIfAbsent` + null-check on `handshake` is not
  /// enough because `_initiateHandshake` has several awaits before
  /// `state.handshake = ...` lands, leaving a window where a second
  /// sendEnvelope observes `handshake == null` and starts its own.
  bool initiating = false;
  /// Phase 2.1 — set after first successful session, used by
  /// `_initiateHandshake` to decide whether to apply recovery jitter.
  bool hadPriorSession = false;
}

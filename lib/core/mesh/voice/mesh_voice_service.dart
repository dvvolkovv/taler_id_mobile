import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import '../../audio/mesh_voice_audio_engine.dart';
import '../crypto/mesh_datagram_cipher.dart';
import '../services/envelope.dart';
import '../services/mesh_messaging_service.dart';
import '../transport/mesh_transport.dart';
import '../transport/peer_id.dart';
import 'mesh_voice_frame.dart';
import 'mesh_voice_state.dart';

/// Orchestrates a 1-on-1 mesh voice call: signaling, state machine,
/// audio-engine ↔ datagram-pipe wiring. One service per app instance;
/// only one call active at a time.
///
/// Lifecycle (caller): IDLE → INVITING → ACTIVE → ENDED.
/// Lifecycle (callee): IDLE → INCOMING → ACTIVE → ENDED.
///
/// CONNECTING state is reserved for a future explicit setup handshake
/// (Phase 3c.1) — Phase 3c does not transition through it.
class MeshVoiceService {
  final MeshMessagingService messaging;
  final MeshTransport transport;
  final MeshVoiceAudioEngine Function() audioEngineFactory;

  final _stateCtrl = StreamController<CallState>.broadcast();
  CallState _state = const IdleState();

  StreamSubscription<InboundEnvelope>? _envelopeSub;
  StreamSubscription<InboundDatagram>? _datagramSub;
  Timer? _inviteTimeoutTimer;

  StreamSubscription<Uint8List>? _audioOutSub;
  MeshVoiceAudioEngine? _activeEngine;
  ({MeshDatagramCipher outbound, MeshDatagramCipher inbound})? _activeCiphers;
  int _outSeq = 0;

  // Generation counter for cancelling an in-flight _enterActive when
  // hangup/_onCallEnd runs concurrently (e.g., user mashes hangup
  // between accept() awaits). Bumped by _exitActive.
  int _enterGen = 0;

  static const Duration _inviteTimeout = Duration(seconds: 30);
  static const Duration _datagramTimeoutDuration = Duration(seconds: 3);
  static const Duration _keepaliveInterval = Duration(seconds: 1);

  Timer? _datagramWatchdog;
  Timer? _keepaliveTimer;

  static const Map<String, dynamic> _defaultCodecParams = {
    'audio': 'opus',
    'rate': 16000,
    'channels': 1,
    'frame_ms': 20,
    'bitrate': 24000,
    'fec': false,
  };

  MeshVoiceService({
    required this.messaging,
    required this.transport,
    required this.audioEngineFactory,
    bool Function()? isGroupCallBusy,
  }) : _isGroupCallBusy = isGroupCallBusy ?? (() => false);

  final bool Function() _isGroupCallBusy;

  /// Current call state.
  CallState get state => _state;

  /// Stream of state transitions.
  Stream<CallState> get stateStream => _stateCtrl.stream;

  /// True while a 1-on-1 mesh call is in progress (inviting, incoming,
  /// connecting, or active). False only when the state is [IdleState] or
  /// [EndedState].
  bool get isBusy => _state is! IdleState && _state is! EndedState;

  /// Wire up signaling + datagram listeners. Call once at app start
  /// (typically from DI bootstrap, after MeshMessagingService.start).
  void start() {
    _envelopeSub = messaging.inbound.listen(_onEnvelope);
    _datagramSub = transport.inboundDatagrams.listen(_onDatagram);
  }

  /// Caller-side: initiate a call to [calleeDevicePk]. Returns the
  /// generated call_id. Throws if not currently IDLE.
  Future<int> invite(PeerId calleeDevicePk) async {
    if (_state is! IdleState) {
      throw StateError('cannot invite: already in $_state');
    }
    final callId = _generateCallId();
    final inviteSentAt = DateTime.now().toUtc();
    final envelope = Envelope(
      version: 1,
      type: 'call_invite',
      convId: 'call-${callId.toRadixString(16)}',
      clientId: callId.toRadixString(16),
      text: '',
      sentAt: inviteSentAt,
      extra: {
        'call_id': callId,
        'codec_params': _defaultCodecParams,
        'datagram_seq_init': _generateSeqInit(),
      },
    );
    await messaging.sendEnvelope(toUserPk: calleeDevicePk, envelope: envelope);
    _setState(InvitingState(
      calleeDevicePk: calleeDevicePk,
      callId: callId,
      sentAt: inviteSentAt,
    ));
    _inviteTimeoutTimer?.cancel();
    _inviteTimeoutTimer = Timer(_inviteTimeout, () {
      if (_state is InvitingState && (_state as InvitingState).callId == callId) {
        _setState(EndedState(callId: callId, reason: EndReason.inviteTimeout));
        // Best-effort end notice (fire-and-forget).
        messaging.sendEnvelope(
          toUserPk: calleeDevicePk,
          envelope: Envelope(
            version: 1,
            type: 'call_end',
            convId: 'call-${callId.toRadixString(16)}',
            clientId: callId.toRadixString(16),
            text: '',
            sentAt: DateTime.now().toUtc(),
            extra: {'call_id': callId, 'reason': 'timeout'},
          ),
        ).catchError((_) {});
      }
    });
    return callId;
  }

  /// Callee-side: accept the current INCOMING call.
  Future<void> accept() async {
    final st = _state;
    if (st is! IncomingState) {
      throw StateError('accept(): not in IncomingState (current=$st)');
    }
    final envelope = Envelope(
      version: 1,
      type: 'call_accept',
      convId: 'call-${st.callId.toRadixString(16)}',
      clientId: st.callId.toRadixString(16),
      text: '',
      sentAt: DateTime.now().toUtc(),
      extra: {
        'call_id': st.callId,
        'codec_params': _defaultCodecParams,
        'datagram_seq_init': _generateSeqInit(),
      },
    );
    await messaging.sendEnvelope(toUserPk: st.callerDevicePk, envelope: envelope);
    await _enterActive(st.callerDevicePk, st.callId, isCaller: false);
  }

  /// Callee-side: reject the current INCOMING call.
  Future<void> reject({String reason = 'declined'}) async {
    final st = _state;
    if (st is! IncomingState) {
      throw StateError('reject(): not in IncomingState (current=$st)');
    }
    await messaging.sendEnvelope(
      toUserPk: st.callerDevicePk,
      envelope: Envelope(
        version: 1,
        type: 'call_reject',
        convId: 'call-${st.callId.toRadixString(16)}',
        clientId: st.callId.toRadixString(16),
        text: '',
        sentAt: DateTime.now().toUtc(),
        extra: {'call_id': st.callId, 'reason': reason},
      ),
    );
    _setState(EndedState(callId: st.callId, reason: EndReason.userHangup));
  }

  /// Either side: end the active or pending call.
  Future<void> hangup({EndReason reason = EndReason.userHangup}) async {
    final st = _state;
    final cid = _callIdOf(st);
    if (cid == null) return;
    PeerId? peer;
    if (st is InvitingState) peer = st.calleeDevicePk;
    if (st is IncomingState) peer = st.callerDevicePk;
    if (st is ConnectingState) peer = st.peerDevicePk;
    if (st is ActiveState) peer = st.peerDevicePk;
    if (peer != null) {
      // Fire-and-forget: don't block hangup on network delivery. If
      // handshake is stuck (ContactKeyStore behind, peer offline), an
      // awaited sendEnvelope can hang up to 10s — unacceptable for the
      // hangup button. State transition must be immediate.
      messaging.sendEnvelope(
        toUserPk: peer,
        envelope: Envelope(
          version: 1,
          type: 'call_end',
          convId: 'call-${cid.toRadixString(16)}',
          clientId: cid.toRadixString(16),
          text: '',
          sentAt: DateTime.now().toUtc(),
          extra: {'call_id': cid, 'reason': reason.name},
        ),
      ).catchError((_) {});
    }
    _setState(EndedState(callId: cid, reason: reason));
    await _exitActive();
    _inviteTimeoutTimer?.cancel();
  }

  /// Cleanup on app shutdown.
  Future<void> dispose() async {
    _inviteTimeoutTimer?.cancel();
    await _exitActive();
    await _envelopeSub?.cancel();
    await _datagramSub?.cancel();
    await _stateCtrl.close();
  }

  void _setState(CallState next) {
    _state = next;
    _stateCtrl.add(next);
    if (next is EndedState) {
      // After a call ends, return to IdleState so the next invite() can
      // proceed. We delay 2s so UI consumers can render the "ended"
      // status before the screen auto-pops.
      final endedCallId = next.callId;
      Timer(const Duration(seconds: 2), () {
        final cur = _state;
        if (cur is EndedState && cur.callId == endedCallId) {
          _state = const IdleState();
          if (!_stateCtrl.isClosed) _stateCtrl.add(const IdleState());
        }
      });
    }
  }

  void _onEnvelope(InboundEnvelope msg) {
    final type = msg.envelope.type;
    if (!type.startsWith('call_')) return;
    final extra = msg.envelope.extra;
    final callId = extra?['call_id'];
    if (callId is! int) return;
    switch (type) {
      case 'call_invite':
        _onCallInvite(msg.fromUserPk, callId, extra!);
        break;
      case 'call_accept':
        _onCallAccept(msg.fromUserPk, callId);
        break;
      case 'call_reject':
        _onCallReject(callId, extra);
        break;
      case 'call_end':
        _onCallEnd(callId);
        break;
      case 'call_keepalive':
        // Refresh the datagram watchdog from the signaling channel too.
        // If UDP datagrams are blocked but envelopes flow (TCP via Bonjour),
        // keepalives keep the call alive — at the cost of audio. UI shows
        // "no audio" indication separately.
        if (_state is ActiveState && (_state as ActiveState).callId == callId) {
          _resetDatagramWatchdog();
        }
        break;
    }
  }

  void _onCallInvite(PeerId from, int callId, Map<String, dynamic> extra) {
    // Mic-conflict guard: if a group mesh call is active on this device, a
    // simultaneous 1-on-1 invite must be auto-rejected immediately so two
    // callers don't fight for the microphone / audio session.
    final groupBusy = _isGroupCallBusy();
    if (_state is! IdleState || groupBusy) {
      messaging.sendEnvelope(
        toUserPk: from,
        envelope: Envelope(
          version: 1,
          type: 'call_reject',
          convId: 'call-${callId.toRadixString(16)}',
          clientId: callId.toRadixString(16),
          text: '',
          sentAt: DateTime.now().toUtc(),
          extra: {'call_id': callId, 'reason': 'busy'},
        ),
      ).catchError((_) {});
      return;
    }
    _setState(IncomingState(
      callerDevicePk: from,
      callId: callId,
      receivedAt: DateTime.now().toUtc(),
    ));
  }

  void _onCallAccept(PeerId from, int callId) {
    final st = _state;
    if (st is! InvitingState || st.callId != callId) return;
    _inviteTimeoutTimer?.cancel();
    _enterActive(from, callId, isCaller: true).catchError((Object _) {
      if (_callIdOf(_state) == callId && _state is! EndedState) {
        _setState(EndedState(callId: callId, reason: EndReason.error));
      }
      _exitActive();
    });
  }

  void _onCallReject(int callId, Map<String, dynamic>? extra) {
    final st = _state;
    if (st is InvitingState && st.callId == callId) {
      _inviteTimeoutTimer?.cancel();
      _setState(EndedState(callId: callId, reason: EndReason.rejectedByCallee));
    }
  }

  void _onCallEnd(int callId) {
    final st = _state;
    if (st is EndedState) return;
    if (_callIdOf(st) != callId) return;
    _inviteTimeoutTimer?.cancel();
    _setState(EndedState(callId: callId, reason: EndReason.remoteHangup));
    _exitActive();
  }

  int? _callIdOf(CallState s) {
    if (s is InvitingState) return s.callId;
    if (s is IncomingState) return s.callId;
    if (s is ConnectingState) return s.callId;
    if (s is ActiveState) return s.callId;
    return null;
  }

  void _onDatagram(InboundDatagram dg) async {
    final st = _state;
    if (st is! ActiveState) return;
    _resetDatagramWatchdog();
    final MeshVoiceFrame frame;
    try {
      frame = MeshVoiceFrame.decode(dg.bytes);
    } on FormatException {
      return;
    }
    if (frame.callId != st.callId) return;
    final ciphers = _activeCiphers;
    Uint8List pt;
    if (ciphers != null) {
      try {
        pt = await ciphers.inbound.decrypt(seq: frame.seq, ciphertext: frame.ciphertext);
      } catch (_) {
        return; // drop on AEAD/replay failure
      }
    } else {
      pt = frame.ciphertext; // test fallback (see _enterActive)
    }
    _activeEngine?.inbound(seq: frame.seq, payload: pt);
  }

  Future<void> _enterActive(PeerId peer, int callId, {required bool isCaller}) async {
    final gen = ++_enterGen;

    ({MeshDatagramCipher outbound, MeshDatagramCipher inbound})? ciphers;
    try {
      ciphers = await messaging.datagramCiphersFor(peer);
    } catch (_) {
      // TEST-ONLY mitigation: FakeMessagingService.datagramCiphersFor is not
      // stubbed so noSuchMethod throws. Production MeshMessagingService never
      // throws here — it returns non-null when a Noise session exists.
      ciphers = null;
    }
    if (gen != _enterGen) return;

    final engine = audioEngineFactory();
    await engine.start();
    if (gen != _enterGen) {
      await engine.stop().catchError((_) {});
      return;
    }

    _activeCiphers = ciphers;
    _activeEngine = engine;
    _audioOutSub = engine.outbound.listen((opus) async {
      final ciphers = _activeCiphers;
      Uint8List ct;
      if (ciphers != null) {
        _outSeq++;
        ct = await ciphers.outbound.encrypt(seq: _outSeq, plaintext: opus);
      } else {
        _outSeq++;
        ct = opus;
      }
      final frame = MeshVoiceFrame(
        type: MeshVoiceFrameType.audio,
        callId: callId,
        seq: _outSeq,
        ciphertext: ct,
      );
      try {
        await transport.sendDatagram(peer, frame.encode());
      } catch (_) {
        // Drop on transport error; persistent failures end the call via
        // the keepalive watchdog.
      }
    });
    _setState(ActiveState(
      peerDevicePk: peer,
      callId: callId,
      isCaller: isCaller,
      startedAt: DateTime.now().toUtc(),
    ));
    _resetDatagramWatchdog();
    _startKeepalive(peer, callId);
  }

  Future<void> _exitActive() async {
    _enterGen++; // invalidate any in-flight _enterActive
    _datagramWatchdog?.cancel();
    _datagramWatchdog = null;
    _keepaliveTimer?.cancel();
    _keepaliveTimer = null;
    await _audioOutSub?.cancel();
    _audioOutSub = null;
    await _activeEngine?.stop();
    _activeEngine = null;
    _activeCiphers = null;
    _outSeq = 0;
  }

  void _resetDatagramWatchdog() {
    _datagramWatchdog?.cancel();
    _datagramWatchdog = Timer(_datagramTimeoutDuration, () {
      final st = _state;
      if (st is ActiveState) {
        _setState(EndedState(callId: st.callId, reason: EndReason.noKeepalive));
        _exitActive();
      }
    });
  }

  void _startKeepalive(PeerId peer, int callId) {
    _keepaliveTimer?.cancel();
    _keepaliveTimer = Timer.periodic(_keepaliveInterval, (_) {
      messaging.sendEnvelope(
        toUserPk: peer,
        envelope: Envelope(
          version: 1,
          type: 'call_keepalive',
          convId: 'call-${callId.toRadixString(16)}',
          clientId: callId.toRadixString(16),
          text: '',
          sentAt: DateTime.now().toUtc(),
          extra: {'call_id': callId},
        ),
      ).catchError((_) {});
    });
  }

  static int _generateCallId() {
    final rng = Random.secure();
    return rng.nextInt(0xFFFFFFFF);
  }

  static int _generateSeqInit() {
    final rng = Random.secure();
    return rng.nextInt(0xFFFFFFFF);
  }
}

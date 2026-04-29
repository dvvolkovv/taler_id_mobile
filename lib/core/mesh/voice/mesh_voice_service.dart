import 'dart:async';
import 'dart:math';

import '../../audio/mesh_voice_audio_engine.dart';
import '../services/envelope.dart';
import '../services/mesh_messaging_service.dart';
import '../transport/mesh_transport.dart';
import '../transport/peer_id.dart';
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

  static const Duration _inviteTimeout = Duration(seconds: 30);

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
  });

  /// Current call state.
  CallState get state => _state;

  /// Stream of state transitions.
  Stream<CallState> get stateStream => _stateCtrl.stream;

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
    _setState(ConnectingState(
      peerDevicePk: st.callerDevicePk,
      callId: st.callId,
      isCaller: false,
    ));
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
    throw UnimplementedError('hangup — implemented in Task 9');
  }

  /// Cleanup on app shutdown.
  Future<void> dispose() async {
    _inviteTimeoutTimer?.cancel();
    await _envelopeSub?.cancel();
    await _datagramSub?.cancel();
    await _stateCtrl.close();
  }

  void _setState(CallState next) {
    _state = next;
    _stateCtrl.add(next);
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
      // call_setup / call_keepalive — Tasks 8-9.
    }
  }

  void _onCallInvite(PeerId from, int callId, Map<String, dynamic> extra) {
    if (_state is! IdleState) {
      // Busy — auto-reject.
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
    _setState(ConnectingState(
      peerDevicePk: from,
      callId: callId,
      isCaller: true,
    ));
    // T8 wires audio + datagram pipe here (will replace ConnectingState with ActiveState).
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
  }

  int? _callIdOf(CallState s) {
    if (s is InvitingState) return s.callId;
    if (s is IncomingState) return s.callId;
    if (s is ConnectingState) return s.callId;
    if (s is ActiveState) return s.callId;
    return null;
  }

  void _onDatagram(InboundDatagram dg) {
    // Decrypt + dispatch in T8.
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

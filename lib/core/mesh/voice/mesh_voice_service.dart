import 'dart:async';

import '../../audio/mesh_voice_audio_engine.dart';
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
    throw UnimplementedError('invite — implemented in Task 6');
  }

  /// Callee-side: accept the current INCOMING call.
  Future<void> accept() async {
    throw UnimplementedError('accept — implemented in Task 7');
  }

  /// Either side: end the active or pending call.
  Future<void> hangup({EndReason reason = EndReason.userHangup}) async {
    throw UnimplementedError('hangup — implemented in Task 9');
  }

  /// Cleanup on app shutdown.
  Future<void> dispose() async {
    await _envelopeSub?.cancel();
    await _datagramSub?.cancel();
    await _stateCtrl.close();
  }

  void _setState(CallState next) {
    _state = next;
    _stateCtrl.add(next);
  }

  void _onEnvelope(InboundEnvelope msg) {
    // Routed by `type` to per-type handlers in T6/T7.
  }

  void _onDatagram(InboundDatagram dg) {
    // Decrypt + dispatch in T8.
  }
}

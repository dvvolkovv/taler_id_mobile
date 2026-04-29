import '../transport/peer_id.dart';

/// Sealed-style hierarchy for the MeshVoiceService state machine.
sealed class CallState {
  const CallState();
}

/// No active call — service waiting for invite or user-initiated call.
class IdleState extends CallState {
  const IdleState();
}

/// Caller side: invite sent, awaiting accept/reject (30s timeout).
class InvitingState extends CallState {
  final PeerId calleeDevicePk;
  final int callId;
  final DateTime sentAt;
  const InvitingState({
    required this.calleeDevicePk,
    required this.callId,
    required this.sentAt,
  });
}

/// Callee side: invite received, UI showing accept/decline.
class IncomingState extends CallState {
  final PeerId callerDevicePk;
  final int callId;
  final DateTime receivedAt;
  const IncomingState({
    required this.callerDevicePk,
    required this.callId,
    required this.receivedAt,
  });
}

/// Both sides: parameters negotiated, audio session being set up (5s timeout).
/// RESERVED but unused in Phase 3c — caller goes straight from INVITING to
/// ACTIVE on call_accept; callee goes straight from INCOMING to ACTIVE on
/// accept(). Phase 3c.1 may add an explicit setup handshake using this state.
class ConnectingState extends CallState {
  final PeerId peerDevicePk;
  final int callId;
  final bool isCaller;
  const ConnectingState({
    required this.peerDevicePk,
    required this.callId,
    required this.isCaller,
  });
}

/// Both sides: audio flowing in both directions.
class ActiveState extends CallState {
  final PeerId peerDevicePk;
  final int callId;
  final bool isCaller;
  final DateTime startedAt;
  const ActiveState({
    required this.peerDevicePk,
    required this.callId,
    required this.isCaller,
    required this.startedAt,
  });
}

/// Terminal state — call cleanup done. `reason` describes why.
class EndedState extends CallState {
  final int callId;
  final EndReason reason;
  const EndedState({required this.callId, required this.reason});
}

enum EndReason {
  userHangup,
  remoteHangup,
  rejectedByCallee,
  inviteTimeout,
  setupTimeout,
  noKeepalive,
  peerLost,
  error,
}

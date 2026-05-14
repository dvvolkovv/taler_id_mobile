import 'package:equatable/equatable.dart';
import 'package:taler_id_mobile/core/mesh/voice/group_mesh_call_state.dart';

sealed class GroupMeshCallEvent extends Equatable {
  const GroupMeshCallEvent();
  @override
  List<Object?> get props => const [];
}

class GMCStartRequested extends GroupMeshCallEvent {
  const GMCStartRequested({
    required this.invitees,
    this.hostDisplayName,
  });
  final Map<String, String> invitees; // devicePkHex → userId
  /// Caller's display name — propagated through invite envelope extras so
  /// receivers can label the call in CallKit and the roster with the
  /// inviter's CURRENT name rather than whatever's stale in their local
  /// contact-key cache.
  final String? hostDisplayName;
  @override
  List<Object?> get props => [invitees, hostDisplayName];
}

class GMCAcceptInvite extends GroupMeshCallEvent {
  const GMCAcceptInvite({
    required this.roomId,
    required this.hostDevicePkHex,
    required this.participantDevicePks,
    this.hostDisplayName,
  });
  final String roomId;
  final String hostDevicePkHex;
  final List<String> participantDevicePks;
  /// Inviter's display name from the invite envelope — used to populate the
  /// host's GMCParticipant on the invitee side so the roster doesn't read
  /// "unknown" or a stale contact-cache name.
  final String? hostDisplayName;
  @override
  List<Object?> get props =>
      [roomId, hostDevicePkHex, participantDevicePks, hostDisplayName];
}

class GMCDeclineInvite extends GroupMeshCallEvent {
  const GMCDeclineInvite({
    required this.roomId,
    required this.hostDevicePkHex,
  });
  final String roomId;
  final String hostDevicePkHex;
  @override
  List<Object?> get props => [roomId, hostDevicePkHex];
}

class GMCLeavePressed extends GroupMeshCallEvent {
  const GMCLeavePressed();
}

class GMCToggleMute extends GroupMeshCallEvent {
  const GMCToggleMute();
}

class GMCServiceStateForwarded extends GroupMeshCallEvent {
  const GMCServiceStateForwarded(this.next);
  final GroupMeshCallState next;
  @override
  List<Object?> get props => [identityHashCode(next)];
}

import 'package:equatable/equatable.dart';
import 'package:taler_id_mobile/core/mesh/voice/group_mesh_call_state.dart';

sealed class GroupMeshCallEvent extends Equatable {
  const GroupMeshCallEvent();
  @override
  List<Object?> get props => const [];
}

class GMCStartRequested extends GroupMeshCallEvent {
  const GMCStartRequested({required this.invitees});
  final Map<String, String> invitees; // devicePkHex → userId
  @override
  List<Object?> get props => [invitees];
}

class GMCAcceptInvite extends GroupMeshCallEvent {
  const GMCAcceptInvite({
    required this.roomId,
    required this.hostDevicePkHex,
    required this.participantDevicePks,
  });
  final String roomId;
  final String hostDevicePkHex;
  final List<String> participantDevicePks;
  @override
  List<Object?> get props => [roomId, hostDevicePkHex, participantDevicePks];
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

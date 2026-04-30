import 'package:freezed_annotation/freezed_annotation.dart';

part 'group_call_event.freezed.dart';

@freezed
sealed class GroupCallEvent with _$GroupCallEvent {
  // User-initiated:
  const factory GroupCallEvent.createCall(List<String> inviteeIds) = CreateCall;
  const factory GroupCallEvent.joinCall(String callId) = JoinCall;
  const factory GroupCallEvent.declineCall(String callId) = DeclineCall;
  const factory GroupCallEvent.leaveCall(String callId) = LeaveCall;
  const factory GroupCallEvent.inviteMore(String callId, List<String> userIds) =
      InviteMore;
  const factory GroupCallEvent.kick(String callId, String userId) = Kick;
  const factory GroupCallEvent.muteAll(String callId) = MuteAll;
  const factory GroupCallEvent.endCall(String callId) = EndCall;

  // Socket.io-driven (incoming):
  const factory GroupCallEvent.statusUpdated(Map<String, dynamic> payload) =
      StatusUpdated;
  const factory GroupCallEvent.kicked(Map<String, dynamic> payload) = Kicked;
  const factory GroupCallEvent.muteRequested(Map<String, dynamic> payload) =
      MuteRequested;
  const factory GroupCallEvent.hostChanged(Map<String, dynamic> payload) =
      HostChanged;
  const factory GroupCallEvent.ended(Map<String, dynamic> payload) = Ended;
}

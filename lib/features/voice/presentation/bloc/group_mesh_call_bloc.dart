import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taler_id_mobile/core/mesh/voice/group_mesh_call_service.dart';
import 'package:taler_id_mobile/core/mesh/voice/group_mesh_call_state.dart';
import 'package:taler_id_mobile/features/voice/presentation/bloc/group_mesh_call_event.dart';

class GroupMeshCallBloc extends Bloc<GroupMeshCallEvent, GroupMeshCallState> {
  GroupMeshCallBloc({required this.service}) : super(service.state) {
    on<GMCStartRequested>(_onStart);
    on<GMCAcceptInvite>(_onAccept);
    on<GMCDeclineInvite>(_onDecline);
    on<GMCLeavePressed>(_onLeave);
    on<GMCToggleMute>(_onToggleMute);
    on<GMCServiceStateForwarded>(_onForwarded);

    _serviceSub = service.stateStream.listen((s) {
      add(GMCServiceStateForwarded(s));
    });
  }

  final GroupMeshCallService service;
  StreamSubscription<GroupMeshCallState>? _serviceSub;

  Future<void> _onStart(
      GMCStartRequested e, Emitter<GroupMeshCallState> emit) async {
    try {
      await service.start(
        invitees: e.invitees,
        hostDisplayName: e.hostDisplayName,
      );
    } on StateError catch (err) {
      emit(GMCError(message: err.message));
    }
  }

  Future<void> _onAccept(
      GMCAcceptInvite e, Emitter<GroupMeshCallState> emit) async {
    await service.acceptInvite(
      roomId: e.roomId,
      hostDevicePkHex: e.hostDevicePkHex,
      participantDevicePks: e.participantDevicePks,
      hostDisplayName: e.hostDisplayName,
    );
  }

  Future<void> _onDecline(
      GMCDeclineInvite e, Emitter<GroupMeshCallState> emit) async {
    await service.declineInvite(
      roomId: e.roomId,
      hostDevicePkHex: e.hostDevicePkHex,
    );
  }

  Future<void> _onLeave(
      GMCLeavePressed e, Emitter<GroupMeshCallState> emit) async {
    await service.leave();
  }

  Future<void> _onToggleMute(
      GMCToggleMute e, Emitter<GroupMeshCallState> emit) async {
    await service.toggleMute();
  }

  void _onForwarded(
      GMCServiceStateForwarded e, Emitter<GroupMeshCallState> emit) {
    emit(e.next);
  }

  @override
  Future<void> close() async {
    await _serviceSub?.cancel();
    return super.close();
  }
}

import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:taler_id_mobile/core/mesh/voice/group_mesh_call_service.dart';
import 'package:taler_id_mobile/core/mesh/voice/group_mesh_call_state.dart';
import 'package:taler_id_mobile/features/voice/presentation/bloc/group_mesh_call_bloc.dart';
import 'package:taler_id_mobile/features/voice/presentation/bloc/group_mesh_call_event.dart';

class _MockService extends Mock implements GroupMeshCallService {}

void main() {
  late _MockService svc;
  late StreamController<GroupMeshCallState> stateCtrl;

  setUp(() {
    svc = _MockService();
    stateCtrl = StreamController<GroupMeshCallState>.broadcast();
    when(() => svc.state).thenReturn(const GMCIdle());
    when(() => svc.stateStream).thenAnswer((_) => stateCtrl.stream);
    when(() => svc.start(invitees: any(named: 'invitees')))
        .thenAnswer((_) async {});
    when(() => svc.leave()).thenAnswer((_) async {});
    when(() => svc.toggleMute()).thenAnswer((_) async {});
    when(() => svc.acceptInvite(
          roomId: any(named: 'roomId'),
          hostDevicePkHex: any(named: 'hostDevicePkHex'),
          participantDevicePks: any(named: 'participantDevicePks'),
        )).thenAnswer((_) async {});
    when(() => svc.declineInvite(
          roomId: any(named: 'roomId'),
          hostDevicePkHex: any(named: 'hostDevicePkHex'),
        )).thenAnswer((_) async {});
  });

  tearDown(() async {
    await stateCtrl.close();
  });

  blocTest<GroupMeshCallBloc, GroupMeshCallState>(
    'forwards service state to bloc state',
    build: () => GroupMeshCallBloc(service: svc),
    act: (b) {
      stateCtrl.add(const GMCLobby(
        roomId: 'r1',
        hostDevicePk: 'h',
        roster: [],
      ));
    },
    expect: () => [isA<GMCLobby>()],
  );

  blocTest<GroupMeshCallBloc, GroupMeshCallState>(
    'GMCStartRequested calls service.start',
    build: () => GroupMeshCallBloc(service: svc),
    act: (b) => b.add(const GMCStartRequested(invitees: {'aabb': 'u1'})),
    verify: (_) {
      verify(() => svc.start(invitees: {'aabb': 'u1'})).called(1);
    },
  );

  blocTest<GroupMeshCallBloc, GroupMeshCallState>(
    'GMCLeavePressed calls service.leave',
    build: () => GroupMeshCallBloc(service: svc),
    act: (b) => b.add(const GMCLeavePressed()),
    verify: (_) {
      verify(() => svc.leave()).called(1);
    },
  );

  blocTest<GroupMeshCallBloc, GroupMeshCallState>(
    'GMCToggleMute calls service.toggleMute',
    build: () => GroupMeshCallBloc(service: svc),
    act: (b) => b.add(const GMCToggleMute()),
    verify: (_) {
      verify(() => svc.toggleMute()).called(1);
    },
  );

  blocTest<GroupMeshCallBloc, GroupMeshCallState>(
    'GMCStartRequested catches StateError as GMCError',
    setUp: () {
      when(() => svc.start(invitees: any(named: 'invitees')))
          .thenThrow(StateError('cap exceeded'));
    },
    build: () => GroupMeshCallBloc(service: svc),
    act: (b) => b.add(const GMCStartRequested(invitees: {'aabb': 'u1'})),
    expect: () => [isA<GMCError>()],
  );
}

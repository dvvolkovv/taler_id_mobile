import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:taler_id_mobile/features/messenger/data/datasources/messenger_remote_datasource.dart';
import 'package:taler_id_mobile/features/voice/domain/entities/group_call.dart';
import 'package:taler_id_mobile/features/voice/domain/entities/group_call_invite.dart';
import 'package:taler_id_mobile/features/voice/domain/repositories/group_call_repository.dart';
import 'package:taler_id_mobile/features/voice/presentation/bloc/group_call_bloc.dart';
import 'package:taler_id_mobile/features/voice/presentation/bloc/group_call_event.dart';
import 'package:taler_id_mobile/features/voice/presentation/bloc/group_call_state.dart';

class MockRepo extends Mock implements GroupCallRepository {}

class MockSocket extends Mock implements MessengerRemoteDataSource {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockRepo repo;
  late MockSocket socket;

  Stream<Map<String, dynamic>> emptyStream() =>
      StreamController<Map<String, dynamic>>.broadcast().stream;

  setUp(() {
    repo = MockRepo();
    socket = MockSocket();
    when(() => socket.gcStatusStream).thenAnswer((_) => emptyStream());
    when(() => socket.gcKickedStream).thenAnswer((_) => emptyStream());
    when(() => socket.gcMuteRequestStream).thenAnswer((_) => emptyStream());
    when(() => socket.gcHostChangedStream).thenAnswer((_) => emptyStream());
    when(() => socket.gcEndedStream).thenAnswer((_) => emptyStream());
  });

  GroupCall fakeCall({
    String id = 'c1',
    GroupCallStatus status = GroupCallStatus.lobby,
  }) {
    return GroupCall(
      id: id,
      livekitRoomName: 'group-$id',
      hostUserId: 'host',
      hostDisplayName: 'Host',
      status: status,
      startedAt: DateTime(2026, 4, 29),
    );
  }

  blocTest<GroupCallBloc, GroupCallState>(
    'createCall: idle -> creating -> inLobby on success',
    build: () => GroupCallBloc(repo, socket),
    setUp: () {
      when(() => repo.create(inviteeIds: ['u1'])).thenAnswer(
        (_) async => (
          call: fakeCall(),
          livekitToken: 'jwt',
          livekitWsUrl: 'ws://lk',
        ),
      );
    },
    act: (bloc) => bloc.add(const GroupCallEvent.createCall(['u1'])),
    expect: () => [
      const GroupCallState.creating(),
      isA<InLobby>(),
    ],
  );

  blocTest<GroupCallBloc, GroupCallState>(
    'createCall: idle -> creating -> error on repo failure',
    build: () => GroupCallBloc(repo, socket),
    setUp: () {
      when(() => repo.create(inviteeIds: ['u1'])).thenThrow(Exception('boom'));
    },
    act: (bloc) => bloc.add(const GroupCallEvent.createCall(['u1'])),
    expect: () => [
      const GroupCallState.creating(),
      isA<ErrorState>(),
    ],
  );

  blocTest<GroupCallBloc, GroupCallState>(
    'joinCall: emits InActive on success',
    build: () => GroupCallBloc(repo, socket),
    setUp: () {
      when(() => repo.join('c1')).thenAnswer(
        (_) async => (livekitToken: 'jwt', livekitWsUrl: 'ws://lk'),
      );
      when(() => repo.getCall('c1'))
          .thenAnswer((_) async => fakeCall(status: GroupCallStatus.active));
    },
    act: (bloc) => bloc.add(const GroupCallEvent.joinCall('c1')),
    expect: () => [isA<InActive>()],
  );

  blocTest<GroupCallBloc, GroupCallState>(
    'joinCall: emits ErrorState on failure',
    build: () => GroupCallBloc(repo, socket),
    setUp: () {
      when(() => repo.join('c1')).thenThrow(Exception('network'));
    },
    act: (bloc) => bloc.add(const GroupCallEvent.joinCall('c1')),
    expect: () => [isA<ErrorState>()],
  );

  blocTest<GroupCallBloc, GroupCallState>(
    'Kicked event in InActive -> emits Idle',
    build: () => GroupCallBloc(repo, socket),
    seed: () => GroupCallState.inActive(
      groupCall: fakeCall(status: GroupCallStatus.active),
      livekitToken: 'jwt',
      livekitWsUrl: 'ws://lk',
    ),
    act: (bloc) => bloc.add(
      const GroupCallEvent.kicked({'groupCallId': 'c1', 'by': 'host'}),
    ),
    expect: () => [const GroupCallState.idle()],
  );

  blocTest<GroupCallBloc, GroupCallState>(
    'Ended event in InActive -> emits Ended(reason)',
    build: () => GroupCallBloc(repo, socket),
    seed: () => GroupCallState.inActive(
      groupCall: fakeCall(status: GroupCallStatus.active),
      livekitToken: 'jwt',
      livekitWsUrl: 'ws://lk',
    ),
    act: (bloc) => bloc.add(
      const GroupCallEvent.ended(
          {'groupCallId': 'c1', 'reason': 'host_ended'}),
    ),
    expect: () => [const GroupCallState.ended('host_ended')],
  );

  blocTest<GroupCallBloc, GroupCallState>(
    'MuteRequested event in InActive -> sets muteRequestedByHost=true',
    build: () => GroupCallBloc(repo, socket),
    seed: () => GroupCallState.inActive(
      groupCall: fakeCall(status: GroupCallStatus.active),
      livekitToken: 'jwt',
      livekitWsUrl: 'ws://lk',
    ),
    act: (bloc) => bloc.add(
      const GroupCallEvent.muteRequested({'groupCallId': 'c1', 'by': 'host'}),
    ),
    expect: () => [
      isA<InActive>().having(
        (s) => s.muteRequestedByHost,
        'muteRequestedByHost',
        true,
      ),
    ],
  );

  blocTest<GroupCallBloc, GroupCallState>(
    'StatusUpdated event in InLobby -> updates invites',
    build: () => GroupCallBloc(repo, socket),
    seed: () => GroupCallState.inLobby(
      groupCall: fakeCall(),
      livekitToken: 'jwt',
      livekitWsUrl: 'ws://lk',
    ),
    act: (bloc) => bloc.add(GroupCallEvent.statusUpdated({
      'groupCallId': 'c1',
      'invites': [
        {
          'id': 'i1',
          'userId': 'u1',
          'status': 'JOINED',
          'invitedAt': DateTime.now().toIso8601String(),
          'user': {
            'id': 'u1',
            'profile': {'firstName': 'Alice', 'lastName': 'Smith'},
          },
        },
      ],
    })),
    expect: () => [
      isA<InLobby>()
          .having(
            (s) => s.groupCall.invites.length,
            'invites.length',
            1,
          )
          .having(
            (s) => s.groupCall.invites.first.status,
            'invites.first.status',
            GroupCallInviteStatus.joined,
          ),
    ],
  );

  blocTest<GroupCallBloc, GroupCallState>(
    'LeaveCall -> emits Idle',
    build: () => GroupCallBloc(repo, socket),
    seed: () => GroupCallState.inActive(
      groupCall: fakeCall(status: GroupCallStatus.active),
      livekitToken: 'jwt',
      livekitWsUrl: 'ws://lk',
    ),
    setUp: () {
      when(() => repo.leave('c1')).thenAnswer((_) async {});
    },
    act: (bloc) => bloc.add(const GroupCallEvent.leaveCall('c1')),
    expect: () => [const GroupCallState.idle()],
  );

  blocTest<GroupCallBloc, GroupCallState>(
    'EndCall -> emits Idle',
    build: () => GroupCallBloc(repo, socket),
    seed: () => GroupCallState.inActive(
      groupCall: fakeCall(status: GroupCallStatus.active),
      livekitToken: 'jwt',
      livekitWsUrl: 'ws://lk',
    ),
    setUp: () {
      when(() => repo.end('c1')).thenAnswer((_) async {});
    },
    act: (bloc) => bloc.add(const GroupCallEvent.endCall('c1')),
    expect: () => [const GroupCallState.idle()],
  );
}

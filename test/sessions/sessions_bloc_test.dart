import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:taler_id_mobile/core/api/api_exception.dart';
import 'package:taler_id_mobile/features/sessions/domain/entities/session_entity.dart';
import 'package:taler_id_mobile/features/sessions/domain/repositories/i_session_repository.dart';
import 'package:taler_id_mobile/features/sessions/presentation/bloc/sessions_bloc.dart';
import 'package:taler_id_mobile/features/sessions/presentation/bloc/sessions_event.dart';
import 'package:taler_id_mobile/features/sessions/presentation/bloc/sessions_state.dart';

class MockSessionRepository extends Mock implements ISessionRepository {}

final _sessions = [
  SessionEntity(
    id: 'sess-1',
    device: 'iPhone 18',
    ip: '192.168.1.1',
    location: 'Vienna, AT',
    createdAt: DateTime(2024, 1, 10),
    isCurrent: true,
  ),
  SessionEntity(
    id: 'sess-2',
    device: 'Chrome on Mac',
    ip: '10.0.0.5',
    createdAt: DateTime(2024, 1, 12),
    isCurrent: false,
  ),
  SessionEntity(
    id: 'sess-3',
    device: 'Android',
    ip: '172.16.0.1',
    createdAt: DateTime(2024, 1, 14),
    isCurrent: false,
  ),
];

void main() {
  late MockSessionRepository repo;
  late SessionsBloc bloc;

  setUp(() {
    repo = MockSessionRepository();
    bloc = SessionsBloc(repo: repo);
  });

  tearDown(() => bloc.close());

  // ── Load sessions ─────────────────────────────────────────────────────────

  group('SessionsLoadRequested', () {
    blocTest<SessionsBloc, SessionsState>(
      'emits [Loading, Loaded] with all sessions',
      build: () {
        when(() => repo.getSessions()).thenAnswer((_) async => _sessions);
        return bloc;
      },
      act: (b) => b.add(SessionsLoadRequested()),
      expect: () => [
        isA<SessionsLoading>(),
        isA<SessionsLoaded>()
            .having((s) => s.sessions.length, 'count', 3)
            .having((s) => s.sessions.first.id, 'first id', 'sess-1'),
      ],
      verify: (_) => verify(() => repo.getSessions()).called(1),
    );

    blocTest<SessionsBloc, SessionsState>(
      'emits [Loading, Loaded] with empty list',
      build: () {
        when(() => repo.getSessions()).thenAnswer((_) async => []);
        return bloc;
      },
      act: (b) => b.add(SessionsLoadRequested()),
      expect: () => [
        isA<SessionsLoading>(),
        isA<SessionsLoaded>().having((s) => s.sessions, 'sessions', isEmpty),
      ],
    );

    blocTest<SessionsBloc, SessionsState>(
      'marks current session correctly',
      build: () {
        when(() => repo.getSessions()).thenAnswer((_) async => _sessions);
        return bloc;
      },
      act: (b) => b.add(SessionsLoadRequested()),
      expect: () => [
        isA<SessionsLoading>(),
        isA<SessionsLoaded>().having(
          (s) => s.sessions.where((s) => s.isCurrent).length,
          'current count',
          1,
        ),
      ],
    );

    blocTest<SessionsBloc, SessionsState>(
      'emits [Loading, Error] on ApiException',
      build: () {
        when(() => repo.getSessions())
            .thenThrow(const ApiException(statusCode: 401, message: 'Unauthorized'));
        return bloc;
      },
      act: (b) => b.add(SessionsLoadRequested()),
      expect: () => [
        isA<SessionsLoading>(),
        isA<SessionsError>().having((s) => s.message, 'message', 'Unauthorized'),
      ],
    );

    blocTest<SessionsBloc, SessionsState>(
      'emits [Loading, Error] on unexpected exception',
      build: () {
        when(() => repo.getSessions()).thenThrow(Exception('timeout'));
        return bloc;
      },
      act: (b) => b.add(SessionsLoadRequested()),
      expect: () => [
        isA<SessionsLoading>(),
        isA<SessionsError>()
            .having((s) => s.message, 'message', 'Не удалось загрузить сессии'),
      ],
    );
  });

  // ── Delete session ────────────────────────────────────────────────────────

  group('SessionDeleteRequested', () {
    blocTest<SessionsBloc, SessionsState>(
      'removes session from loaded list on success',
      build: () {
        when(() => repo.getSessions()).thenAnswer((_) async => _sessions);
        when(() => repo.deleteSession('sess-2')).thenAnswer((_) async {});
        return bloc;
      },
      seed: () => SessionsLoaded(_sessions),
      act: (b) => b.add(SessionDeleteRequested('sess-2')),
      expect: () => [
        isA<SessionsLoaded>()
            .having((s) => s.sessions.length, 'count after delete', 2)
            .having((s) => s.sessions.any((s) => s.id == 'sess-2'), 'sess-2 gone', false),
      ],
      verify: (_) => verify(() => repo.deleteSession('sess-2')).called(1),
    );

    blocTest<SessionsBloc, SessionsState>(
      'emits [Error] when delete fails',
      build: () {
        when(() => repo.deleteSession('sess-2'))
            .thenThrow(const ApiException(statusCode: 403, message: 'Forbidden'));
        return bloc;
      },
      seed: () => SessionsLoaded(_sessions),
      act: (b) => b.add(SessionDeleteRequested('sess-2')),
      expect: () => [
        isA<SessionsError>().having((s) => s.message, 'message', 'Forbidden'),
      ],
    );

    blocTest<SessionsBloc, SessionsState>(
      'keeps remaining sessions after deleting one of three',
      build: () {
        when(() => repo.deleteSession('sess-3')).thenAnswer((_) async {});
        return bloc;
      },
      seed: () => SessionsLoaded(_sessions),
      act: (b) => b.add(SessionDeleteRequested('sess-3')),
      expect: () => [
        isA<SessionsLoaded>().having(
          (s) => s.sessions.map((s) => s.id).toList(),
          'remaining ids',
          ['sess-1', 'sess-2'],
        ),
      ],
    );

    blocTest<SessionsBloc, SessionsState>(
      'deleting all sessions leaves empty list',
      build: () {
        when(() => repo.deleteSession(any())).thenAnswer((_) async {});
        return bloc;
      },
      seed: () => SessionsLoaded([_sessions.last]),
      act: (b) => b.add(SessionDeleteRequested(_sessions.last.id)),
      expect: () => [
        isA<SessionsLoaded>().having((s) => s.sessions, 'sessions', isEmpty),
      ],
    );
  });
}

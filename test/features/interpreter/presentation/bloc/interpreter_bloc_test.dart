import 'dart:async';
import 'dart:convert';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:taler_id_mobile/features/interpreter/data/interpreter_lang_store.dart';
import 'package:taler_id_mobile/features/interpreter/domain/interpreter_error.dart';
import 'package:taler_id_mobile/features/interpreter/domain/interpreter_models.dart';
import 'package:taler_id_mobile/features/interpreter/domain/interpreter_repository.dart';
import 'package:taler_id_mobile/features/interpreter/presentation/bloc/interpreter_bloc.dart';
import 'package:taler_id_mobile/features/interpreter/presentation/bloc/interpreter_event.dart';
import 'package:taler_id_mobile/features/interpreter/presentation/bloc/interpreter_state.dart';
import 'package:taler_id_mobile/features/interpreter/room/interpreter_device.dart';
import 'package:taler_id_mobile/features/interpreter/room/interpreter_room_controller.dart'
    show PartnerJoined;
import 'package:taler_id_mobile/features/interpreter/room/interpreter_room_port.dart';
import 'package:taler_id_mobile/features/interpreter/room/interpreter_signal.dart';
import 'package:taler_id_mobile/features/voice_enrollment/domain/entities/owner_voice_status.dart';
import 'package:taler_id_mobile/features/voice_enrollment/domain/repositories/voice_enrollment_repository.dart';

import '../../fakes.dart';

class MockInterpreterRepository extends Mock implements InterpreterRepository {}

class MockVoiceEnrollmentRepository extends Mock
    implements VoiceEnrollmentRepository {}

class MockInterpreterLangStore extends Mock implements InterpreterLangStore {}

class MockInterpreterDevice extends Mock implements InterpreterDevice {}

const _hostIdentity = 'host-user#aaaaaaaa';
const _partnerIdentity = 'partner-user#bbbbbbbb';
const _partnerUserId = 'partner-user';
const _tinyDelay = Duration(milliseconds: 5);

InterpreterCatalog _catalog() => const InterpreterCatalog(
      enabled: true,
      languages: [
        InterpreterLanguage(code: 'ru', name: 'Русский'),
        InterpreterLanguage(code: 'de', name: 'Deutsch'),
      ],
    );

HostedSession _hostedSession({String code = 'ABCD1234'}) => HostedSession(
      sessionId: 'sess-1',
      code: code,
      expiresAt: DateTime.utc(2026, 11, 1, 12, 5),
      roomName: 'interp-1',
      token: 'tok-host',
      livekitWsUrl: 'wss://lk/host',
    );

JoinedSession _joinedSession() => const JoinedSession(
      sessionId: 'sess-2',
      roomName: 'interp-2',
      token: 'tok-guest',
      livekitWsUrl: 'wss://lk/guest',
      partner: InterpreterPartner(firstName: 'B', lang: 'de'),
      directions: InterpreterDirections(
        toMe: InterpreterEngine.simultaneous,
        fromMe: InterpreterEngine.phrase,
      ),
    );

SessionView _activeView({String? spentPlanck}) => SessionView(
      status: InterpreterStatus.active,
      partner: const InterpreterPartner(firstName: 'B', lang: 'de'),
      directions: const InterpreterDirections(
        toMe: InterpreterEngine.simultaneous,
        fromMe: InterpreterEngine.simultaneous,
      ),
      startedAt: DateTime.utc(2026, 11, 1, 12, 0, 5),
      spentPlanck: spentPlanck,
    );

SessionView _endedView(InterpreterEndReason reason, {String? spentPlanck}) =>
    SessionView(
        status: InterpreterStatus.ended,
        endReason: reason,
        spentPlanck: spentPlanck);

List<int> _signalBytes(Map<String, Object?> json) =>
    utf8.encode(jsonEncode(json));

void main() {
  late MockInterpreterRepository repo;
  late MockVoiceEnrollmentRepository voice;
  late MockInterpreterLangStore langStore;
  late MockInterpreterDevice device;
  late FakeRoomPort port;
  late InterpreterBloc bloc;

  InterpreterBloc makeBloc(
          {Duration pollEvery = const Duration(seconds: 30)}) =>
      InterpreterBloc(
        repo: repo,
        langStore: langStore,
        voice: voice,
        roomFactory: () => port,
        device: device,
        appLocale: () => 'ru',
        livekitUrl: () => 'wss://media/livekit/',
        pollEvery: pollEvery,
      );

  setUpAll(() {
    registerFallbackValue(
        const InterpreterCatalog(enabled: true, languages: []));
  });

  setUp(() {
    repo = MockInterpreterRepository();
    voice = MockVoiceEnrollmentRepository();
    langStore = MockInterpreterLangStore();
    device = MockInterpreterDevice();
    port = FakeRoomPort(identity: _hostIdentity);

    when(() => device.enterConversation()).thenAnswer((_) async {});
    when(() => device.leaveConversation()).thenAnswer((_) async {});
    when(() => device.setNearEarScreenOff(any())).thenAnswer((_) async {});
    when(() => langStore.remember(any())).thenAnswer((_) async {});

    bloc = makeBloc();
  });

  tearDown(() async {
    await bloc.close();
    await port.close();
  });

  group('Started', () {
    blocTest<InterpreterBloc, InterpreterState>(
      'catalog disabled -> Unavailable',
      build: () {
        when(() => repo.catalog()).thenAnswer(
          (_) async => const InterpreterCatalog(enabled: false, languages: []),
        );
        return bloc;
      },
      act: (b) => b.add(const Started()),
      expect: () => [
        const InterpreterLoading(),
        const InterpreterUnavailable(),
      ],
    );

    blocTest<InterpreterBloc, InterpreterState>(
      'loads the catalog and preselects the stored language',
      build: () {
        when(() => repo.catalog()).thenAnswer((_) async => _catalog());
        when(() => langStore.initial(any(), any()))
            .thenAnswer((_) async => 'de');
        return bloc;
      },
      act: (b) => b.add(const Started()),
      expect: () => [
        const InterpreterLoading(),
        isA<InterpreterChoosing>()
            .having((s) => s.myLang, 'myLang', 'de')
            .having((s) => s.catalog.languages.length, 'languages', 2)
            .having((s) => s.joinCode, 'joinCode', isNull),
      ],
    );

    blocTest<InterpreterBloc, InterpreterState>(
      'carries a deep-linked join code through into Choosing',
      build: () {
        when(() => repo.catalog()).thenAnswer((_) async => _catalog());
        when(() => langStore.initial(any(), any()))
            .thenAnswer((_) async => 'ru');
        return bloc;
      },
      act: (b) => b.add(const Started(joinCode: 'JOIN99')),
      expect: () => [
        const InterpreterLoading(),
        isA<InterpreterChoosing>()
            .having((s) => s.joinCode, 'joinCode', 'JOIN99'),
      ],
    );

    blocTest<InterpreterBloc, InterpreterState>(
      'a catalog load failure has nowhere to go back to; RetryPressed reloads it',
      build: () {
        var attempt = 0;
        when(() => repo.catalog()).thenAnswer((_) async {
          attempt++;
          if (attempt == 1) {
            throw const InterpreterException(InterpreterErrorKind.network);
          }
          return _catalog();
        });
        when(() => langStore.initial(any(), any()))
            .thenAnswer((_) async => 'ru');
        return bloc;
      },
      act: (b) async {
        b.add(const Started());
        await Future.delayed(_tinyDelay);
        b.add(const RetryPressed());
      },
      expect: () => [
        const InterpreterLoading(),
        isA<InterpreterFailure>()
            .having((s) => s.kind, 'kind', InterpreterErrorKind.network)
            .having((s) => s.back, 'back', isNull),
        const InterpreterLoading(),
        isA<InterpreterChoosing>(),
      ],
    );
  });

  group('host flow', () {
    blocTest<InterpreterBloc, InterpreterState>(
      'happy path: create, enter the room once, emit Hosting',
      build: () {
        when(() => repo.catalog()).thenAnswer((_) async => _catalog());
        when(() => langStore.initial(any(), any()))
            .thenAnswer((_) async => 'ru');
        when(() => voice.getStatus())
            .thenAnswer((_) async => const OwnerVoiceStatus(enrolled: true));
        when(() => repo.create('ru')).thenAnswer((_) async => _hostedSession());
        return bloc;
      },
      act: (b) async {
        b.add(const Started());
        await Future.delayed(_tinyDelay);
        b.add(const HostPressed());
        await Future.delayed(_tinyDelay);
        // Checked here, not in `verify` — bloc_test closes the bloc (which
        // tears down the room, adding a `disconnect()` call) before `verify`
        // runs, so the room's call log has to be inspected while still live.
        expect(port.calls, [
          'connect(wss://media/livekit/, tok-host)',
          'restrictMicTo(voice-interpreter)',
          'setMicrophone(true)',
        ]);
      },
      expect: () => [
        const InterpreterLoading(),
        isA<InterpreterChoosing>(),
        const InterpreterWorking(InterpreterWorkKind.creating),
        isA<InterpreterHosting>()
            .having((s) => s.code, 'code', 'ABCD1234')
            .having((s) => s.myLang, 'myLang', 'ru'),
      ],
      verify: (_) {
        // The QR is still on screen at this point — turning the proximity
        // sensor on here would blank it before the partner can scan it.
        verifyNever(() => device.setNearEarScreenOff(any()));
      },
    );

    blocTest<InterpreterBloc, InterpreterState>(
      'NewCodePressed replaces the code and expiry while hosting',
      build: () {
        when(() => repo.catalog()).thenAnswer((_) async => _catalog());
        when(() => langStore.initial(any(), any()))
            .thenAnswer((_) async => 'ru');
        when(() => voice.getStatus())
            .thenAnswer((_) async => const OwnerVoiceStatus(enrolled: true));
        when(() => repo.create('ru')).thenAnswer((_) async => _hostedSession());
        when(() => repo.newCode('sess-1')).thenAnswer(
          (_) async => NewCode(
              code: 'NEWCODE1', expiresAt: DateTime.utc(2026, 11, 1, 12, 10)),
        );
        return bloc;
      },
      act: (b) async {
        b.add(const Started());
        await Future.delayed(_tinyDelay);
        b.add(const HostPressed());
        await Future.delayed(_tinyDelay);
        b.add(const NewCodePressed());
      },
      skip: 3,
      expect: () => [
        isA<InterpreterHosting>().having((s) => s.code, 'code', 'ABCD1234'),
        isA<InterpreterHosting>().having((s) => s.code, 'code', 'NEWCODE1'),
      ],
    );

    blocTest<InterpreterBloc, InterpreterState>(
      'NewCodePressed failing falls back to the last known Choosing',
      build: () {
        when(() => repo.catalog()).thenAnswer((_) async => _catalog());
        when(() => langStore.initial(any(), any()))
            .thenAnswer((_) async => 'ru');
        when(() => voice.getStatus())
            .thenAnswer((_) async => const OwnerVoiceStatus(enrolled: true));
        when(() => repo.create('ru')).thenAnswer((_) async => _hostedSession());
        when(() => repo.newCode('sess-1')).thenThrow(
            const InterpreterException(InterpreterErrorKind.notWaiting));
        return bloc;
      },
      act: (b) async {
        b.add(const Started());
        await Future.delayed(_tinyDelay);
        b.add(const HostPressed());
        await Future.delayed(_tinyDelay);
        b.add(const NewCodePressed());
      },
      skip: 3,
      expect: () => [
        isA<InterpreterHosting>(),
        isA<InterpreterFailure>()
            .having((s) => s.kind, 'kind', InterpreterErrorKind.notWaiting)
            .having((s) => s.back, 'back', isA<InterpreterChoosing>()),
      ],
    );

    blocTest<InterpreterBloc, InterpreterState>(
      'PartnerJoined while hosting fetches the session and becomes Active',
      build: () {
        when(() => repo.catalog()).thenAnswer((_) async => _catalog());
        when(() => langStore.initial(any(), any()))
            .thenAnswer((_) async => 'ru');
        when(() => voice.getStatus())
            .thenAnswer((_) async => const OwnerVoiceStatus(enrolled: true));
        when(() => repo.create('ru')).thenAnswer((_) async => _hostedSession());
        when(() => repo.get('sess-1')).thenAnswer((_) async => _activeView());
        return bloc;
      },
      act: (b) async {
        b.add(const Started());
        await Future.delayed(_tinyDelay);
        b.add(const HostPressed());
        await Future.delayed(_tinyDelay);
        port.emit(const ParticipantJoined(_partnerIdentity));
      },
      skip: 3,
      expect: () => [
        isA<InterpreterHosting>(),
        isA<InterpreterActive>()
            .having((s) => s.isHost, 'isHost', true)
            .having((s) => s.partner.lang, 'partner lang', 'de')
            .having((s) => s.directions.toMe, 'toMe',
                InterpreterEngine.simultaneous)
            .having((s) => s.spentPlanck, 'spentPlanck', isNull),
      ],
      verify: (_) {
        // Now that the partner is actually on the call, the proximity
        // sensor can safely take over the screen.
        verify(() => device.setNearEarScreenOff(true)).called(1);
      },
    );

    blocTest<InterpreterBloc, InterpreterState>(
      'a session view missing partner/directions is treated like a failed '
      'repo.get, not a crash',
      build: () {
        when(() => repo.catalog()).thenAnswer((_) async => _catalog());
        when(() => langStore.initial(any(), any()))
            .thenAnswer((_) async => 'ru');
        when(() => voice.getStatus())
            .thenAnswer((_) async => const OwnerVoiceStatus(enrolled: true));
        when(() => repo.create('ru')).thenAnswer((_) async => _hostedSession());
        // The backend contract guarantees partner/directions once a partner
        // has joined, but this is exactly the shape that used to crash via
        // `view.partner!`/`view.directions!`.
        when(() => repo.get('sess-1')).thenAnswer(
            (_) async => const SessionView(status: InterpreterStatus.active));
        return bloc;
      },
      act: (b) async {
        b.add(const Started());
        await Future.delayed(_tinyDelay);
        b.add(const HostPressed());
        await Future.delayed(_tinyDelay);
        port.emit(const ParticipantJoined(_partnerIdentity));
        await Future.delayed(_tinyDelay);
        // Torn down right away, same as a failed repo.get() — not left live.
        expect(port.disconnected, isTrue);
      },
      skip: 3,
      expect: () => [
        isA<InterpreterHosting>(),
        isA<InterpreterFailure>()
            .having((s) => s.kind, 'kind', InterpreterErrorKind.unknown),
      ],
      verify: (_) {
        verifyNever(() => device.setNearEarScreenOff(any()));
      },
    );

    blocTest<InterpreterBloc, InterpreterState>(
      'a PartnerJoined that reaches the bloc before Hosting is emitted is '
      'not dropped — the host still reaches Active, not stuck on the QR',
      build: () {
        when(() => repo.catalog()).thenAnswer((_) async => _catalog());
        when(() => langStore.initial(any(), any()))
            .thenAnswer((_) async => 'ru');
        when(() => voice.getStatus())
            .thenAnswer((_) async => const OwnerVoiceStatus(enrolled: true));
        when(() => repo.create('ru')).thenAnswer((_) async => _hostedSession());
        when(() => repo.get('sess-1')).thenAnswer((_) async => _activeView());
        return bloc;
      },
      act: (b) async {
        b.add(const Started());
        await Future.delayed(_tinyDelay);
        // Queued back-to-back, no await in between: HostPressed's handler
        // still has `voice.getStatus()`, `repo.create()`, entering the room
        // and connecting the port ahead of it before Hosting is ever
        // emitted, while this one only has to reach the `case
        // PartnerJoined` branch — exactly the ordering the room's own
        // ParticipantJoined replay can produce for real.
        b.add(const HostPressed());
        b.add(RoomUpdateArrived(const PartnerJoined(_partnerIdentity)));
        await Future.delayed(_tinyDelay);
      },
      verify: (b) {
        expect(b.state, isA<InterpreterActive>());
      },
    );
  });

  group('guest flow', () {
    blocTest<InterpreterBloc, InterpreterState>(
      'happy path: join, enter the room once, emit Active from the join answer',
      build: () {
        when(() => repo.catalog()).thenAnswer((_) async => _catalog());
        when(() => langStore.initial(any(), any()))
            .thenAnswer((_) async => 'ru');
        when(() => voice.getStatus())
            .thenAnswer((_) async => const OwnerVoiceStatus(enrolled: true));
        when(() => repo.join('CODE1', 'ru'))
            .thenAnswer((_) async => _joinedSession());
        return bloc;
      },
      act: (b) async {
        b.add(const Started());
        await Future.delayed(_tinyDelay);
        b.add(const JoinPressed('CODE1'));
        await Future.delayed(_tinyDelay);
        // Checked here, not in `verify` — see the host happy-path test for why.
        expect(port.calls, [
          'connect(wss://media/livekit/, tok-guest)',
          'restrictMicTo(voice-interpreter)',
          'setMicrophone(true)',
        ]);
      },
      expect: () => [
        const InterpreterLoading(),
        isA<InterpreterChoosing>(),
        const InterpreterWorking(InterpreterWorkKind.joining),
        isA<InterpreterActive>()
            .having((s) => s.isHost, 'isHost', false)
            .having((s) => s.partner.firstName, 'partner', 'B')
            .having((s) => s.spentPlanck, 'spentPlanck', isNull),
      ],
      verify: (_) {
        verify(() => device.setNearEarScreenOff(true)).called(1);
      },
    );
  });

  group('voice-print gate', () {
    blocTest<InterpreterBloc, InterpreterState>(
      'missing voice print opens the gate; cancelling returns to Choosing',
      build: () {
        when(() => repo.catalog()).thenAnswer((_) async => _catalog());
        when(() => langStore.initial(any(), any()))
            .thenAnswer((_) async => 'ru');
        when(() => voice.getStatus())
            .thenAnswer((_) async => const OwnerVoiceStatus(enrolled: false));
        return bloc;
      },
      act: (b) async {
        b.add(const Started());
        await Future.delayed(_tinyDelay);
        b.add(const HostPressed());
        await Future.delayed(_tinyDelay);
        b.add(const VoicePrintResult(false));
      },
      expect: () => [
        const InterpreterLoading(),
        isA<InterpreterChoosing>(),
        const InterpreterNeedVoicePrint(then: InterpreterPendingAction.host),
        isA<InterpreterChoosing>(),
      ],
    );

    blocTest<InterpreterBloc, InterpreterState>(
      'missing voice print opens the gate; confirming continues hosting',
      build: () {
        when(() => repo.catalog()).thenAnswer((_) async => _catalog());
        when(() => langStore.initial(any(), any()))
            .thenAnswer((_) async => 'ru');
        when(() => voice.getStatus())
            .thenAnswer((_) async => const OwnerVoiceStatus(enrolled: false));
        when(() => repo.create('ru')).thenAnswer((_) async => _hostedSession());
        return bloc;
      },
      act: (b) async {
        b.add(const Started());
        await Future.delayed(_tinyDelay);
        b.add(const HostPressed());
        await Future.delayed(_tinyDelay);
        b.add(const VoicePrintResult(true));
      },
      expect: () => [
        const InterpreterLoading(),
        isA<InterpreterChoosing>(),
        const InterpreterNeedVoicePrint(then: InterpreterPendingAction.host),
        const InterpreterWorking(InterpreterWorkKind.creating),
        isA<InterpreterHosting>(),
      ],
    );

    blocTest<InterpreterBloc, InterpreterState>(
      'missing voice print for a join carries the code through and on into Active',
      build: () {
        when(() => repo.catalog()).thenAnswer((_) async => _catalog());
        when(() => langStore.initial(any(), any()))
            .thenAnswer((_) async => 'ru');
        when(() => voice.getStatus())
            .thenAnswer((_) async => const OwnerVoiceStatus(enrolled: false));
        when(() => repo.join('CODE1', 'ru'))
            .thenAnswer((_) async => _joinedSession());
        return bloc;
      },
      act: (b) async {
        b.add(const Started());
        await Future.delayed(_tinyDelay);
        b.add(const JoinPressed('CODE1'));
        await Future.delayed(_tinyDelay);
        b.add(const VoicePrintResult(true));
      },
      expect: () => [
        const InterpreterLoading(),
        isA<InterpreterChoosing>(),
        const InterpreterNeedVoicePrint(
            then: InterpreterPendingAction.join, code: 'CODE1'),
        const InterpreterWorking(InterpreterWorkKind.joining),
        isA<InterpreterActive>(),
      ],
    );

    blocTest<InterpreterBloc, InterpreterState>(
      'a 409 voice_print_required from the server also opens the gate',
      build: () {
        when(() => repo.catalog()).thenAnswer((_) async => _catalog());
        when(() => langStore.initial(any(), any()))
            .thenAnswer((_) async => 'ru');
        when(() => voice.getStatus())
            .thenAnswer((_) async => const OwnerVoiceStatus(enrolled: true));
        when(() => repo.join('CODE1', 'ru')).thenThrow(
          const InterpreterException(InterpreterErrorKind.voicePrintRequired),
        );
        return bloc;
      },
      act: (b) async {
        b.add(const Started());
        await Future.delayed(_tinyDelay);
        b.add(const JoinPressed('CODE1'));
      },
      expect: () => [
        const InterpreterLoading(),
        isA<InterpreterChoosing>(),
        const InterpreterWorking(InterpreterWorkKind.joining),
        const InterpreterNeedVoicePrint(
            then: InterpreterPendingAction.join, code: 'CODE1'),
      ],
    );

    blocTest<InterpreterBloc, InterpreterState>(
      'a failed voice-print check itself surfaces as Failure, not NeedVoicePrint',
      build: () {
        when(() => repo.catalog()).thenAnswer((_) async => _catalog());
        when(() => langStore.initial(any(), any()))
            .thenAnswer((_) async => 'ru');
        when(() => voice.getStatus()).thenThrow(Exception('network'));
        return bloc;
      },
      act: (b) async {
        b.add(const Started());
        await Future.delayed(_tinyDelay);
        b.add(const HostPressed());
      },
      expect: () => [
        const InterpreterLoading(),
        isA<InterpreterChoosing>(),
        isA<InterpreterFailure>()
            .having((s) => s.kind, 'kind', InterpreterErrorKind.unknown)
            .having((s) => s.back, 'back', isA<InterpreterChoosing>()),
      ],
    );
  });

  group('every backend error kind surfaces as Failure', () {
    const kinds = [
      InterpreterErrorKind.sameLanguage,
      InterpreterErrorKind.ownCode,
      InterpreterErrorKind.codeUsed,
      InterpreterErrorKind.codeExpired,
      InterpreterErrorKind.codeNotFound,
      InterpreterErrorKind.hostInsufficientFunds,
      InterpreterErrorKind.hostVoicePrintRequired,
      InterpreterErrorKind.interpreterUnavailable,
      InterpreterErrorKind.tooManyAttempts,
      InterpreterErrorKind.network,
      InterpreterErrorKind.unknown,
    ];

    for (final kind in kinds) {
      blocTest<InterpreterBloc, InterpreterState>(
        'join failing with ${kind.name} -> Failure(back: Choosing)',
        build: () {
          when(() => repo.catalog()).thenAnswer((_) async => _catalog());
          when(() => langStore.initial(any(), any()))
              .thenAnswer((_) async => 'ru');
          when(() => voice.getStatus())
              .thenAnswer((_) async => const OwnerVoiceStatus(enrolled: true));
          when(() => repo.join('CODE1', 'ru'))
              .thenThrow(InterpreterException(kind));
          return bloc;
        },
        act: (b) async {
          b.add(const Started());
          await Future.delayed(_tinyDelay);
          b.add(const JoinPressed('CODE1'));
        },
        expect: () => [
          const InterpreterLoading(),
          isA<InterpreterChoosing>(),
          const InterpreterWorking(InterpreterWorkKind.joining),
          isA<InterpreterFailure>()
              .having((s) => s.kind, 'kind', kind)
              .having((s) => s.back, 'back', isA<InterpreterChoosing>()),
        ],
      );
    }
  });

  group('RetryPressed / BackToStart', () {
    blocTest<InterpreterBloc, InterpreterState>(
      'RetryPressed from a Failure returns to the Choosing it carries',
      build: () {
        when(() => repo.catalog()).thenAnswer((_) async => _catalog());
        when(() => langStore.initial(any(), any()))
            .thenAnswer((_) async => 'ru');
        when(() => voice.getStatus())
            .thenAnswer((_) async => const OwnerVoiceStatus(enrolled: true));
        when(() => repo.join('BAD', 'ru')).thenThrow(
            const InterpreterException(InterpreterErrorKind.codeExpired));
        return bloc;
      },
      act: (b) async {
        b.add(const Started());
        await Future.delayed(_tinyDelay);
        b.add(const JoinPressed('BAD'));
        await Future.delayed(_tinyDelay);
        b.add(const RetryPressed());
      },
      skip: 3,
      expect: () => [
        isA<InterpreterFailure>(),
        isA<InterpreterChoosing>(),
      ],
    );
  });

  group('while active', () {
    blocTest<InterpreterBloc, InterpreterState>(
      'captions, speaking, agent presence and connection signals update Active',
      build: () {
        when(() => repo.catalog()).thenAnswer((_) async => _catalog());
        when(() => langStore.initial(any(), any()))
            .thenAnswer((_) async => 'ru');
        when(() => voice.getStatus())
            .thenAnswer((_) async => const OwnerVoiceStatus(enrolled: true));
        when(() => repo.create('ru')).thenAnswer((_) async => _hostedSession());
        when(() => repo.get('sess-1')).thenAnswer((_) async => _activeView());
        return bloc;
      },
      act: (b) async {
        b.add(const Started());
        await Future.delayed(_tinyDelay);
        b.add(const HostPressed());
        await Future.delayed(_tinyDelay);
        port.emit(const ParticipantJoined(_partnerIdentity));
        await Future.delayed(_tinyDelay);
        // Now Active. Agent joins:
        port.emit(const ParticipantJoined('voice-interpreter'));
        await Future.delayed(_tinyDelay);
        // Partner's translation caption:
        port.emit(DataReceived(
          topic: 'interp',
          bytes: _signalBytes({
            'type': 'caption',
            'role': 'translation',
            'speaker': _partnerUserId,
            'text': 'Hallo',
            'final': false,
          }),
          fromIdentity: 'voice-interpreter',
        ));
        await Future.delayed(_tinyDelay);
        // Partner starts speaking:
        port.emit(DataReceived(
          topic: 'interp',
          bytes: _signalBytes(
              {'type': 'speaking', 'speaker': _partnerUserId, 'on': true}),
          fromIdentity: 'voice-interpreter',
        ));
        await Future.delayed(_tinyDelay);
        // Translation socket hiccups:
        port.emit(DataReceived(
          topic: 'interp',
          bytes: _signalBytes({'type': 'status', 'state': 'reconnecting'}),
          fromIdentity: 'voice-interpreter',
        ));
        await Future.delayed(_tinyDelay);
        // Agent leaves (e.g. a deploy):
        port.emit(const ParticipantLeft('voice-interpreter'));
      },
      skip: 5, // Loading, Choosing, Working(creating), Hosting, Active(initial)
      expect: () => [
        isA<InterpreterActive>()
            .having((s) => s.agentPresent, 'agentPresent', true),
        isA<InterpreterActive>().having(
          (s) => s.captions.linesFor(CaptionRole.translation).single.text,
          'caption text',
          'Hallo',
        ),
        isA<InterpreterActive>()
            .having((s) => s.partnerSpeaking, 'partnerSpeaking', true),
        isA<InterpreterActive>().having((s) => s.connection, 'connection',
            InterpreterLinkState.reconnecting),
        isA<InterpreterActive>()
            .having((s) => s.agentPresent, 'agentPresent', false),
      ],
    );

    blocTest<InterpreterBloc, InterpreterState>(
      'MicToggled calls through to the room and updates micOn',
      build: () {
        when(() => repo.catalog()).thenAnswer((_) async => _catalog());
        when(() => langStore.initial(any(), any()))
            .thenAnswer((_) async => 'ru');
        when(() => voice.getStatus())
            .thenAnswer((_) async => const OwnerVoiceStatus(enrolled: true));
        when(() => repo.create('ru')).thenAnswer((_) async => _hostedSession());
        when(() => repo.get('sess-1')).thenAnswer((_) async => _activeView());
        return bloc;
      },
      act: (b) async {
        b.add(const Started());
        await Future.delayed(_tinyDelay);
        b.add(const HostPressed());
        await Future.delayed(_tinyDelay);
        port.emit(const ParticipantJoined(_partnerIdentity));
        await Future.delayed(_tinyDelay);
        b.add(const MicToggled(false));
        await Future.delayed(_tinyDelay);
        // Checked here, not in `verify` — see the host happy-path test for why.
        expect(port.calls.last, 'setMicrophone(false)');
      },
      skip: 4,
      expect: () => [
        isA<InterpreterActive>().having((s) => s.micOn, 'micOn', true),
        isA<InterpreterActive>().having((s) => s.micOn, 'micOn', false),
      ],
    );

    blocTest<InterpreterBloc, InterpreterState>(
      'the poll timer refreshes the host spentPlanck, then ends the call on ended status',
      build: () {
        when(() => repo.catalog()).thenAnswer((_) async => _catalog());
        when(() => langStore.initial(any(), any()))
            .thenAnswer((_) async => 'ru');
        when(() => voice.getStatus())
            .thenAnswer((_) async => const OwnerVoiceStatus(enrolled: true));
        when(() => repo.create('ru')).thenAnswer((_) async => _hostedSession());

        var call = 0;
        when(() => repo.get('sess-1')).thenAnswer((_) async {
          call++;
          if (call == 1) return _activeView();
          if (call == 2) return _activeView(spentPlanck: '1200');
          return _endedView(InterpreterEndReason.maxDuration,
              spentPlanck: '5000');
        });

        return makeBloc(pollEvery: const Duration(milliseconds: 15));
      },
      act: (b) async {
        b.add(const Started());
        await Future.delayed(_tinyDelay);
        b.add(const HostPressed());
        await Future.delayed(_tinyDelay);
        port.emit(const ParticipantJoined(_partnerIdentity));
      },
      wait: const Duration(milliseconds: 120),
      skip: 4,
      expect: () => [
        isA<InterpreterActive>()
            .having((s) => s.spentPlanck, 'spentPlanck', isNull),
        isA<InterpreterActive>()
            .having((s) => s.spentPlanck, 'spentPlanck', '1200'),
        isA<InterpreterEnded>()
            .having((s) => s.reason, 'reason', InterpreterEndReason.maxDuration)
            .having((s) => s.spentPlanck, 'spentPlanck', '5000')
            .having((s) => s.isHost, 'isHost', true),
      ],
    );
  });

  group('abandoned rooms are always torn down', () {
    blocTest<InterpreterBloc, InterpreterState>(
      'repo.get failing while hosting tears down the room before the failure, '
      'not only once BackToStart is pressed',
      build: () {
        when(() => repo.catalog()).thenAnswer((_) async => _catalog());
        when(() => langStore.initial(any(), any()))
            .thenAnswer((_) async => 'ru');
        when(() => voice.getStatus())
            .thenAnswer((_) async => const OwnerVoiceStatus(enrolled: true));
        when(() => repo.create('ru')).thenAnswer((_) async => _hostedSession());
        when(() => repo.get('sess-1')).thenThrow(
            const InterpreterException(InterpreterErrorKind.network));
        return bloc;
      },
      act: (b) async {
        var leaveCount = 0;
        when(() => device.leaveConversation())
            .thenAnswer((_) async => leaveCount++);

        b.add(const Started());
        await Future.delayed(_tinyDelay);
        b.add(const HostPressed());
        await Future.delayed(_tinyDelay);
        port.emit(const ParticipantJoined(_partnerIdentity));
        await Future.delayed(_tinyDelay);
        // Torn down already, right here — not waiting for BackToStart.
        expect(port.disconnected, isTrue);
        expect(leaveCount, 1);
        b.add(const BackToStart());
        await Future.delayed(_tinyDelay);
        // BackToStart's own teardown call was a no-op: still exactly once.
        expect(leaveCount, 1);
      },
      skip: 4, // Loading, Choosing, Working(creating), Hosting
      expect: () => [
        isA<InterpreterFailure>()
            .having((s) => s.kind, 'kind', InterpreterErrorKind.network),
        isA<InterpreterChoosing>(),
      ],
    );
  });

  group('ending the call', () {
    blocTest<InterpreterBloc, InterpreterState>(
      'EndPressed ends the call once, tears down the room and reports hangup',
      build: () {
        when(() => repo.catalog()).thenAnswer((_) async => _catalog());
        when(() => langStore.initial(any(), any()))
            .thenAnswer((_) async => 'ru');
        when(() => voice.getStatus())
            .thenAnswer((_) async => const OwnerVoiceStatus(enrolled: true));
        when(() => repo.create('ru')).thenAnswer((_) async => _hostedSession());
        when(() => repo.get('sess-1'))
            .thenAnswer((_) async => _activeView(spentPlanck: '900'));
        when(() => repo.end('sess-1')).thenAnswer((_) async {});
        return bloc;
      },
      act: (b) async {
        b.add(const Started());
        await Future.delayed(_tinyDelay);
        b.add(const HostPressed());
        await Future.delayed(_tinyDelay);
        port.emit(const ParticipantJoined(_partnerIdentity));
        await Future.delayed(_tinyDelay);
        b.add(const EndPressed());
      },
      skip: 4,
      expect: () => [
        isA<InterpreterActive>(),
        isA<InterpreterEnded>()
            .having((s) => s.reason, 'reason', InterpreterEndReason.hangup)
            .having((s) => s.spentPlanck, 'spentPlanck', '900')
            .having((s) => s.isHost, 'isHost', true),
      ],
      verify: (_) {
        verify(() => repo.end('sess-1')).called(1);
        verify(() => device.leaveConversation()).called(1);
        expect(port.disconnected, isTrue);
      },
    );

    blocTest<InterpreterBloc, InterpreterState>(
      'EndPressed failing on the server is logged and ends the call locally anyway',
      build: () {
        when(() => repo.catalog()).thenAnswer((_) async => _catalog());
        when(() => langStore.initial(any(), any()))
            .thenAnswer((_) async => 'ru');
        when(() => voice.getStatus())
            .thenAnswer((_) async => const OwnerVoiceStatus(enrolled: true));
        when(() => repo.create('ru')).thenAnswer((_) async => _hostedSession());
        when(() => repo.get('sess-1')).thenAnswer((_) async => _activeView());
        when(() => repo.end('sess-1')).thenThrow(Exception('offline'));
        return bloc;
      },
      act: (b) async {
        b.add(const Started());
        await Future.delayed(_tinyDelay);
        b.add(const HostPressed());
        await Future.delayed(_tinyDelay);
        port.emit(const ParticipantJoined(_partnerIdentity));
        await Future.delayed(_tinyDelay);
        b.add(const EndPressed());
      },
      skip: 4,
      expect: () => [
        isA<InterpreterActive>(),
        isA<InterpreterEnded>()
            .having((s) => s.reason, 'reason', InterpreterEndReason.hangup),
      ],
    );

    blocTest<InterpreterBloc, InterpreterState>(
      'the room closing on its own fetches the reason exactly once and ends the call',
      build: () {
        when(() => repo.catalog()).thenAnswer((_) async => _catalog());
        when(() => langStore.initial(any(), any()))
            .thenAnswer((_) async => 'ru');
        when(() => voice.getStatus())
            .thenAnswer((_) async => const OwnerVoiceStatus(enrolled: true));
        when(() => repo.create('ru')).thenAnswer((_) async => _hostedSession());

        var call = 0;
        when(() => repo.get('sess-1')).thenAnswer((_) async {
          call++;
          if (call == 1) return _activeView();
          return _endedView(InterpreterEndReason.partnerLeft,
              spentPlanck: '300');
        });
        return bloc;
      },
      act: (b) async {
        b.add(const Started());
        await Future.delayed(_tinyDelay);
        b.add(const HostPressed());
        await Future.delayed(_tinyDelay);
        port.emit(const ParticipantJoined(_partnerIdentity));
        await Future.delayed(_tinyDelay);
        port.emit(const Disconnected());
      },
      skip: 4,
      expect: () => [
        isA<InterpreterActive>(),
        isA<InterpreterEnded>()
            .having((s) => s.reason, 'reason', InterpreterEndReason.partnerLeft)
            .having((s) => s.spentPlanck, 'spentPlanck', '300'),
      ],
      verify: (_) {
        verify(() => repo.get('sess-1')).called(2);
      },
    );

    test(
        'closing the bloc tears down the room without ending the session on the server',
        () async {
      when(() => repo.catalog()).thenAnswer((_) async => _catalog());
      when(() => langStore.initial(any(), any())).thenAnswer((_) async => 'ru');
      when(() => voice.getStatus())
          .thenAnswer((_) async => const OwnerVoiceStatus(enrolled: true));
      when(() => repo.create('ru')).thenAnswer((_) async => _hostedSession());
      when(() => repo.get('sess-1')).thenAnswer((_) async => _activeView());

      bloc.add(const Started());
      await Future.delayed(_tinyDelay);
      bloc.add(const HostPressed());
      await Future.delayed(_tinyDelay);
      port.emit(const ParticipantJoined(_partnerIdentity));
      await Future.delayed(_tinyDelay);
      expect(bloc.state, isA<InterpreterActive>());

      await bloc.close();

      verify(() => device.leaveConversation()).called(1);
      verifyNever(() => repo.end(any()));
      expect(port.disconnected, isTrue);
    });
  });

  group('closing the bloc mid-flight', () {
    test(
        'closing while repo.create is still resolving never enters the room, '
        'and ends the session once create finally answers', () async {
      when(() => repo.catalog()).thenAnswer((_) async => _catalog());
      when(() => langStore.initial(any(), any())).thenAnswer((_) async => 'ru');
      when(() => voice.getStatus())
          .thenAnswer((_) async => const OwnerVoiceStatus(enrolled: true));

      final createGate = Completer<HostedSession>();
      when(() => repo.create('ru')).thenAnswer((_) => createGate.future);
      when(() => repo.end('sess-1')).thenAnswer((_) async {});

      bloc.add(const Started());
      await Future.delayed(_tinyDelay);
      bloc.add(const HostPressed());
      await Future.delayed(_tinyDelay); // now awaiting repo.create

      // Deliberately not awaited yet — awaiting here would deadlock: close()
      // itself waits for this very handler to return.
      final closeFuture = bloc.close();
      await Future.delayed(_tinyDelay);

      createGate.complete(_hostedSession());
      // `closeFuture` itself resolves as soon as close() cancels the
      // in-flight emitter — it does not wait for the handler's `async`
      // function to actually finish running, so that finish has to be
      // pumped for separately.
      await closeFuture;
      await Future.delayed(_tinyDelay);

      expect(port.calls, isEmpty);
      verify(() => repo.end('sess-1')).called(1);
    });

    test(
        'closing while repo.join is still resolving never enters the room, '
        'and ends the session once join finally answers', () async {
      when(() => repo.catalog()).thenAnswer((_) async => _catalog());
      when(() => langStore.initial(any(), any())).thenAnswer((_) async => 'ru');
      when(() => voice.getStatus())
          .thenAnswer((_) async => const OwnerVoiceStatus(enrolled: true));

      final joinGate = Completer<JoinedSession>();
      when(() => repo.join('CODE1', 'ru')).thenAnswer((_) => joinGate.future);
      when(() => repo.end('sess-2')).thenAnswer((_) async {});

      bloc.add(const Started());
      await Future.delayed(_tinyDelay);
      bloc.add(const JoinPressed('CODE1'));
      await Future.delayed(_tinyDelay); // now awaiting repo.join

      final closeFuture = bloc.close();
      await Future.delayed(_tinyDelay);

      joinGate.complete(_joinedSession());
      await closeFuture;
      await Future.delayed(_tinyDelay);

      expect(port.calls, isEmpty);
      verify(() => repo.end('sess-2')).called(1);
    });

    test(
        'closing while the room itself is still connecting tears it down '
        'and ends the session once connect finally answers', () async {
      final connectGate = Completer<void>();
      port = FakeRoomPort(identity: _hostIdentity, connectGate: connectGate);

      when(() => repo.catalog()).thenAnswer((_) async => _catalog());
      when(() => langStore.initial(any(), any())).thenAnswer((_) async => 'ru');
      when(() => voice.getStatus())
          .thenAnswer((_) async => const OwnerVoiceStatus(enrolled: true));
      when(() => repo.create('ru')).thenAnswer((_) async => _hostedSession());
      when(() => repo.end('sess-1')).thenAnswer((_) async {});

      bloc.add(const Started());
      await Future.delayed(_tinyDelay);
      bloc.add(const HostPressed());
      await Future.delayed(_tinyDelay); // connect() called, stuck on the gate

      expect(port.calls, ['connect(wss://media/livekit/, tok-host)']);

      final closeFuture = bloc.close();
      await Future.delayed(_tinyDelay);

      connectGate.complete();
      await closeFuture;
      await Future.delayed(_tinyDelay);

      verify(() => device.leaveConversation()).called(1);
      verify(() => repo.end('sess-1')).called(1);
      expect(port.disconnected, isTrue);
    });
  });
}

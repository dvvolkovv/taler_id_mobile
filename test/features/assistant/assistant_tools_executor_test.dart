import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:taler_id_mobile/core/api/dio_client.dart';
import 'package:taler_id_mobile/core/di/service_locator.dart';
import 'package:taler_id_mobile/core/services/messenger_cache_service.dart';
import 'package:taler_id_mobile/core/services/pending_message_service.dart';
import 'package:taler_id_mobile/features/assistant/domain/assistant_action.dart';
import 'package:taler_id_mobile/features/assistant/tools/assistant_tools_executor.dart';
import 'package:taler_id_mobile/features/messenger/data/services/pending_mesh_send_queue.dart';
import 'package:taler_id_mobile/features/messenger/domain/entities/message_entity.dart';
import 'package:taler_id_mobile/features/messenger/domain/repositories/i_messenger_repository.dart';
import 'package:taler_id_mobile/features/messenger/presentation/bloc/messenger_bloc.dart';
import 'package:taler_id_mobile/features/messenger/presentation/bloc/messenger_event.dart';

class MockDioClient extends Mock implements DioClient {}

class _MockMessengerRepository extends Mock implements IMessengerRepository {}

class _MockCacheService extends Mock implements MessengerCacheService {}

class _MockPendingMessageService extends Mock implements PendingMessageService {}

/// Records every event added to any Bloc while installed as `Bloc.observer`
/// — lets the pin/unpin tests below assert "the executor dispatched X to the
/// bloc" directly, independent of what the bloc's own handler does with it
/// afterwards. Mirrors `_RecordingBlocObserver` in
/// test/features/messenger/pinned_messages_screen_test.dart.
class _RecordingBlocObserver extends BlocObserver {
  final List<Object?> events = [];

  @override
  void onEvent(Bloc<dynamic, dynamic> bloc, Object? event) {
    super.onEvent(bloc, event);
    events.add(event);
  }
}

MessageEntity _pinFixture(String id, {DateTime? pinnedAt}) => MessageEntity(
      id: id,
      conversationId: 'conv-1',
      senderId: 'user-1',
      senderName: 'Alice',
      content: 'hello there',
      sentAt: DateTime(2026, 8, 8),
      pinnedAt: pinnedAt,
    );

void main() {
  test('unknown tool returns readable message', () async {
    final ex = AssistantToolsExecutor();
    expect(await ex.execute('no_such_tool', {}), contains('Unknown tool'));
  });

  test('session-bound tool without hooks refuses politely', () async {
    final ex = AssistantToolsExecutor();
    final res = await ex.execute('end_session', {});
    expect(res.toLowerCase(), contains('voice session'));
  });

  group('web_search action bubble', () {
    late MockDioClient client;

    setUp(() {
      client = MockDioClient();
      sl.registerLazySingleton<DioClient>(() => client);
    });

    tearDown(() async {
      await sl.reset();
    });

    void stubWebSearch(Map<String, dynamic> response) {
      when(() => client.post<Map<String, dynamic>>(
            '/assistant/web-search',
            data: any(named: 'data'),
            fromJson: any(named: 'fromJson'),
          )).thenAnswer((_) async => response);
    }

    test('emits web_link action from first citation', () async {
      stubWebSearch({
        'answer': 'Вот билеты',
        'citations': ['https://tickets.example/x', 'https://b.example'],
      });
      final actions = <AssistantAction>[];
      final ex = AssistantToolsExecutor(onAction: actions.add);

      final res = await ex.execute('web_search', {'query': 'билеты в Вену'});

      expect(res, contains('Вот билеты'));
      expect(actions, hasLength(1));
      expect(actions.single.type, AssistantActionType.webLink);
      expect(actions.single.entityId, 'https://tickets.example/x');
      expect(actions.single.title, contains('билеты в Вену'));
    });

    test('no citations → no action emitted', () async {
      stubWebSearch({'answer': 'Ответ без источников'});
      final actions = <AssistantAction>[];
      final ex = AssistantToolsExecutor(onAction: actions.add);

      await ex.execute('web_search', {'query': 'что-то'});

      expect(actions, isEmpty);
    });

    test('empty citations list → no action emitted', () async {
      stubWebSearch({'answer': 'Ответ', 'citations': <String>[]});
      final actions = <AssistantAction>[];
      final ex = AssistantToolsExecutor(onAction: actions.add);

      await ex.execute('web_search', {'query': 'что-то'});

      expect(actions, isEmpty);
    });
  });

  // Task 15 — pin_message/unpin_message/list_pinned. MessengerBloc is
  // constructed for real (not mocked) so the mutations genuinely flow
  // through PinMessage/UnpinMessage's real handlers, backed by a mocked
  // IMessengerRepository — same shape as
  // test/features/messenger/pins_bloc_test.dart. A real MessengerBloc calls
  // WidgetsBinding.instance.addObserver(this) in its constructor, hence
  // ensureInitialized() below.
  group('pin_message / unpin_message / list_pinned', () {
    late _MockMessengerRepository repo;
    late MessengerBloc bloc;
    late _RecordingBlocObserver observer;

    setUpAll(() {
      TestWidgetsFlutterBinding.ensureInitialized();
    });

    setUp(() async {
      // Must be awaited: GetIt 8's reset() is async, and its continuation
      // otherwise drains during this test's own later awaits (the reconcile
      // loop's Future.delayed calls below), wiping the registrations made
      // right after this call.
      await sl.reset();
      sl.registerSingleton<MessengerCacheService>(_MockCacheService());
      sl.registerSingleton<PendingMessageService>(_MockPendingMessageService());
      sl.registerSingleton<PendingMeshSendQueue>(PendingMeshSendQueue());

      // MessengerBloc (via BlocBase) captures Bloc.observer into a `final`
      // field at construction time — it must be assigned before the bloc is
      // built, or this recorder never sees its events.
      observer = _RecordingBlocObserver();
      Bloc.observer = observer;

      repo = _MockMessengerRepository();
      sl.registerSingleton<IMessengerRepository>(repo);
      bloc = MessengerBloc(repo: repo);
      sl.registerSingleton<MessengerBloc>(bloc);
    });

    tearDown(() async {
      await bloc.close();
      await sl.reset();
    });

    test(
        'pin_message dispatches PinMessage to the bloc (not a direct repository call) '
        'and reports the confirmed pinned state and count', () async {
      when(() => repo.pinMessage('conv-1', 'msg-1')).thenAnswer((_) async => {
            'pinnedAt': '2026-08-08T10:00:00.000Z',
            'pinnedCount': 1,
            'alreadyPinned': false,
            'systemMessageId': 'sys-1',
          });
      // Reconcile read: reflects the message as pinned straight away so the
      // executor's retry loop settles on its first attempt.
      when(() => repo.getPinnedMessages('conv-1')).thenAnswer(
          (_) async => [_pinFixture('msg-1', pinnedAt: DateTime(2026, 8, 8, 10))]);

      final ex = AssistantToolsExecutor();
      final res = await ex.execute(
          'pin_message', {'conversationId': 'conv-1', 'messageId': 'msg-1'});

      expect(observer.events, hasLength(1));
      expect(observer.events.single, isA<PinMessage>());
      expect((observer.events.single as PinMessage).conversationId, 'conv-1');
      expect((observer.events.single as PinMessage).messageId, 'msg-1');
      // Exactly one call — from the bloc's own _onPinMessage handler. If the
      // executor also called the repository directly this would be 2.
      verify(() => repo.pinMessage('conv-1', 'msg-1')).called(1);

      expect(res, contains('"ok":true'));
      expect(res, contains('"pinned":true'));
      expect(res, contains('"pinnedCount":1'));
    });

    test(
        'unpin_message dispatches UnpinMessage to the bloc and reports pinned:false '
        'with the resulting count', () async {
      when(() => repo.unpinMessage('conv-1', 'msg-1'))
          .thenAnswer((_) async => {'pinnedCount': 0, 'wasPinned': true});
      when(() => repo.getPinnedMessages('conv-1')).thenAnswer((_) async => []);

      final ex = AssistantToolsExecutor();
      final res = await ex.execute(
          'unpin_message', {'conversationId': 'conv-1', 'messageId': 'msg-1'});

      expect(observer.events, hasLength(1));
      expect(observer.events.single, isA<UnpinMessage>());
      verify(() => repo.unpinMessage('conv-1', 'msg-1')).called(1);

      expect(res, contains('"ok":true'));
      expect(res, contains('"pinned":false'));
      expect(res, contains('"pinnedCount":0'));
    });

    test(
        'list_pinned reads the repository directly (no bloc dispatch) and returns '
        'a compact id/text/sender shape, not an entity dump', () async {
      when(() => repo.getPinnedMessages('conv-1')).thenAnswer(
          (_) async => [_pinFixture('msg-1', pinnedAt: DateTime(2026, 8, 8, 9))]);

      final ex = AssistantToolsExecutor();
      final res =
          await ex.execute('list_pinned', {'conversationId': 'conv-1'});

      // Pure read — nothing dispatched to any bloc.
      expect(observer.events, isEmpty);

      expect(res, contains('"messageId":"msg-1"'));
      expect(res, contains('"text":"hello there"'));
      expect(res, contains('"senderName":"Alice"'));
      // Compact, not an entity dump: internal MessageEntity fields must not
      // leak into what the model sees.
      expect(res, isNot(contains('sentAt')));
      expect(res, isNot(contains('isDelivered')));
      expect(res, isNot(contains('pinnedById')));
    });
  });
}

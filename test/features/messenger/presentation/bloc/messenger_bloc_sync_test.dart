import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'package:taler_id_mobile/core/di/service_locator.dart';
import 'package:taler_id_mobile/core/services/messenger_cache_service.dart';
import 'package:taler_id_mobile/core/services/pending_message_service.dart';
import 'package:taler_id_mobile/core/storage/sync_cursor_storage.dart';
import 'package:taler_id_mobile/features/messenger/data/services/pending_mesh_send_queue.dart';
import 'package:taler_id_mobile/features/messenger/domain/entities/message_entity.dart';
import 'package:taler_id_mobile/features/messenger/domain/entities/sync_result.dart';
import 'package:taler_id_mobile/features/messenger/domain/repositories/i_messenger_repository.dart';
import 'package:taler_id_mobile/features/messenger/presentation/bloc/messenger_bloc.dart';
import 'package:taler_id_mobile/features/messenger/presentation/bloc/messenger_event.dart';

class _StubRepo extends Mock implements IMessengerRepository {}

class _FakeCache implements MessengerCacheService {
  @override
  List<Map<String, dynamic>>? getMessages(String conversationId) => null;
  @override
  List<Map<String, dynamic>> getMeshMessagesFor(String conversationId) =>
      const [];
  @override
  Future<void> appendMessage(String conversationId,
      Map<String, dynamic> message) async {}
  @override
  dynamic noSuchMethod(Invocation i) => null;
}

class _FakePending implements PendingMessageService {
  @override
  dynamic noSuchMethod(Invocation i) => null;
}

class _FakePathProvider extends PathProviderPlatform
    with MockPlatformInterfaceMixin {
  final String dir;
  _FakePathProvider(this.dir);

  @override
  Future<String?> getApplicationDocumentsPath() async => dir;

  @override
  Future<String?> getApplicationSupportPath() async => dir;

  @override
  Future<String?> getTemporaryPath() async => dir;
}

Stream<T> _empty<T>() => const Stream.empty();

MessageEntity _msg(String id, String conv, DateTime sentAt) => MessageEntity(
      id: id,
      conversationId: conv,
      senderId: 'other-user',
      content: 'hi $id',
      sentAt: sentAt,
    );

void _stubAllStreams(_StubRepo repo) {
  when(() => repo.messageStream).thenAnswer((_) => _empty());
  when(() => repo.callInviteStream).thenAnswer((_) => _empty());
  when(() => repo.callAnsweredStream).thenAnswer((_) => const Stream<String>.empty());
  when(() => repo.callEndedStream).thenAnswer((_) => const Stream<String>.empty());
  when(() => repo.messageUpdatedStream).thenAnswer((_) => _empty());
  when(() => repo.messageDeletedStream).thenAnswer((_) => _empty());
  when(() => repo.messagesReadStream).thenAnswer((_) => _empty());
  when(() => repo.groupUpdatedStream).thenAnswer((_) => _empty());
  when(() => repo.groupMemberAddedStream).thenAnswer((_) => _empty());
  when(() => repo.groupMemberRemovedStream).thenAnswer((_) => _empty());
  when(() => repo.groupRoleChangedStream).thenAnswer((_) => _empty());
  when(() => repo.groupCreatedStream).thenAnswer((_) => _empty());
  when(() => repo.groupDeletedStream).thenAnswer((_) => _empty());
  when(() => repo.groupCallStartedStream).thenAnswer((_) => _empty());
  when(() => repo.groupCallEndedStream).thenAnswer((_) => _empty());
  when(() => repo.typingStream).thenAnswer((_) => _empty());
  when(() => repo.contactRequestStream).thenAnswer((_) => _empty());
  when(() => repo.contactAcceptedStream).thenAnswer((_) => _empty());
  when(() => repo.reactionUpdatedStream).thenAnswer((_) => _empty());
  when(() => repo.socketErrorStream).thenAnswer((_) => _empty());
  when(() => repo.analystChunkStream).thenAnswer((_) => _empty());
  when(() => repo.analystSeamStream).thenAnswer((_) => _empty());
  when(() => repo.meshMessageStream).thenAnswer((_) => _empty());
  when(() => repo.meshOutboundStream).thenAnswer((_) => _empty());
  when(() => repo.messageAckedStream).thenAnswer((_) => _empty());
}

void main() {
  late Directory tempDir;
  late _StubRepo repo;

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    if (!sl.isRegistered<MessengerCacheService>()) {
      sl.registerSingleton<MessengerCacheService>(_FakeCache());
    }
    if (!sl.isRegistered<PendingMessageService>()) {
      sl.registerSingleton<PendingMessageService>(_FakePending());
    }
    if (!sl.isRegistered<PendingMeshSendQueue>()) {
      sl.registerSingleton<PendingMeshSendQueue>(PendingMeshSendQueue());
    }
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('bloc_sync_test_');
    PathProviderPlatform.instance = _FakePathProvider(tempDir.path);
    Hive.init(tempDir.path);
    await Hive.openBox<String>(SyncCursorStorage.boxName);

    if (sl.isRegistered<SyncCursorStorage>()) {
      sl.unregister<SyncCursorStorage>();
    }
    sl.registerSingleton<SyncCursorStorage>(SyncCursorStorage());

    repo = _StubRepo();
    _stubAllStreams(repo);
  });

  tearDown(() async {
    await Hive.close();
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  test(
      'initialization (no stored cursor) calls sync() without cursor and stores nextCursor',
      () async {
    when(() => repo.sync(limit: any(named: 'limit'))).thenAnswer(
      (_) async => const SyncResult(
        messages: [],
        nextCursor: '2026-05-13T10:00:00.000Z|init',
        hasMore: false,
      ),
    );

    final bloc = MessengerBloc(repo: repo);
    bloc.add(const SyncMessagesRequested());
    await Future<void>.delayed(const Duration(milliseconds: 200));

    verify(() => repo.sync(limit: 200)).called(1);
    expect(await sl<SyncCursorStorage>().read(), '2026-05-13T10:00:00.000Z|init');
    await bloc.close();
  });

  test(
      'delta paginates until hasMore=false, dispatching MessageReceived per row',
      () async {
    await sl<SyncCursorStorage>().write('2026-05-13T09:00:00.000Z|start');

    final p1 = SyncResult(
      messages: [
        _msg('m1', 'conv-1', DateTime.parse('2026-05-13T10:01:00Z')),
        _msg('m2', 'conv-1', DateTime.parse('2026-05-13T10:02:00Z')),
      ],
      nextCursor: '2026-05-13T10:02:00.000Z|m2',
      hasMore: true,
    );
    final p2 = SyncResult(
      messages: [_msg('m3', 'conv-1', DateTime.parse('2026-05-13T10:03:00Z'))],
      nextCursor: '2026-05-13T10:03:00.000Z|m3',
      hasMore: false,
    );

    when(() => repo.sync(
          cursor: any(named: 'cursor'),
          limit: any(named: 'limit'),
        )).thenAnswer((inv) async {
      final cur = inv.namedArguments[#cursor] as String?;
      return cur == '2026-05-13T09:00:00.000Z|start' ? p1 : p2;
    });

    final bloc = MessengerBloc(repo: repo);
    bloc.add(const SyncMessagesRequested());
    await Future<void>.delayed(const Duration(milliseconds: 300));

    expect(
      bloc.state.messages['conv-1']?.map((m) => m.id).toList(),
      ['m1', 'm2', 'm3'],
    );
    expect(
        await sl<SyncCursorStorage>().read(), '2026-05-13T10:03:00.000Z|m3');
    await bloc.close();
  });

  test('overlapping live MessageReceived + sync delivery dedups by msg.id',
      () async {
    await sl<SyncCursorStorage>().write('2026-05-13T09:00:00.000Z|start');

    final shared = _msg('m1', 'conv-1', DateTime.parse('2026-05-13T10:01:00Z'));
    when(() => repo.sync(
          cursor: any(named: 'cursor'),
          limit: any(named: 'limit'),
        )).thenAnswer((_) async => SyncResult(
          messages: [shared],
          nextCursor: '2026-05-13T10:01:00.000Z|m1',
          hasMore: false,
        ));

    final bloc = MessengerBloc(repo: repo);
    bloc.add(MessageReceived(shared));
    bloc.add(const SyncMessagesRequested());
    await Future<void>.delayed(const Duration(milliseconds: 200));

    expect(bloc.state.messages['conv-1']?.length, 1);
    await bloc.close();
  });

  test('AppLifecycleState.resumed dispatches SyncMessagesRequested', () async {
    when(() => repo.sync(limit: any(named: 'limit'))).thenAnswer((_) async =>
        const SyncResult(messages: [], nextCursor: '2026-05-13T11:00:00.000Z|x', hasMore: false));

    final bloc = MessengerBloc(repo: repo);
    bloc.didChangeAppLifecycleState(AppLifecycleState.resumed);
    await Future<void>.delayed(const Duration(milliseconds: 100));

    verify(() => repo.sync(limit: 200)).called(1);
    await bloc.close();
  });
}

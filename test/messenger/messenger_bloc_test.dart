import 'dart:async';
import 'dart:convert';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:taler_id_mobile/features/messenger/domain/entities/conversation_entity.dart';
import 'package:taler_id_mobile/features/messenger/domain/entities/message_entity.dart';
import 'package:taler_id_mobile/features/messenger/domain/entities/user_search_entity.dart';
import 'package:taler_id_mobile/features/messenger/domain/entities/analyst_events.dart';
import 'package:taler_id_mobile/features/messenger/domain/repositories/i_messenger_repository.dart'
    show IMessengerRepository, MeshInboundMessage, MeshOutboundMessage;
import 'package:taler_id_mobile/features/messenger/presentation/bloc/messenger_bloc.dart';
import 'package:taler_id_mobile/features/messenger/presentation/bloc/messenger_event.dart';
import 'package:taler_id_mobile/features/messenger/presentation/bloc/messenger_state.dart';
import 'package:taler_id_mobile/core/services/messenger_cache_service.dart';
import 'package:taler_id_mobile/core/services/pending_message_service.dart';
import 'package:taler_id_mobile/core/di/service_locator.dart';
import 'package:taler_id_mobile/features/messenger/data/datasources/messenger_remote_datasource.dart';
import 'package:taler_id_mobile/features/messenger/data/services/pending_mesh_send_queue.dart';

class _FakeMessengerRemoteDataSource implements MessengerRemoteDataSource {
  final _reconnectCtrl = StreamController<void>.broadcast();
  final _disconnectCtrl = StreamController<String>.broadcast();
  @override
  Stream<void> get reconnectStream => _reconnectCtrl.stream;
  @override
  Stream<String> get disconnectStream => _disconnectCtrl.stream;

  void emitReconnect() => _reconnectCtrl.add(null);
  void emitDisconnect([String reason = 'transport close']) =>
      _disconnectCtrl.add(reason);

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockMessengerRepository extends Mock implements IMessengerRepository {}

/// Fake without Hive — acts as a no-op pending-message queue for tests.
class FakePendingMessageService extends PendingMessageService {
  @override
  Future<void> init() async {}
  @override
  Future<void> save(String tempId, Map<String, dynamic> message) async {}
  @override
  Future<void> remove(String tempId) async {}
  @override
  List<Map<String, dynamic>> getAll() => const [];
}

/// In-memory pending queue with real save/remove semantics — for tests that
/// exercise the merge logic in OpenConversation / SendMessage.
class _PopulatedPendingMessageService extends PendingMessageService {
  final Map<String, Map<String, dynamic>> _items = {};

  @override
  Future<void> init() async {}

  @override
  Future<void> save(String tempId, Map<String, dynamic> message) async {
    _items[tempId] = Map<String, dynamic>.from(jsonDecode(jsonEncode(message)) as Map);
  }

  @override
  Future<void> remove(String tempId) async {
    _items.remove(tempId);
  }

  @override
  List<Map<String, dynamic>> getAll() {
    final keys = _items.keys.toList()..sort();
    return [
      for (final k in keys) {...?_items[k], 'id': k},
    ];
  }
}

/// Pending service whose save() blocks on a completer — lets us verify that
/// SendMessage awaits persistence before emitting on the socket.
class _BlockingPendingMessageService extends _PopulatedPendingMessageService {
  Completer<void> blockSave = Completer<void>();
  bool saveCompletedBeforeSend = false;
  bool saveResolved = false;

  @override
  Future<void> save(String tempId, Map<String, dynamic> message) async {
    await blockSave.future;
    saveResolved = true;
    await super.save(tempId, message);
  }
}

/// Cache fake that captures appendMessage calls — used to assert that temp
/// messages get persisted on send.
class _CapturingCacheService extends MessengerCacheService {
  final List<(String, Map<String, dynamic>)> appended = [];

  @override
  List<Map<String, dynamic>>? getConversations() => null;
  @override
  Future<void> saveConversations(List<Map<String, dynamic>> conversations) async {}
  @override
  List<Map<String, dynamic>>? getMessages(String conversationId) => null;
  @override
  Future<void> saveMessages(String conversationId, List<Map<String, dynamic>> messages) async {}
  @override
  Future<void> appendMessage(String conversationId, Map<String, dynamic> message) async {
    appended.add((conversationId, message));
  }
  @override
  Future<void> updateMessage(String conversationId, String messageId, Map<String, dynamic> updates) async {}
  @override
  Future<void> removeMessage(String conversationId, String messageId) async {}
  @override
  Future<void> clearAll() async {}
}

/// Fake без Hive — возвращает пустые данные, игнорирует записи
class FakeMessengerCacheService extends MessengerCacheService {
  /// Test-only mesh history (per conversationId). Tests that need to
  /// exercise the merge-time dedup populate this directly.
  final Map<String, List<Map<String, dynamic>>> meshHistory = {};

  @override
  List<Map<String, dynamic>>? getConversations() => null;

  @override
  Future<void> saveConversations(List<Map<String, dynamic>> conversations) async {}

  @override
  List<Map<String, dynamic>>? getMessages(String conversationId) => null;

  @override
  Future<void> saveMessages(String conversationId, List<Map<String, dynamic>> messages) async {}

  @override
  Future<void> appendMessage(String conversationId, Map<String, dynamic> message) async {}

  @override
  Future<void> updateMessage(String conversationId, String messageId, Map<String, dynamic> updates) async {}

  @override
  Future<void> removeMessage(String conversationId, String messageId) async {}

  @override
  Future<void> appendMeshMessage(Map<String, dynamic> entry) async {
    final convId = entry['conversationId'] as String?;
    if (convId == null) return;
    final list = meshHistory.putIfAbsent(convId, () => []);
    if (list.any((m) => m['id'] == entry['id'])) return;
    list.add(entry);
  }

  @override
  List<Map<String, dynamic>> getMeshMessagesFor(String conversationId) {
    return List<Map<String, dynamic>>.from(meshHistory[conversationId] ?? const []);
  }

  @override
  Future<void> clearAll() async {}
}

// Fixtures
final _conv1 = ConversationEntity(
  id: 'conv-1',
  participantIds: ['user-1', 'user-2'],
  otherUserName: 'Anna Smith',
  otherUserId: 'user-2',
  lastMessageContent: 'Hello',
  lastMessageAt: DateTime(2024, 1, 15, 10, 0),
);

final _conv2 = ConversationEntity(
  id: 'conv-2',
  participantIds: ['user-1', 'user-3'],
  otherUserName: 'Boris Jones',
  otherUserId: 'user-3',
  unreadCount: 3,
);

final _message1 = MessageEntity(
  id: 'msg-1',
  conversationId: 'conv-1',
  senderId: 'user-2',
  senderName: 'Anna',
  content: 'Hello!',
  sentAt: DateTime(2024, 1, 15, 10, 0),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockMessengerRepository repo;

  // Helper: create a closed (never-emitting) broadcast stream
  Stream<T> emptyStream<T>() => StreamController<T>.broadcast().stream;

  void stubAllStreams() {
    when(() => repo.messageStream).thenAnswer((_) => emptyStream<MessageEntity>());
    when(() => repo.callInviteStream).thenAnswer((_) => emptyStream<Map<String, dynamic>>());
    when(() => repo.callAnsweredStream).thenAnswer((_) => const Stream<String>.empty());
    when(() => repo.callEndedStream).thenAnswer((_) => const Stream<String>.empty());
    when(() => repo.messageUpdatedStream).thenAnswer((_) => emptyStream<Map<String, dynamic>>());
    when(() => repo.messageDeletedStream).thenAnswer((_) => emptyStream<Map<String, dynamic>>());
    when(() => repo.messageAckedStream).thenAnswer((_) => emptyStream<Map<String, dynamic>>());
    when(() => repo.messagesReadStream).thenAnswer((_) => emptyStream<Map<String, dynamic>>());
    when(() => repo.groupUpdatedStream).thenAnswer((_) => emptyStream<Map<String, dynamic>>());
    when(() => repo.groupMemberAddedStream).thenAnswer((_) => emptyStream<Map<String, dynamic>>());
    when(() => repo.groupMemberRemovedStream).thenAnswer((_) => emptyStream<Map<String, dynamic>>());
    when(() => repo.groupRoleChangedStream).thenAnswer((_) => emptyStream<Map<String, dynamic>>());
    when(() => repo.groupCreatedStream).thenAnswer((_) => emptyStream<Map<String, dynamic>>());
    when(() => repo.groupDeletedStream).thenAnswer((_) => emptyStream<Map<String, dynamic>>());
    when(() => repo.groupCallStartedStream).thenAnswer((_) => emptyStream<Map<String, dynamic>>());
    when(() => repo.groupCallEndedStream).thenAnswer((_) => emptyStream<Map<String, dynamic>>());
    // Pin streams — stub required after messagePinnedStream/messageUnpinnedStream/
    // pinsClearedStream were added to IMessengerRepository.
    when(() => repo.messagePinnedStream).thenAnswer((_) => emptyStream<Map<String, dynamic>>());
    when(() => repo.conversationStateStream).thenAnswer((_) => emptyStream<Map<String, dynamic>>());
    when(() => repo.messageUnpinnedStream).thenAnswer((_) => emptyStream<Map<String, dynamic>>());
    when(() => repo.pinsClearedStream).thenAnswer((_) => emptyStream<Map<String, dynamic>>());
    when(() => repo.typingStream).thenAnswer((_) => emptyStream<Map<String, dynamic>>());
    when(() => repo.contactRequestStream).thenAnswer((_) => emptyStream<Map<String, dynamic>>());
    when(() => repo.contactAcceptedStream).thenAnswer((_) => emptyStream<Map<String, dynamic>>());
    when(() => repo.reactionUpdatedStream).thenAnswer((_) => emptyStream<Map<String, dynamic>>());
    when(() => repo.socketErrorStream).thenAnswer((_) => emptyStream<String>());
    when(() => repo.analystChunkStream).thenAnswer((_) => emptyStream<AnalystChunk>());
    when(() => repo.analystSeamStream).thenAnswer((_) => emptyStream<AnalystSeam>());
    // Phase 1e: mesh inbound stream — stub required after meshMessageStream
    // was added to IMessengerRepository.
    when(() => repo.meshMessageStream).thenAnswer((_) => emptyStream<MeshInboundMessage>());
    // Phase 1h: mesh outbound stream — stub required after meshOutboundStream
    // was added to IMessengerRepository.
    when(() => repo.meshOutboundStream).thenAnswer((_) => emptyStream<MeshOutboundMessage>());
  }

  MessengerBloc buildBloc() => MessengerBloc(repo: repo);

  setUp(() {
    repo = MockMessengerRepository();
    stubAllStreams();

    // Default stubs for methods triggered by connect/message
    when(() => repo.getConversations()).thenAnswer((_) async => []);
    when(() => repo.getContactRequests()).thenAnswer((_) async => []);
    when(() => repo.connect(any())).thenAnswer((_) async {});
    when(() => repo.dispose()).thenReturn(null);

    // Register fake services in GetIt (no Hive dependency)
    if (sl.isRegistered<MessengerCacheService>()) {
      sl.unregister<MessengerCacheService>();
    }
    sl.registerSingleton<MessengerCacheService>(FakeMessengerCacheService());

    if (sl.isRegistered<PendingMessageService>()) {
      sl.unregister<PendingMessageService>();
    }
    sl.registerSingleton<PendingMessageService>(FakePendingMessageService());

    if (sl.isRegistered<MessengerRemoteDataSource>()) {
      sl.unregister<MessengerRemoteDataSource>();
    }
    sl.registerSingleton<MessengerRemoteDataSource>(_FakeMessengerRemoteDataSource());

    if (sl.isRegistered<PendingMeshSendQueue>()) {
      sl.unregister<PendingMeshSendQueue>();
    }
    sl.registerSingleton<PendingMeshSendQueue>(PendingMeshSendQueue());
  });

  // ── Connect ───────────────────────────────────────────────────────────────

  group('ConnectMessenger', () {
    blocTest<MessengerBloc, MessengerState>(
      'sets isConnected=true after connect',
      build: buildBloc,
      act: (b) async {
        b.add(const ConnectMessenger('token-abc', userId: 'user-1'));
        await Future.delayed(const Duration(milliseconds: 50));
      },
      verify: (b) => expect(b.state.isConnected, isTrue),
    );
  });

  // ── Load conversations ────────────────────────────────────────────────────

  group('LoadConversations', () {
    blocTest<MessengerBloc, MessengerState>(
      'loads and returns conversations list',
      build: () {
        when(() => repo.getConversations()).thenAnswer((_) async => [_conv1, _conv2]);
        return buildBloc();
      },
      act: (b) => b.add(LoadConversations()),
      expect: () => [
        isA<MessengerState>().having((s) => s.isLoading, 'isLoading', true),
        isA<MessengerState>()
            .having((s) => s.isLoading, 'isLoading', false)
            .having((s) => s.conversations.length, 'count', 2)
            .having((s) => s.conversations.first.id, 'first id', 'conv-1'),
      ],
    );

    blocTest<MessengerBloc, MessengerState>(
      'returns empty list when no conversations',
      build: () {
        when(() => repo.getConversations()).thenAnswer((_) async => []);
        return buildBloc();
      },
      act: (b) => b.add(LoadConversations()),
      expect: () => [
        isA<MessengerState>().having((s) => s.isLoading, 'isLoading', true),
        isA<MessengerState>()
            .having((s) => s.conversations, 'conversations', isEmpty),
      ],
    );

    blocTest<MessengerBloc, MessengerState>(
      'sets error on repository failure',
      build: () {
        when(() => repo.getConversations()).thenThrow(Exception('Server error'));
        return buildBloc();
      },
      act: (b) => b.add(LoadConversations()),
      expect: () => [
        isA<MessengerState>().having((s) => s.isLoading, 'isLoading', true),
        isA<MessengerState>()
            .having((s) => s.isLoading, 'isLoading', false)
            .having((s) => s.error, 'error', isNotNull),
      ],
    );
  });

  // ── Open conversation / load messages ─────────────────────────────────────

  group('OpenConversation', () {
    blocTest<MessengerBloc, MessengerState>(
      'loads messages for conversation',
      build: () {
        when(() => repo.getMessages('conv-1', cursor: null)).thenAnswer((_) async => {
              'messages': [_message1.toJson()],
              'nextCursor': null,
            });
        when(() => repo.joinConversation('conv-1')).thenReturn(null);
        return buildBloc();
      },
      act: (b) => b.add(const OpenConversation('conv-1')),
      expect: () => [
        isA<MessengerState>().having((s) => s.isLoading, 'isLoading', true),
        isA<MessengerState>()
            .having((s) => s.isLoading, 'isLoading', false)
            .having((s) => s.messages['conv-1']?.length, 'message count', 1),
      ],
    );

    blocTest<MessengerBloc, MessengerState>(
      'still shows pending messages when API call fails (backend down)',
      build: () {
        // Pre-populate pending queue with a message the user typed during outage.
        final pending = _PopulatedPendingMessageService();
        pending.save('temp_111', {
          'conversationId': 'conv-1',
          'content': 'Привет',
          'sentAt': '2024-01-15T10:00:00.000Z',
          'senderId': 'user-1',
        });
        sl.unregister<PendingMessageService>();
        sl.registerSingleton<PendingMessageService>(pending);

        when(() => repo.joinConversation('conv-1')).thenReturn(null);
        when(() => repo.getMessages('conv-1',
                cursor: any(named: 'cursor'), topicId: any(named: 'topicId')))
            .thenThrow(Exception('Network error'));
        return buildBloc();
      },
      act: (b) => b.add(const OpenConversation('conv-1')),
      verify: (b) {
        final msgs = b.state.messages['conv-1'] ?? const [];
        expect(
          msgs.any((m) => m.id == 'temp_111' && m.content == 'Привет'),
          isTrue,
          reason:
              'Pending message must remain visible (with clock icon) when the '
              'server is unreachable, otherwise the user thinks it disappeared.',
        );
        expect(b.state.isLoading, isFalse);
      },
    );

    blocTest<MessengerBloc, MessengerState>(
      'merge dedups mesh entry that has matching server counterpart (regression)',
      build: () {
        // The bloc's live-event dedup in _onMeshMessageReceived already
        // skips the bubble at runtime, but the adapter writes mesh
        // entries to Hive BEFORE the bloc's dedup decision. On chat
        // reload, _loadMeshHistory pulls the stale mesh entry out and
        // _mergeSortedById would otherwise emit two bubbles (different
        // ids: server uuid vs mesh clientId). Phase 2 dedup hygiene at
        // merge time keeps the UI consistent.
        final fakeCache = FakeMessengerCacheService();
        fakeCache.meshHistory['conv-1'] = [
          {
            'id': 'mesh-client-id-aaa',
            'conversationId': 'conv-1',
            'senderId': 'user-2',
            'content': 'Привет',
            'transport': 'mesh',
            'sentAt': '2024-01-15T10:00:00.000Z',
          },
        ];
        sl.unregister<MessengerCacheService>();
        sl.registerSingleton<MessengerCacheService>(fakeCache);

        when(() => repo.getMessages('conv-1', cursor: null)).thenAnswer(
          (_) async => {
            'messages': [
              MessageEntity(
                id: 'server-uuid-xyz',
                conversationId: 'conv-1',
                senderId: 'user-2',
                content: 'Привет',
                sentAt: DateTime.parse('2024-01-15T10:00:01.000Z'),
              ).toJson(),
            ],
            'nextCursor': null,
          },
        );
        when(() => repo.joinConversation('conv-1')).thenReturn(null);
        return buildBloc();
      },
      act: (b) => b.add(const OpenConversation('conv-1')),
      verify: (b) {
        final msgs = b.state.messages['conv-1'] ?? const [];
        expect(msgs, hasLength(1),
            reason: 'mesh entry must be deduped against server counterpart at merge time');
        expect(msgs.single.id, 'server-uuid-xyz',
            reason: 'server entry survives, mesh entry filtered');
      },
    );
  });

  // ── Send message ──────────────────────────────────────────────────────────

  group('SendMessage', () {
    blocTest<MessengerBloc, MessengerState>(
      'awaits _pending.save before emitting message on socket',
      build: () {
        final pending = _BlockingPendingMessageService();
        sl.unregister<PendingMessageService>();
        sl.registerSingleton<PendingMessageService>(pending);

        when(() => repo.sendMessage(
              any(),
              any(),
              fileUrl: any(named: 'fileUrl'),
              fileName: any(named: 'fileName'),
              fileSize: any(named: 'fileSize'),
              fileType: any(named: 'fileType'),
              s3Key: any(named: 's3Key'),
              thumbnailSmallUrl: any(named: 'thumbnailSmallUrl'),
              thumbnailMediumUrl: any(named: 'thumbnailMediumUrl'),
              thumbnailLargeUrl: any(named: 'thumbnailLargeUrl'),
              fileRecordId: any(named: 'fileRecordId'),
              topicId: any(named: 'topicId'),
              clientTempId: any(named: 'clientTempId'),
            )).thenReturn(null);
        return buildBloc();
      },
      act: (b) async {
        b.add(const SendMessage('conv-1', 'Привет'));
        // Give bloc a chance to enter the handler. Pending.save() is blocked,
        // so sendMessage must NOT have run yet.
        await Future.delayed(const Duration(milliseconds: 30));
        verifyNever(() => repo.sendMessage(
              any(),
              any(),
              fileUrl: any(named: 'fileUrl'),
              fileName: any(named: 'fileName'),
              fileSize: any(named: 'fileSize'),
              fileType: any(named: 'fileType'),
              s3Key: any(named: 's3Key'),
              thumbnailSmallUrl: any(named: 'thumbnailSmallUrl'),
              thumbnailMediumUrl: any(named: 'thumbnailMediumUrl'),
              thumbnailLargeUrl: any(named: 'thumbnailLargeUrl'),
              fileRecordId: any(named: 'fileRecordId'),
              topicId: any(named: 'topicId'),
              clientTempId: any(named: 'clientTempId'),
            ));
        // Now release pending.save() and let sendMessage proceed.
        (sl<PendingMessageService>() as _BlockingPendingMessageService)
            .blockSave
            .complete();
        await Future.delayed(const Duration(milliseconds: 30));
      },
      verify: (b) {
        verify(() => repo.sendMessage(
              'conv-1',
              'Привет',
              fileUrl: any(named: 'fileUrl'),
              fileName: any(named: 'fileName'),
              fileSize: any(named: 'fileSize'),
              fileType: any(named: 'fileType'),
              s3Key: any(named: 's3Key'),
              thumbnailSmallUrl: any(named: 'thumbnailSmallUrl'),
              thumbnailMediumUrl: any(named: 'thumbnailMediumUrl'),
              thumbnailLargeUrl: any(named: 'thumbnailLargeUrl'),
              fileRecordId: any(named: 'fileRecordId'),
              topicId: any(named: 'topicId'),
              clientTempId: any(named: 'clientTempId'),
            )).called(1);
      },
    );

    blocTest<MessengerBloc, MessengerState>(
      'persists temp message to cache so it survives app kill',
      build: () {
        final cache = _CapturingCacheService();
        sl.unregister<MessengerCacheService>();
        sl.registerSingleton<MessengerCacheService>(cache);

        when(() => repo.sendMessage(
              any(),
              any(),
              fileUrl: any(named: 'fileUrl'),
              fileName: any(named: 'fileName'),
              fileSize: any(named: 'fileSize'),
              fileType: any(named: 'fileType'),
              s3Key: any(named: 's3Key'),
              thumbnailSmallUrl: any(named: 'thumbnailSmallUrl'),
              thumbnailMediumUrl: any(named: 'thumbnailMediumUrl'),
              thumbnailLargeUrl: any(named: 'thumbnailLargeUrl'),
              fileRecordId: any(named: 'fileRecordId'),
              topicId: any(named: 'topicId'),
              clientTempId: any(named: 'clientTempId'),
            )).thenReturn(null);
        return buildBloc();
      },
      act: (b) async {
        b.add(const SendMessage('conv-1', 'Привет'));
        await Future.delayed(const Duration(milliseconds: 30));
      },
      verify: (b) {
        final cache = sl<MessengerCacheService>() as _CapturingCacheService;
        expect(cache.appended, isNotEmpty,
            reason: 'temp message must be appended to cache so it survives app restart');
        expect(cache.appended.first.$1, equals('conv-1'));
        expect(cache.appended.first.$2['content'], equals('Привет'));
        expect(cache.appended.first.$2['id'] as String, startsWith('temp_'));
      },
    );
  });

  // ── Reconnect storm recovery ──────────────────────────────────────────────

  group('Pending preservation on ack (regression)', () {
    test(
        'message_acked alone must NOT drop pending entry — only echo removes it',
        () async {
      final pending = _PopulatedPendingMessageService();
      sl.unregister<PendingMessageService>();
      sl.registerSingleton<PendingMessageService>(pending);

      final ackCtrl = StreamController<Map<String, dynamic>>.broadcast();
      when(() => repo.messageAckedStream).thenAnswer((_) => ackCtrl.stream);
      when(() => repo.joinConversation(any())).thenReturn(null);
      when(() => repo.sendMessage(
            any(),
            any(),
            fileUrl: any(named: 'fileUrl'),
            fileName: any(named: 'fileName'),
            fileSize: any(named: 'fileSize'),
            fileType: any(named: 'fileType'),
            s3Key: any(named: 's3Key'),
            thumbnailSmallUrl: any(named: 'thumbnailSmallUrl'),
            thumbnailMediumUrl: any(named: 'thumbnailMediumUrl'),
            thumbnailLargeUrl: any(named: 'thumbnailLargeUrl'),
            fileRecordId: any(named: 'fileRecordId'),
            topicId: any(named: 'topicId'),
            clientTempId: any(named: 'clientTempId'),
          )).thenReturn(null);

      final bloc = buildBloc();
      bloc.add(const ConnectMessenger('token', userId: 'user-1'));
      await Future<void>.delayed(const Duration(milliseconds: 30));
      bloc.add(const SendMessage('conv-1', 'Привет'));
      await Future<void>.delayed(const Duration(milliseconds: 30));

      expect(pending.getAll(), hasLength(1),
          reason: 'pending saved on send');
      final tempId = pending.getAll().first['id'] as String;

      ackCtrl.add({'clientTempId': tempId});
      await Future<void>.delayed(const Duration(milliseconds: 30));

      // Pre-fix bug: ack handler removed pending immediately, causing the
      // bubble to vanish on next chat reload if the echo (`new_message`)
      // never arrived. Post-fix: ack only clears in-flight tracking; the
      // persistent entry stays until the echo confirms the message was
      // stored server-side.
      expect(pending.getAll(), hasLength(1),
          reason: 'message_acked must keep pending until echo arrives');

      await bloc.close();
      await ackCtrl.close();
    });
  });

  group('Reconnect recovery', () {
    blocTest<MessengerBloc, MessengerState>(
      'clears in-flight set on disconnect so pending messages re-emit on next reconnect',
      build: () {
        final pending = _PopulatedPendingMessageService();
        sl.unregister<PendingMessageService>();
        sl.registerSingleton<PendingMessageService>(pending);

        when(() => repo.joinConversation(any())).thenReturn(null);
        when(() => repo.sendMessage(
              any(),
              any(),
              fileUrl: any(named: 'fileUrl'),
              fileName: any(named: 'fileName'),
              fileSize: any(named: 'fileSize'),
              fileType: any(named: 'fileType'),
              s3Key: any(named: 's3Key'),
              thumbnailSmallUrl: any(named: 'thumbnailSmallUrl'),
              thumbnailMediumUrl: any(named: 'thumbnailMediumUrl'),
              thumbnailLargeUrl: any(named: 'thumbnailLargeUrl'),
              fileRecordId: any(named: 'fileRecordId'),
              topicId: any(named: 'topicId'),
              clientTempId: any(named: 'clientTempId'),
            )).thenReturn(null);
        return buildBloc();
      },
      act: (b) async {
        b.add(const ConnectMessenger('token', userId: 'user-1'));
        await Future.delayed(const Duration(milliseconds: 30));
        b.add(const SendMessage('conv-1', 'Привет'));
        await Future.delayed(const Duration(milliseconds: 30));

        // Initial send: 1 call to repo.sendMessage.
        verify(() => repo.sendMessage(
              any(),
              any(),
              fileUrl: any(named: 'fileUrl'),
              fileName: any(named: 'fileName'),
              fileSize: any(named: 'fileSize'),
              fileType: any(named: 'fileType'),
              s3Key: any(named: 's3Key'),
              thumbnailSmallUrl: any(named: 'thumbnailSmallUrl'),
              thumbnailMediumUrl: any(named: 'thumbnailMediumUrl'),
              thumbnailLargeUrl: any(named: 'thumbnailLargeUrl'),
              fileRecordId: any(named: 'fileRecordId'),
              topicId: any(named: 'topicId'),
              clientTempId: any(named: 'clientTempId'),
            )).called(1);

        // Simulate the outage: socket dropped, then re-established.
        final ds = sl<MessengerRemoteDataSource>()
            as _FakeMessengerRemoteDataSource;
        ds.emitDisconnect();
        await Future.delayed(const Duration(milliseconds: 30));
        ds.emitReconnect();
        await Future.delayed(const Duration(milliseconds: 30));
      },
      verify: (b) {
        // After reconnect, _resendPending must have re-emitted the message
        // because disconnect cleared the in-flight set.
        verify(() => repo.sendMessage(
              'conv-1',
              'Привет',
              fileUrl: any(named: 'fileUrl'),
              fileName: any(named: 'fileName'),
              fileSize: any(named: 'fileSize'),
              fileType: any(named: 'fileType'),
              s3Key: any(named: 's3Key'),
              thumbnailSmallUrl: any(named: 'thumbnailSmallUrl'),
              thumbnailMediumUrl: any(named: 'thumbnailMediumUrl'),
              thumbnailLargeUrl: any(named: 'thumbnailLargeUrl'),
              fileRecordId: any(named: 'fileRecordId'),
              topicId: any(named: 'topicId'),
              clientTempId: any(named: 'clientTempId'),
            )).called(greaterThanOrEqualTo(1));
      },
    );

    // 2026-07-24 — offline send stuck with clock icon forever.
    // Sending while the socket is already disconnected: the repository drops
    // the emit (isSocketConnected gate) but the tempId stays in the in-flight
    // set. The network then returns and the socket goes straight to 'connect'
    // WITHOUT an intervening 'disconnect' event — so the in-flight set was
    // never cleared and _resendPending skipped the message on every reconnect
    // (and even across app restarts). Regression locks down: a fresh connect
    // must reset in-flight tracking and re-emit pending messages.
    blocTest<MessengerBloc, MessengerState>(
      're-emits pending on reconnect even when no disconnect event preceded it',
      build: () {
        final pending = _PopulatedPendingMessageService();
        sl.unregister<PendingMessageService>();
        sl.registerSingleton<PendingMessageService>(pending);

        when(() => repo.joinConversation(any())).thenReturn(null);
        when(() => repo.sendMessage(
              any(),
              any(),
              fileUrl: any(named: 'fileUrl'),
              fileName: any(named: 'fileName'),
              fileSize: any(named: 'fileSize'),
              fileType: any(named: 'fileType'),
              s3Key: any(named: 's3Key'),
              thumbnailSmallUrl: any(named: 'thumbnailSmallUrl'),
              thumbnailMediumUrl: any(named: 'thumbnailMediumUrl'),
              thumbnailLargeUrl: any(named: 'thumbnailLargeUrl'),
              fileRecordId: any(named: 'fileRecordId'),
              topicId: any(named: 'topicId'),
              clientTempId: any(named: 'clientTempId'),
            )).thenReturn(null);
        return buildBloc();
      },
      act: (b) async {
        b.add(const ConnectMessenger('token', userId: 'user-1'));
        await Future.delayed(const Duration(milliseconds: 30));
        // Send while "offline": repo mock records the call, but in production
        // the repository drops it when the socket is disconnected. The tempId
        // is now marked in-flight either way.
        b.add(const SendMessage('conv-1', 'offline draft'));
        await Future.delayed(const Duration(milliseconds: 30));

        // Network returns: socket connects with NO disconnect event first
        // (it was already down before the send).
        final ds = sl<MessengerRemoteDataSource>()
            as _FakeMessengerRemoteDataSource;
        ds.emitReconnect();
        await Future.delayed(const Duration(milliseconds: 30));
      },
      verify: (b) {
        // Initial emit + reconnect re-emit = 2 calls. Pre-fix the second one
        // was skipped ("already in flight") and the message hung forever.
        verify(() => repo.sendMessage(
              'conv-1',
              'offline draft',
              fileUrl: any(named: 'fileUrl'),
              fileName: any(named: 'fileName'),
              fileSize: any(named: 'fileSize'),
              fileType: any(named: 'fileType'),
              s3Key: any(named: 's3Key'),
              thumbnailSmallUrl: any(named: 'thumbnailSmallUrl'),
              thumbnailMediumUrl: any(named: 'thumbnailMediumUrl'),
              thumbnailLargeUrl: any(named: 'thumbnailLargeUrl'),
              fileRecordId: any(named: 'fileRecordId'),
              topicId: any(named: 'topicId'),
              clientTempId: any(named: 'clientTempId'),
            )).called(2);
      },
    );

    // 2026-06-15 — phantom resend on cross-session pending leak.
    // Pending Hive box persisted through logout; on the next account's first
    // connect, _resendPending flushed the previous user's drafts under the
    // new JWT. Regression locks down: drafts whose senderId does not match
    // the connecting user MUST be evicted, not transmitted.
    test('cross-session pending entries are evicted, never resent', () async {
      final pending = _PopulatedPendingMessageService();
      sl.unregister<PendingMessageService>();
      sl.registerSingleton<PendingMessageService>(pending);

      // Seed pending with a draft authored by a previous account.
      await pending.save('temp_old_user_draft', {
        'conversationId': 'conv-1',
        'content': 'leftover from previous account',
        'sentAt': DateTime.now().toIso8601String(),
        'senderId': 'previous-user',
      });

      when(() => repo.joinConversation(any())).thenReturn(null);
      when(() => repo.sendMessage(
            any(),
            any(),
            fileUrl: any(named: 'fileUrl'),
            fileName: any(named: 'fileName'),
            fileSize: any(named: 'fileSize'),
            fileType: any(named: 'fileType'),
            s3Key: any(named: 's3Key'),
            thumbnailSmallUrl: any(named: 'thumbnailSmallUrl'),
            thumbnailMediumUrl: any(named: 'thumbnailMediumUrl'),
            thumbnailLargeUrl: any(named: 'thumbnailLargeUrl'),
            fileRecordId: any(named: 'fileRecordId'),
            topicId: any(named: 'topicId'),
            clientTempId: any(named: 'clientTempId'),
          )).thenReturn(null);

      final bloc = buildBloc();
      bloc.add(const ConnectMessenger('token', userId: 'new-user'));
      await Future<void>.delayed(const Duration(milliseconds: 50));

      verifyNever(() => repo.sendMessage(
            any(),
            any(),
            fileUrl: any(named: 'fileUrl'),
            fileName: any(named: 'fileName'),
            fileSize: any(named: 'fileSize'),
            fileType: any(named: 'fileType'),
            s3Key: any(named: 's3Key'),
            thumbnailSmallUrl: any(named: 'thumbnailSmallUrl'),
            thumbnailMediumUrl: any(named: 'thumbnailMediumUrl'),
            thumbnailLargeUrl: any(named: 'thumbnailLargeUrl'),
            fileRecordId: any(named: 'fileRecordId'),
            topicId: any(named: 'topicId'),
            clientTempId: any(named: 'clientTempId'),
          ));
      expect(pending.getAll(), isEmpty,
          reason: 'stale draft for previous-user must be evicted from Hive');

      await bloc.close();
    });

    // 2026-06-18 — phantom-resend recurrence on pre-1.0.86 legacy entries.
    // Before 1.0.86 the pending Hive box wrote entries WITHOUT senderId or
    // sentAt. The 1.0.86 guards treated NULL fields as "unknown → keep",
    // so legacy entries lived forever and re-fired on every reconnect for
    // months ("Не выдерживает твоего напора" → trientes/@NARAYANA chats).
    // STRICT policy: any entry missing senderId OR sentAt is evicted, not
    // sent.
    test(
        'legacy entry (no senderId, no sentAt) is evicted, never resent — 2026-06-18 phantom-resend recurrence',
        () async {
      final pending = _PopulatedPendingMessageService();
      sl.unregister<PendingMessageService>();
      sl.registerSingleton<PendingMessageService>(pending);

      // Pre-1.0.86-style entry: no senderId, no sentAt — both NULL on read.
      await pending.save('temp_pre_1086_legacy', {
        'conversationId': 'conv-1',
        'content': 'Не выдерживает твоего напора',
      });
      // Sanity: 1 entry seeded.
      expect(pending.getAll(), hasLength(1));

      when(() => repo.joinConversation(any())).thenReturn(null);
      when(() => repo.sendMessage(
            any(),
            any(),
            fileUrl: any(named: 'fileUrl'),
            fileName: any(named: 'fileName'),
            fileSize: any(named: 'fileSize'),
            fileType: any(named: 'fileType'),
            s3Key: any(named: 's3Key'),
            thumbnailSmallUrl: any(named: 'thumbnailSmallUrl'),
            thumbnailMediumUrl: any(named: 'thumbnailMediumUrl'),
            thumbnailLargeUrl: any(named: 'thumbnailLargeUrl'),
            fileRecordId: any(named: 'fileRecordId'),
            topicId: any(named: 'topicId'),
            clientTempId: any(named: 'clientTempId'),
          )).thenReturn(null);

      final bloc = buildBloc();
      bloc.add(const ConnectMessenger('token', userId: 'current-user'));
      await Future<void>.delayed(const Duration(milliseconds: 50));

      verifyNever(() => repo.sendMessage(
            any(),
            any(),
            fileUrl: any(named: 'fileUrl'),
            fileName: any(named: 'fileName'),
            fileSize: any(named: 'fileSize'),
            fileType: any(named: 'fileType'),
            s3Key: any(named: 's3Key'),
            thumbnailSmallUrl: any(named: 'thumbnailSmallUrl'),
            thumbnailMediumUrl: any(named: 'thumbnailMediumUrl'),
            thumbnailLargeUrl: any(named: 'thumbnailLargeUrl'),
            fileRecordId: any(named: 'fileRecordId'),
            topicId: any(named: 'topicId'),
            clientTempId: any(named: 'clientTempId'),
          ));
      expect(pending.getAll(), isEmpty,
          reason:
              'legacy entry without metadata MUST be evicted, never resent — otherwise the message phantom-fires forever');

      await bloc.close();
    });

    // 2026-06-15 — pending drained reliably by clientTempId, not content.
    // The content+senderId heuristic in _onMessageReceived silently fails for
    // file messages / edited bodies. message_acked carries (clientTempId →
    // messageId); the bloc keeps the mapping so the next new_message echo
    // drops pending by messageId even when the content match misses.
    test('new_message drops pending by messageId when content mismatches',
        () async {
      final pending = _PopulatedPendingMessageService();
      sl.unregister<PendingMessageService>();
      sl.registerSingleton<PendingMessageService>(pending);

      final ackCtrl = StreamController<Map<String, dynamic>>.broadcast();
      final msgCtrl = StreamController<MessageEntity>.broadcast();
      when(() => repo.messageAckedStream).thenAnswer((_) => ackCtrl.stream);
      when(() => repo.messageStream).thenAnswer((_) => msgCtrl.stream);
      when(() => repo.joinConversation(any())).thenReturn(null);
      when(() => repo.sendMessage(
            any(),
            any(),
            fileUrl: any(named: 'fileUrl'),
            fileName: any(named: 'fileName'),
            fileSize: any(named: 'fileSize'),
            fileType: any(named: 'fileType'),
            s3Key: any(named: 's3Key'),
            thumbnailSmallUrl: any(named: 'thumbnailSmallUrl'),
            thumbnailMediumUrl: any(named: 'thumbnailMediumUrl'),
            thumbnailLargeUrl: any(named: 'thumbnailLargeUrl'),
            fileRecordId: any(named: 'fileRecordId'),
            topicId: any(named: 'topicId'),
            clientTempId: any(named: 'clientTempId'),
          )).thenReturn(null);

      final bloc = buildBloc();
      bloc.add(const ConnectMessenger('token', userId: 'user-1'));
      await Future<void>.delayed(const Duration(milliseconds: 30));
      bloc.add(const SendMessage('conv-1', 'original body'));
      await Future<void>.delayed(const Duration(milliseconds: 30));

      final tempId = pending.getAll().first['id'] as String;

      // Server acks with the canonical messageId mapping.
      ackCtrl.add({'clientTempId': tempId, 'messageId': 'srv-msg-1'});
      await Future<void>.delayed(const Duration(milliseconds: 30));

      // Server echo arrives with normalized/edited content — the legacy
      // senderId+content heuristic would have missed.
      msgCtrl.add(MessageEntity(
        id: 'srv-msg-1',
        conversationId: 'conv-1',
        senderId: 'user-1',
        content: 'normalized body',
        sentAt: DateTime.now(),
      ));
      await Future<void>.delayed(const Duration(milliseconds: 30));

      expect(pending.getAll(), isEmpty,
          reason:
              'pending must be cleared by messageId mapping even when content mismatches');

      await bloc.close();
      await ackCtrl.close();
      await msgCtrl.close();
    });
  });

  // ── Search users ──────────────────────────────────────────────────────────

  group('SearchUsers', () {
    blocTest<MessengerBloc, MessengerState>(
      'returns search results',
      build: () {
        when(() => repo.searchUsers('anna')).thenAnswer((_) async => [
              const UserSearchEntity(id: 'user-2', email: 'anna@test.com', username: 'anna_s'),
            ]);
        return buildBloc();
      },
      act: (b) => b.add(const SearchUsers('anna')),
      expect: () => [
        isA<MessengerState>().having((s) => s.isLoading, 'isLoading', true),
        isA<MessengerState>()
            .having((s) => s.searchResults.length, 'results count', 1)
            .having((s) => s.searchResults.first.username, 'username', 'anna_s'),
      ],
    );

    blocTest<MessengerBloc, MessengerState>(
      'returns empty results for no match',
      build: () {
        when(() => repo.searchUsers('zzz')).thenAnswer((_) async => []);
        return buildBloc();
      },
      act: (b) => b.add(const SearchUsers('zzz')),
      expect: () => [
        isA<MessengerState>().having((s) => s.isLoading, 'isLoading', true),
        isA<MessengerState>().having((s) => s.searchResults, 'results', isEmpty),
      ],
    );

    blocTest<MessengerBloc, MessengerState>(
      'short query (< 2 chars) clears results without loading',
      build: buildBloc,
      act: (b) => b.add(const SearchUsers('a')),
      expect: () => [
        isA<MessengerState>()
            .having((s) => s.isLoading, 'isLoading', false)
            .having((s) => s.searchResults, 'results', isEmpty),
      ],
    );
  });

  // ── Incoming message via stream ───────────────────────────────────────────

  group('MessageReceived', () {
    blocTest<MessengerBloc, MessengerState>(
      'adds incoming message to conversation messages',
      build: buildBloc,
      act: (b) => b.add(MessageReceived(_message1)),
      // bloc also triggers LoadConversations → [Loading, Loaded], so skip first 2 states
      // and verify the last state has the message
      verify: (b) {
        final msgs = b.state.messages['conv-1'];
        expect(msgs, isNotNull);
        expect(msgs!.any((m) => m.id == 'msg-1'), isTrue);
      },
    );

    blocTest<MessengerBloc, MessengerState>(
      'ignores duplicate messages',
      build: buildBloc,
      act: (b) async {
        b.add(MessageReceived(_message1));
        await Future.delayed(const Duration(milliseconds: 10));
        b.add(MessageReceived(_message1)); // same id
        await Future.delayed(const Duration(milliseconds: 10));
      },
      verify: (b) {
        final msgs = b.state.messages['conv-1'] ?? [];
        final count = msgs.where((m) => m.id == 'msg-1').length;
        expect(count, equals(1), reason: 'Duplicate message should not be added twice');
      },
    );

    blocTest<MessengerBloc, MessengerState>(
      'echo drains matching mesh-pending entry',
      setUp: () {
        sl<PendingMeshSendQueue>().enqueue(
          clientId: 'temp_mesh-1',
          conversationId: 'conv-1',
          content: 'mesh hi',
          sentAt: DateTime(2024, 1, 15, 10, 0),
        );
      },
      build: buildBloc,
      seed: () => MessengerState(messages: {
        'conv-1': [
          MessageEntity(
            id: 'temp_mesh-1',
            conversationId: 'conv-1',
            senderId: 'user-1',
            senderName: 'Me',
            content: 'mesh hi',
            sentAt: DateTime(2024, 1, 15, 10, 0),
          ),
        ],
      }),
      act: (b) => b.add(MessageReceived(MessageEntity(
        id: 'srv-mesh-1',
        conversationId: 'conv-1',
        senderId: 'user-1',
        senderName: 'Me',
        content: 'mesh hi',
        sentAt: DateTime(2024, 1, 15, 10, 0),
      ))),
      verify: (_) {
        expect(sl<PendingMeshSendQueue>().pendingCount, 0,
            reason: 'echo with matching senderId+content should drain mesh-pending entry');
      },
    );
  });

  // ── Call invite ───────────────────────────────────────────────────────────

  group('CallInviteReceived', () {
    blocTest<MessengerBloc, MessengerState>(
      'stores pending call invite',
      build: buildBloc,
      act: (b) => b.add(CallInviteReceived({'roomName': 'room-abc', 'callerId': 'user-2'})),
      expect: () => [
        isA<MessengerState>()
            .having((s) => s.pendingCallInvite?['roomName'], 'roomName', 'room-abc'),
      ],
    );

    blocTest<MessengerBloc, MessengerState>(
      'clears call invite on dismiss',
      build: buildBloc,
      act: (b) async {
        b.add(CallInviteReceived({'roomName': 'room-abc'}));
        await Future.delayed(const Duration(milliseconds: 5));
        b.add(DismissCallInvite());
      },
      expect: () => [
        isA<MessengerState>().having((s) => s.pendingCallInvite, 'invite present', isNotNull),
        isA<MessengerState>().having((s) => s.pendingCallInvite, 'invite cleared', isNull),
      ],
    );
  });
}

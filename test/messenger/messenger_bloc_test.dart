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
  late MockMessengerRepository repo;

  // Helper: create a closed (never-emitting) broadcast stream
  Stream<T> emptyStream<T>() => StreamController<T>.broadcast().stream;

  void stubAllStreams() {
    when(() => repo.messageStream).thenAnswer((_) => emptyStream<MessageEntity>());
    when(() => repo.callInviteStream).thenAnswer((_) => emptyStream<Map<String, dynamic>>());
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

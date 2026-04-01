import 'dart:async';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:taler_id_mobile/features/messenger/domain/entities/conversation_entity.dart';
import 'package:taler_id_mobile/features/messenger/domain/entities/message_entity.dart';
import 'package:taler_id_mobile/features/messenger/domain/entities/user_search_entity.dart';
import 'package:taler_id_mobile/features/messenger/domain/repositories/i_messenger_repository.dart';
import 'package:taler_id_mobile/features/messenger/presentation/bloc/messenger_bloc.dart';
import 'package:taler_id_mobile/features/messenger/presentation/bloc/messenger_event.dart';
import 'package:taler_id_mobile/features/messenger/presentation/bloc/messenger_state.dart';
import 'package:taler_id_mobile/core/services/messenger_cache_service.dart';
import 'package:taler_id_mobile/core/di/service_locator.dart';

class MockMessengerRepository extends Mock implements IMessengerRepository {}

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

    // Register fake cache service in GetIt (no Hive dependency)
    if (sl.isRegistered<MessengerCacheService>()) {
      sl.unregister<MessengerCacheService>();
    }
    sl.registerSingleton<MessengerCacheService>(FakeMessengerCacheService());
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

import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:taler_id_mobile/core/services/messenger_cache_service.dart';
import 'package:taler_id_mobile/core/services/pending_message_service.dart';
import 'package:taler_id_mobile/core/di/service_locator.dart';
import 'package:taler_id_mobile/features/messenger/data/services/pending_mesh_send_queue.dart';
import 'package:taler_id_mobile/features/messenger/domain/entities/message_entity.dart';
import 'package:taler_id_mobile/features/messenger/domain/repositories/i_messenger_repository.dart';
import 'package:taler_id_mobile/features/messenger/presentation/bloc/messenger_bloc.dart';
import 'package:taler_id_mobile/features/messenger/presentation/bloc/messenger_event.dart';
import 'package:taler_id_mobile/features/messenger/presentation/bloc/messenger_state.dart';

class _StubRepo extends Mock implements IMessengerRepository {}

/// A minimal fake that satisfies the appendMessage(Future<void>) contract
/// without requiring a full mocktail stub per test.
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

Stream<T> _empty<T>() => const Stream.empty();

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    if (!sl.isRegistered<MessengerCacheService>()) {
      sl.registerSingleton<MessengerCacheService>(_FakeCache());
    }
    if (!sl.isRegistered<PendingMessageService>()) {
      sl.registerSingleton<PendingMessageService>(_FakePending());
    }
    if (sl.isRegistered<PendingMeshSendQueue>()) {
      sl.unregister<PendingMeshSendQueue>();
    }
    sl.registerSingleton<PendingMeshSendQueue>(PendingMeshSendQueue());
  });

  late _StubRepo repo;
  setUp(() {
    repo = _StubRepo();
    when(() => repo.messageStream).thenAnswer((_) => _empty());
    when(() => repo.callInviteStream).thenAnswer((_) => _empty());
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
  });

  group('Phase 2 mesh-vs-server dedup heuristic', () {
    blocTest<MessengerBloc, MessengerState>(
      'server MessageReceived dropped when mesh entry with same senderId+content exists in 10s window',
      build: () => MessengerBloc(repo: repo),
      seed: () => MessengerState(messages: {
        'conv-1': [
          MessageEntity(
            id: 'mesh-id-1',
            conversationId: 'conv-1',
            senderId: 'alice',
            content: 'hello',
            sentAt: DateTime.parse('2026-04-26T12:00:00.000Z'),
            transport: 'mesh',
          ),
        ],
      }),
      act: (bloc) => bloc.add(MessageReceived(MessageEntity(
        id: 'server-id-1',
        conversationId: 'conv-1',
        senderId: 'alice',
        content: 'hello',
        sentAt: DateTime.parse('2026-04-26T12:00:02.000Z'),  // 2s later
      ))),
      verify: (bloc) {
        final list = bloc.state.messages['conv-1']!;
        expect(list, hasLength(1));
        expect(list.first.id, 'mesh-id-1');
        expect(list.first.transport, 'mesh');
      },
    );

    blocTest<MessengerBloc, MessengerState>(
      'mesh MeshMessageReceived dropped when server entry with same senderId+content exists in 10s window',
      build: () => MessengerBloc(repo: repo),
      seed: () => MessengerState(messages: {
        'conv-1': [
          MessageEntity(
            id: 'server-id-1',
            conversationId: 'conv-1',
            senderId: 'alice',
            content: 'hi via server first',
            sentAt: DateTime.parse('2026-04-26T12:00:00.000Z'),
            transport: null,  // server-delivered
          ),
        ],
      }),
      act: (bloc) => bloc.add(MeshMessageReceived(
        conversationId: 'conv-1',
        contactUserId: 'alice',
        text: 'hi via server first',
        receivedAt: DateTime.parse('2026-04-26T12:00:01.000Z'),
      )),
      verify: (bloc) {
        final list = bloc.state.messages['conv-1']!;
        expect(list, hasLength(1));
        expect(list.first.id, 'server-id-1');
        expect(list.first.transport, isNull);
      },
    );

    blocTest<MessengerBloc, MessengerState>(
      '10s window respected — newer message outside window is NOT deduped',
      build: () => MessengerBloc(repo: repo),
      seed: () => MessengerState(messages: {
        'conv-1': [
          MessageEntity(
            id: 'mesh-old',
            conversationId: 'conv-1',
            senderId: 'alice',
            content: 'hello',
            sentAt: DateTime.parse('2026-04-26T12:00:00.000Z'),
            transport: 'mesh',
          ),
        ],
      }),
      act: (bloc) => bloc.add(MessageReceived(MessageEntity(
        id: 'server-late',
        conversationId: 'conv-1',
        senderId: 'alice',
        content: 'hello',
        sentAt: DateTime.parse('2026-04-26T12:00:30.000Z'),  // 30s later
      ))),
      verify: (bloc) {
        final list = bloc.state.messages['conv-1']!;
        expect(list, hasLength(2),
            reason: 'outside 10s window — treated as a separate message');
      },
    );
  });
}

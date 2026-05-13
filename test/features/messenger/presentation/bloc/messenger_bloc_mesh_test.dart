import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';

import 'package:taler_id_mobile/core/services/messenger_cache_service.dart';
import 'package:taler_id_mobile/core/services/pending_message_service.dart';
import 'package:taler_id_mobile/core/di/service_locator.dart';
import 'package:taler_id_mobile/features/messenger/data/services/pending_mesh_send_queue.dart';
import 'package:taler_id_mobile/features/messenger/domain/entities/message_entity.dart';
import 'package:taler_id_mobile/features/messenger/domain/repositories/i_messenger_repository.dart'
    show IMessengerRepository, MeshInboundMessage, MeshOutboundMessage;
import 'package:taler_id_mobile/features/messenger/presentation/bloc/messenger_bloc.dart';
import 'package:taler_id_mobile/features/messenger/presentation/bloc/messenger_event.dart';
import 'package:taler_id_mobile/features/messenger/presentation/bloc/messenger_state.dart';

class _FakeRepo implements IMessengerRepository {
  final _meshCtrl = StreamController<MeshInboundMessage>.broadcast();
  final _meshOutCtrl = StreamController<MeshOutboundMessage>.broadcast();

  @override
  Stream<MeshInboundMessage> get meshMessageStream => _meshCtrl.stream;

  @override
  Stream<MeshOutboundMessage> get meshOutboundStream => _meshOutCtrl.stream;

  void pushMesh(MeshInboundMessage m) => _meshCtrl.add(m);

  @override
  void dispose() {}

  @override
  dynamic noSuchMethod(Invocation i) =>
      throw UnimplementedError('not used in mesh test: ${i.memberName}');
}

class _FakeCache implements MessengerCacheService {
  @override
  List<Map<String, dynamic>>? getMessages(String conversationId) => null;
  @override
  List<Map<String, dynamic>> getMeshMessagesFor(String conversationId) =>
      const [];
  @override
  dynamic noSuchMethod(Invocation i) => null;
}

class _FakePending implements PendingMessageService {
  @override
  dynamic noSuchMethod(Invocation i) => null;
}

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

  group('MessengerBloc MeshMessageReceived', () {
    blocTest<MessengerBloc, MessengerState>(
      'emits state with MessageEntity(transport: "mesh") in the routed conversation',
      build: () => MessengerBloc(repo: _FakeRepo()),
      act: (bloc) => bloc.add(MeshMessageReceived(
        conversationId: 'server-conv-42',
        contactUserId: 'contact-1',
        text: 'hello from mesh',
        receivedAt: DateTime(2026, 4, 24, 12, 0),
      )),
      verify: (bloc) {
        final list = bloc.state.messages['server-conv-42'];
        expect(list, isNotNull);
        expect(list!, hasLength(1));
        expect(list.first.content, 'hello from mesh');
        expect(list.first.senderId, 'contact-1');
        expect(list.first.transport, 'mesh');
        expect(list.first.conversationId, 'server-conv-42');
      },
    );

    blocTest<MessengerBloc, MessengerState>(
      'appends to existing conversation messages preserving ascending sentAt order',
      build: () => MessengerBloc(repo: _FakeRepo()),
      act: (bloc) async {
        bloc.add(MeshMessageReceived(
          conversationId: 'server-conv-42',
          contactUserId: 'contact-1',
          text: 'earlier',
          receivedAt: DateTime(2026, 4, 24, 11, 0),
        ));
        bloc.add(MeshMessageReceived(
          conversationId: 'server-conv-42',
          contactUserId: 'contact-1',
          text: 'later',
          receivedAt: DateTime(2026, 4, 24, 12, 0),
        ));
      },
      verify: (bloc) {
        final list = bloc.state.messages['server-conv-42']!;
        expect(list.map((m) => m.content).toList(), ['earlier', 'later']);
      },
    );

    blocTest<MessengerBloc, MessengerState>(
      'deduplicates by message id when the same MeshMessageReceived fires twice',
      build: () => MessengerBloc(repo: _FakeRepo()),
      act: (bloc) async {
        // same event added twice to the bloc queue — dedup on id prevents double emit
        final evt = MeshMessageReceived(
          conversationId: 'server-conv-42',
          contactUserId: 'contact-1',
          text: 'only once',
          receivedAt: DateTime(2026, 4, 24, 12, 0),
        );
        bloc.add(evt);
        bloc.add(evt);
      },
      verify: (bloc) {
        expect(bloc.state.messages['server-conv-42'], hasLength(1));
      },
    );

    blocTest<MessengerBloc, MessengerState>(
      'MeshMessageSent replaces temp_* bubble with mesh-out MessageEntity',
      build: () => MessengerBloc(repo: _FakeRepo()),
      seed: () => MessengerState(
        currentUserId: 'user-me',
        messages: {
          'server-conv-42': [
            MessageEntity(
              id: 'temp_123',
              conversationId: 'server-conv-42',
              senderId: 'user-me',
              content: 'hi via mesh',
              sentAt: DateTime(2026, 4, 24, 12, 0),
            ),
          ],
        },
      ),
      act: (bloc) => bloc.add(MeshMessageSent(
        id: 'mesh-out-contact-1-1777020401699',
        conversationId: 'server-conv-42',
        contactUserId: 'contact-1',
        clientTempId: 'temp_123',
        text: 'hi via mesh',
        sentAt: DateTime(2026, 4, 24, 12, 0),
      )),
      verify: (bloc) {
        final list = bloc.state.messages['server-conv-42']!;
        expect(list, hasLength(1));
        expect(list.first.id, 'mesh-out-contact-1-1777020401699');
        expect(list.first.transport, 'mesh');
        expect(list.first.senderId, 'user-me');
      },
    );

    test(
        'merges mesh history Map with server MessageEntity list via fromJson sorted by sentAt',
        () {
      // Pure helper-level verification: a Map in the mesh_messages Hive box
      // round-trips via MessageEntity.fromJson with transport='mesh', and
      // when merged with server messages and sorted by sentAt, the interleave
      // order matches the timestamps. This locks in the shape that
      // _onOpenConversation's merge must produce.
      final meshRaw = {
        'id': 'mesh-in-contact-1-1761307200000',
        'conversationId': 'server-conv-42',
        'senderId': 'contact-1',
        'content': 'mid mesh',
        'sentAt': '2026-04-24T11:30:00.000Z',
        'transport': 'mesh',
      };
      final server = [
        MessageEntity(
          id: 'srv-1',
          conversationId: 'server-conv-42',
          senderId: 'contact-1',
          content: 'first',
          sentAt: DateTime.parse('2026-04-24T11:00:00.000Z'),
        ),
        MessageEntity(
          id: 'srv-2',
          conversationId: 'server-conv-42',
          senderId: 'me',
          content: 'last',
          sentAt: DateTime.parse('2026-04-24T12:00:00.000Z'),
        ),
      ];
      final merged = <MessageEntity>[
        ...server,
        MessageEntity.fromJson(meshRaw),
      ]..sort((a, b) => a.sentAt.compareTo(b.sentAt));
      expect(merged.map((m) => m.id).toList(),
          ['srv-1', 'mesh-in-contact-1-1761307200000', 'srv-2']);
      expect(merged[1].transport, 'mesh');
    });
  });
}

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';

import 'package:taler_id_mobile/core/services/messenger_cache_service.dart';
import 'package:taler_id_mobile/core/services/pending_message_service.dart';
import 'package:taler_id_mobile/core/di/service_locator.dart';
import 'package:taler_id_mobile/features/messenger/domain/entities/message_entity.dart';
import 'package:taler_id_mobile/features/messenger/domain/repositories/i_messenger_repository.dart';
import 'package:taler_id_mobile/features/messenger/presentation/bloc/messenger_bloc.dart';
import 'package:taler_id_mobile/features/messenger/presentation/bloc/messenger_event.dart';
import 'package:taler_id_mobile/features/messenger/presentation/bloc/messenger_state.dart';

class _FakeRepo implements IMessengerRepository {
  final _meshCtrl = StreamController<MeshInboundMessage>.broadcast();

  @override
  Stream<MeshInboundMessage> get meshMessageStream => _meshCtrl.stream;

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
    if (!sl.isRegistered<MessengerCacheService>()) {
      sl.registerSingleton<MessengerCacheService>(_FakeCache());
    }
    if (!sl.isRegistered<PendingMessageService>()) {
      sl.registerSingleton<PendingMessageService>(_FakePending());
    }
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
  });
}

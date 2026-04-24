import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:taler_id_mobile/core/services/messenger_cache_service.dart';
import 'package:taler_id_mobile/core/services/pending_message_service.dart';
import 'package:taler_id_mobile/features/messenger/data/datasources/messenger_remote_datasource.dart';
import 'package:taler_id_mobile/features/messenger/domain/entities/analyst_events.dart';
import 'package:taler_id_mobile/features/messenger/domain/entities/message_entity.dart';
import 'package:taler_id_mobile/features/messenger/presentation/bloc/messenger_bloc.dart';
import 'package:taler_id_mobile/features/messenger/presentation/bloc/messenger_event.dart';
import 'package:taler_id_mobile/features/messenger/domain/repositories/i_messenger_repository.dart';

class _MockRepo extends Mock implements IMessengerRepository {}
class _MockCacheService extends Mock implements MessengerCacheService {}
class _MockPendingMessageService extends Mock implements PendingMessageService {}
class _MockRemoteDataSource extends Mock implements MessengerRemoteDataSource {}

void main() {
  late _MockRepo repo;
  late StreamController<AnalystChunk> chunkCtrl;
  late StreamController<AnalystSeam> seamCtrl;
  final sl = GetIt.instance;

  setUp(() {
    // Reset GetIt for each test
    sl.reset();

    final mockCache = _MockCacheService();
    final mockPending = _MockPendingMessageService();
    final mockRemote = _MockRemoteDataSource();

    // Stub cache methods used during construction/operation
    when(() => mockCache.getConversations()).thenReturn(null);
    when(() => mockCache.getMessages(any())).thenReturn(null);
    when(() => mockCache.appendMessage(any(), any())).thenAnswer((_) async {});

    // Stub pending message methods
    when(() => mockPending.getAll()).thenReturn([]);
    when(() => mockPending.getForConversation(any())).thenReturn([]);

    // Stub reconnectStream used in _onConnect
    when(() => mockRemote.reconnectStream).thenAnswer((_) => const Stream.empty());

    sl.registerSingleton<MessengerCacheService>(mockCache);
    sl.registerSingleton<PendingMessageService>(mockPending);
    sl.registerSingleton<MessengerRemoteDataSource>(mockRemote);

    repo = _MockRepo();
    chunkCtrl = StreamController<AnalystChunk>.broadcast();
    seamCtrl = StreamController<AnalystSeam>.broadcast();
    when(() => repo.analystChunkStream).thenAnswer((_) => chunkCtrl.stream);
    when(() => repo.analystSeamStream).thenAnswer((_) => seamCtrl.stream);
    when(() => repo.messageStream).thenAnswer((_) => const Stream.empty());
    when(() => repo.typingStream).thenAnswer((_) => const Stream.empty());
    when(() => repo.callInviteStream).thenAnswer((_) => const Stream.empty());
    when(() => repo.messageUpdatedStream).thenAnswer((_) => const Stream.empty());
    when(() => repo.messagesReadStream).thenAnswer((_) => const Stream.empty());
    when(() => repo.groupUpdatedStream).thenAnswer((_) => const Stream.empty());
    when(() => repo.groupMemberAddedStream).thenAnswer((_) => const Stream.empty());
    when(() => repo.groupMemberRemovedStream).thenAnswer((_) => const Stream.empty());
    when(() => repo.groupRoleChangedStream).thenAnswer((_) => const Stream.empty());
    when(() => repo.groupCreatedStream).thenAnswer((_) => const Stream.empty());
    when(() => repo.groupDeletedStream).thenAnswer((_) => const Stream.empty());
    when(() => repo.groupCallStartedStream).thenAnswer((_) => const Stream.empty());
    when(() => repo.groupCallEndedStream).thenAnswer((_) => const Stream.empty());
    when(() => repo.messageDeletedStream).thenAnswer((_) => const Stream.empty());
    when(() => repo.messageAckedStream).thenAnswer((_) => const Stream.empty());
    when(() => repo.contactRequestStream).thenAnswer((_) => const Stream.empty());
    when(() => repo.contactAcceptedStream).thenAnswer((_) => const Stream.empty());
    when(() => repo.reactionUpdatedStream).thenAnswer((_) => const Stream.empty());
    when(() => repo.socketErrorStream).thenAnswer((_) => const Stream.empty());
  });

  tearDown(() async {
    await chunkCtrl.close();
    await seamCtrl.close();
    sl.reset();
  });

  test('AnalystChunkReceived appends to pendingAnalystText', () async {
    final bloc = MessengerBloc(repo: repo);
    bloc.add(const AnalystChunkReceived(conversationId: 'c', text: 'Hello '));
    await Future.delayed(const Duration(milliseconds: 10));
    expect(bloc.state.pendingAnalystText['c'], 'Hello ');
    bloc.add(const AnalystChunkReceived(conversationId: 'c', text: 'world'));
    await Future.delayed(const Duration(milliseconds: 10));
    expect(bloc.state.pendingAnalystText['c'], 'Hello world');
    await bloc.close();
  });

  test('AnalystSeamReceived stores seam by messageId', () async {
    final bloc = MessengerBloc(repo: repo);
    bloc.add(AnalystSeamReceived(
      seam: const AnalystSeam(
        conversationId: 'c', messageId: 'm', steps: [SeamStep(kind: 'file', count: 3)],
        durationMs: 100,
      ),
    ));
    await Future.delayed(const Duration(milliseconds: 10));
    expect(bloc.state.analystSeams['m']?.steps.first.kind, 'file');
    await bloc.close();
  });

  test('MessageReceived for bot (isSystem) clears pendingAnalystText for that conv', () async {
    final bloc = MessengerBloc(repo: repo);
    bloc.add(const AnalystChunkReceived(conversationId: 'c', text: 'hi'));
    await Future.delayed(const Duration(milliseconds: 10));
    expect(bloc.state.pendingAnalystText['c'], 'hi');

    final msg = MessageEntity(
      id: 'm', conversationId: 'c', senderId: 'bot',
      content: 'final answer', sentAt: DateTime.now(), isSystem: true,
    );
    bloc.add(MessageReceived(msg));
    await Future.delayed(const Duration(milliseconds: 30));
    expect(bloc.state.pendingAnalystText.containsKey('c'), false);
    await bloc.close();
  });
}

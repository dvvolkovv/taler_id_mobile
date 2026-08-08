import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';

import 'package:taler_id_mobile/core/services/messenger_cache_service.dart';
import 'package:taler_id_mobile/core/services/pending_message_service.dart';
import 'package:taler_id_mobile/features/messenger/data/services/pending_mesh_send_queue.dart';
import 'package:taler_id_mobile/features/messenger/domain/entities/conversation_entity.dart';
import 'package:taler_id_mobile/features/messenger/domain/repositories/i_messenger_repository.dart';
import 'package:taler_id_mobile/features/messenger/presentation/bloc/messenger_bloc.dart';
import 'package:taler_id_mobile/features/messenger/presentation/bloc/messenger_event.dart';

class _MockRepo extends Mock implements IMessengerRepository {}

class _MockCacheService extends Mock implements MessengerCacheService {}

class _MockPendingMessageService extends Mock implements PendingMessageService {}

/// Builds a minimal [ConversationEntity] fixture. Only the fields relevant
/// to the pin BLoC handlers are parameterised.
ConversationEntity _conv(String id, {int pinnedCount = 0, DateTime? pinsDismissedAt}) =>
    ConversationEntity(
      id: id,
      participantIds: const ['me', 'other'],
      pinnedCount: pinnedCount,
      pinsDismissedAt: pinsDismissedAt,
    );

void main() {
  late _MockRepo repo;
  final sl = GetIt.instance;

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  setUp(() {
    // Reset GetIt for each test so mock/stub state cannot leak between them.
    sl.reset();

    final mockCache = _MockCacheService();
    final mockPending = _MockPendingMessageService();

    sl.registerSingleton<MessengerCacheService>(mockCache);
    sl.registerSingleton<PendingMessageService>(mockPending);
    sl.registerSingleton<PendingMeshSendQueue>(PendingMeshSendQueue());

    repo = _MockRepo();
  });

  tearDown(() {
    sl.reset();
  });

  // Seeds a fresh MessengerBloc's `state.conversations` via the normal
  // LoadConversations path (the only place the BLoC populates the full
  // list — see Step 1 investigation) rather than reaching into bloc
  // internals, which would require a protected `emit` call.
  Future<MessengerBloc> seededBloc(List<ConversationEntity> seed) async {
    when(() => repo.getConversations()).thenAnswer((_) async => seed);
    final bloc = MessengerBloc(repo: repo);
    bloc.add(LoadConversations());
    await Future<void>.delayed(const Duration(milliseconds: 50));
    return bloc;
  }

  test(
      "PinMessage updates that conversation's pinnedCount from the response and leaves other conversations untouched",
      () async {
    final bloc = await seededBloc([_conv('conv-1'), _conv('conv-2', pinnedCount: 5)]);
    when(() => repo.pinMessage('conv-1', 'msg-1')).thenAnswer((_) async => {
          'pinnedAt': '2026-08-08T10:00:00.000Z',
          'pinnedCount': 3,
          'alreadyPinned': false,
          'systemMessageId': 'sys-1',
        });

    bloc.add(const PinMessage(conversationId: 'conv-1', messageId: 'msg-1'));
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(bloc.state.conversations.firstWhere((c) => c.id == 'conv-1').pinnedCount, 3);
    expect(bloc.state.conversations.firstWhere((c) => c.id == 'conv-2').pinnedCount, 5);
    await bloc.close();
  });

  test('UnpinMessage updates that conversation\'s pinnedCount from the response and leaves other conversations untouched',
      () async {
    final bloc = await seededBloc([_conv('conv-1', pinnedCount: 3), _conv('conv-2', pinnedCount: 5)]);
    when(() => repo.unpinMessage('conv-1', 'msg-1')).thenAnswer((_) async => {
          'pinnedCount': 2,
          'wasPinned': true,
        });

    bloc.add(const UnpinMessage(conversationId: 'conv-1', messageId: 'msg-1'));
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(bloc.state.conversations.firstWhere((c) => c.id == 'conv-1').pinnedCount, 2);
    expect(bloc.state.conversations.firstWhere((c) => c.id == 'conv-2').pinnedCount, 5);
    await bloc.close();
  });

  test('UnpinAllMessages zeroes the count', () async {
    final bloc = await seededBloc([_conv('conv-1', pinnedCount: 5)]);
    when(() => repo.unpinAll('conv-1')).thenAnswer((_) async => {'unpinned': 5});

    bloc.add(const UnpinAllMessages('conv-1'));
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(bloc.state.conversations.firstWhere((c) => c.id == 'conv-1').pinnedCount, 0);
    await bloc.close();
  });

  test('DismissPins passes upTo through to the repository and stores the returned stamp', () async {
    final bloc = await seededBloc([_conv('conv-1')]);
    final upTo = DateTime.utc(2026, 8, 8, 9);
    when(() => repo.dismissPins('conv-1', upTo: upTo)).thenAnswer((_) async => {
          'pinsDismissedAt': '2026-08-08T12:00:00.000Z',
        });

    bloc.add(DismissPins('conv-1', upTo: upTo));
    await Future<void>.delayed(const Duration(milliseconds: 50));

    verify(() => repo.dismissPins('conv-1', upTo: upTo)).called(1);
    expect(
      bloc.state.conversations.firstWhere((c) => c.id == 'conv-1').pinsDismissedAt,
      DateTime.parse('2026-08-08T12:00:00.000Z'),
    );
    await bloc.close();
  });

  test("PinEventReceived('message_pinned', ...) updates the count for the right conversation", () async {
    final bloc = await seededBloc([_conv('conv-1'), _conv('conv-2', pinnedCount: 1)]);

    bloc.add(PinEventReceived('message_pinned', {
      'conversationId': 'conv-2',
      'messageId': 'm1',
      'pinnedById': 'u1',
      'pinnedAt': '2026-08-08T10:00:00.000Z',
      'pinnedCount': 7,
    }));
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(bloc.state.conversations.firstWhere((c) => c.id == 'conv-2').pinnedCount, 7);
    expect(bloc.state.conversations.firstWhere((c) => c.id == 'conv-1').pinnedCount, 0);
    await bloc.close();
  });

  test('PinEventReceived with an unknown conversationId changes nothing and does not throw', () async {
    final bloc = await seededBloc([_conv('conv-1', pinnedCount: 2), _conv('conv-2', pinnedCount: 5)]);
    final before = bloc.state.conversations;

    bloc.add(PinEventReceived('message_pinned', {
      'conversationId': 'does-not-exist',
      'pinnedCount': 99,
    }));
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(bloc.state.conversations, before);
    expect(bloc.state.conversations.map((c) => c.pinnedCount).toList(), [2, 5]);

    // Prove the bloc is still alive and processing events normally after
    // the unknown-id event, not just that this specific assertion passed.
    bloc.add(PinEventReceived('message_pinned', {'conversationId': 'conv-1', 'pinnedCount': 9}));
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(bloc.state.conversations.firstWhere((c) => c.id == 'conv-1').pinnedCount, 9);

    await bloc.close();
  });
}

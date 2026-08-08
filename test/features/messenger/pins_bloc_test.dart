import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';

import 'package:taler_id_mobile/core/services/messenger_cache_service.dart';
import 'package:taler_id_mobile/core/services/pending_message_service.dart';
import 'package:taler_id_mobile/features/messenger/data/services/pending_mesh_send_queue.dart';
import 'package:taler_id_mobile/features/messenger/domain/entities/conversation_entity.dart';
import 'package:taler_id_mobile/features/messenger/domain/entities/message_entity.dart';
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

/// Builds a minimal [MessageEntity] fixture. Only the fields relevant to
/// the pin BLoC handlers are parameterised.
MessageEntity _msg(String id, String conversationId, {DateTime? pinnedAt, String? pinnedById}) =>
    MessageEntity(
      id: id,
      conversationId: conversationId,
      senderId: 'other',
      content: 'hello',
      sentAt: DateTime(2026, 8, 8),
      pinnedAt: pinnedAt,
      pinnedById: pinnedById,
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
    // Unlike most calls in the pinnedCount-only tests below, seedMessages()
    // (added for the message-level tests further down) drives real
    // MessageReceived events through _onMessageReceived, which fires this
    // unconditionally as a side effect — mocktail throws on an unstubbed
    // Future-returning method instead of quietly no-op'ing.
    when(() => mockCache.appendMessage(any(), any())).thenAnswer((_) async {});

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

  // Seeds `state.messages[conversationId]` via the normal MessageReceived
  // path — the single-message analogue of seededBloc's LoadConversations
  // choice above, for the same reason: it goes through a real event
  // instead of reaching into bloc internals for a protected `emit`.
  // _onMessageReceived re-triggers LoadConversations() per message as a
  // side effect; already-stubbed via seededBloc, and harmless here since
  // it only ever re-applies the same conversations seed via `copyWith`
  // (never touches `state.messages`), and this always runs before any
  // pin/unpin event under test is dispatched.
  Future<void> seedMessages(MessengerBloc bloc, List<MessageEntity> msgs) async {
    for (final m in msgs) {
      bloc.add(MessageReceived(m));
    }
    await Future<void>.delayed(const Duration(milliseconds: 50));
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
    // Without this the handler could drop the repository call entirely and
    // still pass, since the emitted count is hardcoded to 0.
    verify(() => repo.unpinAll('conv-1')).called(1);
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

  // ─── Message-level pin state (state.messages[..].pinnedAt/pinnedById) ───
  //
  // The tests above cover `ConversationEntity.pinnedCount`, which the
  // pinned banner reloads off. The message long-press menu (Task 14) reads
  // a message's own `pinnedAt` instead, so it needs `_withMessagePin` to
  // keep that field current too — these tests cover that companion path.

  test("PinMessage sets pinnedAt on the target message in state, and leaves other messages untouched", () async {
    final bloc = await seededBloc([_conv('conv-1')]);
    await seedMessages(bloc, [_msg('msg-1', 'conv-1'), _msg('msg-2', 'conv-1')]);
    when(() => repo.pinMessage('conv-1', 'msg-1')).thenAnswer((_) async => {
          'pinnedAt': '2026-08-08T10:00:00.000Z',
          'pinnedCount': 1,
          'alreadyPinned': false,
          'systemMessageId': 'sys-1',
        });

    bloc.add(const PinMessage(conversationId: 'conv-1', messageId: 'msg-1'));
    await Future<void>.delayed(const Duration(milliseconds: 50));

    final messages = bloc.state.messages['conv-1']!;
    expect(
      messages.firstWhere((m) => m.id == 'msg-1').pinnedAt,
      DateTime.parse('2026-08-08T10:00:00.000Z'),
    );
    // state.currentUserId is never set in this harness (no ConnectMessenger
    // dispatched) — pinnedById is correctly left alone rather than guessed.
    expect(messages.firstWhere((m) => m.id == 'msg-1').pinnedById, isNull);
    expect(messages.firstWhere((m) => m.id == 'msg-2').pinnedAt, isNull);
    await bloc.close();
  });

  test('UnpinMessage clears pinnedAt and pinnedById on the target message', () async {
    final bloc = await seededBloc([_conv('conv-1', pinnedCount: 1)]);
    await seedMessages(bloc, [
      _msg('msg-1', 'conv-1', pinnedAt: DateTime.utc(2026, 8, 8, 9), pinnedById: 'other'),
      _msg('msg-2', 'conv-1'),
    ]);
    when(() => repo.unpinMessage('conv-1', 'msg-1')).thenAnswer((_) async => {
          'pinnedCount': 0,
          'wasPinned': true,
        });

    bloc.add(const UnpinMessage(conversationId: 'conv-1', messageId: 'msg-1'));
    await Future<void>.delayed(const Duration(milliseconds: 50));

    final messages = bloc.state.messages['conv-1']!;
    final unpinned = messages.firstWhere((m) => m.id == 'msg-1');
    expect(unpinned.pinnedAt, isNull);
    expect(unpinned.pinnedById, isNull);
    // Untouched message stays untouched.
    expect(messages.firstWhere((m) => m.id == 'msg-2').pinnedAt, isNull);
    await bloc.close();
  });

  test("PinEventReceived('message_pinned', ...) sets pinnedAt/pinnedById on the target message from the socket payload",
      () async {
    final bloc = await seededBloc([_conv('conv-1')]);
    await seedMessages(bloc, [_msg('msg-1', 'conv-1')]);

    bloc.add(PinEventReceived('message_pinned', {
      'conversationId': 'conv-1',
      'messageId': 'msg-1',
      'pinnedById': 'u1',
      'pinnedAt': '2026-08-08T10:00:00.000Z',
      'pinnedCount': 1,
    }));
    await Future<void>.delayed(const Duration(milliseconds: 50));

    final msg = bloc.state.messages['conv-1']!.firstWhere((m) => m.id == 'msg-1');
    expect(msg.pinnedAt, DateTime.parse('2026-08-08T10:00:00.000Z'));
    expect(msg.pinnedById, 'u1');
    await bloc.close();
  });

  test(
      "PinEventReceived('pins_cleared', ...) clears pinnedAt/pinnedById on every loaded message of that conversation, leaving another conversation's messages alone",
      () async {
    final bloc = await seededBloc([_conv('conv-1'), _conv('conv-2')]);
    await seedMessages(bloc, [
      _msg('msg-1', 'conv-1', pinnedAt: DateTime.utc(2026, 8, 8, 9), pinnedById: 'u1'),
      _msg('msg-2', 'conv-1', pinnedAt: DateTime.utc(2026, 8, 8, 9, 5), pinnedById: 'u2'),
      _msg('msg-3', 'conv-1'), // never pinned — clearing it is a no-op
      _msg('msg-9', 'conv-2', pinnedAt: DateTime.utc(2026, 8, 8, 9), pinnedById: 'u3'),
    ]);

    bloc.add(PinEventReceived('pins_cleared', {'conversationId': 'conv-1'}));
    await Future<void>.delayed(const Duration(milliseconds: 50));

    for (final m in bloc.state.messages['conv-1']!) {
      expect(m.pinnedAt, isNull, reason: '${m.id} should have been cleared');
      expect(m.pinnedById, isNull, reason: '${m.id} should have been cleared');
    }
    final other = bloc.state.messages['conv-2']!.firstWhere((m) => m.id == 'msg-9');
    expect(other.pinnedAt, isNotNull);
    expect(other.pinnedById, 'u3');
    await bloc.close();
  });

  test('an unparseable pinnedAt in a message_pinned payload does not throw and does not corrupt state',
      () async {
    final bloc = await seededBloc([_conv('conv-1')]);
    await seedMessages(bloc, [_msg('msg-1', 'conv-1')]);

    bloc.add(PinEventReceived('message_pinned', {
      'conversationId': 'conv-1',
      'messageId': 'msg-1',
      'pinnedById': 'u1',
      'pinnedAt': 'not-a-date',
      'pinnedCount': 1,
    }));
    await Future<void>.delayed(const Duration(milliseconds: 50));

    // The count still updates — proves the handler didn't bail out of the
    // whole case, just skipped the unparseable field.
    expect(bloc.state.conversations.firstWhere((c) => c.id == 'conv-1').pinnedCount, 1);
    // The message itself is left alone rather than corrupted with a bad
    // DateTime or wrongly cleared.
    var msg = bloc.state.messages['conv-1']!.firstWhere((m) => m.id == 'msg-1');
    expect(msg.pinnedAt, isNull);
    expect(msg.pinnedById, isNull);

    // Prove the bloc is still alive and processing pin events normally
    // afterwards, not just that this specific assertion passed.
    bloc.add(PinEventReceived('message_pinned', {
      'conversationId': 'conv-1',
      'messageId': 'msg-1',
      'pinnedById': 'u1',
      'pinnedAt': '2026-08-08T10:00:00.000Z',
      'pinnedCount': 2,
    }));
    await Future<void>.delayed(const Duration(milliseconds: 50));
    msg = bloc.state.messages['conv-1']!.firstWhere((m) => m.id == 'msg-1');
    expect(msg.pinnedAt, DateTime.parse('2026-08-08T10:00:00.000Z'));

    await bloc.close();
  });
}

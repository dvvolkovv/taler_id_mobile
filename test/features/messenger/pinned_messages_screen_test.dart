import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';

import 'package:taler_id_mobile/core/services/messenger_cache_service.dart';
import 'package:taler_id_mobile/core/services/pending_message_service.dart';
import 'package:taler_id_mobile/core/theme/app_theme.dart';
import 'package:taler_id_mobile/features/messenger/data/services/pending_mesh_send_queue.dart';
import 'package:taler_id_mobile/features/messenger/domain/entities/conversation_entity.dart';
import 'package:taler_id_mobile/features/messenger/domain/entities/message_entity.dart';
import 'package:taler_id_mobile/features/messenger/domain/repositories/i_messenger_repository.dart';
import 'package:taler_id_mobile/features/messenger/presentation/bloc/messenger_bloc.dart';
import 'package:taler_id_mobile/features/messenger/presentation/bloc/messenger_event.dart';
import 'package:taler_id_mobile/features/messenger/presentation/screens/pinned_messages_screen.dart';
import 'package:taler_id_mobile/l10n/app_localizations.dart';

class _MockRepo extends Mock implements IMessengerRepository {}

class _MockCacheService extends Mock implements MessengerCacheService {}

class _MockPendingMessageService extends Mock implements PendingMessageService {}

/// Records every event added to any Bloc while installed as `Bloc.observer`
/// (package:bloc). Lets tests assert "the widget dispatched X to the bloc"
/// directly and independently of whatever the bloc's own handler does with
/// it afterwards (e.g. which repository methods it calls in response) —
/// see the "confirming dispatches..." and "per-row unpin control" tests.
class _RecordingBlocObserver extends BlocObserver {
  final List<Object?> events = [];

  @override
  void onEvent(Bloc<dynamic, dynamic> bloc, Object? event) {
    super.onEvent(bloc, event);
    events.add(event);
  }
}

/// Minimal pinned-message fixture, mirroring pinned_banner_test.dart's `_pin`
/// helper but also carrying `senderName` — which the screen renders and the
/// banner does not.
MessageEntity _pin(String id, String senderName, String content) => MessageEntity(
      id: id,
      conversationId: 'conv-1',
      senderId: 'user-1',
      senderName: senderName,
      content: content,
      sentAt: DateTime(2026, 8, 8),
      pinnedAt: DateTime(2026, 8, 8),
      pinnedById: 'user-1',
    );

/// Minimal ConversationEntity fixture for the canPinIn (type, myRole)
/// matrix below.
ConversationEntity _conv(String type, {String? myRole}) => ConversationEntity(
      id: 'conv-1',
      participantIds: const ['me', 'other'],
      type: type,
      myRole: myRole,
    );

/// Wraps [child] with the localization/theme scaffolding every other pin
/// widget test in this suite uses (see pinned_banner_test.dart), plus the
/// MessengerBloc provider PinnedMessagesScreen reads for unpin actions.
Widget _wrap(MessengerBloc bloc, Widget child) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: AppTheme.dark,
      locale: const Locale('en'),
      home: BlocProvider<MessengerBloc>.value(value: bloc, child: child),
    );

void main() {
  // canPinIn is the client-side mirror of the backend's `_assertCanPin`
  // (messenger.service.ts) — the thing that must not silently regress, so
  // it gets its own pure-function coverage independent of the widget below.
  // Renamed from canUnpinIn (Task 14): the same rule now also gates the
  // "Pin" entry in chat_room_screen.dart's message long-press menu, not
  // just the "Unpin" controls below and on this screen.
  group('canPinIn', () {
    test('CHANNEL + SUBSCRIBER is false', () {
      expect(canPinIn(_conv('CHANNEL', myRole: 'SUBSCRIBER')), isFalse);
    });

    test('CHANNEL + ADMIN is true', () {
      expect(canPinIn(_conv('CHANNEL', myRole: 'ADMIN')), isTrue);
    });

    test('CHANNEL + OWNER is true', () {
      expect(canPinIn(_conv('CHANNEL', myRole: 'OWNER')), isTrue);
    });

    test('GROUP + MEMBER is false', () {
      expect(canPinIn(_conv('GROUP', myRole: 'MEMBER')), isFalse);
    });

    test('GROUP + ADMIN is true', () {
      expect(canPinIn(_conv('GROUP', myRole: 'ADMIN')), isTrue);
    });

    test('DIRECT is true regardless of role', () {
      expect(canPinIn(_conv('DIRECT')), isTrue);
      // Role must not gate a DIRECT conversation — even a role string that
      // would read as low-privilege for GROUP/CHANNEL must not leak through
      // and flip this to false.
      expect(canPinIn(_conv('DIRECT', myRole: 'SUBSCRIBER')), isTrue);
    });

    test('SAVED is true', () {
      expect(canPinIn(_conv('SAVED')), isTrue);
    });

    test('an AI_* type is true', () {
      expect(canPinIn(_conv('AI_ANALYST')), isTrue);
    });

    test('null conversation is false', () {
      expect(canPinIn(null), isFalse);
    });
  });

  group('PinnedMessagesScreen', () {
    late _MockRepo repo;
    late _RecordingBlocObserver observer;

    setUp(() {
      // Reset GetIt for each test so mock/stub state cannot leak between
      // them (same rationale as pins_bloc_test.dart's setUp).
      GetIt.instance.reset();
      GetIt.instance.registerSingleton<MessengerCacheService>(_MockCacheService());
      GetIt.instance.registerSingleton<PendingMessageService>(_MockPendingMessageService());
      GetIt.instance.registerSingleton<PendingMeshSendQueue>(PendingMeshSendQueue());

      repo = _MockRepo();
      // The screen reads the repository straight from GetIt
      // (sl<IMessengerRepository>()) for both its initial load and its
      // post-unpin reconciliation — see PinnedMessagesScreen._load()/
      // _reconcile(). The same instance also backs MessengerBloc below, so
      // stubs apply to both call paths.
      GetIt.instance.registerSingleton<IMessengerRepository>(repo);

      observer = _RecordingBlocObserver();
      Bloc.observer = observer;
    });

    tearDown(() => GetIt.instance.reset());

    testWidgets('shows the sender name and preview for each loaded pin', (tester) async {
      when(() => repo.getPinnedMessages('conv-1')).thenAnswer((_) async => [
            _pin('msg-1', 'Alice', 'Hello there\nSecond line'),
            _pin('msg-2', 'Bob', 'Another pinned message'),
          ]);
      final bloc = MessengerBloc(repo: repo);
      addTearDown(bloc.close);

      await tester.pumpWidget(_wrap(
        bloc,
        const PinnedMessagesScreen(conversationId: 'conv-1', canUnpin: false),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Alice'), findsOneWidget);
      // Newlines collapsed into a single-line preview, same transform as
      // PinnedBanner's own preview.
      expect(find.text('Hello there Second line'), findsOneWidget);
      expect(find.text('Bob'), findsOneWidget);
      expect(find.text('Another pinned message'), findsOneWidget);
    });

    testWidgets("tapping a row pops with that message's id", (tester) async {
      when(() => repo.getPinnedMessages('conv-1'))
          .thenAnswer((_) async => [_pin('msg-1', 'Alice', 'Hello there')]);
      final bloc = MessengerBloc(repo: repo);
      addTearDown(bloc.close);

      String? popped;
      // Push PinnedMessagesScreen onto a real Navigator (from a harness
      // button) so its Navigator.pop(context, message.id) has a caller to
      // return the value to — pumping it directly as `home` would make the
      // pop a no-op with nothing to observe.
      await tester.pumpWidget(_wrap(
        bloc,
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              popped = await Navigator.of(context).push<String>(
                MaterialPageRoute(
                  builder: (_) => const PinnedMessagesScreen(
                    conversationId: 'conv-1',
                    canUnpin: false,
                  ),
                ),
              );
            },
            child: const Text('open'),
          ),
        ),
      ));

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Hello there'));
      await tester.pumpAndSettle();

      expect(popped, 'msg-1');
    });

    testWidgets('empty list shows the noPinnedMessages text', (tester) async {
      when(() => repo.getPinnedMessages('conv-1')).thenAnswer((_) async => []);
      final bloc = MessengerBloc(repo: repo);
      addTearDown(bloc.close);

      await tester.pumpWidget(_wrap(
        bloc,
        const PinnedMessagesScreen(conversationId: 'conv-1', canUnpin: false),
      ));
      await tester.pumpAndSettle();

      expect(find.text('No pinned messages'), findsOneWidget);
    });

    testWidgets('canUnpin false renders no unpin control and no Unpin all action',
        (tester) async {
      when(() => repo.getPinnedMessages('conv-1'))
          .thenAnswer((_) async => [_pin('msg-1', 'Alice', 'Hello there')]);
      final bloc = MessengerBloc(repo: repo);
      addTearDown(bloc.close);

      await tester.pumpWidget(_wrap(
        bloc,
        const PinnedMessagesScreen(conversationId: 'conv-1', canUnpin: false),
      ));
      await tester.pumpAndSettle();

      // The row itself still renders...
      expect(find.text('Alice'), findsOneWidget);
      // ...but no per-row unpin control and no AppBar "Unpin all".
      expect(find.byIcon(Icons.close_rounded), findsNothing);
      expect(find.text('Unpin all'), findsNothing);
    });

    testWidgets(
        'tapping the per-row unpin control dispatches UnpinMessage to the bloc and removes the row',
        (tester) async {
      var loadCount = 0;
      when(() => repo.getPinnedMessages('conv-1')).thenAnswer((_) async {
        loadCount++;
        // First call is PinnedMessagesScreen's initial load; every call
        // after that is one of _reconcile()'s retry attempts. Here the
        // very first retry already reflects the server having dropped
        // msg-1, so the retry loop settles (and stops) after exactly one
        // attempt — see loadCount's final value below.
        if (loadCount == 1) {
          return [
            _pin('msg-1', 'Alice', 'Hello there'),
            _pin('msg-2', 'Bob', 'Another pinned message'),
          ];
        }
        return [_pin('msg-2', 'Bob', 'Another pinned message')];
      });
      when(() => repo.unpinMessage('conv-1', 'msg-1'))
          .thenAnswer((_) async => {'pinnedCount': 1, 'wasPinned': true});
      final bloc = MessengerBloc(repo: repo);
      addTearDown(bloc.close);

      await tester.pumpWidget(_wrap(
        bloc,
        const PinnedMessagesScreen(conversationId: 'conv-1', canUnpin: true),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Alice'), findsOneWidget);
      expect(find.text('Bob'), findsOneWidget);

      // Two rows -> two unpin controls; tap the first (Alice's, msg-1).
      await tester.tap(find.byTooltip('Unpin').first);
      await tester.pump(); // optimistic removal, before _reconcile()'s first attempt

      // Dispatched straight to the bloc — no confirmation for a single row.
      expect(observer.events, hasLength(1));
      expect(observer.events.single, isA<UnpinMessage>());
      expect((observer.events.single as UnpinMessage).messageId, 'msg-1');
      expect(find.text('Alice'), findsNothing);

      await tester.pumpAndSettle(); // drive _reconcile()'s retry loop to completion

      // Reconciliation confirms the optimistic removal rather than
      // reverting it — msg-1 stays gone, msg-2 is untouched.
      expect(find.text('Alice'), findsNothing);
      expect(find.text('Bob'), findsOneWidget);
      expect(loadCount, 2);
    });

    testWidgets(
        'reconcile keeps retrying instead of restoring a row whose unpin write lands late',
        (tester) async {
      // Regression test for the fixed-delay reconcile this replaced: that
      // version took a single post-delay read at face value, so a write
      // that was merely slow — not rejected — looked identical to a
      // failure and got its row wrongly restored. Here the first retry
      // still sees msg-1 pinned (write not landed yet); only the second
      // reflects it actually having gone through.
      var loadCount = 0;
      when(() => repo.getPinnedMessages('conv-1')).thenAnswer((_) async {
        loadCount++;
        if (loadCount <= 2) {
          return [
            _pin('msg-1', 'Alice', 'Hello there'),
            _pin('msg-2', 'Bob', 'Another pinned message'),
          ];
        }
        return [_pin('msg-2', 'Bob', 'Another pinned message')];
      });
      when(() => repo.unpinMessage('conv-1', 'msg-1'))
          .thenAnswer((_) async => {'pinnedCount': 1, 'wasPinned': true});
      final bloc = MessengerBloc(repo: repo);
      addTearDown(bloc.close);

      await tester.pumpWidget(_wrap(
        bloc,
        const PinnedMessagesScreen(conversationId: 'conv-1', canUnpin: true),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Unpin').first);
      await tester.pumpAndSettle(); // drive the retry loop through both attempts

      // A single fixed-delay check would have taken the still-pinned first
      // retry at face value and put the row back. The retry loop instead
      // keeps going until the answer actually matches what was asked for,
      // landing here gone for good rather than restored.
      expect(find.text('Alice'), findsNothing);
      expect(find.text('Bob'), findsOneWidget);
      expect(loadCount, 3);
    });

    testWidgets(
        'canUnpin true shows Unpin all; confirming dispatches UnpinAllMessages to the bloc',
        (tester) async {
      var loadCount = 0;
      when(() => repo.getPinnedMessages('conv-1')).thenAnswer((_) async {
        loadCount++;
        // First call is the initial load; every call after that is one of
        // _reconcile(expectEmpty: true)'s retry attempts, by which point
        // the server has (in this fixture) actually cleared the pins —
        // otherwise the retry loop would burn through all its attempts
        // before accepting the still-non-empty answer on the last one.
        if (loadCount == 1) return [_pin('msg-1', 'Alice', 'Hello there')];
        return [];
      });
      when(() => repo.unpinAll('conv-1')).thenAnswer((_) async => {'unpinned': 1});
      final bloc = MessengerBloc(repo: repo);
      addTearDown(bloc.close);

      await tester.pumpWidget(_wrap(
        bloc,
        const PinnedMessagesScreen(conversationId: 'conv-1', canUnpin: true),
      ));
      await tester.pumpAndSettle();

      // Exactly one match before the dialog exists — the AppBar action.
      expect(find.text('Unpin all'), findsOneWidget);

      await tester.tap(find.text('Unpin all'));
      await tester.pumpAndSettle();

      // Confirmation dialog is up (its content string is unique, unlike
      // "Unpin all" which the dialog's own title/button also reuse)...
      expect(find.text('Unpin all messages in this chat?'), findsOneWidget);
      // ...and nothing has been dispatched to the bloc yet.
      expect(observer.events, isEmpty);

      // Confirm — scoped to the dialog so this can't accidentally hit the
      // AppBar action (same text) or the dialog's own title (same text,
      // not a button).
      final confirmButton = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.widgetWithText(TextButton, 'Unpin all'),
      );
      expect(confirmButton, findsOneWidget);
      await tester.tap(confirmButton);
      await tester.pumpAndSettle();

      expect(observer.events, hasLength(1));
      expect(observer.events.single, isA<UnpinAllMessages>());
      expect((observer.events.single as UnpinAllMessages).conversationId, 'conv-1');
    });
  });
}

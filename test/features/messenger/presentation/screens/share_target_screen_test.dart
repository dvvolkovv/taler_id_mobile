import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:taler_id_mobile/core/di/service_locator.dart';
import 'package:taler_id_mobile/core/storage/saved_conversation_id_cache.dart';
import 'package:taler_id_mobile/core/theme/app_theme.dart';
import 'package:taler_id_mobile/features/messenger/domain/entities/conversation_entity.dart';
import 'package:taler_id_mobile/features/messenger/domain/repositories/i_messenger_repository.dart';
import 'package:taler_id_mobile/features/messenger/presentation/bloc/messenger_bloc.dart';
import 'package:taler_id_mobile/features/messenger/presentation/bloc/messenger_event.dart';
import 'package:taler_id_mobile/features/messenger/presentation/bloc/messenger_state.dart';
import 'package:taler_id_mobile/features/messenger/presentation/screens/share_target_screen.dart';
import 'package:taler_id_mobile/l10n/app_localizations.dart';

class _MockMessengerBloc extends MockBloc<MessengerEvent, MessengerState>
    implements MessengerBloc {}

class _MockRepo extends Mock implements IMessengerRepository {}

class _MockCache extends Mock implements SavedConversationIdCache {}

final _files = [
  SharedMediaFile(
      path: '/data/user/0/app/cache/Отчёт.pdf', type: SharedMediaType.file),
];

ConversationEntity _conv(String id, String type,
        {String? name, String? otherUserName}) =>
    ConversationEntity(
      id: id,
      participantIds: const [],
      type: type,
      name: name,
      otherUserName: otherUserName,
    );

void main() {
  late _MockMessengerBloc bloc;
  late _MockRepo repo;
  late _MockCache cache;
  String? openedChat;
  Object? openedExtra;

  setUpAll(() {
    // mocktail 1.0.4: registerFallbackValue(dynamic) без параметра типа.
    registerFallbackValue(LoadConversations());
  });

  setUp(() async {
    await sl.reset();
    bloc = _MockMessengerBloc();
    repo = _MockRepo();
    cache = _MockCache();
    sl.registerSingleton<IMessengerRepository>(repo);
    sl.registerSingleton<SavedConversationIdCache>(cache);
    openedChat = null;
    openedExtra = null;
    when(() => bloc.state).thenReturn(MessengerState(conversations: [
      _conv('c-anna', 'DIRECT', otherUserName: 'Anna Ivanova'),
      _conv('c-team', 'GROUP', name: 'Taler team'),
    ]));
    when(() => bloc.stream).thenAnswer((_) => const Stream.empty());
  });

  tearDown(() => sl.reset());

  Future<void> pumpScreen(WidgetTester tester,
      {bool settle = true, List<SharedMediaFile>? files}) async {
    final router = GoRouter(
      initialLocation: '/dashboard/messenger/share',
      routes: [
        GoRoute(
          path: '/dashboard/messenger',
          builder: (_, __) => const Scaffold(body: Text('chat list')),
          routes: [
            GoRoute(
              path: 'share',
              builder: (_, __) =>
                  ShareTargetScreen(sharedFiles: files ?? _files),
            ),
            GoRoute(
              path: ':id',
              builder: (_, state) {
                openedChat = state.pathParameters['id'];
                openedExtra = state.extra;
                return Scaffold(
                    body: Text('chat ${state.pathParameters['id']}'));
              },
            ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(BlocProvider<MessengerBloc>.value(
      value: bloc,
      child: MaterialApp.router(
        routerConfig: router,
        theme: AppTheme.dark,
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    ));
    if (settle) {
      await tester.pumpAndSettle();
    } else {
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  testWidgets('shows the file and the chats under "Send to"', (tester) async {
    await pumpScreen(tester);
    expect(find.text('Send to'), findsOneWidget);
    expect(find.text('Отчёт.pdf'), findsOneWidget);
    expect(find.text('Favorites'), findsOneWidget);
    expect(find.text('Anna Ivanova'), findsOneWidget);
    expect(find.text('Taler team'), findsOneWidget);
    verify(() => bloc.add(any(that: isA<LoadConversations>()))).called(1);
  });

  testWidgets('search narrows the list', (tester) async {
    await pumpScreen(tester);
    await tester.enterText(find.byType(TextField), 'team');
    await tester.pump();
    expect(find.text('Taler team'), findsOneWidget);
    expect(find.text('Anna Ivanova'), findsNothing);
  });

  testWidgets('picking a chat opens it with the files and sends nothing',
      (tester) async {
    await pumpScreen(tester);
    await tester.tap(find.text('Anna Ivanova'));
    await tester.pumpAndSettle();
    expect(find.text('chat c-anna'), findsOneWidget);
    expect(openedChat, 'c-anna');
    expect((openedExtra as Map)['sharedFiles'], same(_files));
    verifyNever(() => bloc.add(any(that: isA<SendMessage>())));
  });

  testWidgets('Favorites asks the server and remembers the id',
      (tester) async {
    when(() => repo.getOrCreateSavedConversation())
        .thenAnswer((_) async => 'c-saved');
    when(() => cache.write(any())).thenAnswer((_) async {});
    await pumpScreen(tester);
    await tester.tap(find.text('Favorites'));
    await tester.pumpAndSettle();
    expect(openedChat, 'c-saved');
    expect((openedExtra as Map)['sharedFiles'], same(_files));
    verify(() => repo.getOrCreateSavedConversation()).called(1);
    verify(() => cache.write('c-saved')).called(1);
    verifyNever(() => cache.read());
  });

  testWidgets('Favorites without the server falls back to the remembered id',
      (tester) async {
    when(() => repo.getOrCreateSavedConversation())
        .thenThrow(Exception('offline'));
    when(() => cache.read()).thenAnswer((_) async => 'c-cached');
    await pumpScreen(tester);
    await tester.tap(find.text('Favorites'));
    await tester.pumpAndSettle();
    expect(openedChat, 'c-cached');
  });

  testWidgets('a second tap on Favorites while it opens is ignored',
      (tester) async {
    final pending = Completer<String>();
    when(() => repo.getOrCreateSavedConversation())
        .thenAnswer((_) => pending.future);
    when(() => cache.write(any())).thenAnswer((_) async {});
    await pumpScreen(tester);
    await tester.tap(find.text('Favorites'));
    await tester.pump();
    await tester.tap(find.text('Favorites'));
    await tester.pump();
    pending.complete('c-saved');
    await tester.pumpAndSettle();
    verify(() => repo.getOrCreateSavedConversation()).called(1);
    expect(openedChat, 'c-saved');
  });

  testWidgets('Favorites failing shows an error and keeps the picker',
      (tester) async {
    when(() => cache.read()).thenAnswer((_) async => null);
    when(() => repo.getOrCreateSavedConversation())
        .thenThrow(Exception('offline'));
    await pumpScreen(tester);
    await tester.tap(find.text('Favorites'));
    await tester.pumpAndSettle();
    expect(find.text("Couldn't open Saved Messages"), findsOneWidget);
    expect(find.text('Send to'), findsOneWidget);
    expect(openedChat, isNull);
  });

  testWidgets('the cross returns to the chat list', (tester) async {
    await pumpScreen(tester);
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();
    expect(find.text('chat list'), findsOneWidget);
  });

  testWidgets('while conversations load: a spinner, not "No chats"',
      (tester) async {
    when(() => bloc.state).thenReturn(const MessengerState(isLoading: true));
    await pumpScreen(tester, settle: false);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('No chats'), findsNothing);
  });

  testWidgets('the list appears when conversations finish loading',
      (tester) async {
    whenListen(
      bloc,
      Stream.fromIterable([
        MessengerState(conversations: [
          _conv('c-anna', 'DIRECT', otherUserName: 'Anna Ivanova'),
        ]),
      ]),
      initialState: const MessengerState(isLoading: true),
    );
    await pumpScreen(tester, settle: false);
    await tester.pumpAndSettle();
    expect(find.text('Anna Ivanova'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('a shared link is shown as the link, not as a file name',
      (tester) async {
    await pumpScreen(tester, files: [
      SharedMediaFile(
          path: 'https://example.com/share-test', type: SharedMediaType.url),
    ]);
    expect(find.text('https://example.com/share-test'), findsOneWidget);
    expect(find.text('share-test'), findsNothing);
    expect(find.byIcon(Icons.link_rounded), findsOneWidget);
    expect(find.byIcon(Icons.attach_file), findsNothing);
  });
}

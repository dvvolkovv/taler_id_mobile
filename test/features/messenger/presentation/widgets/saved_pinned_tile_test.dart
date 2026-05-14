import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:taler_id_mobile/core/storage/saved_conversation_id_cache.dart';
import 'package:taler_id_mobile/l10n/app_localizations.dart';
import 'package:taler_id_mobile/features/messenger/domain/repositories/i_messenger_repository.dart';
import 'package:taler_id_mobile/features/messenger/presentation/widgets/saved_pinned_tile.dart';

class _MockRepo extends Mock implements IMessengerRepository {}
class _MockCache extends Mock implements SavedConversationIdCache {}

Widget _wrap(Widget child) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: Scaffold(body: child),
    );

void main() {
  setUp(() {
    if (GetIt.instance.isRegistered<IMessengerRepository>()) {
      GetIt.instance.unregister<IMessengerRepository>();
    }
    if (GetIt.instance.isRegistered<SavedConversationIdCache>()) {
      GetIt.instance.unregister<SavedConversationIdCache>();
    }
    GetIt.instance.registerLazySingleton<IMessengerRepository>(() => _MockRepo());
    GetIt.instance.registerLazySingleton<SavedConversationIdCache>(() => _MockCache());
  });

  tearDown(() => GetIt.instance.reset());

  testWidgets('renders title and subtitle', (tester) async {
    await tester.pumpWidget(_wrap(const SavedPinnedTile()));
    await tester.pump();
    expect(find.text('Saved Messages'), findsOneWidget);
    expect(find.text('Your private cloud'), findsOneWidget);
    expect(find.byIcon(Icons.bookmark_rounded), findsOneWidget);
  });

  testWidgets('tap calls repo.getOrCreateSavedConversation on cache miss',
      (tester) async {
    final cache = GetIt.instance<SavedConversationIdCache>() as _MockCache;
    final repo = GetIt.instance<IMessengerRepository>() as _MockRepo;

    // Cache miss — returns null, so repo must be consulted.
    when(() => cache.read()).thenAnswer((_) async => null);
    when(() => cache.write(any())).thenAnswer((_) async {});
    when(() => repo.getOrCreateSavedConversation())
        .thenAnswer((_) async => 'saved-conv-id');

    await tester.pumpWidget(_wrap(const SavedPinnedTile()));
    await tester.tap(find.byType(SavedPinnedTile));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    // Repo was called exactly once and the returned id was persisted.
    verify(() => repo.getOrCreateSavedConversation()).called(1);
    verify(() => cache.write('saved-conv-id')).called(1);
  });
}

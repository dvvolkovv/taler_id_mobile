import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:taler_id_mobile/core/di/service_locator.dart';
import 'package:taler_id_mobile/features/interpreter/domain/interpreter_models.dart';
import 'package:taler_id_mobile/features/interpreter/domain/interpreter_repository.dart';
import 'package:taler_id_mobile/features/interpreter/presentation/widgets/interpreter_entry_button.dart';

class _MockInterpreterRepository extends Mock
    implements InterpreterRepository {}

const _enabledCatalog = InterpreterCatalog(
  enabled: true,
  languages: [InterpreterLanguage(code: 'ru', name: 'Русский')],
);
const _disabledCatalog = InterpreterCatalog(enabled: false, languages: []);

void main() {
  late _MockInterpreterRepository repo;

  setUp(() {
    repo = _MockInterpreterRepository();
    sl.registerSingleton<InterpreterRepository>(repo);
    debugResetInterpreterCatalogCache();
  });

  tearDown(() async {
    debugResetInterpreterCatalogCache();
    await sl.reset();
  });

  // The actual bug: `_catalogFuture ??= _fetchCatalog()` memoized a failed
  // fetch forever (`_fetchCatalog` swallows the error and resolves to
  // `null`), so one network blip or a request racing the auth token hid the
  // button until restart. Exercised directly through the
  // `debugLoadInterpreterCatalogForTest` seam rather than by pumping the
  // widget — see the "desktop test host" note below for why.
  group('catalog cache', () {
    test('a failed fetch is not memoized — the next call fetches again',
        () async {
      var call = 0;
      when(() => repo.catalog()).thenAnswer((_) async {
        call++;
        if (call == 1) throw Exception('network blip');
        return _enabledCatalog;
      });

      final first = await debugLoadInterpreterCatalogForTest();
      expect(first, isNull);

      final second = await debugLoadInterpreterCatalogForTest();
      expect(second, _enabledCatalog);
      verify(() => repo.catalog()).called(2);
    });

    test(
        'a successful fetch is memoized — a later call does not hit the '
        'repository again', () async {
      when(() => repo.catalog()).thenAnswer((_) async => _enabledCatalog);

      final first = await debugLoadInterpreterCatalogForTest();
      final second = await debugLoadInterpreterCatalogForTest();

      expect(first, _enabledCatalog);
      expect(second, _enabledCatalog);
      verify(() => repo.catalog()).called(1);
    });

    test(
        'a disabled catalog is a successful fetch too and is memoized the '
        'same way', () async {
      when(() => repo.catalog()).thenAnswer((_) async => _disabledCatalog);

      final first = await debugLoadInterpreterCatalogForTest();
      final second = await debugLoadInterpreterCatalogForTest();

      expect(first, _disabledCatalog);
      expect(second, _disabledCatalog);
      verify(() => repo.catalog()).called(1);
    });
  });

  group('InterpreterEntryButton widget', () {
    // `PlatformUtils.instance.isMobile` reads `dart:io Platform` directly
    // with no fake/override hook anywhere in this codebase (verified:
    // `PlatformUtils.instance.isMobile` is `false` / `isDesktop` is `true`
    // under `flutter test` on the host this suite runs on). `build()`'s own
    // `if (!PlatformUtils.instance.isMobile) return SizedBox.shrink();` gate
    // therefore fires before the `FutureBuilder` — and the cache it drives —
    // is ever reached, so "button shown after a successful fetch" and
    // "hidden on desktop" are indistinguishable through pumpWidget here:
    // both render nothing, and the repository is never even called. That is
    // the "desktop gating" case left untested per the task's own allowance;
    // the cache/catalog contract that actually changed is covered directly
    // above instead.
    testWidgets(
        'renders nothing on this (desktop) test host regardless of catalog '
        'state, without ever calling the repository', (tester) async {
      when(() => repo.catalog()).thenAnswer((_) async => _enabledCatalog);

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: InterpreterEntryButton(onTap: () {})),
      ));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.translate_rounded), findsNothing);
      verifyNever(() => repo.catalog());
    });
  });
}

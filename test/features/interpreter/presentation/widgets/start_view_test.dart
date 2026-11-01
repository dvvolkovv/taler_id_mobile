import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taler_id_mobile/core/theme/app_theme.dart';
import 'package:taler_id_mobile/features/interpreter/domain/interpreter_models.dart';
import 'package:taler_id_mobile/features/interpreter/presentation/widgets/start_view.dart';
import 'package:taler_id_mobile/l10n/app_localizations.dart';

const _catalog = InterpreterCatalog(
  enabled: true,
  languages: [
    InterpreterLanguage(code: 'ru', name: 'Русский'),
    InterpreterLanguage(code: 'en', name: 'English'),
  ],
);

Widget _wrap(Widget child) => MaterialApp(
      theme: AppTheme.dark,
      locale: const Locale('en'),
      supportedLocales: const [Locale('en')],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Scaffold(body: child),
    );

void main() {
  testWidgets('shows "I speak: <language>" for the current selection',
      (tester) async {
    await tester.pumpWidget(_wrap(StartView(
      catalog: _catalog,
      myLang: 'ru',
      onLanguageChosen: (_) {},
      onStart: () {},
      onScan: () {},
      onJoin: (_) {},
    )));

    expect(find.text('I speak: Русский'), findsOneWidget);
  });

  testWidgets('tapping "Start" fires onStart', (tester) async {
    var started = false;
    await tester.pumpWidget(_wrap(StartView(
      catalog: _catalog,
      myLang: 'ru',
      onLanguageChosen: (_) {},
      onStart: () => started = true,
      onScan: () {},
      onJoin: (_) {},
    )));

    await tester.tap(find.text('Start'));
    await tester.pump();

    expect(started, isTrue);
  });

  testWidgets('tapping "Scan QR" fires onScan', (tester) async {
    var scanned = false;
    await tester.pumpWidget(_wrap(StartView(
      catalog: _catalog,
      myLang: 'ru',
      onLanguageChosen: (_) {},
      onStart: () {},
      onScan: () => scanned = true,
      onJoin: (_) {},
    )));

    await tester.tap(find.text('Scan QR'));
    await tester.pump();

    expect(scanned, isTrue);
  });

  testWidgets(
      'tapping the language row opens a picker; picking a language calls onLanguageChosen',
      (tester) async {
    String? chosen;
    await tester.pumpWidget(_wrap(StartView(
      catalog: _catalog,
      myLang: 'ru',
      onLanguageChosen: (code) => chosen = code,
      onStart: () {},
      onScan: () {},
      onJoin: (_) {},
    )));

    await tester.tap(find.text('I speak: Русский'));
    await tester.pumpAndSettle();

    expect(find.text('English'), findsOneWidget);
    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();

    expect(chosen, 'en');
  });

  testWidgets('shows the "both need a voice print, host pays" hint',
      (tester) async {
    await tester.pumpWidget(_wrap(StartView(
      catalog: _catalog,
      myLang: 'ru',
      onLanguageChosen: (_) {},
      onStart: () {},
      onScan: () {},
      onJoin: (_) {},
    )));

    expect(
      find.text('Both of you need a voice print. The host pays per minute.'),
      findsOneWidget,
    );
  });

  // f1: a code arriving via a scanned/deep-linked link must not be silently
  // dropped on the plain start view — see interpreter_screen.dart's wiring
  // and the "Вход (Б)" flow in the spec.
  group('with a pending joinCode', () {
    testWidgets(
        'shows the invited hint and "Join" instead of "Start"; tapping '
        '"Join" fires onJoin with that code', (tester) async {
      String? joined;
      await tester.pumpWidget(_wrap(StartView(
        catalog: _catalog,
        myLang: 'ru',
        joinCode: 'ABCD2345',
        onLanguageChosen: (_) {},
        onStart: () {},
        onScan: () {},
        onJoin: (code) => joined = code,
      )));

      expect(
        find.text(
            'You were invited to a conversation with translation. Choose '
            'your language and join.'),
        findsOneWidget,
      );
      expect(find.text('Start'), findsNothing);
      expect(find.text('Join'), findsOneWidget);

      await tester.tap(find.text('Join'));
      await tester.pump();

      expect(joined, 'ABCD2345');
    });

    testWidgets('"Scan QR" is still shown', (tester) async {
      await tester.pumpWidget(_wrap(StartView(
        catalog: _catalog,
        myLang: 'ru',
        joinCode: 'ABCD2345',
        onLanguageChosen: (_) {},
        onStart: () {},
        onScan: () {},
        onJoin: (_) {},
      )));

      expect(find.text('Scan QR'), findsOneWidget);
    });
  });

  testWidgets('without a joinCode, behaviour is unchanged: "Start" is shown, '
      'no invited hint, no "Join"', (tester) async {
    await tester.pumpWidget(_wrap(StartView(
      catalog: _catalog,
      myLang: 'ru',
      onLanguageChosen: (_) {},
      onStart: () {},
      onScan: () {},
      onJoin: (_) {},
    )));

    expect(find.text('Start'), findsOneWidget);
    expect(find.text('Join'), findsNothing);
    expect(
      find.text(
          'You were invited to a conversation with translation. Choose '
          'your language and join.'),
      findsNothing,
    );
  });
}

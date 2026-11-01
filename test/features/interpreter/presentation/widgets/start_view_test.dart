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
    )));

    expect(
      find.text('Both of you need a voice print. The host pays per minute.'),
      findsOneWidget,
    );
  });
}

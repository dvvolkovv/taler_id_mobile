import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taler_id_mobile/core/theme/app_theme.dart';
import 'package:taler_id_mobile/features/interpreter/domain/interpreter_models.dart';
import 'package:taler_id_mobile/features/interpreter/presentation/widgets/ended_view.dart';
import 'package:taler_id_mobile/l10n/app_localizations.dart';

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
  testWidgets('shows the reason text, duration and host spend', (tester) async {
    await tester.pumpWidget(_wrap(EndedView(
      reason: InterpreterEndReason.partnerLeft,
      duration: const Duration(minutes: 3, seconds: 20),
      spentPlanck: '24000000',
      isHost: true,
      onDone: () {},
      onAgain: () {},
    )));

    expect(find.text('Your partner disconnected'), findsOneWidget);
    expect(find.text('Duration: 3:20'), findsOneWidget);
    expect(find.text('Spent: 24 μTAL'), findsOneWidget);
  });

  testWidgets('a guest never sees a spent amount, even if one is passed',
      (tester) async {
    await tester.pumpWidget(_wrap(EndedView(
      reason: InterpreterEndReason.hangup,
      duration: const Duration(seconds: 42),
      spentPlanck: '24000000',
      isHost: false,
      onDone: () {},
      onAgain: () {},
    )));

    expect(find.textContaining('μTAL'), findsNothing);
  });

  testWidgets('a null duration omits the duration line entirely',
      (tester) async {
    await tester.pumpWidget(_wrap(EndedView(
      reason: InterpreterEndReason.expired,
      duration: null,
      spentPlanck: null,
      isHost: true,
      onDone: () {},
      onAgain: () {},
    )));

    expect(find.textContaining('Duration:'), findsNothing);
  });

  testWidgets('"Done" pops, "Again" goes back to start', (tester) async {
    var done = false;
    var again = false;
    await tester.pumpWidget(_wrap(EndedView(
      reason: InterpreterEndReason.hangup,
      duration: const Duration(seconds: 10),
      spentPlanck: null,
      isHost: false,
      onDone: () => done = true,
      onAgain: () => again = true,
    )));

    await tester.tap(find.text('Done'));
    await tester.pump();
    expect(done, isTrue);
    expect(again, isFalse);

    await tester.tap(find.text('Again'));
    await tester.pump();
    expect(again, isTrue);
  });
}

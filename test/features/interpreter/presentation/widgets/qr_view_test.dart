import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:taler_id_mobile/core/theme/app_theme.dart';
import 'package:taler_id_mobile/features/interpreter/presentation/widgets/qr_view.dart';
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
  final fixedNow = DateTime(2026, 11, 1, 12, 0, 0);

  testWidgets('renders the QR of the interp link and the show-code text',
      (tester) async {
    await tester.pumpWidget(_wrap(QrView(
      code: 'ABCD1234',
      expiresAt: fixedNow.add(const Duration(minutes: 5)),
      onNewCode: () {},
      now: () => fixedNow,
    )));
    await tester.pump();

    expect(find.text('Show this code to your partner'), findsOneWidget);
    // QrImageView keeps the data it was built with private — a render
    // smoke-check is all that's observable from outside; `interpreterLink`
    // itself (the `talerid://interp/<code>` format) is covered by
    // `interpreter_code_test.dart`.
    expect(find.byType(QrImageView), findsOneWidget);
  });

  testWidgets('shows a live mm:ss countdown from expiresAt', (tester) async {
    await tester.pumpWidget(_wrap(QrView(
      code: 'ABCD1234',
      expiresAt: fixedNow.add(const Duration(minutes: 4, seconds: 32)),
      onNewCode: () {},
      now: () => fixedNow,
    )));
    await tester.pump();

    expect(find.text('4:32'), findsOneWidget);
  });

  testWidgets('shows "Code expired" once expiresAt is in the past',
      (tester) async {
    await tester.pumpWidget(_wrap(QrView(
      code: 'ABCD1234',
      expiresAt: fixedNow.subtract(const Duration(seconds: 1)),
      onNewCode: () {},
      now: () => fixedNow,
    )));
    await tester.pump();

    expect(find.text('Code expired'), findsOneWidget);
    // The new-code button stays available after expiry — that's the only
    // way out of an expired code.
    expect(find.text('New code'), findsOneWidget);
  });

  testWidgets('tapping "New code" fires onNewCode', (tester) async {
    var pressed = false;
    await tester.pumpWidget(_wrap(QrView(
      code: 'ABCD1234',
      expiresAt: fixedNow.add(const Duration(minutes: 5)),
      onNewCode: () => pressed = true,
      now: () => fixedNow,
    )));
    await tester.pump();

    await tester.tap(find.text('New code'));
    await tester.pump();

    expect(pressed, isTrue);
  });
}

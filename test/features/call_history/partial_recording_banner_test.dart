import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taler_id_mobile/features/call_history/presentation/widgets/partial_recording_banner.dart';
import 'package:taler_id_mobile/l10n/app_localizations.dart';

Future<void> pumpBanner(WidgetTester tester, Widget child, Locale locale) async {
  await tester.pumpWidget(MaterialApp(
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  ));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('compact label is localized in English', (tester) async {
    await pumpBanner(
      tester,
      const PartialRecordingBanner(compact: true),
      const Locale('en'),
    );

    expect(find.text('Partial recording'), findsOneWidget);
    expect(find.textContaining('Some audio tracks'), findsNothing);
  });

  testWidgets('full warning is localized in Russian', (tester) async {
    await pumpBanner(
      tester,
      const PartialRecordingBanner(),
      const Locale('ru'),
    );

    expect(find.text('Запись частичная'), findsOneWidget);
    expect(
      find.text('Часть аудиодорожек не обработана. Доступные запись и протокол могут быть неполными.'),
      findsOneWidget,
    );
  });

  testWidgets('compact English label does not overflow at 256 pt with textScaler 2.0', (tester) async {
    await pumpBanner(
      tester,
      const MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(2.0)),
        child: SizedBox(
          width: 256,
          child: PartialRecordingBanner(compact: true),
        ),
      ),
      const Locale('en'),
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets('compact Russian label does not overflow at 256 pt with textScaler 2.0', (tester) async {
    await pumpBanner(
      tester,
      const MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(2.0)),
        child: SizedBox(
          width: 256,
          child: PartialRecordingBanner(compact: true),
        ),
      ),
      const Locale('ru'),
    );

    expect(tester.takeException(), isNull);
  });
}

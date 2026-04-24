import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taler_id_mobile/l10n/app_localizations.dart';
import 'package:taler_id_mobile/features/messenger/domain/entities/analyst_events.dart';
import 'package:taler_id_mobile/features/messenger/presentation/widgets/analyst_seam_widget.dart';

Widget _wrap(Widget child, {Locale locale = const Locale('en')}) => MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    );

void main() {
  testWidgets('renders English pluralized labels and duration', (tester) async {
    await tester.pumpWidget(_wrap(const AnalystSeamWidget(seam: AnalystSeam(
      conversationId: 'c', messageId: 'm',
      steps: [SeamStep(kind: 'search', count: 2), SeamStep(kind: 'file', count: 1)],
      durationMs: 12400,
    ))));
    await tester.pumpAndSettle();
    expect(find.textContaining('2 searches'), findsOneWidget);
    expect(find.textContaining('1 file'), findsOneWidget);
    expect(find.textContaining('12s'), findsOneWidget);
  });

  testWidgets('renders Russian pluralized labels (few form)', (tester) async {
    await tester.pumpWidget(_wrap(const AnalystSeamWidget(seam: AnalystSeam(
      conversationId: 'c', messageId: 'm',
      steps: [SeamStep(kind: 'cmd', count: 3)],
      durationMs: 5000,
    )), locale: const Locale('ru')));
    await tester.pumpAndSettle();
    expect(find.textContaining('3 команды'), findsOneWidget);
    expect(find.textContaining('5 с'), findsOneWidget);
  });
}

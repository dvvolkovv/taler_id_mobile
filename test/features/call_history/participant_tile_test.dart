import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taler_id_mobile/core/theme/app_theme.dart';
import 'package:taler_id_mobile/features/call_history/presentation/screens/call_history_screen.dart';
import 'package:taler_id_mobile/l10n/app_localizations.dart';

Widget _wrap(Widget child) => MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    );

void main() {
  // AppColorsExtension.dark exists per lib/core/theme/app_theme.dart.
  final colors = AppColorsExtension.dark;

  group('ParticipantTile', () {
    testWidgets('non-self participant is tappable (InkWell present)', (tester) async {
      await tester.pumpWidget(_wrap(
        ParticipantTile(
          data: const {'displayName': 'Alice', 'userId': 'user-A'},
          currentUserId: 'user-ME',
          colors: colors,
          youSuffix: '(You)',
          unknownLabel: 'Unknown',
        ),
      ));

      expect(find.byType(InkWell), findsOneWidget);
      expect(find.text('Alice'), findsOneWidget);
      expect(find.textContaining('(You)'), findsNothing);
    });

    testWidgets('self participant is not tappable and shows youSuffix', (tester) async {
      await tester.pumpWidget(_wrap(
        ParticipantTile(
          data: const {'displayName': 'Me', 'userId': 'user-ME'},
          currentUserId: 'user-ME',
          colors: colors,
          youSuffix: '(You)',
          unknownLabel: 'Unknown',
        ),
      ));

      expect(find.byType(InkWell), findsNothing);
      expect(find.text('Me (You)'), findsOneWidget);
    });

    testWidgets('participant with missing userId is not tappable', (tester) async {
      await tester.pumpWidget(_wrap(
        ParticipantTile(
          data: const {'displayName': 'Bob'},
          currentUserId: 'user-ME',
          colors: colors,
          youSuffix: '(You)',
          unknownLabel: 'Unknown',
        ),
      ));

      expect(find.byType(InkWell), findsNothing);
      expect(find.text('Bob'), findsOneWidget);
    });

    testWidgets('participant with missing displayName falls back to unknownLabel', (tester) async {
      await tester.pumpWidget(_wrap(
        ParticipantTile(
          data: const {'userId': 'user-X'},
          currentUserId: 'user-ME',
          colors: colors,
          youSuffix: '(You)',
          unknownLabel: 'Unknown',
        ),
      ));

      expect(find.text('Unknown'), findsOneWidget);
      expect(find.byType(InkWell), findsOneWidget);
    });
  });
}

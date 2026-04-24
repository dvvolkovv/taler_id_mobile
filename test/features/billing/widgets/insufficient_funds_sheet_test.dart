import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:taler_id_mobile/features/billing/presentation/widgets/insufficient_funds_sheet.dart';
import 'package:taler_id_mobile/l10n/app_localizations.dart';

/// Builds a MaterialApp.router with a fake /billing/purchase route
/// so the "Пополнить" button has a destination to go to in tests.
///
/// Forces locale to `ru` so the sheet renders Russian strings we can
/// assert against literally.
GoRouter _buildRouter({required VoidCallback onHome}) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (ctx, __) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () {
                onHome();
                InsufficientFundsSheet.show(
                  ctx,
                  featureKey: 'voice_assistant',
                  requiredPlanck: '26000000',
                  availablePlanck: '1000000',
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
      GoRoute(
        path: '/billing/purchase',
        builder: (_, __) => const Scaffold(body: Text('purchase screen')),
      ),
    ],
  );
}

MaterialApp _wrap(GoRouter router) {
  return MaterialApp.router(
    routerConfig: router,
    locale: const Locale('ru'),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
  );
}

void main() {
  testWidgets('InsufficientFundsSheet renders title, description and CTAs',
      (tester) async {
    final router = _buildRouter(onHome: () {});
    await tester.pumpWidget(_wrap(router));

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('Недостаточно средств'), findsOneWidget);
    expect(
      find.text('Для использования этой функции нужно пополнить баланс.'),
      findsOneWidget,
    );
    // Required (26000000 planck → 26 μTAL) and available (1000000 → 1 μTAL).
    expect(find.textContaining('Нужно: 26 μTAL'), findsOneWidget);
    expect(find.textContaining('Есть: 1 μTAL'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Пополнить'), findsOneWidget);
    expect(find.widgetWithText(TextButton, 'Отмена'), findsOneWidget);
  });

  testWidgets('Tapping Отмена dismisses the sheet', (tester) async {
    final router = _buildRouter(onHome: () {});
    await tester.pumpWidget(_wrap(router));

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('Недостаточно средств'), findsOneWidget);

    await tester.tap(find.widgetWithText(TextButton, 'Отмена'));
    await tester.pumpAndSettle();

    expect(find.text('Недостаточно средств'), findsNothing);
  });

  testWidgets('Tapping Пополнить pops sheet and navigates to /billing/purchase',
      (tester) async {
    final router = _buildRouter(onHome: () {});
    await tester.pumpWidget(_wrap(router));

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Пополнить'));
    await tester.pumpAndSettle();

    expect(find.text('purchase screen'), findsOneWidget);
    expect(find.text('Недостаточно средств'), findsNothing);
  });
}

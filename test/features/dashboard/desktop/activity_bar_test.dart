import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:taler_id_mobile/core/utils/constants.dart';
import 'package:taler_id_mobile/features/dashboard/desktop/widgets/activity_bar.dart';

void main() {
  testWidgets('ActivityBar exposes current mobile feature routes on desktop',
      (tester) async {
    final router = GoRouter(
      initialLocation: RouteConstants.messenger,
      routes: [
        GoRoute(
          path: RouteConstants.messenger,
          builder: (_, __) => const _Harness(RouteConstants.messenger),
        ),
        GoRoute(
          path: RouteConstants.wallet,
          builder: (_, __) => const _Harness(RouteConstants.wallet),
        ),
        GoRoute(
          path: RouteConstants.aiToggles,
          builder: (_, __) => const _Harness(RouteConstants.aiToggles),
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));

    expect(find.byTooltip('Messenger'), findsOneWidget);
    expect(find.byTooltip('Calls'), findsOneWidget);
    expect(find.byTooltip('Assistant'), findsOneWidget);
    expect(find.byTooltip('Calendar'), findsOneWidget);
    expect(find.byTooltip('Wallet'), findsOneWidget);
    expect(find.byTooltip('Notes'), findsOneWidget);
    expect(find.byTooltip('Mail'), findsOneWidget);
    expect(find.byTooltip('Contacts'), findsOneWidget);
    expect(find.byTooltip('Profile'), findsOneWidget);
    expect(find.byTooltip('AI settings'), findsOneWidget);
    expect(find.byTooltip('Settings'), findsOneWidget);

    await tester.tap(find.byTooltip('Wallet'));
    await tester.pumpAndSettle();
    expect(router.routerDelegate.currentConfiguration.uri.path,
        RouteConstants.wallet);

    await tester.ensureVisible(find.byTooltip('AI settings'));
    await tester.tap(find.byTooltip('AI settings'));
    await tester.pumpAndSettle();
    expect(router.routerDelegate.currentConfiguration.uri.path,
        RouteConstants.aiToggles);
  });
}

class _Harness extends StatelessWidget {
  final String currentRoute;
  const _Harness(this.currentRoute);

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: ActivityBar(currentRoute: currentRoute));
  }
}

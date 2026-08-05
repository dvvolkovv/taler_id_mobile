import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:taler_id_mobile/core/keyboard_shortcuts/shortcut_dispatcher.dart';
import 'package:taler_id_mobile/core/utils/constants.dart';

void main() {
  testWidgets('desktop section shortcuts include wallet and AI settings',
      (tester) async {
    final router = GoRouter(
      initialLocation: RouteConstants.messenger,
      routes: [
        for (final route in [
          RouteConstants.messenger,
          RouteConstants.wallet,
          RouteConstants.aiToggles,
        ])
          GoRoute(
            path: route,
            builder: (_, __) => ShortcutDispatcher(
              child: Scaffold(body: Text(route)),
            ),
          ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    final modifier =
        Platform.isMacOS ? LogicalKeyboardKey.meta : LogicalKeyboardKey.control;

    await tester.sendKeyDownEvent(modifier);
    await tester.sendKeyEvent(LogicalKeyboardKey.digit5);
    await tester.sendKeyUpEvent(modifier);
    await tester.pumpAndSettle();
    expect(
      router.routerDelegate.currentConfiguration.uri.path,
      RouteConstants.wallet,
    );

    await tester.sendKeyDownEvent(modifier);
    await tester.sendKeyEvent(LogicalKeyboardKey.digit6);
    await tester.sendKeyUpEvent(modifier);
    await tester.pumpAndSettle();
    expect(
      router.routerDelegate.currentConfiguration.uri.path,
      RouteConstants.aiToggles,
    );
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taler_id_mobile/core/services/call_orientation_service.dart';
import 'package:taler_id_mobile/core/theme/app_theme.dart';
import 'package:taler_id_mobile/features/voice/presentation/widgets/call_rotation_lock_button.dart';
import 'package:taler_id_mobile/l10n/app_localizations.dart';

Widget _wrap(Widget child) => MaterialApp(
      theme: AppTheme.dark,
      locale: const Locale('en'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Scaffold(body: Center(child: child)),
    );

// Never init()-ed: no Hive box, the choice lives in memory — all the button
// needs. isSupported: false keeps SystemChrome out of the test.
CallOrientationService _service() =>
    CallOrientationService(isSupported: false, isIOS: false);

void main() {
  for (final floating in [false, true]) {
    final kind = floating ? 'floating' : 'app bar';
    Widget button(CallOrientationService s) => floating
        ? CallRotationLockButton.floating(service: s)
        : CallRotationLockButton.appBar(service: s);

    testWidgets('$kind: rotation allowed — rotate icon, tap locks', (t) async {
      final s = _service();
      await t.pumpWidget(_wrap(button(s)));
      expect(find.byIcon(Icons.screen_rotation_rounded), findsOneWidget);
      expect(find.byTooltip('Lock rotation'), findsOneWidget);

      await t.tap(find.byKey(const Key('call-rotation-lock')));
      await t.pump();

      expect(s.rotationLocked.value, isTrue);
      expect(find.byIcon(Icons.screen_lock_portrait_rounded), findsOneWidget);
      expect(find.byTooltip('Allow rotation'), findsOneWidget);
    });

    testWidgets('$kind: locked — tap allows rotation again', (t) async {
      final s = _service();
      await s.setRotationLocked(true);
      await t.pumpWidget(_wrap(button(s)));
      expect(find.byIcon(Icons.screen_lock_portrait_rounded), findsOneWidget);

      await t.tap(find.byKey(const Key('call-rotation-lock')));
      await t.pump();

      expect(s.rotationLocked.value, isFalse);
      expect(find.byIcon(Icons.screen_rotation_rounded), findsOneWidget);
    });
  }

  testWidgets('follows a change made elsewhere (the in-call assistant)',
      (t) async {
    final s = _service();
    await t.pumpWidget(_wrap(CallRotationLockButton.appBar(service: s)));

    await s.setRotationLocked(true);
    await t.pump();

    expect(find.byIcon(Icons.screen_lock_portrait_rounded), findsOneWidget);
  });

  testWidgets('floating: a screen reader hears a button named by the action',
      (t) async {
    final semantics = t.ensureSemantics();
    final s = _service();
    await t.pumpWidget(_wrap(CallRotationLockButton.floating(service: s)));

    expect(
      t.getSemantics(find.byKey(const Key('call-rotation-lock'))),
      containsSemantics(
        isButton: true,
        label: 'Lock rotation',
        hasTapAction: true,
      ),
    );
    semantics.dispose();
  });
}

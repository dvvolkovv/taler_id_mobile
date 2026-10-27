import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taler_id_mobile/core/theme/app_theme.dart';
import 'package:taler_id_mobile/features/dashboard/presentation/widgets/update_card.dart';
import 'package:taler_id_mobile/l10n/app_localizations.dart';

import '../../core/services/update_fakes.dart';

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
      home: Scaffold(body: Align(alignment: Alignment.bottomCenter, child: child)),
    );

void main() {
  late UpdateRig rig;
  setUp(() => rig = UpdateRig());
  tearDown(() => rig.calls.close());

  testWidgets('nothing advertised, nothing shown', (t) async {
    final c = rig.controller();
    await t.pumpWidget(_wrap(UpdateCard(controller: c)));
    expect(find.byKey(const Key('update-card')), findsNothing);
    c.dispose();
  });

  testWidgets('available: Update starts the download, close hides the card', (t) async {
    final c = rig.controller()..setInfo(info(notes: 'Fixes'));
    await t.pumpWidget(_wrap(UpdateCard(controller: c)));
    expect(find.byKey(const Key('update-card')), findsOneWidget);
    expect(find.byKey(const Key('update-card-notes')), findsOneWidget);

    await t.tap(find.byKey(const Key('update-card-close')));
    await t.pump();
    expect(find.byKey(const Key('update-card')), findsNothing);

    c.setInfo(info(v: '1.1.38', b: 239));
    await t.pump();
    await t.tap(find.byKey(const Key('update-card-action')));
    await t.pump();
    expect(rig.platform.starts, hasLength(1));
    c.dispose();
  });

  testWidgets('downloading: percent and progress bar, no close button', (t) async {
    rig.platform.next = running(0.42);
    final c = rig.controller()..setInfo(info());
    await c.onResumed();
    await t.pumpWidget(_wrap(UpdateCard(controller: c)));

    expect(find.text('Downloading 42%'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(find.byKey(const Key('update-card-close')), findsNothing);
    c.dispose();
  });

  testWidgets('ready: Install installs', (t) async {
    rig.inCall = true; // keeps the automatic offer out of the way
    rig.platform.next = ready();
    final c = rig.controller()..setInfo(info());
    await c.onResumed();
    await t.pumpWidget(_wrap(UpdateCard(controller: c)));

    expect(find.text('Install'), findsOneWidget);
    await t.tap(find.byKey(const Key('update-card-action')));
    await t.pump();
    expect(rig.installs, hasLength(1));
    c.dispose();
  });

  testWidgets('failed: Retry starts again', (t) async {
    rig.platform.next = const UpdateDownloadStatusFailed();
    final c = rig.controller()..setInfo(info());
    await c.onResumed();
    await t.pumpWidget(_wrap(UpdateCard(controller: c)));

    expect(find.text("Couldn't download the update"), findsOneWidget);
    await t.tap(find.byKey(const Key('update-card-action')));
    await t.pump();
    expect(rig.platform.starts, hasLength(1));
    c.dispose();
  });
}

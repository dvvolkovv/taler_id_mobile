import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taler_id_mobile/core/services/apk_installer_service.dart';
import 'package:taler_id_mobile/core/services/app_update_controller.dart';
import 'package:taler_id_mobile/core/theme/app_theme.dart';
import 'package:taler_id_mobile/features/dashboard/presentation/widgets/update_card.dart';
import 'package:taler_id_mobile/l10n/app_localizations.dart';

import '../../core/services/update_fakes.dart';

Widget _wrap(Widget child, {Locale locale = const Locale('en'), double textScale = 1}) => MaterialApp(
      theme: AppTheme.dark,
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, app) => MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(textScale)),
        child: app!,
      ),
      home: Scaffold(
        body: Align(
          alignment: Alignment.bottomCenter,
          child: Padding(padding: const EdgeInsets.all(16), child: child),
        ),
      ),
    );

void main() {
  late UpdateRig rig;
  setUp(() => rig = UpdateRig());
  tearDown(() => rig.calls.close());

  testWidgets('nothing advertised, nothing shown', (t) async {
    final c = rig.controller();
    addTearDown(c.dispose);
    await t.pumpWidget(_wrap(UpdateCard(controller: c)));
    expect(find.byKey(const Key('update-card')), findsNothing);
  });

  testWidgets('available: Update starts the download, close hides the card', (t) async {
    final c = rig.controller()..setInfo(info(notes: 'Fixes'));
    addTearDown(c.dispose);
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
  });

  testWidgets('downloading: percent and progress bar, no close button', (t) async {
    rig.platform.next = running(0.42);
    final c = rig.controller()..setInfo(info());
    addTearDown(c.dispose);
    await c.onResumed();
    await t.pumpWidget(_wrap(UpdateCard(controller: c)));

    expect(find.text('Downloading 42%'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(find.byKey(const Key('update-card-close')), findsNothing);
    // Still "downloading": the controller's polling timer is live, and
    // addTearDown's dispose() runs after the framework's no-pending-timer
    // check — too late to satisfy it. Pausing (as the real app lifecycle
    // would on backgrounding) stops the timer now; addTearDown disposes once.
    c.onPaused();
  });

  testWidgets('ready: Install installs', (t) async {
    rig.inCall = true; // keeps the automatic offer out of the way
    rig.platform.next = ready();
    final c = rig.controller()..setInfo(info());
    addTearDown(c.dispose);
    await c.onResumed();
    await t.pumpWidget(_wrap(UpdateCard(controller: c)));

    expect(find.text('Install'), findsOneWidget);
    await t.tap(find.byKey(const Key('update-card-action')));
    await t.pump();
    expect(rig.installs, hasLength(1));
  });

  testWidgets('failed: Retry starts again', (t) async {
    rig.platform.next = const UpdateDownloadStatusFailed();
    final c = rig.controller()..setInfo(info());
    addTearDown(c.dispose);
    await c.onResumed();
    await t.pumpWidget(_wrap(UpdateCard(controller: c)));

    expect(find.text("Couldn't download the update"), findsOneWidget);
    await t.tap(find.byKey(const Key('update-card-action')));
    await t.pump();
    expect(rig.platform.starts, hasLength(1));
    // Retry re-entered "downloading": same live-timer reason as above.
    c.onPaused();
  });

  testWidgets('large fonts and a long translation keep the title readable, nothing overflows',
      (t) async {
    t.view.physicalSize = const Size(960, 1920);
    t.view.devicePixelRatio = 3; // 320 × 640 dp
    addTearDown(t.view.reset);
    final c = rig.controller()..setInfo(info(notes: 'Fixes'));
    addTearDown(c.dispose);

    await t.pumpWidget(_wrap(UpdateCard(controller: c), locale: const Locale('ta'), textScale: 2));

    expect(t.takeException(), isNull);
    final title = find
        .descendant(of: find.byKey(const Key('update-card')), matching: find.byType(Text))
        .first;
    expect(t.getSize(title).width, greaterThan(100));
    // Confirms this did go two-row: the action sits below the title, not beside it.
    final actionCenter = t.getCenter(find.byKey(const Key('update-card-action')));
    final titleCenter = t.getCenter(title);
    expect(actionCenter.dy, greaterThan(titleCenter.dy));
  });

  testWidgets('an ordinary 360dp phone at normal text scale stays one row', (t) async {
    t.view.physicalSize = const Size(1080, 1920);
    t.view.devicePixelRatio = 3; // 360 × 640 dp
    addTearDown(t.view.reset);
    final c = rig.controller()..setInfo(info());
    addTearDown(c.dispose);

    await t.pumpWidget(_wrap(UpdateCard(controller: c)));

    expect(t.takeException(), isNull);
    final title = find
        .descendant(of: find.byKey(const Key('update-card')), matching: find.byType(Text))
        .first;
    final actionCenter = t.getCenter(find.byKey(const Key('update-card-action')));
    final titleCenter = t.getCenter(title);
    expect((actionCenter.dy - titleCenter.dy).abs(), lessThan(12));
    expect(t.getSize(find.byKey(const Key('update-card'))).height, lessThan(100));
  });

  testWidgets('an ordinary 360dp phone in Russian at normal text scale stays one row', (t) async {
    t.view.physicalSize = const Size(1080, 1920);
    t.view.devicePixelRatio = 3; // 360 × 640 dp
    addTearDown(t.view.reset);
    final c = rig.controller()..setInfo(info());
    addTearDown(c.dispose);

    await t.pumpWidget(_wrap(UpdateCard(controller: c), locale: const Locale('ru')));

    expect(t.takeException(), isNull);
    final title = find
        .descendant(of: find.byKey(const Key('update-card')), matching: find.byType(Text))
        .first;
    final actionCenter = t.getCenter(find.byKey(const Key('update-card-action')));
    final titleCenter = t.getCenter(title);
    expect((actionCenter.dy - titleCenter.dy).abs(), lessThan(12));
    expect(t.getSize(find.byKey(const Key('update-card'))).height, lessThan(100));
  });

  testWidgets('controls are labelled and big enough to tap', (t) async {
    final semantics = t.ensureSemantics();
    final c = rig.controller()..setInfo(info(notes: 'Fixes'));
    addTearDown(c.dispose);
    await t.pumpWidget(_wrap(UpdateCard(controller: c)));

    await expectLater(t, meetsGuideline(androidTapTargetGuideline));
    await expectLater(t, meetsGuideline(labeledTapTargetGuideline));
    semantics.dispose();
  });

  testWidgets('installing: a spinner, no buttons', (t) async {
    rig.installGate = Completer<ApkInstallResponse>();
    rig.platform.next = ready();
    final c = rig.controller()..setInfo(info());
    addTearDown(c.dispose);
    await c.onResumed(); // the automatic offer starts the install and waits at the gate
    await t.pumpWidget(_wrap(UpdateCard(controller: c)));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byKey(const Key('update-card-action')), findsNothing);
    expect(find.byKey(const Key('update-card-close')), findsNothing);

    rig.installGate!.complete(const ApkInstallResponse(ApkInstallStatus.aborted, ''));
    await t.pump();
  });

  testWidgets('downloading: Hide removes the card, the download goes on', (t) async {
    rig.platform.next = running(0.42);
    final c = rig.controller()..setInfo(info());
    addTearDown(c.dispose);
    await c.onResumed();
    await t.pumpWidget(_wrap(UpdateCard(controller: c)));

    await t.tap(find.byKey(const Key('update-card-action')));
    await t.pump();

    expect(find.byKey(const Key('update-card')), findsNothing);
    expect(c.phase, UpdatePhase.downloading);
    // The download (and its polling timer) deliberately keeps going; stop
    // it for the test's own sake only (see note above).
    c.onPaused();
  });

  testWidgets("What's new opens the notes", (t) async {
    final c = rig.controller()..setInfo(info(notes: 'Fixes calls'));
    addTearDown(c.dispose);
    await t.pumpWidget(_wrap(UpdateCard(controller: c)));

    await t.tap(find.byKey(const Key('update-card-notes')));
    await t.pumpAndSettle();

    expect(find.text('Fixes calls'), findsOneWidget);
  });

  testWidgets("no What's new link without notes", (t) async {
    final c = rig.controller()..setInfo(info());
    addTearDown(c.dispose);
    await t.pumpWidget(_wrap(UpdateCard(controller: c)));

    expect(find.byKey(const Key('update-card-notes')), findsNothing);
  });

  testWidgets('a remembered failure before /app/version answers offers no dead Retry', (t) async {
    rig.platform.next = const UpdateDownloadStatusFailed();
    final c = rig.controller(); // no setInfo: /app/version has not answered yet
    addTearDown(c.dispose);
    await c.onResumed();
    await t.pumpWidget(_wrap(UpdateCard(controller: c)));

    expect(find.byKey(const Key('update-card')), findsOneWidget);
    expect(find.byKey(const Key('update-card-action')), findsNothing);
    expect(find.byKey(const Key('update-card-close')), findsOneWidget);
  });

  Future<void> showResult(WidgetTester t, ApkInstallResponse res) async {
    await t.pumpWidget(_wrap(Builder(
      builder: (ctx) => TextButton(
        onPressed: () => showUpdateInstallResult(ctx, res, 'talerid-1.1.37.apk'),
        child: const Text('go'),
      ),
    )));
    await t.tap(find.text('go'));
    await t.pumpAndSettle();
  }

  testWidgets('install result: success and a declined prompt say nothing', (t) async {
    await showResult(t, const ApkInstallResponse(ApkInstallStatus.success, ''));
    expect(find.byType(AlertDialog), findsNothing);
    await showResult(t, const ApkInstallResponse(ApkInstallStatus.aborted, ''));
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('install result: a signature conflict explains the reinstall', (t) async {
    await showResult(
        t, const ApkInstallResponse(ApkInstallStatus.conflict, '', savedToDownloads: true));
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text("Couldn't update in place"), findsOneWidget);
    expect(find.textContaining('talerid-1.1.37.apk'), findsOneWidget);
  });

  testWidgets('install result: a conflict without a copy in Downloads points to the download page',
      (t) async {
    await showResult(t, const ApkInstallResponse(ApkInstallStatus.conflict, ''));
    expect(find.text("Couldn't update in place"), findsOneWidget);
    expect(
      find.text("The installed version is signed with a different certificate, so Android won't "
          'update it. Uninstall the app in Settings → Apps → Taler ID and install it again from '
          'the download page. You only need to do this once.'),
      findsOneWidget,
    );
    expect(find.textContaining('talerid-1.1.37.apk'), findsNothing);
  });

  testWidgets('install result: other failures name the reason, or the status without a message',
      (t) async {
    await showResult(t,
        const ApkInstallResponse(ApkInstallStatus.failureUnknown, '', savedToDownloads: true));
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text('Install failed'), findsOneWidget);
    expect(find.textContaining('failureUnknown'), findsOneWidget);
    expect(find.textContaining('talerid-1.1.37.apk'), findsOneWidget);
  });

  testWidgets('install result: a failure without a copy in Downloads names only the reason',
      (t) async {
    await showResult(t, const ApkInstallResponse(ApkInstallStatus.storage, 'no space'));
    expect(find.text('Install failed'), findsOneWidget);
    expect(find.text('no space'), findsOneWidget);
    expect(find.textContaining('talerid-1.1.37.apk'), findsNothing);
  });

  testWidgets('install result: a file not signed by us says so and names no file', (t) async {
    await showResult(t, const ApkInstallResponse(ApkInstallStatus.invalid, 'untrusted_signature'));
    expect(find.text('Install failed'), findsOneWidget);
    expect(
      find.text('The downloaded file failed the signature check and was deleted. Try updating again.'),
      findsOneWidget,
    );
    expect(find.textContaining('untrusted_signature'), findsNothing);
    expect(find.textContaining('talerid-1.1.37.apk'), findsNothing);
  });
}

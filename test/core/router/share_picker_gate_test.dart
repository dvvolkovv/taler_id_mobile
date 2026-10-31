import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:taler_id_mobile/core/router/share_picker_gate.dart';
import 'package:taler_id_mobile/core/services/pending_share.dart';
import 'package:taler_id_mobile/core/utils/constants.dart';

void main() {
  test('the picker opens over ordinary screens', () {
    for (final stack in [
      [RouteConstants.assistant],
      [RouteConstants.messenger],
      ['/dashboard/messenger/c-1'],
      [RouteConstants.messengerShare],
      [RouteConstants.settings],
      [RouteConstants.calendar],
      ['/dashboard/messenger/c-1', '/dashboard/user/u-1'],
    ]) {
      expect(canOpenSharePicker(stack), isTrue, reason: '$stack');
    }
  });

  test('the picker waits while a call screen is anywhere on the stack', () {
    for (final stack in [
      [RouteConstants.voice],
      ['/dashboard/messenger/c-1', RouteConstants.voice],
      ['/dashboard/messenger/c-1', RouteConstants.voice, '/other'],
      ['/group-call/gc-1'],
      ['/dashboard/messenger/c-1', '/group-call/gc-1/lobby'],
    ]) {
      expect(canOpenSharePicker(stack), isFalse, reason: '$stack');
    }
  });

  testWidgets('stackLocations sees call screens opened with push or go',
      (tester) async {
    final router = GoRouter(
      initialLocation: '/dashboard/messenger/c-1',
      routes: [
        GoRoute(
            path: RouteConstants.voice,
            builder: (_, __) => const Text('voice')),
        GoRoute(
            path: '/group-call/:id',
            builder: (_, __) => const Text('group call')),
        GoRoute(path: '/other', builder: (_, __) => const Text('other')),
        ShellRoute(
          builder: (_, __, child) => Scaffold(body: child),
          routes: [
            GoRoute(
              path: RouteConstants.messenger,
              builder: (_, __) => const Text('list'),
              routes: [
                GoRoute(path: ':id', builder: (_, __) => const Text('chat')),
              ],
            ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    bool canOpen() => canOpenSharePicker(
        stackLocations(router.routerDelegate.currentConfiguration));

    expect(canOpen(), isTrue);

    router.push('/dashboard/messenger/c-2');
    await tester.pumpAndSettle();
    expect(stackLocations(router.routerDelegate.currentConfiguration),
        contains('/dashboard/messenger/c-2'),
        reason: 'a screen pushed inside the shell is listed too');
    expect(canOpen(), isTrue);
    router.pop();
    await tester.pumpAndSettle();

    router.push('${RouteConstants.voice}?room=r1');
    await tester.pumpAndSettle();
    expect(find.text('voice'), findsOneWidget);
    expect(canOpen(), isFalse, reason: 'call screen pushed over the chat');

    router.push('/other');
    await tester.pumpAndSettle();
    expect(canOpen(), isFalse, reason: 'call screen under another screen');

    router.pop();
    await tester.pumpAndSettle();
    router.pop();
    await tester.pumpAndSettle();
    expect(find.text('chat'), findsOneWidget);
    expect(canOpen(), isTrue, reason: 'call screen closed (minimised)');

    router.push('/group-call/g1');
    await tester.pumpAndSettle();
    expect(canOpen(), isFalse, reason: 'group call pushed');

    router.go('${RouteConstants.voice}?room=r2');
    await tester.pumpAndSettle();
    expect(canOpen(), isFalse, reason: 'call screen reached with go');
  });

  test('the picker route without shared files goes back to the chat list', () {
    expect(sharePickerRedirect(null), RouteConstants.messenger);
    expect(sharePickerRedirect(const []), RouteConstants.messenger);
    expect(sharePickerRedirect('not a list'), RouteConstants.messenger);
    expect(sharePickerRedirect(['/tmp/a.pdf']), RouteConstants.messenger);
  });

  test('the picker route with shared files stays', () {
    expect(
      sharePickerRedirect(
          [SharedMediaFile(path: '/tmp/a.pdf', type: SharedMediaType.file)]),
      isNull,
    );
  });

  test('a share taken from the slot passes the picker route redirect', () {
    final files = (PendingShare()
          ..offer([
            SharedMediaFile(path: '/tmp/a.pdf', type: SharedMediaType.file),
          ]))
        .take();
    expect(sharePickerRedirect(files), isNull);
  });
}

import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taler_id_mobile/core/services/apk_installer_service.dart';
import 'package:taler_id_mobile/core/services/app_update_controller.dart';
import 'package:taler_id_mobile/core/services/update_download_platform.dart';

import 'update_fakes.dart';

void main() {
  late UpdateRig rig;

  setUp(() => rig = UpdateRig());
  tearDown(() => rig.calls.close());

  test('an advertised version shows the card until dismissed; a newer one brings it back', () {
    final c = rig.controller()..setInfo(info(v: '1.1.37'));
    expect(c.visible, isTrue);
    expect(c.phase, UpdatePhase.available);

    c.dismiss();
    expect(c.visible, isFalse);

    c.setInfo(info(v: '1.1.38', b: 239));
    expect(c.visible, isTrue);
  });

  test('the download runs in the background and, once ready, the install is offered once', () {
    fakeAsync((async) {
      final c = rig.controller()..setInfo(info());
      c.startDownload();
      async.flushMicrotasks();
      expect(rig.platform.starts, ['https://x/talerid.apk|1.1.37|238']);
      expect(c.phase, UpdatePhase.downloading);

      rig.platform.next = running(0.5);
      async.elapse(const Duration(seconds: 1));
      expect(c.progress, 0.5);

      rig.platform.next = ready();
      async.elapse(const Duration(seconds: 1));
      expect(rig.installs, ['/f.apk|talerid-1.1.37.apk']);

      async.elapse(const Duration(seconds: 5));
      c.refresh();
      async.flushMicrotasks();
      expect(rig.installs, hasLength(1));
      expect(c.phase, UpdatePhase.ready);
      c.dispose();
    });
  });

  test('a download that finished while the app was away is offered on return, once per launch', () async {
    rig.platform.next = ready();
    final c = rig.controller()..setInfo(info());

    await c.onResumed();
    await pumpEventQueue();
    expect(rig.installs, hasLength(1));

    await c.onResumed();
    await pumpEventQueue();
    expect(rig.installs, hasLength(1));
    expect(c.phase, UpdatePhase.ready);
  });

  test('during a call the install waits for the call to end', () async {
    rig.inCall = true;
    rig.platform.next = ready();
    final c = rig.controller()..setInfo(info());

    await c.onResumed();
    await pumpEventQueue();
    expect(rig.installs, isEmpty);

    rig.inCall = false;
    rig.calls.add(false);
    await pumpEventQueue();
    expect(rig.installs, hasLength(1));
  });

  test('the Install button works during a call', () async {
    rig.inCall = true;
    rig.platform.next = ready();
    final c = rig.controller()..setInfo(info());
    await c.onResumed();
    await pumpEventQueue();

    await c.install();

    expect(rig.installs, hasLength(1));
  });

  test('the "downloaded" notification installs even after the launch offer', () async {
    rig.platform.next = ready();
    final c = rig.controller()..setInfo(info());
    await c.onResumed();
    await pumpEventQueue();

    rig.platform.installRequest = true;
    await c.onResumed();
    await pumpEventQueue();

    expect(rig.installs, hasLength(2));
  });

  test('a failed download is shown and retried from scratch', () async {
    rig.platform.startResult = const UpdateDownloadStatus(
      UpdateDownloadState.failed,
      reason: 'error_1006',
      version: '1.1.37',
      build: 238,
    );
    final c = rig.controller()..setInfo(info());

    await c.startDownload();
    expect(c.phase, UpdatePhase.failed);
    expect(c.failure, 'error_1006');

    rig.platform.startResult = running(0.1);
    await c.startDownload();
    expect(rig.platform.starts, hasLength(2));
    expect(c.phase, UpdatePhase.downloading);
    c.dispose();
  });

  test('a file for another build than the advertised one is not offered', () async {
    rig.platform.next = ready(version: '1.1.36', build: 237);
    final c = rig.controller()..setInfo(info(v: '1.1.37', b: 238));

    await c.onResumed();
    await pumpEventQueue();

    expect(c.phase, UpdatePhase.available);
    expect(rig.installs, isEmpty);
  });

  test('no DownloadManager on the device: the browser downloads it', () async {
    rig.platform.startResult = const UpdateDownloadStatus(
      UpdateDownloadState.failed,
      reason: UpdateDownloadStatus.unavailable,
    );
    final c = rig.controller()..setInfo(info());

    await c.startDownload();

    expect(rig.opened, [Uri.parse('https://x/talerid.apk')]);
    expect(c.phase, UpdatePhase.available);
  });

  test('iOS opens the link and never touches the downloader', () async {
    final c = rig.controller(android: false)..setInfo(info());

    await c.startDownload();
    await c.onResumed();

    expect(rig.opened, hasLength(1));
    expect(rig.platform.starts, isEmpty);
    expect(rig.platform.statusCalls, 0);
  });

  test('polling stops in the background and resumes on return', () {
    fakeAsync((async) {
      rig.platform.startResult = running(0.1);
      rig.platform.next = running(0.2);
      final c = rig.controller()..setInfo(info());
      c.startDownload();
      async.flushMicrotasks();

      c.onPaused();
      final before = rig.platform.statusCalls;
      async.elapse(const Duration(seconds: 5));
      expect(rig.platform.statusCalls, before);

      c.onResumed();
      async.flushMicrotasks();
      async.elapse(const Duration(seconds: 2));
      expect(rig.platform.statusCalls, greaterThan(before + 1));
      c.dispose();
    });
  });

  // AMENDMENT (from Task 1 code review): a failed *status call* says nothing
  // about the download; it must not flip a healthy download to "failed".
  test('a channel error while downloading keeps the card downloading and polling going', () {
    fakeAsync((async) {
      rig.platform.startResult = running(0.3);
      final c = rig.controller()..setInfo(info());
      c.startDownload();
      async.flushMicrotasks();

      rig.platform.next = const UpdateDownloadStatus(
        UpdateDownloadState.failed,
        reason: UpdateDownloadStatus.channelError,
      );
      async.elapse(const Duration(seconds: 1));
      expect(c.phase, UpdatePhase.downloading);
      expect(c.progress, 0.3);

      rig.platform.next = running(0.6);
      async.elapse(const Duration(seconds: 1));
      expect(c.progress, 0.6);
      c.dispose();
    });
  });

  test('install results reach the listeners', () async {
    rig.platform.next = ready();
    final c = rig.controller()..setInfo(info());
    final results = <UpdateInstallResult>[];
    c.installResults.listen(results.add);

    await c.onResumed();
    await pumpEventQueue();

    expect(results.single.displayName, 'talerid-1.1.37.apk');
    expect(results.single.response.status, ApkInstallStatus.aborted);
  });

  test('a throwing installer leaves the card on Install and reports the failure', () async {
    rig.installError = StateError('boom');
    rig.platform.next = ready();
    final c = rig.controller()..setInfo(info());
    final results = <UpdateInstallResult>[];
    c.installResults.listen(results.add);

    await c.onResumed();
    await pumpEventQueue();

    expect(c.phase, UpdatePhase.ready);
    expect(results.single.response.status, ApkInstallStatus.failureUnknown);
  });

  test('coming back after leaving the installer dialog un-sticks the card', () async {
    rig.installGate = Completer<ApkInstallResponse>();
    rig.platform.next = ready();
    final c = rig.controller()..setInfo(info());
    await c.onResumed();
    await pumpEventQueue();
    expect(c.phase, UpdatePhase.installing);

    c.onPaused();
    await c.onResumed();
    expect(c.phase, UpdatePhase.ready);

    rig.installGate!.complete(const ApkInstallResponse(ApkInstallStatus.aborted, 'superseded'));
    await pumpEventQueue();
    rig.installGate = null;
    await c.install();
    expect(rig.installs, hasLength(2));
  });

  test('a channel error right after returning still resumes polling', () {
    fakeAsync((async) {
      rig.platform.startResult = running(0.1);
      final c = rig.controller()..setInfo(info());
      c.startDownload();
      async.flushMicrotasks();
      c.onPaused();

      rig.platform.next = const UpdateDownloadStatus(
        UpdateDownloadState.failed,
        reason: UpdateDownloadStatus.channelError,
      );
      c.onResumed();
      async.flushMicrotasks();

      rig.platform.next = running(0.5);
      async.elapse(const Duration(seconds: 1));
      expect(c.progress, 0.5);
      c.dispose();
    });
  });

  test('a call ending while another line still joins does not open the installer', () async {
    rig.inCall = true; // isInCall() stays true: the second line is still connecting
    rig.platform.next = ready();
    final c = rig.controller()..setInfo(info());
    await c.onResumed();
    await pumpEventQueue();

    rig.calls.add(false);
    await pumpEventQueue();

    expect(rig.installs, isEmpty);
  });

  test('a call that ended while the app was in the background installs on return', () async {
    rig.inCall = true;
    rig.platform.next = ready();
    final c = rig.controller()..setInfo(info());
    await c.onResumed();
    await pumpEventQueue();

    c.onPaused();
    rig.inCall = false;
    rig.calls.add(false);
    await pumpEventQueue();
    expect(rig.installs, isEmpty);

    await c.onResumed();
    await pumpEventQueue();
    expect(rig.installs, hasLength(1));
  });

  test('Update on an already downloaded build installs right away, even in a call', () async {
    rig.inCall = true;
    rig.platform.startResult = ready();
    final c = rig.controller()..setInfo(info());

    await c.startDownload();

    expect(rig.installs, hasLength(1));
  });

  test('after a restart the downloading version shows before /app/version answers', () async {
    rig.platform.next = running(0.4);
    final c = rig.controller();

    await c.onResumed();

    expect(c.visible, isTrue);
    expect(c.version, '1.1.37');
    expect(c.phase, UpdatePhase.downloading);
    c.dispose();
  });

  test('hiding the card during a download keeps polling and still offers the install', () {
    fakeAsync((async) {
      final c = rig.controller()..setInfo(info());
      c.startDownload();
      async.flushMicrotasks();
      c.dismiss();

      rig.platform.next = ready();
      async.elapse(const Duration(seconds: 1));

      expect(c.visible, isFalse);
      expect(rig.installs, hasLength(1));
      c.dispose();
    });
  });

  test('a second version downloaded in the same launch is offered too', () async {
    rig.platform.next = ready();
    final c = rig.controller()..setInfo(info());
    await c.onResumed();
    await pumpEventQueue();
    expect(rig.installs, hasLength(1));

    c.setInfo(info(v: '1.1.38', b: 239));
    rig.platform.next = const UpdateDownloadStatus(
      UpdateDownloadState.ready,
      version: '1.1.38',
      build: 239,
      file: '/g.apk',
    );
    await c.refresh();
    await pumpEventQueue();

    expect(rig.installs, ['/f.apk|talerid-1.1.37.apk', '/g.apk|talerid-1.1.38.apk']);
  });

  test('a double tap on Update starts one download', () async {
    final c = rig.controller()..setInfo(info());

    final first = c.startDownload();
    final second = c.startDownload();
    await Future.wait([first, second]);

    expect(rig.platform.starts, hasLength(1));
    c.dispose();
  });

  test('a start that throws shows the failure instead of hanging on 0%', () async {
    rig.platform.startError = StateError('boom');
    final c = rig.controller()..setInfo(info());

    await c.startDownload();

    expect(c.phase, UpdatePhase.failed);
    c.dispose();
  });

  test('the server saying no update hides a remembered failed download', () async {
    rig.platform.next = const UpdateDownloadStatusFailed();
    final c = rig.controller(); // no setInfo yet: a cold start before /app/version answers

    await c.onResumed();
    expect(c.phase, UpdatePhase.failed);
    expect(c.visible, isTrue);

    c.setInfo(info(available: false));
    expect(c.visible, isFalse);
    c.dispose();
  });

  test('the server saying no update cancels the auto-install of a remembered ready build', () async {
    rig.platform.next = ready();
    final c = rig.controller(); // no setInfo yet: a cold start before /app/version answers

    c.setInfo(info(available: false));
    await c.onResumed();
    await pumpEventQueue();

    expect(rig.installs, isEmpty);
    c.dispose();
  });
}

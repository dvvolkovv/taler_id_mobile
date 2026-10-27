import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
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
}

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

  test('the server sending another app: the browser downloads it, the card is back to Update', () async {
    rig.platform.startResult = const UpdateDownloadStatus(
      UpdateDownloadState.failed,
      reason: UpdateDownloadStatus.wrongPackage,
      version: '1.1.37',
      build: 238,
    );
    final c = rig.controller()..setInfo(info());

    await c.startDownload();

    expect(rig.platform.starts, hasLength(1));
    expect(rig.opened, [Uri.parse('https://x/talerid.apk')]);
    expect(c.phase, UpdatePhase.available);
    expect(rig.installs, isEmpty);
  });

  test('the poll finding another app on screen opens the browser once and the card offers Update', () {
    fakeAsync((async) {
      final c = rig.controller()..setInfo(info());
      c.startDownload();
      async.flushMicrotasks();
      expect(c.phase, UpdatePhase.downloading);

      rig.platform.next = _wrongPackage;
      async.elapse(const Duration(seconds: 1));
      expect(rig.opened, [Uri.parse('https://x/talerid.apk')]);
      expect(c.phase, UpdatePhase.available);

      // The poll is over, and coming back opens nothing more.
      async.elapse(const Duration(seconds: 5));
      c.onResumed();
      async.flushMicrotasks();
      expect(rig.opened, hasLength(1));
      expect(c.phase, UpdatePhase.available);
      c.dispose();
    });
  });

  test('a poll answering with another app after the app left opens nothing; the card offers Update', () {
    fakeAsync((async) {
      final c = rig.controller()..setInfo(info());
      c.startDownload();
      async.flushMicrotasks();

      // The poll asks on screen; the answer lands once the app is away.
      final gate = rig.platform.statusGate = Completer<UpdateDownloadStatus>();
      async.elapse(const Duration(seconds: 1));
      c.onPaused();
      gate.complete(_wrongPackage);
      async.flushMicrotasks();
      expect(rig.opened, isEmpty);
      expect(c.phase, UpdatePhase.available);

      rig.platform.statusGate = null;
      rig.platform.next = _wrongPackage;
      c.onResumed();
      async.flushMicrotasks();
      expect(rig.opened, isEmpty);
      expect(c.phase, UpdatePhase.available);
      c.dispose();
    });
  });

  test('back from the background onto another app: nothing opens until Update, which goes to the browser',
      () async {
    final c = rig.controller()..setInfo(info());
    await c.startDownload();
    c.onPaused();

    rig.platform.next = _wrongPackage;
    await c.onResumed();
    expect(rig.opened, isEmpty);
    expect(c.phase, UpdatePhase.available);

    rig.platform.startResult = _wrongPackage;
    await c.startDownload();
    expect(rig.platform.starts, hasLength(2));
    expect(rig.opened, [Uri.parse('https://x/talerid.apk')]);
    expect(c.phase, UpdatePhase.available);
    c.dispose();
  });

  test('DownloadManager that cannot even be asked: the browser downloads it', () async {
    rig.platform.startResult = const UpdateDownloadStatus(
      UpdateDownloadState.failed,
      reason: UpdateDownloadStatus.channelError,
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

  test('an APK not signed by us: the card drops Install right after the result', () async {
    rig.platform.next = ready();
    final c = rig.controller()..setInfo(info());
    await c.onResumed();
    await pumpEventQueue();
    expect(c.phase, UpdatePhase.ready);

    // Natively the file and the record are gone along with the result.
    rig.platform.next = UpdateDownloadStatus.none;
    rig.installResponse =
        const ApkInstallResponse(ApkInstallStatus.invalid, 'untrusted_signature');
    final results = <UpdateInstallResult>[];
    final sub = c.installResults.listen(results.add);
    await c.install();
    await pumpEventQueue();

    expect(results.single.response.message, 'untrusted_signature');
    expect(c.phase, UpdatePhase.available);
    await sub.cancel();
    c.dispose();
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

  group('automatic offer timing', () {
    const offerDelay = Duration(seconds: 2);
    const callRecheck = Duration(seconds: 5);

    // A ready download of the advertised build: resuming at 0 s makes the
    // install due.
    AppUpdateController resumeWithReadyDownload(FakeAsync async, {Future<bool> Function()? isRinging}) {
      rig.platform.next = ready();
      final c = rig.controller(offerDelay: offerDelay, callRecheck: callRecheck, isRinging: isRinging)
        ..setInfo(info());
      c.onResumed();
      async.flushMicrotasks();
      return c;
    }

    test('the installer opens once, after the offer delay', () {
      fakeAsync((async) {
        final c = resumeWithReadyDownload(async);

        async.elapse(const Duration(milliseconds: 1900));
        expect(rig.installs, isEmpty);
        async.elapse(const Duration(milliseconds: 100));
        expect(rig.installs, hasLength(1));

        async.elapse(const Duration(seconds: 10));
        expect(rig.installs, hasLength(1));
        c.dispose();
      });
    });

    test('a call starting during the delay holds the offer; one ending silently is caught by the recheck, then settles', () {
      fakeAsync((async) {
        final c = resumeWithReadyDownload(async);

        async.elapse(const Duration(seconds: 1));
        rig.inCall = true; // a mesh call: nothing on the stream
        async.elapse(const Duration(seconds: 1)); // 2 s: the offer finds the call
        expect(rig.installs, isEmpty);

        async.elapse(const Duration(seconds: 1));
        rig.inCall = false; // 3 s: it ends, again without an event
        async.elapse(const Duration(seconds: 4)); // 7 s: the recheck finds it gone
        expect(rig.installs, isEmpty);
        async.elapse(const Duration(milliseconds: 1900)); // 8.9 s
        expect(rig.installs, isEmpty);
        async.elapse(const Duration(milliseconds: 100)); // 9 s: settled
        expect(rig.installs, hasLength(1));

        async.elapse(const Duration(seconds: 20));
        expect(rig.installs, hasLength(1));
        c.dispose();
      });
    });

    test('a call ending with an event restarts the offer delay instead of waiting for the recheck', () {
      fakeAsync((async) {
        rig.inCall = true;
        final c = resumeWithReadyDownload(async); // recheck due at 5 s

        async.elapse(const Duration(seconds: 1));
        rig.inCall = false;
        rig.calls.add(false);
        async.flushMicrotasks();
        expect(rig.installs, isEmpty);

        async.elapse(const Duration(milliseconds: 1900)); // 2.9 s
        expect(rig.installs, isEmpty);
        async.elapse(const Duration(milliseconds: 100)); // 3 s: the delay after the event
        expect(rig.installs, hasLength(1));

        async.elapse(const Duration(seconds: 10)); // past the dropped 5 s recheck
        expect(rig.installs, hasLength(1));
        c.dispose();
      });
    });

    test('going to the background during the delay drops the offer until the next return', () {
      fakeAsync((async) {
        final c = resumeWithReadyDownload(async);

        async.elapse(const Duration(seconds: 1));
        c.onPaused();
        async.elapse(const Duration(seconds: 10));
        expect(rig.installs, isEmpty);

        // Still due: the next return offers it, after the delay again.
        c.onResumed();
        async.flushMicrotasks();
        async.elapse(offerDelay);
        expect(rig.installs, hasLength(1));
        c.dispose();
      });
    });

    test('a call that ended silently just before the recheck still gets the settle time', () {
      fakeAsync((async) {
        rig.inCall = true;
        final c = resumeWithReadyDownload(async); // recheck due at 5 s

        async.elapse(const Duration(milliseconds: 4990));
        rig.inCall = false; // ends 10 ms before the recheck, without an event
        async.elapse(const Duration(milliseconds: 10)); // 5 s: the recheck finds it gone
        expect(rig.installs, isEmpty);
        async.elapse(const Duration(milliseconds: 1990)); // 6.99 s
        expect(rig.installs, isEmpty);
        async.elapse(const Duration(milliseconds: 10)); // 7 s
        expect(rig.installs, hasLength(1));
        c.dispose();
      });
    });

    test('a ring in the system call UI holds the offer; once it is gone the offer settles first', () {
      fakeAsync((async) {
        var ringing = true;
        var asked = 0;
        final c = resumeWithReadyDownload(async, isRinging: () async {
          asked++;
          return ringing;
        });

        async.elapse(offerDelay); // 2 s: asked, ringing
        expect(asked, 1);
        expect(rig.installs, isEmpty);

        ringing = false;
        async.elapse(callRecheck); // 7 s: asked, clear, but a ring just ended
        expect(asked, 2);
        expect(rig.installs, isEmpty);

        async.elapse(const Duration(milliseconds: 1900)); // 8.9 s
        expect(rig.installs, isEmpty);
        async.elapse(const Duration(milliseconds: 100)); // 9 s: asked once more
        expect(asked, 3);
        expect(rig.installs, hasLength(1));

        async.elapse(const Duration(seconds: 20));
        expect(rig.installs, hasLength(1));
        c.dispose();
      });
    });

    for (final sync in [false, true]) {
      test('a system call UI that cannot answer (${sync ? 'sync' : 'async'} throw) does not hold the update back', () {
        fakeAsync((async) {
          Future<bool> broken() async => throw StateError('no CallKit');
          final c = resumeWithReadyDownload(
            async,
            isRinging: sync ? () => throw StateError('no CallKit') : broken,
          );

          async.elapse(offerDelay);
          expect(rig.installs, hasLength(1));
          c.dispose();
        });
      });
    }

    test('leaving the screen while the system call UI is asked drops the offer', () {
      fakeAsync((async) {
        final answer = Completer<bool>();
        final c = resumeWithReadyDownload(async, isRinging: () => answer.future);

        async.elapse(offerDelay); // 2 s: asked, no answer yet
        c.onPaused();
        answer.complete(false);
        async.elapse(const Duration(seconds: 10));
        expect(rig.installs, isEmpty);
        c.dispose();
      });
    });

    test('a late answer after leaving and coming back does not skip the delay', () {
      fakeAsync((async) {
        final answers = <Completer<bool>>[];
        final c = resumeWithReadyDownload(async, isRinging: () {
          answers.add(Completer<bool>());
          return answers.last.future;
        });

        async.elapse(offerDelay); // 2 s: asked, no answer yet
        c.onPaused();
        c.onResumed();
        async.flushMicrotasks();
        answers.first.complete(false); // the answer for the dropped offer
        async.flushMicrotasks();
        expect(rig.installs, isEmpty);

        async.elapse(offerDelay); // 4 s: asked afresh after the delay
        expect(answers, hasLength(2));
        answers.last.complete(false);
        async.flushMicrotasks();
        expect(rig.installs, hasLength(1));
        c.dispose();
      });
    });
  });
}

const _wrongPackage = UpdateDownloadStatus(
  UpdateDownloadState.failed,
  reason: UpdateDownloadStatus.wrongPackage,
  version: '1.1.37',
  build: 238,
);

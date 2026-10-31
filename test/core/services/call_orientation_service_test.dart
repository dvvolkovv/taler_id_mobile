import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:taler_id_mobile/core/services/call_orientation_service.dart';

const _free = [
  'DeviceOrientation.portraitUp',
  'DeviceOrientation.landscapeLeft',
  'DeviceOrientation.landscapeRight',
];
const _portrait = ['DeviceOrientation.portraitUp'];
const _iosChannel = MethodChannel('taler_id/orientation');

String _label(List<String> o) => o.join() == _portrait.join()
    ? 'S:portrait'
    : o.join() == _free.join()
        ? 'S:free'
        : 'S:$o';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  // Every SystemChrome.setPreferredOrientations / iOS setAllowAll, in order.
  late List<List<String>> orientations;
  late List<bool> allowAll;
  // Both channels combined, in call order, labelled so assertions read easily.
  late List<String> log;
  final open = <CallOrientationService>[];

  Future<CallOrientationService> make({
    bool isSupported = true,
    bool isIOS = true,
  }) async {
    final s = CallOrientationService(isSupported: isSupported, isIOS: isIOS);
    await s.init();
    open.add(s);
    return s;
  }

  Future<void> close(CallOrientationService s) async {
    await s.dispose();
    open.remove(s);
  }

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('call_orientation_test_');
    Hive.init(tempDir.path);
    orientations = [];
    allowAll = [];
    log = [];
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'SystemChrome.setPreferredOrientations') {
        final args = List<String>.from(call.arguments as List);
        orientations.add(args);
        log.add(_label(args));
      }
      return null;
    });
    messenger.setMockMethodCallHandler(_iosChannel, (call) async {
      if (call.method == 'setAllowAll') {
        allowAll.add(call.arguments as bool);
        log.add('A:${call.arguments}');
      }
      return null;
    });
  });

  tearDown(() async {
    for (final s in List.of(open)) {
      await close(s);
    }
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(SystemChannels.platform, null);
    messenger.setMockMethodCallHandler(_iosChannel, null);
    await Hive.deleteBoxFromDisk('call_prefs');
    await tempDir.delete(recursive: true);
  });

  test('unlocked by default: entering a call lets the phone rotate', () async {
    final s = await make();
    expect(s.rotationLocked.value, isFalse);

    await s.callScreenOpened();

    expect(orientations, [_free]);
    expect(allowAll, [true]);
  });

  test('locking in a call snaps back to portrait and is remembered', () async {
    final s = await make();
    await s.callScreenOpened();

    await s.setRotationLocked(true);

    expect(orientations.last, _portrait);
    expect(allowAll.last, isFalse);
    await close(s);
    final again = await make();
    expect(again.rotationLocked.value, isTrue);
  });

  test('locked: the next call opens portrait-only, never allows all', () async {
    final first = await make();
    await first.setRotationLocked(true);
    await close(first);

    final s = await make();
    await s.callScreenOpened();
    await s.reapply();

    expect(orientations, [_portrait, _portrait]);
    expect(allowAll, [false, false]);
  });

  test('unlocking in a call lets the phone rotate again', () async {
    final s = await make();
    await s.setRotationLocked(true);
    await s.callScreenOpened();

    await s.setRotationLocked(false);

    expect(orientations.last, _free);
    expect(allowAll.last, isTrue);
  });

  test('outside a call the choice is only stored', () async {
    final s = await make();

    await s.setRotationLocked(true);
    await s.setRotationLocked(false);

    expect(orientations, isEmpty);
    expect(allowAll, isEmpty);
  });

  test('closing the last call screen puts the app back to portrait', () async {
    final s = await make();
    await s.callScreenOpened();

    await s.callScreenClosed();

    expect(orientations, [_free, _portrait]);
    expect(allowAll, [true, false]);
  });

  test('an old screen closing late does not take rotation from the new one',
      () async {
    final s = await make();
    await s.callScreenOpened(); // the screen being minimised
    await s.callScreenOpened(); // re-entered before the old one is disposed
    orientations.clear();
    allowAll.clear();

    await s.callScreenClosed(); // the old screen is disposed at last
    expect(orientations, isEmpty);
    expect(allowAll, isEmpty);

    await s.callScreenClosed(); // the new screen closes too
    expect(orientations, [_portrait]);
    expect(allowAll, [false]);
  });

  test('reapply does not count as another screen', () async {
    final s = await make();
    await s.callScreenOpened();
    await s.reapply();

    await s.callScreenClosed();

    expect(orientations, [_free, _free, _portrait]);
    expect(allowAll, [true, true, false]);
  });

  test('an extra callScreenClosed does not break the next call', () async {
    final s = await make();
    await s.callScreenClosed();

    await s.callScreenOpened();
    await s.callScreenClosed();

    expect(orientations, [_free, _portrait]);
  });

  test('Android: SystemChrome only, no iOS channel', () async {
    final s = await make(isIOS: false);

    await s.callScreenOpened();
    await s.setRotationLocked(true);
    await s.callScreenClosed();

    expect(orientations, [_free, _portrait, _portrait]);
    expect(allowAll, isEmpty);
  });

  test('desktop and web: nothing applied, the choice is still kept', () async {
    final s = await make(isSupported: false, isIOS: false);

    await s.callScreenOpened();
    await s.setRotationLocked(true);
    await s.callScreenClosed();

    expect(orientations, isEmpty);
    expect(allowAll, isEmpty);
    expect(s.rotationLocked.value, isTrue);
  });

  test('iOS: the native flag follows SystemChrome, never ahead of it',
      () async {
    final s = await make();

    await s.callScreenOpened();
    await s.setRotationLocked(true);

    expect(log, ['S:free', 'A:true', 'S:portrait', 'A:false']);
  });

  test('unlocking as the last call screen closes still ends in portrait',
      () async {
    final s = await make();
    await s.setRotationLocked(true);
    await s.callScreenOpened();

    // Started in the same tick, as the button and dispose() can do.
    await Future.wait([s.setRotationLocked(false), s.callScreenClosed()]);

    expect(orientations.last, _portrait);
    expect(allowAll.last, isFalse);
  });

  test('a new screen opening as the old one closes never drops to portrait',
      () async {
    final s = await make();
    await s.callScreenOpened();
    log.clear();

    await Future.wait([s.callScreenOpened(), s.callScreenClosed()]);

    expect(log, ['S:free', 'A:true']);
  });

  test('a box that fails to open once is recreated and keeps the choice',
      () async {
    var attempts = 0;
    final s = CallOrientationService(
      isSupported: true,
      isIOS: false,
      openBox: (name) => ++attempts == 1
          ? Future.error(const FileSystemException('corrupt'))
          : Hive.openBox(name),
    );
    await s.init();
    open.add(s);
    await s.setRotationLocked(true);
    expect(attempts, 2);

    await close(s);
    final again = await make();
    expect(again.rotationLocked.value, isTrue);
  });

  // The box is opened through an injected function: making the real Hive fail
  // (no Hive.init) also fails the test — Hive completes an internal Completer
  // with the error nobody listens to, and the test zone reports it as
  // uncaught even though init() catches the rethrown one.
  test('storage that cannot be opened does not fail app start-up', () async {
    final s = CallOrientationService(
      isSupported: true,
      isIOS: false,
      openBox: (_) => Future.error(const FileSystemException('read-only')),
    );

    await s.init();
    expect(s.rotationLocked.value, isFalse);

    await s.setRotationLocked(true);
    expect(s.rotationLocked.value, isTrue);

    await s.callScreenOpened();
    expect(orientations, [_portrait]);
  });

  test('a failing SystemChrome neither throws nor skips the iOS flag',
      () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform,
            (call) async => throw PlatformException(code: 'boom'));
    final s = await make();

    await s.callScreenOpened();

    expect(log, ['A:true']);
  });

  test('a stored value that is not a bool reads as unlocked', () async {
    final box = await Hive.openBox('call_prefs');
    await box.put('rotation_locked_v1', 'yes');
    await box.close();

    final s = await make();

    expect(s.rotationLocked.value, isFalse);
  });

  test('the lock is offered on phones only', () {
    final mobile = CallOrientationService(isSupported: true, isIOS: true);
    final desktop = CallOrientationService(isSupported: false, isIOS: false);

    expect(mobile.lockAvailableFor(const Size(390, 844)), isTrue);
    expect(mobile.lockAvailableFor(const Size(844, 390)), isTrue);
    expect(mobile.lockAvailableFor(const Size(820, 1180)), isFalse);
    expect(desktop.lockAvailableFor(const Size(390, 844)), isFalse);
  });
}

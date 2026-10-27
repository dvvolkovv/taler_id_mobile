import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taler_id_mobile/core/services/update_download_platform.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('taler_id/installer');
  final calls = <MethodCall>[];
  final platform = MethodChannelUpdateDownloadPlatform();

  void answer(Future<Object?> Function(MethodCall call) handler) {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) {
      calls.add(call);
      return handler(call);
    });
  }

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    calls.clear();
  });

  test('start sends url, version and build and reads the answer', () async {
    answer((_) async => {
          'state': 'running',
          'progress': 0.25,
          'version': '1.1.37',
          'build': 238,
          'file': '/f.apk',
        });

    final s = await platform.start(url: 'https://x/a.apk', version: '1.1.37', build: 238);

    expect(calls.single.method, 'startDownload');
    expect(calls.single.arguments, {'url': 'https://x/a.apk', 'version': '1.1.37', 'build': 238});
    expect(s.state, UpdateDownloadState.running);
    expect(s.progress, 0.25);
    expect(s.build, 238);
    expect(s.file, '/f.apk');
  });

  test('status reads ready and failed', () async {
    answer((_) async => {'state': 'ready', 'version': '1.1.37', 'build': 238, 'file': '/f.apk'});
    expect((await platform.status()).state, UpdateDownloadState.ready);
    expect(calls.first.method, 'downloadStatus');

    answer((_) async => {'state': 'failed', 'reason': 'error_1006'});
    final failed = await platform.status();
    expect(failed.state, UpdateDownloadState.failed);
    expect(failed.reason, 'error_1006');
  });

  test('an unknown or missing state reads as none', () {
    expect(UpdateDownloadStatus.fromMap({'state': 'weird'}).state, UpdateDownloadState.none);
    expect(UpdateDownloadStatus.fromMap(null).state, UpdateDownloadState.none);
  });

  test('a start the channel rejects reads as "no downloader on this device"', () async {
    answer((_) async => throw PlatformException(code: 'boom'));

    final s = await platform.start(url: 'u', version: 'v', build: 1);

    expect(s.state, UpdateDownloadState.failed);
    expect(s.reason, UpdateDownloadStatus.unavailable);
  });

  test('consumeInstallRequest returns what the native side says, false on errors', () async {
    answer((_) async => true);
    expect(await platform.consumeInstallRequest(), isTrue);
    expect(calls.first.method, 'consumeInstallRequest');

    answer((_) async => throw PlatformException(code: 'boom'));
    expect(await platform.consumeInstallRequest(), isFalse);
  });

  test('cancel calls cancelDownload and swallows errors', () async {
    answer((_) async => null);
    await platform.cancel();
    expect(calls.single.method, 'cancelDownload');

    answer((_) async => throw PlatformException(code: 'boom'));
    await expectLater(platform.cancel(), completes);
  });

  test('without a native side (iOS, desktop) nothing throws', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);

    final started = await platform.start(url: 'u', version: 'v', build: 1);
    expect(started.state, UpdateDownloadState.failed);
    expect(started.reason, UpdateDownloadStatus.unavailable);

    expect((await platform.status()).state, UpdateDownloadState.none);
    await expectLater(platform.cancel(), completes);
    expect(await platform.consumeInstallRequest(), isFalse);
  });

  test('malformed values from native read as null instead of throwing', () {
    final s = UpdateDownloadStatus.fromMap({
      'state': 'running',
      'build': '238',
      'progress': 'x',
      'version': 1,
      'file': 2,
    });

    expect(s.state, UpdateDownloadState.running);
    expect(s.build, isNull);
    expect(s.progress, isNull);
    expect(s.version, isNull);
    expect(s.file, isNull);
  });
}

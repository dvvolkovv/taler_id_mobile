# Обновление приложения: карточка поверх главного экрана и скачивание в фоне — план реализации

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Предложение обновиться перестаёт сдвигать экраны, а APK на Android качается системным загрузчиком в фоне и предлагается к установке, когда готов.

**Architecture:** Состояние обновления переезжает из `State` баннера в синглтон `AppUpdateController` (GetIt, `ChangeNotifier`). Карточка `UpdateCard` рисуется поверх главного экрана (`AssistantScreen._buildIdle`, `Stack`). На Android загрузку ведёт нативный `UpdateDownloader` на `DownloadManager`; приёмник `ACTION_DOWNLOAD_COMPLETE` из манифеста публикует уведомление «скачано», когда приложение не на экране. Пока приложение на экране, Dart опрашивает статус раз в секунду и сам предлагает установку существующим `ApkInstaller`.

**Tech Stack:** Flutter 3.38.9 / Dart, GetIt, `flutter_test` + `fake_async`, Kotlin (`DownloadManager`, `PackageInstaller`, `NotificationCompat`).

**Спецификация:** `docs/superpowers/specs/2026-10-26-update-banner-background-download-design.md`

**Рабочий каталог:** `~/Downloads/taler_id_mobile/.worktrees/update-download` (ветка `feat/update-background-download`). Все пути ниже — от него.

---

## Карта файлов

| Файл | Что делает |
|---|---|
| `lib/core/services/update_download_platform.dart` (новый) | Модель статуса загрузки и обёртка над методами канала `taler_id/installer` |
| `lib/core/services/app_update_controller.dart` (новый) | Состояние карточки, загрузка, опрос, автопредложение установки, ожидание конца звонка |
| `lib/core/services/update_check_service.dart` | + `UpdateInfo.latestBuild` |
| `lib/features/dashboard/presentation/widgets/update_card.dart` (новый) | `UpdateCard`, «Что нового», диалоги результата установки |
| `lib/features/dashboard/presentation/dashboard_screen.dart` | Убрать `_UpdateBanner`, отдавать `UpdateInfo` контроллеру, жизненный цикл, диалоги |
| `lib/features/assistant/presentation/screens/assistant_screen.dart` | Карточка в `Stack` главного экрана |
| `lib/core/di/service_locator.dart` | Регистрация `AppUpdateController` |
| `lib/l10n/app_ru.arb`, `lib/l10n/app_en.arb` (+ сгенерированные `app_localizations*.dart`) | Новые строки |
| `android/.../installer/UpdateDownloader.kt` (новый) | `DownloadManager`, запись в prefs, статус, проверка APK, уборка, уведомление «скачано» |
| `android/.../installer/UpdateDownloadReceiver.kt` (новый) | `ACTION_DOWNLOAD_COMPLETE` → уведомление, если приложение не на экране |
| `android/.../installer/ApkInstaller.kt` | Новые методы канала |
| `android/.../MainActivity.kt` | Флаг «на экране», разбор нажатия на уведомление |
| `android/app/src/main/AndroidManifest.xml` | Приёмник |
| `test/core/services/update_fakes.dart` (новый) | Общие фейки для тестов |
| `test/core/services/update_download_platform_test.dart`, `app_update_controller_test.dart`, `test/features/dashboard/update_card_test.dart` (новые) | Тесты |

`android/...` = `android/app/src/main/kotlin/tirol/taler/taler_id_mobile`.

---

### Task 1: Модель статуса загрузки и обёртка канала

**Files:**
- Create: `lib/core/services/update_download_platform.dart`
- Modify: `lib/core/services/update_check_service.dart`
- Test: `test/core/services/update_download_platform_test.dart`

- [ ] **Step 1: Написать падающий тест**

`test/core/services/update_download_platform_test.dart`:

```dart
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

    answer((_) async => throw PlatformException(code: 'boom'));
    expect(await platform.consumeInstallRequest(), isFalse);
  });
}
```

- [ ] **Step 2: Убедиться, что тест падает**

Run: `flutter test test/core/services/update_download_platform_test.dart`
Expected: FAIL — `Target of URI doesn't exist: 'package:taler_id_mobile/core/services/update_download_platform.dart'`.

- [ ] **Step 3: Реализация**

`lib/core/services/update_download_platform.dart`:

```dart
import 'package:flutter/services.dart';

/// Where the Android background download of an update stands
/// (UpdateDownloader.kt, system DownloadManager).
enum UpdateDownloadState { none, running, paused, ready, failed }

class UpdateDownloadStatus {
  const UpdateDownloadStatus(
    this.state, {
    this.progress,
    this.version,
    this.build,
    this.file,
    this.reason,
  });

  /// Reason of a failed start when the device has no usable DownloadManager
  /// (disabled on some custom ROMs): the caller falls back to the browser.
  static const unavailable = 'download_manager_unavailable';

  static const none = UpdateDownloadStatus(UpdateDownloadState.none);

  final UpdateDownloadState state;

  /// 0..1 while running or paused.
  final double? progress;
  final String? version;
  final int? build;

  /// Absolute path of the APK; set once the download is ready.
  final String? file;
  final String? reason;

  factory UpdateDownloadStatus.fromMap(Map<dynamic, dynamic>? m) {
    if (m == null) return none;
    final state = switch (m['state']) {
      'running' => UpdateDownloadState.running,
      'paused' => UpdateDownloadState.paused,
      'ready' => UpdateDownloadState.ready,
      'failed' => UpdateDownloadState.failed,
      _ => UpdateDownloadState.none,
    };
    return UpdateDownloadStatus(
      state,
      progress: (m['progress'] as num?)?.toDouble(),
      version: m['version'] as String?,
      build: m['build'] as int?,
      file: m['file'] as String?,
      reason: m['reason'] as String?,
    );
  }
}

abstract class UpdateDownloadPlatform {
  /// Starts (or returns the already running/finished) download of [build].
  Future<UpdateDownloadStatus> start({
    required String url,
    required String version,
    required int build,
  });

  Future<UpdateDownloadStatus> status();

  Future<void> cancel();

  /// True once after the user opened the app from the "downloaded" notification.
  Future<bool> consumeInstallRequest();
}

class MethodChannelUpdateDownloadPlatform implements UpdateDownloadPlatform {
  static const _channel = MethodChannel('taler_id/installer');

  @override
  Future<UpdateDownloadStatus> start({
    required String url,
    required String version,
    required int build,
  }) async {
    try {
      final m = await _channel.invokeMethod<Map<dynamic, dynamic>>(
        'startDownload',
        {'url': url, 'version': version, 'build': build},
      );
      return UpdateDownloadStatus.fromMap(m);
    } on PlatformException {
      return const UpdateDownloadStatus(UpdateDownloadState.failed,
          reason: UpdateDownloadStatus.unavailable);
    } on MissingPluginException {
      return const UpdateDownloadStatus(UpdateDownloadState.failed,
          reason: UpdateDownloadStatus.unavailable);
    }
  }

  @override
  Future<UpdateDownloadStatus> status() async {
    try {
      final m = await _channel.invokeMethod<Map<dynamic, dynamic>>('downloadStatus');
      return UpdateDownloadStatus.fromMap(m);
    } on PlatformException {
      return const UpdateDownloadStatus(UpdateDownloadState.failed, reason: 'channel_error');
    } on MissingPluginException {
      return UpdateDownloadStatus.none;
    }
  }

  @override
  Future<void> cancel() async {
    try {
      await _channel.invokeMethod<void>('cancelDownload');
    } on PlatformException {
      // Nothing to cancel is fine.
    } on MissingPluginException {
      // Not Android.
    }
  }

  @override
  Future<bool> consumeInstallRequest() async {
    try {
      return await _channel.invokeMethod<bool>('consumeInstallRequest') ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }
}
```

В `lib/core/services/update_check_service.dart` добавить номер сборки (загрузчик называет и проверяет APK по нему):

```dart
// в class UpdateInfo, после поля latestVersion:
  /// Build number of [latestVersion]; the Android downloader names and
  /// checks the APK by it.
  final int latestBuild;
```

```dart
// в конструкторе UpdateInfo, после required this.latestVersion,
    this.latestBuild = 0,
```

```dart
// в checkForUpdate(), в return UpdateInfo(..., после latestVersion: remoteVersion,
        latestBuild: remoteBuild,
```

- [ ] **Step 4: Тест проходит**

Run: `flutter test test/core/services/update_download_platform_test.dart`
Expected: PASS, 5 тестов.

- [ ] **Step 5: Коммит**

```bash
git add lib/core/services/update_download_platform.dart lib/core/services/update_check_service.dart test/core/services/update_download_platform_test.dart
git commit -m "feat(обновление): статус фоновой загрузки и обёртка канала"
```

---

### Task 2: `AppUpdateController`

**Files:**
- Create: `lib/core/services/app_update_controller.dart`
- Create: `test/core/services/update_fakes.dart`
- Test: `test/core/services/app_update_controller_test.dart`

- [ ] **Step 1: Общие фейки для тестов**

`test/core/services/update_fakes.dart`:

```dart
import 'dart:async';

import 'package:taler_id_mobile/core/services/apk_installer_service.dart';
import 'package:taler_id_mobile/core/services/app_update_controller.dart';
import 'package:taler_id_mobile/core/services/update_check_service.dart';
import 'package:taler_id_mobile/core/services/update_download_platform.dart';

class FakeUpdatePlatform implements UpdateDownloadPlatform {
  UpdateDownloadStatus next = UpdateDownloadStatus.none;
  UpdateDownloadStatus startResult = running(0);
  bool installRequest = false;
  final starts = <String>[];
  int statusCalls = 0;

  @override
  Future<UpdateDownloadStatus> start({
    required String url,
    required String version,
    required int build,
  }) async {
    starts.add('$url|$version|$build');
    return startResult;
  }

  @override
  Future<UpdateDownloadStatus> status() async {
    statusCalls++;
    return next;
  }

  @override
  Future<void> cancel() async {}

  @override
  Future<bool> consumeInstallRequest() async {
    final r = installRequest;
    installRequest = false;
    return r;
  }
}

/// Everything an [AppUpdateController] talks to, recorded.
class UpdateRig {
  final platform = FakeUpdatePlatform();
  final installs = <String>[];
  final opened = <Uri>[];
  final calls = StreamController<bool>.broadcast();
  bool inCall = false;

  AppUpdateController controller({bool android = true}) => AppUpdateController(
        platform: platform,
        install: (path, name) async {
          installs.add('$path|$name');
          return const ApkInstallResponse(ApkInstallStatus.aborted, '');
        },
        openUrl: (url) async => opened.add(url),
        isInCall: () => inCall,
        callStateStream: calls.stream,
        isAndroid: android,
      );
}

UpdateInfo info({String v = '1.1.37', int b = 238, String notes = ''}) => UpdateInfo(
      isAvailable: true,
      isRequired: false,
      downloadUrl: 'https://x/talerid.apk',
      latestVersion: v,
      latestBuild: b,
      currentVersion: '1.1.36',
      releases: [
        ReleaseEntry(version: v, build: b, date: '', flavor: 'both', notesRu: notes, notesEn: notes),
      ],
    );

UpdateDownloadStatus running(double p) => UpdateDownloadStatus(
      UpdateDownloadState.running,
      progress: p,
      version: '1.1.37',
      build: 238,
    );

UpdateDownloadStatus ready({String version = '1.1.37', int build = 238}) =>
    UpdateDownloadStatus(
      UpdateDownloadState.ready,
      version: version,
      build: build,
      file: '/f.apk',
    );
```

- [ ] **Step 2: Написать падающие тесты**

`test/core/services/app_update_controller_test.dart`:

```dart
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
}
```

- [ ] **Step 3: Убедиться, что тесты падают**

Run: `flutter test test/core/services/app_update_controller_test.dart`
Expected: FAIL — `Target of URI doesn't exist: 'package:taler_id_mobile/core/services/app_update_controller.dart'`.

- [ ] **Step 4: Реализация**

`lib/core/services/app_update_controller.dart`:

```dart
import 'dart:async';

import 'package:flutter/foundation.dart';

import 'apk_installer_service.dart';
import 'update_check_service.dart';
import 'update_download_platform.dart';

/// What the update card shows.
enum UpdatePhase { available, downloading, ready, installing, failed }

typedef UpdateInstallFn = Future<ApkInstallResponse> Function(String path, String displayName);

/// One finished install attempt, for the dashboard to explain failures.
typedef UpdateInstallResult = ({ApkInstallResponse response, String displayName});

/// Owns the in-app update: what `/app/version` advertises, the Android
/// background download (system DownloadManager, UpdateDownloader.kt) and the
/// install. Lives in GetIt so a rebuilt widget never loses a download — the
/// old banner kept it in a widget's State and lost it on any error.
class AppUpdateController extends ChangeNotifier {
  AppUpdateController({
    required UpdateDownloadPlatform platform,
    required UpdateInstallFn install,
    required Future<void> Function(Uri url) openUrl,
    required bool Function() isInCall,
    required Stream<bool> callStateStream,
    required bool isAndroid,
    Duration pollInterval = const Duration(seconds: 1),
  })  : _platform = platform,
        _install = install,
        _openUrl = openUrl,
        _isInCall = isInCall,
        _isAndroid = isAndroid,
        _pollInterval = pollInterval {
    _callSub = callStateStream.listen(_onCallState);
  }

  final UpdateDownloadPlatform _platform;
  final UpdateInstallFn _install;
  final Future<void> Function(Uri url) _openUrl;
  final bool Function() _isInCall;
  final bool _isAndroid;
  final Duration _pollInterval;
  late final StreamSubscription<bool> _callSub;
  final _installResults = StreamController<UpdateInstallResult>.broadcast();

  UpdateInfo? _info;
  UpdateDownloadStatus _download = UpdateDownloadStatus.none;
  UpdatePhase _phase = UpdatePhase.available;
  String? _dismissedVersion;
  bool _foreground = true;
  bool _offeredThisLaunch = false;
  bool _offerAfterCall = false;
  Timer? _poll;

  UpdateInfo? get info => _info;
  UpdatePhase get phase => _phase;
  double get progress => _download.progress ?? 0;
  String? get failure => _download.reason;
  Stream<UpdateInstallResult> get installResults => _installResults.stream;

  /// The version the card talks about: the advertised one or — right after a
  /// restart, before `/app/version` has answered — the one being downloaded.
  String? get version {
    if (_info?.isAvailable == true) return _info!.latestVersion;
    return _download.state == UpdateDownloadState.none ? null : _download.version;
  }

  bool get visible {
    final v = version;
    return v != null && v != _dismissedVersion;
  }

  void setInfo(UpdateInfo info) {
    _info = info;
    _apply(_download);
  }

  /// Hides the card until a newer version shows up; a running download goes on.
  void dismiss() {
    _dismissedVersion = version;
    notifyListeners();
  }

  Future<void> startDownload() async {
    final info = _info;
    if (info == null || !info.isAvailable) return;
    if (!_isAndroid) {
      await _openUrl(Uri.parse(info.downloadUrl));
      return;
    }
    _setPhase(UpdatePhase.downloading);
    final s = await _platform.start(
      url: info.downloadUrl,
      version: info.latestVersion,
      build: info.latestBuild,
    );
    if (s.state == UpdateDownloadState.failed && s.reason == UpdateDownloadStatus.unavailable) {
      // No usable DownloadManager on this device: the browser downloads it.
      _download = UpdateDownloadStatus.none;
      _setPhase(UpdatePhase.available);
      await _openUrl(Uri.parse(info.downloadUrl));
      return;
    }
    _apply(s);
    // Downloaded earlier already: the tap asks to install now.
    if (_phase == UpdatePhase.ready) await install();
  }

  /// Asks the system installer to replace the app. On success Android kills
  /// this process, so getting past the await means it did not happen.
  Future<void> install() async {
    final file = _download.file;
    if (_phase != UpdatePhase.ready || file == null) return;
    final name = 'talerid-${_download.version ?? version ?? 'update'}.apk';
    _setPhase(UpdatePhase.installing);
    final response = await _install(file, name);
    _setPhase(UpdatePhase.ready);
    _installResults.add((response: response, displayName: name));
  }

  Future<void> onResumed() async {
    _foreground = true;
    if (!_isAndroid) return;
    final fromNotification = await _platform.consumeInstallRequest();
    // The notification path installs below; keep refresh() from offering too.
    if (fromNotification) _offeredThisLaunch = true;
    await refresh();
    if (_phase != UpdatePhase.ready) return;
    if (fromNotification || (_offerAfterCall && !_isInCall())) {
      _offerAfterCall = false;
      _offerNow();
    }
  }

  void onPaused() {
    _foreground = false;
    _syncPolling();
  }

  Future<void> refresh() async {
    if (!_isAndroid) return;
    _apply(await _platform.status());
    if (_phase == UpdatePhase.ready && !_offeredThisLaunch) {
      _offeredThisLaunch = true;
      _offerNow();
    }
  }

  /// Opens the installer unless a call is on: installing closes the app and
  /// would cut the conversation. Then it waits for the call to end.
  void _offerNow() {
    if (_isInCall()) {
      _offerAfterCall = true;
      return;
    }
    unawaited(install());
  }

  void _onCallState(bool inCall) {
    if (inCall || !_offerAfterCall || !_foreground || _phase != UpdatePhase.ready) return;
    _offerAfterCall = false;
    unawaited(install());
  }

  void _apply(UpdateDownloadStatus s) {
    _download = s;
    // The installer is up; a refresh landing meanwhile must not flip the card.
    if (_phase == UpdatePhase.installing) return;
    final advertised = _info?.isAvailable == true ? _info : null;
    // A file for an older build than the advertised one is stale: the next
    // "Обновить" replaces it.
    final stale = advertised != null &&
        s.state != UpdateDownloadState.none &&
        s.build != null &&
        s.build != advertised.latestBuild;
    _phase = stale
        ? UpdatePhase.available
        : switch (s.state) {
            UpdateDownloadState.none => UpdatePhase.available,
            UpdateDownloadState.running || UpdateDownloadState.paused => UpdatePhase.downloading,
            UpdateDownloadState.ready => UpdatePhase.ready,
            UpdateDownloadState.failed => UpdatePhase.failed,
          };
    _syncPolling();
    notifyListeners();
  }

  void _setPhase(UpdatePhase p) {
    _phase = p;
    _syncPolling();
    notifyListeners();
  }

  void _syncPolling() {
    final want = _isAndroid && _foreground && _phase == UpdatePhase.downloading;
    if (want && _poll == null) {
      _poll = Timer.periodic(_pollInterval, (_) => unawaited(refresh()));
    } else if (!want) {
      _poll?.cancel();
      _poll = null;
    }
  }

  @override
  void dispose() {
    _poll?.cancel();
    unawaited(_callSub.cancel());
    unawaited(_installResults.close());
    super.dispose();
  }
}
```

- [ ] **Step 5: Тесты проходят**

Run: `flutter test test/core/services/app_update_controller_test.dart`
Expected: PASS, 11 тестов.

- [ ] **Step 6: Коммит**

```bash
git add lib/core/services/app_update_controller.dart test/core/services/update_fakes.dart test/core/services/app_update_controller_test.dart
git commit -m "feat(обновление): AppUpdateController — загрузка в фоне, опрос, установка после звонка"
```

---

### Task 3: Строки локализации

**Files:**
- Modify: `lib/l10n/app_ru.arb` (шаблон), `lib/l10n/app_en.arb`
- Regenerate: `lib/l10n/app_localizations*.dart` (лежат в git)

- [ ] **Step 1: Добавить ключи в `lib/l10n/app_ru.arb`** сразу после `"updateInstallOk": "Понятно",`

```json
  "updateDownloading": "Скачивается {percent}%",
  "@updateDownloading": {
    "placeholders": {
      "percent": {
        "type": "int"
      }
    }
  },
  "updateDownloaded": "Обновление {version} скачано",
  "@updateDownloaded": {
    "placeholders": {
      "version": {
        "type": "String"
      }
    }
  },
  "updateInstall": "Установить",
  "updateHide": "Скрыть",
  "updateDownloadFailed": "Не удалось скачать обновление",
  "updateRetry": "Повторить",
```

- [ ] **Step 2: Добавить ключи в `lib/l10n/app_en.arb`** сразу после `"updateInstallOk": "OK",`

```json
  "updateDownloading": "Downloading {percent}%",
  "@updateDownloading": {
    "placeholders": {
      "percent": {
        "type": "int"
      }
    }
  },
  "updateDownloaded": "Update {version} downloaded",
  "@updateDownloaded": {
    "placeholders": {
      "version": {
        "type": "String"
      }
    }
  },
  "updateInstall": "Install",
  "updateHide": "Hide",
  "updateDownloadFailed": "Couldn't download the update",
  "updateRetry": "Retry",
```

- [ ] **Step 3: Сгенерировать**

Run: `flutter gen-l10n`
Expected: без ошибок; `git status` показывает изменённые `lib/l10n/app_localizations*.dart`. Проверка: `grep -c "updateDownloading" lib/l10n/app_localizations_ru.dart` → `1` или больше.

- [ ] **Step 4: Коммит**

```bash
git add lib/l10n/
git commit -m "feat(обновление): строки карточки обновления"
```

---

### Task 4: `UpdateCard`, «Что нового» и диалоги установки

**Files:**
- Create: `lib/features/dashboard/presentation/widgets/update_card.dart`
- Test: `test/features/dashboard/update_card_test.dart`

- [ ] **Step 1: Написать падающий тест**

`test/features/dashboard/update_card_test.dart`:

```dart
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
```

Добавить в `test/core/services/update_fakes.dart` (нужно тесту «failed»):

```dart
class UpdateDownloadStatusFailed extends UpdateDownloadStatus {
  const UpdateDownloadStatusFailed()
      : super(UpdateDownloadState.failed, reason: 'error_1006', version: '1.1.37', build: 238);
}
```

- [ ] **Step 2: Убедиться, что тест падает**

Run: `flutter test test/features/dashboard/update_card_test.dart`
Expected: FAIL — `Target of URI doesn't exist: '.../widgets/update_card.dart'`.

- [ ] **Step 3: Реализация** — `lib/features/dashboard/presentation/widgets/update_card.dart`

```dart
import 'package:flutter/material.dart';
import 'package:taler_id_mobile/l10n/app_localizations.dart';

import '../../../../core/services/apk_installer_service.dart';
import '../../../../core/services/app_update_controller.dart';
import '../../../../core/theme/app_theme.dart';

/// The update offer. Floats over the home screen (AssistantScreen) and never
/// takes layout space — the old banner pushed every screen down.
class UpdateCard extends StatelessWidget {
  const UpdateCard({super.key, required this.controller});

  final AppUpdateController controller;

  static const _blue = Color(0xFF1565C0);

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        if (!controller.visible) return const SizedBox.shrink();
        final l10n = AppLocalizations.of(context)!;
        final version = controller.version!;
        final phase = controller.phase;
        final notes = controller.info?.latestNotes(Localizations.localeOf(context).languageCode);

        final String title;
        String? actionLabel;
        VoidCallback? onAction;
        switch (phase) {
          case UpdatePhase.available:
            title = l10n.dashboardUpdateAvailable(version);
            actionLabel = l10n.dashboardUpdate;
            onAction = () => controller.startDownload();
          case UpdatePhase.downloading:
            title = l10n.updateDownloading((controller.progress * 100).round());
            actionLabel = l10n.updateHide;
            onAction = controller.dismiss;
          case UpdatePhase.ready:
            title = l10n.updateDownloaded(version);
            actionLabel = l10n.updateInstall;
            onAction = () => controller.install();
          case UpdatePhase.installing:
            title = l10n.dashboardInstalling;
          case UpdatePhase.failed:
            title = l10n.updateDownloadFailed;
            actionLabel = l10n.updateRetry;
            onAction = () => controller.startDownload();
        }
        final showClose = phase != UpdatePhase.downloading && phase != UpdatePhase.installing;
        final showNotes = phase == UpdatePhase.available && (notes?.isNotEmpty ?? false);
        final faded = Colors.white.withValues(alpha: 0.85);

        return Material(
          key: const Key('update-card'),
          color: _blue,
          elevation: 6,
          borderRadius: BorderRadius.circular(16),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 4, 10),
                child: Row(
                  children: [
                    const Icon(Icons.system_update_rounded, color: Colors.white, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (showNotes) ...[
                            const SizedBox(height: 2),
                            GestureDetector(
                              key: const Key('update-card-notes'),
                              onTap: () => showUpdateWhatsNew(context, version, notes!),
                              child: Text(
                                l10n.dashboardWhatsNew,
                                style: TextStyle(
                                  color: faded,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  decoration: TextDecoration.underline,
                                  decorationColor: faded,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (actionLabel != null)
                      TextButton(
                        key: const Key('update-card-action'),
                        onPressed: onAction,
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: 0.2),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          minimumSize: Size.zero,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: Text(
                          actionLabel,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      )
                    else
                      const Padding(
                        padding: EdgeInsets.all(8),
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        ),
                      ),
                    if (showClose)
                      IconButton(
                        key: const Key('update-card-close'),
                        onPressed: controller.dismiss,
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(Icons.close, color: Colors.white, size: 18),
                      )
                    else
                      const SizedBox(width: 8),
                  ],
                ),
              ),
              if (phase == UpdatePhase.downloading)
                LinearProgressIndicator(
                  value: controller.progress,
                  minHeight: 3,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
            ],
          ),
        );
      },
    );
  }
}

void showUpdateWhatsNew(BuildContext context, String version, String notes) {
  final l10n = AppLocalizations.of(context)!;
  final colors = AppColors.of(context);
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: colors.surface,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) => DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      expand: false,
      builder: (ctx, scrollCtrl) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: colors.textSecondary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              l10n.dashboardWhatsNewTitle(version),
              style: TextStyle(color: colors.textPrimary, fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: SingleChildScrollView(
                controller: scrollCtrl,
                child: Text(
                  notes,
                  style: TextStyle(color: colors.textPrimary, fontSize: 14, height: 1.45),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Explains a failed install; success and a declined prompt need no words.
void showUpdateInstallResult(BuildContext context, ApkInstallResponse res, String displayName) {
  final l10n = AppLocalizations.of(context)!;
  final String title;
  final String body;
  switch (res.status) {
    case ApkInstallStatus.success:
    case ApkInstallStatus.aborted:
      return;
    case ApkInstallStatus.conflict:
      title = l10n.updateInstallConflictTitle;
      body = l10n.updateInstallConflictBody(displayName);
    case ApkInstallStatus.downloadFailed:
    case ApkInstallStatus.incompatible:
    case ApkInstallStatus.blocked:
    case ApkInstallStatus.storage:
    case ApkInstallStatus.invalid:
    case ApkInstallStatus.failureUnknown:
      final reason = res.message.isNotEmpty ? res.message : res.status.name;
      title = l10n.updateInstallFailedTitle;
      body = l10n.updateInstallFailedBody(reason, displayName);
  }
  showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(body),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: Text(l10n.updateInstallOk),
        ),
      ],
    ),
  );
}
```

- [ ] **Step 4: Тест проходит**

Run: `flutter test test/features/dashboard/update_card_test.dart`
Expected: PASS, 5 тестов.

- [ ] **Step 5: Коммит**

```bash
git add lib/features/dashboard/presentation/widgets/update_card.dart test/features/dashboard/update_card_test.dart test/core/services/update_fakes.dart
git commit -m "feat(обновление): UpdateCard поверх экрана вместо баннера"
```

---

### Task 5: Подключение — DI, дашборд, главный экран

**Files:**
- Modify: `lib/core/di/service_locator.dart`
- Modify: `lib/features/dashboard/presentation/dashboard_screen.dart`
- Modify: `lib/features/assistant/presentation/screens/assistant_screen.dart`

- [ ] **Step 1: Регистрация в `lib/core/di/service_locator.dart`**

Импорты (рядом с остальными):

```dart
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:url_launcher/url_launcher.dart';
import '../services/apk_installer_service.dart';
import '../services/app_update_controller.dart';
import '../services/call_state_service.dart';
import '../services/update_download_platform.dart';
```

Если какой-то из них уже есть — не дублировать (проверить `grep -n "^import" lib/core/di/service_locator.dart`).

Сразу после строки `sl.registerLazySingleton(() => UpdateCheckService(sl<DioClient>()));`:

```dart
  sl.registerLazySingleton(() => AppUpdateController(
        platform: MethodChannelUpdateDownloadPlatform(),
        install: (path, name) => ApkInstallerService.install(filePath: path, displayName: name),
        openUrl: (url) async {
          await launchUrl(url, mode: LaunchMode.externalApplication);
        },
        isInCall: () =>
            CallStateService.instance.isInCall || CallStateService.instance.isBackgroundConnecting,
        callStateStream: CallStateService.instance.stateStream,
        isAndroid: !kIsWeb && Platform.isAndroid,
      ));
```

- [ ] **Step 2: Дашборд — состояние и жизненный цикл** (`lib/features/dashboard/presentation/dashboard_screen.dart`)

Заменить поля

```dart
  UpdateInfo? _updateInfo;
  bool _updateDismissed = false;
```

на

```dart
  StreamSubscription? _installResultSub;
```

В `initState()` сразу после `WidgetsBinding.instance.addObserver(this);` добавить:

```dart
    // Install outcomes come back here because the card may be gone by then
    // (the install is often offered on its own, after a download).
    final updates = sl<AppUpdateController>();
    _installResultSub = updates.installResults.listen((r) {
      if (mounted) showUpdateInstallResult(context, r.response, r.displayName);
    });
    unawaited(updates.onResumed());
```

В `_checkForUpdate` заменить блок

```dart
    final info = await sl<UpdateCheckService>().checkForUpdate();
    if (info != null && info.isAvailable && mounted) {
      setState(() {
        _updateInfo = info;
        // A newly discovered version un-dismisses the banner: dismissing 1.1.21
        // should not hide 1.1.22.
        _updateDismissed = false;
      });
    }
```

на

```dart
    final info = await sl<UpdateCheckService>().checkForUpdate();
    // A newer version un-dismisses the card by itself (dismissal is per version).
    if (info != null) sl<AppUpdateController>().setInfo(info);
```

В `didChangeAppLifecycleState` сразу после `_checkForUpdate();` в ветке `resumed` добавить:

```dart
      unawaited(sl<AppUpdateController>().onResumed());
```

и в ветке `else if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {` перед `WakeWordService.instance.pause();`:

```dart
      if (state == AppLifecycleState.paused) sl<AppUpdateController>().onPaused();
```

В `dispose()` рядом с остальными `cancel()`:

```dart
    _installResultSub?.cancel();
```

- [ ] **Step 3: Дашборд — убрать баннер**

В `build` удалить блок

```dart
            // Update available banner
            if (_updateInfo != null && _updateInfo!.isAvailable && !_updateDismissed)
              _UpdateBanner(
                version: _updateInfo!.latestVersion,
                downloadUrl: _updateInfo!.downloadUrl,
                notes: _updateInfo!.latestNotes(
                  Localizations.localeOf(context).languageCode,
                ),
                onDismiss: () => setState(() => _updateDismissed = true),
              ),
```

Удалить целиком классы `_UpdateBanner` и `_UpdateBannerState` (от `class _UpdateBanner extends StatefulWidget {` до конца файла).

Импорты: удалить

```dart
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
import 'package:dio/dio.dart' as dio_pkg;
import '../../../core/services/apk_installer_service.dart';
import 'package:path_provider/path_provider.dart';
```

и добавить

```dart
import '../../../core/services/app_update_controller.dart';
import 'widgets/update_card.dart';
```

- [ ] **Step 4: Карточка на главном экране** (`lib/features/assistant/presentation/screens/assistant_screen.dart`)

Импорты:

```dart
import '../../../../core/services/app_update_controller.dart';
import '../../../dashboard/presentation/widgets/update_card.dart';
```

В `_buildIdle` последним элементом `Stack` — заменить

```dart
          ],
        );
      },
    );
  }

  Widget _buildIdleDesktop(AppLocalizations l10n, AppColorsExtension colors) {
```

на

```dart
            // Update offer: floats over the planets and never moves the
            // layout. Only here, not in chats, and only while no assistant
            // session runs — its controls take the bottom of the screen.
            Positioned(
              left: 16,
              right: 16,
              bottom: 16 + MediaQuery.of(context).padding.bottom,
              child: UpdateCard(controller: sl<AppUpdateController>()),
            ),
          ],
        );
      },
    );
  }

  Widget _buildIdleDesktop(AppLocalizations l10n, AppColorsExtension colors) {
```

- [ ] **Step 5: Анализ и полный набор тестов**

Run: `flutter analyze lib/core/di/service_locator.dart lib/features/dashboard/presentation/dashboard_screen.dart lib/features/assistant/presentation/screens/assistant_screen.dart lib/core/services lib/features/dashboard/presentation/widgets`
Expected: ни одного нового замечания в изменённых строках. В `dashboard_screen.dart` до правки было 8 старых (импорты `dart:ui`/`foundation`/`firebase_messaging`, `_currentIndex`, `use_build_context_synchronously` в 115/155/985/1125) — они могут остаться, новых быть не должно.

Run: `flutter test`
Expected: `All tests passed!` (до правки было 1508; плюс 21 новый).

- [ ] **Step 6: Коммит**

```bash
git add lib/core/di/service_locator.dart lib/features/dashboard/presentation/dashboard_screen.dart lib/features/assistant/presentation/screens/assistant_screen.dart
git commit -m "feat(обновление): карточка на главном экране, баннер из дашборда убран"
```

---

### Task 6: Нативная часть Android

**Files:**
- Create: `android/app/src/main/kotlin/tirol/taler/taler_id_mobile/installer/UpdateDownloader.kt`
- Create: `android/app/src/main/kotlin/tirol/taler/taler_id_mobile/installer/UpdateDownloadReceiver.kt`
- Modify: `android/app/src/main/kotlin/tirol/taler/taler_id_mobile/installer/ApkInstaller.kt`
- Modify: `android/app/src/main/kotlin/tirol/taler/taler_id_mobile/MainActivity.kt`
- Modify: `android/app/src/main/AndroidManifest.xml`

Автотестов на Kotlin в проекте нет; проверка — сборка (Step 6) и ручная (Task 7).

- [ ] **Step 1: `UpdateDownloader.kt`**

```kotlin
package tirol.taler.taler_id_mobile.installer

import android.app.DownloadManager
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.util.Log
import androidx.core.app.NotificationCompat
import tirol.taler.taler_id_mobile.MainActivity
import tirol.taler.taler_id_mobile.R
import java.io.File
import java.util.Locale

/**
 * Downloads an update APK with the system DownloadManager, so it survives the
 * app going to the background or being killed, and resumes after the network
 * drops. One download at a time; its id, version and build live in
 * SharedPreferences, so a restarted app picks it up instead of starting over.
 */
object UpdateDownloader {
    private const val TAG = "UpdateDownloader"
    private const val PREFS = "taler_update_download"
    private const val K_ID = "id"
    private const val K_VERSION = "version"
    private const val K_BUILD = "build"
    private const val K_FILE = "file"
    private const val CHANNEL_ID = "app_updates"
    private const val NOTIFICATION_ID = 7301
    const val EXTRA_INSTALL_UPDATE = "install_update"
    private const val UNAVAILABLE = "download_manager_unavailable"

    /** Set when the "downloaded" notification opened the app; Dart consumes it. */
    @Volatile
    var installRequested = false

    fun start(context: Context, url: String, version: String, build: Int): Map<String, Any?> {
        val prefs = prefs(context)
        if (prefs.getLong(K_ID, -1L) != -1L && prefs.getInt(K_BUILD, -1) == build) {
            val current = status(context)
            if (current["state"] in setOf("running", "paused", "ready")) return current
        }
        clear(context) // another version, or a failed attempt: start over
        val dm = context.getSystemService(Context.DOWNLOAD_SERVICE) as? DownloadManager
            ?: return failed(UNAVAILABLE)
        val dir = context.getExternalFilesDir(Environment.DIRECTORY_DOWNLOADS)
            ?: return failed("no_storage")
        val name = "talerid-$version-$build.apk"
        File(dir, name).delete()
        return try {
            val request = DownloadManager.Request(Uri.parse(url))
                .setTitle("Taler ID $version")
                .setMimeType("application/vnd.android.package-archive")
                .setNotificationVisibility(DownloadManager.Request.VISIBILITY_VISIBLE)
                .setAllowedOverMetered(true)
                .setAllowedOverRoaming(true)
                .setDestinationInExternalFilesDir(context, Environment.DIRECTORY_DOWNLOADS, name)
            val id = dm.enqueue(request)
            prefs.edit()
                .putLong(K_ID, id)
                .putString(K_VERSION, version)
                .putInt(K_BUILD, build)
                .putString(K_FILE, File(dir, name).absolutePath)
                .apply()
            status(context)
        } catch (e: Exception) { // DownloadManager disabled on the device, or a bad URL
            Log.e(TAG, "enqueue failed", e)
            failed(UNAVAILABLE)
        }
    }

    fun status(context: Context): Map<String, Any?> {
        val prefs = prefs(context)
        val id = prefs.getLong(K_ID, -1L)
        if (id == -1L) return mapOf("state" to "none")
        val version = prefs.getString(K_VERSION, null)
        val build = prefs.getInt(K_BUILD, -1)
        val file = prefs.getString(K_FILE, null)
        // The app already runs this build or a newer one: the file did its job.
        if (build.toLong() <= installedBuild(context)) {
            clear(context)
            return mapOf("state" to "none")
        }
        val base = mapOf("version" to version, "build" to build, "file" to file)
        val dm = context.getSystemService(Context.DOWNLOAD_SERVICE) as DownloadManager
        dm.query(DownloadManager.Query().setFilterById(id))?.use { c ->
            if (!c.moveToFirst()) { // cancelled from the notification shade
                clear(context)
                return mapOf("state" to "none")
            }
            val st = c.getInt(c.getColumnIndexOrThrow(DownloadManager.COLUMN_STATUS))
            val done = c.getLong(c.getColumnIndexOrThrow(DownloadManager.COLUMN_BYTES_DOWNLOADED_SO_FAR))
            val total = c.getLong(c.getColumnIndexOrThrow(DownloadManager.COLUMN_TOTAL_SIZE_BYTES))
            val reason = c.getInt(c.getColumnIndexOrThrow(DownloadManager.COLUMN_REASON))
            val progress = if (total > 0) done.toDouble() / total else 0.0
            return when (st) {
                DownloadManager.STATUS_SUCCESSFUL ->
                    if (verify(context, file, build)) base + ("state" to "ready")
                    else {
                        clear(context)
                        mapOf("state" to "failed", "reason" to "bad_apk")
                    }
                DownloadManager.STATUS_FAILED -> base + mapOf("state" to "failed", "reason" to "error_$reason")
                DownloadManager.STATUS_PAUSED -> base + mapOf("state" to "paused", "progress" to progress)
                else -> base + mapOf("state" to "running", "progress" to progress)
            }
        }
        return mapOf("state" to "none")
    }

    fun isOurDownload(context: Context, id: Long): Boolean =
        id != -1L && prefs(context).getLong(K_ID, -1L) == id

    /** Forgets the download: removes it from DownloadManager (with its file) and our notification. */
    fun clear(context: Context) {
        val prefs = prefs(context)
        val id = prefs.getLong(K_ID, -1L)
        if (id != -1L) {
            try {
                (context.getSystemService(Context.DOWNLOAD_SERVICE) as DownloadManager).remove(id)
            } catch (e: Exception) {
                Log.w(TAG, "remove failed: ${e.message}")
            }
        }
        prefs.getString(K_FILE, null)?.let { File(it).delete() }
        prefs.edit().clear().apply()
        (context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager).cancel(NOTIFICATION_ID)
    }

    fun showReadyNotification(context: Context) {
        val version = prefs(context).getString(K_VERSION, "") ?: ""
        val ru = Locale.getDefault().language == "ru"
        val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            nm.createNotificationChannel(
                NotificationChannel(
                    CHANNEL_ID,
                    if (ru) "Обновления" else "Updates",
                    NotificationManager.IMPORTANCE_DEFAULT,
                )
            )
        }
        val open = Intent(context, MainActivity::class.java).apply {
            putExtra(EXTRA_INSTALL_UPDATE, true)
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)
        }
        val pi = PendingIntent.getActivity(
            context, NOTIFICATION_ID, open,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        val notification = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_notification)
            .setContentTitle(if (ru) "Обновление $version скачано" else "Update $version downloaded")
            .setContentText(if (ru) "Нажмите, чтобы установить" else "Tap to install")
            .setContentIntent(pi)
            .setAutoCancel(true)
            .build()
        try {
            nm.notify(NOTIFICATION_ID, notification)
        } catch (e: SecurityException) { // POST_NOTIFICATIONS refused on Android 13+
            Log.w(TAG, "notification not allowed: ${e.message}")
        }
    }

    private fun verify(context: Context, path: String?, build: Int): Boolean {
        if (path == null) return false
        val f = File(path)
        if (!f.exists() || f.length() == 0L) return false
        val info = context.packageManager.getPackageArchiveInfo(path, 0) ?: return false
        val code = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) info.longVersionCode
        else @Suppress("DEPRECATION") info.versionCode.toLong()
        return info.packageName == context.packageName && code == build.toLong()
    }

    private fun installedBuild(context: Context): Long {
        val pi = context.packageManager.getPackageInfo(context.packageName, 0)
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) pi.longVersionCode
        else @Suppress("DEPRECATION") pi.versionCode.toLong()
    }

    private fun failed(reason: String): Map<String, Any?> = mapOf("state" to "failed", "reason" to reason)

    private fun prefs(context: Context) = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
}
```

- [ ] **Step 2: `UpdateDownloadReceiver.kt`**

```kotlin
package tirol.taler.taler_id_mobile.installer

import android.app.DownloadManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import tirol.taler.taler_id_mobile.MainActivity

/**
 * Declared in the manifest, so it fires even when the app is not running.
 * On screen the app polls the status and offers the install itself; off
 * screen it can't open the installer (Android 10+ blocks activity starts from
 * the background), so it gets a "downloaded — tap to install" notification.
 */
class UpdateDownloadReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != DownloadManager.ACTION_DOWNLOAD_COMPLETE) return
        val id = intent.getLongExtra(DownloadManager.EXTRA_DOWNLOAD_ID, -1L)
        if (!UpdateDownloader.isOurDownload(context, id)) return
        if (MainActivity.isInForeground) return
        if (UpdateDownloader.status(context)["state"] == "ready") {
            UpdateDownloader.showReadyNotification(context)
        }
    }
}
```

- [ ] **Step 3: Методы канала в `ApkInstaller.kt`**

В `when (call.method)` перед `else -> result.notImplemented()`:

```kotlin
                "startDownload" -> {
                    val url = call.argument<String>("url")
                    val version = call.argument<String>("version")
                    val build = call.argument<Int>("build")
                    if (url == null || version == null || build == null) {
                        result.error("invalid_args", "url, version and build required", null)
                        return@setMethodCallHandler
                    }
                    result.success(UpdateDownloader.start(context, url, version, build))
                }
                "downloadStatus" -> result.success(UpdateDownloader.status(context))
                "cancelDownload" -> {
                    UpdateDownloader.clear(context)
                    result.success(null)
                }
                "consumeInstallRequest" -> {
                    val requested = UpdateDownloader.installRequested
                    UpdateDownloader.installRequested = false
                    result.success(requested)
                }
```

- [ ] **Step 4: `MainActivity.kt`**

Импорт рядом с `import tirol.taler.taler_id_mobile.installer.ApkInstaller`:

```kotlin
import tirol.taler.taler_id_mobile.installer.UpdateDownloader
```

Сразу после строки `class MainActivity : FlutterFragmentActivity() {`:

```kotlin
    companion object {
        /** Read by UpdateDownloadReceiver: on screen the app offers the install itself. */
        @Volatile
        @JvmStatic
        var isInForeground = false
    }
```

Заменить

```kotlin
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        createNotificationChannels()
    }
```

на

```kotlin
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        createNotificationChannels()
        handleUpdateIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        handleUpdateIntent(intent)
    }

    override fun onResume() {
        super.onResume()
        isInForeground = true
    }

    override fun onPause() {
        isInForeground = false
        super.onPause()
    }

    /** The "update downloaded" notification opened the app: Dart installs it. */
    private fun handleUpdateIntent(intent: Intent?) {
        if (intent?.getBooleanExtra(UpdateDownloader.EXTRA_INSTALL_UPDATE, false) == true) {
            UpdateDownloader.installRequested = true
            intent.removeExtra(UpdateDownloader.EXTRA_INSTALL_UPDATE)
        }
    }
```

- [ ] **Step 5: Приёмник в `AndroidManifest.xml`**

Заменить

```xml
        </activity>
        <service
            android:name=".MeshForegroundService"
```

на

```xml
        </activity>
        <!-- Update APK finished downloading (UpdateDownloader): exported because
             the sender is the system DownloadManager; the receiver checks the
             id against its own download and queries the real status. -->
        <receiver
            android:name=".installer.UpdateDownloadReceiver"
            android:exported="true">
            <intent-filter>
                <action android:name="android.intent.action.DOWNLOAD_COMPLETE" />
            </intent-filter>
        </receiver>
        <service
            android:name=".MeshForegroundService"
```

- [ ] **Step 6: Сборка**

Run: `flutter build apk --flavor dev --debug -t lib/main_dev.dart --dart-define=FLAVOR=dev --dart-define=BASE_URL=https://staging.id.taler.tirol`
Expected: `✓ Built build/app/outputs/flutter-apk/app-dev-debug.apk`. Ошибки компиляции Kotlin — исправить по сообщению (`onNewIntent` у `FlutterFragmentActivity` в Flutter 3.38 принимает `Intent` без `?`).

- [ ] **Step 7: Коммит**

```bash
git add android/app/src/main/kotlin/tirol/taler/taler_id_mobile/installer/UpdateDownloader.kt android/app/src/main/kotlin/tirol/taler/taler_id_mobile/installer/UpdateDownloadReceiver.kt android/app/src/main/kotlin/tirol/taler/taler_id_mobile/installer/ApkInstaller.kt android/app/src/main/kotlin/tirol/taler/taler_id_mobile/MainActivity.kt android/app/src/main/AndroidManifest.xml
git commit -m "feat(обновление): загрузка APK системным DownloadManager и уведомление «скачано»"
```

---

### Task 7: Проверка на эмуляторе

Установка поверх возможна только при той же подписи, что у выложенного `taler-id-dev.apk` (отладочный ключ aeza, SHA-256 `550899…`), поэтому тестовая сборка собирается **на aeza**, с номером ниже объявленного DEV (`237`).

- [ ] **Step 1: Запушить ветку и собрать на aeza с номером 236**

```bash
git push -u origin feat/update-background-download
ssh dvolkov@138.124.61.221 'cd ~/taler_id_mobile && git fetch -q origin && git checkout -q -B feat/update-background-download origin/feat/update-background-download && bash -lc "flutter build apk --flavor dev --release -t lib/main_dev.dart --dart-define=FLAVOR=dev --dart-define=BASE_URL=https://staging.id.taler.tirol --build-number=236" && cp build/app/outputs/flutter-apk/app-dev-release.apk ~/apk-update-test-236.apk; git checkout -q main && git reset -q --hard origin/main'
scp dvolkov@138.124.61.221:apk-update-test-236.apk /tmp/
```

Expected: `✓ Built …app-dev-release.apk`, сборочный клон на aeza возвращён на `main`.

- [ ] **Step 2: Поставить на эмулятор и войти**

```bash
~/Library/Android/sdk/emulator/emulator -avd Pixel_XL_API_33 -memory 4096 -no-boot-anim &
adb -s emulator-5554 uninstall tirol.taler.taler_id_mobile.dev; adb -s emulator-5554 install /tmp/apk-update-test-236.apk
```

Войти `integration_test_2@taler-test.com` / `IntegrationTest123!`, разрешить уведомления.
Expected: на главном экране внизу карточка «Update available 1.1.36» или «Доступно обновление 1.1.36»; планеты не сдвинуты; в чатах карточки нет.

- [ ] **Step 3: Сценарии из спецификации** — по каждому записать фактический результат:
  1. «Обновить» при открытом приложении → прогресс в карточке и в шторке → системное «Установить» → после установки версия 1.1.36 (237).
  2. Переставить 236, начать, свернуть (HOME), дождаться → уведомление «Обновление 1.1.36 скачано» → нажатие → «Установить».
  3. Переставить 236, начать, `adb shell am kill tirol.taler.taler_id_mobile.dev` при свёрнутом приложении → загрузка в шторке продолжается → открыть приложение после окончания → установка предлагается сама.
  4. Переставить 236, начать, `adb shell svc wifi disable; adb shell svc data disable` на 20 с, затем включить → прогресс продолжается с места, а не с нуля.
  5. Во время загрузки открыть разговор с ассистентом → карточки нет; вернуться → карточка с прогрессом.

- [ ] **Step 4: Ни одна сборка не выкладывается в `/var/www/downloads` и не объявляется** — это проверка ветки, релиз отдельно по команде пользователя.

---

### Task 8: Завершение

- [ ] **Step 1:** `flutter test` целиком → `All tests passed!`.
- [ ] **Step 2:** Отчёт пользователю: что сделано, результаты Task 7 по каждому сценарию, что не проверено (iOS-карточка на устройстве). Слияние в `dev`/`main` и релиз — только по его команде (по процедуре из CLAUDE.md: версия, `APP_RELEASES`, все сборки, объявление последним).

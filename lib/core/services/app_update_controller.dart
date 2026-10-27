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
    final s = await _platform.status();
    // AMENDMENT: a failed status *call* says nothing about the download
    // itself — keep what we knew and ask again on the next poll.
    if (s.reason == UpdateDownloadStatus.channelError) return;
    _apply(s);
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

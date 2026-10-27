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
    // An automatic offer waits for the screen to settle: a call being
    // answered or rung shows up a moment after resume, and a call that just
    // ended is still tearing down.
    Duration offerDelay = const Duration(seconds: 2),
    // A due install blocked by a call asks again this often: not every kind
    // of call reports its end (mesh calls don't).
    Duration callRecheck = const Duration(seconds: 5),
    // Anything ringing or connecting in the system call UI; asked right
    // before an automatic install.
    Future<bool> Function()? isRinging,
  })  : _platform = platform,
        _install = install,
        _openUrl = openUrl,
        _isInCall = isInCall,
        _isAndroid = isAndroid,
        _pollInterval = pollInterval,
        _offerDelay = offerDelay,
        _callRecheck = callRecheck,
        _isRinging = isRinging {
    _callSub = callStateStream.listen(_onCallState);
  }

  final UpdateDownloadPlatform _platform;
  final UpdateInstallFn _install;
  final Future<void> Function(Uri url) _openUrl;
  final bool Function() _isInCall;
  final bool _isAndroid;
  final Duration _pollInterval;
  final Duration _offerDelay;
  final Duration _callRecheck;
  final Future<bool> Function()? _isRinging;
  late final StreamSubscription<bool> _callSub;
  final _installResults = StreamController<UpdateInstallResult>.broadcast();

  UpdateInfo? _info;
  UpdateDownloadStatus _download = UpdateDownloadStatus.none;
  UpdatePhase _phase = UpdatePhase.available;
  String? _dismissedVersion;
  bool _foreground = true;
  bool _starting = false;
  bool _disposed = false;

  /// Build whose finished download was already offered this launch: every
  /// newly finished download is offered once, by itself.
  int? _offeredBuild;

  /// An install is due (a newly finished download, the "downloaded"
  /// notification) but waits until the app is on screen and out of a call.
  bool _installDue = false;
  Timer? _poll;

  /// Pending automatic offer — the delay before an install due is actually
  /// opened, or the wait for the next in-call recheck.
  Timer? _offer;

  /// The system call UI question an offer is waiting on. Dropped when the app
  /// leaves the screen, so a late answer cannot install right after a return.
  Object? _ringQuery;

  /// The last check found a call: the next clear one waits [_offerDelay]
  /// more, so a call that just ended can finish tearing down.
  bool _sawCall = false;

  UpdateInfo? get info => _info;
  UpdatePhase get phase => _phase;
  double get progress => _download.progress ?? 0;
  String? get failure => _download.reason;
  Stream<UpdateInstallResult> get installResults => _installResults.stream;

  /// The version the card talks about. Once `/app/version` has answered, the
  /// server decides: no update means no card, even for a remembered download
  /// of a build it no longer advertises. Before it answers — a cold start —
  /// the download on disk speaks for itself.
  String? get version {
    final info = _info;
    if (info != null) return info.isAvailable ? info.latestVersion : null;
    // Right after a restart, before /app/version answers: the download on disk.
    return _download.state == UpdateDownloadState.none ? null : _download.version;
  }

  bool get visible {
    final v = version;
    return v != null && v != _dismissedVersion;
  }

  /// Whether Update/Retry has something to download: right after a restart
  /// the card can show a remembered failure before /app/version answers.
  bool get canStartDownload => _info?.isAvailable == true;

  void setInfo(UpdateInfo info) {
    _info = info;
    _apply(_download);
  }

  /// Hides the card until a newer version shows up; a running download goes on.
  void dismiss() {
    _dismissedVersion = version;
    _notify();
  }

  Future<void> startDownload() async {
    final info = _info;
    if (info == null || !info.isAvailable || _starting) return;
    if (!_isAndroid) {
      await _openUrl(Uri.parse(info.downloadUrl));
      return;
    }
    // No polling until start answers: an early "none" would flash "Обновить".
    _starting = true;
    _setPhase(UpdatePhase.downloading);
    UpdateDownloadStatus s;
    try {
      s = await _platform.start(
        url: info.downloadUrl,
        version: info.latestVersion,
        build: info.latestBuild,
      );
    } catch (e) {
      // The wrapper already maps channel errors; anything else still must not
      // leave the card on "Скачивается 0%".
      s = UpdateDownloadStatus(UpdateDownloadState.failed, reason: '$e');
    } finally {
      _starting = false;
    }
    if (_disposed) return;
    if (s.state == UpdateDownloadState.failed &&
        (s.reason == UpdateDownloadStatus.unavailable ||
            s.reason == UpdateDownloadStatus.wrongPackage ||
            s.reason == UpdateDownloadStatus.channelError)) {
      // No usable DownloadManager on this device: the browser downloads it.
      // The server sends this flavor to another app (TEST → PROD): the browser downloads it as a separate install.
      // DownloadManager can't even be asked about the download: the browser is the way out.
      _download = UpdateDownloadStatus.none;
      _setPhase(UpdatePhase.available);
      await _openUrl(Uri.parse(info.downloadUrl));
      return;
    }
    _apply(s);
    if (_phase == UpdatePhase.ready) {
      // Downloaded earlier already: the tap asks to install now, call or not.
      _offeredBuild = _download.build;
      await install();
    }
  }

  /// Asks the system installer to replace the app. On success Android kills
  /// this process, so getting past the await means it did not happen.
  Future<void> install() async {
    final file = _download.file;
    if (_phase != UpdatePhase.ready || file == null) return;
    _installDue = false;
    final name = 'talerid-${_download.version ?? version ?? 'update'}.apk';
    _setPhase(UpdatePhase.installing);
    ApkInstallResponse response;
    try {
      response = await _install(file, name);
    } catch (e) {
      response = ApkInstallResponse(ApkInstallStatus.failureUnknown, '$e');
    }
    if (_disposed) return;
    _leaveInstalling();
    _installResults.add((response: response, displayName: name));
    // A failed install can change the download too: an APK not signed by us
    // is deleted natively, and the card must stop offering to install it.
    if (!_disposed) unawaited(refresh());
  }

  Future<void> onResumed() async {
    _foreground = true;
    if (!_isAndroid || _disposed) return;
    // Back without an answer from the system installer (e.g. Home pressed on
    // its dialog): the card must not stay on "Установка…" for good.
    _leaveInstalling();
    _syncPolling();
    if (await _platform.consumeInstallRequest()) _installDue = true;
    await refresh();
    _maybeInstall();
  }

  void onPaused() {
    _foreground = false;
    _offer?.cancel();
    _offer = null;
    _ringQuery = null;
    _sawCall = false;
    _syncPolling();
  }

  Future<void> refresh() => _refresh();

  /// [polled]: asked by the poll timer, i.e. on screen while downloading.
  Future<void> _refresh({bool polled = false}) async {
    if (!_isAndroid || _disposed) return;
    final s = await _platform.status();
    if (_disposed) return;
    // A failed status call says nothing about the download itself: keep what
    // we knew and ask again on the next poll.
    if (s.reason == UpdateDownloadStatus.channelError) return;
    final wasDownloading = _phase == UpdatePhase.downloading;
    _apply(s);
    final info = _info;
    if (polled &&
        wasDownloading &&
        _foreground &&
        s.state == UpdateDownloadState.failed &&
        s.reason == UpdateDownloadStatus.wrongPackage &&
        info != null &&
        info.isAvailable) {
      // The finished file turned out to be another app (TEST → PROD) while
      // the user waits on screen after tapping Update: the browser finishes
      // the job as a separate install. Off screen nothing opens, and neither
      // does the return: the card says Update, and a tap reaches the browser
      // through startDownload.
      await _openUrl(Uri.parse(info.downloadUrl));
      if (_disposed) return;
    }
    if (_phase == UpdatePhase.ready && _download.build != _offeredBuild) {
      _offeredBuild = _download.build;
      _installDue = true;
    }
    _maybeInstall();
  }

  /// Opens the installer when an install is due, but only on screen and out
  /// of a call: installing closes the app and would cut the conversation.
  /// The offer waits [_offerDelay] and checks again; while a call blocks it,
  /// it checks every [_callRecheck] and on every call-state change, and once
  /// clear it waits [_offerDelay] once more. Last of all it asks the system
  /// call UI, which rings some calls without anything in the app.
  void _maybeInstall() {
    if (!_canOffer()) {
      _offer?.cancel();
      _offer = null;
      return;
    }
    if (_ringQuery != null || (_offer?.isActive ?? false)) return;
    if (_isInCall()) {
      _blocked();
      return;
    }
    // This wait is also the settle time after a call.
    _sawCall = false;
    if (_offerDelay == Duration.zero) {
      _offerNow();
    } else {
      _offer = Timer(_offerDelay, _offerNow);
    }
  }

  bool _canOffer() =>
      !_disposed &&
      _installDue &&
      _phase == UpdatePhase.ready &&
      _foreground &&
      version != null; // the server no longer advertises this build otherwise

  void _offerNow() {
    _offer = null;
    if (!_canOffer() || _ringQuery != null) return;
    if (_isInCall()) {
      _blocked();
      return;
    }
    final ringing = _isRinging;
    if (ringing == null) {
      _offerIfClear();
      return;
    }
    final query = _ringQuery = Object();
    // A failing question must not hold the update back for good.
    unawaited(Future.sync(ringing).catchError((_) => false).then((r) {
      if (!identical(query, _ringQuery)) return;
      _ringQuery = null;
      if (!_canOffer()) return;
      if (r || _isInCall()) {
        _blocked();
      } else {
        _offerIfClear();
      }
    }));
  }

  /// A call or a ring is there: wait for its end (stream) or the next recheck.
  void _blocked() {
    _sawCall = true;
    if (_callRecheck > Duration.zero) _offer = Timer(_callRecheck, _offerNow);
  }

  /// Nothing blocks the install now; right after a call it waits [_offerDelay]
  /// and checks again first.
  void _offerIfClear() {
    if (_sawCall && _offerDelay > Duration.zero) {
      _sawCall = false;
      _offer = Timer(_offerDelay, _offerNow);
      return;
    }
    _sawCall = false;
    _installDue = false;
    unawaited(install());
  }

  void _onCallState(bool inCall) {
    if (inCall) return;
    // A call ended: start the wait over as [_offerDelay] rather than sit out
    // a recheck. _maybeInstall asks isInCall() itself: a line can end while
    // another one is still joining, and the event alone would miss that.
    _offer?.cancel();
    _offer = null;
    _maybeInstall();
  }

  /// Lets the latest known download state decide the card again.
  void _leaveInstalling() {
    if (_phase != UpdatePhase.installing) return;
    _phase = UpdatePhase.ready;
    _apply(_download);
  }

  void _apply(UpdateDownloadStatus s) {
    if (_disposed) return;
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
            // Downloading again gets the same other app: Update goes to the
            // browser instead (startDownload), not to a Retry.
            UpdateDownloadState.failed when s.reason == UpdateDownloadStatus.wrongPackage =>
              UpdatePhase.available,
            UpdateDownloadState.failed => UpdatePhase.failed,
          };
    _syncPolling();
    _notify();
  }

  void _setPhase(UpdatePhase p) {
    if (_disposed) return;
    _phase = p;
    _syncPolling();
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  void _syncPolling() {
    final want = !_disposed &&
        _isAndroid &&
        _foreground &&
        !_starting &&
        _phase == UpdatePhase.downloading;
    if (want && _poll == null) {
      _poll = Timer.periodic(_pollInterval, (_) => unawaited(_refresh(polled: true)));
    } else if (!want) {
      _poll?.cancel();
      _poll = null;
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _poll?.cancel();
    _poll = null;
    _offer?.cancel();
    _offer = null;
    unawaited(_callSub.cancel());
    unawaited(_installResults.close());
    super.dispose();
  }
}

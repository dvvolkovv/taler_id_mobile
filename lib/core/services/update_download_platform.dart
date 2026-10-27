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

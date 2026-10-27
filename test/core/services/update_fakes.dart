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
  Object? startError;

  @override
  Future<UpdateDownloadStatus> start({
    required String url,
    required String version,
    required int build,
  }) async {
    starts.add('$url|$version|$build');
    if (startError != null) throw startError!;
    return startResult;
  }

  /// Set to hold status calls until completed (an answer landing later).
  Completer<UpdateDownloadStatus>? statusGate;

  @override
  Future<UpdateDownloadStatus> status() async {
    statusCalls++;
    if (statusGate != null) return statusGate!.future;
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

  /// Set to make the installer throw.
  Object? installError;

  /// Set to make the installer hang until completed (dialog left with Home).
  Completer<ApkInstallResponse>? installGate;

  /// What the installer answers.
  ApkInstallResponse installResponse = const ApkInstallResponse(ApkInstallStatus.aborted, '');

  /// Offers without delay unless a test asks for the real timing.
  AppUpdateController controller({
    bool android = true,
    Duration offerDelay = Duration.zero,
    Duration callRecheck = Duration.zero,
    Future<bool> Function()? isRinging,
  }) =>
      AppUpdateController(
        platform: platform,
        install: (path, name) async {
          installs.add('$path|$name');
          if (installError != null) throw installError!;
          if (installGate != null) return installGate!.future;
          return installResponse;
        },
        openUrl: (url) async => opened.add(url),
        isInCall: () => inCall,
        callStateStream: calls.stream,
        isAndroid: android,
        offerDelay: offerDelay,
        callRecheck: callRecheck,
        isRinging: isRinging,
      );
}

UpdateInfo info({String v = '1.1.37', int b = 238, String notes = '', bool available = true}) =>
    UpdateInfo(
      isAvailable: available,
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

class UpdateDownloadStatusFailed extends UpdateDownloadStatus {
  const UpdateDownloadStatusFailed()
      : super(UpdateDownloadState.failed, reason: 'error_1006', version: '1.1.37', build: 238);
}

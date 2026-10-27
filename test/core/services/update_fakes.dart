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

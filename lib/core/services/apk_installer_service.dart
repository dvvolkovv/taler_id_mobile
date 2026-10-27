import 'dart:io';
import 'package:flutter/services.dart';

enum ApkInstallStatus {
  success,
  conflict,
  incompatible,
  blocked,
  aborted,
  storage,
  invalid,
  downloadFailed,
  failureUnknown,
}

class ApkInstallResponse {
  final ApkInstallStatus status;
  final String message;
  const ApkInstallResponse(this.status, this.message);

  static ApkInstallResponse _fromMap(Map<dynamic, dynamic> m) {
    final s = (m['status'] as String?) ?? 'failureUnknown';
    final msg = (m['message'] as String?) ?? '';
    return ApkInstallResponse(_parse(s), msg);
  }

  static ApkInstallStatus _parse(String s) {
    switch (s) {
      case 'success':
        return ApkInstallStatus.success;
      case 'conflict':
        return ApkInstallStatus.conflict;
      case 'incompatible':
        return ApkInstallStatus.incompatible;
      case 'blocked':
        return ApkInstallStatus.blocked;
      case 'aborted':
        return ApkInstallStatus.aborted;
      case 'storage':
        return ApkInstallStatus.storage;
      case 'invalid':
        return ApkInstallStatus.invalid;
      case 'downloadFailed':
        return ApkInstallStatus.downloadFailed;
      default:
        return ApkInstallStatus.failureUnknown;
    }
  }
}

class ApkInstallerService {
  static const _channel = MethodChannel('taler_id/installer');

  static Future<ApkInstallResponse> install({
    required String filePath,
    required String displayName,
  }) async {
    if (!Platform.isAndroid) {
      return const ApkInstallResponse(
          ApkInstallStatus.failureUnknown, 'Android only');
    }
    try {
      final res = await _channel.invokeMethod<Map<dynamic, dynamic>>('install', {
        'path': filePath,
        'displayName': displayName,
      });
      if (res == null) {
        return const ApkInstallResponse(ApkInstallStatus.failureUnknown, '');
      }
      return ApkInstallResponse._fromMap(res);
    } on PlatformException catch (e) {
      return ApkInstallResponse(
          ApkInstallStatus.failureUnknown, e.message ?? e.code);
    }
  }
}

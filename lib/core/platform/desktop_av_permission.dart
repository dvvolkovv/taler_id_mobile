import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'platform_utils.dart';

/// macOS-native microphone/camera permission requester.
///
/// `permission_handler` 11.x/12.x does NOT support macOS (only android, ios,
/// web). Calling `Permission.microphone.request()` on macOS is a no-op and
/// returns immediately without showing any TCC popup or registering the app
/// in System Settings → Privacy & Security.
///
/// This wrapper routes through a Swift MethodChannel on macOS that calls
/// `AVCaptureDevice.requestAccess(for:)` directly. On mobile platforms it
/// delegates to `permission_handler` (which works there).
///
/// On Windows and Linux it returns granted=true (no permission system).
class DesktopAvPermission {
  static const _channel =
      MethodChannel('tirol.taler.talerIdMobile/av_permission');

  DesktopAvPermission._();

  /// Requests microphone access. On macOS triggers the system popup; once
  /// granted, the app appears in System Settings → Privacy & Security →
  /// Microphone. Returns true on grant.
  static Future<bool> requestMicrophone() async {
    if (PlatformUtils.instance.isMacOS) {
      try {
        final granted =
            await _channel.invokeMethod<bool>('requestMicrophone');
        return granted ?? false;
      } catch (_) {
        return false;
      }
    }
    if (PlatformUtils.instance.isMobile) {
      final status = await Permission.microphone.request();
      return status.isGranted;
    }
    // Windows / Linux — no TCC, treat as granted.
    return true;
  }

  /// Requests camera access. Same shape as [requestMicrophone].
  static Future<bool> requestCamera() async {
    if (PlatformUtils.instance.isMacOS) {
      try {
        final granted = await _channel.invokeMethod<bool>('requestCamera');
        return granted ?? false;
      } catch (_) {
        return false;
      }
    }
    if (PlatformUtils.instance.isMobile) {
      final status = await Permission.camera.request();
      return status.isGranted;
    }
    return true;
  }

  /// Returns current microphone authorization status.
  /// macOS values: 0=notDetermined, 1=restricted, 2=denied, 3=authorized.
  static Future<int> checkMicrophone() async {
    if (PlatformUtils.instance.isMacOS) {
      try {
        return await _channel.invokeMethod<int>('checkMicrophone') ?? 0;
      } catch (_) {
        return 0;
      }
    }
    if (PlatformUtils.instance.isMobile) {
      final s = await Permission.microphone.status;
      if (s.isGranted) return 3;
      if (s.isDenied) return 2;
      return 0;
    }
    return 3; // assume granted on Win/Linux
  }
}

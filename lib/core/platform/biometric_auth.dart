// lib/core/platform/biometric_auth.dart
import 'package:flutter/foundation.dart';
import 'platform_utils.dart';
import 'biometric_auth_mobile.dart';
import 'biometric_auth_desktop.dart';

/// Biometric type enum mirrored from local_auth (avoids leaking the plugin).
enum BiometricKind { fingerprint, face, iris, weak, strong }

/// Platform-agnostic interface for biometric / device-credential authentication.
///
/// Mobile (iOS, Android) → [BiometricAuthMobile] (delegates to `local_auth`).
/// Desktop (macOS, Windows, Linux) → [BiometricAuthDesktop] (always returns false).
///
/// Use [debugResetForTest] in unit tests to force re-initialisation.
abstract class BiometricAuthPlatform {
  static BiometricAuthPlatform? _instance;

  static BiometricAuthPlatform get instance =>
      _instance ??= PlatformUtils.instance.isMobile
          ? BiometricAuthMobile()
          : BiometricAuthDesktop();

  /// Whether the device has any biometrics enrolled AND can check them.
  Future<bool> get canCheckBiometrics;

  /// Whether the device supports biometrics or device credentials.
  Future<bool> get isDeviceSupported;

  /// List of available biometric types on this device.
  Future<List<BiometricKind>> getAvailableBiometrics();

  /// Attempt authentication. Returns true if the user successfully authenticated.
  ///
  /// [localizedReason] is shown to the user in the system prompt.
  /// [biometricOnly] prevents fallback to device PIN/password when false.
  Future<bool> authenticate({
    required String localizedReason,
    bool biometricOnly = false,
  });

  @visibleForTesting
  static void debugResetForTest() => _instance = null;
}

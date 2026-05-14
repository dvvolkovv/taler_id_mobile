// lib/core/platform/biometric_auth_desktop.dart
import 'biometric_auth.dart';

/// [BiometricAuthPlatform] no-op implementation for macOS, Windows, and Linux.
///
/// Desktop platforms do not expose a hardware biometric sensor via `local_auth`.
/// All methods return false / empty so callers degrade gracefully without
/// platform-channel calls.
class BiometricAuthDesktop implements BiometricAuthPlatform {
  @override
  Future<bool> get canCheckBiometrics async => false;

  @override
  Future<bool> get isDeviceSupported async => false;

  @override
  Future<List<BiometricKind>> getAvailableBiometrics() async => [];

  @override
  Future<bool> authenticate({
    required String localizedReason,
    bool biometricOnly = false,
  }) async =>
      false;
}

// lib/core/platform/biometric_auth_mobile.dart
import 'package:local_auth/local_auth.dart';
import 'biometric_auth.dart';

/// [BiometricAuthPlatform] implementation for iOS and Android.
///
/// Delegates to `package:local_auth`. A single [LocalAuthentication] instance
/// is reused across calls (the plugin is stateless between invocations).
class BiometricAuthMobile implements BiometricAuthPlatform {
  final _auth = LocalAuthentication();

  @override
  Future<bool> get canCheckBiometrics => _auth.canCheckBiometrics;

  @override
  Future<bool> get isDeviceSupported => _auth.isDeviceSupported();

  @override
  Future<List<BiometricKind>> getAvailableBiometrics() async {
    final types = await _auth.getAvailableBiometrics();
    return types.map(_toKind).toList();
  }

  @override
  Future<bool> authenticate({
    required String localizedReason,
    bool biometricOnly = false,
  }) =>
      _auth.authenticate(
        localizedReason: localizedReason,
        options: AuthenticationOptions(biometricOnly: biometricOnly),
      );

  static BiometricKind _toKind(BiometricType t) {
    switch (t) {
      case BiometricType.fingerprint:
        return BiometricKind.fingerprint;
      case BiometricType.face:
        return BiometricKind.face;
      case BiometricType.iris:
        return BiometricKind.iris;
      case BiometricType.weak:
        return BiometricKind.weak;
      case BiometricType.strong:
        return BiometricKind.strong;
    }
  }
}

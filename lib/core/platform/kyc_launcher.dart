// lib/core/platform/kyc_launcher.dart
import 'package:flutter/foundation.dart';
import 'kyc_launcher_desktop.dart';

/// Result of a KYC SDK session.
class KycLaunchResult {
  /// Whether the user completed the verification flow successfully.
  final bool success;

  /// Whether the session was skipped (e.g. web platform, or no URL provided).
  final bool skipped;

  /// Human-readable error message, if any.
  final String? errorMessage;

  /// Raw error type string from the SDK.
  final String? errorType;

  const KycLaunchResult({
    required this.success,
    this.skipped = false,
    this.errorMessage,
    this.errorType,
  });

  const KycLaunchResult.skipped()
      : success = false,
        skipped = true,
        errorMessage = null,
        errorType = null;
}

/// Launches the KYC WebSDK wizard.
///
/// All native platforms (iOS, Android, macOS, Linux, Windows) open the WebSDK
/// inside an in-app WebView via the `/kyc/webview` route. Web shows a
/// platform-not-supported result (the caller renders a dialog).
///
/// `webSdkUrl` is built by the backend as
/// `${SUMSUB_BASE_URL}/idensic/sdk/checkup?accessToken=<token>` — the wizard is
/// auth'd via the access-token in the URL, no extra headers.
abstract class KycLauncherPlatform {
  static KycLauncherPlatform? _instance;

  static KycLauncherPlatform get instance =>
      _instance ??= KycLauncherDesktop();

  Future<KycLaunchResult> launch({required String webSdkUrl});

  @visibleForTesting
  static void debugResetForTest() => _instance = null;
}

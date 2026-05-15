// lib/core/platform/kyc_launcher.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show Locale;
import 'platform_utils.dart';
import 'kyc_launcher_mobile.dart';
import 'kyc_launcher_desktop.dart';

/// Result of a KYC/KYB SDK session.
class KycLaunchResult {
  /// Whether the user completed the verification flow successfully.
  final bool success;

  /// Whether the session was skipped (e.g. desktop platform, web, or test stub).
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

  /// Convenience constructor for a platform-not-supported result.
  const KycLaunchResult.skipped()
      : success = false,
        skipped = true,
        errorMessage = null,
        errorType = null;
}

/// Platform-agnostic interface for launching the Sumsub KYC/KYB SDK.
///
/// Mobile (iOS, Android) → [KycLauncherMobile] (delegates to
/// `flutter_idensic_mobile_sdk_plugin`).
/// Desktop (macOS, Windows, Linux) → [KycLauncherDesktop] (navigates to
/// `/kyc/webview` with the Sumsub Web SDK URL).
///
/// Use [debugResetForTest] in unit tests to force re-initialisation.
abstract class KycLauncherPlatform {
  static KycLauncherPlatform? _instance;

  static KycLauncherPlatform get instance =>
      _instance ??= PlatformUtils.instance.isMobile
          ? KycLauncherMobile()
          : KycLauncherDesktop();

  /// Launch the Sumsub KYC SDK.
  ///
  /// [sdkToken] is the Sumsub Mobile SDK token (mobile only; null on desktop).
  /// [webSdkUrl] is the Sumsub Web SDK URL (desktop only; null on mobile).
  /// [onTokenExpiration] is called when the token expires; must return a fresh token.
  /// [locale] sets the SDK UI language (defaults to 'ru').
  /// [debug] enables SDK debug logging.
  Future<KycLaunchResult> launch({
    String? sdkToken,
    String? webSdkUrl,
    required Future<String?> Function() onTokenExpiration,
    Locale locale = const Locale('ru'),
    bool debug = true,
  });

  @visibleForTesting
  static void debugResetForTest() => _instance = null;
}

// lib/core/platform/kyc_launcher_desktop.dart
import 'package:flutter/widgets.dart' show Locale;

import 'kyc_launcher.dart';

/// [KycLauncherPlatform] Phase-1 stub for macOS, Windows, and Linux.
///
/// The Sumsub SDK is a mobile-only plugin and cannot run on desktop.
/// This stub returns [KycLaunchResult.skipped] immediately so callers can
/// surface a "Not available on desktop" message to the user.
class KycLauncherDesktop implements KycLauncherPlatform {
  @override
  Future<KycLaunchResult> launch({
    required String sdkToken,
    required Future<String?> Function() onTokenExpiration,
    Locale locale = const Locale('ru'),
    bool debug = true,
  }) async =>
      const KycLaunchResult.skipped();
}

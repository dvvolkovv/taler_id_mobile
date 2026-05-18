// lib/core/platform/kyc_launcher_desktop.dart
import 'package:flutter/widgets.dart' show Locale;

import '../router/app_router.dart';
import 'kyc_launcher.dart';

/// [KycLauncherPlatform] implementation for macOS, Windows, and Linux.
///
/// Instead of the mobile-only Sumsub SDK plugin, this opens the Sumsub Web SDK
/// via [KycWebViewScreen] at route `/kyc/webview`. The WebView calls
/// [onComplete] when the SDK signals completion.
///
/// Returns [KycLaunchResult.skipped] if no [webSdkUrl] is provided.
class KycLauncherDesktop implements KycLauncherPlatform {
  @override
  Future<KycLaunchResult> launch({
    String? sdkToken,
    String? webSdkUrl,
    required Future<String?> Function() onTokenExpiration,
    Locale locale = const Locale('ru'),
    bool debug = true,
  }) async {
    if (webSdkUrl == null || webSdkUrl.isEmpty) {
      return const KycLaunchResult.skipped();
    }

    // GoRouter push — returns when the WebView screen is popped.
    // KycWebViewScreen.onComplete pops with result = true; manual close pops
    // with null/false.
    final result = await appRouter.push<bool>('/kyc/webview', extra: webSdkUrl);
    return KycLaunchResult(success: result ?? false);
  }
}

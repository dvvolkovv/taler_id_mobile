// lib/core/platform/kyc_launcher_desktop.dart
import '../router/app_router.dart';
import 'kyc_launcher.dart';

/// [KycLauncherPlatform] implementation that pushes [KycWebViewScreen] at
/// route `/kyc/webview`. Works on all native platforms (iOS, Android, macOS,
/// Linux, Windows) — the mock_ss service does not support native SumSub
/// mobile SDKs, so WebView is the canonical flow everywhere.
class KycLauncherDesktop implements KycLauncherPlatform {
  @override
  Future<KycLaunchResult> launch({required String webSdkUrl}) async {
    if (webSdkUrl.isEmpty) {
      return const KycLaunchResult.skipped();
    }

    // GoRouter push returns true when the WebView screen pops with success
    // (KycWebViewScreen.onComplete), null/false on manual close.
    final result = await appRouter.push<bool>('/kyc/webview', extra: webSdkUrl);
    return KycLaunchResult(success: result ?? false);
  }
}

import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import '../../features/mail/domain/repositories/i_mail_repository.dart';
import '../../features/oauth/data/oauth_pending_request.dart';
import '../di/service_locator.dart';
import '../platform/platform_utils.dart';
import '../storage/secure_storage_service.dart';
import '../utils/constants.dart';

/// Call this after a successful login/biometric/PIN entry. If the user opened
/// the app via a Universal Link to /oauth/authorize before logging in,
/// resume the OAuth consent flow. Otherwise navigate to onboarding (first
/// login on this device) or straight to the assistant.
Future<void> postLoginNavigate(BuildContext context) async {
  final pendingOAuth = await sl<OAuthPendingRequest>().consume();
  if (pendingOAuth != null) {
    if (!context.mounted) return;
    final query = pendingOAuth.query.isEmpty ? '' : '?${pendingOAuth.query}';
    context.go('${RouteConstants.oauthAuthorize}$query');
    return;
  }

  final storage = sl<SecureStorageService>();
  final seen = await storage.isOnboardingSeen;
  if (!context.mounted) return;
  final defaultRoute = PlatformUtils.instance.isDesktop
      ? RouteConstants.messenger
      : RouteConstants.assistant;

  if (!seen) {
    context.go(RouteConstants.onboarding);
    return;
  }

  // Mail address gate: show once after onboarding until user creates a
  // mailbox or explicitly taps "Later".
  final dismissed = await storage.isMailSetupDismissed;
  final confirmed = await storage.isMailSetupConfirmed;
  if (!dismissed && !confirmed) {
    bool hasMailbox = false;
    try {
      await sl<IMailRepository>().getAccount();
      hasMailbox = true;
      // Cache positive result so we skip this network call on future logins.
      await storage.setMailSetupConfirmed();
    } catch (_) {
      hasMailbox = false; // 404 or network — show setup screen with "Later"
    }
    if (!context.mounted) return;
    if (!hasMailbox) {
      context.go(RouteConstants.mailAddressSetup);
      return;
    }
  }

  if (!context.mounted) return;
  context.go(defaultRoute);
}

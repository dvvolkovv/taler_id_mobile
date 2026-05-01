import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import '../../features/oauth/data/oauth_pending_request.dart';
import '../di/service_locator.dart';
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
  context.go(seen ? RouteConstants.assistant : RouteConstants.onboarding);
}

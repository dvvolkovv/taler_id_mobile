import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import '../di/service_locator.dart';
import '../storage/secure_storage_service.dart';
import '../utils/constants.dart';

/// Call this after a successful login/biometric/PIN entry. Navigates to the
/// onboarding screen if the user hasn't seen it yet (first login on this
/// device/account), otherwise goes straight to the assistant.
Future<void> postLoginNavigate(BuildContext context) async {
  final storage = sl<SecureStorageService>();
  final seen = await storage.isOnboardingSeen;
  if (!context.mounted) return;
  context.go(seen ? RouteConstants.assistant : RouteConstants.onboarding);
}

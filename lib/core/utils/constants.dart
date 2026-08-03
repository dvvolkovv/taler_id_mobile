import '../config/app_config.dart';

class ApiConstants {
  static const baseUrl = AppConfig.baseUrl;
  static const accessTokenKey = 'access_token';
  static const refreshTokenKey = 'refresh_token';
  static const biometricEnabledKey = 'biometric_enabled';
  static const userIdKey = 'user_id';
  static const pinHashKey = 'pin_hash';
  static const pinEnabledKey = 'pin_enabled';
  // Survives app restarts — an in-memory counter is reset by killing the app.
  static const pinAttemptsKey = 'pin_failed_attempts';
  static const languageKey = 'app_language';
  static const themeKey = 'app_theme';
  static const wallpaperKey = 'app_wallpaper';
  static const onboardingSeenKey = 'onboarding_seen';
}

class RouteConstants {
  static const splash = '/splash';
  static const login = '/auth/login';
  static const register = '/auth/register';
  static const twoFA = '/auth/2fa';
  static const dashboard = '/dashboard';
  static const profile = '/dashboard/profile';
  static const editProfile = '/dashboard/profile/edit';

  static const kyc = '/dashboard/kyc';
  static const kycSumsub = '/dashboard/kyc/sumsub';
  static const organization = '/dashboard/organization';
  static const organizationDetail = '/dashboard/organization/:id';
  static const organizationMembers = '/dashboard/organization/:id/members';
  static const sessions = '/dashboard/sessions';
  static const settings = '/dashboard/settings';
  static const wallpaper = '/dashboard/settings/wallpaper';
  static const invite = '/invite';
  // In-app route only. The incoming link is /oauth/auth (the OIDC authorization
  // endpoint); DeepLinkHandler maps one to the other.
  static const oauthAuthorize = '/oauth/authorize';
  static const pinSetup = '/auth/pin-setup';
  static const pinEntry = '/auth/pin-entry';
  static const assistant = '/dashboard/assistant';
  static const messenger = '/dashboard/messenger';
  static const messengerSearch = '/dashboard/messenger/search';
  static const voice = '/dashboard/voice';
  static const callHistory = '/dashboard/call-history';
  static const contacts = '/dashboard/contacts';
  static const notes = '/dashboard/notes';
  static const calendar = '/dashboard/calendar';
  static const onboarding = '/onboarding';
  static const forgotPassword = '/auth/forgot-password';
  static const verifyEmail = '/dashboard/profile/verify-email';
  static const translator = '/dashboard/translator';
  static const profileSections = '/dashboard/profile/sections';
  static const aiTwin = '/dashboard/profile/ai-twin';

  // Agent Shell (Phase 0)
  static const agentShell = '/agent-shell';

  // Group voice rooms (Phase 1)
  static const newGroupCall = '/new-group-call';
  static const groupCallLobby = '/group-call/:id/lobby';
  static const groupCallActive = '/group-call/:id';

  // Mail (Phase 2)
  static const String mail = '/mail';
  // NB: NOT '/mail/setup' — тот путь перехватывался бы route'ом '/mail/:uid'
  // (uid="setup" → int.parse crash → серый экран в release).
  static const String mailAddressSetup = '/mail-setup';
}

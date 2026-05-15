/// Desktop density tokens — Slack/Telegram-tight.
/// Constants only in Phase 2A; applied selectively in Phase 2B/2C.
class DesktopDensity {
  DesktopDensity._();

  // Activity bar
  static const double activityBarWidth = 64.0;
  static const double activityBarIconSize = 28.0;
  static const double activityBarPadding = 18.0;

  // Title bar
  static const double titleBarHeightMacOS = 38.0;
  static const double titleBarHeightWinLinux = 44.0;

  // Chat list (used in Phase 2B)
  static const double chatListRowHeight = 56.0;
  static const double chatListAvatarSize = 36.0;
  static const double chatListWidth = 320.0;
  static const double chatListMaxWidth = 400.0;

  // Right info panel (used in Phase 2B)
  static const double infoPanelWidth = 280.0;

  // Voice call mini-bar (used in Phase 2C)
  static const double miniBarHeight = 44.0;
}

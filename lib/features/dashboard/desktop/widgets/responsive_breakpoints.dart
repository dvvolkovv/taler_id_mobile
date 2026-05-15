enum DesktopLayout {
  /// < 800px — minimum size enforced, but if window somehow ends up here, render warning
  notSupported,
  /// 800–1100px — chat list as drawer / overlay; main pane only
  singlePane,
  /// 1100–1300px — chat list + main pane; right info panel as overlay/toggle
  twoPane,
  /// ≥ 1300px — chat list + main pane + right info panel
  threePane,
}

class ResponsiveBreakpoints {
  static const double minWidth = 800.0;
  static const double showFullChatList = 1100.0;
  static const double showInfoPanel = 1300.0;

  ResponsiveBreakpoints._();

  static DesktopLayout layoutFor(double windowWidth) {
    if (windowWidth < minWidth) return DesktopLayout.notSupported;
    if (windowWidth < showFullChatList) return DesktopLayout.singlePane;
    if (windowWidth < showInfoPanel) return DesktopLayout.twoPane;
    return DesktopLayout.threePane;
  }
}

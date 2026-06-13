import 'package:flutter/foundation.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';
import 'package:taler_id_mobile/core/platform/platform_utils.dart';

class DesktopTrayService with TrayListener {
  static final DesktopTrayService instance = DesktopTrayService._();
  DesktopTrayService._();

  final ValueNotifier<int> unreadCount = ValueNotifier(0);

  /// True only when the tray FULLY initialized (icon + context menu + listener).
  /// When false (e.g. Linux without a working tray host / appindicator), the
  /// window close button must quit the app instead of hiding to a dead tray.
  static bool available = false;

  Future<void> initialize() async {
    if (!PlatformUtils.instance.isDesktop) return;
    // The system tray is OPTIONAL. On Linux without a tray host / D-Bus /
    // libayatana-appindicator (or if the tray_manager platform plugin is not
    // registered) these calls throw MissingPluginException — which previously
    // propagated out of main() before runApp(), producing a black window.
    // Swallow and continue so the app always starts.
    try {
      await trayManager.setIcon('assets/tray/tray_idle.png');
      await trayManager.setToolTip('Taler ID');
      await _rebuildMenu();
      trayManager.addListener(this);
      unreadCount.addListener(_onUnreadChanged);
      available = true;
    } catch (e) {
      debugPrint('[DesktopTray] tray unavailable — removing icon: $e');
      try {
        await trayManager.destroy();
      } catch (_) {/* best effort: remove any half-created dead tray icon */}
    }
  }

  void _onUnreadChanged() {
    final n = unreadCount.value;
    trayManager.setIcon(
        n > 0 ? 'assets/tray/tray_unread.png' : 'assets/tray/tray_idle.png');
    trayManager.setToolTip(n > 0 ? 'Taler ID — $n непрочитанных' : 'Taler ID');
  }

  Future<void> _rebuildMenu() async {
    final menu = Menu(items: [
      MenuItem(key: 'open', label: 'Открыть Taler ID'),
      MenuItem.separator(),
      MenuItem(key: 'quit', label: 'Выйти'),
    ]);
    await trayManager.setContextMenu(menu);
  }

  @override
  void onTrayIconMouseDown() async {
    await windowManager.show();
    await windowManager.focus();
  }

  @override
  void onTrayMenuItemClick(MenuItem item) async {
    switch (item.key) {
      case 'open':
        await windowManager.show();
        await windowManager.focus();
        break;
      case 'quit':
        await windowManager.destroy();
        break;
    }
  }
}

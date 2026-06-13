import 'dart:async';
import 'dart:ui';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/widgets.dart';
import 'package:flutter_acrylic/flutter_acrylic.dart' as acrylic;
import 'package:window_manager/window_manager.dart';
import 'package:taler_id_mobile/core/platform/platform_utils.dart';
import 'package:taler_id_mobile/core/desktop_tray/desktop_tray_service.dart';
import 'window_state_persistence.dart';

class WindowSetup with WindowListener {
  static const Size defaultSize = Size(1280, 800);
  static const Size minimumSize = Size(800, 600);

  static final WindowSetup _instance = WindowSetup._();
  static WindowStatePersistence? _persistence;
  static Timer? _saveDebounce;

  WindowSetup._();

  static Future<void> initialize() async {
    if (!PlatformUtils.instance.isDesktop) return;
    WidgetsFlutterBinding.ensureInitialized();
    await windowManager.ensureInitialized();

    // Windows: Mica backdrop (через flutter_acrylic)
    if (PlatformUtils.instance.isWindows) {
      try {
        // Lazy import чтобы не падало на macOS если пакет не подгрузился
        // ignore: avoid_dynamic_calls
        final ok = await _initWindowsAcrylic();
        if (ok) {
          debugPrint('[WindowSetup] Windows Mica backdrop applied');
        }
      } catch (e) {
        debugPrint('[WindowSetup] Mica init failed (downgrade to opaque): $e');
      }
    }

    // Linux: frameless через window_manager
    if (PlatformUtils.instance.isLinux) {
      // titleBarStyle уже hidden, frameless даёт borderless окно
      // ВНИМАНИЕ: на Linux WM поддержка фрэймлесса варьируется (GNOME/KDE/sway).
      // Если что-то странно — закомментировать.
    }

    final persistence = WindowStatePersistence();
    await persistence.initialize();
    final saved = await persistence.load();
    _persistence = persistence;

    final initialSize = saved == null
        ? defaultSize
        : Size(
            saved.width.clamp(minimumSize.width, double.infinity),
            saved.height.clamp(minimumSize.height, double.infinity),
          );

    final options = WindowOptions(
      size: initialSize,
      minimumSize: minimumSize,
      center: saved == null,
      titleBarStyle: TitleBarStyle.hidden,
      title: 'Taler ID',
    );
    await windowManager.waitUntilReadyToShow(options, () async {
      await windowManager.show();
      await windowManager.focus();
      await windowManager.setPreventClose(true);
      if (saved != null) {
        await windowManager.setPosition(Offset(saved.x, saved.y));
        // Off-screen guard: if window ends up outside reasonable bounds,
        // re-center.
        final bounds = await windowManager.getBounds();
        if (bounds.left < -100 || bounds.top < -100) {
          await windowManager.center();
        }
        if (saved.isMaximized) await windowManager.maximize();
      }
    });
  }

  static Future<bool> _initWindowsAcrylic() async {
    await acrylic.Window.initialize();
    await acrylic.Window.setEffect(
      effect: acrylic.WindowEffect.mica,
      dark: true,
    );
    return true;
  }

  /// Call after [initialize] to register a debounced save listener.
  /// Splitting initialize and listener attachment lets tests skip the listener.
  static void attachStateSaver() {
    if (!PlatformUtils.instance.isDesktop) return;
    windowManager.addListener(_instance);
  }

  Future<void> _saveCurrent() async {
    if (_persistence == null) return;
    final bounds = await windowManager.getBounds();
    final isMax = await windowManager.isMaximized();
    await _persistence!.save(
      width: bounds.width,
      height: bounds.height,
      x: bounds.left,
      y: bounds.top,
      isMaximized: isMax,
    );
  }

  void _scheduleSave() {
    _saveDebounce?.cancel();
    _saveDebounce = Timer(const Duration(milliseconds: 500), _saveCurrent);
  }

  @override
  void onWindowResized() => _scheduleSave();
  @override
  void onWindowMoved() => _scheduleSave();
  @override
  void onWindowMaximize() => _scheduleSave();
  @override
  void onWindowUnmaximize() => _scheduleSave();

  @override
  void onWindowClose() async {
    // Intercept close and hide instead. Quit happens via tray "Выйти" menu
    // (see DesktopTrayService) or programmatic windowManager.destroy().
    final isPreventClose = await windowManager.isPreventClose();
    // Minimize-to-tray ONLY when the tray fully initialized; otherwise quit so
    // the user is never trapped (hidden window + dead/blank tray menu).
    if (isPreventClose && DesktopTrayService.available) {
      await windowManager.hide();
    } else {
      await windowManager.destroy();
    }
  }
}

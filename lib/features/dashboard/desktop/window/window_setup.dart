import 'dart:async';
import 'dart:ui';
import 'package:flutter/widgets.dart';
import 'package:window_manager/window_manager.dart';
import 'package:taler_id_mobile/core/platform/platform_utils.dart';
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
}

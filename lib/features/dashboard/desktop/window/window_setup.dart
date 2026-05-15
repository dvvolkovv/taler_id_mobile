import 'package:flutter/widgets.dart';
import 'package:window_manager/window_manager.dart';
import 'package:taler_id_mobile/core/platform/platform_utils.dart';

/// One-shot desktop window initialization. Must be awaited from `main()`
/// BEFORE `runApp()`. No-op on mobile.
class WindowSetup {
  static const Size defaultSize = Size(1280, 800);
  static const Size minimumSize = Size(800, 600);

  WindowSetup._();

  static Future<void> initialize() async {
    if (!PlatformUtils.instance.isDesktop) return;
    WidgetsFlutterBinding.ensureInitialized();
    await windowManager.ensureInitialized();

    const options = WindowOptions(
      size: defaultSize,
      minimumSize: minimumSize,
      center: true,
      backgroundColor: null,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.hidden,
      title: 'Taler ID',
    );
    await windowManager.waitUntilReadyToShow(options, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }
}

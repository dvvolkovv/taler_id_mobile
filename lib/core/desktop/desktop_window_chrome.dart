// lib/core/desktop/desktop_window_chrome.dart
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import '../platform/platform_utils.dart';
import 'desktop_breakpoints.dart';

/// 36px high drag-region вверху окна.
/// macOS: рендерит только drag-зону + опциональный title (traffic lights рисует ОС).
/// Windows/Linux: рендерит drag-зону + custom close/min/max справа.
class DesktopWindowChrome extends StatelessWidget {
  const DesktopWindowChrome({super.key, this.title, this.trailing});

  final String? title;
  final List<Widget>? trailing;

  @override
  Widget build(BuildContext context) {
    if (!PlatformUtils.instance.isDesktop) return const SizedBox.shrink();

    final platform = PlatformUtils.instance;
    final leftPadding = platform.isMacOS ? 80.0 : 12.0;

    return GestureDetector(
      onPanStart: (_) => windowManager.startDragging(),
      onDoubleTap: () async {
        final isMax = await windowManager.isMaximized();
        if (isMax) {
          await windowManager.unmaximize();
        } else {
          await windowManager.maximize();
        }
      },
      child: Container(
        height: kDesktopChromeHeight,
        color: Colors.transparent,
        padding: EdgeInsets.only(left: leftPadding, right: 8),
        child: Row(
          children: [
            if (title != null)
              Text(
                title!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  fontSize: 12,
                ),
              ),
            const Spacer(),
            if (trailing != null) ...trailing!,
            if (platform.isWindows || platform.isLinux)
              const _CustomWindowButtons(),
          ],
        ),
      ),
    );
  }
}

class _CustomWindowButtons extends StatelessWidget {
  const _CustomWindowButtons();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _btn(Icons.remove, () => windowManager.minimize()),
        _btn(Icons.crop_square, () async {
          final isMax = await windowManager.isMaximized();
          isMax ? windowManager.unmaximize() : windowManager.maximize();
        }),
        _btn(Icons.close, () => windowManager.close(), hoverColor: Colors.red),
      ],
    );
  }

  Widget _btn(IconData icon, VoidCallback onTap, {Color? hoverColor}) {
    return _WindowButton(icon: icon, onTap: onTap, hoverColor: hoverColor);
  }
}

class _WindowButton extends StatefulWidget {
  const _WindowButton({required this.icon, required this.onTap, this.hoverColor});
  final IconData icon;
  final VoidCallback onTap;
  final Color? hoverColor;

  @override
  State<_WindowButton> createState() => _WindowButtonState();
}

class _WindowButtonState extends State<_WindowButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          width: 36,
          height: kDesktopChromeHeight,
          color: _hover ? (widget.hoverColor ?? Colors.white24) : Colors.transparent,
          child: Icon(widget.icon, size: 14, color: Colors.white70),
        ),
      ),
    );
  }
}

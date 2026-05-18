import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

/// Custom min/max/close buttons for Windows + Linux. Not used on macOS
/// (native traffic-lights remain at the top-left corner).
class WindowControls extends StatelessWidget {
  const WindowControls({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ControlButton(
          icon: Icons.remove,
          onTap: () => windowManager.minimize(),
        ),
        _ControlButton(
          icon: Icons.crop_square,
          onTap: () async {
            if (await windowManager.isMaximized()) {
              await windowManager.unmaximize();
            } else {
              await windowManager.maximize();
            }
          },
        ),
        _ControlButton(
          icon: Icons.close,
          onTap: () => windowManager.close(),
          isDestructive: true,
        ),
      ],
    );
  }
}

class _ControlButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isDestructive;
  const _ControlButton({
    required this.icon,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  State<_ControlButton> createState() => _ControlButtonState();
}

class _ControlButtonState extends State<_ControlButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          width: 46,
          height: 38,
          color: _hover
              ? (widget.isDestructive
                  ? Colors.red
                  : theme.colorScheme.surfaceContainerHigh)
              : Colors.transparent,
          alignment: Alignment.center,
          child: Icon(
            widget.icon,
            size: 14,
            color: _hover && widget.isDestructive
                ? Colors.white
                : theme.colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}

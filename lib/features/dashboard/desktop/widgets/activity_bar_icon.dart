import 'package:flutter/material.dart';
import 'package:taler_id_mobile/features/dashboard/desktop/theme/desktop_density.dart';

class ActivityBarIcon extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final bool isActive;
  final int? badgeCount;
  final VoidCallback onTap;
  const ActivityBarIcon({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.isActive,
    this.badgeCount,
    required this.onTap,
  });

  @override
  State<ActivityBarIcon> createState() => _ActivityBarIconState();
}

class _ActivityBarIconState extends State<ActivityBarIcon> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Tooltip(
      message: widget.tooltip,
      waitDuration: const Duration(milliseconds: 500),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: widget.onTap,
          child: SizedBox(
            width: DesktopDensity.activityBarWidth,
            height: DesktopDensity.activityBarWidth,
            child: Stack(
              children: [
                if (widget.isActive)
                  Positioned(
                    left: 0, top: 12, bottom: 12,
                    child: Container(
                      width: 3,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        borderRadius: const BorderRadius.only(
                          topRight: Radius.circular(2),
                          bottomRight: Radius.circular(2),
                        ),
                      ),
                    ),
                  ),
                Center(
                  child: Container(
                    decoration: BoxDecoration(
                      color: _hover && !widget.isActive
                          ? theme.colorScheme.surfaceContainerHigh
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.all(8),
                    child: Icon(
                      widget.icon,
                      size: DesktopDensity.activityBarIconSize,
                      color: widget.isActive
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                if ((widget.badgeCount ?? 0) > 0)
                  Positioned(
                    right: 8, top: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.error,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                      child: Text(
                        widget.badgeCount! > 99 ? '99+' : '${widget.badgeCount}',
                        style: TextStyle(
                          color: theme.colorScheme.onError,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

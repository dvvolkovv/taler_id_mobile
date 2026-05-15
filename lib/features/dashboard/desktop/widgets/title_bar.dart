import 'dart:io';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'package:taler_id_mobile/features/dashboard/desktop/theme/desktop_density.dart';
import 'window_controls.dart';

class TitleBar extends StatelessWidget {
  final String sectionName;
  const TitleBar({super.key, required this.sectionName});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMacOS = Platform.isMacOS;

    return Container(
      height: isMacOS
          ? DesktopDensity.titleBarHeightMacOS
          : DesktopDensity.titleBarHeightWinLinux,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(bottom: BorderSide(color: theme.dividerColor, width: 1)),
      ),
      child: Row(
        children: [
          // Left padding: 80px on macOS to clear traffic-lights, 12px elsewhere
          SizedBox(width: isMacOS ? 80 : 12),
          // Drag region with section name centered
          Expanded(
            child: DragToMoveArea(
              child: Container(
                alignment: Alignment.center,
                child: Text(
                  sectionName,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
          // Right side: native on macOS (nothing here), custom controls on Win/Linux
          if (!isMacOS) const WindowControls() else const SizedBox(width: 80),
        ],
      ),
    );
  }
}

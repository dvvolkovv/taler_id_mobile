import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:taler_id_mobile/core/utils/constants.dart';
import 'package:taler_id_mobile/features/dashboard/desktop/theme/desktop_density.dart';
import 'package:taler_id_mobile/features/dashboard/desktop/widgets/activity_bar_icon.dart';

class ActivityBar extends StatelessWidget {
  final String currentRoute;
  const ActivityBar({super.key, required this.currentRoute});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = <_ActivityBarItem>[
      _ActivityBarItem(icon: Icons.chat_bubble_outline, route: RouteConstants.messenger, tooltip: 'Messenger'),
      _ActivityBarItem(icon: Icons.call_outlined, route: RouteConstants.callHistory, tooltip: 'Calls'),
      _ActivityBarItem(icon: Icons.smart_toy_outlined, route: RouteConstants.assistant, tooltip: 'Assistant'),
      _ActivityBarItem(icon: Icons.calendar_today_outlined, route: RouteConstants.calendar, tooltip: 'Calendar'),
      _ActivityBarItem(icon: Icons.settings_outlined, route: RouteConstants.settings, tooltip: 'Settings'),
    ];

    return Container(
      width: DesktopDensity.activityBarWidth,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(right: BorderSide(color: theme.dividerColor, width: 1)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          for (final item in items)
            ActivityBarIcon(
              icon: item.icon,
              tooltip: item.tooltip,
              isActive: currentRoute.startsWith(item.route),
              onTap: () => context.go(item.route),
            ),
        ],
      ),
    );
  }
}

class _ActivityBarItem {
  final IconData icon;
  final String route;
  final String tooltip;
  const _ActivityBarItem({required this.icon, required this.route, required this.tooltip});
}

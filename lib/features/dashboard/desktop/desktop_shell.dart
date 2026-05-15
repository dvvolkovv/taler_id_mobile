import 'package:flutter/material.dart';
import 'package:taler_id_mobile/core/keyboard_shortcuts/shortcut_dispatcher.dart';
import 'package:taler_id_mobile/core/utils/constants.dart';
import 'widgets/activity_bar.dart';
import 'widgets/title_bar.dart';

class DesktopShell extends StatelessWidget {
  final String currentRoute;
  final Widget child;
  const DesktopShell({
    super.key,
    required this.currentRoute,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return ShortcutDispatcher(
      child: Scaffold(
        body: Column(
          children: [
            TitleBar(sectionName: _sectionNameFor(currentRoute)),
            Expanded(
              child: Row(
                children: [
                  ActivityBar(currentRoute: currentRoute),
                  Expanded(child: child),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _sectionNameFor(String route) {
    if (route.startsWith(RouteConstants.messenger)) return 'Messenger';
    if (route.startsWith(RouteConstants.callHistory)) return 'Calls';
    if (route.startsWith(RouteConstants.assistant)) return 'Assistant';
    if (route.startsWith(RouteConstants.calendar)) return 'Calendar';
    if (route.startsWith(RouteConstants.settings)) return 'Settings';
    return 'Taler ID';
  }
}

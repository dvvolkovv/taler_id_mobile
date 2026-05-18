import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taler_id_mobile/core/di/service_locator.dart';
import 'package:taler_id_mobile/core/keyboard_shortcuts/shortcut_dispatcher.dart';
import 'package:taler_id_mobile/core/storage/secure_storage_service.dart';
import 'package:taler_id_mobile/core/utils/constants.dart';
import 'package:taler_id_mobile/features/messenger/data/datasources/messenger_remote_datasource.dart';
import 'package:taler_id_mobile/features/messenger/presentation/bloc/messenger_bloc.dart';
import 'package:taler_id_mobile/features/messenger/presentation/bloc/messenger_event.dart';
import 'widgets/activity_bar.dart';
import 'widgets/title_bar.dart';

class DesktopShell extends StatefulWidget {
  final String currentRoute;
  final Widget child;
  const DesktopShell({
    super.key,
    required this.currentRoute,
    required this.child,
  });

  @override
  State<DesktopShell> createState() => _DesktopShellState();
}

class _DesktopShellState extends State<DesktopShell> {
  @override
  void initState() {
    super.initState();
    // Mirror the mobile DashboardScreen init: connect MessengerBloc socket
    // and load badge counts so the messenger chat list populates after login.
    // Without this, the bloc stays disconnected and the chat list is empty
    // until some other code path (e.g., navigating to Contacts) wakes it up.
    WidgetsBinding.instance.addPostFrameCallback((_) => _initMessenger());
  }

  Future<void> _initMessenger() async {
    if (!mounted) return;
    try {
      final storage = sl<SecureStorageService>();
      final token = await storage.getAccessToken();
      final userId = await storage.getUserId();
      if (!mounted || token == null) return;
      final bloc = context.read<MessengerBloc>();
      // Avoid double-connect after hot-reload.
      if (bloc.state.isConnected && bloc.state.currentUserId == userId) {
        bloc.add(LoadBadgeCounts());
        return;
      }
      // If the underlying socket is already connected (e.g., reconnected by
      // a previous DashboardScreen instance), skip the explicit connect.
      if (sl<MessengerRemoteDataSource>().isSocketConnected) {
        bloc.add(LoadBadgeCounts());
        return;
      }
      bloc.add(ConnectMessenger(token, userId: userId));
      bloc.add(LoadBadgeCounts());
    } catch (_) {
      // Swallow — auth flow handles missing tokens elsewhere.
    }
  }

  @override
  Widget build(BuildContext context) {
    return ShortcutDispatcher(
      child: Scaffold(
        body: Column(
          children: [
            TitleBar(sectionName: _sectionNameFor(widget.currentRoute)),
            Expanded(
              child: Row(
                children: [
                  ActivityBar(currentRoute: widget.currentRoute),
                  Expanded(child: widget.child),
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

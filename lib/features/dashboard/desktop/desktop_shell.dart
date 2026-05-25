import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:taler_id_mobile/core/di/service_locator.dart';
import 'package:taler_id_mobile/core/keyboard_shortcuts/shortcut_dispatcher.dart';
import 'package:taler_id_mobile/core/storage/secure_storage_service.dart';
import 'package:taler_id_mobile/core/theme/app_theme.dart';
import 'package:taler_id_mobile/core/utils/constants.dart';
import 'package:taler_id_mobile/features/messenger/data/datasources/messenger_remote_datasource.dart';
import 'package:taler_id_mobile/features/messenger/presentation/bloc/messenger_bloc.dart';
import 'package:taler_id_mobile/features/messenger/presentation/bloc/messenger_event.dart';
import 'package:taler_id_mobile/features/messenger/presentation/bloc/messenger_state.dart';
import 'package:taler_id_mobile/l10n/app_localizations.dart';
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
  String? _showingCallDialogRoom;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _connectMessenger());
  }

  Future<void> _connectMessenger() async {
    if (!mounted) return;
    final bloc = context.read<MessengerBloc>();
    try {
      final storage = sl<SecureStorageService>();
      final token = await storage.getAccessToken();
      final userId = await storage.getUserId();
      if (bloc.state.isConnected &&
          userId != null &&
          bloc.state.currentUserId == userId) {
        return;
      }
      if (token != null && mounted) {
        bloc.add(ConnectMessenger(token, userId: userId));
      }
    } catch (_) {}
  }

  void _showIncomingCallDialog(
    BuildContext context,
    Map<String, dynamic> data,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final fromName = data['fromUserName'] as String? ?? l10n.dashboardUser;
    final fromAvatar = data['fromUserAvatar'] as String?;
    final roomName = data['roomName'] as String? ?? '';
    final convId = data['conversationId'] as String? ?? '';
    final e2eeKey = data['e2eeKey'] as String?;

    if (_showingCallDialogRoom == roomName) {
      context.read<MessengerBloc>().add(DismissCallInvite());
      return;
    }
    _showingCallDialogRoom = roomName;

    final colors = AppColors.of(context);
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      useRootNavigator: true,
      backgroundColor: colors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.call_rounded, size: 48, color: colors.primary),
              const SizedBox(height: 12),
              Text(
                l10n.dashboardIncomingCall,
                style: TextStyle(color: colors.textSecondary, fontSize: 14),
              ),
              const SizedBox(height: 4),
              Text(
                fromName,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context, rootNavigator: true).pop();
                      if (convId.isNotEmpty && roomName.isNotEmpty) {
                        try {
                          sl<MessengerRemoteDataSource>()
                              .sendCallEnded(convId, roomName);
                        } catch (_) {}
                      }
                    },
                    child: Column(
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: colors.error,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.call_end_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.dashboardDecline,
                          style: TextStyle(
                            color: colors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context, rootNavigator: true).pop();
                      final e2eeParam = e2eeKey != null
                          ? '&e2ee=${Uri.encodeComponent(e2eeKey)}'
                          : '';
                      final calleeParam = fromName.isNotEmpty
                          ? '&callee=${Uri.encodeComponent(fromName)}'
                          : '';
                      final avatarParam =
                          fromAvatar != null && fromAvatar.isNotEmpty
                              ? '&calleeAvatar=${Uri.encodeComponent(fromAvatar)}'
                              : '';
                      final uri = '${RouteConstants.voice}?room=$roomName'
                          '${convId.isNotEmpty ? '&convId=$convId' : ''}'
                          '&incoming=1$e2eeParam$calleeParam$avatarParam';
                      context.push(uri);
                    },
                    child: Column(
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: const BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.call_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.dashboardAccept,
                          style: TextStyle(
                            color: colors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    ).whenComplete(() {
      if (_showingCallDialogRoom == roomName) _showingCallDialogRoom = null;
    });

    if (mounted) {
      context.read<MessengerBloc>().add(DismissCallInvite());
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<MessengerBloc, MessengerState>(
      listenWhen: (prev, curr) =>
          curr.pendingCallInvite != null &&
          prev.pendingCallInvite != curr.pendingCallInvite,
      listener: (context, state) {
        if (state.pendingCallInvite != null) {
          _showIncomingCallDialog(context, state.pendingCallInvite!);
        }
      },
      child: ShortcutDispatcher(
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

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/di/service_locator.dart';
import '../../domain/entities/group_call.dart';
import '../../domain/repositories/group_call_repository.dart';

/// Banner shown on the Calls tab when the current user has at least one
/// active group call (LOBBY/ACTIVE) where their invite is in
/// CALLING/JOINED/LEFT/DECLINED. Tap → navigate to the call.
///
/// Polls the API on initState and on app foreground (via
/// `WidgetsBindingObserver.didChangeAppLifecycleState`). Self-clears when
/// no active calls remain.
class ActiveGroupCallBanner extends StatefulWidget {
  const ActiveGroupCallBanner({super.key});

  @override
  State<ActiveGroupCallBanner> createState() => _ActiveGroupCallBannerState();
}

class _ActiveGroupCallBannerState extends State<ActiveGroupCallBanner>
    with WidgetsBindingObserver {
  List<GroupCall> _calls = const [];
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh();
    // Light polling — refresh every 30s while the screen is visible.
    // Socket.io events would be more elegant but require BLoC integration
    // here, which isn't worth the complexity for a banner.
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) => _refresh());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refresh();
    }
  }

  Future<void> _refresh() async {
    try {
      final calls = await sl<GroupCallRepository>().getActiveCallsForMe();
      if (!mounted) return;
      setState(() => _calls = calls);
    } catch (_) {
      // Network/API failure → leave banner state unchanged.
      // The next periodic tick or app resume will retry.
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_calls.isEmpty) return const SizedBox.shrink();
    final c = _calls.first;
    final theme = Theme.of(context);

    final inviteCount = c.invites.length;
    final summary = inviteCount > 0
        ? 'Группа: ${c.hostDisplayName} + $inviteCount'
        : 'Группа: ${c.hostDisplayName}';

    return Material(
      color: theme.colorScheme.primary,
      child: InkWell(
        onTap: () => context.go('/group-call/${c.id}'),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              const Icon(Icons.group, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Активный звонок',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                    Text(
                      summary,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}

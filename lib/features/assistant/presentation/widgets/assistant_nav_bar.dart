import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:taler_id_mobile/l10n/app_localizations.dart';

import '../../../../core/utils/constants.dart';
import '../../../messenger/presentation/bloc/messenger_bloc.dart';
import '../../../messenger/presentation/bloc/messenger_event.dart';
import '../../../messenger/presentation/bloc/messenger_state.dart';

/// Compact horizontal section navigation for the assistant chat home.
///
/// Port of the "orbital" nav circles from the voice session screen
/// (assistant_screen.dart): same 7 sections, same badge sources from
/// [MessengerBloc], same navigation behavior (`context.push(route)` after an
/// optional badge-reset callback) — rendered as a single scrollable row of
/// small tinted circles with tooltips instead of orbiting labeled circles.
class AssistantNavBar extends StatelessWidget {
  const AssistantNavBar({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return BlocBuilder<MessengerBloc, MessengerState>(
      builder: (context, msState) {
        final unreadMessages =
            msState.conversations.fold<int>(0, (s, c) => s + c.unreadCount);
        final missedCalls = msState.missedCallsCount;
        final pendingCalendar = msState.pendingCalendarInvites;
        final pendingContacts = msState.pendingContactRequests;

        final items = [
          _NavItem(
            icon: Icons.chat_bubble_outline_rounded,
            label: l10n.tabMessenger,
            route: RouteConstants.messenger,
            // Include incoming contact requests — they live inline in the
            // chats list, so the Messenger badge counts them too.
            badge: unreadMessages + pendingContacts,
            color: const Color(0xFF22D3EE), // cyan
          ),
          _NavItem(
            icon: Icons.call_outlined,
            label: l10n.tabCalls,
            route: RouteConstants.callHistory,
            badge: missedCalls,
            color: const Color(0xFF34D399), // emerald
            onTap: () => context
                .read<MessengerBloc>()
                .add(const UpdateBadgeCounts(missedCallsCount: 0)),
          ),
          _NavItem(
            icon: Icons.calendar_month_outlined,
            label: l10n.tabCalendar,
            route: RouteConstants.calendar,
            badge: pendingCalendar,
            color: const Color(0xFFA78BFA), // violet
            onTap: () => context
                .read<MessengerBloc>()
                .add(const UpdateBadgeCounts(pendingCalendarInvites: 0)),
          ),
          _NavItem(
            icon: Icons.sticky_note_2_outlined,
            label: l10n.notesTitle,
            route: RouteConstants.notes,
            badge: 0,
            color: const Color(0xFFFB7185), // rose
          ),
          _NavItem(
            icon: Icons.people_outline,
            label: l10n.contacts,
            route: RouteConstants.contacts,
            badge: pendingContacts,
            color: const Color(0xFF38BDF8), // sky
          ),
          _NavItem(
            icon: Icons.person_outline,
            label: l10n.tabProfile,
            route: RouteConstants.profile,
            badge: 0,
            color: const Color(0xFFFBBF24), // amber
          ),
          _NavItem(
            icon: Icons.settings_outlined,
            label: l10n.tabSettings,
            route: RouteConstants.settings,
            badge: 0,
            color: const Color(0xFF818CF8), // indigo-lavender
          ),
        ];

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              for (final item in items)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  child: _NavCircleButton(item: item),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _NavCircleButton extends StatelessWidget {
  const _NavCircleButton({required this.item});

  final _NavItem item;

  @override
  Widget build(BuildContext context) {
    final errorColor = Theme.of(context).colorScheme.error;
    return Tooltip(
      message: item.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          // Mirrors _NavCircle tap on the voice session screen:
          // haptic → optional badge reset → push route.
          HapticFeedback.selectionClick();
          item.onTap?.call();
          context.push(item.route);
        },
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: item.color.withValues(alpha: 0.15),
                border: Border.all(
                  color: item.color.withValues(alpha: 0.35),
                ),
              ),
              child: Icon(item.icon, size: 20, color: item.color),
            ),
            if (item.badge > 0)
              Positioned(
                top: -3,
                right: -3,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: errorColor,
                    border: Border.all(color: Colors.white, width: 1),
                  ),
                  constraints:
                      const BoxConstraints(minWidth: 16, minHeight: 16),
                  child: Text(
                    item.badge > 99 ? '99+' : '${item.badge}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  final String route;
  final int badge;
  final Color color;
  final VoidCallback? onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.route,
    required this.badge,
    required this.color,
    this.onTap,
  });
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/utils/constants.dart';
import '../../domain/assistant_action.dart';

/// Compact tappable chip rendered under an assistant message that links to
/// the entity the assistant acted on (event, message, call, contact, ...).
class AssistantActionBubble extends StatelessWidget {
  const AssistantActionBubble({
    super.key,
    required this.action,
    required this.onTap,
  });

  final AssistantAction action;
  final void Function(AssistantAction) onTap;

  static const _icons = {
    AssistantActionType.messageSent: Icons.chat_bubble_outline,
    AssistantActionType.eventCreated: Icons.event,
    AssistantActionType.analystReply: Icons.insights,
    AssistantActionType.callMade: Icons.call,
    AssistantActionType.contactAdded: Icons.person_add_alt,
    AssistantActionType.channelPost: Icons.campaign_outlined,
    AssistantActionType.webLink: Icons.link,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => onTap(action),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: theme.colorScheme.primary.withValues(alpha: 0.35),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_icons[action.type], size: 18, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                action.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right, size: 18, color: theme.colorScheme.primary),
          ],
        ),
      ),
    );
  }
}

/// Возвращает false, если сущность/маршрут недоступны (caller показывает snackbar).
Future<bool> navigateToAssistantAction(
    BuildContext context, AssistantAction a) async {
  switch (a.type) {
    case AssistantActionType.messageSent:
      final conv = a.conversationId;
      if (conv == null) return false;
      context.push('${RouteConstants.messenger}/$conv',
          extra: {'highlightMessageId': a.entityId});
      return true;
    case AssistantActionType.analystReply:
      context.push('${RouteConstants.messenger}/${a.entityId}');
      return true;
    case AssistantActionType.eventCreated:
      // CalendarScreen reads the target event id from the URI query
      // parameter `eventId` (same mechanism as notification deep-links).
      context.push(Uri(
        path: RouteConstants.calendar,
        queryParameters: {'eventId': a.entityId},
      ).toString());
      return true;
    case AssistantActionType.callMade:
      context.push(RouteConstants.callHistory);
      return true;
    case AssistantActionType.contactAdded:
      // Dedicated user-profile-by-id route.
      context.push('/dashboard/user/${a.entityId}');
      return true;
    case AssistantActionType.channelPost:
      context.push('${RouteConstants.messenger}/${a.entityId}');
      return true;
    case AssistantActionType.webLink:
      final uri = Uri.tryParse(a.entityId);
      if (uri == null || !(uri.isScheme('http') || uri.isScheme('https'))) {
        return false;
      }
      return launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

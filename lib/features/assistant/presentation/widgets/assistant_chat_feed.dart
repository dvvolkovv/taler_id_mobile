import 'package:flutter/material.dart';
import 'package:taler_id_mobile/l10n/app_localizations.dart';

import '../../../messenger/domain/entities/message_entity.dart';
import '../../domain/assistant_action.dart';
import '../bloc/assistant_chat_bloc.dart';
import 'assistant_chat_message_row.dart';

/// A live (not yet persisted) voice replica shown at the bottom of the feed
/// as a semi-transparent bubble. The voice session screen feeds these while
/// transcripts stream in; the text chat passes none.
class PendingReplica {
  const PendingReplica({required this.role, required this.text, this.itemId});

  /// 'user' | 'assistant'
  final String role;
  final String text;
  final String? itemId;
}

/// Presentation-only assistant chat feed: loading spinner, error+retry when
/// history never loaded, empty hint, and the reversed message list (typing
/// row + pending voice replicas + persisted messages). Takes plain values so
/// both the text chat screen (bloc-driven) and the voice session screen can
/// drive it.
class AssistantChatFeed extends StatelessWidget {
  const AssistantChatFeed({
    super.key,
    required this.messages,
    required this.status,
    this.error,
    this.pending = const [],
    required this.onActionTap,
    required this.onRetry,
  });

  /// Chronological (oldest first).
  final List<MessageEntity> messages;
  final AssistantChatStatus status;
  final String? error;

  /// Live voice replicas rendered after the newest message.
  final List<PendingReplica> pending;
  final Future<void> Function(AssistantAction action) onActionTap;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (status == AssistantChatStatus.initial ||
        status == AssistantChatStatus.loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (messages.isEmpty &&
        pending.isEmpty &&
        status == AssistantChatStatus.error) {
      // History never loaded — offer retry instead of a blank list.
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.assistantError, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: onRetry,
              child: const Icon(Icons.refresh),
            ),
          ],
        ),
      );
    }
    if (messages.isEmpty &&
        pending.isEmpty &&
        status == AssistantChatStatus.ready) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            l10n.assistantEmptyHint,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.6),
              fontSize: 15,
            ),
          ),
        ),
      );
    }
    final sending = status == AssistantChatStatus.sending;
    // Reversed list order (visual bottom first):
    // [typing?] + pending.reversed + messages.reversed.
    return ListView.builder(
      reverse: true,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: messages.length + pending.length + (sending ? 1 : 0),
      itemBuilder: (context, index) {
        if (sending && index == 0) {
          return _TypingRow(text: l10n.assistantTyping);
        }
        final i = index - (sending ? 1 : 0);
        if (i < pending.length) {
          return _PendingReplicaBubble(
            replica: pending[pending.length - 1 - i],
          );
        }
        final mi = i - pending.length;
        final message = messages[messages.length - 1 - mi];
        return AssistantChatMessageRow(
          message: message,
          onActionTap: onActionTap,
        );
      },
    );
  }
}

/// Semi-transparent bubble for a live voice replica: same alignment/colors
/// as persisted rows, no timestamp/actions.
class _PendingReplicaBubble extends StatelessWidget {
  const _PendingReplicaBubble({required this.replica});

  final PendingReplica replica;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isAssistant = replica.role == 'assistant';
    return Opacity(
      opacity: 0.55,
      child: Align(
        alignment: isAssistant ? Alignment.centerLeft : Alignment.centerRight,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.82,
          ),
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isAssistant
                ? scheme.surfaceContainerHighest
                : scheme.primaryContainer,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: Radius.circular(isAssistant ? 4 : 16),
              bottomRight: Radius.circular(isAssistant ? 16 : 4),
            ),
          ),
          child: Text(
            replica.text,
            style: TextStyle(
              color: isAssistant ? scheme.onSurface : scheme.onPrimaryContainer,
              fontSize: 15,
              height: 1.3,
            ),
          ),
        ),
      ),
    );
  }
}

class _TypingRow extends StatelessWidget {
  const _TypingRow({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: scheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              text,
              style: TextStyle(
                color: scheme.onSurface.withValues(alpha: 0.7),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/conversation_read_state.dart';
import '../../domain/entities/message_entity.dart';

/// Bottom-sheet shown on long-press of one's OWN message (Task 13): lists
/// which participants have read up to this message (per their read cursor,
/// Task 8/12) and who reacted with what emoji. Read-only — actual message
/// actions (reply/edit/forward/delete/react) stay in the existing
/// `_showMessageActions` menu in `chat_room_screen.dart`; this only adds an
/// "info" entry to it.
///
/// Styling follows the app's existing bottom-sheet convention: the caller
/// (`showModalBottomSheet`) sets `backgroundColor`/`shape`, this widget just
/// renders a `SafeArea` + drag-handle + content, same as `_showMessageActions`
/// and `_showDeleteConfirm` in `chat_room_screen.dart`.
class MessageInfoSheet extends StatelessWidget {
  final MessageEntity message;
  final List<ParticipantCursor> cursors;
  final Map<String, String> nameById;

  const MessageInfoSheet({
    super.key,
    required this.message,
    required this.cursors,
    required this.nameById,
  });

  String _displayName(String userId) => nameById[userId] ?? userId;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final l10n = AppLocalizations.of(context)!;
    final readers = cursors
        .where((x) => x.lastReadAt != null && !x.lastReadAt!.isBefore(message.sentAt))
        .toList()
      ..sort((a, b) => b.lastReadAt!.compareTo(a.lastReadAt!));
    final reactions = message.reactions;

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colors.textSecondary.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              l10n.messageInfo,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: colors.textPrimary),
            ),
          ),
          const SizedBox(height: 4),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.only(bottom: 12),
              children: [
                _SectionHeader(label: l10n.readBy, colors: colors),
                if (readers.isEmpty)
                  _EmptyRow(label: l10n.notReadYet, colors: colors)
                else
                  ...readers.map((r) => ListTile(
                        dense: true,
                        leading: CircleAvatar(
                          radius: 16,
                          backgroundColor: colors.primary.withValues(alpha: 0.15),
                          child: Text(
                            _displayName(r.userId).isNotEmpty
                                ? _displayName(r.userId)[0].toUpperCase()
                                : '?',
                            style: TextStyle(color: colors.primary, fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                        ),
                        title: Text(_displayName(r.userId), style: TextStyle(color: colors.textPrimary)),
                        trailing: Text(
                          DateFormat('HH:mm').format(r.lastReadAt!.toLocal()),
                          style: TextStyle(color: colors.textSecondary, fontSize: 12),
                        ),
                      )),
                const Divider(height: 24),
                _SectionHeader(label: l10n.reactionsLabel, colors: colors),
                if (reactions.isEmpty)
                  _EmptyRow(label: l10n.noReactions, colors: colors)
                else
                  ...reactions.map((r) {
                    final userId = r['userId'] as String? ?? '';
                    final emoji = r['emoji'] as String? ?? '';
                    return ListTile(
                      dense: true,
                      leading: Text(emoji, style: const TextStyle(fontSize: 20)),
                      title: Text(_displayName(userId), style: TextStyle(color: colors.textPrimary)),
                    );
                  }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  final AppColorsExtension colors;
  const _SectionHeader({required this.label, required this.colors});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            label,
            style: TextStyle(color: colors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),
      );
}

class _EmptyRow extends StatelessWidget {
  final String label;
  final AppColorsExtension colors;
  const _EmptyRow({required this.label, required this.colors});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Text(
          label,
          style: TextStyle(color: colors.textSecondary, fontSize: 13, fontStyle: FontStyle.italic),
        ),
      );
}

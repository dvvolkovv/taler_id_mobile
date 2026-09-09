import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';

/// Prompt for an optional room password before creating a meeting room.
///
/// Returns the entered text (possibly empty = no password) if the user
/// confirmed, or null if they cancelled — callers should abort room
/// creation in that case. A free function (not a State method) because
/// it's shared by two independent screens; checks `context.mounted`
/// itself since it has no `State.mounted` of its own, and callers must
/// still re-check their own `mounted` after awaiting it before touching
/// `context`/`setState` again.
Future<String?> promptRoomPassword(BuildContext context) async {
  if (!context.mounted) return null;
  final colors = AppColors.of(context);
  final l10n = AppLocalizations.of(context)!;
  final controller = TextEditingController();
  final result = await showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: colors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(l10n.roomCreateTitle, style: TextStyle(color: colors.textPrimary)),
      content: TextField(
        controller: controller,
        autofocus: true,
        style: TextStyle(color: colors.textPrimary),
        decoration: InputDecoration(
          labelText: l10n.roomPasswordOptional,
          labelStyle: TextStyle(color: colors.textSecondary),
          helperText: l10n.roomPasswordHelper,
          helperStyle: TextStyle(color: colors.textSecondary, fontSize: 11),
          helperMaxLines: 2,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
        onSubmitted: (_) => Navigator.of(ctx).pop(controller.text),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: Text(l10n.cancel, style: TextStyle(color: colors.textSecondary)),
        ),
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(controller.text),
          child: Text(l10n.create, style: TextStyle(color: colors.primary, fontWeight: FontWeight.w600)),
        ),
      ],
    ),
  );
  controller.dispose();
  return result;
}

/// Shows a room's password on its own line with its own copy button.
///
/// Deliberately separate from any link row shown alongside it — folding
/// the password into the same row as the link would make it trivial to
/// forward both together in one message/paste, which defeats the point
/// of setting one. Shared by call history's temporary-room sheet and the
/// calendar meeting-link form so the two can't drift apart the way the
/// password dialog itself already did once.
class RoomPasswordRow extends StatelessWidget {
  final String password;
  const RoomPasswordRow({super.key, required this.password});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final l10n = AppLocalizations.of(context)!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(left: 12, right: 4, top: 4, bottom: 4),
      decoration: BoxDecoration(
        color: colors.background.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.border.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Text(
            '${l10n.roomPasswordLabel}: ',
            style: TextStyle(color: colors.textSecondary, fontSize: 13),
          ),
          Expanded(
            child: Text(
              password,
              style: TextStyle(color: colors.primary, fontSize: 13, fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: Icon(Icons.copy_rounded, size: 18, color: colors.textSecondary),
            tooltip: l10n.callHistoryCopy,
            onPressed: () {
              Clipboard.setData(ClipboardData(text: password));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(l10n.roomPasswordCopied),
                  backgroundColor: colors.primary,
                  duration: const Duration(seconds: 1),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

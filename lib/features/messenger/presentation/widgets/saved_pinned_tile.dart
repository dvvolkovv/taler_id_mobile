import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/repositories/i_messenger_repository.dart';

class SavedPinnedTile extends StatelessWidget {
  const SavedPinnedTile({super.key});

  Future<void> _open(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final repo = GetIt.instance<IMessengerRepository>();
      final convId = await repo.getOrCreateSavedConversation();
      if (!context.mounted) return;
      context.go('/dashboard/messenger/$convId');
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.savedOpenError)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final ext = Theme.of(context).extension<AppColorsExtension>();
    final primary = ext?.primary ?? cs.primary;
    final textPrimary = ext?.textPrimary ?? cs.onSurface;
    final textSecondary = ext?.textSecondary ?? cs.onSurfaceVariant;

    return InkWell(
      onTap: () => _open(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [primary, primary.withValues(alpha: 0.7)],
                ),
              ),
              child: const Icon(Icons.bookmark_rounded, color: Colors.white, size: 26),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.savedTitle,
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l10n.savedSubtitle,
                    style: TextStyle(color: textSecondary, fontSize: 13),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: textSecondary),
          ],
        ),
      ),
    );
  }
}

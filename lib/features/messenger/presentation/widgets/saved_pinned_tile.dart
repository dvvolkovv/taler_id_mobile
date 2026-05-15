import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/storage/saved_conversation_id_cache.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/repositories/i_messenger_repository.dart';

class SavedPinnedTile extends StatefulWidget {
  const SavedPinnedTile({super.key});

  @override
  State<SavedPinnedTile> createState() => _SavedPinnedTileState();
}

class _SavedPinnedTileState extends State<SavedPinnedTile> {
  bool _opening = false;

  Future<void> _open(BuildContext context) async {
    if (_opening) return;
    _opening = true;
    try {
      final l10n = AppLocalizations.of(context)!;
      final cache = GetIt.instance<SavedConversationIdCache>();
      final repo = GetIt.instance<IMessengerRepository>();

      final cachedId = await cache.read();

      if (cachedId != null) {
        // Optimistic: navigate immediately, refresh from server in the
        // background. Works offline because the chat room itself is
        // offline-capable (Hive cache + outbox).
        if (!context.mounted) return;
        context.go('/dashboard/messenger/$cachedId');
        unawaited(_refreshCache(repo, cache));
        return;
      }

      // Cache miss — first-ever open. Requires connectivity.
      try {
        final convId = await repo.getOrCreateSavedConversation();
        await cache.write(convId);
        if (!context.mounted) return;
        context.go('/dashboard/messenger/$convId');
      } catch (_) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.savedOpenError)),
        );
      }
    } finally {
      _opening = false;
    }
  }

  Future<void> _refreshCache(
    IMessengerRepository repo,
    SavedConversationIdCache cache,
  ) async {
    try {
      final freshId = await repo.getOrCreateSavedConversation();
      await cache.write(freshId);
    } catch (_) {
      // Offline / transient — keep the cached id, no UI feedback.
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

    return ListTile(
      dense: true,
      visualDensity: const VisualDensity(horizontal: 0, vertical: -2),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      onTap: () => _open(context),
      leading: Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: primary, width: 2),
          boxShadow: [
            BoxShadow(
              color: primary.withValues(alpha: 0.35),
              blurRadius: 10,
              spreadRadius: 0,
            ),
          ],
        ),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [primary, primary.withValues(alpha: 0.7)],
            ),
          ),
          child: const Icon(Icons.bookmark_rounded, color: Colors.white, size: 22),
        ),
      ),
      title: Text(
        l10n.savedTitle,
        style: TextStyle(
          color: textPrimary,
          fontWeight: FontWeight.w600,
        ),
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        l10n.savedSubtitle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: textSecondary, fontSize: 13),
      ),
    );
  }
}

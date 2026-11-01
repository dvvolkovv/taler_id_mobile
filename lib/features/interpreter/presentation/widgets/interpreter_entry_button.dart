import 'package:flutter/material.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/platform/platform_utils.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/widgets.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/interpreter_models.dart';
import '../../domain/interpreter_repository.dart';

/// Memoized for the life of the app: the catalog only changes with a server
/// deploy, and every `CallHistoryScreen` rebuild (tab switches, pull to
/// refresh) would otherwise re-fetch it for nothing. Only a *successful*
/// answer is kept — [_fetchCatalog] reports failure as `null`, and memoizing
/// that would hide the button until restart after one network blip or a
/// request racing the auth token, instead of just trying again next build.
Future<InterpreterCatalog?>? _catalogFuture;

Future<InterpreterCatalog?> _loadCatalogOnce() {
  final cached = _catalogFuture;
  if (cached != null) return cached;

  final future = _fetchCatalog();
  _catalogFuture = future;
  future.then((catalog) {
    if (catalog == null && identical(_catalogFuture, future)) {
      _catalogFuture = null;
    }
  });
  return future;
}

Future<InterpreterCatalog?> _fetchCatalog() async {
  try {
    return await sl<InterpreterRepository>().catalog();
  } catch (_) {
    // Disabled-by-default is the safe reading of "couldn't find out" — the
    // button just doesn't render rather than risking a dead link.
    return null;
  }
}

/// Clears the memoized catalog. **Test use only** — never call in production
/// code.
@visibleForTesting
void debugResetInterpreterCatalogCache() {
  _catalogFuture = null;
}

/// Exercises the cache directly. **Test use only** — never call in
/// production code. [PlatformUtils.instance.isMobile] has no fake/override
/// hook (it reads `dart:io Platform` straight through) and is `false` under
/// `flutter test` on every host this repo builds on, so [build]'s own gate
/// would otherwise keep the cache from ever being touched in a widget test.
@visibleForTesting
Future<InterpreterCatalog?> debugLoadInterpreterCatalogForTest() =>
    _loadCatalogOnce();

/// "Разговор с переводом" entry point on the Calls tab. Renders nothing on
/// desktop (the feature is mobile-only) and nothing until the catalog is
/// known to be enabled — no loading placeholder, since a quiet skip reads
/// better than a card that flashes in and out on every screen open.
class InterpreterEntryButton extends StatelessWidget {
  final VoidCallback onTap;

  const InterpreterEntryButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    if (!PlatformUtils.instance.isMobile) return const SizedBox.shrink();

    return FutureBuilder<InterpreterCatalog?>(
      future: _loadCatalogOnce(),
      builder: (context, snapshot) {
        final catalog = snapshot.data;
        if (catalog == null || !catalog.enabled) return const SizedBox.shrink();

        final colors = AppColors.of(context);
        final l10n = AppLocalizations.of(context)!;
        return GestureDetector(
          onTap: onTap,
          child: AppCard(
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [colors.primary, colors.accent],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.translate_rounded,
                      color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l10n.interpreterTitle,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Icon(Icons.chevron_right_rounded,
                    color: colors.textSecondary, size: 22),
              ],
            ),
          ),
        );
      },
    );
  }
}

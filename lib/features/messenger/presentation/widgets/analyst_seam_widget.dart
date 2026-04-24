import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/analyst_events.dart';

class AnalystSeamWidget extends StatelessWidget {
  final AnalystSeam seam;
  const AnalystSeamWidget({super.key, required this.seam});

  String _labelFor(SeamStep step, AppLocalizations l10n) {
    switch (step.kind) {
      case 'search':
        return l10n.analystSeamSearches(step.count);
      case 'file':
        return l10n.analystSeamFiles(step.count);
      case 'cmd':
        return l10n.analystSeamCommands(step.count);
      case 'image':
        return l10n.analystSeamImages(step.count);
      default:
        return l10n.analystSeamOther(step.count);
    }
  }

  String _emojiFor(String kind) {
    switch (kind) {
      case 'search':
        return '🔍';
      case 'file':
        return '📄';
      case 'cmd':
        return '💻';
      case 'image':
        return '🎨';
      default:
        return '⚙️';
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final ext = Theme.of(context).extension<AppColorsExtension>();
    final bg = (ext?.card ?? cs.surfaceContainerHighest).withValues(alpha: 0.5);
    final fg = ext?.textSecondary ?? cs.onSurfaceVariant;

    final parts = <String>[
      for (final s in seam.steps) '${_emojiFor(s.kind)} ${_labelFor(s, l10n)}',
      '⏱ ${l10n.analystSeamDurationSeconds((seam.durationMs / 1000).round())}',
    ];

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 6, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        parts.join(' · '),
        style: TextStyle(color: fg, fontSize: 11),
      ),
    );
  }
}

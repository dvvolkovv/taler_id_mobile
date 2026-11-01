import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../billing/presentation/screens/_billing_formatters.dart';
import '../../domain/interpreter_models.dart';
import 'interpreter_texts.dart';

/// Final screen after a call ends: why it ended, how long it ran and — for
/// the host only — how much it cost.
class EndedView extends StatelessWidget {
  final InterpreterEndReason? reason;
  final Duration? duration;
  final String? spentPlanck;
  final bool isHost;
  final VoidCallback onDone;
  final VoidCallback onAgain;

  const EndedView({
    super.key,
    required this.reason,
    required this.duration,
    required this.spentPlanck,
    required this.isHost,
    required this.onDone,
    required this.onAgain,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final l10n = AppLocalizations.of(context)!;
    final shownDuration = duration;
    final shownSpent = spentPlanck;

    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.call_end_rounded,
                  color: colors.textSecondary, size: 40),
              const SizedBox(height: 16),
              Text(
                l10n.interpreterEndedTitle,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                interpreterEndText(l10n, reason),
                textAlign: TextAlign.center,
                style: TextStyle(color: colors.textSecondary, fontSize: 14),
              ),
              if (shownDuration != null) ...[
                const SizedBox(height: 16),
                Text(
                  l10n.interpreterDurationLabel(
                      interpreterFormatDuration(shownDuration)),
                  style: TextStyle(color: colors.textPrimary, fontSize: 14),
                ),
              ],
              if (isHost && shownSpent != null) ...[
                const SizedBox(height: 4),
                Text(
                  l10n.interpreterSpentAmount(planckToMicroTal(shownSpent)),
                  style: TextStyle(color: colors.textPrimary, fontSize: 14),
                ),
              ],
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: onDone,
                  child: Text(l10n.interpreterDoneButton),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton(
                  onPressed: onAgain,
                  child: Text(l10n.interpreterAgainButton),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

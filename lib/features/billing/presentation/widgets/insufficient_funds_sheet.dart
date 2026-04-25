import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';

/// Modal bottom sheet shown when the server returns HTTP 402 for a metered
/// feature call. Invoked centrally from the Dio paywall interceptor (Task 7).
///
/// Use the static [show] helper to display the sheet — it wires up the
/// modal bottom sheet host with `isScrollControlled: true` so the sheet
/// respects the on-screen keyboard and safe area.
class InsufficientFundsSheet extends StatelessWidget {
  final String featureKey;
  final String requiredPlanck;
  final String availablePlanck;
  final String? suggestedPackage;

  const InsufficientFundsSheet({
    super.key,
    required this.featureKey,
    required this.requiredPlanck,
    required this.availablePlanck,
    this.suggestedPackage,
  });

  /// Shows the sheet. Returns once it is dismissed (pop).
  static Future<void> show(
    BuildContext context, {
    required String featureKey,
    required String requiredPlanck,
    required String availablePlanck,
    String? suggestedPackage,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => InsufficientFundsSheet(
        featureKey: featureKey,
        requiredPlanck: requiredPlanck,
        availablePlanck: availablePlanck,
        suggestedPackage: suggestedPackage,
      ),
    );
  }

  /// Convert planck (18 decimals) → μTAL (12 decimals) by dividing by 1e6.
  /// We operate on strings to avoid int64 overflow on large planck values.
  /// Falls back to the raw planck string on parse errors.
  String _planckToMicroTal(String planck) {
    final value = BigInt.tryParse(planck);
    if (value == null) return planck;
    final microTal = value ~/ BigInt.from(1000000);
    final fraction = value % BigInt.from(1000000);
    if (fraction == BigInt.zero) {
      return microTal.toString();
    }
    final fracStr = fraction.toString().padLeft(6, '0');
    // Trim trailing zeros for readability.
    final trimmed = fracStr.replaceFirst(RegExp(r'0+$'), '');
    if (trimmed.isEmpty) return microTal.toString();
    return '$microTal.$trimmed';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final requiredMicroTal = _planckToMicroTal(requiredPlanck);
    final availableMicroTal = _planckToMicroTal(availablePlanck);

    return Padding(
      padding: EdgeInsets.only(
        top: 24,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.account_balance_wallet_outlined,
                size: 36,
                color: colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            l10n.billingInsufficientFundsTitle,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            l10n.billingInsufficientFundsSubtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  l10n.billingRequiredLine(requiredMicroTal),
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 12),
                Container(width: 1, height: 14, color: colorScheme.outlineVariant),
                const SizedBox(width: 12),
                Text(
                  l10n.billingAvailableLine(availableMicroTal),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              final pref = suggestedPackage ?? 'starter';
              context.push('/billing/wallet?preferred=$pref');
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(l10n.billingTopUp),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.billingCancel),
          ),
        ],
      ),
    );
  }
}

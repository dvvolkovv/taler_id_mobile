import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/utils/constants.dart';
import '../bloc/balance_bloc.dart';
import '../bloc/balance_state.dart';

/// AppBar chip showing the user's wallet balance in μTAL.
///
/// Subscribes to [BalanceBloc] and rebuilds on state changes.
/// Tapping the chip navigates to the in-dashboard wallet screen.
///
/// States:
///  - [BalanceLoaded]   → `"X.XX μTAL"`
///  - [BalanceLoading]  → `"…"`
///  - [BalanceError] / [BalanceInitial] → `"—"`
class BalanceChip extends StatelessWidget {
  const BalanceChip({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return BlocBuilder<BalanceBloc, BalanceState>(
      builder: (context, state) {
        final String text;
        if (state is BalanceLoaded) {
          text = '${state.balance.balanceMicroTal} μTAL';
        } else if (state is BalanceLoading) {
          text = '…';
        } else {
          text = '—';
        }

        return InkWell(
          onTap: () => context.push(RouteConstants.wallet),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: primary.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.account_balance_wallet_outlined,
                  size: 16,
                  color: primary,
                ),
                const SizedBox(width: 6),
                Text(
                  text,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

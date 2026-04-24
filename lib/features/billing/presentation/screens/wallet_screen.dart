import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/utils/error_keys.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/billing_package_entity.dart';
import '../../domain/entities/billing_transaction_entity.dart';
import '../bloc/balance_bloc.dart';
import '../bloc/balance_event.dart';
import '../bloc/balance_state.dart';
import '../bloc/packages_bloc.dart';
import '../bloc/packages_event.dart';
import '../bloc/packages_state.dart';
import '_billing_formatters.dart';

/// Primary wallet screen: shows balance, available packages, recent transactions.
///
/// Entry point for the billing UX — reached from the [BalanceChip] in the
/// AppBar or from the `Insufficient funds` / `Low balance` modals.
///
/// Hosts two BLoCs (balance + packages) via [MultiBlocProvider]. Refresh
/// reloads both from the backend.
class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<BalanceBloc>(
          create: (_) => sl<BalanceBloc>()..add(LoadBalance()),
        ),
        BlocProvider<PackagesBloc>(
          create: (_) => sl<PackagesBloc>()..add(LoadPackages()),
        ),
      ],
      child: const _WalletView(),
    );
  }
}

class _WalletView extends StatelessWidget {
  const _WalletView();

  Future<void> _refresh(BuildContext context) async {
    context.read<BalanceBloc>().add(LoadBalance());
    context.read<PackagesBloc>().add(LoadPackages());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.billingWalletTitle)),
      body: RefreshIndicator(
        color: theme.colorScheme.primary,
        onRefresh: () => _refresh(context),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: const [
            _BalanceCard(),
            SizedBox(height: 24),
            _PackagesSection(),
            SizedBox(height: 24),
            _RecentTransactionsSection(),
          ],
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Balance card
// ────────────────────────────────────────────────────────────────────────────

class _BalanceCard extends StatelessWidget {
  const _BalanceCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return BlocBuilder<BalanceBloc, BalanceState>(
      builder: (context, state) {
        String display;
        if (state is BalanceLoaded) {
          display = '${state.balance.balanceMicroTal} μTAL';
        } else if (state is BalanceLoading || state is BalanceInitial) {
          display = '…';
        } else if (state is BalanceError) {
          display = '—';
        } else {
          display = '—';
        }

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                colorScheme.primary.withValues(alpha: 0.18),
                colorScheme.primary.withValues(alpha: 0.06),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: colorScheme.primary.withValues(alpha: 0.25),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.account_balance_wallet_outlined,
                    color: colorScheme.primary,
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    l10n.billingCurrentBalance,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.75),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                display,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (state is BalanceError) ...[
                const SizedBox(height: 8),
                Text(
                  resolveErrorMessage(l10n, state.message),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.error,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => context.push('/billing/purchase'),
                icon: const Icon(Icons.add, size: 18),
                label: Text(l10n.billingBuyPackage),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Packages
// ────────────────────────────────────────────────────────────────────────────

class _PackagesSection extends StatelessWidget {
  const _PackagesSection();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.billingPackagesTitle,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        BlocBuilder<PackagesBloc, PackagesState>(
          builder: (context, state) {
            if (state is PackagesLoading || state is PackagesInitial) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: CircularProgressIndicator(color: colorScheme.primary),
                ),
              );
            }
            if (state is PackagesError) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  resolveErrorMessage(l10n, state.message),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.error,
                  ),
                ),
              );
            }
            // PackagesLoaded, PurchaseInProgress, PurchaseSuccess, PurchaseFailed
            // all still have the package list in the BLoC's cache — we only
            // render the loaded state here.
            if (state is PackagesLoaded) {
              if (state.packages.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    l10n.billingPackagesUnavailable,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                );
              }
              return Column(
                children: [
                  for (final pkg in state.packages)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _PackageCard(
                        package: pkg,
                        onTap: () => context.push(
                          '/billing/purchase',
                          extra: {'preferred': pkg.id},
                        ),
                      ),
                    ),
                ],
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ],
    );
  }
}

class _PackageCard extends StatelessWidget {
  final BillingPackageEntity package;
  final VoidCallback onTap;

  const _PackageCard({required this.package, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final title = package.label['ru'] ?? package.label['en'] ?? package.id;
    final highlightsRu =
        package.highlights['ru'] ?? package.highlights['en'] ?? const <String>[];
    final priceEur = (package.priceEurCents / 100).toStringAsFixed(2);

    return Material(
      color: colorScheme.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.5),
              width: 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (highlightsRu.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      for (final h in highlightsRu)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '• ',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurface
                                      .withValues(alpha: 0.55),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  h,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurface
                                        .withValues(alpha: 0.75),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '€$priceEur',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Icon(
                    Icons.chevron_right,
                    color: colorScheme.onSurface.withValues(alpha: 0.4),
                    size: 20,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Recent transactions
// ────────────────────────────────────────────────────────────────────────────

class _RecentTransactionsSection extends StatelessWidget {
  const _RecentTransactionsSection();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return BlocBuilder<BalanceBloc, BalanceState>(
      builder: (context, state) {
        final List<BillingTransactionEntity> tx =
            state is BalanceLoaded ? state.balance.recentTx : const [];
        // Latest first; we take at most 5.
        final recent = tx.take(5).toList(growable: false);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.billingRecentOperations,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => context.push('/billing/transactions'),
                  child: Text(l10n.billingAllOperations),
                ),
              ],
            ),
            const SizedBox(height: 4),
            if (state is! BalanceLoaded)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  '—',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              )
            else if (recent.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  l10n.billingNoOperations,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              )
            else
              Column(
                children: [
                  for (final t in recent) _TransactionRow(tx: t),
                ],
              ),
          ],
        );
      },
    );
  }
}

class _TransactionRow extends StatelessWidget {
  final BillingTransactionEntity tx;

  const _TransactionRow({required this.tx});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final credit = isCreditTx(tx);
    final amountMicroTal = planckToMicroTal(tx.amountPlanck);
    // Strip any '-' so we can prepend our own sign in front of μTAL suffix.
    final absAmount = amountMicroTal.startsWith('-')
        ? amountMicroTal.substring(1)
        : amountMicroTal;
    final sign = credit ? '+' : '-';
    final amountColor = credit ? colorScheme.primary : colorScheme.onSurface;
    final label = featureLabel(l10n, tx.featureKey);
    final subtitle = [
      if (label != null && label.isNotEmpty) label,
      formatIsoDate(tx.createdAt),
    ].join(' · ');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              txIcon(tx),
              size: 18,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  typeLabel(l10n, tx),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$sign$absAmount μTAL',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: amountColor,
            ),
          ),
        ],
      ),
    );
  }
}


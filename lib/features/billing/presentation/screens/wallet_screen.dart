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
    return Scaffold(
      appBar: AppBar(title: const Text('Кошелёк')),
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
                    'Текущий баланс',
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
                label: const Text('Купить пакет'),
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
          'Пакеты',
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
                    'Пакеты недоступны',
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
                    'Последние операции',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => context.push('/billing/transactions'),
                  child: const Text('Все операции'),
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
                  'Операций нет',
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

  /// Convert planck (18 decimals) → μTAL (12 decimals) by dividing by 1e6.
  /// Accepts optional leading '-' for outgoing amounts.
  /// Operates on strings to avoid int64 overflow.
  String _planckToMicroTal(String planck) {
    var s = planck;
    final negative = s.startsWith('-');
    if (negative) s = s.substring(1);
    final value = BigInt.tryParse(s);
    if (value == null) return planck;
    final microTal = value ~/ BigInt.from(1000000);
    final fraction = value % BigInt.from(1000000);
    String result;
    if (fraction == BigInt.zero) {
      result = microTal.toString();
    } else {
      final fracStr = fraction.toString().padLeft(6, '0');
      final trimmed = fracStr.replaceFirst(RegExp(r'0+$'), '');
      result = trimmed.isEmpty ? microTal.toString() : '$microTal.$trimmed';
    }
    return negative ? '-$result' : result;
  }

  bool get _isCredit {
    // Classify by type first; fall back to sign of amount.
    final t = tx.type.toUpperCase();
    if (t.startsWith('TOPUP') || t.contains('REFUND') || t.contains('CREDIT')) {
      return true;
    }
    if (t.contains('SPEND') || t.contains('DEBIT') || t.contains('CHARGE')) {
      return false;
    }
    return !tx.amountPlanck.startsWith('-');
  }

  String _typeLabel() {
    final t = tx.type.toUpperCase();
    if (t.startsWith('TOPUP')) return 'Пополнение';
    if (t.contains('REFUND')) return 'Возврат';
    if (t.contains('SPEND') || t.contains('DEBIT') || t.contains('CHARGE')) {
      return 'Оплата';
    }
    return tx.type;
  }

  IconData _icon() {
    if (_isCredit) return Icons.south_west;
    return Icons.north_east;
  }

  String _formatDate(String iso) {
    final dt = DateTime.tryParse(iso);
    if (dt == null) return iso;
    final local = dt.toLocal();
    final y = local.year.toString();
    final m = local.month.toString().padLeft(2, '0');
    final d = local.day.toString().padLeft(2, '0');
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');
    return '$d.$m.$y $hh:$mm';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final amountMicroTal = _planckToMicroTal(tx.amountPlanck);
    // Strip any '-' so we can prepend our own sign in front of μTAL suffix.
    final absAmount = amountMicroTal.startsWith('-')
        ? amountMicroTal.substring(1)
        : amountMicroTal;
    final sign = _isCredit ? '+' : '-';
    final amountColor =
        _isCredit ? colorScheme.primary : colorScheme.onSurface;
    final subtitle = [
      if (tx.featureKey != null && tx.featureKey!.isNotEmpty) tx.featureKey!,
      _formatDate(tx.createdAt),
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
              _icon(),
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
                  _typeLabel(),
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


import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/widgets.dart';
import '../../../../core/utils/constants.dart';
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

/// Single billing screen: balance, packages with inline buy buttons,
/// and recent transactions. Replaces the prior split between wallet
/// (preview) and purchase (actual buy) screens — packages are bought
/// directly here.
///
/// Reached from [BalanceChip], [LowBalanceBanner], and the
/// [InsufficientFundsSheet]. The optional [preferred] query parameter
/// highlights one package (used when the paywall sheet recommends a
/// specific top-up size).
class WalletScreen extends StatelessWidget {
  final String? preferred;
  const WalletScreen({super.key, this.preferred});

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
      child: _WalletView(preferred: preferred),
    );
  }
}

class _WalletView extends StatelessWidget {
  final String? preferred;
  const _WalletView({required this.preferred});

  Future<void> _refresh(BuildContext context) async {
    context.read<BalanceBloc>().add(LoadBalance());
    context.read<PackagesBloc>().add(LoadPackages());
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: Text(l10n.billingWalletTitle),
        backgroundColor: colors.background,
        elevation: 0,
      ),
      body: BlocListener<PackagesBloc, PackagesState>(
        listener: (context, state) {
          final messenger = ScaffoldMessenger.of(context);
          if (state is PurchaseSuccess) {
            try {
              context.read<BalanceBloc>().add(
                    BalanceChangedExternally(state.newBalance.balancePlanck),
                  );
            } catch (_) {}
            messenger.showSnackBar(
              SnackBar(
                content: Text(
                  l10n.billingPackagePurchased(
                      state.newBalance.balanceMicroTal),
                ),
                backgroundColor: colors.primary,
              ),
            );
          } else if (state is PurchaseFailed) {
            messenger.showSnackBar(
              SnackBar(
                content: Text(resolveErrorMessage(l10n, state.message)),
                backgroundColor: colors.error,
              ),
            );
          }
        },
        child: RefreshIndicator(
          color: colors.primary,
          onRefresh: () => _refresh(context),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              _SectionHeader(label: l10n.billingCurrentBalance),
              const SizedBox(height: 8),
              const _BalanceCard(),
              const SizedBox(height: 20),
              _SectionHeader(label: l10n.billingPackagesTitle),
              const SizedBox(height: 8),
              _PackagesSection(preferred: preferred),
              const SizedBox(height: 20),
              const _RecentTransactionsSection(),
            ],
          ),
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Section header — gradient bar + small caps label, identical to Settings
// ────────────────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String label;
  final Widget? trailing;
  const _SectionHeader({required this.label, this.trailing});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 14,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [colors.primary, colors.accent],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: colors.textPrimary.withValues(alpha: 0.85),
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.6,
              ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
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
    final colors = AppColors.of(context);
    final l10n = AppLocalizations.of(context)!;

    return BlocBuilder<BalanceBloc, BalanceState>(
      builder: (context, state) {
        String display;
        String? errMsg;
        if (state is BalanceLoaded) {
          display = '${state.balance.balanceMicroTal} μTAL';
        } else if (state is BalanceLoading || state is BalanceInitial) {
          display = '…';
        } else if (state is BalanceError) {
          display = '—';
          errMsg = resolveErrorMessage(l10n, state.message);
        } else {
          display = '—';
        }

        return AppCard(
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color.lerp(colors.primary, Colors.white, 0.15)!,
                      colors.primary,
                      Color.lerp(colors.primary, Colors.black, 0.25)!,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(11),
                  boxShadow: [
                    BoxShadow(
                      color: colors.primary.withValues(alpha: 0.45),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.account_balance_wallet_outlined,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      display,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (errMsg != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        errMsg,
                        style: TextStyle(color: colors.error, fontSize: 11),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Packages — grouped in a single AppCard, divided by thin lines, each
// row carries an inline LoadingButton (the only place to buy).
// ────────────────────────────────────────────────────────────────────────────

class _PackagesSection extends StatelessWidget {
  final String? preferred;
  const _PackagesSection({required this.preferred});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final l10n = AppLocalizations.of(context)!;

    return BlocBuilder<PackagesBloc, PackagesState>(
      builder: (context, state) {
        if (state is PackagesLoading || state is PackagesInitial) {
          return AppCard(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: CircularProgressIndicator(color: colors.primary),
              ),
            ),
          );
        }
        if (state is PackagesError) {
          return AppCard(
            child: Text(
              resolveErrorMessage(l10n, state.message),
              style: TextStyle(color: colors.error, fontSize: 12),
            ),
          );
        }

        // PackagesLoaded / PurchaseInProgress / PurchaseSuccess /
        // PurchaseFailed all flow through here. The BLoC re-emits
        // PackagesLoaded after each transition, so we read the list
        // off PackagesLoaded — and only carry an inProgressId override
        // while a purchase is mid-flight.
        List<BillingPackageEntity> packages = const [];
        String? inProgressId;
        if (state is PackagesLoaded) {
          packages = state.packages;
        } else if (state is PurchaseInProgress) {
          inProgressId = state.packageId;
        }

        if (packages.isEmpty) {
          return AppCard(
            child: Text(
              l10n.billingPackagesUnavailable,
              style: TextStyle(color: colors.textSecondary, fontSize: 12),
            ),
          );
        }

        return AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (int i = 0; i < packages.length; i++) ...[
                _PackageRow(
                  package: packages[i],
                  highlighted: packages[i].id == preferred,
                  busy: inProgressId == packages[i].id,
                  // Only one purchase at a time — disable the others.
                  disabled:
                      inProgressId != null && inProgressId != packages[i].id,
                ),
                if (i < packages.length - 1)
                  Divider(color: colors.border, height: 1, thickness: 1),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _PackageRow extends StatelessWidget {
  final BillingPackageEntity package;
  final bool highlighted;
  final bool busy;
  final bool disabled;

  const _PackageRow({
    required this.package,
    required this.highlighted,
    required this.busy,
    required this.disabled,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final l10n = AppLocalizations.of(context)!;
    final title = package.label['ru'] ?? package.label['en'] ?? package.id;
    final highlights = package.highlights['ru'] ??
        package.highlights['en'] ??
        const <String>[];
    final priceEur = (package.priceEurCents / 100).toStringAsFixed(2);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            style: TextStyle(
                              color: colors.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (highlighted) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: colors.primary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: colors.primary.withValues(alpha: 0.30),
                              ),
                            ),
                            child: Text(
                              l10n.billingRecommendedBadge,
                              style: TextStyle(
                                color: colors.primary,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (highlights.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      for (final h in highlights)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '• ',
                                style: TextStyle(
                                  color: colors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  h,
                                  style: TextStyle(
                                    color: colors.textSecondary,
                                    fontSize: 12,
                                    height: 1.35,
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
              Text(
                '€$priceEur',
                style: TextStyle(
                  color: colors.primary,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LoadingButton(
            text: l10n.billingBuyForPrice(priceEur),
            loading: busy,
            onPressed: disabled
                ? null
                : () => context
                    .read<PackagesBloc>()
                    .add(PurchasePackage(package.id)),
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Recent transactions — single AppCard with rows, "Все" link in header.
// ────────────────────────────────────────────────────────────────────────────

class _RecentTransactionsSection extends StatelessWidget {
  const _RecentTransactionsSection();

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final l10n = AppLocalizations.of(context)!;

    return BlocBuilder<BalanceBloc, BalanceState>(
      builder: (context, state) {
        final List<BillingTransactionEntity> tx =
            state is BalanceLoaded ? state.balance.recentTx : const [];
        final recent = tx.take(5).toList(growable: false);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SectionHeader(
              label: l10n.billingRecentOperations,
              trailing: TextButton(
                onPressed: () => context.push(RouteConstants.transactions),
                style: TextButton.styleFrom(
                  foregroundColor: colors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: const Size(0, 28),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  l10n.billingAllOperations,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ),
            const SizedBox(height: 8),
            if (state is! BalanceLoaded)
              AppCard(
                child: Text(
                  '—',
                  style: TextStyle(color: colors.textSecondary, fontSize: 12),
                ),
              )
            else if (recent.isEmpty)
              AppCard(
                child: Text(
                  l10n.billingNoOperations,
                  style: TextStyle(color: colors.textSecondary, fontSize: 12),
                ),
              )
            else
              AppCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    for (int i = 0; i < recent.length; i++) ...[
                      _TransactionRow(tx: recent[i]),
                      if (i < recent.length - 1)
                        Divider(color: colors.border, height: 1, thickness: 1),
                    ],
                  ],
                ),
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
    final colors = AppColors.of(context);
    final l10n = AppLocalizations.of(context)!;
    final credit = isCreditTx(tx);
    final amountMicroTal = planckToMicroTal(tx.amountPlanck);
    final absAmount = amountMicroTal.startsWith('-')
        ? amountMicroTal.substring(1)
        : amountMicroTal;
    final sign = credit ? '+' : '-';
    final amountColor = credit ? colors.primary : colors.textPrimary;
    final iconBg = credit ? colors.primary : colors.textSecondary;
    final label = featureLabel(l10n, tx.featureKey);
    final subtitle = [
      if (label != null && label.isNotEmpty) label,
      formatIsoDate(tx.createdAt),
    ].join(' · ');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color.lerp(iconBg, Colors.white, 0.15)!,
                  iconBg,
                  Color.lerp(iconBg, Colors.black, 0.25)!,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(9),
              boxShadow: [
                BoxShadow(
                  color: iconBg.withValues(alpha: 0.45),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Icon(txIcon(tx), size: 16, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  typeLabel(l10n, tx),
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 12,
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
            style: TextStyle(
              color: amountColor,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

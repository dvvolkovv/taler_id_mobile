import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/utils/error_keys.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/billing_package_entity.dart';
import '../bloc/balance_bloc.dart';
import '../bloc/balance_event.dart';
import '../bloc/packages_bloc.dart';
import '../bloc/packages_event.dart';
import '../bloc/packages_state.dart';

/// Purchase a billing package.
///
/// Reached from the wallet screen ("Купить пакет") or from the
/// [InsufficientFundsSheet] ("Пополнить"). Accepts an optional [preferred]
/// package id to highlight.
class PurchaseScreen extends StatelessWidget {
  final String? preferred;

  const PurchaseScreen({super.key, this.preferred});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<PackagesBloc>(
      create: (_) => sl<PackagesBloc>()..add(LoadPackages()),
      child: _PurchaseView(preferred: preferred),
    );
  }
}

class _PurchaseView extends StatelessWidget {
  final String? preferred;

  const _PurchaseView({required this.preferred});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.billingBuyPackage)),
      body: BlocConsumer<PackagesBloc, PackagesState>(
        listener: (context, state) {
          if (state is PurchaseSuccess) {
            // Notify any open BalanceBloc instance (wallet screen below us
            // or other host) that the balance has changed. Reload is
            // idempotent even if no listener is registered.
            try {
              context.read<BalanceBloc>().add(
                    BalanceChangedExternally(
                      state.newBalance.balancePlanck,
                    ),
                  );
            } catch (_) {
              // No BalanceBloc in ancestor scope — safe to ignore.
            }
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  l10n.billingPackagePurchased(
                    state.newBalance.balanceMicroTal,
                  ),
                ),
                backgroundColor: colorScheme.primary,
              ),
            );
            // Close the purchase screen and return control to the caller.
            if (context.mounted && Navigator.of(context).canPop()) {
              context.pop();
            }
          } else if (state is PurchaseFailed) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(resolveErrorMessage(l10n, state.message)),
                backgroundColor: colorScheme.error,
              ),
            );
          }
        },
        builder: (context, state) {
          // Error state before first successful load.
          if (state is PackagesError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 48,
                      color: colorScheme.error,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      resolveErrorMessage(l10n, state.message),
                      style: theme.textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () =>
                          context.read<PackagesBloc>().add(LoadPackages()),
                      child: Text(l10n.billingRetry),
                    ),
                  ],
                ),
              ),
            );
          }

          // Determine which packages to render and in-progress package id.
          final List<BillingPackageEntity> packages;
          String? inProgressId;
          if (state is PackagesLoaded) {
            packages = state.packages;
          } else if (state is PurchaseInProgress) {
            // BLoC emits PurchaseInProgress without the list; packages live
            // in the private cache. We rely on the fact that PackagesLoaded
            // is re-emitted after every purchase — until then show a
            // spinner-only view is fine.
            packages = const [];
            inProgressId = state.packageId;
          } else {
            // Initial / Loading / success-before-loaded snapshot.
            packages = const [];
          }

          final isBusy = inProgressId != null;

          if (packages.isEmpty && !isBusy) {
            return Center(
              child: CircularProgressIndicator(color: colorScheme.primary),
            );
          }

          return Stack(
            children: [
              ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                children: [
                  for (final pkg in packages)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _PackageOptionCard(
                        package: pkg,
                        highlighted: pkg.id == preferred,
                        busy: inProgressId == pkg.id,
                        disabled: isBusy,
                        onBuy: isBusy
                            ? null
                            : () => context
                                .read<PackagesBloc>()
                                .add(PurchasePackage(pkg.id)),
                      ),
                    ),
                ],
              ),
              if (isBusy)
                Positioned.fill(
                  child: IgnorePointer(
                    ignoring: false,
                    child: ColoredBox(
                      color: Colors.black.withValues(alpha: 0.25),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _PackageOptionCard extends StatelessWidget {
  final BillingPackageEntity package;
  final bool highlighted;
  final bool busy;
  final bool disabled;
  final VoidCallback? onBuy;

  const _PackageOptionCard({
    required this.package,
    required this.highlighted,
    required this.busy,
    required this.disabled,
    required this.onBuy,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final title = package.label['ru'] ?? package.label['en'] ?? package.id;
    final highlightsRu =
        package.highlights['ru'] ?? package.highlights['en'] ?? const <String>[];
    final priceEur = (package.priceEurCents / 100).toStringAsFixed(2);

    final borderColor = highlighted
        ? colorScheme.primary
        : colorScheme.outlineVariant.withValues(alpha: 0.5);
    final borderWidth = highlighted ? 2.0 : 1.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: borderWidth),
      ),
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
                            style: theme.textTheme.titleMedium?.copyWith(
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
                              color:
                                  colorScheme.primary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              l10n.billingRecommendedBadge,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (highlightsRu.isNotEmpty) ...[
                      const SizedBox(height: 8),
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
              Text(
                '€$priceEur',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: (disabled || busy) ? null : onBuy,
            child: busy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(l10n.billingBuyForPrice(priceEur)),
          ),
        ],
      ),
    );
  }
}

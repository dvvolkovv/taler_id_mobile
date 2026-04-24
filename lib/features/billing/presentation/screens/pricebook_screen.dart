import 'package:flutter/material.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/utils/error_keys.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/pricebook_item_entity.dart';
import '../../domain/repositories/billing_repository.dart';
import '_billing_formatters.dart';

/// Read-only price list for AI features.
///
/// Pricebook has no events or state transitions — a [FutureBuilder] wrapping
/// [BillingRepository.getPricebook] is simpler than a full BLoC here.
class PricebookScreen extends StatefulWidget {
  const PricebookScreen({super.key});

  @override
  State<PricebookScreen> createState() => _PricebookScreenState();
}

class _PricebookScreenState extends State<PricebookScreen> {
  late Future<List<PricebookItemEntity>> _future;

  @override
  void initState() {
    super.initState();
    _future = sl<BillingRepository>().getPricebook();
  }

  void _reload() {
    setState(() {
      _future = sl<BillingRepository>().getPricebook();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: const Text('Цены на функции')),
      body: FutureBuilder<List<PricebookItemEntity>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return Center(
              child: CircularProgressIndicator(
                color: theme.colorScheme.primary,
              ),
            );
          }
          if (snapshot.hasError) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 48,
                      color: theme.colorScheme.error,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      resolveErrorMessage(l10n, snapshot.error.toString()),
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: _reload,
                      child: const Text('Повторить'),
                    ),
                  ],
                ),
              ),
            );
          }
          final items = snapshot.data ?? const <PricebookItemEntity>[];
          if (items.isEmpty) {
            return Center(
              child: Text(
                'Прайс-лист недоступен',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            );
          }

          // Render in the canonical feature order; append any unknown keys
          // at the end so we never silently drop a backend-supplied item.
          final byKey = {for (final it in items) it.featureKey: it};
          final ordered = <PricebookItemEntity>[
            for (final k in orderedFeatureKeys)
              if (byKey.containsKey(k)) byKey[k]!,
            for (final it in items)
              if (!orderedFeatureKeys.contains(it.featureKey)) it,
          ];

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            itemCount: ordered.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) => _PricebookRow(item: ordered[i]),
          );
        },
      ),
    );
  }
}

class _PricebookRow extends StatelessWidget {
  final PricebookItemEntity item;

  const _PricebookRow({required this.item});

  /// Translate a unit string to a human-friendly Russian label.
  String _unitLabel(String unit) {
    switch (unit) {
      case 'minute':
        return 'минуту';
      case 'request':
        return 'запрос';
      case 'token':
        return 'токен';
      case 'token_1k':
      case 'tokens_1k':
        return '1К токенов';
      case 'call':
        return 'звонок';
      default:
        return unit;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final name = featureLabels[item.featureKey] ?? item.featureKey;
    final unitLabel = _unitLabel(item.unit);
    final subtitle =
        '\$${item.costUsdPerUnit} × ${item.markupMultiplier} за $unitLabel';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.65),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '\$${item.costUsdPerUnit}',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}

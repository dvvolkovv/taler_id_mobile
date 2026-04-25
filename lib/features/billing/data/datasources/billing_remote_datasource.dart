import '../../../../core/api/dio_client.dart';
import '../../domain/entities/billing_package_entity.dart';
import '../../domain/entities/billing_transaction_entity.dart';
import '../../domain/entities/feature_toggle_entity.dart';
import '../../domain/entities/pricebook_item_entity.dart';
import '../../domain/entities/wallet_balance_entity.dart';

class BillingRemoteDataSource {
  final DioClient client;
  BillingRemoteDataSource(this.client);

  Future<WalletBalanceEntity> getBalance() => client.get(
        '/billing/balance',
        fromJson: (d) => WalletBalanceEntity.fromJson(
          Map<String, dynamic>.from(d as Map),
        ),
      );

  Future<List<BillingPackageEntity>> getPackages() => client.get(
        '/billing/packages',
        fromJson: (d) => (d as List)
            .map((p) => BillingPackageEntity.fromJson(
                  Map<String, dynamic>.from(p as Map),
                ))
            .toList(),
      );

  Future<Map<String, dynamic>> purchase(String packageId) => client.post(
        '/billing/purchase/$packageId',
        fromJson: (d) => Map<String, dynamic>.from(d as Map),
      );

  Future<String> getWalletAddress() => client.get(
        '/billing/wallet',
        fromJson: (d) =>
            (Map<String, dynamic>.from(d as Map))['custodialAddress'] as String,
      );

  Future<List<BillingTransactionEntity>> getTransactions() => client.get(
        '/billing/transactions',
        fromJson: (d) => (d as List)
            .map((t) => BillingTransactionEntity.fromJson(
                  Map<String, dynamic>.from(t as Map),
                ))
            .toList(),
      );

  Future<List<PricebookItemEntity>> getPricebook() => client.get(
        '/billing/pricebook',
        fromJson: (d) => (d as List)
            .map((p) => PricebookItemEntity.fromJson(
                  Map<String, dynamic>.from(p as Map),
                ))
            .toList(),
      );

  Future<List<FeatureToggleEntity>> getToggles() => client.get(
        '/billing/settings/toggles',
        fromJson: (d) => (d as List)
            .map((t) => FeatureToggleEntity.fromJson(
                  Map<String, dynamic>.from(t as Map),
                ))
            .toList(),
      );

  Future<FeatureToggleEntity> setToggle(String featureKey, bool enabled) =>
      client.patch(
        '/billing/settings/toggles/$featureKey',
        data: {'enabled': enabled},
        fromJson: (d) => FeatureToggleEntity.fromJson(
          Map<String, dynamic>.from(d as Map),
        ),
      );
}

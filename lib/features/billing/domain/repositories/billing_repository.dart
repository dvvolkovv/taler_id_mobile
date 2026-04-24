import '../entities/billing_package_entity.dart';
import '../entities/billing_transaction_entity.dart';
import '../entities/feature_toggle_entity.dart';
import '../entities/pricebook_item_entity.dart';
import '../entities/wallet_balance_entity.dart';

abstract class BillingRepository {
  Future<WalletBalanceEntity> getBalance();
  Future<List<BillingPackageEntity>> getPackages();
  Future<WalletBalanceEntity> purchase(String packageId);
  Future<String> getWalletAddress();
  Future<List<BillingTransactionEntity>> getTransactions();
  Future<List<PricebookItemEntity>> getPricebook();
  Future<List<FeatureToggleEntity>> getToggles();
  Future<FeatureToggleEntity> setToggle(String featureKey, bool enabled);
}

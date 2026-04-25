import '../../domain/entities/billing_package_entity.dart';
import '../../domain/entities/billing_transaction_entity.dart';
import '../../domain/entities/feature_toggle_entity.dart';
import '../../domain/entities/pricebook_item_entity.dart';
import '../../domain/entities/wallet_balance_entity.dart';
import '../../domain/repositories/billing_repository.dart';
import '../datasources/billing_remote_datasource.dart';

class BillingRepositoryImpl implements BillingRepository {
  final BillingRemoteDataSource remote;

  BillingRepositoryImpl({required this.remote});

  @override
  Future<WalletBalanceEntity> getBalance() => remote.getBalance();

  @override
  Future<List<BillingPackageEntity>> getPackages() => remote.getPackages();

  @override
  Future<WalletBalanceEntity> purchase(String packageId) async {
    await remote.purchase(packageId);
    return remote.getBalance();
  }

  @override
  Future<String> getWalletAddress() => remote.getWalletAddress();

  @override
  Future<List<BillingTransactionEntity>> getTransactions() =>
      remote.getTransactions();

  @override
  Future<List<PricebookItemEntity>> getPricebook() => remote.getPricebook();

  @override
  Future<List<FeatureToggleEntity>> getToggles() => remote.getToggles();

  @override
  Future<FeatureToggleEntity> setToggle(String featureKey, bool enabled) =>
      remote.setToggle(featureKey, enabled);
}

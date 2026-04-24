import 'package:freezed_annotation/freezed_annotation.dart';

import 'billing_transaction_entity.dart';

part 'wallet_balance_entity.freezed.dart';
part 'wallet_balance_entity.g.dart';

@freezed
class WalletBalanceEntity with _$WalletBalanceEntity {
  const factory WalletBalanceEntity({
    required String balancePlanck,
    required String balanceMicroTal,
    String? custodialAddress,
    @Default(<BillingTransactionEntity>[])
    List<BillingTransactionEntity> recentTx,
  }) = _WalletBalanceEntity;

  factory WalletBalanceEntity.fromJson(Map<String, dynamic> json) =>
      _$WalletBalanceEntityFromJson(json);
}

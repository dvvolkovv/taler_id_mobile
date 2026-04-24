// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wallet_balance_entity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$WalletBalanceEntityImpl _$$WalletBalanceEntityImplFromJson(
        Map<String, dynamic> json) =>
    _$WalletBalanceEntityImpl(
      balancePlanck: json['balancePlanck'] as String,
      balanceMicroTal: json['balanceMicroTal'] as String,
      custodialAddress: json['custodialAddress'] as String?,
      recentTx: (json['recentTx'] as List<dynamic>?)
              ?.map((e) =>
                  BillingTransactionEntity.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <BillingTransactionEntity>[],
    );

Map<String, dynamic> _$$WalletBalanceEntityImplToJson(
        _$WalletBalanceEntityImpl instance) =>
    <String, dynamic>{
      'balancePlanck': instance.balancePlanck,
      'balanceMicroTal': instance.balanceMicroTal,
      'custodialAddress': instance.custodialAddress,
      'recentTx': instance.recentTx,
    };

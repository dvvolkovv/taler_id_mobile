// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'billing_transaction_entity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$BillingTransactionEntityImpl _$$BillingTransactionEntityImplFromJson(
        Map<String, dynamic> json) =>
    _$BillingTransactionEntityImpl(
      id: json['id'] as String,
      type: json['type'] as String,
      amountPlanck: json['amountPlanck'] as String,
      featureKey: json['featureKey'] as String?,
      sessionId: json['sessionId'] as String?,
      createdAt: json['createdAt'] as String,
      status: json['status'] as String? ?? 'COMPLETED',
      metadata: json['metadata'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$$BillingTransactionEntityImplToJson(
        _$BillingTransactionEntityImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': instance.type,
      'amountPlanck': instance.amountPlanck,
      'featureKey': instance.featureKey,
      'sessionId': instance.sessionId,
      'createdAt': instance.createdAt,
      'status': instance.status,
      'metadata': instance.metadata,
    };

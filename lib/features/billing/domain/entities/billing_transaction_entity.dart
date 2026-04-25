import 'package:freezed_annotation/freezed_annotation.dart';

part 'billing_transaction_entity.freezed.dart';
part 'billing_transaction_entity.g.dart';

@freezed
class BillingTransactionEntity with _$BillingTransactionEntity {
  const factory BillingTransactionEntity({
    required String id,
    required String type,
    required String amountPlanck,
    String? featureKey,
    String? sessionId,
    required String createdAt,
    @Default('COMPLETED') String status,
    Map<String, dynamic>? metadata,
  }) = _BillingTransactionEntity;

  factory BillingTransactionEntity.fromJson(Map<String, dynamic> json) =>
      _$BillingTransactionEntityFromJson(json);
}

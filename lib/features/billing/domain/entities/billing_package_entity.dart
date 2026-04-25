import 'package:freezed_annotation/freezed_annotation.dart';

part 'billing_package_entity.freezed.dart';
part 'billing_package_entity.g.dart';

@freezed
class BillingPackageEntity with _$BillingPackageEntity {
  const factory BillingPackageEntity({
    required String id,
    required String amountPlanck,
    required int priceEurCents,
    required Map<String, String> label,
    required Map<String, List<String>> highlights,
  }) = _BillingPackageEntity;

  factory BillingPackageEntity.fromJson(Map<String, dynamic> json) =>
      _$BillingPackageEntityFromJson(json);
}

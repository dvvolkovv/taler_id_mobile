import 'package:freezed_annotation/freezed_annotation.dart';

part 'pricebook_item_entity.freezed.dart';
part 'pricebook_item_entity.g.dart';

@freezed
class PricebookItemEntity with _$PricebookItemEntity {
  const factory PricebookItemEntity({
    required String featureKey,
    required String unit,
    required String costUsdPerUnit,
    required String markupMultiplier,
    required String minReservePlanck,
  }) = _PricebookItemEntity;

  factory PricebookItemEntity.fromJson(Map<String, dynamic> json) =>
      _$PricebookItemEntityFromJson(json);
}

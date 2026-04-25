// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pricebook_item_entity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PricebookItemEntityImpl _$$PricebookItemEntityImplFromJson(
        Map<String, dynamic> json) =>
    _$PricebookItemEntityImpl(
      featureKey: json['featureKey'] as String,
      unit: json['unit'] as String,
      costUsdPerUnit: json['costUsdPerUnit'] as String,
      markupMultiplier: json['markupMultiplier'] as String,
      minReservePlanck: json['minReservePlanck'] as String,
    );

Map<String, dynamic> _$$PricebookItemEntityImplToJson(
        _$PricebookItemEntityImpl instance) =>
    <String, dynamic>{
      'featureKey': instance.featureKey,
      'unit': instance.unit,
      'costUsdPerUnit': instance.costUsdPerUnit,
      'markupMultiplier': instance.markupMultiplier,
      'minReservePlanck': instance.minReservePlanck,
    };

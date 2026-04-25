// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'billing_package_entity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$BillingPackageEntityImpl _$$BillingPackageEntityImplFromJson(
        Map<String, dynamic> json) =>
    _$BillingPackageEntityImpl(
      id: json['id'] as String,
      amountPlanck: json['amountPlanck'] as String,
      priceEurCents: (json['priceEurCents'] as num).toInt(),
      label: Map<String, String>.from(json['label'] as Map),
      highlights: (json['highlights'] as Map<String, dynamic>).map(
        (k, e) =>
            MapEntry(k, (e as List<dynamic>).map((e) => e as String).toList()),
      ),
    );

Map<String, dynamic> _$$BillingPackageEntityImplToJson(
        _$BillingPackageEntityImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'amountPlanck': instance.amountPlanck,
      'priceEurCents': instance.priceEurCents,
      'label': instance.label,
      'highlights': instance.highlights,
    };

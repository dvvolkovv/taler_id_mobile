// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'grant_info.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$GrantInfoImpl _$$GrantInfoImplFromJson(Map<String, dynamic> json) =>
    _$GrantInfoImpl(
      clientName: json['client_name'] as String,
      clientLogo: json['client_logo'] as String?,
      scopes: (json['scopes'] as List<dynamic>)
          .map((e) => ScopeDescriptor.fromJson(e as Map<String, dynamic>))
          .toList(),
      remembered: json['remembered'] as bool,
    );

Map<String, dynamic> _$$GrantInfoImplToJson(_$GrantInfoImpl instance) =>
    <String, dynamic>{
      'client_name': instance.clientName,
      'client_logo': instance.clientLogo,
      'scopes': instance.scopes,
      'remembered': instance.remembered,
    };

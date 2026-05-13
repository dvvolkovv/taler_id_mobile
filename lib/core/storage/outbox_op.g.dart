// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'outbox_op.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$OutboxOpImpl _$$OutboxOpImplFromJson(Map<String, dynamic> json) =>
    _$OutboxOpImpl(
      opId: json['opId'] as String,
      feature: json['feature'] as String,
      op: $enumDecode(_$OutboxOpKindEnumMap, json['op']),
      entityId: json['entityId'] as String,
      payload: json['payload'] as Map<String, dynamic>?,
      expectedUpdatedAt: json['expectedUpdatedAt'] == null
          ? null
          : DateTime.parse(json['expectedUpdatedAt'] as String),
      attempts: (json['attempts'] as num?)?.toInt() ?? 0,
      status: $enumDecodeNullable(_$OutboxOpStatusEnumMap, json['status']) ??
          OutboxOpStatus.pending,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastAttemptAt: json['lastAttemptAt'] == null
          ? null
          : DateTime.parse(json['lastAttemptAt'] as String),
      lastError: json['lastError'] as String?,
      serverData: json['serverData'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$$OutboxOpImplToJson(_$OutboxOpImpl instance) =>
    <String, dynamic>{
      'opId': instance.opId,
      'feature': instance.feature,
      'op': _$OutboxOpKindEnumMap[instance.op]!,
      'entityId': instance.entityId,
      'payload': instance.payload,
      'expectedUpdatedAt': instance.expectedUpdatedAt?.toIso8601String(),
      'attempts': instance.attempts,
      'status': _$OutboxOpStatusEnumMap[instance.status]!,
      'createdAt': instance.createdAt.toIso8601String(),
      'lastAttemptAt': instance.lastAttemptAt?.toIso8601String(),
      'lastError': instance.lastError,
      'serverData': instance.serverData,
    };

const _$OutboxOpKindEnumMap = {
  OutboxOpKind.create: 'create',
  OutboxOpKind.update: 'update',
  OutboxOpKind.delete: 'delete',
};

const _$OutboxOpStatusEnumMap = {
  OutboxOpStatus.pending: 'pending',
  OutboxOpStatus.inflight: 'inflight',
  OutboxOpStatus.failedConflict: 'failedConflict',
  OutboxOpStatus.failedDead: 'failedDead',
};

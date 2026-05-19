// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'agent_run_result.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$AgentToolCallImpl _$$AgentToolCallImplFromJson(Map<String, dynamic> json) =>
    _$AgentToolCallImpl(
      name: json['name'] as String,
      input: json['input'] as Map<String, dynamic>,
      output: json['output'] as String,
    );

Map<String, dynamic> _$$AgentToolCallImplToJson(_$AgentToolCallImpl instance) =>
    <String, dynamic>{
      'name': instance.name,
      'input': instance.input,
      'output': instance.output,
    };

_$AgentRunResultImpl _$$AgentRunResultImplFromJson(Map<String, dynamic> json) =>
    _$AgentRunResultImpl(
      finalText: json['finalText'] as String,
      toolCalls: (json['toolCalls'] as List<dynamic>)
          .map((e) => AgentToolCall.fromJson(e as Map<String, dynamic>))
          .toList(),
      aborted: json['aborted'] as bool,
      conversationId: json['conversationId'] as String?,
    );

Map<String, dynamic> _$$AgentRunResultImplToJson(
        _$AgentRunResultImpl instance) =>
    <String, dynamic>{
      'finalText': instance.finalText,
      'toolCalls': instance.toolCalls,
      'aborted': instance.aborted,
      'conversationId': instance.conversationId,
    };

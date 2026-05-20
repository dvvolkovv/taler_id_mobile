import 'package:freezed_annotation/freezed_annotation.dart';

part 'agent_run_result.freezed.dart';
part 'agent_run_result.g.dart';

@freezed
class AgentToolCall with _$AgentToolCall {
  const factory AgentToolCall({
    required String name,
    required Map<String, dynamic> input,
    required String output,
  }) = _AgentToolCall;

  factory AgentToolCall.fromJson(Map<String, dynamic> json) =>
      _$AgentToolCallFromJson(json);
}

@freezed
class AgentRunResult with _$AgentRunResult {
  const factory AgentRunResult({
    required String finalText,
    required List<AgentToolCall> toolCalls,
    required bool aborted,
    String? conversationId,
  }) = _AgentRunResult;

  factory AgentRunResult.fromJson(Map<String, dynamic> json) =>
      _$AgentRunResultFromJson(json);
}

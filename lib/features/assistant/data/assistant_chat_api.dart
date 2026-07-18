import '../../../core/api/dio_client.dart';

enum AssistantTurnStatus { finalText, toolCalls }

class AssistantTurnResult {
  const AssistantTurnResult({
    required this.status,
    this.text,
    this.messageId,
    this.assistantMessage,
    this.toolCalls,
  });
  final AssistantTurnStatus status;
  final String? text;
  final String? messageId;
  final Map<String, dynamic>? assistantMessage;
  final List<Map<String, dynamic>>? toolCalls;
}

class AssistantChatApi {
  AssistantChatApi(this._dio);
  final DioClient _dio;

  Future<String> getThread() async {
    final data = await _dio.get<Map<String, dynamic>>(
      '/assistant/chat',
      fromJson: (d) => (d as Map).cast<String, dynamic>(),
    );
    return data['conversationId'] as String;
  }

  Future<void> logEntries(List<Map<String, dynamic>> entries) async {
    await _dio.post<Map<String, dynamic>>(
      '/assistant/chat/log',
      data: {'entries': entries},
      fromJson: (d) => (d as Map).cast<String, dynamic>(),
    );
  }

  Future<AssistantTurnResult> textTurn({
    String? text,
    required String instructions,
    required List<Map<String, dynamic>> tools,
    Map<String, dynamic>? pendingAssistantMessage,
    List<Map<String, dynamic>>? toolResults,
  }) async {
    final data = await _dio.post<Map<String, dynamic>>(
      '/assistant/chat/turn',
      data: {
        if (text != null) 'text': text,
        'instructions': instructions,
        'tools': tools,
        if (pendingAssistantMessage != null)
          'pendingAssistantMessage': pendingAssistantMessage,
        if (toolResults != null) 'toolResults': toolResults,
      },
      fromJson: (d) => (d as Map).cast<String, dynamic>(),
    );
    if (data['status'] == 'tool_calls') {
      return AssistantTurnResult(
        status: AssistantTurnStatus.toolCalls,
        assistantMessage:
            (data['assistantMessage'] as Map?)?.cast<String, dynamic>(),
        toolCalls: (data['toolCalls'] as List)
            .map((e) => (e as Map).cast<String, dynamic>())
            .toList(),
      );
    }
    return AssistantTurnResult(
      status: AssistantTurnStatus.finalText,
      text: data['text'] as String?,
      messageId: data['messageId'] as String?,
    );
  }
}

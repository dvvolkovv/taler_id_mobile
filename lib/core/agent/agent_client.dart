import 'package:dio/dio.dart';
import 'models/agent_run_result.dart';

class AgentClient {
  final Dio _dio;

  AgentClient(this._dio);

  Future<AgentRunResult> runAgent({
    required String goal,
    String? conversationId,
    String? model,
  }) async {
    final body = <String, dynamic>{
      'goal': goal,
      if (conversationId != null) 'conversationId': conversationId,
      if (model != null) 'model': model,
    };

    final resp = await _dio.post<Map<String, dynamic>>(
      '/agent/run',
      data: body,
    );

    return AgentRunResult.fromJson(resp.data ?? const {});
  }
}

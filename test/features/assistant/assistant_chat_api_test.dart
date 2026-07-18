import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:taler_id_mobile/core/api/dio_client.dart';
import 'package:taler_id_mobile/features/assistant/data/assistant_chat_api.dart';

class MockDioClient extends Mock implements DioClient {}

void main() {
  late MockDioClient dio;
  late AssistantChatApi api;

  setUp(() {
    dio = MockDioClient();
    api = AssistantChatApi(dio);
  });

  test('getThread returns conversationId', () async {
    when(() => dio.get<Map<String, dynamic>>('/assistant/chat',
            fromJson: any(named: 'fromJson')))
        .thenAnswer((_) async => {'conversationId': 'conv-1'});
    expect(await api.getThread(), 'conv-1');
  });

  test('logEntries posts entries payload', () async {
    when(() => dio.post<Map<String, dynamic>>('/assistant/chat/log',
            data: any(named: 'data'), fromJson: any(named: 'fromJson')))
        .thenAnswer((_) async => {'conversationId': 'conv-1', 'messageIds': ['m1']});
    await api.logEntries([
      {'role': 'user', 'source': 'voice', 'text': 'привет'},
    ]);
    final captured = verify(() => dio.post<Map<String, dynamic>>(
          '/assistant/chat/log',
          data: captureAny(named: 'data'),
          fromJson: any(named: 'fromJson'),
        )).captured.single as Map<String, dynamic>;
    expect(captured['entries'], hasLength(1));
  });

  test('textTurn final', () async {
    when(() => dio.post<Map<String, dynamic>>('/assistant/chat/turn',
            data: any(named: 'data'), fromJson: any(named: 'fromJson')))
        .thenAnswer((_) async =>
            {'status': 'final', 'text': 'Готово', 'messageId': 'a1'});
    final r = await api.textTurn(
        text: 'привет', instructions: 'sys', tools: const []);
    expect(r.status, AssistantTurnStatus.finalText);
    expect(r.text, 'Готово');
  });

  test('textTurn tool_calls', () async {
    when(() => dio.post<Map<String, dynamic>>('/assistant/chat/turn',
            data: any(named: 'data'), fromJson: any(named: 'fromJson')))
        .thenAnswer((_) async => {
              'status': 'tool_calls',
              'assistantMessage': {'role': 'assistant', 'tool_calls': []},
              'toolCalls': [
                {
                  'id': 'call_1',
                  'function': {'name': 'send_message', 'arguments': '{}'}
                }
              ],
            });
    final r = await api.textTurn(
        text: 'отправь', instructions: 'sys', tools: const []);
    expect(r.status, AssistantTurnStatus.toolCalls);
    expect(r.toolCalls, hasLength(1));
  });
}

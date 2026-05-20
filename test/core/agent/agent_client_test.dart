import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:taler_id_mobile/core/agent/agent_client.dart';

class _MockDio extends Mock implements Dio {}

class _FakeRequestOptions extends Fake implements RequestOptions {}

void main() {
  setUpAll(() {
    registerFallbackValue(_FakeRequestOptions());
  });

  late _MockDio dio;
  late AgentClient client;

  setUp(() {
    dio = _MockDio();
    client = AgentClient(dio);
  });

  test('POSTs /agent/run with goal and parses response', () async {
    when(() => dio.post<Map<String, dynamic>>(
          any(),
          data: any(named: 'data'),
        )).thenAnswer(
      (_) async => Response<Map<String, dynamic>>(
        requestOptions: RequestOptions(path: '/agent/run'),
        statusCode: 200,
        data: {
          'finalText': 'echoed: ping',
          'toolCalls': [
            {
              'name': 'echo',
              'input': {'text': 'ping'},
              'output': 'ping',
            },
          ],
          'aborted': false,
          'conversationId': 'conv-1',
        },
      ),
    );

    final result = await client.runAgent(goal: 'echo ping');

    expect(result.finalText, 'echoed: ping');
    expect(result.toolCalls.length, 1);
    expect(result.toolCalls.first.name, 'echo');
    expect(result.toolCalls.first.output, 'ping');
    expect(result.aborted, isFalse);
    expect(result.conversationId, 'conv-1');

    verify(() => dio.post<Map<String, dynamic>>(
          '/agent/run',
          data: {'goal': 'echo ping'},
        )).called(1);
  });

  test('includes conversationId and model when provided', () async {
    when(() => dio.post<Map<String, dynamic>>(
          any(),
          data: any(named: 'data'),
        )).thenAnswer(
      (_) async => Response<Map<String, dynamic>>(
        requestOptions: RequestOptions(path: '/agent/run'),
        statusCode: 200,
        data: {
          'finalText': 'ok',
          'toolCalls': [],
          'aborted': false,
        },
      ),
    );

    await client.runAgent(
      goal: 'go',
      conversationId: 'c-9',
      model: 'claude-opus-4-7',
    );

    verify(() => dio.post<Map<String, dynamic>>(
          '/agent/run',
          data: {
            'goal': 'go',
            'conversationId': 'c-9',
            'model': 'claude-opus-4-7',
          },
        )).called(1);
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:taler_id_mobile/core/api/dio_client.dart';
import 'package:taler_id_mobile/core/di/service_locator.dart';
import 'package:taler_id_mobile/features/assistant/domain/assistant_action.dart';
import 'package:taler_id_mobile/features/assistant/tools/assistant_tools_executor.dart';

class MockDioClient extends Mock implements DioClient {}

void main() {
  test('unknown tool returns readable message', () async {
    final ex = AssistantToolsExecutor();
    expect(await ex.execute('no_such_tool', {}), contains('Unknown tool'));
  });

  test('session-bound tool without hooks refuses politely', () async {
    final ex = AssistantToolsExecutor();
    final res = await ex.execute('end_session', {});
    expect(res.toLowerCase(), contains('voice session'));
  });

  group('web_search action bubble', () {
    late MockDioClient client;

    setUp(() {
      client = MockDioClient();
      sl.registerLazySingleton<DioClient>(() => client);
    });

    tearDown(() async {
      await sl.reset();
    });

    void stubWebSearch(Map<String, dynamic> response) {
      when(() => client.post<Map<String, dynamic>>(
            '/assistant/web-search',
            data: any(named: 'data'),
            fromJson: any(named: 'fromJson'),
          )).thenAnswer((_) async => response);
    }

    test('emits web_link action from first citation', () async {
      stubWebSearch({
        'answer': 'Вот билеты',
        'citations': ['https://tickets.example/x', 'https://b.example'],
      });
      final actions = <AssistantAction>[];
      final ex = AssistantToolsExecutor(onAction: actions.add);

      final res = await ex.execute('web_search', {'query': 'билеты в Вену'});

      expect(res, contains('Вот билеты'));
      expect(actions, hasLength(1));
      expect(actions.single.type, AssistantActionType.webLink);
      expect(actions.single.entityId, 'https://tickets.example/x');
      expect(actions.single.title, contains('билеты в Вену'));
    });

    test('no citations → no action emitted', () async {
      stubWebSearch({'answer': 'Ответ без источников'});
      final actions = <AssistantAction>[];
      final ex = AssistantToolsExecutor(onAction: actions.add);

      await ex.execute('web_search', {'query': 'что-то'});

      expect(actions, isEmpty);
    });

    test('empty citations list → no action emitted', () async {
      stubWebSearch({'answer': 'Ответ', 'citations': <String>[]});
      final actions = <AssistantAction>[];
      final ex = AssistantToolsExecutor(onAction: actions.add);

      await ex.execute('web_search', {'query': 'что-то'});

      expect(actions, isEmpty);
    });
  });
}

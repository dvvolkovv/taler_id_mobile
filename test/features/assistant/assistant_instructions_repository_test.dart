import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:mocktail/mocktail.dart';
import 'package:taler_id_mobile/core/api/dio_client.dart';
import 'package:taler_id_mobile/features/assistant/data/assistant_instructions_repository.dart';
import 'package:taler_id_mobile/features/assistant/tools/assistant_system_prompt.dart';

class MockDioClient extends Mock implements DioClient {}

void main() {
  late Directory tmp;
  late Box<String> box;
  late MockDioClient dio;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('instructions_test');
    Hive.init(tmp.path);
    box = await Hive.openBox<String>('assistant_instructions_test');
    dio = MockDioClient();
  });

  tearDown(() async {
    await box.deleteFromDisk();
    await tmp.delete(recursive: true);
  });

  void stubFetch(String body) {
    when(() => dio.get<Map<String, dynamic>>(
          '/assistant/instructions',
          queryParameters: any(named: 'queryParameters'),
        )).thenAnswer((_) async => {
          'locale': 'ru',
          'body': body,
          'updatedAt': '2026-07-18T00:00:00.000Z',
        });
  }

  void stubError() {
    when(() => dio.get<Map<String, dynamic>>(
          '/assistant/instructions',
          queryParameters: any(named: 'queryParameters'),
        )).thenThrow(Exception('network down'));
  }

  group('AssistantInstructionsRepository', () {
    test('returns fetched body and persists it to Hive', () async {
      stubFetch('SERVER BODY {{NOW}}');
      final repo = AssistantInstructionsRepository(dio, box);

      final body = await repo.get('ru');

      expect(body, 'SERVER BODY {{NOW}}');
      expect(box.get('body_ru'), 'SERVER BODY {{NOW}}');
      verify(() => dio.get<Map<String, dynamic>>(
            '/assistant/instructions',
            queryParameters: {'locale': 'ru'},
          )).called(1);
    });

    test('second call within TTL does not re-hit Dio', () async {
      stubFetch('SERVER BODY');
      final repo = AssistantInstructionsRepository(dio, box);

      final first = await repo.get('ru');
      final second = await repo.get('ru');

      expect(first, 'SERVER BODY');
      expect(second, 'SERVER BODY');
      verify(() => dio.get<Map<String, dynamic>>(
            any(),
            queryParameters: any(named: 'queryParameters'),
          )).called(1);
    });

    test('fetch error returns Hive-cached body (stale ok)', () async {
      await box.put('body_ru', 'STALE CACHED BODY');
      stubError();
      final repo = AssistantInstructionsRepository(dio, box);

      final body = await repo.get('ru');

      expect(body, 'STALE CACHED BODY');
    });

    test('fetch error with empty box returns null', () async {
      stubError();
      final repo = AssistantInstructionsRepository(dio, box);

      final body = await repo.get('ru');

      expect(body, isNull);
    });

    test('locales are cached independently', () async {
      stubFetch('BODY');
      final repo = AssistantInstructionsRepository(dio, box);

      await repo.get('ru');
      await repo.get('en');

      verify(() => dio.get<Map<String, dynamic>>(
            any(),
            queryParameters: any(named: 'queryParameters'),
          )).called(2);
      expect(box.get('body_ru'), 'BODY');
      expect(box.get('body_en'), 'BODY');
    });
  });

  group('composeAssistantPrompt', () {
    test('substitutes {{NOW}} with current timestamp', () {
      final prompt = composeAssistantPrompt(
        body: 'X {{NOW}} Y',
        locale: 'ru',
      );

      expect(prompt, isNot(contains('{{NOW}}')));
      expect(prompt, contains('${DateTime.now().year}'));
      expect(prompt, contains('X '));
      expect(prompt, contains(' Y'));
    });

    test('substitutes {{LANG_NAME}} for en locale', () {
      final prompt = composeAssistantPrompt(
        body: 'ALWAYS reply ONLY in {{LANG_NAME}}.',
        locale: 'en',
      );

      expect(prompt, contains('ALWAYS reply ONLY in English.'));
      expect(prompt, isNot(contains('{{LANG_NAME}}')));
    });

    test('prepends name preamble when preferredName given', () {
      final prompt = composeAssistantPrompt(
        body: 'BODY',
        locale: 'ru',
        preferredName: 'Дмитрий',
        nameFromProfile: true,
      );

      expect(prompt, contains('Обращайся к пользователю по имени: Дмитрий.'));
      expect(prompt.endsWith('BODY'), isTrue);
    });

    test('baked-in assistantSystemPrompt has no unresolved placeholders', () {
      for (final locale in ['ru', 'en']) {
        final prompt = assistantSystemPrompt(
          locale: locale,
          preferredName: 'Test',
          nameFromProfile: true,
        );
        expect(prompt, isNot(contains('{{NOW}}')));
        expect(prompt, isNot(contains('{{LANG_NAME}}')));
        expect(prompt, contains('${DateTime.now().year}'));
      }
    });
  });
}

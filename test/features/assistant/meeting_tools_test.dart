import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:taler_id_mobile/core/api/dio_client.dart';
import 'package:taler_id_mobile/core/di/service_locator.dart';
import 'package:taler_id_mobile/features/assistant/tools/assistant_tools_executor.dart';
import 'package:taler_id_mobile/features/assistant/tools/assistant_tools_schema.dart';

class _MockDioClient extends Mock implements DioClient {}

/// Meeting recaps reach the assistant: the recordings the app already lists
/// under "Резюме встреч" were the one product area with no voice access at all,
/// while the rule in CLAUDE.md is that every feature has to be reachable
/// through it.
///
/// The transcript is the interesting part. A 56-minute meeting transcribes to
/// ~50 000 characters — dropping that into a realtime session's context as a
/// tool result costs more than the whole recap and crowds out everything else
/// the assistant knows. So the summary tool answers with the recap by default
/// and only reaches for the transcript when asked, capped.
void main() {
  late _MockDioClient client;

  setUp(() async {
    await sl.reset();
    client = _MockDioClient();
    sl.registerLazySingleton<DioClient>(() => client);
  });

  tearDown(() async {
    await sl.reset();
  });

  final tools = assistantToolSchemas(translatorMode: false);
  Map<String, dynamic> toolNamed(String name) =>
      tools.singleWhere((t) => t['name'] == name);

  AssistantToolsExecutor executor() => AssistantToolsExecutor();

  group('schema', () {
    test('all three meeting tools are declared exactly once', () {
      for (final name in [
        'get_meetings',
        'get_meeting_summary',
        'transcribe_meeting',
      ]) {
        expect(tools.where((t) => t['name'] == name), hasLength(1),
            reason: '$name should be declared once');
        final tool = toolNamed(name);
        expect(tool['type'], 'function');
        expect((tool['description'] as String).isNotEmpty, isTrue);
      }
    });

    test('get_meeting_summary and transcribe_meeting require a meetingId', () {
      for (final name in ['get_meeting_summary', 'transcribe_meeting']) {
        final params = toolNamed(name)['parameters'] as Map<String, dynamic>;
        final props = Map<String, dynamic>.from(params['properties'] as Map);
        expect(props.containsKey('meetingId'), isTrue, reason: name);
        expect(params['required'], contains('meetingId'), reason: name);
      }
    });

    test('the transcript is opt-in, not a required argument', () {
      final params =
          toolNamed('get_meeting_summary')['parameters'] as Map<String, dynamic>;
      final props = Map<String, dynamic>.from(params['properties'] as Map);
      expect(props.containsKey('includeTranscript'), isTrue);
      expect(params['required'], isNot(contains('includeTranscript')));
    });

    test('none of them leak into translator mode', () {
      final names = assistantToolSchemas(translatorMode: true)
          .map((t) => t['name'])
          .toSet();
      for (final name in [
        'get_meetings',
        'get_meeting_summary',
        'transcribe_meeting',
      ]) {
        expect(names, isNot(contains(name)));
      }
    });

    test('they are carried through to the text-chat tool list', () {
      final names = assistantToolSchemasForCompletions()
          .map((t) => (t['function'] as Map)['name'])
          .toSet();
      expect(names, containsAll([
        'get_meetings',
        'get_meeting_summary',
        'transcribe_meeting',
      ]));
    });
  });

  group('get_meetings', () {
    test('asks the backend for the recent meetings', () async {
      when(() => client.get<dynamic>(any(), fromJson: any(named: 'fromJson')))
          .thenAnswer((_) async => [
                {'id': 'm-1', 'roomName': 'personal-abc', 'status': 'done'},
              ]);

      final out = await executor().execute('get_meetings', {});

      final path = verify(() =>
              client.get<dynamic>(captureAny(), fromJson: any(named: 'fromJson')))
          .captured
          .single as String;
      expect(path, startsWith('/voice/meetings'));
      expect(jsonDecode(out), isA<List<dynamic>>());
    });

    test('passes a caller-supplied limit through', () async {
      when(() => client.get<dynamic>(any(), fromJson: any(named: 'fromJson')))
          .thenAnswer((_) async => <dynamic>[]);

      await executor().execute('get_meetings', {'limit': 5});

      final path = verify(() =>
              client.get<dynamic>(captureAny(), fromJson: any(named: 'fromJson')))
          .captured
          .single as String;
      expect(path, contains('limit=5'));
    });
  });

  group('get_meeting_summary', () {
    final fullMeeting = {
      'id': 'm-1',
      'summary': 'Обсудили обмен крипты.',
      'keyPoints': ['Адаптеры'],
      'actionItems': [
        {'task': 'Собрать сценарий', 'assignee': 'Vladimir', 'deadline': null},
      ],
      'decisions': ['Встречаться еженедельно'],
      'participants': ['Dmitry Volkov', 'Vladimir'],
      'status': 'done',
      'durationSec': 3341,
      'transcript': '[00:01] Dmitry Volkov: раз\n[00:13] Vladimir: два',
    };

    void stubMeeting([Map<String, dynamic>? over]) {
      when(() => client.get<dynamic>(any(), fromJson: any(named: 'fromJson')))
          .thenAnswer((_) async => {...fullMeeting, ...?over});
    }

    test('returns the recap without the transcript by default', () async {
      stubMeeting();

      final out = jsonDecode(await executor()
          .execute('get_meeting_summary', {'meetingId': 'm-1'})) as Map;

      expect(out['summary'], 'Обсудили обмен крипты.');
      expect(out['actionItems'], isA<List<dynamic>>());
      expect(out['participants'], contains('Vladimir'));
      expect(out.containsKey('transcript'), isFalse);
    });

    test('includes the transcript when the user asks for it', () async {
      stubMeeting();

      final out = jsonDecode(await executor().execute('get_meeting_summary',
          {'meetingId': 'm-1', 'includeTranscript': true})) as Map;

      expect(out['transcript'], contains('Dmitry Volkov: раз'));
    });

    test('caps a long transcript instead of flooding the session', () async {
      // Real meetings run to tens of thousands of characters.
      stubMeeting({'transcript': List.filled(4000, '[00:01] Кто-то: реплика').join('\n')});

      final out = jsonDecode(await executor().execute('get_meeting_summary',
          {'meetingId': 'm-1', 'includeTranscript': true})) as Map;

      final transcript = out['transcript'] as String;
      expect(transcript.length, lessThan(9000));
      expect(out['transcriptTruncated'], isTrue);
    });

    test('says plainly when the recording produced nothing', () async {
      // The row exists precisely so the user learns the recording failed;
      // handing the assistant an empty recap would make it invent a reason.
      stubMeeting({
        'status': 'failed_no_audio',
        'summary': 'Запись не записалась: recorder не получил аудио из комнаты.',
        'transcript': '',
      });

      final out = jsonDecode(await executor()
          .execute('get_meeting_summary', {'meetingId': 'm-1'})) as Map;

      expect(out['status'], 'failed_no_audio');
      expect(out['recordingFailed'], isTrue);
    });
  });

  group('transcribe_meeting', () {
    test('kicks off transcription for a recording that has none', () async {
      when(() => client.post<dynamic>(any(), data: any(named: 'data')))
          .thenAnswer((_) async => {'id': 'm-1', 'status': 'done'});

      final out = jsonDecode(
          await executor().execute('transcribe_meeting', {'meetingId': 'm-1'})) as Map;

      final path = verify(() =>
              client.post<dynamic>(captureAny(), data: any(named: 'data')))
          .captured
          .single as String;
      expect(path, '/voice/recordings/m-1/transcribe');
      expect(out['status'], 'done');
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:livekit_client/livekit_client.dart' as lk;
import 'package:mocktail/mocktail.dart';
import 'package:taler_id_mobile/core/api/dio_client.dart';
import 'package:taler_id_mobile/core/di/service_locator.dart';
import 'package:taler_id_mobile/core/services/call_state_service.dart';
import 'package:taler_id_mobile/features/assistant/tools/assistant_tools_executor.dart';
import 'package:taler_id_mobile/features/assistant/tools/assistant_tools_schema.dart';

class _MockDioClient extends Mock implements DioClient {}

/// Same shape as MockRoom in test/core/call_state_service_test.dart — the
/// executor never touches the room itself, only the room *name* that
/// CallStateService derives from it, so a bare mock is enough.
class _MockRoom extends Mock implements lk.Room {}

void main() {
  late _MockDioClient client;
  late CallStateService callState;

  setUp(() async {
    await sl.reset();
    client = _MockDioClient();
    sl.registerLazySingleton<DioClient>(() => client);

    // CallStateService is a process-wide singleton (`CallStateService.instance`,
    // not a GetIt registration — see the 73 call sites in lib/), so every test
    // starts by clearing whatever a previous one left behind.
    callState = CallStateService.instance;
    await callState.endCall();
  });

  tearDown(() async {
    await callState.endCall();
    await sl.reset();
  });

  /// Puts the singleton into "user is in a call in [roomName]" state.
  void enterCall(String roomName) {
    final room = _MockRoom();
    when(() => room.disconnect()).thenAnswer((_) async {});
    callState.setRoom(room, roomName, 'conv-1');
  }

  void stubChatPost(String roomName, Map<String, dynamic> response) {
    when(() => client.post<Map<String, dynamic>>(
          '/voice/rooms/$roomName/chat',
          data: any(named: 'data'),
          fromJson: any(named: 'fromJson'),
        )).thenAnswer((_) async => response);
  }

  group('send_room_chat — refusals never hit the network', () {
    test('outside a call there is no room to write to', () async {
      expect(callState.roomName, isNull, reason: 'precondition: not in a call');

      final res = await AssistantToolsExecutor()
          .execute('send_room_chat', {'text': 'привет всем'});

      // Readable for the model, not a JSON error blob.
      expect(res.toLowerCase(), contains('no active call'));
      verifyZeroInteractions(client);
    });

    test('empty text is refused while in a call', () async {
      enterCall('room-1');

      final res =
          await AssistantToolsExecutor().execute('send_room_chat', {'text': ''});

      expect(res.toLowerCase(), contains('empty'));
      verifyZeroInteractions(client);
    });

    test('whitespace-only text counts as empty', () async {
      enterCall('room-1');

      final res = await AssistantToolsExecutor()
          .execute('send_room_chat', {'text': '   \n  '});

      expect(res.toLowerCase(), contains('empty'));
      verifyZeroInteractions(client);
    });

    test('missing text argument is refused', () async {
      enterCall('room-1');

      final res =
          await AssistantToolsExecutor().execute('send_room_chat', const {});

      expect(res.toLowerCase(), contains('empty'));
      verifyZeroInteractions(client);
    });

    test('non-string text does not throw and is refused', () async {
      // The model can and does send a number where a string is declared. A
      // plain `args['text'] as String?` would throw TypeError, the executor's
      // outer catch would turn it into {"error":"type 'int' is not a subtype
      // …"} and the assistant would tell the user something went wrong. Same
      // reasoning as RoomChatController.handlePacket.
      enterCall('room-1');

      final res =
          await AssistantToolsExecutor().execute('send_room_chat', {'text': 42});

      expect(res.toLowerCase(), contains('empty'));
      expect(res.toLowerCase(), isNot(contains('subtype')));
      verifyZeroInteractions(client);
    });

    test('text over the 500-char room-chat limit is refused, not truncated',
        () async {
      enterCall('room-1');

      final res = await AssistantToolsExecutor()
          .execute('send_room_chat', {'text': 'а' * 501});

      expect(res.toLowerCase(), contains('too long'));
      verifyZeroInteractions(client);
    });
  });

  group('send_room_chat — sending', () {
    test('posts the trimmed text to the active room and returns the response',
        () async {
      enterCall('room-42');
      stubChatPost('room-42', {'ok': true});

      final res = await AssistantToolsExecutor()
          .execute('send_room_chat', {'text': '  встречаемся в 18:00  '});

      final captured = verify(() => client.post<Map<String, dynamic>>(
            '/voice/rooms/room-42/chat',
            data: captureAny(named: 'data'),
            fromJson: any(named: 'fromJson'),
          )).captured.single as Map<String, dynamic>;

      expect(captured['text'], 'встречаемся в 18:00');
      expect(res, contains('"ok":true'));
    });

    test('labels the message as coming from the assistant, not from the user',
        () async {
      // Without an explicit name the backend stamps a neutral "Taler ID",
      // which reads as a system notice; with the user's own name it would
      // read as if the user typed it themselves. Neither is honest.
      enterCall('room-42');
      stubChatPost('room-42', {'ok': true});

      await AssistantToolsExecutor()
          .execute('send_room_chat', {'text': 'привет'});

      final captured = verify(() => client.post<Map<String, dynamic>>(
            '/voice/rooms/room-42/chat',
            data: captureAny(named: 'data'),
            fromJson: any(named: 'fromJson'),
          )).captured.single as Map<String, dynamic>;

      expect(captured['name'], isA<String>());
      expect((captured['name'] as String).isNotEmpty, isTrue);
    });

    test('uses the room the user is currently in after switching lines',
        () async {
      enterCall('room-a');
      enterCall('room-b'); // setRoom makes the new line the active one
      stubChatPost('room-b', {'ok': true});

      await AssistantToolsExecutor()
          .execute('send_room_chat', {'text': 'на второй линии'});

      verify(() => client.post<Map<String, dynamic>>(
            '/voice/rooms/room-b/chat',
            data: any(named: 'data'),
            fromJson: any(named: 'fromJson'),
          )).called(1);
      verifyNever(() => client.post<Map<String, dynamic>>(
            '/voice/rooms/room-a/chat',
            data: any(named: 'data'),
            fromJson: any(named: 'fromJson'),
          ));
    });
  });

  group('send_room_chat — schema', () {
    test('declared once, with only `text` required', () {
      final tools = assistantToolSchemas(translatorMode: false);
      final matches = tools.where((t) => t['name'] == 'send_room_chat');
      expect(matches, hasLength(1));

      final tool = matches.single;
      expect(tool['type'], 'function');
      expect((tool['description'] as String).isNotEmpty, isTrue);

      final params = tool['parameters'] as Map<String, dynamic>;
      final props = params['properties'] as Map<String, dynamic>;
      expect(props.keys, ['text']);
      expect(params['required'], ['text']);
    });

    test('the model cannot choose the sender name', () {
      final tool = assistantToolSchemas(translatorMode: false)
          .singleWhere((t) => t['name'] == 'send_room_chat');
      final props = (tool['parameters'] as Map<String, dynamic>)['properties']
          as Map<String, dynamic>;
      expect(props.containsKey('name'), isFalse);
    });

    test('carried through to the text-chat (completions) tool list', () {
      final names = assistantToolSchemasForCompletions()
          .map((t) => (t['function'] as Map<String, dynamic>)['name'])
          .toSet();
      expect(names, contains('send_room_chat'));
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:livekit_client/livekit_client.dart' as lk;
import 'package:mocktail/mocktail.dart';
import 'package:taler_id_mobile/core/api/dio_client.dart';
import 'package:taler_id_mobile/core/di/service_locator.dart';
import 'package:taler_id_mobile/core/services/call_state_service.dart';
import 'package:taler_id_mobile/features/assistant/tools/assistant_tools_executor.dart';
import 'package:taler_id_mobile/features/assistant/tools/assistant_tools_schema.dart';
import 'package:taler_id_mobile/features/voice/data/room_chat_api.dart';

class _MockDioClient extends Mock implements DioClient {}

class _MockRoomChatApi extends Mock implements RoomChatApi {}

/// Same shape as MockRoom in test/core/call_state_service_test.dart — the
/// executor never touches the room itself, only the room *name*/*token* that
/// CallStateService derives from it, so a bare mock is enough.
class _MockRoom extends Mock implements lk.Room {}

void main() {
  late _MockDioClient client;
  late _MockRoomChatApi roomChatApi;
  late CallStateService callState;

  setUp(() async {
    await sl.reset();
    client = _MockDioClient();
    roomChatApi = _MockRoomChatApi();
    sl.registerLazySingleton<DioClient>(() => client);
    sl.registerLazySingleton<RoomChatApi>(() => roomChatApi);

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

  /// Puts the singleton into "user is in a call in [roomName], with a
  /// room-scoped LiveKit token already set" — the normal, healthy state by
  /// the time the assistant can be asked to write anything (see
  /// CallLine.lkToken's doc: it's set in the same `setRoom` call as
  /// roomName, except for the background-connect race covered by
  /// [enterCallWithoutToken] below).
  void enterCall(String roomName, {String? lkToken}) {
    final room = _MockRoom();
    when(() => room.disconnect()).thenAnswer((_) async {});
    callState.setRoom(room, roomName, 'conv-1',
        lkToken: lkToken ?? 'lk-token-$roomName');
  }

  /// Puts the singleton into "in a call, but the room-scoped token hasn't
  /// landed yet" — e.g. a call answered from the background while
  /// `connectInBackground`'s join request is still in flight.
  void enterCallWithoutToken(String roomName) {
    final room = _MockRoom();
    when(() => room.disconnect()).thenAnswer((_) async {});
    callState.setRoom(room, roomName, 'conv-1');
  }

  void stubRoomChatSend(String roomName,
      {String msgId = 'srv-1', int seq = 1}) {
    when(() => roomChatApi.sendMessage(
          roomName: roomName,
          lkToken: any(named: 'lkToken'),
          text: any(named: 'text'),
          name: any(named: 'name'),
          clientMsgId: any(named: 'clientMsgId'),
        )).thenAnswer((_) async => RoomChatSendResult(
          msgId: msgId,
          seq: seq,
          sentAt: DateTime(2026, 1, 1),
        ));
  }

  group('send_room_chat — refusals never hit the network', () {
    test('outside a call there is no room to write to', () async {
      expect(callState.roomName, isNull, reason: 'precondition: not in a call');

      final res = await AssistantToolsExecutor()
          .execute('send_room_chat', {'text': 'привет всем'});

      // Readable for the model, not a JSON error blob.
      expect(res.toLowerCase(), contains('no active call'));
      verifyZeroInteractions(client);
      verifyZeroInteractions(roomChatApi);
    });

    test('call is active but the room-scoped token has not landed yet',
        () async {
      enterCallWithoutToken('room-1');

      final res = await AssistantToolsExecutor()
          .execute('send_room_chat', {'text': 'привет всем'});

      expect(res.toLowerCase(), contains('not ready'));
      verifyZeroInteractions(client);
      verifyZeroInteractions(roomChatApi);
    });

    test('empty text is refused while in a call', () async {
      enterCall('room-1');

      final res =
          await AssistantToolsExecutor().execute('send_room_chat', {'text': ''});

      expect(res.toLowerCase(), contains('empty'));
      verifyZeroInteractions(client);
      verifyZeroInteractions(roomChatApi);
    });

    test('whitespace-only text counts as empty', () async {
      enterCall('room-1');

      final res = await AssistantToolsExecutor()
          .execute('send_room_chat', {'text': '   \n  '});

      expect(res.toLowerCase(), contains('empty'));
      verifyZeroInteractions(client);
      verifyZeroInteractions(roomChatApi);
    });

    test('missing text argument is refused', () async {
      enterCall('room-1');

      final res =
          await AssistantToolsExecutor().execute('send_room_chat', const {});

      expect(res.toLowerCase(), contains('empty'));
      verifyZeroInteractions(client);
      verifyZeroInteractions(roomChatApi);
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
      verifyZeroInteractions(roomChatApi);
    });

    test('text over the 500-char room-chat limit is refused, not truncated',
        () async {
      enterCall('room-1');

      final res = await AssistantToolsExecutor()
          .execute('send_room_chat', {'text': 'а' * 501});

      expect(res.toLowerCase(), contains('too long'));
      verifyZeroInteractions(client);
      verifyZeroInteractions(roomChatApi);
    });
  });

  group('send_room_chat — sending', () {
    test(
        'sends through the room-scoped LiveKit token, never the Taler ID client',
        () async {
      // This is the test that pins the whole reason for the fix: the old
      // code went through DioClient, whose AuthInterceptor stamps the Taler
      // ID access token — and RoomAccessGuard on the backend rejects that
      // token for a guest in someone else's temporary room (403). The
      // room-scoped LiveKit token set on CallStateService is the only one
      // that endpoint accepts from a guest.
      enterCall('room-42', lkToken: 'lk-room-scoped-secret');
      stubRoomChatSend('room-42');

      await AssistantToolsExecutor()
          .execute('send_room_chat', {'text': 'встречаемся в 18:00'});

      final capturedToken = verify(() => roomChatApi.sendMessage(
            roomName: 'room-42',
            lkToken: captureAny(named: 'lkToken'),
            text: any(named: 'text'),
            name: any(named: 'name'),
            clientMsgId: any(named: 'clientMsgId'),
          )).captured.single as String;
      expect(capturedToken, 'lk-room-scoped-secret');

      // Never falls back to the Taler-ID-authorizing client for this
      // endpoint — the only way from a unit test to pin "never touches that
      // path" is asserting zero interactions on it.
      verifyZeroInteractions(client);
    });

    test('posts the trimmed text to the active room', () async {
      enterCall('room-42');
      stubRoomChatSend('room-42');

      final res = await AssistantToolsExecutor()
          .execute('send_room_chat', {'text': '  встречаемся в 18:00  '});

      final capturedText = verify(() => roomChatApi.sendMessage(
            roomName: 'room-42',
            lkToken: any(named: 'lkToken'),
            text: captureAny(named: 'text'),
            name: any(named: 'name'),
            clientMsgId: any(named: 'clientMsgId'),
          )).captured.single as String;
      expect(capturedText, 'встречаемся в 18:00');
      expect(res, contains('"ok":true'));
    });

    test('passes a clientMsgId matching the server-required shape', () async {
      // The server builds the final id from this and the client recognizes
      // its own echo by it — see RoomChatApi.sendMessage's doc. Contract:
      // [A-Za-z0-9_-], 1-64 chars.
      enterCall('room-42');
      stubRoomChatSend('room-42');

      await AssistantToolsExecutor()
          .execute('send_room_chat', {'text': 'привет'});

      final capturedId = verify(() => roomChatApi.sendMessage(
            roomName: 'room-42',
            lkToken: any(named: 'lkToken'),
            text: any(named: 'text'),
            name: any(named: 'name'),
            clientMsgId: captureAny(named: 'clientMsgId'),
          )).captured.single as String;

      expect(capturedId, isNotEmpty);
      expect(RegExp(r'^[A-Za-z0-9_-]{1,64}$').hasMatch(capturedId), isTrue,
          reason: 'clientMsgId "$capturedId" must match [A-Za-z0-9_-]{1,64}');
    });

    test('labels the message as coming from the assistant, not from the user',
        () async {
      // Without an explicit name the backend stamps a neutral "Taler ID",
      // which reads as a system notice; with the user's own name it would
      // read as if the user typed it themselves. Neither is honest.
      enterCall('room-42');
      stubRoomChatSend('room-42');

      await AssistantToolsExecutor()
          .execute('send_room_chat', {'text': 'привет'});

      final capturedName = verify(() => roomChatApi.sendMessage(
            roomName: 'room-42',
            lkToken: any(named: 'lkToken'),
            text: any(named: 'text'),
            name: captureAny(named: 'name'),
            clientMsgId: any(named: 'clientMsgId'),
          )).captured.single as String?;

      expect(capturedName, isA<String>());
      expect(capturedName!.isNotEmpty, isTrue);
    });

    test('does not leak msgId/seq from the send result back to the model',
        () async {
      // Narrowing applies to the send confirmation too, not just to
      // read_room_chat's list — a raw {msgId, seq, ts} in the tool output
      // is just as readable-aloud as a chat history entry would be.
      enterCall('room-42');
      stubRoomChatSend('room-42', msgId: 'server-secret-id', seq: 7);

      final res = await AssistantToolsExecutor()
          .execute('send_room_chat', {'text': 'привет'});

      expect(res, isNot(contains('server-secret-id')));
      expect(res, isNot(contains('"seq"')));
      expect(res, isNot(contains('"msgId"')));
    });

    test('uses the room the user is currently in after switching lines',
        () async {
      enterCall('room-a', lkToken: 'lk-a');
      enterCall('room-b', lkToken: 'lk-b'); // setRoom makes the new line the active one
      stubRoomChatSend('room-b');

      await AssistantToolsExecutor()
          .execute('send_room_chat', {'text': 'на второй линии'});

      verify(() => roomChatApi.sendMessage(
            roomName: 'room-b',
            lkToken: 'lk-b',
            text: any(named: 'text'),
            name: any(named: 'name'),
            clientMsgId: any(named: 'clientMsgId'),
          )).called(1);
      verifyNever(() => roomChatApi.sendMessage(
            roomName: 'room-a',
            lkToken: any(named: 'lkToken'),
            text: any(named: 'text'),
            name: any(named: 'name'),
            clientMsgId: any(named: 'clientMsgId'),
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

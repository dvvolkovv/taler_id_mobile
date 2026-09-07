import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:livekit_client/livekit_client.dart' as lk;
import 'package:mocktail/mocktail.dart';
import 'package:taler_id_mobile/core/api/dio_client.dart';
import 'package:taler_id_mobile/core/di/service_locator.dart';
import 'package:taler_id_mobile/core/services/call_state_service.dart';
import 'package:taler_id_mobile/features/assistant/tools/assistant_tools_executor.dart';
import 'package:taler_id_mobile/features/assistant/tools/assistant_tools_schema.dart';
import 'package:taler_id_mobile/features/voice/data/room_chat_api.dart';
import 'package:taler_id_mobile/features/voice/domain/room_chat_history.dart';

class _MockDioClient extends Mock implements DioClient {}

class _MockRoomChatApi extends Mock implements RoomChatApi {}

/// Same shape as _MockRoom in send_room_chat_tool_test.dart — the executor
/// never touches the room itself, only the room *name*/*token* that
/// CallStateService derives from it, so a bare mock is enough.
class _MockRoom extends Mock implements lk.Room {}

RoomChatHistoryMessage _historyMessage(
  String name,
  String text, {
  int seq = 1,
  String msgId = 'srv-msg',
  String? clientMsgId,
}) =>
    RoomChatHistoryMessage(
      msgId: msgId,
      text: text,
      name: name,
      sentAt: DateTime(2026, 1, 1),
      seq: seq,
      own: false,
      clientMsgId: clientMsgId,
    );

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
  /// room-scoped LiveKit token already set" — see the identical helper in
  /// send_room_chat_tool_test.dart for why this is the normal, healthy state.
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

  void stubHistory(
    String roomName,
    List<RoomChatHistoryMessage> messages, {
    int seq = 0,
    bool truncated = false,
  }) {
    when(() => roomChatApi.fetchHistory(
          roomName: roomName,
          lkToken: any(named: 'lkToken'),
          since: any(named: 'since'),
        )).thenAnswer((_) async => RoomChatHistoryPage(
          messages: messages,
          seq: seq,
          truncated: truncated,
        ));
  }

  group('read_room_chat — schema', () {
    test('declared once and requires no parameters', () {
      final tools = assistantToolSchemas(translatorMode: false);
      final matches = tools.where((t) => t['name'] == 'read_room_chat');
      expect(matches, hasLength(1));

      final tool = matches.single;
      expect(tool['type'], 'function');
      expect((tool['description'] as String).isNotEmpty, isTrue);

      final params = tool['parameters'] as Map<String, dynamic>;
      // `{}` with no downward type context infers as Map<dynamic, dynamic>
      // at the declaration site (a well-known Dart literal-inference quirk),
      // so a direct `as Map<String, dynamic>` cast throws here even though
      // the map is genuinely empty — re-key through .from like the rest of
      // this codebase's JSON-shaped-but-uncertain maps (e.g. RoomChatApi's
      // `Map<String, dynamic>.from(response.data as Map)`).
      final props = Map<String, dynamic>.from(params['properties'] as Map);
      expect(props, isEmpty);
      final required = params['required'];
      expect(required == null || (required as List).isEmpty, isTrue);
    });

    test('not present in translator mode', () {
      final names = assistantToolSchemas(translatorMode: true)
          .map((t) => t['name'])
          .toSet();
      expect(names, isNot(contains('read_room_chat')));
    });

    test('carried through to the text-chat (completions) tool list', () {
      final names = assistantToolSchemasForCompletions()
          .map((t) => (t['function'] as Map<String, dynamic>)['name'])
          .toSet();
      expect(names, contains('read_room_chat'));
    });
  });

  group('read_room_chat — refusals never hit the network', () {
    test('outside a call there is no chat to read', () async {
      expect(callState.roomName, isNull, reason: 'precondition: not in a call');

      final res = await AssistantToolsExecutor().execute('read_room_chat', {});

      expect(res.toLowerCase(), contains('no active call'));
      verifyZeroInteractions(client);
      verifyZeroInteractions(roomChatApi);
    });

    test('call is active but the room-scoped token has not landed yet',
        () async {
      enterCallWithoutToken('room-1');

      final res = await AssistantToolsExecutor().execute('read_room_chat', {});

      expect(res.toLowerCase(), contains('not ready'));
      verifyZeroInteractions(client);
      verifyZeroInteractions(roomChatApi);
    });
  });

  group('read_room_chat — reading', () {
    test('returns name and text for each message, never server ids',
        () async {
      enterCall('room-42');
      stubHistory('room-42', [
        _historyMessage('Alice', 'привет', seq: 5, msgId: 'srv-1', clientMsgId: 'client-abc'),
        _historyMessage('Bob', 'как дела', seq: 6, msgId: 'srv-2'),
      ]);

      final res = await AssistantToolsExecutor().execute('read_room_chat', {});
      final decoded = jsonDecode(res) as Map<String, dynamic>;
      final items = decoded['messages'] as List<dynamic>;

      expect(items, [
        {'name': 'Alice', 'text': 'привет'},
        {'name': 'Bob', 'text': 'как дела'},
      ]);
      // Belt-and-suspenders on the raw string too: msgId/seq/clientMsgId
      // must not appear anywhere the model could read them out loud.
      expect(res, isNot(contains('srv-1')));
      expect(res, isNot(contains('srv-2')));
      expect(res, isNot(contains('client-abc')));
      expect(res, isNot(contains('"seq"')));
      expect(res, isNot(contains('"msgId"')));
      expect(res, isNot(contains('"clientMsgId"')));
    });

    test('truncates to the last 20 messages, not the first 20', () async {
      enterCall('room-42');
      // Ascending order (oldest first, newest last) — the same order
      // parseRoomChatHistory preserves from the server and RoomChatController
      // assumes when prepending a full-history fetch (see its `setHistory`
      // doc: a full page is prepended because it's older than anything
      // already live in the feed).
      final messages = List.generate(
        25,
        (i) => _historyMessage('User$i', 'message-$i', seq: i),
      );
      stubHistory('room-42', messages);

      final res = await AssistantToolsExecutor().execute('read_room_chat', {});
      final decoded = jsonDecode(res) as Map<String, dynamic>;
      final items = decoded['messages'] as List<dynamic>;

      expect(items, hasLength(20));
      // Last 20 of 25 are message-5..message-24 — not message-0..message-19.
      expect(items.first['text'], 'message-5');
      expect(items.last['text'], 'message-24');
      expect(items.any((m) => m['text'] == 'message-0'), isFalse);
      expect(items.any((m) => m['text'] == 'message-4'), isFalse);
    });

    test('exactly 20 messages are all returned, none dropped', () async {
      enterCall('room-42');
      final messages = List.generate(
        20,
        (i) => _historyMessage('User$i', 'message-$i', seq: i),
      );
      stubHistory('room-42', messages);

      final res = await AssistantToolsExecutor().execute('read_room_chat', {});
      final decoded = jsonDecode(res) as Map<String, dynamic>;
      final items = decoded['messages'] as List<dynamic>;

      expect(items, hasLength(20));
      expect(items.first['text'], 'message-0');
      expect(items.last['text'], 'message-19');
    });

    test('empty feed gets an explicit answer, not an empty list', () async {
      enterCall('room-42');
      stubHistory('room-42', const []);

      final res = await AssistantToolsExecutor().execute('read_room_chat', {});

      expect(res, isNot(contains('"messages"')));
      final decoded = jsonDecode(res) as Map<String, dynamic>;
      expect(decoded['ok'], isTrue);
      expect((decoded['message'] as String).isNotEmpty, isTrue);
    });

    test('reads the currently active room, using its room-scoped token',
        () async {
      enterCall('room-a', lkToken: 'lk-a');
      enterCall('room-b', lkToken: 'lk-b'); // setRoom makes the new line active
      stubHistory('room-b', [_historyMessage('Alice', 'hi')]);

      await AssistantToolsExecutor().execute('read_room_chat', {});

      verify(() => roomChatApi.fetchHistory(
            roomName: 'room-b',
            lkToken: 'lk-b',
            since: any(named: 'since'),
          )).called(1);
      verifyNever(() => roomChatApi.fetchHistory(
            roomName: 'room-a',
            lkToken: any(named: 'lkToken'),
            since: any(named: 'since'),
          ));
      verifyZeroInteractions(client);
    });
  });
}

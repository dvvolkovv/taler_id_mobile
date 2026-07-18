import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:taler_id_mobile/features/assistant/data/assistant_chat_api.dart';
import 'package:taler_id_mobile/features/assistant/presentation/bloc/assistant_chat_bloc.dart';
import 'package:taler_id_mobile/features/assistant/tools/assistant_tools_executor.dart';
import 'package:taler_id_mobile/features/messenger/domain/entities/message_entity.dart';

class MockApi extends Mock implements AssistantChatApi {}

class MockExecutor extends Mock implements AssistantToolsExecutor {}

MessageEntity msg(String id, String content,
        {String conversationId = 'conv-1'}) =>
    MessageEntity(
      id: id,
      conversationId: conversationId,
      senderId: 'u1',
      content: content,
      sentAt: DateTime(2026, 7, 17),
    );

void main() {
  late MockApi api;
  late MockExecutor executor;
  late StreamController<MessageEntity> socket;

  setUpAll(() {
    registerFallbackValue(<Map<String, dynamic>>[]);
    registerFallbackValue(<String, dynamic>{});
  });

  setUp(() {
    api = MockApi();
    executor = MockExecutor();
    socket = StreamController<MessageEntity>.broadcast();
    when(() => api.getThread()).thenAnswer((_) async => 'conv-1');
  });

  tearDown(() => socket.close());

  AssistantChatBloc build(
          {Future<List<MessageEntity>> Function(String)? history}) =>
      AssistantChatBloc(
        api: api,
        executor: executor,
        messageStream: socket.stream,
        loadHistory: history ?? (_) async => [msg('m1', 'старое')],
        instructions: () => 'sys',
        toolSchemas: () => const [],
      );

  blocTest<AssistantChatBloc, AssistantChatState>(
    'loads thread + history on start',
    build: build,
    act: (b) => b.add(const AssistantChatStarted()),
    wait: const Duration(milliseconds: 10),
    verify: (b) {
      expect(b.state.conversationId, 'conv-1');
      expect(b.state.messages.map((m) => m.id), ['m1']);
      expect(b.state.status, AssistantChatStatus.ready);
    },
  );

  blocTest<AssistantChatBloc, AssistantChatState>(
    'appends socket messages for own thread only, dedupes by id',
    build: build,
    act: (b) async {
      b.add(const AssistantChatStarted());
      await Future<void>.delayed(const Duration(milliseconds: 10));
      socket.add(msg('m2', 'новое'));
      socket.add(msg('m2', 'новое'));
      socket.add(msg('mX', 'чужое', conversationId: 'other'));
      await Future<void>.delayed(const Duration(milliseconds: 10));
    },
    verify: (b) => expect(b.state.messages.map((m) => m.id), ['m1', 'm2']),
  );

  blocTest<AssistantChatBloc, AssistantChatState>(
    'text turn: tool_calls loop then final',
    build: build,
    setUp: () {
      when(() => api.textTurn(
            text: any(named: 'text'),
            instructions: any(named: 'instructions'),
            tools: any(named: 'tools'),
          )).thenAnswer((_) async => const AssistantTurnResult(
            status: AssistantTurnStatus.toolCalls,
            assistantMessage: {'role': 'assistant'},
            toolCalls: [
              {
                'id': 'call_1',
                'function': {'name': 'get_notes', 'arguments': '{}'}
              }
            ],
          ));
      when(() => executor.execute('get_notes', any()))
          .thenAnswer((_) async => '{"notes":[]}');
      when(() => api.textTurn(
            instructions: any(named: 'instructions'),
            tools: any(named: 'tools'),
            pendingAssistantMessage: any(named: 'pendingAssistantMessage'),
            toolResults: any(named: 'toolResults'),
          )).thenAnswer((_) async => const AssistantTurnResult(
            status: AssistantTurnStatus.finalText,
            text: 'Заметок нет',
            messageId: 'a1',
          ));
    },
    act: (b) async {
      b.add(const AssistantChatStarted());
      await Future<void>.delayed(const Duration(milliseconds: 10));
      b.add(const AssistantChatTextSent('покажи заметки'));
    },
    wait: const Duration(milliseconds: 50),
    verify: (b) {
      verify(() => executor.execute('get_notes', any())).called(1);
      expect(b.state.status, AssistantChatStatus.ready);
    },
  );

  blocTest<AssistantChatBloc, AssistantChatState>(
    'turn error -> error status with message kept',
    build: build,
    setUp: () {
      when(() => api.textTurn(
            text: any(named: 'text'),
            instructions: any(named: 'instructions'),
            tools: any(named: 'tools'),
          )).thenThrow(Exception('network down'));
    },
    act: (b) async {
      b.add(const AssistantChatStarted());
      await Future<void>.delayed(const Duration(milliseconds: 10));
      b.add(const AssistantChatTextSent('привет'));
    },
    wait: const Duration(milliseconds: 20),
    verify: (b) {
      expect(b.state.status, AssistantChatStatus.error);
      expect(b.state.messages.map((m) => m.id), ['m1']); // history intact
    },
  );
}

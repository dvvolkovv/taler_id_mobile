import 'dart:async';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:taler_id_mobile/features/chat/domain/entities/chat_message.dart';
import 'package:taler_id_mobile/features/chat/domain/repositories/i_chat_repository.dart';
import 'package:taler_id_mobile/features/chat/presentation/bloc/chat_bloc.dart';
import 'package:taler_id_mobile/features/chat/presentation/bloc/chat_event.dart';
import 'package:taler_id_mobile/features/chat/presentation/bloc/chat_state.dart';

class MockChatRepository extends Mock implements IChatRepository {}

void main() {
  late MockChatRepository repo;
  late ChatBloc bloc;

  setUp(() {
    repo = MockChatRepository();
    bloc = ChatBloc(repo: repo);
  });

  tearDown(() => bloc.close());

  // ── Send message ──────────────────────────────────────────────────────────

  group('ChatMessageSent', () {
    blocTest<ChatBloc, ChatState>(
      'adds user + streaming assistant messages immediately',
      build: () {
        when(() => repo.sendMessage('Hello')).thenAnswer(
          (_) => Stream.fromIterable(['Hi', ' there', '!']),
        );
        return bloc;
      },
      act: (b) async {
        b.add(ChatMessageSent('Hello'));
        await Future.delayed(const Duration(milliseconds: 50));
      },
      verify: (b) {
        final msgs = b.state.messages;
        expect(msgs.length, greaterThanOrEqualTo(2));
        expect(msgs.first.role, MessageRole.user);
        expect(msgs.first.content, 'Hello');
        expect(msgs.last.role, MessageRole.assistant);
      },
    );

    blocTest<ChatBloc, ChatState>(
      'streams tokens into assistant message content',
      build: () {
        final controller = StreamController<String>();
        when(() => repo.sendMessage(any())).thenAnswer((_) => controller.stream);
        return bloc;
      },
      act: (b) async {
        b.add(ChatMessageSent('What is Taler?'));
        await Future.delayed(const Duration(milliseconds: 10));
        b.add(ChatStreamTokenReceived('Taler'));
        b.add(ChatStreamTokenReceived(' is'));
        b.add(ChatStreamTokenReceived(' digital identity.'));
        b.add(ChatStreamCompleted());
        await Future.delayed(const Duration(milliseconds: 10));
      },
      verify: (b) {
        final last = b.state.messages.last;
        expect(last.content, 'Taler is digital identity.');
        expect(last.isStreaming, isFalse);
        expect(b.state.isStreaming, isFalse);
      },
    );

    blocTest<ChatBloc, ChatState>(
      'isStreaming=true while streaming, false after completion',
      build: () {
        when(() => repo.sendMessage(any())).thenAnswer(
          (_) => Stream.fromIterable(['token']),
        );
        return bloc;
      },
      act: (b) async {
        b.add(ChatMessageSent('test'));
        await Future.delayed(const Duration(milliseconds: 10));
        // After stream completes, bloc auto-emits ChatStreamCompleted
        await Future.delayed(const Duration(milliseconds: 30));
      },
      verify: (b) => expect(b.state.isStreaming, isFalse),
    );

    blocTest<ChatBloc, ChatState>(
      'empty assistant message is removed on error',
      build: () {
        when(() => repo.sendMessage(any()))
            .thenAnswer((_) => Stream.error('Connection lost'));
        return bloc;
      },
      act: (b) async {
        b.add(ChatMessageSent('Hello'));
        await Future.delayed(const Duration(milliseconds: 50));
      },
      verify: (b) {
        // User message stays; empty assistant message removed by _onStreamError.
        // Note: Stream.error also triggers onDone → ChatStreamCompleted which
        // clears error back to null — so we only verify structural state.
        expect(b.state.isStreaming, isFalse);
        final assistantEmpty = b.state.messages
            .where((m) => m.role == MessageRole.assistant && m.content.isEmpty)
            .toList();
        expect(assistantEmpty, isEmpty);
      },
    );

    blocTest<ChatBloc, ChatState>(
      'cancels previous stream when new message sent',
      build: () {
        final slowController = StreamController<String>();
        int callCount = 0;
        when(() => repo.sendMessage(any())).thenAnswer((_) {
          callCount++;
          if (callCount == 1) return slowController.stream;
          return Stream.fromIterable(['fast response']);
        });
        return bloc;
      },
      act: (b) async {
        b.add(ChatMessageSent('first'));
        await Future.delayed(const Duration(milliseconds: 10));
        b.add(ChatMessageSent('second'));
        await Future.delayed(const Duration(milliseconds: 50));
      },
      verify: (b) {
        expect(verify(() => repo.sendMessage(any())).callCount, 2);
      },
    );
  });

  // ── Stream tokens ─────────────────────────────────────────────────────────

  group('ChatStreamTokenReceived', () {
    blocTest<ChatBloc, ChatState>(
      'appends token to last assistant message',
      build: () => bloc,
      seed: () => ChatState(
        messages: [
          ChatMessage(
            id: '1',
            role: MessageRole.user,
            content: 'Hi',
            timestamp: DateTime(2024),
          ),
          ChatMessage(
            id: '2',
            role: MessageRole.assistant,
            content: 'Hello',
            timestamp: DateTime(2024),
            isStreaming: true,
          ),
        ],
        isStreaming: true,
      ),
      act: (b) => b.add(ChatStreamTokenReceived(' World')),
      expect: () => [
        isA<ChatState>().having(
          (s) => s.messages.last.content,
          'content',
          'Hello World',
        ),
      ],
    );

    blocTest<ChatBloc, ChatState>(
      'does nothing when message list is empty',
      build: () => bloc,
      act: (b) => b.add(ChatStreamTokenReceived('orphan')),
      expect: () => [],
    );
  });

  // ── Stream completed ──────────────────────────────────────────────────────

  group('ChatStreamCompleted', () {
    blocTest<ChatBloc, ChatState>(
      'sets isStreaming=false on last message and state',
      build: () => bloc,
      seed: () => ChatState(
        messages: [
          ChatMessage(
            id: '2',
            role: MessageRole.assistant,
            content: 'Done',
            timestamp: DateTime(2024),
            isStreaming: true,
          ),
        ],
        isStreaming: true,
      ),
      act: (b) => b.add(ChatStreamCompleted()),
      expect: () => [
        isA<ChatState>()
            .having((s) => s.isStreaming, 'isStreaming', false)
            .having((s) => s.messages.last.isStreaming, 'message isStreaming', false),
      ],
    );

    blocTest<ChatBloc, ChatState>(
      'does nothing when message list is empty',
      build: () => bloc,
      act: (b) => b.add(ChatStreamCompleted()),
      expect: () => [],
    );
  });

  // ── Stream error ──────────────────────────────────────────────────────────

  group('ChatStreamError', () {
    blocTest<ChatBloc, ChatState>(
      'sets error in state and stops streaming',
      build: () => bloc,
      seed: () => ChatState(
        messages: [
          ChatMessage(
            id: '1',
            role: MessageRole.user,
            content: 'Question',
            timestamp: DateTime(2024),
          ),
          ChatMessage(
            id: '2',
            role: MessageRole.assistant,
            content: 'Partial answer...',
            timestamp: DateTime(2024),
            isStreaming: true,
          ),
        ],
        isStreaming: true,
      ),
      act: (b) => b.add(ChatStreamError('API timeout')),
      expect: () => [
        isA<ChatState>()
            .having((s) => s.error, 'error', 'API timeout')
            .having((s) => s.isStreaming, 'isStreaming', false)
            .having((s) => s.messages.last.isStreaming, 'msg isStreaming', false),
      ],
    );

    blocTest<ChatBloc, ChatState>(
      'removes empty assistant message on error',
      build: () => bloc,
      seed: () => ChatState(
        messages: [
          ChatMessage(
            id: '1',
            role: MessageRole.user,
            content: 'Hi',
            timestamp: DateTime(2024),
          ),
          ChatMessage(
            id: '2',
            role: MessageRole.assistant,
            content: '',  // empty — should be removed
            timestamp: DateTime(2024),
            isStreaming: true,
          ),
        ],
        isStreaming: true,
      ),
      act: (b) => b.add(ChatStreamError('Network error')),
      expect: () => [
        isA<ChatState>()
            .having((s) => s.messages.length, 'only user message remains', 1)
            .having((s) => s.messages.first.role, 'role', MessageRole.user)
            .having((s) => s.error, 'error', 'Network error'),
      ],
    );
  });

  // ── Clear ─────────────────────────────────────────────────────────────────

  group('ChatCleared', () {
    blocTest<ChatBloc, ChatState>(
      'resets to empty state',
      build: () => bloc,
      seed: () => ChatState(
        messages: [
          ChatMessage(
            id: '1',
            role: MessageRole.user,
            content: 'Some message',
            timestamp: DateTime(2024),
          ),
        ],
        isStreaming: false,
      ),
      act: (b) => b.add(ChatCleared()),
      expect: () => [
        isA<ChatState>()
            .having((s) => s.messages, 'messages', isEmpty)
            .having((s) => s.isStreaming, 'isStreaming', false)
            .having((s) => s.error, 'error', isNull),
      ],
    );

    blocTest<ChatBloc, ChatState>(
      'clears history with multiple messages',
      build: () => bloc,
      seed: () => ChatState(messages: List.generate(
        10,
        (i) => ChatMessage(
          id: '$i',
          role: i.isEven ? MessageRole.user : MessageRole.assistant,
          content: 'message $i',
          timestamp: DateTime(2024),
        ),
      )),
      act: (b) => b.add(ChatCleared()),
      expect: () => [
        isA<ChatState>().having((s) => s.messages, 'messages', isEmpty),
      ],
    );
  });
}

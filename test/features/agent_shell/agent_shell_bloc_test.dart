import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:taler_id_mobile/core/agent/agent_client.dart';
import 'package:taler_id_mobile/core/agent/models/agent_run_result.dart';
import 'package:taler_id_mobile/features/agent_shell/presentation/bloc/agent_shell_bloc.dart';

class _MockAgentClient extends Mock implements AgentClient {}

void main() {
  late _MockAgentClient agent;

  setUp(() {
    agent = _MockAgentClient();
  });

  blocTest<AgentShellBloc, AgentShellState>(
    'appends user + agent messages on submit',
    build: () {
      when(() => agent.runAgent(
            goal: any(named: 'goal'),
            conversationId: any(named: 'conversationId'),
            model: any(named: 'model'),
          )).thenAnswer(
        (_) async => const AgentRunResult(
          finalText: 'echoed: hi',
          toolCalls: [],
          aborted: false,
        ),
      );
      return AgentShellBloc(client: agent);
    },
    act: (bloc) => bloc.add(const AgentShellSubmit('hi')),
    expect: () => [
      isA<AgentShellState>()
          .having((s) => s.messages.length, 'messages.length', 1)
          .having((s) => s.busy, 'busy', true),
      isA<AgentShellState>()
          .having((s) => s.messages.length, 'messages.length', 2)
          .having((s) => s.busy, 'busy', false)
          .having((s) => s.messages.last.text, 'last.text', 'echoed: hi'),
    ],
  );

  blocTest<AgentShellBloc, AgentShellState>(
    'emits error state when AgentClient throws',
    build: () {
      when(() => agent.runAgent(
            goal: any(named: 'goal'),
            conversationId: any(named: 'conversationId'),
            model: any(named: 'model'),
          )).thenThrow(Exception('boom'));
      return AgentShellBloc(client: agent);
    },
    act: (bloc) => bloc.add(const AgentShellSubmit('hi')),
    expect: () => [
      isA<AgentShellState>().having((s) => s.busy, 'busy', true),
      isA<AgentShellState>()
          .having((s) => s.busy, 'busy', false)
          .having((s) => s.error, 'error', contains('boom')),
    ],
  );
}

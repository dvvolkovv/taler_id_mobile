import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/agent/agent_client.dart';
import 'agent_shell_event.dart';
import 'agent_shell_state.dart';

export 'agent_shell_event.dart';
export 'agent_shell_state.dart';

class AgentShellBloc extends Bloc<AgentShellEvent, AgentShellState> {
  final AgentClient client;
  AgentShellBloc({required this.client}) : super(AgentShellState.initial()) {
    on<AgentShellSubmit>(_onSubmit);
  }

  Future<void> _onSubmit(
      AgentShellSubmit event, Emitter<AgentShellState> emit) async {
    final userMsg = AgentShellMessage(
      role: 'user',
      text: event.text,
      ts: DateTime.now(),
    );
    emit(state.copyWith(
      messages: [...state.messages, userMsg],
      busy: true,
      error: null,
    ));
    try {
      final result = await client.runAgent(
        goal: event.text,
        conversationId: state.conversationId,
      );
      final agentMsg = AgentShellMessage(
        role: 'agent',
        text: result.finalText.isEmpty ? '(empty response)' : result.finalText,
        ts: DateTime.now(),
      );
      emit(state.copyWith(
        messages: [...state.messages, agentMsg],
        busy: false,
        conversationId: result.conversationId,
      ));
    } catch (e) {
      emit(state.copyWith(
        busy: false,
        error: e.toString(),
      ));
    }
  }
}

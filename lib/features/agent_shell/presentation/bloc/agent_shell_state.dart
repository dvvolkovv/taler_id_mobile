import 'package:equatable/equatable.dart';

class AgentShellMessage extends Equatable {
  final String role; // 'user' | 'agent'
  final String text;
  final DateTime ts;
  const AgentShellMessage({
    required this.role,
    required this.text,
    required this.ts,
  });
  @override
  List<Object?> get props => [role, text, ts];
}

class AgentShellState extends Equatable {
  final List<AgentShellMessage> messages;
  final bool busy;
  final String? error;
  final String? conversationId;
  const AgentShellState({
    required this.messages,
    required this.busy,
    this.error,
    this.conversationId,
  });
  factory AgentShellState.initial() =>
      const AgentShellState(messages: [], busy: false);
  AgentShellState copyWith({
    List<AgentShellMessage>? messages,
    bool? busy,
    String? error,
    String? conversationId,
  }) =>
      AgentShellState(
        messages: messages ?? this.messages,
        busy: busy ?? this.busy,
        error: error,
        conversationId: conversationId ?? this.conversationId,
      );
  @override
  List<Object?> get props => [messages, busy, error, conversationId];
}

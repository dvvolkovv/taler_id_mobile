import 'package:equatable/equatable.dart';

abstract class AgentShellEvent extends Equatable {
  const AgentShellEvent();
  @override
  List<Object?> get props => const [];
}

class AgentShellSubmit extends AgentShellEvent {
  final String text;
  const AgentShellSubmit(this.text);
  @override
  List<Object?> get props => [text];
}

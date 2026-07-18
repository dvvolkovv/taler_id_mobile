import 'dart:async';
import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../messenger/domain/entities/message_entity.dart';
import '../../data/assistant_chat_api.dart';
import '../../tools/assistant_tools_executor.dart';

enum AssistantChatStatus { initial, loading, ready, sending, error }

class AssistantChatState extends Equatable {
  const AssistantChatState({
    this.status = AssistantChatStatus.initial,
    this.conversationId,
    this.messages = const [],
    this.error,
  });

  final AssistantChatStatus status;
  final String? conversationId;

  /// Chronological (oldest first).
  final List<MessageEntity> messages;
  final String? error;

  AssistantChatState copyWith({
    AssistantChatStatus? status,
    String? conversationId,
    List<MessageEntity>? messages,
    String? error,
  }) =>
      AssistantChatState(
        status: status ?? this.status,
        conversationId: conversationId ?? this.conversationId,
        messages: messages ?? this.messages,
        error: error,
      );

  @override
  List<Object?> get props => [status, conversationId, messages, error];
}

sealed class AssistantChatEvent extends Equatable {
  const AssistantChatEvent();

  @override
  List<Object?> get props => [];
}

class AssistantChatStarted extends AssistantChatEvent {
  const AssistantChatStarted();
}

class AssistantChatTextSent extends AssistantChatEvent {
  const AssistantChatTextSent(this.text);
  final String text;

  @override
  List<Object?> get props => [text];
}

class _SocketMessage extends AssistantChatEvent {
  const _SocketMessage(this.message);
  final MessageEntity message;

  @override
  List<Object?> get props => [message];
}

/// Text-mode assistant chat: loads the assistant thread + history, merges
/// persisted messages arriving over the messenger socket (deduped by id,
/// filtered to the assistant conversation) and drives the text turn loop
/// (LLM → tool_calls → executor → LLM … → final text).
class AssistantChatBloc extends Bloc<AssistantChatEvent, AssistantChatState> {
  AssistantChatBloc({
    required AssistantChatApi api,
    required AssistantToolsExecutor executor,
    required Stream<MessageEntity> messageStream,
    required Future<List<MessageEntity>> Function(String conversationId)
        loadHistory,
    required String Function() instructions,
    required List<Map<String, dynamic>> Function() toolSchemas,
  })  : _api = api,
        _executor = executor,
        _loadHistory = loadHistory,
        _instructions = instructions,
        _toolSchemas = toolSchemas,
        super(const AssistantChatState()) {
    on<AssistantChatStarted>(_onStarted);
    on<AssistantChatTextSent>(_onTextSent);
    on<_SocketMessage>(_onSocket);
    _sub = messageStream.listen((m) => add(_SocketMessage(m)));
  }

  static const _maxToolIterations = 6;

  final AssistantChatApi _api;
  final AssistantToolsExecutor _executor;
  final Future<List<MessageEntity>> Function(String conversationId)
      _loadHistory;
  final String Function() _instructions;
  final List<Map<String, dynamic>> Function() _toolSchemas;
  late final StreamSubscription<MessageEntity> _sub;

  Future<void> _onStarted(
      AssistantChatStarted e, Emitter<AssistantChatState> emit) async {
    emit(state.copyWith(status: AssistantChatStatus.loading));
    try {
      final convId = await _api.getThread();
      final history = await _loadHistory(convId);
      emit(state.copyWith(
        status: AssistantChatStatus.ready,
        conversationId: convId,
        messages: history,
      ));
    } catch (err) {
      emit(state.copyWith(
          status: AssistantChatStatus.error, error: err.toString()));
    }
  }

  void _onSocket(_SocketMessage e, Emitter<AssistantChatState> emit) {
    if (e.message.conversationId != state.conversationId) return;
    if (state.messages.any((m) => m.id == e.message.id)) return;
    emit(state.copyWith(messages: [...state.messages, e.message]));
  }

  Future<void> _onTextSent(
      AssistantChatTextSent e, Emitter<AssistantChatState> emit) async {
    // Default bloc transformer is concurrent — drop sends while a turn runs.
    if (state.status == AssistantChatStatus.sending) return;
    emit(state.copyWith(status: AssistantChatStatus.sending));
    try {
      var result = await _api.textTurn(
        text: e.text,
        instructions: _instructions(),
        tools: _toolSchemas(),
      );
      var iterations = 0;
      while (result.status == AssistantTurnStatus.toolCalls &&
          iterations < _maxToolIterations) {
        iterations++;
        final toolResults = <Map<String, dynamic>>[];
        for (final call in result.toolCalls ?? const <Map<String, dynamic>>[]) {
          final fn = (call['function'] as Map).cast<String, dynamic>();
          final args = _parseArgs(fn['arguments']);
          String output;
          try {
            output = await _executor.execute(fn['name'] as String, args);
          } catch (err) {
            output = 'Tool error: $err';
          }
          toolResults.add({'tool_call_id': call['id'], 'output': output});
        }
        result = await _api.textTurn(
          instructions: _instructions(),
          tools: _toolSchemas(),
          pendingAssistantMessage: result.assistantMessage,
          toolResults: toolResults,
        );
      }
      if (result.status == AssistantTurnStatus.toolCalls) {
        // Loop cap hit — nothing was persisted server-side; surface it.
        emit(state.copyWith(
            status: AssistantChatStatus.error,
            error: 'tool_loop_limit'));
        return;
      }
      // Persisted messages arrive via socket new_message (deduped in _onSocket).
      emit(state.copyWith(status: AssistantChatStatus.ready));
    } catch (err) {
      emit(state.copyWith(
          status: AssistantChatStatus.error, error: err.toString()));
    }
  }

  Map<String, dynamic> _parseArgs(dynamic raw) {
    if (raw is Map) return raw.cast<String, dynamic>();
    if (raw is String && raw.isNotEmpty) {
      try {
        return (jsonDecode(raw) as Map).cast<String, dynamic>();
      } catch (_) {}
    }
    return const {};
  }

  @override
  Future<void> close() {
    _sub.cancel();
    return super.close();
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import '../bloc/agent_shell_bloc.dart';
import '../../../../core/agent/agent_client.dart';

class AgentShellHomeScreen extends StatelessWidget {
  const AgentShellHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AgentShellBloc(client: GetIt.I<AgentClient>()),
      child: const _AgentShellScaffold(),
    );
  }
}

class _AgentShellScaffold extends StatefulWidget {
  const _AgentShellScaffold();
  @override
  State<_AgentShellScaffold> createState() => _AgentShellScaffoldState();
}

class _AgentShellScaffoldState extends State<_AgentShellScaffold> {
  final TextEditingController _input = TextEditingController();

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  void _submit(BuildContext context) {
    final text = _input.text.trim();
    if (text.isEmpty) return;
    context.read<AgentShellBloc>().add(AgentShellSubmit(text));
    _input.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Taler ID Agent (Phase 0 spike)')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: BlocBuilder<AgentShellBloc, AgentShellState>(
                builder: (context, state) {
                  if (state.messages.isEmpty) {
                    return const Center(
                      child: Text(
                        'Скажи что-нибудь — попробует echo инструмент.',
                        textAlign: TextAlign.center,
                      ),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: state.messages.length + (state.busy ? 1 : 0),
                    itemBuilder: (_, i) {
                      if (i >= state.messages.length) {
                        return const Padding(
                          padding: EdgeInsets.all(12),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text('Думаю…'),
                          ),
                        );
                      }
                      final msg = state.messages[i];
                      final isUser = msg.role == 'user';
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Align(
                          alignment: isUser
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
                            constraints: const BoxConstraints(maxWidth: 320),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: isUser
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context)
                                      .colorScheme
                                      .surfaceContainerHigh,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Text(msg.text),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            BlocBuilder<AgentShellBloc, AgentShellState>(
              builder: (context, state) => Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _input,
                        enabled: !state.busy,
                        decoration: const InputDecoration(
                          hintText: 'Echo this...',
                          border: OutlineInputBorder(),
                        ),
                        onSubmitted: (_) => _submit(context),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      onPressed: state.busy ? null : () => _submit(context),
                      icon: const Icon(Icons.send),
                    ),
                  ],
                ),
              ),
            ),
            BlocBuilder<AgentShellBloc, AgentShellState>(
              builder: (_, s) => s.error != null
                  ? Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text(
                        s.error!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

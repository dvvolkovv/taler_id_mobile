import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taler_id_mobile/l10n/app_localizations.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/widgets.dart';
import '../bloc/chat_bloc.dart';
import '../bloc/chat_event.dart';
import '../bloc/chat_state.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/chat_input.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<ChatBloc>(),
      child: const _ChatView(),
    );
  }
}

class _ChatView extends StatefulWidget {
  const _ChatView();

  @override
  State<_ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<_ChatView> {
  final _scrollController = ScrollController();

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.of(context).background,
      appBar: AppBar(
        title: Text(l10n.chatTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: l10n.chatClear,
            onPressed: () => context.read<ChatBloc>().add(ChatCleared()),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: BlocConsumer<ChatBloc, ChatState>(
              listener: (context, state) {
                _scrollToBottom();
                if (state.error != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(l10n.chatError),
                      backgroundColor: AppColors.of(context).error,
                    ),
                  );
                }
              },
              builder: (context, state) {
                if (state.messages.isEmpty) {
                  return EmptyStateView(
                    icon: Icons.smart_toy_rounded,
                    title: l10n.chatEmpty,
                    gradient: const [Color(0xFF22D3EE), Color(0xFFA855F7)],
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: state.messages.length,
                  itemBuilder: (_, i) => ChatBubble(message: state.messages[i]),
                );
              },
            ),
          ),
          BlocBuilder<ChatBloc, ChatState>(
            buildWhen: (prev, curr) => prev.isStreaming != curr.isStreaming,
            builder: (context, state) {
              return ChatInput(
                enabled: !state.isStreaming,
                onSend: (text) {
                  context.read<ChatBloc>().add(ChatMessageSent(text));
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

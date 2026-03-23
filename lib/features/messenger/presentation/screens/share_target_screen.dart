import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/share_intent_service.dart';
import '../bloc/messenger_bloc.dart';
import '../bloc/messenger_event.dart';
import '../bloc/messenger_state.dart';
import '../../domain/entities/conversation_entity.dart';

/// Screen shown when user shares files to Taler ID from another app.
/// Displays a list of conversations to choose where to send the files.
class ShareTargetScreen extends StatefulWidget {
  final List<SharedMediaFile> sharedFiles;
  const ShareTargetScreen({super.key, required this.sharedFiles});

  @override
  State<ShareTargetScreen> createState() => _ShareTargetScreenState();
}

class _ShareTargetScreenState extends State<ShareTargetScreen> {
  @override
  void initState() {
    super.initState();
    context.read<MessengerBloc>().add(LoadConversations());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.of(context).background,
      appBar: AppBar(
        title: const Text('Переслать в чат'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            ShareIntentService.instance.clearFiles();
            context.pop();
          },
        ),
      ),
      body: Column(
        children: [
          // Preview of shared files
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.of(context).card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.of(context).border),
            ),
            child: Row(
              children: [
                _buildPreview(),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _getDescription(),
                    style: TextStyle(
                      color: AppColors.of(context).textSecondary,
                      fontSize: 13,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Text(
              'Выберите чат',
              style: TextStyle(
                color: AppColors.of(context).textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: BlocBuilder<MessengerBloc, MessengerState>(
              builder: (context, state) {
                final conversations = state.conversations
                    .where((c) => c.type != 'SYSTEM')
                    .toList();
                if (conversations.isEmpty) {
                  return Center(
                    child: Text(
                      'Нет чатов',
                      style: TextStyle(color: AppColors.of(context).textSecondary),
                    ),
                  );
                }
                return ListView.builder(
                  itemCount: conversations.length,
                  itemBuilder: (context, index) {
                    final conv = conversations[index];
                    return _ConversationTile(
                      conversation: conv,
                      onTap: () => _sendToConversation(conv),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreview() {
    final file = widget.sharedFiles.first;
    final path = file.path;

    if (file.type == SharedMediaType.image && path.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.file(
          File(path),
          width: 48,
          height: 48,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _fileIcon(),
        ),
      );
    }
    if (file.type == SharedMediaType.video) {
      return Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.of(context).primary.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(Icons.videocam, color: AppColors.of(context).primary),
      );
    }
    return _fileIcon();
  }

  Widget _fileIcon() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.of(context).primary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(Icons.attach_file, color: AppColors.of(context).primary),
    );
  }

  String _getDescription() {
    final count = widget.sharedFiles.length;
    if (count == 1) {
      final file = widget.sharedFiles.first;
      final name = file.path.split('/').last;
      return name;
    }
    return '$count файлов';
  }

  void _sendToConversation(ConversationEntity conv) {
    // Navigate to chat and send files
    ShareIntentService.instance.clearFiles();
    context.pushReplacement('/dashboard/messenger/${conv.id}', extra: {
      'sharedFiles': widget.sharedFiles,
    });
  }
}

class _ConversationTile extends StatelessWidget {
  final ConversationEntity conversation;
  final VoidCallback onTap;

  const _ConversationTile({required this.conversation, required this.onTap});

  String get displayName {
    if (conversation.type == 'GROUP') {
      return conversation.name ?? 'Группа';
    }
    return conversation.otherUserName ?? 'Чат';
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: AppColors.of(context).primary,
        child: Text(
          displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      title: Text(
        displayName,
        style: TextStyle(
          color: AppColors.of(context).textPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: conversation.lastMessageContent != null
          ? Text(
              conversation.lastMessageContent!,
              style: TextStyle(
                color: AppColors.of(context).textSecondary,
                fontSize: 13,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )
          : null,
      trailing: Icon(
        Icons.send,
        color: AppColors.of(context).primary,
        size: 20,
      ),
      onTap: onTap,
    );
  }
}

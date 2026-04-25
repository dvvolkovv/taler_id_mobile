import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/api/dio_client.dart';
import '../../../../core/di/service_locator.dart';
import '../../../voice/presentation/widgets/pulsing_avatar.dart' show rainbowColorFor;
import '../../../../l10n/app_localizations.dart';
import '../../../../core/services/share_intent_service.dart';
import '../bloc/messenger_bloc.dart';
import '../bloc/messenger_event.dart';
import '../bloc/messenger_state.dart';
import '../../domain/entities/conversation_entity.dart';
import '../../utils/recipient_filters.dart';

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
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.of(context).background,
      appBar: AppBar(
        title: Text(l10n.shareToChat),
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
              l10n.shareSelectChat,
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
                final conversations = filterRecipients(state.conversations);
                if (conversations.isEmpty) {
                  return Center(
                    child: Text(
                      l10n.shareNoChats,
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
    return AppLocalizations.of(context)!.shareFilesCount(count);
  }

  Future<void> _sendToConversation(ConversationEntity conv) async {
    // If group with topics — show topic picker
    if (conv.topicsEnabled) {
      _showTopicPicker(conv);
      return;
    }
    _navigateToChat(conv.id);
  }

  Future<void> _showTopicPicker(ConversationEntity conv) async {
    setState(() {}); // show loading state if needed
    try {
      final client = sl<DioClient>();
      final topics = await client.get<List<dynamic>>(
        '/messenger/conversations/${conv.id}/topics',
        fromJson: (d) => d as List<dynamic>,
      );
      if (!mounted) return;

      final topicList = topics
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();

      if (topicList.isEmpty) {
        // No topics — send to general
        _navigateToChat(conv.id);
        return;
      }

      // Show bottom sheet with topics
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (ctx) => Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.of(context).card,
            borderRadius: BorderRadius.circular(20),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                Container(width: 36, height: 4, decoration: BoxDecoration(color: AppColors.of(context).textSecondary.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(2))),
                const SizedBox(height: 16),
                Text(AppLocalizations.of(context)!.shareSelectChat, style: TextStyle(color: AppColors.of(context).textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                ...topicList.map((t) {
                  final icon = t['icon'] as String? ?? '💬';
                  final title = t['title'] as String? ?? '';
                  final id = t['id'] as String? ?? '';
                  return ListTile(
                    leading: Text(icon, style: const TextStyle(fontSize: 24)),
                    title: Text(title, style: TextStyle(color: AppColors.of(context).textPrimary, fontWeight: FontWeight.w600)),
                    trailing: Icon(Icons.send_rounded, color: AppColors.of(context).primary, size: 20),
                    onTap: () {
                      Navigator.pop(ctx);
                      _navigateToChat(conv.id, topicId: id, topicTitle: title);
                    },
                  );
                }),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      );
    } catch (_) {
      // Fallback — send without topic
      _navigateToChat(conv.id);
    }
  }

  void _navigateToChat(String convId, {String? topicId, String? topicTitle}) {
    final files = widget.sharedFiles;
    ShareIntentService.instance.clearFiles();
    Navigator.of(context, rootNavigator: true).pop();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.go('/dashboard/messenger/$convId', extra: {
        'sharedFiles': files,
        if (topicId != null) 'topicId': topicId,
        if (topicTitle != null) 'topicTitle': topicTitle,
      });
    });
  }
}

class _ConversationTile extends StatelessWidget {
  final ConversationEntity conversation;
  final VoidCallback onTap;

  const _ConversationTile({required this.conversation, required this.onTap});

  String displayName(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (conversation.type == 'GROUP') {
      return conversation.name ?? l10n.chatGroup;
    }
    return conversation.otherUserName ?? l10n.chatDialog;
  }

  @override
  Widget build(BuildContext context) {
    final name = displayName(context);
    final ringColor = rainbowColorFor(name.isNotEmpty ? name : conversation.id);
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: ringColor, width: 2),
          boxShadow: [
            BoxShadow(
              color: ringColor.withValues(alpha: 0.35),
              blurRadius: 8,
            ),
          ],
        ),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              center: const Alignment(-0.3, -0.4),
              radius: 1.1,
              colors: [
                Color.lerp(ringColor, Colors.white, 0.28)!,
                ringColor,
                Color.lerp(ringColor, Colors.black, 0.38)!,
              ],
              stops: const [0.0, 0.55, 1.0],
            ),
          ),
          child: Center(
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ),
        ),
      ),
      title: Text(
        name,
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
      trailing: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [AppColors.of(context).primary, AppColors.of(context).primaryDark],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.of(context).primary.withValues(alpha: 0.4),
              blurRadius: 6,
            ),
          ],
        ),
        child: const Icon(Icons.send_rounded, color: Colors.white, size: 16),
      ),
      onTap: onTap,
    );
  }
}

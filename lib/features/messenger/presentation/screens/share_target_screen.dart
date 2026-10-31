import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import '../../../../core/api/dio_client.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/storage/saved_conversation_id_cache.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/constants.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/conversation_entity.dart';
import '../../domain/repositories/i_messenger_repository.dart';
import '../bloc/messenger_bloc.dart';
import '../bloc/messenger_event.dart';
import '../bloc/messenger_state.dart';
import '../widgets/recipient_picker_list.dart';

/// "Send to": where files shared from another app go.
///
/// Opens over the chat list (`/dashboard/messenger/share`), so closing it
/// leaves the user in Messenger. The chosen chat opens with the files waiting
/// in its attachment strip — nothing is sent from here, the comment is
/// written in the chat itself.
class ShareTargetScreen extends StatefulWidget {
  final List<SharedMediaFile> sharedFiles;
  const ShareTargetScreen({super.key, required this.sharedFiles});

  @override
  State<ShareTargetScreen> createState() => _ShareTargetScreenState();
}

class _ShareTargetScreenState extends State<ShareTargetScreen> {
  bool _openingSaved = false;

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
          onPressed: _close,
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
          Expanded(
            child: BlocBuilder<MessengerBloc, MessengerState>(
              // Only what the list shows: the bloc emits for every message,
              // typing indicator and call event.
              buildWhen: (prev, curr) =>
                  prev.conversations != curr.conversations ||
                  prev.isLoading != curr.isLoading,
              builder: (context, state) => RecipientPickerList(
                conversations: state.conversations,
                loading: state.isLoading,
                onSelected: _select,
                onSelectSaved: _openSaved,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _close() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(RouteConstants.messenger);
    }
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

  void _select(ConversationEntity conv) {
    // A group with topics asks for the topic first.
    if (conv.topicsEnabled) {
      _showTopicPicker(conv);
      return;
    }
    _openChat(conv.id);
  }

  /// Favorites the way the chat list opens it: the remembered id, else ask
  /// the server and remember the answer.
  Future<void> _openSaved() async {
    if (_openingSaved) return;
    _openingSaved = true;
    try {
      final cache = sl<SavedConversationIdCache>();
      var convId = await cache.read();
      if (convId == null) {
        convId =
            await sl<IMessengerRepository>().getOrCreateSavedConversation();
        await cache.write(convId);
      }
      if (!mounted) return;
      _openChat(convId);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.savedOpenError)),
      );
    } finally {
      _openingSaved = false;
    }
  }

  Future<void> _showTopicPicker(ConversationEntity conv) async {
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
        _openChat(conv.id);
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
                      _openChat(conv.id, topicId: id, topicTitle: title);
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
      _openChat(conv.id);
    }
  }

  /// The chat replaces the picker and the chat list stays beneath it. The
  /// files land in the chat's attachment strip and go only with Send.
  void _openChat(String convId, {String? topicId, String? topicTitle}) {
    context.go('/dashboard/messenger/$convId', extra: {
      'sharedFiles': widget.sharedFiles,
      if (topicId != null) 'topicId': topicId,
      if (topicTitle != null) 'topicTitle': topicTitle,
    });
  }
}

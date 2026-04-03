import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../bloc/messenger_bloc.dart';
import '../bloc/messenger_event.dart';
import '../bloc/messenger_state.dart';
import '../../domain/entities/message_entity.dart';

class ThreadScreen extends StatefulWidget {
  final MessageEntity parentMessage;
  final String? parentSenderName;
  final String conversationId;

  const ThreadScreen({
    super.key,
    required this.parentMessage,
    required this.conversationId,
    this.parentSenderName,
  });

  @override
  State<ThreadScreen> createState() => _ThreadScreenState();
}

class _ThreadScreenState extends State<ThreadScreen> {
  final _ctrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  @override
  void dispose() {
    _ctrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _sendReply() {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    // Send as a regular reply with thread reference
    final who = widget.parentSenderName ?? '';
    final quoted = widget.parentMessage.content;
    final q = quoted.length > 40 ? '${quoted.substring(0, 40)}...' : quoted;
    final content = '↩ $who: «$q»\n$text';
    context.read<MessengerBloc>().add(SendMessage(widget.conversationId, content));
    _ctrl.clear();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final msg = widget.parentMessage;
    final timeStr = DateFormat('dd.MM.yyyy HH:mm').format(msg.sentAt.toLocal());

    // Find thread replies in current messages
    final allMessages = context.read<MessengerBloc>().state.messages[widget.conversationId] ?? [];
    final threadReplies = allMessages.where((m) =>
      m.threadParentId == msg.id ||
      (m.content.contains('«${msg.content.length > 40 ? msg.content.substring(0, 40) : msg.content}') && m.id != msg.id)
    ).toList()
      ..sort((a, b) => a.sentAt.compareTo(b.sentAt));

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.messengerThread),
        backgroundColor: colors.background,
      ),
      body: Column(
        children: [
          // Parent message
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colors.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colors.primary.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      widget.parentSenderName ?? '',
                      style: TextStyle(color: colors.primary, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    const Spacer(),
                    Text(timeStr, style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                  ],
                ),
                const SizedBox(height: 8),
                if (msg.fileUrl != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        Icon(Icons.attach_file, size: 14, color: colors.textSecondary),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(msg.fileName ?? AppLocalizations.of(context)!.messengerDefaultFile,
                              style: TextStyle(color: colors.textSecondary, fontSize: 13),
                              overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                  ),
                Text(msg.content, style: TextStyle(color: colors.textPrimary, fontSize: 15)),
              ],
            ),
          ),

          // Thread replies
          if (threadReplies.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Icon(Icons.subdirectory_arrow_right_rounded, size: 16, color: colors.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    AppLocalizations.of(context)!.messengerThreadReplyCount(threadReplies.length, threadReplies.length == 1 ? AppLocalizations.of(context)!.messengerThreadReply : AppLocalizations.of(context)!.messengerThreadReplies),
                    style: TextStyle(color: colors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                controller: _scrollCtrl,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: threadReplies.length,
                itemBuilder: (context, index) {
                  final reply = threadReplies[index];
                  final replyTime = DateFormat('HH:mm').format(reply.sentAt.toLocal());
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colors.surface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(reply.senderName ?? '',
                                  style: TextStyle(color: colors.primary, fontSize: 12, fontWeight: FontWeight.w600)),
                              const Spacer(),
                              Text(replyTime, style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(reply.content, style: TextStyle(color: colors.textPrimary, fontSize: 14)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ] else
            Expanded(
              child: Center(
                child: Text(AppLocalizations.of(context)!.messengerNoReplies, style: TextStyle(color: colors.textSecondary)),
              ),
            ),

          // Reply input
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: colors.card,
              border: Border(top: BorderSide(color: colors.border)),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _ctrl,
                      style: TextStyle(color: colors.textPrimary),
                      decoration: InputDecoration(
                        hintText: AppLocalizations.of(context)!.messengerReplyHint,
                        hintStyle: TextStyle(color: colors.textSecondary),
                        border: InputBorder.none,
                      ),
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendReply(),
                    ),
                  ),
                  IconButton(
                    onPressed: _sendReply,
                    icon: Icon(Icons.send_rounded, color: colors.primary),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

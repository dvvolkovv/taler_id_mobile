import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:taler_id_mobile/l10n/app_localizations.dart';

import '../../../messenger/domain/entities/message_entity.dart';
import '../../domain/assistant_action.dart';
import 'assistant_action_bubble.dart';
import 'linkified_text.dart';

/// Single message row of the assistant text chat: assistant messages are
/// left-aligned on a surface-variant bubble, user messages right-aligned on
/// a primary-container bubble. Renders an optional file card and an
/// [AssistantActionBubble] when the message metadata carries an action.
class AssistantChatMessageRow extends StatelessWidget {
  const AssistantChatMessageRow({
    super.key,
    required this.message,
    required this.onActionTap,
  });

  final MessageEntity message;
  final void Function(AssistantAction action) onActionTap;

  bool get _isAssistant =>
      message.metadata?['assistantRole'] == 'assistant' || message.isSystem;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isAssistant = _isAssistant;
    final action = AssistantAction.fromMetadata(message.metadata);
    final bubbleColor =
        isAssistant ? scheme.surfaceContainerHighest : scheme.primaryContainer;
    final textColor =
        isAssistant ? scheme.onSurface : scheme.onPrimaryContainer;

    return Align(
      alignment: isAssistant ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.82,
        ),
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isAssistant ? 4 : 16),
            bottomRight: Radius.circular(isAssistant ? 16 : 4),
          ),
        ),
        child: Column(
          crossAxisAlignment:
              isAssistant ? CrossAxisAlignment.start : CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (message.fileUrl != null) ...[
              AssistantFileCard(
                fileUrl: message.fileUrl!,
                fileName: message.fileName ?? message.content,
                fileSize: message.fileSize,
              ),
              const SizedBox(height: 6),
            ],
            if (isAssistant)
              // Assistant text may carry URLs — render them tappable.
              SelectableText.rich(
                TextSpan(
                  children: linkifiedSpans(
                    message.content,
                    TextStyle(color: textColor, fontSize: 15, height: 1.3),
                    TextStyle(
                      color: scheme.primary,
                      fontSize: 15,
                      height: 1.3,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              )
            else
              SelectableText(
                message.content,
                style: TextStyle(color: textColor, fontSize: 15, height: 1.3),
              ),
            if (action != null) ...[
              const SizedBox(height: 8),
              AssistantActionBubble(action: action, onTap: onActionTap),
            ],
            const SizedBox(height: 2),
            Text(
              DateFormat.Hm().format(message.sentAt.toLocal()),
              style: TextStyle(
                color: textColor.withValues(alpha: 0.55),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Compact tappable file card (icon + name + size). Opening mirrors the
/// messenger document bubble: download to a temp cache dir, then OpenFilex.
class AssistantFileCard extends StatefulWidget {
  const AssistantFileCard({
    super.key,
    required this.fileUrl,
    required this.fileName,
    this.fileSize,
  });

  final String fileUrl;
  final String fileName;
  final int? fileSize;

  @override
  State<AssistantFileCard> createState() => _AssistantFileCardState();
}

class _AssistantFileCardState extends State<AssistantFileCard> {
  bool _downloading = false;

  String get _sizeLabel {
    final size = widget.fileSize;
    if (size == null) return '';
    final kb = size / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(0)} KB';
    return '${(kb / 1024).toStringAsFixed(1)} MB';
  }

  // Same approach as messenger's _DocumentBubble._openFile (private there):
  // reuse the cached temp copy if present, otherwise download then open.
  Future<void> _openFile() async {
    final dir = await getTemporaryDirectory();
    final safeName = widget.fileName.replaceAll(RegExp(r'[^\w\.\-]'), '_');
    final filePath = '${dir.path}/messenger_files/$safeName';
    final file = File(filePath);
    if (await file.exists()) {
      await OpenFilex.open(filePath);
      return;
    }
    setState(() => _downloading = true);
    try {
      await Directory('${dir.path}/messenger_files').create(recursive: true);
      await Dio().download(widget.fileUrl, filePath);
      if (!mounted) return;
      setState(() => _downloading = false);
      await OpenFilex.open(filePath);
    } catch (_) {
      if (!mounted) return;
      setState(() => _downloading = false);
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.chatFileDownloadError),
          action: SnackBarAction(label: l10n.retry, onPressed: _openFile),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: _downloading ? null : _openFile,
      child: Container(
        constraints: const BoxConstraints(minWidth: 160, maxWidth: 240),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: scheme.surface.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: scheme.outline.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _downloading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(Icons.insert_drive_file_rounded,
                    size: 26, color: scheme.primary),
            const SizedBox(width: 10),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.fileName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: scheme.onSurface, fontSize: 13),
                  ),
                  if (_sizeLabel.isNotEmpty)
                    Text(
                      _sizeLabel,
                      style: TextStyle(
                        color: scheme.onSurface.withValues(alpha: 0.6),
                        fontSize: 11,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

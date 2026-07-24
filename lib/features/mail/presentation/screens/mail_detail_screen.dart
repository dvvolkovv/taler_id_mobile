import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:taler_id_mobile/l10n/app_localizations.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/platform/platform_utils.dart';
import '../../../../core/utils/constants.dart';
import '../../domain/entities/mail_entities.dart';
import '../../domain/entities/mail_folder_entity.dart';
import '../../domain/repositories/i_mail_repository.dart';
import '../widgets/mail_folder_utils.dart';

class MailDetailScreen extends StatefulWidget {
  final int uid;
  final String folder;

  const MailDetailScreen({super.key, required this.uid, this.folder = 'INBOX'});

  @override
  State<MailDetailScreen> createState() => _MailDetailScreenState();
}

class _MailDetailScreenState extends State<MailDetailScreen> {
  late final Future<MailMessageEntity> _future =
      sl<IMailRepository>().getMessage(widget.uid, folder: widget.folder);

  Future<void> _openAttachment(MailAttachmentEntity att) async {
    final bytes = await sl<IMailRepository>()
        .downloadAttachment(widget.uid, att.index, folder: widget.folder);
    final dir = await getTemporaryDirectory();
    // C1: sanitize attacker-controlled filename — strip path separators and
    // replace ".." components with "_" to prevent path traversal.
    final rawName = att.filename.split('/').last.split('\\').last;
    final safeName =
        rawName.split('.').map((p) => p == '..' ? '_' : p).join('.');
    final safeNameFinal = safeName.isEmpty ? '_attachment' : safeName;
    final attachDir = Directory('${dir.path}/mail/${widget.uid}');
    await attachDir.create(recursive: true);
    final file = File('${attachDir.path}/$safeNameFinal');
    await file.writeAsBytes(bytes);
    await OpenFilex.open(file.path);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return FutureBuilder<MailMessageEntity>(
      future: _future,
      builder: (context, snap) {
        final msg = snap.data;
        return Scaffold(
          appBar: AppBar(
            title: Text(msg?.subject ?? '',
                maxLines: 1, overflow: TextOverflow.ellipsis),
            actions: msg == null
                ? null
                : [
                    IconButton(
                      icon: const Icon(Icons.reply_outlined),
                      tooltip: l10n.mailReply,
                      onPressed: () => context.push(
                        '${RouteConstants.mail}/compose',
                        extra: {
                          'replyTo': _extractAddress(msg.from),
                          'replySubject': msg.subject.startsWith('Re:')
                              ? msg.subject
                              : 'Re: ${msg.subject}',
                          'replyMessageId': msg.messageId,
                        },
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.drive_file_move_outlined),
                      tooltip: l10n.mailMoveTo,
                      onPressed: () => _moveMessage(l10n),
                    ),
                    IconButton(
                      icon: const Icon(Icons.mark_email_unread_outlined),
                      tooltip: l10n.mailMarkUnread,
                      onPressed: () async {
                        await sl<IMailRepository>()
                            .setSeen(widget.uid, false, folder: widget.folder);
                        if (context.mounted) context.pop();
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      tooltip: l10n.mailDelete,
                      onPressed: () async {
                        await sl<IMailRepository>()
                            .deleteMessage(widget.uid, folder: widget.folder);
                        if (context.mounted) context.pop();
                      },
                    ),
                  ],
          ),
          body: snap.hasError
              ? const Center(child: Icon(Icons.cloud_off_outlined, size: 40))
              : msg == null
                  ? const Center(child: CircularProgressIndicator())
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(msg.from,
                                  style:
                                      Theme.of(context).textTheme.titleSmall),
                              Text('${l10n.mailTo}: ${msg.to}',
                                  style: Theme.of(context).textTheme.bodySmall),
                              Text(
                                  msg.date
                                      .toLocal()
                                      .toString()
                                      .substring(0, 16),
                                  style: Theme.of(context).textTheme.bodySmall),
                            ],
                          ),
                        ),
                        if (msg.attachments.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Wrap(
                              spacing: 8,
                              children: msg.attachments
                                  .map((a) => ActionChip(
                                        avatar: const Icon(Icons.attach_file,
                                            size: 16),
                                        label: Text(a.filename,
                                            overflow: TextOverflow.ellipsis),
                                        onPressed: () => _openAttachment(a),
                                      ))
                                  .toList(),
                            ),
                          ),
                        const Divider(),
                        Expanded(child: _MailBody(msg: msg)),
                      ],
                    ),
        );
      },
    );
  }

  Future<void> _moveMessage(AppLocalizations l10n) async {
    final repo = sl<IMailRepository>();
    final messenger = ScaffoldMessenger.of(context);
    List<MailFolderEntity> folders;
    try {
      folders = await repo.getFolders();
    } catch (_) {
      return;
    }
    folders = folders.where((f) => f.path != widget.folder).toList();
    if (!mounted || folders.isEmpty) return;
    final chosen = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(l10n.mailMoveTo,
                  style: Theme.of(ctx).textTheme.titleMedium),
            ),
            for (final f in folders)
              ListTile(
                leading: Icon(mailFolderIcon(f)),
                title:
                    Text(mailFolderDisplayName(f, AppLocalizations.of(ctx)!)),
                onTap: () => Navigator.of(ctx).pop(f.path),
              ),
          ],
        ),
      ),
    );
    if (chosen == null || !mounted) return;
    try {
      await repo.moveMessage(widget.uid,
          fromFolder: widget.folder, toFolder: chosen);
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(l10n.mailMoved)));
      context.pop();
    } catch (_) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(l10n.error)));
    }
  }

  String _extractAddress(String from) {
    final m = RegExp(r'<([^>]+)>').firstMatch(from);
    return m?.group(1) ?? from.trim();
  }
}

class _MailBody extends StatefulWidget {
  final MailMessageEntity msg;
  const _MailBody({required this.msg});

  @override
  State<_MailBody> createState() => _MailBodyState();
}

class _MailBodyState extends State<_MailBody> {
  WebViewController? _controller;

  @override
  void initState() {
    super.initState();
    final html = widget.msg.html;
    // webview_flutter is not supported on desktop platforms.
    if (!PlatformUtils.instance.isDesktop && html != null && html.isNotEmpty) {
      _controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.disabled)
        ..setBackgroundColor(Colors.white)
        ..setNavigationDelegate(NavigationDelegate(
          onNavigationRequest: (req) => req.url.startsWith('about:')
              ? NavigationDecision.navigate
              : NavigationDecision.prevent,
        ))
        ..loadHtmlString('''
<!DOCTYPE html><html><head>
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta http-equiv="Content-Security-Policy" content="default-src 'none'; style-src 'unsafe-inline'; img-src data:;">
<style>body{background:#ffffff;color:#1a1a1a;font-family:-apple-system,Roboto,sans-serif;margin:16px;word-break:break-word}a{color:#1a73e8}</style>
</head><body>$html</body></html>''');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_controller != null) {
      return WebViewWidget(controller: _controller!);
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: SelectableText(widget.msg.text),
    );
  }
}

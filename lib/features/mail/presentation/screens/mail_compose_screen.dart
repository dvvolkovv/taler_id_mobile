import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:taler_id_mobile/l10n/app_localizations.dart';

import '../../../../core/di/service_locator.dart';
import '../../domain/repositories/i_mail_repository.dart';

class MailComposeScreen extends StatefulWidget {
  final String? replyTo;
  final String? replySubject;
  final String? replyMessageId;

  const MailComposeScreen(
      {super.key, this.replyTo, this.replySubject, this.replyMessageId});

  @override
  State<MailComposeScreen> createState() => _MailComposeScreenState();
}

class _MailComposeScreenState extends State<MailComposeScreen> {
  late final _to = TextEditingController(text: widget.replyTo ?? '');
  late final _subject =
      TextEditingController(text: widget.replySubject ?? '');
  final _body = TextEditingController();
  final List<({String filename, List<int> bytes})> _attachments = [];
  bool _sending = false;

  static const _maxTotalBytes = 10 * 1024 * 1024;

  int get _totalBytes => _attachments.fold(0, (s, a) => s + a.bytes.length);

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(withData: true);
    final file = result?.files.firstOrNull;
    if (file?.bytes == null) return;
    if (_totalBytes + file!.bytes!.length > _maxTotalBytes) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.mailAttachmentsTooLarge)));
      }
      return;
    }
    setState(
        () => _attachments.add((filename: file.name, bytes: file.bytes!)));
  }

  Future<void> _send() async {
    // I2: capture context-derived objects before any await to avoid
    // using a potentially unmounted context after async gaps.
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context)!;
    if (_to.text.trim().isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      await sl<IMailRepository>().sendMessage(
        to: _to.text.trim(),
        subject: _subject.text.trim(),
        text: _body.text,
        inReplyTo: widget.replyMessageId,
        attachments: _attachments
            .map((a) =>
                (filename: a.filename, contentBase64: base64Encode(a.bytes)))
            .toList(),
      );
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(l10n.mailSent)));
      context.pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _sending = false);
      final limit = e.toString().contains('mail_send_daily_limit') ||
          e.toString().contains('429');
      messenger.showSnackBar(SnackBar(
          content:
              Text(limit ? l10n.mailSendLimitReached : l10n.mailSendFailed)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.mailCompose),
        actions: [
          IconButton(
              icon: const Icon(Icons.attach_file), onPressed: _pickFile),
          IconButton(
            icon: _sending
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.send_outlined),
            onPressed: _send,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: TextField(
              controller: _to,
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              decoration: InputDecoration(labelText: l10n.mailTo),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: TextField(
              controller: _subject,
              decoration: InputDecoration(labelText: l10n.mailSubject),
            ),
          ),
          if (_attachments.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(8),
              child: Wrap(
                spacing: 8,
                children: [
                  for (var i = 0; i < _attachments.length; i++)
                    Chip(
                      label: Text(_attachments[i].filename,
                          overflow: TextOverflow.ellipsis),
                      onDeleted: () =>
                          setState(() => _attachments.removeAt(i)),
                    ),
                ],
              ),
            ),
          Expanded(
            child: TextField(
              controller: _body,
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              decoration: InputDecoration(
                  hintText: l10n.mailBody,
                  contentPadding: const EdgeInsets.all(16),
                  border: InputBorder.none),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _to.dispose();
    _subject.dispose();
    _body.dispose();
    super.dispose();
  }
}

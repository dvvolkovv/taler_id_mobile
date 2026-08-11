import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/datasources/messenger_remote_datasource.dart';

/// Блок «как позвать людей»: ссылка-приглашение и публичное имя.
///
/// Один на группы и каналы — правила там одинаковые, и две копии разъехались бы
/// без причины. Показывается только владельцам и админам: остальным менять тут
/// нечего, а сервер всё равно откажет.
class ConversationShareSection extends StatefulWidget {
  final String conversationId;
  final String? publicUsername;
  const ConversationShareSection({
    super.key,
    required this.conversationId,
    this.publicUsername,
  });

  @override
  State<ConversationShareSection> createState() => _ConversationShareSectionState();
}

class _ConversationShareSectionState extends State<ConversationShareSection> {
  List<Map<String, dynamic>> _invites = [];
  late final TextEditingController _handleCtrl;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _handleCtrl = TextEditingController(text: widget.publicUsername ?? '');
    _load();
  }

  @override
  void dispose() {
    _handleCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final list = await sl<MessengerRemoteDataSource>().listInvites(widget.conversationId);
      if (mounted) setState(() => _invites = list);
    } catch (_) {
      // Не критично: блок просто останется без списка ссылок.
    }
  }

  Future<void> _create() async {
    setState(() => _busy = true);
    try {
      await sl<MessengerRemoteDataSource>().createInvite(widget.conversationId);
      await _load();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _revoke(String code) async {
    await sl<MessengerRemoteDataSource>().revokeInvite(code);
    await _load();
  }

  Future<void> _saveHandle() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _busy = true);
    try {
      await sl<MessengerRemoteDataSource>()
          .setPublicUsername(widget.conversationId, _handleCtrl.text.trim());
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.invitePublicNameSaved)));
      }
    } catch (e) {
      if (!mounted) return;
      // 409 — имя занято, 400 — не по правилам. Разные причины, разные ответы:
      // «что-то пошло не так» здесь бесполезно.
      final taken = e.toString().contains('409');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(taken ? l10n.invitePublicNameTaken : l10n.invitePublicNameBad),
      ));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Text(l10n.inviteLinkTitle,
            style: TextStyle(
                color: colors.textPrimary, fontSize: 15, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        for (final inv in _invites)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    (inv['url'] as String?) ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: colors.textSecondary, fontSize: 13),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy_rounded, size: 18),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: inv['url'] as String));
                    ScaffoldMessenger.of(context)
                        .showSnackBar(SnackBar(content: Text(l10n.inviteLinkCopied)));
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.ios_share_rounded, size: 18),
                  onPressed: () => Share.share(inv['url'] as String),
                ),
                IconButton(
                  icon: Icon(Icons.link_off_rounded, size: 18, color: colors.error),
                  tooltip: l10n.inviteLinkRevoke,
                  onPressed: () => _revoke(inv['code'] as String),
                ),
              ],
            ),
          ),
        OutlinedButton.icon(
          onPressed: _busy ? null : _create,
          icon: const Icon(Icons.add_link_rounded, size: 18),
          label: Text(l10n.inviteLinkCreate),
        ),
        const SizedBox(height: 24),
        Text(l10n.invitePublicName,
            style: TextStyle(
                color: colors.textPrimary, fontSize: 15, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _handleCtrl,
                style: TextStyle(color: colors.textPrimary),
                decoration: InputDecoration(
                  prefixText: '@',
                  hintText: l10n.invitePublicNameHint,
                  hintStyle: TextStyle(color: colors.textSecondary),
                  border: const OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: _busy ? null : _saveHandle,
              child: const Icon(Icons.check, size: 18),
            ),
          ],
        ),
      ],
    );
  }
}

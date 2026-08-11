import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/datasources/messenger_remote_datasource.dart';

/// Экран, который открывается по ссылке-приглашению.
///
/// Сначала показывает, куда именно зовут, и только потом предлагает вступить:
/// переход по ссылке из чужого сообщения не должен молча добавлять человека в
/// беседу, о которой он ничего не знает.
class ChatInviteScreen extends StatefulWidget {
  final String code;
  const ChatInviteScreen({super.key, required this.code});

  @override
  State<ChatInviteScreen> createState() => _ChatInviteScreenState();
}

class _ChatInviteScreenState extends State<ChatInviteScreen> {
  Map<String, dynamic>? _preview;
  bool _loading = true;
  bool _joining = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await sl<MessengerRemoteDataSource>().previewInvite(widget.code);
      if (mounted) setState(() { _preview = data; _loading = false; });
    } catch (_) {
      if (mounted) setState(() { _error = 'not_found'; _loading = false; });
    }
  }

  Future<void> _join() async {
    setState(() => _joining = true);
    try {
      final res = await sl<MessengerRemoteDataSource>().joinByInvite(widget.code);
      final convId = res['conversationId'] as String?;
      if (!mounted || convId == null) return;
      context.go('/dashboard/messenger/$convId');
    } catch (_) {
      if (mounted) {
        setState(() { _joining = false; _error = 'failed'; });
        _load(); // перечитать причину: ссылку могли отозвать минуту назад
      }
    }
  }

  String _problemText(AppLocalizations l10n, String? problem) {
    switch (problem) {
      case 'revoked':
        return l10n.inviteRevoked;
      case 'expired':
        return l10n.inviteExpired;
      case 'exhausted':
        return l10n.inviteExhausted;
      default:
        return l10n.inviteNotFound;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final l10n = AppLocalizations.of(context)!;
    final p = _preview;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(title: Text(l10n.inviteJoinTitle), backgroundColor: colors.background),
      body: Center(
        child: _loading
            ? const CircularProgressIndicator()
            : p == null
                ? Text(l10n.inviteNotFound, style: TextStyle(color: colors.textSecondary))
                : Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: colors.primary.withValues(alpha: 0.15),
                          backgroundImage: (p['avatarUrl'] as String?)?.isNotEmpty == true
                              ? NetworkImage(p['avatarUrl'] as String)
                              : null,
                          child: (p['avatarUrl'] as String?)?.isNotEmpty == true
                              ? null
                              : Icon(Icons.groups_rounded, size: 36, color: colors.primary),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          (p['name'] as String?) ?? '',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: colors.textPrimary,
                              fontSize: 20,
                              fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.inviteMembers((p['participantCount'] as int?) ?? 0),
                          style: TextStyle(color: colors.textSecondary, fontSize: 13),
                        ),
                        if ((p['description'] as String?)?.isNotEmpty == true) ...[
                          const SizedBox(height: 12),
                          Text(
                            p['description'] as String,
                            textAlign: TextAlign.center,
                            style: TextStyle(color: colors.textSecondary, fontSize: 14),
                          ),
                        ],
                        const SizedBox(height: 28),
                        if (p['alreadyMember'] == true)
                          FilledButton(
                            onPressed: () =>
                                context.go('/dashboard/messenger/${p['conversationId']}'),
                            child: Text(l10n.inviteOpenChat),
                          )
                        else if (p['usable'] == true)
                          FilledButton(
                            onPressed: _joining ? null : _join,
                            child: _joining
                                ? const SizedBox(
                                    width: 18, height: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2))
                                : Text(l10n.inviteJoinAction),
                          )
                        else
                          Text(
                            _problemText(l10n, p['problem'] as String?),
                            textAlign: TextAlign.center,
                            style: TextStyle(color: colors.error, fontSize: 14),
                          ),
                      ],
                    ),
                  ),
      ),
    );
  }
}

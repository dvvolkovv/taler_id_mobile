import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:taler_id_mobile/l10n/app_localizations.dart';

import '../../../../core/di/service_locator.dart';
import '../../domain/entities/mail_entities.dart';
import '../../domain/repositories/i_mail_repository.dart';

class MailAppPasswordsScreen extends StatefulWidget {
  const MailAppPasswordsScreen({super.key});

  @override
  State<MailAppPasswordsScreen> createState() =>
      _MailAppPasswordsScreenState();
}

class _MailAppPasswordsScreenState extends State<MailAppPasswordsScreen> {
  List<MailAppPasswordEntity> _items = [];
  MailAccountEntity? _account;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final repo = sl<IMailRepository>();
      final account = await repo.getAccount();
      final items = await repo.listAppPasswords();
      if (!mounted) return;
      setState(() {
        _account = account;
        _items = items;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _create() async {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController();
    final label = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.mailAppPasswordCreate),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(hintText: l10n.mailAppPasswordLabel),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () =>
                  Navigator.pop(ctx, controller.text.trim()),
              child: Text(l10n.mailAppPasswordCreate)),
        ],
      ),
    );
    controller.dispose();
    if (label == null || label.isEmpty) return;
    final created = await sl<IMailRepository>().createAppPassword(label);
    await _load();
    if (!mounted || created.password == null) return;
    _showPasswordOnce(created);
  }

  void _showPasswordOnce(MailAppPasswordEntity created) {
    final l10n = AppLocalizations.of(context)!;
    final settings = _account?.clientSettings;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(created.label,
                style: Theme.of(ctx).textTheme.titleMedium,
                textAlign: TextAlign.center),
            const SizedBox(height: 12),
            SelectableText(
              created.password!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 20,
                  letterSpacing: 1.5),
            ),
            const SizedBox(height: 8),
            Text(l10n.mailAppPasswordShownOnce,
                style: Theme.of(ctx).textTheme.bodySmall,
                textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton.icon(
              icon: const Icon(Icons.copy),
              label: Text(l10n.mailAppPasswordCopied),
              onPressed: () {
                Clipboard.setData(
                    ClipboardData(text: created.password!));
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(l10n.mailAppPasswordCopied)));
              },
            ),
            if (settings != null) ...[
              const SizedBox(height: 16),
              Text(l10n.mailClientSettingsTitle,
                  style: Theme.of(ctx).textTheme.titleSmall),
              Text('IMAP: ${settings.host}:${settings.imapPort} (SSL)\n'
                  'SMTP: ${settings.host}:${settings.smtpPort} (SSL)\n'
                  'Login: ${settings.login}'),
            ],
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Future<void> _revoke(MailAppPasswordEntity p) async {
    final l10n = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${l10n.mailAppPasswordRevoke}: ${p.label}?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l10n.mailAppPasswordRevoke)),
        ],
      ),
    );
    if (ok != true) return;
    await sl<IMailRepository>().revokeAppPassword(p.id);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final settings = _account?.clientSettings;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.mailAppPasswords)),
      floatingActionButton: FloatingActionButton(
          onPressed: _create, child: const Icon(Icons.add)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(l10n.mailAppPasswordsHint,
                    style: Theme.of(context).textTheme.bodySmall),
                if (settings != null)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                          '${l10n.mailClientSettingsTitle}\n'
                          'IMAP: ${settings.host}:${settings.imapPort} (SSL)\n'
                          'SMTP: ${settings.host}:${settings.smtpPort} (SSL)\n'
                          'Login: ${settings.login}'),
                    ),
                  ),
                const SizedBox(height: 8),
                ..._items.map((p) => ListTile(
                      leading: const Icon(Icons.key_outlined),
                      title: Text(p.label),
                      subtitle: p.createdAt != null
                          ? Text(p.createdAt!
                              .toLocal()
                              .toString()
                              .substring(0, 16))
                          : null,
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => _revoke(p),
                      ),
                    )),
              ],
            ),
    );
  }
}

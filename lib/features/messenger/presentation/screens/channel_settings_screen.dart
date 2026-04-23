import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/datasources/messenger_remote_datasource.dart';
import '../../domain/entities/channel_details.dart';
import '../bloc/messenger_bloc.dart';
import '../bloc/messenger_event.dart';

class ChannelSettingsScreen extends StatefulWidget {
  const ChannelSettingsScreen({super.key, required this.channelId});
  final String channelId;

  @override
  State<ChannelSettingsScreen> createState() => _ChannelSettingsScreenState();
}

class _ChannelSettingsScreenState extends State<ChannelSettingsScreen> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _ds = sl<MessengerRemoteDataSource>();
  ChannelDetails? _channel;
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final ch = await _ds.getChannelDetails(widget.channelId);
      if (!mounted) return;
      if (ch.myRole != 'OWNER' && ch.myRole != 'ADMIN') {
        context.pop();
        return;
      }
      _nameCtrl.text = ch.name ?? '';
      _descCtrl.text = ch.description ?? '';
      setState(() {
        _channel = ch;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e';
        _loading = false;
      });
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await _ds.updateChannel(
        widget.channelId,
        name: _nameCtrl.text.trim(),
        description: _descCtrl.text.trim(),
      );
      if (!mounted) return;
      context.read<MessengerBloc>().add(LoadConversations());
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$e'),
          backgroundColor: AppColors.of(context).error,
        ),
      );
      setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final l10n = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.channelsDelete),
        content: Text(l10n.channelsDeleteConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              l10n.channelsDelete,
              style: TextStyle(color: AppColors.of(context).error),
            ),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _ds.deleteChannel(widget.channelId);
      if (!mounted) return;
      context.read<MessengerBloc>().add(LoadConversations());
      context.go('/dashboard/messenger');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$e'),
          backgroundColor: AppColors.of(context).error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = AppColors.of(context);
    if (_loading) {
      return Scaffold(
        backgroundColor: colors.background,
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return Scaffold(
        backgroundColor: colors.background,
        appBar: AppBar(
          backgroundColor: colors.background,
          title: Text(
            l10n.channelsSettings,
            style: TextStyle(color: colors.textPrimary),
          ),
          iconTheme: IconThemeData(color: colors.textPrimary),
        ),
        body: Center(
          child: Text(_error!, style: TextStyle(color: colors.error)),
        ),
      );
    }
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        title: Text(
          l10n.channelsSettings,
          style: TextStyle(color: colors.textPrimary),
        ),
        iconTheme: IconThemeData(color: colors.textPrimary),
        actions: [
          IconButton(
            icon: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check),
            onPressed: _saving ? null : _save,
            tooltip: l10n.save,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _nameCtrl,
            maxLength: 64,
            style: TextStyle(color: colors.textPrimary),
            decoration: InputDecoration(
              labelText: l10n.channelsNameLabel,
              labelStyle: TextStyle(color: colors.textSecondary),
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _descCtrl,
            maxLength: 300,
            maxLines: 4,
            style: TextStyle(color: colors.textPrimary),
            decoration: InputDecoration(
              labelText: l10n.channelsDescriptionLabel,
              labelStyle: TextStyle(color: colors.textSecondary),
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 32),
          if (_channel?.myRole == 'OWNER')
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: colors.error,
                side: BorderSide(color: colors.error),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: _delete,
              icon: const Icon(Icons.delete_outline),
              label: Text(l10n.channelsDelete),
            ),
        ],
      ),
    );
  }
}

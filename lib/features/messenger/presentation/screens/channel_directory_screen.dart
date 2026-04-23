import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/datasources/messenger_remote_datasource.dart';
import '../../domain/entities/channel_summary.dart';

class ChannelDirectoryScreen extends StatefulWidget {
  const ChannelDirectoryScreen({super.key});

  @override
  State<ChannelDirectoryScreen> createState() => _ChannelDirectoryScreenState();
}

class _ChannelDirectoryScreenState extends State<ChannelDirectoryScreen> {
  final _searchCtrl = TextEditingController();
  Timer? _debounce;
  List<ChannelSummary> _items = [];
  bool _loading = false;
  String? _error;
  final _ds = sl<MessengerRemoteDataSource>();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await _ds.listChannels(q: _searchCtrl.text.trim());
      if (!mounted) return;
      setState(() { _items = res; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  void _onSearchChanged(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), _load);
  }

  Future<void> _subscribe(ChannelSummary ch) async {
    try {
      await _ds.subscribeToChannel(ch.id);
      if (!mounted) return;
      setState(() {
        _items = _items.map((e) => e.id == ch.id
            ? e.copyWith(isSubscribed: true, subscribersCount: e.subscribersCount + 1)
            : e).toList();
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: $e'), backgroundColor: AppColors.of(context).error),
      );
    }
  }

  void _openChannel(ChannelSummary ch) {
    context.push('/dashboard/messenger/${ch.id}');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = AppColors.of(context);
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        title: Text(l10n.channelsDiscover, style: TextStyle(color: colors.textPrimary)),
        iconTheme: IconThemeData(color: colors.textPrimary),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchCtrl,
              style: TextStyle(color: colors.textPrimary),
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: l10n.channelsSearchHint,
                hintStyle: TextStyle(color: colors.textSecondary),
                prefixIcon: Icon(Icons.search, color: colors.textSecondary),
                filled: true,
                fillColor: colors.card,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _load,
              child: _buildList(l10n, colors),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(AppLocalizations l10n, AppColorsExtension colors) {
    if (_loading && _items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return ListView(children: [
        Padding(
          padding: const EdgeInsets.all(24),
          child: Text(_error!, style: TextStyle(color: colors.error)),
        )
      ]);
    }
    if (_items.isEmpty) {
      return ListView(children: [
        const SizedBox(height: 120),
        Center(child: Icon(Icons.explore_rounded, color: colors.textSecondary, size: 64)),
        const SizedBox(height: 12),
        Center(child: Text(l10n.channelsEmpty, style: TextStyle(color: colors.textSecondary))),
      ]);
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      itemCount: _items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final ch = _items[i];
        return Container(
          decoration: BoxDecoration(
            color: colors.card,
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            onTap: () => _openChannel(ch),
            leading: CircleAvatar(
              backgroundColor: colors.primary.withValues(alpha: 0.2),
              backgroundImage: (ch.avatarUrl != null && ch.avatarUrl!.isNotEmpty)
                  ? CachedNetworkImageProvider(ch.avatarUrl!)
                  : null,
              child: (ch.avatarUrl == null || ch.avatarUrl!.isEmpty)
                  ? Text(
                      (ch.name ?? '?').substring(0, 1).toUpperCase(),
                      style: TextStyle(color: colors.primary, fontWeight: FontWeight.bold),
                    )
                  : null,
            ),
            title: Text(ch.name ?? '—', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (ch.description != null && ch.description!.isNotEmpty)
                  Text(ch.description!, maxLines: 2, overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: colors.textSecondary)),
                const SizedBox(height: 2),
                Text('${ch.subscribersCount} ${l10n.channelsSubscribers}',
                    style: TextStyle(color: colors.textSecondary, fontSize: 12)),
              ],
            ),
            trailing: ch.isSubscribed
                ? OutlinedButton(
                    onPressed: () => _openChannel(ch),
                    child: Text(l10n.channelsOpen),
                  )
                : ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.primary,
                      foregroundColor: Colors.black,
                    ),
                    onPressed: () => _subscribe(ch),
                    child: Text(l10n.channelsSubscribe),
                  ),
          ),
        );
      },
    );
  }
}

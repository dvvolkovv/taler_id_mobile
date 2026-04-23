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
  bool _firstLoad = true;
  String? _error;
  int _reqSeq = 0;
  final _locallySubscribed = <String>{};
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
    final seq = ++_reqSeq;
    setState(() { _loading = true; _error = null; });
    try {
      final res = await _ds.listChannels(q: _searchCtrl.text.trim());
      if (!mounted || seq != _reqSeq) return;
      setState(() {
        _items = res
            .map((c) => _locallySubscribed.contains(c.id)
                ? c.copyWith(isSubscribed: true)
                : c)
            .toList();
        _loading = false;
        _firstLoad = false;
      });
    } catch (e) {
      if (!mounted || seq != _reqSeq) return;
      setState(() {
        _error = e.toString();
        _loading = false;
        _firstLoad = false;
      });
    }
  }

  void _onSearchChanged(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), _load);
  }

  Future<void> _subscribe(ChannelSummary ch) async {
    // Optimistic update first.
    setState(() {
      _locallySubscribed.add(ch.id);
      _items = _items
          .map((e) => e.id == ch.id
              ? e.copyWith(
                  isSubscribed: true,
                  subscribersCount: e.subscribersCount + 1,
                )
              : e)
          .toList();
    });
    try {
      await _ds.subscribeToChannel(ch.id);
    } catch (e) {
      if (!mounted) return;
      // Rollback
      setState(() {
        _locallySubscribed.remove(ch.id);
        _items = _items
            .map((e2) => e2.id == ch.id
                ? e2.copyWith(
                    isSubscribed: false,
                    subscribersCount: (e2.subscribersCount - 1).clamp(0, 1 << 30),
                  )
                : e2)
            .toList();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка: $e'),
          backgroundColor: AppColors.of(context).error,
        ),
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
        bottom: _loading && !_firstLoad
            ? PreferredSize(
                preferredSize: const Size.fromHeight(2),
                child: LinearProgressIndicator(
                  minHeight: 2,
                  backgroundColor: colors.card,
                  valueColor: AlwaysStoppedAnimation(colors.primary),
                ),
              )
            : null,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: TextField(
              controller: _searchCtrl,
              style: TextStyle(color: colors.textPrimary),
              onChanged: _onSearchChanged,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: l10n.channelsSearchHint,
                hintStyle: TextStyle(color: colors.textSecondary),
                prefixIcon: Icon(Icons.search, color: colors.textSecondary),
                suffixIcon: _searchCtrl.text.isEmpty
                    ? null
                    : IconButton(
                        icon: Icon(Icons.close, color: colors.textSecondary),
                        onPressed: () {
                          _searchCtrl.clear();
                          _load();
                          setState(() {});
                        },
                      ),
                filled: true,
                fillColor: colors.card,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
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
    if (_firstLoad && _loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && _items.isEmpty) {
      return ListView(children: [
        const SizedBox(height: 120),
        Center(
          child: Icon(Icons.error_outline, color: colors.error, size: 48),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(_error!, textAlign: TextAlign.center, style: TextStyle(color: colors.textSecondary)),
        ),
      ]);
    }
    if (_items.isEmpty) {
      return ListView(children: [
        const SizedBox(height: 120),
        Center(child: Icon(Icons.explore_rounded, color: colors.textSecondary, size: 64)),
        const SizedBox(height: 12),
        Center(
          child: Text(
            l10n.channelsEmpty,
            style: TextStyle(color: colors.textSecondary),
          ),
        ),
      ]);
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
      itemCount: _items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) => _ChannelCard(
        channel: _items[i],
        subscribersLabel: l10n.channelsSubscribers,
        subscribeLabel: l10n.channelsSubscribe,
        openLabel: l10n.channelsOpen,
        onOpen: () => _openChannel(_items[i]),
        onSubscribe: () => _subscribe(_items[i]),
      ),
    );
  }
}

class _ChannelCard extends StatelessWidget {
  const _ChannelCard({
    required this.channel,
    required this.subscribersLabel,
    required this.subscribeLabel,
    required this.openLabel,
    required this.onOpen,
    required this.onSubscribe,
  });

  final ChannelSummary channel;
  final String subscribersLabel;
  final String subscribeLabel;
  final String openLabel;
  final VoidCallback onOpen;
  final VoidCallback onSubscribe;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Material(
      color: colors.card,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: colors.primary.withValues(alpha: 0.2),
                backgroundImage: (channel.avatarUrl != null && channel.avatarUrl!.isNotEmpty)
                    ? CachedNetworkImageProvider(channel.avatarUrl!)
                    : null,
                child: (channel.avatarUrl == null || channel.avatarUrl!.isEmpty)
                    ? Text(
                        (channel.name ?? '?').isNotEmpty ? channel.name!.substring(0, 1).toUpperCase() : '?',
                        style: TextStyle(color: colors.primary, fontWeight: FontWeight.bold),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      channel.name ?? '—',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    if (channel.description != null && channel.description!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        channel.description!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: colors.textSecondary, fontSize: 13),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      '${channel.subscribersCount} $subscribersLabel',
                      style: TextStyle(color: colors.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              channel.isSubscribed
                  ? OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: colors.textPrimary,
                        side: BorderSide(color: colors.textSecondary.withValues(alpha: 0.3)),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        minimumSize: const Size(0, 36),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: onOpen,
                      child: Text(openLabel),
                    )
                  : ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.primary,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        minimumSize: const Size(0, 36),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: onSubscribe,
                      child: Text(subscribeLabel),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

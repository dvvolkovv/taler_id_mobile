import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:open_filex/open_filex.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import '../../../../core/api/dio_client.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';

class SharedMediaScreen extends StatefulWidget {
  final String conversationId;
  const SharedMediaScreen({super.key, required this.conversationId});

  @override
  State<SharedMediaScreen> createState() => _SharedMediaScreenState();
}

class _SharedMediaScreenState extends State<SharedMediaScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final _mediaItems = <_MediaItem>[];
  final _docItems = <_MediaItem>[];
  final _linkItems = <_MediaItem>[];
  bool _mediaLoading = true;
  bool _docsLoading = true;
  bool _linksLoading = true;
  String? _mediaCursor;
  String? _docsCursor;
  String? _linksCursor;
  bool _mediaHasMore = true;
  bool _docsHasMore = true;
  bool _linksHasMore = true;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _loadMedia();
    _loadDocs();
    _loadLinks();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadMedia({bool more = false}) async {
    if (more && !_mediaHasMore) return;
    try {
      final client = sl<DioClient>();
      final cursor = more ? _mediaCursor : null;
      final data = await client.get(
        '/messenger/conversations/${widget.conversationId}/media?type=media${cursor != null ? '&cursor=$cursor' : ''}',
        fromJson: (d) => Map<String, dynamic>.from(d as Map),
      );
      final items = (data['items'] as List).map((e) => _MediaItem.fromJson(e as Map<String, dynamic>)).toList();
      if (mounted) {
        setState(() {
          _mediaItems.addAll(items);
          _mediaCursor = data['nextCursor'] as String?;
          _mediaHasMore = _mediaCursor != null;
          _mediaLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _mediaLoading = false);
    }
  }

  Future<void> _loadDocs({bool more = false}) async {
    if (more && !_docsHasMore) return;
    try {
      final client = sl<DioClient>();
      final cursor = more ? _docsCursor : null;
      final data = await client.get(
        '/messenger/conversations/${widget.conversationId}/media?type=documents${cursor != null ? '&cursor=$cursor' : ''}',
        fromJson: (d) => Map<String, dynamic>.from(d as Map),
      );
      final items = (data['items'] as List).map((e) => _MediaItem.fromJson(e as Map<String, dynamic>)).toList();
      if (mounted) {
        setState(() {
          _docItems.addAll(items);
          _docsCursor = data['nextCursor'] as String?;
          _docsHasMore = _docsCursor != null;
          _docsLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _docsLoading = false);
    }
  }

  Future<void> _loadLinks({bool more = false}) async {
    if (more && !_linksHasMore) return;
    try {
      final client = sl<DioClient>();
      final cursor = more ? _linksCursor : null;
      final data = await client.get(
        '/messenger/conversations/${widget.conversationId}/media?type=links${cursor != null ? '&cursor=$cursor' : ''}',
        fromJson: (d) => Map<String, dynamic>.from(d as Map),
      );
      final items = (data['items'] as List).map((e) => _MediaItem.fromJson(e as Map<String, dynamic>)).toList();
      if (mounted) {
        setState(() {
          _linkItems.addAll(items);
          _linksCursor = data['nextCursor'] as String?;
          _linksHasMore = _linksCursor != null;
          _linksLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _linksLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: Text(l10n.sharedMediaTitle),
        backgroundColor: colors.surface,
        bottom: TabBar(
          controller: _tabCtrl,
          labelColor: colors.primary,
          unselectedLabelColor: colors.textSecondary,
          indicatorColor: colors.primary,
          tabs: [
            Tab(text: l10n.sharedMediaTab),
            Tab(text: l10n.sharedFilesTab),
            Tab(text: l10n.sharedLinksTab),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _buildMediaGrid(colors),
          _buildDocsList(colors),
          _buildLinksList(colors),
        ],
      ),
    );
  }

  Widget _buildMediaGrid(AppColorsExtension colors) {
    if (_mediaLoading) return const Center(child: CircularProgressIndicator());
    if (_mediaItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.photo_library_outlined, size: 64, color: colors.textSecondary),
            const SizedBox(height: 16),
            Text(AppLocalizations.of(context)!.sharedNoMedia, style: TextStyle(color: colors.textSecondary)),
          ],
        ),
      );
    }
    return NotificationListener<ScrollNotification>(
      onNotification: (n) {
        if (n.metrics.pixels > n.metrics.maxScrollExtent - 200 && _mediaHasMore && !_mediaLoading) {
          _loadMedia(more: true);
        }
        return false;
      },
      child: GridView.builder(
        padding: const EdgeInsets.all(2),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 2,
          mainAxisSpacing: 2,
        ),
        itemCount: _mediaItems.length,
        itemBuilder: (context, index) {
          final item = _mediaItems[index];
          final thumb = item.thumbnailMediumUrl ?? item.thumbnailSmallUrl ?? item.fileUrl;
          if (thumb == null) return const SizedBox();
          return GestureDetector(
            onTap: () => _openMediaViewer(item),
            child: Stack(
              fit: StackFit.expand,
              children: [
                CachedNetworkImage(
                  imageUrl: thumb,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(color: colors.surface),
                  errorWidget: (_, __, ___) => Container(
                    color: colors.surface,
                    child: Icon(Icons.broken_image, color: colors.textSecondary),
                  ),
                ),
                if (item.fileType == 'video')
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.play_arrow, color: Colors.white, size: 24),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDocsList(AppColorsExtension colors) {
    if (_docsLoading) return const Center(child: CircularProgressIndicator());
    if (_docItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_open_outlined, size: 64, color: colors.textSecondary),
            const SizedBox(height: 16),
            Text(AppLocalizations.of(context)!.sharedNoFiles, style: TextStyle(color: colors.textSecondary)),
          ],
        ),
      );
    }
    return NotificationListener<ScrollNotification>(
      onNotification: (n) {
        if (n.metrics.pixels > n.metrics.maxScrollExtent - 200 && _docsHasMore && !_docsLoading) {
          _loadDocs(more: true);
        }
        return false;
      },
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _docItems.length,
        separatorBuilder: (_, __) => Divider(color: colors.border, height: 1),
        itemBuilder: (context, index) {
          final item = _docItems[index];
          final ext = item.fileName?.split('.').last.toUpperCase() ?? 'FILE';
          final size = item.fileSize != null ? _formatSize(item.fileSize!) : '';
          final date = item.sentAt != null ? DateFormat('dd.MM.yy').format(item.sentAt!) : '';
          return ListTile(
            leading: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  ext.length > 4 ? ext.substring(0, 4) : ext,
                  style: TextStyle(color: colors.primary, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            title: Text(
              item.fileName ?? 'Файл',
              style: TextStyle(color: colors.textPrimary, fontSize: 14),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              [size, date].where((s) => s.isNotEmpty).join(' · '),
              style: TextStyle(color: colors.textSecondary, fontSize: 12),
            ),
            onTap: () => _openDocument(item),
          );
        },
      ),
    );
  }

  Widget _buildLinksList(AppColorsExtension colors) {
    if (_linksLoading) return const Center(child: CircularProgressIndicator());
    if (_linkItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.link_off, size: 64, color: colors.textSecondary),
            const SizedBox(height: 16),
            Text(AppLocalizations.of(context)!.sharedNoLinks, style: TextStyle(color: colors.textSecondary)),
          ],
        ),
      );
    }
    return NotificationListener<ScrollNotification>(
      onNotification: (n) {
        if (n.metrics.pixels > n.metrics.maxScrollExtent - 200 && _linksHasMore && !_linksLoading) {
          _loadLinks(more: true);
        }
        return false;
      },
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _linkItems.length,
        separatorBuilder: (_, __) => Divider(color: colors.border, height: 1),
        itemBuilder: (context, index) {
          final item = _linkItems[index];
          final url = _extractUrl(item.content ?? '');
          final date = item.sentAt != null ? DateFormat('dd.MM.yy').format(item.sentAt!) : '';
          return ListTile(
            leading: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.link, color: colors.primary),
            ),
            title: Text(
              url ?? item.content ?? '',
              style: TextStyle(color: colors.primary, fontSize: 14),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: date.isNotEmpty
                ? Text(date, style: TextStyle(color: colors.textSecondary, fontSize: 12))
                : null,
            onTap: () {
              if (url != null) launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
            },
          );
        },
      ),
    );
  }

  void _openMediaViewer(_MediaItem item) {
    if (item.fileUrl == null) return;
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => _FullScreenMediaView(item: item),
    ));
  }

  Future<void> _openDocument(_MediaItem item) async {
    if (item.fileUrl == null) return;
    try {
      final dir = await getTemporaryDirectory();
      final path = '${dir.path}/${item.fileName ?? 'file'}';
      await Dio().download(item.fileUrl!, path);
      await OpenFilex.open(path);
    } catch (_) {}
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String? _extractUrl(String text) {
    final match = RegExp(r'https?://\S+').firstMatch(text);
    return match?.group(0);
  }
}

class _MediaItem {
  final String id;
  final String? content;
  final DateTime? sentAt;
  final String? fileUrl;
  final String? fileName;
  final int? fileSize;
  final String? fileType;
  final String? thumbnailSmallUrl;
  final String? thumbnailMediumUrl;
  final String? thumbnailLargeUrl;

  _MediaItem({
    required this.id,
    this.content,
    this.sentAt,
    this.fileUrl,
    this.fileName,
    this.fileSize,
    this.fileType,
    this.thumbnailSmallUrl,
    this.thumbnailMediumUrl,
    this.thumbnailLargeUrl,
  });

  factory _MediaItem.fromJson(Map<String, dynamic> json) => _MediaItem(
    id: json['id'] as String,
    content: json['content'] as String?,
    sentAt: json['sentAt'] != null ? DateTime.tryParse(json['sentAt'] as String) : null,
    fileUrl: json['fileUrl'] as String?,
    fileName: json['fileName'] as String?,
    fileSize: json['fileSize'] as int?,
    fileType: json['fileType'] as String?,
    thumbnailSmallUrl: json['thumbnailSmallUrl'] as String?,
    thumbnailMediumUrl: json['thumbnailMediumUrl'] as String?,
    thumbnailLargeUrl: json['thumbnailLargeUrl'] as String?,
  );
}

class _FullScreenMediaView extends StatelessWidget {
  final _MediaItem item;
  const _FullScreenMediaView({required this.item});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          item.fileName ?? '',
          style: const TextStyle(color: Colors.white, fontSize: 14),
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: Center(
        child: InteractiveViewer(
          child: CachedNetworkImage(
            imageUrl: item.thumbnailLargeUrl ?? item.fileUrl!,
            fit: BoxFit.contain,
            placeholder: (_, __) => const CircularProgressIndicator(),
            errorWidget: (_, __, ___) => const Icon(Icons.broken_image, color: Colors.white, size: 48),
          ),
        ),
      ),
    );
  }
}

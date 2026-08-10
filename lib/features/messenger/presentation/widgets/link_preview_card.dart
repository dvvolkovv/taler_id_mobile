import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/datasources/messenger_remote_datasource.dart';

/// Первая ссылка в тексте — та, для которой строится карточка.
///
/// Форма совпадает с серверной проверкой в общих чертах, но решает всё равно
/// сервер: он же и откажет, если по адресу ходить нельзя.
final _firstUrlRegex = RegExp(
  r'https?://[^\s<>"\)]+',
  caseSensitive: false,
);

String? firstUrlIn(String text) => _firstUrlRegex.firstMatch(text)?.group(0);

/// Карточка ссылки под сообщением.
///
/// Данные запрашиваются один раз на адрес и держатся в памяти процесса: в
/// переписке одна и та же ссылка попадается многократно, и без этого каждое
/// её появление в ленте било бы запросом. Серверный кэш всё равно ответил бы
/// быстро, но лишний круг незачем.
class LinkPreviewCard extends StatefulWidget {
  final String url;
  final bool isMe;
  const LinkPreviewCard({super.key, required this.url, required this.isMe});

  @override
  State<LinkPreviewCard> createState() => _LinkPreviewCardState();
}

class _LinkPreviewCardState extends State<LinkPreviewCard> {
  /// null — ещё не спрашивали; запись с `null` внутри — спрашивали, показывать
  /// нечего. Второе состояние нужно, чтобы не долбить сервер по кругу.
  static final Map<String, Map<String, dynamic>?> _cache = {};

  Map<String, dynamic>? _data;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant LinkPreviewCard old) {
    super.didUpdateWidget(old);
    if (old.url != widget.url) _load();
  }

  Future<void> _load() async {
    if (_cache.containsKey(widget.url)) {
      setState(() => _data = _cache[widget.url]);
      return;
    }
    setState(() => _loading = true);
    try {
      final res = await sl<MessengerRemoteDataSource>().getLinkPreview(widget.url);
      _cache[widget.url] = res;
      if (mounted) setState(() => _data = res);
    } catch (_) {
      // Карточка — украшение. Не вышло — сообщение просто останется без неё,
      // ругаться на пользователя тут не за что.
      _cache[widget.url] = null;
      if (mounted) setState(() => _data = null);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = _data;
    if (_loading || d == null) return const SizedBox.shrink();

    final colors = AppColors.of(context);
    final title = d['title'] as String?;
    final description = d['description'] as String?;
    final imageUrl = d['imageUrl'] as String?;
    final siteName = d['siteName'] as String?;
    final accent = widget.isMe ? Colors.white : colors.primary;

    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: InkWell(
        onTap: () {
          final uri = Uri.tryParse(widget.url);
          if (uri != null) launchUrl(uri, mode: LaunchMode.inAppBrowserView);
        },
        child: Container(
          constraints: const BoxConstraints(maxWidth: 260),
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: accent, width: 3)),
            color: (widget.isMe ? Colors.white : colors.primary)
                .withValues(alpha: 0.06),
          ),
          padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (siteName != null && siteName.isNotEmpty)
                Text(
                  siteName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      color: accent, fontSize: 11, fontWeight: FontWeight.w600),
                ),
              if (title != null && title.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: widget.isMe ? Colors.white : colors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              if (description != null && description.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    description,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: widget.isMe
                          ? Colors.white.withValues(alpha: 0.85)
                          : colors.textSecondary,
                      fontSize: 12,
                      height: 1.25,
                    ),
                  ),
                ),
              if (imageUrl != null && imageUrl.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: CachedNetworkImage(
                      imageUrl: imageUrl,
                      width: 244,
                      fit: BoxFit.cover,
                      // Битая картинка не должна ломать карточку целиком —
                      // заголовок и описание сами по себе полезны.
                      errorWidget: (_, __, ___) => const SizedBox.shrink(),
                      placeholder: (_, __) => const SizedBox(height: 2),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

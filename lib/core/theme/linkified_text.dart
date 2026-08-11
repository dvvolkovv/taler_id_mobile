import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../features/messenger/utils/rich_text_parser.dart';

// Matches both full URLs (https://example.com/path) and bare domains
// (example.com, sub.example.co.uk/path). The bare-domain pattern requires
// at least one dot and a known-length TLD (2-12 chars) to avoid false
// positives on words like "i.e." or version strings like "v2.0".
final _urlRegex = RegExp(
  r'(?:https?://[^\s<>\"\)]+)'           // full URL with scheme
  r'|'
  r'(?:(?:[\w-]+\.)+[a-z]{2,12}(?:/[^\s<>\"\)]*)?)', // bare domain
  caseSensitive: false,
);

/// Упоминание вида `@логин`. Lookbehind отсекает адреса почты: в
/// `anna@taler.test` перед собакой стоит буква, и подсвечивать там нечего.
/// Та же форма, что у серверного разбора (`mention.util.ts`) — если правила
/// разойдутся, подсветится не то, что уведомит.
final _mentionRegex = RegExp(r'(?<![\w@])@([A-Za-z0-9_]{2,32})');

/// Renders [text] with auto-detected URLs as tappable links.
///
/// - Taler-internal room/user links navigate in-app via GoRouter.
/// - All other URLs open in the system's in-app browser
///   (SFSafariViewController on iOS, Chrome Custom Tabs on Android).
///
/// Shared across messenger chat bubbles, voice assistant transcript,
/// call-history AI twin transcript, and any future text surface.
class LinkifiedText extends StatefulWidget {
  final String text;
  final TextStyle style;
  final TextStyle? linkStyle;
  final int? maxLines;
  final TextOverflow? overflow;

  /// Стиль упоминаний. Null — упоминания не выделяются вовсе; так ведут себя
  /// поверхности вне чата (транскрипт ассистента, история звонков), где
  /// «@что-то» упоминанием не является.
  final TextStyle? mentionStyle;

  /// Тап по упоминанию. Null — упоминание просто подсвечено.
  final void Function(String handle)? onMentionTap;

  /// Разбирать ли **жирный**, __курсив__, ~~зачёркнутый~~, `код` и ||спойлер||.
  /// Выключено по умолчанию: вне чата (транскрипт ассистента, история звонков)
  /// звёздочки в тексте разметкой не являются.
  final bool richMarkup;

  const LinkifiedText({
    super.key,
    required this.text,
    required this.style,
    this.linkStyle,
    this.maxLines,
    this.overflow,
    this.mentionStyle,
    this.onMentionTap,
    this.richMarkup = false,
  });

  @override
  State<LinkifiedText> createState() => _LinkifiedTextState();
}

class _LinkifiedTextState extends State<LinkifiedText> {
  /// Раскрытые спойлеры — по индексу куска в разобранном тексте.
  final Set<int> _revealed = {};

  @override
  Widget build(BuildContext context) {
    // Разметка разбирается первой: внутри `кода` и ||спойлера|| ссылки и
    // упоминания не ищутся — там текст показывается как есть.
    if (widget.richMarkup && hasRichMarkup(widget.text)) {
      return _buildRich(context);
    }
    return _buildFlat(context, widget.text);
  }

  /// Текст с разметкой: каждый кусок рисуется своим стилем, спойлер — по тапу.
  Widget _buildRich(BuildContext context) {
    final tokens = parseRichText(widget.text);
    final spans = <InlineSpan>[];
    for (var i = 0; i < tokens.length; i++) {
      final tk = tokens[i];
      switch (tk.style) {
        case RichStyle.plain:
          spans.add(_flatSpan(context, tk.text));
        case RichStyle.bold:
          spans.add(TextSpan(
              text: tk.text,
              style: widget.style.copyWith(fontWeight: FontWeight.w700)));
        case RichStyle.italic:
          spans.add(TextSpan(
              text: tk.text,
              style: widget.style.copyWith(fontStyle: FontStyle.italic)));
        case RichStyle.strike:
          spans.add(TextSpan(
              text: tk.text,
              style: widget.style
                  .copyWith(decoration: TextDecoration.lineThrough)));
        case RichStyle.code:
          spans.add(TextSpan(
              text: tk.text,
              style: widget.style.copyWith(
                fontFamily: 'monospace',
                fontSize: (widget.style.fontSize ?? 14) - 1,
              )));
        case RichStyle.spoiler:
          final open = _revealed.contains(i);
          spans.add(TextSpan(
            text: tk.text,
            style: widget.style.copyWith(
              // Скрытый спойлер закрашивается собственным цветом текста: так
              // из него нельзя ничего вычитать, даже подсветив выделением.
              color: open ? widget.style.color : widget.style.color,
              backgroundColor: open
                  ? null
                  : (widget.style.color ?? Colors.grey).withValues(alpha: 0.85),
            ),
            recognizer: TapGestureRecognizer()
              ..onTap = () => setState(() => _revealed.add(i)),
          ));
      }
    }
    return SelectionArea(
      child: Text.rich(TextSpan(children: spans),
          maxLines: widget.maxLines, overflow: widget.overflow),
    );
  }

  /// Один кусок обычного текста как спан — со ссылками и упоминаниями внутри.
  InlineSpan _flatSpan(BuildContext context, String text) =>
      TextSpan(children: _spansFor(context, text));

  Widget _buildFlat(BuildContext context, String text) {
    final spans = _spansFor(context, text);
    if (spans.length == 1 && spans.first is TextSpan &&
        (spans.first as TextSpan).recognizer == null) {
      return SelectionArea(
        child: Text(text,
            style: widget.style, maxLines: widget.maxLines, overflow: widget.overflow),
      );
    }
    return SelectionArea(
      child: Text.rich(TextSpan(children: spans),
          maxLines: widget.maxLines, overflow: widget.overflow),
    );
  }

  List<InlineSpan> _spansFor(BuildContext context, String text) {
    // Ссылки и упоминания склеиваем в один упорядоченный список: они не
    // пересекаются, но идут вперемешку, а спаны надо выдавать по порядку.
    final matches = <_Span>[
      for (final m in _urlRegex.allMatches(text))
        _Span(m.start, m.end, m.group(0)!, isLink: true),
      if (widget.mentionStyle != null)
        for (final m in _mentionRegex.allMatches(text))
          _Span(m.start, m.end, m.group(0)!, isLink: false),
    ]..sort((a, b) => a.start.compareTo(b.start));
    if (matches.isEmpty) {
      return [TextSpan(text: text, style: widget.style)];
    }

    final effectiveLinkStyle = widget.linkStyle ??
        widget.style.copyWith(
          color: Colors.blue,
          decoration: TextDecoration.underline,
          decorationColor: Colors.blue.withValues(alpha: 0.4),
        );

    final spans = <InlineSpan>[];
    var lastEnd = 0;
    for (final m in matches) {
      // Перекрытия быть не должно, но если ссылка съела кусок с собакой —
      // пропускаем, иначе текст задвоится.
      if (m.start < lastEnd) continue;
      if (m.start > lastEnd) {
        spans.add(TextSpan(
          text: text.substring(lastEnd, m.start),
          style: widget.style,
        ));
      }
      if (m.isLink) {
        spans.add(TextSpan(
          text: m.text,
          style: effectiveLinkStyle,
          recognizer: TapGestureRecognizer()
            ..onTap = () => _handleTap(context, m.text),
        ));
      } else {
        spans.add(TextSpan(
          text: m.text,
          style: widget.mentionStyle,
          recognizer: widget.onMentionTap == null
              ? null
              : (TapGestureRecognizer()
                ..onTap = () => widget.onMentionTap!(m.text.substring(1))),
        ));
      }
      lastEnd = m.end;
    }
    if (lastEnd < text.length) {
      spans.add(TextSpan(text: text.substring(lastEnd), style: widget.style));
    }
    return spans;
  }

  static void _handleTap(BuildContext context, String url) {
    // Bare domains (e.g. "bundesregierung.de") need a scheme prefix.
    final normalized = url.startsWith('http') ? url : 'https://$url';
    final uri = Uri.tryParse(normalized);
    if (uri == null) return;

    const talerHosts = {'id.taler.tirol', 'staging.id.taler.tirol', 'talerid.io'};
    final isTaler = talerHosts.contains(uri.host);

    // Room links → open in-app voice screen
    if (isTaler && uri.path.startsWith('/room/')) {
      final code = uri.pathSegments.last;
      if (code.isNotEmpty) {
        GoRouter.of(context).go('/dashboard/voice?publicCode=$code');
        return;
      }
    }
    // Contact profile links → open in-app
    if (isTaler && uri.path.startsWith('/u/')) {
      final userId = uri.pathSegments.last;
      if (userId.isNotEmpty) {
        GoRouter.of(context).push('/dashboard/user/$userId');
        return;
      }
    }

    // Everything else → in-app browser (SFSafariViewController / Chrome Custom Tabs)
    launchUrl(uri, mode: LaunchMode.inAppBrowserView);
  }
}

/// Найденный участок текста: ссылка или упоминание.
class _Span {
  final int start;
  final int end;
  final String text;
  final bool isLink;
  const _Span(this.start, this.end, this.text, {required this.isLink});
}

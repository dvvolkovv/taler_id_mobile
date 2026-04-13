import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

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

/// Renders [text] with auto-detected URLs as tappable links.
///
/// - Taler-internal room/user links navigate in-app via GoRouter.
/// - All other URLs open in the system's in-app browser
///   (SFSafariViewController on iOS, Chrome Custom Tabs on Android).
///
/// Shared across messenger chat bubbles, voice assistant transcript,
/// call-history AI twin transcript, and any future text surface.
class LinkifiedText extends StatelessWidget {
  final String text;
  final TextStyle style;
  final TextStyle? linkStyle;
  final int? maxLines;
  final TextOverflow? overflow;

  const LinkifiedText({
    super.key,
    required this.text,
    required this.style,
    this.linkStyle,
    this.maxLines,
    this.overflow,
  });

  @override
  Widget build(BuildContext context) {
    final matches = _urlRegex.allMatches(text).toList();
    if (matches.isEmpty) {
      return SelectionArea(
        child: Text(
          text,
          style: style,
          maxLines: maxLines,
          overflow: overflow,
        ),
      );
    }

    final effectiveLinkStyle = linkStyle ??
        style.copyWith(
          color: Colors.blue,
          decoration: TextDecoration.underline,
          decorationColor: Colors.blue.withValues(alpha: 0.4),
        );

    final spans = <InlineSpan>[];
    var lastEnd = 0;
    for (final m in matches) {
      if (m.start > lastEnd) {
        spans.add(TextSpan(
          text: text.substring(lastEnd, m.start),
          style: style,
        ));
      }
      final url = m.group(0)!;
      spans.add(TextSpan(
        text: url,
        style: effectiveLinkStyle,
        recognizer: TapGestureRecognizer()
          ..onTap = () => _handleTap(context, url),
      ));
      lastEnd = m.end;
    }
    if (lastEnd < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastEnd),
        style: style,
      ));
    }
    return SelectionArea(
      child: Text.rich(
        TextSpan(children: spans),
        maxLines: maxLines,
        overflow: overflow,
      ),
    );
  }

  static void _handleTap(BuildContext context, String url) {
    // Bare domains (e.g. "bundesregierung.de") need a scheme prefix.
    final normalized = url.startsWith('http') ? url : 'https://$url';
    final uri = Uri.tryParse(normalized);
    if (uri == null) return;

    const talerHosts = {'id.taler.tirol', 'staging.id.taler.tirol'};
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

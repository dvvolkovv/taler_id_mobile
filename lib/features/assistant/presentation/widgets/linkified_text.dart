import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

final _urlRe = RegExp(r'https?://[^\s<>()\[\]]+');

/// Splits [text] into spans where URLs are tappable (opens externally).
List<InlineSpan> linkifiedSpans(String text, TextStyle base, TextStyle link) {
  final spans = <InlineSpan>[];
  var last = 0;
  for (final m in _urlRe.allMatches(text)) {
    if (m.start > last) {
      spans.add(TextSpan(text: text.substring(last, m.start), style: base));
    }
    final url = m.group(0)!;
    spans.add(TextSpan(
      text: url,
      style: link,
      recognizer: TapGestureRecognizer()
        ..onTap = () {
          final uri = Uri.tryParse(url);
          if (uri != null) {
            launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        },
    ));
    last = m.end;
  }
  if (last < text.length) {
    spans.add(TextSpan(text: text.substring(last), style: base));
  }
  return spans;
}

import 'package:flutter/material.dart';
import 'package:markdown/markdown.dart' as md;
import '../../../../core/theme/app_theme.dart';

/// Resolves canonical color names used in the chat markdown color tags
/// (`[HOT]`, `[COLD]`, `[C:name]`, `[B:name]`, `[HOT_BADGE]`, `[COLD_BADGE]`)
/// to actual [Color] values from the active [AppColorsExtension].
///
/// Unknown names return `null` so callers can fall back to plain text
/// without styling instead of crashing.
class MarkdownColorPalette {
  MarkdownColorPalette._();

  /// Returns the saturated text color for [name], or `null` if unknown.
  static Color? textColor(BuildContext context, String name) {
    final colors = AppColors.of(context);
    switch (name) {
      case 'red':
        return colors.error;
      case 'blue':
        return colors.primary;
      case 'yellow':
        return colors.warning;
      case 'green':
        return colors.success;
      default:
        return null;
    }
  }

  /// Returns the badge background tint (15% opacity of the text color),
  /// or `null` if [name] is unknown.
  static Color? badgeBackground(BuildContext context, String name) {
    return textColor(context, name)?.withOpacity(0.15);
  }

  /// Returns the badge border color (35% opacity of the text color),
  /// or `null` if [name] is unknown.
  static Color? badgeBorder(BuildContext context, String name) {
    return textColor(context, name)?.withOpacity(0.35);
  }
}

/// Parses inline color tags into `color_text` elements.
///
/// Surface forms (three-branch alternation):
///   `[HOT]…[/HOT]`         → color=red
///   `[COLD]…[/COLD]`       → color=blue
///   `[C:<name>]…[/C]`      → color=<name>, where name ∈ {red, blue, yellow, green}
///
/// Body is non-greedy and may span multiple lines. Mismatched or unclosed
/// tags simply do not match — the raw text passes through unchanged.
class ColorTextInlineSyntax extends md.InlineSyntax {
  ColorTextInlineSyntax()
      : super(
          r'(?:\[HOT\]([\s\S]+?)\[/HOT\])'
          r'|(?:\[COLD\]([\s\S]+?)\[/COLD\])'
          r'|(?:\[C:(red|blue|yellow|green)\]([\s\S]+?)\[/C\])',
        );

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    final hotBody = match.group(1);
    if (hotBody != null) {
      _emit(parser, color: 'red', body: hotBody);
      return true;
    }
    final coldBody = match.group(2);
    if (coldBody != null) {
      _emit(parser, color: 'blue', body: coldBody);
      return true;
    }
    final cName = match.group(3);
    final cBody = match.group(4);
    if (cName != null && cBody != null) {
      _emit(parser, color: cName, body: cBody);
      return true;
    }
    return false;
  }

  void _emit(md.InlineParser parser, {required String color, required String body}) {
    final element = md.Element('color_text', [md.Text(body)]);
    element.attributes['color'] = color;
    parser.addNode(element);
  }
}

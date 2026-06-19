import 'package:flutter/material.dart';
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

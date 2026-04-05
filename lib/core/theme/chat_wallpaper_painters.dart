import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Telegram-style procedural chat wallpapers: a smooth colored gradient
/// with a repeating icon-like pattern on top. All patterns are painted
/// directly on the canvas (zero asset weight).
class ChatWallpaperPalette {
  final String id;
  final List<Color> gradient;
  final IconData icon;
  final double iconSize;
  final double spacing;
  const ChatWallpaperPalette({
    required this.id,
    required this.gradient,
    required this.icon,
    this.iconSize = 28,
    this.spacing = 56,
  });
}

const List<ChatWallpaperPalette> kChatWallpaperPalettes = [
  ChatWallpaperPalette(
    id: 'pat_ocean',
    gradient: [Color(0xFF0EA5E9), Color(0xFF2563EB), Color(0xFF7C3AED)],
    icon: Icons.bubble_chart_rounded,
  ),
  ChatWallpaperPalette(
    id: 'pat_sunset',
    gradient: [Color(0xFFF97316), Color(0xFFEC4899), Color(0xFF8B5CF6)],
    icon: Icons.wb_twilight_rounded,
  ),
  ChatWallpaperPalette(
    id: 'pat_forest',
    gradient: [Color(0xFF059669), Color(0xFF065F46), Color(0xFF0E7490)],
    icon: Icons.eco_rounded,
  ),
  ChatWallpaperPalette(
    id: 'pat_aurora',
    gradient: [Color(0xFF22D3EE), Color(0xFFA855F7), Color(0xFFEC4899)],
    icon: Icons.star_rounded,
  ),
  ChatWallpaperPalette(
    id: 'pat_rose',
    gradient: [Color(0xFFFB7185), Color(0xFFE11D48), Color(0xFF7C2D12)],
    icon: Icons.favorite_rounded,
  ),
  ChatWallpaperPalette(
    id: 'pat_midnight',
    gradient: [Color(0xFF1E3A8A), Color(0xFF312E81), Color(0xFF581C87)],
    icon: Icons.nightlight_round,
  ),
  ChatWallpaperPalette(
    id: 'pat_mint',
    gradient: [Color(0xFF10B981), Color(0xFF22D3EE), Color(0xFF3B82F6)],
    icon: Icons.eco_outlined,
  ),
  ChatWallpaperPalette(
    id: 'pat_peach',
    gradient: [Color(0xFFFBBF24), Color(0xFFFB923C), Color(0xFFEC4899)],
    icon: Icons.wb_sunny_rounded,
  ),
];

ChatWallpaperPalette? paletteById(String id) {
  for (final p in kChatWallpaperPalettes) {
    if (p.id == id) return p;
  }
  return null;
}

/// Renders a repeating icon pattern on top of a diagonal gradient.
class ChatWallpaperPainter extends CustomPainter {
  final ChatWallpaperPalette palette;
  final bool isDark;
  ChatWallpaperPainter({required this.palette, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    // 1) Gradient background
    final bgRect = Offset.zero & size;
    final bgPaint = Paint()
      ..shader = LinearGradient(
        colors: palette.gradient,
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(bgRect);
    canvas.drawRect(bgRect, bgPaint);

    // 2) Repeating icon pattern — draw icons in a staggered grid
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    final iconColor = Colors.white.withValues(alpha: isDark ? 0.08 : 0.14);
    textPainter.text = TextSpan(
      text: String.fromCharCode(palette.icon.codePoint),
      style: TextStyle(
        fontSize: palette.iconSize,
        fontFamily: palette.icon.fontFamily,
        package: palette.icon.fontPackage,
        color: iconColor,
      ),
    );
    textPainter.layout();

    final stepX = palette.spacing;
    final stepY = palette.spacing * 0.9;
    for (double y = -palette.iconSize; y < size.height + palette.iconSize; y += stepY) {
      final rowIndex = ((y + palette.iconSize) / stepY).round();
      final offsetX = (rowIndex.isEven ? 0.0 : stepX / 2);
      for (double x = -palette.iconSize + offsetX;
          x < size.width + palette.iconSize;
          x += stepX) {
        // subtle per-icon rotation for organic feel
        final seed = (x * 13 + y * 7);
        final angle = math.sin(seed * 0.01) * 0.4;
        canvas.save();
        canvas.translate(x + palette.iconSize / 2, y + palette.iconSize / 2);
        canvas.rotate(angle);
        canvas.translate(-palette.iconSize / 2, -palette.iconSize / 2);
        textPainter.paint(canvas, Offset.zero);
        canvas.restore();
      }
    }

    // 3) Dark scrim on top so text bubbles stay readable on vivid palettes
    final scrimPaint = Paint()
      ..color = Colors.black.withValues(alpha: isDark ? 0.25 : 0.08);
    canvas.drawRect(bgRect, scrimPaint);
  }

  @override
  bool shouldRepaint(covariant ChatWallpaperPainter old) =>
      old.palette.id != palette.id || old.isDark != isDark;
}

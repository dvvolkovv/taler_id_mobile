import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:taler_id_mobile/l10n/app_localizations.dart';
import '../../../../core/services/wallpaper_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/chat_wallpaper_painters.dart';

/// Grid picker for the in-chat wallpaper. Includes a "None" option,
/// Telegram-style procedural patterns, and 6 photo presets.
class WallpaperPickerScreen extends StatelessWidget {
  const WallpaperPickerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settingsWallpaper),
        centerTitle: true,
      ),
      body: ValueListenableBuilder<String?>(
        valueListenable: WallpaperService.instance.current,
        builder: (context, selected, _) {
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: 0.68,
            ),
            itemCount: 1 + kChatWallpaperPalettes.length + WallpaperService.imagePresets.length,
            itemBuilder: (context, i) {
              // 0: None
              if (i == 0) {
                final isSelected = selected == null || selected.isEmpty;
                return _WallpaperTile(
                  isSelected: isSelected,
                  onTap: () async {
                    HapticFeedback.selectionClick();
                    await WallpaperService.instance.set(null);
                  },
                  label: l10n.settingsWallpaperNone,
                  child: Container(
                    color: colors.card,
                    child: Center(
                      child: Icon(
                        Icons.block_rounded,
                        size: 32,
                        color: colors.textSecondary,
                      ),
                    ),
                  ),
                );
              }
              // 1..N: procedural patterns
              final patIndex = i - 1;
              if (patIndex < kChatWallpaperPalettes.length) {
                final palette = kChatWallpaperPalettes[patIndex];
                final isSelected = selected == palette.id;
                return _WallpaperTile(
                  isSelected: isSelected,
                  onTap: () async {
                    HapticFeedback.selectionClick();
                    await WallpaperService.instance.set(palette.id);
                  },
                  child: CustomPaint(
                    painter: ChatWallpaperPainter(
                      palette: palette,
                      isDark: isDark,
                    ),
                  ),
                );
              }
              // Remaining: photo presets
              final photoIndex = patIndex - kChatWallpaperPalettes.length;
              final id = WallpaperService.imagePresets[photoIndex];
              final isSelected = selected == id;
              return _WallpaperTile(
                isSelected: isSelected,
                onTap: () async {
                  HapticFeedback.selectionClick();
                  await WallpaperService.instance.set(id);
                },
                child: Image.asset(
                  WallpaperService.thumbFor(id),
                  fit: BoxFit.cover,
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _WallpaperTile extends StatelessWidget {
  final Widget child;
  final bool isSelected;
  final VoidCallback onTap;
  final String? label;

  const _WallpaperTile({
    required this.child,
    required this.isSelected,
    required this.onTap,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: child,
          ),
          if (label != null)
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.4),
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(16),
                  ),
                ),
                child: Text(
                  label!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          if (isSelected)
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: colors.primary,
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: colors.primary.withValues(alpha: 0.55),
                      blurRadius: 14,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
            ),
          if (isSelected)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [colors.primary, colors.primaryDark],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: colors.primary.withValues(alpha: 0.5),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: const Icon(Icons.check_rounded, size: 18, color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}

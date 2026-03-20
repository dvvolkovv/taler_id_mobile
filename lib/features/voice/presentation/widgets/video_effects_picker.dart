import 'package:flutter/material.dart';
import '../../../../core/services/video_effects_service.dart';
import '../../../../core/theme/app_theme.dart';

/// Bottom sheet picker for video background effects (blur + virtual backgrounds).
class VideoEffectsPicker extends StatelessWidget {
  final VideoEffect currentEffect;
  final ValueChanged<VideoEffect> onSelect;

  const VideoEffectsPicker({
    super.key,
    required this.currentEffect,
    required this.onSelect,
  });

  static const _effects = VideoEffect.values;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final service = VideoEffectsService();
    return Container(
      padding: const EdgeInsets.only(top: 12, bottom: 24),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: colors.textSecondary.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Фон видео',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 100,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _effects.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final effect = _effects[index];
                final isSelected = effect == currentEffect;
                return _EffectOption(
                  effect: effect,
                  label: service.labelFor(effect),
                  thumbPath: service.thumbPathFor(effect),
                  isSelected: isSelected,
                  primaryColor: colors.primary,
                  textColor: colors.textSecondary,
                  iconColor: colors.textSecondary,
                  borderColor: colors.textSecondary.withOpacity(0.2),
                  tileBgColor: colors.textSecondary.withOpacity(0.1),
                  onTap: () => onSelect(effect),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _EffectOption extends StatelessWidget {
  final VideoEffect effect;
  final String label;
  final String? thumbPath;
  final bool isSelected;
  final Color primaryColor;
  final Color textColor;
  final Color iconColor;
  final Color borderColor;
  final Color tileBgColor;
  final VoidCallback onTap;

  const _EffectOption({
    required this.effect,
    required this.label,
    required this.thumbPath,
    required this.isSelected,
    required this.primaryColor,
    required this.textColor,
    required this.iconColor,
    required this.borderColor,
    required this.tileBgColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? primaryColor : borderColor,
                width: isSelected ? 2.5 : 1,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: _buildContent(),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? primaryColor : textColor,
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (effect == VideoEffect.none) {
      return Container(
        color: tileBgColor,
        child: Center(
          child: Icon(Icons.block_rounded, color: iconColor.withOpacity(0.5), size: 28),
        ),
      );
    }
    if (effect == VideoEffect.blur) {
      return Container(
        color: tileBgColor,
        child: Center(
          child: Icon(Icons.blur_on_rounded, color: iconColor, size: 28),
        ),
      );
    }
    if (thumbPath != null) {
      return Image.asset(
        thumbPath!,
        fit: BoxFit.cover,
        width: 64,
        height: 64,
      );
    }
    return Container(color: tileBgColor);
  }
}

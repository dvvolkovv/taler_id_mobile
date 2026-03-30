import 'dart:typed_data';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:taler_id_mobile/l10n/app_localizations.dart';
import '../../../../core/api/dio_client.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/services/video_effects_service.dart';
import '../../../../core/theme/app_theme.dart';
import 'package:dio/dio.dart';

/// Bottom sheet picker for video background effects (blur + virtual backgrounds + custom).
class VideoEffectsPicker extends StatefulWidget {
  final VideoEffect currentEffect;
  final ValueChanged<VideoEffect> onSelect;
  final void Function(Uint8List imageBytes)? onSelectCustom;

  const VideoEffectsPicker({
    super.key,
    required this.currentEffect,
    required this.onSelect,
    this.onSelectCustom,
  });

  @override
  State<VideoEffectsPicker> createState() => _VideoEffectsPickerState();
}

class _VideoEffectsPickerState extends State<VideoEffectsPicker> {
  List<Map<String, dynamic>> _customBackgrounds = [];
  bool _loading = true;
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    _loadCustomBackgrounds();
  }

  Future<void> _loadCustomBackgrounds() async {
    try {
      final data = await sl<DioClient>().get<dynamic>('/profile/backgrounds');
      if (!mounted) return;
      setState(() {
        _customBackgrounds = (data as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _uploadBackground() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 90);
    if (picked == null || !mounted) return;

    setState(() => _uploading = true);
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(picked.path, filename: picked.name),
      });
      await sl<DioClient>().dio.post('/profile/backgrounds', data: formData);
      await _loadCustomBackgrounds();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _deleteBackground(String id) async {
    try {
      await sl<DioClient>().delete('/profile/backgrounds/$id');
      await _loadCustomBackgrounds();
    } catch (_) {}
  }

  Future<void> _applyCustomBackground(Map<String, dynamic> bg) async {
    try {
      final url = bg['fileUrl'] as String;
      final response = await sl<DioClient>().dio.get<List<int>>(
        url,
        options: Options(responseType: ResponseType.bytes),
      );
      final bytes = Uint8List.fromList(response.data!);
      widget.onSelectCustom?.call(bytes);
    } catch (_) {}
  }

  static const _presetEffects = [
    VideoEffect.none, VideoEffect.blur,
    VideoEffect.bg1, VideoEffect.bg2, VideoEffect.bg3,
    VideoEffect.bg4, VideoEffect.bg5, VideoEffect.bg6,
  ];

  String _effectLabel(AppLocalizations l10n, VideoEffect effect) {
    switch (effect) {
      case VideoEffect.none: return l10n.effectNone;
      case VideoEffect.blur: return l10n.effectBlur;
      case VideoEffect.bg1: return l10n.effectOffice;
      case VideoEffect.bg2: return l10n.effectNature;
      case VideoEffect.bg3: return l10n.effectGradient;
      case VideoEffect.bg4: return l10n.effectLibrary;
      case VideoEffect.bg5: return l10n.effectCity;
      case VideoEffect.bg6: return l10n.effectMinimalism;
      case VideoEffect.custom: return 'Custom';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final l10n = AppLocalizations.of(context)!;
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
            width: 36, height: 4,
            decoration: BoxDecoration(
              color: colors.textSecondary.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                l10n.voiceVideoBackground,
                style: TextStyle(color: colors.textPrimary, fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Preset effects
          SizedBox(
            height: 100,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _presetEffects.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final effect = _presetEffects[index];
                final isSelected = effect == widget.currentEffect;
                return _EffectOption(
                  effect: effect,
                  label: _effectLabel(l10n, effect),
                  thumbPath: service.thumbPathFor(effect),
                  isSelected: isSelected,
                  primaryColor: colors.primary,
                  textColor: colors.textSecondary,
                  iconColor: colors.textSecondary,
                  borderColor: colors.textSecondary.withValues(alpha: 0.2),
                  tileBgColor: colors.textSecondary.withValues(alpha: 0.1),
                  onTap: () => widget.onSelect(effect),
                );
              },
            ),
          ),
          // Custom backgrounds section
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Text('My backgrounds', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500)),
                const Spacer(),
                if (_uploading)
                  SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: colors.primary))
                else
                  GestureDetector(
                    onTap: _customBackgrounds.length >= 10 ? null : _uploadBackground,
                    child: Icon(Icons.add_photo_alternate_rounded, color: _customBackgrounds.length >= 10 ? colors.textSecondary.withValues(alpha: 0.3) : colors.primary, size: 24),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: _loading || _customBackgrounds.isEmpty ? 64 : 100,
            child: _loading
                ? Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: colors.primary)))
                : _customBackgrounds.isEmpty
                    ? Center(child: Text('Tap + to add', style: TextStyle(color: colors.textSecondary, fontSize: 13)))
                    : ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _customBackgrounds.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 12),
                        itemBuilder: (context, index) {
                          final bg = _customBackgrounds[index];
                          final thumbUrl = bg['thumbnailUrl'] as String? ?? bg['fileUrl'] as String;
                          final isSelected = widget.currentEffect == VideoEffect.custom;
                          return GestureDetector(
                            onTap: () => _applyCustomBackground(bg),
                            onLongPress: () => _showDeleteDialog(bg['id'] as String),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  width: 64, height: 64,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isSelected ? colors.primary : colors.textSecondary.withValues(alpha: 0.2),
                                      width: isSelected ? 2.5 : 1,
                                    ),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: CachedNetworkImage(imageUrl: thumbUrl, fit: BoxFit.cover, width: 64, height: 64),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text('Custom', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(String id) {
    final colors = AppColors.of(context);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: colors.card,
        title: Text('Delete background?', style: TextStyle(color: colors.textPrimary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel', style: TextStyle(color: colors.textSecondary))),
          TextButton(
            onPressed: () { Navigator.pop(context); _deleteBackground(id); },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
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
            width: 64, height: 64,
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
          Text(label, style: TextStyle(
            color: isSelected ? primaryColor : textColor,
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          )),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (effect == VideoEffect.none) {
      return Container(color: tileBgColor, child: Center(child: Icon(Icons.block_rounded, color: iconColor.withValues(alpha: 0.5), size: 28)));
    }
    if (effect == VideoEffect.blur) {
      return Container(color: tileBgColor, child: Center(child: Icon(Icons.blur_on_rounded, color: iconColor, size: 28)));
    }
    if (thumbPath != null) {
      return Image.asset(thumbPath!, fit: BoxFit.cover, width: 64, height: 64);
    }
    return Container(color: tileBgColor);
  }
}

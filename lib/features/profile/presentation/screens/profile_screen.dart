import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:taler_id_mobile/l10n/app_localizations.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/widgets.dart';
import '../../../../core/utils/countries.dart';
import '../../../../core/api/dio_client.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/storage/cache_service.dart';
import '../../domain/entities/user_entity.dart';
import '../bloc/profile_bloc.dart';
import '../bloc/profile_event.dart';
import '../bloc/profile_state.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    context.read<ProfileBloc>().add(ProfileLoadRequested());
  }

  Color _kycColor(KycStatus status) {
    switch (status) {
      case KycStatus.verified: return AppColors.of(context).primary;
      case KycStatus.pending: return AppColors.of(context).warning;
      case KycStatus.rejected: return AppColors.of(context).error;
      case KycStatus.unverified: return AppColors.of(context).textSecondary;
    }
  }

  String _kycLabel(KycStatus status, AppLocalizations l10n) {
    switch (status) {
      case KycStatus.verified: return l10n.kycVerified;
      case KycStatus.pending: return l10n.kycPending;
      case KycStatus.rejected: return l10n.kycRejected;
      case KycStatus.unverified: return l10n.kycUnverified;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.of(context).background,
      appBar: AppBar(
        title: Text(l10n.profile),
        actions: const [],
      ),
      body: BlocBuilder<ProfileBloc, ProfileState>(
        builder: (context, state) {
          if (state is ProfileLoading) {
            return _buildSkeleton();
          }

          final user = state is ProfileLoaded
              ? state.user
              : state is ProfileUpdating
                  ? state.user
                  : state is ProfileError
                      ? state.user
                      : null;

          if (user == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, color: AppColors.of(context).error, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    state is ProfileError ? state.message : l10n.loadError,
                    style: TextStyle(color: AppColors.of(context).textSecondary),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.read<ProfileBloc>().add(ProfileLoadRequested()),
                    child: Text(l10n.retry),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            color: AppColors.of(context).primary,
            onRefresh: () async => context.read<ProfileBloc>().add(ProfileLoadRequested()),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Avatar + name
                AppCard(
                  child: Row(
                    children: [
                      _buildAvatar(user),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _fullName(user),
                              style: TextStyle(
                                color: AppColors.of(context).textPrimary,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(user.email, style: TextStyle(color: AppColors.of(context).textSecondary, fontSize: 13)),
                            if (user.username != null) ...[
                              const SizedBox(height: 2),
                              Text('@${user.username}', style: TextStyle(color: AppColors.of(context).primary, fontSize: 12)),
                            ],
                            const SizedBox(height: 8),
                            StatusBadge(
                              label: _kycLabel(user.kycStatus, l10n),
                              color: _kycColor(user.kycStatus),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Personal info
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.personalData, style: TextStyle(color: AppColors.of(context).textSecondary, fontSize: 12, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 12),
                      _usernameRow(context, user),
                      Divider(color: AppColors.of(context).border, height: 1),
                      _infoRow(Icons.phone_outlined, l10n.phone, user.phone ?? l10n.notSpecified),
                      Divider(color: AppColors.of(context).border, height: 1),
                      _infoRow(Icons.flag_outlined, l10n.country, _countryDisplayName(user.country) ?? l10n.notSpecifiedFemale),
                      Divider(color: AppColors.of(context).border, height: 1),
                      _infoRow(Icons.cake_outlined, l10n.dateOfBirth, _formatDateOfBirth(user.dateOfBirth) ?? l10n.notSpecifiedFemale),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _uploadAvatar(BuildContext context) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppColors.of(context).card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            ListTile(
              leading: Icon(Icons.camera_alt_outlined, color: AppColors.of(context).primary),
              title: Text('Сделать фото', style: TextStyle(color: AppColors.of(context).textPrimary)),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: Icon(Icons.photo_library_outlined, color: AppColors.of(context).primary),
              title: Text('Выбрать из галереи', style: TextStyle(color: AppColors.of(context).textPrimary)),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (source == null || !mounted) return;
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, maxWidth: 512, maxHeight: 512, imageQuality: 80);
    if (picked == null || !mounted) return;
    try {
      final client = sl<DioClient>();
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(picked.path, filename: 'avatar.jpg'),
      });
      await client.post('/profile/avatar', data: formData, fromJson: (d) => d);
      if (!mounted) return;
      // Clear image cache so updated avatar URL reloads fresh
      await CachedNetworkImage.evictFromCache(sl<CacheService>().getProfile()?['avatarUrl'] ?? '');
      imageCache.clear();
      context.read<ProfileBloc>().add(ProfileLoadRequested());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Аватар обновлён'), backgroundColor: Colors.green),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: $e'), backgroundColor: AppColors.of(context).error),
      );
    }
  }

  Widget _buildAvatar(UserEntity user) {
    return GestureDetector(
      onTap: () => _uploadAvatar(context),
      child: Stack(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: AppColors.of(context).primary.withValues(alpha: 0.2),
            child: user.avatarUrl != null
                ? ClipOval(
                    child: CachedNetworkImage(
                      imageUrl: user.avatarUrl!,
                      width: 64,
                      height: 64,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => Text(
                        _initials(user),
                        style: TextStyle(color: AppColors.of(context).primary, fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ),
                  )
                : Text(
                    _initials(user),
                    style: TextStyle(color: AppColors.of(context).primary, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: AppColors.of(context).primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.camera_alt, size: 12, color: Colors.black),
            ),
          ),
        ],
      ),
    );
  }

  String _initials(UserEntity user) {
    final first = user.firstName?.isNotEmpty == true ? user.firstName![0] : '';
    final last = user.lastName?.isNotEmpty == true ? user.lastName![0] : '';
    return (first + last).toUpperCase().isEmpty ? user.email[0].toUpperCase() : (first + last).toUpperCase();
  }

  String _fullName(UserEntity user) {
    final parts = [user.firstName, user.lastName].where((s) => s != null && s.isNotEmpty).toList();
    return parts.isEmpty ? user.email : parts.join(' ');
  }

  String? _formatDateOfBirth(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final dt = DateTime.tryParse(raw);
    if (dt == null) return raw;
    return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
  }

  String? _countryDisplayName(String? code) {
    if (code == null || code.isEmpty) return null;
    final locale = Localizations.localeOf(context).languageCode;
    return countryName(code, locale);
  }

  Widget _usernameRow(BuildContext context, UserEntity user) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Icon(Icons.alternate_email, color: AppColors.of(context).textSecondary, size: 18),
            const SizedBox(width: 12),
            Text('Никнейм', style: TextStyle(color: AppColors.of(context).textSecondary, fontSize: 13)),
            const Spacer(),
            Text(
              user.username != null ? '@${user.username}' : 'Не задан',
              style: TextStyle(color: AppColors.of(context).textPrimary, fontSize: 13),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => _editUsername(context, user),
              child: Icon(Icons.edit_outlined, color: AppColors.of(context).primary, size: 18),
            ),
          ],
        ),
      );

  Future<void> _editUsername(BuildContext context, UserEntity user) async {
    final ctrl = TextEditingController(text: user.username ?? '');
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.of(context).card,
        title: Text('Изменить никнейм', style: TextStyle(color: AppColors.of(context).textPrimary)),
        content: TextField(
          controller: ctrl,
          style: TextStyle(color: AppColors.of(context).textPrimary),
          decoration: InputDecoration(
            prefixText: '@',
            prefixStyle: TextStyle(color: AppColors.of(context).textSecondary),
            hintText: 'username',
            hintStyle: TextStyle(color: AppColors.of(context).textSecondary),
            filled: true,
            fillColor: AppColors.of(context).background,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: Text('Сохранить', style: TextStyle(color: AppColors.of(context).primary)),
          ),
        ],
      ),
    );
    ctrl.dispose();
    if (result == null || result.isEmpty) return;
    if (!mounted) return;
    try {
      final client = sl<DioClient>();
      await client.patch('/profile/username', data: {'username': result}, fromJson: (d) => d);
      if (!mounted) return;
      context.read<ProfileBloc>().add(ProfileLoadRequested());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Никнейм обновлён'), backgroundColor: Colors.green),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: $e'), backgroundColor: AppColors.of(context).error),
      );
    }
  }

  Widget _infoRow(IconData icon, String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Icon(icon, color: AppColors.of(context).textSecondary, size: 18),
            const SizedBox(width: 12),
            Text(label, style: TextStyle(color: AppColors.of(context).textSecondary, fontSize: 13)),
            const Spacer(),
            Text(value, style: TextStyle(color: AppColors.of(context).textPrimary, fontSize: 13)),
          ],
        ),
      );

  Widget _buildSkeleton() => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            AppCard(
              child: Row(
                children: [
                  const SkeletonBox(width: 64, height: 64),
                  const SizedBox(width: 16),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
                    SkeletonBox(width: 140, height: 18),
                    SizedBox(height: 8),
                    SkeletonBox(width: 100, height: 14),
                  ]),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const AppCard(child: SkeletonBox(width: double.infinity, height: 120)),
          ],
        ),
      );
}

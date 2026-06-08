import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/utils/share_helper.dart';
import 'package:taler_id_mobile/l10n/app_localizations.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/constants.dart';
import '../../../../core/theme/widgets.dart';
import '../../../../core/utils/countries.dart';
import '../../../../core/api/dio_client.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/storage/cache_service.dart';
import '../../domain/entities/user_entity.dart';
import '../bloc/profile_bloc.dart';
import '../../../voice/presentation/widgets/pulsing_avatar.dart' show rainbowColorFor;
import '../bloc/profile_event.dart';
import '../bloc/profile_state.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  UserEntity? _cachedUser;

  @override
  void initState() {
    super.initState();
    context.read<ProfileBloc>().add(ProfileLoadRequested());
  }

  void _showQrCode(BuildContext context, UserEntity user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.of(context).card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _QrCodeSheet(user: user),
    );
  }

  void _openScanner(BuildContext context) {
    final router = GoRouter.of(context);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _QrScannerScreen(
          onUserScanned: (userId) {
            Navigator.of(context).pop();
            router.go('/dashboard/user/$userId');
          },
        ),
      ),
    );
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
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner_outlined),
            tooltip: l10n.profileScanQr,
            onPressed: () => _openScanner(context),
          ),
        ],
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

          if (user != null && _cachedUser != user) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) setState(() => _cachedUser = user);
            });
          }

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
                if (!user.emailVerified) ...[
                  _verifyEmailBanner(context, user, l10n),
                  const SizedBox(height: 12),
                ],
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
                            if (user.status != null && user.status!.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(user.status!, style: TextStyle(color: AppColors.of(context).textSecondary, fontSize: 13, fontStyle: FontStyle.italic)),
                            ],
                            const SizedBox(height: 8),
                            PulsingBadge(
                              glowColor: _kycColor(user.kycStatus),
                              enabled: user.kycStatus == KycStatus.verified,
                              borderRadius: BorderRadius.circular(20),
                              maxScale: 1.04,
                              child: StatusBadge(
                                label: _kycLabel(user.kycStatus, l10n),
                                color: _kycColor(user.kycStatus),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // QR code card
                AppCard(
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            l10n.profileMyQrCode,
                            style: TextStyle(
                              color: AppColors.of(context).textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Builder(
                            builder: (btnCtx) => GestureDetector(
                              onTap: () => shareText(btnCtx, l10n.profileAddMeShare(user.id)),
                              child: Icon(Icons.share_outlined, color: AppColors.of(context).primary, size: 18),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF22D3EE), Color(0xFFA855F7), Color(0xFFFB7185)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFA855F7).withValues(alpha: 0.35),
                                blurRadius: 20,
                                spreadRadius: 2,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(13),
                            ),
                            child: QrImageView(
                              data: 'talerid://user/${user.id}',
                              version: QrVersions.auto,
                              size: 180,
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black,
                              errorCorrectionLevel: QrErrorCorrectLevel.H,
                              embeddedImage: const AssetImage('assets/app_icon_light.png'),
                              embeddedImageStyle: const QrEmbeddedImageStyle(
                                size: Size(44, 44),
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (user.username != null && user.username!.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(
                          '@${user.username}',
                          style: TextStyle(color: AppColors.of(context).primary, fontSize: 13),
                        ),
                      ],
                      const SizedBox(height: 4),
                      Text(
                        l10n.profileShowCode,
                        style: TextStyle(color: AppColors.of(context).textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // Edit profile
                AppCard(
                  child: InkWell(
                    onTap: () => context.push(RouteConstants.editProfile),
                    borderRadius: BorderRadius.circular(16),
                    child: Row(
                      children: [
                        _navIconTile(Icons.edit_rounded, AppColors.of(context).primary),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(l10n.editProfile, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.of(context).textPrimary)),
                              const SizedBox(height: 2),
                              Text(l10n.profileEditDesc, style: TextStyle(fontSize: 12, color: AppColors.of(context).textSecondary)),
                            ],
                          ),
                        ),
                        Icon(Icons.chevron_right, color: AppColors.of(context).textSecondary, size: 20),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // About me sections
                AppCard(
                  child: InkWell(
                    onTap: () => context.push(RouteConstants.profileSections),
                    child: Row(
                      children: [
                        _navIconTile(Icons.person_pin_rounded, const Color(0xFFA855F7)),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(l10n.profileAboutMe, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.of(context).textPrimary)),
                              const SizedBox(height: 2),
                              Text(
                                l10n.profileAboutMeDesc,
                                style: TextStyle(fontSize: 12, color: AppColors.of(context).textSecondary),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.chevron_right, color: AppColors.of(context).textSecondary, size: 20),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Notes
                AppCard(
                  child: InkWell(
                    onTap: () => context.push(RouteConstants.notes),
                    borderRadius: BorderRadius.circular(16),
                    child: Row(
                      children: [
                        _navIconTile(Icons.sticky_note_2_rounded, const Color(0xFFFB7185)),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(l10n.profileNotes, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.of(context).textPrimary)),
                              const SizedBox(height: 2),
                              Text(
                                l10n.profileNotesDesc,
                                style: TextStyle(fontSize: 12, color: AppColors.of(context).textSecondary),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.chevron_right, color: AppColors.of(context).textSecondary, size: 20),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // AI Voice Twin
                AppCard(
                  child: InkWell(
                    onTap: () => context.push(RouteConstants.aiTwin),
                    borderRadius: BorderRadius.circular(16),
                    child: Row(
                      children: [
                        _navIconTile(Icons.smart_toy_rounded, AppColors.of(context).primary),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    l10n.aiTwinProfileTitle,
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.of(context).textPrimary),
                                  ),
                                  const SizedBox(width: 8),
                                  if (user.aiTwinEnabled)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.of(context).primary.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        l10n.aiTwinBadgeOn,
                                        style: TextStyle(
                                          color: AppColors.of(context).primary,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                l10n.aiTwinProfileDesc,
                                style: TextStyle(fontSize: 12, color: AppColors.of(context).textSecondary),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.chevron_right, color: AppColors.of(context).textSecondary, size: 20),
                      ],
                    ),
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
              title: Text(AppLocalizations.of(context)!.profilePhotoCamera, style: TextStyle(color: AppColors.of(context).textPrimary)),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: Icon(Icons.photo_library_outlined, color: AppColors.of(context).primary),
              title: Text(AppLocalizations.of(context)!.profilePhotoGallery, style: TextStyle(color: AppColors.of(context).textPrimary)),
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
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.profileAvatarUpdated), backgroundColor: Colors.green),
      );
    } catch (e) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.errorWithMessage(e.toString())), backgroundColor: AppColors.of(context).error),
      );
    }
  }

  /// 40x40 gradient icon tile with colored glow for profile nav cards.
  Widget _navIconTile(IconData icon, Color color) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color.lerp(color, Colors.white, 0.15)!,
            color,
            Color.lerp(color, Colors.black, 0.25)!,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: const [0.0, 0.5, 1.0],
        ),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.45),
            blurRadius: 8,
          ),
        ],
      ),
      child: Icon(icon, color: Colors.white, size: 22),
    );
  }

  Widget _buildAvatar(UserEntity user) {
    final ringColor = rainbowColorFor(
      (user.firstName?.isNotEmpty == true ? user.firstName! : user.email),
    );
    return GestureDetector(
      onTap: () => _uploadAvatar(context),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Outer ring + colored glow halo
          Container(
            width: 72,
            height: 72,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: ringColor, width: 2.5),
              boxShadow: [
                BoxShadow(
                  color: ringColor.withValues(alpha: 0.45),
                  blurRadius: 16,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  center: const Alignment(-0.3, -0.4),
                  radius: 1.1,
                  colors: [
                    Color.lerp(ringColor, Colors.white, 0.3)!,
                    ringColor,
                    Color.lerp(ringColor, Colors.black, 0.4)!,
                  ],
                  stops: const [0.0, 0.55, 1.0],
                ),
              ),
              child: user.avatarUrl != null
                  ? ClipOval(
                      child: CachedNetworkImage(
                        imageUrl: user.avatarUrl!,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => Center(
                          child: Text(
                            _initials(user),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    )
                  : Center(
                      child: Text(
                        _initials(user),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
            ),
          ),
          Positioned(
            bottom: -2,
            right: -2,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.of(context).primary,
                    AppColors.of(context).primaryDark,
                  ],
                ),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.of(context).card, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.of(context).primary.withValues(alpha: 0.45),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: const Icon(Icons.camera_alt, size: 12, color: Colors.white),
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
    final parts = [user.firstName, user.middleName, user.lastName].where((s) => s != null && s.isNotEmpty).toList();
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

  Widget _verifyEmailBanner(BuildContext context, UserEntity user, AppLocalizations l10n) {
    final colors = AppColors.of(context);
    return Material(
      color: colors.warning.withOpacity(0.12),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.push(
          RouteConstants.verifyEmail,
          extra: {'email': user.email},
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Icon(Icons.mark_email_unread_outlined, color: colors.warning, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.verifyEmailBannerTitle,
                      style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.verifyEmailBannerSubtitle,
                      style: TextStyle(color: colors.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: colors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }

  Widget _usernameRow(BuildContext context, UserEntity user) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Icon(Icons.alternate_email, color: AppColors.of(context).textSecondary, size: 18),
            const SizedBox(width: 12),
            Text(AppLocalizations.of(context)!.profileNickname, style: TextStyle(color: AppColors.of(context).textSecondary, fontSize: 13)),
            const Spacer(),
            Text(
              user.username != null ? '@${user.username}' : AppLocalizations.of(context)!.profileNotSet,
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
        title: Text(AppLocalizations.of(context)!.profileChangeNickname, style: TextStyle(color: AppColors.of(context).textPrimary)),
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
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.profileNicknameUpdated), backgroundColor: Colors.green),
      );
    } catch (e) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.errorWithMessage(e.toString())), backgroundColor: AppColors.of(context).error),
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

// ── QR Code bottom sheet ──────────────────────────────────────────────────────

class _QrCodeSheet extends StatelessWidget {
  final UserEntity user;
  const _QrCodeSheet({required this.user});

  @override
  Widget build(BuildContext context) {
    final qrData = 'talerid://user/${user.id}';
    final name = [user.firstName, user.lastName]
        .where((s) => s != null && s!.isNotEmpty)
        .join(' ');
    final colors = AppColors.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(32, 16, 32, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: colors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              AppLocalizations.of(context)!.profileMyQrCode,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: QrImageView(
                data: qrData,
                version: QrVersions.auto,
                size: 220,
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
              ),
            ),
            const SizedBox(height: 20),
            if (name.isNotEmpty)
              Text(
                name,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
            if (user.username != null && user.username!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                '@${user.username}',
                style: TextStyle(color: colors.primary, fontSize: 14),
              ),
            ],
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: Builder(
                builder: (btnCtx) => ElevatedButton.icon(
                  onPressed: () => shareText(btnCtx, AppLocalizations.of(context)!.profileAddMeShare(user.id)),
                  icon: const Icon(Icons.share_outlined, color: Colors.black),
                  label: Text(AppLocalizations.of(context)!.profileShareLabel, style: const TextStyle(color: Colors.black)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.of(context).primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── QR Scanner screen ─────────────────────────────────────────────────────────

class _QrScannerScreen extends StatefulWidget {
  final void Function(String userId) onUserScanned;
  const _QrScannerScreen({required this.onUserScanned});

  @override
  State<_QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<_QrScannerScreen> {
  bool _handled = false;

  void _onDetect(BarcodeCapture capture) {
    if (_handled) return;
    for (final barcode in capture.barcodes) {
      final raw = barcode.rawValue;
      if (raw == null) continue;
      final uri = Uri.tryParse(raw);
      if (uri == null) continue;
      if (uri.scheme == 'talerid' && uri.host == 'user' && uri.pathSegments.isNotEmpty) {
        _handled = true;
        widget.onUserScanned(uri.pathSegments.first);
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: Text(AppLocalizations.of(context)!.profileScanQrCode),
      ),
      body: Stack(
        children: [
          MobileScanner(onDetect: _onDetect),
          Center(
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white70, width: 2),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          Positioned(
            bottom: 48,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                AppLocalizations.of(context)!.profilePointCamera,
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

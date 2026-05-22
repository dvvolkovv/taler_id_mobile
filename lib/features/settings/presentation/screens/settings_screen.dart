import 'package:flutter/foundation.dart' show kIsWeb;
import '../../../../core/platform/platform_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taler_id_mobile/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../../../core/platform/biometric_auth.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:taler_id_mobile/core/platform/fcm_messaging.dart';
import '../../../../core/platform/desktop_av_permission.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/widgets.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/utils/constants.dart';
import '../../../../core/services/wake_word_service.dart';
import '../../../../main.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../mesh/presentation/widgets/mesh_settings_section.dart';
import '../../../profile/data/datasources/profile_remote_datasource.dart';
import '../../../auth/data/datasources/auth_remote_datasource.dart';
import '../../../billing/presentation/widgets/balance_chip.dart';
import 'package:dio/dio.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> with WidgetsBindingObserver {
  // Cache across navigations so Security section doesn't jump on re-entry
  static bool? _cachedBiometricAvailable;

  bool _biometricEnabled = false;
  bool _biometricAvailable = _cachedBiometricAvailable ?? false;
  bool _pinEnabled = false;
  String _currentLang = 'ru';
  String _currentTheme =
      PlatformUtils.instance.isDesktop ? 'dark' : 'light';
  bool _wakeWordEnabled = WakeWordService.isSettingEnabled;
  String _appVersion = '';
  bool _permNotifications = false;
  bool _permMicrophone = false;
  bool _permCamera = false;
  bool _permLocation = false;
  final _storage = sl<SecureStorageService>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadSettings();
    _loadPermissions();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadPermissions();
    }
  }

  Future<void> _loadPermissions() async {
    if (kIsWeb) return;
    bool notif = false;
    try {
      notif = await FcmMessagingPlatform.instance.hasPermission();
    } catch (_) {}
    final bool micGranted;
    final bool camGranted;
    final bool locGranted;
    if (PlatformUtils.instance.isDesktop) {
      // permission_handler 11.x/12.x has no macOS implementation —
      // route through DesktopAvPermission. Linux/Windows have no TCC and
      // checkX() returns granted (3).
      micGranted = (await DesktopAvPermission.checkMicrophone()) == 3;
      camGranted = (await DesktopAvPermission.checkCamera()) == 3;
      locGranted = true; // no location prompt on desktop in this app
    } else {
      final mic = await Permission.microphone.status;
      final cam = await Permission.camera.status;
      final loc = await Permission.locationWhenInUse.status;
      micGranted = mic.isGranted || mic.isLimited;
      camGranted = cam.isGranted || cam.isLimited;
      locGranted = loc.isGranted || loc.isLimited;
    }
    if (!mounted) return;
    setState(() {
      _permNotifications = notif;
      _permMicrophone = micGranted;
      _permCamera = camGranted;
      _permLocation = locGranted;
    });
  }

  Future<void> _togglePermission(bool currentlyGranted, Future<PermissionStatus> Function() requestFn) async {
    if (currentlyGranted) {
      // Can't revoke programmatically — open system settings
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.permissionOpenSettings),
          backgroundColor: AppColors.of(context).primary,
        ),
      );
      await openAppSettings();
    } else {
      await requestFn();
    }
    await _loadPermissions();
  }

  /// Desktop-aware toggle for mic/camera that routes through DesktopAvPermission
  /// (permission_handler has no macOS implementation).
  Future<void> _toggleAvPermissionDesktop({
    required bool currentlyGranted,
    required Future<bool> Function() requestFn,
  }) async {
    if (currentlyGranted) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.permissionOpenSettings),
          backgroundColor: AppColors.of(context).primary,
        ),
      );
      // On macOS open System Settings → Privacy & Security manually.
      // openAppSettings() from permission_handler is a no-op on macOS.
    } else {
      await requestFn();
    }
    await _loadPermissions();
  }

  Future<void> _toggleNotifications(bool currentlyGranted) async {
    if (currentlyGranted) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.permissionOpenSettings),
          backgroundColor: AppColors.of(context).primary,
        ),
      );
      await openAppSettings();
    } else {
      try {
        await FcmMessagingPlatform.instance.requestPermissions();
      } catch (_) {}
    }
    await _loadPermissions();
  }

  Future<void> _loadSettings() async {
    final info = await PackageInfo.fromPlatform();
    final biometricEnabled = await _storage.isBiometricEnabled;
    final pinEnabled = await _storage.isPinEnabled;
    final savedLang = await _storage.getLanguage() ?? 'ru';
    final savedTheme = await _storage.getThemeMode() ??
        (PlatformUtils.instance.isDesktop ? 'dark' : 'light');
    bool available = false;
    try {
      final bio = BiometricAuthPlatform.instance;
      final canCheck = await bio.canCheckBiometrics;
      final isSupported = await bio.isDeviceSupported;
      if (canCheck || isSupported) {
        final biometrics = await bio.getAvailableBiometrics();
        available = biometrics.isNotEmpty;
      }
    } catch (_) {
      available = false;
    }
    _cachedBiometricAvailable = available;
    if (!mounted) return;
    setState(() {
      _biometricEnabled = biometricEnabled;
      _biometricAvailable = available;
      _pinEnabled = pinEnabled;
      _currentLang = savedLang;
      _currentTheme = savedTheme;
      _appVersion = '${info.version}+${info.buildNumber}';
    });
  }

  Future<void> _toggleBiometric(bool value) async {
    final l10n = AppLocalizations.of(context)!;
    if (value) {
      try {
        final ok = await BiometricAuthPlatform.instance.authenticate(
          localizedReason: l10n.biometricsConfirm,
        );
        if (!ok) return;
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.biometricsError), backgroundColor: AppColors.of(context).error),
          );
        }
        return;
      }
    }
    await _storage.setBiometricEnabled(value);
    if (!mounted) return;
    setState(() => _biometricEnabled = value);
  }

  Future<void> _togglePin(bool value) async {
    if (value) {
      await context.push(RouteConstants.pinSetup);
      final pinEnabled = await _storage.isPinEnabled;
      setState(() => _pinEnabled = pinEnabled);
    } else {
      await _storage.clearPin();
      setState(() => _pinEnabled = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.of(context).background,
      appBar: AppBar(
        centerTitle: true,
        title: Text(l10n.settings),
        actions: const [
          Padding(
            padding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            child: BalanceChip(),
          ),
        ],
      ),
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthLoggedOut) {
            context.go(RouteConstants.login);
          }
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Identity & Organizations section
            _sectionHeader(l10n.settingsAccount),
            AppCard(
              child: Column(
                children: [
                  _navTile(
                    icon: Icons.verified_user_outlined,
                    iconColor: AppColors.of(context).primary,
                    title: l10n.settingsKycVerification,
                    onTap: () => context.push(RouteConstants.kyc),
                  ),
                  Divider(color: AppColors.of(context).border, height: 1),
                  _navTile(
                    icon: Icons.business_outlined,
                    iconColor: AppColors.of(context).primary,
                    title: l10n.settingsOrganizations,
                    onTap: () => context.push(RouteConstants.organization),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Security section
            _sectionHeader(l10n.security),
            AppCard(
              child: Column(
                children: [
                  if (_biometricAvailable)
                    _switchTile(
                      icon: Icons.fingerprint,
                      iconColor: AppColors.of(context).primary,
                      title: l10n.biometrics,
                      subtitle: l10n.biometricsDesc,
                      value: _biometricEnabled,
                      onChanged: _toggleBiometric,
                    ),
                  if (_biometricAvailable) Divider(color: AppColors.of(context).border, height: 1),
                  _switchTile(
                    icon: Icons.pin_outlined,
                    iconColor: AppColors.of(context).primary,
                    title: l10n.pinCode,
                    subtitle: l10n.pinCodeDesc,
                    value: _pinEnabled,
                    onChanged: _togglePin,
                  ),
                  Divider(color: AppColors.of(context).border, height: 1),
                  _navTile(
                    icon: Icons.lock_outlined,
                    iconColor: AppColors.of(context).secondary,
                    title: l10n.changePassword,
                    onTap: () => _showChangePasswordSheet(context),
                  ),
                  Divider(color: AppColors.of(context).border, height: 1),
                  _navTile(
                    icon: Icons.devices_outlined,
                    iconColor: AppColors.of(context).secondary,
                    title: l10n.sessions,
                    onTap: () => context.push(RouteConstants.sessions),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Permissions section
            _sectionHeader(l10n.permissions),
            AppCard(
              child: Column(
                children: [
                  _switchTile(
                    icon: Icons.notifications_active_outlined,
                    iconColor: AppColors.of(context).warning,
                    title: l10n.permissionNotifications,
                    subtitle: l10n.permissionNotificationsDesc,
                    value: _permNotifications,
                    onChanged: (_) => _toggleNotifications(_permNotifications),
                  ),
                  Divider(color: AppColors.of(context).border, height: 1),
                  _switchTile(
                    icon: Icons.mic_outlined,
                    iconColor: AppColors.of(context).primary,
                    title: l10n.permissionMicrophone,
                    subtitle: l10n.permissionMicrophoneDesc,
                    value: _permMicrophone,
                    onChanged: (_) => PlatformUtils.instance.isDesktop
                        ? _toggleAvPermissionDesktop(
                            currentlyGranted: _permMicrophone,
                            requestFn: DesktopAvPermission.requestMicrophone,
                          )
                        : _togglePermission(
                            _permMicrophone,
                            () => Permission.microphone.request(),
                          ),
                  ),
                  Divider(color: AppColors.of(context).border, height: 1),
                  _switchTile(
                    icon: Icons.camera_alt_outlined,
                    iconColor: AppColors.of(context).primary,
                    title: l10n.permissionCamera,
                    subtitle: l10n.permissionCameraDesc,
                    value: _permCamera,
                    onChanged: (_) => PlatformUtils.instance.isDesktop
                        ? _toggleAvPermissionDesktop(
                            currentlyGranted: _permCamera,
                            requestFn: DesktopAvPermission.requestCamera,
                          )
                        : _togglePermission(
                            _permCamera,
                            () => Permission.camera.request(),
                          ),
                  ),
                  Divider(color: AppColors.of(context).border, height: 1),
                  _switchTile(
                    icon: Icons.location_on_outlined,
                    iconColor: AppColors.of(context).secondary,
                    title: l10n.permissionLocation,
                    subtitle: l10n.permissionLocationDesc,
                    value: _permLocation,
                    onChanged: (_) => _togglePermission(
                      _permLocation,
                      () => Permission.locationWhenInUse.request(),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Billing & AI section
            _sectionHeader(l10n.billingSectionHeader),
            AppCard(
              child: Column(
                children: [
                  _navTile(
                    icon: Icons.account_balance_wallet_outlined,
                    iconColor: AppColors.of(context).primary,
                    title: l10n.billingWalletAndBalance,
                    onTap: () => context.push('/billing/wallet'),
                  ),
                  Divider(color: AppColors.of(context).border, height: 1),
                  _navTile(
                    icon: Icons.smart_toy_outlined,
                    iconColor: AppColors.of(context).accent,
                    title: l10n.billingAiFeaturesTitle,
                    onTap: () => context.push('/settings/ai-toggles'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Account section
            _sectionHeader(l10n.account),
            AppCard(
              child: Column(
                children: [
                  _navTile(
                    icon: Icons.palette_outlined,
                    iconColor: AppColors.of(context).textSecondary,
                    title: l10n.appearance,
                    trailing: _themeLabel(l10n),
                    onTap: () => _showThemePicker(context),
                  ),
                  Divider(color: AppColors.of(context).border, height: 1),
                  _navTile(
                    icon: Icons.language_outlined,
                    iconColor: AppColors.of(context).textSecondary,
                    title: l10n.language,
                    trailing: _currentLang == 'ru' ? l10n.languageRussian : l10n.languageEnglish,
                    onTap: () => _showLanguagePicker(context),
                  ),
                  Divider(color: AppColors.of(context).border, height: 1),
                  _navTile(
                    icon: Icons.wallpaper_rounded,
                    iconColor: const Color(0xFFA855F7),
                    title: l10n.settingsWallpaper,
                    onTap: () => context.push(RouteConstants.wallpaper),
                  ),
                  Divider(color: AppColors.of(context).border, height: 1),
                  _navTile(
                    icon: Icons.delete_forever_outlined,
                    iconColor: AppColors.of(context).error,
                    title: l10n.deleteAccount,
                    onTap: () => _showDeleteAccountDialog(context),
                    textColor: AppColors.of(context).error,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Mesh network section (Phase 1e) — mobile only. Desktop has no
            // mesh networking (no Bonjour/BLE peer discovery).
            if (PlatformUtils.instance.isMobile) ...[
              _sectionHeader(_currentLang == 'ru' ? 'Mesh-сеть' : 'Mesh Network'),
              const MeshSettingsSection(),
              const SizedBox(height: 16),
            ],

            // Voice assistant section
            _sectionHeader(_currentLang == 'ru' ? 'Голосовой помощник' : 'Voice Assistant'),
            AppCard(
              child: Column(
                children: [
                  SwitchListTile(
                    secondary: Icon(Icons.mic_outlined, color: AppColors.of(context).primary),
                    title: Text(
                      _currentLang == 'ru' ? 'Активация голосом' : 'Voice Activation',
                      style: TextStyle(color: AppColors.of(context).textPrimary, fontSize: 15),
                    ),
                    subtitle: Text(
                      _currentLang == 'ru'
                          ? 'Скажите "${WakeWordService.effectivePhrase(_currentLang)}" для запуска'
                          : 'Say "${WakeWordService.effectivePhrase(_currentLang)}" to start',
                      style: TextStyle(color: AppColors.of(context).textSecondary, fontSize: 12),
                    ),
                    value: _wakeWordEnabled,
                    activeColor: AppColors.of(context).primary,
                    onChanged: (v) {
                      setState(() => _wakeWordEnabled = v);
                      WakeWordService.isSettingEnabled = v;
                      if (v) {
                        WakeWordService.instance.resume();
                      } else {
                        WakeWordService.instance.stop();
                      }
                    },
                  ),
                  if (_wakeWordEnabled) ...[
                    Divider(color: AppColors.of(context).border, height: 1),
                    _navTile(
                      icon: Icons.record_voice_over_outlined,
                      iconColor: AppColors.of(context).textSecondary,
                      title: _currentLang == 'ru' ? 'Фраза активации' : 'Wake Phrase',
                      trailing: WakeWordService.effectivePhrase(_currentLang),
                      onTap: () => _showWakePhrasePicker(context),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Logout
            GestureDetector(
              onTap: () => _confirmLogout(context),
              child: Container(
                width: double.infinity,
                height: 52,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFEF4444), Color(0xFFB91C1C)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.of(context).error.withValues(alpha: 0.4),
                      blurRadius: 16,
                      spreadRadius: 0,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.logout, color: Colors.white, size: 20),
                    const SizedBox(width: 10),
                    Text(
                      l10n.logout,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),
            // Version info
            Center(
              child: Text(
                l10n.version(_appVersion.isNotEmpty ? _appVersion : '...'),
                style: TextStyle(color: AppColors.of(context).textSecondary, fontSize: 12),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 8),
        child: Row(
          children: [
            Container(
              width: 3,
              height: 14,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.of(context).primary,
                    AppColors.of(context).accent,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Text(title,
                style: TextStyle(
                  color: AppColors.of(context).textPrimary.withValues(alpha: 0.85),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.6,
                )),
          ],
        ),
      );

  BoxDecoration _iconDecoration(Color c) => BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color.lerp(c, Colors.white, 0.15)!,
            c,
            Color.lerp(c, Colors.black, 0.25)!,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: const [0.0, 0.5, 1.0],
        ),
        borderRadius: BorderRadius.circular(9),
        boxShadow: [
          BoxShadow(
            color: c.withValues(alpha: 0.45),
            blurRadius: 8,
            spreadRadius: 0,
          ),
        ],
      );

  Widget _switchTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: _iconDecoration(iconColor),
              child: Icon(icon, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(color: AppColors.of(context).textPrimary, fontSize: 14)),
                  if (subtitle != null)
                    Text(subtitle, style: TextStyle(color: AppColors.of(context).textSecondary, fontSize: 12)),
                ],
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
              activeColor: AppColors.of(context).primary,
            ),
          ],
        ),
      );

  Widget _navTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    String? trailing,
    required VoidCallback onTap,
    Color? textColor,
  }) =>
      InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            children: [
              Container(
                width: 36, height: 36,
                decoration: _iconDecoration(iconColor),
                child: Icon(icon, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(title,
                    style: TextStyle(color: textColor ?? AppColors.of(context).textPrimary, fontSize: 14)),
              ),
              if (trailing != null)
                Text(trailing, style: TextStyle(color: AppColors.of(context).textSecondary, fontSize: 13)),
              const SizedBox(width: 4),
              if (trailing != null || textColor == null)
                Icon(Icons.chevron_right, color: AppColors.of(context).textSecondary, size: 18),
            ],
          ),
        ),
      );

  void _confirmLogout(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.of(context).card,
        title: Text(l10n.logoutConfirm, style: TextStyle(color: AppColors.of(context).textPrimary)),
        content: Text(l10n.logoutDesc,
            style: TextStyle(color: AppColors.of(context).textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.cancel, style: TextStyle(color: AppColors.of(context).textSecondary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<AuthBloc>().add(LogoutRequested());
            },
            child: Text(l10n.logout, style: TextStyle(color: AppColors.of(context).error)),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordSheet(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = AppColors.of(context);
    final oldCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    bool showOld = false;
    bool showNew = false;
    bool showConfirm = false;
    bool saving = false;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          return Container(
            decoration: BoxDecoration(
              color: colors.card,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: EdgeInsets.fromLTRB(24, 12, 24, MediaQuery.of(ctx).viewInsets.bottom + 32),
            child: SingleChildScrollView(
              child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40, height: 4,
                          decoration: BoxDecoration(color: colors.border, borderRadius: BorderRadius.circular(2)),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Container(
                            width: 44, height: 44,
                            decoration: BoxDecoration(
                              color: colors.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(Icons.lock_outline_rounded, color: colors.primary, size: 22),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            l10n.changePassword,
                            style: TextStyle(color: colors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _PasswordField(
                        controller: oldCtrl,
                        label: l10n.currentPassword,
                        icon: Icons.lock_person_outlined,
                        colors: colors,
                        obscure: !showOld,
                        onToggle: () => setSheetState(() => showOld = !showOld),
                      ),
                      const SizedBox(height: 12),
                      _PasswordField(
                        controller: newCtrl,
                        label: l10n.newPassword,
                        icon: Icons.lock_reset_rounded,
                        colors: colors,
                        obscure: !showNew,
                        onToggle: () => setSheetState(() => showNew = !showNew),
                      ),
                      const SizedBox(height: 12),
                      _PasswordField(
                        controller: confirmCtrl,
                        label: l10n.confirmNewPassword,
                        icon: Icons.check_circle_outline_rounded,
                        colors: colors,
                        obscure: !showConfirm,
                        onToggle: () => setSheetState(() => showConfirm = !showConfirm),
                      ),
                      const SizedBox(height: 24),
                      GestureDetector(
                        onTap: saving ? null : () async {
                          if (oldCtrl.text.isEmpty || newCtrl.text.isEmpty || confirmCtrl.text.isEmpty) return;
                          if (newCtrl.text != confirmCtrl.text) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(l10n.pinMismatch), backgroundColor: colors.error),
                            );
                            return;
                          }
                          if (newCtrl.text.length < 8 || !RegExp(r'^(?=.*[A-Za-z])(?=.*\d).+$').hasMatch(newCtrl.text)) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(l10n.passwordTooWeak), backgroundColor: colors.error),
                            );
                            return;
                          }
                          setSheetState(() => saving = true);
                          final messenger = ScaffoldMessenger.of(context);
                          try {
                            await sl<AuthRemoteDataSource>().changePassword(
                              currentPassword: oldCtrl.text,
                              newPassword: newCtrl.text,
                            );
                            if (!ctx.mounted) return;
                            Navigator.pop(ctx);
                            messenger.showSnackBar(
                              SnackBar(content: Text(l10n.passwordChanged), backgroundColor: colors.primary),
                            );
                          } on DioException catch (e) {
                            setSheetState(() => saving = false);
                            final status = e.response?.statusCode;
                            String msg;
                            if (status == 401) {
                              msg = l10n.wrongCurrentPassword;
                            } else if (status == 400) {
                              final data = e.response?.data;
                              final serverMsg = data is Map ? (data['message'] is List ? (data['message'] as List).join(', ') : data['message']?.toString()) : null;
                              msg = serverMsg ?? l10n.passwordTooWeak;
                            } else {
                              msg = l10n.passwordChangeFailed;
                            }
                            messenger.showSnackBar(SnackBar(content: Text(msg), backgroundColor: colors.error));
                          } catch (_) {
                            setSheetState(() => saving = false);
                            messenger.showSnackBar(
                              SnackBar(content: Text(l10n.passwordChangeFailed), backgroundColor: colors.error),
                            );
                          }
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [colors.primary, Color.lerp(colors.primary, Colors.black, 0.15)!],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [BoxShadow(color: colors.primary.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4))],
                          ),
                          child: Center(
                            child: saving
                                ? const SizedBox(
                                    width: 20, height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : Text(l10n.save, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ),
                    ],
                  ),
            ),
          );
        },
      ),
    );
  }

  void _showLanguagePicker(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.of(context).card,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.languageSelect,
                style: TextStyle(color: AppColors.of(context).textPrimary, fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            ListTile(
              leading: const Text('\u{1f1f7}\u{1f1fa}', style: TextStyle(fontSize: 24)),
              title: Text(l10n.languageRussian, style: TextStyle(color: AppColors.of(context).textPrimary)),
              trailing: _currentLang == 'ru' ? Icon(Icons.check, color: AppColors.of(context).primary) : null,
              onTap: () => _selectLanguage('ru'),
            ),
            ListTile(
              leading: const Text('\u{1f1ec}\u{1f1e7}', style: TextStyle(fontSize: 24)),
              title: Text(l10n.languageEnglish, style: TextStyle(color: AppColors.of(context).textPrimary)),
              trailing: _currentLang == 'en' ? Icon(Icons.check, color: AppColors.of(context).primary) : null,
              onTap: () => _selectLanguage('en'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectLanguage(String lang) async {
    Navigator.pop(context);
    await _storage.saveLanguage(lang);
    TalerIdApp.setLocale(context, Locale(lang));
    setState(() => _currentLang = lang);
  }

  String _themeLabel(AppLocalizations l10n) => switch (_currentTheme) {
    'dark' => l10n.themeDark,
    'system' => l10n.themeSystem,
    _ => l10n.themeLight,
  };

  void _showThemePicker(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = AppColors.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: colors.card,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.appearanceSelect,
                style: TextStyle(color: colors.textPrimary, fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            ListTile(
              leading: Icon(Icons.light_mode_outlined, color: colors.textSecondary),
              title: Text(l10n.themeLight, style: TextStyle(color: colors.textPrimary)),
              trailing: _currentTheme == 'light' ? Icon(Icons.check, color: colors.primary) : null,
              onTap: () => _selectTheme('light'),
            ),
            ListTile(
              leading: Icon(Icons.dark_mode_outlined, color: colors.textSecondary),
              title: Text(l10n.themeDark, style: TextStyle(color: colors.textPrimary)),
              trailing: _currentTheme == 'dark' ? Icon(Icons.check, color: colors.primary) : null,
              onTap: () => _selectTheme('dark'),
            ),
            ListTile(
              leading: Icon(Icons.phone_android_outlined, color: colors.textSecondary),
              title: Text(l10n.themeSystem, style: TextStyle(color: colors.textPrimary)),
              trailing: _currentTheme == 'system' ? Icon(Icons.check, color: colors.primary) : null,
              onTap: () => _selectTheme('system'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectTheme(String theme) async {
    Navigator.pop(context);
    await _storage.saveThemeMode(theme);
    final mode = switch (theme) {
      'dark' => ThemeMode.dark,
      'system' => ThemeMode.system,
      _ => ThemeMode.light,
    };
    TalerIdApp.setThemeMode(context, mode);
    setState(() => _currentTheme = theme);
  }

  void _showWakePhrasePicker(BuildContext context) {
    final colors = AppColors.of(context);
    final current = WakeWordService.effectivePhrase(_currentLang);
    final options = [
      WakeWordService.defaultPhraseRu,
      WakeWordService.defaultPhraseEn,
    ];
    final customCtrl = TextEditingController();
    final saved = WakeWordService.settingPhrase;
    final isCustom = saved.isNotEmpty && !options.contains(saved);
    if (isCustom) customCtrl.text = saved;

    showModalBottomSheet(
      context: context,
      backgroundColor: colors.card,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _currentLang == 'ru' ? 'Фраза активации' : 'Wake Phrase',
              style: TextStyle(color: colors.textPrimary, fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            ...options.map((phrase) => ListTile(
              leading: Icon(Icons.record_voice_over_outlined, color: colors.textSecondary),
              title: Text(phrase, style: TextStyle(color: colors.textPrimary)),
              trailing: current == phrase && !isCustom ? Icon(Icons.check, color: colors.primary) : null,
              onTap: () {
                Navigator.pop(context);
                WakeWordService.settingPhrase = phrase;
                // Restart wake word with new phrase
                WakeWordService.instance.stop();
                if (_wakeWordEnabled) WakeWordService.instance.resume();
                setState(() {});
              },
            )),
            const SizedBox(height: 8),
            Divider(color: colors.border),
            const SizedBox(height: 8),
            Text(
              _currentLang == 'ru' ? 'Или введите свою фразу:' : 'Or enter your own phrase:',
              style: TextStyle(color: colors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: customCtrl,
              style: TextStyle(color: colors.textPrimary),
              decoration: InputDecoration(
                hintText: _currentLang == 'ru' ? 'Например: Окей Талер' : 'e.g. OK Taler',
                hintStyle: TextStyle(color: colors.textSecondary.withValues(alpha: 0.5)),
                filled: true,
                fillColor: colors.background,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                suffixIcon: IconButton(
                  icon: Icon(Icons.check_circle, color: colors.primary),
                  onPressed: () {
                    final text = customCtrl.text.trim();
                    if (text.length < 2) return;
                    Navigator.pop(context);
                    WakeWordService.settingPhrase = text;
                    WakeWordService.instance.stop();
                    if (_wakeWordEnabled) WakeWordService.instance.resume();
                    setState(() {});
                  },
                ),
              ),
              onSubmitted: (text) {
                if (text.trim().length < 2) return;
                Navigator.pop(context);
                WakeWordService.settingPhrase = text.trim();
                WakeWordService.instance.stop();
                if (_wakeWordEnabled) WakeWordService.instance.resume();
                setState(() {});
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.of(context).card,
        title: Text(l10n.deleteAccountConfirm, style: TextStyle(color: AppColors.of(context).error)),
        content: Text(
          l10n.deleteAccountDesc,
          style: TextStyle(color: AppColors.of(context).textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.cancel, style: TextStyle(color: AppColors.of(context).textSecondary)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              try {
                final ds = sl<ProfileRemoteDataSource>();
                await ds.deleteAccount();
                if (mounted) {
                  context.read<AuthBloc>().add(LogoutRequested());
                }
              } catch (_) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error'), backgroundColor: AppColors.of(context).error),
                  );
                }
              }
            },
            child: Text(l10n.delete, style: TextStyle(color: AppColors.of(context).error)),
          ),
        ],
      ),
    );
  }
}

class _PasswordField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final AppColorsExtension colors;
  final bool obscure;
  final VoidCallback onToggle;

  const _PasswordField({
    required this.controller,
    required this.label,
    required this.icon,
    required this.colors,
    required this.obscure,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: TextStyle(color: colors.textPrimary, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: colors.textSecondary, fontSize: 13),
        prefixIcon: Icon(icon, color: colors.textSecondary, size: 18),
        suffixIcon: GestureDetector(
          onTap: onToggle,
          child: Icon(
            obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
            color: colors.textSecondary,
            size: 18,
          ),
        ),
        filled: true,
        fillColor: colors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: colors.border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: colors.border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: colors.primary, width: 1.5)),
      ),
    );
  }
}

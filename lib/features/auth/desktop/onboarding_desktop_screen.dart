import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:taler_id_mobile/core/desktop/desktop_adaptive_scaffold.dart';
import 'package:taler_id_mobile/core/desktop/desktop_breakpoints.dart';
import 'package:taler_id_mobile/core/desktop/hover_lift.dart';
import 'package:taler_id_mobile/core/di/service_locator.dart';
import 'package:taler_id_mobile/core/platform/desktop_av_permission.dart';
import 'package:taler_id_mobile/core/platform/fcm_messaging.dart';
import 'package:taler_id_mobile/core/storage/secure_storage_service.dart';
import 'package:taler_id_mobile/core/theme/app_theme.dart';
import 'package:taler_id_mobile/core/utils/constants.dart';
import 'package:url_launcher/url_launcher.dart';
import 'controllers/onboarding_progress.dart';
import 'widgets/permission_row_card.dart';

/// Desktop-shaped onboarding: single centered card with notifications +
/// microphone permission rows. Renders only when
/// `PlatformUtils.instance.isDesktop` (selected at the router builder).
///
/// Wrapped in [DesktopAdaptiveScaffold] for shared chrome + blob bg + glass
/// card. The inline animated background and Stack from the original
/// implementation are now provided by the scaffold.
class OnboardingDesktopScreen extends StatefulWidget {
  const OnboardingDesktopScreen({super.key});

  @override
  State<OnboardingDesktopScreen> createState() => _OnboardingDesktopScreenState();
}

class _OnboardingDesktopScreenState extends State<OnboardingDesktopScreen> {
  bool _notificationsHandled = false;
  bool _notificationsGranted = false;
  bool _microphoneHandled = false;
  bool _microphoneGranted = false;

  static const _notifGradient = [Color(0xFF3B82F6), Color(0xFFA855F7)];
  static const _micGradient = [Color(0xFF10B981), Color(0xFF22D3EE)];

  @override
  void initState() {
    super.initState();
    _restoreProgress();
  }

  Future<void> _restoreProgress() async {
    final step = await OnboardingProgress.getStep();
    if (!mounted) return;
    // Phase 1 simplification: persisted step records "interacted with N rows"
    // but not which one or what outcome. Treat both rows as `handled` (neutral)
    // when restoring; the actual TCC state isn't surfaced until the user clicks
    // again. Phase 2 polish can query DesktopAvPermission.checkMicrophone /
    // FcmMessagingPlatform.hasPermission to recover the exact state.
    if (step >= 1) setState(() => _notificationsHandled = true);
    if (step >= 2) setState(() => _microphoneHandled = true);
  }

  Future<void> _onClickNotifications() async {
    await FcmMessagingPlatform.instance.requestPermissions();
    final granted = await FcmMessagingPlatform.instance.hasPermission();
    if (!mounted) return;
    setState(() {
      _notificationsHandled = true;
      _notificationsGranted = granted;
    });
    await OnboardingProgress.saveStep(_microphoneHandled ? 2 : 1);
  }

  Future<void> _onClickMicrophone() async {
    final granted = await DesktopAvPermission.requestMicrophone();
    if (!mounted) return;
    setState(() {
      _microphoneHandled = true;
      _microphoneGranted = granted;
    });
    await OnboardingProgress.saveStep(_notificationsHandled ? 2 : 1);
  }

  Future<void> _openSystemSettings(String url) async {
    await launchUrl(Uri.parse(url));
  }

  Future<void> _finish() async {
    await OnboardingProgress.clear();
    final storage = sl<SecureStorageService>();
    await storage.setOnboardingSeen();
    if (!mounted) return;
    final hasToken = await storage.hasRefreshToken;
    if (!mounted) return;
    context.go(hasToken ? RouteConstants.messenger : RouteConstants.login);
  }

  bool get _canContinue => _notificationsHandled && _microphoneHandled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DesktopAdaptiveScaffold(
      cardMaxWidth: kCardWidthSettings,
      cardPadding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Image.asset(
                'assets/app_icon_dark.png',
                width: 56,
                height: 56,
                errorBuilder: (_, __, ___) =>
                    const SizedBox(width: 56, height: 56),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Добро пожаловать в Taler ID',
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Разрешите доступ для полноценной работы — займёт 5 секунд',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          PermissionRowCard(
            icon: Icons.notifications_outlined,
            title: 'Уведомления',
            description: 'Сообщения в трее и звонки когда окно свёрнуто',
            handled: _notificationsHandled,
            granted: _notificationsGranted,
            deniedHint:
                '⚠ Включить в System Settings → Notifications → Taler ID',
            onDeniedHintTap: _notificationsHandled && !_notificationsGranted
                ? () => _openSystemSettings(
                    'x-apple.systempreferences:com.apple.preference.notifications')
                : null,
            accentGradient: _notifGradient,
            onPressed: _onClickNotifications,
          ),
          const SizedBox(height: 12),
          PermissionRowCard(
            icon: Icons.mic_none_outlined,
            title: 'Микрофон',
            description: 'Голосовой ассистент и голосовые сообщения',
            handled: _microphoneHandled,
            granted: _microphoneGranted,
            deniedHint:
                '⚠ Включить в System Settings → Privacy & Security → Microphone',
            onDeniedHintTap: _microphoneHandled && !_microphoneGranted
                ? () => _openSystemSettings(
                    'x-apple.systempreferences:com.apple.preference.security?Privacy_Microphone')
                : null,
            accentGradient: _micGradient,
            onPressed: _onClickMicrophone,
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              TextButton(
                onPressed: _finish,
                child: const Text('Пропустить'),
              ),
              const Spacer(),
              HoverLift(
                shadowBoost: AppColors.of(context).primary,
                child: FilledButton(
                  onPressed: _canContinue ? _finish : null,
                  child: const Text('Продолжить'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

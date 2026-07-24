import 'dart:math' as math;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:taler_id_mobile/l10n/app_localizations.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/notifications/notification_service.dart';
import '../../../../core/platform/desktop_av_permission.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/constants.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final _pageController = PageController();
  int _currentPage = 0;
  bool _requestInFlight = false;

  static const _totalPages = 2;

  // Per-page accent color gradients
  static const _pageGradients = [
    [Color(0xFF3B82F6), Color(0xFFA855F7)], // notifications: blue → purple
    [Color(0xFF10B981), Color(0xFF22D3EE)], // microphone: emerald → cyan
  ];

  late final AnimationController _bgCtrl;

  @override
  void initState() {
    super.initState();
    _bgCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _bgCtrl.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    final storage = sl<SecureStorageService>();
    await storage.setOnboardingSeen();
    if (!mounted) return;
    // If the user has a session, go to the app; otherwise to login.
    final hasToken = await storage.hasRefreshToken;
    if (!mounted) return;
    context.go(hasToken ? RouteConstants.assistant : RouteConstants.login);
  }

  // After the system dialog resolves (granted or denied) we advance
  // automatically — no extra "Next" tap between permissions.
  Future<void> _requestNotifications() async {
    if (_requestInFlight) return;
    _requestInFlight = true;
    try {
      if (!kIsWeb) {
        await NotificationService.requestPermission();
      }
    } finally {
      _requestInFlight = false;
    }
    if (!mounted) return;
    _nextPage();
  }

  Future<void> _requestMicrophone() async {
    if (_requestInFlight) return;
    _requestInFlight = true;
    try {
      if (!kIsWeb) {
        // Use macOS-native AVCaptureDevice.requestAccess on desktop because
        // permission_handler does not support macOS.
        await DesktopAvPermission.requestMicrophone();
      }
    } finally {
      _requestInFlight = false;
    }
    if (!mounted) return;
    await _finish();
  }

  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = AppColors.of(context);

    final pages = [
      _OnboardingPage(
        icon: Icons.notifications_active_rounded,
        title: l10n.onboardingTitle3,
        description: l10n.onboardingDesc3,
        gradient: _pageGradients[0],
      ),
      _OnboardingPage(
        icon: Icons.mic_rounded,
        title: l10n.onboardingTitle4,
        description: l10n.onboardingDesc4,
        gradient: _pageGradients[1],
      ),
    ];

    final currentGradient = _pageGradients[_currentPage];

    return Scaffold(
      backgroundColor: colors.background,
      body: Stack(
        children: [
          // Animated background blobs tinted by current page's accent
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _bgCtrl,
                builder: (context, _) => CustomPaint(
                  painter: _BackgroundBlobsPainter(
                    time: _bgCtrl.value * 2 * math.pi,
                    colors: currentGradient,
                  ),
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Skip button
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 12, right: 16),
                    child: TextButton(
                      onPressed: _finish,
                      child: Text(
                        l10n.onboardingSkip,
                        style: TextStyle(color: colors.textSecondary, fontSize: 14),
                      ),
                    ),
                  ),
                ),

                // Pages
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: (i) => setState(() => _currentPage = i),
                    children: pages,
                  ),
                ),

                // Dots indicator
                Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_totalPages, (i) {
                      final active = i == _currentPage;
                      final inactiveColor = colors.textSecondary.withValues(alpha: 0.3);
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 260),
                        curve: Curves.easeOutBack,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: active ? 28 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          // Use color (not gradient) to keep the decoration
                          // type consistent across animation frames — lerping
                          // between gradient and non-gradient BoxDecoration
                          // can throw.
                          color: active ? _pageGradients[i].first : inactiveColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                ),

                // Bottom buttons
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                  child: _buildBottomButtons(l10n, colors, currentGradient),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButtons(
    AppLocalizations l10n,
    AppColorsExtension colors,
    List<Color> gradient,
  ) {
    // Page 0: Notifications
    if (_currentPage == 0) {
      return _buildPermissionPage(
        onRequest: _requestNotifications,
        icon: Icons.notifications_active,
        enableLabel: l10n.onboardingEnableNotifications,
        afterLabel: l10n.onboardingNext,
        onAfter: _nextPage,
        colors: colors,
        gradient: gradient,
      );
    }

    // Page 1: Microphone (last page)
    return _buildPermissionPage(
      onRequest: _requestMicrophone,
      icon: Icons.mic_rounded,
      enableLabel: l10n.onboardingEnableMicrophone,
      afterLabel: l10n.onboardingStart,
      onAfter: _finish,
      colors: colors,
      gradient: gradient,
    );
  }

  Widget _buildPermissionPage({
    required VoidCallback onRequest,
    required IconData icon,
    required String enableLabel,
    required String afterLabel,
    required VoidCallback onAfter,
    required AppColorsExtension colors,
    required List<Color> gradient,
  }) {
    return Column(
      children: [
        _GradientButton(
          onTap: onRequest,
          icon: icon,
          label: enableLabel,
          gradient: gradient,
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: OutlinedButton(
            onPressed: onAfter,
            child: Text(afterLabel),
          ),
        ),
      ],
    );
  }
}

class _OnboardingPage extends StatefulWidget {
  final IconData icon;
  final String title;
  final String description;
  final List<Color> gradient;

  const _OnboardingPage({
    required this.icon,
    required this.title,
    required this.description,
    required this.gradient,
  });

  @override
  State<_OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<_OnboardingPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final accent = widget.gradient.first;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Hero icon with breathing pulse, gradient ring, and colored glow
          AnimatedBuilder(
            animation: _pulseCtrl,
            builder: (context, _) {
              final t = _pulseCtrl.value;
              final scale = 1.0 + 0.06 * t;
              final glow = 0.45 + 0.25 * t;
              return Transform.scale(
                scale: scale,
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: widget.gradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.22),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: accent.withValues(alpha: glow),
                        blurRadius: 40,
                        spreadRadius: 6,
                      ),
                      BoxShadow(
                        color: widget.gradient.last.withValues(alpha: 0.3),
                        blurRadius: 60,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                  child: Icon(
                    widget.icon,
                    color: Colors.white,
                    size: 64,
                    shadows: [
                      Shadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 48),
          Text(
            widget.title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 26,
              fontWeight: FontWeight.bold,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            widget.description,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 16,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

/// Filled button with a gradient fill, colored glow, and optional leading icon.
class _GradientButton extends StatelessWidget {
  final VoidCallback onTap;
  final String label;
  final IconData? icon;
  final List<Color> gradient;

  const _GradientButton({
    required this.onTap,
    required this.label,
    required this.gradient,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: gradient.first.withValues(alpha: 0.45),
              blurRadius: 16,
              spreadRadius: 0,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 10),
            ],
            Text(
              label,
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
    );
  }
}

/// Soft drifting color blobs that tint the background with the current
/// page's accent colors. They animate on a slow Lissajous path.
class _BackgroundBlobsPainter extends CustomPainter {
  final double time;
  final List<Color> colors;
  _BackgroundBlobsPainter({required this.time, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < colors.length; i++) {
      final phaseX = time * 0.4 + i * 1.9;
      final phaseY = time * 0.3 + i * 2.5;
      final cx = size.width * (0.5 + 0.38 * math.sin(phaseX));
      final cy = size.height * (0.3 + 0.30 * math.cos(phaseY));
      final radius = size.width * 0.7;
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [
            colors[i].withValues(alpha: 0.22),
            colors[i].withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: radius));
      canvas.drawCircle(Offset(cx, cy), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _BackgroundBlobsPainter old) =>
      old.time != time || old.colors != colors;
}

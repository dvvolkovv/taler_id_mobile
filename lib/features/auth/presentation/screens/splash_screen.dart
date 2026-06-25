import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:taler_id_mobile/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/desktop/animated_blob_background.dart';
import '../../../../core/desktop/desktop_window_chrome.dart';
import '../../../../core/platform/biometric_auth.dart';
import '../../../../core/platform/platform_utils.dart';
import '../../../../core/router/post_login_redirect.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/constants.dart';
import '../../../../core/di/service_locator.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _animController;
  late AnimationController _ringCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeIn);
    _ringCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
    _animController.forward();

    _checkAuthState();
  }

  Future<void> _checkAuthState() async {
    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;

    final storage = sl<SecureStorageService>();

    try {
      final hasToken = await storage.hasRefreshToken;

      if (!hasToken) {
        if (mounted) context.go(RouteConstants.login);
        return;
      }

      final pinEnabled = await storage.isPinEnabled;
      final biometricEnabled = await storage.isBiometricEnabled;

      if (biometricEnabled) {
        final success = await _tryBiometric();
        if (success) {
          if (mounted) await postLoginNavigate(context);
          return;
        }
        if (pinEnabled) {
          if (mounted) context.go(RouteConstants.pinEntry);
          return;
        }
        if (mounted) context.go(RouteConstants.login);
      } else if (pinEnabled) {
        if (mounted) context.go(RouteConstants.pinEntry);
      } else {
        if (mounted) await postLoginNavigate(context);
      }
    } catch (e) {
      // Corrupted storage after reinstall — clear and go to login
      debugPrint('SplashScreen: storage error, clearing: $e');
      try { await storage.clearTokens(); } catch (_) {}
      try { await storage.clearPin(); } catch (_) {}
      if (mounted) context.go(RouteConstants.login);
    }
  }

  Future<bool> _tryBiometric() async {
    try {
      final bio = BiometricAuthPlatform.instance;
      final canAuth = await bio.canCheckBiometrics;
      if (!canAuth) return false;
      return await bio.authenticate(localizedReason: 'Войдите в Taler ID');
    } catch (_) {
      return false;
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    _ringCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = AppColors.of(context);

    final body = FadeTransition(
      opacity: _fadeAnim,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 140,
              height: 140,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Rotating conic-gradient ring
                  AnimatedBuilder(
                    animation: _ringCtrl,
                    builder: (context, _) => Transform.rotate(
                      angle: _ringCtrl.value * 2 * math.pi,
                      child: CustomPaint(
                        size: const Size(128, 128),
                        painter: _SplashRingPainter(
                          colors: const [
                            Color(0xFF22D3EE),
                            Color(0xFFA855F7),
                            Color(0xFFFBBF24),
                            Color(0xFFFB7185),
                            Color(0xFF22D3EE),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Logo container — chrome icon has its own warm glow,
                  // no decorative BoxShadow needed
                  Container(
                    width: 80,
                    height: 80,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        width: 80,
                        height: 80,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.black
                            : Colors.white,
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Image.asset(
                            Theme.of(context).brightness == Brightness.dark
                                ? 'assets/app_icon_dark.png'
                                : 'assets/app_icon_light.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            ShaderMask(
              shaderCallback: (rect) => const LinearGradient(
                colors: [Color(0xFF22D3EE), Color(0xFFA855F7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ).createShader(rect),
              child: const Text(
                'Taler ID',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.appSubtitle,
              style: TextStyle(color: colors.textSecondary, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );

    if (!PlatformUtils.instance.isDesktop) {
      return Scaffold(
        backgroundColor: colors.background,
        body: body,
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Stack(
        children: [
          const Positioned.fill(child: AnimatedBlobBackground()),
          Column(
            children: [
              const DesktopWindowChrome(),
              Expanded(child: Center(child: body)),
            ],
          ),
        ],
      ),
    );
  }
}

class _SplashRingPainter extends CustomPainter {
  final List<Color> colors;
  _SplashRingPainter({required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2 - 3;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final bgPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = Colors.white.withOpacity(0.06);
    canvas.drawCircle(center, radius, bgPaint);

    final arcPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(colors: colors).createShader(rect);
    canvas.drawArc(rect, 0, math.pi * 1.4, false, arcPaint);
  }

  @override
  bool shouldRepaint(covariant _SplashRingPainter old) => false;
}

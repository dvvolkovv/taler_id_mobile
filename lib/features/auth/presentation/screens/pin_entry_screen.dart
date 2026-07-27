import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:taler_id_mobile/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/desktop/desktop_adaptive_scaffold.dart';
import '../../../../core/desktop/desktop_breakpoints.dart';
import '../../../../core/platform/biometric_auth.dart';
import '../../../../core/router/post_login_redirect.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/utils/constants.dart';
import '../widgets/pin_keyboard.dart';

class PinEntryScreen extends StatefulWidget {
  const PinEntryScreen({super.key});

  @override
  State<PinEntryScreen> createState() => _PinEntryScreenState();
}

/// Wrong PINs tolerated before the session is dropped and the password is
/// required again.
const int _kMaxPinAttempts = 5;

class _PinEntryScreenState extends State<PinEntryScreen> {
  String _pin = '';
  String? _error;
  bool _biometricAvailable = false;
  final _storage = sl<SecureStorageService>();

  @override
  void initState() {
    super.initState();
    _checkBiometric();
  }

  Future<void> _checkBiometric() async {
    final biometricEnabled = await _storage.isBiometricEnabled;
    if (biometricEnabled) {
      final bio = BiometricAuthPlatform.instance;
      final canCheck = await bio.canCheckBiometrics;
      final available = canCheck && (await bio.getAvailableBiometrics()).isNotEmpty;
      setState(() => _biometricAvailable = available);
      if (available) _tryBiometric();
    }
  }

  Future<void> _tryBiometric() async {
    try {
      final ok = await BiometricAuthPlatform.instance.authenticate(
        localizedReason: AppLocalizations.of(context)?.biometricLoginReason ?? 'Sign in to Taler ID',
      );
      if (ok && mounted) {
        await postLoginNavigate(context);
      }
    } catch (_) {}
  }

  void _onDigit(String digit) {
    if (_pin.length >= 4) return;
    setState(() {
      _pin += digit;
      _error = null;
    });
    if (_pin.length == 4) {
      Future.delayed(const Duration(milliseconds: 200), _verifyPin);
    }
  }

  void _onDelete() {
    if (_pin.isEmpty) return;
    setState(() {
      _pin = _pin.substring(0, _pin.length - 1);
      _error = null;
    });
  }

  Future<void> _verifyPin() async {
    if (!mounted) return;
    final hash = sha256.convert(utf8.encode(_pin)).toString();
    final storedHash = await _storage.getPinHash();

    if (hash == storedHash) {
      await _storage.resetPinAttempts();
      if (mounted) await postLoginNavigate(context);
      return;
    }

    // The counter lives in secure storage, not in State: it used to reset when
    // the app was killed, so a stolen phone gave an attacker five fresh guesses
    // per relaunch against a 4-digit PIN.
    final attempts = await _storage.incrementPinAttempts();
    if (!mounted) return;

    if (attempts >= _kMaxPinAttempts) {
      // Sending them to the login screen was not enough on its own: the tokens
      // stayed, so the next cold start landed back here with a clean slate.
      // Dropping them makes the password the next barrier, not the PIN.
      await _storage.clearTokens();
      await _storage.clearPin();
      if (!mounted) return;
      context.go(RouteConstants.login);
      return;
    }

    setState(() {
      _pin = '';
      _error = AppLocalizations.of(context)!.pinIncorrect;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return DesktopAdaptiveScaffold(
      cardMaxWidth: kCardWidthForm,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset('app_icon_1024.png', width: 64, height: 64),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Taler ID',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.of(context).textPrimary, fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.enterPin,
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.of(context).textSecondary, fontSize: 16),
          ),
          const SizedBox(height: 32),
          PinDots(filled: _pin.length),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.of(context).error, fontSize: 13),
            ),
          ],
          const SizedBox(height: 32),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: PinKeyboard(
              onDigit: _onDigit,
              onDelete: _onDelete,
              onBiometric: _biometricAvailable ? _tryBiometric : null,
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: TextButton(
              onPressed: () => context.go(RouteConstants.login),
              child: Text(l10n.loginButton, style: TextStyle(color: AppColors.of(context).textSecondary)),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:taler_id_mobile/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:local_auth/local_auth.dart';
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

class _PinEntryScreenState extends State<PinEntryScreen> {
  String _pin = '';
  String? _error;
  int _attempts = 0;
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
      final localAuth = LocalAuthentication();
      final canCheck = await localAuth.canCheckBiometrics;
      final available = canCheck && (await localAuth.getAvailableBiometrics()).isNotEmpty;
      setState(() => _biometricAvailable = available);
      if (available) _tryBiometric();
    }
  }

  Future<void> _tryBiometric() async {
    final localAuth = LocalAuthentication();
    try {
      final ok = await localAuth.authenticate(
        localizedReason: AppLocalizations.of(context)?.biometricLoginReason ?? 'Sign in to Taler ID',
        options: const AuthenticationOptions(biometricOnly: false),
      );
      if (ok && mounted) {
        context.go(RouteConstants.assistant);
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
      if (mounted) context.go(RouteConstants.assistant);
    } else {
      _attempts++;
      if (!mounted) return;
      if (_attempts >= 5) {
        context.go(RouteConstants.login);
      } else {
        setState(() {
          _pin = '';
          _error = AppLocalizations.of(context)!.pinIncorrect;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.of(context).background,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset('app_icon_1024.png', width: 64, height: 64),
            ),
            const SizedBox(height: 16),
            Text(
              'Taler ID',
              style: TextStyle(color: AppColors.of(context).textPrimary, fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.enterPin,
              style: TextStyle(color: AppColors.of(context).textSecondary, fontSize: 16),
            ),
            const SizedBox(height: 32),
            PinDots(filled: _pin.length),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: TextStyle(color: AppColors.of(context).error, fontSize: 13)),
            ],
            const Spacer(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48),
              child: PinKeyboard(
                onDigit: _onDigit,
                onDelete: _onDelete,
                onBiometric: _biometricAvailable ? _tryBiometric : null,
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => context.go(RouteConstants.login),
              child: Text(l10n.loginButton, style: TextStyle(color: AppColors.of(context).textSecondary)),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

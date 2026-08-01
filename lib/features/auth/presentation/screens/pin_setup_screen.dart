import 'package:flutter/material.dart';
import 'package:taler_id_mobile/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/desktop/desktop_adaptive_scaffold.dart';
import '../../../../core/desktop/desktop_breakpoints.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/pin_hasher.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../../../core/di/service_locator.dart';
import '../widgets/pin_keyboard.dart';

class PinSetupScreen extends StatefulWidget {
  const PinSetupScreen({super.key});

  @override
  State<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends State<PinSetupScreen> {
  String _pin = '';
  String? _firstPin;
  bool _confirming = false;
  String? _error;

  void _onDigit(String digit) {
    if (_pin.length >= 4) return;
    setState(() {
      _pin += digit;
      _error = null;
    });
    if (_pin.length == 4) {
      Future.delayed(const Duration(milliseconds: 200), _onPinComplete);
    }
  }

  void _onDelete() {
    if (_pin.isEmpty) return;
    setState(() {
      _pin = _pin.substring(0, _pin.length - 1);
      _error = null;
    });
  }

  Future<void> _onPinComplete() async {
    if (!mounted) return;
    if (!_confirming) {
      setState(() {
        _firstPin = _pin;
        _pin = '';
        _confirming = true;
      });
    } else {
      if (_pin == _firstPin) {
        final hash = await PinHasher.hash(_pin);
        final storage = sl<SecureStorageService>();
        await storage.savePinHash(hash);
        await storage.setPinEnabled(true);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.pinSet), backgroundColor: AppColors.of(context).primary),
          );
          context.pop();
        }
      } else {
        if (!mounted) return;
        setState(() {
          _pin = '';
          _firstPin = null;
          _confirming = false;
          _error = AppLocalizations.of(context)!.pinMismatch;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return DesktopAdaptiveScaffold(
      cardMaxWidth: kCardWidthForm,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Tooltip(
                message: MaterialLocalizations.of(context).backButtonTooltip,
                child: IconButton(
                  icon: Icon(Icons.arrow_back_ios, color: AppColors.of(context).textPrimary),
                  onPressed: () => context.pop(),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                l10n.setupPin,
                style: TextStyle(
                  color: AppColors.of(context).textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Icon(
            _confirming ? Icons.lock_outlined : Icons.pin_outlined,
            color: AppColors.of(context).primary,
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            _confirming ? l10n.confirmPin : l10n.setupPin,
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.of(context).textPrimary, fontSize: 20, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            _confirming ? l10n.confirmPin : l10n.pinCodeDesc,
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.of(context).textSecondary, fontSize: 14),
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
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

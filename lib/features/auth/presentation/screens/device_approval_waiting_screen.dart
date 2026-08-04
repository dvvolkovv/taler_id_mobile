import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:taler_id_mobile/l10n/app_localizations.dart';

import '../../../../core/api/api_exception.dart';
import '../../../../core/desktop/desktop_adaptive_scaffold.dart';
import '../../../../core/desktop/desktop_breakpoints.dart';
import '../../../../core/desktop/hover_lift.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/router/post_login_redirect.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/widgets.dart';
import '../../../../core/utils/constants.dart';
import '../../data/datasources/auth_remote_datasource.dart';

/// Экран, на котором вход ждёт подтверждения с доверенного устройства.
///
/// Токенов у нас ещё нет, поэтому Socket.IO недоступен — состояние узнаём
/// опросом. Раз в три секунды при окне в десять минут это максимум двести
/// запросов, что несопоставимо дешевле, чем городить неаутентифицированный
/// канал реального времени.
class DeviceApprovalWaitingScreen extends StatefulWidget {
  final String approvalToken;
  final int approverCount;
  final bool emailAvailable;
  final int expiresIn;

  const DeviceApprovalWaitingScreen({
    super.key,
    required this.approvalToken,
    required this.approverCount,
    required this.emailAvailable,
    required this.expiresIn,
  });

  @override
  State<DeviceApprovalWaitingScreen> createState() =>
      _DeviceApprovalWaitingScreenState();
}

enum _Outcome { waiting, rejected, expired }

class _DeviceApprovalWaitingScreenState
    extends State<DeviceApprovalWaitingScreen> {
  static const _pollInterval = Duration(seconds: 3);

  Timer? _poll;
  Timer? _countdown;
  late int _secondsLeft;

  _Outcome _outcome = _Outcome.waiting;
  bool _codeRequested = false;
  bool _busy = false;
  String? _error;

  final _codeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _secondsLeft = widget.expiresIn;

    // Не от кого ждать подтверждения — сразу показываем путь через почту,
    // иначе человек смотрел бы на крутилку все десять минут впустую.
    if (widget.approverCount == 0 && widget.emailAvailable) {
      _codeRequested = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _sendEmailCode());
    }

    _poll = Timer.periodic(_pollInterval, (_) => _checkStatus());
    _countdown = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _secondsLeft = (_secondsLeft - 1).clamp(0, 1 << 30));
      if (_secondsLeft == 0) _stopTimers();
    });
  }

  @override
  void dispose() {
    // Оба таймера обязаны умереть вместе с экраном: иначе они переживут его и
    // продолжат дёргать сеть после ухода пользователя.
    _stopTimers();
    _codeController.dispose();
    super.dispose();
  }

  void _stopTimers() {
    _poll?.cancel();
    _poll = null;
    _countdown?.cancel();
    _countdown = null;
  }

  AuthRemoteDataSource get _remote => sl<AuthRemoteDataSource>();

  Future<void> _checkStatus() async {
    if (!mounted || _outcome != _Outcome.waiting) return;
    try {
      final data = await _remote.deviceApprovalStatus(widget.approvalToken);
      await _handleStatus(data);
    } catch (_) {
      // Сорванный опрос — обычное дело в мобильной сети. Следующий тик
      // повторит; показывать ошибку на каждый промах значило бы мигать ею.
    }
  }

  Future<void> _handleStatus(Map<String, dynamic> data) async {
    if (!mounted) return;
    switch (data['status'] as String?) {
      case 'approved':
        _stopTimers();
        await _storeTokensAndEnter(data);
        break;
      case 'rejected':
        _stopTimers();
        setState(() => _outcome = _Outcome.rejected);
        break;
      case 'expired':
        _stopTimers();
        setState(() => _outcome = _Outcome.expired);
        break;
      case 'claimed':
        // Токены забрал параллельный опрос этого же экрана — он уже увёл нас
        // дальше, здесь делать нечего.
        _stopTimers();
        break;
    }
  }

  Future<void> _storeTokensAndEnter(Map<String, dynamic> data) async {
    final access = data['accessToken'] as String?;
    final refresh = data['refreshToken'] as String?;
    if (access == null || refresh == null) return;

    await sl<SecureStorageService>()
        .saveTokens(accessToken: access, refreshToken: refresh);
    if (!mounted) return;
    postLoginNavigate(context);
  }

  Future<void> _sendEmailCode() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await _remote.sendDeviceApprovalEmail(widget.approvalToken);
      if (!mounted) return;
      setState(() {
        _codeRequested = true;
        _busy = false;
      });
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.deviceApprovalEmailSent)),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = e.message;
      });
    }
  }

  Future<void> _submitCode() async {
    if (_codeController.text.length != 6) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final data = await _remote.verifyDeviceApprovalCode(
        approvalToken: widget.approvalToken,
        code: _codeController.text,
      );
      _stopTimers();
      await _handleStatus(data);
      if (mounted) setState(() => _busy = false);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = e.message;
      });
      _codeController.clear();
    }
  }

  String get _countdownLabel {
    final m = _secondsLeft ~/ 60;
    final s = _secondsLeft % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = AppColors.of(context);

    if (_outcome != _Outcome.waiting) {
      return DesktopAdaptiveScaffold(
        cardMaxWidth: kCardWidthForm,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _outcome == _Outcome.rejected ? Icons.block : Icons.timer_off,
              color: colors.error,
              size: 48,
            ),
            const SizedBox(height: 24),
            Text(
              _outcome == _Outcome.rejected
                  ? l10n.deviceApprovalRejected
                  : l10n.deviceApprovalExpired,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 32),
            HoverLift(
              shadowBoost: colors.primary,
              child: LoadingButton(
                text: l10n.deviceApprovalBackToLogin,
                loading: false,
                onPressed: () => context.go(RouteConstants.login),
              ),
            ),
          ],
        ),
      );
    }

    return DesktopAdaptiveScaffold(
      cardMaxWidth: kCardWidthForm,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.phonelink_lock, color: colors.primary, size: 48),
          const SizedBox(height: 24),
          Text(
            l10n.deviceApprovalTitle,
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.approverCount > 0
                ? l10n.deviceApprovalWaiting
                : l10n.deviceApprovalNoApprovers,
            style: TextStyle(color: colors.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              if (widget.approverCount > 0) ...[
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: colors.primary,
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Text(
                l10n.deviceApprovalExpiresIn(_countdownLabel),
                style: TextStyle(color: colors.textSecondary, fontSize: 13),
              ),
            ],
          ),
          if (_error != null) ...[
            const SizedBox(height: 16),
            Text(
              _error!,
              style: TextStyle(color: colors.error, fontSize: 13),
            ),
          ],
          const SizedBox(height: 32),
          if (widget.emailAvailable && !_codeRequested)
            HoverLift(
              shadowBoost: colors.primary,
              child: LoadingButton(
                text: l10n.deviceApprovalSendEmail,
                loading: _busy,
                onPressed: _sendEmailCode,
              ),
            ),
          if (_codeRequested) ...[
            Text(
              l10n.deviceApprovalEnterCode,
              style: TextStyle(color: colors.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _codeController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 28,
                fontWeight: FontWeight.bold,
                letterSpacing: 8,
              ),
              decoration: InputDecoration(
                counterText: '',
                hintText: '000000',
                hintStyle: TextStyle(
                  color: colors.border,
                  letterSpacing: 8,
                  fontSize: 28,
                ),
              ),
              onChanged: (v) {
                if (v.length == 6) _submitCode();
              },
            ),
            const SizedBox(height: 24),
            HoverLift(
              shadowBoost: colors.primary,
              child: LoadingButton(
                text: l10n.verify,
                loading: _busy,
                onPressed: _submitCode,
              ),
            ),
          ],
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => context.go(RouteConstants.login),
            child: Text(
              l10n.deviceApprovalBackToLogin,
              style: TextStyle(color: colors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

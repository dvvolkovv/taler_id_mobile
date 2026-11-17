import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:taler_id_mobile/l10n/app_localizations.dart';

import '../../../../core/api/api_exception.dart';
import '../../../../core/desktop/desktop_adaptive_scaffold.dart';
import '../../../../core/desktop/desktop_breakpoints.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/widgets.dart';
import '../../../../core/utils/constants.dart';
import '../../data/datasources/auth_remote_datasource.dart';

/// Экран «кто-то входит в ваш аккаунт», открываемый тапом по уведомлению.
///
/// Отдельный маршрут, а не модальный лист: уведомление могут открыть с
/// холодного старта, когда живого BuildContext для листа ещё нет, — go_router
/// этот случай уже обрабатывает.
class DeviceApprovalRequestScreen extends StatefulWidget {
  final String approvalId;
  final String deviceInfo;
  final String ip;
  final String location;

  /// Когда запрос истекает. Нет у пушей от бэкенда старше 2026-11-17.
  final DateTime? expiresAt;

  const DeviceApprovalRequestScreen({
    super.key,
    required this.approvalId,
    required this.deviceInfo,
    required this.ip,
    required this.location,
    this.expiresAt,
  });

  @override
  State<DeviceApprovalRequestScreen> createState() =>
      _DeviceApprovalRequestScreenState();
}

class _DeviceApprovalRequestScreenState
    extends State<DeviceApprovalRequestScreen> {
  bool _busy = false;
  String? _error;
  String? _done;

  /// Запрос истёк или на него уже ответили. Уведомление легко открыть через
  /// несколько часов, а запрос живёт 10 минут: без этого обе кнопки отвечали
  /// сырым «Approval request not found» (2026-11-17).
  bool _stale = false;

  @override
  void initState() {
    super.initState();
    // По часам телефона судим только при открытии — чтобы не предлагать
    // кнопки к запросу многочасовой давности. Дальше решает сервер: часы
    // могут спешить, а живой запрос отклонять из-за них нельзя.
    final deadline = widget.expiresAt;
    _stale = deadline != null && !DateTime.now().isBefore(deadline);
  }

  Future<void> _respond({required bool allow}) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final l10n = AppLocalizations.of(context)!;
    try {
      final remote = sl<AuthRemoteDataSource>();
      if (allow) {
        await remote.approveDevice(widget.approvalId);
      } else {
        await remote.rejectDevice(widget.approvalId);
      }
      if (!mounted) return;
      setState(() {
        _busy = false;
        _done = allow ? l10n.deviceApprovalApproved : l10n.deviceApprovalDenied;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        // 404 — это и «истёк», и «уже ответили с другого устройства», и чужой
        // approvalId: сервер намеренно их не различает. Для человека всё это
        // одно — отвечать уже не на что.
        if (e.isNotFound) {
          _stale = true;
        } else {
          _error = e.message;
        }
      });
    }
  }

  void _leave() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(RouteConstants.dashboard);
    }
  }

  Widget _row(BuildContext context, IconData icon, String value) {
    final colors = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: colors.textSecondary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: colors.textPrimary, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  /// Конечный экран: ответ отправлен или отвечать уже не на что.
  Widget _outcome(
    BuildContext context,
    IconData icon,
    String title, {
    String? body,
  }) {
    final colors = AppColors.of(context);
    return DesktopAdaptiveScaffold(
      cardMaxWidth: kCardWidthForm,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: colors.primary, size: 48),
          const SizedBox(height: 24),
          Text(
            title,
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (body != null) ...[
            const SizedBox(height: 8),
            Text(
              body,
              style: TextStyle(color: colors.textSecondary, fontSize: 14),
            ),
          ],
          const SizedBox(height: 32),
          LoadingButton(
            text: MaterialLocalizations.of(context).closeButtonLabel,
            loading: false,
            onPressed: _leave,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = AppColors.of(context);

    if (_done != null) {
      return _outcome(context, Icons.check_circle_outline, _done!);
    }
    if (_stale) {
      return _outcome(
        context,
        Icons.timer_off_outlined,
        l10n.deviceApprovalStaleTitle,
        body: l10n.deviceApprovalStaleBody,
      );
    }

    return DesktopAdaptiveScaffold(
      cardMaxWidth: kCardWidthForm,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.gpp_maybe, color: colors.primary, size: 48),
          const SizedBox(height: 24),
          Text(
            l10n.deviceApprovalSheetTitle,
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.deviceApprovalSheetBody,
            style: TextStyle(color: colors.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 24),
          if (widget.deviceInfo.isNotEmpty)
            _row(context, Icons.smartphone, widget.deviceInfo),
          if (widget.location.isNotEmpty)
            _row(context, Icons.place_outlined, widget.location),
          if (widget.ip.isNotEmpty) _row(context, Icons.language, widget.ip),
          if (_error != null) ...[
            const SizedBox(height: 16),
            Text(_error!, style: TextStyle(color: colors.error, fontSize: 13)),
          ],
          const SizedBox(height: 32),
          // «Это не я» стоит первой и красной: в этом диалоге дорого ошибиться
          // именно в сторону «разрешить».
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: colors.error),
              onPressed: _busy ? null : () => _respond(allow: false),
              icon: const Icon(Icons.block),
              label: Text(l10n.deviceApprovalDeny),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _busy ? null : () => _respond(allow: true),
              icon: const Icon(Icons.check),
              label: Text(l10n.deviceApprovalAllow),
            ),
          ),
        ],
      ),
    );
  }
}

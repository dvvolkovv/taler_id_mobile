import 'dart:async';

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/interpreter_code.dart';
import 'interpreter_texts.dart';

/// Host-side waiting screen: a QR of `talerid://interp/<code>` plus a
/// 5-minute countdown to the code's `expiresAt`. Ticks once a second so the
/// countdown and the "expired" swap happen live without the bloc re-polling
/// anything — the code's lifetime is entirely client-computable from
/// [expiresAt].
class QrView extends StatefulWidget {
  final String code;
  final DateTime expiresAt;
  final VoidCallback onNewCode;

  /// Injectable clock for deterministic tests; defaults to the wall clock.
  final DateTime Function() now;

  const QrView({
    super.key,
    required this.code,
    required this.expiresAt,
    required this.onNewCode,
    this.now = DateTime.now,
  });

  @override
  State<QrView> createState() => _QrViewState();
}

class _QrViewState extends State<QrView> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final l10n = AppLocalizations.of(context)!;
    final remaining = widget.expiresAt.difference(widget.now());
    final expired = remaining <= Duration.zero;

    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.interpreterShowCode,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: QrImageView(
                  data: interpreterLink(widget.code),
                  version: QrVersions.auto,
                  size: 220,
                  backgroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                expired
                    ? l10n.interpreterCodeExpiredShort
                    : interpreterFormatDuration(remaining),
                style: TextStyle(
                  color: expired ? colors.error : colors.textSecondary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.interpreterWaitingForPartner,
                style: TextStyle(color: colors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  onPressed: widget.onNewCode,
                  child: Text(l10n.interpreterNewCode),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taler_id_mobile/l10n/app_localizations.dart';
import '../../../../core/platform/kyc_launcher.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/error_keys.dart';
import '../bloc/kyc_bloc.dart';
import '../bloc/kyc_event.dart';
import '../bloc/kyc_state.dart';
import '../widgets/sumsub_data_card.dart';

class KycScreen extends StatefulWidget {
  const KycScreen({super.key});

  @override
  State<KycScreen> createState() => _KycScreenState();
}

class _KycScreenState extends State<KycScreen> {
  @override
  void initState() {
    super.initState();
    context.read<KycBloc>().add(KycStatusRequested());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.of(context).background,
      appBar: AppBar(title: Text(l10n.kycTitle)),
      body: BlocConsumer<KycBloc, KycState>(
        listener: (context, state) {
          if (state is KycSdkReady) {
            _launchSumsub(context, webSdkUrl: state.webSdkUrl);
          } else if (state is KycError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(resolveErrorMessage(AppLocalizations.of(context)!, state.message)),
                backgroundColor: AppColors.of(context).error,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is KycLoading) {
            return Center(child: CircularProgressIndicator(color: AppColors.of(context).primary));
          }
          if (state is KycSdkDone) return _buildWaiting(l10n);
          if (state is KycApplicantDataLoading) return _buildStatusBody(context, state.status, state.verifiedAt, null, l10n, loading: true);
          if (state is KycStatusLoaded) return _buildStatusBody(context, state.status, state.verifiedAt, state, l10n);
          if (state is KycError) return _buildError(context, resolveErrorMessage(l10n, state.message), l10n);
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildStatusBody(
    BuildContext context,
    String status,
    String? verifiedAt,
    KycStatusLoaded? loaded,
    AppLocalizations l10n, {
    bool loading = false,
  }) {
    final inProgress = loaded?.inProgress ?? false;
    final cfg = _getStatusConfig(status, l10n, inProgress: inProgress);
    final colors = AppColors.of(context);

    return RefreshIndicator(
      color: colors.primary,
      onRefresh: () async => context.read<KycBloc>().add(KycStatusRequested()),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // ── Hero header ──
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  cfg.color.withValues(alpha: 0.18),
                  cfg.color.withValues(alpha: 0.04),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Column(
              children: [
                // Big icon ring
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: cfg.color.withValues(alpha: 0.12),
                    border: Border.all(color: cfg.color.withValues(alpha: 0.35), width: 2),
                    boxShadow: [BoxShadow(color: cfg.color.withValues(alpha: 0.2), blurRadius: 20, spreadRadius: 2)],
                  ),
                  child: Icon(cfg.icon, color: cfg.color, size: 44),
                ),
                const SizedBox(height: 20),
                // Status pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: cfg.color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: cfg.color.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(width: 7, height: 7, decoration: BoxDecoration(color: cfg.color, shape: BoxShape.circle)),
                      const SizedBox(width: 6),
                      Text(cfg.label, style: TextStyle(color: cfg.color, fontSize: 13, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  cfg.description,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: colors.textSecondary, fontSize: 14, height: 1.5),
                ),
                if (verifiedAt != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    l10n.verifiedAt(_formatDate(verifiedAt)),
                    style: TextStyle(color: colors.textSecondary, fontSize: 12),
                  ),
                ],
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Steps progress
                _buildStepsCard(status, l10n, colors),
                const SizedBox(height: 16),

                // Rejection reason
                if (loaded?.rejectionReason != null) ...[
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: colors.error.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: colors.error.withValues(alpha: 0.25)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.warning_amber_rounded, color: colors.error, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            loaded!.rejectionReason!,
                            style: TextStyle(color: colors.textSecondary, fontSize: 13, height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Action button. PENDING also gets a "continue" button — the
                // wizard can always be reopened (it just shows the review
                // status if the applicant is genuinely under review), so an
                // abandoned session never dead-ends the user.
                if (status == 'UNVERIFIED' || status == 'REJECTED' || status == 'PENDING')
                  _ActionButton(
                    label: status == 'REJECTED'
                        ? l10n.retryVerification
                        : (inProgress || status == 'PENDING')
                            ? l10n.continueVerification
                            : l10n.startVerification,
                    icon: status == 'REJECTED'
                        ? Icons.refresh_rounded
                        : (inProgress || status == 'PENDING')
                            ? Icons.play_arrow_rounded
                            : Icons.verified_user_outlined,
                    color: cfg.color,
                    onTap: () => context.read<KycBloc>().add(KycStartRequested()),
                  ),

                // Loading spinner (applicant data)
                if (loading) ...[
                  const SizedBox(height: 24),
                  Center(
                    child: Column(
                      children: [
                        CircularProgressIndicator(strokeWidth: 2, color: colors.primary),
                        const SizedBox(height: 12),
                        Text(l10n.sumsubDataLoading, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
                      ],
                    ),
                  ),
                ],

                // Verified data
                if (loaded?.status == 'VERIFIED' && loaded?.applicantData != null) ...[
                  const SizedBox(height: 8),
                  SumsubDataCard(data: loaded!.applicantData!),
                  const SizedBox(height: 8),
                  Center(
                    child: TextButton.icon(
                      onPressed: () => context.read<KycBloc>().add(KycApplicantDataRequested()),
                      icon: Icon(Icons.refresh, size: 16, color: colors.textSecondary),
                      label: Text(l10n.refreshData, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
                    ),
                  ),
                ],

                // Info rows
                const SizedBox(height: 16),
                _buildInfoCard(l10n, colors),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepsCard(String status, AppLocalizations l10n, AppColorsExtension colors) {
    final steps = [
      _StepData('Документы', status != 'UNVERIFIED'),
      _StepData('Проверка', status == 'VERIFIED' || status == 'PENDING'),
      _StepData('Готово', status == 'VERIFIED'),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: List.generate(steps.length * 2 - 1, (i) {
          if (i.isOdd) {
            final prevDone = steps[i ~/ 2].done;
            return Expanded(
              child: Container(
                height: 2,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: prevDone ? colors.primary : colors.border,
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            );
          }
          final step = steps[i ~/ 2];
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: step.done ? colors.primary.withValues(alpha: 0.15) : colors.surface,
                  border: Border.all(
                    color: step.done ? colors.primary : colors.border,
                    width: step.done ? 1.5 : 1,
                  ),
                ),
                child: Icon(
                  step.done ? Icons.check_rounded : Icons.circle_outlined,
                  size: 16,
                  color: step.done ? colors.primary : colors.textSecondary,
                ),
              ),
              const SizedBox(height: 6),
              Text(step.label, style: TextStyle(color: step.done ? colors.textPrimary : colors.textSecondary, fontSize: 10, fontWeight: step.done ? FontWeight.w600 : FontWeight.normal)),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildInfoCard(AppLocalizations l10n, AppColorsExtension colors) {
    final rows = [
      _InfoRowData(Icons.security_outlined, const Color(0xFF2563EB), l10n.securityAes),
      _InfoRowData(Icons.schedule_outlined, const Color(0xFFD97706), l10n.verificationTime),
      _InfoRowData(Icons.notifications_outlined, const Color(0xFF7C3AED), l10n.pushNotification),
    ];

    return Container(
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: List.generate(rows.length * 2 - 1, (i) {
          if (i.isOdd) return Divider(color: colors.border, height: 1, indent: 56);
          final row = rows[i ~/ 2];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: row.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(row.icon, color: row.color, size: 18),
                ),
                const SizedBox(width: 14),
                Expanded(child: Text(row.label, style: TextStyle(color: colors.textSecondary, fontSize: 13, height: 1.4))),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildWaiting(AppLocalizations l10n) {
    final colors = AppColors.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colors.primary.withValues(alpha: 0.1),
                border: Border.all(color: colors.primary.withValues(alpha: 0.3), width: 2),
              ),
              child: Icon(Icons.hourglass_top_rounded, color: colors.primary, size: 40),
            ),
            const SizedBox(height: 24),
            Text(l10n.documentsSubmitted, textAlign: TextAlign.center,
                style: TextStyle(color: colors.textPrimary, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text(l10n.documentsSubmittedDesc, textAlign: TextAlign.center,
                style: TextStyle(color: colors.textSecondary, fontSize: 14, height: 1.5)),
          ],
        ),
      ),
    );
  }

  Widget _buildError(BuildContext context, String message, AppLocalizations l10n) {
    final colors = AppColors.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(shape: BoxShape.circle, color: colors.error.withValues(alpha: 0.1)),
              child: Icon(Icons.error_outline, color: colors.error, size: 36),
            ),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center, style: TextStyle(color: colors.textSecondary, fontSize: 14)),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () => context.read<KycBloc>().add(KycStatusRequested()),
              icon: const Icon(Icons.refresh, size: 18),
              label: Text(l10n.retry),
            ),
          ],
        ),
      ),
    );
  }

  _StatusConfig _getStatusConfig(String status, AppLocalizations l10n, {bool inProgress = false}) {
    switch (status) {
      case 'VERIFIED':
        return _StatusConfig(icon: Icons.verified_rounded, color: const Color(0xFF22C55E), label: l10n.kycVerified, description: l10n.kycVerifiedDesc);
      case 'PENDING':
        return _StatusConfig(icon: Icons.hourglass_empty_rounded, color: const Color(0xFFF59E0B), label: l10n.kycPending, description: l10n.kycPendingDesc);
      case 'REJECTED':
        return _StatusConfig(icon: Icons.cancel_rounded, color: const Color(0xFFEF4444), label: l10n.kycRejected, description: l10n.kycRejectedDesc);
      default:
        if (inProgress) {
          return _StatusConfig(icon: Icons.edit_note_rounded, color: const Color(0xFFF59E0B), label: l10n.kycInProgress, description: l10n.kycInProgressDesc);
        }
        return _StatusConfig(icon: Icons.person_outline_rounded, color: const Color(0xFF64748B), label: l10n.kycUnverified, description: l10n.kycUnverifiedDesc);
    }
  }

  String _formatDate(String isoDate) {
    try {
      final dt = DateTime.parse(isoDate);
      return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
    } catch (_) {
      return isoDate;
    }
  }

  void _launchSumsub(BuildContext context, {required String webSdkUrl}) async {
    if (kIsWeb) {
      // Web: cannot embed mock_ss in an iframe from inside a Flutter web app
      // without extra CSP work — direct users to the native/desktop apps.
      final l10n = AppLocalizations.of(context)!;
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: AppColors.of(context).card,
          title: Text(l10n.verification, style: TextStyle(color: AppColors.of(context).textPrimary)),
          content: Text(l10n.kycWebOnly, style: TextStyle(color: AppColors.of(context).textSecondary)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.ok, style: TextStyle(color: AppColors.of(context).primary)),
            ),
          ],
        ),
      );
      return;
    }

    final bloc = context.read<KycBloc>();
    final result = await KycLauncherPlatform.instance.launch(webSdkUrl: webSdkUrl);
    if (!mounted) return;
    if (result.skipped) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('KYC verification is not available on this platform')),
      );
      return;
    }
    if (result.success) {
      bloc.add(KycSdkCompleted());
    } else if (result.errorMessage != null) {
      bloc.add(KycSdkFailed(result.errorType ?? 'unknown'));
    }
    bloc.add(KycStatusRequested());
  }
}

// ── Helper widgets ───────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _ActionButton({required this.label, required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [color, Color.lerp(color, Colors.black, 0.2)!], begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: color.withValues(alpha: 0.35), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

// ── Data classes ─────────────────────────────────────────────────

class _StatusConfig {
  final IconData icon;
  final Color color;
  final String label;
  final String description;
  const _StatusConfig({required this.icon, required this.color, required this.label, required this.description});
}

class _StepData {
  final String label;
  final bool done;
  const _StepData(this.label, this.done);
}

class _InfoRowData {
  final IconData icon;
  final Color color;
  final String label;
  const _InfoRowData(this.icon, this.color, this.label);
}

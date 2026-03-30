import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taler_id_mobile/l10n/app_localizations.dart';
import 'package:flutter_idensic_mobile_sdk_plugin/flutter_idensic_mobile_sdk_plugin.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/widgets.dart';
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
            // Launch Sumsub SDK
            _launchSumsub(context, state.sdkToken);
          } else if (state is KycError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(resolveErrorMessage(AppLocalizations.of(context)!, state.message)), backgroundColor: AppColors.of(context).error),
            );
          }
        },
        builder: (context, state) {
          if (state is KycLoading) {
            return Center(child: CircularProgressIndicator(color: AppColors.of(context).primary));
          }

          if (state is KycSdkDone) {
            return _buildWaiting(l10n);
          }

          if (state is KycApplicantDataLoading) {
            return _buildStatusWithLoading(context, state, l10n);
          }

          if (state is KycStatusLoaded) {
            return _buildStatus(context, state, l10n);
          }

          if (state is KycError) {
            return _buildError(context, resolveErrorMessage(l10n, state.message), l10n);
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildStatus(BuildContext context, KycStatusLoaded state, AppLocalizations l10n) {
    final statusConfig = _getStatusConfig(state.status, l10n);

    return RefreshIndicator(
      color: AppColors.of(context).primary,
      onRefresh: () async => context.read<KycBloc>().add(KycStatusRequested()),
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 32),
          // Status icon
          Center(
            child: Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: statusConfig.color.withOpacity(0.15),
                shape: BoxShape.circle,
                border: Border.all(color: statusConfig.color.withOpacity(0.4), width: 2),
              ),
              child: Icon(statusConfig.icon, color: statusConfig.color, size: 48),
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: StatusBadge(label: statusConfig.label, color: statusConfig.color),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              statusConfig.description,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.of(context).textSecondary, fontSize: 14, height: 1.5),
            ),
          ),
          if (state.verifiedAt != null) ...[
            const SizedBox(height: 8),
            Center(
              child: Text(
                l10n.verifiedAt(_formatDate(state.verifiedAt!)),
                style: TextStyle(color: AppColors.of(context).textSecondary, fontSize: 12),
              ),
            ),
          ],
          if (state.rejectionReason != null) ...[
            const SizedBox(height: 16),
            AppCard(
              child: Row(
                children: [
                  Icon(Icons.info_outlined, color: AppColors.of(context).warning, size: 18),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      state.rejectionReason!,
                      style: TextStyle(color: AppColors.of(context).textSecondary, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 40),
          if (state.status == 'UNVERIFIED' || state.status == 'REJECTED') ...[
            LoadingButton(
              text: state.status == 'REJECTED' ? l10n.retryVerification : l10n.startVerification,
              loading: false,
              onPressed: () => context.read<KycBloc>().add(KycStartRequested()),
            ),
          ],
          const SizedBox(height: 16),
          // Verified applicant data
          if (state.status == 'VERIFIED' && state.applicantData != null) ...[
            SumsubDataCard(data: state.applicantData!),
            const SizedBox(height: 12),
            Center(
              child: TextButton.icon(
                onPressed: () => context.read<KycBloc>().add(KycApplicantDataRequested()),
                icon: Icon(Icons.refresh, size: 18, color: AppColors.of(context).textSecondary),
                label: Text(l10n.refreshData, style: TextStyle(color: AppColors.of(context).textSecondary, fontSize: 13)),
              ),
            ),
            const SizedBox(height: 16),
          ],
          // Info card
          AppCard(
            child: Column(
              children: [
                _infoRow(Icons.security_outlined, l10n.securityAes),
                Divider(color: AppColors.of(context).border, height: 1),
                _infoRow(Icons.schedule_outlined, l10n.verificationTime),
                Divider(color: AppColors.of(context).border, height: 1),
                _infoRow(Icons.notifications_outlined, l10n.pushNotification),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusWithLoading(BuildContext context, KycApplicantDataLoading state, AppLocalizations l10n) {
    final statusConfig = _getStatusConfig(state.status, l10n);

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 32),
        Center(
          child: Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: statusConfig.color.withOpacity(0.15),
              shape: BoxShape.circle,
              border: Border.all(color: statusConfig.color.withOpacity(0.4), width: 2),
            ),
            child: Icon(statusConfig.icon, color: statusConfig.color, size: 48),
          ),
        ),
        const SizedBox(height: 24),
        Center(child: StatusBadge(label: statusConfig.label, color: statusConfig.color)),
        const SizedBox(height: 16),
        Center(
          child: Text(
            statusConfig.description,
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.of(context).textSecondary, fontSize: 14, height: 1.5),
          ),
        ),
        if (state.verifiedAt != null) ...[
          const SizedBox(height: 8),
          Center(
            child: Text(
              l10n.verifiedAt(_formatDate(state.verifiedAt!)),
              style: TextStyle(color: AppColors.of(context).textSecondary, fontSize: 12),
            ),
          ),
        ],
        const SizedBox(height: 40),
        Center(
          child: Column(
            children: [
              CircularProgressIndicator(color: AppColors.of(context).primary),
              const SizedBox(height: 12),
              Text(
                l10n.sumsubDataLoading,
                style: TextStyle(color: AppColors.of(context).textSecondary, fontSize: 13),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWaiting(AppLocalizations l10n) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: AppColors.of(context).primary),
              const SizedBox(height: 24),
              Text(
                l10n.documentsSubmitted,
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.of(context).textPrimary, fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              Text(
                l10n.documentsSubmittedDesc,
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.of(context).textSecondary, fontSize: 14, height: 1.5),
              ),
            ],
          ),
        ),
      );

  Widget _buildError(BuildContext context, String message, AppLocalizations l10n) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: AppColors.of(context).error, size: 48),
              const SizedBox(height: 16),
              Text(message, textAlign: TextAlign.center, style: TextStyle(color: AppColors.of(context).textSecondary)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.read<KycBloc>().add(KycStatusRequested()),
                child: Text(l10n.retry),
              ),
            ],
          ),
        ),
      );

  Widget _infoRow(IconData icon, String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: AppColors.of(context).secondary, size: 18),
            const SizedBox(width: 12),
            Expanded(child: Text(text, style: TextStyle(color: AppColors.of(context).textSecondary, fontSize: 13))),
          ],
        ),
      );

  _StatusConfig _getStatusConfig(String status, AppLocalizations l10n) {
    switch (status) {
      case 'VERIFIED':
        return _StatusConfig(
          icon: Icons.verified_outlined,
          color: AppColors.of(context).primary,
          label: l10n.kycVerified,
          description: l10n.kycVerifiedDesc,
        );
      case 'PENDING':
        return _StatusConfig(
          icon: Icons.hourglass_empty_outlined,
          color: AppColors.of(context).warning,
          label: l10n.kycPending,
          description: l10n.kycPendingDesc,
        );
      case 'REJECTED':
        return _StatusConfig(
          icon: Icons.cancel_outlined,
          color: AppColors.of(context).error,
          label: l10n.kycRejected,
          description: l10n.kycRejectedDesc,
        );
      default:
        return _StatusConfig(
          icon: Icons.person_outlined,
          color: AppColors.of(context).textSecondary,
          label: l10n.kycUnverified,
          description: l10n.kycUnverifiedDesc,
        );
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

  void _launchSumsub(BuildContext context, String sdkToken) async {
    // Sumsub SDK is native-only, show stub on web
    if (kIsWeb) {
      final l10n = AppLocalizations.of(context)!;
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: AppColors.of(context).card,
          title: Text(l10n.verification, style: TextStyle(color: AppColors.of(context).textPrimary)),
          content: Text(
            l10n.kycWebOnly,
            style: TextStyle(color: AppColors.of(context).textSecondary),
          ),
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

    final onTokenExpiration = () async {
      return await bloc.repo.startKyc();
    };

    final snsMobileSDK = SNSMobileSDK.init(sdkToken, onTokenExpiration)
        .withLocale(const Locale('ru'))
        .withDebug(true)
        .build();

    final SNSMobileSDKResult result = await snsMobileSDK.launch();

    if (!mounted) return;

    if (result.success) {
      bloc.add(KycSdkCompleted());
    } else if (result.errorMsg != null) {
      bloc.add(KycSdkFailed(result.errorType?.toString() ?? 'unknown'));
    }
    // Refresh status after SDK closes
    bloc.add(KycStatusRequested());
  }
}

class _StatusConfig {
  final IconData icon;
  final Color color;
  final String label;
  final String description;
  const _StatusConfig({required this.icon, required this.color, required this.label, required this.description});
}

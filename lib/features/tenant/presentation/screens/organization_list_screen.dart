import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taler_id_mobile/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/widgets.dart';
import '../../../../core/utils/constants.dart';
import '../../../../core/utils/error_keys.dart';
import '../../domain/entities/tenant_entity.dart';
import '../bloc/tenant_bloc.dart';
import '../bloc/tenant_event.dart';
import '../bloc/tenant_state.dart';

class OrganizationListScreen extends StatefulWidget {
  const OrganizationListScreen({super.key});

  @override
  State<OrganizationListScreen> createState() => _OrganizationListScreenState();
}

class _OrganizationListScreenState extends State<OrganizationListScreen> {
  @override
  void initState() {
    super.initState();
    context.read<TenantBloc>().add(TenantsLoadRequested());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.of(context).background,
      appBar: AppBar(
        title: Text(l10n.organizations),
        actions: [
          IconButton(
            icon: Icon(Icons.add, color: AppColors.of(context).primary),
            onPressed: () => _showCreateDialog(context),
          ),
        ],
      ),
      body: BlocConsumer<TenantBloc, TenantState>(
        listener: (context, state) {
          if (state is TenantError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(resolveErrorMessage(l10n, state.message)), backgroundColor: AppColors.of(context).error),
            );
          }
        },
        builder: (context, state) {
          if (state is TenantLoading) {
            return Center(child: CircularProgressIndicator(color: AppColors.of(context).primary));
          }

          if (state is TenantsLoaded) {
            if (state.tenants.isEmpty) {
              return _buildEmpty(context);
            }
            return RefreshIndicator(
              color: AppColors.of(context).primary,
              onRefresh: () async => context.read<TenantBloc>().add(TenantsLoadRequested()),
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: state.tenants.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, i) => _buildCard(context, state.tenants[i]),
              ),
            );
          }

          return _buildEmpty(context);
        },
      ),
    );
  }

  Widget _buildCard(BuildContext context, TenantEntity tenant) {
    final l10n = AppLocalizations.of(context)!;
    final kybColor = _kybColor(tenant.kybStatus);
    final kybLabel = _kybLabel(tenant.kybStatus, l10n);
    final roleLabel = _roleLabel(tenant.myRole, l10n);

    return GestureDetector(
      onTap: () async {
        await context.push(
          RouteConstants.organizationDetail.replaceFirst(':id', tenant.id),
        );
        if (mounted) {
          context.read<TenantBloc>().add(TenantsLoadRequested());
        }
      },
      child: AppCard(
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.of(context).primary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.business_outlined, color: AppColors.of(context).primary, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tenant.name,
                      style: TextStyle(color: AppColors.of(context).textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      StatusBadge(label: kybLabel, color: kybColor),
                      const SizedBox(width: 8),
                      if (roleLabel != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.of(context).secondary.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(roleLabel,
                              style: TextStyle(color: AppColors.of(context).secondary, fontSize: 11, fontWeight: FontWeight.w500)),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: AppColors.of(context).textSecondary),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.business_outlined, color: AppColors.of(context).textSecondary, size: 64),
            const SizedBox(height: 16),
            Text(l10n.noOrganizations, style: TextStyle(color: AppColors.of(context).textPrimary, fontSize: 18)),
            const SizedBox(height: 8),
            Text(l10n.noOrganizationsDesc,
                textAlign: TextAlign.center, style: TextStyle(color: AppColors.of(context).textSecondary, fontSize: 14)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _showCreateDialog(context),
              icon: const Icon(Icons.add),
              label: Text(l10n.createOrganization),
            ),
          ],
        ),
      );
  }

  void _showCreateDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final websiteCtrl = TextEditingController();
    final addressCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.of(context).card,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 24, right: 24, top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.newOrganization,
                  style: TextStyle(color: AppColors.of(context).textPrimary, fontSize: 20, fontWeight: FontWeight.w600)),
              const SizedBox(height: 20),
              TextField(
                controller: nameCtrl,
                style: TextStyle(color: AppColors.of(context).textPrimary),
                decoration: InputDecoration(labelText: l10n.orgName),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailCtrl,
                keyboardType: TextInputType.emailAddress,
                style: TextStyle(color: AppColors.of(context).textPrimary),
                decoration: InputDecoration(labelText: l10n.orgEmail),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: websiteCtrl,
                keyboardType: TextInputType.url,
                style: TextStyle(color: AppColors.of(context).textPrimary),
                decoration: InputDecoration(labelText: l10n.orgWebsite),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: addressCtrl,
                style: TextStyle(color: AppColors.of(context).textPrimary),
                decoration: InputDecoration(labelText: l10n.orgLegalAddress),
                maxLines: 2,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (nameCtrl.text.trim().isNotEmpty) {
                      context.read<TenantBloc>().add(TenantCreateSubmitted({
                        'name': nameCtrl.text.trim(),
                        if (emailCtrl.text.trim().isNotEmpty) 'email': emailCtrl.text.trim(),
                        if (websiteCtrl.text.trim().isNotEmpty) 'website': websiteCtrl.text.trim(),
                        if (addressCtrl.text.trim().isNotEmpty) 'legalAddress': addressCtrl.text.trim(),
                      }));
                      Navigator.pop(ctx);
                    }
                  },
                  child: Text(l10n.create),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _kybColor(KybStatus status) {
    switch (status) {
      case KybStatus.verified: return AppColors.of(context).primary;
      case KybStatus.pending: return AppColors.of(context).warning;
      case KybStatus.rejected: return AppColors.of(context).error;
      default: return AppColors.of(context).textSecondary;
    }
  }

  String _kybLabel(KybStatus status, AppLocalizations l10n) {
    switch (status) {
      case KybStatus.verified: return l10n.kybVerified;
      case KybStatus.pending: return l10n.kybPending;
      case KybStatus.rejected: return l10n.kybRejected;
      default: return l10n.noKyb;
    }
  }

  String? _roleLabel(TenantRole? role, AppLocalizations l10n) {
    switch (role) {
      case TenantRole.owner: return l10n.roleOwner;
      case TenantRole.admin: return l10n.roleAdmin;
      case TenantRole.operator: return l10n.roleOperator;
      case TenantRole.viewer: return l10n.roleViewer;
      default: return null;
    }
  }
}

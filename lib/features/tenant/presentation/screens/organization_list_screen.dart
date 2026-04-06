import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taler_id_mobile/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
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
    final colors = AppColors.of(context);
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: Text(l10n.organizations),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => _showCreateDialog(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: colors.primary.withValues(alpha: 0.25)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_rounded, color: colors.primary, size: 16),
                    const SizedBox(width: 4),
                    Text(l10n.createOrganization, style: TextStyle(color: colors.primary, fontSize: 13, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: BlocConsumer<TenantBloc, TenantState>(
        listener: (context, state) {
          if (state is TenantError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(resolveErrorMessage(l10n, state.message)), backgroundColor: colors.error),
            );
          }
        },
        builder: (context, state) {
          if (state is TenantLoading) {
            return Center(child: CircularProgressIndicator(color: colors.primary));
          }
          if (state is TenantsLoaded) {
            if (state.tenants.isEmpty) return _buildEmpty(context);
            return RefreshIndicator(
              color: colors.primary,
              onRefresh: () async => context.read<TenantBloc>().add(TenantsLoadRequested()),
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                itemCount: state.tenants.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) => _buildCard(context, state.tenants[i]),
              ),
            );
          }
          return _buildEmpty(context);
        },
      ),
    );
  }

  static const List<List<Color>> _cardGradients = [
    [Color(0xFF2563EB), Color(0xFF1E40AF)],
    [Color(0xFF7C3AED), Color(0xFF5B21B6)],
    [Color(0xFF059669), Color(0xFF065F46)],
    [Color(0xFFD97706), Color(0xFFB45309)],
    [Color(0xFFDC2626), Color(0xFF991B1B)],
    [Color(0xFF0891B2), Color(0xFF0E7490)],
  ];

  List<Color> _gradientFor(String id) {
    final idx = id.codeUnitAt(0) % _cardGradients.length;
    return _cardGradients[idx];
  }

  Widget _buildCard(BuildContext context, TenantEntity tenant) {
    final l10n = AppLocalizations.of(context)!;
    final colors = AppColors.of(context);
    final kybColor = _kybColor(tenant.kybStatus, colors);
    final kybLabel = _kybLabel(tenant.kybStatus, l10n);
    final roleLabel = _roleLabel(tenant.myRole, l10n);
    final gradient = _gradientFor(tenant.id);
    final initials = tenant.name.isNotEmpty ? tenant.name[0].toUpperCase() : '?';

    return GestureDetector(
      onTap: () async {
        await context.push(RouteConstants.organizationDetail.replaceFirst(':id', tenant.id));
        if (mounted) context.read<TenantBloc>().add(TenantsLoadRequested());
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.border.withValues(alpha: 0.5)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Row(
          children: [
            // Gradient initials avatar
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: gradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(color: gradient[0].withValues(alpha: 0.35), blurRadius: 10, offset: const Offset(0, 3))],
              ),
              child: Center(
                child: Text(initials, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tenant.name,
                    style: TextStyle(color: colors.textPrimary, fontSize: 15, fontWeight: FontWeight.w700),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      _StatusPill(label: kybLabel, color: kybColor),
                      if (roleLabel != null) _RolePill(label: roleLabel, colors: colors),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right_rounded, color: colors.textSecondary, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
                color: colors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(color: colors.primary.withValues(alpha: 0.2), width: 2),
              ),
              child: Icon(Icons.business_outlined, color: colors.primary, size: 38),
            ),
            const SizedBox(height: 20),
            Text(l10n.noOrganizations, style: TextStyle(color: colors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              l10n.noOrganizationsDesc,
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.textSecondary, fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 28),
            GestureDetector(
              onTap: () => _showCreateDialog(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [colors.primary, Color.lerp(colors.primary, Colors.black, 0.15)!], begin: Alignment.topLeft, end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [BoxShadow(color: colors.primary.withValues(alpha: 0.35), blurRadius: 12, offset: const Offset(0, 4))],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.add_rounded, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Text(l10n.createOrganization, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = AppColors.of(context);
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final websiteCtrl = TextEditingController();
    final addressCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.fromLTRB(24, 12, 24, MediaQuery.of(ctx).viewInsets.bottom + 32),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(color: colors.border, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: colors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.business_outlined, color: colors.primary, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Text(l10n.newOrganization, style: TextStyle(color: colors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 24),
              _FormField(controller: nameCtrl, label: l10n.orgName, icon: Icons.badge_outlined, colors: colors),
              const SizedBox(height: 12),
              _FormField(controller: emailCtrl, label: l10n.orgEmail, icon: Icons.email_outlined, colors: colors, type: TextInputType.emailAddress),
              const SizedBox(height: 12),
              _FormField(controller: websiteCtrl, label: l10n.orgWebsite, icon: Icons.language_outlined, colors: colors, type: TextInputType.url),
              const SizedBox(height: 12),
              _FormField(controller: addressCtrl, label: l10n.orgLegalAddress, icon: Icons.location_on_outlined, colors: colors, maxLines: 2),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: GestureDetector(
                  onTap: () {
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
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [colors.primary, Color.lerp(colors.primary, Colors.black, 0.15)!], begin: Alignment.topLeft, end: Alignment.bottomRight),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [BoxShadow(color: colors.primary.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4))],
                    ),
                    child: Center(child: Text(l10n.create, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold))),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _kybColor(KybStatus status, AppColorsExtension colors) {
    switch (status) {
      case KybStatus.verified: return const Color(0xFF22C55E);
      case KybStatus.pending: return const Color(0xFFF59E0B);
      case KybStatus.rejected: return colors.error;
      default: return colors.textSecondary;
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

class _StatusPill extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 5),
          Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _RolePill extends StatelessWidget {
  final String label;
  final AppColorsExtension colors;
  const _RolePill({required this.label, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: colors.secondary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.secondary.withValues(alpha: 0.25)),
      ),
      child: Text(label, style: TextStyle(color: colors.secondary, fontSize: 11, fontWeight: FontWeight.w500)),
    );
  }
}

class _FormField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final AppColorsExtension colors;
  final TextInputType? type;
  final int maxLines;
  const _FormField({required this.controller, required this.label, required this.icon, required this.colors, this.type, this.maxLines = 1});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: type,
      maxLines: maxLines,
      style: TextStyle(color: colors.textPrimary, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: colors.textSecondary, fontSize: 13),
        prefixIcon: Icon(icon, color: colors.textSecondary, size: 18),
        filled: true,
        fillColor: colors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: colors.border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: colors.border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: colors.primary, width: 1.5)),
      ),
    );
  }
}

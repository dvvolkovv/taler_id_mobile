import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taler_id_mobile/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/platform/kyc_launcher.dart';
import '../../../../core/api/dio_client.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/services/call_state_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/widgets.dart';
import '../../../../core/utils/error_keys.dart';
import '../../../messenger/data/datasources/messenger_remote_datasource.dart';
import '../../../messenger/presentation/bloc/messenger_bloc.dart';
import '../../../messenger/presentation/bloc/messenger_event.dart';
import '../../domain/entities/tenant_entity.dart';
import '../bloc/tenant_bloc.dart';
import '../bloc/tenant_event.dart';
import '../bloc/tenant_state.dart';

class OrganizationDetailScreen extends StatefulWidget {
  final String tenantId;
  const OrganizationDetailScreen({super.key, required this.tenantId});

  @override
  State<OrganizationDetailScreen> createState() => _OrganizationDetailScreenState();
}

class _OrganizationDetailScreenState extends State<OrganizationDetailScreen> {
  @override
  void initState() {
    super.initState();
    context.read<TenantBloc>().add(TenantDetailRequested(widget.tenantId));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.of(context).background,
      appBar: AppBar(
        title: Text(l10n.organization),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: AppColors.of(context).textPrimary),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.person_add_outlined, color: AppColors.of(context).primary),
            onPressed: () => _showInviteSheet(context),
          ),
        ],
      ),
      body: BlocConsumer<TenantBloc, TenantState>(
        listener: (context, state) {
          if (state is TenantActionSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(resolveErrorMessage(l10n, state.message)), backgroundColor: AppColors.of(context).primary),
            );
          } else if (state is TenantError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(resolveErrorMessage(l10n, state.message)), backgroundColor: AppColors.of(context).error),
            );
          } else if (state is TenantKybSdkReady) {
            _launchKybSumsub(context, state.webSdkUrl, state.tenantId);
          }
        },
        builder: (context, state) {
          if (state is TenantLoading) {
            return Center(child: CircularProgressIndicator(color: AppColors.of(context).primary));
          }

          if (state is TenantDetailLoaded) {
            final t = state.tenant;
            final isOwner = t.myRole == TenantRole.owner;
            final isAdmin = t.myRole == TenantRole.admin;
            final canManage = isOwner || isAdmin;

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Header card
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 56, height: 56,
                            decoration: BoxDecoration(color: AppColors.of(context).primary.withOpacity(0.15), borderRadius: BorderRadius.circular(14)),
                            child: Icon(Icons.business_outlined, color: AppColors.of(context).primary, size: 28),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(t.name, style: TextStyle(color: AppColors.of(context).textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    StatusBadge(label: _kybLabel(t.kybStatus, l10n), color: _kybColor(t.kybStatus)),
                                    if (t.myRole != null) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: AppColors.of(context).secondary.withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(_roleLabelForRole(t.myRole!, l10n), style: TextStyle(color: AppColors.of(context).secondary, fontSize: 11, fontWeight: FontWeight.w500)),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                          if (canManage)
                            IconButton(
                              icon: Icon(Icons.edit_outlined, color: AppColors.of(context).textSecondary, size: 20),
                              onPressed: () => _showEditSheet(context, t),
                            ),
                        ],
                      ),
                      if (t.description != null && t.description!.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(t.description!, style: TextStyle(color: AppColors.of(context).textSecondary, fontSize: 13)),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // KYB section
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.kybBusinessVerificationTitle, style: TextStyle(color: AppColors.of(context).textSecondary, fontSize: 12, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(_kybIcon(t.kybStatus), color: _kybColor(t.kybStatus), size: 32),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                StatusBadge(label: _kybLabel(t.kybStatus, l10n), color: _kybColor(t.kybStatus)),
                                const SizedBox(height: 4),
                                Text(_kybDescription(t.kybStatus, l10n), style: TextStyle(color: AppColors.of(context).textSecondary, fontSize: 12)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (isOwner && (t.kybStatus == KybStatus.none || t.kybStatus == KybStatus.rejected)) ...[
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => context.read<TenantBloc>().add(TenantKybStartRequested(widget.tenantId)),
                            icon: const Icon(Icons.verified_user_outlined),
                            label: Text(l10n.kybVerification),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Contact info
                if (t.website != null || t.email != null || t.phone != null)
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.contacts, style: TextStyle(color: AppColors.of(context).textSecondary, fontSize: 12, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 12),
                        if (t.website != null) _contactRow(Icons.language_outlined, t.website!),
                        if (t.email != null) _contactRow(Icons.email_outlined, t.email!),
                        if (t.phone != null) _contactRow(Icons.phone_outlined, t.phone!),
                      ],
                    ),
                  ),
                if (t.website != null || t.email != null || t.phone != null)
                  const SizedBox(height: 16),

                // Members
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(l10n.members(t.members.length),
                              style: TextStyle(color: AppColors.of(context).textSecondary, fontSize: 12, fontWeight: FontWeight.w500)),
                          if (canManage)
                            GestureDetector(
                              onTap: () => _showInviteSheet(context),
                              child: Text(l10n.invitePlus, style: TextStyle(color: AppColors.of(context).primary, fontSize: 13)),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ...t.members.map((m) => _memberRow(m, t.myRole, canManage)),
                    ],
                  ),
                ),
              ],
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _contactRow(IconData icon, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(icon, color: AppColors.of(context).secondary, size: 16),
            const SizedBox(width: 12),
            Text(value, style: TextStyle(color: AppColors.of(context).textPrimary, fontSize: 13)),
          ],
        ),
      );

  Future<void> _callMember(TenantMemberEntity member) async {
    final userId = member.userId ?? member.id;
    if (CallStateService.instance.isInCall && !CallStateService.instance.canAddLine) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.chatAlreadyInCall), backgroundColor: AppColors.of(context).error),
        );
      }
      return;
    }

    try {
      // Create or find 1-on-1 conversation
      final bloc = context.read<MessengerBloc>();
      bloc.add(StartConversationWith(userId));
      final state = await bloc.stream.firstWhere(
        (s) => s.newConversationId != null || (!s.isLoading && s.error != null),
      );
      if (!mounted) return;
      final convId = state.newConversationId;
      if (convId == null) return;
      bloc.add(ClearNewConversation());

      // Create voice room
      final client = sl<DioClient>();
      final res = await client.post(
        '/voice/rooms',
        data: {'withAi': false, 'conversationId': convId},
        fromJson: (d) => Map<String, dynamic>.from(d as Map),
      );
      final roomName = res['roomName'] as String;
      sl<MessengerRemoteDataSource>().sendCallInvite(convId, roomName);

      final calleeName = [member.firstName, member.lastName]
          .where((s) => s != null && s.isNotEmpty)
          .join(' ');
      final calleeParam = calleeName.isNotEmpty ? '&callee=${Uri.encodeComponent(calleeName)}' : '';
      if (mounted) {
        context.push('/dashboard/voice?room=$roomName&convId=$convId$calleeParam');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.chatCallError(e.toString())), backgroundColor: AppColors.of(context).error),
        );
      }
    }
  }

  Widget _memberRow(TenantMemberEntity member, TenantRole? myRole, bool canManage) {
    final l10n = AppLocalizations.of(context)!;
    final roleColors = {
      TenantRole.owner: AppColors.of(context).primary,
      TenantRole.admin: AppColors.of(context).secondary,
      TenantRole.operator: AppColors.of(context).warning,
      TenantRole.viewer: AppColors.of(context).textSecondary,
    };
    final memberName = [member.firstName, member.lastName]
        .where((s) => s != null && s.isNotEmpty)
        .join(' ');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.of(context).border,
            child: Text(
              member.email[0].toUpperCase(),
              style: TextStyle(color: AppColors.of(context).textPrimary, fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  memberName.isEmpty ? member.email : memberName,
                  style: TextStyle(color: AppColors.of(context).textPrimary, fontSize: 13),
                ),
                Text(member.email, style: TextStyle(color: AppColors.of(context).textSecondary, fontSize: 11)),
              ],
            ),
          ),
          // Call button
          IconButton(
            icon: Icon(Icons.call_outlined, color: AppColors.of(context).primary, size: 20),
            onPressed: () => _callMember(member),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
          // Role badge or dropdown
          if (canManage && member.role != TenantRole.owner)
            PopupMenuButton<String>(
              color: AppColors.of(context).card,
              onSelected: (value) {
                if (value == 'remove') {
                  _confirmRemoveMember(context, member);
                } else {
                  final newRole = TenantRole.values.firstWhere((r) => r.name == value);
                  context.read<TenantBloc>().add(TenantMemberRoleChanged(
                    tenantId: widget.tenantId,
                    memberId: member.userId ?? member.id,
                    role: newRole,
                  ));
                }
              },
              itemBuilder: (_) => [
                ...TenantRole.values
                    .where((r) => r != TenantRole.owner)
                    .map((r) => PopupMenuItem(
                          value: r.name,
                          child: Row(
                            children: [
                              if (r == member.role)
                                Icon(Icons.check, size: 16, color: AppColors.of(context).primary)
                              else
                                const SizedBox(width: 16),
                              const SizedBox(width: 8),
                              Text(_roleLabelForRole(r, l10n), style: TextStyle(
                                color: r == member.role ? AppColors.of(context).primary : AppColors.of(context).textPrimary,
                              )),
                            ],
                          ),
                        )),
                const PopupMenuDivider(),
                PopupMenuItem(
                  value: 'remove',
                  child: Row(
                    children: [
                      Icon(Icons.person_remove_outlined, size: 16, color: AppColors.of(context).error),
                      const SizedBox(width: 8),
                      Text(l10n.delete, style: TextStyle(color: AppColors.of(context).error)),
                    ],
                  ),
                ),
              ],
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: (roleColors[member.role] ?? AppColors.of(context).textSecondary).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _roleLabelForRole(member.role, l10n),
                      style: TextStyle(color: roleColors[member.role] ?? AppColors.of(context).textSecondary, fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 2),
                    Icon(Icons.arrow_drop_down, size: 14, color: roleColors[member.role] ?? AppColors.of(context).textSecondary),
                  ],
                ),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: (roleColors[member.role] ?? AppColors.of(context).textSecondary).withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _roleLabelForRole(member.role, l10n),
                style: TextStyle(color: roleColors[member.role] ?? AppColors.of(context).textSecondary, fontSize: 11, fontWeight: FontWeight.w600),
              ),
            ),
        ],
      ),
    );
  }

  void _confirmRemoveMember(BuildContext context, TenantMemberEntity member) {
    final l10n = AppLocalizations.of(context)!;
    final name = [member.firstName, member.lastName]
        .where((s) => s != null && s.isNotEmpty)
        .join(' ');
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.of(context).card,
        title: Text(l10n.removeMember, style: TextStyle(color: AppColors.of(context).textPrimary)),
        content: Text(
          l10n.removeMemberConfirm(name.isEmpty ? member.email : name),
          style: TextStyle(color: AppColors.of(context).textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel, style: TextStyle(color: AppColors.of(context).textSecondary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<TenantBloc>().add(TenantMemberRemoved(
                tenantId: widget.tenantId,
                userId: member.userId ?? member.id,
              ));
            },
            child: Text(l10n.delete, style: TextStyle(color: AppColors.of(context).error)),
          ),
        ],
      ),
    );
  }

  void _showEditSheet(BuildContext context, TenantEntity tenant) {
    final l10n = AppLocalizations.of(context)!;
    final nameCtrl = TextEditingController(text: tenant.name);
    final emailCtrl = TextEditingController(text: tenant.email ?? '');
    final websiteCtrl = TextEditingController(text: tenant.website ?? '');
    final addressCtrl = TextEditingController(text: tenant.address ?? '');
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
              Text(l10n.editOrganizationTitle,
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
                      context.read<TenantBloc>().add(TenantUpdateSubmitted(
                        tenantId: widget.tenantId,
                        data: {
                          'name': nameCtrl.text.trim(),
                          if (emailCtrl.text.trim().isNotEmpty) 'email': emailCtrl.text.trim(),
                          if (websiteCtrl.text.trim().isNotEmpty) 'website': websiteCtrl.text.trim(),
                          if (addressCtrl.text.trim().isNotEmpty) 'legalAddress': addressCtrl.text.trim(),
                        },
                      ));
                      Navigator.pop(ctx);
                    }
                  },
                  child: Text(l10n.save),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showInviteSheet(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final emailCtrl = TextEditingController();
    TenantRole selectedRole = TenantRole.viewer;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.of(context).card,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 24, right: 24, top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.inviteMember,
                  style: TextStyle(color: AppColors.of(context).textPrimary, fontSize: 20, fontWeight: FontWeight.w600)),
              const SizedBox(height: 20),
              TextField(
                controller: emailCtrl,
                keyboardType: TextInputType.emailAddress,
                style: TextStyle(color: AppColors.of(context).textPrimary),
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<TenantRole>(
                value: selectedRole,
                dropdownColor: AppColors.of(context).card,
                style: TextStyle(color: AppColors.of(context).textPrimary),
                decoration: InputDecoration(labelText: l10n.role),
                items: TenantRole.values
                    .where((r) => r != TenantRole.owner)
                    .map((r) => DropdownMenuItem(
                          value: r,
                          child: Text(_roleLabelForRole(r, l10n), style: TextStyle(color: AppColors.of(context).textPrimary)),
                        ))
                    .toList(),
                onChanged: (v) => setModalState(() => selectedRole = v ?? TenantRole.viewer),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (emailCtrl.text.contains('@')) {
                      context.read<TenantBloc>().add(TenantMemberInvited(
                        tenantId: widget.tenantId,
                        email: emailCtrl.text.trim(),
                        role: selectedRole,
                      ));
                      Navigator.pop(ctx);
                    }
                  },
                  child: Text(l10n.sendInvite),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _launchKybSumsub(BuildContext context, String webSdkUrl, String tenantId) async {
    final l10n = AppLocalizations.of(context)!;
    if (kIsWeb) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: AppColors.of(context).card,
          title: Text(l10n.kybVerificationTitle, style: TextStyle(color: AppColors.of(context).textPrimary)),
          content: Text(
            l10n.kybWebOnlyBusiness,
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

    final bloc = context.read<TenantBloc>();
    final result = await KycLauncherPlatform.instance.launch(webSdkUrl: webSdkUrl);

    if (!mounted) return;

    if (result.skipped) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('KYB verification is not available on this platform')),
      );
      return;
    }
    if (result.success) {
      bloc.add(TenantKybSdkCompleted(tenantId));
    }
    bloc.add(TenantDetailRequested(tenantId));
  }

  IconData _kybIcon(KybStatus status) {
    switch (status) {
      case KybStatus.verified: return Icons.verified_outlined;
      case KybStatus.pending: return Icons.hourglass_empty_outlined;
      case KybStatus.rejected: return Icons.cancel_outlined;
      default: return Icons.business_outlined;
    }
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
      default: return l10n.kybNone;
    }
  }

  String _kybDescription(KybStatus status, AppLocalizations l10n) {
    switch (status) {
      case KybStatus.verified: return l10n.kybVerifiedOrgDesc;
      case KybStatus.pending: return l10n.kybPendingOrgDesc;
      case KybStatus.rejected: return l10n.kybRejectedOrgDesc;
      default: return l10n.kybNoneOrgDesc;
    }
  }

  String _roleLabelForRole(TenantRole role, AppLocalizations l10n) {
    switch (role) {
      case TenantRole.owner: return l10n.roleOwner;
      case TenantRole.admin: return l10n.roleAdmin;
      case TenantRole.operator: return l10n.roleOperator;
      case TenantRole.viewer: return l10n.roleViewer;
    }
  }
}

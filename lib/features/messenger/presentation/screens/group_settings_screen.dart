import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/api/dio_client.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../bloc/messenger_bloc.dart';
import '../bloc/messenger_event.dart';
import '../bloc/messenger_state.dart';
import '../../domain/entities/group_member_entity.dart';
import 'shared_media_screen.dart';

class GroupSettingsScreen extends StatefulWidget {
  final String conversationId;
  const GroupSettingsScreen({super.key, required this.conversationId});

  @override
  State<GroupSettingsScreen> createState() => _GroupSettingsScreenState();
}

class _GroupSettingsScreenState extends State<GroupSettingsScreen> {
  bool _uploadingAvatar = false;

  @override
  void initState() {
    super.initState();
    context.read<MessengerBloc>().add(LoadGroupMembers(widget.conversationId));
  }

  static const _roleColors = {
    'OWNER': Colors.amber,
    'ADMIN': Colors.blue,
    'MEMBER': Colors.grey,
  };

  String _roleLabel(String role, AppLocalizations l10n) {
    switch (role) {
      case 'OWNER': return l10n.groupRoleOwner;
      case 'ADMIN': return l10n.groupRoleAdmin;
      case 'MEMBER': return l10n.groupRoleMember;
      default: return role;
    }
  }

  Future<void> _uploadAvatar() async {
    final colors = AppColors.of(context);
    final l10n = AppLocalizations.of(context)!;
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(20),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 36, height: 4,
                decoration: BoxDecoration(color: colors.textSecondary.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(height: 20),
              Text(l10n.groupCamera.contains('Камера') ? 'Фото профиля' : 'Profile Photo',
                  style: TextStyle(color: colors.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: _PickerOption(
                        icon: Icons.camera_alt_rounded,
                        label: l10n.groupCamera,
                        color: colors.primary,
                        bg: colors.primary.withValues(alpha: 0.1),
                        onTap: () => Navigator.pop(ctx, ImageSource.camera),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _PickerOption(
                        icon: Icons.photo_library_rounded,
                        label: l10n.groupGallery,
                        color: const Color(0xFF8B5CF6),
                        bg: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                        onTap: () => Navigator.pop(ctx, ImageSource.gallery),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
    if (source == null || !mounted) return;

    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, maxWidth: 512, maxHeight: 512, imageQuality: 80);
    if (picked == null || !mounted) return;

    setState(() => _uploadingAvatar = true);
    try {
      final client = sl<DioClient>();
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(picked.path, filename: 'group_avatar.jpg'),
      });
      final res = await client.post(
        '/messenger/files',
        data: formData,
        fromJson: (d) => Map<String, dynamic>.from(d as Map),
      );
      if (!mounted) return;
      final fileUrl = res['fileUrl'] as String;
      context.read<MessengerBloc>().add(UpdateGroupInfo(
        conversationId: widget.conversationId,
        avatarUrl: fileUrl,
      ));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.groupAvatarUpdated), backgroundColor: Colors.green),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.errorWithMessage(e.toString())),
            backgroundColor: AppColors.of(context).error),
      );
    } finally {
      if (mounted) setState(() => _uploadingAvatar = false);
    }
  }

  void _editGroupName(String currentName) {
    final colors = AppColors.of(context);
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController(text: currentName);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: colors.card, borderRadius: BorderRadius.circular(20)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(width: 36, height: 4, decoration: BoxDecoration(color: colors.textSecondary.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 20),
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(color: colors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                child: Icon(Icons.group_rounded, color: colors.primary, size: 22),
              ),
              const SizedBox(height: 12),
              Text(l10n.groupNameTitle, style: TextStyle(color: colors.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TextField(
                  controller: controller,
                  autofocus: true,
                  style: TextStyle(color: colors.textPrimary, fontSize: 15),
                  decoration: InputDecoration(
                    hintText: l10n.groupEnterName,
                    hintStyle: TextStyle(color: colors.textSecondary.withValues(alpha: 0.5)),
                    filled: true,
                    fillColor: colors.surface,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: colors.border.withValues(alpha: 0.3))),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: colors.primary, width: 1.5)),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          backgroundColor: colors.surface,
                        ),
                        child: Text(l10n.cancel, style: TextStyle(color: colors.textSecondary, fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          gradient: LinearGradient(colors: [colors.primary, colors.primary.withValues(alpha: 0.8)]),
                        ),
                        child: TextButton(
                          onPressed: () {
                            final name = controller.text.trim();
                            if (name.isNotEmpty && name != currentName) {
                              context.read<MessengerBloc>().add(UpdateGroupInfo(
                                conversationId: widget.conversationId,
                                name: name,
                              ));
                            }
                            Navigator.pop(ctx);
                          },
                          style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                          child: Text(l10n.save, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _editDescription(String? currentDescription) {
    final colors = AppColors.of(context);
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController(text: currentDescription ?? '');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: colors.card, borderRadius: BorderRadius.circular(20)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(width: 36, height: 4, decoration: BoxDecoration(color: colors.textSecondary.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 20),
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(color: const Color(0xFF8B5CF6).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.description_rounded, color: Color(0xFF8B5CF6), size: 22),
              ),
              const SizedBox(height: 12),
              Text(l10n.groupDescriptionTitle, style: TextStyle(color: colors.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TextField(
                  controller: controller,
                  autofocus: true,
                  maxLines: 4,
                  style: TextStyle(color: colors.textPrimary, fontSize: 15),
                  decoration: InputDecoration(
                    hintText: l10n.groupEnterDescription,
                    hintStyle: TextStyle(color: colors.textSecondary.withValues(alpha: 0.5)),
                    filled: true,
                    fillColor: colors.surface,
                    contentPadding: const EdgeInsets.all(16),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: colors.border.withValues(alpha: 0.3))),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: const Color(0xFF8B5CF6), width: 1.5)),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          backgroundColor: colors.surface,
                        ),
                        child: Text(l10n.cancel, style: TextStyle(color: colors.textSecondary, fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          gradient: LinearGradient(colors: [colors.primary, colors.primary.withValues(alpha: 0.8)]),
                        ),
                        child: TextButton(
                          onPressed: () {
                            final desc = controller.text.trim();
                            context.read<MessengerBloc>().add(UpdateGroupInfo(
                              conversationId: widget.conversationId,
                              description: desc,
                            ));
                            Navigator.pop(ctx);
                          },
                          style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                          child: Text(l10n.save, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _showChangeRoleSheet(GroupMemberEntity member, String myRole) {
    final l10n = AppLocalizations.of(context)!;
    final colors = AppColors.of(context);
    final canAssignAdmin = myRole == 'OWNER';
    final name = [member.firstName, member.lastName]
        .where((s) => s != null && s.isNotEmpty).join(' ');
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: colors.card, borderRadius: BorderRadius.circular(20)),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(width: 36, height: 4, decoration: BoxDecoration(color: colors.textSecondary.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 20),
              Text(name.isNotEmpty ? name : (member.username ?? ''),
                  style: TextStyle(color: colors.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(l10n.changeRole, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    if (canAssignAdmin && member.role != 'ADMIN')
                      _RoleOption(
                        icon: Icons.shield_rounded,
                        label: l10n.groupRoleAdmin,
                        subtitle: 'Can manage members and settings',
                        color: _roleColors['ADMIN']!,
                        onTap: () {
                          Navigator.pop(ctx);
                          context.read<MessengerBloc>().add(ChangeGroupRole(
                            conversationId: widget.conversationId,
                            userId: member.userId,
                            role: 'ADMIN',
                          ));
                        },
                      ),
                    if (member.role != 'MEMBER')
                      _RoleOption(
                        icon: Icons.person_rounded,
                        label: l10n.groupRoleMember,
                        subtitle: 'Regular group member',
                        color: _roleColors['MEMBER']!,
                        onTap: () {
                          Navigator.pop(ctx);
                          context.read<MessengerBloc>().add(ChangeGroupRole(
                            conversationId: widget.conversationId,
                            userId: member.userId,
                            role: 'MEMBER',
                          ));
                        },
                      ),
                    const SizedBox(height: 8),
                    _RoleOption(
                      icon: Icons.person_remove_rounded,
                      label: l10n.removeMember,
                      subtitle: '',
                      color: colors.error,
                      isDestructive: true,
                      onTap: () {
                        Navigator.pop(ctx);
                        _confirmRemoveMember(member);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmRemoveMember(GroupMemberEntity member) {
    final l10n = AppLocalizations.of(context)!;
    final colors = AppColors.of(context);
    final name = [member.firstName, member.lastName]
        .where((s) => s != null && s.isNotEmpty).join(' ');
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: colors.card, borderRadius: BorderRadius.circular(20)),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(width: 36, height: 4, decoration: BoxDecoration(color: colors.textSecondary.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 20),
              Container(
                width: 52, height: 52,
                decoration: BoxDecoration(color: colors.error.withValues(alpha: 0.1), shape: BoxShape.circle),
                child: Icon(Icons.person_remove_rounded, color: colors.error, size: 24),
              ),
              const SizedBox(height: 16),
              Text(l10n.removeMember, style: TextStyle(color: colors.textPrimary, fontSize: 17, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  l10n.removeMemberConfirm(name.isNotEmpty ? name : (member.username ?? '')),
                  style: TextStyle(color: colors.textSecondary, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          backgroundColor: colors.surface,
                        ),
                        child: Text(l10n.cancel, style: TextStyle(color: colors.textSecondary, fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          context.read<MessengerBloc>().add(RemoveGroupMember(
                            conversationId: widget.conversationId,
                            userId: member.userId,
                          ));
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          backgroundColor: colors.error,
                        ),
                        child: Text(l10n.delete, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _showAutoDeletePicker(BuildContext context) {
    final colors = AppColors.of(context);
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: colors.card, borderRadius: BorderRadius.circular(20)),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(width: 36, height: 4, decoration: BoxDecoration(color: colors.textSecondary.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 20),
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(color: colors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                child: Icon(Icons.timer_outlined, color: colors.primary, size: 22),
              ),
              const SizedBox(height: 12),
              Text(l10n.messengerAutoDelete, style: TextStyle(color: colors.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    for (final option in [
                      (null, l10n.messengerAutoDeleteOff, Icons.block_rounded),
                      (7, l10n.messengerAutoDelete7d, Icons.looks_one_rounded),
                      (30, l10n.messengerAutoDelete30d, Icons.calendar_month_rounded),
                      (90, l10n.messengerAutoDelete90d, Icons.date_range_rounded),
                    ])
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Material(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () {
                              Navigator.pop(ctx);
                              context.read<MessengerBloc>().add(UpdateGroupSettings(
                                conversationId: widget.conversationId,
                                autoDeleteDays: option.$1 ?? 0,
                              ));
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              decoration: BoxDecoration(
                                color: colors.surface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: colors.border.withValues(alpha: 0.3)),
                              ),
                              child: Row(
                                children: [
                                  Icon(option.$3, color: colors.textSecondary, size: 20),
                                  const SizedBox(width: 14),
                                  Expanded(child: Text(option.$2, style: TextStyle(color: colors.textPrimary, fontSize: 15))),
                                  Icon(Icons.chevron_right_rounded, color: colors.textSecondary.withValues(alpha: 0.5), size: 20),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmLeaveGroup() {
    final l10n = AppLocalizations.of(context)!;
    final colors = AppColors.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: colors.card, borderRadius: BorderRadius.circular(20)),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(width: 36, height: 4, decoration: BoxDecoration(color: colors.textSecondary.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 20),
              Container(
                width: 52, height: 52,
                decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.1), shape: BoxShape.circle),
                child: const Icon(Icons.exit_to_app_rounded, color: Colors.orange, size: 24),
              ),
              const SizedBox(height: 16),
              Text(l10n.leaveGroup, style: TextStyle(color: colors.textPrimary, fontSize: 17, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(l10n.leaveGroupConfirm, style: TextStyle(color: colors.textSecondary, fontSize: 14), textAlign: TextAlign.center),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          backgroundColor: colors.surface,
                        ),
                        child: Text(l10n.cancel, style: TextStyle(color: colors.textSecondary, fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          context.read<MessengerBloc>().add(LeaveGroup(widget.conversationId));
                          context.go('/dashboard/messenger');
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          backgroundColor: Colors.orange,
                        ),
                        child: Text(l10n.leaveGroup, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDeleteGroup() {
    final l10n = AppLocalizations.of(context)!;
    final colors = AppColors.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: colors.card, borderRadius: BorderRadius.circular(20)),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(width: 36, height: 4, decoration: BoxDecoration(color: colors.textSecondary.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 20),
              Container(
                width: 52, height: 52,
                decoration: BoxDecoration(color: colors.error.withValues(alpha: 0.1), shape: BoxShape.circle),
                child: Icon(Icons.delete_forever_rounded, color: colors.error, size: 24),
              ),
              const SizedBox(height: 16),
              Text(l10n.deleteGroup, style: TextStyle(color: colors.textPrimary, fontSize: 17, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(l10n.deleteGroupConfirm, style: TextStyle(color: colors.textSecondary, fontSize: 14), textAlign: TextAlign.center),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          backgroundColor: colors.surface,
                        ),
                        child: Text(l10n.cancel, style: TextStyle(color: colors.textSecondary, fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          context.read<MessengerBloc>().add(DeleteGroup(widget.conversationId));
                          context.go('/dashboard/messenger');
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          backgroundColor: colors.error,
                        ),
                        child: Text(l10n.deleteGroup, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = AppColors.of(context);
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(title: Text(l10n.groupInfo)),
      body: BlocBuilder<MessengerBloc, MessengerState>(
        builder: (context, state) {
          final conv = state.conversations
              .where((c) => c.id == widget.conversationId)
              .firstOrNull;
          final members = state.groupMembers[widget.conversationId] ?? [];
          final myRole = conv?.myRole ?? 'MEMBER';
          final canManage = myRole == 'OWNER' || myRole == 'ADMIN';

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              // ── Group header card ──
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: colors.card,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: colors.border.withValues(alpha: 0.3)),
                ),
                child: Column(
                  children: [
                    // Avatar
                    GestureDetector(
                      onTap: canManage ? _uploadAvatar : null,
                      child: Stack(
                        children: [
                          Container(
                            width: 96, height: 96,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                begin: Alignment.topLeft, end: Alignment.bottomRight,
                                colors: [colors.primary.withValues(alpha: 0.3), colors.primary.withValues(alpha: 0.1)],
                              ),
                            ),
                            child: _uploadingAvatar
                                ? Center(child: SizedBox(width: 32, height: 32, child: CircularProgressIndicator(strokeWidth: 2, color: colors.primary)))
                                : conv?.avatarUrl != null
                                    ? ClipOval(child: CachedNetworkImage(imageUrl: conv!.avatarUrl!, width: 96, height: 96, fit: BoxFit.cover,
                                        errorWidget: (_, __, ___) => Icon(Icons.group_rounded, size: 44, color: colors.primary)))
                                    : Icon(Icons.group_rounded, size: 44, color: colors.primary),
                          ),
                          if (canManage)
                            Positioned(
                              right: 0, bottom: 0,
                              child: Container(
                                width: 32, height: 32,
                                decoration: BoxDecoration(
                                  color: colors.primary,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: colors.card, width: 2.5),
                                  boxShadow: [BoxShadow(color: colors.primary.withValues(alpha: 0.3), blurRadius: 8)],
                                ),
                                child: const Icon(Icons.camera_alt_rounded, size: 14, color: Colors.white),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Group name
                    GestureDetector(
                      onTap: canManage ? () => _editGroupName(conv?.name ?? '') : null,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(conv?.name ?? '', style: TextStyle(color: colors.textPrimary, fontSize: 22, fontWeight: FontWeight.w700), textAlign: TextAlign.center),
                          ),
                          if (canManage) ...[
                            const SizedBox(width: 6),
                            Icon(Icons.edit_rounded, size: 16, color: colors.textSecondary.withValues(alpha: 0.5)),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(color: colors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                      child: Text(l10n.participantsCount(members.length),
                          style: TextStyle(color: colors.primary, fontSize: 12, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // ── Description card ──
              GestureDetector(
                onTap: canManage ? () => _editDescription(conv?.description) : null,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colors.card,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: colors.border.withValues(alpha: 0.3)),
                  ),
                  child: conv?.description != null && conv!.description!.isNotEmpty
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.info_outline_rounded, size: 16, color: colors.textSecondary),
                                const SizedBox(width: 8),
                                Text(l10n.groupDescription,
                                    style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.3)),
                                const Spacer(),
                                if (canManage)
                                  Icon(Icons.edit_rounded, size: 14, color: colors.textSecondary.withValues(alpha: 0.5)),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(conv.description!, style: TextStyle(color: colors.textPrimary, fontSize: 14, height: 1.4)),
                          ],
                        )
                      : Row(
                          children: [
                            Container(
                              width: 36, height: 36,
                              decoration: BoxDecoration(color: colors.surface, borderRadius: BorderRadius.circular(10)),
                              child: Icon(Icons.info_outline_rounded, size: 18, color: colors.textSecondary),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                canManage ? l10n.groupAddDescription : l10n.groupNoDescription,
                                style: TextStyle(color: colors.textSecondary, fontSize: 14),
                              ),
                            ),
                            if (canManage)
                              Icon(Icons.add_rounded, size: 20, color: colors.primary),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 12),

              // ── Members card ──
              Container(
                decoration: BoxDecoration(
                  color: colors.card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: colors.border.withValues(alpha: 0.3)),
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 8, 4),
                      child: Row(
                        children: [
                          Icon(Icons.people_rounded, size: 18, color: colors.textSecondary),
                          const SizedBox(width: 8),
                          Text(l10n.groupMembers(members.length),
                              style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w700)),
                          const Spacer(),
                          if (canManage)
                            TextButton.icon(
                              onPressed: () => context.push('/dashboard/messenger/${widget.conversationId}/add-members'),
                              icon: Icon(Icons.person_add_rounded, size: 16, color: colors.primary),
                              label: Text(l10n.addMembers, style: TextStyle(color: colors.primary, fontSize: 12, fontWeight: FontWeight.w600)),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                backgroundColor: colors.primary.withValues(alpha: 0.08),
                              ),
                            ),
                        ],
                      ),
                    ),
                    ...members.map((m) => _buildMemberTile(m, myRole, state.currentUserId, l10n, colors)),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // ── Actions card (media, mute) ──
              Container(
                decoration: BoxDecoration(
                  color: colors.card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: colors.border.withValues(alpha: 0.3)),
                ),
                child: Column(
                  children: [
                    // Shared media
                    _ActionTile(
                      icon: Icons.perm_media_outlined,
                      iconColor: const Color(0xFF8B5CF6),
                      iconBg: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                      title: l10n.groupMediaAndFiles,
                      trailing: Icon(Icons.chevron_right_rounded, color: colors.textSecondary.withValues(alpha: 0.5), size: 20),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => SharedMediaScreen(conversationId: widget.conversationId)),
                      ),
                      isFirst: true,
                    ),
                    Divider(height: 1, indent: 62, color: colors.border.withValues(alpha: 0.2)),
                    // Mute notifications
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      child: Row(
                        children: [
                          Container(
                            width: 36, height: 36,
                            decoration: BoxDecoration(
                              color: Colors.orange.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              conv?.isMuted == true ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                              color: Colors.orange, size: 18,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(l10n.muteNotifications, style: TextStyle(color: colors.textPrimary, fontSize: 14)),
                                if (conv?.isMuted == true)
                                  Text(l10n.muted, style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                              ],
                            ),
                          ),
                          Switch(
                            value: conv?.isMuted ?? false,
                            activeColor: colors.primary,
                            onChanged: (val) {
                              if (val) {
                                context.read<MessengerBloc>().add(MuteConversation(conversationId: widget.conversationId));
                              } else {
                                context.read<MessengerBloc>().add(UnmuteConversation(widget.conversationId));
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                ),
              ),

              // ── Settings card (OWNER/ADMIN) ──
              if (myRole == 'OWNER' || myRole == 'ADMIN') ...[
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: colors.card,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: colors.border.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
                        child: Row(
                          children: [
                            Icon(Icons.settings_rounded, size: 16, color: colors.textSecondary),
                            const SizedBox(width: 8),
                            Text(l10n.messengerSettingsHeader,
                                style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.3)),
                          ],
                        ),
                      ),
                      // Admin only mode
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        child: Row(
                          children: [
                            Container(
                              width: 36, height: 36,
                              decoration: BoxDecoration(color: colors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                              child: Icon(Icons.admin_panel_settings_outlined, color: colors.primary, size: 18),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(l10n.messengerAdminOnly, style: TextStyle(color: colors.textPrimary, fontSize: 14)),
                                  Text(l10n.messengerAdminOnlyDesc, style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                                ],
                              ),
                            ),
                            Switch(
                              value: conv?.slowMode ?? false,
                              activeColor: colors.primary,
                              onChanged: (val) => context.read<MessengerBloc>().add(UpdateGroupSettings(conversationId: widget.conversationId, slowMode: val)),
                            ),
                          ],
                        ),
                      ),
                      Divider(height: 1, indent: 62, color: colors.border.withValues(alpha: 0.2)),
                      // Topics
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        child: Row(
                          children: [
                            Container(
                              width: 36, height: 36,
                              decoration: BoxDecoration(color: const Color(0xFF22C55E).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                              child: const Icon(Icons.forum_outlined, color: Color(0xFF22C55E), size: 18),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(l10n.messengerTopics, style: TextStyle(color: colors.textPrimary, fontSize: 14)),
                                  Text(l10n.messengerTopicsDesc, style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                                ],
                              ),
                            ),
                            Switch(
                              value: conv?.topicsEnabled ?? false,
                              activeColor: colors.primary,
                              onChanged: (val) => context.read<MessengerBloc>().add(UpdateGroupSettings(conversationId: widget.conversationId, topicsEnabled: val)),
                            ),
                          ],
                        ),
                      ),
                      Divider(height: 1, indent: 62, color: colors.border.withValues(alpha: 0.2)),
                      // Auto-delete
                      _ActionTile(
                        icon: Icons.timer_outlined,
                        iconColor: Colors.orange,
                        iconBg: Colors.orange.withValues(alpha: 0.1),
                        title: l10n.messengerAutoDelete,
                        subtitle: conv?.autoDeleteDays != null
                            ? l10n.messengerAutoDeleteDays(conv!.autoDeleteDays!)
                            : l10n.messengerAutoDeleteOff,
                        trailing: Icon(Icons.chevron_right_rounded, color: colors.textSecondary.withValues(alpha: 0.5), size: 20),
                        onTap: () => _showAutoDeletePicker(context),
                      ),
                      const SizedBox(height: 4),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 12),

              // ── Danger zone ──
              Container(
                decoration: BoxDecoration(
                  color: colors.card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: colors.error.withValues(alpha: 0.15)),
                ),
                child: Column(
                  children: [
                    _ActionTile(
                      icon: Icons.exit_to_app_rounded,
                      iconColor: Colors.orange,
                      iconBg: Colors.orange.withValues(alpha: 0.1),
                      title: l10n.leaveGroup,
                      titleColor: Colors.orange,
                      onTap: _confirmLeaveGroup,
                      isFirst: true,
                    ),
                    if (myRole == 'OWNER') ...[
                      Divider(height: 1, indent: 62, color: colors.border.withValues(alpha: 0.2)),
                      _ActionTile(
                        icon: Icons.delete_forever_rounded,
                        iconColor: colors.error,
                        iconBg: colors.error.withValues(alpha: 0.1),
                        title: l10n.deleteGroup,
                        titleColor: colors.error,
                        onTap: _confirmDeleteGroup,
                      ),
                    ],
                    const SizedBox(height: 4),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMemberTile(GroupMemberEntity member, String myRole, String? myUserId, AppLocalizations l10n, AppColorsExtension colors) {
    final name = [member.firstName, member.lastName]
        .where((s) => s != null && s.isNotEmpty).join(' ');
    final displayName = name.isNotEmpty ? name : (member.username ?? member.userId);
    final isMe = member.userId == myUserId;
    final canManage = (myRole == 'OWNER' || myRole == 'ADMIN') && !isMe && member.role != 'OWNER';
    final roleColor = _roleColors[member.role] ?? Colors.grey;

    return InkWell(
      onTap: !isMe ? () => context.push('/dashboard/user/${member.userId}') : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 42, height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                  colors: [colors.primary.withValues(alpha: 0.3), colors.primary.withValues(alpha: 0.1)],
                ),
              ),
              child: member.avatarUrl != null
                  ? ClipOval(child: CachedNetworkImage(imageUrl: member.avatarUrl!, width: 42, height: 42, fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => Center(child: Text(displayName[0].toUpperCase(), style: TextStyle(color: colors.primary, fontWeight: FontWeight.w700, fontSize: 16)))))
                  : Center(child: Text(displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                      style: TextStyle(color: colors.primary, fontWeight: FontWeight.w700, fontSize: 16))),
            ),
            const SizedBox(width: 12),
            // Name + username
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(displayName, style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: roleColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
                        child: Text(_roleLabel(member.role, l10n),
                            style: TextStyle(color: roleColor, fontSize: 10, fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                  if (member.username != null) ...[
                    const SizedBox(height: 2),
                    Text('@${member.username}', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
                  ],
                ],
              ),
            ),
            if (canManage)
              GestureDetector(
                onTap: () => _showChangeRoleSheet(member, myRole),
                child: Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(color: colors.surface, borderRadius: BorderRadius.circular(8)),
                  child: Icon(Icons.more_horiz_rounded, color: colors.textSecondary, size: 18),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Helper widgets ──

class _PickerOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color bg;
  final VoidCallback onTap;

  const _PickerOption({required this.icon, required this.label, required this.color, required this.bg, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14)),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 8),
              Text(label, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final bool isDestructive;
  final VoidCallback onTap;

  const _RoleOption({required this.icon, required this.label, required this.subtitle, required this.color, this.isDestructive = false, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isDestructive ? color.withValues(alpha: 0.08) : colors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isDestructive ? color.withValues(alpha: 0.2) : colors.border.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                  child: Icon(icon, color: color, size: 18),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label, style: TextStyle(color: isDestructive ? color : colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
                      if (subtitle.isNotEmpty)
                        Text(subtitle, style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String? subtitle;
  final Color? titleColor;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool isFirst;

  const _ActionTile({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    this.subtitle,
    this.titleColor,
    this.trailing,
    this.onTap,
    this.isFirst = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: isFirst ? const BorderRadius.vertical(top: Radius.circular(16)) : BorderRadius.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(color: titleColor ?? colors.textPrimary, fontSize: 14)),
                  if (subtitle != null)
                    Text(subtitle!, style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                ],
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}

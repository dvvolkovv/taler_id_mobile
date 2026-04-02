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
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppColors.of(context).card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: AppColors.of(context).textSecondary.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Icon(Icons.camera_alt_rounded, color: AppColors.of(context).primary),
              title: Text(AppLocalizations.of(context)!.groupCamera, style: TextStyle(color: AppColors.of(context).textPrimary)),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: Icon(Icons.photo_library_rounded, color: AppColors.of(context).primary),
              title: Text(AppLocalizations.of(context)!.groupGallery, style: TextStyle(color: AppColors.of(context).textPrimary)),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
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
        SnackBar(content: Text(AppLocalizations.of(context)!.groupAvatarUpdated), backgroundColor: Colors.green),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.errorWithMessage(e.toString())), backgroundColor: AppColors.of(context).error),
      );
    } finally {
      if (mounted) setState(() => _uploadingAvatar = false);
    }
  }

  void _editGroupName(String currentName) {
    final controller = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.of(context).card,
        title: Text(AppLocalizations.of(context)!.groupNameTitle, style: TextStyle(color: AppColors.of(context).textPrimary)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: TextStyle(color: AppColors.of(context).textPrimary),
          decoration: InputDecoration(
            hintText: AppLocalizations.of(context)!.groupEnterName,
            hintStyle: TextStyle(color: AppColors.of(context).textSecondary),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
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
            child: Text(AppLocalizations.of(context)!.save),
          ),
        ],
      ),
    );
    controller.dispose;
  }

  void _editDescription(String? currentDescription) {
    final controller = TextEditingController(text: currentDescription ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.of(context).card,
        title: Text(AppLocalizations.of(context)!.groupDescriptionTitle, style: TextStyle(color: AppColors.of(context).textPrimary)),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 4,
          style: TextStyle(color: AppColors.of(context).textPrimary),
          decoration: InputDecoration(
            hintText: AppLocalizations.of(context)!.groupEnterDescription,
            hintStyle: TextStyle(color: AppColors.of(context).textSecondary),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () {
              final desc = controller.text.trim();
              context.read<MessengerBloc>().add(UpdateGroupInfo(
                conversationId: widget.conversationId,
                description: desc,
              ));
              Navigator.pop(ctx);
            },
            child: Text(AppLocalizations.of(context)!.save),
          ),
        ],
      ),
    );
  }

  void _showChangeRoleSheet(GroupMemberEntity member, String myRole) {
    final l10n = AppLocalizations.of(context)!;
    final canAssignAdmin = myRole == 'OWNER';
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.of(context).card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: AppColors.of(context).textSecondary.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(l10n.changeRole,
                style: TextStyle(color: AppColors.of(context).textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            if (canAssignAdmin && member.role != 'ADMIN')
              ListTile(
                leading: Icon(Icons.shield_rounded, color: _roleColors['ADMIN']),
                title: Text(l10n.groupRoleAdmin, style: TextStyle(color: AppColors.of(context).textPrimary)),
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
              ListTile(
                leading: Icon(Icons.person_rounded, color: _roleColors['MEMBER']),
                title: Text(l10n.groupRoleMember, style: TextStyle(color: AppColors.of(context).textPrimary)),
                onTap: () {
                  Navigator.pop(ctx);
                  context.read<MessengerBloc>().add(ChangeGroupRole(
                    conversationId: widget.conversationId,
                    userId: member.userId,
                    role: 'MEMBER',
                  ));
                },
              ),
            const Divider(),
            ListTile(
              leading: Icon(Icons.person_remove_rounded, color: AppColors.of(context).error),
              title: Text(l10n.removeMember,
                  style: TextStyle(color: AppColors.of(context).error)),
              onTap: () {
                Navigator.pop(ctx);
                _confirmRemoveMember(member);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _confirmRemoveMember(GroupMemberEntity member) {
    final l10n = AppLocalizations.of(context)!;
    final name = [member.firstName, member.lastName]
        .where((s) => s != null && s.isNotEmpty).join(' ');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.of(context).card,
        title: Text(l10n.removeMember, style: TextStyle(color: AppColors.of(context).textPrimary)),
        content: Text(l10n.removeMemberConfirm(name.isNotEmpty ? name : (member.username ?? '')),
            style: TextStyle(color: AppColors.of(context).textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<MessengerBloc>().add(RemoveGroupMember(
                conversationId: widget.conversationId,
                userId: member.userId,
              ));
            },
            child: Text(l10n.delete, style: TextStyle(color: AppColors.of(context).error)),
          ),
        ],
      ),
    );
  }

  void _confirmLeaveGroup() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.of(context).card,
        title: Text(l10n.leaveGroup, style: TextStyle(color: AppColors.of(context).textPrimary)),
        content: Text(l10n.leaveGroupConfirm, style: TextStyle(color: AppColors.of(context).textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.cancel)),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<MessengerBloc>().add(LeaveGroup(widget.conversationId));
              context.go('/dashboard/messenger');
            },
            child: Text(l10n.leaveGroup, style: TextStyle(color: AppColors.of(context).error)),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteGroup() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.of(context).card,
        title: Text(l10n.deleteGroup, style: TextStyle(color: AppColors.of(context).textPrimary)),
        content: Text(l10n.deleteGroupConfirm, style: TextStyle(color: AppColors.of(context).textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.cancel)),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<MessengerBloc>().add(DeleteGroup(widget.conversationId));
              context.go('/dashboard/messenger');
            },
            child: Text(l10n.deleteGroup, style: TextStyle(color: AppColors.of(context).error)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.of(context).background,
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
            children: [
              // Group header with avatar
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    // Avatar
                    GestureDetector(
                      onTap: canManage ? _uploadAvatar : null,
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 48,
                            backgroundColor: AppColors.of(context).primary.withValues(alpha: 0.3),
                            child: _uploadingAvatar
                                ? SizedBox(
                                    width: 32, height: 32,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.of(context).primary,
                                    ),
                                  )
                                : conv?.avatarUrl != null
                                    ? ClipOval(
                                        child: CachedNetworkImage(
                                          imageUrl: conv!.avatarUrl!,
                                          width: 96, height: 96, fit: BoxFit.cover,
                                          errorWidget: (_, __, ___) => Icon(Icons.group_rounded, size: 48, color: AppColors.of(context).primary),
                                        ),
                                      )
                                    : Icon(Icons.group_rounded, size: 48, color: AppColors.of(context).primary),
                          ),
                          if (canManage)
                            Positioned(
                              right: 0, bottom: 0,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: AppColors.of(context).primary,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: AppColors.of(context).background, width: 2),
                                ),
                                child: const Icon(Icons.camera_alt_rounded, size: 16, color: Colors.white),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Group name (tappable for OWNER/ADMIN)
                    GestureDetector(
                      onTap: canManage ? () => _editGroupName(conv?.name ?? '') : null,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              conv?.name ?? '',
                              style: TextStyle(color: AppColors.of(context).textPrimary, fontSize: 22, fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          if (canManage) ...[
                            const SizedBox(width: 6),
                            Icon(Icons.edit_rounded, size: 18, color: AppColors.of(context).textSecondary),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(l10n.participantsCount(members.length),
                        style: TextStyle(color: AppColors.of(context).textSecondary, fontSize: 14)),
                  ],
                ),
              ),
              // Description section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GestureDetector(
                  onTap: canManage ? () => _editDescription(conv?.description) : null,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.of(context).card,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: conv?.description != null && conv!.description!.isNotEmpty
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(l10n.groupDescription,
                                      style: TextStyle(color: AppColors.of(context).textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
                                  const Spacer(),
                                  if (canManage)
                                    Icon(Icons.edit_rounded, size: 16, color: AppColors.of(context).textSecondary),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(conv.description!,
                                  style: TextStyle(color: AppColors.of(context).textPrimary, fontSize: 15)),
                            ],
                          )
                        : Row(
                            children: [
                              Icon(Icons.info_outline_rounded, size: 20, color: AppColors.of(context).textSecondary),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  canManage ? l10n.groupAddDescription : l10n.groupNoDescription,
                                  style: TextStyle(color: AppColors.of(context).textSecondary, fontSize: 15),
                                ),
                              ),
                              if (canManage)
                                Icon(Icons.add_rounded, size: 20, color: AppColors.of(context).primary),
                            ],
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Divider(height: 1),
              // Members header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  children: [
                    Text(l10n.groupMembers(members.length),
                        style: TextStyle(color: AppColors.of(context).textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
                    const Spacer(),
                    if (canManage)
                      TextButton.icon(
                        onPressed: () => context.push('/dashboard/messenger/${widget.conversationId}/add-members'),
                        icon: Icon(Icons.person_add_rounded, size: 18, color: AppColors.of(context).primary),
                        label: Text(l10n.addMembers,
                            style: TextStyle(color: AppColors.of(context).primary, fontSize: 13)),
                      ),
                  ],
                ),
              ),
              // Member list
              ...members.map((m) => _buildMemberTile(m, myRole, state.currentUserId, l10n)),
              const Divider(height: 32),
              // Shared media
              ListTile(
                leading: Icon(Icons.perm_media_outlined, color: AppColors.of(context).textPrimary),
                title: Text(l10n.groupMediaAndFiles, style: TextStyle(color: AppColors.of(context).textPrimary)),
                trailing: Icon(Icons.chevron_right, color: AppColors.of(context).textSecondary),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => SharedMediaScreen(conversationId: widget.conversationId)),
                ),
              ),
              const Divider(height: 32),
              // Mute notifications
              SwitchListTile(
                secondary: Icon(
                  conv?.isMuted == true ? Icons.volume_off : Icons.volume_up,
                  color: AppColors.of(context).textPrimary,
                ),
                title: Text(l10n.muteNotifications, style: TextStyle(color: AppColors.of(context).textPrimary)),
                subtitle: conv?.isMuted == true
                    ? Text(l10n.muted, style: TextStyle(color: AppColors.of(context).textSecondary, fontSize: 13))
                    : null,
                value: conv?.isMuted ?? false,
                activeColor: AppColors.of(context).primary,
                onChanged: (val) {
                  if (val) {
                    context.read<MessengerBloc>().add(
                        MuteConversation(conversationId: widget.conversationId));
                  } else {
                    context.read<MessengerBloc>().add(
                        UnmuteConversation(widget.conversationId));
                  }
                },
              ),
              // Group settings (OWNER/ADMIN only)
              if (myRole == 'OWNER' || myRole == 'ADMIN') ...[
                const Divider(height: 32),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Text('Настройки', style: TextStyle(
                    color: AppColors.of(context).textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
                ),
                SwitchListTile(
                  secondary: Icon(Icons.admin_panel_settings_outlined, color: AppColors.of(context).textPrimary),
                  title: Text('Только админы пишут', style: TextStyle(color: AppColors.of(context).textPrimary)),
                  subtitle: Text('Участники могут только читать', style: TextStyle(color: AppColors.of(context).textSecondary, fontSize: 12)),
                  value: false, // TODO: bind to conv.slowMode when ConversationEntity gets the field
                  activeColor: AppColors.of(context).primary,
                  onChanged: (val) {
                    // TODO: dispatch UpdateGroupSettings event
                  },
                ),
                SwitchListTile(
                  secondary: Icon(Icons.forum_outlined, color: AppColors.of(context).textPrimary),
                  title: Text('Темы', style: TextStyle(color: AppColors.of(context).textPrimary)),
                  subtitle: Text('Разделить чат на темы', style: TextStyle(color: AppColors.of(context).textSecondary, fontSize: 12)),
                  value: false, // TODO: bind to conv.topicsEnabled
                  activeColor: AppColors.of(context).primary,
                  onChanged: (val) {
                    // TODO: dispatch UpdateGroupSettings event
                  },
                ),
                ListTile(
                  leading: Icon(Icons.timer_outlined, color: AppColors.of(context).textPrimary),
                  title: Text('Авто-удаление сообщений', style: TextStyle(color: AppColors.of(context).textPrimary)),
                  subtitle: Text('Выключено', style: TextStyle(color: AppColors.of(context).textSecondary, fontSize: 12)),
                  onTap: () {
                    // TODO: show picker for 7/30/90 days
                  },
                ),
              ],
              const Divider(height: 32),
              // Leave group
              ListTile(
                leading: Icon(Icons.exit_to_app_rounded, color: AppColors.of(context).error),
                title: Text(l10n.leaveGroup, style: TextStyle(color: AppColors.of(context).error)),
                onTap: _confirmLeaveGroup,
              ),
              // Delete group (OWNER only)
              if (myRole == 'OWNER')
                ListTile(
                  leading: Icon(Icons.delete_forever_rounded, color: AppColors.of(context).error),
                  title: Text(l10n.deleteGroup, style: TextStyle(color: AppColors.of(context).error)),
                  onTap: _confirmDeleteGroup,
                ),
              const SizedBox(height: 32),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMemberTile(GroupMemberEntity member, String myRole, String? myUserId, AppLocalizations l10n) {
    final name = [member.firstName, member.lastName]
        .where((s) => s != null && s.isNotEmpty).join(' ');
    final displayName = name.isNotEmpty ? name : (member.username ?? member.userId);
    final isMe = member.userId == myUserId;
    final canManage = (myRole == 'OWNER' || myRole == 'ADMIN') && !isMe && member.role != 'OWNER';
    final roleColor = _roleColors[member.role] ?? Colors.grey;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: AppColors.of(context).primary,
        child: member.avatarUrl != null
            ? ClipOval(
                child: CachedNetworkImage(
                  imageUrl: member.avatarUrl!,
                  width: 40, height: 40, fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => Text(displayName[0].toUpperCase(),
                      style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                ),
              )
            : Text(displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(displayName,
                style: TextStyle(color: AppColors.of(context).textPrimary)),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: roleColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _roleLabel(member.role, l10n),
              style: TextStyle(color: roleColor, fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      subtitle: member.username != null
          ? Text('@${member.username}',
              style: TextStyle(color: AppColors.of(context).textSecondary, fontSize: 13))
          : null,
      trailing: canManage
          ? IconButton(
              icon: Icon(Icons.more_vert_rounded, color: AppColors.of(context).textSecondary),
              onPressed: () => _showChangeRoleSheet(member, myRole),
            )
          : null,
      onTap: !isMe ? () => context.push('/dashboard/user/${member.userId}') : null,
    );
  }
}

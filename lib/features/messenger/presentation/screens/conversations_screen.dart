import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/storage/cache_service.dart';
import '../../../../core/api/dio_client.dart';
import '../../../../l10n/app_localizations.dart';
import '../bloc/messenger_bloc.dart';
import '../bloc/messenger_event.dart';
import '../bloc/messenger_state.dart';
import '../../domain/entities/conversation_entity.dart';

class ConversationsScreen extends StatefulWidget {
  const ConversationsScreen({super.key});

  @override
  State<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen> {
  String? _myUsername;

  @override
  void initState() {
    super.initState();
    _loadConversationsIfNeeded();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkUsername());
  }

  Future<void> _loadConversationsIfNeeded() async {
    final bloc = context.read<MessengerBloc>();
    if (!bloc.state.isLoading && bloc.state.isConnected) {
      bloc.add(LoadConversations());
    }
  }

  Future<void> _checkUsername() async {
    if (!mounted) return;
    final cache = sl<CacheService>();
    Map<String, dynamic>? profile;
    try {
      final client = sl<DioClient>();
      profile = await client.get(
        '/profile',
        fromJson: (d) => Map<String, dynamic>.from(d as Map),
      );
      if (profile != null) await cache.saveProfile(profile);
    } catch (_) {
      profile = cache.getProfile();
    }
    if (!mounted) return;
    final username = profile?['username'] as String?;
    if (username != null && username.trim().isNotEmpty) {
      setState(() => _myUsername = username.trim());
    } else {
      _showUsernameDialog();
    }
  }

  void _showUsernameDialog() {
    final ctrl = TextEditingController();
    String? errorText;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PopScope(
        canPop: false,
        child: StatefulBuilder(
          builder: (ctx, setDialogState) => AlertDialog(
            backgroundColor: AppColors.of(context).card,
            title: Text(
              'Задайте никнейм',
              style: TextStyle(color: AppColors.of(context).textPrimary),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Никнейм обязателен для использования мессенджера. Другие пользователи смогут найти вас по нему.',
                  style: TextStyle(color: AppColors.of(context).textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: ctrl,
                  autofocus: true,
                  style: TextStyle(color: AppColors.of(context).textPrimary),
                  decoration: InputDecoration(
                    hintText: 'username',
                    hintStyle: TextStyle(color: AppColors.of(context).textSecondary),
                    prefixText: '@',
                    prefixStyle: TextStyle(color: AppColors.of(context).primary),
                    errorText: errorText,
                    border: const OutlineInputBorder(),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: AppColors.of(context).primary),
                    ),
                  ),
                  onChanged: (_) {
                    if (errorText != null) {
                      setDialogState(() => errorText = null);
                    }
                  },
                ),
                const SizedBox(height: 8),
                Text(
                  '3–30 символов: буквы, цифры, _',
                  style: TextStyle(color: AppColors.of(context).textSecondary, fontSize: 11),
                ),
              ],
            ),
            actions: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.of(context).primary,
                    foregroundColor: Colors.black),
                onPressed: () async {
                  final value = ctrl.text.trim();
                  final regex = RegExp(r'^[a-zA-Z0-9_]{3,30}$');
                  if (!regex.hasMatch(value)) {
                    setDialogState(() =>
                        errorText = '3–30 символов: буквы, цифры, _');
                    return;
                  }
                  try {
                    final client = sl<DioClient>();
                    await client.patch(
                      '/profile/username',
                      data: {'username': value},
                      fromJson: (d) => d,
                    );
                    final cache = sl<CacheService>();
                    final currentProfile = cache.getProfile() ?? {};
                    await cache.saveProfile({...currentProfile, 'username': value});
                    if (mounted) setState(() => _myUsername = value);
                    if (ctx.mounted) Navigator.pop(ctx);
                  } on Exception catch (e) {
                    final msg = e.toString();
                    setDialogState(() => errorText =
                        msg.contains('409') ? 'Никнейм уже занят' : 'Ошибка сохранения');
                  }
                },
                child: const Text('Сохранить'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => _ConversationsView(myUsername: _myUsername);
}

class _ConversationsView extends StatelessWidget {
  final String? myUsername;
  const _ConversationsView({this.myUsername});

  void _showContactRequests(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.of(context).card,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.8,
        expand: false,
        builder: (ctx, scrollCtrl) => Column(
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: AppColors.of(context).textSecondary.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Запросы на общение',
                style: TextStyle(
                  color: AppColors.of(context).textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Expanded(
              child: BlocBuilder<MessengerBloc, MessengerState>(
                builder: (context, state) {
                  if (state.contactRequests.isEmpty) {
                    return Center(
                      child: Text(
                        'Нет новых запросов',
                        style: TextStyle(color: AppColors.of(context).textSecondary),
                      ),
                    );
                  }
                  return ListView.builder(
                    controller: scrollCtrl,
                    itemCount: state.contactRequests.length,
                    itemBuilder: (context, i) {
                      final req = state.contactRequests[i];
                      final name = req['senderName'] as String? ?? '';
                      final username = req['senderUsername'] as String?;
                      final email = req['senderEmail'] as String? ?? '';
                      final avatar = req['senderAvatar'] as String?;
                      final id = req['id'] as String;
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.of(context).primary,
                          backgroundImage: avatar != null ? NetworkImage(avatar) : null,
                          child: avatar == null
                              ? Text(
                                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                                  style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                                )
                              : null,
                        ),
                        title: Text(
                          name.isNotEmpty ? name : (username != null ? '@$username' : email),
                          style: TextStyle(color: AppColors.of(context).textPrimary, fontWeight: FontWeight.w600),
                        ),
                        subtitle: username != null
                            ? Text('@$username', style: TextStyle(color: AppColors.of(context).textSecondary, fontSize: 12))
                            : null,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.close_rounded, color: AppColors.of(context).error),
                              onPressed: () {
                                context.read<MessengerBloc>().add(RejectContactRequest(id));
                              },
                            ),
                            IconButton(
                              icon: Icon(Icons.check_rounded, color: Colors.green),
                              onPressed: () {
                                Navigator.pop(ctx);
                                context.read<MessengerBloc>().add(AcceptContactRequest(id));
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showNewChatSheet(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
            ListTile(
              leading: CircleAvatar(
                backgroundColor: AppColors.of(context).primary.withValues(alpha: 0.15),
                child: Icon(Icons.person_add_rounded, color: AppColors.of(context).primary),
              ),
              title: Text(l10n.newChat, style: TextStyle(color: AppColors.of(context).textPrimary)),
              onTap: () {
                Navigator.pop(ctx);
                context.push('/dashboard/messenger/search');
              },
            ),
            ListTile(
              leading: CircleAvatar(
                backgroundColor: AppColors.of(context).primary.withValues(alpha: 0.15),
                child: Icon(Icons.group_add_rounded, color: AppColors.of(context).primary),
              ),
              title: Text(l10n.newGroup, style: TextStyle(color: AppColors.of(context).textPrimary)),
              onTap: () {
                Navigator.pop(ctx);
                context.push('/dashboard/messenger/create-group');
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.of(context).background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.tabMessenger),
            if (myUsername != null && myUsername!.isNotEmpty)
              Text(
                '@$myUsername',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.of(context).textSecondary,
                  fontWeight: FontWeight.normal,
                ),
              ),
          ],
        ),
        actions: [
          // Contact requests badge
          BlocBuilder<MessengerBloc, MessengerState>(
            buildWhen: (prev, curr) => prev.contactRequests.length != curr.contactRequests.length,
            builder: (context, state) {
              final count = state.contactRequests.length;
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.person_add_alt_1_rounded),
                    onPressed: () => context.push('/dashboard/messenger/contacts'),
                  ),
                  if (count > 0)
                    Positioned(
                      right: 6,
                      top: 6,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.of(context).error,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                        child: Text(
                          '$count',
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          // Avatar → Profile
          _ProfileAvatar(),
        ],
      ),
      body: BlocBuilder<MessengerBloc, MessengerState>(
        builder: (context, state) {
          if (state.isLoading && state.conversations.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.conversations.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat_bubble_outline_rounded, size: 64,
                      color: AppColors.of(context).textSecondary),
                  const SizedBox(height: 16),
                  Text('Нет диалогов',
                      style: TextStyle(color: AppColors.of(context).textSecondary, fontSize: 16)),
                  const SizedBox(height: 8),
                  Text('Найдите пользователя чтобы начать переписку',
                      style: TextStyle(color: AppColors.of(context).textSecondary, fontSize: 13),
                      textAlign: TextAlign.center),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async =>
                context.read<MessengerBloc>().add(LoadConversations()),
            child: ListView.separated(
              itemCount: state.conversations.length,
              separatorBuilder: (_, __) =>
                  Divider(color: AppColors.of(context).border, height: 1),
              itemBuilder: (context, index) {
                final conv = state.conversations[index];
                return _ConversationTile(conversation: conv);
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showNewChatSheet(context),
        backgroundColor: AppColors.of(context).primary,
        child: const Icon(Icons.edit_rounded, color: Colors.black),
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  final ConversationEntity conversation;
  const _ConversationTile({required this.conversation});

  @override
  Widget build(BuildContext context) {
    final isGroup = conversation.type == 'GROUP';
    final displayName = isGroup
        ? (conversation.name ?? 'Группа')
        : (conversation.otherUserName ?? 'Пользователь');
    final lastMsg = conversation.lastMessageContent;
    final lastAt = conversation.lastMessageAt;
    final timeStr = lastAt != null
        ? DateFormat('HH:mm').format(lastAt.toLocal())
        : '';

    // Build subtitle for last message
    String? subtitleText;
    if (lastMsg != null) {
      if (conversation.lastMessageIsSystem) {
        subtitleText = _formatSystemMessage(context, lastMsg);
      } else if (isGroup && conversation.lastMessageSenderName != null) {
        subtitleText = '${conversation.lastMessageSenderName}: $lastMsg';
      } else {
        subtitleText = lastMsg;
      }
    }

    final avatar = isGroup ? conversation.avatarUrl : conversation.otherUserAvatar;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: CircleAvatar(
        backgroundColor: isGroup
            ? AppColors.of(context).primary.withValues(alpha: 0.7)
            : AppColors.of(context).primary,
        child: avatar != null
            ? ClipOval(
                child: CachedNetworkImage(
                  imageUrl: avatar,
                  width: 40, height: 40, fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => _avatarLetter(context, displayName, isGroup),
                ),
              )
            : _avatarLetter(context, displayName, isGroup),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              displayName,
              style: TextStyle(
                  color: AppColors.of(context).textPrimary, fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      subtitle: subtitleText != null
          ? Text(
              subtitleText,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  color: AppColors.of(context).textSecondary, fontSize: 13),
            )
          : isGroup
              ? Text(
                  AppLocalizations.of(context)!.participantsCount(conversation.participantCount),
                  style: TextStyle(color: AppColors.of(context).textSecondary, fontSize: 13),
                )
              : null,
      trailing: (timeStr.isNotEmpty || conversation.unreadCount > 0 || conversation.isMuted)
          ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (timeStr.isNotEmpty)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(timeStr,
                          style: TextStyle(color: AppColors.of(context).textSecondary, fontSize: 12)),
                      if (conversation.isMuted) ...[
                        const SizedBox(width: 4),
                        Icon(Icons.volume_off, size: 14, color: AppColors.of(context).textSecondary),
                      ],
                    ],
                  ),
                if (conversation.unreadCount > 0) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: conversation.isMuted
                          ? AppColors.of(context).textSecondary
                          : AppColors.of(context).error,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${conversation.unreadCount}',
                      style: const TextStyle(
                          color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ],
            )
          : null,
      onTap: () => context.push('/dashboard/messenger/${conversation.id}'),
    );
  }

  Widget _avatarLetter(BuildContext context, String name, bool isGroup) {
    if (isGroup) {
      return const Icon(Icons.group_rounded, color: Colors.black, size: 22);
    }
    return Text(
      name.isNotEmpty ? name[0].toUpperCase() : '?',
      style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
    );
  }

  String _formatSystemMessage(BuildContext ctx, String content) {
    try {
      final data = jsonDecode(content) as Map<String, dynamic>;
      final action = data['action'] as String?;
      final actor = data['actor'] as String? ?? '';
      final target = data['target'] as String? ?? '';
      final role = data['role'] as String? ?? '';
      final l10n = AppLocalizations.of(context)!;
      switch (action) {
        case 'group_created': return l10n.groupCreated;
        case 'member_added': return l10n.memberJoined(target);
        case 'member_left': return l10n.memberLeftGroup(actor);
        case 'member_removed': return l10n.memberWasRemoved(target);
        case 'role_changed': return l10n.roleChangedTo(target, role);
        default: return content;
      }
    } catch (_) {
      return content;
    }
  }
}

class _ProfileAvatar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cache = sl<CacheService>();
    final profile = cache.getProfile();
    final avatarUrl = profile?['avatarUrl'] as String?;
    final firstName = profile?['firstName'] as String? ?? '';

    return GestureDetector(
      onTap: () => context.push('/dashboard/profile'),
      child: Padding(
        padding: const EdgeInsets.only(right: 8),
        child: CircleAvatar(
          radius: 16,
          backgroundColor: AppColors.of(context).primary,
          backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
              ? CachedNetworkImageProvider(avatarUrl)
              : null,
          child: (avatarUrl == null || avatarUrl.isEmpty)
              ? Text(
                  firstName.isNotEmpty ? firstName[0].toUpperCase() : '?',
                  style: const TextStyle(color: Colors.black, fontSize: 13, fontWeight: FontWeight.bold),
                )
              : null,
        ),
      ),
    );
  }
}

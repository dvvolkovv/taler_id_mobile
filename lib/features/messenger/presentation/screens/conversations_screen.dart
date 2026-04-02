import 'dart:async';
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../voice/presentation/widgets/pulsing_avatar.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/storage/cache_service.dart';
import '../../../../core/api/dio_client.dart';
import '../../../../l10n/app_localizations.dart';
import '../bloc/messenger_bloc.dart';
import '../bloc/messenger_event.dart';
import '../bloc/messenger_state.dart';
import '../../domain/entities/conversation_entity.dart';
import 'saved_messages_screen.dart';

enum _FilterTab { all, unread, personal, groups }

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
    final l10n = AppLocalizations.of(context)!;
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
              l10n.convSetNickname,
              style: TextStyle(color: AppColors.of(context).textPrimary),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.convNicknameRequired,
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
                  l10n.convNicknameRules,
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
                        errorText = l10n.convNicknameRules);
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
                        msg.contains('409') ? l10n.convNicknameTaken : l10n.convSaveError);
                  }
                },
                child: Text(l10n.save),
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

class _ConversationsView extends StatefulWidget {
  final String? myUsername;
  const _ConversationsView({this.myUsername});

  @override
  State<_ConversationsView> createState() => _ConversationsViewState();
}

class _ConversationsViewState extends State<_ConversationsView> {
  static const _prefsBox = 'messenger_prefs';

  final _searchCtrl = TextEditingController();
  String _searchQuery = '';
  List<Map<String, dynamic>> _messageSearchResults = [];
  bool _messageSearching = false;

  _FilterTab _activeFilter = _FilterTab.all;
  Set<String> _pinnedIds = {};
  Set<String> _archivedIds = {};
  bool _showArchived = false;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    Box box;
    try {
      box = Hive.isBoxOpen(_prefsBox)
          ? Hive.box(_prefsBox)
          : await Hive.openBox(_prefsBox);
    } catch (_) {
      await Hive.deleteBoxFromDisk(_prefsBox);
      box = await Hive.openBox(_prefsBox);
    }
    final pinned = box.get('pinned');
    final archived = box.get('archived');
    if (mounted) {
      setState(() {
        if (pinned != null) _pinnedIds = Set<String>.from(pinned as List);
        if (archived != null) _archivedIds = Set<String>.from(archived as List);
      });
    }
  }

  Future<void> _savePrefs() async {
    final box = Hive.isBoxOpen(_prefsBox)
        ? Hive.box(_prefsBox)
        : await Hive.openBox(_prefsBox);
    await box.put('pinned', _pinnedIds.toList());
    await box.put('archived', _archivedIds.toList());
  }

  void _togglePin(String id) {
    setState(() {
      if (_pinnedIds.contains(id)) {
        _pinnedIds = {..._pinnedIds}..remove(id);
      } else {
        _pinnedIds = {..._pinnedIds, id};
      }
    });
    _savePrefs();
  }

  void _toggleArchive(String id) {
    setState(() {
      if (_archivedIds.contains(id)) {
        _archivedIds = {..._archivedIds}..remove(id);
      } else {
        _archivedIds = {..._archivedIds, id};
        _pinnedIds = {..._pinnedIds}..remove(id);
      }
    });
    _savePrefs();
  }

  void _showConversationActions(BuildContext context, ConversationEntity conv) {
    final colors = AppColors.of(context);
    final isPinned = _pinnedIds.contains(conv.id);
    final isArchived = _archivedIds.contains(conv.id);
    final isGroup = conv.type == 'GROUP';
    final name = isGroup ? (conv.name ?? 'Группа') : (conv.otherUserName ?? 'Пользователь');
    showModalBottomSheet(
      context: context,
      backgroundColor: colors.card,
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
                color: colors.textSecondary.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Text(
                name,
                style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 16),
              ),
            ),
            if (!isArchived)
              ListTile(
                leading: Icon(isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                    color: colors.primary),
                title: Text(isPinned ? 'Открепить' : 'Закрепить',
                    style: TextStyle(color: colors.textPrimary)),
                onTap: () { Navigator.pop(ctx); _togglePin(conv.id); },
              ),
            ListTile(
              leading: Icon(isArchived ? Icons.unarchive_outlined : Icons.archive_outlined,
                  color: colors.textSecondary),
              title: Text(isArchived ? 'Разархивировать' : 'Архивировать',
                  style: TextStyle(color: colors.textPrimary)),
              onTap: () { Navigator.pop(ctx); _toggleArchive(conv.id); },
            ),
            ListTile(
              leading: Icon(Icons.delete_outline_rounded, color: Colors.red.shade400),
              title: Text('Удалить чат', style: TextStyle(color: Colors.red.shade400)),
              onTap: () {
                Navigator.pop(ctx);
                _confirmDeleteChat(context, conv);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteChat(BuildContext context, ConversationEntity conv) {
    final colors = AppColors.of(context);
    final isGroup = conv.type == 'GROUP';
    final name = isGroup ? (conv.name ?? 'Группа') : (conv.otherUserName ?? 'Пользователь');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.card,
        title: Text('Удалить чат?', style: TextStyle(color: colors.textPrimary)),
        content: Text(
          'Удалить чат с $name? Это действие нельзя отменить.',
          style: TextStyle(color: colors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Отмена', style: TextStyle(color: colors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<MessengerBloc>().add(DeleteGroup(conv.id));
            },
            child: Text('Удалить', style: TextStyle(color: Colors.red.shade400)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _showNewChatSheet(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.of(context).card,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        final convs = context.read<MessengerBloc>().state.conversations;
        final contacts = convs.where((c) => c.type == 'DIRECT').toList();
        return DraggableScrollableSheet(
          initialChildSize: contacts.isEmpty ? 0.3 : 0.6,
          minChildSize: 0.25,
          maxChildSize: 0.85,
          expand: false,
          builder: (ctx, scrollCtrl) => SafeArea(
            child: Column(
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
                if (contacts.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        l10n.convContactsLabel,
                        style: TextStyle(
                          color: AppColors.of(context).textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.builder(
                      controller: scrollCtrl,
                      itemCount: contacts.length,
                      itemBuilder: (context, i) {
                        final c = contacts[i];
                        final name = c.otherUserName ?? l10n.convDefaultUser;
                        final avatar = c.otherUserAvatar;
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppColors.of(context).primary,
                            backgroundImage: avatar != null && avatar.isNotEmpty
                                ? CachedNetworkImageProvider(avatar)
                                : null,
                            child: (avatar == null || avatar.isEmpty)
                                ? Text(
                                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                                    style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                                  )
                                : null,
                          ),
                          title: Text(name, style: TextStyle(color: AppColors.of(context).textPrimary)),
                          onTap: () {
                            Navigator.pop(ctx);
                            context.push('/dashboard/messenger/${c.id}');
                          },
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Timer? _searchDebounce;

  void _searchMessagesDebounced(String query) {
    _searchDebounce?.cancel();
    if (query.length < 2) {
      setState(() { _messageSearchResults = []; _messageSearching = false; });
      return;
    }
    setState(() => _messageSearching = true);
    _searchDebounce = Timer(const Duration(milliseconds: 500), () async {
      try {
        final data = await sl<DioClient>().get<dynamic>('/messenger/messages/search?q=${Uri.encodeComponent(query)}');
        if (mounted) setState(() { _messageSearchResults = (data as List).map((e) => Map<String, dynamic>.from(e as Map)).toList(); _messageSearching = false; });
      } catch (_) {
        if (mounted) setState(() => _messageSearching = false);
      }
    });
  }

  List<ConversationEntity> _filterConversations(
    List<ConversationEntity> convs, {
    bool archivedOnly = false,
  }) {
    var result = convs.where((c) {
      return archivedOnly ? _archivedIds.contains(c.id) : !_archivedIds.contains(c.id);
    }).toList();

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      result = result.where((c) {
        final name = (c.type == 'GROUP' ? (c.name ?? '') : (c.otherUserName ?? '')).toLowerCase();
        return name.contains(q);
      }).toList();
    }

    if (!archivedOnly) {
      switch (_activeFilter) {
        case _FilterTab.unread:
          result = result.where((c) => c.unreadCount > 0).toList();
          break;
        case _FilterTab.personal:
          result = result.where((c) => c.type == 'DIRECT').toList();
          break;
        case _FilterTab.groups:
          result = result.where((c) => c.type == 'GROUP').toList();
          break;
        case _FilterTab.all:
          break;
      }
    }

    if (!archivedOnly) {
      result.sort((a, b) {
        final aPinned = _pinnedIds.contains(a.id) ? 0 : 1;
        final bPinned = _pinnedIds.contains(b.id) ? 0 : 1;
        if (aPinned != bPinned) return aPinned.compareTo(bPinned);
        final aTime = a.lastMessageAt ?? DateTime(0);
        final bTime = b.lastMessageAt ?? DateTime(0);
        return bTime.compareTo(aTime);
      });
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = AppColors.of(context);
    return Scaffold(
      backgroundColor: colors.background,
      body: BlocBuilder<MessengerBloc, MessengerState>(
        builder: (context, state) {
          final filtered = _filterConversations(state.conversations);
          final archived = _filterConversations(state.conversations, archivedOnly: true);
          final totalUnread = state.conversations
              .where((c) => !_archivedIds.contains(c.id))
              .fold(0, (sum, c) => sum + c.unreadCount);

          Widget buildTile(ConversationEntity conv) {
            final isPinned = _pinnedIds.contains(conv.id);
            final isArchived = _archivedIds.contains(conv.id);
            return Dismissible(
              key: ValueKey('dismiss_${conv.id}'),
              confirmDismiss: (direction) async {
                HapticFeedback.mediumImpact();
                if (direction == DismissDirection.endToStart) {
                  _toggleArchive(conv.id);
                } else {
                  _togglePin(conv.id);
                }
                return false; // don't remove from list
              },
              background: Container(
                color: colors.primary.withValues(alpha: 0.15),
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.only(left: 24),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(isPinned ? Icons.push_pin_outlined : Icons.push_pin,
                        color: colors.primary),
                    const SizedBox(width: 8),
                    Text(isPinned ? 'Открепить' : 'Закрепить',
                        style: TextStyle(color: colors.primary, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              secondaryBackground: Container(
                color: isArchived
                    ? Colors.green.withValues(alpha: 0.15)
                    : Colors.orange.withValues(alpha: 0.15),
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 24),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(isArchived ? 'Разархивировать' : 'Архивировать',
                        style: TextStyle(
                          color: isArchived ? Colors.green : Colors.orange,
                          fontWeight: FontWeight.w600,
                        )),
                    const SizedBox(width: 8),
                    Icon(isArchived ? Icons.unarchive_outlined : Icons.archive_outlined,
                        color: isArchived ? Colors.green : Colors.orange),
                  ],
                ),
              ),
              child: Column(
                children: [
                  _ConversationTile(
                    conversation: conv,
                    currentUserId: state.currentUserId,
                    isPinned: isPinned,
                    onLongPress: () => _showConversationActions(context, conv),
                  ),
                  Divider(color: colors.border, height: 1),
                ],
              ),
            );
          }

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                centerTitle: true,
                floating: true,
                snap: true,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded),
                  onPressed: () => context.go('/dashboard/assistant'),
                ),
                title: Text(l10n.tabMessenger),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.bookmark_outline_rounded),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SavedMessagesScreen()),
                    ),
                    tooltip: 'Избранное',
                  ),
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
                                  color: colors.error,
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
                ],
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(52),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: TextField(
                      controller: _searchCtrl,
                      style: TextStyle(color: colors.textPrimary, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: l10n.chatSearchHint,
                        hintStyle: TextStyle(color: colors.textSecondary, fontSize: 14),
                        prefixIcon: Icon(Icons.search, color: colors.textSecondary, size: 20),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: Icon(Icons.close, color: colors.textSecondary, size: 18),
                                onPressed: () {
                                  _searchCtrl.clear();
                                  setState(() => _searchQuery = '');
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: colors.surface,
                        contentPadding: const EdgeInsets.symmetric(vertical: 8),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onChanged: (v) {
                        setState(() => _searchQuery = v.trim());
                        _searchMessagesDebounced(v.trim());
                      },
                    ),
                  ),
                ),
              ),
              // Filter chips
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 44,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                    children: [
                      _TabChip(
                        label: 'Все',
                        selected: _activeFilter == _FilterTab.all,
                        onTap: () => setState(() => _activeFilter = _FilterTab.all),
                      ),
                      const SizedBox(width: 8),
                      _TabChip(
                        label: 'Непрочитанные',
                        selected: _activeFilter == _FilterTab.unread,
                        badge: _activeFilter != _FilterTab.unread && totalUnread > 0 ? totalUnread : null,
                        onTap: () => setState(() => _activeFilter = _FilterTab.unread),
                      ),
                      const SizedBox(width: 8),
                      _TabChip(
                        label: 'Личные',
                        selected: _activeFilter == _FilterTab.personal,
                        onTap: () => setState(() => _activeFilter = _FilterTab.personal),
                      ),
                      const SizedBox(width: 8),
                      _TabChip(
                        label: 'Группы',
                        selected: _activeFilter == _FilterTab.groups,
                        onTap: () => setState(() => _activeFilter = _FilterTab.groups),
                      ),
                    ],
                  ),
                ),
              ),
              if (state.isLoading && state.conversations.isEmpty)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (filtered.isEmpty && _activeFilter == _FilterTab.all && _searchQuery.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline_rounded, size: 64, color: colors.textSecondary),
                        const SizedBox(height: 16),
                        Text(l10n.convNoDialogs, style: TextStyle(color: colors.textSecondary, fontSize: 16)),
                        const SizedBox(height: 8),
                        Text(l10n.convFindUserToChat,
                            style: TextStyle(color: colors.textSecondary, fontSize: 13),
                            textAlign: TextAlign.center),
                      ],
                    ),
                  ),
                )
              else ...[
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => buildTile(filtered[index]),
                    childCount: filtered.length,
                  ),
                ),
                // Archived section
                if (archived.isNotEmpty && _searchQuery.isEmpty && _activeFilter == _FilterTab.all) ...[
                  SliverToBoxAdapter(
                    child: InkWell(
                      onTap: () => setState(() => _showArchived = !_showArchived),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          children: [
                            Container(
                              width: 40, height: 40,
                              decoration: BoxDecoration(
                                color: colors.surface,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.archive_outlined, color: colors.primary, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Архивировано',
                                style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w500),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: colors.surface,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${archived.length}',
                                style: TextStyle(color: colors.textSecondary, fontSize: 12),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              _showArchived ? Icons.expand_less : Icons.chevron_right,
                              color: colors.textSecondary, size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (_showArchived)
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => buildTile(archived[index]),
                        childCount: archived.length,
                      ),
                    ),
                ],
              ],
              // Message search results
              if (_searchQuery.length >= 2) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Row(
                      children: [
                        Icon(Icons.message_outlined, size: 16, color: colors.textSecondary),
                        const SizedBox(width: 8),
                        Text(
                          _messageSearching ? 'Поиск в сообщениях...' : 'Найдено в сообщениях (${_messageSearchResults.length})',
                          style: TextStyle(color: colors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_messageSearchResults.isNotEmpty)
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final msg = _messageSearchResults[index];
                        final content = msg['content'] as String? ?? '';
                        final sender = msg['senderName'] as String? ?? '';
                        final convId = msg['conversationId'] as String? ?? '';
                        final sentAt = DateTime.tryParse(msg['sentAt'] as String? ?? '')?.toLocal();
                        final timeStr = sentAt != null ? DateFormat('dd.MM HH:mm').format(sentAt) : '';
                        return ListTile(
                          dense: true,
                          leading: Icon(Icons.chat_bubble_outline, size: 20, color: colors.primary),
                          title: Text(sender, style: TextStyle(color: colors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
                          subtitle: Text(
                            content,
                            style: TextStyle(color: colors.textSecondary, fontSize: 12),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: Text(timeStr, style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                          onTap: () => context.push('/dashboard/messenger/$convId'),
                        );
                      },
                      childCount: _messageSearchResults.length,
                    ),
                  ),
              ],
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showNewChatSheet(context),
        backgroundColor: colors.primary,
        child: const Icon(Icons.edit_rounded, color: Colors.black),
      ),
    );
  }
}

class _TabChip extends StatelessWidget {
  final String label;
  final bool selected;
  final int? badge;
  final VoidCallback onTap;
  const _TabChip({required this.label, required this.selected, required this.onTap, this.badge});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? colors.primary : colors.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.black : colors.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            if (badge != null && badge! > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: selected ? Colors.black26 : colors.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$badge',
                  style: TextStyle(
                    color: selected ? Colors.black : Colors.black,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  final ConversationEntity conversation;
  final String? currentUserId;
  final bool isPinned;
  final VoidCallback? onLongPress;
  const _ConversationTile({
    required this.conversation,
    this.currentUserId,
    this.isPinned = false,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isGroup = conversation.type == 'GROUP';
    final displayName = isGroup
        ? (conversation.name ?? l10n.chatGroup)
        : (conversation.otherUserName ?? l10n.convDefaultUser);
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
      } else {
        String displayMsg = lastMsg;
        // Format contact card preview
        if (lastMsg.startsWith('[CONTACT]')) {
          try {
            final json = lastMsg.substring('[CONTACT]'.length);
            final data = Map<String, dynamic>.from(
              const JsonDecoder().convert(json) as Map,
            );
            displayMsg = '👤 ${data['name'] ?? l10n.convDefaultContact}';
          } catch (_) {
            displayMsg = '👤 ${l10n.convDefaultContact}';
          }
        }
        if (conversation.lastMessageSenderId != null &&
            conversation.lastMessageSenderId == currentUserId) {
          subtitleText = 'Вы: $displayMsg';
        } else if (isGroup && conversation.lastMessageSenderName != null) {
          subtitleText = '${conversation.lastMessageSenderName}: $displayMsg';
        } else {
          subtitleText = displayMsg;
        }
      }
    }

    final avatar = isGroup ? conversation.avatarUrl : conversation.otherUserAvatar;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: rainbowColorFor(displayName), width: 2),
        ),
        child: CircleAvatar(
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
      trailing: () {
        final isMissedCall = conversation.lastMessageIsSystem &&
            lastMsg != null &&
            (lastMsg.contains('Пропущенный звонок') || lastMsg.contains('Missed call')) &&
            conversation.lastMessageSenderId != currentUserId &&
            conversation.unreadCount > 0;
        if (!timeStr.isNotEmpty && conversation.unreadCount == 0 && !conversation.isMuted && !isMissedCall) {
          return null;
        }
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (timeStr.isNotEmpty)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isPinned) ...[
                    Icon(Icons.push_pin, size: 12, color: AppColors.of(context).textSecondary),
                    const SizedBox(width: 4),
                  ],
                  Text(timeStr,
                      style: TextStyle(color: AppColors.of(context).textSecondary, fontSize: 12)),
                  if (conversation.isMuted) ...[
                    const SizedBox(width: 4),
                    Icon(Icons.volume_off, size: 14, color: AppColors.of(context).textSecondary),
                  ],
                ],
              ),
            if (isMissedCall) ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.of(context).error,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.phone_missed_rounded, color: Colors.white, size: 11),
                    const SizedBox(width: 3),
                    const Text('1', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ] else if (conversation.unreadCount > 0) ...[
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
        );
      }(),
      onTap: () => context.push('/dashboard/messenger/${conversation.id}'),
      onLongPress: onLongPress,
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

  String _formatSystemMessage(BuildContext context, String content) {
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

    final glowColor = rainbowColorFor(firstName.isNotEmpty ? firstName : 'user');
    return GestureDetector(
      onTap: () => context.push('/dashboard/profile'),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: glowColor, width: 2),
          ),
          child: CircleAvatar(
            radius: 30,
            backgroundColor: AppColors.of(context).primary,
            backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                ? CachedNetworkImageProvider(avatarUrl)
                : null,
            child: (avatarUrl == null || avatarUrl.isEmpty)
                ? Text(
                    firstName.isNotEmpty ? firstName[0].toUpperCase() : '?',
                    style: const TextStyle(color: Colors.black, fontSize: 22, fontWeight: FontWeight.bold),
                  )
                : null,
          ),
        ),
      ),
    );
  }
}

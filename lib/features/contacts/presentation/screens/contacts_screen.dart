import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/api/dio_client.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../messenger/data/datasources/messenger_remote_datasource.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  late Future<List<_Contact>> _contactsFuture;
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _contactsFuture = _loadContacts();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<List<_Contact>> _loadContacts() async {
    final data = await sl<DioClient>().get<dynamic>('/messenger/conversations');
    final list = (data as List?) ?? [];
    final contacts = <_Contact>[];
    for (final item in list) {
      final conv = Map<String, dynamic>.from(item as Map);
      final type = conv['type'] as String? ?? 'direct';
      if (type != 'direct') continue;
      contacts.add(_Contact(
        conversationId: conv['id'] as String,
        userId: conv['otherUserId'] as String? ?? '',
        name: conv['otherUserName'] as String? ?? 'Пользователь',
        username: conv['otherUserUsername'] as String?,
        avatarUrl: conv['otherUserAvatar'] as String?,
      ));
    }
    contacts.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return contacts;
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Scaffold(
      backgroundColor: colors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            centerTitle: true,
            floating: true,
            snap: true,
            title: const Text('Контакты'),
            actions: [
              IconButton(
                icon: const Icon(Icons.person_add_alt_1_rounded),
                onPressed: () => context.push('/dashboard/messenger/contacts'),
                tooltip: 'Добавить контакт',
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
                    hintText: 'Поиск контактов...',
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
                  onChanged: (v) => setState(() => _searchQuery = v.trim()),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            sliver: FutureBuilder<List<_Contact>>(
              future: _contactsFuture,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: colors.primary)),
                  );
                }
                if (snap.hasError) {
                  return SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.error_outline, color: colors.error, size: 36),
                          const SizedBox(height: 8),
                          Text('Ошибка загрузки', style: TextStyle(color: colors.textPrimary)),
                          TextButton(
                            onPressed: () => setState(() => _contactsFuture = _loadContacts()),
                            child: Text('Повторить', style: TextStyle(color: colors.primary)),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                var contacts = snap.data ?? [];
                if (_searchQuery.isNotEmpty) {
                  final q = _searchQuery.toLowerCase();
                  contacts = contacts.where((c) =>
                    c.name.toLowerCase().contains(q) ||
                    (c.username?.toLowerCase().contains(q) ?? false)
                  ).toList();
                }

                if (contacts.isEmpty) {
                  return SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.people_outline, size: 48, color: colors.textSecondary.withValues(alpha: 0.5)),
                          const SizedBox(height: 12),
                          Text(
                            _searchQuery.isNotEmpty ? 'Ничего не найдено' : 'Нет контактов',
                            style: TextStyle(color: colors.textSecondary, fontSize: 16),
                          ),
                          if (_searchQuery.isEmpty) ...[
                            const SizedBox(height: 8),
                            TextButton.icon(
                              onPressed: () => context.push('/dashboard/messenger/contacts'),
                              icon: Icon(Icons.person_add, color: colors.primary, size: 18),
                              label: Text('Добавить контакт', style: TextStyle(color: colors.primary)),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }

                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _buildContactTile(contacts[index], colors),
                    childCount: contacts.length,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactTile(_Contact contact, AppColorsExtension colors) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: colors.primary.withValues(alpha: 0.15),
          backgroundImage: contact.avatarUrl != null
              ? CachedNetworkImageProvider(contact.avatarUrl!)
              : null,
          child: contact.avatarUrl == null
              ? Text(
                  contact.name.isNotEmpty ? contact.name[0].toUpperCase() : '?',
                  style: TextStyle(color: colors.primary, fontWeight: FontWeight.bold, fontSize: 18),
                )
              : null,
        ),
        title: Text(
          contact.name,
          style: TextStyle(color: colors.textPrimary, fontSize: 16, fontWeight: FontWeight.w500),
        ),
        subtitle: contact.username != null
            ? Text(
                '@${contact.username}',
                style: TextStyle(color: colors.textSecondary, fontSize: 13),
              )
            : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.chat_bubble_outline_rounded, size: 20, color: colors.primary),
              onPressed: () => context.push('/dashboard/messenger/chat/${contact.conversationId}'),
              tooltip: 'Написать',
            ),
            IconButton(
              icon: Icon(Icons.call_rounded, size: 20, color: colors.primary),
              onPressed: () => _startCall(contact),
              tooltip: 'Позвонить',
            ),
          ],
        ),
        onTap: () => context.push('/dashboard/user/${contact.userId}'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _startCall(_Contact contact) async {
    try {
      final room = await sl<DioClient>().post<Map<String, dynamic>>(
        '/voice/rooms',
        data: {'conversationId': contact.conversationId, 'withAi': false},
        fromJson: (d) => Map<String, dynamic>.from(d as Map),
      );
      final roomName = room?['roomName'] as String? ?? '';
      if (mounted) {
        sl<MessengerRemoteDataSource>().sendCallInvite(contact.conversationId, roomName);
        final calleeEncoded = Uri.encodeComponent(contact.name);
        String avatarParam = '';
        if (contact.avatarUrl != null && contact.avatarUrl!.isNotEmpty) {
          avatarParam = '&calleeAvatar=${Uri.encodeComponent(contact.avatarUrl!)}';
        }
        context.push('/dashboard/voice?room=$roomName&convId=${contact.conversationId}&callee=$calleeEncoded$avatarParam&calleeId=${contact.userId}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}

class _Contact {
  final String conversationId;
  final String userId;
  final String name;
  final String? username;
  final String? avatarUrl;

  _Contact({
    required this.conversationId,
    required this.userId,
    required this.name,
    this.username,
    this.avatarUrl,
  });
}

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/api/dio_client.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/services/contacts_cache_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/widgets.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../messenger/data/datasources/messenger_remote_datasource.dart';
import '../../../voice/presentation/widgets/pulsing_avatar.dart' show rainbowColorFor;

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  final _searchCtrl = TextEditingController();
  final _cache = sl<ContactsCacheService>();
  String _searchQuery = '';
  List<_ContactItem> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    final cached = _cache.get();
    if (cached != null && cached.isNotEmpty) {
      _items = cached.map(_ContactItem.fromJson).toList();
      _loading = false;
    }
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (_items.isEmpty) setState(() => _loading = true);
    try {
      final client = sl<DioClient>();
      final items = <_ContactItem>[];

      // 1. Incoming contact requests (shown at the top)
      final incomingData = await client.get<dynamic>('/messenger/contacts/requests');
      final incomingList = (incomingData as List?) ?? [];
      for (final item in incomingList) {
        final req = Map<String, dynamic>.from(item as Map);
        if ((req['status'] as String? ?? 'PENDING') != 'PENDING') continue;
        items.add(_ContactItem(
          userId: req['senderId'] as String? ?? '',
          name: req['senderName'] as String? ?? '',
          username: req['senderUsername'] as String?,
          avatarUrl: req['senderAvatar'] as String?,
          status: _ContactStatus.incoming,
          requestId: req['id'] as String?,
        ));
      }

      // 2. Accepted contacts from conversations
      final convData = await client.get<dynamic>('/messenger/conversations');
      final convList = (convData as List?) ?? [];
      final incomingUserIds = items.map((e) => e.userId).toSet();
      for (final item in convList) {
        final conv = Map<String, dynamic>.from(item as Map);
        if ((conv['type'] as String? ?? 'DIRECT').toUpperCase() != 'DIRECT') continue;
        final uid = conv['otherUserId'] as String? ?? '';
        if (incomingUserIds.contains(uid)) continue;
        items.add(_ContactItem(
          conversationId: conv['id'] as String,
          userId: uid,
          name: conv['otherUserName'] as String? ?? AppLocalizations.of(context)!.convDefaultUser,
          username: conv['otherUserUsername'] as String?,
          avatarUrl: conv['otherUserAvatar'] as String?,
          status: _ContactStatus.accepted,
        ));
      }

      // 3. Sent pending requests
      final sentData = await client.get<dynamic>('/messenger/contacts/requests/sent');
      final sentList = (sentData as List?) ?? [];
      final knownIds = items.map((e) => e.userId).toSet();
      for (final item in sentList) {
        final req = Map<String, dynamic>.from(item as Map);
        if ((req['status'] as String? ?? 'PENDING') != 'PENDING') continue;
        final receiverId = req['receiverId'] as String? ?? '';
        if (knownIds.contains(receiverId)) continue;
        items.add(_ContactItem(
          userId: receiverId,
          name: req['receiverName'] as String? ?? '',
          username: req['receiverUsername'] as String?,
          avatarUrl: req['receiverAvatar'] as String?,
          status: _ContactStatus.pending,
          requestId: req['id'] as String?,
          requestSentAt: DateTime.tryParse(req['updatedAt'] as String? ?? '') ??
              DateTime.tryParse(req['createdAt'] as String? ?? ''),
        ));
      }

      // Sort: incoming first, then accepted (alpha), then pending
      items.sort((a, b) {
        final order = {_ContactStatus.incoming: 0, _ContactStatus.accepted: 1, _ContactStatus.pending: 2};
        final cmp = order[a.status]!.compareTo(order[b.status]!);
        if (cmp != 0) return cmp;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });

      _cache.save(items.map((e) => e.toJson()).toList());
      if (mounted) setState(() { _items = items; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _acceptRequest(_ContactItem contact) async {
    if (contact.requestId == null) return;
    try {
      await sl<DioClient>().patch(
        '/messenger/contacts/requests/${contact.requestId}/accept',
        data: {},
        fromJson: (d) => d,
      );
      HapticFeedback.mediumImpact();
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.errorWithMessage(e.toString())), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _declineRequest(_ContactItem contact) async {
    if (contact.requestId == null) return;
    try {
      await sl<DioClient>().patch(
        '/messenger/contacts/requests/${contact.requestId}/decline',
        data: {},
        fromJson: (d) => d,
      );
      HapticFeedback.lightImpact();
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.errorWithMessage(e.toString())), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: colors.background,
      body: RefreshIndicator(
        color: colors.primary,
        onRefresh: _load,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              centerTitle: true,
              floating: true,
              snap: true,
              title: Text(l10n.contactsTitle),
              actions: [
                IconButton(
                  icon: const Icon(Icons.person_add_alt_1_rounded),
                  onPressed: () async {
                    await context.push('/dashboard/messenger/contacts');
                    _load();
                  },
                  tooltip: l10n.contactsSearchPeople,
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
                      hintText: l10n.contactsSearchHint,
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
            if (_loading)
              SliverFillRemaining(
                child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: colors.primary)),
              )
            else
              _buildList(colors),
          ],
        ),
      ),
    );
  }

  Widget _buildList(AppColorsExtension colors) {
    final l10n = AppLocalizations.of(context)!;
    var filtered = _items;
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      filtered = filtered.where((c) =>
        c.name.toLowerCase().contains(q) ||
        (c.username?.toLowerCase().contains(q) ?? false)
      ).toList();
    }

    if (filtered.isEmpty) {
      return SliverFillRemaining(
        child: EmptyStateView(
          icon: _searchQuery.isNotEmpty ? Icons.search_off_rounded : Icons.people_rounded,
          title: _searchQuery.isNotEmpty ? l10n.contactsNotFound : l10n.contactsEmpty,
          gradient: const [Color(0xFF22D3EE), Color(0xFF3B82F6)],
          action: _searchQuery.isEmpty
              ? TextButton.icon(
                  onPressed: () async {
                    await context.push('/dashboard/messenger/search');
                    _load();
                  },
                  icon: Icon(Icons.person_add, color: colors.primary, size: 18),
                  label: Text(l10n.contactsAdd, style: TextStyle(color: colors.primary)),
                )
              : null,
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) => _buildTile(filtered[index], colors),
          childCount: filtered.length,
        ),
      ),
    );
  }

  Widget _buildTile(_ContactItem contact, AppColorsExtension colors) {
    final l10n = AppLocalizations.of(context)!;
    final ringColor = rainbowColorFor(contact.name.isNotEmpty ? contact.name : contact.userId);

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: ringColor, width: 2),
            boxShadow: [
              BoxShadow(color: ringColor.withValues(alpha: 0.35), blurRadius: 8),
            ],
          ),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                center: const Alignment(-0.3, -0.4),
                radius: 1.1,
                colors: [
                  Color.lerp(ringColor, Colors.white, 0.28)!,
                  ringColor,
                  Color.lerp(ringColor, Colors.black, 0.38)!,
                ],
                stops: const [0.0, 0.55, 1.0],
              ),
            ),
            child: CircleAvatar(
              radius: 22,
              backgroundColor: Colors.transparent,
              backgroundImage: contact.avatarUrl != null && contact.avatarUrl!.isNotEmpty
                  ? CachedNetworkImageProvider(contact.avatarUrl!)
                  : null,
              child: contact.avatarUrl == null || contact.avatarUrl!.isEmpty
                  ? Text(
                      contact.name.isNotEmpty ? contact.name[0].toUpperCase() : '?',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                    )
                  : null,
            ),
          ),
        ),
        title: Text(
          contact.name,
          style: TextStyle(color: colors.textPrimary, fontSize: 16, fontWeight: FontWeight.w500),
        ),
        subtitle: contact.status == _ContactStatus.incoming
            ? Text(l10n.contactsWantsToConnect, style: TextStyle(color: colors.accent, fontSize: 12, fontWeight: FontWeight.w600))
            : contact.status == _ContactStatus.pending
                ? Text(l10n.contactsPendingConfirmation, style: TextStyle(color: colors.textSecondary, fontSize: 12))
                : contact.username != null
                    ? Text('@${contact.username}', style: TextStyle(color: colors.textSecondary, fontSize: 13))
                    : null,
        trailing: switch (contact.status) {
          _ContactStatus.incoming => Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _miniGradientButton(
                icon: Icons.check_rounded,
                gradient: const [Color(0xFF34D399), Color(0xFF10B981)],
                onTap: () => _acceptRequest(contact),
                tooltip: l10n.userProfileAccept,
              ),
              const SizedBox(width: 8),
              _miniGradientButton(
                icon: Icons.close_rounded,
                gradient: [colors.error, colors.error],
                onTap: () => _declineRequest(contact),
                tooltip: l10n.userProfileDecline,
              ),
            ],
          ),
          _ContactStatus.accepted => Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(Icons.chat_bubble_outline_rounded, size: 20, color: colors.primary),
                onPressed: () => context.push('/dashboard/messenger/${contact.conversationId}'),
                tooltip: l10n.contactsMessage,
              ),
              IconButton(
                icon: Icon(Icons.call_rounded, size: 20, color: colors.primary),
                onPressed: () => _startCall(contact),
                tooltip: l10n.contactsCall,
              ),
            ],
          ),
          _ContactStatus.pending => _buildResendButton(contact, colors),
        },
        onTap: () async {
          await context.push('/dashboard/user/${contact.userId}');
          _load();
        },
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _miniGradientButton({
    required IconData icon,
    required List<Color> gradient,
    required VoidCallback onTap,
    String? tooltip,
  }) {
    return Tooltip(
      message: tooltip ?? '',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: gradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: gradient.first.withValues(alpha: 0.45),
                blurRadius: 6,
              ),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    );
  }

  Widget _buildResendButton(_ContactItem contact, AppColorsExtension colors) {
    final l10n = AppLocalizations.of(context)!;
    final canResend = contact.requestSentAt != null &&
        DateTime.now().difference(contact.requestSentAt!).inHours >= 24;
    return IconButton(
      icon: Icon(
        Icons.refresh_rounded,
        size: 20,
        color: canResend ? colors.primary : colors.textSecondary.withValues(alpha: 0.4),
      ),
      tooltip: canResend ? l10n.contactsResend : l10n.contactsResendTimeout,
      onPressed: canResend ? () => _resendRequest(contact) : null,
    );
  }

  Future<void> _resendRequest(_ContactItem contact) async {
    try {
      await sl<DioClient>().post(
        '/messenger/contacts/request',
        data: {'receiverId': contact.userId},
        fromJson: (d) => d,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.contactsResent), backgroundColor: AppColors.of(context).primary),
        );
        _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.errorWithMessage(e.toString())), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _startCall(_ContactItem contact) async {
    if (contact.conversationId == null) return;
    try {
      final room = await sl<DioClient>().post<Map<String, dynamic>>(
        '/voice/rooms',
        data: {'conversationId': contact.conversationId, 'withAi': false},
        fromJson: (d) => Map<String, dynamic>.from(d as Map),
      );
      final roomName = room?['roomName'] as String? ?? '';
      if (mounted) {
        sl<MessengerRemoteDataSource>().sendCallInvite(contact.conversationId!, roomName);
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
          SnackBar(content: Text(AppLocalizations.of(context)!.errorWithMessage(e.toString())), backgroundColor: Colors.red),
        );
      }
    }
  }
}

enum _ContactStatus { incoming, accepted, pending }

class _ContactItem {
  final String? conversationId;
  final String userId;
  final String name;
  final String? username;
  final String? avatarUrl;
  final _ContactStatus status;
  final String? requestId;
  final DateTime? requestSentAt;

  _ContactItem({
    this.conversationId,
    required this.userId,
    required this.name,
    this.username,
    this.avatarUrl,
    required this.status,
    this.requestId,
    this.requestSentAt,
  });

  Map<String, dynamic> toJson() => {
        'conversationId': conversationId,
        'userId': userId,
        'name': name,
        'username': username,
        'avatarUrl': avatarUrl,
        'status': status.name,
        'requestId': requestId,
        'requestSentAt': requestSentAt?.toIso8601String(),
      };

  factory _ContactItem.fromJson(Map<String, dynamic> j) => _ContactItem(
        conversationId: j['conversationId'] as String?,
        userId: j['userId'] as String? ?? '',
        name: j['name'] as String? ?? '',
        username: j['username'] as String?,
        avatarUrl: j['avatarUrl'] as String?,
        status: switch (j['status'] as String?) {
          'incoming' => _ContactStatus.incoming,
          'pending' => _ContactStatus.pending,
          _ => _ContactStatus.accepted,
        },
        requestId: j['requestId'] as String?,
        requestSentAt: DateTime.tryParse(j['requestSentAt'] as String? ?? ''),
      );
}

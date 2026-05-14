import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/api/dio_client.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/widgets.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../messenger/data/datasources/messenger_remote_datasource.dart';
import '../../../voice/presentation/widgets/pulsing_avatar.dart' show rainbowColorFor;
import '../../domain/entities/contact_item_entity.dart';
import '../../domain/repositories/i_contacts_repository.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  final _searchCtrl = TextEditingController();
  final IContactsRepository _repo = sl<IContactsRepository>();
  StreamSubscription<List<ContactItemEntity>>? _itemsSub;
  String _searchQuery = '';
  List<ContactItemEntity> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _itemsSub = _repo.watchAll().listen((items) {
      if (mounted) {
        setState(() {
          _items = items;
          _loading = false;
        });
      }
    });
    _repo.refresh(); // fire-and-forget
  }

  @override
  void dispose() {
    _itemsSub?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    await _repo.refresh();
  }

  Future<void> _acceptRequest(ContactItemEntity contact) async {
    if (contact.requestId == null) return;
    await _repo.acceptContactRequest(contact.requestId!, contact.userId);
    HapticFeedback.mediumImpact();
  }

  Future<void> _declineRequest(ContactItemEntity contact) async {
    if (contact.requestId == null) return;
    await _repo.rejectContactRequest(contact.requestId!, contact.userId);
    HapticFeedback.lightImpact();
  }

  Future<void> _resendRequest(ContactItemEntity contact) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      await _repo.sendContactRequest(contact.userId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.contactsResent), backgroundColor: AppColors.of(context).primary),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.errorWithMessage(e.toString())), backgroundColor: Colors.red),
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

  Widget _syncDot(ContactItemEntity c) {
    if (!c.localPending) return const SizedBox.shrink();
    return const Padding(
      padding: EdgeInsets.only(left: 6),
      child: Icon(Icons.sync, size: 12, color: Colors.grey),
    );
  }

  Widget _buildTile(ContactItemEntity contact, AppColorsExtension colors) {
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
        title: Row(
          children: [
            Flexible(
              child: Text(
                contact.name,
                style: TextStyle(color: colors.textPrimary, fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ),
            _syncDot(contact),
          ],
        ),
        subtitle: contact.status == ContactStatus.incoming
            ? Text(l10n.contactsWantsToConnect, style: TextStyle(color: colors.accent, fontSize: 12, fontWeight: FontWeight.w600))
            : contact.status == ContactStatus.pending
                ? Text(l10n.contactsPendingConfirmation, style: TextStyle(color: colors.textSecondary, fontSize: 12))
                : contact.username != null
                    ? Text('@${contact.username}', style: TextStyle(color: colors.textSecondary, fontSize: 13))
                    : null,
        trailing: switch (contact.status) {
          ContactStatus.incoming => Row(
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
          ContactStatus.accepted => Row(
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
          ContactStatus.pending => _buildResendButton(contact, colors),
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

  Widget _buildResendButton(ContactItemEntity contact, AppColorsExtension colors) {
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

  Future<void> _startCall(ContactItemEntity contact) async {
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

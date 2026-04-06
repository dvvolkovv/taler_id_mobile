import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../bloc/messenger_bloc.dart';
import '../bloc/messenger_event.dart';
import '../bloc/messenger_state.dart';

class ContactRequestsScreen extends StatefulWidget {
  final int initialTab;
  const ContactRequestsScreen({super.key, this.initialTab = 0});

  @override
  State<ContactRequestsScreen> createState() => _ContactRequestsScreenState();
}

class _ContactRequestsScreenState extends State<ContactRequestsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final _searchCtrl = TextEditingController();
  bool _searching = false;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this, initialIndex: widget.initialTab);
    final bloc = context.read<MessengerBloc>();
    bloc.add(LoadContactRequests());
    bloc.add(LoadSentContactRequests());
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _doSearch() {
    final q = _searchCtrl.text.trim();
    if (q.isEmpty) return;
    final query = q.startsWith('@') ? q.substring(1) : q;
    setState(() => _searching = true);
    context.read<MessengerBloc>().add(SearchUsers(query));
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) setState(() => _searching = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: Text(l10n.contactRequestsTitle),
        bottom: TabBar(
          controller: _tabCtrl,
          labelColor: colors.primary,
          unselectedLabelColor: colors.textSecondary,
          indicatorColor: colors.primary,
          tabs: [
            Tab(text: l10n.contactRequestsSearch),
            Tab(text: l10n.contactRequestsIncoming),
            Tab(text: l10n.contactRequestsSent),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _buildSearchTab(colors),
          _buildIncomingTab(colors),
          _buildSentTab(colors),
        ],
      ),
    );
  }

  // ─── Search tab ───

  Widget _buildSearchTab(AppColorsExtension colors) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchCtrl,
            autofocus: false,
            style: TextStyle(color: colors.textPrimary),
            decoration: InputDecoration(
              hintText: l10n.contactRequestsSearchHint,
              hintStyle: TextStyle(color: colors.textSecondary),
              prefixIcon: Icon(Icons.search, color: colors.textSecondary),
              suffixIcon: IconButton(
                icon: _searching
                    ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: colors.primary))
                    : Icon(Icons.arrow_forward_rounded, color: colors.primary),
                onPressed: _searching ? null : _doSearch,
              ),
              filled: true,
              fillColor: colors.card,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: colors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: colors.border),
              ),
            ),
            onSubmitted: (_) => _doSearch(),
          ),
        ),
        Expanded(
          child: BlocConsumer<MessengerBloc, MessengerState>(
            listenWhen: (prev, curr) =>
                curr.contactRequestSent != prev.contactRequestSent ||
                (curr.error != null && curr.error != prev.error),
            buildWhen: (prev, curr) =>
                prev.searchResults != curr.searchResults ||
                prev.isLoading != curr.isLoading ||
                prev.sentContactRequests != curr.sentContactRequests,
            listener: (context, state) {
              if (state.contactRequestSent != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(l10n.contactRequestSent),
                    backgroundColor: colors.primary,
                  ),
                );
                context.read<MessengerBloc>().add(LoadSentContactRequests());
              }
              if (state.error != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.error!),
                    backgroundColor: colors.error,
                  ),
                );
              }
            },
            builder: (context, state) {
              if (state.isLoading && state.searchResults.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }
              if (state.searchResults.isEmpty) {
                return Center(
                  child: Text(
                    _searchCtrl.text.length >= 2
                        ? l10n.contactRequestsNoUsers
                        : l10n.contactRequestsSearchHelp,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: colors.textSecondary),
                  ),
                );
              }
              return ListView.builder(
                itemCount: state.searchResults.length,
                itemBuilder: (context, i) {
                  final user = state.searchResults[i];
                  final name = [user.firstName, user.lastName]
                      .whereType<String>()
                      .where((s) => s.isNotEmpty)
                      .join(' ');
                  final displayName = name.isNotEmpty
                      ? name
                      : (user.username != null ? '@${user.username}' : user.email);

                  // Check if request already sent to this user
                  final sentReq = state.sentContactRequests.where(
                    (r) => r['receiverId'] == user.id && (r['status'] as String? ?? 'PENDING') == 'PENDING',
                  ).firstOrNull;
                  final alreadySent = sentReq != null;
                  DateTime? sentAt;
                  if (alreadySent) {
                    sentAt = DateTime.tryParse(sentReq['createdAt'] as String? ?? '') ??
                        DateTime.tryParse(sentReq['updatedAt'] as String? ?? '');
                  }
                  final cooldownDone = sentAt == null ||
                      DateTime.now().difference(sentAt).inHours >= 3;
                  final nextAllowed = sentAt != null
                      ? sentAt.add(const Duration(hours: 3))
                      : null;

                  return ListTile(
                    leading: _avatar(colors, user.avatarUrl, displayName),
                    title: Text(
                      displayName,
                      style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600),
                    ),
                    subtitle: alreadySent
                        ? Text(
                            cooldownDone
                                ? l10n.contactRequestsSent
                                : _cooldownText(nextAllowed),
                            style: TextStyle(
                              color: cooldownDone ? colors.primary : colors.textSecondary,
                              fontSize: 12,
                            ),
                          )
                        : Text(
                            user.username != null ? '@${user.username}\n${user.email}' : user.email,
                            style: TextStyle(color: colors.textSecondary, fontSize: 12),
                          ),
                    isThreeLine: !alreadySent && user.username != null,
                    trailing: alreadySent && !cooldownDone
                        ? Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Icon(Icons.hourglass_top_rounded, color: colors.textSecondary, size: 20),
                          )
                        : IconButton(
                            icon: Icon(Icons.person_add_rounded, color: colors.primary),
                            tooltip: l10n.contactRequestsSendTooltip,
                            onPressed: () => _sendRequest(context, user.id, displayName),
                          ),
                    onTap: () => context.push('/dashboard/user/${user.id}'),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  String _cooldownText(DateTime? nextAllowed) {
    if (nextAllowed == null) return '';
    final diff = nextAllowed.difference(DateTime.now());
    if (diff.inMinutes <= 0) return '';
    final h = diff.inHours;
    final m = diff.inMinutes % 60;
    if (h > 0) return 'Следующий запрос через ${h}ч ${m}мин';
    return 'Следующий запрос через ${m}мин';
  }

  void _sendRequest(BuildContext context, String userId, String name) {
    final colors = AppColors.of(context);
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            // Icon
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.person_add_rounded, color: colors.primary, size: 32),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.contactRequestTitle,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.contactRequestConfirm(name),
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: colors.border),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => Navigator.pop(ctx),
                    child: Text(l10n.cancel, style: TextStyle(color: colors.textSecondary)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.primary,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      context.read<MessengerBloc>().add(SendContactRequest(userId));
                    },
                    child: Text(l10n.contactRequestSend, style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─── Incoming tab ───

  Widget _buildIncomingTab(AppColorsExtension colors) {
    return BlocBuilder<MessengerBloc, MessengerState>(
      buildWhen: (prev, curr) => prev.contactRequests != curr.contactRequests,
      builder: (context, state) {
        if (state.contactRequests.isEmpty) {
          return Center(
            child: Text(AppLocalizations.of(context)!.contactRequestsNoIncoming, style: TextStyle(color: colors.textSecondary)),
          );
        }
        return ListView.builder(
          itemCount: state.contactRequests.length,
          itemBuilder: (context, i) {
            final req = state.contactRequests[i];
            final name = req['senderName'] as String? ?? '';
            final username = req['senderUsername'] as String?;
            final avatar = req['senderAvatar'] as String?;
            final id = req['id'] as String;
            final senderId = req['senderId'] as String?;
            return ListTile(
              leading: _avatar(colors, avatar, name.isNotEmpty ? name : (username ?? '?')),
              title: Text(
                name.isNotEmpty ? name : (username != null ? '@$username' : ''),
                style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600),
              ),
              subtitle: username != null
                  ? Text('@$username', style: TextStyle(color: colors.textSecondary, fontSize: 12))
                  : null,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _actionButton(
                    icon: Icons.close_rounded,
                    color: colors.error,
                    onTap: () => context.read<MessengerBloc>().add(RejectContactRequest(id)),
                  ),
                  const SizedBox(width: 8),
                  _actionButton(
                    icon: Icons.check_rounded,
                    color: Colors.green,
                    onTap: () => context.read<MessengerBloc>().add(AcceptContactRequest(id)),
                  ),
                ],
              ),
              onTap: senderId != null ? () => context.push('/dashboard/user/$senderId') : null,
            );
          },
        );
      },
    );
  }

  Widget _actionButton({required IconData icon, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }

  // ─── Sent tab ───

  Widget _buildSentTab(AppColorsExtension colors) {
    return BlocBuilder<MessengerBloc, MessengerState>(
      buildWhen: (prev, curr) => prev.sentContactRequests != curr.sentContactRequests,
      builder: (context, state) {
        if (state.sentContactRequests.isEmpty) {
          return Center(
            child: Text(AppLocalizations.of(context)!.contactRequestsNoSent, style: TextStyle(color: colors.textSecondary)),
          );
        }
        return ListView.builder(
          itemCount: state.sentContactRequests.length,
          itemBuilder: (context, i) {
            final req = state.sentContactRequests[i];
            final name = req['receiverName'] as String? ?? '';
            final username = req['receiverUsername'] as String?;
            final avatar = req['receiverAvatar'] as String?;
            final status = req['status'] as String? ?? 'PENDING';
            final receiverId = req['receiverId'] as String?;
            return ListTile(
              leading: _avatar(colors, avatar, name.isNotEmpty ? name : (username ?? '?')),
              title: Text(
                name.isNotEmpty ? name : (username != null ? '@$username' : ''),
                style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                _statusText(status),
                style: TextStyle(
                  color: _statusColor(colors, status),
                  fontSize: 12,
                ),
              ),
              trailing: _statusBadge(colors, status),
              onTap: receiverId != null ? () => context.push('/dashboard/user/$receiverId') : null,
            );
          },
        );
      },
    );
  }

  Widget _statusBadge(AppColorsExtension colors, String status) {
    Color bg;
    Color fg;
    switch (status) {
      case 'ACCEPTED':
        bg = Colors.green.withValues(alpha: 0.15);
        fg = Colors.green;
        break;
      case 'REJECTED':
        bg = colors.error.withValues(alpha: 0.15);
        fg = colors.error;
        break;
      default:
        bg = colors.textSecondary.withValues(alpha: 0.12);
        fg = colors.textSecondary;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _statusText(status),
        style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }

  String _statusText(String status) {
    final l10n = AppLocalizations.of(context)!;
    switch (status) {
      case 'PENDING':
        return l10n.contactRequestStatusPending;
      case 'ACCEPTED':
        return l10n.contactRequestStatusAccepted;
      case 'REJECTED':
        return l10n.contactRequestStatusRejected;
      default:
        return status;
    }
  }

  Color _statusColor(AppColorsExtension colors, String status) {
    switch (status) {
      case 'PENDING':
        return colors.textSecondary;
      case 'ACCEPTED':
        return Colors.green;
      case 'REJECTED':
        return colors.error;
      default:
        return colors.textSecondary;
    }
  }

  Widget _avatar(AppColorsExtension colors, String? url, String name) {
    return CircleAvatar(
      radius: 22,
      backgroundColor: colors.primary,
      backgroundImage: url != null && url.isNotEmpty ? CachedNetworkImageProvider(url) : null,
      child: (url == null || url.isEmpty)
          ? Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
            )
          : null,
    );
  }
}

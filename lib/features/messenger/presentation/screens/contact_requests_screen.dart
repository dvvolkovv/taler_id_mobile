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
    // Reset flag after short delay
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
                prev.isLoading != curr.isLoading,
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
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: colors.primary,
                      backgroundImage: user.avatarUrl != null
                          ? NetworkImage(user.avatarUrl!)
                          : null,
                      child: user.avatarUrl == null
                          ? Text(
                              displayName[0].toUpperCase(),
                              style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                            )
                          : null,
                    ),
                    title: Text(
                      displayName,
                      style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      user.username != null ? '@${user.username}\n${user.email}' : user.email,
                      style: TextStyle(color: colors.textSecondary, fontSize: 12),
                    ),
                    isThreeLine: user.username != null,
                    trailing: IconButton(
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

  void _sendRequest(BuildContext context, String userId, String name) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.of(context).card,
        title: Text(l10n.contactRequestTitle, style: TextStyle(color: AppColors.of(context).textPrimary)),
        content: Text(
          l10n.contactRequestConfirm(name),
          style: TextStyle(color: AppColors.of(context).textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel, style: TextStyle(color: AppColors.of(context).textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.of(context).primary,
              foregroundColor: Colors.black,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              context.read<MessengerBloc>().add(SendContactRequest(userId));
            },
            child: Text(l10n.contactRequestSend),
          ),
        ],
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
              leading: _avatar(colors, avatar, name),
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
                  IconButton(
                    icon: Icon(Icons.close_rounded, color: colors.error),
                    onPressed: () => context.read<MessengerBloc>().add(RejectContactRequest(id)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.check_rounded, color: Colors.green),
                    onPressed: () => context.read<MessengerBloc>().add(AcceptContactRequest(id)),
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
              leading: _avatar(colors, avatar, name),
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
              onTap: receiverId != null ? () => context.push('/dashboard/user/$receiverId') : null,
            );
          },
        );
      },
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

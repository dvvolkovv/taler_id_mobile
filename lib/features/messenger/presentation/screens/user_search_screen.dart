import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../bloc/messenger_bloc.dart';
import '../bloc/messenger_event.dart';
import '../bloc/messenger_state.dart';
import '../../domain/entities/user_search_entity.dart';

class UserSearchScreen extends StatefulWidget {
  const UserSearchScreen({super.key});

  @override
  State<UserSearchScreen> createState() => _UserSearchScreenState();
}

class _UserSearchScreenState extends State<UserSearchScreen> {
  final _ctrl = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _ctrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      // Strip leading @ for nickname searches
      final query = value.startsWith('@') ? value.substring(1) : value;
      context.read<MessengerBloc>().add(SearchUsers(query));
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.of(context).background,
      appBar: AppBar(
        title: Text(l10n.userSearchTitle),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _ctrl,
                  autofocus: true,
                  style: TextStyle(color: AppColors.of(context).textPrimary),
                  decoration: InputDecoration(
                    hintText: l10n.userSearchHint,
                    hintStyle: TextStyle(
                        color: AppColors.of(context).textSecondary),
                    prefixIcon: Icon(Icons.search,
                        color: AppColors.of(context).textSecondary),
                    filled: true,
                    fillColor: AppColors.of(context).card,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          BorderSide(color: AppColors.of(context).border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          BorderSide(color: AppColors.of(context).border),
                    ),
                  ),
                  onChanged: _onChanged,
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.userSearchHelper,
                  style: TextStyle(
                      color: AppColors.of(context).textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
          Expanded(
            child: BlocConsumer<MessengerBloc, MessengerState>(
              listenWhen: (prev, curr) =>
                  curr.newConversationId != prev.newConversationId ||
                  (curr.error != null && curr.error != prev.error),
              listener: (context, state) {
                if (state.newConversationId != null) {
                  context
                      .read<MessengerBloc>()
                      .add(ClearNewConversation());
                  context.pushReplacement(
                      '/dashboard/messenger/${state.newConversationId}');
                }
                if (state.error != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(l10n.errorWithMessage(state.error ?? '')),
                      backgroundColor: AppColors.of(context).error,
                    ),
                  );
                }
              },
              builder: (context, state) {
                if (state.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state.searchResults.isEmpty &&
                    _ctrl.text.length >= 2) {
                  return Center(
                    child: Text(
                      l10n.userSearchNoUsers,
                      style: TextStyle(color: AppColors.of(context).textSecondary),
                    ),
                  );
                }
                return ListView.builder(
                  itemCount: state.searchResults.length,
                  itemBuilder: (context, index) {
                    final user = state.searchResults[index];
                    return _UserTile(user: user);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _UserTile extends StatelessWidget {
  final UserSearchEntity user;
  const _UserTile({required this.user});

  String get displayName {
    final parts = [user.firstName, user.lastName]
        .whereType<String>()
        .where((s) => s.isNotEmpty)
        .toList();
    if (parts.isNotEmpty) return parts.join(' ');
    if (user.username != null) return '@${user.username}';
    return user.email;
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: AppColors.of(context).primary,
        backgroundImage: user.avatarUrl != null
            ? NetworkImage(user.avatarUrl!)
            : null,
        child: user.avatarUrl == null
            ? Text(
                displayName[0].toUpperCase(),
                style: const TextStyle(
                    color: Colors.black, fontWeight: FontWeight.bold),
              )
            : null,
      ),
      title: Text(
        displayName,
        style: TextStyle(
            color: AppColors.of(context).textPrimary,
            fontWeight: FontWeight.w600),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (user.username != null)
            Text(
              '@${user.username}',
              style: TextStyle(
                  color: AppColors.of(context).textSecondary, fontSize: 12),
            ),
          Text(
            user.email,
            style: TextStyle(
                color: AppColors.of(context).textSecondary, fontSize: 12),
          ),
        ],
      ),
      trailing: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.of(context).primary.withOpacity(0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          'KYC \u2713',
          style: TextStyle(
              color: AppColors.of(context).primary,
              fontSize: 11,
              fontWeight: FontWeight.bold),
        ),
      ),
      onTap: () => _onUserTap(context),
    );
  }

  void _onUserTap(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.of(context).card,
        title: Text(l10n.contactRequestTitle, style: TextStyle(color: AppColors.of(context).textPrimary)),
        content: Text(
          l10n.contactRequestConfirm(displayName),
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
              context.read<MessengerBloc>().add(SendContactRequest(user.id));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(l10n.contactRequestSent),
                  backgroundColor: AppColors.of(context).primary,
                ),
              );
            },
            child: Text(l10n.contactRequestSend),
          ),
        ],
      ),
    );
  }
}

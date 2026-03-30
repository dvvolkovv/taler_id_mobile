import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../bloc/messenger_bloc.dart';
import '../bloc/messenger_event.dart';
import '../bloc/messenger_state.dart';
import '../../domain/entities/user_search_entity.dart';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final _searchCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _selectedUsers = <UserSearchEntity>[];
  bool _showNameStep = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  void _toggleUser(UserSearchEntity user) {
    setState(() {
      final exists = _selectedUsers.any((u) => u.id == user.id);
      if (exists) {
        _selectedUsers.removeWhere((u) => u.id == user.id);
      } else {
        _selectedUsers.add(user);
      }
    });
  }

  void _goToNameStep() {
    if (_selectedUsers.isEmpty) return;
    setState(() => _showNameStep = true);
  }

  void _createGroup() {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty || _selectedUsers.isEmpty) return;
    context.read<MessengerBloc>().add(CreateGroup(
      name: name,
      participantIds: _selectedUsers.map((u) => u.id).toList(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.of(context).background,
      appBar: AppBar(
        title: Text(_showNameStep ? l10n.groupName : l10n.selectParticipants),
      ),
      body: BlocListener<MessengerBloc, MessengerState>(
        listenWhen: (prev, curr) =>
            prev.newConversationId != curr.newConversationId &&
            curr.newConversationId != null,
        listener: (context, state) {
          final convId = state.newConversationId;
          if (convId != null) {
            context.read<MessengerBloc>().add(ClearNewConversation());
            context.go('/dashboard/messenger/$convId');
          }
        },
        child: _showNameStep ? _buildNameStep(l10n) : _buildSearchStep(l10n),
      ),
    );
  }

  Widget _buildSearchStep(AppLocalizations l10n) {
    return Column(
      children: [
        // Selected chips
        if (_selectedUsers.isNotEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Wrap(
              spacing: 8,
              runSpacing: 4,
              children: _selectedUsers.map((u) {
                final name = [u.firstName, u.lastName].where((s) => s != null && s.isNotEmpty).join(' ');
                return Chip(
                  label: Text(name.isNotEmpty ? name : u.username ?? u.id,
                      style: TextStyle(color: AppColors.of(context).textPrimary, fontSize: 13)),
                  deleteIcon: Icon(Icons.close, size: 16, color: AppColors.of(context).textSecondary),
                  onDeleted: () => _toggleUser(u),
                  backgroundColor: AppColors.of(context).card,
                  side: BorderSide(color: AppColors.of(context).border),
                );
              }).toList(),
            ),
          ),
        // Search field
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchCtrl,
            style: TextStyle(color: AppColors.of(context).textPrimary),
            decoration: InputDecoration(
              hintText: l10n.search,
              hintStyle: TextStyle(color: AppColors.of(context).textSecondary),
              prefixIcon: Icon(Icons.search, color: AppColors.of(context).textSecondary),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.of(context).primary),
              ),
            ),
            onChanged: (q) {
              if (q.length >= 2) {
                context.read<MessengerBloc>().add(SearchUsers(q));
              }
            },
          ),
        ),
        // Search results
        Expanded(
          child: BlocBuilder<MessengerBloc, MessengerState>(
            builder: (context, state) {
              final results = state.searchResults;
              if (results.isEmpty && _searchCtrl.text.length >= 2) {
                return Center(
                  child: Text(l10n.groupNoResults,
                      style: TextStyle(color: AppColors.of(context).textSecondary)),
                );
              }
              return ListView.builder(
                itemCount: results.length,
                itemBuilder: (context, index) {
                  final user = results[index];
                  final isSelected = _selectedUsers.any((u) => u.id == user.id);
                  final name = [user.firstName, user.lastName]
                      .where((s) => s != null && s.isNotEmpty)
                      .join(' ');
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.of(context).primary,
                      child: user.avatarUrl != null
                          ? ClipOval(
                              child: CachedNetworkImage(
                                imageUrl: user.avatarUrl!,
                                width: 40, height: 40, fit: BoxFit.cover,
                                errorWidget: (_, __, ___) => Text(
                                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                                  style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                                ),
                              ),
                            )
                          : Text(
                              name.isNotEmpty ? name[0].toUpperCase() : '?',
                              style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                            ),
                    ),
                    title: Text(name.isNotEmpty ? name : (user.username ?? ''),
                        style: TextStyle(color: AppColors.of(context).textPrimary)),
                    subtitle: user.username != null
                        ? Text('@${user.username}',
                            style: TextStyle(color: AppColors.of(context).textSecondary, fontSize: 13))
                        : null,
                    trailing: Checkbox(
                      value: isSelected,
                      onChanged: (_) => _toggleUser(user),
                      activeColor: AppColors.of(context).primary,
                      checkColor: Colors.black,
                    ),
                    onTap: () => _toggleUser(user),
                  );
                },
              );
            },
          ),
        ),
        // Next button
        if (_selectedUsers.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _goToNameStep,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.of(context).primary,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text('${l10n.onboardingNext} (${l10n.selectedCount(_selectedUsers.length)})',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildNameStep(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Group icon + name field
          Row(
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: AppColors.of(context).primary.withValues(alpha: 0.3),
                child: Icon(Icons.group_rounded, size: 32, color: AppColors.of(context).primary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  controller: _nameCtrl,
                  autofocus: true,
                  style: TextStyle(color: AppColors.of(context).textPrimary, fontSize: 18),
                  decoration: InputDecoration(
                    hintText: l10n.enterGroupName,
                    hintStyle: TextStyle(color: AppColors.of(context).textSecondary),
                    border: InputBorder.none,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            l10n.selectedCount(_selectedUsers.length),
            style: TextStyle(color: AppColors.of(context).textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: _selectedUsers.map((u) {
              final name = [u.firstName, u.lastName].where((s) => s != null && s.isNotEmpty).join(' ');
              return Chip(
                label: Text(name.isNotEmpty ? name : (u.username ?? u.id),
                    style: TextStyle(color: AppColors.of(context).textPrimary, fontSize: 13)),
                backgroundColor: AppColors.of(context).card,
                side: BorderSide(color: AppColors.of(context).border),
              );
            }).toList(),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _nameCtrl.text.trim().isNotEmpty ? _createGroup : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.of(context).primary,
                foregroundColor: Colors.black,
                disabledBackgroundColor: AppColors.of(context).card,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: BlocBuilder<MessengerBloc, MessengerState>(
                builder: (context, state) {
                  if (state.isLoading) {
                    return const SizedBox(
                      width: 24, height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                    );
                  }
                  return Text(l10n.createGroup,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold));
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

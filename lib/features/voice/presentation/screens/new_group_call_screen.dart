import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/services/contacts_cache_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../bloc/group_call_bloc.dart';
import '../bloc/group_call_event.dart';
import '../bloc/group_call_state.dart';
import '../widgets/pulsing_avatar.dart' show rainbowColorFor;

/// Multi-select contacts picker for starting a group voice call.
///
/// Loads contacts from [ContactsCacheService] (only `accepted` status) and
/// lets the user pick up to 7 invitees (host + 7 = 8 cap per Phase 1 spec).
/// On confirm, dispatches [CreateCall] to the [GroupCallBloc] and navigates
/// to the lobby/active screen on [InLobby].
class NewGroupCallScreen extends StatefulWidget {
  const NewGroupCallScreen({super.key});

  @override
  State<NewGroupCallScreen> createState() => _NewGroupCallScreenState();
}

class _NewGroupCallScreenState extends State<NewGroupCallScreen> {
  static const int _maxSelected = 7;

  final ContactsCacheService _cache = sl<ContactsCacheService>();
  final TextEditingController _searchCtrl = TextEditingController();
  late final GroupCallBloc _bloc;

  List<_PickerContact> _contacts = [];
  final Set<String> _selected = <String>{};
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _bloc = sl<GroupCallBloc>();
    _loadContacts();
  }

  void _loadContacts() {
    final cached = _cache.get() ?? const <Map<String, dynamic>>[];
    final list = <_PickerContact>[];
    for (final j in cached) {
      if ((j['status'] as String?) != 'accepted') continue;
      final id = j['userId'] as String? ?? '';
      final name = j['name'] as String? ?? '';
      if (id.isEmpty || name.isEmpty) continue;
      list.add(_PickerContact(
        id: id,
        displayName: name,
        avatarUrl: j['avatarUrl'] as String?,
      ));
    }
    list.sort((a, b) =>
        a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()));
    setState(() => _contacts = list);
  }

  void _toggle(String contactId) {
    if (_selected.contains(contactId)) {
      setState(() => _selected.remove(contactId));
      return;
    }
    if (_selected.length >= _maxSelected) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.groupCallMaxReached),
        ),
      );
      return;
    }
    setState(() => _selected.add(contactId));
  }

  void _create() {
    if (_selected.isEmpty) return;
    _bloc.add(GroupCallEvent.createCall(_selected.toList()));
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<GroupCallBloc>.value(
      value: _bloc,
      child: BlocConsumer<GroupCallBloc, GroupCallState>(
        listener: (context, state) {
          if (state is InLobby) {
            context.go('/group-call/${state.groupCall.id}/lobby');
          } else if (state is ErrorState) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        builder: (context, state) {
          final colors = AppColors.of(context);
          final l10n = AppLocalizations.of(context)!;
          final isCreating = state is Creating;
          return Scaffold(
            backgroundColor: colors.background,
            appBar: AppBar(
              backgroundColor: colors.background,
              title: Text(
                '${l10n.groupCallSelectParticipants} '
                '(${l10n.groupCallSelectedCount(_selected.length)})',
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.check_rounded),
                  tooltip: 'Готово',
                  onPressed: (_selected.isEmpty || isCreating) ? null : _create,
                ),
              ],
            ),
            body: Stack(
              children: [
                Column(
                  children: [
                    _searchField(colors),
                    if (_selected.isNotEmpty) _selectedRow(colors),
                    Expanded(child: _contactsList(colors)),
                  ],
                ),
                if (isCreating)
                  Positioned.fill(
                    child: ColoredBox(
                      color: Colors.black.withValues(alpha: 0.5),
                      child: Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: colors.primary,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _searchField(AppColorsExtension colors) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: TextField(
        controller: _searchCtrl,
        style: TextStyle(color: colors.textPrimary, fontSize: 14),
        decoration: InputDecoration(
          hintText: AppLocalizations.of(context)!.groupCallSearch,
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
    );
  }

  Widget _selectedRow(AppColorsExtension colors) {
    final picked = _contacts.where((c) => _selected.contains(c.id)).toList();
    return SizedBox(
      height: 56,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        itemCount: picked.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (_, i) {
          final c = picked[i];
          final ringColor = rainbowColorFor(c.displayName);
          return Chip(
            backgroundColor: colors.surface,
            side: BorderSide(color: ringColor.withValues(alpha: 0.5)),
            avatar: CircleAvatar(
              radius: 14,
              backgroundColor: ringColor,
              backgroundImage: c.avatarUrl != null && c.avatarUrl!.isNotEmpty
                  ? CachedNetworkImageProvider(c.avatarUrl!)
                  : null,
              child: c.avatarUrl == null || c.avatarUrl!.isEmpty
                  ? Text(
                      c.displayName.substring(0, 1).toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    )
                  : null,
            ),
            label: Text(
              c.displayName,
              style: TextStyle(color: colors.textPrimary, fontSize: 13),
            ),
            deleteIcon: Icon(Icons.close, size: 16, color: colors.textSecondary),
            onDeleted: () => _toggle(c.id),
          );
        },
      ),
    );
  }

  Widget _contactsList(AppColorsExtension colors) {
    final q = _searchQuery.toLowerCase();
    final filtered = q.isEmpty
        ? _contacts
        : _contacts
            .where((c) => c.displayName.toLowerCase().contains(q))
            .toList();

    if (filtered.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            _searchQuery.isNotEmpty ? 'Ничего не найдено' : 'Нет контактов',
            style: TextStyle(color: colors.textSecondary, fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: filtered.length,
      itemBuilder: (_, i) {
        final c = filtered[i];
        final picked = _selected.contains(c.id);
        final ringColor = rainbowColorFor(c.displayName);
        return CheckboxListTile(
          value: picked,
          controlAffinity: ListTileControlAffinity.trailing,
          activeColor: colors.primary,
          title: Text(
            c.displayName,
            style: TextStyle(color: colors.textPrimary, fontSize: 15),
          ),
          secondary: CircleAvatar(
            radius: 20,
            backgroundColor: ringColor,
            backgroundImage: c.avatarUrl != null && c.avatarUrl!.isNotEmpty
                ? CachedNetworkImageProvider(c.avatarUrl!)
                : null,
            child: c.avatarUrl == null || c.avatarUrl!.isEmpty
                ? Text(
                    c.displayName.substring(0, 1).toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  )
                : null,
          ),
          onChanged: (_) => _toggle(c.id),
        );
      },
    );
  }
}

class _PickerContact {
  final String id;
  final String displayName;
  final String? avatarUrl;

  const _PickerContact({
    required this.id,
    required this.displayName,
    this.avatarUrl,
  });
}

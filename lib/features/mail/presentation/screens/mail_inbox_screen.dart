import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:taler_id_mobile/l10n/app_localizations.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/utils/constants.dart';
import '../../domain/entities/mail_folder_entity.dart';
import '../bloc/mail_bloc.dart';
import '../bloc/mail_event.dart';
import '../bloc/mail_state.dart';
import '../widgets/mail_folder_utils.dart';
import '../widgets/mail_tile.dart';

class MailInboxScreen extends StatelessWidget {
  const MailInboxScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<MailBloc>()..add(const MailInboxRequested()),
      child: const _MailInboxView(),
    );
  }
}

class _MailInboxView extends StatelessWidget {
  const _MailInboxView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return BlocBuilder<MailBloc, MailState>(
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.mailTitle),
                if (state.account != null)
                  Text(state.account!.address,
                      style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.key_outlined),
                onPressed: () =>
                    context.push('${RouteConstants.mail}/app-passwords'),
              ),
            ],
          ),
          floatingActionButton: state.account == null
              ? null
              : FloatingActionButton(
                  onPressed: () =>
                      context.push('${RouteConstants.mail}/compose'),
                  child: const Icon(Icons.edit_outlined),
                ),
          body: Column(
            children: [
              if (state.folders.isNotEmpty) _folderBar(context, state, l10n),
              Expanded(child: _body(context, state, l10n)),
            ],
          ),
        );
      },
    );
  }

  Widget _folderBar(
      BuildContext context, MailState state, AppLocalizations l10n) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          for (final folder in state.folders)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onLongPress: folder.role == 'custom'
                    ? () => _confirmDeleteFolder(context, folder, l10n)
                    : null,
                child: ChoiceChip(
                  label: Text(_chipLabel(folder, l10n)),
                  selected: folder.path == state.currentFolder,
                  onSelected: (_) => context
                      .read<MailBloc>()
                      .add(MailFolderSelected(folder.path)),
                ),
              ),
            ),
          ActionChip(
            avatar: const Icon(Icons.add, size: 18),
            label: Text(l10n.mailNewFolder),
            onPressed: () => _promptNewFolder(context, l10n),
          ),
        ],
      ),
    );
  }

  String _chipLabel(MailFolderEntity folder, AppLocalizations l10n) {
    final name = mailFolderDisplayName(folder, l10n);
    return folder.unseen > 0 ? '$name (${folder.unseen})' : name;
  }

  Future<void> _promptNewFolder(
      BuildContext context, AppLocalizations l10n) async {
    final bloc = context.read<MailBloc>();
    final ctrl = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.mailNewFolder),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: InputDecoration(hintText: l10n.mailFolders),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(ctrl.text.trim()),
            child: Text(l10n.save),
          ),
        ],
      ),
    );
    if (name != null && name.isNotEmpty) {
      bloc.add(MailFolderCreated(name));
    }
  }

  Future<void> _confirmDeleteFolder(BuildContext context,
      MailFolderEntity folder, AppLocalizations l10n) async {
    final bloc = context.read<MailBloc>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.mailDeleteFolder),
        content: Text(folder.name),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      bloc.add(MailFolderDeleted(folder.path));
    }
  }

  Widget _body(BuildContext context, MailState state, AppLocalizations l10n) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.noAccount) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.mailNoAccountTitle),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => context.go(RouteConstants.mailAddressSetup),
              child: Text(l10n.mailChooseAddress),
            ),
          ],
        ),
      );
    }
    if (state.error != null && state.items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined, size: 40),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () =>
                  context.read<MailBloc>().add(const MailInboxRequested()),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    if (state.items.isEmpty) {
      return Center(child: Text(l10n.mailInboxEmpty));
    }
    return RefreshIndicator(
      onRefresh: () async =>
          context.read<MailBloc>().add(const MailInboxRequested()),
      child: NotificationListener<ScrollNotification>(
        onNotification: (n) {
          if (n.metrics.extentAfter < 200) {
            context.read<MailBloc>().add(const MailLoadMoreRequested());
          }
          return false;
        },
        child: ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: state.items.length + (state.isLoadingMore ? 1 : 0),
          itemBuilder: (context, i) {
            if (i >= state.items.length) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            final item = state.items[i];
            return Dismissible(
              key: ValueKey(item.uid),
              direction: DismissDirection.endToStart,
              background: Container(
                color: Theme.of(context).colorScheme.error,
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 16),
                child: const Icon(Icons.delete_outline),
              ),
              onDismissed: (_) =>
                  context.read<MailBloc>().add(MailDeleteRequested(item.uid)),
              child: MailTile(
                item: item,
                onTap: () {
                  final isDrafts = state.folders.any((f) =>
                      f.role == 'drafts' && f.path == state.currentFolder);
                  if (isDrafts) {
                    // Черновик: открываем Compose с prefill вместо просмотра
                    context.push('${RouteConstants.mail}/compose', extra: {
                      'draftUid': item.uid,
                      'draftFolder': state.currentFolder,
                    });
                    return;
                  }
                  context
                      .read<MailBloc>()
                      .add(MailMarkSeenRequested(uid: item.uid, seen: true));
                  context.push(
                      '${RouteConstants.mail}/${item.uid}?folder=${Uri.encodeQueryComponent(state.currentFolder)}');
                },
              ),
            );
          },
        ),
      ),
    );
  }
}

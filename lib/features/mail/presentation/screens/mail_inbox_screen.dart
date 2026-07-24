import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:taler_id_mobile/l10n/app_localizations.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/utils/constants.dart';
import '../bloc/mail_bloc.dart';
import '../bloc/mail_event.dart';
import '../bloc/mail_state.dart';
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
          body: _body(context, state, l10n),
        );
      },
    );
  }

  Widget _body(
      BuildContext context, MailState state, AppLocalizations l10n) {
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
        child: ListView.separated(
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: state.items.length + (state.isLoadingMore ? 1 : 0),
          separatorBuilder: (_, __) => const Divider(height: 1),
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
                  context.read<MailBloc>().add(
                      MailMarkSeenRequested(uid: item.uid, seen: true));
                  context.push('${RouteConstants.mail}/${item.uid}');
                },
              ),
            );
          },
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/mesh/voice/group_mesh_call_state.dart';
import '../../../../l10n/app_localizations.dart';
import '../bloc/group_mesh_call_bloc.dart';
import '../bloc/group_mesh_call_event.dart';

/// Host's "waiting for invitees to accept" screen (mesh group call lobby).
///
/// Listens for [GMCActive] (first invitee joined → switch to active screen),
/// [GMCEnded] (navigate to call history), [GMCError] (show snackbar).
/// Cancel button dispatches [GMCLeavePressed].
class GroupCallLobbyScreen extends StatelessWidget {
  final String callId;
  const GroupCallLobbyScreen({super.key, required this.callId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<GroupMeshCallBloc>.value(
      value: sl<GroupMeshCallBloc>(),
      child: BlocConsumer<GroupMeshCallBloc, GroupMeshCallState>(
        listener: (context, state) {
          if (state is GMCActive) {
            context.go('/group-call/${state.roomId}');
          } else if (state is GMCEnded) {
            context.go('/dashboard/call-history');
          } else if (state is GMCError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        builder: (context, state) {
          if (state is! GMCLobby) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          return _LobbyView(state: state);
        },
      ),
    );
  }
}

class _LobbyView extends StatelessWidget {
  const _LobbyView({required this.state});
  final GMCLobby state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.groupCallLobbyTitle),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: ListView.separated(
                  itemCount: state.roster.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final p = state.roster[i];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: (p.avatarUrl != null &&
                                p.avatarUrl!.isNotEmpty)
                            ? NetworkImage(p.avatarUrl!)
                            : null,
                        child: (p.avatarUrl == null || p.avatarUrl!.isEmpty)
                            ? Text(
                                (p.displayName ?? p.userId)
                                    .substring(0, 1)
                                    .toUpperCase(),
                              )
                            : null,
                      ),
                      title: Text(p.displayName ?? p.userId),
                      subtitle: Text(_subtitleForStatus(p, l10n)),
                      trailing:
                          p.isSelf ? const Icon(Icons.star_border) : null,
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () => context
                    .read<GroupMeshCallBloc>()
                    .add(const GMCLeavePressed()),
                icon: const Icon(Icons.close),
                label: Text(l10n.meshGcCancel),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _subtitleForStatus(GMCParticipant p, AppLocalizations l10n) {
    switch (p.status) {
      case GMCStatus.calling:
        return l10n.meshGcStatusCalling;
      case GMCStatus.joined:
        return l10n.meshGcStatusJoined;
      case GMCStatus.declined:
        return l10n.meshGcStatusDeclined;
      case GMCStatus.noAnswer:
        return l10n.meshGcStatusNoAnswer;
      case GMCStatus.connectionFailed:
        return l10n.meshGcStatusConnectionFailed;
      case GMCStatus.left:
        return l10n.meshGcStatusLeft;
    }
  }
}

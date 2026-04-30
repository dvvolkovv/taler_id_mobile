import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/utils/constants.dart';
import '../../../../l10n/app_localizations.dart';
import '../bloc/group_call_bloc.dart';
// Alias the event import: `GroupCallEvent.ended` and `GroupCallState.ended`
// both freezed-generate a top-level class named `Ended`, so we hide the event
// one here and reach for it via the alias when needed.
import '../bloc/group_call_event.dart' as gce;
import '../bloc/group_call_state.dart';
import '../widgets/participant_tile.dart';

/// Host's "waiting for invitees to accept" screen.
///
/// Listens for [InActive] (first invitee joined → switch to active screen) and
/// [Ended] (toast + back to /calls). Cancel button dispatches
/// [GroupCallEvent.endCall].
class GroupCallLobbyScreen extends StatelessWidget {
  final String callId;
  const GroupCallLobbyScreen({super.key, required this.callId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<GroupCallBloc>.value(
      value: sl<GroupCallBloc>(),
      child: BlocConsumer<GroupCallBloc, GroupCallState>(
        listener: (context, state) {
          if (state is InActive && state.groupCall.id == callId) {
            // First invitee joined → switch to active screen
            context.go('/group-call/$callId');
          } else if (state is Ended) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(_endedLabel(context, state.reason))),
            );
            // Navigate back. Use a microtask so the SnackBar gets a frame.
            Future.microtask(() {
              if (context.mounted) context.go(RouteConstants.callHistory);
            });
          } else if (state is Idle) {
            context.go(RouteConstants.callHistory);
          }
        },
        builder: (context, state) {
          if (state is InLobby && state.groupCall.id == callId) {
            return _LobbyView(state: state);
          }
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        },
      ),
    );
  }

  String _endedLabel(BuildContext context, String reason) {
    final l10n = AppLocalizations.of(context)!;
    switch (reason) {
      case 'timeout':
        return l10n.groupCallNoAnswer;
      case 'host_ended':
        return l10n.groupCallEndedByHost;
      case 'all_left':
        return l10n.groupCallAllLeft;
      default:
        return l10n.groupCallEnded;
    }
  }
}

class _LobbyView extends StatelessWidget {
  final InLobby state;
  const _LobbyView({required this.state});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.groupCallLobbyTitle),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            context
                .read<GroupCallBloc>()
                .add(gce.GroupCallEvent.endCall(state.groupCall.id));
          },
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                l10n.groupCallHostLabel(state.groupCall.hostDisplayName),
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              const _MicStatusRow(),
              const SizedBox(height: 16),
              Expanded(
                child: GridView.builder(
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: state.groupCall.invites.length,
                  itemBuilder: (_, i) {
                    final inv = state.groupCall.invites[i];
                    return ParticipantTile(
                      displayName: inv.displayName,
                      avatarUrl: inv.avatarUrl,
                      status: inv.status,
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.call_end),
                  label: Text(l10n.groupCallCancel),
                  onPressed: () {
                    context.read<GroupCallBloc>().add(
                          gce.GroupCallEvent.endCall(state.groupCall.id),
                        );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Placeholder for mic status — Task 25 wires LiveKit local mic mute/unmute.
/// In Lobby the host hasn't joined the LiveKit room as a publisher yet
/// (token is in InLobby state but mic toggle UX lives in Active).
class _MicStatusRow extends StatelessWidget {
  const _MicStatusRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.mic_none, size: 20),
        const SizedBox(width: 4),
        Text(
          AppLocalizations.of(context)!.groupCallMicHint,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }
}

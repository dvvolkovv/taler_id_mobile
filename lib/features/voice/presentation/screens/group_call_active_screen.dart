import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taler_id_mobile/core/di/service_locator.dart';
import 'package:taler_id_mobile/core/mesh/voice/group_mesh_call_state.dart';
import 'package:taler_id_mobile/features/voice/presentation/bloc/group_mesh_call_bloc.dart';
import 'package:taler_id_mobile/features/voice/presentation/bloc/group_mesh_call_event.dart';
import 'package:taler_id_mobile/l10n/app_localizations.dart';

/// Active mesh group call screen.
///
/// Renders participants from [GMCActive] state emitted by [GroupMeshCallBloc].
/// Audio engine runs inside [GroupMeshCallService] — this screen is a pure
/// renderer; it does not own any LiveKit [Room] object.
class GroupCallActiveScreen extends StatelessWidget {
  const GroupCallActiveScreen({super.key, required this.callId});
  final String callId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: sl<GroupMeshCallBloc>(),
      child: BlocConsumer<GroupMeshCallBloc, GroupMeshCallState>(
        listener: (context, state) {
          if (state is GMCEnded) {
            Navigator.of(context).maybePop();
          }
        },
        builder: (context, state) {
          if (state is! GMCActive) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          return _ActiveCallView(state: state);
        },
      ),
    );
  }
}

class _ActiveCallView extends StatelessWidget {
  const _ActiveCallView({required this.state});
  final GMCActive state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${l10n.meshGcTopTitle} • ${state.roster.length}',
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: state.roster.length <= 2 ? 1 : 2,
              childAspectRatio: 1,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
            ),
            itemCount: state.roster.length,
            itemBuilder: (context, i) => _ParticipantTile(p: state.roster[i]),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton.filledTonal(
                icon: Icon(state.selfMuted ? Icons.mic_off : Icons.mic),
                onPressed: () => context
                    .read<GroupMeshCallBloc>()
                    .add(const GMCToggleMute()),
              ),
              FloatingActionButton(
                backgroundColor: Colors.red,
                onPressed: () => context
                    .read<GroupMeshCallBloc>()
                    .add(const GMCLeavePressed()),
                child: const Icon(Icons.call_end, color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ParticipantTile extends StatelessWidget {
  const _ParticipantTile({required this.p});
  final GMCParticipant p;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 36,
              backgroundImage:
                  p.avatarUrl != null ? NetworkImage(p.avatarUrl!) : null,
              child: p.avatarUrl == null
                  ? Text(
                      (p.displayName ?? p.userId).substring(0, 1).toUpperCase(),
                      style: const TextStyle(fontSize: 24),
                    )
                  : null,
            ),
            const SizedBox(height: 8),
            Text(
              p.displayName ?? p.userId,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (p.isMuted)
                  const Icon(Icons.mic_off, size: 16, color: Colors.grey),
                if (p.isSpeaking)
                  Container(
                    margin: const EdgeInsets.only(left: 4),
                    height: 4,
                    width: 24,
                    color: Colors.green,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:livekit_client/livekit_client.dart' as lk;

import '../../../../core/di/service_locator.dart';
import '../../domain/entities/group_call_invite.dart';
import '../bloc/group_call_bloc.dart';
// Alias the event import: `GroupCallEvent.ended` and `GroupCallState.ended`
// both freezed-generate a top-level class named `Ended`, so we hide the event
// one here and reach for it via the alias when needed.
import '../bloc/group_call_event.dart' as gce;
import '../bloc/group_call_state.dart';
import '../widgets/host_actions_sheet.dart';
import '../widgets/participant_tile.dart';

/// Active multi-party voice room screen.
///
/// Owns its own [lk.Room] and connects with the token + ws URL from the
/// [InActive] state. Mirrors the LiveKit patterns from `voice_call_screen.dart`
/// (the canonical 1-on-1 implementation) for room creation, ActiveSpeakers
/// tracking and disconnect handling, but stays a separate screen — Phase 1
/// spec forbids touching the 1-on-1 flow.
class GroupCallActiveScreen extends StatefulWidget {
  final String callId;
  const GroupCallActiveScreen({super.key, required this.callId});

  @override
  State<GroupCallActiveScreen> createState() => _GroupCallActiveScreenState();
}

class _GroupCallActiveScreenState extends State<GroupCallActiveScreen> {
  lk.Room? _room;
  lk.EventsListener<lk.RoomEvent>? _eventsListener;
  Set<String> _activeSpeakers = {};
  bool _muted = false;
  bool _connecting = true;
  bool _muteRequestedToastShown = false;

  late final GroupCallBloc _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = sl<GroupCallBloc>();
    // Connect to LiveKit on first frame
    WidgetsBinding.instance.addPostFrameCallback((_) => _connectIfNeeded());
  }

  Future<void> _connectIfNeeded() async {
    if (_room != null) return;
    final state = _bloc.state;
    if (state is! InActive) return;
    if (state.groupCall.id != widget.callId) return;

    final room = lk.Room();
    _room = room;

    _eventsListener = room.createListener()
      ..on<lk.ActiveSpeakersChangedEvent>((evt) {
        if (!mounted) return;
        setState(() {
          _activeSpeakers = evt.speakers.map((p) => p.identity).toSet();
        });
      })
      ..on<lk.RoomDisconnectedEvent>((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Соединение потеряно')),
        );
      });

    try {
      await room.connect(state.livekitWsUrl, state.livekitToken);
      await room.localParticipant?.setMicrophoneEnabled(true);
      if (mounted) setState(() => _connecting = false);
    } catch (e) {
      if (mounted) {
        setState(() => _connecting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка LiveKit: $e')),
        );
      }
    }
  }

  Future<void> _toggleMute() async {
    if (_room == null) return;
    final next = !_muted;
    await _room!.localParticipant?.setMicrophoneEnabled(!next);
    if (mounted) setState(() => _muted = next);
  }

  Future<void> _leave() async {
    await _room?.disconnect();
    _bloc.add(gce.GroupCallEvent.leaveCall(widget.callId));
  }

  @override
  void dispose() {
    _eventsListener?.dispose();
    _room?.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<GroupCallBloc>.value(
      value: _bloc,
      child: BlocConsumer<GroupCallBloc, GroupCallState>(
        listener: (context, state) async {
          if (state is Ended) {
            await _room?.disconnect();
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(_endedLabel(state.reason))),
              );
              Future.microtask(() {
                if (context.mounted) context.go('/calls');
              });
            }
          } else if (state is Idle) {
            await _room?.disconnect();
            if (context.mounted) context.go('/calls');
          } else if (state is InActive && state.muteRequestedByHost) {
            // Soft mute — disable local mic if currently publishing.
            // Show the toast at most once per request to avoid spam.
            if (!_muted && _room != null) {
              await _room!.localParticipant?.setMicrophoneEnabled(false);
              if (mounted) setState(() => _muted = true);
            }
            if (!_muteRequestedToastShown && context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Хост попросил всех замьютиться')),
              );
              _muteRequestedToastShown = true;
            }
          }
        },
        builder: (context, state) {
          if (state is! InActive || state.groupCall.id != widget.callId) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          return _ActiveView(
            state: state,
            connecting: _connecting,
            muted: _muted,
            activeSpeakers: _activeSpeakers,
            myUserId: _room?.localParticipant?.identity ?? '',
            onToggleMute: _toggleMute,
            onLeave: _leave,
          );
        },
      ),
    );
  }

  String _endedLabel(String reason) {
    switch (reason) {
      case 'timeout':
        return 'Никто не ответил';
      case 'host_ended':
        return 'Звонок завершён хостом';
      case 'all_left':
        return 'Все вышли из звонка';
      default:
        return 'Звонок завершён';
    }
  }
}

class _ActiveView extends StatelessWidget {
  final InActive state;
  final bool connecting;
  final bool muted;
  final Set<String> activeSpeakers;
  final String myUserId;
  final VoidCallback onToggleMute;
  final VoidCallback onLeave;

  const _ActiveView({
    required this.state,
    required this.connecting,
    required this.muted,
    required this.activeSpeakers,
    required this.myUserId,
    required this.onToggleMute,
    required this.onLeave,
  });

  @override
  Widget build(BuildContext context) {
    final isHost = state.groupCall.hostUserId == myUserId;
    final activeInvites = state.groupCall.invites
        .where((i) =>
            i.status == GroupCallInviteStatus.joined ||
            i.status == GroupCallInviteStatus.calling)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('Группа • ${activeInvites.length + 1}'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              if (connecting)
                const Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: LinearProgressIndicator(),
                ),
              Expanded(
                child: GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: activeInvites.length <= 4 ? 2 : 3,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: activeInvites.length,
                  itemBuilder: (_, i) {
                    final inv = activeInvites[i];
                    final isParticipantHost =
                        inv.userId == state.groupCall.hostUserId;
                    return ParticipantTile(
                      displayName: inv.displayName,
                      avatarUrl: inv.avatarUrl,
                      status: inv.status,
                      isHost: isParticipantHost,
                      isActiveSpeaker: activeSpeakers.contains(inv.userId),
                      onLongPress: isHost && inv.userId != myUserId
                          ? () => showModalBottomSheet<void>(
                                context: context,
                                builder: (_) => HostActionsSheet(
                                  targetName: inv.displayName,
                                  onKick: () =>
                                      context.read<GroupCallBloc>().add(
                                            gce.GroupCallEvent.kick(
                                                state.groupCall.id,
                                                inv.userId),
                                          ),
                                ),
                              )
                          : null,
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    icon: Icon(muted ? Icons.mic_off : Icons.mic),
                    iconSize: 28,
                    tooltip: muted ? 'Включить микрофон' : 'Заглушить',
                    onPressed: onToggleMute,
                  ),
                  if (isHost)
                    IconButton(
                      icon: const Icon(Icons.volume_off),
                      iconSize: 28,
                      tooltip: 'Заглушить всех',
                      onPressed: () => context.read<GroupCallBloc>().add(
                            gce.GroupCallEvent.muteAll(state.groupCall.id),
                          ),
                    ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.call_end),
                    label: const Text('Уйти'),
                    onPressed: onLeave,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

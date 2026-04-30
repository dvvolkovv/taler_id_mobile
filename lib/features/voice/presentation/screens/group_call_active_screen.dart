import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:livekit_client/livekit_client.dart' as lk;

import '../../../../core/di/service_locator.dart';
import '../../../../core/utils/constants.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/group_call_invite.dart';
import '../../domain/repositories/group_call_repository.dart';
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
  StreamSubscription<GroupCallState>? _stateSub;

  late final GroupCallBloc _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = sl<GroupCallBloc>();
    // ignore: avoid_print
    print('[ActiveScreen] initState callId=${widget.callId} initialState=${_bloc.state.runtimeType}');

    // The screen mounts in two paths:
    //   (a) Host: BLoC already InActive (lobby auto-promoted on first JOIN).
    //       `_connectIfNeeded` from the postFrame callback below succeeds.
    //   (b) Invitee: CallKit/deep-link mounts us with state=Idle. We dispatch
    //       JoinCall, but the REST round-trip + `inActive` emit completes
    //       *after* the postFrame callback has already returned. Without a
    //       state listener the screen would sit on a spinner forever — so we
    //       subscribe to the bloc's state stream and re-run `_connectIfNeeded`
    //       on every emission. Idempotent via `_room != null` early-return.
    _stateSub = _bloc.stream.listen((s) {
      // ignore: avoid_print
      print('[ActiveScreen] state stream emit ${s.runtimeType}');
      _connectIfNeeded();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final s = _bloc.state;
      final needsJoin = s is Idle ||
          s is Creating ||
          s is ErrorState ||
          (s is InLobby && s.groupCall.id != widget.callId) ||
          (s is InActive && s.groupCall.id != widget.callId);
      // ignore: avoid_print
      print('[ActiveScreen] postFrame state=${s.runtimeType} needsJoin=$needsJoin');
      if (needsJoin) {
        // Cold-start guard: GoRouter restores the last URL, so we may mount
        // for a callId that has already TIMEOUT'd / ENDED. Without this
        // pre-flight the user sees a spinner → "call not found" snackbar →
        // bounce to call-history. Skip the pre-flight when state is already
        // InActive for this callId (host's lobby→active path has fresh
        // state and shouldn't pay the round-trip).
        _preflightThenJoin();
      } else {
        _connectIfNeeded();
      }
    });
  }

  /// Verify the call is still active server-side before dispatching JoinCall.
  /// On any failure (network blip, parse error) we fall through to the normal
  /// JoinCall path — the BLoC's existing 410-Gone → ErrorState handler will
  /// still bounce the user back to call-history, just with the spinner flicker
  /// we are trying to avoid in the happy path.
  Future<void> _preflightThenJoin() async {
    try {
      final repo = sl<GroupCallRepository>();
      final activeCalls = await repo.getActiveCallsForMe();
      // ignore: avoid_print
      print(
          '[ActiveScreen] preflight got ${activeCalls.length} active calls; looking for ${widget.callId}');
      final isStillActive =
          activeCalls.any((c) => c.id == widget.callId);
      if (!isStillActive) {
        // ignore: avoid_print
        print(
            '[ActiveScreen] preflight: call ${widget.callId} not active — bouncing to call-history');
        if (!mounted) return;
        Future.microtask(() {
          if (!mounted) return;
          context.go(RouteConstants.callHistory);
        });
        return;
      }
    } catch (e) {
      // Pre-flight is best-effort; if it fails we still try JoinCall and
      // let the existing error-handling path take over.
      // ignore: avoid_print
      print('[ActiveScreen] preflight failed: $e — proceeding with JoinCall');
    }
    if (!mounted) return;
    _bloc.add(gce.GroupCallEvent.joinCall(widget.callId));
    _connectIfNeeded();
  }

  Future<void> _connectIfNeeded() async {
    // ignore: avoid_print
    print('[ActiveScreen] _connectIfNeeded callId=${widget.callId} state=${_bloc.state.runtimeType} _room=${_room != null}');
    if (_room != null) return;
    final state = _bloc.state;
    if (state is! InActive) {
      // ignore: avoid_print
      print('[ActiveScreen] state not InActive — skipping connect');
      return;
    }
    if (state.groupCall.id != widget.callId) {
      // ignore: avoid_print
      print('[ActiveScreen] state.id=${state.groupCall.id} != widget.callId=${widget.callId} — skipping connect');
      return;
    }
    // ignore: avoid_print
    print('[ActiveScreen] connecting wsUrl=${state.livekitWsUrl} tokenLen=${state.livekitToken.length}');

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
          SnackBar(
            content:
                Text(AppLocalizations.of(context)!.groupCallConnectionLost),
          ),
        );
      });

    try {
      await room.connect(state.livekitWsUrl, state.livekitToken);
      // ignore: avoid_print
      print('[ActiveScreen] room.connect OK');
      await room.localParticipant?.setMicrophoneEnabled(true);
      if (mounted) setState(() => _connecting = false);
    } catch (e) {
      // ignore: avoid_print
      print('[ActiveScreen] room.connect FAILED: $e');
      if (mounted) {
        setState(() => _connecting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${AppLocalizations.of(context)!.groupCallLivekitError}: $e',
            ),
          ),
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
    _stateSub?.cancel();
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
                SnackBar(content: Text(_endedLabel(context, state.reason))),
              );
              Future.microtask(() {
                if (context.mounted) context.go(RouteConstants.callHistory);
              });
            }
          } else if (state is Idle) {
            await _room?.disconnect();
            if (context.mounted) context.go(RouteConstants.callHistory);
          } else if (state is ErrorState) {
            // JoinCall failed (call already ended / network blip / no invite
            // for this user). Without this branch the screen would sit on a
            // spinner forever — observed when CallKit fires for a stale
            // invite that the server has already TIMEOUT'd.
            await _room?.disconnect();
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message)),
              );
              Future.microtask(() {
                if (context.mounted) context.go(RouteConstants.callHistory);
              });
            }
          } else if (state is InActive && state.groupCall.id == widget.callId) {
            // State just became InActive (e.g. after JoinCall completed for
            // a deep-link invitee, or host's lobby auto-promoted). Try to
            // open the LiveKit connection if we haven't yet.
            if (_room == null) await _connectIfNeeded();
            if (state.muteRequestedByHost) {
              // Soft mute — disable local mic if currently publishing.
              // Show the toast at most once per request to avoid spam.
              if (!_muted && _room != null) {
                await _room!.localParticipant?.setMicrophoneEnabled(false);
                if (mounted) setState(() => _muted = true);
              }
              if (!_muteRequestedToastShown && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      AppLocalizations.of(context)!.groupCallMuteRequested,
                    ),
                  ),
                );
                _muteRequestedToastShown = true;
              }
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
    final l10n = AppLocalizations.of(context)!;
    final isHost = state.groupCall.hostUserId == myUserId;
    final activeInvites = state.groupCall.invites
        .where((i) =>
            i.status == GroupCallInviteStatus.joined ||
            i.status == GroupCallInviteStatus.calling)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.groupCallActiveTitle(activeInvites.length + 1)),
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
                    tooltip: muted
                        ? l10n.groupCallUnmute
                        : l10n.groupCallMute,
                    onPressed: onToggleMute,
                  ),
                  if (isHost)
                    IconButton(
                      icon: const Icon(Icons.volume_off),
                      iconSize: 28,
                      tooltip: l10n.groupCallMuteAll,
                      onPressed: () => context.read<GroupCallBloc>().add(
                            gce.GroupCallEvent.muteAll(state.groupCall.id),
                          ),
                    ),
                  Flexible(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.call_end),
                      label: Text(l10n.groupCallLeave),
                      onPressed: onLeave,
                    ),
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

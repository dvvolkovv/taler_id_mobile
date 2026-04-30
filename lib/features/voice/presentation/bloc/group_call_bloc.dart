import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/services/call_state_service.dart';
import '../../../messenger/data/datasources/messenger_remote_datasource.dart';
import '../../domain/entities/group_call_invite.dart';
import '../../domain/repositories/group_call_repository.dart';
import 'group_call_event.dart' hide Ended;
import 'group_call_event.dart' as ev show Ended;
import 'group_call_state.dart';

/// State machine for the multi-party group voice call (Phase 1).
///
/// User-driven events translate to REST calls on [GroupCallRepository];
/// the resulting state transitions [Idle] → [Creating]/[InLobby]/[InActive] →
/// [Ended]. Server-pushed events arrive over Socket.io via
/// [MessengerRemoteDataSource] streams and are funneled into the same BLoC
/// as [StatusUpdated] / [Kicked] / [MuteRequested] / [HostChanged] / [Ended]
/// (Socket.io variant) so we never mutate state outside the event loop.
///
/// Note: [MessengerRemoteDataSource.gcInviteStream] (incoming invitations) is
/// intentionally NOT wired here — invitations are consumed at the
/// notification/CallKit layer (Task 28); the BLoC only handles already-
/// accepted/in-progress calls. Per-participant `group_call_joined`/`left`
/// events are folded into `group_call_status` by the backend, so we don't
/// subscribe to them either.
class GroupCallBloc extends Bloc<GroupCallEvent, GroupCallState> {
  final GroupCallRepository _repo;
  final MessengerRemoteDataSource _socket;
  final List<StreamSubscription<dynamic>> _subs = [];

  GroupCallBloc(this._repo, this._socket) : super(const GroupCallState.idle()) {
    on<CreateCall>(_onCreate);
    on<JoinCall>(_onJoin);
    on<DeclineCall>(_onDecline);
    on<LeaveCall>(_onLeave);
    on<InviteMore>(_onInviteMore);
    on<Kick>(_onKick);
    on<MuteAll>(_onMuteAll);
    on<EndCall>(_onEnd);
    on<StatusUpdated>(_onStatusUpdated);
    on<Kicked>(_onKicked);
    on<MuteRequested>(_onMuteRequested);
    on<HostChanged>(_onHostChanged);
    on<ev.Ended>(_onEnded);

    _subscribeSocket();
  }

  void _subscribeSocket() {
    _subs.add(_socket.gcStatusStream
        .listen((p) => add(GroupCallEvent.statusUpdated(p))));
    _subs.add(_socket.gcKickedStream
        .listen((p) => add(GroupCallEvent.kicked(p))));
    _subs.add(_socket.gcMuteRequestStream
        .listen((p) => add(GroupCallEvent.muteRequested(p))));
    _subs.add(_socket.gcHostChangedStream
        .listen((p) => add(GroupCallEvent.hostChanged(p))));
    _subs.add(_socket.gcEndedStream
        .listen((p) => add(GroupCallEvent.ended(p))));
  }

  Future<void> _onCreate(CreateCall e, Emitter<GroupCallState> emit) async {
    emit(const GroupCallState.creating());
    try {
      final r = await _repo.create(inviteeIds: e.inviteeIds);
      emit(GroupCallState.inLobby(
        groupCall: r.call,
        livekitToken: r.livekitToken,
        livekitWsUrl: r.livekitWsUrl,
      ));
    } catch (_) {
      emit(const GroupCallState.error('Не удалось создать звонок'));
    }
  }

  Future<void> _onJoin(JoinCall e, Emitter<GroupCallState> emit) async {
    try {
      final r = await _repo.join(e.callId);
      final call = await _repo.getCall(e.callId);
      emit(GroupCallState.inActive(
        groupCall: call,
        livekitToken: r.livekitToken,
        livekitWsUrl: r.livekitWsUrl,
      ));
    } catch (_) {
      emit(const GroupCallState.error('Не удалось присоединиться'));
    }
  }

  Future<void> _onDecline(DeclineCall e, Emitter<GroupCallState> emit) async {
    try {
      await _repo.decline(e.callId);
    } catch (_) {}
    emit(const GroupCallState.idle());
  }

  Future<void> _onLeave(LeaveCall e, Emitter<GroupCallState> emit) async {
    try {
      await _repo.leave(e.callId);
    } catch (_) {}
    emit(const GroupCallState.idle());
  }

  Future<void> _onInviteMore(InviteMore e, Emitter<GroupCallState> emit) async {
    try {
      await _repo.inviteMore(e.callId, e.userIds);
    } catch (_) {}
  }

  Future<void> _onKick(Kick e, Emitter<GroupCallState> emit) async {
    try {
      await _repo.kick(e.callId, e.userId);
    } catch (_) {}
  }

  Future<void> _onMuteAll(MuteAll e, Emitter<GroupCallState> emit) async {
    try {
      await _repo.muteAll(e.callId);
    } catch (_) {}
  }

  Future<void> _onEnd(EndCall e, Emitter<GroupCallState> emit) async {
    try {
      await _repo.end(e.callId);
    } catch (_) {}
    emit(const GroupCallState.idle());
  }

  void _onStatusUpdated(StatusUpdated e, Emitter<GroupCallState> emit) {
    final s = state;
    final updatedId = e.payload['groupCallId'];
    final invitesRaw = e.payload['invites'] as List? ?? const [];
    // ignore: avoid_print
    print('[GroupCallBloc] _onStatusUpdated id=$updatedId state=${s.runtimeType} invitesCount=${invitesRaw.length}');
    if (s is InLobby && s.groupCall.id == updatedId) {
      final invites = _parseInvites(invitesRaw);
      final updatedCall = s.groupCall.copyWith(invites: invites);
      // First invitee transitioned to JOINED -> auto-promote host's lobby
      // to active screen. Token + ws URL carry over from InLobby.
      final anyJoined = invites.any(
        (i) => i.status == GroupCallInviteStatus.joined,
      );
      // ignore: avoid_print
      print('[GroupCallBloc] anyJoined=$anyJoined statuses=${invites.map((i) => i.status).toList()}');
      if (anyJoined) {
        emit(GroupCallState.inActive(
          groupCall: updatedCall,
          livekitToken: s.livekitToken,
          livekitWsUrl: s.livekitWsUrl,
        ));
      } else {
        emit(s.copyWith(groupCall: updatedCall));
      }
    } else if (s is InActive && s.groupCall.id == updatedId) {
      final invites = _parseInvites(invitesRaw);
      emit(s.copyWith(groupCall: s.groupCall.copyWith(invites: invites)));
    }
  }

  void _onKicked(Kicked e, Emitter<GroupCallState> emit) {
    final s = state;
    final affectedId = e.payload['groupCallId'];
    if (s is InLobby && s.groupCall.id == affectedId) {
      emit(const GroupCallState.idle());
    } else if (s is InActive && s.groupCall.id == affectedId) {
      emit(const GroupCallState.idle());
    }
  }

  void _onMuteRequested(MuteRequested e, Emitter<GroupCallState> emit) {
    final s = state;
    if (s is InActive && s.groupCall.id == e.payload['groupCallId']) {
      emit(s.copyWith(muteRequestedByHost: true));
    }
  }

  void _onHostChanged(HostChanged e, Emitter<GroupCallState> emit) {
    final s = state;
    final newHostId = e.payload['newHostUserId'] as String?;
    if (newHostId == null) return;
    if (s is InActive && s.groupCall.id == e.payload['groupCallId']) {
      emit(s.copyWith(
        groupCall: s.groupCall.copyWith(hostUserId: newHostId),
      ));
    } else if (s is InLobby && s.groupCall.id == e.payload['groupCallId']) {
      emit(s.copyWith(
        groupCall: s.groupCall.copyWith(hostUserId: newHostId),
      ));
    }
  }

  void _onEnded(ev.Ended e, Emitter<GroupCallState> emit) {
    final s = state;
    final endedId = e.payload['groupCallId'];
    final reason = (e.payload['reason'] as String?) ?? 'unknown';
    if (s is InLobby && s.groupCall.id == endedId) {
      emit(GroupCallState.ended(reason));
    } else if (s is InActive && s.groupCall.id == endedId) {
      emit(GroupCallState.ended(reason));
    }
  }

  List<GroupCallInvite> _parseInvites(List<dynamic> raw) {
    return raw
        .map((r) => _parseInvite(Map<String, dynamic>.from(r as Map)))
        .toList();
  }

  GroupCallInvite _parseInvite(Map<String, dynamic> j) {
    final user = j['user'] is Map ? Map<String, dynamic>.from(j['user'] as Map) : null;
    final profile = user != null && user['profile'] is Map
        ? Map<String, dynamic>.from(user['profile'] as Map)
        : null;
    final firstName = (profile?['firstName'] as String?)?.trim() ?? '';
    final lastName = (profile?['lastName'] as String?)?.trim() ?? '';
    final fullName = '$firstName $lastName'.trim();
    return GroupCallInvite(
      id: j['id'] as String,
      userId: j['userId'] as String,
      displayName: fullName.isEmpty ? (j['userId'] as String) : fullName,
      avatarUrl: profile?['avatarUrl'] as String?,
      status: _statusFromString(j['status'] as String),
      joinedAt:
          j['joinedAt'] != null ? DateTime.parse(j['joinedAt'] as String) : null,
      leftAt: j['leftAt'] != null ? DateTime.parse(j['leftAt'] as String) : null,
    );
  }

  GroupCallInviteStatus _statusFromString(String s) {
    switch (s) {
      case 'CALLING':
        return GroupCallInviteStatus.calling;
      case 'JOINED':
        return GroupCallInviteStatus.joined;
      case 'DECLINED':
        return GroupCallInviteStatus.declined;
      case 'TIMEOUT':
        return GroupCallInviteStatus.timeout;
      case 'LEFT':
        return GroupCallInviteStatus.left;
      default:
        return GroupCallInviteStatus.calling;
    }
  }

  @override
  void onTransition(Transition<GroupCallEvent, GroupCallState> transition) {
    super.onTransition(transition);
    final next = transition.nextState;
    final svc = CallStateService.instance;
    if (next is InLobby) {
      svc.setActiveGroupCall(next.groupCall.id);
    } else if (next is InActive) {
      svc.setActiveGroupCall(next.groupCall.id);
    } else {
      // Idle, Ended, ErrorState, Creating — all imply "not in a call".
      // (Creating is a transient pre-LOBBY state; clearing is fine since the
      // next emission will be either InLobby (set) or ErrorState (stay null).)
      svc.setActiveGroupCall(null);
    }
  }

  @override
  Future<void> close() async {
    for (final s in _subs) {
      await s.cancel();
    }
    return super.close();
  }
}

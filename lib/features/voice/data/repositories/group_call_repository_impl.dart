import '../../domain/entities/group_call.dart';
import '../../domain/entities/group_call_invite.dart';
import '../../domain/repositories/group_call_repository.dart';
import '../datasources/group_call_remote_datasource.dart';
import '../models/group_call_dto.dart';

/// Maps wire DTOs to domain entities. The backend never sends a top-level
/// `displayName`; this layer synthesizes it from `profile.firstName +
/// lastName`, falling back to the user's id (mirrors backend
/// `group-call.service.ts` host-payload synthesis).
class GroupCallRepositoryImpl implements GroupCallRepository {
  final GroupCallRemoteDatasource _remote;

  GroupCallRepositoryImpl(this._remote);

  @override
  Future<({GroupCall call, String livekitToken, String livekitWsUrl})> create({
    required List<String> inviteeIds,
  }) async {
    final r = await _remote.create(inviteeIds);
    return (
      call: _toCallEntity(r.groupCall),
      livekitToken: r.livekitToken,
      livekitWsUrl: r.livekitWsUrl,
    );
  }

  @override
  Future<List<GroupCall>> getActiveCallsForMe() async {
    final dtos = await _remote.getActive();
    return dtos.map(_toCallEntity).toList();
  }

  @override
  Future<GroupCall> getCall(String callId) async =>
      _toCallEntity(await _remote.getCall(callId));

  @override
  Future<({String livekitToken, String livekitWsUrl})> join(String callId) async {
    final r = await _remote.join(callId);
    return (livekitToken: r.livekitToken, livekitWsUrl: r.livekitWsUrl);
  }

  @override
  Future<void> decline(String callId) => _remote.decline(callId);

  @override
  Future<void> leave(String callId) => _remote.leave(callId);

  @override
  Future<void> inviteMore(String callId, List<String> userIds) =>
      _remote.inviteMore(callId, userIds);

  @override
  Future<void> kick(String callId, String userId) =>
      _remote.kick(callId, userId);

  @override
  Future<void> muteAll(String callId) => _remote.muteAll(callId);

  @override
  Future<void> end(String callId) => _remote.end(callId);

  // --- Mapping helpers ---

  GroupCall _toCallEntity(GroupCallDto d) {
    return GroupCall(
      id: d.id,
      livekitRoomName: d.livekitRoomName,
      hostUserId: d.hostUserId,
      hostDisplayName: _displayNameFor(d.host, fallback: d.hostUserId),
      hostAvatarUrl: d.host?.profile?.avatarUrl,
      status: _mapStatus(d.status),
      startedAt: d.startedAt,
      invites: d.invites.map(_toInviteEntity).toList(),
    );
  }

  GroupCallInvite _toInviteEntity(GroupCallInviteDto d) {
    return GroupCallInvite(
      id: d.id,
      userId: d.userId,
      displayName: _displayNameFor(d.user, fallback: d.userId),
      avatarUrl: d.user?.profile?.avatarUrl,
      status: _mapInviteStatus(d.status),
      joinedAt: d.joinedAt,
      leftAt: d.leftAt,
    );
  }

  String _displayNameFor(UserSummaryDto? user, {required String fallback}) {
    final p = user?.profile;
    if (p == null) return fallback;
    final first = p.firstName?.trim() ?? '';
    final last = p.lastName?.trim() ?? '';
    final full = '$first $last'.trim();
    return full.isEmpty ? fallback : full;
  }

  GroupCallStatus _mapStatus(GroupCallStatusDto s) {
    switch (s) {
      case GroupCallStatusDto.lobby:
        return GroupCallStatus.lobby;
      case GroupCallStatusDto.active:
        return GroupCallStatus.active;
      case GroupCallStatusDto.ended:
        return GroupCallStatus.ended;
    }
  }

  GroupCallInviteStatus _mapInviteStatus(GroupCallInviteStatusDto s) {
    switch (s) {
      case GroupCallInviteStatusDto.calling:
        return GroupCallInviteStatus.calling;
      case GroupCallInviteStatusDto.joined:
        return GroupCallInviteStatus.joined;
      case GroupCallInviteStatusDto.declined:
        return GroupCallInviteStatus.declined;
      case GroupCallInviteStatusDto.timeout:
        return GroupCallInviteStatus.timeout;
      case GroupCallInviteStatusDto.left:
        return GroupCallInviteStatus.left;
    }
  }
}

import '../entities/group_call.dart';

/// Abstract interface for group voice call operations.
/// Implementation lives in `data/repositories/group_call_repository_impl.dart`.
abstract class GroupCallRepository {
  /// Create a new group voice call inviting [inviteeIds]. Returns the created
  /// call domain entity plus the LiveKit token + WebSocket URL the host needs
  /// to connect to the room immediately.
  Future<({GroupCall call, String livekitToken, String livekitWsUrl})> create({
    required List<String> inviteeIds,
  });

  /// Returns calls where the current user is host or has an invite in
  /// (CALLING, JOINED, LEFT, DECLINED) AND the call is in (LOBBY, ACTIVE).
  /// Used for the "active call" banner on the Calls tab.
  Future<List<GroupCall>> getActiveCallsForMe();

  /// Fetch a single call by id. Throws if user is neither host nor invitee.
  Future<GroupCall> getCall(String callId);

  /// Accept an invite. Returns the LiveKit token + WebSocket URL the user
  /// needs to connect to the room. Idempotent — re-issues a fresh token if
  /// the user is already JOINED.
  Future<({String livekitToken, String livekitWsUrl})> join(String callId);

  /// Reject an invite. 409 if invite is already JOINED.
  Future<void> decline(String callId);

  /// Leave an active call. Triggers host-transfer if the leaver was the host.
  /// Auto-ends the call if last JOINED leaves.
  Future<void> leave(String callId);

  // Host-only actions:

  /// Mid-call invite of additional users. 403 if caller is not host. 409 if
  /// (host + JOINED + CALLING + new) > 8.
  Future<void> inviteMore(String callId, List<String> userIds);

  /// Kick a participant. 403 if caller is not host.
  Future<void> kick(String callId, String userId);

  /// Soft mute-all request — broadcasts a `group_call_mute_request` event to
  /// all JOINED participants except the host. Rate-limited to 1 per 10s
  /// per call. Clients decide whether to comply (peer-equal philosophy).
  Future<void> muteAll(String callId);

  /// Force-end the call. 403 if caller is not host.
  Future<void> end(String callId);
}

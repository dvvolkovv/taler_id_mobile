/// Pure decision logic for the chat-room call button. Extracted so it can
/// be unit-tested without instantiating the 6000-line ChatRoomScreen.
///
/// Mesh-first policy: if conversation is DIRECT, peer's userId is known,
/// app is not already in a non-multiline call, no recent LK call within
/// the last 30 minutes, and the peer is currently online via mesh —
/// choose mesh. Otherwise fall through to LiveKit. Conflicts surface as
/// AutoPickDecision.conflict.
enum AutoPickDecision {
  conflict, // active LK or mesh call already in progress
  mesh,     // proceed with MeshVoiceUiCoordinator.placeCall
  lk,       // proceed with the existing LiveKit flow
}

AutoPickDecision chatRoomAutoPickDecision({
  required String? convType,
  required String? otherUserId,
  required bool isInCall,
  required bool canAddLine,
  required bool isUserOnline,
  required int? recentLkCallMs,
  required int nowMs,
  Duration recentLkWindow = const Duration(minutes: 30),
}) {
  if (isInCall && !canAddLine) return AutoPickDecision.conflict;
  if (convType != 'DIRECT') return AutoPickDecision.lk;
  if (otherUserId == null) return AutoPickDecision.lk;
  if (recentLkCallMs != null &&
      nowMs - recentLkCallMs < recentLkWindow.inMilliseconds) {
    return AutoPickDecision.lk;
  }
  if (!isUserOnline) return AutoPickDecision.lk;
  return AutoPickDecision.mesh;
}

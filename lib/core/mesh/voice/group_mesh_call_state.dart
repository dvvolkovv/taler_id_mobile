import 'package:collection/collection.dart';

const _participantListEq = ListEquality<GMCParticipant>();

class GMCParticipant {
  const GMCParticipant({
    required this.devicePk,
    required this.userId,
    required this.status,
    this.displayName,
    this.avatarUrl,
    this.isSelf = false,
    this.isMuted = false,
    this.isSpeaking = false,
  });

  final String devicePk;
  final String userId;
  final GMCStatus status;
  final String? displayName;
  final String? avatarUrl;
  final bool isSelf;
  final bool isMuted;
  final bool isSpeaking;

  GMCParticipant copyWith({
    GMCStatus? status,
    String? displayName,
    String? avatarUrl,
    bool? isMuted,
    bool? isSpeaking,
  }) {
    return GMCParticipant(
      devicePk: devicePk,
      userId: userId,
      status: status ?? this.status,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isSelf: isSelf,
      isMuted: isMuted ?? this.isMuted,
      isSpeaking: isSpeaking ?? this.isSpeaking,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GMCParticipant &&
          other.devicePk == devicePk &&
          other.userId == userId &&
          other.status == status &&
          other.displayName == displayName &&
          other.avatarUrl == avatarUrl &&
          other.isSelf == isSelf &&
          other.isMuted == isMuted &&
          other.isSpeaking == isSpeaking;

  @override
  int get hashCode => Object.hash(
        devicePk,
        userId,
        status,
        displayName,
        avatarUrl,
        isSelf,
        isMuted,
        isSpeaking,
      );
}

enum GMCStatus { calling, joined, declined, noAnswer, connectionFailed, left }

enum GMCEndReason { userHangup, allLeft, noAnswer, allDeclined, error, busy }

sealed class GroupMeshCallState {
  const GroupMeshCallState();
}

final class GMCIdle extends GroupMeshCallState {
  const GMCIdle();

  @override
  bool operator ==(Object other) => other is GMCIdle;

  @override
  int get hashCode => 'GMCIdle'.hashCode;
}

final class GMCInviting extends GroupMeshCallState {
  const GMCInviting({
    required this.roomId,
    required this.invitees,
  });

  final String roomId;
  final List<GMCParticipant> invitees;

  @override
  bool operator ==(Object other) =>
      other is GMCInviting &&
      other.roomId == roomId &&
      _participantListEq.equals(other.invitees, invitees);

  @override
  int get hashCode => Object.hash(roomId, Object.hashAll(invitees));
}

final class GMCLobby extends GroupMeshCallState {
  const GMCLobby({
    required this.roomId,
    required this.hostDevicePk,
    required this.roster,
  });

  final String roomId;
  final String hostDevicePk;
  final List<GMCParticipant> roster;

  GMCLobby copyWith({List<GMCParticipant>? roster}) => GMCLobby(
        roomId: roomId,
        hostDevicePk: hostDevicePk,
        roster: roster ?? this.roster,
      );

  @override
  bool operator ==(Object other) =>
      other is GMCLobby &&
      other.roomId == roomId &&
      other.hostDevicePk == hostDevicePk &&
      _participantListEq.equals(other.roster, roster);

  @override
  int get hashCode => Object.hash(
        roomId,
        hostDevicePk,
        Object.hashAll(roster),
      );
}

final class GMCActive extends GroupMeshCallState {
  const GMCActive({
    required this.roomId,
    required this.roster,
    required this.durationSec,
    this.selfMuted = false,
  });

  final String roomId;
  final List<GMCParticipant> roster;
  final int durationSec;
  final bool selfMuted;

  GMCActive copyWith({
    List<GMCParticipant>? roster,
    int? durationSec,
    bool? selfMuted,
  }) =>
      GMCActive(
        roomId: roomId,
        roster: roster ?? this.roster,
        durationSec: durationSec ?? this.durationSec,
        selfMuted: selfMuted ?? this.selfMuted,
      );

  @override
  bool operator ==(Object other) =>
      other is GMCActive &&
      other.roomId == roomId &&
      other.durationSec == durationSec &&
      other.selfMuted == selfMuted &&
      _participantListEq.equals(other.roster, roster);

  @override
  int get hashCode => Object.hash(
        roomId,
        durationSec,
        selfMuted,
        Object.hashAll(roster),
      );
}

final class GMCEnded extends GroupMeshCallState {
  const GMCEnded({required this.reason});

  final GMCEndReason reason;

  @override
  bool operator ==(Object other) =>
      other is GMCEnded && other.reason == reason;

  @override
  int get hashCode => reason.hashCode;
}

final class GMCError extends GroupMeshCallState {
  const GMCError({required this.message});

  final String message;

  @override
  bool operator ==(Object other) =>
      other is GMCError && other.message == message;

  @override
  int get hashCode => message.hashCode;
}

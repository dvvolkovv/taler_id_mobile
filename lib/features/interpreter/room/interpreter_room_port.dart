import 'package:equatable/equatable.dart';

/// Identifies one published LiveKit track, enough for the controller to
/// decide whether to subscribe to it and for the port to act on that
/// decision.
class RoomTrackRef extends Equatable {
  final String participantIdentity;
  final String trackName;
  final String trackSid;

  const RoomTrackRef({
    required this.participantIdentity,
    required this.trackName,
    required this.trackSid,
  });

  @override
  List<Object?> get props => [participantIdentity, trackName, trackSid];
}

/// Everything the room can tell [InterpreterRoomController] about, in LiveKit
/// vocabulary but without a LiveKit import — that is what keeps the
/// controller unit-testable against a hand-written fake.
sealed class RoomPortEvent extends Equatable {
  const RoomPortEvent();
}

class ParticipantJoined extends RoomPortEvent {
  final String identity;
  const ParticipantJoined(this.identity);
  @override
  List<Object?> get props => [identity];
}

class ParticipantLeft extends RoomPortEvent {
  final String identity;
  const ParticipantLeft(this.identity);
  @override
  List<Object?> get props => [identity];
}

class TrackPublished extends RoomPortEvent {
  final RoomTrackRef track;
  const TrackPublished(this.track);
  @override
  List<Object?> get props => [track];
}

class DataReceived extends RoomPortEvent {
  final String topic;
  final List<int> bytes;
  final String fromIdentity;
  const DataReceived({
    required this.topic,
    required this.bytes,
    required this.fromIdentity,
  });
  @override
  List<Object?> get props => [topic, bytes, fromIdentity];
}

class Reconnecting extends RoomPortEvent {
  const Reconnecting();
  @override
  List<Object?> get props => const [];
}

class Reconnected extends RoomPortEvent {
  const Reconnected();
  @override
  List<Object?> get props => const [];
}

class Disconnected extends RoomPortEvent {
  const Disconnected();
  @override
  List<Object?> get props => const [];
}

/// Thin seam over `livekit_client`'s `Room` so [InterpreterRoomController]'s
/// logic (subscription filtering, mic ordering, partner/agent detection) is
/// testable without a real room. The production implementation adapts
/// `livekit_client` to this port and is exercised manually, not unit-tested.
abstract class InterpreterRoomPort {
  Future<void> connect(String url, String token);

  /// `<userId>#<8 hex>` of the local participant, valid only after [connect].
  String get localIdentity;

  /// Who and what was already in the room when [connect] returned. [events]
  /// only reports later changes, and the guest always arrives after the agent
  /// has published its tracks.
  List<String> get remoteIdentities;
  List<RoomTrackRef> get remoteTracks;

  /// Restricts which other participants may subscribe to the local mic to
  /// just [agentIdentity] — must be called before [setMicrophone] publishes
  /// the track, otherwise there is a window where the partner's device could
  /// subscribe to raw, untranslated audio.
  void restrictMicTo(String agentIdentity);

  Future<void> setMicrophone(bool on);

  Future<void> subscribe(RoomTrackRef track);

  Future<void> disconnect();

  Stream<RoomPortEvent> get events;
}

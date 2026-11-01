import 'dart:async';

import 'package:equatable/equatable.dart';

import 'interpreter_room_port.dart';
import 'interpreter_signal.dart' as sig;

/// Identity of the translation agent in every interpreter room (spec:
/// "the agent is `voice-interpreter`").
const agentIdentity = 'voice-interpreter';

/// Connection health as the controller reports it upward; distinct from
/// Flutter's own `ConnectionState` to avoid a confusing shadowed import at
/// call sites.
enum InterpreterConnectionState { reconnecting, ok }

/// What [InterpreterRoomController] reports to the screen/bloc.
sealed class RoomUpdate extends Equatable {
  const RoomUpdate();
}

class PartnerJoined extends RoomUpdate {
  final String identity;
  const PartnerJoined(this.identity);
  @override
  List<Object?> get props => [identity];
}

class PartnerLeft extends RoomUpdate {
  final String identity;
  const PartnerLeft(this.identity);
  @override
  List<Object?> get props => [identity];
}

class AgentJoined extends RoomUpdate {
  const AgentJoined();
  @override
  List<Object?> get props => const [];
}

class AgentLeft extends RoomUpdate {
  const AgentLeft();
  @override
  List<Object?> get props => const [];
}

class Signal extends RoomUpdate {
  final sig.InterpreterSignal signal;
  const Signal(this.signal);
  @override
  List<Object?> get props => [signal];
}

class Connection extends RoomUpdate {
  final InterpreterConnectionState state;
  const Connection(this.state);
  @override
  List<Object?> get props => [state];
}

class Closed extends RoomUpdate {
  const Closed();
  @override
  List<Object?> get props => const [];
}

/// Owns one interpreter LiveKit room for the lifetime of a call. Translates
/// raw [RoomPortEvent]s from [InterpreterRoomPort] into the [RoomUpdate]s the
/// screen/bloc understand, applying the spec's subscription and mic rules:
///
/// - mic access is restricted to the agent *before* the mic track is
///   published, so there is never a window where the partner's device could
///   subscribe to raw, untranslated audio;
/// - the only track ever subscribed to is the one named
///   `interp-for-<my base identity>`, and only when published by the agent —
///   the partner's own mic track and the other listener's `interp-for-*`
///   track are both ignored, including after a reconnect re-announces them.
class InterpreterRoomController {
  final InterpreterRoomPort _port;

  final _updates = StreamController<RoomUpdate>.broadcast();
  StreamSubscription<RoomPortEvent>? _sub;
  String _myBase = '';
  String _myTrackName = '';
  bool _agentPresent = false;

  /// Mic state as last set through [start]/[setMic] — independent of
  /// whatever the mic is actually doing mid-reconnect (see [Reconnecting]).
  bool _micOn = false;
  bool _reconnecting = false;

  InterpreterRoomController(this._port);

  Stream<RoomUpdate> get updates => _updates.stream;
  bool get agentPresent => _agentPresent;

  /// Base identity (`<userId>`, without the `#<device>` suffix) of the local
  /// participant, valid only after [start]. Callers that need to tell "is
  /// this me?" from a signal's bare `speaker` userId — which is exactly the
  /// shape the agent's `interp`-topic data uses — compare against this
  /// rather than against [InterpreterRoomPort.localIdentity] directly.
  String get myBaseIdentity => _myBase;

  static String baseOf(String identity) {
    final i = identity.indexOf('#');
    return i == -1 ? identity : identity.substring(0, i);
  }

  Future<void> start({
    required String url,
    required String token,
    required bool micOn,
  }) async {
    await _port.connect(url, token);
    _myBase = baseOf(_port.localIdentity);
    _myTrackName = 'interp-for-$_myBase';
    _micOn = micOn;

    // Order matters: permissions must be in place before the mic track is
    // published, otherwise the partner's device has a window to subscribe to
    // the raw (untranslated) track.
    _port.restrictMicTo(agentIdentity);
    await _port.setMicrophone(micOn);

    // Listen first, then go through what is already there: an event may be
    // reported twice, but nothing falls between the two.
    _sub = _port.events.listen(_onEvent);
    for (final id in _port.remoteIdentities) {
      _onEvent(ParticipantJoined(id));
    }
    _subscribePresentTracks();
  }

  void _subscribePresentTracks() {
    for (final track in _port.remoteTracks) {
      _onEvent(TrackPublished(track));
    }
  }

  /// While a full reconnect is in progress the mic is force-muted (see
  /// [Reconnecting]) and must stay that way regardless of what the user
  /// taps — only the remembered state changes, to be applied once
  /// [Reconnected] restores it.
  Future<void> setMic(bool on) {
    _micOn = on;
    if (_reconnecting) return Future.value();
    return _port.setMicrophone(on);
  }

  void _onEvent(RoomPortEvent event) {
    switch (event) {
      case ParticipantJoined(identity: final id):
        if (id == agentIdentity) {
          _agentPresent = true;
          _updates.add(const AgentJoined());
        } else if (baseOf(id) != _myBase) {
          _updates.add(PartnerJoined(id));
        }
      case ParticipantLeft(identity: final id):
        if (id == agentIdentity) {
          _agentPresent = false;
          _updates.add(const AgentLeft());
        } else if (baseOf(id) != _myBase) {
          _updates.add(PartnerLeft(id));
        }
      case TrackPublished(track: final track):
        if (track.participantIdentity == agentIdentity &&
            track.trackName == _myTrackName) {
          _port.subscribe(track);
        }
      case DataReceived(
          topic: final topic,
          bytes: final bytes,
          fromIdentity: final from
        ):
        if (topic == 'interp' && from == agentIdentity) {
          final parsed = sig.parse(bytes);
          if (parsed != null) _updates.add(Signal(parsed));
        }
      case Reconnecting():
        // livekit_client republishes the mic on a full restart BEFORE
        // reporting Reconnected, i.e. before restrictMicTo can be
        // re-applied below — muting here closes that window instead of
        // leaving the raw mic briefly subscribable by the partner.
        _reconnecting = true;
        _port.setMicrophone(false).catchError((_) {});
        _updates.add(const Connection(InterpreterConnectionState.reconnecting));
      case Reconnected():
        _reconnecting = false;
        // LiveKit re-announces existing tracks/participants after a
        // reconnect but does not remember per-track subscription
        // permissions, so the restriction has to be re-applied — before the
        // mic is unmuted again, for the same reason it came first in start().
        _port.restrictMicTo(agentIdentity);
        _port.setMicrophone(_micOn).catchError((_) {});
        _subscribePresentTracks();
        _updates.add(const Connection(InterpreterConnectionState.ok));
      case Disconnected():
        _updates.add(const Closed());
    }
  }

  Future<void> dispose() async {
    await _sub?.cancel();
    await _port.disconnect();
    await _updates.close();
  }
}

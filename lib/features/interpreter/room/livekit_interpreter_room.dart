import 'dart:async';

import 'package:livekit_client/livekit_client.dart' as lk;

import '../../../core/api/endpoint_service.dart';
import '../../../core/di/service_locator.dart';
import 'interpreter_room_port.dart';

/// Thin adapter of `livekit_client`'s [lk.Room] to [InterpreterRoomPort]. Not
/// unit-tested (no fake LiveKit room exists) — exercised manually, and kept
/// deliberately thin so there is little logic left to get wrong here; the
/// subscription/mic-ordering rules live in `InterpreterRoomController`.
class LiveKitInterpreterRoom implements InterpreterRoomPort {
  LiveKitInterpreterRoom({EndpointService? endpointService})
      : _endpointService = endpointService ?? sl<EndpointService>();

  final EndpointService _endpointService;

  lk.Room? _room;
  lk.EventsListener<lk.RoomEvent>? _listener;
  final _events = StreamController<RoomPortEvent>.broadcast();

  @override
  Stream<RoomPortEvent> get events => _events.stream;

  @override
  Future<void> connect(String url, String token) async {
    final room = lk.Room(
      roomOptions: const lk.RoomOptions(
        defaultAudioPublishOptions: lk.AudioPublishOptions(audioBitrate: 32000),
      ),
    );
    _room = room;
    _listener = room.createListener();
    _attachListeners(_listener!);

    // Same CIS fallback-edge check voice_call_screen.dart uses for calls: a
    // direct UDP path to the RU SFU from a non-primary edge dies in ~7s, so
    // force the TURN/TLS relay when the active endpoint is one. No E2EE here
    // — the server has to be able to read the audio to translate it.
    final onEdge = _endpointService.hasFallback &&
        _endpointService.mediaBaseUrl != _endpointService.candidates.first;
    await room.connect(
      url,
      token,
      connectOptions: onEdge
          ? const lk.ConnectOptions(
              autoSubscribe: false,
              rtcConfiguration: lk.RTCConfiguration(
                iceTransportPolicy: lk.RTCIceTransportPolicy.relay,
              ),
            )
          : const lk.ConnectOptions(autoSubscribe: false),
    );
  }

  void _attachListeners(lk.EventsListener<lk.RoomEvent> listener) {
    listener
      ..on<lk.ParticipantConnectedEvent>((e) {
        _events.add(ParticipantJoined(e.participant.identity));
      })
      ..on<lk.ParticipantDisconnectedEvent>((e) {
        _events.add(ParticipantLeft(e.participant.identity));
      })
      ..on<lk.TrackPublishedEvent>((e) {
        _events.add(TrackPublished(RoomTrackRef(
          participantIdentity: e.participant.identity,
          trackName: e.publication.name,
          trackSid: e.publication.sid,
        )));
      })
      ..on<lk.DataReceivedEvent>((e) {
        _events.add(DataReceived(
          topic: e.topic ?? '',
          bytes: e.data,
          fromIdentity: e.participant?.identity ?? '',
        ));
      })
      ..on<lk.RoomReconnectingEvent>((_) {
        _events.add(const Reconnecting());
      })
      ..on<lk.RoomReconnectedEvent>((_) {
        _events.add(const Reconnected());
      })
      ..on<lk.RoomDisconnectedEvent>((_) {
        _events.add(const Disconnected());
      });
  }

  @override
  String get localIdentity => _room?.localParticipant?.identity ?? '';

  @override
  List<String> get remoteIdentities => _room == null
      ? const []
      : [for (final p in _room!.remoteParticipants.values) p.identity];

  @override
  List<RoomTrackRef> get remoteTracks => _room == null
      ? const []
      : [
          for (final p in _room!.remoteParticipants.values)
            for (final pub in p.trackPublications.values)
              RoomTrackRef(
                participantIdentity: p.identity,
                trackName: pub.name,
                trackSid: pub.sid,
              ),
        ];

  @override
  void restrictMicTo(String agentIdentity) {
    _room?.localParticipant?.setTrackSubscriptionPermissions(
      allParticipantsAllowed: false,
      trackPermissions: [
        lk.ParticipantTrackPermission(agentIdentity, true, null),
      ],
    );
  }

  @override
  Future<void> setMicrophone(bool on) async {
    await _room?.localParticipant?.setMicrophoneEnabled(on);
  }

  @override
  Future<void> subscribe(RoomTrackRef track) async {
    final room = _room;
    if (room == null) return;
    for (final p in room.remoteParticipants.values) {
      final pub = p.trackPublications[track.trackSid];
      if (pub != null) {
        // RemoteTrackPublication.subscribe() is itself a no-op when already
        // subscribed, so no extra check is needed here.
        await pub.subscribe();
        return;
      }
    }
  }

  @override
  Future<void> disconnect() async {
    await _listener?.dispose();
    _listener = null;
    await _room?.disconnect();
    await _room?.dispose();
    _room = null;
    await _events.close();
  }
}

/// The room URL calls use: the media endpoint the app is on (the CIS edge
/// included), not the server's own LiveKit address.
String interpreterLivekitUrl([EndpointService? endpoints]) {
  final media = (endpoints ?? sl<EndpointService>()).mediaBaseUrl;
  return '${media.replaceFirst('https://', 'wss://')}/livekit/';
}

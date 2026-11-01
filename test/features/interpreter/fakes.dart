import 'dart:async';

import 'package:taler_id_mobile/features/interpreter/room/interpreter_room_port.dart';

/// Hand-written fake instead of mocktail: the controller's behaviour is a
/// sequence of reactions to a stream of events plus the order of a few
/// calls, which reads far more plainly as a recorded call log + a stream
/// controller than as a pile of `verify`/`verifyInOrder`.
///
/// Shared between the room controller's own tests and the bloc's: the bloc
/// wraps a real `InterpreterRoomController` around this fake rather than
/// mocking the controller itself, so the controller's subscription/mic
/// ordering rules stay exercised end-to-end in bloc tests too.
class FakeRoomPort implements InterpreterRoomPort {
  FakeRoomPort({this.identity = 'me-user#aaaaaaaa', this.connectGate});

  final String identity;

  /// When set, [connect] records its call and then waits on this completer
  /// before returning — lets a test hold a room "connecting" indefinitely to
  /// exercise what happens if the bloc is closed while that is in flight.
  final Completer<void>? connectGate;

  final _events = StreamController<RoomPortEvent>.broadcast();

  final List<String> calls = [];
  final List<RoomTrackRef> subscribed = [];
  bool disconnected = false;
  List<String> present = [];
  List<RoomTrackRef> tracks = [];

  @override
  List<String> get remoteIdentities => present;

  @override
  List<RoomTrackRef> get remoteTracks => tracks;

  void emit(RoomPortEvent event) => _events.add(event);

  @override
  String get localIdentity => identity;

  @override
  Stream<RoomPortEvent> get events => _events.stream;

  @override
  Future<void> connect(String url, String token) async {
    calls.add('connect($url, $token)');
    final gate = connectGate;
    if (gate != null) await gate.future;
  }

  @override
  void restrictMicTo(String agentIdentity) {
    calls.add('restrictMicTo($agentIdentity)');
  }

  @override
  Future<void> setMicrophone(bool on) async {
    calls.add('setMicrophone($on)');
  }

  @override
  Future<void> subscribe(RoomTrackRef track) async {
    calls.add('subscribe(${track.trackName})');
    subscribed.add(track);
  }

  @override
  Future<void> disconnect() async {
    disconnected = true;
    calls.add('disconnect()');
  }

  Future<void> close() => _events.close();
}

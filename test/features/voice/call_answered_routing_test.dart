// Regression cover for the one-way-audio report (2026-07-29): Android caller
// could not hear the iOS callee, while calling back worked.
//
// The server broadcasts call_answered to every participant EXCEPT the answerer,
// so the caller receives it too. The dashboard handler only asked "did I answer
// this?" — always false for the caller — and therefore treated it as "a sibling
// device answered": it flagged the room answeredElsewhere (which blocks joining
// it) and tore down CallKit with fallbackEndAll, killing its own audio.
//
// These cases pin the decision the handler makes, without dragging in the
// widget: the guards below are exactly the ones it applies, in order.

import 'package:flutter_test/flutter_test.dart';
import 'package:livekit_client/livekit_client.dart' as lk;
import 'package:mocktail/mocktail.dart';
import 'package:taler_id_mobile/core/services/call_state_service.dart';

class MockRoom extends Mock implements lk.Room {
  @override
  lk.ConnectionState get connectionState => lk.ConnectionState.connected;
}

class MockLocalParticipant extends Mock implements lk.LocalParticipant {}

MockRoom _room() {
  final room = MockRoom();
  final p = MockLocalParticipant();
  when(() => room.localParticipant).thenReturn(p);
  when(() => p.isMicrophoneEnabled()).thenReturn(true);
  when(() => p.setMicrophoneEnabled(any())).thenAnswer((_) async => null);
  when(() => p.setCameraEnabled(any())).thenAnswer((_) async => null);
  when(() => room.disconnect()).thenAnswer((_) async {});
  return room;
}

/// The handler's decision: should this call_answered be treated as
/// "answered on another device" (and therefore tear our call down)?
bool treatsAsAnsweredElsewhere(CallStateService cs, String roomName) {
  if (cs.didSelfAnswer(roomName)) return false;
  if (cs.outgoingRoomName == roomName) return false;
  if (cs.allLines.any((l) => l.roomName == roomName)) return false;
  return true;
}

void main() {
  late CallStateService cs;

  setUp(() async {
    cs = CallStateService.instance;
    await cs.endCall();
    cs.clearOutgoing();
  });

  test('caller ignores it — this is their callee picking up', () async {
    // Outgoing call: the screen marks the room as ours before dialling.
    cs.markOutgoing('peer-1', 'call-1');

    expect(treatsAsAnsweredElsewhere(cs, 'call-1'), isFalse);
  });

  test('a party already in the room ignores it', () async {
    cs.setRoom(_room(), 'call-1', 'conv-1');

    expect(treatsAsAnsweredElsewhere(cs, 'call-1'), isFalse);
  });

  test('the device that answered ignores its own echo', () async {
    cs.markSelfAnswered('call-1');

    expect(treatsAsAnsweredElsewhere(cs, 'call-1'), isFalse);
  });

  test('a sibling device still acts on it — the case the handler is for', () {
    // Not dialling, not in the room, did not answer: another device did.
    expect(treatsAsAnsweredElsewhere(cs, 'call-1'), isTrue);
  });

  test('an unrelated room is not confused with ours', () async {
    cs.markOutgoing('peer-1', 'call-1');
    cs.setRoom(_room(), 'call-1', 'conv-1');

    // A different call ringing on another device must still be dismissed.
    expect(treatsAsAnsweredElsewhere(cs, 'call-OTHER'), isTrue);
  });
}

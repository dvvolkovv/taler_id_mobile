import 'package:flutter_test/flutter_test.dart';
import 'package:taler_id_mobile/core/api/endpoint_service.dart';
import 'package:taler_id_mobile/features/interpreter/room/livekit_interpreter_room.dart';

void main() {
  test('the room is reached through the media endpoint, as calls do', () {
    final endpoints = EndpointService(
      candidates: ['https://api.talerid.io', 'https://ru.talerid.io'],
      mediaCapable: ['https://api.talerid.io', 'https://ru.talerid.io'],
    );
    expect(interpreterLivekitUrl(endpoints), 'wss://api.talerid.io/livekit/');

    // On the CIS edge the room goes through the edge as well.
    endpoints.activeUrl.value = 'https://ru.talerid.io';
    expect(interpreterLivekitUrl(endpoints), 'wss://ru.talerid.io/livekit/');
  });
}

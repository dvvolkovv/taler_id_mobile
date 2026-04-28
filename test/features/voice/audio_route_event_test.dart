import 'package:flutter_test/flutter_test.dart';
import 'package:taler_id_mobile/features/voice/presentation/screens/voice_call_screen.dart';

void main() {
  group('mapAudioRouteEvent', () {
    test('bluetoothConnected maps to bluetooth', () {
      expect(mapAudioRouteEvent({'event': 'bluetoothConnected'}), 'bluetooth');
    });

    test('bluetoothConnected with extra fields maps to bluetooth', () {
      expect(
        mapAudioRouteEvent({'event': 'bluetoothConnected', 'name': 'AirPods'}),
        'bluetooth',
      );
    });

    test('bluetoothDisconnected maps to earpiece', () {
      expect(mapAudioRouteEvent({'event': 'bluetoothDisconnected'}), 'earpiece');
    });

    test('unknown event returns null', () {
      expect(mapAudioRouteEvent({'event': 'somethingElse'}), isNull);
    });

    test('non-map event returns null', () {
      expect(mapAudioRouteEvent('string event'), isNull);
      expect(mapAudioRouteEvent(42), isNull);
      expect(mapAudioRouteEvent(null), isNull);
    });

    test('map without event key returns null', () {
      expect(mapAudioRouteEvent({'name': 'AirPods'}), isNull);
    });
  });
}

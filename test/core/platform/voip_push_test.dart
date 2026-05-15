// test/core/platform/voip_push_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:taler_id_mobile/core/platform/voip_push.dart';
import 'package:taler_id_mobile/core/platform/voip_push_desktop.dart';

void main() {
  setUp(() => VoipPushPlatform.debugResetForTest());
  tearDown(() => VoipPushPlatform.debugResetForTest());

  group('VoipPushDesktop (no-op)', () {
    test('returns null token', () async {
      final v = VoipPushDesktop();
      expect(await v.getToken(), isNull);
    });

    test('incomingPayloads stream is empty', () async {
      final v = VoipPushDesktop();
      expect(await v.incomingPayloads.toList(), isEmpty);
    });
  });

  group('VoipPushPlatform singleton', () {
    test('debugResetForTest allows re-creation', () {
      final a = VoipPushPlatform.instance;
      VoipPushPlatform.debugResetForTest();
      final b = VoipPushPlatform.instance;
      expect(a, isNotNull);
      expect(b, isNotNull);
    });

    test('debugInstance overrides the singleton', () async {
      VoipPushPlatform.debugInstance = VoipPushDesktop();
      expect(await VoipPushPlatform.instance.getToken(), isNull);
    });
  });
}

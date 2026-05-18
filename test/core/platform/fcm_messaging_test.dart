// test/core/platform/fcm_messaging_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:taler_id_mobile/core/platform/fcm_messaging.dart';
import 'package:taler_id_mobile/core/platform/fcm_messaging_desktop.dart';

void main() {
  setUp(() => FcmMessagingPlatform.debugResetForTest());
  tearDown(() => FcmMessagingPlatform.debugResetForTest());

  group('FcmMessagingDesktop (fully no-op)', () {
    late FcmMessagingDesktop f;

    setUp(() => f = FcmMessagingDesktop());

    test('initialize completes without error', () async {
      await expectLater(f.initialize(), completes);
    });

    test('getToken returns null', () async {
      expect(await f.getToken(), isNull);
    });

    test('requestPermissions completes without error', () async {
      await expectLater(f.requestPermissions(), completes);
    });

    test('hasPermission returns false', () async {
      expect(await f.hasPermission(), isFalse);
    });

    test('subscribeToTopic completes without error', () async {
      await expectLater(f.subscribeToTopic('test-topic'), completes);
    });

    test('unsubscribeFromTopic completes without error', () async {
      await expectLater(f.unsubscribeFromTopic('test-topic'), completes);
    });

    test('onTokenRefresh stream is empty', () async {
      expect(await f.onTokenRefresh.toList(), isEmpty);
    });

    test('onMessage stream is empty', () async {
      expect(await f.onMessage.toList(), isEmpty);
    });

    test('onMessageOpenedApp stream is empty', () async {
      expect(await f.onMessageOpenedApp.toList(), isEmpty);
    });

    test('getInitialMessage returns null', () async {
      expect(await f.getInitialMessage(), isNull);
    });
  });

  group('FcmMessagingPlatform singleton', () {
    test('debugResetForTest allows re-creation', () {
      final a = FcmMessagingPlatform.instance;
      FcmMessagingPlatform.debugResetForTest();
      final b = FcmMessagingPlatform.instance;
      expect(a, isNotNull);
      expect(b, isNotNull);
    });

    test('debugInstance overrides the singleton', () async {
      FcmMessagingPlatform.debugInstance = FcmMessagingDesktop();
      expect(await FcmMessagingPlatform.instance.getToken(), isNull);
    });
  });
}

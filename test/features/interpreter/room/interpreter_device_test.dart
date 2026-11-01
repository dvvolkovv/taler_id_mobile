import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taler_id_mobile/features/interpreter/room/interpreter_device.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('taler_id/interpreter_device');

  late List<String> log;
  late List<MethodCall> channelCalls;

  InterpreterDevice makeDevice({
    bool isAndroid = true,
    bool preferSpeakerOutput = true,
  }) {
    return InterpreterDevice(
      channel: channel,
      isAndroid: isAndroid,
      getPreferSpeakerOutput: () {
        log.add('getPreferSpeakerOutput');
        return preferSpeakerOutput;
      },
      setSpeakerphoneOn: (on) async {
        log.add('setSpeakerphoneOn($on)');
      },
      wakelockEnable: () async {
        log.add('wakelockEnable');
      },
      wakelockDisable: () async {
        log.add('wakelockDisable');
      },
    );
  }

  setUp(() {
    log = [];
    channelCalls = [];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      channelCalls.add(call);
      log.add('${call.method}(${call.arguments})');
      return null;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  group('InterpreterDevice.enterConversation', () {
    test(
        'remembers speaker pref, then earpiece, wakelock, foreground in '
        'order (Android) — proximity is not touched', () async {
      final device = makeDevice(isAndroid: true, preferSpeakerOutput: true);
      await device.enterConversation();

      expect(log, [
        'getPreferSpeakerOutput',
        'setSpeakerphoneOn(false)',
        'wakelockEnable',
        'startForeground(null)',
      ]);
      expect(
          channelCalls.map((c) => c.method), isNot(contains('setProximity')));
    });

    test('does not start the Android foreground service on iOS', () async {
      final device = makeDevice(isAndroid: false);
      await device.enterConversation();

      expect(log, [
        'getPreferSpeakerOutput',
        'setSpeakerphoneOn(false)',
        'wakelockEnable',
      ]);
      expect(channelCalls.map((c) => c.method),
          isNot(contains('startForeground')));
    });

    test('calling it twice in a row has no further effect', () async {
      final device = makeDevice();
      await device.enterConversation();
      log.clear();
      channelCalls.clear();
      await device.enterConversation();

      expect(log, isEmpty);
    });
  });

  group('InterpreterDevice.leaveConversation', () {
    test(
        'reverses enterConversation in the opposite order, restoring the '
        'remembered speaker pref (Android)', () async {
      final device = makeDevice(isAndroid: true, preferSpeakerOutput: false);
      await device.enterConversation();
      log.clear();
      channelCalls.clear();

      await device.leaveConversation();

      expect(log, [
        'stopForeground(null)',
        'setProximity(false)',
        'wakelockDisable',
        'setSpeakerphoneOn(false)', // restores the remembered pref
      ]);
    });

    test('is idempotent: leaving without having entered does nothing',
        () async {
      final device = makeDevice();
      await device.leaveConversation();
      expect(log, isEmpty);
      expect(channelCalls, isEmpty);
    });

    test('is idempotent: leaving twice only acts once', () async {
      final device = makeDevice();
      await device.enterConversation();
      log.clear();
      await device.leaveConversation();
      log.clear();
      await device.leaveConversation();
      expect(log, isEmpty);
    });
  });

  group('InterpreterDevice.setNearEarScreenOff', () {
    test('on(true) calls setProximity(true), independent of enterConversation',
        () async {
      final device = makeDevice();
      await device.setNearEarScreenOff(true);

      expect(log, ['setProximity(true)']);
    });

    test('on(false) calls setProximity(false)', () async {
      final device = makeDevice();
      await device.setNearEarScreenOff(false);

      expect(log, ['setProximity(false)']);
    });

    test('can be called without enterConversation ever having run', () async {
      final device = makeDevice();
      await expectLater(device.setNearEarScreenOff(true), completes);
      expect(log, ['setProximity(true)']);
    });
  });

  group('error handling', () {
    test('a channel error during enterConversation does not throw', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        throw PlatformException(code: 'boom', message: 'no proximity sensor');
      });
      final device = makeDevice();

      await expectLater(device.enterConversation(), completes);
    });

    test('a channel error during leaveConversation does not throw', () async {
      final device = makeDevice();
      await device.enterConversation();

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        throw PlatformException(code: 'boom', message: 'gone');
      });

      await expectLater(device.leaveConversation(), completes);
    });

    test('a channel error during setNearEarScreenOff does not throw',
        () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        throw PlatformException(code: 'boom', message: 'no proximity sensor');
      });
      final device = makeDevice();

      await expectLater(device.setNearEarScreenOff(true), completes);
    });

    test(
        'no handler registered at all (MissingPluginException) does not '
        'throw', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
      final device = makeDevice();

      await expectLater(device.enterConversation(), completes);
      await expectLater(device.leaveConversation(), completes);
      await expectLater(device.setNearEarScreenOff(true), completes);
    });
  });
}

// test/core/platform/system_call_bridge_test.dart
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taler_id_mobile/core/platform/system_call_bridge.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  const channel = MethodChannel('taler_id/callkit_audio');
  late List<MethodCall> log;

  setUp(() {
    log = [];
    messenger.setMockMethodCallHandler(channel, (call) async {
      log.add(call);
      return null;
    });
  });

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  test('setManagedCalls sends the uuid list', () async {
    const uuids = [
      '3fa85f64-5717-4562-b3fc-2c963f66afa6',
      '7c9e6679-7425-40de-944b-e07fc1f90ae7',
    ];
    await MethodChannelSystemCallBridge().setManagedCalls(uuids);
    expect(log.single.method, 'setManagedCalls');
    expect(log.single.arguments, uuids);
  });

  test('prepareCallAudio reaches native', () async {
    await MethodChannelSystemCallBridge().prepareCallAudio();
    expect(log.single.method, 'prepareCallAudio');
  });

  test('otherCallsEnded from native reaches the stream', () async {
    final bridge = MethodChannelSystemCallBridge();
    final got = bridge.otherCallsEnded.first;
    await messenger.handlePlatformMessage(
      channel.name,
      const StandardMethodCodec().encodeMethodCall(const MethodCall('otherCallsEnded')),
      (_) {},
    );
    await expectLater(got.timeout(const Duration(seconds: 2)), completes);
  });

  test('an unrecognized native call does not reach the stream and is rejected', () async {
    final bridge = MethodChannelSystemCallBridge();
    var received = 0;
    final subscription = bridge.otherCallsEnded.listen((_) => received++);

    var replied = false;
    ByteData? reply;
    await messenger.handlePlatformMessage(
      channel.name,
      const StandardMethodCodec().encodeMethodCall(const MethodCall('somethingElse')),
      (data) {
        replied = true;
        reply = data;
      },
    );
    await pumpEventQueue();

    expect(received, 0);
    expect(replied, isTrue);
    // MissingPluginException -> the platform reply envelope is null ("not implemented").
    expect(reply, isNull);

    await subscription.cancel();
  });

  test('a second instance does not take the stream away from the first', () async {
    final first = MethodChannelSystemCallBridge();
    final firstGot = first.otherCallsEnded.first;
    MethodChannelSystemCallBridge(); // also installs a handler; must not replace the first's

    await messenger.handlePlatformMessage(
      channel.name,
      const StandardMethodCodec().encodeMethodCall(const MethodCall('otherCallsEnded')),
      (_) {},
    );

    await expectLater(firstGot.timeout(const Duration(seconds: 2)), completes);
  });
}

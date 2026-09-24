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
    await MethodChannelSystemCallBridge().setManagedCalls(['a', 'b']);
    expect(log.single.method, 'setManagedCalls');
    expect(log.single.arguments, ['a', 'b']);
  });

  test('prepareCallAudio reaches native', () async {
    await MethodChannelSystemCallBridge().prepareCallAudio();
    expect(log.single.method, 'prepareCallAudio');
  });

  test('otherCallsEnded from native reaches the stream', () async {
    final bridge = MethodChannelSystemCallBridge();
    final got = bridge.otherCallsEnded.first;
    await messenger.handlePlatformMessage(
      'taler_id/callkit_audio',
      const StandardMethodCodec().encodeMethodCall(const MethodCall('otherCallsEnded')),
      (_) {},
    );
    await expectLater(got, completes);
  });
}

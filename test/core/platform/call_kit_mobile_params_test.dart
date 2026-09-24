// test/core/platform/call_kit_mobile_params_test.dart
//
// The iOS call settings are the heart of the CallKit work: a call that can't
// be held gets no "Hold & Accept", and a plugin that configures the audio
// session itself fights CallKit for it.
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taler_id_mobile/core/platform/call_kit_mobile.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  const method = MethodChannel('flutter_callkit_incoming');
  const events = EventChannel('flutter_callkit_incoming_events');
  late List<MethodCall> log;

  // UUID-shaped: the iOS plugin force-unwraps CallKitParams.id as a UUID
  // (CallManager.swift, startCall), so a non-UUID id crashes the app for
  // real — these ids shouldn't model something that would.
  const u1 = '11111111-1111-4111-8111-111111111111';
  const u2 = '22222222-2222-4222-8222-222222222222';
  const u3 = '33333333-3333-4333-8333-333333333333';

  setUp(() {
    log = [];
    messenger.setMockMethodCallHandler(method, (call) async {
      log.add(call);
      return true;
    });
    messenger.setMockStreamHandler(
        events, MockStreamHandler.inline(onListen: (_, __) {}));
  });

  tearDown(() {
    messenger.setMockMethodCallHandler(method, null);
    messenger.setMockStreamHandler(events, null);
  });

  Map<String, dynamic> iosOf(MethodCall call) => Map<String, dynamic>.from(
      (Map<String, dynamic>.from(call.arguments as Map))['ios'] as Map);

  void expectCallKitOwnsTheSession(Map<String, dynamic> ios) {
    expect(ios['supportsHolding'], isTrue);
    expect(ios['configureAudioSession'], isFalse);
    expect(ios['audioSessionMode'], 'voiceChat');
  }

  test('startCall registers a holdable call and leaves the session alone', () async {
    await CallKitMobile().startCall(
        uuid: u1, callerName: 'Alice', handle: 'conv-1', extra: {'roomName': 'r1'});
    final call = log.singleWhere((c) => c.method == 'startCall');
    final args = Map<String, dynamic>.from(call.arguments as Map);
    expect(args['id'], u1);
    expect(args['nameCaller'], 'Alice');
    expect(args['handle'], 'conv-1');
    expect(Map<String, dynamic>.from(args['extra'] as Map)['roomName'], 'r1');
    expectCallKitOwnsTheSession(iosOf(call));
  });

  test('incoming calls use the same iOS settings', () async {
    await CallKitMobile().showIncomingCall(uuid: u2, callerName: 'Bob', roomName: 'r2');
    expectCallKitOwnsTheSession(
        iosOf(log.singleWhere((c) => c.method == 'showCallkitIncoming')));
  });

  test('connect, hold and mute go to the plugin with the call id', () async {
    final kit = CallKitMobile();
    await kit.setCallConnected(u3);
    await kit.setHeld(u3, false); // plugin default is true
    await kit.setMuted(u3, false); // plugin default is true
    expect(log.map((c) => c.method), ['callConnected', 'holdCall', 'muteCall']);
    expect(log[0].arguments, {'id': u3});
    expect(log[1].arguments, {'id': u3, 'isOnHold': false});
    expect(log[2].arguments, {'id': u3, 'isMuted': false});
  });
}

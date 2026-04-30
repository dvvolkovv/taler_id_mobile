import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taler_id_mobile/core/mesh/transport/peer_id.dart';
import 'package:taler_id_mobile/core/mesh/voice/mesh_voice_state.dart';
import 'package:taler_id_mobile/core/voice/mesh_voice_ui_coordinator.dart';
import 'package:taler_id_mobile/features/call_history/data/mesh_call_history_entry.dart';
import 'package:taler_id_mobile/features/call_history/data/mesh_call_history_repository.dart';

class _FakeRepo implements MeshCallHistoryRepository {
  @override Future<void> add(MeshCallHistoryEntry e) async {}
  @override Future<void> deleteById(int callId) async {}
  @override Future<List<MeshCallHistoryEntry>> getAll() async => [];
  @override Stream<List<MeshCallHistoryEntry>> watch() => const Stream.empty();
}

class _SpyNavigator implements MeshNavigator {
  Widget? lastSheet;
  bool sheetShown = false;
  @override Future<T?> pushScreen<T>(Widget s) async => null;
  @override Future<void> showSheet(Widget s) async {
    sheetShown = true;
    lastSheet = s;
  }
  @override void popSheet() {}
  @override void popScreen() {}
  @override void showSnackbar(String m) {}
}

PeerId _peer(int seed) =>
    PeerId(Uint8List.fromList(List<int>.generate(32, (i) => i + seed)));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late StreamController<CallState> stateCtrl;
  late _SpyNavigator nav;
  late List<MethodCall> callkitCalls;
  late MeshVoiceUiCoordinator coord;

  setUp(() {
    stateCtrl = StreamController<CallState>.broadcast();
    nav = _SpyNavigator();
    callkitCalls = [];

    const callkitCh = MethodChannel('flutter_callkit_incoming');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(callkitCh, (call) async {
      callkitCalls.add(call);
      return null;
    });

    coord = MeshVoiceUiCoordinator(
      stateStream: stateCtrl.stream,
      invite: (_) async => 1,
      accept: () async {},
      reject: () async {},
      hangup: () async {},
      repo: _FakeRepo(),
      navigator: nav,
      peerInfoLookup: (_) async =>
          const MeshPeerInfo(name: 'Alice', userId: 'u1'),
      selfDevicePk: _peer(0),
      transportLabelForPeer: (_) => null,
    );
  });

  tearDown(() async {
    await coord.dispose();
    await stateCtrl.close();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('flutter_callkit_incoming'), null);
  });

  group('MeshVoiceUiCoordinator background incoming', () {
    test('AppLifecycleState.resumed → showSheet (existing path, regression)',
        () async {
      coord.debugLifecycleState = AppLifecycleState.resumed;
      coord.debugIsAndroid = true;
      coord.start();
      stateCtrl.add(IncomingState(
          callerDevicePk: _peer(7),
          callId: 0xABCD,
          receivedAt: DateTime.utc(2026)));
      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(nav.sheetShown, isTrue);
      expect(callkitCalls.where((c) => c.method == 'showCallkitIncoming'),
          isEmpty);
    });

    test('AppLifecycleState.paused → showCallkitIncoming with mesh extras',
        () async {
      coord.debugLifecycleState = AppLifecycleState.paused;
      coord.debugIsAndroid = true;
      coord.start();
      stateCtrl.add(IncomingState(
          callerDevicePk: _peer(7),
          callId: 0xABCD,
          receivedAt: DateTime.utc(2026)));
      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(nav.sheetShown, isFalse);
      final showCall = callkitCalls.firstWhere(
          (c) => c.method == 'showCallkitIncoming',
          orElse: () => throw StateError('showCallkitIncoming not called'));
      final args = showCall.arguments as Map?;
      expect(args?['id'], 0xABCD.toString());
      expect(args?['nameCaller'], 'Alice');
      expect(args?['extra']?['mesh_call_id'], 0xABCD);
    });

    test('EndedState dismisses callkit overlay via endCall', () async {
      coord.debugLifecycleState = AppLifecycleState.paused;
      coord.debugIsAndroid = true;
      coord.start();
      stateCtrl.add(IncomingState(
          callerDevicePk: _peer(7),
          callId: 0xCAFE,
          receivedAt: DateTime.utc(2026)));
      await Future<void>.delayed(const Duration(milliseconds: 30));
      callkitCalls.clear();
      stateCtrl.add(EndedState(callId: 0xCAFE, reason: EndReason.userHangup));
      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(callkitCalls.where((c) => c.method == 'endCall'), hasLength(1));
    });
  });
}

import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taler_id_mobile/core/voice/mesh_foreground_controller.dart';
import 'package:taler_id_mobile/core/voice/mesh_peer_eligibility_watcher.dart';

class _FakeWatcher implements MeshPeerEligibilityWatcher {
  bool _hasPeer = false;
  int _count = 0;
  final _ctrl = StreamController<({String userId, bool isOnline})>.broadcast();

  void emitOnline(String userId) {
    _hasPeer = true;
    _count = 1;
    _ctrl.add((userId: userId, isOnline: true));
  }
  void emitOffline(String userId) {
    _hasPeer = false;
    _count = 0;
    _ctrl.add((userId: userId, isOnline: false));
  }

  @override Stream<({String userId, bool isOnline})> get userChanges => _ctrl.stream;
  @override bool isUserOnline(String userId) => _hasPeer;
  @override bool get hasAnyOnlinePeer => _hasPeer;
  @override int get onlinePeerCount => _count;
  @override void start() {}
  @override Future<void> dispose() async => _ctrl.close();
  @override
  noSuchMethod(Invocation i) => throw UnimplementedError(i.memberName.toString());
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeWatcher fake;
  late MeshForegroundController controller;
  late List<MethodCall> calls;

  setUp(() {
    fake = _FakeWatcher();
    calls = [];
    const channel = MethodChannel('taler_id/mesh_fg_service');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return null;
    });
    controller = MeshForegroundController(watcher: fake);
  });

  tearDown(() async {
    await controller.dispose();
    await fake.dispose();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('taler_id/mesh_fg_service'), null);
  });

  group('MeshForegroundController', () {
    test('start() with no peer online — no platform call', () async {
      controller.start();
      await Future<void>.delayed(Duration.zero);
      expect(calls, isEmpty);
    });

    test('PeerDiscovered triggers start MethodCall once', () async {
      controller.start();
      fake.emitOnline('u1');
      await Future<void>.delayed(Duration.zero);
      expect(calls.where((c) => c.method == 'start'), hasLength(1));
      expect(calls.first.arguments, {'peerCount': 1});
    });

    test('PeerLost arms 5-min Timer; stop NOT called immediately', () async {
      controller.start();
      fake.emitOnline('u1');
      await Future<void>.delayed(Duration.zero);
      calls.clear();
      fake.emitOffline('u1');
      await Future<void>.delayed(Duration.zero);
      expect(calls, isEmpty);
    });

    test('grace expires → stop called', () {
      fakeAsync((async) {
        controller.start();
        fake.emitOnline('u1');
        async.elapse(const Duration(milliseconds: 1));
        calls.clear();
        fake.emitOffline('u1');
        async.elapse(const Duration(minutes: 5, seconds: 1));
        expect(calls.where((c) => c.method == 'stop'), hasLength(1));
      });
    });

    test('peer returns within grace → Timer cancelled, no stop', () {
      fakeAsync((async) {
        controller.start();
        fake.emitOnline('u1');
        async.elapse(const Duration(milliseconds: 1));
        calls.clear();
        fake.emitOffline('u1');
        async.elapse(const Duration(minutes: 2));
        fake.emitOnline('u1');
        async.elapse(const Duration(minutes: 10));
        expect(calls.where((c) => c.method == 'stop'), isEmpty);
      });
    });

    test('idempotent start: two emissions do not double-call platform start',
        () async {
      controller.start();
      fake.emitOnline('u1');
      fake.emitOnline('u1');
      await Future<void>.delayed(Duration.zero);
      expect(calls.where((c) => c.method == 'start'), hasLength(1));
    });

    test('dispose() cancels subscription and stops running service', () async {
      controller.start();
      fake.emitOnline('u1');
      await Future<void>.delayed(Duration.zero);
      calls.clear();
      await controller.dispose();
      expect(calls.where((c) => c.method == 'stop'), hasLength(1));
    });
  });
}

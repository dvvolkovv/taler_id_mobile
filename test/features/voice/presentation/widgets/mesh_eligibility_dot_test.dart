import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:taler_id_mobile/core/voice/mesh_peer_eligibility_watcher.dart';
import 'package:taler_id_mobile/features/voice/presentation/widgets/mesh_eligibility_dot.dart';

class _FakeWatcher implements MeshPeerEligibilityWatcher {
  bool initial = false;
  final _ctrl = StreamController<({String userId, bool isOnline})>.broadcast();
  void emit(String userId, bool isOnline) =>
      _ctrl.add((userId: userId, isOnline: isOnline));

  @override
  Stream<({String userId, bool isOnline})> get userChanges => _ctrl.stream;
  @override
  bool isUserOnline(String userId) => initial;
  @override
  void start() {}
  @override
  Future<void> dispose() async => _ctrl.close();
  @override
  noSuchMethod(Invocation i) => throw UnimplementedError(i.memberName.toString());
}

void main() {
  late _FakeWatcher fake;

  setUp(() {
    fake = _FakeWatcher();
    GetIt.I.registerSingleton<MeshPeerEligibilityWatcher>(fake);
  });

  tearDown(() async {
    await fake.dispose();
    await GetIt.I.unregister<MeshPeerEligibilityWatcher>();
  });

  group('MeshEligibilityDot', () {
    testWidgets('renders SizedBox.shrink when offline', (tester) async {
      fake.initial = false;
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: MeshEligibilityDot(userId: 'u1')),
      ));
      expect(find.byKey(const Key('mesh-eligibility-dot')), findsNothing);
    });

    testWidgets('renders dot when initially online', (tester) async {
      fake.initial = true;
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: MeshEligibilityDot(userId: 'u1')),
      ));
      expect(find.byKey(const Key('mesh-eligibility-dot')), findsOneWidget);
    });

    testWidgets('updates render when watcher emits change', (tester) async {
      fake.initial = false;
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: MeshEligibilityDot(userId: 'u1')),
      ));
      expect(find.byKey(const Key('mesh-eligibility-dot')), findsNothing);
      fake.emit('u1', true);
      await tester.pump();
      expect(find.byKey(const Key('mesh-eligibility-dot')), findsOneWidget);
      fake.emit('u1', false);
      await tester.pump();
      expect(find.byKey(const Key('mesh-eligibility-dot')), findsNothing);
    });

    testWidgets('ignores changes for other userIds', (tester) async {
      fake.initial = false;
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: MeshEligibilityDot(userId: 'u1')),
      ));
      fake.emit('u2', true);
      await tester.pump();
      expect(find.byKey(const Key('mesh-eligibility-dot')), findsNothing);
    });
  });
}

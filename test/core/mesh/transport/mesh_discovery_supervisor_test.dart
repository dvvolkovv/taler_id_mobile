import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter/widgets.dart' show AppLifecycleState;
import 'package:flutter_test/flutter_test.dart';
import 'package:taler_id_mobile/core/mesh/transport/mesh_discovery_supervisor.dart';

void main() {
  group('MeshDiscoverySupervisor cold-start watchdog', () {
    test('fires reinit after coldStartDelay if no events observed', () {
      fakeAsync((async) {
        final reinitCalls = <String>[];
        final supervisor = MeshDiscoverySupervisor(
          reinit: (reason) async => reinitCalls.add(reason),
          coldStartDelay: const Duration(seconds: 5),
          maxColdStartAttempts: 3,
        );

        supervisor.onDiscoveryStarted();
        async.elapse(const Duration(seconds: 4));
        expect(reinitCalls, isEmpty,
            reason: 'too early — watchdog must wait full delay');

        async.elapse(const Duration(seconds: 2));
        expect(reinitCalls, ['cold-start']);
      });
    });

    test('does not fire if onDiscoveryEvent observed within delay', () {
      fakeAsync((async) {
        final reinitCalls = <String>[];
        final supervisor = MeshDiscoverySupervisor(
          reinit: (reason) async => reinitCalls.add(reason),
          coldStartDelay: const Duration(seconds: 5),
          maxColdStartAttempts: 3,
        );

        supervisor.onDiscoveryStarted();
        async.elapse(const Duration(seconds: 2));
        supervisor.onDiscoveryEvent();
        async.elapse(const Duration(seconds: 10));
        expect(reinitCalls, isEmpty);
      });
    });

    test('after maxColdStartAttempts kicks, watchdog disarms', () {
      fakeAsync((async) {
        final reinitCalls = <String>[];
        final supervisor = MeshDiscoverySupervisor(
          reinit: (reason) async => reinitCalls.add(reason),
          coldStartDelay: const Duration(seconds: 5),
          maxColdStartAttempts: 3,
        );

        supervisor.onDiscoveryStarted();
        // Walk the exponential schedule: 5s, then 10s, then 15s.
        async.elapse(const Duration(seconds: 5));
        async.elapse(const Duration(seconds: 10));
        async.elapse(const Duration(seconds: 15));
        expect(reinitCalls.length, 3);

        // Further elapse — no fourth kick.
        async.elapse(const Duration(seconds: 60));
        expect(reinitCalls.length, 3);
      });
    });
  });

  group('MeshDiscoverySupervisor connectivity hook', () {
    test('reinit fires when connectivity transitions to wifi', () async {
      final reinitCalls = <String>[];
      final connectivityCtrl =
          StreamController<List<ConnectivityResult>>.broadcast();

      final supervisor = MeshDiscoverySupervisor(
        reinit: (reason) async => reinitCalls.add(reason),
        coldStartDelay: const Duration(seconds: 5),
        maxColdStartAttempts: 3,
        connectivityStream: connectivityCtrl.stream,
      );

      connectivityCtrl.add([ConnectivityResult.none]);
      await Future<void>.delayed(Duration.zero);
      expect(reinitCalls, isEmpty,
          reason: 'no kick when connection drops');

      connectivityCtrl.add([ConnectivityResult.wifi]);
      await Future<void>.delayed(Duration.zero);
      expect(reinitCalls, ['connectivity']);

      await connectivityCtrl.close();
      await supervisor.dispose();
    });
  });

  group('MeshDiscoverySupervisor lifecycle hook', () {
    test('reinit fires on paused → resumed', () async {
      final reinitCalls = <String>[];
      final lifecycleCtrl = StreamController<AppLifecycleState>.broadcast();

      final supervisor = MeshDiscoverySupervisor(
        reinit: (reason) async => reinitCalls.add(reason),
        coldStartDelay: const Duration(seconds: 5),
        maxColdStartAttempts: 3,
        lifecycleStream: lifecycleCtrl.stream,
      );

      lifecycleCtrl.add(AppLifecycleState.paused);
      await Future<void>.delayed(Duration.zero);
      expect(reinitCalls, isEmpty);

      lifecycleCtrl.add(AppLifecycleState.resumed);
      await Future<void>.delayed(Duration.zero);
      expect(reinitCalls, ['resumed']);

      // resumed → resumed (already in foreground) must not refire.
      lifecycleCtrl.add(AppLifecycleState.resumed);
      await Future<void>.delayed(Duration.zero);
      expect(reinitCalls.length, 1);

      await lifecycleCtrl.close();
      await supervisor.dispose();
    });
  });
}

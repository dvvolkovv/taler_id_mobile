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

    test('after maxColdStartAttempts kicks, watchdog keeps retrying at cap', () {
      fakeAsync((async) {
        final reinitCalls = <String>[];
        final supervisor = MeshDiscoverySupervisor(
          reinit: (reason) async => reinitCalls.add(reason),
          coldStartDelay: const Duration(seconds: 5),
          maxColdStartAttempts: 3,
        );

        supervisor.onDiscoveryStarted();
        // Linear ramp for the first three attempts: 5s, 10s, 15s.
        async.elapse(const Duration(seconds: 5));
        async.elapse(const Duration(seconds: 10));
        async.elapse(const Duration(seconds: 15));
        expect(reinitCalls.length, 3);

        // 1.0.69 fix: after the ramp, watchdog must keep retrying with the
        // delay capped at 30s. iOS Bonsoir sometimes recovers only after
        // many minutes; we must not silently give up.
        // attempt=4 → 20s, attempt=5 → 25s, attempt=6 → 30s, attempt=7+ → 30s.
        async.elapse(const Duration(seconds: 20));
        expect(reinitCalls.length, 4);
        async.elapse(const Duration(seconds: 25));
        expect(reinitCalls.length, 5);
        async.elapse(const Duration(seconds: 30));
        expect(reinitCalls.length, 6);
        // Further 60s — two more kicks at the 30s cap.
        async.elapse(const Duration(seconds: 60));
        expect(reinitCalls.length, 8);
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
      supervisor.onDiscoveryStarted();

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

    test('connectivity event before onDiscoveryStarted is ignored', () async {
      // Regression: connectivity_plus emits the current state on subscribe.
      // If we react before startAdvertising's _startDiscovery() returns, two
      // concurrent discovery init paths race and one ends up with a null
      // eventStream, breaking the Bonjour transport.
      final reinitCalls = <String>[];
      final connectivityCtrl =
          StreamController<List<ConnectivityResult>>.broadcast();

      final supervisor = MeshDiscoverySupervisor(
        reinit: (reason) async => reinitCalls.add(reason),
        coldStartDelay: const Duration(seconds: 5),
        maxColdStartAttempts: 3,
        connectivityStream: connectivityCtrl.stream,
      );

      // Initial WiFi emission BEFORE discovery has started.
      connectivityCtrl.add([ConnectivityResult.wifi]);
      await Future<void>.delayed(Duration.zero);
      expect(reinitCalls, isEmpty,
          reason: 'must not reinit before host calls onDiscoveryStarted');

      // After discovery is up, subsequent events are honoured.
      supervisor.onDiscoveryStarted();
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
      supervisor.onDiscoveryStarted();

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

  group('MeshDiscoverySupervisor rate-limit', () {
    test('two triggers within rate-limit window collapse to one reinit', () {
      fakeAsync((async) {
        final reinitCalls = <String>[];
        final connectivityCtrl =
            StreamController<List<ConnectivityResult>>.broadcast();
        final lifecycleCtrl = StreamController<AppLifecycleState>.broadcast();

        final supervisor = MeshDiscoverySupervisor(
          reinit: (reason) async => reinitCalls.add(reason),
          coldStartDelay: const Duration(seconds: 5),
          maxColdStartAttempts: 3,
          connectivityStream: connectivityCtrl.stream,
          lifecycleStream: lifecycleCtrl.stream,
          rateLimit: const Duration(seconds: 3),
        );
        supervisor.onDiscoveryStarted();

        connectivityCtrl.add([ConnectivityResult.wifi]);
        async.flushMicrotasks();
        lifecycleCtrl
          ..add(AppLifecycleState.paused)
          ..add(AppLifecycleState.resumed);
        async.flushMicrotasks();

        expect(reinitCalls, ['connectivity']);

        async.elapse(const Duration(seconds: 4));
        connectivityCtrl.add([ConnectivityResult.wifi]);
        async.flushMicrotasks();
        expect(reinitCalls, ['connectivity', 'connectivity']);
      });
    });
  });

  group('MeshDiscoverySupervisor reinitCount', () {
    test('increments on accepted reinit, not on rate-limited skip', () {
      fakeAsync((async) {
        final reinitCalls = <String>[];
        final lifecycleCtrl = StreamController<AppLifecycleState>.broadcast();

        final supervisor = MeshDiscoverySupervisor(
          reinit: (reason) async => reinitCalls.add(reason),
          coldStartDelay: const Duration(seconds: 5),
          maxColdStartAttempts: 3,
          lifecycleStream: lifecycleCtrl.stream,
          rateLimit: const Duration(seconds: 3),
        );
        supervisor.onDiscoveryStarted();

        expect(supervisor.reinitCount, 0);

        // First lifecycle resume — accepted.
        lifecycleCtrl
          ..add(AppLifecycleState.paused)
          ..add(AppLifecycleState.resumed);
        async.flushMicrotasks();
        expect(reinitCalls.length, 1);
        expect(supervisor.reinitCount, 1);

        // Second resume within rate-limit — skipped, counter unchanged.
        lifecycleCtrl
          ..add(AppLifecycleState.paused)
          ..add(AppLifecycleState.resumed);
        async.flushMicrotasks();
        expect(reinitCalls.length, 1);
        expect(supervisor.reinitCount, 1);

        // After rate-limit window — accepted again.
        async.elapse(const Duration(seconds: 4));
        lifecycleCtrl
          ..add(AppLifecycleState.paused)
          ..add(AppLifecycleState.resumed);
        async.flushMicrotasks();
        expect(reinitCalls.length, 2);
        expect(supervisor.reinitCount, 2);
      });
    });
  });
}

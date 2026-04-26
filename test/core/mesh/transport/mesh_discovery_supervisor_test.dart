import 'package:fake_async/fake_async.dart';
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
  });
}

# Mesh Phase 2.1 — Discovery & Handshake Resilience Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make mesh discovery and Noise handshake recover automatically after one-side restart on iOS, removing the bilateral-restart workaround that surfaced during Phase 2 hardware smoke.

**Architecture:** Two independent fixes packaged together. Bug 1 (iOS bonsoir cold-start race) is solved by a new `MeshDiscoverySupervisor` that wraps `BonjourTransport`'s discovery lifecycle with three triggers (cold-start watchdog, connectivity changes, app-lifecycle resume) feeding a single rate-limited reinit. Bug 2 (Noise re-handshake rejection) is solved inside `MeshMessagingService` by accepting `handshake_init` from a peer with cached state, dropping the stale session, anti-thrash jitter on outbound recovery init, and backoff on excessive resets per peer.

**Tech Stack:** Dart/Flutter, `bonsoir` 5.x, `connectivity_plus` (new dep), `WidgetsBindingObserver`, `cryptography` (Noise IK), `fake_async` (test-only timing).

**Spec:** `docs/superpowers/specs/2026-04-26-mesh-phase2-1-discovery-handshake-resilience-design.md`

**Branch:** `feature/mesh-phase2-1-discovery-handshake-resilience` (already created from `dev` at commit `216d47d`).

**File map:**

| File | Role | New / Modified |
|---|---|---|
| `lib/core/mesh/transport/mesh_discovery_supervisor.dart` | Supervisor: watchdog + connectivity + lifecycle → rate-limited reinit | New |
| `lib/core/mesh/transport/bonjour_transport.dart` | Hosts the supervisor; exposes `restartDiscovery()` callback | Modified |
| `lib/core/mesh/services/mesh_messaging_service.dart` | Accept-latest-init + reset + jitter + backoff | Modified |
| `lib/features/mesh/presentation/bloc/mesh_status_bloc.dart` | Observability counters | Modified |
| `pubspec.yaml` | Add `connectivity_plus` dep | Modified |
| `test/core/mesh/transport/mesh_discovery_supervisor_test.dart` | Supervisor unit tests | New |
| `test/core/mesh/services/mesh_messaging_service_handshake_reset_test.dart` | Bug 2 unit tests | New |

---

## Task 1: Add `connectivity_plus` dependency and verify

**Files:**
- Modify: `pubspec.yaml`
- Verify: `pubspec.lock`

- [ ] **Step 1: Add the dependency**

In `pubspec.yaml`, under the `dependencies:` block, after the `bonsoir: ^5.1.10` line, add:

```yaml
  connectivity_plus: ^6.1.0
```

(Aligns with what is already pulled transitively in the iOS Podfile.lock.)

- [ ] **Step 2: Run pub get**

Run: `cd /Users/dmitry/Downloads/taler_id_mesh && flutter pub get`
Expected: `Got dependencies!` and a non-empty diff in `pubspec.lock` containing `connectivity_plus`.

- [ ] **Step 3: Sanity-check import compiles**

Run: `dart analyze lib/ 2>&1 | head`
Expected: no new errors. (Existing analyzer output is the baseline; this task only adds a dep.)

- [ ] **Step 4: Commit**

```bash
git add pubspec.yaml pubspec.lock
git commit -m "mesh(2.1): add connectivity_plus for discovery supervisor"
```

---

## Task 2: `MeshDiscoverySupervisor` — cold-start watchdog (TDD)

**Files:**
- Create: `lib/core/mesh/transport/mesh_discovery_supervisor.dart`
- Create: `test/core/mesh/transport/mesh_discovery_supervisor_test.dart`

The supervisor accepts a `reinit` callback and three event sources (cold-start signals, connectivity changes, lifecycle changes). This task implements only the cold-start watchdog. Subsequent tasks add the other triggers and rate-limit.

- [ ] **Step 1: Write the failing test**

Create `test/core/mesh/transport/mesh_discovery_supervisor_test.dart`:

```dart
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
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `cd /Users/dmitry/Downloads/taler_id_mesh && flutter test test/core/mesh/transport/mesh_discovery_supervisor_test.dart`
Expected: compilation error — `mesh_discovery_supervisor.dart` does not exist.

- [ ] **Step 3: Create minimal supervisor**

Create `lib/core/mesh/transport/mesh_discovery_supervisor.dart`:

```dart
import 'dart:async';

import 'package:flutter/foundation.dart' show debugPrint;

typedef ReinitCallback = Future<void> Function(String reason);

/// Watches a Bonsoir discovery session and forces a `dispose` + `start`
/// cycle when it appears stuck. iOS bonsoir has a cold-start race where
/// `subscribe(eventStream)` happens before `NSNetServiceBrowser` is
/// actually searching, so existing services are missed and the stream
/// stays silent until something else wakes the resolver up. This
/// supervisor kicks discovery back into life via a watchdog timer plus
/// connectivity / lifecycle hooks (added in later tasks).
class MeshDiscoverySupervisor {
  final ReinitCallback reinit;
  final Duration coldStartDelay;
  final int maxColdStartAttempts;

  Timer? _watchdog;
  int _coldStartAttempt = 0;
  bool _eventSeenSinceStart = false;

  MeshDiscoverySupervisor({
    required this.reinit,
    this.coldStartDelay = const Duration(seconds: 5),
    this.maxColdStartAttempts = 3,
  });

  /// Call after subscribing to the discovery event stream.
  void onDiscoveryStarted() {
    _eventSeenSinceStart = false;
    _armWatchdog();
  }

  /// Call on any Bonsoir discovery event (started, found, resolved, lost).
  /// Cancels and disarms the watchdog — discovery is alive.
  void onDiscoveryEvent() {
    _eventSeenSinceStart = true;
    _watchdog?.cancel();
    _watchdog = null;
    _coldStartAttempt = 0;
  }

  void _armWatchdog() {
    _watchdog?.cancel();
    if (_coldStartAttempt >= maxColdStartAttempts) {
      debugPrint(
        '[mesh-discovery-supervisor] cold-start attempts exhausted (max=$maxColdStartAttempts)',
      );
      return;
    }
    _coldStartAttempt += 1;
    final delay = coldStartDelay * _coldStartAttempt; // 5s, 10s, 15s
    _watchdog = Timer(delay, () async {
      if (_eventSeenSinceStart) return;
      debugPrint(
        '[mesh-discovery-supervisor] kick reason=cold-start attempt=$_coldStartAttempt',
      );
      await reinit('cold-start');
      _armWatchdog();
    });
  }

  Future<void> dispose() async {
    _watchdog?.cancel();
    _watchdog = null;
  }
}
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `cd /Users/dmitry/Downloads/taler_id_mesh && flutter test test/core/mesh/transport/mesh_discovery_supervisor_test.dart`
Expected: 2 tests passed.

- [ ] **Step 5: Commit**

```bash
git add lib/core/mesh/transport/mesh_discovery_supervisor.dart \
        test/core/mesh/transport/mesh_discovery_supervisor_test.dart
git commit -m "mesh(2.1): MeshDiscoverySupervisor cold-start watchdog"
```

---

## Task 3: Supervisor — backoff stops after `maxColdStartAttempts` (TDD)

The first task already implemented the attempt counter. Now lock it in with a regression test.

**Files:**
- Modify: `test/core/mesh/transport/mesh_discovery_supervisor_test.dart`

- [ ] **Step 1: Write the failing test**

Append to the `cold-start watchdog` group in `test/core/mesh/transport/mesh_discovery_supervisor_test.dart`:

```dart
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
```

- [ ] **Step 2: Run test to verify it passes already**

Run: `cd /Users/dmitry/Downloads/taler_id_mesh && flutter test test/core/mesh/transport/mesh_discovery_supervisor_test.dart`
Expected: 3 tests passed (the new one validates the backoff cap implemented in Task 2).

- [ ] **Step 3: Commit**

```bash
git add test/core/mesh/transport/mesh_discovery_supervisor_test.dart
git commit -m "mesh(2.1): test cold-start attempts cap"
```

---

## Task 4: Supervisor — connectivity hook (TDD)

**Files:**
- Modify: `lib/core/mesh/transport/mesh_discovery_supervisor.dart`
- Modify: `test/core/mesh/transport/mesh_discovery_supervisor_test.dart`

The supervisor subscribes to a `Stream<List<ConnectivityResult>>`. Any transition where the new state contains `wifi`, `ethernet`, or `mobile` triggers a reinit.

- [ ] **Step 1: Write the failing test**

Append a new group at the bottom of the test file (after the existing closing `}` of the cold-start group, before the outer `}`):

```dart

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
```

Add these imports at the top of the test file:

```dart
import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd /Users/dmitry/Downloads/taler_id_mesh && flutter test test/core/mesh/transport/mesh_discovery_supervisor_test.dart`
Expected: compilation error — `MeshDiscoverySupervisor` constructor does not accept `connectivityStream`.

- [ ] **Step 3: Add connectivity hook to supervisor**

In `lib/core/mesh/transport/mesh_discovery_supervisor.dart`, add the import:

```dart
import 'package:connectivity_plus/connectivity_plus.dart';
```

Replace the class with this version (preserves Task 2/3 behavior, adds the connectivity field + subscription):

```dart
class MeshDiscoverySupervisor {
  final ReinitCallback reinit;
  final Duration coldStartDelay;
  final int maxColdStartAttempts;
  final Stream<List<ConnectivityResult>>? connectivityStream;

  Timer? _watchdog;
  int _coldStartAttempt = 0;
  bool _eventSeenSinceStart = false;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;

  MeshDiscoverySupervisor({
    required this.reinit,
    this.coldStartDelay = const Duration(seconds: 5),
    this.maxColdStartAttempts = 3,
    this.connectivityStream,
  }) {
    final stream = connectivityStream;
    if (stream != null) {
      _connectivitySub = stream.listen(_onConnectivity);
    }
  }

  void onDiscoveryStarted() {
    _eventSeenSinceStart = false;
    _armWatchdog();
  }

  void onDiscoveryEvent() {
    _eventSeenSinceStart = true;
    _watchdog?.cancel();
    _watchdog = null;
    _coldStartAttempt = 0;
  }

  Future<void> _onConnectivity(List<ConnectivityResult> results) async {
    final hasNetwork = results.any((r) =>
        r == ConnectivityResult.wifi ||
        r == ConnectivityResult.ethernet ||
        r == ConnectivityResult.mobile);
    if (!hasNetwork) return;
    debugPrint(
      '[mesh-discovery-supervisor] kick reason=connectivity now=$results',
    );
    await reinit('connectivity');
  }

  void _armWatchdog() {
    _watchdog?.cancel();
    if (_coldStartAttempt >= maxColdStartAttempts) {
      debugPrint(
        '[mesh-discovery-supervisor] cold-start attempts exhausted (max=$maxColdStartAttempts)',
      );
      return;
    }
    _coldStartAttempt += 1;
    final delay = coldStartDelay * _coldStartAttempt;
    _watchdog = Timer(delay, () async {
      if (_eventSeenSinceStart) return;
      debugPrint(
        '[mesh-discovery-supervisor] kick reason=cold-start attempt=$_coldStartAttempt',
      );
      await reinit('cold-start');
      _armWatchdog();
    });
  }

  Future<void> dispose() async {
    _watchdog?.cancel();
    _watchdog = null;
    await _connectivitySub?.cancel();
    _connectivitySub = null;
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd /Users/dmitry/Downloads/taler_id_mesh && flutter test test/core/mesh/transport/mesh_discovery_supervisor_test.dart`
Expected: 4 tests passed.

- [ ] **Step 5: Commit**

```bash
git add lib/core/mesh/transport/mesh_discovery_supervisor.dart \
        test/core/mesh/transport/mesh_discovery_supervisor_test.dart
git commit -m "mesh(2.1): supervisor reacts to connectivity changes"
```

---

## Task 5: Supervisor — lifecycle hook (TDD)

**Files:**
- Modify: `lib/core/mesh/transport/mesh_discovery_supervisor.dart`
- Modify: `test/core/mesh/transport/mesh_discovery_supervisor_test.dart`

The supervisor accepts a `Stream<AppLifecycleState>` (production wires it to a `WidgetsBindingObserver`; tests inject a `StreamController`). On `paused → resumed` transitions, fire reinit.

- [ ] **Step 1: Write the failing test**

Append a new group to the test file (after the connectivity group):

```dart

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
```

Add to imports at the top:

```dart
import 'package:flutter/widgets.dart' show AppLifecycleState;
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd /Users/dmitry/Downloads/taler_id_mesh && flutter test test/core/mesh/transport/mesh_discovery_supervisor_test.dart`
Expected: compilation error — constructor does not accept `lifecycleStream`.

- [ ] **Step 3: Add lifecycle hook**

In `lib/core/mesh/transport/mesh_discovery_supervisor.dart`, add import:

```dart
import 'package:flutter/widgets.dart' show AppLifecycleState;
```

Add field, constructor parameter, subscription, last-state tracker, and handler. The full updated class:

```dart
class MeshDiscoverySupervisor {
  final ReinitCallback reinit;
  final Duration coldStartDelay;
  final int maxColdStartAttempts;
  final Stream<List<ConnectivityResult>>? connectivityStream;
  final Stream<AppLifecycleState>? lifecycleStream;

  Timer? _watchdog;
  int _coldStartAttempt = 0;
  bool _eventSeenSinceStart = false;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  StreamSubscription<AppLifecycleState>? _lifecycleSub;
  AppLifecycleState? _lastLifecycleState;

  MeshDiscoverySupervisor({
    required this.reinit,
    this.coldStartDelay = const Duration(seconds: 5),
    this.maxColdStartAttempts = 3,
    this.connectivityStream,
    this.lifecycleStream,
  }) {
    final cStream = connectivityStream;
    if (cStream != null) _connectivitySub = cStream.listen(_onConnectivity);
    final lStream = lifecycleStream;
    if (lStream != null) _lifecycleSub = lStream.listen(_onLifecycle);
  }

  void onDiscoveryStarted() {
    _eventSeenSinceStart = false;
    _armWatchdog();
  }

  void onDiscoveryEvent() {
    _eventSeenSinceStart = true;
    _watchdog?.cancel();
    _watchdog = null;
    _coldStartAttempt = 0;
  }

  Future<void> _onConnectivity(List<ConnectivityResult> results) async {
    final hasNetwork = results.any((r) =>
        r == ConnectivityResult.wifi ||
        r == ConnectivityResult.ethernet ||
        r == ConnectivityResult.mobile);
    if (!hasNetwork) return;
    debugPrint(
      '[mesh-discovery-supervisor] kick reason=connectivity now=$results',
    );
    await reinit('connectivity');
  }

  Future<void> _onLifecycle(AppLifecycleState state) async {
    final prev = _lastLifecycleState;
    _lastLifecycleState = state;
    final returningFromBackground = state == AppLifecycleState.resumed &&
        (prev == AppLifecycleState.paused ||
            prev == AppLifecycleState.inactive ||
            prev == AppLifecycleState.hidden);
    if (!returningFromBackground) return;
    debugPrint('[mesh-discovery-supervisor] kick reason=resumed prev=$prev');
    await reinit('resumed');
  }

  void _armWatchdog() {
    _watchdog?.cancel();
    if (_coldStartAttempt >= maxColdStartAttempts) {
      debugPrint(
        '[mesh-discovery-supervisor] cold-start attempts exhausted (max=$maxColdStartAttempts)',
      );
      return;
    }
    _coldStartAttempt += 1;
    final delay = coldStartDelay * _coldStartAttempt;
    _watchdog = Timer(delay, () async {
      if (_eventSeenSinceStart) return;
      debugPrint(
        '[mesh-discovery-supervisor] kick reason=cold-start attempt=$_coldStartAttempt',
      );
      await reinit('cold-start');
      _armWatchdog();
    });
  }

  Future<void> dispose() async {
    _watchdog?.cancel();
    _watchdog = null;
    await _connectivitySub?.cancel();
    _connectivitySub = null;
    await _lifecycleSub?.cancel();
    _lifecycleSub = null;
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd /Users/dmitry/Downloads/taler_id_mesh && flutter test test/core/mesh/transport/mesh_discovery_supervisor_test.dart`
Expected: 5 tests passed.

- [ ] **Step 5: Commit**

```bash
git add lib/core/mesh/transport/mesh_discovery_supervisor.dart \
        test/core/mesh/transport/mesh_discovery_supervisor_test.dart
git commit -m "mesh(2.1): supervisor reacts to app-resumed transitions"
```

---

## Task 6: Supervisor — rate-limit reinit (TDD)

**Files:**
- Modify: `lib/core/mesh/transport/mesh_discovery_supervisor.dart`
- Modify: `test/core/mesh/transport/mesh_discovery_supervisor_test.dart`

When triggers fire in rapid succession (resume + connectivity change), only one reinit should run within a 3-second window.

- [ ] **Step 1: Write the failing test**

Append a new group to the test file:

```dart

  group('MeshDiscoverySupervisor rate-limit', () {
    test('two triggers within rate-limit window collapse to one reinit', () {
      fakeAsync((async) {
        final reinitCalls = <String>[];
        final connectivityCtrl =
            StreamController<List<ConnectivityResult>>.broadcast();
        final lifecycleCtrl = StreamController<AppLifecycleState>.broadcast();

        MeshDiscoverySupervisor(
          reinit: (reason) async => reinitCalls.add(reason),
          coldStartDelay: const Duration(seconds: 5),
          maxColdStartAttempts: 3,
          connectivityStream: connectivityCtrl.stream,
          lifecycleStream: lifecycleCtrl.stream,
          rateLimit: const Duration(seconds: 3),
        );

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
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd /Users/dmitry/Downloads/taler_id_mesh && flutter test test/core/mesh/transport/mesh_discovery_supervisor_test.dart`
Expected: compilation error — constructor does not accept `rateLimit`.

- [ ] **Step 3: Add rate-limit**

In `lib/core/mesh/transport/mesh_discovery_supervisor.dart`, add the field, constructor param, and gate the actual `reinit` call. Replace the class:

```dart
class MeshDiscoverySupervisor {
  final ReinitCallback reinit;
  final Duration coldStartDelay;
  final Duration rateLimit;
  final int maxColdStartAttempts;
  final Stream<List<ConnectivityResult>>? connectivityStream;
  final Stream<AppLifecycleState>? lifecycleStream;

  Timer? _watchdog;
  int _coldStartAttempt = 0;
  bool _eventSeenSinceStart = false;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  StreamSubscription<AppLifecycleState>? _lifecycleSub;
  AppLifecycleState? _lastLifecycleState;
  DateTime? _lastReinitAt;

  MeshDiscoverySupervisor({
    required this.reinit,
    this.coldStartDelay = const Duration(seconds: 5),
    this.rateLimit = const Duration(seconds: 3),
    this.maxColdStartAttempts = 3,
    this.connectivityStream,
    this.lifecycleStream,
  }) {
    final cStream = connectivityStream;
    if (cStream != null) _connectivitySub = cStream.listen(_onConnectivity);
    final lStream = lifecycleStream;
    if (lStream != null) _lifecycleSub = lStream.listen(_onLifecycle);
  }

  void onDiscoveryStarted() {
    _eventSeenSinceStart = false;
    _armWatchdog();
  }

  void onDiscoveryEvent() {
    _eventSeenSinceStart = true;
    _watchdog?.cancel();
    _watchdog = null;
    _coldStartAttempt = 0;
  }

  Future<void> _gatedReinit(String reason) async {
    final now = DateTime.now();
    final last = _lastReinitAt;
    if (last != null && now.difference(last) < rateLimit) {
      debugPrint(
        '[mesh-discovery-supervisor] reinit skipped — within ${rateLimit.inSeconds}s rate-limit (reason=$reason)',
      );
      return;
    }
    _lastReinitAt = now;
    await reinit(reason);
  }

  Future<void> _onConnectivity(List<ConnectivityResult> results) async {
    final hasNetwork = results.any((r) =>
        r == ConnectivityResult.wifi ||
        r == ConnectivityResult.ethernet ||
        r == ConnectivityResult.mobile);
    if (!hasNetwork) return;
    debugPrint(
      '[mesh-discovery-supervisor] kick reason=connectivity now=$results',
    );
    await _gatedReinit('connectivity');
  }

  Future<void> _onLifecycle(AppLifecycleState state) async {
    final prev = _lastLifecycleState;
    _lastLifecycleState = state;
    final returningFromBackground = state == AppLifecycleState.resumed &&
        (prev == AppLifecycleState.paused ||
            prev == AppLifecycleState.inactive ||
            prev == AppLifecycleState.hidden);
    if (!returningFromBackground) return;
    debugPrint('[mesh-discovery-supervisor] kick reason=resumed prev=$prev');
    await _gatedReinit('resumed');
  }

  void _armWatchdog() {
    _watchdog?.cancel();
    if (_coldStartAttempt >= maxColdStartAttempts) {
      debugPrint(
        '[mesh-discovery-supervisor] cold-start attempts exhausted (max=$maxColdStartAttempts)',
      );
      return;
    }
    _coldStartAttempt += 1;
    final delay = coldStartDelay * _coldStartAttempt;
    _watchdog = Timer(delay, () async {
      if (_eventSeenSinceStart) return;
      debugPrint(
        '[mesh-discovery-supervisor] kick reason=cold-start attempt=$_coldStartAttempt',
      );
      await _gatedReinit('cold-start');
      _armWatchdog();
    });
  }

  Future<void> dispose() async {
    _watchdog?.cancel();
    _watchdog = null;
    await _connectivitySub?.cancel();
    _connectivitySub = null;
    await _lifecycleSub?.cancel();
    _lifecycleSub = null;
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd /Users/dmitry/Downloads/taler_id_mesh && flutter test test/core/mesh/transport/mesh_discovery_supervisor_test.dart`
Expected: 6 tests passed.

- [ ] **Step 5: Commit**

```bash
git add lib/core/mesh/transport/mesh_discovery_supervisor.dart \
        test/core/mesh/transport/mesh_discovery_supervisor_test.dart
git commit -m "mesh(2.1): rate-limit supervisor reinit to 1 per 3s"
```

---

## Task 7: Wire supervisor into `BonjourTransport`

**Files:**
- Modify: `lib/core/mesh/transport/bonjour_transport.dart`

The transport will own a `MeshDiscoverySupervisor` instance, expose a `_restartDiscovery()` method as the reinit callback, and notify the supervisor on each event.

This task does not have an isolated unit test — `BonjourTransport` requires real Bonsoir on a device. Verification is deferred to the Task 12 hardware smoke. The change is mostly mechanical, and supervisor logic is already covered by Task 2–6 unit tests.

- [ ] **Step 1: Add imports and field**

Open `lib/core/mesh/transport/bonjour_transport.dart`. After line 8 (`import 'frame.dart';`), add imports:

```dart
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/widgets.dart' show AppLifecycleState, WidgetsBinding, WidgetsBindingObserver;

import 'mesh_discovery_supervisor.dart';
```

Inside class `BonjourTransport`, after the line `StreamSubscription<BonsoirDiscoveryEvent>? _discoverySub;` (currently line 40), add:

```dart
  MeshDiscoverySupervisor? _supervisor;
  _LifecycleAdapter? _lifecycleAdapter;
  StreamController<AppLifecycleState>? _lifecycleCtrl;
```

- [ ] **Step 2: Add lifecycle adapter helper class**

At the bottom of `lib/core/mesh/transport/bonjour_transport.dart` (after the closing `}` of class `BonjourTransport`), append:

```dart

class _LifecycleAdapter with WidgetsBindingObserver {
  final void Function(AppLifecycleState) onState;
  _LifecycleAdapter(this.onState);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    onState(state);
  }
}
```

- [ ] **Step 3: Refactor discovery start into reusable `_startDiscovery()`**

Replace the body of `startAdvertising` from line 93 (`_discovery = BonsoirDiscovery(type: serviceType);`) through line 114 (the closing of the `_discoverySub = stream.listen(...)` block) with:

```dart
    _lifecycleCtrl = StreamController<AppLifecycleState>.broadcast();
    _lifecycleAdapter = _LifecycleAdapter((state) {
      _lifecycleCtrl?.add(state);
    });
    WidgetsBinding.instance.addObserver(_lifecycleAdapter!);

    _supervisor = MeshDiscoverySupervisor(
      reinit: (reason) async {
        debugPrint('[mesh-bonjour] supervisor reinit reason=$reason');
        await _restartDiscovery();
      },
      connectivityStream: Connectivity().onConnectivityChanged,
      lifecycleStream: _lifecycleCtrl!.stream,
    );

    await _startDiscovery();
```

Then add a new private method right after `startAdvertising` (between current line 115 and the start of `_onBonjourEvent` at line 117):

```dart
  Future<void> _startDiscovery() async {
    await _discoverySub?.cancel();
    _discoverySub = null;
    await _discovery?.stop();

    _discovery = BonsoirDiscovery(type: serviceType);
    await _discovery!.ready;
    await _discovery!.start();
    debugPrint('[mesh-bonjour] discovery started, type=$serviceType');
    final stream = _discovery!.eventStream;
    if (stream == null) {
      debugPrint('[mesh-bonjour] WARNING: discovery.eventStream is null — discovery WILL NOT WORK');
      return;
    }
    debugPrint('[mesh-bonjour] subscribing to discovery eventStream');
    _discoverySub = stream.listen(
      (event) {
        _supervisor?.onDiscoveryEvent();
        _onBonjourEvent(event);
      },
      onError: (Object e) {
        debugPrint('[mesh-bonjour] discovery stream error: $e');
      },
      onDone: () {
        debugPrint('[mesh-bonjour] discovery stream CLOSED');
      },
    );
    _supervisor?.onDiscoveryStarted();
  }

  Future<void> _restartDiscovery() async {
    await _startDiscovery();
  }
```

- [ ] **Step 4: Update `stopAdvertising` to clean up supervisor**

Replace the existing `stopAdvertising` body (currently lines 268–277) with:

```dart
  @override
  Future<void> stopAdvertising() async {
    await _supervisor?.dispose();
    _supervisor = null;
    if (_lifecycleAdapter != null) {
      WidgetsBinding.instance.removeObserver(_lifecycleAdapter!);
      _lifecycleAdapter = null;
    }
    await _lifecycleCtrl?.close();
    _lifecycleCtrl = null;
    await _broadcast?.stop();
    _broadcast = null;
    await _discovery?.stop();
    await _discoverySub?.cancel();
    _discoverySub = null;
    _discovery = null;
    await _server?.close();
    _server = null;
  }
```

- [ ] **Step 5: Verify compilation and existing tests still pass**

Run: `cd /Users/dmitry/Downloads/taler_id_mesh && dart analyze lib/core/mesh/transport/bonjour_transport.dart`
Expected: no errors.

Run: `cd /Users/dmitry/Downloads/taler_id_mesh && flutter test test/core/mesh/`
Expected: all mesh tests pass (no new tests added, but existing transport-adjacent tests must still go green).

- [ ] **Step 6: Commit**

```bash
git add lib/core/mesh/transport/bonjour_transport.dart
git commit -m "mesh(2.1): wire MeshDiscoverySupervisor into BonjourTransport"
```

---

## Task 8: `MeshMessagingService` — `_resetPeerState` helper (TDD)

**Files:**
- Create: `test/core/mesh/services/mesh_messaging_service_handshake_reset_test.dart`
- Modify: `lib/core/mesh/services/mesh_messaging_service.dart`

Adds a private helper that fully clears `_PeerState` for a given peer. Used by the accept-latest-init handler in Task 9. Tested indirectly via the integration scenario.

- [ ] **Step 1: Write the failing test (covers Task 8 + 9 together)**

Create `test/core/mesh/services/mesh_messaging_service_handshake_reset_test.dart`:

```dart
import 'dart:async';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taler_id_mobile/core/mesh/crypto/keys/contact_key_store.dart';
import 'package:taler_id_mobile/core/mesh/services/envelope.dart';
import 'package:taler_id_mobile/core/mesh/services/mesh_messaging_service.dart';
import 'package:taler_id_mobile/core/mesh/transport/frame.dart';
import 'package:taler_id_mobile/core/mesh/transport/mesh_transport.dart';
import 'package:taler_id_mobile/core/mesh/transport/peer_id.dart';

class _FakeTransport implements MeshTransport {
  final _discoveries = StreamController<PeerDiscovered>.broadcast();
  final _losses = StreamController<PeerLost>.broadcast();
  final _inbound = StreamController<InboundFrame>.broadcast();
  _FakeTransport? partner;
  PeerId? selfPeer;

  @override
  Stream<PeerDiscovered> get discoveries => _discoveries.stream;
  @override
  Stream<PeerLost> get losses => _losses.stream;
  @override
  Stream<InboundFrame> get inbound => _inbound.stream;

  @override
  Future<void> startAdvertising(DeviceInfo self) async {
    selfPeer = self.devicePk;
  }

  @override
  Future<void> stopAdvertising() async {}

  @override
  Future<void> connectTo(PeerId peer) async {}

  @override
  Future<void> send(PeerId peer, Uint8List data) async {
    if (partner == null) throw StateError('no partner');
    final frame = Frame.decode(data);
    partner!._inbound.add(InboundFrame(
      srcPeer: selfPeer!,
      type: frame.type,
      bytes: frame.payload,
    ));
  }

  @override
  Future<void> dispose() async {
    await _discoveries.close();
    await _losses.close();
    await _inbound.close();
  }
}

Future<(Uint8List, Uint8List)> _x25519Keys() async {
  final kp = await X25519().newKeyPair();
  final priv = await kp.extractPrivateKeyBytes();
  final pub = await kp.extractPublicKey();
  return (Uint8List.fromList(priv), Uint8List.fromList(pub.bytes));
}

void main() {
  group('MeshMessagingService handshake reset', () {
    test('peer with cached session can re-handshake after restart', () async {
      // Alice and Bob establish a session, exchange a message, then Bob
      // "restarts" (we drop and recreate his service) and re-initiates.
      // Alice's existing session must be replaced cleanly.

      final (alicePriv, alicePub) = await _x25519Keys();
      final (bobPriv, bobPub) = await _x25519Keys();
      final alicePeer = PeerId(alicePub);
      final bobPeer = PeerId(bobPub);

      final aliceStore = ContactKeyStore()
        ..addContact(userPk: bobPeer, devicePks: [bobPeer]);
      final bobStore = ContactKeyStore()
        ..addContact(userPk: alicePeer, devicePks: [alicePeer]);

      final aliceTransport = _FakeTransport();
      var bobTransport = _FakeTransport();
      aliceTransport.partner = bobTransport;
      bobTransport.partner = aliceTransport;

      final alice = MeshMessagingService(
        transport: aliceTransport,
        contactKeyStore: aliceStore,
        myDevicePrivateKey: alicePriv,
        myDevicePublicKey: alicePub,
      );
      var bob = MeshMessagingService(
        transport: bobTransport,
        contactKeyStore: bobStore,
        myDevicePrivateKey: bobPriv,
        myDevicePublicKey: bobPub,
      );
      await alice.start(serviceName: 'alice');
      await bob.start(serviceName: 'bob');

      final firstReceived = bob.inbound.first;
      await alice.sendEnvelope(
        toUserPk: bobPeer,
        envelope: Envelope(
          version: 2,
          type: 'text',
          convId: 'c1',
          clientId: 'm1',
          text: 'hello',
          sentAt: DateTime.parse('2026-04-26T10:00:00Z'),
        ),
      );
      final firstEnv = await firstReceived;
      expect(firstEnv.envelope.text, 'hello');

      // Simulate Bob restart: dispose old, build new with same keys.
      await bob.dispose();
      bobTransport = _FakeTransport();
      aliceTransport.partner = bobTransport;
      bobTransport.partner = aliceTransport;
      bob = MeshMessagingService(
        transport: bobTransport,
        contactKeyStore: bobStore,
        myDevicePrivateKey: bobPriv,
        myDevicePublicKey: bobPub,
      );
      await bob.start(serviceName: 'bob');

      // Bob now sends to Alice. Alice currently has cached session/handshake
      // for Bob; the fix must let her reset and accept the new handshake.
      final aliceReceived = alice.inbound.first;
      await bob.sendEnvelope(
        toUserPk: alicePeer,
        envelope: Envelope(
          version: 2,
          type: 'text',
          convId: 'c1',
          clientId: 'm2',
          text: 'after-restart',
          sentAt: DateTime.parse('2026-04-26T10:00:05Z'),
        ),
      );
      final secondEnv = await aliceReceived
          .timeout(const Duration(seconds: 3));
      expect(secondEnv.envelope.text, 'after-restart');

      await alice.dispose();
      await bob.dispose();
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd /Users/dmitry/Downloads/taler_id_mesh && flutter test test/core/mesh/services/mesh_messaging_service_handshake_reset_test.dart`
Expected: TimeoutException — Alice never receives the post-restart message because her `_onInboundFrame` rejects the new `handshake_init` (`unexpected handshake frame — state.isInitiator=false handshake!=null`).

- [ ] **Step 3: Add `_resetPeerState` helper**

Open `lib/core/mesh/services/mesh_messaging_service.dart`. Inside class `MeshMessagingService`, just before the `Future<void> dispose()` method (currently line 218), add:

```dart
  /// Phase 2.1 — fully clear cached handshake/session for a peer so the
  /// next inbound `handshake_init` from that peer can be processed cleanly.
  /// Called when peer-side restart is detected.
  void _resetPeerState(PeerId devicePk) {
    final state = _peerStates[devicePk];
    if (state == null) return;
    debugPrint('[mesh-handshake] reset peer state pk=${devicePk.toHex().substring(0, 12)}...');
    state.handshake = null;
    state.session = null;
    state.isInitiator = false;
    state.initiating = false;
    state.sessionEstablished = null;
  }
```

- [ ] **Step 4: Verify the helper compiles (no test changes yet)**

Run: `cd /Users/dmitry/Downloads/taler_id_mesh && dart analyze lib/core/mesh/services/mesh_messaging_service.dart`
Expected: no errors. The integration test from Step 1 still fails — it's only resolved by Task 9.

- [ ] **Step 5: Commit**

```bash
git add lib/core/mesh/services/mesh_messaging_service.dart \
        test/core/mesh/services/mesh_messaging_service_handshake_reset_test.dart
git commit -m "mesh(2.1): add _resetPeerState helper + failing reset test"
```

---

## Task 9: Accept latest `handshake_init` from peer with cached state (TDD)

**Files:**
- Modify: `lib/core/mesh/services/mesh_messaging_service.dart`

The `_onInboundFrame` handshake branch currently has three cases: no state (responder start), is-initiator (msg2 receive), and the "unexpected" reject branch. Replace the reject branch with a reset-and-accept path.

- [ ] **Step 1: Update the handshake handler**

Open `lib/core/mesh/services/mesh_messaging_service.dart`. Replace lines 150–182 (the entire `if (frame.type == FrameType.handshake) { ... }` block) with:

```dart
    if (frame.type == FrameType.handshake) {
      // Phase 2.1 — accept-latest-init: if we have any cached handshake or
      // session for this peer and another `handshake_init` arrives, the peer
      // has restarted. Drop our cached state and process the new init from
      // scratch. Detection: a fresh init carries a Noise IK message1, which
      // is always 48 bytes ephemeral_pk + payload (>= 48); responder-side
      // msg2 we'd expect (from line 169 path) only arrives after we've
      // become initiator. So: if state.session != null OR (state.handshake
      // != null AND !state.isInitiator), this is a fresh init.
      final hasCachedSession = state.session != null;
      final hasCachedResponderHandshake =
          state.handshake != null && !state.isInitiator;
      final isFreshInitFromPeer =
          hasCachedSession || hasCachedResponderHandshake;
      if (isFreshInitFromPeer) {
        debugPrint(
          '[mesh-handshake] peer reset detected, dropping cached session pk=${srcDevice.toHex().substring(0, 12)}...',
        );
        _resetPeerState(srcDevice);
      }

      if (state.handshake == null) {
        debugPrint('[mesh-frame] starting RESPONDER handshake');
        // Responder path — we received msg1 from an initiator.
        final responder = await NoiseIKHandshake.startResponder(
          responderStaticPrivateKey: myDevicePrivateKey,
          responderStaticPublicKey: myDevicePublicKey,
          prologue: Uint8List(0),
        );
        state.handshake = responder;
        state.isInitiator = false;
        await responder.readMessage1(frame.bytes);
        final msg2 = await responder.writeMessage2(payload: Uint8List(0));
        final (k1, k2) = responder.finalize();
        // Responder: k1 = recv (initiator→responder), k2 = send (responder→initiator).
        state.session = NoiseSession(sendKey: k2, recvKey: k1);
        state.sessionEstablished?.complete();
        await _sendFrame(srcDevice, FrameType.handshake, msg2);
        debugPrint('[mesh-frame] responder handshake complete, session established');
      } else if (state.isInitiator) {
        debugPrint('[mesh-frame] initiator receiving msg2');
        // Initiator receiving msg2.
        await state.handshake!.readMessage2(frame.bytes);
        final (k1, k2) = state.handshake!.finalize();
        // Initiator: k1 = send (initiator→responder), k2 = recv (responder→initiator).
        state.session = NoiseSession(sendKey: k1, recvKey: k2);
        state.sessionEstablished?.complete();
        debugPrint('[mesh-frame] initiator handshake complete, session established');
      } else {
        debugPrint('[mesh-frame] unexpected handshake frame — state.isInitiator=${state.isInitiator} handshake!=null');
      }
      return;
    }
```

- [ ] **Step 2: Run the reset test from Task 8**

Run: `cd /Users/dmitry/Downloads/taler_id_mesh && flutter test test/core/mesh/services/mesh_messaging_service_handshake_reset_test.dart`
Expected: 1 test passed (Alice receives `after-restart`).

- [ ] **Step 3: Run the full mesh test suite to confirm no regression**

Run: `cd /Users/dmitry/Downloads/taler_id_mesh && flutter test test/core/mesh/`
Expected: all mesh tests pass.

- [ ] **Step 4: Commit**

```bash
git add lib/core/mesh/services/mesh_messaging_service.dart
git commit -m "mesh(2.1): accept latest handshake_init when peer reset detected"
```

---

## Task 10: Anti-thrash jitter on outbound recovery init (TDD)

**Files:**
- Modify: `lib/core/mesh/services/mesh_messaging_service.dart`
- Modify: `test/core/mesh/services/mesh_messaging_service_handshake_reset_test.dart`

When `_initiateHandshake` is called along the recovery path (i.e., we previously had a session/handshake with this peer and are now re-creating one), delay the outbound `handshake_init` by `random(50..200)` ms. If the peer's init arrives within that window, cancel ours and accept theirs.

- [ ] **Step 1: Write the failing test**

Append to the `MeshMessagingService handshake reset` group in the test file:

```dart

    test('anti-thrash jitter cancels pending outbound init when peer init arrives first', () async {
      // Alice has a stale session. Both sides try to re-handshake at once.
      // Alice's outbound init must be cancelled; she becomes responder.

      final (alicePriv, alicePub) = await _x25519Keys();
      final (bobPriv, bobPub) = await _x25519Keys();
      final alicePeer = PeerId(alicePub);
      final bobPeer = PeerId(bobPub);

      final aliceStore = ContactKeyStore()
        ..addContact(userPk: bobPeer, devicePks: [bobPeer]);
      final bobStore = ContactKeyStore()
        ..addContact(userPk: alicePeer, devicePks: [alicePeer]);

      final aliceTransport = _FakeTransport();
      final bobTransport = _FakeTransport();
      aliceTransport.partner = bobTransport;
      bobTransport.partner = aliceTransport;

      final alice = MeshMessagingService(
        transport: aliceTransport,
        contactKeyStore: aliceStore,
        myDevicePrivateKey: alicePriv,
        myDevicePublicKey: alicePub,
        recoveryInitJitter: const Duration(milliseconds: 100),
      );
      final bob = MeshMessagingService(
        transport: bobTransport,
        contactKeyStore: bobStore,
        myDevicePrivateKey: bobPriv,
        myDevicePublicKey: bobPub,
        recoveryInitJitter: Duration.zero,
      );
      await alice.start(serviceName: 'alice');
      await bob.start(serviceName: 'bob');

      // Establish initial session.
      final firstAtBob = bob.inbound.first;
      await alice.sendEnvelope(
        toUserPk: bobPeer,
        envelope: Envelope(
          version: 2,
          type: 'text',
          convId: 'c1',
          clientId: 'm1',
          text: 'hi',
          sentAt: DateTime.parse('2026-04-26T10:00:00Z'),
        ),
      );
      await firstAtBob;

      // Both sides initiate a recovery handshake at "the same time".
      // Alice's call gets jittered by 100ms; Bob's fires immediately.
      // Bob's init should reach Alice before Alice's init goes out.
      final aliceFuture = alice.sendEnvelope(
        toUserPk: bobPeer,
        envelope: Envelope(
          version: 2,
          type: 'text',
          convId: 'c1',
          clientId: 'm-alice',
          text: 'from-alice',
          sentAt: DateTime.parse('2026-04-26T10:00:01Z'),
        ),
      );
      final bobFuture = bob.sendEnvelope(
        toUserPk: alicePeer,
        envelope: Envelope(
          version: 2,
          type: 'text',
          convId: 'c1',
          clientId: 'm-bob',
          text: 'from-bob',
          sentAt: DateTime.parse('2026-04-26T10:00:01Z'),
        ),
      );
      await Future.wait([aliceFuture, bobFuture]);

      await alice.dispose();
      await bob.dispose();
    });
```

(The assertion is implicit: both sends complete without throwing or timing out. Pre-fix this would deadlock or throw because the simultaneous-init path was unhandled.)

- [ ] **Step 2: Run test to verify it fails**

Run: `cd /Users/dmitry/Downloads/taler_id_mesh && flutter test test/core/mesh/services/mesh_messaging_service_handshake_reset_test.dart`
Expected: compilation error — `recoveryInitJitter` is not a constructor parameter.

- [ ] **Step 3: Add jitter parameter and "had session before" tracking**

In `lib/core/mesh/services/mesh_messaging_service.dart`, add a constructor parameter and a per-peer flag.

Replace the constructor and field block (lines 45–62) with:

```dart
class MeshMessagingService {
  final MeshTransport transport;
  final ContactKeyStore contactKeyStore;
  final Uint8List myDevicePrivateKey;
  final Uint8List myDevicePublicKey;

  /// Phase 2.1 — when initiating a handshake along the recovery path
  /// (i.e., we had a session/handshake with this peer that is now stale),
  /// delay the outbound `handshake_init` by `random(0..jitter)` so that
  /// if the peer initiates concurrently, their init has time to arrive
  /// and we become responder instead of racing.
  final Duration recoveryInitJitter;

  final Map<PeerId, _PeerState> _peerStates = {};
  final _inboundCtrl = StreamController<InboundEnvelope>.broadcast();

  StreamSubscription? _frameSub;
  StreamSubscription? _discoverySub;

  MeshMessagingService({
    required this.transport,
    required this.contactKeyStore,
    required this.myDevicePrivateKey,
    required this.myDevicePublicKey,
    this.recoveryInitJitter = const Duration(milliseconds: 200),
  });
```

Inside the `_PeerState` class at the bottom of the file (currently lines 226–237), add a `hadPriorSession` field. Replace the class with:

```dart
class _PeerState {
  NoiseIKHandshake? handshake;
  NoiseSession? session;
  bool isInitiator = false;
  Completer<void>? sessionEstablished;
  /// Phase 1j — guard against parallel handshake init by two rapid
  /// sendEnvelope calls. `putIfAbsent` + null-check on `handshake` is not
  /// enough because `_initiateHandshake` has several awaits before
  /// `state.handshake = ...` lands, leaving a window where a second
  /// sendEnvelope observes `handshake == null` and starts its own.
  bool initiating = false;
  /// Phase 2.1 — set after first successful session, used by
  /// `_initiateHandshake` to decide whether to apply recovery jitter.
  bool hadPriorSession = false;
}
```

- [ ] **Step 4: Mark `hadPriorSession=true` when sessions are established**

In `lib/core/mesh/services/mesh_messaging_service.dart`, find the two places where `state.session = NoiseSession(...)` happens (responder path around line 165 and initiator path around line 175). After each one, add `state.hadPriorSession = true;`. The two relevant lines change as shown:

Responder path (after `state.session = NoiseSession(sendKey: k2, recvKey: k1);`):
```dart
        state.session = NoiseSession(sendKey: k2, recvKey: k1);
        state.hadPriorSession = true;
        state.sessionEstablished?.complete();
```

Initiator path (after `state.session = NoiseSession(sendKey: k1, recvKey: k2);`):
```dart
        state.session = NoiseSession(sendKey: k1, recvKey: k2);
        state.hadPriorSession = true;
        state.sessionEstablished?.complete();
```

- [ ] **Step 5: Apply jitter in `_initiateHandshake`**

In `lib/core/mesh/services/mesh_messaging_service.dart`, replace the existing `_initiateHandshake` method (currently lines 126–137) with:

```dart
  Future<void> _initiateHandshake(PeerId devicePk, _PeerState state) async {
    final isRecovery = state.hadPriorSession;
    if (isRecovery && recoveryInitJitter > Duration.zero) {
      final ms = (recoveryInitJitter.inMilliseconds *
              (0.25 + 0.75 * (DateTime.now().microsecondsSinceEpoch % 1000) /
                  1000.0))
          .round();
      debugPrint('[mesh-handshake] recovery init — jittering ${ms}ms');
      await Future<void>.delayed(Duration(milliseconds: ms));
      // If the peer initiated during the jitter window, our state will now
      // contain their handshake. Bail out — we became responder.
      if (state.handshake != null && !state.isInitiator) {
        debugPrint('[mesh-handshake] recovery init cancelled — peer beat us');
        state.initiating = false;
        return;
      }
    }
    final handshake = await NoiseIKHandshake.startInitiator(
      initiatorStaticPrivateKey: myDevicePrivateKey,
      initiatorStaticPublicKey: myDevicePublicKey,
      responderStaticPublicKey: devicePk.bytes,
      prologue: Uint8List(0),
    );
    state.handshake = handshake;
    state.isInitiator = true;
    final msg1 = await handshake.writeMessage1(payload: Uint8List(0));
    await _sendFrame(devicePk, FrameType.handshake, msg1);
  }
```

- [ ] **Step 6: Run tests**

Run: `cd /Users/dmitry/Downloads/taler_id_mesh && flutter test test/core/mesh/services/mesh_messaging_service_handshake_reset_test.dart`
Expected: 2 tests passed (reset test from Task 9 still green, jitter test from this task green).

Run: `cd /Users/dmitry/Downloads/taler_id_mesh && flutter test test/core/mesh/`
Expected: all mesh tests pass.

- [ ] **Step 7: Commit**

```bash
git add lib/core/mesh/services/mesh_messaging_service.dart \
        test/core/mesh/services/mesh_messaging_service_handshake_reset_test.dart
git commit -m "mesh(2.1): anti-thrash jitter on recovery handshake init"
```

---

## Task 11: Backoff after 5 resets per peer in 60s window (TDD)

**Files:**
- Modify: `lib/core/mesh/services/mesh_messaging_service.dart`
- Modify: `test/core/mesh/services/mesh_messaging_service_handshake_reset_test.dart`

Track recent reset timestamps per peer. If a 6th reset would occur within a 60-second window, suppress the reset and drop the incoming init (peer must wait out the backoff). Counter resets after a 30-second quiet period.

- [ ] **Step 1: Write the failing test**

Append to the test group:

```dart

    test('after 5 resets in 60s, 6th init from same peer is suppressed', () async {
      final (alicePriv, alicePub) = await _x25519Keys();
      final (bobPriv, bobPub) = await _x25519Keys();
      final alicePeer = PeerId(alicePub);
      final bobPeer = PeerId(bobPub);

      final aliceStore = ContactKeyStore()
        ..addContact(userPk: bobPeer, devicePks: [bobPeer]);
      final bobStore = ContactKeyStore()
        ..addContact(userPk: alicePeer, devicePks: [alicePeer]);

      final aliceTransport = _FakeTransport();
      var bobTransport = _FakeTransport();
      aliceTransport.partner = bobTransport;
      bobTransport.partner = aliceTransport;

      final alice = MeshMessagingService(
        transport: aliceTransport,
        contactKeyStore: aliceStore,
        myDevicePrivateKey: alicePriv,
        myDevicePublicKey: alicePub,
        peerResetWindow: const Duration(seconds: 60),
        peerResetThreshold: 5,
      );
      var bob = MeshMessagingService(
        transport: bobTransport,
        contactKeyStore: bobStore,
        myDevicePrivateKey: bobPriv,
        myDevicePublicKey: bobPub,
      );
      await alice.start(serviceName: 'alice');
      await bob.start(serviceName: 'bob');

      Future<void> establishAndRestartBob({required String text}) async {
        final received = bob.inbound.first;
        await alice.sendEnvelope(
          toUserPk: bobPeer,
          envelope: Envelope(
            version: 2,
            type: 'text',
            convId: 'c1',
            clientId: 'm-$text',
            text: text,
            sentAt: DateTime.parse('2026-04-26T10:00:00Z'),
          ),
        );
        await received;
        await bob.dispose();
        bobTransport = _FakeTransport();
        aliceTransport.partner = bobTransport;
        bobTransport.partner = aliceTransport;
        bob = MeshMessagingService(
          transport: bobTransport,
          contactKeyStore: bobStore,
          myDevicePrivateKey: bobPriv,
          myDevicePublicKey: bobPub,
        );
        await bob.start(serviceName: 'bob');
      }

      // Cycles 1–5: alice→bob, then bob restarts → bob→alice succeeds.
      for (var i = 0; i < 5; i++) {
        await establishAndRestartBob(text: 'cycle$i');
        final aliceReceives = alice.inbound.first;
        await bob.sendEnvelope(
          toUserPk: alicePeer,
          envelope: Envelope(
            version: 2,
            type: 'text',
            convId: 'c1',
            clientId: 'b-$i',
            text: 'reply$i',
            sentAt: DateTime.parse('2026-04-26T10:00:01Z'),
          ),
        );
        await aliceReceives.timeout(const Duration(seconds: 3));
      }

      // Cycle 6: bob restarts again. Alice should suppress this reset.
      await establishAndRestartBob(text: 'cycle5');
      final aliceReceivesAfterBackoff = alice.inbound.first
          .timeout(const Duration(milliseconds: 500), onTimeout: () {
        throw TimeoutException('expected — backoff suppresses sixth reset');
      });
      await bob.sendEnvelope(
        toUserPk: alicePeer,
        envelope: Envelope(
          version: 2,
          type: 'text',
          convId: 'c1',
          clientId: 'b-5',
          text: 'reply5',
          sentAt: DateTime.parse('2026-04-26T10:00:01Z'),
        ),
      );
      await expectLater(
        aliceReceivesAfterBackoff,
        throwsA(isA<TimeoutException>()),
      );

      await alice.dispose();
      await bob.dispose();
    });
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd /Users/dmitry/Downloads/taler_id_mesh && flutter test test/core/mesh/services/mesh_messaging_service_handshake_reset_test.dart`
Expected: compilation error — `peerResetWindow` and `peerResetThreshold` not constructor parameters.

- [ ] **Step 3: Add backoff fields and check**

In `lib/core/mesh/services/mesh_messaging_service.dart`, add to the class fields (after `recoveryInitJitter`):

```dart
  /// Phase 2.1 — after this many resets within `peerResetWindow`, further
  /// resets from the same peer are dropped until the window slides past.
  final int peerResetThreshold;
  final Duration peerResetWindow;

  final Map<PeerId, List<DateTime>> _peerResetTimes = {};
```

Update the constructor signature:

```dart
  MeshMessagingService({
    required this.transport,
    required this.contactKeyStore,
    required this.myDevicePrivateKey,
    required this.myDevicePublicKey,
    this.recoveryInitJitter = const Duration(milliseconds: 200),
    this.peerResetThreshold = 5,
    this.peerResetWindow = const Duration(seconds: 60),
  });
```

Add a helper method just before `_resetPeerState` (added in Task 8):

```dart
  /// Returns true if a reset for [devicePk] is allowed; false if the peer
  /// has hit the rate threshold within the current window.
  bool _allowReset(PeerId devicePk) {
    final now = DateTime.now();
    final times = _peerResetTimes.putIfAbsent(devicePk, () => <DateTime>[]);
    times.removeWhere((t) => now.difference(t) > peerResetWindow);
    if (times.length >= peerResetThreshold) {
      debugPrint(
        '[mesh-handshake] reset suppressed — peer pk=${devicePk.toHex().substring(0, 12)}... hit threshold ($peerResetThreshold in ${peerResetWindow.inSeconds}s)',
      );
      return false;
    }
    times.add(now);
    return true;
  }
```

- [ ] **Step 4: Gate the reset path with `_allowReset`**

In `_onInboundFrame` (Task 9 changes), modify the reset block to consult `_allowReset` first. Replace the block from Task 9 starting at:

```dart
      if (isFreshInitFromPeer) {
        debugPrint(
          '[mesh-handshake] peer reset detected, dropping cached session pk=${srcDevice.toHex().substring(0, 12)}...',
        );
        _resetPeerState(srcDevice);
      }
```

with:

```dart
      if (isFreshInitFromPeer) {
        if (!_allowReset(srcDevice)) {
          // Drop the frame entirely — peer is in backoff.
          return;
        }
        debugPrint(
          '[mesh-handshake] peer reset detected, dropping cached session pk=${srcDevice.toHex().substring(0, 12)}...',
        );
        _resetPeerState(srcDevice);
      }
```

- [ ] **Step 5: Run tests**

Run: `cd /Users/dmitry/Downloads/taler_id_mesh && flutter test test/core/mesh/services/mesh_messaging_service_handshake_reset_test.dart`
Expected: 3 tests passed.

Run: `cd /Users/dmitry/Downloads/taler_id_mesh && flutter test test/core/mesh/`
Expected: all mesh tests pass.

- [ ] **Step 6: Commit**

```bash
git add lib/core/mesh/services/mesh_messaging_service.dart \
        test/core/mesh/services/mesh_messaging_service_handshake_reset_test.dart
git commit -m "mesh(2.1): backoff after 5 peer resets in 60s window"
```

---

## Task 12: Final analyze + full test sweep + push

**Files:**
- (none modified — final integration step)

- [ ] **Step 1: Run static analysis**

Run: `cd /Users/dmitry/Downloads/taler_id_mesh && flutter analyze 2>&1 | tail -20`
Expected: no new errors or warnings introduced. Existing baseline (info-level lints) is acceptable; no new entries from `lib/core/mesh/transport/mesh_discovery_supervisor.dart`, `lib/core/mesh/transport/bonjour_transport.dart`, or `lib/core/mesh/services/mesh_messaging_service.dart`.

- [ ] **Step 2: Run the full test suite**

Run: `cd /Users/dmitry/Downloads/taler_id_mesh && flutter test 2>&1 | tail -10`
Expected: `All tests passed!` and the count is 402 + new tests (Task 2: 2; Task 3: 1; Task 4: 1; Task 5: 1; Task 6: 1; Task 8: 1; Task 10: 1; Task 11: 1) = **411** tests total.

If the count differs, check that no test was accidentally deleted. The numeric check is a regression guard, not a hard gate — additions in unrelated tests by other PRs may shift it.

- [ ] **Step 3: Push to origin**

```bash
git push origin feature/mesh-phase2-1-discovery-handshake-resilience
```
Expected: branch up-to-date on `origin`, ready for hardware smoke + PR.

- [ ] **Step 4: Hardware smoke (manual, before PR)**

Run the three scenarios from the spec on Android Redmi + iPhone wired:

1. **Cold-start fix:** With Android already advertising, force-quit and relaunch iPhone app. Within 15 seconds the iPhone log shows `[mesh-discovery-supervisor] kick reason=cold-start attempt=1` and then `discoveryServiceFound` for the Android peer. **Expected:** iPhone sees Android without restarting Android.

2. **Re-handshake fix:** With both apps running and a recent message exchanged, force-quit and relaunch Android. From the restarted Android, send a message to iPhone. iPhone log shows `[mesh-handshake] peer reset detected`. **Expected:** message arrives via mesh; no iPhone restart needed.

3. **Phase 2 regression:** Re-run the existing Phase 2 hardware smoke (group + server, mesh-only, sender clock fix). **Expected:** all three pass identically to before.

If any scenario fails, file a follow-up commit before opening the PR.

- [ ] **Step 5: Open PR (manual)**

Visit https://github.com/dvvolkovv/taler_id_mobile/compare/dev...feature/mesh-phase2-1-discovery-handshake-resilience and open a PR with:

- **Title:** `mesh(2.1): discovery & handshake resilience — fix iOS bonsoir cold-start + Noise re-handshake`
- **Body:**

```markdown
## Summary
- `MeshDiscoverySupervisor` wraps Bonsoir discovery: cold-start watchdog (5/10/15s exponential, 3 attempts), connectivity hook, lifecycle resume hook, single rate-limited reinit (1 per 3s).
- `MeshMessagingService` accepts fresh `handshake_init` from a peer with cached session/handshake — peer-restart recovery without bilateral restart.
- Anti-thrash jitter on outbound recovery init (50–200 ms): if peer's init arrives during the delay, we cancel ours and become responder.
- Backoff: after 5 resets per peer in 60 s, further resets are suppressed until the window slides past.
- New dep: `connectivity_plus`.

## Test plan
- [x] 411 unit tests green (8 new tests across supervisor + handshake reset)
- [x] Hardware: cold-start fix verified on iPhone wired (no Android restart needed)
- [x] Hardware: re-handshake fix verified on Android Redmi → iPhone wired
- [x] Hardware: Phase 2 regression suite re-run, all green
```

---

## Self-review (already run by author)

**Spec coverage:**
- Goal — Bug 1 fix → Tasks 2–7. Bug 2 fix → Tasks 8–11. ✓
- Architecture overview — file map at top of plan matches spec's "Affected files". ✓
- Bug 1 hybrid (cold-start watchdog + connectivity + lifecycle, rate-limited) → Tasks 2, 4, 5, 6. ✓
- Bug 2 (accept latest init + jitter + backoff) → Tasks 8–11. ✓
- Out-of-scope items (group keys, peer auth, UI indicators) — not added; spec respected. ✓
- Testing strategy (unit + 3 hardware scenarios) → Task 12. ✓
- Rollout (feature branch from `dev`, PR, dev soak, then `main`) → headers + Task 12. ✓

**Placeholder scan:** none.

**Type consistency:**
- Constructor parameter names (`coldStartDelay`, `rateLimit`, `maxColdStartAttempts`, `connectivityStream`, `lifecycleStream`, `recoveryInitJitter`, `peerResetThreshold`, `peerResetWindow`) used consistently across Tasks 2–11. ✓
- Method names (`onDiscoveryStarted`, `onDiscoveryEvent`, `_gatedReinit`, `_resetPeerState`, `_allowReset`, `_startDiscovery`, `_restartDiscovery`) consistent. ✓
- The `hadPriorSession` flag is set in two places (responder + initiator session establishment) and read once in `_initiateHandshake`. ✓

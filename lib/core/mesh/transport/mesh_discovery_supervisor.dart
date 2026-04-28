import 'dart:async';

import 'package:clock/clock.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/widgets.dart' show AppLifecycleState;

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
  final Duration rateLimit;
  final int maxColdStartAttempts;
  final Stream<List<ConnectivityResult>>? connectivityStream;
  final Stream<AppLifecycleState>? lifecycleStream;

  Timer? _watchdog;
  int _coldStartAttempt = 0;
  bool _eventSeenSinceStart = false;
  bool _discoveryStartedOnce = false;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  StreamSubscription<AppLifecycleState>? _lifecycleSub;
  AppLifecycleState? _lastLifecycleState;
  DateTime? _lastReinitAt;
  int _reinitCount = 0;

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

  int get reinitCount => _reinitCount;

  void onDiscoveryStarted() {
    _eventSeenSinceStart = false;
    _discoveryStartedOnce = true;
    _armWatchdog();
  }

  void onDiscoveryEvent() {
    _eventSeenSinceStart = true;
    _watchdog?.cancel();
    _watchdog = null;
    _coldStartAttempt = 0;
  }

  Future<void> _gatedReinit(String reason) async {
    final now = clock.now();
    final last = _lastReinitAt;
    if (last != null && now.difference(last) < rateLimit) {
      debugPrint(
        '[mesh-discovery-supervisor] reinit skipped — within ${rateLimit.inSeconds}s rate-limit (reason=$reason)',
      );
      return;
    }
    _lastReinitAt = now;
    _reinitCount++;
    await reinit(reason);
  }

  Future<void> _onConnectivity(List<ConnectivityResult> results) async {
    final hasNetwork = results.any((r) =>
        r == ConnectivityResult.wifi ||
        r == ConnectivityResult.ethernet ||
        r == ConnectivityResult.mobile);
    if (!hasNetwork) return;
    if (!_discoveryStartedOnce) {
      // connectivity_plus emits the current state on subscribe; we must
      // not race the initial startAdvertising path. Wait for the host to
      // finish bringing discovery up before reacting to network events.
      debugPrint(
        '[mesh-discovery-supervisor] connectivity event ignored — discovery not started yet',
      );
      return;
    }
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
    if (!_discoveryStartedOnce) return;
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

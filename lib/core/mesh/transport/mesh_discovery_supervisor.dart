import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
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

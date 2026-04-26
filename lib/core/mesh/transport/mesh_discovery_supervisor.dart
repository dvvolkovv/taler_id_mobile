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

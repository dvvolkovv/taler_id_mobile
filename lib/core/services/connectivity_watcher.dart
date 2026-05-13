import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'outbox_replay_service.dart';

class ConnectivityWatcher {
  final OutboxReplayService _replay;
  final Connectivity _connectivity;
  StreamSubscription<List<ConnectivityResult>>? _sub;
  bool _wasOnline = true;

  ConnectivityWatcher(this._replay, {Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity();

  void start() {
    _sub?.cancel();
    _sub = _connectivity.onConnectivityChanged.listen(_handle);
  }

  Future<void> stop() async {
    await _sub?.cancel();
    _sub = null;
  }

  void _handle(List<ConnectivityResult> results) {
    final online = results.any(
      (r) =>
          r == ConnectivityResult.wifi ||
          r == ConnectivityResult.mobile ||
          r == ConnectivityResult.ethernet,
    );
    if (online && !_wasOnline) {
      debugPrint('[connectivity] online — triggering outbox drain');
      _replay.drain();
    }
    _wasOnline = online;
  }
}

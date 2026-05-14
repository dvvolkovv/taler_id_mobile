import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import '../../domain/repositories/i_presence_repository.dart';

/// Foreground heartbeat: pings `/presence/ping` every 30 s while the app is
/// resumed AND the user is logged in. Cancels itself on backgrounding,
/// logout, or a 401 response.
class PresenceHeartbeatService with WidgetsBindingObserver {
  static const Duration _interval = Duration(seconds: 30);

  final IPresenceRepository _repo;
  Timer? _timer;
  bool _loggedIn = false;
  bool _resumed = true;
  bool _disposed = false;

  PresenceHeartbeatService(this._repo) {
    WidgetsBinding.instance.addObserver(this);
  }

  void setLoggedIn(bool v) {
    _loggedIn = v;
    _evaluate();
  }

  void start() => _evaluate();

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _resumed = state == AppLifecycleState.resumed;
    _evaluate();
  }

  void _evaluate() {
    if (_disposed) return;
    final shouldRun = _loggedIn && _resumed;
    if (shouldRun && _timer == null) {
      unawaited(_ping());
      _timer = Timer.periodic(_interval, (_) => unawaited(_ping()));
    } else if (!shouldRun && _timer != null) {
      stop();
    }
  }

  Future<void> _ping() async {
    try {
      await _repo.ping();
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        _loggedIn = false;
        stop();
      }
    } catch (_) {
      // swallow other transient errors
    }
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    stop();
    WidgetsBinding.instance.removeObserver(this);
  }
}

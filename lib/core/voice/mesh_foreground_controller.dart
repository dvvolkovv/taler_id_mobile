import 'dart:async';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart' show WidgetsBinding;

import '../../features/voice/presentation/widgets/battery_exemption_dialog.dart';
import '../../main.dart' show globalNavigatorKey;
import 'mesh_peer_eligibility_watcher.dart';

/// Anchors the Android process via a foreground Service when at least one
/// mesh peer is reachable. Idle (no peers): service is not running. Has
/// a 5-minute grace period after the last peer disappears.
///
/// Platform gating happens at the bootstrap call site (Platform.isAndroid).
/// In tests TestDefaultBinaryMessengerBinding intercepts MethodChannel calls.
class MeshForegroundController {
  final MeshPeerEligibilityWatcher watcher;
  static const _channel = MethodChannel('taler_id/mesh_fg_service');
  static const _gracePeriod = Duration(minutes: 5);

  StreamSubscription<({String userId, bool isOnline})>? _sub;
  Timer? _stopTimer;
  bool _serviceRunning = false;
  bool _batteryPromptScheduled = false;

  MeshForegroundController({required this.watcher});

  void start() {
    _sub = watcher.userChanges.listen(_onChange);
    if (watcher.hasAnyOnlinePeer) _ensureRunning();
  }

  Future<void> dispose() async {
    await _sub?.cancel();
    _sub = null;
    _stopTimer?.cancel();
    _stopTimer = null;
    if (_serviceRunning) await _stopService();
  }

  void _onChange(({String userId, bool isOnline}) e) {
    if (watcher.hasAnyOnlinePeer) {
      _stopTimer?.cancel();
      _stopTimer = null;
      _ensureRunning();
    } else {
      _scheduleStop();
    }
  }

  void _maybeScheduleBatteryPrompt() {
    if (_batteryPromptScheduled) return;
    _batteryPromptScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final ctx = globalNavigatorKey.currentContext;
      if (ctx == null) return;
      await BatteryExemptionDialog.showIfNeeded(ctx);
    });
  }

  Future<void> _ensureRunning() async {
    if (_serviceRunning) return;
    _serviceRunning = true;
    try {
      await _channel.invokeMethod(
        'start',
        {'peerCount': watcher.onlinePeerCount},
      );
      _maybeScheduleBatteryPrompt();
    } catch (e) {
      _serviceRunning = false;
      debugPrint('[mesh-fg] service start failed: $e');
    }
  }

  void _scheduleStop() {
    _stopTimer?.cancel();
    _stopTimer = Timer(_gracePeriod, _stopService);
  }

  Future<void> _stopService() async {
    if (!_serviceRunning) return;
    _serviceRunning = false;
    try {
      await _channel.invokeMethod('stop');
    } catch (e) {
      debugPrint('[mesh-fg] service stop failed: $e');
    }
  }
}

# Mesh Voice Call Phase 3d.3 — Android Background Incoming Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Backgrounded Android receives full-screen incoming-call overlay for mesh calls, anchored by a foreground Service that runs only while at least one mesh peer is reachable (5-min grace after last peer disappears).

**Architecture:** Native `MeshForegroundService` (Kotlin) anchors process priority via persistent notification. Dart `MeshForegroundController` toggles the service based on `MeshPeerEligibilityWatcher` events. `MeshVoiceUiCoordinator` branches on `AppLifecycleState`: foreground → existing modal sheet, background → `flutter_callkit_incoming`. iOS path skipped via `Platform.isAndroid` guard.

**Tech Stack:** Flutter 3.38, Dart 3.6, Kotlin (Android Service), `flutter_callkit_incoming` 2.0.2, `permission_handler` 11.3.1, existing mesh stack.

**Spec:** [docs/superpowers/specs/2026-04-30-mesh-voice-call-phase3d3-design.md](../specs/2026-04-30-mesh-voice-call-phase3d3-design.md)

---

## Pre-flight

### Task 0: Branch + clean baseline

**Files:** working tree only.

- [ ] **Step 1: Create feature branch from `dev`**

```bash
cd ~/Downloads/taler_id_mobile
git fetch origin
git checkout -b feature/mesh-voice-call-phase3d.3 origin/dev
```

Expected: `Switched to a new branch 'feature/mesh-voice-call-phase3d.3'`. Tip should be at `b467a19` (3d.3 spec) or later.

- [ ] **Step 2: Verify baseline tests pass**

Run: `flutter test`
Expected: 543+ pass, 0 fail.

- [ ] **Step 3: Verify analyze**

Run: `flutter analyze`
Expected: pre-existing infos only, 0 errors.

---

## Foundation

### Task 1: Extend `MeshPeerEligibilityWatcher` with hasAnyOnlinePeer + onlinePeerCount

**Files:**
- Modify: `lib/core/voice/mesh_peer_eligibility_watcher.dart`
- Modify: `test/core/voice/mesh_peer_eligibility_watcher_test.dart`

The controller (Task 2) needs O(1) checks "is there any peer online" and "how many online" for the persistent notification text.

- [ ] **Step 1: Append failing tests**

Append to `test/core/voice/mesh_peer_eligibility_watcher_test.dart`, inside the existing `main()`:

```dart
group('MeshPeerEligibilityWatcher.hasAnyOnlinePeer', () {
  test('false when no peer online', () {
    watcher.start();
    expect(watcher.hasAnyOnlinePeer, isFalse);
    expect(watcher.onlinePeerCount, 0);
  });

  test('true after first PeerDiscovered', () async {
    watcher.start();
    transport.disc.add(PeerDiscovered(peerId: aliceDevice1, host: 'h', port: 1, attributes: {}));
    await Future<void>.delayed(Duration.zero);
    expect(watcher.hasAnyOnlinePeer, isTrue);
    expect(watcher.onlinePeerCount, 1);
  });

  test('counts distinct userIds, not devices', () async {
    watcher.start();
    transport.disc.add(PeerDiscovered(peerId: aliceDevice1, host: 'h', port: 1, attributes: {}));
    transport.disc.add(PeerDiscovered(peerId: aliceDevice2, host: 'h', port: 1, attributes: {}));
    await Future<void>.delayed(Duration.zero);
    expect(watcher.onlinePeerCount, 1, reason: 'two devices, one userId');
  });
});
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/core/voice/mesh_peer_eligibility_watcher_test.dart`
Expected: 3 failures — getters not defined.

- [ ] **Step 3: Implement getters**

In `lib/core/voice/mesh_peer_eligibility_watcher.dart`, add inside `MeshPeerEligibilityWatcher`:

```dart
bool get hasAnyOnlinePeer => _onlineDevices.isNotEmpty;
int get onlinePeerCount => _onlineDevices.length;
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test test/core/voice/mesh_peer_eligibility_watcher_test.dart`
Expected: `+11: All tests passed!` (8 prior + 3 new).

- [ ] **Step 5: Run full suite**

Run: `flutter test`
Expected: 546 pass (543 baseline + 3 new).

- [ ] **Step 6: Commit**

```bash
git add lib/core/voice/mesh_peer_eligibility_watcher.dart \
        test/core/voice/mesh_peer_eligibility_watcher_test.dart
git commit -m "feat(mesh-voice/3d.3): MeshPeerEligibilityWatcher hasAnyOnlinePeer + onlinePeerCount"
```

---

### Task 2: `MeshForegroundController` (Dart)

**Files:**
- Create: `lib/core/voice/mesh_foreground_controller.dart`
- Test: `test/core/voice/mesh_foreground_controller_test.dart`

Singleton that translates `MeshPeerEligibilityWatcher.userChanges` events into `MethodChannel` calls to start/stop the native foreground service. 5-minute grace period after last peer disappears.

- [ ] **Step 1: Write failing tests**

Create `test/core/voice/mesh_foreground_controller_test.dart`:

```dart
import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taler_id_mobile/core/voice/mesh_foreground_controller.dart';
import 'package:taler_id_mobile/core/voice/mesh_peer_eligibility_watcher.dart';

class _FakeWatcher implements MeshPeerEligibilityWatcher {
  bool _hasPeer = false;
  int _count = 0;
  final _ctrl = StreamController<({String userId, bool isOnline})>.broadcast();

  void emitOnline(String userId) {
    _hasPeer = true;
    _count = 1;
    _ctrl.add((userId: userId, isOnline: true));
  }
  void emitOffline(String userId) {
    _hasPeer = false;
    _count = 0;
    _ctrl.add((userId: userId, isOnline: false));
  }

  @override Stream<({String userId, bool isOnline})> get userChanges => _ctrl.stream;
  @override bool isUserOnline(String userId) => _hasPeer;
  @override bool get hasAnyOnlinePeer => _hasPeer;
  @override int get onlinePeerCount => _count;
  @override void start() {}
  @override Future<void> dispose() async => _ctrl.close();
  @override
  noSuchMethod(Invocation i) => throw UnimplementedError(i.memberName.toString());
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeWatcher fake;
  late MeshForegroundController controller;
  late List<MethodCall> calls;

  setUp(() {
    fake = _FakeWatcher();
    calls = [];
    const channel = MethodChannel('taler_id/mesh_fg_service');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return null;
    });
    controller = MeshForegroundController(watcher: fake);
  });

  tearDown(() async {
    await controller.dispose();
    await fake.dispose();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('taler_id/mesh_fg_service'), null);
  });

  group('MeshForegroundController', () {
    test('start() with no peer online — no platform call', () async {
      controller.start();
      await Future<void>.delayed(Duration.zero);
      expect(calls, isEmpty);
    });

    test('PeerDiscovered triggers start MethodCall once', () async {
      controller.start();
      fake.emitOnline('u1');
      await Future<void>.delayed(Duration.zero);
      expect(calls.where((c) => c.method == 'start'), hasLength(1));
      expect(calls.first.arguments, {'peerCount': 1});
    });

    test('PeerLost arms 5-min Timer; stop NOT called immediately', () async {
      controller.start();
      fake.emitOnline('u1');
      await Future<void>.delayed(Duration.zero);
      calls.clear();
      fake.emitOffline('u1');
      await Future<void>.delayed(Duration.zero);
      expect(calls, isEmpty);
    });

    test('grace expires → stop called', () {
      fakeAsync((async) {
        controller.start();
        fake.emitOnline('u1');
        async.elapse(const Duration(milliseconds: 1));
        calls.clear();
        fake.emitOffline('u1');
        async.elapse(const Duration(minutes: 5, seconds: 1));
        expect(calls.where((c) => c.method == 'stop'), hasLength(1));
      });
    });

    test('peer returns within grace → Timer cancelled, no stop', () {
      fakeAsync((async) {
        controller.start();
        fake.emitOnline('u1');
        async.elapse(const Duration(milliseconds: 1));
        calls.clear();
        fake.emitOffline('u1');
        async.elapse(const Duration(minutes: 2));
        fake.emitOnline('u1');
        async.elapse(const Duration(minutes: 10));
        expect(calls.where((c) => c.method == 'stop'), isEmpty);
      });
    });

    test('idempotent start: two emissions do not double-call platform start',
        () async {
      controller.start();
      fake.emitOnline('u1');
      fake.emitOnline('u1');
      await Future<void>.delayed(Duration.zero);
      expect(calls.where((c) => c.method == 'start'), hasLength(1));
    });

    test('dispose() cancels subscription and stops running service', () async {
      controller.start();
      fake.emitOnline('u1');
      await Future<void>.delayed(Duration.zero);
      calls.clear();
      await controller.dispose();
      expect(calls.where((c) => c.method == 'stop'), hasLength(1));
    });
  });
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/core/voice/mesh_foreground_controller_test.dart`
Expected: compile error — `MeshForegroundController` not defined.

- [ ] **Step 3: Implement the controller**

Create `lib/core/voice/mesh_foreground_controller.dart`:

```dart
import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:flutter/services.dart';

import 'mesh_peer_eligibility_watcher.dart';

/// Anchors the Android process via a foreground Service when at least
/// one mesh peer is reachable. Idle (no peers): service is not running.
/// Has a 5-minute grace period after the last peer disappears.
///
/// No-op on iOS / Web — Phase 3 accepts iOS background suspension.
class MeshForegroundController {
  final MeshPeerEligibilityWatcher watcher;
  static const _channel = MethodChannel('taler_id/mesh_fg_service');
  static const _gracePeriod = Duration(minutes: 5);

  StreamSubscription<({String userId, bool isOnline})>? _sub;
  Timer? _stopTimer;
  bool _serviceRunning = false;

  /// Whether this controller targets a platform that supports the foreground
  /// service. Set in tests via [debugForcePlatformAndroid] or detected via
  /// `Platform.isAndroid` at runtime.
  static bool? debugForcePlatformAndroid;

  MeshForegroundController({required this.watcher});

  bool get _platformSupported {
    if (debugForcePlatformAndroid != null) return debugForcePlatformAndroid!;
    return !kIsWeb && Platform.isAndroid;
  }

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

  Future<void> _ensureRunning() async {
    if (_serviceRunning) return;
    _serviceRunning = true;
    try {
      await _channel.invokeMethod(
        'start',
        {'peerCount': watcher.onlinePeerCount},
      );
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
```

The MethodChannel is invoked unconditionally in tests because `TestDefaultBinaryMessengerBinding` intercepts. In production it's gated implicitly by the runtime not invoking start at all on iOS — see Task 7 boot sequence which adds `Platform.isAndroid` check at controller.start() call site.

Actually we can simplify: leave `_platformSupported` getter but not gate `start()` itself; instead the bootstrap call site checks. The getter is here for future use. Remove if unused — YAGNI.

For now, simplify by removing `_platformSupported` getter and `debugForcePlatformAndroid` field — gating happens at bootstrap (Task 7). Update the implementation:

```dart
import 'dart:async';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/services.dart';

import 'mesh_peer_eligibility_watcher.dart';

class MeshForegroundController {
  final MeshPeerEligibilityWatcher watcher;
  static const _channel = MethodChannel('taler_id/mesh_fg_service');
  static const _gracePeriod = Duration(minutes: 5);

  StreamSubscription<({String userId, bool isOnline})>? _sub;
  Timer? _stopTimer;
  bool _serviceRunning = false;

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

  Future<void> _ensureRunning() async {
    if (_serviceRunning) return;
    _serviceRunning = true;
    try {
      await _channel.invokeMethod(
        'start',
        {'peerCount': watcher.onlinePeerCount},
      );
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
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test test/core/voice/mesh_foreground_controller_test.dart`
Expected: `+7: All tests passed!`

- [ ] **Step 5: Run full suite**

Run: `flutter test`
Expected: 553 pass (546 + 7).

- [ ] **Step 6: Commit**

```bash
git add lib/core/voice/mesh_foreground_controller.dart \
        test/core/voice/mesh_foreground_controller_test.dart
git commit -m "feat(mesh-voice/3d.3): MeshForegroundController — Android FG service toggle with 5-min grace"
```

---

## Native Android

### Task 3: `MeshForegroundService.kt`

**Files:**
- Create: `android/app/src/main/kotlin/tirol/taler/taler_id_mobile/MeshForegroundService.kt`

Minimal Kotlin Service that anchors process priority via persistent notification. Does not host the mesh stack — that's in Dart isolate.

- [ ] **Step 1: Create the file**

Create `android/app/src/main/kotlin/tirol/taler/taler_id_mobile/MeshForegroundService.kt`:

```kotlin
package tirol.taler.taler_id_mobile

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationCompat

class MeshForegroundService : Service() {
    companion object {
        const val CHANNEL_ID = "mesh_fg_anchor"
        const val NOTIFICATION_ID = 9001
        const val ACTION_STOP = "tirol.taler.MESH_FG_STOP"
        const val EXTRA_PEER_COUNT = "peer_count"
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Mesh-сеть в фоне",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Поддерживает приём mesh-звонков когда телефон не активен"
                setShowBadge(false)
            }
            getSystemService(NotificationManager::class.java)
                .createNotificationChannel(channel)
        }
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == ACTION_STOP) {
            stopForeground(STOP_FOREGROUND_REMOVE)
            stopSelf()
            return START_NOT_STICKY
        }
        val peerCount = intent?.getIntExtra(EXTRA_PEER_COUNT, 0) ?: 0
        val text = if (peerCount > 0) "📡 $peerCount рядом" else "📡 Mesh активна"
        val notif = NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle("Mesh-сеть")
            .setContentText(text)
            .setOngoing(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .build()
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
                startForeground(
                    NOTIFICATION_ID,
                    notif,
                    ServiceInfo.FOREGROUND_SERVICE_TYPE_PHONE_CALL
                )
            } else {
                startForeground(NOTIFICATION_ID, notif)
            }
        } catch (e: Exception) {
            stopSelf()
            return START_NOT_STICKY
        }
        return START_STICKY
    }
}
```

- [ ] **Step 2: Verify compilation via Gradle**

Run: `cd android && ./gradlew :app:compileDebugKotlin && cd ..`
Expected: BUILD SUCCESSFUL.

If the Kotlin file fails because of import resolution (e.g., `R.mipmap.ic_launcher` not found), check for the actual launcher icon name in `android/app/src/main/res/mipmap-*/`. The codebase uses `ic_launcher` in all densities — should resolve.

- [ ] **Step 3: Commit**

```bash
git add android/app/src/main/kotlin/tirol/taler/taler_id_mobile/MeshForegroundService.kt
git commit -m "feat(mesh-voice/3d.3): MeshForegroundService.kt — process anchor with peer-count notification"
```

---

### Task 4: `MainActivity.kt` MethodChannel handler

**Files:**
- Modify: `android/app/src/main/kotlin/tirol/taler/taler_id_mobile/MainActivity.kt`

Add handler for `taler_id/mesh_fg_service` channel inside `configureFlutterEngine`. The file already declares multiple MethodChannels (line 80, 148, 287) — follow the existing pattern.

- [ ] **Step 1: Read MainActivity for context**

Read `android/app/src/main/kotlin/tirol/taler/taler_id_mobile/MainActivity.kt` lines 71-90 (start of `configureFlutterEngine`) and lines 280-290 (last existing MethodChannel registration) to identify a clean insertion point.

- [ ] **Step 2: Add imports if missing**

At the top of MainActivity.kt, ensure these imports are present (some likely already are):

```kotlin
import android.content.Intent
import android.os.Build
```

- [ ] **Step 3: Add handler block**

Inside `configureFlutterEngine(...)`, AFTER the last existing MethodChannel registration (around line 290) but BEFORE the closing brace, insert:

```kotlin
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "taler_id/mesh_fg_service")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "start" -> {
                        val peerCount = call.argument<Int>("peerCount") ?: 0
                        val intent = Intent(this, MeshForegroundService::class.java).apply {
                            putExtra(MeshForegroundService.EXTRA_PEER_COUNT, peerCount)
                        }
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            startForegroundService(intent)
                        } else {
                            startService(intent)
                        }
                        result.success(null)
                    }
                    "stop" -> {
                        val intent = Intent(this, MeshForegroundService::class.java).apply {
                            action = MeshForegroundService.ACTION_STOP
                        }
                        startService(intent)
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
```

- [ ] **Step 4: Verify Kotlin compiles**

Run: `cd android && ./gradlew :app:compileDebugKotlin && cd ..`
Expected: BUILD SUCCESSFUL.

- [ ] **Step 5: Commit**

```bash
git add android/app/src/main/kotlin/tirol/taler/taler_id_mobile/MainActivity.kt
git commit -m "feat(mesh-voice/3d.3): MainActivity MethodChannel handler for mesh_fg_service"
```

---

### Task 5: `AndroidManifest.xml` — declare service

**Files:**
- Modify: `android/app/src/main/AndroidManifest.xml`

- [ ] **Step 1: Add `<service>` element**

In `android/app/src/main/AndroidManifest.xml`, find the `<application>` opening tag. Inside the `<application>` block, AFTER the existing activity / service declarations, add:

```xml
        <service
            android:name=".MeshForegroundService"
            android:foregroundServiceType="phoneCall"
            android:exported="false" />
```

(Permissions `FOREGROUND_SERVICE` and `FOREGROUND_SERVICE_PHONE_CALL` are already declared in the manifest from Phase 3d.1 era — verify by searching the file. No new permissions needed.)

- [ ] **Step 2: Verify Gradle build**

Run: `cd android && ./gradlew :app:assembleDebug -x test 2>&1 | tail -20 && cd ..`
Expected: BUILD SUCCESSFUL or only unrelated warnings.

- [ ] **Step 3: Commit**

```bash
git add android/app/src/main/AndroidManifest.xml
git commit -m "feat(mesh-voice/3d.3): declare MeshForegroundService in manifest"
```

---

## Coordinator: callkit dispatch (background path)

### Task 6: `MeshVoiceUiCoordinator` — branch on lifecycle, callkit_incoming for background

**Files:**
- Modify: `lib/core/voice/mesh_voice_ui_coordinator.dart`
- Test: `test/core/voice/mesh_voice_ui_coordinator_callkit_test.dart`

The coordinator's `_handleIncoming` currently always shows a modal sheet. For background incoming, instead invoke `flutter_callkit_incoming` to show a full-screen overlay. Listen for ACCEPT / DECLINE callbacks. On EndedState, dismiss the callkit overlay.

- [ ] **Step 1: Write failing tests**

Create `test/core/voice/mesh_voice_ui_coordinator_callkit_test.dart`:

```dart
import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taler_id_mobile/core/mesh/transport/peer_id.dart';
import 'package:taler_id_mobile/core/mesh/voice/mesh_voice_state.dart';
import 'package:taler_id_mobile/core/voice/mesh_voice_ui_coordinator.dart';
import 'package:taler_id_mobile/features/call_history/data/mesh_call_history_entry.dart';
import 'package:taler_id_mobile/features/call_history/data/mesh_call_history_repository.dart';

class _FakeRepo implements MeshCallHistoryRepository {
  @override Future<void> add(MeshCallHistoryEntry e) async {}
  @override Future<void> deleteById(int callId) async {}
  @override Future<List<MeshCallHistoryEntry>> getAll() async => [];
  @override Stream<List<MeshCallHistoryEntry>> watch() => const Stream.empty();
}

class _SpyNavigator implements MeshNavigator {
  Widget? lastSheet;
  bool sheetShown = false;
  @override Future<T?> pushScreen<T>(Widget s) async => null;
  @override Future<void> showSheet(Widget s) async {
    sheetShown = true;
    lastSheet = s;
  }
  @override void popSheet() {}
  @override void popScreen() {}
  @override void showSnackbar(String m) {}
}

PeerId _peer(int seed) =>
    PeerId(Uint8List.fromList(List<int>.generate(32, (i) => i + seed)));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late StreamController<CallState> stateCtrl;
  late _SpyNavigator nav;
  late List<MethodCall> callkitCalls;
  late MeshVoiceUiCoordinator coord;

  setUp(() {
    stateCtrl = StreamController<CallState>.broadcast();
    nav = _SpyNavigator();
    callkitCalls = [];

    // Mock flutter_callkit_incoming MethodChannel
    const callkitCh = MethodChannel('flutter_callkit_incoming');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(callkitCh, (call) async {
      callkitCalls.add(call);
      return null;
    });

    coord = MeshVoiceUiCoordinator(
      stateStream: stateCtrl.stream,
      invite: (_) async => 1,
      accept: () async {},
      reject: () async {},
      hangup: () async {},
      repo: _FakeRepo(),
      navigator: nav,
      peerInfoLookup: (_) async =>
          const MeshPeerInfo(name: 'Alice', userId: 'u1'),
      selfDevicePk: _peer(0),
      transportLabelForPeer: (_) => null,
    );
  });

  tearDown(() async {
    await coord.dispose();
    await stateCtrl.close();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('flutter_callkit_incoming'), null);
  });

  group('MeshVoiceUiCoordinator background incoming', () {
    test('AppLifecycleState.resumed → showSheet (existing path, regression)',
        () async {
      coord.debugLifecycleState = AppLifecycleState.resumed;
      coord.start();
      stateCtrl.add(IncomingState(
          callerDevicePk: _peer(7),
          callId: 0xABCD,
          receivedAt: DateTime.utc(2026)));
      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(nav.sheetShown, isTrue);
      expect(callkitCalls.where((c) => c.method == 'showCallkitIncoming'),
          isEmpty);
    });

    test('AppLifecycleState.paused → showCallkitIncoming with mesh extras',
        () async {
      coord.debugLifecycleState = AppLifecycleState.paused;
      coord.start();
      stateCtrl.add(IncomingState(
          callerDevicePk: _peer(7),
          callId: 0xABCD,
          receivedAt: DateTime.utc(2026)));
      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(nav.sheetShown, isFalse);
      final showCall = callkitCalls.firstWhere(
          (c) => c.method == 'showCallkitIncoming',
          orElse: () => throw StateError('showCallkitIncoming not called'));
      final args = showCall.arguments as Map?;
      expect(args?['id'], 0xABCD.toString());
      expect(args?['nameCaller'], 'Alice');
      expect(args?['extra']?['mesh_call_id'], 0xABCD);
    });

    test('EndedState dismisses callkit overlay via endCall', () async {
      coord.debugLifecycleState = AppLifecycleState.paused;
      coord.start();
      stateCtrl.add(IncomingState(
          callerDevicePk: _peer(7),
          callId: 0xCAFE,
          receivedAt: DateTime.utc(2026)));
      await Future<void>.delayed(const Duration(milliseconds: 30));
      callkitCalls.clear();
      stateCtrl.add(EndedState(callId: 0xCAFE, reason: EndReason.userHangup));
      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(callkitCalls.where((c) => c.method == 'endCall'), hasLength(1));
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/core/voice/mesh_voice_ui_coordinator_callkit_test.dart`
Expected: compile error — `debugLifecycleState` setter not defined.

- [ ] **Step 3: Modify coordinator**

In `lib/core/voice/mesh_voice_ui_coordinator.dart`:

Add imports at top:

```dart
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/widgets.dart' show AppLifecycleState, WidgetsBinding;
import 'package:flutter_callkit_incoming/entities/call_event.dart' as ck_event;
import 'package:flutter_callkit_incoming/entities/call_kit_params.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'dart:io' show Platform;
```

Inside `MeshVoiceUiCoordinator`, add a debug field:

```dart
/// For tests: override the lifecycle state. Production reads from WidgetsBinding.
AppLifecycleState? debugLifecycleState;
```

Add helper:

```dart
bool _isAppInForeground() {
  final state = debugLifecycleState ?? WidgetsBinding.instance.lifecycleState;
  return state == AppLifecycleState.resumed;
}
```

Modify `_handleIncoming` to branch:

```dart
Future<void> _handleIncoming(IncomingState st) async {
  // ... existing peerInfo lookup + _pending setup (unchanged) ...

  if (_isAppInForeground()) {
    await navigator.showSheet(MeshIncomingCallSheet(
      peer: st.callerDevicePk,
      peerName: info.name,
      peerAvatarUrl: info.avatarUrl,
      onAccept: () => accept(),
      onDecline: () => reject(),
    ));
    return;
  }

  // Background path: full-screen callkit overlay (Android only — iOS lacks
  // the FG service that anchors the process, so iOS app would be suspended
  // before this code runs).
  await _showCallkitIncoming(st, info);
}

Future<void> _showCallkitIncoming(IncomingState st, MeshPeerInfo info) async {
  if (kIsWeb || !Platform.isAndroid) return;
  final fallback =
      'Mesh-устройство ${st.callerDevicePk.toHex().substring(0, 8)}';
  try {
    await FlutterCallkitIncoming.showCallkitIncoming(CallKitParams(
      id: st.callId.toString(),
      nameCaller: info.name ?? fallback,
      handle: '📡 Mesh',
      type: 0,
      avatar: info.avatarUrl,
      extra: {'mesh_call_id': st.callId},
    ));
  } catch (e) {
    // Plugin may throw if FCM-only mode is enabled or notif perm denied.
    // Fall through silently — call already in MeshVoiceService state machine.
  }
}
```

Add a callkit listener subscription in `start()`:

```dart
StreamSubscription<dynamic>? _callkitSub;

void start() {
  _sub ??= stateStream.listen(_onState);
  _callkitSub ??= FlutterCallkitIncoming.onEvent.listen(_onCallkitEvent);
}

@override
Future<void> dispose() async {
  await _sub?.cancel();
  await _callkitSub?.cancel();
  _sub = null;
  _callkitSub = null;
}

void _onCallkitEvent(dynamic event) {
  if (event == null) return;
  // event.body is Map<String, dynamic>
  final body = event.body as Map?;
  final extra = body?['extra'];
  if (extra is! Map) return;
  if (extra['mesh_call_id'] == null) return;
  // event.event is from ck_event.Event enum
  final eventType = event.event;
  if (eventType == ck_event.Event.actionCallAccept) {
    accept();
  } else if (eventType == ck_event.Event.actionCallDecline ||
      eventType == ck_event.Event.actionCallTimeout) {
    reject();
  }
}
```

In `_handleEnded`, after writing history, add:

```dart
if (!kIsWeb && Platform.isAndroid && p != null) {
  unawaited(
      FlutterCallkitIncoming.endCall(p.callId.toString()).catchError((_) {}));
}
```

(`unawaited` from `dart:async` — already imported.)

- [ ] **Step 4: Run callkit tests**

Run: `flutter test test/core/voice/mesh_voice_ui_coordinator_callkit_test.dart`
Expected: `+3: All tests passed!`

- [ ] **Step 5: Run all coordinator tests + integration**

Run: `flutter test test/core/voice/`
Expected: all pass; existing 11 coordinator tests + 7 fg controller tests + 1 integration + 3 new callkit = 22 in this directory.

- [ ] **Step 6: Run full suite**

Run: `flutter test`
Expected: 556 pass (553 + 3 new).

- [ ] **Step 7: Commit**

```bash
git add lib/core/voice/mesh_voice_ui_coordinator.dart \
        test/core/voice/mesh_voice_ui_coordinator_callkit_test.dart
git commit -m "feat(mesh-voice/3d.3): coordinator routes IncomingState to callkit_incoming when backgrounded"
```

---

## Battery exemption + DI + boot

### Task 7: Battery exemption educational dialog

**Files:**
- Modify: `lib/core/voice/mesh_prefs_service.dart`
- Create: `lib/features/voice/presentation/widgets/battery_exemption_dialog.dart`

Add a flag to MeshPrefsService for "user already saw the battery prompt", and a one-shot dialog that opens battery-optimization settings on user consent.

- [ ] **Step 1: Extend `MeshPrefsService`**

In `lib/core/voice/mesh_prefs_service.dart`, add a second key + getters/setters:

```dart
static const _batteryPromptKey = 'battery_prompt_shown_v1';

Future<bool> isBatteryPromptShown() async {
  return (_box?.get(_batteryPromptKey) as bool?) ?? false;
}

Future<void> markBatteryPromptShown() async {
  await _box?.put(_batteryPromptKey, true);
}
```

- [ ] **Step 2: Create the dialog**

Create `lib/features/voice/presentation/widgets/battery_exemption_dialog.dart`:

```dart
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../core/voice/mesh_prefs_service.dart';
import '../../../../l10n/app_localizations.dart';

class BatteryExemptionDialog {
  /// Show the battery-exemption educational dialog if running on Android
  /// and the user hasn't been prompted before. Returns true if dialog was
  /// shown (and dismissed).
  static Future<bool> showIfNeeded(BuildContext context) async {
    if (kIsWeb || !Platform.isAndroid) return false;
    final prefs = GetIt.I<MeshPrefsService>();
    if (await prefs.isBatteryPromptShown()) return false;
    if (!context.mounted) return false;

    final l10n = AppLocalizations.of(context)!;
    final accepted = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.batteryExemptionTitle),
        content: Text(l10n.batteryExemptionBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.batteryExemptionDismiss),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.batteryExemptionAccept),
          ),
        ],
      ),
    );
    await prefs.markBatteryPromptShown();
    if (accepted == true) {
      try {
        await Permission.ignoreBatteryOptimizations.request();
      } catch (_) {}
    }
    return true;
  }
}
```

- [ ] **Step 3: Run analyze**

Run: `flutter analyze lib/core/voice/mesh_prefs_service.dart lib/features/voice/presentation/widgets/battery_exemption_dialog.dart`
Expected: `No issues found!`

- [ ] **Step 4: Commit**

```bash
git add lib/core/voice/mesh_prefs_service.dart \
        lib/features/voice/presentation/widgets/battery_exemption_dialog.dart
git commit -m "feat(mesh-voice/3d.3): battery exemption educational dialog + prefs flag"
```

---

### Task 8: DI wiring + bootstrap (Android-only `controller.start()`)

**Files:**
- Modify: `lib/core/di/service_locator.dart`
- Modify: `lib/core/mesh/mesh_bootstrap.dart`
- Modify: `lib/main.dart` (battery dialog trigger)

- [ ] **Step 1: Register `MeshForegroundController` in DI**

In `lib/core/di/service_locator.dart`, add import:

```dart
import '../voice/mesh_foreground_controller.dart';
```

After `MeshPeerEligibilityWatcher` registration (3d.2), add:

```dart
sl.registerLazySingleton<MeshForegroundController>(
  () => MeshForegroundController(
    watcher: sl<MeshPeerEligibilityWatcher>(),
  ),
);
```

- [ ] **Step 2: Wire `controller.start()` in `runMeshBootstrap` (Android-only)**

In `lib/core/mesh/mesh_bootstrap.dart`, add imports:

```dart
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import '../voice/mesh_foreground_controller.dart';
```

In `runMeshBootstrap()` after `MeshPeerEligibilityWatcher.start()` block, add:

```dart
    if (!kIsWeb && Platform.isAndroid && sl.isRegistered<MeshForegroundController>()) {
      try {
        sl<MeshForegroundController>().start();
        debugPrint('[mesh-boot] MeshForegroundController.start() ok');
      } catch (e) {
        debugPrint('[mesh-boot] MeshForegroundController.start() failed: $e');
      }
    }
```

- [ ] **Step 3: Trigger battery dialog after first peer-online (one-shot)**

In `lib/main.dart`, the existing `TalerIdApp` widget tracks lifecycle. Find the `MaterialApp` `home` builder or similar mount point. Trigger the dialog in `WidgetsBinding.instance.addPostFrameCallback` after first `MeshPeerEligibilityWatcher.userChanges` event, but only once per app launch.

A simpler placement: piggyback on `MeshForegroundController._ensureRunning()` — first time the service starts, immediately schedule the dialog via `addPostFrameCallback`. Edit `mesh_foreground_controller.dart`:

Add field:
```dart
bool _batteryPromptScheduled = false;
```

Add helper to be called when service is started for first time:
```dart
void _maybeScheduleBatteryPrompt() {
  if (_batteryPromptScheduled) return;
  _batteryPromptScheduled = true;
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    final ctx = globalNavigatorKey.currentContext;
    if (ctx == null) return;
    await BatteryExemptionDialog.showIfNeeded(ctx);
  });
}
```

Add imports:
```dart
import 'package:flutter/widgets.dart' show WidgetsBinding;
import '../../features/voice/presentation/widgets/battery_exemption_dialog.dart';
import '../../main.dart' show globalNavigatorKey;
```

Inside `_ensureRunning()`, after the successful `invokeMethod` call, add:
```dart
_maybeScheduleBatteryPrompt();
```

- [ ] **Step 4: Run tests**

Run: `flutter test`
Expected: 556 pass.

- [ ] **Step 5: Run analyze**

Run: `flutter analyze lib/core/`
Expected: no new errors.

- [ ] **Step 6: Commit**

```bash
git add lib/core/di/service_locator.dart \
        lib/core/mesh/mesh_bootstrap.dart \
        lib/core/voice/mesh_foreground_controller.dart
git commit -m "feat(mesh-voice/3d.3): DI wiring + Android-gated controller.start() + battery prompt"
```

---

### Task 9: l10n keys

**Files:**
- Modify: `lib/l10n/app_ru.arb`
- Modify: `lib/l10n/app_en.arb`

- [ ] **Step 1: Add Russian keys**

In `lib/l10n/app_ru.arb`, after the existing `meshHistoryNoChatAvailable` entry, add:

```json
  "batteryExemptionTitle": "📡 Бесперебойные mesh-звонки",
  "batteryExemptionBody": "Чтобы Android не убивал mesh-сеть в фоне, разреши приложению работать без ограничений батареи.",
  "batteryExemptionAccept": "Открыть настройки",
  "batteryExemptionDismiss": "Не сейчас",
```

- [ ] **Step 2: Add English keys**

In `lib/l10n/app_en.arb`, same location:

```json
  "batteryExemptionTitle": "📡 Reliable mesh calls",
  "batteryExemptionBody": "Allow the app to run without battery restrictions so Android doesn't kill the mesh in the background.",
  "batteryExemptionAccept": "Open settings",
  "batteryExemptionDismiss": "Not now",
```

- [ ] **Step 3: Regenerate**

Run: `flutter gen-l10n`
Expected: `app_localizations*.dart` regenerated.

- [ ] **Step 4: Run tests**

Run: `flutter test`
Expected: 556 pass.

- [ ] **Step 5: Commit**

```bash
git add lib/l10n/app_ru.arb lib/l10n/app_en.arb lib/l10n/app_localizations*.dart
git commit -m "feat(mesh-voice/3d.3): l10n keys for battery exemption dialog"
```

---

## Hardware smoke + PR

### Task 10: Hardware smoke (manual)

**Files:** none.

- [ ] **Step 1: Local APK build + install on Redmi**

```bash
cd ~/Downloads/taler_id_mobile
flutter run --release --flavor dev -t lib/main_dev.dart \
  --dart-define=FLAVOR=dev --dart-define=BASE_URL=https://staging.id.taler.tirol \
  -d 78c0742f
```

Expected: app installs, launches, login OK.

- [ ] **Step 2: Local install on iPhone (regression check only)**

```bash
flutter run --release --flavor dev -t lib/main_dev.dart \
  --dart-define=FLAVOR=dev --dart-define=BASE_URL=https://staging.id.taler.tirol \
  -d 00008150-00060C5A21E9401C
```

- [ ] **Step 3: Foreground-service "first peer online" smoke**

On Android: after both devices logged in, peer comes online → notification "📡 Mesh: 1 рядом" appears in shade. (May take ~30 sec for Bonjour discovery.)

Battery exemption dialog appears once → tap "Открыть настройки" → grant exemption in OS settings → return to app. Subsequent launches do NOT show the dialog.

- [ ] **Step 4: Background incoming-call smoke**

On Android: with peer online, press home button → app to background. Persistent notification still showing.

From iPhone: place mesh call to Android.

Expected on Android (locked screen): full-screen callkit overlay with peer name + Accept/Decline buttons.

Tap Accept → screen unlocks → MeshVoiceCallScreen opens → audio works in both directions.

Hangup → MeshVoiceCallScreen closes → callkit overlay dismissed → app returns to background → persistent notification still showing.

- [ ] **Step 5: 5-min grace test**

iPhone disconnects (WiFi off). Wait 30 sec → notification still showing. Wait 5 min total → notification disappears (service stopped).

iPhone reconnects → notification reappears within ~30 sec (next Bonjour discovery cycle).

- [ ] **Step 6: 3d.1/3d.2 regression check**

While Android is foregrounded (chat open with peer):
- Eligibility dot 📡 appears next to phone icon ✓
- Short-tap → mesh call (foreground modal sheet, NOT callkit) ✓
- Long-press → transport popup ✓
- CallHistoryScreen shows mesh entries with badge ✓

iOS — verify mesh calls still work in foreground (no callkit dispatch since `Platform.isAndroid` guard). No persistent notification on iOS. iOS app suspending in background → mesh stops working there as before. No regression.

- [ ] **Step 7: Cleanup any debug prints**

Run: `git diff --stat`
Verify no extra debugPrints or temporary code.

---

### Task 11: Push branch + open PR / merge to dev

**Files:** none.

- [ ] **Step 1: Push branch**

```bash
git push origin feature/mesh-voice-call-phase3d.3
```

- [ ] **Step 2: Open PR via GitHub web (gh CLI not authenticated in this env)**

URL: https://github.com/dvvolkovv/taler_id_mobile/compare/dev...feature/mesh-voice-call-phase3d.3?expand=1

Title: `feat(mesh-voice/3d.3): Android background incoming via foreground service + callkit_incoming`

Body skeleton:
```markdown
## Summary

Phase 3d.3 closes the last gap of Phase 3 mesh voice calls: backgrounded
Android receives incoming mesh calls via full-screen callkit overlay (the
same UX as LiveKit). iOS limitation accepted as documented.

- New Kotlin `MeshForegroundService` anchors process priority via persistent
  notification ("📡 Mesh: N рядом"), foregroundServiceType="phoneCall".
- New Dart `MeshForegroundController` toggles the service based on
  `MeshPeerEligibilityWatcher` events, with 5-min grace after last peer.
- `MeshVoiceUiCoordinator` extended: branches on `AppLifecycleState.resumed`
  to route IncomingState through showSheet (foreground) or
  `flutter_callkit_incoming.showCallkitIncoming(...)` (background). New
  listener for ACCEPT/DECLINE callbacks. EndedState dismisses overlay.
- Battery exemption educational dialog (one-shot via `MeshPrefsService`).
- 4 new l10n keys.

## Test plan

- [x] Unit: MeshPeerEligibilityWatcher hasAnyOnlinePeer (3), MeshForegroundController (7), MeshVoiceUiCoordinator callkit dispatch (3)
- [x] flutter analyze clean
- [x] Hardware smoke on Redmi 78c0742f + iPhone 00008150 same WiFi:
  - Foreground regression: chat dot, mesh-call, history merge — all unchanged
  - Background incoming on Android: locked screen → callkit overlay → Accept → audio
  - 5-min grace: peer goes offline, notification persists 5 min, then disappears
  - Battery exemption: dialog shown once, opens OS settings on user consent

## Spec / plan

- Spec: `docs/superpowers/specs/2026-04-30-mesh-voice-call-phase3d3-design.md`
- Plan: `docs/superpowers/plans/2026-04-30-mesh-voice-call-phase3d3-android-bg.md`

## After merge

**Phase 3 mesh voice calls is complete.** Phase 3d.4 (FCM-bridge for app-killed
cold-start, iOS CallKit) deferred until real user demand.

🤖 Generated with [Claude Code](https://claude.com/claude-code)
```

- [ ] **Step 3: Merge to dev (after review)**

If `gh` CLI is authenticated: `gh pr merge <PR#> --merge --delete-branch=false`. Otherwise local:

```bash
git checkout dev
git pull origin dev --ff-only
git merge --no-ff feature/mesh-voice-call-phase3d.3 -m "Merge pull request #N from dvvolkovv/feature/mesh-voice-call-phase3d.3"
git push origin dev
```

---

## Done criteria

When all 11 tasks are checked off:
1. Branch pushed; PR opened (or merged via local merge).
2. Hardware smoke passed per Task 10 steps 3-6.
3. ~556 unit tests green.
4. `flutter analyze` clean for new + modified files.
5. iOS regression-clean.
6. **Phase 3 of mesh voice calls is complete.**

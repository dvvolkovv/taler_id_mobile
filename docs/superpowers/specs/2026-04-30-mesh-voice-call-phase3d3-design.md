# Phase 3d.3 — Mesh Voice Call: Android Background Incoming

**Status:** Brainstormed 2026-04-30; ready for writing-plans.

**Parent design:** [`2026-04-29-mesh-voice-call-phase3-design.md`](2026-04-29-mesh-voice-call-phase3-design.md). Phase 3d.1/3d.2 (already merged) shipped foreground mesh calls + chat integration. 3d.3 adds Android background-incoming via foreground service + reuse of `flutter_callkit_incoming`.

## Goal

On Android, when the app is in the background but not killed, an incoming mesh call surfaces as a full-screen callkit overlay (just like LiveKit incoming calls do today). After 3d.3, the realistic phone-in-pocket use case works end-to-end on Android.

## Non-Goals (Phase 3d.3)

- **iOS background mesh calls.** Accepted Phase 3 limitation; CallKit integration is out of scope for the entire Phase 3.
- **App killed (force-stopped, swiped from recents, OS reboot).** Process death takes the mesh stack with it; without a server-side wake mechanism, no FCM-style cold-start. Phase 3d.4 may add this if real users complain.
- **Outgoing calls in background.** User must open the app to place a call.
- **Per-peer count refresh in the persistent notification.** Notification shows "📡 N рядом" at the moment service starts, never updates as count changes. Acceptable cosmetic limitation for v1.

## Architecture

```
┌──────────────────────────────────────────────────────────────┐
│  Native (Kotlin)                                              │
│                                                                │
│  MeshForegroundService.kt (NEW, ~100 lines)                   │
│   - persistent notification "📡 Mesh: N рядом"               │
│   - START / STOP via Intent from Dart                         │
│   - foregroundServiceType="phoneCall" (Android 14+ compliant) │
│   - dies cleanly on stopForeground                            │
│                                                                │
│  MainActivity.kt (modify, +35 lines)                           │
│   - registers MethodChannel "taler_id/mesh_fg_service"        │
│   - handles "start" / "stop" calls from Dart                  │
└──────────────────────┬───────────────────────────────────────┘
                       │ platform channel taler_id/mesh_fg_service
                       ▼
┌──────────────────────────────────────────────────────────────┐
│  Dart                                                          │
│                                                                │
│  MeshForegroundController (NEW, ~150 lines)                   │
│   - subscribes to MeshPeerEligibilityWatcher.userChanges      │
│   - first peer online → invokeMethod("start", {peerCount})   │
│   - last peer offline → arm 5-minute Timer                    │
│   - peer comes back within 5 min → cancel Timer               │
│   - 5 min elapse → invokeMethod("stop")                       │
│   - dispose() on logout                                        │
│                                                                │
│  MeshVoiceUiCoordinator (modify, ~50 lines added)             │
│   - on IncomingState: read AppLifecycleState                  │
│     - if resumed → existing showSheet path (3d.1)             │
│     - else → FlutterCallkitIncoming.showCallkitIncoming(...)  │
│   - listener for FlutterCallkitIncoming.onEvent               │
│     - ACTION_CALL_ACCEPT (mesh extras) → accept()             │
│     - ACTION_CALL_DECLINE → reject()                          │
│     - ACTION_CALL_TIMEOUT → reject(reason: timeout)           │
│   - on EndedState: FlutterCallkitIncoming.endCall(callId)    │
│                                                                │
│  MeshPeerEligibilityWatcher (extend, +6 lines)                │
│   - bool get hasAnyOnlinePeer                                 │
│   - int get onlinePeerCount                                   │
└──────────────────────────────────────────────────────────────┘
```

**Incoming-call dispatch flow (background path):**

```
1. App in background, foreground service running, mesh stack alive in Dart isolate
2. Bonjour delivers Noise envelope → MeshMessagingService → MeshVoiceService
3. MeshVoiceService transitions to IncomingState(callerDevicePk, callId)
4. Coordinator._handleIncoming runs:
   a. lookup peerInfo (name/avatar) — existing 3d.1 path
   b. check WidgetsBinding.lifecycleState
   c. paused/inactive → FlutterCallkitIncoming.showCallkitIncoming(CallKitParams(
        id: callId.toString(),
        nameCaller: peerName ?? "Mesh-устройство <hex>",
        handle: "📡 Mesh",
        type: 0, // audio
        extra: {'mesh_call_id': callId},
      ))
5. Plugin renders full-screen overlay on lock screen with ringtone+vibration
6. User taps Accept:
   - Plugin emits CallEvent.ACTION_CALL_ACCEPT
   - Plugin starts MainActivity (existing FlutterActivity)
   - Coordinator's onEvent listener: accept()
   - Existing 3d.1 flow takes over: ActiveState → MeshVoiceCallScreen → audio
```

**Foreground service lifecycle:**

```
app boot (logged in)
  → runMeshBootstrap → watcher.start() → controller.start() (Android-only)

first peer discovered (e.g., 30s after app launch)
  → controller.invokeMethod("start", {peerCount: 1})
  → MainActivity bridges to startForegroundService(MeshForegroundService)
  → service.startForeground(notification "📡 Mesh: 1 рядом", FOREGROUND_SERVICE_TYPE_PHONE_CALL)

last peer goes offline
  → controller arms 5-min Timer

within 5 min: peer returns
  → controller cancels Timer, service stays running

5 min elapsed without peer
  → controller invokeMethod("stop")
  → service.stopForeground(STOP_FOREGROUND_REMOVE) + stopSelf()

user logs out
  → controller.dispose() → if running, stop service
```

## Components

### 1. `MeshForegroundService.kt`

**File:** `android/app/src/main/kotlin/tirol/taler/taler_id_mobile/MeshForegroundService.kt` (~100 lines)

Minimal Service. Does not host the mesh stack — only anchors process priority via persistent notification.

```kotlin
package tirol.taler.taler_id_mobile

import android.app.*
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
                startForeground(NOTIFICATION_ID, notif, ServiceInfo.FOREGROUND_SERVICE_TYPE_PHONE_CALL)
            } else {
                startForeground(NOTIFICATION_ID, notif)
            }
        } catch (e: Exception) {
            // Permission denied or system policy block — graceful degrade.
            stopSelf()
            return START_NOT_STICKY
        }
        return START_STICKY
    }
}
```

Manifest declaration in `AndroidManifest.xml`:

```xml
<service
    android:name=".MeshForegroundService"
    android:foregroundServiceType="phoneCall"
    android:exported="false" />
```

### 2. `MeshForegroundController` (Dart)

**File:** `lib/core/voice/mesh_foreground_controller.dart` (~150 lines)

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

  MeshForegroundController({required this.watcher});

  void start() {
    if (kIsWeb || !Platform.isAndroid) return;
    _sub = watcher.userChanges.listen(_onChange);
    if (watcher.hasAnyOnlinePeer) _ensureRunning();
  }

  Future<void> dispose() async {
    await _sub?.cancel();
    _stopTimer?.cancel();
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

### 3. `MainActivity.kt` — platform channel handler

**File:** `android/app/src/main/kotlin/tirol/taler/taler_id_mobile/MainActivity.kt` (modify, +35 lines)

Read the existing file first. Add inside `configureFlutterEngine` (after any existing channel registrations):

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

### 4. `MeshVoiceUiCoordinator` — callkit dispatcher (background path)

**File:** `lib/core/voice/mesh_voice_ui_coordinator.dart` (modify, ~50 lines)

In `_handleIncoming`, branch on `WidgetsBinding.instance.lifecycleState`:

```dart
Future<void> _handleIncoming(IncomingState st) async {
  // ... existing peer-info lookup + _pending setup unchanged ...

  if (_isAppInForeground()) {
    await navigator.showSheet(MeshIncomingCallSheet(...)); // 3d.1 path
    return;
  }
  await _showCallkitIncoming(st, info);
}

bool _isAppInForeground() {
  final state = WidgetsBinding.instance.lifecycleState;
  return state == AppLifecycleState.resumed;
}

Future<void> _showCallkitIncoming(IncomingState st, MeshPeerInfo info) async {
  await FlutterCallkitIncoming.showCallkitIncoming(CallKitParams(
    id: st.callId.toString(),
    nameCaller: info.name ?? 'Mesh-устройство ${st.callerDevicePk.toHex().substring(0, 8)}',
    handle: '📡 Mesh',
    type: 0,
    avatar: info.avatarUrl,
    extra: {'mesh_call_id': st.callId},
  ));
}
```

Listener in `start()` (one-time):

```dart
StreamSubscription<CallEvent?>? _callkitSub;

void start() {
  _sub ??= stateStream.listen(_onState);
  _callkitSub ??= FlutterCallkitIncoming.onEvent.listen(_onCallkitEvent);
}

void _onCallkitEvent(CallEvent? event) {
  if (event == null) return;
  final extra = event.body['extra'];
  if (extra is! Map) return;
  if (extra['mesh_call_id'] == null) return; // not a mesh call
  switch (event.event) {
    case Event.actionCallAccept:
      accept(); // existing 3d.1 method
      break;
    case Event.actionCallDecline:
    case Event.actionCallTimeout:
      reject();
      break;
    default:
      break;
  }
}
```

In `_handleEnded`, before history write:

```dart
if (Platform.isAndroid) {
  unawaited(FlutterCallkitIncoming.endCall(p.callId.toString()).catchError((_) {}));
}
```

### 5. Battery exemption dialog

**File:** `lib/features/voice/presentation/widgets/battery_exemption_dialog.dart` (~80 lines)

One-shot educational dialog (similar to `IosMeshOnboardingTooltip`) shown when first foreground-service start is attempted:

- Title: «📡 Бесперебойные mesh-звонки»
- Body: «Чтобы Android не убивал mesh-сеть в фоне, разреши приложению работать без ограничений батареи.»
- Actions: `[Открыть настройки] [Не сейчас]`
- "Не сейчас" sets a flag in `MeshPrefsService` so dialog doesn't reappear.
- "Открыть настройки" launches `Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS` via `permission_handler`.

Triggered once from `MeshForegroundController._ensureRunning()` if `MeshPrefsService.isBatteryExemptionPromptShown == false`.

### 6. `MeshPeerEligibilityWatcher` — extension

**File:** `lib/core/voice/mesh_peer_eligibility_watcher.dart` (modify, +6 lines)

```dart
bool get hasAnyOnlinePeer => _onlineDevices.isNotEmpty;
int get onlinePeerCount => _onlineDevices.length;
```

Both are O(1) Map size lookups.

### 7. l10n keys

```json
"meshFgNotificationTitle": "Mesh-сеть",
"meshFgNotificationTextN": "📡 {count} рядом",
"meshFgNotificationTextIdle": "📡 Mesh активна",
"batteryExemptionTitle": "📡 Бесперебойные mesh-звонки",
"batteryExemptionBody": "Чтобы Android не убивал mesh-сеть в фоне, разреши приложению работать без ограничений батареи.",
"batteryExemptionAccept": "Открыть настройки",
"batteryExemptionDismiss": "Не сейчас"
```

(Notification text is hardcoded in Kotlin since `flutter_localizations` doesn't reach native side. Use simpler hardcoded strings there, or pass via Intent extra. v1: hardcoded Russian/English fallback in Kotlin — accept localization debt for the Service-side text.)

## Boot sequence

```dart
// in mesh_bootstrap.dart, after watcher.start():
sl<MeshPeerEligibilityWatcher>().start();
if (!kIsWeb && Platform.isAndroid) {
  sl<MeshForegroundController>().start();
}
```

DI registration in `service_locator.dart`:

```dart
sl.registerLazySingleton<MeshForegroundController>(
  () => MeshForegroundController(
    watcher: sl<MeshPeerEligibilityWatcher>(),
  ),
);
```

## Edge cases

- **App killed mid-call:** mesh stack dies; peer's watchdog fires `noKeepalive` after 3s.
- **Peer disappears during incoming notification (before accept):** notification times out at 30s (callkit default) or user presses Decline. If user accepts after peer left → `accept()` sends call_accept envelope to peer that's gone → fails silently → 3s watchdog → EndedState(noKeepalive) → screen pops with "Соединение потеряно".
- **Battery optimization blocks foreground service:** Service.startForeground throws → caught in Kotlin → service stops itself; mesh-bg unreliable. Mitigation: educational dialog requesting battery exemption.
- **POST_NOTIFICATIONS denied (Android 13+):** Service runs but notification doesn't render; user has no visual confirmation. Acceptable graceful degrade — mesh still works while app foregrounded.
- **Multiple peers come online simultaneously:** notification rendered with peerCount at start time; doesn't refresh on subsequent emissions.
- **iOS:** controller skipped via `Platform.isAndroid` guard; no foreground service, no callkit dispatch (goes to existing showSheet path which still works while iOS app is foregrounded).
- **Race: incoming call at the moment service starting:** plugin works independently of our service. No race.
- **App in resumed but screen-off:** counts as `AppLifecycleState.resumed`. Existing showSheet path runs. Visible when user wakes screen — no overlay needed because screen-on shows app already on top.
- **Logout while service running:** controller.dispose() invokes "stop"; service stops cleanly.

## Testing

**Unit (`MeshForegroundController`):**
- `start()` on Android with empty watcher → no platform call.
- After PeerDiscovered → `start` channel call invoked once.
- After PeerLost → 5-min Timer armed; no `stop` called yet.
- New PeerDiscovered within grace → Timer cancelled; service stays.
- Grace expires (via `fakeAsync`) → `stop` called.
- Idempotent start/stop.
- `Platform.isAndroid == false` → no platform calls regardless of events.

**Unit (`MeshVoiceUiCoordinator` callkit dispatch):**
- New tests:
  - When app lifecycle = `paused` and IncomingState fires → mocked `flutter_callkit_incoming` receives `showCallkitIncoming` with correct CallKitParams (mesh_call_id in extras).
  - When `AppLifecycleState.resumed` → existing showSheet path (regression).
  - On `CallEvent.ACTION_CALL_ACCEPT` for mesh extra → `accept()` invoked.
  - On `CallEvent.ACTION_CALL_DECLINE` → `reject()` invoked.
  - On `EndedState` → `FlutterCallkitIncoming.endCall(callId)` invoked.

**Native (`MeshForegroundService.kt`):** Smoke-tested on hardware. No JUnit-instrumented tests for v1 (CI infra cost vs. value).

**Hardware smoke** (per success criteria below).

## Files to create

```
android/app/src/main/kotlin/tirol/taler/taler_id_mobile/MeshForegroundService.kt   ~100 lines
lib/core/voice/mesh_foreground_controller.dart                                    ~150 lines
lib/features/voice/presentation/widgets/battery_exemption_dialog.dart             ~80 lines

test/core/voice/mesh_foreground_controller_test.dart                              ~180 lines
test/core/voice/mesh_voice_ui_coordinator_callkit_test.dart                       ~120 lines
```

## Files to modify

```
android/app/src/main/AndroidManifest.xml                                +5 lines
android/app/src/main/kotlin/.../MainActivity.kt                         +35 lines
lib/core/voice/mesh_peer_eligibility_watcher.dart                       +6 lines
lib/core/voice/mesh_voice_ui_coordinator.dart                           +50 lines
lib/core/voice/mesh_prefs_service.dart                                  +8 lines (battery prompt flag)
lib/core/di/service_locator.dart                                        +10 lines
lib/core/mesh/mesh_bootstrap.dart                                       +10 lines
lib/l10n/app_ru.arb + app_en.arb                                        +7 keys
```

## Risks

**High:**

1. **Vendor battery optimization (Xiaomi, OPPO, Huawei) ignores foreground priority.** Educational dialog requests exemption; user opt-in.
2. **`flutter_callkit_incoming` plugin coupling to FCM-payload format.** Verify direct `showCallkitIncoming` call works without FCM wakeup. Fallback to `flutter_local_notifications` if plugin throws.

**Medium:**

3. **Android 13+ POST_NOTIFICATIONS runtime permission.** Without it, persistent notification doesn't render.
4. **Notification text doesn't refresh on count change.** v1 acceptable; future enhancement.
5. **CallEvent.ACTION_CALL_ACCEPT bring-to-foreground via plugin's intent.** Verify it correctly resumes MainActivity and routes to MeshVoiceCallScreen.

**Low:**

6. **`startForeground` permission errors silently caught** — mesh-bg becomes best-effort.
7. **Logout race** between dispose() and service-init.

## Success criteria

3d.3 done when:

1. **Hardware smoke on Redmi 78c0742f + iPhone 00008150 (same WiFi):**
   - Android user opens DIRECT chat with iPhone-user → 📡 dot appears.
   - Android user goes to home screen / lock screen.
   - In notification shade: persistent notification "📡 Mesh: 1 рядом" with low-priority icon.
   - iPhone-user places mesh call to Android.
   - Android lock screen shows full-screen callkit overlay with peer name + Accept/Decline.
   - Tap Accept → Android unlocks → MeshVoiceCallScreen open → audio works both directions.
   - Hangup → MeshVoiceCallScreen closes; persistent "📡 Mesh: 1 рядом" still showing (peer still online).
   - iPhone-user disables WiFi → notification stays ~5 min (grace) → disappears.

2. **Battery exemption educational dialog appears once** on first attempted foreground-service start (or at app boot if permission unset). User can dismiss.

3. **`flutter test` — ~553 pass** (543 baseline + ~10 new for controller + callkit dispatch tests).

4. **`flutter analyze` clean** for new files.

5. **iOS (00008150) — no regressions, no new UX.** Foreground controller skipped; mesh works as in 3d.2.

6. **No regressions in 3d.1/3d.2:** all existing mesh-call flows (foreground place/receive, history, eligibility dot) work unchanged.

7. **Android 12 / Android 13 / Android 14+ all behave correctly:**
   - Android 12 (API 31): no `foregroundServiceType` enforcement, service starts.
   - Android 13 (API 33): POST_NOTIFICATIONS permission needed; if denied, graceful degrade.
   - Android 14+ (API 34): `foregroundServiceType="phoneCall"` enforced; manifest already declares it.

## Vertical slice for Phase 3d.4 (future)

After 3d.3, Phase 3 mesh-voice-call is **production-quality on Android** for the realistic use case (phone-in-pocket). Phase 3d.4 (deferred until real user demand) could add:

- FCM-bridge for cold-start app: server-side FCM push includes mesh-call invite envelope; Android wakes app via existing FCM handler; mesh-stack re-establishes on demand.
- iOS CallKit integration via VoIP push (existing infrastructure).

These are server-side changes + multi-week sprints; out of Phase 3 scope.

## Rollout

1. Branch `feature/mesh-voice-call-phase3d.3` from `dev` (3d.2 already merged).
2. Implement via subagent-driven-development: ~10 tasks (Service, Controller, MainActivity, watcher extension, callkit dispatch, callkit listener, battery dialog, DI, smoke).
3. Hardware smoke per success criteria.
4. PR into `dev`. After merge, **Phase 3 is complete**.

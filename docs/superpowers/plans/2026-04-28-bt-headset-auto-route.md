# BT Headset Mid-Call Auto-Route — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** When a user connects a Bluetooth headset during an active call on Android, automatically activate `startBluetoothSco()` so the BT mic is actually used (not the phone's mic), and reflect the change in the call screen UI.

**Architecture:** Native `AudioDeviceCallback` in `MainActivity.kt` listens for BT SCO devices being added/removed; while `AudioManager.mode == MODE_IN_COMMUNICATION`, it triggers the same routing actions that `setAudioOutput("bluetooth")` already performs, then pushes an event to Flutter via a new `EventChannel("taler_id/audio_route")`. Flutter's `voice_call_screen.dart` subscribes and updates `_audioOutputType` so the UI shows the active output.

**Tech Stack:** Kotlin (Android), Flutter, EventChannel.

**Spec:** [docs/superpowers/specs/2026-04-28-bt-headset-auto-route-design.md](docs/superpowers/specs/2026-04-28-bt-headset-auto-route-design.md)

**Min SDK:** 24 — `AudioManager.registerAudioDeviceCallback` (API 23+) is universally available.

---

## File Map

- **Modify** `android/app/src/main/kotlin/tirol/taler/taler_id_mobile/MainActivity.kt` — add EventChannel registration, `AudioDeviceCallback`, lifecycle hooks.
- **Modify** `lib/features/voice/presentation/screens/voice_call_screen.dart` — subscribe to the EventChannel, update `_audioOutputType` on events, dispose on screen exit. Extract a small pure helper `mapAudioRouteEvent` for testability.
- **Create** `test/features/voice/audio_route_event_test.dart` — unit tests for the helper.

No backend changes. No iOS changes. No route, BLoC, repository, or domain entity changes.

---

## Pre-flight

- [ ] **Step P1: Verify branch and clean tree**

```bash
cd ~/Downloads/taler_id_mobile
git status --short
git branch --show-current
```

Expected: branch `dev`, untracked files only (unrelated dev artifacts and existing specs are fine).

- [ ] **Step P2: Confirm baseline tests pass**

```bash
cd ~/Downloads/taler_id_mobile && flutter test
```

Expected: all green (439 tests at time of writing). If red, stop and investigate before starting.

---

## Task 1: Native `AudioDeviceCallback` + EventChannel in `MainActivity.kt`

**Files:**
- Modify: `android/app/src/main/kotlin/tirol/taler/taler_id_mobile/MainActivity.kt`

This task adds the native plumbing only. Flutter wire-up comes in Task 2.

- [ ] **Step 1.1: Add new imports**

At the top of `MainActivity.kt`, alongside existing imports, add:

```kotlin
import android.media.AudioDeviceCallback
import io.flutter.plugin.common.EventChannel
import java.util.concurrent.atomic.AtomicReference
```

(`AudioManager`, `AudioDeviceInfo`, `Build`, `AudioFocusRequest`, `AudioAttributes` are already imported per existing file.)

- [ ] **Step 1.2: Add fields**

Inside the `MainActivity` class, near other private fields (e.g., near `audioChannel` if it exists, or at the top of the class body), add:

```kotlin
private val audioRouteEventSink = AtomicReference<EventChannel.EventSink?>(null)
private var audioDeviceCallback: AudioDeviceCallback? = null
```

- [ ] **Step 1.3: Add the `AudioDeviceCallback` registration helpers**

Add these private methods to the `MainActivity` class (place them near the existing audio-related helpers like `requestAudioFocus`):

```kotlin
private fun registerAudioRouteCallback() {
    if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) return
    val am = getSystemService(AUDIO_SERVICE) as AudioManager

    val cb = object : AudioDeviceCallback() {
        override fun onAudioDevicesAdded(addedDevices: Array<out AudioDeviceInfo>) {
            val bt = addedDevices.firstOrNull { isBluetoothHeadset(it) } ?: return
            if (am.mode != AudioManager.MODE_IN_COMMUNICATION) return
            try {
                am.isSpeakerphoneOn = false
                am.startBluetoothSco()
                am.isBluetoothScoOn = true
                requestAudioFocus(am)
            } catch (e: Exception) {
                Log.w("AudioRoute", "BT SCO start failed: ${e.message}")
            }
            sendRouteEvent(mapOf(
                "event" to "bluetoothConnected",
                "name" to (bt.productName?.toString() ?: "Bluetooth")
            ))
        }

        override fun onAudioDevicesRemoved(removedDevices: Array<out AudioDeviceInfo>) {
            val hadBt = removedDevices.any { isBluetoothHeadset(it) }
            if (!hadBt) return
            if (am.mode != AudioManager.MODE_IN_COMMUNICATION) return
            try {
                am.stopBluetoothSco()
                am.isBluetoothScoOn = false
                am.isSpeakerphoneOn = false
            } catch (e: Exception) {
                Log.w("AudioRoute", "BT SCO stop failed: ${e.message}")
            }
            sendRouteEvent(mapOf("event" to "bluetoothDisconnected"))
        }

        private fun isBluetoothHeadset(d: AudioDeviceInfo): Boolean =
            d.type == AudioDeviceInfo.TYPE_BLUETOOTH_SCO ||
                (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S &&
                    d.type == AudioDeviceInfo.TYPE_BLE_HEADSET)
    }
    am.registerAudioDeviceCallback(cb, null)
    audioDeviceCallback = cb
}

private fun unregisterAudioRouteCallback() {
    val am = getSystemService(AUDIO_SERVICE) as AudioManager
    audioDeviceCallback?.let { am.unregisterAudioDeviceCallback(it) }
    audioDeviceCallback = null
}

private fun sendRouteEvent(payload: Map<String, Any?>) {
    runOnUiThread { audioRouteEventSink.get()?.success(payload) }
}
```

- [ ] **Step 1.4: Register the EventChannel in `configureFlutterEngine`**

Find the existing `configureFlutterEngine(flutterEngine: FlutterEngine)` override. After the `taler_id/audio` MethodChannel is configured (search for `name: "taler_id/audio"` and locate the closing brace of its `setMethodCallHandler` block), add:

```kotlin
EventChannel(flutterEngine.dartExecutor.binaryMessenger, "taler_id/audio_route")
    .setStreamHandler(object : EventChannel.StreamHandler {
        override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
            audioRouteEventSink.set(events)
        }
        override fun onCancel(arguments: Any?) {
            audioRouteEventSink.set(null)
        }
    })

registerAudioRouteCallback()
```

- [ ] **Step 1.5: Unregister in `onDestroy`**

Find the existing `override fun onDestroy()` (or add one if missing). Inside, add a call to `unregisterAudioRouteCallback()` before `super.onDestroy()`. Example template (adapt to existing code):

```kotlin
override fun onDestroy() {
    unregisterAudioRouteCallback()
    super.onDestroy()
}
```

If there is no existing `onDestroy`, add one. If there is one, just add the line.

- [ ] **Step 1.6: Build the Android side to verify it compiles**

```bash
cd ~/Downloads/taler_id_mobile && flutter build apk --flavor dev --debug --dart-define=FLAVOR=dev --dart-define=BASE_URL=https://staging.id.taler.tirol 2>&1 | tail -25
```

Expected: `BUILD SUCCESSFUL`. If Kotlin compile fails, the error message will pinpoint the line — fix and retry.

- [ ] **Step 1.7: Commit**

```bash
cd ~/Downloads/taler_id_mobile
git add android/app/src/main/kotlin/tirol/taler/taler_id_mobile/MainActivity.kt
git commit -m "feat(voice/android): AudioDeviceCallback auto-routes to BT during call"
```

---

## Task 2: Flutter subscription in `voice_call_screen.dart`

**Files:**
- Modify: `lib/features/voice/presentation/screens/voice_call_screen.dart`

- [ ] **Step 2.1: Add EventChannel constant and subscription field**

Near the top of the `_VoiceCallScreenState` class (where `_audioOutputType` is declared at line 69), add:

```dart
static const _audioRouteChannel = EventChannel('taler_id/audio_route');
StreamSubscription<dynamic>? _audioRouteSub;
```

If `EventChannel` is not yet imported in this file, add at the top:

```dart
import 'package:flutter/services.dart' show EventChannel;
```

(Likely already imported via `MethodChannel` from the same package — verify by `grep`.)

If `dart:async` is not imported, add:

```dart
import 'dart:async';
```

(Also likely already imported.)

- [ ] **Step 2.2: Add the testable mapping helper**

Near the bottom of the file (or wherever helper functions live — match local convention), add:

```dart
@visibleForTesting
String? mapAudioRouteEvent(Object? event) {
  if (event is! Map) return null;
  switch (event['event']) {
    case 'bluetoothConnected':
      return 'bluetooth';
    case 'bluetoothDisconnected':
      return 'earpiece';
    default:
      return null;
  }
}
```

If `@visibleForTesting` is not imported, add:

```dart
import 'package:flutter/foundation.dart' show visibleForTesting;
```

(Likely already imported via `kDebugMode` etc. — verify by `grep`.)

- [ ] **Step 2.3: Add the event handler method**

Add inside `_VoiceCallScreenState`:

```dart
void _onAudioRouteEvent(Object? event) {
  if (!mounted) return;
  final mapped = mapAudioRouteEvent(event);
  if (mapped == null || mapped == _audioOutputType) return;
  setState(() => _audioOutputType = mapped);
}
```

- [ ] **Step 2.4: Subscribe in `initState`**

Find the existing `initState()` override in `_VoiceCallScreenState`. Append (just before the closing brace, after existing setup):

```dart
_audioRouteSub = _audioRouteChannel
    .receiveBroadcastStream()
    .listen(_onAudioRouteEvent);
```

- [ ] **Step 2.5: Cancel subscription in `dispose`**

Find the existing `dispose()` override. Add at the top (before `super.dispose()`):

```dart
_audioRouteSub?.cancel();
_audioRouteSub = null;
```

- [ ] **Step 2.6: Verify the Dart side compiles**

```bash
cd ~/Downloads/taler_id_mobile && flutter analyze lib/features/voice/presentation/screens/voice_call_screen.dart
```

Expected: no NEW errors. (Pre-existing warnings are OK; this file has dozens of them.)

- [ ] **Step 2.7: Run full test suite**

```bash
cd ~/Downloads/taler_id_mobile && flutter test
```

Expected: 439/439 still passing.

- [ ] **Step 2.8: Commit**

```bash
cd ~/Downloads/taler_id_mobile
git add lib/features/voice/presentation/screens/voice_call_screen.dart
git commit -m "feat(voice/flutter): subscribe to audio_route events for BT auto-switch"
```

---

## Task 3: Unit tests for `mapAudioRouteEvent`

**Files:**
- Create: `test/features/voice/audio_route_event_test.dart`

- [ ] **Step 3.1: Create the test directory if missing**

```bash
cd ~/Downloads/taler_id_mobile && mkdir -p test/features/voice
```

- [ ] **Step 3.2: Write the test file**

Create `test/features/voice/audio_route_event_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:taler_id_mobile/features/voice/presentation/screens/voice_call_screen.dart';

void main() {
  group('mapAudioRouteEvent', () {
    test('bluetoothConnected maps to bluetooth', () {
      expect(mapAudioRouteEvent({'event': 'bluetoothConnected'}), 'bluetooth');
    });

    test('bluetoothConnected with extra fields maps to bluetooth', () {
      expect(
        mapAudioRouteEvent({'event': 'bluetoothConnected', 'name': 'AirPods'}),
        'bluetooth',
      );
    });

    test('bluetoothDisconnected maps to earpiece', () {
      expect(mapAudioRouteEvent({'event': 'bluetoothDisconnected'}), 'earpiece');
    });

    test('unknown event returns null', () {
      expect(mapAudioRouteEvent({'event': 'somethingElse'}), isNull);
    });

    test('non-map event returns null', () {
      expect(mapAudioRouteEvent('string event'), isNull);
      expect(mapAudioRouteEvent(42), isNull);
      expect(mapAudioRouteEvent(null), isNull);
    });

    test('map without event key returns null', () {
      expect(mapAudioRouteEvent({'name': 'AirPods'}), isNull);
    });
  });
}
```

- [ ] **Step 3.3: Run only this test file first**

```bash
cd ~/Downloads/taler_id_mobile && flutter test test/features/voice/audio_route_event_test.dart
```

Expected: 6 tests, all PASS.

- [ ] **Step 3.4: Run full suite**

```bash
cd ~/Downloads/taler_id_mobile && flutter test
```

Expected: 445/445 passing (439 + 6).

- [ ] **Step 3.5: Commit**

```bash
cd ~/Downloads/taler_id_mobile
git add test/features/voice/audio_route_event_test.dart
git commit -m "test(voice): unit tests for mapAudioRouteEvent"
```

---

## Task 4: Real-device smoke test

This task is performed by the user (or controller with the connected device). It cannot be automated — it requires real Bluetooth hardware and a second device for the remote party.

- [ ] **Step 4.1: Build dev APK**

```bash
cd ~/Downloads/taler_id_mobile && flutter build apk --flavor dev --debug \
  --dart-define=FLAVOR=dev \
  --dart-define=BASE_URL=https://staging.id.taler.tirol
```

Output: `build/app/outputs/flutter-apk/app-dev-debug.apk`.

- [ ] **Step 4.2: Install on test device `78c0742f`**

```bash
~/Library/Android/sdk/platform-tools/adb -s 78c0742f install -r build/app/outputs/flutter-apk/app-dev-debug.apk
```

- [ ] **Step 4.3: Manual smoke checklist**

1. Log in as `integration_test@taler-test.com` / `IntegrationTest123!` on `78c0742f`.
2. On a second device (emulator or other phone), log in as `integration_test_2@taler-test.com` / `IntegrationTest123!`.
3. From device 1, start a call to user 2 via the existing conversation (DEV id `91f97844-307b-4a20-ad62-c1d2820e627f`).
4. Without BT connected, confirm device 2 hears device 1 fine via earpiece.
5. On device 1 mid-call, turn on Bluetooth headphones (pair if needed).
6. **Assertion 1:** within ~2 seconds, the audio output indicator on device 1's call screen automatically shows "Bluetooth" (BT icon active, label changed).
7. **Assertion 2:** device 2 reports voice quality is now clear and at normal volume — NOT muffled / distant.
8. Turn off / disconnect BT on device 1 (e.g., power off headphones).
9. **Assertion 3:** within ~2 seconds, the indicator on device 1 reverts to "earpiece"; voice continues normally on the phone earpiece.

If any assertion fails: stop, gather logs (`adb logcat -s flutter AudioRoute -t 200`), debug, fix in a new commit, re-test.

- [ ] **Step 4.4: No commit — manual verification only**

If all 3 assertions pass, the fix is verified end-to-end. If any failed and required a code fix, the fix is its own commit on `dev`.

---

## Task 5: Push to `origin/dev`

- [ ] **Step 5.1: Pull latest (rebase)**

```bash
cd ~/Downloads/taler_id_mobile && git fetch origin dev && git pull --rebase origin dev
```

If conflicts occur: investigate (the bug fix touches different files than typical mesh/messenger work, so conflicts are unlikely).

- [ ] **Step 5.2: Push**

```bash
cd ~/Downloads/taler_id_mobile && git push origin dev
```

⚠️ Do NOT proceed to dev APK deploy on the build server (138.124.61.221 + `/var/www/downloads/taler-id-dev.apk`) without explicit user approval per CLAUDE.md.

---

## Self-Review Checklist (run before declaring done)

After implementation:

- [ ] All 4 implementation tasks committed on `dev`.
- [ ] Spec requirements covered: native callback registered ✓, BT add triggers SCO ✓, BT remove falls back ✓, Flutter UI updates ✓, mode-guard prevents music interference ✓.
- [ ] Tests: 6 unit tests for `mapAudioRouteEvent` (Task 3), real-device smoke (Task 4).
- [ ] No iOS changes (out-of-scope honored).
- [ ] No regressions in existing 439 tests.

---

## Out of Scope (per spec)

- iOS audio session changes
- "Remember user preference" override
- Wired-headphone auto-detection
- Auto-detect BT already connected at call start (deferred unless smoke test reveals it as a real issue)

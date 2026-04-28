# Bluetooth Headset Mid-Call Auto-Route (Android)

**Date:** 2026-04-28
**Status:** Approved
**Scope:** Android only (Flutter + native Kotlin). iOS not touched.

## Summary

When a user connects Bluetooth headphones during an active LiveKit voice call on Android, the OS automatically reroutes call **output** to the BT device (via A2DP), but the **microphone input remains on the phone's built-in mic** because nothing in the app activates the BT SCO channel. Result: the remote party hears the user faintly and with ambient room noise, since the phone (likely in pocket / on a surface) is far from the user's mouth.

This design adds an `AudioDeviceCallback` listener in `MainActivity.kt` that auto-activates `startBluetoothSco()` when a BT headset is added during a call (i.e., while `AudioManager.mode == MODE_IN_COMMUNICATION`), and fires Flutter events so the call screen reflects the current output device.

## Root Cause

Confirmed in [voice_call_screen.dart:69](lib/features/voice/presentation/screens/voice_call_screen.dart#L69) and [voice_call_screen.dart:2470-2490](lib/features/voice/presentation/screens/voice_call_screen.dart#L2470-L2490):

> `_audioOutputType` is updated **only** when the user explicitly taps the audio-output button. There is no listener for OS-level audio device changes. When the user dynamically connects a BT headset mid-call, the Flutter side never knows, so `setAudioOutput("bluetooth")` (which would call `am.startBluetoothSco()` at [MainActivity.kt:188](android/app/src/main/kotlin/tirol/taler/taler_id_mobile/MainActivity.kt#L188)) never fires.

The native `setAudioOutput("bluetooth")` handler already does exactly the right thing — `MODE_IN_COMMUNICATION` + `startBluetoothSco()` + `isBluetoothScoOn = true`. We just need to **trigger it automatically on device connection**.

## Architecture

Single point of change on each layer:

- **Native Android:** [MainActivity.kt](android/app/src/main/kotlin/tirol/taler/taler_id_mobile/MainActivity.kt) — register `AudioDeviceCallback`, react to `onAudioDevicesAdded` / `onAudioDevicesRemoved`, send events through a new `EventChannel` named `taler_id/audio_route`.
- **Flutter:** [voice_call_screen.dart](lib/features/voice/presentation/screens/voice_call_screen.dart) — subscribe to `EventChannel` in `initState`, update `_audioOutputType` on events, dispose subscription in `dispose`.

No changes to:
- iOS native code
- Existing `taler_id/audio` MethodChannel handler (`setAudioOutput`, `getAudioOutputs`, etc.)
- Backend / API
- Routes, BLoCs, repositories
- The audio-output picker UI in the call screen

## Components

### Native Android: `AudioDeviceCallback`

In `MainActivity.kt`:

```kotlin
private val audioRouteEventSink = AtomicReference<EventChannel.EventSink?>(null)
private var audioDeviceCallback: AudioDeviceCallback? = null

private fun registerAudioRouteCallback() {
    if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) return  // API 23+ required
    val am = getSystemService(AUDIO_SERVICE) as AudioManager

    val cb = object : AudioDeviceCallback() {
        override fun onAudioDevicesAdded(addedDevices: Array<out AudioDeviceInfo>) {
            val bt = addedDevices.firstOrNull { isBluetoothHeadset(it) } ?: return
            // Only auto-route when we are in an active call.
            if (am.mode != AudioManager.MODE_IN_COMMUNICATION) return
            am.isSpeakerphoneOn = false
            am.startBluetoothSco()
            am.isBluetoothScoOn = true
            requestAudioFocus(am)
            sendRouteEvent(mapOf("event" to "bluetoothConnected", "name" to (bt.productName?.toString() ?: "Bluetooth")))
        }

        override fun onAudioDevicesRemoved(removedDevices: Array<out AudioDeviceInfo>) {
            val hadBt = removedDevices.any { isBluetoothHeadset(it) }
            if (!hadBt) return
            if (am.mode != AudioManager.MODE_IN_COMMUNICATION) return
            am.stopBluetoothSco()
            am.isBluetoothScoOn = false
            am.isSpeakerphoneOn = false
            sendRouteEvent(mapOf("event" to "bluetoothDisconnected"))
        }

        private fun isBluetoothHeadset(d: AudioDeviceInfo): Boolean =
            d.type == AudioDeviceInfo.TYPE_BLUETOOTH_SCO ||
                (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S && d.type == AudioDeviceInfo.TYPE_BLE_HEADSET)
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

Lifecycle hookup:
- Call `registerAudioRouteCallback()` in `configureFlutterEngine()` after the audio MethodChannel is set up.
- Unregister in `onDestroy()`.

EventChannel registration:
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
```

**Why filter on `MODE_IN_COMMUNICATION`:** if the user connects BT headphones outside a call (e.g., to listen to music), we must NOT call `startBluetoothSco()` — that would force HFP and degrade music to 8 kHz mono. Only react during active calls.

**Why `TYPE_BLUETOOTH_SCO` (not A2DP):** A2DP is output-only; SCO is the bidirectional voice profile. Listening for SCO devices avoids reacting to non-call BT events.

### Flutter: EventChannel subscription

In `voice_call_screen.dart`:

```dart
static const _audioRouteChannel = EventChannel('taler_id/audio_route');
StreamSubscription<dynamic>? _audioRouteSub;

@override
void initState() {
  super.initState();
  // ... existing init ...
  _audioRouteSub = _audioRouteChannel.receiveBroadcastStream().listen(_onAudioRouteEvent);
}

void _onAudioRouteEvent(dynamic event) {
  if (!mounted || event is! Map) return;
  final type = event['event'];
  if (type == 'bluetoothConnected') {
    setState(() => _audioOutputType = 'bluetooth');
  } else if (type == 'bluetoothDisconnected') {
    setState(() => _audioOutputType = 'earpiece');
  }
}

@override
void dispose() {
  _audioRouteSub?.cancel();
  // ... existing dispose ...
}
```

The native side already runs the audio routing actions; Flutter only updates UI state to match.

## Data Flow

```
[User puts on BT during active call]
        │
        ▼
Android OS → AudioDeviceCallback.onAudioDevicesAdded(...) on MainActivity
        │
        ├─ am.mode == MODE_IN_COMMUNICATION? yes
        ├─ am.startBluetoothSco()
        ├─ am.isBluetoothScoOn = true
        └─ EventSink → "bluetoothConnected" event
                │
                ▼
        Flutter receiveBroadcastStream → _onAudioRouteEvent
                │
                └─ setState(_audioOutputType = 'bluetooth')
                        │
                        ▼
                UI updates: BT indicator on, mic now via SCO

[Remote party now hears user's voice clearly through the BT mic]
```

## Edge Cases

- **BT connected before call starts:** outside call (`am.mode != MODE_IN_COMMUNICATION`), the callback short-circuits. Existing `setAudioOutput` flow at call start handles initial routing — unchanged.
- **User manually selects "earpiece" then connects BT:** the auto-switch fires and overrides their manual choice. Acceptable: BT is almost always the user's preferred device when newly connected; if they want earpiece, they tap manually. (Could be revisited later with a "user preference" memory; out of scope.)
- **Multiple BT devices connected:** the first one in `addedDevices` wins. SCO can only run on one device at a time anyway.
- **API < 23 (Android 5.x):** `registerAudioDeviceCallback` not available. The whole feature degrades gracefully — the callback simply isn't registered, behavior is unchanged from today. Project's `minSdk` is 23+ (verify in implementation).
- **Activity recreated (config change):** `onDestroy` unregisters; `configureFlutterEngine` re-registers on the new instance. Sink reset in `onListen`.
- **Multi-user / multi-call:** voice_call_screen.dart already handles call line switching via `_switchToLine`. The route subscription is screen-scoped (initState/dispose), so it follows the screen.
- **Race: BT plugged in DURING `MODE_IN_COMMUNICATION` change:** if BT connects before mode flips to in-call, the early-return path activates. Existing `setAudioOutput("earpiece")` at call start runs after, but won't auto-detect already-connected BT. **Mitigation:** at the moment Flutter calls `setAudioOutput("earpiece")` (or generally on call start), check for already-connected BT; if any, send a synthetic `bluetoothConnected` event so Flutter UI shows the right state. *(Decision: defer this corner-case to a follow-up unless the smoke test reveals it. The user's reported case is "BT connected mid-call", which is the primary path.)*

## Testing

### 1. Flutter unit test (new)

`test/features/voice/audio_route_event_test.dart`:
- Use `MethodChannel` mock for the EventChannel binary messenger.
- Send `{"event": "bluetoothConnected"}` → assert a state holder (extracted from voice_call_screen for testability OR a small helper class) flips to `'bluetooth'`.
- Send `{"event": "bluetoothDisconnected"}` → assert it flips back to `'earpiece'`.
- Send malformed event → assert no crash, state unchanged.

To make this testable, the event-handler logic moves into a small free function or static helper called by `_onAudioRouteEvent`:

```dart
@visibleForTesting
String? mapAudioRouteEvent(Object? event) {
  if (event is! Map) return null;
  switch (event['event']) {
    case 'bluetoothConnected': return 'bluetooth';
    case 'bluetoothDisconnected': return 'earpiece';
    default: return null;
  }
}
```

Then `_onAudioRouteEvent` calls `mapAudioRouteEvent(event)` and applies it via setState.

### 2. Real-device smoke test (mandatory before declaring fix complete)

Hardware needed: one Android phone (test device `78c0742f`) + Bluetooth headphones (e.g., AirPods, any BT headset) + a second device for the remote party.

Steps:
1. Build dev APK and install on `78c0742f`.
2. Log in as `integration_test@taler-test.com`. Make a call to `integration_test_2@...` (which is logged in on a second device — emulator or physical).
3. Without BT connected, confirm the remote side hears you fine.
4. Mid-call, turn on BT headphones (pair if needed, but they should auto-connect if previously paired).
5. **Assertion 1:** the BT indicator in the call screen UI lights up automatically (no tap).
6. **Assertion 2:** the remote party reports your voice is now coming through clearly — not muffled.
7. Disconnect BT (turn them off).
8. **Assertion 3:** UI reverts to earpiece indicator. Voice continues normally on phone earpiece + mic.

If Assertion 2 fails (remote still says voice is muffled even though BT indicator is on), the SCO channel did not actually activate — investigate further (likely Bluetooth permission, or device-specific quirk).

### 3. Existing test suite

`flutter test` must remain at 439/439 (no regressions).

## Branch & Commit

- Branch: `dev` (per project rule).
- Expect ~3-5 commits: spec, plan, native impl, Flutter impl, test.

## Out of Scope

- iOS audio session changes (no current user complaint on iOS).
- A "remember user preference" memory (auto-switch will override manual selection — accepted trade-off).
- Wired headphone auto-detection (the existing `getAudioOutputs` call from Flutter already exposes the wired state on demand; not a current pain point).
- BT connect-before-call path (existing `setAudioOutput("earpiece")` at call start handles audio focus, but doesn't auto-route to already-connected BT). Mark as known follow-up if real-device smoke shows the issue.

## References

- Existing audio MethodChannel: [AppDelegate.swift:64-173](ios/Runner/AppDelegate.swift#L64-L173) (iOS), [MainActivity.kt:117-310](android/app/src/main/kotlin/tirol/taler/taler_id_mobile/MainActivity.kt#L117-L310) (Android)
- Existing `setAudioOutput("bluetooth")` handler: [MainActivity.kt:186-190](android/app/src/main/kotlin/tirol/taler/taler_id_mobile/MainActivity.kt#L186-L190)
- Audio output state in Flutter: [voice_call_screen.dart:69](lib/features/voice/presentation/screens/voice_call_screen.dart#L69), [voice_call_screen.dart:2470-2490](lib/features/voice/presentation/screens/voice_call_screen.dart#L2470-L2490)
- Android docs: `AudioManager.registerAudioDeviceCallback` (API 23), `AudioDeviceInfo.TYPE_BLUETOOTH_SCO`, `BluetoothHeadset` profile

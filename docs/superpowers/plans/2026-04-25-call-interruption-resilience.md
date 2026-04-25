# Call Interruption Resilience Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Конфигурировать per-call audio session так, чтобы внешние VoIP-звонки (WhatsApp/Telegram) не прерывали активный TalerID-разговор; при невозможности mix — играть 3 beep'а локально как сигнал.

**Architecture:** Per-call native config через method channel `taler_id/audio` (уже существует). iOS — `AVAudioSession` с `.mixWithOthers`. Android — `AudioFocusRequest` с `AUDIOFOCUS_GAIN_TRANSIENT_MAY_DUCK`. Flutter вызывает `enableCallAudioMix` после `room.connect()` и `disableCallAudioMix` в начале `_hangUpInner()`.

**Tech Stack:** Swift (iOS), Kotlin (Android, minSdk 24), Flutter MethodChannel.

**Spec:** `docs/superpowers/specs/2026-04-25-call-interruption-resilience-design.md`

**Branch:** `dev` (мобилка `~/Downloads/taler_id_mobile`).

**Verified anchors (current code state):**
- iOS `AppDelegate.swift`: MethodChannel `taler_id/audio` at line 26, handler at line 30, `switch call.method` at line 32, last case before default at line 118, default at line 125, closing brace at line 128.
- Android `MainActivity.kt` at `android/app/src/main/kotlin/tirol/taler/taler_id_mobile/MainActivity.kt`: minSdk **24**, MethodChannel at line 136, `when (call.method)` at line 139, last case at line 243, default `else -> result.notImplemented()` at line 244, closing brace at line 246. Existing focus listener variable is `focusListener`.
- Flutter `voice_call_screen.dart`: `_audioChannel = MethodChannel('taler_id/audio')` at line 199, `_room!.connect(...)` await at line 634, `Future<void> _hangUpInner(CallStateService cs)` at line 2643.

---

## Task 1: iOS — add `enableCallAudioMix` / `disableCallAudioMix`

**Files:**
- Modify: `/Users/dmitry/Downloads/taler_id_mobile/ios/Runner/AppDelegate.swift` (cases in switch at lines 32–125 area; private methods can go anywhere in `AppDelegate` class).

- [ ] **Step 1: Verify line numbers haven't shifted**

```bash
cd /Users/dmitry/Downloads/taler_id_mobile && grep -nE 'taler_id/audio|switch call\.method|setMethodCallHandler|case "[a-zA-Z]+":|default:' ios/Runner/AppDelegate.swift | head -25
```

If line numbers near 30–128 differ from this plan, adjust insertion points accordingly. The handler is at the line where `setMethodCallHandler { call, result in` appears; the switch right after; cases inside; default last; closing brace at end.

- [ ] **Step 2: Insert two new cases in the switch**

In the switch block (around line 32–125), find the `default: result(FlutterMethodNotImplemented)` line. Insert these two cases JUST BEFORE the `default:`:

```swift
        case "enableCallAudioMix":
            self.enableCallAudioMix()
            result(nil)
        case "disableCallAudioMix":
            self.disableCallAudioMix()
            result(nil)
```

(Indentation must match neighboring `case` lines exactly — Swift's `case` indentation in this file is 8 spaces. Adjust if file uses tabs or different spacing.)

- [ ] **Step 3: Add the two private methods**

At the end of the `AppDelegate` class (just before the final `}` of the class), add:

```swift
    /// Configure AVAudioSession for active call: allow mixing with other apps' audio
    /// (WhatsApp/Telegram VoIP) so their incoming call doesn't preempt ours.
    private func enableCallAudioMix() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(
                .playAndRecord,
                mode: .voiceChat,
                options: [
                    .mixWithOthers,
                    .allowBluetooth,
                    .allowBluetoothA2DP,
                    .defaultToSpeaker,
                ]
            )
            try session.setActive(true, options: .notifyOthersOnDeactivation)
            NSLog("[CallAudioMix] enabled (mixWithOthers + voiceChat)")
        } catch {
            NSLog("[CallAudioMix] enable failed: \(error)")
        }
    }

    /// Revert AVAudioSession to default for non-call app behavior.
    private func disableCallAudioMix() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.soloAmbient)
            try session.setActive(false, options: .notifyOthersOnDeactivation)
            NSLog("[CallAudioMix] disabled (reverted to soloAmbient)")
        } catch {
            NSLog("[CallAudioMix] disable failed: \(error)")
        }
    }
```

- [ ] **Step 4: Verify Xcode project compiles**

This file changes are Swift; compilation can only be verified via `flutter build ios` (slow) or `xcodebuild -project ios/Runner.xcodeproj -scheme Runner -sdk iphonesimulator build`. Do a quick syntax sanity check by ensuring the `import AVFoundation` is at the top of the file (it should already be, since `handleAudioInterruption` exists). Run:

```bash
grep -n "import AVFoundation\|import AVKit" /Users/dmitry/Downloads/taler_id_mobile/ios/Runner/AppDelegate.swift | head -3
```

If `AVFoundation` is not imported, add `import AVFoundation` after the existing imports at the top of the file.

- [ ] **Step 5: Commit**

```bash
cd /Users/dmitry/Downloads/taler_id_mobile && git add ios/Runner/AppDelegate.swift && git commit -m "feat(voice/ios): add enableCallAudioMix/disableCallAudioMix for VoIP coexistence"
```

---

## Task 2: Android — add `enableCallAudioMix` / `disableCallAudioMix` with API 24 fallback

**Files:**
- Modify: `/Users/dmitry/Downloads/taler_id_mobile/android/app/src/main/kotlin/tirol/taler/taler_id_mobile/MainActivity.kt` (cases in `when` at lines 139–244 area; field + methods can go anywhere in the class).

- [ ] **Step 1: Verify line numbers and existing focus listener**

```bash
cd /Users/dmitry/Downloads/taler_id_mobile && grep -nE 'taler_id/audio|when \(call\.method\)|"[a-zA-Z]+" ->|else -> result\.notImplemented|focusListener' android/app/src/main/kotlin/tirol/taler/taler_id_mobile/MainActivity.kt | head -30
```

Confirm:
- `when (call.method)` exists with `else -> result.notImplemented()` at the end
- `focusListener` is the existing `AudioManager.OnAudioFocusChangeListener?` field

If `focusListener` is named differently (e.g. `audioFocusChangeListener`, `mFocusChangeListener`), use the actual name in step 3.

- [ ] **Step 2: Insert two new cases in the `when` block**

Find `else -> result.notImplemented()` in the `when` block. Insert these two cases JUST BEFORE the `else`:

```kotlin
                "enableCallAudioMix" -> {
                    enableCallAudioMix()
                    result.success(null)
                }
                "disableCallAudioMix" -> {
                    disableCallAudioMix()
                    result.success(null)
                }
```

(Indentation must match neighboring cases — typically 16 spaces (4 nesting levels × 4) in Kotlin.)

- [ ] **Step 3: Add field + two methods to the class**

Find a sensible location in the class — e.g. near the existing `focusListener` field or near the audio-related methods. Add:

```kotlin
    private var callAudioFocusRequest: AudioFocusRequest? = null

    /// Request audio focus in mix-respecting mode so external VoIP apps
    /// (WhatsApp/Telegram) can ring without preempting our LiveKit audio.
    private fun enableCallAudioMix() {
        val audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val attrs = AudioAttributes.Builder()
                .setUsage(AudioAttributes.USAGE_VOICE_COMMUNICATION)
                .setContentType(AudioAttributes.CONTENT_TYPE_SPEECH)
                .build()
            val request = AudioFocusRequest.Builder(AudioManager.AUDIOFOCUS_GAIN_TRANSIENT_MAY_DUCK)
                .setAudioAttributes(attrs)
                .setAcceptsDelayedFocusGain(true)
                .setWillPauseWhenDucked(false)
                .also { b -> focusListener?.let { b.setOnAudioFocusChangeListener(it) } }
                .build()
            val outcome = audioManager.requestAudioFocus(request)
            if (outcome == AudioManager.AUDIOFOCUS_REQUEST_GRANTED ||
                outcome == AudioManager.AUDIOFOCUS_REQUEST_DELAYED) {
                callAudioFocusRequest = request
                Log.i("CallAudioMix", "enabled (gain=$outcome, may_duck=true)")
            } else {
                Log.w("CallAudioMix", "enable failed: outcome=$outcome")
            }
        } else {
            // API 24-25 fallback: deprecated API
            @Suppress("DEPRECATION")
            val outcome = audioManager.requestAudioFocus(
                focusListener,
                AudioManager.STREAM_VOICE_CALL,
                AudioManager.AUDIOFOCUS_GAIN_TRANSIENT_MAY_DUCK,
            )
            Log.i("CallAudioMix", "enabled via deprecated API (outcome=$outcome)")
        }
    }

    /// Release the call audio focus request so the app stops mixing with others.
    private fun disableCallAudioMix() {
        val audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val req = callAudioFocusRequest
            if (req != null) {
                audioManager.abandonAudioFocusRequest(req)
                callAudioFocusRequest = null
                Log.i("CallAudioMix", "disabled")
            }
        } else {
            @Suppress("DEPRECATION")
            audioManager.abandonAudioFocus(focusListener)
            Log.i("CallAudioMix", "disabled via deprecated API")
        }
    }
```

If `focusListener` is named differently in this codebase (per step 1's grep result), substitute the correct name.

- [ ] **Step 4: Verify imports**

```bash
grep -nE 'import android\.media\.AudioFocusRequest|import android\.media\.AudioAttributes|import android\.os\.Build|import android\.util\.Log' /Users/dmitry/Downloads/taler_id_mobile/android/app/src/main/kotlin/tirol/taler/taler_id_mobile/MainActivity.kt
```

If any of these are missing, add them at the top of the file:

```kotlin
import android.media.AudioFocusRequest
import android.media.AudioAttributes
import android.os.Build
import android.util.Log
```

- [ ] **Step 5: Verify Kotlin compiles via Gradle**

```bash
cd /Users/dmitry/Downloads/taler_id_mobile && (flutter analyze android/ 2>&1 | tail -5) || true
```

Flutter analyze doesn't deeply analyze native code; the real check is at build time. We'll verify in Task 4 (build APK).

- [ ] **Step 6: Commit**

```bash
git add android/app/src/main/kotlin/tirol/taler/taler_id_mobile/MainActivity.kt && git commit -m "feat(voice/android): add enableCallAudioMix/disableCallAudioMix (API 24 fallback)"
```

---

## Task 3: Flutter — wire `enableCallAudioMix` and `disableCallAudioMix`

**Files:**
- Modify: `/Users/dmitry/Downloads/taler_id_mobile/lib/features/voice/presentation/screens/voice_call_screen.dart`

- [ ] **Step 1: Verify anchors**

```bash
cd /Users/dmitry/Downloads/taler_id_mobile && grep -nE '_audioChannel = MethodChannel|_room!\\.connect|Future<void> _hangUpInner' lib/features/voice/presentation/screens/voice_call_screen.dart | head -10
```

Confirm: `_audioChannel = MethodChannel('taler_id/audio')` at line 199, `_room!.connect(...)` at line 634, `_hangUpInner` at line 2643.

- [ ] **Step 2: Add `enableCallAudioMix` call AFTER `room.connect()`**

Read 5 lines after line 634 to understand the surrounding context:

```bash
sed -n '630,650p' /Users/dmitry/Downloads/taler_id_mobile/lib/features/voice/presentation/screens/voice_call_screen.dart
```

Find the line `await _room!.connect(...)` (likely a multi-line call ending with `;`). On the line immediately AFTER the `connect(...);` statement, add:

```dart
      try {
        await _audioChannel.invokeMethod('enableCallAudioMix');
      } catch (e) {
        debugPrint('[CallAudio] enableCallAudioMix failed: $e');
      }
```

Match the existing indentation (likely 6 spaces, inside an async method).

- [ ] **Step 3: Add `disableCallAudioMix` call as FIRST line of `_hangUpInner`**

Find `Future<void> _hangUpInner(CallStateService cs) async {` at line 2643. The next line (line 2644 or a few later, depending on whether the body opens immediately) is the first body line.

```bash
sed -n '2643,2660p' /Users/dmitry/Downloads/taler_id_mobile/lib/features/voice/presentation/screens/voice_call_screen.dart
```

Insert these lines as the FIRST executable code in the body (immediately after the opening `{`):

```dart
    try {
      await _audioChannel.invokeMethod('disableCallAudioMix');
    } catch (e) {
      debugPrint('[CallAudio] disableCallAudioMix failed: $e');
    }
```

Match the existing indentation (likely 4 spaces, method body).

- [ ] **Step 4: Verify analyze + tests**

```bash
flutter analyze lib/features/voice/presentation/screens/voice_call_screen.dart 2>&1 | tail -10
flutter test 2>&1 | tail -3
```

Expected: no NEW errors in `voice_call_screen.dart`. Pre-existing warnings/infos are fine. All tests still pass.

- [ ] **Step 5: Commit**

```bash
git add lib/features/voice/presentation/screens/voice_call_screen.dart && git commit -m "feat(voice): invoke enableCallAudioMix/disableCallAudioMix at call boundaries"
```

---

## Task 4: Push + build APK + iOS dev

**Files:** N/A — deployment.

- [ ] **Step 1: Push to origin**

```bash
cd /Users/dmitry/Downloads/taler_id_mobile && git push origin dev 2>&1 | tail -3
```

- [ ] **Step 2: Build dev APK on remote build server**

```bash
ssh dvolkov@138.124.61.221 'cd ~/taler_id_mobile && git checkout -- lib/l10n/ android/ ios/ 2>/dev/null; git fetch origin && git checkout dev && git pull --ff-only && flutter pub get 2>&1 | tail -3 && flutter build apk --flavor dev --release -t lib/main_dev.dart --dart-define=FLAVOR=dev --dart-define=BASE_URL=https://staging.id.taler.tirol 2>&1 | tail -8'
```

Expected: APK built at `~/taler_id_mobile/build/app/outputs/flutter-apk/app-dev-release.apk`.

If the Android build fails on the new `MainActivity.kt` code, the error will be in the output. Common issues: wrong `focusListener` variable name (fix in Task 2 step 3), missing import (Task 2 step 4).

- [ ] **Step 3: Publish APK**

```bash
ssh dvolkov@138.124.61.221 'sudo cp ~/taler_id_mobile/build/app/outputs/flutter-apk/app-dev-release.apk /var/www/downloads/taler-id-dev.apk && sudo chmod 644 /var/www/downloads/taler-id-dev.apk && ls -la /var/www/downloads/taler-id-dev.apk'
```

Expected: APK in place at https://id.taler.tirol/download/taler-id-dev.apk.

- [ ] **Step 4 (iOS, optional, locally): build and run on physical device**

Symbol-only verification on simulator is OK but won't reproduce the real CallKit/VoIP behaviour we want to test. For full iOS smoke, a physical iPhone is required. From local Mac:

```bash
cd /Users/dmitry/Downloads/taler_id_mobile && flutter run --flavor dev -t lib/main_dev.dart --dart-define=FLAVOR=dev --dart-define=BASE_URL=https://staging.id.taler.tirol -d 00008101-000E21100202001E
```

If the device UDID has changed since CLAUDE.md was written, list devices first:
```bash
flutter devices
```

---

## Task 5: Manual smoke test (4 scenarios)

**Files:** N/A — manual verification.

Test on two physical devices (or one phone + one Android emulator + one third device for external calls). Login with `integration_test@taler-test.com` and `integration_test_2@taler-test.com`.

- [ ] **Scenario 1: Baseline TalerID call**

1. User A and User B start a TalerID voice call
2. Both speak for ~5 seconds, audio is bidirectional
3. Either party hangs up
4. Confirm audio worked normally on both sides

Pass criterion: voice quality unchanged from before this feature (we only added audio session config, must not regress).

- [ ] **Scenario 2: External VoIP during TalerID call (mix expected)**

1. User A and User B in active TalerID call
2. From a THIRD device, call User A on WhatsApp (or Telegram)
3. Observe on User A's phone:
   - TalerID audio continues uninterrupted (User A still hears User B; User B still hears User A)
   - WhatsApp's CallKit / notification UI appears on screen
   - 3 beeps from our app do NOT play (because mix worked → no `audioInterrupted` event)
4. User A declines WhatsApp call
5. Confirm TalerID call resumed without any audio glitch

Pass criterion: TalerID call does not break, no audio drops.

- [ ] **Scenario 3: PSTN call during TalerID call (preemption expected)**

1. User A and User B in active TalerID call
2. From a regular cellular phone, call User A's phone number (PSTN, not VoIP)
3. Observe on User A's phone:
   - `audioInterrupted` event fires (visible in beeps)
   - 3 beeps play locally
   - TalerID audio briefly interrupted (User B doesn't hear User A; User A doesn't hear User B for the interruption duration)
4. User A declines the PSTN call
5. Confirm `audioResumed` triggered and TalerID audio is restored

Pass criterion: 3 beeps play, then call recovers (worst case TalerID call drops, but recovery via existing `_restoreAudioAfterInterruption()` is acceptable).

- [ ] **Scenario 4: Revert sanity**

1. User A starts a TalerID call → ends it
2. After hangup, open YouTube (or any music app)
3. Play a video / song
4. Confirm audio plays normally — NOT ducked, NOT mixed with anything

Pass criterion: After call end, app's audio session is back to default; no leftover mix-mode behavior.

- [ ] **Step 5: Backend regression**

```bash
cd /Users/dmitry/Downloads/taler_id_tests && npm test && npm run test:files
```

Expected: existing 35/35 + 12/12 tests pass.

---

## Task 6: PROD deploy — gated

**Do not run automatically. Wait for explicit user approval ("deploy to PROD" or similar).**

- [ ] **Step 1: Wait for explicit user OK for PROD**

- [ ] **Step 2: Merge `dev` → `main` on mobile repo**

```bash
cd /Users/dmitry/Downloads/taler_id_mobile && git checkout main && git pull && git merge dev --no-ff -m "Merge dev: call interruption resilience" && git push origin main
```

- [ ] **Step 3: Build prod APK on PROD server**

```bash
ssh dvolkov@138.124.61.221 'cd ~/taler_id_mobile && git checkout main && git pull && flutter pub get && flutter build apk --flavor prod --release --dart-define=FLAVOR=prod && sudo cp build/app/outputs/flutter-apk/app-prod-release.apk /var/www/downloads/taler-id.apk && sudo chmod 644 /var/www/downloads/taler-id.apk'
```

- [ ] **Step 4: Build iOS prod IPA + TestFlight upload**

Locally on Mac (per CLAUDE.md):
```bash
cd /Users/dmitry/Downloads/taler_id_mobile && flutter build ipa --release --export-options-plist ios/ExportOptions.plist
xcrun altool --upload-app --type ios -f build/ios/ipa/*.ipa --apiKey J3P22V4URD --apiIssuer 44b87272-3052-40ea-a48a-6c6f88a2df11
```

- [ ] **Step 5: PROD regression**

```bash
cd /Users/dmitry/Downloads/taler_id_tests && npm run test:prod && npm run test:files:prod
```

Expected: green.

- [ ] **Step 6: Manual PROD smoke (Scenario 2 from Task 5 minimum)**

Re-run Scenario 2 (external VoIP non-preemption) against `id.taler.tirol` PROD with real users.

---

## Appendix — Files summary

### Created
None.

### Modified
- `ios/Runner/AppDelegate.swift` (Task 1: 2 cases + 2 methods)
- `android/app/src/main/kotlin/tirol/taler/taler_id_mobile/MainActivity.kt` (Task 2: 2 cases + 1 field + 2 methods + 4 imports)
- `lib/features/voice/presentation/screens/voice_call_screen.dart` (Task 3: 2 try/catch blocks of 3-5 lines each)

### Backend
**No changes.** All audio session manipulation is on the device.

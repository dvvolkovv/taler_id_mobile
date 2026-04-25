# Call Interruption Resilience — Design Spec

**Date:** 2026-04-25
**Scope:** Taler ID mobile — TalerID звонок не должен прерываться при входящем звонке от WhatsApp/Telegram. Если внешний VoIP-звонок всё-таки забирает audio — короткий звуковой сигнал (3 beep'а) пользователю и восстановление при отбое внешнего звонка.
**Deploy target:** только DEV (мобилка ветка `dev`). PROD — только по явному указанию.

## 1. Цель и пользовательская история

Из исходного запроса пользователя:
> При разговоре внутри TalerID идёт параллельный звонок по WhatsApp или Telegram, и он перебивает сейчас связь. Должно быть так: внешний звонок просто 3-мя бипами и всё, мы разговариваем дальше по TalerID.

**Текущее поведение (research findings):**
- Audio session настраивается LiveKit/WebRTC в `.playAndRecord` БЕЗ `.mixWithOthers` (iOS) и через exclusive `AUDIOFOCUS_GAIN` (Android) → любая audio-конкурирующая активность прерывает наш звонок
- На interruption iOS/Android уже шлёт `audioInterrupted` event в Flutter (через MethodChannel `taler_id/audio`)
- Flutter handler `_onNativeAudioEvent` уже играет 3 beep'а через `_playInterruptionBeeps()` (`voice_call_screen.dart:391-398, 453-463`)
- Но: TalerID audio не восстанавливается полноценно если внешний звонок длительный, и сама фича "не дать прервать" отсутствует

**User story:** как пользователь TalerID, я разговариваю по TalerID, и в это время мне звонят по WhatsApp/Telegram. Я хочу:
- продолжать TalerID-разговор без прерывания
- получить short audio cue ("пиик-пиик-пиик") что есть параллельный звонок (если ОС всё же прервала наш audio)
- после dismiss/decline внешнего звонка — мгновенно вернуться к разговору

**Out of scope (на эту итерацию):**
- Системный (PSTN) звонок: hardware-level preemption на уровне модема, никакой audio-конфигурацией не fix'ится. Документируем как known limitation
- CXCallObserver/TelephonyCallback для precise detection всех external calls — overkill (User chose option A: beep только когда наш audio реально прерывается)
- UI-индикатор external call (toast/badge) — не запрашивался
- Re-apply mix-config при LiveKit reconnect — добавляется только если smoke выявит проблему

## 2. Архитектурные решения

- **Подход:** per-call audio session reconfiguration (изоляция изменений в lifecycle активного звонка). Вне звонка app возвращается к default behavior
- **iOS:** `AVAudioSession.setCategory(.playAndRecord, mode: .voiceChat, options: [.mixWithOthers, .allowBluetooth, .allowBluetoothA2DP, .defaultToSpeaker])` при старте звонка; revert на `.soloAmbient` при завершении
- **Android:** custom `AudioFocusRequest` с `AUDIOFOCUS_GAIN_TRANSIENT_MAY_DUCK` + `setWillPauseWhenDucked(false)` при старте; abandon focus при завершении. Переиспользуем существующий `OnAudioFocusChangeListener` (он уже шлёт `audioInterrupted` event)
- **Flutter:** добавляем 2 method channel-вызова в `voice_call_screen.dart` — `enableCallAudioMix` после `room.connect()`, `disableCallAudioMix` в `_hangUpInner()`. Существующий `_onNativeAudioEvent('audioInterrupted')` НЕ меняется — он остаётся fallback'ом для случаев когда mix не сработал (агрессивный VoIP-app)
- **Beep trigger:** оставляем существующий — `audioInterrupted` event. Если mix сработал → нет interruption → нет beep'ов → нет проблем. Если mix не сработал → есть interruption → играем 3 beep'а как сигнал юзеру
- **Backend = 0 изменений**

## 3. Архитектура и поток

```
voice_call_screen.dart — старт звонка
  ├─ room.connect(...)              ← LiveKit поднимает audio session с default config
  └─ _audioChannel.invokeMethod('enableCallAudioMix')
                                    ↓
       ├──[iOS]──  AVAudioSession.setCategory(.playAndRecord, mode: .voiceChat,
       │             options: [.mixWithOthers, .allowBluetooth,
       │                       .allowBluetoothA2DP, .defaultToSpeaker])
       │           AVAudioSession.setActive(true, options: .notifyOthersOnDeactivation)
       │
       └──[Android]── AudioFocusRequest.Builder()
                       .setAudioAttributes(USAGE_VOICE_COMMUNICATION)
                       .setFocusGain(AUDIOFOCUS_GAIN_TRANSIENT_MAY_DUCK)
                       .setWillPauseWhenDucked(false)
                       .setAcceptsDelayedFocusGain(true)
                       .setOnAudioFocusChangeListener(audioFocusChangeListener)
                       .build()
                     audioManager.requestAudioFocus(request)

WhatsApp/Telegram звонит во время TalerID call:
  Случай "хороший" — `.mixWithOthers` соблюдается:
    • WhatsApp ringtone играет рядом с нашим audio
    • Наш LiveKit audio НЕ прерывается
    • Юзер видит CallKit/notification UI
    • Никакого `audioInterrupted` event → beep'ов нет
    • Юзер может decline или dismiss external call → разговор не прерывался

  Случай "плохой" — внешний app грабит focus агрессивно:
    • Наш audio session получает interruption
    • OS шлёт `audioInterrupted` через method channel
    • Flutter: _onNativeAudioEvent → _playInterruptionBeeps() (3 beep'а локально)
    • LiveKit briefly paused
    • Когда внешний звонок завершается → audioResumed event
    • Flutter: _restoreAudioAfterInterruption() (уже работает)

voice_call_screen.dart — завершение звонка:
  _hangUpInner()
    ├─ _audioChannel.invokeMethod('disableCallAudioMix')   ← FIRST
    │       ├──[iOS]── AVAudioSession.setCategory(.soloAmbient); setActive(false)
    │       └──[Android]── audioManager.abandonAudioFocusRequest(callAudioFocusRequest)
    └─ room.disconnect()
```

## 4. Mobile native — конкретные изменения

### 4.1. iOS (`ios/Runner/AppDelegate.swift`)

В существующем `audioChannel.setMethodCallHandler {…}` block (lines 26-129 per research) добавить два case:

```swift
case "enableCallAudioMix":
    self.enableCallAudioMix()
    result(nil)
case "disableCallAudioMix":
    self.disableCallAudioMix()
    result(nil)
```

Добавить в класс `AppDelegate` два private метода:

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

Существующий `handleAudioInterruption()` (lines 247-287) — без изменений.

### 4.2. Android (`android/app/src/main/kotlin/.../MainActivity.kt`)

В существующем `audioChannel.setMethodCallHandler { call, result -> … }` block (lines 285+ per research) добавить два case:

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

Добавить поле + два метода в class `MainActivity`:

```kotlin
private var callAudioFocusRequest: AudioFocusRequest? = null

/// Request audio focus in mix-respecting mode so external VoIP apps
/// (WhatsApp/Telegram) can ring without preempting our LiveKit audio.
private fun enableCallAudioMix() {
    val audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
    val attrs = AudioAttributes.Builder()
        .setUsage(AudioAttributes.USAGE_VOICE_COMMUNICATION)
        .setContentType(AudioAttributes.CONTENT_TYPE_SPEECH)
        .build()
    val request = AudioFocusRequest.Builder(AudioManager.AUDIOFOCUS_GAIN_TRANSIENT_MAY_DUCK)
        .setAudioAttributes(attrs)
        .setAcceptsDelayedFocusGain(true)
        .setWillPauseWhenDucked(false)
        .setOnAudioFocusChangeListener(audioFocusChangeListener)
        .build()
    val outcome = audioManager.requestAudioFocus(request)
    if (outcome == AudioManager.AUDIOFOCUS_REQUEST_GRANTED ||
        outcome == AudioManager.AUDIOFOCUS_REQUEST_DELAYED) {
        callAudioFocusRequest = request
        Log.i("CallAudioMix", "enabled (gain=$outcome, may_duck=true)")
    } else {
        Log.w("CallAudioMix", "enable failed: outcome=$outcome")
    }
}

/// Release the call audio focus request so the app stops mixing with others.
private fun disableCallAudioMix() {
    val audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
    val req = callAudioFocusRequest ?: return
    audioManager.abandonAudioFocusRequest(req)
    callAudioFocusRequest = null
    Log.i("CallAudioMix", "disabled")
}
```

`AudioFocusRequest.Builder` доступен с **API 26 (Android 8.0)**. Если minSdk проекта < 26, добавить fallback на старый deprecated API:
```kotlin
@Suppress("DEPRECATION")
audioManager.requestAudioFocus(audioFocusChangeListener,
    AudioManager.STREAM_VOICE_CALL,
    AudioManager.AUDIOFOCUS_GAIN_TRANSIENT_MAY_DUCK)
```
Нужно проверить minSdk на старте задачи — если 26+, fallback не нужен.

Существующий `OnAudioFocusChangeListener` (lines 295-315) — без изменений; переиспользуется.

### 4.3. Flutter (`lib/features/voice/presentation/screens/voice_call_screen.dart`)

Реиспользуем существующий MethodChannel `taler_id/audio` (где уже живут `audioInterrupted`/`audioResumed`). Если поле `_audioChannel` ещё не объявлено — объявить:

```dart
static const MethodChannel _audioChannel = MethodChannel('taler_id/audio');
```

После успешного `room.connect(...)` (в `_setupCall()` или эквивалентном месте — найти точное место при реализации):

```dart
try {
  await _audioChannel.invokeMethod('enableCallAudioMix');
} catch (e) {
  debugPrint('[CallAudio] enableCallAudioMix failed: $e');
}
```

В `_hangUpInner()` (строка 2643 per research) — ПЕРВЫМ делом, до `room.disconnect()`:

```dart
try {
  await _audioChannel.invokeMethod('disableCallAudioMix');
} catch (e) {
  debugPrint('[CallAudio] disableCallAudioMix failed: $e');
}
```

Существующий `_onNativeAudioEvent` handler — без изменений. Существующий `_playInterruptionBeeps()` — без изменений.

## 5. Edge cases

| Сценарий | Поведение |
|---|---|
| TalerID звонок → WhatsApp звонит, mix сработал | TalerID audio продолжается, WhatsApp ringtone играет mix'нуто. Юзер видит CallKit UI. Никакого `audioInterrupted` event → beep'ов нет. Decline/dismiss → разговор не прерывался |
| TalerID звонок → WhatsApp звонит, mix НЕ сработал | `audioInterrupted` → 3 beep'а (через существующий handler). LiveKit briefly paused. После dismiss/decline WhatsApp → `audioResumed` → audio восстановлен через `_restoreAudioAfterInterruption()` |
| TalerID → answer'нул WhatsApp | WhatsApp call берёт audio полностью. TalerID audio полностью прерывается. Когда WhatsApp call закончится → `audioResumed` → восстановление. Это ожидаемо — юзер сам выбрал ответить |
| TalerID → системный (PSTN) звонок | Hardware preemption (модем уровень), наш mix не помогает. `audioInterrupted` → 3 beep'а. Worst case — TalerID call lost. Documented as platform limitation |
| `enableCallAudioMix` failed (errored) | Log + продолжить. Звонок работает в default mode, mix не активирован. Behavior = current (interrupt прерывает, не наша вина) |
| `disableCallAudioMix` failed (errored) | Log. App остаётся в mix-mode до перезапуска или следующего звонка. Worst case — играет media mix'нуто с другим audio. Не критично |
| iOS lock screen во время звонка | Существующий `_reactivateAudio()` (line 2776 per research) работает. Наш mix-config сохраняется, т.к. session active |
| Android API < 26 | Fallback на deprecated `requestAudioFocus(listener, STREAM_VOICE_CALL, GAIN_TRANSIENT_MAY_DUCK)`. Поведение идентичное |
| AI Twin звонок | Mix-config применяется идентично. AI Twin не знает о наших audio session changes — работает с тем, что system дал |
| LiveKit reconnect mid-call | Если LiveKit перезапрашивает audio focus → наш mix может быть перезаписан. На первой итерации игнорируем; smoke выявит — добавим re-apply |
| Hangup из notification (background) | Существующий VoIP push hangup flow вызывает `_hangUp` → `_hangUpInner` → наш `disableCallAudioMix` отрабатывает. OK |
| User в TalerID → играет музыку в другом app до звонка | Music play in default mode (single-focus). При TalerID start → enableCallAudioMix → mix → music может продолжать тише (duck'нуто). После hangup → disableCallAudioMix → возвращаемся в `.soloAmbient`, music восстанавливается громкость |

## 6. Тесты

### Юнит/integration

**Юнит-тестов нет.** Это native-bridge feature, юнит-тестируется только через native unit tests (XCTest / JUnit), что излишне для одной фичи. Существующие 201 mobile тестов должны остаться зелёными после наших изменений в `voice_call_screen.dart` (изменения изолированы).

### Manual smoke (обязательный перед DEV-релизом)

Тестируется на двух физических устройствах. Тестовые аккаунты `integration_test@taler-test.com` и `integration_test_2@taler-test.com`.

1. **Baseline:** оба юзера в TalerID звонке, говорят 5 сек, hangup. Звук обе стороны OK
2. **Внешний VoIP (mix expected):** TalerID звонок активен. Третье устройство звонит по WhatsApp/Telegram на одного из юзеров. Ожидание:
   - TalerID audio НЕ прерывается
   - На экране — CallKit/notification UI WhatsApp
   - 3 beep'а от нашего app не играют
   - Decline → разговор продолжается
3. **PSTN (preemption expected):** TalerID звонок активен. Звонишь обычным голосовым.
   - `audioInterrupted` → 3 beep'а
   - TalerID audio прерывается
   - Dismiss → `audioResumed` → восстановление
4. **Revert sanity:** в TalerID звонке hangup красной кнопкой. Открываем YouTube, звук нормальный (не mix'ится). Подтверждает что `disableCallAudioMix` сработал

### Existing automated regression

Стандартный пакет из CLAUDE.md (9 тестов) — должен остаться зелёным.

## 7. Деплой

**Только мобильные изменения. 0 backend.**

1. Коммиты в `dev` (push)
2. Сборка `taler-id-dev.apk` на 138.124.61.221
3. iOS: physical device build (через `flutter run --release` или TestFlight dev) — симулятор не воспроизводит реальный CallKit/VoIP behavior
4. Manual smoke 4-точечный (раздел 6)
5. PROD — **только по явному указанию**

## 8. Критерии готовности

- [ ] Сборка APK + iOS dev OK
- [ ] Baseline TalerID звонок работает обе стороны
- [ ] Внешний VoIP-звонок не прерывает TalerID (mix-сценарий) ИЛИ играет 3 beep'а и восстанавливается (fallback-сценарий)
- [ ] `disableCallAudioMix` срабатывает на hangup, не оставляет app в mix-mode после звонка
- [ ] Existing 201 mobile тестов зелёные
- [ ] Existing API regression зелёный

## 9. Future work (вне этой итерации)

- Native CXCallObserver (iOS) и TelephonyCallback (Android) для детектирования external calls независимо от audio mix outcome → точнее UX (всегда beep при попытке external call)
- Re-apply mix-config при LiveKit reconnect (если smoke выявит проблему)
- UI-индикатор "external call detected" поверх 3 beep'ов
- Тестируемость: добавить native unit-tests (XCTest для AppDelegate enable/disable, JUnit для MainActivity audio focus request)

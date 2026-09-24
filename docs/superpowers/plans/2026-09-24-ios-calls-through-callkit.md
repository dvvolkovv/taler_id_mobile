# iOS: разговор живёт в CallKit до конца — план реализации

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** на iPhone звонок WhatsApp или сотовый во время нашего разговора приходит ожиданием вызова и больше не отбирает у нас звук; после «Удержать и ответить» разговор возвращается сам.

**Architecture:** каждый разговор на экране звонка остаётся в CallKit, пока жив. Звуком управляет CallKit, WebRTC переходит в ручной режим (`RTCAudioSession.useManualAudio`) и следует за `didActivate`/`didDeactivate`. На Dart реестр `SystemCallRegistry` связывает комнаты с UUID CallKit, фильтрует события по UUID и делает автовозврат. Плагин `flutter_callkit_incoming` берётся в репозиторий и чинится в семи местах.

**Tech Stack:** Flutter 3.38 / Dart 3, `flutter_callkit_incoming` 2.5.8 (правленая копия), `livekit_client` 2.4.1, WebRTC-SDK 125 (`RTCAudioSession`), Swift/CallKit, mocktail.

**Проект:** `docs/superpowers/specs/2026-09-24-ios-calls-through-callkit-design.md` — читать перед началом.

---

## Общие правила для исполнителя

- Работать в worktree `~/Downloads/taler_id_mobile/.worktrees/ios-callkit-calls` (ветка `fix/ios-callkit-calls`). Все пути ниже — от его корня. `cd` в него перед каждой командой.
- `flutter analyze` на репозитории чистым не бывает (~340 старых замечаний). Планка — **ноль новых замечаний в тронутых файлах**. Считать так: `flutter analyze <файл> 2>&1 | grep -cE "^\s*(error|warning) "`. База на `origin/dev` (2026-09-24): `voice_call_screen.dart` — **28**, `dashboard_screen.dart` — **2**, `notification_service.dart`, `main.dart`, `call_state_service.dart`, `call_kit*.dart` — **0**. После правки число не должно вырасти; новые файлы — 0.
- Тест `test/core/mesh/services/mesh_messaging_service_test.dart` («stale-session recovery») нестабилен под полным прогоном и падает без нашей вины; в одиночку проходит.
- Коммиты — по-русски в стиле репозитория (`fix(звонок): …`, `feat(звонок): …`), каждый заканчивается строкой `Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>`. Не пушить, не деплоить, не собирать релизы — это решает пользователь.
- Android по поведению не меняется. Любая новая ветка кода на Android обязана вести в старый путь.
- Задачи 0 и 20 требуют пользователя с телефонами: iPhone, второй телефон с Taler ID (DEV) и кто-то, кто позвонит в WhatsApp. Исполнитель готовит сборку и снимает логи, звонки делает пользователь.

## Карта файлов

| Файл | Что | Ответственность |
|---|---|---|
| `packages/flutter_callkit_incoming/**` | новый (копия 2.5.8) | плагин с правками P1–P7, только iOS-часть |
| `packages/flutter_callkit_incoming/PATCHES.md` | новый | список правок для переноса при обновлении |
| `pubspec.yaml`, `analysis_options.yaml` | правка | `dependency_overrides` на копию, исключение копии из анализа |
| `lib/core/platform/callkit_support.dart` | новый | `toCallkitId`, `isIosSimulator` (перенесены из `notification_service.dart`) |
| `lib/core/platform/call_kit.dart`, `call_kit_mobile.dart`, `call_kit_desktop.dart` | правка | `startCall`, `setCallConnected`, `setHeld`, `setMuted`, типы событий hold/mute/audio session; общие iOS-параметры звонка |
| `lib/core/platform/system_call_bridge.dart` | новый | Dart-сторона канала `taler_id/callkit_audio` |
| `lib/core/platform/system_call_registry.dart` | новый | реестр разговоров в CallKit, события, автовозврат |
| `lib/core/platform/call_audio_configuration.dart` | новый | `onConfigureNativeAudio` LiveKit на время разговора в CallKit |
| `lib/core/services/call_state_service.dart` | правка | микрофон на системном удержании; хуки «линия завершена» и «линия на удержании» |
| `ios/Runner/CallKitAudioBridge.swift` | новый | мост CallKit → WebRTC, набор управляемых UUID, «чужие звонки закончились» |
| `ios/Runner/AppDelegate.swift`, `ios/Runner.xcodeproj/project.pbxproj` | правка | делегат плагина, регистрация моста, VoIP-пуш, отключение старой машинерии |
| `lib/main.dart` | правка | подключение реестра до `runApp`, связка с `CallStateService` |
| `lib/features/voice/presentation/screens/voice_call_screen.dart` | правка | регистрация разговора, удержание, сброс, mute |
| `lib/features/dashboard/presentation/dashboard_screen.dart` | правка | диалог приёма, замена `endAllCalls()`, режим плашки |
| `lib/core/notifications/notification_service.dart` | правка | `call_cancelled` снимает только вызов своей комнаты |
| `lib/l10n/app_*.arb` + сгенерированные `app_localizations*.dart` | правка | две строки плашки удержания, 24 локали |
| `test/core/platform/*`, `test/core/call_state_service_test.dart` | новые/правка | юнит-тесты |

---

### Task 0: Проба на iPhone — ворота «идём / не идём»

Выбрасываемая ветка. Проверяет самое рискованное допущение до основной работы: разговор, оставленный в CallKit, со звуком WebRTC в ручном режиме, (а) звучит в обе стороны при приёме с заблокированного экрана, в баннере и при исходящем, (б) не прерывается звонком WhatsApp, который отклонили. Заодно выясняет, снимает ли iOS удержание сама (риск 2 проекта).

**Files (только на ветке `spike/ios-callkit-audio`, в `fix/ios-callkit-calls` не попадает):**
- Modify: `ios/Runner/AppDelegate.swift`
- Modify: `lib/core/platform/call_kit_mobile.dart`
- Modify: `lib/features/voice/presentation/screens/voice_call_screen.dart`

- [ ] **Step 1: Ветка пробы**

```bash
cd ~/Downloads/taler_id_mobile/.worktrees/ios-callkit-calls
git switch -c spike/ios-callkit-audio
```

- [ ] **Step 2: AppDelegate — WebRTC следует за CallKit, старое восстановление молчит**

В `ios/Runner/AppDelegate.swift` добавить `import WebRTC` после `import flutter_callkit_incoming`. В начало `handleAudioInterruption(_:)` вставить журналирование и выход:

```swift
    NSLog("[Spike] interruption userInfo=\(notification.userInfo ?? [:]) object=\(String(describing: notification.object))")
    return
```

В конец файла добавить:

```swift
extension AppDelegate: CallkitIncomingAppDelegate {
  func onAccept(_ call: Call, _ action: CXAnswerCallAction) {
    NSLog("[Spike] onAccept \(call.uuid) outgoing=\(call.isOutGoing)")
    try? AVAudioSession.sharedInstance().setCategory(.playAndRecord, mode: .voiceChat, options: [.allowBluetooth, .allowBluetoothA2DP])
    action.fulfill()
  }
  func onDecline(_ call: Call, _ action: CXEndCallAction) { action.fulfill() }
  func onEnd(_ call: Call, _ action: CXEndCallAction) { action.fulfill() }
  func onTimeOut(_ call: Call) {}
  func didActivateAudioSession(_ audioSession: AVAudioSession) {
    NSLog("[Spike] didActivate")
    let rtc = RTCAudioSession.sharedInstance()
    rtc.audioSessionDidActivate(audioSession)
    rtc.isAudioEnabled = true
    rtc.useManualAudio = true
  }
  func didDeactivateAudioSession(_ audioSession: AVAudioSession) {
    NSLog("[Spike] didDeactivate")
    let rtc = RTCAudioSession.sharedInstance()
    rtc.audioSessionDidDeactivate(audioSession)
    rtc.isAudioEnabled = false
  }
}
```

- [ ] **Step 3: Параметры CallKit**

В `lib/core/platform/call_kit_mobile.dart` в `IOSParams` поменять `audioSessionMode: 'default'` → `'voiceChat'`, `supportsHolding: false` → `true` и добавить `configureAudioSession: false,`.

- [ ] **Step 4: Экран звонка — не снимать звонок с CallKit, исходящий заводить в CallKit**

В `voice_call_screen.dart`:

1. Импорт: `import 'package:flutter_callkit_incoming/entities/entities.dart';` и `import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';`.
2. В `_initCall()` заменить
   ```dart
      if (widget.isIncoming) {
        await _restoreAudioAfterCallKit();
      }
   ```
   на
   ```dart
      if (widget.isIncoming && !Platform.isIOS) {
        await _restoreAudioAfterCallKit();
      } else if (Platform.isIOS) {
        try { await _room?.localParticipant?.setMicrophoneEnabled(true); } catch (_) {}
      }
   ```
3. В `_connect()` условие `if (widget.isIncoming) {` перед строкой `debugPrint('[AudDbg] incoming setup START …` заменить на `if (widget.isIncoming && !Platform.isIOS) {`.
4. В `_connect()` перед комментарием `// Play ringback tone for outgoing calls` вставить:
   ```dart
    if (Platform.isIOS && !widget.isIncoming) {
      try { await _audioChannel.invokeMethod('requestAudioFocus'); } catch (_) {}
      await FlutterCallkitIncoming.startCall(CallKitParams(
        id: const Uuid().v4(),
        nameCaller: widget.calleeName ?? 'Taler ID',
        appName: 'Taler ID',
        handle: widget.conversationId ?? 'taler',
        type: 0,
        ios: const IOSParams(supportsHolding: true, audioSessionMode: 'voiceChat', configureAudioSession: false, supportsVideo: false),
      ));
    }
   ```
5. Вызов `enableCallAudioMix` обернуть в `if (!Platform.isIOS) { … }`.

- [ ] **Step 5: Собрать на iPhone (profile — нужен для приёма при убитом приложении)**

```bash
flutter devices   # взять id iPhone 17 (Dmitry)
flutter run --profile --flavor dev -t lib/main_dev.dart \
  --dart-define=FLAVOR=dev --dart-define=BASE_URL=https://staging.id.taler.tirol \
  -d <iphone-id> 2>&1 | tee /tmp/spike-run.log
```
Expected: приложение установлено и запущено. Логи `[Spike]`, `[CallKit] event:` и `[AudDbg]` видны в выводе (NSLog — в Console.app с фильтром `Spike`, если `flutter run` их не показывает).

- [ ] **Step 6: Сценарии с пользователем**

Звонящий — второй телефон с Taler ID на DEV. Отмечать результат каждого пункта:

| # | Сценарий | Ожидание для «идём» |
|---|---|---|
| S1 | Приложение убито, экран заблокирован, входящий → «Ответить» в CallKit | звук в обе стороны; в логе `onAccept` → `didActivate` |
| S2 | Приложение открыто, входящий → «Ответить» в баннере CallKit | звук в обе стороны |
| S3 | Исходящий с iPhone, собеседник ответил | звук в обе стороны |
| S4 | Во время разговора звонят в WhatsApp → «Отклонить» | звук **ни на миг** не пропал; в логе нет `[Spike] interruption` с типом began |
| S5 | Во время разговора WhatsApp → «Удержать и ответить» → поговорить → завершить WhatsApp | записать: пришло ли `ACTION_CALL_TOGGLE_HOLD` с `isOnHold: false` само; если нет — снять удержание кнопкой в системном интерфейсе и проверить, что звук вернулся |

- [ ] **Step 7: Решение и уборка**

«Идём», если S1–S4 прошли. Результат S5 записать в конец проекта (раздел «Риски», пункт 2): «iOS снимает удержание сама: да/нет». При провале S1–S4 — остановиться и вернуться к пользователю с логами; дальше по плану не идти.

```bash
git switch fix/ios-callkit-calls
git branch -D spike/ios-callkit-audio
```

---

### Task 1: Плагин в репозиторий без правок

**Files:**
- Create: `packages/flutter_callkit_incoming/` (копия `flutter_callkit_incoming-2.5.8` без `example/`, `images/`, `test/`, `*.iml`)
- Create: `packages/flutter_callkit_incoming/PATCHES.md`
- Modify: `pubspec.yaml` (секция `dependency_overrides`)
- Modify: `analysis_options.yaml`

- [ ] **Step 1: Скопировать пакет**

```bash
SRC=~/.pub-cache/hosted/pub.dev/flutter_callkit_incoming-2.5.8
mkdir -p packages
rsync -a --exclude example --exclude images --exclude test --exclude '*.iml' "$SRC/" packages/flutter_callkit_incoming/
ls packages/flutter_callkit_incoming
```
Expected: `CHANGELOG.md CMD.md LICENSE PUSHKIT.md README.md analysis_options.yaml android ios lib pubspec.yaml`.

- [ ] **Step 2: PATCHES.md**

```markdown
# flutter_callkit_incoming 2.5.8 — копия Taler ID

Взята в репозиторий 2026-09-24: на iOS разговор теперь живёт в CallKit до конца
(см. docs/superpowers/specs/2026-09-24-ios-calls-through-callkit-design.md), а
плагин рассчитан на один звонок за раз. Правки только в `ios/Classes`,
помечены в коде `PATCH Pn (Taler ID)`. Android-часть не тронута.

При обновлении плагина: взять новую версию, перенести правки по этому списку,
прогнать матрицу из задачи 20 плана 2026-09-24-ios-calls-through-callkit.

(список правок — ниже, дополняется в задаче 2)
```

- [ ] **Step 3: Подключить копию**

В `pubspec.yaml` секцию

```yaml
dependency_overrides:
  path_provider_foundation: 2.3.2
```
заменить на
```yaml
dependency_overrides:
  path_provider_foundation: 2.3.2
  # Patched copy — see packages/flutter_callkit_incoming/PATCHES.md.
  flutter_callkit_incoming:
    path: packages/flutter_callkit_incoming
```

В `analysis_options.yaml` после строки `include: package:flutter_lints/flutter.yaml` добавить:
```yaml

analyzer:
  exclude:
    # Vendored plugin, linted upstream.
    - packages/**
```

- [ ] **Step 4: Проверить, что копия подхватилась и iOS собирается**

```bash
flutter pub get
grep -n -A3 "flutter_callkit_incoming:" pubspec.lock
flutter build ios --debug --no-codesign --flavor dev -t lib/main_dev.dart \
  --dart-define=FLAVOR=dev --dart-define=BASE_URL=https://staging.id.taler.tirol 2>&1 | tail -5
```
Expected: в `pubspec.lock` у пакета `source: path`, сборка заканчивается `✓ Built build/ios/iphoneos/Runner.app`.

- [ ] **Step 5: Коммит**

```bash
git add packages/flutter_callkit_incoming pubspec.yaml pubspec.lock analysis_options.yaml ios/Podfile.lock
git commit -F - <<'EOF'
chore(callkit): плагин flutter_callkit_incoming 2.5.8 — копия в репозитории

Без правок, только переезд: следующим коммитом в iOS-часть идут
исправления под разговоры, которые живут в CallKit до конца.

Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>
EOF
```
(Если `ios/Podfile.lock` не изменился — `git add` его просто пропустит.)

---

### Task 2: Правки плагина P1–P7

Unit-тестов у Swift-части нет: проверка — сборка и матрица на устройстве (задачи 19–20). Правки маленькие, каждую сверять с текстом ниже дословно.

**Files:**
- Modify: `packages/flutter_callkit_incoming/ios/Classes/SwiftFlutterCallkitIncomingPlugin.swift`
- Modify: `packages/flutter_callkit_incoming/ios/Classes/CallManager.swift`
- Modify: `packages/flutter_callkit_incoming/PATCHES.md`

- [ ] **Step 1: P1 — `endCall` / `callConnected` действуют на переданный id**

В `SwiftFlutterCallkitIncomingPlugin.swift`, `handle(_:result:)`, заменить весь `case "endCall":`:

```swift
        case "endCall":
            // PATCH P1 (Taler ID): end the call that was asked for. Upstream
            // replaced `self.data` with these args — or, after a PushKit call,
            // ignored them and ended the remembered call instead.
            guard let args = call.arguments as? [String: Any] else {
                result(true)
                return
            }
            self.endCall(Data(args: args))
            result(true)
            break
```

и весь `case "callConnected":`:

```swift
        case "callConnected":
            // PATCH P1 (Taler ID): as endCall — the requested call, `self.data`
            // left alone.
            guard let args = call.arguments as? [String: Any] else {
                result(true)
                return
            }
            self.connectedCall(Data(args: args))
            result(true)
            break
```

Функции `endCall(_ data:)` и `connectedCall(_ data:)` заменить целиком:

```swift
    @objc public func endCall(_ data: Data) {
        // PATCH P1 (Taler ID): always the requested uuid.
        guard let uuid = UUID(uuidString: data.uuid) else { return }
        self.isFromPushKit = false
        let call = self.callManager.callWithUUID(uuid: uuid) ?? Call(uuid: uuid, data: data)
        self.callManager.endCall(call: call)
    }

    @objc public func connectedCall(_ data: Data) {
        // PATCH P1 (Taler ID): always the requested uuid.
        guard let uuid = UUID(uuidString: data.uuid) else { return }
        self.isFromPushKit = false
        let call = self.callManager.callWithUUID(uuid: uuid) ?? Call(uuid: uuid, data: data)
        self.callManager.connectedCall(call: call)
    }
```

- [ ] **Step 2: P2 + P3 + P6 — завершение вызова**

Заменить тело `provider(_:perform action: CXEndCallAction)` после `guard … else { … }` (сам guard не трогать): от строки `call.endCall()` до закрывающей скобки функции:

```swift
        // PATCH P3 (Taler ID): declined vs ended is a property of THIS call.
        // Upstream looked at the global answerCall/outgoingCall, so once any
        // outgoing call had happened, declining a ringing call came out as
        // ENDED and the caller was never told.
        let wasAnswered = call.isOutGoing || call.hasConnected || call.data.isAccepted || call === self.answerCall
        call.endCall()
        self.callManager.removeCall(call)
        // PATCH P2 (Taler ID): forget only the call that ended. Upstream never
        // cleared outgoingCall and cleared answerCall on any call's end.
        if call === self.answerCall { self.answerCall = nil }
        if call === self.outgoingCall { self.outgoingCall = nil }
        if !wasAnswered {
            // PATCH P6 (Taler ID): the event carries this call's data.
            sendEvent(SwiftFlutterCallkitIncomingPlugin.ACTION_CALL_DECLINE, call.data.toJSON())
            if let appDelegate = UIApplication.shared.delegate as? CallkitIncomingAppDelegate {
                appDelegate.onDecline(call, action)
            } else {
                action.fulfill()
            }
        } else {
            sendEvent(SwiftFlutterCallkitIncomingPlugin.ACTION_CALL_ENDED, call.data.toJSON())
            if let appDelegate = UIApplication.shared.delegate as? CallkitIncomingAppDelegate {
                appDelegate.onEnd(call, action)
            } else {
                action.fulfill()
            }
        }
    }
```

- [ ] **Step 3: P4 — таймаут звонящего вызова**

Заменить `endCallNotExist(_:)` целиком:

```swift
    func endCallNotExist(_ data: Data) {
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(data.duration)) {
            // PATCH P4 (Taler ID): time out this call only while it is still
            // unanswered. Upstream skipped the timeout whenever ANY call was
            // answered or had ever been placed.
            guard let uuid = UUID(uuidString: data.uuid),
                  let call = self.callManager.callWithUUID(uuid: uuid) else { return }
            if !call.isOutGoing && !call.hasConnected && !call.data.isAccepted && call !== self.answerCall {
                self.callEndTimeout(data)
            }
        }
    }
```

- [ ] **Step 4: P6 — ответ и старт несут данные своего вызова**

В `provider(_:perform action: CXAnswerCallAction)` заменить две строки

```swift
        self.data?.isAccepted = true
        self.answerCall = call
        sendEvent(SwiftFlutterCallkitIncomingPlugin.ACTION_CALL_ACCEPT, self.data?.toJSON())
```
на
```swift
        // PATCH P6 (Taler ID): this call's data, not the last one remembered.
        call.data.isAccepted = true
        self.answerCall = call
        sendEvent(SwiftFlutterCallkitIncomingPlugin.ACTION_CALL_ACCEPT, call.data.toJSON())
```

В `provider(_:perform action: CXStartCallAction)` заменить
```swift
        self.sendEvent(SwiftFlutterCallkitIncomingPlugin.ACTION_CALL_START, self.data?.toJSON())
```
на
```swift
        // PATCH P6 (Taler ID): this call's data.
        self.sendEvent(SwiftFlutterCallkitIncomingPlugin.ACTION_CALL_START, call.data.toJSON())
```

- [ ] **Step 5: P7 — эхо удержания**

В `holdCall(_:onHold:)` заменить
```swift
            self.sendMuteEvent(callId.uuidString,  onHold)
```
на
```swift
            // PATCH P7 (Taler ID): the echo of an unchanged hold is a hold event.
            self.sendHoldEvent(callId.uuidString, onHold)
```

- [ ] **Step 6: P5 — исходящий «соединён» без ответа**

В `CallManager.swift` в `connectedCall(call:)` после строки `callItem?.connectedCall(completion: nil)` вставить:

```swift
        // PATCH P5 (Taler ID): an outgoing call is connected by reporting it —
        // the hasConnectDidChange hook set in CXStartCallAction does that.
        // Answering it made CallKit run an answer action on our own outgoing
        // call.
        if callItem?.isOutGoing == true { return }
```

- [ ] **Step 7: Дописать PATCHES.md**

Заменить строку `(список правок — ниже, дополняется в задаче 2)` на:

```markdown
## Правки

- **P1** `SwiftFlutterCallkitIncomingPlugin.swift` — `endCall` и `callConnected`
  действуют на переданный `id` и не перезаписывают `self.data`. Было: после
  входящего по VoIP-пушу снимался запомненный вызов вместо запрошенного.
- **P2** там же, `CXEndCallAction` — `answerCall`/`outgoingCall` обнуляются,
  только если завершился именно этот вызов. Было: `outgoingCall` не обнулялся
  никогда, `answerCall` — при завершении любого вызова.
- **P3** там же — DECLINE или ENDED по самому вызову (входящий и не отвеченный
  → DECLINE). Было: по глобальным полям.
- **P4** там же, `endCallNotExist` — таймаут звонящего вызова смотрит на этот
  вызов. Было: не срабатывал, если хоть один вызов был отвечен или исходящий.
- **P5** `CallManager.swift`, `connectedCall` — для исходящего не порождается
  `CXAnswerCallAction`.
- **P6** `SwiftFlutterCallkitIncomingPlugin.swift` — события ACCEPT, START,
  DECLINE, ENDED несут `call.data`, флаг `isAccepted` ставится на `call.data`.
- **P7** там же, `holdCall` — при неизменном состоянии шлётся событие
  удержания, а не mute.
```

- [ ] **Step 8: Сборка**

```bash
flutter build ios --debug --no-codesign --flavor dev -t lib/main_dev.dart \
  --dart-define=FLAVOR=dev --dart-define=BASE_URL=https://staging.id.taler.tirol 2>&1 | tail -5
```
Expected: `✓ Built build/ios/iphoneos/Runner.app`.

- [ ] **Step 9: Коммит**

```bash
git add packages/flutter_callkit_incoming
git commit -F - <<'EOF'
fix(callkit): плагин различает звонки, а не помнит один

Пока разговор снимался с CallKit сразу после ответа, плагину хватало
одного запомненного звонка. Теперь разговоры живут в CallKit до конца,
и на этом ломалось: сброс после входящего по пушу снимал не тот вызов,
после первого же исходящего отклонение нового входящего приходило как
«завершён» (звонящего не извещали), таймаут звонящего вызова умолкал.
Семь правок, все в iOS-части, список в PATCHES.md.

Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>
EOF
```

---

### Task 3: `callkit_support.dart` — `toCallkitId` и `isIosSimulator` в одном месте

Реестру нужны обе функции, а тянуть ради них `notification_service.dart` (Firebase и прочее) в `core/platform` нельзя.

**Files:**
- Create: `lib/core/platform/callkit_support.dart`
- Modify: `lib/core/notifications/notification_service.dart:158-178`
- Test: `test/core/platform/callkit_support_test.dart`

- [ ] **Step 1: Тест**

```dart
// test/core/platform/callkit_support_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:taler_id_mobile/core/platform/callkit_support.dart';

void main() {
  final uuidShape = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
    caseSensitive: false,
  );

  test('a UUID-shaped room name is used as is', () {
    expect(toCallkitId('550e8400-e29b-41d4-a716-446655440000'),
        '550e8400-e29b-41d4-a716-446655440000');
  });

  test('call-<uuid> loses the prefix — the id the VoIP push path derives too', () {
    expect(toCallkitId('call-550e8400-e29b-41d4-a716-446655440000'),
        '550e8400-e29b-41d4-a716-446655440000');
  });

  test('any other name maps to a stable valid UUID', () {
    final a = toCallkitId('personal-c79530ed-36fc367a');
    expect(a, matches(uuidShape));
    expect(toCallkitId('personal-c79530ed-36fc367a'), a);
  });
}
```

- [ ] **Step 2: Запустить — падает**

Run: `flutter test test/core/platform/callkit_support_test.dart`
Expected: FAIL — `callkit_support.dart` не существует.

- [ ] **Step 3: Новый файл**

```dart
// lib/core/platform/callkit_support.dart
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;

/// The iOS Simulator has no CallKit.
bool get isIosSimulator =>
    !kIsWeb &&
    Platform.isIOS &&
    (Platform.environment['SIMULATOR_DEVICE_NAME'] != null ||
        Platform.environment['SIMULATOR_UDID'] != null);

/// Extract UUID part from roomName like "call-550e8400-e29b-41d4-a716-446655440000"
/// CallKit requires a valid RFC4122 UUID string as id.
String toCallkitId(String roomName) {
  // If roomName already looks like a UUID, use it directly
  final uuidRegex = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
    caseSensitive: false,
  );
  if (uuidRegex.hasMatch(roomName)) return roomName;
  // Strip prefix "call-" and take remaining UUID part
  final stripped = roomName.replaceFirst(RegExp(r'^call-'), '');
  if (uuidRegex.hasMatch(stripped)) return stripped;
  // Fallback: derive UUID from hash (must be a valid UUID)
  final hash = roomName.hashCode.abs();
  return '00000000-0000-4000-8000-${hash.toRadixString(16).padLeft(12, '0').substring(0, 12)}';
}
```

- [ ] **Step 4: Убрать дубли из `notification_service.dart`**

Удалить геттер `_isIosSimulator` (строки 158–162) и функцию `toCallkitId` с её doc-комментарием (строки 164–178). В импорты добавить:

```dart
import '../platform/callkit_support.dart';
```
и сразу после импортов:
```dart
// toCallkitId lived here; main.dart and the dashboard still import it from here.
export '../platform/callkit_support.dart' show toCallkitId;
```
Три оставшихся `_isIosSimulator` заменить на `isIosSimulator`:
```bash
sed -i '' 's/_isIosSimulator/isIosSimulator/g' lib/core/notifications/notification_service.dart
grep -n "isIosSimulator" lib/core/notifications/notification_service.dart
```

- [ ] **Step 5: Тесты и анализ**

```bash
flutter test test/core/platform/callkit_support_test.dart
for f in lib/core/platform/callkit_support.dart lib/core/notifications/notification_service.dart lib/main.dart lib/features/dashboard/presentation/dashboard_screen.dart; do
  printf "%s: " "$f"; flutter analyze "$f" 2>&1 | grep -cE "^\s*(error|warning) "
done
```
Expected: 3 теста PASS; `dashboard_screen.dart: 2`, остальные `0` (импорт `toCallkitId` через `export` не сломался).

- [ ] **Step 6: Коммит**

```bash
git add lib/core/platform/callkit_support.dart lib/core/notifications/notification_service.dart test/core/platform/callkit_support_test.dart
git commit -F - <<'EOF'
refactor(callkit): toCallkitId и проверка симулятора — в core/platform

Реестру системных звонков нужны обе, а тянуть ради них notification_service
с Firebase в core/platform нельзя. Старые импорты работают через export.

Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>
EOF
```

---

### Task 4: `CallKitPlatform` — исходящий, соединение, удержание, mute

**Files:**
- Modify: `lib/core/platform/call_kit.dart`
- Modify: `lib/core/platform/call_kit_mobile.dart`
- Modify: `lib/core/platform/call_kit_desktop.dart`
- Test: `test/core/platform/call_kit_test.dart`, `test/core/platform/call_kit_mobile_params_test.dart`

- [ ] **Step 1: Тесты**

В `test/core/platform/call_kit_test.dart` в группу `CallKitEvent` добавить:

```dart
    test('hold, mute and audio-session event types match the plugin', () {
      expect(CallKitEvent.typeToggleHold,
          'com.hiennv.flutter_callkit_incoming.ACTION_CALL_TOGGLE_HOLD');
      expect(CallKitEvent.typeToggleMute,
          'com.hiennv.flutter_callkit_incoming.ACTION_CALL_TOGGLE_MUTE');
      expect(CallKitEvent.typeToggleAudioSession,
          'com.hiennv.flutter_callkit_incoming.ACTION_CALL_TOGGLE_AUDIO_SESSION');
    });
```

и в группу `CallKitDesktop (no-op)`:

```dart
    test('call-control methods are no-ops', () async {
      await expectLater(
          desktop.startCall(uuid: 'u1', callerName: 'A', handle: 'h'), completes);
      await expectLater(desktop.setCallConnected('u1'), completes);
      await expectLater(desktop.setHeld('u1', true), completes);
      await expectLater(desktop.setMuted('u1', true), completes);
    });
```

Новый файл:

```dart
// test/core/platform/call_kit_mobile_params_test.dart
//
// The iOS call settings are the heart of the CallKit work: a call that can't
// be held gets no "Hold & Accept", and a plugin that configures the audio
// session itself fights CallKit for it.
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taler_id_mobile/core/platform/call_kit_mobile.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  const method = MethodChannel('flutter_callkit_incoming');
  const events = EventChannel('flutter_callkit_incoming_events');
  late List<MethodCall> log;

  setUp(() {
    log = [];
    messenger.setMockMethodCallHandler(method, (call) async {
      log.add(call);
      return true;
    });
    messenger.setMockStreamHandler(
        events, MockStreamHandler.inline(onListen: (_, __) {}));
  });

  tearDown(() {
    messenger.setMockMethodCallHandler(method, null);
    messenger.setMockStreamHandler(events, null);
  });

  Map<String, dynamic> iosOf(MethodCall call) => Map<String, dynamic>.from(
      (Map<String, dynamic>.from(call.arguments as Map))['ios'] as Map);

  void expectCallKitOwnsTheSession(Map<String, dynamic> ios) {
    expect(ios['supportsHolding'], isTrue);
    expect(ios['configureAudioSession'], isFalse);
    expect(ios['audioSessionMode'], 'voiceChat');
  }

  test('startCall registers a holdable call and leaves the session alone', () async {
    await CallKitMobile().startCall(
        uuid: 'u1', callerName: 'Alice', handle: 'conv-1', extra: {'roomName': 'r1'});
    final call = log.singleWhere((c) => c.method == 'startCall');
    final args = Map<String, dynamic>.from(call.arguments as Map);
    expect(args['id'], 'u1');
    expect(args['nameCaller'], 'Alice');
    expect(args['handle'], 'conv-1');
    expect(Map<String, dynamic>.from(args['extra'] as Map)['roomName'], 'r1');
    expectCallKitOwnsTheSession(iosOf(call));
  });

  test('incoming calls use the same iOS settings', () async {
    await CallKitMobile().showIncomingCall(uuid: 'u2', callerName: 'Bob', roomName: 'r2');
    expectCallKitOwnsTheSession(
        iosOf(log.singleWhere((c) => c.method == 'showCallkitIncoming')));
  });

  test('connect, hold and mute go to the plugin with the call id', () async {
    final kit = CallKitMobile();
    await kit.setCallConnected('u3');
    await kit.setHeld('u3', true);
    await kit.setMuted('u3', false);
    expect(log.map((c) => c.method),
        containsAll(['callConnected', 'holdCall', 'muteCall']));
    expect(log.firstWhere((c) => c.method == 'holdCall').arguments,
        {'id': 'u3', 'isOnHold': true});
    expect(log.firstWhere((c) => c.method == 'muteCall').arguments,
        {'id': 'u3', 'isMuted': false});
  });
}
```

- [ ] **Step 2: Запустить — падает**

Run: `flutter test test/core/platform/call_kit_test.dart test/core/platform/call_kit_mobile_params_test.dart`
Expected: FAIL — `typeToggleHold`, `startCall` и прочего нет.

- [ ] **Step 3: Интерфейс**

В `lib/core/platform/call_kit.dart` после `typePushTokenVoip` добавить:

```dart
  static const typeToggleHold =
      'com.hiennv.flutter_callkit_incoming.ACTION_CALL_TOGGLE_HOLD';
  static const typeToggleMute =
      'com.hiennv.flutter_callkit_incoming.ACTION_CALL_TOGGLE_MUTE';
  static const typeToggleAudioSession =
      'com.hiennv.flutter_callkit_incoming.ACTION_CALL_TOGGLE_AUDIO_SESSION';
```

В `abstract class CallKitPlatform` после `endAllCalls()`:

```dart
  /// Put a conversation that did not ring through CallKit (an outgoing call,
  /// a meeting joined by link) into the OS call system. iOS confirms with a
  /// [CallKitEvent.typeStart] event carrying the same [uuid].
  Future<void> startCall({
    required String uuid,
    required String callerName,
    required String handle,
    Map<String, dynamic>? extra,
  });

  /// Outgoing call: report it connected. Ringing incoming call: answer it,
  /// exactly as the Accept button of the CallKit UI would.
  Future<void> setCallConnected(String uuid);

  /// Put [uuid] on hold, or take it off hold.
  Future<void> setHeld(String uuid, bool onHold);

  /// Mirror our mute state in the system call UI.
  Future<void> setMuted(String uuid, bool muted);
```

- [ ] **Step 4: Мобильная реализация**

В `lib/core/platform/call_kit_mobile.dart` в класс добавить общий набор iOS-параметров:

```dart
  /// Every conversation stays in CallKit for as long as it lasts (see
  /// docs/superpowers/specs/2026-09-24-ios-calls-through-callkit-design.md):
  /// holdable, so WhatsApp and cellular calls offer "Hold & Accept"; and the
  /// plugin keeps its hands off the audio session — CallKit activates it and
  /// the app sets its category (CallKitAudioBridge).
  static const _iosCallParams = IOSParams(
    iconName: 'CallKitLogo',
    supportsVideo: false,
    maximumCallGroups: 2,
    maximumCallsPerCallGroup: 1,
    audioSessionMode: 'voiceChat',
    audioSessionActive: true,
    audioSessionPreferredSampleRate: 44100.0,
    audioSessionPreferredIOBufferDuration: 0.005,
    configureAudioSession: false,
    supportsDTMF: false,
    supportsHolding: true,
    supportsGrouping: false,
    supportsUngrouping: false,
    ringtonePath: 'bumer_ringtone.caf',
  );
```

В `showIncomingCall` заменить весь блок `ios: const IOSParams(…),` на `ios: _iosCallParams,`. После `endAllCalls()` добавить:

```dart
  @override
  Future<void> startCall({
    required String uuid,
    required String callerName,
    required String handle,
    Map<String, dynamic>? extra,
  }) =>
      FlutterCallkitIncoming.startCall(CallKitParams(
        id: uuid,
        nameCaller: callerName,
        appName: 'Taler ID',
        handle: handle,
        type: 0,
        extra: extra,
        ios: _iosCallParams,
      ));

  @override
  Future<void> setCallConnected(String uuid) =>
      FlutterCallkitIncoming.setCallConnected(uuid);

  @override
  Future<void> setHeld(String uuid, bool onHold) =>
      FlutterCallkitIncoming.holdCall(uuid, isOnHold: onHold);

  @override
  Future<void> setMuted(String uuid, bool muted) =>
      FlutterCallkitIncoming.muteCall(uuid, isMuted: muted);
```

- [ ] **Step 5: Десктоп**

В `lib/core/platform/call_kit_desktop.dart` после `endAllCalls()`:

```dart
  @override
  Future<void> startCall({
    required String uuid,
    required String callerName,
    required String handle,
    Map<String, dynamic>? extra,
  }) async {}

  @override
  Future<void> setCallConnected(String uuid) async {}

  @override
  Future<void> setHeld(String uuid, bool onHold) async {}

  @override
  Future<void> setMuted(String uuid, bool muted) async {}
```

- [ ] **Step 6: Тесты проходят**

Run: `flutter test test/core/platform/`
Expected: PASS все.

- [ ] **Step 7: Коммит**

```bash
git add lib/core/platform/call_kit.dart lib/core/platform/call_kit_mobile.dart lib/core/platform/call_kit_desktop.dart test/core/platform/call_kit_test.dart test/core/platform/call_kit_mobile_params_test.dart
git commit -F - <<'EOF'
feat(callkit): исходящий, соединение, удержание и mute через CallKit

Звонок в CallKit теперь можно удерживать (иначе iOS не предложит
«Удержать и ответить» при звонке WhatsApp), а плагин больше не
настраивает и не включает аудиосессию сам — это делают CallKit и
приложение.

Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>
EOF
```

---

### Task 5: `SystemCallBridge` — Dart-сторона канала моста

**Files:**
- Create: `lib/core/platform/system_call_bridge.dart`
- Test: `test/core/platform/system_call_bridge_test.dart`

- [ ] **Step 1: Тест**

```dart
// test/core/platform/system_call_bridge_test.dart
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taler_id_mobile/core/platform/system_call_bridge.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  const channel = MethodChannel('taler_id/callkit_audio');
  late List<MethodCall> log;

  setUp(() {
    log = [];
    messenger.setMockMethodCallHandler(channel, (call) async {
      log.add(call);
      return null;
    });
  });

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  test('setManagedCalls sends the uuid list', () async {
    await MethodChannelSystemCallBridge().setManagedCalls(['a', 'b']);
    expect(log.single.method, 'setManagedCalls');
    expect(log.single.arguments, ['a', 'b']);
  });

  test('prepareCallAudio reaches native', () async {
    await MethodChannelSystemCallBridge().prepareCallAudio();
    expect(log.single.method, 'prepareCallAudio');
  });

  test('otherCallsEnded from native reaches the stream', () async {
    final bridge = MethodChannelSystemCallBridge();
    final got = bridge.otherCallsEnded.first;
    await messenger.handlePlatformMessage(
      'taler_id/callkit_audio',
      const StandardMethodCodec().encodeMethodCall(const MethodCall('otherCallsEnded')),
      (_) {},
    );
    await expectLater(got, completes);
  });
}
```

- [ ] **Step 2: Запустить — падает**

Run: `flutter test test/core/platform/system_call_bridge_test.dart`
Expected: FAIL — файла нет.

- [ ] **Step 3: Реализация**

```dart
// lib/core/platform/system_call_bridge.dart
import 'dart:async';

import 'package:flutter/services.dart';

/// Dart side of `ios/Runner/CallKitAudioBridge.swift`.
abstract class SystemCallBridge {
  /// Which CallKit calls are our conversations. Non-empty: CallKit owns the
  /// audio session and WebRTC follows it; empty: WebRTC manages it as before.
  Future<void> setManagedCalls(List<String> uuids);

  /// Set the call's audio category before CallKit activates the session.
  Future<void> prepareCallAudio();

  /// No call other than our conversations remains — call waiting is over.
  Stream<void> get otherCallsEnded;
}

class MethodChannelSystemCallBridge implements SystemCallBridge {
  MethodChannelSystemCallBridge() {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'otherCallsEnded') _otherCallsEnded.add(null);
      return null;
    });
  }

  // A channel of its own: `taler_id/audio` belongs to the call screen, which
  // drops its handler when it closes, and the bridge must keep working while
  // the call runs behind the banner.
  static const _channel = MethodChannel('taler_id/callkit_audio');
  final _otherCallsEnded = StreamController<void>.broadcast();

  @override
  Future<void> setManagedCalls(List<String> uuids) =>
      _channel.invokeMethod('setManagedCalls', uuids);

  @override
  Future<void> prepareCallAudio() => _channel.invokeMethod('prepareCallAudio');

  @override
  Stream<void> get otherCallsEnded => _otherCallsEnded.stream;
}
```

- [ ] **Step 4: Тесты проходят**

Run: `flutter test test/core/platform/system_call_bridge_test.dart`
Expected: 3 PASS.

- [ ] **Step 5: Коммит**

```bash
git add lib/core/platform/system_call_bridge.dart test/core/platform/system_call_bridge_test.dart
git commit -F - <<'EOF'
feat(звонок): канал к нативному мосту CallKit → WebRTC

Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>
EOF
```

---

### Task 6: Реестр — ядро (регистрация, приём, привязка комнаты, «соединён»)

**Files:**
- Create: `lib/core/platform/system_call_registry.dart`
- Create: `test/core/platform/system_call_fakes.dart`
- Test: `test/core/platform/system_call_registry_test.dart`

- [ ] **Step 1: Подделки для тестов**

```dart
// test/core/platform/system_call_fakes.dart
import 'dart:async';

import 'package:taler_id_mobile/core/platform/call_kit.dart';
import 'package:taler_id_mobile/core/platform/system_call_bridge.dart';

class FakeCallKit implements CallKitPlatform {
  final _events = StreamController<CallKitEvent>.broadcast();

  /// Everything the registry asked for, e.g. `endCall:<uuid>`.
  final log = <String>[];
  List<dynamic> active = [];
  bool confirmStarts = true;

  void emit(String type, String uuid, [Map<String, dynamic> data = const {}]) =>
      _events.add(CallKitEvent(type: type, uuid: uuid, data: {'id': uuid, ...data}));

  @override
  Stream<CallKitEvent> get events => _events.stream;

  @override
  Future<void> startCall({
    required String uuid,
    required String callerName,
    required String handle,
    Map<String, dynamic>? extra,
  }) async {
    log.add('startCall:$uuid:$callerName:$handle');
    if (confirmStarts) emit(CallKitEvent.typeStart, uuid);
  }

  @override
  Future<void> setCallConnected(String uuid) async => log.add('setCallConnected:$uuid');

  @override
  Future<void> setHeld(String uuid, bool onHold) async => log.add('setHeld:$uuid:$onHold');

  @override
  Future<void> setMuted(String uuid, bool muted) async => log.add('setMuted:$uuid:$muted');

  @override
  Future<void> endCall(String uuid) async => log.add('endCall:$uuid');

  @override
  Future<void> endAllCalls() async => log.add('endAllCalls');

  @override
  Future<List<dynamic>> activeCalls() async => active;

  @override
  Future<String?> getDevicePushTokenVoIP() async => null;

  @override
  Future<void> showIncomingCall({
    required String uuid,
    required String callerName,
    required String roomName,
    String? handle,
    String? avatar,
    bool isVideo = false,
    Map<String, dynamic>? extra,
    String? textAccept,
    String? textDecline,
    int? durationMs,
    String? androidIncomingChannelName,
    String? androidMissedChannelName,
  }) async {}
}

class FakeBridge implements SystemCallBridge {
  final managed = <List<String>>[];
  int prepared = 0;
  final _otherCallsEnded = StreamController<void>.broadcast();

  List<String> get lastManaged => managed.isEmpty ? const [] : managed.last;
  void otherCallsGone() => _otherCallsEnded.add(null);

  @override
  Future<void> setManagedCalls(List<String> uuids) async => managed.add(List.of(uuids));

  @override
  Future<void> prepareCallAudio() async => prepared++;

  @override
  Stream<void> get otherCallsEnded => _otherCallsEnded.stream;
}
```

- [ ] **Step 2: Тесты ядра**

```dart
// test/core/platform/system_call_registry_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:taler_id_mobile/core/platform/call_kit.dart';
import 'package:taler_id_mobile/core/platform/system_call_registry.dart';

import 'system_call_fakes.dart';

const u1 = '11111111-1111-4111-8111-111111111111';
const u2 = '22222222-2222-4222-8222-222222222222';

void main() {
  late FakeCallKit kit;
  late FakeBridge bridge;
  late SystemCallRegistry reg;
  late List<SystemCallEvent> events;

  SystemCallRegistry build({bool enabled = true, List<String> uuids = const [u1, u2]}) {
    final queue = List.of(uuids);
    final r = SystemCallRegistry(
      callKit: kit,
      bridge: bridge,
      enabled: enabled,
      startTimeout: const Duration(milliseconds: 50),
      answerTimeout: const Duration(milliseconds: 50),
      newUuid: () => queue.removeAt(0),
    )..attach();
    r.events.listen(events.add);
    return r;
  }

  setUp(() {
    kit = FakeCallKit();
    bridge = FakeBridge();
    events = [];
    reg = build();
  });

  tearDown(() => reg.detach());

  group('outgoing registration', () {
    test('confirmed start returns the uuid and makes it a conversation', () async {
      final uuid = await reg.startOutgoing(displayName: 'Alice', handle: 'conv-1');
      expect(uuid, u1);
      expect(bridge.prepared, 1, reason: 'category is set before CallKit activates');
      expect(kit.log, ['startCall:$u1:Alice:conv-1']);
      expect(bridge.lastManaged, [u1]);
      reg.bindRoom(u1, 'call-room-1');
      expect(reg.isConversation('call-room-1'), isTrue);
      expect(reg.uuidForRoom('call-room-1'), u1);
    });

    test('an unconfirmed start falls back and a late start is ended', () async {
      kit.confirmStarts = false;
      expect(await reg.startOutgoing(displayName: 'Alice', handle: 'h'), isNull);
      expect(bridge.lastManaged, isEmpty);
      kit.emit(CallKitEvent.typeStart, u1);
      await pumpEventQueue();
      expect(kit.log, contains('endCall:$u1'));
    });

    test('disabled registry never touches CallKit', () async {
      await reg.detach();
      reg = build(enabled: false);
      expect(await reg.startOutgoing(displayName: 'Alice', handle: 'h'), isNull);
      expect(kit.log, isEmpty);
    });
  });

  group('incoming', () {
    test('an accepted call with a room becomes a conversation', () async {
      kit.emit(CallKitEvent.typeAccept, u2, {'extra': {'roomName': 'call-r2'}});
      await pumpEventQueue();
      expect(reg.uuidForRoom('call-r2'), u2);
      expect(bridge.lastManaged, [u2]);
    });

    test('group and mesh calls are not ours to manage', () async {
      kit.emit(CallKitEvent.typeAccept, u1, {'extra': {'roomName': 'group-g1'}});
      kit.emit(CallKitEvent.typeAccept, u2,
          {'extra': {'roomName': 'r-mesh', 'kind': 'mesh_gc'}});
      await pumpEventQueue();
      expect(reg.hasConversations, isFalse);
    });

    test('adoptAnswered covers an accept the app did not hear', () async {
      await reg.adoptAnswered(uuid: u2.toUpperCase(), roomName: 'call-r2');
      expect(reg.uuidForRoom('call-r2'), u2);
    });
  });

  group('markConnected', () {
    test('reports an outgoing call connected once', () async {
      await reg.startOutgoing(displayName: 'A', handle: 'h', roomName: 'call-r1');
      await reg.markConnected('call-r1');
      await reg.markConnected('call-r1');
      expect(kit.log.where((l) => l == 'setCallConnected:$u1'), hasLength(1));
    });

    test('leaves incoming calls alone — the answer connected them', () async {
      kit.emit(CallKitEvent.typeAccept, u2, {'extra': {'roomName': 'call-r2'}});
      await pumpEventQueue();
      await reg.markConnected('call-r2');
      expect(kit.log, isNot(contains('setCallConnected:$u2')));
    });
  });
}
```

- [ ] **Step 3: Запустить — падает**

Run: `flutter test test/core/platform/system_call_registry_test.dart`
Expected: FAIL — `system_call_registry.dart` не существует.

- [ ] **Step 4: Реализация ядра**

```dart
// lib/core/platform/system_call_registry.dart
import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import 'call_kit.dart';
import 'callkit_support.dart';
import 'system_call_bridge.dart';

/// Something the OS call system did to one of our conversations.
sealed class SystemCallEvent {
  const SystemCallEvent(this.uuid, this.roomName);

  /// CallKit uuid, lowercase.
  final String uuid;

  /// LiveKit room of the conversation; null until the server created it.
  final String? roomName;
}

/// The conversation went on hold. [bySystem]: call waiting (WhatsApp, a
/// cellular call, a second Taler ID call answered with "Hold & Accept"), as
/// opposed to our own line switch, which is never resumed automatically.
final class SystemCallHeld extends SystemCallEvent {
  const SystemCallHeld(super.uuid, super.roomName, {required this.bySystem});
  final bool bySystem;
}

final class SystemCallResumed extends SystemCallEvent {
  const SystemCallResumed(super.uuid, super.roomName);
}

/// The mute button of the system call UI (lock screen, Dynamic Island).
final class SystemCallMuteChanged extends SystemCallEvent {
  const SystemCallMuteChanged(super.uuid, super.roomName, {required this.muted});
  final bool muted;
}

/// Ended outside the app: the system End button, "End & Accept".
final class SystemCallEndedBySystem extends SystemCallEvent {
  const SystemCallEndedBySystem(super.uuid, super.roomName);
}

enum _State { starting, active, heldBySystem, heldByApp }

class _Entry {
  _Entry({required this.uuid, required this.outgoing, required this.state, this.roomName});

  final String uuid;
  final bool outgoing;
  String? roomName;
  _State state;
  bool connectedReported = false;
  final started = Completer<bool>();
}

/// iOS: every conversation on the call screen lives in CallKit for as long as
/// it lasts, so WhatsApp and cellular calls arrive as call waiting instead of
/// taking our audio session. This is the Dart side of it: which CallKit call
/// is which conversation, and what the system did to it. See
/// docs/superpowers/specs/2026-09-24-ios-calls-through-callkit-design.md.
///
/// Disabled everywhere but a real iPhone. Every method is then a no-op, and
/// the ones that replace a blanket `endAllCalls()` fall back to exactly that,
/// so Android, desktop and the simulator behave as before.
class SystemCallRegistry {
  SystemCallRegistry({
    required CallKitPlatform callKit,
    required SystemCallBridge bridge,
    required this.enabled,
    this.startTimeout = const Duration(seconds: 3),
    this.answerTimeout = const Duration(seconds: 2),
    String Function()? newUuid,
  })  : _callKit = callKit,
        _bridge = bridge,
        _newUuid = newUuid ?? (() => const Uuid().v4());

  static SystemCallRegistry? _instance;

  static SystemCallRegistry get instance => _instance ??= SystemCallRegistry(
        callKit: CallKitPlatform.instance,
        bridge: MethodChannelSystemCallBridge(),
        enabled: !kIsWeb && Platform.isIOS && !isIosSimulator,
      );

  @visibleForTesting
  static set debugInstance(SystemCallRegistry? registry) => _instance = registry;

  final CallKitPlatform _callKit;
  final SystemCallBridge _bridge;
  final bool enabled;
  final Duration startTimeout;
  final Duration answerTimeout;
  final String Function() _newUuid;

  /// Our conversations, by lowercase CallKit uuid.
  final Map<String, _Entry> _entries = {};

  /// Outgoing starts [startOutgoing] gave up on: ended if iOS starts them late.
  final Set<String> _abandonedStarts = {};

  final _events = StreamController<SystemCallEvent>.broadcast();
  StreamSubscription<CallKitEvent>? _callKitSub;
  StreamSubscription<void>? _bridgeSub;

  Stream<SystemCallEvent> get events => _events.stream;

  /// At least one conversation is in CallKit — CallKit owns the audio session.
  bool get hasConversations => _entries.isNotEmpty;

  /// Starts listening. Call once, before runApp, so an accept that launched a
  /// killed app is not missed.
  void attach() {
    if (!enabled || _callKitSub != null) return;
    _callKitSub = _callKit.events.listen(_onCallKitEvent);
    _bridgeSub = _bridge.otherCallsEnded.listen((_) => _onOtherCallsEnded());
  }

  @visibleForTesting
  Future<void> detach() async {
    await _callKitSub?.cancel();
    await _bridgeSub?.cancel();
    _callKitSub = null;
    _bridgeSub = null;
  }

  bool isConversation(String roomName) => _entryForRoom(roomName) != null;

  String? uuidForRoom(String roomName) => _entryForRoom(roomName)?.uuid;

  bool isHeldBySystem(String roomName) =>
      _entryForRoom(roomName)?.state == _State.heldBySystem;

  /// Puts a conversation that did not ring through CallKit into it — an
  /// outgoing call, a meeting joined by link, a call picked up outside
  /// CallKit — and waits for iOS to confirm. Returns the CallKit uuid, or
  /// null: the call then runs the old way, without CallKit.
  Future<String?> startOutgoing({
    required String displayName,
    required String handle,
    String? roomName,
  }) async {
    if (!enabled) return null;
    final uuid = _newUuid().toLowerCase();
    final entry = _Entry(uuid: uuid, outgoing: true, state: _State.starting, roomName: roomName);
    _entries[uuid] = entry;
    await _syncManaged();
    try {
      await _bridge.prepareCallAudio();
      await _callKit.startCall(
        uuid: uuid,
        callerName: displayName,
        handle: handle,
        extra: {if (roomName != null) 'roomName': roomName},
      );
    } catch (e) {
      debugPrint('[SystemCall] could not start $uuid in CallKit: $e');
      if (!entry.started.isCompleted) entry.started.complete(false);
    }
    final ok = await entry.started.future.timeout(startTimeout, onTimeout: () => false);
    if (ok) return uuid;
    _entries.remove(uuid);
    _abandonedStarts.add(uuid);
    await _syncManaged();
    debugPrint('[SystemCall] CallKit did not confirm $uuid — call runs without it');
    return null;
  }

  /// Attaches the room name once the server has created the room.
  void bindRoom(String uuid, String roomName) {
    _entries[uuid.toLowerCase()]?.roomName = roomName;
  }

  /// A conversation whose CallKit call was answered while the app was not
  /// listening (cold start after an answer on the lock screen).
  Future<void> adoptAnswered({required String uuid, required String roomName}) async {
    if (!enabled) return;
    final key = uuid.toLowerCase();
    if (_entries.containsKey(key)) return;
    _entries[key] = _Entry(uuid: key, outgoing: false, state: _State.active, roomName: roomName);
    await _syncManaged();
  }

  /// The callee (or the AI twin) answered, or a meeting was joined: iOS shows
  /// the outgoing call connected from here on. Incoming calls are connected by
  /// the answer itself.
  Future<void> markConnected(String roomName) async {
    final entry = _entryForRoom(roomName);
    if (entry == null || !entry.outgoing || entry.connectedReported) return;
    entry.connectedReported = true;
    await _callKit.setCallConnected(entry.uuid);
  }

  void _onCallKitEvent(CallKitEvent event) {
    final uuid = event.uuid.toLowerCase();
    switch (event.type) {
      case CallKitEvent.typeStart:
        final entry = _entries[uuid];
        if (entry == null) {
          if (_abandonedStarts.remove(uuid)) unawaited(_callKit.endCall(uuid));
          return;
        }
        if (entry.state == _State.starting) entry.state = _State.active;
        if (!entry.started.isCompleted) entry.started.complete(true);
      case CallKitEvent.typeAccept:
        _onAccepted(uuid, event.data);
    }
  }

  void _onAccepted(String uuid, Map<String, dynamic>? data) {
    if (_entries.containsKey(uuid)) return;
    final extra = data?['extra'];
    if (extra is! Map) return;
    final roomName = extra['roomName'];
    if (roomName is! String || roomName.isEmpty) return;
    // Mesh group calls run their own audio stack, LiveKit group calls
    // ('group-<id>') their own screen — neither is a call-screen conversation.
    if (extra['kind'] == 'mesh_gc' || roomName.startsWith('group-')) return;
    _entries[uuid] = _Entry(uuid: uuid, outgoing: false, state: _State.active, roomName: roomName);
    unawaited(_syncManaged());
  }

  void _onOtherCallsEnded() {}

  _Entry? _entryForRoom(String roomName) {
    for (final entry in _entries.values) {
      if (entry.roomName == roomName) return entry;
    }
    return null;
  }

  Future<void> _syncManaged() async {
    try {
      await _bridge.setManagedCalls(_entries.keys.toList());
    } catch (e) {
      debugPrint('[SystemCall] setManagedCalls failed: $e');
    }
  }
}
```

- [ ] **Step 5: Тесты проходят**

Run: `flutter test test/core/platform/system_call_registry_test.dart`
Expected: все PASS.

- [ ] **Step 6: Коммит**

```bash
git add lib/core/platform/system_call_registry.dart test/core/platform/system_call_fakes.dart test/core/platform/system_call_registry_test.dart
git commit -F - <<'EOF'
feat(звонок): реестр разговоров в CallKit — регистрация и приём

Исходящий или встреча заводятся в CallKit и ждут подтверждения iOS;
не дождались за 3 секунды — звонок идёт по-старому, без CallKit.
Принятый в CallKit входящий становится разговором сам. Групповые и
mesh-звонки реестр не трогает.

Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>
EOF
```

---

### Task 7: Реестр — завершение и снятие звонящих вызовов

**Files:**
- Modify: `lib/core/platform/system_call_registry.dart`
- Test: `test/core/platform/system_call_registry_test.dart`

- [ ] **Step 1: Тесты**

В `main()` файла `system_call_registry_test.dart` добавить группы:

```dart
  group('ending', () {
    Future<void> conversation(String uuid, String room) async {
      kit.emit(CallKitEvent.typeAccept, uuid, {'extra': {'roomName': room}});
      await pumpEventQueue();
    }

    test('an end from the system reaches the app once', () async {
      await conversation(u1, 'call-r1');
      kit.emit(CallKitEvent.typeEnded, u1);
      await pumpEventQueue();
      expect(events.whereType<SystemCallEndedBySystem>().single.roomName, 'call-r1');
      expect(reg.isConversation('call-r1'), isFalse);
      expect(bridge.lastManaged, isEmpty);
    });

    test('a declined second call does not touch the conversation', () async {
      await conversation(u1, 'call-r1');
      kit.emit(CallKitEvent.typeDecline, u2);
      kit.emit(CallKitEvent.typeEnded, u2);
      await pumpEventQueue();
      expect(events, isEmpty);
      expect(reg.isConversation('call-r1'), isTrue);
    });

    test('our own hang-up is not reported back as a system end', () async {
      await conversation(u1, 'call-r1');
      await reg.endConversation('call-r1');
      kit.emit(CallKitEvent.typeEnded, u1);
      await pumpEventQueue();
      expect(kit.log, contains('endCall:$u1'));
      expect(events, isEmpty);
    });

    test('endConversationByUuid and endAllConversations end only ours', () async {
      await conversation(u1, 'call-r1');
      await conversation(u2, 'call-r2');
      await reg.endConversationByUuid(u1.toUpperCase());
      expect(kit.log, contains('endCall:$u1'));
      await reg.endAllConversations();
      expect(kit.log, contains('endCall:$u2'));
      expect(kit.log, isNot(contains('endAllCalls')));
      expect(reg.hasConversations, isFalse);
    });

    test('hanging up before CallKit confirms the start stops the wait', () async {
      kit.confirmStarts = false;
      final started = reg.startOutgoing(displayName: 'A', handle: 'h', roomName: 'call-r1');
      await pumpEventQueue();
      await reg.endConversation('call-r1');
      // Well inside the harness startTimeout: the wait ended with the hang-up.
      expect(await started.timeout(const Duration(milliseconds: 200)), isNull);
      kit.emit(CallKitEvent.typeStart, u1); // CallKit processes the start late
      await pumpEventQueue();
      expect(kit.log.where((l) => l == 'endCall:$u1'), hasLength(1),
          reason: 'ended once by the hang-up, not again as an abandoned start');
    });
  });

  group('dismissRinging', () {
    test('ends ringing calls, keeps conversations and other apps\' calls', () async {
      kit.emit(CallKitEvent.typeAccept, u1, {'extra': {'roomName': 'call-r1'}});
      await pumpEventQueue();
      kit.active = [
        {'id': u1, 'extra': {'roomName': 'call-r1'}},
        {'id': u2, 'extra': {'roomName': 'call-r2'}},
        {'id': 'AAAAAAAA-AAAA-4AAA-8AAA-AAAAAAAAAAAA'}, // WhatsApp: no payload
      ];
      await reg.dismissRinging();
      expect(kit.log.where((l) => l.startsWith('endCall:')), ['endCall:$u2']);
    });

    test('disabled registry: the old endAllCalls', () async {
      await reg.detach();
      reg = build(enabled: false);
      await reg.dismissRinging();
      expect(kit.log, ['endAllCalls']);
    });
  });

  group('endRingingForRoom', () {
    test('ends the room\'s ringing call', () async {
      kit.active = [{'id': u2, 'extra': {'roomName': u2}}];
      expect(await reg.endRingingForRoom(u2), isFalse);
      expect(kit.log, ['endCall:$u2']);
    });

    test('leaves a conversation alone and says so', () async {
      kit.emit(CallKitEvent.typeAccept, u1, {'extra': {'roomName': u1}});
      await pumpEventQueue();
      expect(await reg.endRingingForRoom(u1), isTrue);
      expect(kit.log, isEmpty);
    });

    test('a call CallKit reports answered counts as a conversation — the background isolate has no entries', () async {
      kit.active = [{'id': u2, 'extra': {'roomName': u2}, 'isAccepted': true}];
      expect(await reg.endRingingForRoom(u2), isTrue);
      expect(kit.log, isEmpty);
    });

    test('disabled registry: the old endAllCalls', () async {
      await reg.detach();
      reg = build(enabled: false);
      expect(await reg.endRingingForRoom(u2), isFalse);
      expect(kit.log, ['endAllCalls']);
    });
  });
```

- [ ] **Step 2: Запустить — падает**

Run: `flutter test test/core/platform/system_call_registry_test.dart`
Expected: FAIL — нет `endConversation`, `dismissRinging` и прочего.

- [ ] **Step 3: Реализация**

В `SystemCallRegistry` после `markConnected` добавить:

```dart
  /// Hangs up our side of [roomName]'s conversation in CallKit.
  Future<void> endConversation(String roomName) async {
    final entry = _entryForRoom(roomName);
    if (entry != null) await _end(entry.uuid);
  }

  Future<void> endConversationByUuid(String uuid) async {
    final key = uuid.toLowerCase();
    if (_entries.containsKey(key)) await _end(key);
  }

  Future<void> endAllConversations() async {
    for (final uuid in List.of(_entries.keys)) {
      await _end(uuid);
    }
  }

  /// Ends every CallKit call that is not one of our conversations — what the
  /// blanket endAllCalls() was used for: dismissing ringing calls. Disabled
  /// registry: exactly the old endAllCalls().
  Future<void> dismissRinging() async {
    if (!enabled) return _callKit.endAllCalls();
    for (final raw in await _callKit.activeCalls()) {
      if (raw is! Map) continue;
      final id = (raw['id'] ?? '').toString().toLowerCase();
      // Other apps' calls come without our payload — never ours to end.
      if (id.isEmpty || !raw.containsKey('extra') || _entries.containsKey(id)) continue;
      await _callKit.endCall(id);
    }
  }

  /// Ends [roomName]'s ringing call (cancelled by the caller, answered on
  /// another device, declined in our dialog). Returns true — and ends nothing —
  /// when that call is a conversation: an entry, or a call CallKit reports as
  /// answered. The second check is what protects the device that just picked
  /// up when this runs in the background isolate, where there are no entries.
  /// Disabled registry: the old endAllCalls(), returns false.
  Future<bool> endRingingForRoom(String roomName) async {
    if (!enabled) {
      await _callKit.endAllCalls();
      return false;
    }
    if (_entryForRoom(roomName) != null) return true;
    final uuid = toCallkitId(roomName).toLowerCase();
    for (final raw in await _callKit.activeCalls()) {
      if (raw is! Map || (raw['id'] ?? '').toString().toLowerCase() != uuid) continue;
      if (raw['isAccepted'] == true || raw['accepted'] == true) return true;
      await _callKit.endCall(uuid);
      return false;
    }
    return false;
  }

  Future<void> _end(String uuid) async {
    // Removed first: the ENDED event CallKit sends back is then not "ours",
    // and nobody hangs up a second time.
    final entry = _entries.remove(uuid);
    // Hung up before CallKit confirmed the start: startOutgoing stops waiting
    // now instead of timing out.
    if (entry != null && !entry.started.isCompleted) entry.started.complete(false);
    await _syncManaged();
    await _callKit.endCall(uuid);
  }
```

В `startOutgoing` сразу после ожидания подтверждения (после строки `if (ok) return uuid;`) вставить:

```dart
    // Ended while starting — _end already hung it up; nothing to abandon.
    if (!identical(_entries[uuid], entry)) return null;
```

В `_onCallKitEvent` в `switch` добавить ветку:

```dart
      case CallKitEvent.typeEnded || CallKitEvent.typeDecline || CallKitEvent.typeTimeout:
        // For a conversation DECLINE and ENDED mean the same: the system ended it.
        final entry = _entries.remove(uuid);
        if (entry == null) return;
        unawaited(_syncManaged());
        if (!entry.started.isCompleted) entry.started.complete(false);
        _events.add(SystemCallEndedBySystem(uuid, entry.roomName));
```

- [ ] **Step 4: Тесты проходят**

Run: `flutter test test/core/platform/system_call_registry_test.dart`
Expected: все PASS.

- [ ] **Step 5: Коммит**

```bash
git add lib/core/platform/system_call_registry.dart test/core/platform/system_call_registry_test.dart
git commit -F - <<'EOF'
feat(звонок): реестр снимает звонящие вызовы, не трогая разговор

dismissRinging и endRingingForRoom заменяют сплошной endAllCalls():
тот клал заодно и идущий разговор, как только разговор стал жить в
CallKit. Событие о чужом вызове (отклонённом втором звонке) разговор
больше не завершает — фильтр по UUID.

Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>
EOF
```

---

### Task 8: Реестр — удержание, mute, автовозврат, приём из диалога

**Files:**
- Modify: `lib/core/platform/system_call_registry.dart`
- Test: `test/core/platform/system_call_registry_test.dart`

- [ ] **Step 1: Тесты**

```dart
  group('hold and auto-resume', () {
    Future<void> conversation(String uuid, String room) async {
      kit.emit(CallKitEvent.typeAccept, uuid, {'extra': {'roomName': room}});
      await pumpEventQueue();
    }

    test('call waiting holds the call; the end of the other call resumes it', () async {
      await conversation(u1, 'call-r1');
      kit.emit(CallKitEvent.typeToggleHold, u1, {'isOnHold': true});
      kit.emit(CallKitEvent.typeToggleHold, u1, {'isOnHold': true}); // echo
      await pumpEventQueue();
      expect(events.whereType<SystemCallHeld>().single.bySystem, isTrue);
      expect(reg.isHeldBySystem('call-r1'), isTrue);

      bridge.otherCallsGone();
      await pumpEventQueue();
      expect(kit.log, contains('setHeld:$u1:false'));

      kit.emit(CallKitEvent.typeToggleHold, u1, {'isOnHold': false});
      await pumpEventQueue();
      expect(events.last, isA<SystemCallResumed>());
      expect(reg.isHeldBySystem('call-r1'), isFalse);
    });

    test('no auto-resume while another conversation is active', () async {
      await conversation(u1, 'call-r1');
      await conversation(u2, 'call-r2');
      kit.emit(CallKitEvent.typeToggleHold, u1, {'isOnHold': true});
      await pumpEventQueue();
      bridge.otherCallsGone();
      await pumpEventQueue();
      expect(kit.log, isNot(contains('setHeld:$u1:false')));
    });

    test('a line-switch hold is ours and never auto-resumed', () async {
      await conversation(u1, 'call-r1');
      await reg.holdForLineSwitch('call-r1', true);
      kit.emit(CallKitEvent.typeToggleHold, u1, {'isOnHold': true});
      await pumpEventQueue();
      expect(events.whereType<SystemCallHeld>().single.bySystem, isFalse);
      bridge.otherCallsGone();
      await pumpEventQueue();
      expect(kit.log.where((l) => l == 'setHeld:$u1:false'), isEmpty);
    });

    test('resume() is the overlay button', () async {
      await conversation(u1, 'call-r1');
      await reg.resume('call-r1');
      expect(kit.log, contains('setHeld:$u1:false'));
    });
  });

  group('mute', () {
    test('the system mute button reaches the app', () async {
      kit.emit(CallKitEvent.typeAccept, u1, {'extra': {'roomName': 'call-r1'}});
      await pumpEventQueue();
      kit.emit(CallKitEvent.typeToggleMute, u1, {'isMuted': true});
      await pumpEventQueue();
      final e = events.whereType<SystemCallMuteChanged>().single;
      expect(e.muted, isTrue);
      expect(e.roomName, 'call-r1');
    });

    test('our mute is mirrored into CallKit', () async {
      kit.emit(CallKitEvent.typeAccept, u1, {'extra': {'roomName': 'call-r1'}});
      await pumpEventQueue();
      await reg.setMuted('call-r1', true);
      expect(kit.log, contains('setMuted:$u1:true'));
    });
  });

  group('answerRinging', () {
    test('answers through CallKit and reports the accept', () async {
      final answered = reg.answerRinging(u2);
      await pumpEventQueue();
      expect(kit.log, contains('setCallConnected:$u2'));
      kit.emit(CallKitEvent.typeAccept, u2, {'extra': {'roomName': u2}});
      expect(await answered, isTrue);
    });

    test('false when CallKit stays silent — the dialog takes the old path', () async {
      expect(await reg.answerRinging(u2), isFalse);
    });
  });
```

- [ ] **Step 2: Запустить — падает**

Run: `flutter test test/core/platform/system_call_registry_test.dart`
Expected: FAIL — нет `holdForLineSwitch`, `resume`, `setMuted`, `answerRinging`.

- [ ] **Step 3: Реализация**

Поля класса (рядом с `_abandonedStarts`):

```dart
  /// Holds we asked for ourselves (line switch) — not call waiting.
  final Set<String> _appHolds = {};
  final Map<String, Completer<bool>> _pendingAnswers = {};
```

Методы (после `endRingingForRoom`):

```dart
  /// In-app line switch mirrored into CallKit. Not call waiting, so never
  /// resumed automatically.
  Future<void> holdForLineSwitch(String roomName, bool onHold) async {
    final entry = _entryForRoom(roomName);
    if (entry == null) return;
    if (onHold) {
      _appHolds.add(entry.uuid);
    } else {
      _appHolds.remove(entry.uuid);
    }
    await _callKit.setHeld(entry.uuid, onHold);
  }

  /// The "Resume" button of the hold overlay.
  Future<void> resume(String roomName) async {
    final entry = _entryForRoom(roomName);
    if (entry != null) await _callKit.setHeld(entry.uuid, false);
  }

  Future<void> setMuted(String roomName, bool muted) async {
    final entry = _entryForRoom(roomName);
    if (entry != null) await _callKit.setMuted(entry.uuid, muted);
  }

  /// Our dialog's "Answer": answers the ringing CallKit call, so the call
  /// takes the same path as an answer on the CallKit UI (main.dart's accept
  /// handler connects and navigates). False when CallKit did not confirm in
  /// [answerTimeout] — the dialog then takes its old in-app path.
  Future<bool> answerRinging(String roomName) async {
    if (!enabled) return false;
    final uuid = toCallkitId(roomName).toLowerCase();
    final pending = Completer<bool>();
    _pendingAnswers[uuid] = pending;
    try {
      await _callKit.setCallConnected(uuid);
    } catch (e) {
      debugPrint('[SystemCall] answer via CallKit failed: $e');
      if (!pending.isCompleted) pending.complete(false);
    }
    final ok = await pending.future.timeout(answerTimeout, onTimeout: () => false);
    _pendingAnswers.remove(uuid);
    return ok;
  }
```

В `_onAccepted` первой строкой:

```dart
    final pending = _pendingAnswers.remove(uuid);
    if (pending != null && !pending.isCompleted) pending.complete(true);
```

В `_end` после `_entries.remove(uuid);` добавить `_appHolds.remove(uuid);`, и так же в ветке `typeEnded || …` после `_entries.remove(uuid)` (перед `if (entry == null) return;` — строкой `_appHolds.remove(uuid);`).

В `_onCallKitEvent` добавить ветки:

```dart
      case CallKitEvent.typeToggleHold:
        final entry = _entries[uuid];
        if (entry == null) return;
        if (event.data?['isOnHold'] == true) {
          final byApp = _appHolds.contains(uuid);
          final held = byApp ? _State.heldByApp : _State.heldBySystem;
          if (entry.state == held) return; // echo
          entry.state = held;
          _events.add(SystemCallHeld(uuid, entry.roomName, bySystem: !byApp));
        } else {
          _appHolds.remove(uuid);
          if (entry.state == _State.active) return; // echo
          entry.state = _State.active;
          _events.add(SystemCallResumed(uuid, entry.roomName));
        }
      case CallKitEvent.typeToggleMute:
        final entry = _entries[uuid];
        if (entry == null) return;
        _events.add(SystemCallMuteChanged(uuid, entry.roomName,
            muted: event.data?['isMuted'] == true));
```

`_onOtherCallsEnded` заменить:

```dart
  /// The call that put us on hold is over and nothing else is going on:
  /// take the conversation back (agreed with the user 2026-09-24 — resume by
  /// itself, not by a button). If iOS resumes it first, the hold event makes
  /// this a no-op.
  void _onOtherCallsEnded() {
    // A start CallKit hasn't confirmed yet counts as active: the user is
    // opening a new line, and resuming the held one now would fight it.
    if (_entries.values.any((e) => e.state == _State.active || e.state == _State.starting)) return;
    for (final entry in _entries.values) {
      if (entry.state == _State.heldBySystem) {
        unawaited(_callKit.setHeld(entry.uuid, false));
        return;
      }
    }
  }
```

- [ ] **Step 4: Тесты проходят**

Run: `flutter test test/core/platform/`
Expected: все PASS.

- [ ] **Step 5: Коммит**

```bash
git add lib/core/platform/system_call_registry.dart test/core/platform/system_call_registry_test.dart
git commit -F - <<'EOF'
feat(звонок): удержание по ожиданию вызова и автовозврат

«Удержать и ответить» на звонке WhatsApp ставит разговор на паузу;
когда чужой звонок закончился и ничего другого не идёт, реестр сам
снимает удержание. Своё удержание (переключение линий) само не
снимается. Mute синхронизирован с системным интерфейсом, «Ответить» в
нашем диалоге отвечает через CallKit.

Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>
EOF
```

---

### Task 9: `CallStateService` — микрофон на системном удержании и хуки линий

**Files:**
- Modify: `lib/core/services/call_state_service.dart`
- Test: `test/core/call_state_service_test.dart`

- [ ] **Step 1: Тесты**

В конец `main()` файла `test/core/call_state_service_test.dart`:

```dart
  // ── System calls (iOS CallKit) ───────────────────────────────────────────

  group('system hold', () {
    late MockRoom room;
    late MockLocalParticipant mic;

    void line({required bool micOn}) {
      room = _makeRoom(micEnabled: micOn);
      mic = room.localParticipant! as MockLocalParticipant;
      svc.setRoom(room, 'room-1', 'conv-1');
    }

    test('hold turns an open mic off, resume turns it back on', () async {
      line(micOn: true);
      await svc.applySystemHold('room-1');
      verify(() => mic.setMicrophoneEnabled(false)).called(1);
      expect(svc.activeLine!.heldBySystem, isTrue);
      await svc.applySystemResume('room-1');
      verify(() => mic.setMicrophoneEnabled(true)).called(1);
      expect(svc.activeLine!.heldBySystem, isFalse);
    });

    test('a mic muted before the hold stays muted after it', () async {
      line(micOn: false);
      await svc.applySystemHold('room-1');
      await svc.applySystemResume('room-1');
      verifyNever(() => mic.setMicrophoneEnabled(true));
    });

    test('repeats are no-ops', () async {
      line(micOn: true);
      await svc.applySystemHold('room-1');
      await svc.applySystemHold('room-1');
      verify(() => mic.setMicrophoneEnabled(false)).called(1);
      await svc.applySystemResume('room-1');
      await svc.applySystemResume('room-1');
      verify(() => mic.setMicrophoneEnabled(true)).called(1);
    });

    test('system mute applies, but not while held', () async {
      line(micOn: true);
      await svc.applySystemMute('room-1', true);
      verify(() => mic.setMicrophoneEnabled(false)).called(1);
      await svc.applySystemHold('room-1');
      clearInteractions(mic);
      await svc.applySystemMute('room-1', false);
      verifyNever(() => mic.setMicrophoneEnabled(true));
    });
  });

  group('line hooks', () {
    final ended = <String>[];
    final holds = <String>[];

    setUp(() {
      ended.clear();
      holds.clear();
      svc.onLineEnded = (room) async => ended.add(room);
      svc.onLineHoldChanged = (room, onHold) async => holds.add('$room:$onHold');
    });

    tearDown(() {
      svc.onLineEnded = null;
      svc.onLineHoldChanged = null;
    });

    test('every path that removes a line reports it', () async {
      svc.setRoom(_makeRoom(), 'a', 'c1');
      svc.setRoom(_makeRoom(), 'b', 'c2');
      await svc.endLine('b');
      expect(ended, ['b']);
      svc.notifyEnded();
      expect(ended, ['b', 'a']);
      svc.setRoom(_makeRoom(), 'x', 'c3');
      svc.setRoom(_makeRoom(), 'y', 'c4');
      await svc.endCall();
      expect(ended, containsAll(['x', 'y']));
    });

    test('line switching is mirrored as holds', () async {
      svc.setRoom(_makeRoom(), 'a', 'c1');
      svc.setRoom(_makeRoom(), 'b', 'c2');
      await svc.holdAndSwitch('a');
      expect(holds, ['b:true', 'a:false']);
    });

    test('ending the active line brings the next one back', () async {
      svc.setRoom(_makeRoom(), 'a', 'c1');
      svc.setRoom(_makeRoom(), 'b', 'c2');
      await svc.endLine('b');
      expect(holds, ['a:false']);
    });
  });
```

- [ ] **Step 2: Запустить — падает**

Run: `flutter test test/core/call_state_service_test.dart`
Expected: FAIL — нет `applySystemHold`, `heldBySystem`, `onLineEnded`.

- [ ] **Step 3: Реализация**

В `CallLine` после `DateTime? connectedAt;`:

```dart
  /// iOS put this line on hold for another call (call waiting).
  bool heldBySystem = false;
  /// Mic state when that hold began — restored on resume.
  bool micOnBeforeSystemHold = false;
```

В `CallStateService` после `canAddLine`:

```dart
  // ── System calls (iOS CallKit) ───────────────────────────────────────────

  /// Ends the CallKit call of every line that goes away, whichever path
  /// removes it. Set in main.dart; null on platforms without CallKit calls.
  Future<void> Function(String roomName)? onLineEnded;

  /// Mirrors in-app line switching into CallKit holds.
  Future<void> Function(String roomName, bool onHold)? onLineHoldChanged;

  void _reportLineEnded(String roomName) {
    final hook = onLineEnded;
    if (hook != null) unawaited(hook(roomName));
  }

  void _reportLineHold(String roomName, bool onHold) {
    final hook = onLineHoldChanged;
    if (hook != null) unawaited(hook(roomName, onHold));
  }

  /// Call waiting took the audio: the peer gets a muted mic, and whatever the
  /// mic was is remembered for the resume.
  Future<void> applySystemHold(String roomName) async {
    final line = _lines[roomName];
    if (line == null || line.heldBySystem) return;
    line.heldBySystem = true;
    line.micOnBeforeSystemHold = line.room.localParticipant?.isMicrophoneEnabled() ?? false;
    try {
      await line.room.localParticipant?.setMicrophoneEnabled(false);
    } catch (_) {}
  }

  Future<void> applySystemResume(String roomName) async {
    final line = _lines[roomName];
    if (line == null || !line.heldBySystem) return;
    line.heldBySystem = false;
    if (!line.micOnBeforeSystemHold) return;
    try {
      await line.room.localParticipant?.setMicrophoneEnabled(true);
    } catch (_) {}
  }

  /// The mute button of the system call UI. Ignored while held — the mic is
  /// off then, and the resume restores it.
  Future<void> applySystemMute(String roomName, bool muted) async {
    final line = _lines[roomName];
    if (line == null || line.heldBySystem) return;
    try {
      await line.room.localParticipant?.setMicrophoneEnabled(!muted);
    } catch (_) {}
  }
```

В `holdAndSwitch` после `current.isOnHold = true;` добавить `_reportLineHold(current.roomName, true);`, после `target.isOnHold = false;` — `_reportLineHold(targetRoomName, false);`.

В `connectInBackground` после `current.isOnHold = true;` добавить `_reportLineHold(current.roomName, true);`. Это вторая линия, принятая через CallKit или диалог: первая уходит на удержание и в CallKit — иначе у iOS два «активных» звонка, хотя слышна одна линия. Если iOS уже удержала первую сама («Удержать и ответить»), плагин на неизменное состояние только шлёт эхо (P7), лишнего действия CallKit нет. Тест — в группе `line hooks`, если в `sl` просто регистрируется `DioClient`, чей `post` бросает: `setRoom(… 'a' …)`, затем `connectInBackground('b', 'c2')` → `false`, а в `holds` — `'a:true'`.

В `endLine` после `clearAnsweredState(name);` добавить `if (line != null) _reportLineEnded(name);`; в ветке переключения после `next.isOnHold = false;` — `_reportLineHold(next.roomName, false);`.

В `endCall()` после `_lines.clear();` добавить:

```dart
    for (final line in lines) {
      _reportLineEnded(line.roomName);
    }
```

`notifyEnded()` заменить:

```dart
  void notifyEnded() {
    // Remove the active line (or all if unknown)
    if (_activeRoomName != null) {
      final ended = _activeRoomName!;
      if (_lines.remove(ended) != null) _reportLineEnded(ended);
      if (_lines.isNotEmpty) {
        final next = _lines.values.first;
        _activeRoomName = next.roomName;
        next.isOnHold = false;
        _reportLineHold(next.roomName, false);
      } else {
        _activeRoomName = null;
      }
    } else {
      for (final name in _lines.keys) {
        _reportLineEnded(name);
      }
      _lines.clear();
    }
    _bgConnecting = false;
    _bgGeneration++;
    _stateCtrl.add(_lines.isNotEmpty);
  }
```

- [ ] **Step 4: Тесты проходят**

Run: `flutter test test/core/call_state_service_test.dart test/features/voice/call_answered_routing_test.dart`
Expected: все PASS (старые тесты тоже).

- [ ] **Step 5: Коммит**

```bash
git add lib/core/services/call_state_service.dart test/core/call_state_service_test.dart
git commit -F - <<'EOF'
feat(звонок): линия на системном удержании и хуки для CallKit

На удержании по ожиданию вызова микрофон выключается и запоминается,
на возврате — включается, только если был включён. Любой путь, которым
уходит линия, сообщает об этом — CallKit-звонок снимается вместе с ней.

Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>
EOF
```

---

### Task 10: LiveKit не меняет категорию посреди разговора в CallKit

**Files:**
- Create: `lib/core/platform/call_audio_configuration.dart`
- Test: `test/core/platform/call_audio_configuration_test.dart`

- [ ] **Step 1: Тест**

```dart
// test/core/platform/call_audio_configuration_test.dart
// ignore_for_file: implementation_imports
import 'package:flutter_test/flutter_test.dart';
import 'package:livekit_client/src/support/native_audio.dart';
import 'package:livekit_client/src/track/audio_management.dart';
import 'package:taler_id_mobile/core/platform/call_audio_configuration.dart';

void main() {
  tearDown(() => onConfigureNativeAudio = defaultNativeAudioConfigurationFunc);

  test('while CallKit owns a conversation every track state keeps the call category', () async {
    installCallAudioConfiguration(callKitOwnsAudio: () => true);
    for (final state in AudioTrackState.values) {
      final config = await onConfigureNativeAudio(state);
      expect(config.appleAudioCategory, AppleAudioCategory.playAndRecord, reason: '$state');
      expect(config.appleAudioMode, AppleAudioMode.voiceChat, reason: '$state');
      expect(config.appleAudioCategoryOptions,
          isNot(contains(AppleAudioCategoryOption.mixWithOthers)), reason: '$state');
    }
  });

  test('otherwise LiveKit decides as before', () async {
    installCallAudioConfiguration(callKitOwnsAudio: () => false);
    final config = await onConfigureNativeAudio(AudioTrackState.none);
    expect(config.appleAudioCategory, AppleAudioCategory.soloAmbient);
  });
}
```

- [ ] **Step 2: Запустить — падает**

Run: `flutter test test/core/platform/call_audio_configuration_test.dart`
Expected: FAIL — файла нет.

- [ ] **Step 3: Реализация**

```dart
// lib/core/platform/call_audio_configuration.dart
// LiveKit 2.4.1 does not export its audio-session hook; the implementation
// imports are the only way to it.
// ignore_for_file: implementation_imports
import 'package:livekit_client/src/support/native_audio.dart';
import 'package:livekit_client/src/track/audio_management.dart';

/// LiveKit re-applies its own AVAudioSession preset whenever the set of audio
/// tracks changes, and some presets (`playback`, `soloAmbient`) can't record.
/// While CallKit owns a conversation the session keeps the call's category;
/// otherwise LiveKit's defaults apply as before.
void installCallAudioConfiguration({required bool Function() callKitOwnsAudio}) {
  onConfigureNativeAudio = (state) async {
    if (callKitOwnsAudio()) {
      return NativeAudioConfiguration(
        appleAudioCategory: AppleAudioCategory.playAndRecord,
        appleAudioCategoryOptions: {
          AppleAudioCategoryOption.allowBluetooth,
          AppleAudioCategoryOption.allowBluetoothA2DP,
        },
        appleAudioMode: AppleAudioMode.voiceChat,
      );
    }
    return defaultNativeAudioConfigurationFunc(state);
  };
}
```

- [ ] **Step 4: Тест проходит**

Run: `flutter test test/core/platform/call_audio_configuration_test.dart`
Expected: 2 PASS.

- [ ] **Step 5: Коммит**

```bash
git add lib/core/platform/call_audio_configuration.dart test/core/platform/call_audio_configuration_test.dart
git commit -F - <<'EOF'
fix(звонок): LiveKit не переключает категорию сессии посреди разговора

При каждой смене набора дорожек LiveKit ставил свой пресет — вплоть до
playback, в котором не пишется микрофон. Пока разговор в CallKit,
категория остаётся звонковой.

Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>
EOF
```

---

### Task 11: Нативный мост `CallKitAudioBridge.swift`

**Files:**
- Create: `ios/Runner/CallKitAudioBridge.swift`
- Modify: `ios/Runner.xcodeproj/project.pbxproj` (4 строки)
- Modify: `ios/Runner/AppDelegate.swift`

- [ ] **Step 1: Файл моста**

```swift
// ios/Runner/CallKitAudioBridge.swift
import AVFoundation
import CallKit
import Flutter
import WebRTC
import flutter_callkit_incoming

/// Single meeting point of CallKit and WebRTC for Taler ID conversations.
/// While a conversation is in CallKit, CallKit owns the audio session and
/// WebRTC runs in manual-audio mode, starting its audio unit exactly when
/// CallKit activates the session: call waiting, hold and resume become
/// deactivate/activate instead of interruptions we had to recover from.
/// See docs/superpowers/specs/2026-09-24-ios-calls-through-callkit-design.md.
final class CallKitAudioBridge: NSObject {
  static let shared = CallKitAudioBridge()

  private var channel: FlutterMethodChannel?
  /// Conversations Dart registered (SystemCallRegistry).
  private var registeredByDart = Set<UUID>()
  /// Incoming calls answered through CallKit, known here before Dart can
  /// register them. CallKit activates the session right after the answer —
  /// on a killed app long before Flutter runs — and the plugin's fake
  /// "interruption ended" on that activation must not reach the old recovery.
  private var answeredHere = Set<UUID>()
  /// CallKit has our session activated right now.
  private var activatedSession: AVAudioSession?
  /// WebRTC was told the session is active (audioSessionDidActivate) and must
  /// hear about the deactivation too, managed or not by then — otherwise it
  /// believes the session is still live and never activates it again (the
  /// assistant after a call would go silent).
  private var webRTCKnowsActive = false

  private var managedCalls: Set<UUID> { registeredByDart.union(answeredHere) }

  /// A conversation is in CallKit: CallKit owns the audio session.
  var isManaging: Bool { !managedCalls.isEmpty }

  func register(messenger: FlutterBinaryMessenger) {
    let ch = FlutterMethodChannel(name: "taler_id/callkit_audio", binaryMessenger: messenger)
    ch.setMethodCallHandler { [weak self] call, result in
      guard let self else { result(nil); return }
      switch call.method {
      case "setManagedCalls":
        // A shape mismatch must not read as "manage nothing" — that would
        // switch manual audio off in the middle of a call.
        guard let ids = call.arguments as? [String] else {
          result(FlutterError(code: "bad_args", message: "setManagedCalls expects [String]", details: nil))
          return
        }
        let uuids = ids.compactMap { UUID(uuidString: $0) }
        if uuids.count != ids.count {
          NSLog("[CallKitAudio] setManagedCalls: dropped \(ids.count - uuids.count) malformed id(s)")
        }
        self.setManagedCalls(uuids)
        result(nil)
      case "prepareCallAudio":
        self.prepareCallAudio()
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
    channel = ch
  }

  /// The category CallKit activates the session with — set before the answer
  /// or start is fulfilled; no setActive here, that is CallKit's.
  func prepareCallAudio() {
    do {
      try AVAudioSession.sharedInstance().setCategory(
        .playAndRecord, mode: .voiceChat, options: [.allowBluetooth, .allowBluetoothA2DP])
    } catch {
      NSLog("[CallKitAudio] prepareCallAudio failed: \(error)")
    }
  }

  /// onAccept: a call-screen conversation (not a group or mesh call) is ours
  /// from the moment it is answered.
  func callAnswered(_ call: Call) {
    guard Self.isCallScreenConversation(call) else { return }
    updateManaged { answeredHere.insert(call.uuid) }
  }

  /// onDecline / onEnd / the call observer: the call is over.
  func callFinished(_ uuid: UUID) {
    guard answeredHere.contains(uuid) else { return }
    updateManaged { answeredHere.remove(uuid) }
  }

  func didActivate(_ session: AVAudioSession) {
    activatedSession = session
    NSLog("[CallKitAudio] didActivate managing=\(isManaging)")
    if isManaging { enableWebRTCAudio(session) }
  }

  func didDeactivate(_ session: AVAudioSession) {
    activatedSession = nil
    NSLog("[CallKitAudio] didDeactivate managing=\(isManaging)")
    let rtc = RTCAudioSession.sharedInstance()
    if webRTCKnowsActive {
      rtc.audioSessionDidDeactivate(session)
      webRTCKnowsActive = false
    }
    if isManaging { rtc.isAudioEnabled = false }
  }

  /// CXCallObserver hook while managing: tells Dart once no call other than
  /// our conversations remains (the WhatsApp call that held us is over).
  func callChanged(_ observer: CXCallObserver, _ call: CXCall) {
    guard isManaging, call.hasEnded else { return }
    if managedCalls.contains(call.uuid) {
      // One of ours ended — possibly without onEnd (a CallKit reset).
      callFinished(call.uuid)
      return
    }
    let othersLeft = observer.calls.contains { other in
      other.uuid != call.uuid && !other.hasEnded && !managedCalls.contains(other.uuid)
    }
    NSLog("[CallKitAudio] other call ended, othersLeft=\(othersLeft)")
    if !othersLeft {
      channel?.invokeMethod("otherCallsEnded", arguments: nil)
    }
  }

  private func setManagedCalls(_ ids: [UUID]) {
    let registered = Set(ids)
    updateManaged {
      // A call Dart dropped is over for us too — also after a CallKit reset,
      // which the plugin reports to Dart (P9) but which may reach neither
      // onEnd nor the call observer here.
      answeredHere.subtract(registeredByDart.subtracting(registered))
      registeredByDart = registered
    }
  }

  private func updateManaged(_ change: () -> Void) {
    let wasManaging = isManaging
    change()
    NSLog("[CallKitAudio] managed=\(managedCalls.count) sessionActive=\(activatedSession != nil)")
    if !wasManaging && isManaging, let session = activatedSession {
      // CallKit switched the session on before the call was known as ours.
      enableWebRTCAudio(session)
    } else if wasManaging && !isManaging {
      RTCAudioSession.sharedInstance().useManualAudio = false
    }
  }

  /// Group and mesh calls ring through CallKit too but run their own audio;
  /// the same filter as SystemCallRegistry._onAccepted.
  private static func isCallScreenConversation(_ call: Call) -> Bool {
    guard let extra = call.data.extra as? [String: Any],
          let room = extra["roomName"] as? String, !room.isEmpty else { return false }
    return !room.hasPrefix("group-") && (extra["kind"] as? String) != "mesh_gc"
  }

  private func enableWebRTCAudio(_ session: AVAudioSession) {
    let rtc = RTCAudioSession.sharedInstance()
    if !webRTCKnowsActive {
      rtc.audioSessionDidActivate(session)
      webRTCKnowsActive = true
    }
    // Allow audio first, then go manual: the other order would stop an audio
    // unit that is already running.
    rtc.isAudioEnabled = true
    rtc.useManualAudio = true
  }
}
```

- [ ] **Step 2: Добавить файл в Xcode-проект**

В `ios/Runner.xcodeproj/project.pbxproj` четыре вставки (ID продолжают ручную серию `A1B2C3D4…AABBCCDD`, следующий номер — 08):

1. После строки 17 (`74858FAF… /* AppDelegate.swift in Sources */ = {isa = PBXBuildFile; …};`):
```
		A1B2C3D401000008AABBCCDD /* CallKitAudioBridge.swift in Sources */ = {isa = PBXBuildFile; fileRef = A1B2C3D402000008AABBCCDD /* CallKitAudioBridge.swift */; };
```
2. После строки 90 (`74858FAE… /* AppDelegate.swift */ = {isa = PBXFileReference; …};`):
```
		A1B2C3D402000008AABBCCDD /* CallKitAudioBridge.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = CallKitAudioBridge.swift; sourceTree = "<group>"; };
```
3. В группе Runner после `74858FAE1ED2DC5600515810 /* AppDelegate.swift */,`:
```
				A1B2C3D402000008AABBCCDD /* CallKitAudioBridge.swift */,
```
4. В фазе Sources (`97C146EA1CF9000F007C117D /* Sources */`) после `74858FAF1ED2DC5600515810 /* AppDelegate.swift in Sources */,`:
```
				A1B2C3D401000008AABBCCDD /* CallKitAudioBridge.swift in Sources */,
```

Проверка: `grep -c "A1B2C3D40[12]000008AABBCCDD" ios/Runner.xcodeproj/project.pbxproj` → `4`.

- [ ] **Step 3: AppDelegate — регистрация моста и делегат плагина**

В `ios/Runner/AppDelegate.swift` после `import flutter_callkit_incoming` добавить `import WebRTC`.

В `application(_:didFinishLaunchingWithOptions:)` после регистрации `AudioPlaybackChannel`:

```swift
    // CallKit → WebRTC bridge. Registered through a plugin registrar, not the
    // window's controller: on a VoIP cold start the window may not exist yet,
    // and that is exactly when the answered call needs the bridge.
    if let registrar = self.registrar(forPlugin: "CallKitAudioBridge") {
      CallKitAudioBridge.shared.register(messenger: registrar.messenger())
    }
```

В `pushRegistry(_:didReceiveIncomingPushWith:for:completion:)` после `let data = flutter_callkit_incoming.Data(args: args as NSDictionary)`:

```swift
      // Every conversation lives in CallKit now: the plugin must not configure
      // or activate the session itself, and the call must be holdable for
      // WhatsApp/cellular call waiting (same settings as CallKitMobile).
      data.configureAudioSession = false
      data.supportsHolding = true
      data.audioSessionMode = "voiceChat"
      // The push carries no duration: the plugin's 30 s default would ring
      // half as long as the same call arriving over the socket (60 s).
      data.duration = 60000
```

В `pushRegistry(...)` два комментария ссылаются на «Flutter's `_toCallkitId`» — такой функции нет. Заменить упоминание на «`toCallkitId` in `lib/core/platform/callkit_support.dart`» (логику не трогать).

В конец файла:

```swift
extension AppDelegate: CallkitIncomingAppDelegate {
  // Conforming hands fulfilment of these actions to us — the plugin no
  // longer fulfils them itself. Every path must fulfil or fail. (Answering an
  // outgoing call is refused inside the plugin, PATCH P11.)

  func onAccept(_ call: Call, _ action: CXAnswerCallAction) {
    CallKitAudioBridge.shared.callAnswered(call)
    CallKitAudioBridge.shared.prepareCallAudio()
    action.fulfill()
  }

  func onDecline(_ call: Call, _ action: CXEndCallAction) {
    CallKitAudioBridge.shared.callFinished(call.uuid)
    action.fulfill()
  }

  func onEnd(_ call: Call, _ action: CXEndCallAction) {
    CallKitAudioBridge.shared.callFinished(call.uuid)
    action.fulfill()
  }

  func onTimeOut(_ call: Call) {}

  func didActivateAudioSession(_ audioSession: AVAudioSession) {
    CallKitAudioBridge.shared.didActivate(audioSession)
  }

  func didDeactivateAudioSession(_ audioSession: AVAudioSession) {
    CallKitAudioBridge.shared.didDeactivate(audioSession)
  }
}
```

- [ ] **Step 4: Сборка**

```bash
flutter build ios --debug --no-codesign --flavor dev -t lib/main_dev.dart \
  --dart-define=FLAVOR=dev --dart-define=BASE_URL=https://staging.id.taler.tirol 2>&1 | tail -5
```
Expected: `✓ Built build/ios/iphoneos/Runner.app`. Если Swift ругается на неоднозначность `Call` — писать `flutter_callkit_incoming.Call`.

- [ ] **Step 5: Коммит**

```bash
git add ios/Runner/CallKitAudioBridge.swift ios/Runner/AppDelegate.swift ios/Runner.xcodeproj/project.pbxproj
git commit -F - <<'EOF'
feat(звонок): мост CallKit → WebRTC на iOS

Пока разговор в CallKit, сессию включает и выключает только CallKit, а
WebRTC в ручном режиме запускает звук ровно по didActivate. Удержание
и возврат становятся «сессию отобрали/вернули», а не перерывом, после
которого звук надо было вытаскивать. Приём с заблокированного экрана
убитого приложения: CallKit включает звук раньше, чем стартует Flutter,
мост запоминает это и передаёт WebRTC, когда Dart зарегистрирует
звонок.

Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>
EOF
```

---

### Task 12: AppDelegate — старая машинерия молчит, пока разговор в CallKit

**Files:**
- Modify: `ios/Runner/AppDelegate.swift`

- [ ] **Step 1: Перерывы, маршруты, наблюдатель звонков**

В начало `handleAudioInterruption(_:)` (до `guard let info`):

```swift
    // CallKit owns the session of a managed conversation: hold and resume are
    // its deactivate/activate, not interruptions to recover from — and the
    // plugin posts a fake "interruption ended" on every activation.
    if CallKitAudioBridge.shared.isManaging { return }
```

В начало `handleRouteChange(_:)`:

```swift
    if CallKitAudioBridge.shared.isManaging { return }
```

В начало `callObserver(_:callChanged:)`:

```swift
    if CallKitAudioBridge.shared.isManaging {
      CallKitAudioBridge.shared.callChanged(callObserver, call)
      return
    }
```

- [ ] **Step 2: Методы `taler_id/audio` не включают и не выключают сессию**

Добавить в класс `AppDelegate`:

```swift
  /// Only CallKit switches the session of a managed conversation on; our own
  /// setActive(true) there could even take the audio back from a WhatsApp
  /// call that holds us.
  private func activateUnlessCallKitOwns(_ session: AVAudioSession, options: AVAudioSession.SetActiveOptions = []) throws {
    if CallKitAudioBridge.shared.isManaging { return }
    try session.setActive(true, options: options)
  }
```

В `handleAudioMethodCall`:
- в `playRingback`, `setSpeaker`, трёх ветках `setAudioOutput`, `setAudioSessionForVideo`, `prepareForPlayback`, `restoreVoiceChat` заменить `try session.setActive(true)` на `try activateUnlessCallKitOwns(session)`;
- в `requestAudioFocus` заменить `try session.setActive(true, options: .notifyOthersOnDeactivation)` на `try activateUnlessCallKitOwns(session, options: .notifyOthersOnDeactivation)`;
- в `restoreVoiceChat` опции категории сделать зависимыми от режима:
  ```swift
          let options: AVAudioSession.CategoryOptions = CallKitAudioBridge.shared.isManaging
            ? [.allowBluetooth, .allowBluetoothA2DP]
            : [.mixWithOthers, .allowBluetooth, .allowBluetoothA2DP]
          do {
            try session.setCategory(.playAndRecord, mode: .voiceChat, options: options)
            try activateUnlessCallKitOwns(session)
            result(nil)
          } catch {
            result(nil)
          }
  ```
- в начало веток `deactivateAudioSession`, `enableCallAudioMix`, `disableCallAudioMix`:
  ```swift
          if CallKitAudioBridge.shared.isManaging { result(nil); return }
  ```

Проверка, что не осталось прямых включений в обработчике:
```bash
awk '/private func handleAudioMethodCall/,/^  }$/' ios/Runner/AppDelegate.swift | grep -n "setActive(true"
```
Expected: пусто.

- [ ] **Step 3: Сборка**

```bash
flutter build ios --debug --no-codesign --flavor dev -t lib/main_dev.dart \
  --dart-define=FLAVOR=dev --dart-define=BASE_URL=https://staging.id.taler.tirol 2>&1 | tail -5
```
Expected: `✓ Built build/ios/iphoneos/Runner.app`.

- [ ] **Step 4: Коммит**

```bash
git add ios/Runner/AppDelegate.swift
git commit -F - <<'EOF'
fix(звонок): восстановление звука не борется с CallKit

Пока разговор в CallKit, наш код больше не включает и не выключает
сессию сам, не ставит .mixWithOthers и не отвечает на перерывы — всё
это делает CallKit. Для звонков без CallKit (симулятор, отказ системы)
старый путь не тронут.

Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>
EOF
```

---

### Task 13: `main.dart` — реестр до `runApp` и связка с `CallStateService`

**Files:**
- Modify: `lib/main.dart`

- [ ] **Step 1: Импорты**

```dart
import 'core/platform/call_audio_configuration.dart';
import 'core/platform/system_call_registry.dart';
```

- [ ] **Step 2: Функция связки**

Перед `void _setupCallkitListener()`:

```dart
/// iOS: every conversation lives in CallKit (SystemCallRegistry). Wires the
/// registry to the call lines. Must run before [_setupCallkitListener]: the
/// registry has to see an accept that launched a killed app before the
/// accept handler acts on it.
void _wireSystemCalls() {
  final registry = SystemCallRegistry.instance;
  if (!registry.enabled) return;
  final calls = CallStateService.instance;
  registry.attach();
  calls.onLineEnded = registry.endConversation;
  calls.onLineHoldChanged = registry.holdForLineSwitch;
  installCallAudioConfiguration(callKitOwnsAudio: () => registry.hasConversations);
  registry.events.listen((event) {
    final room = event.roomName;
    if (room == null) return;
    switch (event) {
      case SystemCallHeld(bySystem: true):
        calls.applySystemHold(room);
      case SystemCallResumed():
        calls.applySystemResume(room);
      case SystemCallMuteChanged(:final muted):
        calls.applySystemMute(room, muted);
      case SystemCallEndedBySystem():
        // The line on display is hung up by the call screen, or by the
        // dashboard behind the banner. A held background line has nobody
        // else to do it.
        if (calls.roomName != room) _endBackgroundLine(room);
      case SystemCallHeld():
        break;
    }
  });
}

Future<void> _endBackgroundLine(String roomName) async {
  final calls = CallStateService.instance;
  for (final line in calls.allLines) {
    if (line.roomName != roomName) continue;
    final convId = line.conversationId;
    if (convId != null) {
      try {
        sl<MessengerRemoteDataSource>().sendCallEnded(convId, roomName);
      } catch (_) {}
    }
    await calls.endLine(roomName);
    return;
  }
}
```

- [ ] **Step 3: Вызов до слушателя CallKit**

В `main()` перед `_setupCallkitListener();`:

```dart
  _wireSystemCalls();
```

- [ ] **Step 4: Приём, ответ на который уже дан на другом устройстве**

В `_setupCallkitListener` заменить

```dart
      try { CallKitPlatform.instance.endAllCalls(); } catch (_) {}
      return;
```
(внутри `if (CallStateService.instance.isAnsweredElsewhere(roomName))`) на

```dart
      final registry = SystemCallRegistry.instance;
      if (registry.enabled) {
        // It was just answered here: end exactly that call, not every call.
        try { registry.endConversation(roomName); } catch (_) {}
      } else {
        try { CallKitPlatform.instance.endAllCalls(); } catch (_) {}
      }
      return;
```

- [ ] **Step 5: Холодный старт — принятый вызов, событие о котором потерялось**

В `_checkInitialCallKitCall` перед строкой `final e2eeParam = e2eeKey != null ? …` (ветка 1-на-1) вставить:

```dart
      if (call['isAccepted'] == true || call['accepted'] == true) {
        await SystemCallRegistry.instance.adoptAnswered(
            uuid: (call['id'] ?? '').toString(), roomName: roomName);
      }
```

- [ ] **Step 6: Анализ и тесты**

```bash
flutter analyze lib/main.dart 2>&1 | grep -cE "^\s*(error|warning) "
flutter test test/core/
```
Expected: `0`; тесты PASS.

- [ ] **Step 7: Коммит**

```bash
git add lib/main.dart
git commit -F - <<'EOF'
feat(звонок): реестр CallKit подключается до старта приложения

Реестр видит приём, который разбудил убитое приложение, раньше
обработчика приёма; удержание и mute от системы доходят до линий
звонка; линия на удержании, завершённая системой, завершается и у
собеседника.

Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>
EOF
```

---

### Task 14: Экран звонка — разговор заводится в CallKit

**Files:**
- Modify: `lib/features/voice/presentation/screens/voice_call_screen.dart`

- [ ] **Step 1: Импорт и поля**

Импорт рядом с `call_kit.dart`:
```dart
import '../../../../core/platform/system_call_registry.dart';
```

После `bool _onHold = false;`:

```dart
  /// CallKit uuid of this conversation (iOS). Null: no CallKit call — Android,
  /// desktop, the simulator, or iOS refused and the call runs the old way.
  String? _systemCallUuid;
  bool get _systemCallManaged => _systemCallUuid != null;
  /// iOS put this conversation on hold for another call (call waiting).
  bool _heldBySystem = false;
  Future<String?>? _systemCallRegistration;
```

- [ ] **Step 2: Помощники**

Перед `Future<void> _connect() async {`:

```dart
  /// iOS: puts this conversation into CallKit unless it is there already
  /// (answered through CallKit). Null: the call runs without CallKit.
  ///
  /// Runs synchronously from initState for outgoing calls (`_initCall` →
  /// `_connect` with no await in between), so no `context` lookups here —
  /// AppLocalizations.of would throw before initState completes.
  Future<String?> _registerSystemCall() {
    final registry = SystemCallRegistry.instance;
    final room = _roomName ?? widget.roomName;
    final existing = room == null ? null : registry.uuidForRoom(room);
    if (existing != null) return Future.value(existing);
    final name = _currentCalleeName ?? widget.calleeName ?? _publicRoomTitle ?? 'Taler ID';
    return registry.startOutgoing(
      displayName: name,
      handle: widget.conversationId ?? widget.publicCode ?? room ?? name,
      roomName: room,
    );
  }

  /// Starts the CallKit registration and takes the uuid as soon as iOS
  /// confirms, not only after LiveKit has connected: a system "End" pressed
  /// while the call is still connecting must already find this screen.
  void _beginSystemCallRegistration() {
    final registration = _registerSystemCall();
    _systemCallRegistration = registration;
    unawaited(registration.then((uuid) {
      if (uuid != null && mounted && !_hangingUp && _systemCallUuid == null) {
        _systemCallUuid = uuid;
      }
    }));
  }

  /// The callee, the AI twin or a meeting answered: iOS shows the call
  /// connected. No-op for incoming calls — the answer connected them.
  void _markSystemCallConnected() {
    final room = _roomName;
    if (_systemCallManaged && room != null) {
      unawaited(SystemCallRegistry.instance.markConnected(room));
    }
  }

  /// A conversation CallKit owns: the session is already live (CallKit
  /// activated it on the answer); only the mic and the route are ours.
  Future<void> _startManagedCallAudio() async {
    try {
      await _room?.localParticipant?.setMicrophoneEnabled(!_muted && !_heldBySystem);
    } catch (_) {}
    await _applyAudioOutput(_audioOutputType);
  }
```

- [ ] **Step 3: Входящий в `_connect()`**

Заменить строку `    if (widget.isIncoming) {`, открывающую блок с `debugPrint('[AudDbg] incoming setup START …`, на:

```dart
    if (widget.isIncoming) {
      final incomingRoom = widget.roomName;
      _systemCallUuid = incomingRoom == null
          ? null
          : SystemCallRegistry.instance.uuidForRoom(incomingRoom);
    }
    if (widget.isIncoming && _systemCallManaged) {
      // iOS: answered through CallKit, and it stays there — CallKit owns the
      // audio session, WebRTC follows it. Nothing to release or re-activate.
      debugPrint('[AudDbg] incoming: CallKit keeps the call $_systemCallUuid');
    } else if (widget.isIncoming) {
```

В конце этого же блока (после `debugPrint('[AudDbg] incoming setup DONE, entering LiveKit connect');`, перед его закрывающей `}`):

```dart
      // Not in CallKit yet (Android, or iOS answered outside it): iOS gets a
      // CallKit call now, so call waiting protects the rest of it.
      _beginSystemCallRegistration();
```

- [ ] **Step 3a: Старый путь не снимает разговоры CallKit**

В `_restoreAudioAfterCallKit()` и в блоке входящего без CallKit (ветка `else if (widget.isIncoming)` из шага 3) заменить `await CallKitPlatform.instance.endAllCalls();` на `await SystemCallRegistry.instance.dismissRinging();` (текст `debugPrint` рядом — под новое имя). На iPhone сплошной `endAllCalls()` положил бы и разговоры, которые живут в CallKit: например, первую линию, пока вторую принимают по старому пути (`answerRinging` не дождался ответа CallKit). `dismissRinging()` снимает только звонящие вызовы, а на Android и без реестра — это ровно прежний `endAllCalls()`.

- [ ] **Step 4: Исходящий и встречи**

Перед комментарием `    // Play ringback tone for outgoing calls to user (not incoming, not AI assistant).`:

```dart
    // iOS: an outgoing call or a room joined by name enters CallKit before
    // anything plays, so the ringback already sounds in the call's session.
    // Rooms by public link wait for their join dialog below.
    if (!widget.isIncoming && widget.publicCode == null) {
      _beginSystemCallRegistration();
    }
```

После строки `        final roomPassword = joinResult['password'] as String?;`:

```dart
        _beginSystemCallRegistration();
```

- [ ] **Step 5: После подключения к комнате**

Блок

```dart
      try {
        await _audioChannel.invokeMethod('enableCallAudioMix');
        debugPrint('[AudDbg] enableCallAudioMix done');
      } catch (e) {
        debugPrint('[CallAudio] enableCallAudioMix failed: $e');
      }
```
заменить на

```dart
      // Hung up while connecting (the red button, or a system End that
      // reached this screen through its uuid): nothing left to set up, and
      // _hangUpInner has already dropped _room.
      if (_hangingUp || _navigatedAway) return;
      final registration = _systemCallRegistration;
      if (registration != null) {
        final uuid = await registration;
        if (_hangingUp || _navigatedAway) return;
        _systemCallUuid = uuid;
      }
      final systemCallUuid = _systemCallUuid;
      if (systemCallUuid != null) {
        if (!SystemCallRegistry.instance.bindRoom(systemCallUuid, _roomName!)) {
          // The CallKit call was ended from the system UI before the room
          // existed — hang up, as that End asked.
          _systemCallUuid = null;
          unawaited(_hangUp(userInitiated: true));
          return;
        }
        // A room joined without ringing has nobody to wait for.
        if (!_ringing) _markSystemCallConnected();
      } else {
        try {
          await _audioChannel.invokeMethod('enableCallAudioMix');
          debugPrint('[AudDbg] enableCallAudioMix done');
        } catch (e) {
          debugPrint('[CallAudio] enableCallAudioMix failed: $e');
        }
      }
```

- [ ] **Step 6: «Собеседник ответил» — три места и ИИ-двойник**

1. `_connect()`:
   ```dart
      if (_participants.any((p) => p.identity != 'ai-assistant')) {
        _stopRingback();
      }
   ```
   →
   ```dart
      if (_participants.any((p) => p.identity != 'ai-assistant')) {
        _stopRingback();
        _markSystemCallConnected();
      }
   ```
2. `_onRoomChanged()`:
   ```dart
      if (_ringing && _participants.any((p) => p.identity != 'ai-assistant')) {
        _stopRingback();
      }
   ```
   →
   ```dart
      if (_ringing && _participants.any((p) => p.identity != 'ai-assistant')) {
        _stopRingback();
        _markSystemCallConnected();
      }
   ```
3. `ParticipantConnectedEvent`:
   ```dart
        if (event.participant.identity != 'ai-assistant') {
          _stopRingback();
        }
   ```
   →
   ```dart
        if (event.participant.identity != 'ai-assistant') {
          _stopRingback();
          _markSystemCallConnected();
        }
   ```
4. В `_aiTwinJoinedSub` после `_stopRingback();` добавить `_markSystemCallConnected();`.

- [ ] **Step 7: Возврат к уже подключённой комнате (`_initCall`)**

```dart
      // End CallKit and restore audio — must be properly sequenced
      if (widget.isIncoming) {
        await _restoreAudioAfterCallKit();
      }
```
→
```dart
      _systemCallUuid = SystemCallRegistry.instance.uuidForRoom(_roomName!);
      _heldBySystem = SystemCallRegistry.instance.isHeldBySystem(_roomName!);
      if (_systemCallManaged) {
        // iOS: answered through CallKit and it stays there.
        await _startManagedCallAudio();
      } else if (widget.isIncoming) {
        // End CallKit and restore audio — must be properly sequenced
        await _restoreAudioAfterCallKit();
      }
```

- [ ] **Step 8: Анализ**

```bash
flutter analyze lib/features/voice/presentation/screens/voice_call_screen.dart 2>&1 | grep -cE "^\s*(error|warning) "
```
Expected: `28` (база) — не больше.

- [ ] **Step 9: Коммит**

```bash
git add lib/features/voice/presentation/screens/voice_call_screen.dart
git commit -F - <<'EOF'
feat(звонок): разговор на экране звонка заводится в CallKit (iOS)

Исходящий и встреча регистрируются в CallKit до того, как что-то
зазвучит; принятый через CallKit входящий там и остаётся — без
снятия, паузы в секунду и повторных попыток включить звук. Когда
собеседник или ИИ-двойник ответил, iOS показывает звонок соединённым.
Android и звонки без CallKit идут прежним путём.

Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>
EOF
```

---

### Task 15: Экран звонка — сброс, события системы, удержание, mute

**Files:**
- Modify: `lib/features/voice/presentation/screens/voice_call_screen.dart`

- [ ] **Step 1: Подписка на события реестра**

Поле рядом с `_systemCallRegistration`:
```dart
  StreamSubscription<SystemCallEvent>? _systemCallSub;
```

В `initState` после блока `_callkitEndedSub = NotificationService.callEvents.listen(…);`:

```dart
    // iOS: what the system does to this conversation (End button, "End &
    // Accept", call waiting, the lock-screen mute) arrives uuid-filtered.
    _systemCallSub = SystemCallRegistry.instance.events.listen(_onSystemCallEvent);
```

В `dispose()` после `_callkitEndedSub?.cancel();`: `_systemCallSub?.cancel();`.

Метод (рядом с `_onNativeAudioEvent`):

```dart
  bool _isOurSystemCall(SystemCallEvent e) =>
      e.uuid == _systemCallUuid ||
      (e.roomName != null && e.roomName == (_roomName ?? widget.roomName));

  void _onSystemCallEvent(SystemCallEvent e) {
    if (!mounted || _navigatedAway || !_isOurSystemCall(e)) return;
    switch (e) {
      case SystemCallEndedBySystem():
        // The system End button or "End & Accept" — the user decided.
        _hangUp(userInitiated: true);
      case SystemCallHeld(bySystem: true):
        setState(() => _heldBySystem = true);
      case SystemCallResumed():
        if (!_heldBySystem) return;
        setState(() => _heldBySystem = false);
        unawaited(_applyAudioOutput(_audioOutputType));
      case SystemCallMuteChanged(:final muted):
        if (muted != _muted) setState(() => _muted = muted);
      case SystemCallHeld():
        break;
    }
  }
```

- [ ] **Step 2: Старый слушатель CallKit — только для звонков без CallKit**

В `_callkitEndedSub = NotificationService.callEvents.listen((CallKitEvent? event) {` первой строкой тела:

```dart
      // A CallKit-managed conversation hears the system through
      // _onSystemCallEvent, filtered by uuid; raw events here may belong to
      // any call (a declined second call used to hang this one up).
      if (_systemCallManaged) return;
```

- [ ] **Step 3: Сброс**

В `_hangUp` после `_hangingUp = true;`:

```dart
    final wasManaged = _systemCallManaged;
```

В `_hangUp` блок

```dart
    try { await _audioChannel.invokeMethod('abandonAudioFocus'); } catch (_) {}
    try { await _audioChannel.invokeMethod('deactivateAudioSession'); } catch (_) {}
    try { await CallKitPlatform.instance.endAllCalls(); } catch (_) {}
    debugPrint('[VoiceCall] audio cleanup done, navigating back...');
```
заменить на

```dart
    try { await _audioChannel.invokeMethod('abandonAudioFocus'); } catch (_) {}
    // CallKit switches the session off itself when it ends a call.
    if (!wasManaged) {
      try { await _audioChannel.invokeMethod('deactivateAudioSession'); } catch (_) {}
    }
    final registry = SystemCallRegistry.instance;
    if (registry.enabled) {
      // Only this screen's own call. Not endAllConversations(): a call just
      // taken with "End & Accept" may not be a line yet, and this hang-up must
      // not end it too. _hangUpInner normally ended ours already; if its 8 s
      // guard cut it short, end it here — a CallKit call left behind keeps
      // WebRTC in manual audio and the next calls silent.
      final own = _systemCallUuid;
      if (own != null) {
        _systemCallUuid = null;
        try { await registry.endConversationByUuid(own); } catch (_) {}
      }
      // A start iOS has not confirmed yet: ended once it is.
      final pending = _systemCallRegistration;
      if (pending != null) {
        unawaited(pending.then((uuid) {
          if (uuid != null) registry.endConversationByUuid(uuid);
        }));
      }
    } else {
      try { await CallKitPlatform.instance.endAllCalls(); } catch (_) {}
    }
    debugPrint('[VoiceCall] audio cleanup done, navigating back...');
```

В `_hangUpAll` блок

```dart
    try { await _audioChannel.invokeMethod('abandonAudioFocus'); } catch (_) {}
    try { await _audioChannel.invokeMethod('deactivateAudioSession'); } catch (_) {}
    try { await CallKitPlatform.instance.endAllCalls(); } catch (_) {}
```
заменить на

```dart
    try { await _audioChannel.invokeMethod('abandonAudioFocus'); } catch (_) {}
    final registry = SystemCallRegistry.instance;
    if (registry.enabled) {
      try { await registry.endAllConversations(); } catch (_) {}
    } else {
      try { await _audioChannel.invokeMethod('deactivateAudioSession'); } catch (_) {}
      try { await CallKitPlatform.instance.endAllCalls(); } catch (_) {}
    }
```

В `_hangUpInner` блок

```dart
    try {
      await _audioChannel.invokeMethod('disableCallAudioMix');
    } catch (e) {
      debugPrint('[CallAudio] disableCallAudioMix failed: $e');
    }
```
заменить на

```dart
    final systemCallUuid = _systemCallUuid;
    if (systemCallUuid != null) {
      // iOS: this conversation's CallKit call ends here; CallKit turns the
      // session off. The mix/deactivate dance is for calls without CallKit.
      _systemCallUuid = null;
      _heldBySystem = false;
      try {
        await SystemCallRegistry.instance.endConversationByUuid(systemCallUuid);
      } catch (_) {}
    } else {
      try {
        await _audioChannel.invokeMethod('disableCallAudioMix');
      } catch (e) {
        debugPrint('[CallAudio] disableCallAudioMix failed: $e');
      }
    }
```

- [ ] **Step 4: Переключение линий**

В `_switchToLine` после строки `_onHold = false;`:

```dart
    _systemCallUuid = SystemCallRegistry.instance.uuidForRoom(line.roomName);
    _heldBySystem = SystemCallRegistry.instance.isHeldBySystem(line.roomName);
```

- [ ] **Step 5: На удержании ничего не «чинить» и не включать микрофон**

1. `_maybeAutoRecoverAudio()`: первой строкой `if (_heldBySystem) return;`
2. `_restoreAudioAfterInterruption()`: первой строкой (до `debugPrint`) `if (_heldBySystem) return;`
3. `RoomReconnectedEvent`: `setMicrophoneEnabled(!_muted)` → `setMicrophoneEnabled(!_muted && !_heldBySystem)`.
4. `_startManualReconnect`: `await newRoom.localParticipant?.setMicrophoneEnabled(!_muted);` → `…(!_muted && !_heldBySystem);`.
5. `_retryMicEnable`: `if (!_muted) {` → `if (!_muted && !_heldBySystem) {`.

- [ ] **Step 6: Mute зеркалится в CallKit**

`_toggleMute()` заменить:

```dart
  Future<void> _toggleMute() async {
    final newMuted = !_muted;
    await _room?.localParticipant?.setMicrophoneEnabled(!newMuted);
    setState(() => _muted = newMuted);
    final room = _roomName;
    if (_systemCallManaged && room != null) {
      unawaited(SystemCallRegistry.instance.setMuted(room, newMuted));
    }
  }
```

- [ ] **Step 7: Анализ и тесты**

```bash
flutter analyze lib/features/voice/presentation/screens/voice_call_screen.dart 2>&1 | grep -cE "^\s*(error|warning) "
flutter test test/features/voice/ test/voice/ test/core/
```
Expected: `28` — не больше; тесты PASS.

- [ ] **Step 8: Коммит**

```bash
git add lib/features/voice/presentation/screens/voice_call_screen.dart
git commit -F - <<'EOF'
feat(звонок): экран слушает систему — сброс, удержание, mute

«Завершить» в системном интерфейсе и «Завершить и ответить» кладут
трубку как красная кнопка. Отклонённый второй вызов разговор больше не
завершает: события приходят отфильтрованными по UUID. На удержании
ничего не «чинится» и микрофон не включается обратно. Сброс снимает из
CallKit только свои разговоры — второй звонящий вызов продолжает
звонить.

Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>
EOF
```

---

### Task 16: Плашка «На удержании» и строки на 24 языках

**Files:**
- Modify: `lib/l10n/app_*.arb` (24 файла), сгенерированные `lib/l10n/app_localizations*.dart`
- Modify: `lib/features/voice/presentation/screens/voice_call_screen.dart`

- [ ] **Step 1: Строки**

Скрипт вставляет две строки после `"voiceReconnecting"` в каждый ARB:

```bash
python3 - <<'EOF'
import json, pathlib, re
T = {
  "ru": ("Разговор на удержании — идёт другой звонок", "Вернуться к разговору"),
  "en": ("Call on hold — another call is in progress", "Resume call"),
  "ar": ("المكالمة قيد الانتظار — هناك مكالمة أخرى جارية", "استئناف المكالمة"),
  "bn": ("কল হোল্ডে আছে — অন্য একটি কল চলছে", "কলে ফিরে যান"),
  "de": ("Anruf gehalten – ein anderer Anruf läuft", "Zum Gespräch zurückkehren"),
  "es": ("Llamada en espera: hay otra llamada en curso", "Volver a la llamada"),
  "fa": ("تماس در انتظار است — تماس دیگری در جریان است", "بازگشت به تماس"),
  "fr": ("Appel en attente — un autre appel est en cours", "Reprendre l'appel"),
  "ha": ("An dakatar da kiran — wani kira yana gudana", "Koma kan kiran"),
  "hi": ("कॉल होल्ड पर है — दूसरी कॉल चल रही है", "कॉल पर वापस जाएँ"),
  "id": ("Panggilan ditahan — ada panggilan lain yang berlangsung", "Kembali ke panggilan"),
  "it": ("Chiamata in attesa: è in corso un'altra chiamata", "Riprendi la chiamata"),
  "ja": ("通話を保留中 — 別の通話中です", "通話に戻る"),
  "ko": ("통화 대기 중 — 다른 통화가 진행 중입니다", "통화로 돌아가기"),
  "mr": ("कॉल होल्डवर आहे — दुसरा कॉल सुरू आहे", "कॉलवर परत जा"),
  "pa": ("ਕਾਲ ਹੋਲਡ 'ਤੇ ਹੈ — ਇੱਕ ਹੋਰ ਕਾਲ ਚੱਲ ਰਹੀ ਹੈ", "ਕਾਲ 'ਤੇ ਵਾਪਸ ਜਾਓ"),
  "pt": ("Chamada em espera — outra chamada em andamento", "Voltar à chamada"),
  "sk": ("Hovor je podržaný — prebieha iný hovor", "Vrátiť sa k hovoru"),
  "ta": ("அழைப்பு நிறுத்தி வைக்கப்பட்டுள்ளது — மற்றொரு அழைப்பு நடக்கிறது", "அழைப்புக்குத் திரும்பு"),
  "te": ("కాల్ హోల్డ్‌లో ఉంది — మరో కాల్ జరుగుతోంది", "కాల్‌కు తిరిగి వెళ్లండి"),
  "tr": ("Arama beklemede — başka bir arama sürüyor", "Aramaya dön"),
  "ur": ("کال ہولڈ پر ہے — ایک اور کال جاری ہے", "کال پر واپس جائیں"),
  "vi": ("Cuộc gọi đang chờ — đang có cuộc gọi khác", "Quay lại cuộc gọi"),
  "zh": ("通话已保持 — 正在进行另一通电话", "返回通话"),
}
arbs = sorted(pathlib.Path("lib/l10n").glob("app_*.arb"))
assert {p.stem[4:] for p in arbs} == set(T), sorted(p.stem for p in arbs)
for p in arbs:
    held, resume = T[p.stem[4:]]
    s = p.read_text(encoding="utf-8")
    m = re.search(r'^  "voiceReconnecting": .*,$', s, re.M)
    ins = (f'\n  "callHeldBySystem": {json.dumps(held, ensure_ascii=False)},'
           f'\n  "callResumeFromHold": {json.dumps(resume, ensure_ascii=False)},')
    p.write_text(s[:m.end()] + ins + s[m.end():], encoding="utf-8")
    json.loads(p.read_text(encoding="utf-8"))
print("ok", len(arbs))
EOF
flutter gen-l10n
grep -n "callHeldBySystem" lib/l10n/app_localizations.dart
```
Expected: `ok 24`; геттер `callHeldBySystem` в `app_localizations.dart`. Если `assert` упал — список локалей в репозитории отличается: дополнить словарь `T` недостающими, лишние не удалять.

- [ ] **Step 2: Плашка**

В `build` в `Stack` после блока `if (_reconnecting) Container(…),`:

```dart
          if (_heldBySystem) _buildSystemHoldOverlay(),
```

Метод (рядом с `_buildBody`):

```dart
  /// iOS put the call on hold for another one ("Hold & Accept" on a WhatsApp
  /// or cellular call). It comes back by itself when that call ends; the
  /// button takes it back sooner.
  Widget _buildSystemHoldOverlay() {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      color: Colors.black87,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.pause_circle_outline_rounded, color: Colors.white, size: 56),
              const SizedBox(height: 16),
              Text(
                l10n.callHeldBySystem,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () {
                  final room = _roomName;
                  if (room != null) SystemCallRegistry.instance.resume(room);
                },
                child: Text(l10n.callResumeFromHold),
              ),
            ],
          ),
        ),
      ),
    );
  }
```

- [ ] **Step 3: Анализ**

```bash
flutter analyze lib/features/voice/presentation/screens/voice_call_screen.dart 2>&1 | grep -cE "^\s*(error|warning) "
flutter analyze lib/l10n 2>&1 | grep -cE "^\s*(error|warning) "
```
Expected: `28` — не больше; `0`.

- [ ] **Step 4: Коммит**

```bash
git add lib/l10n lib/features/voice/presentation/screens/voice_call_screen.dart
git commit -F - <<'EOF'
feat(звонок): плашка «Разговор на удержании»

Пока идёт звонок WhatsApp, принятый кнопкой «Удержать и ответить»,
экран не притворяется разговором: плашка говорит, что происходит, и
даёт вернуться раньше, чем тот звонок закончится.

Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>
EOF
```

---

### Task 17: Дашборд — диалог приёма, `endAllCalls()`, режим плашки

**Files:**
- Modify: `lib/features/dashboard/presentation/dashboard_screen.dart`

- [ ] **Step 1: Импорт и подписка**

Импорт:
```dart
import '../../../core/platform/system_call_registry.dart';
```

Поле рядом с `_callkitSub`:
```dart
  StreamSubscription<SystemCallEvent>? _systemCallSub;
```

В `initState` после блока `_callkitSub = NotificationService.callEvents.listen(…);`:

```dart
    // iOS: a CallKit conversation ended from the system UI while the call
    // runs behind the banner.
    _systemCallSub = SystemCallRegistry.instance.events
        .where((e) => e is SystemCallEndedBySystem)
        .listen((e) => _onSystemCallEnded(e.roomName));
```

В `dispose()` после `_callkitSub?.cancel();`: `_systemCallSub?.cancel();`.

Метод (рядом с `_endCallKitCallForRoom`):

```dart
  /// The active line was ended from the system call UI (End, "End & Accept")
  /// while the call screen is closed. On the call screen it hangs up itself;
  /// held background lines are handled in main.dart.
  Future<void> _onSystemCallEnded(String? roomName) async {
    try {
      final loc = GoRouter.of(context).routerDelegate.currentConfiguration.uri.path;
      if (loc.startsWith('/dashboard/voice')) return;
    } catch (_) {}
    final cs = CallStateService.instance;
    final rn = roomName ?? cs.roomName;
    if (rn == null || rn != cs.roomName) return;
    final cId = cs.conversationId;
    if (cId != null) {
      try { sl<MessengerRemoteDataSource>().sendCallEnded(cId, rn); } catch (_) {}
      try {
        await sl<DioClient>().post(
          '/messenger/call-ended',
          data: {'conversationId': cId, 'roomName': rn},
          fromJson: (d) => d,
        );
      } catch (_) {}
    }
    await cs.endLine(rn);
  }
```

- [ ] **Step 2: Обработчики событий CallKit**

1. В ветке `typeDecline || typeTimeout` заменить `CallKitPlatform.instance.endAllCalls();` на `SystemCallRegistry.instance.dismissRinging();`.
2. В ветке `else if (event.type == CallKitEvent.typeEnded) {` первой строкой:
   ```dart
        // iOS: our conversations' ends come uuid-filtered from the registry
        // (_onSystemCallEnded); a raw ENDED may belong to any CallKit call.
        if (SystemCallRegistry.instance.enabled) return;
   ```

- [ ] **Step 3: Конец группового звонка и фолбэки `_endCallKitCallForRoom`**

1. В `_listenForGroupCallEnded` `await CallKitPlatform.instance.endAllCalls();` → `await SystemCallRegistry.instance.dismissRinging();`.
2. В `_endCallKitCallForRoom` первой строкой `try`-блока:
   ```dart
      final registry = SystemCallRegistry.instance;
      if (registry.isConversation(roomName)) {
        await registry.endConversation(roomName);
        return;
      }
   ```
   и оба `CallKitPlatform.instance.endAllCalls()` в этой функции → `SystemCallRegistry.instance.dismissRinging()` (в `catch` — без `await`, как было).

- [ ] **Step 4: Диалог входящего**

1. «Отклонить»: `CallKitPlatform.instance.endAllCalls();` → `SystemCallRegistry.instance.endRingingForRoom(roomName);`.
2. «Ответить»: внутри `if (CallStateService.instance.isAnsweredElsewhere(roomName)) {` заменить `try { await CallKitPlatform.instance.endAllCalls(); } catch (_) {}` на `try { await SystemCallRegistry.instance.endRingingForRoom(roomName); } catch (_) {}`. Сразу после закрывающей `}` этого `if` вставить:
   ```dart
                      // iOS: answer the ringing CallKit call — from here the
                      // call goes exactly as an answer on the CallKit UI does
                      // (main.dart's accept handler announces, connects and
                      // navigates), and it stays in CallKit.
                      if (await SystemCallRegistry.instance.answerRinging(roomName)) return;
   ```
   Ниже, в старом пути, `await CallKitPlatform.instance.endAllCalls();` и `CallKitPlatform.instance.endAllCalls();` в цикле `for (final delay in [500, 1500, 3000])` → `SystemCallRegistry.instance.dismissRinging()` (с `await` там, где он был).

- [ ] **Step 5: «Потерянный» принятый вызов**

В `_checkActiveCallKitCalls` перед `// Connect to LiveKit immediately if not already connected (1-on-1)`:

```dart
        if (call['isAccepted'] == true || call['accepted'] == true) {
          await SystemCallRegistry.instance.adoptAnswered(
              uuid: (call['id'] ?? '').toString(), roomName: roomName);
        }
```

- [ ] **Step 5a: Убрать временный re-export `toCallkitId`**

В задаче 3 `toCallkitId` переехал в `lib/core/platform/callkit_support.dart`, а `notification_service.dart` временно его ре-экспортирует. Импортёров двое, убрать шов надо одним коммитом (с живым export прямой импорт даёт `unnecessary_import`):
- `lib/features/dashboard/presentation/dashboard_screen.dart`: добавить `import '../../../core/platform/callkit_support.dart';`
- `lib/main.dart`: добавить `import 'core/platform/callkit_support.dart';`
- `lib/core/notifications/notification_service.dart`: удалить строку `export '../platform/callkit_support.dart' show toCallkitId;` и комментарий над ней.

Проверка: `grep -rn "show toCallkitId" lib/` — пусто; анализ `main.dart` — 0, дашборд — 2 (база).

- [ ] **Step 6: Проверка, что `endAllCalls()` в дашборде не осталось**

```bash
grep -n "endAllCalls" lib/features/dashboard/presentation/dashboard_screen.dart | grep -v "^\s*[0-9]*:\s*//"
flutter analyze lib/features/dashboard/presentation/dashboard_screen.dart 2>&1 | grep -cE "^\s*(error|warning) "
```
Expected: только строки комментариев; `2` — не больше.

- [ ] **Step 7: Коммит**

```bash
git add lib/features/dashboard/presentation/dashboard_screen.dart lib/main.dart lib/core/notifications/notification_service.dart
git commit -F - <<'EOF'
fix(звонок): дашборд не кладёт разговор, убирая звонящие вызовы

Сплошной endAllCalls() в шести местах заменён снятием только
звонящих вызовов. «Ответить» в диалоге отвечает через CallKit и дальше
идёт тем же путём, что ответ в окне CallKit, вместо четырёх
endAllCalls() подряд. Завершение из системного интерфейса при закрытом
экране звонка кладёт трубку и у собеседника.

Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>
EOF
```

---

### Task 18: `call_cancelled` снимает только вызов своей комнаты

**Files:**
- Modify: `lib/core/notifications/notification_service.dart` (фоновый обработчик и обработчик в приложении)

- [ ] **Step 1: Импорт**

```dart
import '../platform/system_call_registry.dart';
```

- [ ] **Step 2: Фоновый обработчик**

В `firebaseMessagingBackgroundHandler` в ветке `type == 'call_cancelled'` заменить

```dart
    var hasAccepted = false;
    try {
      final active = await CallKitPlatform.instance.activeCalls();
      hasAccepted = active.any((c) =>
          c is Map && (c['isAccepted'] == true || c['accepted'] == true));
    } catch (_) {}
    if (!hasAccepted) {
      await CallKitPlatform.instance.endAllCalls();
    }
```
на

```dart
    var hasAccepted = false;
    final roomName = message.data['roomName'] as String? ?? '';
    final registry = SystemCallRegistry.instance;
    if (registry.enabled && roomName.isNotEmpty) {
      // iOS: end only this room's ringing call. Any other call — a
      // conversation in progress, possibly the one this device just answered —
      // is left alone.
      hasAccepted = await registry.endRingingForRoom(roomName);
    } else {
      try {
        final active = await CallKitPlatform.instance.activeCalls();
        hasAccepted = active.any((c) =>
            c is Map && (c['isAccepted'] == true || c['accepted'] == true));
      } catch (_) {}
      if (!hasAccepted) {
        await CallKitPlatform.instance.endAllCalls();
      }
    }
```

- [ ] **Step 3: Обработчик в приложении**

Там же, где `// call_invite is intentionally ignored here — socket handles it.` → `if (type == 'call_cancelled') {`, заменить такой же блок (с отступом внутри `if`) на тот же текст, что в шаге 2.

- [ ] **Step 4: Анализ и тесты**

```bash
flutter analyze lib/core/notifications/notification_service.dart 2>&1 | grep -cE "^\s*(error|warning) "
flutter test test/notifications/ test/core/
```
Expected: `0`; PASS.

- [ ] **Step 5: Коммит**

```bash
git add lib/core/notifications/notification_service.dart
git commit -F - <<'EOF'
fix(звонок): отмена звонка снимает только его вызов

Раньше отмена гасила все вызовы, если среди них не было принятого.
Пока идёт разговор, принятый есть всегда, и отменённый второй вызов
продолжал бы звонить до таймаута. Теперь снимается вызов комнаты из
пуша, а разговор не трогается.

Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>
EOF
```

---

### Task 19: Регресс и сборки

- [ ] **Step 1: Полный прогон тестов**

```bash
flutter test --reporter compact 2>&1 | tr '\r' '\n' | tail -3
```
Expected: `All tests passed!` или единственный провал `mesh_messaging_service_test.dart` («stale-session recovery») — перепроверить его в одиночку: `flutter test test/core/mesh/services/mesh_messaging_service_test.dart --plain-name "stale-session recovery"` → PASS.

- [ ] **Step 2: Новые замечания анализатора в тронутых файлах**

```bash
for f in $(git diff --name-only origin/dev -- '*.dart' | grep -v "^packages/"); do
  printf "%s: " "$f"; flutter analyze "$f" 2>&1 | grep -cE "^\s*(error|warning) "
done
```
Expected: `voice_call_screen.dart: 28`, `dashboard_screen.dart: 2`, остальные `0` — ни одно число не выше базы.

- [ ] **Step 3: Сборки всех iOS-флейворов и Android**

```bash
for f in dev talerid; do
  flutter build ios --debug --no-codesign --flavor $f $( [ $f = dev ] && echo "-t lib/main_dev.dart --dart-define=FLAVOR=dev --dart-define=BASE_URL=https://staging.id.taler.tirol" ) 2>&1 | tail -1
done
flutter build ios --debug --no-codesign 2>&1 | tail -1   # prod (схема Runner)
flutter build apk --debug --flavor dev -t lib/main_dev.dart --dart-define=FLAVOR=dev --dart-define=BASE_URL=https://staging.id.taler.tirol 2>&1 | tail -1
```
Expected: три `✓ Built …Runner.app` и `✓ Built build/app/outputs/flutter-apk/app-dev-debug.apk`.

- [ ] **Step 4: Интеграционный тест Android по CLAUDE.md (Android не должен был измениться)**

```bash
~/Library/Android/sdk/platform-tools/adb devices
flutter test integration_test/app_test.dart --flavor dev --dart-define=FLAVOR=dev \
  --dart-define=BASE_URL=https://staging.id.taler.tirol -d emulator-5554
```
Expected: PASS.

---

### Task 20: Матрица на устройствах (с пользователем)

- [ ] **Step 1: Сборка на iPhone**

```bash
flutter devices
flutter run --profile --flavor dev -t lib/main_dev.dart \
  --dart-define=FLAVOR=dev --dart-define=BASE_URL=https://staging.id.taler.tirol \
  -d <iphone-id> 2>&1 | tee /tmp/callkit-matrix.log
```
Логи моста — Console.app, фильтр `CallKitAudio`; Dart — `[SystemCall]`, `[CallKit] event:`, `[AudDbg]` в выводе `flutter run`.

- [ ] **Step 2: Прогнать и отметить каждый пункт**

| # | Сценарий | Ожидание |
|---|---|---|
| 1 | Разговор → WhatsApp звонит → «Отклонить» | звук не прерывается ни на миг в обе стороны |
| 2 | «Удержать и ответить» → разговор в WhatsApp → WhatsApp завершён | плашка «На удержании» во время WhatsApp; после — разговор вернулся сам, звук в обе стороны, mute как был; у собеседника на время удержания значок выключенного микрофона |
| 3 | «Завершить и ответить» | наш разговор завершён у обеих сторон |
| 4 | Пункты 1–3 с сотовым звонком | как 1–3 |
| 5 | Входящий, приложение убито, экран заблокирован | звук в обе стороны |
| 6 | Входящий при открытом приложении: принят в диалоге; принят в баннере CallKit | звук в обе стороны; экран звонка один (не два) |
| 7 | Исходящий; ИИ-двойник (у `integration_test_2` включён) | гудки слышны с первого; звук; в системном интерфейсе звонок «соединён» после ответа |
| 8 | Встреча по ссылке `/room/…` | звук; WhatsApp при отклонении не прерывает |
| 9 | Mute и «Завершить» на заблокированном экране | mute отражается на нашем экране; «Завершить» кладёт трубку у обеих сторон |
| 10 | Динамик / наушник / Bluetooth — в разговоре и после возврата с удержания | маршрут переключается и сохраняется после возврата |
| 11 | Вторая линия: второй вызов Taler ID → «Удержать и ответить» → переключение → завершить одну | первая возвращается, звук есть; отклонение второго вызова первую не трогает |
| 12 | После исходящего: новый входящий → «Отклонить» | звонящий видит отказ сразу (P3); без ответа вызов снимается сам через 60 с (P4) |
| 13 | После звонка открыть ассистента | ассистента слышно, он слышит нас |
| 14 | Групповой звонок принят через CallKit | звук как раньше (регресс) |
| 15 | «Удержать и ответить» на WhatsApp, и пока он идёт — собеседник в Taler ID выключает и включает интернет | WhatsApp не теряет звук; после WhatsApp наш разговор возвращается (риск 3 проекта) |

- [ ] **Step 3: Найденное — чинить по одной причине за раз**

Каждый провал: лог, гипотеза, минимальная правка, повтор пункта и всех, что уже прошли. Правки — отдельными коммитами. Если за три захода один пункт не сдаётся — остановиться и обсудить с пользователем (правило систематической отладки).

---

### Task 21: Передача

- [ ] **Step 1: Итог пользователю**

Кратко: что сделано, что прошла матрица (таблица 1–14 с отметками), что не проверено. Спросить, сливать ли `fix/ios-callkit-calls` в `dev`, и дальше — обычный релизный порядок из CLAUDE.md (версия, `APP_RELEASES`, TestFlight DEV → TEST → PROD). Ничего из этого без явного согласия.

- [ ] **Step 2: Память**

Записать в `~/.claude/projects/-Users-dmitry-talerid/memory/` заметку `project_ios_calls_callkit.md` (тип project): разговор на iOS живёт в CallKit до конца; плагин вендорный с правками P1–P7 (`packages/flutter_callkit_incoming/PATCHES.md`); Android не менялся и ждёт лога аудиофокуса во время звонка WhatsApp; итог пунктов 2 и 5 матрицы. Добавить строку в `MEMORY.md`.

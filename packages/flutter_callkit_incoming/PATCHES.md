# flutter_callkit_incoming 2.5.8 — копия Taler ID

Взята в репозиторий 2026-09-24: на iOS разговор теперь живёт в CallKit до конца
(см. docs/superpowers/specs/2026-09-24-ios-calls-through-callkit-design.md), а
плагин рассчитан на один звонок за раз. Правки только в `ios/Classes`,
помечены в коде `PATCH Pn (Taler ID)`. Android-часть не тронута.

Основа: pub.dev `flutter_callkit_incoming` 2.5.8, sha256 архива
`993fb0f0cd990961072f0d13ff815a91773f92bfa1895be17d3366b2225ec9cd`.
Не скопированы: `example/`, `images/`, `test/`, `*.iml`, `android/.gradle/`.
Сверка с оригиналом (после правок должна показывать только P1–P13). После
перехода на path-зависимость `flutter pub get` больше не кладёт оригинал в
pub cache — его нужно положить туда вручную:

    dart pub cache add flutter_callkit_incoming --version 2.5.8
    diff -r -x example -x images -x test -x '*.iml' -x .gradle -x PATCHES.md \
      ~/.pub-cache/hosted/pub.dev/flutter_callkit_incoming-2.5.8 packages/flutter_callkit_incoming

При обновлении плагина: взять новую версию, перенести правки по этому списку,
прогнать матрицу из задачи 20 плана 2026-09-24-ios-calls-through-callkit.

## Правки

- **P1** `SwiftFlutterCallkitIncomingPlugin.swift` — `endCall` и `callConnected`
  действуют на переданный `id` и не перезаписывают `self.data`; заодно ушло
  лишнее ENDED-событие, которое апстрим слал сразу для PushKit-вызовов,
  невалидный uuid стал no-op вместо краша на force-unwrap, а `isFromPushKit`
  теперь только пишется и нигде не читается. Было: после входящего по
  VoIP-пушу снимался запомненный вызов вместо запрошенного.
- **P2** там же, `CXEndCallAction` — `answerCall`/`outgoingCall` обнуляются,
  только если завершился именно этот вызов. Было: `outgoingCall` не обнулялся
  никогда, `answerCall` — при завершении любого вызова.
- **P3** там же — DECLINE или ENDED по самому вызову (входящий и не отвеченный
  → DECLINE). Было: по глобальным полям.
- **P4** там же, `endCallNotExist` — таймаут звонящего вызова смотрит на этот
  вызов. Было: не срабатывал, если хоть один вызов был отвечен или исходящий.
- **P5** `CallManager.swift`, `connectedCall` — исходящий помечается
  подключённым и репортится в CallKit, но ответом не считается; звонящий
  входящий только просит CallKit ответить — «отвечен» ставит настоящий ответ
  CallKit (`CXAnswerCallAction`), не эта функция; если вызов уже отвечен
  (`data.isAccepted`), повторный запрос на ответ не уходит. Было:
  `connectedCall` сразу помечал входящий отвеченным, и отклонённый ответ
  выглядел принятым: не срабатывал таймаут звонка, отбой потом уходил как
  ENDED, `activeCalls()` показывал `accepted`.
- **P6** `SwiftFlutterCallkitIncomingPlugin.swift` — события ACCEPT, START,
  DECLINE, ENDED несут `call.data`, флаг `isAccepted` ставится на `call.data`;
  когда `CXEndCallAction` не находит вызов, TIMEOUT/ENDED тоже не берут
  `self.data` (чужой вызов) — только `{id: action.callUUID}`.
- **P7** там же, `holdCall` — при неизменном состоянии шлётся событие
  удержания, а не mute.
- **P8** там же — исходящий в `CXStartCallAction` берёт данные из
  `startingCalls[uuid]`, запомненные в `startCall`, а не `self.data`. Было:
  входящий, пришедший между `startCall` и стартом в CallKit, перезаписывал
  `self.data`, и исходящий вызов получал чужие id/данные.
- **P9** там же, `providerDidReset` — на сброс CallKit каждый вызов шлёт
  ENDED и забывается (`callManager`, `answerCall`, `outgoingCall`,
  `startingCalls`). Было: приложение не узнавало, что CallKit потерял все
  вызовы.
- **P10** там же, `CXSetHeldCallAction` — удержание больше не трогает
  `isMuted`. Было: постановка на удержание перезаписывала мьют, и снятие
  мьюта после снятия с удержания выглядело для `muteCall` эхом и не уходило
  в CallKit.
- **P11** там же, `CXAnswerCallAction` — на собственный исходящий вызов
  отвечает `action.fail()` до побочных эффектов. Было: `answerCall`,
  `isAccepted` и событие ACCEPT (открывает экран звонка) выставлялись раньше,
  чем приложение могло отказать.
- **P12** там же, `callEndTimeout` — таймаут снимает вызов из `callManager`
  (`call.endCall()` + `removeCall`). Было: снятый по таймауту вызов оставался
  в менеджере, и сброс CallKit (P9) снова сообщал о нём.
- **P13** `CallkitIncomingAppDelegate.swift` + `SwiftFlutterCallkitIncomingPlugin.swift`:
  (a) протокол — `providerDidReset` необязательным (`@objc optional`)
  требованием; `providerDidReset(_:)` (P9) зовёт его после своей штатной
  очистки. `CallKitAudioBridge` на это сбрасывает `answeredHere`/`endedHere`
  и, если WebRTC считал сессию активной, досообщает ей о деактивации — P9
  говорит каждому звонку ENDED, но не тому, что делось само CallKit-состояние.
  (b) оба `showCallkitIncoming` — тело `completion` у `reportNewIncomingCall`
  переехало на `DispatchQueue.main.async`. `CXProvider.h`: `setDelegate` с
  `queue: nil` — это «delegate callbacks on the main queue», но у
  `reportNewIncomingCallWithUUID:update:completion:` для `completion`
  отдельная фраза — «on delegate queue, if specified, otherwise on a private
  serial queue» — и наш `nil` «указанной очередью» не считается: тело
  фактически исполнялось в фоновом serial, откуда `callManager.addCall`/
  `sendEvent` (Flutter method channel) трогать нельзя. Было: делегатские
  колбэки на main, а этот `completion` — незаметно в фоне.

## Оставлено как есть (одиночные поля, осознанно)

- `didActivate`/`didDeactivate` по-прежнему смотрят на `answerCall`/
  `outgoingCall` — одиночные поля решают, кому уйдёт TOGGLE_AUDIO_SESSION-
  событие, `configureAudioSession()` (приложение его выключает) и кому
  `didActivate` вызовет `startCall(withAudioSession:)` →
  `reportOutgoingCall(startedConnectingAt:)` — только последнему исходящему,
  запомненному в `outgoingCall`.
- `timedOutPerforming` ищет вызов по `action.uuid` (id самого action, не
  вызова) — мёртвый код.
- `configureAudioSession()` читает `self.data` — no-op, потому что приложение
  передаёт `configureAudioSession: false`.
- `getAcceptedCall()` приложением не используется.
- отклонённый CallKit `startCall` оставляет запись в `startingCalls` до
  следующего `providerDidReset` (P9) — утечка только в памяти, uuid не
  переиспользуются.
- `provider(_:didActivate:)` зовёт `appDelegate.didActivateAudioSession`
  (сейчас строка 765) ДО своих же
  `sendDefaultAudioInterruptionNotificationToStartAudioResource()` (строки
  769/773/787) — `CallKitAudioBridge` полагается именно на этот порядок
  (включает WebRTC до фейкового «прерывание закончилось»). При правках
  плагина порядок сохранять.

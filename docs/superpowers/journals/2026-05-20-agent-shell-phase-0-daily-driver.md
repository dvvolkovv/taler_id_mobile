# Agent Shell Phase 0 — daily-driver journal

**Started:** 2026-05-20
**Device:** Pixel (`78c0742f`)
**Build:** `feature/agent-shell-phase-0` @ `004915a` — release APK, dev flavor, `AGENT_SHELL_AS_HOME=true`, staging backend
**Architecture:** OpenAI Realtime → `agent_task` tool → POST `/agent/run` (NestJS DEV) → SSH `dv@5.101.115.184` → `claude --print`

## Exit criteria for Phase 0

- At least 7 days of continuous use as the Home launcher without rolling back
- `agent_task` invoked at least 20 times across days, with <30% failure rate
- Latency p50 ≤ 12s, p95 ≤ 25s for round-trip (voice → claude → voice)
- No daily crashes
- Clear pain points documented → Phase 1 plan

## How to log an entry

One section per day. Inside: `## YYYY-MM-DD — short headline`, then bullets. Keep it terse — this is a working log, not a writeup. Three buckets:

- **Wins** — what worked, what felt good
- **Friction** — what was slow, awkward, or broken
- **Wishlist** — tools that didn't exist but should have

End each day with one-line **Verdict:** keep / rollback / iterate.

---

## 2026-05-20 — Day 0, install & set as home

- Wins:
- Friction:
- Wishlist:
- Verdict:

---

# Phase 1A — NotificationListener smoke test

**Branch:** `feature/agent-shell-phase-1a-notifications` (6 commits: `6ae461d` plan, `5316c2d` Task 2, `892ed82` Task 3, `7fe2f59` Task 4, `ff3cb86` Task 5, `b12c053` Task 6)
**Tools added:** `messenger_read_recent(app?, sender?, since_minutes?, limit?)`, `messenger_reply(notification_key, text)` — оба on-device, через NotificationListenerService.

## Pre-smoke checklist

- [ ] APK установлен с новой сборкой Phase 1A
- [ ] Открыть приложение → должен быть **баннер** "Включи доступ к уведомлениям"
- [ ] Нажать "Открыть настройки" → системные настройки Android открылись на `Notification access`
- [ ] Включить тоггл "Taler ID Dev" → вернуться в приложение → баннер должен исчезнуть

## Test cases

### TC1: WhatsApp read
- Попроси кого-то написать тебе в WhatsApp
- Открой Assistant, скажи: *"Что мне написали в WhatsApp?"*
- Ожидание: модель вызывает `messenger_read_recent({app:'whatsapp'})`, озвучивает текст + отправителя

### TC2: WhatsApp reply
- После TC1 скажи: *"Ответь: я занят, перезвоню вечером"*
- Ожидание: `messenger_reply` срабатывает, сообщение приходит на тот телефон в течение ~2 секунд
- Echo check: модель НЕ говорит "тебе пришло сообщение «я занят...»" через 5 секунд (это значит echo suppression сработал)

### TC3: Telegram read+reply
- Те же шаги, но через Telegram. Часто `MessagingStyle` ломает парсинг тела — записать что увидел

### TC4: SMS read+reply
- Со второго телефона отправить SMS
- Прочитать + ответить через ассистента

### TC5: Gmail read
- Получить email на Gmail
- *"Что пришло на почту?"* — `messenger_read_recent({app:'gmail'})`
- Note: ответ через Gmail RemoteInput часто открывает compose UI вместо inline reply (Risk 2 в плане)

### TC6: Permission revoked mid-session
- В системных настройках выключить Notification access для Taler ID Dev
- Спросить "что мне написали" → должен вернуться `error: notification_access_not_granted`
- Модель должна сказать "нужно включить доступ", НЕ повторять запрос

## Findings log

**2026-05-20 ~22:00 — first end-to-end success on Xiaomi 2211133G (Android 13, MIUI):**
- TC3 Telegram: ✅ голосовой ассистент через `messenger_read_recent` прочитал входящее сообщение из Telegram и через `messenger_reply` отправил ответ. Цикл полностью работает: голос → OpenAI Realtime → локальный `_handleFunctionCall` → NotificationStore → NotificationBridge → TalerNotificationListenerService → RemoteInput.
- Устройство **не Pixel** — Xiaomi с MIUI. Notification access грантуется через немного другой UI чем сток Android, но работает.
- Echo suppression сработал нормально на этом тесте (не было повторного "ты только что написал...").

**Note про навигацию:** добавил иконку микрофона в AppBar `_AgentShellScaffold` (commit ниже) — без неё с экрана Agent Shell (text chat) к голосовому Assistant не было пути, когда `AGENT_SHELL_AS_HOME=true`.

**Что ещё нужно потестировать:** TC1+TC2 WhatsApp (главный месенджер), TC4 SMS, TC6 permission revocation, групповые чаты, медиа-сообщения.

**2026-05-20 ~23:00 — Gmail работает после серии фиксов:**

Цепка проблем выявленных вечером (всё закрыто 4 коммитами на main: `5beeeaa`, `1b699c6`, `673cf3e`, `318bd98`):

1. **Bug:** filter `app:'gmail'` искал substring 'gmail' в package name, но Gmail's package — `com.google.android.gm` (без 'gmail'). Модель говорила "нет доступа к Gmail" хотя нотификации лежали в системе. **Fix:** APP_ALIASES map в `NotificationStoreNative.kt`: gmail/whatsapp/telegram/sms/messages/instagram/viber/signal/slack/discord/wechat → точные package names. Если фильтр — известный alias, точный match; иначе substring fallback.

2. **Bug:** После старта приложения буфер пустой до первой новой нотификации. Старые в статус-баре игнорировались. **Fix:** `onListenerConnected` теперь вызывает `activeNotifications` и прогоняет каждую через extract+addPosted. На свежем install буфер сразу заполняется (10 нотификаций replayed на твоём устройстве).

3. **Bug:** На MIUI 14 после reinstall система НЕ биндила listener даже когда Notification access ВКЛ. **Fix #1 (Android-side):** `requestRebind` в `NotificationBridge.init {...}`. **Fix #2 (MIUI specifically):** юзер должен включить **Autostart** в MIUI Security → Permissions → Autostart. Без этого AutoStartManagerService отвергает bind: `MIUILOG- Reject service ... AutStart Unable to bind`. На сток-Android этот шаг НЕ нужен.

4. **UX-fix:** Когда `AGENT_SHELL_AS_HOME=true`, app открывался на text Agent Shell (Phase 0 spike). Юзер хотел сразу в голос. **Fix:** Router initial route теперь `/dashboard/assistant`. Text chat доступен только по прямому URL.

5. **End-to-end:** Gmail-агрегация работает. Yandex-через-Gmail нотификации захватываются и читаются голосом. Phase 1C (Gmail OAuth) больше не критичен — Phase 1A покрывает базу.


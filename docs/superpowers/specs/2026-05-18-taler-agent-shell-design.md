# Taler ID Agent Shell — Design

- **Дата:** 2026-05-18
- **Автор:** Дмитрий Волков (brainstorm с Claude)
- **Статус:** Draft, awaiting user review
- **Целевая аудитория документа:** будущий имплементатор (Дмитрий + Claude Code как пара)

## TL;DR

Расширение существующего Flutter-приложения Taler ID до **системного агент-shell'а на Android**: приложение становится default launcher, голосовой ассистент (OpenAI Realtime, уже работает) получает позади себя **Claude Agent Loop** (новый, в Dart) с tools, которые покрывают системные действия Android, коммуникацию через инфраструктуру Taler ID, SSH к серверам Дмитрия и делегирование длинных задач Claude Code на DEV-сервере.

Цель — для **единственного пользователя (Дмитрия)** превратить телефон в управляемое голосом окружение, где агент имеет root-уровневый доступ к телефону и существующему дев-стеку Taler ID.

Не голограмма, не AOSP fork, не iOS, не для других людей — это будет добавлено в visions v2-v∞ и спроектировано отдельно.

**Срок:** 4-5 календарных месяцев соло. Daily-driver с конца Phase 1 (~3-5 недель).

---

## Goals

1. **Дмитрий может управлять телефоном голосом для 80%+ ежедневных задач** — звонки, сообщения, заметки, поиск, утренний дайджест, настройки.
2. **Дмитрий может управлять инфраструктурой Taler ID голосом с мобильника** — SSH к серверам, pm2/git/health, integration с monitor.taler.tirol, dev.fix.
3. **Длинные задачи разработки делегируются Claude Code на DEV-сервере** — рефакторинг, диагностика, добавление фичи. Прогресс виден в чат-thread'е на телефоне.
4. **Все эти задачи переплетаются в одной voice/chat-сессии** — нет переключения между "ассистентом", "терминалом" и "приложениями", всё в одной поверхности.
5. **MVP должен работать как launcher** — после разблокировки экрана пользователь сразу видит чат с агентом, не grid приложений.
6. **Архитектура остаётся configurable** — не хардкодим аккаунты Дмитрия, чтобы при желании можно было дать друзьям/жене попробовать без переписывания.

## Non-goals

- **iOS-версия** этого launcher'а (физически невозможно — iOS не разрешает заменить launcher, не даёт Accessibility-уровня доступ к чужим приложениям). На iOS остаётся обычный Taler ID Assistant в текущем виде.
- **AOSP-форк** или собственная ОС — слишком большой scope для соло-разработчика. Возможно в vision v3 при появлении команды.
- **Голограмма, AR, проецируемая клавиатура** — физически нереализуемо в 2026 году в нужном форм-факторе. Vision 2030+.
- **Доступ к банковским приложениям** — юридический риск + банки активно блокируют автоматизацию.
- **Перехват сетевого трафика других приложений без root** — невозможно.
- **Anthropic Computer Use в облаке для бронирования билетов / столов** — отдельный исследовательский трек после v1.
- **Локальная LLM на устройстве** для приватного offline-режима — после v1.
- **Multi-user поддержка**, payment infrastructure, MDM/Enterprise фичи — не нужны.
- **Polyglot voice** — только ru + en, как и в текущем Taler ID Assistant.

---

## Background & Motivation

### Что уже существует в Taler ID

Полностью функциональное Flutter-приложение + NestJS бэкенд с богатой инфраструктурой:

- **OpenAI Realtime голосовой ассистент** через WebRTC — latency ~300-500ms, поддерживает custom tools.
- **Tool-calling framework** (Perplexity `web_search`, контакты, сообщения, и т.д.) уже частично определён в `voice/`.
- **Socket.IO messenger** с реалтайм-сообщениями, voice messages, file uploads.
- **LiveKit P2P звонки** между Taler ID юзерами, плюс OutboundBot для PSTN-звонков с AI-агентом, который сам говорит.
- **AI-twin Python agent** на DigitalOcean (Deepgram + GPT-4o + ElevenLabs Turbo v2.5) — клонированный голос Дмитрия для пропущенных звонков.
- **Auth, KYC, sessions, organizations** — всё на месте.
- **monitor.taler.tirol** — мониторинг 8 серверов, бот `@taleridbot` с `/fix` командами на удалённое action.
- Резервные серверы со streaming replication.

То есть **60-70% технического стека Agent Shell уже построено**. Этот проект — это новый launcher-mode + Claude Agent Loop + tool-расширения, всё остальное переиспользуется.

### Что неправильно у Humane / Rabbit / Friend pendant

- **Latency:** AI в облаке давал 5-10 сек до ответа → unusable. Решается локальной OpenAI Realtime обработкой голоса (это решение Taler ID использует уже сейчас).
- **Battery:** Маленькое устройство + радио + AI = 2-4 часа. Решается тем, что мы не делаем железо — используем существующий смартфон с большой батареей.
- **Без экрана = телефон всё равно нужен.** Главный killer провалов. Решается тем, что мы есть телефон, а не отдельное устройство.
- **Камеры/микрофоны на груди = социально неприемлемо.** Решается тем, что у нас обычная мобильная UX.
- **Маркетинг > продукт** — продукт строится для одного реального пользователя (Дмитрия) с ежедневным фидбеком.

### Почему это работает технически в 2026

- Anthropic Messages API с `tool_use` стабилен, типизированный SDK.
- MCP standardize'ит tool exposure.
- Android Accessibility API даёт root-уровень доступ к экранам чужих приложений без рута самого устройства.
- on-device wake-word (Porcupine) — low-power, точный.
- OpenAI Realtime в production-grade состоянии.

### Почему Apple/Google не сделают это сами

Конфликт интересов. App Store / Play Store дают им миллиарды. Сделать "agent-as-shell" значит каннибализировать собственную app-экономику. Поэтому Siri/Google Assistant обречены оставаться слабыми. **Эта ниша свободна для маленьких игроков.**

---

## Architecture

### Высокоуровневая схема

```
┌─────────────────────────────────────────────────────────────┐
│              User (Дмитрий)                                  │
│        voice / text / quick-action                           │
└─────────────────────────┬───────────────────────────────────┘
                          ▼
┌─────────────────────────────────────────────────────────────┐
│   Taler ID app (Flutter) — Agent Shell                       │
│                                                              │
│   ┌──────────────────────────────────────────────────┐      │
│   │  Voice loop (existing, переиспользуется)          │      │
│   │  OpenAI Realtime ←→ WebRTC ←→ User                │      │
│   └──────────────────────────────────────────────────┘      │
│                          │                                   │
│                          ▼  tool_call                        │
│   ┌──────────────────────────────────────────────────┐      │
│   │  Tool Router (new)                                │      │
│   │  - простые tools → выполняет сразу                │      │
│   │  - tool `agent_task(...)` → Claude Agent Loop     │      │
│   └──────────────┬───────────────────────────────────┘      │
│                  │ (для сложных задач)                       │
│                  ▼                                           │
│   ┌──────────────────────────────────────────────────┐      │
│   │  Claude Agent Loop (Dart, new)                    │      │
│   │  Anthropic Messages API + tool_use cycle          │      │
│   └──────────────┬───────────────────────────────────┘      │
│                  │                                           │
│         ┌────────┼──────────┬──────────┬─────────────┐      │
│         ▼        ▼          ▼          ▼             ▼      │
│  ┌─────────┐ ┌──────┐ ┌──────────┐ ┌────────┐ ┌──────────┐  │
│  │ Backend │ │System│ │ Access.  │ │ Claude │ │ App      │  │
│  │ tools   │ │ tools│ │ Service  │ │ Code   │ │ launcher │  │
│  │ (REST)  │ │      │ │          │ │ proxy  │ │ (Intent) │  │
│  └────┬────┘ └──┬───┘ └────┬─────┘ └───┬────┘ └────┬─────┘  │
└───────┼─────────┼──────────┼───────────┼──────────┼─────────┘
        │         │          │           │          │
        ▼         ▼          ▼           ▼          ▼
   ┌──────────┐ ┌────┐ ┌──────────┐ ┌─────────┐ ┌────────┐
   │ Taler ID │ │OS  │ │WhatsApp, │ │ SSH to  │ │Telegram│
   │ NestJS   │ │APIs│ │Telegram, │ │ DEV/PROD│ │Spotify │
   │ backend  │ │    │ │Gmail UIs │ │ +claude │ │Browser │
   │ +Postgres│ │    │ │          │ │ CLI     │ │etc     │
   └──────────┘ └────┘ └──────────┘ └─────────┘ └────────┘
```

### Два уровня агентов — supervisor & worker

Чтобы не было путаницы в дальнейшем, ключевое разделение:

- **Supervisor agent** = Claude Agent Loop, живёт на телефоне в Flutter-приложении. Запускается из OpenAI Realtime через специальный tool `agent_task(goal, context?)` когда задача сложнее одного tool-вызова. Быстрый, отзывчивый, держит контекст пользовательской сессии.
- **Worker agent** = full `claude` CLI на DEV-сервере. Запускается из Supervisor через tool `agent.claude_code(task, repo?, server?, timeout_min?)`. Имеет full Linux + repo + tests, может работать 5-30 минут. Возвращает PR / коммит / результат.

То есть в системе есть **три LLM-точки**: OpenAI Realtime (голос + быстрые tools), Claude Sonnet 4.6 на телефоне (supervisor), Claude Opus/Sonnet через `claude` CLI на сервере (worker). Каждая — по своей зоне ответственности.

### Принципиальные решения

1. **Voice-loop не трогаем.** OpenAI Realtime уже работает в Taler ID с минимальной латентностью. Заменять на Claude API сейчас = терять realtime. Когда Anthropic выпустит Realtime API — будет switch behind a flag.

2. **Tool Router — новый слой между voice и tools.** Принимает `tool_call` от OpenAI Realtime, классифицирует:
   - **Простой** (`system.*`, `messenger.send`, `web.search`) — выполняется напрямую через соответствующий subsystem (Android channel / REST / Socket.IO).
   - **Агентный** (через специальный tool `agent_task(goal: str, context?: str)`) — кикает Claude Agent Loop, который сам выбирает sequence tools.

   Это критично для **latency**: 90% команд должны выполниться без захода в Claude.

3. **Claude Agent Loop живёт в Flutter-приложении на Dart.** Не на сервере, не в Termux, не embedded Node.js. Простой цикл: `Anthropic.messages.create(...)` → если `tool_use` → выполнить через Tool Router → `tool_result` → повторить. ~200-400 строк Dart-кода.

4. **Claude Code — это один из tools для агента, не отдельная сущность.** Когда Claude Agent Loop решает что задача тяжёлая, он вызывает `agent.claude_code(task, repo?, server?)`. Под капотом это SSH на DEV-сервер + `claude --task "..."` + асинхронный polling. Это паттерн "supervisor agent (на телефоне) + worker agent (на сервере)".

5. **API keys (Anthropic, OpenAI) живут только на Taler ID backend.** Мобильное приложение никогда не знает ключей напрямую — все LLM-вызовы проксируются через NestJS endpoint, который проверяет JWT юзера и форвардит запрос. Это защита от extract-attack из APK.

6. **Anthropic API доступ.** AEZA-сервера блокируются Anthropic IP-фильтрами. Решение: API-прокси через DigitalOcean (167.172.181.34, который уже работает для outbound-bot OpenAI/ElevenLabs/Deepgram).

### Agent Loop — pseudocode

```dart
Future<AgentResult> runAgent({
  required String userGoal,
  required List<ToolDef> tools,
  required ChatHistory history,
}) async {
  final messages = history.asMessages()..add(UserMessage(userGoal));
  while (true) {
    final response = await anthropic.messages.create(
      model: 'claude-sonnet-4-6',  // default; Opus 4.7 via flag
      messages: messages,
      tools: tools.map((t) => t.toAnthropic()).toList(),
      system: agentSystemPrompt(),
    );
    messages.add(response.message);
    if (response.stopReason == 'end_turn') {
      return AgentResult.complete(response.content);
    }
    if (response.stopReason == 'tool_use') {
      final results = await Future.wait(
        response.toolUseBlocks.map((block) => toolRouter.execute(block)),
      );
      messages.add(ToolResultMessage(results));
      continue;
    }
    throw 'unexpected stop reason: ${response.stopReason}';
  }
}
```

### State management

- **Local-first**, в Hive (как сейчас в Taler ID для desktop).
- Что сохраняется:
  - Текущая chat-thread с агентом (~last 100 turns)
  - Long-running agent tasks (claude_code в процессе) с pollable state
  - SSH ключи (в Android Keystore + биометрический lock)
  - OAuth tokens (Gmail, Calendar)
- Что синхронизируется на сервер (opt-in): chat history backup, agent task results — для возможности восстановления при потере устройства.

### Sync с существующим Taler ID Assistant

OpenAI Realtime сессия в Taler ID уже хранит транскрипты (`AssistantTranscript` table). Мы дополнительно записываем там же Claude Agent transitions для аудита и debugging.

---

## Tool Taxonomy

### v1 (MVP, ~10-13 weeks) — 7 групп

#### 1. `system.*` — управление телефоном
| Tool | Behavior | Backing API |
|------|----------|-------------|
| `system.launch_app(name_or_package)` | Открыть приложение | Android Intent ACTION_MAIN |
| `system.home()`, `system.back()`, `system.recent()` | Системные кнопки | Accessibility |
| `system.screenshot() → image` | Скриншот | MediaProjection |
| `system.set(setting: enum, value)` | wifi/bt/brightness/volume/DND/airplane/flashlight | SettingsProvider + system APIs |
| `system.alarm(time, label?)`, `system.timer(seconds, label?)` | Будильник, таймер | Intent AlarmClock |
| `system.clipboard.read()`, `system.clipboard.write(text)` | Буфер обмена | ClipboardManager |
| `system.notifications.read()` | Прочитать текущие уведомления других приложений | NotificationListenerService |

#### 2. `call.*` — звонки
| Tool | Behavior |
|------|----------|
| `call.dial(number)` | PSTN-звонок через Android dialer, твой голос. Permission: CALL_PHONE |
| `call.taler(handle_or_user_id)` | LiveKit P2P звонок Taler ID юзеру (уже работает) |
| `call.outbound(number, goal, voice_id?)` | OutboundBot говорит сам, агент возвращает сводку. Использует существующую инфру (Asterisk на Selectel → SIPNET) |
| `call.history(filter?)` | История звонков (REST `/voice/calls`) |
| `call.recording.read(call_id)` | Транскрипт + сводка записи |

#### 3. `messenger.*` + `contacts.*`
| Tool | Behavior |
|------|----------|
| `messenger.send(conv_or_handle, text)` | Сообщение в Taler ID мессенджер. Существует Socket.IO `new_message` |
| `messenger.search(query, scope?)` | Найти сообщение в истории |
| `messenger.recent(limit?)` | Последние / непрочитанные |
| `contacts.find(name_or_phone)` | Поиск |
| `contacts.add(...)` | Создать |

#### 4. `mail.*`, `calendar.*` — Gmail + Google Calendar API
| Tool | Behavior |
|------|----------|
| `mail.search(query, mailbox?)` | Gmail API |
| `mail.read(message_id)` | Полный текст |
| `mail.send(to, subject, body)` | Отправка (требует confirm widget) |
| `mail.draft(...)` | Черновик без отправки |
| `calendar.list(range)` | События в диапазоне |
| `calendar.create/update(...)` | CRUD событий |

OAuth-токены хранятся в Taler ID backend на user_id Дмитрия, refresh автоматически.

#### 5. `web.*` — интернет
| Tool | Behavior |
|------|----------|
| `web.search(query)` | Perplexity Sonar (уже есть `web_search` в assistant) |
| `web.fetch(url)` | Скачать страницу, вернуть extracted text |
| `web.read_pdf(url_or_file)` | Извлечь текст из PDF |
| `web.summarize(url_or_text, focus?)` | Реферат с уклоном (через Claude в бэкенде) |

#### 6. `dev.*` — управление разработкой (USP)
| Tool | Behavior |
|------|----------|
| `dev.ssh(host, command, timeout?)` | Универсальный SSH. `host` ∈ {dev, prod, monitor, ru-sip, asterisk, do-outbound, prod-standby, dev-mirror} (alias→IP в конфиге) |
| `dev.tail(host, path, lines?)` | tail логов |
| `dev.pm2.list(host)`, `dev.pm2.restart(host, name)`, `dev.pm2.logs(host, name, n?)` | PM2 |
| `dev.git.status(host, repo)`, `dev.git.pull(host, repo)` | Git |
| `dev.health(host?)` | Краткий health check (cpu, mem, диски, ключевые сервисы) |
| `dev.monitor.status()` | Снапшот всех боксов с monitor.taler.tirol (использует `/status` бота `@taleridbot`) |
| `dev.fix(box, action, target)` | То же что `/fix` в боте — `docker_restart`, `systemctl_restart`, `pm2_restart` |

SSH-ключи в Android Keystore с биометрическим lock; для агента — отдельный ключ, ограниченный по `command="..."` в `authorized_keys` (white-list безопасных команд).

#### 7. `agent.*` — делегирование
| Tool | Behavior |
|------|----------|
| `agent.claude_code(task, repo?, server?, timeout_min?)` | Запускает `claude` CLI на DEV (по умолчанию). Возвращает `task_id` |
| `agent.status(task_id)` | Прогресс длинной задачи |
| `agent.result(task_id)` | Финальный результат + ссылка на PR/коммит |
| `agent.cancel(task_id)` | Прервать |

### v2 (после MVP)

- **`screen.*`** — полный Accessibility-стек: `read`, `find(text)`, `click(elem)`, `type(text)`, `scroll(dir)`, `wait_for(elem)`. Работает с любым приложением без API. Хрупкий fallback.
- **`telegram.*`** — через MTProto (структурированно)
- **`spotify.*`** — Web API
- **`maps.*`** — Google Maps Directions/Places API
- **`notes.*`, `tasks.*`** — заметки/задачи (Taler ID local or Notion API)

### v3 — мечта

- **`booking.*`** — Anthropic Computer Use в облаке для бронирования билетов, столов через web
- **`payments.*`** — оплаты (отдельный security-критичный слой)

### Что НЕ делаем даже в v3

- Доступ к банковским приложениям
- Перехват трафика без рута
- Чтение паролей других приложений
- Замена клавиатуры (отдельный IME = отдельный продукт)

---

## UX & Daily Flows

### Launcher mode

`<intent-filter><category android:name="android.intent.category.HOME" /></intent-filter>` на MainActivity. Первый запуск → системный диалог "Выбрать домашний экран". Запасной выход всегда: swipe-up от нижнего края → grid установленных приложений.

### Главный экран (три зоны сверху вниз)

1. **Greeting/context card** — приветствие, время, ближайшая встреча, важные триггеры (deploy failed, пропущенный звонок).
2. **Chat thread** — продолжение последнего диалога с агентом. Утром агент сам инициирует брифинг.
3. **Input area** — большая mic-кнопка справа + текстовое поле + переключатель ⌨/🎤.

### Способы инвокации в v1

| Способ | Когда |
|--------|-------|
| Tap mic в launcher | Большинство случаев |
| Wake-word "Эй, Талер" (Porcupine, toggle в settings) | Когда руки заняты, off by default |

В v2: press-and-hold Power, из уведомления, notification-shade quick action.

### Голосовой поток

1. Tap mic → listening state (пульсирующий круг, текст диктовки накапливается live).
2. Audio streamится в OpenAI Realtime через WebRTC.
3. Пользователь молчит 1.5с → ответ голосом + text bubble.
4. tool_use → Tool Router → выполнение → результат в chat thread с динамическим UI.

### Динамический UI — примитивы

| Widget | Использование |
|--------|---------------|
| `text` | Простой ответ |
| `card_list` | Список (письма, события, контакты) |
| `confirm` | "Подтверди отправку: [Отправить] [Изменить] [Отмена]" |
| `code_block` | Сниппет / лог |
| `progress` | Долгая задача с live обновлениями |
| `media_player` | Запись звонка, voice message |
| `chooser` | "Какой Игорь?" — список с фото |
| `error_card` | Что упало + suggested action |

v2: `chart`, `map`, `form`.

### Долгие задачи (agent.claude_code)

1. Агент голосом: *"Запустил рефакторинг, будет готово ~15 минут"*
2. На главном экране — `progress` card наверху, заменяет greeting card.
3. Card обновляется live: что claude_code делает прямо сейчас.
4. Tap "Подробнее" → полный лог.
5. Контролы: **Пауза / Отменить**.
6. Завершение → push + голос *"Готов PR в feature/X, основное: ..."*.

**Параллельность:** агент остаётся отзывчивым на другие команды пока claude_code работает в фоне.

### Guardrails — подтверждения опасных действий

| Action | Подтверждение |
|--------|---------------|
| `mail.send` | `confirm` widget с черновиком, тап "Отправить" |
| `call.outbound` | `confirm` widget с номером + целью + voice, тап "Звонить" |
| `dev.ssh(host=prod, ...)` где cmd изменяющая (`pm2 restart`, `git pull`) | `confirm` widget с явной кнопкой |
| `agent.claude_code(... push: true)` | `confirm` перед пушем коммита |
| `system.set("airplane", true)` | Двойное подтверждение |
| `dev.fix(box=prod, ...)` | Только текстом, не голосом — anti-misfire |

В v2: voice ID + биометрия для опасных операций (защита от "берут чужой телефон").

### Permission onboarding (первый запуск)

1. Установить как default home
2. Accessibility Service (объяснение)
3. Микрофон
4. Уведомления + NotificationListener
5. CALL_PHONE
6. SYSTEM_ALERT_WINDOW (опционально, для overlay)
7. OAuth Google (mail/calendar)
8. Импорт SSH ключей (через QR или scp вручную, single-time)

### Privacy

- Accessibility-логи только в памяти агента, не на сервер.
- Чат-thread локально в Hive, opt-in sync на бэк.
- Tool-результаты с чувствительными данными (письма, сообщения) — кэш 5 минут, потом forget.
- Mic-индикатор всегда виден в status bar (Android system requirement).
- Wake-word audio обрабатывается локально через Porcupine, audio в облако не уходит пока не сработал triggering.

---

## Implementation Phases

### Phase 0 — Setup & Spike (1-2 нед)

- Taler ID становится HOME launcher (AndroidManifest).
- Простой chat-screen в новой ветке `feature/agent-shell`.
- Claude Agent Loop в Dart (Anthropic Messages API).
- API-прокси endpoint в Taler ID NestJS бэке (`POST /agent/claude` — проксирует messages.create, скрывает ключ, проверяет JWT).
- Один тестовый tool (`echo`) для валидации сквозного маршрута.
- Используешь как launcher с конца Phase 0 — собираешь раздражения.

**Exit criteria:** voice → OpenAI Realtime → tool_use `agent_task` → Claude Loop → echo tool → ответ голосом. Сквозной маршрут работает.

### Phase 1 — Core tools (2-3 нед)

- `system.*` (launch_app, alarm, timer, clipboard, settings, screenshot, notifications.read)
- `call.*` (dial, taler, outbound, history, recording.read) — `taler`/`outbound` уже есть в backend, обёртка как tool
- `messenger.*` + `contacts.*` (через Taler ID Socket.IO + REST)
- `web.*` (search reuses Perplexity tool из текущего Assistant; fetch + read_pdf + summarize — новое)
- Простой Tool Router в OpenAI Realtime context: эти tools регистрируются прямо в Realtime session, обходят Claude.
- Onboarding-flow для permission'ов.

**Exit criteria:** Дмитрий переходит на Agent Shell как daily driver, не возвращается на стоковый launcher.

### Phase 2 — Dev management (2 нед)

- SSH client в Dart (dartssh2)
- SSH key management UI + биометрический lock в Android Keystore
- `dev.ssh`, `dev.tail`, `dev.pm2.*`, `dev.git.*`, `dev.health`
- `dev.monitor.status` — REST call к monitor.taler.tirol
- `dev.fix(box, action, target)` — proxy через taleridbot API

**Exit criteria:** все ежедневные dev-задачи Дмитрия выполнимы голосом — статус деплоев, перезапуск pm2, git pull, чтение логов.

### Phase 3 — Heavy delegation (1-2 нед)

- Установка `claude` CLI на DEV-сервере (89.169.55.217).
- Обёртка `agent.claude_code(task, repo?)` — SSH `claude --task "..." --repo ...` + асинхронный polling.
- Status streaming: claude эмитит structured progress в файл, агент его tail'ит.
- Progress card UI в chat thread с live updates.
- Push notification при завершении.

**Exit criteria:** "Зарефактори X" → 15 минут → PR в ветке.

### Phase 4 — Mail + Calendar (2 нед)

- Google OAuth flow в Flutter (через `google_sign_in` + custom scopes).
- `mail.*` через Gmail API (Dart's `googleapis` package).
- `calendar.*` через Google Calendar API.
- Утренний дайджест — отдельный background job, собирает почту + календарь + Taler ID notifications + результаты ночных задач Claude Code.

**Exit criteria:** утром агент сам пишет дайджест, "перенеси встречу с X на час", "отправь Игорю что Y".

### Phase 5 — Accessibility (2 нед)

- AccessibilityService setup, manifest, runtime config.
- `screen.read`, `screen.find(text|description)`, `screen.click`, `screen.type`, `screen.scroll`, `screen.wait_for`.
- Тест на 2-3 приложениях, которыми Дмитрий пользуется ежедневно (Telegram, WhatsApp, ещё).

**Exit criteria:** "напиши в WhatsApp X" работает (хрупко, но работает).

**Decision point:** стоит ли Accessibility того (хрупкость vs покрытие)? Если нет — пропускаем, идём в v2 с нативными API.

### Phase 6 — Hardening (1-2 нед)

- Foreground service (Android 14+ requires `mediaProjection` или `specialUse` type).
- Battery-профайлинг, оптимизация.
- Crash reporting.
- Wake-word integration (Porcupine, toggle).
- Polish onboarding flow.

**Exit criteria:** стабильность 99%+, daily-driver quality.

### Параллельный поток — "Use it"

С конца Phase 1 — Taler ID = launcher Дмитрия. Не возвращаемся на стоковый. Каждый день записываются 1-2 раздражения / упущенных сценария в journal (в Taler ID notes). В конце недели приоритезируется: чинить ли текущую фазу или продвинуться вперёд.

### Decision points в конце каждой фазы

| Конец фазы | Решение |
|------------|---------|
| Phase 1 | Достаточно ли быстрый воркфлоу? Если нет — оптимизация latency, а не новые фичи |
| Phase 2 | Воспроизводимо ли всё, что делал в терминале? Если нет — допиливай dev tools |
| Phase 3 | claude_code экономит время или создаёт больше работы (надо проверять каждый PR)? |
| Phase 4 | Pull или push модель уведомлений (агент инициативен или реактивен)? |
| Phase 5 | Accessibility стоит того? Может, пропустить в v2 с нативными API |

### Итого

~10-13 рабочих недель → **4-5 календарных месяцев** с учётом параллельной работы по основному Taler ID.

---

## Risks & Mitigations

| # | Риск | Митигация |
|---|------|-----------|
| R1 | OpenAI Realtime → Claude → tool: суммарная latency делает голосовой UX медленным | Простые tools идут в обход Claude — прямо OpenAI Realtime вызывает их. Claude только для `agent_task` (сложные задачи). |
| R2 | Anthropic/OpenAI блокируют RU IP / банковские карты | API-прокси через DigitalOcean (167.172.181.34, уже есть). Оплата через зарубежную карту. |
| R3 | Anthropic API key утечка через APK | Все LLM-вызовы через Taler ID NestJS backend, ключи только там. |
| R4 | Google Play может забанить за Accessibility-abuse | Sideload через APK ссылку (как уже работает Taler ID dev APK). Play Store не цель. |
| R5 | Battery drain (foreground service + wake-word + WebRTC) | Wake-word off by default. Foreground service в минимальном режиме (только active session). Battery audit после Phase 6. |
| R6 | Опасные команды голосом ("удали PROD") если кто-то возьмёт телефон | Voice-ID toggle (известный голос-владелец, v2), биометрия перед опасными tools, confirm widget для PROD, текстовое подтверждение для `dev.fix prod`. |
| R7 | SSH-ключи на телефоне — украли мобилу → root к серверам | Ключи в Android Keystore с биометрическим lock. Отдельный SSH-ключ только для агента (отзывной). `authorized_keys` с `command="..."` whitelist. |
| R8 | Claude часто выбирает не тот tool / не те параметры | Хороший system prompt, tool descriptions с примерами, few-shot. После Phase 3 — sprint на prompt engineering с evals (golden set 50 команд). |
| R9 | Bills: OpenAI Realtime + Claude API на интенсивном использовании $200-500/месяц | Budget cap в settings, дефолт Sonnet 4.6 (не Opus), переключатель на push-to-talk вместо always-listening. |
| R10 | Sync между OpenAI Realtime и Claude Agent Loop | Чёткий state machine: 5 состояний (idle / listening / thinking-quick / thinking-deep-agent / speaking-result). Переходы через события. |
| R11 | iOS пользователи остаются за бортом | iOS остаётся с обычным Taler ID Assistant. Это **только Android продукт.** |
| R12 | Foreground service ограничения Android 14+ | Использовать `mediaProjection` или `specialUse` type. Persistent notification обязателен. |

### Гипотезы, которые могут провалиться

1. **Голос лучше touch как первичный интерфейс.** Возможно нет в офисе / на улице. Тогда продукт = "хороший Claude-чат на телефоне с системными tools" — узкая ниша, но всё ещё ценный.
2. **Tool latency приемлема.** Если каждый шаг агента 2-3 сек, цепочка из 5 шагов = 15 сек. Защита: speculative execution / параллельные tool calls (Anthropic API поддерживает).
3. **Daily-driver итерация улучшит продукт.** Если базовая UX плохая, откатишься на стоковый. Защита: Phase 1 должна закончиться **рабочим продуктом**, не "почти рабочим".

---

## Defaults & Decisions Log

| # | Решение | Default |
|---|---------|---------|
| D1 | Claude модель для агент-loop | Sonnet 4.6 (быстрее + 5× дешевле Opus). Opus 4.7 через флаг `model: opus` для самых сложных задач |
| D2 | Где живёт agent state | Local-first в Hive + opt-in sync на Taler ID backend |
| D3 | OpenAI Realtime vs альтернативы | Остаётся (уже работает, low latency). Переход на Claude Realtime когда выйдет |
| D4 | Wake-word engine | Picovoice Porcupine (бесплатно для 1 user, on-device). Off by default |
| D5 | Где хранится спек | `~/Downloads/taler_id_mobile/docs/superpowers/specs/` (вместе с кодом) |
| D6 | Целевая аудитория v1 | Дмитрий один. Архитектура configurable — не хардкодим аккаунты, чтобы при желании можно расширить без переписки |
| D7 | Платформа | Android only. iOS не получит этот launcher |
| D8 | Языки | ru + en (как сейчас в Taler ID) |
| D9 | Distribution | Sideload через APK (как сейчас taler-id-dev.apk). Play Store не цель |
| D10 | API key security | Все LLM-вызовы через NestJS backend, мобильное приложение никогда не знает ключи |

---

## Open Questions

| # | Вопрос | Зачем нужно |
|---|--------|-------------|
| Q1 | Какой Pixel-модель у Дмитрия для разработки? | Setup, минимальный API level (рекомендую API 33+ для совместимости с Accessibility и foreground service quirks) |
| Q2 | Стоимостной budget cap — какой устраивает в месяц? | Зашить в settings UI |
| Q3 | Какой набор приложений выбирает Дмитрий для Phase 5 (Accessibility test)? | Топ-3 которые он сам активно использует — нужно знать чтобы writing-plans мог в имплементации указать примеры |
| Q4 | Стоит ли добавлять `dev.cron.*` / `dev.docker.*` / `dev.systemd.*` tools в Phase 2? | Зависит от того, насколько часто Дмитрий это делает с телефона |
| Q5 | Включаем ли в v1 интеграцию с `@taleridbot` Telegram-ом — отвечать на сообщения через bot? Или это лишний пласт? | Бот уже умеет принимать команды через Telegram |
| Q6 | Когда заходим в Anthropic Computer Use (v3)? Конкретный trigger? | Скорее всего "когда задачи на бронирование становятся регулярными" — отдельный сигнал |

---

## Связь с другими частями Taler ID

| Существующее в Taler ID | Используется как |
|--------------------------|-----------------|
| OpenAI Realtime Assistant | Voice layer (без изменений) |
| Socket.IO messenger | Tools `messenger.send/search/recent` |
| LiveKit P2P calls | Tool `call.taler` |
| OutboundBot (Asterisk + livekit-sip + Python agent) | Tool `call.outbound` |
| AI Voice Twin (Deepgram + GPT-4o + ElevenLabs) | Не используется в этом проекте (для входящих звонков, не для агента) |
| AssistantTranscript table | Логи всех agent сессий для аудита |
| Sumsub KYC | Не используется |
| LiveKit AI Agent (legacy) | Не используется |
| monitor.taler.tirol + `@taleridbot` | Tools `dev.monitor.status`, `dev.fix` |
| Резервные standby-сервера | Tool `dev.health` мониторит лаг репликации |

---

## Что после v1

После того как daily-driver стабилизируется (Phase 6+), приоритизированный backlog:

1. **`screen.*` Accessibility** для топ-15 приложений (если Phase 5 показал, что подход рабочий)
2. **Локальная LLM** на устройстве (Phi-4 mini или Gemma) — для приватного offline-режима для чувствительных задач
3. **Anthropic Computer Use в облаке** — `booking.*` tool для бронирования билетов/столов через реальный web
4. **MCP server registry** — подключать внешние MCP-серверы, написанные другими людьми
5. **Multi-device sync** — тот же агент на ноутбуке + планшете + телефоне с общей memory/history
6. **iOS companion app** — без launcher-mode, но с tools которые работают в обычном sandbox (звонки, мессенджер, dev tools через SSH). Чтобы Дмитрий мог использовать с iPhone тоже
7. **AR companion display** (если когда-то железо появится) — голограмма как vision 2030

---

## Метрики успеха

После Phase 6, через 1 месяц использования:

- **80%+ ежедневных мобильных задач** Дмитрий выполняет через агента, не через приложения
- **Stock launcher** — не открывает ни разу за месяц
- **Деплои Taler ID** — 90%+ через голос с мобильника, не через десктоп-терминал
- **Длинные задачи** — минимум 2-3 в неделю делегированы Claude Code (рефакторинги, диагностики, hotfix)
- **Stability:** менее 1 краша в неделю, ни одного потерянного chat-thread'а

---

## История изменений

- 2026-05-18 — Initial draft, после brainstorm-сессии в Claude Code

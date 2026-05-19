# Taler ID Agent Shell — Design

- **Дата:** 2026-05-18
- **Автор:** Дмитрий Волков (brainstorm с Claude)
- **Статус:** Draft, awaiting user review
- **Целевая аудитория документа:** будущий имплементатор (Дмитрий + Claude Code как пара)

## TL;DR

Расширение существующего Flutter-приложения Taler ID до **системного агент-shell'а на Android**: приложение становится default launcher, голосовой ассистент (OpenAI Realtime, уже работает) получает позади себя **Claude Agent SDK** (новое, на NestJS-бэкенде) с tools, которые покрывают системные действия Android (через WebSocket-обратку на телефон), коммуникацию через инфраструктуру Taler ID, SSH к серверам Дмитрия и full Linux на самом бэкенде.

**Аутентификация — OAuth через `claude` CLI**, не API-ключ. Тот же паттерн что в `taler-monitor`: `claude login` на сервере, креды живут в `~/.claude/.credentials.json`, SDK подбирает их автоматически. Биллинг через Claude max-план, не через API-credits.

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
│                          │ tool_call                         │
│                          ▼                                   │
│   ┌──────────────────────────────────────────────────┐      │
│   │  Tool Router (Flutter)                            │      │
│   │  - Простой tool → выполняет на телефоне сразу     │      │
│   │  - tool `agent_task(...)` → POST /agent/run       │      │
│   │  - Phone-tool callbacks из бэкенда — через WS     │      │
│   └──────────────┬───────────────────────────────────┘      │
└──────────────────┼───────────────────────────────────────────┘
                   │ HTTP/WS (JWT)
                   ▼
┌─────────────────────────────────────────────────────────────┐
│   Taler ID NestJS backend                                    │
│                                                              │
│   ┌──────────────────────────────────────────────────┐      │
│   │  AgentController (new)                            │      │
│   │  POST /agent/run {goal, conversationId}           │      │
│   │  WS /agent/tools — bridge для phone-side tools    │      │
│   └──────────────┬───────────────────────────────────┘      │
│                  │                                           │
│                  ▼                                           │
│   ┌──────────────────────────────────────────────────┐      │
│   │  @anthropic-ai/claude-agent-sdk                   │      │
│   │  OAuth из ~/.claude/.credentials.json             │      │
│   │  Полный Claude Code как библиотека: planner +     │      │
│   │  встроенные tools (Bash, Read, Edit, Grep, Task)  │      │
│   │  + кастомные tools (см. ниже)                     │      │
│   └──────────────┬───────────────────────────────────┘      │
│                  │                                           │
│         ┌────────┼──────────┬──────────┐                     │
│         ▼        ▼          ▼          ▼                     │
│   Built-in     Custom    Phone-side  MCP servers             │
│   tools        backend   tools (via  (optional,              │
│   (Bash,       tools     WS bridge)  Phase 1+)               │
│   Read, ...)   (REST)                                        │
└────────────────────────────────────────────────────────────-─┘
        │         │              │
        ▼         ▼              ▼
   Full Linux  Taler ID       Flutter app:
   on server,  Postgres,      Accessibility,
   SSH ко всем serverов,      Android system,
   серверам   REST endpoints  notifications,
                              app-launching
```

### Архитектура: 2 LLM-уровня

После апдейта дизайна (см. также **Update Log** в конце):

- **Voice layer (existing):** OpenAI Realtime в Flutter. Голос, низкая латентность, быстрые tools которые **выполняются на телефоне без захода в Claude** (`system.set`, `system.launch_app`, простые звонки и т.д.). Когда задача сложнее одного шага, Realtime зовёт специальный tool `agent_task(goal, context?)`, который проксируется в бэкенд.

- **Agent layer (new):** Claude Agent SDK на NestJS-бэкенде. Это **Claude Code как библиотека**: тот же планировщик и встроенные tools (Bash, Read, Edit, Grep, Task, MCP integration), плюс кастомные tools которые мы регистрируем (звонки, мессенджер, dev-операции, phone-side tools через WebSocket-обратку).

То есть в системе **2 LLM-точки** (было 3): OpenAI Realtime (голос + локальные tools) и Claude Agent SDK на бэкенде (тяжёлые задачи, дев-работа, Linux). Прежний "worker agent через SSH" из спека больше не нужен — бэкенд **уже** на сервере, у Claude Agent SDK прямой доступ к Bash, файловой системе и SSH-tools к другим серверам.

### Принципиальные решения

1. **Voice-loop не трогаем.** OpenAI Realtime уже работает в Taler ID с минимальной латентностью. Заменять на Claude API сейчас = терять realtime. Когда Anthropic выпустит Realtime API — будет switch behind a flag.

2. **Tool Router на Flutter — простой классификатор.** Принимает `tool_call` от OpenAI Realtime, классифицирует:
   - **Локальный** (`system.*`, `messenger.send`, `web.search`) — выполняется на телефоне без сети LLM (Android channel / REST / Socket.IO).
   - **Агентный** (через `agent_task(goal: str, context?: str)`) — POST на backend, который запускает Claude Agent SDK.

   Это критично для **latency**: 90% команд должны выполниться без захода в Claude.

3. **Claude Agent Loop = Claude Agent SDK на NestJS-бэкенде.** Используем официальный пакет `@anthropic-ai/claude-agent-sdk`. Не строим свой цикл `messages.create` — SDK сам управляет turn'ами, tool_use, ошибками, retries, и даёт богатый набор built-in tools. ~100 строк интеграции вместо ~400 строк своего цикла.

4. **Authentication через OAuth.** SDK подбирает credentials из `~/.claude/.credentials.json` на сервере (создаются командой `claude login`). API-ключ **не** нужен. Биллинг идёт через Claude max-план аккаунта Дмитрия — тот же что используется в Claude Code и в `taler-monitor`.

5. **Claude Code как worker для тяжёлых задач больше не нужен отдельно.** SDK на бэкенде уже = Claude Code. Bash tool работает на DEV-сервере где крутится бэкенд. SSH-tools (`dev.ssh(host, cmd)`) дают доступ к другим серверам. Длинные задачи (рефакторинг) запускаются как саб-агенты SDK (через `Task` tool) — без отдельной CLI-обёртки.

6. **API keys (OpenAI) живут только на Taler ID backend.** OpenAI Realtime по-прежнему API-key. Anthropic — OAuth (без ключа). Мобильное приложение никогда не знает любых ключей — все LLM-вызовы проксируются через NestJS, который проверяет JWT юзера и форвардит запрос.

7. **Anthropic OAuth-эндпойнт и AEZA-блокировки.** OAuth через Claude Code SDK ходит на те же `api.anthropic.com` URL что и API-key путь. Если AEZA-сервера блокируются — настраиваем passthrough nginx на DigitalOcean (167.172.181.34, который уже используется для outbound-bot). Решается на этапе деплоя если нужно.

8. **Phone-side tools реализованы через WebSocket-обратку.** Когда бэкендный агент хочет выполнить tool, который физически должен идти с телефона (читать экран WhatsApp, открыть приложение), SDK вызывает custom tool `phone(action, args)` → бэкенд шлёт сообщение в WS-канал телефона → Flutter выполняет → возвращает результат → SDK продолжает. Этот паттерн уже используется в Taler ID для OpenAI Realtime tool dispatch — переиспользуется как есть.

### Agent integration — pseudocode

```typescript
// backend src/agent/agent.service.ts
import { query, tool } from '@anthropic-ai/claude-agent-sdk';

@Injectable()
export class AgentService {
  async runAgent(params: { goal: string; userId: string; conversationId?: string }) {
    const customTools = [
      tool({
        name: 'echo',
        description: 'Echo back the text verbatim. For plumbing validation.',
        input_schema: { type: 'object', properties: { text: { type: 'string' } }, required: ['text'] },
        handler: async ({ text }) => text,
      }),
      // Phase 1+: phone-side tools via WS bridge, dev-tools via SSH, etc.
    ];

    const result = await query({
      prompt: params.goal,
      model: 'claude-sonnet-4-6',  // Opus 4.7 by flag
      tools: customTools,
      // OAuth credentials автоматически подбираются из ~/.claude/.credentials.json
    });

    return { finalText: result.finalText, toolCalls: result.toolCalls };
  }
}
```

**Flutter сторона стала намного проще:**

```dart
// lib/core/agent/agent_client.dart
class AgentClient {
  final Dio dio;
  AgentClient(this.dio);

  Future<AgentRunResult> runAgent(String goal, {String? conversationId}) async {
    final resp = await dio.post<Map<String, dynamic>>('/agent/run', data: {
      'goal': goal,
      if (conversationId != null) 'conversationId': conversationId,
    });
    return AgentRunResult.fromJson(resp.data ?? const {});
  }
}
```

Нет агентного цикла в Dart, нет ручного управления turn'ами, нет своего ToolRegistry на телефоне. Phone-side tool execution идёт через отдельный WebSocket-канал — это отдельная подсистема, не часть agent loop'а.

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

SSH-ключи живут на бэкенде (DEV-сервер), не на телефоне — агент использует их через bash от своего юзера. Для удалённых серверов (PROD, monitor, ru-sip и т.д.) — отдельные ключи с `command="..."` в `authorized_keys` (white-list безопасных команд). На телефоне SSH-ключей нет — атака через краденый телефон не даёт root к серверам.

#### 7. Long-running sub-tasks (через built-in `Task` tool)

Claude Agent SDK имеет встроенный `Task` tool для запуска саб-агентов. Раньше планировался отдельный `agent.claude_code(...)` для длинных задач (рефакторинг, диагностика) — теперь это просто `Task` от SDK:

- Главный агент запускает саб-агента через `Task(description, subagent_type, prompt)`.
- Саб-агент получает полный доступ к Bash, Read, Edit, Grep на DEV-сервере, может работать 5-30 минут.
- Возврат — полный отчёт саб-агента, главный агент его обрабатывает и отдаёт пользователю.
- Пользователь видит прогресс на телефоне через WebSocket-стрим (status updates от бэкенда).

Это эффективнее чем строить свою CLI-обёртку: ноль кода, SDK сам управляет sub-agent state и context.

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

### Долгие задачи (через SDK `Task` sub-agents)

1. Агент голосом: *"Запустил рефакторинг, будет готово ~15 минут"*.
2. На главном экране — `progress` card наверху, заменяет greeting card.
3. Card обновляется live: что саб-агент делает прямо сейчас (статусы стримятся через WebSocket с бэкенда).
4. Tap "Подробнее" → полный лог саб-агентного диалога.
5. Контролы: **Пауза / Отменить** (шлют abort на бэкенд, SDK останавливает sub-agent).
6. Завершение → push + голос *"Готов PR в feature/X, основное: ..."*.

**Параллельность:** агент на бэкенде остаётся отзывчивым на другие команды пока саб-агент работает в фоне. Каждая chat-сессия имеет свой агентный run, sub-agents живут внутри родительского run'а.

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

### Phase 0 — Setup & Spike (~1 нед — упростилось от 1-2 нед после OAuth-апдейта)

- Taler ID становится HOME launcher (AndroidManifest).
- Простой chat-screen в новой ветке `feature/agent-shell-phase-0`.
- Backend интегрирует `@anthropic-ai/claude-agent-sdk` с OAuth.
- `claude` CLI установлен и залогинен на DEV-сервере (через `claude login`).
- `POST /agent/run` endpoint с JWT, body `{goal}`, использует SDK для агентного run'а с custom `echo` tool, возвращает `{finalText, toolCalls}`.
- Flutter: `AgentClient` (Dio wrapper), `AgentBloc`, chat screen. **Без своего agent loop в Dart** — клиент тонкий.
- `agent_task` tool регистрируется в существующем OpenAI Realtime session → шлёт на бэкенд.
- Используешь как launcher с конца Phase 0.

**Exit criteria:** voice → OpenAI Realtime → tool_use `agent_task` → backend `/agent/run` → Claude Agent SDK (OAuth) → echo tool → ответ голосом. Сквозной маршрут работает. На DEV.

### Phase 1 — Core tools (2-3 нед)

- `system.*` (launch_app, alarm, timer, clipboard, settings, screenshot, notifications.read)
- `call.*` (dial, taler, outbound, history, recording.read) — `taler`/`outbound` уже есть в backend, обёртка как tool
- `messenger.*` + `contacts.*` (через Taler ID Socket.IO + REST)
- `web.*` (search reuses Perplexity tool из текущего Assistant; fetch + read_pdf + summarize — новое)
- Простой Tool Router в OpenAI Realtime context: эти tools регистрируются прямо в Realtime session, обходят Claude.
- Onboarding-flow для permission'ов.

**Exit criteria:** Дмитрий переходит на Agent Shell как daily driver, не возвращается на стоковый launcher.

### Phase 2 — Dev management (1-2 нед — упростилось)

- `dev.*` tools реализуются как custom tools в Claude Agent SDK на бэкенде.
- Большая часть работает **уже из коробки** через встроенный SDK `Bash` tool (он живёт на DEV, имеет full Linux): `pm2 list`, `tail`, `git status` и т.д. — агент просто пишет shell-команды.
- Кастомные tools для удобства: `dev.ssh(host, command)` — SSH к другим серверам через сконфигурированные алиасы, `dev.monitor.status()` — REST к monitor.taler.tirol, `dev.fix(box, action, target)` — proxy через taleridbot API.
- SSH-ключи на DEV-сервере, не на телефоне (на телефоне SSH-клиента нет — это backend-только).

**Exit criteria:** все ежедневные dev-задачи Дмитрия выполнимы голосом — статус деплоев, перезапуск pm2, git pull, чтение логов.

### Phase 3 — Heavy delegation (упрощается)

Раньше планировалась отдельная фаза для `agent.claude_code(task, repo?)` через SSH-обёртку. **Теперь это уже работает в Phase 2** через built-in `Task` tool из SDK — главный агент запускает саб-агента, и тот выполняет тяжёлую задачу с full Bash/Read/Edit.

**Что остаётся в этой фазе:**
- Progress card UI в chat thread с live updates статусов саб-агента (WebSocket стрим с бэкенда).
- Push notification при завершении.
- Контролы pause / cancel — отправлять abort на бэкенд, SDK останавливает sub-agent.

**Exit criteria:** "Зарефактори X" → 15 минут → саб-агент завершается → главный возвращает summary → push с PR URL.

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
| R3 | Anthropic OAuth credentials на бэкенде утекают / истекают | Credentials в `~/.claude/.credentials.json` с правильным chmod 600. Если истекают — re-login (`claude login` на DEV). Мониторим через `dev.health` tool. Мобильное приложение никогда не видит credentials. |
| R4 | Google Play может забанить за Accessibility-abuse | Sideload через APK ссылку (как уже работает Taler ID dev APK). Play Store не цель. |
| R5 | Battery drain (foreground service + wake-word + WebRTC) | Wake-word off by default. Foreground service в минимальном режиме (только active session). Battery audit после Phase 6. |
| R6 | Опасные команды голосом ("удали PROD") если кто-то возьмёт телефон | Voice-ID toggle (известный голос-владелец, v2), биометрия перед опасными tools, confirm widget для PROD, текстовое подтверждение для `dev.fix prod`. |
| R7 | SSH-ключи на бэкенде → если бэкенд скомпрометирован, доступ ко всем серверам | SSH-ключи на DEV-сервере не в дефолтном `~/.ssh/`, а в отдельном пути под dvolkov-юзером (или service-юзером). `authorized_keys` на удалённых серверах с `command="..."` whitelist безопасных команд. На самом телефоне SSH-ключей нет. |
| R8 | Claude часто выбирает не тот tool / не те параметры | Хороший system prompt, tool descriptions с примерами, few-shot. После Phase 3 — sprint на prompt engineering с evals (golden set 50 команд). |
| R9 | Bills: OpenAI Realtime + Claude usage. На Claude через OAuth — лимиты max-плана | OpenAI Realtime — API-key биллинг, budget cap в settings. Claude через OAuth — упирается в rate-limit max-плана (5h windows). Если упрёмся — fallback на API-key Anthropic временно. |
| R10 | Sync между OpenAI Realtime и Claude Agent SDK на бэкенде | Чёткий state machine: 5 состояний (idle / listening / thinking-quick / thinking-deep-agent / speaking-result). Переходы через события WebSocket. |
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
| D1 | Claude модель для agent SDK | Sonnet 4.6 (быстрее + дешевле). Opus 4.7 через флаг `model: opus` для самых сложных задач |
| D2 | Где живёт agent state | Чат-thread локально в Hive на телефоне + opt-in sync на Taler ID backend. Agent run state — на бэкенде в Postgres (`AgentSession` table — добавляется в Phase 0) |
| D3 | OpenAI Realtime vs альтернативы | Остаётся (уже работает, low latency). Переход на Claude Realtime когда выйдет |
| D4 | Wake-word engine | Picovoice Porcupine (бесплатно для 1 user, on-device). Off by default |
| D5 | Где хранится спек | `~/Downloads/taler_id_mobile/docs/superpowers/specs/` (вместе с кодом) |
| D6 | Целевая аудитория v1 | Дмитрий один. Архитектура configurable — не хардкодим аккаунты, чтобы при желании можно расширить без переписки |
| D7 | Платформа | Android only. iOS не получит этот launcher |
| D8 | Языки | ru + en (как сейчас в Taler ID) |
| D9 | Distribution | Sideload через APK (как сейчас taler-id-dev.apk). Play Store не цель |
| D10 | Claude auth | **OAuth через `claude` CLI на бэкенде** (паттерн taler-monitor). Credentials в `~/.claude/.credentials.json` под dvolkov на DEV-сервере. Биллинг — Claude max-план. API-key не используется. |
| D11 | OpenAI auth | API-key, как сейчас в Taler ID. Хранится в backend `.env`, мобила не знает. |
| D12 | Agent runtime location | NestJS backend через `@anthropic-ai/claude-agent-sdk`. Не Dart, не Termux, не embedded Node. |
| D13 | Phone-side tool dispatch | WebSocket-обратка с backend agent → Flutter (same pattern as existing OpenAI Realtime tools). Bridging endpoint в `AgentGateway`. |

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
- 2026-05-19 — **Major architecture revision (Update Log):**
  - Перешли с API-key auth на **OAuth через Claude Code SDK** (паттерн taler-monitor).
  - Свернули "Dart Claude Agent Loop" — теперь используем `@anthropic-ai/claude-agent-sdk` на NestJS-бэкенде.
  - Сократили "3 LLM-уровня" до **2 LLM-уровней** (OpenAI Realtime голос + Claude Agent SDK на бэке).
  - "Worker agent на сервере через SSH" из исходного спека больше не нужен — backend сам на сервере, у SDK есть встроенный `Bash` tool.
  - Long-running задачи делегируются через built-in `Task` tool (саб-агенты SDK), не через свою CLI-обёртку.
  - Phone-side tools будут реализованы через WebSocket-обратку (паттерн уже работает в Taler ID для OpenAI Realtime).
  - Phase 0 спека и план переписаны под новую архитектуру.
  - Phase 2 (dev management) упростился — большинство dev-задач решаются built-in `Bash` tool, без своего SSH-клиента в Dart.
  - Phase 3 (heavy delegation) почти растворился — стал частью Phase 2 через `Task` tool. Остаётся только UX (progress card, push, controls).

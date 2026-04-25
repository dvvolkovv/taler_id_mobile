# AI Analyst Live Status — Design Spec

**Date:** 2026-04-24
**Scope:** Taler ID — показ прогресса работы AI Аналитика в чате (`AI_ANALYST` conversation type) в реальном времени, плюс удаление неиспользуемого модуля `lib/features/chat/`.
**Deploy target:** только DEV (`89.169.55.217` для бэка, ветка `dev` для мобилки). На PROD — только по явному указанию.

## 1. Цель и пользовательская история

Когда пользователь пишет в AI Аналитика, сейчас он видит молчание 5–60 секунд, потом — сразу финальный ответ. Непонятно: ассистент принял запрос? работает? упал? Нужна живая обратная связь как у ChatGPT / Perplexity — "я принял задачу, думаю, ищу в интернете, читаю файл, готовлю ответ", со стримингом финального текста токен-за-токеном.

**User story:** как пользователь AI Аналитика, я хочу видеть, что именно ассистент делает в данный момент, чтобы понимать, что система работает, и примерно ожидать, когда будет ответ.

**Out of scope (на эту итерацию):**
- Голосовой ассистент (`assistant_screen.dart`) — не трогаем
- `AI_OUTBOUND` чат — не трогаем (там свой typing-механизм)
- Раскрываемые карточки "show reasoning" с детальным логом действий — future work
- Resume-индикатор для юзера, ушедшего из чата во время работы агента — future work

## 2. Архитектурные решения

- **Подход:** Backend = источник истины. Мобилка — тонкий клиент, рендерит готовые локализованные фразы и счётчики
- **Где живут фразы-маппинги:** `src/messenger/ai-analyst-labels.ts` (новый файл) — словарь `toolName → {kind, emoji, ru, en}`
- **UX-модель "D":** live typing-indicator во время работы → сворачивается в компактный "шов" (серая полоса) над финальным сообщением
- **Детализация "B":** человекочитаемые тул-фразы с эмодзи ("🔍 Ищу в интернете…"), без аргументов тулов и без раскрываемого лога
- **Шов "B":** агрегат по типам шагов (`🔍 2 поиска · 📄 3 файла · 💻 4 команды · ⏱ 12 с`), сохраняется в `Message.metadata.steps` в БД, виден в истории при перезаходе
- **Стриминг финального ответа "B":** `analyst_chunk` дельты льются в streaming-бубль токен-за-токеном, typing-индикатор параллельно показывает "✍️ Готовлю ответ…"

## 3. Архитектура и поток событий

```
Mobile (ChatRoomScreen, отправка)
  ↓ текст
Backend: messenger.gateway.ts → _dispatchToAnalyst(userId, convId, text, files)
  │
  ├── emit analyst_status {phase: 'thinking',  emoji:'🤔', label:'Думаю…'}
  │
  ├── POST /chat SSE → Claude Worker (5.101.115.184:3033)
  │   Worker стримит события: {type:'delta', text} | {type:'tool', tool, input} | {type:'result', text}
  │
  ├── на каждом событии Worker:
  │   • tool(name,input)
  │       lbl = refineBashLabel(input) ?? TOOL_LABELS[name] ?? {kind:'other', …}
  │       counts[lbl.kind]++
  │       emit analyst_status {phase:'tool', emoji:lbl.emoji, label:lbl[lang], toolKind:lbl.kind}
  │   • delta(text)  (первый)
  │       emit analyst_status {phase:'preparing', emoji:'✍️', label:'Готовлю ответ…'}
  │   • delta(text)  (каждый)
  │       emit analyst_chunk {text}
  │       finalText += text
  │
  ├── на ошибке / таймауте
  │       emit analyst_status {phase:'error', emoji:'❌', label:'Ошибка', detail}
  │       сохранить системное сообщение с текстом ошибки, metadata.steps=[]
  │
  └── на завершении
        steps = [{kind:'search', count:2}, {kind:'file', count:3}, …]
        msg = prisma.message.create({
          conversationId, senderId: BOT_ID, isSystem: true,
          content: finalText,
          metadata: { steps, durationMs },
        })
        emit new_message {msg}
        emit analyst_seam {conversationId, messageId: msg.id, steps, durationMs}

Mobile:
  analyst_status    → обновить live typing-indicator (или скрыть на phase=done отсутствует → по new_message)
  analyst_chunk     → добавить токены в streaming-бубль (создать при первом чанке)
  analyst_seam      → нарисовать шов над финальным ботом-сообщением
  new_message       → заменить streaming-бубль реальным Message (с metadata.steps для истории)
```

## 4. Backend

### 4.1. Новый файл `src/messenger/ai-analyst-labels.ts`

```ts
export type ToolKind = 'search' | 'file' | 'cmd' | 'image' | 'other';

interface ToolLabel {
  kind: ToolKind;
  emoji: string;
  ru: string;
  en: string;
}

export const TOOL_LABELS: Record<string, ToolLabel> = {
  WebSearch: { kind: 'search', emoji: '🔍', ru: 'Ищу в интернете…',    en: 'Searching the web…' },
  WebFetch:  { kind: 'search', emoji: '🌐', ru: 'Открываю страницу…',  en: 'Fetching page…' },
  Read:      { kind: 'file',   emoji: '📄', ru: 'Читаю файл…',         en: 'Reading file…' },
  Write:     { kind: 'file',   emoji: '📝', ru: 'Записываю файл…',     en: 'Writing file…' },
  Edit:      { kind: 'file',   emoji: '✏️', ru: 'Редактирую файл…',    en: 'Editing file…' },
  Glob:      { kind: 'file',   emoji: '🗂️', ru: 'Ищу файлы…',          en: 'Listing files…' },
  Grep:      { kind: 'file',   emoji: '🔎', ru: 'Ищу по содержимому…', en: 'Searching contents…' },
  Bash:      { kind: 'cmd',    emoji: '💻', ru: 'Выполняю команду…',   en: 'Running command…' },
};

export const PHASE_LABELS = {
  thinking:  { emoji: '🤔', ru: 'Думаю…',         en: 'Thinking…' },
  preparing: { emoji: '✍️', ru: 'Готовлю ответ…', en: 'Preparing answer…' },
  error:     { emoji: '❌', ru: 'Ошибка',         en: 'Error' },
};

export function refineBashLabel(input: string): ToolLabel | null {
  if (/generate_image\.sh/.test(input)) {
    return { kind: 'image', emoji: '🎨', ru: 'Генерирую картинку…', en: 'Generating image…' };
  }
  return null;
}

export const UNKNOWN_TOOL_LABEL: ToolLabel = {
  kind: 'other', emoji: '⚙️', ru: 'Работаю…', en: 'Working…',
};
```

### 4.2. Изменения в `src/messenger/messenger.gateway.ts` → `_dispatchToAnalyst()`

Рефакторинг: существующие events `analyst_thinking` / `analyst_chunk` / `analyst_tool` / `analyst_done` **удаляются**, заменяются на унифицированные `analyst_status` / `analyst_chunk` / `analyst_seam` + стандартный `new_message`.

Псевдокод:

```ts
private async _dispatchToAnalyst(userId, conversationId, content, files) {
  const lang = await this.getUserLang(userId);   // 'ru' | 'en'
  const started = Date.now();
  const counts: Record<ToolKind, number> = { search:0, file:0, cmd:0, image:0, other:0 };
  let finalText = '';
  let preparingEmitted = false;

  this.emitPhaseStatus(userId, conversationId, 'thinking', lang);

  try {
    await this.aiAnalyst.submitTask({
      userId, conversationId, content, files,
      onTool: (name, input) => {
        const lbl = refineBashLabel(input) ?? TOOL_LABELS[name] ?? UNKNOWN_TOOL_LABEL;
        counts[lbl.kind]++;
        this.emitToolStatus(userId, conversationId, lbl, lang);
      },
      onChunk: (text) => {
        if (!preparingEmitted) {
          this.emitPhaseStatus(userId, conversationId, 'preparing', lang);
          preparingEmitted = true;
        }
        finalText += text;
        this.emitToUser(userId, 'analyst_chunk', { conversationId, text });
      },
    });
  } catch (err) {
    this.emitPhaseStatus(userId, conversationId, 'error', lang, err.message);
    const errMsg = await this.prisma.message.create({ data: {
      conversationId, senderId: BOT_ID, isSystem: true,
      content: `❌ Ошибка анализа: ${err.message}`,
      metadata: { steps: [], durationMs: Date.now() - started, error: true },
    }});
    this.emitToUser(userId, 'new_message', errMsg);
    return;
  }

  const durationMs = Date.now() - started;
  const steps = Object.entries(counts).filter(([_,v]) => v>0).map(([kind,count]) => ({ kind, count }));
  const msg = await this.prisma.message.create({ data: {
    conversationId, senderId: BOT_ID, isSystem: true,
    content: finalText,
    metadata: { steps, durationMs },
  }});
  this.emitToUser(userId, 'new_message', msg);
  this.emitToUser(userId, 'analyst_seam', { conversationId, messageId: msg.id, steps, durationMs });
}
```

### 4.3. Обновлённый сервис `AiAnalystService`

Убедиться, что `submitTask()` прокидывает в callbacks именно `name + input` для тула (не только текст). Если сейчас там `{tool, input}` — уже ок.

### 4.4. Формат Socket.IO events (исходящие)

| Event | Payload | Когда |
|---|---|---|
| `analyst_status` | `{conversationId, phase: 'thinking'\|'tool'\|'preparing'\|'error', emoji, label, toolKind?, detail?}` | При смене фазы / каждом tool-use |
| `analyst_chunk` | `{conversationId, text}` | На каждую text-дельту от Worker |
| `analyst_seam` | `{conversationId, messageId, steps:[{kind,count}], durationMs}` | Сразу после сохранения финального сообщения |
| `new_message` | стандартный `Message` с `metadata:{steps, durationMs}` | В конце потока |

Удаляются: `analyst_thinking`, `analyst_tool`, `analyst_done`.

### 4.5. Prisma

```prisma
model Message {
  // ... существующие поля
  metadata Json?
}
```

Проверить, есть ли уже поле. Если есть — использовать его. Если нет — миграция `add_message_metadata`, безопасная (nullable column).

## 5. Мобилка

### 5.1. Datasource `messenger_remote_datasource.dart`

Подписки на три новых события, выставляем три Stream'а:

```dart
Stream<AnalystStatus> get analystStatus;
Stream<AnalystChunk>  get analystChunk;
Stream<AnalystSeam>   get analystSeam;
```

### 5.2. Freezed-модели (`lib/features/messenger/domain/entities/`)

```dart
@freezed
class AnalystStatus with _$AnalystStatus {
  const factory AnalystStatus({
    required String conversationId,
    required String phase,    // 'thinking' | 'tool' | 'preparing' | 'error'
    required String emoji,
    required String label,
    String? toolKind,
    String? detail,
  }) = _AnalystStatus;
}

@freezed
class AnalystChunk with _$AnalystChunk {
  const factory AnalystChunk({
    required String conversationId,
    required String text,
  }) = _AnalystChunk;
}

@freezed
class SeamStep with _$SeamStep {
  const factory SeamStep({required String kind, required int count}) = _SeamStep;
}

@freezed
class AnalystSeam with _$AnalystSeam {
  const factory AnalystSeam({
    required String conversationId,
    required String messageId,
    required List<SeamStep> steps,
    required int durationMs,
  }) = _AnalystSeam;
}
```

Плюс: модель `Message` — добавить поле `Map<String,dynamic>? metadata`.

### 5.3. Состояние в BLoC/Cubit чата

В существующем Bloc'е, что держит state для `chat_room_screen`, добавить:

```dart
class AnalystActivity {
  AnalystStatus? currentStatus;       // null ⇒ не активен
  String pendingMessageText = '';     // накопительный буфер
  bool streaming = false;             // true после первого chunk, false после new_message
}
Map<String, AnalystActivity> analystByConversation;
```

**Переходы:**
- `analyst_status` → `currentStatus = status` (если `phase='error'` → оставляем на 3 сек, затем сбрасываем)
- `analyst_chunk` → если `!streaming`: завести streaming-бубль; добавить text в `pendingMessageText`
- `analyst_seam` → сохранить `steps` в map для данного `messageId` (прокинуть в UI ещё до прихода `new_message`)
- `new_message` (type=AI_ANALYST, system=true) → применить реальное сообщение (с `metadata.steps` из payload), сбросить `currentStatus` и `pendingMessageText`, `streaming=false`

### 5.4. UI-виджеты (`lib/features/messenger/presentation/widgets/`)

**`AnalystTypingIndicator`** — в низу списка сообщений (между последним сообщением и полем ввода):
- Серый фон `AppColors.surfaceVariant`, скруглённый, padding 8×12
- Слева: эмодзи (24×24), справа: текст label (14sp, 70% opacity), затем три мигающих точки
- Анимация точек: `AnimatedBuilder` с `TickerProviderStateMixin`, 600мс период, 3 точки с шагом 200мс

**`AnalystStreamingBubble`** — обычный бот-бубль, но текст инкрементальный + курсор-каретка `|` мигает в конце (500мс). Исчезает, когда на его место приходит финальный `Message`.

**`AnalystSeam`** — компактная серая строка, высота ~24px, показывается **над** бот-сообщением:
- Иконка ⚙️, далее формат `{emoji count unit} · {emoji count unit} · … · ⏱ {seconds}`
- Поддержка ru/en plural через `AppLocalizations`

### 5.5. Рендер в ChatRoomScreen

В списке сообщений:
- Если `conv.type == 'AI_ANALYST'` и `msg.isSystem` и `msg.metadata?['steps']` непуст → обернуть в `Column([AnalystSeam(steps, durationMs), bubble])`
- Если `analystByConversation[convId].streaming == true` → после последнего реального сообщения вставить `AnalystStreamingBubble(pendingMessageText)`
- В footer (перед `TextField`): если `analystByConversation[convId].currentStatus != null` → `AnalystTypingIndicator(status)`

Порядок снизу вверх:
```
[TextField]
[AnalystTypingIndicator]      ← эфемерный, пока активен
[AnalystStreamingBubble]      ← эфемерный, пока идёт streaming
[AnalystSeam]
[Bot final Message]
[User Message]
... история ...
```

### 5.6. Локализация мобилки (`lib/l10n/*.arb`)

Новые ключи для шва (pluralization):
- `analystSeamSearches`, `analystSeamFiles`, `analystSeamCommands`, `analystSeamImages`, `analystSeamOther`
- `analystSeamDuration` — форматирование "12 с" / "12s"

Сами фразы статусов (например "Ищу в интернете…") приходят с бэка готовыми — ARB для них не нужны.

## 6. Удаление неиспользуемого `lib/features/chat/`

Файлы/строки на удаление:
- Директория `lib/features/chat/` — целиком
- `lib/core/di/service_locator.dart` — строка регистрации `ChatBloc`
- `lib/core/router/app_router.dart` — import и маршрут `/chat`
- `l10n/*.arb` — ключи, используемые только в chat (если есть)

**Проверка:** `grep -rn "ChatBloc\|ChatScreen\|features/chat" lib/` → ноль результатов после удаления.

## 7. Ошибки и edge-cases

| Сценарий | Поведение |
|---|---|
| Worker 500 | `analyst_status {phase:'error'}` → клиент показывает `❌ Ошибка` 3 сек → сохраняем системное error-сообщение (как сейчас), `metadata.steps=[]` |
| Timeout > 3 мин без событий | Бэк сам эмитит error-фазу и сохраняет timeout-сообщение |
| Юзер ушёл из чата → вернулся после завершения | Видит финальное сообщение с рендерённым швом из `metadata.steps` |
| Юзер ушёл → вернулся ДО завершения | В первой итерации видит финал без промежуточных статусов (future work: `analyst_resume` event) |
| Два сообщения подряд | Worker обрабатывает последовательно; второй typing-indicator появляется после завершения первого |
| `analyst_chunk` без `preparing` | Защита: автоматически выставляем `preparing` при первом чанке |
| Неизвестный тул от Worker | `kind='other'`, эмодзи `⚙️`, label "Работаю…" |

## 8. Тесты

### Backend (Jest, `taler-id`)

1. **Юнит** — `mapToolToLabel`: все известные тулы, `generate_image.sh → image`, неизвестный → other
2. **Интеграционный** — `_dispatchToAnalyst` с мок-Worker'ом:
   - эмитится правильная последовательность `analyst_status`
   - counts агрегируются верно
   - `Message.metadata.steps` записывается
   - на ошибке — `phase:'error'` + error-сообщение

### E2E (`taler_id_tests`)

3. `npm run test:analyst` расширить: принимать и валидировать `analyst_status` + `analyst_seam`; проверить `metadata.steps` в GET messages

### Flutter

4. Виджет-тест `AnalystTypingIndicator` — меняется label/emoji при новом статусе
5. Виджет-тест `AnalystSeam` — корректный plural ru/en для 1/2/5
6. Виджет-тест `AnalystStreamingBubble` — инкрементальный рост текста
7. Bloc-тест: `analyst_status → analyst_chunk → new_message` — корректные переходы

### Регресс перед деплоем (CLAUDE.md)

- `flutter test` — все юниты зелёные
- `flutter test integration_test/app_test.dart --flavor dev ...` — добавить шаг: открыть AI_ANALYST чат, отправить "привет", дождаться typing-indicator, дождаться финального сообщения со швом
- `npm test` (29 тестов), `npm run test:voice`, `npm run test:assistant`, `npm run test:files`, `npm run test:channels`, `npm run test:billing`, `npm run test:analyst`

## 9. Деплой

1. Бэк → DEV: `ssh dvolkov@89.169.55.217 && cd ~/taler-id && git pull && npm run build && pm2 restart taler-id-dev`
2. Мобилка → ветка `dev` → APK `https://id.taler.tirol/download/taler-id-dev.apk` + iOS dev TestFlight
3. Прогнать полный регресс из CLAUDE.md
4. PROD — **только по явному указанию**

## 10. Критерии готовности

- [ ] Новый AI Analyst запрос показывает typing-indicator в течение всей работы
- [ ] Typing-indicator обновляет текст на каждом тул-use (минимум: Bash, Read, WebSearch)
- [ ] Финальный ответ приходит в streaming-бубле токен-за-токеном
- [ ] После завершения над финальным сообщением виден шов `🔍 N · 📄 N · 💻 N · ⏱ Ns`
- [ ] Перезаход в чат сохраняет шов у исторических AI_ANALYST сообщений, записанных после релиза
- [ ] Ошибка Worker показывает `❌ Ошибка` и сохраняет системное сообщение с текстом
- [ ] `lib/features/chat/` удалён, `grep ChatBloc lib/` пуст
- [ ] Все тесты из CLAUDE.md зелёные на DEV

## 11. Future work (вне этой итерации)

- `analyst_resume` event: клиент при реконнекте получает текущее состояние активного таска
- Раскрываемые шаги (tap на шов → список конкретных действий)
- Показ аргумента тула в live-индикаторе (`🔍 Ищу: «кузовной ремонт BMW X5»`)
- Дублирование фичи в голосовом ассистенте
- Интернационализация тул-фраз в бэке — перенос в JSON/DB, чтобы можно было менять без релиза

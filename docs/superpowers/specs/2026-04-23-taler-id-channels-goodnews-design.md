# Channels end-to-end + «Хорошие новости» bot — design

**Date:** 2026-04-23
**Target env:** DEV only (`https://staging.id.taler.tirol`, backend `dvolkov@89.169.55.217`, mobile branch `dev`)
**Goals:**
1. Починить каналы в мобилке так, чтобы любой пользователь мог найти публичный канал, подписаться, читать его и отписаться; чтобы владельцы канала могли редактировать и удалять.
2. Запустить демонстрационный канал «Хорошие новости» — AI-бот на `dv@5.101.115.184` раз в сутки публикует в него 3 хороших мировых новости про достижения человечества.

---

## 1. Architecture overview

```
Flutter mobile (dev flavor)
 ├── ChannelDirectoryScreen          new
 ├── ChatRoomScreen                  role-aware for CHANNEL
 └── ChannelSettingsScreen           new
        │ HTTPS
        ▼
Taler ID backend (DEV)
  messenger module
  ├── GET    /messenger/channels?q=&limit=&offset=   new
  ├── GET    /messenger/channels/:id                 new
  ├── PATCH  /messenger/channels/:id                 new
  ├── DELETE /messenger/channels/:id                 new
  ├── POST   /messenger/channels/:id/post            new — REST post-into-channel (для бота)
  ├── POST   /messenger/channels                     existing
  ├── POST   /messenger/channels/:id/subscribe       existing, made idempotent
  └── DELETE /messenger/channels/:id/subscribe       existing
        ▲
        │ curl POST /auth/login → JWT
        │ curl POST /messenger/channels/:id/post
        │
dv@5.101.115.184 (cron 06:00 UTC = 09:00 MSK)
  ~/goodnews/run.sh
   └── claude CLI --dangerously-skip-permissions -p "..."
       ├── read memory/identity.md, log.md, strategy.md
       ├── WebSearch (built into claude CLI) — мировые хорошие новости 24h
       ├── dedup по memory/log.md (последние 30 дней)
       ├── compose пост на русском
       ├── curl → Taler ID backend (login + POST message)
       └── append memory/log.md, git commit
```

**Что НЕ меняем:**
- Prisma schema (все нужные поля уже есть: `ConvType.CHANNEL`, `GroupRole.SUBSCRIBER`, `Conversation.{name,description,avatarUrl}`).
- Socket.IO gateway (уже корректно проверяет `assertCanPostInChannel`).

**Деплой-контур:**
- Мобилка коммитится в ветку `dev`, APK собирается на `138.124.61.221`, раздаётся по `https://id.taler.tirol/download/taler-id-dev.apk`.
- Бэкенд деплоится только на DEV (89.169.55.217), PM2 процесс `taler-id-dev`.
- Бот живёт только на `dv@5.101.115.184` и пишет только в DEV канал.

---

## 2. Backend changes

### 2.1 Новые эндпоинты

**`GET /messenger/channels`**
- Query: `q` (string, optional), `limit` (default 20, max 50), `offset` (default 0)
- Response: `[{ id, name, description, avatarUrl, subscribersCount, isSubscribed }]`
- Логика:
  - `WHERE Conversation.type = CHANNEL`
  - Если `q` не пустой — `name ILIKE '%q%'`; пустой — без фильтра
  - `subscribersCount = count(ConversationParticipant WHERE role IN (OWNER, ADMIN, SUBSCRIBER))`
  - `isSubscribed = exists(ConversationParticipant WHERE userId = me)`
  - Order: `subscribersCount DESC, createdAt DESC`
- Auth: JWT required.

**`GET /messenger/channels/:id`**
- Response: `{ id, name, description, avatarUrl, subscribersCount, isSubscribed, myRole }`
- `myRole` ∈ `OWNER | ADMIN | SUBSCRIBER | null`
- 404 if not found; 400 if conversation type ≠ CHANNEL.
- Auth: JWT. Не требует membership — любой залогиненный пользователь может посмотреть превью.

**`PATCH /messenger/channels/:id`**
- Body: `{ name?, description?, avatarUrl? }` — все опциональны, передаются только меняющиеся поля
- Guard: участник с `role ∈ {OWNER, ADMIN}`; иначе 403
- Response: обновлённая meta (как `GET /channels/:id`)

**`DELETE /messenger/channels/:id`**
- Guard: `role = OWNER`; иначе 403
- Каскад: `onDelete: Cascade` в Prisma снесёт participants и messages
- Response: `{ ok: true }`

**`POST /messenger/channels/:id/post`**
- Body: `{ content: string }` (max 4000 символов)
- Guard: `role ∈ {OWNER, ADMIN}`; иначе 403 (использовать существующий `assertCanPostInChannel`)
- Вызывает `messenger.service.createMessage(channelId, me.sub, content)`
- Эмитит `new_message` в Socket.IO-room `channelId` — подписчики получат сообщение в реальном времени (как обычное сообщение)
- Response: `{ messageId, createdAt }`
- Мотивация: в мессенджере сейчас сообщения идут только через Socket.IO gateway. Боту из bash/curl проще bash → REST. Мобилка продолжит использовать Socket.IO.

### 2.2 Изменения в существующих методах

**`POST /messenger/channels/:id/subscribe`** — сделать идемпотентным:
- Сейчас бросает `BadRequestException("Already subscribed")` если запись уже есть
- Станет: если `existing` — вернуть `{ ok: true, alreadySubscribed: true }`
- Новая подписка — `{ ok: true, alreadySubscribed: false }`

**`DELETE /messenger/channels/:id/subscribe`** — блокировка OWNER:
- Если `participant.role === OWNER` — 400 `"Owner cannot unsubscribe, delete channel instead"`
- Иначе как сейчас

### 2.3 YAGNI — НЕ делаем
- Флаг `isPublic` на Conversation — все каналы пока публичны.
- Invite-ссылки, slug/username.
- Отдельный `ChannelsController` / `ChannelsModule` — оставляем в messenger-модуле.
- Counter caching (`subscribersCount` считается на лету).
- Optimistic locking для PATCH.

---

## 3. Mobile changes (`lib/features/messenger/`)

### 3.1 ChannelDirectoryScreen (новый)
- Путь: `/dashboard/messenger/channels`
- UI: `SearchBar` (debounce 300ms) + `ListView.builder` карточек.
- Карточка: avatar circle (40×40) + name + 2-line description + "$N подписчиков" + кнопка.
- Кнопка: `Subscribe` (primary) если `!isSubscribed`; `Open` (outlined) если `isSubscribed`.
- Pull-to-refresh.
- Пустой поиск → топ-20 по `subscribersCount`.
- Empty state: иконка `Icons.explore_rounded` + текст «Каналов пока нет».
- Tap на карточку → navigate в `chat_room_screen` по channel id. Если не подписан — composer сам покажет кнопку Subscribe.

### 3.2 ChatRoomScreen (правки)
При `conv.type == 'CHANNEL'`:

**AppBar:**
- title = `channel.name`
- subtitle = `"$subscribersCount подписчиков"` (вместо online/typing)
- actions `PopupMenuButton`:
  - `myRole ∈ {OWNER, ADMIN}`:
    - «Настройки канала» → `/dashboard/messenger/chat/:id/channel-settings`
    - «Поделиться ссылкой» → copy `talerid://channel/:id` + share sheet
    - «Удалить канал» (только OWNER) → confirm → `DELETE` → back
  - `myRole === SUBSCRIBER`:
    - «Поделиться ссылкой»
    - «Отписаться» → confirm → `DELETE /subscribe` → back
  - `myRole === null` (превью не-participant):
    - «Поделиться ссылкой»

**Composer (bottom bar):**
- `OWNER | ADMIN` → обычный composer
- `SUBSCRIBER` → row: `"Вы подписаны на канал"` + outline-кнопка «Отписаться»
- `null` → primary-кнопка «Подписаться» на всю ширину

**Message bubbles:**
- Для канала скрываем аватары отправителей (всё равно все от ADMIN/OWNER) — сообщения выглядят как "посты канала".

### 3.3 ChannelSettingsScreen (новый)
- Путь: `/dashboard/messenger/chat/:id/channel-settings`
- Guard: router проверяет `myRole ∈ {OWNER, ADMIN}`, иначе redirect на `/dashboard/messenger`
- Поля:
  - `name` — `TextFormField`, required, max 64 символа
  - `description` — multiline `TextFormField`, max 300
  - `avatar` — circle-avatar tap → image picker → upload через существующий аватар-upload endpoint (reuse `/upload`)
- Кнопка `Сохранить` → `PATCH /messenger/channels/:id`, back на success, snackbar на error
- Кнопка `Удалить канал` (красная, только `myRole == OWNER`) → `AlertDialog` confirm → `DELETE` → redirect на `/dashboard/messenger`

### 3.4 Entry point
В `conversations_screen._showNewChatSheet`:
- Добавить 4-й ListTile «Найти канал» под «Создать канал»:
  - Иконка `Icons.explore_rounded`, цвет `Color(0xFFF59E0B)`
  - onTap → `context.push('/dashboard/messenger/channels')`

### 3.5 Data layer
`lib/features/messenger/data/datasources/messenger_remote_datasource.dart`:
- `Future<List<ChannelSummary>> searchChannels({String? q, int limit = 20, int offset = 0})`
- `Future<ChannelDetails> getChannelDetails(String id)`
- `Future<ChannelDetails> updateChannel(String id, {String? name, String? description, String? avatarUrl})`
- `Future<void> deleteChannel(String id)`

`ConversationEntity` — добавить опциональные поля (только для CHANNEL):
- `int? subscribersCount`
- `String? myRole` (`'OWNER' | 'ADMIN' | 'SUBSCRIBER' | null`)
- `bool? isSubscribed`

### 3.6 Локализация
Новые ключи в `lib/l10n/app_ru.arb` и `app_en.arb`:

| Ключ | RU | EN |
|---|---|---|
| `channelsDiscover` | Найти канал | Find channel |
| `channelsSearchHint` | Поиск каналов | Search channels |
| `channelsSubscribers` | подписчиков | subscribers |
| `channelsSubscribe` | Подписаться | Subscribe |
| `channelsUnsubscribe` | Отписаться | Unsubscribe |
| `channelsSubscribedLabel` | Вы подписаны на канал | You are subscribed |
| `channelsSettings` | Настройки канала | Channel settings |
| `channelsDelete` | Удалить канал | Delete channel |
| `channelsDeleteConfirm` | Удалить канал без возможности восстановления? | Delete channel permanently? |
| `channelsEmpty` | Каналов пока нет | No channels yet |
| `channelsOpen` | Открыть | Open |
| `channelsNameLabel` | Название | Name |
| `channelsDescriptionLabel` | Описание | Description |

### 3.7 YAGNI — НЕ делаем
- Отдельный `ChannelBloc` — переиспользуем `MessengerBloc` / `ChatBloc`
- Отдельный `channel_room_screen` — conditional-рендер в `chat_room_screen`
- Preview-экран до подписки — tap в Directory → сразу `chat_room_screen`, composer сам покажет Subscribe
- Deep-link handler для `talerid://channel/:id` — на MVP копируем строку, парсинг добавим позже если понадобится

---

## 4. «Хорошие новости» bot на `dv@5.101.115.184`

### 4.1 Структура директории
```
~/goodnews/
├── .env                 # TALER_BASE_URL, TALER_BOT_EMAIL, TALER_BOT_PASSWORD, TALER_CHANNEL_ID
├── run.sh               # cron entry, chmod +x
├── CLAUDE.md            # инструкции агенту (как писать, куда постить, чего избегать)
├── setup.sh             # one-time: регистрация бота, создание канала, запись .env
└── workspace/
    ├── .git/            # коммиты памяти агента
    ├── .gitignore       # logs/
    ├── memory/
    │   ├── identity.md  # кто я, какова цель
    │   ├── strategy.md  # источники, темы, запрещённые темы
    │   └── log.md       # append: YYYY-MM-DD | <заголовок>
    └── logs/
        ├── wake-*.log   # per-run claude output
        └── cron.log     # cron stdout+stderr
```

### 4.2 `.env` (chmod 600)
```
TALER_BASE_URL=https://staging.id.taler.tirol
TALER_BOT_EMAIL=goodnews-bot@taler-test.com
TALER_BOT_PASSWORD=<generated by setup.sh>
TALER_CHANNEL_ID=<uuid, заполняет setup.sh>
```

### 4.3 `run.sh` (паттерн `spirit/run.sh`)
```bash
#!/usr/bin/env bash
set -u
cd "$(dirname "$0")/workspace" || exit 1
mkdir -p logs
TS=$(date -u +%Y-%m-%dT%H:%M:%SZ)
LOG="logs/wake-${TS}.log"
set -a; source ../.env; set +a

# lock чтобы пересекающиеся cron-запуски не пересекались
exec 9>/tmp/goodnews.lock
flock -n 9 || { echo "[${TS}] another instance running, skip" >> logs/wake.log; exit 0; }

PROMPT="Ты проснулся. Прочитай CLAUDE.md, затем memory/identity.md, memory/strategy.md, memory/log.md. Найди через WebSearch хорошие новости про достижения человечества за последние 24 часа, отфильтруй по log.md, опубликуй в канал, обнови log.md, сделай git commit. Текущее UTC время: ${TS}"

echo "[${TS}] waking goodnews" | tee -a logs/wake.log
claude --dangerously-skip-permissions -p "$PROMPT" 2>&1 | tee "$LOG"
EXIT=${PIPESTATUS[0]}
echo "[${TS}] finished exit=${EXIT}" | tee -a logs/wake.log
exit $EXIT
```

### 4.4 `CLAUDE.md` — brief агенту
- Роль: бот «Хорошие новости» в Taler ID. Публикуешь в один конкретный канал.
- Частота: 1 раз в сутки. 3 новости за пост (если нашёл меньше — публикуешь сколько есть, но минимум 1).
- Темы: наука, медицина, технологии, космос, экология, образование, культура, спасение жизней, прорывы.
- **Избегать:** политика, войны/конфликты, стартап-раунды без продукта, крипто-спекуляции, селебрити-сплетни, маркетинговые анонсы.
- Источники (для WebSearch запросов): Nature, Science, BBC, NYT, WaPo, Guardian, Reuters, Positive.News, Good News Network, Reasons to be Cheerful.
- Язык поста: русский (заголовки, описание). Оригинальная ссылка — как есть.
- Формат поста:
  ```
  🌍 Хорошие новости — <дата DD.MM.YYYY>

  1. <эмодзи по теме> <заголовок>
  <2-3 предложения описания>
  🔗 <url>

  2. ...

  3. ...
  ```
- Протокол публикации (bash + curl, переменные из env):
  1. `TOKEN=$(curl -s -X POST "$TALER_BASE_URL/auth/login" -H "Content-Type: application/json" -d "{\"email\":\"$TALER_BOT_EMAIL\",\"password\":\"$TALER_BOT_PASSWORD\"}" | jq -r .accessToken)`
  2. `curl -s -X POST "$TALER_BASE_URL/messenger/channels/$TALER_CHANNEL_ID/post" -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" -d "{\"content\":\"<пост>\"}"`
  3. Статус-код ≥ 400 → не обновлять log.md, exit 1, подробности в wake-log.
- Дедуп:
  - Читать `memory/log.md`, брать строки за последние 30 дней
  - Для каждой кандидатной новости: если заголовок имеет ≥50% пересечения ключевых слов (длинных >4 символов) с любой записью в log — пропустить
  - Если все 3+ кандидата — дубли, попробовать другой WebSearch-запрос
  - Если и после этого только дубли — не публиковать, exit 0, записать «all dupes» в wake-log
- После успеха:
  - Append в `memory/log.md`: по одной строке `YYYY-MM-DD | <заголовок>` для каждой опубликованной новости
  - `cd workspace && git add -A && git commit -m "post YYYY-MM-DD"`

### 4.5 `setup.sh` — one-time bootstrap
```bash
#!/usr/bin/env bash
# Запустить один раз вручную. Идемпотентно: если бот уже создан — не падает, читает ID.
# 1. Если .env пустой: генерит пароль (16 символов), сохраняет
# 2. POST /auth/register с name="Хорошие новости"
#    - Если 409 (уже существует) — POST /auth/login, использовать accessToken
# 3. GET /messenger/conversations — ищет канал по имени "Хорошие новости" среди CHANNEL
#    - Если нашёл — сохранить id в .env
#    - Иначе POST /messenger/channels body {name: "Хорошие новости", description: "Достижения человечества — раз в день"}
# 4. Инициализировать workspace/: git init, скопировать шаблон CLAUDE.md/memory/*
# 5. Chmod 600 .env
# 6. Вывести id канала и подсказку по cron
```

### 4.6 Cron
```
0 6 * * * /home/dv/goodnews/run.sh >> /home/dv/goodnews/workspace/logs/cron.log 2>&1 # goodnews-daily
```
06:00 UTC = 09:00 MSK. Добавляется **вручную** через `crontab -e` после успешного прохождения ручного теста (см. testing plan).

### 4.7 Безопасность
- `~/goodnews/.env` — chmod 600, владелец dv
- `.env` НЕ коммитится в workspace git (живёт уровнем выше `workspace/`)
- `workspace/.gitignore`: `logs/`
- Пароль бота создаётся один раз в `setup.sh`, нигде больше не печатается

### 4.8 YAGNI — НЕ делаем
- Никакого Telegram-моста / внешних нотификаций
- Никаких retry-попыток на уровне run.sh — пропущенный день лучше спама
- Отдельного health endpoint — cron.log достаточно
- Ротации логов (crontab сам не заполнит диск в ближайший год)

---

## 5. Error handling & edge cases

### Backend

| Ситуация | Поведение |
|---|---|
| `GET /channels?q=` пустой | топ-20 по subscribersCount |
| `GET /channels/:id` — не найден | 404 |
| `GET /channels/:id` — это не CHANNEL | 400 `"Not a channel"` |
| `PATCH/DELETE` без OWNER/ADMIN | 403 |
| `DELETE` OWNER-ом | cascade через Prisma onDelete |
| `subscribe` дубль | `{ ok: true, alreadySubscribed: true }` |
| `unsubscribe` OWNER | 400 `"Owner cannot unsubscribe, delete channel instead"` |
| `POST /messages` от SUBSCRIBER | 403 (existing `assertCanPostInChannel`) |

### Mobile

| Ситуация | Поведение |
|---|---|
| Сеть упала на Subscribe | snackbar error + retry; state не меняется |
| Канал удалён, пользователь внутри | redirect на `/dashboard/messenger` + snackbar |
| PATCH concurrent edit | last-write-wins (YAGNI для MVP) |
| Avatar upload fail | inline error, старый avatar остаётся |
| `myRole == null` внутри CHANNEL | composer показывает Subscribe, меню минимально |

### Good News bot

| Ситуация | Поведение |
|---|---|
| `/auth/login` fail | log + exit 1; следующий cron попробует |
| `POST /messages` 403 | log + exit 1; чинить руками (бот потерял роль) |
| WebSearch пусто | попробовать 2-3 разных запроса; если и тогда пусто — exit 0 без публикации |
| Все дубли | exit 0, записать «all dupes» |
| <3 валидных | публикуем что есть (≥1) |
| Параллельный cron-запуск | `flock` пропускает второй |
| `log.md` разросся | агент читает только последние 30 дней; старое не чистим (git history) |
| Бот-юзер забанен на DEV | 401 на login, в логах видно, правим руками |

---

## 6. Testing plan

### 6.1 Новые API smoke-тесты — `~/Downloads/taler_id_tests/test_channels.js`
`npm run test:channels`, 13 тестов:
1. user1: `POST /channels` name="Test Channel" → 200, capture id
2. user2: `GET /channels` → канал в списке, `subscribersCount=1`, `isSubscribed=false`
3. user2: `GET /channels?q=Test` → найден
4. user2: `GET /channels?q=XXXYYY` → пусто
5. user2: `GET /channels/:id` → meta; `myRole=null`; user1: `myRole=OWNER`
6. user2: `POST /channels/:id/subscribe` → ok, `alreadySubscribed=false`
7. user2: повторный subscribe → `alreadySubscribed=true`
8. user2: `POST /channels/:id/post` → 403 (не ADMIN)
9. user1: `POST /channels/:id/post` → 200; user2: `GET /conversations/:id/messages` видит сообщение
10. user2: `PATCH /channels/:id` → 403
11. user1: `PATCH /channels/:id` name="Renamed" → 200
12. user2: `DELETE /channels/:id` → 403
13. user1: `DELETE /channels/:id` → 200; `GET /channels/:id` → 404

Добавить в `CLAUDE.md` раздел «ОБЯЗАТЕЛЬНЫЕ ТЕСТЫ ПЕРЕД ДЕПЛОЕМ».

### 6.2 Flutter unit tests
`flutter test` — проверить, что ничего не сломалось в `messenger_remote_datasource` и `ConversationEntity`.

### 6.3 Integration UI test (эмулятор)
Добавить в `integration_test/app_test.dart` новую секцию Channels:
- Messenger → `+` → «Найти канал»
- Directory: поиск → tap карточки → ChatRoom
- «Подписаться» → composer → «Вы подписаны»
- Меню → «Отписаться» → back, не в списке «Каналы»
- Создать канал (OWNER) → Directory → найти → открыть → composer виден
- Меню → «Настройки канала» → сменить description → save
- Меню → «Удалить канал» → confirm → back, нет в списке

### 6.4 Good News bot — ручной тест
1. `ssh dv@5.101.115.184`
2. `~/goodnews/setup.sh` — создать бота, канал, заполнить `.env`
3. `~/goodnews/run.sh` — вручную, **без cron**
4. Проверить `~/goodnews/workspace/logs/wake-*.log`
5. Проверить пост через API:
   `curl -H "Authorization: Bearer <jwt>" "https://staging.id.taler.tirol/messenger/conversations/$TALER_CHANNEL_ID/messages" | jq`
6. Проверить `memory/log.md` — новые записи
7. Проверить `cd workspace && git log` — есть коммит
8. На Android-эмуляторе: найти канал в Directory, подписаться, увидеть пост
9. **Только после этого** — добавить cron

### 6.5 End-to-end на двух эмуляторах
- user1 создаёт канал, user2 находит и подписывается
- user1 постит → user2 видит
- user1 редактирует description → user2 видит новый
- user2 отписывается → канал исчезает из его списка

### 6.6 Правило деплоя (из CLAUDE.md)
- Мобилка: ветка `dev`, APK собирается на PROD-сервере, но для dev-flavor (раздаётся по `taler-id-dev.apk`)
- Бэкенд: только DEV (`89.169.55.217`, PM2 `taler-id-dev`)
- PROD не трогаем, пока явно не попросят
- Перед деплоем: все тесты из CLAUDE.md раздела «ОБЯЗАТЕЛЬНЫЕ ТЕСТЫ» должны быть зелёными + новый `npm run test:channels`

---

## 7. Out of scope (для будущих итераций)

- Приватные каналы с invite-ссылками
- Реакции/комментарии под постами канала
- Telegram-мост
- Per-user клонирование голоса в AI-twin (упомянуто в CLAUDE.md Phase 5)
- Notifications при новом посте в канале (FCM) — если потребуется отдельно
- Веб-версия каталога каналов

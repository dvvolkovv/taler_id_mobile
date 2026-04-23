# Channels end-to-end + Good News bot — implementation plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Полный флоу каналов в Taler ID мобилке (discovery/subscribe/role-aware UX/settings) + backend endpoints + демо-канал «Хорошие новости» с ботом-автопостером раз в сутки. Всё только на DEV.

**Architecture:** NestJS backend в `~/taler-id` на `dvolkov@89.169.55.217` (PM2 `taler-id-dev`) + Flutter мобилка на ветке `dev` + Claude-CLI-агент на `dv@5.101.115.184` с cron-расписанием.

**Tech Stack:** NestJS/Prisma/PostgreSQL, Flutter/BLoC/go_router/dio, Claude CLI с WebSearch, curl+jq, bash, cron.

**Spec:** `docs/superpowers/specs/2026-04-23-taler-id-channels-goodnews-design.md`

**Test credentials (из CLAUDE.md):**
- User1: `integration_test@taler-test.com` / `IntegrationTest123!`
- User2: `integration_test_2@taler-test.com` / `IntegrationTest123!`

---

## Phase 1 — Backend endpoints + idempotent subscribe

### Task 1.1: API smoke test scaffold (test first)

**Files:**
- Create: `~/Downloads/taler_id_tests/channels_test.ts`
- Modify: `~/Downloads/taler_id_tests/package.json` — add scripts

- [ ] **Step 1.1.1: Создать файл `~/Downloads/taler_id_tests/channels_test.ts`:**

```typescript
import axios, { AxiosError } from 'axios';

const BASE_URL = process.env.BASE_URL ?? 'https://staging.id.taler.tirol';
const USER1 = { email: 'integration_test@taler-test.com', password: 'IntegrationTest123!' };
const USER2 = { email: 'integration_test_2@taler-test.com', password: 'IntegrationTest123!' };

const http = axios.create({ baseURL: BASE_URL, validateStatus: () => true });

async function login(creds: { email: string; password: string }): Promise<string> {
  const res = await http.post('/auth/login', creds);
  if (res.status !== 200) throw new Error(`login ${res.status}: ${JSON.stringify(res.data)}`);
  return res.data.accessToken as string;
}

function auth(token: string) { return { headers: { Authorization: `Bearer ${token}` } }; }

let failed = 0;
let passed = 0;
function check(name: string, cond: boolean, info?: unknown) {
  if (cond) { console.log(`  ✓ ${name}`); passed++; }
  else { console.log(`  ✗ ${name}`, info ?? ''); failed++; }
}

async function main() {
  const t1 = await login(USER1);
  const t2 = await login(USER2);
  console.log('Logged in both users');

  // 1. user1 creates channel
  const createRes = await http.post('/messenger/channels',
    { name: `TestCh ${Date.now()}`, description: 'smoke' }, auth(t1));
  check('1. POST /channels → 200/201', createRes.status === 200 || createRes.status === 201, createRes.data);
  const channelId = createRes.data?.id;
  check('1b. channel id returned', typeof channelId === 'string');

  // 2. user2 lists channels
  const listRes = await http.get('/messenger/channels', auth(t2));
  check('2. GET /channels → 200', listRes.status === 200);
  const found = (listRes.data as any[]).find(c => c.id === channelId);
  check('2b. new channel appears in list', !!found);
  check('2c. subscribersCount === 1', found?.subscribersCount === 1);
  check('2d. isSubscribed === false for user2', found?.isSubscribed === false);

  // 3. search by name
  const name = createRes.data.name as string;
  const searchRes = await http.get(`/messenger/channels?q=${encodeURIComponent(name.slice(0, 4))}`, auth(t2));
  check('3. GET /channels?q= → found', (searchRes.data as any[]).some(c => c.id === channelId));

  // 4. search miss
  const missRes = await http.get('/messenger/channels?q=__nothing_XXYY__', auth(t2));
  check('4. GET /channels?q=miss → empty', Array.isArray(missRes.data) && (missRes.data as any[]).length === 0);

  // 5. GET /channels/:id details
  const detailsU2 = await http.get(`/messenger/channels/${channelId}`, auth(t2));
  check('5. GET /channels/:id (user2) → 200', detailsU2.status === 200);
  check('5b. myRole null for non-participant', detailsU2.data.myRole === null);
  const detailsU1 = await http.get(`/messenger/channels/${channelId}`, auth(t1));
  check('5c. myRole OWNER for creator', detailsU1.data.myRole === 'OWNER');

  // 6. subscribe
  const sub1 = await http.post(`/messenger/channels/${channelId}/subscribe`, {}, auth(t2));
  check('6. subscribe → 200/201', sub1.status === 200 || sub1.status === 201);
  check('6b. alreadySubscribed=false on first call', sub1.data?.alreadySubscribed === false);

  // 7. idempotent subscribe
  const sub2 = await http.post(`/messenger/channels/${channelId}/subscribe`, {}, auth(t2));
  check('7. repeat subscribe → alreadySubscribed=true', sub2.data?.alreadySubscribed === true);

  // 8. user2 can't post
  const postU2 = await http.post(`/messenger/channels/${channelId}/post`,
    { content: 'hi from subscriber' }, auth(t2));
  check('8. subscriber post → 403', postU2.status === 403);

  // 9. user1 posts, user2 sees it via GET messages
  const postU1 = await http.post(`/messenger/channels/${channelId}/post`,
    { content: 'hello world' }, auth(t1));
  check('9. OWNER post → 200/201', postU1.status === 200 || postU1.status === 201);
  const msgs = await http.get(`/messenger/conversations/${channelId}/messages`, auth(t2));
  check('9b. user2 GET messages sees post', Array.isArray(msgs.data.messages) &&
    msgs.data.messages.some((m: any) => m.content === 'hello world'));

  // 10. user2 PATCH forbidden
  const patchU2 = await http.patch(`/messenger/channels/${channelId}`,
    { name: 'hacked' }, auth(t2));
  check('10. subscriber PATCH → 403', patchU2.status === 403);

  // 11. user1 PATCH ok
  const patchU1 = await http.patch(`/messenger/channels/${channelId}`,
    { name: 'Renamed Test' }, auth(t1));
  check('11. OWNER PATCH → 200', patchU1.status === 200);
  check('11b. name changed', patchU1.data?.name === 'Renamed Test');

  // 12. user2 DELETE forbidden
  const delU2 = await http.delete(`/messenger/channels/${channelId}`, auth(t2));
  check('12. subscriber DELETE → 403', delU2.status === 403);

  // 13. user1 DELETE ok + GET 404
  const delU1 = await http.delete(`/messenger/channels/${channelId}`, auth(t1));
  check('13. OWNER DELETE → 200', delU1.status === 200);
  const gone = await http.get(`/messenger/channels/${channelId}`, auth(t1));
  check('13b. GET deleted channel → 404', gone.status === 404);

  console.log(`\n${passed} passed, ${failed} failed`);
  process.exit(failed ? 1 : 0);
}

main().catch(e => { console.error(e); process.exit(1); });
```

- [ ] **Step 1.1.2: Добавить скрипты в `package.json`:**

```
"test:channels": "BASE_URL=https://staging.id.taler.tirol npx ts-node channels_test.ts",
"test:channels:prod": "BASE_URL=https://id.taler.tirol npx ts-node channels_test.ts",
```

Вставить эти две строки в объект `scripts` после `"test:mesh:prod": ...`.

- [ ] **Step 1.1.3: Проверить, что axios установлен; если нет — добавить:**

```bash
cd ~/Downloads/taler_id_tests && grep '"axios"' package.json || npm install axios
```

- [ ] **Step 1.1.4: Запустить тест (ожидаем FAIL — эндпоинтов ещё нет):**

```bash
cd ~/Downloads/taler_id_tests && npm run test:channels
```

Ожидаемо: тесты 2-13 упадут (эндпоинтов нет).

- [ ] **Step 1.1.5: Commit**

```bash
cd ~/Downloads/taler_id_tests && git add channels_test.ts package.json package-lock.json && git commit -m "test: add channels smoke suite (fails pending backend)"
```

### Task 1.2: Idempotent subscribe + OWNER-safe unsubscribe (backend)

**Files:**
- Modify (на `dvolkov@89.169.55.217`): `~/taler-id/src/messenger/messenger.service.ts:714-734`

- [ ] **Step 1.2.1: SSH и обновить код:**

```bash
ssh dvolkov@89.169.55.217 "cd ~/taler-id && git checkout dev 2>/dev/null; git pull origin dev"
```

Если ветка `dev` ещё не создана на сервере — сначала на локалке: `cd ~/taler-id-local || git clone git@github.com:dvvolkovv/taler_id.git ~/taler-id-local`. Бэкенд-репозиторий работает напрямую на сервере (см. CLAUDE.md). Если `dev` не существует, создать: `ssh dvolkov@89.169.55.217 "cd ~/taler-id && git checkout -b dev && git push -u origin dev"`.

- [ ] **Step 1.2.2: Заменить `subscribeToChannel` (локально через scp или на сервере через nano) на идемпотентный:**

Найти блок, начинающийся с `async subscribeToChannel(channelId: string, userId: string) {` в `src/messenger/messenger.service.ts` и заменить на:

```typescript
  async subscribeToChannel(channelId: string, userId: string) {
    const conv = await this._getConversationOrThrow(channelId);
    if (conv.type !== "CHANNEL") throw new BadRequestException("Not a channel");
    const existing = await this.prisma.conversationParticipant.findUnique({
      where: { conversationId_userId: { conversationId: channelId, userId } },
    });
    if (existing) return { ok: true, alreadySubscribed: true };
    await this.prisma.conversationParticipant.create({
      data: { conversationId: channelId, userId, role: "SUBSCRIBER" },
    });
    return { ok: true, alreadySubscribed: false };
  }
```

- [ ] **Step 1.2.3: Заменить `unsubscribeFromChannel` — блок OWNER:**

```typescript
  async unsubscribeFromChannel(channelId: string, userId: string) {
    const conv = await this._getConversationOrThrow(channelId);
    if (conv.type !== "CHANNEL") throw new BadRequestException("Not a channel");
    const existing = await this.prisma.conversationParticipant.findUnique({
      where: { conversationId_userId: { conversationId: channelId, userId } },
    });
    if (!existing) throw new BadRequestException("Not subscribed");
    if (existing.role === "OWNER") {
      throw new BadRequestException("Owner cannot unsubscribe, delete channel instead");
    }
    await this.prisma.conversationParticipant.delete({
      where: { conversationId_userId: { conversationId: channelId, userId } },
    });
    return { ok: true };
  }
```

- [ ] **Step 1.2.4: Commit + rebuild + restart PM2:**

```bash
ssh dvolkov@89.169.55.217 "cd ~/taler-id && git add src/messenger/messenger.service.ts && git commit -m 'feat(channels): idempotent subscribe, block OWNER unsubscribe' && git push origin dev && npm run build && pm2 restart taler-id-dev"
```

- [ ] **Step 1.2.5: Smoke check через curl:**

```bash
curl -s -X POST https://staging.id.taler.tirol/auth/login -H 'Content-Type: application/json' -d '{"email":"integration_test@taler-test.com","password":"IntegrationTest123!"}' | jq .accessToken
```

Должен вернуть JWT (строка).

### Task 1.3: `GET /messenger/channels` (list + search)

**Files:**
- Modify: `~/taler-id/src/messenger/messenger.service.ts` (add `listChannels`)
- Modify: `~/taler-id/src/messenger/messenger.controller.ts` (add `GET` handler)

- [ ] **Step 1.3.1: Добавить метод `listChannels` в `messenger.service.ts` (после `assertCanPostInChannel`):**

```typescript
  async listChannels(userId: string, q?: string, limit = 20, offset = 0) {
    const take = Math.min(Math.max(limit, 1), 50);
    const where: any = { type: "CHANNEL" };
    if (q && q.trim().length > 0) {
      where.name = { contains: q.trim(), mode: "insensitive" };
    }
    const rows = await this.prisma.conversation.findMany({
      where,
      include: {
        participants: { select: { userId: true } },
        _count: { select: { participants: true } },
      },
      orderBy: [{ updatedAt: "desc" }],
      take,
      skip: offset,
    });
    return rows
      .map(r => ({
        id: r.id,
        name: r.name,
        description: r.description,
        avatarUrl: r.avatarUrl,
        subscribersCount: r._count.participants,
        isSubscribed: r.participants.some(p => p.userId === userId),
      }))
      .sort((a, b) => b.subscribersCount - a.subscribersCount);
  }
```

- [ ] **Step 1.3.2: Добавить handler в `messenger.controller.ts` (непосредственно перед `@Post("channels")` на строке ~822):**

```typescript
  @Get("channels")
  async listChannels(
    @Query("q") q: string | undefined,
    @Query("limit") limit: string | undefined,
    @Query("offset") offset: string | undefined,
    @CurrentUser() user: any,
  ) {
    return this.service.listChannels(
      user.sub,
      q,
      limit ? parseInt(limit, 10) : 20,
      offset ? parseInt(offset, 10) : 0,
    );
  }
```

- [ ] **Step 1.3.3: Commit + deploy:**

```bash
ssh dvolkov@89.169.55.217 "cd ~/taler-id && git add src/messenger/messenger.{service,controller}.ts && git commit -m 'feat(channels): GET /channels list+search' && git push origin dev && npm run build && pm2 restart taler-id-dev"
```

- [ ] **Step 1.3.4: Запустить smoke-тест, тесты 2-4 должны пройти:**

```bash
cd ~/Downloads/taler_id_tests && npm run test:channels 2>&1 | head -40
```

### Task 1.4: `GET /messenger/channels/:id` (details)

**Files:**
- Modify: `~/taler-id/src/messenger/messenger.service.ts`
- Modify: `~/taler-id/src/messenger/messenger.controller.ts`

- [ ] **Step 1.4.1: Добавить `getChannelDetails` в service (после `listChannels`):**

```typescript
  async getChannelDetails(channelId: string, userId: string) {
    const conv = await this.prisma.conversation.findUnique({
      where: { id: channelId },
      include: {
        participants: true,
        _count: { select: { participants: true } },
      },
    });
    if (!conv) throw new NotFoundException("Channel not found");
    if (conv.type !== "CHANNEL") throw new BadRequestException("Not a channel");
    const me = conv.participants.find(p => p.userId === userId);
    return {
      id: conv.id,
      name: conv.name,
      description: conv.description,
      avatarUrl: conv.avatarUrl,
      subscribersCount: conv._count.participants,
      isSubscribed: !!me,
      myRole: me ? me.role : null,
    };
  }
```

(Если `NotFoundException` ещё не импортирован — добавить в верхний блок `import { ... } from "@nestjs/common"`.)

- [ ] **Step 1.4.2: Добавить handler в controller (после `GET channels`):**

```typescript
  @Get("channels/:id")
  async getChannelDetails(@Param("id") id: string, @CurrentUser() user: any) {
    return this.service.getChannelDetails(id, user.sub);
  }
```

- [ ] **Step 1.4.3: Commit + deploy + run test 5:**

```bash
ssh dvolkov@89.169.55.217 "cd ~/taler-id && git add src/messenger/messenger.{service,controller}.ts && git commit -m 'feat(channels): GET /channels/:id details' && git push origin dev && npm run build && pm2 restart taler-id-dev"
cd ~/Downloads/taler_id_tests && npm run test:channels 2>&1 | head -60
```

### Task 1.5: `PATCH /messenger/channels/:id`

**Files:**
- Modify: `~/taler-id/src/messenger/messenger.service.ts`
- Modify: `~/taler-id/src/messenger/messenger.controller.ts`

- [ ] **Step 1.5.1: Добавить `updateChannel` в service:**

```typescript
  async updateChannel(channelId: string, userId: string, patch: { name?: string; description?: string; avatarUrl?: string }) {
    const conv = await this._getConversationOrThrow(channelId);
    if (conv.type !== "CHANNEL") throw new BadRequestException("Not a channel");
    const me = await this.prisma.conversationParticipant.findUnique({
      where: { conversationId_userId: { conversationId: channelId, userId } },
    });
    if (!me || (me.role !== "OWNER" && me.role !== "ADMIN")) {
      throw new ForbiddenException("Only channel admins can edit");
    }
    const data: any = {};
    if (patch.name !== undefined) data.name = patch.name;
    if (patch.description !== undefined) data.description = patch.description;
    if (patch.avatarUrl !== undefined) data.avatarUrl = patch.avatarUrl;
    await this.prisma.conversation.update({ where: { id: channelId }, data });
    return this.getChannelDetails(channelId, userId);
  }
```

- [ ] **Step 1.5.2: Добавить handler в controller (после `GET channels/:id`):**

```typescript
  @Patch("channels/:id")
  async updateChannel(
    @Param("id") id: string,
    @Body() body: { name?: string; description?: string; avatarUrl?: string },
    @CurrentUser() user: any,
  ) {
    return this.service.updateChannel(id, user.sub, body);
  }
```

- [ ] **Step 1.5.3: Commit + deploy:**

```bash
ssh dvolkov@89.169.55.217 "cd ~/taler-id && git add src/messenger/messenger.{service,controller}.ts && git commit -m 'feat(channels): PATCH /channels/:id' && git push origin dev && npm run build && pm2 restart taler-id-dev"
```

### Task 1.6: `DELETE /messenger/channels/:id`

**Files:**
- Modify: `~/taler-id/src/messenger/messenger.service.ts`
- Modify: `~/taler-id/src/messenger/messenger.controller.ts`

- [ ] **Step 1.6.1: Добавить `deleteChannel` в service:**

```typescript
  async deleteChannel(channelId: string, userId: string) {
    const conv = await this._getConversationOrThrow(channelId);
    if (conv.type !== "CHANNEL") throw new BadRequestException("Not a channel");
    const me = await this.prisma.conversationParticipant.findUnique({
      where: { conversationId_userId: { conversationId: channelId, userId } },
    });
    if (!me || me.role !== "OWNER") {
      throw new ForbiddenException("Only the owner can delete the channel");
    }
    await this.prisma.conversation.delete({ where: { id: channelId } });
    return { ok: true };
  }
```

- [ ] **Step 1.6.2: Добавить handler:**

```typescript
  @Delete("channels/:id")
  async deleteChannel(@Param("id") id: string, @CurrentUser() user: any) {
    return this.service.deleteChannel(id, user.sub);
  }
```

- [ ] **Step 1.6.3: Commit + deploy:**

```bash
ssh dvolkov@89.169.55.217 "cd ~/taler-id && git add src/messenger/messenger.{service,controller}.ts && git commit -m 'feat(channels): DELETE /channels/:id' && git push origin dev && npm run build && pm2 restart taler-id-dev"
```

### Task 1.7: `POST /messenger/channels/:id/post` (для бота + будущий use-case)

**Files:**
- Modify: `~/taler-id/src/messenger/messenger.service.ts`
- Modify: `~/taler-id/src/messenger/messenger.controller.ts`

- [ ] **Step 1.7.1: Добавить `postToChannel` в service (переиспользует `createMessage` + `assertCanPostInChannel`):**

```typescript
  async postToChannel(channelId: string, userId: string, content: string) {
    await this.assertCanPostInChannel(channelId, userId);
    if (!content || content.trim().length === 0) {
      throw new BadRequestException("Content is empty");
    }
    if (content.length > 4000) {
      throw new BadRequestException("Content exceeds 4000 characters");
    }
    const msg = await this.createMessage(channelId, userId, content);
    return { messageId: msg.id, createdAt: msg.createdAt };
  }
```

- [ ] **Step 1.7.2: Добавить handler — он должен ещё и эмитить `new_message` подписчикам через gateway (паттерн как в `createPoll` на строке 844):**

```typescript
  @Post("channels/:id/post")
  async postToChannel(
    @Param("id") id: string,
    @Body("content") content: string,
    @CurrentUser() user: any,
  ) {
    const result = await this.service.postToChannel(id, user.sub, content);
    // Эмит в room для realtime-доставки подписчикам (как в createPoll)
    const full = await this.service.getMessageById(result.messageId);
    if (full) {
      this.gateway.server.to(id).emit("new_message", {
        ...full,
        senderName: await this.service.getUserDisplayName(user.sub),
        reactions: [],
      });
    }
    return result;
  }
```

- [ ] **Step 1.7.3: Проверить, существует ли `getMessageById` — если нет, добавить в service:**

```bash
ssh dvolkov@89.169.55.217 "cd ~/taler-id && grep -n 'getMessageById\\|getUserDisplayName' src/messenger/messenger.service.ts | head -5"
```

Если `getMessageById` нет — добавить в service:

```typescript
  async getMessageById(messageId: string) {
    return this.prisma.message.findUnique({ where: { id: messageId } });
  }
```

`getUserDisplayName` уже есть — проверено через использование в `createPoll`-handler.

- [ ] **Step 1.7.4: Commit + deploy + полный прогон теста (все 13 должны пройти):**

```bash
ssh dvolkov@89.169.55.217 "cd ~/taler-id && git add src/messenger/messenger.{service,controller}.ts && git commit -m 'feat(channels): POST /channels/:id/post + realtime emit' && git push origin dev && npm run build && pm2 restart taler-id-dev"
cd ~/Downloads/taler_id_tests && npm run test:channels
```

Ожидаемо: `13 passed, 0 failed`.

### Task 1.8: Обновить CLAUDE.md — добавить тест в обязательные

**Files:**
- Modify: `~/CLAUDE.md` (раздел «ОБЯЗАТЕЛЬНЫЕ ТЕСТЫ ПЕРЕД ДЕПЛОЕМ»)

- [ ] **Step 1.8.1: Добавить блок после пункта «7. Тест передачи файлов»:**

```markdown
### 8. Тест каналов (DEV)
E2E: CRUD каналов, subscribe/unsubscribe, роли, postToChannel.
```bash
cd ~/Downloads/taler_id_tests && npm run test:channels
```
- 13/13 тестов.
```

- [ ] **Step 1.8.2: Обновить финальный блок про PROD-прогон, включив `test:channels:prod`:**

```
cd ~/Downloads/taler_id_tests && npm run test:prod && npm run test:voice:prod && npm run test:assistant:prod && npm run test:files:prod && npm run test:channels:prod
```

(Заменить текущую строчку с прогонами после «После деплоя на PROD...».)

- [ ] **Step 1.8.3: Commit (CLAUDE.md — локальный, не в git):**

`~/CLAUDE.md` не под git-контролем, поэтому просто сохранить изменения.

---

## Phase 2 — Mobile: data layer + entity

### Task 2.1: Расширить `ConversationEntity`

**Files:**
- Modify: `~/Downloads/taler_id_mobile/lib/features/messenger/domain/entities/conversation_entity.dart`

- [ ] **Step 2.1.1: Добавить `subscribersCount` и `isSubscribed` в список полей (после `myRole`):**

Заменить блок:
```dart
    String? myRole,
    String? lastMessageContent,
```
на:
```dart
    String? myRole,
    int? subscribersCount,
    bool? isSubscribed,
    String? lastMessageContent,
```

- [ ] **Step 2.1.2: Перегенерить freezed/json:**

```bash
cd ~/Downloads/taler_id_mobile && dart run build_runner build --delete-conflicting-outputs
```

- [ ] **Step 2.1.3: `flutter test` — проверить что не сломалось:**

```bash
cd ~/Downloads/taler_id_mobile && flutter test
```

- [ ] **Step 2.1.4: Commit:**

```bash
cd ~/Downloads/taler_id_mobile && git add lib/features/messenger/domain/entities/conversation_entity.* && git commit -m "feat(channels): add subscribersCount+isSubscribed to ConversationEntity"
```

### Task 2.2: Создать DTO-модели для каналов

**Files:**
- Create: `~/Downloads/taler_id_mobile/lib/features/messenger/domain/entities/channel_summary.dart`
- Create: `~/Downloads/taler_id_mobile/lib/features/messenger/domain/entities/channel_details.dart`

- [ ] **Step 2.2.1: Создать `channel_summary.dart`:**

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'channel_summary.freezed.dart';
part 'channel_summary.g.dart';

@freezed
class ChannelSummary with _$ChannelSummary {
  const factory ChannelSummary({
    required String id,
    String? name,
    String? description,
    String? avatarUrl,
    @Default(0) int subscribersCount,
    @Default(false) bool isSubscribed,
  }) = _ChannelSummary;

  factory ChannelSummary.fromJson(Map<String, dynamic> json) =>
      _$ChannelSummaryFromJson(json);
}
```

- [ ] **Step 2.2.2: Создать `channel_details.dart`:**

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'channel_details.freezed.dart';
part 'channel_details.g.dart';

@freezed
class ChannelDetails with _$ChannelDetails {
  const factory ChannelDetails({
    required String id,
    String? name,
    String? description,
    String? avatarUrl,
    @Default(0) int subscribersCount,
    @Default(false) bool isSubscribed,
    String? myRole,
  }) = _ChannelDetails;

  factory ChannelDetails.fromJson(Map<String, dynamic> json) =>
      _$ChannelDetailsFromJson(json);
}
```

- [ ] **Step 2.2.3: Сгенерить + скомпилить:**

```bash
cd ~/Downloads/taler_id_mobile && dart run build_runner build --delete-conflicting-outputs && flutter analyze 2>&1 | tail -20
```

- [ ] **Step 2.2.4: Commit:**

```bash
cd ~/Downloads/taler_id_mobile && git add lib/features/messenger/domain/entities/channel_*.* && git commit -m "feat(channels): add ChannelSummary/ChannelDetails entities"
```

### Task 2.3: Расширить `MessengerRemoteDataSource` методами каналов

**Files:**
- Modify: `~/Downloads/taler_id_mobile/lib/features/messenger/data/datasources/messenger_remote_datasource.dart`

- [ ] **Step 2.3.1: Проверить, где в файле живут существующие channel-методы:**

```bash
grep -n 'channel\|Channel' ~/Downloads/taler_id_mobile/lib/features/messenger/data/datasources/messenger_remote_datasource.dart | head
```

Если существующих методов нет — добавить группу в конец класса перед закрывающей `}` файла.

- [ ] **Step 2.3.2: Добавить импорты в верх файла (рядом с существующими domain-entity import-ами):**

```dart
import '../../domain/entities/channel_summary.dart';
import '../../domain/entities/channel_details.dart';
```

- [ ] **Step 2.3.3: Добавить группу методов перед закрывающей `}` класса:**

```dart
  // ─── Channels ───────────────────────────────────────────────

  Future<List<ChannelSummary>> listChannels({String? q, int limit = 20, int offset = 0}) async {
    final params = <String, dynamic>{'limit': limit, 'offset': offset};
    if (q != null && q.isNotEmpty) params['q'] = q;
    final list = await _http.get<List<dynamic>>(
      '/messenger/channels',
      queryParameters: params,
      fromJson: (d) => d as List<dynamic>,
    );
    return list
        .map((e) => ChannelSummary.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<ChannelDetails> getChannelDetails(String id) async {
    final data = await _http.get<Map<String, dynamic>>(
      '/messenger/channels/$id',
      fromJson: (d) => Map<String, dynamic>.from(d as Map),
    );
    return ChannelDetails.fromJson(data);
  }

  Future<String> createChannel({required String name, String? description, String? avatarUrl}) async {
    final data = await _http.post<Map<String, dynamic>>(
      '/messenger/channels',
      data: {
        'name': name,
        if (description != null) 'description': description,
        if (avatarUrl != null) 'avatarUrl': avatarUrl,
      },
      fromJson: (d) => Map<String, dynamic>.from(d as Map),
    );
    return data['id'] as String;
  }

  Future<ChannelDetails> updateChannel(String id, {String? name, String? description, String? avatarUrl}) async {
    final data = await _http.patch<Map<String, dynamic>>(
      '/messenger/channels/$id',
      data: {
        if (name != null) 'name': name,
        if (description != null) 'description': description,
        if (avatarUrl != null) 'avatarUrl': avatarUrl,
      },
      fromJson: (d) => Map<String, dynamic>.from(d as Map),
    );
    return ChannelDetails.fromJson(data);
  }

  Future<void> deleteChannel(String id) async {
    await _http.delete<Map<String, dynamic>>(
      '/messenger/channels/$id',
      fromJson: (d) => d is Map ? Map<String, dynamic>.from(d) : <String, dynamic>{},
    );
  }

  Future<Map<String, dynamic>> subscribeToChannel(String id) async {
    return _http.post<Map<String, dynamic>>(
      '/messenger/channels/$id/subscribe',
      data: {},
      fromJson: (d) => Map<String, dynamic>.from(d as Map),
    );
  }

  Future<Map<String, dynamic>> unsubscribeFromChannel(String id) async {
    return _http.delete<Map<String, dynamic>>(
      '/messenger/channels/$id/subscribe',
      fromJson: (d) => Map<String, dynamic>.from(d as Map),
    );
  }
```

- [ ] **Step 2.3.4: Проверить DioClient API соответствует (patch/delete присутствуют):**

```bash
grep -n 'patch<\|delete<\|post<\|get<' ~/Downloads/taler_id_mobile/lib/core/api/dio_client.dart | head -10
```

Если какой-то метод отсутствует — использовать обёртку через dio напрямую или добавить его в DioClient (одна общая сигнатура с `fromJson`).

- [ ] **Step 2.3.5: `flutter analyze` + commit:**

```bash
cd ~/Downloads/taler_id_mobile && flutter analyze 2>&1 | tail -10
cd ~/Downloads/taler_id_mobile && git add lib/features/messenger/data/datasources/messenger_remote_datasource.dart && git commit -m "feat(channels): add remote methods for channels CRUD + subscribe"
```

---

## Phase 3 — Mobile: ChannelDirectoryScreen

### Task 3.1: Создать экран

**Files:**
- Create: `~/Downloads/taler_id_mobile/lib/features/messenger/presentation/screens/channel_directory_screen.dart`

- [ ] **Step 3.1.1: Создать файл с полным содержимым:**

```dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/datasources/messenger_remote_datasource.dart';
import '../../domain/entities/channel_summary.dart';

class ChannelDirectoryScreen extends StatefulWidget {
  const ChannelDirectoryScreen({super.key});

  @override
  State<ChannelDirectoryScreen> createState() => _ChannelDirectoryScreenState();
}

class _ChannelDirectoryScreenState extends State<ChannelDirectoryScreen> {
  final _searchCtrl = TextEditingController();
  Timer? _debounce;
  List<ChannelSummary> _items = [];
  bool _loading = false;
  String? _error;
  final _ds = sl<MessengerRemoteDataSource>();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await _ds.listChannels(q: _searchCtrl.text.trim());
      if (!mounted) return;
      setState(() { _items = res; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  void _onSearchChanged(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), _load);
  }

  Future<void> _subscribe(ChannelSummary ch) async {
    try {
      await _ds.subscribeToChannel(ch.id);
      if (!mounted) return;
      setState(() {
        _items = _items.map((e) => e.id == ch.id
            ? e.copyWith(isSubscribed: true, subscribersCount: e.subscribersCount + 1)
            : e).toList();
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: $e'), backgroundColor: AppColors.of(context).error),
      );
    }
  }

  void _openChannel(ChannelSummary ch) {
    context.push('/dashboard/messenger/${ch.id}');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = AppColors.of(context);
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        title: Text(l10n.channelsDiscover, style: TextStyle(color: colors.textPrimary)),
        iconTheme: IconThemeData(color: colors.textPrimary),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchCtrl,
              style: TextStyle(color: colors.textPrimary),
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: l10n.channelsSearchHint,
                hintStyle: TextStyle(color: colors.textSecondary),
                prefixIcon: Icon(Icons.search, color: colors.textSecondary),
                filled: true,
                fillColor: colors.card,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _load,
              child: _buildList(l10n, colors),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(AppLocalizations l10n, AppColorsData colors) {
    if (_loading && _items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return ListView(children: [
        Padding(
          padding: const EdgeInsets.all(24),
          child: Text(_error!, style: TextStyle(color: colors.error)),
        )
      ]);
    }
    if (_items.isEmpty) {
      return ListView(children: [
        const SizedBox(height: 120),
        Center(child: Icon(Icons.explore_rounded, color: colors.textSecondary, size: 64)),
        const SizedBox(height: 12),
        Center(child: Text(l10n.channelsEmpty, style: TextStyle(color: colors.textSecondary))),
      ]);
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      itemCount: _items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final ch = _items[i];
        return Container(
          decoration: BoxDecoration(
            color: colors.card,
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            onTap: () => _openChannel(ch),
            leading: CircleAvatar(
              backgroundColor: colors.primary.withValues(alpha: 0.2),
              backgroundImage: (ch.avatarUrl != null && ch.avatarUrl!.isNotEmpty)
                  ? CachedNetworkImageProvider(ch.avatarUrl!)
                  : null,
              child: (ch.avatarUrl == null || ch.avatarUrl!.isEmpty)
                  ? Text(
                      (ch.name ?? '?').substring(0, 1).toUpperCase(),
                      style: TextStyle(color: colors.primary, fontWeight: FontWeight.bold),
                    )
                  : null,
            ),
            title: Text(ch.name ?? '—', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (ch.description != null && ch.description!.isNotEmpty)
                  Text(ch.description!, maxLines: 2, overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: colors.textSecondary)),
                const SizedBox(height: 2),
                Text('${ch.subscribersCount} ${l10n.channelsSubscribers}',
                    style: TextStyle(color: colors.textSecondary, fontSize: 12)),
              ],
            ),
            trailing: ch.isSubscribed
                ? OutlinedButton(
                    onPressed: () => _openChannel(ch),
                    child: Text(l10n.channelsOpen),
                  )
                : ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.primary,
                      foregroundColor: Colors.black,
                    ),
                    onPressed: () => _subscribe(ch),
                    child: Text(l10n.channelsSubscribe),
                  ),
          ),
        );
      },
    );
  }
}
```

- [ ] **Step 3.1.2: Проверить, что `AppColorsData` — правильное имя типа colors (может быть `AppColors`), если `flutter analyze` ругается:**

```bash
grep -n 'class AppColors\|class AppColorsData' ~/Downloads/taler_id_mobile/lib/core/theme/app_colors.dart | head -5
```

Если тип называется иначе — заменить `AppColorsData` на правильный в сигнатуре `_buildList`.

### Task 3.2: Добавить локализацию

**Files:**
- Modify: `~/Downloads/taler_id_mobile/lib/l10n/app_ru.arb`
- Modify: `~/Downloads/taler_id_mobile/lib/l10n/app_en.arb`

- [ ] **Step 3.2.1: Добавить ключи в оба файла (JSON). В `app_ru.arb` перед закрывающей `}`:**

```json
  "channelsDiscover": "Найти канал",
  "channelsSearchHint": "Поиск каналов",
  "channelsSubscribers": "подписчиков",
  "channelsSubscribe": "Подписаться",
  "channelsUnsubscribe": "Отписаться",
  "channelsSubscribedLabel": "Вы подписаны на канал",
  "channelsSettings": "Настройки канала",
  "channelsDelete": "Удалить канал",
  "channelsDeleteConfirm": "Удалить канал без возможности восстановления?",
  "channelsEmpty": "Каналов пока нет",
  "channelsOpen": "Открыть",
  "channelsNameLabel": "Название",
  "channelsDescriptionLabel": "Описание",
  "channelsCannotUnsubscribeOwner": "Владелец не может отписаться. Удалите канал.",
  "channelsNotFoundRedirect": "Канал больше не существует",
```

(Обязательно добавить запятую после предыдущего ключа.)

- [ ] **Step 3.2.2: В `app_en.arb` — те же ключи с английскими значениями:**

```json
  "channelsDiscover": "Find channel",
  "channelsSearchHint": "Search channels",
  "channelsSubscribers": "subscribers",
  "channelsSubscribe": "Subscribe",
  "channelsUnsubscribe": "Unsubscribe",
  "channelsSubscribedLabel": "You are subscribed",
  "channelsSettings": "Channel settings",
  "channelsDelete": "Delete channel",
  "channelsDeleteConfirm": "Delete channel permanently?",
  "channelsEmpty": "No channels yet",
  "channelsOpen": "Open",
  "channelsNameLabel": "Name",
  "channelsDescriptionLabel": "Description",
  "channelsCannotUnsubscribeOwner": "Owner cannot unsubscribe. Delete the channel instead.",
  "channelsNotFoundRedirect": "Channel no longer exists",
```

- [ ] **Step 3.2.3: Перегенерить локализации:**

```bash
cd ~/Downloads/taler_id_mobile && flutter gen-l10n
```

- [ ] **Step 3.2.4: Commit:**

```bash
cd ~/Downloads/taler_id_mobile && git add lib/l10n/app_*.arb lib/l10n/app_localizations*.dart && git commit -m "l10n(channels): new keys for channel directory + settings"
```

### Task 3.3: Зарегистрировать маршрут + entry point

**Files:**
- Modify: `~/Downloads/taler_id_mobile/lib/core/router/app_router.dart`
- Modify: `~/Downloads/taler_id_mobile/lib/features/messenger/presentation/screens/conversations_screen.dart`

- [ ] **Step 3.3.1: В `app_router.dart` добавить импорт:**

```dart
import '../../features/messenger/presentation/screens/channel_directory_screen.dart';
```

(Вставить рядом с другими messenger-screens импортами.)

- [ ] **Step 3.3.2: Добавить subroute в messenger-shell (после `path: 'create-group',` блока) — перед `path: ':id',`:**

```dart
            GoRoute(
              path: 'channels',
              builder: (_, __) => const ChannelDirectoryScreen(),
            ),
```

- [ ] **Step 3.3.3: В `conversations_screen.dart` в методе `_showNewChatSheet` (строка ~498) после `ListTile` «Создать канал» (нашёл на строке 543-550) добавить четвёртый tile перед блоком `if (contacts.isNotEmpty)` (строка ~551):**

```dart
                ListTile(
                  leading: _gradientLeading(Icons.explore_rounded, const Color(0xFFF59E0B)),
                  title: Text(AppLocalizations.of(context)!.channelsDiscover, style: TextStyle(color: AppColors.of(context).textPrimary)),
                  onTap: () {
                    Navigator.pop(ctx);
                    context.push('/dashboard/messenger/channels');
                  },
                ),
```

- [ ] **Step 3.3.4: `flutter analyze` + запуск dev-flavor на эмуляторе:**

```bash
cd ~/Downloads/taler_id_mobile && flutter analyze 2>&1 | tail -10
flutter emulators --launch Pixel_XL_API_33  # если ещё не запущен
flutter run --flavor dev -t lib/main_dev.dart --dart-define=FLAVOR=dev --dart-define=BASE_URL=https://staging.id.taler.tirol -d emulator-5554
```

- [ ] **Step 3.3.5: Ручная проверка: Messenger → `+` → «Найти канал» → должен открыться экран, топ-каналы загружаются. Поиск по имени работает.

- [ ] **Step 3.3.6: Commit:**

```bash
cd ~/Downloads/taler_id_mobile && git add lib/core/router/app_router.dart lib/features/messenger/presentation/screens/channel_directory_screen.dart lib/features/messenger/presentation/screens/conversations_screen.dart && git commit -m "feat(channels): channel directory screen + entry from new-chat sheet"
```

---

## Phase 4 — Mobile: ChatRoomScreen role-aware + ChannelSettingsScreen

### Task 4.1: Role-aware правки в ChatRoomScreen

**Files:**
- Modify: `~/Downloads/taler_id_mobile/lib/features/messenger/presentation/screens/chat_room_screen.dart`

Важно: файл большой (~1500+ строк). Правки точечные; при их внесении использовать поиск по уникальным маркерам.

- [ ] **Step 4.1.1: Найти существующий AppBar-блок и composer-блок:**

```bash
grep -n 'AppBar\|_buildAppBar\|TextField.*controller: _messageCtrl\|_buildComposer\|PopupMenuButton' ~/Downloads/taler_id_mobile/lib/features/messenger/presentation/screens/chat_room_screen.dart | head -20
```

(Шаги 4.1.2–4.1.4 адаптируются к реальной структуре файла: вместо «добавить кастомный widget» используем существующие методы, добавляя `if (conv.type == 'CHANNEL')` conditionals.)

- [ ] **Step 4.1.2: В AppBar actions (там, где `PopupMenuButton<String>` или аналогичное меню) — добавить пункты для CHANNEL. Искать `PopupMenuButton<String>` ближайший к началу `build` метода.

Паттерн добавления (применить к существующему меню, добавив condition):

```dart
// Внутри itemBuilder: (ctx) => [ ... ]
if (conv.type == 'CHANNEL') ...[
  if (conv.myRole == 'OWNER' || conv.myRole == 'ADMIN')
    PopupMenuItem(value: 'channel_settings', child: Text(l10n.channelsSettings)),
  if (conv.myRole == 'OWNER')
    PopupMenuItem(value: 'channel_delete', child: Text(l10n.channelsDelete, style: TextStyle(color: AppColors.of(context).error))),
  if (conv.myRole == 'SUBSCRIBER')
    PopupMenuItem(value: 'channel_unsubscribe', child: Text(l10n.channelsUnsubscribe)),
],
```

И в `onSelected`:

```dart
case 'channel_settings':
  context.push('/dashboard/messenger/${widget.conversationId}/channel-settings');
  break;
case 'channel_delete':
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(l10n.channelsDelete),
      content: Text(l10n.channelsDeleteConfirm),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)),
        TextButton(onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.channelsDelete, style: TextStyle(color: AppColors.of(context).error))),
      ],
    ),
  );
  if (ok == true) {
    try {
      await sl<MessengerRemoteDataSource>().deleteChannel(widget.conversationId);
      context.read<MessengerBloc>().add(LoadConversations());
      if (context.mounted) context.pop();
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e'), backgroundColor: AppColors.of(context).error),
      );
    }
  }
  break;
case 'channel_unsubscribe':
  try {
    await sl<MessengerRemoteDataSource>().unsubscribeFromChannel(widget.conversationId);
    context.read<MessengerBloc>().add(LoadConversations());
    if (context.mounted) context.pop();
  } catch (e) {
    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$e'), backgroundColor: AppColors.of(context).error),
    );
  }
  break;
```

(`sl<MessengerRemoteDataSource>()` — уже импортировано в файле через service locator; если нет — добавить импорты из Task 2.3.)

- [ ] **Step 4.1.3: Заменить composer (bottom bar с TextField для сообщений) на условный widget:**

Найти внешний Container/SafeArea, в который завёрнут composer. Обернуть его условием:

```dart
if (conv.type == 'CHANNEL')
  _buildChannelBottom(conv, l10n)
else
  _existingComposer(...),  // старый блок
```

И добавить метод в тот же State-класс:

```dart
Widget _buildChannelBottom(ConversationEntity conv, AppLocalizations l10n) {
  final colors = AppColors.of(context);
  final role = conv.myRole;
  // OWNER/ADMIN — обычный composer (через тот же существующий widget)
  if (role == 'OWNER' || role == 'ADMIN') {
    return _existingComposer(); // вызвать существующий метод построения composer
  }
  // SUBSCRIBER — показать "подписан" + Unsubscribe
  if (role == 'SUBSCRIBER') {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        color: colors.card,
        child: Row(
          children: [
            Icon(Icons.check_circle, color: colors.primary),
            const SizedBox(width: 8),
            Expanded(child: Text(l10n.channelsSubscribedLabel, style: TextStyle(color: colors.textSecondary))),
            OutlinedButton(
              onPressed: () async {
                try {
                  await sl<MessengerRemoteDataSource>().unsubscribeFromChannel(conv.id);
                  if (context.mounted) {
                    context.read<MessengerBloc>().add(LoadConversations());
                    context.pop();
                  }
                } catch (e) {
                  if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('$e'), backgroundColor: colors.error),
                  );
                }
              },
              child: Text(l10n.channelsUnsubscribe),
            ),
          ],
        ),
      ),
    );
  }
  // null — не участник: Subscribe на всю ширину
  return SafeArea(
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: colors.card,
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: colors.primary,
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          onPressed: () async {
            try {
              await sl<MessengerRemoteDataSource>().subscribeToChannel(conv.id);
              if (context.mounted) context.read<MessengerBloc>().add(LoadConversations());
            } catch (e) {
              if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('$e'), backgroundColor: colors.error),
              );
            }
          },
          child: Text(l10n.channelsSubscribe),
        ),
      ),
    ),
  );
}
```

**Примечание:** «`_existingComposer()`» — это placeholder для текущего composer-кода. Найти реальное имя метода (или если composer инлайн — завернуть его в новый метод и вызвать и там, и тут). Во избежание дублирования кода обязательно превратить текущий composer в метод перед введением conditional.

- [ ] **Step 4.1.4: В AppBar subtitle для CHANNEL показать subscribersCount вместо статуса другого пользователя:**

Найти, где строится subtitle под title в AppBar (обычно в `_buildAppBarTitle` или аналогичном). Добавить condition:

```dart
if (conv.type == 'CHANNEL')
  Text('${conv.subscribersCount ?? 0} ${l10n.channelsSubscribers}',
      style: TextStyle(color: colors.textSecondary, fontSize: 12))
else
  ... // существующий код (online status / typing)
```

- [ ] **Step 4.1.5: Проверить build + запустить dev-flavor:**

```bash
cd ~/Downloads/taler_id_mobile && flutter analyze 2>&1 | tail -10
```

- [ ] **Step 4.1.6: Commit:**

```bash
cd ~/Downloads/taler_id_mobile && git add lib/features/messenger/presentation/screens/chat_room_screen.dart && git commit -m "feat(channels): role-aware AppBar + composer in ChatRoomScreen"
```

### Task 4.2: ChannelSettingsScreen

**Files:**
- Create: `~/Downloads/taler_id_mobile/lib/features/messenger/presentation/screens/channel_settings_screen.dart`

- [ ] **Step 4.2.1: Создать экран:**

```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/datasources/messenger_remote_datasource.dart';
import '../../domain/entities/channel_details.dart';
import '../bloc/messenger_bloc.dart';

class ChannelSettingsScreen extends StatefulWidget {
  const ChannelSettingsScreen({super.key, required this.channelId});
  final String channelId;

  @override
  State<ChannelSettingsScreen> createState() => _ChannelSettingsScreenState();
}

class _ChannelSettingsScreenState extends State<ChannelSettingsScreen> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _ds = sl<MessengerRemoteDataSource>();
  ChannelDetails? _channel;
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final ch = await _ds.getChannelDetails(widget.channelId);
      if (!mounted) return;
      // Guard: только OWNER/ADMIN
      if (ch.myRole != 'OWNER' && ch.myRole != 'ADMIN') {
        context.pop();
        return;
      }
      _nameCtrl.text = ch.name ?? '';
      _descCtrl.text = ch.description ?? '';
      setState(() { _channel = ch; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = '$e'; _loading = false; });
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await _ds.updateChannel(
        widget.channelId,
        name: _nameCtrl.text.trim(),
        description: _descCtrl.text.trim(),
      );
      if (!mounted) return;
      context.read<MessengerBloc>().add(LoadConversations());
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e'), backgroundColor: AppColors.of(context).error),
      );
      setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final l10n = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.channelsDelete),
        content: Text(l10n.channelsDeleteConfirm),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.channelsDelete, style: TextStyle(color: AppColors.of(context).error)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _ds.deleteChannel(widget.channelId);
      if (!mounted) return;
      context.read<MessengerBloc>().add(LoadConversations());
      context.go('/dashboard/messenger');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e'), backgroundColor: AppColors.of(context).error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = AppColors.of(context);
    if (_loading) return Scaffold(backgroundColor: colors.background, body: const Center(child: CircularProgressIndicator()));
    if (_error != null) {
      return Scaffold(
        backgroundColor: colors.background,
        appBar: AppBar(backgroundColor: colors.background, title: Text(l10n.channelsSettings)),
        body: Center(child: Text(_error!, style: TextStyle(color: colors.error))),
      );
    }
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        title: Text(l10n.channelsSettings, style: TextStyle(color: colors.textPrimary)),
        iconTheme: IconThemeData(color: colors.textPrimary),
        actions: [
          IconButton(
            icon: _saving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.check),
            onPressed: _saving ? null : _save,
            tooltip: l10n.save,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _nameCtrl,
            maxLength: 64,
            style: TextStyle(color: colors.textPrimary),
            decoration: InputDecoration(
              labelText: l10n.channelsNameLabel,
              labelStyle: TextStyle(color: colors.textSecondary),
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _descCtrl,
            maxLength: 300,
            maxLines: 4,
            style: TextStyle(color: colors.textPrimary),
            decoration: InputDecoration(
              labelText: l10n.channelsDescriptionLabel,
              labelStyle: TextStyle(color: colors.textSecondary),
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 32),
          if (_channel?.myRole == 'OWNER')
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: colors.error,
                side: BorderSide(color: colors.error),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: _delete,
              icon: const Icon(Icons.delete_outline),
              label: Text(l10n.channelsDelete),
            ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4.2.2: В `app_router.dart` импорт + subroute:**

Импорт:
```dart
import '../../features/messenger/presentation/screens/channel_settings_screen.dart';
```

Subroute: внутри блока `path: ':id'` (ChatRoomScreen), в `routes: [...]` — добавить:

```dart
                GoRoute(
                  path: 'channel-settings',
                  builder: (_, state) => ChannelSettingsScreen(
                    channelId: state.pathParameters['id']!,
                  ),
                ),
```

- [ ] **Step 4.2.3: `flutter analyze` + commit:**

```bash
cd ~/Downloads/taler_id_mobile && flutter analyze 2>&1 | tail -10
cd ~/Downloads/taler_id_mobile && git add lib/features/messenger/presentation/screens/channel_settings_screen.dart lib/core/router/app_router.dart && git commit -m "feat(channels): channel settings screen"
```

### Task 4.3: Fold subscribersCount into conversations list payload

**Files:**
- Modify (backend): `~/taler-id/src/messenger/messenger.service.ts` (getConversations)

Мобилка берёт conversations через общий `GET /messenger/conversations`, а у CHANNEL-ов там не хватает `subscribersCount` и `myRole` (отсутствуют в текущем ответе).

- [ ] **Step 4.3.1: Найти метод `getConversations`/`listConversations`:**

```bash
ssh dvolkov@89.169.55.217 "cd ~/taler-id && grep -n 'async getConversations\\|async listConversations' src/messenger/messenger.service.ts"
```

- [ ] **Step 4.3.2: В map-функции, где строится объект ответа на каждую conversation, добавить поля для CHANNEL:**

Для каждой `conv` в ответе, если `conv.type === 'CHANNEL'`, добавить:
```typescript
subscribersCount: conv._count?.participants ?? conv.participants?.length ?? 0,
myRole: conv.participants?.find((p: any) => p.userId === userId)?.role ?? null,
isSubscribed: conv.participants?.some((p: any) => p.userId === userId) ?? false,
```

Если select в prisma-запросе не включает `_count` или `participants` для conversation listing — добавить include. Конкретная правка зависит от текущего запроса (проверить на месте).

- [ ] **Step 4.3.3: Deploy + sanity check через curl:**

```bash
ssh dvolkov@89.169.55.217 "cd ~/taler-id && git add -A && git commit -m 'feat(channels): include subscribersCount+myRole in conversation list' && git push origin dev && npm run build && pm2 restart taler-id-dev"
T=$(curl -s -X POST https://staging.id.taler.tirol/auth/login -H 'Content-Type: application/json' -d '{"email":"integration_test@taler-test.com","password":"IntegrationTest123!"}' | jq -r .accessToken)
curl -s -H "Authorization: Bearer $T" https://staging.id.taler.tirol/messenger/conversations | jq '.[] | select(.type=="CHANNEL") | {id, name, subscribersCount, myRole}'
```

Ожидаем: в каждом CHANNEL-объекте есть `subscribersCount` и `myRole`.

---

## Phase 5 — Good News bot

### Task 5.1: Подготовить директорию и файлы шаблонов

**Files (на `dv@5.101.115.184`):**
- Create: `~/goodnews/.env`
- Create: `~/goodnews/run.sh`
- Create: `~/goodnews/setup.sh`
- Create: `~/goodnews/CLAUDE.md`
- Create: `~/goodnews/workspace/memory/identity.md`
- Create: `~/goodnews/workspace/memory/strategy.md`
- Create: `~/goodnews/workspace/memory/log.md`
- Create: `~/goodnews/workspace/.gitignore`

- [ ] **Step 5.1.1: Создать структуру папок:**

```bash
ssh dv@5.101.115.184 "mkdir -p ~/goodnews/workspace/{memory,logs}"
```

- [ ] **Step 5.1.2: Создать `run.sh`:**

```bash
ssh dv@5.101.115.184 "cat > ~/goodnews/run.sh << 'BASH'
#!/usr/bin/env bash
# Будит goodnews-бота, который постит хорошие новости в Taler ID канал.
set -u
cd \"\$(dirname \"\$0\")/workspace\" || exit 1
mkdir -p logs
TS=\$(date -u +%Y-%m-%dT%H:%M:%SZ)
LOG=\"logs/wake-\${TS}.log\"
set -a; source ../.env; set +a

exec 9>/tmp/goodnews.lock
flock -n 9 || { echo \"[\${TS}] another instance running, skip\" >> logs/wake.log; exit 0; }

PROMPT=\"Ты проснулся. Прочитай CLAUDE.md (в родительской папке), затем memory/identity.md, memory/strategy.md, memory/log.md. Найди через WebSearch хорошие новости про достижения человечества за последние 24 часа, отфильтруй по log.md, опубликуй в канал, обнови log.md, сделай git commit. Текущее UTC время: \${TS}\"

echo \"[\${TS}] waking goodnews\" | tee -a logs/wake.log
claude --dangerously-skip-permissions -p \"\$PROMPT\" 2>&1 | tee \"\$LOG\"
EXIT=\${PIPESTATUS[0]}
echo \"[\${TS}] finished exit=\${EXIT}\" | tee -a logs/wake.log
exit \$EXIT
BASH
chmod +x ~/goodnews/run.sh"
```

- [ ] **Step 5.1.3: Создать `CLAUDE.md` — инструкции агенту:**

```bash
ssh dv@5.101.115.184 "cat > ~/goodnews/CLAUDE.md << 'MD'
# Good News Agent

Ты — бот «Хорошие новости» в Taler ID. Раз в сутки публикуешь 3 хороших новости про достижения человечества в публичный канал.

## Окружение
- \`.env\` (родительская папка) содержит: \`TALER_BASE_URL\`, \`TALER_BOT_EMAIL\`, \`TALER_BOT_PASSWORD\`, \`TALER_CHANNEL_ID\`
- Рабочая директория: \`~/goodnews/workspace\` — здесь твой git и \`memory/\`
- У тебя есть: Bash, Read, Write, Edit, Glob, Grep, WebSearch, WebFetch

## Темы
- Наука (физика, биология, химия)
- Медицина (новые лечения, прорывы, статистика выживаемости)
- Технологии (с человеческой пользой, а не маркетинг)
- Космос (миссии, открытия)
- Экология (восстановление видов, сокращение выбросов, очистка)
- Образование (инициативы, результаты)
- Культура, спасение жизней, прорывы

## Избегать
- Политика, выборы, геополитика
- Войны, конфликты, терроризм
- Стартап-раунды без продукта
- Крипто-спекуляции
- Селебрити-сплетни
- Маркетинговые анонсы без фактов

## Источники (для WebSearch)
Nature, Science, BBC, NYT, WaPo, Guardian, Reuters, Positive.News, Good News Network, Reasons to be Cheerful.

## Формат поста (русский)

\`\`\`
🌍 Хорошие новости — DD.MM.YYYY

1. <эмодзи> <Заголовок>
<2-3 предложения описания на русском>
🔗 <оригинальный URL>

2. <эмодзи> <Заголовок>
<2-3 предложения>
🔗 <URL>

3. <эмодзи> <Заголовок>
<2-3 предложения>
🔗 <URL>
\`\`\`

## Дедуп
- Читай \`memory/log.md\` — последние 30 дней.
- Для каждой кандидатной новости: извлеки ключевые слова заголовка (длиннее 4 символов). Если ≥50% совпадают с какой-то уже записанной — пропусти, ищи другую.
- Если все кандидаты — дубли: попробуй 2-3 разных WebSearch-запроса. Если всё равно дубли — не публикуй, запиши «all dupes» в \`logs/wake.log\` и выходи с exit 0.

## Протокол публикации

1. Получить токен:
\`\`\`bash
TOKEN=\$(curl -s -X POST \"\$TALER_BASE_URL/auth/login\" \\
  -H \"Content-Type: application/json\" \\
  -d \"{\\\"email\\\":\\\"\$TALER_BOT_EMAIL\\\",\\\"password\\\":\\\"\$TALER_BOT_PASSWORD\\\"}\" | jq -r .accessToken)
\`\`\`

2. Опубликовать:
\`\`\`bash
curl -s -X POST \"\$TALER_BASE_URL/messenger/channels/\$TALER_CHANNEL_ID/post\" \\
  -H \"Authorization: Bearer \$TOKEN\" \\
  -H \"Content-Type: application/json\" \\
  -d \"{\\\"content\\\":\\\"<твой текст поста — экранированный JSON>\\\"}\"
\`\`\`

3. Если HTTP статус ≥400 — НЕ обновляй \`log.md\`, запиши детали в \`logs/wake.log\`, выйди с exit 1.

## После успешной публикации

1. Добавить в \`memory/log.md\` по одной строке на каждую опубликованную новость:
   \`YYYY-MM-DD | <Заголовок>\`

2. Git commit:
\`\`\`bash
cd ~/goodnews/workspace
git add -A
git commit -m \"post YYYY-MM-DD\"
\`\`\`

## Минимум

Если нашёл только 1-2 валидных новости (не 3) — публикуй сколько есть (минимум 1). Качество важнее количества.
MD"
```

- [ ] **Step 5.1.4: Создать `memory/identity.md`:**

```bash
ssh dv@5.101.115.184 "cat > ~/goodnews/workspace/memory/identity.md << 'MD'
# Identity

Я — бот «Хорошие новости» в Taler ID. Моя задача — раз в сутки публиковать 3 хороших новости про достижения человечества в одноимённый публичный канал.

Я получил доступ к:
- Taler ID backend (через curl + JWT)
- WebSearch для поиска новостей
- Файловой системе \`~/goodnews/workspace/\` для памяти

Я работаю из-под cron (06:00 UTC = 09:00 MSK) и живу на сервере \`dv@5.101.115.184\`.
MD"
```

- [ ] **Step 5.1.5: Создать `memory/strategy.md`:**

```bash
ssh dv@5.101.115.184 "cat > ~/goodnews/workspace/memory/strategy.md << 'MD'
# Strategy

## Поисковые запросы (ротируй при каждом запуске)
- \"positive science news last 24 hours\"
- \"breakthrough medical research today\"
- \"conservation success story this week\"
- \"space exploration achievement latest\"
- \"education success initiative this month\"
- \"climate restoration progress\"

## Критерии отбора
1. Факт (не мнение, не прогноз).
2. Проверяемый источник (URL обязателен).
3. Пример человечества в позитивном свете.
4. Не политика, не война, не конфликт.

## Если в WebSearch — пусто
Попробуй 3 разных запроса. Если и после этого ничего релевантного — опубликуй «Сегодня без новостей — завтра попробую снова» в канал (один раз). Обнови log.md.
MD"
```

- [ ] **Step 5.1.6: Создать пустой `memory/log.md` и `.gitignore`:**

```bash
ssh dv@5.101.115.184 "echo '# Published News Log' > ~/goodnews/workspace/memory/log.md && echo -e 'logs/\n*.log' > ~/goodnews/workspace/.gitignore"
```

- [ ] **Step 5.1.7: Пока что пустой `.env` (заполнит setup.sh):**

```bash
ssh dv@5.101.115.184 "cat > ~/goodnews/.env << 'ENV'
TALER_BASE_URL=https://staging.id.taler.tirol
TALER_BOT_EMAIL=goodnews-bot@taler-test.com
TALER_BOT_PASSWORD=
TALER_CHANNEL_ID=
ENV
chmod 600 ~/goodnews/.env"
```

### Task 5.2: Написать `setup.sh` и запустить его

**Files:**
- Create: `~/goodnews/setup.sh` (на `dv@5.101.115.184`)

- [ ] **Step 5.2.1: Создать setup.sh:**

```bash
ssh dv@5.101.115.184 "cat > ~/goodnews/setup.sh << 'BASH'
#!/usr/bin/env bash
# One-time bootstrap: регистрирует бота, создаёт канал, заполняет .env.
# Идемпотентно: повторный запуск не создаст дубль, а синхронизует .env.
set -eu
cd \"\$(dirname \"\$0\")\"

source .env

BASE=\$TALER_BASE_URL
EMAIL=\$TALER_BOT_EMAIL

if [ -z \"\$TALER_BOT_PASSWORD\" ]; then
  PW=\$(openssl rand -base64 18 | tr -d '/+=' | cut -c1-20)
  sed -i \"s|^TALER_BOT_PASSWORD=.*|TALER_BOT_PASSWORD=\$PW|\" .env
  echo \"generated password\"
  TALER_BOT_PASSWORD=\$PW
fi

# 1. Попробовать login
TOK=\$(curl -s -X POST \"\$BASE/auth/login\" -H 'Content-Type: application/json' \\
  -d \"{\\\"email\\\":\\\"\$EMAIL\\\",\\\"password\\\":\\\"\$TALER_BOT_PASSWORD\\\"}\" | jq -r .accessToken 2>/dev/null)

if [ \"\$TOK\" = \"null\" ] || [ -z \"\$TOK\" ]; then
  echo \"login failed, registering\"
  # 2. Register
  REG=\$(curl -s -X POST \"\$BASE/auth/register\" -H 'Content-Type: application/json' \\
    -d \"{\\\"email\\\":\\\"\$EMAIL\\\",\\\"password\\\":\\\"\$TALER_BOT_PASSWORD\\\",\\\"firstName\\\":\\\"Хорошие\\\",\\\"lastName\\\":\\\"новости\\\"}\")
  echo \"register: \$REG\"
  TOK=\$(echo \"\$REG\" | jq -r .accessToken 2>/dev/null)
  if [ \"\$TOK\" = \"null\" ] || [ -z \"\$TOK\" ]; then
    # Может быть email уже взят другим паролем — попробуем залогиниться ещё раз
    TOK=\$(curl -s -X POST \"\$BASE/auth/login\" -H 'Content-Type: application/json' \\
      -d \"{\\\"email\\\":\\\"\$EMAIL\\\",\\\"password\\\":\\\"\$TALER_BOT_PASSWORD\\\"}\" | jq -r .accessToken)
  fi
fi

if [ \"\$TOK\" = \"null\" ] || [ -z \"\$TOK\" ]; then
  echo \"FATAL: cannot get token. Check email/password in .env\"
  exit 1
fi
echo \"got token\"

# 3. Ищем существующий канал
CHANNELS=\$(curl -s -H \"Authorization: Bearer \$TOK\" \"\$BASE/messenger/channels\")
CID=\$(echo \"\$CHANNELS\" | jq -r '.[] | select(.name==\"Хорошие новости\") | .id' | head -1)

if [ -z \"\$CID\" ] || [ \"\$CID\" = \"null\" ]; then
  echo \"creating channel\"
  CREATE=\$(curl -s -X POST \"\$BASE/messenger/channels\" \\
    -H \"Authorization: Bearer \$TOK\" -H 'Content-Type: application/json' \\
    -d '{\"name\":\"Хорошие новости\",\"description\":\"Достижения человечества — ежедневный дайджест.\"}')
  CID=\$(echo \"\$CREATE\" | jq -r .id)
  echo \"channel created: \$CID\"
else
  echo \"channel exists: \$CID\"
fi

sed -i \"s|^TALER_CHANNEL_ID=.*|TALER_CHANNEL_ID=\$CID|\" .env

# 4. Init git в workspace (если ещё нет)
cd workspace
if [ ! -d .git ]; then
  git init -q
  git config user.email \"goodnews-bot@taler-test.com\"
  git config user.name \"Good News Bot\"
  git add -A
  git commit -q -m \"initial memory\"
  echo \"git initialized\"
fi

echo \"\"
echo \"=== Setup complete ===\"
echo \"Channel ID: \$CID\"
echo \"\"
echo \"Next steps:\"
echo \"  1. Run ~/goodnews/run.sh once manually to test\"
echo \"  2. Then add to crontab: 0 6 * * * /home/dv/goodnews/run.sh >> /home/dv/goodnews/workspace/logs/cron.log 2>&1 # goodnews-daily\"
BASH
chmod +x ~/goodnews/setup.sh"
```

- [ ] **Step 5.2.2: Запустить `setup.sh`:**

```bash
ssh dv@5.101.115.184 "~/goodnews/setup.sh"
```

Ожидаемый вывод: `got token`, `channel created: <uuid>`, `git initialized`, `Setup complete`.

- [ ] **Step 5.2.3: Проверить `.env`:**

```bash
ssh dv@5.101.115.184 "cat ~/goodnews/.env"
```

Оба `TALER_BOT_PASSWORD` и `TALER_CHANNEL_ID` должны быть заполнены.

### Task 5.3: Запустить бота вручную (без cron) и проверить пост

- [ ] **Step 5.3.1: Ручной запуск:**

```bash
ssh dv@5.101.115.184 "~/goodnews/run.sh"
```

Агент подумает ~1-3 минуты, использует WebSearch, сделает curl-POST.

- [ ] **Step 5.3.2: Проверить лог:**

```bash
ssh dv@5.101.115.184 "ls -t ~/goodnews/workspace/logs/wake-*.log | head -1 | xargs tail -80"
```

Ищем строки про curl POST и успешный JSON-ответ `{\"messageId\":...}`.

- [ ] **Step 5.3.3: Проверить что пост дошёл:**

```bash
ssh dv@5.101.115.184 "source ~/goodnews/.env && \
  TOK=\$(curl -s -X POST \"\$TALER_BASE_URL/auth/login\" -H 'Content-Type: application/json' \
    -d \"{\\\"email\\\":\\\"\$TALER_BOT_EMAIL\\\",\\\"password\\\":\\\"\$TALER_BOT_PASSWORD\\\"}\" | jq -r .accessToken) && \
  curl -s -H \"Authorization: Bearer \$TOK\" \"\$TALER_BASE_URL/messenger/conversations/\$TALER_CHANNEL_ID/messages\" | jq '.messages[0].content'"
```

Должен показать текст поста.

- [ ] **Step 5.3.4: Проверить log.md + git:**

```bash
ssh dv@5.101.115.184 "cat ~/goodnews/workspace/memory/log.md && cd ~/goodnews/workspace && git log --oneline"
```

Должны быть новые строки в log.md и новый коммит.

### Task 5.4: Добавить cron

- [ ] **Step 5.4.1: Добавить запись в crontab:**

```bash
ssh dv@5.101.115.184 "(crontab -l 2>/dev/null; echo '0 6 * * * /home/dv/goodnews/run.sh >> /home/dv/goodnews/workspace/logs/cron.log 2>&1 # goodnews-daily') | crontab -"
```

- [ ] **Step 5.4.2: Проверить:**

```bash
ssh dv@5.101.115.184 "crontab -l | grep goodnews"
```

---

## Phase 6 — Mobile integration test + final deploy

### Task 6.1: Добавить E2E-секцию в `integration_test/app_test.dart`

**Files:**
- Modify: `~/Downloads/taler_id_mobile/integration_test/app_test.dart`

- [ ] **Step 6.1.1: В конец существующего теста (перед `tearDown` или `await tester.pumpAndSettle` финальным), или в новый testWidgets-блок:**

```dart
testWidgets('channels: directory → subscribe → read → unsubscribe', (tester) async {
  // Предполагаем что login уже выполнен в предыдущем блоке.
  // Открыть messenger
  await tester.tap(find.byIcon(Icons.chat_bubble_outline).first);
  await tester.pumpAndSettle();

  // Нажать FAB "+"
  final fab = find.byType(FloatingActionButton).first;
  await tester.tap(fab);
  await tester.pumpAndSettle();

  // Нажать "Найти канал"
  final findChannelTile = find.textContaining('Найти канал');
  expect(findChannelTile, findsOneWidget);
  await tester.tap(findChannelTile);
  await tester.pumpAndSettle();

  // Ищем канал "Хорошие новости"
  final searchField = find.byType(TextField).first;
  await tester.enterText(searchField, 'Хорошие');
  await tester.pumpAndSettle(const Duration(milliseconds: 500));

  // Должен появиться элемент списка
  final channelCard = find.textContaining('Хорошие');
  expect(channelCard, findsWidgets);

  // Подписаться
  final subscribeBtn = find.widgetWithText(ElevatedButton, 'Подписаться').first;
  if (subscribeBtn.evaluate().isNotEmpty) {
    await tester.tap(subscribeBtn);
    await tester.pumpAndSettle();
  }

  // Открыть канал (tap по карточке)
  await tester.tap(channelCard.first);
  await tester.pumpAndSettle();

  // Подтверждение: composer показывает "Вы подписаны"
  expect(find.textContaining('Вы подписаны'), findsOneWidget);

  // Отписаться через меню
  await tester.tap(find.byIcon(Icons.more_vert).first);
  await tester.pumpAndSettle();
  final unsubscribeItem = find.text('Отписаться');
  expect(unsubscribeItem, findsOneWidget);
  await tester.tap(unsubscribeItem);
  await tester.pumpAndSettle();

  // Вернёт в conversations; проверяем что нет крашей
  await tester.pumpAndSettle();
});
```

- [ ] **Step 6.1.2: Запустить integration-test на эмуляторе:**

```bash
cd ~/Downloads/taler_id_mobile && flutter test integration_test/app_test.dart --flavor dev --dart-define=FLAVOR=dev --dart-define=BASE_URL=https://staging.id.taler.tirol -d emulator-5554
```

- [ ] **Step 6.1.3: Commit:**

```bash
cd ~/Downloads/taler_id_mobile && git add integration_test/app_test.dart && git commit -m "test(channels): integration test for directory/subscribe/unsubscribe"
```

### Task 6.2: Полный прогон обязательных тестов

- [ ] **Step 6.2.1: Flutter unit:**

```bash
cd ~/Downloads/taler_id_mobile && flutter test
```

- [ ] **Step 6.2.2: Integration UI:**

```bash
flutter emulators --launch Pixel_XL_API_33 2>/dev/null &
sleep 15
cd ~/Downloads/taler_id_mobile && flutter test integration_test/app_test.dart --flavor dev --dart-define=FLAVOR=dev --dart-define=BASE_URL=https://staging.id.taler.tirol -d emulator-5554
```

- [ ] **Step 6.2.3: API smoke (DEV):**

```bash
cd ~/Downloads/taler_id_tests && npm test && npm run test:channels && npm run test:voice && npm run test:assistant && npm run test:files
```

Все группы должны быть зелёными.

### Task 6.3: Deploy APK (dev flavor)

- [ ] **Step 6.3.1: Собрать dev APK на PROD-сервере (там есть Flutter SDK, см. CLAUDE.md):**

```bash
ssh dvolkov@138.124.61.221 "cd ~/taler_id_mobile && git fetch origin && git checkout dev && git pull origin dev && flutter build apk --flavor dev --release -t lib/main_dev.dart --dart-define=FLAVOR=dev --dart-define=BASE_URL=https://staging.id.taler.tirol && sudo cp build/app/outputs/flutter-apk/app-dev-release.apk /var/www/downloads/taler-id-dev.apk && sudo chmod 644 /var/www/downloads/taler-id-dev.apk"
```

- [ ] **Step 6.3.2: Проверить APK-ссылку:**

```bash
curl -sI https://id.taler.tirol/download/taler-id-dev.apk | head -5
```

HTTP 200 + `content-type: application/vnd.android.package-archive`.

- [ ] **Step 6.3.3: Установить APK на эмулятор или устройство и прокликать каналы:**

```bash
~/Library/Android/sdk/platform-tools/adb -s emulator-5554 install -r /path/to/downloaded/taler-id-dev.apk
```

Или на реальный телефон через `adb install`.

### Task 6.4: Сообщить результат

- [ ] **Step 6.4.1: Вывести пользователю:**
  - Channel ID канала «Хорошие новости» (из `~/goodnews/.env`)
  - Результаты всех тестов (каждый в формате `N/N passed`)
  - Статус cron (`crontab -l | grep goodnews`)
  - Ссылку на dev APK

---

## Self-Review checklist

### Spec coverage

| Spec section | Implementing tasks |
|---|---|
| §2.1 GET /channels | 1.3 |
| §2.1 GET /channels/:id | 1.4 |
| §2.1 PATCH /channels/:id | 1.5 |
| §2.1 DELETE /channels/:id | 1.6 |
| §2.1 POST /channels/:id/post | 1.7 |
| §2.2 idempotent subscribe + OWNER unsubscribe block | 1.2 |
| §3.1 ChannelDirectoryScreen | 3.1–3.3 |
| §3.2 ChatRoomScreen role-aware | 4.1, 4.3 (subscribersCount в списке) |
| §3.3 ChannelSettingsScreen | 4.2 |
| §3.4 Entry point в `_showNewChatSheet` | 3.3.3 |
| §3.5 Data layer | 2.1, 2.2, 2.3 |
| §3.6 Локализация | 3.2 |
| §4.1–4.7 Good News bot | 5.1–5.4 |
| §6.1 API smoke-тесты | 1.1 |
| §6.2 Flutter unit | 6.2.1 |
| §6.3 Integration UI | 6.1, 6.2.2 |
| §6.4 Manual bot test | 5.3 |
| §6.5 Two-emulator E2E | Covered by 6.1 against live channel |
| §6.6 Deploy rule | 6.3 (dev only) |

### Placeholder scan
Все TODO-фразы устранены. В шагах 4.1.3 указан `_existingComposer()` как маркер — прописано, что нужно найти реальное имя перед введением условия; это неизбежно, т.к. структура большого файла уникальна.

### Type consistency
- `ChannelSummary` / `ChannelDetails` — использованы единообразно (fields `subscribersCount`, `isSubscribed`, `myRole`).
- `listChannels({String? q, int limit, int offset})` — одна сигнатура в ремоте, одна в сервисе.
- Backend: `subscribeToChannel` возвращает `{ ok, alreadySubscribed }` — именно это ожидает тест Task 1.1.
- Route path `/dashboard/messenger/channels` и `/dashboard/messenger/:id/channel-settings` — совпадают между `app_router.dart` и push-вызовами в screens.

---

## Execution handoff

**Plan complete and saved to `docs/superpowers/plans/2026-04-23-taler-id-channels-goodnews.md`. Two execution options:**

**1. Subagent-Driven (recommended)** — я диспатчу fresh subagent per task, review между шагами.

**2. Inline Execution** — выполнить задачи в этой сессии, чекпойнты для ревью.

**Which approach?**

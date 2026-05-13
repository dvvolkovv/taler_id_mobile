# Messenger Since-Cursor Sync Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Deliver every chat message created server-side while the mobile client was offline / backgrounded, by adding a `GET /messenger/sync` endpoint with an opaque `(sentAt, id)` cursor, plus client-side polling on connect / reconnect / app resume.

**Architecture:** Server endpoint returns the user's messages strictly greater than the supplied cursor, scoped to conversations the user participates in. Client stores the latest cursor in a Hive box, dispatches a private bloc event to drain the delta page-by-page, and feeds each message through the existing `MessageReceived` handler (which dedups by `msg.id`, clears pending bubbles, and updates the cache).

**Tech Stack:** NestJS + Prisma + PostgreSQL on the server (Prisma `$queryRaw` for row-value comparison); Flutter + flutter_bloc + Hive on the client; Jest for backend unit tests; `ts-node` for integration tests in `taler_id_tests`; `flutter_test` + `bloc_test` + `mocktail` for mobile tests.

**Spec:** `docs/superpowers/specs/2026-05-13-messenger-sync-design.md`

**Repos:**
- Backend: `~/taler-id/`
- Mobile: `~/Downloads/taler_id_mobile/` (branch `dev`)
- Integration tests: `~/Downloads/taler_id_tests/`

---

## File Structure

### Backend (`taler-id`)
- **Create** `src/messenger/dto/sync.dto.ts` — query DTO + response interface.
- **Modify** `src/messenger/messenger.service.ts` — add `sync(userId, cursor?, limit?)` method.
- **Modify** `src/messenger/messenger.controller.ts` — add `GET /messenger/sync` route handler.
- **Create** `src/messenger/messenger.service.sync.spec.ts` — unit tests for the service method.

### Integration tests (`taler_id_tests`)
- **Create** `sync_test.ts` — E2E API test.
- **Modify** `package.json` — register `test:sync` and `test:sync:prod` scripts.

### Mobile (`taler_id_mobile`)
- **Create** `lib/core/storage/sync_cursor_storage.dart` — Hive wrapper for the cursor.
- **Create** `lib/features/messenger/domain/entities/sync_result.dart` — `SyncResult` data class.
- **Modify** `lib/features/messenger/domain/repositories/i_messenger_repository.dart` — add `sync()`.
- **Modify** `lib/features/messenger/data/datasources/messenger_remote_datasource.dart` — add `sync()` HTTP call.
- **Modify** `lib/features/messenger/data/repositories/messenger_repository_impl.dart` — passthrough.
- **Modify** `lib/features/messenger/presentation/bloc/messenger_event.dart` — add `SyncMessagesRequested` event.
- **Modify** `lib/features/messenger/presentation/bloc/messenger_bloc.dart` — handler, three triggers, `WidgetsBindingObserver`, register in `close()`.
- **Modify** `lib/core/di/service_locator.dart` — register `SyncCursorStorage` singleton.
- **Modify** `lib/main.dart` — open Hive box at startup.
- **Create** `test/core/storage/sync_cursor_storage_test.dart` — Hive wrapper unit test.
- **Create** `test/features/messenger/presentation/bloc/messenger_bloc_sync_test.dart` — bloc tests.

---

## Task 1: Backend — Sync DTO + types

**Files:**
- Create: `~/taler-id/src/messenger/dto/sync.dto.ts`

- [ ] **Step 0: Switch backend repo to `dev` branch**

```bash
cd ~/taler-id
git checkout dev && git pull origin dev
```

(Per CLAUDE.md feedback: always work on `dev`, never on `main`.)

- [ ] **Step 1: Create the DTO file**

```typescript
// ~/taler-id/src/messenger/dto/sync.dto.ts

export class SyncQueryDto {
  cursor?: string;
  limit?: string; // string because @Query() values arrive as strings
}

export interface SyncResultMessage {
  id: string;
  conversationId: string;
  senderId: string | null;
  content: string | null;
  sentAt: Date;
  // …all other Message fields, see existing MessengerService.getMessages
  // enrichment for the canonical shape (senderName, reactions[]).
  [key: string]: unknown;
}

export interface SyncResultDto {
  messages: SyncResultMessage[];
  nextCursor: string | null;
  hasMore: boolean;
}
```

- [ ] **Step 2: Commit**

```bash
cd ~/taler-id
git add src/messenger/dto/sync.dto.ts
git commit -m "feat(messenger): add sync DTO + result types"
```

---

## Task 2: Backend — Service method (TDD)

**Files:**
- Create: `~/taler-id/src/messenger/messenger.service.sync.spec.ts`
- Modify: `~/taler-id/src/messenger/messenger.service.ts` — add `sync()` method
- Modify: `~/taler-id/src/messenger/messenger.service.ts:494-540` — reuse the existing senderName + reactions enrichment by extracting a private helper (see Step 5).

- [ ] **Step 1: Write the failing test (initialization branch)**

Create `~/taler-id/src/messenger/messenger.service.sync.spec.ts`:

```typescript
import { Test } from '@nestjs/testing';
import { MessengerService } from './messenger.service';
import { PrismaService } from '../prisma/prisma.service';
import { RedisService } from '../redis/redis.service';

describe('MessengerService.sync', () => {
  let service: MessengerService;
  let mockPrisma: { $queryRaw: jest.Mock; message: { findFirst: jest.Mock } };

  beforeEach(async () => {
    mockPrisma = {
      $queryRaw: jest.fn(),
      message: { findFirst: jest.fn() },
    };
    const mod = await Test.createTestingModule({
      providers: [
        MessengerService,
        { provide: PrismaService, useValue: mockPrisma },
        { provide: RedisService, useValue: { client: { get: jest.fn(), set: jest.fn() } } },
      ],
    }).compile();
    service = mod.get(MessengerService);
  });

  it('initialization (no cursor) returns empty messages and current cursor', async () => {
    mockPrisma.message.findFirst.mockResolvedValue({
      id: 'last-msg-id',
      sentAt: new Date('2026-05-13T10:00:00.000Z'),
    });

    const out = await service.sync('user-1');

    expect(out.messages).toEqual([]);
    expect(out.hasMore).toBe(false);
    expect(out.nextCursor).toBe('2026-05-13T10:00:00.000Z|last-msg-id');
  });
});
```

- [ ] **Step 2: Run the test to verify it fails**

```bash
cd ~/taler-id
npx jest src/messenger/messenger.service.sync.spec.ts --no-coverage
```

Expected: FAIL — `service.sync is not a function`.

- [ ] **Step 3: Implement the initialization branch in the service**

In `~/taler-id/src/messenger/messenger.service.ts`, add the following method (place it after `getMessages` near line 540):

```typescript
async sync(
  userId: string,
  cursor?: string,
  limit = 200,
): Promise<{
  messages: any[];
  nextCursor: string | null;
  hasMore: boolean;
}> {
  const cap = Math.min(Math.max(limit, 1), 500);

  if (!cursor) {
    // Initialization: return the current "max" cursor for this user, no messages.
    const last = await this.prisma.message.findFirst({
      where: {
        deletedAt: null,
        conversation: {
          participants: { some: { userId } },
        },
        NOT: { hiddenFor: { some: { userId } } },
      },
      orderBy: [{ sentAt: 'desc' }, { id: 'desc' }],
      select: { id: true, sentAt: true },
    });
    const nextCursor = last
      ? `${last.sentAt.toISOString()}|${last.id}`
      : `${new Date().toISOString()}|`;
    return { messages: [], nextCursor, hasMore: false };
  }

  // Delta branch — implemented in Task 2, Step 6 below.
  throw new Error('sync delta branch not yet implemented');
}
```

- [ ] **Step 4: Run the test — it should pass**

```bash
cd ~/taler-id
npx jest src/messenger/messenger.service.sync.spec.ts --no-coverage
```

Expected: PASS (1/1).

- [ ] **Step 5: Add the delta-branch failing test**

Append to `messenger.service.sync.spec.ts` inside the `describe` block:

```typescript
  it('delta (with cursor) returns messages strictly greater than cursor, ordered ascending', async () => {
    const rows = [
      {
        id: 'm2',
        conversationId: 'conv-1',
        senderId: 'user-2',
        content: 'hello',
        sentAt: new Date('2026-05-13T10:05:00.000Z'),
        senderUsername: 'bob',
        senderFirstName: 'Bob',
        senderLastName: null,
        reactions: [],
      },
    ];
    mockPrisma.$queryRaw.mockResolvedValueOnce(rows);

    const out = await service.sync(
      'user-1',
      '2026-05-13T10:00:00.000Z|m1',
      100,
    );

    expect(out.messages).toHaveLength(1);
    expect(out.messages[0].id).toBe('m2');
    expect(out.messages[0].senderName).toBe('Bob');
    expect(out.hasMore).toBe(false);
    expect(out.nextCursor).toBe('2026-05-13T10:05:00.000Z|m2');
  });

  it('delta sets hasMore=true and trims to limit when limit+1 rows returned', async () => {
    const make = (i: number) => ({
      id: `m${i}`,
      conversationId: 'conv-1',
      senderId: 'user-2',
      content: `msg ${i}`,
      sentAt: new Date(`2026-05-13T10:${10 + i}:00.000Z`),
      senderUsername: 'bob',
      senderFirstName: null,
      senderLastName: null,
      reactions: [],
    });
    mockPrisma.$queryRaw.mockResolvedValueOnce([1, 2, 3].map(make));

    const out = await service.sync(
      'user-1',
      '2026-05-13T10:00:00.000Z|m0',
      2, // limit = 2, so the query returns 3 (limit+1) and trims to 2
    );

    expect(out.messages).toHaveLength(2);
    expect(out.hasMore).toBe(true);
    expect(out.nextCursor).toBe('2026-05-13T10:12:00.000Z|m2');
  });
```

- [ ] **Step 6: Run the new tests to verify they fail**

```bash
cd ~/taler-id
npx jest src/messenger/messenger.service.sync.spec.ts --no-coverage
```

Expected: 1 PASS (initialization) + 2 FAIL ("sync delta branch not yet implemented").

- [ ] **Step 7: Implement the delta branch**

Replace the `throw new Error('sync delta branch not yet implemented')` in `messenger.service.ts` with the following block, and keep the method's return contract from Step 3:

```typescript
  // Parse cursor: "<ISO8601>|<uuid>". Empty uuid is allowed for first-ever syncs.
  const sepIdx = cursor.indexOf('|');
  if (sepIdx === -1) {
    throw new Error('Invalid sync cursor format');
  }
  const cursorTs = new Date(cursor.slice(0, sepIdx));
  const cursorId = cursor.slice(sepIdx + 1);
  if (Number.isNaN(cursorTs.getTime())) {
    throw new Error('Invalid sync cursor timestamp');
  }

  // Row-value comparison via $queryRaw because Prisma's query builder cannot
  // express `(sentAt, id) > (?, ?)`. The join scopes to the user's
  // conversations; hiddenFor exclusion mirrors getMessages.
  const rows: any[] = await this.prisma.$queryRaw`
    SELECT
      m.id,
      m."conversationId",
      m."senderId",
      m.content,
      m."sentAt",
      m."isSystem",
      m."isEdited",
      m."isDelivered",
      m."isRead",
      m."replyToId",
      m."fileUrl",
      m."fileName",
      m."fileSize",
      m."fileType",
      m."thumbnailSmallUrl",
      m."thumbnailMediumUrl",
      m."thumbnailLargeUrl",
      m."clientTempId",
      m."topicId",
      u.username AS "senderUsername",
      p."firstName" AS "senderFirstName",
      p."lastName" AS "senderLastName",
      COALESCE(
        (
          SELECT json_agg(json_build_object('userId', r."userId", 'emoji', r.emoji))
          FROM "MessageReaction" r WHERE r."messageId" = m.id
        ),
        '[]'::json
      ) AS reactions
    FROM "Message" m
    JOIN "ConversationParticipant" cp
      ON cp."conversationId" = m."conversationId" AND cp."userId" = ${userId}
    LEFT JOIN "User" u ON u.id = m."senderId"
    LEFT JOIN "Profile" p ON p."userId" = u.id
    WHERE m."deletedAt" IS NULL
      AND NOT EXISTS (
        SELECT 1 FROM "MessageHidden" h
        WHERE h."messageId" = m.id AND h."userId" = ${userId}
      )
      AND (m."sentAt", m.id) > (${cursorTs}::timestamptz, ${cursorId}::text)
    ORDER BY m."sentAt" ASC, m.id ASC
    LIMIT ${cap + 1}
  `;

  const hasMore = rows.length > cap;
  const sliced = hasMore ? rows.slice(0, cap) : rows;
  const enriched = sliced.map((r: any) => {
    const firstLast =
      [r.senderFirstName, r.senderLastName].filter(Boolean).join(' ').trim() ||
      null;
    const senderName = firstLast ?? r.senderUsername ?? null;
    // Drop the helper columns from the response.
    const {
      senderUsername,
      senderFirstName,
      senderLastName,
      ...rest
    } = r;
    return { ...rest, senderName, reactions: r.reactions ?? [] };
  });

  const last = sliced[sliced.length - 1];
  const nextCursor = last
    ? `${(last.sentAt instanceof Date ? last.sentAt : new Date(last.sentAt)).toISOString()}|${last.id}`
    : cursor;

  return { messages: enriched, nextCursor, hasMore };
```

- [ ] **Step 8: Run all sync tests — they should pass**

```bash
cd ~/taler-id
npx jest src/messenger/messenger.service.sync.spec.ts --no-coverage
```

Expected: 3/3 PASS.

- [ ] **Step 9: Commit**

```bash
cd ~/taler-id
git add src/messenger/messenger.service.ts src/messenger/messenger.service.sync.spec.ts
git commit -m "feat(messenger): add MessengerService.sync delta + initialization"
```

---

## Task 3: Backend — Controller route

**Files:**
- Modify: `~/taler-id/src/messenger/messenger.controller.ts` — add `GET /sync` after the existing `Get('conversations')` block (~line 115).

- [ ] **Step 1: Add the route handler**

Insert this method into the `MessengerController` class:

```typescript
  @Get('sync')
  sync(
    @Query('cursor') cursor: string | undefined,
    @Query('limit') limit: string | undefined,
    @CurrentUser() user: any,
  ) {
    const parsedLimit = limit ? Math.min(Math.max(parseInt(limit, 10) || 200, 1), 500) : 200;
    return this.service.sync(user.sub, cursor || undefined, parsedLimit);
  }
```

- [ ] **Step 2: Build the backend to confirm no type errors**

```bash
cd ~/taler-id
npm run build
```

Expected: build succeeds.

- [ ] **Step 3: Commit**

```bash
cd ~/taler-id
git add src/messenger/messenger.controller.ts
git commit -m "feat(messenger): add GET /messenger/sync route"
```

---

## Task 4: Backend — Deploy to DEV + manual probe

**Files:** none (deploy + smoke).

- [ ] **Step 1: Push `dev` to GitHub**

```bash
cd ~/taler-id
git push origin dev
```

(Per CLAUDE.md feedback: work continues on `dev`; PROD merge to `main` happens later, only after explicit user approval.)

- [ ] **Step 2: SSH to DEV and pull + restart**

```bash
ssh dvolkov@89.169.55.217 'cd ~/taler-id && git checkout dev && git pull origin dev && npm run build && pm2 restart taler-id-dev'
```

Expected: PM2 reports `taler-id-dev` online.

- [ ] **Step 3: Manual probe via curl (initialization call)**

Use the test account from CLAUDE.md:

```bash
TOKEN=$(curl -s -X POST https://staging.id.taler.tirol/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"integration_test@taler-test.com","password":"IntegrationTest123!"}' \
  | jq -r .accessToken)

curl -s "https://staging.id.taler.tirol/messenger/sync" \
  -H "Authorization: Bearer $TOKEN" | jq .
```

Expected output shape:
```json
{ "messages": [], "nextCursor": "<iso-ts>|<uuid-or-empty>", "hasMore": false }
```

- [ ] **Step 4: Manual probe with stale cursor**

```bash
curl -s "https://staging.id.taler.tirol/messenger/sync?cursor=2020-01-01T00:00:00.000Z%7C&limit=5" \
  -H "Authorization: Bearer $TOKEN" | jq '.messages | length, .hasMore'
```

Expected: a number (likely 5), and `true` (hasMore).

- [ ] **Step 5: Commit nothing (deploy-only task)**

No commit needed.

---

## Task 5: Integration test (`taler_id_tests`)

**Files:**
- Create: `~/Downloads/taler_id_tests/sync_test.ts`
- Modify: `~/Downloads/taler_id_tests/package.json` — add `test:sync` and `test:sync:prod` scripts.

- [ ] **Step 1: Create `sync_test.ts`**

```typescript
// ~/Downloads/taler_id_tests/sync_test.ts
//
// E2E test for GET /messenger/sync.
// Run: npm run test:sync       (DEV)
//      npm run test:sync:prod  (PROD)

import { io, Socket } from 'socket.io-client';

const BASE_URL = process.env.BASE_URL ?? 'https://staging.id.taler.tirol';
const SENDER_EMAIL = 'integration_test@taler-test.com';
const SENDER_PASS = 'IntegrationTest123!';
const RECEIVER_EMAIL = 'integration_test_2@taler-test.com';
const RECEIVER_PASS = 'IntegrationTest123!';

interface SyncResult {
  messages: Array<{ id: string; conversationId: string; content: string | null }>;
  nextCursor: string | null;
  hasMore: boolean;
}

const results: { name: string; passed: boolean; error?: string }[] = [];

async function run(name: string, fn: () => Promise<void>) {
  try {
    await fn();
    results.push({ name, passed: true });
    console.log(`  ✓ ${name}`);
  } catch (e: any) {
    results.push({ name, passed: false, error: e.message });
    console.log(`  ✗ ${name}\n    ${e.message}`);
  }
}

function assert(cond: boolean, msg: string) {
  if (!cond) throw new Error(msg);
}

async function login(email: string, pass: string): Promise<string> {
  const res = await fetch(`${BASE_URL}/auth/login`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email, password: pass }),
  });
  if (!res.ok) throw new Error(`login ${email} failed: ${res.status}`);
  const data: any = await res.json();
  return data.accessToken;
}

async function connectSocket(token: string): Promise<Socket> {
  const socket: Socket = io(`${BASE_URL}/messenger`, {
    auth: { token },
    transports: ['websocket'],
    timeout: 10000,
  });
  await new Promise<void>((resolve, reject) => {
    const timer = setTimeout(() => {
      socket.disconnect();
      reject(new Error('Socket connection timeout (10s)'));
    }, 10000);
    socket.once('connect', () => {
      clearTimeout(timer);
      resolve();
    });
    socket.once('connect_error', (err: Error) => {
      clearTimeout(timer);
      reject(new Error(`Socket connect_error: ${err.message}`));
    });
  });
  return socket;
}

function sendMessage(
  socket: Socket,
  conversationId: string,
  content: string,
  clientId: string,
) {
  socket.emit('message', { conversationId, content, clientId });
}

async function getSync(token: string, cursor?: string, limit?: number): Promise<SyncResult> {
  const qs = new URLSearchParams();
  if (cursor) qs.set('cursor', cursor);
  if (limit) qs.set('limit', String(limit));
  const res = await fetch(`${BASE_URL}/messenger/sync?${qs}`, {
    headers: { Authorization: `Bearer ${token}` },
  });
  if (!res.ok) throw new Error(`sync failed: ${res.status}`);
  return res.json() as Promise<SyncResult>;
}

async function getConversations(token: string): Promise<any[]> {
  const res = await fetch(`${BASE_URL}/messenger/conversations`, {
    headers: { Authorization: `Bearer ${token}` },
  });
  const raw: any = await res.json();
  return Array.isArray(raw) ? raw : (raw.conversations ?? raw.data ?? []);
}

function findShared(conversations: any[], otherEmail: string): string | null {
  for (const c of conversations) {
    const parts = c.participants ?? [];
    if (parts.some((p: any) => p.user?.email === otherEmail)) return c.id;
  }
  return null;
}

async function main() {
  console.log(`Sync tests against ${BASE_URL}`);

  const senderToken = await login(SENDER_EMAIL, SENDER_PASS);
  const receiverToken = await login(RECEIVER_EMAIL, RECEIVER_PASS);

  const convs = await getConversations(receiverToken);
  const convId = findShared(convs, SENDER_EMAIL);
  if (!convId) throw new Error('no shared conversation between test users');

  const senderSock = await connectSocket(senderToken);
  senderSock.emit('join', { conversationId: convId });
  await new Promise((r) => setTimeout(r, 200));

  let initialCursor: string | null = null;
  const tag = `sync-${Date.now()}`;

  await run('1. initialization (no cursor) returns empty + cursor', async () => {
    const out = await getSync(receiverToken);
    assert(Array.isArray(out.messages) && out.messages.length === 0, 'messages empty');
    assert(out.hasMore === false, 'hasMore false');
    assert(typeof out.nextCursor === 'string', 'nextCursor is string');
    initialCursor = out.nextCursor;
  });

  await run('2. delta returns messages sent after cursor', async () => {
    for (let i = 0; i < 5; i++) {
      sendMessage(senderSock, convId, `${tag}-a-${i}`, `${tag}-a-${i}-c`);
    }
    await new Promise((r) => setTimeout(r, 1500)); // settle: socket → DB

    const out = await getSync(receiverToken, initialCursor!);
    const ours = out.messages.filter((m) => (m.content ?? '').startsWith(`${tag}-a-`));
    assert(ours.length === 5, `expected 5 of our messages, got ${ours.length}`);
    initialCursor = out.nextCursor;
  });

  await run('3. repeat sync with advanced cursor returns 0 of ours', async () => {
    const out = await getSync(receiverToken, initialCursor!);
    const ours = out.messages.filter((m) => (m.content ?? '').startsWith(`${tag}-a-`));
    assert(ours.length === 0, `expected 0, got ${ours.length}`);
  });

  await run('4. pagination: limit=2 with 5 messages → hasMore=true, full drain', async () => {
    const anchor = (await getSync(receiverToken)).nextCursor!;
    for (let i = 0; i < 5; i++) {
      sendMessage(senderSock, convId, `${tag}-p-${i}`, `${tag}-p-${i}-c`);
    }
    await new Promise((r) => setTimeout(r, 1500));

    let cursor: string | null = anchor;
    let totalSeen = 0;
    let pages = 0;
    while (true) {
      const out = await getSync(receiverToken, cursor!, 2);
      totalSeen += out.messages.filter((m) =>
        (m.content ?? '').startsWith(`${tag}-p-`),
      ).length;
      pages++;
      if (!out.hasMore) break;
      cursor = out.nextCursor;
      if (pages > 10) throw new Error('infinite pagination');
    }
    assert(totalSeen === 5, `expected 5 of our payloads, got ${totalSeen}`);
    assert(pages >= 3, `expected at least 3 pages, got ${pages}`);
  });

  senderSock.disconnect();

  const passed = results.filter((r) => r.passed).length;
  const failed = results.length - passed;
  console.log(`\n  ${passed}/${results.length} passed, ${failed} failed`);
  if (failed > 0) process.exit(1);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
```

- [ ] **Step 2: Verify the test compiles**

```bash
cd ~/Downloads/taler_id_tests
npx tsc --noEmit sync_test.ts
```

Expected: no errors.

- [ ] **Step 3: Register npm scripts**

Open `~/Downloads/taler_id_tests/package.json` and add the two scripts inside the `"scripts"` object (alongside `test:multi`):

```json
    "test:sync": "npx ts-node sync_test.ts",
    "test:sync:prod": "BASE_URL=https://id.taler.tirol npx ts-node sync_test.ts",
```

- [ ] **Step 4: Run the DEV test**

```bash
cd ~/Downloads/taler_id_tests
npm run test:sync
```

Expected: 4/4 passed.

- [ ] **Step 5: Skip commit**

`~/Downloads/taler_id_tests` is not a git repository. The new file simply
lives on disk and is run via the `test:sync` / `test:sync:prod` npm scripts.

---

## Task 6: Mobile — SyncCursorStorage (TDD)

**Files:**
- Create: `~/Downloads/taler_id_mobile/lib/core/storage/sync_cursor_storage.dart`
- Create: `~/Downloads/taler_id_mobile/test/core/storage/sync_cursor_storage_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
// test/core/storage/sync_cursor_storage_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:taler_id_mobile/core/storage/sync_cursor_storage.dart';

void main() {
  setUpAll(() async {
    await Hive.initFlutter('test-sync-cursor');
    await Hive.openBox<String>(SyncCursorStorage.boxName);
  });

  tearDown(() async {
    await Hive.box<String>(SyncCursorStorage.boxName).clear();
  });

  test('read returns null when no cursor stored', () async {
    final storage = SyncCursorStorage();
    expect(await storage.read(), isNull);
  });

  test('write then read returns the same value', () async {
    final storage = SyncCursorStorage();
    await storage.write('2026-05-13T10:00:00.000Z|abc-uuid');
    expect(await storage.read(), '2026-05-13T10:00:00.000Z|abc-uuid');
  });

  test('overwrite replaces the previous cursor', () async {
    final storage = SyncCursorStorage();
    await storage.write('A');
    await storage.write('B');
    expect(await storage.read(), 'B');
  });
}
```

- [ ] **Step 2: Run the test to verify it fails**

```bash
cd ~/Downloads/taler_id_mobile
flutter test test/core/storage/sync_cursor_storage_test.dart
```

Expected: FAIL — file `sync_cursor_storage.dart` does not exist.

- [ ] **Step 3: Implement `SyncCursorStorage`**

```dart
// lib/core/storage/sync_cursor_storage.dart
import 'package:hive_flutter/hive_flutter.dart';

class SyncCursorStorage {
  static const String boxName = 'messenger_sync';
  static const String _key = 'cursor';

  Future<String?> read() async {
    final box = Hive.box<String>(boxName);
    return box.get(_key);
  }

  Future<void> write(String cursor) async {
    final box = Hive.box<String>(boxName);
    await box.put(_key, cursor);
  }
}
```

- [ ] **Step 4: Run the test to verify it passes**

```bash
cd ~/Downloads/taler_id_mobile
flutter test test/core/storage/sync_cursor_storage_test.dart
```

Expected: 3/3 PASS.

- [ ] **Step 5: Commit**

```bash
cd ~/Downloads/taler_id_mobile
git add lib/core/storage/sync_cursor_storage.dart test/core/storage/sync_cursor_storage_test.dart
git commit -m "feat(storage): add SyncCursorStorage Hive wrapper"
```

---

## Task 7: Mobile — Open Hive box at startup + DI

**Files:**
- Modify: `~/Downloads/taler_id_mobile/lib/main.dart` — open the `messenger_sync` Hive box.
- Modify: `~/Downloads/taler_id_mobile/lib/core/di/service_locator.dart` — register `SyncCursorStorage` singleton.

- [ ] **Step 1: Find the Hive init section in `main.dart`**

Locate the existing `Hive.initFlutter()` / `Hive.openBox(...)` calls in `lib/main.dart` (search for `Hive.openBox`). Add the new box right after the existing messenger-related opens.

```dart
await Hive.openBox<String>(SyncCursorStorage.boxName);
```

Make sure to import:

```dart
import 'core/storage/sync_cursor_storage.dart';
```

- [ ] **Step 2: Register the storage in DI**

Open `lib/core/di/service_locator.dart` and add to the registrations section:

```dart
sl.registerLazySingleton<SyncCursorStorage>(() => SyncCursorStorage());
```

Import at the top:

```dart
import '../storage/sync_cursor_storage.dart';
```

- [ ] **Step 3: Build the app to ensure no errors**

```bash
cd ~/Downloads/taler_id_mobile
flutter analyze
```

Expected: no errors related to the change.

- [ ] **Step 4: Commit**

```bash
cd ~/Downloads/taler_id_mobile
git add lib/main.dart lib/core/di/service_locator.dart
git commit -m "feat(di): wire SyncCursorStorage and open Hive box on startup"
```

---

## Task 8: Mobile — SyncResult entity

**Files:**
- Create: `~/Downloads/taler_id_mobile/lib/features/messenger/domain/entities/sync_result.dart`

- [ ] **Step 1: Create the entity**

```dart
// lib/features/messenger/domain/entities/sync_result.dart
import 'message_entity.dart';

class SyncResult {
  final List<MessageEntity> messages;
  final String? nextCursor;
  final bool hasMore;

  const SyncResult({
    required this.messages,
    required this.nextCursor,
    required this.hasMore,
  });

  factory SyncResult.fromJson(Map<String, dynamic> json) {
    final raw = (json['messages'] as List?) ?? const [];
    return SyncResult(
      messages: raw
          .map((e) => MessageEntity.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      nextCursor: json['nextCursor'] as String?,
      hasMore: (json['hasMore'] as bool?) ?? false,
    );
  }
}
```

- [ ] **Step 2: Commit**

```bash
cd ~/Downloads/taler_id_mobile
git add lib/features/messenger/domain/entities/sync_result.dart
git commit -m "feat(messenger): add SyncResult entity"
```

---

## Task 9: Mobile — Datasource HTTP call

**Files:**
- Modify: `~/Downloads/taler_id_mobile/lib/features/messenger/data/datasources/messenger_remote_datasource.dart` — add `sync()` method.

- [ ] **Step 1: Add the import at the top of the file**

```dart
import '../../domain/entities/sync_result.dart';
```

- [ ] **Step 2: Add the `sync` method to the class**

Place after the existing public methods, before the close-bracket of the class:

```dart
  Future<SyncResult> sync({String? cursor, int limit = 200}) async {
    final qp = <String, dynamic>{'limit': limit};
    if (cursor != null) qp['cursor'] = cursor;
    final res = await _http.dio.get<Map<String, dynamic>>(
      '/messenger/sync',
      queryParameters: qp,
    );
    return SyncResult.fromJson(res.data ?? const {});
  }
```

- [ ] **Step 3: Verify with analyze**

```bash
cd ~/Downloads/taler_id_mobile
flutter analyze lib/features/messenger/data/datasources/messenger_remote_datasource.dart
```

Expected: no errors.

- [ ] **Step 4: Commit**

```bash
cd ~/Downloads/taler_id_mobile
git add lib/features/messenger/data/datasources/messenger_remote_datasource.dart
git commit -m "feat(messenger): add datasource.sync HTTP call"
```

---

## Task 10: Mobile — Repository passthrough

**Files:**
- Modify: `~/Downloads/taler_id_mobile/lib/features/messenger/domain/repositories/i_messenger_repository.dart`
- Modify: `~/Downloads/taler_id_mobile/lib/features/messenger/data/repositories/messenger_repository_impl.dart`

- [ ] **Step 1: Add the abstract method to the interface**

In `i_messenger_repository.dart`, add the import and method (near the other `Future<…>` declarations, e.g. after `getMessages`):

```dart
import '../entities/sync_result.dart';
```

```dart
  Future<SyncResult> sync({String? cursor, int limit});
```

- [ ] **Step 2: Implement in the impl class**

In `messenger_repository_impl.dart`, add the import and method:

```dart
import '../../domain/entities/sync_result.dart';
```

```dart
  @override
  Future<SyncResult> sync({String? cursor, int limit = 200}) {
    return _remote.sync(cursor: cursor, limit: limit);
  }
```

- [ ] **Step 3: Verify with analyze**

```bash
cd ~/Downloads/taler_id_mobile
flutter analyze lib/features/messenger
```

Expected: no errors.

- [ ] **Step 4: Commit**

```bash
cd ~/Downloads/taler_id_mobile
git add lib/features/messenger/domain/repositories/i_messenger_repository.dart lib/features/messenger/data/repositories/messenger_repository_impl.dart
git commit -m "feat(messenger): repo passthrough for sync"
```

---

## Task 11: Mobile — Bloc event

**Files:**
- Modify: `~/Downloads/taler_id_mobile/lib/features/messenger/presentation/bloc/messenger_event.dart` — add `SyncMessagesRequested`.

- [ ] **Step 1: Add the event class**

At the bottom of `messenger_event.dart`, after the last existing event class, add:

```dart
class SyncMessagesRequested extends MessengerEvent {
  const SyncMessagesRequested();
}
```

(`MessengerEvent` is the abstract `Equatable` base used by all events in this file; the parent's `props => []` is inherited.)

- [ ] **Step 2: Verify with analyze**

```bash
cd ~/Downloads/taler_id_mobile
flutter analyze lib/features/messenger/presentation/bloc/messenger_event.dart
```

Expected: no errors.

- [ ] **Step 3: Commit**

```bash
cd ~/Downloads/taler_id_mobile
git add lib/features/messenger/presentation/bloc/messenger_event.dart
git commit -m "feat(messenger): add SyncMessagesRequested event"
```

---

## Task 12: Mobile — Bloc handler (TDD)

**Files:**
- Create: `~/Downloads/taler_id_mobile/test/features/messenger/presentation/bloc/messenger_bloc_sync_test.dart`
- Modify: `~/Downloads/taler_id_mobile/lib/features/messenger/presentation/bloc/messenger_bloc.dart` — add `_onSyncMessages` handler.

- [ ] **Step 1: Write a failing test that drives a successful sync**

Use the same DI setup pattern as `messenger_bloc_dedup_test.dart` (open that file for reference on `_FakeCache`, `_FakePending`, `_StubRepo` plumbing).

Create the test file:

```dart
// test/features/messenger/presentation/bloc/messenger_bloc_sync_test.dart
import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mocktail/mocktail.dart';

import 'package:taler_id_mobile/core/di/service_locator.dart';
import 'package:taler_id_mobile/core/services/messenger_cache_service.dart';
import 'package:taler_id_mobile/core/services/pending_message_service.dart';
import 'package:taler_id_mobile/core/storage/sync_cursor_storage.dart';
import 'package:taler_id_mobile/features/messenger/data/services/pending_mesh_send_queue.dart';
import 'package:taler_id_mobile/features/messenger/domain/entities/message_entity.dart';
import 'package:taler_id_mobile/features/messenger/domain/entities/sync_result.dart';
import 'package:taler_id_mobile/features/messenger/domain/repositories/i_messenger_repository.dart';
import 'package:taler_id_mobile/features/messenger/presentation/bloc/messenger_bloc.dart';
import 'package:taler_id_mobile/features/messenger/presentation/bloc/messenger_event.dart';

class _StubRepo extends Mock implements IMessengerRepository {}
class _FakeCache implements MessengerCacheService {
  @override
  List<Map<String, dynamic>>? getMessages(String conversationId) => null;
  @override
  List<Map<String, dynamic>> getMeshMessagesFor(String c) => const [];
  @override
  Future<void> appendMessage(String c, Map<String, dynamic> m) async {}
  @override
  dynamic noSuchMethod(Invocation i) => null;
}
class _FakePending implements PendingMessageService {
  @override
  dynamic noSuchMethod(Invocation i) => null;
}

Stream<T> _empty<T>() => const Stream.empty();

MessageEntity _msg(String id, String conv, DateTime sentAt) => MessageEntity(
      id: id,
      conversationId: conv,
      senderId: 'other-user',
      content: 'hi $id',
      sentAt: sentAt,
      isSystem: false,
      isEdited: false,
      isDelivered: true,
      isRead: false,
      reactions: const [],
    );

void main() {
  setUpAll(() async {
    await Hive.initFlutter('test-bloc-sync');
    await Hive.openBox<String>(SyncCursorStorage.boxName);
    if (!sl.isRegistered<MessengerCacheService>()) {
      sl.registerSingleton<MessengerCacheService>(_FakeCache());
    }
    if (!sl.isRegistered<PendingMessageService>()) {
      sl.registerSingleton<PendingMessageService>(_FakePending());
    }
    if (!sl.isRegistered<PendingMeshSendQueue>()) {
      sl.registerSingleton<PendingMeshSendQueue>(PendingMeshSendQueue());
    }
    if (!sl.isRegistered<SyncCursorStorage>()) {
      sl.registerSingleton<SyncCursorStorage>(SyncCursorStorage());
    }
  });

  late _StubRepo repo;

  setUp(() async {
    repo = _StubRepo();
    when(() => repo.messageStream).thenAnswer((_) => _empty());
    when(() => repo.callInviteStream).thenAnswer((_) => _empty());
    when(() => repo.messageUpdatedStream).thenAnswer((_) => _empty());
    when(() => repo.messageDeletedStream).thenAnswer((_) => _empty());
    when(() => repo.messagesReadStream).thenAnswer((_) => _empty());
    when(() => repo.groupUpdatedStream).thenAnswer((_) => _empty());
    when(() => repo.groupMemberAddedStream).thenAnswer((_) => _empty());
    when(() => repo.groupMemberRemovedStream).thenAnswer((_) => _empty());
    when(() => repo.groupRoleChangedStream).thenAnswer((_) => _empty());
    when(() => repo.groupCreatedStream).thenAnswer((_) => _empty());
    when(() => repo.groupDeletedStream).thenAnswer((_) => _empty());
    when(() => repo.groupCallStartedStream).thenAnswer((_) => _empty());
    when(() => repo.groupCallEndedStream).thenAnswer((_) => _empty());
    when(() => repo.typingStream).thenAnswer((_) => _empty());
    when(() => repo.contactRequestStream).thenAnswer((_) => _empty());
    when(() => repo.contactAcceptedStream).thenAnswer((_) => _empty());
    when(() => repo.reactionUpdatedStream).thenAnswer((_) => _empty());
    when(() => repo.socketErrorStream).thenAnswer((_) => _empty());
    when(() => repo.analystChunkStream).thenAnswer((_) => _empty());
    when(() => repo.analystSeamStream).thenAnswer((_) => _empty());
    when(() => repo.meshMessageStream).thenAnswer((_) => _empty());
    when(() => repo.meshOutboundStream).thenAnswer((_) => _empty());
    when(() => repo.messageAckedStream).thenAnswer((_) => _empty());
    when(() => repo.reconnectStream).thenAnswer((_) => _empty());
    when(() => repo.disconnectStream).thenAnswer((_) => _empty());

    await Hive.box<String>(SyncCursorStorage.boxName).clear();
  });

  test('initialization (no stored cursor) calls sync() without cursor and stores result', () async {
    when(() => repo.sync(limit: any(named: 'limit'))).thenAnswer((_) async =>
        const SyncResult(messages: [], nextCursor: '2026-05-13T10:00:00.000Z|init', hasMore: false));

    final bloc = MessengerBloc(repo);
    bloc.add(const SyncMessagesRequested());
    await Future<void>.delayed(const Duration(milliseconds: 50));

    verify(() => repo.sync(limit: 200)).called(1);
    expect(await sl<SyncCursorStorage>().read(), '2026-05-13T10:00:00.000Z|init');
    await bloc.close();
  });

  test('delta sync paginates until hasMore=false, dispatching MessageReceived per row', () async {
    await sl<SyncCursorStorage>().write('2026-05-13T09:00:00.000Z|start');

    final p1 = SyncResult(
      messages: [
        _msg('m1', 'conv-1', DateTime.parse('2026-05-13T10:01:00Z')),
        _msg('m2', 'conv-1', DateTime.parse('2026-05-13T10:02:00Z')),
      ],
      nextCursor: '2026-05-13T10:02:00.000Z|m2',
      hasMore: true,
    );
    final p2 = SyncResult(
      messages: [
        _msg('m3', 'conv-1', DateTime.parse('2026-05-13T10:03:00Z')),
      ],
      nextCursor: '2026-05-13T10:03:00.000Z|m3',
      hasMore: false,
    );
    when(() => repo.sync(cursor: any(named: 'cursor'), limit: any(named: 'limit')))
        .thenAnswer((inv) async {
      final cur = inv.namedArguments[#cursor] as String?;
      return cur == '2026-05-13T09:00:00.000Z|start' ? p1 : p2;
    });

    final bloc = MessengerBloc(repo);
    bloc.add(const SyncMessagesRequested());
    await Future<void>.delayed(const Duration(milliseconds: 100));

    expect(bloc.state.messages['conv-1']?.map((m) => m.id).toList(),
        ['m1', 'm2', 'm3']);
    expect(await sl<SyncCursorStorage>().read(), '2026-05-13T10:03:00.000Z|m3');
    await bloc.close();
  });

  test('overlapping live MessageReceived + sync delivery dedups by msg.id', () async {
    await sl<SyncCursorStorage>().write('2026-05-13T09:00:00.000Z|start');
    final shared = _msg('m1', 'conv-1', DateTime.parse('2026-05-13T10:01:00Z'));
    when(() => repo.sync(cursor: any(named: 'cursor'), limit: any(named: 'limit')))
        .thenAnswer((_) async => SyncResult(
            messages: [shared],
            nextCursor: '2026-05-13T10:01:00.000Z|m1',
            hasMore: false));

    final bloc = MessengerBloc(repo);
    bloc.add(MessageReceived(shared));
    bloc.add(const SyncMessagesRequested());
    await Future<void>.delayed(const Duration(milliseconds: 100));

    expect(bloc.state.messages['conv-1']?.length, 1);
    await bloc.close();
  });
}
```

- [ ] **Step 2: Run the test to verify it fails**

```bash
cd ~/Downloads/taler_id_mobile
flutter test test/features/messenger/presentation/bloc/messenger_bloc_sync_test.dart
```

Expected: FAIL — `SyncMessagesRequested` handler not registered (`Invalid event`); or compile error if `repo.sync` mock missing.

- [ ] **Step 3: Add the `_SyncCursorStorage` field and import to the bloc**

In `lib/features/messenger/presentation/bloc/messenger_bloc.dart` near the top imports:

```dart
import '../../../../core/storage/sync_cursor_storage.dart';
import '../../domain/entities/sync_result.dart';
```

Inside the class, add a private field and guard:

```dart
  final SyncCursorStorage _syncCursorStorage = sl<SyncCursorStorage>();
  bool _syncInProgress = false;
```

- [ ] **Step 4: Register the event handler in the constructor**

Inside the bloc constructor (near other `on<...>` calls around line 75-115):

```dart
    on<SyncMessagesRequested>(_onSyncMessages);
```

- [ ] **Step 5: Implement `_onSyncMessages`**

Add this method to the `MessengerBloc` class:

```dart
  Future<void> _onSyncMessages(
    SyncMessagesRequested event,
    Emitter<MessengerState> emit,
  ) async {
    if (_syncInProgress) return;
    _syncInProgress = true;
    try {
      var cursor = await _syncCursorStorage.read();
      if (cursor == null) {
        final init = await _repo.sync(limit: 200);
        if (init.nextCursor != null) {
          await _syncCursorStorage.write(init.nextCursor!);
        }
        return;
      }
      for (var page = 0; page < 10; page++) {
        final SyncResult res = await _repo.sync(cursor: cursor, limit: 200);
        for (final m in res.messages) {
          add(MessageReceived(m));
        }
        if (res.nextCursor != null) {
          cursor = res.nextCursor!;
          await _syncCursorStorage.write(cursor!);
        }
        if (!res.hasMore) break;
      }
    } catch (e) {
      debugPrint('[messenger-sync] failed: $e');
    } finally {
      _syncInProgress = false;
    }
  }
```

- [ ] **Step 6: Run the tests — they should pass**

```bash
cd ~/Downloads/taler_id_mobile
flutter test test/features/messenger/presentation/bloc/messenger_bloc_sync_test.dart
```

Expected: 3/3 PASS.

- [ ] **Step 7: Commit**

```bash
cd ~/Downloads/taler_id_mobile
git add lib/features/messenger/presentation/bloc/messenger_bloc.dart test/features/messenger/presentation/bloc/messenger_bloc_sync_test.dart
git commit -m "feat(messenger): bloc handler for SyncMessagesRequested with pagination"
```

---

## Task 13: Mobile — Trigger sync on connect + reconnect

**Files:**
- Modify: `~/Downloads/taler_id_mobile/lib/features/messenger/presentation/bloc/messenger_bloc.dart`

- [ ] **Step 1: Trigger after initial connect**

Find `_onConnect(ConnectMessenger event, ...)` at `messenger_bloc.dart:138-140`. After the call to `_resendPending();` (which follows `await _repo.connect(...)`), add:

```dart
    add(const SyncMessagesRequested());
```

- [ ] **Step 2: Trigger inside the reconnect listener**

Find the reconnect listener at `messenger_bloc.dart:145-149`. Inside the listener body, after the existing `_resendPending(); _refreshMeshContactKeys();`, add:

```dart
      add(const SyncMessagesRequested());
```

- [ ] **Step 3: Run the existing dedup / mesh bloc tests to ensure no regression**

```bash
cd ~/Downloads/taler_id_mobile
flutter test test/features/messenger/presentation/bloc/
```

Expected: all existing bloc tests still pass plus the 3 new sync tests.

- [ ] **Step 4: Commit**

```bash
cd ~/Downloads/taler_id_mobile
git add lib/features/messenger/presentation/bloc/messenger_bloc.dart
git commit -m "feat(messenger): dispatch SyncMessagesRequested on socket connect + reconnect"
```

---

## Task 14: Mobile — Trigger sync on app resume (lifecycle observer)

**Files:**
- Modify: `~/Downloads/taler_id_mobile/lib/features/messenger/presentation/bloc/messenger_bloc.dart`

- [ ] **Step 1: Add WidgetsBindingObserver mixin**

Find the class declaration `class MessengerBloc extends Bloc<MessengerEvent, MessengerState>` and change it to:

```dart
class MessengerBloc extends Bloc<MessengerEvent, MessengerState>
    with WidgetsBindingObserver {
```

Ensure the import is present at the top:

```dart
import 'package:flutter/widgets.dart';
```

- [ ] **Step 2: Register the observer in the constructor**

At the end of the constructor body, add:

```dart
    WidgetsBinding.instance.addObserver(this);
```

- [ ] **Step 3: Implement didChangeAppLifecycleState**

Add this method to the class:

```dart
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      add(const SyncMessagesRequested());
    }
  }
```

- [ ] **Step 4: Remove observer in close()**

In the existing `close()` method (around `messenger_bloc.dart:1120-1148`), add as the first line:

```dart
    WidgetsBinding.instance.removeObserver(this);
```

- [ ] **Step 5: Run all messenger bloc tests**

```bash
cd ~/Downloads/taler_id_mobile
flutter test test/features/messenger/presentation/bloc/
```

Expected: all pass.

- [ ] **Step 6: Commit**

```bash
cd ~/Downloads/taler_id_mobile
git add lib/features/messenger/presentation/bloc/messenger_bloc.dart
git commit -m "feat(messenger): trigger sync on app resume via WidgetsBindingObserver"
```

---

## Task 15: Hardware smoke (mandatory before main)

**Files:** none.

- [ ] **Step 1: Build dev APK locally and install on a wired Android**

```bash
cd ~/Downloads/taler_id_mobile
flutter run --flavor dev -t lib/main_dev.dart \
  --dart-define=FLAVOR=dev --dart-define=BASE_URL=https://staging.id.taler.tirol \
  -d <android-device-id>
```

(Replace `<android-device-id>` with the output of `adb devices`.)

- [ ] **Step 2: Reproduce the AI-Outbound delivery scenario**

1. Log in as `integration_test@taler-test.com`.
2. Open the AI Outbound chat.
3. Start a campaign (e.g. ask the bot to find a service); confirm "Начинай".
4. While bot is running, press the home button to background the app.
5. Wait until the bot would normally post 2+ messages (1-2 minutes).
6. Foreground the app.

Expected: on resume, the conversations list shows the new preview and unread count; opening the chat reveals the missed bot messages in order.

- [ ] **Step 3: Reproduce the AI-Analyst scenario**

1. Open a conversation that has AI Analyst.
2. Ask a long question.
3. Background the app immediately.
4. Wait 30-60 seconds.
5. Foreground.

Expected: the final analyst response is present in the chat (or arrives within seconds of foregrounding via the live socket).

- [ ] **Step 4: Reproduce the plain offline scenario**

1. Enable airplane mode.
2. Have a second device send 3 messages to this user.
3. Disable airplane mode (force the socket to reconnect).

Expected: within 2-3 seconds of reconnect, the 3 messages appear in the conversation.

- [ ] **Step 5: Document any failures**

If any step fails, file findings in `~/Downloads/taler_id_mobile/docs/superpowers/specs/2026-05-13-messenger-sync-design.md` under a new "Smoke results" section and DO NOT merge.

---

## Task 16: Deploy mobile dev branch

**Files:** none.

- [ ] **Step 1: Push to `dev` branch on GitHub**

```bash
cd ~/Downloads/taler_id_mobile
git push origin dev
```

- [ ] **Step 2: Build dev APK on the PROD server (per CLAUDE.md APK build flow)**

```bash
ssh dvolkov@138.124.61.221
cd ~/taler_id_mobile && git checkout dev && git pull
flutter build apk --flavor dev --release -t lib/main_dev.dart \
  --dart-define=FLAVOR=dev --dart-define=BASE_URL=https://staging.id.taler.tirol
sudo cp build/app/outputs/flutter-apk/app-dev-release.apk /var/www/downloads/taler-id-dev.apk
```

- [ ] **Step 3: Send dev APK link to test devices**

URL: https://id.taler.tirol/download/taler-id-dev.apk

- [ ] **Step 4: Run all DEV API tests to confirm no backend regressions**

```bash
cd ~/Downloads/taler_id_tests
npm test && npm run test:sync
```

Expected: all green.

---

## Task 17: STOP — wait for explicit user approval before PROD

Per CLAUDE.md: "На PROD переносить ТОЛЬКО при явном указании пользователя."

- [ ] **Step 1: Report DEV results and ask for PROD go-ahead**

Post a summary to the user:
- Backend deployed to DEV, manual probe succeeded.
- Mobile dev APK built, hardware smoke for AI-Outbound + AI-Analyst + plain offline passed.
- All DEV tests green: API smoke, sync, files, channels, billing, voice, assistant.

Then ask: "Готов к деплою на PROD?"

**Do not proceed to PROD without an explicit "да" / "go" / equivalent from the user.**

---

## Task 18: Deploy to PROD (only after explicit user approval)

**Files:** none.

- [ ] **Step 1: Backend to PROD**

```bash
ssh dvolkov@138.124.61.221 'cd ~/taler-id && git pull && npm run build && pm2 restart taler-id'
```

- [ ] **Step 2: Build PROD APK**

```bash
ssh dvolkov@138.124.61.221
cd ~/taler_id_mobile && git checkout main && git merge dev && git push origin main
flutter build apk --flavor prod --release --dart-define=FLAVOR=prod
sudo cp build/app/outputs/flutter-apk/app-prod-release.apk /var/www/downloads/taler-id.apk
```

- [ ] **Step 3: Build PROD iOS IPA + upload to TestFlight**

Locally on Mac (per CLAUDE.md iOS flow):

```bash
cd ~/Downloads/taler_id_mobile
git checkout main && git pull
flutter build ipa --release --export-options-plist ios/ExportOptions.plist
xcrun altool --upload-app --type ios -f build/ios/ipa/*.ipa \
  --apiKey J3P22V4URD --apiIssuer 44b87272-3052-40ea-a48a-6c6f88a2df11
```

Set TestFlight release notes in Russian using the existing `/tmp/set_testflight_notes.py` template (per CLAUDE.md: "ОБЯЗАТЕЛЬНО после загрузки в TestFlight").

- [ ] **Step 4: Run the full PROD test suite**

```bash
cd ~/Downloads/taler_id_tests
npm run test:prod && npm run test:sync:prod && npm run test:voice:prod \
  && npm run test:assistant:prod && npm run test:files:prod \
  && npm run test:channels:prod && npm run test:billing:prod
```

Expected: all green.

---

## Spec coverage check (self-review)

Run after the final task is checked off, before reporting completion.

| Spec section / requirement | Implemented in task |
|---|---|
| `GET /messenger/sync` with optional cursor + limit | Task 3 |
| Server returns `messages` / `nextCursor` / `hasMore` | Task 2 |
| Initialization branch returns server-current cursor | Task 2, Step 3 |
| Row-value comparison `(sentAt, id) > (?, ?)` via `$queryRaw` | Task 2, Step 7 |
| Scope to user's conversations via `ConversationParticipant` join | Task 2, Step 7 |
| `MessageEntity`-shape response (senderName, reactions) | Task 2, Step 7 (enrichment) |
| Backend unit tests (init / delta / pagination) | Task 2, Steps 1+5 |
| API integration test (`test:sync`, `test:sync:prod`) | Task 5 |
| Hive cursor storage with safe load/save | Task 6, Task 7 |
| Bloc handler with `_syncInProgress` guard + 10-page cap | Task 12 |
| Trigger on socket connect | Task 13, Step 1 |
| Trigger on socket reconnect | Task 13, Step 2 |
| Trigger on `AppLifecycleState.resumed` | Task 14 |
| Existing `MessageReceived` handles dedup + cache | (uses existing code, verified in Task 12 dedup test) |
| Hardware smoke (AI Outbound + AI Analyst + plain offline) | Task 15 |
| DEV before PROD | Tasks 4, 16, 17, 18 |
| PROD only on explicit user approval | Task 17 (gate) |

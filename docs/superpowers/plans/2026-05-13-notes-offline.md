# Notes Offline (CRUD + OCC) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add full offline CRUD to the Notes feature (create / update / delete while offline, sync on reconnect, surface conflicts via OCC), plus a reusable outbox infrastructure that will be applied to calendar / contacts / favorites later.

**Architecture:** Client-side: a generic `OutboxQueue` (Hive) holds pending operations; an `OutboxReplayService` drains it on connectivity change / socket reconnect / app resume; per-feature `OutboxReplayHandler`s map ops to HTTP calls and handle conflicts. Notes-specific: a local Hive box (`notes_local`) is the rendering source of truth; `NotesRepositoryImpl` orchestrates local writes + outbox enqueue + refresh. Server-side: `POST /notes` accepts an optional client-supplied `id` (idempotent retry); `PATCH /notes/:id` accepts an optional `expectedUpdatedAt` (HTTP 409 on stale).

**Tech Stack:** NestJS + Prisma + PostgreSQL on the server. Flutter + Hive + Freezed + connectivity_plus on the client. Jest for backend unit tests; `ts-node` integration tests in `taler_id_tests`; `flutter_test` + `mocktail` for mobile.

**Spec:** `docs/superpowers/specs/2026-05-13-notes-offline-design.md`

**Repos:**
- Backend: `~/taler-id/` (work on `dev` branch)
- Mobile: `~/Downloads/taler_id_mobile/` (work on `dev` branch)
- Integration tests: `~/Downloads/taler_id_tests/` (not a git repo — no commits)

---

## File Structure

### Backend (`taler-id`)

- **Modify** `src/notes/notes.service.ts` — `create(userId, {id?,...})` accepts optional `id`, idempotent; `update(...)` accepts `expectedUpdatedAt`, throws `ConflictException` on stale.
- **Modify** `src/notes/notes.controller.ts` — pass new optional body fields through.
- **Create** `src/notes/notes.service.spec.ts` — unit tests for create + update OCC semantics.

### Integration tests (`taler_id_tests`)

- **Create** `notes_offline_test.ts` — E2E API test.
- **Modify** `package.json` — register `test:notes:offline` + `:prod` scripts.

### Mobile core infrastructure (`taler_id_mobile`)

- **Create** `lib/core/storage/outbox_op.dart` — Freezed `OutboxOp` model + `OutboxOpStatus` enum + `OutboxReplayResult` sealed type.
- **Create** `lib/core/storage/outbox_queue.dart` — `OutboxQueue` Hive wrapper.
- **Create** `lib/core/services/outbox_replay_service.dart` — `OutboxReplayService` (drain loop, registry).
- **Create** `lib/core/services/outbox_replay_handler.dart` — abstract interface (in a separate file from the service for tidy imports).
- **Create** `lib/core/services/connectivity_watcher.dart` — wraps `connectivity_plus`, triggers drain on transitions.
- **Create** `test/core/storage/outbox_queue_test.dart`.
- **Create** `test/core/services/outbox_replay_service_test.dart`.

### Mobile notes feature

- **Create** `lib/features/notes/domain/entities/note_entity.dart` — Freezed `NoteEntity` + `NoteSource` enum + `ConflictResolution` enum.
- **Create** `lib/features/notes/domain/repositories/i_notes_repository.dart`.
- **Create** `lib/features/notes/data/datasources/notes_local_datasource.dart` — Hive box `notes_local`.
- **Modify** `lib/features/notes/data/datasources/notes_remote_datasource.dart` — add optional `id` to `create`, `expectedUpdatedAt` to `update`; throw `NoteConflictException` on 409.
- **Create** `lib/features/notes/data/repositories/notes_repository_impl.dart`.
- **Create** `lib/features/notes/data/services/notes_outbox_replay_handler.dart`.
- **Modify** `lib/features/notes/presentation/screens/notes_screen.dart` — wire repo, show pending dot + conflict banner.
- **Create** `lib/features/notes/presentation/widgets/conflict_resolution_dialog.dart`.
- **Modify** `lib/core/di/service_locator.dart` — open `outbox_v1` + `notes_local` boxes; register new services and handlers.
- **Create** mirroring test files (see individual tasks).

---

## Task 1: Backend — DTOs and types

**Files:**
- Modify: `~/taler-id/src/notes/notes.controller.ts` — accept new optional body fields.

- [ ] **Step 0: Switch backend repo to `dev`**

```bash
cd ~/taler-id
git checkout dev && git pull origin dev
```

- [ ] **Step 1: Widen the create + update body shapes**

In `src/notes/notes.controller.ts`, change the two relevant methods:

```typescript
  @Post()
  create(
    @CurrentUser() user: any,
    @Body() body: { id?: string; title: string; content: string; source?: string },
  ) {
    return this.service.create(user.sub, body);
  }

  @Patch(':id')
  update(
    @CurrentUser() user: any,
    @Param('id') id: string,
    @Body() body: { title?: string; content?: string; expectedUpdatedAt?: string },
  ) {
    return this.service.update(user.sub, id, body);
  }
```

(No new file. The DTOs in this controller are inline-typed maps following the existing convention.)

- [ ] **Step 2: Build to confirm no type errors**

```bash
cd ~/taler-id
npm run build
```

Expected: build succeeds. (Service signatures will be widened in Task 2; meanwhile TypeScript may complain about unknown keys — that's OK, fixed in next task.)

- [ ] **Step 3: Commit**

```bash
cd ~/taler-id
git add src/notes/notes.controller.ts
git commit -m "$(cat <<'EOF'
feat(notes): controller accepts id (create) + expectedUpdatedAt (update)

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 2: Backend — `create` accepts optional id (TDD)

**Files:**
- Modify: `~/taler-id/src/notes/notes.service.ts`
- Create: `~/taler-id/src/notes/notes.service.spec.ts`

- [ ] **Step 1: Write the failing tests for create-with-id**

Create `src/notes/notes.service.spec.ts`:

```typescript
import { Test } from '@nestjs/testing';
import { NotesService } from './notes.service';
import { PrismaService } from '../prisma/prisma.service';
import { ConflictException } from '@nestjs/common';

describe('NotesService.create', () => {
  let service: NotesService;
  let prisma: { note: { create: jest.Mock; findUnique: jest.Mock } };

  beforeEach(async () => {
    prisma = {
      note: {
        create: jest.fn(),
        findUnique: jest.fn(),
      },
    };
    const mod = await Test.createTestingModule({
      providers: [
        NotesService,
        { provide: PrismaService, useValue: prisma },
      ],
    }).compile();
    service = mod.get(NotesService);
  });

  it('without id: generates uuid as before', async () => {
    prisma.note.create.mockResolvedValue({ id: 'generated', userId: 'u1', title: 't', content: 'c' });
    await service.create('u1', { title: 't', content: 'c' });
    expect(prisma.note.create).toHaveBeenCalledWith({
      data: expect.objectContaining({ userId: 'u1', title: 't', content: 'c' }),
    });
    // The data should NOT contain an id (Prisma default kicks in).
    const arg = prisma.note.create.mock.calls[0][0].data;
    expect(arg.id).toBeUndefined();
  });

  it('with id: passes the id through to Prisma', async () => {
    prisma.note.findUnique.mockResolvedValue(null);
    prisma.note.create.mockResolvedValue({ id: 'mine-uuid', userId: 'u1', title: 't', content: 'c' });
    const result = await service.create('u1', { id: 'mine-uuid', title: 't', content: 'c' });
    expect(prisma.note.create).toHaveBeenCalledWith({
      data: expect.objectContaining({ id: 'mine-uuid', userId: 'u1', title: 't', content: 'c' }),
    });
    expect(result.id).toBe('mine-uuid');
  });

  it('with id of an existing note owned by same user: returns existing (idempotent), no double-create', async () => {
    prisma.note.findUnique.mockResolvedValue({ id: 'mine-uuid', userId: 'u1', title: 'orig', content: 'orig' });
    const result = await service.create('u1', { id: 'mine-uuid', title: 'new', content: 'new' });
    expect(prisma.note.create).not.toHaveBeenCalled();
    expect(result).toEqual({ id: 'mine-uuid', userId: 'u1', title: 'orig', content: 'orig' });
  });

  it('with id of a note owned by another user: throws ConflictException', async () => {
    prisma.note.findUnique.mockResolvedValue({ id: 'theirs', userId: 'other', title: 't', content: 'c' });
    await expect(service.create('u1', { id: 'theirs', title: 't', content: 'c' })).rejects.toBeInstanceOf(ConflictException);
    expect(prisma.note.create).not.toHaveBeenCalled();
  });
});
```

- [ ] **Step 2: Run tests — should FAIL**

```bash
cd ~/taler-id
npx jest src/notes/notes.service.spec.ts --no-coverage
```

Expected: 4 FAIL (service.create signature does not accept id; idempotent path missing).

- [ ] **Step 3: Update `notes.service.ts` create method**

Replace the existing `create` method with:

```typescript
  async create(
    userId: string,
    data: { id?: string; title: string; content: string; source?: string },
  ) {
    if (data.id) {
      const existing = await this.prisma.note.findUnique({ where: { id: data.id } });
      if (existing) {
        if (existing.userId !== userId) {
          throw new ConflictException('Note id already used by another account');
        }
        return existing;
      }
    }
    return this.prisma.note.create({
      data: {
        ...(data.id ? { id: data.id } : {}),
        userId,
        title: data.title,
        content: data.content,
        source: (data.source as any) || 'MANUAL',
      },
    });
  }
```

Add the import at the top of the file (alongside `NotFoundException`, `ForbiddenException`):

```typescript
import {
  Injectable,
  NotFoundException,
  ForbiddenException,
  ConflictException,
} from '@nestjs/common';
```

- [ ] **Step 4: Run tests — should PASS (4/4)**

```bash
cd ~/taler-id
npx jest src/notes/notes.service.spec.ts --no-coverage
```

Expected: 4/4 PASS.

- [ ] **Step 5: Commit**

```bash
cd ~/taler-id
git add src/notes/notes.service.ts src/notes/notes.service.spec.ts
git commit -m "$(cat <<'EOF'
feat(notes): create accepts optional client-supplied id (idempotent)

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 3: Backend — `update` with optimistic concurrency control (TDD)

**Files:**
- Modify: `~/taler-id/src/notes/notes.service.ts` — extend `update`.
- Modify: `~/taler-id/src/notes/notes.service.spec.ts` — add `describe('NotesService.update', …)`.

- [ ] **Step 1: Append the failing update tests**

In `src/notes/notes.service.spec.ts`, append after the existing `describe('NotesService.create', …)`:

```typescript
describe('NotesService.update', () => {
  let service: NotesService;
  let prisma: { note: { findUnique: jest.Mock; update: jest.Mock } };

  beforeEach(async () => {
    prisma = {
      note: {
        findUnique: jest.fn(),
        update: jest.fn(),
      },
    };
    const mod = await Test.createTestingModule({
      providers: [
        NotesService,
        { provide: PrismaService, useValue: prisma },
      ],
    }).compile();
    service = mod.get(NotesService);
  });

  it('without expectedUpdatedAt: applies update (LWW, back-compat)', async () => {
    const now = new Date('2026-05-13T10:00:00Z');
    prisma.note.findUnique.mockResolvedValue({ id: 'n1', userId: 'u1', updatedAt: now });
    prisma.note.update.mockResolvedValue({ id: 'n1', userId: 'u1', title: 'new' });
    const out = await service.update('u1', 'n1', { title: 'new' });
    expect(prisma.note.update).toHaveBeenCalledWith({ where: { id: 'n1' }, data: { title: 'new' } });
    expect(out.title).toBe('new');
  });

  it('with matching expectedUpdatedAt: applies update', async () => {
    const now = new Date('2026-05-13T10:00:00Z');
    prisma.note.findUnique.mockResolvedValue({ id: 'n1', userId: 'u1', updatedAt: now });
    prisma.note.update.mockResolvedValue({ id: 'n1', userId: 'u1', title: 'new' });
    const out = await service.update('u1', 'n1', { title: 'new', expectedUpdatedAt: now.toISOString() });
    expect(prisma.note.update).toHaveBeenCalled();
    expect(out.title).toBe('new');
  });

  it('with stale expectedUpdatedAt: throws ConflictException with currentNote in payload', async () => {
    const dbTime = new Date('2026-05-13T10:05:00Z');
    const clientThought = new Date('2026-05-13T10:00:00Z').toISOString();
    const current = { id: 'n1', userId: 'u1', updatedAt: dbTime, title: 'on server' };
    prisma.note.findUnique.mockResolvedValue(current);
    let thrown: any;
    try {
      await service.update('u1', 'n1', { title: 'mine', expectedUpdatedAt: clientThought });
    } catch (e) {
      thrown = e;
    }
    expect(thrown).toBeInstanceOf(ConflictException);
    // ConflictException response wraps an object in .response. Verify currentNote present.
    const response = (thrown as ConflictException).getResponse() as any;
    expect(response.currentNote).toEqual(current);
    expect(prisma.note.update).not.toHaveBeenCalled();
  });

  it('with bogus expectedUpdatedAt string: throws ConflictException (treated as stale)', async () => {
    const dbTime = new Date('2026-05-13T10:05:00Z');
    prisma.note.findUnique.mockResolvedValue({ id: 'n1', userId: 'u1', updatedAt: dbTime });
    await expect(
      service.update('u1', 'n1', { title: 'mine', expectedUpdatedAt: 'not-a-date' }),
    ).rejects.toBeInstanceOf(ConflictException);
  });
});
```

- [ ] **Step 2: Run tests — should FAIL on the 4 new ones**

```bash
cd ~/taler-id
npx jest src/notes/notes.service.spec.ts --no-coverage
```

Expected: the 4 new tests fail (`update` signature doesn't accept `expectedUpdatedAt`).

- [ ] **Step 3: Update `notes.service.ts` update method**

Replace the existing `update` method:

```typescript
  async update(
    userId: string,
    id: string,
    data: { title?: string; content?: string; expectedUpdatedAt?: string },
  ) {
    const note = await this.prisma.note.findUnique({ where: { id } });
    if (!note) throw new NotFoundException('Note not found');
    if (note.userId !== userId) throw new ForbiddenException();
    if (data.expectedUpdatedAt !== undefined) {
      const expected = new Date(data.expectedUpdatedAt);
      const sameMs =
        !Number.isNaN(expected.getTime()) &&
        expected.getTime() === note.updatedAt.getTime();
      if (!sameMs) {
        throw new ConflictException({
          message: 'Note updated elsewhere',
          currentNote: note,
        });
      }
    }
    const { expectedUpdatedAt: _ignored, ...patch } = data;
    return this.prisma.note.update({ where: { id }, data: patch });
  }
```

(The destructuring on the last line strips `expectedUpdatedAt` from the Prisma payload — it is not a column on `Note`.)

- [ ] **Step 4: Run tests — all 8 should pass (4 create + 4 update)**

```bash
cd ~/taler-id
npx jest src/notes/notes.service.spec.ts --no-coverage
```

Expected: 8/8 PASS.

- [ ] **Step 5: Commit**

```bash
cd ~/taler-id
git add src/notes/notes.service.ts src/notes/notes.service.spec.ts
git commit -m "$(cat <<'EOF'
feat(notes): update enforces optional expectedUpdatedAt (OCC)

When the client supplies expectedUpdatedAt and the DB has advanced past it,
respond with HTTP 409 + the current note in the response body so the client
can present a merge UI. When no expectedUpdatedAt is supplied, behaviour is
unchanged (last-write-wins, back-compat for older clients).

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 4: Backend — Deploy to DEV + manual probes

- [ ] **Step 1: Push `dev`**

```bash
cd ~/taler-id
git push origin dev
```

- [ ] **Step 2: SSH redeploy DEV**

```bash
ssh dvolkov@89.169.55.217 'cd ~/taler-id && git checkout dev && git pull origin dev && npm run build && pm2 restart taler-id-dev'
```

Expected: PM2 reports `taler-id-dev` online.

- [ ] **Step 3: Probe idempotent create**

```bash
TOKEN=$(curl -s -X POST https://staging.id.taler.tirol/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"integration_test@taler-test.com","password":"IntegrationTest123!"}' \
  | jq -r .accessToken)

ID=$(uuidgen)
echo "--- first create with id=$ID ---"
curl -s -X POST https://staging.id.taler.tirol/notes \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"id\":\"$ID\",\"title\":\"plan-probe\",\"content\":\"hi\"}" | jq '{id, title}'
echo "--- second (idempotent) create with same id ---"
curl -s -X POST https://staging.id.taler.tirol/notes \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"id\":\"$ID\",\"title\":\"plan-probe-2\",\"content\":\"hi2\"}" | jq '{id, title}'
```

Expected: same `id` in both responses; `title` is `plan-probe` in BOTH (idempotent — payload of second call ignored).

- [ ] **Step 4: Probe OCC update**

```bash
echo "--- update with bogus expectedUpdatedAt → expect 409 ---"
curl -s -w "\nHTTP_CODE=%{http_code}\n" -X PATCH https://staging.id.taler.tirol/notes/$ID \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"title":"x","expectedUpdatedAt":"1970-01-01T00:00:00.000Z"}'
echo "--- cleanup ---"
curl -s -X DELETE https://staging.id.taler.tirol/notes/$ID -H "Authorization: Bearer $TOKEN" -o /dev/null -w "HTTP_CODE=%{http_code}\n"
```

Expected: 409 on the bogus update; 200 on delete.

---

## Task 5: Integration test (`taler_id_tests`)

**Files:**
- Create: `~/Downloads/taler_id_tests/notes_offline_test.ts`
- Modify: `~/Downloads/taler_id_tests/package.json`

- [ ] **Step 1: Create the integration test**

Create `~/Downloads/taler_id_tests/notes_offline_test.ts`:

```typescript
// E2E test for the offline-friendly notes endpoints.
// Run: npm run test:notes:offline       (DEV)
//      npm run test:notes:offline:prod  (PROD)

import { randomUUID } from 'crypto';

const BASE_URL = process.env.BASE_URL ?? 'https://staging.id.taler.tirol';
const EMAIL = 'integration_test@taler-test.com';
const PASS = 'IntegrationTest123!';

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

async function login(): Promise<string> {
  const res = await fetch(`${BASE_URL}/auth/login`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email: EMAIL, password: PASS }),
  });
  if (!res.ok) throw new Error(`login ${res.status}`);
  const d: any = await res.json();
  return d.accessToken;
}

async function post(path: string, token: string, body: any): Promise<{ status: number; json: any }> {
  const res = await fetch(`${BASE_URL}${path}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${token}` },
    body: JSON.stringify(body),
  });
  return { status: res.status, json: await res.json().catch(() => null) };
}

async function patch(path: string, token: string, body: any): Promise<{ status: number; json: any }> {
  const res = await fetch(`${BASE_URL}${path}`, {
    method: 'PATCH',
    headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${token}` },
    body: JSON.stringify(body),
  });
  return { status: res.status, json: await res.json().catch(() => null) };
}

async function del(path: string, token: string): Promise<number> {
  const res = await fetch(`${BASE_URL}${path}`, {
    method: 'DELETE',
    headers: { Authorization: `Bearer ${token}` },
  });
  return res.status;
}

async function main() {
  console.log(`Notes offline tests against ${BASE_URL}`);
  const token = await login();
  const id = randomUUID();

  await run('1. POST /notes with custom id → returns same id', async () => {
    const r = await post('/notes', token, { id, title: 'offl-1', content: 'c1' });
    assert(r.status === 201 || r.status === 200, `status ${r.status}`);
    assert(r.json.id === id, `id mismatch: ${r.json.id}`);
  });

  await run('2. POST again with same id → idempotent, original payload preserved', async () => {
    const r = await post('/notes', token, { id, title: 'should-be-ignored', content: 'ignored' });
    assert(r.status === 201 || r.status === 200, `status ${r.status}`);
    assert(r.json.id === id, 'id mismatch');
    assert(r.json.title === 'offl-1', `title should still be offl-1, got ${r.json.title}`);
  });

  let firstUpdatedAt = '';
  await run('3. PATCH without expectedUpdatedAt → backwards-compatible LWW', async () => {
    const r = await patch(`/notes/${id}`, token, { title: 'edit-1' });
    assert(r.status === 200, `status ${r.status}`);
    assert(r.json.title === 'edit-1', 'title not updated');
    firstUpdatedAt = r.json.updatedAt as string;
    assert(typeof firstUpdatedAt === 'string' && firstUpdatedAt.length > 0, 'no updatedAt');
  });

  await run('4. PATCH with matching expectedUpdatedAt → 200', async () => {
    const r = await patch(`/notes/${id}`, token, { title: 'edit-2', expectedUpdatedAt: firstUpdatedAt });
    assert(r.status === 200, `status ${r.status}`);
    assert(r.json.title === 'edit-2', 'title not updated');
  });

  await run('5. PATCH with stale expectedUpdatedAt → 409 + currentNote in body', async () => {
    const r = await patch(`/notes/${id}`, token, { title: 'edit-stale', expectedUpdatedAt: firstUpdatedAt });
    assert(r.status === 409, `expected 409, got ${r.status}`);
    assert(!!r.json.currentNote, 'currentNote missing in 409 body');
    assert(r.json.currentNote.id === id, 'currentNote.id mismatch');
  });

  await run('6. DELETE → 200', async () => {
    const code = await del(`/notes/${id}`, token);
    assert(code === 200 || code === 204, `delete status ${code}`);
  });

  await run('7. DELETE again → 404 (idempotent for client)', async () => {
    const code = await del(`/notes/${id}`, token);
    assert(code === 404, `expected 404, got ${code}`);
  });

  const passed = results.filter(r => r.passed).length;
  const failed = results.length - passed;
  console.log(`\n  ${passed}/${results.length} passed, ${failed} failed`);
  if (failed > 0) process.exit(1);
}

main().catch(e => { console.error(e); process.exit(1); });
```

- [ ] **Step 2: Compile check**

```bash
cd ~/Downloads/taler_id_tests
npx tsc --noEmit notes_offline_test.ts
```

Expected: no errors.

- [ ] **Step 3: Register npm scripts**

Open `~/Downloads/taler_id_tests/package.json` and add inside `"scripts"`, near the other `test:*` entries:

```
    "test:notes:offline": "npx ts-node notes_offline_test.ts",
    "test:notes:offline:prod": "BASE_URL=https://id.taler.tirol npx ts-node notes_offline_test.ts",
```

- [ ] **Step 4: Run the DEV test**

```bash
cd ~/Downloads/taler_id_tests
npm run test:notes:offline
```

Expected: 7/7 passed.

- [ ] **Step 5: Skip commit**

`~/Downloads/taler_id_tests` is not a git repository. The new file lives on disk only.

---

## Task 6: Mobile — `OutboxOp` Freezed model

**Files:**
- Create: `~/Downloads/taler_id_mobile/lib/core/storage/outbox_op.dart`
- Create: `~/Downloads/taler_id_mobile/lib/core/services/outbox_replay_handler.dart` (interface only — separate file for tidy imports)

- [ ] **Step 0: Switch mobile to `dev`**

```bash
cd ~/Downloads/taler_id_mobile
git checkout dev && git pull origin dev
```

- [ ] **Step 1: Create `outbox_op.dart`**

```dart
// lib/core/storage/outbox_op.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'outbox_op.freezed.dart';
part 'outbox_op.g.dart';

enum OutboxOpKind { create, update, delete }

enum OutboxOpStatus { pending, inflight, failedConflict, failedDead }

@freezed
class OutboxOp with _$OutboxOp {
  const factory OutboxOp({
    required String opId,
    required String feature,
    required OutboxOpKind op,
    required String entityId,
    Map<String, dynamic>? payload,
    DateTime? expectedUpdatedAt,
    @Default(0) int attempts,
    @Default(OutboxOpStatus.pending) OutboxOpStatus status,
    required DateTime createdAt,
    DateTime? lastAttemptAt,
    String? lastError,
    Map<String, dynamic>? serverData, // populated on failedConflict
  }) = _OutboxOp;

  factory OutboxOp.fromJson(Map<String, dynamic> json) => _$OutboxOpFromJson(json);
}
```

- [ ] **Step 2: Create the replay-handler interface**

```dart
// lib/core/services/outbox_replay_handler.dart
import '../storage/outbox_op.dart';

abstract class OutboxReplayHandler {
  String get feature;
  Future<OutboxReplayResult> replay(OutboxOp op);
}

sealed class OutboxReplayResult {
  const OutboxReplayResult();
  factory OutboxReplayResult.success({Map<String, dynamic>? serverEntity}) =
      OutboxReplaySuccess;
  factory OutboxReplayResult.retry({required String error}) = OutboxReplayRetry;
  factory OutboxReplayResult.conflict({required Map<String, dynamic> serverData}) =
      OutboxReplayConflict;
  factory OutboxReplayResult.dead({required String error}) = OutboxReplayDead;
}

class OutboxReplaySuccess extends OutboxReplayResult {
  final Map<String, dynamic>? serverEntity;
  const OutboxReplaySuccess({this.serverEntity});
}
class OutboxReplayRetry extends OutboxReplayResult {
  final String error;
  const OutboxReplayRetry({required this.error});
}
class OutboxReplayConflict extends OutboxReplayResult {
  final Map<String, dynamic> serverData;
  const OutboxReplayConflict({required this.serverData});
}
class OutboxReplayDead extends OutboxReplayResult {
  final String error;
  const OutboxReplayDead({required this.error});
}
```

- [ ] **Step 3: Run code-gen**

```bash
cd ~/Downloads/taler_id_mobile
dart run build_runner build --delete-conflicting-outputs
```

Expected: `outbox_op.freezed.dart` and `outbox_op.g.dart` created.

- [ ] **Step 4: Analyze**

```bash
flutter analyze lib/core/storage/outbox_op.dart lib/core/services/outbox_replay_handler.dart
```

Expected: no errors.

- [ ] **Step 5: Commit**

```bash
cd ~/Downloads/taler_id_mobile
git add lib/core/storage/outbox_op.dart lib/core/storage/outbox_op.freezed.dart lib/core/storage/outbox_op.g.dart lib/core/services/outbox_replay_handler.dart
git commit -m "$(cat <<'EOF'
feat(outbox): add OutboxOp model + OutboxReplayHandler interface

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 7: Mobile — `OutboxQueue` (TDD)

**Files:**
- Create: `~/Downloads/taler_id_mobile/lib/core/storage/outbox_queue.dart`
- Create: `~/Downloads/taler_id_mobile/test/core/storage/outbox_queue_test.dart`

- [ ] **Step 1: Write the failing tests**

```dart
// test/core/storage/outbox_queue_test.dart
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:taler_id_mobile/core/storage/outbox_op.dart';
import 'package:taler_id_mobile/core/storage/outbox_queue.dart';

class _FakePathProvider extends PathProviderPlatform
    with MockPlatformInterfaceMixin {
  final String dir;
  _FakePathProvider(this.dir);
  @override
  Future<String?> getApplicationDocumentsPath() async => dir;
  @override
  Future<String?> getApplicationSupportPath() async => dir;
  @override
  Future<String?> getTemporaryPath() async => dir;
}

OutboxOp op({
  String opId = 'op-1',
  String feature = 'notes',
  OutboxOpKind kind = OutboxOpKind.create,
  String entityId = 'e-1',
  DateTime? createdAt,
  OutboxOpStatus status = OutboxOpStatus.pending,
  int attempts = 0,
}) =>
    OutboxOp(
      opId: opId,
      feature: feature,
      op: kind,
      entityId: entityId,
      createdAt: createdAt ?? DateTime.parse('2026-05-13T10:00:00Z'),
      status: status,
      attempts: attempts,
    );

void main() {
  late Directory tempDir;

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('outbox_queue_test_');
    PathProviderPlatform.instance = _FakePathProvider(tempDir.path);
    Hive.init(tempDir.path);
    await Hive.openBox<String>(OutboxQueue.boxName);
  });

  tearDown(() async {
    await Hive.close();
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  test('enqueue + pending lists the op', () async {
    final q = OutboxQueue();
    await q.enqueue(op(opId: 'a'));
    final list = await q.pending();
    expect(list.length, 1);
    expect(list[0].opId, 'a');
  });

  test('FIFO by createdAt', () async {
    final q = OutboxQueue();
    await q.enqueue(op(opId: 'b', createdAt: DateTime.parse('2026-05-13T10:02:00Z')));
    await q.enqueue(op(opId: 'a', createdAt: DateTime.parse('2026-05-13T10:01:00Z')));
    final next = await q.nextPending();
    expect(next?.opId, 'a');
  });

  test('markInflight then markPending preserves the op', () async {
    final q = OutboxQueue();
    await q.enqueue(op(opId: 'a'));
    await q.markInflight('a');
    final pendingNow = await q.pending();
    expect(pendingNow[0].status, OutboxOpStatus.inflight);
    await q.markPending('a', lastError: 'boom', attempts: 1);
    final later = await q.pending();
    expect(later[0].status, OutboxOpStatus.pending);
    expect(later[0].attempts, 1);
    expect(later[0].lastError, 'boom');
  });

  test('remove drops the op', () async {
    final q = OutboxQueue();
    await q.enqueue(op(opId: 'a'));
    await q.remove('a');
    expect((await q.pending()).isEmpty, true);
  });

  test('onBoot resets inflight → pending', () async {
    final q = OutboxQueue();
    await q.enqueue(op(opId: 'a', status: OutboxOpStatus.inflight));
    await q.onBoot();
    final list = await q.pending();
    expect(list[0].status, OutboxOpStatus.pending);
  });
}
```

- [ ] **Step 2: Run — should FAIL**

```bash
cd ~/Downloads/taler_id_mobile
flutter test test/core/storage/outbox_queue_test.dart
```

Expected: file `outbox_queue.dart` not found.

- [ ] **Step 3: Implement `OutboxQueue`**

```dart
// lib/core/storage/outbox_queue.dart
import 'dart:async';
import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'outbox_op.dart';

/// Persists OutboxOps in a Hive box keyed by opId.
/// Values are JSON strings to keep Hive schema-stable across model evolutions.
class OutboxQueue {
  static const String boxName = 'outbox_v1';

  Box<String> get _box => Hive.box<String>(boxName);

  Future<void> enqueue(OutboxOp op) async {
    await _box.put(op.opId, jsonEncode(op.toJson()));
  }

  Future<List<OutboxOp>> pending() async {
    final ops = _box.keys
        .cast<String>()
        .map((k) => _decode(_box.get(k)!))
        .whereType<OutboxOp>()
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return ops;
  }

  Future<OutboxOp?> nextPending() async {
    final all = await pending();
    for (final op in all) {
      if (op.status == OutboxOpStatus.pending) return op;
    }
    return null;
  }

  Future<void> markInflight(String opId) async {
    await _mutate(opId, (op) => op.copyWith(status: OutboxOpStatus.inflight, lastAttemptAt: DateTime.now()));
  }

  Future<void> markPending(String opId, {String? lastError, int? attempts}) async {
    await _mutate(opId, (op) => op.copyWith(
          status: OutboxOpStatus.pending,
          lastError: lastError ?? op.lastError,
          attempts: attempts ?? op.attempts,
        ));
  }

  Future<void> markConflict(String opId, Map<String, dynamic> serverData) async {
    await _mutate(opId, (op) => op.copyWith(status: OutboxOpStatus.failedConflict, serverData: serverData));
  }

  Future<void> markDead(String opId, String error) async {
    await _mutate(opId, (op) => op.copyWith(status: OutboxOpStatus.failedDead, lastError: error));
  }

  Future<void> remove(String opId) async {
    await _box.delete(opId);
  }

  Stream<List<OutboxOp>> watch() async* {
    yield await pending();
    await for (final _ in _box.watch()) {
      yield await pending();
    }
  }

  Future<void> onBoot() async {
    for (final k in _box.keys.cast<String>().toList()) {
      final op = _decode(_box.get(k)!);
      if (op == null) continue;
      if (op.status == OutboxOpStatus.inflight) {
        await _box.put(k, jsonEncode(op.copyWith(status: OutboxOpStatus.pending).toJson()));
      }
    }
  }

  Future<void> _mutate(String opId, OutboxOp Function(OutboxOp) f) async {
    final raw = _box.get(opId);
    if (raw == null) return;
    final op = _decode(raw);
    if (op == null) return;
    await _box.put(opId, jsonEncode(f(op).toJson()));
  }

  OutboxOp? _decode(String raw) {
    try {
      return OutboxOp.fromJson(Map<String, dynamic>.from(jsonDecode(raw) as Map));
    } catch (_) {
      return null;
    }
  }
}
```

- [ ] **Step 4: Run — PASS (5/5)**

```bash
flutter test test/core/storage/outbox_queue_test.dart
```

Expected: 5/5 PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/core/storage/outbox_queue.dart test/core/storage/outbox_queue_test.dart
git commit -m "$(cat <<'EOF'
feat(outbox): add OutboxQueue Hive wrapper with FIFO + status transitions

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 8: Mobile — `OutboxReplayService` (TDD)

**Files:**
- Create: `~/Downloads/taler_id_mobile/lib/core/services/outbox_replay_service.dart`
- Create: `~/Downloads/taler_id_mobile/test/core/services/outbox_replay_service_test.dart`

- [ ] **Step 1: Write the failing tests**

```dart
// test/core/services/outbox_replay_service_test.dart
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:taler_id_mobile/core/services/outbox_replay_handler.dart';
import 'package:taler_id_mobile/core/services/outbox_replay_service.dart';
import 'package:taler_id_mobile/core/storage/outbox_op.dart';
import 'package:taler_id_mobile/core/storage/outbox_queue.dart';

class _FakePathProvider extends PathProviderPlatform
    with MockPlatformInterfaceMixin {
  final String dir;
  _FakePathProvider(this.dir);
  @override
  Future<String?> getApplicationDocumentsPath() async => dir;
  @override
  Future<String?> getApplicationSupportPath() async => dir;
  @override
  Future<String?> getTemporaryPath() async => dir;
}

class _FakeHandler implements OutboxReplayHandler {
  @override
  final String feature;
  final List<OutboxReplayResult> resultsQueue;
  final List<OutboxOp> seen = [];
  _FakeHandler(this.feature, this.resultsQueue);
  @override
  Future<OutboxReplayResult> replay(OutboxOp op) async {
    seen.add(op);
    return resultsQueue.removeAt(0);
  }
}

OutboxOp op({String id = 'a', DateTime? createdAt}) => OutboxOp(
      opId: id,
      feature: 'notes',
      op: OutboxOpKind.create,
      entityId: 'n-$id',
      createdAt: createdAt ?? DateTime.parse('2026-05-13T10:00:00Z'),
    );

void main() {
  late Directory tempDir;
  late OutboxQueue queue;

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('outbox_replay_test_');
    PathProviderPlatform.instance = _FakePathProvider(tempDir.path);
    Hive.init(tempDir.path);
    await Hive.openBox<String>(OutboxQueue.boxName);
    queue = OutboxQueue();
  });

  tearDown(() async {
    await Hive.close();
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  test('drain calls handler for each pending op and removes on success', () async {
    final handler = _FakeHandler('notes', [
      OutboxReplayResult.success(),
      OutboxReplayResult.success(),
    ]);
    final svc = OutboxReplayService();
    svc.registerHandler(handler);
    await queue.enqueue(op(id: 'a', createdAt: DateTime.parse('2026-05-13T10:00:00Z')));
    await queue.enqueue(op(id: 'b', createdAt: DateTime.parse('2026-05-13T10:01:00Z')));

    await svc.drain();

    expect(handler.seen.map((o) => o.opId).toList(), ['a', 'b']);
    expect((await queue.pending()).isEmpty, true);
  });

  test('retry result keeps the op pending with incremented attempts', () async {
    final handler = _FakeHandler('notes', [
      OutboxReplayResult.retry(error: 'network'),
    ]);
    final svc = OutboxReplayService();
    svc.registerHandler(handler);
    await queue.enqueue(op());

    await svc.drain();

    final remaining = await queue.pending();
    expect(remaining.length, 1);
    expect(remaining[0].status, OutboxOpStatus.pending);
    expect(remaining[0].attempts, 1);
    expect(remaining[0].lastError, 'network');
  });

  test('conflict result transitions op to failedConflict with serverData', () async {
    final handler = _FakeHandler('notes', [
      OutboxReplayResult.conflict(serverData: {'title': 'srv'}),
    ]);
    final svc = OutboxReplayService();
    svc.registerHandler(handler);
    await queue.enqueue(op());

    await svc.drain();

    final remaining = await queue.pending();
    expect(remaining[0].status, OutboxOpStatus.failedConflict);
    expect(remaining[0].serverData, {'title': 'srv'});
  });

  test('dead result transitions op to failedDead', () async {
    final handler = _FakeHandler('notes', [
      OutboxReplayResult.dead(error: 'bad request'),
    ]);
    final svc = OutboxReplayService();
    svc.registerHandler(handler);
    await queue.enqueue(op());

    await svc.drain();

    expect((await queue.pending())[0].status, OutboxOpStatus.failedDead);
  });

  test('unknown feature → op marked dead with "no handler" error', () async {
    final svc = OutboxReplayService();
    await queue.enqueue(op());
    // no handler registered for 'notes'
    await svc.drain();
    final remaining = await queue.pending();
    expect(remaining[0].status, OutboxOpStatus.failedDead);
    expect(remaining[0].lastError, contains('no handler'));
  });

  test('attempts >= 10 causes auto-dead', () async {
    final handler = _FakeHandler('notes', [OutboxReplayResult.retry(error: 'x')]);
    final svc = OutboxReplayService();
    svc.registerHandler(handler);
    await queue.enqueue(op().copyWith(attempts: 9));
    await svc.drain();
    final remaining = await queue.pending();
    expect(remaining[0].status, OutboxOpStatus.failedDead);
  });

  test('drain is single-flight: concurrent calls do not double-replay', () async {
    final handler = _FakeHandler('notes', [OutboxReplayResult.success()]);
    final svc = OutboxReplayService();
    svc.registerHandler(handler);
    await queue.enqueue(op());

    final f1 = svc.drain();
    final f2 = svc.drain();
    await Future.wait([f1, f2]);

    expect(handler.seen.length, 1);
  });
}
```

- [ ] **Step 2: Run — should FAIL (file missing)**

```bash
flutter test test/core/services/outbox_replay_service_test.dart
```

- [ ] **Step 3: Implement `OutboxReplayService`**

```dart
// lib/core/services/outbox_replay_service.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import '../storage/outbox_op.dart';
import '../storage/outbox_queue.dart';
import 'outbox_replay_handler.dart';

class OutboxReplayService {
  static const int maxAttempts = 10;

  final OutboxQueue _queue;
  final Map<String, OutboxReplayHandler> _handlers = {};
  bool _draining = false;

  OutboxReplayService({OutboxQueue? queue}) : _queue = queue ?? OutboxQueue();

  void registerHandler(OutboxReplayHandler handler) {
    _handlers[handler.feature] = handler;
  }

  Future<void> drain() async {
    if (_draining) return;
    _draining = true;
    try {
      while (true) {
        final op = await _queue.nextPending();
        if (op == null) break;

        if (op.attempts >= maxAttempts) {
          await _queue.markDead(op.opId, 'max attempts reached');
          continue;
        }

        final handler = _handlers[op.feature];
        if (handler == null) {
          await _queue.markDead(op.opId, 'no handler for ${op.feature}');
          continue;
        }

        await _queue.markInflight(op.opId);
        final OutboxReplayResult result;
        try {
          result = await handler.replay(op);
        } catch (e, st) {
          debugPrint('[outbox] handler threw for ${op.opId}: $e\n$st');
          await _queue.markPending(op.opId, lastError: e.toString(), attempts: op.attempts + 1);
          continue;
        }

        switch (result) {
          case OutboxReplaySuccess():
            await _queue.remove(op.opId);
            break;
          case OutboxReplayRetry(:final error):
            await _queue.markPending(op.opId, lastError: error, attempts: op.attempts + 1);
            break;
          case OutboxReplayConflict(:final serverData):
            await _queue.markConflict(op.opId, serverData);
            break;
          case OutboxReplayDead(:final error):
            await _queue.markDead(op.opId, error);
            break;
        }
      }
    } finally {
      _draining = false;
    }
  }
}
```

- [ ] **Step 4: Run — PASS (7/7)**

```bash
flutter test test/core/services/outbox_replay_service_test.dart
```

Expected: 7/7 PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/core/services/outbox_replay_service.dart test/core/services/outbox_replay_service_test.dart
git commit -m "$(cat <<'EOF'
feat(outbox): add OutboxReplayService with single-flight drain + handler registry

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 9: Mobile — `ConnectivityWatcher`

**Files:**
- Create: `~/Downloads/taler_id_mobile/lib/core/services/connectivity_watcher.dart`

Note: This service has minimal logic and depends on a platform plugin. We rely on the OutboxReplayService tests + hardware smoke for verification rather than mocking connectivity_plus.

- [ ] **Step 1: Create the service**

```dart
// lib/core/services/connectivity_watcher.dart
import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'outbox_replay_service.dart';

class ConnectivityWatcher {
  final OutboxReplayService _replay;
  final Connectivity _connectivity;
  StreamSubscription<List<ConnectivityResult>>? _sub;
  bool _wasOnline = true;

  ConnectivityWatcher(this._replay, {Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity();

  void start() {
    _sub?.cancel();
    _sub = _connectivity.onConnectivityChanged.listen(_handle);
  }

  Future<void> stop() async {
    await _sub?.cancel();
    _sub = null;
  }

  void _handle(List<ConnectivityResult> results) {
    final online = results.any((r) =>
        r == ConnectivityResult.wifi ||
        r == ConnectivityResult.mobile ||
        r == ConnectivityResult.ethernet);
    if (online && !_wasOnline) {
      debugPrint('[connectivity] online — triggering outbox drain');
      _replay.drain();
    }
    _wasOnline = online;
  }
}
```

- [ ] **Step 2: Analyze**

```bash
flutter analyze lib/core/services/connectivity_watcher.dart
```

Expected: no errors.

- [ ] **Step 3: Commit**

```bash
git add lib/core/services/connectivity_watcher.dart
git commit -m "$(cat <<'EOF'
feat(outbox): add ConnectivityWatcher that triggers drain on offline→online

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 10: Mobile — `NoteEntity` + enums (Freezed)

**Files:**
- Create: `~/Downloads/taler_id_mobile/lib/features/notes/domain/entities/note_entity.dart`

- [ ] **Step 1: Create the entity**

```dart
// lib/features/notes/domain/entities/note_entity.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'note_entity.freezed.dart';
part 'note_entity.g.dart';

enum NoteSource {
  @JsonValue('MANUAL') manual,
  @JsonValue('ASSISTANT') assistant,
}

enum ConflictResolution { keepMine, acceptServer }

@freezed
class NoteEntity with _$NoteEntity {
  const factory NoteEntity({
    required String id,
    required String title,
    required String content,
    @Default(NoteSource.manual) NoteSource source,
    required DateTime createdAt,
    required DateTime updatedAt,
    @Default(false) bool localPending,
    Map<String, dynamic>? conflictedWith,
  }) = _NoteEntity;

  factory NoteEntity.fromJson(Map<String, dynamic> json) => _$NoteEntityFromJson(json);
}
```

- [ ] **Step 2: Run code-gen**

```bash
dart run build_runner build --delete-conflicting-outputs
```

Expected: `note_entity.freezed.dart` and `note_entity.g.dart` created.

- [ ] **Step 3: Analyze**

```bash
flutter analyze lib/features/notes/domain/entities/note_entity.dart
```

- [ ] **Step 4: Commit**

```bash
git add lib/features/notes/domain/entities/note_entity.dart lib/features/notes/domain/entities/note_entity.freezed.dart lib/features/notes/domain/entities/note_entity.g.dart
git commit -m "$(cat <<'EOF'
feat(notes): add NoteEntity (Freezed) + NoteSource/ConflictResolution enums

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 11: Mobile — Notes repository interface

**Files:**
- Create: `~/Downloads/taler_id_mobile/lib/features/notes/domain/repositories/i_notes_repository.dart`

- [ ] **Step 1: Create the interface**

```dart
// lib/features/notes/domain/repositories/i_notes_repository.dart
import '../entities/note_entity.dart';

abstract class INotesRepository {
  Stream<List<NoteEntity>> watchAll();
  Future<void> refresh();
  Future<NoteEntity> create(String title, String content, {NoteSource source});
  Future<NoteEntity> update(String id, {String? title, String? content});
  Future<void> delete(String id);
  Future<void> resolveConflict(String id, ConflictResolution choice);
  Stream<int> watchPendingCount();
  Stream<int> watchConflictCount();
}
```

- [ ] **Step 2: Analyze**

```bash
flutter analyze lib/features/notes/domain/repositories/i_notes_repository.dart
```

- [ ] **Step 3: Commit**

```bash
git add lib/features/notes/domain/repositories/i_notes_repository.dart
git commit -m "$(cat <<'EOF'
feat(notes): add INotesRepository abstract interface

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 12: Mobile — `NotesLocalDataSource` (TDD)

**Files:**
- Create: `~/Downloads/taler_id_mobile/lib/features/notes/data/datasources/notes_local_datasource.dart`
- Create: `~/Downloads/taler_id_mobile/test/features/notes/data/datasources/notes_local_datasource_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
// test/features/notes/data/datasources/notes_local_datasource_test.dart
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:taler_id_mobile/features/notes/data/datasources/notes_local_datasource.dart';
import 'package:taler_id_mobile/features/notes/domain/entities/note_entity.dart';

class _FakePathProvider extends PathProviderPlatform
    with MockPlatformInterfaceMixin {
  final String dir;
  _FakePathProvider(this.dir);
  @override
  Future<String?> getApplicationDocumentsPath() async => dir;
  @override
  Future<String?> getApplicationSupportPath() async => dir;
  @override
  Future<String?> getTemporaryPath() async => dir;
}

NoteEntity note(String id) => NoteEntity(
      id: id,
      title: 'T-$id',
      content: 'C-$id',
      createdAt: DateTime.parse('2026-05-13T10:00:00Z'),
      updatedAt: DateTime.parse('2026-05-13T10:00:00Z'),
    );

void main() {
  late Directory tempDir;

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('notes_local_test_');
    PathProviderPlatform.instance = _FakePathProvider(tempDir.path);
    Hive.init(tempDir.path);
    await Hive.openBox<String>(NotesLocalDataSource.boxName);
  });

  tearDown(() async {
    await Hive.close();
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  test('upsert + getAll returns notes in updatedAt-desc order', () async {
    final ds = NotesLocalDataSource();
    await ds.upsert(note('a').copyWith(updatedAt: DateTime.parse('2026-05-13T10:01:00Z')));
    await ds.upsert(note('b').copyWith(updatedAt: DateTime.parse('2026-05-13T10:02:00Z')));
    final list = await ds.getAll();
    expect(list.map((n) => n.id).toList(), ['b', 'a']);
  });

  test('remove drops the entry', () async {
    final ds = NotesLocalDataSource();
    await ds.upsert(note('a'));
    await ds.remove('a');
    expect((await ds.getAll()).isEmpty, true);
  });

  test('upsert replaces existing by id', () async {
    final ds = NotesLocalDataSource();
    await ds.upsert(note('a'));
    await ds.upsert(note('a').copyWith(title: 'updated'));
    final list = await ds.getAll();
    expect(list.length, 1);
    expect(list[0].title, 'updated');
  });

  test('watchAll emits on changes', () async {
    final ds = NotesLocalDataSource();
    final emissions = <int>[];
    final sub = ds.watchAll().listen((notes) => emissions.add(notes.length));
    await Future<void>.delayed(const Duration(milliseconds: 50));
    await ds.upsert(note('a'));
    await Future<void>.delayed(const Duration(milliseconds: 50));
    await ds.upsert(note('b'));
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(emissions, contains(1));
    expect(emissions, contains(2));
    await sub.cancel();
  });
}
```

- [ ] **Step 2: Run — should FAIL**

```bash
flutter test test/features/notes/data/datasources/notes_local_datasource_test.dart
```

- [ ] **Step 3: Implement `NotesLocalDataSource`**

```dart
// lib/features/notes/data/datasources/notes_local_datasource.dart
import 'dart:async';
import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../../domain/entities/note_entity.dart';

class NotesLocalDataSource {
  static const String boxName = 'notes_local';

  Box<String> get _box => Hive.box<String>(boxName);

  Future<List<NoteEntity>> getAll() async {
    final list = _box.keys
        .cast<String>()
        .map((k) => _decode(_box.get(k)!))
        .whereType<NoteEntity>()
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return list;
  }

  Future<NoteEntity?> getById(String id) async {
    final raw = _box.get(id);
    if (raw == null) return null;
    return _decode(raw);
  }

  Future<void> upsert(NoteEntity note) async {
    await _box.put(note.id, jsonEncode(note.toJson()));
  }

  Future<void> remove(String id) async {
    await _box.delete(id);
  }

  Stream<List<NoteEntity>> watchAll() async* {
    yield await getAll();
    await for (final _ in _box.watch()) {
      yield await getAll();
    }
  }

  NoteEntity? _decode(String raw) {
    try {
      return NoteEntity.fromJson(Map<String, dynamic>.from(jsonDecode(raw) as Map));
    } catch (_) {
      return null;
    }
  }
}
```

- [ ] **Step 4: Run — PASS (4/4)**

```bash
flutter test test/features/notes/data/datasources/notes_local_datasource_test.dart
```

- [ ] **Step 5: Commit**

```bash
git add lib/features/notes/data/datasources/notes_local_datasource.dart test/features/notes/data/datasources/notes_local_datasource_test.dart
git commit -m "$(cat <<'EOF'
feat(notes): add NotesLocalDataSource (Hive box notes_local)

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 13: Mobile — `NotesRemoteDataSource` updates

**Files:**
- Modify: `~/Downloads/taler_id_mobile/lib/features/notes/data/datasources/notes_remote_datasource.dart`

- [ ] **Step 1: Replace the entire file**

```dart
// lib/features/notes/data/datasources/notes_remote_datasource.dart
import 'package:dio/dio.dart';
import '../../../../core/api/dio_client.dart';

class NoteConflictException implements Exception {
  final Map<String, dynamic> currentNote;
  NoteConflictException(this.currentNote);
}

class NotesRemoteDataSource {
  final DioClient _http;
  NotesRemoteDataSource(this._http);

  Future<List<Map<String, dynamic>>> getAll({int limit = 50, int offset = 0}) async {
    final data = await _http.get<dynamic>('/notes?limit=$limit&offset=$offset');
    return (data as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<Map<String, dynamic>> create({
    String? id,
    required String title,
    required String content,
    String source = 'MANUAL',
  }) async {
    final body = <String, dynamic>{
      if (id != null) 'id': id,
      'title': title,
      'content': content,
      'source': source,
    };
    return _http.post('/notes', data: body, fromJson: (d) => Map<String, dynamic>.from(d as Map));
  }

  Future<Map<String, dynamic>> update(
    String id, {
    String? title,
    String? content,
    DateTime? expectedUpdatedAt,
  }) async {
    final data = <String, dynamic>{};
    if (title != null) data['title'] = title;
    if (content != null) data['content'] = content;
    if (expectedUpdatedAt != null) data['expectedUpdatedAt'] = expectedUpdatedAt.toUtc().toIso8601String();
    try {
      return await _http.patch('/notes/$id', data: data, fromJson: (d) => Map<String, dynamic>.from(d as Map));
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) {
        final body = e.response!.data;
        final current = (body is Map && body['currentNote'] is Map)
            ? Map<String, dynamic>.from(body['currentNote'] as Map)
            : <String, dynamic>{};
        throw NoteConflictException(current);
      }
      rethrow;
    }
  }

  Future<void> delete(String id) async {
    try {
      await _http.delete('/notes/$id');
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return; // idempotent
      rethrow;
    }
  }
}
```

- [ ] **Step 2: Analyze**

```bash
flutter analyze lib/features/notes/data/datasources/notes_remote_datasource.dart
```

Expected: no errors.

- [ ] **Step 3: Commit**

```bash
git add lib/features/notes/data/datasources/notes_remote_datasource.dart
git commit -m "$(cat <<'EOF'
feat(notes): remote datasource accepts id (create) + expectedUpdatedAt (update)

On 409 from update, throws NoteConflictException with the server's
currentNote in payload. On 404 from delete, swallows for idempotency.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 14: Mobile — `NotesOutboxReplayHandler`

**Files:**
- Create: `~/Downloads/taler_id_mobile/lib/features/notes/data/services/notes_outbox_replay_handler.dart`
- Create: `~/Downloads/taler_id_mobile/test/features/notes/data/services/notes_outbox_replay_handler_test.dart`

- [ ] **Step 1: Write the failing tests**

```dart
// test/features/notes/data/services/notes_outbox_replay_handler_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:taler_id_mobile/core/services/outbox_replay_handler.dart';
import 'package:taler_id_mobile/core/storage/outbox_op.dart';
import 'package:taler_id_mobile/features/notes/data/datasources/notes_remote_datasource.dart';
import 'package:taler_id_mobile/features/notes/data/services/notes_outbox_replay_handler.dart';

class _MockRemote extends Mock implements NotesRemoteDataSource {}

OutboxOp _op({
  OutboxOpKind op = OutboxOpKind.create,
  Map<String, dynamic>? payload,
  DateTime? expectedUpdatedAt,
}) =>
    OutboxOp(
      opId: 'op-1',
      feature: 'notes',
      op: op,
      entityId: 'n-1',
      payload: payload,
      expectedUpdatedAt: expectedUpdatedAt,
      createdAt: DateTime.now(),
    );

void main() {
  late _MockRemote remote;
  late NotesOutboxReplayHandler handler;

  setUp(() {
    remote = _MockRemote();
    handler = NotesOutboxReplayHandler(remote: remote);
  });

  test('create success → OutboxReplaySuccess', () async {
    when(() => remote.create(id: 'n-1', title: 't', content: 'c', source: 'MANUAL'))
        .thenAnswer((_) async => {'id': 'n-1', 'title': 't'});
    final res = await handler.replay(
      _op(payload: {'title': 't', 'content': 'c', 'source': 'MANUAL'}),
    );
    expect(res, isA<OutboxReplaySuccess>());
  });

  test('update conflict → OutboxReplayConflict with serverData', () async {
    when(() => remote.update(
          'n-1',
          title: 't',
          content: null,
          expectedUpdatedAt: any(named: 'expectedUpdatedAt'),
        )).thenThrow(NoteConflictException({'title': 'srv'}));
    final res = await handler.replay(
      _op(
        op: OutboxOpKind.update,
        payload: {'title': 't'},
        expectedUpdatedAt: DateTime.parse('2026-05-13T10:00:00Z'),
      ),
    );
    expect(res, isA<OutboxReplayConflict>());
    expect((res as OutboxReplayConflict).serverData, {'title': 'srv'});
  });

  test('delete 404 → success (idempotent via datasource)', () async {
    when(() => remote.delete('n-1')).thenAnswer((_) async {});
    final res = await handler.replay(_op(op: OutboxOpKind.delete));
    expect(res, isA<OutboxReplaySuccess>());
  });

  test('unknown error → retry', () async {
    when(() => remote.create(id: 'n-1', title: 't', content: 'c', source: 'MANUAL'))
        .thenThrow(Exception('network'));
    final res = await handler.replay(
      _op(payload: {'title': 't', 'content': 'c', 'source': 'MANUAL'}),
    );
    expect(res, isA<OutboxReplayRetry>());
  });
}
```

- [ ] **Step 2: Run — should FAIL (no impl)**

```bash
flutter test test/features/notes/data/services/notes_outbox_replay_handler_test.dart
```

- [ ] **Step 3: Implement the handler**

```dart
// lib/features/notes/data/services/notes_outbox_replay_handler.dart
import 'package:dio/dio.dart';
import '../../../../core/services/outbox_replay_handler.dart';
import '../../../../core/storage/outbox_op.dart';
import '../datasources/notes_remote_datasource.dart';

class NotesOutboxReplayHandler implements OutboxReplayHandler {
  final NotesRemoteDataSource _remote;
  NotesOutboxReplayHandler({required NotesRemoteDataSource remote}) : _remote = remote;

  @override
  String get feature => 'notes';

  @override
  Future<OutboxReplayResult> replay(OutboxOp op) async {
    try {
      switch (op.op) {
        case OutboxOpKind.create:
          final p = op.payload ?? {};
          final serverEntity = await _remote.create(
            id: op.entityId,
            title: p['title'] as String? ?? '',
            content: p['content'] as String? ?? '',
            source: p['source'] as String? ?? 'MANUAL',
          );
          return OutboxReplayResult.success(serverEntity: serverEntity);
        case OutboxOpKind.update:
          final p = op.payload ?? {};
          final serverEntity = await _remote.update(
            op.entityId,
            title: p['title'] as String?,
            content: p['content'] as String?,
            expectedUpdatedAt: op.expectedUpdatedAt,
          );
          return OutboxReplayResult.success(serverEntity: serverEntity);
        case OutboxOpKind.delete:
          await _remote.delete(op.entityId);
          return OutboxReplayResult.success();
      }
    } on NoteConflictException catch (e) {
      return OutboxReplayResult.conflict(serverData: e.currentNote);
    } on DioException catch (e) {
      final code = e.response?.statusCode ?? 0;
      if (code >= 400 && code < 500 && code != 408 && code != 429) {
        return OutboxReplayResult.dead(error: 'HTTP $code: ${e.message}');
      }
      return OutboxReplayResult.retry(error: 'HTTP $code: ${e.message}');
    } catch (e) {
      return OutboxReplayResult.retry(error: e.toString());
    }
  }
}
```

- [ ] **Step 4: Run — PASS (4/4)**

```bash
flutter test test/features/notes/data/services/notes_outbox_replay_handler_test.dart
```

- [ ] **Step 5: Commit**

```bash
git add lib/features/notes/data/services/notes_outbox_replay_handler.dart test/features/notes/data/services/notes_outbox_replay_handler_test.dart
git commit -m "$(cat <<'EOF'
feat(notes): NotesOutboxReplayHandler maps HTTP outcomes to OutboxReplayResult

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 15: Mobile — `NotesRepositoryImpl` (TDD)

**Files:**
- Create: `~/Downloads/taler_id_mobile/lib/features/notes/data/repositories/notes_repository_impl.dart`
- Create: `~/Downloads/taler_id_mobile/test/features/notes/data/repositories/notes_repository_impl_test.dart`

This is the orchestrator. It uses `NotesLocalDataSource`, `NotesRemoteDataSource`, and `OutboxQueue`. Squash logic and conflict resolution live here.

- [ ] **Step 1: Write the failing tests**

```dart
// test/features/notes/data/repositories/notes_repository_impl_test.dart
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:taler_id_mobile/core/storage/outbox_op.dart';
import 'package:taler_id_mobile/core/storage/outbox_queue.dart';
import 'package:taler_id_mobile/features/notes/data/datasources/notes_local_datasource.dart';
import 'package:taler_id_mobile/features/notes/data/datasources/notes_remote_datasource.dart';
import 'package:taler_id_mobile/features/notes/data/repositories/notes_repository_impl.dart';
import 'package:taler_id_mobile/features/notes/domain/entities/note_entity.dart';

class _MockRemote extends Mock implements NotesRemoteDataSource {}

class _FakePathProvider extends PathProviderPlatform
    with MockPlatformInterfaceMixin {
  final String dir;
  _FakePathProvider(this.dir);
  @override Future<String?> getApplicationDocumentsPath() async => dir;
  @override Future<String?> getApplicationSupportPath() async => dir;
  @override Future<String?> getTemporaryPath() async => dir;
}

void main() {
  late Directory tempDir;
  late NotesLocalDataSource local;
  late OutboxQueue queue;
  late _MockRemote remote;
  late NotesRepositoryImpl repo;

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('notes_repo_test_');
    PathProviderPlatform.instance = _FakePathProvider(tempDir.path);
    Hive.init(tempDir.path);
    await Hive.openBox<String>(NotesLocalDataSource.boxName);
    await Hive.openBox<String>(OutboxQueue.boxName);
    local = NotesLocalDataSource();
    queue = OutboxQueue();
    remote = _MockRemote();
    repo = NotesRepositoryImpl(local: local, remote: remote, outbox: queue);
  });

  tearDown(() async {
    await Hive.close();
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  test('create writes local with localPending=true and enqueues outbox op', () async {
    final n = await repo.create('t', 'c');
    expect(n.localPending, true);
    final localList = await local.getAll();
    expect(localList.length, 1);
    final ops = await queue.pending();
    expect(ops.length, 1);
    expect(ops[0].op, OutboxOpKind.create);
    expect(ops[0].entityId, n.id);
  });

  test('update on a locally-pending create updates the create payload (no extra op)', () async {
    final n = await repo.create('orig', 'c');
    await repo.update(n.id, title: 'changed');
    final ops = await queue.pending();
    expect(ops.length, 1);
    expect(ops[0].op, OutboxOpKind.create);
    expect(ops[0].payload!['title'], 'changed');
  });

  test('update on a synced note enqueues an update op with expectedUpdatedAt', () async {
    final synced = NoteEntity(
      id: 'n-1',
      title: 'a',
      content: 'b',
      createdAt: DateTime.parse('2026-05-13T10:00:00Z'),
      updatedAt: DateTime.parse('2026-05-13T10:00:00Z'),
    );
    await local.upsert(synced);
    await repo.update('n-1', title: 'a2');
    final ops = await queue.pending();
    expect(ops.length, 1);
    expect(ops[0].op, OutboxOpKind.update);
    expect(ops[0].expectedUpdatedAt, synced.updatedAt);
    final localNow = await local.getById('n-1');
    expect(localNow!.title, 'a2');
    expect(localNow.localPending, true);
  });

  test('delete on a locally-pending create drops both local and outbox', () async {
    final n = await repo.create('t', 'c');
    await repo.delete(n.id);
    expect((await local.getAll()).isEmpty, true);
    expect((await queue.pending()).isEmpty, true);
  });

  test('delete on a synced note enqueues delete + removes from local', () async {
    final synced = NoteEntity(
      id: 'n-1',
      title: 'a',
      content: 'b',
      createdAt: DateTime.parse('2026-05-13T10:00:00Z'),
      updatedAt: DateTime.parse('2026-05-13T10:00:00Z'),
    );
    await local.upsert(synced);
    await repo.delete('n-1');
    expect((await local.getAll()).isEmpty, true);
    final ops = await queue.pending();
    expect(ops.length, 1);
    expect(ops[0].op, OutboxOpKind.delete);
    expect(ops[0].entityId, 'n-1');
  });

  test('resolveConflict KEEP_MINE replaces conflict op with fresh update using server updatedAt', () async {
    final localNote = NoteEntity(
      id: 'n-1',
      title: 'mine',
      content: 'mine-content',
      createdAt: DateTime.parse('2026-05-13T10:00:00Z'),
      updatedAt: DateTime.parse('2026-05-13T10:00:00Z'),
      localPending: true,
      conflictedWith: {
        'id': 'n-1',
        'title': 'server',
        'content': 'server-content',
        'updatedAt': '2026-05-13T10:10:00.000Z',
      },
    );
    await local.upsert(localNote);
    await queue.enqueue(OutboxOp(
      opId: 'conflict-op',
      feature: 'notes',
      op: OutboxOpKind.update,
      entityId: 'n-1',
      payload: {'title': 'mine', 'content': 'mine-content'},
      status: OutboxOpStatus.failedConflict,
      createdAt: DateTime.now(),
    ));

    await repo.resolveConflict('n-1', ConflictResolution.keepMine);

    final ops = await queue.pending();
    expect(ops.length, 1);
    expect(ops[0].opId, isNot('conflict-op'));
    expect(ops[0].status, OutboxOpStatus.pending);
    expect(ops[0].expectedUpdatedAt, DateTime.parse('2026-05-13T10:10:00.000Z'));
    final localNow = await local.getById('n-1');
    expect(localNow!.conflictedWith, isNull);
  });

  test('resolveConflict ACCEPT_SERVER overwrites local + drops op', () async {
    final localNote = NoteEntity(
      id: 'n-1',
      title: 'mine',
      content: 'mine-content',
      createdAt: DateTime.parse('2026-05-13T10:00:00Z'),
      updatedAt: DateTime.parse('2026-05-13T10:00:00Z'),
      localPending: true,
      conflictedWith: {
        'id': 'n-1',
        'title': 'server',
        'content': 'server-content',
        'createdAt': '2026-05-13T10:00:00.000Z',
        'updatedAt': '2026-05-13T10:10:00.000Z',
        'source': 'MANUAL',
      },
    );
    await local.upsert(localNote);
    await queue.enqueue(OutboxOp(
      opId: 'conflict-op',
      feature: 'notes',
      op: OutboxOpKind.update,
      entityId: 'n-1',
      payload: {'title': 'mine'},
      status: OutboxOpStatus.failedConflict,
      createdAt: DateTime.now(),
    ));

    await repo.resolveConflict('n-1', ConflictResolution.acceptServer);

    expect((await queue.pending()).isEmpty, true);
    final localNow = await local.getById('n-1');
    expect(localNow!.title, 'server');
    expect(localNow.localPending, false);
    expect(localNow.conflictedWith, isNull);
  });
}
```

- [ ] **Step 2: Run — should FAIL**

```bash
flutter test test/features/notes/data/repositories/notes_repository_impl_test.dart
```

- [ ] **Step 3: Implement `NotesRepositoryImpl`**

```dart
// lib/features/notes/data/repositories/notes_repository_impl.dart
import 'dart:async';
import 'package:uuid/uuid.dart';
import '../../../../core/storage/outbox_op.dart';
import '../../../../core/storage/outbox_queue.dart';
import '../../domain/entities/note_entity.dart';
import '../../domain/repositories/i_notes_repository.dart';
import '../datasources/notes_local_datasource.dart';
import '../datasources/notes_remote_datasource.dart';

class NotesRepositoryImpl implements INotesRepository {
  final NotesLocalDataSource _local;
  final NotesRemoteDataSource _remote;
  final OutboxQueue _outbox;
  final Uuid _uuid = const Uuid();

  NotesRepositoryImpl({
    required NotesLocalDataSource local,
    required NotesRemoteDataSource remote,
    required OutboxQueue outbox,
  })  : _local = local,
        _remote = remote,
        _outbox = outbox;

  @override
  Stream<List<NoteEntity>> watchAll() => _local.watchAll();

  @override
  Future<void> refresh() async {
    try {
      final remoteList = await _remote.getAll(limit: 200);
      final remoteIds = remoteList.map((m) => m['id'] as String).toSet();
      final localList = await _local.getAll();
      for (final r in remoteList) {
        final entity = _entityFromServerJson(r);
        final localNote = await _local.getById(entity.id);
        if (localNote != null && localNote.localPending) {
          // preserve local in-flight edits
          continue;
        }
        await _local.upsert(entity);
      }
      for (final l in localList) {
        if (!remoteIds.contains(l.id) && !l.localPending) {
          await _local.remove(l.id);
        }
      }
    } catch (_) {
      // offline / failure → ignore, local data stays
    }
  }

  @override
  Future<NoteEntity> create(String title, String content,
      {NoteSource source = NoteSource.manual}) async {
    final id = _uuid.v4();
    final now = DateTime.now().toUtc();
    final n = NoteEntity(
      id: id,
      title: title,
      content: content,
      source: source,
      createdAt: now,
      updatedAt: now,
      localPending: true,
    );
    await _local.upsert(n);
    await _outbox.enqueue(OutboxOp(
      opId: _uuid.v4(),
      feature: 'notes',
      op: OutboxOpKind.create,
      entityId: id,
      payload: {
        'title': title,
        'content': content,
        'source': source == NoteSource.manual ? 'MANUAL' : 'ASSISTANT',
      },
      createdAt: now,
    ));
    return n;
  }

  @override
  Future<NoteEntity> update(String id, {String? title, String? content}) async {
    final current = await _local.getById(id);
    if (current == null) throw StateError('Note $id not in local store');
    final next = current.copyWith(
      title: title ?? current.title,
      content: content ?? current.content,
      localPending: true,
    );
    await _local.upsert(next);

    final existingOps = await _outbox.pending();
    final pendingForThis = existingOps.where((o) => o.entityId == id).toList();

    // squash: if pending create exists, update its payload
    final pendingCreate = pendingForThis.firstWhere(
      (o) => o.op == OutboxOpKind.create,
      orElse: () => _empty,
    );
    if (identical(pendingCreate, _empty) == false) {
      final mergedPayload = Map<String, dynamic>.from(pendingCreate.payload ?? {});
      if (title != null) mergedPayload['title'] = title;
      if (content != null) mergedPayload['content'] = content;
      await _outbox.remove(pendingCreate.opId);
      await _outbox.enqueue(pendingCreate.copyWith(payload: mergedPayload));
      return next;
    }
    // squash: replace any pending update for this entity
    for (final op in pendingForThis) {
      if (op.op == OutboxOpKind.update) {
        await _outbox.remove(op.opId);
      }
    }
    await _outbox.enqueue(OutboxOp(
      opId: _uuid.v4(),
      feature: 'notes',
      op: OutboxOpKind.update,
      entityId: id,
      payload: {
        if (title != null) 'title': title,
        if (content != null) 'content': content,
      },
      expectedUpdatedAt: current.updatedAt,
      createdAt: DateTime.now().toUtc(),
    ));
    return next;
  }

  @override
  Future<void> delete(String id) async {
    final existingOps = await _outbox.pending();
    final pendingForThis = existingOps.where((o) => o.entityId == id).toList();
    final pendingCreate = pendingForThis.firstWhere(
      (o) => o.op == OutboxOpKind.create,
      orElse: () => _empty,
    );
    if (identical(pendingCreate, _empty) == false) {
      // never reached server — drop everything for this id
      for (final op in pendingForThis) {
        await _outbox.remove(op.opId);
      }
      await _local.remove(id);
      return;
    }
    // squash any pending update (now obsolete)
    for (final op in pendingForThis) {
      if (op.op == OutboxOpKind.update) {
        await _outbox.remove(op.opId);
      }
    }
    await _local.remove(id);
    await _outbox.enqueue(OutboxOp(
      opId: _uuid.v4(),
      feature: 'notes',
      op: OutboxOpKind.delete,
      entityId: id,
      createdAt: DateTime.now().toUtc(),
    ));
  }

  @override
  Future<void> resolveConflict(String id, ConflictResolution choice) async {
    final note = await _local.getById(id);
    if (note == null || note.conflictedWith == null) return;
    final server = note.conflictedWith!;

    final ops = await _outbox.pending();
    final conflictOp = ops.firstWhere(
      (o) => o.entityId == id && o.status == OutboxOpStatus.failedConflict,
      orElse: () => _empty,
    );

    switch (choice) {
      case ConflictResolution.keepMine:
        if (identical(conflictOp, _empty) == false) {
          final serverUpdatedAt = DateTime.parse(server['updatedAt'] as String);
          await _outbox.remove(conflictOp.opId);
          await _outbox.enqueue(OutboxOp(
            opId: _uuid.v4(),
            feature: 'notes',
            op: OutboxOpKind.update,
            entityId: id,
            payload: conflictOp.payload,
            expectedUpdatedAt: serverUpdatedAt,
            createdAt: DateTime.now().toUtc(),
          ));
        }
        await _local.upsert(note.copyWith(conflictedWith: null));
        break;
      case ConflictResolution.acceptServer:
        if (identical(conflictOp, _empty) == false) {
          await _outbox.remove(conflictOp.opId);
        }
        await _local.upsert(_entityFromServerJson(server));
        break;
    }
  }

  @override
  Stream<int> watchPendingCount() async* {
    yield (await _local.getAll()).where((n) => n.localPending).length;
    await for (final list in _local.watchAll()) {
      yield list.where((n) => n.localPending).length;
    }
  }

  @override
  Stream<int> watchConflictCount() async* {
    yield (await _local.getAll()).where((n) => n.conflictedWith != null).length;
    await for (final list in _local.watchAll()) {
      yield list.where((n) => n.conflictedWith != null).length;
    }
  }

  NoteEntity _entityFromServerJson(Map<String, dynamic> json) {
    final src = json['source'] as String? ?? 'MANUAL';
    return NoteEntity(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      content: json['content'] as String? ?? '',
      source: src == 'ASSISTANT' ? NoteSource.assistant : NoteSource.manual,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      localPending: false,
      conflictedWith: null,
    );
  }

  // Sentinel for firstWhere fallback.
  static final OutboxOp _empty = OutboxOp(
    opId: '__empty__',
    feature: '',
    op: OutboxOpKind.create,
    entityId: '',
    createdAt: DateTime(1970),
  );
}
```

Also add `uuid: ^4.0.0` to `pubspec.yaml` `dependencies:` if not present. Check first:

```bash
grep "^  uuid:" ~/Downloads/taler_id_mobile/pubspec.yaml
```

If empty, edit `pubspec.yaml` to add under `dependencies:`:

```yaml
  uuid: ^4.0.0
```

Then `flutter pub get`.

- [ ] **Step 4: Run — PASS (7/7)**

```bash
flutter test test/features/notes/data/repositories/notes_repository_impl_test.dart
```

- [ ] **Step 5: Commit**

```bash
git add lib/features/notes/data/repositories/notes_repository_impl.dart test/features/notes/data/repositories/notes_repository_impl_test.dart pubspec.yaml pubspec.lock
git commit -m "$(cat <<'EOF'
feat(notes): add NotesRepositoryImpl with squash + OCC + conflict resolution

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 16: Mobile — DI wiring

**Files:**
- Modify: `~/Downloads/taler_id_mobile/lib/core/di/service_locator.dart`

- [ ] **Step 1: Open Hive boxes and register services**

In `setupDependencies()` (near other `Hive.openBox` calls), add:

```dart
  await Hive.openBox<String>(OutboxQueue.boxName);
  await Hive.openBox<String>(NotesLocalDataSource.boxName);
```

Add imports at top:

```dart
import '../storage/outbox_queue.dart';
import '../services/outbox_replay_service.dart';
import '../services/connectivity_watcher.dart';
import '../../features/notes/data/datasources/notes_local_datasource.dart';
import '../../features/notes/data/datasources/notes_remote_datasource.dart';
import '../../features/notes/data/repositories/notes_repository_impl.dart';
import '../../features/notes/data/services/notes_outbox_replay_handler.dart';
import '../../features/notes/domain/repositories/i_notes_repository.dart';
```

In the registrations section, add:

```dart
  // Outbox infrastructure
  sl.registerLazySingleton<OutboxQueue>(() => OutboxQueue());
  sl.registerLazySingleton<OutboxReplayService>(() => OutboxReplayService(queue: sl<OutboxQueue>()));
  sl.registerLazySingleton<ConnectivityWatcher>(() => ConnectivityWatcher(sl<OutboxReplayService>()));

  // Notes feature
  sl.registerLazySingleton<NotesLocalDataSource>(() => NotesLocalDataSource());
  if (!sl.isRegistered<NotesRemoteDataSource>()) {
    sl.registerLazySingleton<NotesRemoteDataSource>(() => NotesRemoteDataSource(sl<DioClient>()));
  }
  sl.registerLazySingleton<INotesRepository>(() => NotesRepositoryImpl(
        local: sl<NotesLocalDataSource>(),
        remote: sl<NotesRemoteDataSource>(),
        outbox: sl<OutboxQueue>(),
      ));
  sl.registerLazySingleton<NotesOutboxReplayHandler>(() => NotesOutboxReplayHandler(
        remote: sl<NotesRemoteDataSource>(),
      ));
```

(If `NotesRemoteDataSource` is already registered elsewhere, the `if (!sl.isRegistered)` guard keeps things safe.)

At the end of `setupDependencies()`, after all `registerLazySingleton` calls, boot the outbox + connectivity:

```dart
  // Boot outbox: reset any inflight ops, register handlers, start connectivity watch
  await sl<OutboxQueue>().onBoot();
  sl<OutboxReplayService>().registerHandler(sl<NotesOutboxReplayHandler>());
  sl<ConnectivityWatcher>().start();
  // First drain on app boot (in case we were offline last session)
  // ignore: discarded_futures
  sl<OutboxReplayService>().drain();
```

- [ ] **Step 2: Analyze + build**

```bash
flutter analyze lib/core/di/service_locator.dart
```

Expected: no errors.

- [ ] **Step 3: Commit**

```bash
git add lib/core/di/service_locator.dart
git commit -m "$(cat <<'EOF'
feat(di): wire outbox infrastructure + notes offline repository

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 17: Mobile — Refactor `notes_screen.dart` to use `INotesRepository`

**Files:**
- Modify: `~/Downloads/taler_id_mobile/lib/features/notes/presentation/screens/notes_screen.dart`

The current file is ~680 lines, mostly UI. The refactor is mechanical: swap direct `NotesRemoteDataSource` + `SimpleListCache` usage for `INotesRepository` calls and stream subscriptions. Display logic stays.

- [ ] **Step 1: Identify and replace data plumbing**

Find the four data-touch points in `notes_screen.dart`:
1. `final _cache = sl<SimpleListCache>(instanceName: 'notes');` — DELETE.
2. `_load()` function that reads cache + calls `NotesRemoteDataSource.getAll` — REPLACE with stream subscription.
3. Add/Edit dialog handlers that call `NotesRemoteDataSource.create/update` — REPLACE with `_repo.create/update`.
4. Delete handler — REPLACE with `_repo.delete`.

Step-by-step diff:

**Add at top of imports:**

```dart
import 'package:taler_id_mobile/features/notes/domain/entities/note_entity.dart';
import 'package:taler_id_mobile/features/notes/domain/repositories/i_notes_repository.dart';
```

**In the `State<NotesScreen>` class, replace the cache field:**

```dart
  // Remove this line:
  // final _cache = sl<SimpleListCache>(instanceName: 'notes');

  // Add these:
  final INotesRepository _repo = sl<INotesRepository>();
  StreamSubscription<List<NoteEntity>>? _notesSub;
  StreamSubscription<int>? _pendingSub;
  StreamSubscription<int>? _conflictSub;
  List<NoteEntity> _items = [];
  int _pendingCount = 0;
  int _conflictCount = 0;
```

(Change `List<Map<String, dynamic>> _items` → `List<NoteEntity> _items`. All call sites that read `note['title']` need to read `note.title` etc.)

**Replace `initState`:**

```dart
  @override
  void initState() {
    super.initState();
    _notesSub = _repo.watchAll().listen((notes) {
      if (mounted) setState(() => _items = notes);
    });
    _pendingSub = _repo.watchPendingCount().listen((c) {
      if (mounted) setState(() => _pendingCount = c);
    });
    _conflictSub = _repo.watchConflictCount().listen((c) {
      if (mounted) setState(() => _conflictCount = c);
    });
    _repo.refresh(); // fire-and-forget; UI already shows cached
  }
```

**Replace `dispose`:**

```dart
  @override
  void dispose() {
    _notesSub?.cancel();
    _pendingSub?.cancel();
    _conflictSub?.cancel();
    super.dispose();
  }
```

**Replace all callsites that previously did `_cache.save(...)`** — delete them (the repo handles persistence).

**Create handler (in the "+" button onPressed):**

```dart
  Future<void> _onCreate(String title, String content) async {
    await _repo.create(title, content);
    // No setState needed — watchAll() emits.
  }
```

**Update handler:**

```dart
  Future<void> _onUpdate(String id, {String? title, String? content}) async {
    await _repo.update(id, title: title, content: content);
  }
```

**Delete handler:**

```dart
  Future<void> _onDelete(String id) async {
    await _repo.delete(id);
  }
```

**In the note card UI (within the list builder), show pending dot and conflict badge:**

```dart
  Widget _buildNoteCard(NoteEntity note) {
    // ... existing card UI ...
    final indicators = <Widget>[];
    if (note.conflictedWith != null) {
      indicators.add(GestureDetector(
        onTap: () => _showConflictDialog(note),
        child: const Icon(Icons.error_outline, size: 16, color: Colors.orange),
      ));
    } else if (note.localPending) {
      indicators.add(const Icon(Icons.sync, size: 12, color: Colors.grey));
    }
    // place indicators in a Row near the card title
  }
```

(`_showConflictDialog` is defined in Task 18.)

**Add a top-of-list banner when `_conflictCount > 0`:**

```dart
  Widget _buildConflictBanner() {
    if (_conflictCount == 0) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(12),
      color: Colors.orange.shade50,
      child: Row(
        children: [
          const Icon(Icons.warning_amber, color: Colors.orange),
          const SizedBox(width: 8),
          Expanded(child: Text('$_conflictCount notes need your attention')),
        ],
      ),
    );
  }
```

(Insert above the ListView in the screen's `build` method.)

- [ ] **Step 2: Analyze**

```bash
flutter analyze lib/features/notes/presentation/screens/notes_screen.dart
```

Expected: no errors. Existing call sites that read note as `Map<String, dynamic>` will need property migration (e.g. `note['title']` → `note.title`). Fix any remaining warnings.

- [ ] **Step 3: Smoke-run the screen in widget tests is impractical due to dialog complexity** — covered by hardware smoke in Task 19. Run the full test suite to confirm no regressions:

```bash
flutter test
```

Expected: all existing tests still pass.

- [ ] **Step 4: Commit**

```bash
git add lib/features/notes/presentation/screens/notes_screen.dart
git commit -m "$(cat <<'EOF'
refactor(notes): use INotesRepository + streams; add pending/conflict UI

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 18: Mobile — `ConflictResolutionDialog`

**Files:**
- Create: `~/Downloads/taler_id_mobile/lib/features/notes/presentation/widgets/conflict_resolution_dialog.dart`
- Use from `notes_screen.dart` (a one-liner already wired in Task 17 as `_showConflictDialog`).

- [ ] **Step 1: Create the dialog widget**

```dart
// lib/features/notes/presentation/widgets/conflict_resolution_dialog.dart
import 'package:flutter/material.dart';
import '../../domain/entities/note_entity.dart';

class ConflictResolutionDialog extends StatelessWidget {
  final NoteEntity local;
  final Future<void> Function(ConflictResolution) onResolve;

  const ConflictResolutionDialog({
    super.key,
    required this.local,
    required this.onResolve,
  });

  @override
  Widget build(BuildContext context) {
    final server = local.conflictedWith ?? <String, dynamic>{};
    return AlertDialog(
      title: const Text('Конфликт синхронизации'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Заметка была изменена на другом устройстве, пока ваши изменения ждали отправки.',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            _version('Моя версия', local.title, local.content, Colors.blue),
            const SizedBox(height: 12),
            _version('Версия с сервера', server['title'] as String? ?? '',
                server['content'] as String? ?? '', Colors.green),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Закрыть')),
        TextButton(
          onPressed: () async {
            Navigator.pop(context);
            await onResolve(ConflictResolution.acceptServer);
          },
          child: const Text('Принять серверную'),
        ),
        ElevatedButton(
          onPressed: () async {
            Navigator.pop(context);
            await onResolve(ConflictResolution.keepMine);
          },
          child: const Text('Оставить мою'),
        ),
      ],
    );
  }

  Widget _version(String label, String title, String content, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: color.withOpacity(0.4)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(content, maxLines: 5, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Wire `_showConflictDialog` in `notes_screen.dart`**

Add this method to `_NotesScreenState`:

```dart
  void _showConflictDialog(NoteEntity note) {
    showDialog(
      context: context,
      builder: (_) => ConflictResolutionDialog(
        local: note,
        onResolve: (choice) async {
          await _repo.resolveConflict(note.id, choice);
        },
      ),
    );
  }
```

Add the import:

```dart
import '../widgets/conflict_resolution_dialog.dart';
```

- [ ] **Step 3: Analyze**

```bash
flutter analyze lib/features/notes/presentation/screens/notes_screen.dart lib/features/notes/presentation/widgets/conflict_resolution_dialog.dart
```

Expected: no errors.

- [ ] **Step 4: Commit**

```bash
git add lib/features/notes/presentation/widgets/conflict_resolution_dialog.dart lib/features/notes/presentation/screens/notes_screen.dart
git commit -m "$(cat <<'EOF'
feat(notes): conflict resolution dialog (keep mine / accept server)

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 19: Hardware smoke (mandatory before merge)

- [ ] **Step 1: Build dev APK locally and install on a wired Android (or sideload)**

```bash
cd ~/Downloads/taler_id_mobile
flutter run --flavor dev -t lib/main_dev.dart \
  --dart-define=FLAVOR=dev --dart-define=BASE_URL=https://staging.id.taler.tirol \
  -d <android-device-id>
```

- [ ] **Step 2: Offline create / edit / delete**

1. Airplane mode ON.
2. Create 3 notes — confirm all appear with a small sync indicator.
3. Edit one — indicator stays, title updates immediately.
4. Delete one — disappears immediately.
5. Airplane mode OFF — within 5 seconds, indicators on remaining 2 notes disappear.
6. Reload notes screen — server list matches what's visible locally.

- [ ] **Step 3: Conflict scenario**

1. Open a note, airplane mode ON.
2. Edit the note's title to "phone-edit".
3. From a second device (or curl with the integration test account on PROD if dev is dual-purposed):
   ```bash
   TOKEN=$(curl -s -X POST https://staging.id.taler.tirol/auth/login \
     -H "Content-Type: application/json" \
     -d '{"email":"integration_test@taler-test.com","password":"IntegrationTest123!"}' \
     | jq -r .accessToken)
   curl -s -X PATCH https://staging.id.taler.tirol/notes/<note-id> \
     -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
     -d '{"title":"desktop-edit"}'
   ```
4. Airplane mode OFF on the phone.
5. Within seconds: conflict banner appears at top of notes list.
6. Tap the conflicted note → dialog opens with "phone-edit" vs "desktop-edit".
7. Choose "Оставить мою" → dialog closes, sync indicator briefly returns, then disappears.
8. Refresh from another browser/device → server has "phone-edit".

- [ ] **Step 4: Kill-mid-sync**

1. Airplane mode ON.
2. Create a note "kill-test".
3. Airplane mode OFF.
4. Immediately force-quit the app (recents tray → swipe up).
5. Relaunch the app.
6. Note "kill-test" appears in the list. Within seconds of launch, sync indicator disappears.
7. `curl` `GET /notes` confirms it's on the server.

- [ ] **Step 5: Document any issues**

If anything fails, add observations to `docs/superpowers/specs/2026-05-13-notes-offline-design.md` under a new "Smoke results" section and DO NOT merge to main.

---

## Task 20: Deploy mobile dev branch

- [ ] **Step 1: Push**

```bash
cd ~/Downloads/taler_id_mobile
git push origin dev
```

- [ ] **Step 2: Build dev APK on the PROD server (per CLAUDE.md APK flow)**

```bash
ssh dvolkov@138.124.61.221
cd ~/taler_id_mobile && git checkout dev && git pull origin dev
flutter build apk --flavor dev --release -t lib/main_dev.dart \
  --dart-define=FLAVOR=dev --dart-define=BASE_URL=https://staging.id.taler.tirol
sudo cp build/app/outputs/flutter-apk/app-dev-release.apk /var/www/downloads/taler-id-dev.apk
```

- [ ] **Step 3: Run all DEV tests**

```bash
cd ~/Downloads/taler_id_tests
npm test && npm run test:sync && npm run test:notes:offline && npm run test:files && npm run test:channels && npm run test:billing
```

Expected: all green.

---

## Task 21: HARD GATE — wait for explicit PROD approval

Per CLAUDE.md: "На PROD переносить ТОЛЬКО при явном указании пользователя."

- [ ] **Step 1: Report DEV results and ask**

Post a status summary:
- Backend deployed to DEV, integration test green.
- Mobile dev APK published; hardware smoke passes for all 3 scenarios (offline CRUD, conflict, kill-mid-sync).
- All DEV API tests green.

Then ask: "Готов к деплою на PROD?"

**Do not proceed without an explicit "да" / "go".**

---

## Task 22: Deploy to PROD (only after explicit approval)

- [ ] **Step 1: Backend to PROD**

```bash
ssh dvolkov@138.124.61.221 'cd ~/taler-id && git checkout main && git pull origin main && git merge dev --ff-only && git push origin main && npm run build && pm2 restart taler-id'
```

(If fast-forward fails, abort and ask the user — likely main has independent commits that need a separate merge plan.)

- [ ] **Step 2: Build PROD APK**

```bash
ssh dvolkov@138.124.61.221
cd ~/taler_id_mobile && git checkout main && git merge dev && git push origin main
flutter build apk --flavor prod --release --dart-define=FLAVOR=prod
sudo cp build/app/outputs/flutter-apk/app-prod-release.apk /var/www/downloads/taler-id.apk
```

- [ ] **Step 3: Build PROD iOS IPA + upload to TestFlight**

Locally on Mac:

```bash
cd ~/Downloads/taler_id_mobile
git checkout main && git pull
flutter build ipa --release --export-options-plist ios/ExportOptions.plist
xcrun altool --upload-app --type ios -f build/ios/ipa/*.ipa \
  --apiKey J3P22V4URD --apiIssuer 44b87272-3052-40ea-a48a-6c6f88a2df11
```

Set TestFlight release notes in Russian (per CLAUDE.md — mandatory step).

- [ ] **Step 4: Run the PROD test suite**

```bash
cd ~/Downloads/taler_id_tests
npm run test:prod && npm run test:sync:prod && npm run test:notes:offline:prod \
  && npm run test:voice:prod && npm run test:assistant:prod \
  && npm run test:files:prod && npm run test:channels:prod && npm run test:billing:prod
```

Expected: all green.

---

## Spec coverage check (self-review)

| Spec requirement | Implemented in task |
|---|---|
| `POST /notes` accepts optional `id`, idempotent on retry | Task 2 |
| `POST /notes` 409 when `id` collides with another user's | Task 2 |
| `PATCH /notes/:id` accepts optional `expectedUpdatedAt` (OCC) | Task 3 |
| `PATCH` 409 with `currentNote` in body on stale | Task 3 |
| `DELETE` 404 → success | Task 13 (datasource), Task 14 (handler success branch) |
| Hive `notes_local` box for local source of truth | Task 12 |
| Hive `outbox_v1` box for pending ops | Task 7 |
| `OutboxQueue` with FIFO + status transitions | Task 7 |
| `OutboxReplayService` with single-flight drain | Task 8 |
| `OutboxReplayHandler` interface + sealed result type | Task 6 |
| `ConnectivityWatcher` triggers drain on offline→online | Task 9 |
| `NoteEntity` Freezed + `NoteSource` + `ConflictResolution` enums | Task 10 |
| `INotesRepository` interface | Task 11 |
| `NotesLocalDataSource` (Hive watch + CRUD) | Task 12 |
| `NotesRemoteDataSource` id param, expectedUpdatedAt, `NoteConflictException` | Task 13 |
| `NotesOutboxReplayHandler` HTTP outcome mapping | Task 14 |
| `NotesRepositoryImpl` create/update/delete + squash logic | Task 15 |
| `refresh()` server diff respecting `localPending` | Task 15 |
| `resolveConflict(KEEP_MINE / ACCEPT_SERVER)` | Task 15 |
| DI wiring + Hive box opening + handler registration + boot drain | Task 16 |
| `notes_screen.dart` refactor with streams + pending dot + banner | Task 17 |
| `ConflictResolutionDialog` | Task 18 |
| Hardware smoke (offline CRUD, conflict, kill-mid-sync) | Task 19 |
| DEV deploy + tests | Task 4, Task 20 |
| Explicit PROD gate | Task 21 |
| PROD deploy + tests | Task 22 |
| **Out of scope:** desktop port, calendar/contacts/favorites application, 3-way merge, transaction log | n/a (separate specs) |

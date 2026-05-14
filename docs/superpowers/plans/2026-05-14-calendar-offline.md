# Calendar Offline (CRUD + OCC) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Apply the existing outbox + OCC pattern to CalendarEvent CRUD: create / update / delete work offline, sync on reconnect, conflicts surface to the user. Reuses the `OutboxQueue`, `OutboxReplayService`, `ConnectivityWatcher`, and `ConflictResolutionDialog` from the notes work (already on `dev`).

**Architecture:** Server gains an optional `id` on create (idempotent retry) and an optional `expectedUpdatedAt` on update (OCC, 409 with `currentEvent`). Client gets a `CalendarLocalDataSource` (Hive box `calendar_events_local`), `CalendarRepositoryImpl` orchestrating local + outbox + remote, and a `CalendarOutboxReplayHandler` mapping HTTP outcomes to `OutboxReplayResult`. `calendar_screen.dart` swaps direct datasource writes for the repo while keeping the existing month/day view UI intact. Invites stay online-only (separate spec).

**Tech Stack:** NestJS + Prisma + PostgreSQL on the server. Flutter + Hive + Freezed on the client.

**Spec:** `docs/superpowers/specs/2026-05-14-calendar-offline-design.md`

**Repos:**
- Backend: `~/taler-id/` (work on `dev` branch)
- Mobile: `~/Downloads/taler_id_mobile/` (work on `dev` branch)
- Integration tests: `~/Downloads/taler_id_tests/` (not a git repo — no commits)

---

## File Structure

### Backend (`taler-id`)
- **Modify** `src/calendar/calendar.service.ts` — `create` accepts optional `id` (idempotent); `update` accepts `expectedUpdatedAt` (OCC).
- **Create** `src/calendar/calendar.service.spec.ts` — unit tests for create + update OCC.
- (Controller already uses `@Body() body: any` — no changes needed there.)

### Integration tests (`taler_id_tests`)
- **Create** `calendar_offline_test.ts`.
- **Modify** `package.json` — add `test:calendar:offline` and `test:calendar:offline:prod`.

### Mobile (`taler_id_mobile`)
- **Create** `lib/features/calendar/domain/entities/calendar_event_entity.dart` — Freezed `CalendarEventEntity` + `CalendarEventType` enum.
- **Create** `lib/features/calendar/domain/repositories/i_calendar_repository.dart`.
- **Create** `lib/features/calendar/data/datasources/calendar_local_datasource.dart` (Hive box `calendar_events_local`).
- **Modify** `lib/features/calendar/data/datasources/calendar_remote_datasource.dart` — `id?` on create, `expectedUpdatedAt?` on update; throws `CalendarConflictException` on 409; `delete` swallows 404.
- **Create** `lib/features/calendar/data/repositories/calendar_repository_impl.dart`.
- **Create** `lib/features/calendar/data/services/calendar_outbox_replay_handler.dart`.
- **Modify** `lib/features/calendar/presentation/screens/calendar_screen.dart` — route event CRUD through repo; preserve view widgets and invite handling.
- **Modify** `lib/core/di/service_locator.dart` — open `calendar_events_local` box; register new services; register `CalendarOutboxReplayHandler` with `OutboxReplayService`.
- Test files mirroring each new class.

### Reused (NO new code)
- `lib/core/storage/outbox_op.dart`, `outbox_queue.dart`, `services/outbox_replay_service.dart`, `services/outbox_replay_handler.dart`, `services/connectivity_watcher.dart` — all live on `dev`.
- `lib/features/notes/presentation/widgets/conflict_resolution_dialog.dart` — generic enough (reads `local.title` + `local.content`-shape); we pass `CalendarEventEntity` adapter map. See Task 13 step 7.

---

## Task 1: Backend — `create` accepts optional id (TDD)

**Files:**
- Create: `~/taler-id/src/calendar/calendar.service.spec.ts`
- Modify: `~/taler-id/src/calendar/calendar.service.ts`

- [ ] **Step 0: Switch backend repo to `dev`**

```bash
cd ~/taler-id
git checkout dev && git pull origin dev
```

- [ ] **Step 1: Write the failing create tests**

Create `src/calendar/calendar.service.spec.ts`:

```typescript
import { Test } from '@nestjs/testing';
import { CalendarService } from './calendar.service';
import { PrismaService } from '../prisma/prisma.service';
import { FcmService } from '../common/fcm.service';
import { ConflictException } from '@nestjs/common';

describe('CalendarService.create', () => {
  let service: CalendarService;
  let prisma: any;

  beforeEach(async () => {
    prisma = {
      calendarEvent: {
        create: jest.fn(),
        findUnique: jest.fn(),
      },
      calendarInvite: { upsert: jest.fn() },
      user: { findUnique: jest.fn().mockResolvedValue(null) },
    };
    const mod = await Test.createTestingModule({
      providers: [
        CalendarService,
        { provide: PrismaService, useValue: prisma },
        { provide: FcmService, useValue: { sendCalendarInvite: jest.fn() } },
      ],
    }).compile();
    service = mod.get(CalendarService);
  });

  const baseInput = {
    title: 'Coffee',
    type: 'EVENT',
    startAt: '2026-05-14T10:00:00.000Z',
  };

  it('without id: creates as before', async () => {
    prisma.calendarEvent.create.mockResolvedValue({ id: 'srv', userId: 'u1', ...baseInput });
    await service.create('u1', baseInput);
    expect(prisma.calendarEvent.create).toHaveBeenCalled();
    const arg = prisma.calendarEvent.create.mock.calls[0][0].data;
    expect(arg.id).toBeUndefined();
  });

  it('with id: passes id through to Prisma', async () => {
    prisma.calendarEvent.findUnique.mockResolvedValue(null);
    prisma.calendarEvent.create.mockResolvedValue({ id: 'mine', userId: 'u1', ...baseInput });
    const out = await service.create('u1', { ...baseInput, id: 'mine' } as any);
    expect(prisma.calendarEvent.create).toHaveBeenCalledWith({
      data: expect.objectContaining({ id: 'mine', userId: 'u1', title: 'Coffee' }),
    });
    expect(out.id).toBe('mine');
  });

  it('with id of an existing event owned by same user: returns existing, idempotent (no double-create)', async () => {
    prisma.calendarEvent.findUnique.mockResolvedValue({ id: 'mine', userId: 'u1', title: 'orig' });
    const out = await service.create('u1', { ...baseInput, id: 'mine' } as any);
    expect(prisma.calendarEvent.create).not.toHaveBeenCalled();
    expect(out).toEqual({ id: 'mine', userId: 'u1', title: 'orig' });
  });

  it('with id of an event owned by another user: throws ConflictException', async () => {
    prisma.calendarEvent.findUnique.mockResolvedValue({ id: 'theirs', userId: 'other' });
    await expect(
      service.create('u1', { ...baseInput, id: 'theirs' } as any),
    ).rejects.toBeInstanceOf(ConflictException);
    expect(prisma.calendarEvent.create).not.toHaveBeenCalled();
  });
});
```

- [ ] **Step 2: Run — should FAIL on 3 tests**

```bash
cd ~/taler-id
npx jest src/calendar/calendar.service.spec.ts --no-coverage
```

Expected: 3 fail (the `id`-related cases). The "without id" case may pass on first run if the service forwards the params shape compatibly.

- [ ] **Step 3: Update `calendar.service.ts` — accept `id?` and idempotent on collision**

In `src/calendar/calendar.service.ts`, edit the `create` method's data parameter type and add the pre-check:

```typescript
  async create(
    userId: string,
    data: {
      id?: string;
      title: string;
      description?: string;
      type: string;
      startAt: string;
      endAt?: string;
      allDay?: boolean;
      reminderAt?: string;
      contactIds?: string[];
      createdBy?: string;
      displayTime?: string;
      recurrence?: {
        frequency: string;
        interval?: number;
        endAt?: string;
      } | null;
    },
  ) {
    if (data.id) {
      const existing = await this.prisma.calendarEvent.findUnique({
        where: { id: data.id },
      });
      if (existing) {
        if (existing.userId !== userId) {
          throw new ConflictException('Event id already used by another account');
        }
        return existing;
      }
    }

    const event = await this.prisma.calendarEvent.create({
      data: {
        ...(data.id ? { id: data.id } : {}),
        userId,
        title: data.title,
        description: data.description ?? null,
        type: data.type as any,
        startAt: new Date(data.startAt),
        endAt: data.endAt ? new Date(data.endAt) : null,
        allDay: data.allDay ?? false,
        reminderAt: data.reminderAt ? new Date(data.reminderAt) : null,
        displayTime: data.displayTime ?? null,
        recurrence: data.recurrence ?? Prisma.DbNull,
        contactIds: data.contactIds ?? [],
        createdBy: data.createdBy ?? 'MANUAL',
      },
    });

    // (existing invite + FCM block follows unchanged)
```

Add `ConflictException` to the imports at the top of the file:

```typescript
import {
  Injectable,
  NotFoundException,
  ForbiddenException,
  ConflictException,
  Logger,
} from '@nestjs/common';
```

- [ ] **Step 4: Run — 4/4 PASS**

```bash
cd ~/taler-id
npx jest src/calendar/calendar.service.spec.ts --no-coverage
```

- [ ] **Step 5: Commit**

```bash
cd ~/taler-id
git add src/calendar/calendar.service.ts src/calendar/calendar.service.spec.ts
git commit -m "$(cat <<'EOF'
feat(calendar): create accepts optional client-supplied id (idempotent)

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 2: Backend — `update` with OCC (TDD)

**Files:**
- Modify: `~/taler-id/src/calendar/calendar.service.ts` — extend `update`.
- Modify: `~/taler-id/src/calendar/calendar.service.spec.ts` — append `describe('CalendarService.update', …)`.

- [ ] **Step 1: Append failing update tests**

In `src/calendar/calendar.service.spec.ts`, append after the existing `describe`:

```typescript
describe('CalendarService.update', () => {
  let service: CalendarService;
  let prisma: any;

  beforeEach(async () => {
    prisma = {
      calendarEvent: {
        findUnique: jest.fn(),
        update: jest.fn(),
      },
    };
    const mod = await Test.createTestingModule({
      providers: [
        CalendarService,
        { provide: PrismaService, useValue: prisma },
        { provide: FcmService, useValue: { sendCalendarInvite: jest.fn() } },
      ],
    }).compile();
    service = mod.get(CalendarService);
  });

  it('without expectedUpdatedAt: applies update (LWW, back-compat)', async () => {
    const now = new Date('2026-05-14T10:00:00Z');
    prisma.calendarEvent.findUnique.mockResolvedValue({ id: 'e1', userId: 'u1', updatedAt: now });
    prisma.calendarEvent.update.mockResolvedValue({ id: 'e1', userId: 'u1', title: 'new' });
    const out = await service.update('u1', 'e1', { title: 'new' });
    expect(prisma.calendarEvent.update).toHaveBeenCalled();
    expect(out.title).toBe('new');
  });

  it('with matching expectedUpdatedAt: applies update', async () => {
    const now = new Date('2026-05-14T10:00:00Z');
    prisma.calendarEvent.findUnique.mockResolvedValue({ id: 'e1', userId: 'u1', updatedAt: now });
    prisma.calendarEvent.update.mockResolvedValue({ id: 'e1', userId: 'u1', title: 'new' });
    const out = await service.update('u1', 'e1', { title: 'new', expectedUpdatedAt: now.toISOString() });
    expect(prisma.calendarEvent.update).toHaveBeenCalled();
    expect(out.title).toBe('new');
  });

  it('with stale expectedUpdatedAt: throws ConflictException with currentEvent in response', async () => {
    const dbTime = new Date('2026-05-14T10:05:00Z');
    const clientTs = new Date('2026-05-14T10:00:00Z').toISOString();
    const current = { id: 'e1', userId: 'u1', updatedAt: dbTime, title: 'on server' };
    prisma.calendarEvent.findUnique.mockResolvedValue(current);
    let thrown: any;
    try {
      await service.update('u1', 'e1', { title: 'mine', expectedUpdatedAt: clientTs });
    } catch (e) {
      thrown = e;
    }
    expect(thrown).toBeInstanceOf(ConflictException);
    const resp = (thrown as ConflictException).getResponse() as any;
    expect(resp.currentEvent).toEqual(current);
    expect(prisma.calendarEvent.update).not.toHaveBeenCalled();
  });

  it('with bogus expectedUpdatedAt string: throws ConflictException', async () => {
    const dbTime = new Date('2026-05-14T10:05:00Z');
    prisma.calendarEvent.findUnique.mockResolvedValue({ id: 'e1', userId: 'u1', updatedAt: dbTime });
    await expect(
      service.update('u1', 'e1', { title: 'mine', expectedUpdatedAt: 'not-a-date' }),
    ).rejects.toBeInstanceOf(ConflictException);
  });
});
```

- [ ] **Step 2: Run — should FAIL on the 4 new ones**

```bash
cd ~/taler-id
npx jest src/calendar/calendar.service.spec.ts --no-coverage
```

- [ ] **Step 3: Update the `update` method in `calendar.service.ts`**

Find the existing `async update(userId: string, id: string, data: any)` method. Modify the START of it so that after the existing existence + ownership checks, an OCC check runs, then the existing `updateData` building block continues unchanged. Concretely, add this block immediately after the `if (event.userId !== userId) throw new ForbiddenException();` line:

```typescript
    if (data.expectedUpdatedAt !== undefined) {
      const expected = new Date(data.expectedUpdatedAt);
      const sameMs =
        !Number.isNaN(expected.getTime()) &&
        expected.getTime() === event.updatedAt.getTime();
      if (!sameMs) {
        throw new ConflictException({
          message: 'Event updated elsewhere',
          currentEvent: event,
        });
      }
    }
```

The rest of `update` (the `updateData: any = {}; if (data.title !== undefined) ...; return this.prisma.calendarEvent.update(...)`) stays exactly as it is — `expectedUpdatedAt` is not copied into `updateData` because the `if (data.title !== undefined) updateData.title = ...` style ignores any field not explicitly listed.

- [ ] **Step 4: Run — all 8 should pass (4 create + 4 update)**

```bash
cd ~/taler-id
npx jest src/calendar/calendar.service.spec.ts --no-coverage
```

- [ ] **Step 5: Commit**

```bash
cd ~/taler-id
git add src/calendar/calendar.service.ts src/calendar/calendar.service.spec.ts
git commit -m "$(cat <<'EOF'
feat(calendar): update enforces optional expectedUpdatedAt (OCC)

When the client supplies expectedUpdatedAt and the DB has advanced past it,
respond with HTTP 409 + currentEvent in the response body. Without it, LWW
behavior is preserved for back-compat.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 3: Backend — Deploy to DEV + manual probes

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
curl -s -X POST https://staging.id.taler.tirol/calendar \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"id\":\"$ID\",\"title\":\"probe\",\"type\":\"EVENT\",\"startAt\":\"2026-05-14T12:00:00.000Z\"}" | jq '{id, title, type}'
echo "--- second (idempotent) create ---"
curl -s -X POST https://staging.id.taler.tirol/calendar \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"id\":\"$ID\",\"title\":\"ignored\",\"type\":\"EVENT\",\"startAt\":\"2099-01-01T00:00:00.000Z\"}" | jq '{id, title}'
```

Expected: same `id` both times; `title` is `probe` in both (idempotent).

- [ ] **Step 4: Probe OCC + cleanup**

```bash
echo "--- stale PATCH → expect 409 with currentEvent ---"
curl -s -X PATCH https://staging.id.taler.tirol/calendar/$ID \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"title":"x","expectedUpdatedAt":"1970-01-01T00:00:00.000Z"}' | jq '{statusCode, message, hasCurrentEvent: (.currentEvent != null)}'
echo "--- cleanup ---"
curl -s -X DELETE https://staging.id.taler.tirol/calendar/$ID -H "Authorization: Bearer $TOKEN" -o /dev/null -w "DELETE=%{http_code}\n"
```

Expected: `statusCode: 409`, `hasCurrentEvent: true`. DELETE=200.

---

## Task 4: Integration test (`taler_id_tests`)

**Files:**
- Create: `~/Downloads/taler_id_tests/calendar_offline_test.ts`
- Modify: `~/Downloads/taler_id_tests/package.json` — add scripts.

- [ ] **Step 1: Create `calendar_offline_test.ts`**

```typescript
// E2E test for the offline-friendly calendar endpoints.
// Run: npm run test:calendar:offline       (DEV)
//      npm run test:calendar:offline:prod  (PROD)

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

async function post(path: string, token: string, body: any) {
  const res = await fetch(`${BASE_URL}${path}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${token}` },
    body: JSON.stringify(body),
  });
  return { status: res.status, json: await res.json().catch(() => null) };
}

async function patch(path: string, token: string, body: any) {
  const res = await fetch(`${BASE_URL}${path}`, {
    method: 'PATCH',
    headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${token}` },
    body: JSON.stringify(body),
  });
  return { status: res.status, json: await res.json().catch(() => null) };
}

async function del(path: string, token: string) {
  const res = await fetch(`${BASE_URL}${path}`, {
    method: 'DELETE',
    headers: { Authorization: `Bearer ${token}` },
  });
  return res.status;
}

async function main() {
  console.log(`Calendar offline tests against ${BASE_URL}`);
  const token = await login();
  const id = randomUUID();
  const base = {
    title: 'offl-cal-1',
    type: 'EVENT',
    startAt: '2026-05-14T12:00:00.000Z',
  };

  await run('1. POST /calendar with custom id → returns same id', async () => {
    const r = await post('/calendar', token, { id, ...base });
    assert(r.status === 201 || r.status === 200, `status ${r.status}`);
    assert(r.json.id === id, `id mismatch: ${r.json.id}`);
  });

  await run('2. POST again with same id → idempotent, original payload preserved', async () => {
    const r = await post('/calendar', token, { id, title: 'ignored', type: 'EVENT', startAt: '2099-01-01T00:00:00.000Z' });
    assert(r.status === 201 || r.status === 200, `status ${r.status}`);
    assert(r.json.id === id, 'id mismatch');
    assert(r.json.title === 'offl-cal-1', `title should be offl-cal-1, got ${r.json.title}`);
  });

  let firstUpdatedAt = '';
  await run('3. PATCH without expectedUpdatedAt → LWW', async () => {
    const r = await patch(`/calendar/${id}`, token, { title: 'edit-1' });
    assert(r.status === 200, `status ${r.status}`);
    assert(r.json.title === 'edit-1', 'title not updated');
    firstUpdatedAt = r.json.updatedAt as string;
    assert(typeof firstUpdatedAt === 'string' && firstUpdatedAt.length > 0, 'no updatedAt');
  });

  await run('4. PATCH with matching expectedUpdatedAt → 200', async () => {
    const r = await patch(`/calendar/${id}`, token, { title: 'edit-2', expectedUpdatedAt: firstUpdatedAt });
    assert(r.status === 200, `status ${r.status}`);
    assert(r.json.title === 'edit-2', 'title not updated');
  });

  await run('5. PATCH with stale expectedUpdatedAt → 409 + currentEvent in body', async () => {
    const r = await patch(`/calendar/${id}`, token, { title: 'edit-stale', expectedUpdatedAt: firstUpdatedAt });
    assert(r.status === 409, `expected 409, got ${r.status}`);
    assert(!!r.json.currentEvent, 'currentEvent missing in 409 body');
    assert(r.json.currentEvent.id === id, 'currentEvent.id mismatch');
  });

  await run('6. DELETE → 200', async () => {
    const code = await del(`/calendar/${id}`, token);
    assert(code === 200 || code === 204, `delete status ${code}`);
  });

  await run('7. DELETE again → 404 (idempotent for client)', async () => {
    const code = await del(`/calendar/${id}`, token);
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
npx tsc --noEmit calendar_offline_test.ts
```

- [ ] **Step 3: Add npm scripts**

Open `~/Downloads/taler_id_tests/package.json` and add inside `"scripts"`:

```
    "test:calendar:offline": "npx ts-node calendar_offline_test.ts",
    "test:calendar:offline:prod": "BASE_URL=https://id.taler.tirol npx ts-node calendar_offline_test.ts",
```

- [ ] **Step 4: Run on DEV**

```bash
cd ~/Downloads/taler_id_tests
npm run test:calendar:offline
```

Expected: 7/7 passed.

- [ ] **Step 5: Skip commit** — directory is not a git repo.

---

## Task 5: Mobile — `CalendarEventEntity` (Freezed)

**Files:**
- Create: `~/Downloads/taler_id_mobile/lib/features/calendar/domain/entities/calendar_event_entity.dart`

- [ ] **Step 0: Switch mobile to `dev`**

```bash
cd ~/Downloads/taler_id_mobile
git checkout dev && git pull origin dev
```

- [ ] **Step 1: Create the entity**

```dart
// lib/features/calendar/domain/entities/calendar_event_entity.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'calendar_event_entity.freezed.dart';
part 'calendar_event_entity.g.dart';

enum CalendarEventType {
  @JsonValue('CALL') call,
  @JsonValue('EVENT') event,
  @JsonValue('TASK') task,
  @JsonValue('REMINDER') reminder,
}

@freezed
class CalendarEventEntity with _$CalendarEventEntity {
  const factory CalendarEventEntity({
    required String id,
    required String title,
    String? description,
    @Default(CalendarEventType.event) CalendarEventType type,
    required DateTime startAt,
    DateTime? endAt,
    @Default(false) bool allDay,
    DateTime? reminderAt,
    @Default(false) bool reminderSent,
    String? displayTime,
    Map<String, dynamic>? recurrence,
    @Default(<String>[]) List<String> contactIds,
    @Default('MANUAL') String createdBy,
    required DateTime createdAt,
    required DateTime updatedAt,
    @Default(false) bool localPending,
    Map<String, dynamic>? conflictedWith,
  }) = _CalendarEventEntity;

  factory CalendarEventEntity.fromJson(Map<String, dynamic> json) =>
      _$CalendarEventEntityFromJson(json);
}
```

- [ ] **Step 2: Code-gen**

```bash
cd ~/Downloads/taler_id_mobile
dart run build_runner build --delete-conflicting-outputs
```

Note: build_runner may exit non-zero due to pre-existing mesh-crypto test syntax errors. As long as `calendar_event_entity.freezed.dart` and `.g.dart` get generated, that's fine.

- [ ] **Step 3: Analyze**

```bash
flutter analyze lib/features/calendar/domain/entities/calendar_event_entity.dart
```

Expected: no errors.

- [ ] **Step 4: Commit**

```bash
git add lib/features/calendar/domain/entities/calendar_event_entity.dart lib/features/calendar/domain/entities/calendar_event_entity.freezed.dart lib/features/calendar/domain/entities/calendar_event_entity.g.dart
git commit -m "$(cat <<'EOF'
feat(calendar): add CalendarEventEntity (Freezed) + CalendarEventType enum

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 6: Mobile — `ICalendarRepository` interface

**Files:**
- Create: `~/Downloads/taler_id_mobile/lib/features/calendar/domain/repositories/i_calendar_repository.dart`

- [ ] **Step 1: Create the interface**

```dart
// lib/features/calendar/domain/repositories/i_calendar_repository.dart
import '../entities/calendar_event_entity.dart';
import '../../../notes/domain/entities/note_entity.dart' show ConflictResolution;

abstract class ICalendarRepository {
  Stream<List<CalendarEventEntity>> watchAll();
  Future<void> refresh({DateTime? from, DateTime? to});
  Future<CalendarEventEntity> create(CalendarEventEntity draft);
  Future<CalendarEventEntity> update(
    String id, {
    String? title,
    String? description,
    CalendarEventType? type,
    DateTime? startAt,
    DateTime? endAt,
    bool? allDay,
    DateTime? reminderAt,
    String? displayTime,
    Map<String, dynamic>? recurrence,
    List<String>? contactIds,
  });
  Future<void> delete(String id);
  Future<void> resolveConflict(String id, ConflictResolution choice);
  Stream<int> watchPendingCount();
  Stream<int> watchConflictCount();
}
```

(We reuse `ConflictResolution` from notes; if we later want true generality we can move it to a shared core file. Cross-feature import is acceptable here since `ConflictResolution` is a pure enum.)

- [ ] **Step 2: Analyze**

```bash
flutter analyze lib/features/calendar/domain/repositories/i_calendar_repository.dart
```

- [ ] **Step 3: Commit**

```bash
git add lib/features/calendar/domain/repositories/i_calendar_repository.dart
git commit -m "$(cat <<'EOF'
feat(calendar): add ICalendarRepository abstract interface

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 7: Mobile — `CalendarLocalDataSource` (TDD)

**Files:**
- Create: `~/Downloads/taler_id_mobile/lib/features/calendar/data/datasources/calendar_local_datasource.dart`
- Create: `~/Downloads/taler_id_mobile/test/features/calendar/data/datasources/calendar_local_datasource_test.dart`

- [ ] **Step 1: Failing test**

```dart
// test/features/calendar/data/datasources/calendar_local_datasource_test.dart
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:taler_id_mobile/features/calendar/data/datasources/calendar_local_datasource.dart';
import 'package:taler_id_mobile/features/calendar/domain/entities/calendar_event_entity.dart';

class _FakePathProvider extends PathProviderPlatform with MockPlatformInterfaceMixin {
  final String dir;
  _FakePathProvider(this.dir);
  @override Future<String?> getApplicationDocumentsPath() async => dir;
  @override Future<String?> getApplicationSupportPath() async => dir;
  @override Future<String?> getTemporaryPath() async => dir;
}

CalendarEventEntity ev(String id, {DateTime? startAt, DateTime? updatedAt}) =>
    CalendarEventEntity(
      id: id,
      title: 'T-$id',
      startAt: startAt ?? DateTime.parse('2026-05-14T10:00:00Z'),
      createdAt: DateTime.parse('2026-05-14T09:00:00Z'),
      updatedAt: updatedAt ?? DateTime.parse('2026-05-14T09:00:00Z'),
    );

void main() {
  late Directory tempDir;

  setUpAll(() { TestWidgetsFlutterBinding.ensureInitialized(); });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('cal_local_test_');
    PathProviderPlatform.instance = _FakePathProvider(tempDir.path);
    Hive.init(tempDir.path);
    await Hive.openBox<String>(CalendarLocalDataSource.boxName);
  });

  tearDown(() async {
    await Hive.close();
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  test('upsert + getAll returns events in startAt-asc order', () async {
    final ds = CalendarLocalDataSource();
    await ds.upsert(ev('a', startAt: DateTime.parse('2026-05-14T12:00:00Z')));
    await ds.upsert(ev('b', startAt: DateTime.parse('2026-05-14T09:00:00Z')));
    final list = await ds.getAll();
    expect(list.map((e) => e.id).toList(), ['b', 'a']);
  });

  test('remove drops the entry', () async {
    final ds = CalendarLocalDataSource();
    await ds.upsert(ev('a'));
    await ds.remove('a');
    expect((await ds.getAll()).isEmpty, true);
  });

  test('upsert replaces existing by id', () async {
    final ds = CalendarLocalDataSource();
    await ds.upsert(ev('a'));
    await ds.upsert(ev('a').copyWith(title: 'updated'));
    final list = await ds.getAll();
    expect(list.length, 1);
    expect(list[0].title, 'updated');
  });

  test('watchAll emits on changes', () async {
    final ds = CalendarLocalDataSource();
    final emissions = <int>[];
    final sub = ds.watchAll().listen((events) => emissions.add(events.length));
    await Future<void>.delayed(const Duration(milliseconds: 50));
    await ds.upsert(ev('a'));
    await Future<void>.delayed(const Duration(milliseconds: 50));
    await ds.upsert(ev('b'));
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(emissions, contains(1));
    expect(emissions, contains(2));
    await sub.cancel();
  });
}
```

- [ ] **Step 2: Run — fail (file missing)**

```bash
flutter test test/features/calendar/data/datasources/calendar_local_datasource_test.dart
```

- [ ] **Step 3: Implement**

```dart
// lib/features/calendar/data/datasources/calendar_local_datasource.dart
import 'dart:async';
import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../../domain/entities/calendar_event_entity.dart';

class CalendarLocalDataSource {
  static const String boxName = 'calendar_events_local';

  Box<String> get _box => Hive.box<String>(boxName);

  Future<List<CalendarEventEntity>> getAll() async {
    final list = _box.keys
        .cast<String>()
        .map((k) => _decode(_box.get(k)!))
        .whereType<CalendarEventEntity>()
        .toList()
      ..sort((a, b) => a.startAt.compareTo(b.startAt));
    return list;
  }

  Future<CalendarEventEntity?> getById(String id) async {
    final raw = _box.get(id);
    if (raw == null) return null;
    return _decode(raw);
  }

  Future<void> upsert(CalendarEventEntity event) async {
    await _box.put(event.id, jsonEncode(event.toJson()));
  }

  Future<void> remove(String id) async {
    await _box.delete(id);
  }

  Stream<List<CalendarEventEntity>> watchAll() {
    final controller = StreamController<List<CalendarEventEntity>>.broadcast();
    StreamSubscription? sub;
    controller.onListen = () async {
      controller.add(await getAll());
      sub = _box.watch().listen((_) async {
        controller.add(await getAll());
      });
    };
    controller.onCancel = () async {
      await sub?.cancel();
    };
    return controller.stream;
  }

  CalendarEventEntity? _decode(String raw) {
    try {
      return CalendarEventEntity.fromJson(Map<String, dynamic>.from(jsonDecode(raw) as Map));
    } catch (_) {
      return null;
    }
  }
}
```

- [ ] **Step 4: Run — 4/4 PASS**

```bash
flutter test test/features/calendar/data/datasources/calendar_local_datasource_test.dart
```

- [ ] **Step 5: Commit**

```bash
git add lib/features/calendar/data/datasources/calendar_local_datasource.dart test/features/calendar/data/datasources/calendar_local_datasource_test.dart
git commit -m "$(cat <<'EOF'
feat(calendar): add CalendarLocalDataSource (Hive box calendar_events_local)

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 8: Mobile — `CalendarRemoteDataSource` updates

**Files:**
- Modify: `~/Downloads/taler_id_mobile/lib/features/calendar/data/datasources/calendar_remote_datasource.dart`

- [ ] **Step 1: Replace the file**

```dart
import 'package:dio/dio.dart';
import '../../../../core/api/dio_client.dart';

class CalendarConflictException implements Exception {
  final Map<String, dynamic> currentEvent;
  CalendarConflictException(this.currentEvent);
}

class CalendarRemoteDataSource {
  final DioClient _http;
  CalendarRemoteDataSource(this._http);

  Future<List<Map<String, dynamic>>> getEvents({String? from, String? to}) async {
    final params = <String, String>{};
    if (from != null) params['from'] = from;
    if (to != null) params['to'] = to;
    final query = params.entries.map((e) => '${e.key}=${e.value}').join('&');
    final data = await _http.get<dynamic>('/calendar${query.isNotEmpty ? '?$query' : ''}');
    return (data as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<Map<String, dynamic>> create(Map<String, dynamic> data, {String? id}) async {
    final body = <String, dynamic>{
      if (id != null) 'id': id,
      ...data,
    };
    return _http.post('/calendar', data: body, fromJson: (d) => Map<String, dynamic>.from(d as Map));
  }

  Future<Map<String, dynamic>> update(
    String id,
    Map<String, dynamic> data, {
    DateTime? expectedUpdatedAt,
  }) async {
    final body = <String, dynamic>{
      ...data,
      if (expectedUpdatedAt != null)
        'expectedUpdatedAt': expectedUpdatedAt.toUtc().toIso8601String(),
    };
    try {
      return await _http.patch('/calendar/$id', data: body, fromJson: (d) => Map<String, dynamic>.from(d as Map));
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) {
        final body = e.response!.data;
        final current = (body is Map && body['currentEvent'] is Map)
            ? Map<String, dynamic>.from(body['currentEvent'] as Map)
            : <String, dynamic>{};
        throw CalendarConflictException(current);
      }
      rethrow;
    }
  }

  Future<void> delete(String id) async {
    try {
      await _http.delete('/calendar/$id');
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return; // idempotent
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getMyInvites() async {
    final data = await _http.get<dynamic>('/calendar/invites');
    return (data as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<void> acceptInvite(String inviteId) async {
    await _http.patch('/calendar/invites/$inviteId/accept', data: {}, fromJson: (d) => d);
  }

  Future<void> declineInvite(String inviteId) async {
    await _http.patch('/calendar/invites/$inviteId/decline', data: {}, fromJson: (d) => d);
  }

  Future<void> maybeInvite(String inviteId) async {
    await _http.patch('/calendar/invites/$inviteId/maybe', data: {}, fromJson: (d) => d);
  }
}
```

- [ ] **Step 2: Analyze**

```bash
flutter analyze lib/features/calendar/data/datasources/calendar_remote_datasource.dart
```

- [ ] **Step 3: Commit**

```bash
git add lib/features/calendar/data/datasources/calendar_remote_datasource.dart
git commit -m "$(cat <<'EOF'
feat(calendar): remote datasource accepts id (create) + expectedUpdatedAt (update)

On 409 from update, throws CalendarConflictException with the server's
currentEvent in payload. On 404 from delete, swallows for idempotency.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 9: Mobile — `CalendarOutboxReplayHandler` (TDD)

**Files:**
- Create: `~/Downloads/taler_id_mobile/lib/features/calendar/data/services/calendar_outbox_replay_handler.dart`
- Create: `~/Downloads/taler_id_mobile/test/features/calendar/data/services/calendar_outbox_replay_handler_test.dart`

- [ ] **Step 1: Failing tests**

```dart
// test/features/calendar/data/services/calendar_outbox_replay_handler_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:taler_id_mobile/core/services/outbox_replay_handler.dart';
import 'package:taler_id_mobile/core/storage/outbox_op.dart';
import 'package:taler_id_mobile/features/calendar/data/datasources/calendar_remote_datasource.dart';
import 'package:taler_id_mobile/features/calendar/data/services/calendar_outbox_replay_handler.dart';

class _MockRemote extends Mock implements CalendarRemoteDataSource {}

OutboxOp _op({
  OutboxOpKind op = OutboxOpKind.create,
  Map<String, dynamic>? payload,
  DateTime? expectedUpdatedAt,
}) =>
    OutboxOp(
      opId: 'op-1',
      feature: 'calendar',
      op: op,
      entityId: 'e-1',
      payload: payload,
      expectedUpdatedAt: expectedUpdatedAt,
      createdAt: DateTime.now(),
    );

void main() {
  late _MockRemote remote;
  late CalendarOutboxReplayHandler handler;

  setUp(() {
    remote = _MockRemote();
    handler = CalendarOutboxReplayHandler(remote: remote);
  });

  test('create success → OutboxReplaySuccess', () async {
    when(() => remote.create(any(), id: 'e-1'))
        .thenAnswer((_) async => {'id': 'e-1', 'title': 't'});
    final res = await handler.replay(
      _op(payload: {'title': 't', 'type': 'EVENT', 'startAt': '2026-05-14T10:00:00Z'}),
    );
    expect(res, isA<OutboxReplaySuccess>());
  });

  test('update conflict → OutboxReplayConflict with serverData', () async {
    when(() => remote.update('e-1', any(), expectedUpdatedAt: any(named: 'expectedUpdatedAt')))
        .thenThrow(CalendarConflictException({'id': 'e-1', 'title': 'srv'}));
    final res = await handler.replay(_op(
      op: OutboxOpKind.update,
      payload: {'title': 't'},
      expectedUpdatedAt: DateTime.parse('2026-05-14T10:00:00Z'),
    ));
    expect(res, isA<OutboxReplayConflict>());
    expect((res as OutboxReplayConflict).serverData['title'], 'srv');
  });

  test('delete 404 → success (idempotent via datasource)', () async {
    when(() => remote.delete('e-1')).thenAnswer((_) async {});
    final res = await handler.replay(_op(op: OutboxOpKind.delete));
    expect(res, isA<OutboxReplaySuccess>());
  });

  test('unknown error → retry', () async {
    when(() => remote.create(any(), id: 'e-1')).thenThrow(Exception('network'));
    final res = await handler.replay(
      _op(payload: {'title': 't', 'type': 'EVENT', 'startAt': '2026-05-14T10:00:00Z'}),
    );
    expect(res, isA<OutboxReplayRetry>());
  });
}
```

- [ ] **Step 2: Run — fail**

```bash
flutter test test/features/calendar/data/services/calendar_outbox_replay_handler_test.dart
```

- [ ] **Step 3: Implement**

```dart
// lib/features/calendar/data/services/calendar_outbox_replay_handler.dart
import 'package:dio/dio.dart';
import '../../../../core/services/outbox_replay_handler.dart';
import '../../../../core/storage/outbox_op.dart';
import '../datasources/calendar_remote_datasource.dart';

class CalendarOutboxReplayHandler implements OutboxReplayHandler {
  final CalendarRemoteDataSource _remote;
  CalendarOutboxReplayHandler({required CalendarRemoteDataSource remote}) : _remote = remote;

  @override
  String get feature => 'calendar';

  @override
  Future<OutboxReplayResult> replay(OutboxOp op) async {
    try {
      switch (op.op) {
        case OutboxOpKind.create:
          final serverEntity = await _remote.create(op.payload ?? const {}, id: op.entityId);
          return OutboxReplayResult.success(serverEntity: serverEntity);
        case OutboxOpKind.update:
          final serverEntity = await _remote.update(
            op.entityId,
            op.payload ?? const {},
            expectedUpdatedAt: op.expectedUpdatedAt,
          );
          return OutboxReplayResult.success(serverEntity: serverEntity);
        case OutboxOpKind.delete:
          await _remote.delete(op.entityId);
          return OutboxReplayResult.success();
      }
    } on CalendarConflictException catch (e) {
      return OutboxReplayResult.conflict(serverData: e.currentEvent);
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

- [ ] **Step 4: Run — 4/4 PASS**

```bash
flutter test test/features/calendar/data/services/calendar_outbox_replay_handler_test.dart
```

- [ ] **Step 5: Commit**

```bash
git add lib/features/calendar/data/services/calendar_outbox_replay_handler.dart test/features/calendar/data/services/calendar_outbox_replay_handler_test.dart
git commit -m "$(cat <<'EOF'
feat(calendar): CalendarOutboxReplayHandler maps HTTP outcomes to OutboxReplayResult

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 10: Mobile — `CalendarRepositoryImpl` (TDD)

**Files:**
- Create: `~/Downloads/taler_id_mobile/lib/features/calendar/data/repositories/calendar_repository_impl.dart`
- Create: `~/Downloads/taler_id_mobile/test/features/calendar/data/repositories/calendar_repository_impl_test.dart`

- [ ] **Step 1: Write the failing tests**

```dart
// test/features/calendar/data/repositories/calendar_repository_impl_test.dart
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:taler_id_mobile/core/storage/outbox_op.dart';
import 'package:taler_id_mobile/core/storage/outbox_queue.dart';
import 'package:taler_id_mobile/features/calendar/data/datasources/calendar_local_datasource.dart';
import 'package:taler_id_mobile/features/calendar/data/datasources/calendar_remote_datasource.dart';
import 'package:taler_id_mobile/features/calendar/data/repositories/calendar_repository_impl.dart';
import 'package:taler_id_mobile/features/calendar/domain/entities/calendar_event_entity.dart';
import 'package:taler_id_mobile/features/notes/domain/entities/note_entity.dart' show ConflictResolution;

class _MockRemote extends Mock implements CalendarRemoteDataSource {}

class _FakePathProvider extends PathProviderPlatform with MockPlatformInterfaceMixin {
  final String dir;
  _FakePathProvider(this.dir);
  @override Future<String?> getApplicationDocumentsPath() async => dir;
  @override Future<String?> getApplicationSupportPath() async => dir;
  @override Future<String?> getTemporaryPath() async => dir;
}

CalendarEventEntity ev(String id, {DateTime? updatedAt, bool pending = false}) =>
    CalendarEventEntity(
      id: id,
      title: 'T-$id',
      startAt: DateTime.parse('2026-05-14T10:00:00Z'),
      createdAt: DateTime.parse('2026-05-14T09:00:00Z'),
      updatedAt: updatedAt ?? DateTime.parse('2026-05-14T09:00:00Z'),
      localPending: pending,
    );

void main() {
  late Directory tempDir;
  late CalendarLocalDataSource local;
  late OutboxQueue queue;
  late _MockRemote remote;
  late CalendarRepositoryImpl repo;

  setUpAll(() { TestWidgetsFlutterBinding.ensureInitialized(); });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('cal_repo_test_');
    PathProviderPlatform.instance = _FakePathProvider(tempDir.path);
    Hive.init(tempDir.path);
    await Hive.openBox<String>(CalendarLocalDataSource.boxName);
    await Hive.openBox<String>(OutboxQueue.boxName);
    local = CalendarLocalDataSource();
    queue = OutboxQueue();
    remote = _MockRemote();
    repo = CalendarRepositoryImpl(local: local, remote: remote, outbox: queue);
  });

  tearDown(() async {
    await Hive.close();
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  test('create writes local with localPending=true and enqueues outbox op', () async {
    final draft = ev('new-1');
    final n = await repo.create(draft);
    expect(n.localPending, true);
    final list = await local.getAll();
    expect(list.length, 1);
    final ops = await queue.pending();
    expect(ops.length, 1);
    expect(ops[0].op, OutboxOpKind.create);
    expect(ops[0].entityId, draft.id);
    expect(ops[0].feature, 'calendar');
  });

  test('update on a locally-pending create mutates the create payload (no extra op)', () async {
    final n = await repo.create(ev('e1'));
    await repo.update(n.id, title: 'changed');
    final ops = await queue.pending();
    expect(ops.length, 1);
    expect(ops[0].op, OutboxOpKind.create);
    expect(ops[0].payload!['title'], 'changed');
  });

  test('update on a synced event enqueues an update op with expectedUpdatedAt', () async {
    final synced = ev('e1', updatedAt: DateTime.parse('2026-05-14T08:00:00Z'));
    await local.upsert(synced);
    await repo.update('e1', title: 'new-title');
    final ops = await queue.pending();
    expect(ops.length, 1);
    expect(ops[0].op, OutboxOpKind.update);
    expect(ops[0].expectedUpdatedAt, synced.updatedAt);
    final localNow = await local.getById('e1');
    expect(localNow!.title, 'new-title');
    expect(localNow.localPending, true);
  });

  test('delete on a locally-pending create drops both local and outbox', () async {
    final n = await repo.create(ev('e1'));
    await repo.delete(n.id);
    expect((await local.getAll()).isEmpty, true);
    expect((await queue.pending()).isEmpty, true);
  });

  test('delete on a synced event enqueues delete + removes from local', () async {
    await local.upsert(ev('e1'));
    await repo.delete('e1');
    expect((await local.getAll()).isEmpty, true);
    final ops = await queue.pending();
    expect(ops.length, 1);
    expect(ops[0].op, OutboxOpKind.delete);
    expect(ops[0].entityId, 'e1');
  });

  test('resolveConflict KEEP_MINE replaces conflict op with fresh update using server updatedAt', () async {
    final localEv = ev('e1', pending: true).copyWith(conflictedWith: {
      'id': 'e1',
      'title': 'srv-title',
      'startAt': '2026-05-14T10:00:00.000Z',
      'createdAt': '2026-05-14T09:00:00.000Z',
      'updatedAt': '2026-05-14T10:10:00.000Z',
      'type': 'EVENT',
    });
    await local.upsert(localEv);
    await queue.enqueue(OutboxOp(
      opId: 'conflict-op',
      feature: 'calendar',
      op: OutboxOpKind.update,
      entityId: 'e1',
      payload: {'title': 'mine'},
      status: OutboxOpStatus.failedConflict,
      createdAt: DateTime.now(),
    ));

    await repo.resolveConflict('e1', ConflictResolution.keepMine);

    final ops = await queue.pending();
    expect(ops.length, 1);
    expect(ops[0].opId, isNot('conflict-op'));
    expect(ops[0].status, OutboxOpStatus.pending);
    expect(ops[0].expectedUpdatedAt, DateTime.parse('2026-05-14T10:10:00.000Z'));
    final localNow = await local.getById('e1');
    expect(localNow!.conflictedWith, isNull);
  });

  test('resolveConflict ACCEPT_SERVER overwrites local + drops op', () async {
    final localEv = ev('e1', pending: true).copyWith(conflictedWith: {
      'id': 'e1',
      'title': 'srv-title',
      'startAt': '2026-05-14T10:00:00.000Z',
      'createdAt': '2026-05-14T09:00:00.000Z',
      'updatedAt': '2026-05-14T10:10:00.000Z',
      'type': 'EVENT',
    });
    await local.upsert(localEv);
    await queue.enqueue(OutboxOp(
      opId: 'conflict-op',
      feature: 'calendar',
      op: OutboxOpKind.update,
      entityId: 'e1',
      payload: {'title': 'mine'},
      status: OutboxOpStatus.failedConflict,
      createdAt: DateTime.now(),
    ));

    await repo.resolveConflict('e1', ConflictResolution.acceptServer);

    expect((await queue.pending()).isEmpty, true);
    final localNow = await local.getById('e1');
    expect(localNow!.title, 'srv-title');
    expect(localNow.localPending, false);
    expect(localNow.conflictedWith, isNull);
  });
}
```

- [ ] **Step 2: Run — fail**

```bash
flutter test test/features/calendar/data/repositories/calendar_repository_impl_test.dart
```

- [ ] **Step 3: Implement**

```dart
// lib/features/calendar/data/repositories/calendar_repository_impl.dart
import 'dart:async';
import 'package:uuid/uuid.dart';
import '../../../../core/storage/outbox_op.dart';
import '../../../../core/storage/outbox_queue.dart';
import '../../domain/entities/calendar_event_entity.dart';
import '../../domain/repositories/i_calendar_repository.dart';
import '../../../notes/domain/entities/note_entity.dart' show ConflictResolution;
import '../datasources/calendar_local_datasource.dart';
import '../datasources/calendar_remote_datasource.dart';

class CalendarRepositoryImpl implements ICalendarRepository {
  final CalendarLocalDataSource _local;
  final CalendarRemoteDataSource _remote;
  final OutboxQueue _outbox;
  final Uuid _uuid = const Uuid();

  CalendarRepositoryImpl({
    required CalendarLocalDataSource local,
    required CalendarRemoteDataSource remote,
    required OutboxQueue outbox,
  })  : _local = local,
        _remote = remote,
        _outbox = outbox;

  @override
  Stream<List<CalendarEventEntity>> watchAll() => _local.watchAll();

  @override
  Future<void> refresh({DateTime? from, DateTime? to}) async {
    final fromDate = (from ?? DateTime.now().subtract(const Duration(days: 30))).toUtc();
    final toDate = (to ?? DateTime.now().add(const Duration(days: 90))).toUtc();
    try {
      final remoteList = await _remote.getEvents(
        from: fromDate.toIso8601String(),
        to: toDate.toIso8601String(),
      );
      final remoteIds = remoteList.map((m) => m['id'] as String).toSet();
      final localAll = await _local.getAll();
      for (final r in remoteList) {
        final entity = _entityFromServerJson(r);
        final existing = await _local.getById(entity.id);
        if (existing != null && existing.localPending) continue;
        await _local.upsert(entity);
      }
      // Remove only events INSIDE the requested window that the server didn't return.
      for (final l in localAll) {
        if (l.localPending) continue;
        final inWindow = !l.startAt.isBefore(fromDate) && !l.startAt.isAfter(toDate);
        if (inWindow && !remoteIds.contains(l.id)) {
          await _local.remove(l.id);
        }
      }
    } catch (_) {
      // offline / failure → leave local intact
    }
  }

  @override
  Future<CalendarEventEntity> create(CalendarEventEntity draft) async {
    final id = draft.id.isEmpty ? _uuid.v4() : draft.id;
    final now = DateTime.now().toUtc();
    final event = draft.copyWith(
      id: id,
      createdAt: now,
      updatedAt: now,
      localPending: true,
    );
    await _local.upsert(event);
    await _outbox.enqueue(OutboxOp(
      opId: _uuid.v4(),
      feature: 'calendar',
      op: OutboxOpKind.create,
      entityId: id,
      payload: _toServerJson(event),
      createdAt: now,
    ));
    return event;
  }

  @override
  Future<CalendarEventEntity> update(
    String id, {
    String? title,
    String? description,
    CalendarEventType? type,
    DateTime? startAt,
    DateTime? endAt,
    bool? allDay,
    DateTime? reminderAt,
    String? displayTime,
    Map<String, dynamic>? recurrence,
    List<String>? contactIds,
  }) async {
    final current = await _local.getById(id);
    if (current == null) throw StateError('Event $id not in local store');

    final next = current.copyWith(
      title: title ?? current.title,
      description: description ?? current.description,
      type: type ?? current.type,
      startAt: startAt ?? current.startAt,
      endAt: endAt ?? current.endAt,
      allDay: allDay ?? current.allDay,
      reminderAt: reminderAt ?? current.reminderAt,
      displayTime: displayTime ?? current.displayTime,
      recurrence: recurrence ?? current.recurrence,
      contactIds: contactIds ?? current.contactIds,
      localPending: true,
    );
    await _local.upsert(next);

    final partialPayload = <String, dynamic>{
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (type != null) 'type': type.name.toUpperCase(),
      if (startAt != null) 'startAt': startAt.toUtc().toIso8601String(),
      if (endAt != null) 'endAt': endAt.toUtc().toIso8601String(),
      if (allDay != null) 'allDay': allDay,
      if (reminderAt != null) 'reminderAt': reminderAt.toUtc().toIso8601String(),
      if (displayTime != null) 'displayTime': displayTime,
      if (recurrence != null) 'recurrence': recurrence,
      if (contactIds != null) 'contactIds': contactIds,
    };

    final existingOps = await _outbox.pending();
    final pendingForThis = existingOps.where((o) => o.entityId == id).toList();

    OutboxOp? pendingCreate;
    for (final o in pendingForThis) {
      if (o.op == OutboxOpKind.create) {
        pendingCreate = o;
        break;
      }
    }
    if (pendingCreate != null) {
      final merged = Map<String, dynamic>.from(pendingCreate.payload ?? {});
      merged.addAll(partialPayload);
      await _outbox.remove(pendingCreate.opId);
      await _outbox.enqueue(pendingCreate.copyWith(payload: merged));
      return next;
    }
    for (final op in pendingForThis) {
      if (op.op == OutboxOpKind.update) {
        await _outbox.remove(op.opId);
      }
    }
    await _outbox.enqueue(OutboxOp(
      opId: _uuid.v4(),
      feature: 'calendar',
      op: OutboxOpKind.update,
      entityId: id,
      payload: partialPayload,
      expectedUpdatedAt: current.updatedAt,
      createdAt: DateTime.now().toUtc(),
    ));
    return next;
  }

  @override
  Future<void> delete(String id) async {
    final existingOps = await _outbox.pending();
    final pendingForThis = existingOps.where((o) => o.entityId == id).toList();
    OutboxOp? pendingCreate;
    for (final o in pendingForThis) {
      if (o.op == OutboxOpKind.create) {
        pendingCreate = o;
        break;
      }
    }
    if (pendingCreate != null) {
      for (final op in pendingForThis) {
        await _outbox.remove(op.opId);
      }
      await _local.remove(id);
      return;
    }
    for (final op in pendingForThis) {
      if (op.op == OutboxOpKind.update) {
        await _outbox.remove(op.opId);
      }
    }
    await _local.remove(id);
    await _outbox.enqueue(OutboxOp(
      opId: _uuid.v4(),
      feature: 'calendar',
      op: OutboxOpKind.delete,
      entityId: id,
      createdAt: DateTime.now().toUtc(),
    ));
  }

  @override
  Future<void> resolveConflict(String id, ConflictResolution choice) async {
    final event = await _local.getById(id);
    if (event == null || event.conflictedWith == null) return;
    final server = event.conflictedWith!;

    final ops = await _outbox.pending();
    OutboxOp? conflictOp;
    for (final o in ops) {
      if (o.entityId == id && o.status == OutboxOpStatus.failedConflict) {
        conflictOp = o;
        break;
      }
    }

    switch (choice) {
      case ConflictResolution.keepMine:
        if (conflictOp != null) {
          final serverUpdatedAt = DateTime.parse(server['updatedAt'] as String);
          await _outbox.remove(conflictOp.opId);
          await _outbox.enqueue(OutboxOp(
            opId: _uuid.v4(),
            feature: 'calendar',
            op: OutboxOpKind.update,
            entityId: id,
            payload: conflictOp.payload,
            expectedUpdatedAt: serverUpdatedAt,
            createdAt: DateTime.now().toUtc(),
          ));
        }
        await _local.upsert(event.copyWith(conflictedWith: null));
        break;
      case ConflictResolution.acceptServer:
        if (conflictOp != null) {
          await _outbox.remove(conflictOp.opId);
        }
        await _local.upsert(_entityFromServerJson(server));
        break;
    }
  }

  @override
  Stream<int> watchPendingCount() async* {
    yield (await _local.getAll()).where((e) => e.localPending).length;
    await for (final list in _local.watchAll()) {
      yield list.where((e) => e.localPending).length;
    }
  }

  @override
  Stream<int> watchConflictCount() async* {
    yield (await _local.getAll()).where((e) => e.conflictedWith != null).length;
    await for (final list in _local.watchAll()) {
      yield list.where((e) => e.conflictedWith != null).length;
    }
  }

  Map<String, dynamic> _toServerJson(CalendarEventEntity e) {
    return {
      'title': e.title,
      if (e.description != null) 'description': e.description,
      'type': e.type.name.toUpperCase(),
      'startAt': e.startAt.toUtc().toIso8601String(),
      if (e.endAt != null) 'endAt': e.endAt!.toUtc().toIso8601String(),
      'allDay': e.allDay,
      if (e.reminderAt != null) 'reminderAt': e.reminderAt!.toUtc().toIso8601String(),
      if (e.displayTime != null) 'displayTime': e.displayTime,
      if (e.recurrence != null) 'recurrence': e.recurrence,
      'contactIds': e.contactIds,
      'createdBy': e.createdBy,
    };
  }

  CalendarEventEntity _entityFromServerJson(Map<String, dynamic> json) {
    final t = (json['type'] as String? ?? 'EVENT').toUpperCase();
    final typeEnum = CalendarEventType.values.firstWhere(
      (v) => v.name.toUpperCase() == t,
      orElse: () => CalendarEventType.event,
    );
    return CalendarEventEntity(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      type: typeEnum,
      startAt: DateTime.parse(json['startAt'] as String),
      endAt: json['endAt'] != null ? DateTime.parse(json['endAt'] as String) : null,
      allDay: (json['allDay'] as bool?) ?? false,
      reminderAt: json['reminderAt'] != null ? DateTime.parse(json['reminderAt'] as String) : null,
      reminderSent: (json['reminderSent'] as bool?) ?? false,
      displayTime: json['displayTime'] as String?,
      recurrence: json['recurrence'] is Map ? Map<String, dynamic>.from(json['recurrence'] as Map) : null,
      contactIds: (json['contactIds'] as List?)?.cast<String>() ?? const <String>[],
      createdBy: json['createdBy'] as String? ?? 'MANUAL',
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      localPending: false,
      conflictedWith: null,
    );
  }
}
```

- [ ] **Step 4: Run — 7/7 PASS**

```bash
flutter test test/features/calendar/data/repositories/calendar_repository_impl_test.dart
```

- [ ] **Step 5: Commit**

```bash
git add lib/features/calendar/data/repositories/calendar_repository_impl.dart test/features/calendar/data/repositories/calendar_repository_impl_test.dart
git commit -m "$(cat <<'EOF'
feat(calendar): add CalendarRepositoryImpl with squash + OCC + conflict resolution

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 11: Mobile — DI wiring

**Files:**
- Modify: `~/Downloads/taler_id_mobile/lib/core/di/service_locator.dart`

- [ ] **Step 1: Open the box and register**

Add imports at the top (near the existing notes/outbox imports):

```dart
import '../../features/calendar/data/datasources/calendar_local_datasource.dart';
import '../../features/calendar/data/datasources/calendar_remote_datasource.dart';
import '../../features/calendar/data/repositories/calendar_repository_impl.dart';
import '../../features/calendar/data/services/calendar_outbox_replay_handler.dart';
import '../../features/calendar/domain/repositories/i_calendar_repository.dart';
```

Inside `setupDependencies()`, after the existing notes-related `Hive.openBox` (look for `NotesLocalDataSource.boxName`), add:

```dart
  await Hive.openBox<String>(CalendarLocalDataSource.boxName);
```

In the registrations section (alongside the notes feature block), add:

```dart
  // Calendar feature
  sl.registerLazySingleton<CalendarLocalDataSource>(() => CalendarLocalDataSource());
  if (!sl.isRegistered<CalendarRemoteDataSource>()) {
    sl.registerLazySingleton<CalendarRemoteDataSource>(() => CalendarRemoteDataSource(sl<DioClient>()));
  }
  sl.registerLazySingleton<ICalendarRepository>(() => CalendarRepositoryImpl(
        local: sl<CalendarLocalDataSource>(),
        remote: sl<CalendarRemoteDataSource>(),
        outbox: sl<OutboxQueue>(),
      ));
  sl.registerLazySingleton<CalendarOutboxReplayHandler>(() => CalendarOutboxReplayHandler(
        remote: sl<CalendarRemoteDataSource>(),
      ));
```

In the boot sequence (after `sl<OutboxReplayService>().registerHandler(sl<NotesOutboxReplayHandler>())`), add:

```dart
  sl<OutboxReplayService>().registerHandler(sl<CalendarOutboxReplayHandler>());
```

(`sl<ConnectivityWatcher>().start()` and the initial `drain()` call already exist — no duplication needed.)

- [ ] **Step 2: Analyze**

```bash
flutter analyze lib/core/di/service_locator.dart
```

- [ ] **Step 3: Commit**

```bash
git add lib/core/di/service_locator.dart
git commit -m "$(cat <<'EOF'
feat(di): wire calendar offline repository + outbox replay handler

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 12: Mobile — `calendar_screen.dart` refactor

**Files:**
- Modify: `~/Downloads/taler_id_mobile/lib/features/calendar/presentation/screens/calendar_screen.dart`

The file is ~1606 lines and has multiple write sites:
- `_load()` reads from `_cache` + `CalendarRemoteDataSource(...).getEvents()`.
- Delete handlers at lines ~141, 388, 772, 783 use direct `CalendarRemoteDataSource(...).delete(...)` or `client.delete('/calendar/...')`.
- Event-edit save handler at line ~1164 uses `ds.update(...)` or `ds.create(...)`.
- Invite responses at lines 550-568 and 1432-1442 use `acceptInvite/declineInvite/maybeInvite` — these STAY online-only, do not touch.

### Steps

- [ ] **Step 1: Migrate fields & subscriptions**

Replace the cache field and add subscriptions. Find:

```dart
final _cache = sl<SimpleListCache>(instanceName: 'calendar');
```

Replace with:

```dart
  final ICalendarRepository _repo = sl<ICalendarRepository>();
  StreamSubscription<List<CalendarEventEntity>>? _eventsSub;
  StreamSubscription<int>? _pendingSub;
  StreamSubscription<int>? _conflictSub;
  List<CalendarEventEntity> _events = [];
  int _pendingCount = 0;
  int _conflictCount = 0;
```

Add imports at the top of the file:

```dart
import 'dart:async';
import '../../domain/entities/calendar_event_entity.dart';
import '../../domain/repositories/i_calendar_repository.dart';
import '../../../notes/domain/entities/note_entity.dart' show ConflictResolution;
import '../../../notes/presentation/widgets/conflict_resolution_dialog.dart';
import '../../../../core/services/outbox_replay_service.dart';
```

- [ ] **Step 2: Replace `initState`**

```dart
  @override
  void initState() {
    super.initState();
    _eventsSub = _repo.watchAll().listen((events) {
      if (mounted) setState(() => _events = events);
    });
    _pendingSub = _repo.watchPendingCount().listen((c) {
      if (mounted) setState(() => _pendingCount = c);
    });
    _conflictSub = _repo.watchConflictCount().listen((c) {
      if (mounted) setState(() => _conflictCount = c);
    });
    _repo.refresh();
    // Invites flow continues as before (direct datasource).
  }
```

Add a `dispose()` override if not present, or extend the existing one with:

```dart
    _eventsSub?.cancel();
    _pendingSub?.cancel();
    _conflictSub?.cancel();
```

- [ ] **Step 3: Remove old `_load` and `_cache.save / _cache.remove` calls**

Search the file for all `_cache.` references and delete those lines. The `_load` method (around line 58-100) should be removed entirely — the stream subscription does its job.

If any list rendering code references the old map shape `event['title']`, migrate to the entity `event.title`. Properties to map:
- `e['title']` → `event.title`
- `e['startAt']` (String) → `event.startAt.toIso8601String()` if a string is needed, otherwise pass `DateTime` directly.
- `e['endAt']` → `event.endAt?.toIso8601String()`
- `e['id']` → `event.id`
- `e['type']` → `event.type.name.toUpperCase()`
- `e['description']` → `event.description`
- `e['contactIds']` → `event.contactIds`
- `e['displayTime']` → `event.displayTime`
- `e['recurrence']` → `event.recurrence`

For each migration, preserve null-safety: many existing sites assume the map can have missing keys.

- [ ] **Step 4: Route create/update/delete through the repo**

At the save handler (~line 1164):

```dart
      // BEFORE:
      // final ds = CalendarRemoteDataSource(sl<DioClient>());
      // if (widget.event != null) {
      //   await ds.update(widget.event!['id'] as String, data);
      // } else {
      //   await ds.create(data);
      // }
      //
      // AFTER:
      if (widget.event != null) {
        await _repo.update(
          widget.event!.id,
          title: data['title'] as String?,
          description: data['description'] as String?,
          type: _parseType(data['type'] as String?),
          startAt: data['startAt'] != null ? DateTime.parse(data['startAt'] as String) : null,
          endAt: data['endAt'] != null ? DateTime.parse(data['endAt'] as String) : null,
          allDay: data['allDay'] as bool?,
          reminderAt: data['reminderAt'] != null ? DateTime.parse(data['reminderAt'] as String) : null,
          displayTime: data['displayTime'] as String?,
          recurrence: data['recurrence'] is Map ? Map<String, dynamic>.from(data['recurrence'] as Map) : null,
          contactIds: (data['contactIds'] as List?)?.cast<String>(),
        );
      } else {
        await _repo.create(CalendarEventEntity(
          id: '', // repo generates UUID when empty
          title: data['title'] as String? ?? '',
          description: data['description'] as String?,
          type: _parseType(data['type'] as String?) ?? CalendarEventType.event,
          startAt: DateTime.parse(data['startAt'] as String),
          endAt: data['endAt'] != null ? DateTime.parse(data['endAt'] as String) : null,
          allDay: (data['allDay'] as bool?) ?? false,
          reminderAt: data['reminderAt'] != null ? DateTime.parse(data['reminderAt'] as String) : null,
          displayTime: data['displayTime'] as String?,
          recurrence: data['recurrence'] is Map ? Map<String, dynamic>.from(data['recurrence'] as Map) : null,
          contactIds: (data['contactIds'] as List?)?.cast<String>() ?? const <String>[],
          createdAt: DateTime.now().toUtc(), // will be overwritten by repo
          updatedAt: DateTime.now().toUtc(),
        ));
      }
```

Add a small helper near the top of the State class (or as a private top-level function):

```dart
  CalendarEventType? _parseType(String? raw) {
    if (raw == null) return null;
    final upper = raw.toUpperCase();
    return CalendarEventType.values.firstWhere(
      (v) => v.name.toUpperCase() == upper,
      orElse: () => CalendarEventType.event,
    );
  }
```

For the four delete sites (lines ~141, 388, 772, 783):

```dart
      // BEFORE: await CalendarRemoteDataSource(sl<DioClient>()).delete(id);
      // AFTER:
      await _repo.delete(id);
```

(Also remove the corresponding `_cache.remove(id)` lines.)

- [ ] **Step 5: Add the pending indicator and conflict banner**

Inside the event-card widget builder, find the line that renders the title and add an indicator widget next to it:

```dart
  Widget _pendingIndicator(CalendarEventEntity e) {
    if (e.conflictedWith != null) {
      return GestureDetector(
        onTap: () => _showConflictDialog(e),
        child: const Padding(
          padding: EdgeInsets.only(left: 6),
          child: Icon(Icons.error_outline, size: 16, color: Colors.orange),
        ),
      );
    } else if (e.localPending) {
      return const Padding(
        padding: EdgeInsets.only(left: 6),
        child: Icon(Icons.sync, size: 12, color: Colors.grey),
      );
    }
    return const SizedBox.shrink();
  }
```

Add the banner at the top of the screen's `body` (above the existing scaffold body):

```dart
  Widget _buildConflictBanner() {
    if (_conflictCount == 0) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: Colors.orange.shade50,
      child: Row(
        children: [
          const Icon(Icons.warning_amber, color: Colors.orange, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text('$_conflictCount событий ждут вашего решения', style: const TextStyle(color: Colors.orange))),
        ],
      ),
    );
  }
```

Wrap the existing body widget in a `Column` with the banner above. Approximately:

```dart
body: Column(children: [_buildConflictBanner(), Expanded(child: existingBody)]),
```

(`existingBody` is whatever the screen previously returned as `Scaffold.body`.)

- [ ] **Step 6: Add conflict dialog handler**

The notes `ConflictResolutionDialog` expects a `NoteEntity local` parameter. Since we cannot directly pass `CalendarEventEntity`, we adapt: build a transient `NoteEntity` whose `title` and `content` mirror the event's `title` and a textified preview. Add:

```dart
  void _showConflictDialog(CalendarEventEntity e) {
    final localPreview = _eventPreviewText(e.title, e.startAt, e.description);
    final server = e.conflictedWith ?? const <String, dynamic>{};
    final serverPreview = _eventPreviewText(
      server['title'] as String? ?? '',
      server['startAt'] != null ? DateTime.parse(server['startAt'] as String) : DateTime.now(),
      server['description'] as String?,
    );
    final localAsNote = NoteEntity(
      id: e.id,
      title: e.title,
      content: localPreview,
      createdAt: e.createdAt,
      updatedAt: e.updatedAt,
      conflictedWith: {
        'title': server['title'] ?? '',
        'content': serverPreview,
      },
    );
    showDialog(
      context: context,
      builder: (_) => ConflictResolutionDialog(
        local: localAsNote,
        onResolve: (choice) async {
          await _repo.resolveConflict(e.id, choice);
        },
      ),
    );
  }

  String _eventPreviewText(String title, DateTime start, String? description) {
    final dt = '${start.toLocal()}';
    return '$dt${description != null ? '\n$description' : ''}';
  }
```

Add the import for `NoteEntity` (it's already there from Step 1).

- [ ] **Step 7: Pull-to-refresh**

Find the existing `RefreshIndicator.onRefresh` and replace its body with:

```dart
  Future<void> _onRefresh() async {
    await _repo.refresh();
    await sl<OutboxReplayService>().drain();
  }
```

- [ ] **Step 8: Analyze + run all tests**

```bash
flutter analyze lib/features/calendar/presentation/screens/calendar_screen.dart
flutter test
```

Expected: no new errors. All existing tests pass.

- [ ] **Step 9: Commit**

```bash
git add lib/features/calendar/presentation/screens/calendar_screen.dart
git commit -m "$(cat <<'EOF'
refactor(calendar): route event CRUD through ICalendarRepository + streams

Adds pending sync indicator on event cards and conflict banner above the list.
Reuses ConflictResolutionDialog from notes via a small NoteEntity adapter.
Invite responses unchanged (online-only).

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 13: Hardware smoke

- [ ] **Step 1: Build dev APK locally**

```bash
cd ~/Downloads/taler_id_mobile
flutter build apk --flavor dev --release -t lib/main_dev.dart --dart-define=FLAVOR=dev --dart-define=BASE_URL=https://staging.id.taler.tirol
```

- [ ] **Step 2: Install on running emulator**

```bash
~/Library/Android/sdk/platform-tools/adb -s emulator-5554 uninstall tirol.taler.taler_id_mobile.dev
~/Library/Android/sdk/platform-tools/adb -s emulator-5554 install ~/Downloads/taler_id_mobile/build/app/outputs/flutter-apk/app-dev-release.apk
~/Library/Android/sdk/platform-tools/adb -s emulator-5554 shell pm grant tirol.taler.taler_id_mobile.dev android.permission.RECORD_AUDIO
~/Library/Android/sdk/platform-tools/adb -s emulator-5554 shell pm grant tirol.taler.taler_id_mobile.dev android.permission.POST_NOTIFICATIONS
~/Library/Android/sdk/platform-tools/adb -s emulator-5554 shell monkey -p tirol.taler.taler_id_mobile.dev -c android.intent.category.LAUNCHER 1
```

- [ ] **Step 3: Smoke scenarios** (drive the emulator manually):

1. Login → Calendar.
2. **Offline CRUD**: airplane on (`adb shell svc wifi disable; adb shell svc data disable`) → create 3 events → edit one → delete one → re-enable network (`adb shell svc wifi enable; adb shell svc data enable`) → indicators clear in 5s.
3. **Conflict**: edit event A offline. In another terminal, `curl -X PATCH` the same event from the integration test account (changes server's `updatedAt`). Re-enable network on the phone. Conflict banner appears; tap conflict icon → dialog → "Оставить мою" → verify on server via `curl /calendar`.
4. **Kill-mid-sync**: airplane on → create event → airplane off → immediately force-quit (`adb shell am force-stop tirol.taler.taler_id_mobile.dev`) → relaunch → event present + completes sync within seconds.

Document any failures in the spec file under "Smoke results" before merging.

---

## Task 14: Deploy mobile dev branch

- [ ] **Step 1: Push**

```bash
cd ~/Downloads/taler_id_mobile
git push origin dev
```

- [ ] **Step 2: Build dev APK on PROD server**

```bash
ssh dvolkov@138.124.61.221
cd ~/taler_id_mobile && git checkout dev && git pull origin dev
flutter build apk --flavor dev --release -t lib/main_dev.dart \
  --dart-define=FLAVOR=dev --dart-define=BASE_URL=https://staging.id.taler.tirol
sudo cp build/app/outputs/flutter-apk/app-dev-release.apk /var/www/downloads/taler-id-dev.apk
```

- [ ] **Step 3: Run all DEV integration tests** (regression check)

```bash
cd ~/Downloads/taler_id_tests
npm test && npm run test:sync && npm run test:notes:offline && npm run test:calendar:offline && npm run test:files && npm run test:channels && npm run test:billing
```

Expected: all green.

---

## Note on PROD deploy

Per the user's "B" strategy (combined PROD deploy after all 4 offline features): **do NOT deploy to PROD after this calendar plan completes.** The contacts-offline and favorites-offline plans will follow. Once all 4 are merged on `dev` and smoke-tested, the user will explicitly request the combined PROD release.

---

## Spec coverage check (self-review)

| Spec requirement | Implemented in task |
|---|---|
| `POST /calendar` accepts optional `id`, idempotent on same-user collision | Task 1 |
| `POST /calendar` 409 on cross-user `id` collision | Task 1 |
| `PATCH /calendar/:id` accepts optional `expectedUpdatedAt` (OCC) | Task 2 |
| `PATCH` 409 with `currentEvent` in body on stale | Task 2 |
| `DELETE` 404 → client success | Task 8 (`CalendarRemoteDataSource.delete` swallows 404) |
| Hive `calendar_events_local` box | Task 7 |
| Local cache of invites (read-only, no write path) | (existing `SimpleListCache` for invites preserved; no new code needed beyond not breaking it) |
| Reuse `OutboxQueue`/`OutboxReplayService`/`ConnectivityWatcher` | (no new code — DI Task 11 just registers the handler) |
| `CalendarEventEntity` Freezed + `CalendarEventType` enum | Task 5 |
| `ICalendarRepository` interface | Task 6 |
| `CalendarLocalDataSource` (Hive watch + CRUD) | Task 7 |
| `CalendarRemoteDataSource` updates (id, expectedUpdatedAt, ConflictException, 404 idempotent) | Task 8 |
| `CalendarOutboxReplayHandler` HTTP outcome mapping | Task 9 |
| `CalendarRepositoryImpl` create/update/delete + squash logic | Task 10 |
| `refresh({from, to})` rolling-window diff respecting `localPending` | Task 10 |
| `resolveConflict(keepMine / acceptServer)` | Task 10 |
| DI wiring + Hive box opening + handler registration | Task 11 |
| `calendar_screen.dart` refactor with streams + pending dot + banner | Task 12 |
| Conflict dialog reuse via `NoteEntity` adapter | Task 12 step 6 |
| Hardware smoke (offline CRUD, conflict, kill-mid-sync) | Task 13 |
| DEV deploy + regression suite | Tasks 3, 14 |
| PROD deploy deferred to combined release after Contacts + Favorites | (note above; not in this plan) |
| **Out of scope:** invite-response offline, desktop port, 3-way merge | n/a |

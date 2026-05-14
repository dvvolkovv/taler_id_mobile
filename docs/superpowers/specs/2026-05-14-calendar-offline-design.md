# Calendar Offline (CRUD + OCC) — Design

**Date:** 2026-05-14
**Author:** Dmitry + Claude (brainstorming)
**Scope:** Apply the existing outbox + OCC pattern (established by the notes-offline work, 2026-05-13) to CalendarEvent CRUD. Invites and invite-response actions stay online-only.
**Stage:** 2.2 — second feature in the broader offline-mode track (after Notes 2.1).
**Affected repos:** `taler_id_mobile` (Flutter), `taler-id` (NestJS). Desktop port is a separate, follow-up PR using the same code.

## Problem

The Calendar feature today works only when online for writes. The screen has a `SimpleListCache('calendar')` for instant first paint, but every `create`, `update`, `delete` requires an open connection. Users cannot capture a new event on a plane / metro / mountain.

Same gap as Notes had pre-2026-05-13. The outbox infrastructure built for Notes is reusable — this spec wires it into a second feature with minimal new code.

## Goals

- Create, edit, delete CalendarEvents while offline. Local UI shows them immediately; sync on reconnect.
- Multi-device safety: if the same event has been edited on another device while a local edit was pending, show a conflict instead of silent overwrite.
- Local read of invites (received by the user) stays available offline as a read-only view. Accept/decline/maybe actions remain online-only.
- Reuse `OutboxQueue`, `OutboxReplayService`, `ConnectivityWatcher`, `ConflictResolutionDialog` machinery from the Notes work. No duplication.
- No regression on the existing online path: list, edit, reminders, recurrence all continue to work for online users.

## Non-goals (this spec)

- Accept / decline / maybe invite responses offline. Deferred to a separate spec.
- 3-way merge UI for conflicting events. Conflict dialog shows two full versions; user picks one.
- Recurrence-aware conflict resolution. A recurrence change is treated as a normal field update.
- Reminder management while offline. `flutter_local_notifications` already fires reminders independently of network state — no change needed.
- Pagination/window UI ("load older events"). Out of scope, see Refresh strategy below.
- Desktop (`taler_id_desktop`) port — separate PR, same code.
- True CRDT / transaction log.

## Architecture

### Data model

**Server `CalendarEvent`** (`prisma/schema.prisma`): no schema change. Fields used:
- `id String @id @default(uuid())` — accepts a client-supplied UUID for idempotent create.
- `updatedAt DateTime @updatedAt` — version token for OCC.
- All existing fields (`title`, `description`, `type`, `startAt`, `endAt`, `allDay`, `reminderAt`, `reminderSent`, `displayTime`, `recurrence`, `contactIds`, `createdBy`, `createdAt`) are returned to the client as-is.

**Server API contract changes:**

- `POST /calendar`: accepts optional `id: string` in body.
  - No `id` → generate UUID server-side (existing behavior).
  - `id` given, event with that id does not exist → create with that id.
  - `id` given, event exists with that id **and same userId** → return existing as-is (200, idempotent).
  - `id` given, event exists but **different userId** → 409 Conflict (collision).
- `PATCH /calendar/:id`: accepts optional `expectedUpdatedAt: ISO8601` in body.
  - Not given → existing LWW behavior preserved.
  - Given and matches DB `updatedAt` → apply, return updated event.
  - Given and stale → **409 Conflict** with `{ currentEvent: <full Event>, message }` (mirrors the notes 409 shape, just with `currentEvent` instead of `currentNote`).
- `DELETE /calendar/:id`: unchanged. 404 on not-found = client-side success.
- `POST/PATCH /calendar/invites/...` (accept/decline/maybe): unchanged, online-only, no offline path.

**Reuse on the server:** the global `HttpExceptionFilter` already passes through arbitrary extra keys on the exception response body (added during the notes work). No further filter changes needed.

**Client Hive boxes:**

- `calendar_events_local` — local copy of own CalendarEvents, schema mirrors `CalendarEventEntity`:
  ```dart
  CalendarEventEntity {
    id: String
    title: String
    description: String?
    type: CalendarEventType    // CALL | EVENT | TASK | …
    startAt: DateTime
    endAt: DateTime?
    allDay: bool
    reminderAt: DateTime?
    reminderSent: bool          // server-managed, copy as-is
    displayTime: String?
    recurrence: Map<String, dynamic>?
    contactIds: List<String>
    createdBy: String
    createdAt: DateTime
    updatedAt: DateTime          // last KNOWN server version
    localPending: bool
    conflictedWith: Map<String, dynamic>?   // server's current version on 409
  }
  ```
- `calendar_invites_local` — read-only cache of `CalendarInvite` records (id, eventId, status, eventSummary). Refreshed via `GET /calendar/invites`. No outbox writes. Existing `SimpleListCache` for invites continues working — we move it to a typed Hive box for parity but DO NOT add write paths.
- `outbox_v1` — shared with notes. Uses existing `OutboxQueue` with `feature: 'calendar'`.

### Components

#### Server-side (`taler-id`)

- **Modify** `src/calendar/calendar.service.ts`:
  - `create(userId, data: { id?, title, …})` — idempotent on `id` collision with same user; 409 on cross-user id collision.
  - `update(userId, id, data: { …, expectedUpdatedAt? })` — OCC check, 409 with `currentEvent`.
- **Modify** `src/calendar/calendar.controller.ts` — widen `@Body` types for `create` and `update`.
- **Create** `src/calendar/calendar.service.spec.ts` — unit tests for create (4 cases) + update (4 cases).

#### Mobile core — no new infrastructure

`OutboxQueue`, `OutboxReplayService`, `OutboxReplayHandler`, `ConnectivityWatcher`, `OutboxReplayResult` sealed type — all exist from notes. We register a second handler.

#### Mobile — Calendar feature

- **Create** `lib/features/calendar/domain/entities/calendar_event_entity.dart` — Freezed `CalendarEventEntity` + `CalendarEventType` enum (matching server enum values) + reuse `ConflictResolution` from notes.
- **Create** `lib/features/calendar/domain/repositories/i_calendar_repository.dart` — same shape as `INotesRepository`, plus a per-window refresh:
  ```dart
  abstract class ICalendarRepository {
    Stream<List<CalendarEventEntity>> watchAll();
    Future<void> refresh({DateTime? from, DateTime? to}); // default ±60 days
    Future<CalendarEventEntity> create(CalendarEventEntity draft);
    Future<CalendarEventEntity> update(String id, {…field overrides…});
    Future<void> delete(String id);
    Future<void> resolveConflict(String id, ConflictResolution choice);
    Stream<int> watchPendingCount();
    Stream<int> watchConflictCount();
  }
  ```
- **Create** `lib/features/calendar/data/datasources/calendar_local_datasource.dart` — Hive box `calendar_events_local`. CRUD + `watchAll` + `getById`. Pattern from `NotesLocalDataSource`.
- **Modify** `lib/features/calendar/data/datasources/calendar_remote_datasource.dart`:
  - `create(...)` accepts optional `id` parameter.
  - `update(...)` accepts optional `expectedUpdatedAt`.
  - On HTTP 409 from update: throw `CalendarConflictException(currentEvent)`.
  - `delete` swallows 404 (idempotent).
- **Create** `lib/features/calendar/data/repositories/calendar_repository_impl.dart` — orchestrator. Same shape as `NotesRepositoryImpl`:
  - `create()` → local upsert (with `localPending: true`) + outbox enqueue (`OutboxOp(create)`).
  - `update()` → squash on pending create; otherwise enqueue update with `expectedUpdatedAt = current.updatedAt`.
  - `delete()` → squash pending create+update; enqueue delete.
  - `refresh({from, to})` → `GET /calendar?from=...&to=...`, diff with local, preserve `localPending`.
  - `resolveConflict(KEEP_MINE | ACCEPT_SERVER)` — same as notes.
- **Create** `lib/features/calendar/data/services/calendar_outbox_replay_handler.dart`:
  - `feature = 'calendar'`.
  - `replay(op)` dispatches to `remote.create/update/delete` and maps outcomes to `OutboxReplayResult.success / retry / conflict / dead`.
- **Modify** `lib/features/calendar/presentation/screens/calendar_screen.dart` (1606 lines today):
  - Remove `SimpleListCache('calendar')` usage; use `ICalendarRepository.watchAll()`.
  - Remove direct `CalendarRemoteDataSource` writes; route through repo.
  - Add small sync indicator on cards where `localPending == true`.
  - Add conflict banner at top + per-event ⚠ icon → opens `ConflictResolutionDialog` (the same widget from notes — works for any entity that has `title` + `content`-like preview text; we adapt or generalize).
  - **Minimum-touch refactor:** keep month/day/list view widgets intact; only swap the data feed and add indicators.
- **Optional generalization:** if `ConflictResolutionDialog` is notes-specific (it reads `local.title`/`local.content`), introduce a small generic version `EntityConflictDialog<T>` that accepts label/title/preview callbacks. Decide during plan stage; non-blocking.

### Refresh strategy: rolling window

Unlike notes (where we fetched everything), calendars accumulate historical events. To bound payload:

- Default `refresh()` requests `from = now - 30 days`, `to = now + 90 days`.
- When the screen navigates to a month outside the cached window, it calls `refresh(from: monthStart, to: monthEnd)` for that range. The repository deduplicates upserts on the local box.
- Conflicts and outbox sync are independent of refresh windows — they apply to whatever event ids the outbox holds.
- Diff on refresh removes only events that were in the requested window AND not returned by the server (server is source of truth for that window). Events outside the requested window stay in local cache.

### Flow examples

**Offline create:**
```
[User taps + → New Event sheet → save]
  → repo.create(draft with id = uuid())
    → local.upsert(event{id, …, localPending: true})
    → outbox.enqueue(OutboxOp{feature:'calendar', op:create, entityId:id, payload:{title,startAt,…}})
  → watchAll() emits
  → UI shows event with pending dot
[Connectivity returns]
  → drain → handler.replay → POST /calendar {id, …}
  → 201 → local.upsert(serverEvent{localPending:false})
  → outbox.remove()
```

**Offline edit with conflict:**
```
Device A: edit title offline → outbox.update with expectedUpdatedAt
Device B: edit title online (server updatedAt advances)
Device A reconnects → drain → PATCH 409 → handler returns conflict
  → outbox.markConflict + local.conflictedWith = currentEvent
  → UI: banner + ⚠ icon → user taps → dialog
  → "Keep mine" → re-enqueue with server's updatedAt as new OCC token → drains → 200
```

## Edge cases (mirrors notes)

- App killed during `inflight`: `OutboxQueue.onBoot()` resets inflight → pending. Server idempotency by `id` / `expectedUpdatedAt` makes retry safe.
- Edit-then-delete offline: delete squashes pending update; deletes also squash pending create (event never reached server).
- Refresh after long offline: only events inside the requested window that aren't on the server get removed locally. Events with `localPending:true` are preserved.
- `reminderSent`: server-managed; client `update` payload excludes this field. If the server toggled `reminderSent` while client was offline, refresh pulls fresh state.
- `contactIds`: the server creates `CalendarInvite` records on sync. Local cache of own event shows `contactIds` as the source of truth; invites cache refreshes on `GET /calendar/invites`.
- `recurrence`: opaque JSON. Diff treats it as a black box; passes through outbox payload.
- Hard cap: `attempts >= 10` → dead (same as notes, shared via `OutboxReplayService`).

## Testing

### Backend (`taler-id`)

`src/calendar/calendar.service.spec.ts` — unit tests:
- `create({id})` accepts and persists supplied id.
- `create({id})` twice with same id (same user) → returns existing.
- `create({id})` cross-user id collision → 409.
- `update({expectedUpdatedAt: matching})` → 200.
- `update({expectedUpdatedAt: stale})` → throws `ConflictException` with `currentEvent` in response.
- `update({})` without `expectedUpdatedAt` → existing LWW behavior preserved.
- `delete` twice → second is 404, mapped to client success.

### API integration (`taler_id_tests`)

New `calendar_offline_test.ts`, npm scripts `test:calendar:offline` + `:prod`. 7 steps mirroring the notes test:
1. POST /calendar with custom id → returns same id.
2. POST again → idempotent, original payload preserved.
3. PATCH no expectedUpdatedAt → LWW.
4. PATCH matching expectedUpdatedAt → 200 + advanced updatedAt.
5. PATCH stale expectedUpdatedAt → 409 + `currentEvent` in body.
6. DELETE → 200.
7. DELETE again → 404.

### Mobile (`taler_id_mobile`)

- `test/features/calendar/data/datasources/calendar_local_datasource_test.dart` — Hive CRUD + watch (4 tests).
- `test/features/calendar/data/services/calendar_outbox_replay_handler_test.dart` — 4 tests for create/update/delete/conflict outcomes.
- `test/features/calendar/data/repositories/calendar_repository_impl_test.dart` — 7 tests mirroring notes (create, squash update on pending create, update synced, delete pending, delete synced, KEEP_MINE, ACCEPT_SERVER).

### Hardware smoke (mandatory before merge to PROD)

On emulator (or device):
1. **Offline CRUD**: airplane on → create 3 events → edit one → delete one → airplane off → indicators clear in 5s.
2. **Conflict**: edit event A offline; parallel curl PATCH from host changes event A; reconnect → conflict banner → dialog → "Keep mine" → server has phone version.
3. **Kill-mid-sync**: airplane on → create event → airplane off → force-quit app → relaunch → event still local + completes sync.

## Rollout

- Backend changes → `dev` branch on `taler-id` → deploy to DEV (`89.169.55.217`).
- Mobile changes → `dev` branch on `taler_id_mobile` → dev APK built on PROD server, published to `/var/www/downloads/taler-id-dev.apk`.
- Hardware smoke pass.
- HARD GATE: wait for explicit user "deploy to PROD" approval.
- PROD: merge `dev → main` on both repos, redeploy backend (`138.124.61.221`), build PROD APK + iOS TestFlight + DMG/Windows/Linux.
- Run full PROD test suite including `test:calendar:offline:prod`.

## Out of scope (sibling specs / future)

- Accept / decline / maybe invite responses offline.
- Contact requests offline (separate Contact-offline spec, next).
- Favorites offline (separate spec, last).
- 3-way merge / line-level diff in conflict UI.
- Recurrence-aware merge.
- Desktop port.

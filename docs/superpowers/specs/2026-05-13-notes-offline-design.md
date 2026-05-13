# Notes Offline (CRUD + OCC) — Design

**Date:** 2026-05-13
**Author:** Dmitry + Claude (brainstorming)
**Scope:** Full offline CRUD for Notes feature, with optimistic concurrency control on update. Proof-of-pattern for a reusable outbox infrastructure that will later be applied to calendar / contacts / favorites.
**Stage:** 2 of overall "offline mode" work (Stage 1 = AI-delivery sync, shipped).
**Affected repos:** `taler_id_mobile` (Flutter), `taler-id` (NestJS). Desktop (`taler_id_desktop`) is a separate, follow-up PR using the same code.

## Problem

The Notes feature today works only when online. Reads have a `SimpleListCache` (Hive box `notes`) that hydrates on screen open, but every write (`POST /notes`, `PATCH /notes/:id`, `DELETE /notes/:id`) requires an open connection. On the road / on metro / on a plane, the user cannot capture an idea, edit an existing note, or remove one. The same gap exists in `taler_id_desktop` (forked codebase).

The user explicitly asked for offline support for notes among other things. Notes is chosen first because it is the most write-heavy of the four offline candidates (notes, calendar, contacts, favorites) and therefore the cleanest place to harden the outbox pattern before reusing it.

## Goals

- Create, edit, and delete notes while offline. Reflects in the UI immediately, syncs to server when connectivity returns.
- Multi-device safety: if the same note has been edited on another device while a local edit was pending, the user **sees a conflict** instead of silently losing data. Resolution is the user's explicit choice (keep mine / take server's), not an algorithmic merge.
- The offline infrastructure (`OutboxQueue`, `OutboxReplayService`, conflict-resolution UX) is reusable. Adding calendar / contacts / favorites later means writing a thin replay handler plus a UI refactor, not redesigning the pattern.
- No breakage of the existing online path. Notes screen still renders instantly from cache on open, refresh still works.

## Non-goals (this spec)

- 3-way diff / line-level merge of conflicted notes. Conflict UI shows two full-text versions and asks the user to choose one.
- Bulk operations (multi-select delete with offline queue). Single-item at a time.
- Automatic conflict resolution heuristics.
- Application of the outbox pattern to calendar, contacts, favorites — separate specs.
- Desktop (`taler_id_desktop`) port — separate PR using the same code paths.
- True CRDT / transaction-log architecture. The user explicitly chose OCC + LWW over a CRDT model after weighing trade-offs.
- Tunable retry/backoff settings exposed in UI/admin. Hardcoded constants for now.

## Architecture

### Data model

**Server `Note` (Prisma `prisma/schema.prisma`):** no schema change. Uses existing fields:
- `id String @id @default(uuid())` — now accepts a client-supplied UUID for idempotent create.
- `updatedAt DateTime @updatedAt` — version token for optimistic concurrency.

**Server API contract changes:**

- `POST /notes`: accepts optional `id: string` in body.
  - No `id` → existing behavior (server generates UUID).
  - `id` given, no existing note with that id → create with that id.
  - `id` given, note exists with that id **and same userId** → return existing as-is (200, idempotent retry). Does not apply the payload — that is `PATCH`'s job.
  - `id` given, note exists with that id but **different userId** → 409 Conflict (collision; client must not retry).
- `PATCH /notes/:id`: accepts optional `expectedUpdatedAt: ISO8601` in body.
  - Not given → existing LWW behavior.
  - Given and matches DB `updatedAt` → apply, return updated note.
  - Given and does NOT match → **409 Conflict** with body
    ```
    { currentNote: <full Note>, yourPayload: <what client sent> }
    ```
- `DELETE /notes/:id`: unchanged. If note already deleted / does not exist → 404. Client treats 404 as success (idempotent).

**Client Hive boxes:**

- `notes_local` — replaces / extends the existing `SimpleListCache('notes')`. Stores `NoteEntity` records:
  ```dart
  NoteEntity {
    id: String                       // UUID, client-generated for offline-create
    title: String
    content: String
    source: NoteSource               // 'MANUAL' | 'ASSISTANT'
    createdAt: DateTime
    updatedAt: DateTime              // last KNOWN server version
    localPending: bool               // true if there is an outbox op in flight for this note
    conflictedWith: Map<String, dynamic>?  // set when 409: holds the server's currentNote
  }
  ```
- `outbox_v1` — shared across features. Stores `OutboxOp`:
  ```dart
  OutboxOp {
    opId: String                     // UUID, idempotency on retries
    feature: String                  // 'notes'
    op: 'create' | 'update' | 'delete'
    entityId: String                 // the note's id
    payload: Map<String, dynamic>?   // null for delete
    expectedUpdatedAt: DateTime?     // for update only
    attempts: int
    status: 'pending' | 'inflight' | 'failed_conflict' | 'failed_dead'
    createdAt: DateTime
    lastAttemptAt: DateTime?
    lastError: String?
  }
  ```

### Components

#### Shared infrastructure (under `lib/core/`)

- **`storage/outbox_op.dart`** — Freezed model for `OutboxOp` + status enum.
- **`storage/outbox_queue.dart`** — `OutboxQueue` service:
  ```dart
  class OutboxQueue {
    Future<void> enqueue(OutboxOp op);
    Future<List<OutboxOp>> pending();           // all not-success ops
    Future<OutboxOp?> nextPending();            // FIFO by createdAt, respecting backoff
    Future<void> markInflight(String opId);
    Future<void> markPending(String opId, {String? lastError, int? attempts});
    Future<void> markConflict(String opId, Map<String, dynamic> serverData);
    Future<void> markDead(String opId, String error);
    Future<void> remove(String opId);
    Stream<List<OutboxOp>> watch();             // for UI live count badges
    Future<void> onBoot();                       // resets all 'inflight' → 'pending'
  }
  ```
- **`services/outbox_replay_service.dart`** — `OutboxReplayService`:
  - Holds a registry of `OutboxReplayHandler`s keyed by `feature`.
  - `Future<void> drain()` is the entry point. Single-flight via `_draining` guard. Iterates pending ops in FIFO; for each: respect backoff window, dispatch to handler, apply result.
  - Calls `OutboxQueue.onBoot()` once on startup.
  - Public method `registerHandler(handler)` for DI wiring.
  - **Drain triggers:**
    1. Connectivity transition `none → wifi|cellular` (via `ConnectivityWatcher`).
    2. Socket reconnect (already exposed by `MessengerRemoteDataSource.reconnectStream`).
    3. `AppLifecycleState.resumed` (same `WidgetsBindingObserver` pattern as Stage 1; can share the observer or add a separate one).
    4. Manual: UI "retry now" buttons call `drain()` directly.
    5. Periodic safety net: 30s timer.
- **`services/connectivity_watcher.dart`** — wraps `connectivity_plus`. Emits a `Stream<bool>` (online/offline) and on `none → connected` transitions calls `OutboxReplayService.drain()`. Registered in DI at startup.
- **`outbox_replay_handler.dart`** (interface in same file or separate):
  ```dart
  abstract class OutboxReplayHandler {
    String get feature;
    Future<OutboxReplayResult> replay(OutboxOp op);
  }
  sealed class OutboxReplayResult {
    factory OutboxReplayResult.success();
    factory OutboxReplayResult.retry({required String error});
    factory OutboxReplayResult.conflict({required Map<String, dynamic> serverData});
    factory OutboxReplayResult.dead({required String error});
  }
  ```

#### Notes feature

- **`domain/entities/note_entity.dart`** — Freezed `NoteEntity` (fields above). Replaces the raw `Map<String, dynamic>` used today.
- **`domain/entities/note_source.dart`** — enum `MANUAL | ASSISTANT`.
- **`domain/entities/conflict_resolution.dart`** — enum `KEEP_MINE | ACCEPT_SERVER`.
- **`domain/repositories/i_notes_repository.dart`**:
  ```dart
  abstract class INotesRepository {
    Stream<List<NoteEntity>> watchAll();
    Future<void> refresh();                                  // server fetch + diff
    Future<NoteEntity> create(String title, String content, {NoteSource source = NoteSource.MANUAL});
    Future<NoteEntity> update(String id, {String? title, String? content});
    Future<void> delete(String id);
    Future<void> resolveConflict(String id, ConflictResolution choice);
    Stream<int> watchPendingCount();
    Stream<int> watchConflictCount();
  }
  ```
- **`data/datasources/notes_local_datasource.dart`** — Hive-backed CRUD on `notes_local` box. `Stream<List<NoteEntity>>` via `box.watch()`.
- **`data/datasources/notes_remote_datasource.dart`** — existing file, modified:
  - `create(...)` accepts optional `id` parameter, includes in POST body.
  - `update(...)` accepts optional `expectedUpdatedAt`, includes in PATCH body.
  - On HTTP 409 from update: throws `NoteConflictException(currentNote)`.
- **`data/repositories/notes_repository_impl.dart`** — orchestrator:
  - `watchAll()` — `BehaviorSubject` over local box's watch stream.
  - `create()` — generate UUID, write to local box with `localPending: true`, enqueue `OutboxOp(create)`.
  - `update()` — read current local, write new fields with `localPending: true`, enqueue `OutboxOp(update, expectedUpdatedAt = local.updatedAt)`. Pre-enqueue squash: if there is already a pending update for the same entityId, replace it (latest local state wins for the next sync). If there is a pending create — update the create payload directly instead of enqueueing an update.
  - `delete()` — remove from local box (or mark `deletedLocally`, hidden from UI), enqueue `OutboxOp(delete)`. Squash: if pending create exists for the same id, drop both (note never reached server). If pending update exists, drop it.
  - `refresh()` — `GET /notes`, diff against local: server-only → add, both-exist → keep server data (unless local has `localPending=true`, then preserve local), local-only-and-not-pending → remove.
  - `resolveConflict(id, KEEP_MINE)` — replace the `failed_conflict` op with a fresh `update` op using the server's `updatedAt` as `expectedUpdatedAt`; clear local `conflictedWith`.
  - `resolveConflict(id, ACCEPT_SERVER)` — overwrite local note with the conflicted server version; drop the conflict op.
- **`data/services/notes_outbox_replay_handler.dart`** — implements `OutboxReplayHandler`:
  - `replay(op)` dispatches to `_remote.create / update / delete` based on `op.op`.
  - Maps HTTP outcomes:
    - `create` 2xx → success, store returned note in local box (clears `localPending`).
    - `create` 4xx (other than 409) → dead.
    - `create` 5xx / network error → retry.
    - `update` 2xx → success, replace local with returned note.
    - `update` 409 (`NoteConflictException`) → conflict, server data stored on local note.
    - `update` 4xx other → dead. 5xx / network → retry.
    - `delete` 2xx or 404 → success, ensure local removed.
    - `delete` 4xx other → dead. 5xx / network → retry.

#### Presentation layer

- **`presentation/screens/notes_screen.dart`** (refactor, stays `StatefulWidget`):
  - `initState`: subscribe to `_repo.watchAll()`, `watchPendingCount()`, `watchConflictCount()`. Call `_repo.refresh()` fire-and-forget.
  - Card UI: small "pending sync" dot icon on note cards where `note.localPending == true`. Different icon (e.g. ⚠️ filled) where `note.conflictedWith != null`.
  - Top banner when `conflictCount > 0`: tappable, opens conflict-resolution list.
  - Create / edit / delete buttons call `_repo.*` methods (no awaiting for network).
  - Pull-to-refresh: `_repo.refresh()` + `outboxReplayService.drain()`.
- **`presentation/widgets/conflict_resolution_dialog.dart`** — two-column view of local vs server version, three buttons: "Оставить мою" → `resolveConflict(KEEP_MINE)`, "Принять серверную" → `resolveConflict(ACCEPT_SERVER)`, "Закрыть" → dismiss without resolving.

### Flow diagrams (textual)

**Offline create:**
```
[UI: tap "create"]
  → repo.create(title, content)
    → local.upsert(NoteEntity{id=uuid(), localPending=true, ...})
    → outbox.enqueue(OutboxOp{op:create, entityId:<uuid>, payload:{title,content,source}, ...})
  → watchAll() emits new list
  → UI shows note with pending dot
...later, connectivity returns...
[ConnectivityWatcher: none→wifi]
  → OutboxReplayService.drain()
    → handler.replay(op)
      → POST /notes {id, title, content, source}
      → 201 with note body
    → local.upsert(serverNote{localPending=false})
    → outbox.remove(opId)
  → UI dot disappears
```

**Offline edit with conflict on sync:**
```
[Device A offline: user edits note X title → "Y"]
  → repo.update(X, title:"Y")
    → local: X.title="Y", localPending=true
    → outbox.enqueue(OutboxOp{op:update, entityId:X, payload:{title:"Y"}, expectedUpdatedAt:<old>})
[Meanwhile, Device B online edits same note: title → "Z"]
  Server now has X.title="Z" with new updatedAt
[Device A reconnects]
  → drain → handler.replay
    → PATCH /notes/X {title:"Y", expectedUpdatedAt:<old>}
    → 409 {currentNote: {title:"Z",...}}
    → handler returns conflict
  → outbox.markConflict(opId, serverData)
  → local: X.conflictedWith = {title:"Z",...}, localPending stays true
  → UI: conflict banner appears, X card shows ⚠️
[User taps X, sees dialog: "Mine: Y" vs "Server: Z"]
[User taps "Оставить мою"]
  → repo.resolveConflict(X, KEEP_MINE)
    → outbox.remove(oldOpId)
    → outbox.enqueue(OutboxOp{op:update, entityId:X, payload:{title:"Y"}, expectedUpdatedAt:<Z's updatedAt>})
    → local: X.conflictedWith=null
  → drain replays → 200 → done, server now has "Y"
```

## Edge cases (already addressed in the design)

- **App killed during `inflight`:** `OutboxQueue.onBoot()` resets all `inflight` → `pending`. Server idempotency (same `id` for create, `expectedUpdatedAt` for update, 404→success for delete) makes retry safe.
- **Edit-then-delete offline:** `delete` enqueue squashes any pending update; squashes pending create + drops local note entirely.
- **Refresh after a long offline period:** server diff removes locally-existing-but-not-on-server notes, EXCEPT notes with `localPending=true` (still in outbox).
- **Token expiry:** `AuthInterceptor` refreshes transparently. If refresh fails (refresh token expired) → op stays `pending`, retried on next login.
- **Network "ghost 200" (server accepted, client missed response):** retry sends same `id` → server returns existing note (idempotent).
- **User deletes note before resolving conflict:** delete-op replaces conflict-op (squashing). Delete wins.
- **Server returns a different `id` than what client sent:** treated as a server bug; client logs, keeps local id as authoritative.
- **Hard cap on attempts:** `attempts >= 10` → automatic `failed_dead`. Backoff: `min(1s * 2^attempts, 5min)`. Total max time before dead ≈ 33 min.

## Testing

### Backend (`taler-id`)

`src/notes/notes.service.spec.ts` — unit tests:
- `create({id})` accepts and persists supplied id.
- `create({id})` twice with same id (same user) → second call returns existing, no duplicate.
- `create({id})` twice with same id (different user) → 409 Conflict.
- `update({expectedUpdatedAt: matching})` → 200 + updated note.
- `update({expectedUpdatedAt: stale})` → throws ConflictException with `currentNote` payload.
- `update({})` without expectedUpdatedAt → existing LWW behavior preserved.
- `delete` twice → second is 404, controller maps to client-visible status.

### API integration test (`taler_id_tests`)

New file `notes_offline_test.ts`, scripts `test:notes:offline[:prod]`:
1. Login.
2. POST /notes with custom `id` → 201, response echoes the id.
3. Same POST again → 200 (idempotent), no duplicate in `GET /notes`.
4. PATCH with correct `expectedUpdatedAt` → 200, new `updatedAt`.
5. Simulate concurrent edit: bare PATCH (no expected) bumps `updatedAt`; immediate PATCH with stale `expectedUpdatedAt` → 409, body contains `currentNote`.
6. DELETE → 2xx. DELETE again → 404.
7. Backwards-compat: PATCH with no expectedUpdatedAt — still works (old clients unchanged).

### Mobile (`taler_id_mobile`)

- `test/core/storage/outbox_queue_test.dart` — enqueue/dequeue, persistence across restart simulation, `onBoot` resets inflight.
- `test/core/services/outbox_replay_service_test.dart` — drain happy path, retry with backoff, dead on 4xx, conflict-routing into queue.
- `test/features/notes/data/repositories/notes_repository_impl_test.dart`:
  - `create()` writes local + enqueues op + emits new list.
  - `update()` squashes pending update for same id.
  - `delete()` squashes pending create + drops local.
  - `refresh()` removes server-deleted local notes but preserves `localPending` ones.
  - `resolveConflict(KEEP_MINE)` enqueues fresh update with server's `updatedAt`.
- `test/features/notes/data/datasources/notes_local_datasource_test.dart` — Hive box persistence + watch stream.
- `test/features/notes/data/services/notes_outbox_replay_handler_test.dart` — all HTTP outcome mappings.
- `test/features/notes/presentation/widgets/conflict_resolution_dialog_test.dart` — renders both versions, button taps call correct repo methods.

### Hardware smoke (mandatory before merge to `dev`)

1. Airplane mode → create 3 notes → all visible with pending dot.
2. Edit one (still offline) → pending dot remains.
3. Delete one (offline) → disappears from UI.
4. Disconnect airplane mode → watch ops replay in order, dots disappear.
5. **Conflict:** edit note A on phone (offline) → curl/desktop edits note A in parallel → reconnect phone → conflict banner appears → tap → choose "Оставить мою" → verify server has phone's version.
6. **Kill-mid-sync:** airplane on → create note → airplane off → immediately force-quit app before sync completes → relaunch → note still present locally → autom-drain completes within seconds → server has it.

## Rollout

- Backend changes deploy to **DEV first** (`dvolkov@89.169.55.217`, branch `dev`).
- Mobile dev branch + dev APK on build server (138.124.61.221), download URL https://id.taler.tirol/download/taler-id-dev.apk.
- Hardware smoke on a physical phone.
- Only after explicit user "deploy to PROD" approval: backend to PROD (138.124.61.221, branch `main`), mobile prod APK + iOS TestFlight + DMG/Windows/Linux as per CLAUDE.md.

## Out of scope (sibling projects, separate specs)

- Apply pattern to calendar (events CRUD offline) — same outbox infra, thin replay handler.
- Apply pattern to contacts (read offline, plus offline contact-request enqueue).
- Apply pattern to favorites — partial offline support already exists in messenger.
- Port to `taler_id_desktop` (forked codebase) — separate PR, same code.
- 3-way merge or line-level diff in conflict UI.
- True CRDT / transaction log (considered, deferred per YAGNI).

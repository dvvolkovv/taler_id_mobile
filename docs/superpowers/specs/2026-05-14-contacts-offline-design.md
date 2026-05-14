# Contacts Offline (Read + Accept/Reject) — Design

**Date:** 2026-05-14
**Author:** Dmitry + Claude (brainstorming)
**Scope:** Local-first display of contacts and pending requests; accept / reject of incoming requests works offline (queued in outbox).
**Stage:** 2.3 — third feature in the broader offline-mode track (after Notes 2.1, Calendar 2.2).
**Affected repos:** `taler_id_mobile` only. **No backend changes.**

## Problem

The Contacts screen today (`lib/features/contacts/presentation/screens/contacts_screen.dart`, 521 lines) loads three lists synchronously from the server on every open:
1. Incoming pending requests (`GET /messenger/contacts/requests`)
2. Accepted contacts (derived from `GET /messenger/conversations`)
3. Sent pending requests (`GET /messenger/contacts/requests/sent`)

When offline, the screen shows an empty list and the user cannot see whom they know, let alone respond to a request. No local cache, no outbox.

The user explicitly called out contacts among the four offline-target features.

## Goals

- View accepted contacts, incoming pending requests, sent pending requests offline (cache-first render).
- Accept / reject incoming requests offline — the action is captured optimistically in the UI and replayed via outbox when connectivity returns.
- Reuse the `OutboxQueue` / `OutboxReplayService` / `ConnectivityWatcher` infrastructure from notes (Stage 2.1) and calendar (Stage 2.2). No new core infrastructure.
- No regression for online users: same screen, same actions, plus a "pending sync" indicator on items awaiting outbox drain.

## Non-goals (this spec)

- **Send new contact request offline.** Discovery requires user-search (server-side), which is online-only. Send-request remains online-only; the UI surfaces a connectivity-aware error when attempted offline.
- **Block / unblock offline.** Separate feature, separate spec.
- **Contact alias (custom name) edits offline.** Separate model (`ContactAlias`), separate concern.
- **OCC / conflict resolution UI.** State transitions on `ContactRequest.status` are unambiguous (PENDING → ACCEPTED / REJECTED is one-way). If the server has already advanced state (e.g. other side cancelled), the outbox handler treats 4xx as success and refresh reconciles.
- **Desktop port.** Separate PR, same code.

## Architecture

### Data model

**Server `ContactRequest`** (`prisma/schema.prisma`): no schema change. Existing model with `(senderId, receiverId)` unique constraint and `PENDING | ACCEPTED | REJECTED` enum.

**Server API contract changes:** **none**. All existing endpoints unchanged:
- `POST /messenger/contacts/request` — body `{ receiverId }`.
- `GET /messenger/contacts/requests` — incoming PENDING for current user.
- `GET /messenger/contacts/requests/sent` — outgoing PENDING from current user.
- `PATCH /messenger/contacts/requests/:id/accept`.
- `PATCH /messenger/contacts/requests/:id/reject`.
- `GET /messenger/conversations` — used to derive accepted contacts (existing usage in the contacts screen).

**Client local model** — Freezed `ContactItemEntity`:
```dart
enum ContactStatus { incoming, accepted, pending }

@freezed
class ContactItemEntity {
  String userId;            // canonical key (NOT requestId)
  String name;
  String? username;
  String? avatarUrl;
  ContactStatus status;
  String? conversationId;   // only when status == accepted
  String? requestId;        // only when status == incoming or pending
  DateTime? requestSentAt;  // only when status == pending
  bool localPending;        // true when an accept/reject op is in flight in outbox
}
```

**Hive box `contacts_local`:** the aggregated list. Keyed by `userId`. Single user is unique per entry; status transitions in place.

**Outbox reuse:** `outbox_v1` box (shared with notes + calendar). New feature key `'contacts'`. Operation kinds re-used:
- `OutboxOpKind.update` → `payload = { action: 'accept' }` or `{ action: 'reject' }`. `entityId = requestId`.
  This avoids introducing a new `OutboxOpKind`. Discriminating by `payload.action` inside the handler is sufficient for two-op vocabulary.

### Components (mobile only)

- **Create** `lib/features/contacts/domain/entities/contact_item_entity.dart` — Freezed `ContactItemEntity` + `ContactStatus` enum.
- **Create** `lib/features/contacts/domain/repositories/i_contacts_repository.dart`:
  ```dart
  abstract class IContactsRepository {
    Stream<List<ContactItemEntity>> watchAll();
    Future<void> refresh();              // fetches 3 lists, merges into local
    Future<Map<String, dynamic>> sendContactRequest(String receiverId);  // online-only
    Future<void> acceptContactRequest(String requestId, String userId);
    Future<void> rejectContactRequest(String requestId, String userId);
    Stream<int> watchPendingCount();
  }
  ```
  Both accept/reject take both `requestId` (entity id for outbox) and `userId` (for local optimistic update keyed by userId).
- **Create** `lib/features/contacts/data/datasources/contacts_local_datasource.dart` — Hive box `contacts_local`. CRUD + `watchAll`. Pattern from `NotesLocalDataSource` and `CalendarLocalDataSource`.
- **Create** `lib/features/contacts/data/repositories/contacts_repository_impl.dart` — orchestrator:
  - `watchAll()` — stream over local box, sorted: `incoming` → `accepted` (alpha by name) → `pending` (mirrors current `contacts_screen` ordering).
  - `refresh()` — three parallel `GET`s, build merged item list, diff-upsert into local box (preserving any `localPending=true`).
  - `acceptContactRequest(requestId, userId)` — optimistic local update: change status to `accepted`, `localPending=true`. Enqueue `OutboxOp(update, entityId=requestId, payload={action: 'accept'})`. Squash: if a pending op for the same requestId exists (e.g. user tapped reject then accept), replace it.
  - `rejectContactRequest(requestId, userId)` — optimistic: remove the item from local box, enqueue `OutboxOp(update, entityId=requestId, payload={action: 'reject'})`. Squash same way.
  - `sendContactRequest(receiverId)` — direct call to `MessengerRemoteDataSource.sendContactRequest`. Throws on network error; UI shows snackbar.
- **Create** `lib/features/contacts/data/services/contacts_outbox_replay_handler.dart` — implements `OutboxReplayHandler`:
  - `feature = 'contacts'`.
  - `replay(op)`:
    - Reads `op.payload['action']`.
    - If `'accept'` → `messengerRemote.acceptContactRequest(op.entityId)`.
    - If `'reject'` → `messengerRemote.rejectContactRequest(op.entityId)`.
    - HTTP 2xx → success.
    - HTTP 404 (request not found) → success (already gone — local state is fine, refresh will reconcile).
    - HTTP 409 (already not PENDING) → success (state already at target).
    - 5xx / network → retry.
    - Other 4xx → dead.
  - On success of accept, fire-and-forget `IContactsRepository.refresh()` so the new `conversationId` and accepted-contact data become visible.
- **Modify** `lib/features/contacts/presentation/screens/contacts_screen.dart`:
  - Replace direct API `client.get<>(...)` calls in `_load()` with `_repo.watchAll()` stream subscription + fire-and-forget `_repo.refresh()`.
  - Replace accept/reject button handlers with `_repo.acceptContactRequest(reqId, userId)` / `_repo.rejectContactRequest(...)`.
  - Replace send-request button handler with `_repo.sendContactRequest(receiverId)` wrapped in try/catch — show snackbar on failure (specifically network/timeout suggests "Нужен интернет").
  - Add a small sync-dot indicator on items where `localPending == true`.
  - Pull-to-refresh: call `_repo.refresh()` + `OutboxReplayService.drain()`.
- **Modify** `lib/core/di/service_locator.dart`:
  - Open Hive box `contacts_local`.
  - Register `ContactsLocalDataSource`, `IContactsRepository → ContactsRepositoryImpl`, `ContactsOutboxReplayHandler`.
  - Register handler with `OutboxReplayService.registerHandler(...)`.

### Flow examples

**Offline accept:**
```
[Screen shows incoming request from Alice]
User taps "Accept"
  → repo.acceptContactRequest(requestId, alice.userId)
    → local: alice.status = accepted, localPending = true
    → outbox.enqueue(OutboxOp{feature:'contacts', op:update, entityId:requestId, payload:{action:'accept'}})
  → watchAll emits → UI shows alice as accepted contact with sync dot
[Connectivity returns]
  → drain → handler.replay → PATCH /messenger/contacts/requests/:id/accept → 200
  → outbox.remove
  → repo.refresh() → fetches conversation, sets alice.conversationId
  → watchAll emits → sync dot disappears, alice fully synced
```

**Offline send-request (rejected by repo):**
```
User searches for Bob (via online user-search — if offline, search itself fails)
User taps "Send request" (Bob's profile reachable from prior known data)
  → repo.sendContactRequest(bob.userId)
    → MessengerRemoteDataSource.sendContactRequest → throws DioException (offline)
  → UI catches → SnackBar "Нужен интернет"
```

**Outbox replay for a now-stale request (404):**
```
User accepted request offline.
In parallel: sender cancelled the request on their side.
Phone reconnects → drain → PATCH → 404
  → handler returns success (treat as "request already settled")
  → outbox.remove
  → refresh() → drops the entry (server confirms it's gone)
```

## Edge cases

- **App killed during inflight outbox op:** `OutboxQueue.onBoot()` (from notes work) resets `inflight` → `pending`. The accept/reject endpoints are idempotent on the server (PATCH from PENDING → ACCEPTED twice is benign; 409 or 404 both treated as success). Retry is safe.
- **Same request accepted then rejected offline (user changed mind):** squash logic — the new op replaces the previous one for the same `requestId`. Local state reflects the LATEST action.
- **Send-request while offline:** UI shows error; no outbox enqueue. User retries when online.
- **Refresh removes accepted contact who is now offline-incoming again:** unrealistic in practice (the server cannot revert ACCEPTED → PENDING). No handling needed.
- **`watchPendingCount`:** counts items in local box with `localPending == true`. Used by a small top-of-screen indicator if `count > 0`.

## Testing

### Backend
No changes, no new tests.

### API integration test (`taler_id_tests`)
No new integration test added in this spec — backend semantics unchanged.

### Mobile unit tests

- `test/features/contacts/data/datasources/contacts_local_datasource_test.dart` (4 tests):
  upsert + getAll sorting (incoming → accepted → pending), remove, upsert-replace, watchAll emits on changes.
- `test/features/contacts/data/repositories/contacts_repository_impl_test.dart` (5 tests):
  1. `acceptContactRequest` writes localPending + enqueues update op with payload.action=accept.
  2. `rejectContactRequest` removes local item + enqueues update op with payload.action=reject.
  3. Squash: accept then reject leaves only the reject op for that requestId.
  4. `sendContactRequest` throws on remote failure (verify exception propagates).
  5. `refresh` merges 3 server lists, preserves `localPending` items.
- `test/features/contacts/data/services/contacts_outbox_replay_handler_test.dart` (4 tests):
  accept success, reject success, 404 → success, network → retry.

### Hardware smoke
1. **Offline accept**: airplane on → tap accept on incoming request → list shows accepted with sync dot → airplane off → dot disappears within 5s; verify server-side status via curl.
2. **Offline reject**: airplane on → tap reject → request disappears from list → airplane off → server PATCH succeeds.
3. **Offline send-request error**: airplane on → tap send-request on a known contact → snackbar "Нужен интернет".

## Rollout

- Mobile changes only. Push `dev` branch, build dev APK on PROD server, publish to `/var/www/downloads/taler-id-dev.apk`.
- DEV API regression suite still passes (no backend changes).
- HARD GATE before PROD per the combined-release strategy: wait for explicit user approval after Stage 2.4 (Favorites) is also done.

## Out of scope (sibling specs / future)

- Block / unblock offline.
- Contact alias edit offline.
- Offline send-request (would require local user-search cache — significant scope).
- Mesh-based contact discovery offline (mesh handshake already gives device-level peer awareness, but mapping to ContactRequest is a separate concern).
- Desktop port.

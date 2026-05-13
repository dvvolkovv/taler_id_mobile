# Messenger Since-Cursor Sync — Design

**Date:** 2026-05-13
**Author:** Dmitry + Claude (brainstorming)
**Scope:** Bug fix — missed messages while client was offline/backgrounded
**Affected repos:** `taler_id_mobile` (Flutter), `taler-id` (NestJS)

## Problem

When the Taler ID mobile app is backgrounded, killed, or offline, the messenger Socket.IO
client cannot receive `new_message` events. Socket.IO does not buffer events, so any
message emitted server-side during that window is lost on the wire. The message is
persisted in the `Message` table on the server, but the client never sees it until
the user manually opens that conversation (which triggers `GET /messenger/conversations/:id/messages`).

This hits two flows hardest:

1. **AI Outbound bot** — `AI_OUTBOUND` conversation, the bot posts campaign progress and
   results asynchronously over minutes-to-hours. If the user backgrounds the app during a
   campaign, the bot's messages are missing on return.
2. **AI Analyst** — external Claude Worker posts analysis results into the chat
   asynchronously. Same symptom: user navigates away, returns, no response.

The bug is general (affects all conversations) but visible most in AI flows because
those have a server-side actor writing while the user is not actively in the chat.

Root cause confirmed in `messenger_bloc.dart:140-149`: on socket `connect` and
`reconnect`, the bloc only calls `_resendPending()` and `_refreshMeshContactKeys()`. There
is no refetch of inbound messages. `chat_room_screen.dart:204` listens to
`reconnectStream` only to clear an offline banner.

## Goals

- Deliver every message that was created server-side while the client was disconnected,
  for **all** conversations the user is a participant in.
- Trigger automatically on socket connect, socket reconnect, and app resume from
  background. No user action required.
- Be idempotent — multiple syncs of overlapping ranges must not produce duplicates in
  the UI.
- Cheap on the server: a single indexed range scan per page, bounded payload.

## Non-goals (v1)

- Edits, deletes, reaction changes, read-receipt deltas that happened while offline.
  These remain socket-only. If the user scrolls a chat after coming back, existing
  `GET /messenger/conversations/:id/messages` will return the current state. Acceptable
  because edits/deletes are rare relative to new messages, and the AI-delivery scenarios
  this design targets involve only INSERTs.
- Offline outbox for outgoing operations (notes, calendar, favorites, contacts). Tracked
  as a separate, larger sub-project per the user's prioritization.
- Server-side replay buffer with ack protocol. Out of scope; current pull model is
  enough.

## Design

### Cursor model

Opaque string of the form `"<ISO8601-millis>|<message-uuid>"`, e.g.
`"2026-05-13T10:30:45.123Z|f4a1c2d3-..."`. The pair `(sentAt, id)` is the tiebreaker for
timestamps that collide (multiple inserts in the same millisecond).

The cursor is monotonically increasing in the order defined by row-value comparison
`(sentAt, id)`. The server uses this to slice the message stream for the user.

### API contract

#### `GET /messenger/sync`

Auth: JWT bearer (`AuthGuard`).

Query params:
- `cursor` — opaque cursor string. **Optional**.
- `limit` — integer, default `200`, clamped to `500`.

**Behaviour:**

- **No `cursor` (initialization call):** server returns
  `{ messages: [], nextCursor: "<server-now-cursor>", hasMore: false }`. The
  `nextCursor` reflects the current "max" state for this user — set to the cursor of
  the most recent message the user is a participant of, or to `(now()|"")` if no
  messages exist yet. Client stores this and uses it for future delta calls.
- **With `cursor`:** server returns all messages from conversations where the user is a
  `ConversationParticipant`, with `(sentAt, id) > (cursorTs, cursorId)`, ordered
  ascending, limited by `limit`. If `limit + 1` rows are available, sets
  `hasMore: true` and `nextCursor` to the last returned message's cursor; otherwise
  `nextCursor` is the last returned cursor and `hasMore: false`.

**Response:**

```json
{
  "messages": [
    { ...full MessageEntity, conversationId, ... }
  ],
  "nextCursor": "2026-05-13T10:35:12.001Z|abc...",
  "hasMore": false
}
```

`MessageEntity` is the existing shape returned by `GET
/messenger/conversations/:id/messages`. Includes reactions, files, replies, edits. No
slim variant.

**SQL (Prisma `$queryRaw` because Prisma does not support row-value comparisons
natively):**

```sql
SELECT m.* FROM "Message" m
JOIN "ConversationParticipant" cp
  ON cp."conversationId" = m."conversationId" AND cp."userId" = $1
WHERE
  ($2::timestamptz IS NULL)
  OR (m."sentAt", m.id) > ($2::timestamptz, $3::text)
ORDER BY m."sentAt" ASC, m.id ASC
LIMIT $4
```

Then map rows back to `MessageEntity` using existing serializer.

**Index requirement:** `(conversationId, sentAt, id)` on `Message` — verify exists;
add migration if not. Combined with the join, gives a clean index range scan.

### Server changes

- New controller method in `src/messenger/messenger.controller.ts`:
  `GET /sync` → calls `MessengerService.sync(userId, cursor, limit)`.
- New service method `MessengerService.sync(userId, cursor, limit)` in
  `src/messenger/messenger.service.ts` implementing the query above and the
  initialization branch.
- DTO / type for `SyncResult` matching the response shape.
- Migration if the composite index is missing.

No changes to socket protocol, no changes to existing endpoints.

### Client changes

#### Storage

New Hive box `messenger_sync`, single key `cursor: String?`. Wrapper in
`lib/core/storage/sync_cursor_storage.dart`.

#### Data layer

- `MessengerRemoteDataSource.sync({String? cursor, int limit = 200})` →
  `Future<SyncResult>` calling the new endpoint via `DioClient`.
- `MessengerRepository.sync(...)` passes through.
- `SyncResult` type: `(List<MessageEntity> messages, String? nextCursor, bool hasMore)`.

#### Bloc

- New private event class `_SyncMessages` (not exported from the events file — UI does
  not trigger it).
- Handler `_onSyncMessages`:
  ```
  if (_syncInProgress) return;
  _syncInProgress = true;
  try {
    var cursor = await _syncCursorStorage.read();
    if (cursor == null) {
      final init = await _repo.sync();  // no cursor → initialization
      if (init.nextCursor != null) {
        await _syncCursorStorage.write(init.nextCursor!);
      }
      return;
    }
    for (var page = 0; page < 10; page++) {
      final res = await _repo.sync(cursor: cursor, limit: 200);
      for (final m in res.messages) {
        add(MessageReceived(m));  // existing handler dedups by msg.id
      }
      if (res.nextCursor != null) {
        cursor = res.nextCursor!;
        await _syncCursorStorage.write(cursor);
      }
      if (!res.hasMore) break;
    }
  } catch (e) {
    debugPrint('[sync] failed: $e');
  } finally {
    _syncInProgress = false;
  }
  ```
- Hard cap of 10 pages × 200 = 2000 messages per sync cycle. If the user was offline
  for very long, remaining delta drains on subsequent triggers (next reconnect /
  resume / chat open).

#### Triggers

1. **Socket initial connect:** after `_repo.connect(...)` in `MessengerConnect`
   handler, dispatch `_SyncMessages()`.
2. **Socket reconnect:** inside `_reconnectSub` listener (`messenger_bloc.dart:145`),
   alongside `_resendPending()`, dispatch `_SyncMessages()`.
3. **App resumed from background:** `MessengerBloc implements WidgetsBindingObserver`.
   In `didChangeAppLifecycleState`, when state is `AppLifecycleState.resumed` AND the
   bloc has a stored cursor, dispatch `_SyncMessages()`. Register observer in
   constructor, remove in `close()`.

#### Existing dedup

`_onMessageReceived` (`messenger_bloc.dart:733-790`) already:
- Drops duplicates by `msg.id`.
- Clears matching `temp_*` pending bubbles.
- Triggers `LoadConversations` after every insert, which handles the case where a
  message arrives for a conversation the client did not know about yet (new chat
  created server-side during offline window).
- Appends to local cache.

Sync-delivered messages flow through this same path with no special casing.

## Edge cases

- **Clock skew:** initial cursor comes from the server, not from `DateTime.now()`. No
  drift risk.
- **Cursor parse failure (corrupted Hive):** read returns `null`; bloc treats as fresh
  install, hits initialization call, recovers. Delta lost between corruption and
  recovery — acceptable degradation, user sees messages on next chat open.
- **Race between sync delta and live socket event for the same message:** dedup by
  `msg.id` in `_onMessageReceived`.
- **Multiple simultaneous triggers** (e.g. resume + reconnect within 100ms):
  `_syncInProgress` guard makes the second one a no-op. The first one's pagination
  already covers everything available.
- **Sync mid-page crash:** the cursor is advanced per page, after `MessageReceived`
  dispatch. If the app dies between fetch and cursor write, next run re-fetches the
  same page and dedup catches duplicates.
- **Large delta (> 2000 msgs):** drained over multiple sync cycles. UI is not blocked
  because messages are dispatched as events, processed sequentially by the bloc.
- **New conversation during offline:** delta includes message with unknown
  `conversationId`. Existing `_onMessageReceived` triggers `LoadConversations` →
  conversation list refreshes, preview shows.

## Testing

### Backend unit tests (`taler-id`)

`messenger.controller.spec.ts` and/or `messenger.service.spec.ts`:
- Initialization call (no cursor) returns empty messages and a non-null cursor.
- With cursor, returns only messages strictly greater than `(cursorTs, cursorId)`.
- Pagination: `limit=N` returns at most N rows; `hasMore` set correctly when N+1
  exist.
- Scope: user A cannot see messages from a conversation where they are not a
  participant.
- 401 without token.
- `limit > 500` is clamped to 500.

### API integration test (`taler_id_tests`)

New file `sync_test.ts`, registered as `npm run test:sync` and `npm run test:sync:prod`.

Steps:
1. Log in user A and user B (integration test accounts from CLAUDE.md).
2. A calls `GET /sync` without cursor → empty messages, non-null `nextCursor`. Save
   cursor as `C0`.
3. B sends 5 messages to the shared conversation.
4. A calls `GET /sync?cursor=C0` → exactly 5 messages, ascending order. Save
   `nextCursor` as `C1`.
5. A calls `GET /sync?cursor=C1` → 0 messages.
6. Pagination: B sends 250 messages. A calls with `cursor=C1&limit=100` → 100
   messages, `hasMore=true`. Repeat with returned cursor until `hasMore=false`. Sum
   must equal 250.
7. Scope: create unrelated conversation between C and D. A calls `GET /sync?cursor=...`
   — none of their messages appear.
8. AI Outbound simulation: A creates AI_OUTBOUND conversation, triggers a campaign
   (or insert messages directly into DB via test helper to avoid coupling to live
   outbound infra), disconnects, reconnects, calls sync → bot's messages present.

### Flutter unit tests (`taler_id_mobile`)

New file `test/features/messenger/messenger_bloc_sync_test.dart`:
- Mock repo `sync` returns 3 pages → bloc dispatches MessageReceived for each, cursor
  advances per page, dedup confirmed.
- Simulate race: dispatch live `MessageReceived(msg-X)` before sync delivers `msg-X` —
  second dispatch is a no-op.
- Lifecycle: simulate `AppLifecycleState.resumed` → `_SyncMessages` dispatched.
- Guard: dispatch `_SyncMessages` twice rapidly → second is no-op (only one
  `repo.sync` call observed in the same window).

### Hardware smoke (mandatory before merge to `dev`)

On two emulators (Pixel + iPhone simulator, or two physical devices):
- Device A: background app via home button.
- Device B: send 5 text messages to the shared conversation.
- Device A: foreground. Without opening the chat, conversations list shows updated
  preview and unread count.
- Device A: open chat → 5 messages present in correct order, no duplicates.
- Repeat for AI Outbound: launch a campaign, background the app, wait for results,
  foreground → results visible.
- Repeat for AI Analyst: send a long-running query, background → return → answer is
  visible.

## Rollout

- Backend deploys first to DEV (`89.169.55.217`), then mobile `dev` branch APK / iOS
  dev flavor.
- Mobile uses the endpoint defensively: 404 from server (old backend, mobile newer) →
  log and skip sync silently. App keeps working with existing behavior.
- After DEV smoke passes, backend to PROD (`138.124.61.221`) and mobile to `main`
  branch builds (APK + TestFlight + DMG / Windows / Linux as standard).

## Out of scope (sibling project)

Offline mode for notes, calendar, favorites, contacts — separate spec, separate plan.
The cursor design here is reusable in spirit (since-cursor pattern) for those domains
but not coupled.

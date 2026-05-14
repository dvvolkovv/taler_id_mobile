# Favorites Offline (cached SAVED-conversation id) — Design

**Date:** 2026-05-14
**Author:** Dmitry + Claude (brainstorming)
**Scope:** Cache the user's SAVED-conversation id locally so the pinned "Saved Messages" tile opens offline without an extra server round-trip.
**Stage:** 2.4 — fourth and final feature in the broader offline-mode track (after Notes 2.1, Calendar 2.2, Contacts 2.3).
**Affected repos:** `taler_id_mobile` only. **No backend changes.**

## Problem

Tapping the pinned `SavedPinnedTile` on the conversations screen calls `IMessengerRepository.getOrCreateSavedConversation()` (`POST /messenger/saved`) **every time** — even when the user has already opened Saved Messages before and the `conversationId` is known to the server. When the device is offline, the HTTP call throws and the UI shows a `savedOpenError` snackbar. The user cannot open their personal bookmark chat that they've used many times before.

Inside the SAVED chat itself, offline support is already complete via the existing messenger infrastructure (Hive cache, `PendingMessageService` outbox, Stage 1 sync endpoint, mesh fallback) — that part needs no change.

## Goals

- Tapping the `SavedPinnedTile` while offline navigates straight to the SAVED chat for any user who has ever opened it online once before.
- Optimistic navigation: if a cached id exists, navigate immediately; refresh from server in the background to keep the cache fresh.
- New users (never opened SAVED online) still get the existing error snackbar — acceptable because their first-ever open requires connectivity by design (server has to mint the row).
- No regression for online users: they see the same instant UX (cache fills on first online open).

## Non-goals (this spec)

- Deletion of dead-code `SavedMessagesScreen` + the legacy `saved_messages` Hive box reader. Separate cleanup PR.
- Per-message favoriting (pinning, bookmarking individual messages within other chats). Not a current product feature.
- Pre-warming the cache at app startup. Acceptable; cache fills on first tap.
- Desktop port (separate PR, same code).

## Architecture

### Component

A single new helper: `SavedConversationIdCache`.

- **File**: `lib/core/storage/saved_conversation_id_cache.dart`
- **Storage**: Hive box `saved_conv_id` (new), single key `id` holding the conversationId string.
- **API**:
  ```dart
  class SavedConversationIdCache {
    static const String boxName = 'saved_conv_id';
    Future<String?> read();
    Future<void> write(String id);
    Future<void> clear();
  }
  ```

The pattern mirrors `SyncCursorStorage` from Stage 1 (same shape; small, single-key Hive wrapper).

### Wiring

- `lib/main.dart` or `service_locator.dart` (whichever opens existing Hive boxes) opens `saved_conv_id` at startup.
- DI registers `SavedConversationIdCache` as a lazy singleton.
- `lib/features/messenger/presentation/widgets/saved_pinned_tile.dart` is the only call site that consumes the cache.

### Flow

**Online tap (first time):**
```
User taps tile
  → cache.read() → null
  → repo.getOrCreateSavedConversation() → "conv-xyz"
  → cache.write("conv-xyz")
  → context.go('/dashboard/messenger/conv-xyz')
```

**Online tap (subsequent):**
```
User taps tile
  → cache.read() → "conv-xyz"
  → context.go(... conv-xyz ...)  // immediate
  → fire-and-forget repo.getOrCreateSavedConversation() → maybe overwrites cache (no-op if same)
```

**Offline tap (cache present):**
```
User taps tile
  → cache.read() → "conv-xyz"
  → context.go(... conv-xyz ...)  // works; the chat room itself is offline-capable
  → background repo.getOrCreateSavedConversation() throws → swallow silently
```

**Offline tap (cache empty — first-ever open offline):**
```
User taps tile
  → cache.read() → null
  → repo.getOrCreateSavedConversation() throws
  → snackbar savedOpenError (existing behavior)
```

## Edge cases

- **Cache contains stale id** (e.g. server-side conversation was deleted — unlikely for SAVED but theoretically possible): chat room opens; `GET /messenger/conversations/:id/messages` returns 404; messenger flow handles the empty/error case as it does today.
- **Hive read failure / corrupted box**: `read()` catches any decode error and returns null → fallback to the online path.
- **Multi-device concurrent first-open**: server `getOrCreateSavedConversation` is idempotent (returns the same conversationId per user); each device caches the same id.
- **User logs out / switches account**: existing logout cleanup hooks should clear app-scoped Hive boxes (out of scope here — the cache would just be stale and unused until next open).

## Testing

### Backend
No changes, no new tests.

### API integration
No changes, no new tests.

### Mobile unit tests

`test/core/storage/saved_conversation_id_cache_test.dart` — 3 tests:
1. `read()` returns null when no id stored.
2. `write()` then `read()` returns the same value.
3. `clear()` removes the value.

Pattern mirrors `test/core/storage/sync_cursor_storage_test.dart` (uses `_FakePathProvider` + `Hive.init`).

### Hardware smoke

1. **Online first-open**: log in (fresh app state) → tap pinned `Saved Messages` tile → chat opens → exit app → relaunch in airplane mode → tap tile → chat opens immediately (no snackbar).
2. **Offline first-open (regression check)**: clear app data → relaunch in airplane mode → tap tile → snackbar shows (existing behavior preserved).

## Rollout

- Mobile-only change. Push `dev` branch, build dev APK on PROD server, publish to `/var/www/downloads/taler-id-dev.apk`.
- DEV regression suite still green (no API changes).
- Combined PROD deploy gate per the original strategy: wait for explicit user approval after all four sub-projects (Notes 2.1, Calendar 2.2, Contacts 2.3, Favorites 2.4) are merged on `dev`.

## Out of scope (sibling specs / cleanup)

- Delete the dead `SavedMessagesScreen` + legacy `saved_messages` Hive reader.
- Per-message favorite / pin feature.
- Pre-warm cache at app boot.
- Desktop port.

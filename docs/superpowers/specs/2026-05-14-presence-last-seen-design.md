# User Presence + Last Seen — Design

**Date:** 2026-05-14
**Author:** Dmitry + Claude (brainstorming)
**Scope:** Show whether a chat partner is online right now or, if offline, when they were last seen — in the chat room AppBar and the user-profile screen. With three-tier privacy.
**Stage:** New feature, no preceding spec.
**Affected repos:** `taler_id` (backend) + `taler_id_mobile`. Desktop port follows automatically via merge into `taler_id_desktop`.

## Problem

Today the messenger has no notion of user presence. The chat header shows the partner's name and avatar but no "online" indicator and no "last seen" hint. There is also no presence-related privacy setting. This makes 1-on-1 chats feel cold: users can't tell whether a reply is imminent or the partner is offline for the day.

The existing `Session.lastSeenAt` field tracks per-device JWT-refresh activity — not what we want. It bumps on background API traffic (token refresh, FCM register) even when the app is in the background or terminated.

## Goals

- Chat room AppBar and user-profile screen show one of: `в сети` / `был(а) в сети только что` / `был(а) в сети 15 мин назад` / `был(а) в сети сегодня в 21:30` / `был(а) в сети вчера в 21:30` / `был(а) в сети 14.05.2026` / `был(а) в сети недавно` (the last when hidden by privacy).
- Server tracks online via a foreground heartbeat: client pings every 30 s while the app is in foreground. Server considers user online if Redis still holds a `presence:online:<userId>` key (90 s TTL).
- User can choose `EVERYONE` / `CONTACTS` / `NOBODY` for who sees their last-seen, via a dropdown in profile edit.
- UI auto-refreshes every 30 s while the chat header or profile screen is visible (polling).

## Non-goals

- Typing indicator (`печатает...`).
- Read receipts (`прочитано`).
- Real-time push of presence updates over Socket.IO — polling is fine for v1; revisit if it ever shows up in load metrics.
- Last-seen in conversations list — design call (D), not C.
- Per-conversation privacy (visible only to people you've chatted with). `CONTACTS` ACCEPTED-status is the proxy.
- Group-chat participant presence.
- Mesh-only peers (Bonjour discovery already gives "is on this Wi-Fi" semantic; that's a different layer).

## Architecture

### Source of truth
- **Online now** → Redis key `presence:online:<userId>` with TTL 90 s. Each heartbeat resets the TTL. Key existence = online.
- **Last seen** → `Profile.lastSeenAt: DateTime?` in Postgres. Updated by `presence/ping` but throttled to once per 60 s per user (via Redis key `presence:dbwrite:<userId>` TTL 60 s).
- **Privacy** → `Profile.lastSeenPrivacy: enum { EVERYONE, CONTACTS, NOBODY }` default `EVERYONE`.

### Data flow

**Heartbeat (client → server):**
```
Mobile app in foreground (every 30 s)
  → POST /presence/ping (JWT)
    → Redis SETEX presence:online:<viewerId> 90 "1"
    → If NOT EXISTS presence:dbwrite:<viewerId>:
        SETEX presence:dbwrite:<viewerId> 60 "1"
        UPDATE Profile SET lastSeenAt = NOW() WHERE userId = <viewerId>
  → 204 No Content
```

**Query (client → server):**
```
Mobile opens chat room or user profile screen
  → every 30 s while screen visible:
    GET /presence/:targetUserId (JWT, returns JSON)
      → If target == self: bypass privacy filter, return real data
      → Else: read Profile.lastSeenPrivacy
          EVERYONE → return real data
          CONTACTS → check ContactRequest WHERE status='ACCEPTED' AND
                     ((senderId=viewer AND receiverId=target) OR
                      (senderId=target AND receiverId=viewer))
              if exists → real data
              else → { isOnline: null, lastSeenAt: null, hidden: true }
          NOBODY  → { isOnline: null, lastSeenAt: null, hidden: true }
      → "real data" = { isOnline: EXISTS(presence:online:<target>), lastSeenAt: profile.lastSeenAt, hidden: false }
```

### Privacy

Privacy enforcement lives on the server only — the client always sends the same GET and trusts what comes back. `hidden=true` renders as "был(а) в сети недавно" — intentionally vague.

`CONTACTS` mode uses bidirectional check (sender OR receiver of the accepted request) so the relation is symmetric.

Privacy changes take effect immediately: the next polling tick (≤30 s) by anyone watching the user's status reads the new value.

### Components

#### Backend — new module `src/presence/`
- `presence.controller.ts` — three endpoints (see below).
- `presence.service.ts` — Redis read/write + Prisma read/update + privacy decision.
- `presence.module.ts` — wires controller + service; depends on `PrismaModule`, `RedisModule`.
- Mounted in `app.module.ts`.

#### Backend — schema migration
Adds two columns to `Profile` + one enum:
```prisma
enum LastSeenPrivacy {
  EVERYONE
  CONTACTS
  NOBODY
}

model Profile {
  // ... existing fields ...
  lastSeenAt        DateTime?
  lastSeenPrivacy   LastSeenPrivacy @default(EVERYONE)
}
```

#### Backend — profile DTO
Extend the existing `UpdateProfileDto` to accept optional `lastSeenPrivacy`. Existing `PATCH /profile` flow handles persistence.

#### Mobile — new feature folder `lib/features/presence/`

```
features/presence/
├── domain/
│   ├── entities/presence_entity.dart            (Freezed: bool isOnline?, DateTime? lastSeenAt, bool hidden)
│   └── repositories/i_presence_repository.dart  (ping, getPresence(userId), getMyPresence)
├── data/
│   ├── datasources/presence_remote_datasource.dart
│   └── repositories/presence_repository_impl.dart
└── presentation/
    ├── services/presence_heartbeat_service.dart   (lifecycle-aware ping loop)
    └── widgets/presence_label.dart                (universal subtitle widget; polls every 30 s)
```

`PresenceHeartbeatService`:
- Implements `WidgetsBindingObserver`.
- On `AppLifecycleState.resumed` AND logged-in → starts a 30 s `Timer.periodic` firing `repo.ping()`.
- On `paused/inactive/detached` → cancels timer.
- On logout (listens to `AuthBloc.stream` for `Unauthenticated`) → cancels timer.
- Singleton in `service_locator.dart`; started from `main.dart` after DI setup.

`PresenceLabel(userId)`:
- Stateful widget with a `Timer.periodic(30 s)` that calls `repo.getPresence(userId)` and rebuilds.
- Renders nothing while initial fetch in flight (avoid layout jitter).
- Uses formatter `formatLastSeen(PresenceEntity, AppLocalizations)`.

Formatter logic (`core/utils/presence_format.dart`):
| Condition | Output |
|---|---|
| `entity.isOnline == true` | `l10n.presenceOnline` ("в сети") |
| `entity.hidden == true` OR `lastSeenAt == null` | `l10n.presenceLastSeenRecently` ("был(а) в сети недавно") |
| `now - lastSeenAt < 60 s` | `l10n.presenceLastSeenJustNow` ("был(а) в сети только что") |
| `now - lastSeenAt < 60 min` | `l10n.presenceLastSeenMinutesAgo(N)` |
| same calendar day | `l10n.presenceLastSeenToday(HH:mm)` |
| previous calendar day | `l10n.presenceLastSeenYesterday(HH:mm)` |
| older | `l10n.presenceLastSeenOnDate(DD.MM.YYYY)` |

Pluralization (`X мин назад`) via ARB `placeholders` + `intl` plural rules.

#### Mobile — chat header / profile integration
- `chat_room_screen.dart` AppBar: insert `PresenceLabel(otherUserId)` as a small subtitle row under the partner name. Gate render: `conv.type == ConvType.PRIVATE`.
- `user_profile_screen.dart`: insert `PresenceLabel(userId)` above bio. Hide for self (`userId == AuthBloc.state.user.id`).
- Both screens dispose `PresenceLabel` automatically on screen exit (Flutter widget lifecycle), which stops the polling timer.

#### Mobile — privacy setting in profile edit
- `edit_profile_screen.dart`: new "Конфиденциальность" section with a single `DropdownButton<LastSeenPrivacy>` (3 values).
- Save flow: existing `_saveProfile()` extends to include `lastSeenPrivacy` in the PATCH payload.

## API contracts

### `POST /presence/ping`
- Auth: JWT (existing guard)
- Body: none
- Response: `204 No Content`
- Throttle: 3 req / 30 s per user (NestJS `@Throttle`)

### `GET /presence/:userId`
- Auth: JWT
- Path: target user id (UUID)
- Response 200:
  ```json
  { "isOnline": true | false | null,
    "lastSeenAt": "2026-05-14T07:55:00.000Z" | null,
    "hidden": true | false }
  ```
- `hidden=true` ⇒ `isOnline=null` AND `lastSeenAt=null`.
- 404 only if `userId` does not exist (not for blocked / privacy-hidden — those return 200 + hidden).

### `GET /presence/me`
- Auth: JWT
- Same response shape, no privacy filter (returns the caller's own real status).

### `PATCH /profile` (existing) extension
- Accepts new optional field `lastSeenPrivacy: 'EVERYONE' | 'CONTACTS' | 'NOBODY'`.
- Other PATCH fields unchanged.

## Edge cases

- **Self** — `chat_room_screen` does not render `PresenceLabel` for own user. Profile screen uses `/presence/me`. Privacy filter is bypassed when target == self.
- **Bot conversations** (AI Analyst, AI Outbound, SAVED Messages, GROUP) — `PresenceLabel` not rendered. Check via `ConvType`.
- **Blocked / deleted user** — server still returns 200 with `hidden=true` (don't leak existence). UI shows "недавно".
- **Privacy = CONTACTS, viewer has no accepted contact request** — `hidden=true`. After mutual accept, next polling tick (≤ 30 s) sees real data.
- **Redis empty after restart** — `isOnline=false`. `lastSeenAt` comes from Profile (cold-storage backup). Within 30 s of restart, foreground clients re-prime Redis.
- **Heartbeat throttling abuse** — NestJS `ThrottlerGuard` caps at 3 requests / 30 s per JWT user. 4th request → 429.
- **Privacy change is immediate** — no grace period. Setting NOBODY instantly hides from everyone's next poll.
- **Logged-out / token-expired client** — heartbeat service stops on `Unauthenticated` state. On 401 from `/presence/ping` it cancels its timer until next login.

## Testing

### Backend
- `src/presence/presence.service.spec.ts` (mocked Prisma + Redis):
  1. `ping` sets Redis key with 90 s TTL.
  2. `ping` writes `Profile.lastSeenAt` first time; second call within 60 s skips DB write.
  3. `getPresence` returns real data when target = `EVERYONE`.
  4. `getPresence` returns real data when target = `CONTACTS` AND requester is an accepted contact (either direction).
  5. `getPresence` returns `hidden=true` when target = `CONTACTS` AND no accepted contact.
  6. `getPresence` returns `hidden=true` when target = `NOBODY`.
  7. `getPresence` bypasses privacy when viewer == target (self).
  8. `getPresence` returns `isOnline=false` when Redis key absent but Profile has `lastSeenAt`.

### API integration (`taler_id_tests/presence_test.ts`, new `npm run test:presence[:prod]`)
- 2 real test accounts, contact already established (existing fixture).
- Steps:
  1. A pings → B reads → `isOnline=true`.
  2. Wait 95 s (just over Redis TTL) → B reads → `isOnline=false`, `lastSeenAt` ~95 s ago.
  3. A sets `lastSeenPrivacy=NOBODY` via PATCH /profile → B reads → `hidden=true`.
  4. A sets `lastSeenPrivacy=EVERYONE` → B reads → real data back.
  5. A sets `lastSeenPrivacy=CONTACTS` → register fresh account C (not a contact) → C reads A → `hidden=true`.

### Mobile unit tests
- `test/core/utils/presence_format_test.dart` — 7 branches of formatter.
- `test/features/presence/data/repositories/presence_repository_impl_test.dart` — parses normal response and `hidden` response, surfaces 401 cleanly.
- `test/features/presence/presentation/services/presence_heartbeat_service_test.dart` — starts pinging on `resumed`+logged-in, stops on `paused`, stops on `Unauthenticated`, stops on 401.

### Hardware smoke (manual)
- 2 phones, accounts A (iPhone) and B (Android), already contacts.
- Open chat A → B → AppBar shows `в сети` (A foregrounded).
- Background B → wait 90 s → A's screen shows `был(а) в сети только что` then `1 мин назад`.
- B opens profile → toggles privacy to `NOBODY` → switches back to A → A sees `недавно` within 30 s.

## Rollout

- Backend: deploy to DEV first (`dvolkov@89.169.55.217`), run new integration test against DEV, then to PROD on user approval.
- Mobile: ship on `dev` branch only initially. APK at `/var/www/downloads/taler-id-dev.apk`. Hardware-verify, then merge into `main` for the next combined PROD release (likely 1.0.72).
- Migration is forward-only: new `lastSeenAt` is nullable (NULL = "never seen since migration"); new `lastSeenPrivacy` defaults to `EVERYONE` on existing rows. No backfill script.

## Out of scope (sibling specs / future)

- Typing indicator.
- Read receipts.
- Real-time presence push over Socket.IO (Phase 2 if polling load becomes a problem).
- Per-conversation privacy.
- Last-seen in conversation list.
- Group-chat per-participant presence.
- Desktop port (auto-inherited via mobile→desktop merge).

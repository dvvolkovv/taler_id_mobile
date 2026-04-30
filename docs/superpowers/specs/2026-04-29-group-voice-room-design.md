# Zoom-Style Rooms — Phase 1: Group Voice Room

**Date:** 2026-04-29
**Author:** Dmitry + Claude (brainstorming session)
**Status:** Approved design, awaiting implementation plan
**Scope:** Phase 1 of a 5-phase decomposition of the larger "Zoom-style rooms" initiative.

---

## Context

The product currently supports 1-on-1 voice calls (LiveKit + CallKit + Socket.io). Dmitry wants to evolve this into a Zoom-style multi-party calling product. The full vision includes video, screen share, recording, AI-protocol bots, guest links, and SpatialChat-style breakout rooms with consent-based knock-to-join.

Because the full scope is 2-3 months of work, brainstorming decomposed it into five phases. **This spec covers Phase 1 only**: a multi-party voice room (audio-only) for Taler ID users picked ad-hoc from contacts. Phases 2-5 are scoped in §10 (non-goals) and will get their own specs.

### Phase decomposition (overall vision, for reference)

1. **Phase 1 — Group Voice Room (this spec).** 3-8 Taler ID users in audio-only call. Foundation for everything else.
2. **Phase 2 — Breakout with knock-to-join.** Sub-rooms inside an active call, peer-initiated, visible-and-knockable (SpatialChat-style).
3. **Phase 3 — Video + screen share.** Add video track and grid/speaker views.
4. **Phase 4 — Guest access via link.** Guest tokens, waiting room, host approval for non-Taler-ID users.
5. **Phase 5 — Recording + AI protocol.** Server-side recording (reuse existing recorder from outbound bot) + AI stenographer (reuse Deepgram + GPT-4o from ai-twin).

### Killer feature framing

The Phase 2 breakout mechanic is the actual product differentiator. Phase 1 is foundation work — without solid multi-party voice infra, breakouts are impossible. So Phase 1 is intentionally narrow: get group voice _working and stable_, then in Phase 2 add the unique mechanic on top.

### Decisions captured during brainstorming

| Q | Decision | Rationale |
|---|----------|-----------|
| Use cases | All three (Taler ID users + guests + AI) eventually; Phase 1 = users only | Avoid scope creep; auth path already works for Taler ID users |
| Lifecycle model | Ad-hoc multi-select from contacts (Calls tab) | Simplest entry; no calendar/persistent-room complexity in Phase 1 |
| Capacity | Up to 8 participants | 95% of real cases; LiveKit has headroom; UI fits without grid complexity |
| Invite flow | Lobby with status view (host sees who joined/declined/timed-out as it happens) | Better UX feedback than "fire-and-forget" CallKit; richer state |
| Permissions | Light host-mode (initiator has +invite/kick/mute-all); peer-equal otherwise | Some moderation needed for groups; full peer-to-peer feels chaotic at 8 |
| Mute-all semantics | Soft mute (broadcast request, client mutes locally) | Respects peer-equal; host asks not commands |
| Breakout visibility (Phase 2) | Visible + knock-to-join (SpatialChat-style) | Documented for Phase 2 design |

---

## 1. Architecture

```
┌──────────────────────┐                ┌─────────────────────┐
│  Mobile (Flutter)    │                │  NestJS Backend     │
│  features/voice/     │                │  src/voice/         │
│                      │                │                     │
│  ┌────────────────┐  │   REST/WS     │  ┌───────────────┐  │
│  │ NewGroupCall   │──┼──────────────►│  │ GroupCall     │  │
│  │ Screen         │  │               │  │ Controller    │  │
│  │ (multi-select) │  │               │  └───────┬───────┘  │
│  └────────┬───────┘  │               │          │          │
│           ▼          │               │  ┌───────▼───────┐  │
│  ┌────────────────┐  │               │  │ GroupCall     │  │
│  │ GroupCallLobby │◄─┼─Socket.io─────┤  │ Service       │  │
│  │ Screen         │  │ group_call_*  │  └───┬───────┬───┘  │
│  └────────┬───────┘  │               │      │       │      │
│           ▼          │               │      ▼       ▼      │
│  ┌────────────────┐  │               │   Prisma   Redis    │
│  │ GroupCall      │◄─┼─LiveKit──────►│  (state)   (queue)  │
│  │ ActiveScreen   │  │   audio        │                     │
│  └────────────────┘  │               │  ┌───────────────┐  │
│                      │               │  │ Messenger     │  │
│  Reused: VoiceClient │               │  │ Gateway       │  │
│  Reused: CallKit     │               │  │ (push events) │  │
└──────────────────────┘               │  └───────────────┘  │
                                       └─────────────────────┘
                       ┌──────────────────┐
                       │  LiveKit Server  │
                       │  (audio rooms)   │
                       └──────────────────┘
```

### New backend modules

- `src/voice/group-call/group-call.module.ts`
- `src/voice/group-call/group-call.service.ts` — orchestration (creation, lobby state, host actions, lifecycle)
- `src/voice/group-call/group-call.controller.ts` — REST API (8 endpoints)
- `src/voice/group-call/dto/*.dto.ts` — DTOs for create/invite/kick/mute-all
- `src/voice/group-call/jobs/timeout.processor.ts` — Bull queue worker for invite timeouts
- `src/voice/group-call/guards/group-call-host.guard.ts` — host-only authz
- Extension to `src/messenger/messenger.gateway.ts` — new Socket.io events `group_call_*`

### New mobile screens (Flutter)

- `lib/features/voice/presentation/screens/new_group_call_screen.dart` — multi-select from contacts
- `lib/features/voice/presentation/screens/group_call_lobby_screen.dart` — lobby with statuses
- `lib/features/voice/presentation/screens/group_call_active_screen.dart` — main call screen (3-8 participants list + active speaker)
- New `GroupCallBloc` + repository + datasource

### Reused without modification

- `VoiceService` (LiveKit token gen) — extended with one helper `generateGroupCallToken()`
- `CallKitService` (iOS VoIP push)
- `FcmPushService` (Android FCM)
- `MessengerGateway` Socket.io infra
- `AuthGuard` (JWT)
- LiveKit room infrastructure (no new servers)
- Redis (used for both invite cache and Bull queue)

### Isolation principle

`group-call/` is self-contained. Depends only on `VoiceService` (token generation) and `MessengerGateway` (push). Does not modify the existing 1-on-1 voice flow — eliminates regression risk on production users.

---

## 2. Data model (Prisma)

```prisma
enum GroupCallStatus {
  LOBBY      // created, host alone, waiting for first join
  ACTIVE     // ≥2 participants in room
  ENDED
}

enum GroupCallInviteStatus {
  CALLING    // push sent, ringing
  JOINED     // currently in room
  DECLINED   // pressed reject
  TIMEOUT    // didn't respond in 30s
  LEFT       // was JOINED, then left
}

model GroupCall {
  id               String           @id @default(uuid())
  livekitRoomName  String           @unique          // "group-{id}"
  hostUserId       String                            // initiator; transferred on leave
  status           GroupCallStatus  @default(LOBBY)
  startedAt        DateTime         @default(now())
  endedAt          DateTime?
  endedReason      String?                           // "all_left" | "timeout" | "host_ended"

  host             User             @relation("HostedGroupCalls", fields: [hostUserId], references: [id])
  invites          GroupCallInvite[]

  @@index([status, startedAt])
  @@index([hostUserId, startedAt])
}

model GroupCallInvite {
  id            String                 @id @default(uuid())
  groupCallId   String
  userId        String
  status        GroupCallInviteStatus  @default(CALLING)
  invitedAt     DateTime               @default(now())
  respondedAt   DateTime?
  joinedAt      DateTime?
  leftAt        DateTime?
  invitedBy     String                 // userId of host (relevant for mid-call invites)

  groupCall     GroupCall              @relation(fields: [groupCallId], references: [id], onDelete: Cascade)
  user          User                   @relation("GroupCallInvitesReceived", fields: [userId], references: [id])

  @@unique([groupCallId, userId])
  @@index([userId, status])
}
```

User relations:

```prisma
model User {
  // …existing fields…
  hostedGroupCalls   GroupCall[]       @relation("HostedGroupCalls")
  groupCallInvites   GroupCallInvite[] @relation("GroupCallInvitesReceived")
}
```

### State transitions

```
GroupCall:    LOBBY ──first JOINED──► ACTIVE ──last LEFT──► ENDED (all_left)
                │                       │
                │                       └──host /end──► ENDED (host_ended)
                │
                └──30s, all CALLING→TIMEOUT/DECLINED, none JOINED──► ENDED (timeout)

GroupCallInvite:  CALLING ──accept──► JOINED ──leave──► LEFT
                       │                  │
                       ├──reject──► DECLINED
                       └──30s──► TIMEOUT

  Re-join while ACTIVE: accepted from LEFT/DECLINED; status reset to JOINED.
```

### Redis usage

- Bull queue `group-call-timeouts` for delayed invite-timeout jobs (30s).
- Postgres is the source of truth; Redis is queue + transient cache.
- Optional: hash `groupcall:{id}:invites` (userId→status, TTL=2h) for hot-path Socket.io broadcasts. Can be added later if Postgres reads become hot.

### Indexes

- `(status, startedAt)` — cron cleanup of zombie LOBBY rooms
- `(hostUserId, startedAt)` — user's call history
- `(userId, status)` — "active calls for me" lookup (rejoin banner)
- `@@unique([groupCallId, userId])` — no duplicate invites

### Phase 2-5 evolution

- Recording (Phase 5) → add `recordingUrl: String?` to `GroupCall`
- Breakouts (Phase 2) → new model `BreakoutCall { parentGroupCallId, ... }` referencing parent `GroupCall`
- Video (Phase 3) → no schema change (LiveKit handles tracks; UI gate is feature flag)
- Guests (Phase 4) → add `Guest` model + `GroupCallGuestInvite`; or generalize `GroupCallInvite.userId` to nullable + `guestId` field

These are noted for forward-thinking only; **not in Phase 1 scope**.

---

## 3. API surface

### REST endpoints

Base path: `/voice/group-calls`. All require JWT bearer auth.

```
POST   /voice/group-calls
  body: { inviteeIds: string[] }                      // 1..7 contacts; total ≤8 in room
  → { groupCall: { id, livekitRoomName, livekitWsUrl, livekitToken, status, invites: [...] } }
  Creates GroupCall(LOBBY) + GroupCallInvite(CALLING) per invitee,
  fires VoIP/FCM push + Socket.io group_call_invite to each,
  returns livekitToken so host enters room immediately.

GET    /voice/group-calls/active
  → { calls: [{ id, host, invites, myStatus, livekitRoomName }] }
  Lists active calls where currentUser has invite in (CALLING, JOINED, LEFT, DECLINED)
  AND call.status in (LOBBY, ACTIVE). Used for "active call" banner.

GET    /voice/group-calls/:id
  → { groupCall: { id, host, status, invites } }
  Detail fetch (Socket.io is the primary update channel; this is for cold reads).

POST   /voice/group-calls/:id/join
  → { livekitWsUrl, livekitToken }
  Invitee accepts. invite.status=JOINED, joinedAt=now().
  If call.status=LOBBY → ACTIVE. Broadcasts group_call_status + group_call_joined.
  Idempotent: if already JOINED, returns same token.

POST   /voice/group-calls/:id/decline
  → { ok: true }
  invite.status=DECLINED, respondedAt=now(). Broadcasts group_call_status.
  If all invitees DECLINED/TIMEOUT and no JOINED → call=ENDED(timeout).
  409 if invite already JOINED.

POST   /voice/group-calls/:id/leave
  → { ok: true }
  Any participant exits. invite.status=LEFT, leftAt=now().
  If host leaves: transfer to next JOINED (sorted joinedAt asc); if none → ENDED(all_left).
  If last JOINED leaves → ENDED(all_left).
  Idempotent.

POST   /voice/group-calls/:id/invite           [host only]
  body: { userIds: string[] }
  Mid-call invitation. Inserts GroupCallInvite(CALLING) per userId, fires push,
  schedules timeout. 403 if caller != host.
  Capacity check: count JOINED + CALLING invites (= "occupied slots, including
  pending rings"). 409 Conflict if occupied + len(userIds) > 8.
  Reason: a CALLING invitee still occupies a slot — if all CALLING accept
  after new invitees are added, the room could overflow 8.

POST   /voice/group-calls/:id/kick             [host only]
  body: { userId: string }
  Forces invite.status=LEFT for userId, calls LiveKit removeParticipant,
  emits group_call_kicked to target only, group_call_status to others.
  400 if userId == hostUserId. 200 if already LEFT (no-op).

POST   /voice/group-calls/:id/mute-all         [host only]
  → { ok: true }
  Broadcasts group_call_mute_request to all participants except host.
  Soft mute: each client decides whether to disable its own mic track.
  Rate-limited 1/10s.

POST   /voice/group-calls/:id/end              [host only]
  Forces call to ENDED(host_ended). Broadcasts group_call_ended.
```

### Socket.io events (namespace `/messenger`)

**Server → Client:**

| Event | Payload | Recipients |
|-------|---------|-----------|
| `group_call_invite` | `{ groupCallId, host, invitees }` | each invitee user-room |
| `group_call_status` | `{ groupCallId, invites: [...] }` | all participants + invitees |
| `group_call_joined` | `{ groupCallId, userId, joinedAt }` | all participants |
| `group_call_left` | `{ groupCallId, userId, leftAt }` | all participants |
| `group_call_kicked` | `{ groupCallId, by, reason? }` | kicked user only |
| `group_call_mute_request` | `{ groupCallId, by }` | all participants except host |
| `group_call_host_changed` | `{ groupCallId, newHostUserId }` | all participants |
| `group_call_ended` | `{ groupCallId, reason }` | all participants + invitees |

**Client → Server:** REST endpoints above (no command-style WS). Echo via Socket.io after server processes.

### Push payloads

iOS VoIP push (CallKit):

```json
{
  "type": "group_call_invite",
  "groupCallId": "<uuid>",
  "host": { "id": "...", "displayName": "Алиса Иванова", "avatarUrl": "..." },
  "inviteeCount": 5,
  "livekitRoomName": "group-<uuid>"
}
```

Android FCM:

```json
{
  "type": "group_call_invite",
  "groupCallId": "<uuid>",
  "host": { ... },
  "inviteeCount": 5,
  "ttl_seconds": 30
}
```

### Authorization

- All endpoints: standard `JwtAuthGuard`.
- Host-only endpoints: `GroupCallHostGuard` checks `call.hostUserId === req.user.id`.
- Invitee endpoints (`/join`, `/decline`, `/leave`): controller validates `currentUser` has a `GroupCallInvite` for the `groupCallId` (prevents random join).

### Idempotency

- `/join`: if status already JOINED, return same livekitToken.
- `/leave`: if status already LEFT, 200 OK no-op.
- `/decline` after JOINED: 409 Conflict.
- `/kick` of already-LEFT user: 200 OK no-op.

### Rate limits

- `POST /voice/group-calls` (create): 5/minute per user.
- `POST /:id/mute-all`: 1/10s per call.

---

## 4. Lobby state machine and timeouts

### Lifecycle (server-side)

```
T=0    POST /voice/group-calls
       ├─ Insert GroupCall(LOBBY), GroupCallInvite(CALLING) × N
       ├─ Push (VoIP/FCM) to each invitee
       ├─ Socket.io group_call_invite to each invitee user-room
       ├─ Schedule Bull job: timeout-invite for each invite, delay=30s
       └─ Return livekitToken to host → host enters LiveKit room (alone)

T=5s   POST /:id/join (Bob)
       ├─ invite[Bob].status=JOINED
       ├─ call.status=LOBBY → ACTIVE
       └─ Broadcast group_call_status + group_call_joined

T=12s  POST /:id/decline (Charlie)
       ├─ invite[Charlie].status=DECLINED
       └─ Broadcast group_call_status

T=30s  Bull job: timeout-invite (Diana, Eve)
       ├─ Read invite from DB; if status != CALLING → no-op
       ├─ status=TIMEOUT, broadcast group_call_status
       └─ If no JOINED and call.status=LOBBY:
              call.status=ENDED(reason="timeout")
              Broadcast group_call_ended to host
              LiveKit: roomService.deleteRoom(livekitRoomName)

T=N    Last JOINED leaves
       ├─ invite[X].status=LEFT
       ├─ JOINED count == 0
       ├─ call.status=ENDED(reason="all_left")
       ├─ Broadcast group_call_ended to all
       └─ LiveKit: deleteRoom
```

### Bull queue choice

Use **BullMQ** (already common with NestJS, runs on existing Redis 7). Add `@nestjs/bullmq`.

- Queue: `group-call-timeouts`
- Job: `timeout-invite { inviteId }`, delay=30s
- Idempotent: on fire, read invite; if `status != CALLING`, no-op.
- Cancel-on-response is optional (idempotency makes cancel non-essential, but reduces noise — implement if cheap).

**Why not setTimeout in process memory:** PM2 restart loses pending timers → invitees stuck in CALLING forever. Bull queue persists in Redis → survives restarts.

### Cron cleanup (zombie protection)

`@Cron('*/5 * * * *')`:

- Find `GroupCall` where status=LOBBY and `startedAt < now() - 5min` → force ENDED(timeout).
- Find `GroupCall` where status=ACTIVE and zero JOINED for >1min → force ENDED(all_left).
- Find LiveKit rooms with prefix `group-` not in DB → delete.

Double protection layer; absorbs missed pushes, client crashes, etc.

### Host transfer on leave

```
host_user calls /leave
└─ TX:
   ├─ invite[host].status=LEFT
   ├─ Find next JOINED (joinedAt asc, excluding LEFT host)
   ├─ If found: call.hostUserId = newHost.userId; broadcast group_call_host_changed
   └─ If none: call.status=ENDED(all_left); broadcast group_call_ended
```

Use Prisma transaction with `SELECT ... FOR UPDATE` on GroupCall row to prevent races (two simultaneous leaves).

### LiveKit reconnect handling

- LiveKit SDK auto-reconnects (default 15s grace). Backend does NOT mark LEFT on transient network drop.
- LiveKit webhook `participant_left` (`reason: disconnect_timeout`) → backend marks invite LEFT.
- Backend listens via existing webhook endpoint (or new one if missing). New events to handle: `participant_joined`, `participant_left`. Filter by room name prefix `group-`.

### Timer summary

| Timer | Value | Purpose |
|-------|-------|---------|
| Invite ringing timeout | 30s | CALLING → TIMEOUT |
| LOBBY zombie cleanup | 5min | force ENDED if LOBBY too long |
| ACTIVE no-participants cleanup | 1min | force ENDED if no JOINED |
| LiveKit disconnect grace | 15s (LK default) | mark LEFT after webhook |
| `mute-all` rate limit | 10s | anti-spam |
| Create call rate limit | 5/min/user | anti-spam |

---

## 5. Mid-call host actions

### Mid-call invite

```
[Host: tap "👤+ Add"]
└─ Multi-select picker (existing JOINED + CALLING pre-excluded,
   selectable count capped at 8 - count(JOINED + CALLING))
   └─ POST /:id/invite { userIds: [...] }
      │
      ▼
   Backend:
   1. authz: req.user.id === call.hostUserId
   2. validate: count(JOINED) + count(CALLING) + len(userIds) <= 8, else 409
      (CALLING counts because pending rings still hold a slot)
   3. validate: skip userIds with existing JOINED or CALLING invite (no duplicate)
   4. for each: insert GroupCallInvite(CALLING, invitedBy=host.id),
      push (VoIP/FCM), Socket.io group_call_invite, schedule timeout
   5. broadcast group_call_status to room
```

UI: new row appears in lobby-block ("Ivan — calling…" with spinner). On JOINED, row migrates to main participant list.

### Kick

```
[Host: long-press participant]
└─ Sheet "Remove [name]?"
   └─ POST /:id/kick { userId }
      │
      ▼
   Backend:
   1. authz: hostUserId, target != host
   2. invite.status=LEFT, leftAt=now()
   3. Socket.io group_call_kicked → kicked user only
   4. LiveKit RoomService.removeParticipant(roomName, target.identity)
      ↑ Forces disconnect even if Socket.io is missed
   5. broadcast group_call_status to others
```

UI for kicked user: client receives `group_call_kicked`, closes active screen, shows toast "You were removed from the call". LiveKit connection dropped server-side.

### Mute-all (soft)

```
[Host: tap "🔇 Mute all"]
└─ Sheet "Ask everyone to mute?"
   └─ POST /:id/mute-all
      │
      ▼
   Backend:
   1. authz: hostUserId
   2. rate limit: 1/10s
   3. broadcast group_call_mute_request to all participants except host
```

Each client on receiving `group_call_mute_request`:
- If mic publishing → disable local mic track
- Toast: "Alice asked everyone to mute"
- User can unmute anytime (not enforced)

This is a **social signal**, not principal-of-authority. Matches peer-equal philosophy of Taler ID. If hard-mute is later required (corp tenants?), backend can call LiveKit `mutePublishedTrack` server-side — orthogonal change.

### Manual host transfer

**Not in Phase 1.** Host transfer happens only on host `/leave`. Manual `/transfer-host` deferred to Phase 2/3 (YAGNI).

### Permissions summary

| Action | Allowed |
|--------|---------|
| Create call | Any user (rate limited) |
| Accept invite | Invitee |
| Decline invite | Invitee |
| Mute self / leave | Any participant |
| Mid-call invite | Host only |
| Kick | Host only (cannot kick self) |
| Mute-all (soft) | Host only |
| Force-end call (`/end`) | Host only |
| Auto-receive host | First JOINED after host leaves (joinedAt asc) |

---

## 6. Mobile UI flow (Flutter)

### 6.1 Calls tab entry point

```
┌─────────────────────────────────────┐
│ Звонки                          [+] │
├─────────────────────────────────────┤
│  ▶ Активный звонок (если есть)      │
│    "Группа: Алиса, Боб, +2"  [⤴]    │
│                                     │
│  История                            │
│  • Алиса • вчера • 12:34 • 8 мин    │
│  • Группа (Боб, Чарли) • пн • 5 мин │
└─────────────────────────────────────┘
```

Tap [+] → choice screen "Звонок одному" / "Групповой звонок".

### 6.2 Multi-select picker

```
┌─────────────────────────────────────┐
│  ←  Выбрать участников   (3/7) [✓]  │
├─────────────────────────────────────┤
│  🔍  Поиск                          │
├─────────────────────────────────────┤
│  Выбрано:                           │
│  [Алиса×] [Боб×] [Чарли×]           │
│                                     │
│  Контакты                           │
│  ☑ Алиса Иванова                    │
│  ☑ Боб Петров                       │
│  ☑ Чарли Сидоров                    │
│  ☐ Дмитрий Козлов                   │
└─────────────────────────────────────┘
```

- Chips of selected on top + checkable list.
- Search by displayName.
- AppBar [✓] disabled when 0 selected; max 7 invitees + 1 host = 8.
- On tap: optimistic spinner, POST `/voice/group-calls`, on success push lobby route.

### 6.3 Lobby screen

```
┌─────────────────────────────────────┐
│        Группа • LOBBY               │
│                                     │
│        🎤 Mic ON                    │
│                                     │
│   Ты (host)                  ●●●    │ ← active speaker indicator
│   ┌──────┐ ┌──────┐ ┌──────┐        │
│   │Алиса │ │ Боб  │ │Чарли │        │
│   │ ☎️   │ │ ☎️   │ │ ☎️   │        │ ← ringing pulse
│   │звоним│ │звоним│ │звоним│        │
│   └──────┘ └──────┘ └──────┘        │
│                                     │
│   30 sec до таймаута                │ ← countdown
│                                     │
│   [🔇] [👤+] [⚙] [🔚 Отменить]      │
└─────────────────────────────────────┘
```

Invitee tile states:

- `CALLING` — ringing animation, label "звоним" + countdown
- `JOINED` — tile moves to main list (animated)
- `DECLINED` — gray ✕ overlay, label "отклонил"
- `TIMEOUT` — gray clock overlay, label "не ответил"

Subscribers: lobby BLoC listens to `group_call_status`, `group_call_joined`, `group_call_ended`. Any event → re-render.

Buttons:
- 🔇 Mic toggle
- 👤+ Add (mid-call invite)
- ⚙ Audio settings (speaker/earpiece)
- 🔚 Cancel — if LOBBY (no JOINED) → POST `/end`. If ACTIVE → POST `/leave`.

### 6.4 Active screen (≥2 participants)

```
┌─────────────────────────────────────┐
│        Группа • 02:34               │ ← timer from ACTIVE
│                                     │
│   Ты (host)                  ●●●    │
│   ┌──────┐ ┌──────┐                 │
│   │Алиса │ │ Боб  │                 │ ← active speaker = border glow
│   │      │ │  ●●● │                 │
│   └──────┘ └──────┘                 │
│                                     │
│   Звоним:                           │
│   ┌──────┐                          │
│   │Чарли │  ☎️ ringing              │ ← lobby block stays visible
│   └──────┘                          │
│                                     │
│   [🔇] [👤+] [🔇 Mute all] [🔚 Уйти] │
└─────────────────────────────────────┘
```

Layout: vertical wrap or sliver grid. Up to 4 → vertical column; 5-8 → 3×3 grid.

Active speaker: subscribe to LiveKit `Room.activeSpeakers` stream. Border glow + 3 pulse dots. Smooth 200ms transitions.

Long-press participant (host only):
- Sheet: "Remove [name] from call" → `/kick`

### 6.5 Invitee receives invite

```
[Bob's iPhone — VoIP push arrives]
└─ CallKit incoming UI:
   ┌──────────────────────────┐
   │   📞                     │
   │   Алиса Иванова          │
   │   Группа: + 4 ещё        │
   │                          │
   │   [Отклонить] [Принять]  │
   └──────────────────────────┘
       │           │
   /decline    /join
       │           │
       ▼           ▼
     close     GroupCallActiveScreen
```

- Accept → POST `/join` → receive livekitToken → connect → push active screen.
- Decline → POST `/decline` → close CallKit UI.
- Don't answer 30s → CallKit auto-closes (TTL); backend timeout job → TIMEOUT.

### 6.6 Active call banner / rejoin

If user:
- Was JOINED, then LEFT → banner shows on Calls tab "Активный звонок [⤴]"
- Never answered → banner shows
- Was DECLINED → banner shows (changed mind)
- Was KICKED → banner does NOT show

Banner condition: `GET /voice/group-calls/active` returns calls where currentUser invite ∈ {CALLING, JOINED, LEFT, DECLINED} AND call.status ∈ {LOBBY, ACTIVE}.

### 6.7 Isolation from 1-on-1 voice

- Existing `voice_call_screen.dart` untouched.
- Routing: new go_route `/group-call/:id` → `GroupCallActiveScreen`.
- New `GroupCallBloc`, no overlap with `VoiceCallBloc`.
- `CallStateService` (core) extended with `setActiveGroupCall(id)` to prevent dual-call conflicts.

---

## 7. Reuse vs. new code

### Reused without modification

| Component | Path | Use |
|-----------|------|-----|
| LiveKit RoomService / AccessToken | `src/voice/voice.service.ts` | Token gen, room create/delete, removeParticipant |
| MessengerGateway | `src/messenger/messenger.gateway.ts` | Socket.io broadcast |
| FcmPushService | `src/notifications/` | Android FCM |
| ApnsService (VoIP) | `src/notifications/` | iOS VoIP push |
| AuthGuard | `src/auth/guards/` | JWT |
| LiveKit infra | server | No new instances |
| Redis | server | Bull queue + optional cache |

### Minimally extended

**`VoiceService` — add helper:**

```ts
generateGroupCallToken(groupCallId: string, userId: string): { token, livekitWsUrl }
  // Wraps existing generateAccessToken("group-{groupCallId}", userId, ...)
  // Permissions: canPublish=true, canSubscribe=true
```

**LiveKit webhook handler:**
- Existing `POST /voice/livekit-webhook` (if exists for outbound bot or 1-on-1) — extend `participant_left` case → dispatch to `GroupCallService.handleParticipantLeft()` if room name prefix=`group-`.
- If webhook not yet configured on LiveKit server, configure `webhook.urls` in LiveKit config.

**`MessengerGateway`:**
- Add `emitToUser(userId, event, payload)` if missing. Otherwise use existing room-based emit.

**`CallKitService` (Flutter):**
- Existing VoIP push handler dispatches by `payload.type`. Add `case 'group_call_invite'` → new flow.
- `flutter_callkit_incoming` displays standard CallKit UI; caller name = host displayName, callId = groupCallId.

### New code (estimate)

| Layer | New LOC | Modified LOC | New files | Modified files |
|-------|---------|--------------|-----------|----------------|
| Backend NestJS | ~600 | ~50 | 8-10 | 3-4 |
| Prisma | ~80 | 0 | 0 | 1 (schema) |
| Mobile Flutter | ~1200 | ~100 | 12-15 | 3-4 |
| Tests | ~500 | 0 | 4-5 | 0 |
| **Total** | **~2400** | **~150** | **24-30** | **7-12** |

Realistic timeline: ~2 weeks solo dev + 2-3 days testing (two emulators, real-device VoIP push, edge cases).

### Refactors deliberately not done

- No unification of `VoiceCallBloc` and `GroupCallBloc` into a single state machine.
- No generic `Room` abstraction (Approach 3 from brainstorming) — defer to Phase 2 if breakouts confirm the need.
- No microservice split for LiveKit token generation.

---

## 8. Error handling, observability, deployment

### 8.1 Error handling table

| Scenario | Behavior |
|----------|----------|
| Push fail (FCM/APNs) | Retry once after 2s. If still fails: invite remains CALLING, 30s TIMEOUT will fire. Log to Sentry. Host UI is unaffected. |
| LiveKit unavailable on `POST /create` | 503; transaction rollback (no orphan GroupCall). Mobile shows "Не удалось создать звонок". |
| LiveKit drops during ACTIVE | SDK reconnect 15s. If unrecovered, client closes screen "Соединение потеряно". Webhook → backend marks invite LEFT. |
| Bull queue not processed (Redis down) | Cron cleanup (5min) catches zombies. Double protection. |
| Race: host + last JOINED leave simultaneously | Prisma TX with `SELECT ... FOR UPDATE` on GroupCall. Second request reads ENDED → 200 OK. |
| Invitee app backgrounded then foregrounded | `GET /active` → if call still ACTIVE and invite not (LEFT, DECLINED, KICKED) → show banner. |
| Mobile crash during ACTIVE | LiveKit detects disconnect → webhook → backend marks LEFT after 15s grace. App restart: `/active` → banner. |
| Host attempts to kick self | 400 "cannot kick host". |
| Mid-call invite when room full | 409. Mobile toast "Комната заполнена". |
| Accept after `call_ended` | 410 Gone. CallKit UI closes. Mobile toast "Звонок уже завершён". |
| 2FA / blocked user creates call | 403 (standard AuthGuard). |

### 8.2 Concurrency & idempotency

- `livekitRoomName` `@@unique` prevents collisions.
- `/join` returns same token if already JOINED.
- `/leave` returns 200 if already LEFT.
- `/kick` uses Prisma TX for atomic check+update+broadcast; no-op if already LEFT.
- Host transfer in same TX as host's leave.

### 8.3 Logging & observability

Structured logs (Pino):

```json
{ "event": "group_call_created", "groupCallId": "...", "hostId": "...", "inviteeCount": 5 }
{ "event": "group_call_invite_responded", "groupCallId": "...", "userId": "...", "status": "JOINED", "latencyMs": 2300 }
{ "event": "group_call_ended", "groupCallId": "...", "reason": "all_left", "durationSec": 245 }
```

Sentry for errors (push fail, LiveKit fail, transaction conflict).

Optional metrics for Phase 2:
- Counter: `group_call_created_total`
- Histogram: `group_call_invite_response_latency_ms`
- Histogram: `group_call_duration_sec`
- Gauge: `group_call_active_count`

### 8.4 Testing strategy

**Backend unit (`group-call.service.spec.ts`):**

- create with N invitees → DB rows + push calls = N
- join → status transition LOBBY→ACTIVE
- decline last → call ENDED(timeout)
- leave host → host transferred to next JOINED (joinedAt asc)
- leave last JOINED → call ENDED(all_left)
- kick by non-host → 403
- kick already-LEFT → 200 no-op
- mid-call invite at capacity → 409
- timeout job idempotent (no-op if status != CALLING)

**Mobile unit (`group_call_bloc_test.dart`):**

- BLoC transitions: idle → creating → inLobby → active → ended
- group_call_status event → list re-render
- group_call_kicked event → exit + toast
- network error during create → return to picker

**Backend integration (`group-call.e2e-spec.ts`):**

- 3 fake JWT users → create with 2 invitees → fake socket clients → join, leave → assert DB + broadcast events.

**Mobile manual integration test (extends `integration_test/app_test.dart`):**

- Emulator A creates group call with 1 contact → emulator B receives push, accepts → both reach lobby/active → A leaves → both see ENDED.

**Real-device test:**

- iPhone host + 2 Android invitees → create → CallKit on iPhone, FCM banner on Androids → join → bidirectional audio → leave one by one → ENDED reached.

**Smoke for DEV (extends `~/Downloads/taler_id_tests/`):**

- `npm run test:group-calls` — Node script with 3 fake JWTs creates group call via REST + Socket.io, asserts state-flow without LiveKit.

### 8.5 Deployment

1. **Prisma migration** `20260429_add_group_calls.sql`: `prisma migrate deploy` on DEV → smoke → DEV approval → PROD.
2. **Backend deploy**: adds endpoints + Bull queue worker. Existing 1-on-1 unaffected.
3. **LiveKit webhook**: configure if not already.
4. **Mobile**: feature flag `AppConfig.groupCallsEnabled`. Default `true` on dev flavor; `false` on prod until QA, then `true`.

### 8.6 Rollback

If a critical bug appears post-deploy:
- Backend: PM2 rollback to previous release; new endpoints return 404, mobile UI gracefully shows "Group calls temporarily unavailable" (catch in BLoC).
- DB: migrations are additive (new tables only); no rollback needed for schema.
- Mobile: flip feature flag off via env update + restart.

---

## 9. Open implementation questions

These don't block design; resolved during implementation planning:

1. **LiveKit webhook config** — verify `POST /voice/livekit-webhook` exists. If not, configure `webhook.urls` in LiveKit + add controller.
2. **`MessengerGateway.emitToUser(userId, event, payload)`** — verify method exists. Add if missing.
3. **`CallStateService` singleton for active call** — review how 1-on-1 handles conflicting incoming invites; adapt for group.
4. **Active speaker LiveKit threshold** — default `-50dB`. Tune if noisy.
5. **Bull queue setup** — check if `@nestjs/bullmq` already in dependencies (might be there for outbound bot or outboundCalls). Reuse Redis connection.

---

## 10. Non-goals (Phase 1)

Explicitly out of scope; covered by future-phase specs:

- ❌ Video and screen share — Phase 3
- ❌ Recording and transcription — Phase 5
- ❌ AI participant in call — Phase 5
- ❌ Guest access via link — Phase 4
- ❌ Breakout sub-rooms with knock-to-join — Phase 2
- ❌ Scheduled calls (Calendar tab integration) — Phase 6+
- ❌ Missed-call notifications feed — can be added later as simple feature
- ❌ Server-side hard mute — staying with soft-mute social signal
- ❌ Manual host transfer — only auto on leave
- ❌ Tenant-level moderation roles — Phase 6+
- ❌ Post-call quality rating — Phase X
- ❌ Full-text search of group call history — pagination only

---

## 11. Phase 2-5 placeholder summary

This Phase 1 spec is intentionally bounded. The four future phases will get their own specs:

| Phase | Estimated effort | Depends on | Killer detail |
|-------|------------------|-----------|---------------|
| 2 — Breakout w/ knock-to-join | 2-3 weeks | Phase 1 | Visible side-rooms; anyone can initiate; consent-based join; SpatialChat-style |
| 3 — Video + screen share | 2 weeks | Phase 1 | Grid/speaker view; track type added |
| 4 — Guest access via link | 1-2 weeks | Phase 1 | Guest tokens, waiting room, host approval |
| 5 — Recording + AI protocol | 2 weeks | Phase 3 | Reuses outbound-bot recorder + ai-twin transcription stack |

---

## Approval

Design approved by Dmitry on 2026-04-29 (section-by-section).

Implementation plan to be authored next via `superpowers:writing-plans` skill.

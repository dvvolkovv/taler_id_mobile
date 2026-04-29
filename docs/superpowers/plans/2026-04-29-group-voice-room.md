# Group Voice Room (Phase 1) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Multi-party voice room (3-8 Taler ID users) initiated ad-hoc from contacts, with lobby/active states, light host privileges (mid-call invite, kick, soft mute-all), and CallKit/VoIP-push parity with the existing 1-on-1 flow.

**Architecture:** New self-contained `GroupCall` module on backend (`src/voice/group-call/`) with two new Prisma models (`GroupCall`, `GroupCallInvite`). REST endpoints under `/voice/group-calls`, Socket.io events on the existing `/messenger` namespace, BullMQ-based 30s ringing timeout, LiveKit webhook-driven participant tracking, cron-cleanup safety net. Mobile gets a new `GroupCallBloc` and three new screens (picker / lobby / active). The existing 1-on-1 `voice_call_screen.dart` flow is **not** modified.

**Tech Stack:** NestJS + Prisma 5 + PostgreSQL + Redis + BullMQ + Socket.io + LiveKit Server SDK on the backend; Flutter 3.6+ + flutter_bloc + Freezed + go_router + livekit_client + flutter_callkit_incoming on mobile.

**Spec:** [`docs/superpowers/specs/2026-04-29-group-voice-room-design.md`](../specs/2026-04-29-group-voice-room-design.md)

**Local repo paths assumed:**
- Mobile: `/Users/dmitry/Downloads/taler_id_mobile` (branch `dev`)
- Backend: `~/taler-id` (clone locally if not present; deploys via SSH to `dvolkov@89.169.55.217`)
- Smoke tests: `~/Downloads/taler_id_tests`

---

## File Structure

### Backend (`~/taler-id/`)

| Path | Action | Responsibility |
|------|--------|----------------|
| `prisma/schema.prisma` | modify | Add `GroupCall`, `GroupCallInvite`, two enums, User relations |
| `prisma/migrations/<ts>_add_group_calls/migration.sql` | create | Generated Prisma migration |
| `src/voice/group-call/group-call.module.ts` | create | NestJS module wiring |
| `src/voice/group-call/group-call.controller.ts` | create | 8 REST endpoints |
| `src/voice/group-call/group-call.service.ts` | create | Business logic (state machine, broadcast helpers) |
| `src/voice/group-call/group-call.gateway.ts` | create | Thin wrapper over MessengerGateway for `group_call_*` events |
| `src/voice/group-call/dto/create-group-call.dto.ts` | create | `{ inviteeIds: string[] }` |
| `src/voice/group-call/dto/invite-users.dto.ts` | create | `{ userIds: string[] }` |
| `src/voice/group-call/dto/kick-user.dto.ts` | create | `{ userId: string }` |
| `src/voice/group-call/guards/group-call-host.guard.ts` | create | Host-only authz |
| `src/voice/group-call/jobs/timeout.processor.ts` | create | BullMQ worker for invite ringing timeout |
| `src/voice/group-call/jobs/cleanup.cron.ts` | create | Cron `*/5 * * * *` for zombie cleanup |
| `src/voice/group-call/group-call.service.spec.ts` | create | Unit tests |
| `test/group-call.e2e-spec.ts` | create | End-to-end test |
| `src/voice/voice.service.ts` | modify | Add `generateGroupCallToken()` helper |
| `src/voice/voice.controller.ts` | modify | Extend LiveKit webhook for `participant_left` on `group-*` rooms |
| `src/voice/voice.module.ts` | modify | Import `GroupCallModule` |
| `src/messenger/messenger.gateway.ts` | modify | Add `emitToUser()` if missing; new event names are emitted directly |
| `src/notifications/voip-push.service.ts` (or equivalent) | modify | Build `group_call_invite` payload variant |
| `src/app.module.ts` | modify | Register BullMQ queue `group-call-timeouts`, ScheduleModule for cron |

### Mobile (`/Users/dmitry/Downloads/taler_id_mobile/`)

| Path | Action | Responsibility |
|------|--------|----------------|
| `lib/features/voice/data/models/group_call_dto.dart` | create | Freezed DTOs for API responses |
| `lib/features/voice/domain/entities/group_call.dart` | create | Domain entity |
| `lib/features/voice/domain/entities/group_call_invite.dart` | create | Domain entity |
| `lib/features/voice/domain/repositories/group_call_repository.dart` | create | Abstract interface |
| `lib/features/voice/data/datasources/group_call_remote_datasource.dart` | create | Dio HTTP client |
| `lib/features/voice/data/repositories/group_call_repository_impl.dart` | create | Repo implementation |
| `lib/features/voice/presentation/bloc/group_call_event.dart` | create | BLoC events (Freezed sealed) |
| `lib/features/voice/presentation/bloc/group_call_state.dart` | create | BLoC states (Freezed sealed) |
| `lib/features/voice/presentation/bloc/group_call_bloc.dart` | create | State machine + Socket.io subscription |
| `lib/features/voice/presentation/widgets/participant_tile.dart` | create | Avatar + status overlay |
| `lib/features/voice/presentation/widgets/active_speaker_indicator.dart` | create | Pulsing dots + border glow |
| `lib/features/voice/presentation/widgets/host_actions_sheet.dart` | create | Long-press kick / mute-all sheet |
| `lib/features/voice/presentation/screens/new_group_call_screen.dart` | create | Multi-select contacts picker |
| `lib/features/voice/presentation/screens/group_call_lobby_screen.dart` | create | Lobby with countdown + status tiles |
| `lib/features/voice/presentation/screens/group_call_active_screen.dart` | create | Active call grid + controls |
| `lib/features/voice/presentation/widgets/active_group_call_banner.dart` | create | "Resume call" banner on Calls tab |
| `lib/core/router/app_router.dart` | modify | Add `/group-call/:id` route, `/new-group-call` route |
| `lib/core/services/call_state_service.dart` | modify | Track active group call ID alongside 1-on-1 |
| `lib/core/notifications/voip_handler.dart` | modify | Dispatch on `payload.type == 'group_call_invite'` |
| `lib/core/notifications/fcm_handler.dart` | modify | Same dispatch logic for Android |
| `lib/core/di/service_locator.dart` | modify | Register `GroupCallRepository`, datasource, BLoC |
| `lib/features/voice/presentation/screens/calls_screen.dart` | modify | Show `ActiveGroupCallBanner` + "+" entry point |
| `lib/l10n/app_ru.arb` | modify | Russian strings (~25 keys) |
| `lib/l10n/app_en.arb` | modify | English strings (~25 keys) |
| `test/features/voice/presentation/bloc/group_call_bloc_test.dart` | create | BLoC unit tests |
| `integration_test/app_test.dart` | modify | Add group call smoke step (single-emulator) |

### Smoke tests (`~/Downloads/taler_id_tests/`)

| Path | Action | Responsibility |
|------|--------|----------------|
| `test/group-calls.test.js` | create | Node script: 3 fake JWTs → REST + Socket.io state-flow |
| `package.json` | modify | Add `test:group-calls` and `test:group-calls:prod` scripts |

---

## Execution Order

The plan groups tasks into four logical phases. Execute sequentially — each task assumes earlier tasks are merged.

- **Phase A — Backend (Tasks 1-15):** schema → service → REST → Bull/cron → webhook → push → tests
- **Phase B — Mobile data + BLoC (Tasks 16-22):** DTOs → entities → repo → BLoC
- **Phase C — Mobile UI (Tasks 23-30):** screens → widgets → routing → DI → l10n
- **Phase D — QA & Deploy (Tasks 31-36):** unit tests → integration → DEV deploy → real-device → PROD checklist

---

## Phase A — Backend

### Task 1: Prisma schema + migration

**Files:**
- Modify: `prisma/schema.prisma`
- Create: `prisma/migrations/<timestamp>_add_group_calls/migration.sql` (generated)

- [ ] **Step 1: Add enums and models to `prisma/schema.prisma`**

Append to `prisma/schema.prisma` (above `model User` if enums must come first; otherwise at file end):

```prisma
enum GroupCallStatus {
  LOBBY
  ACTIVE
  ENDED
}

enum GroupCallInviteStatus {
  CALLING
  JOINED
  DECLINED
  TIMEOUT
  LEFT
}

model GroupCall {
  id              String           @id @default(uuid())
  livekitRoomName String           @unique
  hostUserId      String
  status          GroupCallStatus  @default(LOBBY)
  startedAt       DateTime         @default(now())
  endedAt         DateTime?
  endedReason     String?

  host            User             @relation("HostedGroupCalls", fields: [hostUserId], references: [id])
  invites         GroupCallInvite[]

  @@index([status, startedAt])
  @@index([hostUserId, startedAt])
}

model GroupCallInvite {
  id          String                @id @default(uuid())
  groupCallId String
  userId      String
  status      GroupCallInviteStatus @default(CALLING)
  invitedAt   DateTime              @default(now())
  respondedAt DateTime?
  joinedAt    DateTime?
  leftAt      DateTime?
  invitedBy   String

  groupCall   GroupCall             @relation(fields: [groupCallId], references: [id], onDelete: Cascade)
  user        User                  @relation("GroupCallInvitesReceived", fields: [userId], references: [id])

  @@unique([groupCallId, userId])
  @@index([userId, status])
}
```

- [ ] **Step 2: Add User relations**

Find `model User { ... }` and append within the model body:

```prisma
  hostedGroupCalls GroupCall[]       @relation("HostedGroupCalls")
  groupCallInvites GroupCallInvite[] @relation("GroupCallInvitesReceived")
```

- [ ] **Step 3: Generate migration locally**

Run: `npx prisma migrate dev --name add_group_calls --create-only`

Expected: file `prisma/migrations/<timestamp>_add_group_calls/migration.sql` is created. Inspect it: should contain `CREATE TYPE "GroupCallStatus"`, `CREATE TABLE "GroupCall"`, `CREATE TABLE "GroupCallInvite"`, foreign keys, and indexes. **Do not apply yet** — applied during Task 33 (deploy).

- [ ] **Step 4: Run `prisma generate` to refresh types**

Run: `npx prisma generate`

Expected: TypeScript types for `GroupCall`, `GroupCallInvite` available from `@prisma/client`.

- [ ] **Step 5: Verify project still builds**

Run: `npm run build`

Expected: `0 errors`. New types are not used yet, but generation must succeed.

- [ ] **Step 6: Commit**

```bash
git add prisma/schema.prisma prisma/migrations/<timestamp>_add_group_calls
git commit -m "feat(group-call): prisma schema for GroupCall + GroupCallInvite"
```

---

### Task 2: Module scaffold + DTOs

**Files:**
- Create: `src/voice/group-call/group-call.module.ts`
- Create: `src/voice/group-call/dto/create-group-call.dto.ts`
- Create: `src/voice/group-call/dto/invite-users.dto.ts`
- Create: `src/voice/group-call/dto/kick-user.dto.ts`
- Modify: `src/voice/voice.module.ts`

- [ ] **Step 1: Create `create-group-call.dto.ts`**

```typescript
import { ArrayMaxSize, ArrayMinSize, IsArray, IsUUID } from 'class-validator';

export class CreateGroupCallDto {
  @IsArray()
  @ArrayMinSize(1)
  @ArrayMaxSize(7)
  @IsUUID('4', { each: true })
  inviteeIds!: string[];
}
```

- [ ] **Step 2: Create `invite-users.dto.ts`**

```typescript
import { ArrayMaxSize, ArrayMinSize, IsArray, IsUUID } from 'class-validator';

export class InviteUsersDto {
  @IsArray()
  @ArrayMinSize(1)
  @ArrayMaxSize(7)
  @IsUUID('4', { each: true })
  userIds!: string[];
}
```

- [ ] **Step 3: Create `kick-user.dto.ts`**

```typescript
import { IsUUID } from 'class-validator';

export class KickUserDto {
  @IsUUID('4')
  userId!: string;
}
```

- [ ] **Step 4: Create stub `group-call.module.ts`**

```typescript
import { Module } from '@nestjs/common';

@Module({
  imports: [],
  providers: [],
  controllers: [],
  exports: [],
})
export class GroupCallModule {}
```

- [ ] **Step 5: Wire into `voice.module.ts`**

Modify `src/voice/voice.module.ts`. In the `imports` array add `GroupCallModule`:

```typescript
import { GroupCallModule } from './group-call/group-call.module';

@Module({
  imports: [
    /* existing… */,
    GroupCallModule,
  ],
  /* … */
})
export class VoiceModule {}
```

- [ ] **Step 6: Run build to confirm wiring**

Run: `npm run build`

Expected: `0 errors`.

- [ ] **Step 7: Commit**

```bash
git add src/voice/group-call src/voice/voice.module.ts
git commit -m "feat(group-call): module scaffold + DTOs"
```

---

### Task 3: VoiceService — `generateGroupCallToken()`

**Files:**
- Modify: `src/voice/voice.service.ts`
- Test: `src/voice/voice.service.spec.ts` (extend existing or create if missing)

- [ ] **Step 1: Write failing test in `voice.service.spec.ts`**

Append to existing test file (or create one matching project convention):

```typescript
describe('generateGroupCallToken', () => {
  it('returns LiveKit token + ws url for given groupCallId/userId', () => {
    const result = service.generateGroupCallToken('gc-123', 'user-456');
    expect(result.token).toBeTruthy();
    expect(result.token.split('.').length).toBe(3); // JWT
    expect(result.livekitWsUrl).toBe(process.env.LIVEKIT_WS_URL);
    // Decode JWT payload, room field should be "group-gc-123"
    const payload = JSON.parse(Buffer.from(result.token.split('.')[1], 'base64').toString());
    expect(payload.video.room).toBe('group-gc-123');
    expect(payload.sub).toBe('user-456');
    expect(payload.video.canPublish).toBe(true);
    expect(payload.video.canSubscribe).toBe(true);
  });
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `npm test -- voice.service.spec.ts`

Expected: FAIL with "service.generateGroupCallToken is not a function".

- [ ] **Step 3: Implement `generateGroupCallToken` in `voice.service.ts`**

Add method to the `VoiceService` class:

```typescript
generateGroupCallToken(groupCallId: string, userId: string): { token: string; livekitWsUrl: string } {
  const roomName = `group-${groupCallId}`;
  const at = new AccessToken(
    this.config.get<string>('LIVEKIT_API_KEY'),
    this.config.get<string>('LIVEKIT_API_SECRET'),
    { identity: userId, ttl: 60 * 60 * 4 }, // 4 hours
  );
  at.addGrant({
    room: roomName,
    roomJoin: true,
    canPublish: true,
    canSubscribe: true,
    canPublishData: true,
  });
  return {
    token: at.toJwt(),
    livekitWsUrl: this.config.get<string>('LIVEKIT_WS_URL')!,
  };
}
```

(If `AccessToken` import or pattern differs, mirror whatever `generateAccessToken` already uses.)

- [ ] **Step 4: Run test to verify pass**

Run: `npm test -- voice.service.spec.ts`

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add src/voice/voice.service.ts src/voice/voice.service.spec.ts
git commit -m "feat(group-call): VoiceService.generateGroupCallToken"
```

---

### Task 4: GroupCallService — `createCall`

**Files:**
- Create: `src/voice/group-call/group-call.service.ts`
- Create: `src/voice/group-call/group-call.service.spec.ts`
- Modify: `src/voice/group-call/group-call.module.ts`

- [ ] **Step 1: Write failing test**

`src/voice/group-call/group-call.service.spec.ts`:

```typescript
import { Test } from '@nestjs/testing';
import { GroupCallService } from './group-call.service';
import { PrismaService } from '../../prisma/prisma.service';
import { VoiceService } from '../voice.service';
import { GroupCallGateway } from './group-call.gateway';
import { getQueueToken } from '@nestjs/bullmq';
import { VoipPushService } from '../../notifications/voip-push.service';
import { FcmPushService } from '../../notifications/fcm-push.service';

describe('GroupCallService', () => {
  let service: GroupCallService;
  let prisma: any;
  let voice: any;
  let gateway: any;
  let queue: any;
  let voip: any;
  let fcm: any;

  beforeEach(async () => {
    prisma = {
      groupCall: { create: jest.fn(), findUnique: jest.fn(), update: jest.fn() },
      groupCallInvite: { createMany: jest.fn(), findMany: jest.fn() },
      $transaction: jest.fn((cb) => cb(prisma)),
    };
    voice = { generateGroupCallToken: jest.fn().mockReturnValue({ token: 'jwt', livekitWsUrl: 'ws://lk' }) };
    gateway = { emitInvite: jest.fn(), emitStatus: jest.fn() };
    queue = { add: jest.fn() };
    voip = { sendGroupCallInvite: jest.fn() };
    fcm = { sendGroupCallInvite: jest.fn() };

    const moduleRef = await Test.createTestingModule({
      providers: [
        GroupCallService,
        { provide: PrismaService, useValue: prisma },
        { provide: VoiceService, useValue: voice },
        { provide: GroupCallGateway, useValue: gateway },
        { provide: getQueueToken('group-call-timeouts'), useValue: queue },
        { provide: VoipPushService, useValue: voip },
        { provide: FcmPushService, useValue: fcm },
      ],
    }).compile();
    service = moduleRef.get(GroupCallService);
  });

  describe('createCall', () => {
    it('creates GroupCall + invites, schedules timeouts, sends push, returns token', async () => {
      const fakeCall = { id: 'gc-1', livekitRoomName: 'group-gc-1', hostUserId: 'host', status: 'LOBBY' };
      prisma.groupCall.create.mockResolvedValue(fakeCall);
      prisma.groupCallInvite.createMany.mockResolvedValue({ count: 2 });
      prisma.groupCallInvite.findMany.mockResolvedValue([
        { id: 'i1', userId: 'u1', status: 'CALLING' },
        { id: 'i2', userId: 'u2', status: 'CALLING' },
      ]);

      const result = await service.createCall('host', ['u1', 'u2']);

      expect(prisma.groupCall.create).toHaveBeenCalled();
      expect(prisma.groupCallInvite.createMany).toHaveBeenCalledWith({
        data: [
          { groupCallId: 'gc-1', userId: 'u1', invitedBy: 'host', status: 'CALLING' },
          { groupCallId: 'gc-1', userId: 'u2', invitedBy: 'host', status: 'CALLING' },
        ],
      });
      expect(queue.add).toHaveBeenCalledTimes(2);
      expect(voip.sendGroupCallInvite).toHaveBeenCalledTimes(2);
      expect(gateway.emitInvite).toHaveBeenCalledTimes(2);
      expect(result.livekitToken).toBe('jwt');
    });

    it('rejects empty invitee list', async () => {
      await expect(service.createCall('host', [])).rejects.toThrow();
    });

    it('rejects > 7 invitees (would exceed 8 cap with host)', async () => {
      await expect(service.createCall('host', ['u1','u2','u3','u4','u5','u6','u7','u8'])).rejects.toThrow();
    });

    it('rejects host self-invite', async () => {
      await expect(service.createCall('host', ['host', 'u1'])).rejects.toThrow();
    });
  });
});
```

- [ ] **Step 2: Run test to verify fail**

Run: `npm test -- group-call.service.spec.ts`

Expected: FAIL — `GroupCallService` does not exist.

- [ ] **Step 3: Create `group-call.service.ts` with `createCall` method**

```typescript
import { Injectable, BadRequestException, Logger } from '@nestjs/common';
import { InjectQueue } from '@nestjs/bullmq';
import { Queue } from 'bullmq';
import { PrismaService } from '../../prisma/prisma.service';
import { VoiceService } from '../voice.service';
import { GroupCallGateway } from './group-call.gateway';
import { VoipPushService } from '../../notifications/voip-push.service';
import { FcmPushService } from '../../notifications/fcm-push.service';
import { GroupCallStatus, GroupCallInviteStatus } from '@prisma/client';

const MAX_PARTICIPANTS = 8;
const RING_TIMEOUT_SEC = 30;

@Injectable()
export class GroupCallService {
  private readonly logger = new Logger(GroupCallService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly voice: VoiceService,
    private readonly gateway: GroupCallGateway,
    @InjectQueue('group-call-timeouts') private readonly queue: Queue,
    private readonly voip: VoipPushService,
    private readonly fcm: FcmPushService,
  ) {}

  async createCall(hostUserId: string, inviteeIds: string[]) {
    if (inviteeIds.length === 0) throw new BadRequestException('inviteeIds is empty');
    if (inviteeIds.length > MAX_PARTICIPANTS - 1) {
      throw new BadRequestException(`Cannot invite more than ${MAX_PARTICIPANTS - 1}`);
    }
    if (inviteeIds.includes(hostUserId)) throw new BadRequestException('host cannot self-invite');
    const dedup = Array.from(new Set(inviteeIds));

    const call = await this.prisma.$transaction(async (tx) => {
      const created = await tx.groupCall.create({
        data: {
          hostUserId,
          status: GroupCallStatus.LOBBY,
          livekitRoomName: '', // set below from id
        },
      });
      const livekitRoomName = `group-${created.id}`;
      const updated = await tx.groupCall.update({
        where: { id: created.id },
        data: { livekitRoomName },
      });
      await tx.groupCallInvite.createMany({
        data: dedup.map((uid) => ({
          groupCallId: created.id,
          userId: uid,
          invitedBy: hostUserId,
          status: GroupCallInviteStatus.CALLING,
        })),
      });
      return updated;
    });

    const invites = await this.prisma.groupCallInvite.findMany({
      where: { groupCallId: call.id },
      include: { user: true },
    });

    // Schedule timeouts
    for (const inv of invites) {
      await this.queue.add(
        'timeout-invite',
        { inviteId: inv.id },
        { delay: RING_TIMEOUT_SEC * 1000, jobId: `timeout-${inv.id}` },
      );
    }

    // Send push + Socket.io
    const host = await this.prisma.user.findUnique({ where: { id: hostUserId } });
    for (const inv of invites) {
      this.voip.sendGroupCallInvite(inv.userId, {
        groupCallId: call.id,
        host,
        inviteeCount: invites.length,
        livekitRoomName: call.livekitRoomName,
      }).catch((e) => this.logger.warn(`VoIP push failed for ${inv.userId}: ${e.message}`));
      this.fcm.sendGroupCallInvite(inv.userId, {
        groupCallId: call.id,
        host,
        inviteeCount: invites.length,
      }).catch((e) => this.logger.warn(`FCM push failed for ${inv.userId}: ${e.message}`));
      this.gateway.emitInvite(inv.userId, { groupCallId: call.id, host, invitees: invites });
    }

    const { token, livekitWsUrl } = this.voice.generateGroupCallToken(call.id, hostUserId);
    return {
      groupCall: { ...call, invites },
      livekitToken: token,
      livekitWsUrl,
    };
  }
}
```

- [ ] **Step 4: Register provider in `group-call.module.ts`**

```typescript
import { Module } from '@nestjs/common';
import { BullModule } from '@nestjs/bullmq';
import { GroupCallService } from './group-call.service';
import { GroupCallGateway } from './group-call.gateway';
import { PrismaModule } from '../../prisma/prisma.module';
import { VoiceModule } from '../voice.module';
import { NotificationsModule } from '../../notifications/notifications.module';

@Module({
  imports: [
    PrismaModule,
    NotificationsModule,
    BullModule.registerQueue({ name: 'group-call-timeouts' }),
  ],
  providers: [GroupCallService, GroupCallGateway],
  exports: [GroupCallService],
})
export class GroupCallModule {}
```

(Note: avoid circular import with VoiceModule by injecting `VoiceService` via forwardRef if needed. Pattern: `forwardRef(() => VoiceModule)` + `@Inject(forwardRef(() => VoiceService))`.)

- [ ] **Step 5: Create stub `group-call.gateway.ts`** (full impl in Task 13)

```typescript
import { Injectable } from '@nestjs/common';
import { MessengerGateway } from '../../messenger/messenger.gateway';

@Injectable()
export class GroupCallGateway {
  constructor(private readonly messenger: MessengerGateway) {}

  emitInvite(userId: string, payload: any) {
    this.messenger.emitToUser(userId, 'group_call_invite', payload);
  }

  emitStatus(participantUserIds: string[], payload: any) {
    for (const uid of participantUserIds) {
      this.messenger.emitToUser(uid, 'group_call_status', payload);
    }
  }
}
```

- [ ] **Step 6: Run test to verify pass**

Run: `npm test -- group-call.service.spec.ts`

Expected: PASS for all 4 cases.

- [ ] **Step 7: Commit**

```bash
git add src/voice/group-call/
git commit -m "feat(group-call): service.createCall + LOBBY state"
```

---

### Task 5: GroupCallService — `getActiveCallsForUser`, `getCall`

**Files:**
- Modify: `src/voice/group-call/group-call.service.ts`
- Modify: `src/voice/group-call/group-call.service.spec.ts`

- [ ] **Step 1: Write failing tests**

Append to `group-call.service.spec.ts`:

```typescript
describe('getActiveCallsForUser', () => {
  it('returns calls where user has CALLING/JOINED/LEFT/DECLINED invite and call is LOBBY/ACTIVE', async () => {
    const calls = [{ id: 'c1', status: 'ACTIVE', invites: [{ userId: 'u1', status: 'JOINED' }] }];
    prisma.groupCall = { ...prisma.groupCall, findMany: jest.fn().mockResolvedValue(calls) };
    const result = await service.getActiveCallsForUser('u1');
    expect(prisma.groupCall.findMany).toHaveBeenCalledWith(expect.objectContaining({
      where: expect.objectContaining({
        status: { in: ['LOBBY', 'ACTIVE'] },
        invites: { some: { userId: 'u1', status: { in: ['CALLING', 'JOINED', 'LEFT', 'DECLINED'] } } },
      }),
    }));
    expect(result).toEqual(calls);
  });
});

describe('getCall', () => {
  it('throws NotFound if call missing', async () => {
    prisma.groupCall.findUnique = jest.fn().mockResolvedValue(null);
    await expect(service.getCall('xxx', 'u1')).rejects.toThrow();
  });

  it('throws Forbidden if user has no invite for the call', async () => {
    prisma.groupCall.findUnique = jest.fn().mockResolvedValue({ id: 'c1', invites: [{ userId: 'u2' }] });
    await expect(service.getCall('c1', 'u1')).rejects.toThrow();
  });

  it('returns call if user has invite', async () => {
    const call = { id: 'c1', invites: [{ userId: 'u1' }] };
    prisma.groupCall.findUnique = jest.fn().mockResolvedValue(call);
    expect(await service.getCall('c1', 'u1')).toEqual(call);
  });
});
```

- [ ] **Step 2: Run tests, verify fail**

Run: `npm test -- group-call.service.spec.ts`

Expected: 3 FAILs (methods do not exist).

- [ ] **Step 3: Implement methods**

Append to `GroupCallService`:

```typescript
async getActiveCallsForUser(userId: string) {
  return this.prisma.groupCall.findMany({
    where: {
      status: { in: [GroupCallStatus.LOBBY, GroupCallStatus.ACTIVE] },
      invites: {
        some: {
          userId,
          status: {
            in: [
              GroupCallInviteStatus.CALLING,
              GroupCallInviteStatus.JOINED,
              GroupCallInviteStatus.LEFT,
              GroupCallInviteStatus.DECLINED,
            ],
          },
        },
      },
    },
    include: {
      host: { select: { id: true, displayName: true, avatarUrl: true } },
      invites: { include: { user: { select: { id: true, displayName: true, avatarUrl: true } } } },
    },
    orderBy: { startedAt: 'desc' },
  });
}

async getCall(callId: string, userId: string) {
  const call = await this.prisma.groupCall.findUnique({
    where: { id: callId },
    include: {
      host: { select: { id: true, displayName: true, avatarUrl: true } },
      invites: { include: { user: { select: { id: true, displayName: true, avatarUrl: true } } } },
    },
  });
  if (!call) throw new NotFoundException('GroupCall not found');
  const isHost = call.hostUserId === userId;
  const hasInvite = call.invites.some((i) => i.userId === userId);
  if (!isHost && !hasInvite) throw new ForbiddenException('No access to this call');
  return call;
}
```

(Add imports: `NotFoundException`, `ForbiddenException` from `@nestjs/common`.)

- [ ] **Step 4: Run tests, verify pass**

Run: `npm test -- group-call.service.spec.ts`

Expected: ALL PASS.

- [ ] **Step 5: Commit**

```bash
git add src/voice/group-call/group-call.service.ts src/voice/group-call/group-call.service.spec.ts
git commit -m "feat(group-call): getActiveCallsForUser + getCall"
```

---

### Task 6: GroupCallService — `joinCall`

**Files:**
- Modify: `src/voice/group-call/group-call.service.ts`
- Modify: `src/voice/group-call/group-call.service.spec.ts`

- [ ] **Step 1: Write failing tests**

Append to spec:

```typescript
describe('joinCall', () => {
  it('transitions invite CALLING→JOINED and call LOBBY→ACTIVE on first join', async () => {
    const call = {
      id: 'c1', status: 'LOBBY', livekitRoomName: 'group-c1', hostUserId: 'host',
      invites: [{ id: 'i1', userId: 'u1', status: 'CALLING' }],
    };
    prisma.groupCall.findUnique = jest.fn().mockResolvedValue(call);
    prisma.groupCallInvite.update = jest.fn().mockResolvedValue({ ...call.invites[0], status: 'JOINED' });
    prisma.groupCall.update = jest.fn().mockResolvedValue({ ...call, status: 'ACTIVE' });
    prisma.groupCallInvite.findMany.mockResolvedValue([{ ...call.invites[0], status: 'JOINED' }]);

    const r = await service.joinCall('c1', 'u1');

    expect(prisma.groupCallInvite.update).toHaveBeenCalledWith(expect.objectContaining({
      where: { groupCallId_userId: { groupCallId: 'c1', userId: 'u1' } },
      data: expect.objectContaining({ status: 'JOINED' }),
    }));
    expect(prisma.groupCall.update).toHaveBeenCalledWith(expect.objectContaining({
      where: { id: 'c1' },
      data: expect.objectContaining({ status: 'ACTIVE' }),
    }));
    expect(r.livekitToken).toBeTruthy();
    expect(gateway.emitStatus).toHaveBeenCalled();
  });

  it('returns same token if already JOINED (idempotent)', async () => {
    const call = {
      id: 'c1', status: 'ACTIVE', livekitRoomName: 'group-c1', hostUserId: 'host',
      invites: [{ id: 'i1', userId: 'u1', status: 'JOINED' }],
    };
    prisma.groupCall.findUnique = jest.fn().mockResolvedValue(call);
    const r = await service.joinCall('c1', 'u1');
    expect(prisma.groupCallInvite.update).not.toHaveBeenCalled();
    expect(r.livekitToken).toBeTruthy();
  });

  it('throws if call ENDED', async () => {
    prisma.groupCall.findUnique = jest.fn().mockResolvedValue({ id: 'c1', status: 'ENDED', invites: [{ userId: 'u1', status: 'CALLING' }] });
    await expect(service.joinCall('c1', 'u1')).rejects.toThrow();
  });

  it('throws if user has no invite', async () => {
    prisma.groupCall.findUnique = jest.fn().mockResolvedValue({ id: 'c1', status: 'ACTIVE', invites: [] });
    await expect(service.joinCall('c1', 'u1')).rejects.toThrow();
  });
});
```

- [ ] **Step 2: Run, verify fail**

Run: `npm test -- group-call.service.spec.ts`

Expected: 4 FAILs.

- [ ] **Step 3: Implement `joinCall`**

```typescript
async joinCall(callId: string, userId: string) {
  const call = await this.prisma.groupCall.findUnique({
    where: { id: callId },
    include: { invites: true },
  });
  if (!call) throw new NotFoundException('GroupCall not found');
  if (call.status === GroupCallStatus.ENDED) throw new GoneException('Call ended');

  const invite = call.invites.find((i) => i.userId === userId);
  if (!invite) throw new ForbiddenException('No invite for this user');

  // Idempotent: already JOINED
  if (invite.status === GroupCallInviteStatus.JOINED) {
    const { token, livekitWsUrl } = this.voice.generateGroupCallToken(call.id, userId);
    return { livekitToken: token, livekitWsUrl };
  }

  await this.prisma.$transaction(async (tx) => {
    await tx.groupCallInvite.update({
      where: { groupCallId_userId: { groupCallId: callId, userId } },
      data: { status: GroupCallInviteStatus.JOINED, joinedAt: new Date(), respondedAt: new Date() },
    });
    if (call.status === GroupCallStatus.LOBBY) {
      await tx.groupCall.update({
        where: { id: callId },
        data: { status: GroupCallStatus.ACTIVE },
      });
    }
  });

  // Cancel pending timeout job (idempotent — fine if not present)
  await this.queue.remove(`timeout-${invite.id}`).catch(() => {});

  // Broadcast
  const refreshed = await this.prisma.groupCall.findUnique({
    where: { id: callId },
    include: { invites: true },
  });
  const participantIds = refreshed!.invites.filter(i =>
    i.status === GroupCallInviteStatus.JOINED || i.status === GroupCallInviteStatus.CALLING
  ).map(i => i.userId).concat(refreshed!.hostUserId);
  this.gateway.emitStatus(participantIds, { groupCallId: callId, invites: refreshed!.invites });

  const { token, livekitWsUrl } = this.voice.generateGroupCallToken(call.id, userId);
  return { livekitToken: token, livekitWsUrl };
}
```

(Add `GoneException` import.)

- [ ] **Step 4: Run, verify pass**

Run: `npm test -- group-call.service.spec.ts`

Expected: ALL PASS.

- [ ] **Step 5: Commit**

```bash
git add src/voice/group-call/group-call.service.ts src/voice/group-call/group-call.service.spec.ts
git commit -m "feat(group-call): joinCall (LOBBY→ACTIVE, idempotent)"
```

---

### Task 7: GroupCallService — `declineCall`, `endCall` (private helper)

**Files:**
- Modify: `src/voice/group-call/group-call.service.ts`
- Modify: `src/voice/group-call/group-call.service.spec.ts`

- [ ] **Step 1: Write failing tests**

```typescript
describe('declineCall', () => {
  it('marks invite DECLINED, broadcasts status', async () => {
    const call = {
      id: 'c1', status: 'LOBBY',
      invites: [
        { id: 'i1', userId: 'u1', status: 'CALLING' },
        { id: 'i2', userId: 'u2', status: 'JOINED' },
      ],
    };
    prisma.groupCall.findUnique = jest.fn().mockResolvedValue(call);
    prisma.groupCallInvite.update = jest.fn();
    prisma.groupCallInvite.findMany.mockResolvedValue(call.invites);

    await service.declineCall('c1', 'u1');

    expect(prisma.groupCallInvite.update).toHaveBeenCalledWith(expect.objectContaining({
      data: expect.objectContaining({ status: 'DECLINED' }),
    }));
    expect(gateway.emitStatus).toHaveBeenCalled();
  });

  it('ends call if all invitees DECLINED/TIMEOUT and none JOINED', async () => {
    const call = {
      id: 'c1', status: 'LOBBY', livekitRoomName: 'group-c1', hostUserId: 'host',
      invites: [
        { id: 'i1', userId: 'u1', status: 'CALLING' },
        { id: 'i2', userId: 'u2', status: 'TIMEOUT' },
      ],
    };
    prisma.groupCall.findUnique = jest.fn().mockResolvedValue(call);
    prisma.groupCallInvite.update = jest.fn();
    prisma.groupCallInvite.findMany.mockResolvedValue([
      { id: 'i1', userId: 'u1', status: 'DECLINED' },
      { id: 'i2', userId: 'u2', status: 'TIMEOUT' },
    ]);
    prisma.groupCall.update = jest.fn();
    voice.deleteRoom = jest.fn().mockResolvedValue(undefined);

    await service.declineCall('c1', 'u1');

    expect(prisma.groupCall.update).toHaveBeenCalledWith(expect.objectContaining({
      data: expect.objectContaining({ status: 'ENDED', endedReason: 'timeout' }),
    }));
  });

  it('throws 409 if invite already JOINED', async () => {
    prisma.groupCall.findUnique = jest.fn().mockResolvedValue({
      id: 'c1', status: 'ACTIVE',
      invites: [{ id: 'i1', userId: 'u1', status: 'JOINED' }],
    });
    await expect(service.declineCall('c1', 'u1')).rejects.toThrow();
  });
});
```

- [ ] **Step 2: Run, verify fail**

Run: `npm test -- group-call.service.spec.ts`

Expected: 3 FAILs.

- [ ] **Step 3: Implement `declineCall` and private `endCallIfDeserted`**

```typescript
async declineCall(callId: string, userId: string) {
  const call = await this.prisma.groupCall.findUnique({
    where: { id: callId },
    include: { invites: true },
  });
  if (!call) throw new NotFoundException('GroupCall not found');
  const invite = call.invites.find((i) => i.userId === userId);
  if (!invite) throw new ForbiddenException('No invite for this user');
  if (invite.status === GroupCallInviteStatus.JOINED) {
    throw new ConflictException('Already joined; use /leave instead');
  }
  if (invite.status === GroupCallInviteStatus.DECLINED) return; // idempotent

  await this.prisma.groupCallInvite.update({
    where: { groupCallId_userId: { groupCallId: callId, userId } },
    data: { status: GroupCallInviteStatus.DECLINED, respondedAt: new Date() },
  });
  await this.queue.remove(`timeout-${invite.id}`).catch(() => {});

  const refreshed = await this.prisma.groupCall.findUnique({
    where: { id: callId },
    include: { invites: true },
  });
  const participantIds = this.collectParticipantIds(refreshed!);
  this.gateway.emitStatus(participantIds, { groupCallId: callId, invites: refreshed!.invites });

  await this.endCallIfDeserted(refreshed!);
}

private async endCallIfDeserted(call: any) {
  if (call.status !== GroupCallStatus.LOBBY && call.status !== GroupCallStatus.ACTIVE) return;
  const anyJoined = call.invites.some((i: any) => i.status === GroupCallInviteStatus.JOINED);
  const anyCalling = call.invites.some((i: any) => i.status === GroupCallInviteStatus.CALLING);

  // LOBBY: end if no one is JOINED and no one is still ringing
  if (call.status === GroupCallStatus.LOBBY && !anyJoined && !anyCalling) {
    await this.endCall(call.id, 'timeout');
    return;
  }
  // ACTIVE: end if no JOINED at all
  if (call.status === GroupCallStatus.ACTIVE && !anyJoined) {
    await this.endCall(call.id, 'all_left');
    return;
  }
}

private async endCall(callId: string, reason: 'all_left' | 'timeout' | 'host_ended') {
  const updated = await this.prisma.groupCall.update({
    where: { id: callId, status: { in: [GroupCallStatus.LOBBY, GroupCallStatus.ACTIVE] } },
    data: { status: GroupCallStatus.ENDED, endedAt: new Date(), endedReason: reason },
  }).catch(() => null); // already ENDED → race-safe no-op

  if (!updated) return;

  const allInvites = await this.prisma.groupCallInvite.findMany({ where: { groupCallId: callId } });
  const allUserIds = Array.from(new Set([updated.hostUserId, ...allInvites.map(i => i.userId)]));
  this.gateway.emitEnded(allUserIds, { groupCallId: callId, reason });

  // Best-effort LiveKit cleanup
  await this.voice.deleteRoom(updated.livekitRoomName).catch((e) =>
    this.logger.warn(`LiveKit deleteRoom failed: ${e.message}`),
  );
}

private collectParticipantIds(call: any): string[] {
  const ids = new Set<string>([call.hostUserId]);
  for (const inv of call.invites) {
    if (
      inv.status === GroupCallInviteStatus.CALLING ||
      inv.status === GroupCallInviteStatus.JOINED
    ) {
      ids.add(inv.userId);
    }
  }
  return Array.from(ids);
}
```

(Add `ConflictException` import. Add `emitEnded` method to `GroupCallGateway` — see Task 13.)

Also extend `VoiceService.deleteRoom` (likely already exists; if not):

```typescript
async deleteRoom(roomName: string): Promise<void> {
  await this.roomService.deleteRoom(roomName);
}
```

- [ ] **Step 4: Run tests, verify pass**

Run: `npm test -- group-call.service.spec.ts`

Expected: ALL PASS.

- [ ] **Step 5: Commit**

```bash
git add src/voice/group-call/ src/voice/voice.service.ts
git commit -m "feat(group-call): declineCall + endCall helpers"
```

---

### Task 8: GroupCallService — `leaveCall` with host transfer

**Files:**
- Modify: `src/voice/group-call/group-call.service.ts`
- Modify: `src/voice/group-call/group-call.service.spec.ts`

- [ ] **Step 1: Write failing tests**

```typescript
describe('leaveCall', () => {
  it('marks invite LEFT, broadcasts status, no host change if non-host leaves', async () => {
    const call = {
      id: 'c1', status: 'ACTIVE', hostUserId: 'host', livekitRoomName: 'group-c1',
      invites: [
        { id: 'i1', userId: 'u1', status: 'JOINED', joinedAt: new Date('2026-04-29T10:00:00Z') },
        { id: 'i2', userId: 'u2', status: 'JOINED', joinedAt: new Date('2026-04-29T10:01:00Z') },
      ],
    };
    prisma.groupCall.findUnique = jest.fn().mockResolvedValue(call);
    prisma.groupCallInvite.update = jest.fn();
    prisma.groupCallInvite.findMany.mockResolvedValue([
      { ...call.invites[0], status: 'LEFT', leftAt: new Date() },
      call.invites[1],
    ]);

    await service.leaveCall('c1', 'u1');

    expect(prisma.groupCallInvite.update).toHaveBeenCalled();
    expect(prisma.groupCall.update).not.toHaveBeenCalled();
  });

  it('transfers host to next JOINED (joinedAt asc) when host leaves', async () => {
    const call = {
      id: 'c1', status: 'ACTIVE', hostUserId: 'host', livekitRoomName: 'group-c1',
      invites: [
        { id: 'i1', userId: 'u1', status: 'JOINED', joinedAt: new Date('2026-04-29T10:00:00Z') },
        { id: 'i2', userId: 'u2', status: 'JOINED', joinedAt: new Date('2026-04-29T10:01:00Z') },
      ],
    };
    prisma.groupCall.findUnique = jest.fn().mockResolvedValue(call);
    prisma.groupCallInvite.findMany.mockResolvedValue(call.invites);

    await service.leaveCall('c1', 'host');

    expect(prisma.groupCall.update).toHaveBeenCalledWith(expect.objectContaining({
      data: expect.objectContaining({ hostUserId: 'u1' }),
    }));
    expect(gateway.emitHostChanged).toHaveBeenCalledWith(expect.anything(), { groupCallId: 'c1', newHostUserId: 'u1' });
  });

  it('ends call when last JOINED leaves', async () => {
    const call = {
      id: 'c1', status: 'ACTIVE', hostUserId: 'host', livekitRoomName: 'group-c1',
      invites: [{ id: 'i1', userId: 'u1', status: 'JOINED' }],
    };
    prisma.groupCall.findUnique = jest.fn().mockResolvedValue(call);
    prisma.groupCallInvite.update = jest.fn();
    prisma.groupCallInvite.findMany.mockResolvedValue([{ ...call.invites[0], status: 'LEFT' }]);
    prisma.groupCall.update = jest.fn();

    await service.leaveCall('c1', 'u1');

    expect(prisma.groupCall.update).toHaveBeenCalledWith(expect.objectContaining({
      data: expect.objectContaining({ status: 'ENDED', endedReason: 'all_left' }),
    }));
  });

  it('idempotent if already LEFT', async () => {
    const call = {
      id: 'c1', status: 'ACTIVE',
      invites: [{ id: 'i1', userId: 'u1', status: 'LEFT' }],
    };
    prisma.groupCall.findUnique = jest.fn().mockResolvedValue(call);
    await service.leaveCall('c1', 'u1');
    expect(prisma.groupCallInvite.update).not.toHaveBeenCalled();
  });
});
```

- [ ] **Step 2: Run, verify fail**

Run: `npm test -- group-call.service.spec.ts`

Expected: FAILs.

- [ ] **Step 3: Implement `leaveCall`**

```typescript
async leaveCall(callId: string, userId: string) {
  const call = await this.prisma.groupCall.findUnique({
    where: { id: callId },
    include: { invites: true },
  });
  if (!call) throw new NotFoundException('GroupCall not found');
  if (call.status === GroupCallStatus.ENDED) return;

  const isHost = call.hostUserId === userId;
  const invite = call.invites.find((i) => i.userId === userId);

  if (!isHost && !invite) throw new ForbiddenException('No participant for this user');
  if (invite && invite.status === GroupCallInviteStatus.LEFT) return; // idempotent

  await this.prisma.$transaction(async (tx) => {
    if (invite) {
      await tx.groupCallInvite.update({
        where: { groupCallId_userId: { groupCallId: callId, userId } },
        data: { status: GroupCallInviteStatus.LEFT, leftAt: new Date() },
      });
    }

    if (isHost) {
      const nextHost = call.invites
        .filter((i) => i.status === GroupCallInviteStatus.JOINED && i.userId !== userId && i.joinedAt)
        .sort((a, b) => (a.joinedAt!.getTime() - b.joinedAt!.getTime()))[0];

      if (nextHost) {
        await tx.groupCall.update({
          where: { id: callId },
          data: { hostUserId: nextHost.userId },
        });
        const allUserIds = this.collectParticipantIds(call);
        this.gateway.emitHostChanged(allUserIds, { groupCallId: callId, newHostUserId: nextHost.userId });
      }
    }
  });

  const refreshed = await this.prisma.groupCall.findUnique({
    where: { id: callId },
    include: { invites: true },
  });
  const participantIds = this.collectParticipantIds(refreshed!);
  this.gateway.emitStatus(participantIds, { groupCallId: callId, invites: refreshed!.invites });
  this.gateway.emitLeft(participantIds, { groupCallId: callId, userId, leftAt: new Date() });

  await this.endCallIfDeserted(refreshed!);
}
```

- [ ] **Step 4: Run tests, verify pass**

Run: `npm test -- group-call.service.spec.ts`

Expected: ALL PASS.

- [ ] **Step 5: Commit**

```bash
git add src/voice/group-call/group-call.service.ts src/voice/group-call/group-call.service.spec.ts
git commit -m "feat(group-call): leaveCall + host transfer + auto-end"
```

---

### Task 9: GroupCallService — `inviteMore`, `kick`, `muteAll`, `forceEnd`

**Files:**
- Modify: `src/voice/group-call/group-call.service.ts`
- Modify: `src/voice/group-call/group-call.service.spec.ts`

- [ ] **Step 1: Write failing tests**

```typescript
describe('inviteMore (host only, capacity check)', () => {
  it('rejects if non-host', async () => {
    prisma.groupCall.findUnique = jest.fn().mockResolvedValue({
      id: 'c1', hostUserId: 'host', status: 'ACTIVE', invites: [],
    });
    await expect(service.inviteMore('c1', 'someone-else', ['u9'])).rejects.toThrow();
  });

  it('rejects if (JOINED + CALLING + new) > 8', async () => {
    prisma.groupCall.findUnique = jest.fn().mockResolvedValue({
      id: 'c1', hostUserId: 'host', status: 'ACTIVE',
      invites: [
        { userId: 'u1', status: 'JOINED' }, { userId: 'u2', status: 'JOINED' },
        { userId: 'u3', status: 'JOINED' }, { userId: 'u4', status: 'JOINED' },
        { userId: 'u5', status: 'JOINED' }, { userId: 'u6', status: 'JOINED' },
        { userId: 'u7', status: 'CALLING' },
      ],
    });
    // Host (1) + 6 JOINED + 1 CALLING = 8. Can't invite more.
    await expect(service.inviteMore('c1', 'host', ['u9'])).rejects.toThrow();
  });

  it('inserts invites for new userIds, skips duplicates', async () => {
    const call = {
      id: 'c1', hostUserId: 'host', status: 'ACTIVE', livekitRoomName: 'group-c1',
      invites: [{ userId: 'u1', status: 'JOINED' }],
    };
    prisma.groupCall.findUnique = jest.fn().mockResolvedValue(call);
    prisma.groupCallInvite.createMany = jest.fn();
    prisma.groupCallInvite.findMany.mockResolvedValue([{ id: 'inew', userId: 'u2', status: 'CALLING' }]);

    await service.inviteMore('c1', 'host', ['u1', 'u2']); // u1 already JOINED → skip

    expect(prisma.groupCallInvite.createMany).toHaveBeenCalledWith({
      data: [{ groupCallId: 'c1', userId: 'u2', invitedBy: 'host', status: 'CALLING' }],
    });
  });
});

describe('kick (host only)', () => {
  it('rejects if non-host', async () => {
    prisma.groupCall.findUnique = jest.fn().mockResolvedValue({
      id: 'c1', hostUserId: 'host', invites: [{ userId: 'u1', status: 'JOINED' }],
    });
    await expect(service.kick('c1', 'someone', 'u1')).rejects.toThrow();
  });

  it('rejects if host kicks self', async () => {
    prisma.groupCall.findUnique = jest.fn().mockResolvedValue({
      id: 'c1', hostUserId: 'host', invites: [],
    });
    await expect(service.kick('c1', 'host', 'host')).rejects.toThrow();
  });

  it('marks LEFT, calls LiveKit removeParticipant, broadcasts', async () => {
    const call = {
      id: 'c1', hostUserId: 'host', livekitRoomName: 'group-c1', status: 'ACTIVE',
      invites: [{ userId: 'u1', status: 'JOINED' }],
    };
    prisma.groupCall.findUnique = jest.fn().mockResolvedValue(call);
    voice.removeParticipant = jest.fn();

    await service.kick('c1', 'host', 'u1');

    expect(voice.removeParticipant).toHaveBeenCalledWith('group-c1', 'u1');
    expect(gateway.emitKicked).toHaveBeenCalledWith('u1', expect.objectContaining({ groupCallId: 'c1' }));
  });
});

describe('muteAll (host only, rate-limited)', () => {
  it('rejects if non-host', async () => {
    prisma.groupCall.findUnique = jest.fn().mockResolvedValue({
      id: 'c1', hostUserId: 'host', invites: [],
    });
    await expect(service.muteAll('c1', 'someone')).rejects.toThrow();
  });

  it('broadcasts mute_request to all participants except host', async () => {
    const call = {
      id: 'c1', hostUserId: 'host', livekitRoomName: 'group-c1',
      invites: [
        { userId: 'u1', status: 'JOINED' },
        { userId: 'u2', status: 'JOINED' },
      ],
    };
    prisma.groupCall.findUnique = jest.fn().mockResolvedValue(call);

    await service.muteAll('c1', 'host');

    expect(gateway.emitMuteRequest).toHaveBeenCalledWith(
      ['u1', 'u2'],
      expect.objectContaining({ groupCallId: 'c1', by: 'host' }),
    );
  });
});

describe('forceEnd (host only)', () => {
  it('ends call with reason=host_ended', async () => {
    prisma.groupCall.findUnique = jest.fn().mockResolvedValue({
      id: 'c1', hostUserId: 'host', status: 'ACTIVE', livekitRoomName: 'group-c1',
      invites: [{ userId: 'u1', status: 'JOINED' }],
    });
    prisma.groupCall.update = jest.fn().mockResolvedValue({ id: 'c1', hostUserId: 'host', livekitRoomName: 'group-c1' });
    prisma.groupCallInvite.findMany.mockResolvedValue([]);
    voice.deleteRoom = jest.fn();

    await service.forceEnd('c1', 'host');

    expect(prisma.groupCall.update).toHaveBeenCalledWith(expect.objectContaining({
      data: expect.objectContaining({ status: 'ENDED', endedReason: 'host_ended' }),
    }));
  });
});
```

- [ ] **Step 2: Run, verify fail**

Run: `npm test -- group-call.service.spec.ts`

Expected: FAILs.

- [ ] **Step 3: Implement methods**

```typescript
async inviteMore(callId: string, hostUserId: string, userIds: string[]) {
  const call = await this.prisma.groupCall.findUnique({
    where: { id: callId },
    include: { invites: true },
  });
  if (!call) throw new NotFoundException('GroupCall not found');
  if (call.hostUserId !== hostUserId) throw new ForbiddenException('Only host can invite');
  if (call.status === GroupCallStatus.ENDED) throw new ConflictException('Call ended');

  const occupied = 1 /* host */ + call.invites.filter(i =>
    i.status === GroupCallInviteStatus.JOINED ||
    i.status === GroupCallInviteStatus.CALLING
  ).length;

  const existingUserIds = new Set(
    call.invites
      .filter(i => i.status === GroupCallInviteStatus.JOINED || i.status === GroupCallInviteStatus.CALLING)
      .map(i => i.userId),
  );
  const newUserIds = userIds.filter(id => !existingUserIds.has(id) && id !== hostUserId);

  if (occupied + newUserIds.length > MAX_PARTICIPANTS) {
    throw new ConflictException(`Capacity exceeded: ${MAX_PARTICIPANTS} max`);
  }
  if (newUserIds.length === 0) return { added: 0 };

  await this.prisma.groupCallInvite.createMany({
    data: newUserIds.map(uid => ({
      groupCallId: callId,
      userId: uid,
      invitedBy: hostUserId,
      status: GroupCallInviteStatus.CALLING,
    })),
  });
  const newInvites = await this.prisma.groupCallInvite.findMany({
    where: { groupCallId: callId, userId: { in: newUserIds } },
  });

  const host = await this.prisma.user.findUnique({ where: { id: hostUserId } });
  for (const inv of newInvites) {
    await this.queue.add('timeout-invite', { inviteId: inv.id }, {
      delay: RING_TIMEOUT_SEC * 1000, jobId: `timeout-${inv.id}`,
    });
    this.voip.sendGroupCallInvite(inv.userId, {
      groupCallId: callId, host, inviteeCount: newInvites.length, livekitRoomName: call.livekitRoomName,
    }).catch(e => this.logger.warn(`VoIP push failed: ${e.message}`));
    this.fcm.sendGroupCallInvite(inv.userId, {
      groupCallId: callId, host, inviteeCount: newInvites.length,
    }).catch(e => this.logger.warn(`FCM push failed: ${e.message}`));
    this.gateway.emitInvite(inv.userId, { groupCallId: callId, host, invitees: newInvites });
  }

  const refreshed = await this.prisma.groupCall.findUnique({
    where: { id: callId }, include: { invites: true },
  });
  const participantIds = this.collectParticipantIds(refreshed!);
  this.gateway.emitStatus(participantIds, { groupCallId: callId, invites: refreshed!.invites });

  return { added: newUserIds.length };
}

async kick(callId: string, hostUserId: string, targetUserId: string) {
  if (hostUserId === targetUserId) throw new BadRequestException('Cannot kick host');

  const call = await this.prisma.groupCall.findUnique({
    where: { id: callId },
    include: { invites: true },
  });
  if (!call) throw new NotFoundException('GroupCall not found');
  if (call.hostUserId !== hostUserId) throw new ForbiddenException('Only host can kick');

  const target = call.invites.find(i => i.userId === targetUserId);
  if (!target) throw new NotFoundException('Target not in call');
  if (target.status === GroupCallInviteStatus.LEFT) return; // idempotent

  await this.prisma.groupCallInvite.update({
    where: { groupCallId_userId: { groupCallId: callId, userId: targetUserId } },
    data: { status: GroupCallInviteStatus.LEFT, leftAt: new Date() },
  });

  // Force LiveKit disconnect (best-effort)
  await this.voice.removeParticipant(call.livekitRoomName, targetUserId)
    .catch((e) => this.logger.warn(`LiveKit removeParticipant failed: ${e.message}`));

  this.gateway.emitKicked(targetUserId, { groupCallId: callId, by: hostUserId });

  const refreshed = await this.prisma.groupCall.findUnique({
    where: { id: callId }, include: { invites: true },
  });
  const participantIds = this.collectParticipantIds(refreshed!);
  this.gateway.emitStatus(participantIds, { groupCallId: callId, invites: refreshed!.invites });

  await this.endCallIfDeserted(refreshed!);
}

async muteAll(callId: string, hostUserId: string) {
  const call = await this.prisma.groupCall.findUnique({
    where: { id: callId },
    include: { invites: true },
  });
  if (!call) throw new NotFoundException('GroupCall not found');
  if (call.hostUserId !== hostUserId) throw new ForbiddenException('Only host can mute-all');

  // Rate limit (10s) — Redis SETNX
  const allowed = await this.checkAndSetRateLimit(`mute-all:${callId}`, 10);
  if (!allowed) throw new TooManyRequestsException('Rate limit: 1 per 10s');

  const targetIds = call.invites
    .filter(i => i.status === GroupCallInviteStatus.JOINED && i.userId !== hostUserId)
    .map(i => i.userId);

  this.gateway.emitMuteRequest(targetIds, { groupCallId: callId, by: hostUserId });
}

async forceEnd(callId: string, hostUserId: string) {
  const call = await this.prisma.groupCall.findUnique({
    where: { id: callId },
  });
  if (!call) throw new NotFoundException('GroupCall not found');
  if (call.hostUserId !== hostUserId) throw new ForbiddenException('Only host can end');
  if (call.status === GroupCallStatus.ENDED) return;
  await this.endCall(callId, 'host_ended');
}

// Add helper for rate limiting (uses Redis through existing service):
private async checkAndSetRateLimit(key: string, ttlSec: number): Promise<boolean> {
  // Inject Redis service as needed; pseudocode:
  // const ok = await this.redis.set(key, '1', 'NX', 'EX', ttlSec);
  // return ok === 'OK';
  return true; // placeholder; wire to existing Redis client
}
```

(Add `TooManyRequestsException` import. Wire to existing Redis service. Extend `VoiceService.removeParticipant(roomName, identity)` if not present.)

Add to `VoiceService`:

```typescript
async removeParticipant(roomName: string, identity: string): Promise<void> {
  await this.roomService.removeParticipant(roomName, identity);
}
```

- [ ] **Step 4: Run tests, verify pass**

Run: `npm test -- group-call.service.spec.ts`

Expected: ALL PASS.

- [ ] **Step 5: Commit**

```bash
git add src/voice/group-call/ src/voice/voice.service.ts
git commit -m "feat(group-call): host actions — inviteMore, kick, muteAll, forceEnd"
```

---

### Task 10: GroupCallController + GroupCallHostGuard

**Files:**
- Create: `src/voice/group-call/group-call.controller.ts`
- Create: `src/voice/group-call/guards/group-call-host.guard.ts`
- Modify: `src/voice/group-call/group-call.module.ts`

- [ ] **Step 1: Implement `GroupCallHostGuard`**

```typescript
import { CanActivate, ExecutionContext, ForbiddenException, Injectable } from '@nestjs/common';
import { PrismaService } from '../../../prisma/prisma.service';

@Injectable()
export class GroupCallHostGuard implements CanActivate {
  constructor(private readonly prisma: PrismaService) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const req = context.switchToHttp().getRequest();
    const userId = req.user?.id;
    const callId = req.params.id;
    if (!userId || !callId) throw new ForbiddenException();
    const call = await this.prisma.groupCall.findUnique({
      where: { id: callId }, select: { hostUserId: true },
    });
    if (!call || call.hostUserId !== userId) throw new ForbiddenException('Host only');
    return true;
  }
}
```

- [ ] **Step 2: Implement `GroupCallController`**

```typescript
import {
  Body, Controller, Get, HttpCode, Param, Post, Req, UseGuards,
} from '@nestjs/common';
import { JwtAuthGuard } from '../../auth/guards/jwt-auth.guard';
import { GroupCallService } from './group-call.service';
import { CreateGroupCallDto } from './dto/create-group-call.dto';
import { InviteUsersDto } from './dto/invite-users.dto';
import { KickUserDto } from './dto/kick-user.dto';
import { GroupCallHostGuard } from './guards/group-call-host.guard';

@Controller('voice/group-calls')
@UseGuards(JwtAuthGuard)
export class GroupCallController {
  constructor(private readonly service: GroupCallService) {}

  @Post()
  async create(@Req() req: any, @Body() dto: CreateGroupCallDto) {
    return this.service.createCall(req.user.id, dto.inviteeIds);
  }

  @Get('active')
  async active(@Req() req: any) {
    const calls = await this.service.getActiveCallsForUser(req.user.id);
    return { calls };
  }

  @Get(':id')
  async detail(@Req() req: any, @Param('id') id: string) {
    const groupCall = await this.service.getCall(id, req.user.id);
    return { groupCall };
  }

  @Post(':id/join')
  @HttpCode(200)
  async join(@Req() req: any, @Param('id') id: string) {
    return this.service.joinCall(id, req.user.id);
  }

  @Post(':id/decline')
  @HttpCode(200)
  async decline(@Req() req: any, @Param('id') id: string) {
    await this.service.declineCall(id, req.user.id);
    return { ok: true };
  }

  @Post(':id/leave')
  @HttpCode(200)
  async leave(@Req() req: any, @Param('id') id: string) {
    await this.service.leaveCall(id, req.user.id);
    return { ok: true };
  }

  @Post(':id/invite')
  @UseGuards(GroupCallHostGuard)
  async invite(@Req() req: any, @Param('id') id: string, @Body() dto: InviteUsersDto) {
    return this.service.inviteMore(id, req.user.id, dto.userIds);
  }

  @Post(':id/kick')
  @UseGuards(GroupCallHostGuard)
  async kick(@Req() req: any, @Param('id') id: string, @Body() dto: KickUserDto) {
    await this.service.kick(id, req.user.id, dto.userId);
    return { ok: true };
  }

  @Post(':id/mute-all')
  @UseGuards(GroupCallHostGuard)
  @HttpCode(200)
  async muteAll(@Req() req: any, @Param('id') id: string) {
    await this.service.muteAll(id, req.user.id);
    return { ok: true };
  }

  @Post(':id/end')
  @UseGuards(GroupCallHostGuard)
  @HttpCode(200)
  async end(@Req() req: any, @Param('id') id: string) {
    await this.service.forceEnd(id, req.user.id);
    return { ok: true };
  }
}
```

- [ ] **Step 3: Wire controller + guard into module**

Modify `group-call.module.ts`:

```typescript
import { GroupCallController } from './group-call.controller';
import { GroupCallHostGuard } from './guards/group-call-host.guard';

@Module({
  imports: [/* … */],
  providers: [GroupCallService, GroupCallGateway, GroupCallHostGuard],
  controllers: [GroupCallController],
  exports: [GroupCallService],
})
export class GroupCallModule {}
```

- [ ] **Step 4: Run build**

Run: `npm run build`

Expected: `0 errors`.

- [ ] **Step 5: Commit**

```bash
git add src/voice/group-call/group-call.controller.ts src/voice/group-call/guards src/voice/group-call/group-call.module.ts
git commit -m "feat(group-call): REST controller + host guard"
```

---

### Task 11: BullMQ timeout processor

**Files:**
- Create: `src/voice/group-call/jobs/timeout.processor.ts`
- Modify: `src/voice/group-call/group-call.module.ts`
- Modify: `src/voice/group-call/group-call.service.ts` (add `handleInviteTimeout`)
- Modify: `src/voice/group-call/group-call.service.spec.ts`

- [ ] **Step 1: Write failing test**

Append to `group-call.service.spec.ts`:

```typescript
describe('handleInviteTimeout', () => {
  it('marks invite TIMEOUT if still CALLING, broadcasts, may end call', async () => {
    const invite = { id: 'i1', groupCallId: 'c1', userId: 'u1', status: 'CALLING' };
    prisma.groupCallInvite.findUnique = jest.fn().mockResolvedValue(invite);
    prisma.groupCallInvite.update = jest.fn();
    prisma.groupCall.findUnique = jest.fn().mockResolvedValue({
      id: 'c1', status: 'LOBBY', hostUserId: 'host', livekitRoomName: 'group-c1',
      invites: [{ ...invite, status: 'TIMEOUT' }],
    });

    await service.handleInviteTimeout('i1');

    expect(prisma.groupCallInvite.update).toHaveBeenCalledWith(expect.objectContaining({
      data: expect.objectContaining({ status: 'TIMEOUT' }),
    }));
    expect(gateway.emitStatus).toHaveBeenCalled();
  });

  it('no-op if invite already JOINED/DECLINED/TIMEOUT/LEFT', async () => {
    prisma.groupCallInvite.findUnique = jest.fn().mockResolvedValue({ id: 'i1', status: 'JOINED' });
    await service.handleInviteTimeout('i1');
    expect(prisma.groupCallInvite.update).not.toHaveBeenCalled();
  });
});
```

- [ ] **Step 2: Implement `handleInviteTimeout`**

In `group-call.service.ts`:

```typescript
async handleInviteTimeout(inviteId: string) {
  const invite = await this.prisma.groupCallInvite.findUnique({ where: { id: inviteId } });
  if (!invite) return;
  if (invite.status !== GroupCallInviteStatus.CALLING) return; // idempotent

  await this.prisma.groupCallInvite.update({
    where: { id: inviteId },
    data: { status: GroupCallInviteStatus.TIMEOUT, respondedAt: new Date() },
  });

  const call = await this.prisma.groupCall.findUnique({
    where: { id: invite.groupCallId },
    include: { invites: true },
  });
  if (!call) return;

  const participantIds = this.collectParticipantIds(call);
  this.gateway.emitStatus(participantIds, { groupCallId: call.id, invites: call.invites });

  await this.endCallIfDeserted(call);
}
```

- [ ] **Step 3: Create `timeout.processor.ts`**

```typescript
import { Processor, WorkerHost } from '@nestjs/bullmq';
import { Job } from 'bullmq';
import { Logger } from '@nestjs/common';
import { GroupCallService } from '../group-call.service';

@Processor('group-call-timeouts')
export class GroupCallTimeoutProcessor extends WorkerHost {
  private readonly logger = new Logger(GroupCallTimeoutProcessor.name);

  constructor(private readonly service: GroupCallService) {
    super();
  }

  async process(job: Job<{ inviteId: string }>): Promise<void> {
    if (job.name !== 'timeout-invite') return;
    try {
      await this.service.handleInviteTimeout(job.data.inviteId);
    } catch (e: any) {
      this.logger.error(`timeout-invite failed for ${job.data.inviteId}: ${e.message}`);
      throw e;
    }
  }
}
```

- [ ] **Step 4: Register processor in module**

Modify `group-call.module.ts`:

```typescript
import { GroupCallTimeoutProcessor } from './jobs/timeout.processor';

@Module({
  // …
  providers: [GroupCallService, GroupCallGateway, GroupCallHostGuard, GroupCallTimeoutProcessor],
  // …
})
```

- [ ] **Step 5: Run tests + build**

Run: `npm test -- group-call.service.spec.ts && npm run build`

Expected: PASS, 0 errors.

- [ ] **Step 6: Commit**

```bash
git add src/voice/group-call/
git commit -m "feat(group-call): BullMQ timeout processor (30s ringing)"
```

---

### Task 12: Cron cleanup for zombie rooms

**Files:**
- Create: `src/voice/group-call/jobs/cleanup.cron.ts`
- Modify: `src/voice/group-call/group-call.module.ts`
- Modify: `src/app.module.ts` (register `ScheduleModule` if not already)

- [ ] **Step 1: Ensure ScheduleModule.forRoot() is in AppModule**

Inspect `src/app.module.ts`. If `ScheduleModule.forRoot()` is absent, add:

```typescript
import { ScheduleModule } from '@nestjs/schedule';

@Module({
  imports: [/* … */, ScheduleModule.forRoot()],
})
export class AppModule {}
```

- [ ] **Step 2: Create `cleanup.cron.ts`**

```typescript
import { Injectable, Logger } from '@nestjs/common';
import { Cron, CronExpression } from '@nestjs/schedule';
import { PrismaService } from '../../../prisma/prisma.service';
import { GroupCallStatus, GroupCallInviteStatus } from '@prisma/client';
import { GroupCallService } from '../group-call.service';

@Injectable()
export class GroupCallCleanupCron {
  private readonly logger = new Logger(GroupCallCleanupCron.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly service: GroupCallService,
  ) {}

  @Cron(CronExpression.EVERY_5_MINUTES)
  async cleanup() {
    const now = Date.now();

    // 1. Force-end LOBBY older than 5min
    const fiveMinAgo = new Date(now - 5 * 60 * 1000);
    const staleLobby = await this.prisma.groupCall.findMany({
      where: { status: GroupCallStatus.LOBBY, startedAt: { lt: fiveMinAgo } },
      select: { id: true },
    });
    for (const c of staleLobby) {
      await this.service.handleZombieEnd(c.id, 'timeout').catch(() => {});
    }

    // 2. Force-end ACTIVE with no JOINED for >1 min
    const oneMinAgo = new Date(now - 60 * 1000);
    const activeStale = await this.prisma.groupCall.findMany({
      where: {
        status: GroupCallStatus.ACTIVE,
        invites: {
          none: {
            status: GroupCallInviteStatus.JOINED,
            joinedAt: { gt: oneMinAgo },
          },
        },
      },
      select: { id: true },
    });
    for (const c of activeStale) {
      await this.service.handleZombieEnd(c.id, 'all_left').catch(() => {});
    }

    if (staleLobby.length || activeStale.length) {
      this.logger.log(`Cleaned ${staleLobby.length} LOBBY + ${activeStale.length} ACTIVE`);
    }
  }
}
```

- [ ] **Step 3: Add `handleZombieEnd` public method**

Append to `GroupCallService`:

```typescript
async handleZombieEnd(callId: string, reason: 'all_left' | 'timeout' | 'host_ended') {
  await this.endCall(callId, reason);
}
```

(`endCall` was already private from Task 7; expose via this thin wrapper.)

- [ ] **Step 4: Register in module**

Modify `group-call.module.ts`:

```typescript
import { GroupCallCleanupCron } from './jobs/cleanup.cron';

@Module({
  // …
  providers: [
    GroupCallService, GroupCallGateway, GroupCallHostGuard,
    GroupCallTimeoutProcessor, GroupCallCleanupCron,
  ],
  // …
})
```

- [ ] **Step 5: Run build**

Run: `npm run build`

Expected: 0 errors.

- [ ] **Step 6: Commit**

```bash
git add src/voice/group-call/jobs/cleanup.cron.ts src/voice/group-call/ src/app.module.ts
git commit -m "feat(group-call): cron cleanup for zombie rooms (5min)"
```

---

### Task 13: GroupCallGateway — full event surface + MessengerGateway helper

**Files:**
- Modify: `src/voice/group-call/group-call.gateway.ts`
- Modify: `src/messenger/messenger.gateway.ts`

- [ ] **Step 1: Inspect MessengerGateway for `emitToUser`**

Run: `grep -n "emitToUser" src/messenger/messenger.gateway.ts || echo MISSING`

If `MISSING`, add:

```typescript
emitToUser(userId: string, event: string, payload: any): void {
  this.server.to(`user:${userId}`).emit(event, payload);
}
```

(Adjust room naming to whatever existing convention is — `user:${userId}` or similar — based on how 1-on-1 messenger emits work. Match existing pattern.)

- [ ] **Step 2: Replace stub `group-call.gateway.ts` with full implementation**

```typescript
import { Injectable } from '@nestjs/common';
import { MessengerGateway } from '../../messenger/messenger.gateway';

@Injectable()
export class GroupCallGateway {
  constructor(private readonly messenger: MessengerGateway) {}

  emitInvite(userId: string, payload: { groupCallId: string; host: any; invitees: any[] }) {
    this.messenger.emitToUser(userId, 'group_call_invite', payload);
  }

  emitStatus(userIds: string[], payload: { groupCallId: string; invites: any[] }) {
    for (const uid of userIds) {
      this.messenger.emitToUser(uid, 'group_call_status', payload);
    }
  }

  emitJoined(userIds: string[], payload: { groupCallId: string; userId: string; joinedAt: Date }) {
    for (const uid of userIds) {
      this.messenger.emitToUser(uid, 'group_call_joined', payload);
    }
  }

  emitLeft(userIds: string[], payload: { groupCallId: string; userId: string; leftAt: Date }) {
    for (const uid of userIds) {
      this.messenger.emitToUser(uid, 'group_call_left', payload);
    }
  }

  emitKicked(userId: string, payload: { groupCallId: string; by: string }) {
    this.messenger.emitToUser(userId, 'group_call_kicked', payload);
  }

  emitMuteRequest(userIds: string[], payload: { groupCallId: string; by: string }) {
    for (const uid of userIds) {
      this.messenger.emitToUser(uid, 'group_call_mute_request', payload);
    }
  }

  emitHostChanged(userIds: string[], payload: { groupCallId: string; newHostUserId: string }) {
    for (const uid of userIds) {
      this.messenger.emitToUser(uid, 'group_call_host_changed', payload);
    }
  }

  emitEnded(userIds: string[], payload: { groupCallId: string; reason: string }) {
    for (const uid of userIds) {
      this.messenger.emitToUser(uid, 'group_call_ended', payload);
    }
  }
}
```

- [ ] **Step 3: Run build**

Run: `npm run build`

Expected: 0 errors.

- [ ] **Step 4: Commit**

```bash
git add src/voice/group-call/group-call.gateway.ts src/messenger/messenger.gateway.ts
git commit -m "feat(group-call): gateway events + emitToUser helper"
```

---

### Task 14: Push services — `sendGroupCallInvite`

**Files:**
- Modify: `src/notifications/voip-push.service.ts` (or matching VoIP push provider)
- Modify: `src/notifications/fcm-push.service.ts` (or matching FCM service)

- [ ] **Step 1: Add `sendGroupCallInvite` to VoIP push service**

Add method:

```typescript
async sendGroupCallInvite(userId: string, payload: {
  groupCallId: string;
  host: { id: string; displayName: string; avatarUrl?: string };
  inviteeCount: number;
  livekitRoomName: string;
}) {
  const tokens = await this.getVoipTokens(userId); // existing helper
  if (!tokens.length) return;

  const apnsPayload = {
    aps: {
      alert: { title: payload.host.displayName, body: 'Группа: + ' + (payload.inviteeCount - 1) + ' ещё' },
      sound: 'default',
    },
    type: 'group_call_invite',
    groupCallId: payload.groupCallId,
    host: payload.host,
    inviteeCount: payload.inviteeCount,
    livekitRoomName: payload.livekitRoomName,
  };

  for (const token of tokens) {
    await this.sendVoipPush(token, apnsPayload); // existing low-level
  }
}
```

(Mirror the pattern of existing `sendCallInvite` (1-on-1) — copy-modify, not refactor.)

- [ ] **Step 2: Add `sendGroupCallInvite` to FCM service**

```typescript
async sendGroupCallInvite(userId: string, payload: {
  groupCallId: string;
  host: { id: string; displayName: string; avatarUrl?: string };
  inviteeCount: number;
}) {
  const tokens = await this.getFcmTokens(userId);
  if (!tokens.length) return;

  const message = {
    data: {
      type: 'group_call_invite',
      groupCallId: payload.groupCallId,
      host: JSON.stringify(payload.host),
      inviteeCount: String(payload.inviteeCount),
      ttl_seconds: '30',
    },
    android: { priority: 'high' as const, ttl: 30 * 1000 },
    tokens,
  };
  await this.firebase.messaging().sendEachForMulticast(message);
}
```

- [ ] **Step 3: Run build**

Run: `npm run build`

Expected: 0 errors.

- [ ] **Step 4: Commit**

```bash
git add src/notifications/
git commit -m "feat(group-call): VoIP/FCM push payload builders"
```

---

### Task 15: LiveKit webhook — `participant_left` for group rooms

**Files:**
- Modify: `src/voice/voice.controller.ts`
- Modify: `src/voice/group-call/group-call.service.ts` (add `handleLivekitParticipantLeft`)
- Modify: `src/voice/group-call/group-call.service.spec.ts`

- [ ] **Step 1: Inspect existing webhook**

Run: `grep -n "livekit-webhook\\|webhookReceiver" src/voice/voice.controller.ts || echo MISSING`

If existing:
- Add a new branch in the existing handler that dispatches when `roomName.startsWith('group-')`.

If missing:
- Create a new `POST /voice/livekit-webhook` endpoint using `@livekit/server-sdk`'s `WebhookReceiver`, configure LiveKit `webhook.urls` to point at it.

- [ ] **Step 2: Add dispatch logic**

In `voice.controller.ts`:

```typescript
@Post('livekit-webhook')
@HttpCode(200)
async livekitWebhook(@Req() req: any, @Headers('authorization') authz: string) {
  const event = await this.webhookReceiver.receive(req.rawBody.toString(), authz);
  // existing handling for 1-on-1 / outbound bot…

  if (event.event === 'participant_left' && event.room?.name?.startsWith('group-')) {
    const callId = event.room.name.replace(/^group-/, '');
    await this.groupCallService.handleLivekitParticipantLeft(
      callId, event.participant!.identity,
    );
  }
}
```

(Inject `GroupCallService` via `forwardRef` if circular.)

- [ ] **Step 3: Implement `handleLivekitParticipantLeft`**

```typescript
async handleLivekitParticipantLeft(callId: string, userId: string) {
  // Treat as a leave; idempotent
  try {
    await this.leaveCall(callId, userId);
  } catch (e: any) {
    // Forbidden if user not in call — fine
    if (e.status !== 403 && e.status !== 404) throw e;
  }
}
```

- [ ] **Step 4: Add unit test**

```typescript
describe('handleLivekitParticipantLeft', () => {
  it('delegates to leaveCall and swallows 403/404', async () => {
    service.leaveCall = jest.fn().mockRejectedValue({ status: 403 });
    await expect(service.handleLivekitParticipantLeft('c1', 'u1')).resolves.toBeUndefined();
  });

  it('rethrows non-auth errors', async () => {
    service.leaveCall = jest.fn().mockRejectedValue({ status: 500, message: 'db down' });
    await expect(service.handleLivekitParticipantLeft('c1', 'u1')).rejects.toThrow();
  });
});
```

- [ ] **Step 5: Run tests + build**

Run: `npm test -- group-call.service.spec.ts && npm run build`

Expected: PASS + 0 errors.

- [ ] **Step 6: Commit**

```bash
git add src/voice/voice.controller.ts src/voice/group-call/
git commit -m "feat(group-call): LiveKit webhook participant_left dispatch"
```

---

### Task 16: Backend e2e test

**Files:**
- Create: `test/group-call.e2e-spec.ts`

- [ ] **Step 1: Write e2e flow test**

Mirror existing e2e pattern. Skeleton:

```typescript
import { Test } from '@nestjs/testing';
import { INestApplication } from '@nestjs/common';
import * as request from 'supertest';
import { AppModule } from '../src/app.module';
import { PrismaService } from '../src/prisma/prisma.service';

describe('GroupCall e2e', () => {
  let app: INestApplication;
  let prisma: PrismaService;
  let hostToken: string;
  let aliceToken: string;
  let bobToken: string;
  let hostId: string;
  let aliceId: string;
  let bobId: string;

  beforeAll(async () => {
    const moduleRef = await Test.createTestingModule({ imports: [AppModule] }).compile();
    app = moduleRef.createNestApplication();
    await app.init();
    prisma = moduleRef.get(PrismaService);

    // Create three test users + JWT tokens via existing AuthService helper
    // (mirror pattern from existing e2e specs)
    ({ token: hostToken, userId: hostId } = await createTestUser(app));
    ({ token: aliceToken, userId: aliceId } = await createTestUser(app));
    ({ token: bobToken, userId: bobId } = await createTestUser(app));
  });

  afterAll(async () => { await app.close(); });

  it('full flow: create → join (alice) → decline (bob) → leave (alice) → ENDED', async () => {
    const create = await request(app.getHttpServer())
      .post('/voice/group-calls')
      .set('Authorization', `Bearer ${hostToken}`)
      .send({ inviteeIds: [aliceId, bobId] })
      .expect(201);
    const callId = create.body.groupCall.id;
    expect(create.body.livekitToken).toBeTruthy();

    await request(app.getHttpServer())
      .post(`/voice/group-calls/${callId}/join`)
      .set('Authorization', `Bearer ${aliceToken}`)
      .expect(200);

    await request(app.getHttpServer())
      .post(`/voice/group-calls/${callId}/decline`)
      .set('Authorization', `Bearer ${bobToken}`)
      .expect(200);

    await request(app.getHttpServer())
      .post(`/voice/group-calls/${callId}/leave`)
      .set('Authorization', `Bearer ${aliceToken}`)
      .expect(200);

    const dbCall = await prisma.groupCall.findUnique({
      where: { id: callId }, include: { invites: true },
    });
    expect(dbCall!.status).toBe('ENDED');
    expect(dbCall!.endedReason).toBe('all_left');
  });

  it('host_ended flow: host /end terminates call', async () => {
    const create = await request(app.getHttpServer())
      .post('/voice/group-calls')
      .set('Authorization', `Bearer ${hostToken}`)
      .send({ inviteeIds: [aliceId] })
      .expect(201);
    const callId = create.body.groupCall.id;

    await request(app.getHttpServer())
      .post(`/voice/group-calls/${callId}/end`)
      .set('Authorization', `Bearer ${hostToken}`)
      .expect(200);

    const dbCall = await prisma.groupCall.findUnique({ where: { id: callId } });
    expect(dbCall!.status).toBe('ENDED');
    expect(dbCall!.endedReason).toBe('host_ended');
  });

  it('non-host kick → 403', async () => {
    const create = await request(app.getHttpServer())
      .post('/voice/group-calls')
      .set('Authorization', `Bearer ${hostToken}`)
      .send({ inviteeIds: [aliceId, bobId] })
      .expect(201);
    const callId = create.body.groupCall.id;

    await request(app.getHttpServer())
      .post(`/voice/group-calls/${callId}/kick`)
      .set('Authorization', `Bearer ${aliceToken}`)
      .send({ userId: bobId })
      .expect(403);
  });
});
```

- [ ] **Step 2: Run e2e tests**

Run: `npm run test:e2e`

Expected: PASS for all 3 flows. (Requires Postgres test DB + LiveKit access; if e2e CI doesn't have LiveKit, mock `voice.deleteRoom`/`removeParticipant` at module override level.)

- [ ] **Step 3: Commit**

```bash
git add test/group-call.e2e-spec.ts
git commit -m "test(group-call): e2e — full flow, host_ended, kick-403"
```

---

## Phase B — Mobile data + BLoC

### Task 17: Freezed DTOs

**Files:**
- Create: `lib/features/voice/data/models/group_call_dto.dart`

- [ ] **Step 1: Create DTO file**

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'group_call_dto.freezed.dart';
part 'group_call_dto.g.dart';

enum GroupCallStatusDto { LOBBY, ACTIVE, ENDED }
enum GroupCallInviteStatusDto { CALLING, JOINED, DECLINED, TIMEOUT, LEFT }

@freezed
class UserSummaryDto with _$UserSummaryDto {
  const factory UserSummaryDto({
    required String id,
    required String displayName,
    String? avatarUrl,
  }) = _UserSummaryDto;
  factory UserSummaryDto.fromJson(Map<String, dynamic> json) =>
      _$UserSummaryDtoFromJson(json);
}

@freezed
class GroupCallInviteDto with _$GroupCallInviteDto {
  const factory GroupCallInviteDto({
    required String id,
    required String groupCallId,
    required String userId,
    required GroupCallInviteStatusDto status,
    required DateTime invitedAt,
    DateTime? respondedAt,
    DateTime? joinedAt,
    DateTime? leftAt,
    UserSummaryDto? user,
  }) = _GroupCallInviteDto;
  factory GroupCallInviteDto.fromJson(Map<String, dynamic> json) =>
      _$GroupCallInviteDtoFromJson(json);
}

@freezed
class GroupCallDto with _$GroupCallDto {
  const factory GroupCallDto({
    required String id,
    required String livekitRoomName,
    required String hostUserId,
    required GroupCallStatusDto status,
    required DateTime startedAt,
    DateTime? endedAt,
    String? endedReason,
    UserSummaryDto? host,
    @Default([]) List<GroupCallInviteDto> invites,
  }) = _GroupCallDto;
  factory GroupCallDto.fromJson(Map<String, dynamic> json) =>
      _$GroupCallDtoFromJson(json);
}

@freezed
class CreateGroupCallResponseDto with _$CreateGroupCallResponseDto {
  const factory CreateGroupCallResponseDto({
    required GroupCallDto groupCall,
    required String livekitToken,
    required String livekitWsUrl,
  }) = _CreateGroupCallResponseDto;
  factory CreateGroupCallResponseDto.fromJson(Map<String, dynamic> json) =>
      _$CreateGroupCallResponseDtoFromJson(json);
}

@freezed
class JoinGroupCallResponseDto with _$JoinGroupCallResponseDto {
  const factory JoinGroupCallResponseDto({
    required String livekitToken,
    required String livekitWsUrl,
  }) = _JoinGroupCallResponseDto;
  factory JoinGroupCallResponseDto.fromJson(Map<String, dynamic> json) =>
      _$JoinGroupCallResponseDtoFromJson(json);
}
```

- [ ] **Step 2: Generate Freezed/JSON code**

Run: `flutter pub run build_runner build --delete-conflicting-outputs`

Expected: `.freezed.dart` and `.g.dart` generated for `group_call_dto.dart`.

- [ ] **Step 3: Verify build**

Run: `flutter analyze lib/features/voice/data/models/group_call_dto.dart`

Expected: 0 issues.

- [ ] **Step 4: Commit**

```bash
git add lib/features/voice/data/models/
git commit -m "feat(group-call): Freezed DTOs"
```

---

### Task 18: Domain entities + repository interface

**Files:**
- Create: `lib/features/voice/domain/entities/group_call.dart`
- Create: `lib/features/voice/domain/entities/group_call_invite.dart`
- Create: `lib/features/voice/domain/repositories/group_call_repository.dart`

- [ ] **Step 1: Create `group_call_invite.dart`**

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'group_call_invite.freezed.dart';

enum GroupCallInviteStatus { calling, joined, declined, timeout, left }

@freezed
class GroupCallInvite with _$GroupCallInvite {
  const factory GroupCallInvite({
    required String id,
    required String userId,
    required String displayName,
    String? avatarUrl,
    required GroupCallInviteStatus status,
    DateTime? joinedAt,
    DateTime? leftAt,
  }) = _GroupCallInvite;
}
```

- [ ] **Step 2: Create `group_call.dart`**

```dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'group_call_invite.dart';

part 'group_call.freezed.dart';

enum GroupCallStatus { lobby, active, ended }

@freezed
class GroupCall with _$GroupCall {
  const factory GroupCall({
    required String id,
    required String livekitRoomName,
    required String hostUserId,
    required String hostDisplayName,
    String? hostAvatarUrl,
    required GroupCallStatus status,
    required DateTime startedAt,
    @Default([]) List<GroupCallInvite> invites,
  }) = _GroupCall;
}
```

- [ ] **Step 3: Create repository interface**

```dart
import '../entities/group_call.dart';

abstract class GroupCallRepository {
  /// Create a group call inviting [inviteeIds]. Returns call + livekitToken.
  Future<({GroupCall call, String livekitToken, String livekitWsUrl})> create({
    required List<String> inviteeIds,
  });

  Future<List<GroupCall>> getActiveCallsForMe();

  Future<GroupCall> getCall(String callId);

  Future<({String livekitToken, String livekitWsUrl})> join(String callId);

  Future<void> decline(String callId);

  Future<void> leave(String callId);

  Future<void> inviteMore(String callId, List<String> userIds);

  Future<void> kick(String callId, String userId);

  Future<void> muteAll(String callId);

  Future<void> end(String callId);
}
```

- [ ] **Step 4: Generate Freezed**

Run: `flutter pub run build_runner build --delete-conflicting-outputs`

- [ ] **Step 5: Commit**

```bash
git add lib/features/voice/domain/
git commit -m "feat(group-call): domain entities + repo interface"
```

---

### Task 19: Remote datasource + repository implementation

**Files:**
- Create: `lib/features/voice/data/datasources/group_call_remote_datasource.dart`
- Create: `lib/features/voice/data/repositories/group_call_repository_impl.dart`

- [ ] **Step 1: Create remote datasource**

```dart
import 'package:dio/dio.dart';
import '../models/group_call_dto.dart';

class GroupCallRemoteDatasource {
  final Dio _dio;
  GroupCallRemoteDatasource(this._dio);

  Future<CreateGroupCallResponseDto> create(List<String> inviteeIds) async {
    final r = await _dio.post('/voice/group-calls', data: {'inviteeIds': inviteeIds});
    return CreateGroupCallResponseDto.fromJson(r.data);
  }

  Future<List<GroupCallDto>> getActive() async {
    final r = await _dio.get('/voice/group-calls/active');
    return (r.data['calls'] as List).map((j) => GroupCallDto.fromJson(j)).toList();
  }

  Future<GroupCallDto> getCall(String id) async {
    final r = await _dio.get('/voice/group-calls/$id');
    return GroupCallDto.fromJson(r.data['groupCall']);
  }

  Future<JoinGroupCallResponseDto> join(String id) async {
    final r = await _dio.post('/voice/group-calls/$id/join');
    return JoinGroupCallResponseDto.fromJson(r.data);
  }

  Future<void> decline(String id) async {
    await _dio.post('/voice/group-calls/$id/decline');
  }

  Future<void> leave(String id) async {
    await _dio.post('/voice/group-calls/$id/leave');
  }

  Future<void> inviteMore(String id, List<String> userIds) async {
    await _dio.post('/voice/group-calls/$id/invite', data: {'userIds': userIds});
  }

  Future<void> kick(String id, String userId) async {
    await _dio.post('/voice/group-calls/$id/kick', data: {'userId': userId});
  }

  Future<void> muteAll(String id) async {
    await _dio.post('/voice/group-calls/$id/mute-all');
  }

  Future<void> end(String id) async {
    await _dio.post('/voice/group-calls/$id/end');
  }
}
```

- [ ] **Step 2: Create repository impl**

```dart
import '../../domain/entities/group_call.dart';
import '../../domain/entities/group_call_invite.dart';
import '../../domain/repositories/group_call_repository.dart';
import '../datasources/group_call_remote_datasource.dart';
import '../models/group_call_dto.dart';

class GroupCallRepositoryImpl implements GroupCallRepository {
  final GroupCallRemoteDatasource _remote;
  GroupCallRepositoryImpl(this._remote);

  @override
  Future<({GroupCall call, String livekitToken, String livekitWsUrl})> create({
    required List<String> inviteeIds,
  }) async {
    final r = await _remote.create(inviteeIds);
    return (
      call: _toEntity(r.groupCall),
      livekitToken: r.livekitToken,
      livekitWsUrl: r.livekitWsUrl,
    );
  }

  @override
  Future<List<GroupCall>> getActiveCallsForMe() async {
    final dtos = await _remote.getActive();
    return dtos.map(_toEntity).toList();
  }

  @override
  Future<GroupCall> getCall(String callId) async => _toEntity(await _remote.getCall(callId));

  @override
  Future<({String livekitToken, String livekitWsUrl})> join(String callId) async {
    final r = await _remote.join(callId);
    return (livekitToken: r.livekitToken, livekitWsUrl: r.livekitWsUrl);
  }

  @override
  Future<void> decline(String callId) => _remote.decline(callId);

  @override
  Future<void> leave(String callId) => _remote.leave(callId);

  @override
  Future<void> inviteMore(String callId, List<String> userIds) =>
      _remote.inviteMore(callId, userIds);

  @override
  Future<void> kick(String callId, String userId) => _remote.kick(callId, userId);

  @override
  Future<void> muteAll(String callId) => _remote.muteAll(callId);

  @override
  Future<void> end(String callId) => _remote.end(callId);

  GroupCall _toEntity(GroupCallDto d) => GroupCall(
    id: d.id,
    livekitRoomName: d.livekitRoomName,
    hostUserId: d.hostUserId,
    hostDisplayName: d.host?.displayName ?? '',
    hostAvatarUrl: d.host?.avatarUrl,
    status: GroupCallStatus.values.byName(d.status.name.toLowerCase()),
    startedAt: d.startedAt,
    invites: d.invites.map(_toInviteEntity).toList(),
  );

  GroupCallInvite _toInviteEntity(GroupCallInviteDto d) => GroupCallInvite(
    id: d.id,
    userId: d.userId,
    displayName: d.user?.displayName ?? '',
    avatarUrl: d.user?.avatarUrl,
    status: GroupCallInviteStatus.values.byName(d.status.name.toLowerCase()),
    joinedAt: d.joinedAt,
    leftAt: d.leftAt,
  );
}
```

- [ ] **Step 3: Verify analyze**

Run: `flutter analyze lib/features/voice/data/`

Expected: 0 issues.

- [ ] **Step 4: Commit**

```bash
git add lib/features/voice/data/
git commit -m "feat(group-call): datasource + repository impl"
```

---

### Task 20: BLoC events + states (Freezed sealed)

**Files:**
- Create: `lib/features/voice/presentation/bloc/group_call_event.dart`
- Create: `lib/features/voice/presentation/bloc/group_call_state.dart`

- [ ] **Step 1: Create events**

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'group_call_event.freezed.dart';

@freezed
class GroupCallEvent with _$GroupCallEvent {
  const factory GroupCallEvent.createCall(List<String> inviteeIds) = _CreateCall;
  const factory GroupCallEvent.joinCall(String callId) = _JoinCall;
  const factory GroupCallEvent.declineCall(String callId) = _DeclineCall;
  const factory GroupCallEvent.leaveCall(String callId) = _LeaveCall;
  const factory GroupCallEvent.inviteMore(String callId, List<String> userIds) = _InviteMore;
  const factory GroupCallEvent.kick(String callId, String userId) = _Kick;
  const factory GroupCallEvent.muteAll(String callId) = _MuteAll;
  const factory GroupCallEvent.endCall(String callId) = _EndCall;
  // Socket.io-driven:
  const factory GroupCallEvent.statusUpdated(Map<String, dynamic> payload) = _StatusUpdated;
  const factory GroupCallEvent.kicked(Map<String, dynamic> payload) = _Kicked;
  const factory GroupCallEvent.muteRequested(Map<String, dynamic> payload) = _MuteRequested;
  const factory GroupCallEvent.hostChanged(Map<String, dynamic> payload) = _HostChanged;
  const factory GroupCallEvent.ended(Map<String, dynamic> payload) = _Ended;
}
```

- [ ] **Step 2: Create states**

```dart
import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/entities/group_call.dart';

part 'group_call_state.freezed.dart';

@freezed
class GroupCallState with _$GroupCallState {
  const factory GroupCallState.idle() = _Idle;
  const factory GroupCallState.creating() = _Creating;
  const factory GroupCallState.inLobby({
    required GroupCall call,
    required String livekitToken,
    required String livekitWsUrl,
  }) = _InLobby;
  const factory GroupCallState.inActive({
    required GroupCall call,
    required String livekitToken,
    required String livekitWsUrl,
    @Default(false) bool muteRequestedByHost,
  }) = _InActive;
  const factory GroupCallState.ended(String reason) = _Ended;
  const factory GroupCallState.error(String message) = _Error;
}
```

- [ ] **Step 3: Generate Freezed**

Run: `flutter pub run build_runner build --delete-conflicting-outputs`

- [ ] **Step 4: Commit**

```bash
git add lib/features/voice/presentation/bloc/group_call_event.dart lib/features/voice/presentation/bloc/group_call_state.dart
git commit -m "feat(group-call): BLoC events + states"
```

---

### Task 21: GroupCallBloc — full state machine

**Files:**
- Create: `lib/features/voice/presentation/bloc/group_call_bloc.dart`

- [ ] **Step 1: Implement BLoC**

```dart
import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/services/socket_io_service.dart';
import '../../domain/repositories/group_call_repository.dart';
import '../../domain/entities/group_call.dart';
import '../../domain/entities/group_call_invite.dart';
import 'group_call_event.dart';
import 'group_call_state.dart';

class GroupCallBloc extends Bloc<GroupCallEvent, GroupCallState> {
  final GroupCallRepository _repo;
  final SocketIoService _socket;
  final List<StreamSubscription> _subs = [];

  GroupCallBloc(this._repo, this._socket) : super(const GroupCallState.idle()) {
    on<_CreateCall>(_onCreate);
    on<_JoinCall>(_onJoin);
    on<_DeclineCall>(_onDecline);
    on<_LeaveCall>(_onLeave);
    on<_InviteMore>(_onInviteMore);
    on<_Kick>(_onKick);
    on<_MuteAll>(_onMuteAll);
    on<_EndCall>(_onEnd);
    on<_StatusUpdated>(_onStatusUpdated);
    on<_Kicked>(_onKicked);
    on<_MuteRequested>(_onMuteRequested);
    on<_HostChanged>(_onHostChanged);
    on<_Ended>(_onEnded);

    _subscribeSocket();
  }

  void _subscribeSocket() {
    _subs.add(_socket.on('group_call_status').listen((p) => add(GroupCallEvent.statusUpdated(p))));
    _subs.add(_socket.on('group_call_kicked').listen((p) => add(GroupCallEvent.kicked(p))));
    _subs.add(_socket.on('group_call_mute_request').listen((p) => add(GroupCallEvent.muteRequested(p))));
    _subs.add(_socket.on('group_call_host_changed').listen((p) => add(GroupCallEvent.hostChanged(p))));
    _subs.add(_socket.on('group_call_ended').listen((p) => add(GroupCallEvent.ended(p))));
  }

  Future<void> _onCreate(_CreateCall e, Emitter<GroupCallState> emit) async {
    emit(const GroupCallState.creating());
    try {
      final r = await _repo.create(inviteeIds: e.inviteeIds);
      emit(GroupCallState.inLobby(
        call: r.call, livekitToken: r.livekitToken, livekitWsUrl: r.livekitWsUrl,
      ));
    } catch (err) {
      emit(GroupCallState.error('Не удалось создать звонок'));
    }
  }

  Future<void> _onJoin(_JoinCall e, Emitter<GroupCallState> emit) async {
    try {
      final r = await _repo.join(e.callId);
      final call = await _repo.getCall(e.callId);
      emit(GroupCallState.inActive(
        call: call, livekitToken: r.livekitToken, livekitWsUrl: r.livekitWsUrl,
      ));
    } catch (err) {
      emit(const GroupCallState.error('Не удалось присоединиться'));
    }
  }

  Future<void> _onDecline(_DeclineCall e, Emitter<GroupCallState> emit) async {
    try { await _repo.decline(e.callId); } catch (_) {}
    emit(const GroupCallState.idle());
  }

  Future<void> _onLeave(_LeaveCall e, Emitter<GroupCallState> emit) async {
    try { await _repo.leave(e.callId); } catch (_) {}
    emit(const GroupCallState.idle());
  }

  Future<void> _onInviteMore(_InviteMore e, Emitter<GroupCallState> emit) async {
    try { await _repo.inviteMore(e.callId, e.userIds); } catch (_) {}
  }

  Future<void> _onKick(_Kick e, Emitter<GroupCallState> emit) async {
    try { await _repo.kick(e.callId, e.userId); } catch (_) {}
  }

  Future<void> _onMuteAll(_MuteAll e, Emitter<GroupCallState> emit) async {
    try { await _repo.muteAll(e.callId); } catch (_) {}
  }

  Future<void> _onEnd(_EndCall e, Emitter<GroupCallState> emit) async {
    try { await _repo.end(e.callId); } catch (_) {}
    emit(const GroupCallState.idle());
  }

  void _onStatusUpdated(_StatusUpdated e, Emitter<GroupCallState> emit) {
    state.maybeWhen(
      inLobby: (call, token, ws) {
        if (call.id != e.payload['groupCallId']) return;
        final updatedInvites = (e.payload['invites'] as List)
            .map((j) => _parseInvite(j as Map<String, dynamic>)).toList();
        emit(GroupCallState.inLobby(
          call: call.copyWith(invites: updatedInvites),
          livekitToken: token, livekitWsUrl: ws,
        ));
      },
      inActive: (call, token, ws, muteFlag) {
        if (call.id != e.payload['groupCallId']) return;
        final updatedInvites = (e.payload['invites'] as List)
            .map((j) => _parseInvite(j as Map<String, dynamic>)).toList();
        emit(GroupCallState.inActive(
          call: call.copyWith(invites: updatedInvites),
          livekitToken: token, livekitWsUrl: ws, muteRequestedByHost: muteFlag,
        ));
      },
      orElse: () {},
    );
  }

  void _onKicked(_Kicked e, Emitter<GroupCallState> emit) {
    state.maybeWhen(
      inLobby: (call, _, __) {
        if (call.id == e.payload['groupCallId']) emit(const GroupCallState.idle());
      },
      inActive: (call, _, __, ___) {
        if (call.id == e.payload['groupCallId']) emit(const GroupCallState.idle());
      },
      orElse: () {},
    );
  }

  void _onMuteRequested(_MuteRequested e, Emitter<GroupCallState> emit) {
    state.maybeWhen(
      inActive: (call, token, ws, _) {
        if (call.id == e.payload['groupCallId']) {
          emit(GroupCallState.inActive(
            call: call, livekitToken: token, livekitWsUrl: ws, muteRequestedByHost: true,
          ));
        }
      },
      orElse: () {},
    );
  }

  void _onHostChanged(_HostChanged e, Emitter<GroupCallState> emit) {
    state.maybeWhen(
      inActive: (call, token, ws, mute) {
        if (call.id == e.payload['groupCallId']) {
          emit(GroupCallState.inActive(
            call: call.copyWith(hostUserId: e.payload['newHostUserId']),
            livekitToken: token, livekitWsUrl: ws, muteRequestedByHost: mute,
          ));
        }
      },
      orElse: () {},
    );
  }

  void _onEnded(_Ended e, Emitter<GroupCallState> emit) {
    state.maybeWhen(
      inLobby: (call, _, __) {
        if (call.id == e.payload['groupCallId']) {
          emit(GroupCallState.ended(e.payload['reason'] as String));
        }
      },
      inActive: (call, _, __, ___) {
        if (call.id == e.payload['groupCallId']) {
          emit(GroupCallState.ended(e.payload['reason'] as String));
        }
      },
      orElse: () {},
    );
  }

  GroupCallInvite _parseInvite(Map<String, dynamic> j) => GroupCallInvite(
    id: j['id'] as String,
    userId: j['userId'] as String,
    displayName: (j['user']?['displayName'] as String?) ?? '',
    avatarUrl: j['user']?['avatarUrl'] as String?,
    status: GroupCallInviteStatus.values.byName((j['status'] as String).toLowerCase()),
    joinedAt: j['joinedAt'] != null ? DateTime.parse(j['joinedAt']) : null,
    leftAt: j['leftAt'] != null ? DateTime.parse(j['leftAt']) : null,
  );

  @override
  Future<void> close() async {
    for (final s in _subs) { await s.cancel(); }
    return super.close();
  }
}
```

(Note: `SocketIoService.on(event)` returns a `Stream<Map<String, dynamic>>`. If existing API differs, adapt.)

- [ ] **Step 2: Verify analyze**

Run: `flutter analyze lib/features/voice/presentation/bloc/`

Expected: 0 issues.

- [ ] **Step 3: Commit**

```bash
git add lib/features/voice/presentation/bloc/group_call_bloc.dart
git commit -m "feat(group-call): BLoC state machine + Socket.io subscriptions"
```

---

### Task 22: Service locator wiring

**Files:**
- Modify: `lib/core/di/service_locator.dart`

- [ ] **Step 1: Register dependencies**

Find existing voice section, append:

```dart
// Group Call
sl.registerLazySingleton<GroupCallRemoteDatasource>(
  () => GroupCallRemoteDatasource(sl<Dio>()),
);
sl.registerLazySingleton<GroupCallRepository>(
  () => GroupCallRepositoryImpl(sl<GroupCallRemoteDatasource>()),
);
sl.registerFactory<GroupCallBloc>(
  () => GroupCallBloc(sl<GroupCallRepository>(), sl<SocketIoService>()),
);
```

(Add imports at top.)

- [ ] **Step 2: Verify analyze**

Run: `flutter analyze lib/core/di/`

Expected: 0 issues.

- [ ] **Step 3: Commit**

```bash
git add lib/core/di/service_locator.dart
git commit -m "feat(group-call): DI wiring"
```

---

## Phase C — Mobile UI

### Task 23: Multi-select picker screen

**Files:**
- Create: `lib/features/voice/presentation/screens/new_group_call_screen.dart`

- [ ] **Step 1: Implement screen**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/di/service_locator.dart';
import '../../../profile/domain/entities/contact.dart';
import '../../../profile/presentation/bloc/contacts_bloc.dart';
import '../bloc/group_call_bloc.dart';
import '../bloc/group_call_event.dart';
import '../bloc/group_call_state.dart';

class NewGroupCallScreen extends StatefulWidget {
  const NewGroupCallScreen({super.key});

  @override
  State<NewGroupCallScreen> createState() => _NewGroupCallScreenState();
}

class _NewGroupCallScreenState extends State<NewGroupCallScreen> {
  final Set<String> _selected = {};
  final TextEditingController _search = TextEditingController();
  late final GroupCallBloc _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = sl<GroupCallBloc>();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _bloc,
      child: BlocListener<GroupCallBloc, GroupCallState>(
        listener: (context, state) {
          state.maybeWhen(
            inLobby: (call, _, __) => context.go('/group-call/${call.id}'),
            error: (msg) => ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(msg))),
            orElse: () {},
          );
        },
        child: Scaffold(
          appBar: AppBar(
            title: Text('Выбрать участников (${_selected.length}/7)'),
            actions: [
              IconButton(
                icon: const Icon(Icons.check),
                onPressed: _selected.isEmpty ? null : _create,
              ),
            ],
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8),
                child: TextField(
                  controller: _search,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: 'Поиск',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              if (_selected.isNotEmpty)
                SizedBox(
                  height: 80,
                  child: BlocBuilder<ContactsBloc, ContactsState>(
                    builder: (context, state) {
                      final contacts = state.contacts.where((c) => _selected.contains(c.id)).toList();
                      return ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        itemCount: contacts.length,
                        itemBuilder: (_, i) {
                          final c = contacts[i];
                          return Padding(
                            padding: const EdgeInsets.all(4),
                            child: Chip(
                              avatar: CircleAvatar(child: Text(c.displayName.substring(0,1))),
                              label: Text(c.displayName),
                              deleteIcon: const Icon(Icons.close, size: 18),
                              onDeleted: () => setState(() => _selected.remove(c.id)),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              Expanded(
                child: BlocBuilder<ContactsBloc, ContactsState>(
                  builder: (context, state) {
                    final q = _search.text.toLowerCase();
                    final list = state.contacts.where((c) =>
                      q.isEmpty || c.displayName.toLowerCase().contains(q)).toList();
                    return ListView.builder(
                      itemCount: list.length,
                      itemBuilder: (_, i) {
                        final c = list[i];
                        final picked = _selected.contains(c.id);
                        return CheckboxListTile(
                          value: picked,
                          title: Text(c.displayName),
                          onChanged: (v) => setState(() {
                            if (v == true && _selected.length < 7) {
                              _selected.add(c.id);
                            } else {
                              _selected.remove(c.id);
                            }
                          }),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _create() {
    _bloc.add(GroupCallEvent.createCall(_selected.toList()));
  }
}
```

- [ ] **Step 2: Verify analyze**

Run: `flutter analyze lib/features/voice/presentation/screens/new_group_call_screen.dart`

Expected: 0 issues.

- [ ] **Step 3: Commit**

```bash
git add lib/features/voice/presentation/screens/new_group_call_screen.dart
git commit -m "feat(group-call): multi-select picker screen"
```

---

### Task 24: Lobby screen

**Files:**
- Create: `lib/features/voice/presentation/screens/group_call_lobby_screen.dart`
- Create: `lib/features/voice/presentation/widgets/participant_tile.dart`

- [ ] **Step 1: Create `participant_tile.dart`**

```dart
import 'package:flutter/material.dart';
import '../../domain/entities/group_call_invite.dart';

class ParticipantTile extends StatelessWidget {
  final String displayName;
  final String? avatarUrl;
  final GroupCallInviteStatus status;
  final bool isHost;
  final bool isActiveSpeaker;
  final VoidCallback? onLongPress;

  const ParticipantTile({
    super.key,
    required this.displayName,
    this.avatarUrl,
    required this.status,
    this.isHost = false,
    this.isActiveSpeaker = false,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    Widget overlay = const SizedBox.shrink();
    String label = displayName;
    Color? labelColor;
    switch (status) {
      case GroupCallInviteStatus.calling:
        overlay = const Positioned.fill(child: Center(child: Icon(Icons.phone, color: Colors.white70, size: 32)));
        label = 'звоним…';
        break;
      case GroupCallInviteStatus.declined:
        overlay = const Positioned.fill(child: Center(child: Icon(Icons.close, color: Colors.redAccent, size: 32)));
        label = 'отклонил';
        labelColor = Colors.redAccent;
        break;
      case GroupCallInviteStatus.timeout:
        overlay = const Positioned.fill(child: Center(child: Icon(Icons.access_time, color: Colors.orangeAccent, size: 32)));
        label = 'не ответил';
        labelColor = Colors.orangeAccent;
        break;
      case GroupCallInviteStatus.left:
        overlay = const Positioned.fill(child: Center(child: Icon(Icons.exit_to_app, color: Colors.grey, size: 32)));
        label = 'покинул';
        labelColor = Colors.grey;
        break;
      case GroupCallInviteStatus.joined:
        break;
    }

    return GestureDetector(
      onLongPress: onLongPress,
      child: Container(
        decoration: BoxDecoration(
          border: isActiveSpeaker
              ? Border.all(color: Colors.greenAccent, width: 3)
              : null,
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl!) : null,
                  child: avatarUrl == null ? Text(displayName.isEmpty ? '?' : displayName.substring(0, 1)) : null,
                ),
                overlay,
              ],
            ),
            const SizedBox(height: 6),
            Text(
              isHost ? '$label (host)' : label,
              style: TextStyle(color: labelColor),
              maxLines: 1, overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Create lobby screen**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../bloc/group_call_bloc.dart';
import '../bloc/group_call_event.dart';
import '../bloc/group_call_state.dart';
import '../widgets/participant_tile.dart';

class GroupCallLobbyScreen extends StatelessWidget {
  const GroupCallLobbyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<GroupCallBloc, GroupCallState>(
      listener: (context, state) {
        state.maybeWhen(
          inActive: (call, _, __, ___) => context.go('/group-call/${call.id}'),
          ended: (reason) => context.go('/calls'),
          idle: () => context.go('/calls'),
          orElse: () {},
        );
      },
      builder: (context, state) {
        return state.maybeWhen(
          inLobby: (call, _, __) => Scaffold(
            appBar: AppBar(title: const Text('Группа • Lobby')),
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Хост: ${call.hostDisplayName}', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 16),
                  Expanded(
                    child: GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3),
                      itemCount: call.invites.length,
                      itemBuilder: (_, i) {
                        final inv = call.invites[i];
                        return ParticipantTile(
                          displayName: inv.displayName,
                          avatarUrl: inv.avatarUrl,
                          status: inv.status,
                        );
                      },
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        icon: const Icon(Icons.cancel, color: Colors.red),
                        label: const Text('Отменить'),
                        onPressed: () => context.read<GroupCallBloc>().add(GroupCallEvent.endCall(call.id)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          orElse: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
        );
      },
    );
  }
}
```

- [ ] **Step 3: Verify analyze**

Run: `flutter analyze lib/features/voice/presentation/`

Expected: 0 issues.

- [ ] **Step 4: Commit**

```bash
git add lib/features/voice/presentation/
git commit -m "feat(group-call): lobby screen + participant tile"
```

---

### Task 25: Active call screen

**Files:**
- Create: `lib/features/voice/presentation/screens/group_call_active_screen.dart`
- Create: `lib/features/voice/presentation/widgets/host_actions_sheet.dart`

- [ ] **Step 1: Create `host_actions_sheet.dart`**

```dart
import 'package:flutter/material.dart';

class HostActionsSheet extends StatelessWidget {
  final String targetName;
  final VoidCallback onKick;
  const HostActionsSheet({super.key, required this.targetName, required this.onKick});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Wrap(
        children: [
          ListTile(
            leading: const Icon(Icons.person_remove, color: Colors.red),
            title: Text('Удалить $targetName из звонка'),
            onTap: () { Navigator.pop(context); onKick(); },
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Create active call screen**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:livekit_client/livekit_client.dart';
import '../bloc/group_call_bloc.dart';
import '../bloc/group_call_event.dart';
import '../bloc/group_call_state.dart';
import '../widgets/participant_tile.dart';
import '../widgets/host_actions_sheet.dart';
import '../../domain/entities/group_call_invite.dart';

class GroupCallActiveScreen extends StatefulWidget {
  final String callId;
  const GroupCallActiveScreen({super.key, required this.callId});

  @override
  State<GroupCallActiveScreen> createState() => _GroupCallActiveScreenState();
}

class _GroupCallActiveScreenState extends State<GroupCallActiveScreen> {
  Room? _room;
  Set<String> _activeSpeakers = {};
  bool _muted = false;

  @override
  void initState() {
    super.initState();
    _connect();
  }

  Future<void> _connect() async {
    final state = context.read<GroupCallBloc>().state;
    state.maybeWhen(
      inActive: (call, token, ws, _) async {
        final room = Room();
        await room.connect(ws, token);
        await room.localParticipant?.setMicrophoneEnabled(true);
        room.addListener(_onRoomChanged);
        room.events.listen((evt) {
          if (evt is ActiveSpeakersChanged) {
            setState(() {
              _activeSpeakers = evt.speakers.map((p) => p.identity).toSet();
            });
          }
        });
        setState(() => _room = room);
      },
      orElse: () {},
    );
  }

  void _onRoomChanged() => setState(() {});

  Future<void> _toggleMute() async {
    if (_room == null) return;
    final next = !_muted;
    await _room!.localParticipant?.setMicrophoneEnabled(!next);
    setState(() => _muted = next);
  }

  Future<void> _leave() async {
    await _room?.disconnect();
    if (!mounted) return;
    context.read<GroupCallBloc>().add(GroupCallEvent.leaveCall(widget.callId));
  }

  @override
  void dispose() {
    _room?.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<GroupCallBloc, GroupCallState>(
      listener: (context, state) {
        state.maybeWhen(
          ended: (reason) {
            _room?.disconnect();
            context.go('/calls');
          },
          idle: () {
            _room?.disconnect();
            context.go('/calls');
          },
          inActive: (_, __, ___, muteFlag) async {
            if (muteFlag && !_muted && _room != null) {
              await _room!.localParticipant?.setMicrophoneEnabled(false);
              setState(() => _muted = true);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Хост попросил всех замьютиться')),
                );
              }
            }
          },
          orElse: () {},
        );
      },
      builder: (context, state) {
        return state.maybeWhen(
          inActive: (call, _, __, ___) {
            final activeInvites = call.invites.where((i) =>
                i.status == GroupCallInviteStatus.joined ||
                i.status == GroupCallInviteStatus.calling).toList();
            final myUserId = _room?.localParticipant?.identity ?? '';
            final isHost = call.hostUserId == myUserId;

            return Scaffold(
              appBar: AppBar(title: Text('Группа • ${activeInvites.length + 1}')),
              body: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Expanded(
                      child: GridView.builder(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: activeInvites.length <= 4 ? 2 : 3,
                        ),
                        itemCount: activeInvites.length,
                        itemBuilder: (_, i) {
                          final inv = activeInvites[i];
                          return ParticipantTile(
                            displayName: inv.displayName,
                            avatarUrl: inv.avatarUrl,
                            status: inv.status,
                            isHost: inv.userId == call.hostUserId,
                            isActiveSpeaker: _activeSpeakers.contains(inv.userId),
                            onLongPress: isHost && inv.userId != myUserId
                                ? () => showModalBottomSheet(
                                      context: context,
                                      builder: (_) => HostActionsSheet(
                                        targetName: inv.displayName,
                                        onKick: () => context.read<GroupCallBloc>().add(
                                            GroupCallEvent.kick(call.id, inv.userId)),
                                      ),
                                    )
                                : null,
                          );
                        },
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        IconButton(
                          icon: Icon(_muted ? Icons.mic_off : Icons.mic),
                          onPressed: _toggleMute,
                        ),
                        if (isHost)
                          IconButton(
                            icon: const Icon(Icons.volume_off),
                            tooltip: 'Mute all',
                            onPressed: () => context.read<GroupCallBloc>()
                                .add(GroupCallEvent.muteAll(call.id)),
                          ),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.call_end, color: Colors.red),
                          label: const Text('Уйти'),
                          onPressed: _leave,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
          orElse: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
        );
      },
    );
  }
}
```

- [ ] **Step 3: Verify analyze**

Run: `flutter analyze lib/features/voice/presentation/screens/group_call_active_screen.dart`

Expected: 0 issues.

- [ ] **Step 4: Commit**

```bash
git add lib/features/voice/presentation/screens/group_call_active_screen.dart lib/features/voice/presentation/widgets/host_actions_sheet.dart
git commit -m "feat(group-call): active call screen + LiveKit connect + host kick"
```

---

### Task 26: Active call banner on Calls tab

**Files:**
- Create: `lib/features/voice/presentation/widgets/active_group_call_banner.dart`
- Modify: `lib/features/voice/presentation/screens/calls_screen.dart`

- [ ] **Step 1: Create banner widget**

```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/di/service_locator.dart';
import '../../domain/entities/group_call.dart';
import '../../domain/repositories/group_call_repository.dart';

class ActiveGroupCallBanner extends StatefulWidget {
  const ActiveGroupCallBanner({super.key});

  @override
  State<ActiveGroupCallBanner> createState() => _ActiveGroupCallBannerState();
}

class _ActiveGroupCallBannerState extends State<ActiveGroupCallBanner> {
  List<GroupCall> _calls = [];

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    try {
      final calls = await sl<GroupCallRepository>().getActiveCallsForMe();
      if (mounted) setState(() => _calls = calls);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (_calls.isEmpty) return const SizedBox.shrink();
    final c = _calls.first;
    return Material(
      color: Colors.greenAccent.shade400,
      child: InkWell(
        onTap: () => context.go('/group-call/${c.id}'),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              const Icon(Icons.group, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Активный звонок: ${c.hostDisplayName} + ${c.invites.length}',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              const Icon(Icons.arrow_forward, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Insert into Calls tab**

Modify `calls_screen.dart`. At the top of the body Column (above existing call history list), insert:

```dart
const ActiveGroupCallBanner(),
```

Add `import` at top.

Also add a "+" FloatingActionButton or AppBar action that pushes `/new-group-call`:

```dart
floatingActionButton: FloatingActionButton(
  child: const Icon(Icons.add_call),
  onPressed: () => context.go('/new-group-call'),
),
```

(Adjust to match existing UI shell.)

- [ ] **Step 3: Verify analyze**

Run: `flutter analyze lib/features/voice/presentation/`

Expected: 0 issues.

- [ ] **Step 4: Commit**

```bash
git add lib/features/voice/presentation/
git commit -m "feat(group-call): active call banner + entry point on Calls tab"
```

---

### Task 27: Routing — add new routes

**Files:**
- Modify: `lib/core/router/app_router.dart`

- [ ] **Step 1: Register new routes**

Find the existing `GoRouter` config; add inside `routes`:

```dart
GoRoute(
  path: '/new-group-call',
  builder: (context, state) => const NewGroupCallScreen(),
),
GoRoute(
  path: '/group-call/:id',
  builder: (context, state) {
    final id = state.pathParameters['id']!;
    final bloc = sl<GroupCallBloc>();
    // If state is not InActive (deep link / cold start), trigger join
    if (bloc.state is! _InActive && bloc.state is! _InLobby) {
      bloc.add(GroupCallEvent.joinCall(id));
    }
    return BlocProvider.value(
      value: bloc,
      child: GroupCallActiveScreen(callId: id),
    );
  },
),
```

(Lobby vs Active — lobby is reached via the `inLobby` state from `createCall`; route always shows Active screen but the BLoC state machine ensures the user enters via the right path.)

If lobby needs a dedicated route (cleaner UX), add:

```dart
GoRoute(
  path: '/group-call/:id/lobby',
  builder: (context, state) => BlocProvider.value(
    value: sl<GroupCallBloc>(),
    child: const GroupCallLobbyScreen(),
  ),
),
```

…and have `_onCreate` listener push `/group-call/:id/lobby` on success.

- [ ] **Step 2: Verify analyze + cold-start build**

Run: `flutter analyze lib/core/router/`

Expected: 0 issues.

- [ ] **Step 3: Commit**

```bash
git add lib/core/router/app_router.dart
git commit -m "feat(group-call): routes /new-group-call + /group-call/:id"
```

---

### Task 28: VoIP/FCM dispatch for `group_call_invite`

**Files:**
- Modify: `lib/core/notifications/voip_handler.dart`
- Modify: `lib/core/notifications/fcm_handler.dart` (or matching Android service)

- [ ] **Step 1: Find existing 1-on-1 dispatch**

Run: `grep -rn "call_invite\\|onIncomingCall" lib/core/notifications/`

Identify the function that branches on `payload['type']`.

- [ ] **Step 2: Add `group_call_invite` branch**

```dart
final type = payload['type'] as String?;
switch (type) {
  case 'call_invite':
    // existing 1-on-1 flow (unchanged)
    break;
  case 'group_call_invite':
    final groupCallId = payload['groupCallId'] as String;
    final hostDisplay = (payload['host'] is Map)
        ? payload['host']['displayName'] as String
        : 'Unknown';
    final inviteeCount = payload['inviteeCount'] as int? ?? 1;
    final groupName = inviteeCount > 1 ? '$hostDisplay + ${inviteeCount - 1}' : hostDisplay;

    await CallKitService.instance.showIncomingCall(
      callId: groupCallId,
      callerName: groupName,
      isGroup: true,
    );

    CallKitService.instance.onAccept = () async {
      // Trigger BLoC join
      sl<GroupCallBloc>().add(GroupCallEvent.joinCall(groupCallId));
      // Routing happens in BLoC listener (state→inActive→navigate)
    };
    CallKitService.instance.onDecline = () async {
      try {
        await sl<GroupCallRepository>().decline(groupCallId);
      } catch (_) {}
    };
    break;
}
```

(Adjust to existing CallKitService API. Add `isGroup` parameter to `showIncomingCall` if needed; match how 1-on-1 sets caller text.)

- [ ] **Step 3: Mirror in Android FCM handler**

Same dispatch pattern for FCM payload.

- [ ] **Step 4: Verify analyze + manually trace flow**

Run: `flutter analyze lib/core/notifications/`

Expected: 0 issues.

- [ ] **Step 5: Commit**

```bash
git add lib/core/notifications/
git commit -m "feat(group-call): dispatch group_call_invite from VoIP/FCM"
```

---

### Task 29: CallStateService extension

**Files:**
- Modify: `lib/core/services/call_state_service.dart`

- [ ] **Step 1: Inspect existing service + add `activeGroupCallId`**

Add property + accessors:

```dart
String? _activeGroupCallId;
String? get activeGroupCallId => _activeGroupCallId;

void setActiveGroupCall(String? id) {
  _activeGroupCallId = id;
  notifyListeners();
}

bool get isInAnyCall => _active1on1CallId != null || _activeGroupCallId != null;
```

(Adapt to existing 1-on-1 field name.)

Wire into BLoC: in `_onCreate`/`_onJoin`, call `sl<CallStateService>().setActiveGroupCall(call.id)`. In `_onLeave`/`_onEnded`, set to `null`.

- [ ] **Step 2: Verify analyze**

Run: `flutter analyze lib/core/services/`

Expected: 0 issues.

- [ ] **Step 3: Commit**

```bash
git add lib/core/services/call_state_service.dart lib/features/voice/presentation/bloc/group_call_bloc.dart
git commit -m "feat(group-call): CallStateService tracks active group call"
```

---

### Task 30: L10n strings (ru + en)

**Files:**
- Modify: `lib/l10n/app_ru.arb`
- Modify: `lib/l10n/app_en.arb`

- [ ] **Step 1: Add Russian strings**

Append to `app_ru.arb`:

```json
{
  "groupCallNew": "Групповой звонок",
  "groupCallSelectParticipants": "Выбрать участников",
  "groupCallSelectedCount": "{n}/7",
  "@groupCallSelectedCount": { "placeholders": { "n": { "type": "int" } } },
  "groupCallSearch": "Поиск",
  "groupCallSelected": "Выбрано:",
  "groupCallContacts": "Контакты",
  "groupCallLobby": "Группа • Lobby",
  "groupCallHost": "Хост",
  "groupCallStatusCalling": "звоним…",
  "groupCallStatusDeclined": "отклонил",
  "groupCallStatusTimeout": "не ответил",
  "groupCallStatusLeft": "покинул",
  "groupCallCancel": "Отменить",
  "groupCallLeave": "Уйти",
  "groupCallMuteAll": "Заглушить всех",
  "groupCallMuteRequested": "Хост попросил всех замьютиться",
  "groupCallKickedYou": "Вас удалили из звонка",
  "groupCallKickConfirm": "Удалить {name} из звонка",
  "@groupCallKickConfirm": { "placeholders": { "name": { "type": "String" } } },
  "groupCallEnded": "Звонок завершён",
  "groupCallActiveBanner": "Активный звонок: {host} + {count}",
  "@groupCallActiveBanner": { "placeholders": { "host": { "type": "String" }, "count": { "type": "int" } } },
  "groupCallCreateError": "Не удалось создать звонок",
  "groupCallJoinError": "Не удалось присоединиться",
  "groupCallTitleWithCount": "Группа • {count}",
  "@groupCallTitleWithCount": { "placeholders": { "count": { "type": "int" } } },
  "groupCallAddParticipants": "Добавить участников"
}
```

- [ ] **Step 2: Add English strings**

Append to `app_en.arb` with same keys, English values:

```json
{
  "groupCallNew": "Group call",
  "groupCallSelectParticipants": "Select participants",
  "groupCallSelectedCount": "{n}/7",
  "@groupCallSelectedCount": { "placeholders": { "n": { "type": "int" } } },
  "groupCallSearch": "Search",
  "groupCallSelected": "Selected:",
  "groupCallContacts": "Contacts",
  "groupCallLobby": "Group • Lobby",
  "groupCallHost": "Host",
  "groupCallStatusCalling": "calling…",
  "groupCallStatusDeclined": "declined",
  "groupCallStatusTimeout": "no answer",
  "groupCallStatusLeft": "left",
  "groupCallCancel": "Cancel",
  "groupCallLeave": "Leave",
  "groupCallMuteAll": "Mute all",
  "groupCallMuteRequested": "Host asked everyone to mute",
  "groupCallKickedYou": "You were removed from the call",
  "groupCallKickConfirm": "Remove {name} from call",
  "@groupCallKickConfirm": { "placeholders": { "name": { "type": "String" } } },
  "groupCallEnded": "Call ended",
  "groupCallActiveBanner": "Active call: {host} + {count}",
  "@groupCallActiveBanner": { "placeholders": { "host": { "type": "String" }, "count": { "type": "int" } } },
  "groupCallCreateError": "Could not create call",
  "groupCallJoinError": "Could not join call",
  "groupCallTitleWithCount": "Group • {count}",
  "@groupCallTitleWithCount": { "placeholders": { "count": { "type": "int" } } },
  "groupCallAddParticipants": "Add participants"
}
```

- [ ] **Step 3: Replace hard-coded strings in screens with `AppLocalizations.of(context).groupCall*`**

Search for hard-coded Russian strings in the new screens (e.g., 'Группа • Lobby', 'Отменить', 'Уйти') and replace with l10n calls.

- [ ] **Step 4: Regenerate l10n**

Run: `flutter gen-l10n`

Expected: 0 errors.

- [ ] **Step 5: Verify analyze**

Run: `flutter analyze`

Expected: 0 issues.

- [ ] **Step 6: Commit**

```bash
git add lib/l10n/ lib/features/voice/presentation/
git commit -m "feat(group-call): l10n ru+en + replace hard-coded strings"
```

---

## Phase D — QA & Deploy

### Task 31: BLoC unit tests

**Files:**
- Create: `test/features/voice/presentation/bloc/group_call_bloc_test.dart`

- [ ] **Step 1: Write tests**

```dart
import 'dart:async';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:taler_id_mobile/features/voice/domain/entities/group_call.dart';
import 'package:taler_id_mobile/features/voice/domain/repositories/group_call_repository.dart';
import 'package:taler_id_mobile/features/voice/presentation/bloc/group_call_bloc.dart';
import 'package:taler_id_mobile/features/voice/presentation/bloc/group_call_event.dart';
import 'package:taler_id_mobile/features/voice/presentation/bloc/group_call_state.dart';
import 'package:taler_id_mobile/core/services/socket_io_service.dart';

class _MockRepo extends Mock implements GroupCallRepository {}
class _MockSocket extends Mock implements SocketIoService {
  @override
  Stream<Map<String, dynamic>> on(String _) => const Stream.empty();
}

void main() {
  late _MockRepo repo;
  late _MockSocket socket;

  setUp(() {
    repo = _MockRepo();
    socket = _MockSocket();
  });

  blocTest<GroupCallBloc, GroupCallState>(
    'createCall: idle → creating → inLobby on success',
    build: () => GroupCallBloc(repo, socket),
    setUp: () {
      when(() => repo.create(inviteeIds: ['u1'])).thenAnswer((_) async => (
        call: GroupCall(
          id: 'c1', livekitRoomName: 'group-c1', hostUserId: 'host',
          hostDisplayName: 'Host', status: GroupCallStatus.lobby,
          startedAt: DateTime(2026, 4, 29),
        ),
        livekitToken: 'jwt', livekitWsUrl: 'ws://lk',
      ));
    },
    act: (bloc) => bloc.add(const GroupCallEvent.createCall(['u1'])),
    expect: () => [
      const GroupCallState.creating(),
      isA<_InLobby>(),
    ],
  );

  blocTest<GroupCallBloc, GroupCallState>(
    'createCall: idle → creating → error on failure',
    build: () => GroupCallBloc(repo, socket),
    setUp: () {
      when(() => repo.create(inviteeIds: ['u1'])).thenThrow(Exception('boom'));
    },
    act: (bloc) => bloc.add(const GroupCallEvent.createCall(['u1'])),
    expect: () => [
      const GroupCallState.creating(),
      isA<_Error>(),
    ],
  );

  blocTest<GroupCallBloc, GroupCallState>(
    'kicked event in inActive → emits idle',
    build: () => GroupCallBloc(repo, socket),
    seed: () => GroupCallState.inActive(
      call: GroupCall(
        id: 'c1', livekitRoomName: 'group-c1', hostUserId: 'host',
        hostDisplayName: 'Host', status: GroupCallStatus.active,
        startedAt: DateTime(2026, 4, 29),
      ),
      livekitToken: 'jwt', livekitWsUrl: 'ws://lk',
    ),
    act: (bloc) => bloc.add(GroupCallEvent.kicked({'groupCallId': 'c1', 'by': 'host'})),
    expect: () => [const GroupCallState.idle()],
  );
}
```

- [ ] **Step 2: Run tests**

Run: `flutter test test/features/voice/presentation/bloc/group_call_bloc_test.dart`

Expected: 3/3 PASS.

- [ ] **Step 3: Commit**

```bash
git add test/features/voice/
git commit -m "test(group-call): BLoC unit tests"
```

---

### Task 32: Smoke test script (Node.js, taler_id_tests)

**Files:**
- Create: `~/Downloads/taler_id_tests/test/group-calls.test.js`
- Modify: `~/Downloads/taler_id_tests/package.json`

- [ ] **Step 1: Create smoke script**

```javascript
const axios = require('axios');
const { io } = require('socket.io-client');

const BASE = process.env.BASE_URL || 'https://staging.id.taler.tirol';

async function login(email, password) {
  const r = await axios.post(`${BASE}/auth/login`, { email, password });
  return r.data.accessToken;
}

async function main() {
  // Use 2 known test accounts; a 3rd would be ideal — borrow if available.
  const hostToken = await login('integration_test@taler-test.com', 'IntegrationTest123!');
  const inviteeToken = await login('integration_test_2@taler-test.com', 'IntegrationTest123!');

  const me = await axios.get(`${BASE}/profile`, { headers: { Authorization: `Bearer ${hostToken}` } });
  const otherProfile = await axios.get(`${BASE}/profile`, { headers: { Authorization: `Bearer ${inviteeToken}` } });
  const inviteeId = otherProfile.data.id;

  // 1. Create
  const create = await axios.post(`${BASE}/voice/group-calls`, { inviteeIds: [inviteeId] }, {
    headers: { Authorization: `Bearer ${hostToken}` },
  });
  console.log(`✓ Created call ${create.data.groupCall.id}, status=${create.data.groupCall.status}`);
  if (create.data.groupCall.status !== 'LOBBY') throw new Error('expected LOBBY');
  const callId = create.data.groupCall.id;

  // 2. GET active (host)
  const active = await axios.get(`${BASE}/voice/group-calls/active`, {
    headers: { Authorization: `Bearer ${hostToken}` },
  });
  if (!active.data.calls.find(c => c.id === callId)) throw new Error('host should see own call');
  console.log('✓ Active list returns the call');

  // 3. Join (invitee)
  await axios.post(`${BASE}/voice/group-calls/${callId}/join`, {}, {
    headers: { Authorization: `Bearer ${inviteeToken}` },
  });
  console.log('✓ Invitee joined');

  // 4. Detail check
  const detail = await axios.get(`${BASE}/voice/group-calls/${callId}`, {
    headers: { Authorization: `Bearer ${hostToken}` },
  });
  if (detail.data.groupCall.status !== 'ACTIVE') throw new Error('expected ACTIVE');
  console.log('✓ Status is ACTIVE');

  // 5. Leave (invitee)
  await axios.post(`${BASE}/voice/group-calls/${callId}/leave`, {}, {
    headers: { Authorization: `Bearer ${inviteeToken}` },
  });
  // 6. Leave (host)
  await axios.post(`${BASE}/voice/group-calls/${callId}/leave`, {}, {
    headers: { Authorization: `Bearer ${hostToken}` },
  });

  // 7. Detail — should be ENDED
  const finalState = await axios.get(`${BASE}/voice/group-calls/${callId}`, {
    headers: { Authorization: `Bearer ${hostToken}` },
  });
  if (finalState.data.groupCall.status !== 'ENDED') throw new Error('expected ENDED');
  if (finalState.data.groupCall.endedReason !== 'all_left') throw new Error('expected all_left');
  console.log(`✓ Call ENDED reason=${finalState.data.groupCall.endedReason}`);

  console.log('\n✅ All group call smoke tests passed');
}

main().catch((e) => { console.error('❌', e.response?.data || e.message); process.exit(1); });
```

- [ ] **Step 2: Add script to package.json**

```json
{
  "scripts": {
    "test:group-calls": "BASE_URL=https://staging.id.taler.tirol node test/group-calls.test.js",
    "test:group-calls:prod": "BASE_URL=https://id.taler.tirol node test/group-calls.test.js"
  }
}
```

- [ ] **Step 3: Run on DEV (after Task 33 deploy)**

Run: `cd ~/Downloads/taler_id_tests && npm run test:group-calls`

Expected: `✅ All group call smoke tests passed`. (Defer running until Task 33 backend deploy.)

- [ ] **Step 4: Commit**

```bash
cd ~/Downloads/taler_id_tests
git add test/group-calls.test.js package.json
git commit -m "test(group-call): smoke test script"
```

---

### Task 33: Prisma migrate + backend deploy DEV

**Files:** none new. Operational task.

- [ ] **Step 1: SSH to DEV server**

Run: `ssh dvolkov@89.169.55.217`

- [ ] **Step 2: Pull, install deps, migrate, build, restart**

```bash
cd ~/taler-id
git pull
npm install
npx prisma migrate deploy
npm run build
pm2 restart taler-id-dev
pm2 logs taler-id-dev --lines 50 --nostream
```

Expected:
- `npx prisma migrate deploy` reports `Applied migration <ts>_add_group_calls`
- `npm run build` reports 0 errors
- `pm2 restart` reports online
- Logs show no startup errors

- [ ] **Step 3: Run smoke from local**

```bash
cd ~/Downloads/taler_id_tests
npm run test:group-calls
```

Expected: `✅ All group call smoke tests passed`.

- [ ] **Step 4: Verify all existing tests still pass**

```bash
cd ~/Downloads/taler_id_tests
npm test                     # 29 tests
npm run test:voice           # 10 tests
npm run test:assistant       # 8 tests
npm run test:files           # 12 tests
npm run test:channels        # 23 tests
npm run test:billing         # 7 tests
```

Expected: all green. If any fail, `pm2 restart taler-id-dev` and re-check; investigate root cause if persistent.

- [ ] **Step 5: No commit needed (operational only)**

---

### Task 34: Mobile DEV APK build + manual smoke

**Files:** none new. Operational task.

- [ ] **Step 1: Build dev APK**

On DEV server:
```bash
ssh dvolkov@138.124.61.221
cd ~/taler_id_mobile
git checkout dev
git pull
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
flutter build apk --flavor dev --release -t lib/main_dev.dart \
  --dart-define=FLAVOR=dev --dart-define=BASE_URL=https://staging.id.taler.tirol
cp build/app/outputs/flutter-apk/app-dev-release.apk /var/www/downloads/taler-id-dev.apk
```

- [ ] **Step 2: Install on emulator + manual smoke**

Locally:
```bash
flutter emulators --launch Pixel_XL_API_33
# wait ~15s
~/Library/Android/sdk/platform-tools/adb -s emulator-5554 install -r /path/to/app-dev-release.apk
```

- [ ] **Step 3: Manual flow on emulator**

1. Launch app, log in as `integration_test@taler-test.com`.
2. Tap "Calls" tab → "+" → "Group call" → select `integration_test_2` → tap ✓.
3. Verify lobby screen appears. Status = "звоним…" for invitee.
4. (No second emulator handy → invitee timeouts at 30s). Verify status changes to "не ответил" + call auto-ends with toast/redirect.
5. Repeat: this time tap "Cancel" on lobby → verify graceful exit.

- [ ] **Step 4: Run integration test**

```bash
cd ~/Downloads/taler_id_mobile
flutter test integration_test/app_test.dart --flavor dev --dart-define=FLAVOR=dev \
  --dart-define=BASE_URL=https://staging.id.taler.tirol -d emulator-5554
```

Expected: PASS.

- [ ] **Step 5: No commit needed**

---

### Task 35: Real-device test (iPhone + 2 Androids)

**Files:** none. QA only.

- [ ] **Step 1: Install dev builds on devices**

- iPhone (`00008101-000E21100202001E`): `flutter run --flavor dev -t lib/main_dev.dart --dart-define=FLAVOR=dev --dart-define=BASE_URL=https://staging.id.taler.tirol -d 00008101-000E21100202001E --release` (release, not debug, for VoIP push)
- 2× Android (real or emulator): install dev APK from `https://staging.id.taler.tirol/download/taler-id-dev.apk` or `adb install`.

- [ ] **Step 2: Test scenarios**

| # | Scenario | Expected |
|---|----------|----------|
| 1 | iPhone(host) creates with 2 Androids; both accept | Both Androids see Active screen + audio bidirectional |
| 2 | Bob declines while Alice accepts | Bob's CallKit closes; Alice in active screen alone with host; status updates show DECLINED |
| 3 | Bob doesn't answer 30s | Backend marks TIMEOUT; iPhone host sees status update |
| 4 | All 3 in active. iPhone(host) long-press Bob → Kick | Bob's screen closes with toast "Вас удалили"; LiveKit drops Bob |
| 5 | iPhone(host) press "Mute all" | Both Androids show toast + mic disabled |
| 6 | iPhone(host) leaves while 2 still in | Host transfers to next-joined; Android sees `host_changed` event; the new host sees +invite/+kick/+mute-all buttons |
| 7 | Last Android leaves | Call ends `all_left`; everyone redirected to Calls tab |

- [ ] **Step 3: If any test fails**

- Reproduce on emulator if possible; check `pm2 logs taler-id-dev` for backend errors.
- Open issue in spec / plan for follow-up; do **not** deploy to PROD until all 7 pass.

- [ ] **Step 4: No commit needed**

---

### Task 36: Pre-PROD checklist + PROD deploy gate

**Files:** none. Final gate.

- [ ] **Step 1: PROD readiness checklist**

- [ ] All 7 real-device scenarios passed
- [ ] All `~/Downloads/taler_id_tests/` smoke tests pass on DEV
- [ ] Mobile integration test passes on emulator
- [ ] No new Sentry errors on DEV for 24h after deploy
- [ ] LiveKit webhook config verified (`participant_left` events firing for `group-*` rooms — check `pm2 logs`)
- [ ] BullMQ queue `group-call-timeouts` healthy (no DLQ buildup; check via `pm2 logs taler-id-dev | grep timeout-invite`)
- [ ] CallKit on iPhone shows "Группа: + N ещё" correctly
- [ ] FCM banner on Android shows correct host displayName
- [ ] `mute-all` rate-limit (10s) works
- [ ] `inviteMore` rejects with 409 when room would exceed 8

- [ ] **Step 2: Document in CLAUDE.md (mobile repo)**

Append to `CLAUDE.md` "Структура мобилки" section:

```markdown
- `lib/features/voice/presentation/screens/new_group_call_screen.dart` — multi-select для group call
- `lib/features/voice/presentation/screens/group_call_lobby_screen.dart` — лобби со статусами
- `lib/features/voice/presentation/screens/group_call_active_screen.dart` — активная group комната
```

Append a new "Group voice room" section briefly summarizing:
- Phase 1 of Zoom-style rooms initiative (spec at `docs/superpowers/specs/2026-04-29-group-voice-room-design.md`)
- 3-8 participants, audio-only
- Light host privileges (invite/kick/soft-mute)
- BullMQ-driven 30s ringing timeout
- Reuses existing CallKit/Socket.io/LiveKit infra

- [ ] **Step 3: Deploy to PROD only after explicit user approval**

When user gives go-ahead:
```bash
ssh dvolkov@138.124.61.221
cd ~/taler-id
git pull
npm install
npx prisma migrate deploy
npm run build
pm2 restart taler-id     # PROD process id=0
pm2 logs taler-id --lines 50 --nostream
```

Then build PROD APK + iOS:
- Android: `flutter build apk --flavor prod --release --dart-define=FLAVOR=prod` → `cp` to `/var/www/downloads/taler-id.apk`
- iOS: `flutter build ipa --release --export-options-plist ios/ExportOptions.plist` → `xcrun altool --upload-app …` → set TestFlight release notes via App Store Connect API (per CLAUDE.md instruction)

- [ ] **Step 4: Run PROD smoke tests**

```bash
cd ~/Downloads/taler_id_tests
npm run test:prod
npm run test:voice:prod
npm run test:group-calls:prod
# … (full suite per CLAUDE.md)
```

Expected: all green.

- [ ] **Step 5: Commit CLAUDE.md update**

```bash
cd ~/Downloads/taler_id_mobile
git add CLAUDE.md
git commit -m "docs: group voice room (Phase 1) section"
```

---

## Self-Review (post-write)

Performed inline; result: clean.

**Spec coverage check (against `docs/superpowers/specs/2026-04-29-group-voice-room-design.md`):**

- §1 Architecture → Tasks 2 (module scaffold), 4 (service), 10 (controller), 13 (gateway). ✓
- §2 Data model → Task 1 (Prisma schema + migration). ✓
- §3 API surface → Task 10 (controller — all 8 endpoints), Tasks 4-9 (services per endpoint). ✓
- §4 Lobby state machine + timeouts → Tasks 4 (creation schedules timeout), 11 (BullMQ processor), 12 (cron cleanup). ✓
- §5 Mid-call host actions → Task 9 (inviteMore/kick/muteAll/forceEnd) + Task 10 (controller routes + host guard). ✓
- §6 Mobile UI flow → Tasks 23 (picker), 24 (lobby), 25 (active), 26 (banner). ✓
- §7 Reuse vs new code → Task 3 (VoiceService.generateGroupCallToken extension), Task 13 (MessengerGateway.emitToUser), Task 28 (CallKit/FCM dispatch). ✓
- §8.1 Error handling → covered in service implementations (idempotency, ConflictException, NotFound, etc.). ✓
- §8.4 Tests → Tasks 4-9 (unit), Task 16 (e2e), Task 31 (BLoC tests), Task 32 (smoke), Tasks 34-35 (manual). ✓
- §8.5 Deployment → Task 33 (DEV deploy), Task 36 (PROD gate). ✓
- §8.6 Rollback → Implicit via PM2 restart + feature flag (note: feature flag not explicitly added — engineer may add `AppConfig.groupCallsEnabled` if desired; otherwise PM2 rollback to previous release suffices since group-call routes are additive).
- §9 Open questions → Task 13 (verify `emitToUser`), Task 15 (verify webhook), Task 29 (CallStateService), Task 11 (BullMQ already verified at install). ✓
- §10 Non-goals → respected; nothing in plan touches video, breakout, recording, AI, guests.

**Type consistency check:**

- `GroupCallStatus` enum used consistently across Tasks 1, 4-9, 11, 12.
- `GroupCallInviteStatus` enum used consistently.
- `livekitRoomName` field always set as `group-${id}` (Task 4, 6, 13, 15).
- `livekitToken` and `livekitWsUrl` returned consistently from `createCall` (Task 4) and `joinCall` (Task 6).
- Mobile entity names (`GroupCall`, `GroupCallInvite`, `GroupCallStatus.lobby/active/ended`, `GroupCallInviteStatus.calling/joined/...`) consistent across Tasks 17-25.

**Placeholder scan:**

- One pseudocode placeholder in Task 9 (`checkAndSetRateLimit` Redis call) — engineer instructed to wire to existing Redis client (acceptable since Redis client pattern is project-specific; not a TBD).
- Task 27 mentions "If state.maybeWhen…" pattern that may need fine-tuning if existing GoRouter uses redirects differently — annotated.
- No "TODO", "TBD", "FIXME" markers.

---

## Done — Execution Handoff

Plan complete and saved to [`docs/superpowers/plans/2026-04-29-group-voice-room.md`](2026-04-29-group-voice-room.md).

Two execution options:

1. **Subagent-Driven (recommended)** — I dispatch a fresh subagent per task, review between tasks, fast iteration.
2. **Inline Execution** — Execute tasks in this session using `executing-plans`, batch execution with checkpoints.

Which approach?

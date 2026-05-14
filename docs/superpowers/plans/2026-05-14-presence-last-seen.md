# Presence / Last Seen Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Show whether a chat partner is online right now (or, if offline, when they were last seen) in the chat AppBar and user-profile screen, with three-tier privacy (`EVERYONE` / `CONTACTS` / `NOBODY`).

**Architecture:** Foreground heartbeat from the mobile (`POST /presence/ping` every 30 s) sets a Redis key `presence:online:<userId>` with 90 s TTL and updates `Profile.lastSeenAt` (DB-write throttled to once per 60 s per user). Chat header and profile screen poll `GET /presence/:userId` every 30 s while visible. Server enforces privacy by reading `Profile.lastSeenPrivacy` and (for `CONTACTS`) checking the bidirectional `ContactRequest` table.

**Tech Stack:** NestJS + Prisma + PostgreSQL + Redis (`ioredis` via `RedisService`); Flutter + Freezed + Hive (none used here) + GetIt; integration tests in TS via `ts-node`.

**Spec:** `docs/superpowers/specs/2026-05-14-presence-last-seen-design.md`

---

## File Structure

### Backend (`~/taler-id/`)

| Path | Responsibility |
|---|---|
| `prisma/schema.prisma` *(modify)* | Add `LastSeenPrivacy` enum + `lastSeenAt` / `lastSeenPrivacy` columns to `Profile`. |
| `prisma/migrations/<ts>_add_presence/migration.sql` *(new, generated)* | Forward migration. |
| `src/presence/presence.module.ts` *(new)* | Wires controller + service; imports `PrismaModule`, `RedisModule`. |
| `src/presence/presence.controller.ts` *(new)* | `POST /presence/ping`, `GET /presence/me`, `GET /presence/:userId` (`Throttle`-decorated). |
| `src/presence/presence.service.ts` *(new)* | Redis read/write + Prisma read/update + privacy filter. |
| `src/presence/presence.service.spec.ts` *(new)* | 8 unit tests of service. |
| `src/profile/dto/update-profile.dto.ts` *(modify)* | Accept optional `lastSeenPrivacy: 'EVERYONE' \| 'CONTACTS' \| 'NOBODY'`. |
| `src/profile/profile.service.ts` *(modify)* | Pass `lastSeenPrivacy` through to Prisma update. |
| `src/app.module.ts` *(modify)* | Register `PresenceModule`. |

### Mobile (`~/Downloads/taler_id_mobile/`)

| Path | Responsibility |
|---|---|
| `lib/features/presence/domain/entities/presence_entity.dart` *(new)* | Freezed entity. |
| `lib/features/presence/domain/repositories/i_presence_repository.dart` *(new)* | Abstract interface. |
| `lib/features/presence/data/datasources/presence_remote_datasource.dart` *(new)* | Dio wrappers for 3 endpoints. |
| `lib/features/presence/data/repositories/presence_repository_impl.dart` *(new)* | Concrete repo. |
| `lib/features/presence/presentation/services/presence_heartbeat_service.dart` *(new)* | Lifecycle-aware 30 s ping loop. |
| `lib/features/presence/presentation/widgets/presence_label.dart` *(new)* | Polling widget rendering presence text. |
| `lib/core/utils/presence_format.dart` *(new)* | Pure formatter `formatLastSeen(entity, l10n, now)`. |
| `lib/l10n/app_ru.arb`, `app_en.arb` *(modify)* | 7 new strings. |
| `lib/core/di/service_locator.dart` *(modify)* | Register `IPresenceRepository`, `PresenceHeartbeatService`. |
| `lib/main.dart` *(modify)* | Start `PresenceHeartbeatService` after DI setup. |
| `lib/features/messenger/presentation/screens/chat_room_screen.dart` *(modify ~line 1782-1801)* | Insert `PresenceLabel` under partner name in AppBar (only when `conv?.type == 'DIRECT'`). |
| `lib/features/messenger/presentation/screens/user_profile_screen.dart` *(modify)* | Insert `PresenceLabel` above bio (skip for self). |
| `lib/features/profile/presentation/screens/edit_profile_screen.dart` *(modify)* | Privacy section + dropdown; include in save payload. |

### API integration tests (`~/Downloads/taler_id_tests/`)

| Path | Responsibility |
|---|---|
| `presence_test.ts` *(new)* | 5-scenario integration test. |
| `package.json` *(modify)* | Add `test:presence` + `test:presence:prod` scripts. |

---

## Task 1: Prisma schema + migration

**Repo:** `~/taler-id/` (branch `dev`)

**Files:**
- Modify: `prisma/schema.prisma`
- Create: `prisma/migrations/<auto-named>/migration.sql`

- [ ] **Step 1: Add enum + columns to `prisma/schema.prisma`**

Locate the `Profile` model (search for `^model Profile`). Add the two new fields at the bottom of the model body, immediately before the closing `}`:

```prisma
  lastSeenAt        DateTime?
  lastSeenPrivacy   LastSeenPrivacy @default(EVERYONE)
```

Then, anywhere in the enums section (e.g. right after `enum KycStatus`), add:

```prisma
enum LastSeenPrivacy {
  EVERYONE
  CONTACTS
  NOBODY
}
```

- [ ] **Step 2: Generate the migration**

Run: `cd ~/taler-id && DATABASE_URL="$DATABASE_URL" npx prisma migrate dev --name add_presence_last_seen --create-only`
Expected: Prisma creates `prisma/migrations/<timestamp>_add_presence_last_seen/migration.sql` with `CREATE TYPE "LastSeenPrivacy"` and `ALTER TABLE "Profile"` statements. The `--create-only` flag means it generates the file without applying.

- [ ] **Step 3: Apply migration to local DEV-mirror DB**

Run: `cd ~/taler-id && npx prisma migrate dev`
Expected: applies the new migration to local DB, regenerates Prisma client.

- [ ] **Step 4: Regenerate Prisma client (if not done by step 3)**

Run: `cd ~/taler-id && npx prisma generate`
Expected: `Generated Prisma Client (...) to ./node_modules/@prisma/client`.

- [ ] **Step 5: Run existing test suite to verify no regression**

Run: `cd ~/taler-id && npm test -- --testPathIgnorePatterns=node_modules 2>&1 | tail -10`
Expected: existing tests pass; no new tests fail.

- [ ] **Step 6: Commit**

```bash
cd ~/taler-id
git add prisma/schema.prisma prisma/migrations/
git commit -m "feat(presence): add Profile.lastSeenAt + lastSeenPrivacy enum"
```

---

## Task 2: PresenceService + Controller + Unit Tests

**Repo:** `~/taler-id/`

**Files:**
- Create: `src/presence/presence.module.ts`
- Create: `src/presence/presence.service.ts`
- Create: `src/presence/presence.service.spec.ts`
- Create: `src/presence/presence.controller.ts`
- Modify: `src/app.module.ts`

- [ ] **Step 1: Write the failing service test**

Create `src/presence/presence.service.spec.ts`:

```typescript
import { Test, TestingModule } from '@nestjs/testing';
import { PresenceService } from './presence.service';
import { PrismaService } from '../prisma/prisma.service';
import { RedisService } from '../redis/redis.service';

describe('PresenceService', () => {
  let service: PresenceService;

  const mockRedis = {
    setEx: jest.fn().mockResolvedValue(undefined),
    get: jest.fn(),
    getClient: jest.fn(),
  };

  const mockExists = jest.fn();
  mockRedis.getClient.mockReturnValue({ exists: mockExists });

  const mockPrisma = {
    profile: {
      findUnique: jest.fn(),
      update: jest.fn().mockResolvedValue({}),
    },
    contactRequest: {
      findFirst: jest.fn(),
    },
  };

  beforeEach(async () => {
    jest.clearAllMocks();
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        PresenceService,
        { provide: PrismaService, useValue: mockPrisma },
        { provide: RedisService, useValue: mockRedis },
      ],
    }).compile();
    service = module.get(PresenceService);
  });

  describe('ping', () => {
    it('sets Redis online key with 90s TTL', async () => {
      mockRedis.get.mockResolvedValue(null);
      await service.ping('user-a');
      expect(mockRedis.setEx).toHaveBeenCalledWith('presence:online:user-a', 90, '1');
    });

    it('writes Profile.lastSeenAt + dbwrite throttle key on first call', async () => {
      mockRedis.get.mockResolvedValue(null);
      await service.ping('user-a');
      expect(mockPrisma.profile.update).toHaveBeenCalledWith({
        where: { userId: 'user-a' },
        data: { lastSeenAt: expect.any(Date) },
      });
      expect(mockRedis.setEx).toHaveBeenCalledWith('presence:dbwrite:user-a', 60, '1');
    });

    it('skips Profile update when throttle key exists', async () => {
      mockRedis.get.mockResolvedValue('1');
      await service.ping('user-a');
      expect(mockPrisma.profile.update).not.toHaveBeenCalled();
    });
  });

  describe('getPresence', () => {
    it('returns real data when target privacy is EVERYONE', async () => {
      mockPrisma.profile.findUnique.mockResolvedValue({
        lastSeenPrivacy: 'EVERYONE',
        lastSeenAt: new Date('2026-05-14T07:00:00Z'),
      });
      mockExists.mockResolvedValue(1);
      const r = await service.getPresence('viewer', 'target');
      expect(r).toEqual({ isOnline: true, lastSeenAt: '2026-05-14T07:00:00.000Z', hidden: false });
    });

    it('returns real data when target=CONTACTS and accepted contact exists', async () => {
      mockPrisma.profile.findUnique.mockResolvedValue({
        lastSeenPrivacy: 'CONTACTS',
        lastSeenAt: new Date('2026-05-14T07:00:00Z'),
      });
      mockPrisma.contactRequest.findFirst.mockResolvedValue({ id: 'cr-1' });
      mockExists.mockResolvedValue(0);
      const r = await service.getPresence('viewer', 'target');
      expect(r.hidden).toBe(false);
      expect(r.isOnline).toBe(false);
    });

    it('returns hidden=true when target=CONTACTS and no accepted contact', async () => {
      mockPrisma.profile.findUnique.mockResolvedValue({
        lastSeenPrivacy: 'CONTACTS',
        lastSeenAt: new Date(),
      });
      mockPrisma.contactRequest.findFirst.mockResolvedValue(null);
      const r = await service.getPresence('viewer', 'target');
      expect(r).toEqual({ isOnline: null, lastSeenAt: null, hidden: true });
    });

    it('returns hidden=true when target=NOBODY', async () => {
      mockPrisma.profile.findUnique.mockResolvedValue({
        lastSeenPrivacy: 'NOBODY',
        lastSeenAt: new Date(),
      });
      const r = await service.getPresence('viewer', 'target');
      expect(r).toEqual({ isOnline: null, lastSeenAt: null, hidden: true });
    });

    it('bypasses privacy when viewer === target (self)', async () => {
      mockPrisma.profile.findUnique.mockResolvedValue({
        lastSeenPrivacy: 'NOBODY',
        lastSeenAt: new Date('2026-05-14T07:00:00Z'),
      });
      mockExists.mockResolvedValue(1);
      const r = await service.getPresence('user-a', 'user-a');
      expect(r.hidden).toBe(false);
      expect(r.isOnline).toBe(true);
    });

    it('returns isOnline=false when Redis key absent but Profile has lastSeenAt', async () => {
      mockPrisma.profile.findUnique.mockResolvedValue({
        lastSeenPrivacy: 'EVERYONE',
        lastSeenAt: new Date('2026-05-14T07:00:00Z'),
      });
      mockExists.mockResolvedValue(0);
      const r = await service.getPresence('viewer', 'target');
      expect(r.isOnline).toBe(false);
      expect(r.lastSeenAt).toBe('2026-05-14T07:00:00.000Z');
    });

    it('returns isOnline=null lastSeenAt=null hidden=true when target profile not found', async () => {
      mockPrisma.profile.findUnique.mockResolvedValue(null);
      const r = await service.getPresence('viewer', 'target');
      expect(r).toEqual({ isOnline: null, lastSeenAt: null, hidden: true });
    });
  });
});
```

- [ ] **Step 2: Run test — expected to fail (service does not exist)**

Run: `cd ~/taler-id && npx jest presence.service.spec --testPathIgnorePatterns=node_modules 2>&1 | tail -15`
Expected: `Cannot find module './presence.service'` or `PresenceService is not a constructor`.

- [ ] **Step 3: Implement `presence.service.ts`**

Create `src/presence/presence.service.ts`:

```typescript
import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { RedisService } from '../redis/redis.service';

export interface PresenceResult {
  isOnline: boolean | null;
  lastSeenAt: string | null;
  hidden: boolean;
}

@Injectable()
export class PresenceService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly redis: RedisService,
  ) {}

  async ping(userId: string): Promise<void> {
    await this.redis.setEx(`presence:online:${userId}`, 90, '1');
    const throttleKey = `presence:dbwrite:${userId}`;
    const throttled = await this.redis.get(throttleKey);
    if (throttled) return;
    await this.redis.setEx(throttleKey, 60, '1');
    await this.prisma.profile.update({
      where: { userId },
      data: { lastSeenAt: new Date() },
    });
  }

  async getPresence(viewerId: string, targetUserId: string): Promise<PresenceResult> {
    const profile = await this.prisma.profile.findUnique({
      where: { userId: targetUserId },
      select: { lastSeenPrivacy: true, lastSeenAt: true },
    });
    if (!profile) return { isOnline: null, lastSeenAt: null, hidden: true };

    const isSelf = viewerId === targetUserId;
    if (!isSelf) {
      if (profile.lastSeenPrivacy === 'NOBODY') {
        return { isOnline: null, lastSeenAt: null, hidden: true };
      }
      if (profile.lastSeenPrivacy === 'CONTACTS') {
        const contact = await this.prisma.contactRequest.findFirst({
          where: {
            status: 'ACCEPTED',
            OR: [
              { senderId: viewerId, receiverId: targetUserId },
              { senderId: targetUserId, receiverId: viewerId },
            ],
          },
          select: { id: true },
        });
        if (!contact) return { isOnline: null, lastSeenAt: null, hidden: true };
      }
    }

    const online = await this.redis.getClient().exists(`presence:online:${targetUserId}`);
    return {
      isOnline: online === 1,
      lastSeenAt: profile.lastSeenAt ? profile.lastSeenAt.toISOString() : null,
      hidden: false,
    };
  }
}
```

- [ ] **Step 4: Run test — expected to pass**

Run: `cd ~/taler-id && npx jest presence.service.spec --testPathIgnorePatterns=node_modules 2>&1 | tail -10`
Expected: `Tests: 8 passed, 8 total`.

- [ ] **Step 5: Implement controller**

Create `src/presence/presence.controller.ts`:

```typescript
import { Controller, Get, Post, Param, HttpCode, UseGuards } from '@nestjs/common';
import { Throttle } from '@nestjs/throttler';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { PresenceService } from './presence.service';

@Controller('presence')
@UseGuards(JwtAuthGuard)
export class PresenceController {
  constructor(private readonly service: PresenceService) {}

  @Post('ping')
  @HttpCode(204)
  @Throttle({ default: { limit: 3, ttl: 30_000 } })
  async ping(@CurrentUser() user: any): Promise<void> {
    await this.service.ping(user.sub);
  }

  @Get('me')
  async getMe(@CurrentUser() user: any) {
    return this.service.getPresence(user.sub, user.sub);
  }

  @Get(':userId')
  async getOne(@CurrentUser() user: any, @Param('userId') userId: string) {
    return this.service.getPresence(user.sub, userId);
  }
}
```

- [ ] **Step 6: Implement module**

Create `src/presence/presence.module.ts`:

```typescript
import { Module } from '@nestjs/common';
import { PresenceController } from './presence.controller';
import { PresenceService } from './presence.service';
import { PrismaModule } from '../prisma/prisma.module';
import { RedisModule } from '../redis/redis.module';

@Module({
  imports: [PrismaModule, RedisModule],
  controllers: [PresenceController],
  providers: [PresenceService],
  exports: [PresenceService],
})
export class PresenceModule {}
```

- [ ] **Step 7: Register module in `src/app.module.ts`**

Locate the `imports: [` array in `@Module({...})` and add `PresenceModule` to it. Add the import at the top of the file: `import { PresenceModule } from './presence/presence.module';` next to the other module imports.

- [ ] **Step 8: Verify the full backend builds**

Run: `cd ~/taler-id && npm run build 2>&1 | tail -10`
Expected: `Successfully compiled` (no TypeScript errors).

- [ ] **Step 9: Commit**

```bash
cd ~/taler-id
git add src/presence/ src/app.module.ts
git commit -m "feat(presence): service + controller (ping, get, get/me) with privacy filter"
```

---

## Task 3: PATCH /profile accepts `lastSeenPrivacy`

**Repo:** `~/taler-id/`

**Files:**
- Modify: `src/profile/dto/update-profile.dto.ts`
- Modify: `src/profile/profile.service.ts`

- [ ] **Step 1: Extend the DTO**

In `src/profile/dto/update-profile.dto.ts`, add this field at the bottom of `UpdateProfileDto` (before the closing `}`):

```typescript
  @IsIn(['EVERYONE', 'CONTACTS', 'NOBODY'])
  @IsOptional()
  lastSeenPrivacy?: 'EVERYONE' | 'CONTACTS' | 'NOBODY';
```

The `IsIn` validator is already imported at the top — no change to imports needed.

- [ ] **Step 2: Verify that `profile.service.updateProfile` already passes the field through**

Open `src/profile/profile.service.ts` and locate `async updateProfile(userId: string, dto: UpdateProfileDto)`. The existing code likely does a `prisma.profile.update({ data: { ...dto } })`-style pass-through. If it uses an explicit field allow-list, add `lastSeenPrivacy` to that allow-list. Otherwise no change is needed.

If the method uses explicit field listing, the change looks like this (example pattern — adjust to existing code):

```typescript
data: {
  ...existingFields,
  ...(dto.lastSeenPrivacy !== undefined && { lastSeenPrivacy: dto.lastSeenPrivacy }),
}
```

- [ ] **Step 3: Build to verify**

Run: `cd ~/taler-id && npm run build 2>&1 | tail -5`
Expected: clean compile.

- [ ] **Step 4: Commit**

```bash
cd ~/taler-id
git add src/profile/
git commit -m "feat(profile): accept lastSeenPrivacy in PATCH /profile"
```

---

## Task 4: Mobile — entity + repository + DI

**Repo:** `~/Downloads/taler_id_mobile/` (branch `dev`)

**Files:**
- Create: `lib/features/presence/domain/entities/presence_entity.dart`
- Create: `lib/features/presence/domain/repositories/i_presence_repository.dart`
- Create: `lib/features/presence/data/datasources/presence_remote_datasource.dart`
- Create: `lib/features/presence/data/repositories/presence_repository_impl.dart`
- Create: `test/features/presence/data/repositories/presence_repository_impl_test.dart`
- Modify: `lib/core/di/service_locator.dart`

- [ ] **Step 1: Create the entity**

Create `lib/features/presence/domain/entities/presence_entity.dart`:

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'presence_entity.freezed.dart';
part 'presence_entity.g.dart';

@freezed
class PresenceEntity with _$PresenceEntity {
  const factory PresenceEntity({
    required bool? isOnline,
    required DateTime? lastSeenAt,
    required bool hidden,
  }) = _PresenceEntity;

  factory PresenceEntity.fromJson(Map<String, dynamic> json) {
    return PresenceEntity(
      isOnline: json['isOnline'] as bool?,
      lastSeenAt: json['lastSeenAt'] != null
          ? DateTime.parse(json['lastSeenAt'] as String).toUtc()
          : null,
      hidden: (json['hidden'] as bool?) ?? false,
    );
  }
}
```

- [ ] **Step 2: Generate Freezed files**

Run: `cd ~/Downloads/taler_id_mobile && dart run build_runner build --delete-conflicting-outputs 2>&1 | tail -3`
Expected: `Succeeded after ...s with N outputs`.

- [ ] **Step 3: Create the abstract repository**

Create `lib/features/presence/domain/repositories/i_presence_repository.dart`:

```dart
import '../entities/presence_entity.dart';

abstract class IPresenceRepository {
  Future<void> ping();
  Future<PresenceEntity> getPresence(String userId);
  Future<PresenceEntity> getMyPresence();
  Future<void> updatePrivacy(String privacy); // 'EVERYONE' | 'CONTACTS' | 'NOBODY'
}
```

- [ ] **Step 4: Create the remote datasource**

Create `lib/features/presence/data/datasources/presence_remote_datasource.dart`:

```dart
import 'package:dio/dio.dart';
import '../../domain/entities/presence_entity.dart';

class PresenceRemoteDataSource {
  final Dio _dio;
  PresenceRemoteDataSource(this._dio);

  Future<void> ping() async {
    await _dio.post('/presence/ping');
  }

  Future<PresenceEntity> getPresence(String userId) async {
    final res = await _dio.get('/presence/$userId');
    return PresenceEntity.fromJson(Map<String, dynamic>.from(res.data as Map));
  }

  Future<PresenceEntity> getMyPresence() async {
    final res = await _dio.get('/presence/me');
    return PresenceEntity.fromJson(Map<String, dynamic>.from(res.data as Map));
  }

  Future<void> updatePrivacy(String privacy) async {
    await _dio.patch('/profile', data: {'lastSeenPrivacy': privacy});
  }
}
```

- [ ] **Step 5: Write the failing repo test**

Create `test/features/presence/data/repositories/presence_repository_impl_test.dart`:

```dart
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:taler_id_mobile/features/presence/data/datasources/presence_remote_datasource.dart';
import 'package:taler_id_mobile/features/presence/data/repositories/presence_repository_impl.dart';
import 'package:taler_id_mobile/features/presence/domain/entities/presence_entity.dart';

class _MockDs extends Mock implements PresenceRemoteDataSource {}

void main() {
  late _MockDs ds;
  late PresenceRepositoryImpl repo;

  setUp(() {
    ds = _MockDs();
    repo = PresenceRepositoryImpl(ds);
  });

  test('getPresence forwards to datasource and returns entity', () async {
    final entity = PresenceEntity(
      isOnline: true,
      lastSeenAt: DateTime.utc(2026, 5, 14, 7),
      hidden: false,
    );
    when(() => ds.getPresence('u1')).thenAnswer((_) async => entity);
    expect(await repo.getPresence('u1'), entity);
    verify(() => ds.getPresence('u1')).called(1);
  });

  test('ping forwards to datasource', () async {
    when(() => ds.ping()).thenAnswer((_) async {});
    await repo.ping();
    verify(() => ds.ping()).called(1);
  });

  test('updatePrivacy forwards privacy string to datasource', () async {
    when(() => ds.updatePrivacy(any())).thenAnswer((_) async {});
    await repo.updatePrivacy('CONTACTS');
    verify(() => ds.updatePrivacy('CONTACTS')).called(1);
  });

  test('PresenceEntity.fromJson handles hidden + null lastSeen correctly', () {
    final e = PresenceEntity.fromJson({
      'isOnline': null,
      'lastSeenAt': null,
      'hidden': true,
    });
    expect(e.isOnline, isNull);
    expect(e.lastSeenAt, isNull);
    expect(e.hidden, isTrue);
  });
}
```

- [ ] **Step 6: Run test — expected to fail (impl missing)**

Run: `cd ~/Downloads/taler_id_mobile && flutter test test/features/presence/data/repositories/presence_repository_impl_test.dart 2>&1 | tail -10`
Expected: Compile error — `PresenceRepositoryImpl` not found.

- [ ] **Step 7: Implement the repository**

Create `lib/features/presence/data/repositories/presence_repository_impl.dart`:

```dart
import '../../domain/entities/presence_entity.dart';
import '../../domain/repositories/i_presence_repository.dart';
import '../datasources/presence_remote_datasource.dart';

class PresenceRepositoryImpl implements IPresenceRepository {
  final PresenceRemoteDataSource _ds;
  PresenceRepositoryImpl(this._ds);

  @override
  Future<void> ping() => _ds.ping();

  @override
  Future<PresenceEntity> getPresence(String userId) => _ds.getPresence(userId);

  @override
  Future<PresenceEntity> getMyPresence() => _ds.getMyPresence();

  @override
  Future<void> updatePrivacy(String privacy) => _ds.updatePrivacy(privacy);
}
```

- [ ] **Step 8: Run test — expected to pass**

Run: `cd ~/Downloads/taler_id_mobile && flutter test test/features/presence/ 2>&1 | tail -5`
Expected: `All tests passed!` (4 of 4).

- [ ] **Step 9: Register in DI**

In `lib/core/di/service_locator.dart`, after the messenger feature registration block (search for `IMessengerRepository`), add:

```dart
// Presence (online/last-seen) feature
sl.registerLazySingleton<PresenceRemoteDataSource>(
  () => PresenceRemoteDataSource(sl<DioClient>().dio),
);
sl.registerLazySingleton<IPresenceRepository>(
  () => PresenceRepositoryImpl(sl<PresenceRemoteDataSource>()),
);
```

Add these imports at the top of the file (alphabetically with other feature imports):

```dart
import '../../features/presence/data/datasources/presence_remote_datasource.dart';
import '../../features/presence/data/repositories/presence_repository_impl.dart';
import '../../features/presence/domain/repositories/i_presence_repository.dart';
```

- [ ] **Step 10: Verify analyzer + full test suite**

Run: `cd ~/Downloads/taler_id_mobile && flutter analyze lib/features/presence lib/core/di/service_locator.dart 2>&1 | tail -5 && flutter test 2>&1 | tail -3`
Expected: `No issues found!` and test suite green.

- [ ] **Step 11: Commit**

```bash
cd ~/Downloads/taler_id_mobile
git add lib/features/presence/ test/features/presence/ lib/core/di/service_locator.dart
git commit -m "feat(presence): entity + repository + datasource + DI"
```

---

## Task 5: PresenceHeartbeatService + main.dart wiring

**Repo:** `~/Downloads/taler_id_mobile/`

**Files:**
- Create: `lib/features/presence/presentation/services/presence_heartbeat_service.dart`
- Create: `test/features/presence/presentation/services/presence_heartbeat_service_test.dart`
- Modify: `lib/core/di/service_locator.dart`
- Modify: `lib/main.dart`

- [ ] **Step 1: Write the failing test**

Create `test/features/presence/presentation/services/presence_heartbeat_service_test.dart`:

```dart
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:taler_id_mobile/features/presence/domain/repositories/i_presence_repository.dart';
import 'package:taler_id_mobile/features/presence/presentation/services/presence_heartbeat_service.dart';

class _MockRepo extends Mock implements IPresenceRepository {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _MockRepo repo;
  late PresenceHeartbeatService svc;

  setUp(() {
    repo = _MockRepo();
    when(() => repo.ping()).thenAnswer((_) async {});
    svc = PresenceHeartbeatService(repo);
  });

  tearDown(() => svc.dispose());

  test('start() pings immediately when logged in and resumed', () async {
    svc.setLoggedIn(true);
    svc.start();
    await Future<void>.delayed(const Duration(milliseconds: 50));
    verify(() => repo.ping()).called(1);
  });

  test('does not ping when logged out', () async {
    svc.setLoggedIn(false);
    svc.start();
    await Future<void>.delayed(const Duration(milliseconds: 50));
    verifyNever(() => repo.ping());
  });

  test('stop() cancels the timer', () async {
    svc.setLoggedIn(true);
    svc.start();
    await Future<void>.delayed(const Duration(milliseconds: 50));
    svc.stop();
    clearInteractions(repo);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    verifyNever(() => repo.ping());
  });
}
```

- [ ] **Step 2: Run test — expected to fail**

Run: `cd ~/Downloads/taler_id_mobile && flutter test test/features/presence/presentation/services/ 2>&1 | tail -5`
Expected: Compile error — `PresenceHeartbeatService` not found.

- [ ] **Step 3: Implement the service**

Create `lib/features/presence/presentation/services/presence_heartbeat_service.dart`:

```dart
import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import '../../domain/repositories/i_presence_repository.dart';

/// Foreground heartbeat: pings `/presence/ping` every 30 s while the app is
/// resumed AND the user is logged in. Cancels itself on backgrounding,
/// logout, or a 401 response.
class PresenceHeartbeatService with WidgetsBindingObserver {
  static const Duration _interval = Duration(seconds: 30);

  final IPresenceRepository _repo;
  Timer? _timer;
  bool _loggedIn = false;
  bool _resumed = true;
  bool _disposed = false;

  PresenceHeartbeatService(this._repo) {
    WidgetsBinding.instance.addObserver(this);
  }

  void setLoggedIn(bool v) {
    _loggedIn = v;
    _evaluate();
  }

  void start() => _evaluate();

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _resumed = state == AppLifecycleState.resumed;
    _evaluate();
  }

  void _evaluate() {
    if (_disposed) return;
    final shouldRun = _loggedIn && _resumed;
    if (shouldRun && _timer == null) {
      _ping();
      _timer = Timer.periodic(_interval, (_) => _ping());
    } else if (!shouldRun && _timer != null) {
      stop();
    }
  }

  Future<void> _ping() async {
    try {
      await _repo.ping();
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        // token expired — wait for explicit re-login
        _loggedIn = false;
        stop();
      }
      // swallow other transient errors
    } catch (_) {
      // swallow
    }
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    stop();
    WidgetsBinding.instance.removeObserver(this);
  }
}
```

- [ ] **Step 4: Run test — expected to pass**

Run: `cd ~/Downloads/taler_id_mobile && flutter test test/features/presence/ 2>&1 | tail -5`
Expected: `All tests passed!`.

- [ ] **Step 5: Register in DI**

In `lib/core/di/service_locator.dart`, after the `IPresenceRepository` registration from Task 4, add:

```dart
sl.registerLazySingleton<PresenceHeartbeatService>(
  () => PresenceHeartbeatService(sl<IPresenceRepository>()),
);
```

Add the import at the top:

```dart
import '../../features/presence/presentation/services/presence_heartbeat_service.dart';
```

- [ ] **Step 6: Wire into `lib/main.dart`**

Find where `runApp(MyApp(...))` is called in `lib/main.dart`. Immediately before it (after `await setupDependencies()` and after the AuthBloc is initialized), add code to start the heartbeat and gate it by auth state. The exact integration depends on existing `AuthBloc` access. The minimal change is to set `_loggedIn=true` after a successful login and `_loggedIn=false` after logout. If `AuthBloc` exposes a stream:

```dart
final heartbeat = GetIt.instance<PresenceHeartbeatService>();
final authBloc = GetIt.instance<AuthBloc>();
heartbeat.setLoggedIn(authBloc.state is AuthAuthenticated);
authBloc.stream.listen((state) {
  heartbeat.setLoggedIn(state is AuthAuthenticated);
});
```

Place this after the existing `setupDependencies()` await, before `runApp(...)`. Verify the actual `AuthState` subclasses by reading the existing `lib/features/auth/presentation/bloc/auth_state.dart` first — adjust class name (e.g. `Authenticated` vs `AuthAuthenticated`) accordingly.

- [ ] **Step 7: Verify analyzer + tests**

Run: `cd ~/Downloads/taler_id_mobile && flutter analyze lib/features/presence lib/core/di/service_locator.dart lib/main.dart 2>&1 | tail -5 && flutter test 2>&1 | tail -3`
Expected: `No issues found!` and test suite green.

- [ ] **Step 8: Commit**

```bash
cd ~/Downloads/taler_id_mobile
git add lib/features/presence/presentation/ test/features/presence/presentation/ lib/core/di/service_locator.dart lib/main.dart
git commit -m "feat(presence): foreground heartbeat service + main.dart wiring"
```

---

## Task 6: Last-seen formatter + ARB localization

**Repo:** `~/Downloads/taler_id_mobile/`

**Files:**
- Create: `lib/core/utils/presence_format.dart`
- Modify: `lib/l10n/app_ru.arb`
- Modify: `lib/l10n/app_en.arb`
- Create: `test/core/utils/presence_format_test.dart`

- [ ] **Step 1: Add l10n strings to `lib/l10n/app_ru.arb`**

Locate the closing `}` of `app_ru.arb`. Before it, add (note: keep trailing commas correct relative to the existing last entry):

```json
  "presenceOnline": "в сети",
  "presenceLastSeenJustNow": "был(а) в сети только что",
  "presenceLastSeenMinutesAgo": "был(а) в сети {minutes} мин назад",
  "@presenceLastSeenMinutesAgo": {
    "placeholders": { "minutes": { "type": "int" } }
  },
  "presenceLastSeenToday": "был(а) в сети сегодня в {time}",
  "@presenceLastSeenToday": {
    "placeholders": { "time": { "type": "String" } }
  },
  "presenceLastSeenYesterday": "был(а) в сети вчера в {time}",
  "@presenceLastSeenYesterday": {
    "placeholders": { "time": { "type": "String" } }
  },
  "presenceLastSeenOnDate": "был(а) в сети {date}",
  "@presenceLastSeenOnDate": {
    "placeholders": { "date": { "type": "String" } }
  },
  "presenceLastSeenRecently": "был(а) в сети недавно"
```

- [ ] **Step 2: Add the equivalent English strings to `lib/l10n/app_en.arb`**

Same keys, mirroring shape, English text:

```json
  "presenceOnline": "online",
  "presenceLastSeenJustNow": "last seen just now",
  "presenceLastSeenMinutesAgo": "last seen {minutes} min ago",
  "@presenceLastSeenMinutesAgo": {
    "placeholders": { "minutes": { "type": "int" } }
  },
  "presenceLastSeenToday": "last seen today at {time}",
  "@presenceLastSeenToday": {
    "placeholders": { "time": { "type": "String" } }
  },
  "presenceLastSeenYesterday": "last seen yesterday at {time}",
  "@presenceLastSeenYesterday": {
    "placeholders": { "time": { "type": "String" } }
  },
  "presenceLastSeenOnDate": "last seen {date}",
  "@presenceLastSeenOnDate": {
    "placeholders": { "date": { "type": "String" } }
  },
  "presenceLastSeenRecently": "last seen recently"
```

- [ ] **Step 3: Regenerate localizations**

Run: `cd ~/Downloads/taler_id_mobile && flutter gen-l10n 2>&1 | tail -3`
Expected: no output / clean exit.

- [ ] **Step 4: Write the failing formatter test**

Create `test/core/utils/presence_format_test.dart`:

```dart
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taler_id_mobile/core/utils/presence_format.dart';
import 'package:taler_id_mobile/features/presence/domain/entities/presence_entity.dart';
import 'package:taler_id_mobile/l10n/app_localizations.dart';

Future<AppLocalizations> _ruL10n() async {
  return AppLocalizations.delegate.load(const Locale('ru'));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final now = DateTime(2026, 5, 14, 12, 0); // arbitrary "now"

  test('isOnline=true returns "в сети"', () async {
    final l10n = await _ruL10n();
    final e = PresenceEntity(isOnline: true, lastSeenAt: null, hidden: false);
    expect(formatLastSeen(e, l10n, now), 'в сети');
  });

  test('hidden=true returns "недавно"', () async {
    final l10n = await _ruL10n();
    final e = PresenceEntity(isOnline: null, lastSeenAt: null, hidden: true);
    expect(formatLastSeen(e, l10n, now), 'был(а) в сети недавно');
  });

  test('lastSeenAt null and not hidden also renders "недавно"', () async {
    final l10n = await _ruL10n();
    final e = PresenceEntity(isOnline: false, lastSeenAt: null, hidden: false);
    expect(formatLastSeen(e, l10n, now), 'был(а) в сети недавно');
  });

  test('less than 60 seconds ago: "только что"', () async {
    final l10n = await _ruL10n();
    final lastSeen = now.subtract(const Duration(seconds: 30));
    final e = PresenceEntity(isOnline: false, lastSeenAt: lastSeen, hidden: false);
    expect(formatLastSeen(e, l10n, now), 'был(а) в сети только что');
  });

  test('15 minutes ago: "15 мин назад"', () async {
    final l10n = await _ruL10n();
    final lastSeen = now.subtract(const Duration(minutes: 15));
    final e = PresenceEntity(isOnline: false, lastSeenAt: lastSeen, hidden: false);
    expect(formatLastSeen(e, l10n, now), 'был(а) в сети 15 мин назад');
  });

  test('same day earlier: "сегодня в HH:MM"', () async {
    final l10n = await _ruL10n();
    final lastSeen = DateTime(2026, 5, 14, 8, 30);
    final e = PresenceEntity(isOnline: false, lastSeenAt: lastSeen, hidden: false);
    expect(formatLastSeen(e, l10n, now), 'был(а) в сети сегодня в 08:30');
  });

  test('yesterday: "вчера в HH:MM"', () async {
    final l10n = await _ruL10n();
    final lastSeen = DateTime(2026, 5, 13, 21, 30);
    final e = PresenceEntity(isOnline: false, lastSeenAt: lastSeen, hidden: false);
    expect(formatLastSeen(e, l10n, now), 'был(а) в сети вчера в 21:30');
  });

  test('older: "DD.MM.YYYY"', () async {
    final l10n = await _ruL10n();
    final lastSeen = DateTime(2026, 4, 30, 12, 0);
    final e = PresenceEntity(isOnline: false, lastSeenAt: lastSeen, hidden: false);
    expect(formatLastSeen(e, l10n, now), 'был(а) в сети 30.04.2026');
  });
}
```

- [ ] **Step 5: Run test — expected to fail (formatter does not exist)**

Run: `cd ~/Downloads/taler_id_mobile && flutter test test/core/utils/presence_format_test.dart 2>&1 | tail -5`
Expected: Compile error — `formatLastSeen` not defined.

- [ ] **Step 6: Implement the formatter**

Create `lib/core/utils/presence_format.dart`:

```dart
import '../../features/presence/domain/entities/presence_entity.dart';
import '../../l10n/app_localizations.dart';

String formatLastSeen(
  PresenceEntity entity,
  AppLocalizations l10n,
  DateTime now,
) {
  if (entity.isOnline == true) return l10n.presenceOnline;
  if (entity.hidden || entity.lastSeenAt == null) {
    return l10n.presenceLastSeenRecently;
  }
  final last = entity.lastSeenAt!;
  final delta = now.difference(last);
  if (delta.inSeconds < 60) return l10n.presenceLastSeenJustNow;
  if (delta.inMinutes < 60) {
    return l10n.presenceLastSeenMinutesAgo(delta.inMinutes);
  }
  String _hhmm(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  final isSameDay =
      last.year == now.year && last.month == now.month && last.day == now.day;
  if (isSameDay) return l10n.presenceLastSeenToday(_hhmm(last));
  final yesterday = now.subtract(const Duration(days: 1));
  final isYesterday = last.year == yesterday.year &&
      last.month == yesterday.month &&
      last.day == yesterday.day;
  if (isYesterday) return l10n.presenceLastSeenYesterday(_hhmm(last));
  final dd = last.day.toString().padLeft(2, '0');
  final mm = last.month.toString().padLeft(2, '0');
  return l10n.presenceLastSeenOnDate('$dd.$mm.${last.year}');
}
```

- [ ] **Step 7: Run test — expected to pass**

Run: `cd ~/Downloads/taler_id_mobile && flutter test test/core/utils/presence_format_test.dart 2>&1 | tail -5`
Expected: `All tests passed!` (8 of 8).

- [ ] **Step 8: Commit**

```bash
cd ~/Downloads/taler_id_mobile
git add lib/core/utils/presence_format.dart lib/l10n/ test/core/utils/presence_format_test.dart
git commit -m "feat(presence): last-seen formatter + RU/EN localization"
```

---

## Task 7: PresenceLabel widget + chat AppBar + user-profile integration

**Repo:** `~/Downloads/taler_id_mobile/`

**Files:**
- Create: `lib/features/presence/presentation/widgets/presence_label.dart`
- Modify: `lib/features/messenger/presentation/screens/chat_room_screen.dart`
- Modify: `lib/features/messenger/presentation/screens/user_profile_screen.dart`

- [ ] **Step 1: Create the polling widget**

Create `lib/features/presence/presentation/widgets/presence_label.dart`:

```dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../../../../core/utils/presence_format.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/presence_entity.dart';
import '../../domain/repositories/i_presence_repository.dart';

/// Subtitle widget that polls `/presence/:userId` every 30 s while mounted.
/// Renders nothing on first frame to avoid layout jitter.
class PresenceLabel extends StatefulWidget {
  final String userId;
  final TextStyle? style;

  const PresenceLabel({super.key, required this.userId, this.style});

  @override
  State<PresenceLabel> createState() => _PresenceLabelState();
}

class _PresenceLabelState extends State<PresenceLabel> {
  static const Duration _pollInterval = Duration(seconds: 30);

  PresenceEntity? _entity;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _fetch();
    _timer = Timer.periodic(_pollInterval, (_) => _fetch());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetch() async {
    try {
      final e = await GetIt.instance<IPresenceRepository>().getPresence(widget.userId);
      if (!mounted) return;
      setState(() => _entity = e);
    } catch (_) {
      // swallow; keep last known value
    }
  }

  @override
  Widget build(BuildContext context) {
    final entity = _entity;
    if (entity == null) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context)!;
    return Text(
      formatLastSeen(entity, l10n, DateTime.now()),
      style: widget.style,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}
```

- [ ] **Step 2: Integrate into chat room AppBar**

In `lib/features/messenger/presentation/screens/chat_room_screen.dart`, find the `title:` block in the AppBar (around line 1782–1810). The existing structure builds a `Row` with avatar + name. Modify the name area so the name and a `PresenceLabel` are stacked in a `Column`. Locate this pattern (around line 1846 in the existing code — the `Text(name ...)` inside the Row's expanded section):

Locate the existing name-rendering area inside the title `Row` — typically:

```dart
Expanded(
  child: Text(name ?? '', ...),
),
```

Replace it with:

```dart
Expanded(
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(name ?? '', /* keep existing style + overflow */),
      if (conv?.type == 'DIRECT' && otherUserId != null)
        PresenceLabel(
          userId: otherUserId,
          style: TextStyle(
            color: AppColors.of(context).textSecondary,
            fontSize: 12,
          ),
        ),
    ],
  ),
),
```

Add the import at the top of `chat_room_screen.dart`:

```dart
import '../../../presence/presentation/widgets/presence_label.dart';
```

- [ ] **Step 3: Integrate into user profile screen**

Open `lib/features/messenger/presentation/screens/user_profile_screen.dart`. Locate the existing layout (typically a `Column` with avatar + name + bio). After the name `Text` and before the bio section, add:

```dart
const SizedBox(height: 4),
PresenceLabel(
  userId: widget.userId,
  style: TextStyle(
    color: AppColors.of(context).textSecondary,
    fontSize: 13,
  ),
),
```

Add the import:

```dart
import '../../../presence/presentation/widgets/presence_label.dart';
```

Guard against showing it for self: locate the existing AuthBloc state read; before rendering the label add a check `if (widget.userId != currentUserId)`. The exact `currentUserId` accessor depends on existing code — find it via `grep -n "currentUserId\|auth.state.user" lib/features/messenger/presentation/screens/user_profile_screen.dart` and reuse the same access pattern.

- [ ] **Step 4: Verify analyzer + tests**

Run: `cd ~/Downloads/taler_id_mobile && flutter analyze lib/features/presence lib/features/messenger/presentation/screens/chat_room_screen.dart lib/features/messenger/presentation/screens/user_profile_screen.dart 2>&1 | tail -5 && flutter test 2>&1 | tail -3`
Expected: `No issues found!` and tests still green.

- [ ] **Step 5: Commit**

```bash
cd ~/Downloads/taler_id_mobile
git add lib/features/presence/presentation/widgets/ lib/features/messenger/presentation/screens/chat_room_screen.dart lib/features/messenger/presentation/screens/user_profile_screen.dart
git commit -m "feat(presence): PresenceLabel widget + chat AppBar + profile integration"
```

---

## Task 8: Privacy dropdown in edit_profile_screen

**Repo:** `~/Downloads/taler_id_mobile/`

**Files:**
- Modify: `lib/features/profile/presentation/screens/edit_profile_screen.dart`

- [ ] **Step 1: Add the dropdown field**

In `lib/features/profile/presentation/screens/edit_profile_screen.dart`, locate the form's `Column` of fields (typically inside a `Form` widget). Decide on a section near the bottom — after the existing profile fields but before any save-button block.

Add this state field at the top of the `State` class (search for `class _EditProfileScreenState`):

```dart
String _lastSeenPrivacy = 'EVERYONE';
```

In `initState()`, after the existing field initialization, load the value from the current profile if available:

```dart
final currentProfile = context.read<ProfileBloc>().state;
if (currentProfile is ProfileLoaded) {
  _lastSeenPrivacy = currentProfile.user.profile?.lastSeenPrivacy ?? 'EVERYONE';
}
```

(Adjust to existing `ProfileBloc` / state accessor — verify by reading the existing initState for analogous field reads.)

Add a section into the form body:

```dart
const SizedBox(height: 16),
Text(
  AppLocalizations.of(context)!.privacySectionTitle,
  style: TextStyle(
    color: AppColors.of(context).textPrimary,
    fontSize: 14,
    fontWeight: FontWeight.w600,
  ),
),
const SizedBox(height: 8),
DropdownButtonFormField<String>(
  value: _lastSeenPrivacy,
  decoration: InputDecoration(
    labelText: AppLocalizations.of(context)!.privacyLastSeenLabel,
  ),
  items: const [
    DropdownMenuItem(value: 'EVERYONE', child: Text('Все')),
    DropdownMenuItem(value: 'CONTACTS', child: Text('Только контакты')),
    DropdownMenuItem(value: 'NOBODY', child: Text('Никто')),
  ],
  onChanged: (v) => setState(() => _lastSeenPrivacy = v ?? 'EVERYONE'),
),
```

- [ ] **Step 2: Add the two ARB strings for the section labels**

In `lib/l10n/app_ru.arb`, before the closing brace, add:

```json
  "privacySectionTitle": "Конфиденциальность",
  "privacyLastSeenLabel": "Кто видит время последнего входа"
```

In `lib/l10n/app_en.arb`:

```json
  "privacySectionTitle": "Privacy",
  "privacyLastSeenLabel": "Who sees your last seen time"
```

Regenerate l10n: `cd ~/Downloads/taler_id_mobile && flutter gen-l10n`

- [ ] **Step 3: Wire into save**

Find the `_save()` (or analogous) method that does `PATCH /profile`. The existing call likely passes a `Map` or DTO; add `lastSeenPrivacy: _lastSeenPrivacy` to that payload. Example pattern — find the existing line that calls `profileRepo.updateProfile(...)` or `dio.patch('/profile', data: {...})` and add the field:

```dart
data: {
  // ... existing fields ...
  'lastSeenPrivacy': _lastSeenPrivacy,
}
```

- [ ] **Step 4: Verify analyzer**

Run: `cd ~/Downloads/taler_id_mobile && flutter analyze lib/features/profile/presentation/screens/edit_profile_screen.dart lib/l10n 2>&1 | tail -5`
Expected: `No issues found!`.

- [ ] **Step 5: Run full mobile test suite to confirm no regression**

Run: `cd ~/Downloads/taler_id_mobile && flutter test 2>&1 | tail -3`
Expected: tests still green.

- [ ] **Step 6: Commit**

```bash
cd ~/Downloads/taler_id_mobile
git add lib/features/profile/presentation/screens/edit_profile_screen.dart lib/l10n/
git commit -m "feat(presence): privacy dropdown in edit_profile_screen"
```

---

## Task 9: API integration test

**Repo:** `~/Downloads/taler_id_tests/`

**Files:**
- Create: `presence_test.ts`
- Modify: `package.json`

- [ ] **Step 1: Add npm script entries**

In `package.json`, locate the `"scripts"` block. Add:

```json
"test:presence": "BASE_URL=https://staging.id.taler.tirol npx ts-node presence_test.ts",
"test:presence:prod": "BASE_URL=https://id.taler.tirol npx ts-node presence_test.ts"
```

(Match the comma style with neighboring entries.)

- [ ] **Step 2: Write the integration test**

Create `presence_test.ts`:

```typescript
import axios from 'axios';

const BASE = process.env.BASE_URL ?? 'https://staging.id.taler.tirol';
const A_EMAIL = 'integration_test@taler-test.com';
const A_PASS = 'IntegrationTest123!';
const B_EMAIL = 'integration_test_2@taler-test.com';
const B_PASS = 'IntegrationTest123!';

async function login(email: string, pass: string): Promise<string> {
  const r = await axios.post(`${BASE}/auth/login`, { email, password: pass });
  return r.data.accessToken as string;
}

async function meId(token: string): Promise<string> {
  const r = await axios.get(`${BASE}/profile`, {
    headers: { Authorization: `Bearer ${token}` },
  });
  return r.data.id as string;
}

function bearer(token: string) {
  return { headers: { Authorization: `Bearer ${token}` } };
}

let passed = 0;
let failed = 0;
async function step(name: string, fn: () => Promise<void>) {
  try {
    await fn();
    console.log(`  ✓ ${name}`);
    passed++;
  } catch (e: any) {
    console.log(`  ✗ ${name}`);
    console.log(`    ${e.message ?? e}`);
    failed++;
  }
}

async function main() {
  console.log(`Presence integration test against ${BASE}\n`);

  const tokenA = await login(A_EMAIL, A_PASS);
  const tokenB = await login(B_EMAIL, B_PASS);
  const idA = await meId(tokenA);

  await step('1. A pings → B reads → isOnline=true', async () => {
    // Reset A's privacy to EVERYONE
    await axios.patch(`${BASE}/profile`, { lastSeenPrivacy: 'EVERYONE' }, bearer(tokenA));
    await axios.post(`${BASE}/presence/ping`, null, bearer(tokenA));
    const r = await axios.get(`${BASE}/presence/${idA}`, bearer(tokenB));
    if (r.data.isOnline !== true) throw new Error(`expected isOnline=true, got ${JSON.stringify(r.data)}`);
    if (r.data.hidden !== false) throw new Error('expected hidden=false');
  });

  await step('2. After 95s without ping → isOnline=false, lastSeenAt set', async () => {
    console.log('    waiting 95s for Redis TTL...');
    await new Promise((res) => setTimeout(res, 95_000));
    const r = await axios.get(`${BASE}/presence/${idA}`, bearer(tokenB));
    if (r.data.isOnline !== false) throw new Error(`expected isOnline=false, got ${JSON.stringify(r.data)}`);
    if (r.data.lastSeenAt == null) throw new Error('expected lastSeenAt to be set');
  });

  await step('3. A privacy=NOBODY → B sees hidden=true', async () => {
    await axios.patch(`${BASE}/profile`, { lastSeenPrivacy: 'NOBODY' }, bearer(tokenA));
    const r = await axios.get(`${BASE}/presence/${idA}`, bearer(tokenB));
    if (r.data.hidden !== true) throw new Error(`expected hidden=true, got ${JSON.stringify(r.data)}`);
    if (r.data.isOnline !== null) throw new Error('expected isOnline=null');
    if (r.data.lastSeenAt !== null) throw new Error('expected lastSeenAt=null');
  });

  await step('4. A privacy=EVERYONE again → B sees real data', async () => {
    await axios.patch(`${BASE}/profile`, { lastSeenPrivacy: 'EVERYONE' }, bearer(tokenA));
    const r = await axios.get(`${BASE}/presence/${idA}`, bearer(tokenB));
    if (r.data.hidden !== false) throw new Error('expected hidden=false');
  });

  await step('5. Self via /presence/me bypasses privacy', async () => {
    await axios.patch(`${BASE}/profile`, { lastSeenPrivacy: 'NOBODY' }, bearer(tokenA));
    const r = await axios.get(`${BASE}/presence/me`, bearer(tokenA));
    if (r.data.hidden !== false) throw new Error(`expected hidden=false (self), got ${JSON.stringify(r.data)}`);
    // restore for next test runs
    await axios.patch(`${BASE}/profile`, { lastSeenPrivacy: 'EVERYONE' }, bearer(tokenA));
  });

  console.log(`\n${passed} passed, ${failed} failed`);
  process.exit(failed === 0 ? 0 : 1);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
```

- [ ] **Step 3: Run the test against DEV (requires backend deployed via Task 1-3)**

Run: `cd ~/Downloads/taler_id_tests && npm run test:presence 2>&1 | tail -15`
Expected: `5 passed, 0 failed`. Note: the test takes ~100 s due to the Redis TTL wait in step 2.

- [ ] **Step 4: Commit**

```bash
cd ~/Downloads/taler_id_tests
git add presence_test.ts package.json
git commit -m "test(presence): integration test for online/last-seen + privacy"
```

---

## Task 10: Deploy to DEV + smoke-verify (user-driven gate)

> Manual operator steps. Skipped during automated execution.

- [ ] **Step 1: Deploy backend to DEV**

```bash
ssh dvolkov@89.169.55.217 'cd ~/taler-id && git fetch && git checkout dev && git pull --ff-only && npm install --silent && npx prisma migrate deploy && npm run build && pm2 restart taler-id-dev'
```

Expected output ends with `[PM2] [taler-id-dev] ✓` and the migration line shows the new `add_presence_last_seen` migration applied.

- [ ] **Step 2: Run integration test against DEV**

```bash
cd ~/Downloads/taler_id_tests && npm run test:presence
```

Expected: 5/5 passed.

- [ ] **Step 3: Build dev APK + publish to /var/www/downloads/**

```bash
ssh dvolkov@138.124.61.221 'cd ~/taler_id_mobile && git fetch && git checkout dev && git pull --ff-only && flutter build apk --flavor dev --release -t lib/main_dev.dart --dart-define=FLAVOR=dev --dart-define=BASE_URL=https://staging.id.taler.tirol && sudo cp build/app/outputs/flutter-apk/app-dev-release.apk /var/www/downloads/taler-id-dev.apk'
```

- [ ] **Step 4: Hardware smoke (manual)**

Two devices, accounts already mutually contacted:
1. A on iPhone (dev TestFlight 1.0.72) opens the app.
2. B on Android (dev APK) opens the chat with A — AppBar shows `в сети`.
3. A backgrounds the app for 95 s → B sees `только что` → `1 мин назад`.
4. B opens A's profile via avatar tap → same status visible.
5. A goes to Edit Profile → switches privacy to `Только контакты`, then to `Никто`, save each time → B's next polling tick (≤ 30 s) reflects the change.

---

## Self-Review

**Spec coverage check:**
- ✅ Heartbeat + Redis 90s TTL — Task 2
- ✅ Profile.lastSeenAt + 60s DB throttle — Task 1 + Task 2
- ✅ 3-tier privacy — Task 1 (enum) + Task 2 (filter) + Task 3 (DTO) + Task 8 (UI)
- ✅ `GET /presence/:userId` + `/me` + `POST /presence/ping` with Throttle — Task 2
- ✅ Self bypass — Task 2 (test #5 + implementation)
- ✅ Bidirectional CONTACTS check via `ContactRequest` — Task 2 (`OR` clause)
- ✅ Mobile heartbeat 30s, lifecycle + login gating + 401 cancel — Task 5
- ✅ Polling label 30s — Task 7
- ✅ Formatter 7 branches — Task 6
- ✅ Privacy dropdown — Task 8
- ✅ Hidden = `недавно` rendering — Task 6 formatter
- ✅ Skip for self / bot conversations / groups — Task 7 conditions (`conv?.type == 'DIRECT'`, `widget.userId != currentUserId`)
- ✅ Integration test — Task 9 (5 scenarios)
- ✅ Hardware smoke — Task 10

**Placeholder scan:** every step has concrete code, file paths, or commands. No "TODO"/"TBD"/"appropriate" left.

**Type consistency:** `PresenceEntity` shape (`isOnline: bool?`, `lastSeenAt: DateTime?`, `hidden: bool`) consistent across Task 4 (Dart entity), Task 6 (formatter input), Task 7 (widget consumer), and Task 9 (TS JSON shape). `lastSeenPrivacy` enum values `EVERYONE | CONTACTS | NOBODY` consistent across Task 1 (Prisma), Task 2 (TS service), Task 3 (DTO IsIn), Task 8 (Dart dropdown), Task 9 (TS test).

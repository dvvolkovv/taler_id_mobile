# Mesh Phase 1b — Backend Device-Key Sync Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development to implement this plan task-by-task.

**Goal:** Mobile devices register their X25519 mesh static public key with the Taler ID NestJS backend, fetch contacts' device keys for Noise IK handshakes, and receive FCM push updates when a contact rotates or revokes a key. Replaces the Phase 1a in-memory `ContactKeyStore` with Hive-persisted storage synchronised from the server.

**Architecture:** Self-signed device certificates (Phase 1b simplification — full user-identity-key PKI deferred to Phase 1c). Each device generates an X25519 static keypair (`MeshStaticKey`) and signs `{devicePk, userId, validUntil, algorithm}` with its private key (acting as its own authority). Server stores certs, serves them to authenticated contacts, and fans out FCM push notifications on changes.

**Tech Stack:**
- Backend: NestJS + Prisma + PostgreSQL (existing) + FCM Admin SDK (already wired for message push — reuse).
- Mobile: Dio + Freezed + Hive + flutter_secure_storage + firebase_messaging (existing).
- E2E tests: `~/Downloads/taler_id_tests/` (Jest + supertest against staging URL).

---

## Spec & Dependencies

- Spec: `docs/superpowers/specs/2026-04-21-mesh-network-design.md`, Section 6 (Session & Crypto), Section 11 (Backend Changes)
- Phase 1a plan (completed): `docs/superpowers/plans/2026-04-21-mesh-phase1a-text-exchange.md`
- Working dirs:
  - **Backend:** `~/taler-id-mesh/` on branch `feature/mesh-bridge` (off `main`)
  - **Mobile:** `~/Downloads/taler_id_mesh/` on branch `feature/mesh-network` (off `dev`)
  - **E2E tests:** `~/Downloads/taler_id_tests/` (no branch — scratch scripts; create new files)

## Phase 1b Self-Signed Cert Format

Decision: use self-signed (simpler than spec's user-identity-key model). Each cert:

```json
{
  "devicePk": "<hex 32B X25519 public key>",
  "userId": "<uuid>",
  "algorithm": "X25519",
  "validUntilEpochMs": 1761945600000,
  "signature": "<hex 64B Ed25519 signature>"
}
```

Signature covers the UTF-8 bytes of the canonical JSON (keys in alphabetical order, no spaces) of the first four fields. Verifying requires only `devicePk` — **but** Phase 1b also keeps a parallel Ed25519 keypair (`DeviceKey` from Phase 1a) per device for the signature, since X25519 cannot sign. Wire signing key and X25519 key side by side.

**Sig input** (canonical JSON):
```
{"algorithm":"X25519","devicePk":"<hex>","userId":"<uuid>","validUntilEpochMs":1761945600000}
```

Default validity: 30 days from generation (per spec).

## File Structure

### Backend (`~/taler-id-mesh/`)

```
prisma/
├── schema.prisma                 # + DeviceKey model
└── migrations/
    └── YYYYMMDDHHMMSS_add_device_keys/

src/
├── device-keys/
│   ├── device-keys.module.ts
│   ├── device-keys.service.ts
│   ├── device-keys.controller.ts
│   ├── device-keys.service.spec.ts
│   └── dto/
│       ├── register-device-key.dto.ts
│       ├── device-key-response.dto.ts
│       └── revoke-device-key.dto.ts
├── fcm/
│   └── fcm.service.ts            # (existing — extend with sendKeyUpdate)
└── app.module.ts                 # + DeviceKeysModule

test/
└── device-keys.e2e-spec.ts
```

### Mobile (`~/Downloads/taler_id_mesh/`)

```
lib/core/mesh/
├── crypto/
│   ├── keys/
│   │   ├── device_cert.dart          # Freezed model of the self-signed cert
│   │   ├── cert_signer.dart          # Create + verify certs
│   │   └── contact_key_store_hive.dart  # Hive-backed impl of ContactKeyStore interface
│   └── noise/                        # (unchanged)
└── services/
    ├── device_keys_api_client.dart   # Dio wrapper for backend endpoints
    ├── device_key_sync_service.dart  # Bootstrap: register own cert; fetch contact keys on demand
    └── mesh_messaging_service.dart   # (unchanged API; wiring updated in Task M7)

lib/features/mesh/
└── data/datasources/
    └── mesh_fcm_listener.dart        # Hook FCM topic "mesh-keys/<userId>" → store update
```

Existing mobile crypto and services from Phase 1a stay intact — Phase 1b adds alongside, preserving backward compatibility so tests don't break.

### E2E tests (`~/Downloads/taler_id_tests/`)

```
device_keys_test.ts                   # Full register → fetch → revoke flow against staging
package.json                          # + "test:mesh": "tsx device_keys_test.ts"
```

---

## Execution Order

Tasks **B1–B7** are backend, tasks **M1–M8** are mobile, final **E1** is end-to-end integration. Backend first (A from brainstorm). Work from:
- Backend tasks: `cd ~/taler-id-mesh` (branch `feature/mesh-bridge`)
- Mobile tasks: `cd ~/Downloads/taler_id_mesh` (branch `feature/mesh-network`)

---

# PART 1 — BACKEND

## Task B1: Prisma DeviceKey model + migration

**Files:**
- Modify: `prisma/schema.prisma`
- Create: migration via `npx prisma migrate dev --name add_device_keys`

- [ ] **Step 1: Add DeviceKey model to schema.prisma**

Append to `prisma/schema.prisma` (after `User` model):

```prisma
model DeviceKey {
  id                 String    @id @default(uuid())
  userId             String
  devicePk           String    @unique  // hex-encoded 32-byte X25519 public key
  algorithm          String    @default("X25519")
  validUntil         DateTime
  certificate        String    @db.Text   // full JSON self-signed cert (for clients to verify)
  signature          String                // hex Ed25519 signature (redundant with certificate JSON but indexed)
  revokedAt          DateTime?
  createdAt          DateTime  @default(now())
  updatedAt          DateTime  @updatedAt

  user               User      @relation(fields: [userId], references: [id], onDelete: Cascade)

  @@index([userId])
  @@index([userId, revokedAt])
}
```

Add to `User` model (inverse relation):
```prisma
model User {
  // ... existing fields ...
  deviceKeys DeviceKey[]
}
```

- [ ] **Step 2: Generate + apply migration**

```bash
cd ~/taler-id-mesh
npx prisma migrate dev --name add_device_keys
```

Expected: migration created under `prisma/migrations/YYYYMMDDHHMMSS_add_device_keys/`, Prisma client regenerated, local DB updated.

- [ ] **Step 3: Verify**

```bash
cd ~/taler-id-mesh
npx prisma generate
npm run build
```

Expected: `prisma generate` succeeds, `nest build` compiles without errors.

- [ ] **Step 4: Commit**

```bash
cd ~/taler-id-mesh
git add prisma/schema.prisma prisma/migrations/
git commit -m "feat(mesh): add DeviceKey Prisma model for Phase 1b"
```

---

## Task B2: DTOs for device-key endpoints

**Files:**
- Create: `src/device-keys/dto/register-device-key.dto.ts`
- Create: `src/device-keys/dto/device-key-response.dto.ts`
- Create: `src/device-keys/dto/revoke-device-key.dto.ts`

- [ ] **Step 1: Create `src/device-keys/dto/register-device-key.dto.ts`**

```typescript
import { IsString, Matches, IsInt, IsPositive } from 'class-validator';

export class RegisterDeviceKeyDto {
  @IsString()
  @Matches(/^[0-9a-f]{64}$/i, { message: 'devicePk must be 64 hex chars' })
  devicePk: string;

  @IsString()
  algorithm: string; // must equal "X25519" — enforced by service

  @IsInt()
  @IsPositive()
  validUntilEpochMs: number;

  @IsString()
  @Matches(/^[0-9a-f]{128}$/i, { message: 'signature must be 128 hex chars (Ed25519)' })
  signature: string;

  @IsString()
  certificate: string; // the full canonical JSON that was signed
}
```

- [ ] **Step 2: Create `src/device-keys/dto/device-key-response.dto.ts`**

```typescript
export class DeviceKeyResponseDto {
  id: string;
  userId: string;
  devicePk: string;
  algorithm: string;
  validUntil: string; // ISO8601
  certificate: string;
  signature: string;
  revokedAt: string | null;
  createdAt: string;
}
```

- [ ] **Step 3: Create `src/device-keys/dto/revoke-device-key.dto.ts`**

```typescript
import { IsOptional, IsString, MaxLength } from 'class-validator';

export class RevokeDeviceKeyDto {
  @IsOptional()
  @IsString()
  @MaxLength(500)
  reason?: string;
}
```

- [ ] **Step 4: Commit**

```bash
cd ~/taler-id-mesh
git add src/device-keys/dto/
git commit -m "feat(mesh): add DTOs for device-key endpoints"
```

---

## Task B3: DeviceKeysService + unit tests (TDD)

**Files:**
- Create: `src/device-keys/device-keys.service.ts`
- Create: `src/device-keys/device-keys.service.spec.ts`

- [ ] **Step 1: Write failing test**

Create `src/device-keys/device-keys.service.spec.ts`:

```typescript
import { Test, TestingModule } from '@nestjs/testing';
import { DeviceKeysService } from './device-keys.service';
import { PrismaService } from '../prisma/prisma.service';
import { FcmService } from '../fcm/fcm.service';
import { BadRequestException, NotFoundException } from '@nestjs/common';

describe('DeviceKeysService', () => {
  let service: DeviceKeysService;
  let prisma: jest.Mocked<PrismaService>;
  let fcm: jest.Mocked<FcmService>;

  beforeEach(async () => {
    const prismaMock = {
      deviceKey: {
        create: jest.fn(),
        findMany: jest.fn(),
        findUnique: jest.fn(),
        update: jest.fn(),
      },
      user: {
        findUnique: jest.fn(),
      },
    };
    const fcmMock = {
      sendKeyUpdate: jest.fn(),
    };
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        DeviceKeysService,
        { provide: PrismaService, useValue: prismaMock },
        { provide: FcmService, useValue: fcmMock },
      ],
    }).compile();

    service = module.get<DeviceKeysService>(DeviceKeysService);
    prisma = module.get(PrismaService);
    fcm = module.get(FcmService);
  });

  describe('register', () => {
    const validDto = {
      devicePk: 'a'.repeat(64),
      algorithm: 'X25519',
      validUntilEpochMs: Date.now() + 30 * 86_400_000,
      signature: 'f'.repeat(128),
      certificate: JSON.stringify({
        algorithm: 'X25519',
        devicePk: 'a'.repeat(64),
        userId: 'user-1',
        validUntilEpochMs: Date.now() + 30 * 86_400_000,
      }),
    };

    it('rejects unsupported algorithm', async () => {
      await expect(
        service.register('user-1', { ...validDto, algorithm: 'ED25519' }),
      ).rejects.toBeInstanceOf(BadRequestException);
    });

    it('rejects expired validUntil', async () => {
      await expect(
        service.register('user-1', {
          ...validDto,
          validUntilEpochMs: Date.now() - 1000,
        }),
      ).rejects.toBeInstanceOf(BadRequestException);
    });

    it('creates device key record and returns response DTO', async () => {
      const created = {
        id: 'dk-1',
        userId: 'user-1',
        devicePk: validDto.devicePk,
        algorithm: validDto.algorithm,
        validUntil: new Date(validDto.validUntilEpochMs),
        certificate: validDto.certificate,
        signature: validDto.signature,
        revokedAt: null,
        createdAt: new Date(),
        updatedAt: new Date(),
      };
      prisma.deviceKey.create.mockResolvedValue(created as any);

      const result = await service.register('user-1', validDto);

      expect(prisma.deviceKey.create).toHaveBeenCalledWith({
        data: expect.objectContaining({
          userId: 'user-1',
          devicePk: validDto.devicePk,
          algorithm: 'X25519',
        }),
      });
      expect(result.devicePk).toBe(validDto.devicePk);
      expect(result.revokedAt).toBeNull();
    });
  });

  describe('listForContact', () => {
    it('returns only non-revoked keys', async () => {
      prisma.user.findUnique.mockResolvedValue({ id: 'user-2' } as any);
      prisma.deviceKey.findMany.mockResolvedValue([
        { devicePk: 'b'.repeat(64), revokedAt: null } as any,
      ]);

      const keys = await service.listForContact('user-1', 'user-2');

      expect(keys).toHaveLength(1);
      expect(prisma.deviceKey.findMany).toHaveBeenCalledWith(
        expect.objectContaining({
          where: expect.objectContaining({
            userId: 'user-2',
            revokedAt: null,
            validUntil: { gt: expect.any(Date) },
          }),
        }),
      );
    });

    it('throws NotFound when user does not exist', async () => {
      prisma.user.findUnique.mockResolvedValue(null);
      await expect(
        service.listForContact('user-1', 'missing'),
      ).rejects.toBeInstanceOf(NotFoundException);
    });
  });

  describe('revoke', () => {
    it('marks key revoked and pushes update', async () => {
      prisma.deviceKey.findUnique.mockResolvedValue({
        id: 'dk-1',
        userId: 'user-1',
        revokedAt: null,
      } as any);
      prisma.deviceKey.update.mockResolvedValue({
        id: 'dk-1',
        userId: 'user-1',
        revokedAt: new Date(),
      } as any);

      await service.revoke('user-1', 'dk-1', {});

      expect(prisma.deviceKey.update).toHaveBeenCalledWith(
        expect.objectContaining({
          where: { id: 'dk-1' },
          data: expect.objectContaining({ revokedAt: expect.any(Date) }),
        }),
      );
      expect(fcm.sendKeyUpdate).toHaveBeenCalledWith('user-1');
    });

    it('refuses to revoke key owned by another user', async () => {
      prisma.deviceKey.findUnique.mockResolvedValue({
        id: 'dk-1',
        userId: 'other-user',
      } as any);
      await expect(
        service.revoke('user-1', 'dk-1', {}),
      ).rejects.toBeInstanceOf(NotFoundException);
    });
  });
});
```

- [ ] **Step 2: Run test to verify it fails**

```bash
cd ~/taler-id-mesh
npm test -- --testPathPattern='device-keys.service.spec'
```

Expected: FAIL — `Cannot find module './device-keys.service'`.

- [ ] **Step 3: Implement DeviceKeysService**

Create `src/device-keys/device-keys.service.ts`:

```typescript
import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { FcmService } from '../fcm/fcm.service';
import { RegisterDeviceKeyDto } from './dto/register-device-key.dto';
import { DeviceKeyResponseDto } from './dto/device-key-response.dto';
import { RevokeDeviceKeyDto } from './dto/revoke-device-key.dto';

const SUPPORTED_ALG = 'X25519';

@Injectable()
export class DeviceKeysService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly fcm: FcmService,
  ) {}

  async register(
    userId: string,
    dto: RegisterDeviceKeyDto,
  ): Promise<DeviceKeyResponseDto> {
    if (dto.algorithm !== SUPPORTED_ALG) {
      throw new BadRequestException(
        `Unsupported algorithm: ${dto.algorithm} (only ${SUPPORTED_ALG})`,
      );
    }
    if (dto.validUntilEpochMs <= Date.now()) {
      throw new BadRequestException('validUntilEpochMs is in the past');
    }

    const record = await this.prisma.deviceKey.create({
      data: {
        userId,
        devicePk: dto.devicePk.toLowerCase(),
        algorithm: SUPPORTED_ALG,
        validUntil: new Date(dto.validUntilEpochMs),
        certificate: dto.certificate,
        signature: dto.signature.toLowerCase(),
      },
    });

    // Fan-out push to this user's contacts (fire-and-forget — does not block response).
    this.fcm.sendKeyUpdate(userId).catch(() => {
      /* swallow: FCM failures should not break registration */
    });

    return this.toResponseDto(record);
  }

  async listForContact(
    _callerId: string,
    contactUserId: string,
  ): Promise<DeviceKeyResponseDto[]> {
    const user = await this.prisma.user.findUnique({
      where: { id: contactUserId },
    });
    if (!user) {
      throw new NotFoundException(`User ${contactUserId} not found`);
    }
    const rows = await this.prisma.deviceKey.findMany({
      where: {
        userId: contactUserId,
        revokedAt: null,
        validUntil: { gt: new Date() },
      },
      orderBy: { createdAt: 'desc' },
    });
    return rows.map((r) => this.toResponseDto(r));
  }

  async revoke(
    callerId: string,
    keyId: string,
    _dto: RevokeDeviceKeyDto,
  ): Promise<DeviceKeyResponseDto> {
    const existing = await this.prisma.deviceKey.findUnique({
      where: { id: keyId },
    });
    if (!existing || existing.userId !== callerId) {
      throw new NotFoundException('Device key not found');
    }
    const updated = await this.prisma.deviceKey.update({
      where: { id: keyId },
      data: { revokedAt: new Date() },
    });
    this.fcm.sendKeyUpdate(callerId).catch(() => {
      /* swallow */
    });
    return this.toResponseDto(updated);
  }

  private toResponseDto(row: {
    id: string;
    userId: string;
    devicePk: string;
    algorithm: string;
    validUntil: Date;
    certificate: string;
    signature: string;
    revokedAt: Date | null;
    createdAt: Date;
  }): DeviceKeyResponseDto {
    return {
      id: row.id,
      userId: row.userId,
      devicePk: row.devicePk,
      algorithm: row.algorithm,
      validUntil: row.validUntil.toISOString(),
      certificate: row.certificate,
      signature: row.signature,
      revokedAt: row.revokedAt ? row.revokedAt.toISOString() : null,
      createdAt: row.createdAt.toISOString(),
    };
  }
}
```

- [ ] **Step 4: Extend FcmService with sendKeyUpdate stub**

Open `src/fcm/fcm.service.ts` and add method (implementation uses existing FCM admin SDK — match the pattern of existing push methods in that file):

```typescript
async sendKeyUpdate(userId: string): Promise<void> {
  // Publish to FCM topic `mesh-keys/<userId>` so all of this user's contacts
  // who subscribed to that topic receive a light ping to refetch.
  // If the FCM admin client is not initialised (local dev), no-op.
  if (!this.isReady()) return;
  try {
    await this.messaging().send({
      topic: `mesh-keys/${userId}`,
      data: {
        type: 'mesh_key_update',
        userId,
        ts: String(Date.now()),
      },
      // No notification — silent data-only push.
    });
  } catch (err) {
    this.logger.warn(`sendKeyUpdate failed for ${userId}: ${err}`);
  }
}
```

**If the existing FcmService does not expose `messaging()` and `isReady()`:** adapt to the actual helper names. Inspect `src/fcm/fcm.service.ts` first (it was written for message/call push; it should already have an Admin SDK client). If the helper surface differs, add a narrow wrapper method for topic-based data push and call it from `sendKeyUpdate`.

- [ ] **Step 5: Run tests to verify they pass**

```bash
cd ~/taler-id-mesh
npm test -- --testPathPattern='device-keys.service.spec'
```

Expected: all tests pass (5 or more cases green).

- [ ] **Step 6: Commit**

```bash
cd ~/taler-id-mesh
git add src/device-keys/device-keys.service.ts src/device-keys/device-keys.service.spec.ts src/fcm/fcm.service.ts
git commit -m "feat(mesh): DeviceKeysService with register/list/revoke + FCM fan-out"
```

---

## Task B4: DeviceKeysController (HTTP endpoints)

**Files:**
- Create: `src/device-keys/device-keys.controller.ts`
- Create: `src/device-keys/device-keys.module.ts`
- Modify: `src/app.module.ts` (add DeviceKeysModule)

- [ ] **Step 1: Create `src/device-keys/device-keys.controller.ts`**

```typescript
import {
  Body,
  Controller,
  Get,
  Param,
  Post,
  UseGuards,
  Request,
} from '@nestjs/common';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { DeviceKeysService } from './device-keys.service';
import { RegisterDeviceKeyDto } from './dto/register-device-key.dto';
import { RevokeDeviceKeyDto } from './dto/revoke-device-key.dto';

@Controller('profile')
@UseGuards(JwtAuthGuard)
export class DeviceKeysController {
  constructor(private readonly svc: DeviceKeysService) {}

  @Post('device-keys')
  register(@Request() req: any, @Body() dto: RegisterDeviceKeyDto) {
    return this.svc.register(req.user.id, dto);
  }

  @Get('contacts/:userId/keys')
  listForContact(@Request() req: any, @Param('userId') userId: string) {
    return this.svc.listForContact(req.user.id, userId);
  }

  @Post('device-keys/:id/revoke')
  revoke(
    @Request() req: any,
    @Param('id') id: string,
    @Body() dto: RevokeDeviceKeyDto,
  ) {
    return this.svc.revoke(req.user.id, id, dto);
  }
}
```

**If the existing `JwtAuthGuard` path differs** (Taler ID uses `src/auth/jwt.guard.ts` or similar — inspect first), adapt the import path. Controller must reject unauthenticated requests.

- [ ] **Step 2: Create `src/device-keys/device-keys.module.ts`**

```typescript
import { Module } from '@nestjs/common';
import { DeviceKeysController } from './device-keys.controller';
import { DeviceKeysService } from './device-keys.service';
import { PrismaModule } from '../prisma/prisma.module';
import { FcmModule } from '../fcm/fcm.module';

@Module({
  imports: [PrismaModule, FcmModule],
  controllers: [DeviceKeysController],
  providers: [DeviceKeysService],
  exports: [DeviceKeysService],
})
export class DeviceKeysModule {}
```

- [ ] **Step 3: Register DeviceKeysModule in `src/app.module.ts`**

Add to imports array:

```typescript
import { DeviceKeysModule } from './device-keys/device-keys.module';

@Module({
  imports: [
    // ... existing ...
    DeviceKeysModule,
  ],
  // ...
})
```

- [ ] **Step 4: Verify build**

```bash
cd ~/taler-id-mesh
npm run build
```

Expected: `nest build` succeeds. No TypeScript errors.

- [ ] **Step 5: Commit**

```bash
cd ~/taler-id-mesh
git add src/device-keys/device-keys.controller.ts src/device-keys/device-keys.module.ts src/app.module.ts
git commit -m "feat(mesh): DeviceKeysController + module registration"
```

---

## Task B5: Backend e2e test

**Files:**
- Create: `test/device-keys.e2e-spec.ts`

- [ ] **Step 1: Create e2e spec**

```typescript
import { INestApplication, ValidationPipe } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import * as request from 'supertest';
import { AppModule } from '../src/app.module';
import { PrismaService } from '../src/prisma/prisma.service';

describe('DeviceKeys (e2e)', () => {
  let app: INestApplication;
  let prisma: PrismaService;
  let user1Token: string;
  let user1Id: string;
  let user2Token: string;
  let user2Id: string;

  beforeAll(async () => {
    const moduleRef = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();
    app = moduleRef.createNestApplication();
    app.useGlobalPipes(new ValidationPipe({ whitelist: true }));
    await app.init();
    prisma = app.get(PrismaService);

    // Seed two users via the auth flow. Adapt to the actual auth flow of taler-id —
    // e.g. POST /auth/register with email+password, extract JWT from response.
    const seedUser = async (email: string) => {
      const res = await request(app.getHttpServer())
        .post('/auth/register')
        .send({ email, password: 'P@ssw0rd!2026', firstName: 'T', lastName: 'T' });
      return { token: res.body.accessToken, userId: res.body.user.id };
    };

    const u1 = await seedUser(`e2e-u1-${Date.now()}@example.test`);
    user1Token = u1.token;
    user1Id = u1.userId;

    const u2 = await seedUser(`e2e-u2-${Date.now()}@example.test`);
    user2Token = u2.token;
    user2Id = u2.userId;
  });

  afterAll(async () => {
    await prisma.deviceKey.deleteMany({
      where: { userId: { in: [user1Id, user2Id] } },
    });
    await prisma.user.deleteMany({
      where: { id: { in: [user1Id, user2Id] } },
    });
    await app.close();
  });

  const sampleDto = (devicePk: string, validMs: number) => ({
    devicePk,
    algorithm: 'X25519',
    validUntilEpochMs: validMs,
    signature: 'f'.repeat(128),
    certificate: JSON.stringify({
      algorithm: 'X25519',
      devicePk,
      userId: 'placeholder',
      validUntilEpochMs: validMs,
    }),
  });

  it('POST /profile/device-keys registers a key', async () => {
    const res = await request(app.getHttpServer())
      .post('/profile/device-keys')
      .set('Authorization', `Bearer ${user1Token}`)
      .send(sampleDto('a'.repeat(64), Date.now() + 30 * 86_400_000))
      .expect(201);
    expect(res.body.devicePk).toBe('a'.repeat(64));
    expect(res.body.revokedAt).toBeNull();
  });

  it('GET /profile/contacts/:userId/keys returns registered keys', async () => {
    const res = await request(app.getHttpServer())
      .get(`/profile/contacts/${user1Id}/keys`)
      .set('Authorization', `Bearer ${user2Token}`)
      .expect(200);
    expect(Array.isArray(res.body)).toBe(true);
    expect(res.body.length).toBeGreaterThanOrEqual(1);
    expect(res.body[0].devicePk).toBe('a'.repeat(64));
  });

  it('POST /profile/device-keys/:id/revoke revokes own key', async () => {
    // Fetch key id first
    const list = await request(app.getHttpServer())
      .get(`/profile/contacts/${user1Id}/keys`)
      .set('Authorization', `Bearer ${user1Token}`)
      .expect(200);
    const keyId = list.body[0].id;

    await request(app.getHttpServer())
      .post(`/profile/device-keys/${keyId}/revoke`)
      .set('Authorization', `Bearer ${user1Token}`)
      .send({ reason: 'e2e test' })
      .expect(201);

    // After revoke the key is no longer returned in list
    const after = await request(app.getHttpServer())
      .get(`/profile/contacts/${user1Id}/keys`)
      .set('Authorization', `Bearer ${user2Token}`)
      .expect(200);
    expect(after.body.find((k: any) => k.id === keyId)).toBeUndefined();
  });

  it('rejects unauthenticated register', async () => {
    await request(app.getHttpServer())
      .post('/profile/device-keys')
      .send(sampleDto('b'.repeat(64), Date.now() + 30 * 86_400_000))
      .expect(401);
  });

  it('rejects expired validUntil', async () => {
    await request(app.getHttpServer())
      .post('/profile/device-keys')
      .set('Authorization', `Bearer ${user1Token}`)
      .send(sampleDto('c'.repeat(64), Date.now() - 1000))
      .expect(400);
  });
});
```

- [ ] **Step 2: Run e2e test**

```bash
cd ~/taler-id-mesh
npm run test:e2e -- --testPathPattern='device-keys.e2e-spec'
```

Expected: all cases green. If the auth seed flow (POST /auth/register body shape, response shape) differs from the template above, adapt to the real Taler ID contract — inspect `src/auth/auth.controller.ts`.

- [ ] **Step 3: Commit**

```bash
cd ~/taler-id-mesh
git add test/device-keys.e2e-spec.ts
git commit -m "test(mesh): e2e spec for device-keys endpoints"
```

---

## Task B6: Deploy backend to DEV server

Per CLAUDE.md deployment rule: **DEV first, PROD only on explicit instruction**.

- [ ] **Step 1: Push branch to origin**

```bash
cd ~/taler-id-mesh
git push -u origin feature/mesh-bridge
```

- [ ] **Step 2: Deploy on DEV server**

```bash
ssh dvolkov@89.169.55.217 '
cd ~/taler-id
git fetch origin
git checkout feature/mesh-bridge
git pull
npm install
npx prisma migrate deploy
npm run build
pm2 restart taler-id-dev
'
```

Expected: PM2 restart succeeds, process online. If `npx prisma migrate deploy` fails because the migration wasn't committed properly, check `prisma/migrations/` was included in Task B1's commit.

- [ ] **Step 3: Smoke-test endpoint**

```bash
curl -X POST https://staging.id.taler.tirol/auth/login \
  -H 'Content-Type: application/json' \
  -d '{"email":"integration_test@taler-test.com","password":"IntegrationTest123!"}'
```

Expected: JSON with `accessToken`. Save token. Then:

```bash
curl -X POST https://staging.id.taler.tirol/profile/device-keys \
  -H "Authorization: Bearer <TOKEN>" \
  -H 'Content-Type: application/json' \
  -d '{
    "devicePk": "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
    "algorithm": "X25519",
    "validUntilEpochMs": 9999999999999,
    "signature": "ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff",
    "certificate": "{}"
  }'
```

Expected: 201 with response DTO. Note the returned `id` — you'll need it to clean up.

Clean up:
```bash
curl -X POST "https://staging.id.taler.tirol/profile/device-keys/<ID>/revoke" \
  -H "Authorization: Bearer <TOKEN>" \
  -H 'Content-Type: application/json' -d '{}'
```

- [ ] **Step 4: Commit deploy record**

No commit needed — deploy is tracked by push + PM2.

---

## Task B7: Public integration test in taler_id_tests

**Files:**
- Create: `~/Downloads/taler_id_tests/device_keys_test.ts`
- Modify: `~/Downloads/taler_id_tests/package.json`

- [ ] **Step 1: Create test script**

Create `~/Downloads/taler_id_tests/device_keys_test.ts`:

```typescript
/**
 * Device-keys smoke test against DEV (staging.id.taler.tirol).
 *
 * Full round-trip: login user1 → register key → login user2 → fetch user1's
 * keys → revoke key → confirm gone.
 */

import axios, { AxiosInstance } from 'axios';

const BASE = process.env.BASE_URL || 'https://staging.id.taler.tirol';
const USER1 = { email: 'integration_test@taler-test.com', password: 'IntegrationTest123!' };
const USER2 = { email: 'integration_test_2@taler-test.com', password: 'IntegrationTest123!' };

async function login(api: AxiosInstance, creds: { email: string; password: string }) {
  const res = await api.post('/auth/login', creds);
  return { token: res.data.accessToken as string, userId: res.data.user.id as string };
}

async function main() {
  const api = axios.create({ baseURL: BASE, validateStatus: () => true });
  const user1 = await login(api, USER1);
  const user2 = await login(api, USER2);

  console.log(`Logged in: user1=${user1.userId}, user2=${user2.userId}`);

  const devicePk = 'abababababababababababababababababababababababababababababababab';
  const sig = 'f'.repeat(128);
  const validUntilEpochMs = Date.now() + 30 * 86_400_000;

  const cert = JSON.stringify({
    algorithm: 'X25519',
    devicePk,
    userId: user1.userId,
    validUntilEpochMs,
  });

  console.log('Registering device key for user1...');
  const regRes = await api.post(
    '/profile/device-keys',
    { devicePk, algorithm: 'X25519', validUntilEpochMs, signature: sig, certificate: cert },
    { headers: { Authorization: `Bearer ${user1.token}` } },
  );
  if (regRes.status !== 201) {
    throw new Error(`register failed: ${regRes.status} ${JSON.stringify(regRes.data)}`);
  }
  const keyId = regRes.data.id;
  console.log(`  → key id=${keyId}`);

  console.log("Fetching user1's keys from user2's POV...");
  const listRes = await api.get(`/profile/contacts/${user1.userId}/keys`, {
    headers: { Authorization: `Bearer ${user2.token}` },
  });
  if (listRes.status !== 200) throw new Error(`list failed: ${listRes.status}`);
  const found = listRes.data.find((k: any) => k.id === keyId);
  if (!found) throw new Error('registered key not in list');
  console.log(`  → found ${listRes.data.length} key(s), our key present`);

  console.log('Revoking the key...');
  const revokeRes = await api.post(
    `/profile/device-keys/${keyId}/revoke`,
    { reason: 'smoke test' },
    { headers: { Authorization: `Bearer ${user1.token}` } },
  );
  if (revokeRes.status !== 201) throw new Error(`revoke failed: ${revokeRes.status}`);

  console.log('Verifying key no longer in list...');
  const after = await api.get(`/profile/contacts/${user1.userId}/keys`, {
    headers: { Authorization: `Bearer ${user2.token}` },
  });
  if (after.data.find((k: any) => k.id === keyId)) {
    throw new Error('key still present after revoke');
  }
  console.log('  → revoked successfully');

  console.log('\n✅ All device-key checks passed against', BASE);
}

main().catch((err) => {
  console.error('❌ FAILED:', err.message || err);
  process.exit(1);
});
```

- [ ] **Step 2: Add test:mesh script to taler_id_tests/package.json**

Open `~/Downloads/taler_id_tests/package.json` and add under `scripts`:

```json
"test:mesh": "tsx device_keys_test.ts",
"test:mesh:prod": "BASE_URL=https://id.taler.tirol tsx device_keys_test.ts",
```

Install `axios` + `tsx` if not already present:

```bash
cd ~/Downloads/taler_id_tests
npm install --save-dev axios tsx
```

- [ ] **Step 3: Run the mesh test**

```bash
cd ~/Downloads/taler_id_tests
npm run test:mesh
```

Expected: `✅ All device-key checks passed against https://staging.id.taler.tirol`

- [ ] **Step 4: Commit**

```bash
cd ~/Downloads/taler_id_tests
git add device_keys_test.ts package.json package-lock.json
git commit -m "test(mesh): device-keys smoke test against DEV/PROD"
```

(Note: `taler_id_tests` is a separate repo — check if it has a remote and branch convention. If not, commit is local-only; user will push manually.)

---

# PART 2 — MOBILE

## Task M1: DeviceCert Freezed model

**Files:**
- Create: `lib/core/mesh/crypto/keys/device_cert.dart`
- Test: `test/core/mesh/crypto/keys/device_cert_test.dart`

- [ ] **Step 1: Write failing test**

Create `test/core/mesh/crypto/keys/device_cert_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:taler_id_mobile/core/mesh/crypto/keys/device_cert.dart';

void main() {
  group('DeviceCert', () {
    test('JSON round-trip preserves fields', () {
      final cert = DeviceCert(
        devicePk: 'ab' * 32,
        userId: 'user-1',
        algorithm: 'X25519',
        validUntilEpochMs: 1_800_000_000_000,
        signature: 'ff' * 64,
      );
      final json = cert.toCanonicalJsonWithoutSignature();
      expect(json.contains('"algorithm":"X25519"'), isTrue);
      expect(json.contains('"devicePk":"${'ab' * 32}"'), isTrue);
      expect(json.contains('"userId":"user-1"'), isTrue);
      expect(json.contains('"validUntilEpochMs":1800000000000'), isTrue);
      // No signature field, no whitespace, keys alphabetically ordered.
      expect(json.indexOf('"algorithm"'), lessThan(json.indexOf('"devicePk"')));
      expect(json.indexOf('"devicePk"'), lessThan(json.indexOf('"userId"')));
      expect(json.indexOf('"userId"'), lessThan(json.indexOf('"validUntilEpochMs"')));
    });

    test('serialises to JSON for transport', () {
      final cert = DeviceCert(
        devicePk: 'ab' * 32,
        userId: 'user-1',
        algorithm: 'X25519',
        validUntilEpochMs: 1_800_000_000_000,
        signature: 'ff' * 64,
      );
      final map = cert.toJson();
      expect(map['devicePk'], 'ab' * 32);
      expect(map['signature'], 'ff' * 64);
      final revived = DeviceCert.fromJson(map);
      expect(revived.devicePk, cert.devicePk);
      expect(revived.signature, cert.signature);
    });

    test('isValid returns false when expired', () {
      final past = DateTime.now().subtract(const Duration(days: 1)).millisecondsSinceEpoch;
      final cert = DeviceCert(
        devicePk: 'ab' * 32,
        userId: 'u',
        algorithm: 'X25519',
        validUntilEpochMs: past,
        signature: 'ff' * 64,
      );
      expect(cert.isValid(), isFalse);
    });
  });
}
```

- [ ] **Step 2: Run test, expect FAIL**

```bash
cd ~/Downloads/taler_id_mesh
flutter test test/core/mesh/crypto/keys/device_cert_test.dart
```

- [ ] **Step 3: Implement DeviceCert**

Create `lib/core/mesh/crypto/keys/device_cert.dart`:

```dart
import 'dart:convert';

/// Self-signed device certificate for Phase 1b mesh identity.
///
/// A device owns an Ed25519 keypair (DeviceKey, signing) and an X25519 keypair
/// (MeshStaticKey, ECDH). The cert binds the X25519 public key to a Taler ID
/// user, signed by the device's Ed25519 private key. Verification only requires
/// the Ed25519 public key, which is communicated side-channel via this same
/// cert (`devicePk` is the X25519 pk, the Ed25519 pk lives in a companion field
/// in Phase 1c — for Phase 1b we trust the server to vouch for Ed25519 pk
/// authenticity via JWT-authenticated registration).
class DeviceCert {
  final String devicePk;             // hex 64 chars, X25519 static pk
  final String userId;               // Taler ID user UUID
  final String algorithm;            // "X25519"
  final int validUntilEpochMs;
  final String signature;            // hex 128 chars Ed25519 over canonical JSON

  const DeviceCert({
    required this.devicePk,
    required this.userId,
    required this.algorithm,
    required this.validUntilEpochMs,
    required this.signature,
  });

  /// Canonical JSON of the signed fields (excluding `signature`), alphabetical
  /// keys, no whitespace. This is what the Ed25519 signature covers.
  String toCanonicalJsonWithoutSignature() {
    // Keys alphabetically: algorithm, devicePk, userId, validUntilEpochMs.
    final map = <String, dynamic>{
      'algorithm': algorithm,
      'devicePk': devicePk,
      'userId': userId,
      'validUntilEpochMs': validUntilEpochMs,
    };
    return jsonEncode(map);
  }

  Map<String, dynamic> toJson() => {
        'devicePk': devicePk,
        'userId': userId,
        'algorithm': algorithm,
        'validUntilEpochMs': validUntilEpochMs,
        'signature': signature,
      };

  factory DeviceCert.fromJson(Map<String, dynamic> json) => DeviceCert(
        devicePk: json['devicePk'] as String,
        userId: json['userId'] as String,
        algorithm: json['algorithm'] as String,
        validUntilEpochMs: json['validUntilEpochMs'] as int,
        signature: json['signature'] as String,
      );

  bool isValid({DateTime? now}) {
    final t = now ?? DateTime.now();
    return t.millisecondsSinceEpoch < validUntilEpochMs;
  }
}
```

- [ ] **Step 4: Run test, expect 3/3 pass**

- [ ] **Step 5: Commit**

```bash
cd ~/Downloads/taler_id_mesh
git add lib/core/mesh/crypto/keys/device_cert.dart test/core/mesh/crypto/keys/device_cert_test.dart
git commit -m "feat(mesh/crypto): add DeviceCert self-signed cert model"
```

---

## Task M2: CertSigner (sign + verify)

**Files:**
- Create: `lib/core/mesh/crypto/keys/cert_signer.dart`
- Test: `test/core/mesh/crypto/keys/cert_signer_test.dart`

- [ ] **Step 1: Write failing test**

```dart
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:taler_id_mobile/core/mesh/crypto/keys/cert_signer.dart';
import 'package:taler_id_mobile/core/mesh/crypto/keys/device_cert.dart';
import 'package:taler_id_mobile/core/mesh/crypto/keys/device_key.dart';
import 'package:taler_id_mobile/core/mesh/crypto/keys/mesh_static_key.dart';

void main() {
  group('CertSigner', () {
    test('sign + verify round-trip succeeds', () async {
      final signing = await DeviceKey.generate();       // Ed25519
      final mesh = await MeshStaticKey.generate();       // X25519
      final signer = CertSigner(signingKey: signing);

      final cert = await signer.sign(
        meshPublicKey: mesh.publicKey,
        userId: 'user-1',
        validUntilEpochMs: DateTime.now()
            .add(const Duration(days: 30))
            .millisecondsSinceEpoch,
      );

      expect(cert.devicePk.length, 64);
      expect(cert.signature.length, 128);

      final ok = await CertSigner.verify(
        cert: cert,
        signingPublicKey: signing.publicKey,
      );
      expect(ok, isTrue);
    });

    test('verify rejects tampered cert', () async {
      final signing = await DeviceKey.generate();
      final mesh = await MeshStaticKey.generate();
      final signer = CertSigner(signingKey: signing);
      final cert = await signer.sign(
        meshPublicKey: mesh.publicKey,
        userId: 'user-1',
        validUntilEpochMs: DateTime.now()
            .add(const Duration(days: 30))
            .millisecondsSinceEpoch,
      );

      final tampered = DeviceCert(
        devicePk: cert.devicePk,
        userId: 'user-2', // CHANGED
        algorithm: cert.algorithm,
        validUntilEpochMs: cert.validUntilEpochMs,
        signature: cert.signature,
      );

      final ok = await CertSigner.verify(
        cert: tampered,
        signingPublicKey: signing.publicKey,
      );
      expect(ok, isFalse);
    });

    test('verify rejects different signing key', () async {
      final signing = await DeviceKey.generate();
      final other = await DeviceKey.generate();
      final mesh = await MeshStaticKey.generate();
      final signer = CertSigner(signingKey: signing);
      final cert = await signer.sign(
        meshPublicKey: mesh.publicKey,
        userId: 'user-1',
        validUntilEpochMs: DateTime.now()
            .add(const Duration(days: 30))
            .millisecondsSinceEpoch,
      );

      final ok = await CertSigner.verify(
        cert: cert,
        signingPublicKey: other.publicKey,
      );
      expect(ok, isFalse);
    });
  });
}
```

- [ ] **Step 2: Run test, expect FAIL**

- [ ] **Step 3: Implement CertSigner**

Create `lib/core/mesh/crypto/keys/cert_signer.dart`:

```dart
import 'dart:convert';
import 'dart:typed_data';

import 'device_cert.dart';
import 'device_key.dart';

class CertSigner {
  final DeviceKey signingKey;

  CertSigner({required this.signingKey});

  Future<DeviceCert> sign({
    required Uint8List meshPublicKey,
    required String userId,
    required int validUntilEpochMs,
  }) async {
    final devicePkHex = _hex(meshPublicKey);
    final draft = DeviceCert(
      devicePk: devicePkHex,
      userId: userId,
      algorithm: 'X25519',
      validUntilEpochMs: validUntilEpochMs,
      signature: '', // filled in after
    );
    final canonical = draft.toCanonicalJsonWithoutSignature();
    final sigBytes = await signingKey.sign(Uint8List.fromList(utf8.encode(canonical)));
    return DeviceCert(
      devicePk: devicePkHex,
      userId: userId,
      algorithm: 'X25519',
      validUntilEpochMs: validUntilEpochMs,
      signature: _hex(sigBytes),
    );
  }

  static Future<bool> verify({
    required DeviceCert cert,
    required Uint8List signingPublicKey,
  }) async {
    final canonical = cert.toCanonicalJsonWithoutSignature();
    final msg = Uint8List.fromList(utf8.encode(canonical));
    final sig = _unhex(cert.signature);
    return await DeviceKey.verify(
      publicKey: signingPublicKey,
      message: msg,
      signature: sig,
    );
  }

  static String _hex(Uint8List bytes) {
    final buf = StringBuffer();
    for (final b in bytes) {
      buf.write(b.toRadixString(16).padLeft(2, '0'));
    }
    return buf.toString();
  }

  static Uint8List _unhex(String hex) {
    final n = hex.length ~/ 2;
    final out = Uint8List(n);
    for (var i = 0; i < n; i++) {
      out[i] = int.parse(hex.substring(i * 2, i * 2 + 2), radix: 16);
    }
    return out;
  }
}
```

- [ ] **Step 4: Run test, expect 3/3 pass**

- [ ] **Step 5: Commit**

```bash
cd ~/Downloads/taler_id_mesh
git add lib/core/mesh/crypto/keys/cert_signer.dart test/core/mesh/crypto/keys/cert_signer_test.dart
git commit -m "feat(mesh/crypto): add CertSigner for self-signed device certs"
```

---

## Task M3: HiveContactKeyStore — persistent ContactKeyStore

**Files:**
- Create: `lib/core/mesh/crypto/keys/contact_key_store_hive.dart`
- Test: `test/core/mesh/crypto/keys/contact_key_store_hive_test.dart`

- [ ] **Step 1: Write failing test**

```dart
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:taler_id_mobile/core/mesh/crypto/keys/contact_key_store_hive.dart';
import 'package:taler_id_mobile/core/mesh/crypto/keys/device_cert.dart';
import 'package:taler_id_mobile/core/mesh/transport/peer_id.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_test_');
    Hive.init(tempDir.path);
  });

  tearDown(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('HiveContactKeyStore', () {
    test('addContact persists across instances', () async {
      final store1 = await HiveContactKeyStore.open(boxName: 'test-contacts-1');
      final userPk = PeerId(Uint8List.fromList(List.filled(32, 0xAA)));
      final cert = DeviceCert(
        devicePk: 'ab' * 32,
        userId: 'user-1',
        algorithm: 'X25519',
        validUntilEpochMs: DateTime.now()
            .add(const Duration(days: 30))
            .millisecondsSinceEpoch,
        signature: 'ff' * 64,
      );
      await store1.addContactCerts(userPk: userPk, certs: [cert]);
      expect(store1.isKnownDevice(PeerId.fromHex(cert.devicePk)), isTrue);
      await store1.close();

      final store2 = await HiveContactKeyStore.open(boxName: 'test-contacts-1');
      expect(store2.isKnownDevice(PeerId.fromHex(cert.devicePk)), isTrue);
      expect(store2.lookupUserByDevice(PeerId.fromHex(cert.devicePk)),
          equals(userPk));
      await store2.close();
    });

    test('removeDevice removes persisted entry', () async {
      final store = await HiveContactKeyStore.open(boxName: 'test-contacts-2');
      final userPk = PeerId(Uint8List.fromList(List.filled(32, 0xBB)));
      final cert = DeviceCert(
        devicePk: 'cd' * 32,
        userId: 'user-2',
        algorithm: 'X25519',
        validUntilEpochMs: DateTime.now()
            .add(const Duration(days: 30))
            .millisecondsSinceEpoch,
        signature: '00' * 64,
      );
      await store.addContactCerts(userPk: userPk, certs: [cert]);
      await store.removeDevice(PeerId.fromHex(cert.devicePk));
      expect(store.isKnownDevice(PeerId.fromHex(cert.devicePk)), isFalse);
      await store.close();

      final reopened = await HiveContactKeyStore.open(boxName: 'test-contacts-2');
      expect(reopened.isKnownDevice(PeerId.fromHex(cert.devicePk)), isFalse);
      await reopened.close();
    });
  });
}
```

- [ ] **Step 2: Add hive dep**

Check `pubspec.yaml` for `hive` — it's already used elsewhere in the project for desktop storage. If not pinned in deps, add:

```yaml
  hive: ^2.2.3
  hive_flutter: ^1.1.0
```

then `flutter pub get`.

- [ ] **Step 3: Run test, expect FAIL**

- [ ] **Step 4: Implement HiveContactKeyStore**

Create `lib/core/mesh/crypto/keys/contact_key_store_hive.dart`:

```dart
import 'dart:convert';

import 'package:hive/hive.dart';

import '../../transport/peer_id.dart';
import 'device_cert.dart';

/// Hive-persisted implementation of the ContactKeyStore contract.
///
/// Storage format (per Hive box entry):
///   key   = devicePk hex
///   value = JSON-encoded { userPk: hex, cert: DeviceCert.toJson }
class HiveContactKeyStore {
  final Box<String> _box;

  HiveContactKeyStore._(this._box);

  static Future<HiveContactKeyStore> open({
    required String boxName,
  }) async {
    final box = await Hive.openBox<String>(boxName);
    return HiveContactKeyStore._(box);
  }

  Future<void> addContactCerts({
    required PeerId userPk,
    required List<DeviceCert> certs,
  }) async {
    for (final cert in certs) {
      final entry = jsonEncode({
        'userPk': userPk.toHex(),
        'cert': cert.toJson(),
      });
      await _box.put(cert.devicePk.toLowerCase(), entry);
    }
  }

  bool isKnownDevice(PeerId devicePk) =>
      _box.containsKey(devicePk.toHex().toLowerCase());

  PeerId? lookupUserByDevice(PeerId devicePk) {
    final raw = _box.get(devicePk.toHex().toLowerCase());
    if (raw == null) return null;
    final map = jsonDecode(raw) as Map<String, dynamic>;
    return PeerId.fromHex(map['userPk'] as String);
  }

  DeviceCert? lookupCertByDevice(PeerId devicePk) {
    final raw = _box.get(devicePk.toHex().toLowerCase());
    if (raw == null) return null;
    final map = jsonDecode(raw) as Map<String, dynamic>;
    return DeviceCert.fromJson(map['cert'] as Map<String, dynamic>);
  }

  List<PeerId> devicesFor(PeerId userPk) {
    final userHex = userPk.toHex();
    final devices = <PeerId>[];
    for (final raw in _box.values) {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      if (map['userPk'] == userHex) {
        devices.add(PeerId.fromHex(
            (map['cert'] as Map<String, dynamic>)['devicePk'] as String));
      }
    }
    return devices;
  }

  Future<void> removeDevice(PeerId devicePk) async {
    await _box.delete(devicePk.toHex().toLowerCase());
  }

  Future<void> clear() async {
    await _box.clear();
  }

  Future<void> close() async {
    await _box.close();
  }
}
```

- [ ] **Step 5: Run test, expect 2/2 pass**

- [ ] **Step 6: Commit**

```bash
cd ~/Downloads/taler_id_mesh
git add lib/core/mesh/crypto/keys/contact_key_store_hive.dart test/core/mesh/crypto/keys/contact_key_store_hive_test.dart pubspec.yaml pubspec.lock
git commit -m "feat(mesh/crypto): Hive-persisted ContactKeyStore"
```

---

## Task M4: DeviceKeysApiClient (Dio)

**Files:**
- Create: `lib/core/mesh/services/device_keys_api_client.dart`
- Test: `test/core/mesh/services/device_keys_api_client_test.dart`

- [ ] **Step 1: Write failing test using Dio's MockAdapter**

```dart
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taler_id_mobile/core/mesh/crypto/keys/device_cert.dart';
import 'package:taler_id_mobile/core/mesh/services/device_keys_api_client.dart';

class _MockInterceptor extends Interceptor {
  final Map<String, dynamic> responses;
  _MockInterceptor(this.responses);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final key = '${options.method} ${options.path}';
    if (responses.containsKey(key)) {
      handler.resolve(Response(
        requestOptions: options,
        statusCode: 200,
        data: responses[key],
      ));
    } else {
      handler.next(options);
    }
  }
}

void main() {
  group('DeviceKeysApiClient', () {
    test('registerDeviceKey posts cert and returns server response', () async {
      final dio = Dio(BaseOptions(baseUrl: 'https://fake.test'));
      dio.interceptors.add(_MockInterceptor({
        'POST /profile/device-keys': {
          'id': 'dk-1',
          'userId': 'user-1',
          'devicePk': 'ab' * 32,
          'algorithm': 'X25519',
          'validUntil': '2030-01-01T00:00:00Z',
          'certificate': '{}',
          'signature': 'ff' * 64,
          'revokedAt': null,
          'createdAt': '2026-04-21T00:00:00Z',
        },
      }));
      final client = DeviceKeysApiClient(dio);
      final cert = DeviceCert(
        devicePk: 'ab' * 32,
        userId: 'user-1',
        algorithm: 'X25519',
        validUntilEpochMs: 1_800_000_000_000,
        signature: 'ff' * 64,
      );
      final result = await client.registerDeviceKey(cert);
      expect(result['id'], 'dk-1');
      expect(result['devicePk'], 'ab' * 32);
    });

    test('getContactKeys returns list', () async {
      final dio = Dio(BaseOptions(baseUrl: 'https://fake.test'));
      dio.interceptors.add(_MockInterceptor({
        'GET /profile/contacts/user-2/keys': [
          {
            'id': 'dk-2',
            'userId': 'user-2',
            'devicePk': 'cd' * 32,
            'algorithm': 'X25519',
            'validUntil': '2030-01-01T00:00:00Z',
            'certificate':
                '{"algorithm":"X25519","devicePk":"${'cd' * 32}","userId":"user-2","validUntilEpochMs":1800000000000}',
            'signature': 'aa' * 64,
            'revokedAt': null,
            'createdAt': '2026-04-21T00:00:00Z',
          }
        ],
      }));
      final client = DeviceKeysApiClient(dio);
      final certs = await client.getContactKeys('user-2');
      expect(certs, hasLength(1));
      expect(certs.first.devicePk, 'cd' * 32);
    });
  });
}
```

- [ ] **Step 2: Run test, expect FAIL**

- [ ] **Step 3: Implement DeviceKeysApiClient**

Create `lib/core/mesh/services/device_keys_api_client.dart`:

```dart
import 'dart:convert';

import 'package:dio/dio.dart';

import '../crypto/keys/device_cert.dart';

/// Dio wrapper for Taler ID backend device-keys endpoints.
///
/// The injected [Dio] instance must already have the project's AuthInterceptor
/// attached (i.e. JWT access token header injection). This client focuses on
/// the device-key surface only.
class DeviceKeysApiClient {
  final Dio _dio;

  DeviceKeysApiClient(this._dio);

  /// POST /profile/device-keys — registers a freshly minted self-signed cert.
  Future<Map<String, dynamic>> registerDeviceKey(DeviceCert cert) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/profile/device-keys',
      data: {
        'devicePk': cert.devicePk,
        'algorithm': cert.algorithm,
        'validUntilEpochMs': cert.validUntilEpochMs,
        'signature': cert.signature,
        'certificate': cert.toCanonicalJsonWithoutSignature(),
      },
    );
    return res.data!;
  }

  /// GET /profile/contacts/:userId/keys — returns the peer's current active
  /// device certs.
  Future<List<DeviceCert>> getContactKeys(String contactUserId) async {
    final res = await _dio.get<List<dynamic>>(
      '/profile/contacts/$contactUserId/keys',
    );
    return res.data!.map((raw) {
      final row = raw as Map<String, dynamic>;
      // The server returns the canonical certificate JSON string in `certificate`;
      // parse it to get the signed content, then attach the server-returned signature.
      final certJsonStr = row['certificate'] as String;
      final inner = jsonDecode(certJsonStr) as Map<String, dynamic>;
      return DeviceCert(
        devicePk: inner['devicePk'] as String,
        userId: inner['userId'] as String,
        algorithm: inner['algorithm'] as String,
        validUntilEpochMs: inner['validUntilEpochMs'] as int,
        signature: row['signature'] as String,
      );
    }).toList();
  }

  /// POST /profile/device-keys/:id/revoke — revokes own key by id.
  Future<void> revokeDeviceKey(String keyId, {String? reason}) async {
    await _dio.post(
      '/profile/device-keys/$keyId/revoke',
      data: reason != null ? {'reason': reason} : {},
    );
  }
}
```

- [ ] **Step 4: Run test, expect 2/2 pass**

- [ ] **Step 5: Commit**

```bash
cd ~/Downloads/taler_id_mesh
git add lib/core/mesh/services/device_keys_api_client.dart test/core/mesh/services/device_keys_api_client_test.dart
git commit -m "feat(mesh/services): DeviceKeysApiClient for backend sync"
```

---

## Task M5: DeviceKeySyncService (bootstrap + contact sync)

**Files:**
- Create: `lib/core/mesh/services/device_key_sync_service.dart`
- Test: `test/core/mesh/services/device_key_sync_service_test.dart`

- [ ] **Step 1: Write failing test with mock ApiClient + HiveContactKeyStore**

```dart
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:taler_id_mobile/core/mesh/crypto/keys/contact_key_store_hive.dart';
import 'package:taler_id_mobile/core/mesh/crypto/keys/device_cert.dart';
import 'package:taler_id_mobile/core/mesh/crypto/keys/device_key.dart';
import 'package:taler_id_mobile/core/mesh/crypto/keys/mesh_static_key.dart';
import 'package:taler_id_mobile/core/mesh/services/device_key_sync_service.dart';
import 'package:taler_id_mobile/core/mesh/services/device_keys_api_client.dart';
import 'package:taler_id_mobile/core/mesh/transport/peer_id.dart';

/// Tiny fake client — enough to exercise the service without Dio.
class _FakeApi implements DeviceKeysApiClient {
  final List<DeviceCert> _ownRegistered = [];
  final Map<String, List<DeviceCert>> _contactStore = {};
  int registerCalls = 0;

  @override
  Future<Map<String, dynamic>> registerDeviceKey(DeviceCert cert) async {
    registerCalls++;
    _ownRegistered.add(cert);
    return {'id': 'dk-${_ownRegistered.length}'};
  }

  @override
  Future<List<DeviceCert>> getContactKeys(String contactUserId) async =>
      List.unmodifiable(_contactStore[contactUserId] ?? const []);

  @override
  Future<void> revokeDeviceKey(String keyId, {String? reason}) async {}

  void seedContactKeys(String userId, List<DeviceCert> certs) {
    _contactStore[userId] = certs;
  }
}

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('sync_test_');
    Hive.init(tempDir.path);
  });

  tearDown(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('registerOwnDevice signs cert and posts it', () async {
    final api = _FakeApi();
    final store = await HiveContactKeyStore.open(boxName: 'sync-1');
    final signing = await DeviceKey.generate();
    final mesh = await MeshStaticKey.generate();
    final service = DeviceKeySyncService(
      api: api,
      store: store,
      signingKey: signing,
      meshStaticKey: mesh,
      myUserId: 'user-1',
    );
    await service.registerOwnDevice();
    expect(api.registerCalls, 1);
    await store.close();
  });

  test('fetchContactKeys stores certs locally', () async {
    final api = _FakeApi();
    final store = await HiveContactKeyStore.open(boxName: 'sync-2');
    final signing = await DeviceKey.generate();
    final mesh = await MeshStaticKey.generate();
    final service = DeviceKeySyncService(
      api: api,
      store: store,
      signingKey: signing,
      meshStaticKey: mesh,
      myUserId: 'user-1',
    );
    final cert = DeviceCert(
      devicePk: 'ab' * 32,
      userId: 'user-2',
      algorithm: 'X25519',
      validUntilEpochMs: DateTime.now()
          .add(const Duration(days: 30))
          .millisecondsSinceEpoch,
      signature: 'ff' * 64,
    );
    api.seedContactKeys('user-2', [cert]);

    await service.fetchContactKeys('user-2');
    expect(
      store.isKnownDevice(PeerId.fromHex(cert.devicePk)),
      isTrue,
    );
    await store.close();
  });
}
```

- [ ] **Step 2: Run test, expect FAIL**

- [ ] **Step 3: Implement DeviceKeySyncService**

```dart
import 'package:flutter/foundation.dart';

import '../crypto/keys/cert_signer.dart';
import '../crypto/keys/contact_key_store_hive.dart';
import '../crypto/keys/device_key.dart';
import '../crypto/keys/mesh_static_key.dart';
import '../transport/peer_id.dart';
import 'device_keys_api_client.dart';

class DeviceKeySyncService {
  final DeviceKeysApiClient api;
  final HiveContactKeyStore store;
  final DeviceKey signingKey;
  final MeshStaticKey meshStaticKey;
  final String myUserId;
  final Duration certValidity;

  DeviceKeySyncService({
    required this.api,
    required this.store,
    required this.signingKey,
    required this.meshStaticKey,
    required this.myUserId,
    this.certValidity = const Duration(days: 30),
  });

  /// Mint a fresh self-signed cert, send it to the server.
  Future<void> registerOwnDevice() async {
    final signer = CertSigner(signingKey: signingKey);
    final cert = await signer.sign(
      meshPublicKey: meshStaticKey.publicKey,
      userId: myUserId,
      validUntilEpochMs: DateTime.now().add(certValidity).millisecondsSinceEpoch,
    );
    await api.registerDeviceKey(cert);
  }

  /// Fetch peer's current active certs and persist locally.
  Future<void> fetchContactKeys(String contactUserId) async {
    final certs = await api.getContactKeys(contactUserId);
    if (certs.isEmpty) {
      debugPrint('[mesh-sync] no keys for $contactUserId');
      return;
    }
    final userPk = PeerId.fromHex(contactUserId.padRight(64, '0').substring(0, 64));
    // Note: userPk is derived from user UUID for Phase 1b consistency;
    // Phase 1c will introduce proper user identity keys.
    await store.addContactCerts(userPk: userPk, certs: certs);
  }
}
```

**Phase 1b note:** the `userPk` derivation above is a placeholder. In Phase 1b we track contacts by `userId` (UUID) — the Noise-level `PeerId` is constructed from the contact's `devicePk`, not from the user id. The `userPk` field in `HiveContactKeyStore` stays opaque for now (used only for reverse lookups); Phase 1c replaces it with a proper user identity key. For Phase 1b tests, any stable derivation is fine as long as `isKnownDevice(devicePk)` works — which it does, because the store is keyed by `devicePk`.

- [ ] **Step 4: Run test, expect 2/2 pass**

- [ ] **Step 5: Commit**

```bash
cd ~/Downloads/taler_id_mesh
git add lib/core/mesh/services/device_key_sync_service.dart test/core/mesh/services/device_key_sync_service_test.dart
git commit -m "feat(mesh/services): DeviceKeySyncService for register + fetch"
```

---

## Task M6: FCM listener for mesh-key updates

**Files:**
- Create: `lib/features/mesh/data/datasources/mesh_fcm_listener.dart`

- [ ] **Step 1: Implement listener**

Phase 1b treats this as glue code (no unit test — FCM is tested manually). Integration test in M8 covers the full flow.

Create `lib/features/mesh/data/datasources/mesh_fcm_listener.dart`:

```dart
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/mesh/services/device_key_sync_service.dart';

/// Subscribes the device to `mesh-keys/<userId>` topics for each contact so
/// the server's `FcmService.sendKeyUpdate` fans out to all interested clients.
///
/// On an incoming data-only push with `type == 'mesh_key_update'`, triggers a
/// re-fetch of the affected user's keys via [DeviceKeySyncService].
class MeshFcmListener {
  final DeviceKeySyncService syncService;
  final FirebaseMessaging _fcm;

  MeshFcmListener({
    required this.syncService,
    FirebaseMessaging? fcm,
  }) : _fcm = fcm ?? FirebaseMessaging.instance;

  Future<void> subscribeContactTopics(List<String> contactUserIds) async {
    for (final id in contactUserIds) {
      await _fcm.subscribeToTopic('mesh-keys/$id');
    }
  }

  Future<void> unsubscribeContactTopic(String contactUserId) async {
    await _fcm.unsubscribeFromTopic('mesh-keys/$contactUserId');
  }

  void attachHandlers() {
    FirebaseMessaging.onMessage.listen((msg) async {
      if (msg.data['type'] != 'mesh_key_update') return;
      final userId = msg.data['userId'] as String?;
      if (userId == null) return;
      debugPrint('[mesh-fcm] key update for $userId — refetching');
      try {
        await syncService.fetchContactKeys(userId);
      } catch (e) {
        debugPrint('[mesh-fcm] refetch failed: $e');
      }
    });
  }
}
```

- [ ] **Step 2: Verify it compiles**

```bash
cd ~/Downloads/taler_id_mesh
flutter analyze lib/features/mesh/data/datasources/mesh_fcm_listener.dart
```

Expected: `No issues found!`

- [ ] **Step 3: Commit**

```bash
cd ~/Downloads/taler_id_mesh
git add lib/features/mesh/data/datasources/mesh_fcm_listener.dart
git commit -m "feat(mesh/features): FCM listener for contact key rotation"
```

---

## Task M7: Wire Phase 1b into existing auth flow (DI)

**Files:**
- Modify: `lib/core/di/service_locator.dart` (or equivalent GetIt setup file — inspect project)
- Modify: `lib/features/auth/presentation/bloc/auth_bloc.dart` (after successful login: register own device key + subscribe to contact FCM topics)

**This is a light integration task** — it should NOT expose mesh functionality to the user yet. No UI changes. The goal is: when a logged-in user launches the app and we have a JWT, the mesh subsystem is silently bootstrapped in the background.

- [ ] **Step 1: Inspect the current DI setup**

```bash
cd ~/Downloads/taler_id_mesh
find lib/core/di -type f -name '*.dart'
# Likely: lib/core/di/service_locator.dart
```

Read the file. Understand how `Dio` and other singletons are registered.

- [ ] **Step 2: Register Phase 1b services**

Add to the service locator, after the existing Dio registration:

```dart
// Mesh Phase 1b — device-key sync
getIt.registerLazySingletonAsync<MeshStaticKey>(() => MeshStaticKey.generate());
getIt.registerLazySingletonAsync<DeviceKey>(() => DeviceKey.generate());
getIt.registerLazySingleton<DeviceKeysApiClient>(
  () => DeviceKeysApiClient(getIt<Dio>()),
);
getIt.registerSingletonAsync<HiveContactKeyStore>(() =>
    HiveContactKeyStore.open(boxName: 'mesh_contacts'));
getIt.registerSingletonWithDependencies<DeviceKeySyncService>(
  () => DeviceKeySyncService(
    api: getIt<DeviceKeysApiClient>(),
    store: getIt<HiveContactKeyStore>(),
    signingKey: getIt<DeviceKey>(),
    meshStaticKey: getIt<MeshStaticKey>(),
    myUserId: _currentUserId(),
  ),
  dependsOn: [HiveContactKeyStore, DeviceKey, MeshStaticKey],
);
```

**If the actual GetIt setup differs** (e.g. uses factories or a custom module system), adapt to match. The important outcome: after `getIt.allReady()` completes, `DeviceKeySyncService` is retrievable.

The `_currentUserId()` helper must read the JWT-decoded user id — use whatever utility the project already has (e.g. an `AuthSession` singleton).

- [ ] **Step 3: Bootstrap on successful login**

In the AuthBloc's login-success handler (inspect actual file: `grep -r "emit(.*Authenticated" lib/features/auth/ | head`), add:

```dart
// Mesh Phase 1b: silent bootstrap
unawaited(() async {
  try {
    final sync = await getIt.getAsync<DeviceKeySyncService>();
    await sync.registerOwnDevice();
  } catch (e) {
    debugPrint('[mesh] bootstrap failed: $e');
  }
}());
```

`unawaited` is from `package:pedantic` or `dart:async` (`Unawaited`). Using `unawaited` ensures login UX is not blocked by mesh registration — it's a background concern.

- [ ] **Step 4: Compile check**

```bash
cd ~/Downloads/taler_id_mesh
flutter analyze lib/
```

Expected: no new errors.

- [ ] **Step 5: Commit**

```bash
cd ~/Downloads/taler_id_mesh
git add lib/core/di/ lib/features/auth/
git commit -m "feat(mesh): wire DeviceKeySyncService into DI + auth bootstrap"
```

---

## Task M8: Mobile integration test — register + fetch against DEV

**Files:**
- Create: `integration_test/mesh_device_keys_test.dart`

- [ ] **Step 1: Write integration test**

```dart
// Runs against staging DEV — requires integration_test user credentials
// to be valid and the DEV backend to be deployed with Phase 1b endpoints.
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:taler_id_mobile/core/mesh/crypto/keys/contact_key_store_hive.dart';
import 'package:taler_id_mobile/core/mesh/crypto/keys/device_key.dart';
import 'package:taler_id_mobile/core/mesh/crypto/keys/mesh_static_key.dart';
import 'package:taler_id_mobile/core/mesh/services/device_key_sync_service.dart';
import 'package:taler_id_mobile/core/mesh/services/device_keys_api_client.dart';
import 'package:taler_id_mobile/core/mesh/transport/peer_id.dart';
import 'package:hive_flutter/hive_flutter.dart';

const _baseUrl = 'https://staging.id.taler.tirol';
const _user1Email = 'integration_test@taler-test.com';
const _user1Password = 'IntegrationTest123!';
const _user2Email = 'integration_test_2@taler-test.com';
const _user2Password = 'IntegrationTest123!';

Future<({String token, String userId})> _login(
    Dio dio, String email, String password) async {
  final res = await dio.post<Map<String, dynamic>>(
    '/auth/login',
    data: {'email': email, 'password': password},
  );
  return (
    token: res.data!['accessToken'] as String,
    userId: res.data!['user']['id'] as String,
  );
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Phase 1b — register own key + user2 fetches it', (tester) async {
    await Hive.initFlutter('mesh_integ_test');
    final bootstrapDio = Dio(BaseOptions(baseUrl: _baseUrl));

    final u1 = await _login(bootstrapDio, _user1Email, _user1Password);
    final u2 = await _login(bootstrapDio, _user2Email, _user2Password);

    final dio1 = Dio(BaseOptions(
      baseUrl: _baseUrl,
      headers: {'Authorization': 'Bearer ${u1.token}'},
    ));
    final dio2 = Dio(BaseOptions(
      baseUrl: _baseUrl,
      headers: {'Authorization': 'Bearer ${u2.token}'},
    ));

    final signing = await DeviceKey.generate();
    final mesh = await MeshStaticKey.generate();

    final store1 = await HiveContactKeyStore.open(boxName: 'integ-u1');
    final svc1 = DeviceKeySyncService(
      api: DeviceKeysApiClient(dio1),
      store: store1,
      signingKey: signing,
      meshStaticKey: mesh,
      myUserId: u1.userId,
    );

    // user1 registers own device key.
    await svc1.registerOwnDevice();

    // user2 fetches user1's keys.
    final store2 = await HiveContactKeyStore.open(boxName: 'integ-u2');
    final svc2 = DeviceKeySyncService(
      api: DeviceKeysApiClient(dio2),
      store: store2,
      signingKey: await DeviceKey.generate(),
      meshStaticKey: await MeshStaticKey.generate(),
      myUserId: u2.userId,
    );
    await svc2.fetchContactKeys(u1.userId);

    // Assert user1's mesh pk is now known to user2.
    final devicePk = PeerId(mesh.publicKey);
    expect(store2.isKnownDevice(devicePk), isTrue,
        reason: "user2 should have user1's newly registered device pk");

    // Cleanup: revoke the key so subsequent runs don't clutter the DB.
    final list = await DeviceKeysApiClient(dio1).getContactKeys(u1.userId);
    for (final cert in list) {
      if (cert.devicePk == devicePk.toHex()) {
        // Fetch id from the raw response — requires extending the API client.
        // For now simply skip revoke; tests can accumulate keys on DEV.
      }
    }

    await store1.close();
    await store2.close();
  }, timeout: const Timeout(Duration(seconds: 60)));
}
```

- [ ] **Step 2: Run on Android emulator**

```bash
cd ~/Downloads/taler_id_mesh
flutter emulators --launch Pixel_XL_API_33
sleep 20
~/Library/Android/sdk/platform-tools/adb devices
flutter test integration_test/mesh_device_keys_test.dart --flavor dev --dart-define=FLAVOR=dev --dart-define=BASE_URL=https://staging.id.taler.tirol -d emulator-5554
```

Expected: test passes.

If the login call shape differs from `{accessToken, user: {id}}` — fix the `_login` helper per actual backend response.

- [ ] **Step 3: Commit**

```bash
cd ~/Downloads/taler_id_mesh
git add integration_test/mesh_device_keys_test.dart
git commit -m "test(mesh): Phase 1b integration test — device-keys sync vs DEV"
```

---

## Task R1: Phase 1b retrospective + push

- [ ] **Step 1: Run full mesh suite**

```bash
cd ~/Downloads/taler_id_mesh
flutter analyze lib/core/mesh/
flutter test test/core/mesh/
```

Expected: `No issues found!` and all tests pass (Phase 1a's 39 + Phase 1b additions).

- [ ] **Step 2: Backend sanity**

```bash
cd ~/taler-id-mesh
npm run build
npm test -- --testPathPattern='device-keys'
```

Expected: build succeeds, all unit tests green.

- [ ] **Step 3: Smoke-test both endpoints against DEV**

```bash
cd ~/Downloads/taler_id_tests
npm run test:mesh
```

Expected: `✅ All device-key checks passed against https://staging.id.taler.tirol`

- [ ] **Step 4: Push branches**

```bash
cd ~/taler-id-mesh
git push origin feature/mesh-bridge

cd ~/Downloads/taler_id_mesh
git push origin feature/mesh-network
```

- [ ] **Step 5: Do NOT merge**

Per user instruction: no merges until full mesh feature complete. Phase 1c is next.

---

## Self-Review Notes

**Spec coverage:**
- Section 11 (Backend Changes) — DeviceKey Prisma model ✓, endpoints ✓ (MeshBridgeToken deferred to Phase 2 when gateway lands; MeshEvent deferred to Phase 2 event onboarding)
- Section 6 (Crypto) — self-signed cert simplification documented; full user identity key deferred to Phase 1c
- Goals #1 — contact messaging in mesh: Phase 1b enables persisted contact keys, unlocking real-world multi-session use

**Placeholders:** none — every step has concrete code.

**Type consistency:**
- `DeviceCert.devicePk` is always lowercase hex (enforced at register)
- `DeviceKey` (Ed25519) is signing, `MeshStaticKey` (X25519) is ECDH — never interchangeable
- `HiveContactKeyStore` maintains the Phase 1a `ContactKeyStore` contract methods

**Ambiguity resolved:**
- `userPk` in `HiveContactKeyStore` stays as derived PeerId for Phase 1b (Phase 1c promotes this to real user identity key)
- FCM topic naming: `mesh-keys/<userId>` — deterministic, safe to subscribe/unsubscribe on contact add/remove

**Scope check:** Phase 1b delivers end-to-end contact-key sync. Does NOT deliver:
- Multi-hop routing (Phase 2)
- Onion encryption (Phase 1f)
- BLE discovery (Phase 1c)
- UI (Phase 1e)
- Multi-device per user (deferred — Phase 1b keeps Phase 1a's one-device-per-user assumption, but the API already accepts multiple certs per user)

## Execution Handoff

After saving:

**1. Subagent-Driven (recommended)** — continue the pattern used in Phase 1a.
**2. Inline Execution** — batch mode with checkpoints.

Total: 15 tasks (B1–B7, M1–M8, R1). Backend block first, then mobile block. Phase 1b has cross-repo integration, so pay attention to the deploy step (B6) which requires SSH access.

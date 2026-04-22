# Mesh Phase 1c — User Identity Keys & Key Persistence Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make mesh device identity persistent across app restarts by adding a permanent per-device `UserIdentityKey`, persisting rotating `DeviceKey` + `MeshStaticKey` in Hive with 30-day startup-triggered rotation, extending `DeviceCert` with `userPk`, and propagating `userPk` through the backend.

**Architecture:** One permanent Ed25519 `UserIdentityKey` per device stored in `FlutterSecureStorage` signs self-issued device certs that commit to an X25519 `MeshStaticKey`. Two short-lived keys (`DeviceKey` Ed25519 for future BLE use, `MeshStaticKey` X25519 for Noise IK ECDH) live in a Hive box alongside their creation timestamps; on each app launch they are regenerated if older than 30 days and a fresh cert is pushed to the backend. Backend stores the new `userPk` column and returns it; mobile receivers verify cert self-consistency on fetch.

**Tech Stack:**
- Mobile: Dart 3.6, `cryptography` (Ed25519 + X25519), `flutter_secure_storage`, `hive`/`hive_flutter`, `dio`.
- Backend: NestJS + Prisma + PostgreSQL (existing).
- Tests: `flutter_test` (unit + integration), Jest (backend unit + e2e), `ts-node` smoke tests in `~/Downloads/taler_id_tests`.

---

## Spec & Dependencies

- Spec: `docs/superpowers/specs/2026-04-22-mesh-phase1c-user-identity-keys-design.md`
- Prior phases:
  - Phase 1a plan: `docs/superpowers/plans/2026-04-21-mesh-phase1a-text-exchange.md`
  - Phase 1b plan: `docs/superpowers/plans/2026-04-21-mesh-phase1b-device-key-sync.md`
- Working dirs:
  - **Mobile:** `~/Downloads/taler_id_mesh/` on branch `feature/mesh-network` (off `dev`)
  - **Backend:** `~/taler-id-mesh/` on branch `feature/mesh-bridge` (off `main`)
  - **E2E tests:** `~/Downloads/taler_id_tests/` (scratch scripts, no branch)

---

## File Structure

### Mobile — new files

```
lib/core/mesh/crypto/keys/
├── user_identity_key.dart           # Ed25519 permanent, Secure-Storage-backed
└── mesh_key_persistence.dart        # Hive load/rotate for DeviceKey + MeshStaticKey

test/core/mesh/crypto/keys/
├── user_identity_key_test.dart
└── mesh_key_persistence_test.dart
```

### Mobile — modified files

```
lib/core/mesh/crypto/keys/device_cert.dart             # +userPk field, canonical JSON order
lib/core/mesh/crypto/keys/cert_signer.dart             # accept UserIdentityKey, include userPk
lib/core/mesh/services/device_key_sync_service.dart    # use UserIdentityKey, real userPk, verify
lib/core/mesh/services/device_keys_api_client.dart     # include userPk in registerDeviceKey body
lib/core/di/service_locator.dart                       # load/rotate keys, register fresh cert
test/core/mesh/crypto/keys/device_cert_test.dart       # +userPk cases
test/core/mesh/crypto/keys/cert_signer_test.dart       # sign with UserIdentityKey, verify userPk
test/core/mesh/services/device_key_sync_service_test.dart  # real userPk, verify-reject behavior
```

### Backend — modified files (`~/taler-id-mesh/`)

```
prisma/schema.prisma                               # +userPk nullable column on DeviceKey
prisma/migrations/YYYYMMDDHHMMSS_add_user_pk_to_device_keys/
src/device-keys/device-keys.service.ts             # extract userPk from cert JSON, store, return
src/device-keys/device-keys.service.spec.ts        # +userPk cases
src/device-keys/dto/device-key-response.dto.ts     # +userPk field
test/device-keys.e2e-spec.ts                       # +userPk in sample DTOs + assertions
```

### E2E tests (`~/Downloads/taler_id_tests/`)

```
device_keys_test.ts                                # +userPk in cert payload + response check
```

---

## Execution Order

**Backend first** (B1–B4) so mobile can target a live DEV server with the new field. Then **mobile** (M1–M8). Final **R1** retrospective.

Work from:
- Backend: `cd ~/taler-id-mesh` (branch `feature/mesh-bridge`)
- Mobile: `cd ~/Downloads/taler_id_mesh` (branch `feature/mesh-network`)

---

# PART 1 — BACKEND

## Task B1: Prisma `userPk` column

**Files:**
- Modify: `prisma/schema.prisma`

- [ ] **Step 1: Add `userPk` to DeviceKey model**

Open `prisma/schema.prisma` and find the `DeviceKey` model. Add a nullable `userPk` field and an index:

```prisma
model DeviceKey {
  id                 String    @id @default(uuid())
  userId             String
  devicePk           String    @unique
  userPk             String?                       // NEW — hex 64 chars, Ed25519 UserIdentityKey
  algorithm          String    @default("X25519")
  validUntil         DateTime
  certificate        String    @db.Text
  signature          String
  revokedAt          DateTime?
  createdAt          DateTime  @default(now())
  updatedAt          DateTime  @updatedAt

  user               User      @relation(fields: [userId], references: [id], onDelete: Cascade)

  @@index([userId])
  @@index([userId, revokedAt])
  @@index([userPk])                                // NEW
}
```

- [ ] **Step 2: Generate migration**

```bash
cd ~/taler-id-mesh
npx prisma migrate dev --name add_user_pk_to_device_keys --create-only
```

Expected: new migration file under `prisma/migrations/YYYYMMDDHHMMSS_add_user_pk_to_device_keys/migration.sql`. Inspect contents — should be `ALTER TABLE "DeviceKey" ADD COLUMN "userPk" TEXT;` plus index creation. No data loss.

- [ ] **Step 3: Apply locally and regenerate client**

```bash
cd ~/taler-id-mesh
npx prisma migrate dev
npx prisma generate
npm run build 2>&1 | tail -5
```

Expected: migration applied to local DB, Prisma client regenerated, `nest build` succeeds.

- [ ] **Step 4: Commit**

```bash
cd ~/taler-id-mesh
git add prisma/schema.prisma prisma/migrations/
git commit -m "feat(mesh): add userPk column to DeviceKey for Phase 1c"
```

---

## Task B2: DeviceKeyResponseDto + service — store and return userPk

**Files:**
- Modify: `src/device-keys/dto/device-key-response.dto.ts`
- Modify: `src/device-keys/device-keys.service.ts`
- Modify: `src/device-keys/device-keys.service.spec.ts`

- [ ] **Step 1: Write failing test cases — userPk persistence & response**

Open `src/device-keys/device-keys.service.spec.ts`. Inside the `describe('register', ...)` block, add these cases **after** the existing `'creates device key record and returns response DTO'` test:

```typescript
    it('extracts userPk from certificate JSON and persists it', async () => {
      const validUntil = Date.now() + 30 * 86_400_000;
      const userPk = 'c'.repeat(64);
      const certJson = JSON.stringify({
        algorithm: 'X25519',
        devicePk: 'a'.repeat(64),
        userId: 'user-1',
        userPk,
        validUntilEpochMs: validUntil,
      });
      prisma.deviceKey.create.mockResolvedValue({
        id: 'dk-2',
        userId: 'user-1',
        devicePk: 'a'.repeat(64),
        userPk,
        algorithm: 'X25519',
        validUntil: new Date(validUntil),
        certificate: certJson,
        signature: 'f'.repeat(128),
        revokedAt: null,
        createdAt: new Date(),
        updatedAt: new Date(),
      } as any);

      const result = await service.register('user-1', {
        devicePk: 'a'.repeat(64),
        algorithm: 'X25519',
        validUntilEpochMs: validUntil,
        signature: 'f'.repeat(128),
        certificate: certJson,
      });

      expect(prisma.deviceKey.create).toHaveBeenCalledWith({
        data: expect.objectContaining({
          userId: 'user-1',
          devicePk: 'a'.repeat(64),
          userPk,
          algorithm: 'X25519',
        }),
      });
      expect(result.userPk).toBe(userPk);
    });

    it('tolerates cert without userPk (Phase 1b compat)', async () => {
      const validUntil = Date.now() + 30 * 86_400_000;
      const certJson = JSON.stringify({
        algorithm: 'X25519',
        devicePk: 'a'.repeat(64),
        userId: 'user-1',
        validUntilEpochMs: validUntil,
      });
      prisma.deviceKey.create.mockResolvedValue({
        id: 'dk-3',
        userId: 'user-1',
        devicePk: 'a'.repeat(64),
        userPk: null,
        algorithm: 'X25519',
        validUntil: new Date(validUntil),
        certificate: certJson,
        signature: 'f'.repeat(128),
        revokedAt: null,
        createdAt: new Date(),
        updatedAt: new Date(),
      } as any);

      const result = await service.register('user-1', {
        devicePk: 'a'.repeat(64),
        algorithm: 'X25519',
        validUntilEpochMs: validUntil,
        signature: 'f'.repeat(128),
        certificate: certJson,
      });

      expect(prisma.deviceKey.create).toHaveBeenCalledWith({
        data: expect.objectContaining({
          userPk: null,
        }),
      });
      expect(result.userPk).toBeNull();
    });

    it('tolerates malformed cert JSON (stores userPk=null)', async () => {
      const validUntil = Date.now() + 30 * 86_400_000;
      prisma.deviceKey.create.mockResolvedValue({
        id: 'dk-4',
        userId: 'user-1',
        devicePk: 'a'.repeat(64),
        userPk: null,
        algorithm: 'X25519',
        validUntil: new Date(validUntil),
        certificate: 'not-json',
        signature: 'f'.repeat(128),
        revokedAt: null,
        createdAt: new Date(),
        updatedAt: new Date(),
      } as any);

      await service.register('user-1', {
        devicePk: 'a'.repeat(64),
        algorithm: 'X25519',
        validUntilEpochMs: validUntil,
        signature: 'f'.repeat(128),
        certificate: 'not-json',
      });

      expect(prisma.deviceKey.create).toHaveBeenCalledWith({
        data: expect.objectContaining({ userPk: null }),
      });
    });
```

- [ ] **Step 2: Run tests — verify they fail**

```bash
cd ~/taler-id-mesh
npm test -- --testPathPatterns='device-keys.service.spec'
```

Expected: the three new tests FAIL (assertions on `userPk` fail because current code never touches that field).

- [ ] **Step 3: Add `userPk` to `DeviceKeyResponseDto`**

Open `src/device-keys/dto/device-key-response.dto.ts` and add the field:

```typescript
export class DeviceKeyResponseDto {
  id: string;
  userId: string;
  devicePk: string;
  userPk: string | null;           // NEW — Phase 1c
  algorithm: string;
  validUntil: string;
  certificate: string;
  signature: string;
  revokedAt: string | null;
  createdAt: string;
}
```

- [ ] **Step 4: Extract `userPk` from cert in service**

Open `src/device-keys/device-keys.service.ts`. Replace the `register` method with this version:

```typescript
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

    const userPk = this.extractUserPk(dto.certificate);

    const record = await this.prisma.deviceKey.create({
      data: {
        userId,
        devicePk: dto.devicePk.toLowerCase(),
        userPk,
        algorithm: SUPPORTED_ALG,
        validUntil: new Date(dto.validUntilEpochMs),
        certificate: dto.certificate,
        signature: dto.signature.toLowerCase(),
      },
    });

    // Fan-out push to this user's contacts (fire-and-forget).
    this.fcm.sendKeyUpdate(userId).catch(() => {
      /* FCM failures should not break registration */
    });

    return this.toResponseDto(record);
  }

  /**
   * Extract the `userPk` field from a cert JSON string.
   *
   * Returns lowercase hex if present and string-typed, otherwise `null`.
   * Malformed JSON returns `null` (Phase 1b backward compat — the legacy
   * cert has no userPk and the backend stored it as-is without parsing).
   */
  private extractUserPk(certificateJson: string): string | null {
    try {
      const parsed = JSON.parse(certificateJson);
      const v = parsed?.userPk;
      if (typeof v !== 'string') return null;
      return v.toLowerCase();
    } catch {
      return null;
    }
  }
```

Then update `toResponseDto` to include `userPk`:

```typescript
  private toResponseDto(row: any): DeviceKeyResponseDto {
    return {
      id: row.id,
      userId: row.userId,
      devicePk: row.devicePk,
      userPk: row.userPk ?? null,
      algorithm: row.algorithm,
      validUntil: (row.validUntil as Date).toISOString(),
      certificate: row.certificate,
      signature: row.signature,
      revokedAt: row.revokedAt ? (row.revokedAt as Date).toISOString() : null,
      createdAt: (row.createdAt as Date).toISOString(),
    };
  }
```

- [ ] **Step 5: Run tests — verify all pass**

```bash
cd ~/taler-id-mesh
npm test -- --testPathPatterns='device-keys.service.spec'
```

Expected: all tests green (original 7 + 3 new = 10).

- [ ] **Step 6: Commit**

```bash
cd ~/taler-id-mesh
git add src/device-keys/dto/device-key-response.dto.ts src/device-keys/device-keys.service.ts src/device-keys/device-keys.service.spec.ts
git commit -m "feat(mesh): store and return userPk on DeviceKey (Phase 1c backend)"
```

---

## Task B3: Update backend e2e spec with userPk

**Files:**
- Modify: `test/device-keys.e2e-spec.ts`

- [ ] **Step 1: Add `userPk` to the sample DTO factory**

Open `test/device-keys.e2e-spec.ts`. Replace the `sampleDto` helper (lines 54-65 currently) with:

```typescript
  const sampleDto = (devicePk: string) => {
    const validUntil = Date.now() + 30 * 86_400_000;
    const userPk = 'c'.repeat(64);
    return {
      devicePk,
      algorithm: 'X25519',
      validUntilEpochMs: validUntil,
      signature: 'f'.repeat(128),
      certificate: JSON.stringify({
        algorithm: 'X25519',
        devicePk,
        userId: 'placeholder',
        userPk,
        validUntilEpochMs: validUntil,
      }),
    };
  };
```

- [ ] **Step 2: Add assertion that response includes `userPk`**

In the `it('POST /profile/device-keys — registers a key (201)', ...)` block, after the existing expect assertions, add:

```typescript
    expect(res.body.userPk).toBe('c'.repeat(64));
```

- [ ] **Step 3: Run e2e (skip if local Linux path missing)**

```bash
cd ~/taler-id-mesh
npm run test:e2e -- --testPathPatterns='device-keys.e2e-spec' 2>&1 | tail -20
```

Expected: either all pass (if running on Linux with the `/home/dvolkov/taler-id/uploads/avatars` path) or the suite fails to load with the known multer path issue (same as Phase 1b — the e2e spec is authored for the DEV server). In both cases, the code is committed and will be exercised during B4 deploy smoke.

- [ ] **Step 4: Commit**

```bash
cd ~/taler-id-mesh
git add test/device-keys.e2e-spec.ts
git commit -m "test(mesh): e2e covers userPk roundtrip on device-keys"
```

---

## Task B4: Deploy backend to DEV + smoke test

Per CLAUDE.md: **DEV first, PROD only on explicit instruction**.

- [ ] **Step 1: Push branch**

```bash
cd ~/taler-id-mesh
git push origin feature/mesh-bridge
```

- [ ] **Step 2: Deploy on DEV**

```bash
ssh dvolkov@89.169.55.217 'cd ~/taler-id && git fetch origin && git checkout feature/mesh-bridge && git pull && npm install --silent && npx prisma db push --accept-data-loss && npm run build 2>&1 | tail -5 && pm2 restart taler-id-dev && echo DEPLOY_OK'
```

Expected: `DEPLOY_OK` at the end. `prisma db push` adds the nullable `userPk` column + index with no data loss. We use `db push` (not `migrate deploy`) because the DEV DB was baselined with `db push` in Phase 1b — per the CLAUDE.md precedent.

- [ ] **Step 3: Smoke-test `userPk` round-trip**

```bash
TOKEN=$(curl -s -X POST https://staging.id.taler.tirol/auth/login \
  -H 'Content-Type: application/json' \
  -d '{"email":"integration_test@taler-test.com","password":"IntegrationTest123!"}' \
  | python3 -c "import sys,json; print(json.load(sys.stdin)['accessToken'])")

DEVICE_PK=$(python3 -c "import secrets; print(secrets.token_hex(32))")
USER_PK=$(python3 -c "import secrets; print(secrets.token_hex(32))")
VALID_UNTIL=$(python3 -c "import time; print(int(time.time()*1000) + 30*86400*1000)")
CERT=$(python3 -c "import json,sys; print(json.dumps({'algorithm':'X25519','devicePk':'$DEVICE_PK','userId':'placeholder','userPk':'$USER_PK','validUntilEpochMs':$VALID_UNTIL}))")

RESPONSE=$(curl -s -X POST https://staging.id.taler.tirol/profile/device-keys \
  -H "Authorization: Bearer $TOKEN" \
  -H 'Content-Type: application/json' \
  -d "{\"devicePk\":\"$DEVICE_PK\",\"algorithm\":\"X25519\",\"validUntilEpochMs\":$VALID_UNTIL,\"signature\":\"$(python3 -c 'print("f"*128)')\",\"certificate\":$(echo $CERT | python3 -c 'import json,sys; print(json.dumps(sys.stdin.read().strip()))')}")

echo "$RESPONSE" | python3 -m json.tool
```

Expected: JSON response with `"userPk": "<USER_PK value>"` (the exact hex you generated). Capture the `id` field for cleanup.

- [ ] **Step 4: Clean up test key**

```bash
KEY_ID=$(echo "$RESPONSE" | python3 -c "import sys,json; print(json.load(sys.stdin)['id'])")
curl -s -X POST "https://staging.id.taler.tirol/profile/device-keys/$KEY_ID/revoke" \
  -H "Authorization: Bearer $TOKEN" \
  -H 'Content-Type: application/json' -d '{}' > /dev/null
echo "Revoked $KEY_ID"
```

- [ ] **Step 5: No commit needed — deploy tracked by push + PM2**

---

# PART 2 — MOBILE

## Task M1: UserIdentityKey — permanent Ed25519 in SecureStorage

**Files:**
- Create: `lib/core/mesh/crypto/keys/user_identity_key.dart`
- Create: `test/core/mesh/crypto/keys/user_identity_key_test.dart`

- [ ] **Step 1: Write failing test**

Create `test/core/mesh/crypto/keys/user_identity_key_test.dart`:

```dart
import 'dart:typed_data';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:taler_id_mobile/core/mesh/crypto/keys/user_identity_key.dart';

/// Minimal in-memory fake that mirrors the subset of FlutterSecureStorage
/// UserIdentityKey relies on. Avoids MissingPluginException in unit tests.
class _MemStorage implements FlutterSecureStorage {
  final Map<String, String> _data = {};

  @override
  Future<String?> read({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async =>
      _data[key];

  @override
  Future<void> write({
    required String key,
    required String? value,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (value == null) {
      _data.remove(key);
    } else {
      _data[key] = value;
    }
  }

  // Unused methods — delegate to noSuchMethod to avoid implementing the whole surface.
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

void main() {
  group('UserIdentityKey', () {
    test('generate produces 32-byte public + private bytes', () async {
      final key = await UserIdentityKey.generate();
      expect(key.publicKey.length, 32);
      expect(key.privateKeyBytes.length, 32);
    });

    test('loadOrCreate creates on first call, returns same key on second', () async {
      final storage = _MemStorage();

      final first = await UserIdentityKey.loadOrCreate(storage);
      final second = await UserIdentityKey.loadOrCreate(storage);

      expect(first.publicKey, equals(second.publicKey));
      expect(first.privateKeyBytes, equals(second.privateKeyBytes));
    });

    test('sign + verify round-trip succeeds', () async {
      final key = await UserIdentityKey.generate();
      final msg = Uint8List.fromList([1, 2, 3, 4, 5]);
      final sig = await key.sign(msg);

      final ok = await UserIdentityKey.verify(
        publicKey: key.publicKey,
        message: msg,
        signature: sig,
      );
      expect(ok, isTrue);
    });

    test('verify rejects signature from different key', () async {
      final a = await UserIdentityKey.generate();
      final b = await UserIdentityKey.generate();
      final msg = Uint8List.fromList([7, 7, 7]);
      final sig = await a.sign(msg);

      final ok = await UserIdentityKey.verify(
        publicKey: b.publicKey,
        message: msg,
        signature: sig,
      );
      expect(ok, isFalse);
    });
  });
}
```

- [ ] **Step 2: Run — expect FAIL**

```bash
cd ~/Downloads/taler_id_mesh
flutter test test/core/mesh/crypto/keys/user_identity_key_test.dart 2>&1 | tail -5
```

Expected: "Cannot find module 'user_identity_key.dart'" or similar import error.

- [ ] **Step 3: Implement `UserIdentityKey`**

Create `lib/core/mesh/crypto/keys/user_identity_key.dart`:

```dart
import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Permanent per-device Ed25519 identity keypair for the mesh PKI.
///
/// Stored in [FlutterSecureStorage] under [storageKey] as base64-encoded
/// 32-byte private seed. Public key is derived on load. Generated once on
/// first app launch and never rotated — this is the stable `userPk` that
/// contacts use to verify this device's self-issued DeviceCerts.
class UserIdentityKey {
  /// Secure-storage key used by [loadOrCreate]. Exposed for debug/test.
  static const String storageKey = 'mesh_user_identity_priv';

  static final _ed25519 = Ed25519();

  final SimpleKeyPairData _keyPair;
  final Uint8List publicKey;
  final Uint8List privateKeyBytes;

  UserIdentityKey._({
    required SimpleKeyPairData keyPair,
    required this.publicKey,
    required this.privateKeyBytes,
  }) : _keyPair = keyPair;

  static Future<UserIdentityKey> generate() async {
    final kp = await _ed25519.newKeyPair();
    final kpData = await kp.extract();
    final pub = await kp.extractPublicKey();
    return UserIdentityKey._(
      keyPair: kpData,
      publicKey: Uint8List.fromList(pub.bytes),
      privateKeyBytes: Uint8List.fromList(kpData.bytes),
    );
  }

  static Future<UserIdentityKey> _fromPrivateKeyBytes(Uint8List privBytes) async {
    final kp = await _ed25519.newKeyPairFromSeed(privBytes);
    final kpData = await kp.extract();
    final pub = await kp.extractPublicKey();
    return UserIdentityKey._(
      keyPair: kpData,
      publicKey: Uint8List.fromList(pub.bytes),
      privateKeyBytes: Uint8List.fromList(kpData.bytes),
    );
  }

  /// Read the identity key from [storage] under [storageKey]. If absent,
  /// generate a new keypair, persist it, and return it. This call is
  /// idempotent across app launches.
  static Future<UserIdentityKey> loadOrCreate(
    FlutterSecureStorage storage,
  ) async {
    final encoded = await storage.read(key: storageKey);
    if (encoded != null && encoded.isNotEmpty) {
      final bytes = Uint8List.fromList(base64Decode(encoded));
      if (bytes.length == 32) {
        return _fromPrivateKeyBytes(bytes);
      }
      // Length mismatch — treat as corrupted, regenerate.
    }
    final fresh = await generate();
    await storage.write(
      key: storageKey,
      value: base64Encode(fresh.privateKeyBytes),
    );
    return fresh;
  }

  Future<Uint8List> sign(Uint8List message) async {
    final sig = await _ed25519.sign(message, keyPair: _keyPair);
    return Uint8List.fromList(sig.bytes);
  }

  static Future<bool> verify({
    required Uint8List publicKey,
    required Uint8List message,
    required Uint8List signature,
  }) async {
    final pub = SimplePublicKey(publicKey, type: KeyPairType.ed25519);
    return _ed25519.verify(
      message,
      signature: Signature(signature, publicKey: pub),
    );
  }
}
```

- [ ] **Step 4: Run — expect 4/4 pass**

```bash
cd ~/Downloads/taler_id_mesh
flutter test test/core/mesh/crypto/keys/user_identity_key_test.dart 2>&1 | tail -5
```

Expected: `+4: All tests passed!`

- [ ] **Step 5: Commit**

```bash
cd ~/Downloads/taler_id_mesh
git add lib/core/mesh/crypto/keys/user_identity_key.dart test/core/mesh/crypto/keys/user_identity_key_test.dart
git commit -m "feat(mesh/crypto): add UserIdentityKey (Ed25519 permanent, SecureStorage)"
```

---

## Task M2: MeshKeyPersistence — Hive-backed DeviceKey + MeshStaticKey with rotation

**Files:**
- Create: `lib/core/mesh/crypto/keys/mesh_key_persistence.dart`
- Create: `test/core/mesh/crypto/keys/mesh_key_persistence_test.dart`

- [ ] **Step 1: Write failing test**

Create `test/core/mesh/crypto/keys/mesh_key_persistence_test.dart`:

```dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:taler_id_mobile/core/mesh/crypto/keys/mesh_key_persistence.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('mesh_keys_test_');
    Hive.init(tempDir.path);
  });

  tearDown(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('MeshKeyPersistence', () {
    test('loadOrRotateDeviceKey generates on empty box and reports didRotate=true',
        () async {
      final p = await MeshKeyPersistence.open(boxName: 'mkp-1');
      final (key, didRotate) = await p.loadOrRotateDeviceKey();
      expect(didRotate, isTrue);
      expect(key.publicKey.length, 32);
      await p.close();
    });

    test('second call returns same DeviceKey and didRotate=false', () async {
      final p1 = await MeshKeyPersistence.open(boxName: 'mkp-2');
      final (k1, r1) = await p1.loadOrRotateDeviceKey();
      expect(r1, isTrue);
      await p1.close();

      final p2 = await MeshKeyPersistence.open(boxName: 'mkp-2');
      final (k2, r2) = await p2.loadOrRotateDeviceKey();
      expect(r2, isFalse);
      expect(k2.publicKey, equals(k1.publicKey));
      await p2.close();
    });

    test('DeviceKey rotates when stored createdAt is older than 30 days',
        () async {
      final p = await MeshKeyPersistence.open(boxName: 'mkp-3');
      final (k1, _) = await p.loadOrRotateDeviceKey(
        now: DateTime(2026, 1, 1),
      );

      // 31 days later → rotation required
      final (k2, didRotate) = await p.loadOrRotateDeviceKey(
        now: DateTime(2026, 2, 1),
      );
      expect(didRotate, isTrue);
      expect(k2.publicKey, isNot(equals(k1.publicKey)));
      await p.close();
    });

    test('loadOrRotateMeshStaticKey mirrors DeviceKey behavior', () async {
      final p = await MeshKeyPersistence.open(boxName: 'mkp-4');
      final (k1, r1) = await p.loadOrRotateMeshStaticKey();
      expect(r1, isTrue);
      expect(k1.publicKey.length, 32);

      final (k2, r2) = await p.loadOrRotateMeshStaticKey();
      expect(r2, isFalse);
      expect(k2.publicKey, equals(k1.publicKey));

      final (k3, r3) = await p.loadOrRotateMeshStaticKey(
        now: DateTime.now().add(const Duration(days: 31)),
      );
      expect(r3, isTrue);
      expect(k3.publicKey, isNot(equals(k1.publicKey)));
      await p.close();
    });
  });
}
```

- [ ] **Step 2: Run — expect FAIL**

```bash
cd ~/Downloads/taler_id_mesh
flutter test test/core/mesh/crypto/keys/mesh_key_persistence_test.dart 2>&1 | tail -5
```

Expected: import error for the missing module.

- [ ] **Step 3: Implement `MeshKeyPersistence`**

Create `lib/core/mesh/crypto/keys/mesh_key_persistence.dart`:

```dart
import 'dart:convert';
import 'dart:typed_data';

import 'package:hive/hive.dart';

import 'device_key.dart';
import 'mesh_static_key.dart';

/// Hive-backed storage for the two rotating mesh keys.
///
/// Keys rotate every [rotationAge] days. Rotation is triggered lazily on the
/// next [loadOrRotateDeviceKey] / [loadOrRotateMeshStaticKey] call that finds
/// a stored `createdAt` older than [rotationAge] — no background timer.
class MeshKeyPersistence {
  static const Duration rotationAge = Duration(days: 30);

  static const _deviceKeyPrivField = 'device_key_priv';
  static const _deviceKeyCreatedField = 'device_key_created_at';
  static const _meshStaticPrivField = 'mesh_static_priv';
  static const _meshStaticCreatedField = 'mesh_static_created_at';

  final Box<String> _box;

  MeshKeyPersistence._(this._box);

  static Future<MeshKeyPersistence> open({
    String boxName = 'mesh_keys',
  }) async {
    final box = await Hive.openBox<String>(boxName);
    return MeshKeyPersistence._(box);
  }

  /// Load or (re)generate the Ed25519 [DeviceKey].
  ///
  /// Returns `(key, didRotate)`. `didRotate` is true when a fresh key was
  /// written to the box in this call — either because it was absent or the
  /// previous one was older than [rotationAge]. Pass [now] for tests.
  Future<(DeviceKey, bool)> loadOrRotateDeviceKey({DateTime? now}) async {
    return _loadOrRotate<DeviceKey>(
      privField: _deviceKeyPrivField,
      createdField: _deviceKeyCreatedField,
      now: now,
      generate: () async {
        final k = await DeviceKey.generate();
        return (k, k.privateKeyBytes);
      },
      revive: (bytes) => DeviceKey.fromPrivateKeyBytes(bytes),
    );
  }

  /// Load or (re)generate the X25519 [MeshStaticKey]. Same semantics as
  /// [loadOrRotateDeviceKey].
  Future<(MeshStaticKey, bool)> loadOrRotateMeshStaticKey({DateTime? now}) async {
    return _loadOrRotate<MeshStaticKey>(
      privField: _meshStaticPrivField,
      createdField: _meshStaticCreatedField,
      now: now,
      generate: () async {
        final k = await MeshStaticKey.generate();
        return (k, k.privateKeyBytes);
      },
      revive: (bytes) => MeshStaticKey.fromPrivateKeyBytes(bytes),
    );
  }

  Future<(T, bool)> _loadOrRotate<T>({
    required String privField,
    required String createdField,
    required DateTime? now,
    required Future<(T, Uint8List)> Function() generate,
    required Future<T> Function(Uint8List) revive,
  }) async {
    final ts = (now ?? DateTime.now()).toUtc();

    final storedPriv = _box.get(privField);
    final storedCreated = _box.get(createdField);

    if (storedPriv != null && storedCreated != null) {
      final createdAt = DateTime.tryParse(storedCreated);
      if (createdAt != null && ts.difference(createdAt) < rotationAge) {
        final bytes = Uint8List.fromList(base64Decode(storedPriv));
        return (await revive(bytes), false);
      }
    }

    // Generate fresh.
    final (fresh, privBytes) = await generate();
    await _box.put(privField, base64Encode(privBytes));
    await _box.put(createdField, ts.toIso8601String());
    return (fresh, true);
  }

  Future<void> close() => _box.close();
}
```

- [ ] **Step 4: Run — expect 4/4 pass**

```bash
cd ~/Downloads/taler_id_mesh
flutter test test/core/mesh/crypto/keys/mesh_key_persistence_test.dart 2>&1 | tail -5
```

Expected: `+4: All tests passed!`

- [ ] **Step 5: Commit**

```bash
cd ~/Downloads/taler_id_mesh
git add lib/core/mesh/crypto/keys/mesh_key_persistence.dart test/core/mesh/crypto/keys/mesh_key_persistence_test.dart
git commit -m "feat(mesh/crypto): Hive-backed persistence + 30d rotation for DeviceKey/MeshStaticKey"
```

---

## Task M3: DeviceCert — add `userPk` field and update canonical order

**Files:**
- Modify: `lib/core/mesh/crypto/keys/device_cert.dart`
- Modify: `test/core/mesh/crypto/keys/device_cert_test.dart`

- [ ] **Step 1: Write failing test**

Open `test/core/mesh/crypto/keys/device_cert_test.dart`. Add a new test group **after** the existing `group('DeviceCert', ...)` tests (do not remove anything yet — we'll adjust them in Step 3):

```dart
  group('DeviceCert userPk (Phase 1c)', () {
    test('toCanonicalJsonWithoutSignature includes userPk in alphabetical order',
        () {
      final cert = DeviceCert(
        devicePk: 'ab' * 32,
        userId: 'user-1',
        userPk: 'cd' * 32,
        algorithm: 'X25519',
        validUntilEpochMs: 1_800_000_000_000,
        signature: 'ff' * 64,
      );
      final json = cert.toCanonicalJsonWithoutSignature();
      // Alphabetical order: algorithm, devicePk, userId, userPk, validUntilEpochMs
      final iAlg = json.indexOf('"algorithm"');
      final iDev = json.indexOf('"devicePk"');
      final iUserId = json.indexOf('"userId"');
      final iUserPk = json.indexOf('"userPk"');
      final iValid = json.indexOf('"validUntilEpochMs"');
      expect(iAlg < iDev, isTrue);
      expect(iDev < iUserId, isTrue);
      expect(iUserId < iUserPk, isTrue);
      expect(iUserPk < iValid, isTrue);
      expect(json.contains('"userPk":"${'cd' * 32}"'), isTrue);
    });

    test('canonical JSON omits userPk when null (Phase 1b compat)', () {
      final cert = DeviceCert(
        devicePk: 'ab' * 32,
        userId: 'user-1',
        userPk: null,
        algorithm: 'X25519',
        validUntilEpochMs: 1_800_000_000_000,
        signature: 'ff' * 64,
      );
      final json = cert.toCanonicalJsonWithoutSignature();
      expect(json.contains('userPk'), isFalse);
    });

    test('toJson/fromJson round-trip with userPk', () {
      final cert = DeviceCert(
        devicePk: 'ab' * 32,
        userId: 'user-1',
        userPk: 'cd' * 32,
        algorithm: 'X25519',
        validUntilEpochMs: 1_800_000_000_000,
        signature: 'ff' * 64,
      );
      final revived = DeviceCert.fromJson(cert.toJson());
      expect(revived.userPk, equals('cd' * 32));
      expect(revived.devicePk, equals(cert.devicePk));
    });

    test('fromJson tolerates missing userPk (sets to null)', () {
      final map = {
        'devicePk': 'ab' * 32,
        'userId': 'user-1',
        'algorithm': 'X25519',
        'validUntilEpochMs': 1_800_000_000_000,
        'signature': 'ff' * 64,
      };
      final cert = DeviceCert.fromJson(map);
      expect(cert.userPk, isNull);
    });
  });
```

Also update the two existing tests that construct `DeviceCert` (inside the original `group('DeviceCert', ...)` block). Find both places in the file where `DeviceCert(` is called, and change each constructor call to include `userPk: null`. For example, replace:

```dart
      final cert = DeviceCert(
        devicePk: 'ab' * 32,
        userId: 'user-1',
        algorithm: 'X25519',
        validUntilEpochMs: 1_800_000_000_000,
        signature: 'ff' * 64,
      );
```

with:

```dart
      final cert = DeviceCert(
        devicePk: 'ab' * 32,
        userId: 'user-1',
        userPk: null,
        algorithm: 'X25519',
        validUntilEpochMs: 1_800_000_000_000,
        signature: 'ff' * 64,
      );
```

in **both** the `'JSON round-trip preserves fields'` and `'serialises to JSON for transport'` tests. Also adjust the existing assertion in `'JSON round-trip preserves fields'` that checks canonical JSON key order — it currently expects `userId < validUntilEpochMs`, which remains true (but `userPk` is null so absent from canonical output — no change needed beyond the constructor).

- [ ] **Step 2: Run — expect FAIL**

```bash
cd ~/Downloads/taler_id_mesh
flutter test test/core/mesh/crypto/keys/device_cert_test.dart 2>&1 | tail -10
```

Expected: compile errors (the existing `DeviceCert` class doesn't have a `userPk` field).

- [ ] **Step 3: Implement updated `DeviceCert`**

Replace the entire contents of `lib/core/mesh/crypto/keys/device_cert.dart` with:

```dart
import 'dart:convert';

/// Self-signed device certificate for mesh identity.
///
/// A device owns:
/// - an Ed25519 keypair ([UserIdentityKey]) that is permanent per device and
///   signs this cert — its public key is the [userPk] field;
/// - an X25519 keypair ([MeshStaticKey]) whose public key is [devicePk], used
///   for Noise IK ECDH.
///
/// Phase 1b compat: certs issued under Phase 1b have no [userPk] (it is null
/// on the wire). When loading such certs, consumers that want to verify the
/// signature will skip verification and fall back to trusting the server that
/// served the cert.
class DeviceCert {
  /// X25519 static public key (hex, 64 chars).
  final String devicePk;

  /// Taler ID user UUID.
  final String userId;

  /// Ed25519 [UserIdentityKey] public key (hex, 64 chars).
  ///
  /// Null for Phase 1b certs that did not carry a user identity key.
  final String? userPk;

  /// Algorithm of [devicePk]; must be `"X25519"`.
  final String algorithm;

  final int validUntilEpochMs;

  /// Ed25519 signature over [toCanonicalJsonWithoutSignature] (hex, 128 chars).
  final String signature;

  const DeviceCert({
    required this.devicePk,
    required this.userId,
    required this.userPk,
    required this.algorithm,
    required this.validUntilEpochMs,
    required this.signature,
  });

  /// Canonical JSON of the signed fields (excluding `signature`), keys in
  /// alphabetical order, no whitespace. This is what the Ed25519 signature
  /// covers. When [userPk] is null, the field is **omitted** — required for
  /// Phase 1b backward compatibility where signatures were computed without
  /// the field.
  String toCanonicalJsonWithoutSignature() {
    // Alphabetical: algorithm, devicePk, userId, userPk, validUntilEpochMs.
    final map = <String, dynamic>{
      'algorithm': algorithm,
      'devicePk': devicePk,
      'userId': userId,
      if (userPk != null) 'userPk': userPk,
      'validUntilEpochMs': validUntilEpochMs,
    };
    return jsonEncode(map);
  }

  Map<String, dynamic> toJson() => {
        'devicePk': devicePk,
        'userId': userId,
        if (userPk != null) 'userPk': userPk,
        'algorithm': algorithm,
        'validUntilEpochMs': validUntilEpochMs,
        'signature': signature,
      };

  factory DeviceCert.fromJson(Map<String, dynamic> json) => DeviceCert(
        devicePk: json['devicePk'] as String,
        userId: json['userId'] as String,
        userPk: json['userPk'] as String?,
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

- [ ] **Step 4: Run — expect all pass (original + new)**

```bash
cd ~/Downloads/taler_id_mesh
flutter test test/core/mesh/crypto/keys/device_cert_test.dart 2>&1 | tail -5
```

Expected: all tests green (3 original + 4 new = 7). The compile errors from Step 2 should now be gone.

- [ ] **Step 5: Commit**

```bash
cd ~/Downloads/taler_id_mesh
git add lib/core/mesh/crypto/keys/device_cert.dart test/core/mesh/crypto/keys/device_cert_test.dart
git commit -m "feat(mesh/crypto): add userPk to DeviceCert (Phase 1c)"
```

---

## Task M4: CertSigner — sign with UserIdentityKey, verify against userPk

**Files:**
- Modify: `lib/core/mesh/crypto/keys/cert_signer.dart`
- Modify: `test/core/mesh/crypto/keys/cert_signer_test.dart`

- [ ] **Step 1: Write failing test — new behavior**

Open `test/core/mesh/crypto/keys/cert_signer_test.dart`. Replace the **entire file contents** with:

```dart
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:taler_id_mobile/core/mesh/crypto/keys/cert_signer.dart';
import 'package:taler_id_mobile/core/mesh/crypto/keys/device_cert.dart';
import 'package:taler_id_mobile/core/mesh/crypto/keys/mesh_static_key.dart';
import 'package:taler_id_mobile/core/mesh/crypto/keys/user_identity_key.dart';

void main() {
  group('CertSigner Phase 1c', () {
    test('sign produces a cert with userPk and Ed25519 signature over userPk inclusive',
        () async {
      final identity = await UserIdentityKey.generate();
      final mesh = await MeshStaticKey.generate();
      final signer = CertSigner(userIdentityKey: identity);

      final cert = await signer.sign(
        meshPublicKey: mesh.publicKey,
        userId: 'user-1',
        validUntilEpochMs: DateTime.now()
            .add(const Duration(days: 30))
            .millisecondsSinceEpoch,
      );

      expect(cert.devicePk.length, 64);
      expect(cert.userPk, isNotNull);
      expect(cert.userPk!.length, 64);
      expect(cert.signature.length, 128);
    });

    test('verify round-trip succeeds using userPk from the cert itself',
        () async {
      final identity = await UserIdentityKey.generate();
      final mesh = await MeshStaticKey.generate();
      final signer = CertSigner(userIdentityKey: identity);
      final cert = await signer.sign(
        meshPublicKey: mesh.publicKey,
        userId: 'user-1',
        validUntilEpochMs: DateTime.now()
            .add(const Duration(days: 30))
            .millisecondsSinceEpoch,
      );

      final ok = await CertSigner.verifyWithEmbeddedUserPk(cert: cert);
      expect(ok, isTrue);
    });

    test('verify rejects tampered userId', () async {
      final identity = await UserIdentityKey.generate();
      final mesh = await MeshStaticKey.generate();
      final signer = CertSigner(userIdentityKey: identity);
      final cert = await signer.sign(
        meshPublicKey: mesh.publicKey,
        userId: 'user-1',
        validUntilEpochMs: DateTime.now()
            .add(const Duration(days: 30))
            .millisecondsSinceEpoch,
      );

      final tampered = DeviceCert(
        devicePk: cert.devicePk,
        userId: 'user-2', // changed
        userPk: cert.userPk,
        algorithm: cert.algorithm,
        validUntilEpochMs: cert.validUntilEpochMs,
        signature: cert.signature,
      );

      final ok = await CertSigner.verifyWithEmbeddedUserPk(cert: tampered);
      expect(ok, isFalse);
    });

    test('verify rejects tampered userPk (attacker swapping identities)',
        () async {
      final identity = await UserIdentityKey.generate();
      final mesh = await MeshStaticKey.generate();
      final signer = CertSigner(userIdentityKey: identity);
      final cert = await signer.sign(
        meshPublicKey: mesh.publicKey,
        userId: 'user-1',
        validUntilEpochMs: DateTime.now()
            .add(const Duration(days: 30))
            .millisecondsSinceEpoch,
      );

      final tampered = DeviceCert(
        devicePk: cert.devicePk,
        userId: cert.userId,
        userPk: 'ab' * 32, // attacker's pk — but signature was by real pk
        algorithm: cert.algorithm,
        validUntilEpochMs: cert.validUntilEpochMs,
        signature: cert.signature,
      );

      final ok = await CertSigner.verifyWithEmbeddedUserPk(cert: tampered);
      expect(ok, isFalse);
    });

    test('verifyWithEmbeddedUserPk returns false when cert.userPk is null',
        () async {
      final cert = DeviceCert(
        devicePk: 'ab' * 32,
        userId: 'user-1',
        userPk: null,
        algorithm: 'X25519',
        validUntilEpochMs: 1_800_000_000_000,
        signature: 'ff' * 64,
      );
      final ok = await CertSigner.verifyWithEmbeddedUserPk(cert: cert);
      expect(ok, isFalse);
    });
  });
}
```

- [ ] **Step 2: Run — expect FAIL**

```bash
cd ~/Downloads/taler_id_mesh
flutter test test/core/mesh/crypto/keys/cert_signer_test.dart 2>&1 | tail -5
```

Expected: compile errors (`userIdentityKey` parameter doesn't exist, `verifyWithEmbeddedUserPk` doesn't exist).

- [ ] **Step 3: Implement updated `CertSigner`**

Replace the entire contents of `lib/core/mesh/crypto/keys/cert_signer.dart` with:

```dart
import 'dart:convert';
import 'dart:typed_data';

import 'device_cert.dart';
import 'user_identity_key.dart';

/// Issues and verifies self-signed [DeviceCert]s.
///
/// Signing is performed by a permanent [UserIdentityKey] (Ed25519). The cert
/// binds an X25519 `devicePk` ([MeshStaticKey] public key) to a Taler ID user
/// and to the signing [UserIdentityKey]'s public key (`userPk`). Verifiers
/// read `userPk` out of the cert itself and use it to check the signature —
/// the cert is self-consistent.
class CertSigner {
  final UserIdentityKey userIdentityKey;

  CertSigner({required this.userIdentityKey});

  /// Produce a signed [DeviceCert] committing [meshPublicKey] as the device's
  /// X25519 static pk for [userId], valid until [validUntilEpochMs]. The
  /// returned cert's `userPk` is the hex of [userIdentityKey]'s public key.
  Future<DeviceCert> sign({
    required Uint8List meshPublicKey,
    required String userId,
    required int validUntilEpochMs,
  }) async {
    final devicePkHex = _hex(meshPublicKey);
    final userPkHex = _hex(userIdentityKey.publicKey);
    final draft = DeviceCert(
      devicePk: devicePkHex,
      userId: userId,
      userPk: userPkHex,
      algorithm: 'X25519',
      validUntilEpochMs: validUntilEpochMs,
      signature: '',
    );
    final canonical = draft.toCanonicalJsonWithoutSignature();
    final sigBytes =
        await userIdentityKey.sign(Uint8List.fromList(utf8.encode(canonical)));
    return DeviceCert(
      devicePk: devicePkHex,
      userId: userId,
      userPk: userPkHex,
      algorithm: 'X25519',
      validUntilEpochMs: validUntilEpochMs,
      signature: _hex(sigBytes),
    );
  }

  /// Verify [cert]'s signature using the `userPk` embedded inside the cert.
  ///
  /// Returns false when [cert]'s `userPk` is null (Phase 1b cert — caller
  /// must decide whether to trust it via out-of-band mechanism).
  static Future<bool> verifyWithEmbeddedUserPk({
    required DeviceCert cert,
  }) async {
    final userPkHex = cert.userPk;
    if (userPkHex == null) return false;
    return _verify(cert: cert, userIdentityPublicKey: _unhex(userPkHex));
  }

  /// Low-level verify against an externally-provided [userIdentityPublicKey].
  /// Exposed for testing and future PKI extensions.
  static Future<bool> verify({
    required DeviceCert cert,
    required Uint8List userIdentityPublicKey,
  }) =>
      _verify(cert: cert, userIdentityPublicKey: userIdentityPublicKey);

  static Future<bool> _verify({
    required DeviceCert cert,
    required Uint8List userIdentityPublicKey,
  }) async {
    final canonical = cert.toCanonicalJsonWithoutSignature();
    final msg = Uint8List.fromList(utf8.encode(canonical));
    final sig = _unhex(cert.signature);
    return UserIdentityKey.verify(
      publicKey: userIdentityPublicKey,
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

- [ ] **Step 4: Run — expect 5/5 pass**

```bash
cd ~/Downloads/taler_id_mesh
flutter test test/core/mesh/crypto/keys/cert_signer_test.dart 2>&1 | tail -5
```

Expected: `+5: All tests passed!`

- [ ] **Step 5: Commit**

```bash
cd ~/Downloads/taler_id_mesh
git add lib/core/mesh/crypto/keys/cert_signer.dart test/core/mesh/crypto/keys/cert_signer_test.dart
git commit -m "feat(mesh/crypto): CertSigner uses UserIdentityKey and embeds userPk"
```

---

## Task M5: DeviceKeysApiClient — include userPk in register body

**Files:**
- Modify: `lib/core/mesh/services/device_keys_api_client.dart`
- Modify: `test/core/mesh/services/device_keys_api_client_test.dart`

- [ ] **Step 1: Write failing test**

Open `test/core/mesh/services/device_keys_api_client_test.dart`. Find the `'registerDeviceKey posts cert and returns server response'` test. Replace it with:

```dart
    test('registerDeviceKey posts userPk alongside other cert fields', () async {
      final dio = Dio(BaseOptions(baseUrl: 'https://fake.test'));
      Map<String, dynamic>? capturedBody;
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            if (options.method == 'POST' &&
                options.path == '/profile/device-keys') {
              capturedBody = options.data as Map<String, dynamic>;
              handler.resolve(Response(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'id': 'dk-1',
                  'userId': 'user-1',
                  'devicePk': 'ab' * 32,
                  'userPk': 'cd' * 32,
                  'algorithm': 'X25519',
                  'validUntil': '2030-01-01T00:00:00Z',
                  'certificate': '{}',
                  'signature': 'ff' * 64,
                  'revokedAt': null,
                  'createdAt': '2026-04-22T00:00:00Z',
                },
              ));
            } else {
              handler.next(options);
            }
          },
        ),
      );
      final client = DeviceKeysApiClient(dio);
      final cert = DeviceCert(
        devicePk: 'ab' * 32,
        userId: 'user-1',
        userPk: 'cd' * 32,
        algorithm: 'X25519',
        validUntilEpochMs: 1_800_000_000_000,
        signature: 'ff' * 64,
      );
      final result = await client.registerDeviceKey(cert);
      expect(result['id'], 'dk-1');
      expect(result['userPk'], 'cd' * 32);
      expect(capturedBody, isNotNull);
      expect(capturedBody!['devicePk'], cert.devicePk);
      expect(capturedBody!['certificate'],
          equals(cert.toCanonicalJsonWithoutSignature()));
      // certificate embedded JSON contains userPk
      expect(capturedBody!['certificate'].contains('"userPk"'), isTrue);
    });
```

Also find the `'getContactKeys returns list'` test. Update the mock response to include `userPk`, and update any constructor calls to `DeviceCert(...)` in that file to include `userPk`. For example, in the cert JSON of the mock response:

```dart
            'certificate':
                '{"algorithm":"X25519","devicePk":"${'cd' * 32}","userId":"user-2","userPk":"${'ef' * 32}","validUntilEpochMs":1800000000000}',
```

And add an assertion:
```dart
      expect(certs.first.userPk, 'ef' * 32);
```

- [ ] **Step 2: Run — expect FAIL**

```bash
cd ~/Downloads/taler_id_mesh
flutter test test/core/mesh/services/device_keys_api_client_test.dart 2>&1 | tail -10
```

Expected: compile errors (`userPk` missing from `DeviceCert` constructor) or assertion failures.

- [ ] **Step 3: Update `DeviceKeysApiClient.registerDeviceKey`**

Open `lib/core/mesh/services/device_keys_api_client.dart`. Replace the `registerDeviceKey` method (and read the full current file first to confirm the method shape). The body must now serialize `userPk` into both the top-level JSON and the embedded `certificate` string — the latter comes automatically from `cert.toCanonicalJsonWithoutSignature()` which now emits `userPk`. Replace with:

```dart
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
```

No structural change — `DeviceCert.toCanonicalJsonWithoutSignature()` already emits `userPk` after Task M3, so the embedded certificate is Phase-1c-correct. The backend extracts `userPk` out of that string.

In `getContactKeys`, the embedded certificate parser must extract `userPk` too. Replace `getContactKeys` with:

```dart
  Future<List<DeviceCert>> getContactKeys(String contactUserId) async {
    final res = await _dio.get<List<dynamic>>(
      '/profile/contacts/$contactUserId/keys',
    );
    return res.data!.map((raw) {
      final row = raw as Map<String, dynamic>;
      final certJsonStr = row['certificate'] as String;
      final inner = jsonDecode(certJsonStr) as Map<String, dynamic>;
      return DeviceCert(
        devicePk: inner['devicePk'] as String,
        userId: inner['userId'] as String,
        userPk: inner['userPk'] as String?,
        algorithm: inner['algorithm'] as String,
        validUntilEpochMs: inner['validUntilEpochMs'] as int,
        signature: row['signature'] as String,
      );
    }).toList();
  }
```

- [ ] **Step 4: Run — expect all pass**

```bash
cd ~/Downloads/taler_id_mesh
flutter test test/core/mesh/services/device_keys_api_client_test.dart 2>&1 | tail -5
```

Expected: all tests green.

- [ ] **Step 5: Commit**

```bash
cd ~/Downloads/taler_id_mesh
git add lib/core/mesh/services/device_keys_api_client.dart test/core/mesh/services/device_keys_api_client_test.dart
git commit -m "feat(mesh/services): DeviceKeysApiClient carries userPk (Phase 1c)"
```

---

## Task M6: DeviceKeySyncService — use real userPk, drop placeholder, verify on fetch

**Files:**
- Modify: `lib/core/mesh/services/device_key_sync_service.dart`
- Modify: `test/core/mesh/services/device_key_sync_service_test.dart`

- [ ] **Step 1: Write failing test — new behavior**

Open `test/core/mesh/services/device_key_sync_service_test.dart`. Replace the **entire file contents** with:

```dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:taler_id_mobile/core/mesh/crypto/keys/cert_signer.dart';
import 'package:taler_id_mobile/core/mesh/crypto/keys/contact_key_store_hive.dart';
import 'package:taler_id_mobile/core/mesh/crypto/keys/device_cert.dart';
import 'package:taler_id_mobile/core/mesh/crypto/keys/mesh_static_key.dart';
import 'package:taler_id_mobile/core/mesh/crypto/keys/user_identity_key.dart';
import 'package:taler_id_mobile/core/mesh/services/device_key_sync_service.dart';
import 'package:taler_id_mobile/core/mesh/services/device_keys_api_client.dart';
import 'package:taler_id_mobile/core/mesh/transport/peer_id.dart';

/// In-memory fake of [DeviceKeysApiClient].
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

  test('registerOwnDevice signs cert with UserIdentityKey and posts it',
      () async {
    final api = _FakeApi();
    final store = await HiveContactKeyStore.open(boxName: 'sync-1');
    final identity = await UserIdentityKey.generate();
    final mesh = await MeshStaticKey.generate();
    final service = DeviceKeySyncService(
      api: api,
      store: store,
      userIdentityKey: identity,
      meshStaticKey: mesh,
      myUserId: 'user-1',
    );
    await service.registerOwnDevice();
    expect(api.registerCalls, 1);
    await store.close();
  });

  test('fetchContactKeys stores valid cert keyed by real userPk', () async {
    final api = _FakeApi();
    final store = await HiveContactKeyStore.open(boxName: 'sync-2');

    // Seed a valid cert from another device.
    final otherIdentity = await UserIdentityKey.generate();
    final otherMesh = await MeshStaticKey.generate();
    final otherSigner = CertSigner(userIdentityKey: otherIdentity);
    final validCert = await otherSigner.sign(
      meshPublicKey: otherMesh.publicKey,
      userId: 'user-2',
      validUntilEpochMs: DateTime.now()
          .add(const Duration(days: 30))
          .millisecondsSinceEpoch,
    );
    api.seedContactKeys('user-2', [validCert]);

    final myIdentity = await UserIdentityKey.generate();
    final myMesh = await MeshStaticKey.generate();
    final service = DeviceKeySyncService(
      api: api,
      store: store,
      userIdentityKey: myIdentity,
      meshStaticKey: myMesh,
      myUserId: 'user-1',
    );
    await service.fetchContactKeys('user-2');

    final devicePeer = PeerId.fromHex(validCert.devicePk);
    expect(store.isKnownDevice(devicePeer), isTrue);

    // userPk lookup must match the real user identity pk, not a UUID placeholder.
    final lookedUp = store.lookupUserByDevice(devicePeer);
    final expectedUserPkHex = _hex(otherIdentity.publicKey);
    expect(lookedUp?.toHex(), equals(expectedUserPkHex));

    await store.close();
  });

  test('fetchContactKeys drops cert with invalid signature', () async {
    final api = _FakeApi();
    final store = await HiveContactKeyStore.open(boxName: 'sync-3');

    // Produce a valid cert then tamper with userId — signature no longer matches.
    final identity = await UserIdentityKey.generate();
    final mesh = await MeshStaticKey.generate();
    final signer = CertSigner(userIdentityKey: identity);
    final cert = await signer.sign(
      meshPublicKey: mesh.publicKey,
      userId: 'user-2',
      validUntilEpochMs: DateTime.now()
          .add(const Duration(days: 30))
          .millisecondsSinceEpoch,
    );
    final tampered = DeviceCert(
      devicePk: cert.devicePk,
      userId: 'evil-attacker',
      userPk: cert.userPk,
      algorithm: cert.algorithm,
      validUntilEpochMs: cert.validUntilEpochMs,
      signature: cert.signature,
    );
    api.seedContactKeys('user-2', [tampered]);

    final service = DeviceKeySyncService(
      api: api,
      store: store,
      userIdentityKey: await UserIdentityKey.generate(),
      meshStaticKey: await MeshStaticKey.generate(),
      myUserId: 'user-1',
    );
    await service.fetchContactKeys('user-2');

    expect(store.isKnownDevice(PeerId.fromHex(tampered.devicePk)), isFalse);
    await store.close();
  });

  test('fetchContactKeys stores Phase 1b cert (userPk null) via server-trust fallback',
      () async {
    final api = _FakeApi();
    final store = await HiveContactKeyStore.open(boxName: 'sync-4');

    // Simulate a legacy Phase 1b cert: userPk null.
    final legacy = DeviceCert(
      devicePk: 'ab' * 32,
      userId: 'user-legacy',
      userPk: null,
      algorithm: 'X25519',
      validUntilEpochMs: DateTime.now()
          .add(const Duration(days: 30))
          .millisecondsSinceEpoch,
      signature: 'ff' * 64,
    );
    api.seedContactKeys('user-legacy', [legacy]);

    final service = DeviceKeySyncService(
      api: api,
      store: store,
      userIdentityKey: await UserIdentityKey.generate(),
      meshStaticKey: await MeshStaticKey.generate(),
      myUserId: 'user-1',
    );
    await service.fetchContactKeys('user-legacy');

    expect(store.isKnownDevice(PeerId.fromHex('ab' * 32)), isTrue);
    await store.close();
  });
}

String _hex(List<int> bytes) {
  final buf = StringBuffer();
  for (final b in bytes) {
    buf.write(b.toRadixString(16).padLeft(2, '0'));
  }
  return buf.toString();
}
```

- [ ] **Step 2: Run — expect FAIL**

```bash
cd ~/Downloads/taler_id_mesh
flutter test test/core/mesh/services/device_key_sync_service_test.dart 2>&1 | tail -10
```

Expected: compile errors (`userIdentityKey` parameter doesn't exist on `DeviceKeySyncService`, `signingKey` still required).

- [ ] **Step 3: Implement updated `DeviceKeySyncService`**

Replace the entire contents of `lib/core/mesh/services/device_key_sync_service.dart` with:

```dart
import 'package:flutter/foundation.dart';

import '../crypto/keys/cert_signer.dart';
import '../crypto/keys/contact_key_store_hive.dart';
import '../crypto/keys/device_cert.dart';
import '../crypto/keys/mesh_static_key.dart';
import '../crypto/keys/user_identity_key.dart';
import '../transport/peer_id.dart';
import 'device_keys_api_client.dart';

/// Coordinates backend device-key sync with local HiveContactKeyStore.
///
/// Phase 1c: certs are signed by the permanent [UserIdentityKey]. On fetch,
/// each cert is verified against its own `userPk` (self-consistency). Certs
/// with a null `userPk` are treated as Phase 1b legacy and stored without
/// signature verification (trusting the JWT-authenticated server).
class DeviceKeySyncService {
  final DeviceKeysApiClient api;
  final HiveContactKeyStore store;
  final UserIdentityKey userIdentityKey;
  final MeshStaticKey meshStaticKey;
  final String myUserId;
  final Duration certValidity;

  DeviceKeySyncService({
    required this.api,
    required this.store,
    required this.userIdentityKey,
    required this.meshStaticKey,
    required this.myUserId,
    this.certValidity = const Duration(days: 30),
  });

  /// Mint a fresh self-signed cert and POST it to the server.
  Future<void> registerOwnDevice() async {
    final signer = CertSigner(userIdentityKey: userIdentityKey);
    final cert = await signer.sign(
      meshPublicKey: meshStaticKey.publicKey,
      userId: myUserId,
      validUntilEpochMs:
          DateTime.now().add(certValidity).millisecondsSinceEpoch,
    );
    await api.registerDeviceKey(cert);
  }

  /// Fetch the contact's active certs and persist only those that verify
  /// against their embedded `userPk`. Phase 1b certs (userPk == null) are
  /// persisted via server-trust fallback — the store still groups them by
  /// userId placeholder PeerId.
  Future<void> fetchContactKeys(String contactUserId) async {
    final certs = await api.getContactKeys(contactUserId);
    if (certs.isEmpty) {
      debugPrint('[mesh-sync] no keys for $contactUserId');
      return;
    }
    for (final cert in certs) {
      if (cert.userPk != null) {
        final ok = await CertSigner.verifyWithEmbeddedUserPk(cert: cert);
        if (!ok) {
          debugPrint(
            '[mesh-sync] dropping cert with bad signature devicePk=${cert.devicePk}',
          );
          continue;
        }
        final userPeer = PeerId.fromHex(cert.userPk!);
        await store.addContactCerts(userPk: userPeer, certs: [cert]);
      } else {
        // Phase 1b legacy cert: no userPk to verify against. Trust the server
        // for backward compat; key the entry by a UUID-derived PeerId.
        final fallbackUserPk = _derivePlaceholderUserPk(contactUserId);
        await store.addContactCerts(userPk: fallbackUserPk, certs: [cert]);
      }
    }
  }

  /// Legacy Phase 1b placeholder derivation for certs that predate Phase 1c.
  /// Not used for any cert that carries a real `userPk`.
  PeerId _derivePlaceholderUserPk(String userId) {
    final bytes = Uint8List(32);
    final utf = userId.codeUnits;
    for (var i = 0; i < utf.length && i < 32; i++) {
      bytes[i] = utf[i] & 0xFF;
    }
    return PeerId(bytes);
  }
}
```

Note: `Uint8List` comes from `dart:typed_data`. Add the import at the top:

```dart
import 'dart:typed_data';
```

- [ ] **Step 4: Run — expect 4/4 pass**

```bash
cd ~/Downloads/taler_id_mesh
flutter test test/core/mesh/services/device_key_sync_service_test.dart 2>&1 | tail -5
```

Expected: `+4: All tests passed!`

- [ ] **Step 5: Commit**

```bash
cd ~/Downloads/taler_id_mesh
git add lib/core/mesh/services/device_key_sync_service.dart test/core/mesh/services/device_key_sync_service_test.dart
git commit -m "feat(mesh/services): DeviceKeySyncService uses UserIdentityKey + verify on fetch"
```

---

## Task M7: Wire persistence into service_locator

**Files:**
- Modify: `lib/core/di/service_locator.dart`

- [ ] **Step 1: Replace ephemeral key generation with persistent load/rotate**

Open `lib/core/di/service_locator.dart`. Find the "Mesh Phase 1b" block (around lines 135-171). Replace everything between the `// Mesh Phase 1b` comment and the blank line that ends that block with:

```dart
  // ---------------------------------------------------------------------------
  // Mesh Phase 1c — persistent identity + rotating device keys
  // ---------------------------------------------------------------------------
  //
  // UserIdentityKey is permanent per device (FlutterSecureStorage). DeviceKey
  // and MeshStaticKey are rotated every 30 days — the rotation check runs at
  // startup and triggers a fresh POST /profile/device-keys if any key was
  // regenerated. Phase 1e will wire _placeholderUserId() to the real JWT user
  // id; until then registerOwnDevice() is still dormant.
  final userIdentityKey = await UserIdentityKey.loadOrCreate(
    const FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
      iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
    ),
  );
  sl.registerSingleton<UserIdentityKey>(userIdentityKey);

  final meshKeyPersistence = await MeshKeyPersistence.open(
    boxName: 'mesh_keys',
  );
  sl.registerSingleton<MeshKeyPersistence>(meshKeyPersistence);

  final (deviceKey, deviceKeyRotated) =
      await meshKeyPersistence.loadOrRotateDeviceKey();
  sl.registerSingleton<DeviceKey>(deviceKey);

  final (meshStaticKey, meshStaticRotated) =
      await meshKeyPersistence.loadOrRotateMeshStaticKey();
  sl.registerSingleton<MeshStaticKey>(meshStaticKey);

  // Hive-backed contact key store. Box name is stable across restarts.
  final contactKeyStore = await HiveContactKeyStore.open(
    boxName: 'mesh_contacts',
  );
  sl.registerSingleton<HiveContactKeyStore>(contactKeyStore);

  sl.registerLazySingleton<DeviceKeysApiClient>(
    () => DeviceKeysApiClient(sl<DioClient>().dio),
  );

  sl.registerLazySingleton<DeviceKeySyncService>(
    () => DeviceKeySyncService(
      api: sl<DeviceKeysApiClient>(),
      store: sl<HiveContactKeyStore>(),
      userIdentityKey: sl<UserIdentityKey>(),
      meshStaticKey: sl<MeshStaticKey>(),
      myUserId: _placeholderUserId(),
    ),
  );

  // If any rotating key was regenerated, push a fresh cert. Best-effort: a
  // failure here must not block app startup. Wait for Phase 1e to wire the
  // real userId before this does anything useful — until then the POST goes
  // to the DEV server under the placeholder userId (dormant).
  if (deviceKeyRotated || meshStaticRotated) {
    // ignore: unawaited_futures
    sl<DeviceKeySyncService>().registerOwnDevice().catchError((e, st) {
      debugPrint('[mesh] registerOwnDevice failed: $e');
    });
  }
```

Add these imports at the top of the file next to the existing Phase 1b block:

```dart
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../mesh/crypto/keys/mesh_key_persistence.dart';
import '../mesh/crypto/keys/user_identity_key.dart';
```

(keep the existing `contact_key_store_hive`, `device_key`, `mesh_static_key`, `device_key_sync_service`, `device_keys_api_client` imports — they remain in use).

- [ ] **Step 2: Static analysis**

```bash
cd ~/Downloads/taler_id_mesh
flutter analyze lib/core/di/service_locator.dart 2>&1 | tail -5
```

Expected: `No issues found!`

- [ ] **Step 3: Full mesh test pass**

```bash
cd ~/Downloads/taler_id_mesh
flutter test test/core/mesh/ 2>&1 | tail -5
```

Expected: all tests green (Phase 1a + 1b + new Phase 1c = approx. 64+).

- [ ] **Step 4: Commit**

```bash
cd ~/Downloads/taler_id_mesh
git add lib/core/di/service_locator.dart
git commit -m "feat(mesh/di): persist UserIdentityKey + rotate DeviceKey/MeshStaticKey"
```

---

## Task M8: Update mobile integration test

**Files:**
- Modify: `integration_test/mesh_device_keys_test.dart`

- [ ] **Step 1: Update to use UserIdentityKey + assert userPk roundtrip**

Replace the entire contents of `integration_test/mesh_device_keys_test.dart` with:

```dart
// Phase 1c integration test: register own device key with userPk + contact
// fetches and verifies it. Runs against staging.id.taler.tirol.
//
// flutter test integration_test/mesh_device_keys_test.dart \
//   --flavor dev -t lib/main_dev.dart \
//   --dart-define=FLAVOR=dev \
//   --dart-define=BASE_URL=https://staging.id.taler.tirol \
//   -d emulator-5554

import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';

import 'package:taler_id_mobile/core/mesh/crypto/keys/contact_key_store_hive.dart';
import 'package:taler_id_mobile/core/mesh/crypto/keys/mesh_static_key.dart';
import 'package:taler_id_mobile/core/mesh/crypto/keys/user_identity_key.dart';
import 'package:taler_id_mobile/core/mesh/services/device_key_sync_service.dart';
import 'package:taler_id_mobile/core/mesh/services/device_keys_api_client.dart';
import 'package:taler_id_mobile/core/mesh/transport/peer_id.dart';

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
  final token = res.data!['accessToken'] as String;
  final parts = token.split('.');
  final payload = jsonDecode(
    utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
  ) as Map<String, dynamic>;
  return (token: token, userId: payload['sub'] as String);
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'Phase 1c — register own key (userPk) + user2 fetches and verifies it',
    (tester) async {
      final appDir = await getApplicationDocumentsDirectory();
      await Hive.initFlutter('${appDir.path}/mesh_integ_test_c');

      final bootstrapDio = Dio(BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
      ));

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

      final identity1 = await UserIdentityKey.generate();
      final mesh1 = await MeshStaticKey.generate();
      final devicePk = PeerId(mesh1.publicKey);

      final stamp = DateTime.now().millisecondsSinceEpoch;
      final store1 = await HiveContactKeyStore.open(boxName: 'integ-u1-c-$stamp');
      final svc1 = DeviceKeySyncService(
        api: DeviceKeysApiClient(dio1),
        store: store1,
        userIdentityKey: identity1,
        meshStaticKey: mesh1,
        myUserId: u1.userId,
      );

      await svc1.registerOwnDevice();

      final store2 = await HiveContactKeyStore.open(boxName: 'integ-u2-c-$stamp');
      final svc2 = DeviceKeySyncService(
        api: DeviceKeysApiClient(dio2),
        store: store2,
        userIdentityKey: await UserIdentityKey.generate(),
        meshStaticKey: await MeshStaticKey.generate(),
        myUserId: u2.userId,
      );
      await svc2.fetchContactKeys(u1.userId);

      // Device known (cert passed signature verification on fetch).
      expect(store2.isKnownDevice(devicePk), isTrue,
          reason: "user2 should have user1's device pk after verification");

      // The stored cert must map to user1's real userPk (not a UUID-derived placeholder).
      final looked = store2.lookupUserByDevice(devicePk);
      expect(looked?.bytes, equals(identity1.publicKey),
          reason: 'stored userPk must be user1 UserIdentityKey, not placeholder');

      await store1.close();
      await store2.close();
    },
    timeout: const Timeout(Duration(seconds: 60)),
  );
}
```

- [ ] **Step 2: Analyze**

```bash
cd ~/Downloads/taler_id_mesh
flutter analyze integration_test/mesh_device_keys_test.dart 2>&1 | tail -5
```

Expected: `No issues found!`

- [ ] **Step 3: Commit**

```bash
cd ~/Downloads/taler_id_mesh
git add integration_test/mesh_device_keys_test.dart
git commit -m "test(mesh): Phase 1c integration — userPk roundtrip + on-fetch verify"
```

---

## Task R1: Update E2E smoke test + final push

**Files:**
- Modify: `~/Downloads/taler_id_tests/device_keys_test.ts`

- [ ] **Step 1: Update the smoke-test cert payload to include userPk**

Open `~/Downloads/taler_id_tests/device_keys_test.ts`. Find the block that builds the cert (currently around lines 78-95). Replace with:

```typescript
  // Unique per run so revoked keys from previous runs don't cause constraint errors.
  const devicePk = Array.from(
    { length: 64 },
    () => Math.floor(Math.random() * 16).toString(16),
  ).join('');
  const userPk = Array.from(
    { length: 64 },
    () => Math.floor(Math.random() * 16).toString(16),
  ).join('');
  const sig = 'ff'.repeat(64);
  const validUntilEpochMs = Date.now() + 30 * 86_400_000;
  const cert = JSON.stringify({
    algorithm: 'X25519',
    devicePk,
    userId: user1.userId,
    userPk,
    validUntilEpochMs,
  });
```

Also in the `register device key for user1` test, after the existing `res.devicePk` check, add:

```typescript
    if (res.userPk !== userPk) throw new Error(`userPk mismatch: ${res.userPk}`);
```

And in the `fetch user1's keys from user2's POV` test, add after the existing `found.devicePk !== devicePk` check:

```typescript
    if (found.userPk !== userPk) throw new Error(`userPk mismatch in list: ${found.userPk}`);
```

- [ ] **Step 2: Run the smoke test against DEV**

```bash
cd ~/Downloads/taler_id_tests
npm run test:mesh 2>&1 | tail -15
```

Expected: `✅ 8/8 tests passed`.

- [ ] **Step 3: Re-run full mobile mesh suite**

```bash
cd ~/Downloads/taler_id_mesh
flutter analyze lib/core/mesh/ 2>&1 | tail -3
flutter test test/core/mesh/ 2>&1 | tail -3
```

Expected: `No issues found!` + `All tests passed!` (Phase 1a + 1b + 1c — 60+ tests green).

- [ ] **Step 4: Re-run backend unit tests**

```bash
cd ~/taler-id-mesh
npm test -- --testPathPatterns='device-keys.service.spec' 2>&1 | tail -10
```

Expected: 10/10 tests green (original 7 + 3 new).

- [ ] **Step 5: Push both branches**

```bash
cd ~/taler-id-mesh && git push origin feature/mesh-bridge
cd ~/Downloads/taler_id_mesh && git push origin feature/mesh-network
```

Expected: both pushes succeed.

- [ ] **Step 6: Do NOT merge**

Per standing instruction: no merges until the full mesh feature is complete. Phase 1d (BLE transport) is next.

---

## Self-Review Notes

### Spec coverage

- Spec §4 — Key model with three storage strategies → Tasks M1 (UserIdentityKey), M2 (DeviceKey + MeshStaticKey persistence), M7 (DI wiring) ✓
- Spec §5 — Updated DeviceCert with userPk → Task M3 ✓
- Spec §5 — canonical JSON with `userPk` in alphabetical position → Task M3 Step 1 (first test) ✓
- Spec §5 — backward compat (userPk null omitted from canonical JSON) → Task M3 Step 1 (second test) ✓
- Spec §6 — CertSigner takes UserIdentityKey → Task M4 ✓
- Spec §6 — receiver verifies embedded userPk → Task M4 + M6 ✓
- Spec §6 — DeviceKeySyncService uses real userPk from cert → Task M6 ✓
- Spec §6 — legacy fallback for null userPk → Task M6 Step 3 ✓
- Spec §7 — nullable `userPk` column on DeviceKey → Task B1 ✓
- Spec §7 — backend extracts userPk from cert JSON → Task B2 ✓
- Spec §7 — DeviceKeyResponseDto returns userPk → Task B2 ✓
- Spec §7 — API returns userPk → Task B2 + B3 ✓
- Spec §8 — startup flow (load-or-rotate + re-register) → Task M7 ✓
- Spec §9 — mobile unit tests → Tasks M1/M2/M3/M4/M6 ✓
- Spec §9 — backend unit tests (register extracts userPk) → Task B2 ✓
- Spec §9 — e2e tests updated → Tasks B3 (backend), R1 (taler_id_tests), M8 (mobile integration) ✓
- Spec §11 — deploy DEV only → Task B4 ✓
- Spec §11 — no PROD unless asked → R1 Step 6 ✓

### Placeholder scan

- Every code step has complete code, not TBD / TODO / "add validation"
- Every test step has full test code
- Every shell step has the exact command and expected output description
- No "similar to Task N" references — each task's code block is self-contained

### Type consistency

- `DeviceCert.userPk` is `String?` everywhere (M3, M4, M6, B2)
- `CertSigner.sign` takes `userIdentityKey: UserIdentityKey` in M4 and M6
- `DeviceKeySyncService` constructor param name is `userIdentityKey` everywhere (M6, M7, M8)
- Backend `userPk` column is `String?` (nullable) in B1 — matches mobile Phase 1b compat
- Hex output is lowercase (backend normalizes in B2, mobile's `_hex` emits lowercase naturally)

---

## Execution Handoff

After saving the plan, offer execution choice:

**Subagent-Driven (recommended)** — fresh subagent per task with two-stage review. Parallel-safe across task boundaries.

**Inline Execution** — batch mode with checkpoints for review.

Total tasks: 14 (B1–B4 + M1–M8 + R1). Backend first, then mobile, then smoke-test roundtrip.

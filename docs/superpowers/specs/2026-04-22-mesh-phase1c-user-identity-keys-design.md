# Mesh Phase 1c — User Identity Keys & Key Persistence

**Date:** 2026-04-22
**Status:** Design approved, ready for implementation planning

**Working dirs:**
- Mobile (Flutter): `~/Downloads/taler_id_mesh/` — branch `feature/mesh-network` (off `dev`)
- Backend (NestJS): `~/taler-id-mesh/` — branch `feature/mesh-bridge` (off `main`)

---

## 1. Executive Summary

Phase 1c makes mesh identity persistent across app restarts and adds proper cert-chain semantics.

**Problem addressed:** In Phase 1b, all keys (`DeviceKey` Ed25519 + `MeshStaticKey` X25519) are regenerated on every app launch. This means every restart produces a new identity — unusable for real-world operation. Device certs are self-signed by a rotating key, with no permanent identity anchor.

**What changes:**
- Introduce `UserIdentityKey` — a permanent per-device Ed25519 keypair stored in `flutter_secure_storage`. Signs device certs.
- Persist `DeviceKey` (Ed25519) and `MeshStaticKey` (X25519) in Hive with a creation timestamp; rotate at startup if older than 30 days.
- Extend `DeviceCert` with a `userPk` field (hex of `UserIdentityKey` public key); signature is now produced by `UserIdentityKey`, not `DeviceKey`.
- Replace the placeholder `_derivePlaceholderUserPk` in `DeviceKeySyncService` with the real `userPk` extracted from the cert.
- Backend stores `userPk` alongside each device cert and returns it in list responses.

**Scope note:** Each device has its own independent `UserIdentityKey`. No cross-device identity sharing, no backup/export — deferred to a later phase.

---

## 2. Decision Log

| # | Question | Decision | Rationale |
|---|----------|----------|-----------|
| 1 | Multi-device identity | B: one `UserIdentityKey` per device (separate identities) | Simplest; export/import machinery deferred |
| 2 | Where does `userPk` live | B: embedded in cert, backend indexes it | Self-contained cert; no separate PKI table |
| 3 | Rotation strategy | A: check at startup, rotate if older than 30 days | Simple time-based, no background task needed |
| 4 | Existing `DeviceKey` role | Keep alongside `UserIdentityKey` (BLE identity in Phase 1d+) | Matches spec Section 6; avoids refactor when BLE lands |
| 5 | Backward compatibility | Backend `userPk` column is nullable | Existing Phase 1b certs stay valid until they expire |
| 6 | Receiver-side signature verification | Enforced: reject cert if signature doesn't match `userPk` from the cert | Self-consistency check; cheap to implement, catches server tampering |

---

## 3. Goals & Non-Goals

### Goals

1. `UserIdentityKey` persists across app restarts (permanent per device)
2. `DeviceKey` + `MeshStaticKey` persist across restarts, auto-rotate at 30 days
3. `DeviceCert` includes `userPk`; signed by `UserIdentityKey`
4. Backend stores and returns `userPk` with each device cert
5. Receivers verify cert self-consistency (signature matches claimed `userPk`)
6. `HiveContactKeyStore` uses real `userPk` from cert, not the UUID-derivation placeholder

### Non-Goals (Phase 1c)

- BLE transport (deferred to Phase 1d)
- Settings UI for mesh (deferred to Phase 1e)
- Cross-device identity sync / export-import
- Server-side cert signature verification (server only stores; trust via JWT on upload)
- Routing layer (direct links only via Bonjour — unchanged from Phase 1a)
- Multi-hop onion (unchanged from Phase 1a)
- Revocation of compromised `UserIdentityKey` (only `DeviceKey` revocation via existing Phase 1b endpoint)

---

## 4. Key Model

### Three keys, three storage strategies

| Key | Algorithm | Lifetime | Storage | Storage key(s) |
|-----|-----------|----------|---------|----------------|
| `UserIdentityKey` | Ed25519 | permanent | `flutter_secure_storage` | `mesh_user_identity_priv` |
| `DeviceKey` | Ed25519 | 30 days, rotating | Hive box `mesh_keys` | `device_key_priv`, `device_key_created_at` |
| `MeshStaticKey` | X25519 | 30 days, rotating | Hive box `mesh_keys` | `mesh_static_priv`, `mesh_static_created_at` |

### Startup logic

```
1. Load UserIdentityKey from flutter_secure_storage.
   If absent: generate Ed25519 keypair, save, emit "first run" signal.

2. Load DeviceKey + created_at from Hive.
   If absent OR age > 30 days: regenerate, save new created_at, mark for re-register.

3. Load MeshStaticKey + created_at from Hive.
   If absent OR age > 30 days: regenerate, save new created_at, mark for re-register.

4. If any of #1/#2/#3 was freshly generated:
   Call DeviceKeySyncService.registerOwnDevice() to push a fresh cert to the backend.
```

No background timer needed. Rotation check is idempotent per app launch. A user who opens the app once every 35 days still rotates on that next launch.

### Roles after Phase 1c

- **`UserIdentityKey`** — signs `DeviceCert`. Stable per-device identity. Exposed as `userPk` in certs. Never rotates in Phase 1c.
- **`DeviceKey`** — no longer signs certs. Reserved for BLE advertising identity (Phase 1d). Rotated every 30 days so advertised prefix changes.
- **`MeshStaticKey`** — unchanged role: X25519 public key used as `devicePk` for Noise IK handshake ECDH.

---

## 5. Updated DeviceCert Format

### Fields

| Field | Type | Source |
|-------|------|--------|
| `algorithm` | `"X25519"` | constant for `devicePk` algorithm |
| `devicePk` | hex 64 chars | `MeshStaticKey` public key |
| `userPk` | hex 64 chars | **NEW** — `UserIdentityKey` public key |
| `userId` | UUID | Taler ID user id (unchanged) |
| `validUntilEpochMs` | int | now + 30 days |
| `signature` | hex 128 chars | **CHANGED** — Ed25519 by `UserIdentityKey` |

### Canonical JSON for signature

Keys in alphabetical order, no whitespace, `signature` excluded:

```json
{"algorithm":"X25519","devicePk":"<hex>","userId":"<uuid>","userPk":"<hex>","validUntilEpochMs":1761945600000}
```

### Backward compatibility

- Backend `userPk` column is nullable. Phase 1b certs (without `userPk`) continue to be stored and returned with `userPk: null`.
- Mobile receivers: if `cert.userPk` is null (old Phase 1b cert), skip signature verification (fall back to "trust the backend"). If present, verify.
- Phase 1b certs naturally expire within 30 days of their issue date — no explicit migration needed.

---

## 6. Mobile Changes

### New files

```
lib/core/mesh/crypto/keys/
├── user_identity_key.dart        # Ed25519 permanent, load/save via SecureStorage
└── mesh_key_persistence.dart     # DeviceKey + MeshStaticKey Hive storage + rotation

test/core/mesh/crypto/keys/
├── user_identity_key_test.dart
└── mesh_key_persistence_test.dart
```

### `UserIdentityKey` interface

```dart
class UserIdentityKey {
  final Uint8List publicKey;       // 32 bytes
  final Uint8List privateKeyBytes; // 32 bytes

  static Future<UserIdentityKey> generate();
  static Future<UserIdentityKey> loadOrCreate(FlutterSecureStorage storage);
  Future<Uint8List> sign(Uint8List message);
  static Future<bool> verify({
    required Uint8List publicKey,
    required Uint8List message,
    required Uint8List signature,
  });
}
```

`loadOrCreate` reads `mesh_user_identity_priv` from secure storage, derives public key, returns instance. If absent, generates a new keypair, persists, returns.

### `MeshKeyPersistence` interface

```dart
class MeshKeyPersistence {
  final Box<String> box;
  static const Duration rotationAge = Duration(days: 30);

  Future<MeshKeyPersistence> open();

  Future<(DeviceKey, bool)> loadOrRotateDeviceKey({DateTime? now});
  Future<(MeshStaticKey, bool)> loadOrRotateMeshStaticKey({DateTime? now});
}
```

Each `loadOrRotate*` returns `(key, didRotate)`. Callers use `didRotate` to trigger `registerOwnDevice()` at startup.

### Updated files

- **`lib/core/mesh/crypto/keys/device_cert.dart`** — add `userPk` field. `toCanonicalJsonWithoutSignature()` orders keys `algorithm, devicePk, userId, userPk, validUntilEpochMs`. Existing `fromJson` / `toJson` handle the new field.
- **`lib/core/mesh/crypto/keys/cert_signer.dart`** — `sign()` now takes `UserIdentityKey` (not `DeviceKey`) and an extra `userIdentityPublicKey` parameter. `verify()` takes the `userPk` bytes from the cert.
- **`lib/core/mesh/services/device_key_sync_service.dart`** — constructor takes `UserIdentityKey` instead of `DeviceKey`. `fetchContactKeys()` extracts `userPk` from each cert (hex → `PeerId`), verifies signature, skips the cert if verification fails. Removes `_derivePlaceholderUserPk`.
- **`lib/core/di/service_locator.dart`** — replaces the `DeviceKey.generate()` + `MeshStaticKey.generate()` calls with `loadOrCreate` + `loadOrRotate*`. On first run or after rotation, calls `registerOwnDevice()`.

### Verification on fetch

```dart
for (final cert in certs) {
  if (cert.userPk == null) continue;  // Phase 1b backward-compat: trust backend
  final userPkBytes = _unhex(cert.userPk!);
  final ok = await CertSigner.verify(cert: cert, userIdentityPublicKey: userPkBytes);
  if (!ok) {
    debugPrint('[mesh-sync] dropping cert with bad signature: ${cert.devicePk}');
    continue;
  }
  await store.addContactCerts(userPk: PeerId(userPkBytes), certs: [cert]);
}
```

---

## 7. Backend Changes

### Prisma schema

Add nullable column to `DeviceKey` model:

```prisma
model DeviceKey {
  // ... existing fields ...
  userPk  String?  // hex 64 chars, Ed25519 public key from cert. Nullable for Phase 1b compat.

  @@index([userPk])
}
```

Migration: `add_user_pk_to_device_keys`. Adds nullable column + index. Zero data loss.

### Service changes

**`src/device-keys/device-keys.service.ts`:**
- `register()` — parse `dto.certificate` as JSON, extract `userPk` field (may be missing for legacy clients — store `null` in that case). Save to DB.
- `toResponseDto()` — include `userPk` field in response.

### DTO changes

**`src/device-keys/dto/register-device-key.dto.ts`** — no change (cert is already passed whole; backend extracts `userPk` from JSON).

**`src/device-keys/dto/device-key-response.dto.ts`** — add `userPk: string | null`.

### API surface

- `POST /profile/device-keys` — unchanged signature; service extracts `userPk` from cert JSON.
- `GET /profile/contacts/:userId/keys` — response items include `userPk` field.
- `POST /profile/device-keys/:id/revoke` — unchanged.

### Backend tests

- **Unit** (`device-keys.service.spec.ts`) — extend `register` cases: verifies `userPk` is extracted from cert and saved; verifies `userPk` appears in response DTO.
- **E2E** (`device-keys.e2e-spec.ts`) — update sample DTOs to include `userPk` in cert; assert response includes `userPk`.

---

## 8. Data Flow

### First app launch

```
App start
  → UserIdentityKey.loadOrCreate() → SecureStorage empty → generate → save
  → MeshKeyPersistence.loadOrRotateDeviceKey() → Hive empty → generate → save
  → MeshKeyPersistence.loadOrRotateMeshStaticKey() → Hive empty → generate → save
  → didRotate == true for all three
  → DeviceKeySyncService.registerOwnDevice()
      → CertSigner.sign(meshPublicKey, userId, userPk, validUntil)  [signed by UserIdentityKey]
      → POST /profile/device-keys {devicePk, userPk, algorithm, validUntilEpochMs, signature, certificate}
      → backend saves with userPk column populated
```

### Subsequent launch (< 30 days later)

```
App start
  → UserIdentityKey.loadOrCreate() → found in SecureStorage → load
  → MeshKeyPersistence.loadOrRotateDeviceKey() → found, age < 30d → load unchanged
  → MeshKeyPersistence.loadOrRotateMeshStaticKey() → found, age < 30d → load unchanged
  → didRotate all false
  → No re-registration needed
```

### Launch after 30+ days

```
App start
  → UserIdentityKey.loadOrCreate() → load existing (permanent)
  → MeshKeyPersistence.loadOrRotateDeviceKey() → found, age > 30d → generate new, save, didRotate=true
  → MeshKeyPersistence.loadOrRotateMeshStaticKey() → found, age > 30d → generate new, save, didRotate=true
  → DeviceKeySyncService.registerOwnDevice() (new cert with fresh devicePk, same userPk)
      → backend stores alongside old certs (old one still has revokedAt=null but will naturally expire)
```

Old certs on the server accumulate but expire via `validUntil`. Explicit revocation of the superseded cert is out of scope (Phase 1d concern once BLE is active).

### Contact fetches keys

```
User B calls DeviceKeySyncService.fetchContactKeys(userA_id)
  → GET /profile/contacts/:userA_id/keys
  → response: [{devicePk, userPk, certificate, signature, ...}, ...]
  → for each cert:
      - verify signature against userPk in cert
      - if pass: store with PeerId(userPk) as user identifier
      - if fail or userPk null: log + (drop | store without verify for Phase 1b compat)
```

---

## 9. Testing Strategy

### Mobile unit tests

- `user_identity_key_test.dart`
  - generate produces 32-byte public/private pair
  - loadOrCreate creates on first call, loads same key on second
  - sign + verify roundtrip
  - verify rejects wrong key
- `mesh_key_persistence_test.dart`
  - loadOrRotateDeviceKey on empty box generates and returns didRotate=true
  - second call returns same key, didRotate=false
  - forcing `createdAt` to 31 days ago triggers rotation on next call
  - MeshStaticKey variant mirrors the above
- `device_cert_test.dart` (updated) — round-trips `userPk` field; canonical JSON order is alphabetical including `userPk`
- `cert_signer_test.dart` (updated) — signs using `UserIdentityKey`, verifies against `userPk`; rejects when `userPk` or signature tampered

### Backend unit tests

- `device-keys.service.spec.ts` — extended cases:
  - register extracts `userPk` from cert JSON and persists it
  - register tolerates missing `userPk` (stores `null`)
  - listForContact returns `userPk` in each response item

### E2E tests

- `device-keys.e2e-spec.ts` (backend) — updated sample certs include `userPk`; assertions on response shape
- `device_keys_test.ts` (taler_id_tests) — sends cert with `userPk`, verifies it's echoed in list
- `mesh_device_keys_test.dart` (mobile integration) — after `registerOwnDevice` + `fetchContactKeys`, the stored cert has a real `userPk`, and the in-memory verification succeeds

### No regression targets

- Phase 1a text exchange test (`mesh_text_exchange_test.dart`) must still pass
- Phase 1b smoke test against DEV must still pass (certs without `userPk` accepted as nullable)
- Full Flutter `flutter test test/core/mesh/` must show all previous + new tests green

---

## 10. Risks & Mitigations

| Risk | Impact | Mitigation |
|------|--------|-----------|
| SecureStorage corruption / user clears data | `UserIdentityKey` lost → new identity generated, contacts must refetch | Accepted. Same recovery path as any first-launch scenario. |
| User rotates keys while contact is offline | Contact has stale `devicePk`, handshake fails | Accepted for Phase 1c. Phase 1d adds FCM-driven key refresh. |
| `userPk` field absent from legacy Phase 1b cert | Verification must fall back to "trust server" | Explicitly handled: if `cert.userPk == null`, skip verify step and still store. |
| Backend `userPk` column added but old clients keep sending old cert format | No issue — `userPk` is nullable, old certs save as `null` | Non-issue by design. |
| Hive box `mesh_keys` corrupted | Keys regenerate on next launch, same as first-run path | Logged as warning; user sees no error. |

---

## 11. Rollout

1. Land Phase 1c behind the existing feature flag (mesh is dormant until Phase 1e wires it into the messenger UI). Zero user-facing impact.
2. Deploy backend to DEV first; `prisma migrate deploy` applies the nullable column. No downtime.
3. Mobile changes ship on branch `feature/mesh-network`. Existing Phase 1b-registered keys remain functional until expiry.
4. No PROD deploy needed unless explicitly requested — feature flag keeps it invisible.

---

## 12. Glossary (Phase 1c)

- **`UserIdentityKey`** — Ed25519 keypair permanent to a device install. Signs every device cert this device issues. Exposed publicly as `userPk` in certs.
- **`DeviceKey`** — Ed25519 keypair per device, rotates every 30 days. In Phase 1c its signing role is removed; reserved for BLE advertising identity in Phase 1d.
- **`MeshStaticKey`** — X25519 keypair per device, rotates every 30 days. Public key is `devicePk` in certs and is the static key used in Noise IK handshakes.
- **`userPk`** — hex representation of `UserIdentityKey.publicKey`. Stable identifier of this device's identity for mesh contacts.
- **`devicePk`** — hex representation of `MeshStaticKey.publicKey`. Changes every 30 days; new cert issued with new `devicePk` but same `userPk`.

---

## 13. Next Steps

1. User review of this spec (current step)
2. Address feedback if any
3. Invoke `writing-plans` skill → detailed Phase 1c implementation plan
4. Execute plan via `subagent-driven-development`

# OAuth Phase 1: RFC 7591 Dynamic Client Registration

**Date:** 2026-04-28
**Status:** Approved
**Scope:** Backend only (`~/taler-id/`). No mobile changes. Phase 1 of the [OAuth UI Kit decomposition](./2026-04-28-oauth-ui-kit-decomposition.md).

## Summary

Adds self-service OAuth client registration to the Taler ID OIDC provider so that third-party developers can register their apps without contacting the Taler team. Authenticated, email-verified Taler ID users can `POST /oauth/register` to create a new client (auto-approved with whitelisted default scopes). Manual registration via DB seed remains for system clients (walletx, awakening-bot, people-bot).

The current static client cache (`oidc-provider.factory.ts:29` — `findMany()` once at boot) is replaced with a dynamic per-request `Adapter` that queries Prisma. This removes the "restart NestJS after every client change" friction permanently and is the foundation for live client management.

## Decisions Locked In (from brainstorming)

| Question | Decision |
|---|---|
| Who can register? | Email-verified Taler ID user only (option C) |
| Approval workflow? | Auto-approve (option A) |
| Scopes self-registered can request? | Whitelist `openid profile email offline_access`. `kyc`/`wallet`/`phone` require manual upgrade via admin (option A) |
| Static vs dynamic client lookup? | Dynamic adapter (option B) — replaces static cache permanently |

## Current State

Verified during the [OAuth decomposition exploration](./2026-04-28-oauth-ui-kit-decomposition.md):

- `oidc-provider` lib running with all standard endpoints + PKCE-only
- DB model `OAuthClient` (no `userId`, no `updatedAt`) at [`prisma/schema.prisma:146`](https://github.com/dvvolkovv/taler_id/blob/main/prisma/schema.prisma#L146)
- Clients loaded once at NestJS boot via `prisma.oAuthClient.findMany()` ([`oidc-provider.factory.ts:29`](https://github.com/dvvolkovv/taler_id/blob/main/src/oidc/oidc-provider.factory.ts#L29))
- Live integrators all created via seed/manual SQL — no REST CRUD path
- Auth pattern: `@UseGuards(JwtAuthGuard) + @CurrentUser()` (e.g. `tenant.controller.ts:19-95`)
- `User.emailVerified` flag exists; existing pattern: `if ((user as any).emailVerified) return ...` (auth.service.ts:318)
- `ThrottlerModule` global, per-route override via `@Throttle({short: {limit: N, ttl: ...}})`
- `AuditLog` table + `auditLog(userId, action, ip, ua, meta)` helper used widely (auth.service.ts:339)
- `EmailService` (nodemailer) available but not needed for auto-approve path

## Architecture

Three independent slices:

1. **DB migration** — extend `OAuthClient` with ownership + audit fields. Backwards compatible (new fields nullable).
2. **Replace static client cache → dynamic Prisma adapter** in oidc-provider integration. Lives in `src/oidc/adapters/`.
3. **New `OAuthRegistrationModule`** (controller + service + DTOs) at `src/oauth-registration/`.

Boundaries match existing modules (`tenant`, `kyc`, `auth`).

## Components

### 1. DB migration

```prisma
model OAuthClient {
  id            String   @id @default(uuid())
  clientId      String   @unique
  clientSecret  String
  name          String
  redirectUris  String[]
  allowedScopes String[]
  logoUri       String?
  userId        String?  // NEW — owner; null for system clients
  user          User?    @relation(fields: [userId], references: [id], onDelete: SetNull)  // NEW
  createdAt     DateTime @default(now())
  updatedAt     DateTime @updatedAt  // NEW

  @@index([userId])  // NEW
}
```

`userId` nullable so existing system clients (walletx, awakening-bot, people-bot) pass migration unchanged. `SetNull` on user delete keeps client config intact (only ownership lost). `updatedAt` enables PATCH endpoints to surface mutation time.

The reverse relation on `User` model is added correspondingly:

```prisma
model User {
  // ...existing fields...
  oauthClients OAuthClient[]
}
```

Migration command (run in implementation):
```bash
cd ~/taler-id && npx prisma migrate dev --name oauth_client_user_owner
```

### 2. `PrismaClientAdapter` (dynamic lookup)

New file `src/oidc/adapters/prisma-client-adapter.ts`. Implements oidc-provider's `Adapter` interface for the `Client` model:

```ts
import { Adapter, AdapterPayload } from 'oidc-provider';
import { PrismaService } from '../../prisma/prisma.service';

export class PrismaClientAdapter implements Adapter {
  constructor(private readonly prisma: PrismaService) {}

  async find(id: string): Promise<AdapterPayload | undefined> {
    const c = await this.prisma.oAuthClient.findUnique({ where: { clientId: id } });
    if (!c) return undefined;
    return {
      client_id: c.clientId,
      client_secret: c.clientSecret,
      client_name: c.name,
      redirect_uris: c.redirectUris,
      scope: c.allowedScopes.join(' '),
      logo_uri: c.logoUri ?? undefined,
      token_endpoint_auth_method: 'client_secret_basic',
      grant_types: ['authorization_code', 'refresh_token'],
      response_types: ['code'],
    };
  }

  // The remaining Adapter methods are required by the interface but never
  // called for the Client model in this project's flow (clients are managed
  // through the dedicated REST controller, not via OIDC dynamic registration
  // exposed by oidc-provider itself).
  async upsert(): Promise<void> { throw new Error('not_implemented'); }
  async findByUserCode(): Promise<undefined> { return undefined; }
  async findByUid(): Promise<undefined> { return undefined; }
  async consume(): Promise<void> { throw new Error('not_implemented'); }
  async destroy(): Promise<void> { throw new Error('not_implemented'); }
  async revokeByGrantId(): Promise<void> { throw new Error('not_implemented'); }
}
```

The existing redis-adapter factory (used for `Grant`, `Session`, `AccessToken`, etc.) is extended so requests for `name === 'Client'` return a `PrismaClientAdapter` instance instead of a `RedisOidcAdapter`:

```ts
// src/oidc/adapters/redis-adapter.ts (or wherever the factory lives)
export function adapterFactory(name: string) {
  if (name === 'Client') return new PrismaClientAdapter(prisma);
  return new RedisOidcAdapter(name, redis);
}
```

In `oidc-provider.factory.ts`:
- Delete the static `clients: dbClients` config (lines around 29-47).
- Keep everything else (issuer, scopes, claims, TTLs, JWKS, PKCE).
- Pass the (now Client-aware) adapter factory to the provider's `adapter` config.

### 3. `OAuthRegistrationModule`

New directory `src/oauth-registration/` containing:

#### `oauth-registration.controller.ts`
```ts
@Controller('oauth')
@UseGuards(JwtAuthGuard)
export class OAuthRegistrationController {
  constructor(private readonly svc: OAuthRegistrationService) {}

  @Post('register')
  @Throttle({ short: { limit: 3, ttl: 60_000 } })  // 3 registrations/min/IP
  register(@CurrentUser() user: any, @Body() dto: RegisterClientDto) {
    return this.svc.register(user.sub, dto);
  }

  @Get('clients')
  list(@CurrentUser() user: any) { return this.svc.listMine(user.sub); }

  @Get('clients/:clientId')
  get(@CurrentUser() user: any, @Param('clientId') clientId: string) {
    return this.svc.getMine(user.sub, clientId);
  }

  @Patch('clients/:clientId')
  update(
    @CurrentUser() user: any,
    @Param('clientId') clientId: string,
    @Body() dto: UpdateClientDto,
  ) {
    return this.svc.updateMine(user.sub, clientId, dto);
  }

  @Delete('clients/:clientId')
  remove(@CurrentUser() user: any, @Param('clientId') clientId: string) {
    return this.svc.deleteMine(user.sub, clientId);
  }
}
```

#### `dto/register-client.dto.ts`
```ts
import { IsArray, IsOptional, IsString, IsUrl, ArrayMaxSize, ArrayMinSize, Length, Matches } from 'class-validator';

export class RegisterClientDto {
  @IsString()
  @Length(1, 128)
  client_name!: string;

  @IsArray()
  @ArrayMinSize(1)
  @ArrayMaxSize(10)
  @Matches(/^(https?:\/\/|talerid:\/\/)/i, { each: true, message: 'redirect_uri must use https://, http:// (localhost only), or talerid:// scheme' })
  redirect_uris!: string[];

  @IsOptional()
  @IsUrl({ require_protocol: true })
  logo_uri?: string;

  @IsOptional()
  @IsString()
  scope?: string;  // space-separated; defaults to 'openid profile email offline_access' if omitted
}
```

#### `dto/update-client.dto.ts`
```ts
import { PartialType, OmitType } from '@nestjs/mapped-types';

export class UpdateClientDto extends PartialType(OmitType(RegisterClientDto, [] as const)) {}
// All fields become optional. Updating `scope` is constrained by the same whitelist.
```

#### `oauth-registration.service.ts`

Whitelisted scopes constant:
```ts
export const SELF_REGISTRATION_ALLOWED_SCOPES = ['openid', 'profile', 'email', 'offline_access'] as const;
export const MAX_CLIENTS_PER_USER = 10;
```

Methods:
- `register(userId, dto)`:
  1. Look up the user via `prisma.user.findUnique({ where: { id: userId }, select: { emailVerified: true } })`. If `!user || !user.emailVerified` → throw `ForbiddenException` with `error: 'email_not_verified'`. (The JWT payload contains `sub/email/phone/kyc_status/session_id` — `emailVerified` is NOT in the token, so we must check the DB.)
  2. Count user's clients. If `>= MAX_CLIENTS_PER_USER` → throw with `error: 'client_limit_exceeded'`.
  3. Parse `dto.scope` (or default), validate every scope is in the whitelist; otherwise → throw with `error: 'invalid_scope'` and `error_description` listing allowed scopes.
  4. Validate `redirect_uris` further (no duplicates; localhost on http only).
  5. Generate `clientId = randomUUID()`, `clientSecret = randomBytes(32).toString('base64url')`. Retry once on `clientId` collision (UNIQUE constraint).
  6. `prisma.oAuthClient.create({ data: { clientId, clientSecret, name, redirectUris, allowedScopes, logoUri, userId } })`.
  7. `auditLog(userId, 'OAUTH_CLIENT_REGISTERED', ip, ua, { clientId, name, scopes })`.
  8. Return RFC 7591 response object (see below).

- `listMine(userId)`: `prisma.oAuthClient.findMany({ where: { userId }, orderBy: { createdAt: 'desc' } })` → array of public-shape Client objects (NO `client_secret` in list view; only on registration response).

- `getMine(userId, clientId)`: `findFirst({ where: { clientId, userId } })`. Returns 404 if not found OR not owned by user (no info leak).

- `updateMine(userId, clientId, dto)`: same `findFirst` ownership check → update allowed fields → `auditLog('OAUTH_CLIENT_UPDATED')`.

- `deleteMine(userId, clientId)`: ownership check → `prisma.oAuthClient.delete({ where: { clientId } })` → `auditLog('OAUTH_CLIENT_DELETED')`. Existing access tokens / grants in Redis are NOT proactively revoked (out of scope for Phase 1; they expire naturally within 30 days max).

#### RFC 7591 response shape (POST /oauth/register, 201 Created)

```json
{
  "client_id": "uuid-here",
  "client_secret": "base64url-secret",
  "client_id_issued_at": 1714293000,
  "client_secret_expires_at": 0,
  "client_name": "My App",
  "redirect_uris": ["https://example.com/callback"],
  "scope": "openid profile email offline_access",
  "logo_uri": "https://example.com/logo.png",
  "token_endpoint_auth_method": "client_secret_basic",
  "grant_types": ["authorization_code", "refresh_token"],
  "response_types": ["code"]
}
```

`client_secret_expires_at: 0` per RFC 7591 = "does not expire" (we don't rotate automatically; rotation is Phase 4).

GET/PATCH responses: same shape but `client_secret` is OMITTED (only revealed at creation; rotation flow is future).

#### Error response shape (RFC 7591 §3.2.2)

```json
{
  "error": "invalid_redirect_uri",
  "error_description": "redirect_uri must use https://, http://localhost, or talerid:// scheme"
}
```

Error codes used: `invalid_redirect_uri`, `invalid_client_metadata`, `invalid_scope`, `email_not_verified`, `client_limit_exceeded`, `client_not_found`.

### 4. `oauth-guide.html` mention

Append a short section to `public/oauth-guide.html` documenting the new self-service flow. Wraps existing "Contact Taler team" instruction with a clearer alternative. ~30 lines of HTML — small, not the bulk of the work.

## Data Flow

```
[Developer wants to add "Login with Taler ID" to their app]
        │
        ▼
1. Logs into Taler ID mobile app or web (must have email_verified=true).
2. POST /oauth/register
     Authorization: Bearer <user JWT>
     { "client_name": "My App", "redirect_uris": ["https://myapp.com/callback"] }
        │
        ├─ JwtAuthGuard validates JWT → @CurrentUser injects user
        ├─ @Throttle limits to 3 reg/min/IP
        ├─ Service: emailVerified ✓, < 10 clients ✓, scope whitelist ✓
        ├─ Generate clientId + clientSecret
        ├─ INSERT INTO OAuthClient (... userId=user.sub ...)
        └─ AuditLog INSERT
        │
        ▼
3. Response: 201 Created + RFC 7591 JSON body
4. Developer copies client_id + client_secret into their app config.
        │
        ▼
[Later, end-user visits developer's app, clicks "Login with Taler ID"]
        │
        ▼
5. App redirects to https://id.taler.tirol/oauth/auth?client_id=<new>...
6. oidc-provider invokes the adapter for `Client` model with id=<new>
   → PrismaClientAdapter.find('<new>')
   → Prisma SELECT → returns AdapterPayload
   → flow continues normally (login + consent + token exchange)
   → NO NestJS restart required
```

## Edge Cases

- **User without `emailVerified`** — 403 `email_not_verified`. Error response includes a hint pointing to `/auth/verify-email` flow.
- **Hit limit of 10 clients** — 403 `client_limit_exceeded`. User can `GET /oauth/clients` to see their list and `DELETE` to free a slot.
- **Scope outside whitelist** — 400 `invalid_scope` with `error_description` listing allowed scopes; encourages contacting admin for elevated scopes.
- **`DELETE` of a client with active refresh tokens** — tokens stay valid until natural expiry (max 30d). Out of scope to proactively revoke; revisit in Phase 4 (developer portal).
- **`clientId` UUID collision** — `@unique` constraint catches it; service retries once with a fresh UUID before returning 500. Probability ~10⁻³⁶.
- **`PATCH` of `redirect_uris`** — existing sessions and tokens unaffected (they don't reference redirect URIs after token issuance). New `/oauth/auth` flows use the updated list.
- **`client_secret` rotation** — explicitly out of scope for Phase 1. Workaround: `DELETE` the client and `POST /register` again. Rotation endpoint planned for Phase 4.
- **Client requests `kyc` scope at /oauth/auth time** — oidc-provider verifies requested scopes against `allowedScopes` at the authorization endpoint. Self-registered clients have only whitelisted scopes in `allowedScopes`, so they cannot request `kyc` even if they construct a URL containing it.
- **User account deleted** — `onDelete: SetNull` keeps the client record (orphan, `userId=null`). Manageable only via admin.
- **Developer attempts to access another user's client** — `GET/PATCH/DELETE /oauth/clients/:clientId` filter by `userId = currentUser.sub`. Mismatched ownership returns 404 (not 403) to avoid leaking the existence of other users' clients.

## Testing

### 1. Unit tests — `OAuthRegistrationService`

`src/oauth-registration/oauth-registration.service.spec.ts`. Pattern matches existing service specs (`tenant.service.spec.ts`, `auth.service.spec.ts`). Cases:

- ✓ Email-verified user (mocked `prisma.user.findUnique` returns `{ emailVerified: true }`) with valid DTO → returns RFC 7591 shape, persists row
- ✗ Email-unverified user (mocked `findUnique` returns `{ emailVerified: false }`) → throws `ForbiddenException` with `email_not_verified`
- ✗ User row missing entirely (`findUnique` returns null) → throws `ForbiddenException` with `email_not_verified` (same code path; safer than separate `user_not_found`)
- ✗ User has 10 clients → throws with `client_limit_exceeded`
- ✗ DTO scope contains `kyc` → throws with `invalid_scope`
- ✓ Default scope (no `scope` in DTO) → `openid profile email offline_access`
- ✓ Generates 32-byte base64url client_secret
- ✓ AuditLog called with correct action

### 2. Unit test — `PrismaClientAdapter`

`src/oidc/adapters/prisma-client-adapter.spec.ts`:
- ✓ Existing client → returns AdapterPayload with correct field mapping (`allowedScopes` joined with spaces → `scope`)
- ✓ Missing client → returns undefined (NOT throws)
- ✓ `logoUri = null` → `logo_uri: undefined`

### 3. E2E test

`test/oauth-registration.e2e-spec.ts` (mirrors existing `app.e2e-spec.ts` style, supertest):

- POST /oauth/register with valid JWT + valid body → 201, RFC 7591 body, `client_secret` present
- POST without Authorization header → 401
- POST with email-unverified user JWT → 403 `email_not_verified`
- POST with `scope: "openid kyc"` → 400 `invalid_scope`
- POST 11 times by same user (using fresh JWTs / pre-seeding 10 clients) → 11th = 403 `client_limit_exceeded`
- GET /oauth/clients with two users → each sees only their own
- DELETE another user's client by clientId → 404
- PATCH valid → 200, returns updated client (no `client_secret` in response)

Fall back to plain unit-style spec if the project's e2e bootstrap requires services we don't have in CI (matching the Task 3 fallback used in the deeplink work — see `src/app.controller.spec.ts`).

### 4. Manual smoke (post-deploy on DEV)

After backend deploy to staging:
1. Get a JWT for `integration_test@taler-test.com` via `POST /auth/login`.
2. `curl -X POST https://staging.id.taler.tirol/oauth/register -H "Authorization: Bearer <jwt>" -H "Content-Type: application/json" -d '{"client_name":"Smoke Test","redirect_uris":["https://example.com/cb"]}'` → expect 201 with RFC 7591 body.
3. Open `https://staging.id.taler.tirol/oauth/auth?client_id=<new-id>&redirect_uri=https://example.com/cb&response_type=code&scope=openid+profile&code_challenge_method=S256&code_challenge=<pkce>` in a browser.
4. Expect login + consent screen renders → after approval redirects to `example.com/cb?code=...`. **Critical**: this proves the dynamic adapter picked up the new client without a restart.

## Branch & Commit

- Branch: `main` (per backend project convention).
- ~6 commits expected (from plan, not spec):
  1. DB migration
  2. PrismaClientAdapter + adapter factory wiring
  3. Remove static clients from oidc-provider.factory.ts
  4. OAuthRegistrationModule (controller + service + DTO)
  5. Tests
  6. oauth-guide.html update

Deploy: DEV first per CLAUDE.md `ВСЕГДА деплоить сначала на DEV`. PROD only on explicit user approval.

## Out of Scope

- `client_secret` rotation endpoint (Phase 4)
- Approval review queue / admin UI for clients (Phase 4 — auto-approve is locked in for Phase 1)
- Email confirmation step on registration (auto-approve does not require it)
- Active token revocation on client delete (tokens expire naturally within 30d)
- Brand assets, button components, SDKs (Phases 0/2/3)
- Developer portal UI (Phase 4)
- Migrating existing system clients (walletx/awakening-bot/people-bot) to per-user ownership — they remain `userId=null`, manageable via admin only

## References

- [Phase decomposition](./2026-04-28-oauth-ui-kit-decomposition.md)
- RFC 7591: <https://datatracker.ietf.org/doc/html/rfc7591>
- oidc-provider Adapter API: <https://github.com/panva/node-oidc-provider/blob/main/docs/README.md#adapter>
- Existing OIDC factory: [`~/taler-id/src/oidc/oidc-provider.factory.ts`](https://github.com/dvvolkovv/taler_id/blob/main/src/oidc/oidc-provider.factory.ts)
- Existing OAuthClient schema: [`~/taler-id/prisma/schema.prisma:146`](https://github.com/dvvolkovv/taler_id/blob/main/prisma/schema.prisma#L146)
- Existing JwtAuthGuard pattern: [`~/taler-id/src/common/guards/jwt-auth.guard.ts`](https://github.com/dvvolkovv/taler_id/blob/main/src/common/guards/jwt-auth.guard.ts)
- ThrottlerModule per-route override: NestJS docs <https://docs.nestjs.com/security/rate-limiting>

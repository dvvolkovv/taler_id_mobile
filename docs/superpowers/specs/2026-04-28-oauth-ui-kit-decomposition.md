# OAuth UI Kit — Decomposition (preparation, not a spec)

**Date:** 2026-04-28
**Status:** Decomposition document — informs future spec work, not directly implementable.
**Origin:** User asked for "UI Kit для сторонних приложений для коннекта через OAuth к talerid". Exploration revealed the OIDC backend is already production-ready, so the work is integration enablement, not provider construction.

## Current State (as of 2026-04-28)

The Taler ID OAuth/OIDC provider is **fully operational** in production:

- Library: `oidc-provider` (npm) wrapped by NestJS
- Code: [`~/taler-id/src/oidc/`](https://github.com/dvvolkovv/taler_id/tree/main/src/oidc)
  - `oidc-interaction.controller.ts` — login + consent UI handlers
  - `oidc-provider.factory.ts` — issuer config, scopes, claims, TTLs
  - `oidc.service.ts` + `oidc.module.ts`
  - `adapters/redis-adapter.ts` — token/session storage
- DB model: `OAuthClient` (clientId, clientSecret, name, redirectUris[], allowedScopes[], logoUri?) at [`prisma/schema.prisma:146`](https://github.com/dvvolkovv/taler_id/blob/main/prisma/schema.prisma#L146)
- Endpoints (live):
  - `GET /oauth/auth` — authorize
  - `POST /oauth/token` — exchange / refresh
  - `GET /oauth/me` — userinfo
  - `POST /oauth/token/revocation`
  - `GET /oauth/session/end`
  - `GET /oauth/jwks` (RS256, kid `taler-id-rsa`)
  - `GET /oauth/.well-known/openid-configuration`
- Flow: **Authorization Code + PKCE (S256), mandatory.** No implicit, no ROPC.
- Scopes: `openid`, `profile`, `email`, `phone`, `kyc`, `wallet`, `offline_access`
- Token lifetimes: access 15min / id_token 1h / refresh 30d (rotated) / session 14d
- Client auth: `client_secret_basic`
- Public docs: [`public/oauth-guide.html`](https://github.com/dvvolkovv/taler_id/blob/main/public/oauth-guide.html) (626 lines, code examples for Node/Python/Flutter/cURL)
- Live integrators: `walletx` (mobile wallet), `awakening-bot`, `people-bot` — all running in PM2

**Not built yet:**
- Self-service client registration (currently manual — "contact Taler team")
- Branded button assets / logo / brand guide
- Web SDK (npm package wrapping `openid-client` with Taler defaults)
- Mobile SDK (Flutter / iOS / Android wrappers)
- Developer portal (web UI for managing OAuth clients)
- Mobile app's OAuth callback handler ([deep_link_handler.dart:60-69](lib/core/router/deep_link_handler.dart#L60-L69)) is a skeleton — `// Handle OAuth code exchange` is a comment, not implemented

## Five Sub-Projects

Each is independently shippable. Each gets its own `2026-XX-XX-<name>-design.md` spec → plan → implementation cycle when the user picks it up.

---

### Phase 0 — UI Kit (assets + buttons)

**Scope:** the literal "UI Kit" — what gets handed to a third-party developer who wants to add "Sign in with Taler ID".

- Logo SVG: tone-on-light, tone-on-dark, monochrome variants
- Brand guide (one-pager): colors, typography, padding rules, do/don't examples
- Pre-built "Sign in with Taler ID" button:
  - Plain HTML/CSS variant
  - React component (`<TalerIdLoginButton />`)
  - Vue component
  - Flutter widget
- Demo page showing the complete OAuth flow end-to-end with the button
- Hosted on `id.taler.tirol/brand` or GitHub Pages

**Estimate:** ~1-2 days
**Dependencies:** none — start immediately
**Why first:** unblocks every other phase visually; smallest "definition of done"

---

### Phase 1 — Dynamic Client Registration (RFC 7591)

**Scope:** single backend endpoint that lets developers register their app without contacting Taler team.

- `POST /oauth/register` — accepts `client_name`, `redirect_uris[]`, `logo_uri`, `scope`. Returns `client_id` + `client_secret`.
- DB: reuse existing `OAuthClient` model (already has all fields).
- Optional safeguards: email-verified Taler ID required, rate limit, CAPTCHA, approval queue (future).
- Add `GET /oauth/clients/:client_id`, `PATCH`, `DELETE` for self-management.

**Estimate:** ~0.5-1 day (endpoint is small; safeguards are the variable)
**Dependencies:** none — independent of UI Kit
**Why early:** removes the biggest friction (manual onboarding) before SDK adoption scales

---

### Phase 2 — JavaScript SDK

**Scope:** npm package wrapping `openid-client` with Taler defaults so web devs get 1-line integration.

- Package name: `@taler-id/oauth-client` or `talerid-sdk`
- API:
  ```ts
  import { login, useTalerIdAuth } from '@taler-id/oauth-client';
  // or React: const { user, login, logout } = useTalerIdAuth();
  ```
- Auto-PKCE, auto-state/nonce, token refresh, secure storage helpers
- TypeScript types
- README with 5-line quickstart + 3-step examples (vanilla, React, Vue, Next.js)

**Estimate:** ~2-3 days
**Dependencies:** Phase 0 (button asset for README/demo); Phase 1 nice-to-have (so demo can self-register a client)
**Output:** published npm package + docs

---

### Phase 3 — Mobile SDK

**Scope:** native mobile integration packages.

- **Flutter package** `talerid_oauth` (wraps `flutter_appauth`)
  - Includes the button widget from Phase 0
  - Handles the deep-link OAuth callback (which the Taler ID mobile app's own [deep_link_handler.dart:60-69](lib/core/router/deep_link_handler.dart#L60-L69) currently stubs)
- iOS Swift Package (optional, can defer)
- Android Kotlin library (optional, can defer)
- Sample app in repo

**Estimate:** ~2-3 days for Flutter; +2-3 days for native iOS/Android each
**Dependencies:** Phase 0 (Flutter widget asset); Phase 1 helpful
**Bonus:** completes the OAuth callback handler in Taler ID's own mobile app, which is currently a skeleton

---

### Phase 4 — Developer Portal

**Scope:** web app at `developers.id.taler.tirol` (or `id.taler.tirol/developers`) for managing OAuth clients.

- Auth: dogfood — log in with Taler ID itself
- CRUD over your OAuth clients
- View `client_id` + reveal `client_secret` (with confirmation)
- Rotate `client_secret`
- Update `redirect_uris`, `logo_uri`, scopes
- API usage logs / rate-limit dashboard
- Quickstart guides linking to Phase 0/2/3 assets

**Estimate:** ~3-5 days
**Dependencies:** all prior phases (uses SDK for login, displays UI Kit assets, exercises RFC 7591)
**Why last:** assembles everything into a polished onboarding experience

---

## Dependency Graph

```
Phase 0 (UI Kit) ─┬─→ Phase 2 (JS SDK) ─┐
                  └─→ Phase 3 (Mobile)  ─┤
Phase 1 (RFC 7591) ──────────────────── ─├─→ Phase 4 (Dev Portal)
                                         ┘
```

## Recommended Order

1. **Phase 0** + **Phase 1** in parallel (next session) — both independent, both ~1 day, both deliver visible progress
2. **Phase 2** (JS SDK) — biggest dev market
3. **Phase 3** (Flutter SDK) — covers cross-platform integrators; also unblocks Taler ID's own deep-link skeleton
4. **Phase 4** (Dev Portal) — when 0-3 are stable

Total estimate (sequential, by single dev): ~10-15 focused days.

## Open Questions for Phase 0/1 (resolve before starting)

- **Phase 0**: where to host the brand assets — `id.taler.tirol/brand` (NestJS static), GitHub Pages, or both?
- **Phase 0**: what existing brand assets exist? Is there an SVG logo on the download page (`/var/www/html/index.html` per CLAUDE.md)? — extract and standardize.
- **Phase 1**: what's the abuse-prevention bar? Open registration with rate limit, or require an existing Taler ID account + email verification before registering an OAuth client?
- **Phase 1**: do new clients need explicit approval (review queue) or auto-approve? What scopes can a self-registered client request without review?

## Out of Scope (entirely)

- Building a new OIDC provider — already done
- Replacing `oidc-provider` library with custom implementation
- Adding non-OIDC auth methods (SAML, custom tokens)
- Email-marketing / partnership program for integrators (business, not engineering)

## File References

- Backend OIDC: [`~/taler-id/src/oidc/`](https://github.com/dvvolkovv/taler_id)
- DB model: [`~/taler-id/prisma/schema.prisma:146`](https://github.com/dvvolkovv/taler_id)
- Public guide: [`~/taler-id/public/oauth-guide.html`](https://github.com/dvvolkovv/taler_id)
- Mobile callback skeleton: [lib/core/router/deep_link_handler.dart:60-69](lib/core/router/deep_link_handler.dart#L60-L69)
- Live integrators (PM2): `awakening-bot`, `people-bot` (per session memory + CLAUDE.md)

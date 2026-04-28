# Deep Links prod+staging — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make `https://id.taler.tirol/room/<id>`, `https://staging.id.taler.tirol/room/<id>`, and the corresponding `/ui/invite*` URLs open the Taler ID app (prod APK for prod domain, dev APK for staging domain) on iOS and Android, instead of falling through to Safari/Chrome.

**Architecture:** Backend exposes a NestJS controller endpoint at `/.well-known/apple-app-site-association` returning JSON with both prod and dev bundle IDs (Content-Type guaranteed). The existing static `/.well-known/assetlinks.json` is extended with the dev package and its build-server + local-developer SHA-256 fingerprints. Mobile entitlements / manifest gain the `staging.id.taler.tirol` host. No Flutter logic changes — `DeepLinkHandler` already routes both URL forms.

**Tech Stack:** NestJS (TypeScript), supertest e2e, iOS plist, Android XML, Apple Universal Links / Android App Links infrastructure.

**Spec:** [docs/superpowers/specs/2026-04-28-deep-links-prod-staging-design.md](docs/superpowers/specs/2026-04-28-deep-links-prod-staging-design.md)

---

## File Map

**Backend (`~/taler-id/`, branch `main`):**
- Modify `src/app.controller.ts` — add `@Get('.well-known/apple-app-site-association')` handler
- Modify `test/app.e2e-spec.ts` — add e2e test for the new endpoint
- Modify `public/.well-known/assetlinks.json` — extend array with dev package entry

**Mobile (`~/Downloads/taler_id_mobile/`, branch `dev`):**
- Modify `ios/Runner/Runner.entitlements` — add `applinks:staging.id.taler.tirol`
- Modify `android/app/src/main/AndroidManifest.xml` — add 2 staging intent-filters

No new files in either repo.

**Two repos, two pushes** — implementation is split into a backend section (Tasks 1-4) and a mobile section (Tasks 5-7), then deploy + verification (Tasks 8-11).

---

## Pre-flight

- [ ] **P1: Verify mobile repo state**

```bash
cd ~/Downloads/taler_id_mobile && git status --short && git branch --show-current
```

Expected: branch `dev`, only the usual unrelated untracked dev artifacts.

- [ ] **P2: Verify backend repo state**

```bash
cd ~/taler-id && git status --short && git branch --show-current
```

Expected: branch `main`, clean tree (or only safe untracked files).

- [ ] **P3: Confirm baselines**

```bash
cd ~/Downloads/taler_id_mobile && flutter test 2>&1 | tail -2
cd ~/taler-id && npm test 2>&1 | tail -5
```

Expected: mobile 447/447 PASS. Backend Jest unit tests PASS (number varies — note baseline). E2E tests are NOT required to pass at baseline (they need DB), but should at least compile.

---

## Task 1: Backend — AASA controller

**File:** `~/taler-id/src/app.controller.ts`

The existing controller already has `@Get('.well-known/openid-configuration')` (a `@Redirect`). We add a sibling endpoint that RETURNS JSON directly with explicit Content-Type. AASA must NOT redirect (Apple won't follow), and Content-Type must be `application/json` (Apple no longer requires `application/pkcs7-mime`).

- [ ] **Step 1.1: Add the new endpoint method to `AppController`**

Open `~/taler-id/src/app.controller.ts`. The current file is:

```ts
import { Controller, Get, Redirect } from '@nestjs/common';

@Controller()
export class AppController {
  @Get()
  @Redirect('/ui/index.html')
  root() {}

  @Get('health')
  health() { /* ... */ }

  @Get('.well-known/openid-configuration')
  @Redirect('/oauth/.well-known/openid-configuration')
  openidConfiguration() {}

  @Get('app/version')
  appVersion() { /* ... */ }
}
```

Add this new method anywhere inside the class body (e.g., right after `openidConfiguration()` for grouping):

```ts
  @Get('.well-known/apple-app-site-association')
  @Header('Content-Type', 'application/json')
  appleAppSiteAssociation() {
    return {
      applinks: {
        apps: [],
        details: [
          {
            appID: 'MG58MDUNZ2.tirol.taler.talerIdMobile',
            paths: ['/room/*', '/ui/invite*'],
          },
          {
            appID: 'MG58MDUNZ2.tirol.taler.talerIdMobile.dev',
            paths: ['/room/*', '/ui/invite*'],
          },
        ],
      },
    };
  }
```

Update the import to include `Header`:

```ts
import { Controller, Get, Header, Redirect } from '@nestjs/common';
```

- [ ] **Step 1.2: Verify TypeScript compiles**

```bash
cd ~/taler-id && npm run build 2>&1 | tail -10
```

Expected: build succeeds, no TypeScript errors.

- [ ] **Step 1.3: Commit (controller change only — assetlinks update is Task 2)**

```bash
cd ~/taler-id
git add src/app.controller.ts
git commit -m "feat(deeplink): apple-app-site-association controller for both bundle IDs"
```

---

## Task 2: Backend — extend assetlinks.json with dev fingerprints

**File:** `~/taler-id/public/.well-known/assetlinks.json`

Current content (one prod entry):

```json
[
  {
    "relation": ["delegate_permission/common.handle_all_urls"],
    "target": {
      "namespace": "android_app",
      "package_name": "tirol.taler.taler_id_mobile",
      "sha256_cert_fingerprints": [
        "55:08:99:75:33:25:B9:D6:1B:71:70:FD:77:0A:13:B5:82:D6:EE:41:3C:6F:25:C0:C8:D9:AF:87:9E:0C:44:99"
      ]
    }
  }
]
```

We add a SECOND entry for the dev package with TWO fingerprints — the build-server's debug keystore (same as prod, since `app/build.gradle.kts:48` uses `signingConfigs.getByName("debug")` for both flavors on the build server) AND the local developer Mac's debug keystore.

- [ ] **Step 2.1: Replace the file content with the extended array**

```json
[
  {
    "relation": ["delegate_permission/common.handle_all_urls"],
    "target": {
      "namespace": "android_app",
      "package_name": "tirol.taler.taler_id_mobile",
      "sha256_cert_fingerprints": [
        "55:08:99:75:33:25:B9:D6:1B:71:70:FD:77:0A:13:B5:82:D6:EE:41:3C:6F:25:C0:C8:D9:AF:87:9E:0C:44:99"
      ]
    }
  },
  {
    "relation": ["delegate_permission/common.handle_all_urls"],
    "target": {
      "namespace": "android_app",
      "package_name": "tirol.taler.taler_id_mobile.dev",
      "sha256_cert_fingerprints": [
        "55:08:99:75:33:25:B9:D6:1B:71:70:FD:77:0A:13:B5:82:D6:EE:41:3C:6F:25:C0:C8:D9:AF:87:9E:0C:44:99",
        "CE:F2:7D:2C:83:A4:F7:0E:7D:6A:2F:D0:61:79:01:96:B2:72:07:78:02:41:00:BC:2A:BB:58:16:37:E1:04:51"
      ]
    }
  }
]
```

- [ ] **Step 2.2: Validate JSON syntax**

```bash
cat ~/taler-id/public/.well-known/assetlinks.json | jq . > /dev/null && echo "valid JSON" || echo "INVALID"
```

Expected: `valid JSON`.

- [ ] **Step 2.3: Commit**

```bash
cd ~/taler-id
git add public/.well-known/assetlinks.json
git commit -m "feat(deeplink): add dev-flavor package + fingerprints to assetlinks.json"
```

---

## Task 3: Backend — e2e test for AASA endpoint

**File:** `~/taler-id/test/app.e2e-spec.ts`

The existing e2e spec already covers `/` and `/health`. Add a test for the new `/.well-known/apple-app-site-association` endpoint.

- [ ] **Step 3.1: Append the test inside the existing `describe('AppController (e2e)')`**

Right after the existing `it('/health (GET) returns ok', ...)` block, add:

```ts
  it('/.well-known/apple-app-site-association returns AASA JSON', () => {
    return request(app.getHttpServer())
      .get('/.well-known/apple-app-site-association')
      .expect(200)
      .expect('Content-Type', /application\/json/)
      .expect((res) => {
        expect(res.body).toHaveProperty('applinks');
        expect(res.body.applinks.apps).toEqual([]);
        expect(res.body.applinks.details).toHaveLength(2);

        const prod = res.body.applinks.details.find(
          (d: { appID: string }) => d.appID === 'MG58MDUNZ2.tirol.taler.talerIdMobile',
        );
        const dev = res.body.applinks.details.find(
          (d: { appID: string }) => d.appID === 'MG58MDUNZ2.tirol.taler.talerIdMobile.dev',
        );
        expect(prod).toBeDefined();
        expect(dev).toBeDefined();
        expect(prod.paths).toEqual(['/room/*', '/ui/invite*']);
        expect(dev.paths).toEqual(['/room/*', '/ui/invite*']);
      });
  });
```

- [ ] **Step 3.2: Run only the new test**

```bash
cd ~/taler-id && npm run test:e2e -- --testNamePattern="apple-app-site-association" 2>&1 | tail -15
```

Expected: 1 test PASS.

If e2e bootstrap fails because the project requires a real DB / Redis, fall back to a UNIT test instead — create `test/aasa-unit.spec.ts`:

```ts
import { AppController } from '../src/app.controller';

describe('AppController.appleAppSiteAssociation', () => {
  it('returns AASA with both bundle IDs', () => {
    const c = new AppController();
    const out = c.appleAppSiteAssociation();
    expect(out.applinks.apps).toEqual([]);
    expect(out.applinks.details).toHaveLength(2);
    expect(out.applinks.details.map((d) => d.appID).sort()).toEqual([
      'MG58MDUNZ2.tirol.taler.talerIdMobile',
      'MG58MDUNZ2.tirol.taler.talerIdMobile.dev',
    ]);
    out.applinks.details.forEach((d) => {
      expect(d.paths).toEqual(['/room/*', '/ui/invite*']);
    });
  });
});
```

Run: `cd ~/taler-id && npm test -- --testPathPatterns="aasa-unit"`. Expected: PASS.

Pick whichever path actually runs in this codebase — prefer e2e (matches existing `app.e2e-spec.ts` pattern); use unit only as fallback.

- [ ] **Step 3.3: Commit**

```bash
cd ~/taler-id
git add test/
git commit -m "test(deeplink): cover apple-app-site-association endpoint"
```

---

## Task 4: Backend — push to remote `main`

- [ ] **Step 4.1: Verify history is clean and rebased**

```bash
cd ~/taler-id
git fetch origin main
git log --oneline origin/main..HEAD
git log --oneline HEAD..origin/main
```

If remote is ahead, run:

```bash
cd ~/taler-id && git pull --rebase origin main
```

Resolve any conflicts (none expected — touching new endpoint + new asset data).

- [ ] **Step 4.2: Push**

```bash
cd ~/taler-id && git push origin main
```

⚠️ Do NOT proceed to deploy yet — Task 8 covers DEV deploy, Task 10 is gated for PROD.

---

## Task 5: Mobile — add `applinks:staging.id.taler.tirol` to iOS entitlements

**File:** `ios/Runner/Runner.entitlements`

Current array:
```xml
<key>com.apple.developer.associated-domains</key>
<array>
    <string>applinks:id.taler.tirol</string>
</array>
```

- [ ] **Step 5.1: Add staging string**

Use Edit to change:

```xml
    <string>applinks:id.taler.tirol</string>
</array>
```

into:

```xml
    <string>applinks:id.taler.tirol</string>
    <string>applinks:staging.id.taler.tirol</string>
</array>
```

- [ ] **Step 5.2: Sanity-check XML well-formed**

```bash
cd ~/Downloads/taler_id_mobile && plutil -lint ios/Runner/Runner.entitlements 2>&1
```

Expected: `ios/Runner/Runner.entitlements: OK`.

- [ ] **Step 5.3: Commit**

```bash
cd ~/Downloads/taler_id_mobile
git add ios/Runner/Runner.entitlements
git commit -m "feat(ios/deeplink): add applinks:staging.id.taler.tirol entitlement"
```

---

## Task 6: Mobile — add staging intent-filters to AndroidManifest

**File:** `android/app/src/main/AndroidManifest.xml`

Current intent-filters at lines 66-78 cover `id.taler.tirol/room/*` and `/ui/invite`. We add a sibling pair for `staging.id.taler.tirol`.

- [ ] **Step 6.1: Inspect existing intent-filters (note exact attributes used)**

```bash
cd ~/Downloads/taler_id_mobile && sed -n '60,90p' android/app/src/main/AndroidManifest.xml
```

This shows the exact format. Mirror it.

- [ ] **Step 6.2: Add two new `<intent-filter>` blocks**

Locate the existing prod intent-filters (the second one, for `/ui/invite`, ends with `</intent-filter>`). Right AFTER that closing tag, but BEFORE the next sibling element (likely `<intent-filter>` for `talerid://` scheme), insert:

```xml
        <intent-filter android:autoVerify="true">
            <action android:name="android.intent.action.VIEW" />
            <category android:name="android.intent.category.DEFAULT" />
            <category android:name="android.intent.category.BROWSABLE" />
            <data
                android:scheme="https"
                android:host="staging.id.taler.tirol"
                android:pathPrefix="/room/" />
        </intent-filter>
        <intent-filter android:autoVerify="true">
            <action android:name="android.intent.action.VIEW" />
            <category android:name="android.intent.category.DEFAULT" />
            <category android:name="android.intent.category.BROWSABLE" />
            <data
                android:scheme="https"
                android:host="staging.id.taler.tirol"
                android:pathPrefix="/ui/invite" />
        </intent-filter>
```

(The exact indentation depends on the existing file — match it.)

- [ ] **Step 6.3: Verify XML well-formed and Gradle sees it**

```bash
cd ~/Downloads/taler_id_mobile && python3 -c "import xml.etree.ElementTree as ET; ET.parse('android/app/src/main/AndroidManifest.xml'); print('OK')"
```

Expected: `OK`.

Then build to confirm Gradle parses:

```bash
cd ~/Downloads/taler_id_mobile && flutter build apk --flavor dev --debug --dart-define=FLAVOR=dev --dart-define=BASE_URL=https://staging.id.taler.tirol 2>&1 | tail -5
```

Expected: `BUILD SUCCESSFUL`.

- [ ] **Step 6.4: Commit**

```bash
cd ~/Downloads/taler_id_mobile
git add android/app/src/main/AndroidManifest.xml
git commit -m "feat(android/deeplink): add staging.id.taler.tirol intent-filters for /room and /ui/invite"
```

---

## Task 7: Mobile — push to `origin/dev`

- [ ] **Step 7.1: Rebase if needed and push**

```bash
cd ~/Downloads/taler_id_mobile
git fetch origin dev
git pull --rebase origin dev
flutter test 2>&1 | tail -2
git push origin dev
```

Expected: 447/447 still pass after rebase, push succeeds. If conflicts arise (none expected — entitlements/manifest are seldom edited): resolve via existing merge tool, document briefly.

---

## Task 8: Deploy backend to DEV server

This is a **controller** task — must be run with operator awareness (SSH session). Subagent OK if it has SSH agent forwarding.

- [ ] **Step 8.1: SSH + pull + build + restart**

```bash
ssh dvolkov@89.169.55.217 "cd ~/taler-id && git pull && npm install && npm run build && pm2 restart taler-id-dev"
```

Expected output near the end: `pm2 restart taler-id-dev` shows the process restarted successfully.

- [ ] **Step 8.2: Confirm process is online**

```bash
ssh dvolkov@89.169.55.217 "pm2 status taler-id-dev"
```

Expected: status `online`, no recent restart loops.

---

## Task 9: Server-side verification on DEV (staging)

- [ ] **Step 9.1: AASA via curl**

```bash
curl -I https://staging.id.taler.tirol/.well-known/apple-app-site-association
```

Expected:
- `HTTP/1.1 200 OK` (or `HTTP/2 200`)
- `Content-Type: application/json` (or `application/json; charset=utf-8`)
- NO `Location:` header (no redirect)

```bash
curl -s https://staging.id.taler.tirol/.well-known/apple-app-site-association | jq .
```

Expected: JSON body with both bundle IDs, paths `["/room/*", "/ui/invite*"]`.

- [ ] **Step 9.2: assetlinks.json via curl**

```bash
curl -I https://staging.id.taler.tirol/.well-known/assetlinks.json
curl -s https://staging.id.taler.tirol/.well-known/assetlinks.json | jq '.[].target.package_name'
```

Expected: 200, JSON content-type, output:
```
"tirol.taler.taler_id_mobile"
"tirol.taler.taler_id_mobile.dev"
```

- [ ] **Step 9.3: Apple validator (optional but recommended)**

Browser: <https://branch.io/resources/aasa-validator/?domain=staging.id.taler.tirol> — should show ✓ for `MG58MDUNZ2.tirol.taler.talerIdMobile.dev`.

- [ ] **Step 9.4: Android verification on test device `78c0742f`**

```bash
# Re-install dev APK so PackageManager re-checks app links
cd ~/Downloads/taler_id_mobile && flutter build apk --flavor dev --debug --dart-define=FLAVOR=dev --dart-define=BASE_URL=https://staging.id.taler.tirol 2>&1 | tail -3
~/Library/Android/sdk/platform-tools/adb -s 78c0742f install -r build/app/outputs/flutter-apk/app-dev-debug.apk

# Force re-verify and inspect
~/Library/Android/sdk/platform-tools/adb -s 78c0742f shell pm verify-app-links --re-verify tirol.taler.taler_id_mobile.dev
sleep 2
~/Library/Android/sdk/platform-tools/adb -s 78c0742f shell pm get-app-links tirol.taler.taler_id_mobile.dev
```

Expected output to include:
```
  staging.id.taler.tirol: verified
```

(`id.taler.tirol` may be `legacy_failure` since the dev package isn't registered for the prod domain — that's correct.)

- [ ] **Step 9.5: If any verification fails — STOP**

Common failures:
- AASA returns 404 → ServeStaticModule wildcard catching `.well-known/*` before our controller. Fix: ensure controller route is registered ahead of static serve, OR add `'/.well-known{/*path}'` to the existing `exclude` array of the `ServeStaticModule.forRoot({serveRoot: '/'})` block in `app.module.ts` (matching the existing pattern used for `/ui{/*path}` and `/uploads{/*path}`).
- AASA Content-Type wrong → check `@Header('Content-Type', 'application/json')` decorator was applied.
- assetlinks.json contains old single-object → file wasn't deployed; redo Task 8.
- Android `pm get-app-links` shows `none` instead of `verified` → assetlinks.json fingerprints wrong, or app needs uninstall+reinstall (DON'T just `install -r`, do `uninstall` then `install`).

Fix in a new commit, redeploy via Task 8, redo Task 9.

---

## Task 10: Deploy backend to PROD (USER-GATED)

⚠️ Do NOT execute without explicit user approval per CLAUDE.md "ВСЕГДА деплоить сначала на DEV".

- [ ] **Step 10.1: Confirm with user**

Ask: "DEV verified ✓. Deploy backend changes to PROD `138.124.61.221` now?"

If yes:

- [ ] **Step 10.2: SSH + pull + build + restart**

```bash
ssh dvolkov@138.124.61.221 "cd ~/taler-id && git pull && npm install && npm run build && pm2 restart taler-id"
```

- [ ] **Step 10.3: PM2 status check**

```bash
ssh dvolkov@138.124.61.221 "pm2 status taler-id"
```

Expected: `online`.

- [ ] **Step 10.4: Verify prod URLs**

```bash
curl -I https://id.taler.tirol/.well-known/apple-app-site-association
curl -s https://id.taler.tirol/.well-known/apple-app-site-association | jq .
curl -s https://id.taler.tirol/.well-known/assetlinks.json | jq '.[].target.package_name'
```

Same expectations as Task 9 but for prod domain.

---

## Task 11: Real-device tap test (USER)

This task is performed by the user. Mobile (Task 6) changes only affect FUTURE app installs — existing prod APK in production won't have `staging.id.taler.tirol` registered until rebuilt + reinstalled.

- [ ] **Step 11.1: Android (test device 78c0742f)**

1. Send yourself `https://staging.id.taler.tirol/room/test123` via Telegram or email.
2. Tap the link.
3. **Expected:** Taler ID Dev opens directly to the public-room join screen. NO "Open with…" chooser. NO Chrome.
4. (If Step 9.4 passed earlier and this fails — odd; gather `adb logcat -s ActivityTaskManager Tag:*` and report.)

- [ ] **Step 11.2: iOS (TestFlight build, separate session)**

iOS verification requires a NEW dev IPA with the staging entitlement. Build via:

```bash
cd ~/Downloads/taler_id_mobile && flutter build ipa --flavor dev -t lib/main_dev.dart --dart-define=FLAVOR=dev --dart-define=BASE_URL=https://staging.id.taler.tirol --export-options-plist ios/ExportOptions.plist
```

Then upload to TestFlight (existing CLAUDE.md command), install on iPhone, send yourself a `staging.id.taler.tirol/room/...` link, tap. Expected: app opens, Safari does not.

If Step 11 fails on a freshly installed APK with a verified state, re-check Step 9.4 output and the AASA file.

---

## Self-Review Checklist

After all tasks:

- [ ] All 5 implementation commits exist (3 backend on `main`, 2 mobile on `dev`).
- [ ] Backend deployed to DEV; DEV curl checks pass.
- [ ] Backend deployed to PROD (if user approved); PROD curl checks pass.
- [ ] Test suite still green: mobile 447/447, backend e2e (or unit fallback) PASS.
- [ ] Spec coverage: AASA controller ✓, dev fingerprints in assetlinks ✓, staging in iOS entitlements ✓, staging intent-filters in Android manifest ✓, e2e test ✓, real-device smoke step documented ✓.
- [ ] Out-of-scope honored: no Flutter logic changes, no nginx config edits, no new domain paths beyond `/room/*` and `/ui/invite*`.

---

## Out of Scope (per spec)

- Adding `/dashboard/user/...` or other paths to AASA/manifest
- OAuth callback path implementation
- Switching backend AASA from controller to host-aware variant
- Automated deploy via CI


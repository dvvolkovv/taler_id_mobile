# Deep Links: prod + staging coverage for `/room/*` and `/ui/invite*`

**Date:** 2026-04-28
**Status:** Approved
**Scope:** Backend (`~/taler-id/`), iOS entitlements, Android manifest, mobile flavor SHA-256. No new Flutter logic — `DeepLinkHandler` and `app_links` plugin already work.

## Summary

Make `https://id.taler.tirol/room/<id>`, `https://staging.id.taler.tirol/room/<id>`, and the corresponding `/ui/invite*` URLs open the Taler ID app (prod APK for `id.taler.tirol`, dev APK for `staging.id.taler.tirol`) without going through Safari / Chrome. Most plumbing is already in place — this design closes the gaps:

1. iOS — add Apple App Site Association (AASA) JSON file on the backend (currently missing → links open in Safari).
2. Android — add the dev-flavor SHA-256 cert fingerprint to `assetlinks.json` (currently only prod is registered).
3. Both platforms — extend coverage to the staging domain (currently only `id.taler.tirol` is registered).

## Current State (verified)

| Layer | Status |
|---|---|
| Flutter `DeepLinkHandler` + GoRouter route `/room/:code` | ✅ working — [deep_link_handler.dart:40-48](lib/core/router/deep_link_handler.dart#L40-L48), [app_router.dart:107-113](lib/core/router/app_router.dart#L107-L113) |
| Backend `GET/POST /voice/rooms/public/:code(/join,/join-auth)` | ✅ — `~/taler-id/src/voice/voice.controller.ts` |
| Web fallback `public/room.html` | ✅ |
| Android manifest `<intent-filter android:autoVerify="true">` for `id.taler.tirol` (`/room/*` + `/ui/invite`) | ✅ — [AndroidManifest.xml:66-78](android/app/src/main/AndroidManifest.xml#L66-L78) |
| Android assetlinks.json (prod fingerprint) | ✅ — `~/taler-id/public/.well-known/assetlinks.json` |
| iOS `applinks:id.taler.tirol` in Runner.entitlements | ✅ — [Runner.entitlements:7-10](ios/Runner/Runner.entitlements#L7-L10) |
| `app_links: ^6.3.4` Flutter plugin | ✅ — pubspec.yaml |
| **iOS apple-app-site-association on server** | ❌ **MISSING — root cause for iOS links going to Safari** |
| **Android dev-flavor fingerprint in assetlinks.json** | ❌ missing |
| **Staging domain coverage (entitlements / manifest / AASA / assetlinks)** | ❌ missing |

## Architecture (Approach 1: single AASA + assetlinks for both bundle IDs)

One `apple-app-site-association` file on the backend lists BOTH bundle IDs (prod + dev). One `assetlinks.json` lists BOTH packages (prod + dev). The same files are served by nginx on both servers. Apple/Google match against the calling app's bundle/package — wrong-flavor entries are silently ignored. The mobile app's *entitlement / manifest* declares which domains it answers for, so the prod APK ignores `staging.id.taler.tirol` (no entitlement), and the dev APK ignores `id.taler.tirol` (no entitlement). Per-domain isolation is enforced at the *mobile* layer, not the *server* layer.

**Why Approach 1, not host-aware NestJS endpoint:** existing assetlinks.json is already served as static from `~/taler-id/public/.well-known/`. Keeping the same mechanism is simpler than introducing a controller, and matches the project's existing static-file pattern.

## Components

### Backend repo (`~/taler-id/`)

#### 1.1 NEW: `public/.well-known/apple-app-site-association`

Plain text file (no `.json` extension), JSON content:

```json
{
  "applinks": {
    "apps": [],
    "details": [
      {
        "appID": "MG58MDUNZ2.tirol.taler.talerIdMobile",
        "paths": ["/room/*", "/ui/invite*"]
      },
      {
        "appID": "MG58MDUNZ2.tirol.taler.talerIdMobile.dev",
        "paths": ["/room/*", "/ui/invite*"]
      }
    ]
  }
}
```

Apple Team ID `MG58MDUNZ2` matches the existing iOS signing config.

#### 1.2 UPDATE: `public/.well-known/assetlinks.json`

Convert from single-object to array-of-objects (or extend existing array if already an array). Final shape:

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
        "<extracted during implementation from build/app/outputs/flutter-apk/app-dev-debug.apk via keytool>"
      ]
    }
  }
]
```

The dev fingerprint is obtained at implementation time via:
```bash
keytool -printcert -jarfile ~/Downloads/taler_id_mobile/build/app/outputs/flutter-apk/app-dev-debug.apk | grep -i "SHA256:" | head -1
```

The dev APK from Task B is already on disk and uses the project's debug keystore.

#### 1.3 Verify NestJS static-asset config

Confirm `~/taler-id/src/main.ts` serves the `public/` directory under `/.well-known/` (current state suggests yes — the existing `assetlinks.json` resolves). If not, add `app.useStaticAssets(...)` or explicit static-mount.

### Mobile repo (`~/Downloads/taler_id_mobile/`)

#### 2.1 UPDATE: `ios/Runner/Runner.entitlements`

Inside the `<array>` for `com.apple.developer.associated-domains`, ADD one line after the existing `applinks:id.taler.tirol`:

```xml
<string>applinks:staging.id.taler.tirol</string>
```

#### 2.2 UPDATE: `android/app/src/main/AndroidManifest.xml`

Inside the same `<activity android:name=".MainActivity">` block as the existing intent-filters for `id.taler.tirol`, ADD two new `<intent-filter>` elements for the staging host (mirror the existing prod filters exactly, only changing `android:host`):

```xml
<intent-filter android:autoVerify="true">
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data android:scheme="https"
          android:host="staging.id.taler.tirol"
          android:pathPrefix="/room/" />
</intent-filter>
<intent-filter android:autoVerify="true">
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data android:scheme="https"
          android:host="staging.id.taler.tirol"
          android:pathPrefix="/ui/invite" />
</intent-filter>
```

## Data Flow

```
[user taps https://id.taler.tirol/room/abc123 in any app]
        │
        ├─ iOS: Apple CDN fetches https://id.taler.tirol/.well-known/apple-app-site-association
        │       (cached on first install / app update, validated against bundle ID).
        │       ✓ matches prod app → app receives NSUserActivity → app_links plugin
        │       → DeepLinkHandler._handleUri() → router.go('/dashboard/voice?publicCode=abc123')
        │       → VoiceCallScreen joins room as guest via POST /voice/rooms/public/abc123/join
        │
        └─ Android: PackageManager fetches https://id.taler.tirol/.well-known/assetlinks.json
                    on app install / update, verifies SHA-256.
                    ✓ matches prod app → ACTION_VIEW intent fires → app_links plugin → same Flutter flow
```

If the user has only the dev APK installed, `id.taler.tirol` opens in browser (no entitlement match) and falls back to `room.html`. Conversely a prod APK ignores `staging.id.taler.tirol`.

## Edge Cases

- **AASA Content-Type:** must be `application/json` (or any 2xx response with valid JSON). Apple no longer requires the `application/pkcs7-mime` MIME from older docs. **Verification step in plan: `curl -I` and inspect.**
- **AASA redirects:** Apple WILL NOT follow HTTP redirects from the AASA path. If nginx redirects e.g. `https://id.taler.tirol/.well-known/apple-app-site-association` to `https://www.id.taler.tirol/...`, the validation fails. **Verify with `curl -I -L`.**
- **Apple cache:** AASA is fetched ONLY on app install / app update on iOS (and ~once per week thereafter). Mid-test, force re-fetch by deleting & reinstalling the app.
- **Android verify state:** can be `unverified`, `verified`, `failed`. Check via `adb shell pm get-app-links <package>`. Re-trigger via `adb shell pm verify-app-links --re-verify <package>`.
- **`/ui/invite*` glob vs Android `pathPrefix`:** iOS AASA uses `/ui/invite*` (glob); Android intent-filter uses `pathPrefix="/ui/invite"` (matches anything starting with that string). Equivalent for current usage.
- **Wrong-flavor entries in shared file:** prod APK seeing the dev bundle ID in AASA does not grant it dev-domain handling — entitlements gate that. No security or behavioral leak.
- **`talerid://` custom scheme** (existing for OAuth callback, contacts, etc.): unaffected. This change only touches HTTPS link handling.

## Testing

### 1. Server-side validation (after backend deploy)

```bash
# Both must return 200 + JSON body, NO redirect, valid certificate.
curl -I https://id.taler.tirol/.well-known/apple-app-site-association
curl -I https://staging.id.taler.tirol/.well-known/apple-app-site-association
curl -I https://id.taler.tirol/.well-known/assetlinks.json
curl -I https://staging.id.taler.tirol/.well-known/assetlinks.json

# Bodies parseable as JSON:
curl -s https://id.taler.tirol/.well-known/apple-app-site-association | jq .
curl -s https://staging.id.taler.tirol/.well-known/assetlinks.json | jq .
```

Apple's validator (manual): https://branch.io/resources/aasa-validator/?domain=id.taler.tirol

### 2. Android verification (post-install)

```bash
# Re-trigger verification on the test device:
adb shell pm verify-app-links --re-verify tirol.taler.taler_id_mobile.dev

# Confirm verification state:
adb shell pm get-app-links tirol.taler.taler_id_mobile.dev
# Expected output includes:
#   id.taler.tirol: verified  (or unverified if prod-only deploy)
#   staging.id.taler.tirol: verified
```

### 3. End-to-end smoke (manual on real devices)

iOS:
1. Reinstall dev IPA on iPhone.
2. Compose a message in iMessage / Notes containing `https://staging.id.taler.tirol/room/test123`.
3. Tap the link.
4. **Expected:** Taler ID Dev opens directly to the public-room join screen with `publicCode=test123`. No Safari prompt.
5. Repeat with prod IPA + `https://id.taler.tirol/room/test123`.

Android:
1. Reinstall dev APK on `78c0742f`.
2. From a different app (Telegram / Slack / etc.) tap a `staging.id.taler.tirol/room/...` link.
3. **Expected:** Taler ID Dev opens directly. No "Open with…" chooser.
4. Repeat with prod APK + `id.taler.tirol/room/...`.

### 4. Existing test suite

`flutter test` must remain at 447/447. No Dart code changes here, so no new unit tests needed. The route handler is already covered by `DeepLinkHandler` (existing).

## Branch & Commit

Two repos involved:

- **Mobile** (`~/Downloads/taler_id_mobile/`): branch `dev`. Two commits:
  1. `feat(ios): add applinks:staging.id.taler.tirol to associated domains`
  2. `feat(android): add staging.id.taler.tirol intent-filters for /room and /ui/invite`

- **Backend** (`~/taler-id/`): branch `main` (verified — backend repo's default branch). Two commits:
  1. `feat(deeplink): add apple-app-site-association for prod + dev bundles`
  2. `feat(deeplink): add dev-flavor fingerprint to assetlinks.json`

**Deploy order (per CLAUDE.md DEV-first rule):**
1. Push backend → DEV server (`89.169.55.217`) → smoke staging deep link on dev APK.
2. Push backend → PROD server (`138.124.61.221`) → smoke prod deep link on prod APK (only after explicit user approval per CLAUDE.md).
3. Push mobile changes → build dev APK → install → verify Android `pm get-app-links`.
4. Test iOS only when prod IPA / TestFlight build is available with the new entitlement (separate user action).

## Out of Scope

- New paths beyond `/room/*` and `/ui/invite*` (e.g. `/dashboard/user/...`, `/oidc/authorize`) — separate iteration.
- Changes to `DeepLinkHandler.dart` — already correctly maps both URL forms.
- OAuth callback path implementation (stubbed at deep_link_handler.dart:60-69) — separate task.
- Switching from static `.well-known` files to a NestJS controller — current static approach is sufficient.
- Deploy automation — done manually per CLAUDE.md SSH commands.

## References

- [Existing Android intent-filters (id.taler.tirol)](android/app/src/main/AndroidManifest.xml#L66-L78)
- [Existing iOS associated-domains entitlement](ios/Runner/Runner.entitlements#L7-L10)
- [Existing DeepLinkHandler](lib/core/router/deep_link_handler.dart)
- [Existing GoRouter `/room/:code` route](lib/core/router/app_router.dart#L107-L113)
- [Backend voice public-join controller](https://github.com/dvvolkovv/taler_id) — `src/voice/voice.controller.ts:72-84`
- Apple docs: <https://developer.apple.com/documentation/xcode/supporting-associated-domains>
- Android docs: <https://developer.android.com/training/app-links/verify-android-applinks>

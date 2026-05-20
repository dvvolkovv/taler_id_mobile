# Taler ID Agent Shell — Phase 1C: Gmail (OAuth + read/send/reply) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `superpowers:subagent-driven-development` (recommended) or `superpowers:executing-plans` to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

- **Date:** 2026-05-20
- **Branch (mobile):** `feature/agent-shell-phase-1c-gmail` off `feature/agent-shell-phase-1a-notifications`
- **Depends on:** Phase 0 (closed 2026-05-20) and Phase 1A (code-complete 2026-05-20 — voice tool registration + dispatcher pattern in `assistant_screen.dart`, DI conventions in `service_locator.dart`, `flavor=dev` build pipeline, real-device smoke loop on Xiaomi 2211133G).
- **Backend changes:** **none.** OAuth runs entirely on-device. Tokens never leave the phone. The NestJS backend on DEV (`89.169.55.217`) is not touched.
- **Spec reference:** `docs/superpowers/specs/2026-05-18-taler-agent-shell-design.md`
- **Plan style reference:** `docs/superpowers/plans/2026-05-20-agent-shell-phase-1a-notification-listener.md` (match its task/step shape, TDD discipline, one commit per task).

**Goal:** Give the OpenAI Realtime voice loop five on-device Gmail tools backed by a real Gmail API client authenticated via OAuth 2.0 with PKCE (RFC 8252). After Phase 1C, Дмитрий can ask out loud "что нового в почте?", "прочитай последнее письмо от Сергея", "отправь Маше письмо что встреча в 18:00", or "ответь на это письмо что согласен" — and the agent will list, read, compose, and send via Gmail without opening the Gmail app. Sends/replies require explicit voice confirmation (the model reads back the draft, waits for "да", only then fires the API).

This phase is voice-only by design — like Phase 1A, the Gmail tools are registered ONLY in the OpenAI Realtime path in `assistant_screen.dart`, NOT in the text Agent Shell (`/agent/run` backend has no access to phone-resident OAuth tokens and we are not building a backend mail relay).

---

## Goals

1. **OAuth 2.0 with PKCE** against Google for a single user account (`dvvolkovv@gmail.com`), using `flutter_appauth` for the authorisation-code dance and `flutter_secure_storage` for refresh token persistence. No client secret (Android-type OAuth client).
2. **Five voice tools** registered alongside `messenger_read_recent` / `messenger_reply` in `assistant_screen.dart` (append after Phase 1A entries at line ~822 in the `tools: [...]` array; append dispatcher arms after the existing `messenger_reply` branch at line ~2406):
   - `gmail_list_recent(query?, limit?)` — slim list of threads.
   - `gmail_read(message_id)` — full body, plain text preferred, HTML stripped.
   - `gmail_send(to, subject, body, cc?, bcc?, confirmed?)` — compose & send NEW message, two-step confirmation.
   - `gmail_reply(thread_id, body, confirmed?)` — reply in thread, two-step confirmation.
   - `gmail_search(query, limit?)` — Gmail search syntax (`from:`, `subject:`, `has:attachment`, `before:`, etc.).
3. **Send confirmation state machine in the tool itself.** When `confirmed: false` (default), `gmail_send` / `gmail_reply` return the rendered draft envelope (`to`, `subject`, `body_preview`) without contacting the API and include a hint that the agent must read it back and obtain explicit verbal "да" before re-invoking with `confirmed: true`. The agent dispatch layer carries no session state — confirmation is a property of the JSON payload from the model.
4. **Body length cap for voice.** If a fetched email body exceeds 2000 characters, the tool returns the first 2000 characters plus `truncated: true`. The agent can either summarise or offer to "read full".
5. **HTML stripping for read.** Plain-text MIME part preferred; if none, fall back to HTML and strip to plain text via the `html` package (text node accumulation). No table rendering — voice cannot read tables anyway.
6. **Attachment surfacing without download.** `gmail_list_recent` / `gmail_read` / `gmail_search` surface `has_attachments: true` and the attachment count + filenames; downloads are deferred to a later phase.
7. **First-call OAuth bootstrap.** When the first `gmail_*` tool runs and no refresh token exists, the dispatcher triggers the `flutter_appauth` browser flow synchronously. If the user has not already granted consent, the tool returns `error: oauth_pending` and the agent says (Russian) `"Чтобы я мог работать с почтой, открой согласие Google в браузере и подтверди, потом скажи мне 'готово'"`. Subsequent calls refresh access tokens silently.
8. **Update the system prompt** (RU + EN blocks at line ~437–550) so the model knows when to use Gmail tools, how to confirm, and that `messenger_read_recent` notifications and `gmail_*` are different sources (notification is "you have new mail", `gmail_*` is the real client).

## Non-goals

- **Multi-account.** Single Google account only for v1. The token store is keyed by a fixed `account_id = "primary"`.
- **Calendar integration.** Google Calendar is **Phase 4** in the master spec and gets its own plan; OAuth scope plumbing here does NOT include calendar scopes.
- **Labels management.** Reading labels OK (we surface them in metadata); creating / removing labels — out of scope.
- **Drafts.** No `users.drafts.create` / `.update` / `.send`. Send goes straight to `users.messages.send` after voice confirmation.
- **Search filters beyond Gmail query syntax.** The `query` field is forwarded verbatim to Gmail (`q=...`); we do not invent a higher-level filter language.
- **Attachment download / upload.** Surface only — no `attachments.get`. Send with attachments — explicitly out of scope.
- **Threaded conversation rendering.** `gmail_read(message_id)` returns one message; agent can call `gmail_list_recent` with the thread filter if it wants more.
- **iOS.** Same Phase 1A reasoning — agent shell is Android-only.
- **Push (Gmail Pub/Sub watch / FCM).** Phase 1A notifications already deliver "new mail arrived" via the OS notification stream. We do not subscribe to Gmail's push API in this phase.
- **Backend changes.** Nothing on `89.169.55.217` or `staging.id.taler.tirol` changes.
- **Encrypted / signed mail (S/MIME, PGP).** Out of scope; rare in Дмитрий's mailbox.
- **HTML reply composition.** Sends and replies are `text/plain` only (Content-Type explicit). Gmail will render them correctly.

---

## Architecture overview

### One-page picture

```
┌─────────────────────────────────────────────────────────────────────┐
│ OpenAI Realtime voice loop (assistant_screen.dart)                   │
│                                                                       │
│   _handleFunctionCall(callId, name, args):                            │
│     ... messenger_read_recent / messenger_reply ...                   │
│     else if name == 'gmail_list_recent'  → GmailClient.listRecent     │
│     else if name == 'gmail_read'         → GmailClient.read           │
│     else if name == 'gmail_send'         → confirm gate → send       │
│     else if name == 'gmail_reply'        → confirm gate → reply      │
│     else if name == 'gmail_search'       → GmailClient.search         │
└───────────────────────┬─────────────────────────────────────────────┘
                        ▼
┌─────────────────────────────────────────────────────────────────────┐
│ Confirm gate (inline in dispatcher)                                  │
│                                                                       │
│   If gmail_send / gmail_reply called with confirmed != true:          │
│     - validate fields (recipient looks like email, body non-empty)    │
│     - return JSON {                                                   │
│         needs_confirmation: true,                                     │
│         draft: { to, subject, body_preview (first 200 chars) },       │
│         hint: "Прочитай вслух адресату, тему, тело. Спроси 'да?'.    │
│                Когда пользователь скажет 'да' — вызови ещё раз с      │
│                confirmed: true и теми же параметрами."                │
│       }                                                               │
│   Else (confirmed == true):                                           │
│     - GmailClient.send / reply                                        │
└───────────────────────┬─────────────────────────────────────────────┘
                        ▼
┌─────────────────────────────────────────────────────────────────────┐
│ GmailClient (lib/features/gmail/services/gmail_client.dart)          │
│                                                                       │
│   - thin typed wrapper over googleapis gmail.v1.GmailApi              │
│   - .listRecent(query, limit)                                         │
│   - .read(messageId)                                                  │
│   - .send(to, subject, body, cc, bcc)         (RFC 2822 build)        │
│   - .reply(threadId, body)         (subject + In-Reply-To, References)│
│   - .search(query, limit)                                             │
│                                                                       │
│   - acquires AuthClient from GmailAuthService.client() each call      │
│   - converts payload tree → plain-text body (preferred) or            │
│     HTML-stripped fallback; caps at 2000 chars; sets truncated flag   │
└───────────────────────┬─────────────────────────────────────────────┘
                        ▼ AuthClient (oauth2 from googleapis_auth)
┌─────────────────────────────────────────────────────────────────────┐
│ GmailAuthService (lib/features/gmail/services/gmail_auth_service.dart)│
│                                                                       │
│   - flutter_appauth-based OAuth code+PKCE                             │
│   - .ensureRefreshToken() → triggers browser tab if absent            │
│   - .accessToken()        → refreshes if expired; caches in memory    │
│   - .client()             → AuthClient for googleapis                 │
│   - .signOut()            → wipes secure storage                      │
│                                                                       │
│   Secure storage layout (flutter_secure_storage, AES on               │
│   EncryptedSharedPreferences on Android):                             │
│     key: gmail.primary.refresh_token  →  string                       │
│     key: gmail.primary.access_token   →  string                       │
│     key: gmail.primary.expires_at_ms  →  string (epoch ms)            │
│     key: gmail.primary.scope          →  string (granted scopes)      │
│     key: gmail.primary.account_email  →  string ("dvvolkovv@…")       │
└───────────────────────┬─────────────────────────────────────────────┘
                        ▼
┌─────────────────────────────────────────────────────────────────────┐
│ Google OAuth endpoints + Gmail API                                   │
│   - https://accounts.google.com/o/oauth2/v2/auth   (consent)          │
│   - https://oauth2.googleapis.com/token            (exchange/refresh) │
│   - https://gmail.googleapis.com/gmail/v1/users/me/...                │
│                                                                       │
│   Redirect URI (custom scheme, RFC 8252 §7.1):                        │
│     tirol.taler.taler_id_mobile.dev:/oauth2redirect                   │
└─────────────────────────────────────────────────────────────────────┘
```

### Why `flutter_appauth` (not `google_sign_in`)

- `google_sign_in` is convenient but assumes Google Play Services and gives us a Google ID token + an opaque access token *without* a refresh token on Android — we'd have to re-prompt every hour.
- `flutter_appauth` (RFC 8252 / AppAuth) does the proper authorisation-code-with-PKCE dance using a Custom Tabs / browser intent, exchanges the code for an access + refresh token at the token endpoint, and gives us full control over scopes and refresh.
- We want refresh tokens (they survive forever or until revoked), explicit Gmail scopes (no Drive, no Photos, no Contacts), and the option to use `prompt=consent access_type=offline` to guarantee a refresh token is returned the first time. `flutter_appauth` lets us pass these parameters; `google_sign_in` does not.
- Trade-off accepted: `flutter_appauth` needs an Activity in `AndroidManifest.xml` with an `<intent-filter>` for our custom redirect scheme. Adds a few lines of manifest config.

### Why `googleapis` (not hand-rolled REST)

- `googleapis` ships a typed Dart client for `gmail/v1`. We get `gmail.users.messages.list`, `.get`, `.send`, `.modify` with strongly-typed request/response models — no manual JSON wrangling for `payload.parts[*].body.data` walks (the part tree is gnarly).
- Bundle-size impact (~1.6 MB of the package; treeshake brings the actual compiled cost well below that, but it is non-trivial). Acceptable: Дмитрий's APK already includes WebRTC, MLKit selfie segmentation, and Hive — Gmail will not be the dominant chunk.
- Alternative considered: hand-rolled Dio calls (smaller binary, more code, more bugs in MIME parsing). Rejected.
- We use `googleapis_auth` only for its `AuthClient` adapter that wires our refresh-aware token source into the `googleapis` HTTP layer. We do NOT use `googleapis_auth`'s own `clientViaUserConsent` (that one opens a localhost loopback, which is the *other* RFC 8252 flow, not great on Android).

### OAuth dance flow (first call)

```
user voice: "что у меня в почте?"
  └─ assistant: gmail_list_recent({}) called
     └─ dispatcher: sl<GmailAuthService>().client() throws GmailAuthRequired
        └─ dispatcher returns {error: 'oauth_pending', hint: 'Открой согласие Google'}
           └─ agent says (RU): "Открываю окно согласия Google, подтверди доступ и
                                скажи 'готово'."
              └─ dispatcher calls sl<GmailAuthService>().beginInteractiveSignIn()
                 └─ flutter_appauth opens Chrome Custom Tab → accounts.google.com
                    → user picks dvvolkovv@gmail.com → grants gmail.modify scope
                    → Google redirects to
                      tirol.taler.taler_id_mobile.dev:/oauth2redirect?code=...
                    → Android resolves the custom scheme → returns to app
                    → flutter_appauth exchanges code → access_token + refresh_token
                    → stored in flutter_secure_storage
                 ← future user voice: "готово, прочитай почту"
                    → gmail_list_recent retried → succeeds
```

### Token refresh

`googleapis_auth.AccessCredentials` exposes `expiry`. We refresh ~60 s before expiry:

```
fun accessToken():
  if creds.expiry - now > 60s: return creds.accessToken
  newCreds = refreshCredentials(client, creds, clientId)
  persist(newCreds)
  return newCreds.accessToken
```

We use `googleapis_auth.refreshCredentials(http.Client(), credentials, clientId)`. This handles 401 from the refresh endpoint correctly; on revoke we wipe storage and surface `GmailAuthRequired` to trigger a fresh interactive flow.

### Send confirmation state machine — fully model-side

Why no Dart state: voice-LLM dialogues do not have a clean "pending action" hook in the OpenAI Realtime API tool layer. Carrying state in Dart between tool calls would require correlating call IDs and risks divergence if the model retries or rephrases. Putting state in the JSON payload (`confirmed: bool`) keeps the agent always in charge and lets the same tool be invoked twice for the same draft with identical args, the second time with one bit flipped.

```
gmail_send(to=..., subject=..., body=..., confirmed=false)   ← model first call
  → tool returns: { needs_confirmation: true,
                    draft: { to, subject, body_preview, body_full_chars } }
  → agent voices: "Отправлю в адрес dvvolkovv@gmail.com, тема "Встреча",
                   текст: «Подтверждаю встречу в 18:00». Подтверди?"
  → user: "да"
  → model calls gmail_send(to=..., subject=..., body=..., confirmed=true)
  → tool: GmailClient.send(...)
  → tool returns: { ok: true, message_id: "18a..." }
  → agent voices: "Отправлено."
```

The required field validation runs in both calls; missing `to` or `body` returns `error: invalid_draft` so the agent never reaches confirmation with broken data.

---

## Prerequisites — user actions (Google Cloud Console)

Дмитрий, you must complete the following **before Task 2** can be executed. The implementer subagent cannot do these — they require your Google identity.

1. **Open Google Cloud Console.** https://console.cloud.google.com
2. **Create or reuse a project.** A new project named `taler-id-mobile` is fine, or pick an existing one. Pick the project; copy the project ID.
3. **Enable the Gmail API.** APIs & Services → Library → search "Gmail API" → Enable.
4. **Configure the OAuth consent screen.**
   - User type: **External** (Internal is only for Workspace orgs; your `gmail.com` account is consumer).
   - App name: `Taler ID Agent Shell`.
   - User support email: `dvvolkovv@gmail.com`.
   - Developer contact: `dvvolkovv@gmail.com`.
   - Authorised scopes: **add `https://www.googleapis.com/auth/gmail.modify`** (covers read + send + reply + modify; narrower than `gmail.full` but enough for our five tools). If you would rather follow least-privilege, add the pair `https://www.googleapis.com/auth/gmail.readonly` + `https://www.googleapis.com/auth/gmail.send` instead. The implementer plan uses `gmail.modify` by default — if you choose the pair, tell the implementer in Task 2 so the constant in `gmail_auth_service.dart` is set to the right scope list.
   - Test users: add **`dvvolkovv@gmail.com`** (and any secondary Google account you might want to test with). Without this you will see "Access blocked: has not completed the verification process" on the consent screen.
   - **Do not** submit for verification — staying in test mode is fine, because (a) the only user is you and (b) verification takes weeks and is not needed for a personal daily-driver.
5. **Create the OAuth 2.0 Client ID.**
   - APIs & Services → Credentials → Create Credentials → OAuth client ID.
   - Application type: **Android**.
   - Name: `Taler ID Dev Android`.
   - Package name: **`tirol.taler.taler_id_mobile.dev`** (this matches the dev flavor applicationId in `android/app/build.gradle.kts` line 35; the prod flavor uses `tirol.taler.taler_id_mobile` without the suffix).
   - SHA-1 certificate fingerprint: get it via the command in step 6.
6. **Extract the SHA-1 of the signing key.** The dev release flavor currently signs with the **debug keystore** (`android/app/build.gradle.kts` line 48: `signingConfig = signingConfigs.getByName("debug")`). The debug keystore lives at `~/.android/debug.keystore` with password `android` and alias `androiddebugkey`.

   Run on the Mac where you build the dev APK:

   ```bash
   keytool -list -v -keystore ~/.android/debug.keystore \
           -alias androiddebugkey -storepass android -keypass android \
   | grep -A1 "SHA1:"
   ```

   Expected output line: `SHA1: AA:BB:CC:DD:EE:...:99` (40 hex pairs).
   Copy that string verbatim — including colons — into the Google Cloud Console field.

   > **Note:** If you ever switch the dev flavor to a real release keystore (e.g. for Play upload), you must register that keystore's SHA-1 as an additional fingerprint on the same OAuth client, or create a separate `prod` OAuth client. Two fingerprints are fine on one client.

7. **Redirect URI — custom scheme.** Android-type OAuth clients in Google Cloud Console **do not have a redirect URI field in the UI**; Google derives it from the package name. The implementer must configure `flutter_appauth` to use the redirect:

   ```
   tirol.taler.taler_id_mobile.dev:/oauth2redirect
   ```

   (Note the colon-slash, not double slash — RFC 8252 §7.1 private-use URI scheme.) The Android `AndroidManifest.xml` must declare an `<intent-filter>` for this scheme on the `com.linusu.flutter_web_auth_2.CallbackActivity` or the `net.openid.appauth.RedirectUriReceiverActivity` — Task 2 covers the exact entry.

8. **Save the Client ID.** Format `123456789012-abcdefghij....apps.googleusercontent.com`. There is **no client secret** for Android-type clients — that is by design (RFC 8252 §8.5). Hand this Client ID to the implementer; it goes into a `--dart-define=GOOGLE_OAUTH_CLIENT_ID=...` at build time, NOT committed to the repo.

9. **Sanity-check the consent flow once manually.** From the consent screen page in the cloud console, click "Publish app" → keep in "Testing" mode. Verify `dvvolkovv@gmail.com` is listed under "Test users". Then proceed to Task 2.

> **Risk if skipped:** Task 8 (E2E smoke) will fail with `Access blocked: Authorisation Error` and the implementer will not be able to complete the phase.

---

## Task list

### Task 1: Branch + plan commit

**Files:**
- No code yet.

- [ ] **Step 1.1** Branch off Phase 1A (which carries the messenger tooling Phase 1C builds on):
  ```bash
  cd /Users/dmitry/Downloads/taler_id_mobile
  git checkout feature/agent-shell-phase-1a-notifications
  git pull
  git checkout -b feature/agent-shell-phase-1c-gmail
  git push -u origin feature/agent-shell-phase-1c-gmail
  ```
- [ ] **Step 1.2** Add `docs/superpowers/plans/2026-05-20-agent-shell-phase-1c-gmail.md` (this file). Commit:
  ```bash
  git add docs/superpowers/plans/2026-05-20-agent-shell-phase-1c-gmail.md
  git commit -m "docs(agent-shell): Phase 1C plan — Gmail OAuth + read/send/reply"
  ```

**Acceptance:** branch pushed; plan file on remote.
**Tests:** none.
**Time:** ~20 min.
**Depends on:** Phase 1A merged into its branch (current state on 2026-05-20).

---

### Task 2: pubspec deps + Android URL scheme manifest + dart-define plumbing

**Files:**
- Modify: `/Users/dmitry/Downloads/taler_id_mobile/pubspec.yaml`
- Modify: `/Users/dmitry/Downloads/taler_id_mobile/android/app/src/main/AndroidManifest.xml`
- Modify: `/Users/dmitry/Downloads/taler_id_mobile/android/app/build.gradle.kts`
- Create: `/Users/dmitry/Downloads/taler_id_mobile/lib/features/gmail/gmail_config.dart`

- [ ] **Step 2.1** Add to `pubspec.yaml` under `dependencies:` (just below the existing `flutter_secure_storage: ^9.2.4`):
  ```yaml
  flutter_appauth: ^7.0.1          # OAuth 2.0 PKCE — RFC 8252
  googleapis: ^13.2.0              # typed gmail.v1.GmailApi
  googleapis_auth: ^1.6.0          # AuthClient + refreshCredentials
  html: ^0.15.5                    # parser for HTML→plain-text stripping
  # flutter_secure_storage is already in (line 30).
  ```

  Run:
  ```bash
  flutter pub get
  ```

- [ ] **Step 2.2** In `android/app/src/main/AndroidManifest.xml`, register the redirect-URI receiver. `flutter_appauth` ships its own `RedirectUriReceiverActivity` from `net.openid.appauth`; we need to declare it with our custom scheme. Add inside `<application>` (next to the new notification listener block from Phase 1A):

  ```xml
  <!-- Phase 1C: OAuth redirect receiver for Gmail (flutter_appauth / AppAuth) -->
  <activity
      android:name="net.openid.appauth.RedirectUriReceiverActivity"
      android:exported="true">
      <intent-filter>
          <action android:name="android.intent.action.VIEW" />
          <category android:name="android.intent.category.DEFAULT" />
          <category android:name="android.intent.category.BROWSABLE" />
          <data android:scheme="tirol.taler.taler_id_mobile.dev"
                android:path="/oauth2redirect" />
      </intent-filter>
  </activity>
  ```

  Note: `flutter_appauth` 7.x merges its own manifest fragment with `appAuthRedirectScheme` set via `manifestPlaceholders`. We prefer the explicit `<activity>` declaration above because we have two flavors (dev vs prod) with different applicationIds and we want to make the scheme explicit per build later (prod will get a separate consent screen). If you take the manifestPlaceholders route instead, set in `android/app/build.gradle.kts` under `defaultConfig`:

  ```kotlin
  manifestPlaceholders["appAuthRedirectScheme"] = "tirol.taler.taler_id_mobile.dev"
  ```

  Pick one approach (explicit `<activity>` recommended) and stick with it.

- [ ] **Step 2.3** In `android/app/build.gradle.kts`, ensure the dev flavor exposes the OAuth Client ID via `buildConfigField` if desired, OR (simpler) pass it via Flutter's `--dart-define` at build time. Default to dart-define. Document in Step 2.5.

- [ ] **Step 2.4** Create `lib/features/gmail/gmail_config.dart`:

  ```dart
  /// Phase 1C — Gmail OAuth + API configuration.
  /// Client ID is injected at build time via --dart-define=GOOGLE_OAUTH_CLIENT_ID=...
  /// to avoid committing it to git. The dev OAuth client is registered against
  /// applicationId tirol.taler.taler_id_mobile.dev and the debug-keystore SHA-1.
  class GmailConfig {
    static const String clientId = String.fromEnvironment(
      'GOOGLE_OAUTH_CLIENT_ID',
      defaultValue: '',
    );

    /// RFC 8252 §7.1 private-use URI scheme redirect.
    static const String redirectUrl =
        'tirol.taler.taler_id_mobile.dev:/oauth2redirect';

    /// Single scope that grants read + send + modify + reply.
    /// If you prefer least-privilege, swap for the pair:
    ///   'https://www.googleapis.com/auth/gmail.readonly',
    ///   'https://www.googleapis.com/auth/gmail.send'.
    static const List<String> scopes = [
      'https://www.googleapis.com/auth/gmail.modify',
    ];

    static const String issuer = 'https://accounts.google.com';

    /// Secure-storage keys (account_id is always 'primary' in v1).
    static const String kRefreshToken = 'gmail.primary.refresh_token';
    static const String kAccessToken = 'gmail.primary.access_token';
    static const String kExpiresAtMs = 'gmail.primary.expires_at_ms';
    static const String kScope = 'gmail.primary.scope';
    static const String kAccountEmail = 'gmail.primary.account_email';
  }
  ```

- [ ] **Step 2.5** Build sanity (with a placeholder client id so dart-define resolves):
  ```bash
  cd /Users/dmitry/Downloads/taler_id_mobile
  flutter build apk --flavor dev --debug -t lib/main_dev.dart \
       --dart-define=FLAVOR=dev \
       --dart-define=GOOGLE_OAUTH_CLIENT_ID=PLACEHOLDER.apps.googleusercontent.com
  ```
  Expected: clean build, no manifest merger error.

- [ ] **Step 2.6** Commit:
  ```bash
  git add pubspec.yaml pubspec.lock android/app/src/main/AndroidManifest.xml \
          android/app/build.gradle.kts lib/features/gmail/gmail_config.dart
  git commit -m "feat(gmail): add OAuth deps + redirect manifest entry + config scaffold"
  ```

**Acceptance:** APK builds dev flavor with the new deps; manifest merger shows `RedirectUriReceiverActivity` with our scheme; `GmailConfig.clientId` is read from `--dart-define`.
**Tests:** none (no logic yet).
**Time:** 1 h.
**Depends on:** Task 1 + prerequisites complete (Дмитрий's OAuth client ID available).

---

### Task 3: `GmailAuthService` — OAuth flow + token storage + refresh + tests (TDD)

**Files:**
- Create: `/Users/dmitry/Downloads/taler_id_mobile/lib/features/gmail/services/gmail_auth_service.dart`
- Create: `/Users/dmitry/Downloads/taler_id_mobile/lib/features/gmail/services/gmail_auth_exceptions.dart`
- Create: `/Users/dmitry/Downloads/taler_id_mobile/test/features/gmail/services/gmail_auth_service_test.dart`

- [ ] **Step 3.1** Define the exception types in `gmail_auth_exceptions.dart`:
  ```dart
  class GmailAuthRequired implements Exception {
    final String hint;
    GmailAuthRequired([this.hint = 'no refresh token']);
    @override String toString() => 'GmailAuthRequired($hint)';
  }
  class GmailAuthDenied implements Exception {
    final String reason;
    GmailAuthDenied(this.reason);
  }
  class GmailAuthNetwork implements Exception {
    final Object cause;
    GmailAuthNetwork(this.cause);
  }
  ```

- [ ] **Step 3.2** Sketch the service surface — `gmail_auth_service.dart`:
  ```dart
  abstract class GmailAuthService {
    /// True if we have a refresh token; does NOT validate access token freshness.
    Future<bool> isSignedIn();

    /// Open browser → consent → exchange code → persist refresh+access tokens.
    /// Throws GmailAuthDenied if user cancels; GmailAuthNetwork on network failure.
    Future<void> beginInteractiveSignIn();

    /// Get a valid access token. Refreshes if expired.
    /// Throws GmailAuthRequired if no refresh token (caller must beginInteractiveSignIn).
    Future<String> accessToken();

    /// Return an `AuthClient` for googleapis. Calls accessToken() internally.
    Future<auth.AuthClient> client();

    /// Wipe stored tokens. Does NOT call Google's revoke endpoint (v1).
    Future<void> signOut();

    /// The email address recorded at the last successful sign-in (for UX).
    Future<String?> accountEmail();
  }
  ```

  Implementation `AppAuthGmailAuthService implements GmailAuthService`:
  - Constructor takes `FlutterSecureStorage storage`, `FlutterAppAuth appAuth`.
  - `beginInteractiveSignIn` calls `appAuth.authorizeAndExchangeCode(AuthorizationTokenRequest(clientId, redirectUrl, issuer: ..., scopes: GmailConfig.scopes, promptValues: ['consent'], additionalParameters: {'access_type': 'offline'}))`. `prompt=consent` + `access_type=offline` guarantee a refresh token returned even if the user has previously consented for this client.
  - After exchange: parse `idToken` to extract `email` (or call `https://gmail.googleapis.com/gmail/v1/users/me/profile` once); persist all five keys.
  - `accessToken()`: load `expiresAtMs`; if `> now + 60s`, return cached. Otherwise call `appAuth.token(TokenRequest(clientId, redirectUrl, issuer: ..., refreshToken: stored, grantType: 'refresh_token'))`, persist new access token + expiry, return.
  - `client()`: build `auth.AccessCredentials(auth.AccessToken('Bearer', token, expiry), null, scopes)` → wrap with `auth.authenticatedClient(http.Client(), credentials)`.
  - On 401 from any Gmail call, the caller (`GmailClient`) catches, calls `accessToken()` again (which re-runs refresh), retries once. If refresh itself returns `invalid_grant` → `signOut()` + throw `GmailAuthRequired('token revoked')`.

- [ ] **Step 3.3** TDD test file `gmail_auth_service_test.dart` using `mocktail` (fake `FlutterAppAuth` + in-memory `FlutterSecureStorage`):
  - `isSignedIn` false when storage empty; true after a refresh token is stored.
  - `beginInteractiveSignIn` success path → storage populated with all five keys.
  - `beginInteractiveSignIn` user-cancel → throws `GmailAuthDenied`.
  - `accessToken` returns cached when `expiresAtMs` is in the future.
  - `accessToken` triggers refresh when `expiresAtMs` is in the past; updates storage.
  - `accessToken` throws `GmailAuthRequired` when no refresh token.
  - `accessToken` after refresh returns `invalid_grant` → wipes storage + throws `GmailAuthRequired('token revoked')`.
  - `signOut` clears all five keys.

  Expected to fail before Step 3.4.

- [ ] **Step 3.4** Implement; run:
  ```bash
  flutter test test/features/gmail/services/gmail_auth_service_test.dart
  ```
  Expected: green.

- [ ] **Step 3.5** Analyze:
  ```bash
  flutter analyze lib/features/gmail/
  ```

- [ ] **Step 3.6** Commit:
  ```bash
  git add lib/features/gmail/services/gmail_auth_service.dart \
          lib/features/gmail/services/gmail_auth_exceptions.dart \
          test/features/gmail/services/gmail_auth_service_test.dart
  git commit -m "feat(gmail): GmailAuthService — flutter_appauth + secure storage + refresh"
  ```

**Acceptance:** Dart unit tests green; analyzer clean; service compiles.
**Tests:** Dart unit (8+ cases).
**Time:** 2.5 h.
**Depends on:** Task 2.

---

### Task 4: `GmailClient` — typed wrapper over `gmail.v1.GmailApi` + tests (TDD)

**Files:**
- Create: `/Users/dmitry/Downloads/taler_id_mobile/lib/features/gmail/services/gmail_client.dart`
- Create: `/Users/dmitry/Downloads/taler_id_mobile/lib/features/gmail/models/gmail_message_summary.dart` (plain Dart, NOT Freezed — small, no codegen needed; freezed acceptable if you prefer consistency with Phase 1A's `CapturedNotification`).
- Create: `/Users/dmitry/Downloads/taler_id_mobile/lib/features/gmail/models/gmail_message.dart`
- Create: `/Users/dmitry/Downloads/taler_id_mobile/lib/features/gmail/services/gmail_body_extractor.dart` (pure function — MIME part tree → plain text + truncation flag + attachment list).
- Create: `/Users/dmitry/Downloads/taler_id_mobile/lib/features/gmail/services/gmail_rfc2822_builder.dart` (pure function — build a base64url RFC 2822 message for `users.messages.send`).
- Create: `/Users/dmitry/Downloads/taler_id_mobile/test/features/gmail/services/gmail_client_test.dart`
- Create: `/Users/dmitry/Downloads/taler_id_mobile/test/features/gmail/services/gmail_body_extractor_test.dart`
- Create: `/Users/dmitry/Downloads/taler_id_mobile/test/features/gmail/services/gmail_rfc2822_builder_test.dart`

- [ ] **Step 4.1** Models:
  ```dart
  class GmailMessageSummary {
    final String messageId;
    final String threadId;
    final String from;          // "Имя <email@host>"
    final String subject;
    final String snippet;       // Gmail's own short preview, ~200 chars
    final DateTime date;
    final bool hasAttachments;
    final int attachmentCount;
    final bool unread;
    Map<String, dynamic> toToolJson();
  }

  class GmailMessage {
    final String messageId;
    final String threadId;
    final String from;
    final List<String> to;
    final List<String> cc;
    final String subject;
    final DateTime date;
    final String bodyText;       // plain-text, HTML-stripped if necessary
    final bool truncated;        // body > 2000 chars
    final List<GmailAttachmentInfo> attachments;
    final List<String> labels;
    Map<String, dynamic> toToolJson();
  }

  class GmailAttachmentInfo {
    final String filename;
    final String mimeType;
    final int sizeBytes;
    final String attachmentId;   // for future download phase
  }
  ```

  `toToolJson` produces the wire shape the model sees — keep keys snake_case (`message_id`, `thread_id`, `has_attachments`, `attachment_count`, `body_text`, etc.).

- [ ] **Step 4.2** `gmail_body_extractor.dart` — pure function:
  ```dart
  class ExtractedBody {
    final String text;
    final bool truncated;
    final List<GmailAttachmentInfo> attachments;
  }
  ExtractedBody extractBody(gmail.Message msg, {int maxChars = 2000});
  ```

  Algorithm:
  1. Recursively walk `msg.payload` part tree.
  2. Collect: first `text/plain` part body (base64url-decoded UTF-8) — preferred.
  3. If no plain part, take first `text/html` part, run `html.parse(...).body?.text ?? ''`, collapse whitespace.
  4. Collect any non-text part with `filename != null && filename.isNotEmpty` into `attachments`.
  5. If decoded text length > `maxChars`, truncate (try to cut at last whitespace within the last 100 chars) and set `truncated = true`.

  TDD: `gmail_body_extractor_test.dart` with hand-crafted `gmail.Message` JSON fixtures:
  - Pure text/plain → returns body verbatim.
  - multipart/alternative with text/plain + text/html → returns text/plain.
  - HTML-only → returns stripped text.
  - multipart/mixed with one attachment → attachment surfaced with right filename + size; body still extracted.
  - 5000-character body → truncated at 2000 with `truncated = true`.
  - Empty payload (`payload.body.data == null` everywhere) → returns empty string, `truncated = false`.
  - Base64url with `=` padding stripped (per RFC 4648 §5) → still decodes.
  - UTF-8 multi-byte body (Cyrillic) → decodes correctly.

- [ ] **Step 4.3** `gmail_rfc2822_builder.dart` — pure function:
  ```dart
  String buildRfc2822({
    required String from,
    required List<String> to,
    List<String> cc = const [],
    List<String> bcc = const [],
    required String subject,
    required String bodyText,
    String? inReplyToMessageId,    // for replies
    List<String> references = const [],
  });
  ```

  Output is a single RFC 2822 string with:
  - `From: ...`
  - `To: <comma-separated>`
  - `Cc:` if non-empty
  - `Subject: ...` with UTF-8 encoded-word (`=?UTF-8?B?<base64>?=`) if non-ASCII.
  - `MIME-Version: 1.0`
  - `Content-Type: text/plain; charset="UTF-8"`
  - `Content-Transfer-Encoding: 8bit`
  - `In-Reply-To: <msg-id>` and `References: <ids>` when replying.
  - blank line, body.

  This whole string then base64url-encoded (without padding) into `gmail.Message.raw` for `users.messages.send`.

  TDD: `gmail_rfc2822_builder_test.dart`:
  - ASCII subject + ASCII body → ASCII headers + raw body.
  - Russian subject "Привет" → encoded-word form.
  - Russian body → stays UTF-8 with `8bit` encoding (Gmail accepts it).
  - Reply: `inReplyToMessageId` populated → emits `In-Reply-To` + `References` containing it + previous references.
  - Cc + Bcc → both surface in headers (Bcc included locally; Gmail's behaviour with Bcc on submitted raw is to honour it).
  - Subject `Re: ...` — caller responsibility; builder does not prefix. (Tested by passing already-prefixed subject.)

- [ ] **Step 4.4** `gmail_client.dart`:
  ```dart
  class GmailClient {
    final GmailAuthService _auth;
    final http.Client Function() _httpFactory;   // for tests
    GmailClient(this._auth, {http.Client Function()? httpFactory});

    Future<List<GmailMessageSummary>> listRecent({String query = 'in:inbox is:unread', int limit = 20});
    Future<GmailMessage> read(String messageId);
    Future<String> send({required List<String> to, required String subject, required String bodyText, List<String> cc, List<String> bcc});
    Future<String> reply({required String threadId, required String bodyText});
    Future<List<GmailMessageSummary>> search({required String query, int limit = 20});
  }
  ```

  Each method:
  1. `final client = await _auth.client();`
  2. `final api = gmail.GmailApi(client);`
  3. Call the api; convert response → our model via `extractBody` / header parsing.
  4. Catch `gmail.DetailedApiRequestError` with `status == 401`. Call `_auth.accessToken()` once more (forces refresh) and retry. If still 401 → throw `GmailAuthRequired`.

  For `reply`:
  - First call `api.users.messages.get(userId: 'me', id: <lastMessageIdOfThread>)` to grab `Subject` and `Message-ID` headers, so the new message has correct `In-Reply-To` + `References` + `Subject: Re: ...` (don't duplicate `Re: `).
  - Strategy to pick "last message of thread": call `api.users.threads.get(userId: 'me', id: threadId)`, take the last entry in `messages`.

  For `send` / `reply`:
  - Build RFC 2822 → base64url encode (without `=` padding, with `+/` replaced by `-_`).
  - `gmail.Message msg = gmail.Message()..raw = encoded..threadId = threadId (for reply only);`
  - `await api.users.messages.send(msg, 'me')`.
  - Return `msg.id` from the response.

- [ ] **Step 4.5** TDD `gmail_client_test.dart`:
  - Use `googleapis_auth`'s `http.MockClient` (from `package:http/testing.dart`) to fake Gmail API responses.
  - `listRecent` calls `users.messages.list?q=in:inbox+is:unread&maxResults=20` and a follow-up `users.messages.get` for each id (in batched `Future.wait`) — assert the URL shape and that the returned summaries map correctly.
  - `read` calls `users.messages.get?format=full` and uses `extractBody`; for a 3000-char body → returns `truncated: true`.
  - `send` produces a base64url payload that round-trips to the expected RFC 2822 string.
  - `reply` does threads.get → picks last message → set `In-Reply-To` to that message's `Message-ID`.
  - `search('from:olga@example.com')` forwards `q` verbatim.
  - 401 then 200 → retried once → succeeds.
  - 401 twice → throws `GmailAuthRequired`.

- [ ] **Step 4.6** Run:
  ```bash
  flutter test test/features/gmail/
  flutter analyze lib/features/gmail/
  ```

- [ ] **Step 4.7** Commit:
  ```bash
  git add lib/features/gmail/services/gmail_client.dart \
          lib/features/gmail/services/gmail_body_extractor.dart \
          lib/features/gmail/services/gmail_rfc2822_builder.dart \
          lib/features/gmail/models/ \
          test/features/gmail/
  git commit -m "feat(gmail): GmailClient (list/read/send/reply/search) + body extractor + RFC2822 builder"
  ```

**Acceptance:** All gmail tests green; analyzer clean.
**Tests:** Dart unit (~20 cases across three test files).
**Time:** 3 h.
**Depends on:** Task 3.

---

### Task 5: DI registration + tool definitions + dispatcher in `assistant_screen.dart`

**Files:**
- Modify: `/Users/dmitry/Downloads/taler_id_mobile/lib/core/di/service_locator.dart` — register `GmailAuthService`, `GmailClient` as lazy singletons next to the existing `NotificationStore` registrations at line ~254–261.
- Modify: `/Users/dmitry/Downloads/taler_id_mobile/lib/features/assistant/presentation/screens/assistant_screen.dart`:
  - In the `tools: [...]` array, **append five new tool definitions immediately after the existing `messenger_reply` entry** which ends at line ~822 (it closes with `'required': ['notification_key', 'text']` then `},`). New entries go between `messenger_reply` and the `get_profile` entry that currently starts at line ~823.
  - In `_handleFunctionCall` (starting line 1712), **append five new `else if` arms immediately after the existing `messenger_reply` branch** which ends at line ~2406 (it closes with `}` of the inner if/else then `}` of the branch). New arms go between that closing brace and the `} else { output = jsonEncode({'error': 'unknown function $name'});` at line ~2407.

- [ ] **Step 5.1** DI in `service_locator.dart` — add immediately after the existing `NotificationPermissionService` registration (line ~261):

  ```dart
  // Phase 1C: Gmail (OAuth + read/send/reply) — voice-only.
  sl.registerLazySingleton<GmailAuthService>(
    () => AppAuthGmailAuthService(
      storage: const FlutterSecureStorage(
        aOptions: AndroidOptions(encryptedSharedPreferences: true),
      ),
      appAuth: const FlutterAppAuth(),
    ),
  );
  sl.registerLazySingleton<GmailClient>(
    () => GmailClient(sl<GmailAuthService>()),
  );
  ```

  Add imports at the top of `service_locator.dart`:
  ```dart
  import '../../features/gmail/services/gmail_auth_service.dart';
  import '../../features/gmail/services/gmail_client.dart';
  ```

- [ ] **Step 5.2** Tool registration — **append after the closing `}` of the `messenger_reply` block at line ~822**, before the `get_profile` entry. Match the verbose-description style already in use:

  ```dart
  // Phase 1C: Gmail tools (voice-only).
  {
    'type': 'function',
    'name': 'gmail_list_recent',
    'description':
        'List recent Gmail threads from the user\'s inbox. Use when the user asks '
        '"что нового в почте", "есть новые письма", "что в Gmail", "проверь почту". '
        'Returns a slim list: from, subject, snippet, date, has_attachments, unread. '
        'NOT for: notification previews already surfaced by messenger_read_recent — '
        'this is the real Gmail client and gives full thread / message IDs you can '
        'pass to gmail_read or gmail_reply.',
    'parameters': {
      'type': 'object',
      'properties': {
        'query': {
          'type': 'string',
          'description':
              'Optional Gmail search query (e.g. "in:inbox is:unread", "from:boss", '
              '"has:attachment newer_than:1d"). Defaults to "in:inbox is:unread".',
        },
        'limit': {
          'type': 'integer',
          'description': 'Max threads to return (default 20, max 50).',
        },
      },
    },
  },
  {
    'type': 'function',
    'name': 'gmail_read',
    'description':
        'Read the full body of one Gmail message by message_id (from gmail_list_recent '
        'or gmail_search). Returns plain-text body (HTML stripped), from, subject, '
        'date, attachments info. If body > 2000 chars, returns truncated body with '
        'truncated: true — offer to summarise or to fetch again with a wider window.',
    'parameters': {
      'type': 'object',
      'properties': {
        'message_id': {
          'type': 'string',
          'description': 'The Gmail message ID from gmail_list_recent / gmail_search.',
        },
      },
      'required': ['message_id'],
    },
  },
  {
    'type': 'function',
    'name': 'gmail_send',
    'description':
        'Compose and send a NEW email from the user. TWO-STEP CONFIRMATION REQUIRED. '
        'First call with confirmed=false (default) — the tool returns the draft for you '
        'to read back to the user (to, subject, body preview). Read it aloud, ask '
        '"подтверди". Only when the user explicitly says "да" / "отправляй" / "yes" / '
        '"send it" — call again with confirmed=true and identical other args. '
        'Use for new outgoing mail; for replies inside an existing thread use gmail_reply.',
    'parameters': {
      'type': 'object',
      'properties': {
        'to': {
          'type': 'string',
          'description': 'Recipient email address. For multiple, comma-separated.',
        },
        'subject': {'type': 'string'},
        'body': {'type': 'string', 'description': 'Plain-text body. No HTML.'},
        'cc': {'type': 'string', 'description': 'Optional comma-separated CC.'},
        'bcc': {'type': 'string', 'description': 'Optional comma-separated BCC.'},
        'confirmed': {
          'type': 'boolean',
          'description':
              'false (default) = return draft for read-back; true = actually send. '
              'NEVER pass true until the user has verbally confirmed.',
        },
      },
      'required': ['to', 'subject', 'body'],
    },
  },
  {
    'type': 'function',
    'name': 'gmail_reply',
    'description':
        'Reply to an existing Gmail thread. TWO-STEP CONFIRMATION REQUIRED — same flow '
        'as gmail_send (first call confirmed=false → read back → user says "да" → '
        'second call confirmed=true). The reply preserves Subject (auto-prepends "Re: " '
        'if needed), In-Reply-To and References headers automatically. Use thread_id '
        'from gmail_list_recent or gmail_search.',
    'parameters': {
      'type': 'object',
      'properties': {
        'thread_id': {'type': 'string'},
        'body': {'type': 'string', 'description': 'Plain-text reply body.'},
        'confirmed': {
          'type': 'boolean',
          'description': 'See gmail_send.confirmed — same two-step rule.',
        },
      },
      'required': ['thread_id', 'body'],
    },
  },
  {
    'type': 'function',
    'name': 'gmail_search',
    'description':
        'Search Gmail using Gmail\'s native query syntax (from:, to:, subject:, '
        'has:attachment, before:, after:, newer_than:, older_than:, label:, is:, etc.). '
        'Returns the same slim shape as gmail_list_recent. Use when the user asks '
        '"найди письма от …", "что приходило от налоговой", "есть письмо с темой …".',
    'parameters': {
      'type': 'object',
      'properties': {
        'query': {'type': 'string', 'description': 'Gmail search expression.'},
        'limit': {'type': 'integer', 'description': 'Default 20, max 50.'},
      },
      'required': ['query'],
    },
  },
  ```

- [ ] **Step 5.3** Dispatcher — append after the existing `messenger_reply` branch which closes at line ~2406. Match the exact shape used by `messenger_read_recent` (read line 2368–2389) — same try/catch surrounding, same `output = jsonEncode(...)` final assignment:

  ```dart
  } else if (name == 'gmail_list_recent') {
    final args = argsJson.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(argsJson) as Map<String, dynamic>;
    final query = (args['query'] as String?) ?? 'in:inbox is:unread';
    final limit = ((args['limit'] as num?)?.toInt() ?? 20).clamp(1, 50);
    try {
      final client = sl<GmailClient>();
      final items = await client.listRecent(query: query, limit: limit);
      output = jsonEncode({'items': items.map((m) => m.toToolJson()).toList()});
    } on GmailAuthRequired catch (e) {
      output = jsonEncode({
        'error': 'oauth_pending',
        'hint': 'Скажи: "Открой согласие Google в браузере и подтверди доступ, '
                'потом скажи готово". Затем вызови sl<GmailAuthService>().beginInteractiveSignIn '
                'через ещё один tool call — пока: попроси пользователя выполнить вход.',
        'detail': e.toString(),
      });
    } catch (e) {
      output = jsonEncode({'error': e.toString()});
    }
  } else if (name == 'gmail_read') {
    final args = jsonDecode(argsJson) as Map<String, dynamic>;
    final messageId = (args['message_id'] as String?) ?? '';
    if (messageId.isEmpty) {
      output = jsonEncode({'error': 'missing message_id'});
    } else {
      try {
        final msg = await sl<GmailClient>().read(messageId);
        output = jsonEncode(msg.toToolJson());
      } on GmailAuthRequired catch (e) {
        output = jsonEncode({'error': 'oauth_pending', 'detail': e.toString()});
      } catch (e) {
        output = jsonEncode({'error': e.toString()});
      }
    }
  } else if (name == 'gmail_send') {
    final args = jsonDecode(argsJson) as Map<String, dynamic>;
    final to = (args['to'] as String?) ?? '';
    final subject = (args['subject'] as String?) ?? '';
    final body = (args['body'] as String?) ?? '';
    final cc = (args['cc'] as String?) ?? '';
    final bcc = (args['bcc'] as String?) ?? '';
    final confirmed = args['confirmed'] == true;
    if (to.isEmpty || subject.isEmpty || body.isEmpty) {
      output = jsonEncode({'error': 'invalid_draft', 'missing': [
        if (to.isEmpty) 'to', if (subject.isEmpty) 'subject', if (body.isEmpty) 'body',
      ]});
    } else if (!confirmed) {
      output = jsonEncode({
        'needs_confirmation': true,
        'draft': {
          'to': to,
          'cc': cc,
          'bcc': bcc,
          'subject': subject,
          'body_preview': body.length > 200 ? '${body.substring(0, 200)}…' : body,
          'body_full_chars': body.length,
        },
        'hint':
            'Прочитай вслух адресата, тему и тело письма пользователю. '
            'Спроси: "Отправлять?" Когда пользователь скажет "да" / "отправляй" / '
            '"yes" — вызови gmail_send ещё раз с теми же аргументами и confirmed: true. '
            'Если пользователь скажет "нет" / "погоди" / "измени" — не отправляй, спроси что поменять.',
      });
    } else {
      try {
        final messageId = await sl<GmailClient>().send(
          to: to.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList(),
          subject: subject,
          bodyText: body,
          cc: cc.isEmpty ? const [] : cc.split(',').map((s) => s.trim()).toList(),
          bcc: bcc.isEmpty ? const [] : bcc.split(',').map((s) => s.trim()).toList(),
        );
        output = jsonEncode({'ok': true, 'message_id': messageId});
      } on GmailAuthRequired catch (e) {
        output = jsonEncode({'error': 'oauth_pending', 'detail': e.toString()});
      } catch (e) {
        output = jsonEncode({'ok': false, 'error': e.toString()});
      }
    }
  } else if (name == 'gmail_reply') {
    final args = jsonDecode(argsJson) as Map<String, dynamic>;
    final threadId = (args['thread_id'] as String?) ?? '';
    final body = (args['body'] as String?) ?? '';
    final confirmed = args['confirmed'] == true;
    if (threadId.isEmpty || body.isEmpty) {
      output = jsonEncode({'error': 'invalid_draft', 'missing': [
        if (threadId.isEmpty) 'thread_id', if (body.isEmpty) 'body',
      ]});
    } else if (!confirmed) {
      output = jsonEncode({
        'needs_confirmation': true,
        'draft': {
          'thread_id': threadId,
          'body_preview': body.length > 200 ? '${body.substring(0, 200)}…' : body,
          'body_full_chars': body.length,
        },
        'hint':
            'Прочитай пользователю текст ответа. Спроси: "Отправлять?". '
            'Когда подтвердит — вызови gmail_reply ещё раз с теми же аргументами и confirmed: true.',
      });
    } else {
      try {
        final messageId = await sl<GmailClient>().reply(threadId: threadId, bodyText: body);
        output = jsonEncode({'ok': true, 'message_id': messageId});
      } on GmailAuthRequired catch (e) {
        output = jsonEncode({'error': 'oauth_pending', 'detail': e.toString()});
      } catch (e) {
        output = jsonEncode({'ok': false, 'error': e.toString()});
      }
    }
  } else if (name == 'gmail_search') {
    final args = jsonDecode(argsJson) as Map<String, dynamic>;
    final query = (args['query'] as String?) ?? '';
    final limit = ((args['limit'] as num?)?.toInt() ?? 20).clamp(1, 50);
    if (query.isEmpty) {
      output = jsonEncode({'error': 'missing query'});
    } else {
      try {
        final items = await sl<GmailClient>().search(query: query, limit: limit);
        output = jsonEncode({'items': items.map((m) => m.toToolJson()).toList()});
      } on GmailAuthRequired catch (e) {
        output = jsonEncode({'error': 'oauth_pending', 'detail': e.toString()});
      } catch (e) {
        output = jsonEncode({'error': e.toString()});
      }
    }
  }
  ```

  **Verify by reading the existing `messenger_read_recent` branch (lines 2368–2389) before pasting — the closing `_sendEvent({...})` call after the dispatch chain (line 2413) is shared and unchanged.** Do not invent helpers.

- [ ] **Step 5.4** Compile + analyze:
  ```bash
  flutter analyze lib/
  ```

- [ ] **Step 5.5** Commit:
  ```bash
  git add lib/core/di/service_locator.dart \
          lib/features/assistant/presentation/screens/assistant_screen.dart
  git commit -m "feat(assistant): register 5 gmail_* voice tools + dispatcher + confirm gate"
  ```

**Acceptance:** Code compiles, no analyzer errors, all five tools listed in the tools array; dispatcher routes each name.
**Tests:** No new dart tests — handlers are thin glue over `GmailClient` (already tested) and the confirm gate is pure JSON construction (verified by Task 7 unit tests + Task 8 E2E).
**Time:** 2 h.
**Depends on:** Tasks 3, 4.

---

### Task 6: System prompt updates (RU + EN) — usage guidance + confirm flow rules

**Files:**
- Modify: `/Users/dmitry/Downloads/taler_id_mobile/lib/features/assistant/presentation/screens/assistant_screen.dart`:
  - Russian block at line ~437–442 — currently has Phase 1A's `ВНЕШНИЕ МЕССЕНДЖЕРЫ` section. Add a new `ПОЧТА (Gmail):` section right below it (before `'\n\n'` separator).
  - English block at line ~546–550 — mirror the new section.

- [ ] **Step 6.1** Russian addition (place after line 440, before the `\n\n` that closes the messenger section):

  ```
  '\n'
  'ПОЧТА (Gmail):\n'
  'Если пользователь спрашивает "что нового в почте", "проверь Gmail", "есть письма", "что мне писали" с упоминанием почты — используй gmail_list_recent. Это РЕАЛЬНЫЙ Gmail-клиент, не уведомления (messenger_read_recent — это короткие превью; gmail_* — настоящие письма с message_id и thread_id).\n'
  'Если нужно прочитать конкретное письмо — gmail_read(message_id). Если тело пришло с truncated:true — спроси, читать целиком или сделать краткое содержание (можешь использовать тот же gmail_read и сократить сам).\n'
  'Поиск по почте — gmail_search с Gmail-синтаксисом (from:, subject:, has:attachment, newer_than:1d). НЕ переводи запрос на свой язык — отдай Gmail как есть.\n'
  'ОТПРАВКА (gmail_send) и ОТВЕТ (gmail_reply) — двухшаговое подтверждение:\n'
  '  ШАГ 1: вызови инструмент БЕЗ confirmed (или confirmed:false). Получишь {needs_confirmation:true, draft:{...}}. Прочитай пользователю получателя, тему (для send), и тело письма ВСЛУХ. Спроси: "Отправлять?".\n'
  '  ШАГ 2: ТОЛЬКО когда пользователь СКАЖЕТ "да" / "отправляй" / "ага" / "ок отправляй" — вызови инструмент ЕЩЁ РАЗ с ровно теми же аргументами и confirmed:true.\n'
  '  Если пользователь скажет "нет" / "погоди" / "измени" / "не так" — НЕ вызывай инструмент с confirmed:true. Спроси что поправить и собери новый draft.\n'
  '  НИКОГДА не передавай confirmed:true без явного устного "да". Это правило БЕЗ ИСКЛЮЧЕНИЙ.\n'
  'Если gmail_* вернул error: oauth_pending — скажи пользователю: "Чтобы я мог работать с почтой, нужно один раз войти в Google. Сейчас открою окно согласия". Затем подскажи, что пользователь должен подтвердить доступ в браузере и сказать "готово". Не повторяй вызов пока пользователь не подтвердит.\n'
  'НЕ используй gmail_* для Taler ID встроенной почты/мессенджера — это разные источники.\n'
  ```

- [ ] **Step 6.2** English mirror (place after line 548 in the English block):

  ```
  '\n'
  'EMAIL (Gmail):\n'
  'If the user asks "any new mail", "check Gmail", "what came in email" — use gmail_list_recent. This is the REAL Gmail client, distinct from notification previews (messenger_read_recent — short previews; gmail_* — actual messages with message_id and thread_id).\n'
  'To read one message — gmail_read(message_id). If body comes back truncated:true — ask the user if they want it in full or summarised (you can call gmail_read again and summarise yourself).\n'
  'Search — gmail_search using Gmail\'s native syntax (from:, subject:, has:attachment, newer_than:1d). Do NOT translate the query — pass it to Gmail verbatim.\n'
  'SEND (gmail_send) and REPLY (gmail_reply) — two-step confirmation:\n'
  '  STEP 1: call the tool WITHOUT confirmed (or confirmed:false). You will get {needs_confirmation:true, draft:{...}}. Read the recipient, subject (for send), and body ALOUD to the user. Ask: "Should I send it?".\n'
  '  STEP 2: ONLY when the user VERBALLY says "yes" / "send it" / "go ahead" — call the tool AGAIN with the exact same args plus confirmed:true.\n'
  '  If the user says "no" / "wait" / "change it" — do NOT call with confirmed:true. Ask what to adjust and build a new draft.\n'
  '  NEVER pass confirmed:true without an explicit verbal "yes". No exceptions.\n'
  'If a gmail_* tool returns error: oauth_pending — tell the user: "To work with your mail I need to sign in to Google once. I\'ll open the consent screen". Then guide them: confirm access in the browser, say "ready". Do not retry until they confirm.\n'
  'Do NOT use gmail_* for Taler ID\'s built-in messenger — these are different sources.\n'
  ```

- [ ] **Step 6.3** Re-read the modified `_systemPrompt` block end-to-end to make sure the string concatenation is intact (no missing trailing single-quote, no doubled newlines). Build + run smoke:
  ```bash
  flutter analyze lib/features/assistant/
  ```

- [ ] **Step 6.4** Commit:
  ```bash
  git add lib/features/assistant/presentation/screens/assistant_screen.dart
  git commit -m "feat(assistant): system-prompt guidance for gmail_* tools (RU+EN) + confirm rule"
  ```

**Acceptance:** Analyzer clean; both RU and EN sections contain ПОЧТА / EMAIL block.
**Tests:** None — prompt content is verified live in Task 8.
**Time:** 45 min.
**Depends on:** Task 5.

---

### Task 7: Confirm-gate unit tests + body length cap + edge cases

**Files:**
- Create: `/Users/dmitry/Downloads/taler_id_mobile/test/features/gmail/confirm_gate_test.dart`
- Modify (if shown necessary): `lib/features/gmail/services/gmail_body_extractor.dart` (edge fixes from tests).

The confirm gate lives inline in `assistant_screen.dart` and is not directly unit-testable without spinning up the whole screen. Solution: refactor the gate into a tiny pure function `GmailConfirmGate.evaluate({required Map<String, dynamic> args, required String toolName}) → GmailConfirmGateResult` (a sealed/value type) and call it from the dispatcher. Pure logic = easy tests.

- [ ] **Step 7.1** Create `lib/features/gmail/services/gmail_confirm_gate.dart`:
  ```dart
  sealed class GmailConfirmGateResult {}
  class GmailConfirmGateInvalid extends GmailConfirmGateResult { final List<String> missingFields; ... }
  class GmailConfirmGateNeedsConfirmation extends GmailConfirmGateResult { final Map<String, dynamic> draftJson; ... }
  class GmailConfirmGateProceed extends GmailConfirmGateResult { /* normalised args */ ... }

  class GmailConfirmGate {
    static GmailConfirmGateResult evaluateSend(Map<String, dynamic> args);
    static GmailConfirmGateResult evaluateReply(Map<String, dynamic> args);
  }
  ```

  Move the validation + draft-construction logic from the dispatcher into these functions. Dispatcher in `assistant_screen.dart` becomes a thin `switch (result) { ... }`.

- [ ] **Step 7.2** TDD `confirm_gate_test.dart`:
  - `evaluateSend({to:'',subject:'',body:''})` → `Invalid(['to','subject','body'])`.
  - `evaluateSend({to:'x',subject:'s',body:'b'})` → `NeedsConfirmation` with `draft.to='x'`, `body_preview='b'`, `body_full_chars=1`.
  - `evaluateSend(..., confirmed:true)` → `Proceed` with normalised list-of-strings for `to`/`cc`/`bcc`.
  - Long body (300 chars) → `body_preview` truncated to 200 + `…`.
  - `evaluateReply({thread_id:'',body:''})` → `Invalid(['thread_id','body'])`.
  - `evaluateReply({thread_id:'t',body:'b',confirmed:false})` → `NeedsConfirmation`.
  - `evaluateReply({thread_id:'t',body:'b',confirmed:true})` → `Proceed`.
  - Comma-list normalisation: `to='a@x.com, b@x.com,  '` → `['a@x.com','b@x.com']`.

- [ ] **Step 7.3** Update the dispatcher in `assistant_screen.dart` to call `GmailConfirmGate.evaluateSend / evaluateReply` instead of inline logic.

- [ ] **Step 7.4** Add body-extractor edge-case tests (extend Task 4's body extractor file):
  - Encoded-word Subject (`=?UTF-8?B?...?=`) in headers → decoded to UTF-8 string before being put on `GmailMessage.subject`.
  - `Content-Transfer-Encoding: quoted-printable` plain part → decoded correctly (use `package:mime` or hand-roll QP decoder; if simpler, declare it as a known limitation and only support `7bit`/`8bit`/`base64`).
  - HTML with `<script>` and `<style>` → contents of those tags excluded from extracted text.
  - HTML with `&nbsp;` and `&mdash;` → decoded to actual characters.

- [ ] **Step 7.5** Run all tests + analyze:
  ```bash
  flutter test test/features/gmail/
  flutter analyze lib/features/gmail/ lib/features/assistant/
  ```

- [ ] **Step 7.6** Commit:
  ```bash
  git add lib/features/gmail/services/gmail_confirm_gate.dart \
          lib/features/gmail/services/gmail_body_extractor.dart \
          lib/features/assistant/presentation/screens/assistant_screen.dart \
          test/features/gmail/
  git commit -m "test(gmail): confirm-gate unit tests + extractor edge cases + dispatcher refactor"
  ```

**Acceptance:** All gmail tests green; dispatcher uses the pure gate; analyzer clean.
**Tests:** Dart unit (8+ confirm-gate cases + 4+ extractor edge cases).
**Time:** 2 h.
**Depends on:** Tasks 4, 5, 6.

---

### Task 8: End-to-end smoke on Xiaomi 2211133G + journal entry

**Files:**
- Create: `/Users/dmitry/Downloads/taler_id_mobile/docs/superpowers/journals/2026-05-2X-agent-shell-phase-1c-gmail.md` (or append to the Phase 1A journal if it makes timeline sense).
- No code.

- [ ] **Step 8.1** Confirm Дмитрий has completed all prerequisites (cloud console setup, OAuth client ID in hand). The implementer subagent will receive the client ID via the dart-define on the command line — Дмитрий passes it interactively at build time.

- [ ] **Step 8.2** Build dev release APK with the real client ID:
  ```bash
  cd ~/Downloads/taler_id_mobile && flutter build apk --flavor dev --release \
       -t lib/main_dev.dart \
       --dart-define=FLAVOR=dev \
       --dart-define=BASE_URL=https://staging.id.taler.tirol \
       --dart-define=AGENT_SHELL_AS_HOME=true \
       --dart-define=GOOGLE_OAUTH_CLIENT_ID=<REAL_CLIENT_ID>.apps.googleusercontent.com
  ```

- [ ] **Step 8.3** Install on the Xiaomi (`adb -s 2211133G install -r build/app/outputs/flutter-apk/app-dev-release.apk`). Verify the dev applicationId is registered (it must match the OAuth client's package name field, otherwise Google rejects the consent at step 8.5).

- [ ] **Step 8.4** Open the Assistant; say (RU): *"Что у меня в почте?"*.
  Expected: model calls `gmail_list_recent({})`; tool returns `{error: 'oauth_pending'}`; model voices: *"Чтобы я мог работать с почтой, нужно один раз войти в Google. Открою согласие."*
  Implementer note: in the v1 confirm-gate-only design, the agent CANNOT trigger `beginInteractiveSignIn` itself — it has no tool for that. There are two viable v1 designs; pick one in Task 5 and update if it diverges from this plan:

  - **Design A (preferred for v1):** add a sixth tool `gmail_signin()` that calls `GmailAuthService.beginInteractiveSignIn` and returns `{ok:true, account_email}`. The model invokes it when it sees `oauth_pending`. Update Task 5 system prompt accordingly. Add this tool now if Task 5 was implemented strictly without it.
  - **Design B (UI button):** the home screen shows a "Войти в Gmail" button alongside the Phase 1A notification banner; user taps it once after hearing the prompt. Add to `AgentShellHomeScreen` if going this route.

  **Decision:** go with **Design A** — voice-only is the phase's stated style. Update Task 5 to include `gmail_signin` definition + dispatcher arm. Update Task 6 system prompt to instruct the model to call `gmail_signin` when seeing `oauth_pending`. If Task 5 has been done strictly per the original spec, do the small follow-up here.

- [ ] **Step 8.5** Tap "OK" in the system browser; pick `dvvolkovv@gmail.com`; grant `gmail.modify`. Get redirected back. Verify return to Assistant.

- [ ] **Step 8.6** Say *"Что у меня в почте?"*. Expected: `gmail_list_recent` succeeds; agent voices the top 3–5 unread.

- [ ] **Step 8.7** Say *"Прочитай первое"*. Expected: `gmail_read(<id>)`; agent voices body (or summary if truncated).

- [ ] **Step 8.8** Send-to-self test. Say: *"Отправь себе письмо с темой 'Тест Phase 1C' и текстом 'это тестовое сообщение'"*. Expected:
  1. Model calls `gmail_send({to:'dvvolkovv@gmail.com', subject:'Тест Phase 1C', body:'это тестовое сообщение'})` → returns `needs_confirmation: true`.
  2. Model voices the draft back.
  3. Say *"да отправляй"*.
  4. Model calls `gmail_send(..., confirmed:true)` → returns `{ok:true, message_id:...}`.
  5. Model voices *"Отправлено"*.
  6. Within ~5 s, a new email arrives on Дмитрий's phone — Phase 1A's `messenger_read_recent` would also surface it (verify cross-feature compatibility — Phase 1C does NOT suppress the Gmail notification).

- [ ] **Step 8.9** Reply test. Say: *"Найди последнее письмо от себя и ответь 'получил тест'"*. Expected:
  1. `gmail_search(query:'from:me')` or `gmail_list_recent`.
  2. `gmail_reply(thread_id:..., body:'получил тест')` → `needs_confirmation`.
  3. Voice readback.
  4. *"да"*.
  5. `gmail_reply(..., confirmed:true)` → `{ok:true}`.
  6. Open the original mail in Gmail app on phone or web; reply visible in thread.

- [ ] **Step 8.10** Search test. Say: *"Найди письма с вложениями за последнюю неделю"*. Expected: `gmail_search(query:'has:attachment newer_than:7d')`.

- [ ] **Step 8.11** Truncation test. Find or send a long email (>2000 chars); call `gmail_read`; expect `truncated:true`; agent offers to summarise.

- [ ] **Step 8.12** Confirmation-refusal test. Say *"Отправь Маше письмо..."* → readback → say *"нет"*. Expected: agent does NOT call `gmail_send` with `confirmed:true`. Verify by inspecting logs / Sent folder remains unchanged.

- [ ] **Step 8.13** Journal entry. Append observations: latency per tool, OAuth UX, any quirks (e.g. Chrome Custom Tab vs default browser handling on MIUI; whether MIUI auto-killed the redirect; HTML stripping quality on real newsletters; Russian subject encoding correctness; whether the model reliably waits for "да" or sometimes self-confirms).

- [ ] **Step 8.14** Commit:
  ```bash
  git add docs/superpowers/journals/2026-05-2X-agent-shell-phase-1c-gmail.md
  git commit -m "docs(agent-shell): Phase 1C field notes — Gmail end-to-end on Xiaomi"
  ```

**Acceptance:** Voice → list / read / send / reply / search all work against real Gmail; confirmation flow gates sends; truncation works; OAuth refresh persists across an app restart (verify by killing the app and asking for mail again — no re-prompt for consent).
**Tests:** End-to-end manual.
**Time:** 2 h (assuming OAuth setup is correct and no quirks).
**Depends on:** Task 7 + Дмитрий having completed prerequisites.

---

### Task 9 (optional): Body length / encoding / multipart hardening

**Files:**
- Modify: `lib/features/gmail/services/gmail_body_extractor.dart`
- Modify: `lib/features/gmail/services/gmail_client.dart` (if header decoding moves here).
- Extend: `test/features/gmail/services/gmail_body_extractor_test.dart`

Once Task 8 surfaces real-world quirks (encoded subjects, quoted-printable bodies, Apple-style multipart/alternative ordering, marketing emails with nested multipart/related for inline images), add the missing handlers here. Keep tests black-box on real Gmail JSON samples captured during Task 8.

- [ ] **Step 9.1** Capture 5–10 real `users.messages.get?format=full` JSON responses from Task 8 — sanitise (replace addresses/IDs with placeholders) and commit as test fixtures under `test/features/gmail/fixtures/`.
- [ ] **Step 9.2** Add a parameterised test that runs `extractBody` on each fixture and asserts the resulting plain-text body is non-empty and free of HTML tags.
- [ ] **Step 9.3** Fix any extractor bugs uncovered.
- [ ] **Step 9.4** Commit `git commit -m "test(gmail): real-world body extractor fixtures + quoted-printable / encoded-word fixes"`.

**Acceptance:** Real-world samples all decode to readable text.
**Tests:** Dart unit on fixtures.
**Time:** 1.5 h.
**Depends on:** Task 8.

---

## Phase 1C Exit Criteria — Sign-off Checklist

- [ ] OAuth client registered in Google Cloud Console with dev SHA-1 + `tirol.taler.taler_id_mobile.dev` package name; `dvvolkovv@gmail.com` listed as test user.
- [ ] APK builds for dev flavor with `--dart-define=GOOGLE_OAUTH_CLIENT_ID=...`.
- [ ] Custom-scheme `tirol.taler.taler_id_mobile.dev:/oauth2redirect` resolves back to the app on Xiaomi after Google consent.
- [ ] All Kotlin unit tests still pass (Phase 1A regression).
- [ ] All Dart tests pass: `flutter test test/features/gmail/` (≥ 30 cases across auth / extractor / client / RFC 2822 / confirm gate).
- [ ] `flutter analyze` clean on `lib/features/gmail/` and the modified `assistant_screen.dart`.
- [ ] Voice end-to-end works on Xiaomi: list, read, search, send (with verbal confirm), reply (with verbal confirm).
- [ ] Confirmation rule observed: `confirmed:true` never sent without explicit voice "да".
- [ ] Token refresh works: kill app → reopen → ask for mail again → no re-consent.
- [ ] Refresh token persists across reboot.
- [ ] Truncation flag set for body > 2000 chars; agent offers summarisation.
- [ ] Attachments surfaced as metadata (filename + size + count); never downloaded.
- [ ] Journal entry recorded with at least one real day of usage.
- [ ] No backend code changed; no new npm packages on backend.
- [ ] PROD untouched; secrets (client ID) NOT committed to git.

When all checked: consider Phase 1 (messenger + Gmail) closed. Next options: Phase 1B (Telegram TDLib full client) or Phase 4 (Calendar — natural pairing with Gmail OAuth plumbing now in place; many cloud-console steps could be reused, just add the calendar scope to the consent screen).

---

## Open questions

1. **Single scope `gmail.modify` vs the pair `gmail.readonly` + `gmail.send`.** `gmail.modify` is one scope, one consent click, slightly broader (can also mark-as-read / star / archive). Pair is least-privilege but two scopes to display in the consent screen. **Default:** `gmail.modify`. Reconsider if Дмитрий wants the consent screen to look narrower.
2. **`gmail_signin` as the sixth tool.** Task 8 forced the addition. Should it be in Task 5 from the start, OR should the home screen have a "Sign in to Gmail" button (Design B)? Default to tool — voice-only style. Update Task 5 spec to include it.
3. **Auto-trigger OAuth on first tool call?** Right now we return `oauth_pending` and let the model call `gmail_signin`. Alternative: the dispatcher could call `beginInteractiveSignIn` automatically inside the same `gmail_list_recent` call (deferred Future, browser tab opens immediately). Simpler UX but the response to that tool call may block on Chrome Custom Tab return — and the OpenAI Realtime tool response is on a strict deadline (~30 s) before the model thinks the tool stalled. Safer to do it as a separate tool call.
4. **HTML-only emails — quality of stripping.** Newsletters and marketing emails are mostly HTML; the `package:html` parser + text accumulation usually produces something reasonable, but tables / multi-column layouts come out as a mess. Worth adding `html2text`-style heuristics? Defer to Task 9 once we see real samples.
5. **Cyrillic / encoded-word subjects.** `=?UTF-8?B?...?=` and `=?KOI8-R?Q?...?=` are common from Russian senders. Task 4 covers UTF-8 base64; KOI8-R / windows-1251 will produce mojibake. Worth handling? Defer with a clear TODO comment; only ~1% of Дмитрий's mail.
6. **Quoted-printable transfer encoding.** Many older mail clients use it for `text/plain` with non-ASCII. Without QP decoding, body comes back full of `=D0=BF=D1=80...` sequences. Task 7 either adds a QP decoder or restricts support. Decision: add a small QP decoder in `gmail_body_extractor.dart` if encoding header says so.
7. **Should `gmail_send` allow sending to multiple recipients in `to`?** v1 supports it via comma-split. Worth surface validation that all addresses look like emails? Add a permissive `RegExp` check; warn but don't block on weird inputs.
8. **Rate limit / quota.** Gmail API gives 1,000,000,000 quota units/day per project — irrelevant for one user. But mass-send abuse from the agent (model decides to send 200 emails because it misread a command) needs a guard. Hard cap in `GmailClient.send`: refuse if any single `to/cc/bcc` list exceeds 20 addresses; refuse more than 10 sends per 60-minute rolling window without an additional confirm.
9. **Should `gmail_search` automatically scope to inbox?** No — Gmail search syntax supports `in:anywhere`; we forward verbatim. The agent should infer scope from the user request.
10. **Privacy of refresh tokens on rooted device.** `flutter_secure_storage` uses `EncryptedSharedPreferences` (AES-256 with key in Android Keystore). On a rooted device, Keystore protections weaken. We accept the risk — Дмитрий accepts it for his daily-driver — but document in the journal.
11. **Multi-language system prompt.** Currently EN + RU. If we want German / Spanish / etc. for future, the prompt will balloon. Defer; Дмитрий speaks RU/EN.
12. **`gmail_reply` to the LATEST vs the FIRST message in the thread.** Default to "reply to last" so `In-Reply-To` chains correctly. Note in tool description.

---

## Risks (≥ 6)

1. **Refresh token revocation cascades.** If Дмитрий ever clicks "Remove access" on Google Account → Security → Third-party apps, the next refresh attempt returns `invalid_grant`. The service wipes storage; next `gmail_*` call returns `oauth_pending` and the user goes through consent again. **Mitigation:** clear error path covered in `GmailAuthService` + `gmail_signin` tool. Document in journal that this is expected behaviour, not a bug.

2. **Token theft on rooted device.** A malicious app with root could read `EncryptedSharedPreferences` (the key is in Android Keystore but root can compromise Keystore on some devices). Stolen refresh token = persistent Gmail access until revoked. **Mitigation:** v1 acceptance — single user, Дмитрий's own device. Stretch: store refresh in `EncryptedFile` with a passphrase-derived key prompted on app open (UX cost too high for v1). Document.

3. **Google Cloud Console quota / suspension.** Test-mode OAuth clients are limited (100 users; 100,000 token grants/year/client). For a single user this is fine forever — but if Дмитрий ever moves the app to production verification track, the unverified-app banner appears unless verification is completed. **Mitigation:** stay in test mode; document the limit; do not submit for verification unless distributing.

4. **Hallucinated recipients.** The model may invent an email address (`marina@gmail.com` instead of a real contact). The send-confirmation gate reads it back, but if Дмитрий is half-asleep and says "да" mechanically, an email goes to the wrong person. **Mitigation:** the confirm prompt explicitly voices the FULL recipient address; the system prompt instructs the model to spell out the address character-by-character if it was inferred rather than provided by the user; add a soft check in `GmailConfirmGate.evaluateSend` that warns the agent if the recipient was not visible in any recent `gmail_list_recent` / `gmail_search` result (heuristic; non-blocking).

5. **OAuth refresh flakes (network / clock skew).** If the device clock is skewed by more than 5 min, Google rejects token requests with `invalid_token`. **Mitigation:** rely on Android system time (always NTP-synced); on `invalid_token` from refresh, retry once after 2 s; if it persists, surface `oauth_pending` with a hint to check the device clock.

6. **Chrome Custom Tab availability on Xiaomi MIUI.** Some MIUI builds disable or replace the default Chrome Custom Tab — `flutter_appauth` then falls back to opening the OS browser, which is fine, but on some setups (Yandex Browser default) the redirect-URI handling may break. **Mitigation:** test on Дмитрий's Xiaomi 2211133G in Task 8; document the default browser used; if it fails, force Chrome via `AndroidIntent` or document "set Chrome as default browser".

7. **MIUI battery optimisation killing the OAuth flow.** MIUI aggressively backgrounds apps; if the user takes >30 s on the consent page, the app process is killed and the `flutter_appauth` callback Activity loses its parent. **Mitigation:** `flutter_appauth` uses an Activity-managed flow; on Android 11+ the receiver handles the redirect even after process death and brings the app back up. Test in Task 8; if broken, add an opaque `AndroidManifest` `taskAffinity` workaround.

8. **System prompt drift / confirmation rule violation.** The model might shortcut: "Ладно, отправляю." → `gmail_send(..., confirmed:true)` without the readback. **Mitigation:** the confirmation rule is repeated in BOTH the system prompt and EACH `gmail_send/_reply` tool description. The confirm-gate detects `confirmed:true` on first call as suspicious (the model should always do confirmed:false first if the user did not literally pre-confirm) — but blocking it would hurt cases where the user said "напиши Маше, что я опаздываю, и отправь" as one breath. Leave the gate permissive; rely on the prompt + readback. Tune after Task 8 if the model misbehaves.

9. **`gmail.modify` scope creep.** With `gmail.modify` the model could (if it wanted to) call `users.messages.trash`, `users.labels.create`, etc. — but our `GmailClient` exposes only the five whitelisted operations. **Mitigation:** the client wraps the API; no raw `GmailApi` is exposed to the dispatcher. Hardening: a comment in `gmail_client.dart` documenting this is a deliberate restriction; future tools must extend the client, not call the API directly.

10. **Bundle size / cold-start regression.** `googleapis` adds tree-shakeable Dart, but the `gmail.v1` part alone is several hundred KB compiled. **Mitigation:** import only the `gmail` library, not the whole `googleapis` umbrella (`import 'package:googleapis/gmail/v1.dart' as gmail;`); verify APK size before/after — should be < 1 MB increase. Defer-load if a problem appears.

11. **Phase 1A Gmail notifications + Phase 1C double-coverage.** `messenger_read_recent` already surfaces Gmail notifications as `(app: 'gmail')`. Now the model has two sources for "you have new mail" — the listener and `gmail_list_recent`. **Mitigation:** the system prompt explicitly distinguishes them ("messenger_read_recent — short previews; gmail_* — real messages"). The model should prefer `gmail_*` for any operation beyond "did anything arrive?". If misuse persists, consider a per-package filter in `NotificationStore` that excludes Gmail notifications when `GmailAuthService.isSignedIn() == true`.

12. **Confirm gate refactor risk.** Task 7 refactors the confirmation logic out of `assistant_screen.dart` into a pure function. There is a moderate risk of introducing a regression where the dispatcher no longer dispatches correctly. **Mitigation:** the test added in Task 7 covers gate behaviour; add a separate manual checklist item in Task 8 to verify the dispatcher returns `needs_confirmation:true` on first call by re-running step 8.8 and inspecting the agent transcript.

---

## Notes for the implementer

- **One commit per task.** Match Phase 0/1A discipline.
- **Read `assistant_screen.dart` lines 700–830 and 2350–2425 before touching them.** Phase 1A's `messenger_*` blocks are the exact template — copy their shape, do not invent helpers. Verify by reading the existing `web_search` / `agent_task` / `messenger_read_recent` / `messenger_reply` patterns first.
- **Do not commit the OAuth client ID.** It goes in via `--dart-define=GOOGLE_OAUTH_CLIENT_ID=...` at build time. The default in `GmailConfig` is the empty string; if empty at runtime, `beginInteractiveSignIn` should immediately throw a clear `GmailAuthDenied('GOOGLE_OAUTH_CLIENT_ID not set at build time')` so the failure is loud.
- **No backend changes.** If you find yourself adding files under `~/code/taler-id-backend` — stop. This phase is on-device only.
- **Keep `googleapis` import narrow.** `import 'package:googleapis/gmail/v1.dart' as gmail;` — never `import 'package:googleapis/googleapis.dart';` (huge bundle).
- **Do not register the tools in the text Agent Shell.** Phase 1A made the same call — tools are voice-only because the backend `/agent/run` claude has no access to phone-resident OAuth tokens.
- **Refresh-token cache flow:** be aware that `flutter_appauth.token(...)` with `grantType: 'refresh_token'` does NOT always return a new refresh token (Google sometimes returns only a new access token; preserve the existing refresh token in storage in that case). The reference implementation in Task 3 must `?? existing` when persisting the refresh token after a refresh exchange.
- **Custom URI scheme is case-sensitive.** `tirol.taler.taler_id_mobile.dev:/oauth2redirect` — all lowercase, single slash. Mismatch → silent failure on redirect.
- **Phase 1A's `NotificationStoreNative` is unrelated.** Phase 1C does not touch the listener service. The two features can coexist (and will — Gmail notifications still flow through Phase 1A).

### Critical Files for Implementation

- `/Users/dmitry/Downloads/taler_id_mobile/lib/features/assistant/presentation/screens/assistant_screen.dart` (tool registration after line ~822 inside `tools:` array; dispatcher arms after line ~2406; system prompt RU line ~437 / EN line ~546)
- `/Users/dmitry/Downloads/taler_id_mobile/lib/features/gmail/services/gmail_auth_service.dart` (to create — OAuth flow + token refresh)
- `/Users/dmitry/Downloads/taler_id_mobile/lib/features/gmail/services/gmail_client.dart` (to create — typed wrapper over `gmail.v1.GmailApi`)
- `/Users/dmitry/Downloads/taler_id_mobile/lib/features/gmail/services/gmail_confirm_gate.dart` (to create — pure confirmation-gate function)
- `/Users/dmitry/Downloads/taler_id_mobile/android/app/src/main/AndroidManifest.xml` (add `RedirectUriReceiverActivity` with custom scheme)
- `/Users/dmitry/Downloads/taler_id_mobile/lib/core/di/service_locator.dart` (register `GmailAuthService` + `GmailClient` near line ~261 next to existing Phase 1A registrations)
- `/Users/dmitry/Downloads/taler_id_mobile/android/app/build.gradle.kts` (confirm dev applicationId `tirol.taler.taler_id_mobile.dev` and debug-keystore signing at line 48 — referenced by SHA-1 fingerprint Дмитрий extracts for Google Cloud Console)

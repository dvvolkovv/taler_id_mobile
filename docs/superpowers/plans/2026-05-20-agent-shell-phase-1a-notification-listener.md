# Taler ID Agent Shell — Phase 1A: Notification Listener Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `superpowers:subagent-driven-development` (recommended) or `superpowers:executing-plans` to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

- **Date:** 2026-05-20
- **Branch (mobile):** `feature/agent-shell-phase-1a-notifications` off `feature/agent-shell-phase-0`
- **Depends on:** Phase 0 (closed 2026-05-20) — requires the `agent_task` tool dispatch pattern in `assistant_screen.dart`, the `AGENT_SHELL_AS_HOME=true` flavour, the `AgentShellHomeScreen` route, and the dev APK delivery loop (`taler-id-dev.apk`).
- **Backend changes:** **none.** Everything in this phase is on-device. Notifications never leave the phone.
- **Spec reference:** `docs/superpowers/specs/2026-05-18-taler-agent-shell-design.md`
- **Plan style reference:** `docs/superpowers/plans/2026-05-18-agent-shell-phase-0.md` (the Phase 0 plan — match its task/step shape, TDD discipline, one commit per task).

**Goal:** Give the OpenAI Realtime voice loop two on-device tools — `messenger_read_recent` and `messenger_reply` — backed by an Android `NotificationListenerService` that captures incoming messages from WhatsApp, Telegram, SMS, Gmail and any other messenger that posts a notification. After Phase 1A, Дмитрий can ask out loud "что мне написали за последний час" or "ответь Маше что буду через 20 минут" and the agent will answer / reply via inline `RemoteInput` without opening any other app.

This is the cheapest possible way to reach 95% of incoming-messenger coverage on Android: no rooting, no Accessibility, no per-app integration, no backend. The full Telegram (TDLib) and Gmail (OAuth) clients arrive in Phase 1B/1C and will *supplement* — not replace — this listener.

---

## Goals

1. **Capture incoming notifications** from WhatsApp / Telegram / SMS / Gmail / any messenger app the user has installed, in real time, while the agent shell is running (or in background).
2. **Expose two OpenAI Realtime tools** registered alongside the existing `web_search`/`agent_task`/`start_call` pattern in `assistant_screen.dart`:
   - `messenger_read_recent(filter?)` — returns a slim list of recent notifications.
   - `messenger_reply(notification_key, text)` — fires the inline `RemoteInput` action on the original notification, so WhatsApp/Telegram/etc. actually send the message.
3. **Handle the tools fully on-device** in `_handleFunctionCall` via a Flutter `NotificationService` that talks to a Kotlin `NotificationListenerService` over `MethodChannel`/`EventChannel`. The backend `/agent/run` endpoint is NOT involved — the backend has no access to phone notifications.
4. **Onboarding** that detects missing `Notification access` permission and walks Дмитрий to `Settings → Apps → Special app access → Notification access → Taler ID Dev`.
5. **Update the system prompt** so the model knows when to use the new tools ("Если пользователь спрашивает 'что мне написали' / 'ответь Х' — используй `messenger_read_recent` и `messenger_reply`, НЕ `agent_task`").

## Non-goals

- **Telegram full-client agent (TDLib login by phone + SMS)** — Phase 1B. RemoteInput is enough for replying to existing message threads but not for searching history, sending to new contacts, joining channels, etc.
- **Gmail full client (OAuth, threads, send-from-scratch, attachments)** — Phase 1C. We will see Gmail *notifications* in 1A (subject + sender + preview) and can mark-as-read by tapping the notification action, but composing a new email is out of scope.
- **WhatsApp full Accessibility-driven UI automation** (opening chats, navigating, scraping history beyond what the notification carries) — Phase 1D, only if 1A proves insufficient.
- **iOS** — Apple does not expose third-party notifications to apps. iOS continues with the existing Taler ID Assistant.
- **Cross-device sync of captured notifications** — they stay on this device, in memory.
- **Persistent SQLite store** — kept in-memory for v1; see Open Questions.
- **Notification grouping / dedup beyond the simple `notification_key` from the OS** — relying on `StatusBarNotification.key` is sufficient.
- **Reading message body inside notifications that arrive end-to-end encrypted to the OS but with empty body** (some "smart reply" / E2EE setups). If `text/extras` is empty, we surface what we have.
- **Outgoing-message echo suppression beyond the simple "we just sent it" cache** — see Architecture.
- **Wake-from-stopped-state delivery** (`NotificationListenerService` binding only happens when permission is granted *and* the system rebinds the listener — restarts after force-stop need manual reopen of the app). Out of scope to harden.

---

## Architecture overview

### One-page picture

```
┌─────────────────────────────────────────────────────────────────────┐
│ Other apps (WhatsApp, Telegram, SMS, Gmail, ...) — system process    │
│   post notification                                                   │
└───────────────────────────────┬─────────────────────────────────────┘
                                ▼ (only if user granted Notification access)
┌─────────────────────────────────────────────────────────────────────┐
│ TalerNotificationListenerService extends NotificationListenerService │
│   process: :notifListener (separate from main app process)            │
│                                                                       │
│   onNotificationPosted(sbn):                                          │
│     extract: pkg, title, text, conversationTitle, key, postTimeMs     │
│     extract: list of Notification.Action with RemoteInput results     │
│     skip:   our own package, ongoing/foreground service noise,        │
│             notifications whose key we just replied to (echo)         │
│     route:  send to NotificationBridge (in-memory store + EventSink)  │
│                                                                       │
│   handleReplyRequest(key, text):                                      │
│     look up cached Action.actionIntent + RemoteInput.resultKey        │
│     build Intent with Bundle{resultKey: text} via RemoteInput.add…    │
│     send via PendingIntent.send(...)                                  │
│     mark key as "we just sent" → 30s suppression window               │
└───────────────────────────────┬─────────────────────────────────────┘
                ▲ MethodChannel (reply)   │ EventChannel (posted)
                │                         ▼
┌─────────────────────────────────────────────────────────────────────┐
│ Flutter app (main process)                                            │
│                                                                       │
│   NotificationStore (in-memory ring buffer, ~200 items)               │
│     - subscribes to EventChannel "taler_id/notifications/stream"      │
│     - exposes:  recent(filter)  → List<CapturedNotification>          │
│                  replyOnKey(key, text) → Future<bool>                 │
│                                                                       │
│   NotificationPermissionService                                       │
│     - isNotificationAccessGranted() via MethodChannel                 │
│     - openNotificationAccessSettings()                                │
│                                                                       │
│   _handleFunctionCall(callId, name, args) (in assistant_screen.dart)  │
│     ... existing cases ...                                            │
│     else if name == 'messenger_read_recent' →                          │
│        sl<NotificationStore>().recent(filter).toJson()                 │
│     else if name == 'messenger_reply' →                                │
│        await sl<NotificationStore>().replyOnKey(key, text)             │
│                                                                       │
│   AgentShellHomeScreen banner: "Включи доступ к уведомлениям →"       │
└─────────────────────────────────────────────────────────────────────┘
```

### Why a separate service process

`NotificationListenerService` is bound by `system_server` *outside* the normal app activity lifecycle. It can be alive when the main Flutter engine isn't. That means the bridge from service → Flutter needs to be lazy and idempotent: the service buffers events to a process-shared list (or a tiny SQLite/SharedPreferences-backed queue) and replays whatever's missed when the Flutter engine reattaches.

For v1 we accept that **if the Flutter engine isn't running, posted notifications still get captured in the service's in-RAM buffer**, but their reply intents survive only as long as the service process. When the user opens the app, the service hands over its buffer via the `EventChannel` once a listener attaches; new notifications stream live. Replies issued while the app is open use the cached `Action`/`RemoteInput` held by the service.

### Storage decision (v1)

**In-memory ring buffer in the service process, max 200 entries**, no SQLite / Hive. Rationale:

- Notification data is fundamentally ephemeral — the source apps already store it. We don't need durable history; we need a *live window* for the agent to query "what came in recently?".
- Avoiding SQLite removes one schema migration story, one plugin dependency, and one source of background-write bugs.
- 200 × (~1 KB per entry) = ~200 KB RAM. Fine.
- If Phase 1B later wants history search, we revisit (and at that point TDLib provides Telegram history natively, so the listener still doesn't need durability).

We *do* persist a small **echo-suppression map** (`Map<NotificationKey, sentAtMs>`) in `SharedPreferences` keyed by notification key, with a 60-second TTL, so a restart-mid-reply doesn't cause the agent to re-read its own outgoing message as new incoming.

### Echo suppression

When the user fires `messenger_reply(key, text)`, the messenger app very often posts its own confirmation notification ("Sent" / new entry in the conversation). Without suppression the listener would re-ingest that and the agent could loop ("ты сейчас написала: «...»").

Strategy:

1. On reply success, the service records `(notification_key, text_hash, sentAtMs)` into a `MutableMap` plus mirror to `SharedPreferences`.
2. `onNotificationPosted` checks: for the same `packageName + conversationTitle` (or `tag`) within 30s, if the body text fuzz-matches `text` we just sent (Levenshtein ≤ 3, case-insensitive, trim), DROP the event silently. (Many messengers prefix with "You: " or echo verbatim.)
3. After 60s the entry expires.

This is intentionally conservative — false suppression of a legitimate inbound message that happens to look like our reply is acceptable for v1 (Дмитрий is the only user; he'll notice).

### Permission UX

Android does NOT allow programmatic granting of `BIND_NOTIFICATION_LISTENER_SERVICE`. Detection + redirect only:

```kotlin
val enabled = NotificationManagerCompat.getEnabledListenerPackages(context)
val granted = enabled.contains(context.packageName)
```

To redirect:

```kotlin
Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS)
```

On Android 11+ we can use `ACTION_NOTIFICATION_LISTENER_DETAIL_SETTINGS` with `EXTRA_NOTIFICATION_LISTENER_COMPONENT_NAME` to jump straight to our component's toggle.

The Flutter side polls permission on app resume; if missing it shows a banner on `AgentShellHomeScreen` and a one-shot dialog in the Assistant screen if a relevant tool was attempted without permission.

---

## Task list

### Task 1: Create feature branch + spec-link commit

**Files:**
- No code yet.

- [ ] **Step 1.1** Branch off Phase 0:
  ```bash
  cd /Users/dmitry/Downloads/taler_id_mobile
  git checkout feature/agent-shell-phase-0
  git pull
  git checkout -b feature/agent-shell-phase-1a-notifications
  git push -u origin feature/agent-shell-phase-1a-notifications
  ```
- [ ] **Step 1.2** Add `docs/superpowers/plans/2026-05-20-agent-shell-phase-1a-notification-listener.md` (this file). Commit:
  ```bash
  git add docs/superpowers/plans/2026-05-20-agent-shell-phase-1a-notification-listener.md
  git commit -m "docs(agent-shell): Phase 1A plan — NotificationListenerService"
  ```

**Acceptance:** branch pushed; plan file on remote.
**Tests:** none.
**Time:** ~20 min.
**Depends on:** Phase 0 complete.

---

### Task 2: Android — Manifest + Kotlin scaffold for `TalerNotificationListenerService`

**Files:**
- Modify: `/Users/dmitry/Downloads/taler_id_mobile/android/app/src/main/AndroidManifest.xml`
- Create: `/Users/dmitry/Downloads/taler_id_mobile/android/app/src/main/kotlin/tirol/taler/taler_id_mobile/notifications/TalerNotificationListenerService.kt`
- Create: `/Users/dmitry/Downloads/taler_id_mobile/android/app/src/main/kotlin/tirol/taler/taler_id_mobile/notifications/CapturedNotification.kt` (data class — pkg, key, postTimeMs, title, body, conversationTitle, replyActions, isOurEcho).
- Create: `/Users/dmitry/Downloads/taler_id_mobile/android/app/src/main/kotlin/tirol/taler/taler_id_mobile/notifications/NotificationStoreNative.kt` (singleton ring buffer + echo-suppression map; thread-safe — `ConcurrentLinkedDeque` or `synchronized` block; capped at 200).

- [ ] **Step 2.1** Add to `AndroidManifest.xml` inside `<application>` (next to `<service android:name=".MeshForegroundService"` around line 152):
  ```xml
  <service
      android:name=".notifications.TalerNotificationListenerService"
      android:label="@string/app_name"
      android:exported="true"
      android:permission="android.permission.BIND_NOTIFICATION_LISTENER_SERVICE"
      android:process=":notifListener">
      <intent-filter>
          <action android:name="android.service.notification.NotificationListenerService" />
      </intent-filter>
      <meta-data
          android:name="android.service.notification.default_filter_types"
          android:value="conversations|alerting" />
      <meta-data
          android:name="android.service.notification.disabled_filter_types"
          android:value="ongoing|silent" />
  </service>
  ```
  No new `<uses-permission>` needed — `BIND_NOTIFICATION_LISTENER_SERVICE` is a system-bound permission declared on the `<service>` itself.

- [ ] **Step 2.2** Implement skeletal `TalerNotificationListenerService.kt`:
  - `onListenerConnected` / `onListenerDisconnected` — log.
  - `onNotificationPosted(sbn: StatusBarNotification)` — extract title/text/conv/key, build `CapturedNotification`, push to `NotificationStoreNative.singleton.add(...)`. Skip `pkg == applicationContext.packageName`. Skip if `sbn.notification.flags and (FLAG_FOREGROUND_SERVICE or FLAG_ONGOING_EVENT) != 0`.
  - `onNotificationRemoved` — for now, just log; future work can mark store entries as "dismissed".
  - Public companion method `tryReply(key: String, text: String): ReplyOutcome` (`Sent` / `NoSuchKey` / `NoReplyAction` / `IntentFailure(msg)`) — looks the key up in the store, finds the first `Notification.Action` that has at least one `RemoteInput`, builds the `Bundle` via `RemoteInput.addResultsToIntent`, fires `PendingIntent.send(...)`. On success records echo entry.

- [ ] **Step 2.3** `NotificationStoreNative.kt` — singleton with:
  - `addPosted(n: CapturedNotification)` — checks echo map first; pushes to ring buffer; notifies registered Flutter EventSink (next task).
  - `recent(filter): List<CapturedNotification>` — apply pkg / sender substring / sinceMs / limit.
  - `findByKey(key: String): CapturedNotification?`.
  - `markSelfSent(key: String, body: String, atMs: Long)` plus 60s expiry on `addPosted` lookup.

- [ ] **Step 2.4** Build sanity:
  ```bash
  cd /Users/dmitry/Downloads/taler_id_mobile
  flutter build apk --flavor dev --debug -t lib/main_dev.dart --dart-define=FLAVOR=dev
  ```
  Expected: clean build. (Don't install yet.)

- [ ] **Step 2.5** Commit:
  ```bash
  git add android/app/src/main/AndroidManifest.xml android/app/src/main/kotlin/tirol/taler/taler_id_mobile/notifications/
  git commit -m "feat(notifications): register TalerNotificationListenerService + native store"
  ```

**Acceptance:** APK builds; manifest merger shows the new service under `:notifListener`; service visible in `Settings → Apps → Special access → Notification access` even before any Flutter wiring.
**Tests:** none yet (Kotlin unit-tested in Task 3).
**Time:** 2 h.
**Depends on:** Task 1.

---

### Task 3: Android — `NotificationBridge` MethodChannel + EventChannel + Kotlin unit tests

**Files:**
- Create: `/Users/dmitry/Downloads/taler_id_mobile/android/app/src/main/kotlin/tirol/taler/taler_id_mobile/notifications/NotificationBridge.kt`
- Modify: `/Users/dmitry/Downloads/taler_id_mobile/android/app/src/main/kotlin/tirol/taler/taler_id_mobile/MainActivity.kt` — wire bridge from `configureFlutterEngine`.
- Create: `/Users/dmitry/Downloads/taler_id_mobile/android/app/src/test/kotlin/tirol/taler/taler_id_mobile/notifications/NotificationStoreNativeTest.kt`
- Create: `/Users/dmitry/Downloads/taler_id_mobile/android/app/src/test/kotlin/tirol/taler/taler_id_mobile/notifications/EchoSuppressionTest.kt`

- [ ] **Step 3.1** `NotificationBridge` exposes:
  - `MethodChannel("taler_id/notifications/cmd")` with handlers:
    - `isNotificationAccessGranted` → `Boolean`.
    - `openNotificationAccessSettings` → opens `Settings.ACTION_NOTIFICATION_LISTENER_DETAIL_SETTINGS` (fallback to `ACTION_NOTIFICATION_LISTENER_SETTINGS`).
    - `getRecent(filterMap)` → `List<Map<String,Any?>>` (calls `NotificationStoreNative.singleton.recent(...)` and serialises).
    - `reply(keyString, textString)` → `Map{ok, error?}` (calls `tryReply`).
  - `EventChannel("taler_id/notifications/stream")` with `setStreamHandler` that registers the EventSink on `NotificationStoreNative.singleton.eventSink`. On disconnect, clear sink.

- [ ] **Step 3.2** In `MainActivity.configureFlutterEngine` (near the existing `taler_id/audio` block, line ~148), add:
  ```kotlin
  NotificationBridge(flutterEngine, this)
  ```
  Add import at top.

- [ ] **Step 3.3** Write Kotlin unit tests for `NotificationStoreNative` (use JUnit4, already configured in the project — check `android/app/build.gradle` for `testImplementation 'junit:junit:...'`; add if missing):
  - `addPosted` evicts oldest when over 200.
  - `recent(filter{pkg})` matches package substring.
  - `recent(filter{sinceMinutes:5})` excludes older entries.
  - `recent(filter{sender:"Маша"})` matches `conversationTitle`/`title`.
  - `markSelfSent` then `addPosted` with fuzzy-matching body within 30s → suppressed; outside 60s → admitted.
  - `markSelfSent` → after `addPosted` suppressed, `recent()` does NOT include the suppressed item.

- [ ] **Step 3.4** Run Kotlin tests:
  ```bash
  cd /Users/dmitry/Downloads/taler_id_mobile/android
  ./gradlew :app:testDevDebugUnitTest --tests "*notifications*"
  ```
  Expected: green.

- [ ] **Step 3.5** Commit:
  ```bash
  git add android/app/src/main/kotlin/tirol/taler/taler_id_mobile/notifications/NotificationBridge.kt \
          android/app/src/main/kotlin/tirol/taler/taler_id_mobile/MainActivity.kt \
          android/app/src/test/kotlin/tirol/taler/taler_id_mobile/notifications/ \
          android/app/build.gradle
  git commit -m "feat(notifications): MethodChannel + EventChannel bridge with unit tests"
  ```

**Acceptance:** Kotlin unit tests pass; `MainActivity` wires the bridge once per engine.
**Tests:** Kotlin unit (6+ cases).
**Time:** 2 h.
**Depends on:** Task 2.

---

### Task 4: Flutter — `CapturedNotification` model + `NotificationStore` + tests (TDD)

**Files:**
- Create: `/Users/dmitry/Downloads/taler_id_mobile/lib/features/notifications/models/captured_notification.dart` (Freezed).
- Create: `/Users/dmitry/Downloads/taler_id_mobile/lib/features/notifications/notification_store.dart`.
- Create: `/Users/dmitry/Downloads/taler_id_mobile/lib/features/notifications/notification_filter.dart` (plain value type — `app?`, `sender?`, `sinceMinutes?`, `limit?`).
- Create: `/Users/dmitry/Downloads/taler_id_mobile/test/features/notifications/notification_store_test.dart`.

- [ ] **Step 4.1** Freezed model `CapturedNotification`:
  - `String packageName, key, title, body, conversationTitle?, DateTime postedAt, bool canReply`.
  - `fromMap(Map<String,dynamic>)` constructor for channel decoding.

- [ ] **Step 4.2** TDD: write `notification_store_test.dart` first. Use Mocktail to fake `MethodChannel` (mock the `_invokeMethod` boundary by abstracting into a `NotificationPlatform` interface). Cases:
  - Constructor subscribes to event stream; emitted maps land in `recent()`.
  - `recent(filter: NotificationFilter(app: 'whatsapp'))` filters by packageName containing `'whatsapp'`.
  - `recent(filter: NotificationFilter(sinceMinutes: 10))` excludes older than 10 min.
  - `recent(filter: NotificationFilter(limit: 5))` truncates.
  - `replyOnKey('k1', 'hi')` calls platform `reply` with right args; returns true on `{ok:true}`; throws (or returns false) on `{ok:false, error:...}`.
  - `replyOnKey` rejects with `NoSuchKey` when key not in current store (defensive — actual key may exist in native; treat warning only, still forward to platform).

- [ ] **Step 4.3** Run failing tests:
  ```bash
  cd /Users/dmitry/Downloads/taler_id_mobile
  flutter test test/features/notifications/notification_store_test.dart
  ```
  Expected: red.

- [ ] **Step 4.4** Implement `NotificationStore` (no internal Dart ring buffer — single source of truth is the native store; Dart side caches only what the stream has delivered since subscription, used for the "throw warning if key unknown" check). Implement `NotificationPlatform` thin wrapper over `MethodChannel('taler_id/notifications/cmd')` + `EventChannel('taler_id/notifications/stream')`.

- [ ] **Step 4.5** Tests green; analyze clean:
  ```bash
  flutter test test/features/notifications/notification_store_test.dart
  flutter analyze lib/features/notifications/
  ```

- [ ] **Step 4.6** Run `build_runner` for Freezed:
  ```bash
  dart run build_runner build --delete-conflicting-outputs
  ```

- [ ] **Step 4.7** Commit:
  ```bash
  git add lib/features/notifications/ test/features/notifications/
  git commit -m "feat(notifications): Flutter NotificationStore + Freezed model with tests"
  ```

**Acceptance:** All store tests pass; Freezed `.g/.freezed` files generated.
**Tests:** Dart unit (6+ cases).
**Time:** 2 h.
**Depends on:** Task 3.

---

### Task 5: Flutter — `NotificationPermissionService` + permission banner on `AgentShellHomeScreen`

**Files:**
- Create: `/Users/dmitry/Downloads/taler_id_mobile/lib/features/notifications/notification_permission_service.dart`.
- Modify: `/Users/dmitry/Downloads/taler_id_mobile/lib/features/agent_shell/presentation/screens/agent_shell_home_screen.dart` — add a `MaterialBanner` (or top `Card`) that shows when `isNotificationAccessGranted()` is false; CTA opens settings; re-polls on `AppLifecycleState.resumed`.
- Create: `/Users/dmitry/Downloads/taler_id_mobile/test/features/notifications/notification_permission_service_test.dart`.

- [ ] **Step 5.1** Service:
  ```dart
  class NotificationPermissionService {
    Future<bool> isGranted();
    Future<void> openSettings();
    Stream<bool> watch(); // polls on resume
  }
  ```
- [ ] **Step 5.2** TDD-test mocking `MethodChannel` returns.
- [ ] **Step 5.3** Banner widget integrated into existing screen; copy in Russian:
  > "Чтобы я мог читать сообщения из WhatsApp/Telegram и отвечать за тебя — включи доступ к уведомлениям."
  Button "Открыть настройки" → `openSettings()`.
- [ ] **Step 5.4** Manual smoke (emulator): launch with `AGENT_SHELL_AS_HOME=true`; verify banner appears; tap → settings opens; flip toggle; return to app; banner hides on resume.
- [ ] **Step 5.5** Commit:
  ```bash
  git add lib/features/notifications/notification_permission_service.dart \
          lib/features/agent_shell/presentation/screens/agent_shell_home_screen.dart \
          test/features/notifications/notification_permission_service_test.dart
  git commit -m "feat(notifications): permission service + onboarding banner on agent shell"
  ```

**Acceptance:** Banner visible iff permission missing; settings deep-link works; auto-hides after grant.
**Tests:** Dart unit on the service; manual UI smoke.
**Time:** 1.5 h.
**Depends on:** Task 4.

---

### Task 6: Flutter — DI registration + `assistant_screen.dart` tool registration + dispatcher

**Files:**
- Modify: `/Users/dmitry/Downloads/taler_id_mobile/lib/core/di/service_locator.dart` — register `NotificationPlatform`, `NotificationStore`, `NotificationPermissionService` (singletons) near the existing `AgentClient` registration at ~line 246.
- Modify: `/Users/dmitry/Downloads/taler_id_mobile/lib/features/assistant/presentation/screens/assistant_screen.dart`:
  - In the `tools: [...]` array around lines 700-748 (just below the existing `agent_task` entry), append two new tool definitions.
  - In `_handleFunctionCall` around line 1638 (right after the `web_search` branch), add two `else if` arms.
  - Extend the Russian and English `_systemPrompt` (line 354) usage-guidance sections.

- [ ] **Step 6.1** DI:
  ```dart
  sl.registerLazySingleton<NotificationPlatform>(() => NotificationPlatform());
  sl.registerLazySingleton<NotificationStore>(() => NotificationStore(sl()));
  sl.registerLazySingleton<NotificationPermissionService>(() => NotificationPermissionService(sl()));
  ```

- [ ] **Step 6.2** Tool registration — match the existing entry style verbatim:
  ```dart
  {
    'type': 'function',
    'name': 'messenger_read_recent',
    'description':
        'Read recent messenger notifications (WhatsApp, Telegram, SMS, Gmail, etc.) that arrived on this phone. '
        'Use when the user asks "что мне написали", "есть новые сообщения", "что в Telegram", "кто звонил/писал". '
        'Returns a slim list: sender, app, body, age. '
        'NOT for: searching old history — use the dedicated messenger tools (Phase 1B+). '
        'NOT for: Taler ID in-app conversations — use get_conversations / get_messages.',
    'parameters': {
      'type': 'object',
      'properties': {
        'app': {'type': 'string', 'description': 'Optional substring of the app package name, e.g. "whatsapp", "telegram", "gmail"'},
        'sender': {'type': 'string', 'description': 'Optional substring of sender/conversation title'},
        'since_minutes': {'type': 'integer', 'description': 'Only notifications newer than N minutes (default 120, max 1440)'},
        'limit': {'type': 'integer', 'description': 'Max items to return (default 20, max 50)'},
      },
    },
  },
  {
    'type': 'function',
    'name': 'messenger_reply',
    'description':
        'Send an inline reply to a specific notification you got from messenger_read_recent. '
        'Use only when the user explicitly asks to reply, e.g. "ответь Маше что буду через 20 минут", "напиши в WhatsApp Олегу что согласен". '
        'The notification_key must come from a recent messenger_read_recent call. '
        'Returns ok or an error if the notification no longer has an active reply action.',
    'parameters': {
      'type': 'object',
      'properties': {
        'notification_key': {'type': 'string', 'description': 'The key field from messenger_read_recent'},
        'text': {'type': 'string', 'description': 'The reply text. Plain text only, no markdown.'},
      },
      'required': ['notification_key', 'text'],
    },
  },
  ```

- [ ] **Step 6.3** Dispatcher — copy the exact `_sendEvent({'type':'conversation.item.create', 'item': {'type':'function_call_output', 'call_id': callId, 'output': output}})` shape already used by `web_search` etc.:
  ```dart
  } else if (name == 'messenger_read_recent') {
    final args = argsJson.isEmpty ? <String, dynamic>{} : jsonDecode(argsJson) as Map<String, dynamic>;
    final filter = NotificationFilter(
      app: args['app'] as String?,
      sender: args['sender'] as String?,
      sinceMinutes: (args['since_minutes'] as num?)?.toInt() ?? 120,
      limit: (args['limit'] as num?)?.toInt() ?? 20,
    );
    final granted = await sl<NotificationPermissionService>().isGranted();
    if (!granted) {
      output = jsonEncode({'error': 'notification_access_not_granted', 'hint': 'Скажи пользователю что нужно дать доступ к уведомлениям'});
    } else {
      final items = await sl<NotificationStore>().recent(filter);
      output = jsonEncode({'items': items.map((n) => n.toToolJson()).toList()});
    }
  } else if (name == 'messenger_reply') {
    final args = jsonDecode(argsJson) as Map<String, dynamic>;
    final key = args['notification_key'] as String? ?? '';
    final text = args['text'] as String? ?? '';
    if (key.isEmpty || text.isEmpty) {
      output = jsonEncode({'ok': false, 'error': 'missing notification_key or text'});
    } else {
      try {
        await sl<NotificationStore>().replyOnKey(key, text);
        output = jsonEncode({'ok': true});
      } catch (e) {
        output = jsonEncode({'ok': false, 'error': e.toString()});
      }
    }
  }
  ```
  Then the existing `_sendEvent` call at the end of the dispatcher branch returns the output the same way other tools do. **Verify by reading the `web_search` branch (line ~1663) and matching its shape exactly — do not invent helpers.**

- [ ] **Step 6.4** System prompt — in `_systemPrompt(locale)`, inside the Russian block (line ~414, near the existing "АНАЛИЗ ПЕРЕПИСКИ:" section), insert a new section:
  ```
  ВНЕШНИЕ МЕССЕНДЖЕРЫ (WhatsApp / Telegram / SMS / Gmail):
  Если пользователь спрашивает "что мне написали", "есть новые сообщения", "что в WhatsApp", "что пришло на почту" — используй messenger_read_recent (НЕ agent_task, НЕ get_conversations — это разные источники).
  Если пользователь говорит "ответь [имени] [текст]" / "напиши в WhatsApp/Telegram [имени] [текст]" — сначала messenger_read_recent чтобы найти notification_key, потом messenger_reply.
  Если messenger_read_recent вернул error: notification_access_not_granted — скажи пользователю что нужно открыть Настройки → Доступ к уведомлениям и включить Taler ID Dev. Не вызывай инструмент ещё раз пока пользователь не подтвердит.
  ВАЖНО: messenger_reply работает ТОЛЬКО для уведомлений из последних ~200 сообщений (живой буфер). Для старых — пока невозможно ответить.
  ```
  Mirror in the English block.

- [ ] **Step 6.5** Compile + analyze:
  ```bash
  flutter analyze lib/
  ```

- [ ] **Step 6.6** Commit:
  ```bash
  git add lib/core/di/service_locator.dart \
          lib/features/assistant/presentation/screens/assistant_screen.dart
  git commit -m "feat(assistant): register messenger_read_recent + messenger_reply tools"
  ```

**Acceptance:** Code compiles, no analyzer errors, system prompt mentions the tools.
**Tests:** No new dart tests (the handler is thin glue over `NotificationStore` already tested). Manual smoke in Task 8.
**Time:** 1.5 h.
**Depends on:** Tasks 4, 5.

---

### Task 7: Echo suppression — integration test on real device + tuning

**Files:**
- Modify (if needed): `NotificationStoreNative.kt` — tune Levenshtein threshold / TTL.
- Create: `/Users/dmitry/Downloads/taler_id_mobile/android/app/src/androidTest/kotlin/tirol/taler/taler_id_mobile/notifications/EchoSuppressionInstrumentedTest.kt` (uses `NotificationManager.notify` to post + remove fake notifications; runs on connected device or emulator with notification access granted to the test instrumentation pkg). If instrumentation against `NotificationListenerService` proves flaky, fall back to unit-testing the suppression *logic* (already done in Task 3) and document a manual smoke procedure here.

- [ ] **Step 7.1** Write the suppression instrumented test OR — if it can't run reliably — a script in `docs/superpowers/journals/2026-05-2X-phase-1a-echo-tuning.md` describing manual steps: send a real WhatsApp message → app fires `messenger_reply` → observe that the resulting "You: ..." notification is NOT re-ingested (verify by inspecting `recent()` for a 60s window).
- [ ] **Step 7.2** Run it; tune Levenshtein/TTL until the WhatsApp + Telegram + SMS triple-test all suppress correctly without dropping the next inbound message.
- [ ] **Step 7.3** Commit any tuning + the test:
  ```bash
  git add android/app/src/androidTest/ android/app/src/main/kotlin/tirol/taler/taler_id_mobile/notifications/NotificationStoreNative.kt
  git commit -m "test(notifications): echo suppression instrumentation + tuned thresholds"
  ```

**Acceptance:** Sending a reply via the tool does NOT cause an immediate re-ingest of the same body; an inbound message arriving 90 s later DOES get through.
**Tests:** Instrumented (preferred) or documented manual.
**Time:** 1.5 h.
**Depends on:** Task 6, plus a real Android device or working emulator.

---

### Task 8: End-to-end smoke on Pixel + journal entry

**Files:**
- Modify: `/Users/dmitry/Downloads/taler_id_mobile/docs/superpowers/journals/2026-05-20-agent-shell-phase-0-daily-driver.md` (append Phase 1A section) or create new journal `2026-05-2X-agent-shell-phase-1a.md`.
- No code.

- [ ] **Step 8.1** Build dev release APK:
  ```bash
  cd ~/Downloads/taler_id_mobile && flutter build apk --flavor dev --release -t lib/main_dev.dart \
       --dart-define=FLAVOR=dev \
       --dart-define=BASE_URL=https://staging.id.taler.tirol \
       --dart-define=AGENT_SHELL_AS_HOME=true
  ```
- [ ] **Step 8.2** Install on the Pixel (`adb -s 78c0742f install -r ...`). Open the app; observe banner; tap → settings → enable Taler ID Dev under Notification access; return.
- [ ] **Step 8.3** From another phone, send a WhatsApp message to Дмитрий: "Привет, это тест 1A".
- [ ] **Step 8.4** Open Assistant; say: *"Что мне написали в WhatsApp?"* Expected: the model calls `messenger_read_recent({app:'whatsapp'})`, then speaks back "Тебе написали в WhatsApp: «Привет, это тест 1A» от …".
- [ ] **Step 8.5** Say: *"Ответь: я занят, перезвоню вечером."* Expected: model calls `messenger_reply` with the captured key; the message lands in WhatsApp on the other phone within ~2 s.
- [ ] **Step 8.6** Repeat for Telegram and SMS. Note quirks per app.
- [ ] **Step 8.7** Append journal section with: latency observations, apps where it worked / didn't, edge cases (E2EE messages with empty body, group chats, media-only messages, language detection problems).
- [ ] **Step 8.8** Commit:
  ```bash
  git add docs/superpowers/journals/
  git commit -m "docs(agent-shell): Phase 1A daily-driver field notes"
  ```

**Acceptance:** Voice → tool → real WhatsApp+Telegram+SMS reply works on Pixel; journal entry exists with observations.
**Tests:** End-to-end manual.
**Time:** 1 h (assuming build & install go smoothly).
**Depends on:** Task 7.

---

### Task 9 (optional): Notification feed surface on `AgentShellHomeScreen`

**Files:**
- Modify: `/Users/dmitry/Downloads/taler_id_mobile/lib/features/agent_shell/presentation/screens/agent_shell_home_screen.dart`.

Add a collapsible list ("Recent inbox", default-collapsed) under the chat input that subscribes to `NotificationStore.stream()` and shows the last 5 captured notifications with tap-to-open-in-original-app (`PackageManager.getLaunchIntentForPackage`). This is *not required* for the tool to work — the agent is the primary surface — but it makes the listener visibly working without needing voice, useful for debugging and for confidence in the daily-driver.

- [ ] Implement; manual verify.
- [ ] Commit `git commit -m "feat(agent-shell): show recent captured notifications under chat"`.

**Acceptance:** Live notifications appear in the list as they arrive.
**Tests:** Widget test that the list rebuilds on `NotificationStore` stream emissions.
**Time:** 1.5 h.
**Depends on:** Task 8 (so we know the pipeline works first).

---

## Phase 1A Exit Criteria — Sign-off Checklist

- [ ] `NotificationListenerService` registered, visible in `Settings → Apps → Special app access → Notification access` as "Taler ID Dev".
- [ ] All Kotlin unit tests pass: `./gradlew :app:testDevDebugUnitTest`.
- [ ] All Dart tests pass: `flutter test`.
- [ ] `flutter analyze` clean on the new directories.
- [ ] APK builds for dev flavor without errors.
- [ ] Permission banner appears on `AgentShellHomeScreen` when access not granted; disappears on grant.
- [ ] Voice end-to-end: spoken "что в WhatsApp?" → `messenger_read_recent` → spoken summary, within ~3 s.
- [ ] Voice end-to-end: spoken "ответь: ..." → `messenger_reply` → message visible on the other party's device.
- [ ] Echo suppression: replying does not cause the model to re-read its own outgoing message.
- [ ] Journal entry recorded with at least one real day of usage.
- [ ] No backend code changed; no new npm packages on backend.
- [ ] PROD untouched.

When all checked: open Phase 1B (Telegram TDLib) plan.

---

## Open questions

1. **Default `since_minutes` window — 60, 120 or 1440?** Default 120 here is a guess. If Дмитрий typically asks "что нового" first thing in the morning, 1440 (24 h) might be more useful. Tunable after Day 2 of journal.
2. **Multi-line bodies and media messages.** Some messengers post `text` = `"📷 Photo"` or `"🎤 Voice message"`. Should the tool surface these literally, hide them, or transform to `"[фото]" / "[голосовое]"`? Decide after Task 8.
3. **Group chat sender attribution.** WhatsApp groups put the group name in `conversationTitle` and the sender name as the line prefix in `body` (`"Маша: ..."`). Telegram uses `EXTRA_TITLE_BIG` / `MessagingStyle`. Worth one extra `extractGroupSender()` helper if we want clean fields, but defer to v1.1 if it takes too long.
4. **Should we cache notification icons / sender avatars** so the optional Task-9 list looks decent? Skipping for v1 — text-only.
5. **Persist captured notifications across app/device restart?** Currently no (in-RAM ring buffer in `:notifListener` process). If `:notifListener` is killed by the OS, the buffer is lost but new notifications resume capture on next bind. Decide whether SharedPreferences-mirrored last-50 is worth the extra code.
6. **Snooze / mark-as-read.** `NotificationListenerService` can `cancelNotification(key)`. Worth exposing as a third tool `messenger_dismiss(key)`? Likely yes but deferred — adds nothing to "read + reply" core promise.
7. **Privacy mode in lockscreen.** If lockscreen privacy hides notification body, our listener still receives the full content (the OS only hides it from the UI, not from listeners). Worth confirming on the Pixel and documenting in the journal.
8. **Per-app allow/deny.** v1 captures every notification regardless of app. A user-facing allow-list (only WhatsApp, Telegram, SMS, Gmail) might be more privacy-friendly. Defer to a settings screen post-1A.
9. **English vs Russian system-prompt section.** Phase 0 keeps both. Match that — but verify the existing English block isn't out of date relative to Russian first.

---

## Risks (≥ 5)

1. **`NotificationListenerService` lifecycle is opaque.** The OS rebinds the listener whenever it wants, and on some OEMs (not stock Pixel) the service is killed aggressively or skipped after force-stop. **Mitigation:** target stock Pixel (Дмитрий's device); document re-grant procedure in the journal; explicitly note it as a known limitation; do NOT promise background-survivability beyond stock Android.
2. **RemoteInput shape differs per app.** WhatsApp uses Wear-style `Notification.Action.WearableExtender`; Telegram uses the standard `Notification.Action.Builder().addRemoteInput`; SMS uses `RemoteInput` via the default SMS app's action; Gmail's "reply" action sometimes only opens the compose UI rather than accepting inline text. **Mitigation:** the service iterates all actions and picks the first that returns a non-null `remoteInputs` array; failing apps surface a clear `error: no_reply_action` to the agent so it tells the user "WhatsApp принял, в Gmail не получилось — нужно открыть приложение". Task 8 lists per-app compatibility.
3. **PendingIntent.send fails silently or with `CanceledException`.** If WhatsApp clears the notification before we click reply, the intent is cancelled. **Mitigation:** wrap in try/catch; report `error: pending_intent_cancelled`; agent re-fetches recent and asks user to retry.
4. **Echo suppression false positives / negatives.** Levenshtein-based matching could drop legitimate inbound messages that happen to look like our reply (e.g. user replies "ok", contact also replies "ok"). **Mitigation:** key the suppression on `notification_key + body fuzz match within 60 s` — same key means same conversation, so the worst case is missing one duplicate "ok" within a one-minute window. Acceptable for v1; tune in Task 7. Single-user product = single user can notice + reroll.
5. **Notification content can be empty / encrypted.** Signal, WhatsApp E2EE pre-decrypted notifications, FCM "data-only" pushes — `text` and `title` come through as `""` or "New message". **Mitigation:** return what we have; agent says "тебе пришло сообщение в Signal, тело недоступно — открой приложение".
6. **Separate `:notifListener` process means no easy direct call from Flutter.** Flutter's `MethodChannel` runs in the *main* process; calling into the listener service requires either a bound `Service`, or — simpler — keeping the singleton `NotificationStoreNative` in the listener's process and using a `Messenger`/`AIDL` IPC, or **easier**: declare the listener to run in the SAME process by removing `android:process=":notifListener"`. **Mitigation:** the cleanest v1 is **single-process** — drop `:notifListener`. Use a separate process only if we observe RAM bloat from Flutter engine while listening. Decide in Task 2 during implementation; default to single-process unless a concrete reason emerges. Updating the plan: remove `android:process` from the manifest snippet if going single-process.
7. **Notification access toggle revoked by user.** OS silently disables our service; events stop flowing. **Mitigation:** the polling-on-resume + banner from Task 5 handles this; agent gets a clear `error` payload if a tool fires while disabled.
8. **Voice-loop UX confusion.** Agent might call `messenger_read_recent` *and then* `get_conversations` because both look like "messages". **Mitigation:** the new system-prompt section in Task 6 explicitly distinguishes Taler ID in-app chats (`get_conversations`) from external messenger notifications (`messenger_read_recent`). Verify in Task 8.
9. **Gmail OAuth / push tokens collision (Phase 1C).** When Phase 1C lands and we have real Gmail OAuth, both paths will surface Gmail messages — once as a notification, once as a real Gmail thread. **Mitigation:** out of scope here; flag for Phase 1C plan (it should suppress Gmail notifications in `NotificationStore` once the real Gmail client is connected, by adding a per-package filter).

---

## Notes for the implementer

- **One commit per task.** Match Phase 0 discipline.
- **Read `assistant_screen.dart` before touching it.** It's large; only the two narrow regions identified in Task 6 should change. Use `web_search` / `start_call` as the dispatcher template — same variable names (`callId`, `output`, `_sendEvent(...)` shape).
- **Keep the Kotlin side small.** No Coroutines required; a `ConcurrentLinkedDeque` + `synchronized` works for v1. If you reach for `kotlinx.coroutines` you're probably over-engineering.
- **Do NOT add `flutter_local_notifications` or `awesome_notifications`.** Those *post* notifications; we need to *listen* to others'. Direct platform channel is the right primitive.
- **No new pubspec dependency expected** — Freezed, `flutter_bloc`, `get_it`, `mocktail`, `dio` already in. Verify.
- **Process-decision (`android:process=":notifListener"` vs single-process)** — see Risk 6. Default to single-process; revisit if RAM/battery shows up in the journal.

### Critical Files for Implementation

- `/Users/dmitry/Downloads/taler_id_mobile/android/app/src/main/AndroidManifest.xml`
- `/Users/dmitry/Downloads/taler_id_mobile/android/app/src/main/kotlin/tirol/taler/taler_id_mobile/MainActivity.kt`
- `/Users/dmitry/Downloads/taler_id_mobile/android/app/src/main/kotlin/tirol/taler/taler_id_mobile/notifications/TalerNotificationListenerService.kt` (to create)
- `/Users/dmitry/Downloads/taler_id_mobile/lib/features/assistant/presentation/screens/assistant_screen.dart` (tool registration ~700-748 and dispatcher ~1638-1747; system prompt at 354)
- `/Users/dmitry/Downloads/taler_id_mobile/lib/features/notifications/notification_store.dart` (to create — Dart-side store + platform bridge)

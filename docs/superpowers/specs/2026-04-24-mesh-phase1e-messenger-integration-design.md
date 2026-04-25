# Mesh Phase 1e — Messenger Integration (Minimal MVP)

**Date:** 2026-04-24
**Status:** Design approved, ready for implementation planning

**Working dir:** `~/Downloads/taler_id_mesh/` — branch `feature/mesh-network` (off `dev`). No backend changes.

---

## 1. Executive Summary

Phase 1e makes the mesh subsystem user-facing in the existing messenger: when the server is unreachable and a contact is visible on the local network, the app transparently delivers the message through mesh instead of queuing it. Adds a minimal Settings section that shows mesh activity and a transport badge in the chat header so users can tell which path a message took.

**Scope:** Minimal MVP per the phase-1e option A approved during brainstorming. Event-mode QR, gateway bridge, voice badge, group chats, and files over mesh are all explicitly deferred.

**Key behaviors introduced:**
- Server-first routing with mesh as offline fallback. If Socket.io is `connected`, send goes through the server as before. If disconnected and the peer is visible in the local mesh, send goes through `MeshMessagingService` over Bonjour/TCP.
- Mesh-delivered messages are stored locally on each device only. No server sync. Clearly marked in UI as "via mesh" so the user understands the history isn't on the server.
- A toggleable runtime flag (default ON) lets the user opt out of mesh fallback entirely.

**Why minimal:** end-to-end cross-platform Noise messaging over Bonjour/TCP is already proven on real hardware (Phase 1d hardware validation). Phase 1e just wires that plumbing into the messenger UI. Event QR and backend bridge are material amounts of work with separate design decisions; they go to Phase 1f and Phase 2 respectively.

---

## 2. Decision Log

| # | Question | Decision | Rationale |
|---|----------|----------|-----------|
| 1 | Phase 1e scope | A: minimal MVP — Settings + chat integration + badge | Delivers offline-send with zero backend work; isolates risk |
| 2 | When to use mesh | A: server-first, mesh only when server unreachable | Invisible in the normal case, only "wakes up" when internet is out |
| 3 | Persistence of mesh messages | C: local-only, no server sync in Phase 1e | Server bridge is Phase 2 gateway work; don't ship a half-baked retry queue |
| 4 | Unreachable detection | A: Socket.io `connected` state | Reuses existing messenger machinery; timeout refinements deferred |
| 5 | BLE data flow | Out of Phase 1e | Peripheral GATT gap from Phase 1d final review; Phase 1d.5 covers it |
| 6 | Feature flag | Runtime toggle `mesh.offlineFallback` (default ON) | User can disable mesh entirely without recompile |

---

## 3. Goals & Non-Goals

### Goals

1. Transparent mesh fallback when Socket.io is disconnected and a contact peer is visible on local WiFi.
2. Settings section showing mesh status (active/inactive, peer count) and the `offlineFallback` toggle.
3. Transport badge in `ChatRoomScreen` header: server / mesh / offline.
4. Per-message "via mesh" indicator for messages delivered through the mesh path.
5. Auto-fetch of a contact's device certs when their chat is opened, so mesh can authenticate their peer on first discovery.
6. Replaces the Phase 1d `_placeholderUserId` in `service_locator.dart` with the real JWT user id so `DeviceKeySyncService.registerOwnDevice` actually works against the deployed backend.

### Non-Goals (Phase 1e)

- Event QR launch/scanner (Phase 1f)
- Gateway bridge / mesh↔server message sync (Phase 2)
- Group chats over mesh (Phase 2)
- File transfer over mesh (Phase 2)
- Voice call transport badge (Phase 3)
- `"Prefer mesh always"` toggle — only offline fallback is user-visible
- True multi-hop routing (Phase 2)
- BLE data path (Phase 1d.5, blocked on peripheral GATT)
- Server-side dedup for any future retry queue (Phase 2)

---

## 4. Architecture

### File layout

```
lib/features/messenger/
├── data/
│   └── services/
│       ├── mesh_messenger_adapter.dart       # NEW — bridge InboundMessage → Message
│       └── transport_selector.dart           # NEW — server / mesh / offline policy
└── presentation/
    └── widgets/
        └── chat_transport_badge.dart         # NEW — 🌐 / 📡 / 🌐⚠ in chat header

lib/features/mesh/                            # NEW feature module
├── domain/
│   └── entities/
│       └── mesh_status.dart                  # peer count + current transport state
└── presentation/
    ├── bloc/
    │   └── mesh_status_bloc.dart             # watches transport, exposes state stream
    └── widgets/
        └── mesh_settings_section.dart        # "Mesh network" card in Settings

lib/core/di/
└── service_locator.dart                      # wire real JWT userId, register new services
```

### Component responsibilities

**`TransportSelector`** (pure function wrapper)

```dart
enum TransportChoice { server, mesh, offline }

class TransportSelector {
  TransportSelector({
    required bool Function() isSocketConnected,
    required bool Function(String contactUserId) isPeerVisibleFor,
    required bool Function() offlineFallbackEnabled,
  });

  TransportChoice chooseFor(String contactUserId);
}
```

- If Socket.io connected → `server`.
- Else if user has `offlineFallback` ON AND peer visible for this contact → `mesh`.
- Otherwise → `offline` (existing pending-queue behavior unchanged).

**`MeshMessengerAdapter`**

Bridges `MeshMessagingService` (transport-level) and `MessengerRepository` (app-level):
- On inbound mesh message: `lookupUserByDevice(devicePk)` → real `userPk` → resolve to Taler ID `contactUserId` via `ContactsCacheService` → find or create local `Conversation` → emit a `Message` object with `transport: 'mesh'` to `MessengerBloc`.
- On outbound mesh send: constructs the proper `DeviceInfo` mapping, calls `MeshMessagingService.sendText(toUserPk, text)`, then persists the message locally with `meshOnly: true` so it shows in history even without server ACK.

**`MeshStatusBloc`**

Subscribes to `MeshTransport.discoveries` / `losses`. Exposes a `Stream<MeshStatus>` consumed by `MeshSettingsSection` and `ChatTransportBadge`. State includes:
- `running: bool`
- `peerCount: int`
- `Map<String, bool> visibilityByContactUserId` — populated by resolving discovered devicePks to known contacts through `HiveContactKeyStore`

**`MessengerRepositoryImpl`** (modified)

`sendMessage()` gains a branch point: it calls `TransportSelector.chooseFor(contactUserId)` and dispatches accordingly — existing `server` path unchanged, `mesh` routes via `MeshMessengerAdapter`, `offline` goes to the existing pending queue.

---

## 5. Data Flow

### Outbound — send a message

```
User tap "Send" → ChatRoomScreen → MessengerBloc.add(SendMessage)
                                      │
                  MessengerRepository.sendMessage()
                                      │
              ┌───── TransportSelector.chooseFor(contactUserId)
              │
              ├─ server:   (unchanged) Dio POST → server broadcasts via socket
              │
              ├─ mesh:
              │   ├─ MeshMessagingService.sendText(toUserPk = devicePkOfContact, text)
              │   │   ├─ Noise IK handshake on first send (msg1/msg2)
              │   │   └─ ChaCha20-Poly1305 encrypt → Frame → MultiTransport.send → Bonjour/TCP
              │   └─ MeshMessengerAdapter.persistLocally(text, convId, transport='mesh')
              │       writes to MessengerCacheService with meshOnly=true,
              │       emits Message to MessengerBloc for UI
              │
              └─ offline: (unchanged) PendingMessageService.queue(...)
```

### Inbound — receive a message

```
BonjourTransport gets TCP Frame
         │
MultiTransport.inbound emits InboundFrame
         │
MeshMessagingService._onInboundFrame (Noise decrypt + session)
         │
  emits InboundMessage(fromUserPk = devicePk, text)
         │
MeshMessengerAdapter.onInbound
  ├─ HiveContactKeyStore.lookupUserByDevice(devicePk) → real userPk
  ├─ resolve userPk → contactUserId via ContactsCacheService
  ├─ find existing Conversation, else create local (meshOnly=true)
  └─ emit Message(transport='mesh') into MessengerBloc inbound stream
         │
ChatRoomScreen renders with 📡 indicator
```

### Chat open — side-effect to prime mesh auth

```
ChatRoomScreen.initState
  └─ DeviceKeySyncService.fetchContactKeys(contact.userId)  // fire-and-forget
        └─ writes contact's device certs to HiveContactKeyStore
              → mesh can now authenticate that contact's devicePk
                when it's seen via Bonjour
```

Idempotent: subsequent opens of the same chat within the last 5 minutes are deduped. Avoids hammering the backend when the user taps in/out of chats.

---

## 6. UI Details

### Settings — Mesh network section

Placement: between "Application" and "Voice assistant" in `settings_screen.dart`.

```
┌────────────────────────────────────────┐
│ 📡 Mesh network                        │
├────────────────────────────────────────┤
│ ⦿ Active                               │
│ 4 peers visible nearby                 │
│                                        │
│ ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ │
│ Use mesh offline          [ toggle ]   │
│                                        │
│ When the server is unreachable, send   │
│ messages via nearby peers.             │
│                                        │
│ ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ │
│ View debug →                           │
└────────────────────────────────────────┘
```

- Status dot: green `⦿ Active` when transport is running, grey `⦾ Inactive` otherwise.
- Peer count: from `MeshStatusBloc.peerCount` — both Bonjour and BLE peers counted.
- Toggle persists to SharedPreferences under `mesh.offlineFallback`, default ON.
- "View debug" deep-links to the existing `MeshDebugScreen` (dev-flavor only, same as Phase 1d).

### ChatRoomScreen — transport badge in header

Small icon to the right of the contact's name, left of the existing call/options buttons.

| State | Icon | Meaning |
|-------|------|---------|
| socket connected | 🌐 (green) | server path, normal |
| socket off + mesh peer visible | 📡 (blue) | mesh path active |
| socket off + no mesh peer | 🌐⚠ (yellow) | queued, waiting |

Live updates via `MeshStatusBloc.state + MessengerBloc.socketState`. Long-press → modal bottom-sheet with peer details (hex prefix, host, transport kind).

### Per-message indicator

Messages with `transport == 'mesh'` get a small grey line under the bubble: `via mesh · HH:MM`. Server messages stay visually unchanged.

---

## 7. Persistence & Conversation Model

### Mesh-only conversation

When a mesh message arrives from a contact who has no existing server conversation (e.g. user added them via contacts but never chatted before they went offline), the adapter creates a local `Conversation` with:
- Standard `ConversationEntity` shape (contactUserId, conversationId synthesized locally as `meshOnly:<contactUserId>:<timestamp>`)
- Field `meshOnly: true` stored in `MessengerCacheService`

When the server comes back later, the UI shows this chat alongside server chats. Opening it shows only the mesh-delivered messages. If the user sends a new message while online, it goes through server under a new `conversationId` (server-issued); the two histories are independent — explicitly accepted per decision #3.

### Message record fields added

`MessengerCacheService` cache entries gain:
- `transport: String` — `"server"` | `"mesh"`
- `meshOnly: bool` — true if conversation is mesh-only, false if server-originated

Both fields default to server-compatible values so existing cache entries stay readable.

---

## 8. DI Wiring Changes

### Service locator (Phase 1e)

```dart
// Phase 1c leftover — REPLACE with real JWT user id lookup
// Old: myUserId: _placeholderUserId()
// New: myUserId: await _resolveCurrentUserIdFromJwt(storage)
```

`_resolveCurrentUserIdFromJwt` decodes the `sub` claim from the access token stored in `SecureStorageService`. If no token (logged out), `DeviceKeySyncService` registration is deferred until login completes.

### New registrations

```dart
sl.registerLazySingleton<TransportSelector>(
  () => TransportSelector(
    isSocketConnected: () => sl<MessengerBloc>().isSocketConnected,
    isPeerVisibleFor: (userId) => sl<MeshStatusBloc>().state.visibilityByContactUserId[userId] ?? false,
    offlineFallbackEnabled: () => sl<SharedPreferences>().getBool('mesh.offlineFallback') ?? true,
  ),
);

sl.registerLazySingleton<MeshMessengerAdapter>(
  () => MeshMessengerAdapter(
    meshMessaging: sl<MeshMessagingService>(),
    contactKeyStore: sl<HiveContactKeyStore>(),
    contactsCache: sl<ContactsCacheService>(),
    messengerCache: sl<MessengerCacheService>(),
  ),
);

sl.registerLazySingleton<MeshStatusBloc>(
  () => MeshStatusBloc(
    transport: sl<MeshTransport>(),
    contactKeyStore: sl<HiveContactKeyStore>(),
  ),
);
```

`MeshMessagingService` itself — currently not registered in DI. Phase 1e registers it here, using keys already in DI from Phase 1c (MeshStaticKey for priv/pub).

### AuthBloc integration

On `AuthLoginSuccess`, after session is established:
- Fire `sl<DeviceKeySyncService>().registerOwnDevice()` once (already present but dormant under placeholder id).
- Kick `MeshMessagingService.start()` to begin advertising + accepting mesh messages.

On `AuthLogout`:
- Call `MeshMessagingService.stop()` and `MeshStatusBloc.reset()`.

---

## 9. Testing

### Unit tests

- `transport_selector_test.dart` — matrix: all combinations of socket-connected × peer-visible × offline-fallback-enabled
- `mesh_messenger_adapter_test.dart`:
  - InboundMessage with known contact → emits Message on existing Conversation
  - InboundMessage with unknown sender devicePk → dropped (not a contact)
  - InboundMessage with contact but no existing Conversation → creates mesh-only conversation
  - outbound sendMessage → MeshMessagingService.sendText called, message persisted locally with `meshOnly=true`
- `mesh_status_bloc_test.dart` — discovery event → visibility map updated; loss event → removed; multiple peers for same contact counted as visible

### Widget tests

- `chat_transport_badge_test.dart` — renders correct icon per state triple
- `mesh_settings_section_test.dart` — status label matches `MeshStatusBloc` state; toggle writes to prefs

### Hardware integration (manual)

- Same WiFi, both online: send through server, badge 🌐, no "via mesh" marker
- Same WiFi, force `socket.disconnect()` from dev-tools on one device: send falls back to mesh, badge 📡, recipient receives with "via mesh" marker, conversation persists after reconnect
- iPhone ↔ Android cross-platform: all scenarios

### Regression

Existing messenger tests (`messenger_bloc_test.dart` + `messenger_repository_test.dart`) must stay green. Phase 1e adds a branch point in `sendMessage` — tests for the existing branch should be unchanged.

---

## 10. Risks & Mitigations

| Risk | Impact | Mitigation |
|------|--------|-----------|
| Mesh delivery looks like server message and user thinks history is synced | Data loss surprise when they switch devices | Explicit "via mesh" marker per message + Settings copy explaining local-only |
| `_placeholderUserId` → real JWT swap breaks Phase 1d flag-off scenario | App crashes on startup if no login | Guard: if no JWT, skip `registerOwnDevice()` entirely, mesh works but unregistered |
| TransportSelector picks mesh during a brief Socket.io reconnect window | User sees 📡 briefly even on good network | Debounce: wait 2s after `socket.disconnected` event before switching choice |
| Contacts cache stale → adapter can't map devicePk → contactUserId | Mesh message appears "from unknown sender" | Drop silently (don't surface), log warning; user refreshes contacts → next delivery maps correctly |
| SharedPreferences toggle + bloc out of sync | Toggle change doesn't immediately affect active sessions | `MeshStatusBloc` listens to prefs via `PrefsService.watch(...)`, replays on change |
| Phase 1d BLE reconnect loop causes peer-count churn | Settings UI number flickers | `MeshStatusBloc` throttles updates to 500ms; Settings shows steady number |

---

## 11. Rollout

1. Land to `feature/mesh-network` with runtime toggle default ON in dev flavor.
2. Existing Phase 1a-1d code and tests should stay green; new tests added.
3. Deploy to DEV via existing mobile `dev` branch flow (no backend change).
4. Manual QA: iPhone ↔ Android on one WiFi, turn WiFi off → on a pair; verify badge transitions and message delivery.
5. If stable after one week of internal testing, flip toggle default ON in prod flavor and ship via next TestFlight build.

No backend changes. No migration. Backward-compatible with existing server messenger behavior — if mesh is off, nothing observable changes.

---

## 12. Next Steps

1. User review of this spec.
2. Feedback incorporated if any.
3. Invoke `writing-plans` → detailed implementation plan broken into tasks.
4. Execute via subagent-driven-development (same pattern as Phase 1c/1d).

---

## Appendix A — Socket.io integration point

Existing `MessengerBloc` holds the Socket.io connection and exposes a `ValueNotifier<bool> socketConnected`. `TransportSelector.isSocketConnected` reads this. No changes to Socket.io setup — Phase 1e only observes it.

## Appendix B — HiveContactKeyStore invariant used

Phase 1c stores: `devicePk → DeviceCert` where cert has `userPk`. And `userPk → Set<devicePk>` via the device list. Phase 1e's `MeshMessengerAdapter` uses `lookupUserByDevice(devicePk)` to get `userPk`, then maps `userPk → contactUserId` via `ContactsCacheService.findByUserPk` (new helper added in Phase 1e — small addition). This mirrors what Phase 1b established on the backend side.

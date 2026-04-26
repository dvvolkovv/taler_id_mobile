# Mesh Phase 2 — Group Chats Implementation Design

**Date:** 2026-04-26
**Status:** Approved, ready for implementation planning

**Working dir:** `~/Downloads/taler_id_mesh/` — branch off `dev`. No backend changes.

---

## 1. Executive Summary

Phase 1 (1f → 1k) shipped 1:1 mesh messaging via Noise IK over Bonjour. Server-side group chats (`type: 'GROUP'`, `participantIds: List<String>`) work through normal REST/Socket.IO fanout but never use mesh — `_resolveContact` returns null for groups and TransportSelector falls through to server-only.

Phase 2.0 makes group chats mesh-aware while keeping the design simple: **mesh is an optimisation layer over the server**, not a replacement. The sender always invokes the server send (when socket is connected) and additionally fans out pairwise Noise sessions to every visible+known group member. Receivers may get the same logical message twice (once via mesh, once via server echo) and deduplicate by a shared `clientTempId`.

This phase is intentionally narrow: text + system messages only. Reactions, edits, deletes, and files stay server-only and ship as later phases.

---

## 2. Decision Log

| # | Question | Decision | Rationale |
|---|----------|----------|-----------|
| 1 | Crypto model | C: pairwise Noise IK to each peer; group keys deferred | Reuses Phase 1 stack as-is. Trade-off (N copies for N members) acceptable for typical group size <10. |
| 2 | Fanout policy | A: hybrid — visible-via-mesh + always server | Best UX (everyone gets it via fastest available path). Dedup needed; clientTempId already exists. |
| 3 | Phase 2.0 scope | A: text + system messages only | Reactions/edit/delete/files are independent feature work; keep Phase 2.0 small. |
| 4 | Wire format | A: bump frame version to 2; encrypted JSON envelope for ALL messages (1:1 too) | Unified format across 1:1 and group; `convId` lives in plaintext-of-cipher (still authenticated by Noise). 1:1 v1 → v2 is breaking — see §10. |
| 5 | clientTempId scheme | UUID v4 (replace Phase 1h's `temp_<millis>`) | Safety against collisions when two senders in the same group emit in the same millisecond. |
| 6 | Group size limit (sanity) | 50 mesh-eligible peers per send; over → server-only | Predictable worst-case for transport stack. |

---

## 3. Goals & Non-Goals

### Goals

1. Sending a text message in a server-side group conversation reaches every visible+known peer via mesh AND every member via server (when server is reachable).
2. Receiver-side dedup means each recipient sees exactly one MessageEntity per logical message regardless of how many transports delivered it.
3. Mesh latency for visible peers stays under 100ms in the group case (matches 1:1 baseline from Phase 1k).
4. 1:1 mesh remains functional after the wire format upgrade (envelope wrapping, same crypto stack).
5. All existing 390+ unit tests stay green; new tests cover envelope encoding, group fanout, and dedup paths.

### Non-Goals (Phase 2.0)

- Group keys / Sender Keys / TreeKEM (deferred to Phase 2.5 if pairwise traffic becomes a problem).
- Reactions, edits, deletes via mesh (server-only; keeps the envelope shape to a single `type: "text"`).
- File attachments via mesh (chunked Bonjour TCP transfer is its own phase).
- BLE peripheral GATT for offline-only mesh (still blocked on `flutter_ble_peripheral` 2.x).
- Per-recipient delivery acknowledgement / retry (best-effort fanout; server is the durable path).
- Cross-device mesh history sync via server bridge (different problem).

---

## 4. Architecture Overview

**Logical model:** mesh is layered on top of server fanout. The server remains authoritative for membership, history, and final delivery. Mesh adds low-latency local-network delivery for currently-visible peers.

**Send-time decision tree (sender side):**

```
On tap Send in conversation C:
  generate clientTempId = uuid()
  emit temp_clientTempId MessageEntity into bloc state (existing)

  if socket connected:
    server.sendMessage(C, content, clientTempId)   // fans out to all members

  for each peer p in C.participantIds (excluding self):
    if MeshStatusBloc.isPeerVisibleFor(p)
       AND HiveContactKeyStore.devicesFor(userPk(p)).isNotEmpty:
      meshAdapter.sendEnvelopeToPeer(
        peer: p,
        envelope: { convId: C, clientId: clientTempId, text, sentAt },
      )
```

**Receive-time decision tree (each peer):**

```
Server new_message arrives for clientId X in conv C:
  if state.messages[C] already contains entry with id == X:
    drop (mesh got there first)
  else:
    add server MessageEntity (transport: null)

Mesh inbound envelope arrives for clientId X in conv C:
  if state.messages[C] already contains entry with id == X:
    drop (server echo arrived first)
  else:
    add mesh MessageEntity (transport: 'mesh', id: X)
    persist via MessengerCacheService.appendMeshMessage
```

**Boundary scenarios:**

| Server | Visible peers in group | Outcome |
|--------|------------------------|---------|
| up | all | every member gets 1 entity (mesh first; server echo deduped) |
| up | partial (e.g. 3 of 5) | visible 3 get mesh entity; non-visible 2 get server entity; sender deduped to 1 |
| down | all | visible peers get mesh; non-visible miss until server returns |
| down | partial | visible get mesh; non-visible miss; on reconnect, sender's pending replays via server → non-visible get server entity, visible dedup the second copy |

**What does NOT change:**

- Backend code (no `/messenger/*` server changes; `clientTempId` is already accepted and echoed back).
- Phase 1 Noise IK stack (handshake frames are unchanged; only `data` frame plaintext is wrapped in JSON).
- Group lifecycle (create, add/remove members, role changes) — entirely server-driven, mesh-irrelevant.

---

## 5. Wire Format Change

### Phase 1 frame (current)

```
Frame {
  version: 1
  type: handshake | data
  srcPk: PeerId (32 bytes)
  payload: bytes
  // for data frames: payload = AEAD(utf8.encode(text), Noise.sessionKey)
}
```

### Phase 2 frame

```
Frame {
  version: 2
  type: handshake | data
  srcPk: PeerId (32 bytes)
  payload: bytes
  // for data frames: payload = AEAD(utf8.encode(jsonEncode(envelope)), Noise.sessionKey)
}

envelope = {
  "v": 1,                    // envelope-format version (separate from frame.version)
  "type": "text",            // future: "system" for joined/left/renamed
  "convId": "<conversation uuid>",
  "clientId": "<sender-generated UUID v4>",   // dedup key with server echo
  "text": "<utf-8 message body>",
  "sentAt": "2026-04-26T12:34:56.789Z"        // ISO-8601 UTC, set by sender
}
```

**Compatibility & migration:**

- `Frame.version` increment to 2 is a breaking change. v1 receivers cannot parse v2 data frames; v2 receivers explicitly reject v1 (log warning, drop). Handshake (`type: handshake`) frame format is unchanged — v1 and v2 devices can still complete Noise IK, but a subsequent data frame will be rejected by the v2 side.
- Mixed-version cohort (during the 1-2 week rollout window): mesh between v1 and v2 devices does not work. Server fanout always covers, so users see no functional regression — only the latency benefit of mesh disappears for mixed pairs.
- After saturation (~3 weeks), all peers are v2 and mesh is fully active again.

**Code changes (§5):**

- `lib/core/mesh/transport/frame.dart` — bump `version: 1 → 2`. `Frame.decode` rejects v != 2 with `FormatException` and the transport logs a one-shot `[mesh-frame] dropping legacy v1 frame from <peer>`.
- `lib/core/mesh/services/mesh_messaging_service.dart` — rename `sendText` → `sendEnvelope` (or add new method, keep `sendText` as backwards-compatible wrapper that builds an envelope from positional args). On inbound data frames, `jsonDecode` the plaintext into `Envelope` and emit it on `_inboundCtrl`.
- New file `lib/core/mesh/services/envelope.dart` — `Envelope` class with `toJson()` / `fromJson()`, fields as listed above.
- `lib/core/mesh/services/mesh_messaging_service.dart` — `InboundMessage` becomes `InboundEnvelope` with the full envelope fields exposed.
- Tests: round-trip envelope encode → encrypt → decrypt → decode, with realistic UTF-8 text containing emoji and Cyrillic.

---

## 6. Send Path

### Where it changes

`MessengerRepositoryImpl.sendMessage` — the mesh branch consolidates with the server branch into a single unified flow. The `_resolveConversationContact` helper (Phase 1f) used to short-circuit on group chats by returning null; this is replaced by per-participant resolution inside the new flow.

### Pseudocode

```dart
void sendMessage(String conversationId, String content, {String? clientTempId, ...}) {
  final conv = _cache.getConversationById(conversationId);
  if (conv == null) {
    // No cached conversation → server-only fallback (matches Phase 1).
    _remote.sendMessage(conversationId, content, clientTempId: clientTempId, ...);
    return;
  }

  final clientId = clientTempId ?? Uuid().v4();   // ensure UUID, not millis-based

  // 1. Always-on: server send when socket is connected.
  if (_socketConnected()) {
    _remote.sendMessage(conversationId, content, clientTempId: clientId, ...);
  }
  // (When socket is offline, the message is enqueued in PendingMessageService —
  //  Phase 1g already handles this. _resendPending will retry on reconnect.)

  // 2. Mesh fanout: visible AND known peers.
  final myUserId = _currentUserIdProvider();
  final eligible = _meshEligibleParticipants(conv, myUserId);
  if (eligible.length > 50) {
    debugPrint('[mesh-send] group size ${eligible.length} > 50, mesh skipped (server-only)');
    return;
  }
  for (final peer in eligible) {
    // ignore: unawaited_futures
    _meshAdapter.sendEnvelopeToPeer(
      peer: peer,
      envelope: Envelope(
        version: 1, type: 'text',
        convId: conversationId,
        clientId: clientId,
        text: content,
        sentAt: DateTime.now().toUtc(),
      ),
    );
  }
}

List<MeshEligiblePeer> _meshEligibleParticipants(ConversationEntity conv, String? myUserId) {
  final peers = <MeshEligiblePeer>[];
  for (final p in conv.participantIds) {
    if (p == myUserId) continue;
    if (!_meshStatus.isPeerVisibleFor(p)) continue;
    final userPk = _hiveContactStore.userPkForContactUserId(p);
    if (userPk == null) continue;
    final devices = _hiveContactStore.devicesFor(userPk);
    if (devices.isEmpty) continue;
    peers.add(MeshEligiblePeer(userId: p, devicePk: devices.first));
  }
  return peers;
}
```

### MeshMessengerAdapter

- New method `sendEnvelopeToPeer(peer, envelope)` — single peer send. Handles per-peer Noise handshake (already in `MeshMessagingService.sendEnvelope`), persists locally on success, emits one `AdaptedOutboundMessage` per logical envelope (NOT per peer — group fanout = one logical send).
- Old `sendMessage(conversationId, text, contactDevicePk, contactUserId, clientTempId)` becomes a thin wrapper that builds the envelope and delegates.
- `MeshMessageSent` event (Phase 1h) carries the `clientId` as its `id` field, replacing the Phase 1h `mesh-out-<userId>-<millis>` scheme. This aligns sender-side mesh entry id with server's clientTempId echo, so server `_onMessageReceived` deduplicates against it cleanly.

### TransportSelector

- Removed. The new logic lives directly in `MessengerRepositoryImpl.sendMessage`. Phase 1f's `chooseFor` was a 1:1-only heuristic (server vs mesh vs offline); the group flow needs both server AND mesh simultaneously, so the binary choice is no longer applicable.
- File: `lib/features/messenger/data/services/transport_selector.dart` is deleted (and its DI registration in `service_locator.dart`).

### Edge cases preserved from Phase 1

- Mesh send to one peer fails (handshake timeout, transport error): logged via existing `[mesh-send] failed (TimeoutException...)`. Other peers continue. Server send already covered the receiver via fanout.
- Socket offline + no eligible mesh peers: existing PendingMessageService queues the message; retry on reconnect (Phase 1g `_resendPending`).
- Sender's own send: the temp_clientId entry in bloc state gets replaced by EITHER the `MeshMessageSent` event (if mesh persists first) OR the server `MessageReceived` echo (if server persists first). Whichever arrives second is dropped by the dedup guard.

---

## 7. Receive Path & Dedup

### Mesh inbound

```dart
// MeshMessagingService._onInboundFrame, data branch
final plaintext = await session.decrypt(frame.bytes);
final envelopeJson = jsonDecode(utf8.decode(plaintext)) as Map<String, dynamic>;
final envelope = Envelope.fromJson(envelopeJson);
_inboundCtrl.add(InboundEnvelope(
  fromUserPk: srcDevice,
  envelope: envelope,
));
```

### MeshMessengerAdapter._onInbound

```dart
void _onInbound(InboundEnvelope inbound) {
  final userPk = lookupUserByDevice(inbound.fromUserPk);
  if (userPk == null) return;
  final contactUserId = contactUserIdForUserPk(userPk);
  if (contactUserId == null) return;

  // Phase 2: convId comes from the envelope (Noise-authenticated, so we trust it).
  // For 1:1 chats this resolves to the same convId as Phase 1f's resolveConversationId
  // would have produced from the contact's userId, so behaviour is preserved.
  final convId = inbound.envelope.convId;
  final msgId = inbound.envelope.clientId;

  persistLocal({
    'id': msgId,
    'conversationId': convId,
    'contactUserId': contactUserId,
    'senderId': contactUserId,
    'content': inbound.envelope.text,
    'transport': 'mesh',
    'direction': 'inbound',
    'sentAt': inbound.envelope.sentAt.toIso8601String(),
  });
  _ctrl.add(AdaptedInboundMessage(
    contactUserId: contactUserId,
    conversationId: convId,
    text: inbound.envelope.text,
    receivedAt: inbound.envelope.sentAt,
    clientId: msgId,
  ));
}
```

### Bloc dedup logic

**Backend reality check:** server's `new_message` Socket.IO event currently sends `MessageEntity.fromJson` of the persisted DB row. It does NOT include `clientTempId` in the payload. Phase 1g's pending-removal in `_onMessageReceived` works because it matches `temp_*` ids by `(senderId, content)` heuristic, not by client id echo.

For Phase 2.0 we keep `no backend changes` and lift the same heuristic to cover mesh entries:

```dart
void _onMessageReceived(MessageReceived event, Emitter<MessengerState> emit) {
  final msg = event.message;
  final existing = List<MessageEntity>.from(state.messages[msg.conversationId] ?? []);

  // Existing duplicate-by-id guard.
  if (existing.any((m) => m.id == msg.id)) return;

  // Phase 1g: drop temp_* with matching senderId + content (already in code).
  // Phase 2.0 extension: ALSO drop mesh-delivered entries (transport == 'mesh')
  // with matching senderId + content within a 10-second window. This is the
  // server echo arriving after the mesh got there first. We keep the mesh
  // entry (it has the "via mesh" caption) and drop the server copy.
  final meshDup = existing.any((m) =>
      m.transport == 'mesh' &&
      m.senderId == msg.senderId &&
      m.content == msg.content &&
      (m.sentAt.difference(msg.sentAt).abs() < const Duration(seconds: 10)));
  if (meshDup) return;

  // ... existing temp_* removal + state update ...
}

void _onMeshMessageReceived(MeshMessageReceived event, Emitter<MessengerState> emit) {
  final convId = event.conversationId;
  final list = state.messages[convId] ?? const [];

  // Phase 2.0 dedup: if a server entry already exists with the same
  // senderId + content within a 10-second window, the server echo got
  // here first — drop the mesh copy.
  final serverDup = list.any((m) =>
      m.transport != 'mesh' &&
      !m.id.startsWith('temp_') &&
      m.senderId == event.contactUserId &&
      m.content == event.text &&
      (m.sentAt.difference(event.receivedAt).abs() < const Duration(seconds: 10)));
  if (serverDup) return;

  // ... emit MessageEntity(id: event.clientId, transport: 'mesh', ...) ...
}
```

**Trade-offs of the heuristic:**
- Two distinct messages from the same sender with identical text in <10s would dedup to one. Acceptable for typical UX (rapid-fire identical messages are rare and indistinguishable from the user's perspective).
- 10-second window covers WiFi → server roundtrip latency including mobile network jitter.
- A future Phase 2.5 polish: backend echo of `clientTempId` in `new_message` event → switch to strict id-based dedup. Tracked as a follow-up; out of scope here.

### Self-send sender dedup

Sender Bob taps Send in a group:

1. bloc creates `temp_<clientId>` entity in state.messages.
2. `_remote.sendMessage(..., clientTempId: clientId)` — server eventually echoes `new_message {clientTempId: X, id: server-uuid}`.
3. Per-peer `_meshAdapter.sendEnvelopeToPeer` calls — adapter persists in Hive AND emits `AdaptedOutboundMessage` ONCE per logical send (not per peer).
4. `MeshMessageSent` event handler (Phase 1h) replaces `temp_<clientId>` with `MessageEntity(id: clientId, transport: 'mesh')`.
5. When server echo arrives later, `_onMessageReceived` finds entry with `id == clientId` → drops the server copy.

Bob sees one entry, with `transport: 'mesh'` (typical when mesh wins the race) or `transport: null` (server-only path, when no eligible peers). Either way, exactly one entry.

---

## 8. State Management & Bloc Changes

### MeshStatusBloc

- Add `Iterable<String> visibleParticipantsOf(List<String> participantIds)` helper:
  ```dart
  Iterable<String> visibleParticipantsOf(List<String> participantIds) =>
      participantIds.where((p) => state.visibilityByContactUserId[p] ?? false);
  ```
- No structural change to state. Existing `visibilityByContactUserId: Map<String, bool>` covers groups by virtue of containing every contact regardless of conversation type.

### ConversationEntity

- No change. `participantIds` and `type` already exist.

### MessengerBloc._onSendMessage

- temp-pending id changes from `temp_<DateTime.now().millisecondsSinceEpoch>` to `Uuid().v4()` (passed to `_repo.sendMessage` as `clientTempId`).
- Group send logic lives in repo, not bloc — bloc still calls `_repo.sendMessage(convId, content, clientTempId: ...)`. Repo handles the fanout.

### MeshMessageSent handler (Phase 1h, modified)

- `event.id` is now `clientTempId` (UUID v4), not `mesh-out-...-millis`.
- Handler replaces `temp_<clientId>` with `MessageEntity(id: clientId, transport: 'mesh')` — same logic, different id format.

### MessengerCacheService

- No structural change. `appendMeshMessage` continues to dedup by `entry['id']` (which is now `clientTempId`).

### UI badge in chat header

- 1:1 chat: existing 🌐 badge with peer-visible-or-not (Phase 1e).
- Group chat: badge shows `<N>/<M> in mesh` where `M = participantIds.length - 1` (excluding self), `N = MeshStatusBloc.visibleParticipantsOf(participantIds).count(p => p != myUserId)`. Updates reactively as peers come/go.
- Both 1:1 and group share the same widget `ChatTransportBadge` — small refactor to read from MeshStatusBloc directly rather than per-conversation contact resolver.

---

## 9. Testing

### Unit (new + updated)

- `test/core/mesh/transport/frame_test.dart` — v1 decode rejected; v2 round-trip with binary, ASCII, and emoji payloads.
- `test/core/mesh/services/envelope_test.dart` — Envelope toJson/fromJson round-trip, ISO-8601 UTC handling, version field.
- `test/core/mesh/services/mesh_messaging_service_test.dart` — sendEnvelope wraps payload as JSON; receive parses envelope and emits InboundEnvelope.
- `test/features/messenger/data/services/mesh_messenger_adapter_test.dart` — group inbound: convId from envelope; persistLocal uses clientId as id.
- `test/features/messenger/data/repositories/messenger_repository_impl_test.dart` (new):
  - Group send with all visible peers — server.sendMessage called once + N pairwise mesh sends.
  - Group send with mixed visibility — only visible get mesh; server still called.
  - Group send with no eligible peers — server-only.
  - Group send with > 50 eligible peers — mesh skipped, server-only with warning log.
  - 1:1 send with visible peer + connected — both transports invoked.
  - 1:1 send + offline socket + visible peer — only mesh; pending queue tracked.
- `test/features/messenger/presentation/bloc/messenger_bloc_dedup_test.dart` (new):
  - Server `MessageReceived` arriving with clientTempId already in state (mesh entry) — dropped.
  - Mesh `MeshMessageReceived` arriving with clientId already in state (server echo) — dropped.
  - Sender's `MeshMessageSent` replaces temp_<clientId> with mesh entry; subsequent server echo deduped.

### Hardware integration (manual checklist)

1. **Group of 3 (Android, iPhone-A, iPhone-B), all on same WiFi, server up:**
   - Create a group chat from any device.
   - Send text from iPhone-A. Confirm Android and iPhone-B both receive it with `via mesh` caption, no duplicates, latency <150ms.
   - Send rapid succession (5 messages in 5 seconds). Confirm order preserved, no duplicates, no spinning clocks.

2. **Group of 3, one device WiFi-off:**
   - Disconnect Android from WiFi.
   - Send from iPhone-A. iPhone-B receives via mesh; Android does not until WiFi returns.
   - Reconnect Android. Confirm Android receives via server fanout, no duplicate on iPhone-B.

3. **Server stop scenario (group of 3, all visible):**
   - Stop dev server.
   - Send from iPhone-A. Both other peers receive via mesh.
   - Restart dev server. Sender's pending re-emits via server. Other peers dedup the second copy.

4. **1:1 regression:**
   - Verify Phase 1f/g/h/i/j/k flows (open chat, fetchContactKeys, mesh send/receive, "via mesh" caption, no clock-icon stuck) still work end-to-end. No regression after the wire format upgrade.

5. **Mixed-version sanity (post-release):**
   - One device on the v1 build, one on v2. Send from each side.
   - v1 → v2: data frame ignored (v2 logs warning, dropped). Server fanout delivers.
   - v2 → v1: data frame parses but envelope decoding fails. Server fanout delivers.
   - User-visible: messages still arrive, just without the mesh-fast-path benefit.

---

## 10. Risks & Rollout

| Risk | Impact | Mitigation |
|------|--------|-----------|
| Frame v1 → v2 breaks mesh between mixed-version devices during rollout | mesh latency benefit lost for ~2-3 weeks until everyone upgrades | server fanout fully covers; functional regression is zero. Announcement to users that mesh comes online once everyone is on the new build. |
| Group of >50 visible peers DoSes the sender (50 pairwise Noise sessions) | sender stalls, possibly OOM on tiny devices | hard limit at 50; server-only fallback above that with a one-shot warning log. |
| Two senders in the same millisecond produce identical clientTempId (current Phase 1h scheme `temp_<millis>`) | their sends would dedup against each other on receivers | switch to `Uuid().v4()` — collision probability is negligible. |
| Envelope decode failure (corrupted JSON, truncated frame) | one mesh message lost | log via `[mesh-frame] envelope decode failed: $e`; server fanout will still deliver. |
| Bloc dedup races (server echo and mesh inbound interleave during the same event-loop turn) | possible double-emit if dedup guard is non-atomic | dedup is a synchronous check inside the bloc handler; bloc events are processed sequentially. No race window. |
| Sender's `MeshMessageSent` and server `MessageReceived` arrive in wrong order, leaving `temp_<clientId>` orphaned | UX bug: clock icon never clears | both handlers replace the temp-id with the corresponding final entry; dedup guard ensures only one survives. Test case explicit. |

**Rollout plan:**

1. Ship Phase 2.0 to dev branch via standard merge → feature/mesh-phase2 → dev (mirroring Phase 1k pattern).
2. Build dev APK + iOS dev TestFlight. Announce internal testing window.
3. Merge dev → main once one full week of dev usage shows no regressions and at least one verified group mesh delivery on hardware.
4. Production APK + iOS prod TestFlight after main merge.
5. Mixed-version window: anywhere from 1 to 3 weeks; mesh latency benefit gradually returns as the cohort updates. Server fanout never breaks.

---

## 11. Next Steps

1. User reviews this spec.
2. `writing-plans` skill produces a task-by-task implementation plan.
3. Execute via `subagent-driven-development` (matches Phase 1k delivery pattern).

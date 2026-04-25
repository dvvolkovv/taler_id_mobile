# Mesh Phase 1f — Messaging Render Fix

**Date:** 2026-04-24
**Status:** Design approved, ready for implementation planning

**Working dir:** `~/Downloads/taler_id_mesh/` — branch `feature/mesh-network` (off `dev`). No backend changes.

---

## 1. Executive Summary

Phase 1e wired the plumbing — `TransportSelector`, `MeshMessengerAdapter`, `MeshStatusBloc` — but mesh messages still don't render in the chat UI and can't actually be sent over Noise because the in-memory `ContactKeyStore` is never populated. Phase 1f closes four tight, interdependent gaps so mesh messaging works end-to-end from the user's point of view:

1. **`MessageEntity.transport` field** (Freezed regen) — lets the UI distinguish server vs. mesh messages per bubble.
2. **`ContactKeyStore` ↔ `HiveContactKeyStore` bridge** — `DeviceKeySyncService.fetchContactKeys` now also writes into the in-memory store, so `MeshMessagingService` can start Noise IK handshakes for real contacts.
3. **Real mesh-message persistence** — `MessengerCacheService.appendMeshMessage` writes to a Hive box keyed by conversation; `getMessages` merges server history with mesh records by `sentAt`.
4. **Correct conversation routing + bubble rendering** — adapter looks up the existing server conversationId for the contact, falls back to `meshOnly:<userId>` only when no server chat exists; `MessengerBloc`'s `MeshMessageReceived` handler emits a proper `MessageEntity` into the per-conversation map so `ChatRoomScreen` renders it with a small "via mesh" caption.

Scope is tight: closes the final-review blockers (C1, C2) at the UI layer and completes the "mesh is user-visible" story for 1:1 chats that already have server history. First-contact-over-mesh (no prior server conversation) still lands in the `meshOnly:*` ghost chat — deferred to Phase 2 gateway work.

---

## 2. Decision Log

| # | Question | Decision | Rationale |
|---|----------|----------|-----------|
| 1 | Mesh messages interleave with server history or separate chat | A: same conversationId, per-message `via mesh` caption | Natural UX; Phase 1e decision #3 (no server sync) ensures no duplication |
| 2 | `MessageEntity.transport` type | `String?` (default null = server) | Minimal change; backward-compatible with server JSON that omits the field |
| 3 | Persistence backend for mesh history | New Hive box `mesh_messages` keyed by conversationId | Reuses existing Hive infrastructure; no new deps |
| 4 | `ContactKeyStore` bridge location | Inside `DeviceKeySyncService.fetchContactKeys`, after Hive write | Single responsibility point; keeps both stores eventually consistent |
| 5 | First-contact-over-mesh UX | Ghost chat `meshOnly:<userId>` — same as Phase 1e stub | Not breaking regression; proper "ensureConversation" server call is Phase 2 |

---

## 3. Goals & Non-Goals

### Goals

1. After `fetchContactKeys(userId)` completes, `MeshMessagingService.sendText(toUserPk=devicePkOfContact)` succeeds — Noise IK handshake finds the devicePk in `ContactKeyStore`.
2. Outbound mesh text messages persist via `MessengerCacheService.appendMeshMessage` to Hive; survive app restart.
3. Inbound mesh text messages emit a `MessageEntity(transport: 'mesh')` into the correct existing conversation's state; `ChatRoomScreen` renders them interleaved with server messages, with a "via mesh" subtitle.
4. Per-message caption `via mesh` appears under bubbles where `message.transport == 'mesh'`. Server messages unchanged.
5. All existing unit tests stay green; add focused tests for the four new mechanisms.

### Non-Goals (Phase 1f)

- Mesh-originated first contact (no prior server conversation) — lands in `meshOnly:*` ghost chat as in Phase 1e
- Mesh message sync to server after reconnect (Phase 2 gateway bridge)
- Per-message acknowledgement / retry over mesh
- Mesh for group chats / files / voice
- BLE data path (still blocked on peripheral GATT — Phase 1d.5)
- Dedup cache for `fetchContactKeys` (5-min rate limit, Phase 2 polish)
- `MeshFcmListener` wiring
- `MeshMessengerAdapter.dispose` on logout (noted leak, Phase 2 cleanup)

---

## 4. File Changes

```
lib/features/messenger/domain/entities/
├── message_entity.dart                    # + transport: String?
├── message_entity.freezed.dart            # REGENERATED
└── message_entity.g.dart                  # REGENERATED

lib/core/services/
└── messenger_cache_service.dart           # real appendMeshMessage + getMeshMessagesFor(convId)
                                           # + getConversationByContact(userId)

lib/core/mesh/services/
└── device_key_sync_service.dart           # + ContactKeyStore dependency + bridge call

lib/features/messenger/data/services/
└── mesh_messenger_adapter.dart            # resolveConversationId callback; use real convId

lib/features/messenger/presentation/bloc/
├── messenger_bloc.dart                    # MeshMessageReceived → MessageEntity emit
└── messenger_state.dart                   # (unchanged — state already holds per-conv messages)

lib/features/messenger/presentation/screens/
└── chat_room_screen.dart                  # "via mesh" caption under mesh bubbles

lib/core/di/
└── service_locator.dart                   # inject ContactKeyStore into DeviceKeySyncService
                                           # inject resolveConversationId into adapter

test/features/messenger/
├── data/services/mesh_messenger_adapter_test.dart  # new test: conversationId routing
├── presentation/bloc/messenger_bloc_test.dart      # new test: MeshMessageReceived → state
test/core/services/
└── messenger_cache_service_test.dart       # new: appendMeshMessage + mergeSorted
test/core/mesh/services/
└── device_key_sync_service_test.dart       # updated: verifies ContactKeyStore bridge call
```

---

## 5. Component Changes

### MessageEntity (Freezed regen)

Add one nullable field:

```dart
@freezed
class MessageEntity with _$MessageEntity {
  const factory MessageEntity({
    required String id,
    // ... existing fields ...
    String? topicId,
    /// Phase 1f — "mesh" for messages delivered via MeshMessagingService.
    /// Null or "server" for the normal path.
    String? transport,
  }) = _MessageEntity;
  // ...
}
```

Regen: `flutter pub run build_runner build --delete-conflicting-outputs`.

### MessengerCacheService

New Hive box `mesh_messages`. Entries are per-conversation lists of serialized `MessageEntity` maps with `transport: 'mesh'`.

```dart
Box<String>? _meshBox;

Future<void> init() async {
  // ... existing ...
  _meshBox = await Hive.openBox<String>('mesh_messages');
}

/// Append a mesh-delivered message (either direction) to the per-conversation
/// list. Idempotent by message id — subsequent writes with the same id are
/// ignored.
Future<void> appendMeshMessage(Map<String, dynamic> entry) async {
  if (_meshBox == null) return;
  final convId = entry['conversationId'] as String?;
  if (convId == null) return;
  final key = 'mesh_history_$convId';
  final raw = _meshBox!.get(key);
  final list = raw != null
      ? (jsonDecode(raw) as List).cast<Map<String, dynamic>>()
      : <Map<String, dynamic>>[];
  final newId = entry['id'] as String?;
  if (newId != null && list.any((m) => m['id'] == newId)) return;
  list.add(entry);
  await _meshBox!.put(key, jsonEncode(list));
}

/// Read all mesh messages for a conversation, oldest first by `sentAt`.
List<Map<String, dynamic>> getMeshMessagesFor(String conversationId) {
  final raw = _meshBox?.get('mesh_history_$conversationId');
  if (raw == null) return const [];
  final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
  list.sort((a, b) => (a['sentAt'] as String).compareTo(b['sentAt'] as String));
  return list;
}

/// Find the existing server conversation between the current user and
/// `contactUserId` (1:1 chat only). Returns null for groups or when no
/// conversation has been cached yet.
ConversationEntity? getConversationByContact(String contactUserId) {
  final all = getConversations() ?? const <ConversationEntity>[];
  for (final c in all) {
    if (c.otherUserId == contactUserId && c.type == 'DIRECT') {
      return c;
    }
  }
  return null;
}
```

`ConversationEntity` already exists; `type` and `otherUserId` are already cached by the messenger load path.

### DeviceKeySyncService bridge

Add a `ContactKeyStore` dependency injected at construction. After Hive cert write in `fetchContactKeys`, mirror into the in-memory store:

```dart
class DeviceKeySyncService {
  final DeviceKeysApiClient api;
  final HiveContactKeyStore store;
  final ContactKeyStore inMemoryStore;   // NEW
  // ... existing ...

  Future<void> fetchContactKeys(String contactUserId) async {
    final certs = await api.getContactKeys(contactUserId);
    // ... existing loop storing certs in hive + userPk mapping ...

    // Phase 1f — mirror to in-memory ContactKeyStore so MeshMessagingService
    // Noise IK handshake succeeds for this contact.
    for (final cert in certs) {
      if (cert.userPk != null && cert.userPk!.isNotEmpty) {
        try {
          final userPk = PeerId.fromHex(cert.userPk!);
          final devicePk = PeerId.fromHex(cert.devicePk);
          inMemoryStore.addContact(userPk: userPk, devicePks: [devicePk]);
        } catch (_) {
          // skip malformed
        }
      }
    }
  }
}
```

### MeshMessengerAdapter

Accept a `resolveConversationId` callback instead of hardcoding `meshOnly:<userId>`:

```dart
class MeshMessengerAdapter {
  // ... existing fields ...
  final String Function(String contactUserId) resolveConversationId;

  MeshMessengerAdapter({
    // ... existing ...
    required this.resolveConversationId,
  });

  void _onInbound(InboundMessage msg) {
    final userPk = lookupUserByDevice(msg.fromUserPk);
    if (userPk == null) return;
    final contactUserId = contactUserIdForUserPk(userPk);
    if (contactUserId == null) return;
    final now = DateTime.now();
    final convId = resolveConversationId(contactUserId);
    persistLocal({
      'id': _generateMessageId(msg.fromUserPk, now),
      'conversationId': convId,
      'contactUserId': contactUserId,
      'senderId': contactUserId,
      'content': msg.text,
      'transport': 'mesh',
      'direction': 'inbound',
      'sentAt': now.toIso8601String(),
    });
    _ctrl.add(AdaptedInboundMessage(
      contactUserId: contactUserId,
      conversationId: convId,
      text: msg.text,
      receivedAt: now,
    ));
  }

  String _generateMessageId(PeerId from, DateTime at) =>
      'mesh-${from.toHex().substring(0, 8)}-${at.millisecondsSinceEpoch}';
  // similar change in sendMessage()
}
```

`AdaptedInboundMessage` grows a `conversationId` field so the bloc can route without reshuffling.

In `service_locator.dart`, inject:

```dart
resolveConversationId: (contactUserId) {
  final existing = sl<MessengerCacheService>().getConversationByContact(contactUserId);
  return existing?.id ?? 'meshOnly:$contactUserId';
},
```

### MessengerBloc

Replace the log-only `MeshMessageReceived` handler with a proper state emit:

```dart
on<MeshMessageReceived>((event, emit) async {
  final msg = MessageEntity(
    id: 'mesh-in-${event.receivedAt.millisecondsSinceEpoch}',
    conversationId: event.conversationId,
    senderId: event.contactUserId,
    content: event.text,
    sentAt: event.receivedAt,
    transport: 'mesh',
  );
  final updated = Map<String, List<MessageEntity>>.from(state.messagesByConversation ?? {});
  final list = List<MessageEntity>.from(updated[event.conversationId] ?? const []);
  list.add(msg);
  list.sort((a, b) => a.sentAt.compareTo(b.sentAt));
  updated[event.conversationId] = list;
  emit(state.copyWith(messagesByConversation: updated));
});
```

Adjust exact state field name (`messagesByConversation` is the typical pattern). `MeshMessageReceived` event also grows a `conversationId` field populated from the adapter's emission.

### ChatRoomScreen bubble

Find the message bubble rendering block. Under the text content add:

```dart
if (message.transport == 'mesh')
  Padding(
    padding: const EdgeInsets.only(top: 2, left: 4),
    child: Text(
      'via mesh',
      style: TextStyle(
        fontSize: 10,
        color: Colors.grey.shade500,
        fontStyle: FontStyle.italic,
      ),
    ),
  ),
```

Surgical addition — no layout refactor.

### getMessages merge

The messenger load path in `MessengerCacheService.getMessages(conversationId, ...)` or wherever the chat message list is assembled should merge mesh records alongside server history on every load. Phase 1f implementation detail: when UI requests messages for conversationId, repository or cache service:

1. Reads server messages from existing cache.
2. Calls `getMeshMessagesFor(conversationId)`, deserializes each into a `MessageEntity` with `transport: 'mesh'`.
3. Merges and returns sorted by `sentAt`.

Exact integration point depends on existing code; the plan will specify.

---

## 6. Data Flow

### Outbound

```
User taps Send
  → MessengerBloc → MessengerRepositoryImpl.sendMessage
  → TransportSelector.chooseFor(contactUserId) → mesh
  → _meshAdapter.sendMessage(conversationId, text, contactDevicePk, contactUserId)
      ├─ MeshMessagingService.sendText(toUserPk=devicePk, text)
      │   └─ Noise IK handshake succeeds because ContactKeyStore.isKnownDevice(devicePk) == true
      │       (bridge from fetchContactKeys populated it)
      └─ persistLocal({
           id, conversationId=<real-server-convId>, text, transport='mesh', ...
         })
         → MessengerCacheService.appendMeshMessage → Hive mesh_messages box
```

### Inbound

```
MeshMessagingService.inbound → MeshMessengerAdapter._onInbound
  → lookup contactUserId via HiveContactKeyStore + contactsCache
  → resolveConversationId(contactUserId) → real conv id
  → persistLocal (same as outbound)
  → _ctrl.add(AdaptedInboundMessage(conversationId=..., ...))
MessengerRepositoryImpl.meshMessageStream
  → MessengerBloc._meshMsgSub fires
  → add(MeshMessageReceived(conversationId, contactUserId, text, receivedAt))
  → handler builds MessageEntity(transport='mesh'), emits into state.messagesByConversation
  → ChatRoomScreen ListView rebuilds, renders bubble + "via mesh" caption
```

### Load after app restart

```
User opens ChatRoomScreen
  → Bloc requests messages for conversationId
  → MessengerRepositoryImpl.getMessages / cache service returns
    server history ∪ getMeshMessagesFor(convId), sorted by sentAt
  → UI renders both kinds; mesh ones get caption
```

---

## 7. Testing

### Unit

- `messenger_cache_service_test.dart` (new): `appendMeshMessage` persists and dedupes by id; `getMeshMessagesFor` returns sorted; `getConversationByContact` resolves 1:1 chats and returns null for groups.
- `mesh_messenger_adapter_test.dart` (updated): uses `resolveConversationId` callback; inbound event carries conversationId; unknown contact still drops silently.
- `device_key_sync_service_test.dart` (updated): after `fetchContactKeys`, the in-memory `ContactKeyStore` contains the expected `userPk → devicePks` mapping.
- `messenger_bloc_test.dart` (new case): `MeshMessageReceived` event produces a `MessageEntity` with `transport: 'mesh'` in the conversation's message list.
- `message_entity_test.dart` (if exists): round-trip with and without `transport` field.

### Widget

- `chat_room_screen_mesh_caption_test.dart` (new): render a chat with one mesh message and one server message; assert `find.text('via mesh')` finds exactly one instance under the mesh bubble.

### Hardware integration (manual)

- Already-contact pair, same WiFi: kill server socket on one side (toggle airplane+wifi-on). Send message from that side. Badge flips to 📡. Message appears on other device with "via mesh" caption. Reboot both apps. History survives.

---

## 8. Risks

| Risk | Impact | Mitigation |
|------|--------|-----------|
| Freezed regen conflicts with manual edits to `.freezed.dart`/`.g.dart` | Build break | Never hand-edit generated files; always run `--delete-conflicting-outputs` |
| Mesh message ID collides with server message ID | Dedup drops server message | ID prefix `mesh-` guarantees disjoint namespace from server UUIDs |
| Hive box `mesh_messages` grows unbounded | Disk bloat | Phase 1f: accept; Phase 2 adds TTL + size cap (spec §8 HeldBlobStore model) |
| ContactKeyStore mirror out of sync with HiveContactKeyStore on cert revoke | Stale devicePk still used for Noise | Phase 1f only appends; Phase 2 adds revoke fan-out |
| First-contact-over-mesh falls into `meshOnly:<userId>` ghost chat | Confusing UX: same contact shows two chats | Explicitly scoped out; rare case in practice; Phase 2 fixes via gateway ensureConversation |
| `messagesByConversation` state field name differs from current bloc | Code won't compile | Plan will specify actual field name after reading messenger_state.dart |

---

## 9. Rollout

Purely mobile; no backend changes. Ship in the existing `feature/mesh-network` branch. Runtime toggle `mesh.offlineFallback` from Phase 1e already controls whether mesh gets picked by TransportSelector — no new flag needed.

---

## 10. Next Steps

1. User review of this spec.
2. Feedback if any.
3. `writing-plans` → task-by-task plan.
4. Execute via `subagent-driven-development`.

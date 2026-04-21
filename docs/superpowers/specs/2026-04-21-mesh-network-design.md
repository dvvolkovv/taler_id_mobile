# Taler ID Mesh Network — Design Specification

**Date:** 2026-04-21
**Status:** Design approved, ready for implementation planning
**Branch:** `feature/mesh-network` (off `dev`)
**Working dir:** `~/Downloads/taler_id_mesh/`

---

## 1. Executive Summary

Добавить в Taler ID peer-to-peer mesh сеть на WiFi + BLE, позволяющую обмениваться сообщениями, файлами, совершать голосовые звонки (включая групповые) без подключения к серверу.

**Целевые сценарии:**
- **Full offline** — нет интернета вообще (поле, подземелье, зона ЧС)
- **Event mode** — конференция / корпоратив на 50-200 человек с временным локальным чатом
- **Multi-hop mesh** — устройства ретранслируют трафик друг через друга
- **Opportunistic server fallback** — любой узел с интернетом автоматически становится gateway'ем к серверу для соседей

**Ключевая архитектурная идея:** trustless relay layer (любое устройство слепо ретранслирует onion-зашифрованные пакеты) + trusted endpoint layer (читать/писать могут только уже знакомые контакты, обменявшиеся ключами ранее через сервер или QR).

---

## 2. Decision Log

| # | Вопрос | Решение |
|---|--------|---------|
| 1 | Целевые сценарии | A (offline) + C (event) + D (multi-hop) |
| 2 | Платформенный scope | Cross-platform через общий WiFi + BLE discovery; iOS только в foreground |
| 3 | Функциональный scope | Сообщения + файлы + звонки (все типы) + gateway к серверу |
| 4 | Identity model | Trustless relay + trusted endpoints (Briar/Tor-подобная) |
| 5 | Voice architecture | Hybrid smart routing: 1-hop direct → 2-hop SFU → voice-message fallback |
| 6 | Delivery semantics | Epidemic store-and-forward (TTL 24ч) + server fallback через gateway |
| 7 | Group calls | Full-duplex 10-15 через SFU-tree на Android-узлах |
| 8 | UX integration | Transparent fallback + отдельная event-launch зона |
| 9 | Event onboarding | QR-код организатора (без PIN) |
| 10 | Noise pattern | Noise_IK_25519_ChaChaPoly_SHA256 |
| 11 | Device key rotation | 30 дней |
| 12 | Event identity storage | Виртуальный контакт в ContactKeyStore |
| 13 | Plugin structure | 5 Flutter plugins за единым facade'ом |
| 14 | Discovery mechanism | BLE-only Phase 1, + mDNS upgrade для общего WiFi |
| 15 | Routing algorithm | Hybrid: distance-vector для unicast + epidemic flood для event-broadcast |
| 16 | Hello interval | Adaptive (5 сек active / 30 сек idle) |
| 17 | Anti-spam | Lite proof-of-work (~50 мс) для event-flood |
| 18 | Onion packet | Fixed 2048 B (Sphinx-like) |
| 19 | HeldBlobStore size | 100 MB default, настройка 10-500 MB, TTL 24ч |
| 20 | Gateway default | OFF (opt-in), с data budget + battery threshold |
| 21 | Feature module | Отдельный `lib/features/mesh/` |
| 22 | Event-chat display | В обычном списке мессенджера с тегом `[EVENT]` |
| 23 | Assistant integration | Phase 2 (не блокер Phase 1) |

---

## 3. Goals & Non-Goals

### Goals
1. Доставлять сообщения и файлы между знакомыми контактами в mesh без интернета
2. Работать multi-hop: 3-hop onion для unicast-сообщений, до 15-hop epidemic flood для event-broadcast
3. Cross-platform: iOS ↔ Android на общем WiFi и в BLE-proximity
4. Голосовые звонки 1-на-1 без сервера (1-hop WebRTC)
5. Малые группы (до 6 чел.) через 2-hop SFU на Android-узле
6. Группы 10-15 чел. через SFU-tree (phase 4)
7. Event-режим 50-200 участников с QR-onboarding
8. Automatic server fallback через gateway-узел с интернетом
9. Trustless relay: участники сети не могут читать чужие сообщения, не могут deanonymize отправителей
10. Forward secrecy: компрометация устройства не раскрывает прошлую переписку

### Non-Goals (v1)
- Полный Tor-уровень anonymity (cover traffic, timing attacks defense) — позже
- Mesh с LoRa / satellite / прочими не-WiFi транспортами
- iOS background-first experience (фундаментальное ограничение платформы)
- Веб-клиент в mesh
- Desktop app в mesh (пока — только мобилки)
- Автоматическое user discovery ("знакомься с людьми рядом") — требует только знакомые контакты по design
- Децентрализованный contact exchange без сервера / QR (нужен trust anchor)
- Групповые звонки > 15 чел. через SFU-tree — использовать gateway+LiveKit

---

## 4. Layered Architecture

Система разделена на 6 слоёв, каждый с чётким interface'ом. Вышестоящие слои не знают о внутренностях нижестоящих.

```
┌─────────────────────────────────────────────────────────┐
│ 6. App Integration Layer                                │
│    Messenger UI, Call UI, Event Launch UI, Settings     │
│    TransportSelector (server / mesh / gateway)          │
├─────────────────────────────────────────────────────────┤
│ 5. Service Layer                                        │
│    MessagingService, VoiceService, FileService,         │
│    GroupCallCoordinator, GatewayService                 │
├─────────────────────────────────────────────────────────┤
│ 4. Onion & Delivery Layer                               │
│    Sphinx onion (3 hops), store-and-forward,            │
│    dedup cache, TTL management                          │
├─────────────────────────────────────────────────────────┤
│ 3. Routing Layer                                        │
│    Distance-vector gossip, link metrics, path selection,│
│    epidemic flood для broadcast, relay policy           │
├─────────────────────────────────────────────────────────┤
│ 2. Session & Crypto Layer                               │
│    User identity + device keys (Ed25519),               │
│    Noise IK handshake, session keys, ContactKeyStore    │
├─────────────────────────────────────────────────────────┤
│ 1. Transport Layer                                      │
│    BLE discovery, WiFi data (UDP/TCP), mDNS announce,   │
│    platform adapters (iOS Multipeer, Android WiFi       │
│    Direct, Android hotspot, common WiFi)                │
└─────────────────────────────────────────────────────────┘
```

### Принципы изоляции

- Каждый слой экспонирует Dart abstract class — реализации заменяемы
- Transport можно расширить (добавить Wi-Fi Aware, LoRa) без правки выше
- Voice и Messaging не знают про onion — для них всё выглядит как «отправь до userPk»
- Onion не знает про содержимое — только фрагменты и next-hop

### Directory layout (в `~/Downloads/taler_id_mesh/`)

```
lib/
├── core/
│   └── mesh/
│       ├── transport/          # Layer 1
│       ├── crypto/             # Layer 2
│       ├── routing/            # Layer 3
│       ├── onion/              # Layer 4
│       └── services/           # Layer 5
├── features/
│   └── mesh/                   # Layer 6 (UI)
│       ├── data/
│       ├── domain/
│       └── presentation/
```

---

## 5. Layer 1 — Transport

### Abstract interface

```dart
abstract class MeshTransport {
  Stream<PeerDiscovered> get discoveries;
  Stream<PeerLost> get losses;
  Stream<InboundFrame> get inbound;

  Future<void> startAdvertising(DeviceInfo self);
  Future<void> stopAdvertising();
  Future<void> connectTo(PeerId peer);
  Future<void> send(PeerId peer, Uint8List data, {bool reliable});
}
```

### Discovery — BLE advertising + scanning

- Advertising payload ≤ 20 байт: `[service UUID][first 8 bytes of device_pk][capability flags]`
- Scanning — duty-cycled (1 сек on / 10 сек off в idle, 100% в active)
- iOS: CoreBluetooth в foreground
- Android: `BluetoothLeAdvertiser` + `BluetoothLeScanner`, работает в background (при наличии foreground service)
- **Privacy:** device_pk ротируется ежедневно; в advertise только 8-байт prefix (не full key)

### Data channel — приоритетный выбор

| # | Transport | Когда | Скорость | iOS | Android |
|---|-----------|-------|----------|-----|---------|
| 1 | Общий WiFi + mDNS + TCP/UDP | оба на одном AP | 50-100 Mbit | ✅ | ✅ |
| 2 | Wi-Fi Direct | нет общего AP, Android↔Android | 20-50 Mbit | ❌ | ✅ |
| 3 | Multipeer Connectivity | нет общего AP, iOS↔iOS | 10-30 Mbit | ✅ | ❌ |
| 4 | Android hotspot + iOS client | cross-platform, нет AP | 10-30 Mbit | partial | ✅ |

`MeshTransportImpl` выбирает лучший доступный автоматически, может переключаться на лету.

### Flutter plugins (5 штук, единый facade)

| Plugin | Базовая lib | Android | iOS |
|--------|-------------|---------|-----|
| `mesh_ble` | flutter_reactive_ble + custom advertise | native | native |
| `mesh_wifi_direct` | custom | `WifiP2pManager` | no-op |
| `mesh_multipeer` | custom | no-op | `MCSession` |
| `mesh_mdns` | bonsoir + multicast_dns | native | native |
| `mesh_hotspot` | custom | `WifiManager.startLocalOnlyHotspot` | no-op |

### Frame format (raw на transport уровне)

```
┌───────┬────────┬────────┬──────────┬──────────┐
│ ver   │ type   │ length │ src_pk   │ payload  │
│ 1B    │ 1B     │ 2B     │ 32B      │ variable │
└───────┴────────┴────────┴──────────┴──────────┘
```
- `type`: HANDSHAKE / DATA / KEEPALIVE / DISCONNECT
- `src_pk`: публичный ключ устройства отправителя
- payload: Noise handshake msg либо encrypted session data

### iOS VoIP Background ограничение

Фундаментальное: iOS не даёт держать в background P2P-сессии и принимать incoming call без APNs VoIP push. Mesh-режим в background на iOS работать не будет для входящих звонков.

**Решение:** VoIP push идёт через server → gateway-узел в mesh перекладывает в mesh-пакет → получатель будит приложение обычным push-механизмом. Если в mesh нет gateway'а — iOS-получатель не видит входящий звонок (принято как реальность).

### Permissions

**Android:** `BLUETOOTH_ADVERTISE`, `BLUETOOTH_CONNECT`, `BLUETOOTH_SCAN`, `ACCESS_FINE_LOCATION`, `CHANGE_WIFI_STATE`, `ACCESS_WIFI_STATE`, `NEARBY_WIFI_DEVICES` (API 33+), `FOREGROUND_SERVICE_CONNECTED_DEVICE`

**iOS:** `NSBluetoothAlwaysUsageDescription`, `NSLocalNetworkUsageDescription`, Bonjour service в Info.plist, **`com.apple.developer.networking.multicast` entitlement** (требует Apple approval — подать заявку в начале Phase 1, ~1-2 недели)

---

## 6. Layer 2 — Session & Crypto

### Три типа ключей

| Ключ | Тип | Срок жизни | Назначение | Хранение |
|------|-----|-----------|-----------|----------|
| User Identity Key | Ed25519 | постоянный | Подписывает device-certs, определяет identity юзера | Secure storage, locked |
| Device Key | Ed25519 | 30 дней (ротация) | Представляет телефон в mesh, публикуется в BLE | Hive (device-encrypted) |
| Session Key | X25519 ephemeral | per session (~1 час) | ChaCha20-Poly1305 на данных | In-memory + persisted to Hive |

Device certificate: `{device_pk, user_pk, valid_until, sig_by_user_identity}`.

### Bootstrap trust

**Online (через сервер):**
- При добавлении контакта → backend возвращает `{user_pk, [device_certs]}`
- Кэшируется в `ContactKeyStore` (Hive encrypted)
- Ротация device_pk пушится через FCM

**Event (QR):**
- Организатор генерит `event_identity_key`
- QR содержит: `{event_id, event_pk, event_name, invite_token, expires_at, org_sig}`
- Участник сканит → добавляет event в ContactKeyStore как virtual contact (группа)
- Каждый участник event-а публикует свой user_pk с подписью event_invite_token — это доказывает членство

**Face-to-face offline QR (Phase 3+):** QR с device_pk напрямую, аналог Signal safety numbers.

### Handshake — Noise IK

Используем `Noise_IK_25519_ChaChaPoly_SHA256`:

```
I = initiator knows recipient static key (из ContactKeyStore)
K = recipient's known static key
```

1-RTT handshake, работает offline (нет нужды в preconnect к серверу). Initiator → Responder:
```
msg1: e, es, s, ss, [payload: session_nonce + timestamp]
msg2: e, ee, se, [payload: ack]
──── established ────
```

Data frames: ChaCha20-Poly1305, chain key rotation per-message.

### Session lifecycle

- **Rekey**: каждые 1 час или 10K сообщений — новый ephemeral exchange без data loss
- **Idle timeout**: 30 мин без трафика → session closed
- **Replay protection**: 64-bit counter + sliding window
- **Reconnect**: новый handshake, old session GC-ится

### Threat model

| Атака | Защита |
|-------|--------|
| Пассивный подслух в mesh | Noise + onion (relay шифрованные данные не видит) |
| Активный MitM | Noise IK static key auth, MitM требует украденного ключа |
| Compromise одного device | Revoke device_pk на сервере + forward secrecy сессий до момента compromise |
| Replay | Session counter + timestamp |
| Sybil в event | event_invite_token подписан организатором |
| Impersonation через BLE | BLE содержит только prefix, Noise handshake проверяет полный ключ |

### Не защищено (осознанно)

- **Metadata** (relay видит размер пакета и время — traffic analysis возможен)
- **Contact graph disclosure** (твои контакты знают о тебе по design)
- **Physical presence** (BLE раскрывает включено ли устройство; ротация prefix смягчает)

### Модули

```
lib/core/mesh/crypto/
├── keys/
│   ├── user_identity_key.dart
│   ├── device_key.dart
│   └── contact_key_store.dart       # Hive-backed, encrypted
├── noise/
│   ├── noise_ik_handshake.dart      # Wrapper over Dart noise lib
│   └── session.dart                 # Active Noise state + counters
├── event/
│   ├── event_bootstrap.dart         # QR parsing, event identity setup
│   └── event_invite_signer.dart
└── session_manager.dart
```

---

## 7. Layer 3 — Routing

### Data structures

```dart
class RoutingTable {
  Map<PeerId, DirectLink> directLinks;             // 1-hop peers
  Map<UserPk, List<RouteEntry>> routes;            // multi-hop: dst -> [via nextHop, hops, metric]
  Map<UserPk, int> lastSeenSeq;                    // loop prevention
}

class DirectLink {
  PeerId peer;
  int rttMs;
  double packetLoss;
  int batterySignalled;       // 0..100 from peer
  DateTime lastHeartbeat;
  LinkType type;              // wifiDirect / commonWifi / multipeer / hotspot
}
```

### Gossip protocol — Hello packet

Отправляется каждым узлом своим directLink-соседям каждые 5 сек (active) / 30 сек (idle).

```
[seq_num(4B)] [src_user_pk(32B)] [battery(1B)] [num_routes(2B)]
[route_1: dst_user_pk(32B), hop_count(1B), link_quality(1B), age(2B)]
[route_2: ...]
```

Max ~30 routes в hello (~1 KB). Сосед мёржит → keeps best по метрике.

### Link metric formula

```
cost = hopCount * 100
     + rttMs / 10
     + packetLoss * 200
     - batteryRemaining / 10
     - linkStability
```

Пересчёт каждые 5 сек, кэшируется.

### Path selection для unicast

1. Lookup `routes[userPk]` → список путей
2. Top-3 по метрике, random selection из них (anti-correlation для onion)
3. Forward в nextHop
4. Если путь отсутствует → reactive `ROUTE_REQUEST` flood с TTL=5

### Epidemic flood — event broadcast

Для event-чата:
- Пакет несёт `event_id` в открытом поле (onion шифрует содержимое)
- Узел forward всем соседям **кроме src и seen**
- Dedup по `messageId` hash (LRU 10K entries, 1ч TTL)
- TTL=15 hop

### Anti-spam

1. **Sequence numbers + sliding window** per source
2. **Rate limiting**: 100 pkt/sec per direct link
3. **Lite proof-of-work**: 4-bit PoW для event-flood (~50 мс)
4. **Relay budget**: узел отказывается релеить при battery < 15%

### Модули

```
lib/core/mesh/routing/
├── routing_table.dart
├── hello_protocol.dart
├── route_discovery.dart
├── path_selector.dart
├── broadcast_flooder.dart
└── relay_policy.dart
```

### Риски

- **Gossip storm at 200 nodes**: смягчение через adaptive hello interval
- **Partition merge**: full table exchange при новом directLink
- **Low-battery fleet**: UI warning + автоматический gateway fallback

---

## 8. Layer 4 — Onion & Delivery

### Sphinx packet — fixed 2048 B

```
┌──────────────┬───────────────────────────────────────┐
│ ephemeral_pk │ onion_blob (fixed 2048B)              │
│ 32B          │ Layer1 { next_hop, Layer2 { ... } }   │
└──────────────┴───────────────────────────────────────┘
```

- ChaCha20-Poly1305 per layer, key derived через ECDH(ephemeral_pk, hop_device_pk)
- Relay peels своего слоя → видит только `next_hop + padded remainder`
- Last hop: `next_hop = 0x00` → payload для endpoint

### Hop count по типу трафика

| Traffic | Hops | Reason |
|---------|------|--------|
| Messages, voice-msg, file chunks | 3 | Standard anonymity |
| Voice RTP | 1 direct / 2 через SFU | Latency budget |
| Routing gossip | 0 (не onion) | Сам routing видит source |
| Store-and-forward discovery | 2 | Privacy/latency compromise |

### Circuit building

1. Pick 3 path кандидатов до recipient из routing table
2. Из каждого: первый hop, random middle, предпоследний
3. **Guard node** для первого hop — стабилен 24 часа (anti-probabilistic deanonymization)

### Store-and-Forward — epidemic delivery

**HeldBlobStore** на каждом устройстве:
- 100 MB default (настройка 10-500 MB)
- TTL 24 часа
- LRU eviction
- Entries: `{blobHash, recipientPkHint (16B BLAKE2b), encryptedTail, receivedAt, attemptCount}`
- Хранится в encrypted Hive

Flow:
```
Alice → 3-hop onion → hop N видит next_hop=Bob, но Bob unreachable
  → hop N кладёт tail в HeldBlobStore
  → Periodic gossip: "у меня blob для pkHint=..."
  → Любой узел видит Bob в routing → forward ему
  → Bob получает → ACK back → blob removed
```

### Dedup

- `messageId = BLAKE2b(senderPk || timestamp || nonce, 16)`
- Endpoint LRU seenMessageIds (100K entries, 24ч TTL)
- Duplicate → silent drop

### Gateway Bridge

**Политика:**
1. User consent toggle (default OFF)
2. Data budget: default 50 MB/день мобильных
3. Battery threshold: отключается при < 30%
4. Roaming guard: отдельный toggle

**Forward path:**
```
Mesh packet с dst=userX → routing видит dst не в local mesh
  → роутим как specialDestination "internet" к ближайшему gateway
  → gateway открывает mesh-bridge Socket.io к id.taler.tirol
  → POST /messenger/bridge/mesh-deliver (gateway cert authenticated)
  → server доставляет userX обычным path
```

**Reverse:** gateway subscribed на incoming mesh-user messages → ре-пакует в mesh onion → роутит соседям.

**Gateway видит:** src_user_pk + dst_user_pk, но не payload. Лучше чем direct server-access, хуже чем pure mesh.

### Модули

```
lib/core/mesh/onion/
├── sphinx_packet.dart
├── circuit_builder.dart
├── onion_router.dart
├── held_blob_store.dart
├── store_forward_scheduler.dart
├── dedup_cache.dart
└── gateway_bridge.dart
```

### Backend зависимости

Gateway-bridging требует изменений в NestJS — детали в Section 11.

---

## 9. Layer 5 — Service Layer

### TransportSelector

```dart
abstract class TransportSelector {
  Future<SendResult> sendMessage({
    required UserPk to,
    required Uint8List payload,
    required MessagePriority priority,
  });
  Stream<InboundMessage> get inbound;
}

enum TransportChoice { server, mesh, meshGateway }
```

**Default policy:**
- Обычные чаты → server-first (быстрее, history, push, multi-device)
- Event-чаты → mesh-only
- Нет internet у отправителя → mesh + held blob, авто-флаш при восстановлении
- User toggle «Prefer mesh» → перевешивает на mesh-first

### MessagingService

Обёртка над существующим `MessengerRepository` + новый `MeshMessagingAdapter`:

```dart
class MessagingService {
  final ServerMessenger server;
  final MeshMessagingAdapter mesh;
  final TransportSelector selector;

  Stream<Message> get inbound => mergeStreams(server.inbound, mesh.inbound);

  Future<void> send(Message msg) async {
    final choice = await selector.chooseFor(msg);
    switch (choice) {
      case TransportChoice.server: await server.send(msg);
      case TransportChoice.mesh: await mesh.send(msg);
      case TransportChoice.meshGateway: await mesh.sendViaGateway(msg);
    }
  }
}
```

### VoiceService (hybrid smart routing)

```dart
class VoiceService {
  Future<CallResult> startCall(UserPk peer) async {
    if (_hasDirectMeshLink(peer)) {
      return await _startP2PWebRTC(peer);
    }
    final sfu = await _findSFU(peer, maxHops: 2);
    if (sfu != null) {
      return await _joinThroughSFU(sfu, peer);
    }
    if (_gatewayAvailable) {
      return await _fallbackToLiveKit(peer);
    }
    return CallResult.failed(reason: CallFailReason.noPath, suggestVoiceMsg: true);
  }
}
```

WebRTC over mesh: `flutter_webrtc` custom ICE transport — RTP frames идут через `MeshTransport.send()` вместо прямого socket.

### GroupCallCoordinator (до 15 чел.)

- Root SFU выбирается из участников по `(battery*0.4 + cpuFree*0.3 + linkQuality*0.3)`
- SFU-tree: root + 1-2 sub-SFU для load distribution
- Каждый участник подключается к ближайшему SFU-узлу
- SFU-узлы обмениваются mixed audio
- Failover: если root уходит — re-election в течение 3 сек

### FileService

- Chunk size: 1 KB (помещается в 2048 B onion)
- Parallel send через 3 разных circuit (load balancing + redundancy)
- Dedup + reassembly на endpoint
- Resume: NACK missing chunks
- Файлы > 10 MB → suggestion "через gateway быстрее?"

### GatewayService

- iOS: foreground-only
- Android: foreground service с notification
- Open WS к `/messenger/bridge/inbound` с device-cert auth
- Telemetry: `bytesBridgedToday` для data budget enforcement

### Модули

```
lib/core/mesh/services/
├── transport_selector.dart
├── messaging_service.dart
├── voice_service_mesh.dart
├── group_call_coordinator.dart
├── file_service_mesh.dart
└── gateway_service.dart
```

---

## 10. Layer 6 — App Integration

### Изменения в существующих экранах

**ChatRoomScreen** — transport indicator в header:
- Иконка: 🌐 server / 📡 mesh / 🔁 mesh+gateway
- Long tap → bottom sheet с деталями доставки

**VoiceCallScreen** — badge с типом transport:
- "через сеть" / "через mesh (1 hop)" / "через соседей (2 hop)"
- Snackbar при деградации качества

**Settings** — новая секция «Mesh Network»:
- Toggle «Подключаться к mesh-соседям» (default ON)
- Toggle «Быть gateway'ем» (default OFF)
  - Sub: «только WiFi» (ON), «макс MB/день» (50)
- Toggle «Предпочитать mesh» (default OFF, advanced)
- Status card: текущие peers, gateway статус
- Slider: HeldBlobStore лимит (10-500 MB)

### Новая секция в Dashboard — «Events»

- Кнопка «Запустить event»:
  - Ввод названия, длительности, лимита участников
  - Генерация QR (full-screen) + добавление event-чата в список
- Кнопка «Присоединиться к event»:
  - QR scanner
  - Валидация подписи организатора
  - Добавление event-чата с тегом `[EVENT]`

### Модуль `lib/features/mesh/`

```
lib/features/mesh/
├── data/
│   └── datasources/mesh_local_datasource.dart
├── domain/
│   ├── entities/
│   │   ├── mesh_status.dart
│   │   └── event_session.dart
│   └── repositories/mesh_repository.dart
└── presentation/
    ├── bloc/
    │   ├── mesh_status_bloc.dart
    │   └── event_launch_bloc.dart
    └── screens/
        ├── mesh_settings_screen.dart
        ├── event_launcher_screen.dart
        ├── event_qr_display_screen.dart
        └── event_qr_scanner_screen.dart
```

### Assistant-first integration (Phase 2)

Новые tools в OpenAI Realtime session:
- `createEvent(name, durationHours, maxParticipants)` → генерит QR, показывает, озвучивает
- `getMeshStatus()` → текущие peers, gateway status
- `setGatewayMode(enabled, durationMinutes)` → temporary toggle

---

## 11. Backend Changes (NestJS)

Изменения в `~/taler-id/` для поддержки mesh:

### Новые endpoints

**`src/messenger/bridge.controller.ts`:**
- `POST /messenger/bridge/mesh-deliver` — gateway передаёт mesh-пакет для доставки юзеру
- `WS /messenger/bridge/inbound` — gateway держит open WS для обратной доставки

**`src/profile/keys.controller.ts`:**
- `POST /profile/device-keys` — регистрация нового device_cert
- `GET /profile/contacts/{userId}/keys` — получить актуальные device_certs контакта
- `POST /profile/device-keys/revoke` — ревокация скомпрометированного device_pk
- FCM push при ротации ключей контакта

### Новые Prisma модели

```prisma
model DeviceKey {
  id           String   @id @default(uuid())
  userId       String
  devicePk     String   @unique  // hex
  certificate  String             // signed cert bytes (hex)
  validUntil   DateTime
  revokedAt    DateTime?
  createdAt    DateTime @default(now())
  user         User     @relation(fields: [userId], references: [id])
}

model MeshBridgeToken {
  id         String   @id @default(uuid())
  deviceId   String   @unique
  userId     String
  devicePk   String
  expiresAt  DateTime
  createdAt  DateTime @default(now())
  lastUsedAt DateTime?
}

model MeshEvent {
  id          String   @id @default(uuid())
  organizerId String
  name        String
  eventPk     String   @unique
  inviteToken String
  expiresAt   DateTime
  createdAt   DateTime @default(now())
}
```

Объём: ~800 строк TS + 2 миграции Prisma.

---

## 12. Phased Rollout

Проект разбит на 4 фазы по ~3 месяца. Каждая — самостоятельная ценность, деплой по завершению.

### Phase 1 — «Foundation» (~3 мес)

**Цель:** базовый mesh transport + 1-hop text messaging между знакомыми в общем WiFi.

Deliverables:
- Transport Layer (все 5 plugins, BLE discovery + mDNS + общий WiFi)
- Session Layer (Noise IK, ContactKeyStore, device-key registration в backend)
- Минимальный Routing (только direct links, без multi-hop)
- Минимальный Onion (1-hop, не fixed size пока)
- MessagingService + TransportSelector в existing мессенджер (transparent fallback)
- Settings UI секция «Mesh Network»
- Apple multicast entitlement approval

Testing:
- Unit tests каждого layer interface
- Integration: two emulators на общем WiFi шлют текстовые сообщения
- Manual: iOS + Android, разные AP-сценарии

### Phase 2 — «Messaging at Scale» (~3 мес)

**Цель:** полноценный mesh-мессенджер работающий на конференции 200 чел.

Deliverables:
- Multi-hop routing (distance-vector gossip, adaptive hello, epidemic flood)
- Full Onion (Sphinx, 3-hop, fixed 2048 B, guard nodes)
- HeldBlobStore + store-and-forward с gossip-driven delivery
- FileService (chunked, resumable)
- Event mode: QR-generator / scanner, event identity в ContactKeyStore
- Event UI в Dashboard, tagged event-чаты в мессенджере
- GatewayService + backend bridge endpoints
- Assistant tools: createEvent / getMeshStatus / setGatewayMode

Testing:
- Scale test: 20-50 эмуляторов через Docker (network namespace mesh simulation)
- Event field test: реальная конференция на 50+ человек
- Gateway test: один узел с интернетом, остальные в airplane mode

### Phase 3 — «Voice» (~3-4 мес)

**Цель:** 1-на-1 и малые групповые звонки без сервера.

Deliverables:
- WebRTC over MeshTransport (custom ICE)
- VoiceService hybrid routing (direct → SFU-2hop → voice-msg)
- SFU functionality в Android client (audio mixing, forwarding)
- CallKit integration (iOS via gateway VoIP push)
- Call UI с transport badge

Testing:
- Two-device call tests (existing integration tests adapted)
- Multi-hop call через SFU-узел
- Quality benchmarks: latency, MOS, packet loss по сценариям

### Phase 4 — «Group Calls» (~3 мес)

**Цель:** full-duplex 10-15 участников через SFU-tree.

Deliverables:
- GroupCallCoordinator (root election, sub-SFU selection, failover)
- Audio mixing на SFU-узлах
- Group call UI (participant list, mute controls, quality indicators)
- Load testing 15 участников

Testing:
- Lab test с 15 физическими устройствами
- Stress: рандомные disconnects, battery drain, CPU contention

---

## 13. Testing Strategy

### Unit tests — per layer

Каждый abstract class имеет mock-based unit tests для сервисов, использующих его. Flutter `test` framework, coverage > 80% на критических модулях (crypto, onion, routing).

### Integration tests

Расширить existing `integration_test/` структуру:
- `integration_test/mesh/` — mesh-specific tests
- `mesh_transport_test.dart` — два эмулятора
- `mesh_routing_test.dart` — три+ эмулятора, multi-hop
- `mesh_voice_test.dart` — расширение существующего call test
- `event_mode_test.dart` — QR flow

### Scale simulation

Docker-based mesh simulator:
- N containers, каждый запускает Android emulator + Flutter app
- Virtual network с latency/loss injection
- Automated scenarios: join/leave churn, partition/merge, broadcast storm

### Field tests

- **Phase 1:** Два человека в офисе/кафе
- **Phase 2:** Реальная конференция 50+ чел.
- **Phase 3:** Группа в походе / за городом (нет интернета)
- **Phase 4:** 15 чел. в одной комнате

### Security review

External crypto review перед Phase 2 release (Noise implementation, onion construction, key rotation). Таргет: 1-2 независимых security аудита.

---

## 14. Open Risks & Mitigations

### Высокие

1. **iOS background ограничения** — неизбежны для текущего iOS API. Mitigation: gateway-based VoIP push; honest UX messaging про background-поведение.
2. **Apple multicast entitlement delay** — может задержать Phase 1 на 1-2 недели. Mitigation: подаём заявку сразу в начале Phase 1, параллельно разрабатываем Android-only.
3. **Battery drain на long-lived BLE scan** — может оттолкнуть юзеров. Mitigation: adaptive duty-cycle + honest power warning; можно полностью отключить в Settings.

### Средние

4. **Gossip storm at 200-node event** — может задушить трафик. Mitigation: adaptive hello + load-based throttling; tested в Docker simulation перед field test.
5. **Android Wi-Fi Direct fragmentation** — vendor-specific баги на некоторых Android OEM (Samsung, Xiaomi). Mitigation: fallback цепочка (common WiFi → Direct → hotspot); manual QA на 5+ OEM.
6. **Store-and-forward storage abuse** — злонамеренный узел спамит held blobs, забивая кэши. Mitigation: per-source rate limit в HeldBlobStore, PoW на submit, reputation tracking.

### Низкие

7. **WebRTC over custom transport instability** — flutter_webrtc custom ICE — сырой API. Mitigation: prototype в Phase 3, запас в расписании; fallback на direct UDP socket если webrtc API не работает.
8. **Onion circuit construction latency** — building 3-hop circuit ~100-200 мс до первого сообщения. Mitigation: pre-warm circuits к частым контактам, keep-alive idle circuits.

---

## 15. Success Metrics

### Phase 1
- Сообщение доставлено cross-platform (iOS ↔ Android) через mesh в >95% случаев когда оба на общем WiFi
- Delivery latency < 500 ms
- Battery drain < 3% /hour в idle с mesh включённым

### Phase 2
- 50+ чел. event успешно работает ≥ 2 часа без потерь сообщений
- Multi-hop (3 hops) delivery > 90% успешности
- Gateway bridge: < 500 ms от mesh до server-доставки

### Phase 3
- 1-на-1 voice MOS > 3.5 (vs 4.2 baseline LiveKit)
- 2-hop SFU call MOS > 3.0
- < 300 ms setup latency

### Phase 4
- 15-чел. full-duplex call MOS > 3.0
- SFU failover < 3 сек
- CPU overhead < 30% на SFU-узле

---

## 16. Next Steps

1. User review этого spec (текущий шаг)
2. Корректировки по feedback
3. Invoke `writing-plans` skill → детальный implementation plan для Phase 1
4. Start implementation в `~/Downloads/taler_id_mesh/` на ветке `feature/mesh-network`

---

## Appendix A — Glossary

- **PeerId** — transport-level identifier (BLE hash / mDNS name), short-lived
- **UserPk** — user identity public key, long-lived
- **DevicePk** — device public key, rotated monthly
- **Circuit** — 3-hop onion path from sender to recipient
- **Guard** — stable first-hop peer (anti-correlation)
- **Gateway** — node with internet that bridges mesh to server
- **HeldBlob** — encrypted packet cached for future delivery
- **Event** — temporary group identity with QR-distributed invite
- **SFU** — Selective Forwarding Unit (voice mixing node)
- **Noise IK** — Noise handshake pattern (Initiator Knows recipient static key)

## Appendix B — References

- Briar Project: https://briarproject.org/ (trust model, epidemic delivery)
- Tor Sphinx format: https://spec.torproject.org/tor-spec/
- Noise Protocol Framework: https://noiseprotocol.org/
- B.A.T.M.A.N. routing: https://www.open-mesh.org/projects/batman-adv/wiki
- flutter_webrtc: https://github.com/flutter-webrtc/flutter-webrtc

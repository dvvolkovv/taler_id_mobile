# Contacts Offline (Read + Accept/Reject) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Cache contacts + pending requests in Hive for offline display; capture accept / reject of incoming requests in the shared outbox so the actions replay on reconnect. Reuses the outbox infrastructure built for notes (2.1) and calendar (2.2). **No backend changes.**

**Architecture:** `ContactsLocalDataSource` (Hive box `contacts_local`) caches an aggregated `ContactItemEntity` list. `ContactsRepositoryImpl` orchestrates refresh (three parallel GETs), optimistic local mutation on accept/reject, and outbox enqueue. The new `ContactsOutboxReplayHandler` (`feature='contacts'`) maps `OutboxOp(update)` with `payload.action='accept'|'reject'` to the existing `MessengerRemoteDataSource.acceptContactRequest` / `rejectContactRequest` HTTP calls. `contacts_screen.dart` (521 lines) is refactored to subscribe to the repo stream instead of calling endpoints directly. Send-request stays online-only.

**Tech Stack:** Flutter + Hive + Freezed on the client. No NestJS work.

**Spec:** `docs/superpowers/specs/2026-05-14-contacts-offline-design.md`

**Repos:**
- Mobile: `~/Downloads/taler_id_mobile/` (work on `dev` branch)

---

## File Structure

### Mobile (`taler_id_mobile`)

- **Create** `lib/features/contacts/domain/entities/contact_item_entity.dart` — Freezed `ContactItemEntity` + `ContactStatus` enum.
- **Create** `lib/features/contacts/domain/repositories/i_contacts_repository.dart`.
- **Create** `lib/features/contacts/data/datasources/contacts_local_datasource.dart` (Hive box `contacts_local`).
- **Create** `lib/features/contacts/data/repositories/contacts_repository_impl.dart`.
- **Create** `lib/features/contacts/data/services/contacts_outbox_replay_handler.dart`.
- **Modify** `lib/features/contacts/presentation/screens/contacts_screen.dart` — route data through the repo; preserve UI.
- **Modify** `lib/core/di/service_locator.dart` — open Hive box; register services + replay handler.
- Test files mirroring each new class.

### Reused (NO new code)
- `lib/core/storage/outbox_op.dart`, `outbox_queue.dart`, `services/outbox_replay_service.dart`, `services/outbox_replay_handler.dart`, `services/connectivity_watcher.dart` — all live on `dev`.
- `lib/features/messenger/data/datasources/messenger_remote_datasource.dart` — existing `sendContactRequest`, `getContactRequests`, `getSentContactRequests`, `acceptContactRequest`, `rejectContactRequest` methods are the HTTP layer.

### Pre-existing bug fix (incidental)
The current `contacts_screen.dart:144` calls `PATCH /messenger/contacts/requests/{id}/decline` but the server endpoint is `/reject`. Routing through `MessengerRemoteDataSource.rejectContactRequest` (which uses the correct `/reject`) fixes this latent bug.

---

## Task 1: Mobile — `ContactItemEntity` + `ContactStatus` (Freezed)

**Files:**
- Create: `~/Downloads/taler_id_mobile/lib/features/contacts/domain/entities/contact_item_entity.dart`

- [ ] **Step 0: Switch to `dev`**

```bash
cd ~/Downloads/taler_id_mobile
git checkout dev && git pull origin dev
```

- [ ] **Step 1: Create the entity**

```dart
// lib/features/contacts/domain/entities/contact_item_entity.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'contact_item_entity.freezed.dart';
part 'contact_item_entity.g.dart';

enum ContactStatus {
  @JsonValue('incoming') incoming,
  @JsonValue('accepted') accepted,
  @JsonValue('pending') pending,
}

@freezed
class ContactItemEntity with _$ContactItemEntity {
  const factory ContactItemEntity({
    required String userId,
    required String name,
    String? username,
    String? avatarUrl,
    required ContactStatus status,
    String? conversationId,
    String? requestId,
    DateTime? requestSentAt,
    @Default(false) bool localPending,
  }) = _ContactItemEntity;

  factory ContactItemEntity.fromJson(Map<String, dynamic> json) =>
      _$ContactItemEntityFromJson(json);
}
```

- [ ] **Step 2: Code-gen**

```bash
cd ~/Downloads/taler_id_mobile
dart run build_runner build --delete-conflicting-outputs
```

Expect `contact_item_entity.freezed.dart` and `contact_item_entity.g.dart` to be created. The pre-existing mesh-crypto SEVERE errors are unrelated; ignore them as long as the two new files are produced.

- [ ] **Step 3: Analyze**

```bash
flutter analyze lib/features/contacts/domain/entities/contact_item_entity.dart
```

Expected: no errors.

- [ ] **Step 4: Commit**

```bash
git add lib/features/contacts/domain/entities/contact_item_entity.dart lib/features/contacts/domain/entities/contact_item_entity.freezed.dart lib/features/contacts/domain/entities/contact_item_entity.g.dart
git commit -m "$(cat <<'EOF'
feat(contacts): add ContactItemEntity (Freezed) + ContactStatus enum

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 2: Mobile — `IContactsRepository` interface

**Files:**
- Create: `~/Downloads/taler_id_mobile/lib/features/contacts/domain/repositories/i_contacts_repository.dart`

- [ ] **Step 1: Create the interface**

```dart
// lib/features/contacts/domain/repositories/i_contacts_repository.dart
import '../entities/contact_item_entity.dart';

abstract class IContactsRepository {
  Stream<List<ContactItemEntity>> watchAll();
  Future<void> refresh();
  /// Online-only. Throws on network error.
  Future<Map<String, dynamic>> sendContactRequest(String receiverId);
  Future<void> acceptContactRequest(String requestId, String userId);
  Future<void> rejectContactRequest(String requestId, String userId);
  Stream<int> watchPendingCount();
}
```

- [ ] **Step 2: Analyze**

```bash
flutter analyze lib/features/contacts/domain/repositories/i_contacts_repository.dart
```

- [ ] **Step 3: Commit**

```bash
git add lib/features/contacts/domain/repositories/i_contacts_repository.dart
git commit -m "$(cat <<'EOF'
feat(contacts): add IContactsRepository abstract interface

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 3: Mobile — `ContactsLocalDataSource` (TDD)

**Files:**
- Create: `~/Downloads/taler_id_mobile/lib/features/contacts/data/datasources/contacts_local_datasource.dart`
- Create: `~/Downloads/taler_id_mobile/test/features/contacts/data/datasources/contacts_local_datasource_test.dart`

- [ ] **Step 1: Failing test**

```dart
// test/features/contacts/data/datasources/contacts_local_datasource_test.dart
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:taler_id_mobile/features/contacts/data/datasources/contacts_local_datasource.dart';
import 'package:taler_id_mobile/features/contacts/domain/entities/contact_item_entity.dart';

class _FakePathProvider extends PathProviderPlatform with MockPlatformInterfaceMixin {
  final String dir;
  _FakePathProvider(this.dir);
  @override Future<String?> getApplicationDocumentsPath() async => dir;
  @override Future<String?> getApplicationSupportPath() async => dir;
  @override Future<String?> getTemporaryPath() async => dir;
}

ContactItemEntity ci(String userId, ContactStatus status, {String? name}) =>
    ContactItemEntity(
      userId: userId,
      name: name ?? 'name-$userId',
      status: status,
    );

void main() {
  late Directory tempDir;

  setUpAll(() { TestWidgetsFlutterBinding.ensureInitialized(); });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('contacts_local_test_');
    PathProviderPlatform.instance = _FakePathProvider(tempDir.path);
    Hive.init(tempDir.path);
    await Hive.openBox<String>(ContactsLocalDataSource.boxName);
  });

  tearDown(() async {
    await Hive.close();
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  test('upsert + getAll returns items sorted incoming → accepted → pending', () async {
    final ds = ContactsLocalDataSource();
    await ds.upsert(ci('u1', ContactStatus.pending, name: 'Zed'));
    await ds.upsert(ci('u2', ContactStatus.accepted, name: 'Bob'));
    await ds.upsert(ci('u3', ContactStatus.incoming, name: 'Alice'));
    await ds.upsert(ci('u4', ContactStatus.accepted, name: 'alice2'));
    final list = await ds.getAll();
    expect(list.map((c) => c.userId).toList(), ['u3', 'u4', 'u2', 'u1']);
  });

  test('remove drops the entry', () async {
    final ds = ContactsLocalDataSource();
    await ds.upsert(ci('u1', ContactStatus.accepted));
    await ds.remove('u1');
    expect((await ds.getAll()).isEmpty, true);
  });

  test('upsert replaces existing by userId', () async {
    final ds = ContactsLocalDataSource();
    await ds.upsert(ci('u1', ContactStatus.incoming));
    await ds.upsert(ci('u1', ContactStatus.accepted, name: 'updated'));
    final list = await ds.getAll();
    expect(list.length, 1);
    expect(list[0].status, ContactStatus.accepted);
    expect(list[0].name, 'updated');
  });

  test('watchAll emits on changes', () async {
    final ds = ContactsLocalDataSource();
    final emissions = <int>[];
    final sub = ds.watchAll().listen((items) => emissions.add(items.length));
    await Future<void>.delayed(const Duration(milliseconds: 50));
    await ds.upsert(ci('u1', ContactStatus.accepted));
    await Future<void>.delayed(const Duration(milliseconds: 50));
    await ds.upsert(ci('u2', ContactStatus.incoming));
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(emissions, contains(1));
    expect(emissions, contains(2));
    await sub.cancel();
  });
}
```

- [ ] **Step 2: Run — fail (file missing)**

```bash
flutter test test/features/contacts/data/datasources/contacts_local_datasource_test.dart
```

- [ ] **Step 3: Implement**

```dart
// lib/features/contacts/data/datasources/contacts_local_datasource.dart
import 'dart:async';
import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../../domain/entities/contact_item_entity.dart';

class ContactsLocalDataSource {
  static const String boxName = 'contacts_local';

  Box<String> get _box => Hive.box<String>(boxName);

  Future<List<ContactItemEntity>> getAll() async {
    final list = _box.keys
        .cast<String>()
        .map((k) => _decode(_box.get(k)!))
        .whereType<ContactItemEntity>()
        .toList();
    list.sort((a, b) {
      final order = {
        ContactStatus.incoming: 0,
        ContactStatus.accepted: 1,
        ContactStatus.pending: 2,
      };
      final cmp = order[a.status]!.compareTo(order[b.status]!);
      if (cmp != 0) return cmp;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return list;
  }

  Future<ContactItemEntity?> getById(String userId) async {
    final raw = _box.get(userId);
    if (raw == null) return null;
    return _decode(raw);
  }

  Future<void> upsert(ContactItemEntity item) async {
    await _box.put(item.userId, jsonEncode(item.toJson()));
  }

  Future<void> remove(String userId) async {
    await _box.delete(userId);
  }

  Stream<List<ContactItemEntity>> watchAll() {
    final controller = StreamController<List<ContactItemEntity>>.broadcast();
    StreamSubscription? sub;
    controller.onListen = () async {
      controller.add(await getAll());
      sub = _box.watch().listen((_) async {
        controller.add(await getAll());
      });
    };
    controller.onCancel = () async {
      await sub?.cancel();
    };
    return controller.stream;
  }

  ContactItemEntity? _decode(String raw) {
    try {
      return ContactItemEntity.fromJson(Map<String, dynamic>.from(jsonDecode(raw) as Map));
    } catch (_) {
      return null;
    }
  }
}
```

- [ ] **Step 4: Run — 4/4 PASS**

```bash
flutter test test/features/contacts/data/datasources/contacts_local_datasource_test.dart
```

- [ ] **Step 5: Commit**

```bash
git add lib/features/contacts/data/datasources/contacts_local_datasource.dart test/features/contacts/data/datasources/contacts_local_datasource_test.dart
git commit -m "$(cat <<'EOF'
feat(contacts): add ContactsLocalDataSource (Hive box contacts_local)

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 4: Mobile — `ContactsRepositoryImpl` (TDD)

**Files:**
- Create: `~/Downloads/taler_id_mobile/lib/features/contacts/data/repositories/contacts_repository_impl.dart`
- Create: `~/Downloads/taler_id_mobile/test/features/contacts/data/repositories/contacts_repository_impl_test.dart`

### Step 1: Failing tests

```dart
// test/features/contacts/data/repositories/contacts_repository_impl_test.dart
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:taler_id_mobile/core/storage/outbox_op.dart';
import 'package:taler_id_mobile/core/storage/outbox_queue.dart';
import 'package:taler_id_mobile/features/contacts/data/datasources/contacts_local_datasource.dart';
import 'package:taler_id_mobile/features/contacts/data/repositories/contacts_repository_impl.dart';
import 'package:taler_id_mobile/features/contacts/domain/entities/contact_item_entity.dart';
import 'package:taler_id_mobile/features/messenger/data/datasources/messenger_remote_datasource.dart';
import 'package:taler_id_mobile/features/messenger/domain/entities/conversation_entity.dart';

class _MockRemote extends Mock implements MessengerRemoteDataSource {}

class _FakePathProvider extends PathProviderPlatform with MockPlatformInterfaceMixin {
  final String dir;
  _FakePathProvider(this.dir);
  @override Future<String?> getApplicationDocumentsPath() async => dir;
  @override Future<String?> getApplicationSupportPath() async => dir;
  @override Future<String?> getTemporaryPath() async => dir;
}

void main() {
  late Directory tempDir;
  late ContactsLocalDataSource local;
  late OutboxQueue queue;
  late _MockRemote remote;
  late ContactsRepositoryImpl repo;

  setUpAll(() { TestWidgetsFlutterBinding.ensureInitialized(); });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('contacts_repo_test_');
    PathProviderPlatform.instance = _FakePathProvider(tempDir.path);
    Hive.init(tempDir.path);
    await Hive.openBox<String>(ContactsLocalDataSource.boxName);
    await Hive.openBox<String>(OutboxQueue.boxName);
    local = ContactsLocalDataSource();
    queue = OutboxQueue();
    remote = _MockRemote();
    repo = ContactsRepositoryImpl(local: local, remote: remote, outbox: queue);
  });

  tearDown(() async {
    await Hive.close();
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  test('acceptContactRequest sets localPending and enqueues update op with action=accept', () async {
    await local.upsert(ContactItemEntity(
      userId: 'u1',
      name: 'Alice',
      status: ContactStatus.incoming,
      requestId: 'req-1',
    ));
    await repo.acceptContactRequest('req-1', 'u1');
    final ops = await queue.pending();
    expect(ops.length, 1);
    expect(ops[0].op, OutboxOpKind.update);
    expect(ops[0].entityId, 'req-1');
    expect(ops[0].feature, 'contacts');
    expect(ops[0].payload!['action'], 'accept');
    final localNow = await local.getById('u1');
    expect(localNow!.localPending, true);
    expect(localNow.status, ContactStatus.accepted);
  });

  test('rejectContactRequest removes local item and enqueues update op with action=reject', () async {
    await local.upsert(ContactItemEntity(
      userId: 'u1',
      name: 'Alice',
      status: ContactStatus.incoming,
      requestId: 'req-1',
    ));
    await repo.rejectContactRequest('req-1', 'u1');
    expect(await local.getById('u1'), isNull);
    final ops = await queue.pending();
    expect(ops.length, 1);
    expect(ops[0].payload!['action'], 'reject');
  });

  test('accept then reject for same requestId — second op replaces first', () async {
    await local.upsert(ContactItemEntity(
      userId: 'u1',
      name: 'Alice',
      status: ContactStatus.incoming,
      requestId: 'req-1',
    ));
    await repo.acceptContactRequest('req-1', 'u1');
    await repo.rejectContactRequest('req-1', 'u1');
    final ops = await queue.pending();
    expect(ops.length, 1);
    expect(ops[0].payload!['action'], 'reject');
  });

  test('sendContactRequest delegates to remote and propagates exceptions', () async {
    when(() => remote.sendContactRequest('u-target'))
        .thenThrow(Exception('offline'));
    await expectLater(
      () => repo.sendContactRequest('u-target'),
      throwsA(isA<Exception>()),
    );
  });

  test('refresh merges incoming + accepted + sent lists, preserves localPending', () async {
    when(() => remote.getContactRequests()).thenAnswer((_) async => [
      {'id': 'req-A', 'senderId': 'u-A', 'senderName': 'Alice', 'status': 'PENDING'},
    ]);
    when(() => remote.getConversations()).thenAnswer((_) async => [
      const ConversationEntity(
        id: 'conv-1',
        participantIds: ['u-self', 'u-B'],
        type: 'DIRECT',
        otherUserId: 'u-B',
        otherUserName: 'Bob',
      ),
    ]);
    when(() => remote.getSentContactRequests()).thenAnswer((_) async => [
      {'id': 'req-C', 'receiverId': 'u-C', 'receiverName': 'Carol', 'status': 'PENDING'},
    ]);

    // Pre-existing local entry with localPending=true to verify preservation.
    await local.upsert(ContactItemEntity(
      userId: 'u-A',
      name: 'Alice (stale)',
      status: ContactStatus.incoming,
      requestId: 'req-A',
      localPending: true,
    ));

    await repo.refresh();

    final all = await local.getAll();
    final aliceLocal = all.firstWhere((c) => c.userId == 'u-A');
    expect(aliceLocal.localPending, true, reason: 'localPending must survive refresh');
    expect(all.any((c) => c.userId == 'u-B' && c.status == ContactStatus.accepted), true);
    expect(all.any((c) => c.userId == 'u-C' && c.status == ContactStatus.pending), true);
  });
}
```

### Step 2: Run — fail

```bash
flutter test test/features/contacts/data/repositories/contacts_repository_impl_test.dart
```

### Step 3: Implement

Look at `MessengerRemoteDataSource` to confirm `getConversations` exists. It does — used by the existing screen at line 68 (`/messenger/conversations`). The repo will call it through the existing method.

Verify by inspecting `lib/features/messenger/data/datasources/messenger_remote_datasource.dart` for `getConversations` and `getSentContactRequests`. If `getConversations` is named differently (e.g. `listConversations`), adapt the impl accordingly — same name in the mock above must match.

```dart
// lib/features/contacts/data/repositories/contacts_repository_impl.dart
import 'dart:async';
import '../../../../core/storage/outbox_op.dart';
import '../../../../core/storage/outbox_queue.dart';
import '../../../messenger/data/datasources/messenger_remote_datasource.dart';
import '../../../messenger/domain/entities/conversation_entity.dart';
import '../../domain/entities/contact_item_entity.dart';
import '../../domain/repositories/i_contacts_repository.dart';
import '../datasources/contacts_local_datasource.dart';
import 'package:uuid/uuid.dart';

class ContactsRepositoryImpl implements IContactsRepository {
  final ContactsLocalDataSource _local;
  final MessengerRemoteDataSource _remote;
  final OutboxQueue _outbox;
  final Uuid _uuid = const Uuid();

  ContactsRepositoryImpl({
    required ContactsLocalDataSource local,
    required MessengerRemoteDataSource remote,
    required OutboxQueue outbox,
  })  : _local = local,
        _remote = remote,
        _outbox = outbox;

  @override
  Stream<List<ContactItemEntity>> watchAll() => _local.watchAll();

  @override
  Future<void> refresh() async {
    try {
      final res = await Future.wait([
        _remote.getContactRequests(),
        _remote.getConversations(),
        _remote.getSentContactRequests(),
      ]);
      final incomingRaw = res[0] as List<Map<String, dynamic>>;
      final convs = res[1] as List<ConversationEntity>;
      final sentRaw = res[2] as List<Map<String, dynamic>>;

      final keep = <String>{};

      for (final r in incomingRaw) {
        final req = Map<String, dynamic>.from(r);
        if ((req['status'] as String? ?? 'PENDING') != 'PENDING') continue;
        final userId = req['senderId'] as String? ?? '';
        if (userId.isEmpty) continue;
        keep.add(userId);
        await _upsertPreservingPending(ContactItemEntity(
          userId: userId,
          name: req['senderName'] as String? ?? '',
          username: req['senderUsername'] as String?,
          avatarUrl: req['senderAvatar'] as String?,
          status: ContactStatus.incoming,
          requestId: req['id'] as String?,
        ));
      }

      for (final conv in convs) {
        if (conv.type.toUpperCase() != 'DIRECT') continue;
        final userId = conv.otherUserId ?? '';
        if (userId.isEmpty) continue;
        if (keep.contains(userId)) continue; // incoming wins
        keep.add(userId);
        await _upsertPreservingPending(ContactItemEntity(
          userId: userId,
          name: conv.otherUserName ?? '',
          username: null, // ConversationEntity does not expose otherUserUsername
          avatarUrl: conv.otherUserAvatar,
          status: ContactStatus.accepted,
          conversationId: conv.id,
        ));
      }

      for (final r in sentRaw) {
        final req = Map<String, dynamic>.from(r);
        if ((req['status'] as String? ?? 'PENDING') != 'PENDING') continue;
        final userId = req['receiverId'] as String? ?? '';
        if (userId.isEmpty) continue;
        if (keep.contains(userId)) continue;
        keep.add(userId);
        await _upsertPreservingPending(ContactItemEntity(
          userId: userId,
          name: req['receiverName'] as String? ?? '',
          username: req['receiverUsername'] as String?,
          avatarUrl: req['receiverAvatar'] as String?,
          status: ContactStatus.pending,
          requestId: req['id'] as String?,
          requestSentAt: DateTime.tryParse(req['updatedAt'] as String? ?? '') ??
              DateTime.tryParse(req['createdAt'] as String? ?? ''),
        ));
      }

      // Drop local items that the server no longer mentions (unless they have localPending).
      final existing = await _local.getAll();
      for (final old in existing) {
        if (old.localPending) continue;
        if (!keep.contains(old.userId)) {
          await _local.remove(old.userId);
        }
      }
    } catch (_) {
      // offline / failure → keep local intact
    }
  }

  Future<void> _upsertPreservingPending(ContactItemEntity incoming) async {
    final existing = await _local.getById(incoming.userId);
    if (existing != null && existing.localPending) return;
    await _local.upsert(incoming);
  }

  @override
  Future<Map<String, dynamic>> sendContactRequest(String receiverId) {
    return _remote.sendContactRequest(receiverId);
  }

  @override
  Future<void> acceptContactRequest(String requestId, String userId) async {
    final current = await _local.getById(userId);
    if (current != null) {
      await _local.upsert(current.copyWith(
        status: ContactStatus.accepted,
        localPending: true,
      ));
    }
    await _squashAndEnqueue(requestId, 'accept');
  }

  @override
  Future<void> rejectContactRequest(String requestId, String userId) async {
    await _local.remove(userId);
    await _squashAndEnqueue(requestId, 'reject');
  }

  Future<void> _squashAndEnqueue(String requestId, String action) async {
    final ops = await _outbox.pending();
    for (final op in ops) {
      if (op.feature == 'contacts' && op.entityId == requestId) {
        await _outbox.remove(op.opId);
      }
    }
    await _outbox.enqueue(OutboxOp(
      opId: _uuid.v4(),
      feature: 'contacts',
      op: OutboxOpKind.update,
      entityId: requestId,
      payload: {'action': action},
      createdAt: DateTime.now().toUtc(),
    ));
  }

  @override
  Stream<int> watchPendingCount() async* {
    yield (await _local.getAll()).where((c) => c.localPending).length;
    await for (final list in _local.watchAll()) {
      yield list.where((c) => c.localPending).length;
    }
  }
}
```

### Step 4: Run — 5/5 PASS

```bash
flutter test test/features/contacts/data/repositories/contacts_repository_impl_test.dart
```

If a test fails because `MessengerRemoteDataSource.getConversations` is actually named differently (e.g. `getConversationList`), update both the mock in the test and the call in the impl. Same for `getSentContactRequests` if absent (check `lib/features/messenger/data/datasources/messenger_remote_datasource.dart` for actual names; both names used above match what was confirmed in the spec exploration).

### Step 5: Commit

```bash
git add lib/features/contacts/data/repositories/contacts_repository_impl.dart test/features/contacts/data/repositories/contacts_repository_impl_test.dart
git commit -m "$(cat <<'EOF'
feat(contacts): add ContactsRepositoryImpl with optimistic accept/reject + squash

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 5: Mobile — `ContactsOutboxReplayHandler` (TDD)

**Files:**
- Create: `~/Downloads/taler_id_mobile/lib/features/contacts/data/services/contacts_outbox_replay_handler.dart`
- Create: `~/Downloads/taler_id_mobile/test/features/contacts/data/services/contacts_outbox_replay_handler_test.dart`

### Step 1: Failing tests

```dart
// test/features/contacts/data/services/contacts_outbox_replay_handler_test.dart
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:taler_id_mobile/core/services/outbox_replay_handler.dart';
import 'package:taler_id_mobile/core/storage/outbox_op.dart';
import 'package:taler_id_mobile/features/contacts/data/services/contacts_outbox_replay_handler.dart';
import 'package:taler_id_mobile/features/messenger/data/datasources/messenger_remote_datasource.dart';

class _MockRemote extends Mock implements MessengerRemoteDataSource {}

OutboxOp _op(String action) => OutboxOp(
      opId: 'op-1',
      feature: 'contacts',
      op: OutboxOpKind.update,
      entityId: 'req-1',
      payload: {'action': action},
      createdAt: DateTime.now(),
    );

void main() {
  late _MockRemote remote;
  late ContactsOutboxReplayHandler handler;

  setUp(() {
    remote = _MockRemote();
    handler = ContactsOutboxReplayHandler(remote: remote);
  });

  test('accept success → OutboxReplaySuccess', () async {
    when(() => remote.acceptContactRequest('req-1'))
        .thenAnswer((_) async => {'ok': true});
    final res = await handler.replay(_op('accept'));
    expect(res, isA<OutboxReplaySuccess>());
  });

  test('reject success → OutboxReplaySuccess', () async {
    when(() => remote.rejectContactRequest('req-1'))
        .thenAnswer((_) async {});
    final res = await handler.replay(_op('reject'));
    expect(res, isA<OutboxReplaySuccess>());
  });

  test('404 from accept → success (already settled)', () async {
    when(() => remote.acceptContactRequest('req-1'))
        .thenThrow(DioException(
          requestOptions: RequestOptions(path: '/x'),
          response: Response(requestOptions: RequestOptions(path: '/x'), statusCode: 404),
        ));
    final res = await handler.replay(_op('accept'));
    expect(res, isA<OutboxReplaySuccess>());
  });

  test('network error → retry', () async {
    when(() => remote.acceptContactRequest('req-1'))
        .thenThrow(Exception('network'));
    final res = await handler.replay(_op('accept'));
    expect(res, isA<OutboxReplayRetry>());
  });
}
```

### Step 2: Run — fail

```bash
flutter test test/features/contacts/data/services/contacts_outbox_replay_handler_test.dart
```

### Step 3: Implement

```dart
// lib/features/contacts/data/services/contacts_outbox_replay_handler.dart
import 'package:dio/dio.dart';
import '../../../../core/services/outbox_replay_handler.dart';
import '../../../../core/storage/outbox_op.dart';
import '../../../messenger/data/datasources/messenger_remote_datasource.dart';

class ContactsOutboxReplayHandler implements OutboxReplayHandler {
  final MessengerRemoteDataSource _remote;
  ContactsOutboxReplayHandler({required MessengerRemoteDataSource remote})
      : _remote = remote;

  @override
  String get feature => 'contacts';

  @override
  Future<OutboxReplayResult> replay(OutboxOp op) async {
    final action = (op.payload ?? const {})['action'] as String? ?? '';
    try {
      switch (action) {
        case 'accept':
          await _remote.acceptContactRequest(op.entityId);
          return OutboxReplayResult.success();
        case 'reject':
          await _remote.rejectContactRequest(op.entityId);
          return OutboxReplayResult.success();
        default:
          return OutboxReplayResult.dead(error: 'unknown contacts action: $action');
      }
    } on DioException catch (e) {
      final code = e.response?.statusCode ?? 0;
      // 404 (request already gone) or 409 (already not PENDING) are accepted —
      // local state is already at the target (or refresh will reconcile).
      if (code == 404 || code == 409) {
        return OutboxReplayResult.success();
      }
      if (code >= 400 && code < 500 && code != 408 && code != 429) {
        return OutboxReplayResult.dead(error: 'HTTP $code: ${e.message}');
      }
      return OutboxReplayResult.retry(error: 'HTTP $code: ${e.message}');
    } catch (e) {
      return OutboxReplayResult.retry(error: e.toString());
    }
  }
}
```

### Step 4: Run — 4/4 PASS

```bash
flutter test test/features/contacts/data/services/contacts_outbox_replay_handler_test.dart
```

### Step 5: Commit

```bash
git add lib/features/contacts/data/services/contacts_outbox_replay_handler.dart test/features/contacts/data/services/contacts_outbox_replay_handler_test.dart
git commit -m "$(cat <<'EOF'
feat(contacts): ContactsOutboxReplayHandler maps accept/reject to MessengerRemoteDataSource

404 / 409 treated as success (state already at target). Network errors retry.
Other 4xx → dead.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 6: Mobile — DI wiring

**Files:**
- Modify: `~/Downloads/taler_id_mobile/lib/core/di/service_locator.dart`

- [ ] **Step 1: Verify branch is `dev`**

```bash
git branch --show-current
```

If detached HEAD or other branch, `git checkout dev`.

- [ ] **Step 2: Add imports**

Add near the existing calendar imports:

```dart
import '../../features/contacts/data/datasources/contacts_local_datasource.dart';
import '../../features/contacts/data/repositories/contacts_repository_impl.dart';
import '../../features/contacts/data/services/contacts_outbox_replay_handler.dart';
import '../../features/contacts/domain/repositories/i_contacts_repository.dart';
```

- [ ] **Step 3: Open the Hive box**

Find the line `await Hive.openBox<String>(CalendarLocalDataSource.boxName);` and add IMMEDIATELY AFTER:

```dart
  await Hive.openBox<String>(ContactsLocalDataSource.boxName);
```

- [ ] **Step 4: Register the services**

Find the calendar feature block (search for `CalendarOutboxReplayHandler`). After it (before any handler.registerHandler boot code), add:

```dart
  // Contacts feature
  sl.registerLazySingleton<ContactsLocalDataSource>(() => ContactsLocalDataSource());
  sl.registerLazySingleton<IContactsRepository>(() => ContactsRepositoryImpl(
        local: sl<ContactsLocalDataSource>(),
        remote: sl<MessengerRemoteDataSource>(),
        outbox: sl<OutboxQueue>(),
      ));
  sl.registerLazySingleton<ContactsOutboxReplayHandler>(() => ContactsOutboxReplayHandler(
        remote: sl<MessengerRemoteDataSource>(),
      ));
```

(`MessengerRemoteDataSource` is already registered globally — no need for a guard.)

- [ ] **Step 5: Register handler with OutboxReplayService**

Find the line `sl<OutboxReplayService>().registerHandler(sl<CalendarOutboxReplayHandler>());`. Add IMMEDIATELY AFTER:

```dart
  sl<OutboxReplayService>().registerHandler(sl<ContactsOutboxReplayHandler>());
```

- [ ] **Step 6: Analyze**

```bash
flutter analyze lib/core/di/service_locator.dart
```

Expected: no errors.

- [ ] **Step 7: Commit**

```bash
git add lib/core/di/service_locator.dart
git commit -m "$(cat <<'EOF'
feat(di): wire contacts offline repository + outbox replay handler

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 7: Mobile — `contacts_screen.dart` refactor

**Files:**
- Modify: `~/Downloads/taler_id_mobile/lib/features/contacts/presentation/screens/contacts_screen.dart`

The existing file is 521 lines. Key touch points:
- Line 26: `final _items = <_ContactItem>[];` — replaced by stream-driven list.
- Lines 45-119: `_load()` method (three direct HTTP calls) — replaced by `_repo.refresh()`.
- Line 36, 131, 150, 168 (RefreshIndicator.onRefresh), 181, 252, 368, 434: `_load()` callsites — most stay (they trigger refresh).
- Lines 122-138: `_acceptRequest` — call `_repo.acceptContactRequest`.
- Lines 141-158: `_declineRequest` — call `_repo.rejectContactRequest` (note: backend endpoint is `/reject`; this fixes the pre-existing `/decline` typo).
- Lines 426-432 (approx): `_resendRequest` — call `_repo.sendContactRequest` directly + catch + snackbar.
- Lines 473-: `enum _ContactStatus`, `class _ContactItem` — replaced by `ContactStatus` enum + `ContactItemEntity` from domain.

### Steps

- [ ] **Step 1: Add imports**

At the top:

```dart
import 'dart:async';
import '../../domain/entities/contact_item_entity.dart';
import '../../domain/repositories/i_contacts_repository.dart';
```

Keep the existing `dio_client.dart` import for `_resendRequest` (which still goes through it — actually replace with `IContactsRepository.sendContactRequest`).

- [ ] **Step 2: Replace state fields**

Find `final _items = <_ContactItem>[];` (around line 26) and the loading flags. Replace with:

```dart
  final IContactsRepository _repo = sl<IContactsRepository>();
  StreamSubscription<List<ContactItemEntity>>? _itemsSub;
  List<ContactItemEntity> _items = [];
  bool _loading = true;
```

- [ ] **Step 3: Migrate initState**

Replace the body of `initState()` with:

```dart
    super.initState();
    _itemsSub = _repo.watchAll().listen((items) {
      if (mounted) {
        setState(() {
          _items = items;
          _loading = false;
        });
      }
    });
    _repo.refresh(); // fire-and-forget
```

- [ ] **Step 4: Add dispose**

```dart
  @override
  void dispose() {
    _itemsSub?.cancel();
    super.dispose();
  }
```

- [ ] **Step 5: Replace `_load()` body**

```dart
  Future<void> _load() async {
    await _repo.refresh();
  }
```

All existing callsites of `_load()` (the RefreshIndicator onRefresh, post-navigation callbacks, etc.) continue to work — they just trigger a fresh server fetch which feeds back into the stream.

- [ ] **Step 6: Replace `_acceptRequest`**

```dart
  Future<void> _acceptRequest(ContactItemEntity contact) async {
    if (contact.requestId == null) return;
    await _repo.acceptContactRequest(contact.requestId!, contact.userId);
    HapticFeedback.mediumImpact();
  }
```

(No `try/catch` — the optimistic update happens locally; the outbox handler reconciles when the network returns. If the server later 4xx-deads the op, that's surfaced via the dead-op log; UX impact is minor — the user simply sees the optimistic state remain on local until next refresh.)

- [ ] **Step 7: Replace `_declineRequest`**

```dart
  Future<void> _declineRequest(ContactItemEntity contact) async {
    if (contact.requestId == null) return;
    await _repo.rejectContactRequest(contact.requestId!, contact.userId);
    HapticFeedback.lightImpact();
  }
```

- [ ] **Step 8: Replace `_resendRequest`**

```dart
  Future<void> _resendRequest(ContactItemEntity contact) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      await _repo.sendContactRequest(contact.userId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.contactsResent), backgroundColor: AppColors.of(context).primary),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.errorWithMessage(e.toString())), backgroundColor: Colors.red),
        );
      }
    }
  }
```

- [ ] **Step 9: Delete the old `_ContactItem` class and `_ContactStatus` enum**

Around line 473-end. Replace usages in the existing file:
- `_ContactItem contact` → `ContactItemEntity contact`
- `_ContactStatus.incoming` → `ContactStatus.incoming`
- `_ContactStatus.accepted` → `ContactStatus.accepted`
- `_ContactStatus.pending` → `ContactStatus.pending`
- `contact.userId`, `contact.name`, `contact.username`, etc. — these field names are identical in `ContactItemEntity`, so most reads continue to work.

There is one subtle migration: the existing `_ContactItem` constructor used positional/named in a slightly different order — when the engineer migrates each `_ContactItem(...)` constructor call, ensure the new `ContactItemEntity(...)` uses named args correctly.

But — since `ContactsRepositoryImpl.refresh` builds entities itself, the screen no longer constructs items. The construction code in lines ~45-114 of the OLD `_load` is deleted entirely (it's replaced by `_repo.refresh()`).

- [ ] **Step 10: Add sync indicator on cards**

In the existing `_buildTile` (line ~272 area), find where the contact name is rendered. Add (near the title widget, in a Row if not already):

```dart
  Widget _syncDot(ContactItemEntity c) {
    if (!c.localPending) return const SizedBox.shrink();
    return const Padding(
      padding: EdgeInsets.only(left: 6),
      child: Icon(Icons.sync, size: 12, color: Colors.grey),
    );
  }
```

Include `_syncDot(contact)` next to the title text in the tile.

- [ ] **Step 11: Verify imports + analyze**

Remove any now-unused imports (e.g. `'../../../../core/api/dio_client.dart'` is no longer needed since `_resendRequest` uses the repo now).

```bash
flutter analyze lib/features/contacts/presentation/screens/contacts_screen.dart
```

Expected: no NEW errors. (Pre-existing project-wide warnings unrelated to this file are OK.)

- [ ] **Step 12: Run full test suite**

```bash
flutter test
```

Expected: existing tests still pass, no regressions.

- [ ] **Step 13: Commit**

```bash
git add lib/features/contacts/presentation/screens/contacts_screen.dart
git commit -m "$(cat <<'EOF'
refactor(contacts): route data through IContactsRepository + streams

Replaces three direct HTTP GETs with _repo.watchAll() + _repo.refresh().
Accept/reject go through optimistic local mutation + outbox; this also fixes
the latent /decline typo (server endpoint is /reject).
Send-request stays online-only via _repo.sendContactRequest with snackbar
on failure.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 8: Hardware smoke (user-driven)

On `emulator-5554` (already running):

- [ ] **Step 1: Build dev APK locally**

```bash
cd ~/Downloads/taler_id_mobile
flutter build apk --flavor dev --release -t lib/main_dev.dart --dart-define=FLAVOR=dev --dart-define=BASE_URL=https://staging.id.taler.tirol
```

- [ ] **Step 2: Install on emulator**

```bash
~/Library/Android/sdk/platform-tools/adb -s emulator-5554 uninstall tirol.taler.taler_id_mobile.dev
~/Library/Android/sdk/platform-tools/adb -s emulator-5554 install ~/Downloads/taler_id_mobile/build/app/outputs/flutter-apk/app-dev-release.apk
~/Library/Android/sdk/platform-tools/adb -s emulator-5554 shell pm grant tirol.taler.taler_id_mobile.dev android.permission.RECORD_AUDIO
~/Library/Android/sdk/platform-tools/adb -s emulator-5554 shell pm grant tirol.taler.taler_id_mobile.dev android.permission.POST_NOTIFICATIONS
~/Library/Android/sdk/platform-tools/adb -s emulator-5554 shell monkey -p tirol.taler.taler_id_mobile.dev -c android.intent.category.LAUNCHER 1
```

- [ ] **Step 3: Smoke scenarios** (driven manually on the emulator):

1. **Offline accept**: log in → contacts → enable airplane (`adb shell svc wifi disable; adb shell svc data disable`) → seed an incoming request via curl from another account beforehand. Tap accept → request moves to accepted with sync icon. Disable airplane (`adb shell svc wifi enable; adb shell svc data enable`) → sync icon disappears within 5s. Verify with curl that server status is ACCEPTED.
2. **Offline reject**: airplane on → tap reject on a pending request → it disappears from the list. Airplane off → server status is REJECTED.
3. **Send-request offline**: airplane on → tap resend on a pending sent request → snackbar "ошибка / Нужен интернет".

Document any failures in the spec file under "Smoke results" before merging.

---

## Task 9: Deploy mobile dev branch

- [ ] **Step 1: Push**

```bash
cd ~/Downloads/taler_id_mobile
git push origin dev
```

- [ ] **Step 2: Build dev APK on PROD server**

```bash
ssh dvolkov@138.124.61.221
cd ~/taler_id_mobile && git checkout dev && git pull origin dev
flutter build apk --flavor dev --release -t lib/main_dev.dart \
  --dart-define=FLAVOR=dev --dart-define=BASE_URL=https://staging.id.taler.tirol
sudo cp build/app/outputs/flutter-apk/app-dev-release.apk /var/www/downloads/taler-id-dev.apk
```

- [ ] **Step 3: Run all DEV integration tests** (regression — no API changes expected to break anything)

```bash
cd ~/Downloads/taler_id_tests
npm test && npm run test:sync && npm run test:notes:offline && npm run test:calendar:offline && npm run test:files && npm run test:channels && npm run test:billing
```

Expected: all green.

---

## Note on PROD deploy

Per the combined-release strategy (option B chosen by user): **do NOT deploy to PROD after this contacts plan completes.** Stage 2.4 (favorites) follows. The combined PROD release is gated on user approval after all four sub-projects are smoke-tested on DEV.

---

## Spec coverage check (self-review)

| Spec requirement | Implemented in task |
|---|---|
| Cache contacts + requests offline; render from local | Task 4 (`refresh`) + Task 7 (screen uses `watchAll`) |
| Accept incoming request offline → outbox | Task 4 (`acceptContactRequest`) + Task 5 (handler) |
| Reject incoming request offline → outbox | Task 4 (`rejectContactRequest`) + Task 5 (handler) |
| Send-request stays online-only with snackbar on failure | Task 7 step 8 |
| Reuse existing outbox infrastructure (no core changes) | Task 5 (new handler only) + Task 6 (DI register) |
| `payload.action = 'accept' \| 'reject'` mapping on `OutboxOpKind.update` | Task 4 + Task 5 |
| 404 / 409 from accept/reject → success | Task 5 (handler `replay`) |
| Squash: accept then reject → only reject op | Task 4 (`_squashAndEnqueue`) |
| Refresh preserves `localPending` | Task 4 (`_upsertPreservingPending`) |
| Sync dot indicator on items where `localPending` | Task 7 step 10 |
| Existing screen reorder (incoming → accepted → pending) preserved | Task 3 (`getAll` sort) |
| No backend / no API changes | (entire plan) |
| No new integration test | (none) |
| Hardware smoke (accept / reject / send-error) | Task 8 |
| DEV deploy + regression suite | Task 9 |
| PROD deploy deferred to combined release after Stage 2.4 | (note above) |
| **Out of scope:** block/unblock, contact alias, send-request offline, desktop port | n/a |

**Fix for pre-existing `/decline` → `/reject` typo:** Task 7 step 7 (routes through `MessengerRemoteDataSource.rejectContactRequest` which uses the correct `/reject` endpoint).

# Forwarding + Share-in + Favorites Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Активировать и довести до пользователя три уже частично построенные фичи: pinned "Избранное" (SAVED), приём внешних файлов через ShareIntent → ShareTargetScreen, единый recipient filter для forward + share-in (включая AI_ANALYST/AI_OUTBOUND/CHANNEL+роль/SAVED).

**Architecture:** Точечные мобильные изменения, переиспользование существующей инфраструктуры. SAVED виден через pinned tile в `conversations_screen`, открывает существующий `chat_room_screen`. Hive-favorites мигрируют one-shot в server SAVED. Backend = 0 изменений.

**Tech Stack:** Flutter + BLoC + GoRouter + GetIt + Hive + flutter_secure_storage + receive_sharing_intent.

**Spec:** `docs/superpowers/specs/2026-04-25-forwarding-share-favorites-design.md`

**Branch:** `dev` (мобилка `~/Downloads/taler_id_mobile`).

---

## Phase 1: Repository extension

### Task 1.1: Add `getOrCreateSavedConversation` to repository (TDD)

**Files:**
- Modify: `/Users/dmitry/Downloads/taler_id_mobile/lib/features/messenger/data/datasources/messenger_remote_datasource.dart`
- Modify: `/Users/dmitry/Downloads/taler_id_mobile/lib/features/messenger/domain/repositories/i_messenger_repository.dart`
- Modify: `/Users/dmitry/Downloads/taler_id_mobile/lib/features/messenger/data/repositories/messenger_repository_impl.dart`

- [ ] **Step 1: Inspect remote datasource HTTP client pattern**

Run:
```bash
grep -n "_dio\|http\|post\|@override Future" /Users/dmitry/Downloads/taler_id_mobile/lib/features/messenger/data/datasources/messenger_remote_datasource.dart | head -20
```
Look at one existing POST method (e.g. `getMessages` or any conversation-creation method) to learn how `_dio` is named/used.

- [ ] **Step 2: Add abstract method to interface**

Open `lib/features/messenger/domain/repositories/i_messenger_repository.dart`. Add at the end of the class (before closing `}`):

```dart
  /// Returns the per-user SAVED conversation id, creating it on the server if needed.
  Future<String> getOrCreateSavedConversation();
```

- [ ] **Step 3: Add datasource method**

Open `lib/features/messenger/data/datasources/messenger_remote_datasource.dart`. Find the section with REST methods (look for `Future<...> get/post`). Match the existing pattern. Add a method:

```dart
  Future<String> getOrCreateSavedConversation() async {
    final res = await _dio.post('/messenger/saved');
    final data = res.data as Map<String, dynamic>;
    final id = data['conversationId'];
    if (id is! String) {
      throw const FormatException('SAVED conversation: missing conversationId in response');
    }
    return id;
  }
```

If the field is not `_dio` (e.g. `_apiClient.dio` or `_dioClient`), adjust to match the existing call sites.

- [ ] **Step 4: Implement in repository**

Open `lib/features/messenger/data/repositories/messenger_repository_impl.dart`. Add:

```dart
  @override
  Future<String> getOrCreateSavedConversation() => _remote.getOrCreateSavedConversation();
```

- [ ] **Step 5: Verify compilation**

Run: `cd /Users/dmitry/Downloads/taler_id_mobile && flutter analyze lib/features/messenger/data/ lib/features/messenger/domain/repositories/i_messenger_repository.dart 2>&1 | tail -10`
Expected: no errors in changed files.

- [ ] **Step 6: Commit**

```bash
cd /Users/dmitry/Downloads/taler_id_mobile && git add lib/features/messenger/data/datasources/messenger_remote_datasource.dart lib/features/messenger/data/repositories/messenger_repository_impl.dart lib/features/messenger/domain/repositories/i_messenger_repository.dart && git commit -m "feat(messenger): add getOrCreateSavedConversation to repository"
```

---

## Phase 2: Recipient filter helper

### Task 2.1: Create `recipient_filters.dart` (TDD)

**Files:**
- Create: `/Users/dmitry/Downloads/taler_id_mobile/lib/features/messenger/utils/recipient_filters.dart`
- Create: `/Users/dmitry/Downloads/taler_id_mobile/test/features/messenger/utils/recipient_filters_test.dart`

- [ ] **Step 1: Write failing test**

Create `test/features/messenger/utils/recipient_filters_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:taler_id_mobile/features/messenger/domain/entities/conversation_entity.dart';
import 'package:taler_id_mobile/features/messenger/utils/recipient_filters.dart';

ConversationEntity _conv(String id, String type, {String? myRole}) =>
    ConversationEntity(id: id, type: type, myRole: myRole);

void main() {
  group('filterRecipients', () {
    test('includes DIRECT and GROUP', () {
      final result = filterRecipients([
        _conv('c1', 'DIRECT'),
        _conv('c2', 'GROUP'),
      ]);
      expect(result.map((c) => c.id), ['c1', 'c2']);
    });

    test('includes SAVED, AI_ANALYST, AI_OUTBOUND', () {
      final result = filterRecipients([
        _conv('s', 'SAVED'),
        _conv('a', 'AI_ANALYST'),
        _conv('o', 'AI_OUTBOUND'),
      ]);
      expect(result.map((c) => c.id), ['s', 'a', 'o']);
    });

    test('CHANNEL: includes OWNER and ADMIN, excludes SUBSCRIBER and null role', () {
      final result = filterRecipients([
        _conv('owner', 'CHANNEL', myRole: 'OWNER'),
        _conv('admin', 'CHANNEL', myRole: 'ADMIN'),
        _conv('sub',   'CHANNEL', myRole: 'SUBSCRIBER'),
        _conv('null',  'CHANNEL'),
      ]);
      expect(result.map((c) => c.id), ['owner', 'admin']);
    });

    test('excludes unknown types', () {
      final result = filterRecipients([
        _conv('x', 'SYSTEM'),
        _conv('y', 'WEIRD'),
      ]);
      expect(result, isEmpty);
    });

    test('preserves order of input', () {
      final result = filterRecipients([
        _conv('c1', 'DIRECT'),
        _conv('c2', 'AI_ANALYST'),
        _conv('c3', 'GROUP'),
      ]);
      expect(result.map((c) => c.id), ['c1', 'c2', 'c3']);
    });
  });
}
```

If `ConversationEntity` requires more required fields than `id`, `type`, `myRole`, adjust the helper `_conv()` to add the minimum required (check the entity at `lib/features/messenger/domain/entities/conversation_entity.dart`).

- [ ] **Step 2: Run — FAIL**

Run: `flutter test test/features/messenger/utils/recipient_filters_test.dart 2>&1 | tail -10`
Expected: FAIL — module not found.

- [ ] **Step 3: Create helper**

Create `lib/features/messenger/utils/recipient_filters.dart`:

```dart
import '../domain/entities/conversation_entity.dart';

/// Roles allowed to post in a CHANNEL (mirrors backend assertCanPostInChannel).
const _channelPostingRoles = {'OWNER', 'ADMIN'};

/// Returns conversations where the current user can SEND a message.
///
/// Inclusions:
///   - DIRECT, GROUP — always
///   - CHANNEL — only when user role is OWNER or ADMIN
///   - SAVED, AI_ANALYST, AI_OUTBOUND — always (single-participant or bot chats)
///
/// Exclusions:
///   - CHANNEL with SUBSCRIBER role (read-only for the user)
///   - Unknown ConvType (defensive)
List<ConversationEntity> filterRecipients(List<ConversationEntity> all) {
  return all.where(_canPost).toList(growable: false);
}

bool _canPost(ConversationEntity c) {
  switch (c.type) {
    case 'DIRECT':
    case 'GROUP':
    case 'SAVED':
    case 'AI_ANALYST':
    case 'AI_OUTBOUND':
      return true;
    case 'CHANNEL':
      return _channelPostingRoles.contains(c.myRole);
    default:
      return false;
  }
}
```

- [ ] **Step 4: Run — PASS**

Run: `flutter test test/features/messenger/utils/recipient_filters_test.dart 2>&1 | tail -5`
Expected: 5 tests pass.

- [ ] **Step 5: Commit**

```bash
git add lib/features/messenger/utils/recipient_filters.dart test/features/messenger/utils/recipient_filters_test.dart && git commit -m "feat(messenger): add recipient_filters helper for forward + share-in"
```

---

## Phase 3: SAVED pinned tile

### Task 3.1: Add localization keys

**Files:**
- Modify: `/Users/dmitry/Downloads/taler_id_mobile/lib/l10n/app_en.arb`
- Modify: `/Users/dmitry/Downloads/taler_id_mobile/lib/l10n/app_ru.arb`

- [ ] **Step 1: Add to `app_en.arb`** (insert before the closing `}`, with comma after the previous entry)

```json
  "savedTitle": "Saved Messages",
  "savedSubtitle": "Your private cloud",
  "savedOpenError": "Couldn't open Saved Messages"
```

- [ ] **Step 2: Add to `app_ru.arb`**

```json
  "savedTitle": "Избранное",
  "savedSubtitle": "Ваше личное облако",
  "savedOpenError": "Не удалось открыть Избранное"
```

- [ ] **Step 3: Regenerate**

Run: `cd /Users/dmitry/Downloads/taler_id_mobile && flutter gen-l10n 2>&1 | tail -3`
Expected: success.

- [ ] **Step 4: Commit**

```bash
git add lib/l10n/app_en.arb lib/l10n/app_ru.arb lib/l10n/app_localizations*.dart && git commit -m "i18n: add saved messages strings (ru/en)"
```

### Task 3.2: Create `SavedPinnedTile` widget (TDD)

**Files:**
- Create: `/Users/dmitry/Downloads/taler_id_mobile/lib/features/messenger/presentation/widgets/saved_pinned_tile.dart`
- Create: `/Users/dmitry/Downloads/taler_id_mobile/test/features/messenger/presentation/widgets/saved_pinned_tile_test.dart`

- [ ] **Step 1: Write failing test**

Create the test file:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:taler_id_mobile/l10n/app_localizations.dart';
import 'package:taler_id_mobile/features/messenger/domain/repositories/i_messenger_repository.dart';
import 'package:taler_id_mobile/features/messenger/presentation/widgets/saved_pinned_tile.dart';

class _MockRepo extends Mock implements IMessengerRepository {}

Widget _wrap(Widget child) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: Scaffold(body: child),
    );

void main() {
  setUp(() {
    if (GetIt.instance.isRegistered<IMessengerRepository>()) {
      GetIt.instance.unregister<IMessengerRepository>();
    }
    GetIt.instance.registerLazySingleton<IMessengerRepository>(() => _MockRepo());
  });

  tearDown(() => GetIt.instance.reset());

  testWidgets('renders title and subtitle', (tester) async {
    await tester.pumpWidget(_wrap(const SavedPinnedTile()));
    expect(find.text('Saved Messages'), findsOneWidget);
    expect(find.text('Your private cloud'), findsOneWidget);
    expect(find.byIcon(Icons.bookmark_rounded), findsOneWidget);
  });

  testWidgets('tap calls repo.getOrCreateSavedConversation', (tester) async {
    final repo = GetIt.instance<IMessengerRepository>() as _MockRepo;
    when(() => repo.getOrCreateSavedConversation()).thenAnswer((_) async => 'saved-conv-id');

    await tester.pumpWidget(_wrap(const SavedPinnedTile()));
    await tester.tap(find.byType(SavedPinnedTile));
    await tester.pump(); // begin tap animation
    await tester.pump(const Duration(seconds: 1)); // settle async

    verify(() => repo.getOrCreateSavedConversation()).called(1);
  });
}
```

- [ ] **Step 2: Run — FAIL**

Run: `flutter test test/features/messenger/presentation/widgets/saved_pinned_tile_test.dart 2>&1 | tail -10`
Expected: FAIL — widget not found.

- [ ] **Step 3: Inspect AppColorsExtension fields**

Run: `grep -n "class AppColorsExtension\|final Color" /Users/dmitry/Downloads/taler_id_mobile/lib/core/theme/app_theme.dart | head -20`
Note the available color names (`primary`, `card`, `textPrimary`, `textSecondary` should exist; `primaryDark` may or may not).

- [ ] **Step 4: Create widget**

Create `lib/features/messenger/presentation/widgets/saved_pinned_tile.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/repositories/i_messenger_repository.dart';

class SavedPinnedTile extends StatelessWidget {
  const SavedPinnedTile({super.key});

  Future<void> _open(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final repo = GetIt.instance<IMessengerRepository>();
      final convId = await repo.getOrCreateSavedConversation();
      if (!context.mounted) return;
      context.go('/dashboard/messenger/$convId');
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.savedOpenError)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final ext = Theme.of(context).extension<AppColorsExtension>();
    final primary = ext?.primary ?? cs.primary;
    final textPrimary = ext?.textPrimary ?? cs.onSurface;
    final textSecondary = ext?.textSecondary ?? cs.onSurfaceVariant;

    return InkWell(
      onTap: () => _open(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [primary, primary.withValues(alpha: 0.7)],
                ),
              ),
              child: const Icon(Icons.bookmark_rounded, color: Colors.white, size: 26),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.savedTitle,
                      style: TextStyle(color: textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(l10n.savedSubtitle,
                      style: TextStyle(color: textSecondary, fontSize: 13)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: textSecondary),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 5: Run — PASS**

Run: `flutter test test/features/messenger/presentation/widgets/saved_pinned_tile_test.dart 2>&1 | tail -10`
Expected: 2 tests pass.

- [ ] **Step 6: Commit**

```bash
git add lib/features/messenger/presentation/widgets/saved_pinned_tile.dart test/features/messenger/presentation/widgets/saved_pinned_tile_test.dart && git commit -m "feat(messenger): SavedPinnedTile widget for SAVED chat entry point"
```

### Task 3.3: Wire `SavedPinnedTile` into conversations_screen

**Files:**
- Modify: `/Users/dmitry/Downloads/taler_id_mobile/lib/features/messenger/presentation/screens/conversations_screen.dart`

- [ ] **Step 1: Inspect current ListView header**

Run: `sed -n "565,585p" /Users/dmitry/Downloads/taler_id_mobile/lib/features/messenger/presentation/screens/conversations_screen.dart`
Look at the structure around line 577 (`ListView.builder`).

- [ ] **Step 2: Add import**

At the top of `conversations_screen.dart`, add:

```dart
import '../widgets/saved_pinned_tile.dart';
```

- [ ] **Step 3: Insert pinned tile**

Replace `ListView.builder` with `ListView` that has the pinned tile + an inner `ListView.builder`-like structure. Easiest approach: switch to `ListView.builder` with `itemCount = contacts.length + 1` and check `index == 0` for the pinned tile.

Find the line `child: ListView.builder(` (≈line 577) and replace its body with:

```dart
child: ListView.builder(
  controller: scrollCtrl,
  itemCount: contacts.length + 1,
  itemBuilder: (context, index) {
    if (index == 0) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: const [
          SavedPinnedTile(),
          Divider(height: 1, thickness: 0.5),
        ],
      );
    }
    final i = index - 1;
    // ...existing item rendering using `i` instead of `index`...
  },
),
```

Inside the existing `itemBuilder` body that comes after, every reference to `index` that maps to `contacts[index]` needs to be `contacts[i]`. Read the current builder closure (lines 578-635 approximately) and adjust accordingly.

- [ ] **Step 4: Verify**

Run: `flutter analyze lib/features/messenger/presentation/screens/conversations_screen.dart 2>&1 | tail -10`
Expected: no NEW errors. Pre-existing warnings OK.

- [ ] **Step 5: Commit**

```bash
git add lib/features/messenger/presentation/screens/conversations_screen.dart && git commit -m "feat(messenger): pin SavedPinnedTile at top of conversations list"
```

---

## Phase 4: Hive favorites migration

### Task 4.1: `HiveFavoritesMigrationService` (TDD)

**Files:**
- Create: `/Users/dmitry/Downloads/taler_id_mobile/lib/features/messenger/services/hive_favorites_migration_service.dart`
- Create: `/Users/dmitry/Downloads/taler_id_mobile/test/features/messenger/services/hive_favorites_migration_service_test.dart`

- [ ] **Step 1: Inspect existing Hive favorites format**

Run: `sed -n "3290,3330p" /Users/dmitry/Downloads/taler_id_mobile/lib/features/messenger/presentation/screens/chat_room_screen.dart`
Note exactly which fields are saved into the Hive box (`'saved_messages'`): likely `content`, `fileUrl`, `fileName`, `fileType`, `fileSize`, `savedAt`. We need to preserve the same shape during migration.

- [ ] **Step 2: Inspect SecureStorageService.read/write API**

Run: `grep -n "Future<String?> read\|Future<void> write\|class SecureStorageService" /Users/dmitry/Downloads/taler_id_mobile/lib/core/storage/secure_storage_service.dart | head -10`
Confirm the method signatures (probably `Future<void> write(String key, String value)` and `Future<String?> read(String key)`).

- [ ] **Step 3: Write failing test**

Create `test/features/messenger/services/hive_favorites_migration_service_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:taler_id_mobile/core/storage/secure_storage_service.dart';
import 'package:taler_id_mobile/features/messenger/domain/repositories/i_messenger_repository.dart';
import 'package:taler_id_mobile/features/messenger/services/hive_favorites_migration_service.dart';

class _FakeStorage implements SecureStorageService {
  final Map<String, String> _kv = {};
  @override
  Future<String?> read(String key) async => _kv[key];
  @override
  Future<void> write(String key, String value) async {
    _kv[key] = value;
  }
  @override
  Future<void> delete(String key) async {
    _kv.remove(key);
  }
  @override
  Future<void> deleteAll() async => _kv.clear();
}

class _MockRepo extends Mock implements IMessengerRepository {}

class _FakePathProvider extends PathProviderPlatform with MockPlatformInterfaceMixin {
  String dir;
  _FakePathProvider(this.dir);
  @override
  Future<String?> getApplicationDocumentsPath() async => dir;
  @override
  Future<String?> getApplicationSupportPath() async => dir;
  @override
  Future<String?> getTemporaryPath() async => dir;
}

void main() {
  late _FakeStorage storage;
  late _MockRepo repo;
  late Directory tempDir;

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_test_');
    PathProviderPlatform.instance = _FakePathProvider(tempDir.path);
    Hive.init(tempDir.path);
    storage = _FakeStorage();
    repo = _MockRepo();
  });

  tearDown(() async {
    await Hive.close();
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  test('skips if flag already set', () async {
    await storage.write('saved_migrated_v1', 'true');
    final svc = HiveFavoritesMigrationService(repo: repo, storage: storage);
    await svc.runOnce();
    verifyNever(() => repo.getOrCreateSavedConversation());
  });

  test('no Hive box → marks flag and exits', () async {
    final svc = HiveFavoritesMigrationService(repo: repo, storage: storage);
    await svc.runOnce();
    expect(await storage.read('saved_migrated_v1'), 'true');
    verifyNever(() => repo.getOrCreateSavedConversation());
  });

  test('empty Hive box → deletes box, marks flag, no sends', () async {
    await Hive.openBox<Map>('saved_messages');
    await Hive.close();
    final svc = HiveFavoritesMigrationService(repo: repo, storage: storage);
    await svc.runOnce();
    expect(await storage.read('saved_migrated_v1'), 'true');
    verifyNever(() => repo.getOrCreateSavedConversation());
    expect(await Hive.boxExists('saved_messages'), false);
  });

  test('non-empty Hive box → migrates entries in chronological order, deletes box, sets flag', () async {
    final box = await Hive.openBox<Map>('saved_messages');
    await box.add({'content': 'B', 'savedAt': '2025-01-02T00:00:00Z'});
    await box.add({'content': 'A', 'savedAt': '2025-01-01T00:00:00Z'});
    await box.add({'content': 'C', 'savedAt': '2025-01-03T00:00:00Z', 'fileUrl': 'http://x', 'fileName': 'f.png', 'fileType': 'image', 'fileSize': 100});
    await Hive.close();

    when(() => repo.getOrCreateSavedConversation()).thenAnswer((_) async => 'saved-id');
    when(() => repo.sendMessage(
      conversationId: any(named: 'conversationId'),
      content: any(named: 'content'),
      fileUrl: any(named: 'fileUrl'),
      fileName: any(named: 'fileName'),
      fileType: any(named: 'fileType'),
      fileSize: any(named: 'fileSize'),
    )).thenAnswer((_) async {});

    final svc = HiveFavoritesMigrationService(repo: repo, storage: storage);
    await svc.runOnce();

    expect(await storage.read('saved_migrated_v1'), 'true');
    expect(await Hive.boxExists('saved_messages'), false);

    final calls = verify(() => repo.sendMessage(
      conversationId: 'saved-id',
      content: captureAny(named: 'content'),
      fileUrl: any(named: 'fileUrl'),
      fileName: any(named: 'fileName'),
      fileType: any(named: 'fileType'),
      fileSize: any(named: 'fileSize'),
    )).captured;
    expect(calls, ['A', 'B', 'C']);
  });

  test('sendMessage throws → flag NOT set, box NOT deleted', () async {
    final box = await Hive.openBox<Map>('saved_messages');
    await box.add({'content': 'test', 'savedAt': '2025-01-01T00:00:00Z'});
    await Hive.close();

    when(() => repo.getOrCreateSavedConversation()).thenAnswer((_) async => 'saved-id');
    when(() => repo.sendMessage(
      conversationId: any(named: 'conversationId'),
      content: any(named: 'content'),
      fileUrl: any(named: 'fileUrl'),
      fileName: any(named: 'fileName'),
      fileType: any(named: 'fileType'),
      fileSize: any(named: 'fileSize'),
    )).thenThrow(Exception('network'));

    final svc = HiveFavoritesMigrationService(repo: repo, storage: storage);
    await svc.runOnce();   // must not throw

    expect(await storage.read('saved_migrated_v1'), isNull);
    expect(await Hive.boxExists('saved_messages'), true);
  });
}
```

If the `IMessengerRepository.sendMessage` signature differs (the named-parameter list above is a guess), inspect and adjust:
```bash
grep -n "Future.*sendMessage" /Users/dmitry/Downloads/taler_id_mobile/lib/features/messenger/domain/repositories/i_messenger_repository.dart
```

If `sendMessage` takes positional args or differently-named ones, adjust the mock setup AND the migration service's `sendMessage` call to match.

- [ ] **Step 4: Run — FAIL**

Run: `flutter test test/features/messenger/services/hive_favorites_migration_service_test.dart 2>&1 | tail -10`
Expected: FAIL — module not found.

- [ ] **Step 5: Create the service**

Create `lib/features/messenger/services/hive_favorites_migration_service.dart`:

```dart
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../domain/repositories/i_messenger_repository.dart';

class HiveFavoritesMigrationService {
  static const _flagKey = 'saved_migrated_v1';
  static const _boxName = 'saved_messages';

  final IMessengerRepository _repo;
  final SecureStorageService _storage;

  HiveFavoritesMigrationService({
    required IMessengerRepository repo,
    required SecureStorageService storage,
  })  : _repo = repo,
        _storage = storage;

  /// Idempotent. Best-effort: never throws. Sets flag only on full success.
  Future<void> runOnce() async {
    try {
      final done = await _storage.read(_flagKey);
      if (done == 'true') return;

      if (!await Hive.boxExists(_boxName)) {
        await _storage.write(_flagKey, 'true');
        return;
      }

      final box = await Hive.openBox<Map>(_boxName);
      try {
        if (box.isEmpty) {
          await box.deleteFromDisk();
          await _storage.write(_flagKey, 'true');
          return;
        }

        final entries = box.values
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
        // Sort by savedAt ASC (chronological). Empty/missing -> sorts first.
        entries.sort((a, b) {
          final av = (a['savedAt'] ?? '').toString();
          final bv = (b['savedAt'] ?? '').toString();
          return av.compareTo(bv);
        });

        final convId = await _repo.getOrCreateSavedConversation();
        for (final e in entries) {
          await _repo.sendMessage(
            conversationId: convId,
            content: (e['content'] ?? '') as String,
            fileUrl: e['fileUrl'] as String?,
            fileName: e['fileName'] as String?,
            fileType: e['fileType'] as String?,
            fileSize: (e['fileSize'] as num?)?.toInt(),
          );
        }

        await box.deleteFromDisk();
        await _storage.write(_flagKey, 'true');
      } finally {
        if (box.isOpen) await box.close();
      }
    } catch (e, st) {
      debugPrint('[HiveFavoritesMigration] failed: $e\n$st');
      // Intentionally do NOT rethrow and do NOT set flag — retry next launch.
    }
  }
}
```

If `sendMessage` signature in `IMessengerRepository` has different parameter names (positional, or `text:` instead of `content:`, etc.), adjust the call to match.

- [ ] **Step 6: Run — PASS**

Run: `flutter test test/features/messenger/services/hive_favorites_migration_service_test.dart 2>&1 | tail -10`
Expected: 5 tests pass.

If any test fails because the assumption about `sendMessage` parameters was wrong, fix the production code to match the actual signature, and adjust the test mocks similarly. Do NOT just relax assertions.

- [ ] **Step 7: Commit**

```bash
git add lib/features/messenger/services/hive_favorites_migration_service.dart test/features/messenger/services/hive_favorites_migration_service_test.dart && git commit -m "feat(messenger): HiveFavoritesMigrationService for legacy local→server SAVED migration"
```

### Task 4.2: Wire migration into app startup

**Files:**
- Modify: `/Users/dmitry/Downloads/taler_id_mobile/lib/core/di/service_locator.dart`
- Modify: `/Users/dmitry/Downloads/taler_id_mobile/lib/main.dart`
- Modify: `/Users/dmitry/Downloads/taler_id_mobile/lib/main_dev.dart`

- [ ] **Step 1: Inspect service_locator structure**

Run: `grep -n "registerLazySingleton\|registerSingleton" /Users/dmitry/Downloads/taler_id_mobile/lib/core/di/service_locator.dart | head -15`
Locate where messenger-related services are registered. We'll add ours near them.

- [ ] **Step 2: Register in service_locator**

In `lib/core/di/service_locator.dart`, near the messenger registrations, add:

```dart
import '../../features/messenger/services/hive_favorites_migration_service.dart';
// ...
sl.registerLazySingleton<HiveFavoritesMigrationService>(
  () => HiveFavoritesMigrationService(
    repo: sl<IMessengerRepository>(),
    storage: sl<SecureStorageService>(),
  ),
);
```

(Imports for `IMessengerRepository` and `SecureStorageService` should already exist in this file.)

- [ ] **Step 3: Invoke from main.dart and main_dev.dart**

Open `lib/main.dart`. Find where `setupDependencies()` (or similar) is called. AFTER that call but BEFORE `runApp(...)`, add:

```dart
// Migrate legacy local Hive favorites to the server SAVED chat (one-shot).
unawaited(sl<HiveFavoritesMigrationService>().runOnce());
```

If `unawaited` is not imported, add `import 'dart:async';` at the top.

Repeat the same edit in `lib/main_dev.dart`.

- [ ] **Step 4: Verify**

Run: `flutter analyze lib/main.dart lib/main_dev.dart lib/core/di/service_locator.dart 2>&1 | tail -10`
Expected: no errors.

Run unit tests to make sure nothing broke:
```bash
flutter test test/features/messenger/services/ 2>&1 | tail -5
```

- [ ] **Step 5: Commit**

```bash
git add lib/core/di/service_locator.dart lib/main.dart lib/main_dev.dart && git commit -m "feat(messenger): run HiveFavoritesMigrationService at app startup"
```

### Task 4.3: Remove legacy `_saveToFavorites` from chat_room_screen

**Files:**
- Modify: `/Users/dmitry/Downloads/taler_id_mobile/lib/features/messenger/presentation/screens/chat_room_screen.dart`

- [ ] **Step 1: Find all references**

Run:
```bash
grep -n "_saveToFavorites\|saved_messages\|Hive\\..*box" /Users/dmitry/Downloads/taler_id_mobile/lib/features/messenger/presentation/screens/chat_room_screen.dart | head -20
```
Note all callers and the method definition.

- [ ] **Step 2: Inspect call sites**

Read 5 lines around each match to know the context. The method is at line ~3291. There may be 1-3 call sites (e.g. from a long-press menu).

- [ ] **Step 3: Remove call sites**

For each `_saveToFavorites(context)` invocation, decide:
- If it's a menu item alongside "Forward" — DELETE the menu item entirely (the SAVED option is now reachable via Forward → "Save to Favorites" shortcut and via the pinned tile)
- If it's wired differently — note in commit message

- [ ] **Step 4: Remove the method body**

Delete `_saveToFavorites` method (lines around 3291–3319). Also remove any local imports/helpers used only by it (e.g. `import 'package:hive/...'` if unused elsewhere in the file).

- [ ] **Step 5: Verify**

Run: `flutter analyze lib/features/messenger/presentation/screens/chat_room_screen.dart 2>&1 | grep -i "error" | head -10`
Expected: no errors. If you removed an import that's still used somewhere else in the file, restore it.

Run: `grep -n "_saveToFavorites\|saved_messages" /Users/dmitry/Downloads/taler_id_mobile/lib/features/messenger/presentation/screens/chat_room_screen.dart`
Expected: no matches.

Run: `flutter test 2>&1 | tail -5`
Expected: all green.

- [ ] **Step 6: Commit**

```bash
git add lib/features/messenger/presentation/screens/chat_room_screen.dart && git commit -m "refactor(messenger): remove legacy local Hive _saveToFavorites (server SAVED replaces it)"
```

---

## Phase 5: Recipient picker integration

### Task 5.1: Use `filterRecipients` in `_ForwardPickerSheet`

**Files:**
- Modify: `/Users/dmitry/Downloads/taler_id_mobile/lib/features/messenger/presentation/screens/chat_room_screen.dart`

- [ ] **Step 1: Inspect current filter**

Run: `sed -n "3795,3815p" /Users/dmitry/Downloads/taler_id_mobile/lib/features/messenger/presentation/screens/chat_room_screen.dart`
Note that line ~3802 currently filters only by `_query` (search text). The CALLER (`_showForwardPicker`) passes `widget.conversations` — find that caller and check if it pre-filters.

Run: `grep -n "_showForwardPicker\|_ForwardPickerSheet(" /Users/dmitry/Downloads/taler_id_mobile/lib/features/messenger/presentation/screens/chat_room_screen.dart | head -5`

- [ ] **Step 2: Apply filter at the caller**

The picker accepts a `List<ConversationEntity> conversations` arg. Apply `filterRecipients` at the call site (preferred — keeps the picker dumb).

Add at the top of the file:
```dart
import '../utils/recipient_filters.dart';
```

In the caller (probably `_showForwardPicker(...)`), wrap the conversations list:

```dart
// Before:
//   conversations: state.conversations,
// After:
   conversations: filterRecipients(state.conversations),
```

- [ ] **Step 3: Verify**

Run: `flutter analyze lib/features/messenger/presentation/screens/chat_room_screen.dart 2>&1 | tail -5`
Expected: no NEW errors.

Run: `flutter test 2>&1 | tail -5`
Expected: all green.

- [ ] **Step 4: Commit**

```bash
git add lib/features/messenger/presentation/screens/chat_room_screen.dart && git commit -m "feat(messenger): apply recipient_filters to forward picker"
```

### Task 5.2: Use `filterRecipients` in `ShareTargetScreen`

**Files:**
- Modify: `/Users/dmitry/Downloads/taler_id_mobile/lib/features/messenger/presentation/screens/share_target_screen.dart`

- [ ] **Step 1: Inspect current filter**

Run: `sed -n "85,100p" /Users/dmitry/Downloads/taler_id_mobile/lib/features/messenger/presentation/screens/share_target_screen.dart`
Confirm line ~92 is `state.conversations.where((c) => c.type != 'SYSTEM').toList()`.

- [ ] **Step 2: Replace filter**

Add import at the top:
```dart
import '../utils/recipient_filters.dart';
```

Replace the filter line:

```dart
// Before:
final conversations = state.conversations
    .where((c) => c.type != 'SYSTEM')
    .toList();
// After:
final conversations = filterRecipients(state.conversations);
```

- [ ] **Step 3: Verify**

Run: `flutter analyze lib/features/messenger/presentation/screens/share_target_screen.dart 2>&1 | tail -5`
Expected: no errors.

- [ ] **Step 4: Commit**

```bash
git add lib/features/messenger/presentation/screens/share_target_screen.dart && git commit -m "feat(messenger): apply recipient_filters to share-target screen"
```

---

## Phase 6: Share-in routing activation

### Task 6.1: Add `/share-target` GoRoute

**Files:**
- Modify: `/Users/dmitry/Downloads/taler_id_mobile/lib/core/router/app_router.dart`

- [ ] **Step 1: Inspect router structure**

Run: `sed -n "1,30p" /Users/dmitry/Downloads/taler_id_mobile/lib/core/router/app_router.dart`
Look at imports and how existing GoRoutes are defined.

Run: `grep -n "GoRoute\|path: '/" /Users/dmitry/Downloads/taler_id_mobile/lib/core/router/app_router.dart | head -20`

- [ ] **Step 2: Add import + route**

At top imports:
```dart
import '../../features/messenger/presentation/screens/share_target_screen.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
```

In the routes list (top-level, NOT inside ShellRoute — share-target is a full-screen modal), add:

```dart
GoRoute(
  path: '/share-target',
  builder: (context, state) {
    final files = (state.extra as List?)?.cast<SharedMediaFile>() ?? const <SharedMediaFile>[];
    return ShareTargetScreen(sharedFiles: files);
  },
),
```

If `app_router.dart` defines routes via a different mechanism (e.g. inside a `GoRouter` constructor's `routes:` list), insert there at top level.

- [ ] **Step 3: Verify**

Run: `flutter analyze lib/core/router/app_router.dart 2>&1 | tail -5`
Expected: no errors.

- [ ] **Step 4: Commit**

```bash
git add lib/core/router/app_router.dart && git commit -m "feat(router): add /share-target route for ShareTargetScreen"
```

### Task 6.2: Hook `ShareIntentService.pendingFilesStream` in DashboardScreen

**Files:**
- Modify: `/Users/dmitry/Downloads/taler_id_mobile/lib/features/dashboard/presentation/dashboard_screen.dart`

- [ ] **Step 1: Inspect dashboard initState**

Run: `sed -n "60,90p" /Users/dmitry/Downloads/taler_id_mobile/lib/features/dashboard/presentation/dashboard_screen.dart`
Confirm `initState` at line ~70.

- [ ] **Step 2: Add imports**

At the top of the file:
```dart
import 'dart:async';
import 'package:go_router/go_router.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import '../../../core/services/share_intent_service.dart';
```

- [ ] **Step 3: Add stream subscription field**

Inside the `_DashboardScreenState` class (or whatever the state class is named), add a private field:

```dart
StreamSubscription<List<SharedMediaFile>>? _shareSub;
```

- [ ] **Step 4: Subscribe in initState**

After existing `super.initState()` and any current logic, add:

```dart
_shareSub = ShareIntentService.instance.pendingFilesStream.listen(_onSharedFiles);
WidgetsBinding.instance.addPostFrameCallback((_) async {
  // Cold-start case: app launched via share. Buffered files are returned by ShareIntentService.
  // The service's getInitialMedia() resolves once on first call; subsequent calls return [].
  final initial = await ShareIntentService.instance.getInitialMedia();
  if (initial.isNotEmpty && mounted) _onSharedFiles(initial);
});
```

If `ShareIntentService` does not have `getInitialMedia()` (it might only expose the stream), check the file:
```bash
grep -n "Future.*getInitial\|getInitial" /Users/dmitry/Downloads/taler_id_mobile/lib/core/services/share_intent_service.dart
```
If no public `getInitialMedia` exists, drain via the stream's first event (which the service should emit synchronously after `_init()`). In that case skip the cold-start block — the live stream will deliver.

- [ ] **Step 5: Cancel in dispose**

Inside the existing `dispose()` (or add one if absent), add:

```dart
@override
void dispose() {
  _shareSub?.cancel();
  super.dispose();
}
```

- [ ] **Step 6: Add handler method**

Inside `_DashboardScreenState`, add:

```dart
void _onSharedFiles(List<SharedMediaFile> files) {
  if (files.isEmpty || !mounted) return;
  context.go('/share-target', extra: files);
}
```

- [ ] **Step 7: Verify**

Run: `flutter analyze lib/features/dashboard/ 2>&1 | tail -10`
Expected: no errors.

Run: `flutter test 2>&1 | tail -5`
Expected: all green.

- [ ] **Step 8: Commit**

```bash
git add lib/features/dashboard/presentation/dashboard_screen.dart && git commit -m "feat(share-in): route external shares to ShareTargetScreen via DashboardScreen"
```

---

## Phase 7: Polish + deploy

### Task 7.1: Push branch + run regression

**Files:** N/A — verification only.

- [ ] **Step 1: Push to origin**

```bash
cd /Users/dmitry/Downloads/taler_id_mobile && git push origin dev 2>&1 | tail -3
```

- [ ] **Step 2: Run full Flutter test suite**

```bash
flutter test 2>&1 | tail -5
```
Expected: all green. If a pre-existing test is now broken because of imports/structure changes, fix it.

- [ ] **Step 3: Run backend regression (DEV)**

Per CLAUDE.md §🧪 — backend tests don't depend on mobile changes, but smoke them to confirm nothing tangentially breaks:
```bash
cd /Users/dmitry/Downloads/taler_id_tests && npm test && npm run test:files && npm run test:channels && npm run test:billing
```
Expected: all green.

### Task 7.2: Build dev APK + manual smoke

**Files:** N/A — deployment only.

- [ ] **Step 1: Build dev APK on remote build server**

```bash
ssh dvolkov@138.124.61.221 'cd ~/taler_id_mobile && git fetch && git checkout dev && git pull && flutter pub get && flutter build apk --flavor dev --release -t lib/main_dev.dart --dart-define=FLAVOR=dev --dart-define=BASE_URL=https://staging.id.taler.tirol'
```
Expected: APK built at `~/taler_id_mobile/build/app/outputs/flutter-apk/app-dev-release.apk`.

- [ ] **Step 2: Publish APK**

```bash
ssh dvolkov@138.124.61.221 'sudo cp ~/taler_id_mobile/build/app/outputs/flutter-apk/app-dev-release.apk /var/www/downloads/taler-id-dev.apk && sudo chmod 644 /var/www/downloads/taler-id-dev.apk && ls -la /var/www/downloads/taler-id-dev.apk'
```
Expected: APK in place at https://id.taler.tirol/download/taler-id-dev.apk.

- [ ] **Step 3: Manual smoke test (Android emulator or real device)**

Install the new dev APK on a fresh-cleared device or emulator. Log in as `integration_test@taler-test.com`. Verify:

1. **SAVED tile** — at top of conversations list, "Saved Messages" / "Избранное". Tap → opens chat_room with title "Избранное".
2. **Forward** — long-press a message in any chat → Forward → picker shows DIRECT / GROUP / CHANNEL (only those user can post in) / SAVED / AI_ANALYST / AI_OUTBOUND. Tap "Save to Favorites" (top of picker) → message appears in SAVED.
3. **Forward to AI Analyst** — pick AI_ANALYST → forwarded text appears in AI Analyst chat. Verify live-status events from Feature 1 still fire.
4. **Share-in (Android)** — go to Files / Gallery → share an image → Taler ID Dev → ShareTargetScreen opens with image preview → pick "Saved" → image appears in SAVED chat.
5. **Hive migration** — if upgrading from a build that has local Hive favorites, those items appear in SAVED chat after first launch.

If any step fails, stop and debug before deploying further.

### Task 7.3: PROD deploy — gated

**Do not run automatically. Wait for explicit user approval.**

Per CLAUDE.md procedure:
- [ ] Merge `dev` → `main` on mobile repo
- [ ] Build prod APK on PROD server, publish to `taler-id.apk`
- [ ] iOS TestFlight build (optional, if PROD deploy approved)
- [ ] Run PROD regression: `npm run test:prod && npm run test:files:prod && npm run test:channels:prod && npm run test:billing:prod`

---

## Appendix — Files summary

### Created
- `lib/features/messenger/utils/recipient_filters.dart`
- `lib/features/messenger/services/hive_favorites_migration_service.dart`
- `lib/features/messenger/presentation/widgets/saved_pinned_tile.dart`
- `test/features/messenger/utils/recipient_filters_test.dart`
- `test/features/messenger/services/hive_favorites_migration_service_test.dart`
- `test/features/messenger/presentation/widgets/saved_pinned_tile_test.dart`

### Modified
- `lib/features/messenger/data/datasources/messenger_remote_datasource.dart`
- `lib/features/messenger/domain/repositories/i_messenger_repository.dart`
- `lib/features/messenger/data/repositories/messenger_repository_impl.dart`
- `lib/features/messenger/presentation/screens/conversations_screen.dart`
- `lib/features/messenger/presentation/screens/chat_room_screen.dart` (remove `_saveToFavorites`, apply `filterRecipients` to forward picker)
- `lib/features/messenger/presentation/screens/share_target_screen.dart`
- `lib/features/dashboard/presentation/dashboard_screen.dart`
- `lib/core/router/app_router.dart`
- `lib/core/di/service_locator.dart`
- `lib/main.dart`
- `lib/main_dev.dart`
- `lib/l10n/app_en.arb`
- `lib/l10n/app_ru.arb`
- (regenerated) `lib/l10n/app_localizations*.dart`

### Backend
**No changes.** All required endpoints already exist (`/messenger/saved`, socket `'message'`, `assertCanPostInChannel`).

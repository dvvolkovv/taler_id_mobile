# Favorites Offline Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Cache the user's SAVED-conversation id locally so the pinned "Saved Messages" tile opens offline once it has been opened online at least once.

**Architecture:** New tiny Hive-backed helper `SavedConversationIdCache` (mirrors `SyncCursorStorage` pattern from Stage 1). `SavedPinnedTile.onTap` reads cache first: if hit, navigate instantly and refresh from server in the background; if miss, fall back to the existing online-only path. No backend changes.

**Tech Stack:** Flutter, Hive (`hive_flutter`), GetIt DI, go_router, flutter_test.

**Spec reference:** `docs/superpowers/specs/2026-05-14-favorites-offline-design.md`.

---

## File Structure

| Path | Responsibility |
|---|---|
| `lib/core/storage/saved_conversation_id_cache.dart` *(new)* | Hive wrapper holding a single string under box `saved_conv_id` / key `id`. Read/write/clear. |
| `test/core/storage/saved_conversation_id_cache_test.dart` *(new)* | 3 unit tests against the helper using `_FakePathProvider` + `Hive.init`. |
| `lib/core/di/service_locator.dart` *(modify ~line 173)* | Open the new Hive box at startup; register `SavedConversationIdCache` as a lazy singleton. |
| `lib/features/messenger/presentation/widgets/saved_pinned_tile.dart` *(modify)* | Consume the cache: optimistic navigation + background refresh + offline-safe error swallowing. |

---

## Task 1: `SavedConversationIdCache` helper

**Files:**
- Create: `lib/core/storage/saved_conversation_id_cache.dart`

- [ ] **Step 1: Create the helper file**

Write `lib/core/storage/saved_conversation_id_cache.dart`:

```dart
import 'package:hive_flutter/hive_flutter.dart';

/// Persists the current user's SAVED-conversation id locally so the pinned
/// `SavedPinnedTile` can open the chat instantly (and offline) on subsequent
/// taps after the first online open.
///
/// Mirrors the shape of [SyncCursorStorage]: tiny Hive box with a single key.
class SavedConversationIdCache {
  static const String boxName = 'saved_conv_id';
  static const String _key = 'id';

  Future<String?> read() async {
    try {
      final box = Hive.box<String>(boxName);
      return box.get(_key);
    } catch (_) {
      // Defensive: corrupted box / not opened. Treat as cache miss.
      return null;
    }
  }

  Future<void> write(String id) async {
    final box = Hive.box<String>(boxName);
    await box.put(_key, id);
  }

  Future<void> clear() async {
    final box = Hive.box<String>(boxName);
    await box.delete(_key);
  }
}
```

- [ ] **Step 2: Run analyzer**

Run: `cd ~/Downloads/taler_id_mobile && flutter analyze lib/core/storage/saved_conversation_id_cache.dart`
Expected: `No issues found!`

- [ ] **Step 3: Commit**

```bash
cd ~/Downloads/taler_id_mobile
git add lib/core/storage/saved_conversation_id_cache.dart
git commit -m "feat(favorites): add SavedConversationIdCache Hive helper"
```

---

## Task 2: Unit tests for `SavedConversationIdCache`

**Files:**
- Create: `test/core/storage/saved_conversation_id_cache_test.dart`

- [ ] **Step 1: Write the failing test file**

Write `test/core/storage/saved_conversation_id_cache_test.dart`:

```dart
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:taler_id_mobile/core/storage/saved_conversation_id_cache.dart';

class _FakePathProvider extends PathProviderPlatform
    with MockPlatformInterfaceMixin {
  final String dir;
  _FakePathProvider(this.dir);

  @override
  Future<String?> getApplicationDocumentsPath() async => dir;
  @override
  Future<String?> getApplicationSupportPath() async => dir;
  @override
  Future<String?> getTemporaryPath() async => dir;
}

void main() {
  late Directory tempDir;

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('saved_conv_id_test_');
    PathProviderPlatform.instance = _FakePathProvider(tempDir.path);
    Hive.init(tempDir.path);
    await Hive.openBox<String>(SavedConversationIdCache.boxName);
  });

  tearDown(() async {
    await Hive.close();
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  test('read returns null when no id stored', () async {
    final cache = SavedConversationIdCache();
    expect(await cache.read(), isNull);
  });

  test('write then read returns the same value', () async {
    final cache = SavedConversationIdCache();
    await cache.write('conv-xyz');
    expect(await cache.read(), 'conv-xyz');
  });

  test('clear removes the value', () async {
    final cache = SavedConversationIdCache();
    await cache.write('conv-xyz');
    await cache.clear();
    expect(await cache.read(), isNull);
  });
}
```

- [ ] **Step 2: Run test (should already pass — helper exists from Task 1)**

Run: `cd ~/Downloads/taler_id_mobile && flutter test test/core/storage/saved_conversation_id_cache_test.dart`
Expected: `All tests passed!` (3 of 3).

- [ ] **Step 3: Commit**

```bash
cd ~/Downloads/taler_id_mobile
git add test/core/storage/saved_conversation_id_cache_test.dart
git commit -m "test(favorites): cover SavedConversationIdCache (read/write/clear)"
```

---

## Task 3: Wire the cache into DI + open Hive box at startup

**Files:**
- Modify: `lib/core/di/service_locator.dart` (around line 173, alongside other Hive box opens)

- [ ] **Step 1: Add the import**

In `lib/core/di/service_locator.dart`, near the top of the file alongside the other `import '../storage/...'` lines, add:

```dart
import '../storage/saved_conversation_id_cache.dart';
```

(Locate by searching for `import '../storage/sync_cursor_storage.dart';` and adding the new line right after it.)

- [ ] **Step 2: Open the Hive box and register the singleton**

In `lib/core/di/service_locator.dart`, locate this block (around line 169–173):

```dart
  // Notes offline: outbox queue + local note store (Hive)
  await Hive.openBox<String>(OutboxQueue.boxName);
  await Hive.openBox<String>(NotesLocalDataSource.boxName);
  await Hive.openBox<String>(CalendarLocalDataSource.boxName);
  await Hive.openBox<String>(ContactsLocalDataSource.boxName);
```

Append immediately after it:

```dart

  // Favorites offline: cached SAVED-conversation id (Hive)
  await Hive.openBox<String>(SavedConversationIdCache.boxName);
  sl.registerLazySingleton<SavedConversationIdCache>(
    () => SavedConversationIdCache(),
  );
```

- [ ] **Step 3: Run analyzer**

Run: `cd ~/Downloads/taler_id_mobile && flutter analyze lib/core/di/service_locator.dart`
Expected: `No issues found!`

- [ ] **Step 4: Run full unit-test suite to confirm no regression**

Run: `cd ~/Downloads/taler_id_mobile && flutter test`
Expected: All tests green (including the 3 new ones from Task 2).

- [ ] **Step 5: Commit**

```bash
cd ~/Downloads/taler_id_mobile
git add lib/core/di/service_locator.dart
git commit -m "feat(favorites): open saved_conv_id Hive box + register cache in DI"
```

---

## Task 4: Make `SavedPinnedTile` cache-aware (optimistic open + background refresh)

**Files:**
- Modify: `lib/features/messenger/presentation/widgets/saved_pinned_tile.dart`

Current `_open` (the entire method body, lines 11–24) makes an unconditional `getOrCreateSavedConversation()` call and shows the `savedOpenError` snackbar on any failure — even when a cached id exists. We replace it with a cache-first flow.

- [ ] **Step 1: Replace the import block**

In `lib/features/messenger/presentation/widgets/saved_pinned_tile.dart`, the existing imports are:

```dart
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/repositories/i_messenger_repository.dart';
```

Add the cache import (place it next to `i_messenger_repository.dart`):

```dart
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/storage/saved_conversation_id_cache.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/repositories/i_messenger_repository.dart';
```

- [ ] **Step 2: Replace `_open` with the cache-aware version**

Replace the existing `_open` method (lines 11–24):

```dart
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
```

with:

```dart
  Future<void> _open(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final cache = GetIt.instance<SavedConversationIdCache>();
    final repo = GetIt.instance<IMessengerRepository>();

    final cachedId = await cache.read();

    if (cachedId != null) {
      // Optimistic: navigate immediately, refresh from server in the
      // background. Works offline because the chat room itself is
      // offline-capable (Hive cache + outbox).
      if (!context.mounted) return;
      context.go('/dashboard/messenger/$cachedId');
      unawaited(_refreshCache(repo, cache));
      return;
    }

    // Cache miss — first-ever open. Requires connectivity.
    try {
      final convId = await repo.getOrCreateSavedConversation();
      await cache.write(convId);
      if (!context.mounted) return;
      context.go('/dashboard/messenger/$convId');
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.savedOpenError)),
      );
    }
  }

  Future<void> _refreshCache(
    IMessengerRepository repo,
    SavedConversationIdCache cache,
  ) async {
    try {
      final freshId = await repo.getOrCreateSavedConversation();
      await cache.write(freshId);
    } catch (_) {
      // Offline / transient — keep the cached id, no UI feedback.
    }
  }
```

- [ ] **Step 3: Add the `dart:async` import for `unawaited`**

At the top of the same file, add:

```dart
import 'dart:async';
```

Place it as the first import. The full final import list is:

```dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/storage/saved_conversation_id_cache.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/repositories/i_messenger_repository.dart';
```

- [ ] **Step 4: Run analyzer**

Run: `cd ~/Downloads/taler_id_mobile && flutter analyze lib/features/messenger/presentation/widgets/saved_pinned_tile.dart`
Expected: `No issues found!`

- [ ] **Step 5: Run full unit-test suite**

Run: `cd ~/Downloads/taler_id_mobile && flutter test`
Expected: All tests green.

- [ ] **Step 6: Commit**

```bash
cd ~/Downloads/taler_id_mobile
git add lib/features/messenger/presentation/widgets/saved_pinned_tile.dart
git commit -m "feat(favorites): cache-aware SavedPinnedTile (optimistic + offline)"
```

---

## Task 5: Integration smoke (hardware) — user-driven gate

> Skipped during automated execution. User runs this manually after merge to `dev` and before the combined PROD deploy gate.

- [ ] **Step 1: Online first-open**

  1. Fresh app state (or clear app data). Launch dev APK on an Android device with internet.
  2. Log in as a normal test account (e.g. `integration_test@taler-test.com`).
  3. On the Messenger tab, tap the pinned `Saved Messages` tile.
  4. Expected: chat opens; no snackbar.

- [ ] **Step 2: Offline subsequent open**

  1. Force-quit the app.
  2. Turn on airplane mode (or disable Wi-Fi + cellular).
  3. Relaunch the app.
  4. Tap the pinned `Saved Messages` tile.
  5. Expected: chat opens immediately; **no** `savedOpenError` snackbar.

- [ ] **Step 3: Regression — offline first-open (cache empty)**

  1. Clear app data (Android settings → Apps → Taler ID Dev → Storage → Clear data).
  2. Relaunch the app in airplane mode (login fails, so this step is artificial — skip if login requires network).
  3. Alternative: log in online, tap any tab **except** `Messenger`, force-quit, go offline, relaunch, then tap the Saved tile. Cache is still empty.
  4. Expected: existing `savedOpenError` snackbar appears.

---

## Self-Review Notes

- **Spec coverage:** every section of the spec is mapped — `SavedConversationIdCache` class (Task 1) + tests (Task 2), DI wiring (Task 3), `SavedPinnedTile` flow including optimistic + background refresh + empty-cache fallback (Task 4), hardware smoke (Task 5).
- **No placeholders:** every code block is complete; no TODO/TBD.
- **Type consistency:** `SavedConversationIdCache` API names (`boxName`, `read`, `write`, `clear`) are identical across Task 1, Task 2, Task 3, and Task 4.
- **Out-of-scope items from the spec** (delete dead `SavedMessagesScreen`, per-message favorites, pre-warming, desktop port) are intentionally **not** covered here.

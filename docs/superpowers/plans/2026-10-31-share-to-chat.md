# «Поделиться» из другого приложения: сразу выбор получателя и комментарий — план реализации

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Файл, которым поделились из другого приложения, открывает выбор получателя поверх «Сообщений», а в выбранном чате ждёт в полосе вложений, пока человек не напишет комментарий и не нажмёт «Отправить».

**Architecture:** `ShareIntentService` складывает share в ячейку `PendingShare` (`ValueNotifier`, забирается ровно один раз). `DashboardScreen` слушает ячейку и смену маршрута и, если не открыт экран звонка, делает `go('/dashboard/messenger/share')` — маршрут внутри «Сообщений» с `ShareTargetScreen`. Выбор построен на общем с «Переслать» виджете `RecipientPickerList`. `ChatRoomScreen` разбирает share чистой функцией `splitSharedItems` и больше не отправляет файлы сам.

**Tech Stack:** Flutter 3.38.9 / Dart, go_router 14.8.1, flutter_bloc, GetIt, receive_sharing_intent 1.8.1, `flutter_test` + `bloc_test` + `mocktail`.

**Спецификация:** `docs/superpowers/specs/2026-10-31-share-to-chat-design.md`

**Рабочий каталог:** `~/Downloads/taler_id_mobile/.worktrees/share-to-chat` (ветка `feat/share-to-chat` от `origin/dev` = `2f68fc0`, upstream снят — `git push` без аргументов никуда не уйдёт). Все пути ниже — от него.

**Исходное состояние:** `flutter test` — 1582 теста, все зелёные (~80 с). Новых тестов в плане 45, итог — 1627.

**Временные файлы:** в `OUT="${TMPDIR:-/tmp}/share-to-chat"`. Состояние shell между командами не сохраняется, поэтому каждая команда, которой он нужен, объявляет его сама.

---

## Карта файлов

| Файл | Что делает |
|---|---|
| `lib/core/services/pending_share.dart` (новый) | Ячейка «ждущий share»: положить, забрать один раз |
| `lib/core/services/share_intent_service.dart` | Плагин → ячейка; `pending` и `take()` вместо `pendingFilesStream`, `initialFiles`, `clearFiles()` |
| `lib/core/router/share_picker_gate.dart` (новый) | `stackLocations` + `canOpenSharePicker` — не поверх звонка, где бы он ни был в стеке; `sharePickerRedirect` — маршрут без файлов уводит в список |
| `lib/core/utils/constants.dart` | `RouteConstants.messengerShare` |
| `lib/core/router/app_router.dart` | Маршрут `share` внутри «Сообщений»; верхнеуровневый `/share-target` удалён |
| `lib/features/dashboard/presentation/dashboard_screen.dart` | Забирает share из ячейки и открывает выбор; таймеры и `Navigator.push` удалены |
| `lib/features/messenger/presentation/widgets/recipient_picker_list.dart` (новый) | Поиск, «Избранное», чаты — общий список для «Переслать» и «Поделиться» |
| `lib/features/messenger/presentation/screens/share_target_screen.dart` | «Кому отправить» на общем списке, «Избранное», индикатор загрузки |
| `lib/features/messenger/utils/shared_items.dart` (новый) | `splitSharedItems`: share → вложения и текст |
| `lib/features/messenger/presentation/screens/chat_room_screen.dart` | «Переслать» на общем списке; `_addSharedFiles` без автоотправки; подсказка поля ввода |
| `lib/l10n/app_ru.arb`, `lib/l10n/app_en.arb` (+ сгенерированные `lib/l10n/app_localizations*.dart`) | «Кому отправить», «Добавьте комментарий...» |
| `test/core/services/pending_share_test.dart`, `test/core/router/share_picker_gate_test.dart`, `test/features/messenger/utils/shared_items_test.dart`, `test/features/messenger/presentation/widgets/recipient_picker_list_test.dart`, `test/features/messenger/presentation/screens/share_target_screen_test.dart` (новые) | Тесты |

Порядок задач подобран так, чтобы после каждой проект собирался и все тесты были зелёными: сначала новые независимые части, потом переключение потребителей, последним — дашборд вместе с API сервиса.

---

### Task 0: Подготовка

**Files:** нет изменений.

- [ ] **Step 1: Зависимости**

```bash
cd ~/Downloads/taler_id_mobile/.worktrees/share-to-chat
git status -sb        # ## feat/share-to-chat, без изменений
flutter --version | head -1   # Flutter 3.38.9
flutter pub get
git status --short    # пусто
```

Если `pub get` изменил `pubspec.lock`, остановиться и выяснить почему: версия Flutter должна совпадать со сборочными хостами.

- [ ] **Step 2: Снимок замечаний анализатора**

Чистым `flutter analyze` в этом репозитории не бывает (сотни старых замечаний), поэтому сравниваем «до» и «после» по своим файлам, без номеров строк. В командах по отдельным файлам сначала отбираются строки диагностики (` • `): иначе в сравнение попадает шапка `Analyzing <файл>...`.

```bash
OUT="${TMPDIR:-/tmp}/share-to-chat"; mkdir -p "$OUT"
flutter analyze --no-fatal-infos --no-fatal-warnings > "$OUT/analyze-before.txt" 2>&1
grep -E "share_intent_service|pending_share|share_picker_gate|shared_items|recipient_picker_list|share_target_screen|chat_room_screen|dashboard_screen|app_router|core/utils/constants" "$OUT/analyze-before.txt" \
  | sed -E 's/:[0-9]+:[0-9]+ / /' | sort > "$OUT/analyze-before-ours.txt"
wc -l < "$OUT/analyze-before-ours.txt"
```

Число запомнить — оно понадобится в Task 11.

---

### Task 1: Ячейка «ждущий share»

**Files:**
- Create: `lib/core/services/pending_share.dart`
- Test: `test/core/services/pending_share_test.dart`

- [ ] **Step 1: Падающий тест**

```dart
// test/core/services/pending_share_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:taler_id_mobile/core/services/pending_share.dart';

SharedMediaFile _file(String path) =>
    SharedMediaFile(path: path, type: SharedMediaType.file);

void main() {
  test('a share offered before anyone listens is still there to take', () {
    final slot = PendingShare()..offer([_file('/tmp/a.pdf')]);
    expect(slot.take()!.single.path, '/tmp/a.pdf');
  });

  test('take hands the share out exactly once', () {
    final slot = PendingShare()..offer([_file('/tmp/a.pdf')]);
    expect(slot.take(), isNotNull);
    expect(slot.take(), isNull);
  });

  test('a newer share replaces one nobody has taken', () {
    final slot = PendingShare()
      ..offer([_file('/tmp/old.pdf')])
      ..offer([_file('/tmp/new.pdf')]);
    expect(slot.take()!.single.path, '/tmp/new.pdf');
    expect(slot.take(), isNull);
  });

  test('an empty share is not stored', () {
    final slot = PendingShare()..offer(const []);
    expect(slot.files.value, isNull);
  });

  test('listeners hear the share arrive and the slot empty', () {
    final slot = PendingShare();
    final seen = <int?>[];
    slot.files.addListener(() => seen.add(slot.files.value?.length));
    slot.offer([_file('/tmp/a.pdf'), _file('/tmp/b.pdf')]);
    slot.take();
    expect(seen, [2, null]);
  });

  test('replacing a waiting share notifies; taking from an empty slot does not',
      () {
    final slot = PendingShare()..offer([_file('/tmp/old.pdf')]);
    var notified = 0;
    slot.files.addListener(() => notified++);
    slot.offer([_file('/tmp/new.pdf')]);
    expect(notified, 1);
    slot.take();
    expect(notified, 2);
    slot.take();
    expect(notified, 2);
  });

  test('the slot keeps its own unmodifiable copy', () {
    final source = [_file('/tmp/a.pdf')];
    final slot = PendingShare()..offer(source);
    source.add(_file('/tmp/b.pdf'));
    final taken = slot.take()!;
    expect(taken.length, 1);
    expect(() => taken.add(_file('/tmp/c.pdf')), throwsUnsupportedError);
  });
}
```

- [ ] **Step 2: Убедиться, что падает**

Run: `flutter test test/core/services/pending_share_test.dart`
Expected: FAIL — ошибка компиляции, `pending_share.dart` не найден / `PendingShare` не определён.

- [ ] **Step 3: Реализация**

```dart
// lib/core/services/pending_share.dart
import 'package:flutter/foundation.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

/// Holds a share from another app until the dashboard can show the
/// recipient picker.
///
/// One slot instead of a stream plus a cold-start copy: both used to reach
/// the dashboard, which then opened the picker twice, and a stream event
/// fired before anyone listened was lost (2026-10-31). A newer share replaces
/// one nobody has taken; [take] hands it out exactly once.
class PendingShare {
  final ValueNotifier<List<SharedMediaFile>?> _files = ValueNotifier(null);

  /// The waiting share; null when there is none.
  ValueListenable<List<SharedMediaFile>?> get files => _files;

  void offer(List<SharedMediaFile> files) {
    if (files.isEmpty) return;
    _files.value = List.unmodifiable(files);
  }

  List<SharedMediaFile>? take() {
    final files = _files.value;
    _files.value = null;
    return files;
  }
}
```

- [ ] **Step 4: Тест проходит**

Run: `flutter test test/core/services/pending_share_test.dart`
Expected: `+7: All tests passed!`

- [ ] **Step 5: Коммит**

```bash
git add lib/core/services/pending_share.dart test/core/services/pending_share_test.dart
git commit -m "feat(share): ячейка «ждущий share» — забирается ровно один раз" \
  -m "Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>"
```

---

### Task 2: Разбор share на вложения и текст

Логика та же, что сейчас внутри `ChatRoomScreen._addSharedFiles`, — выносится, чтобы её можно было проверить без экрана чата.

**Files:**
- Create: `lib/features/messenger/utils/shared_items.dart`
- Test: `test/features/messenger/utils/shared_items_test.dart`

- [ ] **Step 1: Падающий тест**

```dart
// test/features/messenger/utils/shared_items_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:taler_id_mobile/features/messenger/utils/shared_items.dart';

SharedMediaFile _item(String path, SharedMediaType type, {String? message}) =>
    SharedMediaFile(path: path, type: type, message: message);

void main() {
  test('a document becomes an attachment the server types', () {
    final r = splitSharedItems(
        [_item('/data/user/0/app/cache/Отчёт.pdf', SharedMediaType.file)]);
    expect(r.attachments.single.path, '/data/user/0/app/cache/Отчёт.pdf');
    expect(r.attachments.single.name, 'Отчёт.pdf');
    expect(r.attachments.single.type, isNull);
    expect(r.text, isEmpty);
  });

  test('images and videos are typed by extension, case-insensitively', () {
    final r = splitSharedItems([
      _item('/tmp/IMG_1.HEIC', SharedMediaType.image),
      _item('/tmp/clip.mov', SharedMediaType.video),
    ]);
    expect(r.attachments.map((a) => a.type), ['image', 'video']);
  });

  test('a file:// URI becomes a plain path, spaces decoded', () {
    final r = splitSharedItems([
      _item('file:///private/var/mobile/Shared/My%20Report.pdf',
          SharedMediaType.file),
    ]);
    expect(r.attachments.single.path, '/private/var/mobile/Shared/My Report.pdf');
    expect(r.attachments.single.name, 'My Report.pdf');
  });

  test('text and links go to the input field, with the iOS message', () {
    final r = splitSharedItems([
      _item('https://example.com/a', SharedMediaType.url,
          message: 'Look at this'),
      _item('Просто текст', SharedMediaType.text),
    ]);
    expect(r.attachments, isEmpty);
    expect(r.text, 'https://example.com/a\nLook at this\nПросто текст');
  });

  test('a message equal to the link is not repeated', () {
    final r = splitSharedItems([
      _item('https://example.com/a', SharedMediaType.url,
          message: 'https://example.com/a'),
    ]);
    expect(r.text, 'https://example.com/a');
  });

  test('items with an empty path are skipped', () {
    final r = splitSharedItems([
      _item('', SharedMediaType.file),
      _item('', SharedMediaType.text),
    ]);
    expect(r.attachments, isEmpty);
    expect(r.text, isEmpty);
  });

  test('files and text in one share are split, files keep their order', () {
    final r = splitSharedItems([
      _item('/tmp/a.pdf', SharedMediaType.file),
      _item('caption from the app', SharedMediaType.text),
      _item('/tmp/b.jpg', SharedMediaType.image),
    ]);
    expect(r.attachments.map((a) => a.name), ['a.pdf', 'b.jpg']);
    expect(r.text, 'caption from the app');
  });

  test('a file:// URI that does not parse keeps the file, scheme cut off', () {
    final r = splitSharedItems([
      _item('file:///private/var/Shared/Invoice #3.pdf', SharedMediaType.file),
      _item('/tmp/ok.pdf', SharedMediaType.file),
    ]);
    expect(r.attachments.map((a) => a.path),
        ['/private/var/Shared/Invoice #3.pdf', '/tmp/ok.pdf']);
  });

  test('a name without an extension is not typed by its own name', () {
    final r = splitSharedItems([_item('/tmp/mp4', SharedMediaType.file)]);
    expect(r.attachments.single.name, 'mp4');
    expect(r.attachments.single.type, isNull);
  });

  test('a path that ends with a slash is skipped', () {
    final r = splitSharedItems([_item('/tmp/dir/', SharedMediaType.file)]);
    expect(r.attachments, isEmpty);
  });
}
```

- [ ] **Step 2: Убедиться, что падает**

Run: `flutter test test/features/messenger/utils/shared_items_test.dart`
Expected: FAIL — `shared_items.dart` не найден.

- [ ] **Step 3: Реализация**

```dart
// lib/features/messenger/utils/shared_items.dart
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

/// A file from another app, ready for the chat's attachment strip.
class SharedAttachment {
  final String path;
  final String name;

  /// 'image' or 'video' when the extension says so; null lets the server
  /// decide, as for any attached file.
  final String? type;

  const SharedAttachment({required this.path, required this.name, this.type});
}

/// What a share turns into in a chat: files for the attachment strip and
/// text for the input field.
class SharedItems {
  final List<SharedAttachment> attachments;

  /// Shared text and links, one per line; empty when there were none.
  final String text;

  const SharedItems({required this.attachments, required this.text});
}

const _imageExts = {'jpg', 'jpeg', 'png', 'gif', 'webp', 'heic', 'heif', 'bmp'};
const _videoExts = {'mp4', 'mov', 'avi', 'mkv', 'webm', '3gp'};

/// Splits shared [items] into attachments and text.
///
/// Text and link shares go to the input field rather than being uploaded:
/// a URL string is not a file, and uploading it failed silently (1.0.69).
SharedItems splitSharedItems(List<SharedMediaFile> items) {
  final attachments = <SharedAttachment>[];
  final textParts = <String>[];
  for (final item in items) {
    if (item.type == SharedMediaType.text || item.type == SharedMediaType.url) {
      if (item.path.isNotEmpty) textParts.add(item.path);
      // iOS sometimes sends an accompanying message alongside a URL share.
      final message = item.message;
      if (message != null && message.isNotEmpty && message != item.path) {
        textParts.add(message);
      }
      continue;
    }
    var path = item.path;
    if (path.isEmpty) continue;
    if (path.startsWith('file://')) path = _filePath(path);
    final name = path.split('/').last;
    if (name.isEmpty) continue;
    final dot = name.lastIndexOf('.');
    final ext = dot > 0 ? name.substring(dot + 1).toLowerCase() : '';
    final type = _imageExts.contains(ext)
        ? 'image'
        : _videoExts.contains(ext)
            ? 'video'
            : null;
    attachments.add(SharedAttachment(path: path, name: name, type: type));
  }
  return SharedItems(attachments: attachments, text: textParts.join('\n'));
}

/// `file://` URI → plain path. A name with `#`, `?` or an encoded `/` does
/// not parse back as a URI; then the scheme is simply cut off instead of the
/// whole share failing on one file.
String _filePath(String uri) {
  try {
    return Uri.parse(uri).toFilePath();
  } catch (_) {
    return uri.substring('file://'.length);
  }
}
```

- [ ] **Step 4: Тест проходит**

Run: `flutter test test/features/messenger/utils/shared_items_test.dart`
Expected: `+10: All tests passed!`

- [ ] **Step 5: Коммит**

```bash
git add lib/features/messenger/utils/shared_items.dart test/features/messenger/utils/shared_items_test.dart
git commit -m "feat(share): splitSharedItems — разбор share на вложения и текст" \
  -m "Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>"
```

---

### Task 3: Когда выбор можно открыть

Проверяется **весь стек навигации**, а не `currentConfiguration.uri`: в go_router 14.8.1 тот меняется только от `go`, а экраны звонков в приложении в основном открываются `push`-ем (из чата, контактов, истории, по CallKit) — после `push('/dashboard/voice')` `uri.path` остаётся адресом чата. Каждый экран, положенный `push`-ем, — отдельный элемент `currentConfiguration.matches` со своим `matchedLocation` (проверено пробой 2026-10-31).

**Files:**
- Create: `lib/core/router/share_picker_gate.dart`
- Modify: `lib/core/utils/constants.dart` (строка 51, после `messengerSearch`)
- Test: `test/core/router/share_picker_gate_test.dart`

- [ ] **Step 1: Падающий тест**

В виджет-тесте нельзя класть `push`-ем маршрут из `ShellRoute` поверх экрана вне его (чат поверх звонка): go_router падает на `Duplicate GlobalKey` навигатора. Поэтому поверх звонка кладётся отдельный верхнеуровневый маршрут `/other`.

```dart
// test/core/router/share_picker_gate_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:taler_id_mobile/core/router/share_picker_gate.dart';
import 'package:taler_id_mobile/core/services/pending_share.dart';
import 'package:taler_id_mobile/core/utils/constants.dart';

void main() {
  test('the picker opens over ordinary screens', () {
    for (final stack in [
      [RouteConstants.assistant],
      [RouteConstants.messenger],
      ['/dashboard/messenger/c-1'],
      [RouteConstants.messengerShare],
      [RouteConstants.settings],
      [RouteConstants.calendar],
      ['/dashboard/messenger/c-1', '/dashboard/user/u-1'],
    ]) {
      expect(canOpenSharePicker(stack), isTrue, reason: '$stack');
    }
  });

  test('the picker waits while a call screen is anywhere on the stack', () {
    for (final stack in [
      [RouteConstants.voice],
      ['/dashboard/messenger/c-1', RouteConstants.voice],
      ['/dashboard/messenger/c-1', RouteConstants.voice, '/other'],
      ['/group-call/gc-1'],
      ['/dashboard/messenger/c-1', '/group-call/gc-1/lobby'],
    ]) {
      expect(canOpenSharePicker(stack), isFalse, reason: '$stack');
    }
  });

  testWidgets('stackLocations sees call screens opened with push or go',
      (tester) async {
    final router = GoRouter(
      initialLocation: '/dashboard/messenger/c-1',
      routes: [
        GoRoute(
            path: RouteConstants.voice,
            builder: (_, __) => const Text('voice')),
        GoRoute(
            path: '/group-call/:id',
            builder: (_, __) => const Text('group call')),
        GoRoute(path: '/other', builder: (_, __) => const Text('other')),
        ShellRoute(
          builder: (_, __, child) => Scaffold(body: child),
          routes: [
            GoRoute(
              path: RouteConstants.messenger,
              builder: (_, __) => const Text('list'),
              routes: [
                GoRoute(path: ':id', builder: (_, __) => const Text('chat')),
              ],
            ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    bool canOpen() => canOpenSharePicker(
        stackLocations(router.routerDelegate.currentConfiguration));

    expect(canOpen(), isTrue);

    router.push('/dashboard/messenger/c-2');
    await tester.pumpAndSettle();
    expect(stackLocations(router.routerDelegate.currentConfiguration),
        contains('/dashboard/messenger/c-2'),
        reason: 'a screen pushed inside the shell is listed too');
    expect(canOpen(), isTrue);
    router.pop();
    await tester.pumpAndSettle();

    router.push('${RouteConstants.voice}?room=r1');
    await tester.pumpAndSettle();
    expect(find.text('voice'), findsOneWidget);
    expect(canOpen(), isFalse, reason: 'call screen pushed over the chat');

    router.push('/other');
    await tester.pumpAndSettle();
    expect(canOpen(), isFalse, reason: 'call screen under another screen');

    router.pop();
    await tester.pumpAndSettle();
    router.pop();
    await tester.pumpAndSettle();
    expect(find.text('chat'), findsOneWidget);
    expect(canOpen(), isTrue, reason: 'call screen closed (minimised)');

    router.push('/group-call/g1');
    await tester.pumpAndSettle();
    expect(canOpen(), isFalse, reason: 'group call pushed');

    router.go('${RouteConstants.voice}?room=r2');
    await tester.pumpAndSettle();
    expect(canOpen(), isFalse, reason: 'call screen reached with go');
  });

  test('the picker route without shared files goes back to the chat list', () {
    expect(sharePickerRedirect(null), RouteConstants.messenger);
    expect(sharePickerRedirect(const []), RouteConstants.messenger);
    expect(sharePickerRedirect('not a list'), RouteConstants.messenger);
    expect(sharePickerRedirect(['/tmp/a.pdf']), RouteConstants.messenger);
  });

  test('the picker route with shared files stays', () {
    expect(
      sharePickerRedirect(
          [SharedMediaFile(path: '/tmp/a.pdf', type: SharedMediaType.file)]),
      isNull,
    );
  });

  test('a share taken from the slot passes the picker route redirect', () {
    final files = (PendingShare()
          ..offer([
            SharedMediaFile(path: '/tmp/a.pdf', type: SharedMediaType.file),
          ]))
        .take();
    expect(sharePickerRedirect(files), isNull);
  });
}
```

- [ ] **Step 2: Убедиться, что падает**

Run: `flutter test test/core/router/share_picker_gate_test.dart`
Expected: FAIL — `share_picker_gate.dart` не найден, `messengerShare` не определён.

- [ ] **Step 3: Константа маршрута**

В `lib/core/utils/constants.dart` после строки
```dart
  static const messengerSearch = '/dashboard/messenger/search';
```
добавить
```dart
  static const messengerShare = '/dashboard/messenger/share';
```

- [ ] **Step 4: Реализация**

```dart
// lib/core/router/share_picker_gate.dart
import 'package:go_router/go_router.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

import '../utils/constants.dart';

/// Every location on the navigation stack, including screens pushed over or
/// inside a shell route.
///
/// `currentConfiguration.uri` only follows `go`: after `push` of a call
/// screen — and most call screens are pushed — it still shows the chat
/// underneath (go_router 14.8, checked 2026-10-31). A screen pushed over the
/// shell is its own top-level match; one pushed inside the shell is folded
/// into the shell's match, hence the walk into [ShellRouteMatch.matches].
Iterable<String> stackLocations(RouteMatchList configuration) =>
    _locations(configuration.matches);

Iterable<String> _locations(List<RouteMatchBase> matches) sync* {
  for (final m in matches) {
    yield m.matchedLocation;
    if (m is ShellRouteMatch) yield* _locations(m.matches);
  }
}

/// Whether a share from another app may open the recipient picker over the
/// navigation [stack] (see [stackLocations]).
///
/// Not while a call screen is anywhere on it: the picker is opened with `go`,
/// which would drop the screen the conversation runs on, even with something
/// pushed over it. The share waits until the call is minimised or over — the
/// dashboard checks again on every route change.
bool canOpenSharePicker(Iterable<String> stack) => !stack.any(_isCallScreen);

bool _isCallScreen(String location) =>
    location.startsWith(RouteConstants.voice) ||
    location.startsWith('/group-call/');

/// Redirect for the picker route: without shared files there is nothing to
/// show, so back to the chat list.
String? sharePickerRedirect(Object? extra) =>
    extra is List<SharedMediaFile> && extra.isNotEmpty
        ? null
        : RouteConstants.messenger;
```

- [ ] **Step 5: Тест проходит**

Run: `flutter test test/core/router/share_picker_gate_test.dart`
Expected: `+6: All tests passed!`

- [ ] **Step 6: Коммит**

```bash
git add lib/core/router/share_picker_gate.dart lib/core/utils/constants.dart test/core/router/share_picker_gate_test.dart
git commit -m "feat(share): выбор получателя не открывается поверх звонка" \
  -m "Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>"
```

---

### Task 4: Общий список получателей

Плитки и поиск переносятся из `_ForwardPickerSheet` (`chat_room_screen.dart`) почти дословно. Отличия: беседа `SAVED` не попадает в общий список (у «Избранного» своя строка), а пустой список показывает «Нет чатов» или индикатор загрузки.

**Files:**
- Create: `lib/features/messenger/presentation/widgets/recipient_picker_list.dart`
- Test: `test/features/messenger/presentation/widgets/recipient_picker_list_test.dart`

- [ ] **Step 1: Падающий тест**

```dart
// test/features/messenger/presentation/widgets/recipient_picker_list_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taler_id_mobile/core/theme/app_theme.dart';
import 'package:taler_id_mobile/features/messenger/domain/entities/conversation_entity.dart';
import 'package:taler_id_mobile/features/messenger/presentation/widgets/recipient_picker_list.dart';
import 'package:taler_id_mobile/l10n/app_localizations.dart';

ConversationEntity _conv(String id, String type,
        {String? name, String? otherUserName, String? myRole}) =>
    ConversationEntity(
      id: id,
      participantIds: const [],
      type: type,
      name: name,
      otherUserName: otherUserName,
      myRole: myRole,
    );

final _anna = _conv('c-anna', 'DIRECT', otherUserName: 'Anna Ivanova');
final _team = _conv('c-team', 'GROUP', name: 'Taler team');
final _news =
    _conv('c-news', 'CHANNEL', name: 'Taler news', myRole: 'SUBSCRIBER');
final _saved = _conv('c-saved', 'SAVED', name: 'Saved conversation');

Widget _wrap(Widget child) => MaterialApp(
      theme: AppTheme.dark,
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    );

void main() {
  test('candidates: chats the user can write to, without Saved', () {
    expect(
      recipientCandidates([_anna, _team, _news, _saved]).map((c) => c.id),
      ['c-anna', 'c-team'],
    );
  });

  test('display name: the conversation name, else the other person; '
      'the AI analyst by its app title', () {
    final en = lookupAppLocalizations(const Locale('en'));
    expect(recipientDisplayName(_team, en), 'Taler team');
    expect(recipientDisplayName(_anna, en), 'Anna Ivanova');
    expect(recipientDisplayName(_conv('c-x', 'DIRECT'), en), '');
    expect(
        recipientDisplayName(
            _conv('c-ai', 'AI_ANALYST', name: 'AI Аналитик'), en),
        'AI Analyst');
  });

  testWidgets('shows writable chats and Favorites once, at the top',
      (tester) async {
    await tester.pumpWidget(_wrap(RecipientPickerList(
      conversations: [_anna, _team, _news, _saved],
      onSelected: (_) {},
      onSelectSaved: () {},
    )));
    expect(find.text('Favorites'), findsOneWidget);
    expect(find.text('Anna Ivanova'), findsOneWidget);
    expect(find.text('Taler team'), findsOneWidget);
    expect(find.text('Taler news'), findsNothing);
    expect(find.text('Saved conversation'), findsNothing);
    expect(tester.getTopLeft(find.text('Favorites')).dy,
        lessThan(tester.getTopLeft(find.text('Anna Ivanova')).dy));
  });

  testWidgets('search narrows by the shown name and hides Favorites',
      (tester) async {
    await tester.pumpWidget(_wrap(RecipientPickerList(
      conversations: [_anna, _team],
      onSelected: (_) {},
      onSelectSaved: () {},
    )));
    await tester.enterText(find.byType(TextField), 'ANNA');
    await tester.pump();
    expect(find.text('Anna Ivanova'), findsOneWidget);
    expect(find.text('Taler team'), findsNothing);
    expect(find.text('Favorites'), findsNothing);
    expect(find.text('No chats'), findsNothing);
  });

  testWidgets('tapping a chat reports that conversation', (tester) async {
    ConversationEntity? picked;
    await tester.pumpWidget(_wrap(RecipientPickerList(
      conversations: [_anna, _team],
      onSelected: (c) => picked = c,
    )));
    await tester.tap(find.text('Taler team'));
    await tester.pump();
    expect(picked?.id, 'c-team');
  });

  testWidgets('tapping Favorites calls onSelectSaved', (tester) async {
    var savedTaps = 0;
    await tester.pumpWidget(_wrap(RecipientPickerList(
      conversations: [_anna],
      onSelected: (_) {},
      onSelectSaved: () => savedTaps++,
    )));
    await tester.tap(find.text('Favorites'));
    await tester.pump();
    expect(savedTaps, 1);
  });

  testWidgets('no Favorites row without onSelectSaved', (tester) async {
    await tester.pumpWidget(_wrap(RecipientPickerList(
      conversations: [_anna],
      onSelected: (_) {},
    )));
    expect(find.text('Favorites'), findsNothing);
  });

  testWidgets('loading with nothing to show: a spinner, not "No chats"',
      (tester) async {
    await tester.pumpWidget(_wrap(RecipientPickerList(
      conversations: const [],
      loading: true,
      onSelected: (_) {},
    )));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('No chats'), findsNothing);
  });

  testWidgets('loaded and empty: "No chats"', (tester) async {
    await tester.pumpWidget(_wrap(RecipientPickerList(
      conversations: const [],
      onSelected: (_) {},
    )));
    expect(find.text('No chats'), findsOneWidget);
  });

  testWidgets('Favorites stays on top of the spinner while chats load',
      (tester) async {
    await tester.pumpWidget(_wrap(RecipientPickerList(
      conversations: const [],
      loading: true,
      onSelected: (_) {},
      onSelectSaved: () {},
    )));
    expect(find.text('Favorites'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('No chats'), findsNothing);
  });

  testWidgets('a search with no matches shows an empty list', (tester) async {
    await tester.pumpWidget(_wrap(RecipientPickerList(
      conversations: [_anna, _team],
      onSelected: (_) {},
      onSelectSaved: () {},
    )));
    await tester.enterText(find.byType(TextField), 'zzz');
    await tester.pump();
    expect(find.byType(ListTile), findsNothing);
    expect(find.text('No chats'), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('typing while chats still load keeps the spinner',
      (tester) async {
    await tester.pumpWidget(_wrap(RecipientPickerList(
      conversations: const [],
      loading: true,
      onSelected: (_) {},
    )));
    await tester.enterText(find.byType(TextField), 'anna');
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('an unnamed conversation is shown as "Dialog"', (tester) async {
    await tester.pumpWidget(_wrap(RecipientPickerList(
      conversations: [_conv('c-x', 'DIRECT')],
      onSelected: (_) {},
    )));
    expect(find.text('Dialog'), findsOneWidget);
  });

  testWidgets('the AI analyst is listed and found by its app title',
      (tester) async {
    await tester.pumpWidget(_wrap(RecipientPickerList(
      conversations: [_anna, _conv('c-ai', 'AI_ANALYST', name: 'AI Аналитик')],
      onSelected: (_) {},
    )));
    expect(find.text('AI Analyst'), findsOneWidget);
    expect(find.text('AI Аналитик'), findsNothing);
    await tester.enterText(find.byType(TextField), 'analyst');
    await tester.pump();
    expect(find.text('AI Analyst'), findsOneWidget);
    expect(find.text('Anna Ivanova'), findsNothing);
  });

  testWidgets('spaces around the query are ignored', (tester) async {
    await tester.pumpWidget(_wrap(RecipientPickerList(
      conversations: [_anna, _team],
      onSelected: (_) {},
      onSelectSaved: () {},
    )));
    await tester.enterText(find.byType(TextField), ' anna ');
    await tester.pump();
    expect(find.text('Anna Ivanova'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '   ');
    await tester.pump();
    expect(find.text('Favorites'), findsOneWidget);
    expect(find.text('Taler team'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Убедиться, что падает**

Run: `flutter test test/features/messenger/presentation/widgets/recipient_picker_list_test.dart`
Expected: FAIL — `recipient_picker_list.dart` не найден.

- [ ] **Step 3: Реализация**

```dart
// lib/features/messenger/presentation/widgets/recipient_picker_list.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../voice/presentation/widgets/pulsing_avatar.dart'
    show rainbowColorFor;
import '../../domain/entities/conversation_entity.dart';
import '../../utils/recipient_filters.dart';

/// Имя, которое показывает строка получателя и по которому ищет поиск.
///
/// ИИ-аналитик — по названию из локализации, как в списке чатов: на сервере
/// его беседа записана по-русски («AI Аналитик»). Остальные — название
/// беседы, а если его нет — имя собеседника; пустая строка, если нет ничего.
String recipientDisplayName(ConversationEntity c, AppLocalizations l10n) {
  if (c.type == 'AI_ANALYST') return l10n.aiAnalystTitle;
  return c.name ?? c.otherUserName ?? '';
}

/// Беседы, которые предлагаются получателями: те, куда можно писать, кроме
/// «Избранного». У него своя строка сверху, а созданная беседа SAVED в
/// общем списке показывалась второй раз.
List<ConversationEntity> recipientCandidates(List<ConversationEntity> all) =>
    filterRecipients(all)
        .where((c) => c.type != 'SAVED')
        .toList(growable: false);

/// Поиск, «Избранное» и чаты, куда можно писать.
///
/// Общий для «Переслать» и «Поделиться», чтобы два выбора не расходились.
/// Обёртку (лист или полный экран, заголовок) и действие по нажатию задаёт
/// вызывающий. Высота должна быть ограничена: внутри `Column` оборачивать
/// в `Expanded`.
class RecipientPickerList extends StatefulWidget {
  final List<ConversationEntity> conversations;
  final ValueChanged<ConversationEntity> onSelected;

  /// Строка «Избранное» сверху; нет обработчика — нет строки.
  final VoidCallback? onSelectSaved;

  /// Для листа на `DraggableScrollableSheet`.
  final ScrollController? scrollController;

  /// Беседы ещё грузятся: вместо «Нет чатов» — индикатор.
  final bool loading;

  const RecipientPickerList({
    super.key,
    required this.conversations,
    required this.onSelected,
    this.onSelectSaved,
    this.scrollController,
    this.loading = false,
  });

  @override
  State<RecipientPickerList> createState() => _RecipientPickerListState();
}

class _RecipientPickerListState extends State<RecipientPickerList> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final l10n = AppLocalizations.of(context)!;
    final query = _query.trim().toLowerCase();
    final candidates = recipientCandidates(widget.conversations)
        .where((c) =>
            recipientDisplayName(c, l10n).toLowerCase().contains(query))
        .toList();
    // Пока идёт поиск, «Избранное» прячется, а пустой результат — просто
    // пустой список: «Нет чатов» там было бы неправдой. Пока беседы
    // грузятся, индикатор виден и во время поиска.
    final showSaved = widget.onSelectSaved != null && query.isEmpty;
    final showEmptyRow =
        candidates.isEmpty && (query.isEmpty || widget.loading);
    final itemCount =
        (showSaved ? 1 : 0) + (showEmptyRow ? 1 : candidates.length);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            autofocus: false,
            style: TextStyle(color: colors.textPrimary),
            decoration: InputDecoration(
              hintText: l10n.chatSearchHint,
              hintStyle: TextStyle(color: colors.textSecondary),
              prefixIcon:
                  Icon(Icons.search_rounded, color: colors.textSecondary),
              filled: true,
              fillColor: colors.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
            ),
            onChanged: (v) => setState(() => _query = v),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.builder(
            controller: widget.scrollController,
            itemCount: itemCount,
            itemBuilder: (_, i) {
              if (showSaved && i == 0) {
                return _SavedTile(onTap: widget.onSelectSaved!);
              }
              if (showEmptyRow) return _EmptyRow(loading: widget.loading);
              final conv = candidates[showSaved ? i - 1 : i];
              return _RecipientTile(
                conversation: conv,
                onTap: () => widget.onSelected(conv),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _SavedTile extends StatelessWidget {
  final VoidCallback onTap;
  const _SavedTile({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final l10n = AppLocalizations.of(context)!;
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFA855F7), width: 2),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFA855F7).withValues(alpha: 0.35),
              blurRadius: 8,
            ),
          ],
        ),
        child: Container(
          width: 40,
          height: 40,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [Color(0xFF22D3EE), Color(0xFFA855F7)],
            ),
          ),
          child: const Icon(Icons.cloud_done_rounded,
              color: Colors.white, size: 22),
        ),
      ),
      title: Text(l10n.messengerSavedSection,
          style: TextStyle(
              color: colors.textPrimary, fontWeight: FontWeight.w600)),
      subtitle: Text(l10n.messengerSavedSubtitle,
          style: TextStyle(color: colors.textSecondary, fontSize: 13)),
      onTap: onTap,
    );
  }
}

class _RecipientTile extends StatelessWidget {
  final ConversationEntity conversation;
  final VoidCallback onTap;
  const _RecipientTile({required this.conversation, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final l10n = AppLocalizations.of(context)!;
    final conv = conversation;
    final shown = recipientDisplayName(conv, l10n);
    final name = shown.isNotEmpty ? shown : l10n.chatDialog;
    final avatarUrl =
        conv.type == 'DIRECT' ? conv.otherUserAvatar : conv.avatarUrl;
    // Цвет кольца — от имени, а у безымянной беседы от id: иначе все
    // безымянные получили бы один цвет от подставленного «Диалог».
    final ringColor = rainbowColorFor(shown.isNotEmpty ? shown : conv.id);
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: ringColor, width: 2),
          boxShadow: [
            BoxShadow(
              color: ringColor.withValues(alpha: 0.35),
              blurRadius: 8,
            ),
          ],
        ),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: avatarUrl != null
                ? null
                : RadialGradient(
                    center: const Alignment(-0.3, -0.4),
                    radius: 1.1,
                    colors: [
                      Color.lerp(ringColor, Colors.white, 0.28)!,
                      ringColor,
                      Color.lerp(ringColor, Colors.black, 0.38)!,
                    ],
                    stops: const [0.0, 0.55, 1.0],
                  ),
          ),
          child: avatarUrl != null
              ? ClipOval(
                  child: CachedNetworkImage(
                    imageUrl: avatarUrl,
                    fit: BoxFit.cover,
                  ),
                )
              : Center(
                  child: Text(
                    name[0].toUpperCase(),
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18),
                  ),
                ),
        ),
      ),
      title: Text(name, style: TextStyle(color: colors.textPrimary)),
      onTap: onTap,
    );
  }
}

class _EmptyRow extends StatelessWidget {
  final bool loading;
  const _EmptyRow({required this.loading});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: loading
            ? const CircularProgressIndicator()
            : Text(
                AppLocalizations.of(context)!.shareNoChats,
                style: TextStyle(color: AppColors.of(context).textSecondary),
              ),
      ),
    );
  }
}
```

- [ ] **Step 4: Тест проходит**

Run: `flutter test test/features/messenger/presentation/widgets/recipient_picker_list_test.dart`
Expected: `+15: All tests passed!`

- [ ] **Step 5: Коммит**

```bash
git add lib/features/messenger/presentation/widgets/recipient_picker_list.dart test/features/messenger/presentation/widgets/recipient_picker_list_test.dart
git commit -m "feat(messenger): общий список получателей для «Переслать» и «Поделиться»" \
  -m "Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>"
```

---

### Task 5: «Переслать» на общем списке

Поведение «Переслать» не меняется, кроме исчезнувшего дубля «Избранного». Тестов на лист пересылки в репозитории нет, поэтому проверка — анализатор, полный прогон и ручная проверка в Task 12.

**Files:**
- Modify: `lib/features/messenger/presentation/screens/chat_room_screen.dart` — импорты (строки 36 и 71), `showForwardPicker` и удаление `_ForwardPickerSheet` (строки ~5240–5473)

- [ ] **Step 1: Импорты**

Заменить строку
```dart
import '../widgets/markdown_color_extension.dart';
```
на
```dart
import '../widgets/markdown_color_extension.dart';
import '../widgets/recipient_picker_list.dart';
```
и удалить строку (после правки `filterRecipients` в файле больше не используется):
```dart
import '../../utils/recipient_filters.dart';
```

- [ ] **Step 2: Заменить `showForwardPicker` и удалить `_ForwardPickerSheet`**

Фрагмент от doc-комментария `/// Показывает выбор беседы и пересылает туда [messageIds].` до строки `class _InputBar extends StatefulWidget {` (не включая её) заменяется целиком:

```bash
python3 - <<'PY'
from pathlib import Path
p = Path('lib/features/messenger/presentation/screens/chat_room_screen.dart')
s = p.read_text(encoding='utf-8')
start = s.index('/// Показывает выбор беседы и пересылает туда [messageIds].')
end = s.index('class _InputBar extends StatefulWidget {')
new = r'''/// Показывает выбор беседы и пересылает туда [messageIds].
///
/// Одна на два вызова — из меню одного сообщения и из мультивыбора: логика
/// «переслать и сразу открыть чат-получатель» должна быть одинаковой, иначе
/// пачка и одиночка ведут себя по-разному без всякой причины.
void showForwardPicker(BuildContext context, List<String> messageIds) {
  if (messageIds.isEmpty) return;
  final bloc = context.read<MessengerBloc>();
  // Снимок на момент открытия, как раньше: лист перестраивается на каждый
  // кадр клавиатуры, и живой список переставлялся бы под пальцем.
  final conversations = bloc.state.conversations;
  final rootContext = context;

  void forwardTo(String convId) {
    bloc.add(ForwardMessages(
      messageIds: messageIds,
      targetConversationId: convId,
    ));
    // Открываем чат-получатель, чтобы пользователь оказался прямо на
    // пересланном и мог дописать сопровождение.
    if (rootContext.mounted) {
      rootContext.push('/dashboard/messenger/$convId');
    }
  }

  showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.of(context).card,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) {
      final colors = AppColors.of(sheetContext);
      return DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, scrollController) => Column(
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colors.textSecondary.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  AppLocalizations.of(sheetContext)!.chatForwardTo,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: RecipientPickerList(
                conversations: conversations,
                scrollController: scrollController,
                onSelected: (conv) {
                  Navigator.pop(sheetContext);
                  forwardTo(conv.id);
                },
                onSelectSaved: () async {
                  Navigator.pop(sheetContext);
                  try {
                    final res = await sl<DioClient>().post(
                      '/messenger/saved',
                      fromJson: (d) => Map<String, dynamic>.from(d as Map),
                    );
                    final convId = res['conversationId'] as String?;
                    if (convId == null) return;
                    forwardTo(convId);
                  } catch (_) {}
                },
              ),
            ),
          ],
        ),
      );
    },
  );
}
'''
p.write_text(s[:start] + new + '\n' + s[end:], encoding='utf-8')
out = p.read_text(encoding='utf-8')
print('_ForwardPickerSheet left:', out.count('_ForwardPickerSheet'))
print('filterRecipients left:', out.count('filterRecipients'))
PY
```

Expected output:
```
_ForwardPickerSheet left: 0
filterRecipients left: 0
```

- [ ] **Step 3: Анализатор по файлу**

```bash
OUT="${TMPDIR:-/tmp}/share-to-chat"
flutter analyze --no-fatal-infos --no-fatal-warnings lib/features/messenger/presentation/screens/chat_room_screen.dart lib/features/messenger/presentation/widgets/recipient_picker_list.dart 2>&1 \
  | grep " • " | grep -E "chat_room_screen|recipient_picker_list" | sed -E 's/:[0-9]+:[0-9]+ / /' | sort > "$OUT/analyze-t5.txt"
comm -13 <(grep -E "chat_room_screen|recipient_picker_list" "$OUT/analyze-before-ours.txt") "$OUT/analyze-t5.txt"
```

Expected: пустой вывод (новых замечаний нет). Ошибок (`error •`) быть не должно вовсе.

- [ ] **Step 4: Полный прогон**

Run: `flutter test`
Expected: `+1620: All tests passed!` (1582 + 38 новых из Task 1–4).

- [ ] **Step 5: Коммит**

```bash
git add lib/features/messenger/presentation/screens/chat_room_screen.dart
git commit -m "refactor(messenger): «Переслать» на общем списке получателей, без дубля «Избранного»" \
  -m "Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>"
```

---

### Task 6: Строки

Шаблон локализации — русский (`l10n.yaml`: `template-arb-locale: ru`). Новые ключи кладутся в `app_ru.arb` и `app_en.arb`; остальные 22 локали `flutter gen-l10n` сам заполняет английским текстом (проверено 2026-10-31). `shareToChat` есть во всех 24 ARB — меняем только ru и en, остальные сохраняют свой перевод «Переслать в чат».

**Files:**
- Modify: `lib/l10n/app_ru.arb`, `lib/l10n/app_en.arb`
- Regenerate: `lib/l10n/app_localizations.dart`, `lib/l10n/app_localizations_*.dart`

- [ ] **Step 1: `app_ru.arb`**

Заменить
```json
  "chatMessageHint": "Сообщение...",
```
на
```json
  "chatMessageHint": "Сообщение...",
  "chatAttachmentCommentHint": "Добавьте комментарий...",
```
и заменить
```json
  "shareToChat": "Переслать в чат",
```
на
```json
  "shareToChat": "Кому отправить",
```

- [ ] **Step 2: `app_en.arb`**

Заменить
```json
  "chatMessageHint": "Message...",
```
на
```json
  "chatMessageHint": "Message...",
  "chatAttachmentCommentHint": "Add a comment...",
```
и заменить
```json
  "shareToChat": "Forward to chat",
```
на
```json
  "shareToChat": "Send to",
```

- [ ] **Step 3: Генерация и проверка**

```bash
flutter gen-l10n
grep -h "get chatAttachmentCommentHint" lib/l10n/app_localizations_{ru,en,de}.dart
grep -h "get shareToChat" lib/l10n/app_localizations_{ru,en,de}.dart
git diff --stat | tail -1
```

Expected:
```
  String get chatAttachmentCommentHint => 'Добавьте комментарий...';
  String get chatAttachmentCommentHint => 'Add a comment...';
  String get chatAttachmentCommentHint => 'Add a comment...';
  String get shareToChat => 'Кому отправить';
  String get shareToChat => 'Send to';
  String get shareToChat => 'An Chat weiterleiten';
 27 files changed, ...
```
(2 ARB + `app_localizations.dart` + 24 `app_localizations_*.dart`.)

- [ ] **Step 4: Полный прогон**

Run: `flutter test`
Expected: `+1620: All tests passed!` — на тексты «Forward to chat» и «Message...» тесты не завязаны (проверено grep'ом).

- [ ] **Step 5: Коммит**

```bash
git add lib/l10n
git commit -m "feat(l10n): «Кому отправить» и подсказка «Добавьте комментарий...»" \
  -m "Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>"
```

---

### Task 7: Чат — файлы ждут комментарий

Виджет-тестов на `ChatRoomScreen` в репозитории нет, а обвязка экрана на 7,6 тыс. строк несоразмерна правке. Разбор share уже покрыт тестами Task 2. То, что файл не уходит сам, проверяется на устройстве (Task 12 и 13).

**Files:**
- Modify: `lib/features/messenger/presentation/screens/chat_room_screen.dart` — импорт (строка 57), `_addSharedFiles` (~1148–1200), `_InputBar` и два места его создания (~2331 и ~3588)

- [ ] **Step 1: Импорт**

Заменить строку
```dart
import '../../utils/voice_meta.dart';
```
на
```dart
import '../../utils/voice_meta.dart';
import '../../utils/shared_items.dart';
```

- [ ] **Step 2: `_addSharedFiles` без автоотправки**

```bash
python3 - <<'PY'
from pathlib import Path
p = Path('lib/features/messenger/presentation/screens/chat_room_screen.dart')
s = p.read_text(encoding='utf-8')
start = s.index('  void _addSharedFiles(List sharedFiles) {')
end = s.index('  Future<void> _pickFile() async {')
new = r'''  void _addSharedFiles(List sharedFiles) {
    final shared =
        splitSharedItems(sharedFiles.whereType<SharedMediaFile>().toList());
    if (shared.attachments.isEmpty && shared.text.isEmpty) return;
    setState(() {
      for (final a in shared.attachments) {
        _pendingFiles.add(_PendingFile(path: a.path, name: a.name, type: a.type));
      }
      if (shared.text.isNotEmpty) {
        // Keep the draft the user already had; shared text goes on a new line.
        final existing = _ctrl.text;
        _ctrl.text =
            existing.isEmpty ? shared.text : '$existing\n${shared.text}';
        _ctrl.selection = TextSelection.collapsed(offset: _ctrl.text.length);
      }
    });
    // Nothing is sent from here: the files wait in the strip above the input
    // so a comment can be written first, and go with the Send button like any
    // attachment. Until 2026-10-31 they uploaded the moment the chat opened,
    // and there was no way to add a comment.
  }

'''
p.write_text(s[:start] + new + s[end:], encoding='utf-8')
out = p.read_text(encoding='utf-8')
body = out[out.index('  void _addSharedFiles(List sharedFiles) {'):out.index('  Future<void> _pickFile() async {')]
print('auto-send left in _addSharedFiles:', body.count('_sendPendingAttachment'))
PY
```

Expected: `auto-send left in _addSharedFiles: 0`

- [ ] **Step 3: Подсказка поля ввода**

```bash
python3 - <<'PY'
import re
from pathlib import Path
p = Path('lib/features/messenger/presentation/screens/chat_room_screen.dart')
s = p.read_text(encoding='utf-8')
cls = s.index('class _InputBar extends StatefulWidget {')
head, tail = s[:cls], s[cls:]
tail = tail.replace(
    '  final VoidCallback? onVideoRecordStop;\n',
    '  final VoidCallback? onVideoRecordStop;\n'
    '  /// Подсказка в пустом поле; null — обычная «Сообщение...».\n'
    '  final String? hintText;\n', 1)
tail = tail.replace(
    '    this.onVideoRecordStop,\n  });',
    '    this.onVideoRecordStop,\n    this.hintText,\n  });', 1)
tail = tail.replace(
    'hintText: AppLocalizations.of(context)!.chatMessageHint,',
    'hintText: widget.hintText ?? AppLocalizations.of(context)!.chatMessageHint,', 1)
s = head + tail
pattern = re.compile(
    r'^( *)onSend: _pendingFiles\.isNotEmpty \? _sendPendingAttachment : _sendMessage,\n',
    re.M)
def add_hint(m):
    ind = m.group(1)
    return (m.group(0)
            + f'{ind}hintText: _pendingFiles.isNotEmpty\n'
            + f'{ind}    ? AppLocalizations.of(context)!.chatAttachmentCommentHint\n'
            + f'{ind}    : null,\n')
s, n = pattern.subn(add_hint, s)
assert n == 2, f'expected 2 _InputBar call sites, got {n}'
p.write_text(s, encoding='utf-8')
print('call sites:', n)
print('field:', s.count('  final String? hintText;'), 'ctor:', s.count('    this.hintText,'),
      'used:', s.count('widget.hintText ?? AppLocalizations.of(context)!.chatMessageHint'))
PY
```

Expected:
```
call sites: 2
field: 1 ctor: 1 used: 1
```

Если `field`/`ctor` больше 1 — у другого виджета в файле нашлось такое же поле; откатить (`git checkout -- <файл>`) и вставить параметр в `_InputBar` вручную.

- [ ] **Step 4: Анализатор и прогон**

```bash
OUT="${TMPDIR:-/tmp}/share-to-chat"
flutter analyze --no-fatal-infos --no-fatal-warnings lib/features/messenger/presentation/screens/chat_room_screen.dart 2>&1 \
  | grep " • " | grep chat_room_screen | sed -E 's/:[0-9]+:[0-9]+ / /' | sort > "$OUT/analyze-t7.txt"
comm -13 <(grep chat_room_screen "$OUT/analyze-before-ours.txt") "$OUT/analyze-t7.txt"
flutter test
```

Expected: `comm` ничего не выводит; `+1620: All tests passed!`

- [ ] **Step 5: Коммит**

```bash
git add lib/features/messenger/presentation/screens/chat_room_screen.dart
git commit -m "feat(messenger): файлы из «Поделиться» ждут комментарий, а не уходят сами" \
  -m "Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>"
```

---

### Task 8: Экран «Кому отправить»

До Task 10 экран всё ещё открывается старым путём (дашборд кладёт его через `Navigator.push`). Новый код работает в обоих случаях: `context.go` в чат и `context.pop` по крестику.

**Files:**
- Modify (переписать целиком): `lib/features/messenger/presentation/screens/share_target_screen.dart`
- Test: `test/features/messenger/presentation/screens/share_target_screen_test.dart`

- [ ] **Step 1: Падающий тест**

```dart
// test/features/messenger/presentation/screens/share_target_screen_test.dart
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:taler_id_mobile/core/di/service_locator.dart';
import 'package:taler_id_mobile/core/storage/saved_conversation_id_cache.dart';
import 'package:taler_id_mobile/core/theme/app_theme.dart';
import 'package:taler_id_mobile/features/messenger/domain/entities/conversation_entity.dart';
import 'package:taler_id_mobile/features/messenger/domain/repositories/i_messenger_repository.dart';
import 'package:taler_id_mobile/features/messenger/presentation/bloc/messenger_bloc.dart';
import 'package:taler_id_mobile/features/messenger/presentation/bloc/messenger_event.dart';
import 'package:taler_id_mobile/features/messenger/presentation/bloc/messenger_state.dart';
import 'package:taler_id_mobile/features/messenger/presentation/screens/share_target_screen.dart';
import 'package:taler_id_mobile/l10n/app_localizations.dart';

class _MockMessengerBloc extends MockBloc<MessengerEvent, MessengerState>
    implements MessengerBloc {}

class _MockRepo extends Mock implements IMessengerRepository {}

class _MockCache extends Mock implements SavedConversationIdCache {}

final _files = [
  SharedMediaFile(
      path: '/data/user/0/app/cache/Отчёт.pdf', type: SharedMediaType.file),
];

ConversationEntity _conv(String id, String type,
        {String? name, String? otherUserName}) =>
    ConversationEntity(
      id: id,
      participantIds: const [],
      type: type,
      name: name,
      otherUserName: otherUserName,
    );

void main() {
  late _MockMessengerBloc bloc;
  late _MockRepo repo;
  late _MockCache cache;
  String? openedChat;
  Object? openedExtra;

  setUpAll(() {
    registerFallbackValue<MessengerEvent>(LoadConversations());
  });

  setUp(() async {
    await sl.reset();
    bloc = _MockMessengerBloc();
    repo = _MockRepo();
    cache = _MockCache();
    sl.registerSingleton<IMessengerRepository>(repo);
    sl.registerSingleton<SavedConversationIdCache>(cache);
    openedChat = null;
    openedExtra = null;
    when(() => bloc.state).thenReturn(MessengerState(conversations: [
      _conv('c-anna', 'DIRECT', otherUserName: 'Anna Ivanova'),
      _conv('c-team', 'GROUP', name: 'Taler team'),
    ]));
    when(() => bloc.stream).thenAnswer((_) => const Stream.empty());
  });

  tearDown(() => sl.reset());

  Future<void> pumpScreen(WidgetTester tester, {bool settle = true}) async {
    final router = GoRouter(
      initialLocation: '/dashboard/messenger/share',
      routes: [
        GoRoute(
          path: '/dashboard/messenger',
          builder: (_, __) => const Scaffold(body: Text('chat list')),
          routes: [
            GoRoute(
              path: 'share',
              builder: (_, __) => ShareTargetScreen(sharedFiles: _files),
            ),
            GoRoute(
              path: ':id',
              builder: (_, state) {
                openedChat = state.pathParameters['id'];
                openedExtra = state.extra;
                return Scaffold(
                    body: Text('chat ${state.pathParameters['id']}'));
              },
            ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(BlocProvider<MessengerBloc>.value(
      value: bloc,
      child: MaterialApp.router(
        routerConfig: router,
        theme: AppTheme.dark,
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    ));
    if (settle) {
      await tester.pumpAndSettle();
    } else {
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  testWidgets('shows the file and the chats under "Send to"', (tester) async {
    await pumpScreen(tester);
    expect(find.text('Send to'), findsOneWidget);
    expect(find.text('Отчёт.pdf'), findsOneWidget);
    expect(find.text('Favorites'), findsOneWidget);
    expect(find.text('Anna Ivanova'), findsOneWidget);
    expect(find.text('Taler team'), findsOneWidget);
    verify(() => bloc.add(any(that: isA<LoadConversations>()))).called(1);
  });

  testWidgets('search narrows the list', (tester) async {
    await pumpScreen(tester);
    await tester.enterText(find.byType(TextField), 'team');
    await tester.pump();
    expect(find.text('Taler team'), findsOneWidget);
    expect(find.text('Anna Ivanova'), findsNothing);
  });

  testWidgets('picking a chat opens it with the files and sends nothing',
      (tester) async {
    await pumpScreen(tester);
    await tester.tap(find.text('Anna Ivanova'));
    await tester.pumpAndSettle();
    expect(find.text('chat c-anna'), findsOneWidget);
    expect(openedChat, 'c-anna');
    expect((openedExtra as Map)['sharedFiles'], same(_files));
    verifyNever(() => bloc.add(any(that: isA<SendMessage>())));
  });

  testWidgets('Favorites asks the server once and remembers the id',
      (tester) async {
    when(() => cache.read()).thenAnswer((_) async => null);
    when(() => repo.getOrCreateSavedConversation())
        .thenAnswer((_) async => 'c-saved');
    when(() => cache.write(any())).thenAnswer((_) async {});
    await pumpScreen(tester);
    await tester.tap(find.text('Favorites'));
    await tester.pumpAndSettle();
    expect(openedChat, 'c-saved');
    expect((openedExtra as Map)['sharedFiles'], same(_files));
    verify(() => cache.write('c-saved')).called(1);
  });

  testWidgets('Favorites failing shows an error and keeps the picker',
      (tester) async {
    when(() => cache.read()).thenAnswer((_) async => null);
    when(() => repo.getOrCreateSavedConversation())
        .thenThrow(Exception('offline'));
    await pumpScreen(tester);
    await tester.tap(find.text('Favorites'));
    await tester.pumpAndSettle();
    expect(find.text("Couldn't open Saved Messages"), findsOneWidget);
    expect(find.text('Send to'), findsOneWidget);
    expect(openedChat, isNull);
  });

  testWidgets('the cross returns to the chat list', (tester) async {
    await pumpScreen(tester);
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();
    expect(find.text('chat list'), findsOneWidget);
  });

  testWidgets('while conversations load: a spinner, not "No chats"',
      (tester) async {
    when(() => bloc.state).thenReturn(const MessengerState(isLoading: true));
    await pumpScreen(tester, settle: false);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('No chats'), findsNothing);
  });
}
```

- [ ] **Step 2: Убедиться, что падает**

Run: `flutter test test/features/messenger/presentation/screens/share_target_screen_test.dart`
Expected: FAIL. Как минимум не найдутся «Favorites» и спиннер, «Избранное» не открывается, а нажатие на чат уводит через `Navigator.of(context, rootNavigator: true).pop()`.

- [ ] **Step 3: Новый экран**

Переписать `lib/features/messenger/presentation/screens/share_target_screen.dart` целиком:

```dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import '../../../../core/api/dio_client.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/storage/saved_conversation_id_cache.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/constants.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/conversation_entity.dart';
import '../../domain/repositories/i_messenger_repository.dart';
import '../bloc/messenger_bloc.dart';
import '../bloc/messenger_event.dart';
import '../bloc/messenger_state.dart';
import '../widgets/recipient_picker_list.dart';

/// "Send to": where files shared from another app go.
///
/// Opens over the chat list (`/dashboard/messenger/share`), so closing it
/// leaves the user in Messenger. The chosen chat opens with the files waiting
/// in its attachment strip — nothing is sent from here, the comment is
/// written in the chat itself.
class ShareTargetScreen extends StatefulWidget {
  final List<SharedMediaFile> sharedFiles;
  const ShareTargetScreen({super.key, required this.sharedFiles});

  @override
  State<ShareTargetScreen> createState() => _ShareTargetScreenState();
}

class _ShareTargetScreenState extends State<ShareTargetScreen> {
  bool _openingSaved = false;

  @override
  void initState() {
    super.initState();
    context.read<MessengerBloc>().add(LoadConversations());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.of(context).background,
      appBar: AppBar(
        title: Text(l10n.shareToChat),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: _close,
        ),
      ),
      body: Column(
        children: [
          // Preview of shared files
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.of(context).card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.of(context).border),
            ),
            child: Row(
              children: [
                _buildPreview(),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _getDescription(),
                    style: TextStyle(
                      color: AppColors.of(context).textSecondary,
                      fontSize: 13,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: BlocBuilder<MessengerBloc, MessengerState>(
              // Only what the list shows: the bloc emits for every message,
              // typing indicator and call event.
              buildWhen: (prev, curr) =>
                  prev.conversations != curr.conversations ||
                  prev.isLoading != curr.isLoading,
              builder: (context, state) => RecipientPickerList(
                conversations: state.conversations,
                loading: state.isLoading,
                onSelected: _select,
                onSelectSaved: _openSaved,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _close() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(RouteConstants.messenger);
    }
  }

  Widget _buildPreview() {
    final file = widget.sharedFiles.first;
    final path = file.path;

    if (file.type == SharedMediaType.image && path.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.file(
          File(path),
          width: 48,
          height: 48,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _fileIcon(),
        ),
      );
    }
    if (file.type == SharedMediaType.video) {
      return Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.of(context).primary.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(Icons.videocam, color: AppColors.of(context).primary),
      );
    }
    return _fileIcon();
  }

  Widget _fileIcon() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.of(context).primary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(Icons.attach_file, color: AppColors.of(context).primary),
    );
  }

  String _getDescription() {
    final count = widget.sharedFiles.length;
    if (count == 1) {
      final file = widget.sharedFiles.first;
      final name = file.path.split('/').last;
      return name;
    }
    return AppLocalizations.of(context)!.shareFilesCount(count);
  }

  void _select(ConversationEntity conv) {
    // A group with topics asks for the topic first.
    if (conv.topicsEnabled) {
      _showTopicPicker(conv);
      return;
    }
    _openChat(conv.id);
  }

  /// Favorites the way the chat list opens it: the remembered id, else ask
  /// the server and remember the answer.
  Future<void> _openSaved() async {
    if (_openingSaved) return;
    _openingSaved = true;
    try {
      final cache = sl<SavedConversationIdCache>();
      var convId = await cache.read();
      if (convId == null) {
        convId =
            await sl<IMessengerRepository>().getOrCreateSavedConversation();
        await cache.write(convId);
      }
      if (!mounted) return;
      _openChat(convId);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.savedOpenError)),
      );
    } finally {
      _openingSaved = false;
    }
  }

  Future<void> _showTopicPicker(ConversationEntity conv) async {
    try {
      final client = sl<DioClient>();
      final topics = await client.get<List<dynamic>>(
        '/messenger/conversations/${conv.id}/topics',
        fromJson: (d) => d as List<dynamic>,
      );
      if (!mounted) return;

      final topicList = topics
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();

      if (topicList.isEmpty) {
        // No topics — send to general
        _openChat(conv.id);
        return;
      }

      // Show bottom sheet with topics
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (ctx) => Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.of(context).card,
            borderRadius: BorderRadius.circular(20),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                Container(width: 36, height: 4, decoration: BoxDecoration(color: AppColors.of(context).textSecondary.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(2))),
                const SizedBox(height: 16),
                Text(AppLocalizations.of(context)!.shareSelectChat, style: TextStyle(color: AppColors.of(context).textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                ...topicList.map((t) {
                  final icon = t['icon'] as String? ?? '💬';
                  final title = t['title'] as String? ?? '';
                  final id = t['id'] as String? ?? '';
                  return ListTile(
                    leading: Text(icon, style: const TextStyle(fontSize: 24)),
                    title: Text(title, style: TextStyle(color: AppColors.of(context).textPrimary, fontWeight: FontWeight.w600)),
                    trailing: Icon(Icons.send_rounded, color: AppColors.of(context).primary, size: 20),
                    onTap: () {
                      Navigator.pop(ctx);
                      _openChat(conv.id, topicId: id, topicTitle: title);
                    },
                  );
                }),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      );
    } catch (_) {
      // Fallback — send without topic
      _openChat(conv.id);
    }
  }

  /// The chat replaces the picker and the chat list stays beneath it. The
  /// files land in the chat's attachment strip and go only with Send.
  void _openChat(String convId, {String? topicId, String? topicTitle}) {
    context.go('/dashboard/messenger/$convId', extra: {
      'sharedFiles': widget.sharedFiles,
      if (topicId != null) 'topicId': topicId,
      if (topicTitle != null) 'topicTitle': topicTitle,
    });
  }
}
```

- [ ] **Step 4: Тест проходит**

Run: `flutter test test/features/messenger/presentation/screens/share_target_screen_test.dart`
Expected: `+7: All tests passed!`

- [ ] **Step 5: Полный прогон**

Run: `flutter test`
Expected: `+1627: All tests passed!`

- [ ] **Step 6: Коммит**

```bash
git add lib/features/messenger/presentation/screens/share_target_screen.dart test/features/messenger/presentation/screens/share_target_screen_test.dart
git commit -m "feat(share): «Кому отправить» — поиск, «Избранное», чат открывается с файлами" \
  -m "Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>"
```

---

### Task 9: Маршрут внутри «Сообщений»

**Files:**
- Modify: `lib/core/router/app_router.dart` — импорт (после строки 70), маршруты «Сообщений» (~428), удаление `/share-target` (~252–258)

- [ ] **Step 1: Импорт**

Заменить
```dart
import '../utils/constants.dart';
```
на
```dart
import '../utils/constants.dart';
import 'share_picker_gate.dart';
```

- [ ] **Step 2: Маршрут `share`**

Заменить
```dart
            GoRoute(
              path: 'search',
              builder: (_, __) => const UserSearchScreen(),
            ),
```
на
```dart
            // «Поделиться» из другого приложения: выбор получателя поверх
            // списка чатов, крестик возвращает в список. До ':id', иначе
            // 'share' разберётся как id беседы.
            GoRoute(
              path: 'share',
              redirect: (_, state) => sharePickerRedirect(state.extra),
              builder: (_, state) => ShareTargetScreen(
                sharedFiles: state.extra as List<SharedMediaFile>,
              ),
            ),
            GoRoute(
              path: 'search',
              builder: (_, __) => const UserSearchScreen(),
            ),
```

- [ ] **Step 3: Удалить `/share-target`**

Удалить блок целиком:
```dart
    // Share-in recipient picker (full-screen, outside shell)
    GoRoute(
      path: '/share-target',
      builder: (context, state) {
        final files = (state.extra as List?)?.cast<SharedMediaFile>() ?? const <SharedMediaFile>[];
        return ShareTargetScreen(sharedFiles: files);
      },
    ),
```

Проверка: `grep -n "share-target\|path: 'share'" lib/core/router/app_router.dart` → одна строка `path: 'share',`.

- [ ] **Step 4: Анализатор и прогон**

```bash
OUT="${TMPDIR:-/tmp}/share-to-chat"
flutter analyze --no-fatal-infos --no-fatal-warnings lib/core/router 2>&1 \
  | grep " • " | grep -E "app_router|share_picker_gate" | sed -E 's/:[0-9]+:[0-9]+ / /' | sort > "$OUT/analyze-t9.txt"
comm -13 <(grep -E "app_router|share_picker_gate" "$OUT/analyze-before-ours.txt") "$OUT/analyze-t9.txt"
flutter test
```

Expected: `comm` ничего не выводит; `+1627: All tests passed!`

- [ ] **Step 5: Коммит**

```bash
git add lib/core/router/app_router.dart
git commit -m "feat(router): выбор получателя — маршрут внутри «Сообщений» вместо /share-target" \
  -m "Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>"
```

---

### Task 10: Ячейка в сервисе, дашборд открывает выбор

API сервиса и его единственный потребитель меняются одним коммитом. Автотеста на дашборд нет: экран тянет за собой десяток сервисов. Логика сведена к уже проверенным частям: ячейка (Task 1) и `canOpenSharePicker` (Task 3). Поведение целиком проверяется на устройстве (Task 12).

**Files:**
- Modify (переписать целиком): `lib/core/services/share_intent_service.dart`
- Modify: `lib/features/dashboard/presentation/dashboard_screen.dart` — импорты (строки 24, 28), поле (58), конец стартовой цепочки (245), `dispose` (674), `_listenForShareIntent` (688–723)

- [ ] **Step 1: `ShareIntentService` на ячейке**

Переписать `lib/core/services/share_intent_service.dart` целиком:

```dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

import '../router/deep_link_handler.dart';
import 'pending_share.dart';

class ShareIntentService {
  static final ShareIntentService instance = ShareIntentService._();
  ShareIntentService._();

  /// Drops entries that are really one of our own deep links.
  ///
  /// The plugin reads the launching intent, and an App Link arrives as a VIEW
  /// intent carrying an https URI — which it offers up as shared content. So a
  /// room invite or a "sign in with Taler ID" link opened the "forward to chat"
  /// sheet with the URL as an attachment instead of the screen it addresses
  /// (2026-08-03). Those belong to DeepLinkHandler, which is asked here rather
  /// than duplicating the host list.
  @visibleForTesting
  static List<SharedMediaFile> withoutDeepLinks(List<SharedMediaFile> files) {
    return files.where((f) {
      final uri = Uri.tryParse(f.path);
      if (uri == null || !uri.hasScheme) return true;
      return DeepLinkHandler.resolve(uri) == null;
    }).toList(growable: false);
  }

  final _pending = PendingShare();

  /// The share waiting for the recipient picker; null when there is none.
  /// The dashboard listens and takes it once it can show the picker.
  ValueListenable<List<SharedMediaFile>?> get pending => _pending.files;

  StreamSubscription? _sub;

  void init() {
    // Shared while the app was running.
    _sub = ReceiveSharingIntent.instance
        .getMediaStream()
        .listen((raw) => _offer(raw, 'while running'));
    // Shared into a closed app.
    ReceiveSharingIntent.instance
        .getInitialMedia()
        .then((raw) => _offer(raw, 'at launch'));
  }

  void _offer(List<SharedMediaFile> raw, String when) {
    final files = withoutDeepLinks(raw);
    if (files.isEmpty) return;
    debugPrint('[ShareIntent] Received ${files.length} files $when');
    _pending.offer(files);
  }

  /// Hands the pending share out once and drops the plugin's copy, so a
  /// restarted engine does not deliver the same files again.
  List<SharedMediaFile>? take() {
    final files = _pending.take();
    if (files != null) ReceiveSharingIntent.instance.reset();
    return files;
  }

  void dispose() {
    _sub?.cancel();
  }
}
```

- [ ] **Step 2: Импорты дашборда**

Удалить строку
```dart
import '../../messenger/presentation/screens/share_target_screen.dart';
```
Заменить
```dart
import '../../../core/services/share_intent_service.dart';
```
на
```dart
import '../../../core/services/share_intent_service.dart';
import '../../../core/router/share_picker_gate.dart';
```

- [ ] **Step 3: Поле**

Заменить
```dart
  StreamSubscription? _shareIntentSub;
```
на
```dart
  GoRouter? _router; // listened to for the share picker, see _listenForShareIntent
  bool _shareCheckQueued = false;
```

- [ ] **Step 4: `dispose`**

Заменить
```dart
    _shareIntentSub?.cancel();
```
на
```dart
    ShareIntentService.instance.pending.removeListener(_queueSharePickerCheck);
    _router?.routerDelegate.removeListener(_queueSharePickerCheck);
```

- [ ] **Step 5: Первая проверка — в конце стартовой цепочки**

Не раньше: общий `redirect` роутера асинхронный, и `go` к выбору, запрошенный до того, как отработал `push` к звонку, перебил бы экран звонка. Если старт ушёл в звонок (ранние `return` выше), share подхватит слушатель смены маршрута, когда звонок свернут или завершат.

Заменить
```dart
      _startWakeWord();
    });
  }

  /// Startup work every launch needs, regardless of what the app was opened for.
```
на
```dart
      _startWakeWord();
      // A share that arrived before the dashboard existed (login, PIN) is
      // waiting. Checked only now, after the call branches above: the global
      // redirect is async, so a `go` to the picker issued earlier could win
      // over the call screen being pushed. When startup went into a call, the
      // route listener picks the share up once the call is minimised or over.
      _queueSharePickerCheck();
    });
  }

  /// Startup work every launch needs, regardless of what the app was opened for.
```

- [ ] **Step 6: Заменить `_listenForShareIntent`**

```bash
python3 - <<'PY'
from pathlib import Path
p = Path('lib/features/dashboard/presentation/dashboard_screen.dart')
s = p.read_text(encoding='utf-8')
start = s.index('  void _listenForShareIntent() {')
end = s.index('  void _startWakeWord() {')
new = r'''  void _listenForShareIntent() {
    // A share from another app waits in ShareIntentService until the picker
    // can be shown: it may arrive before the dashboard exists (login, PIN) or
    // while a call screen is open. The share arriving and every route change
    // both re-check, so the picker opens as soon as both allow — and once.
    final router = GoRouter.of(context);
    _router = router;
    ShareIntentService.instance.pending.addListener(_queueSharePickerCheck);
    router.routerDelegate.addListener(_queueSharePickerCheck);
  }

  void _queueSharePickerCheck() {
    if (_shareCheckQueued) return;
    _shareCheckQueued = true;
    // After the notification that called us: navigating from inside a router
    // listener would re-enter the router mid-update.
    Future.microtask(() {
      _shareCheckQueued = false;
      _maybeOpenSharePicker();
    });
  }

  void _maybeOpenSharePicker() {
    final router = _router;
    if (!mounted || router == null) return;
    if (ShareIntentService.instance.pending.value == null) return;
    // The whole stack, not currentConfiguration.uri: that one only follows
    // `go`, and most call screens are pushed (see stackLocations).
    if (!canOpenSharePicker(
        stackLocations(router.routerDelegate.currentConfiguration))) {
      return;
    }
    final files = ShareIntentService.instance.take();
    if (files == null) return;
    debugPrint('[Dashboard] Opening the share picker for ${files.length} files');
    router.go(RouteConstants.messengerShare, extra: files);
  }

'''
p.write_text(s[:start] + new + s[end:], encoding='utf-8')
out = p.read_text(encoding='utf-8')
for needle in ('_shareIntentSub', 'pendingFilesStream', 'initialFiles', 'clearFiles', 'ShareTargetScreen'):
    print(needle, out.count(needle))
PY
```

Expected:
```
_shareIntentSub 0
pendingFilesStream 0
initialFiles 0
clearFiles 0
ShareTargetScreen 0
```

- [ ] **Step 7: Старый API нигде не остался**

Run: `grep -rn "pendingFilesStream\|\.initialFiles\|clearFiles()" lib test`
Expected: пусто.

- [ ] **Step 8: Анализатор и прогон**

```bash
OUT="${TMPDIR:-/tmp}/share-to-chat"
flutter analyze --no-fatal-infos --no-fatal-warnings lib/core/services lib/features/dashboard 2>&1 \
  | grep " • " | grep -E "share_intent_service|pending_share|dashboard_screen" | sed -E 's/:[0-9]+:[0-9]+ / /' | sort > "$OUT/analyze-t10.txt"
comm -13 <(grep -E "share_intent_service|pending_share|dashboard_screen" "$OUT/analyze-before-ours.txt") "$OUT/analyze-t10.txt"
flutter test
```

Expected: `comm` ничего не выводит; `+1627: All tests passed!`

- [ ] **Step 9: Коммит**

```bash
git add lib/core/services/share_intent_service.dart lib/features/dashboard/presentation/dashboard_screen.dart
git commit -m "feat(share): выбор получателя открывается в «Сообщениях» ровно один раз" \
  -m "Ячейка вместо потока, копии холодного старта и опроса через 0,5/1,5/3 с. Не поверх звонка: share ждёт, пока звонок свернут или завершат." \
  -m "Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>"
```

---

### Task 11: Общая проверка

**Files:** нет изменений.

- [ ] **Step 1: Все тесты**

Run: `flutter test`
Expected: `+1627: All tests passed!` (1582 + 7 + 10 + 6 + 15 + 7).

Если итог не 1627, но всё зелёное, сверить, какие тесты добавились: `git diff 2f68fc0 --stat -- test`.

- [ ] **Step 2: Новых замечаний анализатора нет**

```bash
OUT="${TMPDIR:-/tmp}/share-to-chat"
flutter analyze --no-fatal-infos --no-fatal-warnings > "$OUT/analyze-after.txt" 2>&1
grep -E "share_intent_service|pending_share|share_picker_gate|shared_items|recipient_picker_list|share_target_screen|chat_room_screen|dashboard_screen|app_router|core/utils/constants" "$OUT/analyze-after.txt" \
  | sed -E 's/:[0-9]+:[0-9]+ / /' | sort > "$OUT/analyze-after-ours.txt"
echo "new:"; comm -13 "$OUT/analyze-before-ours.txt" "$OUT/analyze-after-ours.txt"
echo "gone:"; comm -23 "$OUT/analyze-before-ours.txt" "$OUT/analyze-after-ours.txt"
grep -c " error •" "$OUT/analyze-after.txt"
```

Expected: после `new:` пусто; число ошибок не больше, чем в `analyze-before.txt` (`grep -c " error •" "$OUT/analyze-before.txt"`).

- [ ] **Step 3: Сборка dev-APK**

```bash
flutter build apk --flavor dev --release -t lib/main_dev.dart \
  --dart-define=FLAVOR=dev --dart-define=BASE_URL=https://staging.id.taler.tirol
ls -la build/app/outputs/flutter-apk/app-dev-release.apk
```

Expected: `✓ Built build/app/outputs/flutter-apk/app-dev-release.apk`. Release, а не debug: debug-сборка вешает эмулятор, ей нужно 715 МБ против 249.

---

### Task 12: Android — проверка на эмуляторе

**Files:** нет изменений. Доказательства — скриншоты в `$OUT`. Каждый смотреть глазами (Read по пути PNG), а не считать, что раз команда прошла, то и экран правильный.

- [ ] **Step 1: Эмулятор и установка**

```bash
cd ~/Downloads/taler_id_mobile/.worktrees/share-to-chat
ADB=~/Library/Android/sdk/platform-tools/adb; PKG=tirol.taler.taler_id_mobile.dev
flutter emulators --launch Pixel_XL_API_33; sleep 20; $ADB devices   # emulator-5554  device
# Локальная сборка подписана ключом мака, а не aeza: поверх установленной не встанет.
$ADB -s emulator-5554 uninstall $PKG
$ADB -s emulator-5554 install build/app/outputs/flutter-apk/app-dev-release.apk
```

Войти в приложение под `integration_test@taler-test.com` / `IntegrationTest123!` (PIN не включать до шага 7).

- [ ] **Step 2: Тестовый PDF**

```bash
ADB=~/Library/Android/sdk/platform-tools/adb
OUT="${TMPDIR:-/tmp}/share-to-chat"; mkdir -p "$OUT"
/usr/sbin/cupsfilter -i text/plain -m application/pdf docs/superpowers/specs/2026-10-31-share-to-chat-design.md > "$OUT/share-test.pdf" 2>/dev/null
file "$OUT/share-test.pdf"   # PDF document
$ADB -s emulator-5554 push "$OUT/share-test.pdf" /sdcard/Download/share-test.pdf
```

- [ ] **Step 3: Тёплый старт, PDF, комментарий**

Приложение открыто на главном экране (ассистент). В эмуляторе: «Файлы» → Downloads → долгое нажатие на `share-test.pdf` → «Поделиться» → «DEV Taler ID».

```bash
ADB=~/Library/Android/sdk/platform-tools/adb; OUT="${TMPDIR:-/tmp}/share-to-chat"
$ADB -s emulator-5554 exec-out screencap -p > "$OUT/a1-picker.png"
```

Ожидание на `a1-picker.png`: «Кому отправить», плашка `share-test.pdf`, поиск, «Избранное» сверху, чаты. Дальше:
1. Ввести в поиск часть имени `integration_test_2` — список сужается, «Избранное» пропадает.
2. Нажать на чат с `integration_test_2`. Скриншот `a2-chat.png`: в полосе над полем ввода «1 файл» и `share-test.pdf`, в поле подсказка «Добавьте комментарий...», **в ленте нового сообщения нет**.
3. Ввести «тест комментария» и нажать «Отправить». Скриншот `a3-sent.png`: в ленте файл с подписью «тест комментария».
4. «Назад» из чата ведёт в список чатов, а не во второй экран выбора.

- [ ] **Step 4: Холодный старт**

```bash
ADB=~/Library/Android/sdk/platform-tools/adb; PKG=tirol.taler.taler_id_mobile.dev
$ADB -s emulator-5554 shell am force-stop $PKG
```

Повторить «Поделиться» из «Файлов». Ожидание: после заставки сразу «Кому отправить», **один раз**. Выбрать чат: в нём файл ждёт в полосе. Нажать «Назад»: список чатов, второй экран выбора не всплывает (ждать 5 с). Скриншоты `b1-picker.png`, `b2-back.png`.

- [ ] **Step 5: Крестик, несколько файлов, ссылка**

1. «Поделиться» PDF → на «Кому отправить» нажать крестик. Ожидание: список чатов («Сообщения»), а не ассистент.
2. В «Галерее» выбрать три фото → «Поделиться» → «DEV Taler ID» → чат. Ожидание: в полосе 3 миниатюры. Комментарий уходит подписью к первому фото.
3. Ссылка:
   ```bash
   ADB=~/Library/Android/sdk/platform-tools/adb; PKG=tirol.taler.taler_id_mobile.dev
   $ADB -s emulator-5554 shell am start -a android.intent.action.SEND -t text/plain \
     --es android.intent.extra.TEXT 'https://example.com/share-test' -p $PKG
   ```
   Выбрать «Избранное». Ожидание: открыто «Избранное», ссылка стоит в поле ввода, вложений нет, ничего не отправлено.
4. Второй «Поделиться» при открытом выборе: отправить ссылку командой из п. 3, на «Кому отправить» ничего не выбирать и отправить ещё одну, с `--es android.intent.extra.TEXT 'https://example.com/second'`. Ожидание: остаётся один экран выбора, теперь со второй ссылкой. «Назад» ведёт в список чатов, а не к первой.

- [ ] **Step 6: Во время звонка**

1. Позвонить из чата `integration_test_2`. Пока идёт вызов (экран звонка открыт), отправить ссылку командой из шага 5.3. Ожидание: экран звонка остаётся на месте.
2. Завершить вызов. Ожидание: сразу открывается «Кому отправить» с этой ссылкой.

- [ ] **Step 7: С PIN**

Настройки → включить PIN. Затем:
```bash
ADB=~/Library/Android/sdk/platform-tools/adb; PKG=tirol.taler.taler_id_mobile.dev
$ADB -s emulator-5554 shell am force-stop $PKG
```
«Поделиться» PDF из «Файлов». Ожидание: экран PIN; после ввода — сразу «Кому отправить», один раз. После проверки PIN выключить.

- [ ] **Step 8: «Переслать» не сломалось**

В любом чате долгое нажатие на сообщение → «Переслать». Ожидание: лист «Переслать в...», поиск, «Избранное» один раз сверху. Пересылка в другой чат открывает его, сообщение там.

Если какой-то сценарий не сходится с ожиданием — superpowers:systematic-debugging, исправление отдельным коммитом с тестом там, где это возможно, затем повтор Task 11 и этой задачи.

---

### Task 13: iPhone

Нужен iPhone на руках, делается вместе с пользователем. Устройство Дмитрия — `00008101-000E21100202001E`.

**Files:** нет изменений.

- [ ] **Step 1: dev-бандл**

```bash
cd ~/Downloads/taler_id_mobile/.worktrees/share-to-chat
flutter run --release --flavor dev -t lib/main_dev.dart --dart-define=FLAVOR=dev \
  --dart-define=BASE_URL=https://staging.id.taler.tirol -d 00008101-000E21100202001E
```

Сценарии шагов 3–6 из Task 12, только через «Файлы», «Фото» и Safari. В шторке iOS расширение у всех бандлов подписано «Taler ID» (`CFBundleDisplayName` расширения), так что отличить dev можно только по тому, какое приложение откроется. Холодный старт — смахнуть приложение из переключателя перед «Поделиться».

- [ ] **Step 2: Группа приложений у `io.talerid.app`**

Все три бандла используют одну группу `group.tirol.taler.talerIdMobile`. Если её нет в профиле `io.talerid.app`, расширение не сможет передать файл приложению. Собрать talerid и проверить подписанные права приложения и расширения:

```bash
cd ~/Downloads/taler_id_mobile/.worktrees/share-to-chat
flutter build ios --release --flavor talerid --dart-define=BASE_URL=https://api.talerid.io \
  --dart-define=WEB_URL=https://talerid.io --dart-define=TALERID_PUBLIC=true
codesign -d --entitlements :- build/ios/iphoneos/Runner.app 2>/dev/null | grep -A3 application-groups
codesign -d --entitlements :- build/ios/iphoneos/Runner.app/PlugIns/ShareExtension.appex 2>/dev/null | grep -A3 application-groups
```

Expected: в обоих выводах `group.tirol.taler.talerIdMobile`.

Если локальная подпись talerid не проходит (Xcode-аккаунт GsmSoft залогинен на маке Александра, а не обязательно здесь), сделать эту проверку при релизной сборке на `mac-build`: те же две команды `codesign` по `build/ios/archive/Runner.xcarchive/Products/Applications/Runner.app` сразу после шага архивации talerid, до экспорта. Записать результат в спецификацию — это открытый вопрос.

- [ ] **Step 3: talerid на устройстве**

```bash
flutter run --release --flavor talerid --dart-define=BASE_URL=https://api.talerid.io \
  --dart-define=WEB_URL=https://talerid.io --dart-define=TALERID_PUBLIC=true -d 00008101-000E21100202001E
```

Вход — тестовый аккаунт PROD. Один сценарий: PDF из «Файлов» → «Taler ID» → «Кому отправить» → «Избранное» → файл в полосе, комментарий, «Отправить».

---

### Task 14: Завершение

**Files:**
- Modify: `docs/superpowers/specs/2026-10-31-share-to-chat-design.md` (строка статуса)

- [ ] **Step 1: Статус спецификации**

Заменить
```
**Статус:** проект утверждён 2026-10-31
```
на
```
**Статус:** проект утверждён 2026-10-31, реализован в ветке `feat/share-to-chat`; на устройствах проверено: <Android — дата>, <iPhone — дата и бандлы>
```
Подставить реальные даты и бандлы. Если в Task 13 что-то не проверено, так и написать.

- [ ] **Step 2: Коммит**

```bash
git add docs/superpowers/specs/2026-10-31-share-to-chat-design.md
git commit -m "docs(share): спецификация — реализовано и проверено на устройствах" \
  -m "Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>"
```

- [ ] **Step 3: Дальше — решение пользователя**

superpowers:finishing-a-development-branch: слить в `dev` или открыть PR. Релиз (версия в `pubspec.yaml`, `APP_RELEASES` и `latest` в `taler-id/src/app.controller.ts`, сборки, деплой DEV → TEST → PROD, объявление после всех платформ) — по CLAUDE.md и только по команде пользователя для каждого окружения. Перед деплоем — обязательная батарея из CLAUDE.md.

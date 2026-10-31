# Звонок: кнопка «Не поворачивать экран» — план реализации

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** В звонке появляется кнопка, которая держит экран вертикально и не даёт ему поворачиваться; выбор запоминается между звонками и доступен голосом через ассистента звонка.

**Architecture:** Управление поворотом уезжает из `VoiceCallScreen` в маленький `CallOrientationService` (синглтон в `sl`): он хранит флаг в Hive-боксе `call_prefs`, считает открытые экраны звонка и применяет ориентацию через `SystemChrome` и iOS-канал `taler_id/orientation`. Кнопка — отдельный виджет `CallRotationLockButton` в двух видах (в шапке и плавающий), слушает `ValueNotifier` сервиса. Экран звонка только вызывает сервис и ставит кнопку.

**Tech Stack:** Flutter 3.38.9, Dart, Hive 2.2.3, GetIt (`sl`), gen-l10n (24 ARB), flutter_test.

**Спека:** `docs/superpowers/specs/2026-10-31-call-rotation-lock-design.md`

---

## Где работать

- Worktree: `~/Downloads/taler_id_mobile/.worktrees/call-rotation-lock`, ветка `feat/call-rotation-lock` (от `origin/main` = `2f68fc0`, 1.1.37+238). Upstream у ветки снят намеренно — чтобы случайный `git push` не ушёл в `main`. Пушить, если понадобится: `git push -u origin feat/call-rotation-lock`.
- Все команды ниже — из корня worktree.
- `flutter pub get` в worktree уже сделан.

## Базовая линия (снята 2026-10-31 до изменений)

- `flutter test` — `+1582: All tests passed!` (~1,5 мин).
- `flutter analyze --no-pub lib/features/voice/presentation/screens/voice_call_screen.dart` — 39 замечаний; `lib/core/di/service_locator.dart` — 1. В репозитории сотни старых замечаний анализатора, «чисто» недостижимо: судим только по тому, что число на своих файлах не выросло, а у новых файлов — 0.
- Подсчёт: `flutter analyze --no-pub <файл> 2>&1 | grep -cE "^\s*(info|warning|error) •"`.

## Файлы

| Файл | Что | Ответственность |
|------|-----|-----------------|
| `lib/core/services/call_orientation_service.dart` | создать | флаг фиксации (Hive `call_prefs`), счётчик экранов звонка, применение ориентации |
| `test/core/services/call_orientation_service_test.dart` | создать | юнит-тесты сервиса, включая работу без хранилища |
| `lib/l10n/app_*.arb` (24 файла) + `lib/l10n/app_localizations*.dart` | изменить / перегенерировать | строки `voiceRotationLock`, `voiceRotationUnlock` |
| `lib/features/voice/presentation/widgets/call_rotation_lock_button.dart` | создать | кнопка в двух видах |
| `test/features/voice/presentation/widgets/call_rotation_lock_button_test.dart` | создать | виджет-тест кнопки |
| `lib/core/di/service_locator.dart` | изменить | регистрация и `init()` сервиса |
| `lib/features/voice/presentation/screens/voice_call_screen.dart` | изменить | вызовы сервиса вместо своих методов поворота, две кнопки, инструмент ассистента |

`ios/Runner/AppDelegate.swift` не меняется: метод `setAllowAll` в канале `taler_id/orientation` уже есть.

---

### Task 1: CallOrientationService

**Files:**
- Create: `lib/core/services/call_orientation_service.dart`
- Test: `test/core/services/call_orientation_service_test.dart`

- [ ] **Step 1: Написать падающие тесты сервиса**

`test/core/services/call_orientation_service_test.dart`:

```dart
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:taler_id_mobile/core/services/call_orientation_service.dart';

const _free = [
  'DeviceOrientation.portraitUp',
  'DeviceOrientation.landscapeLeft',
  'DeviceOrientation.landscapeRight',
];
const _portrait = ['DeviceOrientation.portraitUp'];
const _iosChannel = MethodChannel('taler_id/orientation');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  // Every SystemChrome.setPreferredOrientations / iOS setAllowAll, in order.
  late List<List<String>> orientations;
  late List<bool> allowAll;
  final open = <CallOrientationService>[];

  Future<CallOrientationService> make({
    bool isSupported = true,
    bool isIOS = true,
  }) async {
    final s = CallOrientationService(isSupported: isSupported, isIOS: isIOS);
    await s.init();
    open.add(s);
    return s;
  }

  Future<void> close(CallOrientationService s) async {
    await s.dispose();
    open.remove(s);
  }

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('call_orientation_test_');
    Hive.init(tempDir.path);
    orientations = [];
    allowAll = [];
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'SystemChrome.setPreferredOrientations') {
        orientations.add(List<String>.from(call.arguments as List));
      }
      return null;
    });
    messenger.setMockMethodCallHandler(_iosChannel, (call) async {
      if (call.method == 'setAllowAll') allowAll.add(call.arguments as bool);
      return null;
    });
  });

  tearDown(() async {
    for (final s in List.of(open)) {
      await close(s);
    }
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(SystemChannels.platform, null);
    messenger.setMockMethodCallHandler(_iosChannel, null);
    await Hive.deleteBoxFromDisk('call_prefs');
    await tempDir.delete(recursive: true);
  });

  test('unlocked by default: entering a call lets the phone rotate', () async {
    final s = await make();
    expect(s.rotationLocked.value, isFalse);

    await s.enterCall();

    expect(orientations, [_free]);
    expect(allowAll, [true]);
  });

  test('locking in a call snaps back to portrait and is remembered', () async {
    final s = await make();
    await s.enterCall();

    await s.setRotationLocked(true);

    expect(orientations.last, _portrait);
    expect(allowAll.last, isFalse);
    await close(s);
    final again = await make();
    expect(again.rotationLocked.value, isTrue);
  });

  test('locked: the next call opens portrait-only, never allows all', () async {
    final first = await make();
    await first.setRotationLocked(true);
    await close(first);

    final s = await make();
    await s.enterCall();
    await s.reapply();

    expect(orientations, [_portrait, _portrait]);
    expect(allowAll, [false, false]);
  });

  test('unlocking in a call lets the phone rotate again', () async {
    final s = await make();
    await s.setRotationLocked(true);
    await s.enterCall();

    await s.setRotationLocked(false);

    expect(orientations.last, _free);
    expect(allowAll.last, isTrue);
  });

  test('outside a call the choice is only stored', () async {
    final s = await make();

    await s.setRotationLocked(true);
    await s.setRotationLocked(false);

    expect(orientations, isEmpty);
    expect(allowAll, isEmpty);
  });

  test('closing the last call screen puts the app back to portrait', () async {
    final s = await make();
    await s.enterCall();

    await s.leaveCall();

    expect(orientations, [_free, _portrait]);
    expect(allowAll, [true, false]);
  });

  test('an old screen closing late does not take rotation from the new one',
      () async {
    final s = await make();
    await s.enterCall(); // the screen being minimised
    await s.enterCall(); // re-entered before the old one is disposed
    orientations.clear();
    allowAll.clear();

    await s.leaveCall(); // the old screen is disposed at last
    expect(orientations, isEmpty);
    expect(allowAll, isEmpty);

    await s.leaveCall(); // the new screen closes too
    expect(orientations, [_portrait]);
    expect(allowAll, [false]);
  });

  test('reapply does not count as another screen', () async {
    final s = await make();
    await s.enterCall();
    await s.reapply();

    await s.leaveCall();

    expect(orientations, [_free, _free, _portrait]);
    expect(allowAll, [true, true, false]);
  });

  test('an extra leaveCall does not break the next call', () async {
    final s = await make();
    await s.leaveCall();

    await s.enterCall();
    await s.leaveCall();

    expect(orientations, [_free, _portrait]);
  });

  test('Android: SystemChrome only, no iOS channel', () async {
    final s = await make(isIOS: false);

    await s.enterCall();
    await s.setRotationLocked(true);
    await s.leaveCall();

    expect(orientations, [_free, _portrait, _portrait]);
    expect(allowAll, isEmpty);
  });

  test('desktop and web: nothing applied, the choice is still kept', () async {
    final s = await make(isSupported: false, isIOS: false);

    await s.enterCall();
    await s.setRotationLocked(true);
    await s.leaveCall();

    expect(orientations, isEmpty);
    expect(allowAll, isEmpty);
    expect(s.rotationLocked.value, isTrue);
  });

  // The box is opened through an injected function: making the real Hive fail
  // (no Hive.init) also fails the test — Hive completes an internal Completer
  // with the error nobody listens to, and the test zone reports it as
  // uncaught even though init() catches the rethrown one.
  test('storage that cannot be opened does not fail app start-up', () async {
    final s = CallOrientationService(
      isSupported: false,
      isIOS: false,
      openBox: (_) => Future.error(const FileSystemException('read-only')),
    );

    await s.init();
    expect(s.rotationLocked.value, isFalse);

    await s.setRotationLocked(true);
    expect(s.rotationLocked.value, isTrue);
  });
}
```

- [ ] **Step 2: Убедиться, что тесты падают**

Run: `flutter test test/core/services/call_orientation_service_test.dart`
Expected: FAIL — ошибка компиляции, `call_orientation_service.dart` не существует (`Error when reading … call_orientation_service.dart` / `CallOrientationService isn't a type`).

- [ ] **Step 3: Написать сервис**

`lib/core/services/call_orientation_service.dart`:

```dart
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';

import '../platform/platform_utils.dart';

/// Screen rotation on the call screen, and the user's choice to lock it.
///
/// The app is portrait-only (main.dart). A call screen lets the phone rotate —
/// unless the user pressed "Не поворачивать экран", which keeps it upright in
/// this call and the next ones. The choice lives in the `call_prefs` Hive box,
/// opened at start-up, so a call screen reads it synchronously and a locked
/// call never turns sideways even for a frame.
///
/// On iOS SystemChrome alone isn't enough: AppDelegate's
/// `supportedInterfaceOrientationsFor` answers portrait-only unless
/// `taler_id/orientation` → `setAllowAll(true)` flips it. The calls are
/// awaited — synchronous ones were ignored on some iOS 16+ devices.
///
/// Open call screens are counted rather than flagged: re-entering a call while
/// the minimised screen is still animating out builds the new screen before
/// the old one is disposed, and the old one's [leaveCall] must not take
/// rotation away from the new one.
class CallOrientationService {
  /// [openBox] is for tests; the app uses Hive.
  CallOrientationService({
    bool? isSupported,
    bool? isIOS,
    Future<Box> Function(String name)? openBox,
  })  : isSupported = isSupported ?? PlatformUtils.instance.isMobile,
        _isIOS = isIOS ?? PlatformUtils.instance.isIOS,
        _openBox = openBox ?? ((name) => Hive.openBox(name));

  static const _boxName = 'call_prefs';
  static const _lockedKey = 'rotation_locked_v1';
  static const _channel = MethodChannel('taler_id/orientation');

  /// Whether the screen rotates on this platform at all (iOS and Android).
  /// Elsewhere the button is hidden and nothing is applied.
  final bool isSupported;
  final bool _isIOS;
  final Future<Box> Function(String name) _openBox;

  /// The user's choice. The call screen's button listens to it.
  final ValueNotifier<bool> rotationLocked = ValueNotifier(false);

  Box? _box;
  int _openCallScreens = 0;

  Future<void> init() async {
    try {
      _box = await _openBox(_boxName);
    } catch (_) {
      try {
        await Hive.deleteBoxFromDisk(_boxName);
        _box = await _openBox(_boxName);
      } catch (_) {
        // No storage: the choice lives until the app restarts — and the app
        // still starts.
        _box = null;
      }
    }
    rotationLocked.value = (_box?.get(_lockedKey) as bool?) ?? false;
  }

  Future<void> dispose() async {
    await _box?.close();
    _box = null;
  }

  /// A call screen opened: count it and apply the choice.
  Future<void> enterCall() {
    _openCallScreens++;
    return _apply();
  }

  /// Applies the choice again without counting a screen. The call screen
  /// repeats it after its first frame: iOS 16+ doesn't always pick up a new
  /// set of orientations the first time.
  Future<void> reapply() =>
      _openCallScreens > 0 ? _apply() : Future<void>.value();

  /// A call screen closed. The last one out puts the app back to portrait.
  Future<void> leaveCall() {
    if (_openCallScreens == 0) return Future<void>.value();
    _openCallScreens--;
    return _openCallScreens == 0
        ? _setFreeRotation(false)
        : Future<void>.value();
  }

  /// Stores the choice and, if a call screen is open, applies it right away —
  /// a screen lying sideways snaps back upright.
  Future<void> setRotationLocked(bool locked) async {
    rotationLocked.value = locked;
    try {
      await _box?.put(_lockedKey, locked);
    } catch (_) {
      // Not stored: still applies for as long as the app runs.
    }
    if (_openCallScreens > 0) await _apply();
  }

  Future<void> _apply() => _setFreeRotation(!rotationLocked.value);

  Future<void> _setFreeRotation(bool free) async {
    if (!isSupported) return;
    await SystemChrome.setPreferredOrientations(free
        ? const [
            DeviceOrientation.portraitUp,
            DeviceOrientation.landscapeLeft,
            DeviceOrientation.landscapeRight,
          ]
        : const [DeviceOrientation.portraitUp]);
    if (_isIOS) {
      try {
        await _channel.invokeMethod('setAllowAll', free);
      } catch (_) {}
    }
  }
}
```

- [ ] **Step 4: Убедиться, что тесты проходят**

Run: `flutter test test/core/services/call_orientation_service_test.dart`
Expected: `+12: All tests passed!`

- [ ] **Step 5: Анализатор на новых файлах**

Run: `flutter analyze --no-pub lib/core/services/call_orientation_service.dart test/core/services/call_orientation_service_test.dart`
Expected: `No issues found!`

- [ ] **Step 6: Commit**

```bash
git add lib/core/services/call_orientation_service.dart test/core/services/call_orientation_service_test.dart
git commit -m "$(cat <<'EOF'
feat(звонок): сервис поворота экрана с запоминаемой фиксацией

Флаг в Hive-боксе call_prefs, открытые экраны звонка считаются
счётчиком: старый экран, закрывшийся после нового, больше не снимает
поворот у нового. Без хранилища сервис работает в памяти и запуск
приложения не роняет.

Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

### Task 2: Строки кнопки на всех языках

**Files:**
- Modify: `lib/l10n/app_*.arb` — все 24 файла (шаблон — `app_ru.arb`, см. `l10n.yaml`)
- Regenerate: `lib/l10n/app_localizations.dart`, `lib/l10n/app_localizations_*.dart`

Строки экрана звонка в этом репозитории заводятся во всех 24 ARB сразу, без `@`-описаний, сразу после `"voiceAddParticipant"` (так сделаны `callHeldBySystem` / `callResumeFromHold`, коммит `a300996`). Значение — то, что сделает нажатие.

- [ ] **Step 1: Вставить ключи во все ARB**

Run:

```bash
python3 - <<'PY'
import json, pathlib

T = {
    'ar': ('قفل تدوير الشاشة', 'السماح بتدوير الشاشة'),
    'bn': ('স্ক্রিন ঘোরানো লক করুন', 'স্ক্রিন ঘোরানোর অনুমতি দিন'),
    'de': ('Bildschirmdrehung sperren', 'Bildschirmdrehung erlauben'),
    'en': ('Lock screen rotation', 'Allow screen rotation'),
    'es': ('Bloquear la rotación de la pantalla', 'Permitir la rotación de la pantalla'),
    'fa': ('قفل چرخش صفحه', 'اجازه چرخش صفحه'),
    'fr': ("Verrouiller la rotation de l'écran", "Autoriser la rotation de l'écran"),
    'ha': ('Kulle juyawar allo', 'Bari allo ya juya'),
    'hi': ('स्क्रीन रोटेशन लॉक करें', 'स्क्रीन रोटेशन की अनुमति दें'),
    'id': ('Kunci rotasi layar', 'Izinkan rotasi layar'),
    'it': ('Blocca la rotazione dello schermo', 'Consenti la rotazione dello schermo'),
    'ja': ('画面の回転をロック', '画面の回転を許可'),
    'ko': ('화면 회전 잠금', '화면 회전 허용'),
    'mr': ('स्क्रीन फिरणे लॉक करा', 'स्क्रीन फिरू द्या'),
    'pa': ('ਸਕ੍ਰੀਨ ਘੁੰਮਣਾ ਲੌਕ ਕਰੋ', 'ਸਕ੍ਰੀਨ ਘੁੰਮਣ ਦਿਓ'),
    'pt': ('Bloquear a rotação da tela', 'Permitir a rotação da tela'),
    'ru': ('Не поворачивать экран', 'Разрешить поворот экрана'),
    'sk': ('Uzamknúť otáčanie obrazovky', 'Povoliť otáčanie obrazovky'),
    'ta': ('திரைச் சுழற்சியைப் பூட்டு', 'திரைச் சுழற்சியை அனுமதி'),
    'te': ('స్క్రీన్ తిరగడాన్ని లాక్ చేయండి', 'స్క్రీన్ తిరగడానికి అనుమతించండి'),
    'tr': ('Ekran döndürmeyi kilitle', 'Ekran döndürmeye izin ver'),
    'ur': ('اسکرین کی گردش لاک کریں', 'اسکرین کی گردش کی اجازت دیں'),
    'vi': ('Khóa xoay màn hình', 'Cho phép xoay màn hình'),
    'zh': ('锁定屏幕旋转', '允许屏幕旋转'),
}

files = sorted(pathlib.Path('lib/l10n').glob('app_*.arb'))
assert len(files) == len(T) == 24, (len(files), len(T))
for p in files:
    code = p.stem[len('app_'):]
    lock, unlock = T[code]
    text = p.read_text(encoding='utf-8')
    assert '"voiceRotationLock"' not in text, f'{p} already has the keys'
    lines = text.split('\n')
    i = next(n for n, l in enumerate(lines) if l.lstrip().startswith('"voiceAddParticipant"'))
    assert lines[i].rstrip().endswith(','), f'{p}: voiceAddParticipant is the last key'
    indent = lines[i][:len(lines[i]) - len(lines[i].lstrip())]
    lines[i + 1:i + 1] = [
        f'{indent}"voiceRotationLock": {json.dumps(lock, ensure_ascii=False)},',
        f'{indent}"voiceRotationUnlock": {json.dumps(unlock, ensure_ascii=False)},',
    ]
    p.write_text('\n'.join(lines), encoding='utf-8')
    data = json.loads(p.read_text(encoding='utf-8'))
    assert data['voiceRotationLock'] == lock and data['voiceRotationUnlock'] == unlock
print('ok', len(files))
PY
```

Expected: `ok 24`

- [ ] **Step 2: Перегенерировать локализацию**

Run: `flutter gen-l10n 2>&1 | grep -o "[0-9]* untranslated" | sort | uniq -c`
Expected: `  22 193 untranslated`. Генератор и до правки жалуется на старые непереведённые строки: у всех 22 языков, кроме `ru` и `en`, по 193 (базовая линия 2026-10-31). После вставки должно остаться ровно так: наши ключи есть во всех языках. Появилось 194 или 195 — какой-то ARB не получил ключ, см. Step 1.

- [ ] **Step 3: Проверить, что дошло везде**

Run: `grep -l "voiceRotationLock" lib/l10n/app_localizations*.dart | wc -l && grep -n "voiceRotationLock\|voiceRotationUnlock" lib/l10n/app_localizations_en.dart lib/l10n/app_localizations_ru.dart`
Expected: `25` (базовый класс + 24 языка), затем по две строки-геттера в `en` (`Lock screen rotation` / `Allow screen rotation`) и в `ru` (`Не поворачивать экран` / `Разрешить поворот экрана`).

- [ ] **Step 4: Commit**

```bash
git add lib/l10n/
git commit -m "$(cat <<'EOF'
feat(звонок): строки кнопки «Не поворачивать экран» на всех языках

Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

### Task 3: Виджет кнопки CallRotationLockButton

**Files:**
- Create: `lib/features/voice/presentation/widgets/call_rotation_lock_button.dart`
- Test: `test/features/voice/presentation/widgets/call_rotation_lock_button_test.dart`

- [ ] **Step 1: Написать падающий виджет-тест**

`test/features/voice/presentation/widgets/call_rotation_lock_button_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taler_id_mobile/core/services/call_orientation_service.dart';
import 'package:taler_id_mobile/core/theme/app_theme.dart';
import 'package:taler_id_mobile/features/voice/presentation/widgets/call_rotation_lock_button.dart';
import 'package:taler_id_mobile/l10n/app_localizations.dart';

Widget _wrap(Widget child) => MaterialApp(
      theme: AppTheme.dark,
      locale: const Locale('en'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Scaffold(body: Center(child: child)),
    );

// Never init()-ed: no Hive box, the choice lives in memory — all the button
// needs. isSupported: false keeps SystemChrome out of the test.
CallOrientationService _service() =>
    CallOrientationService(isSupported: false, isIOS: false);

void main() {
  for (final floating in [false, true]) {
    final kind = floating ? 'floating' : 'app bar';
    Widget button(CallOrientationService s) => floating
        ? CallRotationLockButton.floating(service: s)
        : CallRotationLockButton.appBar(service: s);

    testWidgets('$kind: rotation allowed — rotate icon, tap locks', (t) async {
      final s = _service();
      await t.pumpWidget(_wrap(button(s)));
      expect(find.byIcon(Icons.screen_rotation_rounded), findsOneWidget);
      expect(find.byTooltip('Lock screen rotation'), findsOneWidget);

      await t.tap(find.byKey(const Key('call-rotation-lock')));
      await t.pump();

      expect(s.rotationLocked.value, isTrue);
      expect(find.byIcon(Icons.screen_lock_portrait_rounded), findsOneWidget);
      expect(find.byTooltip('Allow screen rotation'), findsOneWidget);
    });

    testWidgets('$kind: locked — tap allows rotation again', (t) async {
      final s = _service();
      await s.setRotationLocked(true);
      await t.pumpWidget(_wrap(button(s)));
      expect(find.byIcon(Icons.screen_lock_portrait_rounded), findsOneWidget);

      await t.tap(find.byKey(const Key('call-rotation-lock')));
      await t.pump();

      expect(s.rotationLocked.value, isFalse);
      expect(find.byIcon(Icons.screen_rotation_rounded), findsOneWidget);
    });
  }

  testWidgets('follows a change made elsewhere (the in-call assistant)',
      (t) async {
    final s = _service();
    await t.pumpWidget(_wrap(CallRotationLockButton.appBar(service: s)));

    await s.setRotationLocked(true);
    await t.pump();

    expect(find.byIcon(Icons.screen_lock_portrait_rounded), findsOneWidget);
  });
}
```

- [ ] **Step 2: Убедиться, что тест падает**

Run: `flutter test test/features/voice/presentation/widgets/call_rotation_lock_button_test.dart`
Expected: FAIL — ошибка компиляции, `call_rotation_lock_button.dart` не существует.

- [ ] **Step 3: Написать виджет**

`lib/features/voice/presentation/widgets/call_rotation_lock_button.dart`:

```dart
import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/services/call_orientation_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';

/// The call screen's "Не поворачивать экран" toggle.
///
/// [CallRotationLockButton.appBar] sits among the call app bar's actions in
/// portrait. [CallRotationLockButton.floating] is the round 36 px button for
/// the top-right corner in landscape, where the app bar is gone — styled to
/// pair with the back chevron in the top-left one.
///
/// The tooltip names what a tap will do, not the current state.
class CallRotationLockButton extends StatelessWidget {
  const CallRotationLockButton.appBar({super.key, required this.service})
      : floating = false;

  const CallRotationLockButton.floating({super.key, required this.service})
      : floating = true;

  final CallOrientationService service;
  final bool floating;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: service.rotationLocked,
      builder: (context, locked, _) {
        final l10n = AppLocalizations.of(context)!;
        final colors = AppColors.of(context);
        final icon = locked
            ? Icons.screen_lock_portrait_rounded
            : Icons.screen_rotation_rounded;
        final label =
            locked ? l10n.voiceRotationUnlock : l10n.voiceRotationLock;
        void toggle() => unawaited(service.setRotationLocked(!locked));

        if (!floating) {
          return IconButton(
            key: const Key('call-rotation-lock'),
            icon: Icon(icon, color: locked ? colors.primary : null),
            tooltip: label,
            onPressed: toggle,
          );
        }
        return Tooltip(
          message: label,
          child: GestureDetector(
            key: const Key('call-rotation-lock'),
            onTap: toggle,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white24),
              ),
              alignment: Alignment.center,
              child: Icon(
                icon,
                color: locked ? colors.primary : Colors.white,
                size: 20,
              ),
            ),
          ),
        );
      },
    );
  }
}
```

- [ ] **Step 4: Убедиться, что тест проходит**

Run: `flutter test test/features/voice/presentation/widgets/call_rotation_lock_button_test.dart`
Expected: `+5: All tests passed!`

- [ ] **Step 5: Анализатор на новых файлах**

Run: `flutter analyze --no-pub lib/features/voice/presentation/widgets/call_rotation_lock_button.dart test/features/voice/presentation/widgets/call_rotation_lock_button_test.dart`
Expected: `No issues found!`

- [ ] **Step 6: Commit**

```bash
git add lib/features/voice/presentation/widgets/call_rotation_lock_button.dart test/features/voice/presentation/widgets/call_rotation_lock_button_test.dart
git commit -m "$(cat <<'EOF'
feat(звонок): кнопка «Не поворачивать экран» — для шапки и плавающая

Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

### Task 4: Регистрация сервиса при старте

**Files:**
- Modify: `lib/core/di/service_locator.dart` (импорты ~строки 26–44; блок `MeshPrefsService` ~строки 247–250)

Сервис регистрируется на всех платформах (экран звонка есть и на десктопе; там `isSupported == false`, и сервис ничего не применяет). Регистрировать рядом с `MeshPrefsService` — тот же приём: `init()` открывает Hive-бокс при старте, дальше чтение синхронное.

- [ ] **Step 1: Добавить импорт**

Найти:

```dart
import '../services/call_state_service.dart';
```

Заменить на:

```dart
import '../services/call_orientation_service.dart';
import '../services/call_state_service.dart';
```

- [ ] **Step 2: Зарегистрировать сервис после `MeshPrefsService`**

Найти:

```dart
  // Mesh prefs (Hive) — small flag store for mesh-related UI state
  final meshPrefs = MeshPrefsService();
  await meshPrefs.init();
  sl.registerSingleton<MeshPrefsService>(meshPrefs);
```

Заменить на:

```dart
  // Mesh prefs (Hive) — small flag store for mesh-related UI state
  final meshPrefs = MeshPrefsService();
  await meshPrefs.init();
  sl.registerSingleton<MeshPrefsService>(meshPrefs);

  // Call screen rotation (Hive) — the "Не поворачивать экран" choice, kept
  // across calls and read synchronously when a call screen opens. init()
  // never throws: without storage the choice just lives in memory.
  final callOrientation = CallOrientationService();
  await callOrientation.init();
  sl.registerSingleton<CallOrientationService>(callOrientation);
```

- [ ] **Step 3: Анализатор**

Run: `flutter analyze --no-pub lib/core/di/service_locator.dart 2>&1 | grep -cE "^\s*(info|warning|error) •"`
Expected: `1` (как в базовой линии).

- [ ] **Step 4: Commit**

```bash
git add lib/core/di/service_locator.dart
git commit -m "$(cat <<'EOF'
feat(звонок): CallOrientationService регистрируется при старте

Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

### Task 5: Экран звонка поворачивается через сервис

**Files:**
- Modify: `lib/features/voice/presentation/screens/voice_call_screen.dart` — импорты (~строка 26), поля состояния (~строка 377), `initState` (~строки 398–404), `dispose` (~строки 4769–4770), методы поворота (~строки 6258–6281)

Поведение после этой задачи — как сейчас (кнопки ещё нет), но поворот идёт через сервис: учитывается сохранённый выбор и работает счётчик экранов.

- [ ] **Step 1: Импорт сервиса**

Найти:

```dart
import '../../../../core/services/call_state_service.dart';
```

Заменить на:

```dart
import '../../../../core/services/call_orientation_service.dart';
import '../../../../core/services/call_state_service.dart';
```

- [ ] **Step 2: Поле состояния**

Найти:

```dart
  // Tracks whether we've already hidden system status bar for landscape fullscreen
  bool _systemUiHiddenForFs = false;
```

Заменить на:

```dart
  // Tracks whether we've already hidden system status bar for landscape fullscreen
  bool _systemUiHiddenForFs = false;

  /// Rotation during the call and the user's "Не поворачивать экран" choice.
  final CallOrientationService _orientation = sl<CallOrientationService>();
```

- [ ] **Step 3: `initState` — вход в звонок через сервис**

Найти:

```dart
    // Allow free rotation during a call. iOS 16+ doesn't pick up the new
    // allowed-orientation set immediately, so we await + apply twice with a
    // post-frame nudge — that triggers the native rotation refresh path.
    _enableFreeRotation();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _enableFreeRotation();
    });
```

Заменить на:

```dart
    // Let the phone rotate during the call — unless the user locked it
    // (remembered across calls, see CallOrientationService). iOS 16+ doesn't
    // pick up a new allowed-orientation set immediately, so it is applied
    // again after the first frame — that triggers the native rotation
    // refresh path.
    unawaited(_orientation.enterCall());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_orientation.reapply());
    });
```

- [ ] **Step 4: `dispose` — выход через сервис**

Найти:

```dart
    // Restore portrait + native iOS orientation lock for the rest of the app
    _restorePortraitLock();
```

Заменить на:

```dart
    // Back to portrait-only for the rest of the app — unless another call
    // screen is already open (re-entered before this one was disposed).
    unawaited(_orientation.leaveCall());
```

- [ ] **Step 5: Удалить собственные методы поворота экрана**

Удалить целиком (вместе с пустой строкой после блока):

```dart
  static const _orientationChannel = MethodChannel('taler_id/orientation');

  /// Allow portrait + both landscape orientations during the call.
  /// Async-await is required on iOS — synchronous calls were ignored on
  /// some iOS 16+ devices (the rotation simply didn't happen). Plus we
  /// flip the iOS-native orientation lock via AppDelegate so SystemChrome
  /// preferences actually take effect on iPhone.
  Future<void> _enableFreeRotation() async {
    await SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    if (Platform.isIOS) {
      try { await _orientationChannel.invokeMethod('setAllowAll', true); } catch (_) {}
    }
  }

  Future<void> _restorePortraitLock() async {
    await SystemChrome.setPreferredOrientations(const [DeviceOrientation.portraitUp]);
    if (Platform.isIOS) {
      try { await _orientationChannel.invokeMethod('setAllowAll', false); } catch (_) {}
    }
  }

```

Всё, что эти комментарии объясняли (await на iOS, флаг `AppDelegate`), теперь записано в doc-комментарии `CallOrientationService`.

- [ ] **Step 6: Проверить, что старых вызовов не осталось**

Run: `grep -n "_enableFreeRotation\|_restorePortraitLock\|_orientationChannel\|setPreferredOrientations" lib/features/voice/presentation/screens/voice_call_screen.dart`
Expected: пустой вывод (код выхода 1).

- [ ] **Step 7: Анализатор**

Run: `flutter analyze --no-pub lib/features/voice/presentation/screens/voice_call_screen.dart 2>&1 | grep -cE "^\s*(info|warning|error) •"`
Expected: `39` или меньше. Больше — значит, появилось новое замечание: посмотреть `flutter analyze --no-pub <файл>` и исправить.

- [ ] **Step 8: Commit**

```bash
git add lib/features/voice/presentation/screens/voice_call_screen.dart
git commit -m "$(cat <<'EOF'
refactor(звонок): поворот экрана звонка — через CallOrientationService

Экран больше не держит свой канал taler_id/orientation и методы
поворота. Попутно уходит гонка: экран, закрывшийся позже нового
(вернулись в звонок во время анимации сворачивания), больше не
запрещает поворот новому.

Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

### Task 6: Кнопка на экране звонка — в шапке и в альбомной ориентации

**Files:**
- Modify: `lib/features/voice/presentation/screens/voice_call_screen.dart` — импорты виджетов (~строки 43–45), `actions` шапки в `build` (~строка 4878), плавающие кнопки в `Stack` (~строка 4944)

- [ ] **Step 1: Импорт виджета**

Найти:

```dart
import '../widgets/room_chat_panel.dart';
```

Заменить на:

```dart
import '../widgets/call_rotation_lock_button.dart';
import '../widgets/room_chat_panel.dart';
```

- [ ] **Step 2: Кнопка первой в действиях шапки (портрет)**

Найти:

```dart
        automaticallyImplyLeading: false,
        actions: [
          if (_roomName != null)
```

Заменить на:

```dart
        automaticallyImplyLeading: false,
        actions: [
          if (_orientation.isSupported)
            CallRotationLockButton.appBar(service: _orientation),
          if (_roomName != null)
```

- [ ] **Step 3: Плавающая кнопка в правом верхнем углу (альбомная)**

Найти (конец блока плавающей стрелки «назад» и начало следующего блока):

```dart
                  child: const Icon(
                    Icons.arrow_back_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
          // Floating restore button when bottom controls are auto-hidden
```

Заменить на:

```dart
                  child: const Icon(
                    Icons.arrow_back_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
          // Rotation lock, paired with the back chevron: in landscape the
          // AppBar — and the lock in it — is gone. Immersive fullscreen keeps
          // its own exit button in this corner, so the lock isn't shown there.
          if (isLandscape && !immersiveFs && _orientation.isSupported)
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              right: MediaQuery.of(context).padding.right + 8,
              child: CallRotationLockButton.floating(service: _orientation),
            ),
          // Floating restore button when bottom controls are auto-hidden
```

- [ ] **Step 4: Анализатор**

Run: `flutter analyze --no-pub lib/features/voice/presentation/screens/voice_call_screen.dart 2>&1 | grep -cE "^\s*(info|warning|error) •"`
Expected: `39` или меньше.

- [ ] **Step 5: Тесты голосовой части и новых файлов**

Run: `flutter test test/features/voice test/core/services/call_orientation_service_test.dart`
Expected: `All tests passed!`

- [ ] **Step 6: Commit**

```bash
git add lib/features/voice/presentation/screens/voice_call_screen.dart
git commit -m "$(cat <<'EOF'
feat(звонок): кнопка «Не поворачивать экран» на экране звонка

В портрете — первой в шапке, в альбомной — круглая в правом верхнем
углу, парная к стрелке «назад». Только iOS и Android.

Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

### Task 7: Голосовая команда ассистента в звонке

**Files:**
- Modify: `lib/features/voice/presentation/screens/voice_call_screen.dart` — `_buildCallAssistantPrompt` (~строки 2200–2244), список `tools` в `_configureAssistantSession` (~строки 2256–2320), `_handleAssistantFunctionCall` (~строка 2497)

Правило «Assistant-first» из `CLAUDE.md`: новая функция доступна голосом. Ассистент звонка объявляет свои инструменты сам, в мобилке (бэкенд не участвует) — рядом с `set_translation`. На платформах без поворота ни инструмента, ни фразы в подсказке нет.

- [ ] **Step 1: Фраза в русской подсказке**

Найти:

```dart
      final participantsStr = participantNames.isEmpty
          ? ''
          : '\nУчастники текущего звонка: $participantsJoined';
```

Заменить на:

```dart
      final participantsStr = participantNames.isEmpty
          ? ''
          : '\nУчастники текущего звонка: $participantsJoined';
      final rotationStr = _orientation.isSupported
          ? '\nЭкран звонка можно зафиксировать вертикально. Если пользователь просит «не переворачивай экран», «зафиксируй экран» — вызови set_screen_rotation_lock с locked=true; «разреши поворот», «пусть экран поворачивается» — с locked=false. Выбор запоминается и для следующих звонков.\n'
          : '';
```

Затем найти:

```dart
Если названа только одна сторона — переспроси вторую, не догадывайся.

Отвечай коротко — пользователь в разгаре разговора.''';
```

Заменить на:

```dart
Если названа только одна сторона — переспроси вторую, не догадывайся.
$rotationStr
Отвечай коротко — пользователь в разгаре разговора.''';
```

(Пустая `rotationStr` даёт ровно прежнюю пустую строку между абзацами; непустая начинается и кончается `\n`, поэтому абзац встаёт отдельно, как соседние.)

- [ ] **Step 2: Фраза в английской подсказке**

Найти:

```dart
    final participantsStr = participantNames.isEmpty
        ? ''
        : '\nCurrent call participants: $participantsJoined';
```

Заменить на:

```dart
    final participantsStr = participantNames.isEmpty
        ? ''
        : '\nCurrent call participants: $participantsJoined';
    final rotationStr = _orientation.isSupported
        ? '\nThe call screen can be locked upright. If the user asks to "stop the screen rotating", "lock the screen" — call set_screen_rotation_lock with locked=true; "let the screen rotate", "unlock rotation" — with locked=false. The choice is remembered for the next calls too.\n'
        : '';
```

Затем найти:

```dart
If only one side is named, ask for the other rather than guessing.

Answer briefly — the user is in the middle of a conversation.''';
```

Заменить на:

```dart
If only one side is named, ask for the other rather than guessing.
$rotationStr
Answer briefly — the user is in the middle of a conversation.''';
```

- [ ] **Step 3: Объявить инструмент**

Найти (конец объявления `send_room_chat` и закрытие списка `tools`):

```dart
                'text': {'type': 'string', 'description': 'The message text, up to $kRoomChatMaxLength characters'},
              },
              'required': ['text'],
            },
          },
        ],
```

Заменить на:

```dart
                'text': {'type': 'string', 'description': 'The message text, up to $kRoomChatMaxLength characters'},
              },
              'required': ['text'],
            },
          },
          if (_orientation.isSupported)
            {
              'type': 'function',
              'name': 'set_screen_rotation_lock',
              'description': 'Lock or unlock rotation of the call screen on this phone. locked=true keeps the screen upright (portrait) and stops it turning when the phone tilts — "не переворачивай экран", "зафиксируй экран", "stop the screen rotating". locked=false lets it rotate with the phone again — "разреши поворот", "let the screen rotate". The choice is remembered for the next calls too.',
              'parameters': {
                'type': 'object',
                'properties': {
                  'locked': {
                    'type': 'boolean',
                    'description': 'true keeps the screen upright, false lets it rotate',
                  },
                },
                'required': ['locked'],
              },
            },
        ],
```

- [ ] **Step 4: Обработать вызов**

Найти:

```dart
        output = jsonEncode(await _setTranslationPair(hear, speak));
      } else if (name == 'send_room_chat') {
```

Заменить на:

```dart
        output = jsonEncode(await _setTranslationPair(hear, speak));
      } else if (name == 'set_screen_rotation_lock') {
        final raw = args['locked'];
        final locked = raw == true || raw == 'true';
        debugPrint('[InCallAssistant] set_screen_rotation_lock: $locked');
        await _orientation.setRotationLocked(locked);
        output = jsonEncode({'ok': true, 'locked': locked});
      } else if (name == 'send_room_chat') {
```

Кнопка в шапке подхватит изменение сама — она слушает `rotationLocked` (тест «follows a change made elsewhere» из Task 3).

- [ ] **Step 5: Проверить сборку строк и анализатор**

Run: `grep -c "set_screen_rotation_lock" lib/features/voice/presentation/screens/voice_call_screen.dart && flutter analyze --no-pub lib/features/voice/presentation/screens/voice_call_screen.dart 2>&1 | grep -cE "^\s*(info|warning|error) •"`
Expected: сначала `5` — по одной строке: фраза `rotationStr` (ru), фраза `rotationStr` (en), `'name': 'set_screen_rotation_lock'`, `name == 'set_screen_rotation_lock'`, `debugPrint`. Затем `39` или меньше. Другое число строк — сверить вставки с шагами 1–4.

- [ ] **Step 6: Commit**

```bash
git add lib/features/voice/presentation/screens/voice_call_screen.dart
git commit -m "$(cat <<'EOF'
feat(звонок): «не переворачивай экран» голосом через ассистента звонка

Инструмент set_screen_rotation_lock рядом с set_translation и фраза в
подсказке ассистента звонка (ru, en). На платформах без поворота не
объявляется.

Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

### Task 8: Проверка целиком

**Files:**
- Modify: `docs/superpowers/specs/2026-10-31-call-rotation-lock-design.md` (строка «Статус»)

- [ ] **Step 1: Весь набор тестов**

Run: `flutter test`
Expected: `+1599: All tests passed!` (1582 базовых + 12 из Task 1 + 5 из Task 3).

- [ ] **Step 2: Анализатор на всех тронутых файлах**

Run:

```bash
for f in lib/core/services/call_orientation_service.dart lib/features/voice/presentation/widgets/call_rotation_lock_button.dart lib/features/voice/presentation/screens/voice_call_screen.dart lib/core/di/service_locator.dart test/core/services/call_orientation_service_test.dart test/features/voice/presentation/widgets/call_rotation_lock_button_test.dart; do echo "$f: $(flutter analyze --no-pub "$f" 2>&1 | grep -cE "^\s*(info|warning|error) •")"; done
```

Expected: новые файлы — `0`, `voice_call_screen.dart` — не больше `39`, `service_locator.dart` — не больше `1`.

- [ ] **Step 3: Android-сборка компилируется**

Run: `flutter build apk --flavor dev --debug -t lib/main_dev.dart --dart-define=FLAVOR=dev --dart-define=BASE_URL=https://staging.id.taler.tirol`
Expected: `✓ Built build/app/outputs/flutter-apk/app-dev-debug.apk` (несколько минут).

- [ ] **Step 4: Проверка на устройстве — Android**

Эмулятор (на маке Дмитрия сеть до DEV медленная — если звонок не дозванивается, гонять на маке Александра, см. память «Эмулятор с быстрой сетью»; debug-сборка вешает эмулятор, поэтому `--profile`):

```bash
flutter emulators --launch Pixel_XL_API_33
~/Library/Android/sdk/platform-tools/adb -s emulator-5554 shell settings put system accelerometer_rotation 1
flutter run --profile --flavor dev -t lib/main_dev.dart --dart-define=FLAVOR=dev --dart-define=BASE_URL=https://staging.id.taler.tirol -d emulator-5554
# повернуть «телефон» на 90°: ~/Library/Android/sdk/platform-tools/adb -s emulator-5554 emu rotate
```

Войти `integration_test@taler-test.com` / `IntegrationTest123!`, позвонить `integration_test_2` (отвечать не нужно — экран звонка открыт уже на «Вызов…»). Отметить:

- [ ] в шапке звонка первым стоит значок поворота;
- [ ] повернуть → экран ложится набок, шапки нет, в правом верхнем углу круглая кнопка поворота, напротив стрелки «назад»;
- [ ] нажать её → экран сразу встаёт вертикально, в шапке значок замка цветом акцента;
- [ ] повернуть ещё раз → экран остаётся вертикальным;
- [ ] стрелка «назад» (свернуть) → снова войти в звонок с плашки → вертикально, замок на месте, поворот не срабатывает;
- [ ] завершить, позвонить снова → открывается вертикально, замок горит, поворот не срабатывает;
- [ ] нажать замок → значок поворота, поворот снова работает;
- [ ] вне звонка (чаты, профиль) приложение по-прежнему не поворачивается;
- [ ] долгое нажатие на кнопку показывает подсказку («Не поворачивать экран» / «Разрешить поворот экрана» в русской локали).

- [ ] **Step 5: Проверка на устройстве — iPhone**

```bash
flutter run --flavor dev -t lib/main_dev.dart --dart-define=FLAVOR=dev --dart-define=BASE_URL=https://staging.id.taler.tirol -d 00008101-000E21100202001E
```

Тот же список, что в Step 4 (блокировка ориентации в Пункте управления должна быть выключена — иначе звонок не поворачивается и без кнопки). Плюс голосом: в звонке включить ассистента → «не переворачивай экран» → значок в шапке меняется на замок; «разреши поворот» → обратно.

- [ ] **Step 6: Статус спеки**

В `docs/superpowers/specs/2026-10-31-call-rotation-lock-design.md` заменить строку

```markdown
**Статус:** проект утверждён 2026-10-31
```

на

```markdown
**Статус:** проект утверждён 2026-10-31, реализован в ветке `feat/call-rotation-lock`
```

Если в ходе реализации что-то разошлось со спекой — привести спеку к сделанному в этом же шаге.

- [ ] **Step 7: Commit**

```bash
git add docs/superpowers/specs/2026-10-31-call-rotation-lock-design.md
git commit -m "$(cat <<'EOF'
docs(звонок): спецификация фиксации поворота — реализовано

Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## После плана (не входит в задачи)

- Слияние ветки и релиз — через superpowers:finishing-a-development-branch и обычный мобильный порядок из `CLAUDE.md`: DEV → TEST → PROD, `APP_RELEASES` в бэкенде, заметки TestFlight без эмодзи. Объявлять версию — только когда выложены все платформы (память «Объявлять версию только после ВСЕХ платформ»).
- Перед деплоем — обязательная батарея из `CLAUDE.md`, для мобилки как минимум: №1 `flutter test`, №2 интеграционный UI-тест на эмуляторе, №3 звонок между двумя эмуляторами (он открывает этот самый экран звонка).

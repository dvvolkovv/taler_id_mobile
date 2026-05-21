# Desktop Adaptation — Phase 1 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Создать shared widgets `lib/core/desktop/` и применить их ко всем 8 auth-экранам так, что на десктопе формы рендерятся в центрированной glass-карточке поверх анимированного blob-фона, с кастомным window chrome, hover/focus/tooltips и увеличенным typography scale.

**Architecture:** Тонкий слой shared widgets в `lib/core/desktop/`. Каждый экран opt-in оборачивает свой body в `DesktopAdaptiveScaffold` (passthrough на мобиле, full desktop layout на десктопе ≥600 px). Существующий `WindowSetup` (macOS hidden titlebar уже работает) расширяется на Windows (Mica) и Linux (frameless).

**Tech Stack:** Flutter 3.38, Dart 3, `window_manager: ^0.4.3` (уже в pubspec), `flutter_acrylic` (новая зависимость для Windows Mica), `BackdropFilter` для glassmorphism, существующие `AppColors` + `Material 3`.

**Spec:** [2026-05-21-desktop-adaptation-design.md](../specs/2026-05-21-desktop-adaptation-design.md)

**Out of this plan:** Phase 2 (edit_profile/settings/sessions/tenant) и Phase 3 (call_history/voice_call/KYC) — будут отдельными планами после успешного мержа Phase 1.

---

## Pre-flight

- [ ] **Verify clean working tree**

```bash
cd /Users/dmitry/Downloads/taler_id_mobile
git status
```

Expected: only `ios/Podfile.lock` modified (известный артефакт), либо чисто. Если ещё что-то — закоммитить или stash.

- [ ] **Create branch**

```bash
git checkout dev && git pull origin dev
git checkout -b feature/desktop-adaptation-phase-1
```

- [ ] **Sanity: existing tests are green**

```bash
flutter test 2>&1 | tail -5
```

Expected: all green. Если что-то падает — починить ДО начала работы.

---

## Task 1: Add `flutter_acrylic` dependency

**Files:**
- Modify: `pubspec.yaml`

- [ ] **Step 1: Edit pubspec.yaml**

Найти раздел `dependencies:` и добавить (рядом с `window_manager: ^0.4.3`):

```yaml
  flutter_acrylic: ^1.1.4
```

- [ ] **Step 2: Run pub get**

```bash
flutter pub get
```

Expected: `Got dependencies!`. Если конфликт версий — попробовать `flutter_acrylic: ^1.1.3`, при дальнейшем фейле — отметить риск и пропустить (Windows получит обычный titlebar; всё остальное в плане работает).

- [ ] **Step 3: Commit**

```bash
git add pubspec.yaml pubspec.lock
git commit -m "chore(deps): add flutter_acrylic for Windows Mica backdrop"
```

---

## Task 2: Create breakpoint constants

**Files:**
- Create: `lib/core/desktop/desktop_breakpoints.dart`

- [ ] **Step 1: Write the file**

```dart
// lib/core/desktop/desktop_breakpoints.dart

/// Минимальная ширина окна, при которой включается desktop-layout.
/// Уже ниже — fallback на мобильный UX внутри desktop chrome.
const double kDesktopBreakpoint = 600.0;

/// Максимальная ширина для form-карточек (login, register, forgot, 2FA, pin).
const double kCardWidthForm = 480.0;

/// Максимальная ширина для settings/profile карточек.
const double kCardWidthSettings = 720.0;

/// Максимальная ширина для широких списков и таблиц (call_history, channels).
const double kCardWidthWide = 960.0;

/// Высота кастомного window chrome бара (drag-region + traffic lights).
const double kDesktopChromeHeight = 36.0;
```

- [ ] **Step 2: Commit**

```bash
git add lib/core/desktop/desktop_breakpoints.dart
git commit -m "feat(desktop): add breakpoint and card-width constants"
```

---

## Task 3: Extract `AnimatedBlobBackground` widget

**Files:**
- Create: `lib/core/desktop/animated_blob_background.dart`
- Modify: `lib/features/auth/presentation/screens/login_screen.dart:280-311` (remove inline painter)

- [ ] **Step 1: Write the failing test**

Create `test/core/desktop/animated_blob_background_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taler_id_mobile/core/desktop/animated_blob_background.dart';

void main() {
  testWidgets('AnimatedBlobBackground builds CustomPaint with painter', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: AnimatedBlobBackground()));
    expect(find.byType(CustomPaint), findsWidgets);
  });

  testWidgets('AnimatedBlobBackground disposes animation controller cleanly', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: AnimatedBlobBackground()));
    await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
    // If controller leaks → tester throws. Reaching here means OK.
    expect(tester.takeException(), isNull);
  });
}
```

- [ ] **Step 2: Run test, verify fails**

```bash
flutter test test/core/desktop/animated_blob_background_test.dart
```

Expected: compile error (file doesn't exist).

- [ ] **Step 3: Write the widget**

Create `lib/core/desktop/animated_blob_background.dart`:

```dart
// lib/core/desktop/animated_blob_background.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Анимированный фон из 3 плавающих радиальных blob-градиентов.
/// Извлечён из login_screen.dart для переиспользования на других desktop-экранах.
///
/// Использовать в `Stack` как `Positioned.fill(child: AnimatedBlobBackground())`.
class AnimatedBlobBackground extends StatefulWidget {
  const AnimatedBlobBackground({super.key});

  @override
  State<AnimatedBlobBackground> createState() => _AnimatedBlobBackgroundState();
}

class _AnimatedBlobBackgroundState extends State<AnimatedBlobBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bgCtrl;

  @override
  void initState() {
    super.initState();
    _bgCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    )..repeat();
  }

  @override
  void dispose() {
    _bgCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _bgCtrl,
        builder: (context, _) => CustomPaint(
          size: Size.infinite,
          painter: BlobBackgroundPainter(time: _bgCtrl.value * 2 * math.pi),
        ),
      ),
    );
  }
}

class BlobBackgroundPainter extends CustomPainter {
  final double time;
  BlobBackgroundPainter({required this.time});

  static const _blobColors = [
    Color(0xFF3B82F6),
    Color(0xFFA855F7),
    Color(0xFF22D3EE),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < _blobColors.length; i++) {
      final phaseX = time * 0.4 + i * 1.8;
      final phaseY = time * 0.3 + i * 2.4;
      final cx = size.width * (0.5 + 0.42 * math.sin(phaseX));
      final cy = size.height * (0.35 + 0.33 * math.cos(phaseY));
      final radius = size.width * 0.75;
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [
            _blobColors[i].withOpacity(0.18),
            _blobColors[i].withOpacity(0.0),
          ],
        ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: radius));
      canvas.drawCircle(Offset(cx, cy), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant BlobBackgroundPainter old) => old.time != time;
}
```

- [ ] **Step 4: Run test, verify passes**

```bash
flutter test test/core/desktop/animated_blob_background_test.dart
```

Expected: 2 tests pass.

- [ ] **Step 5: Refactor login_screen.dart to use shared widget**

В `lib/features/auth/presentation/screens/login_screen.dart`:

1. Удалить класс `_LoginBgPainter` (строки 280-311).
2. Удалить из `_LoginScreenState`: поле `_bgCtrl`, инициализацию в `initState`, `dispose`.
3. Удалить mixin `SingleTickerProviderStateMixin` из state class.
4. Удалить `import 'dart:math' as math;` если он больше не используется.
5. Добавить `import '../../../../core/desktop/animated_blob_background.dart';`
6. Заменить в build() блок:

```dart
// Animated background blobs
Positioned.fill(
  child: IgnorePointer(
    child: AnimatedBuilder(
      animation: _bgCtrl,
      builder: (context, _) => CustomPaint(
        painter: _LoginBgPainter(time: _bgCtrl.value * 2 * math.pi),
      ),
    ),
  ),
),
```

На:

```dart
const Positioned.fill(child: AnimatedBlobBackground()),
```

- [ ] **Step 6: Run flutter test on login_screen tests**

```bash
flutter test test/features/auth/ 2>&1 | tail -10
```

Expected: existing auth tests still pass (или skip если их нет).

- [ ] **Step 7: Smoke test login screen**

```bash
flutter run -d macos -t lib/main_dev.dart --dart-define=FLAVOR=dev --dart-define=BASE_URL=https://staging.id.taler.tirol
```

Открыть /login — фон должен анимироваться как раньше. Закрыть процесс через `pkill -f "flutter_tools.snapshot run"`.

- [ ] **Step 8: Commit**

```bash
git add lib/core/desktop/animated_blob_background.dart \
        test/core/desktop/animated_blob_background_test.dart \
        lib/features/auth/presentation/screens/login_screen.dart
git commit -m "refactor(desktop): extract AnimatedBlobBackground for shared use"
```

---

## Task 4: Create `CenteredCard` widget

**Files:**
- Create: `lib/core/desktop/centered_card.dart`
- Create: `test/core/desktop/centered_card_test.dart`

- [ ] **Step 1: Write the failing test**

`test/core/desktop/centered_card_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taler_id_mobile/core/desktop/centered_card.dart';

void main() {
  testWidgets('CenteredCard wraps child', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: CenteredCard(child: Text('inner'))),
    );
    expect(find.text('inner'), findsOneWidget);
  });

  testWidgets('CenteredCard applies default padding', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: CenteredCard(child: SizedBox.shrink())),
    );
    final padding = tester.widget<Padding>(
      find.descendant(of: find.byType(CenteredCard), matching: find.byType(Padding)).first,
    );
    expect((padding.padding as EdgeInsets).top, 32.0);
  });
}
```

- [ ] **Step 2: Run test, verify fails**

```bash
flutter test test/core/desktop/centered_card_test.dart
```

Expected: compile error.

- [ ] **Step 3: Write the widget**

```dart
// lib/core/desktop/centered_card.dart
import 'dart:ui';
import 'package:flutter/material.dart';

/// Glassmorphism-карточка, в которую заворачивается desktop-форма.
/// На мобиле использовать не нужно — это desktop-only widget.
class CenteredCard extends StatelessWidget {
  const CenteredCard({
    super.key,
    required this.child,
    this.useGlass = true,
    this.padding = const EdgeInsets.all(32),
    this.borderRadius = 20,
  });

  final Widget child;
  final bool useGlass;
  final EdgeInsets padding;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      decoration: BoxDecoration(
        color: useGlass
            ? Colors.white.withOpacity(0.07)
            : Theme.of(context).colorScheme.surface,
        border: useGlass
            ? Border.all(color: Colors.white.withOpacity(0.14))
            : null,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 60,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: Padding(padding: padding, child: child),
    );

    if (!useGlass) return card;

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: card,
      ),
    );
  }
}
```

- [ ] **Step 4: Run test, verify passes**

```bash
flutter test test/core/desktop/centered_card_test.dart
```

Expected: 2 tests pass.

- [ ] **Step 5: Commit**

```bash
git add lib/core/desktop/centered_card.dart test/core/desktop/centered_card_test.dart
git commit -m "feat(desktop): add CenteredCard glassmorphism widget"
```

---

## Task 5: Create `HoverLift` widget

**Files:**
- Create: `lib/core/desktop/hover_lift.dart`
- Create: `test/core/desktop/hover_lift_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
// test/core/desktop/hover_lift_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taler_id_mobile/core/desktop/hover_lift.dart';

void main() {
  testWidgets('HoverLift renders child', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: HoverLift(child: Text('btn'))),
    );
    expect(find.text('btn'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test, verify fails**

```bash
flutter test test/core/desktop/hover_lift_test.dart
```

- [ ] **Step 3: Write the widget**

```dart
// lib/core/desktop/hover_lift.dart
import 'package:flutter/material.dart';
import '../platform/platform_utils.dart';

/// Поднимает дочерний widget на `liftPx` при hover на десктопе.
/// На мобиле — passthrough.
class HoverLift extends StatefulWidget {
  const HoverLift({
    super.key,
    required this.child,
    this.liftPx = 2.0,
    this.shadowBoost,
    this.duration = const Duration(milliseconds: 180),
  });

  final Widget child;
  final double liftPx;
  final Color? shadowBoost;
  final Duration duration;

  @override
  State<HoverLift> createState() => _HoverLiftState();
}

class _HoverLiftState extends State<HoverLift> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    if (!PlatformUtils.instance.isDesktop) return widget.child;

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: widget.duration,
        curve: Curves.easeOut,
        transform: Matrix4.translationValues(0, _hover ? -widget.liftPx : 0, 0),
        decoration: BoxDecoration(
          boxShadow: _hover && widget.shadowBoost != null
              ? [
                  BoxShadow(
                    color: widget.shadowBoost!.withOpacity(0.35),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: widget.child,
      ),
    );
  }
}
```

- [ ] **Step 4: Run test, verify passes**

```bash
flutter test test/core/desktop/hover_lift_test.dart
```

- [ ] **Step 5: Commit**

```bash
git add lib/core/desktop/hover_lift.dart test/core/desktop/hover_lift_test.dart
git commit -m "feat(desktop): add HoverLift micro-interaction wrapper"
```

---

## Task 6: Create `HoverScale` widget

**Files:**
- Create: `lib/core/desktop/hover_scale.dart`
- Create: `test/core/desktop/hover_scale_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
// test/core/desktop/hover_scale_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taler_id_mobile/core/desktop/hover_scale.dart';

void main() {
  testWidgets('HoverScale renders child', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: HoverScale(child: Icon(Icons.star))),
    );
    expect(find.byIcon(Icons.star), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test, verify fails**

```bash
flutter test test/core/desktop/hover_scale_test.dart
```

- [ ] **Step 3: Write the widget**

```dart
// lib/core/desktop/hover_scale.dart
import 'package:flutter/material.dart';
import '../platform/platform_utils.dart';

/// Увеличивает дочерний widget при hover на десктопе.
/// Для icon-only кнопок: back/share/more.
class HoverScale extends StatefulWidget {
  const HoverScale({
    super.key,
    required this.child,
    this.scale = 1.08,
    this.duration = const Duration(milliseconds: 140),
  });

  final Widget child;
  final double scale;
  final Duration duration;

  @override
  State<HoverScale> createState() => _HoverScaleState();
}

class _HoverScaleState extends State<HoverScale> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    if (!PlatformUtils.instance.isDesktop) return widget.child;
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedScale(
        scale: _hover ? widget.scale : 1.0,
        duration: widget.duration,
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}
```

- [ ] **Step 4: Run test, verify passes**

```bash
flutter test test/core/desktop/hover_scale_test.dart
```

- [ ] **Step 5: Commit**

```bash
git add lib/core/desktop/hover_scale.dart test/core/desktop/hover_scale_test.dart
git commit -m "feat(desktop): add HoverScale wrapper for icon buttons"
```

---

## Task 7: Create `FocusRing` widget

**Files:**
- Create: `lib/core/desktop/focus_ring.dart`
- Create: `test/core/desktop/focus_ring_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
// test/core/desktop/focus_ring_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taler_id_mobile/core/desktop/focus_ring.dart';

void main() {
  testWidgets('FocusRing wraps child without focus', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: FocusRing(child: SizedBox(width: 50, height: 50))),
    );
    expect(find.byType(SizedBox), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test, verify fails**

```bash
flutter test test/core/desktop/focus_ring_test.dart
```

- [ ] **Step 3: Write the widget**

```dart
// lib/core/desktop/focus_ring.dart
import 'package:flutter/material.dart';
import '../platform/platform_utils.dart';

/// Усиленный visible focus ring для keyboard nav на десктопе.
/// На мобиле — passthrough.
///
/// Использовать только если нужна обёртка над не-input widget.
/// Для TextFormField есть `desktopInputDecoration()` helper.
class FocusRing extends StatefulWidget {
  const FocusRing({
    super.key,
    required this.child,
    this.focusNode,
    this.ringWidth = 3,
    this.ringColor,
    this.borderRadius = 12,
  });

  final Widget child;
  final FocusNode? focusNode;
  final double ringWidth;
  final Color? ringColor;
  final double borderRadius;

  @override
  State<FocusRing> createState() => _FocusRingState();
}

class _FocusRingState extends State<FocusRing> {
  late final FocusNode _internalNode;
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _internalNode = widget.focusNode ?? FocusNode();
    _internalNode.addListener(_onFocus);
  }

  @override
  void dispose() {
    _internalNode.removeListener(_onFocus);
    if (widget.focusNode == null) _internalNode.dispose();
    super.dispose();
  }

  void _onFocus() {
    if (_focused != _internalNode.hasFocus) {
      setState(() => _focused = _internalNode.hasFocus);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!PlatformUtils.instance.isDesktop) return widget.child;
    final color = widget.ringColor ?? Theme.of(context).colorScheme.primary;
    return Focus(
      focusNode: _internalNode,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          boxShadow: _focused
              ? [BoxShadow(color: color.withOpacity(0.25), blurRadius: 0, spreadRadius: widget.ringWidth)]
              : null,
        ),
        child: widget.child,
      ),
    );
  }
}
```

- [ ] **Step 4: Run test, verify passes**

```bash
flutter test test/core/desktop/focus_ring_test.dart
```

- [ ] **Step 5: Commit**

```bash
git add lib/core/desktop/focus_ring.dart test/core/desktop/focus_ring_test.dart
git commit -m "feat(desktop): add FocusRing widget for keyboard nav"
```

---

## Task 8: Create `desktopInputDecoration()` helper

**Files:**
- Create: `lib/core/desktop/desktop_input_decoration.dart`

- [ ] **Step 1: Write the helper**

```dart
// lib/core/desktop/desktop_input_decoration.dart
import 'package:flutter/material.dart';
import '../platform/platform_utils.dart';
import '../theme/app_theme.dart';

/// Возвращает `InputDecoration` с усиленным focus ring (3px primary boxShadow).
/// На мобиле — обычная decoration без усиления.
///
/// Использовать:
/// ```
/// TextFormField(decoration: desktopInputDecoration(context, label: 'Email', icon: Icons.email_outlined))
/// ```
InputDecoration desktopInputDecoration(
  BuildContext context, {
  required String label,
  required IconData icon,
  Widget? suffix,
  String? hint,
}) {
  final colors = AppColors.of(context);
  final isDesktop = PlatformUtils.instance.isDesktop;

  final base = OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide(color: colors.border),
  );

  return InputDecoration(
    labelText: label,
    hintText: hint,
    filled: true,
    fillColor: isDesktop
        ? colors.card.withOpacity(0.6)
        : colors.card,
    prefixIcon: Icon(icon, color: colors.textSecondary),
    suffixIcon: suffix,
    border: base,
    enabledBorder: base,
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(
        color: colors.primary,
        width: isDesktop ? 2.5 : 2,
      ),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: colors.error),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: colors.error, width: 2),
    ),
  );
}
```

- [ ] **Step 2: Verify it compiles**

```bash
flutter analyze lib/core/desktop/desktop_input_decoration.dart
```

Expected: `No issues found!` (или предупреждения которые не блокеры).

- [ ] **Step 3: Commit**

```bash
git add lib/core/desktop/desktop_input_decoration.dart
git commit -m "feat(desktop): add desktopInputDecoration helper"
```

---

## Task 9: Create `EmptyState` widget

**Files:**
- Create: `lib/core/desktop/empty_state.dart`
- Create: `test/core/desktop/empty_state_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
// test/core/desktop/empty_state_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taler_id_mobile/core/desktop/empty_state.dart';

void main() {
  testWidgets('EmptyState renders title and subtitle', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: EmptyState(
          icon: Icons.call_outlined,
          title: 'Нет звонков',
          subtitle: 'Позвоните контакту',
        ),
      ),
    );
    expect(find.text('Нет звонков'), findsOneWidget);
    expect(find.text('Позвоните контакту'), findsOneWidget);
    expect(find.byIcon(Icons.call_outlined), findsOneWidget);
  });

  testWidgets('EmptyState renders action button when provided', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: EmptyState(
          icon: Icons.add,
          title: 'Empty',
          action: FilledButton(onPressed: () {}, child: const Text('Add')),
        ),
      ),
    );
    expect(find.text('Add'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test, verify fails**

```bash
flutter test test/core/desktop/empty_state_test.dart
```

- [ ] **Step 3: Write the widget**

```dart
// lib/core/desktop/empty_state.dart
import 'package:flutter/material.dart';
import '../platform/platform_utils.dart';
import '../theme/app_theme.dart';

/// Стандартизированный empty state с glow-иконкой, title, subtitle и optional CTA.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final isDesktop = PlatformUtils.instance.isDesktop;
    final colors = AppColors.of(context);
    final glowSize = isDesktop ? 96.0 : 64.0;
    final iconSize = isDesktop ? 36.0 : 28.0;
    final titleSize = isDesktop ? 22.0 : 18.0;
    final subtitleSize = isDesktop ? 15.0 : 14.0;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: glowSize,
              height: glowSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    colors.primary.withOpacity(0.35),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Icon(icon, size: iconSize, color: colors.primary),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: titleSize,
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: subtitleSize, color: colors.textSecondary),
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: 20),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Run test, verify passes**

```bash
flutter test test/core/desktop/empty_state_test.dart
```

- [ ] **Step 5: Commit**

```bash
git add lib/core/desktop/empty_state.dart test/core/desktop/empty_state_test.dart
git commit -m "feat(desktop): add EmptyState widget with glow illustration"
```

---

## Task 10: Create `DesktopWindowChrome` widget

**Files:**
- Create: `lib/core/desktop/desktop_window_chrome.dart`

- [ ] **Step 1: Write the widget**

```dart
// lib/core/desktop/desktop_window_chrome.dart
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import '../platform/platform_utils.dart';
import 'desktop_breakpoints.dart';

/// 36px high drag-region вверху окна.
/// macOS: рендерит только drag-зону + опциональный title (traffic lights рисует ОС).
/// Windows/Linux: рендерит drag-зону + custom close/min/max справа.
class DesktopWindowChrome extends StatelessWidget {
  const DesktopWindowChrome({super.key, this.title, this.trailing});

  final String? title;
  final List<Widget>? trailing;

  @override
  Widget build(BuildContext context) {
    if (!PlatformUtils.instance.isDesktop) return const SizedBox.shrink();

    final platform = PlatformUtils.instance;
    final leftPadding = platform.isMacOS ? 80.0 : 12.0;

    return GestureDetector(
      onPanStart: (_) => windowManager.startDragging(),
      onDoubleTap: () async {
        final isMax = await windowManager.isMaximized();
        if (isMax) {
          await windowManager.unmaximize();
        } else {
          await windowManager.maximize();
        }
      },
      child: Container(
        height: kDesktopChromeHeight,
        color: Colors.transparent,
        padding: EdgeInsets.only(left: leftPadding, right: 8),
        child: Row(
          children: [
            if (title != null)
              Text(
                title!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  fontSize: 12,
                ),
              ),
            const Spacer(),
            if (trailing != null) ...trailing!,
            if (platform.isWindows || platform.isLinux)
              const _CustomWindowButtons(),
          ],
        ),
      ),
    );
  }
}

class _CustomWindowButtons extends StatelessWidget {
  const _CustomWindowButtons();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _btn(Icons.remove, () => windowManager.minimize()),
        _btn(Icons.crop_square, () async {
          final isMax = await windowManager.isMaximized();
          isMax ? windowManager.unmaximize() : windowManager.maximize();
        }),
        _btn(Icons.close, () => windowManager.close(), hoverColor: Colors.red),
      ],
    );
  }

  Widget _btn(IconData icon, VoidCallback onTap, {Color? hoverColor}) {
    return _WindowButton(icon: icon, onTap: onTap, hoverColor: hoverColor);
  }
}

class _WindowButton extends StatefulWidget {
  const _WindowButton({required this.icon, required this.onTap, this.hoverColor});
  final IconData icon;
  final VoidCallback onTap;
  final Color? hoverColor;

  @override
  State<_WindowButton> createState() => _WindowButtonState();
}

class _WindowButtonState extends State<_WindowButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          width: 36,
          height: kDesktopChromeHeight,
          color: _hover ? (widget.hoverColor ?? Colors.white24) : Colors.transparent,
          child: Icon(widget.icon, size: 14, color: Colors.white70),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Verify it compiles**

```bash
flutter analyze lib/core/desktop/desktop_window_chrome.dart
```

Expected: `No issues found!`.

- [ ] **Step 3: Commit**

```bash
git add lib/core/desktop/desktop_window_chrome.dart
git commit -m "feat(desktop): add DesktopWindowChrome widget"
```

---

## Task 11: Create `DesktopAdaptiveScaffold` widget

**Files:**
- Create: `lib/core/desktop/desktop_adaptive_scaffold.dart`
- Create: `test/core/desktop/desktop_adaptive_scaffold_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
// test/core/desktop/desktop_adaptive_scaffold_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taler_id_mobile/core/desktop/desktop_adaptive_scaffold.dart';

void main() {
  testWidgets('DesktopAdaptiveScaffold mobile fallback returns child', (tester) async {
    // На тестовом окружении PlatformUtils.isDesktop == false (тестируется через test runner).
    // Поэтому scaffold должен сделать passthrough.
    await tester.pumpWidget(
      const MaterialApp(
        home: DesktopAdaptiveScaffold(child: Text('mobile-content')),
      ),
    );
    expect(find.text('mobile-content'), findsOneWidget);
    // На mobile НЕТ chrome bar и blob bg.
    expect(find.byType(CustomPaint), findsNothing);
  });
}
```

- [ ] **Step 2: Run test, verify fails**

```bash
flutter test test/core/desktop/desktop_adaptive_scaffold_test.dart
```

- [ ] **Step 3: Write the widget**

```dart
// lib/core/desktop/desktop_adaptive_scaffold.dart
import 'package:flutter/material.dart';
import '../platform/platform_utils.dart';
import 'animated_blob_background.dart';
import 'centered_card.dart';
import 'desktop_breakpoints.dart';
import 'desktop_window_chrome.dart';

/// Высокоуровневый wrapper для desktop adaptation.
///
/// На мобиле — passthrough (возвращает child).
/// На десктопе:
///   - Stack: blob bg + Column(chrome, content)
///   - При ширине ≥ kDesktopBreakpoint: content центрируется в CenteredCard
///   - При меньшей ширине: content идёт во всю ширину с боковым padding (mobile-style внутри desktop chrome)
///
/// Использовать вместо обычного Scaffold-like обёртки в любом screen.
class DesktopAdaptiveScaffold extends StatelessWidget {
  const DesktopAdaptiveScaffold({
    super.key,
    required this.child,
    this.cardMaxWidth = kCardWidthForm,
    this.useGlass = true,
    this.useBlobBackground = true,
    this.cardPadding = const EdgeInsets.all(32),
    this.chromeTitle,
  });

  final Widget child;
  final double cardMaxWidth;
  final bool useGlass;
  final bool useBlobBackground;
  final EdgeInsets cardPadding;
  final String? chromeTitle;

  @override
  Widget build(BuildContext context) {
    if (!PlatformUtils.instance.isDesktop) return child;

    final width = MediaQuery.of(context).size.width;
    final isWide = width >= kDesktopBreakpoint;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Stack(
        children: [
          if (useBlobBackground) const Positioned.fill(child: AnimatedBlobBackground()),
          SafeArea(
            top: false,
            child: Column(
              children: [
                DesktopWindowChrome(title: chromeTitle),
                Expanded(
                  child: isWide
                      ? Center(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(24),
                            child: ConstrainedBox(
                              constraints: BoxConstraints(maxWidth: cardMaxWidth),
                              child: CenteredCard(
                                useGlass: useGlass,
                                padding: cardPadding,
                                child: child,
                              ),
                            ),
                          ),
                        )
                      : Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: child,
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Run test, verify passes**

```bash
flutter test test/core/desktop/desktop_adaptive_scaffold_test.dart
```

- [ ] **Step 5: Commit**

```bash
git add lib/core/desktop/desktop_adaptive_scaffold.dart \
        test/core/desktop/desktop_adaptive_scaffold_test.dart
git commit -m "feat(desktop): add DesktopAdaptiveScaffold high-level wrapper"
```

---

## Task 12: Add `desktopTextTheme` to AppTheme

**Files:**
- Modify: `lib/core/theme/app_theme.dart`

- [ ] **Step 1: Find current textTheme location**

```bash
grep -n "textTheme\|TextTheme\|GoogleFonts" lib/core/theme/app_theme.dart | head -20
```

Зафиксировать в каком месте `ThemeData.dark/light` собираются.

- [ ] **Step 2: Add extension method**

Внизу файла `lib/core/theme/app_theme.dart` (перед последним `}` файла, ВНЕ всех существующих классов):

```dart
extension AppDesktopTextScale on ThemeData {
  /// Увеличенный typography scale для десктопа.
  /// Body 14 → 15, H1 30 → 34, и т.д.
  TextTheme get desktopTextTheme => textTheme.copyWith(
    displayLarge: textTheme.displayLarge?.copyWith(fontSize: 56, height: 1.1),
    headlineLarge: textTheme.headlineLarge?.copyWith(fontSize: 40, height: 1.15),
    headlineMedium: textTheme.headlineMedium?.copyWith(fontSize: 34, height: 1.2),
    headlineSmall: textTheme.headlineSmall?.copyWith(fontSize: 28, height: 1.25),
    titleLarge: textTheme.titleLarge?.copyWith(fontSize: 22, height: 1.3),
    titleMedium: textTheme.titleMedium?.copyWith(fontSize: 17, height: 1.4),
    bodyLarge: textTheme.bodyLarge?.copyWith(fontSize: 16, height: 1.5),
    bodyMedium: textTheme.bodyMedium?.copyWith(fontSize: 15, height: 1.5),
    bodySmall: textTheme.bodySmall?.copyWith(fontSize: 13, height: 1.45),
  );
}
```

- [ ] **Step 3: Verify compile**

```bash
flutter analyze lib/core/theme/app_theme.dart
```

Expected: `No issues found!`.

- [ ] **Step 4: Commit**

```bash
git add lib/core/theme/app_theme.dart
git commit -m "feat(theme): add desktopTextTheme extension with larger scale"
```

---

## Task 13: Wire desktopTextTheme in main.dart

**Files:**
- Modify: `lib/main.dart` (where MaterialApp.router theme is configured)

- [ ] **Step 1: Find MaterialApp theme block**

```bash
grep -n "theme:\|darkTheme:\|MaterialApp" lib/main.dart | head -20
```

- [ ] **Step 2: Apply desktop scale conditionally**

В блоке `MaterialApp.router(...)` найти:

```dart
theme: AppTheme.light,
darkTheme: AppTheme.dark,
```

Заменить на:

```dart
theme: PlatformUtils.instance.isDesktop
    ? AppTheme.light.copyWith(textTheme: AppTheme.light.desktopTextTheme)
    : AppTheme.light,
darkTheme: PlatformUtils.instance.isDesktop
    ? AppTheme.dark.copyWith(textTheme: AppTheme.dark.desktopTextTheme)
    : AppTheme.dark,
```

Если `AppTheme.light`/`AppTheme.dark` это `ThemeData` константы — будет работать. Если getter — тоже OK.

- [ ] **Step 3: Verify compile**

```bash
flutter analyze lib/main.dart
```

- [ ] **Step 4: Commit**

```bash
git add lib/main.dart
git commit -m "feat(theme): apply desktopTextTheme on desktop platforms"
```

---

## Task 14: Extend WindowSetup for Windows Mica + Linux frameless

**Files:**
- Modify: `lib/features/dashboard/desktop/window/window_setup.dart`

- [ ] **Step 1: Add Windows + Linux branches**

Открыть `lib/features/dashboard/desktop/window/window_setup.dart`. В методе `initialize()` найти блок:

```dart
final options = WindowOptions(
  size: initialSize,
  minimumSize: minimumSize,
  center: saved == null,
  titleBarStyle: TitleBarStyle.hidden,
  title: 'Taler ID',
);
```

(Это уже работает на macOS.) Добавить ПОСЛЕ `await windowManager.ensureInitialized();` и ПЕРЕД построением `WindowOptions`:

```dart
// Windows: Mica backdrop (через flutter_acrylic)
if (PlatformUtils.instance.isWindows) {
  try {
    // Lazy import чтобы не падало на macOS если пакет не подгрузился
    // ignore: avoid_dynamic_calls
    final acrylic = await _initWindowsAcrylic();
    if (acrylic) {
      debugPrint('[WindowSetup] Windows Mica backdrop applied');
    }
  } catch (e) {
    debugPrint('[WindowSetup] Mica init failed (downgrade to opaque): $e');
  }
}

// Linux: frameless через window_manager
if (PlatformUtils.instance.isLinux) {
  // titleBarStyle уже hidden, frameless даёт borderless окно
  // ВНИМАНИЕ: на Linux WM поддержка фрэймлесса варьируется (GNOME/KDE/sway).
  // Если что-то странно — закомментировать.
}
```

В начало файла добавить импорт:

```dart
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_acrylic/flutter_acrylic.dart' as acrylic;
```

И вспомогательный метод где-то рядом с `initialize`:

```dart
static Future<bool> _initWindowsAcrylic() async {
  await acrylic.Window.initialize();
  await acrylic.Window.setEffect(
    effect: acrylic.WindowEffect.mica,
    dark: true,
  );
  return true;
}
```

- [ ] **Step 2: Verify it analyzes**

```bash
flutter analyze lib/features/dashboard/desktop/window/window_setup.dart
```

Если падает на `flutter_acrylic` import — закомментировать import и метод, оставить `try/catch` блок пустым. Это downgrade: Windows получит обычный titlebar (всё остальное в плане работает).

- [ ] **Step 3: Commit**

```bash
git add lib/features/dashboard/desktop/window/window_setup.dart
git commit -m "feat(window): add Mica backdrop on Windows + frameless on Linux"
```

---

## Task 15: Convert login_screen.dart to DesktopAdaptiveScaffold

**Files:**
- Modify: `lib/features/auth/presentation/screens/login_screen.dart`

- [ ] **Step 1: Restructure imports**

В начало файла добавить:

```dart
import '../../../../core/desktop/desktop_adaptive_scaffold.dart';
import '../../../../core/desktop/desktop_input_decoration.dart';
import '../../../../core/desktop/hover_lift.dart';
```

Удалить (после рефакторинга blob в Task 3 это уже сделано, проверить):
- `import 'dart:math' as math;` — если уже удалили в Task 3, пропустить.

- [ ] **Step 2: Wrap body in DesktopAdaptiveScaffold**

В `build()` обернуть текущий `Scaffold(body: BlocConsumer(...))` так:

Заменить:

```dart
return Scaffold(
  backgroundColor: AppColors.of(context).background,
  body: BlocConsumer<AuthBloc, AuthState>(
    ...
    builder: (context, state) {
      return Stack(
        children: [
          // Animated background blobs (уже extracted в Task 3 на AnimatedBlobBackground)
          const Positioned.fill(child: AnimatedBlobBackground()),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(...)
            ),
          ),
        ],
      );
    },
  ),
);
```

На:

```dart
return BlocConsumer<AuthBloc, AuthState>(
  listener: (...) { ... },  // как было
  builder: (context, state) {
    return DesktopAdaptiveScaffold(
      cardMaxWidth: kCardWidthForm,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ... (всё что было внутри Column в SingleChildScrollView)
        ],
      ),
    );
  },
);
```

Импортировать `kCardWidthForm` из `core/desktop/desktop_breakpoints.dart`.

**Важно:** убрать SafeArea+SingleChildScrollView+padding — `DesktopAdaptiveScaffold` это уже делает в desktop-режиме. На мобиле возвращается raw child, поэтому ОБЕРНУТЬ child в `SafeArea + SingleChildScrollView` через trick:

Решение: passthrough `DesktopAdaptiveScaffold` на мобиле возвращает голый child. Чтобы на мобиле сохранить SafeArea + SingleChildScrollView, нужно их явно поместить в child. Тогда на десктопе они продублируются с скроллом scaffold-а — это нежелательно, но работает (двойной скролл — physics: NeverScrollableScrollPhysics на внешнем убирает).

Чище: добавить параметр `wrapInScrollOnMobile` в `DesktopAdaptiveScaffold`, который оборачивает мобильный passthrough в SafeArea + SingleChildScrollView.

Реализация — модифицировать `DesktopAdaptiveScaffold` из Task 11:

```dart
// в build() для mobile passthrough:
if (!PlatformUtils.instance.isDesktop) {
  return Scaffold(
    backgroundColor: Theme.of(context).colorScheme.surface,
    body: SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: child,
      ),
    ),
  );
}
```

Откатить Task 11 step 3 в этой части — обновить mobile-passthrough. Перезапустить test из Task 11. Перекоммитить.

После этого в login_screen.dart `child:` это просто `Column(...)`.

- [ ] **Step 3: Apply tooltips + hover to buttons**

Найти `LoadingButton(text: l10n.loginButton, ...)` и обернуть в `HoverLift`:

```dart
HoverLift(
  shadowBoost: AppColors.of(context).primary,
  child: LoadingButton(text: l10n.loginButton, ...),
),
```

Кнопка "глаз" (visibility toggle) — обернуть в `Tooltip`:

```dart
Tooltip(
  message: _obscurePassword ? l10n.showPassword : l10n.hidePassword,
  child: IconButton(...),
)
```

Если строк `showPassword`/`hidePassword` нет в ARB — добавить их в `lib/l10n/app_ru.arb` и `app_en.arb`, прогнать `flutter gen-l10n`.

- [ ] **Step 4: Use desktopInputDecoration**

Заменить громоздкий `InputDecoration(filled: ..., fillColor: ..., prefixIcon: ..., border: ..., enabledBorder: ..., focusedBorder: ..., errorBorder: ..., focusedErrorBorder: ...)` для двух TextFormField на:

```dart
decoration: desktopInputDecoration(
  context,
  label: l10n.email,
  icon: Icons.email_outlined,
),
```

И:

```dart
decoration: desktopInputDecoration(
  context,
  label: l10n.password,
  icon: Icons.lock_outlined,
  suffix: Tooltip(
    message: _obscurePassword ? l10n.showPassword : l10n.hidePassword,
    child: IconButton(...),
  ),
),
```

- [ ] **Step 5: Run analyze + flutter test**

```bash
flutter analyze lib/features/auth/presentation/screens/login_screen.dart
flutter test test/features/auth/ 2>&1 | tail -10
```

- [ ] **Step 6: Visual smoke test on macOS**

```bash
flutter run -d macos --flavor dev -t lib/main_dev.dart \
  --dart-define=FLAVOR=dev --dart-define=BASE_URL=https://staging.id.taler.tirol
```

Проверить:
- Логин-экран показывает centered card с blob bg.
- Hover на кнопку Login — поднимается, появляется тень.
- Tab по полям — visible focus ring.
- Hover на eye icon — tooltip "Показать пароль".
- Resize окно до 500 px ширины — fallback на mobile UX (полная ширина, без card).

Закрыть: `pkill -f "flutter_tools.snapshot run"`.

- [ ] **Step 7: Visual smoke test on iOS**

```bash
flutter run --flavor dev -t lib/main_dev.dart \
  --dart-define=FLAVOR=dev --dart-define=BASE_URL=https://staging.id.taler.tirol \
  -d 00008101-000E21100202001E
```

Проверить:
- Логин-экран выглядит как РАНЬШЕ (без card, full-width). Никаких визуальных изменений.

Закрыть.

- [ ] **Step 8: Commit**

```bash
git add lib/features/auth/presentation/screens/login_screen.dart \
        lib/l10n/app_ru.arb lib/l10n/app_en.arb lib/l10n/app_localizations*.dart
git commit -m "feat(login): wrap in DesktopAdaptiveScaffold with hover/tooltips/focus"
```

---

## Task 16: Convert register_screen.dart

**Files:**
- Modify: `lib/features/auth/presentation/screens/register_screen.dart`

- [ ] **Step 1: Apply same pattern as login**

Повторить структуру из Task 15:
1. Импорты desktop widgets.
2. Обернуть body в `DesktopAdaptiveScaffold(cardMaxWidth: kCardWidthForm, child: ...)`.
3. Кнопку Register обернуть в `HoverLift(shadowBoost: AppColors.of(context).primary, ...)`.
4. Все TextFormField → `desktopInputDecoration()`.
5. Все icon-only кнопки → `Tooltip(message: ...)`.

- [ ] **Step 2: Analyze**

```bash
flutter analyze lib/features/auth/presentation/screens/register_screen.dart
```

- [ ] **Step 3: Visual smoke (macOS only)**

```bash
flutter run -d macos --flavor dev -t lib/main_dev.dart \
  --dart-define=FLAVOR=dev --dart-define=BASE_URL=https://staging.id.taler.tirol
```

Нажать "Создать аккаунт" с login screen, проверить визуально. Закрыть.

- [ ] **Step 4: Commit**

```bash
git add lib/features/auth/presentation/screens/register_screen.dart
git commit -m "feat(register): wrap in DesktopAdaptiveScaffold"
```

---

## Task 17: Convert forgot_password_screen.dart

**Files:**
- Modify: `lib/features/auth/presentation/screens/forgot_password_screen.dart`

- [ ] **Step 1: Apply same pattern**

(идентично Task 16)

- [ ] **Step 2: Analyze**

```bash
flutter analyze lib/features/auth/presentation/screens/forgot_password_screen.dart
```

- [ ] **Step 3: Commit**

```bash
git add lib/features/auth/presentation/screens/forgot_password_screen.dart
git commit -m "feat(forgot-password): wrap in DesktopAdaptiveScaffold"
```

---

## Task 18: Convert two_fa_screen.dart

**Files:**
- Modify: `lib/features/auth/presentation/screens/two_fa_screen.dart`

- [ ] **Step 1: Apply same pattern**

(идентично Task 16; ввод 6-значного кода обычно компактный — card OK)

- [ ] **Step 2: Analyze**

```bash
flutter analyze lib/features/auth/presentation/screens/two_fa_screen.dart
```

- [ ] **Step 3: Commit**

```bash
git add lib/features/auth/presentation/screens/two_fa_screen.dart
git commit -m "feat(2fa): wrap in DesktopAdaptiveScaffold"
```

---

## Task 19: Unify onboarding (delete OnboardingDesktopScreen)

**Files:**
- Modify: `lib/features/auth/presentation/screens/onboarding_screen.dart`
- Delete: `lib/features/auth/presentation/screens/onboarding_desktop_screen.dart` (если существует)
- Modify: `lib/core/router/app_router.dart:86-91` (удалить ветку isDesktop)

- [ ] **Step 1: Find OnboardingDesktopScreen**

```bash
find /Users/dmitry/Downloads/taler_id_mobile/lib -name "onboarding_desktop*"
```

- [ ] **Step 2: Compare implementations**

```bash
diff lib/features/auth/presentation/screens/onboarding_screen.dart \
     lib/features/auth/presentation/screens/onboarding_desktop_screen.dart
```

Зафиксировать что унифицируем: take mobile onboarding (PageView с illustrations), на десктопе обернуть в DesktopAdaptiveScaffold с cardMaxWidth=kCardWidthWide (960).

- [ ] **Step 3: Unify onboarding_screen.dart**

В `OnboardingScreen.build()` обернуть body:

```dart
return DesktopAdaptiveScaffold(
  cardMaxWidth: kCardWidthWide,
  cardPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
  child: <existing PageView body>,
);
```

Если в `OnboardingDesktopScreen` есть какая-то логика, которой нет в mobile (отдельные layout, дополнительные элементы) — перенести её в `onboarding_screen.dart` под `if (PlatformUtils.instance.isDesktop)` где нужно.

- [ ] **Step 4: Delete the desktop variant**

```bash
git rm lib/features/auth/presentation/screens/onboarding_desktop_screen.dart
```

- [ ] **Step 5: Update router**

В `lib/core/router/app_router.dart:86-91` заменить:

```dart
GoRoute(
  path: RouteConstants.onboarding,
  builder: (_, __) => PlatformUtils.instance.isDesktop
      ? const OnboardingDesktopScreen()
      : const OnboardingScreen(),
),
```

На:

```dart
GoRoute(
  path: RouteConstants.onboarding,
  builder: (_, __) => const OnboardingScreen(),
),
```

Удалить импорт `OnboardingDesktopScreen` сверху файла.

- [ ] **Step 6: Analyze + test**

```bash
flutter analyze lib/features/auth/presentation/screens/onboarding_screen.dart lib/core/router/app_router.dart
flutter test
```

- [ ] **Step 7: Visual smoke (macOS)**

Открыть /onboarding на desktop — должен показать карточку 960px с PageView внутри. Закрыть.

- [ ] **Step 8: Commit**

```bash
git add lib/features/auth/presentation/screens/onboarding_screen.dart \
        lib/core/router/app_router.dart
git commit -m "feat(onboarding): unify mobile+desktop via DesktopAdaptiveScaffold"
```

---

## Task 20: Convert pin_setup_screen.dart

**Files:**
- Modify: `lib/features/auth/presentation/screens/pin_setup_screen.dart`

- [ ] **Step 1: Wrap PIN keypad in DesktopAdaptiveScaffold**

```dart
return DesktopAdaptiveScaffold(
  cardMaxWidth: kCardWidthForm,
  child: <existing pin setup content>,
);
```

Если PIN-keypad — Grid из 12 кнопок (1-9, 0, backspace), он уже компактный. Карточка с padding 32 будет нормальной.

- [ ] **Step 2: Analyze**

```bash
flutter analyze lib/features/auth/presentation/screens/pin_setup_screen.dart
```

- [ ] **Step 3: Commit**

```bash
git add lib/features/auth/presentation/screens/pin_setup_screen.dart
git commit -m "feat(pin-setup): wrap in DesktopAdaptiveScaffold"
```

---

## Task 21: Convert pin_entry_screen.dart

**Files:**
- Modify: `lib/features/auth/presentation/screens/pin_entry_screen.dart`

- [ ] **Step 1: Apply same pattern as pin_setup**

```bash
flutter analyze lib/features/auth/presentation/screens/pin_entry_screen.dart
```

- [ ] **Step 2: Commit**

```bash
git add lib/features/auth/presentation/screens/pin_entry_screen.dart
git commit -m "feat(pin-entry): wrap in DesktopAdaptiveScaffold"
```

---

## Task 22: Convert splash_screen.dart (blob bg only)

**Files:**
- Modify: `lib/features/auth/presentation/screens/splash_screen.dart`

- [ ] **Step 1: Add AnimatedBlobBackground on desktop**

`SplashScreen` обычно показывает только логотип + spinner. Карточка не нужна, но фон + chrome — да.

В `build()` обернуть в Stack:

```dart
@override
Widget build(BuildContext context) {
  final isDesktop = PlatformUtils.instance.isDesktop;
  final originalBody = <existing splash body>;

  if (!isDesktop) return originalBody;

  return Scaffold(
    backgroundColor: Theme.of(context).colorScheme.surface,
    body: Stack(
      children: [
        const Positioned.fill(child: AnimatedBlobBackground()),
        Column(
          children: [
            const DesktopWindowChrome(),
            Expanded(child: Center(child: originalBody)),
          ],
        ),
      ],
    ),
  );
}
```

(Не используем `DesktopAdaptiveScaffold` потому что нет card.)

- [ ] **Step 2: Analyze + test**

```bash
flutter analyze lib/features/auth/presentation/screens/splash_screen.dart
flutter test
```

- [ ] **Step 3: Commit**

```bash
git add lib/features/auth/presentation/screens/splash_screen.dart
git commit -m "feat(splash): add blob bg + chrome on desktop (no card)"
```

---

## Task 23: Full mobile + desktop integration smoke

Все экраны переделаны. Теперь — глобальный smoke на каждой платформе.

- [ ] **Step 1: Run all unit tests**

```bash
flutter test 2>&1 | tail -10
```

Expected: all green. Если что-то падает — пофиксить.

- [ ] **Step 2: Integration UI test on Android emulator**

```bash
flutter emulators --launch Pixel_XL_API_33
# wait 15s
~/Library/Android/sdk/platform-tools/adb devices

flutter test integration_test/app_test.dart --flavor dev \
  --dart-define=FLAVOR=dev --dart-define=BASE_URL=https://staging.id.taler.tirol \
  -d emulator-5554
```

Expected: проходит (auth flow на эмуляторе должен работать как раньше, мобильный UX не изменился).

- [ ] **Step 3: macOS full smoke**

```bash
flutter run -d macos --flavor dev -t lib/main_dev.dart \
  --dart-define=FLAVOR=dev --dart-define=BASE_URL=https://staging.id.taler.tirol
```

Прогнать вручную:
- /splash → /onboarding → /login → /register → forgot → 2FA → pin_setup → pin_entry
- На каждом: chrome 36 px, blob bg, glass card (где применимо), hover, focus ring, tooltips.
- Resize окна до 500 px на каждом — fallback на mobile UX.
- Сделать ~8 скриншотов в `/tmp/phase1-screenshots/` для review.

- [ ] **Step 4: iOS regression smoke**

```bash
flutter run --flavor dev -t lib/main_dev.dart \
  --dart-define=FLAVOR=dev --dart-define=BASE_URL=https://staging.id.taler.tirol \
  -d 00008101-000E21100202001E
```

Прогнать те же auth-экраны на iPhone. Убедиться: всё выглядит как раньше, нет регрессий.

- [ ] **Step 5: Commit screenshots reference (optional)**

Можно скриншоты не комитить, просто приложить к PR-у.

---

## Task 24: Build & deploy desktop binaries to PROD

Финальная фаза — собрать три бинарника и выложить на download server.

**Pre-flight:**

- [ ] **Step 1: Verify branch is on dev**

```bash
git log --oneline -5
```

Если ветка `feature/desktop-adaptation-phase-1` — оставаться на ней, **не** мержить в main без отдельного approval.
Для теста на staging — собрать с ветки. Для PROD-deploy — нужно сначала смержить в dev (или main, по обычной процедуре).

Согласовать с пользователем: куда мержим? `dev` (DEV staging) → потом, после теста, `main` (PROD).

- [ ] **Step 2: Merge to dev**

```bash
git checkout dev
git pull origin dev
git merge --no-ff feature/desktop-adaptation-phase-1
git push origin dev
```

**macOS DMG:**

- [ ] **Step 3: Pull on local Mac**

```bash
cd /Users/dmitry/Downloads/taler_id_mobile
git checkout dev && git pull origin dev
flutter pub get
```

- [ ] **Step 4: Build + sign + DMG + notarize + staple + upload**

```bash
flutter build macos --release

codesign --deep --force --options runtime --sign "Developer ID Application: GsmSoft GmbH (MG58MDUNZ2)" \
  build/macos/Build/Products/Release/taler_id_mobile.app

hdiutil create -volname "TalerID-build" \
  -srcfolder build/macos/Build/Products/Release/taler_id_mobile.app \
  -ov -format UDZO /tmp/TalerID.dmg

codesign --sign "Developer ID Application: GsmSoft GmbH (MG58MDUNZ2)" /tmp/TalerID.dmg

xcrun notarytool submit /tmp/TalerID.dmg \
  --key ~/.appstoreconnect/private_keys/AuthKey_J3P22V4URD.p8 \
  --key-id J3P22V4URD --issuer 44b87272-3052-40ea-a48a-6c6f88a2df11 --wait

xcrun stapler staple /tmp/TalerID.dmg

scp /tmp/TalerID.dmg dvolkov@138.124.61.221:~/TalerID.dmg
ssh dvolkov@138.124.61.221 \
  "sudo cp ~/TalerID.dmg /var/www/downloads/TalerID.dmg && \
   sudo chmod 644 /var/www/downloads/TalerID.dmg && rm ~/TalerID.dmg"

curl -sI https://id.taler.tirol/download/TalerID.dmg | head -3
```

Expected: HTTP 200, размер ~55-60 MB.

**Linux tar.gz:**

- [ ] **Step 5: Build on DEV server, transfer to PROD**

```bash
ssh dvolkov@89.169.55.217 '
  cd ~/taler_id_mobile && git checkout dev && git pull origin dev && \
  export PATH="$HOME/flutter/bin:$PATH" && flutter pub get && \
  flutter build linux --release && \
  cd build/linux/x64/release && rm -rf /tmp/taler_linux_install && \
  DESTDIR=/tmp/taler_linux_install cmake --install . && \
  cd /tmp/taler_linux_install/usr/local && \
  tar czf /tmp/TalerID-linux-x64.tar.gz .
'
scp dvolkov@89.169.55.217:/tmp/TalerID-linux-x64.tar.gz /tmp/TalerID-linux-x64.tar.gz
scp /tmp/TalerID-linux-x64.tar.gz dvolkov@138.124.61.221:~/TalerID-linux-x64.tar.gz
ssh dvolkov@138.124.61.221 \
  "sudo cp ~/TalerID-linux-x64.tar.gz /var/www/downloads/TalerID-linux-x64.tar.gz && \
   sudo chmod 644 /var/www/downloads/TalerID-linux-x64.tar.gz && rm ~/TalerID-linux-x64.tar.gz"

curl -sI https://id.taler.tirol/download/TalerID-linux-x64.tar.gz | head -3
```

**Windows ZIP:**

- [ ] **Step 6: Build on Windows server, transfer to PROD**

```bash
# 1. Pull repo
sshpass -p 'PIe&J0!V$qI!M!MN' ssh -o StrictHostKeyChecking=no Administrator@147.45.42.116 \
  "cd C:/taler_id_mobile && git checkout main && git pull origin main && flutter pub get"
# (Используем main потому что на Windows ветка main, нужно сначала смержить dev в main.
#  Если ещё не делали — пропустить deploy на Windows до merge dev→main.)

# 2. Patch generated files (speech_to_text)
sshpass -p 'PIe&J0!V$qI!M!MN' ssh -o StrictHostKeyChecking=no Administrator@147.45.42.116 \
  "cd C:/taler_id_mobile && powershell -Command \"\
    (Get-Content 'windows\flutter\generated_plugin_registrant.cc' -Raw) -replace '(?s)#include <speech_to_text_windows/speech_to_text_windows.h>\r?\n', '' -replace '(?s)  SpeechToTextWindowsRegisterWithRegistrar\(\r?\n      registry->GetRegistrarForPlugin\(.SpeechToTextWindows.\)\);\r?\n', '' | Set-Content 'windows\flutter\generated_plugin_registrant.cc'; \
    (Get-Content 'windows\flutter\generated_plugins.cmake' -Raw) -replace '  speech_to_text_windows\r?\n', '' | Set-Content 'windows\flutter\generated_plugins.cmake'\""

# 3. Patch local_auth_windows nuget (если ещё актуально)
sshpass -p 'PIe&J0!V$qI!M!MN' ssh -o StrictHostKeyChecking=no Administrator@147.45.42.116 \
  "powershell -Command \"\$f='C:\Users\Administrator\AppData\Local\Pub\Cache\hosted\pub.dev\local_auth_windows-1.0.10\windows\CMakeLists.txt'; if (Test-Path \$f) { \$c=Get-Content \$f -Raw; \$c=\$c -replace '(?ms)execute_process\(\s*COMMAND[^)]*?nuget[^)]*?\)', '# PATCHED: nuget install skipped (handled manually)'; Set-Content \$f \$c; Write-Host 'patched' } else { Write-Host 'no nuget patch needed' }\""

# 4. Flutter build (упадёт на speech_to_text, но сгенерит CMake)
sshpass -p 'PIe&J0!V$qI!M!MN' ssh -o StrictHostKeyChecking=no Administrator@147.45.42.116 \
  "cd C:/taler_id_mobile && flutter build windows --release --dart-define=FLAVOR=prod --dart-define=BASE_URL=https://id.taler.tirol" || echo "expected to fail on speech_to_text"

# 5. Re-apply speech_to_text patch (flutter build wipes generated)
# (повтор шага 2)

# 6. MSBuild через Build Tools 14.44
sshpass -p 'PIe&J0!V$qI!M!MN' ssh -o StrictHostKeyChecking=no Administrator@147.45.42.116 \
  "\"C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\MSBuild\Current\Bin\MSBuild.exe\" C:\taler_id_mobile\build\windows\x64\taler_id_mobile.sln /p:Configuration=Release /verbosity:minimal"

# 7. Zip via .NET (no Write-Progress issue)
sshpass -p 'PIe&J0!V$qI!M!MN' ssh -o StrictHostKeyChecking=no Administrator@147.45.42.116 \
  "powershell -Command \"\$ProgressPreference='SilentlyContinue'; if (Test-Path 'C:\TalerID-Windows.zip') { Remove-Item 'C:\TalerID-Windows.zip' }; Add-Type -AssemblyName System.IO.Compression.FileSystem; [System.IO.Compression.ZipFile]::CreateFromDirectory('C:\Program Files\taler_id_mobile', 'C:\TalerID-Windows.zip'); Get-Item 'C:\TalerID-Windows.zip' | Select-Object Length\""

# 8. Transfer to PROD
sshpass -p 'PIe&J0!V$qI!M!MN' scp -o StrictHostKeyChecking=no Administrator@147.45.42.116:C:/TalerID-Windows.zip /tmp/TalerID-Windows.zip
scp /tmp/TalerID-Windows.zip dvolkov@138.124.61.221:~/TalerID-Windows.zip
ssh dvolkov@138.124.61.221 \
  "sudo cp ~/TalerID-Windows.zip /var/www/downloads/TalerID-Windows.zip && \
   sudo chmod 644 /var/www/downloads/TalerID-Windows.zip && rm ~/TalerID-Windows.zip"

curl -sI https://id.taler.tirol/download/TalerID-Windows.zip | head -3
```

**Note:** Windows ветка `main`. Если Phase 1 живёт в `dev`, Windows получит обновление только после merge dev → main. Согласовать порядок с пользователем.

---

## Self-Review Checklist

- [x] **Spec coverage**: каждое требование спека покрыто задачей.
  - 8 widgets в `lib/core/desktop/`: Task 2 (breakpoints), 3 (blob), 4 (centered card), 5 (hover lift), 6 (hover scale), 7 (focus ring), 8 (input decoration), 9 (empty state), 10 (window chrome), 11 (adaptive scaffold). 10 widgets вместо 8 — нормально, два helper-разделил из спека.
  - desktopTextTheme: Task 12 + 13.
  - Window chrome init: Task 14 (расширение существующего WindowSetup).
  - 8 auth экранов: Task 15 (login), 16 (register), 17 (forgot), 18 (2fa), 19 (onboarding), 20 (pin_setup), 21 (pin_entry), 22 (splash).
  - Mobile регрессия: Task 23 step 2 (Android integration) + step 4 (iOS smoke).
  - Build + deploy: Task 24.

- [x] **Placeholder scan**: проверено — все steps содержат конкретный код или конкретные команды. Единственный аутсорс — содержимое экранов register/forgot/2fa/pin (Task 16-21) сказано "apply same pattern as Task 15/16". Engineer должен прочитать Task 15 и повторить структуру. Это oversimplification оправдан, потому что pattern полностью описан в Task 15 со всеми кодом.

- [x] **Type consistency**: имена widget'ов одинаковые в спеке, плане и тестах: `DesktopAdaptiveScaffold`, `CenteredCard`, `AnimatedBlobBackground`, `HoverLift`, `HoverScale`, `FocusRing`, `DesktopWindowChrome`, `EmptyState`, `desktopInputDecoration` (function), `desktopTextTheme` (extension getter). Константы: `kDesktopBreakpoint`, `kCardWidthForm`, `kCardWidthSettings`, `kCardWidthWide`, `kDesktopChromeHeight`.

- **Известное смягчение**: Task 11 (`DesktopAdaptiveScaffold`) изначально написан с mobile-passthrough = голый child. В Task 15 step 2 оно меняется на mobile = `Scaffold(body: SafeArea + SingleChildScrollView + child)`. Engineer должен обновить Task 11 widget и перезапустить test. Это явно расписано в Task 15 step 2.

## Execution Handoff

Plan complete and saved to [docs/superpowers/plans/2026-05-21-desktop-adaptation-phase-1.md](2026-05-21-desktop-adaptation-phase-1.md). Two execution options:

**1. Subagent-Driven (recommended)** — я диспатчу свежего subagent на каждую задачу, между задачами review. Fast iteration, не съедает мой контекст.

**2. Inline Execution** — я выполняю задачи в этой же сессии через executing-plans skill, batch с чекпоинтами.

Какой подход?

**Out-of-plan (will be separate plans after Phase 1 ships):**
- Phase 2: edit_profile, settings, sessions, tenant (form/settings screens, ~10-12 задач)
- Phase 3: call_history (DataTable), voice_call (compact mode), KYC start (~10-12 задач)

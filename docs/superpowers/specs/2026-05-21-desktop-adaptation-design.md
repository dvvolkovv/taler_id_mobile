# Desktop Adaptation — Centered Card + 2026 Trends

**Status:** design draft 2026-05-21
**Scope:** macOS / Windows / Linux desktop builds (mobile UX unchanged)
**Branch:** (TBD — `feature/desktop-adaptation`)

## Problem

Унифицированный Flutter-репо собирает один и тот же код в мобильные и десктопные бинарники. На десктопе уже адаптированы несколько two-pane экранов (`assistant`, `kyc`, `messenger`, шелл/роутер), но **большинство экранов всё ещё работает в чистом мобильном режиме** — `SingleChildScrollView` + `Column` на всю ширину окна. На 1440×900 это:

- Login / register / forgot-password / 2FA / onboarding / pin (2 экрана): форма растягивается на 1440px, текстовые поля шириной с экран, читать неудобно, выглядит как масштабированный мобильный скриншот.
- Edit profile / settings подэкраны: тот же эффект.
- Call history / voice call (компактный режим): mobile-first, не используют ширину разумно.
- Нет visible focus ring при keyboard nav (Tab между полями).
- Нет hover-эффектов (десктопные пользователи привыкли).
- Нет tooltips на icon-only кнопках.
- Empty states из одной строки текста выглядят сломанно на больших мониторах.
- Нативный titlebar (macOS / Windows) занимает место и выбивается из тёмной темы.

## Goals

1. Все non-two-pane экраны при ширине окна ≥ 600 px рендерят содержимое в **центрированной карточке** разумной ширины (`max-width` зависит от типа контента: формы 480 px, settings/profile 720 px, списки full-width с боковыми отступами).
2. На десктопе используется **общий анимированный blob-фон** (вынесенный из `login_screen.dart:280-311` в shared widget), карточка прозрачная (glassmorphism).
3. Включены 7 трендовых улучшений 2026:
   - Glassmorphism cards (использует уже существующие токены `glassOpacity`/`glassBlurSigma` в теме)
   - Hover micro-interactions на кнопках и интерактивных строках
   - Кастомный window chrome: hidden titlebar на macOS (traffic lights в кастомной drag-зоне), Mica/Acrylic backdrop на Windows, borderless на Linux
   - Visible focus ring (3 px ореол primary-цвета) на текстовых полях и кнопках при Tab-nav
   - Tooltips на каждой icon-only кнопке
   - Empty states с минимальной glow-иллюстрацией + CTA
   - Увеличенный typography scale на десктопе (body 14→15, H1 30→34)
4. Мобильный UX **не изменяется** — ни одна правка не должна задеть iOS/Android рендеринг.

## Non-goals

- Не редизайнить two-pane экраны (`messenger`, `assistant`, `kyc`, dashboard shell) — у них уже есть свои desktop-adapations.
- Не вводить command palette `⌘K`, keyboard shortcut layer, density toggle (отложено за `пункт C "полноценный desktop-first"`, который пользователь отверг в этом этапе).
- Не делать split-screen с продуктовым визуалом (отложено — нужны иллюстрации).
- Не добавлять отдельную тему — продолжаем использовать существующий `AppTheme.dark`. На десктопе только дополнительный typography scale + glass через `MediaQuery`.
- Не менять breakpoints в роутере или DI — добавки только в widget-слое.

## Approach

Создаём тонкий слой shared widgets в `lib/core/desktop/`, каждый экран **opt-in** оборачивает свой существующий body в `DesktopAdaptiveScaffold` (или конкретные `CenteredCard` / `AnimatedBlobBackground` напрямую, если scaffold не подходит). На мобиле эти widgets — пустые passthroughs (рендерят `child` без изменений). На десктопе — применяют trend-стек.

Roll-out в 3 фазы — каждая фаза мерджится отдельно, чтобы не блокировать ничего на одной большой ветке.

## Architecture

### New widgets — `lib/core/desktop/`

```
lib/core/desktop/
  desktop_adaptive_scaffold.dart   — высокоуровневый wrapper (см. ниже)
  animated_blob_background.dart    — переиспользует _LoginBgPainter из login_screen.dart
  centered_card.dart               — glass card с max-width + responsive padding
  hover_scale.dart                 — MouseRegion + AnimatedScale wrapper
  hover_lift.dart                  — то же, но с translateY + boxShadow boost
  focus_ring.dart                  — Focus + AnimatedContainer с external border
  desktop_window_chrome.dart       — per-OS titlebar / Mica / borderless logic
  empty_state.dart                 — glow icon + title + subtitle + optional CTA
  desktop_breakpoints.dart         — константы: kDesktopBreakpoint=600, kCardWidthForm=480, kCardWidthSettings=720
```

### `DesktopAdaptiveScaffold` API

```dart
class DesktopAdaptiveScaffold extends StatelessWidget {
  final Widget child;
  final double cardMaxWidth;        // default: kCardWidthForm (480)
  final bool useGlass;              // default: true on desktop
  final bool useBlobBackground;     // default: true on desktop
  final bool includeWindowChrome;   // default: true — adds traffic lights row
  final EdgeInsets cardPadding;     // default: EdgeInsets.all(32)
  final ScrollPhysics? physics;     // forwarded to inner ScrollView
}
```

Build:

- `if (!PlatformUtils.instance.isDesktop)` → возвращает `child` без изменений (мобильное поведение, чистый passthrough).
- Иначе:
  - `Scaffold` → `Stack`:
    - `AnimatedBlobBackground` (фон, если `useBlobBackground`)
    - `Column`:
      - `DesktopWindowChrome` (top, 36 px, drag region + traffic lights) — **всегда рендерится на десктопе независимо от ширины**, иначе traffic lights/custom titlebar остаются на экране как сирота-элемент над контентом.
      - `Expanded`:
        - Если `MediaQuery.size.width >= kDesktopBreakpoint`: → `Center` → `ConstrainedBox(maxWidth: cardMaxWidth)` → `CenteredCard(child: child)`.
        - Иначе (узкое окно на десктопе): → `child` напрямую с боковым padding 16 px (mobile-стиль внутри desktop-чрома).

### `AnimatedBlobBackground`

Извлечь `_LoginBgPainter` из `lib/features/auth/presentation/screens/login_screen.dart:280-311` в `lib/core/desktop/animated_blob_background.dart`. Сделать публичным `BlobBackgroundPainter`. После — заменить в `login_screen.dart` использование локального painter на shared widget. Никаких изменений визуального поведения.

### `CenteredCard`

```dart
class CenteredCard extends StatelessWidget {
  final Widget child;
  final bool useGlass;
  final EdgeInsets padding;
  final double borderRadius;  // default 20
}
```

Build (на десктопе):
- `BackdropFilter(filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24))` (только если `useGlass`)
- `Container` с `BoxDecoration`:
  - `color: Colors.white.withOpacity(0.07)` (тёмная тема)
  - `border: Border.all(color: Colors.white.withOpacity(0.14))`
  - `borderRadius: BorderRadius.circular(borderRadius)`
  - `boxShadow: [BoxShadow(blurRadius: 60, color: Colors.black38, offset: Offset(0,20))]`

### `HoverLift` и `HoverScale`

Тонкие wrapper-ы вокруг `MouseRegion`. На мобиле — passthrough.

```dart
class HoverLift extends StatefulWidget {
  final Widget child;
  final double liftPx;       // default 2
  final Color? shadowBoost;  // default: primary color
}
```

Применять к: основным кнопкам (LoginButton), card-tappable rows (ContactRow, SettingsRow), navigation tiles.

### `FocusRing`

```dart
class FocusRing extends StatelessWidget {
  final Widget child;
  final FocusNode? focusNode;
  final double ringWidth;     // default 3
  final Color? ringColor;     // default: primary
}
```

На десктопе при `focusNode.hasFocus == true` — `AnimatedContainer` с `BoxDecoration(border)` + `BoxShadow` ореол primary с opacity 0.25.

Применять к `TextFormField` (через decoration override) и кнопкам.

### `DesktopWindowChrome`

```dart
class DesktopWindowChrome extends StatelessWidget {
  final String? title;       // shown in titlebar
  final List<Widget>? trailing;  // optional menu actions
}
```

Per-OS implementation:

- **macOS**: при инициализации приложения в `main.dart` (опять же, только если `isMacOS`) вызвать `window_manager`:
  ```dart
  await windowManager.setTitleBarStyle(TitleBarStyle.hidden, windowButtonVisibility: true);
  ```
  Это **прячет titlebar, но оставляет traffic lights видимыми**. Виджет рендерит 36px высоты drag-зону (`GestureDetector` + `windowManager.startDragging()`), но НЕ рисует свои traffic lights — это делает macOS. Левый padding виджета 80 px чтобы не оверлапить с системными кнопками.
- **Windows**: использовать `flutter_acrylic` для Mica backdrop. Виджет рендерит custom titlebar с close/min/max кнопками справа (Windows показывает их сама, если включить). Drag-зона + кнопки.
- **Linux**: borderless через `window_manager.setAsFrameless()`. Виджет рендерит свой close/min/max справа (slate-стиль).

`window_manager: ^0.4.3` уже в `pubspec.yaml`. `flutter_acrylic` — новая зависимость, нужно добавить.

### `EmptyState`

```dart
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;     // CTA button
}
```

Рендерит glow-radial-gradient круг (40 px) + иконку (24 px) + title + subtitle (центрированно). На десктопе размеры больше: 96 px glow + 36 px иконка + H3 24 + body 15.

### Theme additions — `lib/core/theme/app_theme.dart`

Добавить getter `desktopTextTheme` который масштабирует текущий `textTheme`:

```dart
TextTheme get desktopTextTheme => textTheme.copyWith(
  displayLarge: textTheme.displayLarge?.copyWith(fontSize: 56, height: 1.1),   // was 48
  headlineMedium: textTheme.headlineMedium?.copyWith(fontSize: 34, height: 1.2), // was 30
  titleLarge: textTheme.titleLarge?.copyWith(fontSize: 22, height: 1.3),       // was 20
  bodyLarge: textTheme.bodyLarge?.copyWith(fontSize: 16, height: 1.5),         // was 15
  bodyMedium: textTheme.bodyMedium?.copyWith(fontSize: 15, height: 1.5),       // was 14
);
```

В `main.dart` где задаётся `MaterialApp.theme/darkTheme`:

```dart
darkTheme: AppTheme.dark.copyWith(
  textTheme: PlatformUtils.instance.isDesktop
    ? AppTheme.dark.desktopTextTheme
    : AppTheme.dark.textTheme,
),
```

### Breakpoints — `lib/core/desktop/desktop_breakpoints.dart`

```dart
const double kDesktopBreakpoint = 600.0;
const double kCardWidthForm = 480.0;
const double kCardWidthSettings = 720.0;
const double kCardWidthWide = 960.0;
```

Использует `MediaQuery.of(context).size.width >= kDesktopBreakpoint && PlatformUtils.instance.isDesktop` как боевой признак "развернуть desktop-layout".

## Per-screen treatment

| Экран | Файл | Card width | Special |
|------|------|-----------|---------|
| Splash | `auth/.../splash_screen.dart` | — | Full-bleed: только `AnimatedBlobBackground` без card. Логотип и spinner центрированы поверх. |
| Onboarding | `auth/.../onboarding_screen.dart` | wide (960) | PageView внутри card. Картинки + текст 2-колоночно на десктопе. |
| Login | `auth/.../login_screen.dart` | form (480) | Полностью переезжает на `DesktopAdaptiveScaffold` |
| Register | `auth/.../register_screen.dart` | form (480) | То же |
| Forgot password | `auth/.../forgot_password_screen.dart` | form (480) | То же |
| 2FA | `auth/.../two_fa_screen.dart` | form (480) | То же |
| PIN setup | `auth/.../pin_setup_screen.dart` | form (480) | PIN keypad без растяжения |
| PIN entry | `auth/.../pin_entry_screen.dart` | form (480) | То же |
| Edit profile | `profile/.../edit_profile_screen.dart` | settings (720) | Aвтар сверху + 2-колоночная сетка полей |
| Settings | `settings/.../settings_screen.dart` | settings (720) | Список настроек с большими hit-targets |
| Sessions | `sessions/.../sessions_screen.dart` | settings (720) | List of devices |
| Tenant | `tenant/.../tenant_screen.dart` | settings (720) | Organizations list |
| Call history | `call_history/.../call_history_screen.dart` | wide (960) | На десктопе — DataTable: время / контакт / длительность / тип / действия. Card-wrap опционален (`useGlass: false`) — таблица читается лучше без backdrop blur. |
| Voice call (compact) | `voice/.../voice_call_screen.dart` | form (480) | Компактный режим в окне, не fullscreen |
| KYC start (если не в KYC scaffold) | проверить отдельно | form (480) | Зависит от текущего поведения |

Splash и Onboarding — отдельный случай: они без `DesktopAdaptiveScaffold`-обёртки, потому что full-bleed логика. На них вешаем только `AnimatedBlobBackground`.

## Window chrome details — пер-платформенно

### macOS

1. В `main.dart` сразу после `WidgetsFlutterBinding.ensureInitialized()` (внутри блока `if (PlatformUtils.instance.isMacOS)`):
   ```dart
   await windowManager.ensureInitialized();
   await windowManager.setTitleBarStyle(TitleBarStyle.hidden, windowButtonVisibility: true);
   await windowManager.setMinimumSize(const Size(480, 600));
   ```
2. Каждый desktop scaffold кладёт `DesktopWindowChrome` сверху — это 36 px полоса с `onPanStart`/`onPanUpdate` → `windowManager.startDragging()`. Слева 80 px пустого паддинга чтобы traffic lights были видны и кликабельны без оверлапа.
3. Никаких изменений в `macos/Runner/MainFlutterWindow.swift` — `window_manager` справится через method channel.

### Windows

1. Добавить пакет `flutter_acrylic: ^1.1.4` (проверить совместимость с текущим Flutter 3.38).
2. В `main.dart`:
   ```dart
   if (PlatformUtils.instance.isWindows) {
     await Window.initialize();
     await Window.setEffect(effect: WindowEffect.mica, dark: true);
   }
   ```
3. `DesktopWindowChrome` рендерит свой close/min/max справа (12×12 px, на hover подсвечивается). Drag-зона = весь левый и центральный фрагмент.

### Linux

1. `await windowManager.setAsFrameless()` в `main.dart`.
2. `DesktopWindowChrome` рендерит свой close/min/max справа (slate-стиль из MoonScroll/Gnome-touch).
3. Drag-зона — вся titlebar.

## Phases / Roll-out

**Phase 1 — Foundation + Auth screens** (1 PR):
- `lib/core/desktop/*` все widgets.
- Извлечь `_LoginBgPainter` → shared.
- `desktopTextTheme` в `app_theme.dart`.
- Window chrome init в `main.dart`.
- Применить к 8 экранам: splash, onboarding, login, register, forgot_password, 2FA, pin_setup, pin_entry.
- **Visual goal:** все auth flow на macOS открывается с traffic lights + glass card + blob bg.

**Phase 2 — Form & List screens** (1 PR):
- Применить к edit_profile, settings, sessions, tenant.
- Эта фаза включает EmptyState rollout на settings (если пусто) и sessions (если нет сессий).

**Phase 3 — Call History + Voice Call** (1 PR):
- Перерисовать call_history как desktop-таблицу (а не stacked list).
- Сделать compact voice call mode для desktop (окно 480×320 floating, без fullscreen).
- Empty state на call_history.

Каждая фаза мерджится отдельно. Между фазами — ручная проверка на macOS (локально), Linux (DEV сервер), Windows (147.45.42.116). Все три десктоп-бинарника пересобираются и выкладываются.

## Hover / Focus / Tooltips — convention

- **HoverLift** — на все primary buttons (`LoadingButton`, `ElevatedButton`-replacements).
- **HoverScale (1.05)** — на icon-only buttons (back, share, more).
- **FocusRing** — на TextFormField (через `InputDecoration` override в shared `desktopInputDecoration()` helper), на кнопки (через wrapper).
- **Tooltip widget** — обязателен на каждой icon-only кнопке. Convention: `Tooltip(message: l10n.tooltipKeyName, child: IconButton(...))`. Добавляем l10n ключи в существующие ARB файлы.

## Testing

Без visual regression infrastructure. Тестируем:

1. **Юнит-тесты Flutter** — добавить widget tests на `DesktopAdaptiveScaffold` (mobile → passthrough; desktop ≥600 → wraps; desktop <600 → passthrough). На `HoverLift` / `FocusRing` — smoke tests, что они не падают на mobile.
2. **Существующий интеграционный тест** (`integration_test/app_test.dart`) запускается на эмуляторе Android — не задеваем. Но если задеть мобильную обёртку — он упадёт, что станет защитной сеткой.
3. **Ручная QA-чеклист** на каждой фазе:
   - macOS 1280×800: открыть каждый затронутый экран, скриншот.
   - macOS resize до 500 px: убедиться что fallback на mobile UX работает.
   - Linux на DEV (через X-forwarding или скриншот): открыть login, убедиться borderless.
   - Windows на 147.45.42.116 (через RDP): открыть login, убедиться Mica.
4. **Регрессия мобилки** — после каждой фазы запустить `flutter run` на iPhone (`-d 00008101-...`) и Android-эмуляторе, пройти весь затронутый flow. Глазами проверить, что ничего не поменялось.

## Risks / open questions

- **`flutter_acrylic` совместимость** с Flutter 3.38: не проверено. Если не соберётся — Windows получит обычный titlebar (downgrade), Phase 1 всё равно мерджится.
- **Chrome решение применяется к процессу, а не к экрану**: `window_manager.setTitleBarStyle(hidden)` / `setAsFrameless()` вызывается ОДИН РАЗ в `main.dart` и действует на всё окно приложения. Это значит desktop window chrome всегда активен — даже когда юзер сузил окно до мобильной ширины. Чтобы избежать сирота-traffic-lights без owner-бара, `DesktopAdaptiveScaffold` всегда рендерит `DesktopWindowChrome` (36 px) на десктопе независимо от текущей ширины. Только centered-card / max-width-логика отключается на узком окне.
- **Glassmorphism performance**: `BackdropFilter` дорогой. На Linux desktop сборке (Intel GPU виртуалка) может быть слабо. Если FPS просядет — добавить flag `useGlass: false` для Linux в `DesktopAdaptiveScaffold` по умолчанию.
- **Focus ring цвет конфликт с error state**: TextFormField в error-состоянии имеет красный border. При focus накладывается primary-ring → визуально странно. Решение: при error focus ring тоже красный (наследует error color).
- **Voice call compact mode** (Phase 3) — требует, чтобы окно можно было ресайзить до 480×320 и оно бы вело себя адекватно. Текущий `voice_call_screen.dart` рассчитан на fullscreen. Может вылиться в отдельный widget.

## Out-of-scope follow-ups (логируем, не делаем сейчас)

- Command palette `⌘K` для navigation/actions.
- Keyboard shortcuts layer (`⌘N` новая беседа, `⌘,` settings, etc.).
- Density toggle (comfortable / cozy / compact).
- Split-screen с продуктовым визуалом на auth-экранах (нужны иллюстрации).
- Onboarding tour для нового пользователя на десктопе.
- System tray menu расширения (notifications, mute, end call).

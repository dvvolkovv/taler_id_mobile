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

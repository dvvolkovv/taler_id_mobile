import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// All color tokens used across the app.
/// Access via `AppColors.of(context).tokenName`.
class AppColorsExtension extends ThemeExtension<AppColorsExtension> {
  final Color primary;
  final Color primaryDark;
  final Color secondary;
  final Color accent;
  final Color surface;
  final Color background;
  final Color card;
  final Color textPrimary;
  final Color textSecondary;
  final Color error;
  final Color warning;
  final Color border;
  final Color glassColor;
  final double glassOpacity;
  final double glassBorderOpacity;
  final double glassBlurSigma;
  final LinearGradient primaryGradient;
  final LinearGradient backgroundGradient;

  const AppColorsExtension({
    required this.primary,
    required this.primaryDark,
    required this.secondary,
    required this.accent,
    required this.surface,
    required this.background,
    required this.card,
    required this.textPrimary,
    required this.textSecondary,
    required this.error,
    required this.warning,
    required this.border,
    required this.glassColor,
    required this.glassOpacity,
    required this.glassBorderOpacity,
    required this.glassBlurSigma,
    required this.primaryGradient,
    required this.backgroundGradient,
  });

  // ── Dark palette (Blue + Gold on navy) ──
  static const dark = AppColorsExtension(
    primary: Color(0xFF167EF2),
    primaryDark: Color(0xFF0D5FD8),
    secondary: Color(0xFF0D5FD8),
    accent: Color(0xFFFBBF24),
    surface: Color(0xFF142338),
    background: Color(0xFF0A1628),
    card: Color(0xFF142338),
    textPrimary: Color(0xFFE2E8F0),
    textSecondary: Color(0xFF94A3B8),
    error: Color(0xFFEF4444),
    warning: Color(0xFFF59E0B),
    border: Color(0xFF1E3A5F),
    glassColor: Colors.white,
    glassOpacity: 0.10,
    glassBorderOpacity: 0.15,
    glassBlurSigma: 24.0,
    primaryGradient: LinearGradient(
      colors: [Color(0xFF167EF2), Color(0xFF0D5FD8)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    backgroundGradient: LinearGradient(
      colors: [Color(0xFF0A1628), Color(0xFF0F2035)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
  );

  // ── Light palette (Blue + Gold on slate) ──
  static const light = AppColorsExtension(
    primary: Color(0xFF1570D6),
    primaryDark: Color(0xFF0D5FD8),
    secondary: Color(0xFF1570D6),
    accent: Color(0xFFD97706),
    surface: Color(0xFFF8FAFC),
    background: Color(0xFFF1F5F9),
    card: Color(0xFFFFFFFF),
    textPrimary: Color(0xFF0F172A),
    textSecondary: Color(0xFF64748B),
    error: Color(0xFFDC2626),
    warning: Color(0xFFD97706),
    border: Color(0xFFCBD5E1),
    glassColor: Colors.black,
    glassOpacity: 0.04,
    glassBorderOpacity: 0.08,
    glassBlurSigma: 20.0,
    primaryGradient: LinearGradient(
      colors: [Color(0xFF1570D6), Color(0xFF0D5FD8)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    backgroundGradient: LinearGradient(
      colors: [Color(0xFFF1F5F9), Color(0xFFE2E8F0)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
  );

  @override
  AppColorsExtension copyWith({
    Color? primary,
    Color? primaryDark,
    Color? secondary,
    Color? accent,
    Color? surface,
    Color? background,
    Color? card,
    Color? textPrimary,
    Color? textSecondary,
    Color? error,
    Color? warning,
    Color? border,
    Color? glassColor,
    double? glassOpacity,
    double? glassBorderOpacity,
    double? glassBlurSigma,
    LinearGradient? primaryGradient,
    LinearGradient? backgroundGradient,
  }) {
    return AppColorsExtension(
      primary: primary ?? this.primary,
      primaryDark: primaryDark ?? this.primaryDark,
      secondary: secondary ?? this.secondary,
      accent: accent ?? this.accent,
      surface: surface ?? this.surface,
      background: background ?? this.background,
      card: card ?? this.card,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      error: error ?? this.error,
      warning: warning ?? this.warning,
      border: border ?? this.border,
      glassColor: glassColor ?? this.glassColor,
      glassOpacity: glassOpacity ?? this.glassOpacity,
      glassBorderOpacity: glassBorderOpacity ?? this.glassBorderOpacity,
      glassBlurSigma: glassBlurSigma ?? this.glassBlurSigma,
      primaryGradient: primaryGradient ?? this.primaryGradient,
      backgroundGradient: backgroundGradient ?? this.backgroundGradient,
    );
  }

  @override
  AppColorsExtension lerp(AppColorsExtension? other, double t) {
    if (other is! AppColorsExtension) return this;
    return AppColorsExtension(
      primary: Color.lerp(primary, other.primary, t)!,
      primaryDark: Color.lerp(primaryDark, other.primaryDark, t)!,
      secondary: Color.lerp(secondary, other.secondary, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      background: Color.lerp(background, other.background, t)!,
      card: Color.lerp(card, other.card, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      error: Color.lerp(error, other.error, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      border: Color.lerp(border, other.border, t)!,
      glassColor: Color.lerp(glassColor, other.glassColor, t)!,
      glassOpacity: lerpDouble(glassOpacity, other.glassOpacity, t) ?? glassOpacity,
      glassBorderOpacity: lerpDouble(glassBorderOpacity, other.glassBorderOpacity, t) ?? glassBorderOpacity,
      glassBlurSigma: lerpDouble(glassBlurSigma, other.glassBlurSigma, t) ?? glassBlurSigma,
      primaryGradient: t < 0.5 ? primaryGradient : other.primaryGradient,
      backgroundGradient: t < 0.5 ? backgroundGradient : other.backgroundGradient,
    );
  }
}

double? lerpDouble(double a, double b, double t) => a + (b - a) * t;

/// Backward-compatible accessor.
/// Usage: `AppColors.of(context).background`
class AppColors {
  AppColors._();
  static AppColorsExtension of(BuildContext context) =>
      Theme.of(context).extension<AppColorsExtension>()!;
}

class AppTheme {
  static ThemeData get light => _build(Brightness.light, AppColorsExtension.light);
  static ThemeData get dark => _build(Brightness.dark, AppColorsExtension.dark);

  static ThemeData _build(Brightness brightness, AppColorsExtension colors) {
    final isDark = brightness == Brightness.dark;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      extensions: [colors],
      fontFamily: GoogleFonts.inter().fontFamily,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: colors.primary,
        secondary: colors.accent,
        surface: colors.surface,
        error: colors.error,
        onPrimary: Colors.white,
        onSecondary: isDark ? Colors.white : Colors.black,
        onSurface: colors.textPrimary,
        onError: Colors.white,
      ),
      scaffoldBackgroundColor: colors.background,
      cardColor: colors.card,

      // AppBar — semi-transparent glass
      appBarTheme: AppBarTheme(
        backgroundColor: colors.surface.withOpacity(0.80),
        foregroundColor: colors.textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(
          color: colors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),

      // Elevated buttons — teal fill, white text
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: colors.glassColor.withOpacity(0.08)),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          elevation: 0,
        ),
      ),

      // Outlined buttons — glass border
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colors.primary,
          minimumSize: const Size(double.infinity, 52),
          side: BorderSide(color: colors.glassColor.withOpacity(0.15)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Bottom nav — transparent, gold selected
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.transparent,
        selectedItemColor: colors.accent,
        unselectedItemColor: colors.textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),

      // Dialogs
      dialogTheme: DialogThemeData(
        backgroundColor: colors.surface.withOpacity(0.95),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      // Bottom sheets
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colors.card,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),

      // Input fields — glass fill
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.glassColor.withOpacity(0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.glassColor.withOpacity(0.15)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.glassColor.withOpacity(0.10)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.error),
        ),
        labelStyle: TextStyle(color: colors.textSecondary),
        hintStyle: TextStyle(color: colors.textSecondary),
      ),

      // Switch — teal
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected)
                ? colors.primary
                : colors.textSecondary),
        trackColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected)
                ? colors.primary.withOpacity(0.3)
                : colors.glassColor.withOpacity(0.10)),
      ),

      dividerColor: colors.glassColor.withOpacity(0.08),

      // Typography — Inter
      textTheme: TextTheme(
        headlineLarge: GoogleFonts.inter(
          color: colors.textPrimary,
          fontSize: 28,
          fontWeight: FontWeight.bold,
        ),
        headlineMedium: GoogleFonts.inter(
          color: colors.textPrimary,
          fontSize: 22,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: GoogleFonts.inter(
          color: colors.textPrimary,
          fontSize: 16,
        ),
        bodyMedium: GoogleFonts.inter(
          color: colors.textSecondary,
          fontSize: 14,
        ),
        labelLarge: GoogleFonts.inter(
          color: colors.textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

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

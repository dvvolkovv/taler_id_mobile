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

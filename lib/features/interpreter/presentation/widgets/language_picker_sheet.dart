import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/interpreter_models.dart';

/// Searchable language picker, the interpreter equivalent of
/// `voice_call_screen.dart`'s `_showLangPicker`. Returns the chosen code, or
/// `null` if the sheet was dismissed without a choice.
Future<String?> showLanguagePickerSheet({
  required BuildContext context,
  required List<InterpreterLanguage> languages,
  required String selected,
}) {
  final colors = AppColors.of(context);
  final l10n = AppLocalizations.of(context)!;
  var query = '';

  return showModalBottomSheet<String>(
    context: context,
    backgroundColor: colors.card,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => StatefulBuilder(
      builder: (ctx, setModalState) {
        final sorted = [...languages]..sort((a, b) => a.name.compareTo(b.name));
        final filtered = query.isEmpty
            ? sorted
            : sorted
                .where((lang) =>
                    lang.name.toLowerCase().contains(query.toLowerCase()) ||
                    lang.code.toLowerCase().contains(query.toLowerCase()))
                .toList();
        return SafeArea(
          child: DraggableScrollableSheet(
            initialChildSize: 0.7,
            minChildSize: 0.4,
            maxChildSize: 0.9,
            expand: false,
            builder: (_, scrollController) => Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.interpreterChooseLanguage,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                    autofocus: false,
                    style: TextStyle(color: colors.textPrimary, fontSize: 15),
                    decoration: InputDecoration(
                      hintText: l10n.interpreterSearchLanguage,
                      hintStyle: TextStyle(color: colors.textSecondary),
                      prefixIcon:
                          Icon(Icons.search, color: colors.textSecondary),
                      filled: true,
                      fillColor: colors.surface,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (v) => setModalState(() => query = v),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    children: [
                      ...filtered.map((lang) => ListTile(
                            leading: Icon(
                              Icons.language_rounded,
                              color: lang.code == selected
                                  ? colors.primary
                                  : colors.textSecondary,
                            ),
                            title: Text(
                              lang.name,
                              style: TextStyle(
                                color: lang.code == selected
                                    ? colors.primary
                                    : colors.textPrimary,
                                fontWeight: lang.code == selected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                            trailing: lang.code == selected
                                ? Icon(Icons.check_rounded,
                                    color: colors.primary)
                                : null,
                            onTap: () => Navigator.pop(ctx, lang.code),
                          )),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}

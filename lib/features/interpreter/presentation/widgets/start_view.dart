import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/widgets.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/interpreter_models.dart';
import 'interpreter_texts.dart';
import 'language_picker_sheet.dart';

/// Pre-session screen: pick a language, then either host a new call or scan
/// a partner's QR code. [joinCode] carries a code that arrived via a
/// scanned/deep-linked `talerid://interp/<code>` link before any language
/// was picked — per the spec's "Вход (Б)" flow the guest chooses a language
/// first and only then joins, so while a code is pending this view swaps
/// «Начать» for a short invitation hint and a «Подключиться» button that
/// fires [onJoin] with that same code. «Сканировать QR» is shown either way.
class StartView extends StatelessWidget {
  final InterpreterCatalog catalog;
  final String myLang;
  final String? joinCode;
  final ValueChanged<String> onLanguageChosen;
  final VoidCallback onStart;
  final VoidCallback onScan;
  final ValueChanged<String> onJoin;

  const StartView({
    super.key,
    required this.catalog,
    required this.myLang,
    this.joinCode,
    required this.onLanguageChosen,
    required this.onStart,
    required this.onScan,
    required this.onJoin,
  });

  Future<void> _openPicker(BuildContext context) async {
    final chosen = await showLanguagePickerSheet(
      context: context,
      languages: catalog.languages,
      selected: myLang,
    );
    if (chosen != null) onLanguageChosen(chosen);
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final l10n = AppLocalizations.of(context)!;
    final langName = interpreterLanguageName(catalog.languages, myLang);
    final code = joinCode;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: () => _openPicker(context),
              child: AppCard(
                child: Row(
                  children: [
                    Icon(Icons.translate_rounded, color: colors.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '${l10n.interpreterSpeakLabel} $langName',
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Icon(Icons.arrow_drop_down_rounded,
                        color: colors.textSecondary),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),
            if (code != null) ...[
              Text(
                l10n.interpreterInvitedHint,
                textAlign: TextAlign.center,
                style: TextStyle(color: colors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () => onJoin(code),
                  child: Text(l10n.interpreterJoinButton),
                ),
              ),
            ] else
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: onStart,
                  child: Text(l10n.interpreterStartButton),
                ),
              ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                onPressed: onScan,
                icon: const Icon(Icons.qr_code_scanner_rounded),
                label: Text(l10n.interpreterScanButton),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              l10n.interpreterStartHint,
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.textSecondary, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

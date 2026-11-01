import 'package:flutter_test/flutter_test.dart';
import 'package:taler_id_mobile/features/interpreter/domain/interpreter_error.dart';
import 'package:taler_id_mobile/features/interpreter/domain/interpreter_models.dart';
import 'package:taler_id_mobile/features/interpreter/presentation/widgets/interpreter_texts.dart';
import 'package:taler_id_mobile/l10n/app_localizations_en.dart';

void main() {
  final l10n = AppLocalizationsEn();

  group('interpreterErrorText', () {
    test('covers every InterpreterErrorKind with a non-empty, distinct text',
        () {
      final seen = <String>{};
      for (final kind in InterpreterErrorKind.values) {
        final text = interpreterErrorText(l10n, kind);
        expect(text, isNotEmpty, reason: 'no text for $kind');
        // Each kind gets its own wording — a shared fallback for several
        // kinds would be a sign one of them was forgotten in the switch.
        expect(seen.add(text), isTrue, reason: '$kind reuses "$text"');
      }
    });

    test('insufficientFunds text differs from hostInsufficientFunds', () {
      expect(
        interpreterErrorText(l10n, InterpreterErrorKind.insufficientFunds),
        isNot(interpreterErrorText(
            l10n, InterpreterErrorKind.hostInsufficientFunds)),
      );
    });
  });

  group('interpreterEndText', () {
    test(
        'covers every InterpreterEndReason plus null with a non-empty, distinct text',
        () {
      final seen = <String>{};
      final allReasons = <InterpreterEndReason?>[
        null,
        ...InterpreterEndReason.values
      ];
      for (final reason in allReasons) {
        final text = interpreterEndText(l10n, reason);
        expect(text, isNotEmpty, reason: 'no text for $reason');
      }
      // hangup and the null fallback both read "Call ended" by design (a
      // click on End and a reason-less close look the same to the user) —
      // everything else must be distinct from each other.
      for (final reason in InterpreterEndReason.values) {
        if (reason == InterpreterEndReason.hangup) continue;
        final text = interpreterEndText(l10n, reason);
        expect(seen.add(text), isTrue, reason: '$reason reuses "$text"');
      }
    });

    test('null and hangup share the generic "call ended" wording', () {
      expect(
        interpreterEndText(l10n, null),
        interpreterEndText(l10n, InterpreterEndReason.hangup),
      );
    });
  });

  group('interpreterLanguageName', () {
    const languages = [
      InterpreterLanguage(code: 'ru', name: 'Русский'),
      InterpreterLanguage(code: 'en', name: 'English'),
    ];

    test('resolves a known code to its catalog name', () {
      expect(interpreterLanguageName(languages, 'ru'), 'Русский');
    });

    test('falls back to the upper-cased code for an unknown one', () {
      expect(interpreterLanguageName(languages, 'sk'), 'SK');
    });
  });

  group('interpreterFormatDuration', () {
    test('formats minutes and seconds with zero-padded seconds', () {
      expect(interpreterFormatDuration(const Duration(minutes: 4, seconds: 5)),
          '4:05');
    });

    test('clamps a negative duration to 0:00', () {
      expect(interpreterFormatDuration(const Duration(seconds: -5)), '0:00');
    });

    test('zero duration is 0:00', () {
      expect(interpreterFormatDuration(Duration.zero), '0:00');
    });
  });
}

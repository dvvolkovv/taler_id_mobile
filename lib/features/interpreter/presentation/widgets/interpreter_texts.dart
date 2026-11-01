import '../../../../l10n/app_localizations.dart';
import '../../domain/interpreter_error.dart';
import '../../domain/interpreter_models.dart';

/// User-facing text for every [InterpreterErrorKind]. The caller decides on
/// top of this which kinds additionally get a call-to-action (see the
/// failure view in `interpreter_screen.dart`): `insufficientFunds` → "Пополнить"
/// (push the wallet route), `codeExpired` → an extra "ask for a new code"
/// hint, `voicePrintRequired` never reaches here (the bloc reopens the
/// enrollment gate instead) — everything else just falls back to "back to
/// start".
String interpreterErrorText(AppLocalizations l10n, InterpreterErrorKind kind) {
  switch (kind) {
    case InterpreterErrorKind.interpreterDisabled:
      return l10n.interpreterErrInterpreterDisabled;
    case InterpreterErrorKind.unsupportedLanguage:
      return l10n.interpreterErrUnsupportedLanguage;
    case InterpreterErrorKind.sameLanguage:
      return l10n.interpreterErrSameLanguage;
    case InterpreterErrorKind.voicePrintRequired:
      return l10n.interpreterErrVoicePrintRequired;
    case InterpreterErrorKind.hostVoicePrintRequired:
      return l10n.interpreterErrHostVoicePrintRequired;
    case InterpreterErrorKind.alreadyInSession:
      return l10n.interpreterErrAlreadyInSession;
    case InterpreterErrorKind.sameVoicePrint:
      return l10n.interpreterErrSameVoicePrint;
    case InterpreterErrorKind.ownCode:
      return l10n.interpreterErrOwnCode;
    case InterpreterErrorKind.codeUsed:
      return l10n.interpreterErrCodeUsed;
    case InterpreterErrorKind.notWaiting:
      return l10n.interpreterErrNotWaiting;
    case InterpreterErrorKind.insufficientFunds:
      return l10n.interpreterErrInsufficientFunds;
    case InterpreterErrorKind.hostInsufficientFunds:
      return l10n.interpreterErrHostInsufficientFunds;
    case InterpreterErrorKind.featureDisabled:
      return l10n.interpreterErrFeatureDisabled;
    case InterpreterErrorKind.hostFeatureDisabled:
      return l10n.interpreterErrHostFeatureDisabled;
    case InterpreterErrorKind.codeNotFound:
      return l10n.interpreterErrCodeNotFound;
    case InterpreterErrorKind.sessionNotFound:
      return l10n.interpreterErrSessionNotFound;
    case InterpreterErrorKind.codeExpired:
      return l10n.interpreterErrCodeExpired;
    case InterpreterErrorKind.tooManyAttempts:
      return l10n.interpreterErrTooManyAttempts;
    case InterpreterErrorKind.interpreterUnavailable:
      return l10n.interpreterErrInterpreterUnavailable;
    case InterpreterErrorKind.network:
      return l10n.interpreterErrNetwork;
    case InterpreterErrorKind.unknown:
      return l10n.interpreterErrUnknown;
  }
}

/// User-facing text for how a call ended. `null` is the generic fallback —
/// an end reason the server didn't send or didn't name (see
/// `interpreterEndReasonFromJson`'s doc on why an unrecognised value maps to
/// `null` rather than guessing).
String interpreterEndText(AppLocalizations l10n, InterpreterEndReason? reason) {
  switch (reason) {
    case null:
      return l10n.interpreterEndGeneric;
    case InterpreterEndReason.hangup:
      return l10n.interpreterEndHangup;
    case InterpreterEndReason.partnerLeft:
      return l10n.interpreterEndPartnerLeft;
    case InterpreterEndReason.expired:
      return l10n.interpreterEndExpired;
    case InterpreterEndReason.translationFailed:
      return l10n.interpreterEndTranslationFailed;
    case InterpreterEndReason.agentLost:
      return l10n.interpreterEndAgentLost;
    case InterpreterEndReason.noFunds:
      return l10n.interpreterEndNoFunds;
    case InterpreterEndReason.maxDuration:
      return l10n.interpreterEndMaxDuration;
  }
}

/// Display name for a language code, resolved against the loaded catalog.
/// Falls back to the upper-cased code itself for one a caller passes that
/// isn't in [languages] — a partner's reported language is always one of
/// the 81 the backend knows, but defensive here is free.
String interpreterLanguageName(
    List<InterpreterLanguage> languages, String code) {
  for (final lang in languages) {
    if (lang.code == code) return lang.name;
  }
  return code.toUpperCase();
}

/// `mm:ss` rendering of a non-negative [duration], used by the QR
/// countdown, the session timer and the ended screen. Negative durations
/// (already elapsed) clamp to `0:00` rather than printing a minus sign.
String interpreterFormatDuration(Duration duration) {
  final clamped = duration.isNegative ? Duration.zero : duration;
  final minutes = clamped.inMinutes;
  final seconds = clamped.inSeconds.remainder(60);
  return '$minutes:${seconds.toString().padLeft(2, '0')}';
}

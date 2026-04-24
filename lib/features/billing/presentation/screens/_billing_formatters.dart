import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/billing_transaction_entity.dart';

/// Shared formatters/classifiers for billing UI.
///
/// Extracted from `wallet_screen.dart` so that the standalone transactions
/// screen renders rows identically to the wallet's recent-tx section.

/// Convert planck (18 decimals) → μTAL (12 decimals) by dividing by 1e6.
/// Accepts optional leading '-' for outgoing amounts.
/// Operates on strings to avoid int64 overflow.
String planckToMicroTal(String planck) {
  var s = planck;
  final negative = s.startsWith('-');
  if (negative) s = s.substring(1);
  final value = BigInt.tryParse(s);
  if (value == null) return planck;
  final microTal = value ~/ BigInt.from(1000000);
  final fraction = value % BigInt.from(1000000);
  String result;
  if (fraction == BigInt.zero) {
    result = microTal.toString();
  } else {
    final fracStr = fraction.toString().padLeft(6, '0');
    final trimmed = fracStr.replaceFirst(RegExp(r'0+$'), '');
    result = trimmed.isEmpty ? microTal.toString() : '$microTal.$trimmed';
  }
  return negative ? '-$result' : result;
}

/// True for credit-like transactions (top-ups, refunds) — false for debits.
bool isCreditTx(BillingTransactionEntity tx) {
  final t = tx.type.toUpperCase();
  if (t.startsWith('TOPUP') || t.contains('REFUND') || t.contains('CREDIT')) {
    return true;
  }
  if (t.contains('SPEND') || t.contains('DEBIT') || t.contains('CHARGE')) {
    return false;
  }
  return !tx.amountPlanck.startsWith('-');
}

/// Human-friendly transaction type label, localized.
String typeLabel(AppLocalizations l10n, BillingTransactionEntity tx) {
  final t = tx.type.toUpperCase();
  if (t.startsWith('TOPUP')) return l10n.billingTxTypeTopup;
  if (t.contains('REFUND')) return l10n.billingTxTypeRefund;
  if (t.contains('SPEND') || t.contains('DEBIT') || t.contains('CHARGE')) {
    return l10n.billingTxTypeSpend;
  }
  return tx.type;
}

/// Direction icon for a transaction (down-in for credit, up-out for debit).
IconData txIcon(BillingTransactionEntity tx) {
  return isCreditTx(tx) ? Icons.south_west : Icons.north_east;
}

/// Formats an ISO 8601 string as "dd.MM.yyyy HH:mm" in local time.
/// Returns the original string if parsing fails.
String formatIsoDate(String iso) {
  final dt = DateTime.tryParse(iso);
  if (dt == null) return iso;
  final local = dt.toLocal();
  final y = local.year.toString();
  final m = local.month.toString().padLeft(2, '0');
  final d = local.day.toString().padLeft(2, '0');
  final hh = local.hour.toString().padLeft(2, '0');
  final mm = local.minute.toString().padLeft(2, '0');
  return '$d.$m.$y $hh:$mm';
}

/// Human-friendly labels for AI feature keys (short form).
/// Used across transactions, pricebook, and toggles screens.
String? featureLabel(AppLocalizations l10n, String? key) {
  if (key == null) return null;
  switch (key) {
    case 'voice_assistant':
      return l10n.billingFeatureVoiceAssistant;
    case 'web_search':
      return l10n.billingFeatureWebSearch;
    case 'ai_twin':
      return l10n.billingFeatureAiTwin;
    case 'outbound_call':
      return l10n.billingFeatureOutboundCall;
    case 'whisper_transcribe':
      return l10n.billingFeatureWhisperTranscribe;
    case 'meeting_summary':
      return l10n.billingFeatureMeetingSummary;
    default:
      return key;
  }
}

/// Long-form feature label (used on settings/toggles screen where we
/// want clarifying qualifiers like "(AI Twin)" / "bot обзвона").
String featureLabelLong(AppLocalizations l10n, String key) {
  switch (key) {
    case 'voice_assistant':
      return l10n.billingFeatureVoiceAssistant;
    case 'web_search':
      return l10n.billingFeatureWebSearch;
    case 'ai_twin':
      return l10n.billingFeatureAiTwinLong;
    case 'outbound_call':
      return l10n.billingFeatureOutboundCallLong;
    case 'whisper_transcribe':
      return l10n.billingFeatureWhisperTranscribe;
    case 'meeting_summary':
      return l10n.billingFeatureMeetingSummary;
    default:
      return key;
  }
}

/// Ordered feature list — ensures a stable UI ordering across
/// the toggles and pricebook screens regardless of API response order.
const orderedFeatureKeys = <String>[
  'voice_assistant',
  'web_search',
  'ai_twin',
  'outbound_call',
  'whisper_transcribe',
  'meeting_summary',
];

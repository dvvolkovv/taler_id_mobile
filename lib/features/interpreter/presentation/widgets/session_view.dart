import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../billing/presentation/screens/_billing_formatters.dart';
import '../../domain/interpreter_models.dart';
import '../../room/caption_lines.dart';
import '../../room/interpreter_signal.dart';
import '../bloc/interpreter_state.dart' show InterpreterLinkState;
import 'interpreter_texts.dart';

/// The conversation itself, for both host and guest. Mirrors
/// `InterpreterActive` field for field — see that state's class doc for why
/// [captions] is a mutable accumulator rather than an immutable value.
class InterpreterSessionView extends StatefulWidget {
  final bool isHost;
  final InterpreterPartner partner;
  final InterpreterDirections directions;
  final CaptionLines captions;
  final bool partnerSpeaking;
  final bool meSpeaking;
  final bool agentPresent;
  final InterpreterLinkState connection;
  final bool micOn;
  final DateTime startedAt;
  final String? spentPlanck;
  final List<InterpreterLanguage> languages;
  final ValueChanged<bool> onMicToggle;
  final VoidCallback onEnd;

  /// Injectable clock for the host's elapsed-time readout; defaults to the
  /// wall clock.
  final DateTime Function() now;

  const InterpreterSessionView({
    super.key,
    required this.isHost,
    required this.partner,
    required this.directions,
    required this.captions,
    required this.partnerSpeaking,
    required this.meSpeaking,
    required this.agentPresent,
    required this.connection,
    required this.micOn,
    required this.startedAt,
    required this.spentPlanck,
    required this.languages,
    required this.onMicToggle,
    required this.onEnd,
    this.now = DateTime.now,
  });

  @override
  State<InterpreterSessionView> createState() => _InterpreterSessionViewState();
}

class _InterpreterSessionViewState extends State<InterpreterSessionView> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Only the host shows a running timer — ticking for the guest too would
    // just burn frames on a clock nobody reads (see spec: "у А — таймер и
    // стоимость").
    if (widget.isHost) {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final l10n = AppLocalizations.of(context)!;
    final partnerName = widget.partner.firstName?.trim().isNotEmpty == true
        ? widget.partner.firstName!
        : l10n.interpreterPartnerFallback;
    final partnerLangName =
        interpreterLanguageName(widget.languages, widget.partner.lang);

    return SafeArea(
      child: Column(
        children: [
          const SizedBox(height: 12),
          _buildHeader(colors, partnerName, partnerLangName),
          const SizedBox(height: 8),
          if (widget.directions.toMe == InterpreterEngine.phrase)
            _buildBadge(colors, l10n.interpreterPhraseBadge),
          if (!widget.agentPresent)
            _buildBanner(colors, l10n.interpreterAgentAbsent)
          else if (widget.connection == InterpreterLinkState.reconnecting)
            _buildBanner(colors, l10n.interpreterReconnecting)
          else if (widget.connection == InterpreterLinkState.failed)
            _buildBanner(colors, l10n.interpreterTranslationFailedBanner),
          Expanded(child: _buildCaptions(colors, l10n)),
          if (widget.isHost) _buildHostMeter(colors, l10n),
          Text(
            l10n.interpreterServerNote,
            style: TextStyle(color: colors.textSecondary, fontSize: 11),
          ),
          const SizedBox(height: 12),
          _buildControls(colors, l10n),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildHeader(
    AppColorsExtension colors,
    String partnerName,
    String partnerLangName,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  partnerName,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  partnerLangName,
                  style: TextStyle(color: colors.textSecondary, fontSize: 13),
                ),
              ],
            ),
          ),
          if (widget.partnerSpeaking)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: colors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  AppLocalizations.of(context)!.interpreterPartnerSpeaking,
                  style: TextStyle(color: colors.primary, fontSize: 12),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildBadge(AppColorsExtension colors, String text) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: colors.accent.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: colors.accent.withValues(alpha: 0.4)),
      ),
      child: Text(
        text,
        style: TextStyle(
            color: colors.accent, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildBanner(AppColorsExtension colors, String text) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: colors.warning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.warning.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: colors.warning, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style: TextStyle(color: colors.warning, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _buildCaptions(AppColorsExtension colors, AppLocalizations l10n) {
    // `linesFor` hands back oldest-first, newest-last — rendered top to
    // bottom in that same order, so the newest line of each role is always
    // the one closest to the bottom of its section.
    final translation = widget.captions.linesFor(CaptionRole.translation);
    final source = widget.captions.linesFor(CaptionRole.source);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      children: [
        if (source.isNotEmpty) ...[
          Text(
            l10n.interpreterMyCaptionLabel,
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 4),
          for (final line in source)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                line.text,
                style: TextStyle(color: colors.textSecondary, fontSize: 13),
              ),
            ),
          const SizedBox(height: 16),
        ],
        Text(
          l10n.interpreterTranslationCaptionLabel,
          style: TextStyle(
            color: colors.primary,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 4),
        for (final line in translation)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              line.text,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w500,
                height: 1.3,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildHostMeter(AppColorsExtension colors, AppLocalizations l10n) {
    final elapsed = widget.now().difference(widget.startedAt);
    final spent = widget.spentPlanck;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.timer_outlined, color: colors.textSecondary, size: 16),
          const SizedBox(width: 6),
          Text(
            interpreterFormatDuration(elapsed),
            style: TextStyle(color: colors.textPrimary, fontSize: 14),
          ),
          if (spent != null) ...[
            const SizedBox(width: 16),
            Text(
              l10n.interpreterSpentAmount(planckToMicroTal(spent)),
              style: TextStyle(color: colors.textSecondary, fontSize: 13),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildControls(AppColorsExtension colors, AppLocalizations l10n) {
    // The app theme gives every Elevated/OutlinedButton a 'minimumSize' of
    // `Size(double.infinity, 52)` (every other screen wraps its buttons in a
    // full-width SizedBox) — inside a plain Row that infinite minimum width
    // has nothing finite to clamp against and the layout asserts. `Expanded`
    // gives each button a finite, shared slice of the row's width instead of
    // a fixed 150px — which also used to overflow once a large text scale
    // made "Микрофон"/"Завершить" wider than that.
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 50,
            child: OutlinedButton.icon(
              onPressed: () => widget.onMicToggle(!widget.micOn),
              icon: Icon(
                  widget.micOn ? Icons.mic_rounded : Icons.mic_off_rounded),
              label: Text(l10n.interpreterMicButton),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: SizedBox(
            height: 50,
            child: ElevatedButton.icon(
              onPressed: widget.onEnd,
              style: ElevatedButton.styleFrom(backgroundColor: colors.error),
              icon: const Icon(Icons.call_end_rounded),
              label: Text(l10n.interpreterEndButton),
            ),
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';

class PartialRecordingBanner extends StatelessWidget {
  final bool compact;

  const PartialRecordingBanner({super.key, this.compact = false});

  @override
  Widget build(BuildContext context) {
    const amber = Color(0xFFF59E0B);
    final l10n = AppLocalizations.of(context)!;

    if (compact) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.warning_amber_rounded, size: 14, color: amber),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              l10n.callHistoryPartialRecording,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: amber, fontSize: 12),
            ),
          ),
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: amber.withValues(alpha: 0.12),
        border: Border.all(color: amber.withValues(alpha: 0.45)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded, size: 20, color: amber),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.callHistoryPartialRecording,
                  style: const TextStyle(color: amber, fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.callHistoryPartialRecordingDetails,
                  style: const TextStyle(color: amber, fontSize: 13, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

import '../../features/presence/domain/entities/presence_entity.dart';
import '../../l10n/app_localizations.dart';

String formatLastSeen(
  PresenceEntity entity,
  AppLocalizations l10n,
  DateTime now,
) {
  if (entity.isOnline == true) return l10n.presenceOnline;
  if (entity.hidden || entity.lastSeenAt == null) {
    return l10n.presenceLastSeenRecently;
  }
  // `lastSeenAt` is parsed as UTC by PresenceEntity.fromJson. Convert to the
  // device's local time before any day-boundary math; `now` is already local
  // (DateTime.now()), so without this conversion every nightly UTC/local
  // boundary would misclassify "today" vs "yesterday" and render UTC hours.
  final last = entity.lastSeenAt!.toLocal();
  final delta = now.difference(last);
  if (delta.inSeconds < 60) return l10n.presenceLastSeenJustNow;
  if (delta.inMinutes < 60) {
    return l10n.presenceLastSeenMinutesAgo(delta.inMinutes);
  }
  String hhmm(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  final isSameDay =
      last.year == now.year && last.month == now.month && last.day == now.day;
  if (isSameDay) return l10n.presenceLastSeenToday(hhmm(last));
  final yesterday = now.subtract(const Duration(days: 1));
  final isYesterday = last.year == yesterday.year &&
      last.month == yesterday.month &&
      last.day == yesterday.day;
  if (isYesterday) return l10n.presenceLastSeenYesterday(hhmm(last));
  final dd = last.day.toString().padLeft(2, '0');
  final mm = last.month.toString().padLeft(2, '0');
  return l10n.presenceLastSeenOnDate('$dd.$mm.${last.year}');
}

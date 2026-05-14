import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taler_id_mobile/core/utils/presence_format.dart';
import 'package:taler_id_mobile/features/presence/domain/entities/presence_entity.dart';
import 'package:taler_id_mobile/l10n/app_localizations.dart';

Future<AppLocalizations> ruL10n() async {
  return AppLocalizations.delegate.load(const Locale('ru'));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final now = DateTime(2026, 5, 14, 12, 0);

  test('isOnline=true returns "в сети"', () async {
    final l10n = await ruL10n();
    final e = PresenceEntity(isOnline: true, lastSeenAt: null, hidden: false);
    expect(formatLastSeen(e, l10n, now), 'в сети');
  });

  test('hidden=true returns "недавно"', () async {
    final l10n = await ruL10n();
    final e = PresenceEntity(isOnline: null, lastSeenAt: null, hidden: true);
    expect(formatLastSeen(e, l10n, now), 'был(а) в сети недавно');
  });

  test('lastSeenAt null and not hidden also renders "недавно"', () async {
    final l10n = await ruL10n();
    final e = PresenceEntity(isOnline: false, lastSeenAt: null, hidden: false);
    expect(formatLastSeen(e, l10n, now), 'был(а) в сети недавно');
  });

  test('less than 60 seconds ago: "только что"', () async {
    final l10n = await ruL10n();
    final lastSeen = now.subtract(const Duration(seconds: 30));
    final e = PresenceEntity(isOnline: false, lastSeenAt: lastSeen, hidden: false);
    expect(formatLastSeen(e, l10n, now), 'был(а) в сети только что');
  });

  test('15 minutes ago: "15 мин назад"', () async {
    final l10n = await ruL10n();
    final lastSeen = now.subtract(const Duration(minutes: 15));
    final e = PresenceEntity(isOnline: false, lastSeenAt: lastSeen, hidden: false);
    expect(formatLastSeen(e, l10n, now), 'был(а) в сети 15 мин назад');
  });

  test('same day earlier: "сегодня в HH:MM"', () async {
    final l10n = await ruL10n();
    final lastSeen = DateTime(2026, 5, 14, 8, 30);
    final e = PresenceEntity(isOnline: false, lastSeenAt: lastSeen, hidden: false);
    expect(formatLastSeen(e, l10n, now), 'был(а) в сети сегодня в 08:30');
  });

  test('yesterday: "вчера в HH:MM"', () async {
    final l10n = await ruL10n();
    final lastSeen = DateTime(2026, 5, 13, 21, 30);
    final e = PresenceEntity(isOnline: false, lastSeenAt: lastSeen, hidden: false);
    expect(formatLastSeen(e, l10n, now), 'был(а) в сети вчера в 21:30');
  });

  test('older: "DD.MM.YYYY"', () async {
    final l10n = await ruL10n();
    final lastSeen = DateTime(2026, 4, 30, 12, 0);
    final e = PresenceEntity(isOnline: false, lastSeenAt: lastSeen, hidden: false);
    expect(formatLastSeen(e, l10n, now), 'был(а) в сети 30.04.2026');
  });
}

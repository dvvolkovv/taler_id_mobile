import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taler_id_mobile/l10n/app_localizations.dart';

Future<AppLocalizations> enL10n() async {
  return AppLocalizations.delegate.load(const Locale('en'));
}

Future<AppLocalizations> ruL10n() async {
  return AppLocalizations.delegate.load(const Locale('ru'));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Pinned messages l10n', () {
    test('plain key resolves in English', () async {
      final l10n = await enL10n();
      expect(l10n.pinnedMessagesTitle, 'Pinned');
    });

    test('plain key resolves in Russian', () async {
      final l10n = await ruL10n();
      expect(l10n.pinnedMessagesTitle, 'Закреплённые');
    });

    test('pinnedCounter(2, 3) produces "2 of 3" in English', () async {
      final l10n = await enL10n();
      expect(l10n.pinnedCounter(2, 3), '2 of 3');
    });

    test('pinnedCounter(2, 3) produces "2 из 3" in Russian', () async {
      final l10n = await ruL10n();
      expect(l10n.pinnedCounter(2, 3), '2 из 3');
    });

    test('messagePinnedBy("Ann") contains "Ann" in English', () async {
      final l10n = await enL10n();
      expect(l10n.messagePinnedBy('Ann'), contains('Ann'));
    });

    test('messagePinnedBy("Ann") contains "Ann" in Russian', () async {
      final l10n = await ruL10n();
      expect(l10n.messagePinnedBy('Ann'), contains('Ann'));
    });
  });
}

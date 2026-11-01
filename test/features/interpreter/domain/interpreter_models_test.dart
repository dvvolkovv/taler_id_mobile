import 'package:flutter_test/flutter_test.dart';
import 'package:taler_id_mobile/features/interpreter/domain/interpreter_models.dart';

void main() {
  group('InterpreterLanguage', () {
    test('parses from json', () {
      final lang =
          InterpreterLanguage.fromJson({'code': 'ru', 'name': 'Русский'});
      expect(lang.code, 'ru');
      expect(lang.name, 'Русский');
    });

    test('equality by value', () {
      expect(
        InterpreterLanguage(code: 'ru', name: 'Русский'),
        InterpreterLanguage(code: 'ru', name: 'Русский'),
      );
    });
  });

  group('InterpreterCatalog', () {
    test('parses enabled + languages', () {
      final catalog = InterpreterCatalog.fromJson({
        'enabled': true,
        'languages': [
          {'code': 'ru', 'name': 'Русский'},
          {'code': 'en', 'name': 'English'},
        ],
      });
      expect(catalog.enabled, isTrue);
      expect(catalog.languages, hasLength(2));
      expect(catalog.languages.first.code, 'ru');
    });

    test('parses disabled with empty list', () {
      final catalog =
          InterpreterCatalog.fromJson({'enabled': false, 'languages': []});
      expect(catalog.enabled, isFalse);
      expect(catalog.languages, isEmpty);
    });
  });

  group('interpreterEngineFromJson', () {
    test('simultaneous', () {
      expect(interpreterEngineFromJson('simultaneous'),
          InterpreterEngine.simultaneous);
    });

    test('phrase', () {
      expect(interpreterEngineFromJson('phrase'), InterpreterEngine.phrase);
    });

    test('unknown falls back to phrase (the conservative UI)', () {
      expect(
          interpreterEngineFromJson('something_new'), InterpreterEngine.phrase);
    });
  });

  group('InterpreterDirections', () {
    test('parses both directions independently', () {
      final directions = InterpreterDirections.fromJson({
        'toMe': 'simultaneous',
        'fromMe': 'phrase',
      });
      expect(directions.toMe, InterpreterEngine.simultaneous);
      expect(directions.fromMe, InterpreterEngine.phrase);
    });
  });

  group('InterpreterPartner', () {
    test('parses with nulls', () {
      final partner = InterpreterPartner.fromJson({
        'firstName': null,
        'avatarUrl': null,
        'lang': 'de',
      });
      expect(partner.firstName, isNull);
      expect(partner.avatarUrl, isNull);
      expect(partner.lang, 'de');
    });

    test('parses full', () {
      final partner = InterpreterPartner.fromJson({
        'firstName': 'Anna',
        'avatarUrl': 'https://x/y.png',
        'lang': 'de',
      });
      expect(partner.firstName, 'Anna');
      expect(partner.avatarUrl, 'https://x/y.png');
    });
  });

  group('HostedSession', () {
    test('parses host session', () {
      final session = HostedSession.fromJson({
        'sessionId': 's1',
        'code': 'ABC123',
        'expiresAt': '2026-11-01T12:05:00Z',
        'roomName': 'interp-s1',
        'token': 'tok',
        'livekitWsUrl': 'wss://lk/',
      });
      expect(session.sessionId, 's1');
      expect(session.code, 'ABC123');
      expect(session.expiresAt, DateTime.parse('2026-11-01T12:05:00Z'));
      expect(session.roomName, 'interp-s1');
      expect(session.token, 'tok');
      expect(session.livekitWsUrl, 'wss://lk/');
    });
  });

  group('NewCode', () {
    test('parses new code', () {
      final code = NewCode.fromJson({
        'code': 'XYZ789',
        'expiresAt': '2026-11-01T12:10:00Z',
      });
      expect(code.code, 'XYZ789');
      expect(code.expiresAt, DateTime.parse('2026-11-01T12:10:00Z'));
    });
  });

  group('JoinedSession', () {
    test('parses guest join response', () {
      final joined = JoinedSession.fromJson({
        'sessionId': 's1',
        'roomName': 'interp-s1',
        'token': 'tok',
        'livekitWsUrl': 'wss://lk/',
        'partner': {'firstName': 'Dmitry', 'avatarUrl': null, 'lang': 'ru'},
        'directions': {'toMe': 'simultaneous', 'fromMe': 'simultaneous'},
      });
      expect(joined.sessionId, 's1');
      expect(joined.partner.firstName, 'Dmitry');
      expect(joined.partner.lang, 'ru');
      expect(joined.directions.toMe, InterpreterEngine.simultaneous);
    });
  });

  group('interpreterStatusFromJson', () {
    test(
        'waiting',
        () => expect(
            interpreterStatusFromJson('waiting'), InterpreterStatus.waiting));
    test(
        'active',
        () => expect(
            interpreterStatusFromJson('active'), InterpreterStatus.active));
    test(
        'ended',
        () => expect(
            interpreterStatusFromJson('ended'), InterpreterStatus.ended));
    test('unknown falls back to ended', () {
      expect(interpreterStatusFromJson('whatever'), InterpreterStatus.ended);
    });
  });

  group('interpreterEndReasonFromJson', () {
    const cases = {
      'hangup': InterpreterEndReason.hangup,
      'partner_left': InterpreterEndReason.partnerLeft,
      'expired': InterpreterEndReason.expired,
      'translation_failed': InterpreterEndReason.translationFailed,
      'agent_lost': InterpreterEndReason.agentLost,
      'no_funds': InterpreterEndReason.noFunds,
      'max_duration': InterpreterEndReason.maxDuration,
    };

    cases.forEach((raw, expected) {
      test('maps $raw', () {
        expect(interpreterEndReasonFromJson(raw), expected);
      });
    });

    test('null stays null', () {
      expect(interpreterEndReasonFromJson(null), isNull);
    });

    test('unknown code maps to null, not a guess', () {
      expect(interpreterEndReasonFromJson('something_new'), isNull);
    });
  });

  group('SessionView', () {
    test('parses a full host view', () {
      final view = SessionView.fromJson({
        'status': 'active',
        'endReason': null,
        'partner': {'firstName': 'B', 'avatarUrl': null, 'lang': 'en'},
        'directions': {'toMe': 'phrase', 'fromMe': 'simultaneous'},
        'startedAt': '2026-11-01T12:00:00Z',
        'spentPlanck': '12345',
      });
      expect(view.status, InterpreterStatus.active);
      expect(view.endReason, isNull);
      expect(view.partner!.firstName, 'B');
      expect(view.directions!.fromMe, InterpreterEngine.simultaneous);
      expect(view.startedAt, DateTime.parse('2026-11-01T12:00:00Z'));
      expect(view.spentPlanck, '12345');
    });

    test('parses a minimal waiting view (guest, before billing opens)', () {
      final view = SessionView.fromJson({
        'status': 'waiting',
        'endReason': null,
        'partner': null,
        'directions': null,
        'startedAt': null,
        'spentPlanck': null,
      });
      expect(view.status, InterpreterStatus.waiting);
      expect(view.partner, isNull);
      expect(view.directions, isNull);
      expect(view.startedAt, isNull);
      expect(view.spentPlanck, isNull);
    });

    test('parses an ended view with a reason', () {
      final view = SessionView.fromJson({
        'status': 'ended',
        'endReason': 'partner_left',
        'partner': null,
        'directions': null,
        'startedAt': '2026-11-01T12:00:00Z',
        'spentPlanck': '500',
      });
      expect(view.status, InterpreterStatus.ended);
      expect(view.endReason, InterpreterEndReason.partnerLeft);
    });
  });
}

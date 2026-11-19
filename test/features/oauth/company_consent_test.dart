import 'package:flutter_test/flutter_test.dart';
import 'package:taler_id_mobile/features/oauth/domain/entities/company_consent.dart';
import 'package:taler_id_mobile/features/oauth/domain/entities/grant_info.dart';

const _json = {
  'person': {'name': 'Иван Петров'},
  'eligible': [
    {'id': 'a', 'name': 'Ромашка', 'legal_name': 'ООО «Ромашка»', 'logo_url': null, 'role': 'OWNER'},
    {'id': 'b', 'name': 'Лютик', 'legal_name': null, 'logo_url': null, 'role': 'ADMIN'},
  ],
  'unverified': [
    {'id': 'c', 'name': 'Василёк'},
  ],
  'last_selection': {'act_as': 'a', 'company_ids': ['a']},
};

void main() {
  group('CompanyConsent.fromJson', () {
    test('reads the block grant-info sends', () {
      final c = CompanyConsent.fromJson(_json);
      expect(c.personName, 'Иван Петров');
      expect(c.eligible.map((e) => e.displayName), ['ООО «Ромашка»', 'Лютик']);
      expect(c.unverified.single.name, 'Василёк');
      expect(c.lastSelection, const CompanySelection(actAs: 'a', companyIds: ['a']));
    });

    test('round-trips through toJson without jsonEncode', () {
      final c = CompanyConsent.fromJson(_json);
      expect(CompanyConsent.fromJson(c.toJson()), c);
    });

    test('null stays null', () {
      expect(CompanyConsent.fromJsonOrNull(null), isNull);
    });

    test('a malformed block is dropped, not thrown — sign-in goes on as a person', () {
      final badId = {
        ..._json,
        'eligible': [
          {'id': null, 'name': 'Ромашка', 'role': 'OWNER'},
        ],
      };
      expect(CompanyConsent.fromJsonOrNull(badId), isNull);
      expect(CompanyConsent.fromJsonOrNull({..._json, 'eligible': 'oops'}), isNull);
      expect(CompanyConsent.fromJsonOrNull({..._json, 'last_selection': {'company_ids': 'a'}}),
          isNull);
      expect(CompanyConsent.fromJsonOrNull('oops'), isNull);

      final g = GrantInfo.fromJson(
          {'client_name': 'Trientes', 'scopes': [], 'remembered': false, 'companies': badId});
      expect(g.companies, isNull);
      expect(g.clientName, 'Trientes');
    });
  });

  group('CompanySelection', () {
    test('defaults: last choice if any, otherwise a person sharing nothing', () {
      final c = CompanyConsent.fromJson(_json);
      expect(CompanySelection.initialFor(c), const CompanySelection(actAs: 'a', companyIds: ['a']));
      final noLast = CompanyConsent.fromJson({..._json, 'last_selection': null});
      expect(CompanySelection.initialFor(noLast), const CompanySelection(actAs: 'person', companyIds: []));
    });

    test('the initial choice only holds eligible companies and shares the act-as one', () {
      final c = CompanyConsent.fromJson(_json);
      CompanySelection initialFrom(Map<String, dynamic> last) =>
          CompanySelection.initialFor(CompanyConsent.fromJson({..._json, 'last_selection': last}));

      expect(initialFrom({'act_as': 'b', 'company_ids': []}),
          const CompanySelection(actAs: 'b', companyIds: ['b']));
      expect(initialFrom({'act_as': 'person', 'company_ids': ['z', 'b', 'c']}),
          const CompanySelection(actAs: 'person', companyIds: ['b']));
      // компания из «войти как» больше не подходит → вход физлицом
      expect(initialFrom({'act_as': 'z', 'company_ids': ['z', 'a']}),
          const CompanySelection(actAs: 'person', companyIds: ['a']));
      expect(CompanySelection.initialFor(c), const CompanySelection(actAs: 'a', companyIds: ['a']));
    });

    test('acting as a company always shares it', () {
      const s = CompanySelection(actAs: 'person', companyIds: []);
      expect(s.withActAs('b'), const CompanySelection(actAs: 'b', companyIds: ['b']));
    });

    test('the act-as company cannot be unshared, others toggle', () {
      const s = CompanySelection(actAs: 'a', companyIds: ['a']);
      expect(s.toggled('a', false), s);
      expect(s.toggled('b', true), const CompanySelection(actAs: 'a', companyIds: ['a', 'b']));
      expect(s.toggled('b', true).toggled('b', false), s);
    });

    test('approve body', () {
      expect(const CompanySelection(actAs: 'a', companyIds: ['a', 'b']).toApproveFields(),
          {'act_as': 'a', 'company_ids': ['a', 'b']});
    });
  });

  group('GrantInfo.companies', () {
    test('parsed when grant-info sends it', () {
      final g = GrantInfo.fromJson({
        'client_name': 'Trientes',
        'scopes': [],
        'remembered': false,
        'companies': _json,
      });
      expect(g.companies?.eligible.length, 2);
    });

    test('absent → null, older backends unaffected', () {
      final g = GrantInfo.fromJson({'client_name': 'MyBook', 'scopes': [], 'remembered': true});
      expect(g.companies, isNull);
    });

    test('round-trips without jsonEncode', () {
      final g = GrantInfo.fromJson({'client_name': 'T', 'scopes': [], 'remembered': false, 'companies': _json});
      expect(GrantInfo.fromJson(g.toJson()), g);
    });
  });
}

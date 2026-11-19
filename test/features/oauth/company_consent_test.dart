import 'package:flutter_test/flutter_test.dart';
import 'package:taler_id_mobile/features/oauth/domain/entities/company_consent.dart';

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
  });

  group('CompanySelection', () {
    test('defaults: last choice if any, otherwise a person sharing nothing', () {
      final c = CompanyConsent.fromJson(_json);
      expect(CompanySelection.initialFor(c), const CompanySelection(actAs: 'a', companyIds: ['a']));
      final noLast = CompanyConsent.fromJson({..._json, 'last_selection': null});
      expect(CompanySelection.initialFor(noLast), const CompanySelection(actAs: 'person', companyIds: []));
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
}

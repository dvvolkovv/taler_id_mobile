import 'package:equatable/equatable.dart';

/// Блок «компании» из /oauth/mobile/grant-info (scope `companies`).
///
/// Обычные классы, а не freezed: вложенная freezed-сущность в freezed-модели
/// требует explicitToJson и легко ломает fromJson(toJson()) — здесь (де)сериализация
/// явная. Спека taler-id: docs/superpowers/specs/2026-11-19-companies-oauth-design.md
class CompanyConsent extends Equatable {
  final String personName;
  final List<CompanyOption> eligible;
  final List<UnverifiedCompany> unverified;
  final CompanySelection? lastSelection;

  const CompanyConsent({
    required this.personName,
    required this.eligible,
    required this.unverified,
    this.lastSelection,
  });

  factory CompanyConsent.fromJson(Map<String, dynamic> json) {
    final last = json['last_selection'] as Map?;
    return CompanyConsent(
      personName: ((json['person'] as Map?)?['name'] as String?) ?? '',
      eligible: ((json['eligible'] as List?) ?? const [])
          .map((e) => CompanyOption.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      unverified: ((json['unverified'] as List?) ?? const [])
          .map((e) => UnverifiedCompany.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      lastSelection: last == null
          ? null
          : CompanySelection(
              actAs: last['act_as'] as String? ?? CompanySelection.person,
              companyIds: List<String>.from(last['company_ids'] as List? ?? const []),
            ),
    );
  }

  /// Битый блок (не те типы, нет id) — null, а не исключение: из-за него не
  /// должен ломаться вход на сайт целиком. Без выбора сервер считает вход
  /// физлицом.
  static CompanyConsent? fromJsonOrNull(Object? json) {
    if (json == null) return null;
    try {
      return CompanyConsent.fromJson(Map<String, dynamic>.from(json as Map));
    } catch (_) {
      return null;
    }
  }

  static Map<String, dynamic>? toJsonOrNull(CompanyConsent? c) => c?.toJson();

  Map<String, dynamic> toJson() => {
        'person': {'name': personName},
        'eligible': eligible.map((e) => e.toJson()).toList(),
        'unverified': unverified.map((e) => e.toJson()).toList(),
        'last_selection': lastSelection?.toApproveFields(),
      };

  @override
  List<Object?> get props => [personName, eligible, unverified, lastSelection];
}

class CompanyOption extends Equatable {
  final String id;
  final String name;
  final String? legalName;
  final String? logoUrl;
  final String role;

  const CompanyOption({
    required this.id,
    required this.name,
    this.legalName,
    this.logoUrl,
    required this.role,
  });

  /// Проверенное юридическое название, если есть, иначе название в Taler ID.
  String get displayName => legalName ?? name;

  factory CompanyOption.fromJson(Map<String, dynamic> json) => CompanyOption(
        id: json['id'] as String,
        name: json['name'] as String? ?? '',
        legalName: json['legal_name'] as String?,
        logoUrl: json['logo_url'] as String?,
        role: json['role'] as String? ?? '',
      );

  Map<String, dynamic> toJson() =>
      {'id': id, 'name': name, 'legal_name': legalName, 'logo_url': logoUrl, 'role': role};

  @override
  List<Object?> get props => [id, name, legalName, logoUrl, role];
}

class UnverifiedCompany extends Equatable {
  final String id;
  final String name;

  const UnverifiedCompany({required this.id, required this.name});

  factory UnverifiedCompany.fromJson(Map<String, dynamic> json) =>
      UnverifiedCompany(id: json['id'] as String, name: json['name'] as String? ?? '');

  Map<String, dynamic> toJson() => {'id': id, 'name': name};

  @override
  List<Object?> get props => [id, name];
}

/// «Войти как» и «какие компании передать». Компания из «войти как»
/// передаётся всегда — снять её галочку нельзя (сервер проверяет то же).
class CompanySelection extends Equatable {
  static const person = 'person';

  final String actAs;
  final List<String> companyIds;

  const CompanySelection({required this.actAs, required this.companyIds});

  factory CompanySelection.initialFor(CompanyConsent c) =>
      (c.lastSelection ?? const CompanySelection(actAs: person, companyIds: [])).restrictedTo(c);

  /// Тот же выбор, суженный до подходящих компаний [c]: неподходящие
  /// выпадают (если это компания из «войти как» — вход становится от
  /// физлица), а компания из «войти как» всегда среди передаваемых.
  CompanySelection restrictedTo(CompanyConsent c) {
    final eligible = {for (final e in c.eligible) e.id};
    final act = eligible.contains(actAs) ? actAs : person;
    final shared = <String>[];
    for (final id in companyIds) {
      if (eligible.contains(id) && !shared.contains(id)) shared.add(id);
    }
    if (act != person && !shared.contains(act)) shared.add(act);
    return CompanySelection(actAs: act, companyIds: shared);
  }

  CompanySelection withActAs(String id) => CompanySelection(
        actAs: id,
        companyIds: id == person || companyIds.contains(id) ? companyIds : [...companyIds, id],
      );

  CompanySelection toggled(String id, bool on) {
    if (id == actAs) return this;
    final rest = companyIds.where((x) => x != id).toList();
    return CompanySelection(actAs: actAs, companyIds: on ? [...rest, id] : rest);
  }

  Map<String, dynamic> toApproveFields() => {'act_as': actAs, 'company_ids': companyIds};

  @override
  List<Object?> get props => [actAs, companyIds];
}

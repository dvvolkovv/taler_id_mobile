// ignore_for_file: invalid_annotation_target
import 'package:freezed_annotation/freezed_annotation.dart';
import 'company_consent.dart';
import 'scope_descriptor.dart';

part 'grant_info.freezed.dart';
part 'grant_info.g.dart';

@freezed
class GrantInfo with _$GrantInfo {
  const factory GrantInfo({
    @JsonKey(name: 'client_name') required String clientName,
    @JsonKey(name: 'client_logo') String? clientLogo,
    required List<ScopeDescriptor> scopes,
    required bool remembered,
    /// Блок scope `companies`; (де)сериализация явная — см. company_consent.dart.
    @JsonKey(fromJson: CompanyConsent.fromJsonOrNull, toJson: CompanyConsent.toJsonOrNull)
    CompanyConsent? companies,
  }) = _GrantInfo;

  factory GrantInfo.fromJson(Map<String, dynamic> json) =>
      _$GrantInfoFromJson(json);
}

import 'package:equatable/equatable.dart';
import '../../domain/entities/company_consent.dart';
import '../../domain/entities/grant_info.dart';
import '../../domain/entities/oauth_authorize_params.dart';

abstract class OAuthAuthorizeState extends Equatable {
  const OAuthAuthorizeState();
  @override
  List<Object?> get props => [];
}

class OAuthInitial extends OAuthAuthorizeState {
  const OAuthInitial();
}

class OAuthLoading extends OAuthAuthorizeState {
  const OAuthLoading();
}

/// Почему не прошло одобрение; текст подбирает экран.
enum OAuthApproveError {
  /// Запрос не прошёл — можно повторить как есть.
  failed,

  /// Запрос с выбором компаний не прошёл (например, компанию сняли с KYB
  /// между grant-info и approve): список перечитан, выбор сужен до него.
  companiesChanged,
}

class OAuthConsentRequired extends OAuthAuthorizeState {
  final GrantInfo grantInfo;
  final OAuthAuthorizeParams params;
  /// Есть, только если сайт просит `companies` и есть подходящая компания.
  final CompanySelection? selection;
  /// Предыдущая попытка «Разрешить» не прошла; держится до следующей.
  final OAuthApproveError? error;
  const OAuthConsentRequired(this.grantInfo, this.params, {this.selection, this.error});
  @override
  List<Object?> get props => [grantInfo, params, selection, error];
}

class OAuthApproving extends OAuthAuthorizeState {
  final GrantInfo grantInfo;
  final OAuthAuthorizeParams params;
  final CompanySelection? selection;
  const OAuthApproving(this.grantInfo, this.params, {this.selection});
  @override
  List<Object?> get props => [grantInfo, params, selection];
}

class OAuthAutoApproving extends OAuthAuthorizeState {
  const OAuthAutoApproving();
}

class OAuthSuccess extends OAuthAuthorizeState {
  final String redirectUri;
  const OAuthSuccess(this.redirectUri);
  @override
  List<Object?> get props => [redirectUri];
}

class OAuthCancelled extends OAuthAuthorizeState {
  final String redirectUri;
  const OAuthCancelled(this.redirectUri);
  @override
  List<Object?> get props => [redirectUri];
}

class OAuthFailure extends OAuthAuthorizeState {
  final String message;
  final OAuthAuthorizeParams params;
  const OAuthFailure(this.message, this.params);
  @override
  List<Object?> get props => [message, params];
}

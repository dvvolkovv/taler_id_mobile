import 'package:equatable/equatable.dart';
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

class OAuthConsentRequired extends OAuthAuthorizeState {
  final GrantInfo grantInfo;
  final OAuthAuthorizeParams params;
  const OAuthConsentRequired(this.grantInfo, this.params);
  @override
  List<Object?> get props => [grantInfo, params];
}

class OAuthApproving extends OAuthAuthorizeState {
  final GrantInfo grantInfo;
  final OAuthAuthorizeParams params;
  const OAuthApproving(this.grantInfo, this.params);
  @override
  List<Object?> get props => [grantInfo, params];
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

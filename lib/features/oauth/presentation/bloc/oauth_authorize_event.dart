import 'package:equatable/equatable.dart';
import '../../domain/entities/oauth_authorize_params.dart';

abstract class OAuthAuthorizeEvent extends Equatable {
  const OAuthAuthorizeEvent();
  @override
  List<Object?> get props => [];
}

class LoadGrantInfo extends OAuthAuthorizeEvent {
  final OAuthAuthorizeParams params;
  const LoadGrantInfo(this.params);
  @override
  List<Object?> get props => [params];
}

class ApprovePressed extends OAuthAuthorizeEvent {
  const ApprovePressed();
}

class CancelPressed extends OAuthAuthorizeEvent {
  const CancelPressed();
}

class ActAsChanged extends OAuthAuthorizeEvent {
  /// 'person' или id компании.
  final String actAs;
  const ActAsChanged(this.actAs);
  @override
  List<Object?> get props => [actAs];
}

class ShareToggled extends OAuthAuthorizeEvent {
  final String companyId;
  final bool on;
  const ShareToggled(this.companyId, this.on);
  @override
  List<Object?> get props => [companyId, on];
}

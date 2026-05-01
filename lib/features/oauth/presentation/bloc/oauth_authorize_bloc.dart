import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/grant_info.dart';
import '../../domain/entities/oauth_authorize_params.dart';
import '../../domain/repositories/oauth_repository.dart';
import 'oauth_authorize_event.dart';
import 'oauth_authorize_state.dart';

class OAuthAuthorizeBloc extends Bloc<OAuthAuthorizeEvent, OAuthAuthorizeState> {
  final OAuthRepository _repo;
  OAuthAuthorizeParams? _currentParams;
  GrantInfo? _currentGrantInfo;

  OAuthAuthorizeBloc(this._repo) : super(const OAuthInitial()) {
    on<LoadGrantInfo>(_onLoad);
    on<ApprovePressed>(_onApprove);
    on<CancelPressed>(_onCancel);
  }

  Future<void> _onLoad(LoadGrantInfo event, Emitter<OAuthAuthorizeState> emit) async {
    _currentParams = event.params;
    emit(const OAuthLoading());
    try {
      final grantInfo = await _repo.getGrantInfo(event.params);
      _currentGrantInfo = grantInfo;
      if (grantInfo.remembered) {
        emit(const OAuthAutoApproving());
        final result = await _repo.approve(event.params);
        emit(OAuthSuccess(result.redirectUri));
      } else {
        emit(OAuthConsentRequired(grantInfo, event.params));
      }
    } catch (e) {
      emit(OAuthFailure(e.toString(), event.params));
    }
  }

  Future<void> _onApprove(ApprovePressed event, Emitter<OAuthAuthorizeState> emit) async {
    // Resolve params/grantInfo from current state (handles seed() in tests)
    // or fall back to the stored fields set during LoadGrantInfo.
    OAuthAuthorizeParams? params;
    GrantInfo? grantInfo;
    final s = state;
    if (s is OAuthConsentRequired) {
      params = s.params;
      grantInfo = s.grantInfo;
    } else {
      params = _currentParams;
      grantInfo = _currentGrantInfo;
    }
    if (params == null || grantInfo == null) return;
    emit(OAuthApproving(grantInfo, params));
    try {
      final result = await _repo.approve(params);
      emit(OAuthSuccess(result.redirectUri));
    } catch (_) {
      emit(OAuthConsentRequired(grantInfo, params));
    }
  }

  void _onCancel(CancelPressed event, Emitter<OAuthAuthorizeState> emit) {
    // Resolve params from current state (handles seed() in tests)
    // or fall back to the stored field set during LoadGrantInfo.
    OAuthAuthorizeParams? params;
    final s = state;
    if (s is OAuthConsentRequired) {
      params = s.params;
    } else {
      params = _currentParams;
    }
    if (params == null) return;
    final uri = Uri.parse(params.redirectUri).replace(queryParameters: {
      'error': 'access_denied',
      if (params.state != null) 'state': params.state!,
    });
    emit(OAuthCancelled(uri.toString()));
  }
}

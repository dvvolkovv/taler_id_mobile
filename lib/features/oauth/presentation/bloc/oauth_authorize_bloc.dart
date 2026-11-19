import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/company_consent.dart';
import '../../domain/entities/grant_info.dart';
import '../../domain/entities/oauth_authorize_params.dart';
import '../../domain/repositories/oauth_repository.dart';
import 'oauth_authorize_event.dart';
import 'oauth_authorize_state.dart';

class OAuthAuthorizeBloc extends Bloc<OAuthAuthorizeEvent, OAuthAuthorizeState> {
  final OAuthRepository _repo;
  OAuthAuthorizeParams? _currentParams;
  GrantInfo? _currentGrantInfo;
  CompanySelection? _currentSelection;

  OAuthAuthorizeBloc(this._repo) : super(const OAuthInitial()) {
    on<LoadGrantInfo>(_onLoad);
    on<ApprovePressed>(_onApprove);
    on<CancelPressed>(_onCancel);
    on<ActAsChanged>(_onActAs);
    on<ShareToggled>(_onShare);
  }

  Future<void> _onLoad(LoadGrantInfo event, Emitter<OAuthAuthorizeState> emit) async {
    _currentSelection = null;
    _currentParams = event.params;
    emit(const OAuthLoading());
    try {
      final grantInfo = await _repo.getGrantInfo(event.params);
      _currentGrantInfo = grantInfo;
      if (grantInfo.remembered) {
        // Без выбора: бэкенд не ставит remembered, когда есть компания на выбор.
        emit(const OAuthAutoApproving());
        final result = await _repo.approve(event.params);
        emit(OAuthSuccess(result.redirectUri));
      } else {
        final companies = grantInfo.companies;
        _currentSelection = companies != null && companies.eligible.isNotEmpty
            ? CompanySelection.initialFor(companies)
            : null;
        emit(OAuthConsentRequired(grantInfo, event.params, selection: _currentSelection));
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
    CompanySelection? selection;
    final s = state;
    if (s is OAuthConsentRequired) {
      params = s.params;
      grantInfo = s.grantInfo;
      selection = s.selection;
    } else {
      params = _currentParams;
      grantInfo = _currentGrantInfo;
      selection = _currentSelection;
    }
    if (params == null || grantInfo == null) return;
    emit(OAuthApproving(grantInfo, params, selection: selection));
    try {
      final result = await _repo.approve(params, selection: selection);
      emit(OAuthSuccess(result.redirectUri));
    } catch (_) {
      if (selection == null) {
        emit(OAuthConsentRequired(grantInfo, params, error: OAuthApproveError.failed));
        return;
      }
      await _reloadAfterRejectedChoice(params, selection, emit);
    }
  }

  // Выбор компаний мог устареть между grant-info и approve (компанию сняли с
  // KYB, у пользователя отобрали роль) — сервер отвечает 400, и повторная
  // отправка того же выбора падала бы снова и молча. Перечитываем список и
  // сужаем выбор пользователя до него, а не сбрасываем к last_selection.
  Future<void> _reloadAfterRejectedChoice(
    OAuthAuthorizeParams params,
    CompanySelection selection,
    Emitter<OAuthAuthorizeState> emit,
  ) async {
    try {
      final fresh = await _repo.getGrantInfo(params);
      _currentGrantInfo = fresh;
      final companies = fresh.companies;
      _currentSelection = companies != null && companies.eligible.isNotEmpty
          ? selection.restrictedTo(companies)
          : null;
      emit(OAuthConsentRequired(fresh, params,
          selection: _currentSelection, error: OAuthApproveError.companiesChanged));
    } catch (e) {
      // Не перечитать — экран ошибки: его «Повторить» загружает список заново.
      emit(OAuthFailure(e.toString(), params));
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

  void _onActAs(ActAsChanged event, Emitter<OAuthAuthorizeState> emit) {
    final s = state;
    if (s is! OAuthConsentRequired || s.selection == null) return;
    _currentSelection = s.selection!.withActAs(event.actAs);
    emit(OAuthConsentRequired(s.grantInfo, s.params,
        selection: _currentSelection, error: s.error));
  }

  void _onShare(ShareToggled event, Emitter<OAuthAuthorizeState> emit) {
    final s = state;
    if (s is! OAuthConsentRequired || s.selection == null) return;
    final next = s.selection!.toggled(event.companyId, event.on);
    if (next == s.selection) return;
    _currentSelection = next;
    emit(OAuthConsentRequired(s.grantInfo, s.params, selection: next, error: s.error));
  }
}

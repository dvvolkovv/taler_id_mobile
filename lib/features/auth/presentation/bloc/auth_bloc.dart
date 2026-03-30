import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/repositories/i_auth_repository.dart';
import '../../../../core/api/api_exception.dart';
import '../../../../core/utils/error_keys.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final IAuthRepository authRepository;

  AuthBloc({required this.authRepository}) : super(AuthInitial()) {
    on<LoginSubmitted>(_onLogin);
    on<RegisterSubmitted>(_onRegister);
    on<TwoFASubmitted>(_onTwoFA);
    on<LogoutRequested>(_onLogout);
    on<ForgotPasswordRequested>(_onForgotPassword);
    on<ForgotPasswordCodeVerified>(_onForgotPasswordCodeVerified);
    on<ForgotPasswordNewPassword>(_onForgotPasswordNewPassword);
  }

  Future<void> _onLogin(LoginSubmitted event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final tokens = await authRepository.login(
        email: event.email,
        password: event.password,
      );
      emit(AuthSuccess(tokens.accessToken));
    } on TwoFARequiredException catch (e) {
      emit(AuthRequires2FA(email: e.email, tempToken: e.tempToken));
    } on ApiException catch (e) {
      emit(AuthFailure(e.message));
    } catch (e) {
      emit(AuthFailure(ErrorKeys.generalError));
    }
  }

  Future<void> _onRegister(RegisterSubmitted event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final tokens = await authRepository.register(
        email: event.email,
        password: event.password,
        firstName: event.firstName,
        lastName: event.lastName,
        username: event.username,
      );
      emit(AuthSuccess(tokens.accessToken));
    } on ApiException catch (e) {
      emit(AuthFailure(e.message));
    } catch (e) {
      emit(AuthFailure(ErrorKeys.generalError));
    }
  }

  Future<void> _onTwoFA(TwoFASubmitted event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final tokens = await authRepository.verify2FA(
        email: event.email,
        code: event.code,
        tempToken: event.tempToken,
      );
      emit(AuthSuccess(tokens.accessToken));
    } on ApiException catch (e) {
      emit(AuthFailure(e.message));
    } catch (e) {
      emit(AuthFailure(ErrorKeys.invalidCode));
    }
  }

  Future<void> _onLogout(LogoutRequested event, Emitter<AuthState> emit) async {
    await authRepository.logout();
    emit(AuthLoggedOut());
  }

  Future<void> _onForgotPassword(ForgotPasswordRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      await authRepository.requestPasswordReset(event.email);
      emit(PasswordResetCodeSent(email: event.email));
    } on ApiException catch (e) {
      emit(AuthFailure(e.message));
    } catch (e) {
      emit(AuthFailure(ErrorKeys.generalError));
    }
  }

  Future<void> _onForgotPasswordCodeVerified(ForgotPasswordCodeVerified event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final resetToken = await authRepository.verifyPasswordResetCode(
        email: event.email,
        code: event.code,
      );
      emit(PasswordResetCodeVerified(email: event.email, resetToken: resetToken));
    } on ApiException catch (e) {
      emit(AuthFailure(e.message));
    } catch (e) {
      emit(AuthFailure(ErrorKeys.invalidCode));
    }
  }

  Future<void> _onForgotPasswordNewPassword(ForgotPasswordNewPassword event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      await authRepository.resetPassword(
        resetToken: event.resetToken,
        newPassword: event.newPassword,
      );
      emit(PasswordResetSuccess());
    } on ApiException catch (e) {
      emit(AuthFailure(e.message));
    } catch (e) {
      emit(AuthFailure(ErrorKeys.generalError));
    }
  }
}

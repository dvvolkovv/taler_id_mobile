import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/repositories/i_auth_repository.dart';
import '../../../../core/api/api_exception.dart';
import '../../../../core/utils/error_keys.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/mesh/mesh_bootstrap.dart';
import '../../../../core/mesh/services/mesh_messaging_service.dart';
import '../../../mesh/presentation/bloc/mesh_status_bloc.dart';
import '../../../messenger/presentation/bloc/messenger_bloc.dart';
import '../../../messenger/presentation/bloc/messenger_event.dart';
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
    on<EmailVerifySendRequested>(_onEmailVerifySend);
    on<EmailVerifySubmitted>(_onEmailVerifySubmit);
  }

  Future<void> _onLogin(LoginSubmitted event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final tokens = await authRepository.login(
        email: event.email,
        password: event.password,
      );
      emit(AuthSuccess(tokens.accessToken));
      unawaited(_bootstrapMeshAfterLogin());
    } on TwoFARequiredException catch (e) {
      emit(AuthRequires2FA(email: e.email, challengeToken: e.challengeToken));
    } on DeviceApprovalRequiredException catch (e) {
      emit(AuthRequiresDeviceApproval(
        approvalToken: e.approvalToken,
        approverCount: e.approverCount,
        emailAvailable: e.emailAvailable,
        expiresIn: e.expiresIn,
      ));
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
      unawaited(_bootstrapMeshAfterLogin());
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
        code: event.code,
        challengeToken: event.challengeToken,
      );
      emit(AuthSuccess(tokens.accessToken));
      unawaited(_bootstrapMeshAfterLogin());
    } on DeviceApprovalRequiredException catch (e) {
      emit(AuthRequiresDeviceApproval(
        approvalToken: e.approvalToken,
        approverCount: e.approverCount,
        emailAvailable: e.emailAvailable,
        expiresIn: e.expiresIn,
      ));
    } on ApiException catch (e) {
      emit(AuthFailure(e.message));
    } catch (e) {
      emit(AuthFailure(ErrorKeys.invalidCode));
    }
  }

  Future<void> _onLogout(LogoutRequested event, Emitter<AuthState> emit) async {
    // Drop the messenger socket so the dashboard's connect-guard reconnects
    // with the new account's JWT on next login. Without this, the previous
    // user's authenticated socket stays alive and outbound messages keep
    // being signed as that user.
    try {
      sl<MessengerBloc>().add(const DisconnectMessenger());
    } catch (_) {}
    await authRepository.logout();
    await _teardownMeshOnLogout();
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

  Future<void> _onEmailVerifySend(EmailVerifySendRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final result = await authRepository.sendEmailVerification();
      emit(EmailVerifyCodeSent(alreadyVerified: result['alreadyVerified'] == true));
    } on ApiException catch (e) {
      emit(AuthFailure(e.message));
    } catch (e) {
      emit(AuthFailure(ErrorKeys.generalError));
    }
  }

  Future<void> _onEmailVerifySubmit(EmailVerifySubmitted event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      await authRepository.confirmEmailVerification(event.code);
      emit(EmailVerifySuccess());
    } on ApiException catch (e) {
      emit(AuthFailure(e.message));
    } catch (e) {
      emit(AuthFailure(ErrorKeys.invalidCode));
    }
  }

  // ---------------------------------------------------------------------------
  // Mesh Phase 1e — bootstrap / teardown helpers
  // ---------------------------------------------------------------------------

  Future<void> _bootstrapMeshAfterLogin() =>
      runMeshBootstrapIfAuthenticated();

  Future<void> _teardownMeshOnLogout() async {
    try {
      if (sl.isRegistered<MeshMessagingService>()) {
        try {
          await sl<MeshMessagingService>().dispose();
        } catch (_) {}
        await sl.unregister<MeshMessagingService>();
      }
    } catch (_) {
      // swallow
    }
    // I2: reflect stopped state in the Settings card.
    try {
      sl<MeshStatusBloc>().markRunning(false);
    } catch (_) {}
  }
}

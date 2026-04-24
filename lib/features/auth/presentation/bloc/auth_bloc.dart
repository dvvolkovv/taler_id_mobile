import 'dart:async';
import 'dart:convert';

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/repositories/i_auth_repository.dart';
import '../../../../core/api/api_exception.dart';
import '../../../../core/utils/error_keys.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/mesh/crypto/keys/mesh_static_key.dart';
import '../../../../core/mesh/crypto/keys/user_identity_key.dart';
import '../../../../core/mesh/crypto/keys/contact_key_store_hive.dart';
import '../../../../core/mesh/services/device_key_sync_service.dart';
import '../../../../core/mesh/services/device_keys_api_client.dart';
import '../../../../core/mesh/services/mesh_messaging_service.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../../mesh/presentation/bloc/mesh_status_bloc.dart';
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
      unawaited(_bootstrapMeshAfterLogin());
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
        email: event.email,
        code: event.code,
        tempToken: event.tempToken,
      );
      emit(AuthSuccess(tokens.accessToken));
      unawaited(_bootstrapMeshAfterLogin());
    } on ApiException catch (e) {
      emit(AuthFailure(e.message));
    } catch (e) {
      emit(AuthFailure(ErrorKeys.invalidCode));
    }
  }

  Future<void> _onLogout(LogoutRequested event, Emitter<AuthState> emit) async {
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

  // ---------------------------------------------------------------------------
  // Mesh Phase 1e — bootstrap / teardown helpers
  // ---------------------------------------------------------------------------

  Future<void> _bootstrapMeshAfterLogin() async {
    try {
      final storage = sl<SecureStorageService>();
      final accessToken = await storage.getAccessToken();
      if (accessToken == null || accessToken.isEmpty) return;
      final userId = _decodeSubFromJwt(accessToken);
      if (userId == null) return;

      // Re-register DeviceKeySyncService with the real JWT userId. The
      // registration performed in service_locator used a placeholder that
      // could not pass backend authentication.
      if (sl.isRegistered<DeviceKeySyncService>()) {
        await sl.unregister<DeviceKeySyncService>();
      }
      sl.registerLazySingleton<DeviceKeySyncService>(
        () => DeviceKeySyncService(
          api: sl<DeviceKeysApiClient>(),
          store: sl<HiveContactKeyStore>(),
          userIdentityKey: sl<UserIdentityKey>(),
          meshStaticKey: sl<MeshStaticKey>(),
          myUserId: userId,
        ),
      );

      try {
        await sl<DeviceKeySyncService>().registerOwnDevice();
      } catch (_) {
        // best-effort; FCM/backend registration failure must not block UX
      }

      if (sl.isRegistered<MeshMessagingService>()) {
        try {
          await sl<MeshMessagingService>()
              .start(serviceName: 'taler-mesh-$userId');
        } catch (_) {
          // transport may already be started by a previous session
        }
      }

      // I2: reflect running state in the Settings card.
      try {
        sl<MeshStatusBloc>().markRunning(true);
      } catch (_) {}
    } catch (_) {
      // Mesh bootstrap must never block the login UX.
    }
  }

  String? _decodeSubFromJwt(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      final payload = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      ) as Map<String, dynamic>;
      return payload['sub'] as String?;
    } catch (_) {
      return null;
    }
  }

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

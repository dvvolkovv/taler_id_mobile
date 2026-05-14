import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../../../core/platform/call_kit.dart';
import '../../../../core/platform/fcm_messaging.dart';
import '../../domain/entities/auth_entities.dart';
import '../../domain/repositories/i_auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../../../core/storage/cache_service.dart';
import '../../../../core/di/service_locator.dart';

class AuthRepositoryImpl implements IAuthRepository {
  final AuthRemoteDataSource remote;
  final SecureStorageService storage;

  AuthRepositoryImpl({required this.remote, required this.storage});

  Future<void> _saveUserIdFromToken(String accessToken) async {
    try {
      final parts = accessToken.split('.');
      if (parts.length == 3) {
        final payload = utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
        final map = jsonDecode(payload) as Map<String, dynamic>;
        final sub = map['sub'] as String?;
        if (sub != null) await storage.saveUserId(sub);
      }
    } catch (_) {}
  }

  @override
  Future<AuthTokens> login({required String email, required String password}) async {
    final data = await remote.login(email, password);
    if (data['requires2FA'] == true) {
      // Signal 2FA needed by throwing with special data
      throw TwoFARequiredException(
        tempToken: data['tempToken'] as String,
        email: email,
      );
    }
    final tokens = AuthTokens(
      accessToken: data['accessToken'] as String,
      refreshToken: data['refreshToken'] as String,
    );
    await storage.saveTokens(
      accessToken: tokens.accessToken,
      refreshToken: tokens.refreshToken,
    );
    await _saveUserIdFromToken(tokens.accessToken);
    return tokens;
  }

  @override
  Future<AuthTokens> register({
    required String email,
    required String password,
    String? firstName,
    String? lastName,
    String? username,
  }) async {
    final data = await remote.register(
      email: email,
      password: password,
      firstName: firstName,
      lastName: lastName,
      username: username,
    );
    final tokens = AuthTokens(
      accessToken: data['accessToken'] as String,
      refreshToken: data['refreshToken'] as String,
    );
    await storage.saveTokens(
      accessToken: tokens.accessToken,
      refreshToken: tokens.refreshToken,
    );
    await _saveUserIdFromToken(tokens.accessToken);
    return tokens;
  }

  @override
  Future<AuthTokens> verify2FA({
    required String email,
    required String code,
    required String tempToken,
  }) async {
    final data = await remote.verify2FA(
      email: email,
      code: code,
      tempToken: tempToken,
    );
    final tokens = AuthTokens(
      accessToken: data['accessToken'] as String,
      refreshToken: data['refreshToken'] as String,
    );
    await storage.saveTokens(
      accessToken: tokens.accessToken,
      refreshToken: tokens.refreshToken,
    );
    await _saveUserIdFromToken(tokens.accessToken);
    return tokens;
  }

  @override
  Future<AuthTokens> refreshToken(String refreshToken) async {
    // Handled by AuthInterceptor
    throw UnimplementedError('Handled by AuthInterceptor');
  }

  @override
  Future<void> logout() async {
    try {
      // Collect push tokens to clear from backend on logout
      String? fcmToken;
      String? voipToken;
      try {
        fcmToken = await FcmMessagingPlatform.instance.getToken();
        if (!kIsWeb && Platform.isIOS) {
          voipToken = await CallKitPlatform.instance.getDevicePushTokenVoIP();
        }
      } catch (_) {}
      await remote
          .logout(fcmToken: fcmToken, voipToken: voipToken?.isNotEmpty == true ? voipToken : null)
          .timeout(const Duration(seconds: 3));
    } catch (_) {
      // Server call may fail/hang (expired token, network error, slow server) — ignore
    }
    await storage.clearTokens();
    // Reset onboarding flag so the next user sees permission prompts
    await storage.clearOnboardingSeen();
    // Clear cached profile so the next login gets fresh data
    try {
      await sl<CacheService>().clearAll();
    } catch (_) {}
  }

  @override
  Future<void> requestPasswordReset(String email) async {
    await remote.requestPasswordReset(email);
  }

  @override
  Future<String> verifyPasswordResetCode({required String email, required String code}) async {
    final data = await remote.verifyPasswordResetCode(email: email, code: code);
    return data['resetToken'] as String;
  }

  @override
  Future<void> resetPassword({required String resetToken, required String newPassword}) async {
    await remote.resetPassword(resetToken: resetToken, newPassword: newPassword);
  }
}

class TwoFARequiredException implements Exception {
  final String tempToken;
  final String email;
  TwoFARequiredException({required this.tempToken, required this.email});
}

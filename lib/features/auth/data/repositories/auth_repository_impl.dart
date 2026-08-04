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
import '../../../../core/services/messenger_cache_service.dart';
import '../../../../core/services/pending_message_service.dart';
import '../../../../core/mesh/crypto/keys/contact_key_store_hive.dart';
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

    // Пароль верный, но вход ещё не закончен. Имена полей здесь обязаны
    // совпадать с бэкендом дословно: клиент читал `requires2FA`/`tempToken`,
    // которых бэкенд никогда не отдавал, поэтому вход с включённым TOTP
    // проваливался мимо этой ветки и падал на приведении null к String.
    switch (data['next'] as String?) {
      case '2fa':
        throw TwoFARequiredException(
          challengeToken: data['challengeToken'] as String,
          email: email,
        );
      case 'device_approval':
        throw DeviceApprovalRequiredException(
          approvalToken: data['approvalToken'] as String,
          approverCount: (data['approverCount'] as num?)?.toInt() ?? 0,
          emailAvailable: data['emailAvailable'] as bool? ?? false,
          expiresIn: (data['expiresIn'] as num?)?.toInt() ?? 600,
        );
      case null:
        break;
      default:
        // Бэкенд знает шаг, которого не знает эта версия приложения.
        // Лучше внятная ошибка, чем падение на null ниже.
        throw UnsupportedLoginStepException(data['next'] as String);
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
    required String code,
    required String challengeToken,
  }) async {
    final data = await remote.verify2FA(
      code: code,
      challengeToken: challengeToken,
    );

    // Пройденный TOTP не отменяет проверку устройства: с незнакомого
    // устройства бэкенд и здесь отправит ждать подтверждения.
    if (data['next'] == 'device_approval') {
      throw DeviceApprovalRequiredException(
        approvalToken: data['approvalToken'] as String,
        approverCount: (data['approverCount'] as num?)?.toInt() ?? 0,
        emailAvailable: data['emailAvailable'] as bool? ?? false,
        expiresIn: (data['expiresIn'] as num?)?.toInt() ?? 600,
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
    // The PIN and the biometric flag belong to the account that just left. Kept
    // across logout, the previous user's PIN would guard the next user's
    // session — and that user has no way to know or change it.
    await storage.clearPin();
    await storage.setBiometricEnabled(false);
    // Reset onboarding flag so the next user sees permission prompts
    await storage.clearOnboardingSeen();
    // Clear cached profile so the next login gets fresh data
    try {
      await sl<CacheService>().clearAll();
    } catch (_) {}
    // Revoke the device's FCM registration token so the previous user's
    // server-side mapping is fully severed. Without this, Firebase keeps the
    // same token alive — there is a window between logout and the next user's
    // /profile token-update where pushes for the prior user could still land.
    try {
      await FcmMessagingPlatform.instance.deleteToken();
    } catch (_) {}
    // End any stuck CallKit overlays. Otherwise an in-progress incoming-call
    // UI (overlay shown but unanswered) can linger across user switch and the
    // next session inherits a phantom call.
    try {
      await CallKitPlatform.instance.endAllCalls();
    } catch (_) {}
    // Clear mesh state tied to the previous user. Without this, the next
    // login on the same device inherits userId→userPk mappings (contact
    // display names, presence labels) from the prior account — observed in
    // the 2026-05-14 hardware smoke where iPhone 1 kept showing "integration
    // test" after relogin as a different user. Also wipes locally cached
    // mesh messages so chat history from the prior session doesn't bleed in.
    try {
      await sl<HiveContactKeyStore>().clear();
    } catch (_) {}
    try {
      await sl<MessengerCacheService>().clearAll();
    } catch (_) {}
    // Wipe persisted outgoing-message queue. Without this, drafts queued by
    // the previous account survive logout and are flushed to the server under
    // the new user's JWT on next ConnectMessenger — observed 2026-06-15 as
    // "phantom messages from cache, Android shown as initiator".
    try {
      await sl<PendingMessageService>().clearAll();
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

  @override
  Future<Map<String, dynamic>> sendEmailVerification() =>
      remote.sendEmailVerification();

  @override
  Future<void> confirmEmailVerification(String code) =>
      remote.confirmEmailVerification(code);
}

class TwoFARequiredException implements Exception {
  /// Имя поля совпадает с тем, что отдаёт бэкенд (`challengeToken`).
  /// Раньше здесь было `tempToken` — и расхождение с проводом никто не
  /// замечал, потому что TOTP включён у единиц.
  final String challengeToken;
  final String email;
  TwoFARequiredException({required this.challengeToken, required this.email});
}

/// Пароль верный, но устройство незнакомое: токены выдадут после подтверждения
/// с другого устройства пользователя либо по коду с почты.
class DeviceApprovalRequiredException implements Exception {
  final String approvalToken;

  /// Сколько доверенных устройств получили пуш. Ноль означает, что ждать
  /// подтверждения не от кого и надо сразу предлагать код на почту.
  final int approverCount;
  final bool emailAvailable;
  final int expiresIn;

  const DeviceApprovalRequiredException({
    required this.approvalToken,
    required this.approverCount,
    required this.emailAvailable,
    required this.expiresIn,
  });
}

class UnsupportedLoginStepException implements Exception {
  final String step;
  const UnsupportedLoginStepException(this.step);

  @override
  String toString() =>
      'This version of the app does not know the sign-in step "$step". '
      'Update the app to continue.';
}

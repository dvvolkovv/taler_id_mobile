import '../entities/auth_entities.dart';

abstract class IAuthRepository {
  Future<AuthTokens> login({required String email, required String password});
  Future<AuthTokens> register({required String email, required String password, String? firstName, String? lastName, String? username});
  Future<AuthTokens> verify2FA({required String email, required String code, required String tempToken});
  Future<AuthTokens> refreshToken(String refreshToken);
  Future<void> logout();
  Future<void> requestPasswordReset(String email);
  Future<String> verifyPasswordResetCode({required String email, required String code});
  Future<void> resetPassword({required String resetToken, required String newPassword});

  /// Returns `{sent, alreadyVerified?}`. `alreadyVerified=true` means the
  /// backend skipped sending because the address was already confirmed.
  Future<Map<String, dynamic>> sendEmailVerification();

  /// Throws on invalid/expired code.
  Future<void> confirmEmailVerification(String code);
}

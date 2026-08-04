import '../../../../core/api/dio_client.dart';

class AuthRemoteDataSource {
  final DioClient client;
  AuthRemoteDataSource(this.client);

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await client.post<Map<String, dynamic>>(
      '/auth/login',
      data: {'email': email, 'password': password},
      fromJson: (data) => Map<String, dynamic>.from(data),
    );
    return response;
  }

  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    String? firstName,
    String? lastName,
    String? username,
  }) async {
    return client.post<Map<String, dynamic>>(
      '/auth/register',
      data: {
        'email': email,
        'password': password,
        if (firstName != null) 'firstName': firstName,
        if (lastName != null) 'lastName': lastName,
        if (username != null && username.isNotEmpty) 'username': username,
      },
      fromJson: (data) => Map<String, dynamic>.from(data),
    );
  }

  Future<Map<String, dynamic>> verify2FA({
    required String code,
    required String challengeToken,
  }) async {
    return client.post<Map<String, dynamic>>(
      '/auth/login/2fa',
      // Бэкенд поднят с forbidNonWhitelisted: любое лишнее поле здесь даёт
      // 400. Раньше сюда уезжали `email` и `tempToken`, которых DTO не знает.
      data: {'challengeToken': challengeToken, 'code': code},
      fromJson: (data) => Map<String, dynamic>.from(data),
    );
  }

  // ── Подтверждение входа с нового устройства ──

  Future<Map<String, dynamic>> deviceApprovalStatus(String approvalToken) {
    return client.post<Map<String, dynamic>>(
      '/auth/login/device-approval/status',
      data: {'approvalToken': approvalToken},
      fromJson: (data) => Map<String, dynamic>.from(data),
    );
  }

  Future<void> sendDeviceApprovalEmail(String approvalToken) =>
      client.post('/auth/login/device-approval/email',
          data: {'approvalToken': approvalToken});

  Future<Map<String, dynamic>> verifyDeviceApprovalCode({
    required String approvalToken,
    required String code,
  }) {
    return client.post<Map<String, dynamic>>(
      '/auth/login/device-approval/verify',
      data: {'approvalToken': approvalToken, 'code': code},
      fromJson: (data) => Map<String, dynamic>.from(data),
    );
  }

  Future<void> approveDevice(String approvalId) =>
      client.post('/auth/devices/approvals/$approvalId/approve');

  Future<void> rejectDevice(String approvalId) =>
      client.post('/auth/devices/approvals/$approvalId/reject');

  Future<List<dynamic>> listTrustedDevices() => client.get<List<dynamic>>(
        '/auth/devices',
        fromJson: (data) => List<dynamic>.from(data as List),
      );

  Future<void> revokeTrustedDevice(String id) =>
      client.delete('/auth/devices/$id');

  Future<void> logout({String? fcmToken, String? voipToken}) => client.post('/auth/logout', data: {
    if (fcmToken != null) 'fcmToken': fcmToken,
    if (voipToken != null) 'voipToken': voipToken,
  });

  Future<void> requestPasswordReset(String email) async {
    await client.post('/auth/forgot-password', data: {'email': email});
  }

  Future<Map<String, dynamic>> verifyPasswordResetCode({
    required String email,
    required String code,
  }) async {
    return client.post<Map<String, dynamic>>(
      '/auth/forgot-password/verify',
      data: {'email': email, 'code': code},
      fromJson: (data) => Map<String, dynamic>.from(data),
    );
  }

  Future<void> resetPassword({
    required String resetToken,
    required String newPassword,
  }) async {
    await client.post('/auth/forgot-password/reset', data: {
      'resetToken': resetToken,
      'newPassword': newPassword,
    });
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await client.post('/auth/change-password', data: {
      'currentPassword': currentPassword,
      'newPassword': newPassword,
    });
  }

  /// Trigger sending a 6-digit verification code to the user's registered email.
  /// Returns `{sent: bool, alreadyVerified?: bool}` — `alreadyVerified=true` is
  /// not an error, just a no-op when the address was already confirmed.
  Future<Map<String, dynamic>> sendEmailVerification() async {
    return client.post<Map<String, dynamic>>(
      '/auth/email/verify/send',
      data: const {},
      fromJson: (data) => Map<String, dynamic>.from(data),
    );
  }

  /// Submit the 6-digit code received by email. Throws on invalid/expired code.
  Future<void> confirmEmailVerification(String code) async {
    await client.post('/auth/email/verify/confirm', data: {'code': code});
  }
}

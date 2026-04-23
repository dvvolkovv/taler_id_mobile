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
    required String email,
    required String code,
    required String tempToken,
  }) async {
    return client.post<Map<String, dynamic>>(
      '/auth/login/2fa',
      data: {'email': email, 'code': code, 'tempToken': tempToken},
      fromJson: (data) => Map<String, dynamic>.from(data),
    );
  }

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
}

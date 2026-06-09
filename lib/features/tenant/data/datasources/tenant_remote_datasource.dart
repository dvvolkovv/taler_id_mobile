import '../../../../core/api/dio_client.dart';

class TenantRemoteDataSource {
  final DioClient client;
  TenantRemoteDataSource(this.client);

  Future<List<Map<String, dynamic>>> getMyTenants() async {
    final data = await client.get<dynamic>('/tenant', fromJson: (d) => d);
    return List<Map<String, dynamic>>.from(data as List);
  }

  Future<Map<String, dynamic>> getTenant(String id) =>
      client.get('/tenant/$id', fromJson: (d) => Map<String, dynamic>.from(d));

  Future<Map<String, dynamic>> createTenant(Map<String, dynamic> data) =>
      client.post('/tenant', data: data, fromJson: (d) => Map<String, dynamic>.from(d));

  Future<Map<String, dynamic>> updateTenant(String id, Map<String, dynamic> data) =>
      client.put('/tenant/$id', data: data, fromJson: (d) => Map<String, dynamic>.from(d));

  Future<void> inviteMember({required String tenantId, required String email, required String role}) =>
      client.post('/tenant/$tenantId/members/invite', data: {'email': email, 'role': role});

  Future<void> updateMember({required String tenantId, required String memberId, required String role}) =>
      client.put('/tenant/$tenantId/members/$memberId/role', data: {'role': role});

  Future<void> acceptInvite(String token) =>
      client.post('/tenant/invites/$token/accept', data: {});

  Future<void> removeMember({required String tenantId, required String userId}) =>
      client.delete('/tenant/$tenantId/members/$userId');

  /// Returns the KYB WebSDK URL — backend issues an access token against the
  /// SumSub-compatible mock and builds the wizard URL.
  Future<String> startKyb(String tenantId) async {
    final data = await client.post<Map<String, dynamic>>(
      '/tenant/$tenantId/kyb/start',
      data: {},
      fromJson: (d) => Map<String, dynamic>.from(d),
    );
    return (data['webSdkUrl'] as String?) ?? '';
  }

  Future<Map<String, dynamic>> getKybStatus(String tenantId) =>
      client.get('/tenant/$tenantId/kyb/status', fromJson: (d) => Map<String, dynamic>.from(d));
}

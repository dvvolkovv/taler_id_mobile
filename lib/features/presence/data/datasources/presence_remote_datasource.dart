import 'package:dio/dio.dart';
import '../../domain/entities/presence_entity.dart';

class PresenceRemoteDataSource {
  final Dio _dio;
  PresenceRemoteDataSource(this._dio);

  Future<void> ping() async {
    await _dio.post('/presence/ping');
  }

  Future<PresenceEntity> getPresence(String userId) async {
    final res = await _dio.get('/presence/$userId');
    return PresenceEntity.fromJson(Map<String, dynamic>.from(res.data as Map));
  }

  Future<PresenceEntity> getMyPresence() async {
    final res = await _dio.get('/presence/me');
    return PresenceEntity.fromJson(Map<String, dynamic>.from(res.data as Map));
  }

  Future<void> updatePrivacy(String privacy) async {
    await _dio.patch('/profile', data: {'lastSeenPrivacy': privacy});
  }
}

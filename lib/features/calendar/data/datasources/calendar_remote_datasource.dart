import 'package:dio/dio.dart';
import '../../../../core/api/dio_client.dart';

class CalendarConflictException implements Exception {
  final Map<String, dynamic> currentEvent;
  CalendarConflictException(this.currentEvent);
}

class CalendarRemoteDataSource {
  final DioClient _http;
  CalendarRemoteDataSource(this._http);

  Future<List<Map<String, dynamic>>> getEvents({String? from, String? to}) async {
    final params = <String, String>{};
    if (from != null) params['from'] = from;
    if (to != null) params['to'] = to;
    final query = params.entries.map((e) => '${e.key}=${e.value}').join('&');
    final data = await _http.get<dynamic>('/calendar${query.isNotEmpty ? '?$query' : ''}');
    return (data as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<Map<String, dynamic>> create(Map<String, dynamic> data, {String? id}) async {
    final body = <String, dynamic>{
      if (id != null) 'id': id,
      ...data,
    };
    return _http.post('/calendar', data: body, fromJson: (d) => Map<String, dynamic>.from(d as Map));
  }

  Future<Map<String, dynamic>> update(
    String id,
    Map<String, dynamic> data, {
    DateTime? expectedUpdatedAt,
  }) async {
    final body = <String, dynamic>{
      ...data,
      if (expectedUpdatedAt != null)
        'expectedUpdatedAt': expectedUpdatedAt.toUtc().toIso8601String(),
    };
    try {
      return await _http.patch('/calendar/$id', data: body, fromJson: (d) => Map<String, dynamic>.from(d as Map));
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) {
        final responseBody = e.response!.data;
        final current = (responseBody is Map && responseBody['currentEvent'] is Map)
            ? Map<String, dynamic>.from(responseBody['currentEvent'] as Map)
            : <String, dynamic>{};
        throw CalendarConflictException(current);
      }
      rethrow;
    }
  }

  Future<void> delete(String id) async {
    try {
      await _http.delete('/calendar/$id');
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return; // idempotent
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getMyInvites() async {
    final data = await _http.get<dynamic>('/calendar/invites');
    return (data as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<void> acceptInvite(String inviteId) async {
    await _http.patch('/calendar/invites/$inviteId/accept', data: {}, fromJson: (d) => d);
  }

  Future<void> declineInvite(String inviteId) async {
    await _http.patch('/calendar/invites/$inviteId/decline', data: {}, fromJson: (d) => d);
  }

  Future<void> maybeInvite(String inviteId) async {
    await _http.patch('/calendar/invites/$inviteId/maybe', data: {}, fromJson: (d) => d);
  }
}

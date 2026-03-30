import '../../../../core/api/dio_client.dart';

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

  Future<Map<String, dynamic>> create(Map<String, dynamic> data) async {
    return _http.post('/calendar', data: data, fromJson: (d) => Map<String, dynamic>.from(d as Map));
  }

  Future<Map<String, dynamic>> update(String id, Map<String, dynamic> data) async {
    return _http.patch('/calendar/$id', data: data, fromJson: (d) => Map<String, dynamic>.from(d as Map));
  }

  Future<void> delete(String id) async {
    await _http.delete('/calendar/$id');
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

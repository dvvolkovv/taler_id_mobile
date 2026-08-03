import 'package:dio/dio.dart';
import '../../../../core/api/dio_client.dart';

/// REST client for the real Task entity (due/deadline/routines/per-occurrence
/// completion) — distinct from calendar events. Backed by the backend
/// `/tasks` API (TasksController). Tasks are displayed in the calendar via the
/// server-side merge into GET /calendar; this datasource is for create /
/// complete / delete from the app.
class TaskRemoteDataSource {
  final DioClient _http;
  TaskRemoteDataSource(this._http);

  /// Create a task or routine. `data` keys: title, due?, deadline?, note?,
  /// recurrence? (recurrence => routine).
  Future<Map<String, dynamic>> create(Map<String, dynamic> data) async {
    return _http.post(
      '/tasks',
      data: data,
      fromJson: (d) => Map<String, dynamic>.from(d as Map),
    );
  }

  /// Set status: 'done' | 'pending' | 'dropped'. For a routine, pass
  /// [occurrenceDate] (YYYY-MM-DD) to mark a single day without ending the
  /// series; omit it to set the whole task's status.
  Future<Map<String, dynamic>> setStatus(
    String id,
    String status, {
    String? occurrenceDate,
  }) async {
    return _http.post(
      '/tasks/$id/status',
      data: <String, dynamic>{
        'status': status,
        if (occurrenceDate != null) 'occurrenceDate': occurrenceDate,
      },
      fromJson: (d) => Map<String, dynamic>.from(d as Map),
    );
  }

  Future<void> delete(String id) async {
    try {
      await _http.delete('/tasks/$id');
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return; // idempotent
      rethrow;
    }
  }
}

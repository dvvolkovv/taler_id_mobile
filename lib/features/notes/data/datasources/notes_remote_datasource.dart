import 'package:dio/dio.dart';
import '../../../../core/api/dio_client.dart';

class NoteConflictException implements Exception {
  final Map<String, dynamic> currentNote;
  NoteConflictException(this.currentNote);
}

class NotesRemoteDataSource {
  final DioClient _http;
  NotesRemoteDataSource(this._http);

  Future<List<Map<String, dynamic>>> getAll({int limit = 50, int offset = 0}) async {
    final data = await _http.get<dynamic>('/notes?limit=$limit&offset=$offset');
    return (data as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<Map<String, dynamic>> create({
    String? id,
    required String title,
    required String content,
    String source = 'MANUAL',
  }) async {
    final body = <String, dynamic>{
      if (id != null) 'id': id,
      'title': title,
      'content': content,
      'source': source,
    };
    return _http.post('/notes', data: body, fromJson: (d) => Map<String, dynamic>.from(d as Map));
  }

  Future<Map<String, dynamic>> update(
    String id, {
    String? title,
    String? content,
    DateTime? expectedUpdatedAt,
  }) async {
    final data = <String, dynamic>{};
    if (title != null) data['title'] = title;
    if (content != null) data['content'] = content;
    if (expectedUpdatedAt != null) data['expectedUpdatedAt'] = expectedUpdatedAt.toUtc().toIso8601String();
    try {
      return await _http.patch('/notes/$id', data: data, fromJson: (d) => Map<String, dynamic>.from(d as Map));
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) {
        final body = e.response!.data;
        final current = (body is Map && body['currentNote'] is Map)
            ? Map<String, dynamic>.from(body['currentNote'] as Map)
            : <String, dynamic>{};
        throw NoteConflictException(current);
      }
      rethrow;
    }
  }

  Future<void> delete(String id) async {
    try {
      await _http.delete('/notes/$id');
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return; // idempotent
      rethrow;
    }
  }
}

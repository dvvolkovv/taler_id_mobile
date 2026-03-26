import '../../../../core/api/dio_client.dart';

class NotesRemoteDataSource {
  final DioClient _http;
  NotesRemoteDataSource(this._http);

  Future<List<Map<String, dynamic>>> getAll({int limit = 50, int offset = 0}) async {
    final data = await _http.get<dynamic>('/notes?limit=$limit&offset=$offset');
    return (data as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<Map<String, dynamic>> create({required String title, required String content, String source = 'MANUAL'}) async {
    return _http.post('/notes', data: {'title': title, 'content': content, 'source': source}, fromJson: (d) => Map<String, dynamic>.from(d as Map));
  }

  Future<Map<String, dynamic>> update(String id, {String? title, String? content}) async {
    final data = <String, dynamic>{};
    if (title != null) data['title'] = title;
    if (content != null) data['content'] = content;
    return _http.patch('/notes/$id', data: data, fromJson: (d) => Map<String, dynamic>.from(d as Map));
  }

  Future<void> delete(String id) async {
    await _http.delete('/notes/$id');
  }
}

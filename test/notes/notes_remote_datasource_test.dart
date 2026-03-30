import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:taler_id_mobile/core/api/dio_client.dart';
import 'package:taler_id_mobile/features/notes/data/datasources/notes_remote_datasource.dart';

class MockDioClient extends Mock implements DioClient {}

void main() {
  late MockDioClient http;
  late NotesRemoteDataSource ds;

  setUp(() {
    http = MockDioClient();
    ds = NotesRemoteDataSource(http);
  });

  // ── getAll ──────────────────────────────────────────────────────────────

  group('getAll', () {
    test('returns list of notes with default params', () async {
      when(() => http.get<dynamic>('/notes?limit=50&offset=0'))
          .thenAnswer((_) async => [
                {'id': '1', 'title': 'Note 1', 'content': 'Content 1'},
                {'id': '2', 'title': 'Note 2', 'content': 'Content 2'},
              ]);

      final result = await ds.getAll();

      expect(result, hasLength(2));
      expect(result[0]['title'], 'Note 1');
      expect(result[1]['id'], '2');
    });

    test('passes custom limit and offset', () async {
      when(() => http.get<dynamic>('/notes?limit=10&offset=20'))
          .thenAnswer((_) async => []);

      final result = await ds.getAll(limit: 10, offset: 20);

      expect(result, isEmpty);
      verify(() => http.get<dynamic>('/notes?limit=10&offset=20')).called(1);
    });

    test('returns empty list when no notes', () async {
      when(() => http.get<dynamic>('/notes?limit=50&offset=0'))
          .thenAnswer((_) async => []);

      final result = await ds.getAll();

      expect(result, isEmpty);
    });

    test('propagates exception on failure', () async {
      when(() => http.get<dynamic>('/notes?limit=50&offset=0'))
          .thenThrow(Exception('Server error'));

      expect(() => ds.getAll(), throwsException);
    });
  });

  // ── create ──────────────────────────────────────────────────────────────

  group('create', () {
    test('creates note with default source MANUAL', () async {
      when(() => http.post<Map<String, dynamic>>(
            '/notes',
            data: {'title': 'My Note', 'content': 'Hello', 'source': 'MANUAL'},
            fromJson: any(named: 'fromJson'),
          )).thenAnswer((_) async => {'id': '1', 'title': 'My Note', 'content': 'Hello'});

      final result = await ds.create(title: 'My Note', content: 'Hello');

      expect(result['id'], '1');
      expect(result['title'], 'My Note');
    });

    test('creates note with custom source', () async {
      when(() => http.post<Map<String, dynamic>>(
            '/notes',
            data: {'title': 'AI Note', 'content': 'Generated', 'source': 'ASSISTANT'},
            fromJson: any(named: 'fromJson'),
          )).thenAnswer((_) async => {'id': '2', 'title': 'AI Note'});

      final result = await ds.create(
        title: 'AI Note',
        content: 'Generated',
        source: 'ASSISTANT',
      );

      expect(result['id'], '2');
    });
  });

  // ── update ──────────────────────────────────────────────────────────────

  group('update', () {
    test('updates title only', () async {
      when(() => http.patch<Map<String, dynamic>>(
            '/notes/note-1',
            data: {'title': 'Updated'},
            fromJson: any(named: 'fromJson'),
          )).thenAnswer((_) async => {'id': 'note-1', 'title': 'Updated'});

      final result = await ds.update('note-1', title: 'Updated');

      expect(result['title'], 'Updated');
    });

    test('updates content only', () async {
      when(() => http.patch<Map<String, dynamic>>(
            '/notes/note-1',
            data: {'content': 'New content'},
            fromJson: any(named: 'fromJson'),
          )).thenAnswer((_) async => {'id': 'note-1', 'content': 'New content'});

      final result = await ds.update('note-1', content: 'New content');

      expect(result['content'], 'New content');
    });

    test('updates both title and content', () async {
      when(() => http.patch<Map<String, dynamic>>(
            '/notes/note-1',
            data: {'title': 'T', 'content': 'C'},
            fromJson: any(named: 'fromJson'),
          )).thenAnswer((_) async => {'id': 'note-1', 'title': 'T', 'content': 'C'});

      final result = await ds.update('note-1', title: 'T', content: 'C');

      expect(result['title'], 'T');
      expect(result['content'], 'C');
    });
  });

  // ── delete ──────────────────────────────────────────────────────────────

  group('delete', () {
    test('deletes note by id', () async {
      when(() => http.delete('/notes/note-1')).thenAnswer((_) async {});

      await ds.delete('note-1');

      verify(() => http.delete('/notes/note-1')).called(1);
    });

    test('propagates exception on failure', () async {
      when(() => http.delete('/notes/note-1')).thenThrow(Exception('Not found'));

      expect(() => ds.delete('note-1'), throwsException);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:taler_id_mobile/core/api/dio_client.dart';
import 'package:taler_id_mobile/features/calendar/data/datasources/calendar_remote_datasource.dart';

class MockDioClient extends Mock implements DioClient {}

void main() {
  late MockDioClient http;
  late CalendarRemoteDataSource ds;

  setUp(() {
    http = MockDioClient();
    ds = CalendarRemoteDataSource(http);
  });

  // ── getEvents ───────────────────────────────────────────────────────────

  group('getEvents', () {
    test('fetches events with date range', () async {
      when(() => http.get<dynamic>('/calendar?from=2026-01-01&to=2026-01-31'))
          .thenAnswer((_) async => [
                {'id': '1', 'title': 'Meeting', 'startAt': '2026-01-15T10:00:00Z'},
                {'id': '2', 'title': 'Call', 'startAt': '2026-01-20T14:00:00Z'},
              ]);

      final result = await ds.getEvents(from: '2026-01-01', to: '2026-01-31');

      expect(result, hasLength(2));
      expect(result[0]['title'], 'Meeting');
    });

    test('fetches events without params', () async {
      when(() => http.get<dynamic>('/calendar')).thenAnswer((_) async => []);

      final result = await ds.getEvents();

      expect(result, isEmpty);
    });

    test('fetches events with only from param', () async {
      when(() => http.get<dynamic>('/calendar?from=2026-03-01'))
          .thenAnswer((_) async => [
                {'id': '1', 'title': 'Event'},
              ]);

      final result = await ds.getEvents(from: '2026-03-01');

      expect(result, hasLength(1));
    });

    test('propagates exception on failure', () async {
      when(() => http.get<dynamic>('/calendar'))
          .thenThrow(Exception('Server error'));

      expect(() => ds.getEvents(), throwsException);
    });
  });

  // ── create ──────────────────────────────────────────────────────────────

  group('create', () {
    test('creates event and returns response', () async {
      final eventData = {
        'title': 'Team standup',
        'startAt': '2026-03-26T09:00:00Z',
        'endAt': '2026-03-26T09:30:00Z',
      };

      when(() => http.post<Map<String, dynamic>>(
            '/calendar',
            data: eventData,
            fromJson: any(named: 'fromJson'),
          )).thenAnswer((_) async => {'id': 'ev-1', ...eventData});

      final result = await ds.create(eventData);

      expect(result['id'], 'ev-1');
      expect(result['title'], 'Team standup');
    });
  });

  // ── update ──────────────────────────────────────────────────────────────

  group('update', () {
    test('updates event by id', () async {
      when(() => http.patch<Map<String, dynamic>>(
            '/calendar/ev-1',
            data: {'title': 'Updated standup'},
            fromJson: any(named: 'fromJson'),
          )).thenAnswer((_) async => {'id': 'ev-1', 'title': 'Updated standup'});

      final result = await ds.update('ev-1', {'title': 'Updated standup'});

      expect(result['title'], 'Updated standup');
    });
  });

  // ── delete ──────────────────────────────────────────────────────────────

  group('delete', () {
    test('deletes event by id', () async {
      when(() => http.delete('/calendar/ev-1')).thenAnswer((_) async {});

      await ds.delete('ev-1');

      verify(() => http.delete('/calendar/ev-1')).called(1);
    });
  });

  // ── getMyInvites ────────────────────────────────────────────────────────

  group('getMyInvites', () {
    test('returns list of invites', () async {
      when(() => http.get<dynamic>('/calendar/invites'))
          .thenAnswer((_) async => [
                {'id': 'inv-1', 'eventId': 'ev-1', 'status': 'pending'},
              ]);

      final result = await ds.getMyInvites();

      expect(result, hasLength(1));
      expect(result[0]['status'], 'pending');
    });

    test('returns empty list when no invites', () async {
      when(() => http.get<dynamic>('/calendar/invites'))
          .thenAnswer((_) async => []);

      final result = await ds.getMyInvites();

      expect(result, isEmpty);
    });
  });

  // ── acceptInvite ────────────────────────────────────────────────────────

  group('acceptInvite', () {
    test('accepts invite by id', () async {
      when(() => http.patch<dynamic>(
            '/calendar/invites/inv-1/accept',
            data: {},
            fromJson: any(named: 'fromJson'),
          )).thenAnswer((_) async => {});

      await ds.acceptInvite('inv-1');

      verify(() => http.patch<dynamic>(
            '/calendar/invites/inv-1/accept',
            data: {},
            fromJson: any(named: 'fromJson'),
          )).called(1);
    });
  });

  // ── declineInvite ───────────────────────────────────────────────────────

  group('declineInvite', () {
    test('declines invite by id', () async {
      when(() => http.patch<dynamic>(
            '/calendar/invites/inv-1/decline',
            data: {},
            fromJson: any(named: 'fromJson'),
          )).thenAnswer((_) async => {});

      await ds.declineInvite('inv-1');

      verify(() => http.patch<dynamic>(
            '/calendar/invites/inv-1/decline',
            data: {},
            fromJson: any(named: 'fromJson'),
          )).called(1);
    });
  });

  // ── maybeInvite ─────────────────────────────────────────────────────────

  group('maybeInvite', () {
    test('sets maybe status by invite id', () async {
      when(() => http.patch<dynamic>(
            '/calendar/invites/inv-1/maybe',
            data: {},
            fromJson: any(named: 'fromJson'),
          )).thenAnswer((_) async => {});

      await ds.maybeInvite('inv-1');

      verify(() => http.patch<dynamic>(
            '/calendar/invites/inv-1/maybe',
            data: {},
            fromJson: any(named: 'fromJson'),
          )).called(1);
    });
  });
}

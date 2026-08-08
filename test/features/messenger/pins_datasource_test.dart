import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:taler_id_mobile/core/api/dio_client.dart';
import 'package:taler_id_mobile/core/api/endpoint_service.dart';
import 'package:taler_id_mobile/features/messenger/data/datasources/messenger_remote_datasource.dart';

class MockDioClient extends Mock implements DioClient {}

void main() {
  late MockDioClient http;
  late MessengerRemoteDataSource ds;

  setUp(() {
    http = MockDioClient();
    // EndpointService() is real (not mocked): its constructor only touches a
    // plain ValueNotifier + compile-time AppConfig constants, no platform
    // channels, and MessengerRemoteDataSource only reads it in connect()/
    // _onEndpointChanged, neither of which the REST methods under test touch.
    ds = MessengerRemoteDataSource(http, EndpointService());
  });

  // ── getPinnedMessages ─────────────────────────────────────────────────

  group('getPinnedMessages', () {
    test('maps the messages array into a MessageEntity list', () async {
      when(() => http.get<Map<String, dynamic>>(
            '/messenger/conversations/conv-1/pinned',
            fromJson: any(named: 'fromJson'),
          )).thenAnswer((_) async => {
            'messages': [
              {
                'id': 'm1',
                'conversationId': 'conv-1',
                'senderId': 'u1',
                'content': 'hello',
                'sentAt': '2026-08-08T10:00:00.000Z',
                'pinnedAt': '2026-08-08T11:00:00.000Z',
                'pinnedById': 'u2',
              },
            ],
            'total': 1,
          });

      final result = await ds.getPinnedMessages('conv-1');

      expect(result, hasLength(1));
      expect(result.single.id, 'm1');
      expect(result.single.content, 'hello');
      expect(result.single.pinnedAt, DateTime.parse('2026-08-08T11:00:00.000Z'));
      expect(result.single.pinnedById, 'u2');
    });

    test('tolerates a response with no messages key, returning an empty list', () async {
      when(() => http.get<Map<String, dynamic>>(
            '/messenger/conversations/conv-1/pinned',
            fromJson: any(named: 'fromJson'),
          )).thenAnswer((_) async => {'total': 0});

      final result = await ds.getPinnedMessages('conv-1');

      expect(result, isEmpty);
    });
  });

  // ── dismissPins ───────────────────────────────────────────────────────

  group('dismissPins', () {
    test('sends upTo as a UTC ISO-8601 string when given', () async {
      when(() => http.post<Map<String, dynamic>>(
            '/messenger/conversations/conv-1/pinned/dismiss',
            data: any(named: 'data'),
            fromJson: any(named: 'fromJson'),
          )).thenAnswer((_) async => {'pinsDismissedAt': '2026-08-08T12:00:00.000Z'});

      // A LOCAL DateTime on purpose. An offset string such as
      // '2026-08-08T14:30:00+02:00' would be useless here: DateTime.parse
      // already normalizes it to isUtc == true, so .toUtc() would be a no-op
      // and deleting it from the datasource would not fail this test.
      // A local DateTime is the only input that actually discriminates.
      final upTo = DateTime(2026, 8, 8, 14, 30);
      expect(upTo.isUtc, isFalse, reason: 'fixture must be local to be meaningful');
      await ds.dismissPins('conv-1', upTo: upTo);

      final captured = verify(() => http.post<Map<String, dynamic>>(
            '/messenger/conversations/conv-1/pinned/dismiss',
            data: captureAny(named: 'data'),
            fromJson: any(named: 'fromJson'),
          )).captured;

      final sentData = captured.single as Map<String, dynamic>;
      expect(sentData['upTo'], upTo.toUtc().toIso8601String());
      expect(sentData['upTo'], endsWith('Z'));
    });

    test('omits the upTo key entirely when not given', () async {
      when(() => http.post<Map<String, dynamic>>(
            '/messenger/conversations/conv-1/pinned/dismiss',
            data: any(named: 'data'),
            fromJson: any(named: 'fromJson'),
          )).thenAnswer((_) async => {'pinsDismissedAt': null});

      await ds.dismissPins('conv-1');

      final captured = verify(() => http.post<Map<String, dynamic>>(
            '/messenger/conversations/conv-1/pinned/dismiss',
            data: captureAny(named: 'data'),
            fromJson: any(named: 'fromJson'),
          )).captured;

      final sentData = captured.single as Map<String, dynamic>;
      expect(sentData.containsKey('upTo'), isFalse);
    });
  });

  // ── unpin paths ───────────────────────────────────────────────────────
  // These go through deleteWithResponse rather than delete: plain delete
  // returns Future<void> and would silently swallow the response body the
  // caller needs (wasPinned / pinnedCount / unpinned).

  group('unpin', () {
    test('unpinMessage returns the response body', () async {
      when(() => http.deleteWithResponse<Map<String, dynamic>>(
            '/messenger/conversations/conv-1/messages/m1/pin',
            fromJson: any(named: 'fromJson'),
          )).thenAnswer((_) async => {'pinnedCount': 2, 'wasPinned': true});

      final res = await ds.unpinMessage('conv-1', 'm1');

      expect(res['wasPinned'], isTrue);
      expect(res['pinnedCount'], 2);
    });

    test('unpinAll returns the number of pins removed', () async {
      when(() => http.deleteWithResponse<Map<String, dynamic>>(
            '/messenger/conversations/conv-1/pinned',
            fromJson: any(named: 'fromJson'),
          )).thenAnswer((_) async => {'unpinned': 3});

      final res = await ds.unpinAll('conv-1');

      expect(res['unpinned'], 3);
    });
  });
}

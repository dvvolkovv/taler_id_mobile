import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:taler_id_mobile/core/services/outbox_replay_handler.dart';
import 'package:taler_id_mobile/core/storage/outbox_op.dart';
import 'package:taler_id_mobile/features/contacts/data/services/contacts_outbox_replay_handler.dart';
import 'package:taler_id_mobile/features/messenger/data/datasources/messenger_remote_datasource.dart';

class _MockRemote extends Mock implements MessengerRemoteDataSource {}

OutboxOp _op(String action) => OutboxOp(
      opId: 'op-1',
      feature: 'contacts',
      op: OutboxOpKind.update,
      entityId: 'req-1',
      payload: {'action': action},
      createdAt: DateTime.now(),
    );

void main() {
  late _MockRemote remote;
  late ContactsOutboxReplayHandler handler;

  setUp(() {
    remote = _MockRemote();
    handler = ContactsOutboxReplayHandler(remote: remote);
  });

  test('accept success → OutboxReplaySuccess', () async {
    when(() => remote.acceptContactRequest('req-1'))
        .thenAnswer((_) async => {'ok': true});
    final res = await handler.replay(_op('accept'));
    expect(res, isA<OutboxReplaySuccess>());
  });

  test('reject success → OutboxReplaySuccess', () async {
    when(() => remote.rejectContactRequest('req-1'))
        .thenAnswer((_) async {});
    final res = await handler.replay(_op('reject'));
    expect(res, isA<OutboxReplaySuccess>());
  });

  test('404 from accept → success (already settled)', () async {
    when(() => remote.acceptContactRequest('req-1'))
        .thenThrow(DioException(
          requestOptions: RequestOptions(path: '/x'),
          response: Response(requestOptions: RequestOptions(path: '/x'), statusCode: 404),
        ));
    final res = await handler.replay(_op('accept'));
    expect(res, isA<OutboxReplaySuccess>());
  });

  test('network error → retry', () async {
    when(() => remote.acceptContactRequest('req-1'))
        .thenThrow(Exception('network'));
    final res = await handler.replay(_op('accept'));
    expect(res, isA<OutboxReplayRetry>());
  });
}

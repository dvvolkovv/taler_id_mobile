import 'package:dio/dio.dart';
import '../../../../core/services/outbox_replay_handler.dart';
import '../../../../core/storage/outbox_op.dart';
import '../datasources/calendar_remote_datasource.dart';

class CalendarOutboxReplayHandler implements OutboxReplayHandler {
  final CalendarRemoteDataSource _remote;
  CalendarOutboxReplayHandler({required CalendarRemoteDataSource remote}) : _remote = remote;

  @override
  String get feature => 'calendar';

  @override
  Future<OutboxReplayResult> replay(OutboxOp op) async {
    try {
      switch (op.op) {
        case OutboxOpKind.create:
          final serverEntity = await _remote.create(op.payload ?? const {}, id: op.entityId);
          return OutboxReplayResult.success(serverEntity: serverEntity);
        case OutboxOpKind.update:
          final serverEntity = await _remote.update(
            op.entityId,
            op.payload ?? const {},
            expectedUpdatedAt: op.expectedUpdatedAt,
          );
          return OutboxReplayResult.success(serverEntity: serverEntity);
        case OutboxOpKind.delete:
          await _remote.delete(op.entityId);
          return OutboxReplayResult.success();
      }
    } on CalendarConflictException catch (e) {
      return OutboxReplayResult.conflict(serverData: e.currentEvent);
    } on DioException catch (e) {
      final code = e.response?.statusCode ?? 0;
      if (code >= 400 && code < 500 && code != 408 && code != 429) {
        return OutboxReplayResult.dead(error: 'HTTP $code: ${e.message}');
      }
      return OutboxReplayResult.retry(error: 'HTTP $code: ${e.message}');
    } catch (e) {
      return OutboxReplayResult.retry(error: e.toString());
    }
  }
}

import 'package:dio/dio.dart';
import '../../../../core/api/api_exception.dart';
import '../../../../core/services/outbox_replay_handler.dart';
import '../../../../core/storage/outbox_op.dart';
import '../datasources/task_remote_datasource.dart';

/// Durable replay of real-Task mutations (feature `task`). Task create/status/
/// delete used to be direct, fire-and-forget HTTP from the UI — a lost or
/// offline delete silently never reached the server, leaving a task the app
/// had hidden locally but that Linkeon (reading the same backend via MCP) still
/// saw as pending. Routing them through the outbox retries until the server
/// confirms. Error mapping mirrors [CalendarOutboxReplayHandler].
class TaskOutboxReplayHandler implements OutboxReplayHandler {
  final TaskRemoteDataSource _remote;
  TaskOutboxReplayHandler({required TaskRemoteDataSource remote}) : _remote = remote;

  @override
  String get feature => 'task';

  @override
  Future<OutboxReplayResult> replay(OutboxOp op) async {
    try {
      switch (op.op) {
        case OutboxOpKind.create:
          final serverEntity =
              await _remote.create(op.payload ?? const {}, id: op.entityId);
          return OutboxReplayResult.success(serverEntity: serverEntity);
        case OutboxOpKind.update:
          // update carries a status change: payload {status, occurrenceDate?}
          final payload = op.payload ?? const {};
          final serverEntity = await _remote.setStatus(
            op.entityId,
            (payload['status'] as String?) ?? 'done',
            occurrenceDate: payload['occurrenceDate'] as String?,
          );
          return OutboxReplayResult.success(serverEntity: serverEntity);
        case OutboxOpKind.delete:
          await _remote.delete(op.entityId);
          return OutboxReplayResult.success();
      }
    } on ApiException catch (e) {
      // The HTTP wrapper (_http) throws ApiException, NOT DioException — map by
      // code explicitly, else every API error would fall through to a generic
      // retry and a delete of an already-gone task (404) would retry forever,
      // poisoning the queue (the calendar bug fixed 2026-09-19).
      final code = e.statusCode ?? 0;
      // Idempotency: deleting an already-absent task is success, not a poison retry.
      if (op.op == OutboxOpKind.delete && code == 404) {
        return OutboxReplayResult.success();
      }
      // A status change on a task the server no longer has is also terminally done.
      if (op.op == OutboxOpKind.update && code == 404) {
        return OutboxReplayResult.success();
      }
      // Permanent client errors (except 401 expired-token / 408 / 429) — terminal.
      if (code >= 400 && code < 500 && code != 401 && code != 408 && code != 429) {
        return OutboxReplayResult.dead(error: 'HTTP $code: ${e.message}');
      }
      // 401 (token refresh), 408/429, 5xx, network — transient, retry.
      return OutboxReplayResult.retry(error: 'HTTP $code: ${e.message}');
    } on DioException catch (e) {
      final code = e.response?.statusCode ?? 0;
      if ((op.op == OutboxOpKind.delete || op.op == OutboxOpKind.update) && code == 404) {
        return OutboxReplayResult.success();
      }
      if (code >= 400 && code < 500 && code != 401 && code != 408 && code != 429) {
        return OutboxReplayResult.dead(error: 'HTTP $code: ${e.message}');
      }
      return OutboxReplayResult.retry(error: 'HTTP $code: ${e.message}');
    } catch (e) {
      return OutboxReplayResult.retry(error: e.toString());
    }
  }
}

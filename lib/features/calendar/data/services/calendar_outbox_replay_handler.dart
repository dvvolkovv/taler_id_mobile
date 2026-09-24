import 'package:dio/dio.dart';
import '../../../../core/api/api_exception.dart';
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
    } on ApiException catch (e) {
      // ВАЖНО: HTTP-обёртка (_http) бросает ApiException, НЕ DioException — поэтому раньше все
      // API-ошибки падали в общий catch → retry, и delete уже удалённого события (404) ретраился
      // ВЕЧНО, отравляя и замораживая outbox (bug 2026-09-19). Маппим по коду явно:
      final code = e.statusCode ?? 0;
      // Идемпотентность: удаление уже отсутствующего события — это успех, а не отравленный ретрай.
      if (op.op == OutboxOpKind.delete && code == 404) {
        return OutboxReplayResult.success();
      }
      // Перманентные клиентские ошибки (кроме 401-протух-токен / 408 / 429) — терминально, без ретрая.
      if (code >= 400 && code < 500 && code != 401 && code != 408 && code != 429) {
        return OutboxReplayResult.dead(error: 'HTTP $code: ${e.message}');
      }
      // 401 (обновится токен), 408/429, 5xx, сеть — временно, ретраим.
      return OutboxReplayResult.retry(error: 'HTTP $code: ${e.message}');
    } on DioException catch (e) {
      final code = e.response?.statusCode ?? 0;
      if (op.op == OutboxOpKind.delete && code == 404) {
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

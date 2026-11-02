import 'dart:async';
import 'package:flutter/foundation.dart';
import '../storage/outbox_op.dart';
import '../storage/outbox_queue.dart';
import 'outbox_replay_handler.dart';

class OutboxReplayService {
  static const int maxAttempts = 10;
  /// Верхняя граница на один replay. Страхует от зависшего HTTP без ответа, который иначе
  /// навсегда держит _draining=true и морозит всю очередь (см. _processOp).
  static const Duration replayTimeout = Duration(seconds: 30);

  /// Возраст, после которого «отправляется» считается залипшим и возвращается в строй
  /// (см. [OutboxQueue.reviveStaleInflight]). Заведомо больше [replayTimeout], чтобы
  /// watchdog не отбирал операцию у живой отправки.
  static const Duration staleInflightAge = Duration(minutes: 5);

  /// Как часто очередь пытается уехать сама, без действий пользователя. До 02.11.2026
  /// прогон запускали только события — старт приложения, открытие экрана, возврат связи;
  /// если прогон залипал, очередь стояла до перезапуска приложения (стояла 5 суток).
  static const Duration defaultDrainInterval = Duration(minutes: 5);

  final OutboxQueue _queue;
  final Map<String, OutboxReplayHandler> _handlers = {};
  bool _draining = false;
  DateTime? _drainStartedAt;
  /// Номер текущего прогона: повисший предшественник, если он однажды всё-таки
  /// завершится, не должен сбросить флаг уже идущего преемника.
  int _drainSeq = 0;
  Timer? _ticker;

  /// Срок, после которого прогон считается повисшим и перестаёт запирать очередь.
  /// Одного флага single-flight мало: прогон, который не дошёл до конца (02.11.2026 —
  /// запрос ушёл на сервер, применился там, а ответ в код не вернулся), запирал
  /// очередь до перезапуска приложения, и ни сторож, ни таймер внутрь не попадали.
  final Duration maxDrainDuration;

  OutboxReplayService({
    OutboxQueue? queue,
    this.maxDrainDuration = const Duration(minutes: 2),
  }) : _queue = queue ?? OutboxQueue();

  void registerHandler(OutboxReplayHandler handler) {
    _handlers[handler.feature] = handler;
  }

  /// Persists [op] and triggers a drain so the op is replayed immediately
  /// when the device is online. Without this, the op would sit in the queue
  /// until the next connectivity-up event or app cold start.
  Future<void> enqueue(OutboxOp op) async {
    await _queue.enqueue(op);
    // Fire-and-forget; errors are handled inside drain → handler chain.
    unawaited(drain());
  }

  /// Drains all currently-pending ops (single-flight).
  /// Each op is processed at most once per drain call — retried ops are
  /// left for the next drain triggered by the next connectivity event.
  Future<void> drain() async {
    // Операции, помеченные повисшим предшественником, бесхозны по определению:
    // прогон, который их взял, уже признан мёртвым, ждать его ответа нечего.
    var staleAge = staleInflightAge;
    if (_draining) {
      final since = _drainStartedAt;
      if (since == null || DateTime.now().difference(since) < maxDrainDuration) return;
      debugPrint('[outbox] предыдущий прогон висит '
          '${DateTime.now().difference(since).inSeconds}с — начинаем новый');
      staleAge = maxDrainDuration;
    }
    _draining = true;
    _drainStartedAt = DateTime.now();
    final token = ++_drainSeq;
    try {
      // Сперва вернуть в строй залипшие «отправляется»: без этого одна операция,
      // на которой прогон когда-то бросил, морозит очередь до перезапуска приложения.
      try {
        final revived = await _queue.reviveStaleInflight(staleAge);
        if (revived > 0) debugPrint('[outbox] revived $revived stale inflight op(s)');
      } catch (e) {
        debugPrint('[outbox] revive failed: $e');
      }
      // Snapshot the pending ops upfront so retried ops (reset back to
      // pending during this drain) are not re-processed in this same pass.
      final snapshot = await _queue.pending();
      for (final op in snapshot) {
        if (op.status != OutboxOpStatus.pending) continue;
        // Падение на одной операции (в т.ч. при ЗАПИСИ результата) не должно уносить
        // весь прогон: раньше исключение улетало из drain молча, а операция оставалась
        // inflight навсегда. Логируем и возвращаем её в «ждёт», очередь едет дальше.
        try {
          debugPrint('[outbox] → ${op.feature}/${op.op.name} ${op.opId}');
          await _processOp(op);
          debugPrint('[outbox] ← ${op.opId} обработана');
        } catch (e, st) {
          debugPrint('[outbox] processing ${op.opId} failed: $e\n$st');
          try {
            await _queue.markPending(
              op.opId,
              lastError: e.toString(),
              attempts: op.attempts + 1,
            );
          } catch (e2) {
            debugPrint('[outbox] could not reset ${op.opId}: $e2');
          }
        }
      }
    } finally {
      if (_drainSeq == token) {
        _draining = false;
        _drainStartedAt = null;
      }
    }
  }

  /// Запускает фоновый прогон очереди по таймеру. Это страховка на случай, когда
  /// событийных триггеров не случается (приложение открыто сутками, экран календаря
  /// не трогают) или когда прогон однажды упал.
  void startPeriodicDrain({Duration interval = defaultDrainInterval}) {
    _ticker?.cancel();
    _ticker = Timer.periodic(interval, (_) => unawaited(drain()));
  }

  void stopPeriodicDrain() {
    _ticker?.cancel();
    _ticker = null;
  }

  Future<void> _processOp(OutboxOp op) async {
    if (op.attempts >= maxAttempts - 1) {
      await _queue.markDead(op.opId, 'max attempts reached');
      return;
    }

    final handler = _handlers[op.feature];
    if (handler == null) {
      await _queue.markDead(op.opId, 'no handler for ${op.feature}');
      return;
    }

    await _queue.markInflight(op.opId);
    final OutboxReplayResult result;
    try {
      // Таймаут ОБЯЗАТЕЛЕН: без него зависший HTTP-replay (нет ответа) навсегда оставляет
      // _draining=true → весь outbox замерзает (bug 2026-09-19: очередь стояла с 15.09). При
      // таймауте — TimeoutException попадает в catch ниже → markPending(retry), очередь живёт.
      result = await handler.replay(op).timeout(replayTimeout);
    } catch (e, st) {
      debugPrint('[outbox] handler threw for ${op.opId}: $e\n$st');
      await _queue.markPending(
        op.opId,
        lastError: e.toString(),
        attempts: op.attempts + 1,
      );
      return;
    }

    switch (result) {
      case OutboxReplaySuccess():
        await _queue.remove(op.opId);
      case OutboxReplayRetry(:final error):
        await _queue.markPending(
          op.opId,
          lastError: error,
          attempts: op.attempts + 1,
        );
      case OutboxReplayConflict(:final serverData):
        await _queue.markConflict(op.opId, serverData);
      case OutboxReplayDead(:final error):
        await _queue.markDead(op.opId, error);
    }
  }
}

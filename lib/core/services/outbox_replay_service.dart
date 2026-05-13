import 'dart:async';
import 'package:flutter/foundation.dart';
import '../storage/outbox_op.dart';
import '../storage/outbox_queue.dart';
import 'outbox_replay_handler.dart';

class OutboxReplayService {
  static const int maxAttempts = 10;

  final OutboxQueue _queue;
  final Map<String, OutboxReplayHandler> _handlers = {};
  bool _draining = false;

  OutboxReplayService({OutboxQueue? queue}) : _queue = queue ?? OutboxQueue();

  void registerHandler(OutboxReplayHandler handler) {
    _handlers[handler.feature] = handler;
  }

  /// Drains all currently-pending ops (single-flight).
  /// Each op is processed at most once per drain call — retried ops are
  /// left for the next drain triggered by the next connectivity event.
  Future<void> drain() async {
    if (_draining) return;
    _draining = true;
    try {
      // Snapshot the pending ops upfront so retried ops (reset back to
      // pending during this drain) are not re-processed in this same pass.
      final snapshot = await _queue.pending();
      for (final op in snapshot) {
        if (op.status != OutboxOpStatus.pending) continue;
        await _processOp(op);
      }
    } finally {
      _draining = false;
    }
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
      result = await handler.replay(op);
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

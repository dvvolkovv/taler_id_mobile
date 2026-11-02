import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'outbox_op.dart';

class OutboxQueue {
  static const String boxName = 'outbox_v1';

  Box<String> get _box => Hive.box<String>(boxName);

  Future<void> enqueue(OutboxOp op) async {
    await _box.put(op.opId, jsonEncode(op.toJson()));
  }

  Future<List<OutboxOp>> pending() async {
    final ops = _box.keys
        .cast<String>()
        .map((k) => _decode(_box.get(k)!))
        .whereType<OutboxOp>()
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return ops;
  }

  Future<OutboxOp?> nextPending() async {
    final all = await pending();
    for (final op in all) {
      if (op.status == OutboxOpStatus.pending) return op;
    }
    return null;
  }

  Future<void> markInflight(String opId) async {
    await _mutate(
      opId,
      (op) => op.copyWith(
        status: OutboxOpStatus.inflight,
        lastAttemptAt: DateTime.now(),
      ),
    );
  }

  Future<void> markPending(
    String opId, {
    String? lastError,
    int? attempts,
  }) async {
    await _mutate(
      opId,
      (op) => op.copyWith(
        status: OutboxOpStatus.pending,
        lastError: lastError ?? op.lastError,
        attempts: attempts ?? op.attempts,
      ),
    );
  }

  Future<void> markConflict(
    String opId,
    Map<String, dynamic> serverData,
  ) async {
    await _mutate(
      opId,
      (op) => op.copyWith(
        status: OutboxOpStatus.failedConflict,
        serverData: serverData,
      ),
    );
  }

  Future<void> markDead(String opId, String error) async {
    await _mutate(
      opId,
      (op) => op.copyWith(
        status: OutboxOpStatus.failedDead,
        lastError: error,
      ),
    );
  }

  Future<void> remove(String opId) async {
    await _box.delete(opId);
  }

  Stream<List<OutboxOp>> watch() async* {
    yield await pending();
    await for (final _ in _box.watch()) {
      yield await pending();
    }
  }

  /// Переводит «отправляется» старше [maxAge] обратно в «ждёт», считая попытку.
  ///
  /// Операция остаётся inflight только если прогон бросил между пометкой и записью
  /// результата (или процесс умер в этот момент). До 02.11.2026 воскрешал её ТОЛЬКО
  /// [onBoot], то есть холодный старт приложения: одна зависшая операция морозила
  /// очередь на дни — правки владельца жили в локальном кэше, а сервер их не видел.
  /// Попытка инкрементится намеренно: операция, зависающая всегда, иначе воскресала
  /// бы вечно, а так доходит до предела попыток и честно умирает.
  /// [maxAge] обязан быть больше таймаута одного replay, иначе watchdog уведёт
  /// операцию из-под живой отправки и та уедет на сервер дважды.
  Future<int> reviveStaleInflight(Duration maxAge, {DateTime? now}) async {
    final cutoff = (now ?? DateTime.now()).subtract(maxAge);
    var revived = 0;
    for (final k in _box.keys.cast<String>().toList()) {
      final raw = _box.get(k);
      if (raw == null) continue;
      final op = _decode(raw);
      if (op == null || op.status != OutboxOpStatus.inflight) continue;
      // Нет отметки о попытке — операция старая/битая, её тоже надо вернуть в строй.
      final at = op.lastAttemptAt;
      if (at != null && at.isAfter(cutoff)) continue;
      await _box.put(
        k,
        jsonEncode(op
            .copyWith(
              status: OutboxOpStatus.pending,
              attempts: op.attempts + 1,
              lastError: 'stale inflight revived',
            )
            .toJson()),
      );
      revived++;
    }
    return revived;
  }

  /// ТОЛЬКО ДЛЯ ТЕСТОВ: состарить отметку последней попытки, чтобы проверить watchdog
  /// без ожидания реального времени.
  @visibleForTesting
  Future<void> backdateAttempt(String opId, DateTime at) async {
    await _mutate(opId, (op) => op.copyWith(lastAttemptAt: at));
  }

  Future<void> onBoot() async {
    for (final k in _box.keys.cast<String>().toList()) {
      final raw = _box.get(k);
      if (raw == null) continue;
      final op = _decode(raw);
      if (op == null) continue;
      if (op.status == OutboxOpStatus.inflight) {
        await _box.put(
          k,
          jsonEncode(op.copyWith(status: OutboxOpStatus.pending).toJson()),
        );
      }
    }
  }

  Future<void> _mutate(String opId, OutboxOp Function(OutboxOp) f) async {
    final raw = _box.get(opId);
    if (raw == null) return;
    final op = _decode(raw);
    if (op == null) return;
    await _box.put(opId, jsonEncode(f(op).toJson()));
  }

  OutboxOp? _decode(String raw) {
    try {
      return OutboxOp.fromJson(
        Map<String, dynamic>.from(jsonDecode(raw) as Map),
      );
    } catch (_) {
      return null;
    }
  }
}

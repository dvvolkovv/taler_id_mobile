import 'dart:async';
import 'dart:convert';
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

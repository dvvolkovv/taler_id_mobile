import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:hive/hive.dart';

import 'mesh_call_history_entry.dart';

abstract class MeshCallHistoryRepository {
  Future<void> add(MeshCallHistoryEntry entry);
  Future<List<MeshCallHistoryEntry>> getAll();
  Future<void> deleteById(int callId);
  Stream<List<MeshCallHistoryEntry>> watch();
}

class HiveMeshCallHistoryRepository implements MeshCallHistoryRepository {
  static const _boxName = 'mesh_call_history';
  Box<String>? _box;

  // Broadcast controller for ongoing mutations after initial subscription.
  final _ctrl = StreamController<List<MeshCallHistoryEntry>>.broadcast();

  // Latest known snapshot — used to replay to new subscribers immediately.
  List<MeshCallHistoryEntry> _latest = const [];

  bool _disposed = false;

  Future<void> init() async {
    try {
      _box = await Hive.openBox<String>(_boxName);
    } catch (e) {
      debugPrint('[mesh-call-history] open failed: $e — recreating');
      await Hive.deleteBoxFromDisk(_boxName);
      _box = await Hive.openBox<String>(_boxName);
    }
    _latest = await getAll();
    // No broadcast emit on init — subscribers haven't attached yet and
    // watch() replays _latest synchronously on each new subscription.
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    await _ctrl.close();
    await _box?.close();
    _box = null;
  }

  @override
  Future<void> add(MeshCallHistoryEntry entry) async {
    final box = _box;
    if (box == null) return;
    await box.put(entry.callId.toString(), jsonEncode(entry.toJson()));
    await _refreshAndEmit();
  }

  @override
  Future<List<MeshCallHistoryEntry>> getAll() async {
    final box = _box;
    if (box == null) return const [];
    final list = <MeshCallHistoryEntry>[];
    for (final raw in box.values) {
      try {
        list.add(MeshCallHistoryEntry.fromJson(
            jsonDecode(raw) as Map<String, dynamic>));
      } catch (e) {
        debugPrint('[mesh-call-history] skipping malformed entry: $e');
      }
    }
    list.sort((a, b) => b.startedAt.compareTo(a.startedAt));
    return list;
  }

  @override
  Future<void> deleteById(int callId) async {
    final box = _box;
    if (box == null) return;
    await box.delete(callId.toString());
    await _refreshAndEmit();
  }

  /// Returns a stream that immediately emits the current snapshot (via
  /// [Future.microtask]) and then forwards every subsequent mutation.
  @override
  Stream<List<MeshCallHistoryEntry>> watch() {
    late StreamController<List<MeshCallHistoryEntry>> sc;
    StreamSubscription<List<MeshCallHistoryEntry>>? upstream;

    sc = StreamController<List<MeshCallHistoryEntry>>(
      onListen: () {
        // Emit the current snapshot asynchronously so callers can attach
        // their listener before the first event arrives (matches test's
        // `await Future<void>.delayed(Duration.zero)` pattern).
        final snapshot = _latest;
        Future<void>.microtask(() {
          if (!sc.isClosed) sc.add(snapshot);
        });
        upstream = _ctrl.stream.listen(
          (v) { if (!sc.isClosed) sc.add(v); },
          onError: (Object e, StackTrace s) { if (!sc.isClosed) sc.addError(e, s); },
          onDone: () { if (!sc.isClosed) sc.close(); },
        );
      },
      onCancel: () async {
        await upstream?.cancel();
        upstream = null;
        if (!sc.isClosed) await sc.close();
      },
    );

    return sc.stream;
  }

  Future<void> _refreshAndEmit() async {
    if (_disposed) return;
    _latest = await getAll();
    if (!_ctrl.isClosed) _ctrl.add(_latest);
  }
}

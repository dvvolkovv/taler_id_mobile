import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:taler_id_mobile/features/call_history/data/mesh_call_history_entry.dart';
import 'package:taler_id_mobile/features/call_history/data/mesh_call_history_repository.dart';

MeshCallHistoryEntry _entry({required int id, DateTime? startedAt}) =>
    MeshCallHistoryEntry(
      callId: id,
      peerDevicePkBase64: 'pk-$id',
      peerUserId: null,
      peerName: 'Peer $id',
      isOutgoing: id.isEven,
      startedAt: startedAt ?? DateTime.utc(2026, 4, 29, 10, id),
      activatedAt: null,
      endedAt: (startedAt ?? DateTime.utc(2026, 4, 29, 10, id))
          .add(const Duration(seconds: 5)),
      durationSec: null,
      endReason: 'userHangup',
      transport: 'bonjour',
    );

void main() {
  late Directory tempDir;
  late HiveMeshCallHistoryRepository repo;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('mesh_call_history_test_');
    Hive.init(tempDir.path);
    repo = HiveMeshCallHistoryRepository();
    await repo.init();
  });

  tearDown(() async {
    await repo.dispose();
    await Hive.deleteBoxFromDisk('mesh_call_history');
    await tempDir.delete(recursive: true);
  });

  group('HiveMeshCallHistoryRepository', () {
    test('add then getAll returns the entry', () async {
      final e = _entry(id: 1);
      await repo.add(e);
      expect(await repo.getAll(), [e]);
    });

    test('getAll returns entries sorted by startedAt desc', () async {
      final older = _entry(id: 1, startedAt: DateTime.utc(2026, 4, 29, 9, 0));
      final newer = _entry(id: 2, startedAt: DateTime.utc(2026, 4, 29, 11, 0));
      await repo.add(older);
      await repo.add(newer);
      final list = await repo.getAll();
      expect(list.first.callId, 2);
      expect(list.last.callId, 1);
    });

    test('deleteById removes the entry', () async {
      await repo.add(_entry(id: 1));
      await repo.add(_entry(id: 2));
      await repo.deleteById(1);
      final remaining = await repo.getAll();
      expect(remaining.map((e) => e.callId), [2]);
    });

    test('watch emits the current snapshot on subscribe and after each mutation',
        () async {
      final emissions = <List<int>>[];
      final sub = repo.watch().listen((list) {
        emissions.add(list.map((e) => e.callId).toList());
      });
      await Future<void>.delayed(Duration.zero); // initial emit
      await repo.add(_entry(id: 1));
      await Future<void>.delayed(Duration.zero);
      await repo.add(_entry(id: 2));
      await Future<void>.delayed(Duration.zero);
      await repo.deleteById(1);
      await Future<void>.delayed(Duration.zero);
      await sub.cancel();
      expect(emissions, [
        <int>[],
        [1],
        [2, 1],
        [2],
      ]);
    });

    test('survives reopen — entries persisted to disk', () async {
      await repo.add(_entry(id: 7));
      await repo.dispose();
      final repo2 = HiveMeshCallHistoryRepository();
      await repo2.init();
      try {
        final list = await repo2.getAll();
        expect(list.single.callId, 7);
      } finally {
        await repo2.dispose();
      }
    });
  });
}

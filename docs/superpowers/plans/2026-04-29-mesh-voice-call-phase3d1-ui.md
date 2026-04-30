# Mesh Voice Call Phase 3d.1 — UI Integration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make a mesh voice call work end-to-end through the app UI: place from `MeshDebugScreen`, see incoming modal sheet, see active call screen with timer / mute / hangup, get a history entry on call end.

**Architecture:** A singleton `MeshVoiceUiCoordinator` subscribes to `MeshVoiceService.stateStream` (Phase 3c, already shipped) and drives all UI control flow via `globalNavigatorKey`. Two new screens (`MeshVoiceCallScreen`, `MeshIncomingCallSheet`) are stateless w.r.t. the call state machine. Local Hive box `mesh_call_history` stores per-call entries (JSON, no type adapter — matches existing `messenger_cache_service` pattern).

**Tech Stack:** Flutter 3.38, Dart 3.6, `hive_flutter`, `get_it`, `flutter_bloc`, existing mesh stack (Phases 1–3c).

**Spec:** [docs/superpowers/specs/2026-04-29-mesh-voice-call-phase3d1-design.md](../specs/2026-04-29-mesh-voice-call-phase3d1-design.md)

---

## Pre-flight

### Task 0: Branch + verify clean baseline

**Files:**
- Modify: working tree (no file changes)

- [ ] **Step 1: Create feature branch from `dev`**

```bash
cd ~/Downloads/taler_id_mobile
git fetch origin
git checkout -b feature/mesh-voice-call-phase3d.1 origin/dev
```

Expected: `Switched to a new branch 'feature/mesh-voice-call-phase3d.1'`.

- [ ] **Step 2: Confirm tests pass on baseline**

Run: `flutter test`
Expected: `486` (or current `dev`) tests pass; no failures.

- [ ] **Step 3: Confirm flutter analyze clean**

Run: `flutter analyze`
Expected: `No issues found!` (warnings about deprecated APIs are pre-existing and OK).

---

## Storage layer

### Task 1: `MeshCallHistoryEntry` model

**Files:**
- Create: `lib/features/call_history/data/mesh_call_history_entry.dart`
- Test: `test/features/call_history/data/mesh_call_history_entry_test.dart`

The model is plain Dart (no Freezed) — kept tiny, JSON-serializable for Hive String storage.

- [ ] **Step 1: Write the failing test**

Create `test/features/call_history/data/mesh_call_history_entry_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:taler_id_mobile/features/call_history/data/mesh_call_history_entry.dart';

void main() {
  group('MeshCallHistoryEntry', () {
    test('round-trips through toJson/fromJson with all fields populated', () {
      final entry = MeshCallHistoryEntry(
        callId: 0xCAFEBABE,
        peerDevicePkBase64: 'AQIDBA==',
        peerUserId: 'user-123',
        peerName: 'Alice',
        isOutgoing: true,
        startedAt: DateTime.utc(2026, 4, 29, 10, 15, 30),
        activatedAt: DateTime.utc(2026, 4, 29, 10, 15, 32),
        endedAt: DateTime.utc(2026, 4, 29, 10, 16, 5),
        durationSec: 33,
        endReason: 'userHangup',
        transport: 'bonjour',
      );
      final round = MeshCallHistoryEntry.fromJson(entry.toJson());
      expect(round, entry);
    });

    test('round-trips with nullable fields null', () {
      final entry = MeshCallHistoryEntry(
        callId: 1,
        peerDevicePkBase64: 'AA==',
        peerUserId: null,
        peerName: null,
        isOutgoing: false,
        startedAt: DateTime.utc(2026, 4, 29, 10, 15, 30),
        activatedAt: null,
        endedAt: DateTime.utc(2026, 4, 29, 10, 15, 35),
        durationSec: null,
        endReason: 'rejectedByCallee',
        transport: null,
      );
      final round = MeshCallHistoryEntry.fromJson(entry.toJson());
      expect(round, entry);
    });

    test('equality and hashCode work field-by-field', () {
      final a = MeshCallHistoryEntry(
        callId: 1,
        peerDevicePkBase64: 'X',
        peerUserId: null,
        peerName: null,
        isOutgoing: true,
        startedAt: DateTime.utc(2026),
        activatedAt: null,
        endedAt: DateTime.utc(2026),
        durationSec: null,
        endReason: 'userHangup',
        transport: null,
      );
      final b = MeshCallHistoryEntry(
        callId: 1,
        peerDevicePkBase64: 'X',
        peerUserId: null,
        peerName: null,
        isOutgoing: true,
        startedAt: DateTime.utc(2026),
        activatedAt: null,
        endedAt: DateTime.utc(2026),
        durationSec: null,
        endReason: 'userHangup',
        transport: null,
      );
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/call_history/data/mesh_call_history_entry_test.dart`
Expected: compile error — `MeshCallHistoryEntry` not defined.

- [ ] **Step 3: Implement `MeshCallHistoryEntry`**

Create `lib/features/call_history/data/mesh_call_history_entry.dart`:

```dart
/// Local-only mesh call history record. Stored in Hive box `mesh_call_history`
/// as a JSON-encoded string (no type adapter — matches the rest of the
/// codebase's Hive-as-string-cache pattern, e.g. `messenger_cache_service`).
class MeshCallHistoryEntry {
  final int callId;
  final String peerDevicePkBase64;
  final String? peerUserId;
  final String? peerName;
  final bool isOutgoing;
  final DateTime startedAt;
  final DateTime? activatedAt;
  final DateTime endedAt;
  final int? durationSec;
  final String endReason;
  final String? transport;

  const MeshCallHistoryEntry({
    required this.callId,
    required this.peerDevicePkBase64,
    required this.peerUserId,
    required this.peerName,
    required this.isOutgoing,
    required this.startedAt,
    required this.activatedAt,
    required this.endedAt,
    required this.durationSec,
    required this.endReason,
    required this.transport,
  });

  Map<String, dynamic> toJson() => {
        'callId': callId,
        'peerDevicePkBase64': peerDevicePkBase64,
        'peerUserId': peerUserId,
        'peerName': peerName,
        'isOutgoing': isOutgoing,
        'startedAt': startedAt.toUtc().toIso8601String(),
        'activatedAt': activatedAt?.toUtc().toIso8601String(),
        'endedAt': endedAt.toUtc().toIso8601String(),
        'durationSec': durationSec,
        'endReason': endReason,
        'transport': transport,
      };

  factory MeshCallHistoryEntry.fromJson(Map<String, dynamic> j) =>
      MeshCallHistoryEntry(
        callId: j['callId'] as int,
        peerDevicePkBase64: j['peerDevicePkBase64'] as String,
        peerUserId: j['peerUserId'] as String?,
        peerName: j['peerName'] as String?,
        isOutgoing: j['isOutgoing'] as bool,
        startedAt: DateTime.parse(j['startedAt'] as String),
        activatedAt: j['activatedAt'] == null
            ? null
            : DateTime.parse(j['activatedAt'] as String),
        endedAt: DateTime.parse(j['endedAt'] as String),
        durationSec: j['durationSec'] as int?,
        endReason: j['endReason'] as String,
        transport: j['transport'] as String?,
      );

  @override
  bool operator ==(Object other) =>
      other is MeshCallHistoryEntry &&
      other.callId == callId &&
      other.peerDevicePkBase64 == peerDevicePkBase64 &&
      other.peerUserId == peerUserId &&
      other.peerName == peerName &&
      other.isOutgoing == isOutgoing &&
      other.startedAt == startedAt &&
      other.activatedAt == activatedAt &&
      other.endedAt == endedAt &&
      other.durationSec == durationSec &&
      other.endReason == endReason &&
      other.transport == transport;

  @override
  int get hashCode => Object.hash(callId, peerDevicePkBase64, peerUserId,
      peerName, isOutgoing, startedAt, activatedAt, endedAt, durationSec,
      endReason, transport);
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/call_history/data/mesh_call_history_entry_test.dart`
Expected: `+3: All tests passed!`

- [ ] **Step 5: Commit**

```bash
git add lib/features/call_history/data/mesh_call_history_entry.dart \
        test/features/call_history/data/mesh_call_history_entry_test.dart
git commit -m "feat(mesh-voice/3d.1): MeshCallHistoryEntry — JSON-serializable history record"
```

---

### Task 2: `HiveMeshCallHistoryRepository`

**Files:**
- Create: `lib/features/call_history/data/mesh_call_history_repository.dart`
- Test: `test/features/call_history/data/mesh_call_history_repository_test.dart`

Hive box uses key = `callId.toString()`, value = `jsonEncode(entry.toJson())`. Stream-watching is implemented via a local `StreamController` updated by `add` / `deleteById`.

- [ ] **Step 1: Write the failing test**

Create `test/features/call_history/data/mesh_call_history_repository_test.dart`:

```dart
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
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/call_history/data/mesh_call_history_repository_test.dart`
Expected: compile error — `HiveMeshCallHistoryRepository` not defined.

- [ ] **Step 3: Implement repository**

Create `lib/features/call_history/data/mesh_call_history_repository.dart`:

```dart
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
  final _ctrl = StreamController<List<MeshCallHistoryEntry>>.broadcast();

  Future<void> init() async {
    try {
      _box = await Hive.openBox<String>(_boxName);
    } catch (e) {
      debugPrint('[mesh-call-history] open failed: $e — recreating');
      await Hive.deleteBoxFromDisk(_boxName);
      _box = await Hive.openBox<String>(_boxName);
    }
    _emit();
  }

  Future<void> dispose() async {
    await _ctrl.close();
    await _box?.close();
    _box = null;
  }

  @override
  Future<void> add(MeshCallHistoryEntry entry) async {
    final box = _box;
    if (box == null) return;
    await box.put(entry.callId.toString(), jsonEncode(entry.toJson()));
    _emit();
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
    _emit();
  }

  @override
  Stream<List<MeshCallHistoryEntry>> watch() => _ctrl.stream;

  void _emit() {
    if (_ctrl.isClosed) return;
    getAll().then((list) {
      if (!_ctrl.isClosed) _ctrl.add(list);
    });
  }
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test test/features/call_history/data/mesh_call_history_repository_test.dart`
Expected: `+5: All tests passed!`

- [ ] **Step 5: Commit**

```bash
git add lib/features/call_history/data/mesh_call_history_repository.dart \
        test/features/call_history/data/mesh_call_history_repository_test.dart
git commit -m "feat(mesh-voice/3d.1): HiveMeshCallHistoryRepository — JSON-in-Hive CRUD + watch stream"
```

---

## UI widgets (data-driven, stateless w.r.t. call state machine)

### Task 3: `MeshIncomingCallSheet` widget

**Files:**
- Create: `lib/features/voice/presentation/widgets/mesh_incoming_call_sheet.dart`
- Test: `test/features/voice/presentation/widgets/mesh_incoming_call_sheet_test.dart`

A `StatefulWidget` because it owns the 30 s self-decline `Timer`. Renders avatar (or fallback initials), name (or fallback `Mesh-устройство <hex>`), subtitle "📡 Входящий mesh-звонок", green Accept + red Decline buttons.

- [ ] **Step 1: Write the failing test**

Create `test/features/voice/presentation/widgets/mesh_incoming_call_sheet_test.dart`:

```dart
import 'dart:typed_data';

import 'package:fake_async/fake_async.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taler_id_mobile/core/mesh/transport/peer_id.dart';
import 'package:taler_id_mobile/features/voice/presentation/widgets/mesh_incoming_call_sheet.dart';

PeerId _peer() =>
    PeerId(Uint8List.fromList(List<int>.generate(32, (i) => i + 100)));

void main() {
  group('MeshIncomingCallSheet', () {
    testWidgets('renders peer name and avatar URL when provided',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: MeshIncomingCallSheet(
            peer: _peer(),
            peerName: 'Alice',
            peerAvatarUrl: 'https://example.com/a.png',
            onAccept: () {},
            onDecline: () {},
          ),
        ),
      ));
      expect(find.text('Alice'), findsOneWidget);
      expect(find.text('📡 Входящий mesh-звонок'), findsOneWidget);
    });

    testWidgets('falls back to "Mesh-устройство <hex>" when peerName is null',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: MeshIncomingCallSheet(
            peer: _peer(),
            peerName: null,
            peerAvatarUrl: null,
            onAccept: () {},
            onDecline: () {},
          ),
        ),
      ));
      // PeerId hex prefix of bytes [100,101,102,103,104,105,106,107] starts
      // with "64656667…"; we just assert the prefix marker is present.
      expect(find.textContaining('Mesh-устройство'), findsOneWidget);
    });

    testWidgets('Accept button fires onAccept', (tester) async {
      var accepted = 0;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: MeshIncomingCallSheet(
            peer: _peer(),
            peerName: 'A',
            peerAvatarUrl: null,
            onAccept: () => accepted++,
            onDecline: () {},
          ),
        ),
      ));
      await tester.tap(find.byKey(const Key('mesh-incoming-accept')));
      await tester.pumpAndSettle();
      expect(accepted, 1);
    });

    testWidgets('Decline button fires onDecline', (tester) async {
      var declined = 0;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: MeshIncomingCallSheet(
            peer: _peer(),
            peerName: 'A',
            peerAvatarUrl: null,
            onAccept: () {},
            onDecline: () => declined++,
          ),
        ),
      ));
      await tester.tap(find.byKey(const Key('mesh-incoming-decline')));
      await tester.pumpAndSettle();
      expect(declined, 1);
    });

    test('30s auto-decline timer fires onDecline once and only once', () {
      fakeAsync((async) {
        var declined = 0;
        final widget = MeshIncomingCallSheet(
          peer: _peer(),
          peerName: 'A',
          peerAvatarUrl: null,
          onAccept: () {},
          onDecline: () => declined++,
        );
        // Driving through tester here is overkill — instead we instantiate
        // the State directly via a TestWidgetsFlutterBinding harness:
        final tester = TestWidgetsFlutterBinding.ensureInitialized();
        // Scoped pump: build the widget once.
        runApp(MaterialApp(home: Scaffold(body: widget)));
        async.elapse(const Duration(seconds: 31));
        expect(declined, 1);
        tester.platformDispatcher.scheduleFrame();
      });
    });
  });
}
```

> Note on the timer test: `fakeAsync` with a real widget tree is awkward in Flutter tests. The cleaner alternative is `tester.pumpWidget` + `tester.pump(const Duration(seconds: 31))`, but `pump()` does not advance internal `Timer` callbacks — only `await tester.pump(...)` calls advance frames, not absolute time. We use the fakeAsync zone wrapper around the widget construction. If this test proves flaky in CI, replace it with a unit test on a private `_AutoDeclineController` extracted from the widget.

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/voice/presentation/widgets/mesh_incoming_call_sheet_test.dart`
Expected: compile error — `MeshIncomingCallSheet` not defined.

- [ ] **Step 3: Implement the sheet**

Create `lib/features/voice/presentation/widgets/mesh_incoming_call_sheet.dart`:

```dart
import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/mesh/transport/peer_id.dart';

class MeshIncomingCallSheet extends StatefulWidget {
  final PeerId peer;
  final String? peerName;
  final String? peerAvatarUrl;
  final VoidCallback onAccept;
  final VoidCallback onDecline;
  final Duration autoDeclineAfter;

  const MeshIncomingCallSheet({
    super.key,
    required this.peer,
    required this.peerName,
    required this.peerAvatarUrl,
    required this.onAccept,
    required this.onDecline,
    this.autoDeclineAfter = const Duration(seconds: 30),
  });

  @override
  State<MeshIncomingCallSheet> createState() => _MeshIncomingCallSheetState();
}

class _MeshIncomingCallSheetState extends State<MeshIncomingCallSheet> {
  Timer? _autoDecline;
  bool _fired = false;

  @override
  void initState() {
    super.initState();
    _autoDecline = Timer(widget.autoDeclineAfter, () {
      if (_fired) return;
      _fired = true;
      widget.onDecline();
    });
  }

  @override
  void dispose() {
    _autoDecline?.cancel();
    super.dispose();
  }

  void _handleAccept() {
    if (_fired) return;
    _fired = true;
    _autoDecline?.cancel();
    widget.onAccept();
  }

  void _handleDecline() {
    if (_fired) return;
    _fired = true;
    _autoDecline?.cancel();
    widget.onDecline();
  }

  String _displayName() {
    final n = widget.peerName;
    if (n != null && n.isNotEmpty) return n;
    final hex = widget.peer.toHex();
    return 'Mesh-устройство ${hex.substring(0, 8)}';
  }

  @override
  Widget build(BuildContext context) {
    final avatarUrl = widget.peerAvatarUrl;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 48,
              backgroundImage:
                  avatarUrl != null && avatarUrl.isNotEmpty
                      ? NetworkImage(avatarUrl)
                      : null,
              child: avatarUrl == null || avatarUrl.isEmpty
                  ? Text(
                      _displayName().substring(0, 1).toUpperCase(),
                      style: const TextStyle(fontSize: 28),
                    )
                  : null,
            ),
            const SizedBox(height: 16),
            Text(_displayName(),
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text('📡 Входящий mesh-звонок',
                style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  key: const Key('mesh-incoming-decline'),
                  onPressed: _handleDecline,
                  icon: const Icon(Icons.call_end),
                  label: const Text('Отклонить'),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red, foregroundColor: Colors.white),
                ),
                ElevatedButton.icon(
                  key: const Key('mesh-incoming-accept'),
                  onPressed: _handleAccept,
                  icon: const Icon(Icons.call),
                  label: const Text('Принять'),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green, foregroundColor: Colors.white),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test test/features/voice/presentation/widgets/mesh_incoming_call_sheet_test.dart`
Expected: 4 of 5 tests pass; the 30s auto-decline test may need refinement (see step 3 note). If it fails, **simplify** the test:

```dart
testWidgets('30s auto-decline calls onDecline', (tester) async {
  var declined = 0;
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: MeshIncomingCallSheet(
        peer: _peer(),
        peerName: 'A',
        peerAvatarUrl: null,
        onAccept: () {},
        onDecline: () => declined++,
        autoDeclineAfter: const Duration(milliseconds: 50),
      ),
    ),
  ));
  await tester.pump(const Duration(milliseconds: 100));
  expect(declined, 1);
});
```

Re-run; expected: `+5: All tests passed!`

- [ ] **Step 5: Commit**

```bash
git add lib/features/voice/presentation/widgets/mesh_incoming_call_sheet.dart \
        test/features/voice/presentation/widgets/mesh_incoming_call_sheet_test.dart
git commit -m "feat(mesh-voice/3d.1): MeshIncomingCallSheet — modal sheet with 30s auto-decline"
```

---

### Task 4: `MeshVoiceCallScreen` widget

**Files:**
- Create: `lib/features/voice/presentation/screens/mesh_voice_call_screen.dart`
- Test: `test/features/voice/presentation/screens/mesh_voice_call_screen_test.dart`

A `StatefulWidget` driven by an injected `Stream<CallState>`. Owns local mute state and the active-duration timer. Renders avatar, name, status text (state-derived), transport badge, mute + hangup buttons. On `EndedState`, displays the closure label for 1.5 s then `Navigator.pop(context)`.

- [ ] **Step 1: Write the failing test**

Create `test/features/voice/presentation/screens/mesh_voice_call_screen_test.dart`:

```dart
import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taler_id_mobile/core/mesh/transport/peer_id.dart';
import 'package:taler_id_mobile/core/mesh/voice/mesh_voice_state.dart';
import 'package:taler_id_mobile/features/voice/presentation/screens/mesh_voice_call_screen.dart';

PeerId _peer() =>
    PeerId(Uint8List.fromList(List<int>.generate(32, (i) => i + 100)));

void main() {
  group('MeshVoiceCallScreen', () {
    testWidgets('renders "Вызов…" status during InvitingState', (tester) async {
      final ctrl = StreamController<CallState>.broadcast();
      addTearDown(ctrl.close);
      await tester.pumpWidget(MaterialApp(
        home: MeshVoiceCallScreen(
          stateStream: ctrl.stream,
          peer: _peer(),
          peerName: 'Alice',
          peerAvatarUrl: null,
          transportName: 'Bonjour',
          onMuteToggle: () async {},
          onHangup: () async {},
        ),
      ));
      ctrl.add(InvitingState(
          calleeDevicePk: _peer(), callId: 1, sentAt: DateTime.utc(2026)));
      await tester.pump();
      expect(find.text('Alice'), findsOneWidget);
      expect(find.text('Вызов…'), findsOneWidget);
      expect(find.textContaining('Mesh · Bonjour'), findsOneWidget);
    });

    testWidgets('renders timer during ActiveState', (tester) async {
      final ctrl = StreamController<CallState>.broadcast();
      addTearDown(ctrl.close);
      await tester.pumpWidget(MaterialApp(
        home: MeshVoiceCallScreen(
          stateStream: ctrl.stream,
          peer: _peer(),
          peerName: 'Alice',
          peerAvatarUrl: null,
          transportName: 'BLE',
          onMuteToggle: () async {},
          onHangup: () async {},
        ),
      ));
      ctrl.add(ActiveState(
          peerDevicePk: _peer(),
          callId: 1,
          isCaller: true,
          startedAt: DateTime.now()));
      await tester.pump();
      expect(find.textContaining('0:0'), findsOneWidget); // matches 0:00 / 0:01
      await tester.pump(const Duration(seconds: 2));
      expect(find.textContaining('0:0'), findsOneWidget); // 0:02 still matches
    });

    testWidgets('hangup tap fires onHangup callback', (tester) async {
      final ctrl = StreamController<CallState>.broadcast();
      addTearDown(ctrl.close);
      var hung = 0;
      await tester.pumpWidget(MaterialApp(
        home: MeshVoiceCallScreen(
          stateStream: ctrl.stream,
          peer: _peer(),
          peerName: 'A',
          peerAvatarUrl: null,
          transportName: null,
          onMuteToggle: () async {},
          onHangup: () async => hung++,
        ),
      ));
      ctrl.add(ActiveState(
          peerDevicePk: _peer(),
          callId: 1,
          isCaller: false,
          startedAt: DateTime.now()));
      await tester.pump();
      await tester.tap(find.byKey(const Key('mesh-call-hangup')));
      await tester.pump();
      expect(hung, 1);
    });

    testWidgets('mute toggle fires onMuteToggle callback', (tester) async {
      final ctrl = StreamController<CallState>.broadcast();
      addTearDown(ctrl.close);
      var toggled = 0;
      await tester.pumpWidget(MaterialApp(
        home: MeshVoiceCallScreen(
          stateStream: ctrl.stream,
          peer: _peer(),
          peerName: 'A',
          peerAvatarUrl: null,
          transportName: null,
          onMuteToggle: () async => toggled++,
          onHangup: () async {},
        ),
      ));
      ctrl.add(ActiveState(
          peerDevicePk: _peer(),
          callId: 1,
          isCaller: true,
          startedAt: DateTime.now()));
      await tester.pump();
      await tester.tap(find.byKey(const Key('mesh-call-mute')));
      await tester.pump();
      expect(toggled, 1);
    });

    testWidgets('EndedState shows reason-specific status text', (tester) async {
      final ctrl = StreamController<CallState>.broadcast();
      addTearDown(ctrl.close);
      await tester.pumpWidget(MaterialApp(
        home: MeshVoiceCallScreen(
          stateStream: ctrl.stream,
          peer: _peer(),
          peerName: 'A',
          peerAvatarUrl: null,
          transportName: null,
          onMuteToggle: () async {},
          onHangup: () async {},
        ),
      ));
      ctrl.add(EndedState(callId: 1, reason: EndReason.noKeepalive));
      await tester.pump();
      expect(find.text('Соединение потеряно'), findsOneWidget);
    });

    testWidgets('auto-pops the route 1.5s after EndedState', (tester) async {
      final ctrl = StreamController<CallState>.broadcast();
      addTearDown(ctrl.close);
      final navObserver = _PopObserver();
      await tester.pumpWidget(MaterialApp(
        navigatorObservers: [navObserver],
        home: Builder(
          builder: (ctx) => Scaffold(
            body: ElevatedButton(
              onPressed: () => Navigator.of(ctx).push(MaterialPageRoute(
                builder: (_) => MeshVoiceCallScreen(
                  stateStream: ctrl.stream,
                  peer: _peer(),
                  peerName: 'A',
                  peerAvatarUrl: null,
                  transportName: null,
                  onMuteToggle: () async {},
                  onHangup: () async {},
                  popDelay: const Duration(milliseconds: 50),
                ),
              )),
              child: const Text('go'),
            ),
          ),
        ),
      ));
      await tester.tap(find.text('go'));
      await tester.pumpAndSettle();
      ctrl.add(EndedState(callId: 1, reason: EndReason.userHangup));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();
      expect(navObserver.popped, isTrue);
    });
  });
}

class _PopObserver extends NavigatorObserver {
  bool popped = false;
  @override
  void didPop(Route route, Route? previousRoute) {
    popped = true;
    super.didPop(route, previousRoute);
  }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/voice/presentation/screens/mesh_voice_call_screen_test.dart`
Expected: compile error — `MeshVoiceCallScreen` not defined.

- [ ] **Step 3: Implement the screen**

Create `lib/features/voice/presentation/screens/mesh_voice_call_screen.dart`:

```dart
import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/mesh/transport/peer_id.dart';
import '../../../../core/mesh/voice/mesh_voice_state.dart';

class MeshVoiceCallScreen extends StatefulWidget {
  final Stream<CallState> stateStream;
  final PeerId peer;
  final String? peerName;
  final String? peerAvatarUrl;
  final String? transportName; // 'Bonjour' | 'BLE' | null
  final Future<void> Function() onMuteToggle;
  final Future<void> Function() onHangup;
  final Duration popDelay;

  const MeshVoiceCallScreen({
    super.key,
    required this.stateStream,
    required this.peer,
    required this.peerName,
    required this.peerAvatarUrl,
    required this.transportName,
    required this.onMuteToggle,
    required this.onHangup,
    this.popDelay = const Duration(milliseconds: 1500),
  });

  @override
  State<MeshVoiceCallScreen> createState() => _MeshVoiceCallScreenState();
}

class _MeshVoiceCallScreenState extends State<MeshVoiceCallScreen> {
  CallState _state = const IdleState();
  StreamSubscription<CallState>? _sub;
  Timer? _ticker;
  Timer? _popTimer;
  DateTime? _activeStartedAt;
  Duration _activeElapsed = Duration.zero;
  bool _isMuted = false;
  bool _hasPopped = false;

  @override
  void initState() {
    super.initState();
    _sub = widget.stateStream.listen(_onState);
  }

  @override
  void dispose() {
    _sub?.cancel();
    _ticker?.cancel();
    _popTimer?.cancel();
    super.dispose();
  }

  void _onState(CallState st) {
    setState(() => _state = st);
    if (st is ActiveState) {
      _activeStartedAt ??= st.startedAt;
      _ticker ??= Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted || _activeStartedAt == null) return;
        setState(() {
          _activeElapsed = DateTime.now().difference(_activeStartedAt!);
        });
      });
    }
    if (st is EndedState && !_hasPopped) {
      _ticker?.cancel();
      _ticker = null;
      _popTimer ??= Timer(widget.popDelay, () {
        if (!mounted || _hasPopped) return;
        _hasPopped = true;
        Navigator.of(context).maybePop();
      });
    }
  }

  String _displayName() {
    final n = widget.peerName;
    if (n != null && n.isNotEmpty) return n;
    return 'Mesh-устройство ${widget.peer.toHex().substring(0, 8)}';
  }

  String _statusText() {
    final st = _state;
    if (st is InvitingState) return 'Вызов…';
    if (st is ConnectingState) return 'Соединение…';
    if (st is ActiveState) {
      final m = _activeElapsed.inMinutes;
      final s = _activeElapsed.inSeconds % 60;
      return '$m:${s.toString().padLeft(2, '0')}';
    }
    if (st is EndedState) {
      switch (st.reason) {
        case EndReason.userHangup:
          return 'Звонок завершён';
        case EndReason.remoteHangup:
          return 'Завершён собеседником';
        case EndReason.rejectedByCallee:
          return 'Отклонён';
        case EndReason.inviteTimeout:
          return 'Не отвечает';
        case EndReason.noKeepalive:
        case EndReason.peerLost:
          return 'Соединение потеряно';
        case EndReason.setupTimeout:
        case EndReason.error:
          return 'Ошибка соединения';
      }
    }
    return '';
  }

  String _transportBadge() {
    final t = widget.transportName;
    return t != null ? '📡 Mesh · $t' : '📡 Mesh';
  }

  @override
  Widget build(BuildContext context) {
    final avatarUrl = widget.peerAvatarUrl;
    return Scaffold(
      backgroundColor: Colors.black87,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 60),
            CircleAvatar(
              radius: 64,
              backgroundImage:
                  avatarUrl != null && avatarUrl.isNotEmpty
                      ? NetworkImage(avatarUrl)
                      : null,
              child: avatarUrl == null || avatarUrl.isEmpty
                  ? Text(_displayName().substring(0, 1).toUpperCase(),
                      style: const TextStyle(fontSize: 36, color: Colors.white))
                  : null,
            ),
            const SizedBox(height: 24),
            Text(_displayName(),
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(_statusText(),
                style: const TextStyle(color: Colors.white70, fontSize: 16)),
            const SizedBox(height: 12),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white12,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(_transportBadge(),
                  style:
                      const TextStyle(color: Colors.white, fontSize: 12)),
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  key: const Key('mesh-call-mute'),
                  iconSize: 36,
                  color: Colors.white,
                  icon: Icon(_isMuted ? Icons.mic_off : Icons.mic),
                  onPressed: () async {
                    await widget.onMuteToggle();
                    if (mounted) setState(() => _isMuted = !_isMuted);
                  },
                ),
                FloatingActionButton(
                  key: const Key('mesh-call-hangup'),
                  backgroundColor: Colors.red,
                  onPressed: widget.onHangup,
                  child: const Icon(Icons.call_end),
                ),
              ],
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test test/features/voice/presentation/screens/mesh_voice_call_screen_test.dart`
Expected: `+6: All tests passed!`

- [ ] **Step 5: Commit**

```bash
git add lib/features/voice/presentation/screens/mesh_voice_call_screen.dart \
        test/features/voice/presentation/screens/mesh_voice_call_screen_test.dart
git commit -m "feat(mesh-voice/3d.1): MeshVoiceCallScreen — active call UI driven by CallState stream"
```

---

## Coordinator (signaling → UI bridge)

The Coordinator is built incrementally over Tasks 5-9. Each task adds one state-transition handler. We use a single test file and append cases as we go.

### Task 5: Coordinator scaffold + dependencies + start/dispose

**Files:**
- Create: `lib/core/voice/mesh_voice_ui_coordinator.dart`
- Test: `test/core/voice/mesh_voice_ui_coordinator_test.dart`

The Coordinator uses a `_Navigator` interface (injected) that wraps `globalNavigatorKey` so tests can substitute a fake. Same for a `_PeerInfoLookup` callback (injected) for resolving peer name / userId / avatar.

- [ ] **Step 1: Write the failing test**

Create `test/core/voice/mesh_voice_ui_coordinator_test.dart`:

```dart
import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taler_id_mobile/core/mesh/transport/peer_id.dart';
import 'package:taler_id_mobile/core/mesh/voice/mesh_voice_state.dart';
import 'package:taler_id_mobile/core/voice/mesh_voice_ui_coordinator.dart';
import 'package:taler_id_mobile/features/call_history/data/mesh_call_history_entry.dart';
import 'package:taler_id_mobile/features/call_history/data/mesh_call_history_repository.dart';

class _FakeRepo implements MeshCallHistoryRepository {
  final entries = <MeshCallHistoryEntry>[];
  final _ctrl = StreamController<List<MeshCallHistoryEntry>>.broadcast();
  @override
  Future<void> add(MeshCallHistoryEntry entry) async {
    entries.add(entry);
    _ctrl.add(List.of(entries));
  }
  @override
  Future<void> deleteById(int callId) async {
    entries.removeWhere((e) => e.callId == callId);
    _ctrl.add(List.of(entries));
  }
  @override
  Future<List<MeshCallHistoryEntry>> getAll() async => List.of(entries);
  @override
  Stream<List<MeshCallHistoryEntry>> watch() => _ctrl.stream;
}

class _SpyNavigator implements MeshNavigator {
  String? lastPushedRouteName;
  Widget? lastPushedScreen;
  bool sheetOpen = false;
  Widget? lastSheet;
  bool sheetPopped = false;
  bool screenPopped = false;
  String? snackbar;

  @override
  Future<T?> pushScreen<T>(Widget screen) async {
    lastPushedScreen = screen;
    return null;
  }

  @override
  Future<void> showSheet(Widget sheet) async {
    sheetOpen = true;
    lastSheet = sheet;
  }

  @override
  void popSheet() {
    if (sheetOpen) {
      sheetOpen = false;
      sheetPopped = true;
    }
  }

  @override
  void popScreen() {
    screenPopped = true;
  }

  @override
  void showSnackbar(String message) {
    snackbar = message;
  }
}

PeerId _peer(int seed) =>
    PeerId(Uint8List.fromList(List<int>.generate(32, (i) => i + seed)));

void main() {
  group('MeshVoiceUiCoordinator scaffold', () {
    test('start() subscribes to stateStream; dispose() cancels', () async {
      final ctrl = StreamController<CallState>.broadcast();
      final repo = _FakeRepo();
      final nav = _SpyNavigator();
      final coord = MeshVoiceUiCoordinator(
        stateStream: ctrl.stream,
        invite: (_) async => 1,
        accept: () async {},
        reject: () async {},
        hangup: () async {},
        repo: repo,
        navigator: nav,
        peerInfoLookup: (_) async => const MeshPeerInfo(),
        selfDevicePk: _peer(0),
        transportLabelForPeer: (_) => 'Bonjour',
      );
      coord.start();
      await coord.dispose();
      expect(ctrl.hasListener, isFalse);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/core/voice/mesh_voice_ui_coordinator_test.dart`
Expected: compile error — `MeshVoiceUiCoordinator` / `MeshNavigator` / `MeshPeerInfo` not defined.

- [ ] **Step 3: Implement the scaffold**

Create `lib/core/voice/mesh_voice_ui_coordinator.dart`:

```dart
import 'dart:async';

import 'package:flutter/material.dart';

import '../mesh/transport/peer_id.dart';
import '../mesh/voice/mesh_voice_state.dart';
import '../../features/call_history/data/mesh_call_history_repository.dart';

/// Thin abstraction over `globalNavigatorKey` so unit tests can inject a spy.
abstract class MeshNavigator {
  Future<T?> pushScreen<T>(Widget screen);
  Future<void> showSheet(Widget sheet);
  void popSheet();
  void popScreen();
  void showSnackbar(String message);
}

class MeshPeerInfo {
  final String? userId;
  final String? name;
  final String? avatarUrl;
  const MeshPeerInfo({this.userId, this.name, this.avatarUrl});
}

/// Singleton UI controller for mesh voice calls.
///
/// Subscribes to [MeshVoiceService.stateStream] and drives navigation
/// (modal sheet + active-call screen) and Hive history writes. Exposes
/// [placeCall] as the imperative entry point used by debug / chat UIs.
class MeshVoiceUiCoordinator {
  final Stream<CallState> stateStream;
  final Future<int> Function(PeerId peer) invite;
  final Future<void> Function() accept;
  final Future<void> Function() reject;
  final Future<void> Function() hangup;
  final MeshCallHistoryRepository repo;
  final MeshNavigator navigator;
  final Future<MeshPeerInfo> Function(PeerId peer) peerInfoLookup;
  final PeerId selfDevicePk;
  final String? Function(PeerId peer) transportLabelForPeer;

  StreamSubscription<CallState>? _sub;

  // Per-call snapshot built during Inviting/Incoming, finalized on Ended.
  _PendingCall? _pending;
  // Whether MeshVoiceCallScreen is currently in the navigator stack.
  bool _screenPushed = false;

  MeshVoiceUiCoordinator({
    required this.stateStream,
    required this.invite,
    required this.accept,
    required this.reject,
    required this.hangup,
    required this.repo,
    required this.navigator,
    required this.peerInfoLookup,
    required this.selfDevicePk,
    required this.transportLabelForPeer,
  });

  void start() {
    _sub ??= stateStream.listen(_onState);
  }

  Future<void> dispose() async {
    await _sub?.cancel();
    _sub = null;
  }

  void _onState(CallState st) {
    // Tasks 6-9 fill this in.
  }
}

class _PendingCall {
  final int callId;
  final PeerId peer;
  final String? peerUserId;
  final String? peerName;
  final String? peerAvatarUrl;
  final bool isOutgoing;
  final DateTime startedAt;
  DateTime? activatedAt;
  final String? transport;

  _PendingCall({
    required this.callId,
    required this.peer,
    required this.peerUserId,
    required this.peerName,
    required this.peerAvatarUrl,
    required this.isOutgoing,
    required this.startedAt,
    required this.transport,
  });
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/core/voice/mesh_voice_ui_coordinator_test.dart`
Expected: `+1: All tests passed!`

- [ ] **Step 5: Commit**

```bash
git add lib/core/voice/mesh_voice_ui_coordinator.dart \
        test/core/voice/mesh_voice_ui_coordinator_test.dart
git commit -m "feat(mesh-voice/3d.1): MeshVoiceUiCoordinator scaffold + MeshNavigator interface"
```

---

### Task 6: Coordinator handles `InvitingState` (caller side — push screen)

**Files:**
- Modify: `lib/core/voice/mesh_voice_ui_coordinator.dart`
- Test: `test/core/voice/mesh_voice_ui_coordinator_test.dart`

- [ ] **Step 1: Append failing test**

Append to `test/core/voice/mesh_voice_ui_coordinator_test.dart`, inside the existing `main()`:

```dart
group('Coordinator caller path', () {
  test('on InvitingState, looks up peer info and pushes MeshVoiceCallScreen',
      () async {
    final ctrl = StreamController<CallState>.broadcast();
    final repo = _FakeRepo();
    final nav = _SpyNavigator();
    final coord = MeshVoiceUiCoordinator(
      stateStream: ctrl.stream,
      invite: (_) async => 1,
      accept: () async {},
      reject: () async {},
      hangup: () async {},
      repo: repo,
      navigator: nav,
      peerInfoLookup: (_) async => const MeshPeerInfo(
          userId: 'user-7', name: 'Bob', avatarUrl: 'https://x/y.png'),
      selfDevicePk: _peer(0),
      transportLabelForPeer: (_) => 'BLE',
    );
    coord.start();
    ctrl.add(InvitingState(
        calleeDevicePk: _peer(7),
        callId: 0xABCD,
        sentAt: DateTime.utc(2026, 4, 29, 10)));
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(nav.lastPushedScreen, isNotNull);
    await coord.dispose();
  });
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/core/voice/mesh_voice_ui_coordinator_test.dart`
Expected: failure — `nav.lastPushedScreen` is null.

- [ ] **Step 3: Implement `_onState` for InvitingState**

In `lib/core/voice/mesh_voice_ui_coordinator.dart`, add the import for `MeshVoiceCallScreen` and replace `_onState` body:

```dart
import '../../features/voice/presentation/screens/mesh_voice_call_screen.dart';
```

```dart
void _onState(CallState st) {
  if (st is InvitingState) {
    _handleInviting(st);
  }
}

Future<void> _handleInviting(InvitingState st) async {
  final info = await peerInfoLookup(st.calleeDevicePk);
  _pending = _PendingCall(
    callId: st.callId,
    peer: st.calleeDevicePk,
    peerUserId: info.userId,
    peerName: info.name,
    peerAvatarUrl: info.avatarUrl,
    isOutgoing: true,
    startedAt: st.sentAt,
    transport: transportLabelForPeer(st.calleeDevicePk),
  );
  if (_screenPushed) return;
  _screenPushed = true;
  final screenStream = stateStream;
  await navigator.pushScreen(MeshVoiceCallScreen(
    stateStream: screenStream,
    peer: st.calleeDevicePk,
    peerName: info.name,
    peerAvatarUrl: info.avatarUrl,
    transportName: transportLabelForPeer(st.calleeDevicePk),
    onMuteToggle: () async {},
    onHangup: hangup,
  ));
  _screenPushed = false;
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test test/core/voice/mesh_voice_ui_coordinator_test.dart`
Expected: `+2: All tests passed!`

- [ ] **Step 5: Commit**

```bash
git add lib/core/voice/mesh_voice_ui_coordinator.dart \
        test/core/voice/mesh_voice_ui_coordinator_test.dart
git commit -m "feat(mesh-voice/3d.1): coordinator handles InvitingState (caller path)"
```

---

### Task 7: Coordinator handles `IncomingState` (callee side — show sheet)

**Files:**
- Modify: `lib/core/voice/mesh_voice_ui_coordinator.dart`
- Test: `test/core/voice/mesh_voice_ui_coordinator_test.dart`

- [ ] **Step 1: Append failing test**

Append to `test/core/voice/mesh_voice_ui_coordinator_test.dart`:

```dart
group('Coordinator callee path', () {
  test('on IncomingState, opens modal sheet with peer info', () async {
    final ctrl = StreamController<CallState>.broadcast();
    final repo = _FakeRepo();
    final nav = _SpyNavigator();
    final coord = MeshVoiceUiCoordinator(
      stateStream: ctrl.stream,
      invite: (_) async => 1,
      accept: () async {},
      reject: () async {},
      hangup: () async {},
      repo: repo,
      navigator: nav,
      peerInfoLookup: (_) async =>
          const MeshPeerInfo(userId: 'u', name: 'Carol', avatarUrl: null),
      selfDevicePk: _peer(0),
      transportLabelForPeer: (_) => 'Bonjour',
    );
    coord.start();
    ctrl.add(IncomingState(
        callerDevicePk: _peer(7),
        callId: 0xBEEF,
        receivedAt: DateTime.utc(2026, 4, 29)));
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(nav.sheetOpen, isTrue);
    expect(nav.lastSheet, isNotNull);
    await coord.dispose();
  });
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/core/voice/mesh_voice_ui_coordinator_test.dart`
Expected: failure — `nav.sheetOpen` is false.

- [ ] **Step 3: Implement IncomingState handler**

Add import:

```dart
import '../../features/voice/presentation/widgets/mesh_incoming_call_sheet.dart';
```

Update `_onState`:

```dart
void _onState(CallState st) {
  if (st is InvitingState) {
    _handleInviting(st);
  } else if (st is IncomingState) {
    _handleIncoming(st);
  }
}

Future<void> _handleIncoming(IncomingState st) async {
  final info = await peerInfoLookup(st.callerDevicePk);
  _pending = _PendingCall(
    callId: st.callId,
    peer: st.callerDevicePk,
    peerUserId: info.userId,
    peerName: info.name,
    peerAvatarUrl: info.avatarUrl,
    isOutgoing: false,
    startedAt: st.receivedAt,
    transport: transportLabelForPeer(st.callerDevicePk),
  );
  await navigator.showSheet(MeshIncomingCallSheet(
    peer: st.callerDevicePk,
    peerName: info.name,
    peerAvatarUrl: info.avatarUrl,
    onAccept: () => accept(),
    onDecline: () => reject(),
  ));
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test test/core/voice/mesh_voice_ui_coordinator_test.dart`
Expected: `+3: All tests passed!`

- [ ] **Step 5: Commit**

```bash
git add lib/core/voice/mesh_voice_ui_coordinator.dart \
        test/core/voice/mesh_voice_ui_coordinator_test.dart
git commit -m "feat(mesh-voice/3d.1): coordinator handles IncomingState (callee path)"
```

---

### Task 8: Coordinator handles `ActiveState` (callee — pop sheet, push screen)

**Files:**
- Modify: `lib/core/voice/mesh_voice_ui_coordinator.dart`
- Test: `test/core/voice/mesh_voice_ui_coordinator_test.dart`

On the caller path, `_screenPushed` is already true when ActiveState arrives — screen handles the transition itself via its stream subscription. On the callee path, `_screenPushed` is false; pop the sheet, push the screen.

- [ ] **Step 1: Append failing test**

Append to `test/core/voice/mesh_voice_ui_coordinator_test.dart`:

```dart
group('Coordinator ActiveState', () {
  test('callee path: pops sheet and pushes screen on ActiveState', () async {
    final ctrl = StreamController<CallState>.broadcast();
    final repo = _FakeRepo();
    final nav = _SpyNavigator();
    final coord = MeshVoiceUiCoordinator(
      stateStream: ctrl.stream,
      invite: (_) async => 1,
      accept: () async {},
      reject: () async {},
      hangup: () async {},
      repo: repo,
      navigator: nav,
      peerInfoLookup: (_) async => const MeshPeerInfo(name: 'D'),
      selfDevicePk: _peer(0),
      transportLabelForPeer: (_) => 'Bonjour',
    );
    coord.start();
    ctrl.add(IncomingState(
        callerDevicePk: _peer(9),
        callId: 5,
        receivedAt: DateTime.utc(2026)));
    await Future<void>.delayed(const Duration(milliseconds: 50));
    ctrl.add(ActiveState(
        peerDevicePk: _peer(9),
        callId: 5,
        isCaller: false,
        startedAt: DateTime.utc(2026, 4, 29, 10)));
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(nav.sheetPopped, isTrue);
    expect(nav.lastPushedScreen, isNotNull);
    await coord.dispose();
  });
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/core/voice/mesh_voice_ui_coordinator_test.dart`
Expected: failure — `nav.sheetPopped` is false.

- [ ] **Step 3: Implement ActiveState handler**

Update `_onState`:

```dart
void _onState(CallState st) {
  if (st is InvitingState) {
    _handleInviting(st);
  } else if (st is IncomingState) {
    _handleIncoming(st);
  } else if (st is ActiveState) {
    _handleActive(st);
  }
}

Future<void> _handleActive(ActiveState st) async {
  final p = _pending;
  if (p != null && p.callId == st.callId) {
    p.activatedAt = st.startedAt;
  }
  // Caller side already has the screen pushed; nothing to do.
  if (_screenPushed) return;
  // Callee side: close sheet, push screen.
  navigator.popSheet();
  _screenPushed = true;
  await navigator.pushScreen(MeshVoiceCallScreen(
    stateStream: stateStream,
    peer: st.peerDevicePk,
    peerName: p?.peerName,
    peerAvatarUrl: p?.peerAvatarUrl,
    transportName: transportLabelForPeer(st.peerDevicePk),
    onMuteToggle: () async {},
    onHangup: hangup,
  ));
  _screenPushed = false;
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test test/core/voice/mesh_voice_ui_coordinator_test.dart`
Expected: `+4: All tests passed!`

- [ ] **Step 5: Commit**

```bash
git add lib/core/voice/mesh_voice_ui_coordinator.dart \
        test/core/voice/mesh_voice_ui_coordinator_test.dart
git commit -m "feat(mesh-voice/3d.1): coordinator handles ActiveState (callee pops sheet, pushes screen)"
```

---

### Task 9: Coordinator handles `EndedState` (history write + cleanup)

**Files:**
- Modify: `lib/core/voice/mesh_voice_ui_coordinator.dart`
- Test: `test/core/voice/mesh_voice_ui_coordinator_test.dart`

- [ ] **Step 1: Append failing test**

Append to `test/core/voice/mesh_voice_ui_coordinator_test.dart`:

```dart
group('Coordinator EndedState', () {
  test('caller hangup mid-call writes history with userHangup reason', () async {
    final ctrl = StreamController<CallState>.broadcast();
    final repo = _FakeRepo();
    final nav = _SpyNavigator();
    final coord = MeshVoiceUiCoordinator(
      stateStream: ctrl.stream,
      invite: (_) async => 100,
      accept: () async {},
      reject: () async {},
      hangup: () async {},
      repo: repo,
      navigator: nav,
      peerInfoLookup: (_) async =>
          const MeshPeerInfo(userId: 'u-7', name: 'Bob'),
      selfDevicePk: _peer(0),
      transportLabelForPeer: (_) => 'Bonjour',
    );
    coord.start();
    ctrl.add(InvitingState(
        calleeDevicePk: _peer(7),
        callId: 100,
        sentAt: DateTime.utc(2026, 4, 29, 10)));
    await Future<void>.delayed(const Duration(milliseconds: 30));
    ctrl.add(ActiveState(
        peerDevicePk: _peer(7),
        callId: 100,
        isCaller: true,
        startedAt: DateTime.utc(2026, 4, 29, 10, 0, 2)));
    await Future<void>.delayed(const Duration(milliseconds: 30));
    ctrl.add(EndedState(callId: 100, reason: EndReason.userHangup));
    await Future<void>.delayed(const Duration(milliseconds: 30));
    expect(repo.entries, hasLength(1));
    final e = repo.entries.single;
    expect(e.callId, 100);
    expect(e.peerName, 'Bob');
    expect(e.peerUserId, 'u-7');
    expect(e.isOutgoing, isTrue);
    expect(e.endReason, 'userHangup');
    expect(e.transport, 'Bonjour');
    expect(e.activatedAt, isNotNull);
    expect(e.durationSec, isNotNull);
    expect(e.durationSec! >= 0, isTrue);
    await coord.dispose();
  });

  test('callee declines invite — history written with userHangup, no activatedAt',
      () async {
    final ctrl = StreamController<CallState>.broadcast();
    final repo = _FakeRepo();
    final nav = _SpyNavigator();
    final coord = MeshVoiceUiCoordinator(
      stateStream: ctrl.stream,
      invite: (_) async => 1,
      accept: () async {},
      reject: () async {},
      hangup: () async {},
      repo: repo,
      navigator: nav,
      peerInfoLookup: (_) async => const MeshPeerInfo(),
      selfDevicePk: _peer(0),
      transportLabelForPeer: (_) => 'BLE',
    );
    coord.start();
    ctrl.add(IncomingState(
        callerDevicePk: _peer(9),
        callId: 50,
        receivedAt: DateTime.utc(2026, 4, 29)));
    await Future<void>.delayed(const Duration(milliseconds: 30));
    ctrl.add(EndedState(callId: 50, reason: EndReason.userHangup));
    await Future<void>.delayed(const Duration(milliseconds: 30));
    expect(repo.entries, hasLength(1));
    expect(repo.entries.single.activatedAt, isNull);
    expect(repo.entries.single.durationSec, isNull);
    expect(repo.entries.single.isOutgoing, isFalse);
    await coord.dispose();
  });

  test('Ended without prior _pending writes nothing (defensive)', () async {
    final ctrl = StreamController<CallState>.broadcast();
    final repo = _FakeRepo();
    final coord = MeshVoiceUiCoordinator(
      stateStream: ctrl.stream,
      invite: (_) async => 1,
      accept: () async {},
      reject: () async {},
      hangup: () async {},
      repo: repo,
      navigator: _SpyNavigator(),
      peerInfoLookup: (_) async => const MeshPeerInfo(),
      selfDevicePk: _peer(0),
      transportLabelForPeer: (_) => null,
    );
    coord.start();
    ctrl.add(EndedState(callId: 999, reason: EndReason.userHangup));
    await Future<void>.delayed(const Duration(milliseconds: 30));
    expect(repo.entries, isEmpty);
    await coord.dispose();
  });
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/core/voice/mesh_voice_ui_coordinator_test.dart`
Expected: failure — `repo.entries` is empty.

- [ ] **Step 3: Implement EndedState handler**

Add imports:

```dart
import 'dart:convert';
```

Update `_onState`:

```dart
void _onState(CallState st) {
  if (st is InvitingState) {
    _handleInviting(st);
  } else if (st is IncomingState) {
    _handleIncoming(st);
  } else if (st is ActiveState) {
    _handleActive(st);
  } else if (st is EndedState) {
    _handleEnded(st);
  }
}

Future<void> _handleEnded(EndedState st) async {
  final p = _pending;
  _pending = null;
  navigator.popSheet();
  if (p == null) return; // no inflight call to log
  if (p.callId != st.callId) return;
  final endedAt = DateTime.now().toUtc();
  final dur = p.activatedAt == null
      ? null
      : endedAt.difference(p.activatedAt!).inSeconds;
  await repo.add(MeshCallHistoryEntry(
    callId: p.callId,
    peerDevicePkBase64: base64Encode(p.peer.bytes),
    peerUserId: p.peerUserId,
    peerName: p.peerName,
    isOutgoing: p.isOutgoing,
    startedAt: p.startedAt,
    activatedAt: p.activatedAt,
    endedAt: endedAt,
    durationSec: dur,
    endReason: st.reason.name,
    transport: p.transport,
  ));
}
```

Add import for `MeshCallHistoryEntry`:

```dart
import '../../features/call_history/data/mesh_call_history_entry.dart';
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test test/core/voice/mesh_voice_ui_coordinator_test.dart`
Expected: `+7: All tests passed!`

- [ ] **Step 5: Commit**

```bash
git add lib/core/voice/mesh_voice_ui_coordinator.dart \
        test/core/voice/mesh_voice_ui_coordinator_test.dart
git commit -m "feat(mesh-voice/3d.1): coordinator handles EndedState — writes history entry"
```

---

### Task 10: Coordinator `placeCall` helper (loopback guard + StateError snackbar)

**Files:**
- Modify: `lib/core/voice/mesh_voice_ui_coordinator.dart`
- Test: `test/core/voice/mesh_voice_ui_coordinator_test.dart`

- [ ] **Step 1: Append failing tests**

Append to `test/core/voice/mesh_voice_ui_coordinator_test.dart`:

```dart
group('Coordinator placeCall', () {
  test('loopback (peer == self) is silently ignored', () async {
    final ctrl = StreamController<CallState>.broadcast();
    var inviteCalled = 0;
    final coord = MeshVoiceUiCoordinator(
      stateStream: ctrl.stream,
      invite: (_) async {
        inviteCalled++;
        return 1;
      },
      accept: () async {},
      reject: () async {},
      hangup: () async {},
      repo: _FakeRepo(),
      navigator: _SpyNavigator(),
      peerInfoLookup: (_) async => const MeshPeerInfo(),
      selfDevicePk: _peer(0),
      transportLabelForPeer: (_) => null,
    );
    coord.start();
    await coord.placeCall(_peer(0)); // self
    expect(inviteCalled, 0);
    await coord.dispose();
  });

  test('StateError from invite shows snackbar', () async {
    final ctrl = StreamController<CallState>.broadcast();
    final nav = _SpyNavigator();
    final coord = MeshVoiceUiCoordinator(
      stateStream: ctrl.stream,
      invite: (_) async => throw StateError('cannot invite: already in foo'),
      accept: () async {},
      reject: () async {},
      hangup: () async {},
      repo: _FakeRepo(),
      navigator: nav,
      peerInfoLookup: (_) async => const MeshPeerInfo(),
      selfDevicePk: _peer(0),
      transportLabelForPeer: (_) => null,
    );
    coord.start();
    await coord.placeCall(_peer(7));
    expect(nav.snackbar, contains('Звонок уже идёт'));
    await coord.dispose();
  });

  test('successful invite returns the callId', () async {
    final ctrl = StreamController<CallState>.broadcast();
    final coord = MeshVoiceUiCoordinator(
      stateStream: ctrl.stream,
      invite: (_) async => 0xCAFE,
      accept: () async {},
      reject: () async {},
      hangup: () async {},
      repo: _FakeRepo(),
      navigator: _SpyNavigator(),
      peerInfoLookup: (_) async => const MeshPeerInfo(),
      selfDevicePk: _peer(0),
      transportLabelForPeer: (_) => null,
    );
    coord.start();
    final id = await coord.placeCall(_peer(7));
    expect(id, 0xCAFE);
    await coord.dispose();
  });
});
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/core/voice/mesh_voice_ui_coordinator_test.dart`
Expected: compile error — `placeCall` not defined on coordinator.

- [ ] **Step 3: Implement `placeCall`**

In `lib/core/voice/mesh_voice_ui_coordinator.dart`, add to the class:

```dart
/// Initiate a mesh call to [peer]. Returns the generated call id, or
/// `null` if the call could not be started (loopback, busy, etc.).
Future<int?> placeCall(PeerId peer) async {
  if (_bytesEqual(peer.bytes, selfDevicePk.bytes)) return null;
  try {
    return await invite(peer);
  } on StateError {
    navigator.showSnackbar('Звонок уже идёт');
    return null;
  }
}

static bool _bytesEqual(List<int> a, List<int> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test test/core/voice/mesh_voice_ui_coordinator_test.dart`
Expected: `+10: All tests passed!`

- [ ] **Step 5: Commit**

```bash
git add lib/core/voice/mesh_voice_ui_coordinator.dart \
        test/core/voice/mesh_voice_ui_coordinator_test.dart
git commit -m "feat(mesh-voice/3d.1): coordinator placeCall — loopback guard + StateError snackbar"
```

---

## DI wiring + global integration

### Task 10.5: Public `defaultMeshVoiceAudioEngine` factory

**Files:**
- Create: `lib/core/audio/default_mesh_voice_audio_engine.dart`

The Phase 3a self-test screen wraps `AudioCapture`/`AudioPlayback` in private adapters. To register `MeshVoiceService` in DI we need the same wrapping in a public factory so the same code path can construct an engine for real calls.

- [ ] **Step 1: Create the factory file**

```dart
import 'dart:typed_data';
import 'mesh_voice_audio_engine.dart';
import 'platform/audio_capture.dart';
import 'platform/audio_playback.dart';

class _CaptureAdapter implements AudioCaptureSource {
  final AudioCapture _capture;
  _CaptureAdapter(this._capture);
  @override Stream<Int16List> get frames => _capture.frames;
  @override Future<void> start() => _capture.start();
  @override Future<void> stop() => _capture.stop();
  @override Future<void> setMicEnabled(bool enabled) => _capture.setMicEnabled(enabled);
}

class _PlaybackAdapter implements AudioPlaybackSink {
  final AudioPlayback _playback;
  _PlaybackAdapter(this._playback);
  @override Future<void> start() => _playback.start();
  @override Future<void> stop() => _playback.stop();
  @override Future<void> push(Int16List pcm) => _playback.push(pcm);
}

/// Build a [MeshVoiceAudioEngine] backed by the platform's
/// `AudioCapture` / `AudioPlayback` (Phase 3a). Use this from
/// [MeshVoiceService.audioEngineFactory] in DI so each call gets a
/// fresh engine + microphone session.
MeshVoiceAudioEngine defaultMeshVoiceAudioEngine() {
  return MeshVoiceAudioEngine(
    capture: _CaptureAdapter(AudioCapture()),
    playback: _PlaybackAdapter(AudioPlayback()),
  );
}
```

- [ ] **Step 2: Migrate `mesh_voice_self_test_screen.dart` to use the new factory** (DRY — the private adapters can be removed)

In `lib/features/mesh_debug/presentation/screens/mesh_voice_self_test_screen.dart`, replace the private `_CaptureAdapter` / `_PlaybackAdapter` classes with the import + factory call:

```dart
import '../../../../core/audio/default_mesh_voice_audio_engine.dart';
```

Replace the body of `_startLoopback`:

```dart
Future<void> _startLoopback() async {
  final engine = defaultMeshVoiceAudioEngine();
  _engine = engine;
  _outboundSub = engine.outbound.listen((opusBytes) {
    _seq++;
    engine.inbound(seq: _seq, payload: opusBytes);
    if (mounted && _seq % 50 == 0) setState(() {});
  });
  await engine.start();
  if (mounted) setState(() => _running = true);
}
```

Delete the now-unused `_captureAdapter` / `_playbackAdapter` fields and the `_CaptureAdapter` / `_PlaybackAdapter` classes from the file.

- [ ] **Step 3: Run tests**

Run: `flutter test`
Expected: all tests pass; no regressions.

- [ ] **Step 4: Run analyze**

Run: `flutter analyze`
Expected: `No issues found!`

- [ ] **Step 5: Commit**

```bash
git add lib/core/audio/default_mesh_voice_audio_engine.dart \
        lib/features/mesh_debug/presentation/screens/mesh_voice_self_test_screen.dart
git commit -m "refactor(audio): extract defaultMeshVoiceAudioEngine factory for DI use"
```

---

### Task 11: Register `MeshVoiceService`, repository, coordinator in DI

**Files:**
- Modify: `lib/core/di/service_locator.dart`
- Modify: `lib/main.dart` (only if a Hive openBox call needs to move)

The Coordinator needs a real `MeshNavigator` implementation backed by `globalNavigatorKey`. Provide it inline as a private class in the DI file (small, only one usage).

- [ ] **Step 1: Modify `service_locator.dart`**

At the top of `lib/core/di/service_locator.dart`, add the imports (alphabetical group):

```dart
import 'package:flutter/material.dart';
import '../../features/call_history/data/mesh_call_history_entry.dart';
import '../../features/call_history/data/mesh_call_history_repository.dart';
import '../audio/default_mesh_voice_audio_engine.dart';
import '../mesh/voice/mesh_voice_service.dart';
import '../voice/mesh_voice_ui_coordinator.dart';
import '../../main.dart' show globalNavigatorKey;
```

Inside `setupDependencies()`, after `MessengerCacheService.init();` line and before the `// Mesh static key` block:

```dart
  // Mesh call history (Hive) — local-only journal of mesh voice calls
  final meshCallHistory = HiveMeshCallHistoryRepository();
  await meshCallHistory.init();
  sl.registerSingleton<MeshCallHistoryRepository>(meshCallHistory);
```

After the `MeshMessagingService` registration block (around line 280), add:

```dart
  // MeshVoiceService — Phase 3c orchestrator. start() is called by
  // runMeshBootstrap after MeshMessagingService.start() succeeds.
  sl.registerLazySingleton<MeshVoiceService>(() {
    final messaging = sl<MeshMessagingService>();
    return MeshVoiceService(
      messaging: messaging,
      transport: sl<MeshTransport>(),
      audioEngineFactory: defaultMeshVoiceAudioEngine,
    );
  });

  // MeshVoiceUiCoordinator — the singleton that connects MeshVoiceService
  // state transitions to UI (sheets, screens, history).
  sl.registerLazySingleton<MeshVoiceUiCoordinator>(() {
    final voice = sl<MeshVoiceService>();
    final transport = sl<MeshTransport>();
    final messaging = sl<MeshMessagingService>();
    final keyStore = sl<HiveContactKeyStore>();
    return MeshVoiceUiCoordinator(
      stateStream: voice.stateStream,
      invite: voice.invite,
      accept: voice.accept,
      reject: voice.reject,
      hangup: () => voice.hangup(),
      repo: sl<MeshCallHistoryRepository>(),
      navigator: _GlobalKeyMeshNavigator(),
      peerInfoLookup: (peer) async => _resolvePeerInfo(
        devicePk: peer,
        keyStore: keyStore,
      ),
      selfDevicePk: PeerId(messaging.myDevicePublicKey),
      transportLabelForPeer: (peer) {
        // Phase 3d.2 will surface this from MeshTransport.peerStatus +
        // discovery attributes. Phase 3d.1 returns null (badge says
        // just "📡 Mesh"). This is intentional — see spec Risks #4.
        return null;
      },
    );
  });
```

At the bottom of `service_locator.dart`, before the closing brace, add the helper class:

```dart
class _GlobalKeyMeshNavigator implements MeshNavigator {
  @override
  Future<T?> pushScreen<T>(Widget screen) async {
    final ctx = globalNavigatorKey.currentContext;
    if (ctx == null) return null;
    return Navigator.of(ctx).push<T>(MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Future<void> showSheet(Widget sheet) async {
    final ctx = globalNavigatorKey.currentContext;
    if (ctx == null) return;
    await showModalBottomSheet<void>(
      context: ctx,
      isDismissible: false,
      enableDrag: false,
      builder: (_) => sheet,
    );
  }

  @override
  void popSheet() {
    final ctx = globalNavigatorKey.currentContext;
    if (ctx == null) return;
    final nav = Navigator.of(ctx);
    if (nav.canPop()) nav.pop();
  }

  @override
  void popScreen() {
    final ctx = globalNavigatorKey.currentContext;
    if (ctx == null) return;
    final nav = Navigator.of(ctx);
    if (nav.canPop()) nav.pop();
  }

  @override
  void showSnackbar(String message) {
    final ctx = globalNavigatorKey.currentContext;
    if (ctx == null) return;
    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(message)));
  }
}

Future<MeshPeerInfo> _resolvePeerInfo({
  required PeerId devicePk,
  required HiveContactKeyStore keyStore,
}) async {
  // Phase 1a: userPk == devicePk. Resolve userId by scanning Hive
  // contactUserId mappings (helper already exists below as
  // _contactUserIdByUserPk — but only at file scope; inline its logic).
  String? userId;
  try {
    final hex = devicePk.toHex();
    for (final entry in keyStore.allUserIdMappings()) {
      if (entry.$2.toHex() == hex) {
        userId = entry.$1;
        break;
      }
    }
  } catch (_) {}
  if (userId == null) return const MeshPeerInfo();
  // Resolve name + avatar from MessengerBloc.state.conversations.
  String? name;
  String? avatar;
  try {
    final convs = sl<MessengerBloc>().state.conversations;
    for (final c in convs) {
      if (c.type == 'DIRECT' && c.otherUserId == userId) {
        name = c.otherUserName;
        avatar = c.otherUserAvatar;
        break;
      }
    }
  } catch (_) {}
  return MeshPeerInfo(userId: userId, name: name, avatarUrl: avatar);
}
```

- [ ] **Step 2: Wire `coordinator.start()` into `runMeshBootstrap`**

In `lib/core/mesh/mesh_bootstrap.dart`, inside `runMeshBootstrap`, after the `MeshMessagingService.start()` block, add:

```dart
    if (sl.isRegistered<MeshVoiceService>()) {
      try {
        sl<MeshVoiceService>().start();
        debugPrint('[mesh-boot] MeshVoiceService.start() ok');
      } catch (e) {
        debugPrint('[mesh-boot] MeshVoiceService.start() failed: $e');
      }
    }
    if (sl.isRegistered<MeshVoiceUiCoordinator>()) {
      try {
        sl<MeshVoiceUiCoordinator>().start();
        debugPrint('[mesh-boot] MeshVoiceUiCoordinator.start() ok');
      } catch (e) {
        debugPrint('[mesh-boot] MeshVoiceUiCoordinator.start() failed: $e');
      }
    }
```

Also import the new types at the top of `mesh_bootstrap.dart`:

```dart
import 'voice/mesh_voice_service.dart';
import '../voice/mesh_voice_ui_coordinator.dart';
```

- [ ] **Step 3: Run all tests to verify nothing regressed**

Run: `flutter test`
Expected: all tests pass; no compile errors. The DI wiring is exercised only in app boot, not in unit tests, so no test addition is needed here. **If any pre-existing test fails because it depends on `setupDependencies` partially**, file an issue — but typical tests stub `sl` directly.

- [ ] **Step 4: Run `flutter analyze`**

Run: `flutter analyze`
Expected: `No issues found!` (or only pre-existing warnings).

- [ ] **Step 5: Commit**

```bash
git add lib/core/di/service_locator.dart lib/core/mesh/mesh_bootstrap.dart
git commit -m "feat(mesh-voice/3d.1): DI wiring — register MeshVoiceService, repo, coordinator + bootstrap"
```

---

### Task 12: `MeshDebugScreen` — "Place mesh call" button per peer

**Files:**
- Modify: `lib/features/mesh_debug/presentation/screens/mesh_debug_screen.dart`

This is the **sole** entry point for placing calls in 3d.1. Replaced by chat-header button in 3d.2.

- [ ] **Step 1: Locate `_PeerTile` and add `onPlaceCall` parameter**

In `lib/features/mesh_debug/presentation/screens/mesh_debug_screen.dart`, find class `_PeerTile` (around line 393). Modify its constructor and `build` method:

```dart
class _PeerTile extends StatelessWidget {
  final _PeerEntry entry;
  final VoidCallback? onSendTest;
  final VoidCallback? onPlaceCall;
  const _PeerTile({
    required this.entry,
    required this.onSendTest,
    required this.onPlaceCall,
  });

  @override
  Widget build(BuildContext context) {
    final blePrefix = entry.attributes['ble_prefix'];
    final transport = blePrefix != null ? 'BLE' : 'Bonjour';
    final prefix = entry.peerId.toHex().substring(0, 16);
    return Card(
      child: ListTile(
        dense: true,
        leading: CircleAvatar(
          radius: 14,
          backgroundColor: transport == 'BLE' ? Colors.blue : Colors.orange,
          child: Text(
            transport == 'BLE' ? 'B' : 'W',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
        title: Text(prefix,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 13)),
        subtitle: Text(
          '$transport  ·  ${entry.host}:${entry.port}',
          style: const TextStyle(fontSize: 11),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (onPlaceCall != null)
              IconButton(
                tooltip: 'Place mesh call',
                icon: const Icon(Icons.call, color: Colors.green),
                onPressed: onPlaceCall,
              ),
            if (onSendTest != null)
              TextButton(
                onPressed: onSendTest,
                child: const Text('Send test'),
              )
            else
              const Text(
                'no pk',
                style: TextStyle(fontSize: 10, color: Colors.grey),
              ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Wire the callback at the call site**

Find where `_PeerTile` is instantiated (around line 269) and modify:

```dart
              ..._peers.values.map((p) => _PeerTile(
                    entry: p,
                    onSendTest: p.canMessage ? () => _sendTestMessage(p.peerId) : null,
                    onPlaceCall: p.canMessage ? () => _placeMeshCall(p.peerId) : null,
                  )),
```

Add the `_placeMeshCall` method to `_MeshDebugScreenState` (around line 27-200, anywhere near `_sendTestMessage`):

```dart
Future<void> _placeMeshCall(PeerId peerId) async {
  try {
    final coord = sl<MeshVoiceUiCoordinator>();
    final id = await coord.placeCall(peerId);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(id == null
            ? 'Call not started (loopback or busy)'
            : 'Calling… (call_id=0x${id.toRadixString(16)})'),
        duration: const Duration(seconds: 2),
      ));
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Place call error: $e'),
        backgroundColor: Colors.red,
      ));
    }
  }
}
```

Add the import at the top of the file:

```dart
import '../../../../core/di/service_locator.dart';
import '../../../../core/voice/mesh_voice_ui_coordinator.dart';
```

- [ ] **Step 3: Run analyze**

Run: `flutter analyze lib/features/mesh_debug/`
Expected: `No issues found!`

- [ ] **Step 4: Manual smoke build**

Run (replace device id):
```bash
flutter run --release --flavor dev -t lib/main_dev.dart \
  --dart-define=FLAVOR=dev \
  --dart-define=BASE_URL=https://staging.id.taler.tirol \
  -d <android-device-id>
```
Expected: app launches, in `MeshDebugScreen` each discovered peer row shows a green phone icon. Tapping shows snackbar `Calling… (call_id=0x...)`.

- [ ] **Step 5: Commit**

```bash
git add lib/features/mesh_debug/presentation/screens/mesh_debug_screen.dart
git commit -m "feat(mesh-voice/3d.1): MeshDebugScreen — per-peer 'Place mesh call' button (debug-only)"
```

---

## Integration test

### Task 13: End-to-end coordinator test with fake transport pair

**Files:**
- Create: `test/core/voice/mesh_voice_integration_test.dart`

This test wires two coordinators to two real `MeshVoiceService` instances over an in-memory fake messaging service (Phase 3c test utils). It does NOT exercise audio engines or Bonjour — just verifies the signaling + UI navigation + history pipeline.

- [ ] **Step 1: Write the failing test**

Create `test/core/voice/mesh_voice_integration_test.dart`:

```dart
import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taler_id_mobile/core/audio/mesh_voice_audio_engine.dart';
import 'package:taler_id_mobile/core/mesh/services/envelope.dart';
import 'package:taler_id_mobile/core/mesh/services/mesh_messaging_service.dart';
import 'package:taler_id_mobile/core/mesh/transport/peer_id.dart';
import 'package:taler_id_mobile/core/mesh/voice/mesh_voice_service.dart';
import 'package:taler_id_mobile/core/voice/mesh_voice_ui_coordinator.dart';
import 'package:taler_id_mobile/features/call_history/data/mesh_call_history_entry.dart';
import 'package:taler_id_mobile/features/call_history/data/mesh_call_history_repository.dart';

import '../../mesh/voice/mesh_voice_service_test_utils.dart';

class _NoopRepo implements MeshCallHistoryRepository {
  final entries = <MeshCallHistoryEntry>[];
  @override Future<void> add(MeshCallHistoryEntry e) async => entries.add(e);
  @override Future<void> deleteById(int callId) async {}
  @override Future<List<MeshCallHistoryEntry>> getAll() async =>
      List.of(entries);
  @override Stream<List<MeshCallHistoryEntry>> watch() =>
      const Stream.empty();
}

class _NoopNav implements MeshNavigator {
  @override Future<T?> pushScreen<T>(Widget s) async => null;
  @override Future<void> showSheet(Widget s) async {}
  @override void popSheet() {}
  @override void popScreen() {}
  @override void showSnackbar(String m) {}
}

PeerId _peer(int seed) =>
    PeerId(Uint8List.fromList(List<int>.generate(32, (i) => i + seed)));

void main() {
  test('full flow: invite → accept → ACTIVE → hangup → history written on both sides',
      () async {
    // Two harnesses share a single inbound stream (each sees the other's
    // outbound envelopes). FakeMessagingService doesn't route by recipient,
    // but both services subscribe to the same controller — sufficient to
    // exercise the coordinator.
    final aliceHarness = MeshVoiceTestHarness.build();
    final bobHarness = MeshVoiceTestHarness.build();

    aliceHarness.svc.start();
    bobHarness.svc.start();

    // Bridge alice → bob and bob → alice via reflecting sentEnvelopes.
    void aliceSend({required PeerId toUserPk, required Envelope envelope}) {
      bobHarness.fakeMessaging.emitInbound(InboundEnvelope(
        fromUserPk: _peer(1), envelope: envelope));
    }
    void bobSend({required PeerId toUserPk, required Envelope envelope}) {
      aliceHarness.fakeMessaging.emitInbound(InboundEnvelope(
        fromUserPk: _peer(2), envelope: envelope));
    }
    // Patch sendEnvelope by intercepting via a wrapper: we override
    // FakeMessagingService.sendEnvelope here at the test level by
    // periodically draining sentEnvelopes (simulates a delivery loop).
    Timer.periodic(const Duration(milliseconds: 5), (t) {
      if (t.tick > 200) { t.cancel(); return; }
      while (aliceHarness.fakeMessaging.sentEnvelopes.isNotEmpty) {
        final e = aliceHarness.fakeMessaging.sentEnvelopes.removeAt(0);
        aliceSend(toUserPk: e.toUserPk, envelope: e.envelope);
      }
      while (bobHarness.fakeMessaging.sentEnvelopes.isNotEmpty) {
        final e = bobHarness.fakeMessaging.sentEnvelopes.removeAt(0);
        bobSend(toUserPk: e.toUserPk, envelope: e.envelope);
      }
    });

    final aliceRepo = _NoopRepo();
    final bobRepo = _NoopRepo();
    final aliceCoord = MeshVoiceUiCoordinator(
      stateStream: aliceHarness.svc.stateStream,
      invite: aliceHarness.svc.invite,
      accept: aliceHarness.svc.accept,
      reject: aliceHarness.svc.reject,
      hangup: () => aliceHarness.svc.hangup(),
      repo: aliceRepo,
      navigator: _NoopNav(),
      peerInfoLookup: (_) async => const MeshPeerInfo(name: 'Bob'),
      selfDevicePk: _peer(1),
      transportLabelForPeer: (_) => 'Bonjour',
    );
    final bobCoord = MeshVoiceUiCoordinator(
      stateStream: bobHarness.svc.stateStream,
      invite: bobHarness.svc.invite,
      accept: bobHarness.svc.accept,
      reject: bobHarness.svc.reject,
      hangup: () => bobHarness.svc.hangup(),
      repo: bobRepo,
      navigator: _NoopNav(),
      peerInfoLookup: (_) async => const MeshPeerInfo(name: 'Alice'),
      selfDevicePk: _peer(2),
      transportLabelForPeer: (_) => 'Bonjour',
    );
    aliceCoord.start();
    bobCoord.start();

    // Alice places a call to Bob.
    final callId = await aliceCoord.placeCall(_peer(2));
    expect(callId, isNotNull);

    // Wait for handshake propagation.
    await Future<void>.delayed(const Duration(milliseconds: 50));
    // Bob should now be in IncomingState; accept.
    expect(bobHarness.svc.state, isA<IncomingState>());
    await bobHarness.svc.accept();
    await Future<void>.delayed(const Duration(milliseconds: 50));

    // Both should be in ActiveState.
    expect(aliceHarness.svc.state, isA<ActiveState>());
    expect(bobHarness.svc.state, isA<ActiveState>());

    // Alice hangs up.
    await aliceCoord.dispose(); // stops listening but service still emits
    await aliceHarness.svc.hangup();
    await Future<void>.delayed(const Duration(milliseconds: 50));

    // Bob's coordinator should observe call_end → EndedState → write history.
    expect(bobRepo.entries, hasLength(1));
    expect(bobRepo.entries.single.endReason, 'remoteHangup');

    await bobCoord.dispose();
  });
}
```

- [ ] **Step 2: Run test to verify it passes**

Run: `flutter test test/core/voice/mesh_voice_integration_test.dart`
Expected: `+1: All tests passed!`

If the test is flaky due to timing, increase the inter-step `Future.delayed` durations to `100 ms`.

- [ ] **Step 3: Run full test suite**

Run: `flutter test`
Expected: all tests pass (count: 486 baseline + 28 new tests across Tasks 1–13 = ~514, give or take a few subtests).

- [ ] **Step 4: Run `flutter analyze`**

Run: `flutter analyze`
Expected: `No issues found!`

- [ ] **Step 5: Commit**

```bash
git add test/core/voice/mesh_voice_integration_test.dart
git commit -m "test(mesh-voice/3d.1): integration test — full caller↔callee flow with two coordinators"
```

---

## Hardware smoke + PR

### Task 14: Hardware smoke checklist (manual)

**Files:**
- (No file changes — this task is run manually on two devices)

- [ ] **Step 1: Build local APK for Android target**

```bash
cd ~/Downloads/taler_id_mobile
flutter run --release --flavor dev -t lib/main_dev.dart \
  --dart-define=FLAVOR=dev \
  --dart-define=BASE_URL=https://staging.id.taler.tirol \
  -d 78c0742f
```
Expected: app installs and launches on Redmi.

- [ ] **Step 2: Build & install on iPhone**

```bash
flutter run --release --flavor dev -t lib/main_dev.dart \
  --dart-define=FLAVOR=dev \
  --dart-define=BASE_URL=https://staging.id.taler.tirol \
  -d 00008101-000E21100202001E
```
Expected: app installs and launches on iPhone.

- [ ] **Step 3: Verify mesh discovery on both**

On both devices: open Settings → "Mesh debug". Confirm: each device sees the other in the Peers list (Bonjour or BLE), `canMessage` is true (green phone icon visible).

- [ ] **Step 4: Place and answer a call (Android → iPhone)**

On Android: tap the green phone icon next to the iPhone peer. Expected: snackbar shows `Calling… (call_id=0x…)`.
On iPhone: a modal sheet appears at the bottom with "📡 Входящий mesh-звонок" + Accept/Decline buttons.
On iPhone: tap Accept. Expected: sheet dismisses, `MeshVoiceCallScreen` slides up showing avatar + "Alice" (or hex fallback) + timer counting up + transport badge.
On Android: same screen appears immediately on Active.

- [ ] **Step 5: Verify hangup and history write**

After ≥10 seconds: tap red hangup on either device.
Expected:
- Both screens show "Звонок завершён" / "Завершён собеседником" briefly (1.5 s) then close.
- `flutter logs` (on the wired device) shows `[mesh-call-history]` write debug lines (if you added any during dev) or you can verify by re-opening the app and checking that DI startup logs show successful repo init.

- [ ] **Step 6: Verify history persistence**

Force-quit and re-launch the app on either device. Re-open `MeshDebugScreen`. (The `mesh_call_history` Hive box has no UI in 3d.1 — it's checked via debugger/logs. To prove persistence, run a quick repl-style verification by adding a temporary debugPrint of `await sl<MeshCallHistoryRepository>().getAll()` somewhere visible, then remove before commit.)

- [ ] **Step 7: Reverse roles (iPhone → Android)**

On iPhone: tap the green phone icon next to the Android peer. Repeat steps 4-5.

- [ ] **Step 8: iOS background-drop test**

Start a call from Android → iPhone. Once Active: lock the iPhone screen and wait 35 s.
Expected on Android: `MeshVoiceCallScreen` shows "Соединение потеряно" then closes after 1.5 s.
Expected on iPhone: on next foreground, the call screen briefly shows "Соединение потеряно" then closes.

- [ ] **Step 9: Cleanup any test debug prints**

```bash
git diff --stat
# If any temporary debugPrints were added during smoke verification, remove them.
git status
```

---

### Task 15: Open PR

**Files:**
- (no file changes)

- [ ] **Step 1: Push branch**

```bash
git push origin feature/mesh-voice-call-phase3d.1
```

- [ ] **Step 2: Open PR via gh CLI**

```bash
gh pr create --title "feat(mesh-voice/3d.1): UI integration — coordinator + screen + sheet + history" \
  --body "$(cat <<'EOF'
## Summary

Phase 3d.1 of the mesh voice call feature: makes calls work end-to-end through the UI.

- New `MeshVoiceUiCoordinator` (singleton) bridges `MeshVoiceService.stateStream` → navigation + Hive history writes.
- New `MeshVoiceCallScreen` — minimal active-call UI (avatar/name/timer/mute/hangup/transport-badge), no LiveKit deps.
- New `MeshIncomingCallSheet` — modal sheet with 30 s auto-decline.
- New `mesh_call_history` Hive box (JSON storage, matches `messenger_cache_service` pattern — no type adapter).
- DI: registered `MeshVoiceService` + repository + coordinator; `coordinator.start()` wired into `runMeshBootstrap`.
- `MeshDebugScreen` gains a per-peer "Place call" button (debug-only entry point — replaced by chat-header button in 3d.2).

Architectural decision: separate `MeshVoiceCallScreen` rather than extending the 5280-line `voice_call_screen.dart` (LiveKit-coupled). Coordinator owns all UI control flow, keeps Flutter coupling concentrated.

## Spec / plan

- Spec: `docs/superpowers/specs/2026-04-29-mesh-voice-call-phase3d1-design.md`
- Plan: `docs/superpowers/plans/2026-04-29-mesh-voice-call-phase3d1-ui.md`

## Test plan

- [x] Unit tests: model serialization, repository CRUD + watch, coordinator state transitions (10 scenarios)
- [x] Widget tests: `MeshVoiceCallScreen` (6 scenarios) + `MeshIncomingCallSheet` (5 scenarios)
- [x] Integration test: two-coordinator end-to-end flow with fake transport pair
- [x] All baseline tests still pass
- [x] `flutter analyze` clean
- [ ] Hardware smoke on Redmi 78c0742f + iPhone 00008101 (see Task 14 in plan)

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"
```

- [ ] **Step 2: Confirm CI green** (if CI exists; otherwise skip)

- [ ] **Step 3: Notify reviewer + merge after approval**

---

## Done criteria

When all 15 tasks are checked off:

1. Phase 3d.1 branch is pushed, PR is open.
2. Hardware smoke completed on both devices.
3. All ~514 unit + widget + integration tests green.
4. `flutter analyze` clean.

After merge into `dev`, branch `feature/mesh-voice-call-phase3d.2` from `dev` for the next phase (chat integration + history merge + Android bg notification + iOS onboarding tooltip + LiveKit conflict toast).

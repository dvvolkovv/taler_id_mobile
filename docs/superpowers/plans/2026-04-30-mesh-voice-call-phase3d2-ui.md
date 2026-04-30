# Mesh Voice Call Phase 3d.2 — Chat Integration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make mesh calls placeable from chat-header (auto-pick mesh-first, long-press for transport popup), surface eligibility dot when peer is reachable, merge mesh-call history with the existing CallHistoryScreen, and add iOS background-suspend onboarding tooltip + LiveKit-conflict toast.

**Architecture:** A new singleton `MeshPeerEligibilityWatcher` subscribes once to `MeshTransport.discoveries`/`losses` and exposes per-userId online state. `MeshEligibilityDot` widget consumes the watcher. `chat_room_screen.dart` adds an auto-pick decision tree on top of the existing phone IconButton. `CallHistoryScreen` merges `MeshCallHistoryRepository.watch()` with server fetch, sorted globally. iOS onboarding tooltip persists a one-shot bool in a new tiny `mesh_prefs` Hive box.

**Tech Stack:** Flutter 3.38, Dart 3.6, hive_flutter, get_it, existing mesh stack (Phases 1–3d.1).

**Spec:** [docs/superpowers/specs/2026-04-30-mesh-voice-call-phase3d2-design.md](../specs/2026-04-30-mesh-voice-call-phase3d2-design.md)

---

## Pre-flight

### Task 0: Branch + clean baseline

**Files:** working tree only.

- [ ] **Step 1: Create feature branch from `dev`**

```bash
cd ~/Downloads/taler_id_mobile
git fetch origin
git checkout -b feature/mesh-voice-call-phase3d.2 origin/dev
```

Expected: `Switched to a new branch 'feature/mesh-voice-call-phase3d.2'`. Tip should be at `feed258` (Phase 3d.2 spec) or later.

- [ ] **Step 2: Verify baseline tests pass**

Run: `flutter test`
Expected: 516+ pass, 0 fail.

- [ ] **Step 3: Verify analyze clean**

Run: `flutter analyze`
Expected: 282 pre-existing infos/warnings, 0 errors.

---

## Foundation

### Task 1: `MeshPeerEligibilityWatcher` + tests

**Files:**
- Create: `lib/core/voice/mesh_peer_eligibility_watcher.dart`
- Test: `test/core/voice/mesh_peer_eligibility_watcher_test.dart`

The watcher exposes per-userId online state by aggregating discovery/loss events through the contact key store's `(devicePk → userPk → userId)` resolver.

- [ ] **Step 1: Write failing tests**

Create `test/core/voice/mesh_peer_eligibility_watcher_test.dart`:

```dart
import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:taler_id_mobile/core/mesh/transport/mesh_transport.dart';
import 'package:taler_id_mobile/core/mesh/transport/peer_id.dart';
import 'package:taler_id_mobile/core/voice/mesh_peer_eligibility_watcher.dart';

class _FakeTransport implements MeshTransport {
  final _disc = StreamController<PeerDiscovered>.broadcast();
  final _loss = StreamController<PeerLost>.broadcast();
  @override Stream<PeerDiscovered> get discoveries => _disc.stream;
  @override Stream<PeerLost> get losses => _loss.stream;
  @override Stream<InboundFrame> get inbound => const Stream.empty();
  @override Stream<InboundDatagram> get inboundDatagrams => const Stream.empty();
  @override Future<void> startAdvertising(DeviceInfo self) async {}
  @override Future<void> stopAdvertising() async {}
  @override Future<void> connectTo(PeerId peer) async {}
  @override Future<void> send(PeerId peer, Uint8List data) async {}
  @override Future<void> sendDatagram(PeerId peer, Uint8List data) async {}
  @override PeerStatus peerStatus(PeerId peer) => PeerStatus.unknown;
  @override Future<void> dispose() async {}
}

class _FakeContactStore implements ContactKeyStoreLookup {
  final Map<PeerId, PeerId> deviceToUser; // devicePk → userPk
  final Map<String, PeerId> userIdToUserPk;
  _FakeContactStore({required this.deviceToUser, required this.userIdToUserPk});

  @override
  PeerId? lookupUserByDevice(PeerId devicePk) => deviceToUser[devicePk];

  @override
  Iterable<(String, PeerId)> allUserIdMappings() sync* {
    for (final e in userIdToUserPk.entries) yield (e.key, e.value);
  }
}

PeerId _device(int seed) =>
    PeerId(Uint8List.fromList(List<int>.generate(32, (i) => seed + i)));

void main() {
  late _FakeTransport transport;
  late _FakeContactStore store;
  late MeshPeerEligibilityWatcher watcher;

  final aliceUserPk = _device(10);
  final aliceDevice1 = _device(20);
  final aliceDevice2 = _device(30);

  setUp(() {
    transport = _FakeTransport();
    store = _FakeContactStore(
      deviceToUser: {
        aliceDevice1: aliceUserPk,
        aliceDevice2: aliceUserPk,
      },
      userIdToUserPk: {'alice-user-id': aliceUserPk},
    );
    watcher = MeshPeerEligibilityWatcher(transport: transport, contactKeyStore: store);
  });

  tearDown(() async => watcher.dispose());

  group('MeshPeerEligibilityWatcher', () {
    test('isUserOnline returns false before any discovery', () {
      watcher.start();
      expect(watcher.isUserOnline('alice-user-id'), isFalse);
    });

    test('isUserOnline returns true after PeerDiscovered for owned device', () async {
      watcher.start();
      transport._disc.add(PeerDiscovered(peerId: aliceDevice1, host: 'h', port: 1, attributes: {}));
      await Future<void>.delayed(Duration.zero);
      expect(watcher.isUserOnline('alice-user-id'), isTrue);
    });

    test('isUserOnline returns false after all owned devices are PeerLost', () async {
      watcher.start();
      transport._disc.add(PeerDiscovered(peerId: aliceDevice1, host: 'h', port: 1, attributes: {}));
      await Future<void>.delayed(Duration.zero);
      transport._loss.add(PeerLost(aliceDevice1));
      await Future<void>.delayed(Duration.zero);
      expect(watcher.isUserOnline('alice-user-id'), isFalse);
    });

    test('isUserOnline stays true when one of two devices is lost', () async {
      watcher.start();
      transport._disc.add(PeerDiscovered(peerId: aliceDevice1, host: 'h', port: 1, attributes: {}));
      transport._disc.add(PeerDiscovered(peerId: aliceDevice2, host: 'h', port: 1, attributes: {}));
      await Future<void>.delayed(Duration.zero);
      transport._loss.add(PeerLost(aliceDevice1));
      await Future<void>.delayed(Duration.zero);
      expect(watcher.isUserOnline('alice-user-id'), isTrue);
    });

    test('userChanges emits only on first-add and last-remove', () async {
      watcher.start();
      final emissions = <(String, bool)>[];
      final sub = watcher.userChanges.listen((e) => emissions.add((e.userId, e.isOnline)));
      transport._disc.add(PeerDiscovered(peerId: aliceDevice1, host: 'h', port: 1, attributes: {}));
      await Future<void>.delayed(Duration.zero);
      transport._disc.add(PeerDiscovered(peerId: aliceDevice2, host: 'h', port: 1, attributes: {}));
      await Future<void>.delayed(Duration.zero);
      transport._loss.add(PeerLost(aliceDevice1));
      await Future<void>.delayed(Duration.zero);
      transport._loss.add(PeerLost(aliceDevice2));
      await Future<void>.delayed(Duration.zero);
      await sub.cancel();
      expect(emissions, [
        ('alice-user-id', true),  // first add
        ('alice-user-id', false), // last remove
      ]);
    });

    test('PeerDiscovered with unknown device is ignored', () async {
      watcher.start();
      final unknownDevice = _device(99);
      transport._disc.add(PeerDiscovered(peerId: unknownDevice, host: 'h', port: 1, attributes: {}));
      await Future<void>.delayed(Duration.zero);
      expect(watcher.isUserOnline('alice-user-id'), isFalse);
    });

    test('isUserOnline returns false when ContactKeyStore has no userId mapping', () async {
      watcher.start();
      // Simulate: device known, but userId mapping not yet in store.
      store.userIdToUserPk.clear();
      transport._disc.add(PeerDiscovered(peerId: aliceDevice1, host: 'h', port: 1, attributes: {}));
      await Future<void>.delayed(Duration.zero);
      expect(watcher.isUserOnline('alice-user-id'), isFalse);
    });

    test('dispose() cancels subscriptions', () async {
      watcher.start();
      await watcher.dispose();
      expect(transport._disc.hasListener, isFalse);
      expect(transport._loss.hasListener, isFalse);
    });
  });
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/core/voice/mesh_peer_eligibility_watcher_test.dart`
Expected: compile error — `MeshPeerEligibilityWatcher` and `ContactKeyStoreLookup` not defined.

- [ ] **Step 3: Implement the watcher**

Create `lib/core/voice/mesh_peer_eligibility_watcher.dart`:

```dart
import 'dart:async';

import '../mesh/transport/mesh_transport.dart';
import '../mesh/transport/peer_id.dart';

/// Minimal interface needed by the watcher. HiveContactKeyStore implements it.
/// Defining as an abstract here lets unit tests inject a fake without pulling
/// the full Hive store + path_provider dependency.
abstract class ContactKeyStoreLookup {
  PeerId? lookupUserByDevice(PeerId devicePk);
  Iterable<(String, PeerId)> allUserIdMappings();
}

/// Tracks per-userId online state derived from MeshTransport discovery events
/// + ContactKeyStore mappings. A userId is "online" iff at least one of its
/// known devicePks has been discovered (and not yet lost).
///
/// Singleton wired in setupDependencies and started in runMeshBootstrap.
class MeshPeerEligibilityWatcher {
  final MeshTransport transport;
  final ContactKeyStoreLookup contactKeyStore;

  StreamSubscription<PeerDiscovered>? _discSub;
  StreamSubscription<PeerLost>? _lossSub;
  final Map<String, Set<PeerId>> _onlineDevices = {};
  final _changesCtrl =
      StreamController<({String userId, bool isOnline})>.broadcast();

  MeshPeerEligibilityWatcher({
    required this.transport,
    required this.contactKeyStore,
  });

  Stream<({String userId, bool isOnline})> get userChanges =>
      _changesCtrl.stream;

  void start() {
    _discSub ??= transport.discoveries.listen(_onDiscovered);
    _lossSub ??= transport.losses.listen(_onLost);
  }

  Future<void> dispose() async {
    await _discSub?.cancel();
    await _lossSub?.cancel();
    _discSub = null;
    _lossSub = null;
    if (!_changesCtrl.isClosed) await _changesCtrl.close();
    _onlineDevices.clear();
  }

  bool isUserOnline(String userId) =>
      _onlineDevices[userId]?.isNotEmpty ?? false;

  String? _userIdForDevice(PeerId devicePk) {
    final userPk = contactKeyStore.lookupUserByDevice(devicePk);
    if (userPk == null) return null;
    final userPkHex = userPk.toHex();
    for (final (userId, mappedUserPk) in contactKeyStore.allUserIdMappings()) {
      if (mappedUserPk.toHex() == userPkHex) return userId;
    }
    return null;
  }

  void _onDiscovered(PeerDiscovered event) {
    final userId = _userIdForDevice(event.peerId);
    if (userId == null) return;
    final set = _onlineDevices.putIfAbsent(userId, () => <PeerId>{});
    final wasEmpty = set.isEmpty;
    set.add(event.peerId);
    if (wasEmpty && !_changesCtrl.isClosed) {
      _changesCtrl.add((userId: userId, isOnline: true));
    }
  }

  void _onLost(PeerLost event) {
    String? hitUserId;
    for (final entry in _onlineDevices.entries) {
      if (entry.value.contains(event.peerId)) {
        hitUserId = entry.key;
        break;
      }
    }
    if (hitUserId == null) return;
    final set = _onlineDevices[hitUserId]!;
    set.remove(event.peerId);
    if (set.isEmpty) {
      _onlineDevices.remove(hitUserId);
      if (!_changesCtrl.isClosed) {
        _changesCtrl.add((userId: hitUserId, isOnline: false));
      }
    }
  }
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test test/core/voice/mesh_peer_eligibility_watcher_test.dart`
Expected: `+8: All tests passed!`

- [ ] **Step 5: Commit**

```bash
git add lib/core/voice/mesh_peer_eligibility_watcher.dart \
        test/core/voice/mesh_peer_eligibility_watcher_test.dart
git commit -m "feat(mesh-voice/3d.2): MeshPeerEligibilityWatcher — per-userId online state"
```

---

### Task 2: `MeshEligibilityDot` widget + tests

**Files:**
- Create: `lib/features/voice/presentation/widgets/mesh_eligibility_dot.dart`
- Test: `test/features/voice/presentation/widgets/mesh_eligibility_dot_test.dart`

A small reactive widget that subscribes to the watcher and renders a 6px green circle when its `userId` is online, or `SizedBox.shrink()` otherwise.

- [ ] **Step 1: Write failing tests**

Create `test/features/voice/presentation/widgets/mesh_eligibility_dot_test.dart`:

```dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:taler_id_mobile/core/voice/mesh_peer_eligibility_watcher.dart';
import 'package:taler_id_mobile/features/voice/presentation/widgets/mesh_eligibility_dot.dart';

class _FakeWatcher implements MeshPeerEligibilityWatcher {
  bool initial = false;
  final _ctrl = StreamController<({String userId, bool isOnline})>.broadcast();
  void emit(String userId, bool isOnline) =>
      _ctrl.add((userId: userId, isOnline: isOnline));

  @override Stream<({String userId, bool isOnline})> get userChanges => _ctrl.stream;
  @override bool isUserOnline(String userId) => initial;
  @override void start() {}
  @override Future<void> dispose() async => _ctrl.close();
  @override
  noSuchMethod(Invocation i) => throw UnimplementedError(i.memberName.toString());
}

void main() {
  late _FakeWatcher fake;

  setUp(() {
    fake = _FakeWatcher();
    GetIt.I.registerSingleton<MeshPeerEligibilityWatcher>(fake);
  });

  tearDown(() async {
    await fake.dispose();
    await GetIt.I.unregister<MeshPeerEligibilityWatcher>();
  });

  group('MeshEligibilityDot', () {
    testWidgets('renders SizedBox.shrink when offline', (tester) async {
      fake.initial = false;
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: MeshEligibilityDot(userId: 'u1')),
      ));
      // The dot Container has key 'mesh-eligibility-dot' when visible.
      expect(find.byKey(const Key('mesh-eligibility-dot')), findsNothing);
    });

    testWidgets('renders dot when initially online', (tester) async {
      fake.initial = true;
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: MeshEligibilityDot(userId: 'u1')),
      ));
      expect(find.byKey(const Key('mesh-eligibility-dot')), findsOneWidget);
    });

    testWidgets('updates render when watcher emits change', (tester) async {
      fake.initial = false;
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: MeshEligibilityDot(userId: 'u1')),
      ));
      expect(find.byKey(const Key('mesh-eligibility-dot')), findsNothing);
      fake.emit('u1', true);
      await tester.pump();
      expect(find.byKey(const Key('mesh-eligibility-dot')), findsOneWidget);
      fake.emit('u1', false);
      await tester.pump();
      expect(find.byKey(const Key('mesh-eligibility-dot')), findsNothing);
    });

    testWidgets('ignores changes for other userIds', (tester) async {
      fake.initial = false;
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: MeshEligibilityDot(userId: 'u1')),
      ));
      fake.emit('u2', true);
      await tester.pump();
      expect(find.byKey(const Key('mesh-eligibility-dot')), findsNothing);
    });
  });
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/features/voice/presentation/widgets/mesh_eligibility_dot_test.dart`
Expected: compile error — `MeshEligibilityDot` not defined.

- [ ] **Step 3: Implement the widget**

Create `lib/features/voice/presentation/widgets/mesh_eligibility_dot.dart`:

```dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../../../../core/voice/mesh_peer_eligibility_watcher.dart';

class MeshEligibilityDot extends StatefulWidget {
  final String userId;
  final Color color;
  final double size;

  const MeshEligibilityDot({
    super.key,
    required this.userId,
    this.color = const Color(0xFF4CAF50),
    this.size = 6.0,
  });

  @override
  State<MeshEligibilityDot> createState() => _MeshEligibilityDotState();
}

class _MeshEligibilityDotState extends State<MeshEligibilityDot> {
  StreamSubscription<({String userId, bool isOnline})>? _sub;
  bool _isOnline = false;

  @override
  void initState() {
    super.initState();
    final watcher = GetIt.I<MeshPeerEligibilityWatcher>();
    _isOnline = watcher.isUserOnline(widget.userId);
    _sub = watcher.userChanges
        .where((e) => e.userId == widget.userId)
        .listen((e) {
      if (!mounted) return;
      setState(() => _isOnline = e.isOnline);
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isOnline) return const SizedBox.shrink();
    return Container(
      key: const Key('mesh-eligibility-dot'),
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: widget.color,
      ),
    );
  }
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test test/features/voice/presentation/widgets/mesh_eligibility_dot_test.dart`
Expected: `+4: All tests passed!`

- [ ] **Step 5: Commit**

```bash
git add lib/features/voice/presentation/widgets/mesh_eligibility_dot.dart \
        test/features/voice/presentation/widgets/mesh_eligibility_dot_test.dart
git commit -m "feat(mesh-voice/3d.2): MeshEligibilityDot widget reactive to watcher"
```

---

### Task 3: l10n keys

**Files:**
- Modify: `lib/l10n/app_ru.arb`
- Modify: `lib/l10n/app_en.arb`

Add 10 new keys for popup, conflict toast, tooltip, history badge.

- [ ] **Step 1: Add Russian keys**

Find the existing `"meshDeviceFallback"` block in `lib/l10n/app_ru.arb` and add the new keys immediately after the closing `}` of its `@meshDeviceFallback` placeholder block (or any well-defined location near other mesh keys):

```json
  "callConflictAlreadyInCall": "Завершите текущий звонок",
  "callPopupTransportTitle": "Способ звонка",
  "callPopupTransportMesh": "📡 По сети (mesh)",
  "callPopupTransportLk": "📞 Через сервер",
  "callPopupTransportMeshUnavailable": "Контакт не доступен через mesh",
  "meshOnboardingTitle": "📡 Mesh-звонки требуют активного приложения",
  "meshOnboardingBody": "Когда телефон заблокирован, mesh-звонки могут прерываться через ~30 секунд (iOS ограничение).",
  "meshOnboardingAck": "Понятно",
  "meshHistoryBadge": "📡 Mesh",
  "meshHistoryNoChatAvailable": "Контакт не в списке",
```

- [ ] **Step 2: Add English keys**

In `lib/l10n/app_en.arb`, same location:

```json
  "callConflictAlreadyInCall": "Finish the current call first",
  "callPopupTransportTitle": "Call via",
  "callPopupTransportMesh": "📡 Mesh (peer-to-peer)",
  "callPopupTransportLk": "📞 Server",
  "callPopupTransportMeshUnavailable": "Contact not reachable via mesh",
  "meshOnboardingTitle": "📡 Mesh calls need the app open",
  "meshOnboardingBody": "When the phone is locked, mesh calls may drop after ~30 seconds (iOS limitation).",
  "meshOnboardingAck": "Got it",
  "meshHistoryBadge": "📡 Mesh",
  "meshHistoryNoChatAvailable": "Contact is not in your list",
```

Make sure both ARB files remain valid JSON (commas in correct places).

- [ ] **Step 3: Regenerate AppLocalizations**

Run: `flutter gen-l10n`
Expected: `lib/l10n/app_localizations*.dart` regenerated with the 10 new getters.

- [ ] **Step 4: Verify analyze + tests still pass**

Run: `flutter analyze lib/l10n/`
Expected: `No issues found!`

Run: `flutter test`
Expected: still 516+ pass, no regressions.

- [ ] **Step 5: Commit**

```bash
git add lib/l10n/app_ru.arb lib/l10n/app_en.arb lib/l10n/app_localizations*.dart
git commit -m "feat(mesh-voice/3d.2): add l10n keys for popup, conflict, tooltip, history badge"
```

---

### Task 4: iOS onboarding tooltip + Hive prefs box

**Files:**
- Create: `lib/core/voice/mesh_prefs_service.dart`
- Create: `lib/features/voice/presentation/widgets/ios_mesh_onboarding_tooltip.dart`
- Test: `test/core/voice/mesh_prefs_service_test.dart`

The onboarding flag is persisted via a tiny new Hive box `mesh_prefs` (codebase doesn't use SharedPreferences). Single string box, key `onboarding_shown_v1`.

- [ ] **Step 1: Write failing test for prefs service**

Create `test/core/voice/mesh_prefs_service_test.dart`:

```dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:taler_id_mobile/core/voice/mesh_prefs_service.dart';

void main() {
  late Directory tempDir;
  late MeshPrefsService prefs;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('mesh_prefs_test_');
    Hive.init(tempDir.path);
    prefs = MeshPrefsService();
    await prefs.init();
  });

  tearDown(() async {
    await prefs.dispose();
    await Hive.deleteBoxFromDisk('mesh_prefs');
    await tempDir.delete(recursive: true);
  });

  group('MeshPrefsService', () {
    test('isOnboardingShown returns false initially', () async {
      expect(await prefs.isOnboardingShown(), isFalse);
    });

    test('markOnboardingShown then isOnboardingShown returns true', () async {
      await prefs.markOnboardingShown();
      expect(await prefs.isOnboardingShown(), isTrue);
    });

    test('flag persists across reopen', () async {
      await prefs.markOnboardingShown();
      await prefs.dispose();
      final prefs2 = MeshPrefsService();
      await prefs2.init();
      try {
        expect(await prefs2.isOnboardingShown(), isTrue);
      } finally {
        await prefs2.dispose();
      }
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/core/voice/mesh_prefs_service_test.dart`
Expected: compile error — `MeshPrefsService` not defined.

- [ ] **Step 3: Implement the prefs service**

Create `lib/core/voice/mesh_prefs_service.dart`:

```dart
import 'package:hive/hive.dart';

/// Tiny persistent prefs for mesh-related UI state. Currently only the
/// iOS onboarding-tooltip flag, but kept as a separate service so future
/// flags (e.g. user-preferred transport) have a clear home.
///
/// Hive box: 'mesh_prefs', untyped Box. Single key 'onboarding_shown_v1'.
class MeshPrefsService {
  static const _boxName = 'mesh_prefs';
  static const _onboardingKey = 'onboarding_shown_v1';

  Box? _box;

  Future<void> init() async {
    try {
      _box = await Hive.openBox(_boxName);
    } catch (_) {
      await Hive.deleteBoxFromDisk(_boxName);
      _box = await Hive.openBox(_boxName);
    }
  }

  Future<void> dispose() async {
    await _box?.close();
    _box = null;
  }

  Future<bool> isOnboardingShown() async {
    return (_box?.get(_onboardingKey) as bool?) ?? false;
  }

  Future<void> markOnboardingShown() async {
    await _box?.put(_onboardingKey, true);
  }
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test test/core/voice/mesh_prefs_service_test.dart`
Expected: `+3: All tests passed!`

- [ ] **Step 5: Implement the tooltip widget**

Create `lib/features/voice/presentation/widgets/ios_mesh_onboarding_tooltip.dart`:

```dart
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../../../../core/voice/mesh_prefs_service.dart';
import '../../../../l10n/app_localizations.dart';

class IosMeshOnboardingTooltip {
  /// If running on iOS and the onboarding has not yet been shown, presents a
  /// modal AlertDialog warning about background-suspend behavior. Marks the
  /// onboarding flag persistently after dismissal.
  ///
  /// Returns true iff the dialog was actually shown (and dismissed) just now.
  /// On non-iOS or when the flag is already set, returns false immediately.
  static Future<bool> showIfNeeded(BuildContext context) async {
    if (kIsWeb || !Platform.isIOS) return false;
    final prefs = GetIt.I<MeshPrefsService>();
    if (await prefs.isOnboardingShown()) return false;
    if (!context.mounted) return false;

    final l10n = AppLocalizations.of(context)!;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.meshOnboardingTitle),
        content: Text(l10n.meshOnboardingBody),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.meshOnboardingAck),
          ),
        ],
      ),
    );
    await prefs.markOnboardingShown();
    return true;
  }
}
```

- [ ] **Step 6: Run analyze**

Run: `flutter analyze lib/core/voice/mesh_prefs_service.dart lib/features/voice/presentation/widgets/ios_mesh_onboarding_tooltip.dart`
Expected: `No issues found!`

- [ ] **Step 7: Commit**

```bash
git add lib/core/voice/mesh_prefs_service.dart \
        lib/features/voice/presentation/widgets/ios_mesh_onboarding_tooltip.dart \
        test/core/voice/mesh_prefs_service_test.dart
git commit -m "feat(mesh-voice/3d.2): MeshPrefsService + iOS onboarding tooltip"
```

---

### Task 5: Coordinator `_screenPushed` refactor

**Files:**
- Modify: `lib/core/voice/mesh_voice_ui_coordinator.dart`

Move the `_screenPushed` flag from coordinator field to `_PendingCall.screenPushed`. Carry-over from 3d.1 code review (flag was relying on `Navigator.push.future` blocking until pop, which was fragile).

- [ ] **Step 1: Read current coordinator state**

Read `lib/core/voice/mesh_voice_ui_coordinator.dart`. Note the existing `bool _screenPushed = false;` field (around line 60-65) and the `_PendingCall` class (bottom of file).

- [ ] **Step 2: Apply the refactor**

In `lib/core/voice/mesh_voice_ui_coordinator.dart`:

1. **Remove** the field `bool _screenPushed = false;` from `MeshVoiceUiCoordinator`.
2. **Add** `bool screenPushed = false;` (mutable) to `_PendingCall`.
3. In `_handleInviting`, replace `if (_screenPushed) return;` with `if (_pending?.screenPushed == true) return;` and `_screenPushed = true;` with `_pending?.screenPushed = true;`. Remove the trailing `_screenPushed = false;`.
4. In `_handleActive`, same replacement: read `p?.screenPushed == true`, set `p.screenPushed = true`. Remove trailing reset.

The flag now naturally clears when `_pending = null` happens in `_handleEnded`.

Concretely, change `_handleInviting` from:

```dart
    if (_screenPushed) return;
    _screenPushed = true;
    await navigator.pushScreen(MeshVoiceCallScreen(...));
    _screenPushed = false;
  }
```

to:

```dart
    if (_pending?.screenPushed == true) return;
    _pending?.screenPushed = true;
    await navigator.pushScreen(MeshVoiceCallScreen(...));
  }
```

And `_handleActive` from:

```dart
    if (_screenPushed) return;
    navigator.popSheet();
    _screenPushed = true;
    await navigator.pushScreen(MeshVoiceCallScreen(...));
    _screenPushed = false;
  }
```

to:

```dart
    if (p?.screenPushed == true) return;
    navigator.popSheet();
    p?.screenPushed = true;
    await navigator.pushScreen(MeshVoiceCallScreen(...));
  }
```

In `_PendingCall`:

```dart
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
  bool screenPushed = false;  // NEW

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

- [ ] **Step 3: Run all coordinator tests**

Run: `flutter test test/core/voice/mesh_voice_ui_coordinator_test.dart test/core/voice/mesh_voice_integration_test.dart test/core/voice/mesh_voice_ui_coordinator_test.dart`
Expected: 11+ tests pass (all existing 3d.1 coordinator tests still green).

- [ ] **Step 4: Run full test suite**

Run: `flutter test`
Expected: 516+ pass, no regressions.

- [ ] **Step 5: Commit**

```bash
git add lib/core/voice/mesh_voice_ui_coordinator.dart
git commit -m "refactor(mesh-voice/3d.2): move _screenPushed flag into _PendingCall

Carry-over from 3d.1 code review: the coordinator-level _screenPushed
flag relied on Navigator.push.future blocking until the route pops,
which is fragile. Tying screenPushed to the _PendingCall lifecycle
naturally clears the flag when _pending = null at call end."
```

---

## Chat-room integration

### Task 6: Auto-pick logic + LiveKit-conflict guard

**Files:**
- Modify: `lib/features/messenger/presentation/screens/chat_room_screen.dart`
- Test: `test/features/messenger/presentation/screens/chat_room_auto_pick_test.dart`

Replace the existing `_startCall()` callsite of the phone IconButton with a new `_autoPickCall()` decision tree. Existing `_startCall` is renamed to `_startLkCall`.

- [ ] **Step 1: Write failing tests**

Create `test/features/messenger/presentation/screens/chat_room_auto_pick_test.dart`:

```dart
// Note: chat_room_screen is huge (6000+ lines) and tightly coupled to
// MessengerBloc / GoRouter / multiple services. Unit-testing the full
// widget is impractical. Instead, the auto-pick decision is extracted
// into a pure function chatRoomAutoPickDecision() (Task 6 step 3) which
// is tested here. The widget itself stays a thin wrapper.

import 'package:flutter_test/flutter_test.dart';
import 'package:taler_id_mobile/features/messenger/presentation/screens/chat_room_auto_pick.dart';

void main() {
  group('chatRoomAutoPickDecision', () {
    test('returns conflict when isInCall && !canAddLine', () {
      expect(
        chatRoomAutoPickDecision(
          convType: 'DIRECT',
          otherUserId: 'u1',
          isInCall: true,
          canAddLine: false,
          isUserOnline: true,
          recentLkCallMs: null,
          nowMs: 1000,
        ),
        AutoPickDecision.conflict,
      );
    });

    test('returns lk for non-DIRECT conv (group)', () {
      expect(
        chatRoomAutoPickDecision(
          convType: 'GROUP',
          otherUserId: null,
          isInCall: false,
          canAddLine: true,
          isUserOnline: true,
          recentLkCallMs: null,
          nowMs: 1000,
        ),
        AutoPickDecision.lk,
      );
    });

    test('returns lk for DIRECT with null otherUserId', () {
      expect(
        chatRoomAutoPickDecision(
          convType: 'DIRECT',
          otherUserId: null,
          isInCall: false,
          canAddLine: true,
          isUserOnline: true,
          recentLkCallMs: null,
          nowMs: 1000,
        ),
        AutoPickDecision.lk,
      );
    });

    test('returns lk when recent LK call < 30 min ago', () {
      const tenMin = 10 * 60 * 1000;
      expect(
        chatRoomAutoPickDecision(
          convType: 'DIRECT',
          otherUserId: 'u1',
          isInCall: false,
          canAddLine: true,
          isUserOnline: true,
          recentLkCallMs: 1000,
          nowMs: 1000 + tenMin,
        ),
        AutoPickDecision.lk,
      );
    });

    test('returns mesh when recent LK call > 30 min ago', () {
      const fortyMin = 40 * 60 * 1000;
      expect(
        chatRoomAutoPickDecision(
          convType: 'DIRECT',
          otherUserId: 'u1',
          isInCall: false,
          canAddLine: true,
          isUserOnline: true,
          recentLkCallMs: 1000,
          nowMs: 1000 + fortyMin,
        ),
        AutoPickDecision.mesh,
      );
    });

    test('returns lk when peer is not online via mesh', () {
      expect(
        chatRoomAutoPickDecision(
          convType: 'DIRECT',
          otherUserId: 'u1',
          isInCall: false,
          canAddLine: true,
          isUserOnline: false,
          recentLkCallMs: null,
          nowMs: 1000,
        ),
        AutoPickDecision.lk,
      );
    });

    test('returns mesh when DIRECT + online + no recent LK', () {
      expect(
        chatRoomAutoPickDecision(
          convType: 'DIRECT',
          otherUserId: 'u1',
          isInCall: false,
          canAddLine: true,
          isUserOnline: true,
          recentLkCallMs: null,
          nowMs: 1000,
        ),
        AutoPickDecision.mesh,
      );
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/messenger/presentation/screens/chat_room_auto_pick_test.dart`
Expected: compile error — `chatRoomAutoPickDecision` and `AutoPickDecision` not defined.

- [ ] **Step 3: Extract pure decision function**

Create `lib/features/messenger/presentation/screens/chat_room_auto_pick.dart`:

```dart
/// Pure decision logic for the chat-room call button. Extracted so it can
/// be unit-tested without instantiating the 6000-line ChatRoomScreen.
///
/// Mesh-first policy: if the conversation is DIRECT, peer's userId is known,
/// app is not already in a non-multiline call, no recent LK call within the
/// last 30 minutes, and the peer is currently online via mesh — choose mesh.
/// Otherwise fall through to LiveKit. Conflicts surface as AutoPickDecision.conflict.
enum AutoPickDecision {
  conflict, // active LK or mesh call already in progress
  mesh,     // proceed with MeshVoiceUiCoordinator.placeCall
  lk,       // proceed with the existing LiveKit flow
}

AutoPickDecision chatRoomAutoPickDecision({
  required String? convType,
  required String? otherUserId,
  required bool isInCall,
  required bool canAddLine,
  required bool isUserOnline,
  required int? recentLkCallMs,
  required int nowMs,
  Duration recentLkWindow = const Duration(minutes: 30),
}) {
  if (isInCall && !canAddLine) return AutoPickDecision.conflict;
  if (convType != 'DIRECT') return AutoPickDecision.lk;
  if (otherUserId == null) return AutoPickDecision.lk;
  if (recentLkCallMs != null &&
      nowMs - recentLkCallMs < recentLkWindow.inMilliseconds) {
    return AutoPickDecision.lk;
  }
  if (!isUserOnline) return AutoPickDecision.lk;
  return AutoPickDecision.mesh;
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test test/features/messenger/presentation/screens/chat_room_auto_pick_test.dart`
Expected: `+7: All tests passed!`

- [ ] **Step 5: Wire `_autoPickCall` in chat_room_screen**

In `lib/features/messenger/presentation/screens/chat_room_screen.dart`:

1. Add import at the top:
```dart
import '../../../../core/voice/mesh_peer_eligibility_watcher.dart';
import '../../../../core/voice/mesh_voice_ui_coordinator.dart';
import '../../../../core/mesh/crypto/keys/contact_key_store_hive.dart';
import '../../../../core/mesh/transport/peer_id.dart';
import '../../../voice/presentation/widgets/ios_mesh_onboarding_tooltip.dart';
import 'chat_room_auto_pick.dart';
```

2. Add a static map at file-level (above the `class _ChatRoomScreenState`):

```dart
/// Per-process cache of "user explicitly used LiveKit with this peer at time T".
/// Drives the 30-minute sticky-LK heuristic in chat_room_auto_pick decision.
final Map<String, int> _recentLkCallMs = {};
```

3. Rename the existing `Future<void> _startCall() async` to `Future<void> _startLkCall() async`. Add the recency-recording line at the very start of `_startLkCall`:

```dart
Future<void> _startLkCall() async {
  final convForRecency = _resolveConv(context.read<MessengerBloc>().state.conversations);
  if (convForRecency?.type == 'DIRECT' && convForRecency?.otherUserId != null) {
    _recentLkCallMs[convForRecency!.otherUserId!] = DateTime.now().millisecondsSinceEpoch;
  }
  // ... existing body unchanged ...
}
```

4. Add the new `_autoPickCall` method right above `_startLkCall`:

```dart
Future<void> _autoPickCall() async {
  final l10n = AppLocalizations.of(context)!;
  final conv = _resolveConv(context.read<MessengerBloc>().state.conversations);
  final otherUserId = conv?.type == 'DIRECT' ? conv?.otherUserId : null;
  final watcher = sl<MeshPeerEligibilityWatcher>();

  final decision = chatRoomAutoPickDecision(
    convType: conv?.type,
    otherUserId: otherUserId,
    isInCall: CallStateService.instance.isInCall,
    canAddLine: CallStateService.instance.canAddLine,
    isUserOnline: otherUserId != null && watcher.isUserOnline(otherUserId),
    recentLkCallMs: otherUserId == null ? null : _recentLkCallMs[otherUserId],
    nowMs: DateTime.now().millisecondsSinceEpoch,
  );

  switch (decision) {
    case AutoPickDecision.conflict:
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(l10n.callConflictAlreadyInCall),
        backgroundColor: AppColors.of(context).error,
      ));
      return;
    case AutoPickDecision.lk:
      return _startLkCall();
    case AutoPickDecision.mesh:
      await IosMeshOnboardingTooltip.showIfNeeded(context);
      if (mounted) await _startMeshCall(otherUserId!);
      return;
  }
}

Future<void> _startMeshCall(String userId) async {
  final keyStore = sl<HiveContactKeyStore>();
  final userPk = keyStore.userPkForContactUserId(userId);
  if (userPk == null) {
    debugPrint('[chat-room] mesh fallback: userPk for $userId not in store, falling back to LK');
    return _startLkCall();
  }
  final devices = keyStore.devicesFor(userPk);
  if (devices.isEmpty) return _startLkCall();
  final ordered = devices.toList()
    ..sort((a, b) => a.toHex().compareTo(b.toHex()));
  await sl<MeshVoiceUiCoordinator>().placeCall(ordered.first);
}
```

5. Replace the `onPressed: _startCall,` line in the IconButton (around line 1817 of the existing file) with `onPressed: _autoPickCall,`. The IconButton remains for the visual; popup-on-long-press is added in Task 7.

6. Search for any other call sites of `_startCall(` and replace with `_startLkCall(`. There is one in the missed-call message system-message handler around line 2094 — that one should stay as `_startLkCall` (because it's a retry from a missed LK call).

- [ ] **Step 6: Run analyze**

Run: `flutter analyze lib/features/messenger/presentation/screens/`
Expected: No new errors. Pre-existing infos OK.

- [ ] **Step 7: Run tests**

Run: `flutter test`
Expected: 516 + 7 (Task 6 unit) + 4 (Task 2 widget) + 8 (Task 1 unit) + 3 (Task 4 prefs) = ~538 pass.

- [ ] **Step 8: Commit**

```bash
git add lib/features/messenger/presentation/screens/chat_room_auto_pick.dart \
        lib/features/messenger/presentation/screens/chat_room_screen.dart \
        test/features/messenger/presentation/screens/chat_room_auto_pick_test.dart
git commit -m "feat(mesh-voice/3d.2): chat-header auto-pick (mesh-first when peer online)"
```

---

### Task 7: Long-press transport popup + dot overlay

**Files:**
- Modify: `lib/features/messenger/presentation/screens/chat_room_screen.dart`

The phone IconButton becomes a `GestureDetector` wrapper that detects long-press → bottom sheet with explicit transport choice. The MeshEligibilityDot is overlaid on top via a Stack.

- [ ] **Step 1: Add `_showTransportPopup` method**

In the same file, near `_autoPickCall`:

```dart
Future<void> _showTransportPopup() async {
  final l10n = AppLocalizations.of(context)!;
  final conv = _resolveConv(context.read<MessengerBloc>().state.conversations);
  if (conv?.type != 'DIRECT') return;
  final otherUserId = conv?.otherUserId;
  if (otherUserId == null) return;

  if (CallStateService.instance.isInCall && !CallStateService.instance.canAddLine) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(l10n.callConflictAlreadyInCall),
      backgroundColor: AppColors.of(context).error,
    ));
    return;
  }

  final watcher = sl<MeshPeerEligibilityWatcher>();
  final isMeshAvailable = watcher.isUserOnline(otherUserId);

  await showModalBottomSheet<void>(
    context: context,
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.callPopupTransportTitle,
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            ListTile(
              key: const Key('chat-popup-mesh'),
              leading: const Icon(Icons.wifi_tethering, color: Colors.green),
              title: Text(l10n.callPopupTransportMesh),
              subtitle: isMeshAvailable
                  ? null
                  : Text(l10n.callPopupTransportMeshUnavailable),
              enabled: isMeshAvailable,
              onTap: !isMeshAvailable
                  ? null
                  : () async {
                      Navigator.of(ctx).pop();
                      await IosMeshOnboardingTooltip.showIfNeeded(context);
                      if (mounted) await _startMeshCall(otherUserId);
                    },
            ),
            ListTile(
              key: const Key('chat-popup-lk'),
              leading: Icon(Icons.phone, color: AppColors.of(context).primary),
              title: Text(l10n.callPopupTransportLk),
              onTap: () {
                Navigator.of(ctx).pop();
                _startLkCall();
              },
            ),
          ],
        ),
      ),
    ),
  );
}
```

- [ ] **Step 2: Wrap phone IconButton with GestureDetector + dot overlay**

Find the existing IconButton around line 1815 (already modified in Task 6 to use `_autoPickCall`). Replace the whole `IconButton` widget with:

```dart
GestureDetector(
  onLongPress: _showTransportPopup,
  child: Stack(
    clipBehavior: Clip.none,
    children: [
      IconButton(
        icon: const Icon(Icons.phone_outlined),
        onPressed: _autoPickCall,
        tooltip: AppLocalizations.of(context)!.chatCall,
      ),
      if (conv?.type == 'DIRECT' && conv?.otherUserId != null)
        Positioned(
          top: 6,
          right: 6,
          child: MeshEligibilityDot(userId: conv!.otherUserId!),
        ),
    ],
  ),
),
```

Add import at top:

```dart
import '../../../voice/presentation/widgets/mesh_eligibility_dot.dart';
```

- [ ] **Step 3: Run analyze + tests**

Run: `flutter analyze lib/features/messenger/presentation/screens/`
Expected: No new errors.

Run: `flutter test`
Expected: still ~538 pass, no regressions.

- [ ] **Step 4: Manual visual smoke (optional, before commit)**

Run on a device:
```bash
flutter run --release --flavor dev -t lib/main_dev.dart \
  --dart-define=FLAVOR=dev --dart-define=BASE_URL=https://staging.id.taler.tirol \
  -d <device-id>
```
Open a DIRECT chat → confirm phone icon renders correctly. With another device online via mesh → green dot visible. Long-press → popup appears with two options.

- [ ] **Step 5: Commit**

```bash
git add lib/features/messenger/presentation/screens/chat_room_screen.dart
git commit -m "feat(mesh-voice/3d.2): chat-header long-press transport popup + eligibility dot"
```

---

## Call history merge

### Task 8: CallHistoryScreen merges mesh entries

**Files:**
- Modify: `lib/features/call_history/presentation/screens/call_history_screen.dart`
- Test: `test/features/call_history/call_history_mesh_merge_test.dart`

The mesh repository emits a stream of all entries (Phase 3d.1). The screen subscribes in initState, then merges with the existing `_history` list (which is populated from the server fetch + cache).

- [ ] **Step 1: Write failing test for merge logic**

Create `test/features/call_history/call_history_mesh_merge_test.dart`:

```dart
// The full CallHistoryScreen has external dependencies (DioClient,
// CallHistoryCacheService, MessengerBloc). Extract the pure merge
// function into call_history_merge.dart so it can be tested in isolation.

import 'package:flutter_test/flutter_test.dart';
import 'package:taler_id_mobile/features/call_history/data/mesh_call_history_entry.dart';
import 'package:taler_id_mobile/features/call_history/presentation/screens/call_history_merge.dart';

MeshCallHistoryEntry _meshEntry({
  required int callId,
  required DateTime startedAt,
  String? peerName,
  String? peerUserId,
  bool isOutgoing = true,
  String endReason = 'userHangup',
  DateTime? activatedAt,
  int? durationSec,
  String? transport = 'bonjour',
}) =>
    MeshCallHistoryEntry(
      callId: callId,
      peerDevicePkBase64: 'AQIDBA==',
      peerUserId: peerUserId,
      peerName: peerName,
      isOutgoing: isOutgoing,
      startedAt: startedAt,
      activatedAt: activatedAt,
      endedAt: startedAt.add(const Duration(seconds: 30)),
      durationSec: durationSec,
      endReason: endReason,
      transport: transport,
    );

void main() {
  group('mergedHistoryEntries', () {
    test('mesh entries are converted to display rows with badge=true', () {
      final mesh = _meshEntry(
        callId: 0xCAFE,
        startedAt: DateTime.utc(2026, 4, 30, 10),
        peerName: 'Alice',
        peerUserId: 'u-1',
        durationSec: 30,
        activatedAt: DateTime.utc(2026, 4, 30, 10, 0, 1),
      );
      final result = mergedHistoryEntries(serverEntries: const [], meshEntries: [mesh]);
      expect(result, hasLength(1));
      expect(result.single.id, 'mesh-cafe');
      expect(result.single.isMesh, isTrue);
      expect(result.single.otherPartyName, 'Alice');
      expect(result.single.otherPartyId, 'u-1');
      expect(result.single.durationSec, 30);
      expect(result.single.isOutgoing, isTrue);
    });

    test('merged list is sorted by startedAt desc', () {
      final older = _meshEntry(callId: 1, startedAt: DateTime.utc(2026, 4, 30, 9));
      final newer = _meshEntry(callId: 2, startedAt: DateTime.utc(2026, 4, 30, 11));
      final server = HistoryDisplayRow(
        id: 'srv-1',
        otherPartyName: 'Server peer',
        otherPartyAvatar: null,
        otherPartyId: 'u-srv',
        startedAt: DateTime.utc(2026, 4, 30, 10),
        durationSec: 60,
        isOutgoing: false,
        isMissed: false,
        withAi: false,
        conversationId: null,
        isMesh: false,
        meshEndReason: null,
      );
      final result = mergedHistoryEntries(
        serverEntries: [server],
        meshEntries: [older, newer],
      );
      expect(result.map((r) => r.id), ['mesh-2', 'srv-1', 'mesh-1']);
    });

    test('mesh entry with peerName=null falls back to "Mesh-устройство <hex>"', () {
      final mesh = _meshEntry(
        callId: 1,
        startedAt: DateTime.utc(2026, 4, 30, 10),
        peerName: null,
      );
      final result = mergedHistoryEntries(serverEntries: const [], meshEntries: [mesh]);
      // base64 'AQIDBA==' → bytes [1, 2, 3, 4] → hex '01020304'
      expect(result.single.otherPartyName, 'Mesh-устройство 01020304');
    });

    test('isMissed true for never-activated invite-timeout', () {
      final mesh = _meshEntry(
        callId: 1,
        startedAt: DateTime.utc(2026),
        endReason: 'inviteTimeout',
        activatedAt: null,
      );
      final result = mergedHistoryEntries(serverEntries: const [], meshEntries: [mesh]);
      expect(result.single.isMissed, isTrue);
    });

    test('isMissed false for completed call (activatedAt non-null)', () {
      final mesh = _meshEntry(
        callId: 1,
        startedAt: DateTime.utc(2026),
        endReason: 'userHangup',
        activatedAt: DateTime.utc(2026),
      );
      final result = mergedHistoryEntries(serverEntries: const [], meshEntries: [mesh]);
      expect(result.single.isMissed, isFalse);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/call_history/call_history_mesh_merge_test.dart`
Expected: compile error — `mergedHistoryEntries` and `HistoryDisplayRow` not defined.

- [ ] **Step 3: Extract merge logic + display row type**

Create `lib/features/call_history/presentation/screens/call_history_merge.dart`:

```dart
import 'dart:convert';

import '../../data/mesh_call_history_entry.dart';

/// View-model row used by the CallHistoryScreen list. Both server-fetched
/// and mesh-stored entries map onto this shape so the rendering code
/// doesn't branch on source.
class HistoryDisplayRow {
  final String id;
  final String otherPartyName;
  final String? otherPartyAvatar;
  final String? otherPartyId;
  final DateTime startedAt;
  final int? durationSec;
  final bool isOutgoing;
  final bool isMissed;
  final bool withAi;
  final String? conversationId;
  final bool isMesh;
  final String? meshEndReason;

  const HistoryDisplayRow({
    required this.id,
    required this.otherPartyName,
    required this.otherPartyAvatar,
    required this.otherPartyId,
    required this.startedAt,
    required this.durationSec,
    required this.isOutgoing,
    required this.isMissed,
    required this.withAi,
    required this.conversationId,
    required this.isMesh,
    required this.meshEndReason,
  });
}

HistoryDisplayRow displayRowFromMesh(MeshCallHistoryEntry m) {
  // Convert peerDevicePkBase64 → first 4 bytes hex for fallback name.
  String hexShort;
  try {
    final bytes = base64Decode(m.peerDevicePkBase64);
    final n = bytes.length < 4 ? bytes.length : 4;
    hexShort = bytes
        .take(n)
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join();
  } catch (_) {
    final l = m.peerDevicePkBase64.length;
    hexShort = m.peerDevicePkBase64.substring(0, l < 8 ? l : 8);
  }
  final name = (m.peerName != null && m.peerName!.isNotEmpty)
      ? m.peerName!
      : 'Mesh-устройство $hexShort';
  final isMissed = m.activatedAt == null &&
      (m.endReason == 'inviteTimeout' || m.endReason == 'rejectedByCallee');
  return HistoryDisplayRow(
    id: 'mesh-${m.callId.toRadixString(16)}',
    otherPartyName: name,
    otherPartyAvatar: null,
    otherPartyId: m.peerUserId,
    startedAt: m.startedAt,
    durationSec: m.durationSec,
    isOutgoing: m.isOutgoing,
    isMissed: isMissed,
    withAi: false,
    conversationId: null,
    isMesh: true,
    meshEndReason: m.endReason,
  );
}

/// Merge server-fetched display rows with mesh entries (converted on the fly),
/// sorted globally by startedAt desc.
List<HistoryDisplayRow> mergedHistoryEntries({
  required List<HistoryDisplayRow> serverEntries,
  required List<MeshCallHistoryEntry> meshEntries,
}) {
  final all = <HistoryDisplayRow>[
    ...serverEntries,
    ...meshEntries.map(displayRowFromMesh),
  ];
  all.sort((a, b) => b.startedAt.compareTo(a.startedAt));
  return all;
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test test/features/call_history/call_history_mesh_merge_test.dart`
Expected: `+5: All tests passed!`

- [ ] **Step 5: Wire merge into CallHistoryScreen**

In `lib/features/call_history/presentation/screens/call_history_screen.dart`:

1. Add imports at top:
```dart
import '../../data/mesh_call_history_entry.dart';
import '../../data/mesh_call_history_repository.dart';
import 'call_history_merge.dart';
```

2. Change the type of `_history` field from `List<_CallEntry>?` to `List<HistoryDisplayRow>?`.

3. Add a state field:
```dart
StreamSubscription<List<MeshCallHistoryEntry>>? _meshHistorySub;
List<MeshCallHistoryEntry> _meshLatest = const [];
List<HistoryDisplayRow> _serverLatest = const [];
```

4. Add a helper method on `_CallEntry` (or convert at call sites — simplest: write a small adapter in this file converting the existing `_CallEntry` to `HistoryDisplayRow` for server entries):

```dart
HistoryDisplayRow _serverEntryToRow(_CallEntry e) => HistoryDisplayRow(
      id: e.id,
      otherPartyName: e.otherPartyName,
      otherPartyAvatar: e.otherPartyAvatar,
      otherPartyId: e.otherPartyId,
      startedAt: e.startedAt,
      durationSec: e.durationSec,
      isOutgoing: e.isOutgoing,
      isMissed: e.isMissed,
      withAi: e.withAi,
      conversationId: e.conversationId,
      isMesh: false,
      meshEndReason: null,
    );
```

5. In `initState`, after `_refreshHistory();`:
```dart
_meshHistorySub = sl<MeshCallHistoryRepository>().watch().listen((mesh) {
  _meshLatest = mesh;
  _recomputeMerged();
});
// initial mesh load (watch may take one microtask to emit)
sl<MeshCallHistoryRepository>().getAll().then((mesh) {
  _meshLatest = mesh;
  _recomputeMerged();
});
```

6. In `dispose`, before `super.dispose()`:
```dart
_meshHistorySub?.cancel();
```

7. Add the recompute helper:
```dart
void _recomputeMerged() {
  if (!mounted) return;
  setState(() {
    _history = mergedHistoryEntries(
      serverEntries: _serverLatest,
      meshEntries: _meshLatest,
    );
  });
}
```

8. In `_hydrateFromCache` and `_refreshHistory`, instead of directly setting `_history = raw.map(...)`, do:
```dart
_serverLatest = raw.map(_CallEntry.fromJson).map(_serverEntryToRow).toList();
_recomputeMerged();
```

9. **Render the badge**: find where the entry is rendered (search for `_CallEntry` usage in widgets — likely a `_CallTile` widget or inline `ListView.builder`). For each row, where the time/duration row is rendered, add (only if `entry.isMesh`):
```dart
if (entry.isMesh) ...[
  const SizedBox(width: 6),
  Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      color: Colors.green.withOpacity(0.15),
      borderRadius: BorderRadius.circular(4),
    ),
    child: Text(
      AppLocalizations.of(context)!.meshHistoryBadge,
      style: const TextStyle(fontSize: 10, color: Colors.green),
    ),
  ),
],
```

10. **Tap behavior for mesh entries** (in the same render or onTap handler):
```dart
onTap: () async {
  if (entry.isMesh && entry.otherPartyId == null) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(AppLocalizations.of(context)!.meshHistoryNoChatAvailable),
    ));
    return;
  }
  // ... existing tap-handler that opens DIRECT chat by otherPartyId.
},
```

(The existing tap handler likely already navigates by `otherPartyId`. If yes — just guard the `null` case with the SnackBar before calling it.)

- [ ] **Step 6: Run analyze + tests**

Run: `flutter analyze lib/features/call_history/`
Expected: No new errors. Existing infos OK.

Run: `flutter test`
Expected: ~543 pass total.

- [ ] **Step 7: Commit**

```bash
git add lib/features/call_history/presentation/screens/call_history_merge.dart \
        lib/features/call_history/presentation/screens/call_history_screen.dart \
        test/features/call_history/call_history_mesh_merge_test.dart
git commit -m "feat(mesh-voice/3d.2): merge mesh_call_history into CallHistoryScreen"
```

---

## DI wiring + cleanup

### Task 9: Register `MeshPeerEligibilityWatcher` + `MeshPrefsService`; bootstrap

**Files:**
- Modify: `lib/core/di/service_locator.dart`
- Modify: `lib/core/mesh/mesh_bootstrap.dart`

- [ ] **Step 1: Modify `service_locator.dart`**

At the top of `lib/core/di/service_locator.dart`, add imports (alphabetical placement):

```dart
import '../voice/mesh_peer_eligibility_watcher.dart';
import '../voice/mesh_prefs_service.dart';
```

In `setupDependencies()`, after `MeshCallHistoryRepository` registration (added in 3d.1), add:

```dart
  // Mesh prefs (Hive) — small flag store for mesh-related UI state
  final meshPrefs = MeshPrefsService();
  await meshPrefs.init();
  sl.registerSingleton<MeshPrefsService>(meshPrefs);
```

After `MeshVoiceUiCoordinator` registration, add:

```dart
  sl.registerLazySingleton<MeshPeerEligibilityWatcher>(
    () => MeshPeerEligibilityWatcher(
      transport: sl<MeshTransport>(),
      contactKeyStore: sl<HiveContactKeyStore>(),
    ),
  );
```

(The watcher's `ContactKeyStoreLookup` interface is implemented by `HiveContactKeyStore`'s existing `lookupUserByDevice` and `allUserIdMappings` methods. No adapter needed — the abstract is structural here.)

If `HiveContactKeyStore` doesn't structurally satisfy `ContactKeyStoreLookup` (Dart doesn't have structural types), add `implements ContactKeyStoreLookup` to the `HiveContactKeyStore` class declaration — both methods are already present.

- [ ] **Step 2: Modify `mesh_bootstrap.dart`**

In `lib/core/mesh/mesh_bootstrap.dart`, in `runMeshBootstrap()` after `sl<MeshVoiceUiCoordinator>().start()` block, add:

```dart
    if (sl.isRegistered<MeshPeerEligibilityWatcher>()) {
      try {
        sl<MeshPeerEligibilityWatcher>().start();
        debugPrint('[mesh-boot] MeshPeerEligibilityWatcher.start() ok');
      } catch (e) {
        debugPrint('[mesh-boot] MeshPeerEligibilityWatcher.start() failed: $e');
      }
    }
```

Add the import at the top of `mesh_bootstrap.dart`:

```dart
import '../voice/mesh_peer_eligibility_watcher.dart';
```

- [ ] **Step 3: Run analyze + tests**

Run: `flutter analyze lib/core/`
Expected: No new errors.

Run: `flutter test`
Expected: still ~543 pass (no test changes here, but DI order matters).

- [ ] **Step 4: Commit**

```bash
git add lib/core/di/service_locator.dart lib/core/mesh/mesh_bootstrap.dart \
        lib/core/mesh/crypto/keys/contact_key_store_hive.dart
git commit -m "feat(mesh-voice/3d.2): DI wiring for MeshPrefsService + MeshPeerEligibilityWatcher"
```

(`contact_key_store_hive.dart` may need the `implements ContactKeyStoreLookup` line — confirm during analyze. If not needed, drop it from the git add.)

---

### Task 10: Remove debug "Place mesh call" button from MeshDebugScreen

**Files:**
- Modify: `lib/features/mesh_debug/presentation/screens/mesh_debug_screen.dart`

The chat-header is now the primary entry point. Keep MeshDebugScreen as a pure diagnostics tool (status, peers list, send-test text), without the user-facing call action.

- [ ] **Step 1: Remove `_placeMeshCall` method + IconButton invocation**

In `lib/features/mesh_debug/presentation/screens/mesh_debug_screen.dart`:

1. Delete the `Future<void> _placeMeshCall(...)` method.
2. In `_PeerTile`, remove the `final VoidCallback? onPlaceCall;` field and remove the green-phone IconButton from the trailing Row. Restore the original simpler `trailing:` to:
```dart
trailing: onSendTest != null
  ? TextButton(onPressed: onSendTest, child: const Text('Send test'))
  : const Text('no pk', style: TextStyle(fontSize: 10, color: Colors.grey)),
```
3. At the call site, remove the `onPlaceCall: ...` parameter.
4. Remove unused imports: `mesh_voice_ui_coordinator.dart` and any others that became unused.

- [ ] **Step 2: Run analyze + tests**

Run: `flutter analyze lib/features/mesh_debug/`
Expected: No new errors. No "unused import" warnings on the touched file.

Run: `flutter test`
Expected: ~543 pass.

- [ ] **Step 3: Commit**

```bash
git add lib/features/mesh_debug/presentation/screens/mesh_debug_screen.dart
git commit -m "chore(mesh-debug): remove Place-mesh-call debug button (chat-header is primary)"
```

---

## Hardware smoke + PR

### Task 11: Hardware smoke (manual)

**Files:** none.

- [ ] **Step 1: Local APK install on Android**

```bash
cd ~/Downloads/taler_id_mobile
flutter run --release --flavor dev -t lib/main_dev.dart \
  --dart-define=FLAVOR=dev --dart-define=BASE_URL=https://staging.id.taler.tirol \
  -d 78c0742f
```

- [ ] **Step 2: Local install on iPhone**

```bash
flutter run --release --flavor dev -t lib/main_dev.dart \
  --dart-define=FLAVOR=dev --dart-define=BASE_URL=https://staging.id.taler.tirol \
  -d 00008150-00060C5A21E9401C
```

Both devices authenticated as the two integration_test accounts (which are mutual contacts on DEV).

- [ ] **Step 3: Eligibility dot test**

Open a DIRECT chat with the other test user on each device.
Expected: green 📡 dot appears next to the phone icon within ~10 sec of mesh discovery on both sides.

Toggle WiFi off on iPhone → dot disappears on Android within ~10 sec (mDNS ServiceLost). Toggle on → dot reappears.

- [ ] **Step 4: Auto-pick mesh test**

On Android while iPhone is online (dot visible), tap phone icon. Expected: mesh call rings on iPhone (modal dialog), accept → call screen with audio in both directions (verifies 3d.1 audio fixes still hold).

Hangup. After 10 sec (cooldown), tap phone icon again on iPhone (now caller). Expected: mesh call goes to Android.

- [ ] **Step 5: First-time iOS tooltip**

After uninstalling the iPhone build (`flutter clean ios; flutter run ...`), do the first mesh call from iPhone. Expected: AlertDialog "📡 Mesh-звонки требуют активного приложения" appears once. Dismiss → call proceeds.

Make a second mesh call. Expected: no dialog, call proceeds directly.

- [ ] **Step 6: Long-press popup test**

Long-press phone icon on Android while iPhone offline. Expected: popup appears with "📡 Mesh" disabled (greyed) showing "Контакт не доступен через mesh", and "📞 Через сервер" enabled. Tap server option → LiveKit call starts.

- [ ] **Step 7: LiveKit-conflict toast**

On Android: place a LiveKit call, then on Android (while LK is active and you're back in chat) tap phone icon for a different chat — should show SnackBar "Завершите текущий звонок", LK call uninterrupted.

- [ ] **Step 8: Recent-LK sticky-transport heuristic**

On Android: place a LiveKit call to iPhone via long-press → server option. Hangup after 5 sec. Within 30 min: tap phone icon (short-tap, mesh dot still visible). Expected: LiveKit call again (sticky), not mesh.

After 35 min (or restart Android): same short-tap → mesh call.

- [ ] **Step 9: Call history merge**

Open Calls screen on either device. Expected: list shows both LK and mesh entries chronologically. Mesh entries have small "📡 Mesh" badge near time. Tap mesh entry → opens DIRECT chat with peer.

- [ ] **Step 10: 3d.1 regression**

Verify that all the 3d.1 hardware-smoke flows still work: incoming sheet renders, AlertDialog has Accept+Decline buttons, hangup works on both sides, history entries persist.

---

### Task 12: Push branch + open PR

**Files:** none.

- [ ] **Step 1: Push branch**

```bash
git push origin feature/mesh-voice-call-phase3d.2
```

- [ ] **Step 2: Open PR via web (or `gh pr create` if authenticated)**

URL: https://github.com/dvvolkovv/taler_id_mobile/compare/dev...feature/mesh-voice-call-phase3d.2?expand=1

Title: `feat(mesh-voice/3d.2): chat integration + history merge + iOS onboarding`

Body skeleton:
```markdown
## Summary

Phase 3d.2 makes mesh voice calls usable end-to-end through normal chat UX (replacing the debug-screen entry point from 3d.1).

- New MeshPeerEligibilityWatcher: per-userId online state from MeshTransport discovery streams + ContactKeyStore mappings.
- New MeshEligibilityDot widget: 📡 indicator next to chat-header phone icon when peer is reachable via mesh.
- chat_room_screen: short-tap = auto-pick (mesh-first when peer online + no recent LK call within 30 min); long-press = transport popup.
- iOS-only onboarding tooltip on first mesh call (background-suspend warning).
- LiveKit-conflict guard with SnackBar.
- CallHistoryScreen: merges mesh_call_history Hive entries with server-fetched entries, sorted globally, with 📡 badge.
- Carry-over from 3d.1 review: _screenPushed flag moved into _PendingCall.

Out of scope (Phase 3d.3): Android foreground service for background incoming notification.

## Test plan

- [x] Unit: MeshPeerEligibilityWatcher (8), MeshPrefsService (3), chat_room_auto_pick_decision (7), call_history_merge (5)
- [x] Widget: MeshEligibilityDot (4)
- [x] flutter analyze clean for new files
- [x] Hardware smoke per success criteria in spec
- [ ] Reviewer eyes

🤖 Generated with [Claude Code](https://claude.com/claude-code)
```

- [ ] **Step 3: Address review feedback if any, merge into dev**

Either via GitHub web Merge button, or local `git merge --no-ff feature/mesh-voice-call-phase3d.2 -m "..."` + `git push origin dev`.

---

## Done criteria

When all 12 tasks are checked off:
1. Branch pushed, PR opened.
2. Hardware smoke passed on both devices (Steps 3-10 of Task 11).
3. ~543 unit/widget tests green; 3d.1 regression-clean.
4. `flutter analyze` clean for new + modified files.

After merge into `dev`, branch `feature/mesh-voice-call-phase3d.3` from `dev` for the Android foreground-service phase.

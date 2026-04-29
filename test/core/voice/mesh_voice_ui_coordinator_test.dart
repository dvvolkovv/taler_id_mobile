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
      await coord.placeCall(_peer(0));
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
}

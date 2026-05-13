import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:taler_id_mobile/core/mesh/crypto/mesh_datagram_cipher.dart';
import 'package:taler_id_mobile/core/mesh/services/envelope.dart';
import 'package:taler_id_mobile/core/mesh/services/mesh_messaging_service.dart';
import 'package:taler_id_mobile/core/mesh/transport/mesh_transport.dart';
import 'package:taler_id_mobile/core/mesh/transport/peer_id.dart';
import 'package:taler_id_mobile/core/mesh/voice/group_mesh_call_state.dart';

/// Maximum participants including self.
const int kGmcMaxParticipants = 5;
const int kGmcMaxInvitees = kGmcMaxParticipants - 1;

/// Orchestrator for one group mesh voice call at a time on this device.
///
/// Task 5 scope: state machine + signaling envelope dispatch via
/// [MeshMessagingService]. Audio engine wiring (Tasks 6-7) and Noise IK /
/// per-peer datagram routing land on top of this class incrementally —
/// they are NOT part of Task 5.
class GroupMeshCallService {
  GroupMeshCallService({
    required this.messaging,
    required this.transport,
    required this.myDevicePk,
    this.lobbyTimeout = const Duration(seconds: 30),
    Random? random,
  }) : _random = random ?? Random() {
    _inboundSub = messaging.inbound.listen(_onInbound);
    _datagramSub = transport.inboundDatagrams.listen(_onInboundDatagram);
  }

  /// Deterministic Noise-IK role assignment to avoid concurrent-handshake races.
  /// The peer with the numerically smaller devicePk byte-string is the sole
  /// initiator. Equal pks are a degenerate self-pair and yield false.
  static bool shouldInitiateNoise(Uint8List myPk, Uint8List peerPk) {
    if (myPk.length != peerPk.length) return false;
    for (var i = 0; i < myPk.length; i++) {
      if (myPk[i] < peerPk[i]) return true;
      if (myPk[i] > peerPk[i]) return false;
    }
    return false;
  }

  final MeshMessagingService messaging;
  final MeshTransport transport;
  final Uint8List myDevicePk;
  final Duration lobbyTimeout;
  final Random _random;

  GroupMeshCallState _state = const GMCIdle();
  final _stateCtrl = StreamController<GroupMeshCallState>.broadcast();
  StreamSubscription<InboundEnvelope>? _inboundSub;
  StreamSubscription<InboundDatagram>? _datagramSub;
  Timer? _lobbyTimer;

  final _peerCiphers =
      <String, ({MeshDatagramCipher outbound, MeshDatagramCipher inbound})>{};

  final _incomingInviteCtrl = StreamController<InboundEnvelope>.broadcast();

  GroupMeshCallState get state => _state;
  Stream<GroupMeshCallState> get stateStream => _stateCtrl.stream;
  Stream<InboundEnvelope> get incomingInviteStream =>
      _incomingInviteCtrl.stream;

  String get _myPkHex => _bytesToHex(myDevicePk);

  /// Host path: send invites to a map of {devicePkHex: userId}.
  Future<void> start({required Map<String, String> invitees}) async {
    if (_state is! GMCIdle) {
      throw StateError('Cannot start: not idle (current=$_state)');
    }
    if (invitees.length > kGmcMaxInvitees) {
      throw StateError(
        'Group calls are capped at $kGmcMaxInvitees invitees'
        ' ($kGmcMaxParticipants peers total)',
      );
    }
    final roomId = _generateRoomId();
    final participants = <GMCParticipant>[
      GMCParticipant(
        devicePk: _myPkHex,
        userId: 'self',
        status: GMCStatus.joined,
        isSelf: true,
      ),
      for (final e in invitees.entries)
        GMCParticipant(
          devicePk: e.key,
          userId: e.value,
          status: GMCStatus.calling,
        ),
    ];

    _emit(GMCInviting(roomId: roomId, invitees: participants));

    for (final entry in invitees.entries) {
      await messaging.sendEnvelope(
        toUserPk: PeerId.fromHex(entry.key),
        envelope: Envelope(
          version: 1,
          type: MeshGcEnvelopeType.invite,
          convId: roomId,
          clientId: _randomClientId(),
          text: '',
          sentAt: DateTime.now().toUtc(),
          extra: {
            'roomId': roomId,
            'hostDevicePk': _myPkHex,
            'participants': [for (final p in participants) p.devicePk],
            'startedAt': DateTime.now().toUtc().toIso8601String(),
          },
        ),
      );
    }

    _emit(GMCLobby(
      roomId: roomId,
      hostDevicePk: _myPkHex,
      roster: participants,
    ));
    _startLobbyTimer();
  }

  /// Invitee path — called after the user taps Accept on the native UI.
  Future<void> acceptInvite({
    required String roomId,
    required String hostDevicePkHex,
    required List<String> participantDevicePks,
  }) async {
    final roster = <GMCParticipant>[
      for (final pk in participantDevicePks)
        GMCParticipant(
          devicePk: pk,
          userId: pk == _myPkHex ? 'self' : 'unknown',
          status: pk == _myPkHex ? GMCStatus.joined : GMCStatus.calling,
          isSelf: pk == _myPkHex,
        ),
    ];
    _emit(GMCLobby(
      roomId: roomId,
      hostDevicePk: hostDevicePkHex,
      roster: roster,
    ));

    for (final p in roster) {
      if (p.isSelf) continue;
      await messaging.sendEnvelope(
        toUserPk: PeerId.fromHex(p.devicePk),
        envelope: Envelope(
          version: 1,
          type: MeshGcEnvelopeType.accept,
          convId: roomId,
          clientId: _randomClientId(),
          text: '',
          sentAt: DateTime.now().toUtc(),
          extra: {'roomId': roomId, 'devicePk': _myPkHex},
        ),
      );
    }
    _startLobbyTimer();
  }

  Future<void> declineInvite({
    required String roomId,
    required String hostDevicePkHex,
  }) async {
    await messaging.sendEnvelope(
      toUserPk: PeerId.fromHex(hostDevicePkHex),
      envelope: Envelope(
        version: 1,
        type: MeshGcEnvelopeType.decline,
        convId: roomId,
        clientId: _randomClientId(),
        text: '',
        sentAt: DateTime.now().toUtc(),
        extra: {'roomId': roomId, 'devicePk': _myPkHex},
      ),
    );
    _emit(const GMCIdle());
  }

  Future<void> leave() async {
    final s = _state;
    if (s is! GMCLobby && s is! GMCActive) return;
    _lobbyTimer?.cancel();
    final roomId = s is GMCLobby ? s.roomId : (s as GMCActive).roomId;
    final roster = s is GMCLobby ? s.roster : (s as GMCActive).roster;
    for (final p in roster) {
      if (p.isSelf) continue;
      await messaging.sendEnvelope(
        toUserPk: PeerId.fromHex(p.devicePk),
        envelope: Envelope(
          version: 1,
          type: MeshGcEnvelopeType.leave,
          convId: roomId,
          clientId: _randomClientId(),
          text: '',
          sentAt: DateTime.now().toUtc(),
          extra: {'roomId': roomId, 'devicePk': _myPkHex},
        ),
      );
    }
    _emit(const GMCEnded(reason: GMCEndReason.userHangup));
  }

  void _onInbound(InboundEnvelope evt) {
    final type = evt.envelope.type;
    if (!MeshGcEnvelopeType.isMeshGc(type)) return;
    final s = _state;
    final roomId = evt.envelope.extra?['roomId'] as String?;
    if (roomId == null) return;

    switch (type) {
      case MeshGcEnvelopeType.invite:
        _incomingInviteCtrl.add(evt);
        return;

      case MeshGcEnvelopeType.accept:
        if (s is! GMCLobby || s.roomId != roomId) return;
        final senderHex = evt.envelope.extra?['devicePk'] as String?;
        if (senderHex == null) return;
        final updated = s.roster
            .map((p) => p.devicePk == senderHex
                ? p.copyWith(status: GMCStatus.joined)
                : p)
            .toList();
        final allJoined = updated.every((p) => p.status == GMCStatus.joined);
        if (allJoined) {
          _lobbyTimer?.cancel();
          _emit(GMCActive(roomId: roomId, roster: updated, durationSec: 0));
        } else {
          _emit(s.copyWith(roster: updated));
        }
        return;

      case MeshGcEnvelopeType.decline:
        if (s is! GMCLobby || s.roomId != roomId) return;
        final senderHex = evt.envelope.extra?['devicePk'] as String?;
        if (senderHex == null) return;
        final updated = s.roster
            .map((p) => p.devicePk == senderHex
                ? p.copyWith(status: GMCStatus.declined)
                : p)
            .toList();
        final anyCallingOrJoined = updated.any((p) =>
            !p.isSelf &&
            (p.status == GMCStatus.calling ||
                p.status == GMCStatus.joined));
        if (!anyCallingOrJoined) {
          _lobbyTimer?.cancel();
          _emit(const GMCEnded(reason: GMCEndReason.allDeclined));
        } else {
          _emit(s.copyWith(roster: updated));
        }
        return;

      case MeshGcEnvelopeType.leave:
        final senderHex = evt.envelope.extra?['devicePk'] as String?;
        if (senderHex == null) return;
        _handlePeerGone(senderHex);
        return;

      case MeshGcEnvelopeType.keepalive:
        // Audio-engine task (Task 6/7) handles per-peer watchdog reset.
        return;
    }
  }

  void _handlePeerGone(String pkHex) {
    final s = _state;
    if (s is GMCActive) {
      final updated = s.roster.where((p) => p.devicePk != pkHex).toList();
      final othersRemain = updated.any((p) => !p.isSelf);
      if (!othersRemain) {
        _emit(const GMCEnded(reason: GMCEndReason.allLeft));
      } else {
        _emit(s.copyWith(roster: updated));
      }
    } else if (s is GMCLobby) {
      final updated = s.roster
          .map((p) =>
              p.devicePk == pkHex ? p.copyWith(status: GMCStatus.left) : p)
          .toList();
      _emit(s.copyWith(roster: updated));
    }
  }

  void _startLobbyTimer() {
    _lobbyTimer?.cancel();
    _lobbyTimer = Timer(lobbyTimeout, () {
      final s = _state;
      if (s is! GMCLobby) return;
      final anyJoined =
          s.roster.any((p) => !p.isSelf && p.status == GMCStatus.joined);
      if (anyJoined) {
        final filtered = s.roster
            .where((p) => p.isSelf || p.status == GMCStatus.joined)
            .toList();
        _emit(GMCActive(roomId: s.roomId, roster: filtered, durationSec: 0));
      } else {
        _emit(const GMCEnded(reason: GMCEndReason.noAnswer));
      }
    });
  }

  void _emit(GroupMeshCallState s) {
    _state = s;
    _stateCtrl.add(s);
    if (s is GMCActive) {
      unawaited(_bootstrapActiveSessions(s));
    }
  }

  void _onInboundDatagram(InboundDatagram dg) {
    // Audio path wired in Task 7. Task 6 leaves this empty.
  }

  Future<void> _bootstrapActiveSessions(GMCActive active) async {
    for (final p in active.roster) {
      if (p.isSelf) continue;
      final peerBytes = PeerId.fromHex(p.devicePk);
      final ciphers = await messaging.datagramCiphersFor(peerBytes);
      if (ciphers != null) {
        _peerCiphers[p.devicePk] = ciphers;
      }
      // null means Noise session not yet established. Task 7 will add a retry
      // loop. For Task 6 we simply skip — outbound encrypt will refuse for that
      // peer until ciphers materialise.
    }
  }

  String _generateRoomId() {
    final n = _random.nextInt(0xFFFFFFFF);
    return n.toRadixString(16).padLeft(8, '0');
  }

  String _randomClientId() =>
      DateTime.now().microsecondsSinceEpoch.toRadixString(36);

  Future<void> dispose() async {
    _lobbyTimer?.cancel();
    await _inboundSub?.cancel();
    await _datagramSub?.cancel();
    await _stateCtrl.close();
    await _incomingInviteCtrl.close();
  }
}

String _bytesToHex(Uint8List b) =>
    b.map((x) => x.toRadixString(16).padLeft(2, '0')).join();

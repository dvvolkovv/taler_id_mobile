import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:taler_id_mobile/core/audio/group_mesh_voice_audio_engine.dart';
import 'package:taler_id_mobile/core/mesh/crypto/mesh_datagram_cipher.dart';
import 'package:taler_id_mobile/core/mesh/services/envelope.dart';
import 'package:taler_id_mobile/core/mesh/services/mesh_messaging_service.dart';
import 'package:taler_id_mobile/core/mesh/transport/mesh_transport.dart';
import 'package:taler_id_mobile/core/mesh/transport/peer_id.dart';
import 'package:taler_id_mobile/core/mesh/voice/group_mesh_call_state.dart';
import 'package:taler_id_mobile/core/mesh/voice/mesh_voice_frame.dart';

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
    required this.audioEngineFactory,
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
  final GroupMeshVoiceAudioEngine Function() audioEngineFactory;
  final Duration lobbyTimeout;
  final Random _random;

  GroupMeshCallState _state = const GMCIdle();
  final _stateCtrl = StreamController<GroupMeshCallState>.broadcast();
  StreamSubscription<InboundEnvelope>? _inboundSub;
  StreamSubscription<InboundDatagram>? _datagramSub;
  Timer? _lobbyTimer;

  final _peerCiphers =
      <String, ({MeshDatagramCipher outbound, MeshDatagramCipher inbound})>{};
  // Bounded retry counter for `_bootstrapActiveSessions` so a peer whose
  // Noise session lands after GMCActive emit still gets audio ciphers.
  final _bootstrapRetryByRoom = <String, int>{};

  final _incomingInviteCtrl = StreamController<InboundEnvelope>.broadcast();

  GroupMeshVoiceAudioEngine? _audio;
  StreamSubscription<Uint8List>? _audioOutSub;
  bool _selfMuted = false;
  final _outboundSeqByPeer = <String, int>{};

  GroupMeshCallState get state => _state;

  /// True while a group mesh call is in progress (joining, active, in lobby,
  /// etc.). False only when the service is idle, ended, or in an error state.
  bool get isBusy =>
      _state is! GMCIdle && _state is! GMCEnded && _state is! GMCError;

  Stream<GroupMeshCallState> get stateStream => _stateCtrl.stream;
  Stream<InboundEnvelope> get incomingInviteStream =>
      _incomingInviteCtrl.stream;

  String get _myPkHex => _bytesToHex(myDevicePk);

  /// Host path: send invites to a map of {devicePkHex: userId}.
  /// [hostDisplayName] is included in the invite envelope so receivers can
  /// label the incoming-call UI with the inviter's current display name.
  Future<void> start({
    required Map<String, String> invitees,
    String? hostDisplayName,
  }) async {
    // Allow re-entry after a previous call ended (GMCEnded) or errored
    // (GMCError) — the service doesn't auto-revert to Idle. Without this,
    // starting a SECOND call after hanging up the first one fails with
    // "Cannot start: not idle" and surfaces as a generic GMCError in UI.
    if (_state is! GMCIdle && _state is! GMCEnded && _state is! GMCError) {
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

    // Per-invitee try/catch — `MultiTransport.send` throws StateError when the
    // peer isn't yet registered on any child transport (Bonjour resolve race).
    // Failing the whole loop strands the host in GMCInviting forever; instead
    // we mark the failed invitee as connectionFailed and continue, so the
    // lobby still renders and other peers can join.
    var lobbyRoster = participants;
    for (final entry in invitees.entries) {
      try {
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
              if (hostDisplayName != null && hostDisplayName.isNotEmpty)
                'hostDisplayName': hostDisplayName,
            },
          ),
        );
      } catch (e) {
        // Mark just this invitee as failed; do not abort the whole call.
        lobbyRoster = [
          for (final p in lobbyRoster)
            if (p.devicePk == entry.key)
              p.copyWith(status: GMCStatus.connectionFailed)
            else
              p,
        ];
      }
    }

    _emit(GMCLobby(
      roomId: roomId,
      hostDevicePk: _myPkHex,
      roster: lobbyRoster,
    ));
    _startLobbyTimer();
  }

  /// Invitee path — called after the user taps Accept on the native UI.
  /// [hostDisplayName] is the inviter's name from the invite envelope; we
  /// stamp it onto the host's GMCParticipant so the roster reads correctly.
  Future<void> acceptInvite({
    required String roomId,
    required String hostDevicePkHex,
    required List<String> participantDevicePks,
    String? hostDisplayName,
  }) async {
    // Host is implicitly joined (they're the one ringing us). Invitees other
    // than self start as "calling" and flip to "joined" as their accept
    // envelopes arrive.
    final roster = <GMCParticipant>[
      for (final pk in participantDevicePks)
        GMCParticipant(
          devicePk: pk,
          userId: pk == _myPkHex ? 'self' : 'unknown',
          status: pk == _myPkHex || pk == hostDevicePkHex
              ? GMCStatus.joined
              : GMCStatus.calling,
          isSelf: pk == _myPkHex,
          displayName: pk == hostDevicePkHex ? hostDisplayName : null,
        ),
    ];
    // Go straight to Active — the user already tapped Accept, the call is
    // live for them. _emit hooks _startAudio + _bootstrapActiveSessions on
    // the Active transition so audio engine and per-peer ciphers initialise
    // immediately instead of waiting for the lobby timeout.
    _emit(GMCActive(roomId: roomId, roster: roster, durationSec: 0));

    // Per-peer try/catch — invitee may not yet know all other participants'
    // transports (Bonjour resolve race); proceed with accept even if some
    // notifications drop, the host will see this invitee via its own delivery.
    for (final p in roster) {
      if (p.isSelf) continue;
      try {
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
      } catch (_) {
        // Peer transport not (yet) known — skip this fan-out notification.
      }
    }
    // Note: _startLobbyTimer is intentionally NOT called here — we already
    // emitted GMCActive, the no-answer/all-declined timeout only applies to
    // the host while it's waiting in GMCLobby.
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
    // Also accept Cancel during GMCInviting — host's invite fan-out may still
    // be in flight when the user taps Cancel; without this branch the press
    // is a no-op and the call is stuck until the lobby timer elapses.
    if (s is! GMCLobby && s is! GMCActive && s is! GMCInviting) return;
    _lobbyTimer?.cancel();
    final String roomId;
    final List<GMCParticipant> roster;
    if (s is GMCLobby) {
      roomId = s.roomId;
      roster = s.roster;
    } else if (s is GMCActive) {
      roomId = s.roomId;
      roster = s.roster;
    } else {
      // GMCInviting
      final inviting = s as GMCInviting;
      roomId = inviting.roomId;
      roster = inviting.invitees;
    }
    // Per-peer try/catch — a single StateError ("No transport knows ...")
    // would otherwise abort the loop before _emit(GMCEnded) and leave the
    // Cancel button effectively dead.
    for (final p in roster) {
      if (p.isSelf) continue;
      try {
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
      } catch (_) {
        // Peer transport not (yet) known — skip the leave notification.
      }
    }
    _emit(const GMCEnded(reason: GMCEndReason.userHangup));
  }

  Future<void> toggleMute() async {
    _selfMuted = !_selfMuted;
    final s = _state;
    if (s is GMCActive) {
      _emit(s.copyWith(selfMuted: _selfMuted));
    }
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
        final senderHex = evt.envelope.extra?['devicePk'] as String?;
        if (senderHex == null) return;
        // Two paths: first acceptor moves us from Lobby → Active immediately
        // (don't wait for everyone — late joiners stay as "calling" in the
        // roster until their own accept arrives). Subsequent accepts in
        // Active just flip that peer's status to joined.
        if (s is GMCLobby && s.roomId == roomId) {
          final updated = s.roster
              .map((p) => p.devicePk == senderHex
                  ? p.copyWith(status: GMCStatus.joined)
                  : p)
              .toList();
          _lobbyTimer?.cancel();
          _emit(GMCActive(roomId: roomId, roster: updated, durationSec: 0));
        } else if (s is GMCActive && s.roomId == roomId) {
          final updated = s.roster
              .map((p) => p.devicePk == senderHex
                  ? p.copyWith(status: GMCStatus.joined)
                  : p)
              .toList();
          // Reset the bootstrap retry budget — the new joiner needs a fresh
          // chance to derive Noise datagram ciphers, otherwise the per-room
          // counter (already exhausted by the original 12 s window) would
          // silently abandon late peers and they'd remain audio-isolated.
          _bootstrapRetryByRoom.remove(roomId);
          _emit(s.copyWith(roster: updated));
        }
        return;

      case MeshGcEnvelopeType.decline:
        // Decline may arrive while host is still in Lobby (no one accepted
        // yet) OR after host transitioned to Active because someone else
        // already joined — handle both.
        final senderHex = evt.envelope.extra?['devicePk'] as String?;
        if (senderHex == null) return;
        if (s is GMCLobby && s.roomId == roomId) {
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
        } else if (s is GMCActive && s.roomId == roomId) {
          final updated = s.roster
              .map((p) => p.devicePk == senderHex
                  ? p.copyWith(status: GMCStatus.declined)
                  : p)
              .toList();
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
    final previous = _state;
    _state = s;
    // Diagnostic trace — surfaces every state transition in adb/Xcode logs so
    // future "stuck on spinner" / "Cancel does nothing" reports have evidence
    // without needing to attach a debugger.
    debugPrint(
      '[mesh-gc] state: ${previous.runtimeType} → ${s.runtimeType}'
      '${s is GMCLobby ? " roomId=${s.roomId} roster=${s.roster.length}" : ""}'
      '${s is GMCActive ? " roomId=${s.roomId} roster=${s.roster.length}" : ""}'
      '${s is GMCEnded ? " reason=${s.reason}" : ""}'
      '${s is GMCError ? " msg=${s.message}" : ""}',
    );
    _stateCtrl.add(s);

    if (s is GMCActive && previous is! GMCActive) {
      unawaited(_startAudio(s));
    } else if (s is! GMCActive && previous is GMCActive) {
      unawaited(_stopAudio());
    }
    if (s is GMCActive) {
      unawaited(_bootstrapActiveSessions(s));
    }
  }

  Future<void> _startAudio(GMCActive active) async {
    final engine = audioEngineFactory();
    _audio = engine;
    await engine.start();
    for (final p in active.roster) {
      if (p.isSelf) continue;
      engine.addPeer(p.devicePk);
      _outboundSeqByPeer[p.devicePk] = 0;
    }
    _audioOutSub = engine.outbound.listen(_onEncodedAudioFrame);
  }

  Future<void> _stopAudio() async {
    await _audioOutSub?.cancel();
    _audioOutSub = null;
    await _audio?.stop();
    await _audio?.dispose();
    _audio = null;
    _peerCiphers.clear();
    _outboundSeqByPeer.clear();
    _bootstrapRetryByRoom.clear();
  }

  Future<void> _onEncodedAudioFrame(Uint8List opusPayload) async {
    final s = _state;
    if (s is! GMCActive) return;
    if (_selfMuted) return;
    final roomIdInt = int.parse(s.roomId, radix: 16);
    for (final p in s.roster) {
      if (p.isSelf) continue;
      final ciphers = _peerCiphers[p.devicePk];
      if (ciphers == null) continue;
      final seq = (_outboundSeqByPeer[p.devicePk] ?? 0) + 1;
      _outboundSeqByPeer[p.devicePk] = seq;
      try {
        final ciphertext = await ciphers.outbound.encrypt(
          seq: seq,
          plaintext: opusPayload,
        );
        final frame = MeshVoiceFrame(
          type: MeshVoiceFrameType.audio,
          callId: roomIdInt,
          seq: seq,
          ciphertext: ciphertext,
        ).encode();
        unawaited(transport.sendDatagram(PeerId.fromHex(p.devicePk), frame));
      } catch (_) {
        // Encrypt or send failure for this peer this frame — skip silently.
        // Next frame will retry.
      }
    }
  }

  Future<void> _onInboundDatagram(InboundDatagram dg) async {
    final engine = _audio;
    if (engine == null) return;
    final s = _state;
    if (s is! GMCActive) return;
    final MeshVoiceFrame frame;
    try {
      frame = MeshVoiceFrame.decode(dg.bytes);
    } catch (_) {
      return;
    }
    final roomIdInt = int.parse(s.roomId, radix: 16);
    if (frame.callId != roomIdInt) return;
    if (frame.type != MeshVoiceFrameType.audio) return;

    final senderHex = dg.srcPeer.toHex();
    final ciphers = _peerCiphers[senderHex];
    if (ciphers == null) return;
    try {
      final plaintext = await ciphers.inbound.decrypt(
        seq: frame.seq,
        ciphertext: frame.ciphertext,
      );
      engine.inbound(senderHex, seq: frame.seq, payload: plaintext);
    } catch (_) {
      // Decrypt failure (replay / MAC mismatch / cipher missing) — drop.
    }
  }

  Future<void> _bootstrapActiveSessions(GMCActive active) async {
    final missingPeers = <String>[];
    for (final p in active.roster) {
      if (p.isSelf) continue;
      if (_peerCiphers.containsKey(p.devicePk)) continue;
      final peerBytes = PeerId.fromHex(p.devicePk);
      final ciphers = await messaging.datagramCiphersFor(peerBytes);
      if (ciphers != null) {
        _peerCiphers[p.devicePk] = ciphers;
      } else {
        missingPeers.add(p.devicePk);
      }
    }
    // For non-host peers, the only Noise sessions established during invite
    // exchange are with the HOST. Pair-wise sessions between invitees never
    // get bootstrapped — so audio in either direction silently drops because
    // datagramCiphersFor returns null forever. Send a keepalive envelope to
    // each missing peer; messaging.sendEnvelope kicks off a Noise handshake
    // when no session exists, after which the next retry tick of this method
    // will pick up the freshly-derived ciphers.
    for (final pkHex in missingPeers) {
      unawaited(
        messaging.sendEnvelope(
          toUserPk: PeerId.fromHex(pkHex),
          envelope: Envelope(
            version: 1,
            type: MeshGcEnvelopeType.keepalive,
            convId: active.roomId,
            clientId: _randomClientId(),
            text: '',
            sentAt: DateTime.now().toUtc(),
            extra: {'roomId': active.roomId, 'devicePk': _myPkHex},
          ),
        ).catchError((_) {
          // "No transport knows ..." (still resolving Bonjour) — retry tick
          // picks it up once the peer's address materialises.
        }),
      );
    }
    if (missingPeers.isEmpty) return;
    final attempt = (_bootstrapRetryByRoom[active.roomId] ?? 0) + 1;
    _bootstrapRetryByRoom[active.roomId] = attempt;
    // ~12 s total: 6 retries × 2 s. Audio dialer drops the call anyway after
    // its own watchdog, so bounded retry is fine.
    if (attempt > 6) return;
    await Future<void>.delayed(const Duration(seconds: 2));
    final s = _state;
    if (s is! GMCActive || s.roomId != active.roomId) return;
    unawaited(_bootstrapActiveSessions(s));
  }

  String _generateRoomId() {
    final n = _random.nextInt(0xFFFFFFFF);
    return n.toRadixString(16).padLeft(8, '0');
  }

  String _randomClientId() =>
      DateTime.now().microsecondsSinceEpoch.toRadixString(36);

  Future<void> dispose() async {
    _lobbyTimer?.cancel();
    await _stopAudio();
    await _inboundSub?.cancel();
    await _datagramSub?.cancel();
    await _stateCtrl.close();
    await _incomingInviteCtrl.close();
  }
}

String _bytesToHex(Uint8List b) =>
    b.map((x) => x.toRadixString(16).padLeft(2, '0')).join();

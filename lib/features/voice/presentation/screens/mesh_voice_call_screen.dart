import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/mesh/transport/peer_id.dart';
import '../../../../core/mesh/voice/mesh_voice_state.dart';
import '../../../../l10n/app_localizations.dart';
import '../widgets/pulsing_avatar.dart';

class MeshVoiceCallScreen extends StatefulWidget {
  final Stream<CallState> stateStream;
  final CallState? initialState; // current snapshot (broadcast stream doesn't replay)
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
    this.initialState,
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
    final initial = widget.initialState;
    if (initial != null && initial is! IdleState) {
      // Apply the snapshot immediately so a screen pushed AFTER an
      // ActiveState was already emitted on the broadcast stream still
      // sees the timer / status text.
      _onState(initial);
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    _ticker?.cancel();
    _popTimer?.cancel();
    super.dispose();
  }

  void _onState(CallState st) {
    // Ignore IdleState after EndedState — service auto-resets to Idle 2s
    // post-Ended so the next call can proceed, but the screen should
    // keep showing the "ended" status until popDelay fires.
    if (_state is EndedState && st is IdleState) return;
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

  String _displayName(AppLocalizations l10n) {
    final n = widget.peerName;
    if (n != null && n.isNotEmpty) return n;
    return l10n.meshDeviceFallback(widget.peer.toHex().substring(0, 8));
  }

  String _statusText(AppLocalizations l10n) {
    final st = _state;
    if (st is InvitingState) return l10n.meshCallStatusInviting;
    if (st is ConnectingState) return l10n.meshCallStatusConnecting;
    if (st is ActiveState) {
      final m = _activeElapsed.inMinutes;
      final s = _activeElapsed.inSeconds % 60;
      return '$m:${s.toString().padLeft(2, '0')}';
    }
    if (st is EndedState) {
      switch (st.reason) {
        case EndReason.userHangup:
          return l10n.meshCallEndedUserHangup;
        case EndReason.remoteHangup:
          return l10n.meshCallEndedRemoteHangup;
        case EndReason.rejectedByCallee:
          return l10n.meshCallEndedRejected;
        case EndReason.inviteTimeout:
          return l10n.meshCallEndedNoAnswer;
        case EndReason.noKeepalive:
        case EndReason.peerLost:
          return l10n.meshCallEndedConnectionLost;
        case EndReason.setupTimeout:
        case EndReason.error:
          return l10n.meshCallEndedError;
      }
    }
    return '';
  }

  String _transportBadge(AppLocalizations l10n) {
    final t = widget.transportName;
    return t != null
        ? l10n.meshCallTransportBadge(t)
        : l10n.meshCallTransportBadgePlain;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final avatarUrl = widget.peerAvatarUrl;
    final displayName = _displayName(l10n);
    return Scaffold(
      backgroundColor: Colors.black87,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 60),
            PulsingAvatar(
              radius: 64,
              glowColor: rainbowColorFor(widget.peer.toHex()),
              child: CircleAvatar(
                radius: 64,
                backgroundColor: Colors.white24,
                child: (avatarUrl != null && avatarUrl.isNotEmpty)
                    ? ClipOval(
                        child: Image.network(
                          avatarUrl,
                          width: 128,
                          height: 128,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Text(
                            displayName.substring(0, 1).toUpperCase(),
                            style: const TextStyle(
                                fontSize: 36, color: Colors.white),
                          ),
                        ),
                      )
                    : Text(displayName.substring(0, 1).toUpperCase(),
                        style: const TextStyle(
                            fontSize: 36, color: Colors.white)),
              ),
            ),
            const SizedBox(height: 24),
            Text(displayName,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(_statusText(l10n),
                style:
                    const TextStyle(color: Colors.white70, fontSize: 16)),
            const SizedBox(height: 12),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white12,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(_transportBadge(l10n),
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

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/config/mesh_config.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/mesh/crypto/keys/mesh_static_key.dart';
import '../../../../core/mesh/services/envelope.dart';
import '../../../../core/mesh/services/mesh_messaging_service.dart';
import '../../../../core/mesh/transport/bonjour_transport.dart';
import '../../../../core/mesh/transport/mesh_transport.dart';
import '../../../../core/mesh/transport/peer_id.dart';
import '../../../messenger/data/services/pending_mesh_send_queue.dart';

/// Phase 1d debug screen — live visibility into the mesh transport + Noise
/// messaging stack. Start/stop the stack, see discovered peers, send test
/// messages, watch incoming ones.
class MeshDebugScreen extends StatefulWidget {
  const MeshDebugScreen({super.key});

  @override
  State<MeshDebugScreen> createState() => _MeshDebugScreenState();
}

class _MeshDebugScreenState extends State<MeshDebugScreen> {
  late final MeshTransport _transport;
  late final MeshStaticKey _meshKey;

  MeshMessagingService? _messaging;

  bool _running = false;
  String? _lastError;

  final Map<PeerId, _PeerEntry> _peers = {};
  final List<_LogEntry> _messages = [];
  StreamSubscription<PeerDiscovered>? _discoverySub;
  StreamSubscription<PeerLost>? _lossSub;
  StreamSubscription<InboundEnvelope>? _inboundSub;
  Timer? _refreshTicker;

  @override
  void initState() {
    super.initState();
    _transport = sl<MeshTransport>();
    _meshKey = sl<MeshStaticKey>();
    // Mesh Debug counters (Pending / Resets / Reinits) read fresh from DI on
    // each rebuild. Outbound mesh-fanout, supervisor reinits, and peer
    // resets on the receive side don't always coincide with a discovery /
    // inbound event, so we drive a 1 Hz tick to keep the status card honest.
    _refreshTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {});
    });
  }

  @override
  void dispose() {
    _refreshTicker?.cancel();
    _discoverySub?.cancel();
    _lossSub?.cancel();
    _inboundSub?.cancel();
    super.dispose();
  }

  Future<void> _start() async {
    setState(() => _lastError = null);
    try {
      // Phase 1i — reuse the shared DI MeshMessagingService that was
      // started by AuthBloc / runMeshBootstrap at login. Do NOT call
      // start() again here — it would replace the app's main Bonjour
      // advertisement (taler-mesh-<userId>) with a taler-mesh-debug-*
      // one, breaking mesh for the rest of the app until logout.
      //
      // We still attach our own listeners to visualize live traffic.
      final messaging = sl.isRegistered<MeshMessagingService>()
          ? sl<MeshMessagingService>()
          : null;
      if (messaging == null) {
        setState(() {
          _lastError =
              'MeshMessagingService not registered — log out and back in.';
        });
        return;
      }
      _messaging = messaging;

      _inboundSub = messaging.inbound.listen((msg) {
        final prefix = msg.fromUserPk.toHex().substring(0, 16);
        setState(() => _messages.insert(
              0,
              _LogEntry(
                text: '← $prefix: ${msg.envelope.text}',
                timestamp: DateTime.now(),
              ),
            ));
      });

      _discoverySub = _transport.discoveries.listen((event) {
        // Debug screen reflects discoveries live. The actual
        // ContactKeyStore population is handled by DeviceKeySyncService
        // (Phase 1f+1g bridge) — the debug screen no longer touches the
        // main trust graph to avoid diverging from what the messenger
        // uses at runtime.
        setState(() {
          _peers[event.peerId] = _PeerEntry(
            peerId: event.peerId,
            host: event.host,
            port: event.port,
            attributes: event.attributes,
            discoveredAt: DateTime.now(),
            canMessage: (event.attributes['pk'] ?? '').length == 64,
          );
        });
      });
      _lossSub = _transport.losses.listen((event) {
        setState(() => _peers.remove(event.peerId));
      });

      setState(() => _running = true);
    } catch (e, st) {
      debugPrint('[mesh-debug] start failed: $e\n$st');
      setState(() {
        _lastError = e.toString();
        _running = false;
      });
    }
  }

  Future<void> _stop() async {
    // Phase 1i — we don't own the DI MeshMessagingService / transport.
    // Just detach our listeners; the shared services keep running for
    // the messenger layer.
    await _discoverySub?.cancel();
    await _lossSub?.cancel();
    await _inboundSub?.cancel();
    _discoverySub = null;
    _lossSub = null;
    _inboundSub = null;
    _messaging = null;
    setState(() {
      _running = false;
      _peers.clear();
    });
  }

  Future<void> _sendTestMessage(PeerId peer) async {
    final messaging = _messaging;
    if (messaging == null) return;
    final myPrefix = PeerId(_meshKey.publicKey).toHex().substring(0, 8);
    final text = 'Hello from $myPrefix @ ${DateTime.now().toIso8601String().substring(11, 19)}';
    try {
      await messaging.sendEnvelope(
        toUserPk: peer,
        envelope: Envelope(
          version: 1,
          type: 'text',
          convId: 'debug',
          clientId: const Uuid().v4(),
          text: text,
          sentAt: DateTime.now().toUtc(),
        ),
      );
      final peerPrefix = peer.toHex().substring(0, 16);
      setState(() => _messages.insert(
            0,
            _LogEntry(
              text: '→ $peerPrefix: $text',
              timestamp: DateTime.now(),
            ),
          ));
    } catch (e) {
      setState(() => _messages.insert(
            0,
            _LogEntry(
              text: '⚠ send failed: $e',
              timestamp: DateTime.now(),
            ),
          ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final myPkHex = PeerId(_meshKey.publicKey).toHex();
    final myPrefix = myPkHex.substring(0, 16);

    return Scaffold(
      appBar: AppBar(title: const Text('Mesh Debug')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _StatusCard(
              running: _running,
              bleEnabled: MeshConfig.bleEnabled,
              myPrefix: myPrefix,
              peerCount: _peers.length,
              pendingCount: sl.isRegistered<PendingMeshSendQueue>()
                  ? sl<PendingMeshSendQueue>().pendingCount
                  : 0,
              resetCountTotal: sl.isRegistered<MeshMessagingService>()
                  ? sl<MeshMessagingService>().peerResetCountTotal
                  : 0,
              discoveryReinitCount: sl.isRegistered<BonjourTransport>()
                  ? sl<BonjourTransport>().discoveryReinitCount
                  : 0,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: Icon(_running ? Icons.stop : Icons.play_arrow),
                    label: Text(_running ? 'Stop' : 'Start'),
                    onPressed: _running ? _stop : _start,
                  ),
                ),
              ],
            ),
            if (_lastError != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _lastError!,
                  style: const TextStyle(color: Colors.redAccent),
                ),
              ),
            ],
            const SizedBox(height: 16),
            Text(
              'Peers (${_peers.length})',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            if (_peers.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'No peers. Start and make sure the other device is also running.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              )
            else
              ..._peers.values.map((p) => _PeerTile(
                    entry: p,
                    onSendTest: p.canMessage ? () => _sendTestMessage(p.peerId) : null,
                  )),
            const SizedBox(height: 16),
            Text(
              'Messages (${_messages.length})',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Expanded(
              child: _messages.isEmpty
                  ? const Center(
                      child: Text(
                        'No messages yet. Tap "Send test" on a peer.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView(
                      children: _messages
                          .map((m) => _MessageTile(entry: m))
                          .toList(),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PeerEntry {
  final PeerId peerId;
  final String host;
  final int port;
  final Map<String, String> attributes;
  final DateTime discoveredAt;
  final bool canMessage;

  _PeerEntry({
    required this.peerId,
    required this.host,
    required this.port,
    required this.attributes,
    required this.discoveredAt,
    required this.canMessage,
  });
}

class _LogEntry {
  final String text;
  final DateTime timestamp;
  _LogEntry({required this.text, required this.timestamp});
}

class _StatusCard extends StatelessWidget {
  final bool running;
  final bool bleEnabled;
  final String myPrefix;
  final int peerCount;
  final int pendingCount;
  final int resetCountTotal;
  final int discoveryReinitCount;

  const _StatusCard({
    required this.running,
    required this.bleEnabled,
    required this.myPrefix,
    required this.peerCount,
    required this.pendingCount,
    required this.resetCountTotal,
    required this.discoveryReinitCount,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  running ? Icons.radio_button_checked : Icons.radio_button_off,
                  color: running ? Colors.green : Colors.grey,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  running ? 'Running' : 'Stopped',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 8),
            _kv('BLE', bleEnabled ? 'ON' : 'off'),
            _kv('Me', myPrefix),
            _kv('Peers', '$peerCount'),
            _kv('Pending', '$pendingCount'),
            _kv('Resets', '$resetCountTotal (60s)'),
            _kv('Reinits', '$discoveryReinitCount'),
          ],
        ),
      ),
    );
  }

  Widget _kv(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 1),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 80,
              child: Text(
                k,
                style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
              ),
            ),
            Expanded(
              child: Text(
                v,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
              ),
            ),
          ],
        ),
      );
}

class _PeerTile extends StatelessWidget {
  final _PeerEntry entry;
  final VoidCallback? onSendTest;
  const _PeerTile({required this.entry, required this.onSendTest});

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
        title: Text(prefix, style: const TextStyle(fontFamily: 'monospace', fontSize: 13)),
        subtitle: Text(
          '$transport  ·  ${entry.host}:${entry.port}',
          style: const TextStyle(fontSize: 11),
        ),
        trailing: onSendTest != null
            ? TextButton(
                onPressed: onSendTest,
                child: const Text('Send test'),
              )
            : const Text(
                'no pk',
                style: TextStyle(fontSize: 10, color: Colors.grey),
              ),
      ),
    );
  }
}

class _MessageTile extends StatelessWidget {
  final _LogEntry entry;
  const _MessageTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    final ts = entry.timestamp.toIso8601String().substring(11, 19);
    final isIn = entry.text.startsWith('←');
    final isErr = entry.text.startsWith('⚠');
    final color = isErr
        ? Colors.redAccent
        : isIn
            ? Colors.lightBlueAccent
            : Colors.greenAccent;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            ts,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 10,
              color: Colors.grey,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              entry.text,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

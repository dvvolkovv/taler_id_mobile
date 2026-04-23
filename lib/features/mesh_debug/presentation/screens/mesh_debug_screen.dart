import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/config/mesh_config.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/mesh/crypto/keys/mesh_static_key.dart';
import '../../../../core/mesh/transport/mesh_transport.dart';
import '../../../../core/mesh/transport/peer_id.dart';

/// Phase 1d debug screen — live visibility into the mesh transport layer.
///
/// Lets a developer start/stop the MeshTransport (Bonjour + BLE via
/// MultiTransport), see discovered peers in real time, and verify basic
/// advertising + scanning on real hardware.
///
/// Enable with `--dart-define=MESH_BLE_ENABLED=true` to activate the BLE
/// child transport.
class MeshDebugScreen extends StatefulWidget {
  const MeshDebugScreen({super.key});

  @override
  State<MeshDebugScreen> createState() => _MeshDebugScreenState();
}

class _MeshDebugScreenState extends State<MeshDebugScreen> {
  late final MeshTransport _transport;
  late final MeshStaticKey _meshKey;

  bool _running = false;
  String? _lastError;

  final Map<PeerId, _PeerEntry> _peers = {};
  StreamSubscription<PeerDiscovered>? _discoverySub;
  StreamSubscription<PeerLost>? _lossSub;

  @override
  void initState() {
    super.initState();
    _transport = sl<MeshTransport>();
    _meshKey = sl<MeshStaticKey>();
  }

  @override
  void dispose() {
    _discoverySub?.cancel();
    _lossSub?.cancel();
    super.dispose();
  }

  Future<void> _start() async {
    setState(() => _lastError = null);
    try {
      _discoverySub = _transport.discoveries.listen((event) {
        setState(() {
          _peers[event.peerId] = _PeerEntry(
            peerId: event.peerId,
            host: event.host,
            port: event.port,
            attributes: event.attributes,
            discoveredAt: DateTime.now(),
          );
        });
      });
      _lossSub = _transport.losses.listen((event) {
        setState(() => _peers.remove(event.peerId));
      });

      await _transport.startAdvertising(DeviceInfo(
        devicePk: PeerId(_meshKey.publicKey),
        serviceName: 'taler-mesh-debug-${DateTime.now().millisecondsSinceEpoch}',
      ));
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
    try {
      await _transport.stopAdvertising();
    } catch (e) {
      debugPrint('[mesh-debug] stop error: $e');
    }
    await _discoverySub?.cancel();
    await _lossSub?.cancel();
    _discoverySub = null;
    _lossSub = null;
    setState(() {
      _running = false;
      _peers.clear();
    });
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
            ),
            const SizedBox(height: 16),
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
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
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
            const SizedBox(height: 24),
            Text(
              'Discovered peers (${_peers.length})',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _peers.isEmpty
                  ? const Center(
                      child: Text(
                        'No peers yet.\nStart the transport and\nmake sure the other device is running.',
                        textAlign: TextAlign.center,
                      ),
                    )
                  : ListView(
                      children: _peers.values
                          .map((p) => _PeerTile(entry: p))
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

  _PeerEntry({
    required this.peerId,
    required this.host,
    required this.port,
    required this.attributes,
    required this.discoveredAt,
  });
}

class _StatusCard extends StatelessWidget {
  final bool running;
  final bool bleEnabled;
  final String myPrefix;
  final int peerCount;

  const _StatusCard({
    required this.running,
    required this.bleEnabled,
    required this.myPrefix,
    required this.peerCount,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  running ? Icons.radio_button_checked : Icons.radio_button_off,
                  color: running ? Colors.green : Colors.grey,
                ),
                const SizedBox(width: 8),
                Text(
                  running ? 'Transport running' : 'Transport stopped',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 12),
            _kv('BLE enabled', bleEnabled ? 'YES' : 'NO (compile flag off)'),
            _kv('My devicePk prefix', myPrefix),
            _kv('Peers seen', '$peerCount'),
          ],
        ),
      ),
    );
  }

  Widget _kv(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 140,
              child: Text(
                k,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
            Expanded(
              child: Text(
                v,
                style: const TextStyle(fontFamily: 'monospace'),
              ),
            ),
          ],
        ),
      );
}

class _PeerTile extends StatelessWidget {
  final _PeerEntry entry;
  const _PeerTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    final blePrefix = entry.attributes['ble_prefix'];
    final transport = blePrefix != null ? 'BLE' : 'Bonjour';
    final prefix = entry.peerId.toHex().substring(0, 16);
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: transport == 'BLE' ? Colors.blue : Colors.orange,
          child: Text(
            transport == 'BLE' ? 'B' : 'W',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          prefix,
          style: const TextStyle(fontFamily: 'monospace'),
        ),
        subtitle: Text(
          '$transport  ·  ${entry.host}:${entry.port}',
          style: const TextStyle(fontSize: 12),
        ),
        trailing: Text(
          _age(entry.discoveredAt),
          style: const TextStyle(fontSize: 11, color: Colors.grey),
        ),
      ),
    );
  }

  String _age(DateTime t) {
    final s = DateTime.now().difference(t).inSeconds;
    if (s < 60) return '${s}s ago';
    return '${s ~/ 60}m ago';
  }
}

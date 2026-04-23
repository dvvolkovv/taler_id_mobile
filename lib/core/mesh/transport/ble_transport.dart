import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_ble_peripheral/flutter_ble_peripheral.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:permission_handler/permission_handler.dart';

import 'ble/ble_connection.dart';
import 'ble/ble_gatt_protocol.dart';
import 'ble/ble_peer_registry.dart';
import 'frame.dart';
import 'mesh_transport.dart';
import 'peer_id.dart';

/// BLE-based MeshTransport. Implements discovery (advertising + scanning)
/// and full-duplex data (GATT write / notify).
///
/// Phase 1d scope: 100% active scan, foreground only, lexicographic
/// connection tiebreak. See design doc §5 for wire format details.
///
/// ### Plugin API notes (actual vs. draft)
/// - `flutter_ble_peripheral` 2.1.0: `FlutterBlePeripheral.stop()` returns
///   `Future<BluetoothPeripheralState>` (not `Future<void>`). Return value
///   is intentionally discarded here.
/// - `flutter_reactive_ble` 5.4.1: `subscribeToCharacteristic` returns
///   `Stream<List<int>>` (not `Stream<Uint8List>`). Converted with
///   `Uint8List.fromList` at the call-site.
/// - `writeCharacteristicWithoutResponse` takes `List<int>` — `Uint8List`
///   satisfies this because `Uint8List implements List<int>`.
/// - `scanForDevices` requires `List<Uuid>` — `Uuid.parse(...)` used from
///   the reactive_ble platform interface.
class BleTransport implements MeshTransport {
  final _discoveriesCtrl = StreamController<PeerDiscovered>.broadcast();
  final _lossesCtrl = StreamController<PeerLost>.broadcast();
  final _inboundCtrl = StreamController<InboundFrame>.broadcast();

  final FlutterReactiveBle _central = FlutterReactiveBle();
  final FlutterBlePeripheral _peripheral = FlutterBlePeripheral();

  BlePeerRegistry? _registry;
  StreamSubscription<DiscoveredDevice>? _scanSub;
  final Map<PeerId, StreamSubscription<ConnectionStateUpdate>> _connectionSubs =
      {};
  final Map<PeerId, StreamSubscription<List<int>>> _notifySubs = {};
  final Map<PeerId, FrameReassembler> _reassemblers = {};
  final Map<PeerId, DiscoveredDevice> _deviceCache = {};
  final Set<PeerId> _seenPeers = {};

  bool _started = false;

  @override
  Stream<PeerDiscovered> get discoveries => _discoveriesCtrl.stream;
  @override
  Stream<PeerLost> get losses => _lossesCtrl.stream;
  @override
  Stream<InboundFrame> get inbound => _inboundCtrl.stream;

  @override
  Future<void> startAdvertising(DeviceInfo self) async {
    if (_started) return;
    _registry = BlePeerRegistry(selfPk: self.devicePk);

    final granted = await _ensurePermissions();
    if (!granted) {
      debugPrint('[ble] permissions denied — transport disabled');
      return;
    }

    final mfgData = BleConnection.buildAdvertisementData(
      devicePkFull: self.devicePk.bytes,
    );

    // flutter_ble_peripheral 2.1.0: AdvertiseData accepts serviceUuid (String)
    // and manufacturerData (Uint8List) + manufacturerId (int).
    await _peripheral.start(
      advertiseData: AdvertiseData(
        serviceUuid: BleGattProtocol.serviceUuid,
        manufacturerId: 0xFFFF,
        manufacturerData: mfgData,
      ),
    );

    // flutter_reactive_ble 5.4.1: scanForDevices takes List<Uuid>.
    _scanSub = _central
        .scanForDevices(
            withServices: [Uuid.parse(BleGattProtocol.serviceUuid)])
        .listen(
          _handleScanResult,
          onError: (Object e) => debugPrint('[ble] scan error: $e'),
        );

    _started = true;
    debugPrint('[ble] started advertising + scanning');
  }

  Future<bool> _ensurePermissions() async {
    final needed = <Permission>[
      Permission.bluetoothAdvertise,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
    ];
    for (final p in needed) {
      final status = await p.request();
      if (!status.isGranted) return false;
    }
    return true;
  }

  void _handleScanResult(DiscoveredDevice device) {
    final mfg = device.manufacturerData;
    final parsed = BleConnection.parseAdvertisementData(mfg);
    if (parsed == null) return;
    // We only know the 8-byte prefix from the advertisement. The full
    // PeerId is learned during the Noise handshake. Phase 1d: identify
    // the peer by the prefix tag stored in `attributes`.
    //
    // Phase 1d note: the 8-byte prefix space is birthday-sparse for small
    // mesh networks (< 100 devices, collision probability < 10^-14). If two
    // peers collide, the second overwrites the first in `_deviceCache` —
    // documented as an accepted limitation. Phase 1e remaps to the full
    // 32-byte PeerId once the Noise handshake learns it.
    final placeholder = _placeholderPeerId(parsed.devicePkPrefix);
    _deviceCache[placeholder] = device;

    // Dedup: BLE scans re-emit the same device on every advertising
    // interval. We only surface PeerDiscovered once per peer.
    if (!_seenPeers.add(placeholder)) return;

    final prefixHex = parsed.devicePkPrefix
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join();
    _discoveriesCtrl.add(PeerDiscovered(
      peerId: placeholder,
      host: device.id,
      port: 0,
      attributes: {'ble_prefix': prefixHex},
    ));
  }

  /// Build a synthetic 32-byte PeerId from the 8-byte prefix. Upper
  /// layers treat this opaquely until the Noise handshake learns the
  /// real 32-byte static key.
  PeerId _placeholderPeerId(Uint8List prefix) {
    final bytes = Uint8List(32);
    bytes.setRange(0, 8, prefix);
    return PeerId(bytes);
  }

  @override
  Future<void> connectTo(PeerId peer) async {
    if (!_started) throw StateError('BleTransport not started');
    if (!(_registry!.shouldInitiate(peer))) {
      debugPrint('[ble] skip connect — peer has lower pk, waiting inbound');
      return;
    }
    final device = _deviceCache[peer];
    if (device == null) {
      throw StateError('Unknown BLE device for peer $peer');
    }

    _registry!.mark(peer, BleLinkState.connecting);
    final sub = _central
        .connectToDevice(id: device.id)
        .listen((update) => _handleConnectionState(peer, update));
    _connectionSubs[peer] = sub;
  }

  void _handleConnectionState(PeerId peer, ConnectionStateUpdate update) {
    switch (update.connectionState) {
      case DeviceConnectionState.connected:
        _registry!.mark(peer, BleLinkState.connected);
        _reassemblers[peer] = FrameReassembler()
          ..onFrame = (bytes) => _inboundCtrl.add(
                InboundFrame(
                  srcPeer: peer,
                  type: FrameType.data,
                  bytes: bytes,
                ),
              );
        _subscribeCharacteristic(peer);
        break;
      case DeviceConnectionState.disconnected:
        _registry!.forget(peer);
        _reassemblers.remove(peer);
        _lossesCtrl.add(PeerLost(peer));
        _connectionSubs[peer]?.cancel();
        _connectionSubs.remove(peer);
        _notifySubs[peer]?.cancel();
        _notifySubs.remove(peer);
        break;
      case DeviceConnectionState.connecting:
      case DeviceConnectionState.disconnecting:
        break;
    }
  }

  void _subscribeCharacteristic(PeerId peer) {
    final device = _deviceCache[peer]!;
    final ch = QualifiedCharacteristic(
      serviceId: Uuid.parse(BleGattProtocol.serviceUuid),
      characteristicId: Uuid.parse(BleGattProtocol.characteristicUuid),
      deviceId: device.id,
    );
    // flutter_reactive_ble 5.4.1: subscribeToCharacteristic returns
    // Stream<List<int>>, not Stream<Uint8List> — convert at the call-site.
    // The returned subscription is tracked in _notifySubs so it is cancelled
    // on disconnect/dispose.
    _notifySubs[peer] = _central.subscribeToCharacteristic(ch).listen(
          (bytes) => _reassemblers[peer]?.feed(Uint8List.fromList(bytes)),
          onError: (Object e) => debugPrint('[ble] subscribe error: $e'),
        );
  }

  @override
  Future<void> send(PeerId peer, Uint8List data) async {
    if (!_started) throw StateError('BleTransport not started');
    final device = _deviceCache[peer];
    if (device == null) throw StateError('No BLE device for peer $peer');
    final ch = QualifiedCharacteristic(
      serviceId: Uuid.parse(BleGattProtocol.serviceUuid),
      characteristicId: Uuid.parse(BleGattProtocol.characteristicUuid),
      deviceId: device.id,
    );
    final wire = BleGattProtocol.encodeFrame(data);
    // MTU negotiation is library-internal; we chunk conservatively at 20B.
    final chunks = BleGattProtocol.chunkForMtu(wire, mtu: 20);
    for (final chunk in chunks) {
      // writeCharacteristicWithoutResponse takes List<int>; Uint8List satisfies
      // this contract without conversion.
      await _central.writeCharacteristicWithoutResponse(ch, value: chunk);
    }
  }

  @override
  Future<void> stopAdvertising() async {
    if (!_started) return;
    try {
      // flutter_ble_peripheral 2.1.0: stop() returns Future<BluetoothPeripheralState>.
      // Return value intentionally discarded — we only care about side effects.
      await _peripheral.stop();
    } catch (e) {
      debugPrint('[ble] stop peripheral failed: $e');
    }
    await _scanSub?.cancel();
    _scanSub = null;
    _started = false;
  }

  @override
  Future<void> dispose() async {
    await stopAdvertising();
    for (final sub in _connectionSubs.values) {
      await sub.cancel();
    }
    _connectionSubs.clear();
    for (final sub in _notifySubs.values) {
      await sub.cancel();
    }
    _notifySubs.clear();
    _reassemblers.clear();
    _deviceCache.clear();
    _seenPeers.clear();
    await _discoveriesCtrl.close();
    await _lossesCtrl.close();
    await _inboundCtrl.close();
  }
}

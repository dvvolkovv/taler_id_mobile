import 'dart:async';
import 'dart:typed_data';

import 'package:bonsoir/bonsoir.dart';

import 'mesh_transport.dart';
import 'peer_id.dart';

class BonjourTransport implements MeshTransport {
  static const String serviceType = '_talermesh._tcp';

  BonsoirBroadcast? _broadcast;
  final int _listenPort = 0;

  final _discoveriesCtrl = StreamController<PeerDiscovered>.broadcast();
  final _lossesCtrl = StreamController<PeerLost>.broadcast();
  final _inboundCtrl = StreamController<InboundFrame>.broadcast();

  @override
  Stream<PeerDiscovered> get discoveries => _discoveriesCtrl.stream;
  @override
  Stream<PeerLost> get losses => _lossesCtrl.stream;
  @override
  Stream<InboundFrame> get inbound => _inboundCtrl.stream;

  @override
  Future<void> startAdvertising(DeviceInfo self) async {
    // Temporary: listen port not wired yet — Task 12 adds TCP.
    // For Task 11, just publish the Bonjour record with port 0 placeholder.
    final service = BonsoirService(
      name: self.serviceName,
      type: serviceType,
      port: _listenPort,
      attributes: {
        'pk': self.devicePk.toHex(),
        'ver': '1',
      },
    );
    _broadcast = BonsoirBroadcast(service: service);
    await _broadcast!.ready;
    await _broadcast!.start();
  }

  @override
  Future<void> stopAdvertising() async {
    await _broadcast?.stop();
    _broadcast = null;
  }

  @override
  Future<void> connectTo(PeerId peer) async {
    throw UnimplementedError('implemented in Task 12');
  }

  @override
  Future<void> send(PeerId peer, Uint8List data) async {
    throw UnimplementedError('implemented in Task 12');
  }

  @override
  Future<void> dispose() async {
    await stopAdvertising();
    await _discoveriesCtrl.close();
    await _lossesCtrl.close();
    await _inboundCtrl.close();
  }
}

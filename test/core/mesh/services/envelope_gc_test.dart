import 'package:flutter_test/flutter_test.dart';

import 'package:taler_id_mobile/core/mesh/services/envelope.dart';

void main() {
  group('MeshGcEnvelopeType', () {
    test('mesh_gc_invite round-trip preserves payload', () {
      final env = Envelope(
        version: 1,
        type: MeshGcEnvelopeType.invite,
        convId: 'room-abc',
        clientId: 'invite-uuid-1',
        text: '',
        sentAt: DateTime.utc(2026, 5, 13, 12, 0),
        extra: {
          'roomId': 'room-xyz-789',
          'hostDevicePk': 'host-pk-123',
          'participants': ['user-1', 'user-2', 'user-3'],
          'startedAt': '2026-05-13T12:00:00.000Z',
        },
      );

      final json = env.toJson();
      expect(json['type'], 'mesh_gc_invite');
      expect(json['extra']['roomId'], 'room-xyz-789');
      expect(json['extra']['hostDevicePk'], 'host-pk-123');
      expect(json['extra']['participants'], ['user-1', 'user-2', 'user-3']);
      expect(json['extra']['startedAt'], '2026-05-13T12:00:00.000Z');

      final decoded = Envelope.fromJson(json);
      expect(decoded.type, 'mesh_gc_invite');
      expect(decoded.convId, 'room-abc');
      expect(decoded.text, '');
      expect(decoded.extra, isNotNull);
      expect(decoded.extra!['roomId'], 'room-xyz-789');
      expect(decoded.extra!['hostDevicePk'], 'host-pk-123');
      expect(decoded.extra!['participants'], ['user-1', 'user-2', 'user-3']);
      expect(decoded.extra!['startedAt'], '2026-05-13T12:00:00.000Z');
    });

    test('mesh_gc_accept round-trip preserves payload', () {
      final env = Envelope(
        version: 1,
        type: MeshGcEnvelopeType.accept,
        convId: 'room-xyz',
        clientId: 'accept-uuid-1',
        text: '',
        sentAt: DateTime.utc(2026, 5, 13, 12, 1),
        extra: {
          'roomId': 'room-xyz-789',
          'devicePk': 'device-pk-456',
        },
      );

      final json = env.toJson();
      expect(json['type'], 'mesh_gc_accept');
      expect(json['extra']['roomId'], 'room-xyz-789');
      expect(json['extra']['devicePk'], 'device-pk-456');

      final decoded = Envelope.fromJson(json);
      expect(decoded.type, 'mesh_gc_accept');
      expect(decoded.convId, 'room-xyz');
      expect(decoded.extra, isNotNull);
      expect(decoded.extra!['roomId'], 'room-xyz-789');
      expect(decoded.extra!['devicePk'], 'device-pk-456');
    });

    test('all five mesh_gc types are classified correctly', () {
      expect(MeshGcEnvelopeType.isMeshGc(MeshGcEnvelopeType.invite), isTrue);
      expect(MeshGcEnvelopeType.isMeshGc(MeshGcEnvelopeType.accept), isTrue);
      expect(MeshGcEnvelopeType.isMeshGc(MeshGcEnvelopeType.decline), isTrue);
      expect(MeshGcEnvelopeType.isMeshGc(MeshGcEnvelopeType.leave), isTrue);
      expect(
          MeshGcEnvelopeType.isMeshGc(MeshGcEnvelopeType.keepalive), isTrue);
    });

    test('non-mesh-gc types are rejected', () {
      expect(MeshGcEnvelopeType.isMeshGc('call_invite'), isFalse);
      expect(MeshGcEnvelopeType.isMeshGc('text'), isFalse);
      expect(MeshGcEnvelopeType.isMeshGc('call_accept'), isFalse);
      expect(MeshGcEnvelopeType.isMeshGc('call_reject'), isFalse);
      expect(MeshGcEnvelopeType.isMeshGc('system'), isFalse);
      expect(MeshGcEnvelopeType.isMeshGc('unknown_type'), isFalse);
    });

    test('string values of mesh_gc types match constants', () {
      expect(MeshGcEnvelopeType.invite, 'mesh_gc_invite');
      expect(MeshGcEnvelopeType.accept, 'mesh_gc_accept');
      expect(MeshGcEnvelopeType.decline, 'mesh_gc_decline');
      expect(MeshGcEnvelopeType.leave, 'mesh_gc_leave');
      expect(MeshGcEnvelopeType.keepalive, 'mesh_gc_keepalive');
    });
  });
}

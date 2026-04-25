import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:taler_id_mobile/core/mesh/transport/ble/ble_connection.dart';

void main() {
  group('BleConnection.parseAdvertisementData', () {
    test('parses 8-byte devicePk prefix + flags + version from 10 bytes', () {
      final mfg = Uint8List.fromList([
        0xAB, 0xCD, 0xEF, 0x01, 0x23, 0x45, 0x67, 0x89, // 8B prefix
        0x00, // flags
        0x01, // version
      ]);
      final parsed = BleConnection.parseAdvertisementData(mfg);
      expect(parsed, isNotNull);
      expect(parsed!.devicePkPrefix,
          equals(Uint8List.fromList([0xAB, 0xCD, 0xEF, 0x01, 0x23, 0x45, 0x67, 0x89])));
      expect(parsed.flags, equals(0));
      expect(parsed.version, equals(1));
    });

    test('returns null for too-short buffer', () {
      final mfg = Uint8List.fromList([0xAB, 0xCD]);
      expect(BleConnection.parseAdvertisementData(mfg), isNull);
    });

    test('returns null for wrong version', () {
      final mfg = Uint8List.fromList([
        0xAB, 0xCD, 0xEF, 0x01, 0x23, 0x45, 0x67, 0x89,
        0x00,
        0x02, // unsupported version
      ]);
      expect(BleConnection.parseAdvertisementData(mfg), isNull);
    });
  });
}

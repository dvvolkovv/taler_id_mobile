import 'dart:typed_data';

/// Parsed BLE advertisement payload for the mesh service.
class ParsedAdvertisement {
  final Uint8List devicePkPrefix; // 8 bytes
  final int flags;                // reserved, 0 in Phase 1d
  final int version;              // must equal 1

  ParsedAdvertisement({
    required this.devicePkPrefix,
    required this.flags,
    required this.version,
  });
}

/// Helpers for the BLE connection-level protocol.
///
/// Advertisement wire format (10 bytes of manufacturer data):
/// ```
/// ┌──────────────────────┬──────┬──────────┐
/// │ devicePk prefix (8B) │flags │ version  │
/// │                      │ (1B) │ (1B)     │
/// └──────────────────────┴──────┴──────────┘
/// ```
class BleConnection {
  static const int advertisementVersion = 1;
  static const int advertisementByteLength = 10;

  static ParsedAdvertisement? parseAdvertisementData(Uint8List mfgData) {
    if (mfgData.length < advertisementByteLength) return null;
    final version = mfgData[9];
    if (version != advertisementVersion) return null;
    return ParsedAdvertisement(
      devicePkPrefix: Uint8List.fromList(mfgData.sublist(0, 8)),
      flags: mfgData[8],
      version: version,
    );
  }

  /// Build the 10-byte advertisement manufacturer-data block for our own
  /// device.
  static Uint8List buildAdvertisementData({
    required Uint8List devicePkFull,
    int flags = 0,
  }) {
    if (devicePkFull.length < 8) {
      throw ArgumentError('devicePkFull must be at least 8 bytes');
    }
    final out = Uint8List(advertisementByteLength);
    out.setRange(0, 8, devicePkFull);
    out[8] = flags & 0xFF;
    out[9] = advertisementVersion;
    return out;
  }
}

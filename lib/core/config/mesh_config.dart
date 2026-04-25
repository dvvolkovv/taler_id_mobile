/// Compile-time feature flags for the mesh subsystem.
///
/// Phase 1d: `bleEnabled` gates the BLE transport. Default OFF so shipping
/// builds continue to use only Bonjour until hardware testing signs off.
///
/// Override via:
///   flutter run --dart-define=MESH_BLE_ENABLED=true
class MeshConfig {
  /// Whether the BLE-based MeshTransport is active.
  static const bool bleEnabled = bool.fromEnvironment(
    'MESH_BLE_ENABLED',
    defaultValue: false,
  );
}

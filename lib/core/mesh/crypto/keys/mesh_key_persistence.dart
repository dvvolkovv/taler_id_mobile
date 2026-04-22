import 'dart:convert';
import 'dart:typed_data';

import 'package:hive/hive.dart';

import 'device_key.dart';
import 'mesh_static_key.dart';

/// Hive-backed storage for the two rotating mesh keys.
///
/// Keys rotate every [rotationAge] days. Rotation is triggered lazily on the
/// next [loadOrRotateDeviceKey] / [loadOrRotateMeshStaticKey] call that finds
/// a stored `createdAt` older than [rotationAge] — no background timer.
class MeshKeyPersistence {
  static const Duration rotationAge = Duration(days: 30);

  static const _deviceKeyPrivField = 'device_key_priv';
  static const _deviceKeyCreatedField = 'device_key_created_at';
  static const _meshStaticPrivField = 'mesh_static_priv';
  static const _meshStaticCreatedField = 'mesh_static_created_at';

  final Box<String> _box;

  MeshKeyPersistence._(this._box);

  static Future<MeshKeyPersistence> open({
    String boxName = 'mesh_keys',
  }) async {
    final box = await Hive.openBox<String>(boxName);
    return MeshKeyPersistence._(box);
  }

  /// Load or (re)generate the Ed25519 [DeviceKey].
  ///
  /// Returns `(key, didRotate)`. `didRotate` is true when a fresh key was
  /// written to the box in this call — either because it was absent or the
  /// previous one was older than [rotationAge]. Pass [now] for tests.
  Future<(DeviceKey, bool)> loadOrRotateDeviceKey({DateTime? now}) async {
    return _loadOrRotate<DeviceKey>(
      privField: _deviceKeyPrivField,
      createdField: _deviceKeyCreatedField,
      now: now,
      generate: () async {
        final k = await DeviceKey.generate();
        return (k, k.privateKeyBytes);
      },
      revive: (bytes) => DeviceKey.fromPrivateKeyBytes(bytes),
    );
  }

  /// Load or (re)generate the X25519 [MeshStaticKey]. Same semantics as
  /// [loadOrRotateDeviceKey].
  Future<(MeshStaticKey, bool)> loadOrRotateMeshStaticKey({DateTime? now}) async {
    return _loadOrRotate<MeshStaticKey>(
      privField: _meshStaticPrivField,
      createdField: _meshStaticCreatedField,
      now: now,
      generate: () async {
        final k = await MeshStaticKey.generate();
        return (k, k.privateKeyBytes);
      },
      revive: (bytes) => MeshStaticKey.fromPrivateKeyBytes(bytes),
    );
  }

  Future<(T, bool)> _loadOrRotate<T>({
    required String privField,
    required String createdField,
    required DateTime? now,
    required Future<(T, Uint8List)> Function() generate,
    required Future<T> Function(Uint8List) revive,
  }) async {
    final ts = (now ?? DateTime.now()).toUtc();

    final storedPriv = _box.get(privField);
    final storedCreated = _box.get(createdField);

    if (storedPriv != null && storedCreated != null) {
      final createdAt = DateTime.tryParse(storedCreated);
      if (createdAt != null && ts.difference(createdAt) < rotationAge) {
        final bytes = Uint8List.fromList(base64Decode(storedPriv));
        return (await revive(bytes), false);
      }
    }

    // Generate fresh.
    final (fresh, privBytes) = await generate();
    await _box.put(privField, base64Encode(privBytes));
    await _box.put(createdField, ts.toIso8601String());
    return (fresh, true);
  }

  Future<void> close() => _box.close();
}

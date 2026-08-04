import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../storage/secure_storage_service.dart';

/// Абстракция поверх хранилища — чтобы сервис тестировался без платформенного
/// канала flutter_secure_storage.
abstract class DeviceIdStore {
  Future<String?> read();
  Future<void> write(String value);
}

class SecureDeviceIdStore implements DeviceIdStore {
  static const _key = 'device_id';

  final SecureStorageService storage;
  SecureDeviceIdStore(this.storage);

  @override
  Future<String?> read() => storage.read(_key);

  @override
  Future<void> write(String value) => storage.write(_key, value);
}

/// Непрозрачный идентификатор этой установки приложения.
///
/// Бэкенд по нему отличает знакомое устройство от нового. Ничего личного он не
/// несёт и пересоздаётся при переустановке — тогда вход просто потребует
/// подтверждения, как с нового устройства.
class DeviceIdService {
  final DeviceIdStore _store;
  String _deviceId = '';

  DeviceIdService(this._store);

  String get deviceId => _deviceId;

  Future<void> init() async {
    try {
      final existing = await _store.read();
      if (existing != null && existing.isNotEmpty) {
        _deviceId = existing;
        return;
      }
      final fresh = const Uuid().v4();
      await _store.write(fresh);
      _deviceId = fresh;
    } catch (e) {
      // Идентификатор — удобство, а не условие работы: пустое значение просто
      // означает, что заголовок не уйдёт и вход пройдёт как у старых клиентов.
      // Уронить старт приложения из-за заблокированного keychain было бы хуже.
      debugPrint('[DeviceId] unavailable, continuing without one: $e');
      _deviceId = '';
    }
  }
}

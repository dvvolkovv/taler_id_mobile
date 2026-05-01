import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract class OAuthPendingStorage {
  Future<String?> read();
  Future<void> write(String value);
  Future<void> clear();
}

class SecureStorageOAuthPending implements OAuthPendingStorage {
  static const _key = 'oauth_pending_v1';
  final FlutterSecureStorage _storage;
  SecureStorageOAuthPending([FlutterSecureStorage? storage])
      : _storage = storage ?? const FlutterSecureStorage();

  @override
  Future<String?> read() => _storage.read(key: _key);

  @override
  Future<void> write(String value) => _storage.write(key: _key, value: value);

  @override
  Future<void> clear() => _storage.delete(key: _key);
}

class OAuthPendingRequest {
  static const _ttl = Duration(minutes: 5);

  final OAuthPendingStorage _storage;
  final DateTime Function() _now;

  OAuthPendingRequest({
    required OAuthPendingStorage storage,
    DateTime Function()? now,
  })  : _storage = storage,
        _now = now ?? DateTime.now;

  Future<void> save(Uri uri) async {
    final payload = jsonEncode({
      'uri': uri.toString(),
      'savedAt': _now().toIso8601String(),
    });
    await _storage.write(payload);
  }

  Future<Uri?> consume() async {
    final raw = await _storage.read();
    if (raw == null) return null;
    try {
      final payload = jsonDecode(raw) as Map<String, dynamic>;
      final savedAt = DateTime.parse(payload['savedAt'] as String);
      if (_now().difference(savedAt) > _ttl) {
        await _storage.clear();
        return null;
      }
      await _storage.clear();
      return Uri.parse(payload['uri'] as String);
    } catch (_) {
      await _storage.clear();
      return null;
    }
  }
}

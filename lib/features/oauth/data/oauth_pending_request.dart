import 'dart:convert';

import '../../../core/platform/secure_storage.dart';

abstract class OAuthPendingStorage {
  Future<String?> read();
  Future<void> write(String value);
  Future<void> clear();
}

class SecureStorageOAuthPending implements OAuthPendingStorage {
  static const _key = 'oauth_pending_v1';

  @override
  Future<String?> read() => SecureStorage.instance.read(_key);

  @override
  Future<void> write(String value) => SecureStorage.instance.write(_key, value);

  @override
  Future<void> clear() => SecureStorage.instance.delete(_key);
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
      final age = _now().difference(savedAt);
      // Reject negative ages too — guards against device clock corrected
      // backwards between save and consume, which would otherwise bypass TTL.
      if (age < Duration.zero || age >= _ttl) {
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

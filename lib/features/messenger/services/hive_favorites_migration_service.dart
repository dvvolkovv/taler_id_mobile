import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../domain/repositories/i_messenger_repository.dart';

/// One-shot migration: moves legacy Hive `saved_messages` entries to the
/// server-side SAVED conversation via [IMessengerRepository].
///
/// Idempotent — guarded by a `saved_migrated_v1` flag in secure storage.
/// Best-effort — never throws; if anything fails the flag is NOT set so the
/// migration is retried on the next app launch.
class HiveFavoritesMigrationService {
  static const _flagKey = 'saved_migrated_v1';
  static const _boxName = 'saved_messages';

  final IMessengerRepository _repo;
  final SecureStorageService _storage;

  HiveFavoritesMigrationService({
    required IMessengerRepository repo,
    required SecureStorageService storage,
  })  : _repo = repo,
        _storage = storage;

  Future<void> runOnce() async {
    try {
      final done = await _storage.read(_flagKey);
      if (done == 'true') return;

      if (!await Hive.boxExists(_boxName)) {
        await _storage.write(_flagKey, 'true');
        return;
      }

      final box = await Hive.openBox<Map>(_boxName);
      try {
        if (box.isEmpty) {
          await box.deleteFromDisk();
          await _storage.write(_flagKey, 'true');
          return;
        }

        final entries = box.values
            .map((e) => Map<String, dynamic>.from(e))
            .toList();

        // Sort oldest-first so messages appear in chronological order in SAVED.
        entries.sort((a, b) {
          final av = (a['savedAt'] ?? '').toString();
          final bv = (b['savedAt'] ?? '').toString();
          return av.compareTo(bv);
        });

        final convId = await _repo.getOrCreateSavedConversation();

        for (final e in entries) {
          _repo.sendMessage(
            convId,
            (e['content'] ?? '') as String,
            fileUrl: e['fileUrl'] as String?,
            fileName: e['fileName'] as String?,
            fileType: e['fileType'] as String?,
            fileSize: (e['fileSize'] as num?)?.toInt(),
          );
        }

        await box.deleteFromDisk();
        await _storage.write(_flagKey, 'true');
      } finally {
        if (box.isOpen) await box.close();
      }
    } catch (e, st) {
      debugPrint('[HiveFavoritesMigration] failed: $e\n$st');
      // Intentionally NOT rethrow + NOT set flag → retry next launch.
    }
  }
}

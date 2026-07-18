import 'dart:async';

import 'package:hive/hive.dart';

import '../../../core/api/dio_client.dart';

/// Fetches the assistant system-prompt static body from the backend
/// (`GET /assistant/instructions?locale=…`) and caches it:
/// - in memory with a 15-minute TTL (avoid re-fetching on every session);
/// - in Hive (`body_<locale>`) for offline / fetch-error fallback.
///
/// On fetch error the last Hive-persisted body is returned (stale is fine —
/// the prompt changes rarely); if nothing was ever cached, `null` is returned
/// and the caller falls back to the baked-in prompt.
class AssistantInstructionsRepository {
  AssistantInstructionsRepository(this._dio, this._box);

  final DioClient _dio;
  final Box<String> _box;

  static const boxName = 'assistant_instructions';
  static const _ttl = Duration(minutes: 15);

  final Map<String, String> _memory = {};
  final Map<String, DateTime> _fetchedAt = {};
  final Map<String, Future<String?>> _inflight = {};

  /// Returns the cached body if fresh (<15 min), otherwise fetches from the
  /// backend, persists to Hive + memory and returns it. On fetch error returns
  /// the Hive-cached body if present (stale ok), else null.
  Future<String?> get(String locale) {
    final cached = _memory[locale];
    final at = _fetchedAt[locale];
    if (cached != null && at != null && DateTime.now().difference(at) < _ttl) {
      return Future.value(cached);
    }
    // NB: the whenComplete callback must not RETURN the removed future —
    // `Map.remove` hands back the stored future and `whenComplete` would then
    // await it, deadlocking on itself. Use a block body to discard it.
    return _inflight[locale] ??= _fetch(locale).whenComplete(() {
      _inflight.remove(locale);
    });
  }

  Future<String?> _fetch(String locale) async {
    try {
      final data = await _dio.get<Map<String, dynamic>>(
        '/assistant/instructions',
        queryParameters: {'locale': locale},
      );
      final body = data['body'] as String?;
      if (body == null || body.isEmpty) {
        return _box.get('body_$locale');
      }
      _memory[locale] = body;
      _fetchedAt[locale] = DateTime.now();
      await _box.put('body_$locale', body);
      return body;
    } catch (_) {
      return _box.get('body_$locale');
    }
  }

  /// Fire-and-forget warmup used at screen init.
  void prefetch(String locale) {
    unawaited(get(locale));
  }
}

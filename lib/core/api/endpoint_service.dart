import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../config/app_config.dart';

/// Single source of truth for the active backend base URL, with failover.
///
/// CIS ISPs DPI-block the DO backend (`api.talerid.io`) for end-users. When the
/// primary endpoint is unreachable we transparently fail over to the Russian-IP
/// Selectel edges (`ru.talerid.io` / `ru2.talerid.io`) which relay to the SAME
/// backend over a path that works from inside Russia.
///
/// Both the HTTP client (Dio) and the messenger Socket.IO read [baseUrl] and
/// listen to [activeUrl], so they always move to the same endpoint together.
///
/// For non-`talerid` flavors (dev / aeza-prod) there are no fallbacks, so this
/// is inert — behaves exactly as before.
class EndpointService {
  EndpointService({List<String>? candidates})
      : _candidates = candidates ?? _defaultCandidates() {
    if (_candidates.isNotEmpty && activeUrl.value != _candidates.first) {
      activeUrl.value = _candidates.first;
    }
  }

  static const _boxName = 'endpoint_cache';
  static const _key = 'active_base_url';

  final List<String> _candidates;
  int _idx = 0;
  Box<dynamic>? _box;

  /// Fires whenever the active base URL changes (Dio + Socket.IO listen to this).
  final ValueNotifier<String> activeUrl =
      ValueNotifier<String>(AppConfig.baseUrl);

  String get baseUrl => activeUrl.value;
  List<String> get candidates => List.unmodifiable(_candidates);
  bool get hasFallback => _candidates.length > 1;

  static List<String> _defaultCandidates() {
    final seen = <String>{};
    return [
      for (final u in [AppConfig.baseUrl, ...AppConfig.fallbackBaseUrls])
        if (seen.add(u)) u,
    ];
  }

  /// Restore the last-known-good endpoint so a CIS device doesn't re-discover the
  /// edge on every cold start. Best-effort; failover still works without it.
  /// Safe to call after Hive is initialized (CacheService.init()).
  Future<void> init() async {
    if (!hasFallback) return;
    try {
      _box = await Hive.openBox(_boxName);
      final saved = _box?.get(_key) as String?;
      if (saved != null && _candidates.contains(saved)) {
        _idx = _candidates.indexOf(saved);
        if (activeUrl.value != saved) activeUrl.value = saved;
      }
    } catch (_) {/* persistence is optional */}
  }

  /// Proactively pick a reachable endpoint at startup so the first real request
  /// (login) doesn't eat a full connect-timeout before failing over. Time-boxed
  /// and best-effort: if nothing answers we keep the current value and let the
  /// Dio interceptor fail over on the first call.
  Future<void> probe() async {
    if (!hasFallback) return;
    // Try the current endpoint first (last-good or primary), then the rest.
    final order = <String>[
      _candidates[_idx],
      for (var i = 0; i < _candidates.length; i++)
        if (i != _idx) _candidates[i],
    ];
    final probe = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 4),
      receiveTimeout: const Duration(seconds: 4),
    ));
    for (final url in order) {
      try {
        final r = await probe.getUri(Uri.parse('$url/health'));
        if (r.statusCode == 200) {
          await _setActive(url);
          probe.close(force: true);
          return;
        }
      } catch (_) {/* try next */}
    }
    probe.close(force: true);
  }

  Future<void> _setActive(String url) async {
    final i = _candidates.indexOf(url);
    if (i < 0) return;
    _idx = i;
    try {
      await _box?.put(_key, url);
    } catch (_) {}
    if (activeUrl.value != url) activeUrl.value = url; // notify Dio + socket
  }

  /// Advance to the next candidate after a network failure on the current one.
  /// Returns true if the active endpoint actually changed.
  Future<bool> reportFailureAndFallback() async {
    if (!hasFallback) return false;
    final next = (_idx + 1) % _candidates.length;
    final url = _candidates[next];
    final changed = url != activeUrl.value;
    await _setActive(url);
    return changed;
  }

  /// Optimistically return to the primary (e.g. on app resume / network regained),
  /// so a recovered DO connection is preferred over the RU edge again.
  Future<void> resetToPrimary() async {
    if (_idx == 0) return;
    await _setActive(_candidates[0]);
  }
}

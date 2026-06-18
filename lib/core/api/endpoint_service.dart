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

  // Per-endpoint failure cooldown. After an endpoint fails we avoid rotating
  // back onto it for [_cooldown]. This is what stops a CIS device from cycling
  // back onto the DPI-blocked primary every rotation (the symptom: yellow cloud
  // + "error timeout()" while parked on api.talerid.io). A working endpoint
  // clears its mark via [reportSuccess], so the blocked primary is only retried
  // when EVERY edge is also failing.
  final Map<String, DateTime> _failedAt = {};
  static const Duration _cooldown = Duration(minutes: 5);
  String? _persistedGood;

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

  /// Switch the active endpoint. Only persists as last-known-good when [persist]
  /// is true — i.e. for endpoints we have positively validated (startup probe or
  /// a real success). A blind failover hop ([persist] false) must NOT be cached,
  /// or a cold start could re-prefer an endpoint that merely "wasn't tried last".
  Future<void> _setActive(String url, {bool persist = true}) async {
    final i = _candidates.indexOf(url);
    if (i < 0) return;
    _idx = i;
    if (persist) {
      _persistedGood = url;
      try {
        await _box?.put(_key, url);
      } catch (_) {}
    }
    if (activeUrl.value != url) activeUrl.value = url; // notify Dio + socket
  }

  /// Advance to the next *usable* candidate after a network failure on the
  /// current one. "Usable" = not failed within [_cooldown]. If every candidate
  /// is in cooldown we reuse the least-recently-failed one so we still make
  /// progress (rather than hammer the just-failed endpoint). Returns true if the
  /// active endpoint actually changed.
  Future<bool> reportFailureAndFallback() async {
    if (!hasFallback) return false;
    final now = DateTime.now();
    _failedAt[_candidates[_idx]] = now; // the current endpoint just failed

    int? pick;
    // Prefer the next candidate (in order, after current) that is NOT cooling down.
    for (var step = 1; step <= _candidates.length; step++) {
      final i = (_idx + step) % _candidates.length;
      final failed = _failedAt[_candidates[i]];
      if (failed == null || now.difference(failed) > _cooldown) {
        pick = i;
        break;
      }
    }
    // Everything is cooling down -> reuse the least-recently-failed endpoint
    // (excluding the one that just failed) so the client keeps trying *something*.
    if (pick == null) {
      DateTime? oldest;
      for (var i = 0; i < _candidates.length; i++) {
        if (i == _idx) continue;
        final f = _failedAt[_candidates[i]];
        if (f != null && (oldest == null || f.isBefore(oldest))) {
          oldest = f;
          pick = i;
        }
      }
      pick ??= (_idx + 1) % _candidates.length;
    }

    final url = _candidates[pick];
    final changed = url != activeUrl.value;
    await _setActive(url, persist: false); // not yet validated on the new edge
    return changed;
  }

  /// Mark the active endpoint as healthy: clears its failure mark (so it's
  /// eligible again) and persists it as last-known-good. Called by Dio on a
  /// successful response and by the messenger socket on `connect`.
  Future<void> reportSuccess() async {
    if (!hasFallback) return;
    _failedAt.remove(activeUrl.value);
    if (_persistedGood != activeUrl.value) {
      _persistedGood = activeUrl.value;
      try {
        await _box?.put(_key, activeUrl.value);
      } catch (_) {}
    }
  }

  /// Optimistically return to the primary (e.g. on app resume / network regained),
  /// so a recovered DO connection is preferred over the RU edge again.
  Future<void> resetToPrimary() async {
    if (_idx == 0) return;
    await _setActive(_candidates[0]);
  }
}

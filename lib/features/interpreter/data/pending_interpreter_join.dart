/// Carries a face-to-face interpreter join code across the login screen.
///
/// `talerid://interp/<code>` opened from the system camera while logged out
/// lands on `/login` (see `_globalRedirect` in `app_router.dart`) before the
/// code can be used — without this, the code is simply lost. Mirrors
/// `OAuthPendingRequest`, but in memory only: a cold start by link and the
/// login that follows it happen in the same process, so there is nothing to
/// persist across app restarts, unlike the OAuth consent flow (which can be
/// interrupted by a biometric prompt or backgrounding long enough to need
/// secure storage).
class PendingInterpreterJoin {
  /// The join code's own life, not an arbitrary pick — matches the 5-minute
  /// QR/code expiry on the backend.
  static const _ttl = Duration(minutes: 5);

  PendingInterpreterJoin({DateTime Function()? now})
      : _now = now ?? DateTime.now;

  final DateTime Function() _now;

  String? _code;
  DateTime? _savedAt;

  void save(String code) {
    _code = code;
    _savedAt = _now();
  }

  /// Returns the saved code if one is pending and still fresh, consuming it
  /// either way (one-shot, like `OAuthPendingRequest.consume`).
  String? consume() {
    final code = _code;
    final savedAt = _savedAt;
    _code = null;
    _savedAt = null;
    if (code == null || savedAt == null) return null;
    final age = _now().difference(savedAt);
    // Reject negative ages too — guards against a device clock corrected
    // backwards between save and consume, which would otherwise bypass TTL.
    if (age < Duration.zero || age >= _ttl) return null;
    return code;
  }
}

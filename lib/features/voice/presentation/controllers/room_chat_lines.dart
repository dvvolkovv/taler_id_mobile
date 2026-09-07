import 'room_chat_controller.dart';

/// Per-call-line chat state for a screen that can show more than one
/// simultaneous call (`CallStateService`'s multi-line support /
/// `VoiceCallScreen._switchToLine`).
///
/// Before room chat had server-backed history, `VoiceCallScreen` used a
/// single [RoomChatController] shared across every line it ever showed.
/// That was already slightly wrong (switching lines never cleared the
/// feed), but harmless in practice: the feed was P2P-only and ephemeral, so
/// a stray message from the line you'd left just looked like an odd
/// leftover bubble. Once chat became server-backed and per-room — history
/// fetched specifically for *this* room — the same sharing became a real
/// bug: switching to a second simultaneous call showed the *first* call's
/// conversation (wrong people, wrong meeting), and a still-in-flight send
/// or history fetch from the line you left could resolve after you'd
/// switched and mutate the feed you're now looking at.
///
/// The fix is not "clear the shared controller on switch" — that still
/// leaves a live race for anything already in flight when the switch
/// happens — but to give each line (keyed by `roomName`, the same identity
/// `CallStateService._lines` already uses) its own controller. A response
/// for a line that is no longer on screen simply has nowhere shared left to
/// corrupt: it lands on that line's own controller, which nothing is
/// listening to right now.
///
/// ## Why every return to a line re-fetches (catch-up, not "just in case")
///
/// `VoiceCallScreen._switchToLine` tears down the data-channel listener for
/// the line you're leaving and attaches it only to the line you're
/// switching to — a held line has no live listener AT ALL, not a
/// less-reliable one. Anything another participant sends on that line while
/// it's held is not delayed, not queued, not caught up on arrival: it is
/// simply never received by this screen instance, full stop. The only way
/// this screen ever finds out about it is by asking the server directly,
/// which is why [fetchCursor] returns a cursor (not "skip, already know
/// this line") on every return to an already-shown line, not just the
/// first time it's shown.
class RoomChatLines {
  final Map<String, RoomChatController> _controllers = {};
  final Map<String, int> _lastSeq = {};
  String? _activeRoomName;

  /// Marks [roomName] as the line currently on screen and returns its
  /// controller, creating one the first time this line is shown. Call this
  /// at every point `VoiceCallScreen` starts showing a (possibly different)
  /// room: the initial connect, resuming an already-connected room, and
  /// `_switchToLine`.
  RoomChatController select(String roomName) {
    _activeRoomName = roomName;
    return _controllers.putIfAbsent(roomName, () => RoomChatController());
  }

  /// The `since` cursor [roomName]'s next history fetch should use: `null`
  /// for a full fetch, covering the case of the very first time this line
  /// is shown, or a prior fetch for it that never got far enough to record
  /// a cursor (network failure — we don't know what we might have missed,
  /// so re-reading everything is the honest option, not a guess). Otherwise
  /// the last known seq, for a catch-up fetch that returns only what's new
  /// since then.
  ///
  /// Called every time [select] points at a (possibly repeat) line — see
  /// the class doc on why a return visit still needs a real fetch, not a
  /// skip.
  int? fetchCursor(String roomName) => _lastSeq[roomName];

  /// Records that [roomName]'s feed is known up to at least [seq] — from
  /// either a history page's own cursor ([RoomChatHistoryPage.seq], via
  /// `parseRoomChatHistory` — individual messages don't carry it, only the
  /// page does) or a live data-channel packet's own `seq` field, whichever
  /// arrives. Monotonic: a lower [seq] than what's already recorded (an
  /// out-of-order or redelivered older packet) never rolls the cursor
  /// backward — the next catch-up fetch must never re-request something
  /// this line has already definitely seen.
  void recordSeq(String roomName, int seq) {
    final current = _lastSeq[roomName];
    if (current == null || seq > current) {
      _lastSeq[roomName] = seq;
    }
  }

  /// Whether a fetch that used [since] as its cursor and came back with
  /// [truncated] should be discarded in favour of a fresh full re-fetch,
  /// rather than trusted and merged in as-is.
  ///
  /// True only when the fetch WAS a catch-up ([since] non-null) and the
  /// server flagged it truncated: that combination means something between
  /// the cursor and now didn't fit in the page, i.e. there is a genuine gap
  /// this response can't account for, and gluing it onto the existing feed
  /// would silently paper over missing conversation — the exact case
  /// `truncated` exists to flag. A truncated FULL fetch ([since] null) is a
  /// different, already-accepted limitation (there's simply more history
  /// than the server will ever return in one page) and is trusted as-is —
  /// retrying it would only truncate again.
  static bool needsFullRefetch({required bool truncated, required int? since}) =>
      truncated && since != null;

  /// Whether [roomName] is still the line on screen right now. A history
  /// fetch (or any other async continuation keyed to a specific line) that
  /// resolves after the user has switched away — possibly back and forth
  /// more than once — should check this before triggering a UI rebuild for
  /// a controller nobody is currently looking at.
  ///
  /// This does not guard correctness of the *data* — [select] already
  /// guarantees a response can only ever be written to its own line's
  /// controller — only whether redrawing the screen for it is still
  /// warranted.
  bool isActive(String roomName) => roomName == _activeRoomName;

  /// Disposes every controller this instance ever created, exactly once
  /// each. Call from `VoiceCallScreen.dispose()`.
  void disposeAll() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
  }
}

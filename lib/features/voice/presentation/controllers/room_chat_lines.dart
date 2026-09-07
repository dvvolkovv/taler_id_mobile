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
class RoomChatLines {
  final Map<String, RoomChatController> _controllers = {};
  final Set<String> _historyRequested = {};
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

  /// True the first time this is called for [roomName] — and marks it
  /// requested immediately, before the caller's fetch even starts, so two
  /// near-simultaneous calls (shouldn't happen, but costs nothing to guard)
  /// don't both dispatch a fetch. False on every later call for the same
  /// [roomName].
  ///
  /// The caller uses this to fetch a line's history exactly once per screen
  /// instance — the original single-line "once after connecting" rule,
  /// extended to every line the screen ever shows, not just the first.
  bool shouldFetchHistory(String roomName) => _historyRequested.add(roomName);

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

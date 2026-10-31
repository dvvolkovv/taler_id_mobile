import '../utils/constants.dart';

/// Whether a share from another app may open the recipient picker while
/// [location] is on screen.
///
/// Not over a call: the picker is opened with `go`, which would replace the
/// screen the conversation runs on. The share waits until the call is
/// minimised or over — the dashboard checks again on every route change.
bool canOpenSharePicker(String location) =>
    !location.startsWith(RouteConstants.voice) &&
    !location.startsWith('/group-call/');

/// Redirect for the picker route: without files there is nothing to show,
/// so back to the chat list.
String? sharePickerRedirect(Object? extra) =>
    extra is List && extra.isNotEmpty ? null : RouteConstants.messenger;
